
bin/kernel:     file format elf32-i386


Disassembly of section .text:

c0100000 <kern_entry>:

.text
.globl kern_entry
kern_entry:
    # load pa of boot pgdir
    movl $REALLOC(__boot_pgdir), %eax
c0100000:	b8 00 b0 11 00       	mov    $0x11b000,%eax
    movl %eax, %cr3     # CR3含有存放页目录表页面的物理地址，因此CR3也被称为PDBR。因为页目录表页面是页对齐的，所以该寄存器只有高20位是有效的。而低12位保留供更高级处理器使用，因此在往CR3中加载一个新值时低12位必须设置为0。
c0100005:	0f 22 d8             	mov    %eax,%cr3
                        # 注意，放的是物理内存地址，主要估计是用于进程切换的时候换页映射。
                        # https://blog.csdn.net/SweeNeil/article/details/106171361
    # enable paging
    # 和开保护模式类似
    # 在mmu.h里面
    movl %cr0, %eax
c0100008:	0f 20 c0             	mov    %cr0,%eax
    orl $(CR0_PE | CR0_PG | CR0_AM | CR0_WP | CR0_NE | CR0_TS | CR0_EM | CR0_MP), %eax
c010000b:	0d 2f 00 05 80       	or     $0x8005002f,%eax
    andl $~(CR0_TS | CR0_EM), %eax
c0100010:	83 e0 f3             	and    $0xfffffff3,%eax
    movl %eax, %cr0
c0100013:	0f 22 c0             	mov    %eax,%cr0

    # update eip
    # now, eip = 0x1.....
    leal next, %eax
c0100016:	8d 05 1e 00 10 c0    	lea    0xc010001e,%eax
    # set eip = KERNBASE + 0x1.....
    jmp *%eax
c010001c:	ff e0                	jmp    *%eax

c010001e <next>:
next:

    # unmap va 0 ~ 4M, it's temporary mapping
    xorl %eax, %eax
c010001e:	31 c0                	xor    %eax,%eax
    movl %eax, __boot_pgdir
c0100020:	a3 00 b0 11 c0       	mov    %eax,0xc011b000

    # set ebp, esp
    movl $0x0, %ebp
c0100025:	bd 00 00 00 00       	mov    $0x0,%ebp
    # the kernel stack region is from bootstack -- bootstacktop,
    # the kernel stack size is KSTACKSIZE (8KB)defined in memlayout.h
    movl $bootstacktop, %esp
c010002a:	bc 00 a0 11 c0       	mov    $0xc011a000,%esp
    # now kernel stack is ready , call the first C function
    call kern_init
c010002f:	e8 02 00 00 00       	call   c0100036 <kern_init>

c0100034 <spin>:

# should never get here
spin:
    jmp spin
c0100034:	eb fe                	jmp    c0100034 <spin>

c0100036 <kern_init>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);
static void lab1_switch_test(void);

int
kern_init(void) {
c0100036:	55                   	push   %ebp
c0100037:	89 e5                	mov    %esp,%ebp
c0100039:	83 ec 28             	sub    $0x28,%esp
    extern char edata[], end[]; //这俩东西在kernel.ld里
    memset(edata, 0, end - edata);
c010003c:	ba 00 58 12 c0       	mov    $0xc0125800,%edx
c0100041:	b8 00 d0 11 c0       	mov    $0xc011d000,%eax
c0100046:	29 c2                	sub    %eax,%edx
c0100048:	89 d0                	mov    %edx,%eax
c010004a:	89 44 24 08          	mov    %eax,0x8(%esp)
c010004e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0100055:	00 
c0100056:	c7 04 24 00 d0 11 c0 	movl   $0xc011d000,(%esp)
c010005d:	e8 05 71 00 00       	call   c0107167 <memset>

    cons_init();                // init the console
c0100062:	e8 8e 15 00 00       	call   c01015f5 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
c0100067:	c7 45 f4 00 73 10 c0 	movl   $0xc0107300,-0xc(%ebp)
    cprintf("%s\n\n", message);
c010006e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100071:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100075:	c7 04 24 1c 73 10 c0 	movl   $0xc010731c,(%esp)
c010007c:	e8 d3 02 00 00       	call   c0100354 <cprintf>

    print_kerninfo();
c0100081:	e8 02 08 00 00       	call   c0100888 <print_kerninfo>

    grade_backtrace();
c0100086:	e8 8b 00 00 00       	call   c0100116 <grade_backtrace>

    pmm_init();                 // init physical memory management
c010008b:	e8 fc 55 00 00       	call   c010568c <pmm_init>

    pic_init();                 // init interrupt controller
c0100090:	e8 c9 16 00 00       	call   c010175e <pic_init>
    idt_init();                 // init interrupt descriptor table
c0100095:	e8 1b 18 00 00       	call   c01018b5 <idt_init>

    clock_init();               // init clock interrupt
c010009a:	e8 0c 0d 00 00       	call   c0100dab <clock_init>
    intr_enable();              // enable irq interrupt
c010009f:	e8 28 16 00 00       	call   c01016cc <intr_enable>

    //LAB1: CAHLLENGE 1 If you try to do it, uncomment lab1_switch_test()
    // user/kernel mode switch test
    lab1_switch_test();
c01000a4:	e8 69 01 00 00       	call   c0100212 <lab1_switch_test>

    /* do nothing */
    while (1);
c01000a9:	eb fe                	jmp    c01000a9 <kern_init+0x73>

c01000ab <grade_backtrace2>:
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
c01000ab:	55                   	push   %ebp
c01000ac:	89 e5                	mov    %esp,%ebp
c01000ae:	83 ec 18             	sub    $0x18,%esp
    mon_backtrace(0, NULL, NULL);
c01000b1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01000b8:	00 
c01000b9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c01000c0:	00 
c01000c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c01000c8:	e8 ff 0b 00 00       	call   c0100ccc <mon_backtrace>
}
c01000cd:	c9                   	leave  
c01000ce:	c3                   	ret    

c01000cf <grade_backtrace1>:

void __attribute__((noinline))
grade_backtrace1(int arg0, int arg1) {
c01000cf:	55                   	push   %ebp
c01000d0:	89 e5                	mov    %esp,%ebp
c01000d2:	53                   	push   %ebx
c01000d3:	83 ec 14             	sub    $0x14,%esp
    grade_backtrace2(arg0, (int)&arg0, arg1, (int)&arg1);
c01000d6:	8d 5d 0c             	lea    0xc(%ebp),%ebx
c01000d9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
c01000dc:	8d 55 08             	lea    0x8(%ebp),%edx
c01000df:	8b 45 08             	mov    0x8(%ebp),%eax
c01000e2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
c01000e6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c01000ea:	89 54 24 04          	mov    %edx,0x4(%esp)
c01000ee:	89 04 24             	mov    %eax,(%esp)
c01000f1:	e8 b5 ff ff ff       	call   c01000ab <grade_backtrace2>
}
c01000f6:	83 c4 14             	add    $0x14,%esp
c01000f9:	5b                   	pop    %ebx
c01000fa:	5d                   	pop    %ebp
c01000fb:	c3                   	ret    

c01000fc <grade_backtrace0>:

void __attribute__((noinline))
grade_backtrace0(int arg0, int arg1, int arg2) {
c01000fc:	55                   	push   %ebp
c01000fd:	89 e5                	mov    %esp,%ebp
c01000ff:	83 ec 18             	sub    $0x18,%esp
    grade_backtrace1(arg0, arg2);
c0100102:	8b 45 10             	mov    0x10(%ebp),%eax
c0100105:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100109:	8b 45 08             	mov    0x8(%ebp),%eax
c010010c:	89 04 24             	mov    %eax,(%esp)
c010010f:	e8 bb ff ff ff       	call   c01000cf <grade_backtrace1>
}
c0100114:	c9                   	leave  
c0100115:	c3                   	ret    

c0100116 <grade_backtrace>:

void
grade_backtrace(void) {
c0100116:	55                   	push   %ebp
c0100117:	89 e5                	mov    %esp,%ebp
c0100119:	83 ec 18             	sub    $0x18,%esp
    grade_backtrace0(0, (int)kern_init, 0xffff0000);
c010011c:	b8 36 00 10 c0       	mov    $0xc0100036,%eax
c0100121:	c7 44 24 08 00 00 ff 	movl   $0xffff0000,0x8(%esp)
c0100128:	ff 
c0100129:	89 44 24 04          	mov    %eax,0x4(%esp)
c010012d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c0100134:	e8 c3 ff ff ff       	call   c01000fc <grade_backtrace0>
}
c0100139:	c9                   	leave  
c010013a:	c3                   	ret    

c010013b <lab1_print_cur_status>:

static void
lab1_print_cur_status(void) {
c010013b:	55                   	push   %ebp
c010013c:	89 e5                	mov    %esp,%ebp
c010013e:	83 ec 28             	sub    $0x28,%esp
    static int round = 0;
    uint16_t reg1, reg2, reg3, reg4;
    asm volatile (
c0100141:	8c 4d f6             	mov    %cs,-0xa(%ebp)
c0100144:	8c 5d f4             	mov    %ds,-0xc(%ebp)
c0100147:	8c 45 f2             	mov    %es,-0xe(%ebp)
c010014a:	8c 55 f0             	mov    %ss,-0x10(%ebp)
            "mov %%cs, %0;"
            "mov %%ds, %1;"
            "mov %%es, %2;"
            "mov %%ss, %3;"
            : "=m"(reg1), "=m"(reg2), "=m"(reg3), "=m"(reg4));
    cprintf("%d: @ring %d\n", round, reg1 & 3);
c010014d:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100151:	0f b7 c0             	movzwl %ax,%eax
c0100154:	83 e0 03             	and    $0x3,%eax
c0100157:	89 c2                	mov    %eax,%edx
c0100159:	a1 00 d0 11 c0       	mov    0xc011d000,%eax
c010015e:	89 54 24 08          	mov    %edx,0x8(%esp)
c0100162:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100166:	c7 04 24 21 73 10 c0 	movl   $0xc0107321,(%esp)
c010016d:	e8 e2 01 00 00       	call   c0100354 <cprintf>
    cprintf("%d:  cs = %x\n", round, reg1);
c0100172:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100176:	0f b7 d0             	movzwl %ax,%edx
c0100179:	a1 00 d0 11 c0       	mov    0xc011d000,%eax
c010017e:	89 54 24 08          	mov    %edx,0x8(%esp)
c0100182:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100186:	c7 04 24 2f 73 10 c0 	movl   $0xc010732f,(%esp)
c010018d:	e8 c2 01 00 00       	call   c0100354 <cprintf>
    cprintf("%d:  ds = %x\n", round, reg2);
c0100192:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
c0100196:	0f b7 d0             	movzwl %ax,%edx
c0100199:	a1 00 d0 11 c0       	mov    0xc011d000,%eax
c010019e:	89 54 24 08          	mov    %edx,0x8(%esp)
c01001a2:	89 44 24 04          	mov    %eax,0x4(%esp)
c01001a6:	c7 04 24 3d 73 10 c0 	movl   $0xc010733d,(%esp)
c01001ad:	e8 a2 01 00 00       	call   c0100354 <cprintf>
    cprintf("%d:  es = %x\n", round, reg3);
c01001b2:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c01001b6:	0f b7 d0             	movzwl %ax,%edx
c01001b9:	a1 00 d0 11 c0       	mov    0xc011d000,%eax
c01001be:	89 54 24 08          	mov    %edx,0x8(%esp)
c01001c2:	89 44 24 04          	mov    %eax,0x4(%esp)
c01001c6:	c7 04 24 4b 73 10 c0 	movl   $0xc010734b,(%esp)
c01001cd:	e8 82 01 00 00       	call   c0100354 <cprintf>
    cprintf("%d:  ss = %x\n", round, reg4);
c01001d2:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
c01001d6:	0f b7 d0             	movzwl %ax,%edx
c01001d9:	a1 00 d0 11 c0       	mov    0xc011d000,%eax
c01001de:	89 54 24 08          	mov    %edx,0x8(%esp)
c01001e2:	89 44 24 04          	mov    %eax,0x4(%esp)
c01001e6:	c7 04 24 59 73 10 c0 	movl   $0xc0107359,(%esp)
c01001ed:	e8 62 01 00 00       	call   c0100354 <cprintf>
    round ++;
c01001f2:	a1 00 d0 11 c0       	mov    0xc011d000,%eax
c01001f7:	83 c0 01             	add    $0x1,%eax
c01001fa:	a3 00 d0 11 c0       	mov    %eax,0xc011d000
}
c01001ff:	c9                   	leave  
c0100200:	c3                   	ret    

c0100201 <lab1_switch_to_user>:

static void
lab1_switch_to_user(void) {
c0100201:	55                   	push   %ebp
c0100202:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 : TODO
    asm volatile (
c0100204:	16                   	push   %ss
c0100205:	54                   	push   %esp
c0100206:	cd 78                	int    $0x78
            "pushl %%ss\n\t"
            "pushl %%esp\n\t"
            "int %0\n\t"
            ::"i" (T_SWITCH_TOU));
}
c0100208:	5d                   	pop    %ebp
c0100209:	c3                   	ret    

c010020a <lab1_switch_to_kernel>:

static void
lab1_switch_to_kernel(void) {
c010020a:	55                   	push   %ebp
c010020b:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 :  TODO
    asm volatile (
c010020d:	cd 79                	int    $0x79
c010020f:	5c                   	pop    %esp
        "int %0\n\t"
        "popl %%esp\n\t"
        ::"i" (T_SWITCH_TOK));
}
c0100210:	5d                   	pop    %ebp
c0100211:	c3                   	ret    

c0100212 <lab1_switch_test>:

static void
lab1_switch_test(void) {
c0100212:	55                   	push   %ebp
c0100213:	89 e5                	mov    %esp,%ebp
c0100215:	83 ec 18             	sub    $0x18,%esp
    lab1_print_cur_status();
c0100218:	e8 1e ff ff ff       	call   c010013b <lab1_print_cur_status>
    cprintf("+++ switch to  user  mode +++\n");
c010021d:	c7 04 24 68 73 10 c0 	movl   $0xc0107368,(%esp)
c0100224:	e8 2b 01 00 00       	call   c0100354 <cprintf>
    lab1_switch_to_user();
c0100229:	e8 d3 ff ff ff       	call   c0100201 <lab1_switch_to_user>
    lab1_print_cur_status();
c010022e:	e8 08 ff ff ff       	call   c010013b <lab1_print_cur_status>
    cprintf("+++ switch to kernel mode +++\n");
c0100233:	c7 04 24 88 73 10 c0 	movl   $0xc0107388,(%esp)
c010023a:	e8 15 01 00 00       	call   c0100354 <cprintf>
    lab1_switch_to_kernel();
c010023f:	e8 c6 ff ff ff       	call   c010020a <lab1_switch_to_kernel>
    lab1_print_cur_status();
c0100244:	e8 f2 fe ff ff       	call   c010013b <lab1_print_cur_status>
}
c0100249:	c9                   	leave  
c010024a:	c3                   	ret    

c010024b <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
c010024b:	55                   	push   %ebp
c010024c:	89 e5                	mov    %esp,%ebp
c010024e:	83 ec 28             	sub    $0x28,%esp
    if (prompt != NULL) {
c0100251:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0100255:	74 13                	je     c010026a <readline+0x1f>
        cprintf("%s", prompt);
c0100257:	8b 45 08             	mov    0x8(%ebp),%eax
c010025a:	89 44 24 04          	mov    %eax,0x4(%esp)
c010025e:	c7 04 24 a7 73 10 c0 	movl   $0xc01073a7,(%esp)
c0100265:	e8 ea 00 00 00       	call   c0100354 <cprintf>
    }
    int i = 0, c;
c010026a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        c = getchar();
c0100271:	e8 66 01 00 00       	call   c01003dc <getchar>
c0100276:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (c < 0) {
c0100279:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010027d:	79 07                	jns    c0100286 <readline+0x3b>
            return NULL;
c010027f:	b8 00 00 00 00       	mov    $0x0,%eax
c0100284:	eb 79                	jmp    c01002ff <readline+0xb4>
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
c0100286:	83 7d f0 1f          	cmpl   $0x1f,-0x10(%ebp)
c010028a:	7e 28                	jle    c01002b4 <readline+0x69>
c010028c:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
c0100293:	7f 1f                	jg     c01002b4 <readline+0x69>
            cputchar(c);
c0100295:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100298:	89 04 24             	mov    %eax,(%esp)
c010029b:	e8 da 00 00 00       	call   c010037a <cputchar>
            buf[i ++] = c;
c01002a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01002a3:	8d 50 01             	lea    0x1(%eax),%edx
c01002a6:	89 55 f4             	mov    %edx,-0xc(%ebp)
c01002a9:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01002ac:	88 90 20 d0 11 c0    	mov    %dl,-0x3fee2fe0(%eax)
c01002b2:	eb 46                	jmp    c01002fa <readline+0xaf>
        }
        else if (c == '\b' && i > 0) {
c01002b4:	83 7d f0 08          	cmpl   $0x8,-0x10(%ebp)
c01002b8:	75 17                	jne    c01002d1 <readline+0x86>
c01002ba:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01002be:	7e 11                	jle    c01002d1 <readline+0x86>
            cputchar(c);
c01002c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01002c3:	89 04 24             	mov    %eax,(%esp)
c01002c6:	e8 af 00 00 00       	call   c010037a <cputchar>
            i --;
c01002cb:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
c01002cf:	eb 29                	jmp    c01002fa <readline+0xaf>
        }
        else if (c == '\n' || c == '\r') {
c01002d1:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
c01002d5:	74 06                	je     c01002dd <readline+0x92>
c01002d7:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
c01002db:	75 1d                	jne    c01002fa <readline+0xaf>
            cputchar(c);
c01002dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01002e0:	89 04 24             	mov    %eax,(%esp)
c01002e3:	e8 92 00 00 00       	call   c010037a <cputchar>
            buf[i] = '\0';
c01002e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01002eb:	05 20 d0 11 c0       	add    $0xc011d020,%eax
c01002f0:	c6 00 00             	movb   $0x0,(%eax)
            return buf;
c01002f3:	b8 20 d0 11 c0       	mov    $0xc011d020,%eax
c01002f8:	eb 05                	jmp    c01002ff <readline+0xb4>
        }
    }
c01002fa:	e9 72 ff ff ff       	jmp    c0100271 <readline+0x26>
}
c01002ff:	c9                   	leave  
c0100300:	c3                   	ret    

c0100301 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
c0100301:	55                   	push   %ebp
c0100302:	89 e5                	mov    %esp,%ebp
c0100304:	83 ec 18             	sub    $0x18,%esp
    cons_putc(c);
c0100307:	8b 45 08             	mov    0x8(%ebp),%eax
c010030a:	89 04 24             	mov    %eax,(%esp)
c010030d:	e8 0f 13 00 00       	call   c0101621 <cons_putc>
    (*cnt) ++;
c0100312:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100315:	8b 00                	mov    (%eax),%eax
c0100317:	8d 50 01             	lea    0x1(%eax),%edx
c010031a:	8b 45 0c             	mov    0xc(%ebp),%eax
c010031d:	89 10                	mov    %edx,(%eax)
}
c010031f:	c9                   	leave  
c0100320:	c3                   	ret    

c0100321 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
c0100321:	55                   	push   %ebp
c0100322:	89 e5                	mov    %esp,%ebp
c0100324:	83 ec 28             	sub    $0x28,%esp
    int cnt = 0;
c0100327:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
c010032e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100331:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0100335:	8b 45 08             	mov    0x8(%ebp),%eax
c0100338:	89 44 24 08          	mov    %eax,0x8(%esp)
c010033c:	8d 45 f4             	lea    -0xc(%ebp),%eax
c010033f:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100343:	c7 04 24 01 03 10 c0 	movl   $0xc0100301,(%esp)
c010034a:	e8 31 66 00 00       	call   c0106980 <vprintfmt>
    return cnt;
c010034f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0100352:	c9                   	leave  
c0100353:	c3                   	ret    

c0100354 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
c0100354:	55                   	push   %ebp
c0100355:	89 e5                	mov    %esp,%ebp
c0100357:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
c010035a:	8d 45 0c             	lea    0xc(%ebp),%eax
c010035d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vcprintf(fmt, ap);
c0100360:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100363:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100367:	8b 45 08             	mov    0x8(%ebp),%eax
c010036a:	89 04 24             	mov    %eax,(%esp)
c010036d:	e8 af ff ff ff       	call   c0100321 <vcprintf>
c0100372:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
c0100375:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0100378:	c9                   	leave  
c0100379:	c3                   	ret    

c010037a <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
c010037a:	55                   	push   %ebp
c010037b:	89 e5                	mov    %esp,%ebp
c010037d:	83 ec 18             	sub    $0x18,%esp
    cons_putc(c);
c0100380:	8b 45 08             	mov    0x8(%ebp),%eax
c0100383:	89 04 24             	mov    %eax,(%esp)
c0100386:	e8 96 12 00 00       	call   c0101621 <cons_putc>
}
c010038b:	c9                   	leave  
c010038c:	c3                   	ret    

c010038d <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
c010038d:	55                   	push   %ebp
c010038e:	89 e5                	mov    %esp,%ebp
c0100390:	83 ec 28             	sub    $0x28,%esp
    int cnt = 0;
c0100393:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    char c;
    while ((c = *str ++) != '\0') {
c010039a:	eb 13                	jmp    c01003af <cputs+0x22>
        cputch(c, &cnt);
c010039c:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c01003a0:	8d 55 f0             	lea    -0x10(%ebp),%edx
c01003a3:	89 54 24 04          	mov    %edx,0x4(%esp)
c01003a7:	89 04 24             	mov    %eax,(%esp)
c01003aa:	e8 52 ff ff ff       	call   c0100301 <cputch>
 * */
int
cputs(const char *str) {
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
c01003af:	8b 45 08             	mov    0x8(%ebp),%eax
c01003b2:	8d 50 01             	lea    0x1(%eax),%edx
c01003b5:	89 55 08             	mov    %edx,0x8(%ebp)
c01003b8:	0f b6 00             	movzbl (%eax),%eax
c01003bb:	88 45 f7             	mov    %al,-0x9(%ebp)
c01003be:	80 7d f7 00          	cmpb   $0x0,-0x9(%ebp)
c01003c2:	75 d8                	jne    c010039c <cputs+0xf>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
c01003c4:	8d 45 f0             	lea    -0x10(%ebp),%eax
c01003c7:	89 44 24 04          	mov    %eax,0x4(%esp)
c01003cb:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
c01003d2:	e8 2a ff ff ff       	call   c0100301 <cputch>
    return cnt;
c01003d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
c01003da:	c9                   	leave  
c01003db:	c3                   	ret    

c01003dc <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
c01003dc:	55                   	push   %ebp
c01003dd:	89 e5                	mov    %esp,%ebp
c01003df:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = cons_getc()) == 0)
c01003e2:	e8 76 12 00 00       	call   c010165d <cons_getc>
c01003e7:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01003ea:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01003ee:	74 f2                	je     c01003e2 <getchar+0x6>
        /* do nothing */;
    return c;
c01003f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01003f3:	c9                   	leave  
c01003f4:	c3                   	ret    

c01003f5 <stab_binsearch>:
 *      stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
 * will exit setting left = 118, right = 554.
 * */
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
c01003f5:	55                   	push   %ebp
c01003f6:	89 e5                	mov    %esp,%ebp
c01003f8:	83 ec 20             	sub    $0x20,%esp
    int l = *region_left, r = *region_right, any_matches = 0;
c01003fb:	8b 45 0c             	mov    0xc(%ebp),%eax
c01003fe:	8b 00                	mov    (%eax),%eax
c0100400:	89 45 fc             	mov    %eax,-0x4(%ebp)
c0100403:	8b 45 10             	mov    0x10(%ebp),%eax
c0100406:	8b 00                	mov    (%eax),%eax
c0100408:	89 45 f8             	mov    %eax,-0x8(%ebp)
c010040b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

    while (l <= r) {
c0100412:	e9 d2 00 00 00       	jmp    c01004e9 <stab_binsearch+0xf4>
        int true_m = (l + r) / 2, m = true_m;
c0100417:	8b 45 f8             	mov    -0x8(%ebp),%eax
c010041a:	8b 55 fc             	mov    -0x4(%ebp),%edx
c010041d:	01 d0                	add    %edx,%eax
c010041f:	89 c2                	mov    %eax,%edx
c0100421:	c1 ea 1f             	shr    $0x1f,%edx
c0100424:	01 d0                	add    %edx,%eax
c0100426:	d1 f8                	sar    %eax
c0100428:	89 45 ec             	mov    %eax,-0x14(%ebp)
c010042b:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010042e:	89 45 f0             	mov    %eax,-0x10(%ebp)

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
c0100431:	eb 04                	jmp    c0100437 <stab_binsearch+0x42>
            m --;
c0100433:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)

    while (l <= r) {
        int true_m = (l + r) / 2, m = true_m;

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
c0100437:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010043a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
c010043d:	7c 1f                	jl     c010045e <stab_binsearch+0x69>
c010043f:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100442:	89 d0                	mov    %edx,%eax
c0100444:	01 c0                	add    %eax,%eax
c0100446:	01 d0                	add    %edx,%eax
c0100448:	c1 e0 02             	shl    $0x2,%eax
c010044b:	89 c2                	mov    %eax,%edx
c010044d:	8b 45 08             	mov    0x8(%ebp),%eax
c0100450:	01 d0                	add    %edx,%eax
c0100452:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c0100456:	0f b6 c0             	movzbl %al,%eax
c0100459:	3b 45 14             	cmp    0x14(%ebp),%eax
c010045c:	75 d5                	jne    c0100433 <stab_binsearch+0x3e>
            m --;
        }
        if (m < l) {    // no match in [l, m]
c010045e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100461:	3b 45 fc             	cmp    -0x4(%ebp),%eax
c0100464:	7d 0b                	jge    c0100471 <stab_binsearch+0x7c>
            l = true_m + 1;
c0100466:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100469:	83 c0 01             	add    $0x1,%eax
c010046c:	89 45 fc             	mov    %eax,-0x4(%ebp)
            continue;
c010046f:	eb 78                	jmp    c01004e9 <stab_binsearch+0xf4>
        }

        // actual binary search
        any_matches = 1;
c0100471:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
        if (stabs[m].n_value < addr) {
c0100478:	8b 55 f0             	mov    -0x10(%ebp),%edx
c010047b:	89 d0                	mov    %edx,%eax
c010047d:	01 c0                	add    %eax,%eax
c010047f:	01 d0                	add    %edx,%eax
c0100481:	c1 e0 02             	shl    $0x2,%eax
c0100484:	89 c2                	mov    %eax,%edx
c0100486:	8b 45 08             	mov    0x8(%ebp),%eax
c0100489:	01 d0                	add    %edx,%eax
c010048b:	8b 40 08             	mov    0x8(%eax),%eax
c010048e:	3b 45 18             	cmp    0x18(%ebp),%eax
c0100491:	73 13                	jae    c01004a6 <stab_binsearch+0xb1>
            *region_left = m;
c0100493:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100496:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100499:	89 10                	mov    %edx,(%eax)
            l = true_m + 1;
c010049b:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010049e:	83 c0 01             	add    $0x1,%eax
c01004a1:	89 45 fc             	mov    %eax,-0x4(%ebp)
c01004a4:	eb 43                	jmp    c01004e9 <stab_binsearch+0xf4>
        } else if (stabs[m].n_value > addr) {
c01004a6:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01004a9:	89 d0                	mov    %edx,%eax
c01004ab:	01 c0                	add    %eax,%eax
c01004ad:	01 d0                	add    %edx,%eax
c01004af:	c1 e0 02             	shl    $0x2,%eax
c01004b2:	89 c2                	mov    %eax,%edx
c01004b4:	8b 45 08             	mov    0x8(%ebp),%eax
c01004b7:	01 d0                	add    %edx,%eax
c01004b9:	8b 40 08             	mov    0x8(%eax),%eax
c01004bc:	3b 45 18             	cmp    0x18(%ebp),%eax
c01004bf:	76 16                	jbe    c01004d7 <stab_binsearch+0xe2>
            *region_right = m - 1;
c01004c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01004c4:	8d 50 ff             	lea    -0x1(%eax),%edx
c01004c7:	8b 45 10             	mov    0x10(%ebp),%eax
c01004ca:	89 10                	mov    %edx,(%eax)
            r = m - 1;
c01004cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01004cf:	83 e8 01             	sub    $0x1,%eax
c01004d2:	89 45 f8             	mov    %eax,-0x8(%ebp)
c01004d5:	eb 12                	jmp    c01004e9 <stab_binsearch+0xf4>
        } else {
            // exact match for 'addr', but continue loop to find
            // *region_right
            *region_left = m;
c01004d7:	8b 45 0c             	mov    0xc(%ebp),%eax
c01004da:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01004dd:	89 10                	mov    %edx,(%eax)
            l = m;
c01004df:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01004e2:	89 45 fc             	mov    %eax,-0x4(%ebp)
            addr ++;
c01004e5:	83 45 18 01          	addl   $0x1,0x18(%ebp)
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
    int l = *region_left, r = *region_right, any_matches = 0;

    while (l <= r) {
c01004e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01004ec:	3b 45 f8             	cmp    -0x8(%ebp),%eax
c01004ef:	0f 8e 22 ff ff ff    	jle    c0100417 <stab_binsearch+0x22>
            l = m;
            addr ++;
        }
    }

    if (!any_matches) {
c01004f5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01004f9:	75 0f                	jne    c010050a <stab_binsearch+0x115>
        *region_right = *region_left - 1;
c01004fb:	8b 45 0c             	mov    0xc(%ebp),%eax
c01004fe:	8b 00                	mov    (%eax),%eax
c0100500:	8d 50 ff             	lea    -0x1(%eax),%edx
c0100503:	8b 45 10             	mov    0x10(%ebp),%eax
c0100506:	89 10                	mov    %edx,(%eax)
c0100508:	eb 3f                	jmp    c0100549 <stab_binsearch+0x154>
    }
    else {
        // find rightmost region containing 'addr'
        l = *region_right;
c010050a:	8b 45 10             	mov    0x10(%ebp),%eax
c010050d:	8b 00                	mov    (%eax),%eax
c010050f:	89 45 fc             	mov    %eax,-0x4(%ebp)
        for (; l > *region_left && stabs[l].n_type != type; l --)
c0100512:	eb 04                	jmp    c0100518 <stab_binsearch+0x123>
c0100514:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
c0100518:	8b 45 0c             	mov    0xc(%ebp),%eax
c010051b:	8b 00                	mov    (%eax),%eax
c010051d:	3b 45 fc             	cmp    -0x4(%ebp),%eax
c0100520:	7d 1f                	jge    c0100541 <stab_binsearch+0x14c>
c0100522:	8b 55 fc             	mov    -0x4(%ebp),%edx
c0100525:	89 d0                	mov    %edx,%eax
c0100527:	01 c0                	add    %eax,%eax
c0100529:	01 d0                	add    %edx,%eax
c010052b:	c1 e0 02             	shl    $0x2,%eax
c010052e:	89 c2                	mov    %eax,%edx
c0100530:	8b 45 08             	mov    0x8(%ebp),%eax
c0100533:	01 d0                	add    %edx,%eax
c0100535:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c0100539:	0f b6 c0             	movzbl %al,%eax
c010053c:	3b 45 14             	cmp    0x14(%ebp),%eax
c010053f:	75 d3                	jne    c0100514 <stab_binsearch+0x11f>
            /* do nothing */;
        *region_left = l;
c0100541:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100544:	8b 55 fc             	mov    -0x4(%ebp),%edx
c0100547:	89 10                	mov    %edx,(%eax)
    }
}
c0100549:	c9                   	leave  
c010054a:	c3                   	ret    

c010054b <debuginfo_eip>:
 * the specified instruction address, @addr.  Returns 0 if information
 * was found, and negative if not.  But even if it returns negative it
 * has stored some information into '*info'.
 * */
int
debuginfo_eip(uintptr_t addr, struct eipdebuginfo *info) {
c010054b:	55                   	push   %ebp
c010054c:	89 e5                	mov    %esp,%ebp
c010054e:	83 ec 58             	sub    $0x58,%esp
    const struct stab *stabs, *stab_end;
    const char *stabstr, *stabstr_end;

    info->eip_file = "<unknown>";
c0100551:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100554:	c7 00 ac 73 10 c0    	movl   $0xc01073ac,(%eax)
    info->eip_line = 0;
c010055a:	8b 45 0c             	mov    0xc(%ebp),%eax
c010055d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
    info->eip_fn_name = "<unknown>";
c0100564:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100567:	c7 40 08 ac 73 10 c0 	movl   $0xc01073ac,0x8(%eax)
    info->eip_fn_namelen = 9;
c010056e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100571:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
    info->eip_fn_addr = addr;
c0100578:	8b 45 0c             	mov    0xc(%ebp),%eax
c010057b:	8b 55 08             	mov    0x8(%ebp),%edx
c010057e:	89 50 10             	mov    %edx,0x10(%eax)
    info->eip_fn_narg = 0;
c0100581:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100584:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

    stabs = __STAB_BEGIN__;
c010058b:	c7 45 f4 48 8a 10 c0 	movl   $0xc0108a48,-0xc(%ebp)
    stab_end = __STAB_END__;
c0100592:	c7 45 f0 50 4b 11 c0 	movl   $0xc0114b50,-0x10(%ebp)
    stabstr = __STABSTR_BEGIN__;
c0100599:	c7 45 ec 51 4b 11 c0 	movl   $0xc0114b51,-0x14(%ebp)
    stabstr_end = __STABSTR_END__;
c01005a0:	c7 45 e8 17 78 11 c0 	movl   $0xc0117817,-0x18(%ebp)

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0) {
c01005a7:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01005aa:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c01005ad:	76 0d                	jbe    c01005bc <debuginfo_eip+0x71>
c01005af:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01005b2:	83 e8 01             	sub    $0x1,%eax
c01005b5:	0f b6 00             	movzbl (%eax),%eax
c01005b8:	84 c0                	test   %al,%al
c01005ba:	74 0a                	je     c01005c6 <debuginfo_eip+0x7b>
        return -1;
c01005bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c01005c1:	e9 c0 02 00 00       	jmp    c0100886 <debuginfo_eip+0x33b>
    // 'eip'.  First, we find the basic source file containing 'eip'.
    // Then, we look in that source file for the function.  Then we look
    // for the line number.

    // Search the entire set of stabs for the source file (type N_SO).
    int lfile = 0, rfile = (stab_end - stabs) - 1;
c01005c6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
c01005cd:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01005d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01005d3:	29 c2                	sub    %eax,%edx
c01005d5:	89 d0                	mov    %edx,%eax
c01005d7:	c1 f8 02             	sar    $0x2,%eax
c01005da:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
c01005e0:	83 e8 01             	sub    $0x1,%eax
c01005e3:	89 45 e0             	mov    %eax,-0x20(%ebp)
    stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
c01005e6:	8b 45 08             	mov    0x8(%ebp),%eax
c01005e9:	89 44 24 10          	mov    %eax,0x10(%esp)
c01005ed:	c7 44 24 0c 64 00 00 	movl   $0x64,0xc(%esp)
c01005f4:	00 
c01005f5:	8d 45 e0             	lea    -0x20(%ebp),%eax
c01005f8:	89 44 24 08          	mov    %eax,0x8(%esp)
c01005fc:	8d 45 e4             	lea    -0x1c(%ebp),%eax
c01005ff:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100603:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100606:	89 04 24             	mov    %eax,(%esp)
c0100609:	e8 e7 fd ff ff       	call   c01003f5 <stab_binsearch>
    if (lfile == 0)
c010060e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100611:	85 c0                	test   %eax,%eax
c0100613:	75 0a                	jne    c010061f <debuginfo_eip+0xd4>
        return -1;
c0100615:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c010061a:	e9 67 02 00 00       	jmp    c0100886 <debuginfo_eip+0x33b>

    // Search within that file's stabs for the function definition
    // (N_FUN).
    int lfun = lfile, rfun = rfile;
c010061f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100622:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0100625:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0100628:	89 45 d8             	mov    %eax,-0x28(%ebp)
    int lline, rline;
    stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
c010062b:	8b 45 08             	mov    0x8(%ebp),%eax
c010062e:	89 44 24 10          	mov    %eax,0x10(%esp)
c0100632:	c7 44 24 0c 24 00 00 	movl   $0x24,0xc(%esp)
c0100639:	00 
c010063a:	8d 45 d8             	lea    -0x28(%ebp),%eax
c010063d:	89 44 24 08          	mov    %eax,0x8(%esp)
c0100641:	8d 45 dc             	lea    -0x24(%ebp),%eax
c0100644:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100648:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010064b:	89 04 24             	mov    %eax,(%esp)
c010064e:	e8 a2 fd ff ff       	call   c01003f5 <stab_binsearch>

    if (lfun <= rfun) {
c0100653:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0100656:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0100659:	39 c2                	cmp    %eax,%edx
c010065b:	7f 7c                	jg     c01006d9 <debuginfo_eip+0x18e>
        // stabs[lfun] points to the function name
        // in the string table, but check bounds just in case.
        if (stabs[lfun].n_strx < stabstr_end - stabstr) {
c010065d:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100660:	89 c2                	mov    %eax,%edx
c0100662:	89 d0                	mov    %edx,%eax
c0100664:	01 c0                	add    %eax,%eax
c0100666:	01 d0                	add    %edx,%eax
c0100668:	c1 e0 02             	shl    $0x2,%eax
c010066b:	89 c2                	mov    %eax,%edx
c010066d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100670:	01 d0                	add    %edx,%eax
c0100672:	8b 10                	mov    (%eax),%edx
c0100674:	8b 4d e8             	mov    -0x18(%ebp),%ecx
c0100677:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010067a:	29 c1                	sub    %eax,%ecx
c010067c:	89 c8                	mov    %ecx,%eax
c010067e:	39 c2                	cmp    %eax,%edx
c0100680:	73 22                	jae    c01006a4 <debuginfo_eip+0x159>
            info->eip_fn_name = stabstr + stabs[lfun].n_strx;
c0100682:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100685:	89 c2                	mov    %eax,%edx
c0100687:	89 d0                	mov    %edx,%eax
c0100689:	01 c0                	add    %eax,%eax
c010068b:	01 d0                	add    %edx,%eax
c010068d:	c1 e0 02             	shl    $0x2,%eax
c0100690:	89 c2                	mov    %eax,%edx
c0100692:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100695:	01 d0                	add    %edx,%eax
c0100697:	8b 10                	mov    (%eax),%edx
c0100699:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010069c:	01 c2                	add    %eax,%edx
c010069e:	8b 45 0c             	mov    0xc(%ebp),%eax
c01006a1:	89 50 08             	mov    %edx,0x8(%eax)
        }
        info->eip_fn_addr = stabs[lfun].n_value;
c01006a4:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01006a7:	89 c2                	mov    %eax,%edx
c01006a9:	89 d0                	mov    %edx,%eax
c01006ab:	01 c0                	add    %eax,%eax
c01006ad:	01 d0                	add    %edx,%eax
c01006af:	c1 e0 02             	shl    $0x2,%eax
c01006b2:	89 c2                	mov    %eax,%edx
c01006b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01006b7:	01 d0                	add    %edx,%eax
c01006b9:	8b 50 08             	mov    0x8(%eax),%edx
c01006bc:	8b 45 0c             	mov    0xc(%ebp),%eax
c01006bf:	89 50 10             	mov    %edx,0x10(%eax)
        addr -= info->eip_fn_addr;
c01006c2:	8b 45 0c             	mov    0xc(%ebp),%eax
c01006c5:	8b 40 10             	mov    0x10(%eax),%eax
c01006c8:	29 45 08             	sub    %eax,0x8(%ebp)
        // Search within the function definition for the line number.
        lline = lfun;
c01006cb:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01006ce:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfun;
c01006d1:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01006d4:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01006d7:	eb 15                	jmp    c01006ee <debuginfo_eip+0x1a3>
    } else {
        // Couldn't find function stab!  Maybe we're in an assembly
        // file.  Search the whole file for the line number.
        info->eip_fn_addr = addr;
c01006d9:	8b 45 0c             	mov    0xc(%ebp),%eax
c01006dc:	8b 55 08             	mov    0x8(%ebp),%edx
c01006df:	89 50 10             	mov    %edx,0x10(%eax)
        lline = lfile;
c01006e2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01006e5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfile;
c01006e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01006eb:	89 45 d0             	mov    %eax,-0x30(%ebp)
    }
    info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
c01006ee:	8b 45 0c             	mov    0xc(%ebp),%eax
c01006f1:	8b 40 08             	mov    0x8(%eax),%eax
c01006f4:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
c01006fb:	00 
c01006fc:	89 04 24             	mov    %eax,(%esp)
c01006ff:	e8 d7 68 00 00       	call   c0106fdb <strfind>
c0100704:	89 c2                	mov    %eax,%edx
c0100706:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100709:	8b 40 08             	mov    0x8(%eax),%eax
c010070c:	29 c2                	sub    %eax,%edx
c010070e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100711:	89 50 0c             	mov    %edx,0xc(%eax)

    // Search within [lline, rline] for the line number stab.
    // If found, set info->eip_line to the right line number.
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
c0100714:	8b 45 08             	mov    0x8(%ebp),%eax
c0100717:	89 44 24 10          	mov    %eax,0x10(%esp)
c010071b:	c7 44 24 0c 44 00 00 	movl   $0x44,0xc(%esp)
c0100722:	00 
c0100723:	8d 45 d0             	lea    -0x30(%ebp),%eax
c0100726:	89 44 24 08          	mov    %eax,0x8(%esp)
c010072a:	8d 45 d4             	lea    -0x2c(%ebp),%eax
c010072d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100731:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100734:	89 04 24             	mov    %eax,(%esp)
c0100737:	e8 b9 fc ff ff       	call   c01003f5 <stab_binsearch>
    if (lline <= rline) {
c010073c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c010073f:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0100742:	39 c2                	cmp    %eax,%edx
c0100744:	7f 24                	jg     c010076a <debuginfo_eip+0x21f>
        info->eip_line = stabs[rline].n_desc;
c0100746:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0100749:	89 c2                	mov    %eax,%edx
c010074b:	89 d0                	mov    %edx,%eax
c010074d:	01 c0                	add    %eax,%eax
c010074f:	01 d0                	add    %edx,%eax
c0100751:	c1 e0 02             	shl    $0x2,%eax
c0100754:	89 c2                	mov    %eax,%edx
c0100756:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100759:	01 d0                	add    %edx,%eax
c010075b:	0f b7 40 06          	movzwl 0x6(%eax),%eax
c010075f:	0f b7 d0             	movzwl %ax,%edx
c0100762:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100765:	89 50 04             	mov    %edx,0x4(%eax)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
c0100768:	eb 13                	jmp    c010077d <debuginfo_eip+0x232>
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
    if (lline <= rline) {
        info->eip_line = stabs[rline].n_desc;
    } else {
        return -1;
c010076a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c010076f:	e9 12 01 00 00       	jmp    c0100886 <debuginfo_eip+0x33b>
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
           && stabs[lline].n_type != N_SOL
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
        lline --;
c0100774:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100777:	83 e8 01             	sub    $0x1,%eax
c010077a:	89 45 d4             	mov    %eax,-0x2c(%ebp)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
c010077d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0100780:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100783:	39 c2                	cmp    %eax,%edx
c0100785:	7c 56                	jl     c01007dd <debuginfo_eip+0x292>
           && stabs[lline].n_type != N_SOL
c0100787:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010078a:	89 c2                	mov    %eax,%edx
c010078c:	89 d0                	mov    %edx,%eax
c010078e:	01 c0                	add    %eax,%eax
c0100790:	01 d0                	add    %edx,%eax
c0100792:	c1 e0 02             	shl    $0x2,%eax
c0100795:	89 c2                	mov    %eax,%edx
c0100797:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010079a:	01 d0                	add    %edx,%eax
c010079c:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c01007a0:	3c 84                	cmp    $0x84,%al
c01007a2:	74 39                	je     c01007dd <debuginfo_eip+0x292>
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
c01007a4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01007a7:	89 c2                	mov    %eax,%edx
c01007a9:	89 d0                	mov    %edx,%eax
c01007ab:	01 c0                	add    %eax,%eax
c01007ad:	01 d0                	add    %edx,%eax
c01007af:	c1 e0 02             	shl    $0x2,%eax
c01007b2:	89 c2                	mov    %eax,%edx
c01007b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01007b7:	01 d0                	add    %edx,%eax
c01007b9:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c01007bd:	3c 64                	cmp    $0x64,%al
c01007bf:	75 b3                	jne    c0100774 <debuginfo_eip+0x229>
c01007c1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01007c4:	89 c2                	mov    %eax,%edx
c01007c6:	89 d0                	mov    %edx,%eax
c01007c8:	01 c0                	add    %eax,%eax
c01007ca:	01 d0                	add    %edx,%eax
c01007cc:	c1 e0 02             	shl    $0x2,%eax
c01007cf:	89 c2                	mov    %eax,%edx
c01007d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01007d4:	01 d0                	add    %edx,%eax
c01007d6:	8b 40 08             	mov    0x8(%eax),%eax
c01007d9:	85 c0                	test   %eax,%eax
c01007db:	74 97                	je     c0100774 <debuginfo_eip+0x229>
        lline --;
    }
    if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr) {
c01007dd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01007e0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01007e3:	39 c2                	cmp    %eax,%edx
c01007e5:	7c 46                	jl     c010082d <debuginfo_eip+0x2e2>
c01007e7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01007ea:	89 c2                	mov    %eax,%edx
c01007ec:	89 d0                	mov    %edx,%eax
c01007ee:	01 c0                	add    %eax,%eax
c01007f0:	01 d0                	add    %edx,%eax
c01007f2:	c1 e0 02             	shl    $0x2,%eax
c01007f5:	89 c2                	mov    %eax,%edx
c01007f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01007fa:	01 d0                	add    %edx,%eax
c01007fc:	8b 10                	mov    (%eax),%edx
c01007fe:	8b 4d e8             	mov    -0x18(%ebp),%ecx
c0100801:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100804:	29 c1                	sub    %eax,%ecx
c0100806:	89 c8                	mov    %ecx,%eax
c0100808:	39 c2                	cmp    %eax,%edx
c010080a:	73 21                	jae    c010082d <debuginfo_eip+0x2e2>
        info->eip_file = stabstr + stabs[lline].n_strx;
c010080c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010080f:	89 c2                	mov    %eax,%edx
c0100811:	89 d0                	mov    %edx,%eax
c0100813:	01 c0                	add    %eax,%eax
c0100815:	01 d0                	add    %edx,%eax
c0100817:	c1 e0 02             	shl    $0x2,%eax
c010081a:	89 c2                	mov    %eax,%edx
c010081c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010081f:	01 d0                	add    %edx,%eax
c0100821:	8b 10                	mov    (%eax),%edx
c0100823:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100826:	01 c2                	add    %eax,%edx
c0100828:	8b 45 0c             	mov    0xc(%ebp),%eax
c010082b:	89 10                	mov    %edx,(%eax)
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
c010082d:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0100830:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0100833:	39 c2                	cmp    %eax,%edx
c0100835:	7d 4a                	jge    c0100881 <debuginfo_eip+0x336>
        for (lline = lfun + 1;
c0100837:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010083a:	83 c0 01             	add    $0x1,%eax
c010083d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
c0100840:	eb 18                	jmp    c010085a <debuginfo_eip+0x30f>
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
            info->eip_fn_narg ++;
c0100842:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100845:	8b 40 14             	mov    0x14(%eax),%eax
c0100848:	8d 50 01             	lea    0x1(%eax),%edx
c010084b:	8b 45 0c             	mov    0xc(%ebp),%eax
c010084e:	89 50 14             	mov    %edx,0x14(%eax)
    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
c0100851:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100854:	83 c0 01             	add    $0x1,%eax
c0100857:	89 45 d4             	mov    %eax,-0x2c(%ebp)

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM;
c010085a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c010085d:	8b 45 d8             	mov    -0x28(%ebp),%eax
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
c0100860:	39 c2                	cmp    %eax,%edx
c0100862:	7d 1d                	jge    c0100881 <debuginfo_eip+0x336>
             lline < rfun && stabs[lline].n_type == N_PSYM;
c0100864:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100867:	89 c2                	mov    %eax,%edx
c0100869:	89 d0                	mov    %edx,%eax
c010086b:	01 c0                	add    %eax,%eax
c010086d:	01 d0                	add    %edx,%eax
c010086f:	c1 e0 02             	shl    $0x2,%eax
c0100872:	89 c2                	mov    %eax,%edx
c0100874:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100877:	01 d0                	add    %edx,%eax
c0100879:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c010087d:	3c a0                	cmp    $0xa0,%al
c010087f:	74 c1                	je     c0100842 <debuginfo_eip+0x2f7>
             lline ++) {
            info->eip_fn_narg ++;
        }
    }
    return 0;
c0100881:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100886:	c9                   	leave  
c0100887:	c3                   	ret    

c0100888 <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void
print_kerninfo(void) {
c0100888:	55                   	push   %ebp
c0100889:	89 e5                	mov    %esp,%ebp
c010088b:	83 ec 18             	sub    $0x18,%esp
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
c010088e:	c7 04 24 b6 73 10 c0 	movl   $0xc01073b6,(%esp)
c0100895:	e8 ba fa ff ff       	call   c0100354 <cprintf>
    cprintf("  entry  0x%08x (phys)\n", kern_init);
c010089a:	c7 44 24 04 36 00 10 	movl   $0xc0100036,0x4(%esp)
c01008a1:	c0 
c01008a2:	c7 04 24 cf 73 10 c0 	movl   $0xc01073cf,(%esp)
c01008a9:	e8 a6 fa ff ff       	call   c0100354 <cprintf>
    cprintf("  etext  0x%08x (phys)\n", etext);
c01008ae:	c7 44 24 04 f0 72 10 	movl   $0xc01072f0,0x4(%esp)
c01008b5:	c0 
c01008b6:	c7 04 24 e7 73 10 c0 	movl   $0xc01073e7,(%esp)
c01008bd:	e8 92 fa ff ff       	call   c0100354 <cprintf>
    cprintf("  edata  0x%08x (phys)\n", edata);
c01008c2:	c7 44 24 04 00 d0 11 	movl   $0xc011d000,0x4(%esp)
c01008c9:	c0 
c01008ca:	c7 04 24 ff 73 10 c0 	movl   $0xc01073ff,(%esp)
c01008d1:	e8 7e fa ff ff       	call   c0100354 <cprintf>
    cprintf("  end    0x%08x (phys)\n", end);
c01008d6:	c7 44 24 04 00 58 12 	movl   $0xc0125800,0x4(%esp)
c01008dd:	c0 
c01008de:	c7 04 24 17 74 10 c0 	movl   $0xc0107417,(%esp)
c01008e5:	e8 6a fa ff ff       	call   c0100354 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n", (end - kern_init + 1023)/1024);
c01008ea:	b8 00 58 12 c0       	mov    $0xc0125800,%eax
c01008ef:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
c01008f5:	b8 36 00 10 c0       	mov    $0xc0100036,%eax
c01008fa:	29 c2                	sub    %eax,%edx
c01008fc:	89 d0                	mov    %edx,%eax
c01008fe:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
c0100904:	85 c0                	test   %eax,%eax
c0100906:	0f 48 c2             	cmovs  %edx,%eax
c0100909:	c1 f8 0a             	sar    $0xa,%eax
c010090c:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100910:	c7 04 24 30 74 10 c0 	movl   $0xc0107430,(%esp)
c0100917:	e8 38 fa ff ff       	call   c0100354 <cprintf>
}
c010091c:	c9                   	leave  
c010091d:	c3                   	ret    

c010091e <print_debuginfo>:
/* *
 * print_debuginfo - read and print the stat information for the address @eip,
 * and info.eip_fn_addr should be the first address of the related function.
 * */
void
print_debuginfo(uintptr_t eip) {
c010091e:	55                   	push   %ebp
c010091f:	89 e5                	mov    %esp,%ebp
c0100921:	81 ec 48 01 00 00    	sub    $0x148,%esp
    struct eipdebuginfo info;
    if (debuginfo_eip(eip, &info) != 0) {
c0100927:	8d 45 dc             	lea    -0x24(%ebp),%eax
c010092a:	89 44 24 04          	mov    %eax,0x4(%esp)
c010092e:	8b 45 08             	mov    0x8(%ebp),%eax
c0100931:	89 04 24             	mov    %eax,(%esp)
c0100934:	e8 12 fc ff ff       	call   c010054b <debuginfo_eip>
c0100939:	85 c0                	test   %eax,%eax
c010093b:	74 15                	je     c0100952 <print_debuginfo+0x34>
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
c010093d:	8b 45 08             	mov    0x8(%ebp),%eax
c0100940:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100944:	c7 04 24 5a 74 10 c0 	movl   $0xc010745a,(%esp)
c010094b:	e8 04 fa ff ff       	call   c0100354 <cprintf>
c0100950:	eb 6d                	jmp    c01009bf <print_debuginfo+0xa1>
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
c0100952:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0100959:	eb 1c                	jmp    c0100977 <print_debuginfo+0x59>
            fnname[j] = info.eip_fn_name[j];
c010095b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c010095e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100961:	01 d0                	add    %edx,%eax
c0100963:	0f b6 00             	movzbl (%eax),%eax
c0100966:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
c010096c:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010096f:	01 ca                	add    %ecx,%edx
c0100971:	88 02                	mov    %al,(%edx)
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
c0100973:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0100977:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010097a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010097d:	7f dc                	jg     c010095b <print_debuginfo+0x3d>
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
c010097f:	8d 95 dc fe ff ff    	lea    -0x124(%ebp),%edx
c0100985:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100988:	01 d0                	add    %edx,%eax
c010098a:	c6 00 00             	movb   $0x0,(%eax)
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
                fnname, eip - info.eip_fn_addr);
c010098d:	8b 45 ec             	mov    -0x14(%ebp),%eax
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
c0100990:	8b 55 08             	mov    0x8(%ebp),%edx
c0100993:	89 d1                	mov    %edx,%ecx
c0100995:	29 c1                	sub    %eax,%ecx
c0100997:	8b 55 e0             	mov    -0x20(%ebp),%edx
c010099a:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010099d:	89 4c 24 10          	mov    %ecx,0x10(%esp)
c01009a1:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
c01009a7:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
c01009ab:	89 54 24 08          	mov    %edx,0x8(%esp)
c01009af:	89 44 24 04          	mov    %eax,0x4(%esp)
c01009b3:	c7 04 24 76 74 10 c0 	movl   $0xc0107476,(%esp)
c01009ba:	e8 95 f9 ff ff       	call   c0100354 <cprintf>
                fnname, eip - info.eip_fn_addr);
    }
}
c01009bf:	c9                   	leave  
c01009c0:	c3                   	ret    

c01009c1 <read_eip>:

static __noinline uint32_t
read_eip(void) {
c01009c1:	55                   	push   %ebp
c01009c2:	89 e5                	mov    %esp,%ebp
c01009c4:	83 ec 10             	sub    $0x10,%esp
    uint32_t eip;
    asm volatile("movl 4(%%ebp), %0" : "=r" (eip));
c01009c7:	8b 45 04             	mov    0x4(%ebp),%eax
c01009ca:	89 45 fc             	mov    %eax,-0x4(%ebp)
    return eip;
c01009cd:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c01009d0:	c9                   	leave  
c01009d1:	c3                   	ret    

c01009d2 <print_stackframe>:
 *
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the boundary.
 * */
void
print_stackframe(void) {
c01009d2:	55                   	push   %ebp
c01009d3:	89 e5                	mov    %esp,%ebp
c01009d5:	53                   	push   %ebx
c01009d6:	83 ec 34             	sub    $0x34,%esp
}

static inline uint32_t
read_ebp(void) {
    uint32_t ebp;
    asm volatile ("movl %%ebp, %0" : "=r" (ebp));
c01009d9:	89 e8                	mov    %ebp,%eax
c01009db:	89 45 e8             	mov    %eax,-0x18(%ebp)
    return ebp;
c01009de:	8b 45 e8             	mov    -0x18(%ebp),%eax
      *    (3.4) call print_debuginfo(eip-1) to print the C calling function name and line number, etc.
      *    (3.5) popup a calling stackframe
      *           NOTICE: the calling funciton's return addr eip  = ss:[ebp+4]
      *                   the calling funciton's ebp = ss:[ebp]
      */
    uint32_t ebp = read_ebp();
c01009e1:	89 45 f4             	mov    %eax,-0xc(%ebp)
    uint32_t eip = read_eip();
c01009e4:	e8 d8 ff ff ff       	call   c01009c1 <read_eip>
c01009e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    int i;
    for (i = 0; i < ebp && STACKFRAME_DEPTH; i++) {
c01009ec:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
c01009f3:	e9 87 00 00 00       	jmp    c0100a7f <print_stackframe+0xad>
        cprintf("ebp:%08x eip:%08x ", ebp, eip);
c01009f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01009fb:	89 44 24 08          	mov    %eax,0x8(%esp)
c01009ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a02:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100a06:	c7 04 24 88 74 10 c0 	movl   $0xc0107488,(%esp)
c0100a0d:	e8 42 f9 ff ff       	call   c0100354 <cprintf>
        cprintf("args:%08x %08x %08x %08x", *(uint32_t*)(ebp + 8), *(uint32_t*)(ebp + 12), *(uint32_t*)(ebp + 16), *(uint32_t*)(ebp + 20));
c0100a12:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a15:	83 c0 14             	add    $0x14,%eax
c0100a18:	8b 18                	mov    (%eax),%ebx
c0100a1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a1d:	83 c0 10             	add    $0x10,%eax
c0100a20:	8b 08                	mov    (%eax),%ecx
c0100a22:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a25:	83 c0 0c             	add    $0xc,%eax
c0100a28:	8b 10                	mov    (%eax),%edx
c0100a2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a2d:	83 c0 08             	add    $0x8,%eax
c0100a30:	8b 00                	mov    (%eax),%eax
c0100a32:	89 5c 24 10          	mov    %ebx,0x10(%esp)
c0100a36:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
c0100a3a:	89 54 24 08          	mov    %edx,0x8(%esp)
c0100a3e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100a42:	c7 04 24 9b 74 10 c0 	movl   $0xc010749b,(%esp)
c0100a49:	e8 06 f9 ff ff       	call   c0100354 <cprintf>
        cprintf("\n");
c0100a4e:	c7 04 24 b4 74 10 c0 	movl   $0xc01074b4,(%esp)
c0100a55:	e8 fa f8 ff ff       	call   c0100354 <cprintf>
        print_debuginfo(eip - 1);
c0100a5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100a5d:	83 e8 01             	sub    $0x1,%eax
c0100a60:	89 04 24             	mov    %eax,(%esp)
c0100a63:	e8 b6 fe ff ff       	call   c010091e <print_debuginfo>
        eip = *(uint32_t*)(ebp + 4); //这里要先更新eip再更新ebp
c0100a68:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a6b:	83 c0 04             	add    $0x4,%eax
c0100a6e:	8b 00                	mov    (%eax),%eax
c0100a70:	89 45 f0             	mov    %eax,-0x10(%ebp)
        ebp = *(uint32_t*)(ebp);
c0100a73:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a76:	8b 00                	mov    (%eax),%eax
c0100a78:	89 45 f4             	mov    %eax,-0xc(%ebp)
      *                   the calling funciton's ebp = ss:[ebp]
      */
    uint32_t ebp = read_ebp();
    uint32_t eip = read_eip();
    int i;
    for (i = 0; i < ebp && STACKFRAME_DEPTH; i++) {
c0100a7b:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
c0100a7f:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100a82:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0100a85:	0f 82 6d ff ff ff    	jb     c01009f8 <print_stackframe+0x26>
        cprintf("\n");
        print_debuginfo(eip - 1);
        eip = *(uint32_t*)(ebp + 4); //这里要先更新eip再更新ebp
        ebp = *(uint32_t*)(ebp);
    }
}
c0100a8b:	83 c4 34             	add    $0x34,%esp
c0100a8e:	5b                   	pop    %ebx
c0100a8f:	5d                   	pop    %ebp
c0100a90:	c3                   	ret    

c0100a91 <parse>:
#define MAXARGS         16
#define WHITESPACE      " \t\n\r"

/* parse - parse the command buffer into whitespace-separated arguments */
static int
parse(char *buf, char **argv) {
c0100a91:	55                   	push   %ebp
c0100a92:	89 e5                	mov    %esp,%ebp
c0100a94:	83 ec 28             	sub    $0x28,%esp
    int argc = 0;
c0100a97:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
c0100a9e:	eb 0c                	jmp    c0100aac <parse+0x1b>
            *buf ++ = '\0';
c0100aa0:	8b 45 08             	mov    0x8(%ebp),%eax
c0100aa3:	8d 50 01             	lea    0x1(%eax),%edx
c0100aa6:	89 55 08             	mov    %edx,0x8(%ebp)
c0100aa9:	c6 00 00             	movb   $0x0,(%eax)
static int
parse(char *buf, char **argv) {
    int argc = 0;
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
c0100aac:	8b 45 08             	mov    0x8(%ebp),%eax
c0100aaf:	0f b6 00             	movzbl (%eax),%eax
c0100ab2:	84 c0                	test   %al,%al
c0100ab4:	74 1d                	je     c0100ad3 <parse+0x42>
c0100ab6:	8b 45 08             	mov    0x8(%ebp),%eax
c0100ab9:	0f b6 00             	movzbl (%eax),%eax
c0100abc:	0f be c0             	movsbl %al,%eax
c0100abf:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100ac3:	c7 04 24 38 75 10 c0 	movl   $0xc0107538,(%esp)
c0100aca:	e8 d9 64 00 00       	call   c0106fa8 <strchr>
c0100acf:	85 c0                	test   %eax,%eax
c0100ad1:	75 cd                	jne    c0100aa0 <parse+0xf>
            *buf ++ = '\0';
        }
        if (*buf == '\0') {
c0100ad3:	8b 45 08             	mov    0x8(%ebp),%eax
c0100ad6:	0f b6 00             	movzbl (%eax),%eax
c0100ad9:	84 c0                	test   %al,%al
c0100adb:	75 02                	jne    c0100adf <parse+0x4e>
            break;
c0100add:	eb 67                	jmp    c0100b46 <parse+0xb5>
        }

        // save and scan past next arg
        if (argc == MAXARGS - 1) {
c0100adf:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
c0100ae3:	75 14                	jne    c0100af9 <parse+0x68>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
c0100ae5:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
c0100aec:	00 
c0100aed:	c7 04 24 3d 75 10 c0 	movl   $0xc010753d,(%esp)
c0100af4:	e8 5b f8 ff ff       	call   c0100354 <cprintf>
        }
        argv[argc ++] = buf;
c0100af9:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100afc:	8d 50 01             	lea    0x1(%eax),%edx
c0100aff:	89 55 f4             	mov    %edx,-0xc(%ebp)
c0100b02:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0100b09:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100b0c:	01 c2                	add    %eax,%edx
c0100b0e:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b11:	89 02                	mov    %eax,(%edx)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
c0100b13:	eb 04                	jmp    c0100b19 <parse+0x88>
            buf ++;
c0100b15:	83 45 08 01          	addl   $0x1,0x8(%ebp)
        // save and scan past next arg
        if (argc == MAXARGS - 1) {
            cprintf("Too many arguments (max %d).\n", MAXARGS);
        }
        argv[argc ++] = buf;
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
c0100b19:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b1c:	0f b6 00             	movzbl (%eax),%eax
c0100b1f:	84 c0                	test   %al,%al
c0100b21:	74 1d                	je     c0100b40 <parse+0xaf>
c0100b23:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b26:	0f b6 00             	movzbl (%eax),%eax
c0100b29:	0f be c0             	movsbl %al,%eax
c0100b2c:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100b30:	c7 04 24 38 75 10 c0 	movl   $0xc0107538,(%esp)
c0100b37:	e8 6c 64 00 00       	call   c0106fa8 <strchr>
c0100b3c:	85 c0                	test   %eax,%eax
c0100b3e:	74 d5                	je     c0100b15 <parse+0x84>
            buf ++;
        }
    }
c0100b40:	90                   	nop
static int
parse(char *buf, char **argv) {
    int argc = 0;
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
c0100b41:	e9 66 ff ff ff       	jmp    c0100aac <parse+0x1b>
        argv[argc ++] = buf;
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
            buf ++;
        }
    }
    return argc;
c0100b46:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0100b49:	c9                   	leave  
c0100b4a:	c3                   	ret    

c0100b4b <runcmd>:
/* *
 * runcmd - parse the input string, split it into separated arguments
 * and then lookup and invoke some related commands/
 * */
static int
runcmd(char *buf, struct trapframe *tf) {
c0100b4b:	55                   	push   %ebp
c0100b4c:	89 e5                	mov    %esp,%ebp
c0100b4e:	83 ec 68             	sub    $0x68,%esp
    char *argv[MAXARGS];
    int argc = parse(buf, argv);
c0100b51:	8d 45 b0             	lea    -0x50(%ebp),%eax
c0100b54:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100b58:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b5b:	89 04 24             	mov    %eax,(%esp)
c0100b5e:	e8 2e ff ff ff       	call   c0100a91 <parse>
c0100b63:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if (argc == 0) {
c0100b66:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0100b6a:	75 0a                	jne    c0100b76 <runcmd+0x2b>
        return 0;
c0100b6c:	b8 00 00 00 00       	mov    $0x0,%eax
c0100b71:	e9 85 00 00 00       	jmp    c0100bfb <runcmd+0xb0>
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100b76:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0100b7d:	eb 5c                	jmp    c0100bdb <runcmd+0x90>
        if (strcmp(commands[i].name, argv[0]) == 0) {
c0100b7f:	8b 4d b0             	mov    -0x50(%ebp),%ecx
c0100b82:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100b85:	89 d0                	mov    %edx,%eax
c0100b87:	01 c0                	add    %eax,%eax
c0100b89:	01 d0                	add    %edx,%eax
c0100b8b:	c1 e0 02             	shl    $0x2,%eax
c0100b8e:	05 00 a0 11 c0       	add    $0xc011a000,%eax
c0100b93:	8b 00                	mov    (%eax),%eax
c0100b95:	89 4c 24 04          	mov    %ecx,0x4(%esp)
c0100b99:	89 04 24             	mov    %eax,(%esp)
c0100b9c:	e8 68 63 00 00       	call   c0106f09 <strcmp>
c0100ba1:	85 c0                	test   %eax,%eax
c0100ba3:	75 32                	jne    c0100bd7 <runcmd+0x8c>
            return commands[i].func(argc - 1, argv + 1, tf);
c0100ba5:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100ba8:	89 d0                	mov    %edx,%eax
c0100baa:	01 c0                	add    %eax,%eax
c0100bac:	01 d0                	add    %edx,%eax
c0100bae:	c1 e0 02             	shl    $0x2,%eax
c0100bb1:	05 00 a0 11 c0       	add    $0xc011a000,%eax
c0100bb6:	8b 40 08             	mov    0x8(%eax),%eax
c0100bb9:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100bbc:	8d 4a ff             	lea    -0x1(%edx),%ecx
c0100bbf:	8b 55 0c             	mov    0xc(%ebp),%edx
c0100bc2:	89 54 24 08          	mov    %edx,0x8(%esp)
c0100bc6:	8d 55 b0             	lea    -0x50(%ebp),%edx
c0100bc9:	83 c2 04             	add    $0x4,%edx
c0100bcc:	89 54 24 04          	mov    %edx,0x4(%esp)
c0100bd0:	89 0c 24             	mov    %ecx,(%esp)
c0100bd3:	ff d0                	call   *%eax
c0100bd5:	eb 24                	jmp    c0100bfb <runcmd+0xb0>
    int argc = parse(buf, argv);
    if (argc == 0) {
        return 0;
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100bd7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0100bdb:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100bde:	83 f8 02             	cmp    $0x2,%eax
c0100be1:	76 9c                	jbe    c0100b7f <runcmd+0x34>
        if (strcmp(commands[i].name, argv[0]) == 0) {
            return commands[i].func(argc - 1, argv + 1, tf);
        }
    }
    cprintf("Unknown command '%s'\n", argv[0]);
c0100be3:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0100be6:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100bea:	c7 04 24 5b 75 10 c0 	movl   $0xc010755b,(%esp)
c0100bf1:	e8 5e f7 ff ff       	call   c0100354 <cprintf>
    return 0;
c0100bf6:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100bfb:	c9                   	leave  
c0100bfc:	c3                   	ret    

c0100bfd <kmonitor>:

/***** Implementations of basic kernel monitor commands *****/

void
kmonitor(struct trapframe *tf) {
c0100bfd:	55                   	push   %ebp
c0100bfe:	89 e5                	mov    %esp,%ebp
c0100c00:	83 ec 28             	sub    $0x28,%esp
    cprintf("Welcome to the kernel debug monitor!!\n");
c0100c03:	c7 04 24 74 75 10 c0 	movl   $0xc0107574,(%esp)
c0100c0a:	e8 45 f7 ff ff       	call   c0100354 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
c0100c0f:	c7 04 24 9c 75 10 c0 	movl   $0xc010759c,(%esp)
c0100c16:	e8 39 f7 ff ff       	call   c0100354 <cprintf>

    if (tf != NULL) {
c0100c1b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0100c1f:	74 0b                	je     c0100c2c <kmonitor+0x2f>
        print_trapframe(tf);
c0100c21:	8b 45 08             	mov    0x8(%ebp),%eax
c0100c24:	89 04 24             	mov    %eax,(%esp)
c0100c27:	e8 3b 0f 00 00       	call   c0101b67 <print_trapframe>
    }

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
c0100c2c:	c7 04 24 c1 75 10 c0 	movl   $0xc01075c1,(%esp)
c0100c33:	e8 13 f6 ff ff       	call   c010024b <readline>
c0100c38:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0100c3b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0100c3f:	74 18                	je     c0100c59 <kmonitor+0x5c>
            if (runcmd(buf, tf) < 0) {
c0100c41:	8b 45 08             	mov    0x8(%ebp),%eax
c0100c44:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100c48:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100c4b:	89 04 24             	mov    %eax,(%esp)
c0100c4e:	e8 f8 fe ff ff       	call   c0100b4b <runcmd>
c0100c53:	85 c0                	test   %eax,%eax
c0100c55:	79 02                	jns    c0100c59 <kmonitor+0x5c>
                break;
c0100c57:	eb 02                	jmp    c0100c5b <kmonitor+0x5e>
            }
        }
    }
c0100c59:	eb d1                	jmp    c0100c2c <kmonitor+0x2f>
}
c0100c5b:	c9                   	leave  
c0100c5c:	c3                   	ret    

c0100c5d <mon_help>:

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
c0100c5d:	55                   	push   %ebp
c0100c5e:	89 e5                	mov    %esp,%ebp
c0100c60:	83 ec 28             	sub    $0x28,%esp
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100c63:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0100c6a:	eb 3f                	jmp    c0100cab <mon_help+0x4e>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
c0100c6c:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100c6f:	89 d0                	mov    %edx,%eax
c0100c71:	01 c0                	add    %eax,%eax
c0100c73:	01 d0                	add    %edx,%eax
c0100c75:	c1 e0 02             	shl    $0x2,%eax
c0100c78:	05 00 a0 11 c0       	add    $0xc011a000,%eax
c0100c7d:	8b 48 04             	mov    0x4(%eax),%ecx
c0100c80:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100c83:	89 d0                	mov    %edx,%eax
c0100c85:	01 c0                	add    %eax,%eax
c0100c87:	01 d0                	add    %edx,%eax
c0100c89:	c1 e0 02             	shl    $0x2,%eax
c0100c8c:	05 00 a0 11 c0       	add    $0xc011a000,%eax
c0100c91:	8b 00                	mov    (%eax),%eax
c0100c93:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c0100c97:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100c9b:	c7 04 24 c5 75 10 c0 	movl   $0xc01075c5,(%esp)
c0100ca2:	e8 ad f6 ff ff       	call   c0100354 <cprintf>

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100ca7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0100cab:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100cae:	83 f8 02             	cmp    $0x2,%eax
c0100cb1:	76 b9                	jbe    c0100c6c <mon_help+0xf>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
    }
    return 0;
c0100cb3:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100cb8:	c9                   	leave  
c0100cb9:	c3                   	ret    

c0100cba <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
c0100cba:	55                   	push   %ebp
c0100cbb:	89 e5                	mov    %esp,%ebp
c0100cbd:	83 ec 08             	sub    $0x8,%esp
    print_kerninfo();
c0100cc0:	e8 c3 fb ff ff       	call   c0100888 <print_kerninfo>
    return 0;
c0100cc5:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100cca:	c9                   	leave  
c0100ccb:	c3                   	ret    

c0100ccc <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
c0100ccc:	55                   	push   %ebp
c0100ccd:	89 e5                	mov    %esp,%ebp
c0100ccf:	83 ec 08             	sub    $0x8,%esp
    print_stackframe();
c0100cd2:	e8 fb fc ff ff       	call   c01009d2 <print_stackframe>
    return 0;
c0100cd7:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100cdc:	c9                   	leave  
c0100cdd:	c3                   	ret    

c0100cde <__panic>:
/* *
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
c0100cde:	55                   	push   %ebp
c0100cdf:	89 e5                	mov    %esp,%ebp
c0100ce1:	83 ec 28             	sub    $0x28,%esp
    if (is_panic) {
c0100ce4:	a1 20 d4 11 c0       	mov    0xc011d420,%eax
c0100ce9:	85 c0                	test   %eax,%eax
c0100ceb:	74 02                	je     c0100cef <__panic+0x11>
        goto panic_dead;
c0100ced:	eb 59                	jmp    c0100d48 <__panic+0x6a>
    }
    is_panic = 1;
c0100cef:	c7 05 20 d4 11 c0 01 	movl   $0x1,0xc011d420
c0100cf6:	00 00 00 

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
c0100cf9:	8d 45 14             	lea    0x14(%ebp),%eax
c0100cfc:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
c0100cff:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100d02:	89 44 24 08          	mov    %eax,0x8(%esp)
c0100d06:	8b 45 08             	mov    0x8(%ebp),%eax
c0100d09:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100d0d:	c7 04 24 ce 75 10 c0 	movl   $0xc01075ce,(%esp)
c0100d14:	e8 3b f6 ff ff       	call   c0100354 <cprintf>
    vcprintf(fmt, ap);
c0100d19:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100d1c:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100d20:	8b 45 10             	mov    0x10(%ebp),%eax
c0100d23:	89 04 24             	mov    %eax,(%esp)
c0100d26:	e8 f6 f5 ff ff       	call   c0100321 <vcprintf>
    cprintf("\n");
c0100d2b:	c7 04 24 ea 75 10 c0 	movl   $0xc01075ea,(%esp)
c0100d32:	e8 1d f6 ff ff       	call   c0100354 <cprintf>
    
    cprintf("stack trackback:\n");
c0100d37:	c7 04 24 ec 75 10 c0 	movl   $0xc01075ec,(%esp)
c0100d3e:	e8 11 f6 ff ff       	call   c0100354 <cprintf>
    print_stackframe();
c0100d43:	e8 8a fc ff ff       	call   c01009d2 <print_stackframe>
    
    va_end(ap);

panic_dead:
    intr_disable();
c0100d48:	e8 85 09 00 00       	call   c01016d2 <intr_disable>
    while (1) {
        kmonitor(NULL);
c0100d4d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c0100d54:	e8 a4 fe ff ff       	call   c0100bfd <kmonitor>
    }
c0100d59:	eb f2                	jmp    c0100d4d <__panic+0x6f>

c0100d5b <__warn>:
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
c0100d5b:	55                   	push   %ebp
c0100d5c:	89 e5                	mov    %esp,%ebp
c0100d5e:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    va_start(ap, fmt);
c0100d61:	8d 45 14             	lea    0x14(%ebp),%eax
c0100d64:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
c0100d67:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100d6a:	89 44 24 08          	mov    %eax,0x8(%esp)
c0100d6e:	8b 45 08             	mov    0x8(%ebp),%eax
c0100d71:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100d75:	c7 04 24 fe 75 10 c0 	movl   $0xc01075fe,(%esp)
c0100d7c:	e8 d3 f5 ff ff       	call   c0100354 <cprintf>
    vcprintf(fmt, ap);
c0100d81:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100d84:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100d88:	8b 45 10             	mov    0x10(%ebp),%eax
c0100d8b:	89 04 24             	mov    %eax,(%esp)
c0100d8e:	e8 8e f5 ff ff       	call   c0100321 <vcprintf>
    cprintf("\n");
c0100d93:	c7 04 24 ea 75 10 c0 	movl   $0xc01075ea,(%esp)
c0100d9a:	e8 b5 f5 ff ff       	call   c0100354 <cprintf>
    va_end(ap);
}
c0100d9f:	c9                   	leave  
c0100da0:	c3                   	ret    

c0100da1 <is_kernel_panic>:

bool
is_kernel_panic(void) {
c0100da1:	55                   	push   %ebp
c0100da2:	89 e5                	mov    %esp,%ebp
    return is_panic;
c0100da4:	a1 20 d4 11 c0       	mov    0xc011d420,%eax
}
c0100da9:	5d                   	pop    %ebp
c0100daa:	c3                   	ret    

c0100dab <clock_init>:
/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void
clock_init(void) {
c0100dab:	55                   	push   %ebp
c0100dac:	89 e5                	mov    %esp,%ebp
c0100dae:	83 ec 28             	sub    $0x28,%esp
c0100db1:	66 c7 45 f6 43 00    	movw   $0x43,-0xa(%ebp)
c0100db7:	c6 45 f5 34          	movb   $0x34,-0xb(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100dbb:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
c0100dbf:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100dc3:	ee                   	out    %al,(%dx)
c0100dc4:	66 c7 45 f2 40 00    	movw   $0x40,-0xe(%ebp)
c0100dca:	c6 45 f1 9c          	movb   $0x9c,-0xf(%ebp)
c0100dce:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c0100dd2:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0100dd6:	ee                   	out    %al,(%dx)
c0100dd7:	66 c7 45 ee 40 00    	movw   $0x40,-0x12(%ebp)
c0100ddd:	c6 45 ed 2e          	movb   $0x2e,-0x13(%ebp)
c0100de1:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c0100de5:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c0100de9:	ee                   	out    %al,(%dx)
    outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
    outb(IO_TIMER1, TIMER_DIV(100) % 256);
    outb(IO_TIMER1, TIMER_DIV(100) / 256);

    // initialize time counter 'ticks' to zero
    ticks = 0;
c0100dea:	c7 05 2c 57 12 c0 00 	movl   $0x0,0xc012572c
c0100df1:	00 00 00 

    cprintf("++ setup timer interrupts\n");
c0100df4:	c7 04 24 1c 76 10 c0 	movl   $0xc010761c,(%esp)
c0100dfb:	e8 54 f5 ff ff       	call   c0100354 <cprintf>
    pic_enable(IRQ_TIMER);
c0100e00:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c0100e07:	e8 24 09 00 00       	call   c0101730 <pic_enable>
}
c0100e0c:	c9                   	leave  
c0100e0d:	c3                   	ret    

c0100e0e <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
c0100e0e:	55                   	push   %ebp
c0100e0f:	89 e5                	mov    %esp,%ebp
c0100e11:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c0100e14:	9c                   	pushf  
c0100e15:	58                   	pop    %eax
c0100e16:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c0100e19:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
c0100e1c:	25 00 02 00 00       	and    $0x200,%eax
c0100e21:	85 c0                	test   %eax,%eax
c0100e23:	74 0c                	je     c0100e31 <__intr_save+0x23>
        intr_disable();
c0100e25:	e8 a8 08 00 00       	call   c01016d2 <intr_disable>
        return 1;
c0100e2a:	b8 01 00 00 00       	mov    $0x1,%eax
c0100e2f:	eb 05                	jmp    c0100e36 <__intr_save+0x28>
    }
    return 0;
c0100e31:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100e36:	c9                   	leave  
c0100e37:	c3                   	ret    

c0100e38 <__intr_restore>:

static inline void
__intr_restore(bool flag) {
c0100e38:	55                   	push   %ebp
c0100e39:	89 e5                	mov    %esp,%ebp
c0100e3b:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c0100e3e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0100e42:	74 05                	je     c0100e49 <__intr_restore+0x11>
        intr_enable();
c0100e44:	e8 83 08 00 00       	call   c01016cc <intr_enable>
    }
}
c0100e49:	c9                   	leave  
c0100e4a:	c3                   	ret    

c0100e4b <delay>:
#include <memlayout.h>
#include <sync.h>

/* stupid I/O delay routine necessitated by historical PC design flaws */
static void
delay(void) {
c0100e4b:	55                   	push   %ebp
c0100e4c:	89 e5                	mov    %esp,%ebp
c0100e4e:	83 ec 10             	sub    $0x10,%esp
c0100e51:	66 c7 45 fe 84 00    	movw   $0x84,-0x2(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100e57:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
c0100e5b:	89 c2                	mov    %eax,%edx
c0100e5d:	ec                   	in     (%dx),%al
c0100e5e:	88 45 fd             	mov    %al,-0x3(%ebp)
c0100e61:	66 c7 45 fa 84 00    	movw   $0x84,-0x6(%ebp)
c0100e67:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c0100e6b:	89 c2                	mov    %eax,%edx
c0100e6d:	ec                   	in     (%dx),%al
c0100e6e:	88 45 f9             	mov    %al,-0x7(%ebp)
c0100e71:	66 c7 45 f6 84 00    	movw   $0x84,-0xa(%ebp)
c0100e77:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100e7b:	89 c2                	mov    %eax,%edx
c0100e7d:	ec                   	in     (%dx),%al
c0100e7e:	88 45 f5             	mov    %al,-0xb(%ebp)
c0100e81:	66 c7 45 f2 84 00    	movw   $0x84,-0xe(%ebp)
c0100e87:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c0100e8b:	89 c2                	mov    %eax,%edx
c0100e8d:	ec                   	in     (%dx),%al
c0100e8e:	88 45 f1             	mov    %al,-0xf(%ebp)
    inb(0x84);
    inb(0x84);
    inb(0x84);
    inb(0x84);
}
c0100e91:	c9                   	leave  
c0100e92:	c3                   	ret    

c0100e93 <cga_init>:
static uint16_t addr_6845;

/* TEXT-mode CGA/VGA display output */

static void
cga_init(void) {
c0100e93:	55                   	push   %ebp
c0100e94:	89 e5                	mov    %esp,%ebp
c0100e96:	83 ec 20             	sub    $0x20,%esp
    volatile uint16_t *cp = (uint16_t *)(CGA_BUF + KERNBASE);
c0100e99:	c7 45 fc 00 80 0b c0 	movl   $0xc00b8000,-0x4(%ebp)
    uint16_t was = *cp;
c0100ea0:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100ea3:	0f b7 00             	movzwl (%eax),%eax
c0100ea6:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
    *cp = (uint16_t) 0xA55A;
c0100eaa:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100ead:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
    if (*cp != 0xA55A) {
c0100eb2:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100eb5:	0f b7 00             	movzwl (%eax),%eax
c0100eb8:	66 3d 5a a5          	cmp    $0xa55a,%ax
c0100ebc:	74 12                	je     c0100ed0 <cga_init+0x3d>
        cp = (uint16_t*)(MONO_BUF + KERNBASE);
c0100ebe:	c7 45 fc 00 00 0b c0 	movl   $0xc00b0000,-0x4(%ebp)
        addr_6845 = MONO_BASE;
c0100ec5:	66 c7 05 46 d4 11 c0 	movw   $0x3b4,0xc011d446
c0100ecc:	b4 03 
c0100ece:	eb 13                	jmp    c0100ee3 <cga_init+0x50>
    } else {
        *cp = was;
c0100ed0:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100ed3:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c0100ed7:	66 89 10             	mov    %dx,(%eax)
        addr_6845 = CGA_BASE;
c0100eda:	66 c7 05 46 d4 11 c0 	movw   $0x3d4,0xc011d446
c0100ee1:	d4 03 
    }

    // Extract cursor location
    uint32_t pos;
    outb(addr_6845, 14);
c0100ee3:	0f b7 05 46 d4 11 c0 	movzwl 0xc011d446,%eax
c0100eea:	0f b7 c0             	movzwl %ax,%eax
c0100eed:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
c0100ef1:	c6 45 f1 0e          	movb   $0xe,-0xf(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100ef5:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c0100ef9:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0100efd:	ee                   	out    %al,(%dx)
    pos = inb(addr_6845 + 1) << 8;
c0100efe:	0f b7 05 46 d4 11 c0 	movzwl 0xc011d446,%eax
c0100f05:	83 c0 01             	add    $0x1,%eax
c0100f08:	0f b7 c0             	movzwl %ax,%eax
c0100f0b:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100f0f:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
c0100f13:	89 c2                	mov    %eax,%edx
c0100f15:	ec                   	in     (%dx),%al
c0100f16:	88 45 ed             	mov    %al,-0x13(%ebp)
    return data;
c0100f19:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c0100f1d:	0f b6 c0             	movzbl %al,%eax
c0100f20:	c1 e0 08             	shl    $0x8,%eax
c0100f23:	89 45 f4             	mov    %eax,-0xc(%ebp)
    outb(addr_6845, 15);
c0100f26:	0f b7 05 46 d4 11 c0 	movzwl 0xc011d446,%eax
c0100f2d:	0f b7 c0             	movzwl %ax,%eax
c0100f30:	66 89 45 ea          	mov    %ax,-0x16(%ebp)
c0100f34:	c6 45 e9 0f          	movb   $0xf,-0x17(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100f38:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c0100f3c:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c0100f40:	ee                   	out    %al,(%dx)
    pos |= inb(addr_6845 + 1);
c0100f41:	0f b7 05 46 d4 11 c0 	movzwl 0xc011d446,%eax
c0100f48:	83 c0 01             	add    $0x1,%eax
c0100f4b:	0f b7 c0             	movzwl %ax,%eax
c0100f4e:	66 89 45 e6          	mov    %ax,-0x1a(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100f52:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax
c0100f56:	89 c2                	mov    %eax,%edx
c0100f58:	ec                   	in     (%dx),%al
c0100f59:	88 45 e5             	mov    %al,-0x1b(%ebp)
    return data;
c0100f5c:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
c0100f60:	0f b6 c0             	movzbl %al,%eax
c0100f63:	09 45 f4             	or     %eax,-0xc(%ebp)

    crt_buf = (uint16_t*) cp;
c0100f66:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100f69:	a3 40 d4 11 c0       	mov    %eax,0xc011d440
    crt_pos = pos;
c0100f6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100f71:	66 a3 44 d4 11 c0    	mov    %ax,0xc011d444
}
c0100f77:	c9                   	leave  
c0100f78:	c3                   	ret    

c0100f79 <serial_init>:

static bool serial_exists = 0;

static void
serial_init(void) {
c0100f79:	55                   	push   %ebp
c0100f7a:	89 e5                	mov    %esp,%ebp
c0100f7c:	83 ec 48             	sub    $0x48,%esp
c0100f7f:	66 c7 45 f6 fa 03    	movw   $0x3fa,-0xa(%ebp)
c0100f85:	c6 45 f5 00          	movb   $0x0,-0xb(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100f89:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
c0100f8d:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100f91:	ee                   	out    %al,(%dx)
c0100f92:	66 c7 45 f2 fb 03    	movw   $0x3fb,-0xe(%ebp)
c0100f98:	c6 45 f1 80          	movb   $0x80,-0xf(%ebp)
c0100f9c:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c0100fa0:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0100fa4:	ee                   	out    %al,(%dx)
c0100fa5:	66 c7 45 ee f8 03    	movw   $0x3f8,-0x12(%ebp)
c0100fab:	c6 45 ed 0c          	movb   $0xc,-0x13(%ebp)
c0100faf:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c0100fb3:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c0100fb7:	ee                   	out    %al,(%dx)
c0100fb8:	66 c7 45 ea f9 03    	movw   $0x3f9,-0x16(%ebp)
c0100fbe:	c6 45 e9 00          	movb   $0x0,-0x17(%ebp)
c0100fc2:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c0100fc6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c0100fca:	ee                   	out    %al,(%dx)
c0100fcb:	66 c7 45 e6 fb 03    	movw   $0x3fb,-0x1a(%ebp)
c0100fd1:	c6 45 e5 03          	movb   $0x3,-0x1b(%ebp)
c0100fd5:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
c0100fd9:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
c0100fdd:	ee                   	out    %al,(%dx)
c0100fde:	66 c7 45 e2 fc 03    	movw   $0x3fc,-0x1e(%ebp)
c0100fe4:	c6 45 e1 00          	movb   $0x0,-0x1f(%ebp)
c0100fe8:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
c0100fec:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
c0100ff0:	ee                   	out    %al,(%dx)
c0100ff1:	66 c7 45 de f9 03    	movw   $0x3f9,-0x22(%ebp)
c0100ff7:	c6 45 dd 01          	movb   $0x1,-0x23(%ebp)
c0100ffb:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
c0100fff:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
c0101003:	ee                   	out    %al,(%dx)
c0101004:	66 c7 45 da fd 03    	movw   $0x3fd,-0x26(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c010100a:	0f b7 45 da          	movzwl -0x26(%ebp),%eax
c010100e:	89 c2                	mov    %eax,%edx
c0101010:	ec                   	in     (%dx),%al
c0101011:	88 45 d9             	mov    %al,-0x27(%ebp)
    return data;
c0101014:	0f b6 45 d9          	movzbl -0x27(%ebp),%eax
    // Enable rcv interrupts
    outb(COM1 + COM_IER, COM_IER_RDI);

    // Clear any preexisting overrun indications and interrupts
    // Serial port doesn't exist if COM_LSR returns 0xFF
    serial_exists = (inb(COM1 + COM_LSR) != 0xFF);
c0101018:	3c ff                	cmp    $0xff,%al
c010101a:	0f 95 c0             	setne  %al
c010101d:	0f b6 c0             	movzbl %al,%eax
c0101020:	a3 48 d4 11 c0       	mov    %eax,0xc011d448
c0101025:	66 c7 45 d6 fa 03    	movw   $0x3fa,-0x2a(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c010102b:	0f b7 45 d6          	movzwl -0x2a(%ebp),%eax
c010102f:	89 c2                	mov    %eax,%edx
c0101031:	ec                   	in     (%dx),%al
c0101032:	88 45 d5             	mov    %al,-0x2b(%ebp)
c0101035:	66 c7 45 d2 f8 03    	movw   $0x3f8,-0x2e(%ebp)
c010103b:	0f b7 45 d2          	movzwl -0x2e(%ebp),%eax
c010103f:	89 c2                	mov    %eax,%edx
c0101041:	ec                   	in     (%dx),%al
c0101042:	88 45 d1             	mov    %al,-0x2f(%ebp)
    (void) inb(COM1+COM_IIR);
    (void) inb(COM1+COM_RX);

    if (serial_exists) {
c0101045:	a1 48 d4 11 c0       	mov    0xc011d448,%eax
c010104a:	85 c0                	test   %eax,%eax
c010104c:	74 0c                	je     c010105a <serial_init+0xe1>
        pic_enable(IRQ_COM1);
c010104e:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
c0101055:	e8 d6 06 00 00       	call   c0101730 <pic_enable>
    }
}
c010105a:	c9                   	leave  
c010105b:	c3                   	ret    

c010105c <lpt_putc_sub>:

static void
lpt_putc_sub(int c) {
c010105c:	55                   	push   %ebp
c010105d:	89 e5                	mov    %esp,%ebp
c010105f:	83 ec 20             	sub    $0x20,%esp
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
c0101062:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c0101069:	eb 09                	jmp    c0101074 <lpt_putc_sub+0x18>
        delay();
c010106b:	e8 db fd ff ff       	call   c0100e4b <delay>
}

static void
lpt_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
c0101070:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c0101074:	66 c7 45 fa 79 03    	movw   $0x379,-0x6(%ebp)
c010107a:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c010107e:	89 c2                	mov    %eax,%edx
c0101080:	ec                   	in     (%dx),%al
c0101081:	88 45 f9             	mov    %al,-0x7(%ebp)
    return data;
c0101084:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
c0101088:	84 c0                	test   %al,%al
c010108a:	78 09                	js     c0101095 <lpt_putc_sub+0x39>
c010108c:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
c0101093:	7e d6                	jle    c010106b <lpt_putc_sub+0xf>
        delay();
    }
    outb(LPTPORT + 0, c);
c0101095:	8b 45 08             	mov    0x8(%ebp),%eax
c0101098:	0f b6 c0             	movzbl %al,%eax
c010109b:	66 c7 45 f6 78 03    	movw   $0x378,-0xa(%ebp)
c01010a1:	88 45 f5             	mov    %al,-0xb(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c01010a4:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
c01010a8:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c01010ac:	ee                   	out    %al,(%dx)
c01010ad:	66 c7 45 f2 7a 03    	movw   $0x37a,-0xe(%ebp)
c01010b3:	c6 45 f1 0d          	movb   $0xd,-0xf(%ebp)
c01010b7:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c01010bb:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c01010bf:	ee                   	out    %al,(%dx)
c01010c0:	66 c7 45 ee 7a 03    	movw   $0x37a,-0x12(%ebp)
c01010c6:	c6 45 ed 08          	movb   $0x8,-0x13(%ebp)
c01010ca:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c01010ce:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c01010d2:	ee                   	out    %al,(%dx)
    outb(LPTPORT + 2, 0x08 | 0x04 | 0x01);
    outb(LPTPORT + 2, 0x08);
}
c01010d3:	c9                   	leave  
c01010d4:	c3                   	ret    

c01010d5 <lpt_putc>:

/* lpt_putc - copy console output to parallel port */
static void
lpt_putc(int c) {
c01010d5:	55                   	push   %ebp
c01010d6:	89 e5                	mov    %esp,%ebp
c01010d8:	83 ec 04             	sub    $0x4,%esp
    if (c != '\b') {
c01010db:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
c01010df:	74 0d                	je     c01010ee <lpt_putc+0x19>
        lpt_putc_sub(c);
c01010e1:	8b 45 08             	mov    0x8(%ebp),%eax
c01010e4:	89 04 24             	mov    %eax,(%esp)
c01010e7:	e8 70 ff ff ff       	call   c010105c <lpt_putc_sub>
c01010ec:	eb 24                	jmp    c0101112 <lpt_putc+0x3d>
    }
    else {
        lpt_putc_sub('\b');
c01010ee:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
c01010f5:	e8 62 ff ff ff       	call   c010105c <lpt_putc_sub>
        lpt_putc_sub(' ');
c01010fa:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
c0101101:	e8 56 ff ff ff       	call   c010105c <lpt_putc_sub>
        lpt_putc_sub('\b');
c0101106:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
c010110d:	e8 4a ff ff ff       	call   c010105c <lpt_putc_sub>
    }
}
c0101112:	c9                   	leave  
c0101113:	c3                   	ret    

c0101114 <cga_putc>:

/* cga_putc - print character to console */
static void
cga_putc(int c) {
c0101114:	55                   	push   %ebp
c0101115:	89 e5                	mov    %esp,%ebp
c0101117:	53                   	push   %ebx
c0101118:	83 ec 34             	sub    $0x34,%esp
    // set black on white
    if (!(c & ~0xFF)) {
c010111b:	8b 45 08             	mov    0x8(%ebp),%eax
c010111e:	b0 00                	mov    $0x0,%al
c0101120:	85 c0                	test   %eax,%eax
c0101122:	75 07                	jne    c010112b <cga_putc+0x17>
        c |= 0x0700;
c0101124:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)
    }

    switch (c & 0xff) {
c010112b:	8b 45 08             	mov    0x8(%ebp),%eax
c010112e:	0f b6 c0             	movzbl %al,%eax
c0101131:	83 f8 0a             	cmp    $0xa,%eax
c0101134:	74 4c                	je     c0101182 <cga_putc+0x6e>
c0101136:	83 f8 0d             	cmp    $0xd,%eax
c0101139:	74 57                	je     c0101192 <cga_putc+0x7e>
c010113b:	83 f8 08             	cmp    $0x8,%eax
c010113e:	0f 85 88 00 00 00    	jne    c01011cc <cga_putc+0xb8>
    case '\b':
        if (crt_pos > 0) {
c0101144:	0f b7 05 44 d4 11 c0 	movzwl 0xc011d444,%eax
c010114b:	66 85 c0             	test   %ax,%ax
c010114e:	74 30                	je     c0101180 <cga_putc+0x6c>
            crt_pos --;
c0101150:	0f b7 05 44 d4 11 c0 	movzwl 0xc011d444,%eax
c0101157:	83 e8 01             	sub    $0x1,%eax
c010115a:	66 a3 44 d4 11 c0    	mov    %ax,0xc011d444
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
c0101160:	a1 40 d4 11 c0       	mov    0xc011d440,%eax
c0101165:	0f b7 15 44 d4 11 c0 	movzwl 0xc011d444,%edx
c010116c:	0f b7 d2             	movzwl %dx,%edx
c010116f:	01 d2                	add    %edx,%edx
c0101171:	01 c2                	add    %eax,%edx
c0101173:	8b 45 08             	mov    0x8(%ebp),%eax
c0101176:	b0 00                	mov    $0x0,%al
c0101178:	83 c8 20             	or     $0x20,%eax
c010117b:	66 89 02             	mov    %ax,(%edx)
        }
        break;
c010117e:	eb 72                	jmp    c01011f2 <cga_putc+0xde>
c0101180:	eb 70                	jmp    c01011f2 <cga_putc+0xde>
    case '\n':
        crt_pos += CRT_COLS;
c0101182:	0f b7 05 44 d4 11 c0 	movzwl 0xc011d444,%eax
c0101189:	83 c0 50             	add    $0x50,%eax
c010118c:	66 a3 44 d4 11 c0    	mov    %ax,0xc011d444
    case '\r':
        crt_pos -= (crt_pos % CRT_COLS);
c0101192:	0f b7 1d 44 d4 11 c0 	movzwl 0xc011d444,%ebx
c0101199:	0f b7 0d 44 d4 11 c0 	movzwl 0xc011d444,%ecx
c01011a0:	0f b7 c1             	movzwl %cx,%eax
c01011a3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
c01011a9:	c1 e8 10             	shr    $0x10,%eax
c01011ac:	89 c2                	mov    %eax,%edx
c01011ae:	66 c1 ea 06          	shr    $0x6,%dx
c01011b2:	89 d0                	mov    %edx,%eax
c01011b4:	c1 e0 02             	shl    $0x2,%eax
c01011b7:	01 d0                	add    %edx,%eax
c01011b9:	c1 e0 04             	shl    $0x4,%eax
c01011bc:	29 c1                	sub    %eax,%ecx
c01011be:	89 ca                	mov    %ecx,%edx
c01011c0:	89 d8                	mov    %ebx,%eax
c01011c2:	29 d0                	sub    %edx,%eax
c01011c4:	66 a3 44 d4 11 c0    	mov    %ax,0xc011d444
        break;
c01011ca:	eb 26                	jmp    c01011f2 <cga_putc+0xde>
    default:
        crt_buf[crt_pos ++] = c;     // write the character
c01011cc:	8b 0d 40 d4 11 c0    	mov    0xc011d440,%ecx
c01011d2:	0f b7 05 44 d4 11 c0 	movzwl 0xc011d444,%eax
c01011d9:	8d 50 01             	lea    0x1(%eax),%edx
c01011dc:	66 89 15 44 d4 11 c0 	mov    %dx,0xc011d444
c01011e3:	0f b7 c0             	movzwl %ax,%eax
c01011e6:	01 c0                	add    %eax,%eax
c01011e8:	8d 14 01             	lea    (%ecx,%eax,1),%edx
c01011eb:	8b 45 08             	mov    0x8(%ebp),%eax
c01011ee:	66 89 02             	mov    %ax,(%edx)
        break;
c01011f1:	90                   	nop
    }

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
c01011f2:	0f b7 05 44 d4 11 c0 	movzwl 0xc011d444,%eax
c01011f9:	66 3d cf 07          	cmp    $0x7cf,%ax
c01011fd:	76 5b                	jbe    c010125a <cga_putc+0x146>
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
c01011ff:	a1 40 d4 11 c0       	mov    0xc011d440,%eax
c0101204:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
c010120a:	a1 40 d4 11 c0       	mov    0xc011d440,%eax
c010120f:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
c0101216:	00 
c0101217:	89 54 24 04          	mov    %edx,0x4(%esp)
c010121b:	89 04 24             	mov    %eax,(%esp)
c010121e:	e8 83 5f 00 00       	call   c01071a6 <memmove>
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
c0101223:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
c010122a:	eb 15                	jmp    c0101241 <cga_putc+0x12d>
            crt_buf[i] = 0x0700 | ' ';
c010122c:	a1 40 d4 11 c0       	mov    0xc011d440,%eax
c0101231:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0101234:	01 d2                	add    %edx,%edx
c0101236:	01 d0                	add    %edx,%eax
c0101238:	66 c7 00 20 07       	movw   $0x720,(%eax)

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
c010123d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0101241:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
c0101248:	7e e2                	jle    c010122c <cga_putc+0x118>
            crt_buf[i] = 0x0700 | ' ';
        }
        crt_pos -= CRT_COLS;
c010124a:	0f b7 05 44 d4 11 c0 	movzwl 0xc011d444,%eax
c0101251:	83 e8 50             	sub    $0x50,%eax
c0101254:	66 a3 44 d4 11 c0    	mov    %ax,0xc011d444
    }

    // move that little blinky thing
    outb(addr_6845, 14);
c010125a:	0f b7 05 46 d4 11 c0 	movzwl 0xc011d446,%eax
c0101261:	0f b7 c0             	movzwl %ax,%eax
c0101264:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
c0101268:	c6 45 f1 0e          	movb   $0xe,-0xf(%ebp)
c010126c:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c0101270:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0101274:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos >> 8);
c0101275:	0f b7 05 44 d4 11 c0 	movzwl 0xc011d444,%eax
c010127c:	66 c1 e8 08          	shr    $0x8,%ax
c0101280:	0f b6 c0             	movzbl %al,%eax
c0101283:	0f b7 15 46 d4 11 c0 	movzwl 0xc011d446,%edx
c010128a:	83 c2 01             	add    $0x1,%edx
c010128d:	0f b7 d2             	movzwl %dx,%edx
c0101290:	66 89 55 ee          	mov    %dx,-0x12(%ebp)
c0101294:	88 45 ed             	mov    %al,-0x13(%ebp)
c0101297:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c010129b:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c010129f:	ee                   	out    %al,(%dx)
    outb(addr_6845, 15);
c01012a0:	0f b7 05 46 d4 11 c0 	movzwl 0xc011d446,%eax
c01012a7:	0f b7 c0             	movzwl %ax,%eax
c01012aa:	66 89 45 ea          	mov    %ax,-0x16(%ebp)
c01012ae:	c6 45 e9 0f          	movb   $0xf,-0x17(%ebp)
c01012b2:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c01012b6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c01012ba:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos);
c01012bb:	0f b7 05 44 d4 11 c0 	movzwl 0xc011d444,%eax
c01012c2:	0f b6 c0             	movzbl %al,%eax
c01012c5:	0f b7 15 46 d4 11 c0 	movzwl 0xc011d446,%edx
c01012cc:	83 c2 01             	add    $0x1,%edx
c01012cf:	0f b7 d2             	movzwl %dx,%edx
c01012d2:	66 89 55 e6          	mov    %dx,-0x1a(%ebp)
c01012d6:	88 45 e5             	mov    %al,-0x1b(%ebp)
c01012d9:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
c01012dd:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
c01012e1:	ee                   	out    %al,(%dx)
}
c01012e2:	83 c4 34             	add    $0x34,%esp
c01012e5:	5b                   	pop    %ebx
c01012e6:	5d                   	pop    %ebp
c01012e7:	c3                   	ret    

c01012e8 <serial_putc_sub>:

static void
serial_putc_sub(int c) {
c01012e8:	55                   	push   %ebp
c01012e9:	89 e5                	mov    %esp,%ebp
c01012eb:	83 ec 10             	sub    $0x10,%esp
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
c01012ee:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c01012f5:	eb 09                	jmp    c0101300 <serial_putc_sub+0x18>
        delay();
c01012f7:	e8 4f fb ff ff       	call   c0100e4b <delay>
}

static void
serial_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
c01012fc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c0101300:	66 c7 45 fa fd 03    	movw   $0x3fd,-0x6(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0101306:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c010130a:	89 c2                	mov    %eax,%edx
c010130c:	ec                   	in     (%dx),%al
c010130d:	88 45 f9             	mov    %al,-0x7(%ebp)
    return data;
c0101310:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
c0101314:	0f b6 c0             	movzbl %al,%eax
c0101317:	83 e0 20             	and    $0x20,%eax
c010131a:	85 c0                	test   %eax,%eax
c010131c:	75 09                	jne    c0101327 <serial_putc_sub+0x3f>
c010131e:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
c0101325:	7e d0                	jle    c01012f7 <serial_putc_sub+0xf>
        delay();
    }
    outb(COM1 + COM_TX, c);
c0101327:	8b 45 08             	mov    0x8(%ebp),%eax
c010132a:	0f b6 c0             	movzbl %al,%eax
c010132d:	66 c7 45 f6 f8 03    	movw   $0x3f8,-0xa(%ebp)
c0101333:	88 45 f5             	mov    %al,-0xb(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0101336:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
c010133a:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c010133e:	ee                   	out    %al,(%dx)
}
c010133f:	c9                   	leave  
c0101340:	c3                   	ret    

c0101341 <serial_putc>:

/* serial_putc - print character to serial port */
static void
serial_putc(int c) {
c0101341:	55                   	push   %ebp
c0101342:	89 e5                	mov    %esp,%ebp
c0101344:	83 ec 04             	sub    $0x4,%esp
    if (c != '\b') {
c0101347:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
c010134b:	74 0d                	je     c010135a <serial_putc+0x19>
        serial_putc_sub(c);
c010134d:	8b 45 08             	mov    0x8(%ebp),%eax
c0101350:	89 04 24             	mov    %eax,(%esp)
c0101353:	e8 90 ff ff ff       	call   c01012e8 <serial_putc_sub>
c0101358:	eb 24                	jmp    c010137e <serial_putc+0x3d>
    }
    else {
        serial_putc_sub('\b');
c010135a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
c0101361:	e8 82 ff ff ff       	call   c01012e8 <serial_putc_sub>
        serial_putc_sub(' ');
c0101366:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
c010136d:	e8 76 ff ff ff       	call   c01012e8 <serial_putc_sub>
        serial_putc_sub('\b');
c0101372:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
c0101379:	e8 6a ff ff ff       	call   c01012e8 <serial_putc_sub>
    }
}
c010137e:	c9                   	leave  
c010137f:	c3                   	ret    

c0101380 <cons_intr>:
/* *
 * cons_intr - called by device interrupt routines to feed input
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
c0101380:	55                   	push   %ebp
c0101381:	89 e5                	mov    %esp,%ebp
c0101383:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = (*proc)()) != -1) {
c0101386:	eb 33                	jmp    c01013bb <cons_intr+0x3b>
        if (c != 0) {
c0101388:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c010138c:	74 2d                	je     c01013bb <cons_intr+0x3b>
            cons.buf[cons.wpos ++] = c;
c010138e:	a1 64 d6 11 c0       	mov    0xc011d664,%eax
c0101393:	8d 50 01             	lea    0x1(%eax),%edx
c0101396:	89 15 64 d6 11 c0    	mov    %edx,0xc011d664
c010139c:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010139f:	88 90 60 d4 11 c0    	mov    %dl,-0x3fee2ba0(%eax)
            if (cons.wpos == CONSBUFSIZE) {
c01013a5:	a1 64 d6 11 c0       	mov    0xc011d664,%eax
c01013aa:	3d 00 02 00 00       	cmp    $0x200,%eax
c01013af:	75 0a                	jne    c01013bb <cons_intr+0x3b>
                cons.wpos = 0;
c01013b1:	c7 05 64 d6 11 c0 00 	movl   $0x0,0xc011d664
c01013b8:	00 00 00 
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
    int c;
    while ((c = (*proc)()) != -1) {
c01013bb:	8b 45 08             	mov    0x8(%ebp),%eax
c01013be:	ff d0                	call   *%eax
c01013c0:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01013c3:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
c01013c7:	75 bf                	jne    c0101388 <cons_intr+0x8>
            if (cons.wpos == CONSBUFSIZE) {
                cons.wpos = 0;
            }
        }
    }
}
c01013c9:	c9                   	leave  
c01013ca:	c3                   	ret    

c01013cb <serial_proc_data>:

/* serial_proc_data - get data from serial port */
static int
serial_proc_data(void) {
c01013cb:	55                   	push   %ebp
c01013cc:	89 e5                	mov    %esp,%ebp
c01013ce:	83 ec 10             	sub    $0x10,%esp
c01013d1:	66 c7 45 fa fd 03    	movw   $0x3fd,-0x6(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c01013d7:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c01013db:	89 c2                	mov    %eax,%edx
c01013dd:	ec                   	in     (%dx),%al
c01013de:	88 45 f9             	mov    %al,-0x7(%ebp)
    return data;
c01013e1:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
    if (!(inb(COM1 + COM_LSR) & COM_LSR_DATA)) {
c01013e5:	0f b6 c0             	movzbl %al,%eax
c01013e8:	83 e0 01             	and    $0x1,%eax
c01013eb:	85 c0                	test   %eax,%eax
c01013ed:	75 07                	jne    c01013f6 <serial_proc_data+0x2b>
        return -1;
c01013ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c01013f4:	eb 2a                	jmp    c0101420 <serial_proc_data+0x55>
c01013f6:	66 c7 45 f6 f8 03    	movw   $0x3f8,-0xa(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c01013fc:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0101400:	89 c2                	mov    %eax,%edx
c0101402:	ec                   	in     (%dx),%al
c0101403:	88 45 f5             	mov    %al,-0xb(%ebp)
    return data;
c0101406:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
    }
    int c = inb(COM1 + COM_RX);
c010140a:	0f b6 c0             	movzbl %al,%eax
c010140d:	89 45 fc             	mov    %eax,-0x4(%ebp)
    if (c == 127) {
c0101410:	83 7d fc 7f          	cmpl   $0x7f,-0x4(%ebp)
c0101414:	75 07                	jne    c010141d <serial_proc_data+0x52>
        c = '\b';
c0101416:	c7 45 fc 08 00 00 00 	movl   $0x8,-0x4(%ebp)
    }
    return c;
c010141d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0101420:	c9                   	leave  
c0101421:	c3                   	ret    

c0101422 <serial_intr>:

/* serial_intr - try to feed input characters from serial port */
void
serial_intr(void) {
c0101422:	55                   	push   %ebp
c0101423:	89 e5                	mov    %esp,%ebp
c0101425:	83 ec 18             	sub    $0x18,%esp
    if (serial_exists) {
c0101428:	a1 48 d4 11 c0       	mov    0xc011d448,%eax
c010142d:	85 c0                	test   %eax,%eax
c010142f:	74 0c                	je     c010143d <serial_intr+0x1b>
        cons_intr(serial_proc_data);
c0101431:	c7 04 24 cb 13 10 c0 	movl   $0xc01013cb,(%esp)
c0101438:	e8 43 ff ff ff       	call   c0101380 <cons_intr>
    }
}
c010143d:	c9                   	leave  
c010143e:	c3                   	ret    

c010143f <kbd_proc_data>:
 *
 * The kbd_proc_data() function gets data from the keyboard.
 * If we finish a character, return it, else 0. And return -1 if no data.
 * */
static int
kbd_proc_data(void) {
c010143f:	55                   	push   %ebp
c0101440:	89 e5                	mov    %esp,%ebp
c0101442:	83 ec 38             	sub    $0x38,%esp
c0101445:	66 c7 45 f0 64 00    	movw   $0x64,-0x10(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c010144b:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
c010144f:	89 c2                	mov    %eax,%edx
c0101451:	ec                   	in     (%dx),%al
c0101452:	88 45 ef             	mov    %al,-0x11(%ebp)
    return data;
c0101455:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
    int c;
    uint8_t data;
    static uint32_t shift;

    if ((inb(KBSTATP) & KBS_DIB) == 0) {
c0101459:	0f b6 c0             	movzbl %al,%eax
c010145c:	83 e0 01             	and    $0x1,%eax
c010145f:	85 c0                	test   %eax,%eax
c0101461:	75 0a                	jne    c010146d <kbd_proc_data+0x2e>
        return -1;
c0101463:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c0101468:	e9 59 01 00 00       	jmp    c01015c6 <kbd_proc_data+0x187>
c010146d:	66 c7 45 ec 60 00    	movw   $0x60,-0x14(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0101473:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
c0101477:	89 c2                	mov    %eax,%edx
c0101479:	ec                   	in     (%dx),%al
c010147a:	88 45 eb             	mov    %al,-0x15(%ebp)
    return data;
c010147d:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
    }

    data = inb(KBDATAP);
c0101481:	88 45 f3             	mov    %al,-0xd(%ebp)

    if (data == 0xE0) {
c0101484:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
c0101488:	75 17                	jne    c01014a1 <kbd_proc_data+0x62>
        // E0 escape character
        shift |= E0ESC;
c010148a:	a1 68 d6 11 c0       	mov    0xc011d668,%eax
c010148f:	83 c8 40             	or     $0x40,%eax
c0101492:	a3 68 d6 11 c0       	mov    %eax,0xc011d668
        return 0;
c0101497:	b8 00 00 00 00       	mov    $0x0,%eax
c010149c:	e9 25 01 00 00       	jmp    c01015c6 <kbd_proc_data+0x187>
    } else if (data & 0x80) {
c01014a1:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c01014a5:	84 c0                	test   %al,%al
c01014a7:	79 47                	jns    c01014f0 <kbd_proc_data+0xb1>
        // Key released
        data = (shift & E0ESC ? data : data & 0x7F);
c01014a9:	a1 68 d6 11 c0       	mov    0xc011d668,%eax
c01014ae:	83 e0 40             	and    $0x40,%eax
c01014b1:	85 c0                	test   %eax,%eax
c01014b3:	75 09                	jne    c01014be <kbd_proc_data+0x7f>
c01014b5:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c01014b9:	83 e0 7f             	and    $0x7f,%eax
c01014bc:	eb 04                	jmp    c01014c2 <kbd_proc_data+0x83>
c01014be:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c01014c2:	88 45 f3             	mov    %al,-0xd(%ebp)
        shift &= ~(shiftcode[data] | E0ESC);
c01014c5:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c01014c9:	0f b6 80 40 a0 11 c0 	movzbl -0x3fee5fc0(%eax),%eax
c01014d0:	83 c8 40             	or     $0x40,%eax
c01014d3:	0f b6 c0             	movzbl %al,%eax
c01014d6:	f7 d0                	not    %eax
c01014d8:	89 c2                	mov    %eax,%edx
c01014da:	a1 68 d6 11 c0       	mov    0xc011d668,%eax
c01014df:	21 d0                	and    %edx,%eax
c01014e1:	a3 68 d6 11 c0       	mov    %eax,0xc011d668
        return 0;
c01014e6:	b8 00 00 00 00       	mov    $0x0,%eax
c01014eb:	e9 d6 00 00 00       	jmp    c01015c6 <kbd_proc_data+0x187>
    } else if (shift & E0ESC) {
c01014f0:	a1 68 d6 11 c0       	mov    0xc011d668,%eax
c01014f5:	83 e0 40             	and    $0x40,%eax
c01014f8:	85 c0                	test   %eax,%eax
c01014fa:	74 11                	je     c010150d <kbd_proc_data+0xce>
        // Last character was an E0 escape; or with 0x80
        data |= 0x80;
c01014fc:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
        shift &= ~E0ESC;
c0101500:	a1 68 d6 11 c0       	mov    0xc011d668,%eax
c0101505:	83 e0 bf             	and    $0xffffffbf,%eax
c0101508:	a3 68 d6 11 c0       	mov    %eax,0xc011d668
    }

    shift |= shiftcode[data];
c010150d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101511:	0f b6 80 40 a0 11 c0 	movzbl -0x3fee5fc0(%eax),%eax
c0101518:	0f b6 d0             	movzbl %al,%edx
c010151b:	a1 68 d6 11 c0       	mov    0xc011d668,%eax
c0101520:	09 d0                	or     %edx,%eax
c0101522:	a3 68 d6 11 c0       	mov    %eax,0xc011d668
    shift ^= togglecode[data];
c0101527:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c010152b:	0f b6 80 40 a1 11 c0 	movzbl -0x3fee5ec0(%eax),%eax
c0101532:	0f b6 d0             	movzbl %al,%edx
c0101535:	a1 68 d6 11 c0       	mov    0xc011d668,%eax
c010153a:	31 d0                	xor    %edx,%eax
c010153c:	a3 68 d6 11 c0       	mov    %eax,0xc011d668

    c = charcode[shift & (CTL | SHIFT)][data];
c0101541:	a1 68 d6 11 c0       	mov    0xc011d668,%eax
c0101546:	83 e0 03             	and    $0x3,%eax
c0101549:	8b 14 85 40 a5 11 c0 	mov    -0x3fee5ac0(,%eax,4),%edx
c0101550:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101554:	01 d0                	add    %edx,%eax
c0101556:	0f b6 00             	movzbl (%eax),%eax
c0101559:	0f b6 c0             	movzbl %al,%eax
c010155c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (shift & CAPSLOCK) {
c010155f:	a1 68 d6 11 c0       	mov    0xc011d668,%eax
c0101564:	83 e0 08             	and    $0x8,%eax
c0101567:	85 c0                	test   %eax,%eax
c0101569:	74 22                	je     c010158d <kbd_proc_data+0x14e>
        if ('a' <= c && c <= 'z')
c010156b:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
c010156f:	7e 0c                	jle    c010157d <kbd_proc_data+0x13e>
c0101571:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
c0101575:	7f 06                	jg     c010157d <kbd_proc_data+0x13e>
            c += 'A' - 'a';
c0101577:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
c010157b:	eb 10                	jmp    c010158d <kbd_proc_data+0x14e>
        else if ('A' <= c && c <= 'Z')
c010157d:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
c0101581:	7e 0a                	jle    c010158d <kbd_proc_data+0x14e>
c0101583:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
c0101587:	7f 04                	jg     c010158d <kbd_proc_data+0x14e>
            c += 'a' - 'A';
c0101589:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
    }

    // Process special keys
    // Ctrl-Alt-Del: reboot
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
c010158d:	a1 68 d6 11 c0       	mov    0xc011d668,%eax
c0101592:	f7 d0                	not    %eax
c0101594:	83 e0 06             	and    $0x6,%eax
c0101597:	85 c0                	test   %eax,%eax
c0101599:	75 28                	jne    c01015c3 <kbd_proc_data+0x184>
c010159b:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
c01015a2:	75 1f                	jne    c01015c3 <kbd_proc_data+0x184>
        cprintf("Rebooting!\n");
c01015a4:	c7 04 24 37 76 10 c0 	movl   $0xc0107637,(%esp)
c01015ab:	e8 a4 ed ff ff       	call   c0100354 <cprintf>
c01015b0:	66 c7 45 e8 92 00    	movw   $0x92,-0x18(%ebp)
c01015b6:	c6 45 e7 03          	movb   $0x3,-0x19(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c01015ba:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
c01015be:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
c01015c2:	ee                   	out    %al,(%dx)
        outb(0x92, 0x3); // courtesy of Chris Frost
    }
    return c;
c01015c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01015c6:	c9                   	leave  
c01015c7:	c3                   	ret    

c01015c8 <kbd_intr>:

/* kbd_intr - try to feed input characters from keyboard */
static void
kbd_intr(void) {
c01015c8:	55                   	push   %ebp
c01015c9:	89 e5                	mov    %esp,%ebp
c01015cb:	83 ec 18             	sub    $0x18,%esp
    cons_intr(kbd_proc_data);
c01015ce:	c7 04 24 3f 14 10 c0 	movl   $0xc010143f,(%esp)
c01015d5:	e8 a6 fd ff ff       	call   c0101380 <cons_intr>
}
c01015da:	c9                   	leave  
c01015db:	c3                   	ret    

c01015dc <kbd_init>:

static void
kbd_init(void) {
c01015dc:	55                   	push   %ebp
c01015dd:	89 e5                	mov    %esp,%ebp
c01015df:	83 ec 18             	sub    $0x18,%esp
    // drain the kbd buffer
    kbd_intr();
c01015e2:	e8 e1 ff ff ff       	call   c01015c8 <kbd_intr>
    pic_enable(IRQ_KBD);
c01015e7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01015ee:	e8 3d 01 00 00       	call   c0101730 <pic_enable>
}
c01015f3:	c9                   	leave  
c01015f4:	c3                   	ret    

c01015f5 <cons_init>:

/* cons_init - initializes the console devices */
void
cons_init(void) {
c01015f5:	55                   	push   %ebp
c01015f6:	89 e5                	mov    %esp,%ebp
c01015f8:	83 ec 18             	sub    $0x18,%esp
    cga_init();
c01015fb:	e8 93 f8 ff ff       	call   c0100e93 <cga_init>
    serial_init();
c0101600:	e8 74 f9 ff ff       	call   c0100f79 <serial_init>
    kbd_init();
c0101605:	e8 d2 ff ff ff       	call   c01015dc <kbd_init>
    if (!serial_exists) {
c010160a:	a1 48 d4 11 c0       	mov    0xc011d448,%eax
c010160f:	85 c0                	test   %eax,%eax
c0101611:	75 0c                	jne    c010161f <cons_init+0x2a>
        cprintf("serial port does not exist!!\n");
c0101613:	c7 04 24 43 76 10 c0 	movl   $0xc0107643,(%esp)
c010161a:	e8 35 ed ff ff       	call   c0100354 <cprintf>
    }
}
c010161f:	c9                   	leave  
c0101620:	c3                   	ret    

c0101621 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void
cons_putc(int c) {
c0101621:	55                   	push   %ebp
c0101622:	89 e5                	mov    %esp,%ebp
c0101624:	83 ec 28             	sub    $0x28,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
c0101627:	e8 e2 f7 ff ff       	call   c0100e0e <__intr_save>
c010162c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        lpt_putc(c);
c010162f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101632:	89 04 24             	mov    %eax,(%esp)
c0101635:	e8 9b fa ff ff       	call   c01010d5 <lpt_putc>
        cga_putc(c);
c010163a:	8b 45 08             	mov    0x8(%ebp),%eax
c010163d:	89 04 24             	mov    %eax,(%esp)
c0101640:	e8 cf fa ff ff       	call   c0101114 <cga_putc>
        serial_putc(c);
c0101645:	8b 45 08             	mov    0x8(%ebp),%eax
c0101648:	89 04 24             	mov    %eax,(%esp)
c010164b:	e8 f1 fc ff ff       	call   c0101341 <serial_putc>
    }
    local_intr_restore(intr_flag);
c0101650:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101653:	89 04 24             	mov    %eax,(%esp)
c0101656:	e8 dd f7 ff ff       	call   c0100e38 <__intr_restore>
}
c010165b:	c9                   	leave  
c010165c:	c3                   	ret    

c010165d <cons_getc>:
/* *
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int
cons_getc(void) {
c010165d:	55                   	push   %ebp
c010165e:	89 e5                	mov    %esp,%ebp
c0101660:	83 ec 28             	sub    $0x28,%esp
    int c = 0;
c0101663:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
c010166a:	e8 9f f7 ff ff       	call   c0100e0e <__intr_save>
c010166f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        // poll for any pending input characters,
        // so that this function works even when interrupts are disabled
        // (e.g., when called from the kernel monitor).
        serial_intr();
c0101672:	e8 ab fd ff ff       	call   c0101422 <serial_intr>
        kbd_intr();
c0101677:	e8 4c ff ff ff       	call   c01015c8 <kbd_intr>

        // grab the next character from the input buffer.
        if (cons.rpos != cons.wpos) {
c010167c:	8b 15 60 d6 11 c0    	mov    0xc011d660,%edx
c0101682:	a1 64 d6 11 c0       	mov    0xc011d664,%eax
c0101687:	39 c2                	cmp    %eax,%edx
c0101689:	74 31                	je     c01016bc <cons_getc+0x5f>
            c = cons.buf[cons.rpos ++];
c010168b:	a1 60 d6 11 c0       	mov    0xc011d660,%eax
c0101690:	8d 50 01             	lea    0x1(%eax),%edx
c0101693:	89 15 60 d6 11 c0    	mov    %edx,0xc011d660
c0101699:	0f b6 80 60 d4 11 c0 	movzbl -0x3fee2ba0(%eax),%eax
c01016a0:	0f b6 c0             	movzbl %al,%eax
c01016a3:	89 45 f4             	mov    %eax,-0xc(%ebp)
            if (cons.rpos == CONSBUFSIZE) {
c01016a6:	a1 60 d6 11 c0       	mov    0xc011d660,%eax
c01016ab:	3d 00 02 00 00       	cmp    $0x200,%eax
c01016b0:	75 0a                	jne    c01016bc <cons_getc+0x5f>
                cons.rpos = 0;
c01016b2:	c7 05 60 d6 11 c0 00 	movl   $0x0,0xc011d660
c01016b9:	00 00 00 
            }
        }
    }
    local_intr_restore(intr_flag);
c01016bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01016bf:	89 04 24             	mov    %eax,(%esp)
c01016c2:	e8 71 f7 ff ff       	call   c0100e38 <__intr_restore>
    return c;
c01016c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01016ca:	c9                   	leave  
c01016cb:	c3                   	ret    

c01016cc <intr_enable>:
#include <x86.h>
#include <intr.h>

/* intr_enable - enable irq interrupt */
void
intr_enable(void) {
c01016cc:	55                   	push   %ebp
c01016cd:	89 e5                	mov    %esp,%ebp
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
}

static inline void
sti(void) {
    asm volatile ("sti");
c01016cf:	fb                   	sti    
    sti();
}
c01016d0:	5d                   	pop    %ebp
c01016d1:	c3                   	ret    

c01016d2 <intr_disable>:

/* intr_disable - disable irq interrupt */
void
intr_disable(void) {
c01016d2:	55                   	push   %ebp
c01016d3:	89 e5                	mov    %esp,%ebp
}

static inline void
cli(void) {
    asm volatile ("cli" ::: "memory");
c01016d5:	fa                   	cli    
    cli();
}
c01016d6:	5d                   	pop    %ebp
c01016d7:	c3                   	ret    

c01016d8 <pic_setmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static uint16_t irq_mask = 0xFFFF & ~(1 << IRQ_SLAVE);
static bool did_init = 0;

static void
pic_setmask(uint16_t mask) {
c01016d8:	55                   	push   %ebp
c01016d9:	89 e5                	mov    %esp,%ebp
c01016db:	83 ec 14             	sub    $0x14,%esp
c01016de:	8b 45 08             	mov    0x8(%ebp),%eax
c01016e1:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
    irq_mask = mask;
c01016e5:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
c01016e9:	66 a3 50 a5 11 c0    	mov    %ax,0xc011a550
    if (did_init) {
c01016ef:	a1 6c d6 11 c0       	mov    0xc011d66c,%eax
c01016f4:	85 c0                	test   %eax,%eax
c01016f6:	74 36                	je     c010172e <pic_setmask+0x56>
        outb(IO_PIC1 + 1, mask);
c01016f8:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
c01016fc:	0f b6 c0             	movzbl %al,%eax
c01016ff:	66 c7 45 fe 21 00    	movw   $0x21,-0x2(%ebp)
c0101705:	88 45 fd             	mov    %al,-0x3(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0101708:	0f b6 45 fd          	movzbl -0x3(%ebp),%eax
c010170c:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
c0101710:	ee                   	out    %al,(%dx)
        outb(IO_PIC2 + 1, mask >> 8);
c0101711:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
c0101715:	66 c1 e8 08          	shr    $0x8,%ax
c0101719:	0f b6 c0             	movzbl %al,%eax
c010171c:	66 c7 45 fa a1 00    	movw   $0xa1,-0x6(%ebp)
c0101722:	88 45 f9             	mov    %al,-0x7(%ebp)
c0101725:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
c0101729:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c010172d:	ee                   	out    %al,(%dx)
    }
}
c010172e:	c9                   	leave  
c010172f:	c3                   	ret    

c0101730 <pic_enable>:

void
pic_enable(unsigned int irq) {
c0101730:	55                   	push   %ebp
c0101731:	89 e5                	mov    %esp,%ebp
c0101733:	83 ec 04             	sub    $0x4,%esp
    pic_setmask(irq_mask & ~(1 << irq));
c0101736:	8b 45 08             	mov    0x8(%ebp),%eax
c0101739:	ba 01 00 00 00       	mov    $0x1,%edx
c010173e:	89 c1                	mov    %eax,%ecx
c0101740:	d3 e2                	shl    %cl,%edx
c0101742:	89 d0                	mov    %edx,%eax
c0101744:	f7 d0                	not    %eax
c0101746:	89 c2                	mov    %eax,%edx
c0101748:	0f b7 05 50 a5 11 c0 	movzwl 0xc011a550,%eax
c010174f:	21 d0                	and    %edx,%eax
c0101751:	0f b7 c0             	movzwl %ax,%eax
c0101754:	89 04 24             	mov    %eax,(%esp)
c0101757:	e8 7c ff ff ff       	call   c01016d8 <pic_setmask>
}
c010175c:	c9                   	leave  
c010175d:	c3                   	ret    

c010175e <pic_init>:

/* pic_init - initialize the 8259A interrupt controllers */
void
pic_init(void) {
c010175e:	55                   	push   %ebp
c010175f:	89 e5                	mov    %esp,%ebp
c0101761:	83 ec 44             	sub    $0x44,%esp
    did_init = 1;
c0101764:	c7 05 6c d6 11 c0 01 	movl   $0x1,0xc011d66c
c010176b:	00 00 00 
c010176e:	66 c7 45 fe 21 00    	movw   $0x21,-0x2(%ebp)
c0101774:	c6 45 fd ff          	movb   $0xff,-0x3(%ebp)
c0101778:	0f b6 45 fd          	movzbl -0x3(%ebp),%eax
c010177c:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
c0101780:	ee                   	out    %al,(%dx)
c0101781:	66 c7 45 fa a1 00    	movw   $0xa1,-0x6(%ebp)
c0101787:	c6 45 f9 ff          	movb   $0xff,-0x7(%ebp)
c010178b:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
c010178f:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c0101793:	ee                   	out    %al,(%dx)
c0101794:	66 c7 45 f6 20 00    	movw   $0x20,-0xa(%ebp)
c010179a:	c6 45 f5 11          	movb   $0x11,-0xb(%ebp)
c010179e:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
c01017a2:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c01017a6:	ee                   	out    %al,(%dx)
c01017a7:	66 c7 45 f2 21 00    	movw   $0x21,-0xe(%ebp)
c01017ad:	c6 45 f1 20          	movb   $0x20,-0xf(%ebp)
c01017b1:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c01017b5:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c01017b9:	ee                   	out    %al,(%dx)
c01017ba:	66 c7 45 ee 21 00    	movw   $0x21,-0x12(%ebp)
c01017c0:	c6 45 ed 04          	movb   $0x4,-0x13(%ebp)
c01017c4:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c01017c8:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c01017cc:	ee                   	out    %al,(%dx)
c01017cd:	66 c7 45 ea 21 00    	movw   $0x21,-0x16(%ebp)
c01017d3:	c6 45 e9 03          	movb   $0x3,-0x17(%ebp)
c01017d7:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c01017db:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c01017df:	ee                   	out    %al,(%dx)
c01017e0:	66 c7 45 e6 a0 00    	movw   $0xa0,-0x1a(%ebp)
c01017e6:	c6 45 e5 11          	movb   $0x11,-0x1b(%ebp)
c01017ea:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
c01017ee:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
c01017f2:	ee                   	out    %al,(%dx)
c01017f3:	66 c7 45 e2 a1 00    	movw   $0xa1,-0x1e(%ebp)
c01017f9:	c6 45 e1 28          	movb   $0x28,-0x1f(%ebp)
c01017fd:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
c0101801:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
c0101805:	ee                   	out    %al,(%dx)
c0101806:	66 c7 45 de a1 00    	movw   $0xa1,-0x22(%ebp)
c010180c:	c6 45 dd 02          	movb   $0x2,-0x23(%ebp)
c0101810:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
c0101814:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
c0101818:	ee                   	out    %al,(%dx)
c0101819:	66 c7 45 da a1 00    	movw   $0xa1,-0x26(%ebp)
c010181f:	c6 45 d9 03          	movb   $0x3,-0x27(%ebp)
c0101823:	0f b6 45 d9          	movzbl -0x27(%ebp),%eax
c0101827:	0f b7 55 da          	movzwl -0x26(%ebp),%edx
c010182b:	ee                   	out    %al,(%dx)
c010182c:	66 c7 45 d6 20 00    	movw   $0x20,-0x2a(%ebp)
c0101832:	c6 45 d5 68          	movb   $0x68,-0x2b(%ebp)
c0101836:	0f b6 45 d5          	movzbl -0x2b(%ebp),%eax
c010183a:	0f b7 55 d6          	movzwl -0x2a(%ebp),%edx
c010183e:	ee                   	out    %al,(%dx)
c010183f:	66 c7 45 d2 20 00    	movw   $0x20,-0x2e(%ebp)
c0101845:	c6 45 d1 0a          	movb   $0xa,-0x2f(%ebp)
c0101849:	0f b6 45 d1          	movzbl -0x2f(%ebp),%eax
c010184d:	0f b7 55 d2          	movzwl -0x2e(%ebp),%edx
c0101851:	ee                   	out    %al,(%dx)
c0101852:	66 c7 45 ce a0 00    	movw   $0xa0,-0x32(%ebp)
c0101858:	c6 45 cd 68          	movb   $0x68,-0x33(%ebp)
c010185c:	0f b6 45 cd          	movzbl -0x33(%ebp),%eax
c0101860:	0f b7 55 ce          	movzwl -0x32(%ebp),%edx
c0101864:	ee                   	out    %al,(%dx)
c0101865:	66 c7 45 ca a0 00    	movw   $0xa0,-0x36(%ebp)
c010186b:	c6 45 c9 0a          	movb   $0xa,-0x37(%ebp)
c010186f:	0f b6 45 c9          	movzbl -0x37(%ebp),%eax
c0101873:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
c0101877:	ee                   	out    %al,(%dx)
    outb(IO_PIC1, 0x0a);    // read IRR by default

    outb(IO_PIC2, 0x68);    // OCW3
    outb(IO_PIC2, 0x0a);    // OCW3

    if (irq_mask != 0xFFFF) {
c0101878:	0f b7 05 50 a5 11 c0 	movzwl 0xc011a550,%eax
c010187f:	66 83 f8 ff          	cmp    $0xffff,%ax
c0101883:	74 12                	je     c0101897 <pic_init+0x139>
        pic_setmask(irq_mask);
c0101885:	0f b7 05 50 a5 11 c0 	movzwl 0xc011a550,%eax
c010188c:	0f b7 c0             	movzwl %ax,%eax
c010188f:	89 04 24             	mov    %eax,(%esp)
c0101892:	e8 41 fe ff ff       	call   c01016d8 <pic_setmask>
    }
}
c0101897:	c9                   	leave  
c0101898:	c3                   	ret    

c0101899 <print_ticks>:
#include <console.h>
#include <kdebug.h>

#define TICK_NUM 100

static void print_ticks() {
c0101899:	55                   	push   %ebp
c010189a:	89 e5                	mov    %esp,%ebp
c010189c:	83 ec 18             	sub    $0x18,%esp
    cprintf("%d ticks\n",TICK_NUM);
c010189f:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
c01018a6:	00 
c01018a7:	c7 04 24 80 76 10 c0 	movl   $0xc0107680,(%esp)
c01018ae:	e8 a1 ea ff ff       	call   c0100354 <cprintf>
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}
c01018b3:	c9                   	leave  
c01018b4:	c3                   	ret    

c01018b5 <idt_init>:
    sizeof(idt) - 1, (uintptr_t)idt
};

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S */
void
idt_init(void) {
c01018b5:	55                   	push   %ebp
c01018b6:	89 e5                	mov    %esp,%ebp
c01018b8:	83 ec 10             	sub    $0x10,%esp
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
    extern uintptr_t __vectors[];
    int i;
    for (i = 0; i < 256; i++) {
c01018bb:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c01018c2:	e9 c3 00 00 00       	jmp    c010198a <idt_init+0xd5>
        SETGATE(idt[i], 0, GD_KTEXT, __vectors[i], DPL_KERNEL);
c01018c7:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018ca:	8b 04 85 e0 a5 11 c0 	mov    -0x3fee5a20(,%eax,4),%eax
c01018d1:	89 c2                	mov    %eax,%edx
c01018d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018d6:	66 89 14 c5 80 d6 11 	mov    %dx,-0x3fee2980(,%eax,8)
c01018dd:	c0 
c01018de:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018e1:	66 c7 04 c5 82 d6 11 	movw   $0x8,-0x3fee297e(,%eax,8)
c01018e8:	c0 08 00 
c01018eb:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018ee:	0f b6 14 c5 84 d6 11 	movzbl -0x3fee297c(,%eax,8),%edx
c01018f5:	c0 
c01018f6:	83 e2 e0             	and    $0xffffffe0,%edx
c01018f9:	88 14 c5 84 d6 11 c0 	mov    %dl,-0x3fee297c(,%eax,8)
c0101900:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101903:	0f b6 14 c5 84 d6 11 	movzbl -0x3fee297c(,%eax,8),%edx
c010190a:	c0 
c010190b:	83 e2 1f             	and    $0x1f,%edx
c010190e:	88 14 c5 84 d6 11 c0 	mov    %dl,-0x3fee297c(,%eax,8)
c0101915:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101918:	0f b6 14 c5 85 d6 11 	movzbl -0x3fee297b(,%eax,8),%edx
c010191f:	c0 
c0101920:	83 e2 f0             	and    $0xfffffff0,%edx
c0101923:	83 ca 0e             	or     $0xe,%edx
c0101926:	88 14 c5 85 d6 11 c0 	mov    %dl,-0x3fee297b(,%eax,8)
c010192d:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101930:	0f b6 14 c5 85 d6 11 	movzbl -0x3fee297b(,%eax,8),%edx
c0101937:	c0 
c0101938:	83 e2 ef             	and    $0xffffffef,%edx
c010193b:	88 14 c5 85 d6 11 c0 	mov    %dl,-0x3fee297b(,%eax,8)
c0101942:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101945:	0f b6 14 c5 85 d6 11 	movzbl -0x3fee297b(,%eax,8),%edx
c010194c:	c0 
c010194d:	83 e2 9f             	and    $0xffffff9f,%edx
c0101950:	88 14 c5 85 d6 11 c0 	mov    %dl,-0x3fee297b(,%eax,8)
c0101957:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010195a:	0f b6 14 c5 85 d6 11 	movzbl -0x3fee297b(,%eax,8),%edx
c0101961:	c0 
c0101962:	83 ca 80             	or     $0xffffff80,%edx
c0101965:	88 14 c5 85 d6 11 c0 	mov    %dl,-0x3fee297b(,%eax,8)
c010196c:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010196f:	8b 04 85 e0 a5 11 c0 	mov    -0x3fee5a20(,%eax,4),%eax
c0101976:	c1 e8 10             	shr    $0x10,%eax
c0101979:	89 c2                	mov    %eax,%edx
c010197b:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010197e:	66 89 14 c5 86 d6 11 	mov    %dx,-0x3fee297a(,%eax,8)
c0101985:	c0 
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
    extern uintptr_t __vectors[];
    int i;
    for (i = 0; i < 256; i++) {
c0101986:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c010198a:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
c0101991:	0f 8e 30 ff ff ff    	jle    c01018c7 <idt_init+0x12>
        SETGATE(idt[i], 0, GD_KTEXT, __vectors[i], DPL_KERNEL);
    }
    // 只有0x80这个特殊，用户就能用，而且是trap门
    SETGATE(idt[T_SYSCALL], 1, GD_KTEXT, __vectors[T_SYSCALL], DPL_USER);
c0101997:	a1 e0 a7 11 c0       	mov    0xc011a7e0,%eax
c010199c:	66 a3 80 da 11 c0    	mov    %ax,0xc011da80
c01019a2:	66 c7 05 82 da 11 c0 	movw   $0x8,0xc011da82
c01019a9:	08 00 
c01019ab:	0f b6 05 84 da 11 c0 	movzbl 0xc011da84,%eax
c01019b2:	83 e0 e0             	and    $0xffffffe0,%eax
c01019b5:	a2 84 da 11 c0       	mov    %al,0xc011da84
c01019ba:	0f b6 05 84 da 11 c0 	movzbl 0xc011da84,%eax
c01019c1:	83 e0 1f             	and    $0x1f,%eax
c01019c4:	a2 84 da 11 c0       	mov    %al,0xc011da84
c01019c9:	0f b6 05 85 da 11 c0 	movzbl 0xc011da85,%eax
c01019d0:	83 c8 0f             	or     $0xf,%eax
c01019d3:	a2 85 da 11 c0       	mov    %al,0xc011da85
c01019d8:	0f b6 05 85 da 11 c0 	movzbl 0xc011da85,%eax
c01019df:	83 e0 ef             	and    $0xffffffef,%eax
c01019e2:	a2 85 da 11 c0       	mov    %al,0xc011da85
c01019e7:	0f b6 05 85 da 11 c0 	movzbl 0xc011da85,%eax
c01019ee:	83 c8 60             	or     $0x60,%eax
c01019f1:	a2 85 da 11 c0       	mov    %al,0xc011da85
c01019f6:	0f b6 05 85 da 11 c0 	movzbl 0xc011da85,%eax
c01019fd:	83 c8 80             	or     $0xffffff80,%eax
c0101a00:	a2 85 da 11 c0       	mov    %al,0xc011da85
c0101a05:	a1 e0 a7 11 c0       	mov    0xc011a7e0,%eax
c0101a0a:	c1 e8 10             	shr    $0x10,%eax
c0101a0d:	66 a3 86 da 11 c0    	mov    %ax,0xc011da86
    SETGATE(idt[T_SWITCH_TOU], 0, GD_KTEXT, __vectors[T_SWITCH_TOU], DPL_KERNEL);
c0101a13:	a1 c0 a7 11 c0       	mov    0xc011a7c0,%eax
c0101a18:	66 a3 40 da 11 c0    	mov    %ax,0xc011da40
c0101a1e:	66 c7 05 42 da 11 c0 	movw   $0x8,0xc011da42
c0101a25:	08 00 
c0101a27:	0f b6 05 44 da 11 c0 	movzbl 0xc011da44,%eax
c0101a2e:	83 e0 e0             	and    $0xffffffe0,%eax
c0101a31:	a2 44 da 11 c0       	mov    %al,0xc011da44
c0101a36:	0f b6 05 44 da 11 c0 	movzbl 0xc011da44,%eax
c0101a3d:	83 e0 1f             	and    $0x1f,%eax
c0101a40:	a2 44 da 11 c0       	mov    %al,0xc011da44
c0101a45:	0f b6 05 45 da 11 c0 	movzbl 0xc011da45,%eax
c0101a4c:	83 e0 f0             	and    $0xfffffff0,%eax
c0101a4f:	83 c8 0e             	or     $0xe,%eax
c0101a52:	a2 45 da 11 c0       	mov    %al,0xc011da45
c0101a57:	0f b6 05 45 da 11 c0 	movzbl 0xc011da45,%eax
c0101a5e:	83 e0 ef             	and    $0xffffffef,%eax
c0101a61:	a2 45 da 11 c0       	mov    %al,0xc011da45
c0101a66:	0f b6 05 45 da 11 c0 	movzbl 0xc011da45,%eax
c0101a6d:	83 e0 9f             	and    $0xffffff9f,%eax
c0101a70:	a2 45 da 11 c0       	mov    %al,0xc011da45
c0101a75:	0f b6 05 45 da 11 c0 	movzbl 0xc011da45,%eax
c0101a7c:	83 c8 80             	or     $0xffffff80,%eax
c0101a7f:	a2 45 da 11 c0       	mov    %al,0xc011da45
c0101a84:	a1 c0 a7 11 c0       	mov    0xc011a7c0,%eax
c0101a89:	c1 e8 10             	shr    $0x10,%eax
c0101a8c:	66 a3 46 da 11 c0    	mov    %ax,0xc011da46
    SETGATE(idt[T_SWITCH_TOK], 0, GD_KTEXT, __vectors[T_SWITCH_TOK], DPL_USER);
c0101a92:	a1 c4 a7 11 c0       	mov    0xc011a7c4,%eax
c0101a97:	66 a3 48 da 11 c0    	mov    %ax,0xc011da48
c0101a9d:	66 c7 05 4a da 11 c0 	movw   $0x8,0xc011da4a
c0101aa4:	08 00 
c0101aa6:	0f b6 05 4c da 11 c0 	movzbl 0xc011da4c,%eax
c0101aad:	83 e0 e0             	and    $0xffffffe0,%eax
c0101ab0:	a2 4c da 11 c0       	mov    %al,0xc011da4c
c0101ab5:	0f b6 05 4c da 11 c0 	movzbl 0xc011da4c,%eax
c0101abc:	83 e0 1f             	and    $0x1f,%eax
c0101abf:	a2 4c da 11 c0       	mov    %al,0xc011da4c
c0101ac4:	0f b6 05 4d da 11 c0 	movzbl 0xc011da4d,%eax
c0101acb:	83 e0 f0             	and    $0xfffffff0,%eax
c0101ace:	83 c8 0e             	or     $0xe,%eax
c0101ad1:	a2 4d da 11 c0       	mov    %al,0xc011da4d
c0101ad6:	0f b6 05 4d da 11 c0 	movzbl 0xc011da4d,%eax
c0101add:	83 e0 ef             	and    $0xffffffef,%eax
c0101ae0:	a2 4d da 11 c0       	mov    %al,0xc011da4d
c0101ae5:	0f b6 05 4d da 11 c0 	movzbl 0xc011da4d,%eax
c0101aec:	83 c8 60             	or     $0x60,%eax
c0101aef:	a2 4d da 11 c0       	mov    %al,0xc011da4d
c0101af4:	0f b6 05 4d da 11 c0 	movzbl 0xc011da4d,%eax
c0101afb:	83 c8 80             	or     $0xffffff80,%eax
c0101afe:	a2 4d da 11 c0       	mov    %al,0xc011da4d
c0101b03:	a1 c4 a7 11 c0       	mov    0xc011a7c4,%eax
c0101b08:	c1 e8 10             	shr    $0x10,%eax
c0101b0b:	66 a3 4e da 11 c0    	mov    %ax,0xc011da4e
c0101b11:	c7 45 f8 60 a5 11 c0 	movl   $0xc011a560,-0x8(%ebp)
    }
}

static inline void
lidt(struct pseudodesc *pd) {
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
c0101b18:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0101b1b:	0f 01 18             	lidtl  (%eax)
    lidt(&idt_pd);
}
c0101b1e:	c9                   	leave  
c0101b1f:	c3                   	ret    

c0101b20 <trapname>:

static const char *
trapname(int trapno) {
c0101b20:	55                   	push   %ebp
c0101b21:	89 e5                	mov    %esp,%ebp
        "Alignment Check",
        "Machine-Check",
        "SIMD Floating-Point Exception"
    };

    if (trapno < sizeof(excnames)/sizeof(const char * const)) {
c0101b23:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b26:	83 f8 13             	cmp    $0x13,%eax
c0101b29:	77 0c                	ja     c0101b37 <trapname+0x17>
        return excnames[trapno];
c0101b2b:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b2e:	8b 04 85 e0 79 10 c0 	mov    -0x3fef8620(,%eax,4),%eax
c0101b35:	eb 18                	jmp    c0101b4f <trapname+0x2f>
    }
    if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16) {
c0101b37:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
c0101b3b:	7e 0d                	jle    c0101b4a <trapname+0x2a>
c0101b3d:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
c0101b41:	7f 07                	jg     c0101b4a <trapname+0x2a>
        return "Hardware Interrupt";
c0101b43:	b8 8a 76 10 c0       	mov    $0xc010768a,%eax
c0101b48:	eb 05                	jmp    c0101b4f <trapname+0x2f>
    }
    return "(unknown trap)";
c0101b4a:	b8 9d 76 10 c0       	mov    $0xc010769d,%eax
}
c0101b4f:	5d                   	pop    %ebp
c0101b50:	c3                   	ret    

c0101b51 <trap_in_kernel>:

/* trap_in_kernel - test if trap happened in kernel */
bool
trap_in_kernel(struct trapframe *tf) {
c0101b51:	55                   	push   %ebp
c0101b52:	89 e5                	mov    %esp,%ebp
    return (tf->tf_cs == (uint16_t)KERNEL_CS);
c0101b54:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b57:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101b5b:	66 83 f8 08          	cmp    $0x8,%ax
c0101b5f:	0f 94 c0             	sete   %al
c0101b62:	0f b6 c0             	movzbl %al,%eax
}
c0101b65:	5d                   	pop    %ebp
c0101b66:	c3                   	ret    

c0101b67 <print_trapframe>:
    "TF", "IF", "DF", "OF", NULL, NULL, "NT", NULL,
    "RF", "VM", "AC", "VIF", "VIP", "ID", NULL, NULL,
};

void
print_trapframe(struct trapframe *tf) {
c0101b67:	55                   	push   %ebp
c0101b68:	89 e5                	mov    %esp,%ebp
c0101b6a:	83 ec 28             	sub    $0x28,%esp
    cprintf("trapframe at %p\n", tf);
c0101b6d:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b70:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101b74:	c7 04 24 de 76 10 c0 	movl   $0xc01076de,(%esp)
c0101b7b:	e8 d4 e7 ff ff       	call   c0100354 <cprintf>
    print_regs(&tf->tf_regs);
c0101b80:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b83:	89 04 24             	mov    %eax,(%esp)
c0101b86:	e8 a1 01 00 00       	call   c0101d2c <print_regs>
    cprintf("  ds   0x----%04x\n", tf->tf_ds);
c0101b8b:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b8e:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
c0101b92:	0f b7 c0             	movzwl %ax,%eax
c0101b95:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101b99:	c7 04 24 ef 76 10 c0 	movl   $0xc01076ef,(%esp)
c0101ba0:	e8 af e7 ff ff       	call   c0100354 <cprintf>
    cprintf("  es   0x----%04x\n", tf->tf_es);
c0101ba5:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ba8:	0f b7 40 28          	movzwl 0x28(%eax),%eax
c0101bac:	0f b7 c0             	movzwl %ax,%eax
c0101baf:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101bb3:	c7 04 24 02 77 10 c0 	movl   $0xc0107702,(%esp)
c0101bba:	e8 95 e7 ff ff       	call   c0100354 <cprintf>
    cprintf("  fs   0x----%04x\n", tf->tf_fs);
c0101bbf:	8b 45 08             	mov    0x8(%ebp),%eax
c0101bc2:	0f b7 40 24          	movzwl 0x24(%eax),%eax
c0101bc6:	0f b7 c0             	movzwl %ax,%eax
c0101bc9:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101bcd:	c7 04 24 15 77 10 c0 	movl   $0xc0107715,(%esp)
c0101bd4:	e8 7b e7 ff ff       	call   c0100354 <cprintf>
    cprintf("  gs   0x----%04x\n", tf->tf_gs);
c0101bd9:	8b 45 08             	mov    0x8(%ebp),%eax
c0101bdc:	0f b7 40 20          	movzwl 0x20(%eax),%eax
c0101be0:	0f b7 c0             	movzwl %ax,%eax
c0101be3:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101be7:	c7 04 24 28 77 10 c0 	movl   $0xc0107728,(%esp)
c0101bee:	e8 61 e7 ff ff       	call   c0100354 <cprintf>
    cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
c0101bf3:	8b 45 08             	mov    0x8(%ebp),%eax
c0101bf6:	8b 40 30             	mov    0x30(%eax),%eax
c0101bf9:	89 04 24             	mov    %eax,(%esp)
c0101bfc:	e8 1f ff ff ff       	call   c0101b20 <trapname>
c0101c01:	8b 55 08             	mov    0x8(%ebp),%edx
c0101c04:	8b 52 30             	mov    0x30(%edx),%edx
c0101c07:	89 44 24 08          	mov    %eax,0x8(%esp)
c0101c0b:	89 54 24 04          	mov    %edx,0x4(%esp)
c0101c0f:	c7 04 24 3b 77 10 c0 	movl   $0xc010773b,(%esp)
c0101c16:	e8 39 e7 ff ff       	call   c0100354 <cprintf>
    cprintf("  err  0x%08x\n", tf->tf_err);
c0101c1b:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c1e:	8b 40 34             	mov    0x34(%eax),%eax
c0101c21:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101c25:	c7 04 24 4d 77 10 c0 	movl   $0xc010774d,(%esp)
c0101c2c:	e8 23 e7 ff ff       	call   c0100354 <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
c0101c31:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c34:	8b 40 38             	mov    0x38(%eax),%eax
c0101c37:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101c3b:	c7 04 24 5c 77 10 c0 	movl   $0xc010775c,(%esp)
c0101c42:	e8 0d e7 ff ff       	call   c0100354 <cprintf>
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
c0101c47:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c4a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101c4e:	0f b7 c0             	movzwl %ax,%eax
c0101c51:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101c55:	c7 04 24 6b 77 10 c0 	movl   $0xc010776b,(%esp)
c0101c5c:	e8 f3 e6 ff ff       	call   c0100354 <cprintf>
    cprintf("  flag 0x%08x ", tf->tf_eflags);
c0101c61:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c64:	8b 40 40             	mov    0x40(%eax),%eax
c0101c67:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101c6b:	c7 04 24 7e 77 10 c0 	movl   $0xc010777e,(%esp)
c0101c72:	e8 dd e6 ff ff       	call   c0100354 <cprintf>

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
c0101c77:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0101c7e:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
c0101c85:	eb 3e                	jmp    c0101cc5 <print_trapframe+0x15e>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
c0101c87:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c8a:	8b 50 40             	mov    0x40(%eax),%edx
c0101c8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0101c90:	21 d0                	and    %edx,%eax
c0101c92:	85 c0                	test   %eax,%eax
c0101c94:	74 28                	je     c0101cbe <print_trapframe+0x157>
c0101c96:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101c99:	8b 04 85 80 a5 11 c0 	mov    -0x3fee5a80(,%eax,4),%eax
c0101ca0:	85 c0                	test   %eax,%eax
c0101ca2:	74 1a                	je     c0101cbe <print_trapframe+0x157>
            cprintf("%s,", IA32flags[i]);
c0101ca4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101ca7:	8b 04 85 80 a5 11 c0 	mov    -0x3fee5a80(,%eax,4),%eax
c0101cae:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101cb2:	c7 04 24 8d 77 10 c0 	movl   $0xc010778d,(%esp)
c0101cb9:	e8 96 e6 ff ff       	call   c0100354 <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
    cprintf("  flag 0x%08x ", tf->tf_eflags);

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
c0101cbe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0101cc2:	d1 65 f0             	shll   -0x10(%ebp)
c0101cc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101cc8:	83 f8 17             	cmp    $0x17,%eax
c0101ccb:	76 ba                	jbe    c0101c87 <print_trapframe+0x120>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
            cprintf("%s,", IA32flags[i]);
        }
    }
    cprintf("IOPL=%d\n", (tf->tf_eflags & FL_IOPL_MASK) >> 12);
c0101ccd:	8b 45 08             	mov    0x8(%ebp),%eax
c0101cd0:	8b 40 40             	mov    0x40(%eax),%eax
c0101cd3:	25 00 30 00 00       	and    $0x3000,%eax
c0101cd8:	c1 e8 0c             	shr    $0xc,%eax
c0101cdb:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101cdf:	c7 04 24 91 77 10 c0 	movl   $0xc0107791,(%esp)
c0101ce6:	e8 69 e6 ff ff       	call   c0100354 <cprintf>

    if (!trap_in_kernel(tf)) {
c0101ceb:	8b 45 08             	mov    0x8(%ebp),%eax
c0101cee:	89 04 24             	mov    %eax,(%esp)
c0101cf1:	e8 5b fe ff ff       	call   c0101b51 <trap_in_kernel>
c0101cf6:	85 c0                	test   %eax,%eax
c0101cf8:	75 30                	jne    c0101d2a <print_trapframe+0x1c3>
        cprintf("  esp  0x%08x\n", tf->tf_esp);
c0101cfa:	8b 45 08             	mov    0x8(%ebp),%eax
c0101cfd:	8b 40 44             	mov    0x44(%eax),%eax
c0101d00:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101d04:	c7 04 24 9a 77 10 c0 	movl   $0xc010779a,(%esp)
c0101d0b:	e8 44 e6 ff ff       	call   c0100354 <cprintf>
        cprintf("  ss   0x----%04x\n", tf->tf_ss);
c0101d10:	8b 45 08             	mov    0x8(%ebp),%eax
c0101d13:	0f b7 40 48          	movzwl 0x48(%eax),%eax
c0101d17:	0f b7 c0             	movzwl %ax,%eax
c0101d1a:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101d1e:	c7 04 24 a9 77 10 c0 	movl   $0xc01077a9,(%esp)
c0101d25:	e8 2a e6 ff ff       	call   c0100354 <cprintf>
    }
}
c0101d2a:	c9                   	leave  
c0101d2b:	c3                   	ret    

c0101d2c <print_regs>:

void
print_regs(struct pushregs *regs) {
c0101d2c:	55                   	push   %ebp
c0101d2d:	89 e5                	mov    %esp,%ebp
c0101d2f:	83 ec 18             	sub    $0x18,%esp
    cprintf("  edi  0x%08x\n", regs->reg_edi);
c0101d32:	8b 45 08             	mov    0x8(%ebp),%eax
c0101d35:	8b 00                	mov    (%eax),%eax
c0101d37:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101d3b:	c7 04 24 bc 77 10 c0 	movl   $0xc01077bc,(%esp)
c0101d42:	e8 0d e6 ff ff       	call   c0100354 <cprintf>
    cprintf("  esi  0x%08x\n", regs->reg_esi);
c0101d47:	8b 45 08             	mov    0x8(%ebp),%eax
c0101d4a:	8b 40 04             	mov    0x4(%eax),%eax
c0101d4d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101d51:	c7 04 24 cb 77 10 c0 	movl   $0xc01077cb,(%esp)
c0101d58:	e8 f7 e5 ff ff       	call   c0100354 <cprintf>
    cprintf("  ebp  0x%08x\n", regs->reg_ebp);
c0101d5d:	8b 45 08             	mov    0x8(%ebp),%eax
c0101d60:	8b 40 08             	mov    0x8(%eax),%eax
c0101d63:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101d67:	c7 04 24 da 77 10 c0 	movl   $0xc01077da,(%esp)
c0101d6e:	e8 e1 e5 ff ff       	call   c0100354 <cprintf>
    cprintf("  oesp 0x%08x\n", regs->reg_oesp);
c0101d73:	8b 45 08             	mov    0x8(%ebp),%eax
c0101d76:	8b 40 0c             	mov    0xc(%eax),%eax
c0101d79:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101d7d:	c7 04 24 e9 77 10 c0 	movl   $0xc01077e9,(%esp)
c0101d84:	e8 cb e5 ff ff       	call   c0100354 <cprintf>
    cprintf("  ebx  0x%08x\n", regs->reg_ebx);
c0101d89:	8b 45 08             	mov    0x8(%ebp),%eax
c0101d8c:	8b 40 10             	mov    0x10(%eax),%eax
c0101d8f:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101d93:	c7 04 24 f8 77 10 c0 	movl   $0xc01077f8,(%esp)
c0101d9a:	e8 b5 e5 ff ff       	call   c0100354 <cprintf>
    cprintf("  edx  0x%08x\n", regs->reg_edx);
c0101d9f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101da2:	8b 40 14             	mov    0x14(%eax),%eax
c0101da5:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101da9:	c7 04 24 07 78 10 c0 	movl   $0xc0107807,(%esp)
c0101db0:	e8 9f e5 ff ff       	call   c0100354 <cprintf>
    cprintf("  ecx  0x%08x\n", regs->reg_ecx);
c0101db5:	8b 45 08             	mov    0x8(%ebp),%eax
c0101db8:	8b 40 18             	mov    0x18(%eax),%eax
c0101dbb:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101dbf:	c7 04 24 16 78 10 c0 	movl   $0xc0107816,(%esp)
c0101dc6:	e8 89 e5 ff ff       	call   c0100354 <cprintf>
    cprintf("  eax  0x%08x\n", regs->reg_eax);
c0101dcb:	8b 45 08             	mov    0x8(%ebp),%eax
c0101dce:	8b 40 1c             	mov    0x1c(%eax),%eax
c0101dd1:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101dd5:	c7 04 24 25 78 10 c0 	movl   $0xc0107825,(%esp)
c0101ddc:	e8 73 e5 ff ff       	call   c0100354 <cprintf>
}
c0101de1:	c9                   	leave  
c0101de2:	c3                   	ret    

c0101de3 <trap_dispatch>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static void
trap_dispatch(struct trapframe *tf) {
c0101de3:	55                   	push   %ebp
c0101de4:	89 e5                	mov    %esp,%ebp
c0101de6:	57                   	push   %edi
c0101de7:	56                   	push   %esi
c0101de8:	53                   	push   %ebx
c0101de9:	81 ec ac 00 00 00    	sub    $0xac,%esp
    char c;

    switch (tf->tf_trapno) {
c0101def:	8b 45 08             	mov    0x8(%ebp),%eax
c0101df2:	8b 40 30             	mov    0x30(%eax),%eax
c0101df5:	83 f8 2f             	cmp    $0x2f,%eax
c0101df8:	77 21                	ja     c0101e1b <trap_dispatch+0x38>
c0101dfa:	83 f8 2e             	cmp    $0x2e,%eax
c0101dfd:	0f 83 72 03 00 00    	jae    c0102175 <trap_dispatch+0x392>
c0101e03:	83 f8 21             	cmp    $0x21,%eax
c0101e06:	0f 84 8a 00 00 00    	je     c0101e96 <trap_dispatch+0xb3>
c0101e0c:	83 f8 24             	cmp    $0x24,%eax
c0101e0f:	74 5c                	je     c0101e6d <trap_dispatch+0x8a>
c0101e11:	83 f8 20             	cmp    $0x20,%eax
c0101e14:	74 1c                	je     c0101e32 <trap_dispatch+0x4f>
c0101e16:	e9 22 03 00 00       	jmp    c010213d <trap_dispatch+0x35a>
c0101e1b:	83 f8 78             	cmp    $0x78,%eax
c0101e1e:	0f 84 2c 02 00 00    	je     c0102050 <trap_dispatch+0x26d>
c0101e24:	83 f8 79             	cmp    $0x79,%eax
c0101e27:	0f 84 a4 02 00 00    	je     c01020d1 <trap_dispatch+0x2ee>
c0101e2d:	e9 0b 03 00 00       	jmp    c010213d <trap_dispatch+0x35a>
        /* handle the timer interrupt */
        /* (1) After a timer interrupt, you should record this event using a global variable (increase it), such as ticks in kern/driver/clock.c
         * (2) Every TICK_NUM cycle, you can print some info using a funciton, such as print_ticks().
         * (3) Too Simple? Yes, I think so!
         */
        ticks++;
c0101e32:	a1 2c 57 12 c0       	mov    0xc012572c,%eax
c0101e37:	83 c0 01             	add    $0x1,%eax
c0101e3a:	a3 2c 57 12 c0       	mov    %eax,0xc012572c
        if (ticks % TICK_NUM == 0) {
c0101e3f:	8b 0d 2c 57 12 c0    	mov    0xc012572c,%ecx
c0101e45:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
c0101e4a:	89 c8                	mov    %ecx,%eax
c0101e4c:	f7 e2                	mul    %edx
c0101e4e:	89 d0                	mov    %edx,%eax
c0101e50:	c1 e8 05             	shr    $0x5,%eax
c0101e53:	6b c0 64             	imul   $0x64,%eax,%eax
c0101e56:	29 c1                	sub    %eax,%ecx
c0101e58:	89 c8                	mov    %ecx,%eax
c0101e5a:	85 c0                	test   %eax,%eax
c0101e5c:	75 0a                	jne    c0101e68 <trap_dispatch+0x85>
            print_ticks();
c0101e5e:	e8 36 fa ff ff       	call   c0101899 <print_ticks>
        }
        break;
c0101e63:	e9 0e 03 00 00       	jmp    c0102176 <trap_dispatch+0x393>
c0101e68:	e9 09 03 00 00       	jmp    c0102176 <trap_dispatch+0x393>
    case IRQ_OFFSET + IRQ_COM1:
        c = cons_getc();
c0101e6d:	e8 eb f7 ff ff       	call   c010165d <cons_getc>
c0101e72:	88 45 e7             	mov    %al,-0x19(%ebp)
        cprintf("serial [%03d] %c\n", c, c);
c0101e75:	0f be 55 e7          	movsbl -0x19(%ebp),%edx
c0101e79:	0f be 45 e7          	movsbl -0x19(%ebp),%eax
c0101e7d:	89 54 24 08          	mov    %edx,0x8(%esp)
c0101e81:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101e85:	c7 04 24 34 78 10 c0 	movl   $0xc0107834,(%esp)
c0101e8c:	e8 c3 e4 ff ff       	call   c0100354 <cprintf>
        break;
c0101e91:	e9 e0 02 00 00       	jmp    c0102176 <trap_dispatch+0x393>
    case IRQ_OFFSET + IRQ_KBD:
        c = cons_getc();
c0101e96:	e8 c2 f7 ff ff       	call   c010165d <cons_getc>
c0101e9b:	88 45 e7             	mov    %al,-0x19(%ebp)
        cprintf("kbd [%03d] %c\n", c, c);
c0101e9e:	0f be 55 e7          	movsbl -0x19(%ebp),%edx
c0101ea2:	0f be 45 e7          	movsbl -0x19(%ebp),%eax
c0101ea6:	89 54 24 08          	mov    %edx,0x8(%esp)
c0101eaa:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101eae:	c7 04 24 46 78 10 c0 	movl   $0xc0107846,(%esp)
c0101eb5:	e8 9a e4 ff ff       	call   c0100354 <cprintf>
        if (c == 51 && tf->tf_cs == KERNEL_CS) { //切换到用户态
c0101eba:	80 7d e7 33          	cmpb   $0x33,-0x19(%ebp)
c0101ebe:	75 76                	jne    c0101f36 <trap_dispatch+0x153>
c0101ec0:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ec3:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101ec7:	66 83 f8 08          	cmp    $0x8,%ax
c0101ecb:	75 69                	jne    c0101f36 <trap_dispatch+0x153>
            struct trapframe fake_tf = *tf;
c0101ecd:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ed0:	8d 95 64 ff ff ff    	lea    -0x9c(%ebp),%edx
c0101ed6:	89 c3                	mov    %eax,%ebx
c0101ed8:	b8 13 00 00 00       	mov    $0x13,%eax
c0101edd:	89 d7                	mov    %edx,%edi
c0101edf:	89 de                	mov    %ebx,%esi
c0101ee1:	89 c1                	mov    %eax,%ecx
c0101ee3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
            //设置段寄存器
            fake_tf.tf_cs = USER_CS;
c0101ee5:	66 c7 45 a0 1b 00    	movw   $0x1b,-0x60(%ebp)
            fake_tf.tf_ss = fake_tf.tf_ds = fake_tf.tf_es = fake_tf.tf_fs = fake_tf.tf_gs = USER_DS;
c0101eeb:	66 c7 45 84 23 00    	movw   $0x23,-0x7c(%ebp)
c0101ef1:	0f b7 45 84          	movzwl -0x7c(%ebp),%eax
c0101ef5:	66 89 45 88          	mov    %ax,-0x78(%ebp)
c0101ef9:	0f b7 45 88          	movzwl -0x78(%ebp),%eax
c0101efd:	66 89 45 8c          	mov    %ax,-0x74(%ebp)
c0101f01:	0f b7 45 8c          	movzwl -0x74(%ebp),%eax
c0101f05:	66 89 45 90          	mov    %ax,-0x70(%ebp)
c0101f09:	0f b7 45 90          	movzwl -0x70(%ebp),%eax
c0101f0d:	66 89 45 ac          	mov    %ax,-0x54(%ebp)
            //设置esp，相当于骗CPU，让它以为是从U到K，然后他就会恢复esp的值
            fake_tf.tf_esp = (&tf->tf_esp);
c0101f11:	8b 45 08             	mov    0x8(%ebp),%eax
c0101f14:	83 c0 44             	add    $0x44,%eax
c0101f17:	89 45 a8             	mov    %eax,-0x58(%ebp)
            //把eflags的IO位打开，要不切换到用户态后没办法打印信息了。
            fake_tf.tf_eflags |= FL_IOPL_MASK;
c0101f1a:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0101f1d:	80 cc 30             	or     $0x30,%ah
c0101f20:	89 45 a4             	mov    %eax,-0x5c(%ebp)
            //存在栈里的esp指向了tf的首地址，这里把这个esp的值改了，pop之后
            //的esp就指向fake_tf了
            *((uint32_t*)tf - 1) = &fake_tf;
c0101f23:	8b 45 08             	mov    0x8(%ebp),%eax
c0101f26:	8d 50 fc             	lea    -0x4(%eax),%edx
c0101f29:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
c0101f2f:	89 02                	mov    %eax,(%edx)
        cprintf("serial [%03d] %c\n", c, c);
        break;
    case IRQ_OFFSET + IRQ_KBD:
        c = cons_getc();
        cprintf("kbd [%03d] %c\n", c, c);
        if (c == 51 && tf->tf_cs == KERNEL_CS) { //切换到用户态
c0101f31:	e9 15 01 00 00       	jmp    c010204b <trap_dispatch+0x268>
            fake_tf.tf_eflags |= FL_IOPL_MASK;
            //存在栈里的esp指向了tf的首地址，这里把这个esp的值改了，pop之后
            //的esp就指向fake_tf了
            *((uint32_t*)tf - 1) = &fake_tf;
        }
        else if (c == 48 && tf->tf_cs == USER_CS) { //切换到内核态
c0101f36:	80 7d e7 30          	cmpb   $0x30,-0x19(%ebp)
c0101f3a:	0f 85 0b 01 00 00    	jne    c010204b <trap_dispatch+0x268>
c0101f40:	8b 45 08             	mov    0x8(%ebp),%eax
c0101f43:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101f47:	66 83 f8 1b          	cmp    $0x1b,%ax
c0101f4b:	0f 85 fa 00 00 00    	jne    c010204b <trap_dispatch+0x268>
            struct trapframe fake_tf = *tf;
c0101f51:	8b 45 08             	mov    0x8(%ebp),%eax
c0101f54:	8d 95 64 ff ff ff    	lea    -0x9c(%ebp),%edx
c0101f5a:	89 c3                	mov    %eax,%ebx
c0101f5c:	b8 13 00 00 00       	mov    $0x13,%eax
c0101f61:	89 d7                	mov    %edx,%edi
c0101f63:	89 de                	mov    %ebx,%esi
c0101f65:	89 c1                	mov    %eax,%ecx
c0101f67:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
            //设置段寄存器
            fake_tf.tf_cs = KERNEL_CS;
c0101f69:	66 c7 45 a0 08 00    	movw   $0x8,-0x60(%ebp)
            fake_tf.tf_ss = fake_tf.tf_ds = fake_tf.tf_es = fake_tf.tf_fs = fake_tf.tf_gs = KERNEL_DS;
c0101f6f:	66 c7 45 84 10 00    	movw   $0x10,-0x7c(%ebp)
c0101f75:	0f b7 45 84          	movzwl -0x7c(%ebp),%eax
c0101f79:	66 89 45 88          	mov    %ax,-0x78(%ebp)
c0101f7d:	0f b7 45 88          	movzwl -0x78(%ebp),%eax
c0101f81:	66 89 45 8c          	mov    %ax,-0x74(%ebp)
c0101f85:	0f b7 45 8c          	movzwl -0x74(%ebp),%eax
c0101f89:	66 89 45 90          	mov    %ax,-0x70(%ebp)
c0101f8d:	0f b7 45 90          	movzwl -0x70(%ebp),%eax
c0101f91:	66 89 45 ac          	mov    %ax,-0x54(%ebp)
            fake_tf.tf_eflags &= ~FL_IOPL_MASK;
c0101f95:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0101f98:	80 e4 cf             	and    $0xcf,%ah
c0101f9b:	89 45 a4             	mov    %eax,-0x5c(%ebp)
            uintptr_t user_tf_add = (struct trapframe*)fake_tf.tf_esp - 1;
c0101f9e:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0101fa1:	83 e8 4c             	sub    $0x4c,%eax
c0101fa4:	89 45 e0             	mov    %eax,-0x20(%ebp)
            user_tf_add += 8;
c0101fa7:	83 45 e0 08          	addl   $0x8,-0x20(%ebp)
            __memmove(user_tf_add, &fake_tf, sizeof(struct trapframe) - 8);
c0101fab:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0101fae:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0101fb1:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
c0101fb7:	89 45 d8             	mov    %eax,-0x28(%ebp)
c0101fba:	c7 45 d4 44 00 00 00 	movl   $0x44,-0x2c(%ebp)

#ifndef __HAVE_ARCH_MEMMOVE
#define __HAVE_ARCH_MEMMOVE
static inline void *
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
c0101fc1:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0101fc4:	3b 45 d8             	cmp    -0x28(%ebp),%eax
c0101fc7:	73 3f                	jae    c0102008 <trap_dispatch+0x225>
c0101fc9:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0101fcc:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0101fcf:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0101fd2:	89 45 cc             	mov    %eax,-0x34(%ebp)
c0101fd5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0101fd8:	89 45 c8             	mov    %eax,-0x38(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c0101fdb:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0101fde:	c1 e8 02             	shr    $0x2,%eax
c0101fe1:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
c0101fe3:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0101fe6:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0101fe9:	89 d7                	mov    %edx,%edi
c0101feb:	89 c6                	mov    %eax,%esi
c0101fed:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c0101fef:	8b 4d c8             	mov    -0x38(%ebp),%ecx
c0101ff2:	83 e1 03             	and    $0x3,%ecx
c0101ff5:	74 02                	je     c0101ff9 <trap_dispatch+0x216>
c0101ff7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c0101ff9:	89 f0                	mov    %esi,%eax
c0101ffb:	89 fa                	mov    %edi,%edx
c0101ffd:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
c0102000:	89 55 c0             	mov    %edx,-0x40(%ebp)
c0102003:	89 45 bc             	mov    %eax,-0x44(%ebp)
c0102006:	eb 33                	jmp    c010203b <trap_dispatch+0x258>
    asm volatile (
        "std;"
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
c0102008:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010200b:	8d 50 ff             	lea    -0x1(%eax),%edx
c010200e:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0102011:	01 c2                	add    %eax,%edx
c0102013:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0102016:	8d 48 ff             	lea    -0x1(%eax),%ecx
c0102019:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010201c:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
        return __memcpy(dst, src, n);
    }
    int d0, d1, d2;
    asm volatile (
c010201f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0102022:	89 c1                	mov    %eax,%ecx
c0102024:	89 d8                	mov    %ebx,%eax
c0102026:	89 d6                	mov    %edx,%esi
c0102028:	89 c7                	mov    %eax,%edi
c010202a:	fd                   	std    
c010202b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c010202d:	fc                   	cld    
c010202e:	89 f8                	mov    %edi,%eax
c0102030:	89 f2                	mov    %esi,%edx
c0102032:	89 4d b8             	mov    %ecx,-0x48(%ebp)
c0102035:	89 55 b4             	mov    %edx,-0x4c(%ebp)
c0102038:	89 45 b0             	mov    %eax,-0x50(%ebp)
            //存在栈里的esp指向了tf的首地址，这里把这个esp的值改了，pop之后
            //的esp就指向fake_tf了
            *((uint32_t*)tf - 1) = user_tf_add;
c010203b:	8b 45 08             	mov    0x8(%ebp),%eax
c010203e:	8d 50 fc             	lea    -0x4(%eax),%edx
c0102041:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0102044:	89 02                	mov    %eax,(%edx)
        }
        break;
c0102046:	e9 2b 01 00 00       	jmp    c0102176 <trap_dispatch+0x393>
c010204b:	e9 26 01 00 00       	jmp    c0102176 <trap_dispatch+0x393>
    //LAB1 CHALLENGE 1 : YOUR CODE you should modify below codes.
    case T_SWITCH_TOU:
        if (tf->tf_cs != USER_CS) {
c0102050:	8b 45 08             	mov    0x8(%ebp),%eax
c0102053:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0102057:	66 83 f8 1b          	cmp    $0x1b,%ax
c010205b:	74 6f                	je     c01020cc <trap_dispatch+0x2e9>
            //设置段寄存
            tf->tf_cs = USER_CS;
c010205d:	8b 45 08             	mov    0x8(%ebp),%eax
c0102060:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
            tf->tf_ss = tf->tf_ds = tf->tf_es = tf->tf_fs = tf->tf_gs = USER_DS;
c0102066:	8b 45 08             	mov    0x8(%ebp),%eax
c0102069:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
c010206f:	8b 45 08             	mov    0x8(%ebp),%eax
c0102072:	0f b7 50 20          	movzwl 0x20(%eax),%edx
c0102076:	8b 45 08             	mov    0x8(%ebp),%eax
c0102079:	66 89 50 24          	mov    %dx,0x24(%eax)
c010207d:	8b 45 08             	mov    0x8(%ebp),%eax
c0102080:	0f b7 50 24          	movzwl 0x24(%eax),%edx
c0102084:	8b 45 08             	mov    0x8(%ebp),%eax
c0102087:	66 89 50 28          	mov    %dx,0x28(%eax)
c010208b:	8b 45 08             	mov    0x8(%ebp),%eax
c010208e:	0f b7 50 28          	movzwl 0x28(%eax),%edx
c0102092:	8b 45 08             	mov    0x8(%ebp),%eax
c0102095:	66 89 50 2c          	mov    %dx,0x2c(%eax)
c0102099:	8b 45 08             	mov    0x8(%ebp),%eax
c010209c:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
c01020a0:	8b 45 08             	mov    0x8(%ebp),%eax
c01020a3:	66 89 50 48          	mov    %dx,0x48(%eax)
            tf->tf_esp += 4;
c01020a7:	8b 45 08             	mov    0x8(%ebp),%eax
c01020aa:	8b 40 44             	mov    0x44(%eax),%eax
c01020ad:	8d 50 04             	lea    0x4(%eax),%edx
c01020b0:	8b 45 08             	mov    0x8(%ebp),%eax
c01020b3:	89 50 44             	mov    %edx,0x44(%eax)
            //把eflags的IO位打开，要不切换到用户态后没办法打印信息了。
            tf->tf_eflags |= FL_IOPL_MASK;
c01020b6:	8b 45 08             	mov    0x8(%ebp),%eax
c01020b9:	8b 40 40             	mov    0x40(%eax),%eax
c01020bc:	80 cc 30             	or     $0x30,%ah
c01020bf:	89 c2                	mov    %eax,%edx
c01020c1:	8b 45 08             	mov    0x8(%ebp),%eax
c01020c4:	89 50 40             	mov    %edx,0x40(%eax)
        }
        break;
c01020c7:	e9 aa 00 00 00       	jmp    c0102176 <trap_dispatch+0x393>
c01020cc:	e9 a5 00 00 00       	jmp    c0102176 <trap_dispatch+0x393>
    case T_SWITCH_TOK:
        if (tf->tf_cs != KERNEL_CS) {
c01020d1:	8b 45 08             	mov    0x8(%ebp),%eax
c01020d4:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c01020d8:	66 83 f8 08          	cmp    $0x8,%ax
c01020dc:	74 5d                	je     c010213b <trap_dispatch+0x358>
            //设置段寄存器
            tf->tf_cs = KERNEL_CS;
c01020de:	8b 45 08             	mov    0x8(%ebp),%eax
c01020e1:	66 c7 40 3c 08 00    	movw   $0x8,0x3c(%eax)
            tf->tf_ss = tf->tf_ds = tf->tf_es = tf->tf_fs = tf->tf_gs = KERNEL_DS;
c01020e7:	8b 45 08             	mov    0x8(%ebp),%eax
c01020ea:	66 c7 40 20 10 00    	movw   $0x10,0x20(%eax)
c01020f0:	8b 45 08             	mov    0x8(%ebp),%eax
c01020f3:	0f b7 50 20          	movzwl 0x20(%eax),%edx
c01020f7:	8b 45 08             	mov    0x8(%ebp),%eax
c01020fa:	66 89 50 24          	mov    %dx,0x24(%eax)
c01020fe:	8b 45 08             	mov    0x8(%ebp),%eax
c0102101:	0f b7 50 24          	movzwl 0x24(%eax),%edx
c0102105:	8b 45 08             	mov    0x8(%ebp),%eax
c0102108:	66 89 50 28          	mov    %dx,0x28(%eax)
c010210c:	8b 45 08             	mov    0x8(%ebp),%eax
c010210f:	0f b7 50 28          	movzwl 0x28(%eax),%edx
c0102113:	8b 45 08             	mov    0x8(%ebp),%eax
c0102116:	66 89 50 2c          	mov    %dx,0x2c(%eax)
c010211a:	8b 45 08             	mov    0x8(%ebp),%eax
c010211d:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
c0102121:	8b 45 08             	mov    0x8(%ebp),%eax
c0102124:	66 89 50 48          	mov    %dx,0x48(%eax)
            //把eflags的IO位关闭
            tf->tf_eflags &= ~FL_IOPL_MASK;
c0102128:	8b 45 08             	mov    0x8(%ebp),%eax
c010212b:	8b 40 40             	mov    0x40(%eax),%eax
c010212e:	80 e4 cf             	and    $0xcf,%ah
c0102131:	89 c2                	mov    %eax,%edx
c0102133:	8b 45 08             	mov    0x8(%ebp),%eax
c0102136:	89 50 40             	mov    %edx,0x40(%eax)
        }
        break;
c0102139:	eb 3b                	jmp    c0102176 <trap_dispatch+0x393>
c010213b:	eb 39                	jmp    c0102176 <trap_dispatch+0x393>
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
    default:
        // in kernel, it must be a mistake
        if ((tf->tf_cs & 3) == 0) {
c010213d:	8b 45 08             	mov    0x8(%ebp),%eax
c0102140:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0102144:	0f b7 c0             	movzwl %ax,%eax
c0102147:	83 e0 03             	and    $0x3,%eax
c010214a:	85 c0                	test   %eax,%eax
c010214c:	75 28                	jne    c0102176 <trap_dispatch+0x393>
            print_trapframe(tf);
c010214e:	8b 45 08             	mov    0x8(%ebp),%eax
c0102151:	89 04 24             	mov    %eax,(%esp)
c0102154:	e8 0e fa ff ff       	call   c0101b67 <print_trapframe>
            panic("unexpected trap in kernel.\n");
c0102159:	c7 44 24 08 55 78 10 	movl   $0xc0107855,0x8(%esp)
c0102160:	c0 
c0102161:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
c0102168:	00 
c0102169:	c7 04 24 71 78 10 c0 	movl   $0xc0107871,(%esp)
c0102170:	e8 69 eb ff ff       	call   c0100cde <__panic>
        }
        break;
    case IRQ_OFFSET + IRQ_IDE1:
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
c0102175:	90                   	nop
        if ((tf->tf_cs & 3) == 0) {
            print_trapframe(tf);
            panic("unexpected trap in kernel.\n");
        }
    }
}
c0102176:	81 c4 ac 00 00 00    	add    $0xac,%esp
c010217c:	5b                   	pop    %ebx
c010217d:	5e                   	pop    %esi
c010217e:	5f                   	pop    %edi
c010217f:	5d                   	pop    %ebp
c0102180:	c3                   	ret    

c0102181 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
c0102181:	55                   	push   %ebp
c0102182:	89 e5                	mov    %esp,%ebp
c0102184:	83 ec 18             	sub    $0x18,%esp
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
c0102187:	8b 45 08             	mov    0x8(%ebp),%eax
c010218a:	89 04 24             	mov    %eax,(%esp)
c010218d:	e8 51 fc ff ff       	call   c0101de3 <trap_dispatch>
}
c0102192:	c9                   	leave  
c0102193:	c3                   	ret    

c0102194 <__alltraps>:
.text
.globl __alltraps
__alltraps:
    # push registers to build a trap frame
    # therefore make the stack look like a struct trapframe
    pushl %ds
c0102194:	1e                   	push   %ds
    pushl %es
c0102195:	06                   	push   %es
    pushl %fs
c0102196:	0f a0                	push   %fs
    pushl %gs
c0102198:	0f a8                	push   %gs
    pushal
c010219a:	60                   	pusha  

    # load GD_KDATA into %ds and %es to set up data segments for kernel
    movl $GD_KDATA, %eax
c010219b:	b8 10 00 00 00       	mov    $0x10,%eax
    movw %ax, %ds
c01021a0:	8e d8                	mov    %eax,%ds
    movw %ax, %es
c01021a2:	8e c0                	mov    %eax,%es

    # push %esp to pass a pointer to the trapframe as an argument to trap()
    pushl %esp
c01021a4:	54                   	push   %esp

    # call trap(tf), where tf=%esp
    call trap
c01021a5:	e8 d7 ff ff ff       	call   c0102181 <trap>

    # pop the pushed stack pointer
    popl %esp
c01021aa:	5c                   	pop    %esp

c01021ab <__trapret>:

    # return falls through to trapret...
.globl __trapret
__trapret:
    # restore registers from stack
    popal
c01021ab:	61                   	popa   

    # restore %ds, %es, %fs and %gs
    popl %gs
c01021ac:	0f a9                	pop    %gs
    popl %fs
c01021ae:	0f a1                	pop    %fs
    popl %es
c01021b0:	07                   	pop    %es
    popl %ds
c01021b1:	1f                   	pop    %ds

    # get rid of the trap number and error code
    addl $0x8, %esp
c01021b2:	83 c4 08             	add    $0x8,%esp
    iret
c01021b5:	cf                   	iret   

c01021b6 <vector0>:
# handler
.text
.globl __alltraps
.globl vector0
vector0:
  pushl $0
c01021b6:	6a 00                	push   $0x0
  pushl $0
c01021b8:	6a 00                	push   $0x0
  jmp __alltraps
c01021ba:	e9 d5 ff ff ff       	jmp    c0102194 <__alltraps>

c01021bf <vector1>:
.globl vector1
vector1:
  pushl $0
c01021bf:	6a 00                	push   $0x0
  pushl $1
c01021c1:	6a 01                	push   $0x1
  jmp __alltraps
c01021c3:	e9 cc ff ff ff       	jmp    c0102194 <__alltraps>

c01021c8 <vector2>:
.globl vector2
vector2:
  pushl $0
c01021c8:	6a 00                	push   $0x0
  pushl $2
c01021ca:	6a 02                	push   $0x2
  jmp __alltraps
c01021cc:	e9 c3 ff ff ff       	jmp    c0102194 <__alltraps>

c01021d1 <vector3>:
.globl vector3
vector3:
  pushl $0
c01021d1:	6a 00                	push   $0x0
  pushl $3
c01021d3:	6a 03                	push   $0x3
  jmp __alltraps
c01021d5:	e9 ba ff ff ff       	jmp    c0102194 <__alltraps>

c01021da <vector4>:
.globl vector4
vector4:
  pushl $0
c01021da:	6a 00                	push   $0x0
  pushl $4
c01021dc:	6a 04                	push   $0x4
  jmp __alltraps
c01021de:	e9 b1 ff ff ff       	jmp    c0102194 <__alltraps>

c01021e3 <vector5>:
.globl vector5
vector5:
  pushl $0
c01021e3:	6a 00                	push   $0x0
  pushl $5
c01021e5:	6a 05                	push   $0x5
  jmp __alltraps
c01021e7:	e9 a8 ff ff ff       	jmp    c0102194 <__alltraps>

c01021ec <vector6>:
.globl vector6
vector6:
  pushl $0
c01021ec:	6a 00                	push   $0x0
  pushl $6
c01021ee:	6a 06                	push   $0x6
  jmp __alltraps
c01021f0:	e9 9f ff ff ff       	jmp    c0102194 <__alltraps>

c01021f5 <vector7>:
.globl vector7
vector7:
  pushl $0
c01021f5:	6a 00                	push   $0x0
  pushl $7
c01021f7:	6a 07                	push   $0x7
  jmp __alltraps
c01021f9:	e9 96 ff ff ff       	jmp    c0102194 <__alltraps>

c01021fe <vector8>:
.globl vector8
vector8:
  pushl $8
c01021fe:	6a 08                	push   $0x8
  jmp __alltraps
c0102200:	e9 8f ff ff ff       	jmp    c0102194 <__alltraps>

c0102205 <vector9>:
.globl vector9
vector9:
  pushl $0
c0102205:	6a 00                	push   $0x0
  pushl $9
c0102207:	6a 09                	push   $0x9
  jmp __alltraps
c0102209:	e9 86 ff ff ff       	jmp    c0102194 <__alltraps>

c010220e <vector10>:
.globl vector10
vector10:
  pushl $10
c010220e:	6a 0a                	push   $0xa
  jmp __alltraps
c0102210:	e9 7f ff ff ff       	jmp    c0102194 <__alltraps>

c0102215 <vector11>:
.globl vector11
vector11:
  pushl $11
c0102215:	6a 0b                	push   $0xb
  jmp __alltraps
c0102217:	e9 78 ff ff ff       	jmp    c0102194 <__alltraps>

c010221c <vector12>:
.globl vector12
vector12:
  pushl $12
c010221c:	6a 0c                	push   $0xc
  jmp __alltraps
c010221e:	e9 71 ff ff ff       	jmp    c0102194 <__alltraps>

c0102223 <vector13>:
.globl vector13
vector13:
  pushl $13
c0102223:	6a 0d                	push   $0xd
  jmp __alltraps
c0102225:	e9 6a ff ff ff       	jmp    c0102194 <__alltraps>

c010222a <vector14>:
.globl vector14
vector14:
  pushl $14
c010222a:	6a 0e                	push   $0xe
  jmp __alltraps
c010222c:	e9 63 ff ff ff       	jmp    c0102194 <__alltraps>

c0102231 <vector15>:
.globl vector15
vector15:
  pushl $0
c0102231:	6a 00                	push   $0x0
  pushl $15
c0102233:	6a 0f                	push   $0xf
  jmp __alltraps
c0102235:	e9 5a ff ff ff       	jmp    c0102194 <__alltraps>

c010223a <vector16>:
.globl vector16
vector16:
  pushl $0
c010223a:	6a 00                	push   $0x0
  pushl $16
c010223c:	6a 10                	push   $0x10
  jmp __alltraps
c010223e:	e9 51 ff ff ff       	jmp    c0102194 <__alltraps>

c0102243 <vector17>:
.globl vector17
vector17:
  pushl $17
c0102243:	6a 11                	push   $0x11
  jmp __alltraps
c0102245:	e9 4a ff ff ff       	jmp    c0102194 <__alltraps>

c010224a <vector18>:
.globl vector18
vector18:
  pushl $0
c010224a:	6a 00                	push   $0x0
  pushl $18
c010224c:	6a 12                	push   $0x12
  jmp __alltraps
c010224e:	e9 41 ff ff ff       	jmp    c0102194 <__alltraps>

c0102253 <vector19>:
.globl vector19
vector19:
  pushl $0
c0102253:	6a 00                	push   $0x0
  pushl $19
c0102255:	6a 13                	push   $0x13
  jmp __alltraps
c0102257:	e9 38 ff ff ff       	jmp    c0102194 <__alltraps>

c010225c <vector20>:
.globl vector20
vector20:
  pushl $0
c010225c:	6a 00                	push   $0x0
  pushl $20
c010225e:	6a 14                	push   $0x14
  jmp __alltraps
c0102260:	e9 2f ff ff ff       	jmp    c0102194 <__alltraps>

c0102265 <vector21>:
.globl vector21
vector21:
  pushl $0
c0102265:	6a 00                	push   $0x0
  pushl $21
c0102267:	6a 15                	push   $0x15
  jmp __alltraps
c0102269:	e9 26 ff ff ff       	jmp    c0102194 <__alltraps>

c010226e <vector22>:
.globl vector22
vector22:
  pushl $0
c010226e:	6a 00                	push   $0x0
  pushl $22
c0102270:	6a 16                	push   $0x16
  jmp __alltraps
c0102272:	e9 1d ff ff ff       	jmp    c0102194 <__alltraps>

c0102277 <vector23>:
.globl vector23
vector23:
  pushl $0
c0102277:	6a 00                	push   $0x0
  pushl $23
c0102279:	6a 17                	push   $0x17
  jmp __alltraps
c010227b:	e9 14 ff ff ff       	jmp    c0102194 <__alltraps>

c0102280 <vector24>:
.globl vector24
vector24:
  pushl $0
c0102280:	6a 00                	push   $0x0
  pushl $24
c0102282:	6a 18                	push   $0x18
  jmp __alltraps
c0102284:	e9 0b ff ff ff       	jmp    c0102194 <__alltraps>

c0102289 <vector25>:
.globl vector25
vector25:
  pushl $0
c0102289:	6a 00                	push   $0x0
  pushl $25
c010228b:	6a 19                	push   $0x19
  jmp __alltraps
c010228d:	e9 02 ff ff ff       	jmp    c0102194 <__alltraps>

c0102292 <vector26>:
.globl vector26
vector26:
  pushl $0
c0102292:	6a 00                	push   $0x0
  pushl $26
c0102294:	6a 1a                	push   $0x1a
  jmp __alltraps
c0102296:	e9 f9 fe ff ff       	jmp    c0102194 <__alltraps>

c010229b <vector27>:
.globl vector27
vector27:
  pushl $0
c010229b:	6a 00                	push   $0x0
  pushl $27
c010229d:	6a 1b                	push   $0x1b
  jmp __alltraps
c010229f:	e9 f0 fe ff ff       	jmp    c0102194 <__alltraps>

c01022a4 <vector28>:
.globl vector28
vector28:
  pushl $0
c01022a4:	6a 00                	push   $0x0
  pushl $28
c01022a6:	6a 1c                	push   $0x1c
  jmp __alltraps
c01022a8:	e9 e7 fe ff ff       	jmp    c0102194 <__alltraps>

c01022ad <vector29>:
.globl vector29
vector29:
  pushl $0
c01022ad:	6a 00                	push   $0x0
  pushl $29
c01022af:	6a 1d                	push   $0x1d
  jmp __alltraps
c01022b1:	e9 de fe ff ff       	jmp    c0102194 <__alltraps>

c01022b6 <vector30>:
.globl vector30
vector30:
  pushl $0
c01022b6:	6a 00                	push   $0x0
  pushl $30
c01022b8:	6a 1e                	push   $0x1e
  jmp __alltraps
c01022ba:	e9 d5 fe ff ff       	jmp    c0102194 <__alltraps>

c01022bf <vector31>:
.globl vector31
vector31:
  pushl $0
c01022bf:	6a 00                	push   $0x0
  pushl $31
c01022c1:	6a 1f                	push   $0x1f
  jmp __alltraps
c01022c3:	e9 cc fe ff ff       	jmp    c0102194 <__alltraps>

c01022c8 <vector32>:
.globl vector32
vector32:
  pushl $0
c01022c8:	6a 00                	push   $0x0
  pushl $32
c01022ca:	6a 20                	push   $0x20
  jmp __alltraps
c01022cc:	e9 c3 fe ff ff       	jmp    c0102194 <__alltraps>

c01022d1 <vector33>:
.globl vector33
vector33:
  pushl $0
c01022d1:	6a 00                	push   $0x0
  pushl $33
c01022d3:	6a 21                	push   $0x21
  jmp __alltraps
c01022d5:	e9 ba fe ff ff       	jmp    c0102194 <__alltraps>

c01022da <vector34>:
.globl vector34
vector34:
  pushl $0
c01022da:	6a 00                	push   $0x0
  pushl $34
c01022dc:	6a 22                	push   $0x22
  jmp __alltraps
c01022de:	e9 b1 fe ff ff       	jmp    c0102194 <__alltraps>

c01022e3 <vector35>:
.globl vector35
vector35:
  pushl $0
c01022e3:	6a 00                	push   $0x0
  pushl $35
c01022e5:	6a 23                	push   $0x23
  jmp __alltraps
c01022e7:	e9 a8 fe ff ff       	jmp    c0102194 <__alltraps>

c01022ec <vector36>:
.globl vector36
vector36:
  pushl $0
c01022ec:	6a 00                	push   $0x0
  pushl $36
c01022ee:	6a 24                	push   $0x24
  jmp __alltraps
c01022f0:	e9 9f fe ff ff       	jmp    c0102194 <__alltraps>

c01022f5 <vector37>:
.globl vector37
vector37:
  pushl $0
c01022f5:	6a 00                	push   $0x0
  pushl $37
c01022f7:	6a 25                	push   $0x25
  jmp __alltraps
c01022f9:	e9 96 fe ff ff       	jmp    c0102194 <__alltraps>

c01022fe <vector38>:
.globl vector38
vector38:
  pushl $0
c01022fe:	6a 00                	push   $0x0
  pushl $38
c0102300:	6a 26                	push   $0x26
  jmp __alltraps
c0102302:	e9 8d fe ff ff       	jmp    c0102194 <__alltraps>

c0102307 <vector39>:
.globl vector39
vector39:
  pushl $0
c0102307:	6a 00                	push   $0x0
  pushl $39
c0102309:	6a 27                	push   $0x27
  jmp __alltraps
c010230b:	e9 84 fe ff ff       	jmp    c0102194 <__alltraps>

c0102310 <vector40>:
.globl vector40
vector40:
  pushl $0
c0102310:	6a 00                	push   $0x0
  pushl $40
c0102312:	6a 28                	push   $0x28
  jmp __alltraps
c0102314:	e9 7b fe ff ff       	jmp    c0102194 <__alltraps>

c0102319 <vector41>:
.globl vector41
vector41:
  pushl $0
c0102319:	6a 00                	push   $0x0
  pushl $41
c010231b:	6a 29                	push   $0x29
  jmp __alltraps
c010231d:	e9 72 fe ff ff       	jmp    c0102194 <__alltraps>

c0102322 <vector42>:
.globl vector42
vector42:
  pushl $0
c0102322:	6a 00                	push   $0x0
  pushl $42
c0102324:	6a 2a                	push   $0x2a
  jmp __alltraps
c0102326:	e9 69 fe ff ff       	jmp    c0102194 <__alltraps>

c010232b <vector43>:
.globl vector43
vector43:
  pushl $0
c010232b:	6a 00                	push   $0x0
  pushl $43
c010232d:	6a 2b                	push   $0x2b
  jmp __alltraps
c010232f:	e9 60 fe ff ff       	jmp    c0102194 <__alltraps>

c0102334 <vector44>:
.globl vector44
vector44:
  pushl $0
c0102334:	6a 00                	push   $0x0
  pushl $44
c0102336:	6a 2c                	push   $0x2c
  jmp __alltraps
c0102338:	e9 57 fe ff ff       	jmp    c0102194 <__alltraps>

c010233d <vector45>:
.globl vector45
vector45:
  pushl $0
c010233d:	6a 00                	push   $0x0
  pushl $45
c010233f:	6a 2d                	push   $0x2d
  jmp __alltraps
c0102341:	e9 4e fe ff ff       	jmp    c0102194 <__alltraps>

c0102346 <vector46>:
.globl vector46
vector46:
  pushl $0
c0102346:	6a 00                	push   $0x0
  pushl $46
c0102348:	6a 2e                	push   $0x2e
  jmp __alltraps
c010234a:	e9 45 fe ff ff       	jmp    c0102194 <__alltraps>

c010234f <vector47>:
.globl vector47
vector47:
  pushl $0
c010234f:	6a 00                	push   $0x0
  pushl $47
c0102351:	6a 2f                	push   $0x2f
  jmp __alltraps
c0102353:	e9 3c fe ff ff       	jmp    c0102194 <__alltraps>

c0102358 <vector48>:
.globl vector48
vector48:
  pushl $0
c0102358:	6a 00                	push   $0x0
  pushl $48
c010235a:	6a 30                	push   $0x30
  jmp __alltraps
c010235c:	e9 33 fe ff ff       	jmp    c0102194 <__alltraps>

c0102361 <vector49>:
.globl vector49
vector49:
  pushl $0
c0102361:	6a 00                	push   $0x0
  pushl $49
c0102363:	6a 31                	push   $0x31
  jmp __alltraps
c0102365:	e9 2a fe ff ff       	jmp    c0102194 <__alltraps>

c010236a <vector50>:
.globl vector50
vector50:
  pushl $0
c010236a:	6a 00                	push   $0x0
  pushl $50
c010236c:	6a 32                	push   $0x32
  jmp __alltraps
c010236e:	e9 21 fe ff ff       	jmp    c0102194 <__alltraps>

c0102373 <vector51>:
.globl vector51
vector51:
  pushl $0
c0102373:	6a 00                	push   $0x0
  pushl $51
c0102375:	6a 33                	push   $0x33
  jmp __alltraps
c0102377:	e9 18 fe ff ff       	jmp    c0102194 <__alltraps>

c010237c <vector52>:
.globl vector52
vector52:
  pushl $0
c010237c:	6a 00                	push   $0x0
  pushl $52
c010237e:	6a 34                	push   $0x34
  jmp __alltraps
c0102380:	e9 0f fe ff ff       	jmp    c0102194 <__alltraps>

c0102385 <vector53>:
.globl vector53
vector53:
  pushl $0
c0102385:	6a 00                	push   $0x0
  pushl $53
c0102387:	6a 35                	push   $0x35
  jmp __alltraps
c0102389:	e9 06 fe ff ff       	jmp    c0102194 <__alltraps>

c010238e <vector54>:
.globl vector54
vector54:
  pushl $0
c010238e:	6a 00                	push   $0x0
  pushl $54
c0102390:	6a 36                	push   $0x36
  jmp __alltraps
c0102392:	e9 fd fd ff ff       	jmp    c0102194 <__alltraps>

c0102397 <vector55>:
.globl vector55
vector55:
  pushl $0
c0102397:	6a 00                	push   $0x0
  pushl $55
c0102399:	6a 37                	push   $0x37
  jmp __alltraps
c010239b:	e9 f4 fd ff ff       	jmp    c0102194 <__alltraps>

c01023a0 <vector56>:
.globl vector56
vector56:
  pushl $0
c01023a0:	6a 00                	push   $0x0
  pushl $56
c01023a2:	6a 38                	push   $0x38
  jmp __alltraps
c01023a4:	e9 eb fd ff ff       	jmp    c0102194 <__alltraps>

c01023a9 <vector57>:
.globl vector57
vector57:
  pushl $0
c01023a9:	6a 00                	push   $0x0
  pushl $57
c01023ab:	6a 39                	push   $0x39
  jmp __alltraps
c01023ad:	e9 e2 fd ff ff       	jmp    c0102194 <__alltraps>

c01023b2 <vector58>:
.globl vector58
vector58:
  pushl $0
c01023b2:	6a 00                	push   $0x0
  pushl $58
c01023b4:	6a 3a                	push   $0x3a
  jmp __alltraps
c01023b6:	e9 d9 fd ff ff       	jmp    c0102194 <__alltraps>

c01023bb <vector59>:
.globl vector59
vector59:
  pushl $0
c01023bb:	6a 00                	push   $0x0
  pushl $59
c01023bd:	6a 3b                	push   $0x3b
  jmp __alltraps
c01023bf:	e9 d0 fd ff ff       	jmp    c0102194 <__alltraps>

c01023c4 <vector60>:
.globl vector60
vector60:
  pushl $0
c01023c4:	6a 00                	push   $0x0
  pushl $60
c01023c6:	6a 3c                	push   $0x3c
  jmp __alltraps
c01023c8:	e9 c7 fd ff ff       	jmp    c0102194 <__alltraps>

c01023cd <vector61>:
.globl vector61
vector61:
  pushl $0
c01023cd:	6a 00                	push   $0x0
  pushl $61
c01023cf:	6a 3d                	push   $0x3d
  jmp __alltraps
c01023d1:	e9 be fd ff ff       	jmp    c0102194 <__alltraps>

c01023d6 <vector62>:
.globl vector62
vector62:
  pushl $0
c01023d6:	6a 00                	push   $0x0
  pushl $62
c01023d8:	6a 3e                	push   $0x3e
  jmp __alltraps
c01023da:	e9 b5 fd ff ff       	jmp    c0102194 <__alltraps>

c01023df <vector63>:
.globl vector63
vector63:
  pushl $0
c01023df:	6a 00                	push   $0x0
  pushl $63
c01023e1:	6a 3f                	push   $0x3f
  jmp __alltraps
c01023e3:	e9 ac fd ff ff       	jmp    c0102194 <__alltraps>

c01023e8 <vector64>:
.globl vector64
vector64:
  pushl $0
c01023e8:	6a 00                	push   $0x0
  pushl $64
c01023ea:	6a 40                	push   $0x40
  jmp __alltraps
c01023ec:	e9 a3 fd ff ff       	jmp    c0102194 <__alltraps>

c01023f1 <vector65>:
.globl vector65
vector65:
  pushl $0
c01023f1:	6a 00                	push   $0x0
  pushl $65
c01023f3:	6a 41                	push   $0x41
  jmp __alltraps
c01023f5:	e9 9a fd ff ff       	jmp    c0102194 <__alltraps>

c01023fa <vector66>:
.globl vector66
vector66:
  pushl $0
c01023fa:	6a 00                	push   $0x0
  pushl $66
c01023fc:	6a 42                	push   $0x42
  jmp __alltraps
c01023fe:	e9 91 fd ff ff       	jmp    c0102194 <__alltraps>

c0102403 <vector67>:
.globl vector67
vector67:
  pushl $0
c0102403:	6a 00                	push   $0x0
  pushl $67
c0102405:	6a 43                	push   $0x43
  jmp __alltraps
c0102407:	e9 88 fd ff ff       	jmp    c0102194 <__alltraps>

c010240c <vector68>:
.globl vector68
vector68:
  pushl $0
c010240c:	6a 00                	push   $0x0
  pushl $68
c010240e:	6a 44                	push   $0x44
  jmp __alltraps
c0102410:	e9 7f fd ff ff       	jmp    c0102194 <__alltraps>

c0102415 <vector69>:
.globl vector69
vector69:
  pushl $0
c0102415:	6a 00                	push   $0x0
  pushl $69
c0102417:	6a 45                	push   $0x45
  jmp __alltraps
c0102419:	e9 76 fd ff ff       	jmp    c0102194 <__alltraps>

c010241e <vector70>:
.globl vector70
vector70:
  pushl $0
c010241e:	6a 00                	push   $0x0
  pushl $70
c0102420:	6a 46                	push   $0x46
  jmp __alltraps
c0102422:	e9 6d fd ff ff       	jmp    c0102194 <__alltraps>

c0102427 <vector71>:
.globl vector71
vector71:
  pushl $0
c0102427:	6a 00                	push   $0x0
  pushl $71
c0102429:	6a 47                	push   $0x47
  jmp __alltraps
c010242b:	e9 64 fd ff ff       	jmp    c0102194 <__alltraps>

c0102430 <vector72>:
.globl vector72
vector72:
  pushl $0
c0102430:	6a 00                	push   $0x0
  pushl $72
c0102432:	6a 48                	push   $0x48
  jmp __alltraps
c0102434:	e9 5b fd ff ff       	jmp    c0102194 <__alltraps>

c0102439 <vector73>:
.globl vector73
vector73:
  pushl $0
c0102439:	6a 00                	push   $0x0
  pushl $73
c010243b:	6a 49                	push   $0x49
  jmp __alltraps
c010243d:	e9 52 fd ff ff       	jmp    c0102194 <__alltraps>

c0102442 <vector74>:
.globl vector74
vector74:
  pushl $0
c0102442:	6a 00                	push   $0x0
  pushl $74
c0102444:	6a 4a                	push   $0x4a
  jmp __alltraps
c0102446:	e9 49 fd ff ff       	jmp    c0102194 <__alltraps>

c010244b <vector75>:
.globl vector75
vector75:
  pushl $0
c010244b:	6a 00                	push   $0x0
  pushl $75
c010244d:	6a 4b                	push   $0x4b
  jmp __alltraps
c010244f:	e9 40 fd ff ff       	jmp    c0102194 <__alltraps>

c0102454 <vector76>:
.globl vector76
vector76:
  pushl $0
c0102454:	6a 00                	push   $0x0
  pushl $76
c0102456:	6a 4c                	push   $0x4c
  jmp __alltraps
c0102458:	e9 37 fd ff ff       	jmp    c0102194 <__alltraps>

c010245d <vector77>:
.globl vector77
vector77:
  pushl $0
c010245d:	6a 00                	push   $0x0
  pushl $77
c010245f:	6a 4d                	push   $0x4d
  jmp __alltraps
c0102461:	e9 2e fd ff ff       	jmp    c0102194 <__alltraps>

c0102466 <vector78>:
.globl vector78
vector78:
  pushl $0
c0102466:	6a 00                	push   $0x0
  pushl $78
c0102468:	6a 4e                	push   $0x4e
  jmp __alltraps
c010246a:	e9 25 fd ff ff       	jmp    c0102194 <__alltraps>

c010246f <vector79>:
.globl vector79
vector79:
  pushl $0
c010246f:	6a 00                	push   $0x0
  pushl $79
c0102471:	6a 4f                	push   $0x4f
  jmp __alltraps
c0102473:	e9 1c fd ff ff       	jmp    c0102194 <__alltraps>

c0102478 <vector80>:
.globl vector80
vector80:
  pushl $0
c0102478:	6a 00                	push   $0x0
  pushl $80
c010247a:	6a 50                	push   $0x50
  jmp __alltraps
c010247c:	e9 13 fd ff ff       	jmp    c0102194 <__alltraps>

c0102481 <vector81>:
.globl vector81
vector81:
  pushl $0
c0102481:	6a 00                	push   $0x0
  pushl $81
c0102483:	6a 51                	push   $0x51
  jmp __alltraps
c0102485:	e9 0a fd ff ff       	jmp    c0102194 <__alltraps>

c010248a <vector82>:
.globl vector82
vector82:
  pushl $0
c010248a:	6a 00                	push   $0x0
  pushl $82
c010248c:	6a 52                	push   $0x52
  jmp __alltraps
c010248e:	e9 01 fd ff ff       	jmp    c0102194 <__alltraps>

c0102493 <vector83>:
.globl vector83
vector83:
  pushl $0
c0102493:	6a 00                	push   $0x0
  pushl $83
c0102495:	6a 53                	push   $0x53
  jmp __alltraps
c0102497:	e9 f8 fc ff ff       	jmp    c0102194 <__alltraps>

c010249c <vector84>:
.globl vector84
vector84:
  pushl $0
c010249c:	6a 00                	push   $0x0
  pushl $84
c010249e:	6a 54                	push   $0x54
  jmp __alltraps
c01024a0:	e9 ef fc ff ff       	jmp    c0102194 <__alltraps>

c01024a5 <vector85>:
.globl vector85
vector85:
  pushl $0
c01024a5:	6a 00                	push   $0x0
  pushl $85
c01024a7:	6a 55                	push   $0x55
  jmp __alltraps
c01024a9:	e9 e6 fc ff ff       	jmp    c0102194 <__alltraps>

c01024ae <vector86>:
.globl vector86
vector86:
  pushl $0
c01024ae:	6a 00                	push   $0x0
  pushl $86
c01024b0:	6a 56                	push   $0x56
  jmp __alltraps
c01024b2:	e9 dd fc ff ff       	jmp    c0102194 <__alltraps>

c01024b7 <vector87>:
.globl vector87
vector87:
  pushl $0
c01024b7:	6a 00                	push   $0x0
  pushl $87
c01024b9:	6a 57                	push   $0x57
  jmp __alltraps
c01024bb:	e9 d4 fc ff ff       	jmp    c0102194 <__alltraps>

c01024c0 <vector88>:
.globl vector88
vector88:
  pushl $0
c01024c0:	6a 00                	push   $0x0
  pushl $88
c01024c2:	6a 58                	push   $0x58
  jmp __alltraps
c01024c4:	e9 cb fc ff ff       	jmp    c0102194 <__alltraps>

c01024c9 <vector89>:
.globl vector89
vector89:
  pushl $0
c01024c9:	6a 00                	push   $0x0
  pushl $89
c01024cb:	6a 59                	push   $0x59
  jmp __alltraps
c01024cd:	e9 c2 fc ff ff       	jmp    c0102194 <__alltraps>

c01024d2 <vector90>:
.globl vector90
vector90:
  pushl $0
c01024d2:	6a 00                	push   $0x0
  pushl $90
c01024d4:	6a 5a                	push   $0x5a
  jmp __alltraps
c01024d6:	e9 b9 fc ff ff       	jmp    c0102194 <__alltraps>

c01024db <vector91>:
.globl vector91
vector91:
  pushl $0
c01024db:	6a 00                	push   $0x0
  pushl $91
c01024dd:	6a 5b                	push   $0x5b
  jmp __alltraps
c01024df:	e9 b0 fc ff ff       	jmp    c0102194 <__alltraps>

c01024e4 <vector92>:
.globl vector92
vector92:
  pushl $0
c01024e4:	6a 00                	push   $0x0
  pushl $92
c01024e6:	6a 5c                	push   $0x5c
  jmp __alltraps
c01024e8:	e9 a7 fc ff ff       	jmp    c0102194 <__alltraps>

c01024ed <vector93>:
.globl vector93
vector93:
  pushl $0
c01024ed:	6a 00                	push   $0x0
  pushl $93
c01024ef:	6a 5d                	push   $0x5d
  jmp __alltraps
c01024f1:	e9 9e fc ff ff       	jmp    c0102194 <__alltraps>

c01024f6 <vector94>:
.globl vector94
vector94:
  pushl $0
c01024f6:	6a 00                	push   $0x0
  pushl $94
c01024f8:	6a 5e                	push   $0x5e
  jmp __alltraps
c01024fa:	e9 95 fc ff ff       	jmp    c0102194 <__alltraps>

c01024ff <vector95>:
.globl vector95
vector95:
  pushl $0
c01024ff:	6a 00                	push   $0x0
  pushl $95
c0102501:	6a 5f                	push   $0x5f
  jmp __alltraps
c0102503:	e9 8c fc ff ff       	jmp    c0102194 <__alltraps>

c0102508 <vector96>:
.globl vector96
vector96:
  pushl $0
c0102508:	6a 00                	push   $0x0
  pushl $96
c010250a:	6a 60                	push   $0x60
  jmp __alltraps
c010250c:	e9 83 fc ff ff       	jmp    c0102194 <__alltraps>

c0102511 <vector97>:
.globl vector97
vector97:
  pushl $0
c0102511:	6a 00                	push   $0x0
  pushl $97
c0102513:	6a 61                	push   $0x61
  jmp __alltraps
c0102515:	e9 7a fc ff ff       	jmp    c0102194 <__alltraps>

c010251a <vector98>:
.globl vector98
vector98:
  pushl $0
c010251a:	6a 00                	push   $0x0
  pushl $98
c010251c:	6a 62                	push   $0x62
  jmp __alltraps
c010251e:	e9 71 fc ff ff       	jmp    c0102194 <__alltraps>

c0102523 <vector99>:
.globl vector99
vector99:
  pushl $0
c0102523:	6a 00                	push   $0x0
  pushl $99
c0102525:	6a 63                	push   $0x63
  jmp __alltraps
c0102527:	e9 68 fc ff ff       	jmp    c0102194 <__alltraps>

c010252c <vector100>:
.globl vector100
vector100:
  pushl $0
c010252c:	6a 00                	push   $0x0
  pushl $100
c010252e:	6a 64                	push   $0x64
  jmp __alltraps
c0102530:	e9 5f fc ff ff       	jmp    c0102194 <__alltraps>

c0102535 <vector101>:
.globl vector101
vector101:
  pushl $0
c0102535:	6a 00                	push   $0x0
  pushl $101
c0102537:	6a 65                	push   $0x65
  jmp __alltraps
c0102539:	e9 56 fc ff ff       	jmp    c0102194 <__alltraps>

c010253e <vector102>:
.globl vector102
vector102:
  pushl $0
c010253e:	6a 00                	push   $0x0
  pushl $102
c0102540:	6a 66                	push   $0x66
  jmp __alltraps
c0102542:	e9 4d fc ff ff       	jmp    c0102194 <__alltraps>

c0102547 <vector103>:
.globl vector103
vector103:
  pushl $0
c0102547:	6a 00                	push   $0x0
  pushl $103
c0102549:	6a 67                	push   $0x67
  jmp __alltraps
c010254b:	e9 44 fc ff ff       	jmp    c0102194 <__alltraps>

c0102550 <vector104>:
.globl vector104
vector104:
  pushl $0
c0102550:	6a 00                	push   $0x0
  pushl $104
c0102552:	6a 68                	push   $0x68
  jmp __alltraps
c0102554:	e9 3b fc ff ff       	jmp    c0102194 <__alltraps>

c0102559 <vector105>:
.globl vector105
vector105:
  pushl $0
c0102559:	6a 00                	push   $0x0
  pushl $105
c010255b:	6a 69                	push   $0x69
  jmp __alltraps
c010255d:	e9 32 fc ff ff       	jmp    c0102194 <__alltraps>

c0102562 <vector106>:
.globl vector106
vector106:
  pushl $0
c0102562:	6a 00                	push   $0x0
  pushl $106
c0102564:	6a 6a                	push   $0x6a
  jmp __alltraps
c0102566:	e9 29 fc ff ff       	jmp    c0102194 <__alltraps>

c010256b <vector107>:
.globl vector107
vector107:
  pushl $0
c010256b:	6a 00                	push   $0x0
  pushl $107
c010256d:	6a 6b                	push   $0x6b
  jmp __alltraps
c010256f:	e9 20 fc ff ff       	jmp    c0102194 <__alltraps>

c0102574 <vector108>:
.globl vector108
vector108:
  pushl $0
c0102574:	6a 00                	push   $0x0
  pushl $108
c0102576:	6a 6c                	push   $0x6c
  jmp __alltraps
c0102578:	e9 17 fc ff ff       	jmp    c0102194 <__alltraps>

c010257d <vector109>:
.globl vector109
vector109:
  pushl $0
c010257d:	6a 00                	push   $0x0
  pushl $109
c010257f:	6a 6d                	push   $0x6d
  jmp __alltraps
c0102581:	e9 0e fc ff ff       	jmp    c0102194 <__alltraps>

c0102586 <vector110>:
.globl vector110
vector110:
  pushl $0
c0102586:	6a 00                	push   $0x0
  pushl $110
c0102588:	6a 6e                	push   $0x6e
  jmp __alltraps
c010258a:	e9 05 fc ff ff       	jmp    c0102194 <__alltraps>

c010258f <vector111>:
.globl vector111
vector111:
  pushl $0
c010258f:	6a 00                	push   $0x0
  pushl $111
c0102591:	6a 6f                	push   $0x6f
  jmp __alltraps
c0102593:	e9 fc fb ff ff       	jmp    c0102194 <__alltraps>

c0102598 <vector112>:
.globl vector112
vector112:
  pushl $0
c0102598:	6a 00                	push   $0x0
  pushl $112
c010259a:	6a 70                	push   $0x70
  jmp __alltraps
c010259c:	e9 f3 fb ff ff       	jmp    c0102194 <__alltraps>

c01025a1 <vector113>:
.globl vector113
vector113:
  pushl $0
c01025a1:	6a 00                	push   $0x0
  pushl $113
c01025a3:	6a 71                	push   $0x71
  jmp __alltraps
c01025a5:	e9 ea fb ff ff       	jmp    c0102194 <__alltraps>

c01025aa <vector114>:
.globl vector114
vector114:
  pushl $0
c01025aa:	6a 00                	push   $0x0
  pushl $114
c01025ac:	6a 72                	push   $0x72
  jmp __alltraps
c01025ae:	e9 e1 fb ff ff       	jmp    c0102194 <__alltraps>

c01025b3 <vector115>:
.globl vector115
vector115:
  pushl $0
c01025b3:	6a 00                	push   $0x0
  pushl $115
c01025b5:	6a 73                	push   $0x73
  jmp __alltraps
c01025b7:	e9 d8 fb ff ff       	jmp    c0102194 <__alltraps>

c01025bc <vector116>:
.globl vector116
vector116:
  pushl $0
c01025bc:	6a 00                	push   $0x0
  pushl $116
c01025be:	6a 74                	push   $0x74
  jmp __alltraps
c01025c0:	e9 cf fb ff ff       	jmp    c0102194 <__alltraps>

c01025c5 <vector117>:
.globl vector117
vector117:
  pushl $0
c01025c5:	6a 00                	push   $0x0
  pushl $117
c01025c7:	6a 75                	push   $0x75
  jmp __alltraps
c01025c9:	e9 c6 fb ff ff       	jmp    c0102194 <__alltraps>

c01025ce <vector118>:
.globl vector118
vector118:
  pushl $0
c01025ce:	6a 00                	push   $0x0
  pushl $118
c01025d0:	6a 76                	push   $0x76
  jmp __alltraps
c01025d2:	e9 bd fb ff ff       	jmp    c0102194 <__alltraps>

c01025d7 <vector119>:
.globl vector119
vector119:
  pushl $0
c01025d7:	6a 00                	push   $0x0
  pushl $119
c01025d9:	6a 77                	push   $0x77
  jmp __alltraps
c01025db:	e9 b4 fb ff ff       	jmp    c0102194 <__alltraps>

c01025e0 <vector120>:
.globl vector120
vector120:
  pushl $0
c01025e0:	6a 00                	push   $0x0
  pushl $120
c01025e2:	6a 78                	push   $0x78
  jmp __alltraps
c01025e4:	e9 ab fb ff ff       	jmp    c0102194 <__alltraps>

c01025e9 <vector121>:
.globl vector121
vector121:
  pushl $0
c01025e9:	6a 00                	push   $0x0
  pushl $121
c01025eb:	6a 79                	push   $0x79
  jmp __alltraps
c01025ed:	e9 a2 fb ff ff       	jmp    c0102194 <__alltraps>

c01025f2 <vector122>:
.globl vector122
vector122:
  pushl $0
c01025f2:	6a 00                	push   $0x0
  pushl $122
c01025f4:	6a 7a                	push   $0x7a
  jmp __alltraps
c01025f6:	e9 99 fb ff ff       	jmp    c0102194 <__alltraps>

c01025fb <vector123>:
.globl vector123
vector123:
  pushl $0
c01025fb:	6a 00                	push   $0x0
  pushl $123
c01025fd:	6a 7b                	push   $0x7b
  jmp __alltraps
c01025ff:	e9 90 fb ff ff       	jmp    c0102194 <__alltraps>

c0102604 <vector124>:
.globl vector124
vector124:
  pushl $0
c0102604:	6a 00                	push   $0x0
  pushl $124
c0102606:	6a 7c                	push   $0x7c
  jmp __alltraps
c0102608:	e9 87 fb ff ff       	jmp    c0102194 <__alltraps>

c010260d <vector125>:
.globl vector125
vector125:
  pushl $0
c010260d:	6a 00                	push   $0x0
  pushl $125
c010260f:	6a 7d                	push   $0x7d
  jmp __alltraps
c0102611:	e9 7e fb ff ff       	jmp    c0102194 <__alltraps>

c0102616 <vector126>:
.globl vector126
vector126:
  pushl $0
c0102616:	6a 00                	push   $0x0
  pushl $126
c0102618:	6a 7e                	push   $0x7e
  jmp __alltraps
c010261a:	e9 75 fb ff ff       	jmp    c0102194 <__alltraps>

c010261f <vector127>:
.globl vector127
vector127:
  pushl $0
c010261f:	6a 00                	push   $0x0
  pushl $127
c0102621:	6a 7f                	push   $0x7f
  jmp __alltraps
c0102623:	e9 6c fb ff ff       	jmp    c0102194 <__alltraps>

c0102628 <vector128>:
.globl vector128
vector128:
  pushl $0
c0102628:	6a 00                	push   $0x0
  pushl $128
c010262a:	68 80 00 00 00       	push   $0x80
  jmp __alltraps
c010262f:	e9 60 fb ff ff       	jmp    c0102194 <__alltraps>

c0102634 <vector129>:
.globl vector129
vector129:
  pushl $0
c0102634:	6a 00                	push   $0x0
  pushl $129
c0102636:	68 81 00 00 00       	push   $0x81
  jmp __alltraps
c010263b:	e9 54 fb ff ff       	jmp    c0102194 <__alltraps>

c0102640 <vector130>:
.globl vector130
vector130:
  pushl $0
c0102640:	6a 00                	push   $0x0
  pushl $130
c0102642:	68 82 00 00 00       	push   $0x82
  jmp __alltraps
c0102647:	e9 48 fb ff ff       	jmp    c0102194 <__alltraps>

c010264c <vector131>:
.globl vector131
vector131:
  pushl $0
c010264c:	6a 00                	push   $0x0
  pushl $131
c010264e:	68 83 00 00 00       	push   $0x83
  jmp __alltraps
c0102653:	e9 3c fb ff ff       	jmp    c0102194 <__alltraps>

c0102658 <vector132>:
.globl vector132
vector132:
  pushl $0
c0102658:	6a 00                	push   $0x0
  pushl $132
c010265a:	68 84 00 00 00       	push   $0x84
  jmp __alltraps
c010265f:	e9 30 fb ff ff       	jmp    c0102194 <__alltraps>

c0102664 <vector133>:
.globl vector133
vector133:
  pushl $0
c0102664:	6a 00                	push   $0x0
  pushl $133
c0102666:	68 85 00 00 00       	push   $0x85
  jmp __alltraps
c010266b:	e9 24 fb ff ff       	jmp    c0102194 <__alltraps>

c0102670 <vector134>:
.globl vector134
vector134:
  pushl $0
c0102670:	6a 00                	push   $0x0
  pushl $134
c0102672:	68 86 00 00 00       	push   $0x86
  jmp __alltraps
c0102677:	e9 18 fb ff ff       	jmp    c0102194 <__alltraps>

c010267c <vector135>:
.globl vector135
vector135:
  pushl $0
c010267c:	6a 00                	push   $0x0
  pushl $135
c010267e:	68 87 00 00 00       	push   $0x87
  jmp __alltraps
c0102683:	e9 0c fb ff ff       	jmp    c0102194 <__alltraps>

c0102688 <vector136>:
.globl vector136
vector136:
  pushl $0
c0102688:	6a 00                	push   $0x0
  pushl $136
c010268a:	68 88 00 00 00       	push   $0x88
  jmp __alltraps
c010268f:	e9 00 fb ff ff       	jmp    c0102194 <__alltraps>

c0102694 <vector137>:
.globl vector137
vector137:
  pushl $0
c0102694:	6a 00                	push   $0x0
  pushl $137
c0102696:	68 89 00 00 00       	push   $0x89
  jmp __alltraps
c010269b:	e9 f4 fa ff ff       	jmp    c0102194 <__alltraps>

c01026a0 <vector138>:
.globl vector138
vector138:
  pushl $0
c01026a0:	6a 00                	push   $0x0
  pushl $138
c01026a2:	68 8a 00 00 00       	push   $0x8a
  jmp __alltraps
c01026a7:	e9 e8 fa ff ff       	jmp    c0102194 <__alltraps>

c01026ac <vector139>:
.globl vector139
vector139:
  pushl $0
c01026ac:	6a 00                	push   $0x0
  pushl $139
c01026ae:	68 8b 00 00 00       	push   $0x8b
  jmp __alltraps
c01026b3:	e9 dc fa ff ff       	jmp    c0102194 <__alltraps>

c01026b8 <vector140>:
.globl vector140
vector140:
  pushl $0
c01026b8:	6a 00                	push   $0x0
  pushl $140
c01026ba:	68 8c 00 00 00       	push   $0x8c
  jmp __alltraps
c01026bf:	e9 d0 fa ff ff       	jmp    c0102194 <__alltraps>

c01026c4 <vector141>:
.globl vector141
vector141:
  pushl $0
c01026c4:	6a 00                	push   $0x0
  pushl $141
c01026c6:	68 8d 00 00 00       	push   $0x8d
  jmp __alltraps
c01026cb:	e9 c4 fa ff ff       	jmp    c0102194 <__alltraps>

c01026d0 <vector142>:
.globl vector142
vector142:
  pushl $0
c01026d0:	6a 00                	push   $0x0
  pushl $142
c01026d2:	68 8e 00 00 00       	push   $0x8e
  jmp __alltraps
c01026d7:	e9 b8 fa ff ff       	jmp    c0102194 <__alltraps>

c01026dc <vector143>:
.globl vector143
vector143:
  pushl $0
c01026dc:	6a 00                	push   $0x0
  pushl $143
c01026de:	68 8f 00 00 00       	push   $0x8f
  jmp __alltraps
c01026e3:	e9 ac fa ff ff       	jmp    c0102194 <__alltraps>

c01026e8 <vector144>:
.globl vector144
vector144:
  pushl $0
c01026e8:	6a 00                	push   $0x0
  pushl $144
c01026ea:	68 90 00 00 00       	push   $0x90
  jmp __alltraps
c01026ef:	e9 a0 fa ff ff       	jmp    c0102194 <__alltraps>

c01026f4 <vector145>:
.globl vector145
vector145:
  pushl $0
c01026f4:	6a 00                	push   $0x0
  pushl $145
c01026f6:	68 91 00 00 00       	push   $0x91
  jmp __alltraps
c01026fb:	e9 94 fa ff ff       	jmp    c0102194 <__alltraps>

c0102700 <vector146>:
.globl vector146
vector146:
  pushl $0
c0102700:	6a 00                	push   $0x0
  pushl $146
c0102702:	68 92 00 00 00       	push   $0x92
  jmp __alltraps
c0102707:	e9 88 fa ff ff       	jmp    c0102194 <__alltraps>

c010270c <vector147>:
.globl vector147
vector147:
  pushl $0
c010270c:	6a 00                	push   $0x0
  pushl $147
c010270e:	68 93 00 00 00       	push   $0x93
  jmp __alltraps
c0102713:	e9 7c fa ff ff       	jmp    c0102194 <__alltraps>

c0102718 <vector148>:
.globl vector148
vector148:
  pushl $0
c0102718:	6a 00                	push   $0x0
  pushl $148
c010271a:	68 94 00 00 00       	push   $0x94
  jmp __alltraps
c010271f:	e9 70 fa ff ff       	jmp    c0102194 <__alltraps>

c0102724 <vector149>:
.globl vector149
vector149:
  pushl $0
c0102724:	6a 00                	push   $0x0
  pushl $149
c0102726:	68 95 00 00 00       	push   $0x95
  jmp __alltraps
c010272b:	e9 64 fa ff ff       	jmp    c0102194 <__alltraps>

c0102730 <vector150>:
.globl vector150
vector150:
  pushl $0
c0102730:	6a 00                	push   $0x0
  pushl $150
c0102732:	68 96 00 00 00       	push   $0x96
  jmp __alltraps
c0102737:	e9 58 fa ff ff       	jmp    c0102194 <__alltraps>

c010273c <vector151>:
.globl vector151
vector151:
  pushl $0
c010273c:	6a 00                	push   $0x0
  pushl $151
c010273e:	68 97 00 00 00       	push   $0x97
  jmp __alltraps
c0102743:	e9 4c fa ff ff       	jmp    c0102194 <__alltraps>

c0102748 <vector152>:
.globl vector152
vector152:
  pushl $0
c0102748:	6a 00                	push   $0x0
  pushl $152
c010274a:	68 98 00 00 00       	push   $0x98
  jmp __alltraps
c010274f:	e9 40 fa ff ff       	jmp    c0102194 <__alltraps>

c0102754 <vector153>:
.globl vector153
vector153:
  pushl $0
c0102754:	6a 00                	push   $0x0
  pushl $153
c0102756:	68 99 00 00 00       	push   $0x99
  jmp __alltraps
c010275b:	e9 34 fa ff ff       	jmp    c0102194 <__alltraps>

c0102760 <vector154>:
.globl vector154
vector154:
  pushl $0
c0102760:	6a 00                	push   $0x0
  pushl $154
c0102762:	68 9a 00 00 00       	push   $0x9a
  jmp __alltraps
c0102767:	e9 28 fa ff ff       	jmp    c0102194 <__alltraps>

c010276c <vector155>:
.globl vector155
vector155:
  pushl $0
c010276c:	6a 00                	push   $0x0
  pushl $155
c010276e:	68 9b 00 00 00       	push   $0x9b
  jmp __alltraps
c0102773:	e9 1c fa ff ff       	jmp    c0102194 <__alltraps>

c0102778 <vector156>:
.globl vector156
vector156:
  pushl $0
c0102778:	6a 00                	push   $0x0
  pushl $156
c010277a:	68 9c 00 00 00       	push   $0x9c
  jmp __alltraps
c010277f:	e9 10 fa ff ff       	jmp    c0102194 <__alltraps>

c0102784 <vector157>:
.globl vector157
vector157:
  pushl $0
c0102784:	6a 00                	push   $0x0
  pushl $157
c0102786:	68 9d 00 00 00       	push   $0x9d
  jmp __alltraps
c010278b:	e9 04 fa ff ff       	jmp    c0102194 <__alltraps>

c0102790 <vector158>:
.globl vector158
vector158:
  pushl $0
c0102790:	6a 00                	push   $0x0
  pushl $158
c0102792:	68 9e 00 00 00       	push   $0x9e
  jmp __alltraps
c0102797:	e9 f8 f9 ff ff       	jmp    c0102194 <__alltraps>

c010279c <vector159>:
.globl vector159
vector159:
  pushl $0
c010279c:	6a 00                	push   $0x0
  pushl $159
c010279e:	68 9f 00 00 00       	push   $0x9f
  jmp __alltraps
c01027a3:	e9 ec f9 ff ff       	jmp    c0102194 <__alltraps>

c01027a8 <vector160>:
.globl vector160
vector160:
  pushl $0
c01027a8:	6a 00                	push   $0x0
  pushl $160
c01027aa:	68 a0 00 00 00       	push   $0xa0
  jmp __alltraps
c01027af:	e9 e0 f9 ff ff       	jmp    c0102194 <__alltraps>

c01027b4 <vector161>:
.globl vector161
vector161:
  pushl $0
c01027b4:	6a 00                	push   $0x0
  pushl $161
c01027b6:	68 a1 00 00 00       	push   $0xa1
  jmp __alltraps
c01027bb:	e9 d4 f9 ff ff       	jmp    c0102194 <__alltraps>

c01027c0 <vector162>:
.globl vector162
vector162:
  pushl $0
c01027c0:	6a 00                	push   $0x0
  pushl $162
c01027c2:	68 a2 00 00 00       	push   $0xa2
  jmp __alltraps
c01027c7:	e9 c8 f9 ff ff       	jmp    c0102194 <__alltraps>

c01027cc <vector163>:
.globl vector163
vector163:
  pushl $0
c01027cc:	6a 00                	push   $0x0
  pushl $163
c01027ce:	68 a3 00 00 00       	push   $0xa3
  jmp __alltraps
c01027d3:	e9 bc f9 ff ff       	jmp    c0102194 <__alltraps>

c01027d8 <vector164>:
.globl vector164
vector164:
  pushl $0
c01027d8:	6a 00                	push   $0x0
  pushl $164
c01027da:	68 a4 00 00 00       	push   $0xa4
  jmp __alltraps
c01027df:	e9 b0 f9 ff ff       	jmp    c0102194 <__alltraps>

c01027e4 <vector165>:
.globl vector165
vector165:
  pushl $0
c01027e4:	6a 00                	push   $0x0
  pushl $165
c01027e6:	68 a5 00 00 00       	push   $0xa5
  jmp __alltraps
c01027eb:	e9 a4 f9 ff ff       	jmp    c0102194 <__alltraps>

c01027f0 <vector166>:
.globl vector166
vector166:
  pushl $0
c01027f0:	6a 00                	push   $0x0
  pushl $166
c01027f2:	68 a6 00 00 00       	push   $0xa6
  jmp __alltraps
c01027f7:	e9 98 f9 ff ff       	jmp    c0102194 <__alltraps>

c01027fc <vector167>:
.globl vector167
vector167:
  pushl $0
c01027fc:	6a 00                	push   $0x0
  pushl $167
c01027fe:	68 a7 00 00 00       	push   $0xa7
  jmp __alltraps
c0102803:	e9 8c f9 ff ff       	jmp    c0102194 <__alltraps>

c0102808 <vector168>:
.globl vector168
vector168:
  pushl $0
c0102808:	6a 00                	push   $0x0
  pushl $168
c010280a:	68 a8 00 00 00       	push   $0xa8
  jmp __alltraps
c010280f:	e9 80 f9 ff ff       	jmp    c0102194 <__alltraps>

c0102814 <vector169>:
.globl vector169
vector169:
  pushl $0
c0102814:	6a 00                	push   $0x0
  pushl $169
c0102816:	68 a9 00 00 00       	push   $0xa9
  jmp __alltraps
c010281b:	e9 74 f9 ff ff       	jmp    c0102194 <__alltraps>

c0102820 <vector170>:
.globl vector170
vector170:
  pushl $0
c0102820:	6a 00                	push   $0x0
  pushl $170
c0102822:	68 aa 00 00 00       	push   $0xaa
  jmp __alltraps
c0102827:	e9 68 f9 ff ff       	jmp    c0102194 <__alltraps>

c010282c <vector171>:
.globl vector171
vector171:
  pushl $0
c010282c:	6a 00                	push   $0x0
  pushl $171
c010282e:	68 ab 00 00 00       	push   $0xab
  jmp __alltraps
c0102833:	e9 5c f9 ff ff       	jmp    c0102194 <__alltraps>

c0102838 <vector172>:
.globl vector172
vector172:
  pushl $0
c0102838:	6a 00                	push   $0x0
  pushl $172
c010283a:	68 ac 00 00 00       	push   $0xac
  jmp __alltraps
c010283f:	e9 50 f9 ff ff       	jmp    c0102194 <__alltraps>

c0102844 <vector173>:
.globl vector173
vector173:
  pushl $0
c0102844:	6a 00                	push   $0x0
  pushl $173
c0102846:	68 ad 00 00 00       	push   $0xad
  jmp __alltraps
c010284b:	e9 44 f9 ff ff       	jmp    c0102194 <__alltraps>

c0102850 <vector174>:
.globl vector174
vector174:
  pushl $0
c0102850:	6a 00                	push   $0x0
  pushl $174
c0102852:	68 ae 00 00 00       	push   $0xae
  jmp __alltraps
c0102857:	e9 38 f9 ff ff       	jmp    c0102194 <__alltraps>

c010285c <vector175>:
.globl vector175
vector175:
  pushl $0
c010285c:	6a 00                	push   $0x0
  pushl $175
c010285e:	68 af 00 00 00       	push   $0xaf
  jmp __alltraps
c0102863:	e9 2c f9 ff ff       	jmp    c0102194 <__alltraps>

c0102868 <vector176>:
.globl vector176
vector176:
  pushl $0
c0102868:	6a 00                	push   $0x0
  pushl $176
c010286a:	68 b0 00 00 00       	push   $0xb0
  jmp __alltraps
c010286f:	e9 20 f9 ff ff       	jmp    c0102194 <__alltraps>

c0102874 <vector177>:
.globl vector177
vector177:
  pushl $0
c0102874:	6a 00                	push   $0x0
  pushl $177
c0102876:	68 b1 00 00 00       	push   $0xb1
  jmp __alltraps
c010287b:	e9 14 f9 ff ff       	jmp    c0102194 <__alltraps>

c0102880 <vector178>:
.globl vector178
vector178:
  pushl $0
c0102880:	6a 00                	push   $0x0
  pushl $178
c0102882:	68 b2 00 00 00       	push   $0xb2
  jmp __alltraps
c0102887:	e9 08 f9 ff ff       	jmp    c0102194 <__alltraps>

c010288c <vector179>:
.globl vector179
vector179:
  pushl $0
c010288c:	6a 00                	push   $0x0
  pushl $179
c010288e:	68 b3 00 00 00       	push   $0xb3
  jmp __alltraps
c0102893:	e9 fc f8 ff ff       	jmp    c0102194 <__alltraps>

c0102898 <vector180>:
.globl vector180
vector180:
  pushl $0
c0102898:	6a 00                	push   $0x0
  pushl $180
c010289a:	68 b4 00 00 00       	push   $0xb4
  jmp __alltraps
c010289f:	e9 f0 f8 ff ff       	jmp    c0102194 <__alltraps>

c01028a4 <vector181>:
.globl vector181
vector181:
  pushl $0
c01028a4:	6a 00                	push   $0x0
  pushl $181
c01028a6:	68 b5 00 00 00       	push   $0xb5
  jmp __alltraps
c01028ab:	e9 e4 f8 ff ff       	jmp    c0102194 <__alltraps>

c01028b0 <vector182>:
.globl vector182
vector182:
  pushl $0
c01028b0:	6a 00                	push   $0x0
  pushl $182
c01028b2:	68 b6 00 00 00       	push   $0xb6
  jmp __alltraps
c01028b7:	e9 d8 f8 ff ff       	jmp    c0102194 <__alltraps>

c01028bc <vector183>:
.globl vector183
vector183:
  pushl $0
c01028bc:	6a 00                	push   $0x0
  pushl $183
c01028be:	68 b7 00 00 00       	push   $0xb7
  jmp __alltraps
c01028c3:	e9 cc f8 ff ff       	jmp    c0102194 <__alltraps>

c01028c8 <vector184>:
.globl vector184
vector184:
  pushl $0
c01028c8:	6a 00                	push   $0x0
  pushl $184
c01028ca:	68 b8 00 00 00       	push   $0xb8
  jmp __alltraps
c01028cf:	e9 c0 f8 ff ff       	jmp    c0102194 <__alltraps>

c01028d4 <vector185>:
.globl vector185
vector185:
  pushl $0
c01028d4:	6a 00                	push   $0x0
  pushl $185
c01028d6:	68 b9 00 00 00       	push   $0xb9
  jmp __alltraps
c01028db:	e9 b4 f8 ff ff       	jmp    c0102194 <__alltraps>

c01028e0 <vector186>:
.globl vector186
vector186:
  pushl $0
c01028e0:	6a 00                	push   $0x0
  pushl $186
c01028e2:	68 ba 00 00 00       	push   $0xba
  jmp __alltraps
c01028e7:	e9 a8 f8 ff ff       	jmp    c0102194 <__alltraps>

c01028ec <vector187>:
.globl vector187
vector187:
  pushl $0
c01028ec:	6a 00                	push   $0x0
  pushl $187
c01028ee:	68 bb 00 00 00       	push   $0xbb
  jmp __alltraps
c01028f3:	e9 9c f8 ff ff       	jmp    c0102194 <__alltraps>

c01028f8 <vector188>:
.globl vector188
vector188:
  pushl $0
c01028f8:	6a 00                	push   $0x0
  pushl $188
c01028fa:	68 bc 00 00 00       	push   $0xbc
  jmp __alltraps
c01028ff:	e9 90 f8 ff ff       	jmp    c0102194 <__alltraps>

c0102904 <vector189>:
.globl vector189
vector189:
  pushl $0
c0102904:	6a 00                	push   $0x0
  pushl $189
c0102906:	68 bd 00 00 00       	push   $0xbd
  jmp __alltraps
c010290b:	e9 84 f8 ff ff       	jmp    c0102194 <__alltraps>

c0102910 <vector190>:
.globl vector190
vector190:
  pushl $0
c0102910:	6a 00                	push   $0x0
  pushl $190
c0102912:	68 be 00 00 00       	push   $0xbe
  jmp __alltraps
c0102917:	e9 78 f8 ff ff       	jmp    c0102194 <__alltraps>

c010291c <vector191>:
.globl vector191
vector191:
  pushl $0
c010291c:	6a 00                	push   $0x0
  pushl $191
c010291e:	68 bf 00 00 00       	push   $0xbf
  jmp __alltraps
c0102923:	e9 6c f8 ff ff       	jmp    c0102194 <__alltraps>

c0102928 <vector192>:
.globl vector192
vector192:
  pushl $0
c0102928:	6a 00                	push   $0x0
  pushl $192
c010292a:	68 c0 00 00 00       	push   $0xc0
  jmp __alltraps
c010292f:	e9 60 f8 ff ff       	jmp    c0102194 <__alltraps>

c0102934 <vector193>:
.globl vector193
vector193:
  pushl $0
c0102934:	6a 00                	push   $0x0
  pushl $193
c0102936:	68 c1 00 00 00       	push   $0xc1
  jmp __alltraps
c010293b:	e9 54 f8 ff ff       	jmp    c0102194 <__alltraps>

c0102940 <vector194>:
.globl vector194
vector194:
  pushl $0
c0102940:	6a 00                	push   $0x0
  pushl $194
c0102942:	68 c2 00 00 00       	push   $0xc2
  jmp __alltraps
c0102947:	e9 48 f8 ff ff       	jmp    c0102194 <__alltraps>

c010294c <vector195>:
.globl vector195
vector195:
  pushl $0
c010294c:	6a 00                	push   $0x0
  pushl $195
c010294e:	68 c3 00 00 00       	push   $0xc3
  jmp __alltraps
c0102953:	e9 3c f8 ff ff       	jmp    c0102194 <__alltraps>

c0102958 <vector196>:
.globl vector196
vector196:
  pushl $0
c0102958:	6a 00                	push   $0x0
  pushl $196
c010295a:	68 c4 00 00 00       	push   $0xc4
  jmp __alltraps
c010295f:	e9 30 f8 ff ff       	jmp    c0102194 <__alltraps>

c0102964 <vector197>:
.globl vector197
vector197:
  pushl $0
c0102964:	6a 00                	push   $0x0
  pushl $197
c0102966:	68 c5 00 00 00       	push   $0xc5
  jmp __alltraps
c010296b:	e9 24 f8 ff ff       	jmp    c0102194 <__alltraps>

c0102970 <vector198>:
.globl vector198
vector198:
  pushl $0
c0102970:	6a 00                	push   $0x0
  pushl $198
c0102972:	68 c6 00 00 00       	push   $0xc6
  jmp __alltraps
c0102977:	e9 18 f8 ff ff       	jmp    c0102194 <__alltraps>

c010297c <vector199>:
.globl vector199
vector199:
  pushl $0
c010297c:	6a 00                	push   $0x0
  pushl $199
c010297e:	68 c7 00 00 00       	push   $0xc7
  jmp __alltraps
c0102983:	e9 0c f8 ff ff       	jmp    c0102194 <__alltraps>

c0102988 <vector200>:
.globl vector200
vector200:
  pushl $0
c0102988:	6a 00                	push   $0x0
  pushl $200
c010298a:	68 c8 00 00 00       	push   $0xc8
  jmp __alltraps
c010298f:	e9 00 f8 ff ff       	jmp    c0102194 <__alltraps>

c0102994 <vector201>:
.globl vector201
vector201:
  pushl $0
c0102994:	6a 00                	push   $0x0
  pushl $201
c0102996:	68 c9 00 00 00       	push   $0xc9
  jmp __alltraps
c010299b:	e9 f4 f7 ff ff       	jmp    c0102194 <__alltraps>

c01029a0 <vector202>:
.globl vector202
vector202:
  pushl $0
c01029a0:	6a 00                	push   $0x0
  pushl $202
c01029a2:	68 ca 00 00 00       	push   $0xca
  jmp __alltraps
c01029a7:	e9 e8 f7 ff ff       	jmp    c0102194 <__alltraps>

c01029ac <vector203>:
.globl vector203
vector203:
  pushl $0
c01029ac:	6a 00                	push   $0x0
  pushl $203
c01029ae:	68 cb 00 00 00       	push   $0xcb
  jmp __alltraps
c01029b3:	e9 dc f7 ff ff       	jmp    c0102194 <__alltraps>

c01029b8 <vector204>:
.globl vector204
vector204:
  pushl $0
c01029b8:	6a 00                	push   $0x0
  pushl $204
c01029ba:	68 cc 00 00 00       	push   $0xcc
  jmp __alltraps
c01029bf:	e9 d0 f7 ff ff       	jmp    c0102194 <__alltraps>

c01029c4 <vector205>:
.globl vector205
vector205:
  pushl $0
c01029c4:	6a 00                	push   $0x0
  pushl $205
c01029c6:	68 cd 00 00 00       	push   $0xcd
  jmp __alltraps
c01029cb:	e9 c4 f7 ff ff       	jmp    c0102194 <__alltraps>

c01029d0 <vector206>:
.globl vector206
vector206:
  pushl $0
c01029d0:	6a 00                	push   $0x0
  pushl $206
c01029d2:	68 ce 00 00 00       	push   $0xce
  jmp __alltraps
c01029d7:	e9 b8 f7 ff ff       	jmp    c0102194 <__alltraps>

c01029dc <vector207>:
.globl vector207
vector207:
  pushl $0
c01029dc:	6a 00                	push   $0x0
  pushl $207
c01029de:	68 cf 00 00 00       	push   $0xcf
  jmp __alltraps
c01029e3:	e9 ac f7 ff ff       	jmp    c0102194 <__alltraps>

c01029e8 <vector208>:
.globl vector208
vector208:
  pushl $0
c01029e8:	6a 00                	push   $0x0
  pushl $208
c01029ea:	68 d0 00 00 00       	push   $0xd0
  jmp __alltraps
c01029ef:	e9 a0 f7 ff ff       	jmp    c0102194 <__alltraps>

c01029f4 <vector209>:
.globl vector209
vector209:
  pushl $0
c01029f4:	6a 00                	push   $0x0
  pushl $209
c01029f6:	68 d1 00 00 00       	push   $0xd1
  jmp __alltraps
c01029fb:	e9 94 f7 ff ff       	jmp    c0102194 <__alltraps>

c0102a00 <vector210>:
.globl vector210
vector210:
  pushl $0
c0102a00:	6a 00                	push   $0x0
  pushl $210
c0102a02:	68 d2 00 00 00       	push   $0xd2
  jmp __alltraps
c0102a07:	e9 88 f7 ff ff       	jmp    c0102194 <__alltraps>

c0102a0c <vector211>:
.globl vector211
vector211:
  pushl $0
c0102a0c:	6a 00                	push   $0x0
  pushl $211
c0102a0e:	68 d3 00 00 00       	push   $0xd3
  jmp __alltraps
c0102a13:	e9 7c f7 ff ff       	jmp    c0102194 <__alltraps>

c0102a18 <vector212>:
.globl vector212
vector212:
  pushl $0
c0102a18:	6a 00                	push   $0x0
  pushl $212
c0102a1a:	68 d4 00 00 00       	push   $0xd4
  jmp __alltraps
c0102a1f:	e9 70 f7 ff ff       	jmp    c0102194 <__alltraps>

c0102a24 <vector213>:
.globl vector213
vector213:
  pushl $0
c0102a24:	6a 00                	push   $0x0
  pushl $213
c0102a26:	68 d5 00 00 00       	push   $0xd5
  jmp __alltraps
c0102a2b:	e9 64 f7 ff ff       	jmp    c0102194 <__alltraps>

c0102a30 <vector214>:
.globl vector214
vector214:
  pushl $0
c0102a30:	6a 00                	push   $0x0
  pushl $214
c0102a32:	68 d6 00 00 00       	push   $0xd6
  jmp __alltraps
c0102a37:	e9 58 f7 ff ff       	jmp    c0102194 <__alltraps>

c0102a3c <vector215>:
.globl vector215
vector215:
  pushl $0
c0102a3c:	6a 00                	push   $0x0
  pushl $215
c0102a3e:	68 d7 00 00 00       	push   $0xd7
  jmp __alltraps
c0102a43:	e9 4c f7 ff ff       	jmp    c0102194 <__alltraps>

c0102a48 <vector216>:
.globl vector216
vector216:
  pushl $0
c0102a48:	6a 00                	push   $0x0
  pushl $216
c0102a4a:	68 d8 00 00 00       	push   $0xd8
  jmp __alltraps
c0102a4f:	e9 40 f7 ff ff       	jmp    c0102194 <__alltraps>

c0102a54 <vector217>:
.globl vector217
vector217:
  pushl $0
c0102a54:	6a 00                	push   $0x0
  pushl $217
c0102a56:	68 d9 00 00 00       	push   $0xd9
  jmp __alltraps
c0102a5b:	e9 34 f7 ff ff       	jmp    c0102194 <__alltraps>

c0102a60 <vector218>:
.globl vector218
vector218:
  pushl $0
c0102a60:	6a 00                	push   $0x0
  pushl $218
c0102a62:	68 da 00 00 00       	push   $0xda
  jmp __alltraps
c0102a67:	e9 28 f7 ff ff       	jmp    c0102194 <__alltraps>

c0102a6c <vector219>:
.globl vector219
vector219:
  pushl $0
c0102a6c:	6a 00                	push   $0x0
  pushl $219
c0102a6e:	68 db 00 00 00       	push   $0xdb
  jmp __alltraps
c0102a73:	e9 1c f7 ff ff       	jmp    c0102194 <__alltraps>

c0102a78 <vector220>:
.globl vector220
vector220:
  pushl $0
c0102a78:	6a 00                	push   $0x0
  pushl $220
c0102a7a:	68 dc 00 00 00       	push   $0xdc
  jmp __alltraps
c0102a7f:	e9 10 f7 ff ff       	jmp    c0102194 <__alltraps>

c0102a84 <vector221>:
.globl vector221
vector221:
  pushl $0
c0102a84:	6a 00                	push   $0x0
  pushl $221
c0102a86:	68 dd 00 00 00       	push   $0xdd
  jmp __alltraps
c0102a8b:	e9 04 f7 ff ff       	jmp    c0102194 <__alltraps>

c0102a90 <vector222>:
.globl vector222
vector222:
  pushl $0
c0102a90:	6a 00                	push   $0x0
  pushl $222
c0102a92:	68 de 00 00 00       	push   $0xde
  jmp __alltraps
c0102a97:	e9 f8 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102a9c <vector223>:
.globl vector223
vector223:
  pushl $0
c0102a9c:	6a 00                	push   $0x0
  pushl $223
c0102a9e:	68 df 00 00 00       	push   $0xdf
  jmp __alltraps
c0102aa3:	e9 ec f6 ff ff       	jmp    c0102194 <__alltraps>

c0102aa8 <vector224>:
.globl vector224
vector224:
  pushl $0
c0102aa8:	6a 00                	push   $0x0
  pushl $224
c0102aaa:	68 e0 00 00 00       	push   $0xe0
  jmp __alltraps
c0102aaf:	e9 e0 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102ab4 <vector225>:
.globl vector225
vector225:
  pushl $0
c0102ab4:	6a 00                	push   $0x0
  pushl $225
c0102ab6:	68 e1 00 00 00       	push   $0xe1
  jmp __alltraps
c0102abb:	e9 d4 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102ac0 <vector226>:
.globl vector226
vector226:
  pushl $0
c0102ac0:	6a 00                	push   $0x0
  pushl $226
c0102ac2:	68 e2 00 00 00       	push   $0xe2
  jmp __alltraps
c0102ac7:	e9 c8 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102acc <vector227>:
.globl vector227
vector227:
  pushl $0
c0102acc:	6a 00                	push   $0x0
  pushl $227
c0102ace:	68 e3 00 00 00       	push   $0xe3
  jmp __alltraps
c0102ad3:	e9 bc f6 ff ff       	jmp    c0102194 <__alltraps>

c0102ad8 <vector228>:
.globl vector228
vector228:
  pushl $0
c0102ad8:	6a 00                	push   $0x0
  pushl $228
c0102ada:	68 e4 00 00 00       	push   $0xe4
  jmp __alltraps
c0102adf:	e9 b0 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102ae4 <vector229>:
.globl vector229
vector229:
  pushl $0
c0102ae4:	6a 00                	push   $0x0
  pushl $229
c0102ae6:	68 e5 00 00 00       	push   $0xe5
  jmp __alltraps
c0102aeb:	e9 a4 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102af0 <vector230>:
.globl vector230
vector230:
  pushl $0
c0102af0:	6a 00                	push   $0x0
  pushl $230
c0102af2:	68 e6 00 00 00       	push   $0xe6
  jmp __alltraps
c0102af7:	e9 98 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102afc <vector231>:
.globl vector231
vector231:
  pushl $0
c0102afc:	6a 00                	push   $0x0
  pushl $231
c0102afe:	68 e7 00 00 00       	push   $0xe7
  jmp __alltraps
c0102b03:	e9 8c f6 ff ff       	jmp    c0102194 <__alltraps>

c0102b08 <vector232>:
.globl vector232
vector232:
  pushl $0
c0102b08:	6a 00                	push   $0x0
  pushl $232
c0102b0a:	68 e8 00 00 00       	push   $0xe8
  jmp __alltraps
c0102b0f:	e9 80 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102b14 <vector233>:
.globl vector233
vector233:
  pushl $0
c0102b14:	6a 00                	push   $0x0
  pushl $233
c0102b16:	68 e9 00 00 00       	push   $0xe9
  jmp __alltraps
c0102b1b:	e9 74 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102b20 <vector234>:
.globl vector234
vector234:
  pushl $0
c0102b20:	6a 00                	push   $0x0
  pushl $234
c0102b22:	68 ea 00 00 00       	push   $0xea
  jmp __alltraps
c0102b27:	e9 68 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102b2c <vector235>:
.globl vector235
vector235:
  pushl $0
c0102b2c:	6a 00                	push   $0x0
  pushl $235
c0102b2e:	68 eb 00 00 00       	push   $0xeb
  jmp __alltraps
c0102b33:	e9 5c f6 ff ff       	jmp    c0102194 <__alltraps>

c0102b38 <vector236>:
.globl vector236
vector236:
  pushl $0
c0102b38:	6a 00                	push   $0x0
  pushl $236
c0102b3a:	68 ec 00 00 00       	push   $0xec
  jmp __alltraps
c0102b3f:	e9 50 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102b44 <vector237>:
.globl vector237
vector237:
  pushl $0
c0102b44:	6a 00                	push   $0x0
  pushl $237
c0102b46:	68 ed 00 00 00       	push   $0xed
  jmp __alltraps
c0102b4b:	e9 44 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102b50 <vector238>:
.globl vector238
vector238:
  pushl $0
c0102b50:	6a 00                	push   $0x0
  pushl $238
c0102b52:	68 ee 00 00 00       	push   $0xee
  jmp __alltraps
c0102b57:	e9 38 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102b5c <vector239>:
.globl vector239
vector239:
  pushl $0
c0102b5c:	6a 00                	push   $0x0
  pushl $239
c0102b5e:	68 ef 00 00 00       	push   $0xef
  jmp __alltraps
c0102b63:	e9 2c f6 ff ff       	jmp    c0102194 <__alltraps>

c0102b68 <vector240>:
.globl vector240
vector240:
  pushl $0
c0102b68:	6a 00                	push   $0x0
  pushl $240
c0102b6a:	68 f0 00 00 00       	push   $0xf0
  jmp __alltraps
c0102b6f:	e9 20 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102b74 <vector241>:
.globl vector241
vector241:
  pushl $0
c0102b74:	6a 00                	push   $0x0
  pushl $241
c0102b76:	68 f1 00 00 00       	push   $0xf1
  jmp __alltraps
c0102b7b:	e9 14 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102b80 <vector242>:
.globl vector242
vector242:
  pushl $0
c0102b80:	6a 00                	push   $0x0
  pushl $242
c0102b82:	68 f2 00 00 00       	push   $0xf2
  jmp __alltraps
c0102b87:	e9 08 f6 ff ff       	jmp    c0102194 <__alltraps>

c0102b8c <vector243>:
.globl vector243
vector243:
  pushl $0
c0102b8c:	6a 00                	push   $0x0
  pushl $243
c0102b8e:	68 f3 00 00 00       	push   $0xf3
  jmp __alltraps
c0102b93:	e9 fc f5 ff ff       	jmp    c0102194 <__alltraps>

c0102b98 <vector244>:
.globl vector244
vector244:
  pushl $0
c0102b98:	6a 00                	push   $0x0
  pushl $244
c0102b9a:	68 f4 00 00 00       	push   $0xf4
  jmp __alltraps
c0102b9f:	e9 f0 f5 ff ff       	jmp    c0102194 <__alltraps>

c0102ba4 <vector245>:
.globl vector245
vector245:
  pushl $0
c0102ba4:	6a 00                	push   $0x0
  pushl $245
c0102ba6:	68 f5 00 00 00       	push   $0xf5
  jmp __alltraps
c0102bab:	e9 e4 f5 ff ff       	jmp    c0102194 <__alltraps>

c0102bb0 <vector246>:
.globl vector246
vector246:
  pushl $0
c0102bb0:	6a 00                	push   $0x0
  pushl $246
c0102bb2:	68 f6 00 00 00       	push   $0xf6
  jmp __alltraps
c0102bb7:	e9 d8 f5 ff ff       	jmp    c0102194 <__alltraps>

c0102bbc <vector247>:
.globl vector247
vector247:
  pushl $0
c0102bbc:	6a 00                	push   $0x0
  pushl $247
c0102bbe:	68 f7 00 00 00       	push   $0xf7
  jmp __alltraps
c0102bc3:	e9 cc f5 ff ff       	jmp    c0102194 <__alltraps>

c0102bc8 <vector248>:
.globl vector248
vector248:
  pushl $0
c0102bc8:	6a 00                	push   $0x0
  pushl $248
c0102bca:	68 f8 00 00 00       	push   $0xf8
  jmp __alltraps
c0102bcf:	e9 c0 f5 ff ff       	jmp    c0102194 <__alltraps>

c0102bd4 <vector249>:
.globl vector249
vector249:
  pushl $0
c0102bd4:	6a 00                	push   $0x0
  pushl $249
c0102bd6:	68 f9 00 00 00       	push   $0xf9
  jmp __alltraps
c0102bdb:	e9 b4 f5 ff ff       	jmp    c0102194 <__alltraps>

c0102be0 <vector250>:
.globl vector250
vector250:
  pushl $0
c0102be0:	6a 00                	push   $0x0
  pushl $250
c0102be2:	68 fa 00 00 00       	push   $0xfa
  jmp __alltraps
c0102be7:	e9 a8 f5 ff ff       	jmp    c0102194 <__alltraps>

c0102bec <vector251>:
.globl vector251
vector251:
  pushl $0
c0102bec:	6a 00                	push   $0x0
  pushl $251
c0102bee:	68 fb 00 00 00       	push   $0xfb
  jmp __alltraps
c0102bf3:	e9 9c f5 ff ff       	jmp    c0102194 <__alltraps>

c0102bf8 <vector252>:
.globl vector252
vector252:
  pushl $0
c0102bf8:	6a 00                	push   $0x0
  pushl $252
c0102bfa:	68 fc 00 00 00       	push   $0xfc
  jmp __alltraps
c0102bff:	e9 90 f5 ff ff       	jmp    c0102194 <__alltraps>

c0102c04 <vector253>:
.globl vector253
vector253:
  pushl $0
c0102c04:	6a 00                	push   $0x0
  pushl $253
c0102c06:	68 fd 00 00 00       	push   $0xfd
  jmp __alltraps
c0102c0b:	e9 84 f5 ff ff       	jmp    c0102194 <__alltraps>

c0102c10 <vector254>:
.globl vector254
vector254:
  pushl $0
c0102c10:	6a 00                	push   $0x0
  pushl $254
c0102c12:	68 fe 00 00 00       	push   $0xfe
  jmp __alltraps
c0102c17:	e9 78 f5 ff ff       	jmp    c0102194 <__alltraps>

c0102c1c <vector255>:
.globl vector255
vector255:
  pushl $0
c0102c1c:	6a 00                	push   $0x0
  pushl $255
c0102c1e:	68 ff 00 00 00       	push   $0xff
  jmp __alltraps
c0102c23:	e9 6c f5 ff ff       	jmp    c0102194 <__alltraps>

c0102c28 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
c0102c28:	55                   	push   %ebp
c0102c29:	89 e5                	mov    %esp,%ebp
    return page - pages;
c0102c2b:	8b 55 08             	mov    0x8(%ebp),%edx
c0102c2e:	a1 fc 57 12 c0       	mov    0xc01257fc,%eax
c0102c33:	29 c2                	sub    %eax,%edx
c0102c35:	89 d0                	mov    %edx,%eax
c0102c37:	c1 f8 02             	sar    $0x2,%eax
c0102c3a:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
c0102c40:	5d                   	pop    %ebp
c0102c41:	c3                   	ret    

c0102c42 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
c0102c42:	55                   	push   %ebp
c0102c43:	89 e5                	mov    %esp,%ebp
c0102c45:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
c0102c48:	8b 45 08             	mov    0x8(%ebp),%eax
c0102c4b:	89 04 24             	mov    %eax,(%esp)
c0102c4e:	e8 d5 ff ff ff       	call   c0102c28 <page2ppn>
c0102c53:	c1 e0 0c             	shl    $0xc,%eax
}
c0102c56:	c9                   	leave  
c0102c57:	c3                   	ret    

c0102c58 <set_page_ref>:
page_ref(struct Page *page) {
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
c0102c58:	55                   	push   %ebp
c0102c59:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c0102c5b:	8b 45 08             	mov    0x8(%ebp),%eax
c0102c5e:	8b 55 0c             	mov    0xc(%ebp),%edx
c0102c61:	89 10                	mov    %edx,(%eax)
}
c0102c63:	5d                   	pop    %ebp
c0102c64:	c3                   	ret    

c0102c65 <print_buddy_sys>:
free_area_t free_area[MAX_ORDER + 1];
#define free_list(i) (free_area[i].free_list)
#define nr_free(i) (free_area[i].nr_free)

static void
print_buddy_sys(char* s) {
c0102c65:	55                   	push   %ebp
c0102c66:	89 e5                	mov    %esp,%ebp
c0102c68:	83 ec 38             	sub    $0x38,%esp
    cprintf("===============================\n%s\n", s);
c0102c6b:	8b 45 08             	mov    0x8(%ebp),%eax
c0102c6e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102c72:	c7 04 24 30 7a 10 c0 	movl   $0xc0107a30,(%esp)
c0102c79:	e8 d6 d6 ff ff       	call   c0100354 <cprintf>
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
c0102c7e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0102c85:	e9 a6 00 00 00       	jmp    c0102d30 <print_buddy_sys+0xcb>
        cprintf("order %d: ", i);
c0102c8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102c8d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102c91:	c7 04 24 54 7a 10 c0 	movl   $0xc0107a54,(%esp)
c0102c98:	e8 b7 d6 ff ff       	call   c0100354 <cprintf>
        list_entry_t *le = &free_list(i);
c0102c9d:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0102ca0:	89 d0                	mov    %edx,%eax
c0102ca2:	01 c0                	add    %eax,%eax
c0102ca4:	01 d0                	add    %edx,%eax
c0102ca6:	c1 e0 02             	shl    $0x2,%eax
c0102ca9:	05 40 57 12 c0       	add    $0xc0125740,%eax
c0102cae:	89 45 f0             	mov    %eax,-0x10(%ebp)
        while ((le = list_next(le)) != &free_list(i)) {
c0102cb1:	eb 48                	jmp    c0102cfb <print_buddy_sys+0x96>
            struct Page *page = le2page(le, page_link);
c0102cb3:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0102cb6:	83 e8 0c             	sub    $0xc,%eax
c0102cb9:	89 45 ec             	mov    %eax,-0x14(%ebp)
            intptr_t off = offset(page);
c0102cbc:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0102cbf:	a1 80 de 11 c0       	mov    0xc011de80,%eax
c0102cc4:	29 c2                	sub    %eax,%edx
c0102cc6:	89 d0                	mov    %edx,%eax
c0102cc8:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
c0102ccd:	f7 e2                	mul    %edx
c0102ccf:	89 d0                	mov    %edx,%eax
c0102cd1:	c1 e8 04             	shr    $0x4,%eax
c0102cd4:	89 45 e8             	mov    %eax,-0x18(%ebp)
            cprintf("va: %x, offset: %d, property: %d->", page, off, page->property);
c0102cd7:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0102cda:	8b 40 08             	mov    0x8(%eax),%eax
c0102cdd:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0102ce1:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0102ce4:	89 44 24 08          	mov    %eax,0x8(%esp)
c0102ce8:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0102ceb:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102cef:	c7 04 24 60 7a 10 c0 	movl   $0xc0107a60,(%esp)
c0102cf6:	e8 59 d6 ff ff       	call   c0100354 <cprintf>
c0102cfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0102cfe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0102d01:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0102d04:	8b 40 04             	mov    0x4(%eax),%eax
    cprintf("===============================\n%s\n", s);
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
        cprintf("order %d: ", i);
        list_entry_t *le = &free_list(i);
        while ((le = list_next(le)) != &free_list(i)) {
c0102d07:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0102d0a:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0102d0d:	89 d0                	mov    %edx,%eax
c0102d0f:	01 c0                	add    %eax,%eax
c0102d11:	01 d0                	add    %edx,%eax
c0102d13:	c1 e0 02             	shl    $0x2,%eax
c0102d16:	05 40 57 12 c0       	add    $0xc0125740,%eax
c0102d1b:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c0102d1e:	75 93                	jne    c0102cb3 <print_buddy_sys+0x4e>
            struct Page *page = le2page(le, page_link);
            intptr_t off = offset(page);
            cprintf("va: %x, offset: %d, property: %d->", page, off, page->property);
        }
        cprintf("\n");
c0102d20:	c7 04 24 83 7a 10 c0 	movl   $0xc0107a83,(%esp)
c0102d27:	e8 28 d6 ff ff       	call   c0100354 <cprintf>

static void
print_buddy_sys(char* s) {
    cprintf("===============================\n%s\n", s);
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
c0102d2c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0102d30:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
c0102d34:	0f 8e 50 ff ff ff    	jle    c0102c8a <print_buddy_sys+0x25>
            intptr_t off = offset(page);
            cprintf("va: %x, offset: %d, property: %d->", page, off, page->property);
        }
        cprintf("\n");
    }
}
c0102d3a:	c9                   	leave  
c0102d3b:	c3                   	ret    

c0102d3c <buddy_init>:

static void
buddy_init(void) {
c0102d3c:	55                   	push   %ebp
c0102d3d:	89 e5                	mov    %esp,%ebp
c0102d3f:	83 ec 10             	sub    $0x10,%esp
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
c0102d42:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c0102d49:	eb 44                	jmp    c0102d8f <buddy_init+0x53>
        list_init(&free_list(i));
c0102d4b:	8b 55 fc             	mov    -0x4(%ebp),%edx
c0102d4e:	89 d0                	mov    %edx,%eax
c0102d50:	01 c0                	add    %eax,%eax
c0102d52:	01 d0                	add    %edx,%eax
c0102d54:	c1 e0 02             	shl    $0x2,%eax
c0102d57:	05 40 57 12 c0       	add    $0xc0125740,%eax
c0102d5c:	89 45 f8             	mov    %eax,-0x8(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c0102d5f:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0102d62:	8b 55 f8             	mov    -0x8(%ebp),%edx
c0102d65:	89 50 04             	mov    %edx,0x4(%eax)
c0102d68:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0102d6b:	8b 50 04             	mov    0x4(%eax),%edx
c0102d6e:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0102d71:	89 10                	mov    %edx,(%eax)
        nr_free(i) = 0;
c0102d73:	8b 55 fc             	mov    -0x4(%ebp),%edx
c0102d76:	89 d0                	mov    %edx,%eax
c0102d78:	01 c0                	add    %eax,%eax
c0102d7a:	01 d0                	add    %edx,%eax
c0102d7c:	c1 e0 02             	shl    $0x2,%eax
c0102d7f:	05 40 57 12 c0       	add    $0xc0125740,%eax
c0102d84:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}

static void
buddy_init(void) {
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
c0102d8b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c0102d8f:	83 7d fc 0e          	cmpl   $0xe,-0x4(%ebp)
c0102d93:	7e b6                	jle    c0102d4b <buddy_init+0xf>
        list_init(&free_list(i));
        nr_free(i) = 0;
    }
}
c0102d95:	c9                   	leave  
c0102d96:	c3                   	ret    

c0102d97 <flip_bit_map>:

static inline void 
flip_bit_map(int32_t order, struct Page* page) {
c0102d97:	55                   	push   %ebp
c0102d98:	89 e5                	mov    %esp,%ebp
c0102d9a:	56                   	push   %esi
c0102d9b:	53                   	push   %ebx
c0102d9c:	83 ec 10             	sub    $0x10,%esp
    int32_t bit_num = (offset(page) >> (order + 1));
c0102d9f:	8b 55 0c             	mov    0xc(%ebp),%edx
c0102da2:	a1 80 de 11 c0       	mov    0xc011de80,%eax
c0102da7:	29 c2                	sub    %eax,%edx
c0102da9:	89 d0                	mov    %edx,%eax
c0102dab:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
c0102db0:	f7 e2                	mul    %edx
c0102db2:	c1 ea 04             	shr    $0x4,%edx
c0102db5:	8b 45 08             	mov    0x8(%ebp),%eax
c0102db8:	83 c0 01             	add    $0x1,%eax
c0102dbb:	89 c1                	mov    %eax,%ecx
c0102dbd:	d3 ea                	shr    %cl,%edx
c0102dbf:	89 d0                	mov    %edx,%eax
c0102dc1:	89 45 f4             	mov    %eax,-0xc(%ebp)
    bit_map[order][bit_num / 32] ^= (1 << (bit_num % 32));
c0102dc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102dc7:	8d 50 1f             	lea    0x1f(%eax),%edx
c0102dca:	85 c0                	test   %eax,%eax
c0102dcc:	0f 48 c2             	cmovs  %edx,%eax
c0102dcf:	c1 f8 05             	sar    $0x5,%eax
c0102dd2:	8b 55 08             	mov    0x8(%ebp),%edx
c0102dd5:	c1 e2 09             	shl    $0x9,%edx
c0102dd8:	01 c2                	add    %eax,%edx
c0102dda:	8b 1c 95 a0 de 11 c0 	mov    -0x3fee2160(,%edx,4),%ebx
c0102de1:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0102de4:	89 d1                	mov    %edx,%ecx
c0102de6:	c1 f9 1f             	sar    $0x1f,%ecx
c0102de9:	c1 e9 1b             	shr    $0x1b,%ecx
c0102dec:	01 ca                	add    %ecx,%edx
c0102dee:	83 e2 1f             	and    $0x1f,%edx
c0102df1:	29 ca                	sub    %ecx,%edx
c0102df3:	be 01 00 00 00       	mov    $0x1,%esi
c0102df8:	89 d1                	mov    %edx,%ecx
c0102dfa:	d3 e6                	shl    %cl,%esi
c0102dfc:	89 f2                	mov    %esi,%edx
c0102dfe:	31 da                	xor    %ebx,%edx
c0102e00:	8b 4d 08             	mov    0x8(%ebp),%ecx
c0102e03:	c1 e1 09             	shl    $0x9,%ecx
c0102e06:	01 c8                	add    %ecx,%eax
c0102e08:	89 14 85 a0 de 11 c0 	mov    %edx,-0x3fee2160(,%eax,4)
}
c0102e0f:	83 c4 10             	add    $0x10,%esp
c0102e12:	5b                   	pop    %ebx
c0102e13:	5e                   	pop    %esi
c0102e14:	5d                   	pop    %ebp
c0102e15:	c3                   	ret    

c0102e16 <buddy_init_memmap>:

static void
buddy_init_memmap(struct Page *base, size_t n) {
c0102e16:	55                   	push   %ebp
c0102e17:	89 e5                	mov    %esp,%ebp
c0102e19:	53                   	push   %ebx
c0102e1a:	83 ec 54             	sub    $0x54,%esp
    // 这里发现只有一个可用的页框
    cprintf("va: 0x%x, pa: 0x%x, num: %d\n", base, page2pa(base), n);
c0102e1d:	8b 45 08             	mov    0x8(%ebp),%eax
c0102e20:	89 04 24             	mov    %eax,(%esp)
c0102e23:	e8 1a fe ff ff       	call   c0102c42 <page2pa>
c0102e28:	8b 55 0c             	mov    0xc(%ebp),%edx
c0102e2b:	89 54 24 0c          	mov    %edx,0xc(%esp)
c0102e2f:	89 44 24 08          	mov    %eax,0x8(%esp)
c0102e33:	8b 45 08             	mov    0x8(%ebp),%eax
c0102e36:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102e3a:	c7 04 24 85 7a 10 c0 	movl   $0xc0107a85,(%esp)
c0102e41:	e8 0e d5 ff ff       	call   c0100354 <cprintf>
    assert(n > 0);
c0102e46:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0102e4a:	75 24                	jne    c0102e70 <buddy_init_memmap+0x5a>
c0102e4c:	c7 44 24 0c a2 7a 10 	movl   $0xc0107aa2,0xc(%esp)
c0102e53:	c0 
c0102e54:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c0102e5b:	c0 
c0102e5c:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
c0102e63:	00 
c0102e64:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c0102e6b:	e8 6e de ff ff       	call   c0100cde <__panic>
    //设置base_page，用于归零
    base_page = base;
c0102e70:	8b 45 08             	mov    0x8(%ebp),%eax
c0102e73:	a3 80 de 11 c0       	mov    %eax,0xc011de80
    struct Page *p = base;
c0102e78:	8b 45 08             	mov    0x8(%ebp),%eax
c0102e7b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
c0102e7e:	eb 7d                	jmp    c0102efd <buddy_init_memmap+0xe7>
        assert(PageReserved(p));
c0102e80:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102e83:	83 c0 04             	add    $0x4,%eax
c0102e86:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
c0102e8d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0102e90:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0102e93:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0102e96:	0f a3 10             	bt     %edx,(%eax)
c0102e99:	19 c0                	sbb    %eax,%eax
c0102e9b:	89 45 e0             	mov    %eax,-0x20(%ebp)
    return oldbit != 0;
c0102e9e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c0102ea2:	0f 95 c0             	setne  %al
c0102ea5:	0f b6 c0             	movzbl %al,%eax
c0102ea8:	85 c0                	test   %eax,%eax
c0102eaa:	75 24                	jne    c0102ed0 <buddy_init_memmap+0xba>
c0102eac:	c7 44 24 0c d1 7a 10 	movl   $0xc0107ad1,0xc(%esp)
c0102eb3:	c0 
c0102eb4:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c0102ebb:	c0 
c0102ebc:	c7 44 24 04 39 00 00 	movl   $0x39,0x4(%esp)
c0102ec3:	00 
c0102ec4:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c0102ecb:	e8 0e de ff ff       	call   c0100cde <__panic>
        p->flags = p->property = 0;
c0102ed0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102ed3:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
c0102eda:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102edd:	8b 50 08             	mov    0x8(%eax),%edx
c0102ee0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102ee3:	89 50 04             	mov    %edx,0x4(%eax)
        set_page_ref(p, 0);
c0102ee6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0102eed:	00 
c0102eee:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102ef1:	89 04 24             	mov    %eax,(%esp)
c0102ef4:	e8 5f fd ff ff       	call   c0102c58 <set_page_ref>
    cprintf("va: 0x%x, pa: 0x%x, num: %d\n", base, page2pa(base), n);
    assert(n > 0);
    //设置base_page，用于归零
    base_page = base;
    struct Page *p = base;
    for (; p != base + n; p ++) {
c0102ef9:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
c0102efd:	8b 55 0c             	mov    0xc(%ebp),%edx
c0102f00:	89 d0                	mov    %edx,%eax
c0102f02:	c1 e0 02             	shl    $0x2,%eax
c0102f05:	01 d0                	add    %edx,%eax
c0102f07:	c1 e0 02             	shl    $0x2,%eax
c0102f0a:	89 c2                	mov    %eax,%edx
c0102f0c:	8b 45 08             	mov    0x8(%ebp),%eax
c0102f0f:	01 d0                	add    %edx,%eax
c0102f11:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0102f14:	0f 85 66 ff ff ff    	jne    c0102e80 <buddy_init_memmap+0x6a>
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    struct Page *page = base;
c0102f1a:	8b 45 08             	mov    0x8(%ebp),%eax
c0102f1d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    int32_t now_order = MAX_ORDER;
c0102f20:	c7 45 ec 0e 00 00 00 	movl   $0xe,-0x14(%ebp)
    // 由于初始时只映射了4M，这里如果全用了，按照算法实现会返回没有被映射到的页
    // while (now_order <= MAX_ORDER) {
        if (n > (1 << now_order)) {
c0102f27:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0102f2a:	ba 01 00 00 00       	mov    $0x1,%edx
c0102f2f:	89 c1                	mov    %eax,%ecx
c0102f31:	d3 e2                	shl    %cl,%edx
c0102f33:	89 d0                	mov    %edx,%eax
c0102f35:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0102f38:	0f 83 fe 00 00 00    	jae    c010303c <buddy_init_memmap+0x226>
            page->property = (1 << now_order);
c0102f3e:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0102f41:	ba 01 00 00 00       	mov    $0x1,%edx
c0102f46:	89 c1                	mov    %eax,%ecx
c0102f48:	d3 e2                	shl    %cl,%edx
c0102f4a:	89 d0                	mov    %edx,%eax
c0102f4c:	89 c2                	mov    %eax,%edx
c0102f4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0102f51:	89 50 08             	mov    %edx,0x8(%eax)
            SetPageProperty(page);
c0102f54:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0102f57:	83 c0 04             	add    $0x4,%eax
c0102f5a:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
c0102f61:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0102f64:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0102f67:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102f6a:	0f ab 10             	bts    %edx,(%eax)
            nr_free(now_order)  += (1 << now_order);
c0102f6d:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0102f70:	89 d0                	mov    %edx,%eax
c0102f72:	01 c0                	add    %eax,%eax
c0102f74:	01 d0                	add    %edx,%eax
c0102f76:	c1 e0 02             	shl    $0x2,%eax
c0102f79:	05 40 57 12 c0       	add    $0xc0125740,%eax
c0102f7e:	8b 50 08             	mov    0x8(%eax),%edx
c0102f81:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0102f84:	bb 01 00 00 00       	mov    $0x1,%ebx
c0102f89:	89 c1                	mov    %eax,%ecx
c0102f8b:	d3 e3                	shl    %cl,%ebx
c0102f8d:	89 d8                	mov    %ebx,%eax
c0102f8f:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
c0102f92:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0102f95:	89 d0                	mov    %edx,%eax
c0102f97:	01 c0                	add    %eax,%eax
c0102f99:	01 d0                	add    %edx,%eax
c0102f9b:	c1 e0 02             	shl    $0x2,%eax
c0102f9e:	05 40 57 12 c0       	add    $0xc0125740,%eax
c0102fa3:	89 48 08             	mov    %ecx,0x8(%eax)
            list_add(&free_list(now_order), &(page->page_link));
c0102fa6:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0102fa9:	8d 48 0c             	lea    0xc(%eax),%ecx
c0102fac:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0102faf:	89 d0                	mov    %edx,%eax
c0102fb1:	01 c0                	add    %eax,%eax
c0102fb3:	01 d0                	add    %edx,%eax
c0102fb5:	c1 e0 02             	shl    $0x2,%eax
c0102fb8:	05 40 57 12 c0       	add    $0xc0125740,%eax
c0102fbd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
c0102fc0:	89 4d d0             	mov    %ecx,-0x30(%ebp)
c0102fc3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0102fc6:	89 45 cc             	mov    %eax,-0x34(%ebp)
c0102fc9:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102fcc:	89 45 c8             	mov    %eax,-0x38(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
c0102fcf:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0102fd2:	8b 40 04             	mov    0x4(%eax),%eax
c0102fd5:	8b 55 c8             	mov    -0x38(%ebp),%edx
c0102fd8:	89 55 c4             	mov    %edx,-0x3c(%ebp)
c0102fdb:	8b 55 cc             	mov    -0x34(%ebp),%edx
c0102fde:	89 55 c0             	mov    %edx,-0x40(%ebp)
c0102fe1:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c0102fe4:	8b 45 bc             	mov    -0x44(%ebp),%eax
c0102fe7:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c0102fea:	89 10                	mov    %edx,(%eax)
c0102fec:	8b 45 bc             	mov    -0x44(%ebp),%eax
c0102fef:	8b 10                	mov    (%eax),%edx
c0102ff1:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0102ff4:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c0102ff7:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0102ffa:	8b 55 bc             	mov    -0x44(%ebp),%edx
c0102ffd:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0103000:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0103003:	8b 55 c0             	mov    -0x40(%ebp),%edx
c0103006:	89 10                	mov    %edx,(%eax)
            // 这里位图要更新一下
            flip_bit_map(now_order, page);
c0103008:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010300b:	89 44 24 04          	mov    %eax,0x4(%esp)
c010300f:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103012:	89 04 24             	mov    %eax,(%esp)
c0103015:	e8 7d fd ff ff       	call   c0102d97 <flip_bit_map>
            page += (1 << now_order);
c010301a:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010301d:	ba 14 00 00 00       	mov    $0x14,%edx
c0103022:	89 c1                	mov    %eax,%ecx
c0103024:	d3 e2                	shl    %cl,%edx
c0103026:	89 d0                	mov    %edx,%eax
c0103028:	01 45 f0             	add    %eax,-0x10(%ebp)
            n -= (1 << now_order);
c010302b:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010302e:	ba 01 00 00 00       	mov    $0x1,%edx
c0103033:	89 c1                	mov    %eax,%ecx
c0103035:	d3 e2                	shl    %cl,%edx
c0103037:	89 d0                	mov    %edx,%eax
c0103039:	29 45 0c             	sub    %eax,0xc(%ebp)
        }
        now_order += 1;
c010303c:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
    // }
    cprintf("base_page is: %x\n", base_page);
c0103040:	a1 80 de 11 c0       	mov    0xc011de80,%eax
c0103045:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103049:	c7 04 24 e1 7a 10 c0 	movl   $0xc0107ae1,(%esp)
c0103050:	e8 ff d2 ff ff       	call   c0100354 <cprintf>
    print_buddy_sys("init_status");
c0103055:	c7 04 24 f3 7a 10 c0 	movl   $0xc0107af3,(%esp)
c010305c:	e8 04 fc ff ff       	call   c0102c65 <print_buddy_sys>
}
c0103061:	83 c4 54             	add    $0x54,%esp
c0103064:	5b                   	pop    %ebx
c0103065:	5d                   	pop    %ebp
c0103066:	c3                   	ret    

c0103067 <buddy_alloc_pages>:

static struct Page *
buddy_alloc_pages(size_t n) {
c0103067:	55                   	push   %ebp
c0103068:	89 e5                	mov    %esp,%ebp
c010306a:	83 ec 78             	sub    $0x78,%esp
    assert(n > 0);
c010306d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0103071:	75 24                	jne    c0103097 <buddy_alloc_pages+0x30>
c0103073:	c7 44 24 0c a2 7a 10 	movl   $0xc0107aa2,0xc(%esp)
c010307a:	c0 
c010307b:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c0103082:	c0 
c0103083:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
c010308a:	00 
c010308b:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c0103092:	e8 47 dc ff ff       	call   c0100cde <__panic>
    int32_t upper_order = 0;
c0103097:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    //找到刚好大于n，且有空闲页框的阶
    while ((1 << upper_order) < n || nr_free(upper_order) < n) {
c010309e:	eb 04                	jmp    c01030a4 <buddy_alloc_pages+0x3d>
        upper_order += 1;
c01030a0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    int32_t upper_order = 0;
    //找到刚好大于n，且有空闲页框的阶
    while ((1 << upper_order) < n || nr_free(upper_order) < n) {
c01030a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01030a7:	ba 01 00 00 00       	mov    $0x1,%edx
c01030ac:	89 c1                	mov    %eax,%ecx
c01030ae:	d3 e2                	shl    %cl,%edx
c01030b0:	89 d0                	mov    %edx,%eax
c01030b2:	3b 45 08             	cmp    0x8(%ebp),%eax
c01030b5:	72 e9                	jb     c01030a0 <buddy_alloc_pages+0x39>
c01030b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01030ba:	89 d0                	mov    %edx,%eax
c01030bc:	01 c0                	add    %eax,%eax
c01030be:	01 d0                	add    %edx,%eax
c01030c0:	c1 e0 02             	shl    $0x2,%eax
c01030c3:	05 40 57 12 c0       	add    $0xc0125740,%eax
c01030c8:	8b 40 08             	mov    0x8(%eax),%eax
c01030cb:	3b 45 08             	cmp    0x8(%ebp),%eax
c01030ce:	72 d0                	jb     c01030a0 <buddy_alloc_pages+0x39>
        upper_order += 1;
    }
    if (upper_order > MAX_ORDER) {
c01030d0:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
c01030d4:	7e 0a                	jle    c01030e0 <buddy_alloc_pages+0x79>
        return NULL;
c01030d6:	b8 00 00 00 00       	mov    $0x0,%eax
c01030db:	e9 fe 01 00 00       	jmp    c01032de <buddy_alloc_pages+0x277>
    }
    struct Page *page = NULL;
c01030e0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    list_entry_t *le = &free_list(upper_order);
c01030e7:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01030ea:	89 d0                	mov    %edx,%eax
c01030ec:	01 c0                	add    %eax,%eax
c01030ee:	01 d0                	add    %edx,%eax
c01030f0:	c1 e0 02             	shl    $0x2,%eax
c01030f3:	05 40 57 12 c0       	add    $0xc0125740,%eax
c01030f8:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01030fb:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01030fe:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0103101:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0103104:	8b 40 04             	mov    0x4(%eax),%eax
    le = list_next(le);
c0103107:	89 45 e8             	mov    %eax,-0x18(%ebp)
    page = le2page(le, page_link);
c010310a:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010310d:	83 e8 0c             	sub    $0xc,%eax
c0103110:	89 45 f0             	mov    %eax,-0x10(%ebp)
    //把当前这个页摘下来
    // 设置位图
    flip_bit_map(upper_order, page);
c0103113:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103116:	89 44 24 04          	mov    %eax,0x4(%esp)
c010311a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010311d:	89 04 24             	mov    %eax,(%esp)
c0103120:	e8 72 fc ff ff       	call   c0102d97 <flip_bit_map>
    // 把这个页框从链表删除
    list_del(&(page->page_link));
c0103125:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103128:	83 c0 0c             	add    $0xc,%eax
c010312b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c010312e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0103131:	8b 40 04             	mov    0x4(%eax),%eax
c0103134:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0103137:	8b 12                	mov    (%edx),%edx
c0103139:	89 55 d0             	mov    %edx,-0x30(%ebp)
c010313c:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c010313f:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0103142:	8b 55 cc             	mov    -0x34(%ebp),%edx
c0103145:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c0103148:	8b 45 cc             	mov    -0x34(%ebp),%eax
c010314b:	8b 55 d0             	mov    -0x30(%ebp),%edx
c010314e:	89 10                	mov    %edx,(%eax)
    nr_free(upper_order) -= page->property;
c0103150:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0103153:	89 d0                	mov    %edx,%eax
c0103155:	01 c0                	add    %eax,%eax
c0103157:	01 d0                	add    %edx,%eax
c0103159:	c1 e0 02             	shl    $0x2,%eax
c010315c:	05 40 57 12 c0       	add    $0xc0125740,%eax
c0103161:	8b 50 08             	mov    0x8(%eax),%edx
c0103164:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103167:	8b 40 08             	mov    0x8(%eax),%eax
c010316a:	89 d1                	mov    %edx,%ecx
c010316c:	29 c1                	sub    %eax,%ecx
c010316e:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0103171:	89 d0                	mov    %edx,%eax
c0103173:	01 c0                	add    %eax,%eax
c0103175:	01 d0                	add    %edx,%eax
c0103177:	c1 e0 02             	shl    $0x2,%eax
c010317a:	05 40 57 12 c0       	add    $0xc0125740,%eax
c010317f:	89 48 08             	mov    %ecx,0x8(%eax)
    if (page->property >= (n << 1)) {
c0103182:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103185:	8b 40 08             	mov    0x8(%eax),%eax
c0103188:	8b 55 08             	mov    0x8(%ebp),%edx
c010318b:	01 d2                	add    %edx,%edx
c010318d:	39 d0                	cmp    %edx,%eax
c010318f:	0f 82 2d 01 00 00    	jb     c01032c2 <buddy_alloc_pages+0x25b>
        // 如果可以分裂，得一直分裂，分裂结束得条件是当前的页框大小/2<n
        // now_order记录当前分裂的页框的阶
        int32_t now_order = upper_order;
c0103195:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103198:	89 45 ec             	mov    %eax,-0x14(%ebp)
        while ((page->property >> 1) >= n) {
c010319b:	e9 11 01 00 00       	jmp    c01032b1 <buddy_alloc_pages+0x24a>
            int32_t lower_order = now_order - 1;
c01031a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01031a3:	83 e8 01             	sub    $0x1,%eax
c01031a6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            // 把当前页分裂成左右两个
            struct Page *left_sub_page, *right_sub_page;
            left_sub_page = page;
c01031a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01031ac:	89 45 e0             	mov    %eax,-0x20(%ebp)
            right_sub_page = page + page->property / 2;
c01031af:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01031b2:	8b 40 08             	mov    0x8(%eax),%eax
c01031b5:	d1 e8                	shr    %eax
c01031b7:	89 c2                	mov    %eax,%edx
c01031b9:	89 d0                	mov    %edx,%eax
c01031bb:	c1 e0 02             	shl    $0x2,%eax
c01031be:	01 d0                	add    %edx,%eax
c01031c0:	c1 e0 02             	shl    $0x2,%eax
c01031c3:	89 c2                	mov    %eax,%edx
c01031c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01031c8:	01 d0                	add    %edx,%eax
c01031ca:	89 45 dc             	mov    %eax,-0x24(%ebp)
            // 把右边页插入到下一阶的链表中，并设置位图
            SetPageProperty(right_sub_page);
c01031cd:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01031d0:	83 c0 04             	add    $0x4,%eax
c01031d3:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
c01031da:	89 45 c4             	mov    %eax,-0x3c(%ebp)
c01031dd:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c01031e0:	8b 55 c8             	mov    -0x38(%ebp),%edx
c01031e3:	0f ab 10             	bts    %edx,(%eax)
            right_sub_page->property = page->property / 2;
c01031e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01031e9:	8b 40 08             	mov    0x8(%eax),%eax
c01031ec:	d1 e8                	shr    %eax
c01031ee:	89 c2                	mov    %eax,%edx
c01031f0:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01031f3:	89 50 08             	mov    %edx,0x8(%eax)
            list_add(&free_list(lower_order), &right_sub_page->page_link);
c01031f6:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01031f9:	8d 48 0c             	lea    0xc(%eax),%ecx
c01031fc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01031ff:	89 d0                	mov    %edx,%eax
c0103201:	01 c0                	add    %eax,%eax
c0103203:	01 d0                	add    %edx,%eax
c0103205:	c1 e0 02             	shl    $0x2,%eax
c0103208:	05 40 57 12 c0       	add    $0xc0125740,%eax
c010320d:	89 45 c0             	mov    %eax,-0x40(%ebp)
c0103210:	89 4d bc             	mov    %ecx,-0x44(%ebp)
c0103213:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0103216:	89 45 b8             	mov    %eax,-0x48(%ebp)
c0103219:	8b 45 bc             	mov    -0x44(%ebp),%eax
c010321c:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
c010321f:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0103222:	8b 40 04             	mov    0x4(%eax),%eax
c0103225:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0103228:	89 55 b0             	mov    %edx,-0x50(%ebp)
c010322b:	8b 55 b8             	mov    -0x48(%ebp),%edx
c010322e:	89 55 ac             	mov    %edx,-0x54(%ebp)
c0103231:	89 45 a8             	mov    %eax,-0x58(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c0103234:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0103237:	8b 55 b0             	mov    -0x50(%ebp),%edx
c010323a:	89 10                	mov    %edx,(%eax)
c010323c:	8b 45 a8             	mov    -0x58(%ebp),%eax
c010323f:	8b 10                	mov    (%eax),%edx
c0103241:	8b 45 ac             	mov    -0x54(%ebp),%eax
c0103244:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c0103247:	8b 45 b0             	mov    -0x50(%ebp),%eax
c010324a:	8b 55 a8             	mov    -0x58(%ebp),%edx
c010324d:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0103250:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0103253:	8b 55 ac             	mov    -0x54(%ebp),%edx
c0103256:	89 10                	mov    %edx,(%eax)
            nr_free(lower_order) += right_sub_page->property;
c0103258:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c010325b:	89 d0                	mov    %edx,%eax
c010325d:	01 c0                	add    %eax,%eax
c010325f:	01 d0                	add    %edx,%eax
c0103261:	c1 e0 02             	shl    $0x2,%eax
c0103264:	05 40 57 12 c0       	add    $0xc0125740,%eax
c0103269:	8b 50 08             	mov    0x8(%eax),%edx
c010326c:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010326f:	8b 40 08             	mov    0x8(%eax),%eax
c0103272:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
c0103275:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0103278:	89 d0                	mov    %edx,%eax
c010327a:	01 c0                	add    %eax,%eax
c010327c:	01 d0                	add    %edx,%eax
c010327e:	c1 e0 02             	shl    $0x2,%eax
c0103281:	05 40 57 12 c0       	add    $0xc0125740,%eax
c0103286:	89 48 08             	mov    %ecx,0x8(%eax)
            flip_bit_map(lower_order, right_sub_page);
c0103289:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010328c:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103290:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103293:	89 04 24             	mov    %eax,(%esp)
c0103296:	e8 fc fa ff ff       	call   c0102d97 <flip_bit_map>
            // 左边页继续分裂
            now_order -= 1;
c010329b:	83 6d ec 01          	subl   $0x1,-0x14(%ebp)
            left_sub_page->property = right_sub_page->property;
c010329f:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01032a2:	8b 50 08             	mov    0x8(%eax),%edx
c01032a5:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01032a8:	89 50 08             	mov    %edx,0x8(%eax)
            page = left_sub_page;
c01032ab:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01032ae:	89 45 f0             	mov    %eax,-0x10(%ebp)
    nr_free(upper_order) -= page->property;
    if (page->property >= (n << 1)) {
        // 如果可以分裂，得一直分裂，分裂结束得条件是当前的页框大小/2<n
        // now_order记录当前分裂的页框的阶
        int32_t now_order = upper_order;
        while ((page->property >> 1) >= n) {
c01032b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01032b4:	8b 40 08             	mov    0x8(%eax),%eax
c01032b7:	d1 e8                	shr    %eax
c01032b9:	3b 45 08             	cmp    0x8(%ebp),%eax
c01032bc:	0f 83 de fe ff ff    	jae    c01031a0 <buddy_alloc_pages+0x139>
            now_order -= 1;
            left_sub_page->property = right_sub_page->property;
            page = left_sub_page;
        }
    }
    ClearPageProperty(page);
c01032c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01032c5:	83 c0 04             	add    $0x4,%eax
c01032c8:	c7 45 a4 01 00 00 00 	movl   $0x1,-0x5c(%ebp)
c01032cf:	89 45 a0             	mov    %eax,-0x60(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c01032d2:	8b 45 a0             	mov    -0x60(%ebp),%eax
c01032d5:	8b 55 a4             	mov    -0x5c(%ebp),%edx
c01032d8:	0f b3 10             	btr    %edx,(%eax)
    return page;
c01032db:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
c01032de:	c9                   	leave  
c01032df:	c3                   	ret    

c01032e0 <get_buddy>:

static inline struct Page *
get_buddy(struct Page* page, int32_t order) {
c01032e0:	55                   	push   %ebp
c01032e1:	89 e5                	mov    %esp,%ebp
c01032e3:	83 ec 10             	sub    $0x10,%esp
    // 得到当前页的伙伴
    int32_t off = offset(page);
c01032e6:	8b 55 08             	mov    0x8(%ebp),%edx
c01032e9:	a1 80 de 11 c0       	mov    0xc011de80,%eax
c01032ee:	29 c2                	sub    %eax,%edx
c01032f0:	89 d0                	mov    %edx,%eax
c01032f2:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
c01032f7:	f7 e2                	mul    %edx
c01032f9:	89 d0                	mov    %edx,%eax
c01032fb:	c1 e8 04             	shr    $0x4,%eax
c01032fe:	89 45 fc             	mov    %eax,-0x4(%ebp)
    int32_t buddy_off = (off ^ (1 << order));
c0103301:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103304:	ba 01 00 00 00       	mov    $0x1,%edx
c0103309:	89 c1                	mov    %eax,%ecx
c010330b:	d3 e2                	shl    %cl,%edx
c010330d:	89 d0                	mov    %edx,%eax
c010330f:	33 45 fc             	xor    -0x4(%ebp),%eax
c0103312:	89 45 f8             	mov    %eax,-0x8(%ebp)
    return base_page + buddy_off * sizeof(struct Page);
c0103315:	8b 55 f8             	mov    -0x8(%ebp),%edx
c0103318:	89 d0                	mov    %edx,%eax
c010331a:	c1 e0 02             	shl    $0x2,%eax
c010331d:	01 d0                	add    %edx,%eax
c010331f:	c1 e0 02             	shl    $0x2,%eax
c0103322:	89 c2                	mov    %eax,%edx
c0103324:	a1 80 de 11 c0       	mov    0xc011de80,%eax
c0103329:	01 d0                	add    %edx,%eax
}
c010332b:	c9                   	leave  
c010332c:	c3                   	ret    

c010332d <buddy_free_pages>:

static void
buddy_free_pages(struct Page *base, size_t n) {
c010332d:	55                   	push   %ebp
c010332e:	89 e5                	mov    %esp,%ebp
c0103330:	53                   	push   %ebx
c0103331:	83 ec 74             	sub    $0x74,%esp
    // 先检查n的合法性
    assert(n > 0);
c0103334:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0103338:	75 24                	jne    c010335e <buddy_free_pages+0x31>
c010333a:	c7 44 24 0c a2 7a 10 	movl   $0xc0107aa2,0xc(%esp)
c0103341:	c0 
c0103342:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c0103349:	c0 
c010334a:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
c0103351:	00 
c0103352:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c0103359:	e8 80 d9 ff ff       	call   c0100cde <__panic>
    int now_order = 0;
c010335e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while ((1 << now_order) < n) {
c0103365:	eb 04                	jmp    c010336b <buddy_free_pages+0x3e>
        now_order += 1;
c0103367:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
static void
buddy_free_pages(struct Page *base, size_t n) {
    // 先检查n的合法性
    assert(n > 0);
    int now_order = 0;
    while ((1 << now_order) < n) {
c010336b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010336e:	ba 01 00 00 00       	mov    $0x1,%edx
c0103373:	89 c1                	mov    %eax,%ecx
c0103375:	d3 e2                	shl    %cl,%edx
c0103377:	89 d0                	mov    %edx,%eax
c0103379:	3b 45 0c             	cmp    0xc(%ebp),%eax
c010337c:	72 e9                	jb     c0103367 <buddy_free_pages+0x3a>
        now_order += 1;
    }
    n = (1 << now_order);
c010337e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103381:	ba 01 00 00 00       	mov    $0x1,%edx
c0103386:	89 c1                	mov    %eax,%ecx
c0103388:	d3 e2                	shl    %cl,%edx
c010338a:	89 d0                	mov    %edx,%eax
c010338c:	89 45 0c             	mov    %eax,0xc(%ebp)
    assert(now_order <= MAX_ORDER && now_order >= 0);
c010338f:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
c0103393:	7f 06                	jg     c010339b <buddy_free_pages+0x6e>
c0103395:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103399:	79 24                	jns    c01033bf <buddy_free_pages+0x92>
c010339b:	c7 44 24 0c 00 7b 10 	movl   $0xc0107b00,0xc(%esp)
c01033a2:	c0 
c01033a3:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c01033aa:	c0 
c01033ab:	c7 44 24 04 91 00 00 	movl   $0x91,0x4(%esp)
c01033b2:	00 
c01033b3:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c01033ba:	e8 1f d9 ff ff       	call   c0100cde <__panic>
    // 再检查base的合法性
    assert(offset(base) % n == 0);
c01033bf:	8b 55 08             	mov    0x8(%ebp),%edx
c01033c2:	a1 80 de 11 c0       	mov    0xc011de80,%eax
c01033c7:	29 c2                	sub    %eax,%edx
c01033c9:	89 d0                	mov    %edx,%eax
c01033cb:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
c01033d0:	f7 e2                	mul    %edx
c01033d2:	89 d0                	mov    %edx,%eax
c01033d4:	c1 e8 04             	shr    $0x4,%eax
c01033d7:	ba 00 00 00 00       	mov    $0x0,%edx
c01033dc:	f7 75 0c             	divl   0xc(%ebp)
c01033df:	89 d0                	mov    %edx,%eax
c01033e1:	85 c0                	test   %eax,%eax
c01033e3:	74 24                	je     c0103409 <buddy_free_pages+0xdc>
c01033e5:	c7 44 24 0c 29 7b 10 	movl   $0xc0107b29,0xc(%esp)
c01033ec:	c0 
c01033ed:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c01033f4:	c0 
c01033f5:	c7 44 24 04 93 00 00 	movl   $0x93,0x4(%esp)
c01033fc:	00 
c01033fd:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c0103404:	e8 d5 d8 ff ff       	call   c0100cde <__panic>
    struct Page *p = base;
c0103409:	8b 45 08             	mov    0x8(%ebp),%eax
c010340c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    for (; p != base + n; p ++) {
c010340f:	e9 9d 00 00 00       	jmp    c01034b1 <buddy_free_pages+0x184>
        assert(!PageReserved(p) && !PageProperty(p));
c0103414:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103417:	83 c0 04             	add    $0x4,%eax
c010341a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
c0103421:	89 45 e0             	mov    %eax,-0x20(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0103424:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103427:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c010342a:	0f a3 10             	bt     %edx,(%eax)
c010342d:	19 c0                	sbb    %eax,%eax
c010342f:	89 45 dc             	mov    %eax,-0x24(%ebp)
    return oldbit != 0;
c0103432:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0103436:	0f 95 c0             	setne  %al
c0103439:	0f b6 c0             	movzbl %al,%eax
c010343c:	85 c0                	test   %eax,%eax
c010343e:	75 2c                	jne    c010346c <buddy_free_pages+0x13f>
c0103440:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103443:	83 c0 04             	add    $0x4,%eax
c0103446:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
c010344d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0103450:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0103453:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0103456:	0f a3 10             	bt     %edx,(%eax)
c0103459:	19 c0                	sbb    %eax,%eax
c010345b:	89 45 d0             	mov    %eax,-0x30(%ebp)
    return oldbit != 0;
c010345e:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
c0103462:	0f 95 c0             	setne  %al
c0103465:	0f b6 c0             	movzbl %al,%eax
c0103468:	85 c0                	test   %eax,%eax
c010346a:	74 24                	je     c0103490 <buddy_free_pages+0x163>
c010346c:	c7 44 24 0c 40 7b 10 	movl   $0xc0107b40,0xc(%esp)
c0103473:	c0 
c0103474:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c010347b:	c0 
c010347c:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
c0103483:	00 
c0103484:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c010348b:	e8 4e d8 ff ff       	call   c0100cde <__panic>
        p->flags = 0;
c0103490:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103493:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
        set_page_ref(p, 0);
c010349a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c01034a1:	00 
c01034a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01034a5:	89 04 24             	mov    %eax,(%esp)
c01034a8:	e8 ab f7 ff ff       	call   c0102c58 <set_page_ref>
    n = (1 << now_order);
    assert(now_order <= MAX_ORDER && now_order >= 0);
    // 再检查base的合法性
    assert(offset(base) % n == 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
c01034ad:	83 45 f0 14          	addl   $0x14,-0x10(%ebp)
c01034b1:	8b 55 0c             	mov    0xc(%ebp),%edx
c01034b4:	89 d0                	mov    %edx,%eax
c01034b6:	c1 e0 02             	shl    $0x2,%eax
c01034b9:	01 d0                	add    %edx,%eax
c01034bb:	c1 e0 02             	shl    $0x2,%eax
c01034be:	89 c2                	mov    %eax,%edx
c01034c0:	8b 45 08             	mov    0x8(%ebp),%eax
c01034c3:	01 d0                	add    %edx,%eax
c01034c5:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c01034c8:	0f 85 46 ff ff ff    	jne    c0103414 <buddy_free_pages+0xe7>
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
c01034ce:	8b 45 08             	mov    0x8(%ebp),%eax
c01034d1:	8b 55 0c             	mov    0xc(%ebp),%edx
c01034d4:	89 50 08             	mov    %edx,0x8(%eax)
    // 开始尝试合并页框
    flip_bit_map(now_order, base);
c01034d7:	8b 45 08             	mov    0x8(%ebp),%eax
c01034da:	89 44 24 04          	mov    %eax,0x4(%esp)
c01034de:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01034e1:	89 04 24             	mov    %eax,(%esp)
c01034e4:	e8 ae f8 ff ff       	call   c0102d97 <flip_bit_map>
    intptr_t bit_num = (offset(base) >> (now_order + 1));
c01034e9:	8b 55 08             	mov    0x8(%ebp),%edx
c01034ec:	a1 80 de 11 c0       	mov    0xc011de80,%eax
c01034f1:	29 c2                	sub    %eax,%edx
c01034f3:	89 d0                	mov    %edx,%eax
c01034f5:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
c01034fa:	f7 e2                	mul    %edx
c01034fc:	c1 ea 04             	shr    $0x4,%edx
c01034ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103502:	83 c0 01             	add    $0x1,%eax
c0103505:	89 c1                	mov    %eax,%ecx
c0103507:	d3 ea                	shr    %cl,%edx
c0103509:	89 d0                	mov    %edx,%eax
c010350b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    while (now_order < MAX_ORDER && (bit_map[now_order][bit_num / 32] & (1 << (bit_num % 32))) == 0) {
c010350e:	e9 e3 00 00 00       	jmp    c01035f6 <buddy_free_pages+0x2c9>
        // 得到当前插入页框的buddy
        struct Page *now_buddy = get_buddy(base, now_order);
c0103513:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103516:	89 44 24 04          	mov    %eax,0x4(%esp)
c010351a:	8b 45 08             	mov    0x8(%ebp),%eax
c010351d:	89 04 24             	mov    %eax,(%esp)
c0103520:	e8 bb fd ff ff       	call   c01032e0 <get_buddy>
c0103525:	89 45 e8             	mov    %eax,-0x18(%ebp)
        list_del(&now_buddy->page_link);
c0103528:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010352b:	83 c0 0c             	add    $0xc,%eax
c010352e:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c0103531:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0103534:	8b 40 04             	mov    0x4(%eax),%eax
c0103537:	8b 55 cc             	mov    -0x34(%ebp),%edx
c010353a:	8b 12                	mov    (%edx),%edx
c010353c:	89 55 c8             	mov    %edx,-0x38(%ebp)
c010353f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c0103542:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0103545:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c0103548:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c010354b:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c010354e:	8b 55 c8             	mov    -0x38(%ebp),%edx
c0103551:	89 10                	mov    %edx,(%eax)
        ClearPageProperty(now_buddy);
c0103553:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103556:	83 c0 04             	add    $0x4,%eax
c0103559:	c7 45 c0 01 00 00 00 	movl   $0x1,-0x40(%ebp)
c0103560:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0103563:	8b 45 bc             	mov    -0x44(%ebp),%eax
c0103566:	8b 55 c0             	mov    -0x40(%ebp),%edx
c0103569:	0f b3 10             	btr    %edx,(%eax)
        nr_free(now_order) -= now_buddy->property;
c010356c:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010356f:	89 d0                	mov    %edx,%eax
c0103571:	01 c0                	add    %eax,%eax
c0103573:	01 d0                	add    %edx,%eax
c0103575:	c1 e0 02             	shl    $0x2,%eax
c0103578:	05 40 57 12 c0       	add    $0xc0125740,%eax
c010357d:	8b 50 08             	mov    0x8(%eax),%edx
c0103580:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103583:	8b 40 08             	mov    0x8(%eax),%eax
c0103586:	89 d1                	mov    %edx,%ecx
c0103588:	29 c1                	sub    %eax,%ecx
c010358a:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010358d:	89 d0                	mov    %edx,%eax
c010358f:	01 c0                	add    %eax,%eax
c0103591:	01 d0                	add    %edx,%eax
c0103593:	c1 e0 02             	shl    $0x2,%eax
c0103596:	05 40 57 12 c0       	add    $0xc0125740,%eax
c010359b:	89 48 08             	mov    %ecx,0x8(%eax)
        if (now_buddy < base) {
c010359e:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01035a1:	3b 45 08             	cmp    0x8(%ebp),%eax
c01035a4:	73 06                	jae    c01035ac <buddy_free_pages+0x27f>
            base = now_buddy;
c01035a6:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01035a9:	89 45 08             	mov    %eax,0x8(%ebp)
        }
        base->property <<= 1;
c01035ac:	8b 45 08             	mov    0x8(%ebp),%eax
c01035af:	8b 40 08             	mov    0x8(%eax),%eax
c01035b2:	8d 14 00             	lea    (%eax,%eax,1),%edx
c01035b5:	8b 45 08             	mov    0x8(%ebp),%eax
c01035b8:	89 50 08             	mov    %edx,0x8(%eax)
        now_order += 1;
c01035bb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
        flip_bit_map(now_order, base);
c01035bf:	8b 45 08             	mov    0x8(%ebp),%eax
c01035c2:	89 44 24 04          	mov    %eax,0x4(%esp)
c01035c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01035c9:	89 04 24             	mov    %eax,(%esp)
c01035cc:	e8 c6 f7 ff ff       	call   c0102d97 <flip_bit_map>
        bit_num = (offset(base) >> (now_order + 1));
c01035d1:	8b 55 08             	mov    0x8(%ebp),%edx
c01035d4:	a1 80 de 11 c0       	mov    0xc011de80,%eax
c01035d9:	29 c2                	sub    %eax,%edx
c01035db:	89 d0                	mov    %edx,%eax
c01035dd:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
c01035e2:	f7 e2                	mul    %edx
c01035e4:	c1 ea 04             	shr    $0x4,%edx
c01035e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01035ea:	83 c0 01             	add    $0x1,%eax
c01035ed:	89 c1                	mov    %eax,%ecx
c01035ef:	d3 ea                	shr    %cl,%edx
c01035f1:	89 d0                	mov    %edx,%eax
c01035f3:	89 45 ec             	mov    %eax,-0x14(%ebp)
    }
    base->property = n;
    // 开始尝试合并页框
    flip_bit_map(now_order, base);
    intptr_t bit_num = (offset(base) >> (now_order + 1));
    while (now_order < MAX_ORDER && (bit_map[now_order][bit_num / 32] & (1 << (bit_num % 32))) == 0) {
c01035f6:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
c01035fa:	7f 3c                	jg     c0103638 <buddy_free_pages+0x30b>
c01035fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01035ff:	8d 50 1f             	lea    0x1f(%eax),%edx
c0103602:	85 c0                	test   %eax,%eax
c0103604:	0f 48 c2             	cmovs  %edx,%eax
c0103607:	c1 f8 05             	sar    $0x5,%eax
c010360a:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010360d:	c1 e2 09             	shl    $0x9,%edx
c0103610:	01 d0                	add    %edx,%eax
c0103612:	8b 1c 85 a0 de 11 c0 	mov    -0x3fee2160(,%eax,4),%ebx
c0103619:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010361c:	99                   	cltd   
c010361d:	c1 ea 1b             	shr    $0x1b,%edx
c0103620:	01 d0                	add    %edx,%eax
c0103622:	83 e0 1f             	and    $0x1f,%eax
c0103625:	29 d0                	sub    %edx,%eax
c0103627:	89 c1                	mov    %eax,%ecx
c0103629:	d3 fb                	sar    %cl,%ebx
c010362b:	89 d8                	mov    %ebx,%eax
c010362d:	83 e0 01             	and    $0x1,%eax
c0103630:	85 c0                	test   %eax,%eax
c0103632:	0f 84 db fe ff ff    	je     c0103513 <buddy_free_pages+0x1e6>
        base->property <<= 1;
        now_order += 1;
        flip_bit_map(now_order, base);
        bit_num = (offset(base) >> (now_order + 1));
    }
    SetPageProperty(base);
c0103638:	8b 45 08             	mov    0x8(%ebp),%eax
c010363b:	83 c0 04             	add    $0x4,%eax
c010363e:	c7 45 b8 01 00 00 00 	movl   $0x1,-0x48(%ebp)
c0103645:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0103648:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c010364b:	8b 55 b8             	mov    -0x48(%ebp),%edx
c010364e:	0f ab 10             	bts    %edx,(%eax)
    nr_free(now_order) += base->property;
c0103651:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0103654:	89 d0                	mov    %edx,%eax
c0103656:	01 c0                	add    %eax,%eax
c0103658:	01 d0                	add    %edx,%eax
c010365a:	c1 e0 02             	shl    $0x2,%eax
c010365d:	05 40 57 12 c0       	add    $0xc0125740,%eax
c0103662:	8b 50 08             	mov    0x8(%eax),%edx
c0103665:	8b 45 08             	mov    0x8(%ebp),%eax
c0103668:	8b 40 08             	mov    0x8(%eax),%eax
c010366b:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
c010366e:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0103671:	89 d0                	mov    %edx,%eax
c0103673:	01 c0                	add    %eax,%eax
c0103675:	01 d0                	add    %edx,%eax
c0103677:	c1 e0 02             	shl    $0x2,%eax
c010367a:	05 40 57 12 c0       	add    $0xc0125740,%eax
c010367f:	89 48 08             	mov    %ecx,0x8(%eax)
    list_add(&free_list(now_order), &base->page_link);
c0103682:	8b 45 08             	mov    0x8(%ebp),%eax
c0103685:	8d 48 0c             	lea    0xc(%eax),%ecx
c0103688:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010368b:	89 d0                	mov    %edx,%eax
c010368d:	01 c0                	add    %eax,%eax
c010368f:	01 d0                	add    %edx,%eax
c0103691:	c1 e0 02             	shl    $0x2,%eax
c0103694:	05 40 57 12 c0       	add    $0xc0125740,%eax
c0103699:	89 45 b0             	mov    %eax,-0x50(%ebp)
c010369c:	89 4d ac             	mov    %ecx,-0x54(%ebp)
c010369f:	8b 45 b0             	mov    -0x50(%ebp),%eax
c01036a2:	89 45 a8             	mov    %eax,-0x58(%ebp)
c01036a5:	8b 45 ac             	mov    -0x54(%ebp),%eax
c01036a8:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
c01036ab:	8b 45 a8             	mov    -0x58(%ebp),%eax
c01036ae:	8b 40 04             	mov    0x4(%eax),%eax
c01036b1:	8b 55 a4             	mov    -0x5c(%ebp),%edx
c01036b4:	89 55 a0             	mov    %edx,-0x60(%ebp)
c01036b7:	8b 55 a8             	mov    -0x58(%ebp),%edx
c01036ba:	89 55 9c             	mov    %edx,-0x64(%ebp)
c01036bd:	89 45 98             	mov    %eax,-0x68(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c01036c0:	8b 45 98             	mov    -0x68(%ebp),%eax
c01036c3:	8b 55 a0             	mov    -0x60(%ebp),%edx
c01036c6:	89 10                	mov    %edx,(%eax)
c01036c8:	8b 45 98             	mov    -0x68(%ebp),%eax
c01036cb:	8b 10                	mov    (%eax),%edx
c01036cd:	8b 45 9c             	mov    -0x64(%ebp),%eax
c01036d0:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c01036d3:	8b 45 a0             	mov    -0x60(%ebp),%eax
c01036d6:	8b 55 98             	mov    -0x68(%ebp),%edx
c01036d9:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c01036dc:	8b 45 a0             	mov    -0x60(%ebp),%eax
c01036df:	8b 55 9c             	mov    -0x64(%ebp),%edx
c01036e2:	89 10                	mov    %edx,(%eax)
}
c01036e4:	83 c4 74             	add    $0x74,%esp
c01036e7:	5b                   	pop    %ebx
c01036e8:	5d                   	pop    %ebp
c01036e9:	c3                   	ret    

c01036ea <buddy_nr_free_pages>:

static size_t
buddy_nr_free_pages(void) {
c01036ea:	55                   	push   %ebp
c01036eb:	89 e5                	mov    %esp,%ebp
c01036ed:	83 ec 10             	sub    $0x10,%esp
    size_t total_nr_free = 0;
c01036f0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
c01036f7:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
c01036fe:	eb 1b                	jmp    c010371b <buddy_nr_free_pages+0x31>
        total_nr_free += nr_free(i);
c0103700:	8b 55 f8             	mov    -0x8(%ebp),%edx
c0103703:	89 d0                	mov    %edx,%eax
c0103705:	01 c0                	add    %eax,%eax
c0103707:	01 d0                	add    %edx,%eax
c0103709:	c1 e0 02             	shl    $0x2,%eax
c010370c:	05 40 57 12 c0       	add    $0xc0125740,%eax
c0103711:	8b 40 08             	mov    0x8(%eax),%eax
c0103714:	01 45 fc             	add    %eax,-0x4(%ebp)

static size_t
buddy_nr_free_pages(void) {
    size_t total_nr_free = 0;
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
c0103717:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
c010371b:	83 7d f8 0e          	cmpl   $0xe,-0x8(%ebp)
c010371f:	7e df                	jle    c0103700 <buddy_nr_free_pages+0x16>
        total_nr_free += nr_free(i);
    }
    return total_nr_free;
c0103721:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0103724:	c9                   	leave  
c0103725:	c3                   	ret    

c0103726 <buddy_check>:

static void
buddy_check(void) {
c0103726:	55                   	push   %ebp
c0103727:	89 e5                	mov    %esp,%ebp
c0103729:	83 ec 28             	sub    $0x28,%esp
    struct Page *p0, *p1, *p2;
    cprintf("\ntest_stage 1\n");
c010372c:	c7 04 24 65 7b 10 c0 	movl   $0xc0107b65,(%esp)
c0103733:	e8 1c cc ff ff       	call   c0100354 <cprintf>
    p0 = buddy_alloc_pages(1);
c0103738:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010373f:	e8 23 f9 ff ff       	call   c0103067 <buddy_alloc_pages>
c0103744:	89 45 f0             	mov    %eax,-0x10(%ebp)
    print_buddy_sys("alloc p0, size 1");
c0103747:	c7 04 24 74 7b 10 c0 	movl   $0xc0107b74,(%esp)
c010374e:	e8 12 f5 ff ff       	call   c0102c65 <print_buddy_sys>
    buddy_free_pages(p0, 1);
c0103753:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c010375a:	00 
c010375b:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010375e:	89 04 24             	mov    %eax,(%esp)
c0103761:	e8 c7 fb ff ff       	call   c010332d <buddy_free_pages>
    print_buddy_sys("free p0");
c0103766:	c7 04 24 85 7b 10 c0 	movl   $0xc0107b85,(%esp)
c010376d:	e8 f3 f4 ff ff       	call   c0102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER));
c0103772:	e8 73 ff ff ff       	call   c01036ea <buddy_nr_free_pages>
c0103777:	3d 00 40 00 00       	cmp    $0x4000,%eax
c010377c:	74 24                	je     c01037a2 <buddy_check+0x7c>
c010377e:	c7 44 24 0c 90 7b 10 	movl   $0xc0107b90,0xc(%esp)
c0103785:	c0 
c0103786:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c010378d:	c0 
c010378e:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
c0103795:	00 
c0103796:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c010379d:	e8 3c d5 ff ff       	call   c0100cde <__panic>

    cprintf("\ntest_stage 2\n");
c01037a2:	c7 04 24 ba 7b 10 c0 	movl   $0xc0107bba,(%esp)
c01037a9:	e8 a6 cb ff ff       	call   c0100354 <cprintf>
    p0 = buddy_alloc_pages(7);
c01037ae:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
c01037b5:	e8 ad f8 ff ff       	call   c0103067 <buddy_alloc_pages>
c01037ba:	89 45 f0             	mov    %eax,-0x10(%ebp)
    print_buddy_sys("alloc p0, size 7");
c01037bd:	c7 04 24 c9 7b 10 c0 	movl   $0xc0107bc9,(%esp)
c01037c4:	e8 9c f4 ff ff       	call   c0102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 8);
c01037c9:	e8 1c ff ff ff       	call   c01036ea <buddy_nr_free_pages>
c01037ce:	3d f8 3f 00 00       	cmp    $0x3ff8,%eax
c01037d3:	74 24                	je     c01037f9 <buddy_check+0xd3>
c01037d5:	c7 44 24 0c dc 7b 10 	movl   $0xc0107bdc,0xc(%esp)
c01037dc:	c0 
c01037dd:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c01037e4:	c0 
c01037e5:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
c01037ec:	00 
c01037ed:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c01037f4:	e8 e5 d4 ff ff       	call   c0100cde <__panic>
    p1 = buddy_alloc_pages(15);
c01037f9:	c7 04 24 0f 00 00 00 	movl   $0xf,(%esp)
c0103800:	e8 62 f8 ff ff       	call   c0103067 <buddy_alloc_pages>
c0103805:	89 45 ec             	mov    %eax,-0x14(%ebp)
    print_buddy_sys("alloc p1, size 15");
c0103808:	c7 04 24 0a 7c 10 c0 	movl   $0xc0107c0a,(%esp)
c010380f:	e8 51 f4 ff ff       	call   c0102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 24);
c0103814:	e8 d1 fe ff ff       	call   c01036ea <buddy_nr_free_pages>
c0103819:	3d e8 3f 00 00       	cmp    $0x3fe8,%eax
c010381e:	74 24                	je     c0103844 <buddy_check+0x11e>
c0103820:	c7 44 24 0c 1c 7c 10 	movl   $0xc0107c1c,0xc(%esp)
c0103827:	c0 
c0103828:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c010382f:	c0 
c0103830:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
c0103837:	00 
c0103838:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c010383f:	e8 9a d4 ff ff       	call   c0100cde <__panic>
    p2 = buddy_alloc_pages(1);
c0103844:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010384b:	e8 17 f8 ff ff       	call   c0103067 <buddy_alloc_pages>
c0103850:	89 45 e8             	mov    %eax,-0x18(%ebp)
    print_buddy_sys("alloc p2, size 1");
c0103853:	c7 04 24 4b 7c 10 c0 	movl   $0xc0107c4b,(%esp)
c010385a:	e8 06 f4 ff ff       	call   c0102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 25);
c010385f:	e8 86 fe ff ff       	call   c01036ea <buddy_nr_free_pages>
c0103864:	3d e7 3f 00 00       	cmp    $0x3fe7,%eax
c0103869:	74 24                	je     c010388f <buddy_check+0x169>
c010386b:	c7 44 24 0c 5c 7c 10 	movl   $0xc0107c5c,0xc(%esp)
c0103872:	c0 
c0103873:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c010387a:	c0 
c010387b:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
c0103882:	00 
c0103883:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c010388a:	e8 4f d4 ff ff       	call   c0100cde <__panic>
    buddy_free_pages(p0, 7);
c010388f:	c7 44 24 04 07 00 00 	movl   $0x7,0x4(%esp)
c0103896:	00 
c0103897:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010389a:	89 04 24             	mov    %eax,(%esp)
c010389d:	e8 8b fa ff ff       	call   c010332d <buddy_free_pages>
    print_buddy_sys("free p0");
c01038a2:	c7 04 24 85 7b 10 c0 	movl   $0xc0107b85,(%esp)
c01038a9:	e8 b7 f3 ff ff       	call   c0102c65 <print_buddy_sys>
    buddy_free_pages(p1, 15);
c01038ae:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
c01038b5:	00 
c01038b6:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01038b9:	89 04 24             	mov    %eax,(%esp)
c01038bc:	e8 6c fa ff ff       	call   c010332d <buddy_free_pages>
    print_buddy_sys("free p1");
c01038c1:	c7 04 24 8b 7c 10 c0 	movl   $0xc0107c8b,(%esp)
c01038c8:	e8 98 f3 ff ff       	call   c0102c65 <print_buddy_sys>
    buddy_free_pages(p2, 1);
c01038cd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c01038d4:	00 
c01038d5:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01038d8:	89 04 24             	mov    %eax,(%esp)
c01038db:	e8 4d fa ff ff       	call   c010332d <buddy_free_pages>
    print_buddy_sys("free p2");
c01038e0:	c7 04 24 93 7c 10 c0 	movl   $0xc0107c93,(%esp)
c01038e7:	e8 79 f3 ff ff       	call   c0102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER));
c01038ec:	e8 f9 fd ff ff       	call   c01036ea <buddy_nr_free_pages>
c01038f1:	3d 00 40 00 00       	cmp    $0x4000,%eax
c01038f6:	74 24                	je     c010391c <buddy_check+0x1f6>
c01038f8:	c7 44 24 0c 90 7b 10 	movl   $0xc0107b90,0xc(%esp)
c01038ff:	c0 
c0103900:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c0103907:	c0 
c0103908:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
c010390f:	00 
c0103910:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c0103917:	e8 c2 d3 ff ff       	call   c0100cde <__panic>

    cprintf("\ntest_stage 3\n");
c010391c:	c7 04 24 9b 7c 10 c0 	movl   $0xc0107c9b,(%esp)
c0103923:	e8 2c ca ff ff       	call   c0100354 <cprintf>
    p0 = buddy_alloc_pages(257);
c0103928:	c7 04 24 01 01 00 00 	movl   $0x101,(%esp)
c010392f:	e8 33 f7 ff ff       	call   c0103067 <buddy_alloc_pages>
c0103934:	89 45 f0             	mov    %eax,-0x10(%ebp)
    print_buddy_sys("alloc p0, size 257");
c0103937:	c7 04 24 aa 7c 10 c0 	movl   $0xc0107caa,(%esp)
c010393e:	e8 22 f3 ff ff       	call   c0102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 512);
c0103943:	e8 a2 fd ff ff       	call   c01036ea <buddy_nr_free_pages>
c0103948:	3d 00 3e 00 00       	cmp    $0x3e00,%eax
c010394d:	74 24                	je     c0103973 <buddy_check+0x24d>
c010394f:	c7 44 24 0c c0 7c 10 	movl   $0xc0107cc0,0xc(%esp)
c0103956:	c0 
c0103957:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c010395e:	c0 
c010395f:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
c0103966:	00 
c0103967:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c010396e:	e8 6b d3 ff ff       	call   c0100cde <__panic>
    p1 = buddy_alloc_pages(257);
c0103973:	c7 04 24 01 01 00 00 	movl   $0x101,(%esp)
c010397a:	e8 e8 f6 ff ff       	call   c0103067 <buddy_alloc_pages>
c010397f:	89 45 ec             	mov    %eax,-0x14(%ebp)
    print_buddy_sys("alloc p1, size 257");
c0103982:	c7 04 24 f0 7c 10 c0 	movl   $0xc0107cf0,(%esp)
c0103989:	e8 d7 f2 ff ff       	call   c0102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 1024);
c010398e:	e8 57 fd ff ff       	call   c01036ea <buddy_nr_free_pages>
c0103993:	3d 00 3c 00 00       	cmp    $0x3c00,%eax
c0103998:	74 24                	je     c01039be <buddy_check+0x298>
c010399a:	c7 44 24 0c 04 7d 10 	movl   $0xc0107d04,0xc(%esp)
c01039a1:	c0 
c01039a2:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c01039a9:	c0 
c01039aa:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
c01039b1:	00 
c01039b2:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c01039b9:	e8 20 d3 ff ff       	call   c0100cde <__panic>
    p2 = buddy_alloc_pages(257);
c01039be:	c7 04 24 01 01 00 00 	movl   $0x101,(%esp)
c01039c5:	e8 9d f6 ff ff       	call   c0103067 <buddy_alloc_pages>
c01039ca:	89 45 e8             	mov    %eax,-0x18(%ebp)
    print_buddy_sys("alloc p2, size 257");
c01039cd:	c7 04 24 35 7d 10 c0 	movl   $0xc0107d35,(%esp)
c01039d4:	e8 8c f2 ff ff       	call   c0102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 1536);
c01039d9:	e8 0c fd ff ff       	call   c01036ea <buddy_nr_free_pages>
c01039de:	3d 00 3a 00 00       	cmp    $0x3a00,%eax
c01039e3:	74 24                	je     c0103a09 <buddy_check+0x2e3>
c01039e5:	c7 44 24 0c 48 7d 10 	movl   $0xc0107d48,0xc(%esp)
c01039ec:	c0 
c01039ed:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c01039f4:	c0 
c01039f5:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
c01039fc:	00 
c01039fd:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c0103a04:	e8 d5 d2 ff ff       	call   c0100cde <__panic>
    buddy_free_pages(p0, 257);
c0103a09:	c7 44 24 04 01 01 00 	movl   $0x101,0x4(%esp)
c0103a10:	00 
c0103a11:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103a14:	89 04 24             	mov    %eax,(%esp)
c0103a17:	e8 11 f9 ff ff       	call   c010332d <buddy_free_pages>
    print_buddy_sys("free p0");
c0103a1c:	c7 04 24 85 7b 10 c0 	movl   $0xc0107b85,(%esp)
c0103a23:	e8 3d f2 ff ff       	call   c0102c65 <print_buddy_sys>
    buddy_free_pages(p1, 257);
c0103a28:	c7 44 24 04 01 01 00 	movl   $0x101,0x4(%esp)
c0103a2f:	00 
c0103a30:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103a33:	89 04 24             	mov    %eax,(%esp)
c0103a36:	e8 f2 f8 ff ff       	call   c010332d <buddy_free_pages>
    print_buddy_sys("free p1");
c0103a3b:	c7 04 24 8b 7c 10 c0 	movl   $0xc0107c8b,(%esp)
c0103a42:	e8 1e f2 ff ff       	call   c0102c65 <print_buddy_sys>
    buddy_free_pages(p2, 257);
c0103a47:	c7 44 24 04 01 01 00 	movl   $0x101,0x4(%esp)
c0103a4e:	00 
c0103a4f:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103a52:	89 04 24             	mov    %eax,(%esp)
c0103a55:	e8 d3 f8 ff ff       	call   c010332d <buddy_free_pages>
    print_buddy_sys("free p2");
c0103a5a:	c7 04 24 93 7c 10 c0 	movl   $0xc0107c93,(%esp)
c0103a61:	e8 ff f1 ff ff       	call   c0102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER));
c0103a66:	e8 7f fc ff ff       	call   c01036ea <buddy_nr_free_pages>
c0103a6b:	3d 00 40 00 00       	cmp    $0x4000,%eax
c0103a70:	74 24                	je     c0103a96 <buddy_check+0x370>
c0103a72:	c7 44 24 0c 90 7b 10 	movl   $0xc0107b90,0xc(%esp)
c0103a79:	c0 
c0103a7a:	c7 44 24 08 a8 7a 10 	movl   $0xc0107aa8,0x8(%esp)
c0103a81:	c0 
c0103a82:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
c0103a89:	00 
c0103a8a:	c7 04 24 bd 7a 10 c0 	movl   $0xc0107abd,(%esp)
c0103a91:	e8 48 d2 ff ff       	call   c0100cde <__panic>

    cprintf("\ntest_stage 4\n");
c0103a96:	c7 04 24 79 7d 10 c0 	movl   $0xc0107d79,(%esp)
c0103a9d:	e8 b2 c8 ff ff       	call   c0100354 <cprintf>
    p0 = buddy_alloc_pages(8);
c0103aa2:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
c0103aa9:	e8 b9 f5 ff ff       	call   c0103067 <buddy_alloc_pages>
c0103aae:	89 45 f0             	mov    %eax,-0x10(%ebp)
    print_buddy_sys("alloc p0, size 8");
c0103ab1:	c7 04 24 88 7d 10 c0 	movl   $0xc0107d88,(%esp)
c0103ab8:	e8 a8 f1 ff ff       	call   c0102c65 <print_buddy_sys>
    int32_t i;
    for (i = 0; i < 8; i += 2) {
c0103abd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0103ac4:	eb 34                	jmp    c0103afa <buddy_check+0x3d4>
        buddy_free_pages(p0 + i, 1);
c0103ac6:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0103ac9:	89 d0                	mov    %edx,%eax
c0103acb:	c1 e0 02             	shl    $0x2,%eax
c0103ace:	01 d0                	add    %edx,%eax
c0103ad0:	c1 e0 02             	shl    $0x2,%eax
c0103ad3:	89 c2                	mov    %eax,%edx
c0103ad5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103ad8:	01 d0                	add    %edx,%eax
c0103ada:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0103ae1:	00 
c0103ae2:	89 04 24             	mov    %eax,(%esp)
c0103ae5:	e8 43 f8 ff ff       	call   c010332d <buddy_free_pages>
        print_buddy_sys("free p0 + i, size 1");
c0103aea:	c7 04 24 99 7d 10 c0 	movl   $0xc0107d99,(%esp)
c0103af1:	e8 6f f1 ff ff       	call   c0102c65 <print_buddy_sys>

    cprintf("\ntest_stage 4\n");
    p0 = buddy_alloc_pages(8);
    print_buddy_sys("alloc p0, size 8");
    int32_t i;
    for (i = 0; i < 8; i += 2) {
c0103af6:	83 45 f4 02          	addl   $0x2,-0xc(%ebp)
c0103afa:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
c0103afe:	7e c6                	jle    c0103ac6 <buddy_check+0x3a0>
        buddy_free_pages(p0 + i, 1);
        print_buddy_sys("free p0 + i, size 1");
    }
    for (i = 1; i < 8; i += 2) {
c0103b00:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
c0103b07:	eb 34                	jmp    c0103b3d <buddy_check+0x417>
        buddy_free_pages(p0 + i, 1);
c0103b09:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0103b0c:	89 d0                	mov    %edx,%eax
c0103b0e:	c1 e0 02             	shl    $0x2,%eax
c0103b11:	01 d0                	add    %edx,%eax
c0103b13:	c1 e0 02             	shl    $0x2,%eax
c0103b16:	89 c2                	mov    %eax,%edx
c0103b18:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103b1b:	01 d0                	add    %edx,%eax
c0103b1d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0103b24:	00 
c0103b25:	89 04 24             	mov    %eax,(%esp)
c0103b28:	e8 00 f8 ff ff       	call   c010332d <buddy_free_pages>
        print_buddy_sys("free p0 + i, size 1");
c0103b2d:	c7 04 24 99 7d 10 c0 	movl   $0xc0107d99,(%esp)
c0103b34:	e8 2c f1 ff ff       	call   c0102c65 <print_buddy_sys>
    int32_t i;
    for (i = 0; i < 8; i += 2) {
        buddy_free_pages(p0 + i, 1);
        print_buddy_sys("free p0 + i, size 1");
    }
    for (i = 1; i < 8; i += 2) {
c0103b39:	83 45 f4 02          	addl   $0x2,-0xc(%ebp)
c0103b3d:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
c0103b41:	7e c6                	jle    c0103b09 <buddy_check+0x3e3>
        buddy_free_pages(p0 + i, 1);
        print_buddy_sys("free p0 + i, size 1");
    }
}
c0103b43:	c9                   	leave  
c0103b44:	c3                   	ret    

c0103b45 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
c0103b45:	55                   	push   %ebp
c0103b46:	89 e5                	mov    %esp,%ebp
    return page - pages;
c0103b48:	8b 55 08             	mov    0x8(%ebp),%edx
c0103b4b:	a1 fc 57 12 c0       	mov    0xc01257fc,%eax
c0103b50:	29 c2                	sub    %eax,%edx
c0103b52:	89 d0                	mov    %edx,%eax
c0103b54:	c1 f8 02             	sar    $0x2,%eax
c0103b57:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
c0103b5d:	5d                   	pop    %ebp
c0103b5e:	c3                   	ret    

c0103b5f <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
c0103b5f:	55                   	push   %ebp
c0103b60:	89 e5                	mov    %esp,%ebp
c0103b62:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
c0103b65:	8b 45 08             	mov    0x8(%ebp),%eax
c0103b68:	89 04 24             	mov    %eax,(%esp)
c0103b6b:	e8 d5 ff ff ff       	call   c0103b45 <page2ppn>
c0103b70:	c1 e0 0c             	shl    $0xc,%eax
}
c0103b73:	c9                   	leave  
c0103b74:	c3                   	ret    

c0103b75 <page_ref>:
pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
}

static inline int
page_ref(struct Page *page) {
c0103b75:	55                   	push   %ebp
c0103b76:	89 e5                	mov    %esp,%ebp
    return page->ref;
c0103b78:	8b 45 08             	mov    0x8(%ebp),%eax
c0103b7b:	8b 00                	mov    (%eax),%eax
}
c0103b7d:	5d                   	pop    %ebp
c0103b7e:	c3                   	ret    

c0103b7f <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
c0103b7f:	55                   	push   %ebp
c0103b80:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c0103b82:	8b 45 08             	mov    0x8(%ebp),%eax
c0103b85:	8b 55 0c             	mov    0xc(%ebp),%edx
c0103b88:	89 10                	mov    %edx,(%eax)
}
c0103b8a:	5d                   	pop    %ebp
c0103b8b:	c3                   	ret    

c0103b8c <default_init>:

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
c0103b8c:	55                   	push   %ebp
c0103b8d:	89 e5                	mov    %esp,%ebp
c0103b8f:	83 ec 10             	sub    $0x10,%esp
c0103b92:	c7 45 fc 40 57 12 c0 	movl   $0xc0125740,-0x4(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c0103b99:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103b9c:	8b 55 fc             	mov    -0x4(%ebp),%edx
c0103b9f:	89 50 04             	mov    %edx,0x4(%eax)
c0103ba2:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103ba5:	8b 50 04             	mov    0x4(%eax),%edx
c0103ba8:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103bab:	89 10                	mov    %edx,(%eax)
    list_init(&free_list);
    nr_free = 0;
c0103bad:	c7 05 48 57 12 c0 00 	movl   $0x0,0xc0125748
c0103bb4:	00 00 00 
}
c0103bb7:	c9                   	leave  
c0103bb8:	c3                   	ret    

c0103bb9 <default_init_memmap>:

static void
default_init_memmap(struct Page *base, size_t n) {
c0103bb9:	55                   	push   %ebp
c0103bba:	89 e5                	mov    %esp,%ebp
c0103bbc:	83 ec 48             	sub    $0x48,%esp
    cprintf("va: 0x%x, pa: 0x%x, num: %d\n", base, page2pa(base), n);
c0103bbf:	8b 45 08             	mov    0x8(%ebp),%eax
c0103bc2:	89 04 24             	mov    %eax,(%esp)
c0103bc5:	e8 95 ff ff ff       	call   c0103b5f <page2pa>
c0103bca:	8b 55 0c             	mov    0xc(%ebp),%edx
c0103bcd:	89 54 24 0c          	mov    %edx,0xc(%esp)
c0103bd1:	89 44 24 08          	mov    %eax,0x8(%esp)
c0103bd5:	8b 45 08             	mov    0x8(%ebp),%eax
c0103bd8:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103bdc:	c7 04 24 dc 7d 10 c0 	movl   $0xc0107ddc,(%esp)
c0103be3:	e8 6c c7 ff ff       	call   c0100354 <cprintf>
    assert(n > 0);
c0103be8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0103bec:	75 24                	jne    c0103c12 <default_init_memmap+0x59>
c0103bee:	c7 44 24 0c f9 7d 10 	movl   $0xc0107df9,0xc(%esp)
c0103bf5:	c0 
c0103bf6:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0103bfd:	c0 
c0103bfe:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
c0103c05:	00 
c0103c06:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0103c0d:	e8 cc d0 ff ff       	call   c0100cde <__panic>
    struct Page *p = base;
c0103c12:	8b 45 08             	mov    0x8(%ebp),%eax
c0103c15:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
c0103c18:	eb 7d                	jmp    c0103c97 <default_init_memmap+0xde>
        assert(PageReserved(p));
c0103c1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103c1d:	83 c0 04             	add    $0x4,%eax
c0103c20:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
c0103c27:	89 45 ec             	mov    %eax,-0x14(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0103c2a:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103c2d:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0103c30:	0f a3 10             	bt     %edx,(%eax)
c0103c33:	19 c0                	sbb    %eax,%eax
c0103c35:	89 45 e8             	mov    %eax,-0x18(%ebp)
    return oldbit != 0;
c0103c38:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0103c3c:	0f 95 c0             	setne  %al
c0103c3f:	0f b6 c0             	movzbl %al,%eax
c0103c42:	85 c0                	test   %eax,%eax
c0103c44:	75 24                	jne    c0103c6a <default_init_memmap+0xb1>
c0103c46:	c7 44 24 0c 2a 7e 10 	movl   $0xc0107e2a,0xc(%esp)
c0103c4d:	c0 
c0103c4e:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0103c55:	c0 
c0103c56:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
c0103c5d:	00 
c0103c5e:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0103c65:	e8 74 d0 ff ff       	call   c0100cde <__panic>
        p->flags = p->property = 0;
c0103c6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103c6d:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
c0103c74:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103c77:	8b 50 08             	mov    0x8(%eax),%edx
c0103c7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103c7d:	89 50 04             	mov    %edx,0x4(%eax)
        set_page_ref(p, 0);
c0103c80:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0103c87:	00 
c0103c88:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103c8b:	89 04 24             	mov    %eax,(%esp)
c0103c8e:	e8 ec fe ff ff       	call   c0103b7f <set_page_ref>
static void
default_init_memmap(struct Page *base, size_t n) {
    cprintf("va: 0x%x, pa: 0x%x, num: %d\n", base, page2pa(base), n);
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
c0103c93:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
c0103c97:	8b 55 0c             	mov    0xc(%ebp),%edx
c0103c9a:	89 d0                	mov    %edx,%eax
c0103c9c:	c1 e0 02             	shl    $0x2,%eax
c0103c9f:	01 d0                	add    %edx,%eax
c0103ca1:	c1 e0 02             	shl    $0x2,%eax
c0103ca4:	89 c2                	mov    %eax,%edx
c0103ca6:	8b 45 08             	mov    0x8(%ebp),%eax
c0103ca9:	01 d0                	add    %edx,%eax
c0103cab:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0103cae:	0f 85 66 ff ff ff    	jne    c0103c1a <default_init_memmap+0x61>
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
c0103cb4:	8b 45 08             	mov    0x8(%ebp),%eax
c0103cb7:	8b 55 0c             	mov    0xc(%ebp),%edx
c0103cba:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
c0103cbd:	8b 45 08             	mov    0x8(%ebp),%eax
c0103cc0:	83 c0 04             	add    $0x4,%eax
c0103cc3:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
c0103cca:	89 45 e0             	mov    %eax,-0x20(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0103ccd:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103cd0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0103cd3:	0f ab 10             	bts    %edx,(%eax)
    nr_free += n;
c0103cd6:	8b 15 48 57 12 c0    	mov    0xc0125748,%edx
c0103cdc:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103cdf:	01 d0                	add    %edx,%eax
c0103ce1:	a3 48 57 12 c0       	mov    %eax,0xc0125748
    //默认地址是从小到大来的，因此这里要改成before
    list_add_before(&free_list, &(base->page_link));
c0103ce6:	8b 45 08             	mov    0x8(%ebp),%eax
c0103ce9:	83 c0 0c             	add    $0xc,%eax
c0103cec:	c7 45 dc 40 57 12 c0 	movl   $0xc0125740,-0x24(%ebp)
c0103cf3:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
c0103cf6:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0103cf9:	8b 00                	mov    (%eax),%eax
c0103cfb:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0103cfe:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0103d01:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0103d04:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0103d07:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c0103d0a:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0103d0d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0103d10:	89 10                	mov    %edx,(%eax)
c0103d12:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0103d15:	8b 10                	mov    (%eax),%edx
c0103d17:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0103d1a:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c0103d1d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0103d20:	8b 55 cc             	mov    -0x34(%ebp),%edx
c0103d23:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0103d26:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0103d29:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0103d2c:	89 10                	mov    %edx,(%eax)
}
c0103d2e:	c9                   	leave  
c0103d2f:	c3                   	ret    

c0103d30 <default_alloc_pages>:

static struct Page *
default_alloc_pages(size_t n) {
c0103d30:	55                   	push   %ebp
c0103d31:	89 e5                	mov    %esp,%ebp
c0103d33:	83 ec 68             	sub    $0x68,%esp
    assert(n > 0);
c0103d36:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0103d3a:	75 24                	jne    c0103d60 <default_alloc_pages+0x30>
c0103d3c:	c7 44 24 0c f9 7d 10 	movl   $0xc0107df9,0xc(%esp)
c0103d43:	c0 
c0103d44:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0103d4b:	c0 
c0103d4c:	c7 44 24 04 7e 00 00 	movl   $0x7e,0x4(%esp)
c0103d53:	00 
c0103d54:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0103d5b:	e8 7e cf ff ff       	call   c0100cde <__panic>
    if (n > nr_free) {
c0103d60:	a1 48 57 12 c0       	mov    0xc0125748,%eax
c0103d65:	3b 45 08             	cmp    0x8(%ebp),%eax
c0103d68:	73 0a                	jae    c0103d74 <default_alloc_pages+0x44>
        return NULL;
c0103d6a:	b8 00 00 00 00       	mov    $0x0,%eax
c0103d6f:	e9 3d 01 00 00       	jmp    c0103eb1 <default_alloc_pages+0x181>
    }
    struct Page *page = NULL;
c0103d74:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    list_entry_t *le = &free_list;
c0103d7b:	c7 45 f0 40 57 12 c0 	movl   $0xc0125740,-0x10(%ebp)
    while ((le = list_next(le)) != &free_list) {
c0103d82:	eb 1c                	jmp    c0103da0 <default_alloc_pages+0x70>
        struct Page *p = le2page(le, page_link);
c0103d84:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103d87:	83 e8 0c             	sub    $0xc,%eax
c0103d8a:	89 45 ec             	mov    %eax,-0x14(%ebp)
        if (p->property >= n) {
c0103d8d:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103d90:	8b 40 08             	mov    0x8(%eax),%eax
c0103d93:	3b 45 08             	cmp    0x8(%ebp),%eax
c0103d96:	72 08                	jb     c0103da0 <default_alloc_pages+0x70>
            page = p;
c0103d98:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103d9b:	89 45 f4             	mov    %eax,-0xc(%ebp)
            break;
c0103d9e:	eb 18                	jmp    c0103db8 <default_alloc_pages+0x88>
c0103da0:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103da3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0103da6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103da9:	8b 40 04             	mov    0x4(%eax),%eax
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c0103dac:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103daf:	81 7d f0 40 57 12 c0 	cmpl   $0xc0125740,-0x10(%ebp)
c0103db6:	75 cc                	jne    c0103d84 <default_alloc_pages+0x54>
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
c0103db8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103dbc:	0f 84 ec 00 00 00    	je     c0103eae <default_alloc_pages+0x17e>
        if (page->property > n) {
c0103dc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103dc5:	8b 40 08             	mov    0x8(%eax),%eax
c0103dc8:	3b 45 08             	cmp    0x8(%ebp),%eax
c0103dcb:	0f 86 8c 00 00 00    	jbe    c0103e5d <default_alloc_pages+0x12d>
            struct Page *p = page + n;
c0103dd1:	8b 55 08             	mov    0x8(%ebp),%edx
c0103dd4:	89 d0                	mov    %edx,%eax
c0103dd6:	c1 e0 02             	shl    $0x2,%eax
c0103dd9:	01 d0                	add    %edx,%eax
c0103ddb:	c1 e0 02             	shl    $0x2,%eax
c0103dde:	89 c2                	mov    %eax,%edx
c0103de0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103de3:	01 d0                	add    %edx,%eax
c0103de5:	89 45 e8             	mov    %eax,-0x18(%ebp)
            p->property = page->property - n;
c0103de8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103deb:	8b 40 08             	mov    0x8(%eax),%eax
c0103dee:	2b 45 08             	sub    0x8(%ebp),%eax
c0103df1:	89 c2                	mov    %eax,%edx
c0103df3:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103df6:	89 50 08             	mov    %edx,0x8(%eax)
            SetPageProperty(p);
c0103df9:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103dfc:	83 c0 04             	add    $0x4,%eax
c0103dff:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
c0103e06:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0103e09:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0103e0c:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0103e0f:	0f ab 10             	bts    %edx,(%eax)
            list_add_after(page->page_link.prev, &(p->page_link));
c0103e12:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103e15:	8d 50 0c             	lea    0xc(%eax),%edx
c0103e18:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103e1b:	8b 40 0c             	mov    0xc(%eax),%eax
c0103e1e:	89 45 d8             	mov    %eax,-0x28(%ebp)
c0103e21:	89 55 d4             	mov    %edx,-0x2c(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
c0103e24:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0103e27:	8b 40 04             	mov    0x4(%eax),%eax
c0103e2a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0103e2d:	89 55 d0             	mov    %edx,-0x30(%ebp)
c0103e30:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0103e33:	89 55 cc             	mov    %edx,-0x34(%ebp)
c0103e36:	89 45 c8             	mov    %eax,-0x38(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c0103e39:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0103e3c:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0103e3f:	89 10                	mov    %edx,(%eax)
c0103e41:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0103e44:	8b 10                	mov    (%eax),%edx
c0103e46:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0103e49:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c0103e4c:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0103e4f:	8b 55 c8             	mov    -0x38(%ebp),%edx
c0103e52:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0103e55:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0103e58:	8b 55 cc             	mov    -0x34(%ebp),%edx
c0103e5b:	89 10                	mov    %edx,(%eax)
        }
        list_del(&(page->page_link));
c0103e5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103e60:	83 c0 0c             	add    $0xc,%eax
c0103e63:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c0103e66:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0103e69:	8b 40 04             	mov    0x4(%eax),%eax
c0103e6c:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c0103e6f:	8b 12                	mov    (%edx),%edx
c0103e71:	89 55 c0             	mov    %edx,-0x40(%ebp)
c0103e74:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c0103e77:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0103e7a:	8b 55 bc             	mov    -0x44(%ebp),%edx
c0103e7d:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c0103e80:	8b 45 bc             	mov    -0x44(%ebp),%eax
c0103e83:	8b 55 c0             	mov    -0x40(%ebp),%edx
c0103e86:	89 10                	mov    %edx,(%eax)
        nr_free -= n;
c0103e88:	a1 48 57 12 c0       	mov    0xc0125748,%eax
c0103e8d:	2b 45 08             	sub    0x8(%ebp),%eax
c0103e90:	a3 48 57 12 c0       	mov    %eax,0xc0125748
        ClearPageProperty(page);
c0103e95:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103e98:	83 c0 04             	add    $0x4,%eax
c0103e9b:	c7 45 b8 01 00 00 00 	movl   $0x1,-0x48(%ebp)
c0103ea2:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0103ea5:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c0103ea8:	8b 55 b8             	mov    -0x48(%ebp),%edx
c0103eab:	0f b3 10             	btr    %edx,(%eax)
    }
    return page;
c0103eae:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0103eb1:	c9                   	leave  
c0103eb2:	c3                   	ret    

c0103eb3 <default_free_pages>:

static void
default_free_pages(struct Page *base, size_t n) {
c0103eb3:	55                   	push   %ebp
c0103eb4:	89 e5                	mov    %esp,%ebp
c0103eb6:	81 ec 98 00 00 00    	sub    $0x98,%esp
    assert(n > 0);
c0103ebc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0103ec0:	75 24                	jne    c0103ee6 <default_free_pages+0x33>
c0103ec2:	c7 44 24 0c f9 7d 10 	movl   $0xc0107df9,0xc(%esp)
c0103ec9:	c0 
c0103eca:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0103ed1:	c0 
c0103ed2:	c7 44 24 04 9b 00 00 	movl   $0x9b,0x4(%esp)
c0103ed9:	00 
c0103eda:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0103ee1:	e8 f8 cd ff ff       	call   c0100cde <__panic>
    struct Page *p = base;
c0103ee6:	8b 45 08             	mov    0x8(%ebp),%eax
c0103ee9:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
c0103eec:	e9 9d 00 00 00       	jmp    c0103f8e <default_free_pages+0xdb>
        assert(!PageReserved(p) && !PageProperty(p));
c0103ef1:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103ef4:	83 c0 04             	add    $0x4,%eax
c0103ef7:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
c0103efe:	89 45 e8             	mov    %eax,-0x18(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0103f01:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103f04:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0103f07:	0f a3 10             	bt     %edx,(%eax)
c0103f0a:	19 c0                	sbb    %eax,%eax
c0103f0c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    return oldbit != 0;
c0103f0f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0103f13:	0f 95 c0             	setne  %al
c0103f16:	0f b6 c0             	movzbl %al,%eax
c0103f19:	85 c0                	test   %eax,%eax
c0103f1b:	75 2c                	jne    c0103f49 <default_free_pages+0x96>
c0103f1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103f20:	83 c0 04             	add    $0x4,%eax
c0103f23:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
c0103f2a:	89 45 dc             	mov    %eax,-0x24(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0103f2d:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0103f30:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0103f33:	0f a3 10             	bt     %edx,(%eax)
c0103f36:	19 c0                	sbb    %eax,%eax
c0103f38:	89 45 d8             	mov    %eax,-0x28(%ebp)
    return oldbit != 0;
c0103f3b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
c0103f3f:	0f 95 c0             	setne  %al
c0103f42:	0f b6 c0             	movzbl %al,%eax
c0103f45:	85 c0                	test   %eax,%eax
c0103f47:	74 24                	je     c0103f6d <default_free_pages+0xba>
c0103f49:	c7 44 24 0c 3c 7e 10 	movl   $0xc0107e3c,0xc(%esp)
c0103f50:	c0 
c0103f51:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0103f58:	c0 
c0103f59:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
c0103f60:	00 
c0103f61:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0103f68:	e8 71 cd ff ff       	call   c0100cde <__panic>
        p->flags = 0;
c0103f6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103f70:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
        set_page_ref(p, 0);
c0103f77:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0103f7e:	00 
c0103f7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103f82:	89 04 24             	mov    %eax,(%esp)
c0103f85:	e8 f5 fb ff ff       	call   c0103b7f <set_page_ref>

static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
c0103f8a:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
c0103f8e:	8b 55 0c             	mov    0xc(%ebp),%edx
c0103f91:	89 d0                	mov    %edx,%eax
c0103f93:	c1 e0 02             	shl    $0x2,%eax
c0103f96:	01 d0                	add    %edx,%eax
c0103f98:	c1 e0 02             	shl    $0x2,%eax
c0103f9b:	89 c2                	mov    %eax,%edx
c0103f9d:	8b 45 08             	mov    0x8(%ebp),%eax
c0103fa0:	01 d0                	add    %edx,%eax
c0103fa2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0103fa5:	0f 85 46 ff ff ff    	jne    c0103ef1 <default_free_pages+0x3e>
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
c0103fab:	8b 45 08             	mov    0x8(%ebp),%eax
c0103fae:	8b 55 0c             	mov    0xc(%ebp),%edx
c0103fb1:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
c0103fb4:	8b 45 08             	mov    0x8(%ebp),%eax
c0103fb7:	83 c0 04             	add    $0x4,%eax
c0103fba:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
c0103fc1:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0103fc4:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0103fc7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0103fca:	0f ab 10             	bts    %edx,(%eax)
c0103fcd:	c7 45 cc 40 57 12 c0 	movl   $0xc0125740,-0x34(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0103fd4:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0103fd7:	8b 40 04             	mov    0x4(%eax),%eax
    list_entry_t *le = list_next(&free_list);
c0103fda:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
c0103fdd:	e9 0b 01 00 00       	jmp    c01040ed <default_free_pages+0x23a>
        p = le2page(le, page_link);
c0103fe2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103fe5:	83 e8 0c             	sub    $0xc,%eax
c0103fe8:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0103feb:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103fee:	89 45 c8             	mov    %eax,-0x38(%ebp)
c0103ff1:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0103ff4:	8b 40 04             	mov    0x4(%eax),%eax
        le = list_next(le);
c0103ff7:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (base + base->property == p) {
c0103ffa:	8b 45 08             	mov    0x8(%ebp),%eax
c0103ffd:	8b 50 08             	mov    0x8(%eax),%edx
c0104000:	89 d0                	mov    %edx,%eax
c0104002:	c1 e0 02             	shl    $0x2,%eax
c0104005:	01 d0                	add    %edx,%eax
c0104007:	c1 e0 02             	shl    $0x2,%eax
c010400a:	89 c2                	mov    %eax,%edx
c010400c:	8b 45 08             	mov    0x8(%ebp),%eax
c010400f:	01 d0                	add    %edx,%eax
c0104011:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104014:	75 5d                	jne    c0104073 <default_free_pages+0x1c0>
            base->property += p->property;
c0104016:	8b 45 08             	mov    0x8(%ebp),%eax
c0104019:	8b 50 08             	mov    0x8(%eax),%edx
c010401c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010401f:	8b 40 08             	mov    0x8(%eax),%eax
c0104022:	01 c2                	add    %eax,%edx
c0104024:	8b 45 08             	mov    0x8(%ebp),%eax
c0104027:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(p);
c010402a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010402d:	83 c0 04             	add    $0x4,%eax
c0104030:	c7 45 c4 01 00 00 00 	movl   $0x1,-0x3c(%ebp)
c0104037:	89 45 c0             	mov    %eax,-0x40(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c010403a:	8b 45 c0             	mov    -0x40(%ebp),%eax
c010403d:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c0104040:	0f b3 10             	btr    %edx,(%eax)
            list_del(&(p->page_link));
c0104043:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104046:	83 c0 0c             	add    $0xc,%eax
c0104049:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c010404c:	8b 45 bc             	mov    -0x44(%ebp),%eax
c010404f:	8b 40 04             	mov    0x4(%eax),%eax
c0104052:	8b 55 bc             	mov    -0x44(%ebp),%edx
c0104055:	8b 12                	mov    (%edx),%edx
c0104057:	89 55 b8             	mov    %edx,-0x48(%ebp)
c010405a:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c010405d:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0104060:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0104063:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c0104066:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c0104069:	8b 55 b8             	mov    -0x48(%ebp),%edx
c010406c:	89 10                	mov    %edx,(%eax)
            break;
c010406e:	e9 87 00 00 00       	jmp    c01040fa <default_free_pages+0x247>
        }
        else if (p + p->property == base) {
c0104073:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104076:	8b 50 08             	mov    0x8(%eax),%edx
c0104079:	89 d0                	mov    %edx,%eax
c010407b:	c1 e0 02             	shl    $0x2,%eax
c010407e:	01 d0                	add    %edx,%eax
c0104080:	c1 e0 02             	shl    $0x2,%eax
c0104083:	89 c2                	mov    %eax,%edx
c0104085:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104088:	01 d0                	add    %edx,%eax
c010408a:	3b 45 08             	cmp    0x8(%ebp),%eax
c010408d:	75 5e                	jne    c01040ed <default_free_pages+0x23a>
            p->property += base->property;
c010408f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104092:	8b 50 08             	mov    0x8(%eax),%edx
c0104095:	8b 45 08             	mov    0x8(%ebp),%eax
c0104098:	8b 40 08             	mov    0x8(%eax),%eax
c010409b:	01 c2                	add    %eax,%edx
c010409d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01040a0:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(base);
c01040a3:	8b 45 08             	mov    0x8(%ebp),%eax
c01040a6:	83 c0 04             	add    $0x4,%eax
c01040a9:	c7 45 b0 01 00 00 00 	movl   $0x1,-0x50(%ebp)
c01040b0:	89 45 ac             	mov    %eax,-0x54(%ebp)
c01040b3:	8b 45 ac             	mov    -0x54(%ebp),%eax
c01040b6:	8b 55 b0             	mov    -0x50(%ebp),%edx
c01040b9:	0f b3 10             	btr    %edx,(%eax)
            list_del(&(p->page_link));
c01040bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01040bf:	83 c0 0c             	add    $0xc,%eax
c01040c2:	89 45 a8             	mov    %eax,-0x58(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c01040c5:	8b 45 a8             	mov    -0x58(%ebp),%eax
c01040c8:	8b 40 04             	mov    0x4(%eax),%eax
c01040cb:	8b 55 a8             	mov    -0x58(%ebp),%edx
c01040ce:	8b 12                	mov    (%edx),%edx
c01040d0:	89 55 a4             	mov    %edx,-0x5c(%ebp)
c01040d3:	89 45 a0             	mov    %eax,-0x60(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c01040d6:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c01040d9:	8b 55 a0             	mov    -0x60(%ebp),%edx
c01040dc:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c01040df:	8b 45 a0             	mov    -0x60(%ebp),%eax
c01040e2:	8b 55 a4             	mov    -0x5c(%ebp),%edx
c01040e5:	89 10                	mov    %edx,(%eax)
            base = p;
c01040e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01040ea:	89 45 08             	mov    %eax,0x8(%ebp)
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    list_entry_t *le = list_next(&free_list);
    while (le != &free_list) {
c01040ed:	81 7d f0 40 57 12 c0 	cmpl   $0xc0125740,-0x10(%ebp)
c01040f4:	0f 85 e8 fe ff ff    	jne    c0103fe2 <default_free_pages+0x12f>
c01040fa:	c7 45 9c 40 57 12 c0 	movl   $0xc0125740,-0x64(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0104101:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0104104:	8b 40 04             	mov    0x4(%eax),%eax
            ClearPageProperty(base);
            list_del(&(p->page_link));
            base = p;
        }
    }
    le = list_next(&free_list);
c0104107:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
c010410a:	eb 22                	jmp    c010412e <default_free_pages+0x27b>
        p = le2page(le, page_link);
c010410c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010410f:	83 e8 0c             	sub    $0xc,%eax
c0104112:	89 45 f4             	mov    %eax,-0xc(%ebp)
        if (base < p) {
c0104115:	8b 45 08             	mov    0x8(%ebp),%eax
c0104118:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010411b:	73 02                	jae    c010411f <default_free_pages+0x26c>
            break;
c010411d:	eb 18                	jmp    c0104137 <default_free_pages+0x284>
c010411f:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104122:	89 45 98             	mov    %eax,-0x68(%ebp)
c0104125:	8b 45 98             	mov    -0x68(%ebp),%eax
c0104128:	8b 40 04             	mov    0x4(%eax),%eax
        }
        le = list_next(le);
c010412b:	89 45 f0             	mov    %eax,-0x10(%ebp)
            list_del(&(p->page_link));
            base = p;
        }
    }
    le = list_next(&free_list);
    while (le != &free_list) {
c010412e:	81 7d f0 40 57 12 c0 	cmpl   $0xc0125740,-0x10(%ebp)
c0104135:	75 d5                	jne    c010410c <default_free_pages+0x259>
        if (base < p) {
            break;
        }
        le = list_next(le);
    }
    nr_free += n;
c0104137:	8b 15 48 57 12 c0    	mov    0xc0125748,%edx
c010413d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0104140:	01 d0                	add    %edx,%eax
c0104142:	a3 48 57 12 c0       	mov    %eax,0xc0125748
    list_add_before(le, &(base->page_link));
c0104147:	8b 45 08             	mov    0x8(%ebp),%eax
c010414a:	8d 50 0c             	lea    0xc(%eax),%edx
c010414d:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104150:	89 45 94             	mov    %eax,-0x6c(%ebp)
c0104153:	89 55 90             	mov    %edx,-0x70(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
c0104156:	8b 45 94             	mov    -0x6c(%ebp),%eax
c0104159:	8b 00                	mov    (%eax),%eax
c010415b:	8b 55 90             	mov    -0x70(%ebp),%edx
c010415e:	89 55 8c             	mov    %edx,-0x74(%ebp)
c0104161:	89 45 88             	mov    %eax,-0x78(%ebp)
c0104164:	8b 45 94             	mov    -0x6c(%ebp),%eax
c0104167:	89 45 84             	mov    %eax,-0x7c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c010416a:	8b 45 84             	mov    -0x7c(%ebp),%eax
c010416d:	8b 55 8c             	mov    -0x74(%ebp),%edx
c0104170:	89 10                	mov    %edx,(%eax)
c0104172:	8b 45 84             	mov    -0x7c(%ebp),%eax
c0104175:	8b 10                	mov    (%eax),%edx
c0104177:	8b 45 88             	mov    -0x78(%ebp),%eax
c010417a:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c010417d:	8b 45 8c             	mov    -0x74(%ebp),%eax
c0104180:	8b 55 84             	mov    -0x7c(%ebp),%edx
c0104183:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0104186:	8b 45 8c             	mov    -0x74(%ebp),%eax
c0104189:	8b 55 88             	mov    -0x78(%ebp),%edx
c010418c:	89 10                	mov    %edx,(%eax)
}
c010418e:	c9                   	leave  
c010418f:	c3                   	ret    

c0104190 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void) {
c0104190:	55                   	push   %ebp
c0104191:	89 e5                	mov    %esp,%ebp
    return nr_free;
c0104193:	a1 48 57 12 c0       	mov    0xc0125748,%eax
}
c0104198:	5d                   	pop    %ebp
c0104199:	c3                   	ret    

c010419a <basic_check>:

static void
basic_check(void) {
c010419a:	55                   	push   %ebp
c010419b:	89 e5                	mov    %esp,%ebp
c010419d:	83 ec 48             	sub    $0x48,%esp
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
c01041a0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c01041a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01041aa:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01041ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01041b0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    assert((p0 = alloc_page()) != NULL);
c01041b3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01041ba:	e8 db 0e 00 00       	call   c010509a <alloc_pages>
c01041bf:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01041c2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c01041c6:	75 24                	jne    c01041ec <basic_check+0x52>
c01041c8:	c7 44 24 0c 61 7e 10 	movl   $0xc0107e61,0xc(%esp)
c01041cf:	c0 
c01041d0:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c01041d7:	c0 
c01041d8:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
c01041df:	00 
c01041e0:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c01041e7:	e8 f2 ca ff ff       	call   c0100cde <__panic>
    assert((p1 = alloc_page()) != NULL);
c01041ec:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01041f3:	e8 a2 0e 00 00       	call   c010509a <alloc_pages>
c01041f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01041fb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01041ff:	75 24                	jne    c0104225 <basic_check+0x8b>
c0104201:	c7 44 24 0c 7d 7e 10 	movl   $0xc0107e7d,0xc(%esp)
c0104208:	c0 
c0104209:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104210:	c0 
c0104211:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
c0104218:	00 
c0104219:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104220:	e8 b9 ca ff ff       	call   c0100cde <__panic>
    assert((p2 = alloc_page()) != NULL);
c0104225:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010422c:	e8 69 0e 00 00       	call   c010509a <alloc_pages>
c0104231:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0104234:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0104238:	75 24                	jne    c010425e <basic_check+0xc4>
c010423a:	c7 44 24 0c 99 7e 10 	movl   $0xc0107e99,0xc(%esp)
c0104241:	c0 
c0104242:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104249:	c0 
c010424a:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
c0104251:	00 
c0104252:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104259:	e8 80 ca ff ff       	call   c0100cde <__panic>

    assert(p0 != p1 && p0 != p2 && p1 != p2);
c010425e:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104261:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c0104264:	74 10                	je     c0104276 <basic_check+0xdc>
c0104266:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104269:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010426c:	74 08                	je     c0104276 <basic_check+0xdc>
c010426e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104271:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104274:	75 24                	jne    c010429a <basic_check+0x100>
c0104276:	c7 44 24 0c b8 7e 10 	movl   $0xc0107eb8,0xc(%esp)
c010427d:	c0 
c010427e:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104285:	c0 
c0104286:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
c010428d:	00 
c010428e:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104295:	e8 44 ca ff ff       	call   c0100cde <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
c010429a:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010429d:	89 04 24             	mov    %eax,(%esp)
c01042a0:	e8 d0 f8 ff ff       	call   c0103b75 <page_ref>
c01042a5:	85 c0                	test   %eax,%eax
c01042a7:	75 1e                	jne    c01042c7 <basic_check+0x12d>
c01042a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01042ac:	89 04 24             	mov    %eax,(%esp)
c01042af:	e8 c1 f8 ff ff       	call   c0103b75 <page_ref>
c01042b4:	85 c0                	test   %eax,%eax
c01042b6:	75 0f                	jne    c01042c7 <basic_check+0x12d>
c01042b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01042bb:	89 04 24             	mov    %eax,(%esp)
c01042be:	e8 b2 f8 ff ff       	call   c0103b75 <page_ref>
c01042c3:	85 c0                	test   %eax,%eax
c01042c5:	74 24                	je     c01042eb <basic_check+0x151>
c01042c7:	c7 44 24 0c dc 7e 10 	movl   $0xc0107edc,0xc(%esp)
c01042ce:	c0 
c01042cf:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c01042d6:	c0 
c01042d7:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
c01042de:	00 
c01042df:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c01042e6:	e8 f3 c9 ff ff       	call   c0100cde <__panic>

    assert(page2pa(p0) < npage * PGSIZE);
c01042eb:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01042ee:	89 04 24             	mov    %eax,(%esp)
c01042f1:	e8 69 f8 ff ff       	call   c0103b5f <page2pa>
c01042f6:	8b 15 a0 56 12 c0    	mov    0xc01256a0,%edx
c01042fc:	c1 e2 0c             	shl    $0xc,%edx
c01042ff:	39 d0                	cmp    %edx,%eax
c0104301:	72 24                	jb     c0104327 <basic_check+0x18d>
c0104303:	c7 44 24 0c 18 7f 10 	movl   $0xc0107f18,0xc(%esp)
c010430a:	c0 
c010430b:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104312:	c0 
c0104313:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
c010431a:	00 
c010431b:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104322:	e8 b7 c9 ff ff       	call   c0100cde <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
c0104327:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010432a:	89 04 24             	mov    %eax,(%esp)
c010432d:	e8 2d f8 ff ff       	call   c0103b5f <page2pa>
c0104332:	8b 15 a0 56 12 c0    	mov    0xc01256a0,%edx
c0104338:	c1 e2 0c             	shl    $0xc,%edx
c010433b:	39 d0                	cmp    %edx,%eax
c010433d:	72 24                	jb     c0104363 <basic_check+0x1c9>
c010433f:	c7 44 24 0c 35 7f 10 	movl   $0xc0107f35,0xc(%esp)
c0104346:	c0 
c0104347:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c010434e:	c0 
c010434f:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
c0104356:	00 
c0104357:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c010435e:	e8 7b c9 ff ff       	call   c0100cde <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
c0104363:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104366:	89 04 24             	mov    %eax,(%esp)
c0104369:	e8 f1 f7 ff ff       	call   c0103b5f <page2pa>
c010436e:	8b 15 a0 56 12 c0    	mov    0xc01256a0,%edx
c0104374:	c1 e2 0c             	shl    $0xc,%edx
c0104377:	39 d0                	cmp    %edx,%eax
c0104379:	72 24                	jb     c010439f <basic_check+0x205>
c010437b:	c7 44 24 0c 52 7f 10 	movl   $0xc0107f52,0xc(%esp)
c0104382:	c0 
c0104383:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c010438a:	c0 
c010438b:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
c0104392:	00 
c0104393:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c010439a:	e8 3f c9 ff ff       	call   c0100cde <__panic>

    list_entry_t free_list_store = free_list;
c010439f:	a1 40 57 12 c0       	mov    0xc0125740,%eax
c01043a4:	8b 15 44 57 12 c0    	mov    0xc0125744,%edx
c01043aa:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01043ad:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c01043b0:	c7 45 e0 40 57 12 c0 	movl   $0xc0125740,-0x20(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c01043b7:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01043ba:	8b 55 e0             	mov    -0x20(%ebp),%edx
c01043bd:	89 50 04             	mov    %edx,0x4(%eax)
c01043c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01043c3:	8b 50 04             	mov    0x4(%eax),%edx
c01043c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01043c9:	89 10                	mov    %edx,(%eax)
c01043cb:	c7 45 dc 40 57 12 c0 	movl   $0xc0125740,-0x24(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
c01043d2:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01043d5:	8b 40 04             	mov    0x4(%eax),%eax
c01043d8:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c01043db:	0f 94 c0             	sete   %al
c01043de:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
c01043e1:	85 c0                	test   %eax,%eax
c01043e3:	75 24                	jne    c0104409 <basic_check+0x26f>
c01043e5:	c7 44 24 0c 6f 7f 10 	movl   $0xc0107f6f,0xc(%esp)
c01043ec:	c0 
c01043ed:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c01043f4:	c0 
c01043f5:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
c01043fc:	00 
c01043fd:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104404:	e8 d5 c8 ff ff       	call   c0100cde <__panic>

    unsigned int nr_free_store = nr_free;
c0104409:	a1 48 57 12 c0       	mov    0xc0125748,%eax
c010440e:	89 45 e8             	mov    %eax,-0x18(%ebp)
    nr_free = 0;
c0104411:	c7 05 48 57 12 c0 00 	movl   $0x0,0xc0125748
c0104418:	00 00 00 

    assert(alloc_page() == NULL);
c010441b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104422:	e8 73 0c 00 00       	call   c010509a <alloc_pages>
c0104427:	85 c0                	test   %eax,%eax
c0104429:	74 24                	je     c010444f <basic_check+0x2b5>
c010442b:	c7 44 24 0c 86 7f 10 	movl   $0xc0107f86,0xc(%esp)
c0104432:	c0 
c0104433:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c010443a:	c0 
c010443b:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
c0104442:	00 
c0104443:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c010444a:	e8 8f c8 ff ff       	call   c0100cde <__panic>

    free_page(p0);
c010444f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104456:	00 
c0104457:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010445a:	89 04 24             	mov    %eax,(%esp)
c010445d:	e8 70 0c 00 00       	call   c01050d2 <free_pages>
    free_page(p1);
c0104462:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104469:	00 
c010446a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010446d:	89 04 24             	mov    %eax,(%esp)
c0104470:	e8 5d 0c 00 00       	call   c01050d2 <free_pages>
    free_page(p2);
c0104475:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c010447c:	00 
c010447d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104480:	89 04 24             	mov    %eax,(%esp)
c0104483:	e8 4a 0c 00 00       	call   c01050d2 <free_pages>
    assert(nr_free == 3);
c0104488:	a1 48 57 12 c0       	mov    0xc0125748,%eax
c010448d:	83 f8 03             	cmp    $0x3,%eax
c0104490:	74 24                	je     c01044b6 <basic_check+0x31c>
c0104492:	c7 44 24 0c 9b 7f 10 	movl   $0xc0107f9b,0xc(%esp)
c0104499:	c0 
c010449a:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c01044a1:	c0 
c01044a2:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
c01044a9:	00 
c01044aa:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c01044b1:	e8 28 c8 ff ff       	call   c0100cde <__panic>

    assert((p0 = alloc_page()) != NULL);
c01044b6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01044bd:	e8 d8 0b 00 00       	call   c010509a <alloc_pages>
c01044c2:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01044c5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c01044c9:	75 24                	jne    c01044ef <basic_check+0x355>
c01044cb:	c7 44 24 0c 61 7e 10 	movl   $0xc0107e61,0xc(%esp)
c01044d2:	c0 
c01044d3:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c01044da:	c0 
c01044db:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
c01044e2:	00 
c01044e3:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c01044ea:	e8 ef c7 ff ff       	call   c0100cde <__panic>
    assert((p1 = alloc_page()) != NULL);
c01044ef:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01044f6:	e8 9f 0b 00 00       	call   c010509a <alloc_pages>
c01044fb:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01044fe:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0104502:	75 24                	jne    c0104528 <basic_check+0x38e>
c0104504:	c7 44 24 0c 7d 7e 10 	movl   $0xc0107e7d,0xc(%esp)
c010450b:	c0 
c010450c:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104513:	c0 
c0104514:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
c010451b:	00 
c010451c:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104523:	e8 b6 c7 ff ff       	call   c0100cde <__panic>
    assert((p2 = alloc_page()) != NULL);
c0104528:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010452f:	e8 66 0b 00 00       	call   c010509a <alloc_pages>
c0104534:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0104537:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c010453b:	75 24                	jne    c0104561 <basic_check+0x3c7>
c010453d:	c7 44 24 0c 99 7e 10 	movl   $0xc0107e99,0xc(%esp)
c0104544:	c0 
c0104545:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c010454c:	c0 
c010454d:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
c0104554:	00 
c0104555:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c010455c:	e8 7d c7 ff ff       	call   c0100cde <__panic>

    assert(alloc_page() == NULL);
c0104561:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104568:	e8 2d 0b 00 00       	call   c010509a <alloc_pages>
c010456d:	85 c0                	test   %eax,%eax
c010456f:	74 24                	je     c0104595 <basic_check+0x3fb>
c0104571:	c7 44 24 0c 86 7f 10 	movl   $0xc0107f86,0xc(%esp)
c0104578:	c0 
c0104579:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104580:	c0 
c0104581:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
c0104588:	00 
c0104589:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104590:	e8 49 c7 ff ff       	call   c0100cde <__panic>

    free_page(p0);
c0104595:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c010459c:	00 
c010459d:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01045a0:	89 04 24             	mov    %eax,(%esp)
c01045a3:	e8 2a 0b 00 00       	call   c01050d2 <free_pages>
c01045a8:	c7 45 d8 40 57 12 c0 	movl   $0xc0125740,-0x28(%ebp)
c01045af:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01045b2:	8b 40 04             	mov    0x4(%eax),%eax
c01045b5:	39 45 d8             	cmp    %eax,-0x28(%ebp)
c01045b8:	0f 94 c0             	sete   %al
c01045bb:	0f b6 c0             	movzbl %al,%eax
    assert(!list_empty(&free_list));
c01045be:	85 c0                	test   %eax,%eax
c01045c0:	74 24                	je     c01045e6 <basic_check+0x44c>
c01045c2:	c7 44 24 0c a8 7f 10 	movl   $0xc0107fa8,0xc(%esp)
c01045c9:	c0 
c01045ca:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c01045d1:	c0 
c01045d2:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
c01045d9:	00 
c01045da:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c01045e1:	e8 f8 c6 ff ff       	call   c0100cde <__panic>

    struct Page *p;
    assert((p = alloc_page()) == p0);
c01045e6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01045ed:	e8 a8 0a 00 00       	call   c010509a <alloc_pages>
c01045f2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01045f5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01045f8:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c01045fb:	74 24                	je     c0104621 <basic_check+0x487>
c01045fd:	c7 44 24 0c c0 7f 10 	movl   $0xc0107fc0,0xc(%esp)
c0104604:	c0 
c0104605:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c010460c:	c0 
c010460d:	c7 44 24 04 ed 00 00 	movl   $0xed,0x4(%esp)
c0104614:	00 
c0104615:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c010461c:	e8 bd c6 ff ff       	call   c0100cde <__panic>
    assert(alloc_page() == NULL);
c0104621:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104628:	e8 6d 0a 00 00       	call   c010509a <alloc_pages>
c010462d:	85 c0                	test   %eax,%eax
c010462f:	74 24                	je     c0104655 <basic_check+0x4bb>
c0104631:	c7 44 24 0c 86 7f 10 	movl   $0xc0107f86,0xc(%esp)
c0104638:	c0 
c0104639:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104640:	c0 
c0104641:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
c0104648:	00 
c0104649:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104650:	e8 89 c6 ff ff       	call   c0100cde <__panic>

    assert(nr_free == 0);
c0104655:	a1 48 57 12 c0       	mov    0xc0125748,%eax
c010465a:	85 c0                	test   %eax,%eax
c010465c:	74 24                	je     c0104682 <basic_check+0x4e8>
c010465e:	c7 44 24 0c d9 7f 10 	movl   $0xc0107fd9,0xc(%esp)
c0104665:	c0 
c0104666:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c010466d:	c0 
c010466e:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
c0104675:	00 
c0104676:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c010467d:	e8 5c c6 ff ff       	call   c0100cde <__panic>
    free_list = free_list_store;
c0104682:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104685:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104688:	a3 40 57 12 c0       	mov    %eax,0xc0125740
c010468d:	89 15 44 57 12 c0    	mov    %edx,0xc0125744
    nr_free = nr_free_store;
c0104693:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0104696:	a3 48 57 12 c0       	mov    %eax,0xc0125748

    free_page(p);
c010469b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c01046a2:	00 
c01046a3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01046a6:	89 04 24             	mov    %eax,(%esp)
c01046a9:	e8 24 0a 00 00       	call   c01050d2 <free_pages>
    free_page(p1);
c01046ae:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c01046b5:	00 
c01046b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01046b9:	89 04 24             	mov    %eax,(%esp)
c01046bc:	e8 11 0a 00 00       	call   c01050d2 <free_pages>
    free_page(p2);
c01046c1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c01046c8:	00 
c01046c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01046cc:	89 04 24             	mov    %eax,(%esp)
c01046cf:	e8 fe 09 00 00       	call   c01050d2 <free_pages>
}
c01046d4:	c9                   	leave  
c01046d5:	c3                   	ret    

c01046d6 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
c01046d6:	55                   	push   %ebp
c01046d7:	89 e5                	mov    %esp,%ebp
c01046d9:	53                   	push   %ebx
c01046da:	81 ec 94 00 00 00    	sub    $0x94,%esp
    int count = 0, total = 0;
c01046e0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c01046e7:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    list_entry_t *le = &free_list;
c01046ee:	c7 45 ec 40 57 12 c0 	movl   $0xc0125740,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
c01046f5:	eb 6b                	jmp    c0104762 <default_check+0x8c>
        struct Page *p = le2page(le, page_link);
c01046f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01046fa:	83 e8 0c             	sub    $0xc,%eax
c01046fd:	89 45 e8             	mov    %eax,-0x18(%ebp)
        assert(PageProperty(p));
c0104700:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0104703:	83 c0 04             	add    $0x4,%eax
c0104706:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
c010470d:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104710:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0104713:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0104716:	0f a3 10             	bt     %edx,(%eax)
c0104719:	19 c0                	sbb    %eax,%eax
c010471b:	89 45 c8             	mov    %eax,-0x38(%ebp)
    return oldbit != 0;
c010471e:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
c0104722:	0f 95 c0             	setne  %al
c0104725:	0f b6 c0             	movzbl %al,%eax
c0104728:	85 c0                	test   %eax,%eax
c010472a:	75 24                	jne    c0104750 <default_check+0x7a>
c010472c:	c7 44 24 0c e6 7f 10 	movl   $0xc0107fe6,0xc(%esp)
c0104733:	c0 
c0104734:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c010473b:	c0 
c010473c:	c7 44 24 04 01 01 00 	movl   $0x101,0x4(%esp)
c0104743:	00 
c0104744:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c010474b:	e8 8e c5 ff ff       	call   c0100cde <__panic>
        count ++, total += p->property;
c0104750:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0104754:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0104757:	8b 50 08             	mov    0x8(%eax),%edx
c010475a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010475d:	01 d0                	add    %edx,%eax
c010475f:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104762:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104765:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0104768:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c010476b:	8b 40 04             	mov    0x4(%eax),%eax
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c010476e:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0104771:	81 7d ec 40 57 12 c0 	cmpl   $0xc0125740,-0x14(%ebp)
c0104778:	0f 85 79 ff ff ff    	jne    c01046f7 <default_check+0x21>
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());
c010477e:	8b 5d f0             	mov    -0x10(%ebp),%ebx
c0104781:	e8 7e 09 00 00       	call   c0105104 <nr_free_pages>
c0104786:	39 c3                	cmp    %eax,%ebx
c0104788:	74 24                	je     c01047ae <default_check+0xd8>
c010478a:	c7 44 24 0c f6 7f 10 	movl   $0xc0107ff6,0xc(%esp)
c0104791:	c0 
c0104792:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104799:	c0 
c010479a:	c7 44 24 04 04 01 00 	movl   $0x104,0x4(%esp)
c01047a1:	00 
c01047a2:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c01047a9:	e8 30 c5 ff ff       	call   c0100cde <__panic>

    basic_check();
c01047ae:	e8 e7 f9 ff ff       	call   c010419a <basic_check>

    struct Page *p0 = alloc_pages(5), *p1, *p2;
c01047b3:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
c01047ba:	e8 db 08 00 00       	call   c010509a <alloc_pages>
c01047bf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(p0 != NULL);
c01047c2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c01047c6:	75 24                	jne    c01047ec <default_check+0x116>
c01047c8:	c7 44 24 0c 0f 80 10 	movl   $0xc010800f,0xc(%esp)
c01047cf:	c0 
c01047d0:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c01047d7:	c0 
c01047d8:	c7 44 24 04 09 01 00 	movl   $0x109,0x4(%esp)
c01047df:	00 
c01047e0:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c01047e7:	e8 f2 c4 ff ff       	call   c0100cde <__panic>
    assert(!PageProperty(p0));
c01047ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01047ef:	83 c0 04             	add    $0x4,%eax
c01047f2:	c7 45 c0 01 00 00 00 	movl   $0x1,-0x40(%ebp)
c01047f9:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c01047fc:	8b 45 bc             	mov    -0x44(%ebp),%eax
c01047ff:	8b 55 c0             	mov    -0x40(%ebp),%edx
c0104802:	0f a3 10             	bt     %edx,(%eax)
c0104805:	19 c0                	sbb    %eax,%eax
c0104807:	89 45 b8             	mov    %eax,-0x48(%ebp)
    return oldbit != 0;
c010480a:	83 7d b8 00          	cmpl   $0x0,-0x48(%ebp)
c010480e:	0f 95 c0             	setne  %al
c0104811:	0f b6 c0             	movzbl %al,%eax
c0104814:	85 c0                	test   %eax,%eax
c0104816:	74 24                	je     c010483c <default_check+0x166>
c0104818:	c7 44 24 0c 1a 80 10 	movl   $0xc010801a,0xc(%esp)
c010481f:	c0 
c0104820:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104827:	c0 
c0104828:	c7 44 24 04 0a 01 00 	movl   $0x10a,0x4(%esp)
c010482f:	00 
c0104830:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104837:	e8 a2 c4 ff ff       	call   c0100cde <__panic>

    list_entry_t free_list_store = free_list;
c010483c:	a1 40 57 12 c0       	mov    0xc0125740,%eax
c0104841:	8b 15 44 57 12 c0    	mov    0xc0125744,%edx
c0104847:	89 45 80             	mov    %eax,-0x80(%ebp)
c010484a:	89 55 84             	mov    %edx,-0x7c(%ebp)
c010484d:	c7 45 b4 40 57 12 c0 	movl   $0xc0125740,-0x4c(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c0104854:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c0104857:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c010485a:	89 50 04             	mov    %edx,0x4(%eax)
c010485d:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c0104860:	8b 50 04             	mov    0x4(%eax),%edx
c0104863:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c0104866:	89 10                	mov    %edx,(%eax)
c0104868:	c7 45 b0 40 57 12 c0 	movl   $0xc0125740,-0x50(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
c010486f:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0104872:	8b 40 04             	mov    0x4(%eax),%eax
c0104875:	39 45 b0             	cmp    %eax,-0x50(%ebp)
c0104878:	0f 94 c0             	sete   %al
c010487b:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
c010487e:	85 c0                	test   %eax,%eax
c0104880:	75 24                	jne    c01048a6 <default_check+0x1d0>
c0104882:	c7 44 24 0c 6f 7f 10 	movl   $0xc0107f6f,0xc(%esp)
c0104889:	c0 
c010488a:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104891:	c0 
c0104892:	c7 44 24 04 0e 01 00 	movl   $0x10e,0x4(%esp)
c0104899:	00 
c010489a:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c01048a1:	e8 38 c4 ff ff       	call   c0100cde <__panic>
    assert(alloc_page() == NULL);
c01048a6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01048ad:	e8 e8 07 00 00       	call   c010509a <alloc_pages>
c01048b2:	85 c0                	test   %eax,%eax
c01048b4:	74 24                	je     c01048da <default_check+0x204>
c01048b6:	c7 44 24 0c 86 7f 10 	movl   $0xc0107f86,0xc(%esp)
c01048bd:	c0 
c01048be:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c01048c5:	c0 
c01048c6:	c7 44 24 04 0f 01 00 	movl   $0x10f,0x4(%esp)
c01048cd:	00 
c01048ce:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c01048d5:	e8 04 c4 ff ff       	call   c0100cde <__panic>

    unsigned int nr_free_store = nr_free;
c01048da:	a1 48 57 12 c0       	mov    0xc0125748,%eax
c01048df:	89 45 e0             	mov    %eax,-0x20(%ebp)
    nr_free = 0;
c01048e2:	c7 05 48 57 12 c0 00 	movl   $0x0,0xc0125748
c01048e9:	00 00 00 

    free_pages(p0 + 2, 3);
c01048ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01048ef:	83 c0 28             	add    $0x28,%eax
c01048f2:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
c01048f9:	00 
c01048fa:	89 04 24             	mov    %eax,(%esp)
c01048fd:	e8 d0 07 00 00       	call   c01050d2 <free_pages>
    assert(alloc_pages(4) == NULL);
c0104902:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
c0104909:	e8 8c 07 00 00       	call   c010509a <alloc_pages>
c010490e:	85 c0                	test   %eax,%eax
c0104910:	74 24                	je     c0104936 <default_check+0x260>
c0104912:	c7 44 24 0c 2c 80 10 	movl   $0xc010802c,0xc(%esp)
c0104919:	c0 
c010491a:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104921:	c0 
c0104922:	c7 44 24 04 15 01 00 	movl   $0x115,0x4(%esp)
c0104929:	00 
c010492a:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104931:	e8 a8 c3 ff ff       	call   c0100cde <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
c0104936:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104939:	83 c0 28             	add    $0x28,%eax
c010493c:	83 c0 04             	add    $0x4,%eax
c010493f:	c7 45 ac 01 00 00 00 	movl   $0x1,-0x54(%ebp)
c0104946:	89 45 a8             	mov    %eax,-0x58(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104949:	8b 45 a8             	mov    -0x58(%ebp),%eax
c010494c:	8b 55 ac             	mov    -0x54(%ebp),%edx
c010494f:	0f a3 10             	bt     %edx,(%eax)
c0104952:	19 c0                	sbb    %eax,%eax
c0104954:	89 45 a4             	mov    %eax,-0x5c(%ebp)
    return oldbit != 0;
c0104957:	83 7d a4 00          	cmpl   $0x0,-0x5c(%ebp)
c010495b:	0f 95 c0             	setne  %al
c010495e:	0f b6 c0             	movzbl %al,%eax
c0104961:	85 c0                	test   %eax,%eax
c0104963:	74 0e                	je     c0104973 <default_check+0x29d>
c0104965:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104968:	83 c0 28             	add    $0x28,%eax
c010496b:	8b 40 08             	mov    0x8(%eax),%eax
c010496e:	83 f8 03             	cmp    $0x3,%eax
c0104971:	74 24                	je     c0104997 <default_check+0x2c1>
c0104973:	c7 44 24 0c 44 80 10 	movl   $0xc0108044,0xc(%esp)
c010497a:	c0 
c010497b:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104982:	c0 
c0104983:	c7 44 24 04 16 01 00 	movl   $0x116,0x4(%esp)
c010498a:	00 
c010498b:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104992:	e8 47 c3 ff ff       	call   c0100cde <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
c0104997:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
c010499e:	e8 f7 06 00 00       	call   c010509a <alloc_pages>
c01049a3:	89 45 dc             	mov    %eax,-0x24(%ebp)
c01049a6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c01049aa:	75 24                	jne    c01049d0 <default_check+0x2fa>
c01049ac:	c7 44 24 0c 70 80 10 	movl   $0xc0108070,0xc(%esp)
c01049b3:	c0 
c01049b4:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c01049bb:	c0 
c01049bc:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
c01049c3:	00 
c01049c4:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c01049cb:	e8 0e c3 ff ff       	call   c0100cde <__panic>
    assert(alloc_page() == NULL);
c01049d0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01049d7:	e8 be 06 00 00       	call   c010509a <alloc_pages>
c01049dc:	85 c0                	test   %eax,%eax
c01049de:	74 24                	je     c0104a04 <default_check+0x32e>
c01049e0:	c7 44 24 0c 86 7f 10 	movl   $0xc0107f86,0xc(%esp)
c01049e7:	c0 
c01049e8:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c01049ef:	c0 
c01049f0:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
c01049f7:	00 
c01049f8:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c01049ff:	e8 da c2 ff ff       	call   c0100cde <__panic>
    assert(p0 + 2 == p1);
c0104a04:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104a07:	83 c0 28             	add    $0x28,%eax
c0104a0a:	3b 45 dc             	cmp    -0x24(%ebp),%eax
c0104a0d:	74 24                	je     c0104a33 <default_check+0x35d>
c0104a0f:	c7 44 24 0c 8e 80 10 	movl   $0xc010808e,0xc(%esp)
c0104a16:	c0 
c0104a17:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104a1e:	c0 
c0104a1f:	c7 44 24 04 19 01 00 	movl   $0x119,0x4(%esp)
c0104a26:	00 
c0104a27:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104a2e:	e8 ab c2 ff ff       	call   c0100cde <__panic>

    p2 = p0 + 1;
c0104a33:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104a36:	83 c0 14             	add    $0x14,%eax
c0104a39:	89 45 d8             	mov    %eax,-0x28(%ebp)
    free_page(p0);
c0104a3c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104a43:	00 
c0104a44:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104a47:	89 04 24             	mov    %eax,(%esp)
c0104a4a:	e8 83 06 00 00       	call   c01050d2 <free_pages>
    free_pages(p1, 3);
c0104a4f:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
c0104a56:	00 
c0104a57:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104a5a:	89 04 24             	mov    %eax,(%esp)
c0104a5d:	e8 70 06 00 00       	call   c01050d2 <free_pages>
    assert(PageProperty(p0) && p0->property == 1);
c0104a62:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104a65:	83 c0 04             	add    $0x4,%eax
c0104a68:	c7 45 a0 01 00 00 00 	movl   $0x1,-0x60(%ebp)
c0104a6f:	89 45 9c             	mov    %eax,-0x64(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104a72:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0104a75:	8b 55 a0             	mov    -0x60(%ebp),%edx
c0104a78:	0f a3 10             	bt     %edx,(%eax)
c0104a7b:	19 c0                	sbb    %eax,%eax
c0104a7d:	89 45 98             	mov    %eax,-0x68(%ebp)
    return oldbit != 0;
c0104a80:	83 7d 98 00          	cmpl   $0x0,-0x68(%ebp)
c0104a84:	0f 95 c0             	setne  %al
c0104a87:	0f b6 c0             	movzbl %al,%eax
c0104a8a:	85 c0                	test   %eax,%eax
c0104a8c:	74 0b                	je     c0104a99 <default_check+0x3c3>
c0104a8e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104a91:	8b 40 08             	mov    0x8(%eax),%eax
c0104a94:	83 f8 01             	cmp    $0x1,%eax
c0104a97:	74 24                	je     c0104abd <default_check+0x3e7>
c0104a99:	c7 44 24 0c 9c 80 10 	movl   $0xc010809c,0xc(%esp)
c0104aa0:	c0 
c0104aa1:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104aa8:	c0 
c0104aa9:	c7 44 24 04 1e 01 00 	movl   $0x11e,0x4(%esp)
c0104ab0:	00 
c0104ab1:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104ab8:	e8 21 c2 ff ff       	call   c0100cde <__panic>
    assert(PageProperty(p1) && p1->property == 3);
c0104abd:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104ac0:	83 c0 04             	add    $0x4,%eax
c0104ac3:	c7 45 94 01 00 00 00 	movl   $0x1,-0x6c(%ebp)
c0104aca:	89 45 90             	mov    %eax,-0x70(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104acd:	8b 45 90             	mov    -0x70(%ebp),%eax
c0104ad0:	8b 55 94             	mov    -0x6c(%ebp),%edx
c0104ad3:	0f a3 10             	bt     %edx,(%eax)
c0104ad6:	19 c0                	sbb    %eax,%eax
c0104ad8:	89 45 8c             	mov    %eax,-0x74(%ebp)
    return oldbit != 0;
c0104adb:	83 7d 8c 00          	cmpl   $0x0,-0x74(%ebp)
c0104adf:	0f 95 c0             	setne  %al
c0104ae2:	0f b6 c0             	movzbl %al,%eax
c0104ae5:	85 c0                	test   %eax,%eax
c0104ae7:	74 0b                	je     c0104af4 <default_check+0x41e>
c0104ae9:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104aec:	8b 40 08             	mov    0x8(%eax),%eax
c0104aef:	83 f8 03             	cmp    $0x3,%eax
c0104af2:	74 24                	je     c0104b18 <default_check+0x442>
c0104af4:	c7 44 24 0c c4 80 10 	movl   $0xc01080c4,0xc(%esp)
c0104afb:	c0 
c0104afc:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104b03:	c0 
c0104b04:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
c0104b0b:	00 
c0104b0c:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104b13:	e8 c6 c1 ff ff       	call   c0100cde <__panic>

    assert((p0 = alloc_page()) == p2 - 1);
c0104b18:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104b1f:	e8 76 05 00 00       	call   c010509a <alloc_pages>
c0104b24:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0104b27:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104b2a:	83 e8 14             	sub    $0x14,%eax
c0104b2d:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
c0104b30:	74 24                	je     c0104b56 <default_check+0x480>
c0104b32:	c7 44 24 0c ea 80 10 	movl   $0xc01080ea,0xc(%esp)
c0104b39:	c0 
c0104b3a:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104b41:	c0 
c0104b42:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
c0104b49:	00 
c0104b4a:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104b51:	e8 88 c1 ff ff       	call   c0100cde <__panic>
    free_page(p0);
c0104b56:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104b5d:	00 
c0104b5e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104b61:	89 04 24             	mov    %eax,(%esp)
c0104b64:	e8 69 05 00 00       	call   c01050d2 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
c0104b69:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
c0104b70:	e8 25 05 00 00       	call   c010509a <alloc_pages>
c0104b75:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0104b78:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104b7b:	83 c0 14             	add    $0x14,%eax
c0104b7e:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
c0104b81:	74 24                	je     c0104ba7 <default_check+0x4d1>
c0104b83:	c7 44 24 0c 08 81 10 	movl   $0xc0108108,0xc(%esp)
c0104b8a:	c0 
c0104b8b:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104b92:	c0 
c0104b93:	c7 44 24 04 23 01 00 	movl   $0x123,0x4(%esp)
c0104b9a:	00 
c0104b9b:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104ba2:	e8 37 c1 ff ff       	call   c0100cde <__panic>

    free_pages(p0, 2);
c0104ba7:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
c0104bae:	00 
c0104baf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104bb2:	89 04 24             	mov    %eax,(%esp)
c0104bb5:	e8 18 05 00 00       	call   c01050d2 <free_pages>
    free_page(p2);
c0104bba:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104bc1:	00 
c0104bc2:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104bc5:	89 04 24             	mov    %eax,(%esp)
c0104bc8:	e8 05 05 00 00       	call   c01050d2 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
c0104bcd:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
c0104bd4:	e8 c1 04 00 00       	call   c010509a <alloc_pages>
c0104bd9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0104bdc:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0104be0:	75 24                	jne    c0104c06 <default_check+0x530>
c0104be2:	c7 44 24 0c 28 81 10 	movl   $0xc0108128,0xc(%esp)
c0104be9:	c0 
c0104bea:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104bf1:	c0 
c0104bf2:	c7 44 24 04 28 01 00 	movl   $0x128,0x4(%esp)
c0104bf9:	00 
c0104bfa:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104c01:	e8 d8 c0 ff ff       	call   c0100cde <__panic>
    assert(alloc_page() == NULL);
c0104c06:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104c0d:	e8 88 04 00 00       	call   c010509a <alloc_pages>
c0104c12:	85 c0                	test   %eax,%eax
c0104c14:	74 24                	je     c0104c3a <default_check+0x564>
c0104c16:	c7 44 24 0c 86 7f 10 	movl   $0xc0107f86,0xc(%esp)
c0104c1d:	c0 
c0104c1e:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104c25:	c0 
c0104c26:	c7 44 24 04 29 01 00 	movl   $0x129,0x4(%esp)
c0104c2d:	00 
c0104c2e:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104c35:	e8 a4 c0 ff ff       	call   c0100cde <__panic>

    assert(nr_free == 0);
c0104c3a:	a1 48 57 12 c0       	mov    0xc0125748,%eax
c0104c3f:	85 c0                	test   %eax,%eax
c0104c41:	74 24                	je     c0104c67 <default_check+0x591>
c0104c43:	c7 44 24 0c d9 7f 10 	movl   $0xc0107fd9,0xc(%esp)
c0104c4a:	c0 
c0104c4b:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104c52:	c0 
c0104c53:	c7 44 24 04 2b 01 00 	movl   $0x12b,0x4(%esp)
c0104c5a:	00 
c0104c5b:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104c62:	e8 77 c0 ff ff       	call   c0100cde <__panic>
    nr_free = nr_free_store;
c0104c67:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0104c6a:	a3 48 57 12 c0       	mov    %eax,0xc0125748

    free_list = free_list_store;
c0104c6f:	8b 45 80             	mov    -0x80(%ebp),%eax
c0104c72:	8b 55 84             	mov    -0x7c(%ebp),%edx
c0104c75:	a3 40 57 12 c0       	mov    %eax,0xc0125740
c0104c7a:	89 15 44 57 12 c0    	mov    %edx,0xc0125744
    free_pages(p0, 5);
c0104c80:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
c0104c87:	00 
c0104c88:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104c8b:	89 04 24             	mov    %eax,(%esp)
c0104c8e:	e8 3f 04 00 00       	call   c01050d2 <free_pages>

    le = &free_list;
c0104c93:	c7 45 ec 40 57 12 c0 	movl   $0xc0125740,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
c0104c9a:	eb 5b                	jmp    c0104cf7 <default_check+0x621>
        assert(le->next->prev == le && le->prev->next == le);
c0104c9c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104c9f:	8b 40 04             	mov    0x4(%eax),%eax
c0104ca2:	8b 00                	mov    (%eax),%eax
c0104ca4:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0104ca7:	75 0d                	jne    c0104cb6 <default_check+0x5e0>
c0104ca9:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104cac:	8b 00                	mov    (%eax),%eax
c0104cae:	8b 40 04             	mov    0x4(%eax),%eax
c0104cb1:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0104cb4:	74 24                	je     c0104cda <default_check+0x604>
c0104cb6:	c7 44 24 0c 48 81 10 	movl   $0xc0108148,0xc(%esp)
c0104cbd:	c0 
c0104cbe:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104cc5:	c0 
c0104cc6:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
c0104ccd:	00 
c0104cce:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104cd5:	e8 04 c0 ff ff       	call   c0100cde <__panic>
        struct Page *p = le2page(le, page_link);
c0104cda:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104cdd:	83 e8 0c             	sub    $0xc,%eax
c0104ce0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        count --, total -= p->property;
c0104ce3:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
c0104ce7:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0104cea:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0104ced:	8b 40 08             	mov    0x8(%eax),%eax
c0104cf0:	29 c2                	sub    %eax,%edx
c0104cf2:	89 d0                	mov    %edx,%eax
c0104cf4:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104cf7:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104cfa:	89 45 88             	mov    %eax,-0x78(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0104cfd:	8b 45 88             	mov    -0x78(%ebp),%eax
c0104d00:	8b 40 04             	mov    0x4(%eax),%eax

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c0104d03:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0104d06:	81 7d ec 40 57 12 c0 	cmpl   $0xc0125740,-0x14(%ebp)
c0104d0d:	75 8d                	jne    c0104c9c <default_check+0x5c6>
        assert(le->next->prev == le && le->prev->next == le);
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
c0104d0f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0104d13:	74 24                	je     c0104d39 <default_check+0x663>
c0104d15:	c7 44 24 0c 75 81 10 	movl   $0xc0108175,0xc(%esp)
c0104d1c:	c0 
c0104d1d:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104d24:	c0 
c0104d25:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
c0104d2c:	00 
c0104d2d:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104d34:	e8 a5 bf ff ff       	call   c0100cde <__panic>
    assert(total == 0);
c0104d39:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0104d3d:	74 24                	je     c0104d63 <default_check+0x68d>
c0104d3f:	c7 44 24 0c 80 81 10 	movl   $0xc0108180,0xc(%esp)
c0104d46:	c0 
c0104d47:	c7 44 24 08 ff 7d 10 	movl   $0xc0107dff,0x8(%esp)
c0104d4e:	c0 
c0104d4f:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
c0104d56:	00 
c0104d57:	c7 04 24 14 7e 10 c0 	movl   $0xc0107e14,(%esp)
c0104d5e:	e8 7b bf ff ff       	call   c0100cde <__panic>
}
c0104d63:	81 c4 94 00 00 00    	add    $0x94,%esp
c0104d69:	5b                   	pop    %ebx
c0104d6a:	5d                   	pop    %ebp
c0104d6b:	c3                   	ret    

c0104d6c <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
c0104d6c:	55                   	push   %ebp
c0104d6d:	89 e5                	mov    %esp,%ebp
    return page - pages;
c0104d6f:	8b 55 08             	mov    0x8(%ebp),%edx
c0104d72:	a1 fc 57 12 c0       	mov    0xc01257fc,%eax
c0104d77:	29 c2                	sub    %eax,%edx
c0104d79:	89 d0                	mov    %edx,%eax
c0104d7b:	c1 f8 02             	sar    $0x2,%eax
c0104d7e:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
c0104d84:	5d                   	pop    %ebp
c0104d85:	c3                   	ret    

c0104d86 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
c0104d86:	55                   	push   %ebp
c0104d87:	89 e5                	mov    %esp,%ebp
c0104d89:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
c0104d8c:	8b 45 08             	mov    0x8(%ebp),%eax
c0104d8f:	89 04 24             	mov    %eax,(%esp)
c0104d92:	e8 d5 ff ff ff       	call   c0104d6c <page2ppn>
c0104d97:	c1 e0 0c             	shl    $0xc,%eax
}
c0104d9a:	c9                   	leave  
c0104d9b:	c3                   	ret    

c0104d9c <pa2page>:

static inline struct Page *
pa2page(uintptr_t pa) {
c0104d9c:	55                   	push   %ebp
c0104d9d:	89 e5                	mov    %esp,%ebp
c0104d9f:	83 ec 18             	sub    $0x18,%esp
    if (PPN(pa) >= npage) {
c0104da2:	8b 45 08             	mov    0x8(%ebp),%eax
c0104da5:	c1 e8 0c             	shr    $0xc,%eax
c0104da8:	89 c2                	mov    %eax,%edx
c0104daa:	a1 a0 56 12 c0       	mov    0xc01256a0,%eax
c0104daf:	39 c2                	cmp    %eax,%edx
c0104db1:	72 1c                	jb     c0104dcf <pa2page+0x33>
        panic("pa2page called with invalid pa");
c0104db3:	c7 44 24 08 bc 81 10 	movl   $0xc01081bc,0x8(%esp)
c0104dba:	c0 
c0104dbb:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
c0104dc2:	00 
c0104dc3:	c7 04 24 db 81 10 c0 	movl   $0xc01081db,(%esp)
c0104dca:	e8 0f bf ff ff       	call   c0100cde <__panic>
    }
    return &pages[PPN(pa)];
c0104dcf:	8b 0d fc 57 12 c0    	mov    0xc01257fc,%ecx
c0104dd5:	8b 45 08             	mov    0x8(%ebp),%eax
c0104dd8:	c1 e8 0c             	shr    $0xc,%eax
c0104ddb:	89 c2                	mov    %eax,%edx
c0104ddd:	89 d0                	mov    %edx,%eax
c0104ddf:	c1 e0 02             	shl    $0x2,%eax
c0104de2:	01 d0                	add    %edx,%eax
c0104de4:	c1 e0 02             	shl    $0x2,%eax
c0104de7:	01 c8                	add    %ecx,%eax
}
c0104de9:	c9                   	leave  
c0104dea:	c3                   	ret    

c0104deb <page2kva>:

static inline void *
page2kva(struct Page *page) {
c0104deb:	55                   	push   %ebp
c0104dec:	89 e5                	mov    %esp,%ebp
c0104dee:	83 ec 28             	sub    $0x28,%esp
    return KADDR(page2pa(page));
c0104df1:	8b 45 08             	mov    0x8(%ebp),%eax
c0104df4:	89 04 24             	mov    %eax,(%esp)
c0104df7:	e8 8a ff ff ff       	call   c0104d86 <page2pa>
c0104dfc:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0104dff:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104e02:	c1 e8 0c             	shr    $0xc,%eax
c0104e05:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104e08:	a1 a0 56 12 c0       	mov    0xc01256a0,%eax
c0104e0d:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c0104e10:	72 23                	jb     c0104e35 <page2kva+0x4a>
c0104e12:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104e15:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0104e19:	c7 44 24 08 ec 81 10 	movl   $0xc01081ec,0x8(%esp)
c0104e20:	c0 
c0104e21:	c7 44 24 04 61 00 00 	movl   $0x61,0x4(%esp)
c0104e28:	00 
c0104e29:	c7 04 24 db 81 10 c0 	movl   $0xc01081db,(%esp)
c0104e30:	e8 a9 be ff ff       	call   c0100cde <__panic>
c0104e35:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104e38:	2d 00 00 00 40       	sub    $0x40000000,%eax
}
c0104e3d:	c9                   	leave  
c0104e3e:	c3                   	ret    

c0104e3f <pte2page>:
kva2page(void *kva) {
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte) {
c0104e3f:	55                   	push   %ebp
c0104e40:	89 e5                	mov    %esp,%ebp
c0104e42:	83 ec 18             	sub    $0x18,%esp
    if (!(pte & PTE_P)) {
c0104e45:	8b 45 08             	mov    0x8(%ebp),%eax
c0104e48:	83 e0 01             	and    $0x1,%eax
c0104e4b:	85 c0                	test   %eax,%eax
c0104e4d:	75 1c                	jne    c0104e6b <pte2page+0x2c>
        panic("pte2page called with invalid pte");
c0104e4f:	c7 44 24 08 10 82 10 	movl   $0xc0108210,0x8(%esp)
c0104e56:	c0 
c0104e57:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
c0104e5e:	00 
c0104e5f:	c7 04 24 db 81 10 c0 	movl   $0xc01081db,(%esp)
c0104e66:	e8 73 be ff ff       	call   c0100cde <__panic>
    }
    return pa2page(PTE_ADDR(pte));
c0104e6b:	8b 45 08             	mov    0x8(%ebp),%eax
c0104e6e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0104e73:	89 04 24             	mov    %eax,(%esp)
c0104e76:	e8 21 ff ff ff       	call   c0104d9c <pa2page>
}
c0104e7b:	c9                   	leave  
c0104e7c:	c3                   	ret    

c0104e7d <pde2page>:

static inline struct Page *
pde2page(pde_t pde) {
c0104e7d:	55                   	push   %ebp
c0104e7e:	89 e5                	mov    %esp,%ebp
c0104e80:	83 ec 18             	sub    $0x18,%esp
    return pa2page(PDE_ADDR(pde));
c0104e83:	8b 45 08             	mov    0x8(%ebp),%eax
c0104e86:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0104e8b:	89 04 24             	mov    %eax,(%esp)
c0104e8e:	e8 09 ff ff ff       	call   c0104d9c <pa2page>
}
c0104e93:	c9                   	leave  
c0104e94:	c3                   	ret    

c0104e95 <page_ref>:

static inline int
page_ref(struct Page *page) {
c0104e95:	55                   	push   %ebp
c0104e96:	89 e5                	mov    %esp,%ebp
    return page->ref;
c0104e98:	8b 45 08             	mov    0x8(%ebp),%eax
c0104e9b:	8b 00                	mov    (%eax),%eax
}
c0104e9d:	5d                   	pop    %ebp
c0104e9e:	c3                   	ret    

c0104e9f <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
c0104e9f:	55                   	push   %ebp
c0104ea0:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c0104ea2:	8b 45 08             	mov    0x8(%ebp),%eax
c0104ea5:	8b 55 0c             	mov    0xc(%ebp),%edx
c0104ea8:	89 10                	mov    %edx,(%eax)
}
c0104eaa:	5d                   	pop    %ebp
c0104eab:	c3                   	ret    

c0104eac <page_ref_inc>:

static inline int
page_ref_inc(struct Page *page) {
c0104eac:	55                   	push   %ebp
c0104ead:	89 e5                	mov    %esp,%ebp
    page->ref += 1;
c0104eaf:	8b 45 08             	mov    0x8(%ebp),%eax
c0104eb2:	8b 00                	mov    (%eax),%eax
c0104eb4:	8d 50 01             	lea    0x1(%eax),%edx
c0104eb7:	8b 45 08             	mov    0x8(%ebp),%eax
c0104eba:	89 10                	mov    %edx,(%eax)
    return page->ref;
c0104ebc:	8b 45 08             	mov    0x8(%ebp),%eax
c0104ebf:	8b 00                	mov    (%eax),%eax
}
c0104ec1:	5d                   	pop    %ebp
c0104ec2:	c3                   	ret    

c0104ec3 <page_ref_dec>:

static inline int
page_ref_dec(struct Page *page) {
c0104ec3:	55                   	push   %ebp
c0104ec4:	89 e5                	mov    %esp,%ebp
    page->ref -= 1;
c0104ec6:	8b 45 08             	mov    0x8(%ebp),%eax
c0104ec9:	8b 00                	mov    (%eax),%eax
c0104ecb:	8d 50 ff             	lea    -0x1(%eax),%edx
c0104ece:	8b 45 08             	mov    0x8(%ebp),%eax
c0104ed1:	89 10                	mov    %edx,(%eax)
    return page->ref;
c0104ed3:	8b 45 08             	mov    0x8(%ebp),%eax
c0104ed6:	8b 00                	mov    (%eax),%eax
}
c0104ed8:	5d                   	pop    %ebp
c0104ed9:	c3                   	ret    

c0104eda <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
c0104eda:	55                   	push   %ebp
c0104edb:	89 e5                	mov    %esp,%ebp
c0104edd:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c0104ee0:	9c                   	pushf  
c0104ee1:	58                   	pop    %eax
c0104ee2:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c0104ee5:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
c0104ee8:	25 00 02 00 00       	and    $0x200,%eax
c0104eed:	85 c0                	test   %eax,%eax
c0104eef:	74 0c                	je     c0104efd <__intr_save+0x23>
        intr_disable();
c0104ef1:	e8 dc c7 ff ff       	call   c01016d2 <intr_disable>
        return 1;
c0104ef6:	b8 01 00 00 00       	mov    $0x1,%eax
c0104efb:	eb 05                	jmp    c0104f02 <__intr_save+0x28>
    }
    return 0;
c0104efd:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0104f02:	c9                   	leave  
c0104f03:	c3                   	ret    

c0104f04 <__intr_restore>:

static inline void
__intr_restore(bool flag) {
c0104f04:	55                   	push   %ebp
c0104f05:	89 e5                	mov    %esp,%ebp
c0104f07:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c0104f0a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0104f0e:	74 05                	je     c0104f15 <__intr_restore+0x11>
        intr_enable();
c0104f10:	e8 b7 c7 ff ff       	call   c01016cc <intr_enable>
    }
}
c0104f15:	c9                   	leave  
c0104f16:	c3                   	ret    

c0104f17 <lgdt>:
/* *
 * lgdt - load the global descriptor table register and reset the
 * data/code segement registers for kernel.
 * */
static inline void
lgdt(struct pseudodesc *pd) {
c0104f17:	55                   	push   %ebp
c0104f18:	89 e5                	mov    %esp,%ebp
    asm volatile ("lgdt (%0)" :: "r" (pd));
c0104f1a:	8b 45 08             	mov    0x8(%ebp),%eax
c0104f1d:	0f 01 10             	lgdtl  (%eax)
    asm volatile ("movw %%ax, %%gs" :: "a" (USER_DS));
c0104f20:	b8 23 00 00 00       	mov    $0x23,%eax
c0104f25:	8e e8                	mov    %eax,%gs
    asm volatile ("movw %%ax, %%fs" :: "a" (USER_DS));
c0104f27:	b8 23 00 00 00       	mov    $0x23,%eax
c0104f2c:	8e e0                	mov    %eax,%fs
    asm volatile ("movw %%ax, %%es" :: "a" (KERNEL_DS));
c0104f2e:	b8 10 00 00 00       	mov    $0x10,%eax
c0104f33:	8e c0                	mov    %eax,%es
    asm volatile ("movw %%ax, %%ds" :: "a" (KERNEL_DS));
c0104f35:	b8 10 00 00 00       	mov    $0x10,%eax
c0104f3a:	8e d8                	mov    %eax,%ds
    asm volatile ("movw %%ax, %%ss" :: "a" (KERNEL_DS));
c0104f3c:	b8 10 00 00 00       	mov    $0x10,%eax
c0104f41:	8e d0                	mov    %eax,%ss
    // reload cs
    asm volatile ("ljmp %0, $1f\n 1:\n" :: "i" (KERNEL_CS));
c0104f43:	ea 4a 4f 10 c0 08 00 	ljmp   $0x8,$0xc0104f4a
}
c0104f4a:	5d                   	pop    %ebp
c0104f4b:	c3                   	ret    

c0104f4c <load_esp0>:
 * load_esp0 - change the ESP0 in default task state segment,
 * so that we can use different kernel stack when we trap frame
 * user to kernel.
 * */
void
load_esp0(uintptr_t esp0) {
c0104f4c:	55                   	push   %ebp
c0104f4d:	89 e5                	mov    %esp,%ebp
    ts.ts_esp0 = esp0;
c0104f4f:	8b 45 08             	mov    0x8(%ebp),%eax
c0104f52:	a3 c4 56 12 c0       	mov    %eax,0xc01256c4
}
c0104f57:	5d                   	pop    %ebp
c0104f58:	c3                   	ret    

c0104f59 <gdt_init>:

/* gdt_init - initialize the default GDT and TSS */
static void
gdt_init(void) {
c0104f59:	55                   	push   %ebp
c0104f5a:	89 e5                	mov    %esp,%ebp
c0104f5c:	83 ec 14             	sub    $0x14,%esp
    // set boot kernel stack and default SS0
    load_esp0((uintptr_t)bootstacktop);
c0104f5f:	b8 00 a0 11 c0       	mov    $0xc011a000,%eax
c0104f64:	89 04 24             	mov    %eax,(%esp)
c0104f67:	e8 e0 ff ff ff       	call   c0104f4c <load_esp0>
    ts.ts_ss0 = KERNEL_DS;
c0104f6c:	66 c7 05 c8 56 12 c0 	movw   $0x10,0xc01256c8
c0104f73:	10 00 

    // initialize the TSS filed of the gdt
    gdt[SEG_TSS] = SEGTSS(STS_T32A, (uintptr_t)&ts, sizeof(ts), DPL_KERNEL);
c0104f75:	66 c7 05 28 aa 11 c0 	movw   $0x68,0xc011aa28
c0104f7c:	68 00 
c0104f7e:	b8 c0 56 12 c0       	mov    $0xc01256c0,%eax
c0104f83:	66 a3 2a aa 11 c0    	mov    %ax,0xc011aa2a
c0104f89:	b8 c0 56 12 c0       	mov    $0xc01256c0,%eax
c0104f8e:	c1 e8 10             	shr    $0x10,%eax
c0104f91:	a2 2c aa 11 c0       	mov    %al,0xc011aa2c
c0104f96:	0f b6 05 2d aa 11 c0 	movzbl 0xc011aa2d,%eax
c0104f9d:	83 e0 f0             	and    $0xfffffff0,%eax
c0104fa0:	83 c8 09             	or     $0x9,%eax
c0104fa3:	a2 2d aa 11 c0       	mov    %al,0xc011aa2d
c0104fa8:	0f b6 05 2d aa 11 c0 	movzbl 0xc011aa2d,%eax
c0104faf:	83 e0 ef             	and    $0xffffffef,%eax
c0104fb2:	a2 2d aa 11 c0       	mov    %al,0xc011aa2d
c0104fb7:	0f b6 05 2d aa 11 c0 	movzbl 0xc011aa2d,%eax
c0104fbe:	83 e0 9f             	and    $0xffffff9f,%eax
c0104fc1:	a2 2d aa 11 c0       	mov    %al,0xc011aa2d
c0104fc6:	0f b6 05 2d aa 11 c0 	movzbl 0xc011aa2d,%eax
c0104fcd:	83 c8 80             	or     $0xffffff80,%eax
c0104fd0:	a2 2d aa 11 c0       	mov    %al,0xc011aa2d
c0104fd5:	0f b6 05 2e aa 11 c0 	movzbl 0xc011aa2e,%eax
c0104fdc:	83 e0 f0             	and    $0xfffffff0,%eax
c0104fdf:	a2 2e aa 11 c0       	mov    %al,0xc011aa2e
c0104fe4:	0f b6 05 2e aa 11 c0 	movzbl 0xc011aa2e,%eax
c0104feb:	83 e0 ef             	and    $0xffffffef,%eax
c0104fee:	a2 2e aa 11 c0       	mov    %al,0xc011aa2e
c0104ff3:	0f b6 05 2e aa 11 c0 	movzbl 0xc011aa2e,%eax
c0104ffa:	83 e0 df             	and    $0xffffffdf,%eax
c0104ffd:	a2 2e aa 11 c0       	mov    %al,0xc011aa2e
c0105002:	0f b6 05 2e aa 11 c0 	movzbl 0xc011aa2e,%eax
c0105009:	83 c8 40             	or     $0x40,%eax
c010500c:	a2 2e aa 11 c0       	mov    %al,0xc011aa2e
c0105011:	0f b6 05 2e aa 11 c0 	movzbl 0xc011aa2e,%eax
c0105018:	83 e0 7f             	and    $0x7f,%eax
c010501b:	a2 2e aa 11 c0       	mov    %al,0xc011aa2e
c0105020:	b8 c0 56 12 c0       	mov    $0xc01256c0,%eax
c0105025:	c1 e8 18             	shr    $0x18,%eax
c0105028:	a2 2f aa 11 c0       	mov    %al,0xc011aa2f

    // reload all segment registers
    lgdt(&gdt_pd);
c010502d:	c7 04 24 30 aa 11 c0 	movl   $0xc011aa30,(%esp)
c0105034:	e8 de fe ff ff       	call   c0104f17 <lgdt>
c0105039:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
    asm volatile ("cli" ::: "memory");
}

static inline void
ltr(uint16_t sel) {
    asm volatile ("ltr %0" :: "r" (sel) : "memory");
c010503f:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
c0105043:	0f 00 d8             	ltr    %ax

    // load the TSS
    ltr(GD_TSS);
}
c0105046:	c9                   	leave  
c0105047:	c3                   	ret    

c0105048 <init_pmm_manager>:

//init_pmm_manager - initialize a pmm_manager instance
static void
init_pmm_manager(void) {
c0105048:	55                   	push   %ebp
c0105049:	89 e5                	mov    %esp,%ebp
c010504b:	83 ec 18             	sub    $0x18,%esp
#ifdef __DEFAULT_PMM_MANAGER__
    pmm_manager = &default_pmm_manager;
c010504e:	c7 05 f4 57 12 c0 a0 	movl   $0xc01081a0,0xc01257f4
c0105055:	81 10 c0 
#else
    pmm_manager = &buddy_pmm_manager;
#endif
    cprintf("memory management: %s\n", pmm_manager->name);
c0105058:	a1 f4 57 12 c0       	mov    0xc01257f4,%eax
c010505d:	8b 00                	mov    (%eax),%eax
c010505f:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105063:	c7 04 24 3c 82 10 c0 	movl   $0xc010823c,(%esp)
c010506a:	e8 e5 b2 ff ff       	call   c0100354 <cprintf>
    pmm_manager->init();
c010506f:	a1 f4 57 12 c0       	mov    0xc01257f4,%eax
c0105074:	8b 40 04             	mov    0x4(%eax),%eax
c0105077:	ff d0                	call   *%eax
}
c0105079:	c9                   	leave  
c010507a:	c3                   	ret    

c010507b <init_memmap>:

//init_memmap - call pmm->init_memmap to build Page struct for free memory  
static void
init_memmap(struct Page *base, size_t n) {
c010507b:	55                   	push   %ebp
c010507c:	89 e5                	mov    %esp,%ebp
c010507e:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->init_memmap(base, n);
c0105081:	a1 f4 57 12 c0       	mov    0xc01257f4,%eax
c0105086:	8b 40 08             	mov    0x8(%eax),%eax
c0105089:	8b 55 0c             	mov    0xc(%ebp),%edx
c010508c:	89 54 24 04          	mov    %edx,0x4(%esp)
c0105090:	8b 55 08             	mov    0x8(%ebp),%edx
c0105093:	89 14 24             	mov    %edx,(%esp)
c0105096:	ff d0                	call   *%eax
}
c0105098:	c9                   	leave  
c0105099:	c3                   	ret    

c010509a <alloc_pages>:

//alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory 
struct Page *
alloc_pages(size_t n) {
c010509a:	55                   	push   %ebp
c010509b:	89 e5                	mov    %esp,%ebp
c010509d:	83 ec 28             	sub    $0x28,%esp
    struct Page *page=NULL;
c01050a0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
c01050a7:	e8 2e fe ff ff       	call   c0104eda <__intr_save>
c01050ac:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        page = pmm_manager->alloc_pages(n);
c01050af:	a1 f4 57 12 c0       	mov    0xc01257f4,%eax
c01050b4:	8b 40 0c             	mov    0xc(%eax),%eax
c01050b7:	8b 55 08             	mov    0x8(%ebp),%edx
c01050ba:	89 14 24             	mov    %edx,(%esp)
c01050bd:	ff d0                	call   *%eax
c01050bf:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }
    local_intr_restore(intr_flag);
c01050c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01050c5:	89 04 24             	mov    %eax,(%esp)
c01050c8:	e8 37 fe ff ff       	call   c0104f04 <__intr_restore>
    return page;
c01050cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01050d0:	c9                   	leave  
c01050d1:	c3                   	ret    

c01050d2 <free_pages>:

//free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory 
void
free_pages(struct Page *base, size_t n) {
c01050d2:	55                   	push   %ebp
c01050d3:	89 e5                	mov    %esp,%ebp
c01050d5:	83 ec 28             	sub    $0x28,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
c01050d8:	e8 fd fd ff ff       	call   c0104eda <__intr_save>
c01050dd:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        pmm_manager->free_pages(base, n);
c01050e0:	a1 f4 57 12 c0       	mov    0xc01257f4,%eax
c01050e5:	8b 40 10             	mov    0x10(%eax),%eax
c01050e8:	8b 55 0c             	mov    0xc(%ebp),%edx
c01050eb:	89 54 24 04          	mov    %edx,0x4(%esp)
c01050ef:	8b 55 08             	mov    0x8(%ebp),%edx
c01050f2:	89 14 24             	mov    %edx,(%esp)
c01050f5:	ff d0                	call   *%eax
    }
    local_intr_restore(intr_flag);
c01050f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01050fa:	89 04 24             	mov    %eax,(%esp)
c01050fd:	e8 02 fe ff ff       	call   c0104f04 <__intr_restore>
}
c0105102:	c9                   	leave  
c0105103:	c3                   	ret    

c0105104 <nr_free_pages>:

//nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE) 
//of current free memory
size_t
nr_free_pages(void) {
c0105104:	55                   	push   %ebp
c0105105:	89 e5                	mov    %esp,%ebp
c0105107:	83 ec 28             	sub    $0x28,%esp
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
c010510a:	e8 cb fd ff ff       	call   c0104eda <__intr_save>
c010510f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        ret = pmm_manager->nr_free_pages();
c0105112:	a1 f4 57 12 c0       	mov    0xc01257f4,%eax
c0105117:	8b 40 14             	mov    0x14(%eax),%eax
c010511a:	ff d0                	call   *%eax
c010511c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    }
    local_intr_restore(intr_flag);
c010511f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105122:	89 04 24             	mov    %eax,(%esp)
c0105125:	e8 da fd ff ff       	call   c0104f04 <__intr_restore>
    return ret;
c010512a:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
c010512d:	c9                   	leave  
c010512e:	c3                   	ret    

c010512f <page_init>:

/* pmm_init - initialize the physical memory management */
static void
page_init(void) {
c010512f:	55                   	push   %ebp
c0105130:	89 e5                	mov    %esp,%ebp
c0105132:	57                   	push   %edi
c0105133:	56                   	push   %esi
c0105134:	53                   	push   %ebx
c0105135:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
c010513b:	c7 45 c4 00 80 00 c0 	movl   $0xc0008000,-0x3c(%ebp)
    uint64_t maxpa = 0;
c0105142:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
c0105149:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

    cprintf("e820map:\n");
c0105150:	c7 04 24 53 82 10 c0 	movl   $0xc0108253,(%esp)
c0105157:	e8 f8 b1 ff ff       	call   c0100354 <cprintf>
    // 检测出内存能用的最大物理地址
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
c010515c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0105163:	e9 15 01 00 00       	jmp    c010527d <page_init+0x14e>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
c0105168:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c010516b:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010516e:	89 d0                	mov    %edx,%eax
c0105170:	c1 e0 02             	shl    $0x2,%eax
c0105173:	01 d0                	add    %edx,%eax
c0105175:	c1 e0 02             	shl    $0x2,%eax
c0105178:	01 c8                	add    %ecx,%eax
c010517a:	8b 50 08             	mov    0x8(%eax),%edx
c010517d:	8b 40 04             	mov    0x4(%eax),%eax
c0105180:	89 45 b8             	mov    %eax,-0x48(%ebp)
c0105183:	89 55 bc             	mov    %edx,-0x44(%ebp)
c0105186:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0105189:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010518c:	89 d0                	mov    %edx,%eax
c010518e:	c1 e0 02             	shl    $0x2,%eax
c0105191:	01 d0                	add    %edx,%eax
c0105193:	c1 e0 02             	shl    $0x2,%eax
c0105196:	01 c8                	add    %ecx,%eax
c0105198:	8b 48 0c             	mov    0xc(%eax),%ecx
c010519b:	8b 58 10             	mov    0x10(%eax),%ebx
c010519e:	8b 45 b8             	mov    -0x48(%ebp),%eax
c01051a1:	8b 55 bc             	mov    -0x44(%ebp),%edx
c01051a4:	01 c8                	add    %ecx,%eax
c01051a6:	11 da                	adc    %ebx,%edx
c01051a8:	89 45 b0             	mov    %eax,-0x50(%ebp)
c01051ab:	89 55 b4             	mov    %edx,-0x4c(%ebp)
        cprintf("  memory: %08llx, [%08llx, %08llx], type = %d.\n",
c01051ae:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c01051b1:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01051b4:	89 d0                	mov    %edx,%eax
c01051b6:	c1 e0 02             	shl    $0x2,%eax
c01051b9:	01 d0                	add    %edx,%eax
c01051bb:	c1 e0 02             	shl    $0x2,%eax
c01051be:	01 c8                	add    %ecx,%eax
c01051c0:	83 c0 14             	add    $0x14,%eax
c01051c3:	8b 00                	mov    (%eax),%eax
c01051c5:	89 85 7c ff ff ff    	mov    %eax,-0x84(%ebp)
c01051cb:	8b 45 b0             	mov    -0x50(%ebp),%eax
c01051ce:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c01051d1:	83 c0 ff             	add    $0xffffffff,%eax
c01051d4:	83 d2 ff             	adc    $0xffffffff,%edx
c01051d7:	89 c6                	mov    %eax,%esi
c01051d9:	89 d7                	mov    %edx,%edi
c01051db:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c01051de:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01051e1:	89 d0                	mov    %edx,%eax
c01051e3:	c1 e0 02             	shl    $0x2,%eax
c01051e6:	01 d0                	add    %edx,%eax
c01051e8:	c1 e0 02             	shl    $0x2,%eax
c01051eb:	01 c8                	add    %ecx,%eax
c01051ed:	8b 48 0c             	mov    0xc(%eax),%ecx
c01051f0:	8b 58 10             	mov    0x10(%eax),%ebx
c01051f3:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
c01051f9:	89 44 24 1c          	mov    %eax,0x1c(%esp)
c01051fd:	89 74 24 14          	mov    %esi,0x14(%esp)
c0105201:	89 7c 24 18          	mov    %edi,0x18(%esp)
c0105205:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0105208:	8b 55 bc             	mov    -0x44(%ebp),%edx
c010520b:	89 44 24 0c          	mov    %eax,0xc(%esp)
c010520f:	89 54 24 10          	mov    %edx,0x10(%esp)
c0105213:	89 4c 24 04          	mov    %ecx,0x4(%esp)
c0105217:	89 5c 24 08          	mov    %ebx,0x8(%esp)
c010521b:	c7 04 24 60 82 10 c0 	movl   $0xc0108260,(%esp)
c0105222:	e8 2d b1 ff ff       	call   c0100354 <cprintf>
                memmap->map[i].size, begin, end - 1, memmap->map[i].type);
        if (memmap->map[i].type == E820_ARM) {
c0105227:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c010522a:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010522d:	89 d0                	mov    %edx,%eax
c010522f:	c1 e0 02             	shl    $0x2,%eax
c0105232:	01 d0                	add    %edx,%eax
c0105234:	c1 e0 02             	shl    $0x2,%eax
c0105237:	01 c8                	add    %ecx,%eax
c0105239:	83 c0 14             	add    $0x14,%eax
c010523c:	8b 00                	mov    (%eax),%eax
c010523e:	83 f8 01             	cmp    $0x1,%eax
c0105241:	75 36                	jne    c0105279 <page_init+0x14a>
            if (maxpa < end && begin < KMEMSIZE) {
c0105243:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105246:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0105249:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
c010524c:	77 2b                	ja     c0105279 <page_init+0x14a>
c010524e:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
c0105251:	72 05                	jb     c0105258 <page_init+0x129>
c0105253:	3b 45 b0             	cmp    -0x50(%ebp),%eax
c0105256:	73 21                	jae    c0105279 <page_init+0x14a>
c0105258:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
c010525c:	77 1b                	ja     c0105279 <page_init+0x14a>
c010525e:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
c0105262:	72 09                	jb     c010526d <page_init+0x13e>
c0105264:	81 7d b8 ff ff ff 37 	cmpl   $0x37ffffff,-0x48(%ebp)
c010526b:	77 0c                	ja     c0105279 <page_init+0x14a>
                maxpa = end;
c010526d:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0105270:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0105273:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0105276:	89 55 e4             	mov    %edx,-0x1c(%ebp)
    uint64_t maxpa = 0;

    cprintf("e820map:\n");
    // 检测出内存能用的最大物理地址
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
c0105279:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
c010527d:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0105280:	8b 00                	mov    (%eax),%eax
c0105282:	3b 45 dc             	cmp    -0x24(%ebp),%eax
c0105285:	0f 8f dd fe ff ff    	jg     c0105168 <page_init+0x39>
            if (maxpa < end && begin < KMEMSIZE) {
                maxpa = end;
            }
        }
    }
    if (maxpa > KMEMSIZE) {
c010528b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c010528f:	72 1d                	jb     c01052ae <page_init+0x17f>
c0105291:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0105295:	77 09                	ja     c01052a0 <page_init+0x171>
c0105297:	81 7d e0 00 00 00 38 	cmpl   $0x38000000,-0x20(%ebp)
c010529e:	76 0e                	jbe    c01052ae <page_init+0x17f>
        maxpa = KMEMSIZE;
c01052a0:	c7 45 e0 00 00 00 38 	movl   $0x38000000,-0x20(%ebp)
c01052a7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    }

    extern char end[];

    npage = maxpa / PGSIZE;
c01052ae:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01052b1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01052b4:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c01052b8:	c1 ea 0c             	shr    $0xc,%edx
c01052bb:	a3 a0 56 12 c0       	mov    %eax,0xc01256a0
    // 内核之后就是pages结构体数组
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
c01052c0:	c7 45 ac 00 10 00 00 	movl   $0x1000,-0x54(%ebp)
c01052c7:	b8 00 58 12 c0       	mov    $0xc0125800,%eax
c01052cc:	8d 50 ff             	lea    -0x1(%eax),%edx
c01052cf:	8b 45 ac             	mov    -0x54(%ebp),%eax
c01052d2:	01 d0                	add    %edx,%eax
c01052d4:	89 45 a8             	mov    %eax,-0x58(%ebp)
c01052d7:	8b 45 a8             	mov    -0x58(%ebp),%eax
c01052da:	ba 00 00 00 00       	mov    $0x0,%edx
c01052df:	f7 75 ac             	divl   -0x54(%ebp)
c01052e2:	89 d0                	mov    %edx,%eax
c01052e4:	8b 55 a8             	mov    -0x58(%ebp),%edx
c01052e7:	29 c2                	sub    %eax,%edx
c01052e9:	89 d0                	mov    %edx,%eax
c01052eb:	a3 fc 57 12 c0       	mov    %eax,0xc01257fc

    for (i = 0; i < npage; i ++) {
c01052f0:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c01052f7:	eb 2f                	jmp    c0105328 <page_init+0x1f9>
        SetPageReserved(pages + i);
c01052f9:	8b 0d fc 57 12 c0    	mov    0xc01257fc,%ecx
c01052ff:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0105302:	89 d0                	mov    %edx,%eax
c0105304:	c1 e0 02             	shl    $0x2,%eax
c0105307:	01 d0                	add    %edx,%eax
c0105309:	c1 e0 02             	shl    $0x2,%eax
c010530c:	01 c8                	add    %ecx,%eax
c010530e:	83 c0 04             	add    $0x4,%eax
c0105311:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
c0105318:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c010531b:	8b 45 8c             	mov    -0x74(%ebp),%eax
c010531e:	8b 55 90             	mov    -0x70(%ebp),%edx
c0105321:	0f ab 10             	bts    %edx,(%eax)

    npage = maxpa / PGSIZE;
    // 内核之后就是pages结构体数组
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    for (i = 0; i < npage; i ++) {
c0105324:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
c0105328:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010532b:	a1 a0 56 12 c0       	mov    0xc01256a0,%eax
c0105330:	39 c2                	cmp    %eax,%edx
c0105332:	72 c5                	jb     c01052f9 <page_init+0x1ca>
        SetPageReserved(pages + i);
    }

    // 相当于最小能用的物理地址
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);
c0105334:	8b 15 a0 56 12 c0    	mov    0xc01256a0,%edx
c010533a:	89 d0                	mov    %edx,%eax
c010533c:	c1 e0 02             	shl    $0x2,%eax
c010533f:	01 d0                	add    %edx,%eax
c0105341:	c1 e0 02             	shl    $0x2,%eax
c0105344:	89 c2                	mov    %eax,%edx
c0105346:	a1 fc 57 12 c0       	mov    0xc01257fc,%eax
c010534b:	01 d0                	add    %edx,%eax
c010534d:	89 45 a4             	mov    %eax,-0x5c(%ebp)
c0105350:	81 7d a4 ff ff ff bf 	cmpl   $0xbfffffff,-0x5c(%ebp)
c0105357:	77 23                	ja     c010537c <page_init+0x24d>
c0105359:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c010535c:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0105360:	c7 44 24 08 90 82 10 	movl   $0xc0108290,0x8(%esp)
c0105367:	c0 
c0105368:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
c010536f:	00 
c0105370:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105377:	e8 62 b9 ff ff       	call   c0100cde <__panic>
c010537c:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c010537f:	05 00 00 00 40       	add    $0x40000000,%eax
c0105384:	89 45 a0             	mov    %eax,-0x60(%ebp)
    cprintf("freemem low addr: %x, high addr: %x\n", freemem, KMEMSIZE);
c0105387:	c7 44 24 08 00 00 00 	movl   $0x38000000,0x8(%esp)
c010538e:	38 
c010538f:	8b 45 a0             	mov    -0x60(%ebp),%eax
c0105392:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105396:	c7 04 24 c4 82 10 c0 	movl   $0xc01082c4,(%esp)
c010539d:	e8 b2 af ff ff       	call   c0100354 <cprintf>
    for (i = 0; i < memmap->nr_map; i ++) {
c01053a2:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c01053a9:	e9 74 01 00 00       	jmp    c0105522 <page_init+0x3f3>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
c01053ae:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c01053b1:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01053b4:	89 d0                	mov    %edx,%eax
c01053b6:	c1 e0 02             	shl    $0x2,%eax
c01053b9:	01 d0                	add    %edx,%eax
c01053bb:	c1 e0 02             	shl    $0x2,%eax
c01053be:	01 c8                	add    %ecx,%eax
c01053c0:	8b 50 08             	mov    0x8(%eax),%edx
c01053c3:	8b 40 04             	mov    0x4(%eax),%eax
c01053c6:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01053c9:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c01053cc:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c01053cf:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01053d2:	89 d0                	mov    %edx,%eax
c01053d4:	c1 e0 02             	shl    $0x2,%eax
c01053d7:	01 d0                	add    %edx,%eax
c01053d9:	c1 e0 02             	shl    $0x2,%eax
c01053dc:	01 c8                	add    %ecx,%eax
c01053de:	8b 48 0c             	mov    0xc(%eax),%ecx
c01053e1:	8b 58 10             	mov    0x10(%eax),%ebx
c01053e4:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01053e7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01053ea:	01 c8                	add    %ecx,%eax
c01053ec:	11 da                	adc    %ebx,%edx
c01053ee:	89 45 c8             	mov    %eax,-0x38(%ebp)
c01053f1:	89 55 cc             	mov    %edx,-0x34(%ebp)
        if (memmap->map[i].type == E820_ARM) {
c01053f4:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c01053f7:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01053fa:	89 d0                	mov    %edx,%eax
c01053fc:	c1 e0 02             	shl    $0x2,%eax
c01053ff:	01 d0                	add    %edx,%eax
c0105401:	c1 e0 02             	shl    $0x2,%eax
c0105404:	01 c8                	add    %ecx,%eax
c0105406:	83 c0 14             	add    $0x14,%eax
c0105409:	8b 00                	mov    (%eax),%eax
c010540b:	83 f8 01             	cmp    $0x1,%eax
c010540e:	0f 85 0a 01 00 00    	jne    c010551e <page_init+0x3ef>
            if (begin < freemem) {
c0105414:	8b 45 a0             	mov    -0x60(%ebp),%eax
c0105417:	ba 00 00 00 00       	mov    $0x0,%edx
c010541c:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c010541f:	72 17                	jb     c0105438 <page_init+0x309>
c0105421:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0105424:	77 05                	ja     c010542b <page_init+0x2fc>
c0105426:	3b 45 d0             	cmp    -0x30(%ebp),%eax
c0105429:	76 0d                	jbe    c0105438 <page_init+0x309>
                begin = freemem;
c010542b:	8b 45 a0             	mov    -0x60(%ebp),%eax
c010542e:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0105431:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
            }
            if (end > KMEMSIZE) {
c0105438:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c010543c:	72 1d                	jb     c010545b <page_init+0x32c>
c010543e:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c0105442:	77 09                	ja     c010544d <page_init+0x31e>
c0105444:	81 7d c8 00 00 00 38 	cmpl   $0x38000000,-0x38(%ebp)
c010544b:	76 0e                	jbe    c010545b <page_init+0x32c>
                end = KMEMSIZE;
c010544d:	c7 45 c8 00 00 00 38 	movl   $0x38000000,-0x38(%ebp)
c0105454:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
            }
            if (begin < end) {
c010545b:	8b 45 d0             	mov    -0x30(%ebp),%eax
c010545e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0105461:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0105464:	0f 87 b4 00 00 00    	ja     c010551e <page_init+0x3ef>
c010546a:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c010546d:	72 09                	jb     c0105478 <page_init+0x349>
c010546f:	3b 45 c8             	cmp    -0x38(%ebp),%eax
c0105472:	0f 83 a6 00 00 00    	jae    c010551e <page_init+0x3ef>
                begin = ROUNDUP(begin, PGSIZE);
c0105478:	c7 45 9c 00 10 00 00 	movl   $0x1000,-0x64(%ebp)
c010547f:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0105482:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0105485:	01 d0                	add    %edx,%eax
c0105487:	83 e8 01             	sub    $0x1,%eax
c010548a:	89 45 98             	mov    %eax,-0x68(%ebp)
c010548d:	8b 45 98             	mov    -0x68(%ebp),%eax
c0105490:	ba 00 00 00 00       	mov    $0x0,%edx
c0105495:	f7 75 9c             	divl   -0x64(%ebp)
c0105498:	89 d0                	mov    %edx,%eax
c010549a:	8b 55 98             	mov    -0x68(%ebp),%edx
c010549d:	29 c2                	sub    %eax,%edx
c010549f:	89 d0                	mov    %edx,%eax
c01054a1:	ba 00 00 00 00       	mov    $0x0,%edx
c01054a6:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01054a9:	89 55 d4             	mov    %edx,-0x2c(%ebp)
                end = ROUNDDOWN(end, PGSIZE);
c01054ac:	8b 45 c8             	mov    -0x38(%ebp),%eax
c01054af:	89 45 94             	mov    %eax,-0x6c(%ebp)
c01054b2:	8b 45 94             	mov    -0x6c(%ebp),%eax
c01054b5:	ba 00 00 00 00       	mov    $0x0,%edx
c01054ba:	89 c7                	mov    %eax,%edi
c01054bc:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
c01054c2:	89 7d 80             	mov    %edi,-0x80(%ebp)
c01054c5:	89 d0                	mov    %edx,%eax
c01054c7:	83 e0 00             	and    $0x0,%eax
c01054ca:	89 45 84             	mov    %eax,-0x7c(%ebp)
c01054cd:	8b 45 80             	mov    -0x80(%ebp),%eax
c01054d0:	8b 55 84             	mov    -0x7c(%ebp),%edx
c01054d3:	89 45 c8             	mov    %eax,-0x38(%ebp)
c01054d6:	89 55 cc             	mov    %edx,-0x34(%ebp)
                if (begin < end) {
c01054d9:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01054dc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01054df:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c01054e2:	77 3a                	ja     c010551e <page_init+0x3ef>
c01054e4:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c01054e7:	72 05                	jb     c01054ee <page_init+0x3bf>
c01054e9:	3b 45 c8             	cmp    -0x38(%ebp),%eax
c01054ec:	73 30                	jae    c010551e <page_init+0x3ef>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
c01054ee:	8b 4d d0             	mov    -0x30(%ebp),%ecx
c01054f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
c01054f4:	8b 45 c8             	mov    -0x38(%ebp),%eax
c01054f7:	8b 55 cc             	mov    -0x34(%ebp),%edx
c01054fa:	29 c8                	sub    %ecx,%eax
c01054fc:	19 da                	sbb    %ebx,%edx
c01054fe:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c0105502:	c1 ea 0c             	shr    $0xc,%edx
c0105505:	89 c3                	mov    %eax,%ebx
c0105507:	8b 45 d0             	mov    -0x30(%ebp),%eax
c010550a:	89 04 24             	mov    %eax,(%esp)
c010550d:	e8 8a f8 ff ff       	call   c0104d9c <pa2page>
c0105512:	89 5c 24 04          	mov    %ebx,0x4(%esp)
c0105516:	89 04 24             	mov    %eax,(%esp)
c0105519:	e8 5d fb ff ff       	call   c010507b <init_memmap>
    }

    // 相当于最小能用的物理地址
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);
    cprintf("freemem low addr: %x, high addr: %x\n", freemem, KMEMSIZE);
    for (i = 0; i < memmap->nr_map; i ++) {
c010551e:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
c0105522:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0105525:	8b 00                	mov    (%eax),%eax
c0105527:	3b 45 dc             	cmp    -0x24(%ebp),%eax
c010552a:	0f 8f 7e fe ff ff    	jg     c01053ae <page_init+0x27f>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
                }
            }
        }
    }
}
c0105530:	81 c4 9c 00 00 00    	add    $0x9c,%esp
c0105536:	5b                   	pop    %ebx
c0105537:	5e                   	pop    %esi
c0105538:	5f                   	pop    %edi
c0105539:	5d                   	pop    %ebp
c010553a:	c3                   	ret    

c010553b <boot_map_segment>:
//  la:   linear address of this memory need to map (after x86 segment map)
//  size: memory size
//  pa:   physical address of this memory
//  perm: permission of this memory  
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
c010553b:	55                   	push   %ebp
c010553c:	89 e5                	mov    %esp,%ebp
c010553e:	83 ec 38             	sub    $0x38,%esp
    assert(PGOFF(la) == PGOFF(pa));
c0105541:	8b 45 14             	mov    0x14(%ebp),%eax
c0105544:	8b 55 0c             	mov    0xc(%ebp),%edx
c0105547:	31 d0                	xor    %edx,%eax
c0105549:	25 ff 0f 00 00       	and    $0xfff,%eax
c010554e:	85 c0                	test   %eax,%eax
c0105550:	74 24                	je     c0105576 <boot_map_segment+0x3b>
c0105552:	c7 44 24 0c e9 82 10 	movl   $0xc01082e9,0xc(%esp)
c0105559:	c0 
c010555a:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105561:	c0 
c0105562:	c7 44 24 04 06 01 00 	movl   $0x106,0x4(%esp)
c0105569:	00 
c010556a:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105571:	e8 68 b7 ff ff       	call   c0100cde <__panic>
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
c0105576:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
c010557d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105580:	25 ff 0f 00 00       	and    $0xfff,%eax
c0105585:	89 c2                	mov    %eax,%edx
c0105587:	8b 45 10             	mov    0x10(%ebp),%eax
c010558a:	01 c2                	add    %eax,%edx
c010558c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010558f:	01 d0                	add    %edx,%eax
c0105591:	83 e8 01             	sub    $0x1,%eax
c0105594:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105597:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010559a:	ba 00 00 00 00       	mov    $0x0,%edx
c010559f:	f7 75 f0             	divl   -0x10(%ebp)
c01055a2:	89 d0                	mov    %edx,%eax
c01055a4:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01055a7:	29 c2                	sub    %eax,%edx
c01055a9:	89 d0                	mov    %edx,%eax
c01055ab:	c1 e8 0c             	shr    $0xc,%eax
c01055ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
    la = ROUNDDOWN(la, PGSIZE);
c01055b1:	8b 45 0c             	mov    0xc(%ebp),%eax
c01055b4:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01055b7:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01055ba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c01055bf:	89 45 0c             	mov    %eax,0xc(%ebp)
    pa = ROUNDDOWN(pa, PGSIZE);
c01055c2:	8b 45 14             	mov    0x14(%ebp),%eax
c01055c5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01055c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01055cb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c01055d0:	89 45 14             	mov    %eax,0x14(%ebp)
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
c01055d3:	eb 6b                	jmp    c0105640 <boot_map_segment+0x105>
        pte_t *ptep = get_pte(pgdir, la, 1);
c01055d5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
c01055dc:	00 
c01055dd:	8b 45 0c             	mov    0xc(%ebp),%eax
c01055e0:	89 44 24 04          	mov    %eax,0x4(%esp)
c01055e4:	8b 45 08             	mov    0x8(%ebp),%eax
c01055e7:	89 04 24             	mov    %eax,(%esp)
c01055ea:	e8 82 01 00 00       	call   c0105771 <get_pte>
c01055ef:	89 45 e0             	mov    %eax,-0x20(%ebp)
        assert(ptep != NULL);
c01055f2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c01055f6:	75 24                	jne    c010561c <boot_map_segment+0xe1>
c01055f8:	c7 44 24 0c 15 83 10 	movl   $0xc0108315,0xc(%esp)
c01055ff:	c0 
c0105600:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105607:	c0 
c0105608:	c7 44 24 04 0c 01 00 	movl   $0x10c,0x4(%esp)
c010560f:	00 
c0105610:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105617:	e8 c2 b6 ff ff       	call   c0100cde <__panic>
        *ptep = pa | PTE_P | perm;
c010561c:	8b 45 18             	mov    0x18(%ebp),%eax
c010561f:	8b 55 14             	mov    0x14(%ebp),%edx
c0105622:	09 d0                	or     %edx,%eax
c0105624:	83 c8 01             	or     $0x1,%eax
c0105627:	89 c2                	mov    %eax,%edx
c0105629:	8b 45 e0             	mov    -0x20(%ebp),%eax
c010562c:	89 10                	mov    %edx,(%eax)
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
    assert(PGOFF(la) == PGOFF(pa));
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
c010562e:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
c0105632:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
c0105639:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
c0105640:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0105644:	75 8f                	jne    c01055d5 <boot_map_segment+0x9a>
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pa | PTE_P | perm;
    }
}
c0105646:	c9                   	leave  
c0105647:	c3                   	ret    

c0105648 <boot_alloc_page>:

//boot_alloc_page - allocate one page using pmm->alloc_pages(1) 
// return value: the kernel virtual address of this allocated page
//note: this function is used to get the memory for PDT(Page Directory Table)&PT(Page Table)
static void *
boot_alloc_page(void) {
c0105648:	55                   	push   %ebp
c0105649:	89 e5                	mov    %esp,%ebp
c010564b:	83 ec 28             	sub    $0x28,%esp
    struct Page *p = alloc_page();
c010564e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0105655:	e8 40 fa ff ff       	call   c010509a <alloc_pages>
c010565a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (p == NULL) {
c010565d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0105661:	75 1c                	jne    c010567f <boot_alloc_page+0x37>
        panic("boot_alloc_page failed.\n");
c0105663:	c7 44 24 08 22 83 10 	movl   $0xc0108322,0x8(%esp)
c010566a:	c0 
c010566b:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
c0105672:	00 
c0105673:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c010567a:	e8 5f b6 ff ff       	call   c0100cde <__panic>
    }
    return page2kva(p);
c010567f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105682:	89 04 24             	mov    %eax,(%esp)
c0105685:	e8 61 f7 ff ff       	call   c0104deb <page2kva>
}
c010568a:	c9                   	leave  
c010568b:	c3                   	ret    

c010568c <pmm_init>:

//pmm_init - setup a pmm to manage physical memory, build PDT&PT to setup paging mechanism 
//         - check the correctness of pmm & paging mechanism, print PDT&PT
void
pmm_init(void) {
c010568c:	55                   	push   %ebp
c010568d:	89 e5                	mov    %esp,%ebp
c010568f:	83 ec 38             	sub    $0x38,%esp
    // We've already enabled paging
    boot_cr3 = PADDR(boot_pgdir);
c0105692:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0105697:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010569a:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
c01056a1:	77 23                	ja     c01056c6 <pmm_init+0x3a>
c01056a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01056a6:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01056aa:	c7 44 24 08 90 82 10 	movl   $0xc0108290,0x8(%esp)
c01056b1:	c0 
c01056b2:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
c01056b9:	00 
c01056ba:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c01056c1:	e8 18 b6 ff ff       	call   c0100cde <__panic>
c01056c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01056c9:	05 00 00 00 40       	add    $0x40000000,%eax
c01056ce:	a3 f8 57 12 c0       	mov    %eax,0xc01257f8
    //We need to alloc/free the physical memory (granularity is 4KB or other size). 
    //So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    //First we should init a physical memory manager(pmm) based on the framework.
    //Then pmm can alloc/free the physical memory. 
    //Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();
c01056d3:	e8 70 f9 ff ff       	call   c0105048 <init_pmm_manager>

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();
c01056d8:	e8 52 fa ff ff       	call   c010512f <page_init>

    //use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();
c01056dd:	e8 21 04 00 00       	call   c0105b03 <check_alloc_page>

    check_pgdir();
c01056e2:	e8 3a 04 00 00       	call   c0105b21 <check_pgdir>

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // recursively insert boot_pgdir in itself
    // to form a virtual page table at virtual address VPT
    boot_pgdir[PDX(VPT)] = PADDR(boot_pgdir) | PTE_P | PTE_W;
c01056e7:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c01056ec:	8d 90 ac 0f 00 00    	lea    0xfac(%eax),%edx
c01056f2:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c01056f7:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01056fa:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
c0105701:	77 23                	ja     c0105726 <pmm_init+0x9a>
c0105703:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105706:	89 44 24 0c          	mov    %eax,0xc(%esp)
c010570a:	c7 44 24 08 90 82 10 	movl   $0xc0108290,0x8(%esp)
c0105711:	c0 
c0105712:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
c0105719:	00 
c010571a:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105721:	e8 b8 b5 ff ff       	call   c0100cde <__panic>
c0105726:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105729:	05 00 00 00 40       	add    $0x40000000,%eax
c010572e:	83 c8 03             	or     $0x3,%eax
c0105731:	89 02                	mov    %eax,(%edx)

    // map all physical memory to linear memory with base linear addr KERNBASE
    // linear_addr KERNBASE ~ KERNBASE + KMEMSIZE = phy_addr 0 ~ KMEMSIZE
    boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, 0, PTE_W);
c0105733:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0105738:	c7 44 24 10 02 00 00 	movl   $0x2,0x10(%esp)
c010573f:	00 
c0105740:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
c0105747:	00 
c0105748:	c7 44 24 08 00 00 00 	movl   $0x38000000,0x8(%esp)
c010574f:	38 
c0105750:	c7 44 24 04 00 00 00 	movl   $0xc0000000,0x4(%esp)
c0105757:	c0 
c0105758:	89 04 24             	mov    %eax,(%esp)
c010575b:	e8 db fd ff ff       	call   c010553b <boot_map_segment>

    // Since we are using bootloader's GDT,
    // we should reload gdt (second time, the last time) to get user segments and the TSS
    // map virtual_addr 0 ~ 4G = linear_addr 0 ~ 4G
    // then set kernel stack (ss:esp) in TSS, setup TSS in gdt, load TSS
    gdt_init();
c0105760:	e8 f4 f7 ff ff       	call   c0104f59 <gdt_init>

    //now the basic virtual memory map(see memalyout.h) is established.
    //check the correctness of the basic virtual memory map.
    check_boot_pgdir();
c0105765:	e8 52 0a 00 00       	call   c01061bc <check_boot_pgdir>

    print_pgdir();
c010576a:	e8 da 0e 00 00       	call   c0106649 <print_pgdir>

}
c010576f:	c9                   	leave  
c0105770:	c3                   	ret    

c0105771 <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *
get_pte(pde_t *pgdir, uintptr_t la, bool create) {
c0105771:	55                   	push   %ebp
c0105772:	89 e5                	mov    %esp,%ebp
c0105774:	83 ec 48             	sub    $0x48,%esp
    }
    return NULL;          // (8) return page table entry
#endif
    // 注意页目录表和页表存的都是物理地址，（如果是虚拟地址的话陷入循环了）
    // 但是操作系统代码里要虚拟地址，CPU可以帮忙转
    pte_t *result = NULL;
c0105777:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    pde_t *pdep = &pgdir[PDX(la)];
c010577e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105781:	c1 e8 16             	shr    $0x16,%eax
c0105784:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c010578b:	8b 45 08             	mov    0x8(%ebp),%eax
c010578e:	01 d0                	add    %edx,%eax
c0105790:	89 45 e8             	mov    %eax,-0x18(%ebp)
    pte_t *pte_base = NULL;
c0105793:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    struct Page *page;
    bool find_pte = 1;
c010579a:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
    if (*pdep & PTE_P) { //存在对应的页表
c01057a1:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01057a4:	8b 00                	mov    (%eax),%eax
c01057a6:	83 e0 01             	and    $0x1,%eax
c01057a9:	85 c0                	test   %eax,%eax
c01057ab:	74 53                	je     c0105800 <get_pte+0x8f>
        pte_base = KADDR(*pdep & ~0xFFF); 
c01057ad:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01057b0:	8b 00                	mov    (%eax),%eax
c01057b2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c01057b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01057ba:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01057bd:	c1 e8 0c             	shr    $0xc,%eax
c01057c0:	89 45 e0             	mov    %eax,-0x20(%ebp)
c01057c3:	a1 a0 56 12 c0       	mov    0xc01256a0,%eax
c01057c8:	39 45 e0             	cmp    %eax,-0x20(%ebp)
c01057cb:	72 23                	jb     c01057f0 <get_pte+0x7f>
c01057cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01057d0:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01057d4:	c7 44 24 08 ec 81 10 	movl   $0xc01081ec,0x8(%esp)
c01057db:	c0 
c01057dc:	c7 44 24 04 7d 01 00 	movl   $0x17d,0x4(%esp)
c01057e3:	00 
c01057e4:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c01057eb:	e8 ee b4 ff ff       	call   c0100cde <__panic>
c01057f0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01057f3:	2d 00 00 00 40       	sub    $0x40000000,%eax
c01057f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01057fb:	e9 c2 00 00 00       	jmp    c01058c2 <get_pte+0x151>
    } 
    else if (create && (page = alloc_page()) != NULL) { //不存在对应的页表，但允许分配
c0105800:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0105804:	0f 84 b1 00 00 00    	je     c01058bb <get_pte+0x14a>
c010580a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0105811:	e8 84 f8 ff ff       	call   c010509a <alloc_pages>
c0105816:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0105819:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c010581d:	0f 84 98 00 00 00    	je     c01058bb <get_pte+0x14a>
        set_page_ref(page, 1);
c0105823:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c010582a:	00 
c010582b:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010582e:	89 04 24             	mov    %eax,(%esp)
c0105831:	e8 69 f6 ff ff       	call   c0104e9f <set_page_ref>
        *pdep = page2pa(page);
c0105836:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105839:	89 04 24             	mov    %eax,(%esp)
c010583c:	e8 45 f5 ff ff       	call   c0104d86 <page2pa>
c0105841:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0105844:	89 02                	mov    %eax,(%edx)
        pte_base = KADDR(*pdep);
c0105846:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105849:	8b 00                	mov    (%eax),%eax
c010584b:	89 45 d8             	mov    %eax,-0x28(%ebp)
c010584e:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0105851:	c1 e8 0c             	shr    $0xc,%eax
c0105854:	89 45 d4             	mov    %eax,-0x2c(%ebp)
c0105857:	a1 a0 56 12 c0       	mov    0xc01256a0,%eax
c010585c:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
c010585f:	72 23                	jb     c0105884 <get_pte+0x113>
c0105861:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0105864:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0105868:	c7 44 24 08 ec 81 10 	movl   $0xc01081ec,0x8(%esp)
c010586f:	c0 
c0105870:	c7 44 24 04 82 01 00 	movl   $0x182,0x4(%esp)
c0105877:	00 
c0105878:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c010587f:	e8 5a b4 ff ff       	call   c0100cde <__panic>
c0105884:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0105887:	2d 00 00 00 40       	sub    $0x40000000,%eax
c010588c:	89 45 f0             	mov    %eax,-0x10(%ebp)
        memset(pte_base, 0, PGSIZE);
c010588f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
c0105896:	00 
c0105897:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c010589e:	00 
c010589f:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01058a2:	89 04 24             	mov    %eax,(%esp)
c01058a5:	e8 bd 18 00 00       	call   c0107167 <memset>
        *pdep = *pdep | PTE_P | PTE_W | PTE_U;
c01058aa:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01058ad:	8b 00                	mov    (%eax),%eax
c01058af:	83 c8 07             	or     $0x7,%eax
c01058b2:	89 c2                	mov    %eax,%edx
c01058b4:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01058b7:	89 10                	mov    %edx,(%eax)
c01058b9:	eb 07                	jmp    c01058c2 <get_pte+0x151>
    }
    else {
        find_pte = 0;
c01058bb:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
    }
    if (find_pte) {
c01058c2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c01058c6:	74 1a                	je     c01058e2 <get_pte+0x171>
        result = &pte_base[PTX(la)];
c01058c8:	8b 45 0c             	mov    0xc(%ebp),%eax
c01058cb:	c1 e8 0c             	shr    $0xc,%eax
c01058ce:	25 ff 03 00 00       	and    $0x3ff,%eax
c01058d3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c01058da:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01058dd:	01 d0                	add    %edx,%eax
c01058df:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }
    return result;
c01058e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01058e5:	c9                   	leave  
c01058e6:	c3                   	ret    

c01058e7 <get_page>:

//get_page - get related Page struct for linear address la using PDT pgdir
struct Page *
get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
c01058e7:	55                   	push   %ebp
c01058e8:	89 e5                	mov    %esp,%ebp
c01058ea:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
c01058ed:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01058f4:	00 
c01058f5:	8b 45 0c             	mov    0xc(%ebp),%eax
c01058f8:	89 44 24 04          	mov    %eax,0x4(%esp)
c01058fc:	8b 45 08             	mov    0x8(%ebp),%eax
c01058ff:	89 04 24             	mov    %eax,(%esp)
c0105902:	e8 6a fe ff ff       	call   c0105771 <get_pte>
c0105907:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep_store != NULL) {
c010590a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c010590e:	74 08                	je     c0105918 <get_page+0x31>
        *ptep_store = ptep;
c0105910:	8b 45 10             	mov    0x10(%ebp),%eax
c0105913:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105916:	89 10                	mov    %edx,(%eax)
    }
    if (ptep != NULL && *ptep & PTE_P) {
c0105918:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c010591c:	74 1b                	je     c0105939 <get_page+0x52>
c010591e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105921:	8b 00                	mov    (%eax),%eax
c0105923:	83 e0 01             	and    $0x1,%eax
c0105926:	85 c0                	test   %eax,%eax
c0105928:	74 0f                	je     c0105939 <get_page+0x52>
        return pte2page(*ptep);
c010592a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010592d:	8b 00                	mov    (%eax),%eax
c010592f:	89 04 24             	mov    %eax,(%esp)
c0105932:	e8 08 f5 ff ff       	call   c0104e3f <pte2page>
c0105937:	eb 05                	jmp    c010593e <get_page+0x57>
    }
    return NULL;
c0105939:	b8 00 00 00 00       	mov    $0x0,%eax
}
c010593e:	c9                   	leave  
c010593f:	c3                   	ret    

c0105940 <page_remove_pte>:

//page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
//note: PT is changed, so the TLB need to be invalidate 
static inline void
page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
c0105940:	55                   	push   %ebp
c0105941:	89 e5                	mov    %esp,%ebp
c0105943:	83 ec 28             	sub    $0x28,%esp
                                  //(4) and free this page when page reference reachs 0
                                  //(5) clear second page table entry
                                  //(6) flush tlb
    }
#endif
    if (!(*ptep & PTE_P)) {
c0105946:	8b 45 10             	mov    0x10(%ebp),%eax
c0105949:	8b 00                	mov    (%eax),%eax
c010594b:	83 e0 01             	and    $0x1,%eax
c010594e:	85 c0                	test   %eax,%eax
c0105950:	75 02                	jne    c0105954 <page_remove_pte+0x14>
        return;
c0105952:	eb 53                	jmp    c01059a7 <page_remove_pte+0x67>
    }
    struct Page *page = pte2page(*ptep);
c0105954:	8b 45 10             	mov    0x10(%ebp),%eax
c0105957:	8b 00                	mov    (%eax),%eax
c0105959:	89 04 24             	mov    %eax,(%esp)
c010595c:	e8 de f4 ff ff       	call   c0104e3f <pte2page>
c0105961:	89 45 f4             	mov    %eax,-0xc(%ebp)
    page_ref_dec(page);
c0105964:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105967:	89 04 24             	mov    %eax,(%esp)
c010596a:	e8 54 f5 ff ff       	call   c0104ec3 <page_ref_dec>
    if (page->ref <= 0) {
c010596f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105972:	8b 00                	mov    (%eax),%eax
c0105974:	85 c0                	test   %eax,%eax
c0105976:	7f 13                	jg     c010598b <page_remove_pte+0x4b>
        free_page(page);
c0105978:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c010597f:	00 
c0105980:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105983:	89 04 24             	mov    %eax,(%esp)
c0105986:	e8 47 f7 ff ff       	call   c01050d2 <free_pages>
    }
    *ptep = 0;
c010598b:	8b 45 10             	mov    0x10(%ebp),%eax
c010598e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    tlb_invalidate(pgdir, la);
c0105994:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105997:	89 44 24 04          	mov    %eax,0x4(%esp)
c010599b:	8b 45 08             	mov    0x8(%ebp),%eax
c010599e:	89 04 24             	mov    %eax,(%esp)
c01059a1:	e8 00 01 00 00       	call   c0105aa6 <tlb_invalidate>
    return;
c01059a6:	90                   	nop
}
c01059a7:	c9                   	leave  
c01059a8:	c3                   	ret    

c01059a9 <page_remove>:

//page_remove - free an Page which is related linear address la and has an validated pte
void
page_remove(pde_t *pgdir, uintptr_t la) {
c01059a9:	55                   	push   %ebp
c01059aa:	89 e5                	mov    %esp,%ebp
c01059ac:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
c01059af:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01059b6:	00 
c01059b7:	8b 45 0c             	mov    0xc(%ebp),%eax
c01059ba:	89 44 24 04          	mov    %eax,0x4(%esp)
c01059be:	8b 45 08             	mov    0x8(%ebp),%eax
c01059c1:	89 04 24             	mov    %eax,(%esp)
c01059c4:	e8 a8 fd ff ff       	call   c0105771 <get_pte>
c01059c9:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep != NULL) {
c01059cc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01059d0:	74 19                	je     c01059eb <page_remove+0x42>
        page_remove_pte(pgdir, la, ptep);
c01059d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01059d5:	89 44 24 08          	mov    %eax,0x8(%esp)
c01059d9:	8b 45 0c             	mov    0xc(%ebp),%eax
c01059dc:	89 44 24 04          	mov    %eax,0x4(%esp)
c01059e0:	8b 45 08             	mov    0x8(%ebp),%eax
c01059e3:	89 04 24             	mov    %eax,(%esp)
c01059e6:	e8 55 ff ff ff       	call   c0105940 <page_remove_pte>
    }
}
c01059eb:	c9                   	leave  
c01059ec:	c3                   	ret    

c01059ed <page_insert>:
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
//note: PT is changed, so the TLB need to be invalidate 
int
page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
c01059ed:	55                   	push   %ebp
c01059ee:	89 e5                	mov    %esp,%ebp
c01059f0:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 1);
c01059f3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
c01059fa:	00 
c01059fb:	8b 45 10             	mov    0x10(%ebp),%eax
c01059fe:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105a02:	8b 45 08             	mov    0x8(%ebp),%eax
c0105a05:	89 04 24             	mov    %eax,(%esp)
c0105a08:	e8 64 fd ff ff       	call   c0105771 <get_pte>
c0105a0d:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep == NULL) {
c0105a10:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0105a14:	75 0a                	jne    c0105a20 <page_insert+0x33>
        return -E_NO_MEM;
c0105a16:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
c0105a1b:	e9 84 00 00 00       	jmp    c0105aa4 <page_insert+0xb7>
    }
    page_ref_inc(page);
c0105a20:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105a23:	89 04 24             	mov    %eax,(%esp)
c0105a26:	e8 81 f4 ff ff       	call   c0104eac <page_ref_inc>
    if (*ptep & PTE_P) {
c0105a2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105a2e:	8b 00                	mov    (%eax),%eax
c0105a30:	83 e0 01             	and    $0x1,%eax
c0105a33:	85 c0                	test   %eax,%eax
c0105a35:	74 3e                	je     c0105a75 <page_insert+0x88>
        struct Page *p = pte2page(*ptep);
c0105a37:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105a3a:	8b 00                	mov    (%eax),%eax
c0105a3c:	89 04 24             	mov    %eax,(%esp)
c0105a3f:	e8 fb f3 ff ff       	call   c0104e3f <pte2page>
c0105a44:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (p == page) {
c0105a47:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105a4a:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0105a4d:	75 0d                	jne    c0105a5c <page_insert+0x6f>
            page_ref_dec(page);
c0105a4f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105a52:	89 04 24             	mov    %eax,(%esp)
c0105a55:	e8 69 f4 ff ff       	call   c0104ec3 <page_ref_dec>
c0105a5a:	eb 19                	jmp    c0105a75 <page_insert+0x88>
        }
        else {
            page_remove_pte(pgdir, la, ptep);
c0105a5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105a5f:	89 44 24 08          	mov    %eax,0x8(%esp)
c0105a63:	8b 45 10             	mov    0x10(%ebp),%eax
c0105a66:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105a6a:	8b 45 08             	mov    0x8(%ebp),%eax
c0105a6d:	89 04 24             	mov    %eax,(%esp)
c0105a70:	e8 cb fe ff ff       	call   c0105940 <page_remove_pte>
        }
    }
    *ptep = page2pa(page) | PTE_P | perm;
c0105a75:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105a78:	89 04 24             	mov    %eax,(%esp)
c0105a7b:	e8 06 f3 ff ff       	call   c0104d86 <page2pa>
c0105a80:	0b 45 14             	or     0x14(%ebp),%eax
c0105a83:	83 c8 01             	or     $0x1,%eax
c0105a86:	89 c2                	mov    %eax,%edx
c0105a88:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105a8b:	89 10                	mov    %edx,(%eax)
    tlb_invalidate(pgdir, la);
c0105a8d:	8b 45 10             	mov    0x10(%ebp),%eax
c0105a90:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105a94:	8b 45 08             	mov    0x8(%ebp),%eax
c0105a97:	89 04 24             	mov    %eax,(%esp)
c0105a9a:	e8 07 00 00 00       	call   c0105aa6 <tlb_invalidate>
    return 0;
c0105a9f:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0105aa4:	c9                   	leave  
c0105aa5:	c3                   	ret    

c0105aa6 <tlb_invalidate>:

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void
tlb_invalidate(pde_t *pgdir, uintptr_t la) {
c0105aa6:	55                   	push   %ebp
c0105aa7:	89 e5                	mov    %esp,%ebp
c0105aa9:	83 ec 28             	sub    $0x28,%esp
}

static inline uintptr_t
rcr3(void) {
    uintptr_t cr3;
    asm volatile ("mov %%cr3, %0" : "=r" (cr3) :: "memory");
c0105aac:	0f 20 d8             	mov    %cr3,%eax
c0105aaf:	89 45 f0             	mov    %eax,-0x10(%ebp)
    return cr3;
c0105ab2:	8b 45 f0             	mov    -0x10(%ebp),%eax
    if (rcr3() == PADDR(pgdir)) {
c0105ab5:	89 c2                	mov    %eax,%edx
c0105ab7:	8b 45 08             	mov    0x8(%ebp),%eax
c0105aba:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105abd:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
c0105ac4:	77 23                	ja     c0105ae9 <tlb_invalidate+0x43>
c0105ac6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105ac9:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0105acd:	c7 44 24 08 90 82 10 	movl   $0xc0108290,0x8(%esp)
c0105ad4:	c0 
c0105ad5:	c7 44 24 04 f1 01 00 	movl   $0x1f1,0x4(%esp)
c0105adc:	00 
c0105add:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105ae4:	e8 f5 b1 ff ff       	call   c0100cde <__panic>
c0105ae9:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105aec:	05 00 00 00 40       	add    $0x40000000,%eax
c0105af1:	39 c2                	cmp    %eax,%edx
c0105af3:	75 0c                	jne    c0105b01 <tlb_invalidate+0x5b>
        invlpg((void *)la);
c0105af5:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105af8:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

static inline void
invlpg(void *addr) {
    asm volatile ("invlpg (%0)" :: "r" (addr) : "memory");
c0105afb:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105afe:	0f 01 38             	invlpg (%eax)
    }
}
c0105b01:	c9                   	leave  
c0105b02:	c3                   	ret    

c0105b03 <check_alloc_page>:

static void
check_alloc_page(void) {
c0105b03:	55                   	push   %ebp
c0105b04:	89 e5                	mov    %esp,%ebp
c0105b06:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->check();
c0105b09:	a1 f4 57 12 c0       	mov    0xc01257f4,%eax
c0105b0e:	8b 40 18             	mov    0x18(%eax),%eax
c0105b11:	ff d0                	call   *%eax
    cprintf("check_alloc_page() succeeded!\n");
c0105b13:	c7 04 24 3c 83 10 c0 	movl   $0xc010833c,(%esp)
c0105b1a:	e8 35 a8 ff ff       	call   c0100354 <cprintf>
}
c0105b1f:	c9                   	leave  
c0105b20:	c3                   	ret    

c0105b21 <check_pgdir>:

static void
check_pgdir(void) {
c0105b21:	55                   	push   %ebp
c0105b22:	89 e5                	mov    %esp,%ebp
c0105b24:	83 ec 38             	sub    $0x38,%esp
    assert(npage <= KMEMSIZE / PGSIZE);
c0105b27:	a1 a0 56 12 c0       	mov    0xc01256a0,%eax
c0105b2c:	3d 00 80 03 00       	cmp    $0x38000,%eax
c0105b31:	76 24                	jbe    c0105b57 <check_pgdir+0x36>
c0105b33:	c7 44 24 0c 5b 83 10 	movl   $0xc010835b,0xc(%esp)
c0105b3a:	c0 
c0105b3b:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105b42:	c0 
c0105b43:	c7 44 24 04 fe 01 00 	movl   $0x1fe,0x4(%esp)
c0105b4a:	00 
c0105b4b:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105b52:	e8 87 b1 ff ff       	call   c0100cde <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
c0105b57:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0105b5c:	85 c0                	test   %eax,%eax
c0105b5e:	74 0e                	je     c0105b6e <check_pgdir+0x4d>
c0105b60:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0105b65:	25 ff 0f 00 00       	and    $0xfff,%eax
c0105b6a:	85 c0                	test   %eax,%eax
c0105b6c:	74 24                	je     c0105b92 <check_pgdir+0x71>
c0105b6e:	c7 44 24 0c 78 83 10 	movl   $0xc0108378,0xc(%esp)
c0105b75:	c0 
c0105b76:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105b7d:	c0 
c0105b7e:	c7 44 24 04 ff 01 00 	movl   $0x1ff,0x4(%esp)
c0105b85:	00 
c0105b86:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105b8d:	e8 4c b1 ff ff       	call   c0100cde <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
c0105b92:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0105b97:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0105b9e:	00 
c0105b9f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0105ba6:	00 
c0105ba7:	89 04 24             	mov    %eax,(%esp)
c0105baa:	e8 38 fd ff ff       	call   c01058e7 <get_page>
c0105baf:	85 c0                	test   %eax,%eax
c0105bb1:	74 24                	je     c0105bd7 <check_pgdir+0xb6>
c0105bb3:	c7 44 24 0c b0 83 10 	movl   $0xc01083b0,0xc(%esp)
c0105bba:	c0 
c0105bbb:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105bc2:	c0 
c0105bc3:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
c0105bca:	00 
c0105bcb:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105bd2:	e8 07 b1 ff ff       	call   c0100cde <__panic>

    struct Page *p1, *p2;
    p1 = alloc_page();
c0105bd7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0105bde:	e8 b7 f4 ff ff       	call   c010509a <alloc_pages>
c0105be3:	89 45 f4             	mov    %eax,-0xc(%ebp)
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
c0105be6:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0105beb:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
c0105bf2:	00 
c0105bf3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0105bfa:	00 
c0105bfb:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105bfe:	89 54 24 04          	mov    %edx,0x4(%esp)
c0105c02:	89 04 24             	mov    %eax,(%esp)
c0105c05:	e8 e3 fd ff ff       	call   c01059ed <page_insert>
c0105c0a:	85 c0                	test   %eax,%eax
c0105c0c:	74 24                	je     c0105c32 <check_pgdir+0x111>
c0105c0e:	c7 44 24 0c d8 83 10 	movl   $0xc01083d8,0xc(%esp)
c0105c15:	c0 
c0105c16:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105c1d:	c0 
c0105c1e:	c7 44 24 04 04 02 00 	movl   $0x204,0x4(%esp)
c0105c25:	00 
c0105c26:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105c2d:	e8 ac b0 ff ff       	call   c0100cde <__panic>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
c0105c32:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0105c37:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0105c3e:	00 
c0105c3f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0105c46:	00 
c0105c47:	89 04 24             	mov    %eax,(%esp)
c0105c4a:	e8 22 fb ff ff       	call   c0105771 <get_pte>
c0105c4f:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105c52:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0105c56:	75 24                	jne    c0105c7c <check_pgdir+0x15b>
c0105c58:	c7 44 24 0c 04 84 10 	movl   $0xc0108404,0xc(%esp)
c0105c5f:	c0 
c0105c60:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105c67:	c0 
c0105c68:	c7 44 24 04 07 02 00 	movl   $0x207,0x4(%esp)
c0105c6f:	00 
c0105c70:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105c77:	e8 62 b0 ff ff       	call   c0100cde <__panic>
    assert(pte2page(*ptep) == p1);
c0105c7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105c7f:	8b 00                	mov    (%eax),%eax
c0105c81:	89 04 24             	mov    %eax,(%esp)
c0105c84:	e8 b6 f1 ff ff       	call   c0104e3f <pte2page>
c0105c89:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0105c8c:	74 24                	je     c0105cb2 <check_pgdir+0x191>
c0105c8e:	c7 44 24 0c 31 84 10 	movl   $0xc0108431,0xc(%esp)
c0105c95:	c0 
c0105c96:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105c9d:	c0 
c0105c9e:	c7 44 24 04 08 02 00 	movl   $0x208,0x4(%esp)
c0105ca5:	00 
c0105ca6:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105cad:	e8 2c b0 ff ff       	call   c0100cde <__panic>
    assert(page_ref(p1) == 1);
c0105cb2:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105cb5:	89 04 24             	mov    %eax,(%esp)
c0105cb8:	e8 d8 f1 ff ff       	call   c0104e95 <page_ref>
c0105cbd:	83 f8 01             	cmp    $0x1,%eax
c0105cc0:	74 24                	je     c0105ce6 <check_pgdir+0x1c5>
c0105cc2:	c7 44 24 0c 47 84 10 	movl   $0xc0108447,0xc(%esp)
c0105cc9:	c0 
c0105cca:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105cd1:	c0 
c0105cd2:	c7 44 24 04 09 02 00 	movl   $0x209,0x4(%esp)
c0105cd9:	00 
c0105cda:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105ce1:	e8 f8 af ff ff       	call   c0100cde <__panic>

    ptep = &((pte_t *)KADDR(PDE_ADDR(boot_pgdir[0])))[1];
c0105ce6:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0105ceb:	8b 00                	mov    (%eax),%eax
c0105ced:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0105cf2:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105cf5:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105cf8:	c1 e8 0c             	shr    $0xc,%eax
c0105cfb:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0105cfe:	a1 a0 56 12 c0       	mov    0xc01256a0,%eax
c0105d03:	39 45 e8             	cmp    %eax,-0x18(%ebp)
c0105d06:	72 23                	jb     c0105d2b <check_pgdir+0x20a>
c0105d08:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105d0b:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0105d0f:	c7 44 24 08 ec 81 10 	movl   $0xc01081ec,0x8(%esp)
c0105d16:	c0 
c0105d17:	c7 44 24 04 0b 02 00 	movl   $0x20b,0x4(%esp)
c0105d1e:	00 
c0105d1f:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105d26:	e8 b3 af ff ff       	call   c0100cde <__panic>
c0105d2b:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105d2e:	2d 00 00 00 40       	sub    $0x40000000,%eax
c0105d33:	83 c0 04             	add    $0x4,%eax
c0105d36:	89 45 f0             	mov    %eax,-0x10(%ebp)
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
c0105d39:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0105d3e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0105d45:	00 
c0105d46:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c0105d4d:	00 
c0105d4e:	89 04 24             	mov    %eax,(%esp)
c0105d51:	e8 1b fa ff ff       	call   c0105771 <get_pte>
c0105d56:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c0105d59:	74 24                	je     c0105d7f <check_pgdir+0x25e>
c0105d5b:	c7 44 24 0c 5c 84 10 	movl   $0xc010845c,0xc(%esp)
c0105d62:	c0 
c0105d63:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105d6a:	c0 
c0105d6b:	c7 44 24 04 0c 02 00 	movl   $0x20c,0x4(%esp)
c0105d72:	00 
c0105d73:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105d7a:	e8 5f af ff ff       	call   c0100cde <__panic>

    p2 = alloc_page();
c0105d7f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0105d86:	e8 0f f3 ff ff       	call   c010509a <alloc_pages>
c0105d8b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
c0105d8e:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0105d93:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
c0105d9a:	00 
c0105d9b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
c0105da2:	00 
c0105da3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0105da6:	89 54 24 04          	mov    %edx,0x4(%esp)
c0105daa:	89 04 24             	mov    %eax,(%esp)
c0105dad:	e8 3b fc ff ff       	call   c01059ed <page_insert>
c0105db2:	85 c0                	test   %eax,%eax
c0105db4:	74 24                	je     c0105dda <check_pgdir+0x2b9>
c0105db6:	c7 44 24 0c 84 84 10 	movl   $0xc0108484,0xc(%esp)
c0105dbd:	c0 
c0105dbe:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105dc5:	c0 
c0105dc6:	c7 44 24 04 0f 02 00 	movl   $0x20f,0x4(%esp)
c0105dcd:	00 
c0105dce:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105dd5:	e8 04 af ff ff       	call   c0100cde <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
c0105dda:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0105ddf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0105de6:	00 
c0105de7:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c0105dee:	00 
c0105def:	89 04 24             	mov    %eax,(%esp)
c0105df2:	e8 7a f9 ff ff       	call   c0105771 <get_pte>
c0105df7:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105dfa:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0105dfe:	75 24                	jne    c0105e24 <check_pgdir+0x303>
c0105e00:	c7 44 24 0c bc 84 10 	movl   $0xc01084bc,0xc(%esp)
c0105e07:	c0 
c0105e08:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105e0f:	c0 
c0105e10:	c7 44 24 04 10 02 00 	movl   $0x210,0x4(%esp)
c0105e17:	00 
c0105e18:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105e1f:	e8 ba ae ff ff       	call   c0100cde <__panic>
    assert(*ptep & PTE_U);
c0105e24:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105e27:	8b 00                	mov    (%eax),%eax
c0105e29:	83 e0 04             	and    $0x4,%eax
c0105e2c:	85 c0                	test   %eax,%eax
c0105e2e:	75 24                	jne    c0105e54 <check_pgdir+0x333>
c0105e30:	c7 44 24 0c ec 84 10 	movl   $0xc01084ec,0xc(%esp)
c0105e37:	c0 
c0105e38:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105e3f:	c0 
c0105e40:	c7 44 24 04 11 02 00 	movl   $0x211,0x4(%esp)
c0105e47:	00 
c0105e48:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105e4f:	e8 8a ae ff ff       	call   c0100cde <__panic>
    assert(*ptep & PTE_W);
c0105e54:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105e57:	8b 00                	mov    (%eax),%eax
c0105e59:	83 e0 02             	and    $0x2,%eax
c0105e5c:	85 c0                	test   %eax,%eax
c0105e5e:	75 24                	jne    c0105e84 <check_pgdir+0x363>
c0105e60:	c7 44 24 0c fa 84 10 	movl   $0xc01084fa,0xc(%esp)
c0105e67:	c0 
c0105e68:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105e6f:	c0 
c0105e70:	c7 44 24 04 12 02 00 	movl   $0x212,0x4(%esp)
c0105e77:	00 
c0105e78:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105e7f:	e8 5a ae ff ff       	call   c0100cde <__panic>
    assert(boot_pgdir[0] & PTE_U);
c0105e84:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0105e89:	8b 00                	mov    (%eax),%eax
c0105e8b:	83 e0 04             	and    $0x4,%eax
c0105e8e:	85 c0                	test   %eax,%eax
c0105e90:	75 24                	jne    c0105eb6 <check_pgdir+0x395>
c0105e92:	c7 44 24 0c 08 85 10 	movl   $0xc0108508,0xc(%esp)
c0105e99:	c0 
c0105e9a:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105ea1:	c0 
c0105ea2:	c7 44 24 04 13 02 00 	movl   $0x213,0x4(%esp)
c0105ea9:	00 
c0105eaa:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105eb1:	e8 28 ae ff ff       	call   c0100cde <__panic>
    assert(page_ref(p2) == 1);
c0105eb6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105eb9:	89 04 24             	mov    %eax,(%esp)
c0105ebc:	e8 d4 ef ff ff       	call   c0104e95 <page_ref>
c0105ec1:	83 f8 01             	cmp    $0x1,%eax
c0105ec4:	74 24                	je     c0105eea <check_pgdir+0x3c9>
c0105ec6:	c7 44 24 0c 1e 85 10 	movl   $0xc010851e,0xc(%esp)
c0105ecd:	c0 
c0105ece:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105ed5:	c0 
c0105ed6:	c7 44 24 04 14 02 00 	movl   $0x214,0x4(%esp)
c0105edd:	00 
c0105ede:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105ee5:	e8 f4 ad ff ff       	call   c0100cde <__panic>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
c0105eea:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0105eef:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
c0105ef6:	00 
c0105ef7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
c0105efe:	00 
c0105eff:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105f02:	89 54 24 04          	mov    %edx,0x4(%esp)
c0105f06:	89 04 24             	mov    %eax,(%esp)
c0105f09:	e8 df fa ff ff       	call   c01059ed <page_insert>
c0105f0e:	85 c0                	test   %eax,%eax
c0105f10:	74 24                	je     c0105f36 <check_pgdir+0x415>
c0105f12:	c7 44 24 0c 30 85 10 	movl   $0xc0108530,0xc(%esp)
c0105f19:	c0 
c0105f1a:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105f21:	c0 
c0105f22:	c7 44 24 04 16 02 00 	movl   $0x216,0x4(%esp)
c0105f29:	00 
c0105f2a:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105f31:	e8 a8 ad ff ff       	call   c0100cde <__panic>
    assert(page_ref(p1) == 2);
c0105f36:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105f39:	89 04 24             	mov    %eax,(%esp)
c0105f3c:	e8 54 ef ff ff       	call   c0104e95 <page_ref>
c0105f41:	83 f8 02             	cmp    $0x2,%eax
c0105f44:	74 24                	je     c0105f6a <check_pgdir+0x449>
c0105f46:	c7 44 24 0c 5c 85 10 	movl   $0xc010855c,0xc(%esp)
c0105f4d:	c0 
c0105f4e:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105f55:	c0 
c0105f56:	c7 44 24 04 17 02 00 	movl   $0x217,0x4(%esp)
c0105f5d:	00 
c0105f5e:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105f65:	e8 74 ad ff ff       	call   c0100cde <__panic>
    assert(page_ref(p2) == 0);
c0105f6a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105f6d:	89 04 24             	mov    %eax,(%esp)
c0105f70:	e8 20 ef ff ff       	call   c0104e95 <page_ref>
c0105f75:	85 c0                	test   %eax,%eax
c0105f77:	74 24                	je     c0105f9d <check_pgdir+0x47c>
c0105f79:	c7 44 24 0c 6e 85 10 	movl   $0xc010856e,0xc(%esp)
c0105f80:	c0 
c0105f81:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105f88:	c0 
c0105f89:	c7 44 24 04 18 02 00 	movl   $0x218,0x4(%esp)
c0105f90:	00 
c0105f91:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105f98:	e8 41 ad ff ff       	call   c0100cde <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
c0105f9d:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0105fa2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0105fa9:	00 
c0105faa:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c0105fb1:	00 
c0105fb2:	89 04 24             	mov    %eax,(%esp)
c0105fb5:	e8 b7 f7 ff ff       	call   c0105771 <get_pte>
c0105fba:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105fbd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0105fc1:	75 24                	jne    c0105fe7 <check_pgdir+0x4c6>
c0105fc3:	c7 44 24 0c bc 84 10 	movl   $0xc01084bc,0xc(%esp)
c0105fca:	c0 
c0105fcb:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0105fd2:	c0 
c0105fd3:	c7 44 24 04 19 02 00 	movl   $0x219,0x4(%esp)
c0105fda:	00 
c0105fdb:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0105fe2:	e8 f7 ac ff ff       	call   c0100cde <__panic>
    assert(pte2page(*ptep) == p1);
c0105fe7:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105fea:	8b 00                	mov    (%eax),%eax
c0105fec:	89 04 24             	mov    %eax,(%esp)
c0105fef:	e8 4b ee ff ff       	call   c0104e3f <pte2page>
c0105ff4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0105ff7:	74 24                	je     c010601d <check_pgdir+0x4fc>
c0105ff9:	c7 44 24 0c 31 84 10 	movl   $0xc0108431,0xc(%esp)
c0106000:	c0 
c0106001:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0106008:	c0 
c0106009:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
c0106010:	00 
c0106011:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0106018:	e8 c1 ac ff ff       	call   c0100cde <__panic>
    assert((*ptep & PTE_U) == 0);
c010601d:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106020:	8b 00                	mov    (%eax),%eax
c0106022:	83 e0 04             	and    $0x4,%eax
c0106025:	85 c0                	test   %eax,%eax
c0106027:	74 24                	je     c010604d <check_pgdir+0x52c>
c0106029:	c7 44 24 0c 80 85 10 	movl   $0xc0108580,0xc(%esp)
c0106030:	c0 
c0106031:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0106038:	c0 
c0106039:	c7 44 24 04 1b 02 00 	movl   $0x21b,0x4(%esp)
c0106040:	00 
c0106041:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0106048:	e8 91 ac ff ff       	call   c0100cde <__panic>

    page_remove(boot_pgdir, 0x0);
c010604d:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0106052:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0106059:	00 
c010605a:	89 04 24             	mov    %eax,(%esp)
c010605d:	e8 47 f9 ff ff       	call   c01059a9 <page_remove>
    assert(page_ref(p1) == 1);
c0106062:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106065:	89 04 24             	mov    %eax,(%esp)
c0106068:	e8 28 ee ff ff       	call   c0104e95 <page_ref>
c010606d:	83 f8 01             	cmp    $0x1,%eax
c0106070:	74 24                	je     c0106096 <check_pgdir+0x575>
c0106072:	c7 44 24 0c 47 84 10 	movl   $0xc0108447,0xc(%esp)
c0106079:	c0 
c010607a:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0106081:	c0 
c0106082:	c7 44 24 04 1e 02 00 	movl   $0x21e,0x4(%esp)
c0106089:	00 
c010608a:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0106091:	e8 48 ac ff ff       	call   c0100cde <__panic>
    assert(page_ref(p2) == 0);
c0106096:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0106099:	89 04 24             	mov    %eax,(%esp)
c010609c:	e8 f4 ed ff ff       	call   c0104e95 <page_ref>
c01060a1:	85 c0                	test   %eax,%eax
c01060a3:	74 24                	je     c01060c9 <check_pgdir+0x5a8>
c01060a5:	c7 44 24 0c 6e 85 10 	movl   $0xc010856e,0xc(%esp)
c01060ac:	c0 
c01060ad:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c01060b4:	c0 
c01060b5:	c7 44 24 04 1f 02 00 	movl   $0x21f,0x4(%esp)
c01060bc:	00 
c01060bd:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c01060c4:	e8 15 ac ff ff       	call   c0100cde <__panic>

    page_remove(boot_pgdir, PGSIZE);
c01060c9:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c01060ce:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c01060d5:	00 
c01060d6:	89 04 24             	mov    %eax,(%esp)
c01060d9:	e8 cb f8 ff ff       	call   c01059a9 <page_remove>
    assert(page_ref(p1) == 0);
c01060de:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01060e1:	89 04 24             	mov    %eax,(%esp)
c01060e4:	e8 ac ed ff ff       	call   c0104e95 <page_ref>
c01060e9:	85 c0                	test   %eax,%eax
c01060eb:	74 24                	je     c0106111 <check_pgdir+0x5f0>
c01060ed:	c7 44 24 0c 95 85 10 	movl   $0xc0108595,0xc(%esp)
c01060f4:	c0 
c01060f5:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c01060fc:	c0 
c01060fd:	c7 44 24 04 22 02 00 	movl   $0x222,0x4(%esp)
c0106104:	00 
c0106105:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c010610c:	e8 cd ab ff ff       	call   c0100cde <__panic>
    assert(page_ref(p2) == 0);
c0106111:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0106114:	89 04 24             	mov    %eax,(%esp)
c0106117:	e8 79 ed ff ff       	call   c0104e95 <page_ref>
c010611c:	85 c0                	test   %eax,%eax
c010611e:	74 24                	je     c0106144 <check_pgdir+0x623>
c0106120:	c7 44 24 0c 6e 85 10 	movl   $0xc010856e,0xc(%esp)
c0106127:	c0 
c0106128:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c010612f:	c0 
c0106130:	c7 44 24 04 23 02 00 	movl   $0x223,0x4(%esp)
c0106137:	00 
c0106138:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c010613f:	e8 9a ab ff ff       	call   c0100cde <__panic>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
c0106144:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0106149:	8b 00                	mov    (%eax),%eax
c010614b:	89 04 24             	mov    %eax,(%esp)
c010614e:	e8 2a ed ff ff       	call   c0104e7d <pde2page>
c0106153:	89 04 24             	mov    %eax,(%esp)
c0106156:	e8 3a ed ff ff       	call   c0104e95 <page_ref>
c010615b:	83 f8 01             	cmp    $0x1,%eax
c010615e:	74 24                	je     c0106184 <check_pgdir+0x663>
c0106160:	c7 44 24 0c a8 85 10 	movl   $0xc01085a8,0xc(%esp)
c0106167:	c0 
c0106168:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c010616f:	c0 
c0106170:	c7 44 24 04 25 02 00 	movl   $0x225,0x4(%esp)
c0106177:	00 
c0106178:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c010617f:	e8 5a ab ff ff       	call   c0100cde <__panic>
    free_page(pde2page(boot_pgdir[0]));
c0106184:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0106189:	8b 00                	mov    (%eax),%eax
c010618b:	89 04 24             	mov    %eax,(%esp)
c010618e:	e8 ea ec ff ff       	call   c0104e7d <pde2page>
c0106193:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c010619a:	00 
c010619b:	89 04 24             	mov    %eax,(%esp)
c010619e:	e8 2f ef ff ff       	call   c01050d2 <free_pages>
    boot_pgdir[0] = 0;
c01061a3:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c01061a8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_pgdir() succeeded!\n");
c01061ae:	c7 04 24 cf 85 10 c0 	movl   $0xc01085cf,(%esp)
c01061b5:	e8 9a a1 ff ff       	call   c0100354 <cprintf>
}
c01061ba:	c9                   	leave  
c01061bb:	c3                   	ret    

c01061bc <check_boot_pgdir>:

static void
check_boot_pgdir(void) {
c01061bc:	55                   	push   %ebp
c01061bd:	89 e5                	mov    %esp,%ebp
c01061bf:	83 ec 38             	sub    $0x38,%esp
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
c01061c2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c01061c9:	e9 ca 00 00 00       	jmp    c0106298 <check_boot_pgdir+0xdc>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
c01061ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01061d1:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01061d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01061d7:	c1 e8 0c             	shr    $0xc,%eax
c01061da:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01061dd:	a1 a0 56 12 c0       	mov    0xc01256a0,%eax
c01061e2:	39 45 ec             	cmp    %eax,-0x14(%ebp)
c01061e5:	72 23                	jb     c010620a <check_boot_pgdir+0x4e>
c01061e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01061ea:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01061ee:	c7 44 24 08 ec 81 10 	movl   $0xc01081ec,0x8(%esp)
c01061f5:	c0 
c01061f6:	c7 44 24 04 31 02 00 	movl   $0x231,0x4(%esp)
c01061fd:	00 
c01061fe:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0106205:	e8 d4 aa ff ff       	call   c0100cde <__panic>
c010620a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010620d:	2d 00 00 00 40       	sub    $0x40000000,%eax
c0106212:	89 c2                	mov    %eax,%edx
c0106214:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0106219:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0106220:	00 
c0106221:	89 54 24 04          	mov    %edx,0x4(%esp)
c0106225:	89 04 24             	mov    %eax,(%esp)
c0106228:	e8 44 f5 ff ff       	call   c0105771 <get_pte>
c010622d:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0106230:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0106234:	75 24                	jne    c010625a <check_boot_pgdir+0x9e>
c0106236:	c7 44 24 0c ec 85 10 	movl   $0xc01085ec,0xc(%esp)
c010623d:	c0 
c010623e:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0106245:	c0 
c0106246:	c7 44 24 04 31 02 00 	movl   $0x231,0x4(%esp)
c010624d:	00 
c010624e:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0106255:	e8 84 aa ff ff       	call   c0100cde <__panic>
        assert(PTE_ADDR(*ptep) == i);
c010625a:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010625d:	8b 00                	mov    (%eax),%eax
c010625f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0106264:	89 c2                	mov    %eax,%edx
c0106266:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106269:	39 c2                	cmp    %eax,%edx
c010626b:	74 24                	je     c0106291 <check_boot_pgdir+0xd5>
c010626d:	c7 44 24 0c 29 86 10 	movl   $0xc0108629,0xc(%esp)
c0106274:	c0 
c0106275:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c010627c:	c0 
c010627d:	c7 44 24 04 32 02 00 	movl   $0x232,0x4(%esp)
c0106284:	00 
c0106285:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c010628c:	e8 4d aa ff ff       	call   c0100cde <__panic>

static void
check_boot_pgdir(void) {
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
c0106291:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
c0106298:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010629b:	a1 a0 56 12 c0       	mov    0xc01256a0,%eax
c01062a0:	39 c2                	cmp    %eax,%edx
c01062a2:	0f 82 26 ff ff ff    	jb     c01061ce <check_boot_pgdir+0x12>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }

    assert(PDE_ADDR(boot_pgdir[PDX(VPT)]) == PADDR(boot_pgdir));
c01062a8:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c01062ad:	05 ac 0f 00 00       	add    $0xfac,%eax
c01062b2:	8b 00                	mov    (%eax),%eax
c01062b4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c01062b9:	89 c2                	mov    %eax,%edx
c01062bb:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c01062c0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01062c3:	81 7d e4 ff ff ff bf 	cmpl   $0xbfffffff,-0x1c(%ebp)
c01062ca:	77 23                	ja     c01062ef <check_boot_pgdir+0x133>
c01062cc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01062cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01062d3:	c7 44 24 08 90 82 10 	movl   $0xc0108290,0x8(%esp)
c01062da:	c0 
c01062db:	c7 44 24 04 35 02 00 	movl   $0x235,0x4(%esp)
c01062e2:	00 
c01062e3:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c01062ea:	e8 ef a9 ff ff       	call   c0100cde <__panic>
c01062ef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01062f2:	05 00 00 00 40       	add    $0x40000000,%eax
c01062f7:	39 c2                	cmp    %eax,%edx
c01062f9:	74 24                	je     c010631f <check_boot_pgdir+0x163>
c01062fb:	c7 44 24 0c 40 86 10 	movl   $0xc0108640,0xc(%esp)
c0106302:	c0 
c0106303:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c010630a:	c0 
c010630b:	c7 44 24 04 35 02 00 	movl   $0x235,0x4(%esp)
c0106312:	00 
c0106313:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c010631a:	e8 bf a9 ff ff       	call   c0100cde <__panic>

    assert(boot_pgdir[0] == 0);
c010631f:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0106324:	8b 00                	mov    (%eax),%eax
c0106326:	85 c0                	test   %eax,%eax
c0106328:	74 24                	je     c010634e <check_boot_pgdir+0x192>
c010632a:	c7 44 24 0c 74 86 10 	movl   $0xc0108674,0xc(%esp)
c0106331:	c0 
c0106332:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0106339:	c0 
c010633a:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
c0106341:	00 
c0106342:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0106349:	e8 90 a9 ff ff       	call   c0100cde <__panic>

    struct Page *p;
    p = alloc_page();
c010634e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0106355:	e8 40 ed ff ff       	call   c010509a <alloc_pages>
c010635a:	89 45 e0             	mov    %eax,-0x20(%ebp)
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W) == 0);
c010635d:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0106362:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
c0106369:	00 
c010636a:	c7 44 24 08 00 01 00 	movl   $0x100,0x8(%esp)
c0106371:	00 
c0106372:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0106375:	89 54 24 04          	mov    %edx,0x4(%esp)
c0106379:	89 04 24             	mov    %eax,(%esp)
c010637c:	e8 6c f6 ff ff       	call   c01059ed <page_insert>
c0106381:	85 c0                	test   %eax,%eax
c0106383:	74 24                	je     c01063a9 <check_boot_pgdir+0x1ed>
c0106385:	c7 44 24 0c 88 86 10 	movl   $0xc0108688,0xc(%esp)
c010638c:	c0 
c010638d:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0106394:	c0 
c0106395:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
c010639c:	00 
c010639d:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c01063a4:	e8 35 a9 ff ff       	call   c0100cde <__panic>
    assert(page_ref(p) == 1);
c01063a9:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01063ac:	89 04 24             	mov    %eax,(%esp)
c01063af:	e8 e1 ea ff ff       	call   c0104e95 <page_ref>
c01063b4:	83 f8 01             	cmp    $0x1,%eax
c01063b7:	74 24                	je     c01063dd <check_boot_pgdir+0x221>
c01063b9:	c7 44 24 0c b6 86 10 	movl   $0xc01086b6,0xc(%esp)
c01063c0:	c0 
c01063c1:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c01063c8:	c0 
c01063c9:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
c01063d0:	00 
c01063d1:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c01063d8:	e8 01 a9 ff ff       	call   c0100cde <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W) == 0);
c01063dd:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c01063e2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
c01063e9:	00 
c01063ea:	c7 44 24 08 00 11 00 	movl   $0x1100,0x8(%esp)
c01063f1:	00 
c01063f2:	8b 55 e0             	mov    -0x20(%ebp),%edx
c01063f5:	89 54 24 04          	mov    %edx,0x4(%esp)
c01063f9:	89 04 24             	mov    %eax,(%esp)
c01063fc:	e8 ec f5 ff ff       	call   c01059ed <page_insert>
c0106401:	85 c0                	test   %eax,%eax
c0106403:	74 24                	je     c0106429 <check_boot_pgdir+0x26d>
c0106405:	c7 44 24 0c c8 86 10 	movl   $0xc01086c8,0xc(%esp)
c010640c:	c0 
c010640d:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0106414:	c0 
c0106415:	c7 44 24 04 3d 02 00 	movl   $0x23d,0x4(%esp)
c010641c:	00 
c010641d:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0106424:	e8 b5 a8 ff ff       	call   c0100cde <__panic>
    assert(page_ref(p) == 2);
c0106429:	8b 45 e0             	mov    -0x20(%ebp),%eax
c010642c:	89 04 24             	mov    %eax,(%esp)
c010642f:	e8 61 ea ff ff       	call   c0104e95 <page_ref>
c0106434:	83 f8 02             	cmp    $0x2,%eax
c0106437:	74 24                	je     c010645d <check_boot_pgdir+0x2a1>
c0106439:	c7 44 24 0c ff 86 10 	movl   $0xc01086ff,0xc(%esp)
c0106440:	c0 
c0106441:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c0106448:	c0 
c0106449:	c7 44 24 04 3e 02 00 	movl   $0x23e,0x4(%esp)
c0106450:	00 
c0106451:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c0106458:	e8 81 a8 ff ff       	call   c0100cde <__panic>

    const char *str = "ucore: Hello world!!";
c010645d:	c7 45 dc 10 87 10 c0 	movl   $0xc0108710,-0x24(%ebp)
    strcpy((void *)0x100, str);
c0106464:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0106467:	89 44 24 04          	mov    %eax,0x4(%esp)
c010646b:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
c0106472:	e8 19 0a 00 00       	call   c0106e90 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
c0106477:	c7 44 24 04 00 11 00 	movl   $0x1100,0x4(%esp)
c010647e:	00 
c010647f:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
c0106486:	e8 7e 0a 00 00       	call   c0106f09 <strcmp>
c010648b:	85 c0                	test   %eax,%eax
c010648d:	74 24                	je     c01064b3 <check_boot_pgdir+0x2f7>
c010648f:	c7 44 24 0c 28 87 10 	movl   $0xc0108728,0xc(%esp)
c0106496:	c0 
c0106497:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c010649e:	c0 
c010649f:	c7 44 24 04 42 02 00 	movl   $0x242,0x4(%esp)
c01064a6:	00 
c01064a7:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c01064ae:	e8 2b a8 ff ff       	call   c0100cde <__panic>

    *(char *)(page2kva(p) + 0x100) = '\0';
c01064b3:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01064b6:	89 04 24             	mov    %eax,(%esp)
c01064b9:	e8 2d e9 ff ff       	call   c0104deb <page2kva>
c01064be:	05 00 01 00 00       	add    $0x100,%eax
c01064c3:	c6 00 00             	movb   $0x0,(%eax)
    assert(strlen((const char *)0x100) == 0);
c01064c6:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
c01064cd:	e8 66 09 00 00       	call   c0106e38 <strlen>
c01064d2:	85 c0                	test   %eax,%eax
c01064d4:	74 24                	je     c01064fa <check_boot_pgdir+0x33e>
c01064d6:	c7 44 24 0c 60 87 10 	movl   $0xc0108760,0xc(%esp)
c01064dd:	c0 
c01064de:	c7 44 24 08 00 83 10 	movl   $0xc0108300,0x8(%esp)
c01064e5:	c0 
c01064e6:	c7 44 24 04 45 02 00 	movl   $0x245,0x4(%esp)
c01064ed:	00 
c01064ee:	c7 04 24 b4 82 10 c0 	movl   $0xc01082b4,(%esp)
c01064f5:	e8 e4 a7 ff ff       	call   c0100cde <__panic>

    free_page(p);
c01064fa:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0106501:	00 
c0106502:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0106505:	89 04 24             	mov    %eax,(%esp)
c0106508:	e8 c5 eb ff ff       	call   c01050d2 <free_pages>
    free_page(pde2page(boot_pgdir[0]));
c010650d:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0106512:	8b 00                	mov    (%eax),%eax
c0106514:	89 04 24             	mov    %eax,(%esp)
c0106517:	e8 61 e9 ff ff       	call   c0104e7d <pde2page>
c010651c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0106523:	00 
c0106524:	89 04 24             	mov    %eax,(%esp)
c0106527:	e8 a6 eb ff ff       	call   c01050d2 <free_pages>
    boot_pgdir[0] = 0;
c010652c:	a1 e0 a9 11 c0       	mov    0xc011a9e0,%eax
c0106531:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_boot_pgdir() succeeded!\n");
c0106537:	c7 04 24 84 87 10 c0 	movl   $0xc0108784,(%esp)
c010653e:	e8 11 9e ff ff       	call   c0100354 <cprintf>
}
c0106543:	c9                   	leave  
c0106544:	c3                   	ret    

c0106545 <perm2str>:

//perm2str - use string 'u,r,w,-' to present the permission
static const char *
perm2str(int perm) {
c0106545:	55                   	push   %ebp
c0106546:	89 e5                	mov    %esp,%ebp
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
c0106548:	8b 45 08             	mov    0x8(%ebp),%eax
c010654b:	83 e0 04             	and    $0x4,%eax
c010654e:	85 c0                	test   %eax,%eax
c0106550:	74 07                	je     c0106559 <perm2str+0x14>
c0106552:	b8 75 00 00 00       	mov    $0x75,%eax
c0106557:	eb 05                	jmp    c010655e <perm2str+0x19>
c0106559:	b8 2d 00 00 00       	mov    $0x2d,%eax
c010655e:	a2 28 57 12 c0       	mov    %al,0xc0125728
    str[1] = 'r';
c0106563:	c6 05 29 57 12 c0 72 	movb   $0x72,0xc0125729
    str[2] = (perm & PTE_W) ? 'w' : '-';
c010656a:	8b 45 08             	mov    0x8(%ebp),%eax
c010656d:	83 e0 02             	and    $0x2,%eax
c0106570:	85 c0                	test   %eax,%eax
c0106572:	74 07                	je     c010657b <perm2str+0x36>
c0106574:	b8 77 00 00 00       	mov    $0x77,%eax
c0106579:	eb 05                	jmp    c0106580 <perm2str+0x3b>
c010657b:	b8 2d 00 00 00       	mov    $0x2d,%eax
c0106580:	a2 2a 57 12 c0       	mov    %al,0xc012572a
    str[3] = '\0';
c0106585:	c6 05 2b 57 12 c0 00 	movb   $0x0,0xc012572b
    return str;
c010658c:	b8 28 57 12 c0       	mov    $0xc0125728,%eax
}
c0106591:	5d                   	pop    %ebp
c0106592:	c3                   	ret    

c0106593 <get_pgtable_items>:
//  table:       the beginning addr of table
//  left_store:  the pointer of the high side of table's next range
//  right_store: the pointer of the low side of table's next range
// return value: 0 - not a invalid item range, perm - a valid item range with perm permission 
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
c0106593:	55                   	push   %ebp
c0106594:	89 e5                	mov    %esp,%ebp
c0106596:	83 ec 10             	sub    $0x10,%esp
    if (start >= right) {
c0106599:	8b 45 10             	mov    0x10(%ebp),%eax
c010659c:	3b 45 0c             	cmp    0xc(%ebp),%eax
c010659f:	72 0a                	jb     c01065ab <get_pgtable_items+0x18>
        return 0;
c01065a1:	b8 00 00 00 00       	mov    $0x0,%eax
c01065a6:	e9 9c 00 00 00       	jmp    c0106647 <get_pgtable_items+0xb4>
    }
    while (start < right && !(table[start] & PTE_P)) {
c01065ab:	eb 04                	jmp    c01065b1 <get_pgtable_items+0x1e>
        start ++;
c01065ad:	83 45 10 01          	addl   $0x1,0x10(%ebp)
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
    if (start >= right) {
        return 0;
    }
    while (start < right && !(table[start] & PTE_P)) {
c01065b1:	8b 45 10             	mov    0x10(%ebp),%eax
c01065b4:	3b 45 0c             	cmp    0xc(%ebp),%eax
c01065b7:	73 18                	jae    c01065d1 <get_pgtable_items+0x3e>
c01065b9:	8b 45 10             	mov    0x10(%ebp),%eax
c01065bc:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c01065c3:	8b 45 14             	mov    0x14(%ebp),%eax
c01065c6:	01 d0                	add    %edx,%eax
c01065c8:	8b 00                	mov    (%eax),%eax
c01065ca:	83 e0 01             	and    $0x1,%eax
c01065cd:	85 c0                	test   %eax,%eax
c01065cf:	74 dc                	je     c01065ad <get_pgtable_items+0x1a>
        start ++;
    }
    if (start < right) {
c01065d1:	8b 45 10             	mov    0x10(%ebp),%eax
c01065d4:	3b 45 0c             	cmp    0xc(%ebp),%eax
c01065d7:	73 69                	jae    c0106642 <get_pgtable_items+0xaf>
        if (left_store != NULL) {
c01065d9:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
c01065dd:	74 08                	je     c01065e7 <get_pgtable_items+0x54>
            *left_store = start;
c01065df:	8b 45 18             	mov    0x18(%ebp),%eax
c01065e2:	8b 55 10             	mov    0x10(%ebp),%edx
c01065e5:	89 10                	mov    %edx,(%eax)
        }
        int perm = (table[start ++] & PTE_USER);
c01065e7:	8b 45 10             	mov    0x10(%ebp),%eax
c01065ea:	8d 50 01             	lea    0x1(%eax),%edx
c01065ed:	89 55 10             	mov    %edx,0x10(%ebp)
c01065f0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c01065f7:	8b 45 14             	mov    0x14(%ebp),%eax
c01065fa:	01 d0                	add    %edx,%eax
c01065fc:	8b 00                	mov    (%eax),%eax
c01065fe:	83 e0 07             	and    $0x7,%eax
c0106601:	89 45 fc             	mov    %eax,-0x4(%ebp)
        while (start < right && (table[start] & PTE_USER) == perm) {
c0106604:	eb 04                	jmp    c010660a <get_pgtable_items+0x77>
            start ++;
c0106606:	83 45 10 01          	addl   $0x1,0x10(%ebp)
    if (start < right) {
        if (left_store != NULL) {
            *left_store = start;
        }
        int perm = (table[start ++] & PTE_USER);
        while (start < right && (table[start] & PTE_USER) == perm) {
c010660a:	8b 45 10             	mov    0x10(%ebp),%eax
c010660d:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0106610:	73 1d                	jae    c010662f <get_pgtable_items+0x9c>
c0106612:	8b 45 10             	mov    0x10(%ebp),%eax
c0106615:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c010661c:	8b 45 14             	mov    0x14(%ebp),%eax
c010661f:	01 d0                	add    %edx,%eax
c0106621:	8b 00                	mov    (%eax),%eax
c0106623:	83 e0 07             	and    $0x7,%eax
c0106626:	89 c2                	mov    %eax,%edx
c0106628:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010662b:	39 c2                	cmp    %eax,%edx
c010662d:	74 d7                	je     c0106606 <get_pgtable_items+0x73>
            start ++;
        }
        if (right_store != NULL) {
c010662f:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
c0106633:	74 08                	je     c010663d <get_pgtable_items+0xaa>
            *right_store = start;
c0106635:	8b 45 1c             	mov    0x1c(%ebp),%eax
c0106638:	8b 55 10             	mov    0x10(%ebp),%edx
c010663b:	89 10                	mov    %edx,(%eax)
        }
        return perm;
c010663d:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0106640:	eb 05                	jmp    c0106647 <get_pgtable_items+0xb4>
    }
    return 0;
c0106642:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0106647:	c9                   	leave  
c0106648:	c3                   	ret    

c0106649 <print_pgdir>:

//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
c0106649:	55                   	push   %ebp
c010664a:	89 e5                	mov    %esp,%ebp
c010664c:	57                   	push   %edi
c010664d:	56                   	push   %esi
c010664e:	53                   	push   %ebx
c010664f:	83 ec 4c             	sub    $0x4c,%esp
    cprintf("-------------------- BEGIN --------------------\n");
c0106652:	c7 04 24 a4 87 10 c0 	movl   $0xc01087a4,(%esp)
c0106659:	e8 f6 9c ff ff       	call   c0100354 <cprintf>
    size_t left, right = 0, perm;
c010665e:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
c0106665:	e9 fa 00 00 00       	jmp    c0106764 <print_pgdir+0x11b>
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
c010666a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010666d:	89 04 24             	mov    %eax,(%esp)
c0106670:	e8 d0 fe ff ff       	call   c0106545 <perm2str>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
c0106675:	8b 4d dc             	mov    -0x24(%ebp),%ecx
c0106678:	8b 55 e0             	mov    -0x20(%ebp),%edx
c010667b:	29 d1                	sub    %edx,%ecx
c010667d:	89 ca                	mov    %ecx,%edx
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
c010667f:	89 d6                	mov    %edx,%esi
c0106681:	c1 e6 16             	shl    $0x16,%esi
c0106684:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0106687:	89 d3                	mov    %edx,%ebx
c0106689:	c1 e3 16             	shl    $0x16,%ebx
c010668c:	8b 55 e0             	mov    -0x20(%ebp),%edx
c010668f:	89 d1                	mov    %edx,%ecx
c0106691:	c1 e1 16             	shl    $0x16,%ecx
c0106694:	8b 7d dc             	mov    -0x24(%ebp),%edi
c0106697:	8b 55 e0             	mov    -0x20(%ebp),%edx
c010669a:	29 d7                	sub    %edx,%edi
c010669c:	89 fa                	mov    %edi,%edx
c010669e:	89 44 24 14          	mov    %eax,0x14(%esp)
c01066a2:	89 74 24 10          	mov    %esi,0x10(%esp)
c01066a6:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
c01066aa:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c01066ae:	89 54 24 04          	mov    %edx,0x4(%esp)
c01066b2:	c7 04 24 d5 87 10 c0 	movl   $0xc01087d5,(%esp)
c01066b9:	e8 96 9c ff ff       	call   c0100354 <cprintf>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
c01066be:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01066c1:	c1 e0 0a             	shl    $0xa,%eax
c01066c4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
c01066c7:	eb 54                	jmp    c010671d <print_pgdir+0xd4>
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
c01066c9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01066cc:	89 04 24             	mov    %eax,(%esp)
c01066cf:	e8 71 fe ff ff       	call   c0106545 <perm2str>
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
c01066d4:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
c01066d7:	8b 55 d8             	mov    -0x28(%ebp),%edx
c01066da:	29 d1                	sub    %edx,%ecx
c01066dc:	89 ca                	mov    %ecx,%edx
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
c01066de:	89 d6                	mov    %edx,%esi
c01066e0:	c1 e6 0c             	shl    $0xc,%esi
c01066e3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01066e6:	89 d3                	mov    %edx,%ebx
c01066e8:	c1 e3 0c             	shl    $0xc,%ebx
c01066eb:	8b 55 d8             	mov    -0x28(%ebp),%edx
c01066ee:	c1 e2 0c             	shl    $0xc,%edx
c01066f1:	89 d1                	mov    %edx,%ecx
c01066f3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
c01066f6:	8b 55 d8             	mov    -0x28(%ebp),%edx
c01066f9:	29 d7                	sub    %edx,%edi
c01066fb:	89 fa                	mov    %edi,%edx
c01066fd:	89 44 24 14          	mov    %eax,0x14(%esp)
c0106701:	89 74 24 10          	mov    %esi,0x10(%esp)
c0106705:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
c0106709:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c010670d:	89 54 24 04          	mov    %edx,0x4(%esp)
c0106711:	c7 04 24 f4 87 10 c0 	movl   $0xc01087f4,(%esp)
c0106718:	e8 37 9c ff ff       	call   c0100354 <cprintf>
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
c010671d:	ba 00 00 c0 fa       	mov    $0xfac00000,%edx
c0106722:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0106725:	8b 4d dc             	mov    -0x24(%ebp),%ecx
c0106728:	89 ce                	mov    %ecx,%esi
c010672a:	c1 e6 0a             	shl    $0xa,%esi
c010672d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
c0106730:	89 cb                	mov    %ecx,%ebx
c0106732:	c1 e3 0a             	shl    $0xa,%ebx
c0106735:	8d 4d d4             	lea    -0x2c(%ebp),%ecx
c0106738:	89 4c 24 14          	mov    %ecx,0x14(%esp)
c010673c:	8d 4d d8             	lea    -0x28(%ebp),%ecx
c010673f:	89 4c 24 10          	mov    %ecx,0x10(%esp)
c0106743:	89 54 24 0c          	mov    %edx,0xc(%esp)
c0106747:	89 44 24 08          	mov    %eax,0x8(%esp)
c010674b:	89 74 24 04          	mov    %esi,0x4(%esp)
c010674f:	89 1c 24             	mov    %ebx,(%esp)
c0106752:	e8 3c fe ff ff       	call   c0106593 <get_pgtable_items>
c0106757:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c010675a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c010675e:	0f 85 65 ff ff ff    	jne    c01066c9 <print_pgdir+0x80>
//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
c0106764:	ba 00 b0 fe fa       	mov    $0xfafeb000,%edx
c0106769:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010676c:	8d 4d dc             	lea    -0x24(%ebp),%ecx
c010676f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
c0106773:	8d 4d e0             	lea    -0x20(%ebp),%ecx
c0106776:	89 4c 24 10          	mov    %ecx,0x10(%esp)
c010677a:	89 54 24 0c          	mov    %edx,0xc(%esp)
c010677e:	89 44 24 08          	mov    %eax,0x8(%esp)
c0106782:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
c0106789:	00 
c010678a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c0106791:	e8 fd fd ff ff       	call   c0106593 <get_pgtable_items>
c0106796:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0106799:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c010679d:	0f 85 c7 fe ff ff    	jne    c010666a <print_pgdir+0x21>
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
        }
    }
    cprintf("--------------------- END ---------------------\n");
c01067a3:	c7 04 24 18 88 10 c0 	movl   $0xc0108818,(%esp)
c01067aa:	e8 a5 9b ff ff       	call   c0100354 <cprintf>
}
c01067af:	83 c4 4c             	add    $0x4c,%esp
c01067b2:	5b                   	pop    %ebx
c01067b3:	5e                   	pop    %esi
c01067b4:	5f                   	pop    %edi
c01067b5:	5d                   	pop    %ebp
c01067b6:	c3                   	ret    

c01067b7 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
c01067b7:	55                   	push   %ebp
c01067b8:	89 e5                	mov    %esp,%ebp
c01067ba:	83 ec 58             	sub    $0x58,%esp
c01067bd:	8b 45 10             	mov    0x10(%ebp),%eax
c01067c0:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01067c3:	8b 45 14             	mov    0x14(%ebp),%eax
c01067c6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    unsigned long long result = num;
c01067c9:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01067cc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01067cf:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01067d2:	89 55 ec             	mov    %edx,-0x14(%ebp)
    unsigned mod = do_div(result, base);
c01067d5:	8b 45 18             	mov    0x18(%ebp),%eax
c01067d8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01067db:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01067de:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01067e1:	89 45 e0             	mov    %eax,-0x20(%ebp)
c01067e4:	89 55 f0             	mov    %edx,-0x10(%ebp)
c01067e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01067ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01067ed:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01067f1:	74 1c                	je     c010680f <printnum+0x58>
c01067f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01067f6:	ba 00 00 00 00       	mov    $0x0,%edx
c01067fb:	f7 75 e4             	divl   -0x1c(%ebp)
c01067fe:	89 55 f4             	mov    %edx,-0xc(%ebp)
c0106801:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106804:	ba 00 00 00 00       	mov    $0x0,%edx
c0106809:	f7 75 e4             	divl   -0x1c(%ebp)
c010680c:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010680f:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0106812:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0106815:	f7 75 e4             	divl   -0x1c(%ebp)
c0106818:	89 45 e0             	mov    %eax,-0x20(%ebp)
c010681b:	89 55 dc             	mov    %edx,-0x24(%ebp)
c010681e:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0106821:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0106824:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0106827:	89 55 ec             	mov    %edx,-0x14(%ebp)
c010682a:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010682d:	89 45 d8             	mov    %eax,-0x28(%ebp)

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
c0106830:	8b 45 18             	mov    0x18(%ebp),%eax
c0106833:	ba 00 00 00 00       	mov    $0x0,%edx
c0106838:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c010683b:	77 56                	ja     c0106893 <printnum+0xdc>
c010683d:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0106840:	72 05                	jb     c0106847 <printnum+0x90>
c0106842:	3b 45 d0             	cmp    -0x30(%ebp),%eax
c0106845:	77 4c                	ja     c0106893 <printnum+0xdc>
        printnum(putch, putdat, result, base, width - 1, padc);
c0106847:	8b 45 1c             	mov    0x1c(%ebp),%eax
c010684a:	8d 50 ff             	lea    -0x1(%eax),%edx
c010684d:	8b 45 20             	mov    0x20(%ebp),%eax
c0106850:	89 44 24 18          	mov    %eax,0x18(%esp)
c0106854:	89 54 24 14          	mov    %edx,0x14(%esp)
c0106858:	8b 45 18             	mov    0x18(%ebp),%eax
c010685b:	89 44 24 10          	mov    %eax,0x10(%esp)
c010685f:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0106862:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0106865:	89 44 24 08          	mov    %eax,0x8(%esp)
c0106869:	89 54 24 0c          	mov    %edx,0xc(%esp)
c010686d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106870:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106874:	8b 45 08             	mov    0x8(%ebp),%eax
c0106877:	89 04 24             	mov    %eax,(%esp)
c010687a:	e8 38 ff ff ff       	call   c01067b7 <printnum>
c010687f:	eb 1c                	jmp    c010689d <printnum+0xe6>
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
            putch(padc, putdat);
c0106881:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106884:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106888:	8b 45 20             	mov    0x20(%ebp),%eax
c010688b:	89 04 24             	mov    %eax,(%esp)
c010688e:	8b 45 08             	mov    0x8(%ebp),%eax
c0106891:	ff d0                	call   *%eax
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
c0106893:	83 6d 1c 01          	subl   $0x1,0x1c(%ebp)
c0106897:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
c010689b:	7f e4                	jg     c0106881 <printnum+0xca>
            putch(padc, putdat);
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
c010689d:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01068a0:	05 cc 88 10 c0       	add    $0xc01088cc,%eax
c01068a5:	0f b6 00             	movzbl (%eax),%eax
c01068a8:	0f be c0             	movsbl %al,%eax
c01068ab:	8b 55 0c             	mov    0xc(%ebp),%edx
c01068ae:	89 54 24 04          	mov    %edx,0x4(%esp)
c01068b2:	89 04 24             	mov    %eax,(%esp)
c01068b5:	8b 45 08             	mov    0x8(%ebp),%eax
c01068b8:	ff d0                	call   *%eax
}
c01068ba:	c9                   	leave  
c01068bb:	c3                   	ret    

c01068bc <getuint>:
 * getuint - get an unsigned int of various possible sizes from a varargs list
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static unsigned long long
getuint(va_list *ap, int lflag) {
c01068bc:	55                   	push   %ebp
c01068bd:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
c01068bf:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
c01068c3:	7e 14                	jle    c01068d9 <getuint+0x1d>
        return va_arg(*ap, unsigned long long);
c01068c5:	8b 45 08             	mov    0x8(%ebp),%eax
c01068c8:	8b 00                	mov    (%eax),%eax
c01068ca:	8d 48 08             	lea    0x8(%eax),%ecx
c01068cd:	8b 55 08             	mov    0x8(%ebp),%edx
c01068d0:	89 0a                	mov    %ecx,(%edx)
c01068d2:	8b 50 04             	mov    0x4(%eax),%edx
c01068d5:	8b 00                	mov    (%eax),%eax
c01068d7:	eb 30                	jmp    c0106909 <getuint+0x4d>
    }
    else if (lflag) {
c01068d9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c01068dd:	74 16                	je     c01068f5 <getuint+0x39>
        return va_arg(*ap, unsigned long);
c01068df:	8b 45 08             	mov    0x8(%ebp),%eax
c01068e2:	8b 00                	mov    (%eax),%eax
c01068e4:	8d 48 04             	lea    0x4(%eax),%ecx
c01068e7:	8b 55 08             	mov    0x8(%ebp),%edx
c01068ea:	89 0a                	mov    %ecx,(%edx)
c01068ec:	8b 00                	mov    (%eax),%eax
c01068ee:	ba 00 00 00 00       	mov    $0x0,%edx
c01068f3:	eb 14                	jmp    c0106909 <getuint+0x4d>
    }
    else {
        return va_arg(*ap, unsigned int);
c01068f5:	8b 45 08             	mov    0x8(%ebp),%eax
c01068f8:	8b 00                	mov    (%eax),%eax
c01068fa:	8d 48 04             	lea    0x4(%eax),%ecx
c01068fd:	8b 55 08             	mov    0x8(%ebp),%edx
c0106900:	89 0a                	mov    %ecx,(%edx)
c0106902:	8b 00                	mov    (%eax),%eax
c0106904:	ba 00 00 00 00       	mov    $0x0,%edx
    }
}
c0106909:	5d                   	pop    %ebp
c010690a:	c3                   	ret    

c010690b <getint>:
 * getint - same as getuint but signed, we can't use getuint because of sign extension
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static long long
getint(va_list *ap, int lflag) {
c010690b:	55                   	push   %ebp
c010690c:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
c010690e:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
c0106912:	7e 14                	jle    c0106928 <getint+0x1d>
        return va_arg(*ap, long long);
c0106914:	8b 45 08             	mov    0x8(%ebp),%eax
c0106917:	8b 00                	mov    (%eax),%eax
c0106919:	8d 48 08             	lea    0x8(%eax),%ecx
c010691c:	8b 55 08             	mov    0x8(%ebp),%edx
c010691f:	89 0a                	mov    %ecx,(%edx)
c0106921:	8b 50 04             	mov    0x4(%eax),%edx
c0106924:	8b 00                	mov    (%eax),%eax
c0106926:	eb 28                	jmp    c0106950 <getint+0x45>
    }
    else if (lflag) {
c0106928:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c010692c:	74 12                	je     c0106940 <getint+0x35>
        return va_arg(*ap, long);
c010692e:	8b 45 08             	mov    0x8(%ebp),%eax
c0106931:	8b 00                	mov    (%eax),%eax
c0106933:	8d 48 04             	lea    0x4(%eax),%ecx
c0106936:	8b 55 08             	mov    0x8(%ebp),%edx
c0106939:	89 0a                	mov    %ecx,(%edx)
c010693b:	8b 00                	mov    (%eax),%eax
c010693d:	99                   	cltd   
c010693e:	eb 10                	jmp    c0106950 <getint+0x45>
    }
    else {
        return va_arg(*ap, int);
c0106940:	8b 45 08             	mov    0x8(%ebp),%eax
c0106943:	8b 00                	mov    (%eax),%eax
c0106945:	8d 48 04             	lea    0x4(%eax),%ecx
c0106948:	8b 55 08             	mov    0x8(%ebp),%edx
c010694b:	89 0a                	mov    %ecx,(%edx)
c010694d:	8b 00                	mov    (%eax),%eax
c010694f:	99                   	cltd   
    }
}
c0106950:	5d                   	pop    %ebp
c0106951:	c3                   	ret    

c0106952 <printfmt>:
 * @putch:      specified putch function, print a single character
 * @putdat:     used by @putch function
 * @fmt:        the format string to use
 * */
void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
c0106952:	55                   	push   %ebp
c0106953:	89 e5                	mov    %esp,%ebp
c0106955:	83 ec 28             	sub    $0x28,%esp
    va_list ap;

    va_start(ap, fmt);
c0106958:	8d 45 14             	lea    0x14(%ebp),%eax
c010695b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    vprintfmt(putch, putdat, fmt, ap);
c010695e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106961:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0106965:	8b 45 10             	mov    0x10(%ebp),%eax
c0106968:	89 44 24 08          	mov    %eax,0x8(%esp)
c010696c:	8b 45 0c             	mov    0xc(%ebp),%eax
c010696f:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106973:	8b 45 08             	mov    0x8(%ebp),%eax
c0106976:	89 04 24             	mov    %eax,(%esp)
c0106979:	e8 02 00 00 00       	call   c0106980 <vprintfmt>
    va_end(ap);
}
c010697e:	c9                   	leave  
c010697f:	c3                   	ret    

c0106980 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
c0106980:	55                   	push   %ebp
c0106981:	89 e5                	mov    %esp,%ebp
c0106983:	56                   	push   %esi
c0106984:	53                   	push   %ebx
c0106985:	83 ec 40             	sub    $0x40,%esp
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c0106988:	eb 18                	jmp    c01069a2 <vprintfmt+0x22>
            if (ch == '\0') {
c010698a:	85 db                	test   %ebx,%ebx
c010698c:	75 05                	jne    c0106993 <vprintfmt+0x13>
                return;
c010698e:	e9 d1 03 00 00       	jmp    c0106d64 <vprintfmt+0x3e4>
            }
            putch(ch, putdat);
c0106993:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106996:	89 44 24 04          	mov    %eax,0x4(%esp)
c010699a:	89 1c 24             	mov    %ebx,(%esp)
c010699d:	8b 45 08             	mov    0x8(%ebp),%eax
c01069a0:	ff d0                	call   *%eax
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c01069a2:	8b 45 10             	mov    0x10(%ebp),%eax
c01069a5:	8d 50 01             	lea    0x1(%eax),%edx
c01069a8:	89 55 10             	mov    %edx,0x10(%ebp)
c01069ab:	0f b6 00             	movzbl (%eax),%eax
c01069ae:	0f b6 d8             	movzbl %al,%ebx
c01069b1:	83 fb 25             	cmp    $0x25,%ebx
c01069b4:	75 d4                	jne    c010698a <vprintfmt+0xa>
            }
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
c01069b6:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
        width = precision = -1;
c01069ba:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
c01069c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01069c4:	89 45 e8             	mov    %eax,-0x18(%ebp)
        lflag = altflag = 0;
c01069c7:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c01069ce:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01069d1:	89 45 e0             	mov    %eax,-0x20(%ebp)

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
c01069d4:	8b 45 10             	mov    0x10(%ebp),%eax
c01069d7:	8d 50 01             	lea    0x1(%eax),%edx
c01069da:	89 55 10             	mov    %edx,0x10(%ebp)
c01069dd:	0f b6 00             	movzbl (%eax),%eax
c01069e0:	0f b6 d8             	movzbl %al,%ebx
c01069e3:	8d 43 dd             	lea    -0x23(%ebx),%eax
c01069e6:	83 f8 55             	cmp    $0x55,%eax
c01069e9:	0f 87 44 03 00 00    	ja     c0106d33 <vprintfmt+0x3b3>
c01069ef:	8b 04 85 f0 88 10 c0 	mov    -0x3fef7710(,%eax,4),%eax
c01069f6:	ff e0                	jmp    *%eax

        // flag to pad on the right
        case '-':
            padc = '-';
c01069f8:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
            goto reswitch;
c01069fc:	eb d6                	jmp    c01069d4 <vprintfmt+0x54>

        // flag to pad with 0's instead of spaces
        case '0':
            padc = '0';
c01069fe:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
            goto reswitch;
c0106a02:	eb d0                	jmp    c01069d4 <vprintfmt+0x54>

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
c0106a04:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
                precision = precision * 10 + ch - '0';
c0106a0b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0106a0e:	89 d0                	mov    %edx,%eax
c0106a10:	c1 e0 02             	shl    $0x2,%eax
c0106a13:	01 d0                	add    %edx,%eax
c0106a15:	01 c0                	add    %eax,%eax
c0106a17:	01 d8                	add    %ebx,%eax
c0106a19:	83 e8 30             	sub    $0x30,%eax
c0106a1c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
                ch = *fmt;
c0106a1f:	8b 45 10             	mov    0x10(%ebp),%eax
c0106a22:	0f b6 00             	movzbl (%eax),%eax
c0106a25:	0f be d8             	movsbl %al,%ebx
                if (ch < '0' || ch > '9') {
c0106a28:	83 fb 2f             	cmp    $0x2f,%ebx
c0106a2b:	7e 0b                	jle    c0106a38 <vprintfmt+0xb8>
c0106a2d:	83 fb 39             	cmp    $0x39,%ebx
c0106a30:	7f 06                	jg     c0106a38 <vprintfmt+0xb8>
            padc = '0';
            goto reswitch;

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
c0106a32:	83 45 10 01          	addl   $0x1,0x10(%ebp)
                precision = precision * 10 + ch - '0';
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
c0106a36:	eb d3                	jmp    c0106a0b <vprintfmt+0x8b>
            goto process_precision;
c0106a38:	eb 33                	jmp    c0106a6d <vprintfmt+0xed>

        case '*':
            precision = va_arg(ap, int);
c0106a3a:	8b 45 14             	mov    0x14(%ebp),%eax
c0106a3d:	8d 50 04             	lea    0x4(%eax),%edx
c0106a40:	89 55 14             	mov    %edx,0x14(%ebp)
c0106a43:	8b 00                	mov    (%eax),%eax
c0106a45:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            goto process_precision;
c0106a48:	eb 23                	jmp    c0106a6d <vprintfmt+0xed>

        case '.':
            if (width < 0)
c0106a4a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0106a4e:	79 0c                	jns    c0106a5c <vprintfmt+0xdc>
                width = 0;
c0106a50:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
            goto reswitch;
c0106a57:	e9 78 ff ff ff       	jmp    c01069d4 <vprintfmt+0x54>
c0106a5c:	e9 73 ff ff ff       	jmp    c01069d4 <vprintfmt+0x54>

        case '#':
            altflag = 1;
c0106a61:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
            goto reswitch;
c0106a68:	e9 67 ff ff ff       	jmp    c01069d4 <vprintfmt+0x54>

        process_precision:
            if (width < 0)
c0106a6d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0106a71:	79 12                	jns    c0106a85 <vprintfmt+0x105>
                width = precision, precision = -1;
c0106a73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0106a76:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0106a79:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
            goto reswitch;
c0106a80:	e9 4f ff ff ff       	jmp    c01069d4 <vprintfmt+0x54>
c0106a85:	e9 4a ff ff ff       	jmp    c01069d4 <vprintfmt+0x54>

        // long flag (doubled for long long)
        case 'l':
            lflag ++;
c0106a8a:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
            goto reswitch;
c0106a8e:	e9 41 ff ff ff       	jmp    c01069d4 <vprintfmt+0x54>

        // character
        case 'c':
            putch(va_arg(ap, int), putdat);
c0106a93:	8b 45 14             	mov    0x14(%ebp),%eax
c0106a96:	8d 50 04             	lea    0x4(%eax),%edx
c0106a99:	89 55 14             	mov    %edx,0x14(%ebp)
c0106a9c:	8b 00                	mov    (%eax),%eax
c0106a9e:	8b 55 0c             	mov    0xc(%ebp),%edx
c0106aa1:	89 54 24 04          	mov    %edx,0x4(%esp)
c0106aa5:	89 04 24             	mov    %eax,(%esp)
c0106aa8:	8b 45 08             	mov    0x8(%ebp),%eax
c0106aab:	ff d0                	call   *%eax
            break;
c0106aad:	e9 ac 02 00 00       	jmp    c0106d5e <vprintfmt+0x3de>

        // error message
        case 'e':
            err = va_arg(ap, int);
c0106ab2:	8b 45 14             	mov    0x14(%ebp),%eax
c0106ab5:	8d 50 04             	lea    0x4(%eax),%edx
c0106ab8:	89 55 14             	mov    %edx,0x14(%ebp)
c0106abb:	8b 18                	mov    (%eax),%ebx
            if (err < 0) {
c0106abd:	85 db                	test   %ebx,%ebx
c0106abf:	79 02                	jns    c0106ac3 <vprintfmt+0x143>
                err = -err;
c0106ac1:	f7 db                	neg    %ebx
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
c0106ac3:	83 fb 06             	cmp    $0x6,%ebx
c0106ac6:	7f 0b                	jg     c0106ad3 <vprintfmt+0x153>
c0106ac8:	8b 34 9d b0 88 10 c0 	mov    -0x3fef7750(,%ebx,4),%esi
c0106acf:	85 f6                	test   %esi,%esi
c0106ad1:	75 23                	jne    c0106af6 <vprintfmt+0x176>
                printfmt(putch, putdat, "error %d", err);
c0106ad3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
c0106ad7:	c7 44 24 08 dd 88 10 	movl   $0xc01088dd,0x8(%esp)
c0106ade:	c0 
c0106adf:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106ae2:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106ae6:	8b 45 08             	mov    0x8(%ebp),%eax
c0106ae9:	89 04 24             	mov    %eax,(%esp)
c0106aec:	e8 61 fe ff ff       	call   c0106952 <printfmt>
            }
            else {
                printfmt(putch, putdat, "%s", p);
            }
            break;
c0106af1:	e9 68 02 00 00       	jmp    c0106d5e <vprintfmt+0x3de>
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
                printfmt(putch, putdat, "error %d", err);
            }
            else {
                printfmt(putch, putdat, "%s", p);
c0106af6:	89 74 24 0c          	mov    %esi,0xc(%esp)
c0106afa:	c7 44 24 08 e6 88 10 	movl   $0xc01088e6,0x8(%esp)
c0106b01:	c0 
c0106b02:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106b05:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106b09:	8b 45 08             	mov    0x8(%ebp),%eax
c0106b0c:	89 04 24             	mov    %eax,(%esp)
c0106b0f:	e8 3e fe ff ff       	call   c0106952 <printfmt>
            }
            break;
c0106b14:	e9 45 02 00 00       	jmp    c0106d5e <vprintfmt+0x3de>

        // string
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
c0106b19:	8b 45 14             	mov    0x14(%ebp),%eax
c0106b1c:	8d 50 04             	lea    0x4(%eax),%edx
c0106b1f:	89 55 14             	mov    %edx,0x14(%ebp)
c0106b22:	8b 30                	mov    (%eax),%esi
c0106b24:	85 f6                	test   %esi,%esi
c0106b26:	75 05                	jne    c0106b2d <vprintfmt+0x1ad>
                p = "(null)";
c0106b28:	be e9 88 10 c0       	mov    $0xc01088e9,%esi
            }
            if (width > 0 && padc != '-') {
c0106b2d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0106b31:	7e 3e                	jle    c0106b71 <vprintfmt+0x1f1>
c0106b33:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
c0106b37:	74 38                	je     c0106b71 <vprintfmt+0x1f1>
                for (width -= strnlen(p, precision); width > 0; width --) {
c0106b39:	8b 5d e8             	mov    -0x18(%ebp),%ebx
c0106b3c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0106b3f:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106b43:	89 34 24             	mov    %esi,(%esp)
c0106b46:	e8 15 03 00 00       	call   c0106e60 <strnlen>
c0106b4b:	29 c3                	sub    %eax,%ebx
c0106b4d:	89 d8                	mov    %ebx,%eax
c0106b4f:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0106b52:	eb 17                	jmp    c0106b6b <vprintfmt+0x1eb>
                    putch(padc, putdat);
c0106b54:	0f be 45 db          	movsbl -0x25(%ebp),%eax
c0106b58:	8b 55 0c             	mov    0xc(%ebp),%edx
c0106b5b:	89 54 24 04          	mov    %edx,0x4(%esp)
c0106b5f:	89 04 24             	mov    %eax,(%esp)
c0106b62:	8b 45 08             	mov    0x8(%ebp),%eax
c0106b65:	ff d0                	call   *%eax
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
                p = "(null)";
            }
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
c0106b67:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
c0106b6b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0106b6f:	7f e3                	jg     c0106b54 <vprintfmt+0x1d4>
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
c0106b71:	eb 38                	jmp    c0106bab <vprintfmt+0x22b>
                if (altflag && (ch < ' ' || ch > '~')) {
c0106b73:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0106b77:	74 1f                	je     c0106b98 <vprintfmt+0x218>
c0106b79:	83 fb 1f             	cmp    $0x1f,%ebx
c0106b7c:	7e 05                	jle    c0106b83 <vprintfmt+0x203>
c0106b7e:	83 fb 7e             	cmp    $0x7e,%ebx
c0106b81:	7e 15                	jle    c0106b98 <vprintfmt+0x218>
                    putch('?', putdat);
c0106b83:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106b86:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106b8a:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
c0106b91:	8b 45 08             	mov    0x8(%ebp),%eax
c0106b94:	ff d0                	call   *%eax
c0106b96:	eb 0f                	jmp    c0106ba7 <vprintfmt+0x227>
                }
                else {
                    putch(ch, putdat);
c0106b98:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106b9b:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106b9f:	89 1c 24             	mov    %ebx,(%esp)
c0106ba2:	8b 45 08             	mov    0x8(%ebp),%eax
c0106ba5:	ff d0                	call   *%eax
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
c0106ba7:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
c0106bab:	89 f0                	mov    %esi,%eax
c0106bad:	8d 70 01             	lea    0x1(%eax),%esi
c0106bb0:	0f b6 00             	movzbl (%eax),%eax
c0106bb3:	0f be d8             	movsbl %al,%ebx
c0106bb6:	85 db                	test   %ebx,%ebx
c0106bb8:	74 10                	je     c0106bca <vprintfmt+0x24a>
c0106bba:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0106bbe:	78 b3                	js     c0106b73 <vprintfmt+0x1f3>
c0106bc0:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
c0106bc4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0106bc8:	79 a9                	jns    c0106b73 <vprintfmt+0x1f3>
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
c0106bca:	eb 17                	jmp    c0106be3 <vprintfmt+0x263>
                putch(' ', putdat);
c0106bcc:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106bcf:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106bd3:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
c0106bda:	8b 45 08             	mov    0x8(%ebp),%eax
c0106bdd:	ff d0                	call   *%eax
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
c0106bdf:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
c0106be3:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0106be7:	7f e3                	jg     c0106bcc <vprintfmt+0x24c>
                putch(' ', putdat);
            }
            break;
c0106be9:	e9 70 01 00 00       	jmp    c0106d5e <vprintfmt+0x3de>

        // (signed) decimal
        case 'd':
            num = getint(&ap, lflag);
c0106bee:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0106bf1:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106bf5:	8d 45 14             	lea    0x14(%ebp),%eax
c0106bf8:	89 04 24             	mov    %eax,(%esp)
c0106bfb:	e8 0b fd ff ff       	call   c010690b <getint>
c0106c00:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0106c03:	89 55 f4             	mov    %edx,-0xc(%ebp)
            if ((long long)num < 0) {
c0106c06:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106c09:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0106c0c:	85 d2                	test   %edx,%edx
c0106c0e:	79 26                	jns    c0106c36 <vprintfmt+0x2b6>
                putch('-', putdat);
c0106c10:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106c13:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106c17:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
c0106c1e:	8b 45 08             	mov    0x8(%ebp),%eax
c0106c21:	ff d0                	call   *%eax
                num = -(long long)num;
c0106c23:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106c26:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0106c29:	f7 d8                	neg    %eax
c0106c2b:	83 d2 00             	adc    $0x0,%edx
c0106c2e:	f7 da                	neg    %edx
c0106c30:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0106c33:	89 55 f4             	mov    %edx,-0xc(%ebp)
            }
            base = 10;
c0106c36:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
c0106c3d:	e9 a8 00 00 00       	jmp    c0106cea <vprintfmt+0x36a>

        // unsigned decimal
        case 'u':
            num = getuint(&ap, lflag);
c0106c42:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0106c45:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106c49:	8d 45 14             	lea    0x14(%ebp),%eax
c0106c4c:	89 04 24             	mov    %eax,(%esp)
c0106c4f:	e8 68 fc ff ff       	call   c01068bc <getuint>
c0106c54:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0106c57:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 10;
c0106c5a:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
c0106c61:	e9 84 00 00 00       	jmp    c0106cea <vprintfmt+0x36a>

        // (unsigned) octal
        case 'o':
            num = getuint(&ap, lflag);
c0106c66:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0106c69:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106c6d:	8d 45 14             	lea    0x14(%ebp),%eax
c0106c70:	89 04 24             	mov    %eax,(%esp)
c0106c73:	e8 44 fc ff ff       	call   c01068bc <getuint>
c0106c78:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0106c7b:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 8;
c0106c7e:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
            goto number;
c0106c85:	eb 63                	jmp    c0106cea <vprintfmt+0x36a>

        // pointer
        case 'p':
            putch('0', putdat);
c0106c87:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106c8a:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106c8e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
c0106c95:	8b 45 08             	mov    0x8(%ebp),%eax
c0106c98:	ff d0                	call   *%eax
            putch('x', putdat);
c0106c9a:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106c9d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106ca1:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
c0106ca8:	8b 45 08             	mov    0x8(%ebp),%eax
c0106cab:	ff d0                	call   *%eax
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
c0106cad:	8b 45 14             	mov    0x14(%ebp),%eax
c0106cb0:	8d 50 04             	lea    0x4(%eax),%edx
c0106cb3:	89 55 14             	mov    %edx,0x14(%ebp)
c0106cb6:	8b 00                	mov    (%eax),%eax
c0106cb8:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0106cbb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
            base = 16;
c0106cc2:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
            goto number;
c0106cc9:	eb 1f                	jmp    c0106cea <vprintfmt+0x36a>

        // (unsigned) hexadecimal
        case 'x':
            num = getuint(&ap, lflag);
c0106ccb:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0106cce:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106cd2:	8d 45 14             	lea    0x14(%ebp),%eax
c0106cd5:	89 04 24             	mov    %eax,(%esp)
c0106cd8:	e8 df fb ff ff       	call   c01068bc <getuint>
c0106cdd:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0106ce0:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 16;
c0106ce3:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
        number:
            printnum(putch, putdat, num, base, width, padc);
c0106cea:	0f be 55 db          	movsbl -0x25(%ebp),%edx
c0106cee:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0106cf1:	89 54 24 18          	mov    %edx,0x18(%esp)
c0106cf5:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0106cf8:	89 54 24 14          	mov    %edx,0x14(%esp)
c0106cfc:	89 44 24 10          	mov    %eax,0x10(%esp)
c0106d00:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106d03:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0106d06:	89 44 24 08          	mov    %eax,0x8(%esp)
c0106d0a:	89 54 24 0c          	mov    %edx,0xc(%esp)
c0106d0e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106d11:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106d15:	8b 45 08             	mov    0x8(%ebp),%eax
c0106d18:	89 04 24             	mov    %eax,(%esp)
c0106d1b:	e8 97 fa ff ff       	call   c01067b7 <printnum>
            break;
c0106d20:	eb 3c                	jmp    c0106d5e <vprintfmt+0x3de>

        // escaped '%' character
        case '%':
            putch(ch, putdat);
c0106d22:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106d25:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106d29:	89 1c 24             	mov    %ebx,(%esp)
c0106d2c:	8b 45 08             	mov    0x8(%ebp),%eax
c0106d2f:	ff d0                	call   *%eax
            break;
c0106d31:	eb 2b                	jmp    c0106d5e <vprintfmt+0x3de>

        // unrecognized escape sequence - just print it literally
        default:
            putch('%', putdat);
c0106d33:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106d36:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106d3a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
c0106d41:	8b 45 08             	mov    0x8(%ebp),%eax
c0106d44:	ff d0                	call   *%eax
            for (fmt --; fmt[-1] != '%'; fmt --)
c0106d46:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
c0106d4a:	eb 04                	jmp    c0106d50 <vprintfmt+0x3d0>
c0106d4c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
c0106d50:	8b 45 10             	mov    0x10(%ebp),%eax
c0106d53:	83 e8 01             	sub    $0x1,%eax
c0106d56:	0f b6 00             	movzbl (%eax),%eax
c0106d59:	3c 25                	cmp    $0x25,%al
c0106d5b:	75 ef                	jne    c0106d4c <vprintfmt+0x3cc>
                /* do nothing */;
            break;
c0106d5d:	90                   	nop
        }
    }
c0106d5e:	90                   	nop
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c0106d5f:	e9 3e fc ff ff       	jmp    c01069a2 <vprintfmt+0x22>
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
c0106d64:	83 c4 40             	add    $0x40,%esp
c0106d67:	5b                   	pop    %ebx
c0106d68:	5e                   	pop    %esi
c0106d69:	5d                   	pop    %ebp
c0106d6a:	c3                   	ret    

c0106d6b <sprintputch>:
 * sprintputch - 'print' a single character in a buffer
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
c0106d6b:	55                   	push   %ebp
c0106d6c:	89 e5                	mov    %esp,%ebp
    b->cnt ++;
c0106d6e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106d71:	8b 40 08             	mov    0x8(%eax),%eax
c0106d74:	8d 50 01             	lea    0x1(%eax),%edx
c0106d77:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106d7a:	89 50 08             	mov    %edx,0x8(%eax)
    if (b->buf < b->ebuf) {
c0106d7d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106d80:	8b 10                	mov    (%eax),%edx
c0106d82:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106d85:	8b 40 04             	mov    0x4(%eax),%eax
c0106d88:	39 c2                	cmp    %eax,%edx
c0106d8a:	73 12                	jae    c0106d9e <sprintputch+0x33>
        *b->buf ++ = ch;
c0106d8c:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106d8f:	8b 00                	mov    (%eax),%eax
c0106d91:	8d 48 01             	lea    0x1(%eax),%ecx
c0106d94:	8b 55 0c             	mov    0xc(%ebp),%edx
c0106d97:	89 0a                	mov    %ecx,(%edx)
c0106d99:	8b 55 08             	mov    0x8(%ebp),%edx
c0106d9c:	88 10                	mov    %dl,(%eax)
    }
}
c0106d9e:	5d                   	pop    %ebp
c0106d9f:	c3                   	ret    

c0106da0 <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
c0106da0:	55                   	push   %ebp
c0106da1:	89 e5                	mov    %esp,%ebp
c0106da3:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
c0106da6:	8d 45 14             	lea    0x14(%ebp),%eax
c0106da9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vsnprintf(str, size, fmt, ap);
c0106dac:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106daf:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0106db3:	8b 45 10             	mov    0x10(%ebp),%eax
c0106db6:	89 44 24 08          	mov    %eax,0x8(%esp)
c0106dba:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106dbd:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106dc1:	8b 45 08             	mov    0x8(%ebp),%eax
c0106dc4:	89 04 24             	mov    %eax,(%esp)
c0106dc7:	e8 08 00 00 00       	call   c0106dd4 <vsnprintf>
c0106dcc:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
c0106dcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0106dd2:	c9                   	leave  
c0106dd3:	c3                   	ret    

c0106dd4 <vsnprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
c0106dd4:	55                   	push   %ebp
c0106dd5:	89 e5                	mov    %esp,%ebp
c0106dd7:	83 ec 28             	sub    $0x28,%esp
    struct sprintbuf b = {str, str + size - 1, 0};
c0106dda:	8b 45 08             	mov    0x8(%ebp),%eax
c0106ddd:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0106de0:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106de3:	8d 50 ff             	lea    -0x1(%eax),%edx
c0106de6:	8b 45 08             	mov    0x8(%ebp),%eax
c0106de9:	01 d0                	add    %edx,%eax
c0106deb:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0106dee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if (str == NULL || b.buf > b.ebuf) {
c0106df5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0106df9:	74 0a                	je     c0106e05 <vsnprintf+0x31>
c0106dfb:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0106dfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106e01:	39 c2                	cmp    %eax,%edx
c0106e03:	76 07                	jbe    c0106e0c <vsnprintf+0x38>
        return -E_INVAL;
c0106e05:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
c0106e0a:	eb 2a                	jmp    c0106e36 <vsnprintf+0x62>
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
c0106e0c:	8b 45 14             	mov    0x14(%ebp),%eax
c0106e0f:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0106e13:	8b 45 10             	mov    0x10(%ebp),%eax
c0106e16:	89 44 24 08          	mov    %eax,0x8(%esp)
c0106e1a:	8d 45 ec             	lea    -0x14(%ebp),%eax
c0106e1d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106e21:	c7 04 24 6b 6d 10 c0 	movl   $0xc0106d6b,(%esp)
c0106e28:	e8 53 fb ff ff       	call   c0106980 <vprintfmt>
    // null terminate the buffer
    *b.buf = '\0';
c0106e2d:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0106e30:	c6 00 00             	movb   $0x0,(%eax)
    return b.cnt;
c0106e33:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0106e36:	c9                   	leave  
c0106e37:	c3                   	ret    

c0106e38 <strlen>:
 * @s:      the input string
 *
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
c0106e38:	55                   	push   %ebp
c0106e39:	89 e5                	mov    %esp,%ebp
c0106e3b:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
c0106e3e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (*s ++ != '\0') {
c0106e45:	eb 04                	jmp    c0106e4b <strlen+0x13>
        cnt ++;
c0106e47:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
c0106e4b:	8b 45 08             	mov    0x8(%ebp),%eax
c0106e4e:	8d 50 01             	lea    0x1(%eax),%edx
c0106e51:	89 55 08             	mov    %edx,0x8(%ebp)
c0106e54:	0f b6 00             	movzbl (%eax),%eax
c0106e57:	84 c0                	test   %al,%al
c0106e59:	75 ec                	jne    c0106e47 <strlen+0xf>
        cnt ++;
    }
    return cnt;
c0106e5b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0106e5e:	c9                   	leave  
c0106e5f:	c3                   	ret    

c0106e60 <strnlen>:
 * The return value is strlen(s), if that is less than @len, or
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
c0106e60:	55                   	push   %ebp
c0106e61:	89 e5                	mov    %esp,%ebp
c0106e63:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
c0106e66:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (cnt < len && *s ++ != '\0') {
c0106e6d:	eb 04                	jmp    c0106e73 <strnlen+0x13>
        cnt ++;
c0106e6f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
c0106e73:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0106e76:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0106e79:	73 10                	jae    c0106e8b <strnlen+0x2b>
c0106e7b:	8b 45 08             	mov    0x8(%ebp),%eax
c0106e7e:	8d 50 01             	lea    0x1(%eax),%edx
c0106e81:	89 55 08             	mov    %edx,0x8(%ebp)
c0106e84:	0f b6 00             	movzbl (%eax),%eax
c0106e87:	84 c0                	test   %al,%al
c0106e89:	75 e4                	jne    c0106e6f <strnlen+0xf>
        cnt ++;
    }
    return cnt;
c0106e8b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0106e8e:	c9                   	leave  
c0106e8f:	c3                   	ret    

c0106e90 <strcpy>:
 * To avoid overflows, the size of array pointed by @dst should be long enough to
 * contain the same string as @src (including the terminating null character), and
 * should not overlap in memory with @src.
 * */
char *
strcpy(char *dst, const char *src) {
c0106e90:	55                   	push   %ebp
c0106e91:	89 e5                	mov    %esp,%ebp
c0106e93:	57                   	push   %edi
c0106e94:	56                   	push   %esi
c0106e95:	83 ec 20             	sub    $0x20,%esp
c0106e98:	8b 45 08             	mov    0x8(%ebp),%eax
c0106e9b:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0106e9e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106ea1:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCPY
#define __HAVE_ARCH_STRCPY
static inline char *
__strcpy(char *dst, const char *src) {
    int d0, d1, d2;
    asm volatile (
c0106ea4:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0106ea7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106eaa:	89 d1                	mov    %edx,%ecx
c0106eac:	89 c2                	mov    %eax,%edx
c0106eae:	89 ce                	mov    %ecx,%esi
c0106eb0:	89 d7                	mov    %edx,%edi
c0106eb2:	ac                   	lods   %ds:(%esi),%al
c0106eb3:	aa                   	stos   %al,%es:(%edi)
c0106eb4:	84 c0                	test   %al,%al
c0106eb6:	75 fa                	jne    c0106eb2 <strcpy+0x22>
c0106eb8:	89 fa                	mov    %edi,%edx
c0106eba:	89 f1                	mov    %esi,%ecx
c0106ebc:	89 4d ec             	mov    %ecx,-0x14(%ebp)
c0106ebf:	89 55 e8             	mov    %edx,-0x18(%ebp)
c0106ec2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        "stosb;"
        "testb %%al, %%al;"
        "jne 1b;"
        : "=&S" (d0), "=&D" (d1), "=&a" (d2)
        : "0" (src), "1" (dst) : "memory");
    return dst;
c0106ec5:	8b 45 f4             	mov    -0xc(%ebp),%eax
    char *p = dst;
    while ((*p ++ = *src ++) != '\0')
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
c0106ec8:	83 c4 20             	add    $0x20,%esp
c0106ecb:	5e                   	pop    %esi
c0106ecc:	5f                   	pop    %edi
c0106ecd:	5d                   	pop    %ebp
c0106ece:	c3                   	ret    

c0106ecf <strncpy>:
 * @len:    maximum number of characters to be copied from @src
 *
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
c0106ecf:	55                   	push   %ebp
c0106ed0:	89 e5                	mov    %esp,%ebp
c0106ed2:	83 ec 10             	sub    $0x10,%esp
    char *p = dst;
c0106ed5:	8b 45 08             	mov    0x8(%ebp),%eax
c0106ed8:	89 45 fc             	mov    %eax,-0x4(%ebp)
    while (len > 0) {
c0106edb:	eb 21                	jmp    c0106efe <strncpy+0x2f>
        if ((*p = *src) != '\0') {
c0106edd:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106ee0:	0f b6 10             	movzbl (%eax),%edx
c0106ee3:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0106ee6:	88 10                	mov    %dl,(%eax)
c0106ee8:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0106eeb:	0f b6 00             	movzbl (%eax),%eax
c0106eee:	84 c0                	test   %al,%al
c0106ef0:	74 04                	je     c0106ef6 <strncpy+0x27>
            src ++;
c0106ef2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
        }
        p ++, len --;
c0106ef6:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c0106efa:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
    char *p = dst;
    while (len > 0) {
c0106efe:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0106f02:	75 d9                	jne    c0106edd <strncpy+0xe>
        if ((*p = *src) != '\0') {
            src ++;
        }
        p ++, len --;
    }
    return dst;
c0106f04:	8b 45 08             	mov    0x8(%ebp),%eax
}
c0106f07:	c9                   	leave  
c0106f08:	c3                   	ret    

c0106f09 <strcmp>:
 * - A value greater than zero indicates that the first character that does
 *   not match has a greater value in @s1 than in @s2;
 * - And a value less than zero indicates the opposite.
 * */
int
strcmp(const char *s1, const char *s2) {
c0106f09:	55                   	push   %ebp
c0106f0a:	89 e5                	mov    %esp,%ebp
c0106f0c:	57                   	push   %edi
c0106f0d:	56                   	push   %esi
c0106f0e:	83 ec 20             	sub    $0x20,%esp
c0106f11:	8b 45 08             	mov    0x8(%ebp),%eax
c0106f14:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0106f17:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106f1a:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCMP
#define __HAVE_ARCH_STRCMP
static inline int
__strcmp(const char *s1, const char *s2) {
    int d0, d1, ret;
    asm volatile (
c0106f1d:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0106f20:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106f23:	89 d1                	mov    %edx,%ecx
c0106f25:	89 c2                	mov    %eax,%edx
c0106f27:	89 ce                	mov    %ecx,%esi
c0106f29:	89 d7                	mov    %edx,%edi
c0106f2b:	ac                   	lods   %ds:(%esi),%al
c0106f2c:	ae                   	scas   %es:(%edi),%al
c0106f2d:	75 08                	jne    c0106f37 <strcmp+0x2e>
c0106f2f:	84 c0                	test   %al,%al
c0106f31:	75 f8                	jne    c0106f2b <strcmp+0x22>
c0106f33:	31 c0                	xor    %eax,%eax
c0106f35:	eb 04                	jmp    c0106f3b <strcmp+0x32>
c0106f37:	19 c0                	sbb    %eax,%eax
c0106f39:	0c 01                	or     $0x1,%al
c0106f3b:	89 fa                	mov    %edi,%edx
c0106f3d:	89 f1                	mov    %esi,%ecx
c0106f3f:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0106f42:	89 4d e8             	mov    %ecx,-0x18(%ebp)
c0106f45:	89 55 e4             	mov    %edx,-0x1c(%ebp)
        "orb $1, %%al;"
        "3:"
        : "=a" (ret), "=&S" (d0), "=&D" (d1)
        : "1" (s1), "2" (s2)
        : "memory");
    return ret;
c0106f48:	8b 45 ec             	mov    -0x14(%ebp),%eax
    while (*s1 != '\0' && *s1 == *s2) {
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
#endif /* __HAVE_ARCH_STRCMP */
}
c0106f4b:	83 c4 20             	add    $0x20,%esp
c0106f4e:	5e                   	pop    %esi
c0106f4f:	5f                   	pop    %edi
c0106f50:	5d                   	pop    %ebp
c0106f51:	c3                   	ret    

c0106f52 <strncmp>:
 * they are equal to each other, it continues with the following pairs until
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
c0106f52:	55                   	push   %ebp
c0106f53:	89 e5                	mov    %esp,%ebp
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
c0106f55:	eb 0c                	jmp    c0106f63 <strncmp+0x11>
        n --, s1 ++, s2 ++;
c0106f57:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
c0106f5b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c0106f5f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
c0106f63:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0106f67:	74 1a                	je     c0106f83 <strncmp+0x31>
c0106f69:	8b 45 08             	mov    0x8(%ebp),%eax
c0106f6c:	0f b6 00             	movzbl (%eax),%eax
c0106f6f:	84 c0                	test   %al,%al
c0106f71:	74 10                	je     c0106f83 <strncmp+0x31>
c0106f73:	8b 45 08             	mov    0x8(%ebp),%eax
c0106f76:	0f b6 10             	movzbl (%eax),%edx
c0106f79:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106f7c:	0f b6 00             	movzbl (%eax),%eax
c0106f7f:	38 c2                	cmp    %al,%dl
c0106f81:	74 d4                	je     c0106f57 <strncmp+0x5>
        n --, s1 ++, s2 ++;
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
c0106f83:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0106f87:	74 18                	je     c0106fa1 <strncmp+0x4f>
c0106f89:	8b 45 08             	mov    0x8(%ebp),%eax
c0106f8c:	0f b6 00             	movzbl (%eax),%eax
c0106f8f:	0f b6 d0             	movzbl %al,%edx
c0106f92:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106f95:	0f b6 00             	movzbl (%eax),%eax
c0106f98:	0f b6 c0             	movzbl %al,%eax
c0106f9b:	29 c2                	sub    %eax,%edx
c0106f9d:	89 d0                	mov    %edx,%eax
c0106f9f:	eb 05                	jmp    c0106fa6 <strncmp+0x54>
c0106fa1:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0106fa6:	5d                   	pop    %ebp
c0106fa7:	c3                   	ret    

c0106fa8 <strchr>:
 *
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
c0106fa8:	55                   	push   %ebp
c0106fa9:	89 e5                	mov    %esp,%ebp
c0106fab:	83 ec 04             	sub    $0x4,%esp
c0106fae:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106fb1:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
c0106fb4:	eb 14                	jmp    c0106fca <strchr+0x22>
        if (*s == c) {
c0106fb6:	8b 45 08             	mov    0x8(%ebp),%eax
c0106fb9:	0f b6 00             	movzbl (%eax),%eax
c0106fbc:	3a 45 fc             	cmp    -0x4(%ebp),%al
c0106fbf:	75 05                	jne    c0106fc6 <strchr+0x1e>
            return (char *)s;
c0106fc1:	8b 45 08             	mov    0x8(%ebp),%eax
c0106fc4:	eb 13                	jmp    c0106fd9 <strchr+0x31>
        }
        s ++;
c0106fc6:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
c0106fca:	8b 45 08             	mov    0x8(%ebp),%eax
c0106fcd:	0f b6 00             	movzbl (%eax),%eax
c0106fd0:	84 c0                	test   %al,%al
c0106fd2:	75 e2                	jne    c0106fb6 <strchr+0xe>
        if (*s == c) {
            return (char *)s;
        }
        s ++;
    }
    return NULL;
c0106fd4:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0106fd9:	c9                   	leave  
c0106fda:	c3                   	ret    

c0106fdb <strfind>:
 * The strfind() function is like strchr() except that if @c is
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
c0106fdb:	55                   	push   %ebp
c0106fdc:	89 e5                	mov    %esp,%ebp
c0106fde:	83 ec 04             	sub    $0x4,%esp
c0106fe1:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106fe4:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
c0106fe7:	eb 11                	jmp    c0106ffa <strfind+0x1f>
        if (*s == c) {
c0106fe9:	8b 45 08             	mov    0x8(%ebp),%eax
c0106fec:	0f b6 00             	movzbl (%eax),%eax
c0106fef:	3a 45 fc             	cmp    -0x4(%ebp),%al
c0106ff2:	75 02                	jne    c0106ff6 <strfind+0x1b>
            break;
c0106ff4:	eb 0e                	jmp    c0107004 <strfind+0x29>
        }
        s ++;
c0106ff6:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
    while (*s != '\0') {
c0106ffa:	8b 45 08             	mov    0x8(%ebp),%eax
c0106ffd:	0f b6 00             	movzbl (%eax),%eax
c0107000:	84 c0                	test   %al,%al
c0107002:	75 e5                	jne    c0106fe9 <strfind+0xe>
        if (*s == c) {
            break;
        }
        s ++;
    }
    return (char *)s;
c0107004:	8b 45 08             	mov    0x8(%ebp),%eax
}
c0107007:	c9                   	leave  
c0107008:	c3                   	ret    

c0107009 <strtol>:
 * an optional "0x" or "0X" prefix.
 *
 * The strtol() function returns the converted integral number as a long int value.
 * */
long
strtol(const char *s, char **endptr, int base) {
c0107009:	55                   	push   %ebp
c010700a:	89 e5                	mov    %esp,%ebp
c010700c:	83 ec 10             	sub    $0x10,%esp
    int neg = 0;
c010700f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    long val = 0;
c0107016:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
c010701d:	eb 04                	jmp    c0107023 <strtol+0x1a>
        s ++;
c010701f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
strtol(const char *s, char **endptr, int base) {
    int neg = 0;
    long val = 0;

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
c0107023:	8b 45 08             	mov    0x8(%ebp),%eax
c0107026:	0f b6 00             	movzbl (%eax),%eax
c0107029:	3c 20                	cmp    $0x20,%al
c010702b:	74 f2                	je     c010701f <strtol+0x16>
c010702d:	8b 45 08             	mov    0x8(%ebp),%eax
c0107030:	0f b6 00             	movzbl (%eax),%eax
c0107033:	3c 09                	cmp    $0x9,%al
c0107035:	74 e8                	je     c010701f <strtol+0x16>
        s ++;
    }

    // plus/minus sign
    if (*s == '+') {
c0107037:	8b 45 08             	mov    0x8(%ebp),%eax
c010703a:	0f b6 00             	movzbl (%eax),%eax
c010703d:	3c 2b                	cmp    $0x2b,%al
c010703f:	75 06                	jne    c0107047 <strtol+0x3e>
        s ++;
c0107041:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c0107045:	eb 15                	jmp    c010705c <strtol+0x53>
    }
    else if (*s == '-') {
c0107047:	8b 45 08             	mov    0x8(%ebp),%eax
c010704a:	0f b6 00             	movzbl (%eax),%eax
c010704d:	3c 2d                	cmp    $0x2d,%al
c010704f:	75 0b                	jne    c010705c <strtol+0x53>
        s ++, neg = 1;
c0107051:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c0107055:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)
    }

    // hex or octal base prefix
    if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x')) {
c010705c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0107060:	74 06                	je     c0107068 <strtol+0x5f>
c0107062:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
c0107066:	75 24                	jne    c010708c <strtol+0x83>
c0107068:	8b 45 08             	mov    0x8(%ebp),%eax
c010706b:	0f b6 00             	movzbl (%eax),%eax
c010706e:	3c 30                	cmp    $0x30,%al
c0107070:	75 1a                	jne    c010708c <strtol+0x83>
c0107072:	8b 45 08             	mov    0x8(%ebp),%eax
c0107075:	83 c0 01             	add    $0x1,%eax
c0107078:	0f b6 00             	movzbl (%eax),%eax
c010707b:	3c 78                	cmp    $0x78,%al
c010707d:	75 0d                	jne    c010708c <strtol+0x83>
        s += 2, base = 16;
c010707f:	83 45 08 02          	addl   $0x2,0x8(%ebp)
c0107083:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
c010708a:	eb 2a                	jmp    c01070b6 <strtol+0xad>
    }
    else if (base == 0 && s[0] == '0') {
c010708c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0107090:	75 17                	jne    c01070a9 <strtol+0xa0>
c0107092:	8b 45 08             	mov    0x8(%ebp),%eax
c0107095:	0f b6 00             	movzbl (%eax),%eax
c0107098:	3c 30                	cmp    $0x30,%al
c010709a:	75 0d                	jne    c01070a9 <strtol+0xa0>
        s ++, base = 8;
c010709c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c01070a0:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
c01070a7:	eb 0d                	jmp    c01070b6 <strtol+0xad>
    }
    else if (base == 0) {
c01070a9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01070ad:	75 07                	jne    c01070b6 <strtol+0xad>
        base = 10;
c01070af:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

    // digits
    while (1) {
        int dig;

        if (*s >= '0' && *s <= '9') {
c01070b6:	8b 45 08             	mov    0x8(%ebp),%eax
c01070b9:	0f b6 00             	movzbl (%eax),%eax
c01070bc:	3c 2f                	cmp    $0x2f,%al
c01070be:	7e 1b                	jle    c01070db <strtol+0xd2>
c01070c0:	8b 45 08             	mov    0x8(%ebp),%eax
c01070c3:	0f b6 00             	movzbl (%eax),%eax
c01070c6:	3c 39                	cmp    $0x39,%al
c01070c8:	7f 11                	jg     c01070db <strtol+0xd2>
            dig = *s - '0';
c01070ca:	8b 45 08             	mov    0x8(%ebp),%eax
c01070cd:	0f b6 00             	movzbl (%eax),%eax
c01070d0:	0f be c0             	movsbl %al,%eax
c01070d3:	83 e8 30             	sub    $0x30,%eax
c01070d6:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01070d9:	eb 48                	jmp    c0107123 <strtol+0x11a>
        }
        else if (*s >= 'a' && *s <= 'z') {
c01070db:	8b 45 08             	mov    0x8(%ebp),%eax
c01070de:	0f b6 00             	movzbl (%eax),%eax
c01070e1:	3c 60                	cmp    $0x60,%al
c01070e3:	7e 1b                	jle    c0107100 <strtol+0xf7>
c01070e5:	8b 45 08             	mov    0x8(%ebp),%eax
c01070e8:	0f b6 00             	movzbl (%eax),%eax
c01070eb:	3c 7a                	cmp    $0x7a,%al
c01070ed:	7f 11                	jg     c0107100 <strtol+0xf7>
            dig = *s - 'a' + 10;
c01070ef:	8b 45 08             	mov    0x8(%ebp),%eax
c01070f2:	0f b6 00             	movzbl (%eax),%eax
c01070f5:	0f be c0             	movsbl %al,%eax
c01070f8:	83 e8 57             	sub    $0x57,%eax
c01070fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01070fe:	eb 23                	jmp    c0107123 <strtol+0x11a>
        }
        else if (*s >= 'A' && *s <= 'Z') {
c0107100:	8b 45 08             	mov    0x8(%ebp),%eax
c0107103:	0f b6 00             	movzbl (%eax),%eax
c0107106:	3c 40                	cmp    $0x40,%al
c0107108:	7e 3d                	jle    c0107147 <strtol+0x13e>
c010710a:	8b 45 08             	mov    0x8(%ebp),%eax
c010710d:	0f b6 00             	movzbl (%eax),%eax
c0107110:	3c 5a                	cmp    $0x5a,%al
c0107112:	7f 33                	jg     c0107147 <strtol+0x13e>
            dig = *s - 'A' + 10;
c0107114:	8b 45 08             	mov    0x8(%ebp),%eax
c0107117:	0f b6 00             	movzbl (%eax),%eax
c010711a:	0f be c0             	movsbl %al,%eax
c010711d:	83 e8 37             	sub    $0x37,%eax
c0107120:	89 45 f4             	mov    %eax,-0xc(%ebp)
        }
        else {
            break;
        }
        if (dig >= base) {
c0107123:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0107126:	3b 45 10             	cmp    0x10(%ebp),%eax
c0107129:	7c 02                	jl     c010712d <strtol+0x124>
            break;
c010712b:	eb 1a                	jmp    c0107147 <strtol+0x13e>
        }
        s ++, val = (val * base) + dig;
c010712d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c0107131:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0107134:	0f af 45 10          	imul   0x10(%ebp),%eax
c0107138:	89 c2                	mov    %eax,%edx
c010713a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010713d:	01 d0                	add    %edx,%eax
c010713f:	89 45 f8             	mov    %eax,-0x8(%ebp)
        // we don't properly detect overflow!
    }
c0107142:	e9 6f ff ff ff       	jmp    c01070b6 <strtol+0xad>

    if (endptr) {
c0107147:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c010714b:	74 08                	je     c0107155 <strtol+0x14c>
        *endptr = (char *) s;
c010714d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0107150:	8b 55 08             	mov    0x8(%ebp),%edx
c0107153:	89 10                	mov    %edx,(%eax)
    }
    return (neg ? -val : val);
c0107155:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
c0107159:	74 07                	je     c0107162 <strtol+0x159>
c010715b:	8b 45 f8             	mov    -0x8(%ebp),%eax
c010715e:	f7 d8                	neg    %eax
c0107160:	eb 03                	jmp    c0107165 <strtol+0x15c>
c0107162:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
c0107165:	c9                   	leave  
c0107166:	c3                   	ret    

c0107167 <memset>:
 * @n:      number of bytes to be set to the value
 *
 * The memset() function returns @s.
 * */
void *
memset(void *s, char c, size_t n) {
c0107167:	55                   	push   %ebp
c0107168:	89 e5                	mov    %esp,%ebp
c010716a:	57                   	push   %edi
c010716b:	83 ec 24             	sub    $0x24,%esp
c010716e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0107171:	88 45 d8             	mov    %al,-0x28(%ebp)
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
c0107174:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
c0107178:	8b 55 08             	mov    0x8(%ebp),%edx
c010717b:	89 55 f8             	mov    %edx,-0x8(%ebp)
c010717e:	88 45 f7             	mov    %al,-0x9(%ebp)
c0107181:	8b 45 10             	mov    0x10(%ebp),%eax
c0107184:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_MEMSET
#define __HAVE_ARCH_MEMSET
static inline void *
__memset(void *s, char c, size_t n) {
    int d0, d1;
    asm volatile (
c0107187:	8b 4d f0             	mov    -0x10(%ebp),%ecx
c010718a:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
c010718e:	8b 55 f8             	mov    -0x8(%ebp),%edx
c0107191:	89 d7                	mov    %edx,%edi
c0107193:	f3 aa                	rep stos %al,%es:(%edi)
c0107195:	89 fa                	mov    %edi,%edx
c0107197:	89 4d ec             	mov    %ecx,-0x14(%ebp)
c010719a:	89 55 e8             	mov    %edx,-0x18(%ebp)
        "rep; stosb;"
        : "=&c" (d0), "=&D" (d1)
        : "0" (n), "a" (c), "1" (s)
        : "memory");
    return s;
c010719d:	8b 45 f8             	mov    -0x8(%ebp),%eax
    while (n -- > 0) {
        *p ++ = c;
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
c01071a0:	83 c4 24             	add    $0x24,%esp
c01071a3:	5f                   	pop    %edi
c01071a4:	5d                   	pop    %ebp
c01071a5:	c3                   	ret    

c01071a6 <memmove>:
 * @n:      number of bytes to copy
 *
 * The memmove() function returns @dst.
 * */
void *
memmove(void *dst, const void *src, size_t n) {
c01071a6:	55                   	push   %ebp
c01071a7:	89 e5                	mov    %esp,%ebp
c01071a9:	57                   	push   %edi
c01071aa:	56                   	push   %esi
c01071ab:	53                   	push   %ebx
c01071ac:	83 ec 30             	sub    $0x30,%esp
c01071af:	8b 45 08             	mov    0x8(%ebp),%eax
c01071b2:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01071b5:	8b 45 0c             	mov    0xc(%ebp),%eax
c01071b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01071bb:	8b 45 10             	mov    0x10(%ebp),%eax
c01071be:	89 45 e8             	mov    %eax,-0x18(%ebp)

#ifndef __HAVE_ARCH_MEMMOVE
#define __HAVE_ARCH_MEMMOVE
static inline void *
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
c01071c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01071c4:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c01071c7:	73 42                	jae    c010720b <memmove+0x65>
c01071c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01071cc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01071cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01071d2:	89 45 e0             	mov    %eax,-0x20(%ebp)
c01071d5:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01071d8:	89 45 dc             	mov    %eax,-0x24(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c01071db:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01071de:	c1 e8 02             	shr    $0x2,%eax
c01071e1:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
c01071e3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01071e6:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01071e9:	89 d7                	mov    %edx,%edi
c01071eb:	89 c6                	mov    %eax,%esi
c01071ed:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c01071ef:	8b 4d dc             	mov    -0x24(%ebp),%ecx
c01071f2:	83 e1 03             	and    $0x3,%ecx
c01071f5:	74 02                	je     c01071f9 <memmove+0x53>
c01071f7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c01071f9:	89 f0                	mov    %esi,%eax
c01071fb:	89 fa                	mov    %edi,%edx
c01071fd:	89 4d d8             	mov    %ecx,-0x28(%ebp)
c0107200:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0107203:	89 45 d0             	mov    %eax,-0x30(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
c0107206:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0107209:	eb 36                	jmp    c0107241 <memmove+0x9b>
    asm volatile (
        "std;"
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
c010720b:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010720e:	8d 50 ff             	lea    -0x1(%eax),%edx
c0107211:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0107214:	01 c2                	add    %eax,%edx
c0107216:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0107219:	8d 48 ff             	lea    -0x1(%eax),%ecx
c010721c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010721f:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
        return __memcpy(dst, src, n);
    }
    int d0, d1, d2;
    asm volatile (
c0107222:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0107225:	89 c1                	mov    %eax,%ecx
c0107227:	89 d8                	mov    %ebx,%eax
c0107229:	89 d6                	mov    %edx,%esi
c010722b:	89 c7                	mov    %eax,%edi
c010722d:	fd                   	std    
c010722e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c0107230:	fc                   	cld    
c0107231:	89 f8                	mov    %edi,%eax
c0107233:	89 f2                	mov    %esi,%edx
c0107235:	89 4d cc             	mov    %ecx,-0x34(%ebp)
c0107238:	89 55 c8             	mov    %edx,-0x38(%ebp)
c010723b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
        : "memory");
    return dst;
c010723e:	8b 45 f0             	mov    -0x10(%ebp),%eax
            *d ++ = *s ++;
        }
    }
    return dst;
#endif /* __HAVE_ARCH_MEMMOVE */
}
c0107241:	83 c4 30             	add    $0x30,%esp
c0107244:	5b                   	pop    %ebx
c0107245:	5e                   	pop    %esi
c0107246:	5f                   	pop    %edi
c0107247:	5d                   	pop    %ebp
c0107248:	c3                   	ret    

c0107249 <memcpy>:
 * it always copies exactly @n bytes. To avoid overflows, the size of arrays pointed
 * by both @src and @dst, should be at least @n bytes, and should not overlap
 * (for overlapping memory area, memmove is a safer approach).
 * */
void *
memcpy(void *dst, const void *src, size_t n) {
c0107249:	55                   	push   %ebp
c010724a:	89 e5                	mov    %esp,%ebp
c010724c:	57                   	push   %edi
c010724d:	56                   	push   %esi
c010724e:	83 ec 20             	sub    $0x20,%esp
c0107251:	8b 45 08             	mov    0x8(%ebp),%eax
c0107254:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0107257:	8b 45 0c             	mov    0xc(%ebp),%eax
c010725a:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010725d:	8b 45 10             	mov    0x10(%ebp),%eax
c0107260:	89 45 ec             	mov    %eax,-0x14(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c0107263:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0107266:	c1 e8 02             	shr    $0x2,%eax
c0107269:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
c010726b:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010726e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0107271:	89 d7                	mov    %edx,%edi
c0107273:	89 c6                	mov    %eax,%esi
c0107275:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c0107277:	8b 4d ec             	mov    -0x14(%ebp),%ecx
c010727a:	83 e1 03             	and    $0x3,%ecx
c010727d:	74 02                	je     c0107281 <memcpy+0x38>
c010727f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c0107281:	89 f0                	mov    %esi,%eax
c0107283:	89 fa                	mov    %edi,%edx
c0107285:	89 4d e8             	mov    %ecx,-0x18(%ebp)
c0107288:	89 55 e4             	mov    %edx,-0x1c(%ebp)
c010728b:	89 45 e0             	mov    %eax,-0x20(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
c010728e:	8b 45 f4             	mov    -0xc(%ebp),%eax
    while (n -- > 0) {
        *d ++ = *s ++;
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
c0107291:	83 c4 20             	add    $0x20,%esp
c0107294:	5e                   	pop    %esi
c0107295:	5f                   	pop    %edi
c0107296:	5d                   	pop    %ebp
c0107297:	c3                   	ret    

c0107298 <memcmp>:
 *   match in both memory blocks has a greater value in @v1 than in @v2
 *   as if evaluated as unsigned char values;
 * - And a value less than zero indicates the opposite.
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
c0107298:	55                   	push   %ebp
c0107299:	89 e5                	mov    %esp,%ebp
c010729b:	83 ec 10             	sub    $0x10,%esp
    const char *s1 = (const char *)v1;
c010729e:	8b 45 08             	mov    0x8(%ebp),%eax
c01072a1:	89 45 fc             	mov    %eax,-0x4(%ebp)
    const char *s2 = (const char *)v2;
c01072a4:	8b 45 0c             	mov    0xc(%ebp),%eax
c01072a7:	89 45 f8             	mov    %eax,-0x8(%ebp)
    while (n -- > 0) {
c01072aa:	eb 30                	jmp    c01072dc <memcmp+0x44>
        if (*s1 != *s2) {
c01072ac:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01072af:	0f b6 10             	movzbl (%eax),%edx
c01072b2:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01072b5:	0f b6 00             	movzbl (%eax),%eax
c01072b8:	38 c2                	cmp    %al,%dl
c01072ba:	74 18                	je     c01072d4 <memcmp+0x3c>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
c01072bc:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01072bf:	0f b6 00             	movzbl (%eax),%eax
c01072c2:	0f b6 d0             	movzbl %al,%edx
c01072c5:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01072c8:	0f b6 00             	movzbl (%eax),%eax
c01072cb:	0f b6 c0             	movzbl %al,%eax
c01072ce:	29 c2                	sub    %eax,%edx
c01072d0:	89 d0                	mov    %edx,%eax
c01072d2:	eb 1a                	jmp    c01072ee <memcmp+0x56>
        }
        s1 ++, s2 ++;
c01072d4:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c01072d8:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
c01072dc:	8b 45 10             	mov    0x10(%ebp),%eax
c01072df:	8d 50 ff             	lea    -0x1(%eax),%edx
c01072e2:	89 55 10             	mov    %edx,0x10(%ebp)
c01072e5:	85 c0                	test   %eax,%eax
c01072e7:	75 c3                	jne    c01072ac <memcmp+0x14>
        if (*s1 != *s2) {
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
    }
    return 0;
c01072e9:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01072ee:	c9                   	leave  
c01072ef:	c3                   	ret    
