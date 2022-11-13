#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>

#define MAX_ORDER 14
#define MAX_BIT_LENGTH 512

static intptr_t base_page; // 记录基虚拟地址页
static int32_t bit_map[MAX_ORDER + 1][MAX_BIT_LENGTH];
#define offset(p) (((intptr_t)p - base_page) / sizeof(struct Page))

free_area_t free_area[MAX_ORDER + 1];
#define free_list(i) (free_area[i].free_list)
#define nr_free(i) (free_area[i].nr_free)

static void
print_buddy_sys(char* s) {
    cprintf("===============================\n%s\n", s);
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
        cprintf("order %d: ", i);
        list_entry_t *le = &free_list(i);
        while ((le = list_next(le)) != &free_list(i)) {
            struct Page *page = le2page(le, page_link);
            intptr_t off = offset(page);
            cprintf("va: %x, offset: %d, property: %d->", page, off, page->property);
        }
        cprintf("\n");
    }
}

static void
buddy_init(void) {
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
        list_init(&free_list(i));
        nr_free(i) = 0;
    }
}

static inline void 
flip_bit_map(int32_t order, struct Page* page) {
    int32_t bit_num = (offset(page) >> (order + 1));
    bit_map[order][bit_num / 32] ^= (1 << (bit_num % 32));
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    // 这里发现只有一个可用的页框
    cprintf("va: 0x%x, pa: 0x%x, num: %d\n", base, page2pa(base), n);
    assert(n > 0);
    //设置base_page，用于归零
    base_page = base;
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    struct Page *page = base;
    int32_t now_order = MAX_ORDER;
    // 由于初始时只映射了4M，这里如果全用了，按照算法实现会返回没有被映射到的页
    // while (now_order <= MAX_ORDER) {
        if (n > (1 << now_order)) {
            page->property = (1 << now_order);
            SetPageProperty(page);
            nr_free(now_order)  += (1 << now_order);
            list_add(&free_list(now_order), &(page->page_link));
            // 这里位图要更新一下
            flip_bit_map(now_order, page);
            page += (1 << now_order);
            n -= (1 << now_order);
        }
        now_order += 1;
    // }
    cprintf("base_page is: %x\n", base_page);
    print_buddy_sys("init_status");
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    int32_t upper_order = 0;
    //找到刚好大于n，且有空闲页框的阶
    while ((1 << upper_order) < n || nr_free(upper_order) < n) {
        upper_order += 1;
    }
    if (upper_order > MAX_ORDER) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list(upper_order);
    le = list_next(le);
    page = le2page(le, page_link);
    //把当前这个页摘下来
    // 设置位图
    flip_bit_map(upper_order, page);
    // 把这个页框从链表删除
    list_del(&(page->page_link));
    nr_free(upper_order) -= page->property;
    if (page->property >= (n << 1)) {
        // 如果可以分裂，得一直分裂，分裂结束得条件是当前的页框大小/2<n
        // now_order记录当前分裂的页框的阶
        int32_t now_order = upper_order;
        while ((page->property >> 1) >= n) {
            int32_t lower_order = now_order - 1;
            // 把当前页分裂成左右两个
            struct Page *left_sub_page, *right_sub_page;
            left_sub_page = page;
            right_sub_page = page + page->property / 2;
            // 把右边页插入到下一阶的链表中，并设置位图
            SetPageProperty(right_sub_page);
            right_sub_page->property = page->property / 2;
            list_add(&free_list(lower_order), &right_sub_page->page_link);
            nr_free(lower_order) += right_sub_page->property;
            flip_bit_map(lower_order, right_sub_page);
            // 左边页继续分裂
            now_order -= 1;
            left_sub_page->property = right_sub_page->property;
            page = left_sub_page;
        }
    }
    ClearPageProperty(page);
    return page;
}

static inline struct Page *
get_buddy(struct Page* page, int32_t order) {
    // 得到当前页的伙伴
    int32_t off = offset(page);
    int32_t buddy_off = (off ^ (1 << order));
    return base_page + buddy_off * sizeof(struct Page);
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    // 先检查n的合法性
    assert(n > 0);
    int now_order = 0;
    while ((1 << now_order) < n) {
        now_order += 1;
    }
    n = (1 << now_order);
    assert(now_order <= MAX_ORDER && now_order >= 0);
    // 再检查base的合法性
    assert(offset(base) % n == 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    // 开始尝试合并页框
    flip_bit_map(now_order, base);
    intptr_t bit_num = (offset(base) >> (now_order + 1));
    while (now_order < MAX_ORDER && (bit_map[now_order][bit_num / 32] & (1 << (bit_num % 32))) == 0) {
        // 得到当前插入页框的buddy
        struct Page *now_buddy = get_buddy(base, now_order);
        list_del(&now_buddy->page_link);
        ClearPageProperty(now_buddy);
        nr_free(now_order) -= now_buddy->property;
        if (now_buddy < base) {
            base = now_buddy;
        }
        base->property <<= 1;
        now_order += 1;
        flip_bit_map(now_order, base);
        bit_num = (offset(base) >> (now_order + 1));
    }
    SetPageProperty(base);
    nr_free(now_order) += base->property;
    list_add(&free_list(now_order), &base->page_link);
}

static size_t
buddy_nr_free_pages(void) {
    size_t total_nr_free = 0;
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
        total_nr_free += nr_free(i);
    }
    return total_nr_free;
}

static void
buddy_check(void) {
    struct Page *p0, *p1, *p2;
    cprintf("\ntest_stage 1\n");
    p0 = buddy_alloc_pages(1);
    print_buddy_sys("alloc p0, size 1");
    buddy_free_pages(p0, 1);
    print_buddy_sys("free p0");
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER));

    cprintf("\ntest_stage 2\n");
    p0 = buddy_alloc_pages(7);
    print_buddy_sys("alloc p0, size 7");
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 8);
    p1 = buddy_alloc_pages(15);
    print_buddy_sys("alloc p1, size 15");
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 24);
    p2 = buddy_alloc_pages(1);
    print_buddy_sys("alloc p2, size 1");
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 25);
    buddy_free_pages(p0, 7);
    print_buddy_sys("free p0");
    buddy_free_pages(p1, 15);
    print_buddy_sys("free p1");
    buddy_free_pages(p2, 1);
    print_buddy_sys("free p2");
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER));

    cprintf("\ntest_stage 3\n");
    p0 = buddy_alloc_pages(257);
    print_buddy_sys("alloc p0, size 257");
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 512);
    p1 = buddy_alloc_pages(257);
    print_buddy_sys("alloc p1, size 257");
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 1024);
    p2 = buddy_alloc_pages(257);
    print_buddy_sys("alloc p2, size 257");
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 1536);
    buddy_free_pages(p0, 257);
    print_buddy_sys("free p0");
    buddy_free_pages(p1, 257);
    print_buddy_sys("free p1");
    buddy_free_pages(p2, 257);
    print_buddy_sys("free p2");
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER));

    cprintf("\ntest_stage 4\n");
    p0 = buddy_alloc_pages(8);
    print_buddy_sys("alloc p0, size 8");
    int32_t i;
    for (i = 0; i < 8; i += 2) {
        buddy_free_pages(p0 + i, 1);
        print_buddy_sys("free p0 + i, size 1");
    }
    for (i = 1; i < 8; i += 2) {
        buddy_free_pages(p0 + i, 1);
        print_buddy_sys("free p0 + i, size 1");
    }
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};