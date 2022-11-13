#include <mmu.h>
#include <memlayout.h>

#define REALLOC(x) (x - KERNBASE)

.text
.globl kern_entry
kern_entry:
    # load pa of boot pgdir
    movl $REALLOC(__boot_pgdir), %eax
    movl %eax, %cr3     # CR3含有存放页目录表页面的物理地址，因此CR3也被称为PDBR。因为页目录表页面是页对齐的，所以该寄存器只有高20位是有效的。而低12位保留供更高级处理器使用，因此在往CR3中加载一个新值时低12位必须设置为0。
                        # 使用MOV指令加载CR3时具有让页高速缓冲(TLB)无效的副作用。
                        # 注意，放的是物理内存地址，主要估计是用于进程切换的时候换页映射。
                        # https://blog.csdn.net/SweeNeil/article/details/106171361
    # enable paging
    # 和开保护模式类似
    # 在mmu.h里面
    movl %cr0, %eax
    orl $(CR0_PE | CR0_PG | CR0_AM | CR0_WP | CR0_NE | CR0_TS | CR0_EM | CR0_MP), %eax
    andl $~(CR0_TS | CR0_EM), %eax
    movl %eax, %cr0

    # update eip
    # now, eip = 0x1.....
    leal next, %eax
    # set eip = KERNBASE + 0x1.....
    jmp *%eax
next:

    # unmap va 0 ~ 4M, it's temporary mapping
    xorl %eax, %eax
    movl %eax, __boot_pgdir

    # set ebp, esp
    movl $0x0, %ebp
    # the kernel stack region is from bootstack -- bootstacktop,
    # the kernel stack size is KSTACKSIZE (8KB)defined in memlayout.h
    movl $bootstacktop, %esp
    # now kernel stack is ready , call the first C function
    call kern_init

# should never get here
spin:
    jmp spin

.data
.align PGSIZE
    .globl bootstack
bootstack:
    .space KSTACKSIZE
    .globl bootstacktop
bootstacktop:

# kernel builtin pgdir
# an initial page directory (Page Directory Table, PDT)
# These page directory table and page table can be reused!
.section .data.pgdir
.align PGSIZE
__boot_pgdir:
.globl __boot_pgdir
    # map va 0 ~ 4M to pa 0 ~ 4M (temporary)
    .long REALLOC(__boot_pt1) + (PTE_P | PTE_U | PTE_W)
    # 下边这个.space是为了填充空隙，因为KERNBASE=0xc000000，它在页目录表中的索引就是KERNBASE>>22，
    # 所以这里就是填字节，从而定位对应的KERNBASE>>22那一个页目录表项（下边的那个.long就是）
    .space (KERNBASE >> PGSHIFT >> 10 << 2) - (. - __boot_pgdir)
    # map va KERNBASE + (0 ~ 4M) to pa 0 ~ 4M
    .long REALLOC(__boot_pt1) + (PTE_P | PTE_U | PTE_W)
    .space PGSIZE - (. - __boot_pgdir) # pad to PGSIZE # 这句话的目的是为了把页目录表刚好填到一页的大小

.set i, 0
__boot_pt1: # 刚好是一页的空间，每一项是一个i * PGSIZE的物理地址，一共能索引1024 * 4K = 4M的空间
.rept 1024
    .long i * PGSIZE + (PTE_P | PTE_W)
    .set i, i + 1
.endr

