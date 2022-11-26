#include <defs.h>
#include <x86.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_extended_clock.h>
#include <list.h>

list_entry_t pra_list_head; // 链表头，把所有可交换的页连接起来

static int
_ext_clock_init_mm(struct mm_struct *mm)
{
    list_init(&pra_list_head);
    mm->sm_priv = &pra_list_head;
    return 0;
}

static int
_ext_clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
    list_entry_t *entry = &(page->pra_page_link);

    assert(entry != NULL && head != NULL);
    // record the page access situlation
    list_add_before(head, entry);
    return 0;
}

static int
_ext_clock_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick)
{
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
    assert(head != NULL);
    assert(in_tick == 0);
    // 最多得三遍遍历
    // 先找00的
    list_entry_t *le = head;
    while ((le = list_next(le)) != head) {
        struct Page *page = le2page(le, pra_page_link);
        assert(page != NULL);
        pte_t *pte = get_pte(mm->pgdir, page->pra_vaddr, 0);
        assert(pte != NULL);
        // 如果找到00的了，直接返回
        if (!(*pte & PTE_A) && !(*pte & PTE_D)) {
            list_del(le);
            *ptr_page = page;
            return 0;
        }
    }
    // 然后找01的，这时候碰上1*的，把1刷成0
    le = head;
    while ((le = list_next(le)) != head) {
        struct Page *page = le2page(le, pra_page_link);
        assert(page != NULL);
        pte_t *pte = get_pte(mm->pgdir, page->pra_vaddr, 0);
        assert(pte != NULL);
        // 找到了01的，直接返回
        if (!(*pte & PTE_A) && (*pte & PTE_D)) {
            list_del(le);
            *ptr_page = page;
            return 0;
        }
        // 当前是1*，把1刷成0
        else if (*pte & PTE_A) {
            *pte &= (~PTE_A);
            tlb_invalidate(mm->pgdir, page->pra_vaddr);
        }
    }
    // 第三遍，找00和01的
    struct Page *result_page = NULL;
    list_entry_t *result_le;
    le = head;
    while ((le = list_next(le)) != head) {
        struct Page *page = le2page(le, pra_page_link);
        assert(page != NULL);
        pte_t *pte = get_pte(mm->pgdir, page->pra_vaddr, 0);
        assert(pte != NULL);
        // 如果找到00的了，直接返回
        if (!(*pte & PTE_A) && !(*pte & PTE_D)) {
            list_del(le);
            *ptr_page = page;
            return 0;
        }
        // 如果当前是01，则看看前边有没有01，若没有，则赋值result_page
        else if (!(*pte & PTE_A) && (*pte & PTE_D) && result_page == NULL) {
            result_le = le;
            result_page = page;
        }
    }
    // 如果最后一遍没有找到00，找到了01，返回01
    if (result_page != NULL) {
        list_del(result_le);
        *ptr_page = result_page;
        return 0;
    }
    // 嘎了
    return -1;
}

static int
_ext_clock_check_swap(void)
{
    cprintf("write Virt Page c in ext_clock_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 4);
    cprintf("write Virt Page a in ext_clock_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 4);
    cprintf("write Virt Page d in ext_clock_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 4);
    cprintf("write Virt Page b in ext_clock_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 4);
    cprintf("write Virt Page e in ext_clock_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 5);
    cprintf("write Virt Page b in ext_clock_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 5);
    cprintf("write Virt Page a in ext_clock_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 6);
    cprintf("write Virt Page b in ext_clock_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 6);
    cprintf("write Virt Page c in ext_clock_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 7);
    cprintf("write Virt Page d in ext_clock_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 8);
    cprintf("write Virt Page e in ext_clock_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 8);
    cprintf("write Virt Page a in ext_clock_check_swap\n");
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 8);
    return 0;
}

static int
_ext_clock_init(void)
{
    return 0;
}

static int
_ext_clock_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
_ext_clock_tick_event(struct mm_struct *mm)
{
    return 0;
}

struct swap_manager swap_manager_extended_clock =
{
    .name = "extended clock swap manager",
    .init = &_ext_clock_init,
    .init_mm = &_ext_clock_init_mm,
    .tick_event = &_ext_clock_tick_event,
    .map_swappable = &_ext_clock_map_swappable,
    .set_unswappable = &_ext_clock_set_unswappable,
    .swap_out_victim = &_ext_clock_swap_out_victim,
    .check_swap = &_ext_clock_check_swap,
};