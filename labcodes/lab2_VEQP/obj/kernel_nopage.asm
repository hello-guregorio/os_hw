
bin/kernel_nopage:     file format elf32-i386


Disassembly of section .text:

00100000 <kern_entry>:

.text
.globl kern_entry
kern_entry:
    # load pa of boot pgdir
    movl $REALLOC(__boot_pgdir), %eax
  100000:	b8 00 80 11 00       	mov    $0x118000,%eax
    movl %eax, %cr3     # CR3含有存放页目录表页面的物理地址，因此CR3也被称为PDBR。因为页目录表页面是页对齐的，所以该寄存器只有高20位是有效的。而低12位保留供更高级处理器使用，因此在往CR3中加载一个新值时低12位必须设置为0。
  100005:	0f 22 d8             	mov    %eax,%cr3
                        # 注意，放的是物理内存地址，主要估计是用于进程切换的时候换页映射。
                        # https://blog.csdn.net/SweeNeil/article/details/106171361
    # enable paging
    # 和开保护模式类似
    # 在mmu.h里面
    movl %cr0, %eax
  100008:	0f 20 c0             	mov    %cr0,%eax
    orl $(CR0_PE | CR0_PG | CR0_AM | CR0_WP | CR0_NE | CR0_TS | CR0_EM | CR0_MP), %eax
  10000b:	0d 2f 00 05 80       	or     $0x8005002f,%eax
    andl $~(CR0_TS | CR0_EM), %eax
  100010:	83 e0 f3             	and    $0xfffffff3,%eax
    movl %eax, %cr0
  100013:	0f 22 c0             	mov    %eax,%cr0

    # update eip
    # now, eip = 0x1.....
    leal next, %eax
  100016:	8d 05 1e 00 10 00    	lea    0x10001e,%eax
    # set eip = KERNBASE + 0x1.....
    jmp *%eax
  10001c:	ff e0                	jmp    *%eax

0010001e <next>:
    # unmap va 0 ~ 4M, it's temporary mapping
    # xorl %eax, %eax
    # movl %eax, __boot_pgdir

    # set ebp, esp
    movl $0x0, %ebp
  10001e:	bd 00 00 00 00       	mov    $0x0,%ebp
    # the kernel stack region is from bootstack -- bootstacktop,
    # the kernel stack size is KSTACKSIZE (8KB)defined in memlayout.h
    movl $bootstacktop, %esp
  100023:	bc 00 70 11 00       	mov    $0x117000,%esp
    # now kernel stack is ready , call the first C function
    call kern_init
  100028:	e8 02 00 00 00       	call   10002f <kern_init>

0010002d <spin>:

# should never get here
spin:
    jmp spin
  10002d:	eb fe                	jmp    10002d <spin>

0010002f <kern_init>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);
static void lab1_switch_test(void);

int
kern_init(void) {
  10002f:	55                   	push   %ebp
  100030:	89 e5                	mov    %esp,%ebp
  100032:	83 ec 28             	sub    $0x28,%esp
    extern char edata[], end[]; //这俩东西在kernel.ld里
    memset(edata, 0, end - edata);
  100035:	ba 28 af 11 00       	mov    $0x11af28,%edx
  10003a:	b8 36 7a 11 00       	mov    $0x117a36,%eax
  10003f:	29 c2                	sub    %eax,%edx
  100041:	89 d0                	mov    %edx,%eax
  100043:	89 44 24 08          	mov    %eax,0x8(%esp)
  100047:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10004e:	00 
  10004f:	c7 04 24 36 7a 11 00 	movl   $0x117a36,(%esp)
  100056:	e8 8c 60 00 00       	call   1060e7 <memset>

    cons_init();                // init the console
  10005b:	e8 8e 15 00 00       	call   1015ee <cons_init>

    const char *message = "(THU.CST) os is loading ...";
  100060:	c7 45 f4 80 62 10 00 	movl   $0x106280,-0xc(%ebp)
    cprintf("%s\n\n", message);
  100067:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10006a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10006e:	c7 04 24 9c 62 10 00 	movl   $0x10629c,(%esp)
  100075:	e8 d3 02 00 00       	call   10034d <cprintf>

    print_kerninfo();
  10007a:	e8 02 08 00 00       	call   100881 <print_kerninfo>

    grade_backtrace();
  10007f:	e8 8b 00 00 00       	call   10010f <grade_backtrace>

    pmm_init();                 // init physical memory management
  100084:	e8 65 46 00 00       	call   1046ee <pmm_init>

    pic_init();                 // init interrupt controller
  100089:	e8 c9 16 00 00       	call   101757 <pic_init>
    idt_init();                 // init interrupt descriptor table
  10008e:	e8 1b 18 00 00       	call   1018ae <idt_init>

    clock_init();               // init clock interrupt
  100093:	e8 0c 0d 00 00       	call   100da4 <clock_init>
    intr_enable();              // enable irq interrupt
  100098:	e8 28 16 00 00       	call   1016c5 <intr_enable>

    //LAB1: CAHLLENGE 1 If you try to do it, uncomment lab1_switch_test()
    // user/kernel mode switch test
    lab1_switch_test();
  10009d:	e8 69 01 00 00       	call   10020b <lab1_switch_test>

    /* do nothing */
    while (1);
  1000a2:	eb fe                	jmp    1000a2 <kern_init+0x73>

001000a4 <grade_backtrace2>:
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
  1000a4:	55                   	push   %ebp
  1000a5:	89 e5                	mov    %esp,%ebp
  1000a7:	83 ec 18             	sub    $0x18,%esp
    mon_backtrace(0, NULL, NULL);
  1000aa:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1000b1:	00 
  1000b2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000b9:	00 
  1000ba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1000c1:	e8 ff 0b 00 00       	call   100cc5 <mon_backtrace>
}
  1000c6:	c9                   	leave  
  1000c7:	c3                   	ret    

001000c8 <grade_backtrace1>:

void __attribute__((noinline))
grade_backtrace1(int arg0, int arg1) {
  1000c8:	55                   	push   %ebp
  1000c9:	89 e5                	mov    %esp,%ebp
  1000cb:	53                   	push   %ebx
  1000cc:	83 ec 14             	sub    $0x14,%esp
    grade_backtrace2(arg0, (int)&arg0, arg1, (int)&arg1);
  1000cf:	8d 5d 0c             	lea    0xc(%ebp),%ebx
  1000d2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  1000d5:	8d 55 08             	lea    0x8(%ebp),%edx
  1000d8:	8b 45 08             	mov    0x8(%ebp),%eax
  1000db:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  1000df:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1000e3:	89 54 24 04          	mov    %edx,0x4(%esp)
  1000e7:	89 04 24             	mov    %eax,(%esp)
  1000ea:	e8 b5 ff ff ff       	call   1000a4 <grade_backtrace2>
}
  1000ef:	83 c4 14             	add    $0x14,%esp
  1000f2:	5b                   	pop    %ebx
  1000f3:	5d                   	pop    %ebp
  1000f4:	c3                   	ret    

001000f5 <grade_backtrace0>:

void __attribute__((noinline))
grade_backtrace0(int arg0, int arg1, int arg2) {
  1000f5:	55                   	push   %ebp
  1000f6:	89 e5                	mov    %esp,%ebp
  1000f8:	83 ec 18             	sub    $0x18,%esp
    grade_backtrace1(arg0, arg2);
  1000fb:	8b 45 10             	mov    0x10(%ebp),%eax
  1000fe:	89 44 24 04          	mov    %eax,0x4(%esp)
  100102:	8b 45 08             	mov    0x8(%ebp),%eax
  100105:	89 04 24             	mov    %eax,(%esp)
  100108:	e8 bb ff ff ff       	call   1000c8 <grade_backtrace1>
}
  10010d:	c9                   	leave  
  10010e:	c3                   	ret    

0010010f <grade_backtrace>:

void
grade_backtrace(void) {
  10010f:	55                   	push   %ebp
  100110:	89 e5                	mov    %esp,%ebp
  100112:	83 ec 18             	sub    $0x18,%esp
    grade_backtrace0(0, (int)kern_init, 0xffff0000);
  100115:	b8 2f 00 10 00       	mov    $0x10002f,%eax
  10011a:	c7 44 24 08 00 00 ff 	movl   $0xffff0000,0x8(%esp)
  100121:	ff 
  100122:	89 44 24 04          	mov    %eax,0x4(%esp)
  100126:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10012d:	e8 c3 ff ff ff       	call   1000f5 <grade_backtrace0>
}
  100132:	c9                   	leave  
  100133:	c3                   	ret    

00100134 <lab1_print_cur_status>:

static void
lab1_print_cur_status(void) {
  100134:	55                   	push   %ebp
  100135:	89 e5                	mov    %esp,%ebp
  100137:	83 ec 28             	sub    $0x28,%esp
    static int round = 0;
    uint16_t reg1, reg2, reg3, reg4;
    asm volatile (
  10013a:	8c 4d f6             	mov    %cs,-0xa(%ebp)
  10013d:	8c 5d f4             	mov    %ds,-0xc(%ebp)
  100140:	8c 45 f2             	mov    %es,-0xe(%ebp)
  100143:	8c 55 f0             	mov    %ss,-0x10(%ebp)
            "mov %%cs, %0;"
            "mov %%ds, %1;"
            "mov %%es, %2;"
            "mov %%ss, %3;"
            : "=m"(reg1), "=m"(reg2), "=m"(reg3), "=m"(reg4));
    cprintf("%d: @ring %d\n", round, reg1 & 3);
  100146:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  10014a:	0f b7 c0             	movzwl %ax,%eax
  10014d:	83 e0 03             	and    $0x3,%eax
  100150:	89 c2                	mov    %eax,%edx
  100152:	a1 00 a0 11 00       	mov    0x11a000,%eax
  100157:	89 54 24 08          	mov    %edx,0x8(%esp)
  10015b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10015f:	c7 04 24 a1 62 10 00 	movl   $0x1062a1,(%esp)
  100166:	e8 e2 01 00 00       	call   10034d <cprintf>
    cprintf("%d:  cs = %x\n", round, reg1);
  10016b:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  10016f:	0f b7 d0             	movzwl %ax,%edx
  100172:	a1 00 a0 11 00       	mov    0x11a000,%eax
  100177:	89 54 24 08          	mov    %edx,0x8(%esp)
  10017b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10017f:	c7 04 24 af 62 10 00 	movl   $0x1062af,(%esp)
  100186:	e8 c2 01 00 00       	call   10034d <cprintf>
    cprintf("%d:  ds = %x\n", round, reg2);
  10018b:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
  10018f:	0f b7 d0             	movzwl %ax,%edx
  100192:	a1 00 a0 11 00       	mov    0x11a000,%eax
  100197:	89 54 24 08          	mov    %edx,0x8(%esp)
  10019b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10019f:	c7 04 24 bd 62 10 00 	movl   $0x1062bd,(%esp)
  1001a6:	e8 a2 01 00 00       	call   10034d <cprintf>
    cprintf("%d:  es = %x\n", round, reg3);
  1001ab:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
  1001af:	0f b7 d0             	movzwl %ax,%edx
  1001b2:	a1 00 a0 11 00       	mov    0x11a000,%eax
  1001b7:	89 54 24 08          	mov    %edx,0x8(%esp)
  1001bb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1001bf:	c7 04 24 cb 62 10 00 	movl   $0x1062cb,(%esp)
  1001c6:	e8 82 01 00 00       	call   10034d <cprintf>
    cprintf("%d:  ss = %x\n", round, reg4);
  1001cb:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
  1001cf:	0f b7 d0             	movzwl %ax,%edx
  1001d2:	a1 00 a0 11 00       	mov    0x11a000,%eax
  1001d7:	89 54 24 08          	mov    %edx,0x8(%esp)
  1001db:	89 44 24 04          	mov    %eax,0x4(%esp)
  1001df:	c7 04 24 d9 62 10 00 	movl   $0x1062d9,(%esp)
  1001e6:	e8 62 01 00 00       	call   10034d <cprintf>
    round ++;
  1001eb:	a1 00 a0 11 00       	mov    0x11a000,%eax
  1001f0:	83 c0 01             	add    $0x1,%eax
  1001f3:	a3 00 a0 11 00       	mov    %eax,0x11a000
}
  1001f8:	c9                   	leave  
  1001f9:	c3                   	ret    

001001fa <lab1_switch_to_user>:

static void
lab1_switch_to_user(void) {
  1001fa:	55                   	push   %ebp
  1001fb:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 : TODO
    asm volatile (
  1001fd:	16                   	push   %ss
  1001fe:	54                   	push   %esp
  1001ff:	cd 78                	int    $0x78
            "pushl %%ss\n\t"
            "pushl %%esp\n\t"
            "int %0\n\t"
            ::"i" (T_SWITCH_TOU));
}
  100201:	5d                   	pop    %ebp
  100202:	c3                   	ret    

00100203 <lab1_switch_to_kernel>:

static void
lab1_switch_to_kernel(void) {
  100203:	55                   	push   %ebp
  100204:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 :  TODO
    asm volatile (
  100206:	cd 79                	int    $0x79
  100208:	5c                   	pop    %esp
        "int %0\n\t"
        "popl %%esp\n\t"
        ::"i" (T_SWITCH_TOK));
}
  100209:	5d                   	pop    %ebp
  10020a:	c3                   	ret    

0010020b <lab1_switch_test>:

static void
lab1_switch_test(void) {
  10020b:	55                   	push   %ebp
  10020c:	89 e5                	mov    %esp,%ebp
  10020e:	83 ec 18             	sub    $0x18,%esp
    lab1_print_cur_status();
  100211:	e8 1e ff ff ff       	call   100134 <lab1_print_cur_status>
    cprintf("+++ switch to  user  mode +++\n");
  100216:	c7 04 24 e8 62 10 00 	movl   $0x1062e8,(%esp)
  10021d:	e8 2b 01 00 00       	call   10034d <cprintf>
    lab1_switch_to_user();
  100222:	e8 d3 ff ff ff       	call   1001fa <lab1_switch_to_user>
    lab1_print_cur_status();
  100227:	e8 08 ff ff ff       	call   100134 <lab1_print_cur_status>
    cprintf("+++ switch to kernel mode +++\n");
  10022c:	c7 04 24 08 63 10 00 	movl   $0x106308,(%esp)
  100233:	e8 15 01 00 00       	call   10034d <cprintf>
    lab1_switch_to_kernel();
  100238:	e8 c6 ff ff ff       	call   100203 <lab1_switch_to_kernel>
    lab1_print_cur_status();
  10023d:	e8 f2 fe ff ff       	call   100134 <lab1_print_cur_status>
}
  100242:	c9                   	leave  
  100243:	c3                   	ret    

00100244 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
  100244:	55                   	push   %ebp
  100245:	89 e5                	mov    %esp,%ebp
  100247:	83 ec 28             	sub    $0x28,%esp
    if (prompt != NULL) {
  10024a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  10024e:	74 13                	je     100263 <readline+0x1f>
        cprintf("%s", prompt);
  100250:	8b 45 08             	mov    0x8(%ebp),%eax
  100253:	89 44 24 04          	mov    %eax,0x4(%esp)
  100257:	c7 04 24 27 63 10 00 	movl   $0x106327,(%esp)
  10025e:	e8 ea 00 00 00       	call   10034d <cprintf>
    }
    int i = 0, c;
  100263:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        c = getchar();
  10026a:	e8 66 01 00 00       	call   1003d5 <getchar>
  10026f:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (c < 0) {
  100272:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  100276:	79 07                	jns    10027f <readline+0x3b>
            return NULL;
  100278:	b8 00 00 00 00       	mov    $0x0,%eax
  10027d:	eb 79                	jmp    1002f8 <readline+0xb4>
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
  10027f:	83 7d f0 1f          	cmpl   $0x1f,-0x10(%ebp)
  100283:	7e 28                	jle    1002ad <readline+0x69>
  100285:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
  10028c:	7f 1f                	jg     1002ad <readline+0x69>
            cputchar(c);
  10028e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100291:	89 04 24             	mov    %eax,(%esp)
  100294:	e8 da 00 00 00       	call   100373 <cputchar>
            buf[i ++] = c;
  100299:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10029c:	8d 50 01             	lea    0x1(%eax),%edx
  10029f:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1002a2:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1002a5:	88 90 20 a0 11 00    	mov    %dl,0x11a020(%eax)
  1002ab:	eb 46                	jmp    1002f3 <readline+0xaf>
        }
        else if (c == '\b' && i > 0) {
  1002ad:	83 7d f0 08          	cmpl   $0x8,-0x10(%ebp)
  1002b1:	75 17                	jne    1002ca <readline+0x86>
  1002b3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1002b7:	7e 11                	jle    1002ca <readline+0x86>
            cputchar(c);
  1002b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1002bc:	89 04 24             	mov    %eax,(%esp)
  1002bf:	e8 af 00 00 00       	call   100373 <cputchar>
            i --;
  1002c4:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
  1002c8:	eb 29                	jmp    1002f3 <readline+0xaf>
        }
        else if (c == '\n' || c == '\r') {
  1002ca:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
  1002ce:	74 06                	je     1002d6 <readline+0x92>
  1002d0:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
  1002d4:	75 1d                	jne    1002f3 <readline+0xaf>
            cputchar(c);
  1002d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1002d9:	89 04 24             	mov    %eax,(%esp)
  1002dc:	e8 92 00 00 00       	call   100373 <cputchar>
            buf[i] = '\0';
  1002e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1002e4:	05 20 a0 11 00       	add    $0x11a020,%eax
  1002e9:	c6 00 00             	movb   $0x0,(%eax)
            return buf;
  1002ec:	b8 20 a0 11 00       	mov    $0x11a020,%eax
  1002f1:	eb 05                	jmp    1002f8 <readline+0xb4>
        }
    }
  1002f3:	e9 72 ff ff ff       	jmp    10026a <readline+0x26>
}
  1002f8:	c9                   	leave  
  1002f9:	c3                   	ret    

001002fa <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  1002fa:	55                   	push   %ebp
  1002fb:	89 e5                	mov    %esp,%ebp
  1002fd:	83 ec 18             	sub    $0x18,%esp
    cons_putc(c);
  100300:	8b 45 08             	mov    0x8(%ebp),%eax
  100303:	89 04 24             	mov    %eax,(%esp)
  100306:	e8 0f 13 00 00       	call   10161a <cons_putc>
    (*cnt) ++;
  10030b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10030e:	8b 00                	mov    (%eax),%eax
  100310:	8d 50 01             	lea    0x1(%eax),%edx
  100313:	8b 45 0c             	mov    0xc(%ebp),%eax
  100316:	89 10                	mov    %edx,(%eax)
}
  100318:	c9                   	leave  
  100319:	c3                   	ret    

0010031a <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
  10031a:	55                   	push   %ebp
  10031b:	89 e5                	mov    %esp,%ebp
  10031d:	83 ec 28             	sub    $0x28,%esp
    int cnt = 0;
  100320:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  100327:	8b 45 0c             	mov    0xc(%ebp),%eax
  10032a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10032e:	8b 45 08             	mov    0x8(%ebp),%eax
  100331:	89 44 24 08          	mov    %eax,0x8(%esp)
  100335:	8d 45 f4             	lea    -0xc(%ebp),%eax
  100338:	89 44 24 04          	mov    %eax,0x4(%esp)
  10033c:	c7 04 24 fa 02 10 00 	movl   $0x1002fa,(%esp)
  100343:	e8 b8 55 00 00       	call   105900 <vprintfmt>
    return cnt;
  100348:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  10034b:	c9                   	leave  
  10034c:	c3                   	ret    

0010034d <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  10034d:	55                   	push   %ebp
  10034e:	89 e5                	mov    %esp,%ebp
  100350:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
  100353:	8d 45 0c             	lea    0xc(%ebp),%eax
  100356:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vcprintf(fmt, ap);
  100359:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10035c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100360:	8b 45 08             	mov    0x8(%ebp),%eax
  100363:	89 04 24             	mov    %eax,(%esp)
  100366:	e8 af ff ff ff       	call   10031a <vcprintf>
  10036b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
  10036e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100371:	c9                   	leave  
  100372:	c3                   	ret    

00100373 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
  100373:	55                   	push   %ebp
  100374:	89 e5                	mov    %esp,%ebp
  100376:	83 ec 18             	sub    $0x18,%esp
    cons_putc(c);
  100379:	8b 45 08             	mov    0x8(%ebp),%eax
  10037c:	89 04 24             	mov    %eax,(%esp)
  10037f:	e8 96 12 00 00       	call   10161a <cons_putc>
}
  100384:	c9                   	leave  
  100385:	c3                   	ret    

00100386 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
  100386:	55                   	push   %ebp
  100387:	89 e5                	mov    %esp,%ebp
  100389:	83 ec 28             	sub    $0x28,%esp
    int cnt = 0;
  10038c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    char c;
    while ((c = *str ++) != '\0') {
  100393:	eb 13                	jmp    1003a8 <cputs+0x22>
        cputch(c, &cnt);
  100395:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  100399:	8d 55 f0             	lea    -0x10(%ebp),%edx
  10039c:	89 54 24 04          	mov    %edx,0x4(%esp)
  1003a0:	89 04 24             	mov    %eax,(%esp)
  1003a3:	e8 52 ff ff ff       	call   1002fa <cputch>
 * */
int
cputs(const char *str) {
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
  1003a8:	8b 45 08             	mov    0x8(%ebp),%eax
  1003ab:	8d 50 01             	lea    0x1(%eax),%edx
  1003ae:	89 55 08             	mov    %edx,0x8(%ebp)
  1003b1:	0f b6 00             	movzbl (%eax),%eax
  1003b4:	88 45 f7             	mov    %al,-0x9(%ebp)
  1003b7:	80 7d f7 00          	cmpb   $0x0,-0x9(%ebp)
  1003bb:	75 d8                	jne    100395 <cputs+0xf>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
  1003bd:	8d 45 f0             	lea    -0x10(%ebp),%eax
  1003c0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1003c4:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
  1003cb:	e8 2a ff ff ff       	call   1002fa <cputch>
    return cnt;
  1003d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1003d3:	c9                   	leave  
  1003d4:	c3                   	ret    

001003d5 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
  1003d5:	55                   	push   %ebp
  1003d6:	89 e5                	mov    %esp,%ebp
  1003d8:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = cons_getc()) == 0)
  1003db:	e8 76 12 00 00       	call   101656 <cons_getc>
  1003e0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1003e3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1003e7:	74 f2                	je     1003db <getchar+0x6>
        /* do nothing */;
    return c;
  1003e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1003ec:	c9                   	leave  
  1003ed:	c3                   	ret    

001003ee <stab_binsearch>:
 *      stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
 * will exit setting left = 118, right = 554.
 * */
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
  1003ee:	55                   	push   %ebp
  1003ef:	89 e5                	mov    %esp,%ebp
  1003f1:	83 ec 20             	sub    $0x20,%esp
    int l = *region_left, r = *region_right, any_matches = 0;
  1003f4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1003f7:	8b 00                	mov    (%eax),%eax
  1003f9:	89 45 fc             	mov    %eax,-0x4(%ebp)
  1003fc:	8b 45 10             	mov    0x10(%ebp),%eax
  1003ff:	8b 00                	mov    (%eax),%eax
  100401:	89 45 f8             	mov    %eax,-0x8(%ebp)
  100404:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

    while (l <= r) {
  10040b:	e9 d2 00 00 00       	jmp    1004e2 <stab_binsearch+0xf4>
        int true_m = (l + r) / 2, m = true_m;
  100410:	8b 45 f8             	mov    -0x8(%ebp),%eax
  100413:	8b 55 fc             	mov    -0x4(%ebp),%edx
  100416:	01 d0                	add    %edx,%eax
  100418:	89 c2                	mov    %eax,%edx
  10041a:	c1 ea 1f             	shr    $0x1f,%edx
  10041d:	01 d0                	add    %edx,%eax
  10041f:	d1 f8                	sar    %eax
  100421:	89 45 ec             	mov    %eax,-0x14(%ebp)
  100424:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100427:	89 45 f0             	mov    %eax,-0x10(%ebp)

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
  10042a:	eb 04                	jmp    100430 <stab_binsearch+0x42>
            m --;
  10042c:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)

    while (l <= r) {
        int true_m = (l + r) / 2, m = true_m;

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
  100430:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100433:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  100436:	7c 1f                	jl     100457 <stab_binsearch+0x69>
  100438:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10043b:	89 d0                	mov    %edx,%eax
  10043d:	01 c0                	add    %eax,%eax
  10043f:	01 d0                	add    %edx,%eax
  100441:	c1 e0 02             	shl    $0x2,%eax
  100444:	89 c2                	mov    %eax,%edx
  100446:	8b 45 08             	mov    0x8(%ebp),%eax
  100449:	01 d0                	add    %edx,%eax
  10044b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  10044f:	0f b6 c0             	movzbl %al,%eax
  100452:	3b 45 14             	cmp    0x14(%ebp),%eax
  100455:	75 d5                	jne    10042c <stab_binsearch+0x3e>
            m --;
        }
        if (m < l) {    // no match in [l, m]
  100457:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10045a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  10045d:	7d 0b                	jge    10046a <stab_binsearch+0x7c>
            l = true_m + 1;
  10045f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100462:	83 c0 01             	add    $0x1,%eax
  100465:	89 45 fc             	mov    %eax,-0x4(%ebp)
            continue;
  100468:	eb 78                	jmp    1004e2 <stab_binsearch+0xf4>
        }

        // actual binary search
        any_matches = 1;
  10046a:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
        if (stabs[m].n_value < addr) {
  100471:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100474:	89 d0                	mov    %edx,%eax
  100476:	01 c0                	add    %eax,%eax
  100478:	01 d0                	add    %edx,%eax
  10047a:	c1 e0 02             	shl    $0x2,%eax
  10047d:	89 c2                	mov    %eax,%edx
  10047f:	8b 45 08             	mov    0x8(%ebp),%eax
  100482:	01 d0                	add    %edx,%eax
  100484:	8b 40 08             	mov    0x8(%eax),%eax
  100487:	3b 45 18             	cmp    0x18(%ebp),%eax
  10048a:	73 13                	jae    10049f <stab_binsearch+0xb1>
            *region_left = m;
  10048c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10048f:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100492:	89 10                	mov    %edx,(%eax)
            l = true_m + 1;
  100494:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100497:	83 c0 01             	add    $0x1,%eax
  10049a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  10049d:	eb 43                	jmp    1004e2 <stab_binsearch+0xf4>
        } else if (stabs[m].n_value > addr) {
  10049f:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1004a2:	89 d0                	mov    %edx,%eax
  1004a4:	01 c0                	add    %eax,%eax
  1004a6:	01 d0                	add    %edx,%eax
  1004a8:	c1 e0 02             	shl    $0x2,%eax
  1004ab:	89 c2                	mov    %eax,%edx
  1004ad:	8b 45 08             	mov    0x8(%ebp),%eax
  1004b0:	01 d0                	add    %edx,%eax
  1004b2:	8b 40 08             	mov    0x8(%eax),%eax
  1004b5:	3b 45 18             	cmp    0x18(%ebp),%eax
  1004b8:	76 16                	jbe    1004d0 <stab_binsearch+0xe2>
            *region_right = m - 1;
  1004ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1004bd:	8d 50 ff             	lea    -0x1(%eax),%edx
  1004c0:	8b 45 10             	mov    0x10(%ebp),%eax
  1004c3:	89 10                	mov    %edx,(%eax)
            r = m - 1;
  1004c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1004c8:	83 e8 01             	sub    $0x1,%eax
  1004cb:	89 45 f8             	mov    %eax,-0x8(%ebp)
  1004ce:	eb 12                	jmp    1004e2 <stab_binsearch+0xf4>
        } else {
            // exact match for 'addr', but continue loop to find
            // *region_right
            *region_left = m;
  1004d0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004d3:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1004d6:	89 10                	mov    %edx,(%eax)
            l = m;
  1004d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1004db:	89 45 fc             	mov    %eax,-0x4(%ebp)
            addr ++;
  1004de:	83 45 18 01          	addl   $0x1,0x18(%ebp)
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
    int l = *region_left, r = *region_right, any_matches = 0;

    while (l <= r) {
  1004e2:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1004e5:	3b 45 f8             	cmp    -0x8(%ebp),%eax
  1004e8:	0f 8e 22 ff ff ff    	jle    100410 <stab_binsearch+0x22>
            l = m;
            addr ++;
        }
    }

    if (!any_matches) {
  1004ee:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1004f2:	75 0f                	jne    100503 <stab_binsearch+0x115>
        *region_right = *region_left - 1;
  1004f4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004f7:	8b 00                	mov    (%eax),%eax
  1004f9:	8d 50 ff             	lea    -0x1(%eax),%edx
  1004fc:	8b 45 10             	mov    0x10(%ebp),%eax
  1004ff:	89 10                	mov    %edx,(%eax)
  100501:	eb 3f                	jmp    100542 <stab_binsearch+0x154>
    }
    else {
        // find rightmost region containing 'addr'
        l = *region_right;
  100503:	8b 45 10             	mov    0x10(%ebp),%eax
  100506:	8b 00                	mov    (%eax),%eax
  100508:	89 45 fc             	mov    %eax,-0x4(%ebp)
        for (; l > *region_left && stabs[l].n_type != type; l --)
  10050b:	eb 04                	jmp    100511 <stab_binsearch+0x123>
  10050d:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
  100511:	8b 45 0c             	mov    0xc(%ebp),%eax
  100514:	8b 00                	mov    (%eax),%eax
  100516:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  100519:	7d 1f                	jge    10053a <stab_binsearch+0x14c>
  10051b:	8b 55 fc             	mov    -0x4(%ebp),%edx
  10051e:	89 d0                	mov    %edx,%eax
  100520:	01 c0                	add    %eax,%eax
  100522:	01 d0                	add    %edx,%eax
  100524:	c1 e0 02             	shl    $0x2,%eax
  100527:	89 c2                	mov    %eax,%edx
  100529:	8b 45 08             	mov    0x8(%ebp),%eax
  10052c:	01 d0                	add    %edx,%eax
  10052e:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  100532:	0f b6 c0             	movzbl %al,%eax
  100535:	3b 45 14             	cmp    0x14(%ebp),%eax
  100538:	75 d3                	jne    10050d <stab_binsearch+0x11f>
            /* do nothing */;
        *region_left = l;
  10053a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10053d:	8b 55 fc             	mov    -0x4(%ebp),%edx
  100540:	89 10                	mov    %edx,(%eax)
    }
}
  100542:	c9                   	leave  
  100543:	c3                   	ret    

00100544 <debuginfo_eip>:
 * the specified instruction address, @addr.  Returns 0 if information
 * was found, and negative if not.  But even if it returns negative it
 * has stored some information into '*info'.
 * */
int
debuginfo_eip(uintptr_t addr, struct eipdebuginfo *info) {
  100544:	55                   	push   %ebp
  100545:	89 e5                	mov    %esp,%ebp
  100547:	83 ec 58             	sub    $0x58,%esp
    const struct stab *stabs, *stab_end;
    const char *stabstr, *stabstr_end;

    info->eip_file = "<unknown>";
  10054a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10054d:	c7 00 2c 63 10 00    	movl   $0x10632c,(%eax)
    info->eip_line = 0;
  100553:	8b 45 0c             	mov    0xc(%ebp),%eax
  100556:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
    info->eip_fn_name = "<unknown>";
  10055d:	8b 45 0c             	mov    0xc(%ebp),%eax
  100560:	c7 40 08 2c 63 10 00 	movl   $0x10632c,0x8(%eax)
    info->eip_fn_namelen = 9;
  100567:	8b 45 0c             	mov    0xc(%ebp),%eax
  10056a:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
    info->eip_fn_addr = addr;
  100571:	8b 45 0c             	mov    0xc(%ebp),%eax
  100574:	8b 55 08             	mov    0x8(%ebp),%edx
  100577:	89 50 10             	mov    %edx,0x10(%eax)
    info->eip_fn_narg = 0;
  10057a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10057d:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

    stabs = __STAB_BEGIN__;
  100584:	c7 45 f4 b4 75 10 00 	movl   $0x1075b4,-0xc(%ebp)
    stab_end = __STAB_END__;
  10058b:	c7 45 f0 6c 23 11 00 	movl   $0x11236c,-0x10(%ebp)
    stabstr = __STABSTR_BEGIN__;
  100592:	c7 45 ec 6d 23 11 00 	movl   $0x11236d,-0x14(%ebp)
    stabstr_end = __STABSTR_END__;
  100599:	c7 45 e8 c6 4d 11 00 	movl   $0x114dc6,-0x18(%ebp)

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0) {
  1005a0:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1005a3:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1005a6:	76 0d                	jbe    1005b5 <debuginfo_eip+0x71>
  1005a8:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1005ab:	83 e8 01             	sub    $0x1,%eax
  1005ae:	0f b6 00             	movzbl (%eax),%eax
  1005b1:	84 c0                	test   %al,%al
  1005b3:	74 0a                	je     1005bf <debuginfo_eip+0x7b>
        return -1;
  1005b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1005ba:	e9 c0 02 00 00       	jmp    10087f <debuginfo_eip+0x33b>
    // 'eip'.  First, we find the basic source file containing 'eip'.
    // Then, we look in that source file for the function.  Then we look
    // for the line number.

    // Search the entire set of stabs for the source file (type N_SO).
    int lfile = 0, rfile = (stab_end - stabs) - 1;
  1005bf:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  1005c6:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1005c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1005cc:	29 c2                	sub    %eax,%edx
  1005ce:	89 d0                	mov    %edx,%eax
  1005d0:	c1 f8 02             	sar    $0x2,%eax
  1005d3:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
  1005d9:	83 e8 01             	sub    $0x1,%eax
  1005dc:	89 45 e0             	mov    %eax,-0x20(%ebp)
    stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
  1005df:	8b 45 08             	mov    0x8(%ebp),%eax
  1005e2:	89 44 24 10          	mov    %eax,0x10(%esp)
  1005e6:	c7 44 24 0c 64 00 00 	movl   $0x64,0xc(%esp)
  1005ed:	00 
  1005ee:	8d 45 e0             	lea    -0x20(%ebp),%eax
  1005f1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1005f5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  1005f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1005ff:	89 04 24             	mov    %eax,(%esp)
  100602:	e8 e7 fd ff ff       	call   1003ee <stab_binsearch>
    if (lfile == 0)
  100607:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10060a:	85 c0                	test   %eax,%eax
  10060c:	75 0a                	jne    100618 <debuginfo_eip+0xd4>
        return -1;
  10060e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  100613:	e9 67 02 00 00       	jmp    10087f <debuginfo_eip+0x33b>

    // Search within that file's stabs for the function definition
    // (N_FUN).
    int lfun = lfile, rfun = rfile;
  100618:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10061b:	89 45 dc             	mov    %eax,-0x24(%ebp)
  10061e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100621:	89 45 d8             	mov    %eax,-0x28(%ebp)
    int lline, rline;
    stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
  100624:	8b 45 08             	mov    0x8(%ebp),%eax
  100627:	89 44 24 10          	mov    %eax,0x10(%esp)
  10062b:	c7 44 24 0c 24 00 00 	movl   $0x24,0xc(%esp)
  100632:	00 
  100633:	8d 45 d8             	lea    -0x28(%ebp),%eax
  100636:	89 44 24 08          	mov    %eax,0x8(%esp)
  10063a:	8d 45 dc             	lea    -0x24(%ebp),%eax
  10063d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100641:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100644:	89 04 24             	mov    %eax,(%esp)
  100647:	e8 a2 fd ff ff       	call   1003ee <stab_binsearch>

    if (lfun <= rfun) {
  10064c:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10064f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  100652:	39 c2                	cmp    %eax,%edx
  100654:	7f 7c                	jg     1006d2 <debuginfo_eip+0x18e>
        // stabs[lfun] points to the function name
        // in the string table, but check bounds just in case.
        if (stabs[lfun].n_strx < stabstr_end - stabstr) {
  100656:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100659:	89 c2                	mov    %eax,%edx
  10065b:	89 d0                	mov    %edx,%eax
  10065d:	01 c0                	add    %eax,%eax
  10065f:	01 d0                	add    %edx,%eax
  100661:	c1 e0 02             	shl    $0x2,%eax
  100664:	89 c2                	mov    %eax,%edx
  100666:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100669:	01 d0                	add    %edx,%eax
  10066b:	8b 10                	mov    (%eax),%edx
  10066d:	8b 4d e8             	mov    -0x18(%ebp),%ecx
  100670:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100673:	29 c1                	sub    %eax,%ecx
  100675:	89 c8                	mov    %ecx,%eax
  100677:	39 c2                	cmp    %eax,%edx
  100679:	73 22                	jae    10069d <debuginfo_eip+0x159>
            info->eip_fn_name = stabstr + stabs[lfun].n_strx;
  10067b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10067e:	89 c2                	mov    %eax,%edx
  100680:	89 d0                	mov    %edx,%eax
  100682:	01 c0                	add    %eax,%eax
  100684:	01 d0                	add    %edx,%eax
  100686:	c1 e0 02             	shl    $0x2,%eax
  100689:	89 c2                	mov    %eax,%edx
  10068b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10068e:	01 d0                	add    %edx,%eax
  100690:	8b 10                	mov    (%eax),%edx
  100692:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100695:	01 c2                	add    %eax,%edx
  100697:	8b 45 0c             	mov    0xc(%ebp),%eax
  10069a:	89 50 08             	mov    %edx,0x8(%eax)
        }
        info->eip_fn_addr = stabs[lfun].n_value;
  10069d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1006a0:	89 c2                	mov    %eax,%edx
  1006a2:	89 d0                	mov    %edx,%eax
  1006a4:	01 c0                	add    %eax,%eax
  1006a6:	01 d0                	add    %edx,%eax
  1006a8:	c1 e0 02             	shl    $0x2,%eax
  1006ab:	89 c2                	mov    %eax,%edx
  1006ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1006b0:	01 d0                	add    %edx,%eax
  1006b2:	8b 50 08             	mov    0x8(%eax),%edx
  1006b5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1006b8:	89 50 10             	mov    %edx,0x10(%eax)
        addr -= info->eip_fn_addr;
  1006bb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1006be:	8b 40 10             	mov    0x10(%eax),%eax
  1006c1:	29 45 08             	sub    %eax,0x8(%ebp)
        // Search within the function definition for the line number.
        lline = lfun;
  1006c4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1006c7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfun;
  1006ca:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1006cd:	89 45 d0             	mov    %eax,-0x30(%ebp)
  1006d0:	eb 15                	jmp    1006e7 <debuginfo_eip+0x1a3>
    } else {
        // Couldn't find function stab!  Maybe we're in an assembly
        // file.  Search the whole file for the line number.
        info->eip_fn_addr = addr;
  1006d2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1006d5:	8b 55 08             	mov    0x8(%ebp),%edx
  1006d8:	89 50 10             	mov    %edx,0x10(%eax)
        lline = lfile;
  1006db:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1006de:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfile;
  1006e1:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1006e4:	89 45 d0             	mov    %eax,-0x30(%ebp)
    }
    info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
  1006e7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1006ea:	8b 40 08             	mov    0x8(%eax),%eax
  1006ed:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
  1006f4:	00 
  1006f5:	89 04 24             	mov    %eax,(%esp)
  1006f8:	e8 5e 58 00 00       	call   105f5b <strfind>
  1006fd:	89 c2                	mov    %eax,%edx
  1006ff:	8b 45 0c             	mov    0xc(%ebp),%eax
  100702:	8b 40 08             	mov    0x8(%eax),%eax
  100705:	29 c2                	sub    %eax,%edx
  100707:	8b 45 0c             	mov    0xc(%ebp),%eax
  10070a:	89 50 0c             	mov    %edx,0xc(%eax)

    // Search within [lline, rline] for the line number stab.
    // If found, set info->eip_line to the right line number.
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
  10070d:	8b 45 08             	mov    0x8(%ebp),%eax
  100710:	89 44 24 10          	mov    %eax,0x10(%esp)
  100714:	c7 44 24 0c 44 00 00 	movl   $0x44,0xc(%esp)
  10071b:	00 
  10071c:	8d 45 d0             	lea    -0x30(%ebp),%eax
  10071f:	89 44 24 08          	mov    %eax,0x8(%esp)
  100723:	8d 45 d4             	lea    -0x2c(%ebp),%eax
  100726:	89 44 24 04          	mov    %eax,0x4(%esp)
  10072a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10072d:	89 04 24             	mov    %eax,(%esp)
  100730:	e8 b9 fc ff ff       	call   1003ee <stab_binsearch>
    if (lline <= rline) {
  100735:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  100738:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10073b:	39 c2                	cmp    %eax,%edx
  10073d:	7f 24                	jg     100763 <debuginfo_eip+0x21f>
        info->eip_line = stabs[rline].n_desc;
  10073f:	8b 45 d0             	mov    -0x30(%ebp),%eax
  100742:	89 c2                	mov    %eax,%edx
  100744:	89 d0                	mov    %edx,%eax
  100746:	01 c0                	add    %eax,%eax
  100748:	01 d0                	add    %edx,%eax
  10074a:	c1 e0 02             	shl    $0x2,%eax
  10074d:	89 c2                	mov    %eax,%edx
  10074f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100752:	01 d0                	add    %edx,%eax
  100754:	0f b7 40 06          	movzwl 0x6(%eax),%eax
  100758:	0f b7 d0             	movzwl %ax,%edx
  10075b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10075e:	89 50 04             	mov    %edx,0x4(%eax)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
  100761:	eb 13                	jmp    100776 <debuginfo_eip+0x232>
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
    if (lline <= rline) {
        info->eip_line = stabs[rline].n_desc;
    } else {
        return -1;
  100763:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  100768:	e9 12 01 00 00       	jmp    10087f <debuginfo_eip+0x33b>
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
           && stabs[lline].n_type != N_SOL
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
        lline --;
  10076d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  100770:	83 e8 01             	sub    $0x1,%eax
  100773:	89 45 d4             	mov    %eax,-0x2c(%ebp)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
  100776:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  100779:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10077c:	39 c2                	cmp    %eax,%edx
  10077e:	7c 56                	jl     1007d6 <debuginfo_eip+0x292>
           && stabs[lline].n_type != N_SOL
  100780:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  100783:	89 c2                	mov    %eax,%edx
  100785:	89 d0                	mov    %edx,%eax
  100787:	01 c0                	add    %eax,%eax
  100789:	01 d0                	add    %edx,%eax
  10078b:	c1 e0 02             	shl    $0x2,%eax
  10078e:	89 c2                	mov    %eax,%edx
  100790:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100793:	01 d0                	add    %edx,%eax
  100795:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  100799:	3c 84                	cmp    $0x84,%al
  10079b:	74 39                	je     1007d6 <debuginfo_eip+0x292>
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
  10079d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1007a0:	89 c2                	mov    %eax,%edx
  1007a2:	89 d0                	mov    %edx,%eax
  1007a4:	01 c0                	add    %eax,%eax
  1007a6:	01 d0                	add    %edx,%eax
  1007a8:	c1 e0 02             	shl    $0x2,%eax
  1007ab:	89 c2                	mov    %eax,%edx
  1007ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1007b0:	01 d0                	add    %edx,%eax
  1007b2:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  1007b6:	3c 64                	cmp    $0x64,%al
  1007b8:	75 b3                	jne    10076d <debuginfo_eip+0x229>
  1007ba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1007bd:	89 c2                	mov    %eax,%edx
  1007bf:	89 d0                	mov    %edx,%eax
  1007c1:	01 c0                	add    %eax,%eax
  1007c3:	01 d0                	add    %edx,%eax
  1007c5:	c1 e0 02             	shl    $0x2,%eax
  1007c8:	89 c2                	mov    %eax,%edx
  1007ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1007cd:	01 d0                	add    %edx,%eax
  1007cf:	8b 40 08             	mov    0x8(%eax),%eax
  1007d2:	85 c0                	test   %eax,%eax
  1007d4:	74 97                	je     10076d <debuginfo_eip+0x229>
        lline --;
    }
    if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr) {
  1007d6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1007d9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1007dc:	39 c2                	cmp    %eax,%edx
  1007de:	7c 46                	jl     100826 <debuginfo_eip+0x2e2>
  1007e0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1007e3:	89 c2                	mov    %eax,%edx
  1007e5:	89 d0                	mov    %edx,%eax
  1007e7:	01 c0                	add    %eax,%eax
  1007e9:	01 d0                	add    %edx,%eax
  1007eb:	c1 e0 02             	shl    $0x2,%eax
  1007ee:	89 c2                	mov    %eax,%edx
  1007f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1007f3:	01 d0                	add    %edx,%eax
  1007f5:	8b 10                	mov    (%eax),%edx
  1007f7:	8b 4d e8             	mov    -0x18(%ebp),%ecx
  1007fa:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1007fd:	29 c1                	sub    %eax,%ecx
  1007ff:	89 c8                	mov    %ecx,%eax
  100801:	39 c2                	cmp    %eax,%edx
  100803:	73 21                	jae    100826 <debuginfo_eip+0x2e2>
        info->eip_file = stabstr + stabs[lline].n_strx;
  100805:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  100808:	89 c2                	mov    %eax,%edx
  10080a:	89 d0                	mov    %edx,%eax
  10080c:	01 c0                	add    %eax,%eax
  10080e:	01 d0                	add    %edx,%eax
  100810:	c1 e0 02             	shl    $0x2,%eax
  100813:	89 c2                	mov    %eax,%edx
  100815:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100818:	01 d0                	add    %edx,%eax
  10081a:	8b 10                	mov    (%eax),%edx
  10081c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10081f:	01 c2                	add    %eax,%edx
  100821:	8b 45 0c             	mov    0xc(%ebp),%eax
  100824:	89 10                	mov    %edx,(%eax)
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
  100826:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100829:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10082c:	39 c2                	cmp    %eax,%edx
  10082e:	7d 4a                	jge    10087a <debuginfo_eip+0x336>
        for (lline = lfun + 1;
  100830:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100833:	83 c0 01             	add    $0x1,%eax
  100836:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  100839:	eb 18                	jmp    100853 <debuginfo_eip+0x30f>
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
            info->eip_fn_narg ++;
  10083b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10083e:	8b 40 14             	mov    0x14(%eax),%eax
  100841:	8d 50 01             	lea    0x1(%eax),%edx
  100844:	8b 45 0c             	mov    0xc(%ebp),%eax
  100847:	89 50 14             	mov    %edx,0x14(%eax)
    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
  10084a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10084d:	83 c0 01             	add    $0x1,%eax
  100850:	89 45 d4             	mov    %eax,-0x2c(%ebp)

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM;
  100853:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  100856:	8b 45 d8             	mov    -0x28(%ebp),%eax
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
  100859:	39 c2                	cmp    %eax,%edx
  10085b:	7d 1d                	jge    10087a <debuginfo_eip+0x336>
             lline < rfun && stabs[lline].n_type == N_PSYM;
  10085d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  100860:	89 c2                	mov    %eax,%edx
  100862:	89 d0                	mov    %edx,%eax
  100864:	01 c0                	add    %eax,%eax
  100866:	01 d0                	add    %edx,%eax
  100868:	c1 e0 02             	shl    $0x2,%eax
  10086b:	89 c2                	mov    %eax,%edx
  10086d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100870:	01 d0                	add    %edx,%eax
  100872:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  100876:	3c a0                	cmp    $0xa0,%al
  100878:	74 c1                	je     10083b <debuginfo_eip+0x2f7>
             lline ++) {
            info->eip_fn_narg ++;
        }
    }
    return 0;
  10087a:	b8 00 00 00 00       	mov    $0x0,%eax
}
  10087f:	c9                   	leave  
  100880:	c3                   	ret    

00100881 <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void
print_kerninfo(void) {
  100881:	55                   	push   %ebp
  100882:	89 e5                	mov    %esp,%ebp
  100884:	83 ec 18             	sub    $0x18,%esp
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
  100887:	c7 04 24 36 63 10 00 	movl   $0x106336,(%esp)
  10088e:	e8 ba fa ff ff       	call   10034d <cprintf>
    cprintf("  entry  0x%08x (phys)\n", kern_init);
  100893:	c7 44 24 04 2f 00 10 	movl   $0x10002f,0x4(%esp)
  10089a:	00 
  10089b:	c7 04 24 4f 63 10 00 	movl   $0x10634f,(%esp)
  1008a2:	e8 a6 fa ff ff       	call   10034d <cprintf>
    cprintf("  etext  0x%08x (phys)\n", etext);
  1008a7:	c7 44 24 04 70 62 10 	movl   $0x106270,0x4(%esp)
  1008ae:	00 
  1008af:	c7 04 24 67 63 10 00 	movl   $0x106367,(%esp)
  1008b6:	e8 92 fa ff ff       	call   10034d <cprintf>
    cprintf("  edata  0x%08x (phys)\n", edata);
  1008bb:	c7 44 24 04 36 7a 11 	movl   $0x117a36,0x4(%esp)
  1008c2:	00 
  1008c3:	c7 04 24 7f 63 10 00 	movl   $0x10637f,(%esp)
  1008ca:	e8 7e fa ff ff       	call   10034d <cprintf>
    cprintf("  end    0x%08x (phys)\n", end);
  1008cf:	c7 44 24 04 28 af 11 	movl   $0x11af28,0x4(%esp)
  1008d6:	00 
  1008d7:	c7 04 24 97 63 10 00 	movl   $0x106397,(%esp)
  1008de:	e8 6a fa ff ff       	call   10034d <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n", (end - kern_init + 1023)/1024);
  1008e3:	b8 28 af 11 00       	mov    $0x11af28,%eax
  1008e8:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
  1008ee:	b8 2f 00 10 00       	mov    $0x10002f,%eax
  1008f3:	29 c2                	sub    %eax,%edx
  1008f5:	89 d0                	mov    %edx,%eax
  1008f7:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
  1008fd:	85 c0                	test   %eax,%eax
  1008ff:	0f 48 c2             	cmovs  %edx,%eax
  100902:	c1 f8 0a             	sar    $0xa,%eax
  100905:	89 44 24 04          	mov    %eax,0x4(%esp)
  100909:	c7 04 24 b0 63 10 00 	movl   $0x1063b0,(%esp)
  100910:	e8 38 fa ff ff       	call   10034d <cprintf>
}
  100915:	c9                   	leave  
  100916:	c3                   	ret    

00100917 <print_debuginfo>:
/* *
 * print_debuginfo - read and print the stat information for the address @eip,
 * and info.eip_fn_addr should be the first address of the related function.
 * */
void
print_debuginfo(uintptr_t eip) {
  100917:	55                   	push   %ebp
  100918:	89 e5                	mov    %esp,%ebp
  10091a:	81 ec 48 01 00 00    	sub    $0x148,%esp
    struct eipdebuginfo info;
    if (debuginfo_eip(eip, &info) != 0) {
  100920:	8d 45 dc             	lea    -0x24(%ebp),%eax
  100923:	89 44 24 04          	mov    %eax,0x4(%esp)
  100927:	8b 45 08             	mov    0x8(%ebp),%eax
  10092a:	89 04 24             	mov    %eax,(%esp)
  10092d:	e8 12 fc ff ff       	call   100544 <debuginfo_eip>
  100932:	85 c0                	test   %eax,%eax
  100934:	74 15                	je     10094b <print_debuginfo+0x34>
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
  100936:	8b 45 08             	mov    0x8(%ebp),%eax
  100939:	89 44 24 04          	mov    %eax,0x4(%esp)
  10093d:	c7 04 24 da 63 10 00 	movl   $0x1063da,(%esp)
  100944:	e8 04 fa ff ff       	call   10034d <cprintf>
  100949:	eb 6d                	jmp    1009b8 <print_debuginfo+0xa1>
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
  10094b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100952:	eb 1c                	jmp    100970 <print_debuginfo+0x59>
            fnname[j] = info.eip_fn_name[j];
  100954:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100957:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10095a:	01 d0                	add    %edx,%eax
  10095c:	0f b6 00             	movzbl (%eax),%eax
  10095f:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
  100965:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100968:	01 ca                	add    %ecx,%edx
  10096a:	88 02                	mov    %al,(%edx)
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
  10096c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100970:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100973:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  100976:	7f dc                	jg     100954 <print_debuginfo+0x3d>
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
  100978:	8d 95 dc fe ff ff    	lea    -0x124(%ebp),%edx
  10097e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100981:	01 d0                	add    %edx,%eax
  100983:	c6 00 00             	movb   $0x0,(%eax)
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
                fnname, eip - info.eip_fn_addr);
  100986:	8b 45 ec             	mov    -0x14(%ebp),%eax
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
  100989:	8b 55 08             	mov    0x8(%ebp),%edx
  10098c:	89 d1                	mov    %edx,%ecx
  10098e:	29 c1                	sub    %eax,%ecx
  100990:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100993:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100996:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  10099a:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
  1009a0:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  1009a4:	89 54 24 08          	mov    %edx,0x8(%esp)
  1009a8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009ac:	c7 04 24 f6 63 10 00 	movl   $0x1063f6,(%esp)
  1009b3:	e8 95 f9 ff ff       	call   10034d <cprintf>
                fnname, eip - info.eip_fn_addr);
    }
}
  1009b8:	c9                   	leave  
  1009b9:	c3                   	ret    

001009ba <read_eip>:

static __noinline uint32_t
read_eip(void) {
  1009ba:	55                   	push   %ebp
  1009bb:	89 e5                	mov    %esp,%ebp
  1009bd:	83 ec 10             	sub    $0x10,%esp
    uint32_t eip;
    asm volatile("movl 4(%%ebp), %0" : "=r" (eip));
  1009c0:	8b 45 04             	mov    0x4(%ebp),%eax
  1009c3:	89 45 fc             	mov    %eax,-0x4(%ebp)
    return eip;
  1009c6:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1009c9:	c9                   	leave  
  1009ca:	c3                   	ret    

001009cb <print_stackframe>:
 *
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the boundary.
 * */
void
print_stackframe(void) {
  1009cb:	55                   	push   %ebp
  1009cc:	89 e5                	mov    %esp,%ebp
  1009ce:	53                   	push   %ebx
  1009cf:	83 ec 34             	sub    $0x34,%esp
}

static inline uint32_t
read_ebp(void) {
    uint32_t ebp;
    asm volatile ("movl %%ebp, %0" : "=r" (ebp));
  1009d2:	89 e8                	mov    %ebp,%eax
  1009d4:	89 45 e8             	mov    %eax,-0x18(%ebp)
    return ebp;
  1009d7:	8b 45 e8             	mov    -0x18(%ebp),%eax
      *    (3.4) call print_debuginfo(eip-1) to print the C calling function name and line number, etc.
      *    (3.5) popup a calling stackframe
      *           NOTICE: the calling funciton's return addr eip  = ss:[ebp+4]
      *                   the calling funciton's ebp = ss:[ebp]
      */
    uint32_t ebp = read_ebp();
  1009da:	89 45 f4             	mov    %eax,-0xc(%ebp)
    uint32_t eip = read_eip();
  1009dd:	e8 d8 ff ff ff       	call   1009ba <read_eip>
  1009e2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    int i;
    for (i = 0; i < ebp && STACKFRAME_DEPTH; i++) {
  1009e5:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  1009ec:	e9 87 00 00 00       	jmp    100a78 <print_stackframe+0xad>
        cprintf("ebp:%08x eip:%08x ", ebp, eip);
  1009f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1009f4:	89 44 24 08          	mov    %eax,0x8(%esp)
  1009f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1009fb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009ff:	c7 04 24 08 64 10 00 	movl   $0x106408,(%esp)
  100a06:	e8 42 f9 ff ff       	call   10034d <cprintf>
        cprintf("args:%08x %08x %08x %08x", *(uint32_t*)(ebp + 8), *(uint32_t*)(ebp + 12), *(uint32_t*)(ebp + 16), *(uint32_t*)(ebp + 20));
  100a0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a0e:	83 c0 14             	add    $0x14,%eax
  100a11:	8b 18                	mov    (%eax),%ebx
  100a13:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a16:	83 c0 10             	add    $0x10,%eax
  100a19:	8b 08                	mov    (%eax),%ecx
  100a1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a1e:	83 c0 0c             	add    $0xc,%eax
  100a21:	8b 10                	mov    (%eax),%edx
  100a23:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a26:	83 c0 08             	add    $0x8,%eax
  100a29:	8b 00                	mov    (%eax),%eax
  100a2b:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  100a2f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  100a33:	89 54 24 08          	mov    %edx,0x8(%esp)
  100a37:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a3b:	c7 04 24 1b 64 10 00 	movl   $0x10641b,(%esp)
  100a42:	e8 06 f9 ff ff       	call   10034d <cprintf>
        cprintf("\n");
  100a47:	c7 04 24 34 64 10 00 	movl   $0x106434,(%esp)
  100a4e:	e8 fa f8 ff ff       	call   10034d <cprintf>
        print_debuginfo(eip - 1);
  100a53:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100a56:	83 e8 01             	sub    $0x1,%eax
  100a59:	89 04 24             	mov    %eax,(%esp)
  100a5c:	e8 b6 fe ff ff       	call   100917 <print_debuginfo>
        eip = *(uint32_t*)(ebp + 4); //这里要先更新eip再更新ebp
  100a61:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a64:	83 c0 04             	add    $0x4,%eax
  100a67:	8b 00                	mov    (%eax),%eax
  100a69:	89 45 f0             	mov    %eax,-0x10(%ebp)
        ebp = *(uint32_t*)(ebp);
  100a6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a6f:	8b 00                	mov    (%eax),%eax
  100a71:	89 45 f4             	mov    %eax,-0xc(%ebp)
      *                   the calling funciton's ebp = ss:[ebp]
      */
    uint32_t ebp = read_ebp();
    uint32_t eip = read_eip();
    int i;
    for (i = 0; i < ebp && STACKFRAME_DEPTH; i++) {
  100a74:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  100a78:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100a7b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  100a7e:	0f 82 6d ff ff ff    	jb     1009f1 <print_stackframe+0x26>
        cprintf("\n");
        print_debuginfo(eip - 1);
        eip = *(uint32_t*)(ebp + 4); //这里要先更新eip再更新ebp
        ebp = *(uint32_t*)(ebp);
    }
}
  100a84:	83 c4 34             	add    $0x34,%esp
  100a87:	5b                   	pop    %ebx
  100a88:	5d                   	pop    %ebp
  100a89:	c3                   	ret    

00100a8a <parse>:
#define MAXARGS         16
#define WHITESPACE      " \t\n\r"

/* parse - parse the command buffer into whitespace-separated arguments */
static int
parse(char *buf, char **argv) {
  100a8a:	55                   	push   %ebp
  100a8b:	89 e5                	mov    %esp,%ebp
  100a8d:	83 ec 28             	sub    $0x28,%esp
    int argc = 0;
  100a90:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
  100a97:	eb 0c                	jmp    100aa5 <parse+0x1b>
            *buf ++ = '\0';
  100a99:	8b 45 08             	mov    0x8(%ebp),%eax
  100a9c:	8d 50 01             	lea    0x1(%eax),%edx
  100a9f:	89 55 08             	mov    %edx,0x8(%ebp)
  100aa2:	c6 00 00             	movb   $0x0,(%eax)
static int
parse(char *buf, char **argv) {
    int argc = 0;
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
  100aa5:	8b 45 08             	mov    0x8(%ebp),%eax
  100aa8:	0f b6 00             	movzbl (%eax),%eax
  100aab:	84 c0                	test   %al,%al
  100aad:	74 1d                	je     100acc <parse+0x42>
  100aaf:	8b 45 08             	mov    0x8(%ebp),%eax
  100ab2:	0f b6 00             	movzbl (%eax),%eax
  100ab5:	0f be c0             	movsbl %al,%eax
  100ab8:	89 44 24 04          	mov    %eax,0x4(%esp)
  100abc:	c7 04 24 b8 64 10 00 	movl   $0x1064b8,(%esp)
  100ac3:	e8 60 54 00 00       	call   105f28 <strchr>
  100ac8:	85 c0                	test   %eax,%eax
  100aca:	75 cd                	jne    100a99 <parse+0xf>
            *buf ++ = '\0';
        }
        if (*buf == '\0') {
  100acc:	8b 45 08             	mov    0x8(%ebp),%eax
  100acf:	0f b6 00             	movzbl (%eax),%eax
  100ad2:	84 c0                	test   %al,%al
  100ad4:	75 02                	jne    100ad8 <parse+0x4e>
            break;
  100ad6:	eb 67                	jmp    100b3f <parse+0xb5>
        }

        // save and scan past next arg
        if (argc == MAXARGS - 1) {
  100ad8:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
  100adc:	75 14                	jne    100af2 <parse+0x68>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
  100ade:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  100ae5:	00 
  100ae6:	c7 04 24 bd 64 10 00 	movl   $0x1064bd,(%esp)
  100aed:	e8 5b f8 ff ff       	call   10034d <cprintf>
        }
        argv[argc ++] = buf;
  100af2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100af5:	8d 50 01             	lea    0x1(%eax),%edx
  100af8:	89 55 f4             	mov    %edx,-0xc(%ebp)
  100afb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  100b02:	8b 45 0c             	mov    0xc(%ebp),%eax
  100b05:	01 c2                	add    %eax,%edx
  100b07:	8b 45 08             	mov    0x8(%ebp),%eax
  100b0a:	89 02                	mov    %eax,(%edx)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
  100b0c:	eb 04                	jmp    100b12 <parse+0x88>
            buf ++;
  100b0e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
        // save and scan past next arg
        if (argc == MAXARGS - 1) {
            cprintf("Too many arguments (max %d).\n", MAXARGS);
        }
        argv[argc ++] = buf;
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
  100b12:	8b 45 08             	mov    0x8(%ebp),%eax
  100b15:	0f b6 00             	movzbl (%eax),%eax
  100b18:	84 c0                	test   %al,%al
  100b1a:	74 1d                	je     100b39 <parse+0xaf>
  100b1c:	8b 45 08             	mov    0x8(%ebp),%eax
  100b1f:	0f b6 00             	movzbl (%eax),%eax
  100b22:	0f be c0             	movsbl %al,%eax
  100b25:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b29:	c7 04 24 b8 64 10 00 	movl   $0x1064b8,(%esp)
  100b30:	e8 f3 53 00 00       	call   105f28 <strchr>
  100b35:	85 c0                	test   %eax,%eax
  100b37:	74 d5                	je     100b0e <parse+0x84>
            buf ++;
        }
    }
  100b39:	90                   	nop
static int
parse(char *buf, char **argv) {
    int argc = 0;
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
  100b3a:	e9 66 ff ff ff       	jmp    100aa5 <parse+0x1b>
        argv[argc ++] = buf;
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
            buf ++;
        }
    }
    return argc;
  100b3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100b42:	c9                   	leave  
  100b43:	c3                   	ret    

00100b44 <runcmd>:
/* *
 * runcmd - parse the input string, split it into separated arguments
 * and then lookup and invoke some related commands/
 * */
static int
runcmd(char *buf, struct trapframe *tf) {
  100b44:	55                   	push   %ebp
  100b45:	89 e5                	mov    %esp,%ebp
  100b47:	83 ec 68             	sub    $0x68,%esp
    char *argv[MAXARGS];
    int argc = parse(buf, argv);
  100b4a:	8d 45 b0             	lea    -0x50(%ebp),%eax
  100b4d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b51:	8b 45 08             	mov    0x8(%ebp),%eax
  100b54:	89 04 24             	mov    %eax,(%esp)
  100b57:	e8 2e ff ff ff       	call   100a8a <parse>
  100b5c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if (argc == 0) {
  100b5f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  100b63:	75 0a                	jne    100b6f <runcmd+0x2b>
        return 0;
  100b65:	b8 00 00 00 00       	mov    $0x0,%eax
  100b6a:	e9 85 00 00 00       	jmp    100bf4 <runcmd+0xb0>
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
  100b6f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100b76:	eb 5c                	jmp    100bd4 <runcmd+0x90>
        if (strcmp(commands[i].name, argv[0]) == 0) {
  100b78:	8b 4d b0             	mov    -0x50(%ebp),%ecx
  100b7b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100b7e:	89 d0                	mov    %edx,%eax
  100b80:	01 c0                	add    %eax,%eax
  100b82:	01 d0                	add    %edx,%eax
  100b84:	c1 e0 02             	shl    $0x2,%eax
  100b87:	05 00 70 11 00       	add    $0x117000,%eax
  100b8c:	8b 00                	mov    (%eax),%eax
  100b8e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  100b92:	89 04 24             	mov    %eax,(%esp)
  100b95:	e8 ef 52 00 00       	call   105e89 <strcmp>
  100b9a:	85 c0                	test   %eax,%eax
  100b9c:	75 32                	jne    100bd0 <runcmd+0x8c>
            return commands[i].func(argc - 1, argv + 1, tf);
  100b9e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100ba1:	89 d0                	mov    %edx,%eax
  100ba3:	01 c0                	add    %eax,%eax
  100ba5:	01 d0                	add    %edx,%eax
  100ba7:	c1 e0 02             	shl    $0x2,%eax
  100baa:	05 00 70 11 00       	add    $0x117000,%eax
  100baf:	8b 40 08             	mov    0x8(%eax),%eax
  100bb2:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100bb5:	8d 4a ff             	lea    -0x1(%edx),%ecx
  100bb8:	8b 55 0c             	mov    0xc(%ebp),%edx
  100bbb:	89 54 24 08          	mov    %edx,0x8(%esp)
  100bbf:	8d 55 b0             	lea    -0x50(%ebp),%edx
  100bc2:	83 c2 04             	add    $0x4,%edx
  100bc5:	89 54 24 04          	mov    %edx,0x4(%esp)
  100bc9:	89 0c 24             	mov    %ecx,(%esp)
  100bcc:	ff d0                	call   *%eax
  100bce:	eb 24                	jmp    100bf4 <runcmd+0xb0>
    int argc = parse(buf, argv);
    if (argc == 0) {
        return 0;
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
  100bd0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100bd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100bd7:	83 f8 02             	cmp    $0x2,%eax
  100bda:	76 9c                	jbe    100b78 <runcmd+0x34>
        if (strcmp(commands[i].name, argv[0]) == 0) {
            return commands[i].func(argc - 1, argv + 1, tf);
        }
    }
    cprintf("Unknown command '%s'\n", argv[0]);
  100bdc:	8b 45 b0             	mov    -0x50(%ebp),%eax
  100bdf:	89 44 24 04          	mov    %eax,0x4(%esp)
  100be3:	c7 04 24 db 64 10 00 	movl   $0x1064db,(%esp)
  100bea:	e8 5e f7 ff ff       	call   10034d <cprintf>
    return 0;
  100bef:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100bf4:	c9                   	leave  
  100bf5:	c3                   	ret    

00100bf6 <kmonitor>:

/***** Implementations of basic kernel monitor commands *****/

void
kmonitor(struct trapframe *tf) {
  100bf6:	55                   	push   %ebp
  100bf7:	89 e5                	mov    %esp,%ebp
  100bf9:	83 ec 28             	sub    $0x28,%esp
    cprintf("Welcome to the kernel debug monitor!!\n");
  100bfc:	c7 04 24 f4 64 10 00 	movl   $0x1064f4,(%esp)
  100c03:	e8 45 f7 ff ff       	call   10034d <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
  100c08:	c7 04 24 1c 65 10 00 	movl   $0x10651c,(%esp)
  100c0f:	e8 39 f7 ff ff       	call   10034d <cprintf>

    if (tf != NULL) {
  100c14:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  100c18:	74 0b                	je     100c25 <kmonitor+0x2f>
        print_trapframe(tf);
  100c1a:	8b 45 08             	mov    0x8(%ebp),%eax
  100c1d:	89 04 24             	mov    %eax,(%esp)
  100c20:	e8 3b 0f 00 00       	call   101b60 <print_trapframe>
    }

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
  100c25:	c7 04 24 41 65 10 00 	movl   $0x106541,(%esp)
  100c2c:	e8 13 f6 ff ff       	call   100244 <readline>
  100c31:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100c34:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100c38:	74 18                	je     100c52 <kmonitor+0x5c>
            if (runcmd(buf, tf) < 0) {
  100c3a:	8b 45 08             	mov    0x8(%ebp),%eax
  100c3d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100c41:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100c44:	89 04 24             	mov    %eax,(%esp)
  100c47:	e8 f8 fe ff ff       	call   100b44 <runcmd>
  100c4c:	85 c0                	test   %eax,%eax
  100c4e:	79 02                	jns    100c52 <kmonitor+0x5c>
                break;
  100c50:	eb 02                	jmp    100c54 <kmonitor+0x5e>
            }
        }
    }
  100c52:	eb d1                	jmp    100c25 <kmonitor+0x2f>
}
  100c54:	c9                   	leave  
  100c55:	c3                   	ret    

00100c56 <mon_help>:

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
  100c56:	55                   	push   %ebp
  100c57:	89 e5                	mov    %esp,%ebp
  100c59:	83 ec 28             	sub    $0x28,%esp
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
  100c5c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100c63:	eb 3f                	jmp    100ca4 <mon_help+0x4e>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
  100c65:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c68:	89 d0                	mov    %edx,%eax
  100c6a:	01 c0                	add    %eax,%eax
  100c6c:	01 d0                	add    %edx,%eax
  100c6e:	c1 e0 02             	shl    $0x2,%eax
  100c71:	05 00 70 11 00       	add    $0x117000,%eax
  100c76:	8b 48 04             	mov    0x4(%eax),%ecx
  100c79:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c7c:	89 d0                	mov    %edx,%eax
  100c7e:	01 c0                	add    %eax,%eax
  100c80:	01 d0                	add    %edx,%eax
  100c82:	c1 e0 02             	shl    $0x2,%eax
  100c85:	05 00 70 11 00       	add    $0x117000,%eax
  100c8a:	8b 00                	mov    (%eax),%eax
  100c8c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  100c90:	89 44 24 04          	mov    %eax,0x4(%esp)
  100c94:	c7 04 24 45 65 10 00 	movl   $0x106545,(%esp)
  100c9b:	e8 ad f6 ff ff       	call   10034d <cprintf>

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
  100ca0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100ca4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100ca7:	83 f8 02             	cmp    $0x2,%eax
  100caa:	76 b9                	jbe    100c65 <mon_help+0xf>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
    }
    return 0;
  100cac:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100cb1:	c9                   	leave  
  100cb2:	c3                   	ret    

00100cb3 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
  100cb3:	55                   	push   %ebp
  100cb4:	89 e5                	mov    %esp,%ebp
  100cb6:	83 ec 08             	sub    $0x8,%esp
    print_kerninfo();
  100cb9:	e8 c3 fb ff ff       	call   100881 <print_kerninfo>
    return 0;
  100cbe:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100cc3:	c9                   	leave  
  100cc4:	c3                   	ret    

00100cc5 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
  100cc5:	55                   	push   %ebp
  100cc6:	89 e5                	mov    %esp,%ebp
  100cc8:	83 ec 08             	sub    $0x8,%esp
    print_stackframe();
  100ccb:	e8 fb fc ff ff       	call   1009cb <print_stackframe>
    return 0;
  100cd0:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100cd5:	c9                   	leave  
  100cd6:	c3                   	ret    

00100cd7 <__panic>:
/* *
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
  100cd7:	55                   	push   %ebp
  100cd8:	89 e5                	mov    %esp,%ebp
  100cda:	83 ec 28             	sub    $0x28,%esp
    if (is_panic) {
  100cdd:	a1 20 a4 11 00       	mov    0x11a420,%eax
  100ce2:	85 c0                	test   %eax,%eax
  100ce4:	74 02                	je     100ce8 <__panic+0x11>
        goto panic_dead;
  100ce6:	eb 59                	jmp    100d41 <__panic+0x6a>
    }
    is_panic = 1;
  100ce8:	c7 05 20 a4 11 00 01 	movl   $0x1,0x11a420
  100cef:	00 00 00 

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
  100cf2:	8d 45 14             	lea    0x14(%ebp),%eax
  100cf5:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
  100cf8:	8b 45 0c             	mov    0xc(%ebp),%eax
  100cfb:	89 44 24 08          	mov    %eax,0x8(%esp)
  100cff:	8b 45 08             	mov    0x8(%ebp),%eax
  100d02:	89 44 24 04          	mov    %eax,0x4(%esp)
  100d06:	c7 04 24 4e 65 10 00 	movl   $0x10654e,(%esp)
  100d0d:	e8 3b f6 ff ff       	call   10034d <cprintf>
    vcprintf(fmt, ap);
  100d12:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100d15:	89 44 24 04          	mov    %eax,0x4(%esp)
  100d19:	8b 45 10             	mov    0x10(%ebp),%eax
  100d1c:	89 04 24             	mov    %eax,(%esp)
  100d1f:	e8 f6 f5 ff ff       	call   10031a <vcprintf>
    cprintf("\n");
  100d24:	c7 04 24 6a 65 10 00 	movl   $0x10656a,(%esp)
  100d2b:	e8 1d f6 ff ff       	call   10034d <cprintf>
    
    cprintf("stack trackback:\n");
  100d30:	c7 04 24 6c 65 10 00 	movl   $0x10656c,(%esp)
  100d37:	e8 11 f6 ff ff       	call   10034d <cprintf>
    print_stackframe();
  100d3c:	e8 8a fc ff ff       	call   1009cb <print_stackframe>
    
    va_end(ap);

panic_dead:
    intr_disable();
  100d41:	e8 85 09 00 00       	call   1016cb <intr_disable>
    while (1) {
        kmonitor(NULL);
  100d46:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  100d4d:	e8 a4 fe ff ff       	call   100bf6 <kmonitor>
    }
  100d52:	eb f2                	jmp    100d46 <__panic+0x6f>

00100d54 <__warn>:
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
  100d54:	55                   	push   %ebp
  100d55:	89 e5                	mov    %esp,%ebp
  100d57:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    va_start(ap, fmt);
  100d5a:	8d 45 14             	lea    0x14(%ebp),%eax
  100d5d:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
  100d60:	8b 45 0c             	mov    0xc(%ebp),%eax
  100d63:	89 44 24 08          	mov    %eax,0x8(%esp)
  100d67:	8b 45 08             	mov    0x8(%ebp),%eax
  100d6a:	89 44 24 04          	mov    %eax,0x4(%esp)
  100d6e:	c7 04 24 7e 65 10 00 	movl   $0x10657e,(%esp)
  100d75:	e8 d3 f5 ff ff       	call   10034d <cprintf>
    vcprintf(fmt, ap);
  100d7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100d7d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100d81:	8b 45 10             	mov    0x10(%ebp),%eax
  100d84:	89 04 24             	mov    %eax,(%esp)
  100d87:	e8 8e f5 ff ff       	call   10031a <vcprintf>
    cprintf("\n");
  100d8c:	c7 04 24 6a 65 10 00 	movl   $0x10656a,(%esp)
  100d93:	e8 b5 f5 ff ff       	call   10034d <cprintf>
    va_end(ap);
}
  100d98:	c9                   	leave  
  100d99:	c3                   	ret    

00100d9a <is_kernel_panic>:

bool
is_kernel_panic(void) {
  100d9a:	55                   	push   %ebp
  100d9b:	89 e5                	mov    %esp,%ebp
    return is_panic;
  100d9d:	a1 20 a4 11 00       	mov    0x11a420,%eax
}
  100da2:	5d                   	pop    %ebp
  100da3:	c3                   	ret    

00100da4 <clock_init>:
/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void
clock_init(void) {
  100da4:	55                   	push   %ebp
  100da5:	89 e5                	mov    %esp,%ebp
  100da7:	83 ec 28             	sub    $0x28,%esp
  100daa:	66 c7 45 f6 43 00    	movw   $0x43,-0xa(%ebp)
  100db0:	c6 45 f5 34          	movb   $0x34,-0xb(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  100db4:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
  100db8:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  100dbc:	ee                   	out    %al,(%dx)
  100dbd:	66 c7 45 f2 40 00    	movw   $0x40,-0xe(%ebp)
  100dc3:	c6 45 f1 9c          	movb   $0x9c,-0xf(%ebp)
  100dc7:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
  100dcb:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  100dcf:	ee                   	out    %al,(%dx)
  100dd0:	66 c7 45 ee 40 00    	movw   $0x40,-0x12(%ebp)
  100dd6:	c6 45 ed 2e          	movb   $0x2e,-0x13(%ebp)
  100dda:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
  100dde:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  100de2:	ee                   	out    %al,(%dx)
    outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
    outb(IO_TIMER1, TIMER_DIV(100) % 256);
    outb(IO_TIMER1, TIMER_DIV(100) / 256);

    // initialize time counter 'ticks' to zero
    ticks = 0;
  100de3:	c7 05 0c af 11 00 00 	movl   $0x0,0x11af0c
  100dea:	00 00 00 

    cprintf("++ setup timer interrupts\n");
  100ded:	c7 04 24 9c 65 10 00 	movl   $0x10659c,(%esp)
  100df4:	e8 54 f5 ff ff       	call   10034d <cprintf>
    pic_enable(IRQ_TIMER);
  100df9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  100e00:	e8 24 09 00 00       	call   101729 <pic_enable>
}
  100e05:	c9                   	leave  
  100e06:	c3                   	ret    

00100e07 <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
  100e07:	55                   	push   %ebp
  100e08:	89 e5                	mov    %esp,%ebp
  100e0a:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
  100e0d:	9c                   	pushf  
  100e0e:	58                   	pop    %eax
  100e0f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
  100e12:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
  100e15:	25 00 02 00 00       	and    $0x200,%eax
  100e1a:	85 c0                	test   %eax,%eax
  100e1c:	74 0c                	je     100e2a <__intr_save+0x23>
        intr_disable();
  100e1e:	e8 a8 08 00 00       	call   1016cb <intr_disable>
        return 1;
  100e23:	b8 01 00 00 00       	mov    $0x1,%eax
  100e28:	eb 05                	jmp    100e2f <__intr_save+0x28>
    }
    return 0;
  100e2a:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100e2f:	c9                   	leave  
  100e30:	c3                   	ret    

00100e31 <__intr_restore>:

static inline void
__intr_restore(bool flag) {
  100e31:	55                   	push   %ebp
  100e32:	89 e5                	mov    %esp,%ebp
  100e34:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
  100e37:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  100e3b:	74 05                	je     100e42 <__intr_restore+0x11>
        intr_enable();
  100e3d:	e8 83 08 00 00       	call   1016c5 <intr_enable>
    }
}
  100e42:	c9                   	leave  
  100e43:	c3                   	ret    

00100e44 <delay>:
#include <memlayout.h>
#include <sync.h>

/* stupid I/O delay routine necessitated by historical PC design flaws */
static void
delay(void) {
  100e44:	55                   	push   %ebp
  100e45:	89 e5                	mov    %esp,%ebp
  100e47:	83 ec 10             	sub    $0x10,%esp
  100e4a:	66 c7 45 fe 84 00    	movw   $0x84,-0x2(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  100e50:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
  100e54:	89 c2                	mov    %eax,%edx
  100e56:	ec                   	in     (%dx),%al
  100e57:	88 45 fd             	mov    %al,-0x3(%ebp)
  100e5a:	66 c7 45 fa 84 00    	movw   $0x84,-0x6(%ebp)
  100e60:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
  100e64:	89 c2                	mov    %eax,%edx
  100e66:	ec                   	in     (%dx),%al
  100e67:	88 45 f9             	mov    %al,-0x7(%ebp)
  100e6a:	66 c7 45 f6 84 00    	movw   $0x84,-0xa(%ebp)
  100e70:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  100e74:	89 c2                	mov    %eax,%edx
  100e76:	ec                   	in     (%dx),%al
  100e77:	88 45 f5             	mov    %al,-0xb(%ebp)
  100e7a:	66 c7 45 f2 84 00    	movw   $0x84,-0xe(%ebp)
  100e80:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
  100e84:	89 c2                	mov    %eax,%edx
  100e86:	ec                   	in     (%dx),%al
  100e87:	88 45 f1             	mov    %al,-0xf(%ebp)
    inb(0x84);
    inb(0x84);
    inb(0x84);
    inb(0x84);
}
  100e8a:	c9                   	leave  
  100e8b:	c3                   	ret    

00100e8c <cga_init>:
static uint16_t addr_6845;

/* TEXT-mode CGA/VGA display output */

static void
cga_init(void) {
  100e8c:	55                   	push   %ebp
  100e8d:	89 e5                	mov    %esp,%ebp
  100e8f:	83 ec 20             	sub    $0x20,%esp
    volatile uint16_t *cp = (uint16_t *)(CGA_BUF + KERNBASE);
  100e92:	c7 45 fc 00 80 0b 00 	movl   $0xb8000,-0x4(%ebp)
    uint16_t was = *cp;
  100e99:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100e9c:	0f b7 00             	movzwl (%eax),%eax
  100e9f:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
    *cp = (uint16_t) 0xA55A;
  100ea3:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100ea6:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
    if (*cp != 0xA55A) {
  100eab:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100eae:	0f b7 00             	movzwl (%eax),%eax
  100eb1:	66 3d 5a a5          	cmp    $0xa55a,%ax
  100eb5:	74 12                	je     100ec9 <cga_init+0x3d>
        cp = (uint16_t*)(MONO_BUF + KERNBASE);
  100eb7:	c7 45 fc 00 00 0b 00 	movl   $0xb0000,-0x4(%ebp)
        addr_6845 = MONO_BASE;
  100ebe:	66 c7 05 46 a4 11 00 	movw   $0x3b4,0x11a446
  100ec5:	b4 03 
  100ec7:	eb 13                	jmp    100edc <cga_init+0x50>
    } else {
        *cp = was;
  100ec9:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100ecc:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
  100ed0:	66 89 10             	mov    %dx,(%eax)
        addr_6845 = CGA_BASE;
  100ed3:	66 c7 05 46 a4 11 00 	movw   $0x3d4,0x11a446
  100eda:	d4 03 
    }

    // Extract cursor location
    uint32_t pos;
    outb(addr_6845, 14);
  100edc:	0f b7 05 46 a4 11 00 	movzwl 0x11a446,%eax
  100ee3:	0f b7 c0             	movzwl %ax,%eax
  100ee6:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
  100eea:	c6 45 f1 0e          	movb   $0xe,-0xf(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  100eee:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
  100ef2:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  100ef6:	ee                   	out    %al,(%dx)
    pos = inb(addr_6845 + 1) << 8;
  100ef7:	0f b7 05 46 a4 11 00 	movzwl 0x11a446,%eax
  100efe:	83 c0 01             	add    $0x1,%eax
  100f01:	0f b7 c0             	movzwl %ax,%eax
  100f04:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  100f08:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
  100f0c:	89 c2                	mov    %eax,%edx
  100f0e:	ec                   	in     (%dx),%al
  100f0f:	88 45 ed             	mov    %al,-0x13(%ebp)
    return data;
  100f12:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
  100f16:	0f b6 c0             	movzbl %al,%eax
  100f19:	c1 e0 08             	shl    $0x8,%eax
  100f1c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    outb(addr_6845, 15);
  100f1f:	0f b7 05 46 a4 11 00 	movzwl 0x11a446,%eax
  100f26:	0f b7 c0             	movzwl %ax,%eax
  100f29:	66 89 45 ea          	mov    %ax,-0x16(%ebp)
  100f2d:	c6 45 e9 0f          	movb   $0xf,-0x17(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  100f31:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
  100f35:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
  100f39:	ee                   	out    %al,(%dx)
    pos |= inb(addr_6845 + 1);
  100f3a:	0f b7 05 46 a4 11 00 	movzwl 0x11a446,%eax
  100f41:	83 c0 01             	add    $0x1,%eax
  100f44:	0f b7 c0             	movzwl %ax,%eax
  100f47:	66 89 45 e6          	mov    %ax,-0x1a(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  100f4b:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax
  100f4f:	89 c2                	mov    %eax,%edx
  100f51:	ec                   	in     (%dx),%al
  100f52:	88 45 e5             	mov    %al,-0x1b(%ebp)
    return data;
  100f55:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
  100f59:	0f b6 c0             	movzbl %al,%eax
  100f5c:	09 45 f4             	or     %eax,-0xc(%ebp)

    crt_buf = (uint16_t*) cp;
  100f5f:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100f62:	a3 40 a4 11 00       	mov    %eax,0x11a440
    crt_pos = pos;
  100f67:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100f6a:	66 a3 44 a4 11 00    	mov    %ax,0x11a444
}
  100f70:	c9                   	leave  
  100f71:	c3                   	ret    

00100f72 <serial_init>:

static bool serial_exists = 0;

static void
serial_init(void) {
  100f72:	55                   	push   %ebp
  100f73:	89 e5                	mov    %esp,%ebp
  100f75:	83 ec 48             	sub    $0x48,%esp
  100f78:	66 c7 45 f6 fa 03    	movw   $0x3fa,-0xa(%ebp)
  100f7e:	c6 45 f5 00          	movb   $0x0,-0xb(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  100f82:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
  100f86:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  100f8a:	ee                   	out    %al,(%dx)
  100f8b:	66 c7 45 f2 fb 03    	movw   $0x3fb,-0xe(%ebp)
  100f91:	c6 45 f1 80          	movb   $0x80,-0xf(%ebp)
  100f95:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
  100f99:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  100f9d:	ee                   	out    %al,(%dx)
  100f9e:	66 c7 45 ee f8 03    	movw   $0x3f8,-0x12(%ebp)
  100fa4:	c6 45 ed 0c          	movb   $0xc,-0x13(%ebp)
  100fa8:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
  100fac:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  100fb0:	ee                   	out    %al,(%dx)
  100fb1:	66 c7 45 ea f9 03    	movw   $0x3f9,-0x16(%ebp)
  100fb7:	c6 45 e9 00          	movb   $0x0,-0x17(%ebp)
  100fbb:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
  100fbf:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
  100fc3:	ee                   	out    %al,(%dx)
  100fc4:	66 c7 45 e6 fb 03    	movw   $0x3fb,-0x1a(%ebp)
  100fca:	c6 45 e5 03          	movb   $0x3,-0x1b(%ebp)
  100fce:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
  100fd2:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
  100fd6:	ee                   	out    %al,(%dx)
  100fd7:	66 c7 45 e2 fc 03    	movw   $0x3fc,-0x1e(%ebp)
  100fdd:	c6 45 e1 00          	movb   $0x0,-0x1f(%ebp)
  100fe1:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
  100fe5:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
  100fe9:	ee                   	out    %al,(%dx)
  100fea:	66 c7 45 de f9 03    	movw   $0x3f9,-0x22(%ebp)
  100ff0:	c6 45 dd 01          	movb   $0x1,-0x23(%ebp)
  100ff4:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
  100ff8:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  100ffc:	ee                   	out    %al,(%dx)
  100ffd:	66 c7 45 da fd 03    	movw   $0x3fd,-0x26(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  101003:	0f b7 45 da          	movzwl -0x26(%ebp),%eax
  101007:	89 c2                	mov    %eax,%edx
  101009:	ec                   	in     (%dx),%al
  10100a:	88 45 d9             	mov    %al,-0x27(%ebp)
    return data;
  10100d:	0f b6 45 d9          	movzbl -0x27(%ebp),%eax
    // Enable rcv interrupts
    outb(COM1 + COM_IER, COM_IER_RDI);

    // Clear any preexisting overrun indications and interrupts
    // Serial port doesn't exist if COM_LSR returns 0xFF
    serial_exists = (inb(COM1 + COM_LSR) != 0xFF);
  101011:	3c ff                	cmp    $0xff,%al
  101013:	0f 95 c0             	setne  %al
  101016:	0f b6 c0             	movzbl %al,%eax
  101019:	a3 48 a4 11 00       	mov    %eax,0x11a448
  10101e:	66 c7 45 d6 fa 03    	movw   $0x3fa,-0x2a(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  101024:	0f b7 45 d6          	movzwl -0x2a(%ebp),%eax
  101028:	89 c2                	mov    %eax,%edx
  10102a:	ec                   	in     (%dx),%al
  10102b:	88 45 d5             	mov    %al,-0x2b(%ebp)
  10102e:	66 c7 45 d2 f8 03    	movw   $0x3f8,-0x2e(%ebp)
  101034:	0f b7 45 d2          	movzwl -0x2e(%ebp),%eax
  101038:	89 c2                	mov    %eax,%edx
  10103a:	ec                   	in     (%dx),%al
  10103b:	88 45 d1             	mov    %al,-0x2f(%ebp)
    (void) inb(COM1+COM_IIR);
    (void) inb(COM1+COM_RX);

    if (serial_exists) {
  10103e:	a1 48 a4 11 00       	mov    0x11a448,%eax
  101043:	85 c0                	test   %eax,%eax
  101045:	74 0c                	je     101053 <serial_init+0xe1>
        pic_enable(IRQ_COM1);
  101047:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  10104e:	e8 d6 06 00 00       	call   101729 <pic_enable>
    }
}
  101053:	c9                   	leave  
  101054:	c3                   	ret    

00101055 <lpt_putc_sub>:

static void
lpt_putc_sub(int c) {
  101055:	55                   	push   %ebp
  101056:	89 e5                	mov    %esp,%ebp
  101058:	83 ec 20             	sub    $0x20,%esp
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
  10105b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  101062:	eb 09                	jmp    10106d <lpt_putc_sub+0x18>
        delay();
  101064:	e8 db fd ff ff       	call   100e44 <delay>
}

static void
lpt_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
  101069:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  10106d:	66 c7 45 fa 79 03    	movw   $0x379,-0x6(%ebp)
  101073:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
  101077:	89 c2                	mov    %eax,%edx
  101079:	ec                   	in     (%dx),%al
  10107a:	88 45 f9             	mov    %al,-0x7(%ebp)
    return data;
  10107d:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
  101081:	84 c0                	test   %al,%al
  101083:	78 09                	js     10108e <lpt_putc_sub+0x39>
  101085:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
  10108c:	7e d6                	jle    101064 <lpt_putc_sub+0xf>
        delay();
    }
    outb(LPTPORT + 0, c);
  10108e:	8b 45 08             	mov    0x8(%ebp),%eax
  101091:	0f b6 c0             	movzbl %al,%eax
  101094:	66 c7 45 f6 78 03    	movw   $0x378,-0xa(%ebp)
  10109a:	88 45 f5             	mov    %al,-0xb(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  10109d:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
  1010a1:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  1010a5:	ee                   	out    %al,(%dx)
  1010a6:	66 c7 45 f2 7a 03    	movw   $0x37a,-0xe(%ebp)
  1010ac:	c6 45 f1 0d          	movb   $0xd,-0xf(%ebp)
  1010b0:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
  1010b4:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  1010b8:	ee                   	out    %al,(%dx)
  1010b9:	66 c7 45 ee 7a 03    	movw   $0x37a,-0x12(%ebp)
  1010bf:	c6 45 ed 08          	movb   $0x8,-0x13(%ebp)
  1010c3:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
  1010c7:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  1010cb:	ee                   	out    %al,(%dx)
    outb(LPTPORT + 2, 0x08 | 0x04 | 0x01);
    outb(LPTPORT + 2, 0x08);
}
  1010cc:	c9                   	leave  
  1010cd:	c3                   	ret    

001010ce <lpt_putc>:

/* lpt_putc - copy console output to parallel port */
static void
lpt_putc(int c) {
  1010ce:	55                   	push   %ebp
  1010cf:	89 e5                	mov    %esp,%ebp
  1010d1:	83 ec 04             	sub    $0x4,%esp
    if (c != '\b') {
  1010d4:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
  1010d8:	74 0d                	je     1010e7 <lpt_putc+0x19>
        lpt_putc_sub(c);
  1010da:	8b 45 08             	mov    0x8(%ebp),%eax
  1010dd:	89 04 24             	mov    %eax,(%esp)
  1010e0:	e8 70 ff ff ff       	call   101055 <lpt_putc_sub>
  1010e5:	eb 24                	jmp    10110b <lpt_putc+0x3d>
    }
    else {
        lpt_putc_sub('\b');
  1010e7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  1010ee:	e8 62 ff ff ff       	call   101055 <lpt_putc_sub>
        lpt_putc_sub(' ');
  1010f3:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1010fa:	e8 56 ff ff ff       	call   101055 <lpt_putc_sub>
        lpt_putc_sub('\b');
  1010ff:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  101106:	e8 4a ff ff ff       	call   101055 <lpt_putc_sub>
    }
}
  10110b:	c9                   	leave  
  10110c:	c3                   	ret    

0010110d <cga_putc>:

/* cga_putc - print character to console */
static void
cga_putc(int c) {
  10110d:	55                   	push   %ebp
  10110e:	89 e5                	mov    %esp,%ebp
  101110:	53                   	push   %ebx
  101111:	83 ec 34             	sub    $0x34,%esp
    // set black on white
    if (!(c & ~0xFF)) {
  101114:	8b 45 08             	mov    0x8(%ebp),%eax
  101117:	b0 00                	mov    $0x0,%al
  101119:	85 c0                	test   %eax,%eax
  10111b:	75 07                	jne    101124 <cga_putc+0x17>
        c |= 0x0700;
  10111d:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)
    }

    switch (c & 0xff) {
  101124:	8b 45 08             	mov    0x8(%ebp),%eax
  101127:	0f b6 c0             	movzbl %al,%eax
  10112a:	83 f8 0a             	cmp    $0xa,%eax
  10112d:	74 4c                	je     10117b <cga_putc+0x6e>
  10112f:	83 f8 0d             	cmp    $0xd,%eax
  101132:	74 57                	je     10118b <cga_putc+0x7e>
  101134:	83 f8 08             	cmp    $0x8,%eax
  101137:	0f 85 88 00 00 00    	jne    1011c5 <cga_putc+0xb8>
    case '\b':
        if (crt_pos > 0) {
  10113d:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  101144:	66 85 c0             	test   %ax,%ax
  101147:	74 30                	je     101179 <cga_putc+0x6c>
            crt_pos --;
  101149:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  101150:	83 e8 01             	sub    $0x1,%eax
  101153:	66 a3 44 a4 11 00    	mov    %ax,0x11a444
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
  101159:	a1 40 a4 11 00       	mov    0x11a440,%eax
  10115e:	0f b7 15 44 a4 11 00 	movzwl 0x11a444,%edx
  101165:	0f b7 d2             	movzwl %dx,%edx
  101168:	01 d2                	add    %edx,%edx
  10116a:	01 c2                	add    %eax,%edx
  10116c:	8b 45 08             	mov    0x8(%ebp),%eax
  10116f:	b0 00                	mov    $0x0,%al
  101171:	83 c8 20             	or     $0x20,%eax
  101174:	66 89 02             	mov    %ax,(%edx)
        }
        break;
  101177:	eb 72                	jmp    1011eb <cga_putc+0xde>
  101179:	eb 70                	jmp    1011eb <cga_putc+0xde>
    case '\n':
        crt_pos += CRT_COLS;
  10117b:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  101182:	83 c0 50             	add    $0x50,%eax
  101185:	66 a3 44 a4 11 00    	mov    %ax,0x11a444
    case '\r':
        crt_pos -= (crt_pos % CRT_COLS);
  10118b:	0f b7 1d 44 a4 11 00 	movzwl 0x11a444,%ebx
  101192:	0f b7 0d 44 a4 11 00 	movzwl 0x11a444,%ecx
  101199:	0f b7 c1             	movzwl %cx,%eax
  10119c:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  1011a2:	c1 e8 10             	shr    $0x10,%eax
  1011a5:	89 c2                	mov    %eax,%edx
  1011a7:	66 c1 ea 06          	shr    $0x6,%dx
  1011ab:	89 d0                	mov    %edx,%eax
  1011ad:	c1 e0 02             	shl    $0x2,%eax
  1011b0:	01 d0                	add    %edx,%eax
  1011b2:	c1 e0 04             	shl    $0x4,%eax
  1011b5:	29 c1                	sub    %eax,%ecx
  1011b7:	89 ca                	mov    %ecx,%edx
  1011b9:	89 d8                	mov    %ebx,%eax
  1011bb:	29 d0                	sub    %edx,%eax
  1011bd:	66 a3 44 a4 11 00    	mov    %ax,0x11a444
        break;
  1011c3:	eb 26                	jmp    1011eb <cga_putc+0xde>
    default:
        crt_buf[crt_pos ++] = c;     // write the character
  1011c5:	8b 0d 40 a4 11 00    	mov    0x11a440,%ecx
  1011cb:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  1011d2:	8d 50 01             	lea    0x1(%eax),%edx
  1011d5:	66 89 15 44 a4 11 00 	mov    %dx,0x11a444
  1011dc:	0f b7 c0             	movzwl %ax,%eax
  1011df:	01 c0                	add    %eax,%eax
  1011e1:	8d 14 01             	lea    (%ecx,%eax,1),%edx
  1011e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1011e7:	66 89 02             	mov    %ax,(%edx)
        break;
  1011ea:	90                   	nop
    }

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
  1011eb:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  1011f2:	66 3d cf 07          	cmp    $0x7cf,%ax
  1011f6:	76 5b                	jbe    101253 <cga_putc+0x146>
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
  1011f8:	a1 40 a4 11 00       	mov    0x11a440,%eax
  1011fd:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  101203:	a1 40 a4 11 00       	mov    0x11a440,%eax
  101208:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  10120f:	00 
  101210:	89 54 24 04          	mov    %edx,0x4(%esp)
  101214:	89 04 24             	mov    %eax,(%esp)
  101217:	e8 0a 4f 00 00       	call   106126 <memmove>
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
  10121c:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
  101223:	eb 15                	jmp    10123a <cga_putc+0x12d>
            crt_buf[i] = 0x0700 | ' ';
  101225:	a1 40 a4 11 00       	mov    0x11a440,%eax
  10122a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10122d:	01 d2                	add    %edx,%edx
  10122f:	01 d0                	add    %edx,%eax
  101231:	66 c7 00 20 07       	movw   $0x720,(%eax)

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
  101236:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10123a:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
  101241:	7e e2                	jle    101225 <cga_putc+0x118>
            crt_buf[i] = 0x0700 | ' ';
        }
        crt_pos -= CRT_COLS;
  101243:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  10124a:	83 e8 50             	sub    $0x50,%eax
  10124d:	66 a3 44 a4 11 00    	mov    %ax,0x11a444
    }

    // move that little blinky thing
    outb(addr_6845, 14);
  101253:	0f b7 05 46 a4 11 00 	movzwl 0x11a446,%eax
  10125a:	0f b7 c0             	movzwl %ax,%eax
  10125d:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
  101261:	c6 45 f1 0e          	movb   $0xe,-0xf(%ebp)
  101265:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
  101269:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  10126d:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos >> 8);
  10126e:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  101275:	66 c1 e8 08          	shr    $0x8,%ax
  101279:	0f b6 c0             	movzbl %al,%eax
  10127c:	0f b7 15 46 a4 11 00 	movzwl 0x11a446,%edx
  101283:	83 c2 01             	add    $0x1,%edx
  101286:	0f b7 d2             	movzwl %dx,%edx
  101289:	66 89 55 ee          	mov    %dx,-0x12(%ebp)
  10128d:	88 45 ed             	mov    %al,-0x13(%ebp)
  101290:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
  101294:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  101298:	ee                   	out    %al,(%dx)
    outb(addr_6845, 15);
  101299:	0f b7 05 46 a4 11 00 	movzwl 0x11a446,%eax
  1012a0:	0f b7 c0             	movzwl %ax,%eax
  1012a3:	66 89 45 ea          	mov    %ax,-0x16(%ebp)
  1012a7:	c6 45 e9 0f          	movb   $0xf,-0x17(%ebp)
  1012ab:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
  1012af:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
  1012b3:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos);
  1012b4:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  1012bb:	0f b6 c0             	movzbl %al,%eax
  1012be:	0f b7 15 46 a4 11 00 	movzwl 0x11a446,%edx
  1012c5:	83 c2 01             	add    $0x1,%edx
  1012c8:	0f b7 d2             	movzwl %dx,%edx
  1012cb:	66 89 55 e6          	mov    %dx,-0x1a(%ebp)
  1012cf:	88 45 e5             	mov    %al,-0x1b(%ebp)
  1012d2:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
  1012d6:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
  1012da:	ee                   	out    %al,(%dx)
}
  1012db:	83 c4 34             	add    $0x34,%esp
  1012de:	5b                   	pop    %ebx
  1012df:	5d                   	pop    %ebp
  1012e0:	c3                   	ret    

001012e1 <serial_putc_sub>:

static void
serial_putc_sub(int c) {
  1012e1:	55                   	push   %ebp
  1012e2:	89 e5                	mov    %esp,%ebp
  1012e4:	83 ec 10             	sub    $0x10,%esp
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
  1012e7:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1012ee:	eb 09                	jmp    1012f9 <serial_putc_sub+0x18>
        delay();
  1012f0:	e8 4f fb ff ff       	call   100e44 <delay>
}

static void
serial_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
  1012f5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  1012f9:	66 c7 45 fa fd 03    	movw   $0x3fd,-0x6(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  1012ff:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
  101303:	89 c2                	mov    %eax,%edx
  101305:	ec                   	in     (%dx),%al
  101306:	88 45 f9             	mov    %al,-0x7(%ebp)
    return data;
  101309:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
  10130d:	0f b6 c0             	movzbl %al,%eax
  101310:	83 e0 20             	and    $0x20,%eax
  101313:	85 c0                	test   %eax,%eax
  101315:	75 09                	jne    101320 <serial_putc_sub+0x3f>
  101317:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
  10131e:	7e d0                	jle    1012f0 <serial_putc_sub+0xf>
        delay();
    }
    outb(COM1 + COM_TX, c);
  101320:	8b 45 08             	mov    0x8(%ebp),%eax
  101323:	0f b6 c0             	movzbl %al,%eax
  101326:	66 c7 45 f6 f8 03    	movw   $0x3f8,-0xa(%ebp)
  10132c:	88 45 f5             	mov    %al,-0xb(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  10132f:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
  101333:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  101337:	ee                   	out    %al,(%dx)
}
  101338:	c9                   	leave  
  101339:	c3                   	ret    

0010133a <serial_putc>:

/* serial_putc - print character to serial port */
static void
serial_putc(int c) {
  10133a:	55                   	push   %ebp
  10133b:	89 e5                	mov    %esp,%ebp
  10133d:	83 ec 04             	sub    $0x4,%esp
    if (c != '\b') {
  101340:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
  101344:	74 0d                	je     101353 <serial_putc+0x19>
        serial_putc_sub(c);
  101346:	8b 45 08             	mov    0x8(%ebp),%eax
  101349:	89 04 24             	mov    %eax,(%esp)
  10134c:	e8 90 ff ff ff       	call   1012e1 <serial_putc_sub>
  101351:	eb 24                	jmp    101377 <serial_putc+0x3d>
    }
    else {
        serial_putc_sub('\b');
  101353:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  10135a:	e8 82 ff ff ff       	call   1012e1 <serial_putc_sub>
        serial_putc_sub(' ');
  10135f:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101366:	e8 76 ff ff ff       	call   1012e1 <serial_putc_sub>
        serial_putc_sub('\b');
  10136b:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  101372:	e8 6a ff ff ff       	call   1012e1 <serial_putc_sub>
    }
}
  101377:	c9                   	leave  
  101378:	c3                   	ret    

00101379 <cons_intr>:
/* *
 * cons_intr - called by device interrupt routines to feed input
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
  101379:	55                   	push   %ebp
  10137a:	89 e5                	mov    %esp,%ebp
  10137c:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = (*proc)()) != -1) {
  10137f:	eb 33                	jmp    1013b4 <cons_intr+0x3b>
        if (c != 0) {
  101381:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101385:	74 2d                	je     1013b4 <cons_intr+0x3b>
            cons.buf[cons.wpos ++] = c;
  101387:	a1 64 a6 11 00       	mov    0x11a664,%eax
  10138c:	8d 50 01             	lea    0x1(%eax),%edx
  10138f:	89 15 64 a6 11 00    	mov    %edx,0x11a664
  101395:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101398:	88 90 60 a4 11 00    	mov    %dl,0x11a460(%eax)
            if (cons.wpos == CONSBUFSIZE) {
  10139e:	a1 64 a6 11 00       	mov    0x11a664,%eax
  1013a3:	3d 00 02 00 00       	cmp    $0x200,%eax
  1013a8:	75 0a                	jne    1013b4 <cons_intr+0x3b>
                cons.wpos = 0;
  1013aa:	c7 05 64 a6 11 00 00 	movl   $0x0,0x11a664
  1013b1:	00 00 00 
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
    int c;
    while ((c = (*proc)()) != -1) {
  1013b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1013b7:	ff d0                	call   *%eax
  1013b9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1013bc:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  1013c0:	75 bf                	jne    101381 <cons_intr+0x8>
            if (cons.wpos == CONSBUFSIZE) {
                cons.wpos = 0;
            }
        }
    }
}
  1013c2:	c9                   	leave  
  1013c3:	c3                   	ret    

001013c4 <serial_proc_data>:

/* serial_proc_data - get data from serial port */
static int
serial_proc_data(void) {
  1013c4:	55                   	push   %ebp
  1013c5:	89 e5                	mov    %esp,%ebp
  1013c7:	83 ec 10             	sub    $0x10,%esp
  1013ca:	66 c7 45 fa fd 03    	movw   $0x3fd,-0x6(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  1013d0:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
  1013d4:	89 c2                	mov    %eax,%edx
  1013d6:	ec                   	in     (%dx),%al
  1013d7:	88 45 f9             	mov    %al,-0x7(%ebp)
    return data;
  1013da:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
    if (!(inb(COM1 + COM_LSR) & COM_LSR_DATA)) {
  1013de:	0f b6 c0             	movzbl %al,%eax
  1013e1:	83 e0 01             	and    $0x1,%eax
  1013e4:	85 c0                	test   %eax,%eax
  1013e6:	75 07                	jne    1013ef <serial_proc_data+0x2b>
        return -1;
  1013e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1013ed:	eb 2a                	jmp    101419 <serial_proc_data+0x55>
  1013ef:	66 c7 45 f6 f8 03    	movw   $0x3f8,-0xa(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  1013f5:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  1013f9:	89 c2                	mov    %eax,%edx
  1013fb:	ec                   	in     (%dx),%al
  1013fc:	88 45 f5             	mov    %al,-0xb(%ebp)
    return data;
  1013ff:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
    }
    int c = inb(COM1 + COM_RX);
  101403:	0f b6 c0             	movzbl %al,%eax
  101406:	89 45 fc             	mov    %eax,-0x4(%ebp)
    if (c == 127) {
  101409:	83 7d fc 7f          	cmpl   $0x7f,-0x4(%ebp)
  10140d:	75 07                	jne    101416 <serial_proc_data+0x52>
        c = '\b';
  10140f:	c7 45 fc 08 00 00 00 	movl   $0x8,-0x4(%ebp)
    }
    return c;
  101416:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  101419:	c9                   	leave  
  10141a:	c3                   	ret    

0010141b <serial_intr>:

/* serial_intr - try to feed input characters from serial port */
void
serial_intr(void) {
  10141b:	55                   	push   %ebp
  10141c:	89 e5                	mov    %esp,%ebp
  10141e:	83 ec 18             	sub    $0x18,%esp
    if (serial_exists) {
  101421:	a1 48 a4 11 00       	mov    0x11a448,%eax
  101426:	85 c0                	test   %eax,%eax
  101428:	74 0c                	je     101436 <serial_intr+0x1b>
        cons_intr(serial_proc_data);
  10142a:	c7 04 24 c4 13 10 00 	movl   $0x1013c4,(%esp)
  101431:	e8 43 ff ff ff       	call   101379 <cons_intr>
    }
}
  101436:	c9                   	leave  
  101437:	c3                   	ret    

00101438 <kbd_proc_data>:
 *
 * The kbd_proc_data() function gets data from the keyboard.
 * If we finish a character, return it, else 0. And return -1 if no data.
 * */
static int
kbd_proc_data(void) {
  101438:	55                   	push   %ebp
  101439:	89 e5                	mov    %esp,%ebp
  10143b:	83 ec 38             	sub    $0x38,%esp
  10143e:	66 c7 45 f0 64 00    	movw   $0x64,-0x10(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  101444:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
  101448:	89 c2                	mov    %eax,%edx
  10144a:	ec                   	in     (%dx),%al
  10144b:	88 45 ef             	mov    %al,-0x11(%ebp)
    return data;
  10144e:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
    int c;
    uint8_t data;
    static uint32_t shift;

    if ((inb(KBSTATP) & KBS_DIB) == 0) {
  101452:	0f b6 c0             	movzbl %al,%eax
  101455:	83 e0 01             	and    $0x1,%eax
  101458:	85 c0                	test   %eax,%eax
  10145a:	75 0a                	jne    101466 <kbd_proc_data+0x2e>
        return -1;
  10145c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101461:	e9 59 01 00 00       	jmp    1015bf <kbd_proc_data+0x187>
  101466:	66 c7 45 ec 60 00    	movw   $0x60,-0x14(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  10146c:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  101470:	89 c2                	mov    %eax,%edx
  101472:	ec                   	in     (%dx),%al
  101473:	88 45 eb             	mov    %al,-0x15(%ebp)
    return data;
  101476:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
    }

    data = inb(KBDATAP);
  10147a:	88 45 f3             	mov    %al,-0xd(%ebp)

    if (data == 0xE0) {
  10147d:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
  101481:	75 17                	jne    10149a <kbd_proc_data+0x62>
        // E0 escape character
        shift |= E0ESC;
  101483:	a1 68 a6 11 00       	mov    0x11a668,%eax
  101488:	83 c8 40             	or     $0x40,%eax
  10148b:	a3 68 a6 11 00       	mov    %eax,0x11a668
        return 0;
  101490:	b8 00 00 00 00       	mov    $0x0,%eax
  101495:	e9 25 01 00 00       	jmp    1015bf <kbd_proc_data+0x187>
    } else if (data & 0x80) {
  10149a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10149e:	84 c0                	test   %al,%al
  1014a0:	79 47                	jns    1014e9 <kbd_proc_data+0xb1>
        // Key released
        data = (shift & E0ESC ? data : data & 0x7F);
  1014a2:	a1 68 a6 11 00       	mov    0x11a668,%eax
  1014a7:	83 e0 40             	and    $0x40,%eax
  1014aa:	85 c0                	test   %eax,%eax
  1014ac:	75 09                	jne    1014b7 <kbd_proc_data+0x7f>
  1014ae:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1014b2:	83 e0 7f             	and    $0x7f,%eax
  1014b5:	eb 04                	jmp    1014bb <kbd_proc_data+0x83>
  1014b7:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1014bb:	88 45 f3             	mov    %al,-0xd(%ebp)
        shift &= ~(shiftcode[data] | E0ESC);
  1014be:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1014c2:	0f b6 80 40 70 11 00 	movzbl 0x117040(%eax),%eax
  1014c9:	83 c8 40             	or     $0x40,%eax
  1014cc:	0f b6 c0             	movzbl %al,%eax
  1014cf:	f7 d0                	not    %eax
  1014d1:	89 c2                	mov    %eax,%edx
  1014d3:	a1 68 a6 11 00       	mov    0x11a668,%eax
  1014d8:	21 d0                	and    %edx,%eax
  1014da:	a3 68 a6 11 00       	mov    %eax,0x11a668
        return 0;
  1014df:	b8 00 00 00 00       	mov    $0x0,%eax
  1014e4:	e9 d6 00 00 00       	jmp    1015bf <kbd_proc_data+0x187>
    } else if (shift & E0ESC) {
  1014e9:	a1 68 a6 11 00       	mov    0x11a668,%eax
  1014ee:	83 e0 40             	and    $0x40,%eax
  1014f1:	85 c0                	test   %eax,%eax
  1014f3:	74 11                	je     101506 <kbd_proc_data+0xce>
        // Last character was an E0 escape; or with 0x80
        data |= 0x80;
  1014f5:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
        shift &= ~E0ESC;
  1014f9:	a1 68 a6 11 00       	mov    0x11a668,%eax
  1014fe:	83 e0 bf             	and    $0xffffffbf,%eax
  101501:	a3 68 a6 11 00       	mov    %eax,0x11a668
    }

    shift |= shiftcode[data];
  101506:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10150a:	0f b6 80 40 70 11 00 	movzbl 0x117040(%eax),%eax
  101511:	0f b6 d0             	movzbl %al,%edx
  101514:	a1 68 a6 11 00       	mov    0x11a668,%eax
  101519:	09 d0                	or     %edx,%eax
  10151b:	a3 68 a6 11 00       	mov    %eax,0x11a668
    shift ^= togglecode[data];
  101520:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101524:	0f b6 80 40 71 11 00 	movzbl 0x117140(%eax),%eax
  10152b:	0f b6 d0             	movzbl %al,%edx
  10152e:	a1 68 a6 11 00       	mov    0x11a668,%eax
  101533:	31 d0                	xor    %edx,%eax
  101535:	a3 68 a6 11 00       	mov    %eax,0x11a668

    c = charcode[shift & (CTL | SHIFT)][data];
  10153a:	a1 68 a6 11 00       	mov    0x11a668,%eax
  10153f:	83 e0 03             	and    $0x3,%eax
  101542:	8b 14 85 40 75 11 00 	mov    0x117540(,%eax,4),%edx
  101549:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10154d:	01 d0                	add    %edx,%eax
  10154f:	0f b6 00             	movzbl (%eax),%eax
  101552:	0f b6 c0             	movzbl %al,%eax
  101555:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (shift & CAPSLOCK) {
  101558:	a1 68 a6 11 00       	mov    0x11a668,%eax
  10155d:	83 e0 08             	and    $0x8,%eax
  101560:	85 c0                	test   %eax,%eax
  101562:	74 22                	je     101586 <kbd_proc_data+0x14e>
        if ('a' <= c && c <= 'z')
  101564:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
  101568:	7e 0c                	jle    101576 <kbd_proc_data+0x13e>
  10156a:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
  10156e:	7f 06                	jg     101576 <kbd_proc_data+0x13e>
            c += 'A' - 'a';
  101570:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
  101574:	eb 10                	jmp    101586 <kbd_proc_data+0x14e>
        else if ('A' <= c && c <= 'Z')
  101576:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
  10157a:	7e 0a                	jle    101586 <kbd_proc_data+0x14e>
  10157c:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
  101580:	7f 04                	jg     101586 <kbd_proc_data+0x14e>
            c += 'a' - 'A';
  101582:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
    }

    // Process special keys
    // Ctrl-Alt-Del: reboot
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  101586:	a1 68 a6 11 00       	mov    0x11a668,%eax
  10158b:	f7 d0                	not    %eax
  10158d:	83 e0 06             	and    $0x6,%eax
  101590:	85 c0                	test   %eax,%eax
  101592:	75 28                	jne    1015bc <kbd_proc_data+0x184>
  101594:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
  10159b:	75 1f                	jne    1015bc <kbd_proc_data+0x184>
        cprintf("Rebooting!\n");
  10159d:	c7 04 24 b7 65 10 00 	movl   $0x1065b7,(%esp)
  1015a4:	e8 a4 ed ff ff       	call   10034d <cprintf>
  1015a9:	66 c7 45 e8 92 00    	movw   $0x92,-0x18(%ebp)
  1015af:	c6 45 e7 03          	movb   $0x3,-0x19(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  1015b3:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  1015b7:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
  1015bb:	ee                   	out    %al,(%dx)
        outb(0x92, 0x3); // courtesy of Chris Frost
    }
    return c;
  1015bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1015bf:	c9                   	leave  
  1015c0:	c3                   	ret    

001015c1 <kbd_intr>:

/* kbd_intr - try to feed input characters from keyboard */
static void
kbd_intr(void) {
  1015c1:	55                   	push   %ebp
  1015c2:	89 e5                	mov    %esp,%ebp
  1015c4:	83 ec 18             	sub    $0x18,%esp
    cons_intr(kbd_proc_data);
  1015c7:	c7 04 24 38 14 10 00 	movl   $0x101438,(%esp)
  1015ce:	e8 a6 fd ff ff       	call   101379 <cons_intr>
}
  1015d3:	c9                   	leave  
  1015d4:	c3                   	ret    

001015d5 <kbd_init>:

static void
kbd_init(void) {
  1015d5:	55                   	push   %ebp
  1015d6:	89 e5                	mov    %esp,%ebp
  1015d8:	83 ec 18             	sub    $0x18,%esp
    // drain the kbd buffer
    kbd_intr();
  1015db:	e8 e1 ff ff ff       	call   1015c1 <kbd_intr>
    pic_enable(IRQ_KBD);
  1015e0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1015e7:	e8 3d 01 00 00       	call   101729 <pic_enable>
}
  1015ec:	c9                   	leave  
  1015ed:	c3                   	ret    

001015ee <cons_init>:

/* cons_init - initializes the console devices */
void
cons_init(void) {
  1015ee:	55                   	push   %ebp
  1015ef:	89 e5                	mov    %esp,%ebp
  1015f1:	83 ec 18             	sub    $0x18,%esp
    cga_init();
  1015f4:	e8 93 f8 ff ff       	call   100e8c <cga_init>
    serial_init();
  1015f9:	e8 74 f9 ff ff       	call   100f72 <serial_init>
    kbd_init();
  1015fe:	e8 d2 ff ff ff       	call   1015d5 <kbd_init>
    if (!serial_exists) {
  101603:	a1 48 a4 11 00       	mov    0x11a448,%eax
  101608:	85 c0                	test   %eax,%eax
  10160a:	75 0c                	jne    101618 <cons_init+0x2a>
        cprintf("serial port does not exist!!\n");
  10160c:	c7 04 24 c3 65 10 00 	movl   $0x1065c3,(%esp)
  101613:	e8 35 ed ff ff       	call   10034d <cprintf>
    }
}
  101618:	c9                   	leave  
  101619:	c3                   	ret    

0010161a <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void
cons_putc(int c) {
  10161a:	55                   	push   %ebp
  10161b:	89 e5                	mov    %esp,%ebp
  10161d:	83 ec 28             	sub    $0x28,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
  101620:	e8 e2 f7 ff ff       	call   100e07 <__intr_save>
  101625:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        lpt_putc(c);
  101628:	8b 45 08             	mov    0x8(%ebp),%eax
  10162b:	89 04 24             	mov    %eax,(%esp)
  10162e:	e8 9b fa ff ff       	call   1010ce <lpt_putc>
        cga_putc(c);
  101633:	8b 45 08             	mov    0x8(%ebp),%eax
  101636:	89 04 24             	mov    %eax,(%esp)
  101639:	e8 cf fa ff ff       	call   10110d <cga_putc>
        serial_putc(c);
  10163e:	8b 45 08             	mov    0x8(%ebp),%eax
  101641:	89 04 24             	mov    %eax,(%esp)
  101644:	e8 f1 fc ff ff       	call   10133a <serial_putc>
    }
    local_intr_restore(intr_flag);
  101649:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10164c:	89 04 24             	mov    %eax,(%esp)
  10164f:	e8 dd f7 ff ff       	call   100e31 <__intr_restore>
}
  101654:	c9                   	leave  
  101655:	c3                   	ret    

00101656 <cons_getc>:
/* *
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int
cons_getc(void) {
  101656:	55                   	push   %ebp
  101657:	89 e5                	mov    %esp,%ebp
  101659:	83 ec 28             	sub    $0x28,%esp
    int c = 0;
  10165c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
  101663:	e8 9f f7 ff ff       	call   100e07 <__intr_save>
  101668:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        // poll for any pending input characters,
        // so that this function works even when interrupts are disabled
        // (e.g., when called from the kernel monitor).
        serial_intr();
  10166b:	e8 ab fd ff ff       	call   10141b <serial_intr>
        kbd_intr();
  101670:	e8 4c ff ff ff       	call   1015c1 <kbd_intr>

        // grab the next character from the input buffer.
        if (cons.rpos != cons.wpos) {
  101675:	8b 15 60 a6 11 00    	mov    0x11a660,%edx
  10167b:	a1 64 a6 11 00       	mov    0x11a664,%eax
  101680:	39 c2                	cmp    %eax,%edx
  101682:	74 31                	je     1016b5 <cons_getc+0x5f>
            c = cons.buf[cons.rpos ++];
  101684:	a1 60 a6 11 00       	mov    0x11a660,%eax
  101689:	8d 50 01             	lea    0x1(%eax),%edx
  10168c:	89 15 60 a6 11 00    	mov    %edx,0x11a660
  101692:	0f b6 80 60 a4 11 00 	movzbl 0x11a460(%eax),%eax
  101699:	0f b6 c0             	movzbl %al,%eax
  10169c:	89 45 f4             	mov    %eax,-0xc(%ebp)
            if (cons.rpos == CONSBUFSIZE) {
  10169f:	a1 60 a6 11 00       	mov    0x11a660,%eax
  1016a4:	3d 00 02 00 00       	cmp    $0x200,%eax
  1016a9:	75 0a                	jne    1016b5 <cons_getc+0x5f>
                cons.rpos = 0;
  1016ab:	c7 05 60 a6 11 00 00 	movl   $0x0,0x11a660
  1016b2:	00 00 00 
            }
        }
    }
    local_intr_restore(intr_flag);
  1016b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1016b8:	89 04 24             	mov    %eax,(%esp)
  1016bb:	e8 71 f7 ff ff       	call   100e31 <__intr_restore>
    return c;
  1016c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1016c3:	c9                   	leave  
  1016c4:	c3                   	ret    

001016c5 <intr_enable>:
#include <x86.h>
#include <intr.h>

/* intr_enable - enable irq interrupt */
void
intr_enable(void) {
  1016c5:	55                   	push   %ebp
  1016c6:	89 e5                	mov    %esp,%ebp
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
}

static inline void
sti(void) {
    asm volatile ("sti");
  1016c8:	fb                   	sti    
    sti();
}
  1016c9:	5d                   	pop    %ebp
  1016ca:	c3                   	ret    

001016cb <intr_disable>:

/* intr_disable - disable irq interrupt */
void
intr_disable(void) {
  1016cb:	55                   	push   %ebp
  1016cc:	89 e5                	mov    %esp,%ebp
}

static inline void
cli(void) {
    asm volatile ("cli" ::: "memory");
  1016ce:	fa                   	cli    
    cli();
}
  1016cf:	5d                   	pop    %ebp
  1016d0:	c3                   	ret    

001016d1 <pic_setmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static uint16_t irq_mask = 0xFFFF & ~(1 << IRQ_SLAVE);
static bool did_init = 0;

static void
pic_setmask(uint16_t mask) {
  1016d1:	55                   	push   %ebp
  1016d2:	89 e5                	mov    %esp,%ebp
  1016d4:	83 ec 14             	sub    $0x14,%esp
  1016d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1016da:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
    irq_mask = mask;
  1016de:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1016e2:	66 a3 50 75 11 00    	mov    %ax,0x117550
    if (did_init) {
  1016e8:	a1 6c a6 11 00       	mov    0x11a66c,%eax
  1016ed:	85 c0                	test   %eax,%eax
  1016ef:	74 36                	je     101727 <pic_setmask+0x56>
        outb(IO_PIC1 + 1, mask);
  1016f1:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1016f5:	0f b6 c0             	movzbl %al,%eax
  1016f8:	66 c7 45 fe 21 00    	movw   $0x21,-0x2(%ebp)
  1016fe:	88 45 fd             	mov    %al,-0x3(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  101701:	0f b6 45 fd          	movzbl -0x3(%ebp),%eax
  101705:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
  101709:	ee                   	out    %al,(%dx)
        outb(IO_PIC2 + 1, mask >> 8);
  10170a:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  10170e:	66 c1 e8 08          	shr    $0x8,%ax
  101712:	0f b6 c0             	movzbl %al,%eax
  101715:	66 c7 45 fa a1 00    	movw   $0xa1,-0x6(%ebp)
  10171b:	88 45 f9             	mov    %al,-0x7(%ebp)
  10171e:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
  101722:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
  101726:	ee                   	out    %al,(%dx)
    }
}
  101727:	c9                   	leave  
  101728:	c3                   	ret    

00101729 <pic_enable>:

void
pic_enable(unsigned int irq) {
  101729:	55                   	push   %ebp
  10172a:	89 e5                	mov    %esp,%ebp
  10172c:	83 ec 04             	sub    $0x4,%esp
    pic_setmask(irq_mask & ~(1 << irq));
  10172f:	8b 45 08             	mov    0x8(%ebp),%eax
  101732:	ba 01 00 00 00       	mov    $0x1,%edx
  101737:	89 c1                	mov    %eax,%ecx
  101739:	d3 e2                	shl    %cl,%edx
  10173b:	89 d0                	mov    %edx,%eax
  10173d:	f7 d0                	not    %eax
  10173f:	89 c2                	mov    %eax,%edx
  101741:	0f b7 05 50 75 11 00 	movzwl 0x117550,%eax
  101748:	21 d0                	and    %edx,%eax
  10174a:	0f b7 c0             	movzwl %ax,%eax
  10174d:	89 04 24             	mov    %eax,(%esp)
  101750:	e8 7c ff ff ff       	call   1016d1 <pic_setmask>
}
  101755:	c9                   	leave  
  101756:	c3                   	ret    

00101757 <pic_init>:

/* pic_init - initialize the 8259A interrupt controllers */
void
pic_init(void) {
  101757:	55                   	push   %ebp
  101758:	89 e5                	mov    %esp,%ebp
  10175a:	83 ec 44             	sub    $0x44,%esp
    did_init = 1;
  10175d:	c7 05 6c a6 11 00 01 	movl   $0x1,0x11a66c
  101764:	00 00 00 
  101767:	66 c7 45 fe 21 00    	movw   $0x21,-0x2(%ebp)
  10176d:	c6 45 fd ff          	movb   $0xff,-0x3(%ebp)
  101771:	0f b6 45 fd          	movzbl -0x3(%ebp),%eax
  101775:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
  101779:	ee                   	out    %al,(%dx)
  10177a:	66 c7 45 fa a1 00    	movw   $0xa1,-0x6(%ebp)
  101780:	c6 45 f9 ff          	movb   $0xff,-0x7(%ebp)
  101784:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
  101788:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
  10178c:	ee                   	out    %al,(%dx)
  10178d:	66 c7 45 f6 20 00    	movw   $0x20,-0xa(%ebp)
  101793:	c6 45 f5 11          	movb   $0x11,-0xb(%ebp)
  101797:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
  10179b:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  10179f:	ee                   	out    %al,(%dx)
  1017a0:	66 c7 45 f2 21 00    	movw   $0x21,-0xe(%ebp)
  1017a6:	c6 45 f1 20          	movb   $0x20,-0xf(%ebp)
  1017aa:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
  1017ae:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  1017b2:	ee                   	out    %al,(%dx)
  1017b3:	66 c7 45 ee 21 00    	movw   $0x21,-0x12(%ebp)
  1017b9:	c6 45 ed 04          	movb   $0x4,-0x13(%ebp)
  1017bd:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
  1017c1:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  1017c5:	ee                   	out    %al,(%dx)
  1017c6:	66 c7 45 ea 21 00    	movw   $0x21,-0x16(%ebp)
  1017cc:	c6 45 e9 03          	movb   $0x3,-0x17(%ebp)
  1017d0:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
  1017d4:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
  1017d8:	ee                   	out    %al,(%dx)
  1017d9:	66 c7 45 e6 a0 00    	movw   $0xa0,-0x1a(%ebp)
  1017df:	c6 45 e5 11          	movb   $0x11,-0x1b(%ebp)
  1017e3:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
  1017e7:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
  1017eb:	ee                   	out    %al,(%dx)
  1017ec:	66 c7 45 e2 a1 00    	movw   $0xa1,-0x1e(%ebp)
  1017f2:	c6 45 e1 28          	movb   $0x28,-0x1f(%ebp)
  1017f6:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
  1017fa:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
  1017fe:	ee                   	out    %al,(%dx)
  1017ff:	66 c7 45 de a1 00    	movw   $0xa1,-0x22(%ebp)
  101805:	c6 45 dd 02          	movb   $0x2,-0x23(%ebp)
  101809:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
  10180d:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  101811:	ee                   	out    %al,(%dx)
  101812:	66 c7 45 da a1 00    	movw   $0xa1,-0x26(%ebp)
  101818:	c6 45 d9 03          	movb   $0x3,-0x27(%ebp)
  10181c:	0f b6 45 d9          	movzbl -0x27(%ebp),%eax
  101820:	0f b7 55 da          	movzwl -0x26(%ebp),%edx
  101824:	ee                   	out    %al,(%dx)
  101825:	66 c7 45 d6 20 00    	movw   $0x20,-0x2a(%ebp)
  10182b:	c6 45 d5 68          	movb   $0x68,-0x2b(%ebp)
  10182f:	0f b6 45 d5          	movzbl -0x2b(%ebp),%eax
  101833:	0f b7 55 d6          	movzwl -0x2a(%ebp),%edx
  101837:	ee                   	out    %al,(%dx)
  101838:	66 c7 45 d2 20 00    	movw   $0x20,-0x2e(%ebp)
  10183e:	c6 45 d1 0a          	movb   $0xa,-0x2f(%ebp)
  101842:	0f b6 45 d1          	movzbl -0x2f(%ebp),%eax
  101846:	0f b7 55 d2          	movzwl -0x2e(%ebp),%edx
  10184a:	ee                   	out    %al,(%dx)
  10184b:	66 c7 45 ce a0 00    	movw   $0xa0,-0x32(%ebp)
  101851:	c6 45 cd 68          	movb   $0x68,-0x33(%ebp)
  101855:	0f b6 45 cd          	movzbl -0x33(%ebp),%eax
  101859:	0f b7 55 ce          	movzwl -0x32(%ebp),%edx
  10185d:	ee                   	out    %al,(%dx)
  10185e:	66 c7 45 ca a0 00    	movw   $0xa0,-0x36(%ebp)
  101864:	c6 45 c9 0a          	movb   $0xa,-0x37(%ebp)
  101868:	0f b6 45 c9          	movzbl -0x37(%ebp),%eax
  10186c:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
  101870:	ee                   	out    %al,(%dx)
    outb(IO_PIC1, 0x0a);    // read IRR by default

    outb(IO_PIC2, 0x68);    // OCW3
    outb(IO_PIC2, 0x0a);    // OCW3

    if (irq_mask != 0xFFFF) {
  101871:	0f b7 05 50 75 11 00 	movzwl 0x117550,%eax
  101878:	66 83 f8 ff          	cmp    $0xffff,%ax
  10187c:	74 12                	je     101890 <pic_init+0x139>
        pic_setmask(irq_mask);
  10187e:	0f b7 05 50 75 11 00 	movzwl 0x117550,%eax
  101885:	0f b7 c0             	movzwl %ax,%eax
  101888:	89 04 24             	mov    %eax,(%esp)
  10188b:	e8 41 fe ff ff       	call   1016d1 <pic_setmask>
    }
}
  101890:	c9                   	leave  
  101891:	c3                   	ret    

00101892 <print_ticks>:
#include <console.h>
#include <kdebug.h>

#define TICK_NUM 100

static void print_ticks() {
  101892:	55                   	push   %ebp
  101893:	89 e5                	mov    %esp,%ebp
  101895:	83 ec 18             	sub    $0x18,%esp
    cprintf("%d ticks\n",TICK_NUM);
  101898:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  10189f:	00 
  1018a0:	c7 04 24 00 66 10 00 	movl   $0x106600,(%esp)
  1018a7:	e8 a1 ea ff ff       	call   10034d <cprintf>
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}
  1018ac:	c9                   	leave  
  1018ad:	c3                   	ret    

001018ae <idt_init>:
    sizeof(idt) - 1, (uintptr_t)idt
};

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S */
void
idt_init(void) {
  1018ae:	55                   	push   %ebp
  1018af:	89 e5                	mov    %esp,%ebp
  1018b1:	83 ec 10             	sub    $0x10,%esp
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
    extern uintptr_t __vectors[];
    int i;
    for (i = 0; i < 256; i++) {
  1018b4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1018bb:	e9 c3 00 00 00       	jmp    101983 <idt_init+0xd5>
        SETGATE(idt[i], 0, GD_KTEXT, __vectors[i], DPL_KERNEL);
  1018c0:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1018c3:	8b 04 85 e0 75 11 00 	mov    0x1175e0(,%eax,4),%eax
  1018ca:	89 c2                	mov    %eax,%edx
  1018cc:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1018cf:	66 89 14 c5 80 a6 11 	mov    %dx,0x11a680(,%eax,8)
  1018d6:	00 
  1018d7:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1018da:	66 c7 04 c5 82 a6 11 	movw   $0x8,0x11a682(,%eax,8)
  1018e1:	00 08 00 
  1018e4:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1018e7:	0f b6 14 c5 84 a6 11 	movzbl 0x11a684(,%eax,8),%edx
  1018ee:	00 
  1018ef:	83 e2 e0             	and    $0xffffffe0,%edx
  1018f2:	88 14 c5 84 a6 11 00 	mov    %dl,0x11a684(,%eax,8)
  1018f9:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1018fc:	0f b6 14 c5 84 a6 11 	movzbl 0x11a684(,%eax,8),%edx
  101903:	00 
  101904:	83 e2 1f             	and    $0x1f,%edx
  101907:	88 14 c5 84 a6 11 00 	mov    %dl,0x11a684(,%eax,8)
  10190e:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101911:	0f b6 14 c5 85 a6 11 	movzbl 0x11a685(,%eax,8),%edx
  101918:	00 
  101919:	83 e2 f0             	and    $0xfffffff0,%edx
  10191c:	83 ca 0e             	or     $0xe,%edx
  10191f:	88 14 c5 85 a6 11 00 	mov    %dl,0x11a685(,%eax,8)
  101926:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101929:	0f b6 14 c5 85 a6 11 	movzbl 0x11a685(,%eax,8),%edx
  101930:	00 
  101931:	83 e2 ef             	and    $0xffffffef,%edx
  101934:	88 14 c5 85 a6 11 00 	mov    %dl,0x11a685(,%eax,8)
  10193b:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10193e:	0f b6 14 c5 85 a6 11 	movzbl 0x11a685(,%eax,8),%edx
  101945:	00 
  101946:	83 e2 9f             	and    $0xffffff9f,%edx
  101949:	88 14 c5 85 a6 11 00 	mov    %dl,0x11a685(,%eax,8)
  101950:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101953:	0f b6 14 c5 85 a6 11 	movzbl 0x11a685(,%eax,8),%edx
  10195a:	00 
  10195b:	83 ca 80             	or     $0xffffff80,%edx
  10195e:	88 14 c5 85 a6 11 00 	mov    %dl,0x11a685(,%eax,8)
  101965:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101968:	8b 04 85 e0 75 11 00 	mov    0x1175e0(,%eax,4),%eax
  10196f:	c1 e8 10             	shr    $0x10,%eax
  101972:	89 c2                	mov    %eax,%edx
  101974:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101977:	66 89 14 c5 86 a6 11 	mov    %dx,0x11a686(,%eax,8)
  10197e:	00 
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
    extern uintptr_t __vectors[];
    int i;
    for (i = 0; i < 256; i++) {
  10197f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  101983:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
  10198a:	0f 8e 30 ff ff ff    	jle    1018c0 <idt_init+0x12>
        SETGATE(idt[i], 0, GD_KTEXT, __vectors[i], DPL_KERNEL);
    }
    // 只有0x80这个特殊，用户就能用，而且是trap门
    SETGATE(idt[T_SYSCALL], 1, GD_KTEXT, __vectors[T_SYSCALL], DPL_USER);
  101990:	a1 e0 77 11 00       	mov    0x1177e0,%eax
  101995:	66 a3 80 aa 11 00    	mov    %ax,0x11aa80
  10199b:	66 c7 05 82 aa 11 00 	movw   $0x8,0x11aa82
  1019a2:	08 00 
  1019a4:	0f b6 05 84 aa 11 00 	movzbl 0x11aa84,%eax
  1019ab:	83 e0 e0             	and    $0xffffffe0,%eax
  1019ae:	a2 84 aa 11 00       	mov    %al,0x11aa84
  1019b3:	0f b6 05 84 aa 11 00 	movzbl 0x11aa84,%eax
  1019ba:	83 e0 1f             	and    $0x1f,%eax
  1019bd:	a2 84 aa 11 00       	mov    %al,0x11aa84
  1019c2:	0f b6 05 85 aa 11 00 	movzbl 0x11aa85,%eax
  1019c9:	83 c8 0f             	or     $0xf,%eax
  1019cc:	a2 85 aa 11 00       	mov    %al,0x11aa85
  1019d1:	0f b6 05 85 aa 11 00 	movzbl 0x11aa85,%eax
  1019d8:	83 e0 ef             	and    $0xffffffef,%eax
  1019db:	a2 85 aa 11 00       	mov    %al,0x11aa85
  1019e0:	0f b6 05 85 aa 11 00 	movzbl 0x11aa85,%eax
  1019e7:	83 c8 60             	or     $0x60,%eax
  1019ea:	a2 85 aa 11 00       	mov    %al,0x11aa85
  1019ef:	0f b6 05 85 aa 11 00 	movzbl 0x11aa85,%eax
  1019f6:	83 c8 80             	or     $0xffffff80,%eax
  1019f9:	a2 85 aa 11 00       	mov    %al,0x11aa85
  1019fe:	a1 e0 77 11 00       	mov    0x1177e0,%eax
  101a03:	c1 e8 10             	shr    $0x10,%eax
  101a06:	66 a3 86 aa 11 00    	mov    %ax,0x11aa86
    SETGATE(idt[T_SWITCH_TOU], 0, GD_KTEXT, __vectors[T_SWITCH_TOU], DPL_KERNEL);
  101a0c:	a1 c0 77 11 00       	mov    0x1177c0,%eax
  101a11:	66 a3 40 aa 11 00    	mov    %ax,0x11aa40
  101a17:	66 c7 05 42 aa 11 00 	movw   $0x8,0x11aa42
  101a1e:	08 00 
  101a20:	0f b6 05 44 aa 11 00 	movzbl 0x11aa44,%eax
  101a27:	83 e0 e0             	and    $0xffffffe0,%eax
  101a2a:	a2 44 aa 11 00       	mov    %al,0x11aa44
  101a2f:	0f b6 05 44 aa 11 00 	movzbl 0x11aa44,%eax
  101a36:	83 e0 1f             	and    $0x1f,%eax
  101a39:	a2 44 aa 11 00       	mov    %al,0x11aa44
  101a3e:	0f b6 05 45 aa 11 00 	movzbl 0x11aa45,%eax
  101a45:	83 e0 f0             	and    $0xfffffff0,%eax
  101a48:	83 c8 0e             	or     $0xe,%eax
  101a4b:	a2 45 aa 11 00       	mov    %al,0x11aa45
  101a50:	0f b6 05 45 aa 11 00 	movzbl 0x11aa45,%eax
  101a57:	83 e0 ef             	and    $0xffffffef,%eax
  101a5a:	a2 45 aa 11 00       	mov    %al,0x11aa45
  101a5f:	0f b6 05 45 aa 11 00 	movzbl 0x11aa45,%eax
  101a66:	83 e0 9f             	and    $0xffffff9f,%eax
  101a69:	a2 45 aa 11 00       	mov    %al,0x11aa45
  101a6e:	0f b6 05 45 aa 11 00 	movzbl 0x11aa45,%eax
  101a75:	83 c8 80             	or     $0xffffff80,%eax
  101a78:	a2 45 aa 11 00       	mov    %al,0x11aa45
  101a7d:	a1 c0 77 11 00       	mov    0x1177c0,%eax
  101a82:	c1 e8 10             	shr    $0x10,%eax
  101a85:	66 a3 46 aa 11 00    	mov    %ax,0x11aa46
    SETGATE(idt[T_SWITCH_TOK], 0, GD_KTEXT, __vectors[T_SWITCH_TOK], DPL_USER);
  101a8b:	a1 c4 77 11 00       	mov    0x1177c4,%eax
  101a90:	66 a3 48 aa 11 00    	mov    %ax,0x11aa48
  101a96:	66 c7 05 4a aa 11 00 	movw   $0x8,0x11aa4a
  101a9d:	08 00 
  101a9f:	0f b6 05 4c aa 11 00 	movzbl 0x11aa4c,%eax
  101aa6:	83 e0 e0             	and    $0xffffffe0,%eax
  101aa9:	a2 4c aa 11 00       	mov    %al,0x11aa4c
  101aae:	0f b6 05 4c aa 11 00 	movzbl 0x11aa4c,%eax
  101ab5:	83 e0 1f             	and    $0x1f,%eax
  101ab8:	a2 4c aa 11 00       	mov    %al,0x11aa4c
  101abd:	0f b6 05 4d aa 11 00 	movzbl 0x11aa4d,%eax
  101ac4:	83 e0 f0             	and    $0xfffffff0,%eax
  101ac7:	83 c8 0e             	or     $0xe,%eax
  101aca:	a2 4d aa 11 00       	mov    %al,0x11aa4d
  101acf:	0f b6 05 4d aa 11 00 	movzbl 0x11aa4d,%eax
  101ad6:	83 e0 ef             	and    $0xffffffef,%eax
  101ad9:	a2 4d aa 11 00       	mov    %al,0x11aa4d
  101ade:	0f b6 05 4d aa 11 00 	movzbl 0x11aa4d,%eax
  101ae5:	83 c8 60             	or     $0x60,%eax
  101ae8:	a2 4d aa 11 00       	mov    %al,0x11aa4d
  101aed:	0f b6 05 4d aa 11 00 	movzbl 0x11aa4d,%eax
  101af4:	83 c8 80             	or     $0xffffff80,%eax
  101af7:	a2 4d aa 11 00       	mov    %al,0x11aa4d
  101afc:	a1 c4 77 11 00       	mov    0x1177c4,%eax
  101b01:	c1 e8 10             	shr    $0x10,%eax
  101b04:	66 a3 4e aa 11 00    	mov    %ax,0x11aa4e
  101b0a:	c7 45 f8 60 75 11 00 	movl   $0x117560,-0x8(%ebp)
    }
}

static inline void
lidt(struct pseudodesc *pd) {
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
  101b11:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101b14:	0f 01 18             	lidtl  (%eax)
    lidt(&idt_pd);
}
  101b17:	c9                   	leave  
  101b18:	c3                   	ret    

00101b19 <trapname>:

static const char *
trapname(int trapno) {
  101b19:	55                   	push   %ebp
  101b1a:	89 e5                	mov    %esp,%ebp
        "Alignment Check",
        "Machine-Check",
        "SIMD Floating-Point Exception"
    };

    if (trapno < sizeof(excnames)/sizeof(const char * const)) {
  101b1c:	8b 45 08             	mov    0x8(%ebp),%eax
  101b1f:	83 f8 13             	cmp    $0x13,%eax
  101b22:	77 0c                	ja     101b30 <trapname+0x17>
        return excnames[trapno];
  101b24:	8b 45 08             	mov    0x8(%ebp),%eax
  101b27:	8b 04 85 60 69 10 00 	mov    0x106960(,%eax,4),%eax
  101b2e:	eb 18                	jmp    101b48 <trapname+0x2f>
    }
    if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16) {
  101b30:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  101b34:	7e 0d                	jle    101b43 <trapname+0x2a>
  101b36:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  101b3a:	7f 07                	jg     101b43 <trapname+0x2a>
        return "Hardware Interrupt";
  101b3c:	b8 0a 66 10 00       	mov    $0x10660a,%eax
  101b41:	eb 05                	jmp    101b48 <trapname+0x2f>
    }
    return "(unknown trap)";
  101b43:	b8 1d 66 10 00       	mov    $0x10661d,%eax
}
  101b48:	5d                   	pop    %ebp
  101b49:	c3                   	ret    

00101b4a <trap_in_kernel>:

/* trap_in_kernel - test if trap happened in kernel */
bool
trap_in_kernel(struct trapframe *tf) {
  101b4a:	55                   	push   %ebp
  101b4b:	89 e5                	mov    %esp,%ebp
    return (tf->tf_cs == (uint16_t)KERNEL_CS);
  101b4d:	8b 45 08             	mov    0x8(%ebp),%eax
  101b50:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101b54:	66 83 f8 08          	cmp    $0x8,%ax
  101b58:	0f 94 c0             	sete   %al
  101b5b:	0f b6 c0             	movzbl %al,%eax
}
  101b5e:	5d                   	pop    %ebp
  101b5f:	c3                   	ret    

00101b60 <print_trapframe>:
    "TF", "IF", "DF", "OF", NULL, NULL, "NT", NULL,
    "RF", "VM", "AC", "VIF", "VIP", "ID", NULL, NULL,
};

void
print_trapframe(struct trapframe *tf) {
  101b60:	55                   	push   %ebp
  101b61:	89 e5                	mov    %esp,%ebp
  101b63:	83 ec 28             	sub    $0x28,%esp
    cprintf("trapframe at %p\n", tf);
  101b66:	8b 45 08             	mov    0x8(%ebp),%eax
  101b69:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b6d:	c7 04 24 5e 66 10 00 	movl   $0x10665e,(%esp)
  101b74:	e8 d4 e7 ff ff       	call   10034d <cprintf>
    print_regs(&tf->tf_regs);
  101b79:	8b 45 08             	mov    0x8(%ebp),%eax
  101b7c:	89 04 24             	mov    %eax,(%esp)
  101b7f:	e8 a1 01 00 00       	call   101d25 <print_regs>
    cprintf("  ds   0x----%04x\n", tf->tf_ds);
  101b84:	8b 45 08             	mov    0x8(%ebp),%eax
  101b87:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  101b8b:	0f b7 c0             	movzwl %ax,%eax
  101b8e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b92:	c7 04 24 6f 66 10 00 	movl   $0x10666f,(%esp)
  101b99:	e8 af e7 ff ff       	call   10034d <cprintf>
    cprintf("  es   0x----%04x\n", tf->tf_es);
  101b9e:	8b 45 08             	mov    0x8(%ebp),%eax
  101ba1:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101ba5:	0f b7 c0             	movzwl %ax,%eax
  101ba8:	89 44 24 04          	mov    %eax,0x4(%esp)
  101bac:	c7 04 24 82 66 10 00 	movl   $0x106682,(%esp)
  101bb3:	e8 95 e7 ff ff       	call   10034d <cprintf>
    cprintf("  fs   0x----%04x\n", tf->tf_fs);
  101bb8:	8b 45 08             	mov    0x8(%ebp),%eax
  101bbb:	0f b7 40 24          	movzwl 0x24(%eax),%eax
  101bbf:	0f b7 c0             	movzwl %ax,%eax
  101bc2:	89 44 24 04          	mov    %eax,0x4(%esp)
  101bc6:	c7 04 24 95 66 10 00 	movl   $0x106695,(%esp)
  101bcd:	e8 7b e7 ff ff       	call   10034d <cprintf>
    cprintf("  gs   0x----%04x\n", tf->tf_gs);
  101bd2:	8b 45 08             	mov    0x8(%ebp),%eax
  101bd5:	0f b7 40 20          	movzwl 0x20(%eax),%eax
  101bd9:	0f b7 c0             	movzwl %ax,%eax
  101bdc:	89 44 24 04          	mov    %eax,0x4(%esp)
  101be0:	c7 04 24 a8 66 10 00 	movl   $0x1066a8,(%esp)
  101be7:	e8 61 e7 ff ff       	call   10034d <cprintf>
    cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
  101bec:	8b 45 08             	mov    0x8(%ebp),%eax
  101bef:	8b 40 30             	mov    0x30(%eax),%eax
  101bf2:	89 04 24             	mov    %eax,(%esp)
  101bf5:	e8 1f ff ff ff       	call   101b19 <trapname>
  101bfa:	8b 55 08             	mov    0x8(%ebp),%edx
  101bfd:	8b 52 30             	mov    0x30(%edx),%edx
  101c00:	89 44 24 08          	mov    %eax,0x8(%esp)
  101c04:	89 54 24 04          	mov    %edx,0x4(%esp)
  101c08:	c7 04 24 bb 66 10 00 	movl   $0x1066bb,(%esp)
  101c0f:	e8 39 e7 ff ff       	call   10034d <cprintf>
    cprintf("  err  0x%08x\n", tf->tf_err);
  101c14:	8b 45 08             	mov    0x8(%ebp),%eax
  101c17:	8b 40 34             	mov    0x34(%eax),%eax
  101c1a:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c1e:	c7 04 24 cd 66 10 00 	movl   $0x1066cd,(%esp)
  101c25:	e8 23 e7 ff ff       	call   10034d <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
  101c2a:	8b 45 08             	mov    0x8(%ebp),%eax
  101c2d:	8b 40 38             	mov    0x38(%eax),%eax
  101c30:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c34:	c7 04 24 dc 66 10 00 	movl   $0x1066dc,(%esp)
  101c3b:	e8 0d e7 ff ff       	call   10034d <cprintf>
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
  101c40:	8b 45 08             	mov    0x8(%ebp),%eax
  101c43:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101c47:	0f b7 c0             	movzwl %ax,%eax
  101c4a:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c4e:	c7 04 24 eb 66 10 00 	movl   $0x1066eb,(%esp)
  101c55:	e8 f3 e6 ff ff       	call   10034d <cprintf>
    cprintf("  flag 0x%08x ", tf->tf_eflags);
  101c5a:	8b 45 08             	mov    0x8(%ebp),%eax
  101c5d:	8b 40 40             	mov    0x40(%eax),%eax
  101c60:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c64:	c7 04 24 fe 66 10 00 	movl   $0x1066fe,(%esp)
  101c6b:	e8 dd e6 ff ff       	call   10034d <cprintf>

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
  101c70:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  101c77:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
  101c7e:	eb 3e                	jmp    101cbe <print_trapframe+0x15e>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
  101c80:	8b 45 08             	mov    0x8(%ebp),%eax
  101c83:	8b 50 40             	mov    0x40(%eax),%edx
  101c86:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101c89:	21 d0                	and    %edx,%eax
  101c8b:	85 c0                	test   %eax,%eax
  101c8d:	74 28                	je     101cb7 <print_trapframe+0x157>
  101c8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c92:	8b 04 85 80 75 11 00 	mov    0x117580(,%eax,4),%eax
  101c99:	85 c0                	test   %eax,%eax
  101c9b:	74 1a                	je     101cb7 <print_trapframe+0x157>
            cprintf("%s,", IA32flags[i]);
  101c9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101ca0:	8b 04 85 80 75 11 00 	mov    0x117580(,%eax,4),%eax
  101ca7:	89 44 24 04          	mov    %eax,0x4(%esp)
  101cab:	c7 04 24 0d 67 10 00 	movl   $0x10670d,(%esp)
  101cb2:	e8 96 e6 ff ff       	call   10034d <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
    cprintf("  flag 0x%08x ", tf->tf_eflags);

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
  101cb7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  101cbb:	d1 65 f0             	shll   -0x10(%ebp)
  101cbe:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101cc1:	83 f8 17             	cmp    $0x17,%eax
  101cc4:	76 ba                	jbe    101c80 <print_trapframe+0x120>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
            cprintf("%s,", IA32flags[i]);
        }
    }
    cprintf("IOPL=%d\n", (tf->tf_eflags & FL_IOPL_MASK) >> 12);
  101cc6:	8b 45 08             	mov    0x8(%ebp),%eax
  101cc9:	8b 40 40             	mov    0x40(%eax),%eax
  101ccc:	25 00 30 00 00       	and    $0x3000,%eax
  101cd1:	c1 e8 0c             	shr    $0xc,%eax
  101cd4:	89 44 24 04          	mov    %eax,0x4(%esp)
  101cd8:	c7 04 24 11 67 10 00 	movl   $0x106711,(%esp)
  101cdf:	e8 69 e6 ff ff       	call   10034d <cprintf>

    if (!trap_in_kernel(tf)) {
  101ce4:	8b 45 08             	mov    0x8(%ebp),%eax
  101ce7:	89 04 24             	mov    %eax,(%esp)
  101cea:	e8 5b fe ff ff       	call   101b4a <trap_in_kernel>
  101cef:	85 c0                	test   %eax,%eax
  101cf1:	75 30                	jne    101d23 <print_trapframe+0x1c3>
        cprintf("  esp  0x%08x\n", tf->tf_esp);
  101cf3:	8b 45 08             	mov    0x8(%ebp),%eax
  101cf6:	8b 40 44             	mov    0x44(%eax),%eax
  101cf9:	89 44 24 04          	mov    %eax,0x4(%esp)
  101cfd:	c7 04 24 1a 67 10 00 	movl   $0x10671a,(%esp)
  101d04:	e8 44 e6 ff ff       	call   10034d <cprintf>
        cprintf("  ss   0x----%04x\n", tf->tf_ss);
  101d09:	8b 45 08             	mov    0x8(%ebp),%eax
  101d0c:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101d10:	0f b7 c0             	movzwl %ax,%eax
  101d13:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d17:	c7 04 24 29 67 10 00 	movl   $0x106729,(%esp)
  101d1e:	e8 2a e6 ff ff       	call   10034d <cprintf>
    }
}
  101d23:	c9                   	leave  
  101d24:	c3                   	ret    

00101d25 <print_regs>:

void
print_regs(struct pushregs *regs) {
  101d25:	55                   	push   %ebp
  101d26:	89 e5                	mov    %esp,%ebp
  101d28:	83 ec 18             	sub    $0x18,%esp
    cprintf("  edi  0x%08x\n", regs->reg_edi);
  101d2b:	8b 45 08             	mov    0x8(%ebp),%eax
  101d2e:	8b 00                	mov    (%eax),%eax
  101d30:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d34:	c7 04 24 3c 67 10 00 	movl   $0x10673c,(%esp)
  101d3b:	e8 0d e6 ff ff       	call   10034d <cprintf>
    cprintf("  esi  0x%08x\n", regs->reg_esi);
  101d40:	8b 45 08             	mov    0x8(%ebp),%eax
  101d43:	8b 40 04             	mov    0x4(%eax),%eax
  101d46:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d4a:	c7 04 24 4b 67 10 00 	movl   $0x10674b,(%esp)
  101d51:	e8 f7 e5 ff ff       	call   10034d <cprintf>
    cprintf("  ebp  0x%08x\n", regs->reg_ebp);
  101d56:	8b 45 08             	mov    0x8(%ebp),%eax
  101d59:	8b 40 08             	mov    0x8(%eax),%eax
  101d5c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d60:	c7 04 24 5a 67 10 00 	movl   $0x10675a,(%esp)
  101d67:	e8 e1 e5 ff ff       	call   10034d <cprintf>
    cprintf("  oesp 0x%08x\n", regs->reg_oesp);
  101d6c:	8b 45 08             	mov    0x8(%ebp),%eax
  101d6f:	8b 40 0c             	mov    0xc(%eax),%eax
  101d72:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d76:	c7 04 24 69 67 10 00 	movl   $0x106769,(%esp)
  101d7d:	e8 cb e5 ff ff       	call   10034d <cprintf>
    cprintf("  ebx  0x%08x\n", regs->reg_ebx);
  101d82:	8b 45 08             	mov    0x8(%ebp),%eax
  101d85:	8b 40 10             	mov    0x10(%eax),%eax
  101d88:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d8c:	c7 04 24 78 67 10 00 	movl   $0x106778,(%esp)
  101d93:	e8 b5 e5 ff ff       	call   10034d <cprintf>
    cprintf("  edx  0x%08x\n", regs->reg_edx);
  101d98:	8b 45 08             	mov    0x8(%ebp),%eax
  101d9b:	8b 40 14             	mov    0x14(%eax),%eax
  101d9e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101da2:	c7 04 24 87 67 10 00 	movl   $0x106787,(%esp)
  101da9:	e8 9f e5 ff ff       	call   10034d <cprintf>
    cprintf("  ecx  0x%08x\n", regs->reg_ecx);
  101dae:	8b 45 08             	mov    0x8(%ebp),%eax
  101db1:	8b 40 18             	mov    0x18(%eax),%eax
  101db4:	89 44 24 04          	mov    %eax,0x4(%esp)
  101db8:	c7 04 24 96 67 10 00 	movl   $0x106796,(%esp)
  101dbf:	e8 89 e5 ff ff       	call   10034d <cprintf>
    cprintf("  eax  0x%08x\n", regs->reg_eax);
  101dc4:	8b 45 08             	mov    0x8(%ebp),%eax
  101dc7:	8b 40 1c             	mov    0x1c(%eax),%eax
  101dca:	89 44 24 04          	mov    %eax,0x4(%esp)
  101dce:	c7 04 24 a5 67 10 00 	movl   $0x1067a5,(%esp)
  101dd5:	e8 73 e5 ff ff       	call   10034d <cprintf>
}
  101dda:	c9                   	leave  
  101ddb:	c3                   	ret    

00101ddc <trap_dispatch>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static void
trap_dispatch(struct trapframe *tf) {
  101ddc:	55                   	push   %ebp
  101ddd:	89 e5                	mov    %esp,%ebp
  101ddf:	57                   	push   %edi
  101de0:	56                   	push   %esi
  101de1:	53                   	push   %ebx
  101de2:	81 ec ac 00 00 00    	sub    $0xac,%esp
    char c;

    switch (tf->tf_trapno) {
  101de8:	8b 45 08             	mov    0x8(%ebp),%eax
  101deb:	8b 40 30             	mov    0x30(%eax),%eax
  101dee:	83 f8 2f             	cmp    $0x2f,%eax
  101df1:	77 21                	ja     101e14 <trap_dispatch+0x38>
  101df3:	83 f8 2e             	cmp    $0x2e,%eax
  101df6:	0f 83 72 03 00 00    	jae    10216e <trap_dispatch+0x392>
  101dfc:	83 f8 21             	cmp    $0x21,%eax
  101dff:	0f 84 8a 00 00 00    	je     101e8f <trap_dispatch+0xb3>
  101e05:	83 f8 24             	cmp    $0x24,%eax
  101e08:	74 5c                	je     101e66 <trap_dispatch+0x8a>
  101e0a:	83 f8 20             	cmp    $0x20,%eax
  101e0d:	74 1c                	je     101e2b <trap_dispatch+0x4f>
  101e0f:	e9 22 03 00 00       	jmp    102136 <trap_dispatch+0x35a>
  101e14:	83 f8 78             	cmp    $0x78,%eax
  101e17:	0f 84 2c 02 00 00    	je     102049 <trap_dispatch+0x26d>
  101e1d:	83 f8 79             	cmp    $0x79,%eax
  101e20:	0f 84 a4 02 00 00    	je     1020ca <trap_dispatch+0x2ee>
  101e26:	e9 0b 03 00 00       	jmp    102136 <trap_dispatch+0x35a>
        /* handle the timer interrupt */
        /* (1) After a timer interrupt, you should record this event using a global variable (increase it), such as ticks in kern/driver/clock.c
         * (2) Every TICK_NUM cycle, you can print some info using a funciton, such as print_ticks().
         * (3) Too Simple? Yes, I think so!
         */
        ticks++;
  101e2b:	a1 0c af 11 00       	mov    0x11af0c,%eax
  101e30:	83 c0 01             	add    $0x1,%eax
  101e33:	a3 0c af 11 00       	mov    %eax,0x11af0c
        if (ticks % TICK_NUM == 0) {
  101e38:	8b 0d 0c af 11 00    	mov    0x11af0c,%ecx
  101e3e:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
  101e43:	89 c8                	mov    %ecx,%eax
  101e45:	f7 e2                	mul    %edx
  101e47:	89 d0                	mov    %edx,%eax
  101e49:	c1 e8 05             	shr    $0x5,%eax
  101e4c:	6b c0 64             	imul   $0x64,%eax,%eax
  101e4f:	29 c1                	sub    %eax,%ecx
  101e51:	89 c8                	mov    %ecx,%eax
  101e53:	85 c0                	test   %eax,%eax
  101e55:	75 0a                	jne    101e61 <trap_dispatch+0x85>
            print_ticks();
  101e57:	e8 36 fa ff ff       	call   101892 <print_ticks>
        }
        break;
  101e5c:	e9 0e 03 00 00       	jmp    10216f <trap_dispatch+0x393>
  101e61:	e9 09 03 00 00       	jmp    10216f <trap_dispatch+0x393>
    case IRQ_OFFSET + IRQ_COM1:
        c = cons_getc();
  101e66:	e8 eb f7 ff ff       	call   101656 <cons_getc>
  101e6b:	88 45 e7             	mov    %al,-0x19(%ebp)
        cprintf("serial [%03d] %c\n", c, c);
  101e6e:	0f be 55 e7          	movsbl -0x19(%ebp),%edx
  101e72:	0f be 45 e7          	movsbl -0x19(%ebp),%eax
  101e76:	89 54 24 08          	mov    %edx,0x8(%esp)
  101e7a:	89 44 24 04          	mov    %eax,0x4(%esp)
  101e7e:	c7 04 24 b4 67 10 00 	movl   $0x1067b4,(%esp)
  101e85:	e8 c3 e4 ff ff       	call   10034d <cprintf>
        break;
  101e8a:	e9 e0 02 00 00       	jmp    10216f <trap_dispatch+0x393>
    case IRQ_OFFSET + IRQ_KBD:
        c = cons_getc();
  101e8f:	e8 c2 f7 ff ff       	call   101656 <cons_getc>
  101e94:	88 45 e7             	mov    %al,-0x19(%ebp)
        cprintf("kbd [%03d] %c\n", c, c);
  101e97:	0f be 55 e7          	movsbl -0x19(%ebp),%edx
  101e9b:	0f be 45 e7          	movsbl -0x19(%ebp),%eax
  101e9f:	89 54 24 08          	mov    %edx,0x8(%esp)
  101ea3:	89 44 24 04          	mov    %eax,0x4(%esp)
  101ea7:	c7 04 24 c6 67 10 00 	movl   $0x1067c6,(%esp)
  101eae:	e8 9a e4 ff ff       	call   10034d <cprintf>
        if (c == 51 && tf->tf_cs == KERNEL_CS) { //切换到用户态
  101eb3:	80 7d e7 33          	cmpb   $0x33,-0x19(%ebp)
  101eb7:	75 76                	jne    101f2f <trap_dispatch+0x153>
  101eb9:	8b 45 08             	mov    0x8(%ebp),%eax
  101ebc:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101ec0:	66 83 f8 08          	cmp    $0x8,%ax
  101ec4:	75 69                	jne    101f2f <trap_dispatch+0x153>
            struct trapframe fake_tf = *tf;
  101ec6:	8b 45 08             	mov    0x8(%ebp),%eax
  101ec9:	8d 95 64 ff ff ff    	lea    -0x9c(%ebp),%edx
  101ecf:	89 c3                	mov    %eax,%ebx
  101ed1:	b8 13 00 00 00       	mov    $0x13,%eax
  101ed6:	89 d7                	mov    %edx,%edi
  101ed8:	89 de                	mov    %ebx,%esi
  101eda:	89 c1                	mov    %eax,%ecx
  101edc:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
            //设置段寄存器
            fake_tf.tf_cs = USER_CS;
  101ede:	66 c7 45 a0 1b 00    	movw   $0x1b,-0x60(%ebp)
            fake_tf.tf_ss = fake_tf.tf_ds = fake_tf.tf_es = fake_tf.tf_fs = fake_tf.tf_gs = USER_DS;
  101ee4:	66 c7 45 84 23 00    	movw   $0x23,-0x7c(%ebp)
  101eea:	0f b7 45 84          	movzwl -0x7c(%ebp),%eax
  101eee:	66 89 45 88          	mov    %ax,-0x78(%ebp)
  101ef2:	0f b7 45 88          	movzwl -0x78(%ebp),%eax
  101ef6:	66 89 45 8c          	mov    %ax,-0x74(%ebp)
  101efa:	0f b7 45 8c          	movzwl -0x74(%ebp),%eax
  101efe:	66 89 45 90          	mov    %ax,-0x70(%ebp)
  101f02:	0f b7 45 90          	movzwl -0x70(%ebp),%eax
  101f06:	66 89 45 ac          	mov    %ax,-0x54(%ebp)
            //设置esp，相当于骗CPU，让它以为是从U到K，然后他就会恢复esp的值
            fake_tf.tf_esp = (&tf->tf_esp);
  101f0a:	8b 45 08             	mov    0x8(%ebp),%eax
  101f0d:	83 c0 44             	add    $0x44,%eax
  101f10:	89 45 a8             	mov    %eax,-0x58(%ebp)
            //把eflags的IO位打开，要不切换到用户态后没办法打印信息了。
            fake_tf.tf_eflags |= FL_IOPL_MASK;
  101f13:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  101f16:	80 cc 30             	or     $0x30,%ah
  101f19:	89 45 a4             	mov    %eax,-0x5c(%ebp)
            //存在栈里的esp指向了tf的首地址，这里把这个esp的值改了，pop之后
            //的esp就指向fake_tf了
            *((uint32_t*)tf - 1) = &fake_tf;
  101f1c:	8b 45 08             	mov    0x8(%ebp),%eax
  101f1f:	8d 50 fc             	lea    -0x4(%eax),%edx
  101f22:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
  101f28:	89 02                	mov    %eax,(%edx)
        cprintf("serial [%03d] %c\n", c, c);
        break;
    case IRQ_OFFSET + IRQ_KBD:
        c = cons_getc();
        cprintf("kbd [%03d] %c\n", c, c);
        if (c == 51 && tf->tf_cs == KERNEL_CS) { //切换到用户态
  101f2a:	e9 15 01 00 00       	jmp    102044 <trap_dispatch+0x268>
            fake_tf.tf_eflags |= FL_IOPL_MASK;
            //存在栈里的esp指向了tf的首地址，这里把这个esp的值改了，pop之后
            //的esp就指向fake_tf了
            *((uint32_t*)tf - 1) = &fake_tf;
        }
        else if (c == 48 && tf->tf_cs == USER_CS) { //切换到内核态
  101f2f:	80 7d e7 30          	cmpb   $0x30,-0x19(%ebp)
  101f33:	0f 85 0b 01 00 00    	jne    102044 <trap_dispatch+0x268>
  101f39:	8b 45 08             	mov    0x8(%ebp),%eax
  101f3c:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101f40:	66 83 f8 1b          	cmp    $0x1b,%ax
  101f44:	0f 85 fa 00 00 00    	jne    102044 <trap_dispatch+0x268>
            struct trapframe fake_tf = *tf;
  101f4a:	8b 45 08             	mov    0x8(%ebp),%eax
  101f4d:	8d 95 64 ff ff ff    	lea    -0x9c(%ebp),%edx
  101f53:	89 c3                	mov    %eax,%ebx
  101f55:	b8 13 00 00 00       	mov    $0x13,%eax
  101f5a:	89 d7                	mov    %edx,%edi
  101f5c:	89 de                	mov    %ebx,%esi
  101f5e:	89 c1                	mov    %eax,%ecx
  101f60:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
            //设置段寄存器
            fake_tf.tf_cs = KERNEL_CS;
  101f62:	66 c7 45 a0 08 00    	movw   $0x8,-0x60(%ebp)
            fake_tf.tf_ss = fake_tf.tf_ds = fake_tf.tf_es = fake_tf.tf_fs = fake_tf.tf_gs = KERNEL_DS;
  101f68:	66 c7 45 84 10 00    	movw   $0x10,-0x7c(%ebp)
  101f6e:	0f b7 45 84          	movzwl -0x7c(%ebp),%eax
  101f72:	66 89 45 88          	mov    %ax,-0x78(%ebp)
  101f76:	0f b7 45 88          	movzwl -0x78(%ebp),%eax
  101f7a:	66 89 45 8c          	mov    %ax,-0x74(%ebp)
  101f7e:	0f b7 45 8c          	movzwl -0x74(%ebp),%eax
  101f82:	66 89 45 90          	mov    %ax,-0x70(%ebp)
  101f86:	0f b7 45 90          	movzwl -0x70(%ebp),%eax
  101f8a:	66 89 45 ac          	mov    %ax,-0x54(%ebp)
            fake_tf.tf_eflags &= ~FL_IOPL_MASK;
  101f8e:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  101f91:	80 e4 cf             	and    $0xcf,%ah
  101f94:	89 45 a4             	mov    %eax,-0x5c(%ebp)
            uintptr_t user_tf_add = (struct trapframe*)fake_tf.tf_esp - 1;
  101f97:	8b 45 a8             	mov    -0x58(%ebp),%eax
  101f9a:	83 e8 4c             	sub    $0x4c,%eax
  101f9d:	89 45 e0             	mov    %eax,-0x20(%ebp)
            user_tf_add += 8;
  101fa0:	83 45 e0 08          	addl   $0x8,-0x20(%ebp)
            __memmove(user_tf_add, &fake_tf, sizeof(struct trapframe) - 8);
  101fa4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101fa7:	89 45 dc             	mov    %eax,-0x24(%ebp)
  101faa:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
  101fb0:	89 45 d8             	mov    %eax,-0x28(%ebp)
  101fb3:	c7 45 d4 44 00 00 00 	movl   $0x44,-0x2c(%ebp)

#ifndef __HAVE_ARCH_MEMMOVE
#define __HAVE_ARCH_MEMMOVE
static inline void *
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
  101fba:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101fbd:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  101fc0:	73 3f                	jae    102001 <trap_dispatch+0x225>
  101fc2:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101fc5:	89 45 d0             	mov    %eax,-0x30(%ebp)
  101fc8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101fcb:	89 45 cc             	mov    %eax,-0x34(%ebp)
  101fce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  101fd1:	89 45 c8             	mov    %eax,-0x38(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
  101fd4:	8b 45 c8             	mov    -0x38(%ebp),%eax
  101fd7:	c1 e8 02             	shr    $0x2,%eax
  101fda:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
  101fdc:	8b 55 d0             	mov    -0x30(%ebp),%edx
  101fdf:	8b 45 cc             	mov    -0x34(%ebp),%eax
  101fe2:	89 d7                	mov    %edx,%edi
  101fe4:	89 c6                	mov    %eax,%esi
  101fe6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  101fe8:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  101feb:	83 e1 03             	and    $0x3,%ecx
  101fee:	74 02                	je     101ff2 <trap_dispatch+0x216>
  101ff0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  101ff2:	89 f0                	mov    %esi,%eax
  101ff4:	89 fa                	mov    %edi,%edx
  101ff6:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
  101ff9:	89 55 c0             	mov    %edx,-0x40(%ebp)
  101ffc:	89 45 bc             	mov    %eax,-0x44(%ebp)
  101fff:	eb 33                	jmp    102034 <trap_dispatch+0x258>
    asm volatile (
        "std;"
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
  102001:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102004:	8d 50 ff             	lea    -0x1(%eax),%edx
  102007:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10200a:	01 c2                	add    %eax,%edx
  10200c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10200f:	8d 48 ff             	lea    -0x1(%eax),%ecx
  102012:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102015:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
        return __memcpy(dst, src, n);
    }
    int d0, d1, d2;
    asm volatile (
  102018:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10201b:	89 c1                	mov    %eax,%ecx
  10201d:	89 d8                	mov    %ebx,%eax
  10201f:	89 d6                	mov    %edx,%esi
  102021:	89 c7                	mov    %eax,%edi
  102023:	fd                   	std    
  102024:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  102026:	fc                   	cld    
  102027:	89 f8                	mov    %edi,%eax
  102029:	89 f2                	mov    %esi,%edx
  10202b:	89 4d b8             	mov    %ecx,-0x48(%ebp)
  10202e:	89 55 b4             	mov    %edx,-0x4c(%ebp)
  102031:	89 45 b0             	mov    %eax,-0x50(%ebp)
            //存在栈里的esp指向了tf的首地址，这里把这个esp的值改了，pop之后
            //的esp就指向fake_tf了
            *((uint32_t*)tf - 1) = user_tf_add;
  102034:	8b 45 08             	mov    0x8(%ebp),%eax
  102037:	8d 50 fc             	lea    -0x4(%eax),%edx
  10203a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10203d:	89 02                	mov    %eax,(%edx)
        }
        break;
  10203f:	e9 2b 01 00 00       	jmp    10216f <trap_dispatch+0x393>
  102044:	e9 26 01 00 00       	jmp    10216f <trap_dispatch+0x393>
    //LAB1 CHALLENGE 1 : YOUR CODE you should modify below codes.
    case T_SWITCH_TOU:
        if (tf->tf_cs != USER_CS) {
  102049:	8b 45 08             	mov    0x8(%ebp),%eax
  10204c:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  102050:	66 83 f8 1b          	cmp    $0x1b,%ax
  102054:	74 6f                	je     1020c5 <trap_dispatch+0x2e9>
            //设置段寄存
            tf->tf_cs = USER_CS;
  102056:	8b 45 08             	mov    0x8(%ebp),%eax
  102059:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
            tf->tf_ss = tf->tf_ds = tf->tf_es = tf->tf_fs = tf->tf_gs = USER_DS;
  10205f:	8b 45 08             	mov    0x8(%ebp),%eax
  102062:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
  102068:	8b 45 08             	mov    0x8(%ebp),%eax
  10206b:	0f b7 50 20          	movzwl 0x20(%eax),%edx
  10206f:	8b 45 08             	mov    0x8(%ebp),%eax
  102072:	66 89 50 24          	mov    %dx,0x24(%eax)
  102076:	8b 45 08             	mov    0x8(%ebp),%eax
  102079:	0f b7 50 24          	movzwl 0x24(%eax),%edx
  10207d:	8b 45 08             	mov    0x8(%ebp),%eax
  102080:	66 89 50 28          	mov    %dx,0x28(%eax)
  102084:	8b 45 08             	mov    0x8(%ebp),%eax
  102087:	0f b7 50 28          	movzwl 0x28(%eax),%edx
  10208b:	8b 45 08             	mov    0x8(%ebp),%eax
  10208e:	66 89 50 2c          	mov    %dx,0x2c(%eax)
  102092:	8b 45 08             	mov    0x8(%ebp),%eax
  102095:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
  102099:	8b 45 08             	mov    0x8(%ebp),%eax
  10209c:	66 89 50 48          	mov    %dx,0x48(%eax)
            tf->tf_esp += 4;
  1020a0:	8b 45 08             	mov    0x8(%ebp),%eax
  1020a3:	8b 40 44             	mov    0x44(%eax),%eax
  1020a6:	8d 50 04             	lea    0x4(%eax),%edx
  1020a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1020ac:	89 50 44             	mov    %edx,0x44(%eax)
            //把eflags的IO位打开，要不切换到用户态后没办法打印信息了。
            tf->tf_eflags |= FL_IOPL_MASK;
  1020af:	8b 45 08             	mov    0x8(%ebp),%eax
  1020b2:	8b 40 40             	mov    0x40(%eax),%eax
  1020b5:	80 cc 30             	or     $0x30,%ah
  1020b8:	89 c2                	mov    %eax,%edx
  1020ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1020bd:	89 50 40             	mov    %edx,0x40(%eax)
        }
        break;
  1020c0:	e9 aa 00 00 00       	jmp    10216f <trap_dispatch+0x393>
  1020c5:	e9 a5 00 00 00       	jmp    10216f <trap_dispatch+0x393>
    case T_SWITCH_TOK:
        if (tf->tf_cs != KERNEL_CS) {
  1020ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1020cd:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1020d1:	66 83 f8 08          	cmp    $0x8,%ax
  1020d5:	74 5d                	je     102134 <trap_dispatch+0x358>
            //设置段寄存器
            tf->tf_cs = KERNEL_CS;
  1020d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1020da:	66 c7 40 3c 08 00    	movw   $0x8,0x3c(%eax)
            tf->tf_ss = tf->tf_ds = tf->tf_es = tf->tf_fs = tf->tf_gs = KERNEL_DS;
  1020e0:	8b 45 08             	mov    0x8(%ebp),%eax
  1020e3:	66 c7 40 20 10 00    	movw   $0x10,0x20(%eax)
  1020e9:	8b 45 08             	mov    0x8(%ebp),%eax
  1020ec:	0f b7 50 20          	movzwl 0x20(%eax),%edx
  1020f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1020f3:	66 89 50 24          	mov    %dx,0x24(%eax)
  1020f7:	8b 45 08             	mov    0x8(%ebp),%eax
  1020fa:	0f b7 50 24          	movzwl 0x24(%eax),%edx
  1020fe:	8b 45 08             	mov    0x8(%ebp),%eax
  102101:	66 89 50 28          	mov    %dx,0x28(%eax)
  102105:	8b 45 08             	mov    0x8(%ebp),%eax
  102108:	0f b7 50 28          	movzwl 0x28(%eax),%edx
  10210c:	8b 45 08             	mov    0x8(%ebp),%eax
  10210f:	66 89 50 2c          	mov    %dx,0x2c(%eax)
  102113:	8b 45 08             	mov    0x8(%ebp),%eax
  102116:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
  10211a:	8b 45 08             	mov    0x8(%ebp),%eax
  10211d:	66 89 50 48          	mov    %dx,0x48(%eax)
            //把eflags的IO位关闭
            tf->tf_eflags &= ~FL_IOPL_MASK;
  102121:	8b 45 08             	mov    0x8(%ebp),%eax
  102124:	8b 40 40             	mov    0x40(%eax),%eax
  102127:	80 e4 cf             	and    $0xcf,%ah
  10212a:	89 c2                	mov    %eax,%edx
  10212c:	8b 45 08             	mov    0x8(%ebp),%eax
  10212f:	89 50 40             	mov    %edx,0x40(%eax)
        }
        break;
  102132:	eb 3b                	jmp    10216f <trap_dispatch+0x393>
  102134:	eb 39                	jmp    10216f <trap_dispatch+0x393>
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
    default:
        // in kernel, it must be a mistake
        if ((tf->tf_cs & 3) == 0) {
  102136:	8b 45 08             	mov    0x8(%ebp),%eax
  102139:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  10213d:	0f b7 c0             	movzwl %ax,%eax
  102140:	83 e0 03             	and    $0x3,%eax
  102143:	85 c0                	test   %eax,%eax
  102145:	75 28                	jne    10216f <trap_dispatch+0x393>
            print_trapframe(tf);
  102147:	8b 45 08             	mov    0x8(%ebp),%eax
  10214a:	89 04 24             	mov    %eax,(%esp)
  10214d:	e8 0e fa ff ff       	call   101b60 <print_trapframe>
            panic("unexpected trap in kernel.\n");
  102152:	c7 44 24 08 d5 67 10 	movl   $0x1067d5,0x8(%esp)
  102159:	00 
  10215a:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  102161:	00 
  102162:	c7 04 24 f1 67 10 00 	movl   $0x1067f1,(%esp)
  102169:	e8 69 eb ff ff       	call   100cd7 <__panic>
        }
        break;
    case IRQ_OFFSET + IRQ_IDE1:
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
  10216e:	90                   	nop
        if ((tf->tf_cs & 3) == 0) {
            print_trapframe(tf);
            panic("unexpected trap in kernel.\n");
        }
    }
}
  10216f:	81 c4 ac 00 00 00    	add    $0xac,%esp
  102175:	5b                   	pop    %ebx
  102176:	5e                   	pop    %esi
  102177:	5f                   	pop    %edi
  102178:	5d                   	pop    %ebp
  102179:	c3                   	ret    

0010217a <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
  10217a:	55                   	push   %ebp
  10217b:	89 e5                	mov    %esp,%ebp
  10217d:	83 ec 18             	sub    $0x18,%esp
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
  102180:	8b 45 08             	mov    0x8(%ebp),%eax
  102183:	89 04 24             	mov    %eax,(%esp)
  102186:	e8 51 fc ff ff       	call   101ddc <trap_dispatch>
}
  10218b:	c9                   	leave  
  10218c:	c3                   	ret    

0010218d <__alltraps>:
.text
.globl __alltraps
__alltraps:
    # push registers to build a trap frame
    # therefore make the stack look like a struct trapframe
    pushl %ds
  10218d:	1e                   	push   %ds
    pushl %es
  10218e:	06                   	push   %es
    pushl %fs
  10218f:	0f a0                	push   %fs
    pushl %gs
  102191:	0f a8                	push   %gs
    pushal
  102193:	60                   	pusha  

    # load GD_KDATA into %ds and %es to set up data segments for kernel
    movl $GD_KDATA, %eax
  102194:	b8 10 00 00 00       	mov    $0x10,%eax
    movw %ax, %ds
  102199:	8e d8                	mov    %eax,%ds
    movw %ax, %es
  10219b:	8e c0                	mov    %eax,%es

    # push %esp to pass a pointer to the trapframe as an argument to trap()
    pushl %esp
  10219d:	54                   	push   %esp

    # call trap(tf), where tf=%esp
    call trap
  10219e:	e8 d7 ff ff ff       	call   10217a <trap>

    # pop the pushed stack pointer
    popl %esp
  1021a3:	5c                   	pop    %esp

001021a4 <__trapret>:

    # return falls through to trapret...
.globl __trapret
__trapret:
    # restore registers from stack
    popal
  1021a4:	61                   	popa   

    # restore %ds, %es, %fs and %gs
    popl %gs
  1021a5:	0f a9                	pop    %gs
    popl %fs
  1021a7:	0f a1                	pop    %fs
    popl %es
  1021a9:	07                   	pop    %es
    popl %ds
  1021aa:	1f                   	pop    %ds

    # get rid of the trap number and error code
    addl $0x8, %esp
  1021ab:	83 c4 08             	add    $0x8,%esp
    iret
  1021ae:	cf                   	iret   

001021af <vector0>:
# handler
.text
.globl __alltraps
.globl vector0
vector0:
  pushl $0
  1021af:	6a 00                	push   $0x0
  pushl $0
  1021b1:	6a 00                	push   $0x0
  jmp __alltraps
  1021b3:	e9 d5 ff ff ff       	jmp    10218d <__alltraps>

001021b8 <vector1>:
.globl vector1
vector1:
  pushl $0
  1021b8:	6a 00                	push   $0x0
  pushl $1
  1021ba:	6a 01                	push   $0x1
  jmp __alltraps
  1021bc:	e9 cc ff ff ff       	jmp    10218d <__alltraps>

001021c1 <vector2>:
.globl vector2
vector2:
  pushl $0
  1021c1:	6a 00                	push   $0x0
  pushl $2
  1021c3:	6a 02                	push   $0x2
  jmp __alltraps
  1021c5:	e9 c3 ff ff ff       	jmp    10218d <__alltraps>

001021ca <vector3>:
.globl vector3
vector3:
  pushl $0
  1021ca:	6a 00                	push   $0x0
  pushl $3
  1021cc:	6a 03                	push   $0x3
  jmp __alltraps
  1021ce:	e9 ba ff ff ff       	jmp    10218d <__alltraps>

001021d3 <vector4>:
.globl vector4
vector4:
  pushl $0
  1021d3:	6a 00                	push   $0x0
  pushl $4
  1021d5:	6a 04                	push   $0x4
  jmp __alltraps
  1021d7:	e9 b1 ff ff ff       	jmp    10218d <__alltraps>

001021dc <vector5>:
.globl vector5
vector5:
  pushl $0
  1021dc:	6a 00                	push   $0x0
  pushl $5
  1021de:	6a 05                	push   $0x5
  jmp __alltraps
  1021e0:	e9 a8 ff ff ff       	jmp    10218d <__alltraps>

001021e5 <vector6>:
.globl vector6
vector6:
  pushl $0
  1021e5:	6a 00                	push   $0x0
  pushl $6
  1021e7:	6a 06                	push   $0x6
  jmp __alltraps
  1021e9:	e9 9f ff ff ff       	jmp    10218d <__alltraps>

001021ee <vector7>:
.globl vector7
vector7:
  pushl $0
  1021ee:	6a 00                	push   $0x0
  pushl $7
  1021f0:	6a 07                	push   $0x7
  jmp __alltraps
  1021f2:	e9 96 ff ff ff       	jmp    10218d <__alltraps>

001021f7 <vector8>:
.globl vector8
vector8:
  pushl $8
  1021f7:	6a 08                	push   $0x8
  jmp __alltraps
  1021f9:	e9 8f ff ff ff       	jmp    10218d <__alltraps>

001021fe <vector9>:
.globl vector9
vector9:
  pushl $0
  1021fe:	6a 00                	push   $0x0
  pushl $9
  102200:	6a 09                	push   $0x9
  jmp __alltraps
  102202:	e9 86 ff ff ff       	jmp    10218d <__alltraps>

00102207 <vector10>:
.globl vector10
vector10:
  pushl $10
  102207:	6a 0a                	push   $0xa
  jmp __alltraps
  102209:	e9 7f ff ff ff       	jmp    10218d <__alltraps>

0010220e <vector11>:
.globl vector11
vector11:
  pushl $11
  10220e:	6a 0b                	push   $0xb
  jmp __alltraps
  102210:	e9 78 ff ff ff       	jmp    10218d <__alltraps>

00102215 <vector12>:
.globl vector12
vector12:
  pushl $12
  102215:	6a 0c                	push   $0xc
  jmp __alltraps
  102217:	e9 71 ff ff ff       	jmp    10218d <__alltraps>

0010221c <vector13>:
.globl vector13
vector13:
  pushl $13
  10221c:	6a 0d                	push   $0xd
  jmp __alltraps
  10221e:	e9 6a ff ff ff       	jmp    10218d <__alltraps>

00102223 <vector14>:
.globl vector14
vector14:
  pushl $14
  102223:	6a 0e                	push   $0xe
  jmp __alltraps
  102225:	e9 63 ff ff ff       	jmp    10218d <__alltraps>

0010222a <vector15>:
.globl vector15
vector15:
  pushl $0
  10222a:	6a 00                	push   $0x0
  pushl $15
  10222c:	6a 0f                	push   $0xf
  jmp __alltraps
  10222e:	e9 5a ff ff ff       	jmp    10218d <__alltraps>

00102233 <vector16>:
.globl vector16
vector16:
  pushl $0
  102233:	6a 00                	push   $0x0
  pushl $16
  102235:	6a 10                	push   $0x10
  jmp __alltraps
  102237:	e9 51 ff ff ff       	jmp    10218d <__alltraps>

0010223c <vector17>:
.globl vector17
vector17:
  pushl $17
  10223c:	6a 11                	push   $0x11
  jmp __alltraps
  10223e:	e9 4a ff ff ff       	jmp    10218d <__alltraps>

00102243 <vector18>:
.globl vector18
vector18:
  pushl $0
  102243:	6a 00                	push   $0x0
  pushl $18
  102245:	6a 12                	push   $0x12
  jmp __alltraps
  102247:	e9 41 ff ff ff       	jmp    10218d <__alltraps>

0010224c <vector19>:
.globl vector19
vector19:
  pushl $0
  10224c:	6a 00                	push   $0x0
  pushl $19
  10224e:	6a 13                	push   $0x13
  jmp __alltraps
  102250:	e9 38 ff ff ff       	jmp    10218d <__alltraps>

00102255 <vector20>:
.globl vector20
vector20:
  pushl $0
  102255:	6a 00                	push   $0x0
  pushl $20
  102257:	6a 14                	push   $0x14
  jmp __alltraps
  102259:	e9 2f ff ff ff       	jmp    10218d <__alltraps>

0010225e <vector21>:
.globl vector21
vector21:
  pushl $0
  10225e:	6a 00                	push   $0x0
  pushl $21
  102260:	6a 15                	push   $0x15
  jmp __alltraps
  102262:	e9 26 ff ff ff       	jmp    10218d <__alltraps>

00102267 <vector22>:
.globl vector22
vector22:
  pushl $0
  102267:	6a 00                	push   $0x0
  pushl $22
  102269:	6a 16                	push   $0x16
  jmp __alltraps
  10226b:	e9 1d ff ff ff       	jmp    10218d <__alltraps>

00102270 <vector23>:
.globl vector23
vector23:
  pushl $0
  102270:	6a 00                	push   $0x0
  pushl $23
  102272:	6a 17                	push   $0x17
  jmp __alltraps
  102274:	e9 14 ff ff ff       	jmp    10218d <__alltraps>

00102279 <vector24>:
.globl vector24
vector24:
  pushl $0
  102279:	6a 00                	push   $0x0
  pushl $24
  10227b:	6a 18                	push   $0x18
  jmp __alltraps
  10227d:	e9 0b ff ff ff       	jmp    10218d <__alltraps>

00102282 <vector25>:
.globl vector25
vector25:
  pushl $0
  102282:	6a 00                	push   $0x0
  pushl $25
  102284:	6a 19                	push   $0x19
  jmp __alltraps
  102286:	e9 02 ff ff ff       	jmp    10218d <__alltraps>

0010228b <vector26>:
.globl vector26
vector26:
  pushl $0
  10228b:	6a 00                	push   $0x0
  pushl $26
  10228d:	6a 1a                	push   $0x1a
  jmp __alltraps
  10228f:	e9 f9 fe ff ff       	jmp    10218d <__alltraps>

00102294 <vector27>:
.globl vector27
vector27:
  pushl $0
  102294:	6a 00                	push   $0x0
  pushl $27
  102296:	6a 1b                	push   $0x1b
  jmp __alltraps
  102298:	e9 f0 fe ff ff       	jmp    10218d <__alltraps>

0010229d <vector28>:
.globl vector28
vector28:
  pushl $0
  10229d:	6a 00                	push   $0x0
  pushl $28
  10229f:	6a 1c                	push   $0x1c
  jmp __alltraps
  1022a1:	e9 e7 fe ff ff       	jmp    10218d <__alltraps>

001022a6 <vector29>:
.globl vector29
vector29:
  pushl $0
  1022a6:	6a 00                	push   $0x0
  pushl $29
  1022a8:	6a 1d                	push   $0x1d
  jmp __alltraps
  1022aa:	e9 de fe ff ff       	jmp    10218d <__alltraps>

001022af <vector30>:
.globl vector30
vector30:
  pushl $0
  1022af:	6a 00                	push   $0x0
  pushl $30
  1022b1:	6a 1e                	push   $0x1e
  jmp __alltraps
  1022b3:	e9 d5 fe ff ff       	jmp    10218d <__alltraps>

001022b8 <vector31>:
.globl vector31
vector31:
  pushl $0
  1022b8:	6a 00                	push   $0x0
  pushl $31
  1022ba:	6a 1f                	push   $0x1f
  jmp __alltraps
  1022bc:	e9 cc fe ff ff       	jmp    10218d <__alltraps>

001022c1 <vector32>:
.globl vector32
vector32:
  pushl $0
  1022c1:	6a 00                	push   $0x0
  pushl $32
  1022c3:	6a 20                	push   $0x20
  jmp __alltraps
  1022c5:	e9 c3 fe ff ff       	jmp    10218d <__alltraps>

001022ca <vector33>:
.globl vector33
vector33:
  pushl $0
  1022ca:	6a 00                	push   $0x0
  pushl $33
  1022cc:	6a 21                	push   $0x21
  jmp __alltraps
  1022ce:	e9 ba fe ff ff       	jmp    10218d <__alltraps>

001022d3 <vector34>:
.globl vector34
vector34:
  pushl $0
  1022d3:	6a 00                	push   $0x0
  pushl $34
  1022d5:	6a 22                	push   $0x22
  jmp __alltraps
  1022d7:	e9 b1 fe ff ff       	jmp    10218d <__alltraps>

001022dc <vector35>:
.globl vector35
vector35:
  pushl $0
  1022dc:	6a 00                	push   $0x0
  pushl $35
  1022de:	6a 23                	push   $0x23
  jmp __alltraps
  1022e0:	e9 a8 fe ff ff       	jmp    10218d <__alltraps>

001022e5 <vector36>:
.globl vector36
vector36:
  pushl $0
  1022e5:	6a 00                	push   $0x0
  pushl $36
  1022e7:	6a 24                	push   $0x24
  jmp __alltraps
  1022e9:	e9 9f fe ff ff       	jmp    10218d <__alltraps>

001022ee <vector37>:
.globl vector37
vector37:
  pushl $0
  1022ee:	6a 00                	push   $0x0
  pushl $37
  1022f0:	6a 25                	push   $0x25
  jmp __alltraps
  1022f2:	e9 96 fe ff ff       	jmp    10218d <__alltraps>

001022f7 <vector38>:
.globl vector38
vector38:
  pushl $0
  1022f7:	6a 00                	push   $0x0
  pushl $38
  1022f9:	6a 26                	push   $0x26
  jmp __alltraps
  1022fb:	e9 8d fe ff ff       	jmp    10218d <__alltraps>

00102300 <vector39>:
.globl vector39
vector39:
  pushl $0
  102300:	6a 00                	push   $0x0
  pushl $39
  102302:	6a 27                	push   $0x27
  jmp __alltraps
  102304:	e9 84 fe ff ff       	jmp    10218d <__alltraps>

00102309 <vector40>:
.globl vector40
vector40:
  pushl $0
  102309:	6a 00                	push   $0x0
  pushl $40
  10230b:	6a 28                	push   $0x28
  jmp __alltraps
  10230d:	e9 7b fe ff ff       	jmp    10218d <__alltraps>

00102312 <vector41>:
.globl vector41
vector41:
  pushl $0
  102312:	6a 00                	push   $0x0
  pushl $41
  102314:	6a 29                	push   $0x29
  jmp __alltraps
  102316:	e9 72 fe ff ff       	jmp    10218d <__alltraps>

0010231b <vector42>:
.globl vector42
vector42:
  pushl $0
  10231b:	6a 00                	push   $0x0
  pushl $42
  10231d:	6a 2a                	push   $0x2a
  jmp __alltraps
  10231f:	e9 69 fe ff ff       	jmp    10218d <__alltraps>

00102324 <vector43>:
.globl vector43
vector43:
  pushl $0
  102324:	6a 00                	push   $0x0
  pushl $43
  102326:	6a 2b                	push   $0x2b
  jmp __alltraps
  102328:	e9 60 fe ff ff       	jmp    10218d <__alltraps>

0010232d <vector44>:
.globl vector44
vector44:
  pushl $0
  10232d:	6a 00                	push   $0x0
  pushl $44
  10232f:	6a 2c                	push   $0x2c
  jmp __alltraps
  102331:	e9 57 fe ff ff       	jmp    10218d <__alltraps>

00102336 <vector45>:
.globl vector45
vector45:
  pushl $0
  102336:	6a 00                	push   $0x0
  pushl $45
  102338:	6a 2d                	push   $0x2d
  jmp __alltraps
  10233a:	e9 4e fe ff ff       	jmp    10218d <__alltraps>

0010233f <vector46>:
.globl vector46
vector46:
  pushl $0
  10233f:	6a 00                	push   $0x0
  pushl $46
  102341:	6a 2e                	push   $0x2e
  jmp __alltraps
  102343:	e9 45 fe ff ff       	jmp    10218d <__alltraps>

00102348 <vector47>:
.globl vector47
vector47:
  pushl $0
  102348:	6a 00                	push   $0x0
  pushl $47
  10234a:	6a 2f                	push   $0x2f
  jmp __alltraps
  10234c:	e9 3c fe ff ff       	jmp    10218d <__alltraps>

00102351 <vector48>:
.globl vector48
vector48:
  pushl $0
  102351:	6a 00                	push   $0x0
  pushl $48
  102353:	6a 30                	push   $0x30
  jmp __alltraps
  102355:	e9 33 fe ff ff       	jmp    10218d <__alltraps>

0010235a <vector49>:
.globl vector49
vector49:
  pushl $0
  10235a:	6a 00                	push   $0x0
  pushl $49
  10235c:	6a 31                	push   $0x31
  jmp __alltraps
  10235e:	e9 2a fe ff ff       	jmp    10218d <__alltraps>

00102363 <vector50>:
.globl vector50
vector50:
  pushl $0
  102363:	6a 00                	push   $0x0
  pushl $50
  102365:	6a 32                	push   $0x32
  jmp __alltraps
  102367:	e9 21 fe ff ff       	jmp    10218d <__alltraps>

0010236c <vector51>:
.globl vector51
vector51:
  pushl $0
  10236c:	6a 00                	push   $0x0
  pushl $51
  10236e:	6a 33                	push   $0x33
  jmp __alltraps
  102370:	e9 18 fe ff ff       	jmp    10218d <__alltraps>

00102375 <vector52>:
.globl vector52
vector52:
  pushl $0
  102375:	6a 00                	push   $0x0
  pushl $52
  102377:	6a 34                	push   $0x34
  jmp __alltraps
  102379:	e9 0f fe ff ff       	jmp    10218d <__alltraps>

0010237e <vector53>:
.globl vector53
vector53:
  pushl $0
  10237e:	6a 00                	push   $0x0
  pushl $53
  102380:	6a 35                	push   $0x35
  jmp __alltraps
  102382:	e9 06 fe ff ff       	jmp    10218d <__alltraps>

00102387 <vector54>:
.globl vector54
vector54:
  pushl $0
  102387:	6a 00                	push   $0x0
  pushl $54
  102389:	6a 36                	push   $0x36
  jmp __alltraps
  10238b:	e9 fd fd ff ff       	jmp    10218d <__alltraps>

00102390 <vector55>:
.globl vector55
vector55:
  pushl $0
  102390:	6a 00                	push   $0x0
  pushl $55
  102392:	6a 37                	push   $0x37
  jmp __alltraps
  102394:	e9 f4 fd ff ff       	jmp    10218d <__alltraps>

00102399 <vector56>:
.globl vector56
vector56:
  pushl $0
  102399:	6a 00                	push   $0x0
  pushl $56
  10239b:	6a 38                	push   $0x38
  jmp __alltraps
  10239d:	e9 eb fd ff ff       	jmp    10218d <__alltraps>

001023a2 <vector57>:
.globl vector57
vector57:
  pushl $0
  1023a2:	6a 00                	push   $0x0
  pushl $57
  1023a4:	6a 39                	push   $0x39
  jmp __alltraps
  1023a6:	e9 e2 fd ff ff       	jmp    10218d <__alltraps>

001023ab <vector58>:
.globl vector58
vector58:
  pushl $0
  1023ab:	6a 00                	push   $0x0
  pushl $58
  1023ad:	6a 3a                	push   $0x3a
  jmp __alltraps
  1023af:	e9 d9 fd ff ff       	jmp    10218d <__alltraps>

001023b4 <vector59>:
.globl vector59
vector59:
  pushl $0
  1023b4:	6a 00                	push   $0x0
  pushl $59
  1023b6:	6a 3b                	push   $0x3b
  jmp __alltraps
  1023b8:	e9 d0 fd ff ff       	jmp    10218d <__alltraps>

001023bd <vector60>:
.globl vector60
vector60:
  pushl $0
  1023bd:	6a 00                	push   $0x0
  pushl $60
  1023bf:	6a 3c                	push   $0x3c
  jmp __alltraps
  1023c1:	e9 c7 fd ff ff       	jmp    10218d <__alltraps>

001023c6 <vector61>:
.globl vector61
vector61:
  pushl $0
  1023c6:	6a 00                	push   $0x0
  pushl $61
  1023c8:	6a 3d                	push   $0x3d
  jmp __alltraps
  1023ca:	e9 be fd ff ff       	jmp    10218d <__alltraps>

001023cf <vector62>:
.globl vector62
vector62:
  pushl $0
  1023cf:	6a 00                	push   $0x0
  pushl $62
  1023d1:	6a 3e                	push   $0x3e
  jmp __alltraps
  1023d3:	e9 b5 fd ff ff       	jmp    10218d <__alltraps>

001023d8 <vector63>:
.globl vector63
vector63:
  pushl $0
  1023d8:	6a 00                	push   $0x0
  pushl $63
  1023da:	6a 3f                	push   $0x3f
  jmp __alltraps
  1023dc:	e9 ac fd ff ff       	jmp    10218d <__alltraps>

001023e1 <vector64>:
.globl vector64
vector64:
  pushl $0
  1023e1:	6a 00                	push   $0x0
  pushl $64
  1023e3:	6a 40                	push   $0x40
  jmp __alltraps
  1023e5:	e9 a3 fd ff ff       	jmp    10218d <__alltraps>

001023ea <vector65>:
.globl vector65
vector65:
  pushl $0
  1023ea:	6a 00                	push   $0x0
  pushl $65
  1023ec:	6a 41                	push   $0x41
  jmp __alltraps
  1023ee:	e9 9a fd ff ff       	jmp    10218d <__alltraps>

001023f3 <vector66>:
.globl vector66
vector66:
  pushl $0
  1023f3:	6a 00                	push   $0x0
  pushl $66
  1023f5:	6a 42                	push   $0x42
  jmp __alltraps
  1023f7:	e9 91 fd ff ff       	jmp    10218d <__alltraps>

001023fc <vector67>:
.globl vector67
vector67:
  pushl $0
  1023fc:	6a 00                	push   $0x0
  pushl $67
  1023fe:	6a 43                	push   $0x43
  jmp __alltraps
  102400:	e9 88 fd ff ff       	jmp    10218d <__alltraps>

00102405 <vector68>:
.globl vector68
vector68:
  pushl $0
  102405:	6a 00                	push   $0x0
  pushl $68
  102407:	6a 44                	push   $0x44
  jmp __alltraps
  102409:	e9 7f fd ff ff       	jmp    10218d <__alltraps>

0010240e <vector69>:
.globl vector69
vector69:
  pushl $0
  10240e:	6a 00                	push   $0x0
  pushl $69
  102410:	6a 45                	push   $0x45
  jmp __alltraps
  102412:	e9 76 fd ff ff       	jmp    10218d <__alltraps>

00102417 <vector70>:
.globl vector70
vector70:
  pushl $0
  102417:	6a 00                	push   $0x0
  pushl $70
  102419:	6a 46                	push   $0x46
  jmp __alltraps
  10241b:	e9 6d fd ff ff       	jmp    10218d <__alltraps>

00102420 <vector71>:
.globl vector71
vector71:
  pushl $0
  102420:	6a 00                	push   $0x0
  pushl $71
  102422:	6a 47                	push   $0x47
  jmp __alltraps
  102424:	e9 64 fd ff ff       	jmp    10218d <__alltraps>

00102429 <vector72>:
.globl vector72
vector72:
  pushl $0
  102429:	6a 00                	push   $0x0
  pushl $72
  10242b:	6a 48                	push   $0x48
  jmp __alltraps
  10242d:	e9 5b fd ff ff       	jmp    10218d <__alltraps>

00102432 <vector73>:
.globl vector73
vector73:
  pushl $0
  102432:	6a 00                	push   $0x0
  pushl $73
  102434:	6a 49                	push   $0x49
  jmp __alltraps
  102436:	e9 52 fd ff ff       	jmp    10218d <__alltraps>

0010243b <vector74>:
.globl vector74
vector74:
  pushl $0
  10243b:	6a 00                	push   $0x0
  pushl $74
  10243d:	6a 4a                	push   $0x4a
  jmp __alltraps
  10243f:	e9 49 fd ff ff       	jmp    10218d <__alltraps>

00102444 <vector75>:
.globl vector75
vector75:
  pushl $0
  102444:	6a 00                	push   $0x0
  pushl $75
  102446:	6a 4b                	push   $0x4b
  jmp __alltraps
  102448:	e9 40 fd ff ff       	jmp    10218d <__alltraps>

0010244d <vector76>:
.globl vector76
vector76:
  pushl $0
  10244d:	6a 00                	push   $0x0
  pushl $76
  10244f:	6a 4c                	push   $0x4c
  jmp __alltraps
  102451:	e9 37 fd ff ff       	jmp    10218d <__alltraps>

00102456 <vector77>:
.globl vector77
vector77:
  pushl $0
  102456:	6a 00                	push   $0x0
  pushl $77
  102458:	6a 4d                	push   $0x4d
  jmp __alltraps
  10245a:	e9 2e fd ff ff       	jmp    10218d <__alltraps>

0010245f <vector78>:
.globl vector78
vector78:
  pushl $0
  10245f:	6a 00                	push   $0x0
  pushl $78
  102461:	6a 4e                	push   $0x4e
  jmp __alltraps
  102463:	e9 25 fd ff ff       	jmp    10218d <__alltraps>

00102468 <vector79>:
.globl vector79
vector79:
  pushl $0
  102468:	6a 00                	push   $0x0
  pushl $79
  10246a:	6a 4f                	push   $0x4f
  jmp __alltraps
  10246c:	e9 1c fd ff ff       	jmp    10218d <__alltraps>

00102471 <vector80>:
.globl vector80
vector80:
  pushl $0
  102471:	6a 00                	push   $0x0
  pushl $80
  102473:	6a 50                	push   $0x50
  jmp __alltraps
  102475:	e9 13 fd ff ff       	jmp    10218d <__alltraps>

0010247a <vector81>:
.globl vector81
vector81:
  pushl $0
  10247a:	6a 00                	push   $0x0
  pushl $81
  10247c:	6a 51                	push   $0x51
  jmp __alltraps
  10247e:	e9 0a fd ff ff       	jmp    10218d <__alltraps>

00102483 <vector82>:
.globl vector82
vector82:
  pushl $0
  102483:	6a 00                	push   $0x0
  pushl $82
  102485:	6a 52                	push   $0x52
  jmp __alltraps
  102487:	e9 01 fd ff ff       	jmp    10218d <__alltraps>

0010248c <vector83>:
.globl vector83
vector83:
  pushl $0
  10248c:	6a 00                	push   $0x0
  pushl $83
  10248e:	6a 53                	push   $0x53
  jmp __alltraps
  102490:	e9 f8 fc ff ff       	jmp    10218d <__alltraps>

00102495 <vector84>:
.globl vector84
vector84:
  pushl $0
  102495:	6a 00                	push   $0x0
  pushl $84
  102497:	6a 54                	push   $0x54
  jmp __alltraps
  102499:	e9 ef fc ff ff       	jmp    10218d <__alltraps>

0010249e <vector85>:
.globl vector85
vector85:
  pushl $0
  10249e:	6a 00                	push   $0x0
  pushl $85
  1024a0:	6a 55                	push   $0x55
  jmp __alltraps
  1024a2:	e9 e6 fc ff ff       	jmp    10218d <__alltraps>

001024a7 <vector86>:
.globl vector86
vector86:
  pushl $0
  1024a7:	6a 00                	push   $0x0
  pushl $86
  1024a9:	6a 56                	push   $0x56
  jmp __alltraps
  1024ab:	e9 dd fc ff ff       	jmp    10218d <__alltraps>

001024b0 <vector87>:
.globl vector87
vector87:
  pushl $0
  1024b0:	6a 00                	push   $0x0
  pushl $87
  1024b2:	6a 57                	push   $0x57
  jmp __alltraps
  1024b4:	e9 d4 fc ff ff       	jmp    10218d <__alltraps>

001024b9 <vector88>:
.globl vector88
vector88:
  pushl $0
  1024b9:	6a 00                	push   $0x0
  pushl $88
  1024bb:	6a 58                	push   $0x58
  jmp __alltraps
  1024bd:	e9 cb fc ff ff       	jmp    10218d <__alltraps>

001024c2 <vector89>:
.globl vector89
vector89:
  pushl $0
  1024c2:	6a 00                	push   $0x0
  pushl $89
  1024c4:	6a 59                	push   $0x59
  jmp __alltraps
  1024c6:	e9 c2 fc ff ff       	jmp    10218d <__alltraps>

001024cb <vector90>:
.globl vector90
vector90:
  pushl $0
  1024cb:	6a 00                	push   $0x0
  pushl $90
  1024cd:	6a 5a                	push   $0x5a
  jmp __alltraps
  1024cf:	e9 b9 fc ff ff       	jmp    10218d <__alltraps>

001024d4 <vector91>:
.globl vector91
vector91:
  pushl $0
  1024d4:	6a 00                	push   $0x0
  pushl $91
  1024d6:	6a 5b                	push   $0x5b
  jmp __alltraps
  1024d8:	e9 b0 fc ff ff       	jmp    10218d <__alltraps>

001024dd <vector92>:
.globl vector92
vector92:
  pushl $0
  1024dd:	6a 00                	push   $0x0
  pushl $92
  1024df:	6a 5c                	push   $0x5c
  jmp __alltraps
  1024e1:	e9 a7 fc ff ff       	jmp    10218d <__alltraps>

001024e6 <vector93>:
.globl vector93
vector93:
  pushl $0
  1024e6:	6a 00                	push   $0x0
  pushl $93
  1024e8:	6a 5d                	push   $0x5d
  jmp __alltraps
  1024ea:	e9 9e fc ff ff       	jmp    10218d <__alltraps>

001024ef <vector94>:
.globl vector94
vector94:
  pushl $0
  1024ef:	6a 00                	push   $0x0
  pushl $94
  1024f1:	6a 5e                	push   $0x5e
  jmp __alltraps
  1024f3:	e9 95 fc ff ff       	jmp    10218d <__alltraps>

001024f8 <vector95>:
.globl vector95
vector95:
  pushl $0
  1024f8:	6a 00                	push   $0x0
  pushl $95
  1024fa:	6a 5f                	push   $0x5f
  jmp __alltraps
  1024fc:	e9 8c fc ff ff       	jmp    10218d <__alltraps>

00102501 <vector96>:
.globl vector96
vector96:
  pushl $0
  102501:	6a 00                	push   $0x0
  pushl $96
  102503:	6a 60                	push   $0x60
  jmp __alltraps
  102505:	e9 83 fc ff ff       	jmp    10218d <__alltraps>

0010250a <vector97>:
.globl vector97
vector97:
  pushl $0
  10250a:	6a 00                	push   $0x0
  pushl $97
  10250c:	6a 61                	push   $0x61
  jmp __alltraps
  10250e:	e9 7a fc ff ff       	jmp    10218d <__alltraps>

00102513 <vector98>:
.globl vector98
vector98:
  pushl $0
  102513:	6a 00                	push   $0x0
  pushl $98
  102515:	6a 62                	push   $0x62
  jmp __alltraps
  102517:	e9 71 fc ff ff       	jmp    10218d <__alltraps>

0010251c <vector99>:
.globl vector99
vector99:
  pushl $0
  10251c:	6a 00                	push   $0x0
  pushl $99
  10251e:	6a 63                	push   $0x63
  jmp __alltraps
  102520:	e9 68 fc ff ff       	jmp    10218d <__alltraps>

00102525 <vector100>:
.globl vector100
vector100:
  pushl $0
  102525:	6a 00                	push   $0x0
  pushl $100
  102527:	6a 64                	push   $0x64
  jmp __alltraps
  102529:	e9 5f fc ff ff       	jmp    10218d <__alltraps>

0010252e <vector101>:
.globl vector101
vector101:
  pushl $0
  10252e:	6a 00                	push   $0x0
  pushl $101
  102530:	6a 65                	push   $0x65
  jmp __alltraps
  102532:	e9 56 fc ff ff       	jmp    10218d <__alltraps>

00102537 <vector102>:
.globl vector102
vector102:
  pushl $0
  102537:	6a 00                	push   $0x0
  pushl $102
  102539:	6a 66                	push   $0x66
  jmp __alltraps
  10253b:	e9 4d fc ff ff       	jmp    10218d <__alltraps>

00102540 <vector103>:
.globl vector103
vector103:
  pushl $0
  102540:	6a 00                	push   $0x0
  pushl $103
  102542:	6a 67                	push   $0x67
  jmp __alltraps
  102544:	e9 44 fc ff ff       	jmp    10218d <__alltraps>

00102549 <vector104>:
.globl vector104
vector104:
  pushl $0
  102549:	6a 00                	push   $0x0
  pushl $104
  10254b:	6a 68                	push   $0x68
  jmp __alltraps
  10254d:	e9 3b fc ff ff       	jmp    10218d <__alltraps>

00102552 <vector105>:
.globl vector105
vector105:
  pushl $0
  102552:	6a 00                	push   $0x0
  pushl $105
  102554:	6a 69                	push   $0x69
  jmp __alltraps
  102556:	e9 32 fc ff ff       	jmp    10218d <__alltraps>

0010255b <vector106>:
.globl vector106
vector106:
  pushl $0
  10255b:	6a 00                	push   $0x0
  pushl $106
  10255d:	6a 6a                	push   $0x6a
  jmp __alltraps
  10255f:	e9 29 fc ff ff       	jmp    10218d <__alltraps>

00102564 <vector107>:
.globl vector107
vector107:
  pushl $0
  102564:	6a 00                	push   $0x0
  pushl $107
  102566:	6a 6b                	push   $0x6b
  jmp __alltraps
  102568:	e9 20 fc ff ff       	jmp    10218d <__alltraps>

0010256d <vector108>:
.globl vector108
vector108:
  pushl $0
  10256d:	6a 00                	push   $0x0
  pushl $108
  10256f:	6a 6c                	push   $0x6c
  jmp __alltraps
  102571:	e9 17 fc ff ff       	jmp    10218d <__alltraps>

00102576 <vector109>:
.globl vector109
vector109:
  pushl $0
  102576:	6a 00                	push   $0x0
  pushl $109
  102578:	6a 6d                	push   $0x6d
  jmp __alltraps
  10257a:	e9 0e fc ff ff       	jmp    10218d <__alltraps>

0010257f <vector110>:
.globl vector110
vector110:
  pushl $0
  10257f:	6a 00                	push   $0x0
  pushl $110
  102581:	6a 6e                	push   $0x6e
  jmp __alltraps
  102583:	e9 05 fc ff ff       	jmp    10218d <__alltraps>

00102588 <vector111>:
.globl vector111
vector111:
  pushl $0
  102588:	6a 00                	push   $0x0
  pushl $111
  10258a:	6a 6f                	push   $0x6f
  jmp __alltraps
  10258c:	e9 fc fb ff ff       	jmp    10218d <__alltraps>

00102591 <vector112>:
.globl vector112
vector112:
  pushl $0
  102591:	6a 00                	push   $0x0
  pushl $112
  102593:	6a 70                	push   $0x70
  jmp __alltraps
  102595:	e9 f3 fb ff ff       	jmp    10218d <__alltraps>

0010259a <vector113>:
.globl vector113
vector113:
  pushl $0
  10259a:	6a 00                	push   $0x0
  pushl $113
  10259c:	6a 71                	push   $0x71
  jmp __alltraps
  10259e:	e9 ea fb ff ff       	jmp    10218d <__alltraps>

001025a3 <vector114>:
.globl vector114
vector114:
  pushl $0
  1025a3:	6a 00                	push   $0x0
  pushl $114
  1025a5:	6a 72                	push   $0x72
  jmp __alltraps
  1025a7:	e9 e1 fb ff ff       	jmp    10218d <__alltraps>

001025ac <vector115>:
.globl vector115
vector115:
  pushl $0
  1025ac:	6a 00                	push   $0x0
  pushl $115
  1025ae:	6a 73                	push   $0x73
  jmp __alltraps
  1025b0:	e9 d8 fb ff ff       	jmp    10218d <__alltraps>

001025b5 <vector116>:
.globl vector116
vector116:
  pushl $0
  1025b5:	6a 00                	push   $0x0
  pushl $116
  1025b7:	6a 74                	push   $0x74
  jmp __alltraps
  1025b9:	e9 cf fb ff ff       	jmp    10218d <__alltraps>

001025be <vector117>:
.globl vector117
vector117:
  pushl $0
  1025be:	6a 00                	push   $0x0
  pushl $117
  1025c0:	6a 75                	push   $0x75
  jmp __alltraps
  1025c2:	e9 c6 fb ff ff       	jmp    10218d <__alltraps>

001025c7 <vector118>:
.globl vector118
vector118:
  pushl $0
  1025c7:	6a 00                	push   $0x0
  pushl $118
  1025c9:	6a 76                	push   $0x76
  jmp __alltraps
  1025cb:	e9 bd fb ff ff       	jmp    10218d <__alltraps>

001025d0 <vector119>:
.globl vector119
vector119:
  pushl $0
  1025d0:	6a 00                	push   $0x0
  pushl $119
  1025d2:	6a 77                	push   $0x77
  jmp __alltraps
  1025d4:	e9 b4 fb ff ff       	jmp    10218d <__alltraps>

001025d9 <vector120>:
.globl vector120
vector120:
  pushl $0
  1025d9:	6a 00                	push   $0x0
  pushl $120
  1025db:	6a 78                	push   $0x78
  jmp __alltraps
  1025dd:	e9 ab fb ff ff       	jmp    10218d <__alltraps>

001025e2 <vector121>:
.globl vector121
vector121:
  pushl $0
  1025e2:	6a 00                	push   $0x0
  pushl $121
  1025e4:	6a 79                	push   $0x79
  jmp __alltraps
  1025e6:	e9 a2 fb ff ff       	jmp    10218d <__alltraps>

001025eb <vector122>:
.globl vector122
vector122:
  pushl $0
  1025eb:	6a 00                	push   $0x0
  pushl $122
  1025ed:	6a 7a                	push   $0x7a
  jmp __alltraps
  1025ef:	e9 99 fb ff ff       	jmp    10218d <__alltraps>

001025f4 <vector123>:
.globl vector123
vector123:
  pushl $0
  1025f4:	6a 00                	push   $0x0
  pushl $123
  1025f6:	6a 7b                	push   $0x7b
  jmp __alltraps
  1025f8:	e9 90 fb ff ff       	jmp    10218d <__alltraps>

001025fd <vector124>:
.globl vector124
vector124:
  pushl $0
  1025fd:	6a 00                	push   $0x0
  pushl $124
  1025ff:	6a 7c                	push   $0x7c
  jmp __alltraps
  102601:	e9 87 fb ff ff       	jmp    10218d <__alltraps>

00102606 <vector125>:
.globl vector125
vector125:
  pushl $0
  102606:	6a 00                	push   $0x0
  pushl $125
  102608:	6a 7d                	push   $0x7d
  jmp __alltraps
  10260a:	e9 7e fb ff ff       	jmp    10218d <__alltraps>

0010260f <vector126>:
.globl vector126
vector126:
  pushl $0
  10260f:	6a 00                	push   $0x0
  pushl $126
  102611:	6a 7e                	push   $0x7e
  jmp __alltraps
  102613:	e9 75 fb ff ff       	jmp    10218d <__alltraps>

00102618 <vector127>:
.globl vector127
vector127:
  pushl $0
  102618:	6a 00                	push   $0x0
  pushl $127
  10261a:	6a 7f                	push   $0x7f
  jmp __alltraps
  10261c:	e9 6c fb ff ff       	jmp    10218d <__alltraps>

00102621 <vector128>:
.globl vector128
vector128:
  pushl $0
  102621:	6a 00                	push   $0x0
  pushl $128
  102623:	68 80 00 00 00       	push   $0x80
  jmp __alltraps
  102628:	e9 60 fb ff ff       	jmp    10218d <__alltraps>

0010262d <vector129>:
.globl vector129
vector129:
  pushl $0
  10262d:	6a 00                	push   $0x0
  pushl $129
  10262f:	68 81 00 00 00       	push   $0x81
  jmp __alltraps
  102634:	e9 54 fb ff ff       	jmp    10218d <__alltraps>

00102639 <vector130>:
.globl vector130
vector130:
  pushl $0
  102639:	6a 00                	push   $0x0
  pushl $130
  10263b:	68 82 00 00 00       	push   $0x82
  jmp __alltraps
  102640:	e9 48 fb ff ff       	jmp    10218d <__alltraps>

00102645 <vector131>:
.globl vector131
vector131:
  pushl $0
  102645:	6a 00                	push   $0x0
  pushl $131
  102647:	68 83 00 00 00       	push   $0x83
  jmp __alltraps
  10264c:	e9 3c fb ff ff       	jmp    10218d <__alltraps>

00102651 <vector132>:
.globl vector132
vector132:
  pushl $0
  102651:	6a 00                	push   $0x0
  pushl $132
  102653:	68 84 00 00 00       	push   $0x84
  jmp __alltraps
  102658:	e9 30 fb ff ff       	jmp    10218d <__alltraps>

0010265d <vector133>:
.globl vector133
vector133:
  pushl $0
  10265d:	6a 00                	push   $0x0
  pushl $133
  10265f:	68 85 00 00 00       	push   $0x85
  jmp __alltraps
  102664:	e9 24 fb ff ff       	jmp    10218d <__alltraps>

00102669 <vector134>:
.globl vector134
vector134:
  pushl $0
  102669:	6a 00                	push   $0x0
  pushl $134
  10266b:	68 86 00 00 00       	push   $0x86
  jmp __alltraps
  102670:	e9 18 fb ff ff       	jmp    10218d <__alltraps>

00102675 <vector135>:
.globl vector135
vector135:
  pushl $0
  102675:	6a 00                	push   $0x0
  pushl $135
  102677:	68 87 00 00 00       	push   $0x87
  jmp __alltraps
  10267c:	e9 0c fb ff ff       	jmp    10218d <__alltraps>

00102681 <vector136>:
.globl vector136
vector136:
  pushl $0
  102681:	6a 00                	push   $0x0
  pushl $136
  102683:	68 88 00 00 00       	push   $0x88
  jmp __alltraps
  102688:	e9 00 fb ff ff       	jmp    10218d <__alltraps>

0010268d <vector137>:
.globl vector137
vector137:
  pushl $0
  10268d:	6a 00                	push   $0x0
  pushl $137
  10268f:	68 89 00 00 00       	push   $0x89
  jmp __alltraps
  102694:	e9 f4 fa ff ff       	jmp    10218d <__alltraps>

00102699 <vector138>:
.globl vector138
vector138:
  pushl $0
  102699:	6a 00                	push   $0x0
  pushl $138
  10269b:	68 8a 00 00 00       	push   $0x8a
  jmp __alltraps
  1026a0:	e9 e8 fa ff ff       	jmp    10218d <__alltraps>

001026a5 <vector139>:
.globl vector139
vector139:
  pushl $0
  1026a5:	6a 00                	push   $0x0
  pushl $139
  1026a7:	68 8b 00 00 00       	push   $0x8b
  jmp __alltraps
  1026ac:	e9 dc fa ff ff       	jmp    10218d <__alltraps>

001026b1 <vector140>:
.globl vector140
vector140:
  pushl $0
  1026b1:	6a 00                	push   $0x0
  pushl $140
  1026b3:	68 8c 00 00 00       	push   $0x8c
  jmp __alltraps
  1026b8:	e9 d0 fa ff ff       	jmp    10218d <__alltraps>

001026bd <vector141>:
.globl vector141
vector141:
  pushl $0
  1026bd:	6a 00                	push   $0x0
  pushl $141
  1026bf:	68 8d 00 00 00       	push   $0x8d
  jmp __alltraps
  1026c4:	e9 c4 fa ff ff       	jmp    10218d <__alltraps>

001026c9 <vector142>:
.globl vector142
vector142:
  pushl $0
  1026c9:	6a 00                	push   $0x0
  pushl $142
  1026cb:	68 8e 00 00 00       	push   $0x8e
  jmp __alltraps
  1026d0:	e9 b8 fa ff ff       	jmp    10218d <__alltraps>

001026d5 <vector143>:
.globl vector143
vector143:
  pushl $0
  1026d5:	6a 00                	push   $0x0
  pushl $143
  1026d7:	68 8f 00 00 00       	push   $0x8f
  jmp __alltraps
  1026dc:	e9 ac fa ff ff       	jmp    10218d <__alltraps>

001026e1 <vector144>:
.globl vector144
vector144:
  pushl $0
  1026e1:	6a 00                	push   $0x0
  pushl $144
  1026e3:	68 90 00 00 00       	push   $0x90
  jmp __alltraps
  1026e8:	e9 a0 fa ff ff       	jmp    10218d <__alltraps>

001026ed <vector145>:
.globl vector145
vector145:
  pushl $0
  1026ed:	6a 00                	push   $0x0
  pushl $145
  1026ef:	68 91 00 00 00       	push   $0x91
  jmp __alltraps
  1026f4:	e9 94 fa ff ff       	jmp    10218d <__alltraps>

001026f9 <vector146>:
.globl vector146
vector146:
  pushl $0
  1026f9:	6a 00                	push   $0x0
  pushl $146
  1026fb:	68 92 00 00 00       	push   $0x92
  jmp __alltraps
  102700:	e9 88 fa ff ff       	jmp    10218d <__alltraps>

00102705 <vector147>:
.globl vector147
vector147:
  pushl $0
  102705:	6a 00                	push   $0x0
  pushl $147
  102707:	68 93 00 00 00       	push   $0x93
  jmp __alltraps
  10270c:	e9 7c fa ff ff       	jmp    10218d <__alltraps>

00102711 <vector148>:
.globl vector148
vector148:
  pushl $0
  102711:	6a 00                	push   $0x0
  pushl $148
  102713:	68 94 00 00 00       	push   $0x94
  jmp __alltraps
  102718:	e9 70 fa ff ff       	jmp    10218d <__alltraps>

0010271d <vector149>:
.globl vector149
vector149:
  pushl $0
  10271d:	6a 00                	push   $0x0
  pushl $149
  10271f:	68 95 00 00 00       	push   $0x95
  jmp __alltraps
  102724:	e9 64 fa ff ff       	jmp    10218d <__alltraps>

00102729 <vector150>:
.globl vector150
vector150:
  pushl $0
  102729:	6a 00                	push   $0x0
  pushl $150
  10272b:	68 96 00 00 00       	push   $0x96
  jmp __alltraps
  102730:	e9 58 fa ff ff       	jmp    10218d <__alltraps>

00102735 <vector151>:
.globl vector151
vector151:
  pushl $0
  102735:	6a 00                	push   $0x0
  pushl $151
  102737:	68 97 00 00 00       	push   $0x97
  jmp __alltraps
  10273c:	e9 4c fa ff ff       	jmp    10218d <__alltraps>

00102741 <vector152>:
.globl vector152
vector152:
  pushl $0
  102741:	6a 00                	push   $0x0
  pushl $152
  102743:	68 98 00 00 00       	push   $0x98
  jmp __alltraps
  102748:	e9 40 fa ff ff       	jmp    10218d <__alltraps>

0010274d <vector153>:
.globl vector153
vector153:
  pushl $0
  10274d:	6a 00                	push   $0x0
  pushl $153
  10274f:	68 99 00 00 00       	push   $0x99
  jmp __alltraps
  102754:	e9 34 fa ff ff       	jmp    10218d <__alltraps>

00102759 <vector154>:
.globl vector154
vector154:
  pushl $0
  102759:	6a 00                	push   $0x0
  pushl $154
  10275b:	68 9a 00 00 00       	push   $0x9a
  jmp __alltraps
  102760:	e9 28 fa ff ff       	jmp    10218d <__alltraps>

00102765 <vector155>:
.globl vector155
vector155:
  pushl $0
  102765:	6a 00                	push   $0x0
  pushl $155
  102767:	68 9b 00 00 00       	push   $0x9b
  jmp __alltraps
  10276c:	e9 1c fa ff ff       	jmp    10218d <__alltraps>

00102771 <vector156>:
.globl vector156
vector156:
  pushl $0
  102771:	6a 00                	push   $0x0
  pushl $156
  102773:	68 9c 00 00 00       	push   $0x9c
  jmp __alltraps
  102778:	e9 10 fa ff ff       	jmp    10218d <__alltraps>

0010277d <vector157>:
.globl vector157
vector157:
  pushl $0
  10277d:	6a 00                	push   $0x0
  pushl $157
  10277f:	68 9d 00 00 00       	push   $0x9d
  jmp __alltraps
  102784:	e9 04 fa ff ff       	jmp    10218d <__alltraps>

00102789 <vector158>:
.globl vector158
vector158:
  pushl $0
  102789:	6a 00                	push   $0x0
  pushl $158
  10278b:	68 9e 00 00 00       	push   $0x9e
  jmp __alltraps
  102790:	e9 f8 f9 ff ff       	jmp    10218d <__alltraps>

00102795 <vector159>:
.globl vector159
vector159:
  pushl $0
  102795:	6a 00                	push   $0x0
  pushl $159
  102797:	68 9f 00 00 00       	push   $0x9f
  jmp __alltraps
  10279c:	e9 ec f9 ff ff       	jmp    10218d <__alltraps>

001027a1 <vector160>:
.globl vector160
vector160:
  pushl $0
  1027a1:	6a 00                	push   $0x0
  pushl $160
  1027a3:	68 a0 00 00 00       	push   $0xa0
  jmp __alltraps
  1027a8:	e9 e0 f9 ff ff       	jmp    10218d <__alltraps>

001027ad <vector161>:
.globl vector161
vector161:
  pushl $0
  1027ad:	6a 00                	push   $0x0
  pushl $161
  1027af:	68 a1 00 00 00       	push   $0xa1
  jmp __alltraps
  1027b4:	e9 d4 f9 ff ff       	jmp    10218d <__alltraps>

001027b9 <vector162>:
.globl vector162
vector162:
  pushl $0
  1027b9:	6a 00                	push   $0x0
  pushl $162
  1027bb:	68 a2 00 00 00       	push   $0xa2
  jmp __alltraps
  1027c0:	e9 c8 f9 ff ff       	jmp    10218d <__alltraps>

001027c5 <vector163>:
.globl vector163
vector163:
  pushl $0
  1027c5:	6a 00                	push   $0x0
  pushl $163
  1027c7:	68 a3 00 00 00       	push   $0xa3
  jmp __alltraps
  1027cc:	e9 bc f9 ff ff       	jmp    10218d <__alltraps>

001027d1 <vector164>:
.globl vector164
vector164:
  pushl $0
  1027d1:	6a 00                	push   $0x0
  pushl $164
  1027d3:	68 a4 00 00 00       	push   $0xa4
  jmp __alltraps
  1027d8:	e9 b0 f9 ff ff       	jmp    10218d <__alltraps>

001027dd <vector165>:
.globl vector165
vector165:
  pushl $0
  1027dd:	6a 00                	push   $0x0
  pushl $165
  1027df:	68 a5 00 00 00       	push   $0xa5
  jmp __alltraps
  1027e4:	e9 a4 f9 ff ff       	jmp    10218d <__alltraps>

001027e9 <vector166>:
.globl vector166
vector166:
  pushl $0
  1027e9:	6a 00                	push   $0x0
  pushl $166
  1027eb:	68 a6 00 00 00       	push   $0xa6
  jmp __alltraps
  1027f0:	e9 98 f9 ff ff       	jmp    10218d <__alltraps>

001027f5 <vector167>:
.globl vector167
vector167:
  pushl $0
  1027f5:	6a 00                	push   $0x0
  pushl $167
  1027f7:	68 a7 00 00 00       	push   $0xa7
  jmp __alltraps
  1027fc:	e9 8c f9 ff ff       	jmp    10218d <__alltraps>

00102801 <vector168>:
.globl vector168
vector168:
  pushl $0
  102801:	6a 00                	push   $0x0
  pushl $168
  102803:	68 a8 00 00 00       	push   $0xa8
  jmp __alltraps
  102808:	e9 80 f9 ff ff       	jmp    10218d <__alltraps>

0010280d <vector169>:
.globl vector169
vector169:
  pushl $0
  10280d:	6a 00                	push   $0x0
  pushl $169
  10280f:	68 a9 00 00 00       	push   $0xa9
  jmp __alltraps
  102814:	e9 74 f9 ff ff       	jmp    10218d <__alltraps>

00102819 <vector170>:
.globl vector170
vector170:
  pushl $0
  102819:	6a 00                	push   $0x0
  pushl $170
  10281b:	68 aa 00 00 00       	push   $0xaa
  jmp __alltraps
  102820:	e9 68 f9 ff ff       	jmp    10218d <__alltraps>

00102825 <vector171>:
.globl vector171
vector171:
  pushl $0
  102825:	6a 00                	push   $0x0
  pushl $171
  102827:	68 ab 00 00 00       	push   $0xab
  jmp __alltraps
  10282c:	e9 5c f9 ff ff       	jmp    10218d <__alltraps>

00102831 <vector172>:
.globl vector172
vector172:
  pushl $0
  102831:	6a 00                	push   $0x0
  pushl $172
  102833:	68 ac 00 00 00       	push   $0xac
  jmp __alltraps
  102838:	e9 50 f9 ff ff       	jmp    10218d <__alltraps>

0010283d <vector173>:
.globl vector173
vector173:
  pushl $0
  10283d:	6a 00                	push   $0x0
  pushl $173
  10283f:	68 ad 00 00 00       	push   $0xad
  jmp __alltraps
  102844:	e9 44 f9 ff ff       	jmp    10218d <__alltraps>

00102849 <vector174>:
.globl vector174
vector174:
  pushl $0
  102849:	6a 00                	push   $0x0
  pushl $174
  10284b:	68 ae 00 00 00       	push   $0xae
  jmp __alltraps
  102850:	e9 38 f9 ff ff       	jmp    10218d <__alltraps>

00102855 <vector175>:
.globl vector175
vector175:
  pushl $0
  102855:	6a 00                	push   $0x0
  pushl $175
  102857:	68 af 00 00 00       	push   $0xaf
  jmp __alltraps
  10285c:	e9 2c f9 ff ff       	jmp    10218d <__alltraps>

00102861 <vector176>:
.globl vector176
vector176:
  pushl $0
  102861:	6a 00                	push   $0x0
  pushl $176
  102863:	68 b0 00 00 00       	push   $0xb0
  jmp __alltraps
  102868:	e9 20 f9 ff ff       	jmp    10218d <__alltraps>

0010286d <vector177>:
.globl vector177
vector177:
  pushl $0
  10286d:	6a 00                	push   $0x0
  pushl $177
  10286f:	68 b1 00 00 00       	push   $0xb1
  jmp __alltraps
  102874:	e9 14 f9 ff ff       	jmp    10218d <__alltraps>

00102879 <vector178>:
.globl vector178
vector178:
  pushl $0
  102879:	6a 00                	push   $0x0
  pushl $178
  10287b:	68 b2 00 00 00       	push   $0xb2
  jmp __alltraps
  102880:	e9 08 f9 ff ff       	jmp    10218d <__alltraps>

00102885 <vector179>:
.globl vector179
vector179:
  pushl $0
  102885:	6a 00                	push   $0x0
  pushl $179
  102887:	68 b3 00 00 00       	push   $0xb3
  jmp __alltraps
  10288c:	e9 fc f8 ff ff       	jmp    10218d <__alltraps>

00102891 <vector180>:
.globl vector180
vector180:
  pushl $0
  102891:	6a 00                	push   $0x0
  pushl $180
  102893:	68 b4 00 00 00       	push   $0xb4
  jmp __alltraps
  102898:	e9 f0 f8 ff ff       	jmp    10218d <__alltraps>

0010289d <vector181>:
.globl vector181
vector181:
  pushl $0
  10289d:	6a 00                	push   $0x0
  pushl $181
  10289f:	68 b5 00 00 00       	push   $0xb5
  jmp __alltraps
  1028a4:	e9 e4 f8 ff ff       	jmp    10218d <__alltraps>

001028a9 <vector182>:
.globl vector182
vector182:
  pushl $0
  1028a9:	6a 00                	push   $0x0
  pushl $182
  1028ab:	68 b6 00 00 00       	push   $0xb6
  jmp __alltraps
  1028b0:	e9 d8 f8 ff ff       	jmp    10218d <__alltraps>

001028b5 <vector183>:
.globl vector183
vector183:
  pushl $0
  1028b5:	6a 00                	push   $0x0
  pushl $183
  1028b7:	68 b7 00 00 00       	push   $0xb7
  jmp __alltraps
  1028bc:	e9 cc f8 ff ff       	jmp    10218d <__alltraps>

001028c1 <vector184>:
.globl vector184
vector184:
  pushl $0
  1028c1:	6a 00                	push   $0x0
  pushl $184
  1028c3:	68 b8 00 00 00       	push   $0xb8
  jmp __alltraps
  1028c8:	e9 c0 f8 ff ff       	jmp    10218d <__alltraps>

001028cd <vector185>:
.globl vector185
vector185:
  pushl $0
  1028cd:	6a 00                	push   $0x0
  pushl $185
  1028cf:	68 b9 00 00 00       	push   $0xb9
  jmp __alltraps
  1028d4:	e9 b4 f8 ff ff       	jmp    10218d <__alltraps>

001028d9 <vector186>:
.globl vector186
vector186:
  pushl $0
  1028d9:	6a 00                	push   $0x0
  pushl $186
  1028db:	68 ba 00 00 00       	push   $0xba
  jmp __alltraps
  1028e0:	e9 a8 f8 ff ff       	jmp    10218d <__alltraps>

001028e5 <vector187>:
.globl vector187
vector187:
  pushl $0
  1028e5:	6a 00                	push   $0x0
  pushl $187
  1028e7:	68 bb 00 00 00       	push   $0xbb
  jmp __alltraps
  1028ec:	e9 9c f8 ff ff       	jmp    10218d <__alltraps>

001028f1 <vector188>:
.globl vector188
vector188:
  pushl $0
  1028f1:	6a 00                	push   $0x0
  pushl $188
  1028f3:	68 bc 00 00 00       	push   $0xbc
  jmp __alltraps
  1028f8:	e9 90 f8 ff ff       	jmp    10218d <__alltraps>

001028fd <vector189>:
.globl vector189
vector189:
  pushl $0
  1028fd:	6a 00                	push   $0x0
  pushl $189
  1028ff:	68 bd 00 00 00       	push   $0xbd
  jmp __alltraps
  102904:	e9 84 f8 ff ff       	jmp    10218d <__alltraps>

00102909 <vector190>:
.globl vector190
vector190:
  pushl $0
  102909:	6a 00                	push   $0x0
  pushl $190
  10290b:	68 be 00 00 00       	push   $0xbe
  jmp __alltraps
  102910:	e9 78 f8 ff ff       	jmp    10218d <__alltraps>

00102915 <vector191>:
.globl vector191
vector191:
  pushl $0
  102915:	6a 00                	push   $0x0
  pushl $191
  102917:	68 bf 00 00 00       	push   $0xbf
  jmp __alltraps
  10291c:	e9 6c f8 ff ff       	jmp    10218d <__alltraps>

00102921 <vector192>:
.globl vector192
vector192:
  pushl $0
  102921:	6a 00                	push   $0x0
  pushl $192
  102923:	68 c0 00 00 00       	push   $0xc0
  jmp __alltraps
  102928:	e9 60 f8 ff ff       	jmp    10218d <__alltraps>

0010292d <vector193>:
.globl vector193
vector193:
  pushl $0
  10292d:	6a 00                	push   $0x0
  pushl $193
  10292f:	68 c1 00 00 00       	push   $0xc1
  jmp __alltraps
  102934:	e9 54 f8 ff ff       	jmp    10218d <__alltraps>

00102939 <vector194>:
.globl vector194
vector194:
  pushl $0
  102939:	6a 00                	push   $0x0
  pushl $194
  10293b:	68 c2 00 00 00       	push   $0xc2
  jmp __alltraps
  102940:	e9 48 f8 ff ff       	jmp    10218d <__alltraps>

00102945 <vector195>:
.globl vector195
vector195:
  pushl $0
  102945:	6a 00                	push   $0x0
  pushl $195
  102947:	68 c3 00 00 00       	push   $0xc3
  jmp __alltraps
  10294c:	e9 3c f8 ff ff       	jmp    10218d <__alltraps>

00102951 <vector196>:
.globl vector196
vector196:
  pushl $0
  102951:	6a 00                	push   $0x0
  pushl $196
  102953:	68 c4 00 00 00       	push   $0xc4
  jmp __alltraps
  102958:	e9 30 f8 ff ff       	jmp    10218d <__alltraps>

0010295d <vector197>:
.globl vector197
vector197:
  pushl $0
  10295d:	6a 00                	push   $0x0
  pushl $197
  10295f:	68 c5 00 00 00       	push   $0xc5
  jmp __alltraps
  102964:	e9 24 f8 ff ff       	jmp    10218d <__alltraps>

00102969 <vector198>:
.globl vector198
vector198:
  pushl $0
  102969:	6a 00                	push   $0x0
  pushl $198
  10296b:	68 c6 00 00 00       	push   $0xc6
  jmp __alltraps
  102970:	e9 18 f8 ff ff       	jmp    10218d <__alltraps>

00102975 <vector199>:
.globl vector199
vector199:
  pushl $0
  102975:	6a 00                	push   $0x0
  pushl $199
  102977:	68 c7 00 00 00       	push   $0xc7
  jmp __alltraps
  10297c:	e9 0c f8 ff ff       	jmp    10218d <__alltraps>

00102981 <vector200>:
.globl vector200
vector200:
  pushl $0
  102981:	6a 00                	push   $0x0
  pushl $200
  102983:	68 c8 00 00 00       	push   $0xc8
  jmp __alltraps
  102988:	e9 00 f8 ff ff       	jmp    10218d <__alltraps>

0010298d <vector201>:
.globl vector201
vector201:
  pushl $0
  10298d:	6a 00                	push   $0x0
  pushl $201
  10298f:	68 c9 00 00 00       	push   $0xc9
  jmp __alltraps
  102994:	e9 f4 f7 ff ff       	jmp    10218d <__alltraps>

00102999 <vector202>:
.globl vector202
vector202:
  pushl $0
  102999:	6a 00                	push   $0x0
  pushl $202
  10299b:	68 ca 00 00 00       	push   $0xca
  jmp __alltraps
  1029a0:	e9 e8 f7 ff ff       	jmp    10218d <__alltraps>

001029a5 <vector203>:
.globl vector203
vector203:
  pushl $0
  1029a5:	6a 00                	push   $0x0
  pushl $203
  1029a7:	68 cb 00 00 00       	push   $0xcb
  jmp __alltraps
  1029ac:	e9 dc f7 ff ff       	jmp    10218d <__alltraps>

001029b1 <vector204>:
.globl vector204
vector204:
  pushl $0
  1029b1:	6a 00                	push   $0x0
  pushl $204
  1029b3:	68 cc 00 00 00       	push   $0xcc
  jmp __alltraps
  1029b8:	e9 d0 f7 ff ff       	jmp    10218d <__alltraps>

001029bd <vector205>:
.globl vector205
vector205:
  pushl $0
  1029bd:	6a 00                	push   $0x0
  pushl $205
  1029bf:	68 cd 00 00 00       	push   $0xcd
  jmp __alltraps
  1029c4:	e9 c4 f7 ff ff       	jmp    10218d <__alltraps>

001029c9 <vector206>:
.globl vector206
vector206:
  pushl $0
  1029c9:	6a 00                	push   $0x0
  pushl $206
  1029cb:	68 ce 00 00 00       	push   $0xce
  jmp __alltraps
  1029d0:	e9 b8 f7 ff ff       	jmp    10218d <__alltraps>

001029d5 <vector207>:
.globl vector207
vector207:
  pushl $0
  1029d5:	6a 00                	push   $0x0
  pushl $207
  1029d7:	68 cf 00 00 00       	push   $0xcf
  jmp __alltraps
  1029dc:	e9 ac f7 ff ff       	jmp    10218d <__alltraps>

001029e1 <vector208>:
.globl vector208
vector208:
  pushl $0
  1029e1:	6a 00                	push   $0x0
  pushl $208
  1029e3:	68 d0 00 00 00       	push   $0xd0
  jmp __alltraps
  1029e8:	e9 a0 f7 ff ff       	jmp    10218d <__alltraps>

001029ed <vector209>:
.globl vector209
vector209:
  pushl $0
  1029ed:	6a 00                	push   $0x0
  pushl $209
  1029ef:	68 d1 00 00 00       	push   $0xd1
  jmp __alltraps
  1029f4:	e9 94 f7 ff ff       	jmp    10218d <__alltraps>

001029f9 <vector210>:
.globl vector210
vector210:
  pushl $0
  1029f9:	6a 00                	push   $0x0
  pushl $210
  1029fb:	68 d2 00 00 00       	push   $0xd2
  jmp __alltraps
  102a00:	e9 88 f7 ff ff       	jmp    10218d <__alltraps>

00102a05 <vector211>:
.globl vector211
vector211:
  pushl $0
  102a05:	6a 00                	push   $0x0
  pushl $211
  102a07:	68 d3 00 00 00       	push   $0xd3
  jmp __alltraps
  102a0c:	e9 7c f7 ff ff       	jmp    10218d <__alltraps>

00102a11 <vector212>:
.globl vector212
vector212:
  pushl $0
  102a11:	6a 00                	push   $0x0
  pushl $212
  102a13:	68 d4 00 00 00       	push   $0xd4
  jmp __alltraps
  102a18:	e9 70 f7 ff ff       	jmp    10218d <__alltraps>

00102a1d <vector213>:
.globl vector213
vector213:
  pushl $0
  102a1d:	6a 00                	push   $0x0
  pushl $213
  102a1f:	68 d5 00 00 00       	push   $0xd5
  jmp __alltraps
  102a24:	e9 64 f7 ff ff       	jmp    10218d <__alltraps>

00102a29 <vector214>:
.globl vector214
vector214:
  pushl $0
  102a29:	6a 00                	push   $0x0
  pushl $214
  102a2b:	68 d6 00 00 00       	push   $0xd6
  jmp __alltraps
  102a30:	e9 58 f7 ff ff       	jmp    10218d <__alltraps>

00102a35 <vector215>:
.globl vector215
vector215:
  pushl $0
  102a35:	6a 00                	push   $0x0
  pushl $215
  102a37:	68 d7 00 00 00       	push   $0xd7
  jmp __alltraps
  102a3c:	e9 4c f7 ff ff       	jmp    10218d <__alltraps>

00102a41 <vector216>:
.globl vector216
vector216:
  pushl $0
  102a41:	6a 00                	push   $0x0
  pushl $216
  102a43:	68 d8 00 00 00       	push   $0xd8
  jmp __alltraps
  102a48:	e9 40 f7 ff ff       	jmp    10218d <__alltraps>

00102a4d <vector217>:
.globl vector217
vector217:
  pushl $0
  102a4d:	6a 00                	push   $0x0
  pushl $217
  102a4f:	68 d9 00 00 00       	push   $0xd9
  jmp __alltraps
  102a54:	e9 34 f7 ff ff       	jmp    10218d <__alltraps>

00102a59 <vector218>:
.globl vector218
vector218:
  pushl $0
  102a59:	6a 00                	push   $0x0
  pushl $218
  102a5b:	68 da 00 00 00       	push   $0xda
  jmp __alltraps
  102a60:	e9 28 f7 ff ff       	jmp    10218d <__alltraps>

00102a65 <vector219>:
.globl vector219
vector219:
  pushl $0
  102a65:	6a 00                	push   $0x0
  pushl $219
  102a67:	68 db 00 00 00       	push   $0xdb
  jmp __alltraps
  102a6c:	e9 1c f7 ff ff       	jmp    10218d <__alltraps>

00102a71 <vector220>:
.globl vector220
vector220:
  pushl $0
  102a71:	6a 00                	push   $0x0
  pushl $220
  102a73:	68 dc 00 00 00       	push   $0xdc
  jmp __alltraps
  102a78:	e9 10 f7 ff ff       	jmp    10218d <__alltraps>

00102a7d <vector221>:
.globl vector221
vector221:
  pushl $0
  102a7d:	6a 00                	push   $0x0
  pushl $221
  102a7f:	68 dd 00 00 00       	push   $0xdd
  jmp __alltraps
  102a84:	e9 04 f7 ff ff       	jmp    10218d <__alltraps>

00102a89 <vector222>:
.globl vector222
vector222:
  pushl $0
  102a89:	6a 00                	push   $0x0
  pushl $222
  102a8b:	68 de 00 00 00       	push   $0xde
  jmp __alltraps
  102a90:	e9 f8 f6 ff ff       	jmp    10218d <__alltraps>

00102a95 <vector223>:
.globl vector223
vector223:
  pushl $0
  102a95:	6a 00                	push   $0x0
  pushl $223
  102a97:	68 df 00 00 00       	push   $0xdf
  jmp __alltraps
  102a9c:	e9 ec f6 ff ff       	jmp    10218d <__alltraps>

00102aa1 <vector224>:
.globl vector224
vector224:
  pushl $0
  102aa1:	6a 00                	push   $0x0
  pushl $224
  102aa3:	68 e0 00 00 00       	push   $0xe0
  jmp __alltraps
  102aa8:	e9 e0 f6 ff ff       	jmp    10218d <__alltraps>

00102aad <vector225>:
.globl vector225
vector225:
  pushl $0
  102aad:	6a 00                	push   $0x0
  pushl $225
  102aaf:	68 e1 00 00 00       	push   $0xe1
  jmp __alltraps
  102ab4:	e9 d4 f6 ff ff       	jmp    10218d <__alltraps>

00102ab9 <vector226>:
.globl vector226
vector226:
  pushl $0
  102ab9:	6a 00                	push   $0x0
  pushl $226
  102abb:	68 e2 00 00 00       	push   $0xe2
  jmp __alltraps
  102ac0:	e9 c8 f6 ff ff       	jmp    10218d <__alltraps>

00102ac5 <vector227>:
.globl vector227
vector227:
  pushl $0
  102ac5:	6a 00                	push   $0x0
  pushl $227
  102ac7:	68 e3 00 00 00       	push   $0xe3
  jmp __alltraps
  102acc:	e9 bc f6 ff ff       	jmp    10218d <__alltraps>

00102ad1 <vector228>:
.globl vector228
vector228:
  pushl $0
  102ad1:	6a 00                	push   $0x0
  pushl $228
  102ad3:	68 e4 00 00 00       	push   $0xe4
  jmp __alltraps
  102ad8:	e9 b0 f6 ff ff       	jmp    10218d <__alltraps>

00102add <vector229>:
.globl vector229
vector229:
  pushl $0
  102add:	6a 00                	push   $0x0
  pushl $229
  102adf:	68 e5 00 00 00       	push   $0xe5
  jmp __alltraps
  102ae4:	e9 a4 f6 ff ff       	jmp    10218d <__alltraps>

00102ae9 <vector230>:
.globl vector230
vector230:
  pushl $0
  102ae9:	6a 00                	push   $0x0
  pushl $230
  102aeb:	68 e6 00 00 00       	push   $0xe6
  jmp __alltraps
  102af0:	e9 98 f6 ff ff       	jmp    10218d <__alltraps>

00102af5 <vector231>:
.globl vector231
vector231:
  pushl $0
  102af5:	6a 00                	push   $0x0
  pushl $231
  102af7:	68 e7 00 00 00       	push   $0xe7
  jmp __alltraps
  102afc:	e9 8c f6 ff ff       	jmp    10218d <__alltraps>

00102b01 <vector232>:
.globl vector232
vector232:
  pushl $0
  102b01:	6a 00                	push   $0x0
  pushl $232
  102b03:	68 e8 00 00 00       	push   $0xe8
  jmp __alltraps
  102b08:	e9 80 f6 ff ff       	jmp    10218d <__alltraps>

00102b0d <vector233>:
.globl vector233
vector233:
  pushl $0
  102b0d:	6a 00                	push   $0x0
  pushl $233
  102b0f:	68 e9 00 00 00       	push   $0xe9
  jmp __alltraps
  102b14:	e9 74 f6 ff ff       	jmp    10218d <__alltraps>

00102b19 <vector234>:
.globl vector234
vector234:
  pushl $0
  102b19:	6a 00                	push   $0x0
  pushl $234
  102b1b:	68 ea 00 00 00       	push   $0xea
  jmp __alltraps
  102b20:	e9 68 f6 ff ff       	jmp    10218d <__alltraps>

00102b25 <vector235>:
.globl vector235
vector235:
  pushl $0
  102b25:	6a 00                	push   $0x0
  pushl $235
  102b27:	68 eb 00 00 00       	push   $0xeb
  jmp __alltraps
  102b2c:	e9 5c f6 ff ff       	jmp    10218d <__alltraps>

00102b31 <vector236>:
.globl vector236
vector236:
  pushl $0
  102b31:	6a 00                	push   $0x0
  pushl $236
  102b33:	68 ec 00 00 00       	push   $0xec
  jmp __alltraps
  102b38:	e9 50 f6 ff ff       	jmp    10218d <__alltraps>

00102b3d <vector237>:
.globl vector237
vector237:
  pushl $0
  102b3d:	6a 00                	push   $0x0
  pushl $237
  102b3f:	68 ed 00 00 00       	push   $0xed
  jmp __alltraps
  102b44:	e9 44 f6 ff ff       	jmp    10218d <__alltraps>

00102b49 <vector238>:
.globl vector238
vector238:
  pushl $0
  102b49:	6a 00                	push   $0x0
  pushl $238
  102b4b:	68 ee 00 00 00       	push   $0xee
  jmp __alltraps
  102b50:	e9 38 f6 ff ff       	jmp    10218d <__alltraps>

00102b55 <vector239>:
.globl vector239
vector239:
  pushl $0
  102b55:	6a 00                	push   $0x0
  pushl $239
  102b57:	68 ef 00 00 00       	push   $0xef
  jmp __alltraps
  102b5c:	e9 2c f6 ff ff       	jmp    10218d <__alltraps>

00102b61 <vector240>:
.globl vector240
vector240:
  pushl $0
  102b61:	6a 00                	push   $0x0
  pushl $240
  102b63:	68 f0 00 00 00       	push   $0xf0
  jmp __alltraps
  102b68:	e9 20 f6 ff ff       	jmp    10218d <__alltraps>

00102b6d <vector241>:
.globl vector241
vector241:
  pushl $0
  102b6d:	6a 00                	push   $0x0
  pushl $241
  102b6f:	68 f1 00 00 00       	push   $0xf1
  jmp __alltraps
  102b74:	e9 14 f6 ff ff       	jmp    10218d <__alltraps>

00102b79 <vector242>:
.globl vector242
vector242:
  pushl $0
  102b79:	6a 00                	push   $0x0
  pushl $242
  102b7b:	68 f2 00 00 00       	push   $0xf2
  jmp __alltraps
  102b80:	e9 08 f6 ff ff       	jmp    10218d <__alltraps>

00102b85 <vector243>:
.globl vector243
vector243:
  pushl $0
  102b85:	6a 00                	push   $0x0
  pushl $243
  102b87:	68 f3 00 00 00       	push   $0xf3
  jmp __alltraps
  102b8c:	e9 fc f5 ff ff       	jmp    10218d <__alltraps>

00102b91 <vector244>:
.globl vector244
vector244:
  pushl $0
  102b91:	6a 00                	push   $0x0
  pushl $244
  102b93:	68 f4 00 00 00       	push   $0xf4
  jmp __alltraps
  102b98:	e9 f0 f5 ff ff       	jmp    10218d <__alltraps>

00102b9d <vector245>:
.globl vector245
vector245:
  pushl $0
  102b9d:	6a 00                	push   $0x0
  pushl $245
  102b9f:	68 f5 00 00 00       	push   $0xf5
  jmp __alltraps
  102ba4:	e9 e4 f5 ff ff       	jmp    10218d <__alltraps>

00102ba9 <vector246>:
.globl vector246
vector246:
  pushl $0
  102ba9:	6a 00                	push   $0x0
  pushl $246
  102bab:	68 f6 00 00 00       	push   $0xf6
  jmp __alltraps
  102bb0:	e9 d8 f5 ff ff       	jmp    10218d <__alltraps>

00102bb5 <vector247>:
.globl vector247
vector247:
  pushl $0
  102bb5:	6a 00                	push   $0x0
  pushl $247
  102bb7:	68 f7 00 00 00       	push   $0xf7
  jmp __alltraps
  102bbc:	e9 cc f5 ff ff       	jmp    10218d <__alltraps>

00102bc1 <vector248>:
.globl vector248
vector248:
  pushl $0
  102bc1:	6a 00                	push   $0x0
  pushl $248
  102bc3:	68 f8 00 00 00       	push   $0xf8
  jmp __alltraps
  102bc8:	e9 c0 f5 ff ff       	jmp    10218d <__alltraps>

00102bcd <vector249>:
.globl vector249
vector249:
  pushl $0
  102bcd:	6a 00                	push   $0x0
  pushl $249
  102bcf:	68 f9 00 00 00       	push   $0xf9
  jmp __alltraps
  102bd4:	e9 b4 f5 ff ff       	jmp    10218d <__alltraps>

00102bd9 <vector250>:
.globl vector250
vector250:
  pushl $0
  102bd9:	6a 00                	push   $0x0
  pushl $250
  102bdb:	68 fa 00 00 00       	push   $0xfa
  jmp __alltraps
  102be0:	e9 a8 f5 ff ff       	jmp    10218d <__alltraps>

00102be5 <vector251>:
.globl vector251
vector251:
  pushl $0
  102be5:	6a 00                	push   $0x0
  pushl $251
  102be7:	68 fb 00 00 00       	push   $0xfb
  jmp __alltraps
  102bec:	e9 9c f5 ff ff       	jmp    10218d <__alltraps>

00102bf1 <vector252>:
.globl vector252
vector252:
  pushl $0
  102bf1:	6a 00                	push   $0x0
  pushl $252
  102bf3:	68 fc 00 00 00       	push   $0xfc
  jmp __alltraps
  102bf8:	e9 90 f5 ff ff       	jmp    10218d <__alltraps>

00102bfd <vector253>:
.globl vector253
vector253:
  pushl $0
  102bfd:	6a 00                	push   $0x0
  pushl $253
  102bff:	68 fd 00 00 00       	push   $0xfd
  jmp __alltraps
  102c04:	e9 84 f5 ff ff       	jmp    10218d <__alltraps>

00102c09 <vector254>:
.globl vector254
vector254:
  pushl $0
  102c09:	6a 00                	push   $0x0
  pushl $254
  102c0b:	68 fe 00 00 00       	push   $0xfe
  jmp __alltraps
  102c10:	e9 78 f5 ff ff       	jmp    10218d <__alltraps>

00102c15 <vector255>:
.globl vector255
vector255:
  pushl $0
  102c15:	6a 00                	push   $0x0
  pushl $255
  102c17:	68 ff 00 00 00       	push   $0xff
  jmp __alltraps
  102c1c:	e9 6c f5 ff ff       	jmp    10218d <__alltraps>

00102c21 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
  102c21:	55                   	push   %ebp
  102c22:	89 e5                	mov    %esp,%ebp
    return page - pages;
  102c24:	8b 55 08             	mov    0x8(%ebp),%edx
  102c27:	a1 24 af 11 00       	mov    0x11af24,%eax
  102c2c:	29 c2                	sub    %eax,%edx
  102c2e:	89 d0                	mov    %edx,%eax
  102c30:	c1 f8 02             	sar    $0x2,%eax
  102c33:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
  102c39:	5d                   	pop    %ebp
  102c3a:	c3                   	ret    

00102c3b <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
  102c3b:	55                   	push   %ebp
  102c3c:	89 e5                	mov    %esp,%ebp
  102c3e:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
  102c41:	8b 45 08             	mov    0x8(%ebp),%eax
  102c44:	89 04 24             	mov    %eax,(%esp)
  102c47:	e8 d5 ff ff ff       	call   102c21 <page2ppn>
  102c4c:	c1 e0 0c             	shl    $0xc,%eax
}
  102c4f:	c9                   	leave  
  102c50:	c3                   	ret    

00102c51 <page_ref>:
pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
}

static inline int
page_ref(struct Page *page) {
  102c51:	55                   	push   %ebp
  102c52:	89 e5                	mov    %esp,%ebp
    return page->ref;
  102c54:	8b 45 08             	mov    0x8(%ebp),%eax
  102c57:	8b 00                	mov    (%eax),%eax
}
  102c59:	5d                   	pop    %ebp
  102c5a:	c3                   	ret    

00102c5b <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
  102c5b:	55                   	push   %ebp
  102c5c:	89 e5                	mov    %esp,%ebp
    page->ref = val;
  102c5e:	8b 45 08             	mov    0x8(%ebp),%eax
  102c61:	8b 55 0c             	mov    0xc(%ebp),%edx
  102c64:	89 10                	mov    %edx,(%eax)
}
  102c66:	5d                   	pop    %ebp
  102c67:	c3                   	ret    

00102c68 <default_init>:

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
  102c68:	55                   	push   %ebp
  102c69:	89 e5                	mov    %esp,%ebp
  102c6b:	83 ec 10             	sub    $0x10,%esp
  102c6e:	c7 45 fc 10 af 11 00 	movl   $0x11af10,-0x4(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
  102c75:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102c78:	8b 55 fc             	mov    -0x4(%ebp),%edx
  102c7b:	89 50 04             	mov    %edx,0x4(%eax)
  102c7e:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102c81:	8b 50 04             	mov    0x4(%eax),%edx
  102c84:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102c87:	89 10                	mov    %edx,(%eax)
    list_init(&free_list);
    nr_free = 0;
  102c89:	c7 05 18 af 11 00 00 	movl   $0x0,0x11af18
  102c90:	00 00 00 
}
  102c93:	c9                   	leave  
  102c94:	c3                   	ret    

00102c95 <default_init_memmap>:

static void
default_init_memmap(struct Page *base, size_t n) {
  102c95:	55                   	push   %ebp
  102c96:	89 e5                	mov    %esp,%ebp
  102c98:	83 ec 48             	sub    $0x48,%esp
    assert(n > 0);
  102c9b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  102c9f:	75 24                	jne    102cc5 <default_init_memmap+0x30>
  102ca1:	c7 44 24 0c b0 69 10 	movl   $0x1069b0,0xc(%esp)
  102ca8:	00 
  102ca9:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  102cb0:	00 
  102cb1:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
  102cb8:	00 
  102cb9:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  102cc0:	e8 12 e0 ff ff       	call   100cd7 <__panic>
    struct Page *p = base;
  102cc5:	8b 45 08             	mov    0x8(%ebp),%eax
  102cc8:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
  102ccb:	eb 7d                	jmp    102d4a <default_init_memmap+0xb5>
        assert(PageReserved(p));
  102ccd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102cd0:	83 c0 04             	add    $0x4,%eax
  102cd3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  102cda:	89 45 ec             	mov    %eax,-0x14(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  102cdd:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102ce0:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102ce3:	0f a3 10             	bt     %edx,(%eax)
  102ce6:	19 c0                	sbb    %eax,%eax
  102ce8:	89 45 e8             	mov    %eax,-0x18(%ebp)
    return oldbit != 0;
  102ceb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  102cef:	0f 95 c0             	setne  %al
  102cf2:	0f b6 c0             	movzbl %al,%eax
  102cf5:	85 c0                	test   %eax,%eax
  102cf7:	75 24                	jne    102d1d <default_init_memmap+0x88>
  102cf9:	c7 44 24 0c e1 69 10 	movl   $0x1069e1,0xc(%esp)
  102d00:	00 
  102d01:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  102d08:	00 
  102d09:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  102d10:	00 
  102d11:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  102d18:	e8 ba df ff ff       	call   100cd7 <__panic>
        p->flags = p->property = 0;
  102d1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d20:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  102d27:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d2a:	8b 50 08             	mov    0x8(%eax),%edx
  102d2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d30:	89 50 04             	mov    %edx,0x4(%eax)
        set_page_ref(p, 0);
  102d33:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102d3a:	00 
  102d3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d3e:	89 04 24             	mov    %eax,(%esp)
  102d41:	e8 15 ff ff ff       	call   102c5b <set_page_ref>

static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
  102d46:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
  102d4a:	8b 55 0c             	mov    0xc(%ebp),%edx
  102d4d:	89 d0                	mov    %edx,%eax
  102d4f:	c1 e0 02             	shl    $0x2,%eax
  102d52:	01 d0                	add    %edx,%eax
  102d54:	c1 e0 02             	shl    $0x2,%eax
  102d57:	89 c2                	mov    %eax,%edx
  102d59:	8b 45 08             	mov    0x8(%ebp),%eax
  102d5c:	01 d0                	add    %edx,%eax
  102d5e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  102d61:	0f 85 66 ff ff ff    	jne    102ccd <default_init_memmap+0x38>
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
  102d67:	8b 45 08             	mov    0x8(%ebp),%eax
  102d6a:	8b 55 0c             	mov    0xc(%ebp),%edx
  102d6d:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
  102d70:	8b 45 08             	mov    0x8(%ebp),%eax
  102d73:	83 c0 04             	add    $0x4,%eax
  102d76:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
  102d7d:	89 45 e0             	mov    %eax,-0x20(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  102d80:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102d83:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  102d86:	0f ab 10             	bts    %edx,(%eax)
    nr_free += n;
  102d89:	8b 15 18 af 11 00    	mov    0x11af18,%edx
  102d8f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102d92:	01 d0                	add    %edx,%eax
  102d94:	a3 18 af 11 00       	mov    %eax,0x11af18
    //默认地址是从小到大来的，因此这里要改成before
    list_add_before(&free_list, &(base->page_link));
  102d99:	8b 45 08             	mov    0x8(%ebp),%eax
  102d9c:	83 c0 0c             	add    $0xc,%eax
  102d9f:	c7 45 dc 10 af 11 00 	movl   $0x11af10,-0x24(%ebp)
  102da6:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
  102da9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102dac:	8b 00                	mov    (%eax),%eax
  102dae:	8b 55 d8             	mov    -0x28(%ebp),%edx
  102db1:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  102db4:	89 45 d0             	mov    %eax,-0x30(%ebp)
  102db7:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102dba:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  102dbd:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102dc0:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  102dc3:	89 10                	mov    %edx,(%eax)
  102dc5:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102dc8:	8b 10                	mov    (%eax),%edx
  102dca:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102dcd:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  102dd0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102dd3:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102dd6:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  102dd9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102ddc:	8b 55 d0             	mov    -0x30(%ebp),%edx
  102ddf:	89 10                	mov    %edx,(%eax)
}
  102de1:	c9                   	leave  
  102de2:	c3                   	ret    

00102de3 <default_alloc_pages>:

static struct Page *
default_alloc_pages(size_t n) {
  102de3:	55                   	push   %ebp
  102de4:	89 e5                	mov    %esp,%ebp
  102de6:	83 ec 68             	sub    $0x68,%esp
    assert(n > 0);
  102de9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102ded:	75 24                	jne    102e13 <default_alloc_pages+0x30>
  102def:	c7 44 24 0c b0 69 10 	movl   $0x1069b0,0xc(%esp)
  102df6:	00 
  102df7:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  102dfe:	00 
  102dff:	c7 44 24 04 7d 00 00 	movl   $0x7d,0x4(%esp)
  102e06:	00 
  102e07:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  102e0e:	e8 c4 de ff ff       	call   100cd7 <__panic>
    if (n > nr_free) {
  102e13:	a1 18 af 11 00       	mov    0x11af18,%eax
  102e18:	3b 45 08             	cmp    0x8(%ebp),%eax
  102e1b:	73 0a                	jae    102e27 <default_alloc_pages+0x44>
        return NULL;
  102e1d:	b8 00 00 00 00       	mov    $0x0,%eax
  102e22:	e9 3d 01 00 00       	jmp    102f64 <default_alloc_pages+0x181>
    }
    struct Page *page = NULL;
  102e27:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    list_entry_t *le = &free_list;
  102e2e:	c7 45 f0 10 af 11 00 	movl   $0x11af10,-0x10(%ebp)
    while ((le = list_next(le)) != &free_list) {
  102e35:	eb 1c                	jmp    102e53 <default_alloc_pages+0x70>
        struct Page *p = le2page(le, page_link);
  102e37:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e3a:	83 e8 0c             	sub    $0xc,%eax
  102e3d:	89 45 ec             	mov    %eax,-0x14(%ebp)
        if (p->property >= n) {
  102e40:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102e43:	8b 40 08             	mov    0x8(%eax),%eax
  102e46:	3b 45 08             	cmp    0x8(%ebp),%eax
  102e49:	72 08                	jb     102e53 <default_alloc_pages+0x70>
            page = p;
  102e4b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102e4e:	89 45 f4             	mov    %eax,-0xc(%ebp)
            break;
  102e51:	eb 18                	jmp    102e6b <default_alloc_pages+0x88>
  102e53:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e56:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  102e59:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102e5c:	8b 40 04             	mov    0x4(%eax),%eax
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
  102e5f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102e62:	81 7d f0 10 af 11 00 	cmpl   $0x11af10,-0x10(%ebp)
  102e69:	75 cc                	jne    102e37 <default_alloc_pages+0x54>
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
  102e6b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102e6f:	0f 84 ec 00 00 00    	je     102f61 <default_alloc_pages+0x17e>
        if (page->property > n) {
  102e75:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e78:	8b 40 08             	mov    0x8(%eax),%eax
  102e7b:	3b 45 08             	cmp    0x8(%ebp),%eax
  102e7e:	0f 86 8c 00 00 00    	jbe    102f10 <default_alloc_pages+0x12d>
            struct Page *p = page + n;
  102e84:	8b 55 08             	mov    0x8(%ebp),%edx
  102e87:	89 d0                	mov    %edx,%eax
  102e89:	c1 e0 02             	shl    $0x2,%eax
  102e8c:	01 d0                	add    %edx,%eax
  102e8e:	c1 e0 02             	shl    $0x2,%eax
  102e91:	89 c2                	mov    %eax,%edx
  102e93:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e96:	01 d0                	add    %edx,%eax
  102e98:	89 45 e8             	mov    %eax,-0x18(%ebp)
            p->property = page->property - n;
  102e9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e9e:	8b 40 08             	mov    0x8(%eax),%eax
  102ea1:	2b 45 08             	sub    0x8(%ebp),%eax
  102ea4:	89 c2                	mov    %eax,%edx
  102ea6:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102ea9:	89 50 08             	mov    %edx,0x8(%eax)
            SetPageProperty(p);
  102eac:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102eaf:	83 c0 04             	add    $0x4,%eax
  102eb2:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
  102eb9:	89 45 dc             	mov    %eax,-0x24(%ebp)
  102ebc:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102ebf:	8b 55 e0             	mov    -0x20(%ebp),%edx
  102ec2:	0f ab 10             	bts    %edx,(%eax)
            list_add_after(page->page_link.prev, &(p->page_link));
  102ec5:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102ec8:	8d 50 0c             	lea    0xc(%eax),%edx
  102ecb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ece:	8b 40 0c             	mov    0xc(%eax),%eax
  102ed1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  102ed4:	89 55 d4             	mov    %edx,-0x2c(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
  102ed7:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102eda:	8b 40 04             	mov    0x4(%eax),%eax
  102edd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  102ee0:	89 55 d0             	mov    %edx,-0x30(%ebp)
  102ee3:	8b 55 d8             	mov    -0x28(%ebp),%edx
  102ee6:	89 55 cc             	mov    %edx,-0x34(%ebp)
  102ee9:	89 45 c8             	mov    %eax,-0x38(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  102eec:	8b 45 c8             	mov    -0x38(%ebp),%eax
  102eef:	8b 55 d0             	mov    -0x30(%ebp),%edx
  102ef2:	89 10                	mov    %edx,(%eax)
  102ef4:	8b 45 c8             	mov    -0x38(%ebp),%eax
  102ef7:	8b 10                	mov    (%eax),%edx
  102ef9:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102efc:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  102eff:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102f02:	8b 55 c8             	mov    -0x38(%ebp),%edx
  102f05:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  102f08:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102f0b:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102f0e:	89 10                	mov    %edx,(%eax)
        }
        list_del(&(page->page_link));
  102f10:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f13:	83 c0 0c             	add    $0xc,%eax
  102f16:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
  102f19:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  102f1c:	8b 40 04             	mov    0x4(%eax),%eax
  102f1f:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  102f22:	8b 12                	mov    (%edx),%edx
  102f24:	89 55 c0             	mov    %edx,-0x40(%ebp)
  102f27:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
  102f2a:	8b 45 c0             	mov    -0x40(%ebp),%eax
  102f2d:	8b 55 bc             	mov    -0x44(%ebp),%edx
  102f30:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
  102f33:	8b 45 bc             	mov    -0x44(%ebp),%eax
  102f36:	8b 55 c0             	mov    -0x40(%ebp),%edx
  102f39:	89 10                	mov    %edx,(%eax)
        nr_free -= n;
  102f3b:	a1 18 af 11 00       	mov    0x11af18,%eax
  102f40:	2b 45 08             	sub    0x8(%ebp),%eax
  102f43:	a3 18 af 11 00       	mov    %eax,0x11af18
        ClearPageProperty(page);
  102f48:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f4b:	83 c0 04             	add    $0x4,%eax
  102f4e:	c7 45 b8 01 00 00 00 	movl   $0x1,-0x48(%ebp)
  102f55:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  102f58:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  102f5b:	8b 55 b8             	mov    -0x48(%ebp),%edx
  102f5e:	0f b3 10             	btr    %edx,(%eax)
    }
    return page;
  102f61:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  102f64:	c9                   	leave  
  102f65:	c3                   	ret    

00102f66 <default_free_pages>:

static void
default_free_pages(struct Page *base, size_t n) {
  102f66:	55                   	push   %ebp
  102f67:	89 e5                	mov    %esp,%ebp
  102f69:	81 ec 98 00 00 00    	sub    $0x98,%esp
    assert(n > 0);
  102f6f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  102f73:	75 24                	jne    102f99 <default_free_pages+0x33>
  102f75:	c7 44 24 0c b0 69 10 	movl   $0x1069b0,0xc(%esp)
  102f7c:	00 
  102f7d:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  102f84:	00 
  102f85:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  102f8c:	00 
  102f8d:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  102f94:	e8 3e dd ff ff       	call   100cd7 <__panic>
    struct Page *p = base;
  102f99:	8b 45 08             	mov    0x8(%ebp),%eax
  102f9c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
  102f9f:	e9 9d 00 00 00       	jmp    103041 <default_free_pages+0xdb>
        assert(!PageReserved(p) && !PageProperty(p));
  102fa4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102fa7:	83 c0 04             	add    $0x4,%eax
  102faa:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  102fb1:	89 45 e8             	mov    %eax,-0x18(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  102fb4:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102fb7:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102fba:	0f a3 10             	bt     %edx,(%eax)
  102fbd:	19 c0                	sbb    %eax,%eax
  102fbf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    return oldbit != 0;
  102fc2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  102fc6:	0f 95 c0             	setne  %al
  102fc9:	0f b6 c0             	movzbl %al,%eax
  102fcc:	85 c0                	test   %eax,%eax
  102fce:	75 2c                	jne    102ffc <default_free_pages+0x96>
  102fd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102fd3:	83 c0 04             	add    $0x4,%eax
  102fd6:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
  102fdd:	89 45 dc             	mov    %eax,-0x24(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  102fe0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102fe3:	8b 55 e0             	mov    -0x20(%ebp),%edx
  102fe6:	0f a3 10             	bt     %edx,(%eax)
  102fe9:	19 c0                	sbb    %eax,%eax
  102feb:	89 45 d8             	mov    %eax,-0x28(%ebp)
    return oldbit != 0;
  102fee:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  102ff2:	0f 95 c0             	setne  %al
  102ff5:	0f b6 c0             	movzbl %al,%eax
  102ff8:	85 c0                	test   %eax,%eax
  102ffa:	74 24                	je     103020 <default_free_pages+0xba>
  102ffc:	c7 44 24 0c f4 69 10 	movl   $0x1069f4,0xc(%esp)
  103003:	00 
  103004:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  10300b:	00 
  10300c:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  103013:	00 
  103014:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  10301b:	e8 b7 dc ff ff       	call   100cd7 <__panic>
        p->flags = 0;
  103020:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103023:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
        set_page_ref(p, 0);
  10302a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103031:	00 
  103032:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103035:	89 04 24             	mov    %eax,(%esp)
  103038:	e8 1e fc ff ff       	call   102c5b <set_page_ref>

static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
  10303d:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
  103041:	8b 55 0c             	mov    0xc(%ebp),%edx
  103044:	89 d0                	mov    %edx,%eax
  103046:	c1 e0 02             	shl    $0x2,%eax
  103049:	01 d0                	add    %edx,%eax
  10304b:	c1 e0 02             	shl    $0x2,%eax
  10304e:	89 c2                	mov    %eax,%edx
  103050:	8b 45 08             	mov    0x8(%ebp),%eax
  103053:	01 d0                	add    %edx,%eax
  103055:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  103058:	0f 85 46 ff ff ff    	jne    102fa4 <default_free_pages+0x3e>
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
  10305e:	8b 45 08             	mov    0x8(%ebp),%eax
  103061:	8b 55 0c             	mov    0xc(%ebp),%edx
  103064:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
  103067:	8b 45 08             	mov    0x8(%ebp),%eax
  10306a:	83 c0 04             	add    $0x4,%eax
  10306d:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  103074:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  103077:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10307a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10307d:	0f ab 10             	bts    %edx,(%eax)
  103080:	c7 45 cc 10 af 11 00 	movl   $0x11af10,-0x34(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  103087:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10308a:	8b 40 04             	mov    0x4(%eax),%eax
    list_entry_t *le = list_next(&free_list);
  10308d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
  103090:	e9 0b 01 00 00       	jmp    1031a0 <default_free_pages+0x23a>
        p = le2page(le, page_link);
  103095:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103098:	83 e8 0c             	sub    $0xc,%eax
  10309b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10309e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030a1:	89 45 c8             	mov    %eax,-0x38(%ebp)
  1030a4:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1030a7:	8b 40 04             	mov    0x4(%eax),%eax
        le = list_next(le);
  1030aa:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (base + base->property == p) {
  1030ad:	8b 45 08             	mov    0x8(%ebp),%eax
  1030b0:	8b 50 08             	mov    0x8(%eax),%edx
  1030b3:	89 d0                	mov    %edx,%eax
  1030b5:	c1 e0 02             	shl    $0x2,%eax
  1030b8:	01 d0                	add    %edx,%eax
  1030ba:	c1 e0 02             	shl    $0x2,%eax
  1030bd:	89 c2                	mov    %eax,%edx
  1030bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1030c2:	01 d0                	add    %edx,%eax
  1030c4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  1030c7:	75 5d                	jne    103126 <default_free_pages+0x1c0>
            base->property += p->property;
  1030c9:	8b 45 08             	mov    0x8(%ebp),%eax
  1030cc:	8b 50 08             	mov    0x8(%eax),%edx
  1030cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030d2:	8b 40 08             	mov    0x8(%eax),%eax
  1030d5:	01 c2                	add    %eax,%edx
  1030d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1030da:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(p);
  1030dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030e0:	83 c0 04             	add    $0x4,%eax
  1030e3:	c7 45 c4 01 00 00 00 	movl   $0x1,-0x3c(%ebp)
  1030ea:	89 45 c0             	mov    %eax,-0x40(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  1030ed:	8b 45 c0             	mov    -0x40(%ebp),%eax
  1030f0:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  1030f3:	0f b3 10             	btr    %edx,(%eax)
            list_del(&(p->page_link));
  1030f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030f9:	83 c0 0c             	add    $0xc,%eax
  1030fc:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
  1030ff:	8b 45 bc             	mov    -0x44(%ebp),%eax
  103102:	8b 40 04             	mov    0x4(%eax),%eax
  103105:	8b 55 bc             	mov    -0x44(%ebp),%edx
  103108:	8b 12                	mov    (%edx),%edx
  10310a:	89 55 b8             	mov    %edx,-0x48(%ebp)
  10310d:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
  103110:	8b 45 b8             	mov    -0x48(%ebp),%eax
  103113:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  103116:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
  103119:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  10311c:	8b 55 b8             	mov    -0x48(%ebp),%edx
  10311f:	89 10                	mov    %edx,(%eax)
            break;
  103121:	e9 87 00 00 00       	jmp    1031ad <default_free_pages+0x247>
        }
        else if (p + p->property == base) {
  103126:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103129:	8b 50 08             	mov    0x8(%eax),%edx
  10312c:	89 d0                	mov    %edx,%eax
  10312e:	c1 e0 02             	shl    $0x2,%eax
  103131:	01 d0                	add    %edx,%eax
  103133:	c1 e0 02             	shl    $0x2,%eax
  103136:	89 c2                	mov    %eax,%edx
  103138:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10313b:	01 d0                	add    %edx,%eax
  10313d:	3b 45 08             	cmp    0x8(%ebp),%eax
  103140:	75 5e                	jne    1031a0 <default_free_pages+0x23a>
            p->property += base->property;
  103142:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103145:	8b 50 08             	mov    0x8(%eax),%edx
  103148:	8b 45 08             	mov    0x8(%ebp),%eax
  10314b:	8b 40 08             	mov    0x8(%eax),%eax
  10314e:	01 c2                	add    %eax,%edx
  103150:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103153:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(base);
  103156:	8b 45 08             	mov    0x8(%ebp),%eax
  103159:	83 c0 04             	add    $0x4,%eax
  10315c:	c7 45 b0 01 00 00 00 	movl   $0x1,-0x50(%ebp)
  103163:	89 45 ac             	mov    %eax,-0x54(%ebp)
  103166:	8b 45 ac             	mov    -0x54(%ebp),%eax
  103169:	8b 55 b0             	mov    -0x50(%ebp),%edx
  10316c:	0f b3 10             	btr    %edx,(%eax)
            list_del(&(p->page_link));
  10316f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103172:	83 c0 0c             	add    $0xc,%eax
  103175:	89 45 a8             	mov    %eax,-0x58(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
  103178:	8b 45 a8             	mov    -0x58(%ebp),%eax
  10317b:	8b 40 04             	mov    0x4(%eax),%eax
  10317e:	8b 55 a8             	mov    -0x58(%ebp),%edx
  103181:	8b 12                	mov    (%edx),%edx
  103183:	89 55 a4             	mov    %edx,-0x5c(%ebp)
  103186:	89 45 a0             	mov    %eax,-0x60(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
  103189:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  10318c:	8b 55 a0             	mov    -0x60(%ebp),%edx
  10318f:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
  103192:	8b 45 a0             	mov    -0x60(%ebp),%eax
  103195:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  103198:	89 10                	mov    %edx,(%eax)
            base = p;
  10319a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10319d:	89 45 08             	mov    %eax,0x8(%ebp)
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    list_entry_t *le = list_next(&free_list);
    while (le != &free_list) {
  1031a0:	81 7d f0 10 af 11 00 	cmpl   $0x11af10,-0x10(%ebp)
  1031a7:	0f 85 e8 fe ff ff    	jne    103095 <default_free_pages+0x12f>
  1031ad:	c7 45 9c 10 af 11 00 	movl   $0x11af10,-0x64(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  1031b4:	8b 45 9c             	mov    -0x64(%ebp),%eax
  1031b7:	8b 40 04             	mov    0x4(%eax),%eax
            ClearPageProperty(base);
            list_del(&(p->page_link));
            base = p;
        }
    }
    le = list_next(&free_list);
  1031ba:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
  1031bd:	eb 22                	jmp    1031e1 <default_free_pages+0x27b>
        p = le2page(le, page_link);
  1031bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1031c2:	83 e8 0c             	sub    $0xc,%eax
  1031c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
        if (base < p) {
  1031c8:	8b 45 08             	mov    0x8(%ebp),%eax
  1031cb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  1031ce:	73 02                	jae    1031d2 <default_free_pages+0x26c>
            break;
  1031d0:	eb 18                	jmp    1031ea <default_free_pages+0x284>
  1031d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1031d5:	89 45 98             	mov    %eax,-0x68(%ebp)
  1031d8:	8b 45 98             	mov    -0x68(%ebp),%eax
  1031db:	8b 40 04             	mov    0x4(%eax),%eax
        }
        le = list_next(le);
  1031de:	89 45 f0             	mov    %eax,-0x10(%ebp)
            list_del(&(p->page_link));
            base = p;
        }
    }
    le = list_next(&free_list);
    while (le != &free_list) {
  1031e1:	81 7d f0 10 af 11 00 	cmpl   $0x11af10,-0x10(%ebp)
  1031e8:	75 d5                	jne    1031bf <default_free_pages+0x259>
        if (base < p) {
            break;
        }
        le = list_next(le);
    }
    nr_free += n;
  1031ea:	8b 15 18 af 11 00    	mov    0x11af18,%edx
  1031f0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1031f3:	01 d0                	add    %edx,%eax
  1031f5:	a3 18 af 11 00       	mov    %eax,0x11af18
    list_add_before(le, &(base->page_link));
  1031fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1031fd:	8d 50 0c             	lea    0xc(%eax),%edx
  103200:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103203:	89 45 94             	mov    %eax,-0x6c(%ebp)
  103206:	89 55 90             	mov    %edx,-0x70(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
  103209:	8b 45 94             	mov    -0x6c(%ebp),%eax
  10320c:	8b 00                	mov    (%eax),%eax
  10320e:	8b 55 90             	mov    -0x70(%ebp),%edx
  103211:	89 55 8c             	mov    %edx,-0x74(%ebp)
  103214:	89 45 88             	mov    %eax,-0x78(%ebp)
  103217:	8b 45 94             	mov    -0x6c(%ebp),%eax
  10321a:	89 45 84             	mov    %eax,-0x7c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  10321d:	8b 45 84             	mov    -0x7c(%ebp),%eax
  103220:	8b 55 8c             	mov    -0x74(%ebp),%edx
  103223:	89 10                	mov    %edx,(%eax)
  103225:	8b 45 84             	mov    -0x7c(%ebp),%eax
  103228:	8b 10                	mov    (%eax),%edx
  10322a:	8b 45 88             	mov    -0x78(%ebp),%eax
  10322d:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  103230:	8b 45 8c             	mov    -0x74(%ebp),%eax
  103233:	8b 55 84             	mov    -0x7c(%ebp),%edx
  103236:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  103239:	8b 45 8c             	mov    -0x74(%ebp),%eax
  10323c:	8b 55 88             	mov    -0x78(%ebp),%edx
  10323f:	89 10                	mov    %edx,(%eax)
}
  103241:	c9                   	leave  
  103242:	c3                   	ret    

00103243 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void) {
  103243:	55                   	push   %ebp
  103244:	89 e5                	mov    %esp,%ebp
    return nr_free;
  103246:	a1 18 af 11 00       	mov    0x11af18,%eax
}
  10324b:	5d                   	pop    %ebp
  10324c:	c3                   	ret    

0010324d <basic_check>:

static void
basic_check(void) {
  10324d:	55                   	push   %ebp
  10324e:	89 e5                	mov    %esp,%ebp
  103250:	83 ec 48             	sub    $0x48,%esp
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
  103253:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10325a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10325d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103260:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103263:	89 45 ec             	mov    %eax,-0x14(%ebp)
    assert((p0 = alloc_page()) != NULL);
  103266:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10326d:	e8 d6 0e 00 00       	call   104148 <alloc_pages>
  103272:	89 45 ec             	mov    %eax,-0x14(%ebp)
  103275:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  103279:	75 24                	jne    10329f <basic_check+0x52>
  10327b:	c7 44 24 0c 19 6a 10 	movl   $0x106a19,0xc(%esp)
  103282:	00 
  103283:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  10328a:	00 
  10328b:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
  103292:	00 
  103293:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  10329a:	e8 38 da ff ff       	call   100cd7 <__panic>
    assert((p1 = alloc_page()) != NULL);
  10329f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1032a6:	e8 9d 0e 00 00       	call   104148 <alloc_pages>
  1032ab:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1032ae:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1032b2:	75 24                	jne    1032d8 <basic_check+0x8b>
  1032b4:	c7 44 24 0c 35 6a 10 	movl   $0x106a35,0xc(%esp)
  1032bb:	00 
  1032bc:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  1032c3:	00 
  1032c4:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  1032cb:	00 
  1032cc:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  1032d3:	e8 ff d9 ff ff       	call   100cd7 <__panic>
    assert((p2 = alloc_page()) != NULL);
  1032d8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1032df:	e8 64 0e 00 00       	call   104148 <alloc_pages>
  1032e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1032e7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1032eb:	75 24                	jne    103311 <basic_check+0xc4>
  1032ed:	c7 44 24 0c 51 6a 10 	movl   $0x106a51,0xc(%esp)
  1032f4:	00 
  1032f5:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  1032fc:	00 
  1032fd:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
  103304:	00 
  103305:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  10330c:	e8 c6 d9 ff ff       	call   100cd7 <__panic>

    assert(p0 != p1 && p0 != p2 && p1 != p2);
  103311:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103314:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  103317:	74 10                	je     103329 <basic_check+0xdc>
  103319:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10331c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  10331f:	74 08                	je     103329 <basic_check+0xdc>
  103321:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103324:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  103327:	75 24                	jne    10334d <basic_check+0x100>
  103329:	c7 44 24 0c 70 6a 10 	movl   $0x106a70,0xc(%esp)
  103330:	00 
  103331:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103338:	00 
  103339:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  103340:	00 
  103341:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103348:	e8 8a d9 ff ff       	call   100cd7 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
  10334d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103350:	89 04 24             	mov    %eax,(%esp)
  103353:	e8 f9 f8 ff ff       	call   102c51 <page_ref>
  103358:	85 c0                	test   %eax,%eax
  10335a:	75 1e                	jne    10337a <basic_check+0x12d>
  10335c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10335f:	89 04 24             	mov    %eax,(%esp)
  103362:	e8 ea f8 ff ff       	call   102c51 <page_ref>
  103367:	85 c0                	test   %eax,%eax
  103369:	75 0f                	jne    10337a <basic_check+0x12d>
  10336b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10336e:	89 04 24             	mov    %eax,(%esp)
  103371:	e8 db f8 ff ff       	call   102c51 <page_ref>
  103376:	85 c0                	test   %eax,%eax
  103378:	74 24                	je     10339e <basic_check+0x151>
  10337a:	c7 44 24 0c 94 6a 10 	movl   $0x106a94,0xc(%esp)
  103381:	00 
  103382:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103389:	00 
  10338a:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  103391:	00 
  103392:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103399:	e8 39 d9 ff ff       	call   100cd7 <__panic>

    assert(page2pa(p0) < npage * PGSIZE);
  10339e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1033a1:	89 04 24             	mov    %eax,(%esp)
  1033a4:	e8 92 f8 ff ff       	call   102c3b <page2pa>
  1033a9:	8b 15 80 ae 11 00    	mov    0x11ae80,%edx
  1033af:	c1 e2 0c             	shl    $0xc,%edx
  1033b2:	39 d0                	cmp    %edx,%eax
  1033b4:	72 24                	jb     1033da <basic_check+0x18d>
  1033b6:	c7 44 24 0c d0 6a 10 	movl   $0x106ad0,0xc(%esp)
  1033bd:	00 
  1033be:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  1033c5:	00 
  1033c6:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
  1033cd:	00 
  1033ce:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  1033d5:	e8 fd d8 ff ff       	call   100cd7 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
  1033da:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1033dd:	89 04 24             	mov    %eax,(%esp)
  1033e0:	e8 56 f8 ff ff       	call   102c3b <page2pa>
  1033e5:	8b 15 80 ae 11 00    	mov    0x11ae80,%edx
  1033eb:	c1 e2 0c             	shl    $0xc,%edx
  1033ee:	39 d0                	cmp    %edx,%eax
  1033f0:	72 24                	jb     103416 <basic_check+0x1c9>
  1033f2:	c7 44 24 0c ed 6a 10 	movl   $0x106aed,0xc(%esp)
  1033f9:	00 
  1033fa:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103401:	00 
  103402:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  103409:	00 
  10340a:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103411:	e8 c1 d8 ff ff       	call   100cd7 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
  103416:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103419:	89 04 24             	mov    %eax,(%esp)
  10341c:	e8 1a f8 ff ff       	call   102c3b <page2pa>
  103421:	8b 15 80 ae 11 00    	mov    0x11ae80,%edx
  103427:	c1 e2 0c             	shl    $0xc,%edx
  10342a:	39 d0                	cmp    %edx,%eax
  10342c:	72 24                	jb     103452 <basic_check+0x205>
  10342e:	c7 44 24 0c 0a 6b 10 	movl   $0x106b0a,0xc(%esp)
  103435:	00 
  103436:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  10343d:	00 
  10343e:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  103445:	00 
  103446:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  10344d:	e8 85 d8 ff ff       	call   100cd7 <__panic>

    list_entry_t free_list_store = free_list;
  103452:	a1 10 af 11 00       	mov    0x11af10,%eax
  103457:	8b 15 14 af 11 00    	mov    0x11af14,%edx
  10345d:	89 45 d0             	mov    %eax,-0x30(%ebp)
  103460:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  103463:	c7 45 e0 10 af 11 00 	movl   $0x11af10,-0x20(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
  10346a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10346d:	8b 55 e0             	mov    -0x20(%ebp),%edx
  103470:	89 50 04             	mov    %edx,0x4(%eax)
  103473:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103476:	8b 50 04             	mov    0x4(%eax),%edx
  103479:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10347c:	89 10                	mov    %edx,(%eax)
  10347e:	c7 45 dc 10 af 11 00 	movl   $0x11af10,-0x24(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
  103485:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103488:	8b 40 04             	mov    0x4(%eax),%eax
  10348b:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  10348e:	0f 94 c0             	sete   %al
  103491:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
  103494:	85 c0                	test   %eax,%eax
  103496:	75 24                	jne    1034bc <basic_check+0x26f>
  103498:	c7 44 24 0c 27 6b 10 	movl   $0x106b27,0xc(%esp)
  10349f:	00 
  1034a0:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  1034a7:	00 
  1034a8:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
  1034af:	00 
  1034b0:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  1034b7:	e8 1b d8 ff ff       	call   100cd7 <__panic>

    unsigned int nr_free_store = nr_free;
  1034bc:	a1 18 af 11 00       	mov    0x11af18,%eax
  1034c1:	89 45 e8             	mov    %eax,-0x18(%ebp)
    nr_free = 0;
  1034c4:	c7 05 18 af 11 00 00 	movl   $0x0,0x11af18
  1034cb:	00 00 00 

    assert(alloc_page() == NULL);
  1034ce:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1034d5:	e8 6e 0c 00 00       	call   104148 <alloc_pages>
  1034da:	85 c0                	test   %eax,%eax
  1034dc:	74 24                	je     103502 <basic_check+0x2b5>
  1034de:	c7 44 24 0c 3e 6b 10 	movl   $0x106b3e,0xc(%esp)
  1034e5:	00 
  1034e6:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  1034ed:	00 
  1034ee:	c7 44 24 04 db 00 00 	movl   $0xdb,0x4(%esp)
  1034f5:	00 
  1034f6:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  1034fd:	e8 d5 d7 ff ff       	call   100cd7 <__panic>

    free_page(p0);
  103502:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103509:	00 
  10350a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10350d:	89 04 24             	mov    %eax,(%esp)
  103510:	e8 6b 0c 00 00       	call   104180 <free_pages>
    free_page(p1);
  103515:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10351c:	00 
  10351d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103520:	89 04 24             	mov    %eax,(%esp)
  103523:	e8 58 0c 00 00       	call   104180 <free_pages>
    free_page(p2);
  103528:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10352f:	00 
  103530:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103533:	89 04 24             	mov    %eax,(%esp)
  103536:	e8 45 0c 00 00       	call   104180 <free_pages>
    assert(nr_free == 3);
  10353b:	a1 18 af 11 00       	mov    0x11af18,%eax
  103540:	83 f8 03             	cmp    $0x3,%eax
  103543:	74 24                	je     103569 <basic_check+0x31c>
  103545:	c7 44 24 0c 53 6b 10 	movl   $0x106b53,0xc(%esp)
  10354c:	00 
  10354d:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103554:	00 
  103555:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
  10355c:	00 
  10355d:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103564:	e8 6e d7 ff ff       	call   100cd7 <__panic>

    assert((p0 = alloc_page()) != NULL);
  103569:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  103570:	e8 d3 0b 00 00       	call   104148 <alloc_pages>
  103575:	89 45 ec             	mov    %eax,-0x14(%ebp)
  103578:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10357c:	75 24                	jne    1035a2 <basic_check+0x355>
  10357e:	c7 44 24 0c 19 6a 10 	movl   $0x106a19,0xc(%esp)
  103585:	00 
  103586:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  10358d:	00 
  10358e:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  103595:	00 
  103596:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  10359d:	e8 35 d7 ff ff       	call   100cd7 <__panic>
    assert((p1 = alloc_page()) != NULL);
  1035a2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1035a9:	e8 9a 0b 00 00       	call   104148 <alloc_pages>
  1035ae:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1035b1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1035b5:	75 24                	jne    1035db <basic_check+0x38e>
  1035b7:	c7 44 24 0c 35 6a 10 	movl   $0x106a35,0xc(%esp)
  1035be:	00 
  1035bf:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  1035c6:	00 
  1035c7:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  1035ce:	00 
  1035cf:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  1035d6:	e8 fc d6 ff ff       	call   100cd7 <__panic>
    assert((p2 = alloc_page()) != NULL);
  1035db:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1035e2:	e8 61 0b 00 00       	call   104148 <alloc_pages>
  1035e7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1035ea:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1035ee:	75 24                	jne    103614 <basic_check+0x3c7>
  1035f0:	c7 44 24 0c 51 6a 10 	movl   $0x106a51,0xc(%esp)
  1035f7:	00 
  1035f8:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  1035ff:	00 
  103600:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  103607:	00 
  103608:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  10360f:	e8 c3 d6 ff ff       	call   100cd7 <__panic>

    assert(alloc_page() == NULL);
  103614:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10361b:	e8 28 0b 00 00       	call   104148 <alloc_pages>
  103620:	85 c0                	test   %eax,%eax
  103622:	74 24                	je     103648 <basic_check+0x3fb>
  103624:	c7 44 24 0c 3e 6b 10 	movl   $0x106b3e,0xc(%esp)
  10362b:	00 
  10362c:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103633:	00 
  103634:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
  10363b:	00 
  10363c:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103643:	e8 8f d6 ff ff       	call   100cd7 <__panic>

    free_page(p0);
  103648:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10364f:	00 
  103650:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103653:	89 04 24             	mov    %eax,(%esp)
  103656:	e8 25 0b 00 00       	call   104180 <free_pages>
  10365b:	c7 45 d8 10 af 11 00 	movl   $0x11af10,-0x28(%ebp)
  103662:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103665:	8b 40 04             	mov    0x4(%eax),%eax
  103668:	39 45 d8             	cmp    %eax,-0x28(%ebp)
  10366b:	0f 94 c0             	sete   %al
  10366e:	0f b6 c0             	movzbl %al,%eax
    assert(!list_empty(&free_list));
  103671:	85 c0                	test   %eax,%eax
  103673:	74 24                	je     103699 <basic_check+0x44c>
  103675:	c7 44 24 0c 60 6b 10 	movl   $0x106b60,0xc(%esp)
  10367c:	00 
  10367d:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103684:	00 
  103685:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
  10368c:	00 
  10368d:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103694:	e8 3e d6 ff ff       	call   100cd7 <__panic>

    struct Page *p;
    assert((p = alloc_page()) == p0);
  103699:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1036a0:	e8 a3 0a 00 00       	call   104148 <alloc_pages>
  1036a5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1036a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1036ab:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1036ae:	74 24                	je     1036d4 <basic_check+0x487>
  1036b0:	c7 44 24 0c 78 6b 10 	movl   $0x106b78,0xc(%esp)
  1036b7:	00 
  1036b8:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  1036bf:	00 
  1036c0:	c7 44 24 04 ec 00 00 	movl   $0xec,0x4(%esp)
  1036c7:	00 
  1036c8:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  1036cf:	e8 03 d6 ff ff       	call   100cd7 <__panic>
    assert(alloc_page() == NULL);
  1036d4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1036db:	e8 68 0a 00 00       	call   104148 <alloc_pages>
  1036e0:	85 c0                	test   %eax,%eax
  1036e2:	74 24                	je     103708 <basic_check+0x4bb>
  1036e4:	c7 44 24 0c 3e 6b 10 	movl   $0x106b3e,0xc(%esp)
  1036eb:	00 
  1036ec:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  1036f3:	00 
  1036f4:	c7 44 24 04 ed 00 00 	movl   $0xed,0x4(%esp)
  1036fb:	00 
  1036fc:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103703:	e8 cf d5 ff ff       	call   100cd7 <__panic>

    assert(nr_free == 0);
  103708:	a1 18 af 11 00       	mov    0x11af18,%eax
  10370d:	85 c0                	test   %eax,%eax
  10370f:	74 24                	je     103735 <basic_check+0x4e8>
  103711:	c7 44 24 0c 91 6b 10 	movl   $0x106b91,0xc(%esp)
  103718:	00 
  103719:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103720:	00 
  103721:	c7 44 24 04 ef 00 00 	movl   $0xef,0x4(%esp)
  103728:	00 
  103729:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103730:	e8 a2 d5 ff ff       	call   100cd7 <__panic>
    free_list = free_list_store;
  103735:	8b 45 d0             	mov    -0x30(%ebp),%eax
  103738:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10373b:	a3 10 af 11 00       	mov    %eax,0x11af10
  103740:	89 15 14 af 11 00    	mov    %edx,0x11af14
    nr_free = nr_free_store;
  103746:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103749:	a3 18 af 11 00       	mov    %eax,0x11af18

    free_page(p);
  10374e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103755:	00 
  103756:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103759:	89 04 24             	mov    %eax,(%esp)
  10375c:	e8 1f 0a 00 00       	call   104180 <free_pages>
    free_page(p1);
  103761:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103768:	00 
  103769:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10376c:	89 04 24             	mov    %eax,(%esp)
  10376f:	e8 0c 0a 00 00       	call   104180 <free_pages>
    free_page(p2);
  103774:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10377b:	00 
  10377c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10377f:	89 04 24             	mov    %eax,(%esp)
  103782:	e8 f9 09 00 00       	call   104180 <free_pages>
}
  103787:	c9                   	leave  
  103788:	c3                   	ret    

00103789 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
  103789:	55                   	push   %ebp
  10378a:	89 e5                	mov    %esp,%ebp
  10378c:	53                   	push   %ebx
  10378d:	81 ec 94 00 00 00    	sub    $0x94,%esp
    int count = 0, total = 0;
  103793:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10379a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    list_entry_t *le = &free_list;
  1037a1:	c7 45 ec 10 af 11 00 	movl   $0x11af10,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
  1037a8:	eb 6b                	jmp    103815 <default_check+0x8c>
        struct Page *p = le2page(le, page_link);
  1037aa:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1037ad:	83 e8 0c             	sub    $0xc,%eax
  1037b0:	89 45 e8             	mov    %eax,-0x18(%ebp)
        assert(PageProperty(p));
  1037b3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1037b6:	83 c0 04             	add    $0x4,%eax
  1037b9:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  1037c0:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  1037c3:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1037c6:	8b 55 d0             	mov    -0x30(%ebp),%edx
  1037c9:	0f a3 10             	bt     %edx,(%eax)
  1037cc:	19 c0                	sbb    %eax,%eax
  1037ce:	89 45 c8             	mov    %eax,-0x38(%ebp)
    return oldbit != 0;
  1037d1:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
  1037d5:	0f 95 c0             	setne  %al
  1037d8:	0f b6 c0             	movzbl %al,%eax
  1037db:	85 c0                	test   %eax,%eax
  1037dd:	75 24                	jne    103803 <default_check+0x7a>
  1037df:	c7 44 24 0c 9e 6b 10 	movl   $0x106b9e,0xc(%esp)
  1037e6:	00 
  1037e7:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  1037ee:	00 
  1037ef:	c7 44 24 04 00 01 00 	movl   $0x100,0x4(%esp)
  1037f6:	00 
  1037f7:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  1037fe:	e8 d4 d4 ff ff       	call   100cd7 <__panic>
        count ++, total += p->property;
  103803:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  103807:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10380a:	8b 50 08             	mov    0x8(%eax),%edx
  10380d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103810:	01 d0                	add    %edx,%eax
  103812:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103815:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103818:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  10381b:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  10381e:	8b 40 04             	mov    0x4(%eax),%eax
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
  103821:	89 45 ec             	mov    %eax,-0x14(%ebp)
  103824:	81 7d ec 10 af 11 00 	cmpl   $0x11af10,-0x14(%ebp)
  10382b:	0f 85 79 ff ff ff    	jne    1037aa <default_check+0x21>
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());
  103831:	8b 5d f0             	mov    -0x10(%ebp),%ebx
  103834:	e8 79 09 00 00       	call   1041b2 <nr_free_pages>
  103839:	39 c3                	cmp    %eax,%ebx
  10383b:	74 24                	je     103861 <default_check+0xd8>
  10383d:	c7 44 24 0c ae 6b 10 	movl   $0x106bae,0xc(%esp)
  103844:	00 
  103845:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  10384c:	00 
  10384d:	c7 44 24 04 03 01 00 	movl   $0x103,0x4(%esp)
  103854:	00 
  103855:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  10385c:	e8 76 d4 ff ff       	call   100cd7 <__panic>

    basic_check();
  103861:	e8 e7 f9 ff ff       	call   10324d <basic_check>

    struct Page *p0 = alloc_pages(5), *p1, *p2;
  103866:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
  10386d:	e8 d6 08 00 00       	call   104148 <alloc_pages>
  103872:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(p0 != NULL);
  103875:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  103879:	75 24                	jne    10389f <default_check+0x116>
  10387b:	c7 44 24 0c c7 6b 10 	movl   $0x106bc7,0xc(%esp)
  103882:	00 
  103883:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  10388a:	00 
  10388b:	c7 44 24 04 08 01 00 	movl   $0x108,0x4(%esp)
  103892:	00 
  103893:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  10389a:	e8 38 d4 ff ff       	call   100cd7 <__panic>
    assert(!PageProperty(p0));
  10389f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1038a2:	83 c0 04             	add    $0x4,%eax
  1038a5:	c7 45 c0 01 00 00 00 	movl   $0x1,-0x40(%ebp)
  1038ac:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  1038af:	8b 45 bc             	mov    -0x44(%ebp),%eax
  1038b2:	8b 55 c0             	mov    -0x40(%ebp),%edx
  1038b5:	0f a3 10             	bt     %edx,(%eax)
  1038b8:	19 c0                	sbb    %eax,%eax
  1038ba:	89 45 b8             	mov    %eax,-0x48(%ebp)
    return oldbit != 0;
  1038bd:	83 7d b8 00          	cmpl   $0x0,-0x48(%ebp)
  1038c1:	0f 95 c0             	setne  %al
  1038c4:	0f b6 c0             	movzbl %al,%eax
  1038c7:	85 c0                	test   %eax,%eax
  1038c9:	74 24                	je     1038ef <default_check+0x166>
  1038cb:	c7 44 24 0c d2 6b 10 	movl   $0x106bd2,0xc(%esp)
  1038d2:	00 
  1038d3:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  1038da:	00 
  1038db:	c7 44 24 04 09 01 00 	movl   $0x109,0x4(%esp)
  1038e2:	00 
  1038e3:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  1038ea:	e8 e8 d3 ff ff       	call   100cd7 <__panic>

    list_entry_t free_list_store = free_list;
  1038ef:	a1 10 af 11 00       	mov    0x11af10,%eax
  1038f4:	8b 15 14 af 11 00    	mov    0x11af14,%edx
  1038fa:	89 45 80             	mov    %eax,-0x80(%ebp)
  1038fd:	89 55 84             	mov    %edx,-0x7c(%ebp)
  103900:	c7 45 b4 10 af 11 00 	movl   $0x11af10,-0x4c(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
  103907:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  10390a:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  10390d:	89 50 04             	mov    %edx,0x4(%eax)
  103910:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  103913:	8b 50 04             	mov    0x4(%eax),%edx
  103916:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  103919:	89 10                	mov    %edx,(%eax)
  10391b:	c7 45 b0 10 af 11 00 	movl   $0x11af10,-0x50(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
  103922:	8b 45 b0             	mov    -0x50(%ebp),%eax
  103925:	8b 40 04             	mov    0x4(%eax),%eax
  103928:	39 45 b0             	cmp    %eax,-0x50(%ebp)
  10392b:	0f 94 c0             	sete   %al
  10392e:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
  103931:	85 c0                	test   %eax,%eax
  103933:	75 24                	jne    103959 <default_check+0x1d0>
  103935:	c7 44 24 0c 27 6b 10 	movl   $0x106b27,0xc(%esp)
  10393c:	00 
  10393d:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103944:	00 
  103945:	c7 44 24 04 0d 01 00 	movl   $0x10d,0x4(%esp)
  10394c:	00 
  10394d:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103954:	e8 7e d3 ff ff       	call   100cd7 <__panic>
    assert(alloc_page() == NULL);
  103959:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  103960:	e8 e3 07 00 00       	call   104148 <alloc_pages>
  103965:	85 c0                	test   %eax,%eax
  103967:	74 24                	je     10398d <default_check+0x204>
  103969:	c7 44 24 0c 3e 6b 10 	movl   $0x106b3e,0xc(%esp)
  103970:	00 
  103971:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103978:	00 
  103979:	c7 44 24 04 0e 01 00 	movl   $0x10e,0x4(%esp)
  103980:	00 
  103981:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103988:	e8 4a d3 ff ff       	call   100cd7 <__panic>

    unsigned int nr_free_store = nr_free;
  10398d:	a1 18 af 11 00       	mov    0x11af18,%eax
  103992:	89 45 e0             	mov    %eax,-0x20(%ebp)
    nr_free = 0;
  103995:	c7 05 18 af 11 00 00 	movl   $0x0,0x11af18
  10399c:	00 00 00 

    free_pages(p0 + 2, 3);
  10399f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1039a2:	83 c0 28             	add    $0x28,%eax
  1039a5:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
  1039ac:	00 
  1039ad:	89 04 24             	mov    %eax,(%esp)
  1039b0:	e8 cb 07 00 00       	call   104180 <free_pages>
    assert(alloc_pages(4) == NULL);
  1039b5:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  1039bc:	e8 87 07 00 00       	call   104148 <alloc_pages>
  1039c1:	85 c0                	test   %eax,%eax
  1039c3:	74 24                	je     1039e9 <default_check+0x260>
  1039c5:	c7 44 24 0c e4 6b 10 	movl   $0x106be4,0xc(%esp)
  1039cc:	00 
  1039cd:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  1039d4:	00 
  1039d5:	c7 44 24 04 14 01 00 	movl   $0x114,0x4(%esp)
  1039dc:	00 
  1039dd:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  1039e4:	e8 ee d2 ff ff       	call   100cd7 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
  1039e9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1039ec:	83 c0 28             	add    $0x28,%eax
  1039ef:	83 c0 04             	add    $0x4,%eax
  1039f2:	c7 45 ac 01 00 00 00 	movl   $0x1,-0x54(%ebp)
  1039f9:	89 45 a8             	mov    %eax,-0x58(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  1039fc:	8b 45 a8             	mov    -0x58(%ebp),%eax
  1039ff:	8b 55 ac             	mov    -0x54(%ebp),%edx
  103a02:	0f a3 10             	bt     %edx,(%eax)
  103a05:	19 c0                	sbb    %eax,%eax
  103a07:	89 45 a4             	mov    %eax,-0x5c(%ebp)
    return oldbit != 0;
  103a0a:	83 7d a4 00          	cmpl   $0x0,-0x5c(%ebp)
  103a0e:	0f 95 c0             	setne  %al
  103a11:	0f b6 c0             	movzbl %al,%eax
  103a14:	85 c0                	test   %eax,%eax
  103a16:	74 0e                	je     103a26 <default_check+0x29d>
  103a18:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103a1b:	83 c0 28             	add    $0x28,%eax
  103a1e:	8b 40 08             	mov    0x8(%eax),%eax
  103a21:	83 f8 03             	cmp    $0x3,%eax
  103a24:	74 24                	je     103a4a <default_check+0x2c1>
  103a26:	c7 44 24 0c fc 6b 10 	movl   $0x106bfc,0xc(%esp)
  103a2d:	00 
  103a2e:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103a35:	00 
  103a36:	c7 44 24 04 15 01 00 	movl   $0x115,0x4(%esp)
  103a3d:	00 
  103a3e:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103a45:	e8 8d d2 ff ff       	call   100cd7 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
  103a4a:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
  103a51:	e8 f2 06 00 00       	call   104148 <alloc_pages>
  103a56:	89 45 dc             	mov    %eax,-0x24(%ebp)
  103a59:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  103a5d:	75 24                	jne    103a83 <default_check+0x2fa>
  103a5f:	c7 44 24 0c 28 6c 10 	movl   $0x106c28,0xc(%esp)
  103a66:	00 
  103a67:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103a6e:	00 
  103a6f:	c7 44 24 04 16 01 00 	movl   $0x116,0x4(%esp)
  103a76:	00 
  103a77:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103a7e:	e8 54 d2 ff ff       	call   100cd7 <__panic>
    assert(alloc_page() == NULL);
  103a83:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  103a8a:	e8 b9 06 00 00       	call   104148 <alloc_pages>
  103a8f:	85 c0                	test   %eax,%eax
  103a91:	74 24                	je     103ab7 <default_check+0x32e>
  103a93:	c7 44 24 0c 3e 6b 10 	movl   $0x106b3e,0xc(%esp)
  103a9a:	00 
  103a9b:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103aa2:	00 
  103aa3:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
  103aaa:	00 
  103aab:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103ab2:	e8 20 d2 ff ff       	call   100cd7 <__panic>
    assert(p0 + 2 == p1);
  103ab7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103aba:	83 c0 28             	add    $0x28,%eax
  103abd:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  103ac0:	74 24                	je     103ae6 <default_check+0x35d>
  103ac2:	c7 44 24 0c 46 6c 10 	movl   $0x106c46,0xc(%esp)
  103ac9:	00 
  103aca:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103ad1:	00 
  103ad2:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
  103ad9:	00 
  103ada:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103ae1:	e8 f1 d1 ff ff       	call   100cd7 <__panic>

    p2 = p0 + 1;
  103ae6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103ae9:	83 c0 14             	add    $0x14,%eax
  103aec:	89 45 d8             	mov    %eax,-0x28(%ebp)
    free_page(p0);
  103aef:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103af6:	00 
  103af7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103afa:	89 04 24             	mov    %eax,(%esp)
  103afd:	e8 7e 06 00 00       	call   104180 <free_pages>
    free_pages(p1, 3);
  103b02:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
  103b09:	00 
  103b0a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103b0d:	89 04 24             	mov    %eax,(%esp)
  103b10:	e8 6b 06 00 00       	call   104180 <free_pages>
    assert(PageProperty(p0) && p0->property == 1);
  103b15:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103b18:	83 c0 04             	add    $0x4,%eax
  103b1b:	c7 45 a0 01 00 00 00 	movl   $0x1,-0x60(%ebp)
  103b22:	89 45 9c             	mov    %eax,-0x64(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  103b25:	8b 45 9c             	mov    -0x64(%ebp),%eax
  103b28:	8b 55 a0             	mov    -0x60(%ebp),%edx
  103b2b:	0f a3 10             	bt     %edx,(%eax)
  103b2e:	19 c0                	sbb    %eax,%eax
  103b30:	89 45 98             	mov    %eax,-0x68(%ebp)
    return oldbit != 0;
  103b33:	83 7d 98 00          	cmpl   $0x0,-0x68(%ebp)
  103b37:	0f 95 c0             	setne  %al
  103b3a:	0f b6 c0             	movzbl %al,%eax
  103b3d:	85 c0                	test   %eax,%eax
  103b3f:	74 0b                	je     103b4c <default_check+0x3c3>
  103b41:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103b44:	8b 40 08             	mov    0x8(%eax),%eax
  103b47:	83 f8 01             	cmp    $0x1,%eax
  103b4a:	74 24                	je     103b70 <default_check+0x3e7>
  103b4c:	c7 44 24 0c 54 6c 10 	movl   $0x106c54,0xc(%esp)
  103b53:	00 
  103b54:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103b5b:	00 
  103b5c:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
  103b63:	00 
  103b64:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103b6b:	e8 67 d1 ff ff       	call   100cd7 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
  103b70:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103b73:	83 c0 04             	add    $0x4,%eax
  103b76:	c7 45 94 01 00 00 00 	movl   $0x1,-0x6c(%ebp)
  103b7d:	89 45 90             	mov    %eax,-0x70(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  103b80:	8b 45 90             	mov    -0x70(%ebp),%eax
  103b83:	8b 55 94             	mov    -0x6c(%ebp),%edx
  103b86:	0f a3 10             	bt     %edx,(%eax)
  103b89:	19 c0                	sbb    %eax,%eax
  103b8b:	89 45 8c             	mov    %eax,-0x74(%ebp)
    return oldbit != 0;
  103b8e:	83 7d 8c 00          	cmpl   $0x0,-0x74(%ebp)
  103b92:	0f 95 c0             	setne  %al
  103b95:	0f b6 c0             	movzbl %al,%eax
  103b98:	85 c0                	test   %eax,%eax
  103b9a:	74 0b                	je     103ba7 <default_check+0x41e>
  103b9c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103b9f:	8b 40 08             	mov    0x8(%eax),%eax
  103ba2:	83 f8 03             	cmp    $0x3,%eax
  103ba5:	74 24                	je     103bcb <default_check+0x442>
  103ba7:	c7 44 24 0c 7c 6c 10 	movl   $0x106c7c,0xc(%esp)
  103bae:	00 
  103baf:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103bb6:	00 
  103bb7:	c7 44 24 04 1e 01 00 	movl   $0x11e,0x4(%esp)
  103bbe:	00 
  103bbf:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103bc6:	e8 0c d1 ff ff       	call   100cd7 <__panic>

    assert((p0 = alloc_page()) == p2 - 1);
  103bcb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  103bd2:	e8 71 05 00 00       	call   104148 <alloc_pages>
  103bd7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  103bda:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103bdd:	83 e8 14             	sub    $0x14,%eax
  103be0:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
  103be3:	74 24                	je     103c09 <default_check+0x480>
  103be5:	c7 44 24 0c a2 6c 10 	movl   $0x106ca2,0xc(%esp)
  103bec:	00 
  103bed:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103bf4:	00 
  103bf5:	c7 44 24 04 20 01 00 	movl   $0x120,0x4(%esp)
  103bfc:	00 
  103bfd:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103c04:	e8 ce d0 ff ff       	call   100cd7 <__panic>
    free_page(p0);
  103c09:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103c10:	00 
  103c11:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103c14:	89 04 24             	mov    %eax,(%esp)
  103c17:	e8 64 05 00 00       	call   104180 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
  103c1c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  103c23:	e8 20 05 00 00       	call   104148 <alloc_pages>
  103c28:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  103c2b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103c2e:	83 c0 14             	add    $0x14,%eax
  103c31:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
  103c34:	74 24                	je     103c5a <default_check+0x4d1>
  103c36:	c7 44 24 0c c0 6c 10 	movl   $0x106cc0,0xc(%esp)
  103c3d:	00 
  103c3e:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103c45:	00 
  103c46:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
  103c4d:	00 
  103c4e:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103c55:	e8 7d d0 ff ff       	call   100cd7 <__panic>

    free_pages(p0, 2);
  103c5a:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  103c61:	00 
  103c62:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103c65:	89 04 24             	mov    %eax,(%esp)
  103c68:	e8 13 05 00 00       	call   104180 <free_pages>
    free_page(p2);
  103c6d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103c74:	00 
  103c75:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103c78:	89 04 24             	mov    %eax,(%esp)
  103c7b:	e8 00 05 00 00       	call   104180 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
  103c80:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
  103c87:	e8 bc 04 00 00       	call   104148 <alloc_pages>
  103c8c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  103c8f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  103c93:	75 24                	jne    103cb9 <default_check+0x530>
  103c95:	c7 44 24 0c e0 6c 10 	movl   $0x106ce0,0xc(%esp)
  103c9c:	00 
  103c9d:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103ca4:	00 
  103ca5:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  103cac:	00 
  103cad:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103cb4:	e8 1e d0 ff ff       	call   100cd7 <__panic>
    assert(alloc_page() == NULL);
  103cb9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  103cc0:	e8 83 04 00 00       	call   104148 <alloc_pages>
  103cc5:	85 c0                	test   %eax,%eax
  103cc7:	74 24                	je     103ced <default_check+0x564>
  103cc9:	c7 44 24 0c 3e 6b 10 	movl   $0x106b3e,0xc(%esp)
  103cd0:	00 
  103cd1:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103cd8:	00 
  103cd9:	c7 44 24 04 28 01 00 	movl   $0x128,0x4(%esp)
  103ce0:	00 
  103ce1:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103ce8:	e8 ea cf ff ff       	call   100cd7 <__panic>

    assert(nr_free == 0);
  103ced:	a1 18 af 11 00       	mov    0x11af18,%eax
  103cf2:	85 c0                	test   %eax,%eax
  103cf4:	74 24                	je     103d1a <default_check+0x591>
  103cf6:	c7 44 24 0c 91 6b 10 	movl   $0x106b91,0xc(%esp)
  103cfd:	00 
  103cfe:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103d05:	00 
  103d06:	c7 44 24 04 2a 01 00 	movl   $0x12a,0x4(%esp)
  103d0d:	00 
  103d0e:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103d15:	e8 bd cf ff ff       	call   100cd7 <__panic>
    nr_free = nr_free_store;
  103d1a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103d1d:	a3 18 af 11 00       	mov    %eax,0x11af18

    free_list = free_list_store;
  103d22:	8b 45 80             	mov    -0x80(%ebp),%eax
  103d25:	8b 55 84             	mov    -0x7c(%ebp),%edx
  103d28:	a3 10 af 11 00       	mov    %eax,0x11af10
  103d2d:	89 15 14 af 11 00    	mov    %edx,0x11af14
    free_pages(p0, 5);
  103d33:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
  103d3a:	00 
  103d3b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103d3e:	89 04 24             	mov    %eax,(%esp)
  103d41:	e8 3a 04 00 00       	call   104180 <free_pages>

    le = &free_list;
  103d46:	c7 45 ec 10 af 11 00 	movl   $0x11af10,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
  103d4d:	eb 5b                	jmp    103daa <default_check+0x621>
        assert(le->next->prev == le && le->prev->next == le);
  103d4f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103d52:	8b 40 04             	mov    0x4(%eax),%eax
  103d55:	8b 00                	mov    (%eax),%eax
  103d57:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  103d5a:	75 0d                	jne    103d69 <default_check+0x5e0>
  103d5c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103d5f:	8b 00                	mov    (%eax),%eax
  103d61:	8b 40 04             	mov    0x4(%eax),%eax
  103d64:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  103d67:	74 24                	je     103d8d <default_check+0x604>
  103d69:	c7 44 24 0c 00 6d 10 	movl   $0x106d00,0xc(%esp)
  103d70:	00 
  103d71:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103d78:	00 
  103d79:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
  103d80:	00 
  103d81:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103d88:	e8 4a cf ff ff       	call   100cd7 <__panic>
        struct Page *p = le2page(le, page_link);
  103d8d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103d90:	83 e8 0c             	sub    $0xc,%eax
  103d93:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        count --, total -= p->property;
  103d96:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
  103d9a:	8b 55 f0             	mov    -0x10(%ebp),%edx
  103d9d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  103da0:	8b 40 08             	mov    0x8(%eax),%eax
  103da3:	29 c2                	sub    %eax,%edx
  103da5:	89 d0                	mov    %edx,%eax
  103da7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103daa:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103dad:	89 45 88             	mov    %eax,-0x78(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  103db0:	8b 45 88             	mov    -0x78(%ebp),%eax
  103db3:	8b 40 04             	mov    0x4(%eax),%eax

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
  103db6:	89 45 ec             	mov    %eax,-0x14(%ebp)
  103db9:	81 7d ec 10 af 11 00 	cmpl   $0x11af10,-0x14(%ebp)
  103dc0:	75 8d                	jne    103d4f <default_check+0x5c6>
        assert(le->next->prev == le && le->prev->next == le);
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
  103dc2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103dc6:	74 24                	je     103dec <default_check+0x663>
  103dc8:	c7 44 24 0c 2d 6d 10 	movl   $0x106d2d,0xc(%esp)
  103dcf:	00 
  103dd0:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103dd7:	00 
  103dd8:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
  103ddf:	00 
  103de0:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103de7:	e8 eb ce ff ff       	call   100cd7 <__panic>
    assert(total == 0);
  103dec:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  103df0:	74 24                	je     103e16 <default_check+0x68d>
  103df2:	c7 44 24 0c 38 6d 10 	movl   $0x106d38,0xc(%esp)
  103df9:	00 
  103dfa:	c7 44 24 08 b6 69 10 	movl   $0x1069b6,0x8(%esp)
  103e01:	00 
  103e02:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
  103e09:	00 
  103e0a:	c7 04 24 cb 69 10 00 	movl   $0x1069cb,(%esp)
  103e11:	e8 c1 ce ff ff       	call   100cd7 <__panic>
}
  103e16:	81 c4 94 00 00 00    	add    $0x94,%esp
  103e1c:	5b                   	pop    %ebx
  103e1d:	5d                   	pop    %ebp
  103e1e:	c3                   	ret    

00103e1f <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
  103e1f:	55                   	push   %ebp
  103e20:	89 e5                	mov    %esp,%ebp
    return page - pages;
  103e22:	8b 55 08             	mov    0x8(%ebp),%edx
  103e25:	a1 24 af 11 00       	mov    0x11af24,%eax
  103e2a:	29 c2                	sub    %eax,%edx
  103e2c:	89 d0                	mov    %edx,%eax
  103e2e:	c1 f8 02             	sar    $0x2,%eax
  103e31:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
  103e37:	5d                   	pop    %ebp
  103e38:	c3                   	ret    

00103e39 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
  103e39:	55                   	push   %ebp
  103e3a:	89 e5                	mov    %esp,%ebp
  103e3c:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
  103e3f:	8b 45 08             	mov    0x8(%ebp),%eax
  103e42:	89 04 24             	mov    %eax,(%esp)
  103e45:	e8 d5 ff ff ff       	call   103e1f <page2ppn>
  103e4a:	c1 e0 0c             	shl    $0xc,%eax
}
  103e4d:	c9                   	leave  
  103e4e:	c3                   	ret    

00103e4f <pa2page>:

static inline struct Page *
pa2page(uintptr_t pa) {
  103e4f:	55                   	push   %ebp
  103e50:	89 e5                	mov    %esp,%ebp
  103e52:	83 ec 18             	sub    $0x18,%esp
    if (PPN(pa) >= npage) {
  103e55:	8b 45 08             	mov    0x8(%ebp),%eax
  103e58:	c1 e8 0c             	shr    $0xc,%eax
  103e5b:	89 c2                	mov    %eax,%edx
  103e5d:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  103e62:	39 c2                	cmp    %eax,%edx
  103e64:	72 1c                	jb     103e82 <pa2page+0x33>
        panic("pa2page called with invalid pa");
  103e66:	c7 44 24 08 74 6d 10 	movl   $0x106d74,0x8(%esp)
  103e6d:	00 
  103e6e:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  103e75:	00 
  103e76:	c7 04 24 93 6d 10 00 	movl   $0x106d93,(%esp)
  103e7d:	e8 55 ce ff ff       	call   100cd7 <__panic>
    }
    return &pages[PPN(pa)];
  103e82:	8b 0d 24 af 11 00    	mov    0x11af24,%ecx
  103e88:	8b 45 08             	mov    0x8(%ebp),%eax
  103e8b:	c1 e8 0c             	shr    $0xc,%eax
  103e8e:	89 c2                	mov    %eax,%edx
  103e90:	89 d0                	mov    %edx,%eax
  103e92:	c1 e0 02             	shl    $0x2,%eax
  103e95:	01 d0                	add    %edx,%eax
  103e97:	c1 e0 02             	shl    $0x2,%eax
  103e9a:	01 c8                	add    %ecx,%eax
}
  103e9c:	c9                   	leave  
  103e9d:	c3                   	ret    

00103e9e <page2kva>:

static inline void *
page2kva(struct Page *page) {
  103e9e:	55                   	push   %ebp
  103e9f:	89 e5                	mov    %esp,%ebp
  103ea1:	83 ec 28             	sub    $0x28,%esp
    return KADDR(page2pa(page));
  103ea4:	8b 45 08             	mov    0x8(%ebp),%eax
  103ea7:	89 04 24             	mov    %eax,(%esp)
  103eaa:	e8 8a ff ff ff       	call   103e39 <page2pa>
  103eaf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  103eb2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103eb5:	c1 e8 0c             	shr    $0xc,%eax
  103eb8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103ebb:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  103ec0:	39 45 f0             	cmp    %eax,-0x10(%ebp)
  103ec3:	72 23                	jb     103ee8 <page2kva+0x4a>
  103ec5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ec8:	89 44 24 0c          	mov    %eax,0xc(%esp)
  103ecc:	c7 44 24 08 a4 6d 10 	movl   $0x106da4,0x8(%esp)
  103ed3:	00 
  103ed4:	c7 44 24 04 61 00 00 	movl   $0x61,0x4(%esp)
  103edb:	00 
  103edc:	c7 04 24 93 6d 10 00 	movl   $0x106d93,(%esp)
  103ee3:	e8 ef cd ff ff       	call   100cd7 <__panic>
  103ee8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  103eeb:	c9                   	leave  
  103eec:	c3                   	ret    

00103eed <pte2page>:
kva2page(void *kva) {
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte) {
  103eed:	55                   	push   %ebp
  103eee:	89 e5                	mov    %esp,%ebp
  103ef0:	83 ec 18             	sub    $0x18,%esp
    if (!(pte & PTE_P)) {
  103ef3:	8b 45 08             	mov    0x8(%ebp),%eax
  103ef6:	83 e0 01             	and    $0x1,%eax
  103ef9:	85 c0                	test   %eax,%eax
  103efb:	75 1c                	jne    103f19 <pte2page+0x2c>
        panic("pte2page called with invalid pte");
  103efd:	c7 44 24 08 c8 6d 10 	movl   $0x106dc8,0x8(%esp)
  103f04:	00 
  103f05:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
  103f0c:	00 
  103f0d:	c7 04 24 93 6d 10 00 	movl   $0x106d93,(%esp)
  103f14:	e8 be cd ff ff       	call   100cd7 <__panic>
    }
    return pa2page(PTE_ADDR(pte));
  103f19:	8b 45 08             	mov    0x8(%ebp),%eax
  103f1c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103f21:	89 04 24             	mov    %eax,(%esp)
  103f24:	e8 26 ff ff ff       	call   103e4f <pa2page>
}
  103f29:	c9                   	leave  
  103f2a:	c3                   	ret    

00103f2b <pde2page>:

static inline struct Page *
pde2page(pde_t pde) {
  103f2b:	55                   	push   %ebp
  103f2c:	89 e5                	mov    %esp,%ebp
  103f2e:	83 ec 18             	sub    $0x18,%esp
    return pa2page(PDE_ADDR(pde));
  103f31:	8b 45 08             	mov    0x8(%ebp),%eax
  103f34:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103f39:	89 04 24             	mov    %eax,(%esp)
  103f3c:	e8 0e ff ff ff       	call   103e4f <pa2page>
}
  103f41:	c9                   	leave  
  103f42:	c3                   	ret    

00103f43 <page_ref>:

static inline int
page_ref(struct Page *page) {
  103f43:	55                   	push   %ebp
  103f44:	89 e5                	mov    %esp,%ebp
    return page->ref;
  103f46:	8b 45 08             	mov    0x8(%ebp),%eax
  103f49:	8b 00                	mov    (%eax),%eax
}
  103f4b:	5d                   	pop    %ebp
  103f4c:	c3                   	ret    

00103f4d <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
  103f4d:	55                   	push   %ebp
  103f4e:	89 e5                	mov    %esp,%ebp
    page->ref = val;
  103f50:	8b 45 08             	mov    0x8(%ebp),%eax
  103f53:	8b 55 0c             	mov    0xc(%ebp),%edx
  103f56:	89 10                	mov    %edx,(%eax)
}
  103f58:	5d                   	pop    %ebp
  103f59:	c3                   	ret    

00103f5a <page_ref_inc>:

static inline int
page_ref_inc(struct Page *page) {
  103f5a:	55                   	push   %ebp
  103f5b:	89 e5                	mov    %esp,%ebp
    page->ref += 1;
  103f5d:	8b 45 08             	mov    0x8(%ebp),%eax
  103f60:	8b 00                	mov    (%eax),%eax
  103f62:	8d 50 01             	lea    0x1(%eax),%edx
  103f65:	8b 45 08             	mov    0x8(%ebp),%eax
  103f68:	89 10                	mov    %edx,(%eax)
    return page->ref;
  103f6a:	8b 45 08             	mov    0x8(%ebp),%eax
  103f6d:	8b 00                	mov    (%eax),%eax
}
  103f6f:	5d                   	pop    %ebp
  103f70:	c3                   	ret    

00103f71 <page_ref_dec>:

static inline int
page_ref_dec(struct Page *page) {
  103f71:	55                   	push   %ebp
  103f72:	89 e5                	mov    %esp,%ebp
    page->ref -= 1;
  103f74:	8b 45 08             	mov    0x8(%ebp),%eax
  103f77:	8b 00                	mov    (%eax),%eax
  103f79:	8d 50 ff             	lea    -0x1(%eax),%edx
  103f7c:	8b 45 08             	mov    0x8(%ebp),%eax
  103f7f:	89 10                	mov    %edx,(%eax)
    return page->ref;
  103f81:	8b 45 08             	mov    0x8(%ebp),%eax
  103f84:	8b 00                	mov    (%eax),%eax
}
  103f86:	5d                   	pop    %ebp
  103f87:	c3                   	ret    

00103f88 <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
  103f88:	55                   	push   %ebp
  103f89:	89 e5                	mov    %esp,%ebp
  103f8b:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
  103f8e:	9c                   	pushf  
  103f8f:	58                   	pop    %eax
  103f90:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
  103f93:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
  103f96:	25 00 02 00 00       	and    $0x200,%eax
  103f9b:	85 c0                	test   %eax,%eax
  103f9d:	74 0c                	je     103fab <__intr_save+0x23>
        intr_disable();
  103f9f:	e8 27 d7 ff ff       	call   1016cb <intr_disable>
        return 1;
  103fa4:	b8 01 00 00 00       	mov    $0x1,%eax
  103fa9:	eb 05                	jmp    103fb0 <__intr_save+0x28>
    }
    return 0;
  103fab:	b8 00 00 00 00       	mov    $0x0,%eax
}
  103fb0:	c9                   	leave  
  103fb1:	c3                   	ret    

00103fb2 <__intr_restore>:

static inline void
__intr_restore(bool flag) {
  103fb2:	55                   	push   %ebp
  103fb3:	89 e5                	mov    %esp,%ebp
  103fb5:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
  103fb8:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  103fbc:	74 05                	je     103fc3 <__intr_restore+0x11>
        intr_enable();
  103fbe:	e8 02 d7 ff ff       	call   1016c5 <intr_enable>
    }
}
  103fc3:	c9                   	leave  
  103fc4:	c3                   	ret    

00103fc5 <lgdt>:
/* *
 * lgdt - load the global descriptor table register and reset the
 * data/code segement registers for kernel.
 * */
static inline void
lgdt(struct pseudodesc *pd) {
  103fc5:	55                   	push   %ebp
  103fc6:	89 e5                	mov    %esp,%ebp
    asm volatile ("lgdt (%0)" :: "r" (pd));
  103fc8:	8b 45 08             	mov    0x8(%ebp),%eax
  103fcb:	0f 01 10             	lgdtl  (%eax)
    asm volatile ("movw %%ax, %%gs" :: "a" (USER_DS));
  103fce:	b8 23 00 00 00       	mov    $0x23,%eax
  103fd3:	8e e8                	mov    %eax,%gs
    asm volatile ("movw %%ax, %%fs" :: "a" (USER_DS));
  103fd5:	b8 23 00 00 00       	mov    $0x23,%eax
  103fda:	8e e0                	mov    %eax,%fs
    asm volatile ("movw %%ax, %%es" :: "a" (KERNEL_DS));
  103fdc:	b8 10 00 00 00       	mov    $0x10,%eax
  103fe1:	8e c0                	mov    %eax,%es
    asm volatile ("movw %%ax, %%ds" :: "a" (KERNEL_DS));
  103fe3:	b8 10 00 00 00       	mov    $0x10,%eax
  103fe8:	8e d8                	mov    %eax,%ds
    asm volatile ("movw %%ax, %%ss" :: "a" (KERNEL_DS));
  103fea:	b8 10 00 00 00       	mov    $0x10,%eax
  103fef:	8e d0                	mov    %eax,%ss
    // reload cs
    asm volatile ("ljmp %0, $1f\n 1:\n" :: "i" (KERNEL_CS));
  103ff1:	ea f8 3f 10 00 08 00 	ljmp   $0x8,$0x103ff8
}
  103ff8:	5d                   	pop    %ebp
  103ff9:	c3                   	ret    

00103ffa <load_esp0>:
 * load_esp0 - change the ESP0 in default task state segment,
 * so that we can use different kernel stack when we trap frame
 * user to kernel.
 * */
void
load_esp0(uintptr_t esp0) {
  103ffa:	55                   	push   %ebp
  103ffb:	89 e5                	mov    %esp,%ebp
    ts.ts_esp0 = esp0;
  103ffd:	8b 45 08             	mov    0x8(%ebp),%eax
  104000:	a3 a4 ae 11 00       	mov    %eax,0x11aea4
}
  104005:	5d                   	pop    %ebp
  104006:	c3                   	ret    

00104007 <gdt_init>:

/* gdt_init - initialize the default GDT and TSS */
static void
gdt_init(void) {
  104007:	55                   	push   %ebp
  104008:	89 e5                	mov    %esp,%ebp
  10400a:	83 ec 14             	sub    $0x14,%esp
    // set boot kernel stack and default SS0
    load_esp0((uintptr_t)bootstacktop);
  10400d:	b8 00 70 11 00       	mov    $0x117000,%eax
  104012:	89 04 24             	mov    %eax,(%esp)
  104015:	e8 e0 ff ff ff       	call   103ffa <load_esp0>
    ts.ts_ss0 = KERNEL_DS;
  10401a:	66 c7 05 a8 ae 11 00 	movw   $0x10,0x11aea8
  104021:	10 00 

    // initialize the TSS filed of the gdt
    gdt[SEG_TSS] = SEGTSS(STS_T32A, (uintptr_t)&ts, sizeof(ts), DPL_KERNEL);
  104023:	66 c7 05 28 7a 11 00 	movw   $0x68,0x117a28
  10402a:	68 00 
  10402c:	b8 a0 ae 11 00       	mov    $0x11aea0,%eax
  104031:	66 a3 2a 7a 11 00    	mov    %ax,0x117a2a
  104037:	b8 a0 ae 11 00       	mov    $0x11aea0,%eax
  10403c:	c1 e8 10             	shr    $0x10,%eax
  10403f:	a2 2c 7a 11 00       	mov    %al,0x117a2c
  104044:	0f b6 05 2d 7a 11 00 	movzbl 0x117a2d,%eax
  10404b:	83 e0 f0             	and    $0xfffffff0,%eax
  10404e:	83 c8 09             	or     $0x9,%eax
  104051:	a2 2d 7a 11 00       	mov    %al,0x117a2d
  104056:	0f b6 05 2d 7a 11 00 	movzbl 0x117a2d,%eax
  10405d:	83 e0 ef             	and    $0xffffffef,%eax
  104060:	a2 2d 7a 11 00       	mov    %al,0x117a2d
  104065:	0f b6 05 2d 7a 11 00 	movzbl 0x117a2d,%eax
  10406c:	83 e0 9f             	and    $0xffffff9f,%eax
  10406f:	a2 2d 7a 11 00       	mov    %al,0x117a2d
  104074:	0f b6 05 2d 7a 11 00 	movzbl 0x117a2d,%eax
  10407b:	83 c8 80             	or     $0xffffff80,%eax
  10407e:	a2 2d 7a 11 00       	mov    %al,0x117a2d
  104083:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  10408a:	83 e0 f0             	and    $0xfffffff0,%eax
  10408d:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  104092:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  104099:	83 e0 ef             	and    $0xffffffef,%eax
  10409c:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  1040a1:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  1040a8:	83 e0 df             	and    $0xffffffdf,%eax
  1040ab:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  1040b0:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  1040b7:	83 c8 40             	or     $0x40,%eax
  1040ba:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  1040bf:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  1040c6:	83 e0 7f             	and    $0x7f,%eax
  1040c9:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  1040ce:	b8 a0 ae 11 00       	mov    $0x11aea0,%eax
  1040d3:	c1 e8 18             	shr    $0x18,%eax
  1040d6:	a2 2f 7a 11 00       	mov    %al,0x117a2f

    // reload all segment registers
    lgdt(&gdt_pd);
  1040db:	c7 04 24 30 7a 11 00 	movl   $0x117a30,(%esp)
  1040e2:	e8 de fe ff ff       	call   103fc5 <lgdt>
  1040e7:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
    asm volatile ("cli" ::: "memory");
}

static inline void
ltr(uint16_t sel) {
    asm volatile ("ltr %0" :: "r" (sel) : "memory");
  1040ed:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
  1040f1:	0f 00 d8             	ltr    %ax

    // load the TSS
    ltr(GD_TSS);
}
  1040f4:	c9                   	leave  
  1040f5:	c3                   	ret    

001040f6 <init_pmm_manager>:

//init_pmm_manager - initialize a pmm_manager instance
static void
init_pmm_manager(void) {
  1040f6:	55                   	push   %ebp
  1040f7:	89 e5                	mov    %esp,%ebp
  1040f9:	83 ec 18             	sub    $0x18,%esp
    pmm_manager = &default_pmm_manager;
  1040fc:	c7 05 1c af 11 00 58 	movl   $0x106d58,0x11af1c
  104103:	6d 10 00 
    cprintf("memory management: %s\n", pmm_manager->name);
  104106:	a1 1c af 11 00       	mov    0x11af1c,%eax
  10410b:	8b 00                	mov    (%eax),%eax
  10410d:	89 44 24 04          	mov    %eax,0x4(%esp)
  104111:	c7 04 24 f4 6d 10 00 	movl   $0x106df4,(%esp)
  104118:	e8 30 c2 ff ff       	call   10034d <cprintf>
    pmm_manager->init();
  10411d:	a1 1c af 11 00       	mov    0x11af1c,%eax
  104122:	8b 40 04             	mov    0x4(%eax),%eax
  104125:	ff d0                	call   *%eax
}
  104127:	c9                   	leave  
  104128:	c3                   	ret    

00104129 <init_memmap>:

//init_memmap - call pmm->init_memmap to build Page struct for free memory  
static void
init_memmap(struct Page *base, size_t n) {
  104129:	55                   	push   %ebp
  10412a:	89 e5                	mov    %esp,%ebp
  10412c:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->init_memmap(base, n);
  10412f:	a1 1c af 11 00       	mov    0x11af1c,%eax
  104134:	8b 40 08             	mov    0x8(%eax),%eax
  104137:	8b 55 0c             	mov    0xc(%ebp),%edx
  10413a:	89 54 24 04          	mov    %edx,0x4(%esp)
  10413e:	8b 55 08             	mov    0x8(%ebp),%edx
  104141:	89 14 24             	mov    %edx,(%esp)
  104144:	ff d0                	call   *%eax
}
  104146:	c9                   	leave  
  104147:	c3                   	ret    

00104148 <alloc_pages>:

//alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory 
struct Page *
alloc_pages(size_t n) {
  104148:	55                   	push   %ebp
  104149:	89 e5                	mov    %esp,%ebp
  10414b:	83 ec 28             	sub    $0x28,%esp
    struct Page *page=NULL;
  10414e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
  104155:	e8 2e fe ff ff       	call   103f88 <__intr_save>
  10415a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        page = pmm_manager->alloc_pages(n);
  10415d:	a1 1c af 11 00       	mov    0x11af1c,%eax
  104162:	8b 40 0c             	mov    0xc(%eax),%eax
  104165:	8b 55 08             	mov    0x8(%ebp),%edx
  104168:	89 14 24             	mov    %edx,(%esp)
  10416b:	ff d0                	call   *%eax
  10416d:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }
    local_intr_restore(intr_flag);
  104170:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104173:	89 04 24             	mov    %eax,(%esp)
  104176:	e8 37 fe ff ff       	call   103fb2 <__intr_restore>
    return page;
  10417b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  10417e:	c9                   	leave  
  10417f:	c3                   	ret    

00104180 <free_pages>:

//free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory 
void
free_pages(struct Page *base, size_t n) {
  104180:	55                   	push   %ebp
  104181:	89 e5                	mov    %esp,%ebp
  104183:	83 ec 28             	sub    $0x28,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
  104186:	e8 fd fd ff ff       	call   103f88 <__intr_save>
  10418b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        pmm_manager->free_pages(base, n);
  10418e:	a1 1c af 11 00       	mov    0x11af1c,%eax
  104193:	8b 40 10             	mov    0x10(%eax),%eax
  104196:	8b 55 0c             	mov    0xc(%ebp),%edx
  104199:	89 54 24 04          	mov    %edx,0x4(%esp)
  10419d:	8b 55 08             	mov    0x8(%ebp),%edx
  1041a0:	89 14 24             	mov    %edx,(%esp)
  1041a3:	ff d0                	call   *%eax
    }
    local_intr_restore(intr_flag);
  1041a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1041a8:	89 04 24             	mov    %eax,(%esp)
  1041ab:	e8 02 fe ff ff       	call   103fb2 <__intr_restore>
}
  1041b0:	c9                   	leave  
  1041b1:	c3                   	ret    

001041b2 <nr_free_pages>:

//nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE) 
//of current free memory
size_t
nr_free_pages(void) {
  1041b2:	55                   	push   %ebp
  1041b3:	89 e5                	mov    %esp,%ebp
  1041b5:	83 ec 28             	sub    $0x28,%esp
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
  1041b8:	e8 cb fd ff ff       	call   103f88 <__intr_save>
  1041bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        ret = pmm_manager->nr_free_pages();
  1041c0:	a1 1c af 11 00       	mov    0x11af1c,%eax
  1041c5:	8b 40 14             	mov    0x14(%eax),%eax
  1041c8:	ff d0                	call   *%eax
  1041ca:	89 45 f0             	mov    %eax,-0x10(%ebp)
    }
    local_intr_restore(intr_flag);
  1041cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1041d0:	89 04 24             	mov    %eax,(%esp)
  1041d3:	e8 da fd ff ff       	call   103fb2 <__intr_restore>
    return ret;
  1041d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1041db:	c9                   	leave  
  1041dc:	c3                   	ret    

001041dd <page_init>:

/* pmm_init - initialize the physical memory management */
static void
page_init(void) {
  1041dd:	55                   	push   %ebp
  1041de:	89 e5                	mov    %esp,%ebp
  1041e0:	57                   	push   %edi
  1041e1:	56                   	push   %esi
  1041e2:	53                   	push   %ebx
  1041e3:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
  1041e9:	c7 45 c4 00 80 00 00 	movl   $0x8000,-0x3c(%ebp)
    uint64_t maxpa = 0;
  1041f0:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  1041f7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

    cprintf("e820map:\n");
  1041fe:	c7 04 24 0b 6e 10 00 	movl   $0x106e0b,(%esp)
  104205:	e8 43 c1 ff ff       	call   10034d <cprintf>
    // 检测出内存能用的最大物理地址
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
  10420a:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  104211:	e9 15 01 00 00       	jmp    10432b <page_init+0x14e>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
  104216:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  104219:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10421c:	89 d0                	mov    %edx,%eax
  10421e:	c1 e0 02             	shl    $0x2,%eax
  104221:	01 d0                	add    %edx,%eax
  104223:	c1 e0 02             	shl    $0x2,%eax
  104226:	01 c8                	add    %ecx,%eax
  104228:	8b 50 08             	mov    0x8(%eax),%edx
  10422b:	8b 40 04             	mov    0x4(%eax),%eax
  10422e:	89 45 b8             	mov    %eax,-0x48(%ebp)
  104231:	89 55 bc             	mov    %edx,-0x44(%ebp)
  104234:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  104237:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10423a:	89 d0                	mov    %edx,%eax
  10423c:	c1 e0 02             	shl    $0x2,%eax
  10423f:	01 d0                	add    %edx,%eax
  104241:	c1 e0 02             	shl    $0x2,%eax
  104244:	01 c8                	add    %ecx,%eax
  104246:	8b 48 0c             	mov    0xc(%eax),%ecx
  104249:	8b 58 10             	mov    0x10(%eax),%ebx
  10424c:	8b 45 b8             	mov    -0x48(%ebp),%eax
  10424f:	8b 55 bc             	mov    -0x44(%ebp),%edx
  104252:	01 c8                	add    %ecx,%eax
  104254:	11 da                	adc    %ebx,%edx
  104256:	89 45 b0             	mov    %eax,-0x50(%ebp)
  104259:	89 55 b4             	mov    %edx,-0x4c(%ebp)
        cprintf("  memory: %08llx, [%08llx, %08llx], type = %d.\n",
  10425c:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  10425f:	8b 55 dc             	mov    -0x24(%ebp),%edx
  104262:	89 d0                	mov    %edx,%eax
  104264:	c1 e0 02             	shl    $0x2,%eax
  104267:	01 d0                	add    %edx,%eax
  104269:	c1 e0 02             	shl    $0x2,%eax
  10426c:	01 c8                	add    %ecx,%eax
  10426e:	83 c0 14             	add    $0x14,%eax
  104271:	8b 00                	mov    (%eax),%eax
  104273:	89 85 7c ff ff ff    	mov    %eax,-0x84(%ebp)
  104279:	8b 45 b0             	mov    -0x50(%ebp),%eax
  10427c:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  10427f:	83 c0 ff             	add    $0xffffffff,%eax
  104282:	83 d2 ff             	adc    $0xffffffff,%edx
  104285:	89 c6                	mov    %eax,%esi
  104287:	89 d7                	mov    %edx,%edi
  104289:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  10428c:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10428f:	89 d0                	mov    %edx,%eax
  104291:	c1 e0 02             	shl    $0x2,%eax
  104294:	01 d0                	add    %edx,%eax
  104296:	c1 e0 02             	shl    $0x2,%eax
  104299:	01 c8                	add    %ecx,%eax
  10429b:	8b 48 0c             	mov    0xc(%eax),%ecx
  10429e:	8b 58 10             	mov    0x10(%eax),%ebx
  1042a1:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  1042a7:	89 44 24 1c          	mov    %eax,0x1c(%esp)
  1042ab:	89 74 24 14          	mov    %esi,0x14(%esp)
  1042af:	89 7c 24 18          	mov    %edi,0x18(%esp)
  1042b3:	8b 45 b8             	mov    -0x48(%ebp),%eax
  1042b6:	8b 55 bc             	mov    -0x44(%ebp),%edx
  1042b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1042bd:	89 54 24 10          	mov    %edx,0x10(%esp)
  1042c1:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  1042c5:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  1042c9:	c7 04 24 18 6e 10 00 	movl   $0x106e18,(%esp)
  1042d0:	e8 78 c0 ff ff       	call   10034d <cprintf>
                memmap->map[i].size, begin, end - 1, memmap->map[i].type);
        if (memmap->map[i].type == E820_ARM) {
  1042d5:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  1042d8:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1042db:	89 d0                	mov    %edx,%eax
  1042dd:	c1 e0 02             	shl    $0x2,%eax
  1042e0:	01 d0                	add    %edx,%eax
  1042e2:	c1 e0 02             	shl    $0x2,%eax
  1042e5:	01 c8                	add    %ecx,%eax
  1042e7:	83 c0 14             	add    $0x14,%eax
  1042ea:	8b 00                	mov    (%eax),%eax
  1042ec:	83 f8 01             	cmp    $0x1,%eax
  1042ef:	75 36                	jne    104327 <page_init+0x14a>
            if (maxpa < end && begin < KMEMSIZE) {
  1042f1:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1042f4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1042f7:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
  1042fa:	77 2b                	ja     104327 <page_init+0x14a>
  1042fc:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
  1042ff:	72 05                	jb     104306 <page_init+0x129>
  104301:	3b 45 b0             	cmp    -0x50(%ebp),%eax
  104304:	73 21                	jae    104327 <page_init+0x14a>
  104306:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
  10430a:	77 1b                	ja     104327 <page_init+0x14a>
  10430c:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
  104310:	72 09                	jb     10431b <page_init+0x13e>
  104312:	81 7d b8 ff ff ff 37 	cmpl   $0x37ffffff,-0x48(%ebp)
  104319:	77 0c                	ja     104327 <page_init+0x14a>
                maxpa = end;
  10431b:	8b 45 b0             	mov    -0x50(%ebp),%eax
  10431e:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  104321:	89 45 e0             	mov    %eax,-0x20(%ebp)
  104324:	89 55 e4             	mov    %edx,-0x1c(%ebp)
    uint64_t maxpa = 0;

    cprintf("e820map:\n");
    // 检测出内存能用的最大物理地址
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
  104327:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
  10432b:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  10432e:	8b 00                	mov    (%eax),%eax
  104330:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  104333:	0f 8f dd fe ff ff    	jg     104216 <page_init+0x39>
            if (maxpa < end && begin < KMEMSIZE) {
                maxpa = end;
            }
        }
    }
    if (maxpa > KMEMSIZE) {
  104339:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  10433d:	72 1d                	jb     10435c <page_init+0x17f>
  10433f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  104343:	77 09                	ja     10434e <page_init+0x171>
  104345:	81 7d e0 00 00 00 38 	cmpl   $0x38000000,-0x20(%ebp)
  10434c:	76 0e                	jbe    10435c <page_init+0x17f>
        maxpa = KMEMSIZE;
  10434e:	c7 45 e0 00 00 00 38 	movl   $0x38000000,-0x20(%ebp)
  104355:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    }

    extern char end[];

    npage = maxpa / PGSIZE;
  10435c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10435f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  104362:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
  104366:	c1 ea 0c             	shr    $0xc,%edx
  104369:	a3 80 ae 11 00       	mov    %eax,0x11ae80
    // 内核之后就是pages结构体数组
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
  10436e:	c7 45 ac 00 10 00 00 	movl   $0x1000,-0x54(%ebp)
  104375:	b8 28 af 11 00       	mov    $0x11af28,%eax
  10437a:	8d 50 ff             	lea    -0x1(%eax),%edx
  10437d:	8b 45 ac             	mov    -0x54(%ebp),%eax
  104380:	01 d0                	add    %edx,%eax
  104382:	89 45 a8             	mov    %eax,-0x58(%ebp)
  104385:	8b 45 a8             	mov    -0x58(%ebp),%eax
  104388:	ba 00 00 00 00       	mov    $0x0,%edx
  10438d:	f7 75 ac             	divl   -0x54(%ebp)
  104390:	89 d0                	mov    %edx,%eax
  104392:	8b 55 a8             	mov    -0x58(%ebp),%edx
  104395:	29 c2                	sub    %eax,%edx
  104397:	89 d0                	mov    %edx,%eax
  104399:	a3 24 af 11 00       	mov    %eax,0x11af24

    for (i = 0; i < npage; i ++) {
  10439e:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  1043a5:	eb 2f                	jmp    1043d6 <page_init+0x1f9>
        SetPageReserved(pages + i);
  1043a7:	8b 0d 24 af 11 00    	mov    0x11af24,%ecx
  1043ad:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1043b0:	89 d0                	mov    %edx,%eax
  1043b2:	c1 e0 02             	shl    $0x2,%eax
  1043b5:	01 d0                	add    %edx,%eax
  1043b7:	c1 e0 02             	shl    $0x2,%eax
  1043ba:	01 c8                	add    %ecx,%eax
  1043bc:	83 c0 04             	add    $0x4,%eax
  1043bf:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  1043c6:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  1043c9:	8b 45 8c             	mov    -0x74(%ebp),%eax
  1043cc:	8b 55 90             	mov    -0x70(%ebp),%edx
  1043cf:	0f ab 10             	bts    %edx,(%eax)

    npage = maxpa / PGSIZE;
    // 内核之后就是pages结构体数组
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    for (i = 0; i < npage; i ++) {
  1043d2:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
  1043d6:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1043d9:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  1043de:	39 c2                	cmp    %eax,%edx
  1043e0:	72 c5                	jb     1043a7 <page_init+0x1ca>
        SetPageReserved(pages + i);
    }

    // 相当于最小能用的物理地址
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);
  1043e2:	8b 15 80 ae 11 00    	mov    0x11ae80,%edx
  1043e8:	89 d0                	mov    %edx,%eax
  1043ea:	c1 e0 02             	shl    $0x2,%eax
  1043ed:	01 d0                	add    %edx,%eax
  1043ef:	c1 e0 02             	shl    $0x2,%eax
  1043f2:	89 c2                	mov    %eax,%edx
  1043f4:	a1 24 af 11 00       	mov    0x11af24,%eax
  1043f9:	01 d0                	add    %edx,%eax
  1043fb:	89 45 a4             	mov    %eax,-0x5c(%ebp)
  1043fe:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  104401:	89 45 a0             	mov    %eax,-0x60(%ebp)

    for (i = 0; i < memmap->nr_map; i ++) {
  104404:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  10440b:	e9 74 01 00 00       	jmp    104584 <page_init+0x3a7>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
  104410:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  104413:	8b 55 dc             	mov    -0x24(%ebp),%edx
  104416:	89 d0                	mov    %edx,%eax
  104418:	c1 e0 02             	shl    $0x2,%eax
  10441b:	01 d0                	add    %edx,%eax
  10441d:	c1 e0 02             	shl    $0x2,%eax
  104420:	01 c8                	add    %ecx,%eax
  104422:	8b 50 08             	mov    0x8(%eax),%edx
  104425:	8b 40 04             	mov    0x4(%eax),%eax
  104428:	89 45 d0             	mov    %eax,-0x30(%ebp)
  10442b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  10442e:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  104431:	8b 55 dc             	mov    -0x24(%ebp),%edx
  104434:	89 d0                	mov    %edx,%eax
  104436:	c1 e0 02             	shl    $0x2,%eax
  104439:	01 d0                	add    %edx,%eax
  10443b:	c1 e0 02             	shl    $0x2,%eax
  10443e:	01 c8                	add    %ecx,%eax
  104440:	8b 48 0c             	mov    0xc(%eax),%ecx
  104443:	8b 58 10             	mov    0x10(%eax),%ebx
  104446:	8b 45 d0             	mov    -0x30(%ebp),%eax
  104449:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10444c:	01 c8                	add    %ecx,%eax
  10444e:	11 da                	adc    %ebx,%edx
  104450:	89 45 c8             	mov    %eax,-0x38(%ebp)
  104453:	89 55 cc             	mov    %edx,-0x34(%ebp)
        if (memmap->map[i].type == E820_ARM) {
  104456:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  104459:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10445c:	89 d0                	mov    %edx,%eax
  10445e:	c1 e0 02             	shl    $0x2,%eax
  104461:	01 d0                	add    %edx,%eax
  104463:	c1 e0 02             	shl    $0x2,%eax
  104466:	01 c8                	add    %ecx,%eax
  104468:	83 c0 14             	add    $0x14,%eax
  10446b:	8b 00                	mov    (%eax),%eax
  10446d:	83 f8 01             	cmp    $0x1,%eax
  104470:	0f 85 0a 01 00 00    	jne    104580 <page_init+0x3a3>
            if (begin < freemem) {
  104476:	8b 45 a0             	mov    -0x60(%ebp),%eax
  104479:	ba 00 00 00 00       	mov    $0x0,%edx
  10447e:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  104481:	72 17                	jb     10449a <page_init+0x2bd>
  104483:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  104486:	77 05                	ja     10448d <page_init+0x2b0>
  104488:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10448b:	76 0d                	jbe    10449a <page_init+0x2bd>
                begin = freemem;
  10448d:	8b 45 a0             	mov    -0x60(%ebp),%eax
  104490:	89 45 d0             	mov    %eax,-0x30(%ebp)
  104493:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
            }
            if (end > KMEMSIZE) {
  10449a:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  10449e:	72 1d                	jb     1044bd <page_init+0x2e0>
  1044a0:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  1044a4:	77 09                	ja     1044af <page_init+0x2d2>
  1044a6:	81 7d c8 00 00 00 38 	cmpl   $0x38000000,-0x38(%ebp)
  1044ad:	76 0e                	jbe    1044bd <page_init+0x2e0>
                end = KMEMSIZE;
  1044af:	c7 45 c8 00 00 00 38 	movl   $0x38000000,-0x38(%ebp)
  1044b6:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
            }
            if (begin < end) {
  1044bd:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1044c0:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1044c3:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  1044c6:	0f 87 b4 00 00 00    	ja     104580 <page_init+0x3a3>
  1044cc:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  1044cf:	72 09                	jb     1044da <page_init+0x2fd>
  1044d1:	3b 45 c8             	cmp    -0x38(%ebp),%eax
  1044d4:	0f 83 a6 00 00 00    	jae    104580 <page_init+0x3a3>
                begin = ROUNDUP(begin, PGSIZE);
  1044da:	c7 45 9c 00 10 00 00 	movl   $0x1000,-0x64(%ebp)
  1044e1:	8b 55 d0             	mov    -0x30(%ebp),%edx
  1044e4:	8b 45 9c             	mov    -0x64(%ebp),%eax
  1044e7:	01 d0                	add    %edx,%eax
  1044e9:	83 e8 01             	sub    $0x1,%eax
  1044ec:	89 45 98             	mov    %eax,-0x68(%ebp)
  1044ef:	8b 45 98             	mov    -0x68(%ebp),%eax
  1044f2:	ba 00 00 00 00       	mov    $0x0,%edx
  1044f7:	f7 75 9c             	divl   -0x64(%ebp)
  1044fa:	89 d0                	mov    %edx,%eax
  1044fc:	8b 55 98             	mov    -0x68(%ebp),%edx
  1044ff:	29 c2                	sub    %eax,%edx
  104501:	89 d0                	mov    %edx,%eax
  104503:	ba 00 00 00 00       	mov    $0x0,%edx
  104508:	89 45 d0             	mov    %eax,-0x30(%ebp)
  10450b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
                end = ROUNDDOWN(end, PGSIZE);
  10450e:	8b 45 c8             	mov    -0x38(%ebp),%eax
  104511:	89 45 94             	mov    %eax,-0x6c(%ebp)
  104514:	8b 45 94             	mov    -0x6c(%ebp),%eax
  104517:	ba 00 00 00 00       	mov    $0x0,%edx
  10451c:	89 c7                	mov    %eax,%edi
  10451e:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  104524:	89 7d 80             	mov    %edi,-0x80(%ebp)
  104527:	89 d0                	mov    %edx,%eax
  104529:	83 e0 00             	and    $0x0,%eax
  10452c:	89 45 84             	mov    %eax,-0x7c(%ebp)
  10452f:	8b 45 80             	mov    -0x80(%ebp),%eax
  104532:	8b 55 84             	mov    -0x7c(%ebp),%edx
  104535:	89 45 c8             	mov    %eax,-0x38(%ebp)
  104538:	89 55 cc             	mov    %edx,-0x34(%ebp)
                if (begin < end) {
  10453b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10453e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  104541:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  104544:	77 3a                	ja     104580 <page_init+0x3a3>
  104546:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  104549:	72 05                	jb     104550 <page_init+0x373>
  10454b:	3b 45 c8             	cmp    -0x38(%ebp),%eax
  10454e:	73 30                	jae    104580 <page_init+0x3a3>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
  104550:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  104553:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  104556:	8b 45 c8             	mov    -0x38(%ebp),%eax
  104559:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10455c:	29 c8                	sub    %ecx,%eax
  10455e:	19 da                	sbb    %ebx,%edx
  104560:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
  104564:	c1 ea 0c             	shr    $0xc,%edx
  104567:	89 c3                	mov    %eax,%ebx
  104569:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10456c:	89 04 24             	mov    %eax,(%esp)
  10456f:	e8 db f8 ff ff       	call   103e4f <pa2page>
  104574:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  104578:	89 04 24             	mov    %eax,(%esp)
  10457b:	e8 a9 fb ff ff       	call   104129 <init_memmap>
    }

    // 相当于最小能用的物理地址
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);

    for (i = 0; i < memmap->nr_map; i ++) {
  104580:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
  104584:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  104587:	8b 00                	mov    (%eax),%eax
  104589:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  10458c:	0f 8f 7e fe ff ff    	jg     104410 <page_init+0x233>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
                }
            }
        }
    }
}
  104592:	81 c4 9c 00 00 00    	add    $0x9c,%esp
  104598:	5b                   	pop    %ebx
  104599:	5e                   	pop    %esi
  10459a:	5f                   	pop    %edi
  10459b:	5d                   	pop    %ebp
  10459c:	c3                   	ret    

0010459d <boot_map_segment>:
//  la:   linear address of this memory need to map (after x86 segment map)
//  size: memory size
//  pa:   physical address of this memory
//  perm: permission of this memory  
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
  10459d:	55                   	push   %ebp
  10459e:	89 e5                	mov    %esp,%ebp
  1045a0:	83 ec 38             	sub    $0x38,%esp
    assert(PGOFF(la) == PGOFF(pa));
  1045a3:	8b 45 14             	mov    0x14(%ebp),%eax
  1045a6:	8b 55 0c             	mov    0xc(%ebp),%edx
  1045a9:	31 d0                	xor    %edx,%eax
  1045ab:	25 ff 0f 00 00       	and    $0xfff,%eax
  1045b0:	85 c0                	test   %eax,%eax
  1045b2:	74 24                	je     1045d8 <boot_map_segment+0x3b>
  1045b4:	c7 44 24 0c 48 6e 10 	movl   $0x106e48,0xc(%esp)
  1045bb:	00 
  1045bc:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  1045c3:	00 
  1045c4:	c7 44 24 04 fd 00 00 	movl   $0xfd,0x4(%esp)
  1045cb:	00 
  1045cc:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  1045d3:	e8 ff c6 ff ff       	call   100cd7 <__panic>
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
  1045d8:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
  1045df:	8b 45 0c             	mov    0xc(%ebp),%eax
  1045e2:	25 ff 0f 00 00       	and    $0xfff,%eax
  1045e7:	89 c2                	mov    %eax,%edx
  1045e9:	8b 45 10             	mov    0x10(%ebp),%eax
  1045ec:	01 c2                	add    %eax,%edx
  1045ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1045f1:	01 d0                	add    %edx,%eax
  1045f3:	83 e8 01             	sub    $0x1,%eax
  1045f6:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1045f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1045fc:	ba 00 00 00 00       	mov    $0x0,%edx
  104601:	f7 75 f0             	divl   -0x10(%ebp)
  104604:	89 d0                	mov    %edx,%eax
  104606:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104609:	29 c2                	sub    %eax,%edx
  10460b:	89 d0                	mov    %edx,%eax
  10460d:	c1 e8 0c             	shr    $0xc,%eax
  104610:	89 45 f4             	mov    %eax,-0xc(%ebp)
    la = ROUNDDOWN(la, PGSIZE);
  104613:	8b 45 0c             	mov    0xc(%ebp),%eax
  104616:	89 45 e8             	mov    %eax,-0x18(%ebp)
  104619:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10461c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104621:	89 45 0c             	mov    %eax,0xc(%ebp)
    pa = ROUNDDOWN(pa, PGSIZE);
  104624:	8b 45 14             	mov    0x14(%ebp),%eax
  104627:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  10462a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10462d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104632:	89 45 14             	mov    %eax,0x14(%ebp)
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
  104635:	eb 6b                	jmp    1046a2 <boot_map_segment+0x105>
        pte_t *ptep = get_pte(pgdir, la, 1);
  104637:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  10463e:	00 
  10463f:	8b 45 0c             	mov    0xc(%ebp),%eax
  104642:	89 44 24 04          	mov    %eax,0x4(%esp)
  104646:	8b 45 08             	mov    0x8(%ebp),%eax
  104649:	89 04 24             	mov    %eax,(%esp)
  10464c:	e8 16 01 00 00       	call   104767 <get_pte>
  104651:	89 45 e0             	mov    %eax,-0x20(%ebp)
        assert(ptep != NULL);
  104654:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  104658:	75 24                	jne    10467e <boot_map_segment+0xe1>
  10465a:	c7 44 24 0c 82 6e 10 	movl   $0x106e82,0xc(%esp)
  104661:	00 
  104662:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104669:	00 
  10466a:	c7 44 24 04 03 01 00 	movl   $0x103,0x4(%esp)
  104671:	00 
  104672:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104679:	e8 59 c6 ff ff       	call   100cd7 <__panic>
        *ptep = pa | PTE_P | perm;
  10467e:	8b 45 18             	mov    0x18(%ebp),%eax
  104681:	8b 55 14             	mov    0x14(%ebp),%edx
  104684:	09 d0                	or     %edx,%eax
  104686:	83 c8 01             	or     $0x1,%eax
  104689:	89 c2                	mov    %eax,%edx
  10468b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10468e:	89 10                	mov    %edx,(%eax)
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
    assert(PGOFF(la) == PGOFF(pa));
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
  104690:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
  104694:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
  10469b:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  1046a2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1046a6:	75 8f                	jne    104637 <boot_map_segment+0x9a>
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pa | PTE_P | perm;
    }
}
  1046a8:	c9                   	leave  
  1046a9:	c3                   	ret    

001046aa <boot_alloc_page>:

//boot_alloc_page - allocate one page using pmm->alloc_pages(1) 
// return value: the kernel virtual address of this allocated page
//note: this function is used to get the memory for PDT(Page Directory Table)&PT(Page Table)
static void *
boot_alloc_page(void) {
  1046aa:	55                   	push   %ebp
  1046ab:	89 e5                	mov    %esp,%ebp
  1046ad:	83 ec 28             	sub    $0x28,%esp
    struct Page *p = alloc_page();
  1046b0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1046b7:	e8 8c fa ff ff       	call   104148 <alloc_pages>
  1046bc:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (p == NULL) {
  1046bf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1046c3:	75 1c                	jne    1046e1 <boot_alloc_page+0x37>
        panic("boot_alloc_page failed.\n");
  1046c5:	c7 44 24 08 8f 6e 10 	movl   $0x106e8f,0x8(%esp)
  1046cc:	00 
  1046cd:	c7 44 24 04 0f 01 00 	movl   $0x10f,0x4(%esp)
  1046d4:	00 
  1046d5:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  1046dc:	e8 f6 c5 ff ff       	call   100cd7 <__panic>
    }
    return page2kva(p);
  1046e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1046e4:	89 04 24             	mov    %eax,(%esp)
  1046e7:	e8 b2 f7 ff ff       	call   103e9e <page2kva>
}
  1046ec:	c9                   	leave  
  1046ed:	c3                   	ret    

001046ee <pmm_init>:

//pmm_init - setup a pmm to manage physical memory, build PDT&PT to setup paging mechanism 
//         - check the correctness of pmm & paging mechanism, print PDT&PT
void
pmm_init(void) {
  1046ee:	55                   	push   %ebp
  1046ef:	89 e5                	mov    %esp,%ebp
  1046f1:	83 ec 38             	sub    $0x38,%esp
    // We've already enabled paging
    boot_cr3 = PADDR(boot_pgdir);
  1046f4:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1046f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1046fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1046ff:	a3 20 af 11 00       	mov    %eax,0x11af20
    //We need to alloc/free the physical memory (granularity is 4KB or other size). 
    //So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    //First we should init a physical memory manager(pmm) based on the framework.
    //Then pmm can alloc/free the physical memory. 
    //Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();
  104704:	e8 ed f9 ff ff       	call   1040f6 <init_pmm_manager>

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();
  104709:	e8 cf fa ff ff       	call   1041dd <page_init>

    //use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();
  10470e:	e8 ab 03 00 00       	call   104abe <check_alloc_page>

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // recursively insert boot_pgdir in itself
    // to form a virtual page table at virtual address VPT
    boot_pgdir[PDX(VPT)] = PADDR(boot_pgdir) | PTE_P | PTE_W;
  104713:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104718:	8d 90 ac 0f 00 00    	lea    0xfac(%eax),%edx
  10471e:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104723:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104726:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104729:	83 c8 03             	or     $0x3,%eax
  10472c:	89 02                	mov    %eax,(%edx)

    // map all physical memory to linear memory with base linear addr KERNBASE
    // linear_addr KERNBASE ~ KERNBASE + KMEMSIZE = phy_addr 0 ~ KMEMSIZE
    boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, 0, PTE_W);
  10472e:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104733:	c7 44 24 10 02 00 00 	movl   $0x2,0x10(%esp)
  10473a:	00 
  10473b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  104742:	00 
  104743:	c7 44 24 08 00 00 00 	movl   $0x38000000,0x8(%esp)
  10474a:	38 
  10474b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104752:	00 
  104753:	89 04 24             	mov    %eax,(%esp)
  104756:	e8 42 fe ff ff       	call   10459d <boot_map_segment>

    // Since we are using bootloader's GDT,
    // we should reload gdt (second time, the last time) to get user segments and the TSS
    // map virtual_addr 0 ~ 4G = linear_addr 0 ~ 4G
    // then set kernel stack (ss:esp) in TSS, setup TSS in gdt, load TSS
    gdt_init();
  10475b:	e8 a7 f8 ff ff       	call   104007 <gdt_init>

    //now the basic virtual memory map(see memalyout.h) is established.
    //check the correctness of the basic virtual memory map.
    // check_boot_pgdir();

    print_pgdir();
  104760:	e8 64 0e 00 00       	call   1055c9 <print_pgdir>

}
  104765:	c9                   	leave  
  104766:	c3                   	ret    

00104767 <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *
get_pte(pde_t *pgdir, uintptr_t la, bool create) {
  104767:	55                   	push   %ebp
  104768:	89 e5                	mov    %esp,%ebp
  10476a:	83 ec 48             	sub    $0x48,%esp
    }
    return NULL;          // (8) return page table entry
#endif
    // 注意页目录表和页表存的都是物理地址，（如果是虚拟地址的话陷入循环了）
    // 但是操作系统代码里要虚拟地址，CPU可以帮忙转
    pte_t *result = NULL;
  10476d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    pde_t *pdep = &pgdir[PDX(la)];
  104774:	8b 45 0c             	mov    0xc(%ebp),%eax
  104777:	c1 e8 16             	shr    $0x16,%eax
  10477a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  104781:	8b 45 08             	mov    0x8(%ebp),%eax
  104784:	01 d0                	add    %edx,%eax
  104786:	89 45 e8             	mov    %eax,-0x18(%ebp)
    pte_t *pte_base = NULL;
  104789:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    struct Page *page;
    bool find_pte = 1;
  104790:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
    if (*pdep & PTE_P) { //存在对应的页表
  104797:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10479a:	8b 00                	mov    (%eax),%eax
  10479c:	83 e0 01             	and    $0x1,%eax
  10479f:	85 c0                	test   %eax,%eax
  1047a1:	74 4e                	je     1047f1 <get_pte+0x8a>
        pte_base = KADDR(*pdep & ~0xFFF); 
  1047a3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1047a6:	8b 00                	mov    (%eax),%eax
  1047a8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1047ad:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1047b0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1047b3:	c1 e8 0c             	shr    $0xc,%eax
  1047b6:	89 45 e0             	mov    %eax,-0x20(%ebp)
  1047b9:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  1047be:	39 45 e0             	cmp    %eax,-0x20(%ebp)
  1047c1:	72 23                	jb     1047e6 <get_pte+0x7f>
  1047c3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1047c6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1047ca:	c7 44 24 08 a4 6d 10 	movl   $0x106da4,0x8(%esp)
  1047d1:	00 
  1047d2:	c7 44 24 04 74 01 00 	movl   $0x174,0x4(%esp)
  1047d9:	00 
  1047da:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  1047e1:	e8 f1 c4 ff ff       	call   100cd7 <__panic>
  1047e6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1047e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1047ec:	e9 bd 00 00 00       	jmp    1048ae <get_pte+0x147>
    } 
    else if (create && (page = alloc_page()) != NULL) { //不存在对应的页表，但允许分配
  1047f1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1047f5:	0f 84 ac 00 00 00    	je     1048a7 <get_pte+0x140>
  1047fb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104802:	e8 41 f9 ff ff       	call   104148 <alloc_pages>
  104807:	89 45 dc             	mov    %eax,-0x24(%ebp)
  10480a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  10480e:	0f 84 93 00 00 00    	je     1048a7 <get_pte+0x140>
        set_page_ref(page, 1);
  104814:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10481b:	00 
  10481c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10481f:	89 04 24             	mov    %eax,(%esp)
  104822:	e8 26 f7 ff ff       	call   103f4d <set_page_ref>
        *pdep = page2pa(page);
  104827:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10482a:	89 04 24             	mov    %eax,(%esp)
  10482d:	e8 07 f6 ff ff       	call   103e39 <page2pa>
  104832:	8b 55 e8             	mov    -0x18(%ebp),%edx
  104835:	89 02                	mov    %eax,(%edx)
        pte_base = KADDR(*pdep);
  104837:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10483a:	8b 00                	mov    (%eax),%eax
  10483c:	89 45 d8             	mov    %eax,-0x28(%ebp)
  10483f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104842:	c1 e8 0c             	shr    $0xc,%eax
  104845:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  104848:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  10484d:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
  104850:	72 23                	jb     104875 <get_pte+0x10e>
  104852:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104855:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104859:	c7 44 24 08 a4 6d 10 	movl   $0x106da4,0x8(%esp)
  104860:	00 
  104861:	c7 44 24 04 79 01 00 	movl   $0x179,0x4(%esp)
  104868:	00 
  104869:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104870:	e8 62 c4 ff ff       	call   100cd7 <__panic>
  104875:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104878:	89 45 f0             	mov    %eax,-0x10(%ebp)
        memset(pte_base, 0, PGSIZE);
  10487b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  104882:	00 
  104883:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10488a:	00 
  10488b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10488e:	89 04 24             	mov    %eax,(%esp)
  104891:	e8 51 18 00 00       	call   1060e7 <memset>
        *pdep = *pdep | PTE_P | PTE_W | PTE_U;
  104896:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104899:	8b 00                	mov    (%eax),%eax
  10489b:	83 c8 07             	or     $0x7,%eax
  10489e:	89 c2                	mov    %eax,%edx
  1048a0:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1048a3:	89 10                	mov    %edx,(%eax)
  1048a5:	eb 07                	jmp    1048ae <get_pte+0x147>
    }
    else {
        find_pte = 0;
  1048a7:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
    }
    if (find_pte) {
  1048ae:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1048b2:	74 1a                	je     1048ce <get_pte+0x167>
        result = &pte_base[PTX(la)];
  1048b4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1048b7:	c1 e8 0c             	shr    $0xc,%eax
  1048ba:	25 ff 03 00 00       	and    $0x3ff,%eax
  1048bf:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  1048c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1048c9:	01 d0                	add    %edx,%eax
  1048cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }
    return result;
  1048ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1048d1:	c9                   	leave  
  1048d2:	c3                   	ret    

001048d3 <get_page>:

//get_page - get related Page struct for linear address la using PDT pgdir
struct Page *
get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
  1048d3:	55                   	push   %ebp
  1048d4:	89 e5                	mov    %esp,%ebp
  1048d6:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
  1048d9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1048e0:	00 
  1048e1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1048e4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1048e8:	8b 45 08             	mov    0x8(%ebp),%eax
  1048eb:	89 04 24             	mov    %eax,(%esp)
  1048ee:	e8 74 fe ff ff       	call   104767 <get_pte>
  1048f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep_store != NULL) {
  1048f6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1048fa:	74 08                	je     104904 <get_page+0x31>
        *ptep_store = ptep;
  1048fc:	8b 45 10             	mov    0x10(%ebp),%eax
  1048ff:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104902:	89 10                	mov    %edx,(%eax)
    }
    if (ptep != NULL && *ptep & PTE_P) {
  104904:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  104908:	74 1b                	je     104925 <get_page+0x52>
  10490a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10490d:	8b 00                	mov    (%eax),%eax
  10490f:	83 e0 01             	and    $0x1,%eax
  104912:	85 c0                	test   %eax,%eax
  104914:	74 0f                	je     104925 <get_page+0x52>
        return pte2page(*ptep);
  104916:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104919:	8b 00                	mov    (%eax),%eax
  10491b:	89 04 24             	mov    %eax,(%esp)
  10491e:	e8 ca f5 ff ff       	call   103eed <pte2page>
  104923:	eb 05                	jmp    10492a <get_page+0x57>
    }
    return NULL;
  104925:	b8 00 00 00 00       	mov    $0x0,%eax
}
  10492a:	c9                   	leave  
  10492b:	c3                   	ret    

0010492c <page_remove_pte>:

//page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
//note: PT is changed, so the TLB need to be invalidate 
static inline void
page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
  10492c:	55                   	push   %ebp
  10492d:	89 e5                	mov    %esp,%ebp
  10492f:	83 ec 28             	sub    $0x28,%esp
                                  //(4) and free this page when page reference reachs 0
                                  //(5) clear second page table entry
                                  //(6) flush tlb
    }
#endif
    if (!(*ptep & PTE_P)) {
  104932:	8b 45 10             	mov    0x10(%ebp),%eax
  104935:	8b 00                	mov    (%eax),%eax
  104937:	83 e0 01             	and    $0x1,%eax
  10493a:	85 c0                	test   %eax,%eax
  10493c:	75 02                	jne    104940 <page_remove_pte+0x14>
        return;
  10493e:	eb 53                	jmp    104993 <page_remove_pte+0x67>
    }
    struct Page *page = pte2page(*ptep);
  104940:	8b 45 10             	mov    0x10(%ebp),%eax
  104943:	8b 00                	mov    (%eax),%eax
  104945:	89 04 24             	mov    %eax,(%esp)
  104948:	e8 a0 f5 ff ff       	call   103eed <pte2page>
  10494d:	89 45 f4             	mov    %eax,-0xc(%ebp)
    page_ref_dec(page);
  104950:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104953:	89 04 24             	mov    %eax,(%esp)
  104956:	e8 16 f6 ff ff       	call   103f71 <page_ref_dec>
    if (page->ref <= 0) {
  10495b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10495e:	8b 00                	mov    (%eax),%eax
  104960:	85 c0                	test   %eax,%eax
  104962:	7f 13                	jg     104977 <page_remove_pte+0x4b>
        free_page(page);
  104964:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10496b:	00 
  10496c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10496f:	89 04 24             	mov    %eax,(%esp)
  104972:	e8 09 f8 ff ff       	call   104180 <free_pages>
    }
    *ptep = 0;
  104977:	8b 45 10             	mov    0x10(%ebp),%eax
  10497a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    tlb_invalidate(pgdir, la);
  104980:	8b 45 0c             	mov    0xc(%ebp),%eax
  104983:	89 44 24 04          	mov    %eax,0x4(%esp)
  104987:	8b 45 08             	mov    0x8(%ebp),%eax
  10498a:	89 04 24             	mov    %eax,(%esp)
  10498d:	e8 00 01 00 00       	call   104a92 <tlb_invalidate>
    return;
  104992:	90                   	nop
}
  104993:	c9                   	leave  
  104994:	c3                   	ret    

00104995 <page_remove>:

//page_remove - free an Page which is related linear address la and has an validated pte
void
page_remove(pde_t *pgdir, uintptr_t la) {
  104995:	55                   	push   %ebp
  104996:	89 e5                	mov    %esp,%ebp
  104998:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
  10499b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1049a2:	00 
  1049a3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1049a6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049aa:	8b 45 08             	mov    0x8(%ebp),%eax
  1049ad:	89 04 24             	mov    %eax,(%esp)
  1049b0:	e8 b2 fd ff ff       	call   104767 <get_pte>
  1049b5:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep != NULL) {
  1049b8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1049bc:	74 19                	je     1049d7 <page_remove+0x42>
        page_remove_pte(pgdir, la, ptep);
  1049be:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1049c1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1049c5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1049c8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049cc:	8b 45 08             	mov    0x8(%ebp),%eax
  1049cf:	89 04 24             	mov    %eax,(%esp)
  1049d2:	e8 55 ff ff ff       	call   10492c <page_remove_pte>
    }
}
  1049d7:	c9                   	leave  
  1049d8:	c3                   	ret    

001049d9 <page_insert>:
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
//note: PT is changed, so the TLB need to be invalidate 
int
page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
  1049d9:	55                   	push   %ebp
  1049da:	89 e5                	mov    %esp,%ebp
  1049dc:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 1);
  1049df:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  1049e6:	00 
  1049e7:	8b 45 10             	mov    0x10(%ebp),%eax
  1049ea:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1049f1:	89 04 24             	mov    %eax,(%esp)
  1049f4:	e8 6e fd ff ff       	call   104767 <get_pte>
  1049f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep == NULL) {
  1049fc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  104a00:	75 0a                	jne    104a0c <page_insert+0x33>
        return -E_NO_MEM;
  104a02:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
  104a07:	e9 84 00 00 00       	jmp    104a90 <page_insert+0xb7>
    }
    page_ref_inc(page);
  104a0c:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a0f:	89 04 24             	mov    %eax,(%esp)
  104a12:	e8 43 f5 ff ff       	call   103f5a <page_ref_inc>
    if (*ptep & PTE_P) {
  104a17:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104a1a:	8b 00                	mov    (%eax),%eax
  104a1c:	83 e0 01             	and    $0x1,%eax
  104a1f:	85 c0                	test   %eax,%eax
  104a21:	74 3e                	je     104a61 <page_insert+0x88>
        struct Page *p = pte2page(*ptep);
  104a23:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104a26:	8b 00                	mov    (%eax),%eax
  104a28:	89 04 24             	mov    %eax,(%esp)
  104a2b:	e8 bd f4 ff ff       	call   103eed <pte2page>
  104a30:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (p == page) {
  104a33:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104a36:	3b 45 0c             	cmp    0xc(%ebp),%eax
  104a39:	75 0d                	jne    104a48 <page_insert+0x6f>
            page_ref_dec(page);
  104a3b:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a3e:	89 04 24             	mov    %eax,(%esp)
  104a41:	e8 2b f5 ff ff       	call   103f71 <page_ref_dec>
  104a46:	eb 19                	jmp    104a61 <page_insert+0x88>
        }
        else {
            page_remove_pte(pgdir, la, ptep);
  104a48:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104a4b:	89 44 24 08          	mov    %eax,0x8(%esp)
  104a4f:	8b 45 10             	mov    0x10(%ebp),%eax
  104a52:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a56:	8b 45 08             	mov    0x8(%ebp),%eax
  104a59:	89 04 24             	mov    %eax,(%esp)
  104a5c:	e8 cb fe ff ff       	call   10492c <page_remove_pte>
        }
    }
    *ptep = page2pa(page) | PTE_P | perm;
  104a61:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a64:	89 04 24             	mov    %eax,(%esp)
  104a67:	e8 cd f3 ff ff       	call   103e39 <page2pa>
  104a6c:	0b 45 14             	or     0x14(%ebp),%eax
  104a6f:	83 c8 01             	or     $0x1,%eax
  104a72:	89 c2                	mov    %eax,%edx
  104a74:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104a77:	89 10                	mov    %edx,(%eax)
    tlb_invalidate(pgdir, la);
  104a79:	8b 45 10             	mov    0x10(%ebp),%eax
  104a7c:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a80:	8b 45 08             	mov    0x8(%ebp),%eax
  104a83:	89 04 24             	mov    %eax,(%esp)
  104a86:	e8 07 00 00 00       	call   104a92 <tlb_invalidate>
    return 0;
  104a8b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  104a90:	c9                   	leave  
  104a91:	c3                   	ret    

00104a92 <tlb_invalidate>:

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void
tlb_invalidate(pde_t *pgdir, uintptr_t la) {
  104a92:	55                   	push   %ebp
  104a93:	89 e5                	mov    %esp,%ebp
  104a95:	83 ec 10             	sub    $0x10,%esp
}

static inline uintptr_t
rcr3(void) {
    uintptr_t cr3;
    asm volatile ("mov %%cr3, %0" : "=r" (cr3) :: "memory");
  104a98:	0f 20 d8             	mov    %cr3,%eax
  104a9b:	89 45 f8             	mov    %eax,-0x8(%ebp)
    return cr3;
  104a9e:	8b 45 f8             	mov    -0x8(%ebp),%eax
    if (rcr3() == PADDR(pgdir)) {
  104aa1:	89 c2                	mov    %eax,%edx
  104aa3:	8b 45 08             	mov    0x8(%ebp),%eax
  104aa6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  104aa9:	8b 45 fc             	mov    -0x4(%ebp),%eax
  104aac:	39 c2                	cmp    %eax,%edx
  104aae:	75 0c                	jne    104abc <tlb_invalidate+0x2a>
        invlpg((void *)la);
  104ab0:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ab3:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static inline void
invlpg(void *addr) {
    asm volatile ("invlpg (%0)" :: "r" (addr) : "memory");
  104ab6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104ab9:	0f 01 38             	invlpg (%eax)
    }
}
  104abc:	c9                   	leave  
  104abd:	c3                   	ret    

00104abe <check_alloc_page>:

static void
check_alloc_page(void) {
  104abe:	55                   	push   %ebp
  104abf:	89 e5                	mov    %esp,%ebp
  104ac1:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->check();
  104ac4:	a1 1c af 11 00       	mov    0x11af1c,%eax
  104ac9:	8b 40 18             	mov    0x18(%eax),%eax
  104acc:	ff d0                	call   *%eax
    cprintf("check_alloc_page() succeeded!\n");
  104ace:	c7 04 24 a8 6e 10 00 	movl   $0x106ea8,(%esp)
  104ad5:	e8 73 b8 ff ff       	call   10034d <cprintf>
}
  104ada:	c9                   	leave  
  104adb:	c3                   	ret    

00104adc <check_pgdir>:

static void
check_pgdir(void) {
  104adc:	55                   	push   %ebp
  104add:	89 e5                	mov    %esp,%ebp
  104adf:	83 ec 38             	sub    $0x38,%esp
    assert(npage <= KMEMSIZE / PGSIZE);
  104ae2:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  104ae7:	3d 00 80 03 00       	cmp    $0x38000,%eax
  104aec:	76 24                	jbe    104b12 <check_pgdir+0x36>
  104aee:	c7 44 24 0c c7 6e 10 	movl   $0x106ec7,0xc(%esp)
  104af5:	00 
  104af6:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104afd:	00 
  104afe:	c7 44 24 04 f5 01 00 	movl   $0x1f5,0x4(%esp)
  104b05:	00 
  104b06:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104b0d:	e8 c5 c1 ff ff       	call   100cd7 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
  104b12:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104b17:	85 c0                	test   %eax,%eax
  104b19:	74 0e                	je     104b29 <check_pgdir+0x4d>
  104b1b:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104b20:	25 ff 0f 00 00       	and    $0xfff,%eax
  104b25:	85 c0                	test   %eax,%eax
  104b27:	74 24                	je     104b4d <check_pgdir+0x71>
  104b29:	c7 44 24 0c e4 6e 10 	movl   $0x106ee4,0xc(%esp)
  104b30:	00 
  104b31:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104b38:	00 
  104b39:	c7 44 24 04 f6 01 00 	movl   $0x1f6,0x4(%esp)
  104b40:	00 
  104b41:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104b48:	e8 8a c1 ff ff       	call   100cd7 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
  104b4d:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104b52:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104b59:	00 
  104b5a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104b61:	00 
  104b62:	89 04 24             	mov    %eax,(%esp)
  104b65:	e8 69 fd ff ff       	call   1048d3 <get_page>
  104b6a:	85 c0                	test   %eax,%eax
  104b6c:	74 24                	je     104b92 <check_pgdir+0xb6>
  104b6e:	c7 44 24 0c 1c 6f 10 	movl   $0x106f1c,0xc(%esp)
  104b75:	00 
  104b76:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104b7d:	00 
  104b7e:	c7 44 24 04 f7 01 00 	movl   $0x1f7,0x4(%esp)
  104b85:	00 
  104b86:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104b8d:	e8 45 c1 ff ff       	call   100cd7 <__panic>

    struct Page *p1, *p2;
    p1 = alloc_page();
  104b92:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104b99:	e8 aa f5 ff ff       	call   104148 <alloc_pages>
  104b9e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
  104ba1:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104ba6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  104bad:	00 
  104bae:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104bb5:	00 
  104bb6:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104bb9:	89 54 24 04          	mov    %edx,0x4(%esp)
  104bbd:	89 04 24             	mov    %eax,(%esp)
  104bc0:	e8 14 fe ff ff       	call   1049d9 <page_insert>
  104bc5:	85 c0                	test   %eax,%eax
  104bc7:	74 24                	je     104bed <check_pgdir+0x111>
  104bc9:	c7 44 24 0c 44 6f 10 	movl   $0x106f44,0xc(%esp)
  104bd0:	00 
  104bd1:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104bd8:	00 
  104bd9:	c7 44 24 04 fb 01 00 	movl   $0x1fb,0x4(%esp)
  104be0:	00 
  104be1:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104be8:	e8 ea c0 ff ff       	call   100cd7 <__panic>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
  104bed:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104bf2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104bf9:	00 
  104bfa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104c01:	00 
  104c02:	89 04 24             	mov    %eax,(%esp)
  104c05:	e8 5d fb ff ff       	call   104767 <get_pte>
  104c0a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104c0d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104c11:	75 24                	jne    104c37 <check_pgdir+0x15b>
  104c13:	c7 44 24 0c 70 6f 10 	movl   $0x106f70,0xc(%esp)
  104c1a:	00 
  104c1b:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104c22:	00 
  104c23:	c7 44 24 04 fe 01 00 	movl   $0x1fe,0x4(%esp)
  104c2a:	00 
  104c2b:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104c32:	e8 a0 c0 ff ff       	call   100cd7 <__panic>
    assert(pte2page(*ptep) == p1);
  104c37:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104c3a:	8b 00                	mov    (%eax),%eax
  104c3c:	89 04 24             	mov    %eax,(%esp)
  104c3f:	e8 a9 f2 ff ff       	call   103eed <pte2page>
  104c44:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104c47:	74 24                	je     104c6d <check_pgdir+0x191>
  104c49:	c7 44 24 0c 9d 6f 10 	movl   $0x106f9d,0xc(%esp)
  104c50:	00 
  104c51:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104c58:	00 
  104c59:	c7 44 24 04 ff 01 00 	movl   $0x1ff,0x4(%esp)
  104c60:	00 
  104c61:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104c68:	e8 6a c0 ff ff       	call   100cd7 <__panic>
    assert(page_ref(p1) == 1);
  104c6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104c70:	89 04 24             	mov    %eax,(%esp)
  104c73:	e8 cb f2 ff ff       	call   103f43 <page_ref>
  104c78:	83 f8 01             	cmp    $0x1,%eax
  104c7b:	74 24                	je     104ca1 <check_pgdir+0x1c5>
  104c7d:	c7 44 24 0c b3 6f 10 	movl   $0x106fb3,0xc(%esp)
  104c84:	00 
  104c85:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104c8c:	00 
  104c8d:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
  104c94:	00 
  104c95:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104c9c:	e8 36 c0 ff ff       	call   100cd7 <__panic>

    ptep = &((pte_t *)KADDR(PDE_ADDR(boot_pgdir[0])))[1];
  104ca1:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104ca6:	8b 00                	mov    (%eax),%eax
  104ca8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104cad:	89 45 ec             	mov    %eax,-0x14(%ebp)
  104cb0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104cb3:	c1 e8 0c             	shr    $0xc,%eax
  104cb6:	89 45 e8             	mov    %eax,-0x18(%ebp)
  104cb9:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  104cbe:	39 45 e8             	cmp    %eax,-0x18(%ebp)
  104cc1:	72 23                	jb     104ce6 <check_pgdir+0x20a>
  104cc3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104cc6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104cca:	c7 44 24 08 a4 6d 10 	movl   $0x106da4,0x8(%esp)
  104cd1:	00 
  104cd2:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
  104cd9:	00 
  104cda:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104ce1:	e8 f1 bf ff ff       	call   100cd7 <__panic>
  104ce6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104ce9:	83 c0 04             	add    $0x4,%eax
  104cec:	89 45 f0             	mov    %eax,-0x10(%ebp)
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
  104cef:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104cf4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104cfb:	00 
  104cfc:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  104d03:	00 
  104d04:	89 04 24             	mov    %eax,(%esp)
  104d07:	e8 5b fa ff ff       	call   104767 <get_pte>
  104d0c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104d0f:	74 24                	je     104d35 <check_pgdir+0x259>
  104d11:	c7 44 24 0c c8 6f 10 	movl   $0x106fc8,0xc(%esp)
  104d18:	00 
  104d19:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104d20:	00 
  104d21:	c7 44 24 04 03 02 00 	movl   $0x203,0x4(%esp)
  104d28:	00 
  104d29:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104d30:	e8 a2 bf ff ff       	call   100cd7 <__panic>

    p2 = alloc_page();
  104d35:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104d3c:	e8 07 f4 ff ff       	call   104148 <alloc_pages>
  104d41:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
  104d44:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104d49:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  104d50:	00 
  104d51:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  104d58:	00 
  104d59:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  104d5c:	89 54 24 04          	mov    %edx,0x4(%esp)
  104d60:	89 04 24             	mov    %eax,(%esp)
  104d63:	e8 71 fc ff ff       	call   1049d9 <page_insert>
  104d68:	85 c0                	test   %eax,%eax
  104d6a:	74 24                	je     104d90 <check_pgdir+0x2b4>
  104d6c:	c7 44 24 0c f0 6f 10 	movl   $0x106ff0,0xc(%esp)
  104d73:	00 
  104d74:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104d7b:	00 
  104d7c:	c7 44 24 04 06 02 00 	movl   $0x206,0x4(%esp)
  104d83:	00 
  104d84:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104d8b:	e8 47 bf ff ff       	call   100cd7 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
  104d90:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104d95:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104d9c:	00 
  104d9d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  104da4:	00 
  104da5:	89 04 24             	mov    %eax,(%esp)
  104da8:	e8 ba f9 ff ff       	call   104767 <get_pte>
  104dad:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104db0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104db4:	75 24                	jne    104dda <check_pgdir+0x2fe>
  104db6:	c7 44 24 0c 28 70 10 	movl   $0x107028,0xc(%esp)
  104dbd:	00 
  104dbe:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104dc5:	00 
  104dc6:	c7 44 24 04 07 02 00 	movl   $0x207,0x4(%esp)
  104dcd:	00 
  104dce:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104dd5:	e8 fd be ff ff       	call   100cd7 <__panic>
    assert(*ptep & PTE_U);
  104dda:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104ddd:	8b 00                	mov    (%eax),%eax
  104ddf:	83 e0 04             	and    $0x4,%eax
  104de2:	85 c0                	test   %eax,%eax
  104de4:	75 24                	jne    104e0a <check_pgdir+0x32e>
  104de6:	c7 44 24 0c 58 70 10 	movl   $0x107058,0xc(%esp)
  104ded:	00 
  104dee:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104df5:	00 
  104df6:	c7 44 24 04 08 02 00 	movl   $0x208,0x4(%esp)
  104dfd:	00 
  104dfe:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104e05:	e8 cd be ff ff       	call   100cd7 <__panic>
    assert(*ptep & PTE_W);
  104e0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104e0d:	8b 00                	mov    (%eax),%eax
  104e0f:	83 e0 02             	and    $0x2,%eax
  104e12:	85 c0                	test   %eax,%eax
  104e14:	75 24                	jne    104e3a <check_pgdir+0x35e>
  104e16:	c7 44 24 0c 66 70 10 	movl   $0x107066,0xc(%esp)
  104e1d:	00 
  104e1e:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104e25:	00 
  104e26:	c7 44 24 04 09 02 00 	movl   $0x209,0x4(%esp)
  104e2d:	00 
  104e2e:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104e35:	e8 9d be ff ff       	call   100cd7 <__panic>
    assert(boot_pgdir[0] & PTE_U);
  104e3a:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104e3f:	8b 00                	mov    (%eax),%eax
  104e41:	83 e0 04             	and    $0x4,%eax
  104e44:	85 c0                	test   %eax,%eax
  104e46:	75 24                	jne    104e6c <check_pgdir+0x390>
  104e48:	c7 44 24 0c 74 70 10 	movl   $0x107074,0xc(%esp)
  104e4f:	00 
  104e50:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104e57:	00 
  104e58:	c7 44 24 04 0a 02 00 	movl   $0x20a,0x4(%esp)
  104e5f:	00 
  104e60:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104e67:	e8 6b be ff ff       	call   100cd7 <__panic>
    assert(page_ref(p2) == 1);
  104e6c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104e6f:	89 04 24             	mov    %eax,(%esp)
  104e72:	e8 cc f0 ff ff       	call   103f43 <page_ref>
  104e77:	83 f8 01             	cmp    $0x1,%eax
  104e7a:	74 24                	je     104ea0 <check_pgdir+0x3c4>
  104e7c:	c7 44 24 0c 8a 70 10 	movl   $0x10708a,0xc(%esp)
  104e83:	00 
  104e84:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104e8b:	00 
  104e8c:	c7 44 24 04 0b 02 00 	movl   $0x20b,0x4(%esp)
  104e93:	00 
  104e94:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104e9b:	e8 37 be ff ff       	call   100cd7 <__panic>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
  104ea0:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104ea5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  104eac:	00 
  104ead:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  104eb4:	00 
  104eb5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104eb8:	89 54 24 04          	mov    %edx,0x4(%esp)
  104ebc:	89 04 24             	mov    %eax,(%esp)
  104ebf:	e8 15 fb ff ff       	call   1049d9 <page_insert>
  104ec4:	85 c0                	test   %eax,%eax
  104ec6:	74 24                	je     104eec <check_pgdir+0x410>
  104ec8:	c7 44 24 0c 9c 70 10 	movl   $0x10709c,0xc(%esp)
  104ecf:	00 
  104ed0:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104ed7:	00 
  104ed8:	c7 44 24 04 0d 02 00 	movl   $0x20d,0x4(%esp)
  104edf:	00 
  104ee0:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104ee7:	e8 eb bd ff ff       	call   100cd7 <__panic>
    assert(page_ref(p1) == 2);
  104eec:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104eef:	89 04 24             	mov    %eax,(%esp)
  104ef2:	e8 4c f0 ff ff       	call   103f43 <page_ref>
  104ef7:	83 f8 02             	cmp    $0x2,%eax
  104efa:	74 24                	je     104f20 <check_pgdir+0x444>
  104efc:	c7 44 24 0c c8 70 10 	movl   $0x1070c8,0xc(%esp)
  104f03:	00 
  104f04:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104f0b:	00 
  104f0c:	c7 44 24 04 0e 02 00 	movl   $0x20e,0x4(%esp)
  104f13:	00 
  104f14:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104f1b:	e8 b7 bd ff ff       	call   100cd7 <__panic>
    assert(page_ref(p2) == 0);
  104f20:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104f23:	89 04 24             	mov    %eax,(%esp)
  104f26:	e8 18 f0 ff ff       	call   103f43 <page_ref>
  104f2b:	85 c0                	test   %eax,%eax
  104f2d:	74 24                	je     104f53 <check_pgdir+0x477>
  104f2f:	c7 44 24 0c da 70 10 	movl   $0x1070da,0xc(%esp)
  104f36:	00 
  104f37:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104f3e:	00 
  104f3f:	c7 44 24 04 0f 02 00 	movl   $0x20f,0x4(%esp)
  104f46:	00 
  104f47:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104f4e:	e8 84 bd ff ff       	call   100cd7 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
  104f53:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  104f58:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104f5f:	00 
  104f60:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  104f67:	00 
  104f68:	89 04 24             	mov    %eax,(%esp)
  104f6b:	e8 f7 f7 ff ff       	call   104767 <get_pte>
  104f70:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104f73:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104f77:	75 24                	jne    104f9d <check_pgdir+0x4c1>
  104f79:	c7 44 24 0c 28 70 10 	movl   $0x107028,0xc(%esp)
  104f80:	00 
  104f81:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104f88:	00 
  104f89:	c7 44 24 04 10 02 00 	movl   $0x210,0x4(%esp)
  104f90:	00 
  104f91:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104f98:	e8 3a bd ff ff       	call   100cd7 <__panic>
    assert(pte2page(*ptep) == p1);
  104f9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104fa0:	8b 00                	mov    (%eax),%eax
  104fa2:	89 04 24             	mov    %eax,(%esp)
  104fa5:	e8 43 ef ff ff       	call   103eed <pte2page>
  104faa:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104fad:	74 24                	je     104fd3 <check_pgdir+0x4f7>
  104faf:	c7 44 24 0c 9d 6f 10 	movl   $0x106f9d,0xc(%esp)
  104fb6:	00 
  104fb7:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104fbe:	00 
  104fbf:	c7 44 24 04 11 02 00 	movl   $0x211,0x4(%esp)
  104fc6:	00 
  104fc7:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104fce:	e8 04 bd ff ff       	call   100cd7 <__panic>
    assert((*ptep & PTE_U) == 0);
  104fd3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104fd6:	8b 00                	mov    (%eax),%eax
  104fd8:	83 e0 04             	and    $0x4,%eax
  104fdb:	85 c0                	test   %eax,%eax
  104fdd:	74 24                	je     105003 <check_pgdir+0x527>
  104fdf:	c7 44 24 0c ec 70 10 	movl   $0x1070ec,0xc(%esp)
  104fe6:	00 
  104fe7:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  104fee:	00 
  104fef:	c7 44 24 04 12 02 00 	movl   $0x212,0x4(%esp)
  104ff6:	00 
  104ff7:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  104ffe:	e8 d4 bc ff ff       	call   100cd7 <__panic>

    page_remove(boot_pgdir, 0x0);
  105003:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  105008:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10500f:	00 
  105010:	89 04 24             	mov    %eax,(%esp)
  105013:	e8 7d f9 ff ff       	call   104995 <page_remove>
    assert(page_ref(p1) == 1);
  105018:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10501b:	89 04 24             	mov    %eax,(%esp)
  10501e:	e8 20 ef ff ff       	call   103f43 <page_ref>
  105023:	83 f8 01             	cmp    $0x1,%eax
  105026:	74 24                	je     10504c <check_pgdir+0x570>
  105028:	c7 44 24 0c b3 6f 10 	movl   $0x106fb3,0xc(%esp)
  10502f:	00 
  105030:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  105037:	00 
  105038:	c7 44 24 04 15 02 00 	movl   $0x215,0x4(%esp)
  10503f:	00 
  105040:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  105047:	e8 8b bc ff ff       	call   100cd7 <__panic>
    assert(page_ref(p2) == 0);
  10504c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10504f:	89 04 24             	mov    %eax,(%esp)
  105052:	e8 ec ee ff ff       	call   103f43 <page_ref>
  105057:	85 c0                	test   %eax,%eax
  105059:	74 24                	je     10507f <check_pgdir+0x5a3>
  10505b:	c7 44 24 0c da 70 10 	movl   $0x1070da,0xc(%esp)
  105062:	00 
  105063:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  10506a:	00 
  10506b:	c7 44 24 04 16 02 00 	movl   $0x216,0x4(%esp)
  105072:	00 
  105073:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  10507a:	e8 58 bc ff ff       	call   100cd7 <__panic>

    page_remove(boot_pgdir, PGSIZE);
  10507f:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  105084:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  10508b:	00 
  10508c:	89 04 24             	mov    %eax,(%esp)
  10508f:	e8 01 f9 ff ff       	call   104995 <page_remove>
    assert(page_ref(p1) == 0);
  105094:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105097:	89 04 24             	mov    %eax,(%esp)
  10509a:	e8 a4 ee ff ff       	call   103f43 <page_ref>
  10509f:	85 c0                	test   %eax,%eax
  1050a1:	74 24                	je     1050c7 <check_pgdir+0x5eb>
  1050a3:	c7 44 24 0c 01 71 10 	movl   $0x107101,0xc(%esp)
  1050aa:	00 
  1050ab:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  1050b2:	00 
  1050b3:	c7 44 24 04 19 02 00 	movl   $0x219,0x4(%esp)
  1050ba:	00 
  1050bb:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  1050c2:	e8 10 bc ff ff       	call   100cd7 <__panic>
    assert(page_ref(p2) == 0);
  1050c7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1050ca:	89 04 24             	mov    %eax,(%esp)
  1050cd:	e8 71 ee ff ff       	call   103f43 <page_ref>
  1050d2:	85 c0                	test   %eax,%eax
  1050d4:	74 24                	je     1050fa <check_pgdir+0x61e>
  1050d6:	c7 44 24 0c da 70 10 	movl   $0x1070da,0xc(%esp)
  1050dd:	00 
  1050de:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  1050e5:	00 
  1050e6:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
  1050ed:	00 
  1050ee:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  1050f5:	e8 dd bb ff ff       	call   100cd7 <__panic>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
  1050fa:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1050ff:	8b 00                	mov    (%eax),%eax
  105101:	89 04 24             	mov    %eax,(%esp)
  105104:	e8 22 ee ff ff       	call   103f2b <pde2page>
  105109:	89 04 24             	mov    %eax,(%esp)
  10510c:	e8 32 ee ff ff       	call   103f43 <page_ref>
  105111:	83 f8 01             	cmp    $0x1,%eax
  105114:	74 24                	je     10513a <check_pgdir+0x65e>
  105116:	c7 44 24 0c 14 71 10 	movl   $0x107114,0xc(%esp)
  10511d:	00 
  10511e:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  105125:	00 
  105126:	c7 44 24 04 1c 02 00 	movl   $0x21c,0x4(%esp)
  10512d:	00 
  10512e:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  105135:	e8 9d bb ff ff       	call   100cd7 <__panic>
    free_page(pde2page(boot_pgdir[0]));
  10513a:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  10513f:	8b 00                	mov    (%eax),%eax
  105141:	89 04 24             	mov    %eax,(%esp)
  105144:	e8 e2 ed ff ff       	call   103f2b <pde2page>
  105149:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105150:	00 
  105151:	89 04 24             	mov    %eax,(%esp)
  105154:	e8 27 f0 ff ff       	call   104180 <free_pages>
    boot_pgdir[0] = 0;
  105159:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  10515e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_pgdir() succeeded!\n");
  105164:	c7 04 24 3b 71 10 00 	movl   $0x10713b,(%esp)
  10516b:	e8 dd b1 ff ff       	call   10034d <cprintf>
}
  105170:	c9                   	leave  
  105171:	c3                   	ret    

00105172 <check_boot_pgdir>:

static void
check_boot_pgdir(void) {
  105172:	55                   	push   %ebp
  105173:	89 e5                	mov    %esp,%ebp
  105175:	83 ec 38             	sub    $0x38,%esp
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
  105178:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10517f:	e9 c5 00 00 00       	jmp    105249 <check_boot_pgdir+0xd7>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
  105184:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105187:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10518a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10518d:	c1 e8 0c             	shr    $0xc,%eax
  105190:	89 45 ec             	mov    %eax,-0x14(%ebp)
  105193:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  105198:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  10519b:	72 23                	jb     1051c0 <check_boot_pgdir+0x4e>
  10519d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1051a0:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1051a4:	c7 44 24 08 a4 6d 10 	movl   $0x106da4,0x8(%esp)
  1051ab:	00 
  1051ac:	c7 44 24 04 28 02 00 	movl   $0x228,0x4(%esp)
  1051b3:	00 
  1051b4:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  1051bb:	e8 17 bb ff ff       	call   100cd7 <__panic>
  1051c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1051c3:	89 c2                	mov    %eax,%edx
  1051c5:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1051ca:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1051d1:	00 
  1051d2:	89 54 24 04          	mov    %edx,0x4(%esp)
  1051d6:	89 04 24             	mov    %eax,(%esp)
  1051d9:	e8 89 f5 ff ff       	call   104767 <get_pte>
  1051de:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1051e1:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  1051e5:	75 24                	jne    10520b <check_boot_pgdir+0x99>
  1051e7:	c7 44 24 0c 58 71 10 	movl   $0x107158,0xc(%esp)
  1051ee:	00 
  1051ef:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  1051f6:	00 
  1051f7:	c7 44 24 04 28 02 00 	movl   $0x228,0x4(%esp)
  1051fe:	00 
  1051ff:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  105206:	e8 cc ba ff ff       	call   100cd7 <__panic>
        assert(PTE_ADDR(*ptep) == i);
  10520b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10520e:	8b 00                	mov    (%eax),%eax
  105210:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105215:	89 c2                	mov    %eax,%edx
  105217:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10521a:	39 c2                	cmp    %eax,%edx
  10521c:	74 24                	je     105242 <check_boot_pgdir+0xd0>
  10521e:	c7 44 24 0c 95 71 10 	movl   $0x107195,0xc(%esp)
  105225:	00 
  105226:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  10522d:	00 
  10522e:	c7 44 24 04 29 02 00 	movl   $0x229,0x4(%esp)
  105235:	00 
  105236:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  10523d:	e8 95 ba ff ff       	call   100cd7 <__panic>

static void
check_boot_pgdir(void) {
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
  105242:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
  105249:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10524c:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  105251:	39 c2                	cmp    %eax,%edx
  105253:	0f 82 2b ff ff ff    	jb     105184 <check_boot_pgdir+0x12>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }

    assert(PDE_ADDR(boot_pgdir[PDX(VPT)]) == PADDR(boot_pgdir));
  105259:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  10525e:	05 ac 0f 00 00       	add    $0xfac,%eax
  105263:	8b 00                	mov    (%eax),%eax
  105265:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10526a:	89 c2                	mov    %eax,%edx
  10526c:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  105271:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  105274:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105277:	39 c2                	cmp    %eax,%edx
  105279:	74 24                	je     10529f <check_boot_pgdir+0x12d>
  10527b:	c7 44 24 0c ac 71 10 	movl   $0x1071ac,0xc(%esp)
  105282:	00 
  105283:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  10528a:	00 
  10528b:	c7 44 24 04 2c 02 00 	movl   $0x22c,0x4(%esp)
  105292:	00 
  105293:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  10529a:	e8 38 ba ff ff       	call   100cd7 <__panic>

    assert(boot_pgdir[0] == 0);
  10529f:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1052a4:	8b 00                	mov    (%eax),%eax
  1052a6:	85 c0                	test   %eax,%eax
  1052a8:	74 24                	je     1052ce <check_boot_pgdir+0x15c>
  1052aa:	c7 44 24 0c e0 71 10 	movl   $0x1071e0,0xc(%esp)
  1052b1:	00 
  1052b2:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  1052b9:	00 
  1052ba:	c7 44 24 04 2e 02 00 	movl   $0x22e,0x4(%esp)
  1052c1:	00 
  1052c2:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  1052c9:	e8 09 ba ff ff       	call   100cd7 <__panic>

    struct Page *p;
    p = alloc_page();
  1052ce:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1052d5:	e8 6e ee ff ff       	call   104148 <alloc_pages>
  1052da:	89 45 e0             	mov    %eax,-0x20(%ebp)
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W) == 0);
  1052dd:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1052e2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
  1052e9:	00 
  1052ea:	c7 44 24 08 00 01 00 	movl   $0x100,0x8(%esp)
  1052f1:	00 
  1052f2:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1052f5:	89 54 24 04          	mov    %edx,0x4(%esp)
  1052f9:	89 04 24             	mov    %eax,(%esp)
  1052fc:	e8 d8 f6 ff ff       	call   1049d9 <page_insert>
  105301:	85 c0                	test   %eax,%eax
  105303:	74 24                	je     105329 <check_boot_pgdir+0x1b7>
  105305:	c7 44 24 0c f4 71 10 	movl   $0x1071f4,0xc(%esp)
  10530c:	00 
  10530d:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  105314:	00 
  105315:	c7 44 24 04 32 02 00 	movl   $0x232,0x4(%esp)
  10531c:	00 
  10531d:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  105324:	e8 ae b9 ff ff       	call   100cd7 <__panic>
    assert(page_ref(p) == 1);
  105329:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10532c:	89 04 24             	mov    %eax,(%esp)
  10532f:	e8 0f ec ff ff       	call   103f43 <page_ref>
  105334:	83 f8 01             	cmp    $0x1,%eax
  105337:	74 24                	je     10535d <check_boot_pgdir+0x1eb>
  105339:	c7 44 24 0c 22 72 10 	movl   $0x107222,0xc(%esp)
  105340:	00 
  105341:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  105348:	00 
  105349:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
  105350:	00 
  105351:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  105358:	e8 7a b9 ff ff       	call   100cd7 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W) == 0);
  10535d:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  105362:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
  105369:	00 
  10536a:	c7 44 24 08 00 11 00 	movl   $0x1100,0x8(%esp)
  105371:	00 
  105372:	8b 55 e0             	mov    -0x20(%ebp),%edx
  105375:	89 54 24 04          	mov    %edx,0x4(%esp)
  105379:	89 04 24             	mov    %eax,(%esp)
  10537c:	e8 58 f6 ff ff       	call   1049d9 <page_insert>
  105381:	85 c0                	test   %eax,%eax
  105383:	74 24                	je     1053a9 <check_boot_pgdir+0x237>
  105385:	c7 44 24 0c 34 72 10 	movl   $0x107234,0xc(%esp)
  10538c:	00 
  10538d:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  105394:	00 
  105395:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
  10539c:	00 
  10539d:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  1053a4:	e8 2e b9 ff ff       	call   100cd7 <__panic>
    assert(page_ref(p) == 2);
  1053a9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1053ac:	89 04 24             	mov    %eax,(%esp)
  1053af:	e8 8f eb ff ff       	call   103f43 <page_ref>
  1053b4:	83 f8 02             	cmp    $0x2,%eax
  1053b7:	74 24                	je     1053dd <check_boot_pgdir+0x26b>
  1053b9:	c7 44 24 0c 6b 72 10 	movl   $0x10726b,0xc(%esp)
  1053c0:	00 
  1053c1:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  1053c8:	00 
  1053c9:	c7 44 24 04 35 02 00 	movl   $0x235,0x4(%esp)
  1053d0:	00 
  1053d1:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  1053d8:	e8 fa b8 ff ff       	call   100cd7 <__panic>

    const char *str = "ucore: Hello world!!";
  1053dd:	c7 45 dc 7c 72 10 00 	movl   $0x10727c,-0x24(%ebp)
    strcpy((void *)0x100, str);
  1053e4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1053e7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1053eb:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
  1053f2:	e8 19 0a 00 00       	call   105e10 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
  1053f7:	c7 44 24 04 00 11 00 	movl   $0x1100,0x4(%esp)
  1053fe:	00 
  1053ff:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
  105406:	e8 7e 0a 00 00       	call   105e89 <strcmp>
  10540b:	85 c0                	test   %eax,%eax
  10540d:	74 24                	je     105433 <check_boot_pgdir+0x2c1>
  10540f:	c7 44 24 0c 94 72 10 	movl   $0x107294,0xc(%esp)
  105416:	00 
  105417:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  10541e:	00 
  10541f:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
  105426:	00 
  105427:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  10542e:	e8 a4 b8 ff ff       	call   100cd7 <__panic>

    *(char *)(page2kva(p) + 0x100) = '\0';
  105433:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105436:	89 04 24             	mov    %eax,(%esp)
  105439:	e8 60 ea ff ff       	call   103e9e <page2kva>
  10543e:	05 00 01 00 00       	add    $0x100,%eax
  105443:	c6 00 00             	movb   $0x0,(%eax)
    assert(strlen((const char *)0x100) == 0);
  105446:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
  10544d:	e8 66 09 00 00       	call   105db8 <strlen>
  105452:	85 c0                	test   %eax,%eax
  105454:	74 24                	je     10547a <check_boot_pgdir+0x308>
  105456:	c7 44 24 0c cc 72 10 	movl   $0x1072cc,0xc(%esp)
  10545d:	00 
  10545e:	c7 44 24 08 5f 6e 10 	movl   $0x106e5f,0x8(%esp)
  105465:	00 
  105466:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
  10546d:	00 
  10546e:	c7 04 24 74 6e 10 00 	movl   $0x106e74,(%esp)
  105475:	e8 5d b8 ff ff       	call   100cd7 <__panic>

    free_page(p);
  10547a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105481:	00 
  105482:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105485:	89 04 24             	mov    %eax,(%esp)
  105488:	e8 f3 ec ff ff       	call   104180 <free_pages>
    free_page(pde2page(boot_pgdir[0]));
  10548d:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  105492:	8b 00                	mov    (%eax),%eax
  105494:	89 04 24             	mov    %eax,(%esp)
  105497:	e8 8f ea ff ff       	call   103f2b <pde2page>
  10549c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1054a3:	00 
  1054a4:	89 04 24             	mov    %eax,(%esp)
  1054a7:	e8 d4 ec ff ff       	call   104180 <free_pages>
    boot_pgdir[0] = 0;
  1054ac:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1054b1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_boot_pgdir() succeeded!\n");
  1054b7:	c7 04 24 f0 72 10 00 	movl   $0x1072f0,(%esp)
  1054be:	e8 8a ae ff ff       	call   10034d <cprintf>
}
  1054c3:	c9                   	leave  
  1054c4:	c3                   	ret    

001054c5 <perm2str>:

//perm2str - use string 'u,r,w,-' to present the permission
static const char *
perm2str(int perm) {
  1054c5:	55                   	push   %ebp
  1054c6:	89 e5                	mov    %esp,%ebp
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
  1054c8:	8b 45 08             	mov    0x8(%ebp),%eax
  1054cb:	83 e0 04             	and    $0x4,%eax
  1054ce:	85 c0                	test   %eax,%eax
  1054d0:	74 07                	je     1054d9 <perm2str+0x14>
  1054d2:	b8 75 00 00 00       	mov    $0x75,%eax
  1054d7:	eb 05                	jmp    1054de <perm2str+0x19>
  1054d9:	b8 2d 00 00 00       	mov    $0x2d,%eax
  1054de:	a2 08 af 11 00       	mov    %al,0x11af08
    str[1] = 'r';
  1054e3:	c6 05 09 af 11 00 72 	movb   $0x72,0x11af09
    str[2] = (perm & PTE_W) ? 'w' : '-';
  1054ea:	8b 45 08             	mov    0x8(%ebp),%eax
  1054ed:	83 e0 02             	and    $0x2,%eax
  1054f0:	85 c0                	test   %eax,%eax
  1054f2:	74 07                	je     1054fb <perm2str+0x36>
  1054f4:	b8 77 00 00 00       	mov    $0x77,%eax
  1054f9:	eb 05                	jmp    105500 <perm2str+0x3b>
  1054fb:	b8 2d 00 00 00       	mov    $0x2d,%eax
  105500:	a2 0a af 11 00       	mov    %al,0x11af0a
    str[3] = '\0';
  105505:	c6 05 0b af 11 00 00 	movb   $0x0,0x11af0b
    return str;
  10550c:	b8 08 af 11 00       	mov    $0x11af08,%eax
}
  105511:	5d                   	pop    %ebp
  105512:	c3                   	ret    

00105513 <get_pgtable_items>:
//  table:       the beginning addr of table
//  left_store:  the pointer of the high side of table's next range
//  right_store: the pointer of the low side of table's next range
// return value: 0 - not a invalid item range, perm - a valid item range with perm permission 
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
  105513:	55                   	push   %ebp
  105514:	89 e5                	mov    %esp,%ebp
  105516:	83 ec 10             	sub    $0x10,%esp
    if (start >= right) {
  105519:	8b 45 10             	mov    0x10(%ebp),%eax
  10551c:	3b 45 0c             	cmp    0xc(%ebp),%eax
  10551f:	72 0a                	jb     10552b <get_pgtable_items+0x18>
        return 0;
  105521:	b8 00 00 00 00       	mov    $0x0,%eax
  105526:	e9 9c 00 00 00       	jmp    1055c7 <get_pgtable_items+0xb4>
    }
    while (start < right && !(table[start] & PTE_P)) {
  10552b:	eb 04                	jmp    105531 <get_pgtable_items+0x1e>
        start ++;
  10552d:	83 45 10 01          	addl   $0x1,0x10(%ebp)
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
    if (start >= right) {
        return 0;
    }
    while (start < right && !(table[start] & PTE_P)) {
  105531:	8b 45 10             	mov    0x10(%ebp),%eax
  105534:	3b 45 0c             	cmp    0xc(%ebp),%eax
  105537:	73 18                	jae    105551 <get_pgtable_items+0x3e>
  105539:	8b 45 10             	mov    0x10(%ebp),%eax
  10553c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  105543:	8b 45 14             	mov    0x14(%ebp),%eax
  105546:	01 d0                	add    %edx,%eax
  105548:	8b 00                	mov    (%eax),%eax
  10554a:	83 e0 01             	and    $0x1,%eax
  10554d:	85 c0                	test   %eax,%eax
  10554f:	74 dc                	je     10552d <get_pgtable_items+0x1a>
        start ++;
    }
    if (start < right) {
  105551:	8b 45 10             	mov    0x10(%ebp),%eax
  105554:	3b 45 0c             	cmp    0xc(%ebp),%eax
  105557:	73 69                	jae    1055c2 <get_pgtable_items+0xaf>
        if (left_store != NULL) {
  105559:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
  10555d:	74 08                	je     105567 <get_pgtable_items+0x54>
            *left_store = start;
  10555f:	8b 45 18             	mov    0x18(%ebp),%eax
  105562:	8b 55 10             	mov    0x10(%ebp),%edx
  105565:	89 10                	mov    %edx,(%eax)
        }
        int perm = (table[start ++] & PTE_USER);
  105567:	8b 45 10             	mov    0x10(%ebp),%eax
  10556a:	8d 50 01             	lea    0x1(%eax),%edx
  10556d:	89 55 10             	mov    %edx,0x10(%ebp)
  105570:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  105577:	8b 45 14             	mov    0x14(%ebp),%eax
  10557a:	01 d0                	add    %edx,%eax
  10557c:	8b 00                	mov    (%eax),%eax
  10557e:	83 e0 07             	and    $0x7,%eax
  105581:	89 45 fc             	mov    %eax,-0x4(%ebp)
        while (start < right && (table[start] & PTE_USER) == perm) {
  105584:	eb 04                	jmp    10558a <get_pgtable_items+0x77>
            start ++;
  105586:	83 45 10 01          	addl   $0x1,0x10(%ebp)
    if (start < right) {
        if (left_store != NULL) {
            *left_store = start;
        }
        int perm = (table[start ++] & PTE_USER);
        while (start < right && (table[start] & PTE_USER) == perm) {
  10558a:	8b 45 10             	mov    0x10(%ebp),%eax
  10558d:	3b 45 0c             	cmp    0xc(%ebp),%eax
  105590:	73 1d                	jae    1055af <get_pgtable_items+0x9c>
  105592:	8b 45 10             	mov    0x10(%ebp),%eax
  105595:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  10559c:	8b 45 14             	mov    0x14(%ebp),%eax
  10559f:	01 d0                	add    %edx,%eax
  1055a1:	8b 00                	mov    (%eax),%eax
  1055a3:	83 e0 07             	and    $0x7,%eax
  1055a6:	89 c2                	mov    %eax,%edx
  1055a8:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1055ab:	39 c2                	cmp    %eax,%edx
  1055ad:	74 d7                	je     105586 <get_pgtable_items+0x73>
            start ++;
        }
        if (right_store != NULL) {
  1055af:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
  1055b3:	74 08                	je     1055bd <get_pgtable_items+0xaa>
            *right_store = start;
  1055b5:	8b 45 1c             	mov    0x1c(%ebp),%eax
  1055b8:	8b 55 10             	mov    0x10(%ebp),%edx
  1055bb:	89 10                	mov    %edx,(%eax)
        }
        return perm;
  1055bd:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1055c0:	eb 05                	jmp    1055c7 <get_pgtable_items+0xb4>
    }
    return 0;
  1055c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1055c7:	c9                   	leave  
  1055c8:	c3                   	ret    

001055c9 <print_pgdir>:

//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
  1055c9:	55                   	push   %ebp
  1055ca:	89 e5                	mov    %esp,%ebp
  1055cc:	57                   	push   %edi
  1055cd:	56                   	push   %esi
  1055ce:	53                   	push   %ebx
  1055cf:	83 ec 4c             	sub    $0x4c,%esp
    cprintf("-------------------- BEGIN --------------------\n");
  1055d2:	c7 04 24 10 73 10 00 	movl   $0x107310,(%esp)
  1055d9:	e8 6f ad ff ff       	call   10034d <cprintf>
    size_t left, right = 0, perm;
  1055de:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
  1055e5:	e9 fa 00 00 00       	jmp    1056e4 <print_pgdir+0x11b>
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
  1055ea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1055ed:	89 04 24             	mov    %eax,(%esp)
  1055f0:	e8 d0 fe ff ff       	call   1054c5 <perm2str>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
  1055f5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  1055f8:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1055fb:	29 d1                	sub    %edx,%ecx
  1055fd:	89 ca                	mov    %ecx,%edx
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
  1055ff:	89 d6                	mov    %edx,%esi
  105601:	c1 e6 16             	shl    $0x16,%esi
  105604:	8b 55 dc             	mov    -0x24(%ebp),%edx
  105607:	89 d3                	mov    %edx,%ebx
  105609:	c1 e3 16             	shl    $0x16,%ebx
  10560c:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10560f:	89 d1                	mov    %edx,%ecx
  105611:	c1 e1 16             	shl    $0x16,%ecx
  105614:	8b 7d dc             	mov    -0x24(%ebp),%edi
  105617:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10561a:	29 d7                	sub    %edx,%edi
  10561c:	89 fa                	mov    %edi,%edx
  10561e:	89 44 24 14          	mov    %eax,0x14(%esp)
  105622:	89 74 24 10          	mov    %esi,0x10(%esp)
  105626:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  10562a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  10562e:	89 54 24 04          	mov    %edx,0x4(%esp)
  105632:	c7 04 24 41 73 10 00 	movl   $0x107341,(%esp)
  105639:	e8 0f ad ff ff       	call   10034d <cprintf>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
  10563e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105641:	c1 e0 0a             	shl    $0xa,%eax
  105644:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
  105647:	eb 54                	jmp    10569d <print_pgdir+0xd4>
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
  105649:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10564c:	89 04 24             	mov    %eax,(%esp)
  10564f:	e8 71 fe ff ff       	call   1054c5 <perm2str>
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
  105654:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  105657:	8b 55 d8             	mov    -0x28(%ebp),%edx
  10565a:	29 d1                	sub    %edx,%ecx
  10565c:	89 ca                	mov    %ecx,%edx
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
  10565e:	89 d6                	mov    %edx,%esi
  105660:	c1 e6 0c             	shl    $0xc,%esi
  105663:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  105666:	89 d3                	mov    %edx,%ebx
  105668:	c1 e3 0c             	shl    $0xc,%ebx
  10566b:	8b 55 d8             	mov    -0x28(%ebp),%edx
  10566e:	c1 e2 0c             	shl    $0xc,%edx
  105671:	89 d1                	mov    %edx,%ecx
  105673:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  105676:	8b 55 d8             	mov    -0x28(%ebp),%edx
  105679:	29 d7                	sub    %edx,%edi
  10567b:	89 fa                	mov    %edi,%edx
  10567d:	89 44 24 14          	mov    %eax,0x14(%esp)
  105681:	89 74 24 10          	mov    %esi,0x10(%esp)
  105685:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  105689:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  10568d:	89 54 24 04          	mov    %edx,0x4(%esp)
  105691:	c7 04 24 60 73 10 00 	movl   $0x107360,(%esp)
  105698:	e8 b0 ac ff ff       	call   10034d <cprintf>
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
  10569d:	ba 00 00 c0 fa       	mov    $0xfac00000,%edx
  1056a2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1056a5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  1056a8:	89 ce                	mov    %ecx,%esi
  1056aa:	c1 e6 0a             	shl    $0xa,%esi
  1056ad:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  1056b0:	89 cb                	mov    %ecx,%ebx
  1056b2:	c1 e3 0a             	shl    $0xa,%ebx
  1056b5:	8d 4d d4             	lea    -0x2c(%ebp),%ecx
  1056b8:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  1056bc:	8d 4d d8             	lea    -0x28(%ebp),%ecx
  1056bf:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  1056c3:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1056c7:	89 44 24 08          	mov    %eax,0x8(%esp)
  1056cb:	89 74 24 04          	mov    %esi,0x4(%esp)
  1056cf:	89 1c 24             	mov    %ebx,(%esp)
  1056d2:	e8 3c fe ff ff       	call   105513 <get_pgtable_items>
  1056d7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1056da:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  1056de:	0f 85 65 ff ff ff    	jne    105649 <print_pgdir+0x80>
//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
  1056e4:	ba 00 b0 fe fa       	mov    $0xfafeb000,%edx
  1056e9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1056ec:	8d 4d dc             	lea    -0x24(%ebp),%ecx
  1056ef:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  1056f3:	8d 4d e0             	lea    -0x20(%ebp),%ecx
  1056f6:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  1056fa:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1056fe:	89 44 24 08          	mov    %eax,0x8(%esp)
  105702:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  105709:	00 
  10570a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  105711:	e8 fd fd ff ff       	call   105513 <get_pgtable_items>
  105716:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  105719:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  10571d:	0f 85 c7 fe ff ff    	jne    1055ea <print_pgdir+0x21>
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
        }
    }
    cprintf("--------------------- END ---------------------\n");
  105723:	c7 04 24 84 73 10 00 	movl   $0x107384,(%esp)
  10572a:	e8 1e ac ff ff       	call   10034d <cprintf>
}
  10572f:	83 c4 4c             	add    $0x4c,%esp
  105732:	5b                   	pop    %ebx
  105733:	5e                   	pop    %esi
  105734:	5f                   	pop    %edi
  105735:	5d                   	pop    %ebp
  105736:	c3                   	ret    

00105737 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  105737:	55                   	push   %ebp
  105738:	89 e5                	mov    %esp,%ebp
  10573a:	83 ec 58             	sub    $0x58,%esp
  10573d:	8b 45 10             	mov    0x10(%ebp),%eax
  105740:	89 45 d0             	mov    %eax,-0x30(%ebp)
  105743:	8b 45 14             	mov    0x14(%ebp),%eax
  105746:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    unsigned long long result = num;
  105749:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10574c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10574f:	89 45 e8             	mov    %eax,-0x18(%ebp)
  105752:	89 55 ec             	mov    %edx,-0x14(%ebp)
    unsigned mod = do_div(result, base);
  105755:	8b 45 18             	mov    0x18(%ebp),%eax
  105758:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  10575b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10575e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  105761:	89 45 e0             	mov    %eax,-0x20(%ebp)
  105764:	89 55 f0             	mov    %edx,-0x10(%ebp)
  105767:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10576a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10576d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  105771:	74 1c                	je     10578f <printnum+0x58>
  105773:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105776:	ba 00 00 00 00       	mov    $0x0,%edx
  10577b:	f7 75 e4             	divl   -0x1c(%ebp)
  10577e:	89 55 f4             	mov    %edx,-0xc(%ebp)
  105781:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105784:	ba 00 00 00 00       	mov    $0x0,%edx
  105789:	f7 75 e4             	divl   -0x1c(%ebp)
  10578c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10578f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105792:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105795:	f7 75 e4             	divl   -0x1c(%ebp)
  105798:	89 45 e0             	mov    %eax,-0x20(%ebp)
  10579b:	89 55 dc             	mov    %edx,-0x24(%ebp)
  10579e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1057a1:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1057a4:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1057a7:	89 55 ec             	mov    %edx,-0x14(%ebp)
  1057aa:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1057ad:	89 45 d8             	mov    %eax,-0x28(%ebp)

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
  1057b0:	8b 45 18             	mov    0x18(%ebp),%eax
  1057b3:	ba 00 00 00 00       	mov    $0x0,%edx
  1057b8:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  1057bb:	77 56                	ja     105813 <printnum+0xdc>
  1057bd:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  1057c0:	72 05                	jb     1057c7 <printnum+0x90>
  1057c2:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1057c5:	77 4c                	ja     105813 <printnum+0xdc>
        printnum(putch, putdat, result, base, width - 1, padc);
  1057c7:	8b 45 1c             	mov    0x1c(%ebp),%eax
  1057ca:	8d 50 ff             	lea    -0x1(%eax),%edx
  1057cd:	8b 45 20             	mov    0x20(%ebp),%eax
  1057d0:	89 44 24 18          	mov    %eax,0x18(%esp)
  1057d4:	89 54 24 14          	mov    %edx,0x14(%esp)
  1057d8:	8b 45 18             	mov    0x18(%ebp),%eax
  1057db:	89 44 24 10          	mov    %eax,0x10(%esp)
  1057df:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1057e2:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1057e5:	89 44 24 08          	mov    %eax,0x8(%esp)
  1057e9:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1057ed:	8b 45 0c             	mov    0xc(%ebp),%eax
  1057f0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1057f4:	8b 45 08             	mov    0x8(%ebp),%eax
  1057f7:	89 04 24             	mov    %eax,(%esp)
  1057fa:	e8 38 ff ff ff       	call   105737 <printnum>
  1057ff:	eb 1c                	jmp    10581d <printnum+0xe6>
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
            putch(padc, putdat);
  105801:	8b 45 0c             	mov    0xc(%ebp),%eax
  105804:	89 44 24 04          	mov    %eax,0x4(%esp)
  105808:	8b 45 20             	mov    0x20(%ebp),%eax
  10580b:	89 04 24             	mov    %eax,(%esp)
  10580e:	8b 45 08             	mov    0x8(%ebp),%eax
  105811:	ff d0                	call   *%eax
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  105813:	83 6d 1c 01          	subl   $0x1,0x1c(%ebp)
  105817:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
  10581b:	7f e4                	jg     105801 <printnum+0xca>
            putch(padc, putdat);
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  10581d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105820:	05 38 74 10 00       	add    $0x107438,%eax
  105825:	0f b6 00             	movzbl (%eax),%eax
  105828:	0f be c0             	movsbl %al,%eax
  10582b:	8b 55 0c             	mov    0xc(%ebp),%edx
  10582e:	89 54 24 04          	mov    %edx,0x4(%esp)
  105832:	89 04 24             	mov    %eax,(%esp)
  105835:	8b 45 08             	mov    0x8(%ebp),%eax
  105838:	ff d0                	call   *%eax
}
  10583a:	c9                   	leave  
  10583b:	c3                   	ret    

0010583c <getuint>:
 * getuint - get an unsigned int of various possible sizes from a varargs list
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static unsigned long long
getuint(va_list *ap, int lflag) {
  10583c:	55                   	push   %ebp
  10583d:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
  10583f:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  105843:	7e 14                	jle    105859 <getuint+0x1d>
        return va_arg(*ap, unsigned long long);
  105845:	8b 45 08             	mov    0x8(%ebp),%eax
  105848:	8b 00                	mov    (%eax),%eax
  10584a:	8d 48 08             	lea    0x8(%eax),%ecx
  10584d:	8b 55 08             	mov    0x8(%ebp),%edx
  105850:	89 0a                	mov    %ecx,(%edx)
  105852:	8b 50 04             	mov    0x4(%eax),%edx
  105855:	8b 00                	mov    (%eax),%eax
  105857:	eb 30                	jmp    105889 <getuint+0x4d>
    }
    else if (lflag) {
  105859:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  10585d:	74 16                	je     105875 <getuint+0x39>
        return va_arg(*ap, unsigned long);
  10585f:	8b 45 08             	mov    0x8(%ebp),%eax
  105862:	8b 00                	mov    (%eax),%eax
  105864:	8d 48 04             	lea    0x4(%eax),%ecx
  105867:	8b 55 08             	mov    0x8(%ebp),%edx
  10586a:	89 0a                	mov    %ecx,(%edx)
  10586c:	8b 00                	mov    (%eax),%eax
  10586e:	ba 00 00 00 00       	mov    $0x0,%edx
  105873:	eb 14                	jmp    105889 <getuint+0x4d>
    }
    else {
        return va_arg(*ap, unsigned int);
  105875:	8b 45 08             	mov    0x8(%ebp),%eax
  105878:	8b 00                	mov    (%eax),%eax
  10587a:	8d 48 04             	lea    0x4(%eax),%ecx
  10587d:	8b 55 08             	mov    0x8(%ebp),%edx
  105880:	89 0a                	mov    %ecx,(%edx)
  105882:	8b 00                	mov    (%eax),%eax
  105884:	ba 00 00 00 00       	mov    $0x0,%edx
    }
}
  105889:	5d                   	pop    %ebp
  10588a:	c3                   	ret    

0010588b <getint>:
 * getint - same as getuint but signed, we can't use getuint because of sign extension
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static long long
getint(va_list *ap, int lflag) {
  10588b:	55                   	push   %ebp
  10588c:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
  10588e:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  105892:	7e 14                	jle    1058a8 <getint+0x1d>
        return va_arg(*ap, long long);
  105894:	8b 45 08             	mov    0x8(%ebp),%eax
  105897:	8b 00                	mov    (%eax),%eax
  105899:	8d 48 08             	lea    0x8(%eax),%ecx
  10589c:	8b 55 08             	mov    0x8(%ebp),%edx
  10589f:	89 0a                	mov    %ecx,(%edx)
  1058a1:	8b 50 04             	mov    0x4(%eax),%edx
  1058a4:	8b 00                	mov    (%eax),%eax
  1058a6:	eb 28                	jmp    1058d0 <getint+0x45>
    }
    else if (lflag) {
  1058a8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  1058ac:	74 12                	je     1058c0 <getint+0x35>
        return va_arg(*ap, long);
  1058ae:	8b 45 08             	mov    0x8(%ebp),%eax
  1058b1:	8b 00                	mov    (%eax),%eax
  1058b3:	8d 48 04             	lea    0x4(%eax),%ecx
  1058b6:	8b 55 08             	mov    0x8(%ebp),%edx
  1058b9:	89 0a                	mov    %ecx,(%edx)
  1058bb:	8b 00                	mov    (%eax),%eax
  1058bd:	99                   	cltd   
  1058be:	eb 10                	jmp    1058d0 <getint+0x45>
    }
    else {
        return va_arg(*ap, int);
  1058c0:	8b 45 08             	mov    0x8(%ebp),%eax
  1058c3:	8b 00                	mov    (%eax),%eax
  1058c5:	8d 48 04             	lea    0x4(%eax),%ecx
  1058c8:	8b 55 08             	mov    0x8(%ebp),%edx
  1058cb:	89 0a                	mov    %ecx,(%edx)
  1058cd:	8b 00                	mov    (%eax),%eax
  1058cf:	99                   	cltd   
    }
}
  1058d0:	5d                   	pop    %ebp
  1058d1:	c3                   	ret    

001058d2 <printfmt>:
 * @putch:      specified putch function, print a single character
 * @putdat:     used by @putch function
 * @fmt:        the format string to use
 * */
void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  1058d2:	55                   	push   %ebp
  1058d3:	89 e5                	mov    %esp,%ebp
  1058d5:	83 ec 28             	sub    $0x28,%esp
    va_list ap;

    va_start(ap, fmt);
  1058d8:	8d 45 14             	lea    0x14(%ebp),%eax
  1058db:	89 45 f4             	mov    %eax,-0xc(%ebp)
    vprintfmt(putch, putdat, fmt, ap);
  1058de:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1058e1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1058e5:	8b 45 10             	mov    0x10(%ebp),%eax
  1058e8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1058ec:	8b 45 0c             	mov    0xc(%ebp),%eax
  1058ef:	89 44 24 04          	mov    %eax,0x4(%esp)
  1058f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1058f6:	89 04 24             	mov    %eax,(%esp)
  1058f9:	e8 02 00 00 00       	call   105900 <vprintfmt>
    va_end(ap);
}
  1058fe:	c9                   	leave  
  1058ff:	c3                   	ret    

00105900 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  105900:	55                   	push   %ebp
  105901:	89 e5                	mov    %esp,%ebp
  105903:	56                   	push   %esi
  105904:	53                   	push   %ebx
  105905:	83 ec 40             	sub    $0x40,%esp
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  105908:	eb 18                	jmp    105922 <vprintfmt+0x22>
            if (ch == '\0') {
  10590a:	85 db                	test   %ebx,%ebx
  10590c:	75 05                	jne    105913 <vprintfmt+0x13>
                return;
  10590e:	e9 d1 03 00 00       	jmp    105ce4 <vprintfmt+0x3e4>
            }
            putch(ch, putdat);
  105913:	8b 45 0c             	mov    0xc(%ebp),%eax
  105916:	89 44 24 04          	mov    %eax,0x4(%esp)
  10591a:	89 1c 24             	mov    %ebx,(%esp)
  10591d:	8b 45 08             	mov    0x8(%ebp),%eax
  105920:	ff d0                	call   *%eax
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  105922:	8b 45 10             	mov    0x10(%ebp),%eax
  105925:	8d 50 01             	lea    0x1(%eax),%edx
  105928:	89 55 10             	mov    %edx,0x10(%ebp)
  10592b:	0f b6 00             	movzbl (%eax),%eax
  10592e:	0f b6 d8             	movzbl %al,%ebx
  105931:	83 fb 25             	cmp    $0x25,%ebx
  105934:	75 d4                	jne    10590a <vprintfmt+0xa>
            }
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
  105936:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
        width = precision = -1;
  10593a:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  105941:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105944:	89 45 e8             	mov    %eax,-0x18(%ebp)
        lflag = altflag = 0;
  105947:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  10594e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105951:	89 45 e0             	mov    %eax,-0x20(%ebp)

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
  105954:	8b 45 10             	mov    0x10(%ebp),%eax
  105957:	8d 50 01             	lea    0x1(%eax),%edx
  10595a:	89 55 10             	mov    %edx,0x10(%ebp)
  10595d:	0f b6 00             	movzbl (%eax),%eax
  105960:	0f b6 d8             	movzbl %al,%ebx
  105963:	8d 43 dd             	lea    -0x23(%ebx),%eax
  105966:	83 f8 55             	cmp    $0x55,%eax
  105969:	0f 87 44 03 00 00    	ja     105cb3 <vprintfmt+0x3b3>
  10596f:	8b 04 85 5c 74 10 00 	mov    0x10745c(,%eax,4),%eax
  105976:	ff e0                	jmp    *%eax

        // flag to pad on the right
        case '-':
            padc = '-';
  105978:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
            goto reswitch;
  10597c:	eb d6                	jmp    105954 <vprintfmt+0x54>

        // flag to pad with 0's instead of spaces
        case '0':
            padc = '0';
  10597e:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
            goto reswitch;
  105982:	eb d0                	jmp    105954 <vprintfmt+0x54>

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
  105984:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
                precision = precision * 10 + ch - '0';
  10598b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10598e:	89 d0                	mov    %edx,%eax
  105990:	c1 e0 02             	shl    $0x2,%eax
  105993:	01 d0                	add    %edx,%eax
  105995:	01 c0                	add    %eax,%eax
  105997:	01 d8                	add    %ebx,%eax
  105999:	83 e8 30             	sub    $0x30,%eax
  10599c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
                ch = *fmt;
  10599f:	8b 45 10             	mov    0x10(%ebp),%eax
  1059a2:	0f b6 00             	movzbl (%eax),%eax
  1059a5:	0f be d8             	movsbl %al,%ebx
                if (ch < '0' || ch > '9') {
  1059a8:	83 fb 2f             	cmp    $0x2f,%ebx
  1059ab:	7e 0b                	jle    1059b8 <vprintfmt+0xb8>
  1059ad:	83 fb 39             	cmp    $0x39,%ebx
  1059b0:	7f 06                	jg     1059b8 <vprintfmt+0xb8>
            padc = '0';
            goto reswitch;

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
  1059b2:	83 45 10 01          	addl   $0x1,0x10(%ebp)
                precision = precision * 10 + ch - '0';
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
  1059b6:	eb d3                	jmp    10598b <vprintfmt+0x8b>
            goto process_precision;
  1059b8:	eb 33                	jmp    1059ed <vprintfmt+0xed>

        case '*':
            precision = va_arg(ap, int);
  1059ba:	8b 45 14             	mov    0x14(%ebp),%eax
  1059bd:	8d 50 04             	lea    0x4(%eax),%edx
  1059c0:	89 55 14             	mov    %edx,0x14(%ebp)
  1059c3:	8b 00                	mov    (%eax),%eax
  1059c5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            goto process_precision;
  1059c8:	eb 23                	jmp    1059ed <vprintfmt+0xed>

        case '.':
            if (width < 0)
  1059ca:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  1059ce:	79 0c                	jns    1059dc <vprintfmt+0xdc>
                width = 0;
  1059d0:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
            goto reswitch;
  1059d7:	e9 78 ff ff ff       	jmp    105954 <vprintfmt+0x54>
  1059dc:	e9 73 ff ff ff       	jmp    105954 <vprintfmt+0x54>

        case '#':
            altflag = 1;
  1059e1:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
            goto reswitch;
  1059e8:	e9 67 ff ff ff       	jmp    105954 <vprintfmt+0x54>

        process_precision:
            if (width < 0)
  1059ed:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  1059f1:	79 12                	jns    105a05 <vprintfmt+0x105>
                width = precision, precision = -1;
  1059f3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1059f6:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1059f9:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
            goto reswitch;
  105a00:	e9 4f ff ff ff       	jmp    105954 <vprintfmt+0x54>
  105a05:	e9 4a ff ff ff       	jmp    105954 <vprintfmt+0x54>

        // long flag (doubled for long long)
        case 'l':
            lflag ++;
  105a0a:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
            goto reswitch;
  105a0e:	e9 41 ff ff ff       	jmp    105954 <vprintfmt+0x54>

        // character
        case 'c':
            putch(va_arg(ap, int), putdat);
  105a13:	8b 45 14             	mov    0x14(%ebp),%eax
  105a16:	8d 50 04             	lea    0x4(%eax),%edx
  105a19:	89 55 14             	mov    %edx,0x14(%ebp)
  105a1c:	8b 00                	mov    (%eax),%eax
  105a1e:	8b 55 0c             	mov    0xc(%ebp),%edx
  105a21:	89 54 24 04          	mov    %edx,0x4(%esp)
  105a25:	89 04 24             	mov    %eax,(%esp)
  105a28:	8b 45 08             	mov    0x8(%ebp),%eax
  105a2b:	ff d0                	call   *%eax
            break;
  105a2d:	e9 ac 02 00 00       	jmp    105cde <vprintfmt+0x3de>

        // error message
        case 'e':
            err = va_arg(ap, int);
  105a32:	8b 45 14             	mov    0x14(%ebp),%eax
  105a35:	8d 50 04             	lea    0x4(%eax),%edx
  105a38:	89 55 14             	mov    %edx,0x14(%ebp)
  105a3b:	8b 18                	mov    (%eax),%ebx
            if (err < 0) {
  105a3d:	85 db                	test   %ebx,%ebx
  105a3f:	79 02                	jns    105a43 <vprintfmt+0x143>
                err = -err;
  105a41:	f7 db                	neg    %ebx
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  105a43:	83 fb 06             	cmp    $0x6,%ebx
  105a46:	7f 0b                	jg     105a53 <vprintfmt+0x153>
  105a48:	8b 34 9d 1c 74 10 00 	mov    0x10741c(,%ebx,4),%esi
  105a4f:	85 f6                	test   %esi,%esi
  105a51:	75 23                	jne    105a76 <vprintfmt+0x176>
                printfmt(putch, putdat, "error %d", err);
  105a53:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  105a57:	c7 44 24 08 49 74 10 	movl   $0x107449,0x8(%esp)
  105a5e:	00 
  105a5f:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a62:	89 44 24 04          	mov    %eax,0x4(%esp)
  105a66:	8b 45 08             	mov    0x8(%ebp),%eax
  105a69:	89 04 24             	mov    %eax,(%esp)
  105a6c:	e8 61 fe ff ff       	call   1058d2 <printfmt>
            }
            else {
                printfmt(putch, putdat, "%s", p);
            }
            break;
  105a71:	e9 68 02 00 00       	jmp    105cde <vprintfmt+0x3de>
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
                printfmt(putch, putdat, "error %d", err);
            }
            else {
                printfmt(putch, putdat, "%s", p);
  105a76:	89 74 24 0c          	mov    %esi,0xc(%esp)
  105a7a:	c7 44 24 08 52 74 10 	movl   $0x107452,0x8(%esp)
  105a81:	00 
  105a82:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a85:	89 44 24 04          	mov    %eax,0x4(%esp)
  105a89:	8b 45 08             	mov    0x8(%ebp),%eax
  105a8c:	89 04 24             	mov    %eax,(%esp)
  105a8f:	e8 3e fe ff ff       	call   1058d2 <printfmt>
            }
            break;
  105a94:	e9 45 02 00 00       	jmp    105cde <vprintfmt+0x3de>

        // string
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
  105a99:	8b 45 14             	mov    0x14(%ebp),%eax
  105a9c:	8d 50 04             	lea    0x4(%eax),%edx
  105a9f:	89 55 14             	mov    %edx,0x14(%ebp)
  105aa2:	8b 30                	mov    (%eax),%esi
  105aa4:	85 f6                	test   %esi,%esi
  105aa6:	75 05                	jne    105aad <vprintfmt+0x1ad>
                p = "(null)";
  105aa8:	be 55 74 10 00       	mov    $0x107455,%esi
            }
            if (width > 0 && padc != '-') {
  105aad:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  105ab1:	7e 3e                	jle    105af1 <vprintfmt+0x1f1>
  105ab3:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
  105ab7:	74 38                	je     105af1 <vprintfmt+0x1f1>
                for (width -= strnlen(p, precision); width > 0; width --) {
  105ab9:	8b 5d e8             	mov    -0x18(%ebp),%ebx
  105abc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105abf:	89 44 24 04          	mov    %eax,0x4(%esp)
  105ac3:	89 34 24             	mov    %esi,(%esp)
  105ac6:	e8 15 03 00 00       	call   105de0 <strnlen>
  105acb:	29 c3                	sub    %eax,%ebx
  105acd:	89 d8                	mov    %ebx,%eax
  105acf:	89 45 e8             	mov    %eax,-0x18(%ebp)
  105ad2:	eb 17                	jmp    105aeb <vprintfmt+0x1eb>
                    putch(padc, putdat);
  105ad4:	0f be 45 db          	movsbl -0x25(%ebp),%eax
  105ad8:	8b 55 0c             	mov    0xc(%ebp),%edx
  105adb:	89 54 24 04          	mov    %edx,0x4(%esp)
  105adf:	89 04 24             	mov    %eax,(%esp)
  105ae2:	8b 45 08             	mov    0x8(%ebp),%eax
  105ae5:	ff d0                	call   *%eax
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
                p = "(null)";
            }
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
  105ae7:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
  105aeb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  105aef:	7f e3                	jg     105ad4 <vprintfmt+0x1d4>
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  105af1:	eb 38                	jmp    105b2b <vprintfmt+0x22b>
                if (altflag && (ch < ' ' || ch > '~')) {
  105af3:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  105af7:	74 1f                	je     105b18 <vprintfmt+0x218>
  105af9:	83 fb 1f             	cmp    $0x1f,%ebx
  105afc:	7e 05                	jle    105b03 <vprintfmt+0x203>
  105afe:	83 fb 7e             	cmp    $0x7e,%ebx
  105b01:	7e 15                	jle    105b18 <vprintfmt+0x218>
                    putch('?', putdat);
  105b03:	8b 45 0c             	mov    0xc(%ebp),%eax
  105b06:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b0a:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  105b11:	8b 45 08             	mov    0x8(%ebp),%eax
  105b14:	ff d0                	call   *%eax
  105b16:	eb 0f                	jmp    105b27 <vprintfmt+0x227>
                }
                else {
                    putch(ch, putdat);
  105b18:	8b 45 0c             	mov    0xc(%ebp),%eax
  105b1b:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b1f:	89 1c 24             	mov    %ebx,(%esp)
  105b22:	8b 45 08             	mov    0x8(%ebp),%eax
  105b25:	ff d0                	call   *%eax
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  105b27:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
  105b2b:	89 f0                	mov    %esi,%eax
  105b2d:	8d 70 01             	lea    0x1(%eax),%esi
  105b30:	0f b6 00             	movzbl (%eax),%eax
  105b33:	0f be d8             	movsbl %al,%ebx
  105b36:	85 db                	test   %ebx,%ebx
  105b38:	74 10                	je     105b4a <vprintfmt+0x24a>
  105b3a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  105b3e:	78 b3                	js     105af3 <vprintfmt+0x1f3>
  105b40:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
  105b44:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  105b48:	79 a9                	jns    105af3 <vprintfmt+0x1f3>
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
  105b4a:	eb 17                	jmp    105b63 <vprintfmt+0x263>
                putch(' ', putdat);
  105b4c:	8b 45 0c             	mov    0xc(%ebp),%eax
  105b4f:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b53:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  105b5a:	8b 45 08             	mov    0x8(%ebp),%eax
  105b5d:	ff d0                	call   *%eax
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
  105b5f:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
  105b63:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  105b67:	7f e3                	jg     105b4c <vprintfmt+0x24c>
                putch(' ', putdat);
            }
            break;
  105b69:	e9 70 01 00 00       	jmp    105cde <vprintfmt+0x3de>

        // (signed) decimal
        case 'd':
            num = getint(&ap, lflag);
  105b6e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105b71:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b75:	8d 45 14             	lea    0x14(%ebp),%eax
  105b78:	89 04 24             	mov    %eax,(%esp)
  105b7b:	e8 0b fd ff ff       	call   10588b <getint>
  105b80:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105b83:	89 55 f4             	mov    %edx,-0xc(%ebp)
            if ((long long)num < 0) {
  105b86:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105b89:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105b8c:	85 d2                	test   %edx,%edx
  105b8e:	79 26                	jns    105bb6 <vprintfmt+0x2b6>
                putch('-', putdat);
  105b90:	8b 45 0c             	mov    0xc(%ebp),%eax
  105b93:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b97:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  105b9e:	8b 45 08             	mov    0x8(%ebp),%eax
  105ba1:	ff d0                	call   *%eax
                num = -(long long)num;
  105ba3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105ba6:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105ba9:	f7 d8                	neg    %eax
  105bab:	83 d2 00             	adc    $0x0,%edx
  105bae:	f7 da                	neg    %edx
  105bb0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105bb3:	89 55 f4             	mov    %edx,-0xc(%ebp)
            }
            base = 10;
  105bb6:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
  105bbd:	e9 a8 00 00 00       	jmp    105c6a <vprintfmt+0x36a>

        // unsigned decimal
        case 'u':
            num = getuint(&ap, lflag);
  105bc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105bc5:	89 44 24 04          	mov    %eax,0x4(%esp)
  105bc9:	8d 45 14             	lea    0x14(%ebp),%eax
  105bcc:	89 04 24             	mov    %eax,(%esp)
  105bcf:	e8 68 fc ff ff       	call   10583c <getuint>
  105bd4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105bd7:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 10;
  105bda:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
  105be1:	e9 84 00 00 00       	jmp    105c6a <vprintfmt+0x36a>

        // (unsigned) octal
        case 'o':
            num = getuint(&ap, lflag);
  105be6:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105be9:	89 44 24 04          	mov    %eax,0x4(%esp)
  105bed:	8d 45 14             	lea    0x14(%ebp),%eax
  105bf0:	89 04 24             	mov    %eax,(%esp)
  105bf3:	e8 44 fc ff ff       	call   10583c <getuint>
  105bf8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105bfb:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 8;
  105bfe:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
            goto number;
  105c05:	eb 63                	jmp    105c6a <vprintfmt+0x36a>

        // pointer
        case 'p':
            putch('0', putdat);
  105c07:	8b 45 0c             	mov    0xc(%ebp),%eax
  105c0a:	89 44 24 04          	mov    %eax,0x4(%esp)
  105c0e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  105c15:	8b 45 08             	mov    0x8(%ebp),%eax
  105c18:	ff d0                	call   *%eax
            putch('x', putdat);
  105c1a:	8b 45 0c             	mov    0xc(%ebp),%eax
  105c1d:	89 44 24 04          	mov    %eax,0x4(%esp)
  105c21:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  105c28:	8b 45 08             	mov    0x8(%ebp),%eax
  105c2b:	ff d0                	call   *%eax
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  105c2d:	8b 45 14             	mov    0x14(%ebp),%eax
  105c30:	8d 50 04             	lea    0x4(%eax),%edx
  105c33:	89 55 14             	mov    %edx,0x14(%ebp)
  105c36:	8b 00                	mov    (%eax),%eax
  105c38:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105c3b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
            base = 16;
  105c42:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
            goto number;
  105c49:	eb 1f                	jmp    105c6a <vprintfmt+0x36a>

        // (unsigned) hexadecimal
        case 'x':
            num = getuint(&ap, lflag);
  105c4b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105c4e:	89 44 24 04          	mov    %eax,0x4(%esp)
  105c52:	8d 45 14             	lea    0x14(%ebp),%eax
  105c55:	89 04 24             	mov    %eax,(%esp)
  105c58:	e8 df fb ff ff       	call   10583c <getuint>
  105c5d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105c60:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 16;
  105c63:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
        number:
            printnum(putch, putdat, num, base, width, padc);
  105c6a:	0f be 55 db          	movsbl -0x25(%ebp),%edx
  105c6e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105c71:	89 54 24 18          	mov    %edx,0x18(%esp)
  105c75:	8b 55 e8             	mov    -0x18(%ebp),%edx
  105c78:	89 54 24 14          	mov    %edx,0x14(%esp)
  105c7c:	89 44 24 10          	mov    %eax,0x10(%esp)
  105c80:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105c83:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105c86:	89 44 24 08          	mov    %eax,0x8(%esp)
  105c8a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  105c8e:	8b 45 0c             	mov    0xc(%ebp),%eax
  105c91:	89 44 24 04          	mov    %eax,0x4(%esp)
  105c95:	8b 45 08             	mov    0x8(%ebp),%eax
  105c98:	89 04 24             	mov    %eax,(%esp)
  105c9b:	e8 97 fa ff ff       	call   105737 <printnum>
            break;
  105ca0:	eb 3c                	jmp    105cde <vprintfmt+0x3de>

        // escaped '%' character
        case '%':
            putch(ch, putdat);
  105ca2:	8b 45 0c             	mov    0xc(%ebp),%eax
  105ca5:	89 44 24 04          	mov    %eax,0x4(%esp)
  105ca9:	89 1c 24             	mov    %ebx,(%esp)
  105cac:	8b 45 08             	mov    0x8(%ebp),%eax
  105caf:	ff d0                	call   *%eax
            break;
  105cb1:	eb 2b                	jmp    105cde <vprintfmt+0x3de>

        // unrecognized escape sequence - just print it literally
        default:
            putch('%', putdat);
  105cb3:	8b 45 0c             	mov    0xc(%ebp),%eax
  105cb6:	89 44 24 04          	mov    %eax,0x4(%esp)
  105cba:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  105cc1:	8b 45 08             	mov    0x8(%ebp),%eax
  105cc4:	ff d0                	call   *%eax
            for (fmt --; fmt[-1] != '%'; fmt --)
  105cc6:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  105cca:	eb 04                	jmp    105cd0 <vprintfmt+0x3d0>
  105ccc:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  105cd0:	8b 45 10             	mov    0x10(%ebp),%eax
  105cd3:	83 e8 01             	sub    $0x1,%eax
  105cd6:	0f b6 00             	movzbl (%eax),%eax
  105cd9:	3c 25                	cmp    $0x25,%al
  105cdb:	75 ef                	jne    105ccc <vprintfmt+0x3cc>
                /* do nothing */;
            break;
  105cdd:	90                   	nop
        }
    }
  105cde:	90                   	nop
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  105cdf:	e9 3e fc ff ff       	jmp    105922 <vprintfmt+0x22>
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  105ce4:	83 c4 40             	add    $0x40,%esp
  105ce7:	5b                   	pop    %ebx
  105ce8:	5e                   	pop    %esi
  105ce9:	5d                   	pop    %ebp
  105cea:	c3                   	ret    

00105ceb <sprintputch>:
 * sprintputch - 'print' a single character in a buffer
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
  105ceb:	55                   	push   %ebp
  105cec:	89 e5                	mov    %esp,%ebp
    b->cnt ++;
  105cee:	8b 45 0c             	mov    0xc(%ebp),%eax
  105cf1:	8b 40 08             	mov    0x8(%eax),%eax
  105cf4:	8d 50 01             	lea    0x1(%eax),%edx
  105cf7:	8b 45 0c             	mov    0xc(%ebp),%eax
  105cfa:	89 50 08             	mov    %edx,0x8(%eax)
    if (b->buf < b->ebuf) {
  105cfd:	8b 45 0c             	mov    0xc(%ebp),%eax
  105d00:	8b 10                	mov    (%eax),%edx
  105d02:	8b 45 0c             	mov    0xc(%ebp),%eax
  105d05:	8b 40 04             	mov    0x4(%eax),%eax
  105d08:	39 c2                	cmp    %eax,%edx
  105d0a:	73 12                	jae    105d1e <sprintputch+0x33>
        *b->buf ++ = ch;
  105d0c:	8b 45 0c             	mov    0xc(%ebp),%eax
  105d0f:	8b 00                	mov    (%eax),%eax
  105d11:	8d 48 01             	lea    0x1(%eax),%ecx
  105d14:	8b 55 0c             	mov    0xc(%ebp),%edx
  105d17:	89 0a                	mov    %ecx,(%edx)
  105d19:	8b 55 08             	mov    0x8(%ebp),%edx
  105d1c:	88 10                	mov    %dl,(%eax)
    }
}
  105d1e:	5d                   	pop    %ebp
  105d1f:	c3                   	ret    

00105d20 <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
  105d20:	55                   	push   %ebp
  105d21:	89 e5                	mov    %esp,%ebp
  105d23:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
  105d26:	8d 45 14             	lea    0x14(%ebp),%eax
  105d29:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vsnprintf(str, size, fmt, ap);
  105d2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105d2f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105d33:	8b 45 10             	mov    0x10(%ebp),%eax
  105d36:	89 44 24 08          	mov    %eax,0x8(%esp)
  105d3a:	8b 45 0c             	mov    0xc(%ebp),%eax
  105d3d:	89 44 24 04          	mov    %eax,0x4(%esp)
  105d41:	8b 45 08             	mov    0x8(%ebp),%eax
  105d44:	89 04 24             	mov    %eax,(%esp)
  105d47:	e8 08 00 00 00       	call   105d54 <vsnprintf>
  105d4c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
  105d4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  105d52:	c9                   	leave  
  105d53:	c3                   	ret    

00105d54 <vsnprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
  105d54:	55                   	push   %ebp
  105d55:	89 e5                	mov    %esp,%ebp
  105d57:	83 ec 28             	sub    $0x28,%esp
    struct sprintbuf b = {str, str + size - 1, 0};
  105d5a:	8b 45 08             	mov    0x8(%ebp),%eax
  105d5d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  105d60:	8b 45 0c             	mov    0xc(%ebp),%eax
  105d63:	8d 50 ff             	lea    -0x1(%eax),%edx
  105d66:	8b 45 08             	mov    0x8(%ebp),%eax
  105d69:	01 d0                	add    %edx,%eax
  105d6b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105d6e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if (str == NULL || b.buf > b.ebuf) {
  105d75:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  105d79:	74 0a                	je     105d85 <vsnprintf+0x31>
  105d7b:	8b 55 ec             	mov    -0x14(%ebp),%edx
  105d7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105d81:	39 c2                	cmp    %eax,%edx
  105d83:	76 07                	jbe    105d8c <vsnprintf+0x38>
        return -E_INVAL;
  105d85:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  105d8a:	eb 2a                	jmp    105db6 <vsnprintf+0x62>
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
  105d8c:	8b 45 14             	mov    0x14(%ebp),%eax
  105d8f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105d93:	8b 45 10             	mov    0x10(%ebp),%eax
  105d96:	89 44 24 08          	mov    %eax,0x8(%esp)
  105d9a:	8d 45 ec             	lea    -0x14(%ebp),%eax
  105d9d:	89 44 24 04          	mov    %eax,0x4(%esp)
  105da1:	c7 04 24 eb 5c 10 00 	movl   $0x105ceb,(%esp)
  105da8:	e8 53 fb ff ff       	call   105900 <vprintfmt>
    // null terminate the buffer
    *b.buf = '\0';
  105dad:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105db0:	c6 00 00             	movb   $0x0,(%eax)
    return b.cnt;
  105db3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  105db6:	c9                   	leave  
  105db7:	c3                   	ret    

00105db8 <strlen>:
 * @s:      the input string
 *
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
  105db8:	55                   	push   %ebp
  105db9:	89 e5                	mov    %esp,%ebp
  105dbb:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
  105dbe:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (*s ++ != '\0') {
  105dc5:	eb 04                	jmp    105dcb <strlen+0x13>
        cnt ++;
  105dc7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
  105dcb:	8b 45 08             	mov    0x8(%ebp),%eax
  105dce:	8d 50 01             	lea    0x1(%eax),%edx
  105dd1:	89 55 08             	mov    %edx,0x8(%ebp)
  105dd4:	0f b6 00             	movzbl (%eax),%eax
  105dd7:	84 c0                	test   %al,%al
  105dd9:	75 ec                	jne    105dc7 <strlen+0xf>
        cnt ++;
    }
    return cnt;
  105ddb:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  105dde:	c9                   	leave  
  105ddf:	c3                   	ret    

00105de0 <strnlen>:
 * The return value is strlen(s), if that is less than @len, or
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
  105de0:	55                   	push   %ebp
  105de1:	89 e5                	mov    %esp,%ebp
  105de3:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
  105de6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (cnt < len && *s ++ != '\0') {
  105ded:	eb 04                	jmp    105df3 <strnlen+0x13>
        cnt ++;
  105def:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
  105df3:	8b 45 fc             	mov    -0x4(%ebp),%eax
  105df6:	3b 45 0c             	cmp    0xc(%ebp),%eax
  105df9:	73 10                	jae    105e0b <strnlen+0x2b>
  105dfb:	8b 45 08             	mov    0x8(%ebp),%eax
  105dfe:	8d 50 01             	lea    0x1(%eax),%edx
  105e01:	89 55 08             	mov    %edx,0x8(%ebp)
  105e04:	0f b6 00             	movzbl (%eax),%eax
  105e07:	84 c0                	test   %al,%al
  105e09:	75 e4                	jne    105def <strnlen+0xf>
        cnt ++;
    }
    return cnt;
  105e0b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  105e0e:	c9                   	leave  
  105e0f:	c3                   	ret    

00105e10 <strcpy>:
 * To avoid overflows, the size of array pointed by @dst should be long enough to
 * contain the same string as @src (including the terminating null character), and
 * should not overlap in memory with @src.
 * */
char *
strcpy(char *dst, const char *src) {
  105e10:	55                   	push   %ebp
  105e11:	89 e5                	mov    %esp,%ebp
  105e13:	57                   	push   %edi
  105e14:	56                   	push   %esi
  105e15:	83 ec 20             	sub    $0x20,%esp
  105e18:	8b 45 08             	mov    0x8(%ebp),%eax
  105e1b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  105e1e:	8b 45 0c             	mov    0xc(%ebp),%eax
  105e21:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCPY
#define __HAVE_ARCH_STRCPY
static inline char *
__strcpy(char *dst, const char *src) {
    int d0, d1, d2;
    asm volatile (
  105e24:	8b 55 f0             	mov    -0x10(%ebp),%edx
  105e27:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105e2a:	89 d1                	mov    %edx,%ecx
  105e2c:	89 c2                	mov    %eax,%edx
  105e2e:	89 ce                	mov    %ecx,%esi
  105e30:	89 d7                	mov    %edx,%edi
  105e32:	ac                   	lods   %ds:(%esi),%al
  105e33:	aa                   	stos   %al,%es:(%edi)
  105e34:	84 c0                	test   %al,%al
  105e36:	75 fa                	jne    105e32 <strcpy+0x22>
  105e38:	89 fa                	mov    %edi,%edx
  105e3a:	89 f1                	mov    %esi,%ecx
  105e3c:	89 4d ec             	mov    %ecx,-0x14(%ebp)
  105e3f:	89 55 e8             	mov    %edx,-0x18(%ebp)
  105e42:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        "stosb;"
        "testb %%al, %%al;"
        "jne 1b;"
        : "=&S" (d0), "=&D" (d1), "=&a" (d2)
        : "0" (src), "1" (dst) : "memory");
    return dst;
  105e45:	8b 45 f4             	mov    -0xc(%ebp),%eax
    char *p = dst;
    while ((*p ++ = *src ++) != '\0')
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
  105e48:	83 c4 20             	add    $0x20,%esp
  105e4b:	5e                   	pop    %esi
  105e4c:	5f                   	pop    %edi
  105e4d:	5d                   	pop    %ebp
  105e4e:	c3                   	ret    

00105e4f <strncpy>:
 * @len:    maximum number of characters to be copied from @src
 *
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
  105e4f:	55                   	push   %ebp
  105e50:	89 e5                	mov    %esp,%ebp
  105e52:	83 ec 10             	sub    $0x10,%esp
    char *p = dst;
  105e55:	8b 45 08             	mov    0x8(%ebp),%eax
  105e58:	89 45 fc             	mov    %eax,-0x4(%ebp)
    while (len > 0) {
  105e5b:	eb 21                	jmp    105e7e <strncpy+0x2f>
        if ((*p = *src) != '\0') {
  105e5d:	8b 45 0c             	mov    0xc(%ebp),%eax
  105e60:	0f b6 10             	movzbl (%eax),%edx
  105e63:	8b 45 fc             	mov    -0x4(%ebp),%eax
  105e66:	88 10                	mov    %dl,(%eax)
  105e68:	8b 45 fc             	mov    -0x4(%ebp),%eax
  105e6b:	0f b6 00             	movzbl (%eax),%eax
  105e6e:	84 c0                	test   %al,%al
  105e70:	74 04                	je     105e76 <strncpy+0x27>
            src ++;
  105e72:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
        }
        p ++, len --;
  105e76:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  105e7a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
    char *p = dst;
    while (len > 0) {
  105e7e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105e82:	75 d9                	jne    105e5d <strncpy+0xe>
        if ((*p = *src) != '\0') {
            src ++;
        }
        p ++, len --;
    }
    return dst;
  105e84:	8b 45 08             	mov    0x8(%ebp),%eax
}
  105e87:	c9                   	leave  
  105e88:	c3                   	ret    

00105e89 <strcmp>:
 * - A value greater than zero indicates that the first character that does
 *   not match has a greater value in @s1 than in @s2;
 * - And a value less than zero indicates the opposite.
 * */
int
strcmp(const char *s1, const char *s2) {
  105e89:	55                   	push   %ebp
  105e8a:	89 e5                	mov    %esp,%ebp
  105e8c:	57                   	push   %edi
  105e8d:	56                   	push   %esi
  105e8e:	83 ec 20             	sub    $0x20,%esp
  105e91:	8b 45 08             	mov    0x8(%ebp),%eax
  105e94:	89 45 f4             	mov    %eax,-0xc(%ebp)
  105e97:	8b 45 0c             	mov    0xc(%ebp),%eax
  105e9a:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCMP
#define __HAVE_ARCH_STRCMP
static inline int
__strcmp(const char *s1, const char *s2) {
    int d0, d1, ret;
    asm volatile (
  105e9d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105ea0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105ea3:	89 d1                	mov    %edx,%ecx
  105ea5:	89 c2                	mov    %eax,%edx
  105ea7:	89 ce                	mov    %ecx,%esi
  105ea9:	89 d7                	mov    %edx,%edi
  105eab:	ac                   	lods   %ds:(%esi),%al
  105eac:	ae                   	scas   %es:(%edi),%al
  105ead:	75 08                	jne    105eb7 <strcmp+0x2e>
  105eaf:	84 c0                	test   %al,%al
  105eb1:	75 f8                	jne    105eab <strcmp+0x22>
  105eb3:	31 c0                	xor    %eax,%eax
  105eb5:	eb 04                	jmp    105ebb <strcmp+0x32>
  105eb7:	19 c0                	sbb    %eax,%eax
  105eb9:	0c 01                	or     $0x1,%al
  105ebb:	89 fa                	mov    %edi,%edx
  105ebd:	89 f1                	mov    %esi,%ecx
  105ebf:	89 45 ec             	mov    %eax,-0x14(%ebp)
  105ec2:	89 4d e8             	mov    %ecx,-0x18(%ebp)
  105ec5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
        "orb $1, %%al;"
        "3:"
        : "=a" (ret), "=&S" (d0), "=&D" (d1)
        : "1" (s1), "2" (s2)
        : "memory");
    return ret;
  105ec8:	8b 45 ec             	mov    -0x14(%ebp),%eax
    while (*s1 != '\0' && *s1 == *s2) {
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
#endif /* __HAVE_ARCH_STRCMP */
}
  105ecb:	83 c4 20             	add    $0x20,%esp
  105ece:	5e                   	pop    %esi
  105ecf:	5f                   	pop    %edi
  105ed0:	5d                   	pop    %ebp
  105ed1:	c3                   	ret    

00105ed2 <strncmp>:
 * they are equal to each other, it continues with the following pairs until
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
  105ed2:	55                   	push   %ebp
  105ed3:	89 e5                	mov    %esp,%ebp
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
  105ed5:	eb 0c                	jmp    105ee3 <strncmp+0x11>
        n --, s1 ++, s2 ++;
  105ed7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  105edb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  105edf:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
  105ee3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105ee7:	74 1a                	je     105f03 <strncmp+0x31>
  105ee9:	8b 45 08             	mov    0x8(%ebp),%eax
  105eec:	0f b6 00             	movzbl (%eax),%eax
  105eef:	84 c0                	test   %al,%al
  105ef1:	74 10                	je     105f03 <strncmp+0x31>
  105ef3:	8b 45 08             	mov    0x8(%ebp),%eax
  105ef6:	0f b6 10             	movzbl (%eax),%edx
  105ef9:	8b 45 0c             	mov    0xc(%ebp),%eax
  105efc:	0f b6 00             	movzbl (%eax),%eax
  105eff:	38 c2                	cmp    %al,%dl
  105f01:	74 d4                	je     105ed7 <strncmp+0x5>
        n --, s1 ++, s2 ++;
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
  105f03:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105f07:	74 18                	je     105f21 <strncmp+0x4f>
  105f09:	8b 45 08             	mov    0x8(%ebp),%eax
  105f0c:	0f b6 00             	movzbl (%eax),%eax
  105f0f:	0f b6 d0             	movzbl %al,%edx
  105f12:	8b 45 0c             	mov    0xc(%ebp),%eax
  105f15:	0f b6 00             	movzbl (%eax),%eax
  105f18:	0f b6 c0             	movzbl %al,%eax
  105f1b:	29 c2                	sub    %eax,%edx
  105f1d:	89 d0                	mov    %edx,%eax
  105f1f:	eb 05                	jmp    105f26 <strncmp+0x54>
  105f21:	b8 00 00 00 00       	mov    $0x0,%eax
}
  105f26:	5d                   	pop    %ebp
  105f27:	c3                   	ret    

00105f28 <strchr>:
 *
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
  105f28:	55                   	push   %ebp
  105f29:	89 e5                	mov    %esp,%ebp
  105f2b:	83 ec 04             	sub    $0x4,%esp
  105f2e:	8b 45 0c             	mov    0xc(%ebp),%eax
  105f31:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
  105f34:	eb 14                	jmp    105f4a <strchr+0x22>
        if (*s == c) {
  105f36:	8b 45 08             	mov    0x8(%ebp),%eax
  105f39:	0f b6 00             	movzbl (%eax),%eax
  105f3c:	3a 45 fc             	cmp    -0x4(%ebp),%al
  105f3f:	75 05                	jne    105f46 <strchr+0x1e>
            return (char *)s;
  105f41:	8b 45 08             	mov    0x8(%ebp),%eax
  105f44:	eb 13                	jmp    105f59 <strchr+0x31>
        }
        s ++;
  105f46:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
  105f4a:	8b 45 08             	mov    0x8(%ebp),%eax
  105f4d:	0f b6 00             	movzbl (%eax),%eax
  105f50:	84 c0                	test   %al,%al
  105f52:	75 e2                	jne    105f36 <strchr+0xe>
        if (*s == c) {
            return (char *)s;
        }
        s ++;
    }
    return NULL;
  105f54:	b8 00 00 00 00       	mov    $0x0,%eax
}
  105f59:	c9                   	leave  
  105f5a:	c3                   	ret    

00105f5b <strfind>:
 * The strfind() function is like strchr() except that if @c is
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
  105f5b:	55                   	push   %ebp
  105f5c:	89 e5                	mov    %esp,%ebp
  105f5e:	83 ec 04             	sub    $0x4,%esp
  105f61:	8b 45 0c             	mov    0xc(%ebp),%eax
  105f64:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
  105f67:	eb 11                	jmp    105f7a <strfind+0x1f>
        if (*s == c) {
  105f69:	8b 45 08             	mov    0x8(%ebp),%eax
  105f6c:	0f b6 00             	movzbl (%eax),%eax
  105f6f:	3a 45 fc             	cmp    -0x4(%ebp),%al
  105f72:	75 02                	jne    105f76 <strfind+0x1b>
            break;
  105f74:	eb 0e                	jmp    105f84 <strfind+0x29>
        }
        s ++;
  105f76:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
    while (*s != '\0') {
  105f7a:	8b 45 08             	mov    0x8(%ebp),%eax
  105f7d:	0f b6 00             	movzbl (%eax),%eax
  105f80:	84 c0                	test   %al,%al
  105f82:	75 e5                	jne    105f69 <strfind+0xe>
        if (*s == c) {
            break;
        }
        s ++;
    }
    return (char *)s;
  105f84:	8b 45 08             	mov    0x8(%ebp),%eax
}
  105f87:	c9                   	leave  
  105f88:	c3                   	ret    

00105f89 <strtol>:
 * an optional "0x" or "0X" prefix.
 *
 * The strtol() function returns the converted integral number as a long int value.
 * */
long
strtol(const char *s, char **endptr, int base) {
  105f89:	55                   	push   %ebp
  105f8a:	89 e5                	mov    %esp,%ebp
  105f8c:	83 ec 10             	sub    $0x10,%esp
    int neg = 0;
  105f8f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    long val = 0;
  105f96:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
  105f9d:	eb 04                	jmp    105fa3 <strtol+0x1a>
        s ++;
  105f9f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
strtol(const char *s, char **endptr, int base) {
    int neg = 0;
    long val = 0;

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
  105fa3:	8b 45 08             	mov    0x8(%ebp),%eax
  105fa6:	0f b6 00             	movzbl (%eax),%eax
  105fa9:	3c 20                	cmp    $0x20,%al
  105fab:	74 f2                	je     105f9f <strtol+0x16>
  105fad:	8b 45 08             	mov    0x8(%ebp),%eax
  105fb0:	0f b6 00             	movzbl (%eax),%eax
  105fb3:	3c 09                	cmp    $0x9,%al
  105fb5:	74 e8                	je     105f9f <strtol+0x16>
        s ++;
    }

    // plus/minus sign
    if (*s == '+') {
  105fb7:	8b 45 08             	mov    0x8(%ebp),%eax
  105fba:	0f b6 00             	movzbl (%eax),%eax
  105fbd:	3c 2b                	cmp    $0x2b,%al
  105fbf:	75 06                	jne    105fc7 <strtol+0x3e>
        s ++;
  105fc1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  105fc5:	eb 15                	jmp    105fdc <strtol+0x53>
    }
    else if (*s == '-') {
  105fc7:	8b 45 08             	mov    0x8(%ebp),%eax
  105fca:	0f b6 00             	movzbl (%eax),%eax
  105fcd:	3c 2d                	cmp    $0x2d,%al
  105fcf:	75 0b                	jne    105fdc <strtol+0x53>
        s ++, neg = 1;
  105fd1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  105fd5:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)
    }

    // hex or octal base prefix
    if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x')) {
  105fdc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105fe0:	74 06                	je     105fe8 <strtol+0x5f>
  105fe2:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
  105fe6:	75 24                	jne    10600c <strtol+0x83>
  105fe8:	8b 45 08             	mov    0x8(%ebp),%eax
  105feb:	0f b6 00             	movzbl (%eax),%eax
  105fee:	3c 30                	cmp    $0x30,%al
  105ff0:	75 1a                	jne    10600c <strtol+0x83>
  105ff2:	8b 45 08             	mov    0x8(%ebp),%eax
  105ff5:	83 c0 01             	add    $0x1,%eax
  105ff8:	0f b6 00             	movzbl (%eax),%eax
  105ffb:	3c 78                	cmp    $0x78,%al
  105ffd:	75 0d                	jne    10600c <strtol+0x83>
        s += 2, base = 16;
  105fff:	83 45 08 02          	addl   $0x2,0x8(%ebp)
  106003:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
  10600a:	eb 2a                	jmp    106036 <strtol+0xad>
    }
    else if (base == 0 && s[0] == '0') {
  10600c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  106010:	75 17                	jne    106029 <strtol+0xa0>
  106012:	8b 45 08             	mov    0x8(%ebp),%eax
  106015:	0f b6 00             	movzbl (%eax),%eax
  106018:	3c 30                	cmp    $0x30,%al
  10601a:	75 0d                	jne    106029 <strtol+0xa0>
        s ++, base = 8;
  10601c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  106020:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
  106027:	eb 0d                	jmp    106036 <strtol+0xad>
    }
    else if (base == 0) {
  106029:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10602d:	75 07                	jne    106036 <strtol+0xad>
        base = 10;
  10602f:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

    // digits
    while (1) {
        int dig;

        if (*s >= '0' && *s <= '9') {
  106036:	8b 45 08             	mov    0x8(%ebp),%eax
  106039:	0f b6 00             	movzbl (%eax),%eax
  10603c:	3c 2f                	cmp    $0x2f,%al
  10603e:	7e 1b                	jle    10605b <strtol+0xd2>
  106040:	8b 45 08             	mov    0x8(%ebp),%eax
  106043:	0f b6 00             	movzbl (%eax),%eax
  106046:	3c 39                	cmp    $0x39,%al
  106048:	7f 11                	jg     10605b <strtol+0xd2>
            dig = *s - '0';
  10604a:	8b 45 08             	mov    0x8(%ebp),%eax
  10604d:	0f b6 00             	movzbl (%eax),%eax
  106050:	0f be c0             	movsbl %al,%eax
  106053:	83 e8 30             	sub    $0x30,%eax
  106056:	89 45 f4             	mov    %eax,-0xc(%ebp)
  106059:	eb 48                	jmp    1060a3 <strtol+0x11a>
        }
        else if (*s >= 'a' && *s <= 'z') {
  10605b:	8b 45 08             	mov    0x8(%ebp),%eax
  10605e:	0f b6 00             	movzbl (%eax),%eax
  106061:	3c 60                	cmp    $0x60,%al
  106063:	7e 1b                	jle    106080 <strtol+0xf7>
  106065:	8b 45 08             	mov    0x8(%ebp),%eax
  106068:	0f b6 00             	movzbl (%eax),%eax
  10606b:	3c 7a                	cmp    $0x7a,%al
  10606d:	7f 11                	jg     106080 <strtol+0xf7>
            dig = *s - 'a' + 10;
  10606f:	8b 45 08             	mov    0x8(%ebp),%eax
  106072:	0f b6 00             	movzbl (%eax),%eax
  106075:	0f be c0             	movsbl %al,%eax
  106078:	83 e8 57             	sub    $0x57,%eax
  10607b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10607e:	eb 23                	jmp    1060a3 <strtol+0x11a>
        }
        else if (*s >= 'A' && *s <= 'Z') {
  106080:	8b 45 08             	mov    0x8(%ebp),%eax
  106083:	0f b6 00             	movzbl (%eax),%eax
  106086:	3c 40                	cmp    $0x40,%al
  106088:	7e 3d                	jle    1060c7 <strtol+0x13e>
  10608a:	8b 45 08             	mov    0x8(%ebp),%eax
  10608d:	0f b6 00             	movzbl (%eax),%eax
  106090:	3c 5a                	cmp    $0x5a,%al
  106092:	7f 33                	jg     1060c7 <strtol+0x13e>
            dig = *s - 'A' + 10;
  106094:	8b 45 08             	mov    0x8(%ebp),%eax
  106097:	0f b6 00             	movzbl (%eax),%eax
  10609a:	0f be c0             	movsbl %al,%eax
  10609d:	83 e8 37             	sub    $0x37,%eax
  1060a0:	89 45 f4             	mov    %eax,-0xc(%ebp)
        }
        else {
            break;
        }
        if (dig >= base) {
  1060a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1060a6:	3b 45 10             	cmp    0x10(%ebp),%eax
  1060a9:	7c 02                	jl     1060ad <strtol+0x124>
            break;
  1060ab:	eb 1a                	jmp    1060c7 <strtol+0x13e>
        }
        s ++, val = (val * base) + dig;
  1060ad:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1060b1:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1060b4:	0f af 45 10          	imul   0x10(%ebp),%eax
  1060b8:	89 c2                	mov    %eax,%edx
  1060ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1060bd:	01 d0                	add    %edx,%eax
  1060bf:	89 45 f8             	mov    %eax,-0x8(%ebp)
        // we don't properly detect overflow!
    }
  1060c2:	e9 6f ff ff ff       	jmp    106036 <strtol+0xad>

    if (endptr) {
  1060c7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  1060cb:	74 08                	je     1060d5 <strtol+0x14c>
        *endptr = (char *) s;
  1060cd:	8b 45 0c             	mov    0xc(%ebp),%eax
  1060d0:	8b 55 08             	mov    0x8(%ebp),%edx
  1060d3:	89 10                	mov    %edx,(%eax)
    }
    return (neg ? -val : val);
  1060d5:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
  1060d9:	74 07                	je     1060e2 <strtol+0x159>
  1060db:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1060de:	f7 d8                	neg    %eax
  1060e0:	eb 03                	jmp    1060e5 <strtol+0x15c>
  1060e2:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  1060e5:	c9                   	leave  
  1060e6:	c3                   	ret    

001060e7 <memset>:
 * @n:      number of bytes to be set to the value
 *
 * The memset() function returns @s.
 * */
void *
memset(void *s, char c, size_t n) {
  1060e7:	55                   	push   %ebp
  1060e8:	89 e5                	mov    %esp,%ebp
  1060ea:	57                   	push   %edi
  1060eb:	83 ec 24             	sub    $0x24,%esp
  1060ee:	8b 45 0c             	mov    0xc(%ebp),%eax
  1060f1:	88 45 d8             	mov    %al,-0x28(%ebp)
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
  1060f4:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  1060f8:	8b 55 08             	mov    0x8(%ebp),%edx
  1060fb:	89 55 f8             	mov    %edx,-0x8(%ebp)
  1060fe:	88 45 f7             	mov    %al,-0x9(%ebp)
  106101:	8b 45 10             	mov    0x10(%ebp),%eax
  106104:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_MEMSET
#define __HAVE_ARCH_MEMSET
static inline void *
__memset(void *s, char c, size_t n) {
    int d0, d1;
    asm volatile (
  106107:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  10610a:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  10610e:	8b 55 f8             	mov    -0x8(%ebp),%edx
  106111:	89 d7                	mov    %edx,%edi
  106113:	f3 aa                	rep stos %al,%es:(%edi)
  106115:	89 fa                	mov    %edi,%edx
  106117:	89 4d ec             	mov    %ecx,-0x14(%ebp)
  10611a:	89 55 e8             	mov    %edx,-0x18(%ebp)
        "rep; stosb;"
        : "=&c" (d0), "=&D" (d1)
        : "0" (n), "a" (c), "1" (s)
        : "memory");
    return s;
  10611d:	8b 45 f8             	mov    -0x8(%ebp),%eax
    while (n -- > 0) {
        *p ++ = c;
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
  106120:	83 c4 24             	add    $0x24,%esp
  106123:	5f                   	pop    %edi
  106124:	5d                   	pop    %ebp
  106125:	c3                   	ret    

00106126 <memmove>:
 * @n:      number of bytes to copy
 *
 * The memmove() function returns @dst.
 * */
void *
memmove(void *dst, const void *src, size_t n) {
  106126:	55                   	push   %ebp
  106127:	89 e5                	mov    %esp,%ebp
  106129:	57                   	push   %edi
  10612a:	56                   	push   %esi
  10612b:	53                   	push   %ebx
  10612c:	83 ec 30             	sub    $0x30,%esp
  10612f:	8b 45 08             	mov    0x8(%ebp),%eax
  106132:	89 45 f0             	mov    %eax,-0x10(%ebp)
  106135:	8b 45 0c             	mov    0xc(%ebp),%eax
  106138:	89 45 ec             	mov    %eax,-0x14(%ebp)
  10613b:	8b 45 10             	mov    0x10(%ebp),%eax
  10613e:	89 45 e8             	mov    %eax,-0x18(%ebp)

#ifndef __HAVE_ARCH_MEMMOVE
#define __HAVE_ARCH_MEMMOVE
static inline void *
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
  106141:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106144:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  106147:	73 42                	jae    10618b <memmove+0x65>
  106149:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10614c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  10614f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106152:	89 45 e0             	mov    %eax,-0x20(%ebp)
  106155:	8b 45 e8             	mov    -0x18(%ebp),%eax
  106158:	89 45 dc             	mov    %eax,-0x24(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
  10615b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10615e:	c1 e8 02             	shr    $0x2,%eax
  106161:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
  106163:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  106166:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106169:	89 d7                	mov    %edx,%edi
  10616b:	89 c6                	mov    %eax,%esi
  10616d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  10616f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  106172:	83 e1 03             	and    $0x3,%ecx
  106175:	74 02                	je     106179 <memmove+0x53>
  106177:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  106179:	89 f0                	mov    %esi,%eax
  10617b:	89 fa                	mov    %edi,%edx
  10617d:	89 4d d8             	mov    %ecx,-0x28(%ebp)
  106180:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  106183:	89 45 d0             	mov    %eax,-0x30(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
  106186:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  106189:	eb 36                	jmp    1061c1 <memmove+0x9b>
    asm volatile (
        "std;"
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
  10618b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10618e:	8d 50 ff             	lea    -0x1(%eax),%edx
  106191:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106194:	01 c2                	add    %eax,%edx
  106196:	8b 45 e8             	mov    -0x18(%ebp),%eax
  106199:	8d 48 ff             	lea    -0x1(%eax),%ecx
  10619c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10619f:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
        return __memcpy(dst, src, n);
    }
    int d0, d1, d2;
    asm volatile (
  1061a2:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1061a5:	89 c1                	mov    %eax,%ecx
  1061a7:	89 d8                	mov    %ebx,%eax
  1061a9:	89 d6                	mov    %edx,%esi
  1061ab:	89 c7                	mov    %eax,%edi
  1061ad:	fd                   	std    
  1061ae:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  1061b0:	fc                   	cld    
  1061b1:	89 f8                	mov    %edi,%eax
  1061b3:	89 f2                	mov    %esi,%edx
  1061b5:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  1061b8:	89 55 c8             	mov    %edx,-0x38(%ebp)
  1061bb:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
        : "memory");
    return dst;
  1061be:	8b 45 f0             	mov    -0x10(%ebp),%eax
            *d ++ = *s ++;
        }
    }
    return dst;
#endif /* __HAVE_ARCH_MEMMOVE */
}
  1061c1:	83 c4 30             	add    $0x30,%esp
  1061c4:	5b                   	pop    %ebx
  1061c5:	5e                   	pop    %esi
  1061c6:	5f                   	pop    %edi
  1061c7:	5d                   	pop    %ebp
  1061c8:	c3                   	ret    

001061c9 <memcpy>:
 * it always copies exactly @n bytes. To avoid overflows, the size of arrays pointed
 * by both @src and @dst, should be at least @n bytes, and should not overlap
 * (for overlapping memory area, memmove is a safer approach).
 * */
void *
memcpy(void *dst, const void *src, size_t n) {
  1061c9:	55                   	push   %ebp
  1061ca:	89 e5                	mov    %esp,%ebp
  1061cc:	57                   	push   %edi
  1061cd:	56                   	push   %esi
  1061ce:	83 ec 20             	sub    $0x20,%esp
  1061d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1061d4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1061d7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1061da:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1061dd:	8b 45 10             	mov    0x10(%ebp),%eax
  1061e0:	89 45 ec             	mov    %eax,-0x14(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
  1061e3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1061e6:	c1 e8 02             	shr    $0x2,%eax
  1061e9:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
  1061eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1061ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1061f1:	89 d7                	mov    %edx,%edi
  1061f3:	89 c6                	mov    %eax,%esi
  1061f5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  1061f7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
  1061fa:	83 e1 03             	and    $0x3,%ecx
  1061fd:	74 02                	je     106201 <memcpy+0x38>
  1061ff:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  106201:	89 f0                	mov    %esi,%eax
  106203:	89 fa                	mov    %edi,%edx
  106205:	89 4d e8             	mov    %ecx,-0x18(%ebp)
  106208:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  10620b:	89 45 e0             	mov    %eax,-0x20(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
  10620e:	8b 45 f4             	mov    -0xc(%ebp),%eax
    while (n -- > 0) {
        *d ++ = *s ++;
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
  106211:	83 c4 20             	add    $0x20,%esp
  106214:	5e                   	pop    %esi
  106215:	5f                   	pop    %edi
  106216:	5d                   	pop    %ebp
  106217:	c3                   	ret    

00106218 <memcmp>:
 *   match in both memory blocks has a greater value in @v1 than in @v2
 *   as if evaluated as unsigned char values;
 * - And a value less than zero indicates the opposite.
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
  106218:	55                   	push   %ebp
  106219:	89 e5                	mov    %esp,%ebp
  10621b:	83 ec 10             	sub    $0x10,%esp
    const char *s1 = (const char *)v1;
  10621e:	8b 45 08             	mov    0x8(%ebp),%eax
  106221:	89 45 fc             	mov    %eax,-0x4(%ebp)
    const char *s2 = (const char *)v2;
  106224:	8b 45 0c             	mov    0xc(%ebp),%eax
  106227:	89 45 f8             	mov    %eax,-0x8(%ebp)
    while (n -- > 0) {
  10622a:	eb 30                	jmp    10625c <memcmp+0x44>
        if (*s1 != *s2) {
  10622c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10622f:	0f b6 10             	movzbl (%eax),%edx
  106232:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106235:	0f b6 00             	movzbl (%eax),%eax
  106238:	38 c2                	cmp    %al,%dl
  10623a:	74 18                	je     106254 <memcmp+0x3c>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
  10623c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10623f:	0f b6 00             	movzbl (%eax),%eax
  106242:	0f b6 d0             	movzbl %al,%edx
  106245:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106248:	0f b6 00             	movzbl (%eax),%eax
  10624b:	0f b6 c0             	movzbl %al,%eax
  10624e:	29 c2                	sub    %eax,%edx
  106250:	89 d0                	mov    %edx,%eax
  106252:	eb 1a                	jmp    10626e <memcmp+0x56>
        }
        s1 ++, s2 ++;
  106254:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  106258:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
  10625c:	8b 45 10             	mov    0x10(%ebp),%eax
  10625f:	8d 50 ff             	lea    -0x1(%eax),%edx
  106262:	89 55 10             	mov    %edx,0x10(%ebp)
  106265:	85 c0                	test   %eax,%eax
  106267:	75 c3                	jne    10622c <memcmp+0x14>
        if (*s1 != *s2) {
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
    }
    return 0;
  106269:	b8 00 00 00 00       	mov    $0x0,%eax
}
  10626e:	c9                   	leave  
  10626f:	c3                   	ret    
