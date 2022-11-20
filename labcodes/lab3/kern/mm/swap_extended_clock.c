#include <defs.h>
#include <x86.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_extended_clock.h>
#include <list.h>

list_entry_t pra_list_head; // 链表头，把所有可交换的页连接起来
/*
 * (2) _fifo_init_mm: init pra_list_head and let  mm->sm_priv point to the addr of pra_list_head.
 *              Now, From the memory control struct mm_struct, we can access FIFO PRA
 */
static int
_ext_clock_init_mm(struct mm_struct *mm)
{
    list_init(&pra_list_head);
    mm->sm_priv = &pra_list_head;
    return 0;
}
/*
 * (3)_fifo_map_swappable: According FIFO PRA, we should link the most recent arrival page at the back of pra_list_head qeueue
 */
static int
_ext_clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
    list_entry_t *entry = &(page->pra_page_link);

    assert(entry != NULL && head != NULL);
    // record the page access situlation
    /*LAB3 EXERCISE 2: YOUR CODE*/
    //(1)link the most recent arrival page at the back of the pra_list_head qeueue.
    list_add_before(head, entry);
    return 0;
}
/*
 *  (4)_fifo_swap_out_victim: According FIFO PRA, we should unlink the  earliest arrival page in front of pra_list_head qeueue,
 *                            then assign the value of *ptr_page to the addr of this page.
 */
static int
_ext_clock_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick)
{
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
    assert(head != NULL);
    assert(in_tick == 0);
    // 最多需要找两遍
    struct Page *result_page; 
    list_entry_t *result_le;
    result_page = NULL;
    list_entry_t *le = head;
    while ((le = list_next(le)) != head) {
        struct Page *page = le2page(le, pra_page_link);
        assert(page != NULL);
        pte_t *pte = get_pte(mm->pgdir, page->pra_vaddr, 0);
        assert(pte != NULL);
        // 如果找到00，直接返回
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
        // 如果当前是1*，则看看有没有找到01，若没有，则把1给赋值为0
        else if (result_page == NULL) {
            *pte &= (~PTE_A);
            tlb_invalidate(mm->pgdir, page->pra_vaddr);
        }
    }
    // 如果第一遍没找到00，找到了01，返回01
    if (result_page != NULL) {
        list_del(result_le);
        *ptr_page = result_page;
        return 0;
    }
    le = head;
    // 第二遍找，第一遍的时候已经把1*给刷成0*了，所以这里不需要再改页表项了
    while ((le = list_next(le)) != head) {
        struct Page *page = le2page(le, pra_page_link);
        pte_t *pte = get_pte(mm->pgdir, page->pra_vaddr, 0);
        if (!(*pte & PTE_A) && !(*pte & PTE_D)) {
            list_del(le);
            *ptr_page = page;
            return 0;
        }
        else if (!(*pte & PTE_A) && (*pte & PTE_D) && result_page == NULL) {
            result_le = le;
            result_page = page;
        }
    }
    if (result_page != NULL) {
        list_del(result_le);
        *ptr_page = result_page;
        return 0;
    }
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