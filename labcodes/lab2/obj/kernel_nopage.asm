
bin/kernel_nopage:     file format elf32-i386


Disassembly of section .text:

00100000 <kern_entry>:

.text
.globl kern_entry
kern_entry:
    # load pa of boot pgdir
    movl $REALLOC(__boot_pgdir), %eax
  100000:	b8 00 b0 11 40       	mov    $0x4011b000,%eax
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
next:

    # unmap va 0 ~ 4M, it's temporary mapping
    xorl %eax, %eax
  10001e:	31 c0                	xor    %eax,%eax
    movl %eax, __boot_pgdir
  100020:	a3 00 b0 11 00       	mov    %eax,0x11b000

    # set ebp, esp
    movl $0x0, %ebp
  100025:	bd 00 00 00 00       	mov    $0x0,%ebp
    # the kernel stack region is from bootstack -- bootstacktop,
    # the kernel stack size is KSTACKSIZE (8KB)defined in memlayout.h
    movl $bootstacktop, %esp
  10002a:	bc 00 a0 11 00       	mov    $0x11a000,%esp
    # now kernel stack is ready , call the first C function
    call kern_init
  10002f:	e8 02 00 00 00       	call   100036 <kern_init>

00100034 <spin>:

# should never get here
spin:
    jmp spin
  100034:	eb fe                	jmp    100034 <spin>

00100036 <kern_init>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);
static void lab1_switch_test(void);

int
kern_init(void) {
  100036:	55                   	push   %ebp
  100037:	89 e5                	mov    %esp,%ebp
  100039:	83 ec 28             	sub    $0x28,%esp
    extern char edata[], end[]; //这俩东西在kernel.ld里
    memset(edata, 0, end - edata);
  10003c:	ba 00 58 12 00       	mov    $0x125800,%edx
  100041:	b8 36 aa 11 00       	mov    $0x11aa36,%eax
  100046:	29 c2                	sub    %eax,%edx
  100048:	89 d0                	mov    %edx,%eax
  10004a:	89 44 24 08          	mov    %eax,0x8(%esp)
  10004e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100055:	00 
  100056:	c7 04 24 36 aa 11 00 	movl   $0x11aa36,(%esp)
  10005d:	e8 05 71 00 00       	call   107167 <memset>

    cons_init();                // init the console
  100062:	e8 8e 15 00 00       	call   1015f5 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
  100067:	c7 45 f4 00 73 10 00 	movl   $0x107300,-0xc(%ebp)
    cprintf("%s\n\n", message);
  10006e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100071:	89 44 24 04          	mov    %eax,0x4(%esp)
  100075:	c7 04 24 1c 73 10 00 	movl   $0x10731c,(%esp)
  10007c:	e8 d3 02 00 00       	call   100354 <cprintf>

    print_kerninfo();
  100081:	e8 02 08 00 00       	call   100888 <print_kerninfo>

    grade_backtrace();
  100086:	e8 8b 00 00 00       	call   100116 <grade_backtrace>

    pmm_init();                 // init physical memory management
  10008b:	e8 fc 55 00 00       	call   10568c <pmm_init>

    pic_init();                 // init interrupt controller
  100090:	e8 c9 16 00 00       	call   10175e <pic_init>
    idt_init();                 // init interrupt descriptor table
  100095:	e8 1b 18 00 00       	call   1018b5 <idt_init>

    clock_init();               // init clock interrupt
  10009a:	e8 0c 0d 00 00       	call   100dab <clock_init>
    intr_enable();              // enable irq interrupt
  10009f:	e8 28 16 00 00       	call   1016cc <intr_enable>

    //LAB1: CAHLLENGE 1 If you try to do it, uncomment lab1_switch_test()
    // user/kernel mode switch test
    lab1_switch_test();
  1000a4:	e8 69 01 00 00       	call   100212 <lab1_switch_test>

    /* do nothing */
    while (1);
  1000a9:	eb fe                	jmp    1000a9 <kern_init+0x73>

001000ab <grade_backtrace2>:
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
  1000ab:	55                   	push   %ebp
  1000ac:	89 e5                	mov    %esp,%ebp
  1000ae:	83 ec 18             	sub    $0x18,%esp
    mon_backtrace(0, NULL, NULL);
  1000b1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1000b8:	00 
  1000b9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000c0:	00 
  1000c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1000c8:	e8 ff 0b 00 00       	call   100ccc <mon_backtrace>
}
  1000cd:	c9                   	leave  
  1000ce:	c3                   	ret    

001000cf <grade_backtrace1>:

void __attribute__((noinline))
grade_backtrace1(int arg0, int arg1) {
  1000cf:	55                   	push   %ebp
  1000d0:	89 e5                	mov    %esp,%ebp
  1000d2:	53                   	push   %ebx
  1000d3:	83 ec 14             	sub    $0x14,%esp
    grade_backtrace2(arg0, (int)&arg0, arg1, (int)&arg1);
  1000d6:	8d 5d 0c             	lea    0xc(%ebp),%ebx
  1000d9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  1000dc:	8d 55 08             	lea    0x8(%ebp),%edx
  1000df:	8b 45 08             	mov    0x8(%ebp),%eax
  1000e2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  1000e6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1000ea:	89 54 24 04          	mov    %edx,0x4(%esp)
  1000ee:	89 04 24             	mov    %eax,(%esp)
  1000f1:	e8 b5 ff ff ff       	call   1000ab <grade_backtrace2>
}
  1000f6:	83 c4 14             	add    $0x14,%esp
  1000f9:	5b                   	pop    %ebx
  1000fa:	5d                   	pop    %ebp
  1000fb:	c3                   	ret    

001000fc <grade_backtrace0>:

void __attribute__((noinline))
grade_backtrace0(int arg0, int arg1, int arg2) {
  1000fc:	55                   	push   %ebp
  1000fd:	89 e5                	mov    %esp,%ebp
  1000ff:	83 ec 18             	sub    $0x18,%esp
    grade_backtrace1(arg0, arg2);
  100102:	8b 45 10             	mov    0x10(%ebp),%eax
  100105:	89 44 24 04          	mov    %eax,0x4(%esp)
  100109:	8b 45 08             	mov    0x8(%ebp),%eax
  10010c:	89 04 24             	mov    %eax,(%esp)
  10010f:	e8 bb ff ff ff       	call   1000cf <grade_backtrace1>
}
  100114:	c9                   	leave  
  100115:	c3                   	ret    

00100116 <grade_backtrace>:

void
grade_backtrace(void) {
  100116:	55                   	push   %ebp
  100117:	89 e5                	mov    %esp,%ebp
  100119:	83 ec 18             	sub    $0x18,%esp
    grade_backtrace0(0, (int)kern_init, 0xffff0000);
  10011c:	b8 36 00 10 00       	mov    $0x100036,%eax
  100121:	c7 44 24 08 00 00 ff 	movl   $0xffff0000,0x8(%esp)
  100128:	ff 
  100129:	89 44 24 04          	mov    %eax,0x4(%esp)
  10012d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  100134:	e8 c3 ff ff ff       	call   1000fc <grade_backtrace0>
}
  100139:	c9                   	leave  
  10013a:	c3                   	ret    

0010013b <lab1_print_cur_status>:

static void
lab1_print_cur_status(void) {
  10013b:	55                   	push   %ebp
  10013c:	89 e5                	mov    %esp,%ebp
  10013e:	83 ec 28             	sub    $0x28,%esp
    static int round = 0;
    uint16_t reg1, reg2, reg3, reg4;
    asm volatile (
  100141:	8c 4d f6             	mov    %cs,-0xa(%ebp)
  100144:	8c 5d f4             	mov    %ds,-0xc(%ebp)
  100147:	8c 45 f2             	mov    %es,-0xe(%ebp)
  10014a:	8c 55 f0             	mov    %ss,-0x10(%ebp)
            "mov %%cs, %0;"
            "mov %%ds, %1;"
            "mov %%es, %2;"
            "mov %%ss, %3;"
            : "=m"(reg1), "=m"(reg2), "=m"(reg3), "=m"(reg4));
    cprintf("%d: @ring %d\n", round, reg1 & 3);
  10014d:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  100151:	0f b7 c0             	movzwl %ax,%eax
  100154:	83 e0 03             	and    $0x3,%eax
  100157:	89 c2                	mov    %eax,%edx
  100159:	a1 00 d0 11 00       	mov    0x11d000,%eax
  10015e:	89 54 24 08          	mov    %edx,0x8(%esp)
  100162:	89 44 24 04          	mov    %eax,0x4(%esp)
  100166:	c7 04 24 21 73 10 00 	movl   $0x107321,(%esp)
  10016d:	e8 e2 01 00 00       	call   100354 <cprintf>
    cprintf("%d:  cs = %x\n", round, reg1);
  100172:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  100176:	0f b7 d0             	movzwl %ax,%edx
  100179:	a1 00 d0 11 00       	mov    0x11d000,%eax
  10017e:	89 54 24 08          	mov    %edx,0x8(%esp)
  100182:	89 44 24 04          	mov    %eax,0x4(%esp)
  100186:	c7 04 24 2f 73 10 00 	movl   $0x10732f,(%esp)
  10018d:	e8 c2 01 00 00       	call   100354 <cprintf>
    cprintf("%d:  ds = %x\n", round, reg2);
  100192:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
  100196:	0f b7 d0             	movzwl %ax,%edx
  100199:	a1 00 d0 11 00       	mov    0x11d000,%eax
  10019e:	89 54 24 08          	mov    %edx,0x8(%esp)
  1001a2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1001a6:	c7 04 24 3d 73 10 00 	movl   $0x10733d,(%esp)
  1001ad:	e8 a2 01 00 00       	call   100354 <cprintf>
    cprintf("%d:  es = %x\n", round, reg3);
  1001b2:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
  1001b6:	0f b7 d0             	movzwl %ax,%edx
  1001b9:	a1 00 d0 11 00       	mov    0x11d000,%eax
  1001be:	89 54 24 08          	mov    %edx,0x8(%esp)
  1001c2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1001c6:	c7 04 24 4b 73 10 00 	movl   $0x10734b,(%esp)
  1001cd:	e8 82 01 00 00       	call   100354 <cprintf>
    cprintf("%d:  ss = %x\n", round, reg4);
  1001d2:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
  1001d6:	0f b7 d0             	movzwl %ax,%edx
  1001d9:	a1 00 d0 11 00       	mov    0x11d000,%eax
  1001de:	89 54 24 08          	mov    %edx,0x8(%esp)
  1001e2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1001e6:	c7 04 24 59 73 10 00 	movl   $0x107359,(%esp)
  1001ed:	e8 62 01 00 00       	call   100354 <cprintf>
    round ++;
  1001f2:	a1 00 d0 11 00       	mov    0x11d000,%eax
  1001f7:	83 c0 01             	add    $0x1,%eax
  1001fa:	a3 00 d0 11 00       	mov    %eax,0x11d000
}
  1001ff:	c9                   	leave  
  100200:	c3                   	ret    

00100201 <lab1_switch_to_user>:

static void
lab1_switch_to_user(void) {
  100201:	55                   	push   %ebp
  100202:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 : TODO
    asm volatile (
  100204:	16                   	push   %ss
  100205:	54                   	push   %esp
  100206:	cd 78                	int    $0x78
            "pushl %%ss\n\t"
            "pushl %%esp\n\t"
            "int %0\n\t"
            ::"i" (T_SWITCH_TOU));
}
  100208:	5d                   	pop    %ebp
  100209:	c3                   	ret    

0010020a <lab1_switch_to_kernel>:

static void
lab1_switch_to_kernel(void) {
  10020a:	55                   	push   %ebp
  10020b:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 :  TODO
    asm volatile (
  10020d:	cd 79                	int    $0x79
  10020f:	5c                   	pop    %esp
        "int %0\n\t"
        "popl %%esp\n\t"
        ::"i" (T_SWITCH_TOK));
}
  100210:	5d                   	pop    %ebp
  100211:	c3                   	ret    

00100212 <lab1_switch_test>:

static void
lab1_switch_test(void) {
  100212:	55                   	push   %ebp
  100213:	89 e5                	mov    %esp,%ebp
  100215:	83 ec 18             	sub    $0x18,%esp
    lab1_print_cur_status();
  100218:	e8 1e ff ff ff       	call   10013b <lab1_print_cur_status>
    cprintf("+++ switch to  user  mode +++\n");
  10021d:	c7 04 24 68 73 10 00 	movl   $0x107368,(%esp)
  100224:	e8 2b 01 00 00       	call   100354 <cprintf>
    lab1_switch_to_user();
  100229:	e8 d3 ff ff ff       	call   100201 <lab1_switch_to_user>
    lab1_print_cur_status();
  10022e:	e8 08 ff ff ff       	call   10013b <lab1_print_cur_status>
    cprintf("+++ switch to kernel mode +++\n");
  100233:	c7 04 24 88 73 10 00 	movl   $0x107388,(%esp)
  10023a:	e8 15 01 00 00       	call   100354 <cprintf>
    lab1_switch_to_kernel();
  10023f:	e8 c6 ff ff ff       	call   10020a <lab1_switch_to_kernel>
    lab1_print_cur_status();
  100244:	e8 f2 fe ff ff       	call   10013b <lab1_print_cur_status>
}
  100249:	c9                   	leave  
  10024a:	c3                   	ret    

0010024b <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
  10024b:	55                   	push   %ebp
  10024c:	89 e5                	mov    %esp,%ebp
  10024e:	83 ec 28             	sub    $0x28,%esp
    if (prompt != NULL) {
  100251:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  100255:	74 13                	je     10026a <readline+0x1f>
        cprintf("%s", prompt);
  100257:	8b 45 08             	mov    0x8(%ebp),%eax
  10025a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10025e:	c7 04 24 a7 73 10 00 	movl   $0x1073a7,(%esp)
  100265:	e8 ea 00 00 00       	call   100354 <cprintf>
    }
    int i = 0, c;
  10026a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        c = getchar();
  100271:	e8 66 01 00 00       	call   1003dc <getchar>
  100276:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (c < 0) {
  100279:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  10027d:	79 07                	jns    100286 <readline+0x3b>
            return NULL;
  10027f:	b8 00 00 00 00       	mov    $0x0,%eax
  100284:	eb 79                	jmp    1002ff <readline+0xb4>
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
  100286:	83 7d f0 1f          	cmpl   $0x1f,-0x10(%ebp)
  10028a:	7e 28                	jle    1002b4 <readline+0x69>
  10028c:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
  100293:	7f 1f                	jg     1002b4 <readline+0x69>
            cputchar(c);
  100295:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100298:	89 04 24             	mov    %eax,(%esp)
  10029b:	e8 da 00 00 00       	call   10037a <cputchar>
            buf[i ++] = c;
  1002a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1002a3:	8d 50 01             	lea    0x1(%eax),%edx
  1002a6:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1002a9:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1002ac:	88 90 20 d0 11 00    	mov    %dl,0x11d020(%eax)
  1002b2:	eb 46                	jmp    1002fa <readline+0xaf>
        }
        else if (c == '\b' && i > 0) {
  1002b4:	83 7d f0 08          	cmpl   $0x8,-0x10(%ebp)
  1002b8:	75 17                	jne    1002d1 <readline+0x86>
  1002ba:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1002be:	7e 11                	jle    1002d1 <readline+0x86>
            cputchar(c);
  1002c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1002c3:	89 04 24             	mov    %eax,(%esp)
  1002c6:	e8 af 00 00 00       	call   10037a <cputchar>
            i --;
  1002cb:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
  1002cf:	eb 29                	jmp    1002fa <readline+0xaf>
        }
        else if (c == '\n' || c == '\r') {
  1002d1:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
  1002d5:	74 06                	je     1002dd <readline+0x92>
  1002d7:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
  1002db:	75 1d                	jne    1002fa <readline+0xaf>
            cputchar(c);
  1002dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1002e0:	89 04 24             	mov    %eax,(%esp)
  1002e3:	e8 92 00 00 00       	call   10037a <cputchar>
            buf[i] = '\0';
  1002e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1002eb:	05 20 d0 11 00       	add    $0x11d020,%eax
  1002f0:	c6 00 00             	movb   $0x0,(%eax)
            return buf;
  1002f3:	b8 20 d0 11 00       	mov    $0x11d020,%eax
  1002f8:	eb 05                	jmp    1002ff <readline+0xb4>
        }
    }
  1002fa:	e9 72 ff ff ff       	jmp    100271 <readline+0x26>
}
  1002ff:	c9                   	leave  
  100300:	c3                   	ret    

00100301 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  100301:	55                   	push   %ebp
  100302:	89 e5                	mov    %esp,%ebp
  100304:	83 ec 18             	sub    $0x18,%esp
    cons_putc(c);
  100307:	8b 45 08             	mov    0x8(%ebp),%eax
  10030a:	89 04 24             	mov    %eax,(%esp)
  10030d:	e8 0f 13 00 00       	call   101621 <cons_putc>
    (*cnt) ++;
  100312:	8b 45 0c             	mov    0xc(%ebp),%eax
  100315:	8b 00                	mov    (%eax),%eax
  100317:	8d 50 01             	lea    0x1(%eax),%edx
  10031a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10031d:	89 10                	mov    %edx,(%eax)
}
  10031f:	c9                   	leave  
  100320:	c3                   	ret    

00100321 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
  100321:	55                   	push   %ebp
  100322:	89 e5                	mov    %esp,%ebp
  100324:	83 ec 28             	sub    $0x28,%esp
    int cnt = 0;
  100327:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  10032e:	8b 45 0c             	mov    0xc(%ebp),%eax
  100331:	89 44 24 0c          	mov    %eax,0xc(%esp)
  100335:	8b 45 08             	mov    0x8(%ebp),%eax
  100338:	89 44 24 08          	mov    %eax,0x8(%esp)
  10033c:	8d 45 f4             	lea    -0xc(%ebp),%eax
  10033f:	89 44 24 04          	mov    %eax,0x4(%esp)
  100343:	c7 04 24 01 03 10 00 	movl   $0x100301,(%esp)
  10034a:	e8 31 66 00 00       	call   106980 <vprintfmt>
    return cnt;
  10034f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100352:	c9                   	leave  
  100353:	c3                   	ret    

00100354 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  100354:	55                   	push   %ebp
  100355:	89 e5                	mov    %esp,%ebp
  100357:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
  10035a:	8d 45 0c             	lea    0xc(%ebp),%eax
  10035d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vcprintf(fmt, ap);
  100360:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100363:	89 44 24 04          	mov    %eax,0x4(%esp)
  100367:	8b 45 08             	mov    0x8(%ebp),%eax
  10036a:	89 04 24             	mov    %eax,(%esp)
  10036d:	e8 af ff ff ff       	call   100321 <vcprintf>
  100372:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
  100375:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100378:	c9                   	leave  
  100379:	c3                   	ret    

0010037a <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
  10037a:	55                   	push   %ebp
  10037b:	89 e5                	mov    %esp,%ebp
  10037d:	83 ec 18             	sub    $0x18,%esp
    cons_putc(c);
  100380:	8b 45 08             	mov    0x8(%ebp),%eax
  100383:	89 04 24             	mov    %eax,(%esp)
  100386:	e8 96 12 00 00       	call   101621 <cons_putc>
}
  10038b:	c9                   	leave  
  10038c:	c3                   	ret    

0010038d <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
  10038d:	55                   	push   %ebp
  10038e:	89 e5                	mov    %esp,%ebp
  100390:	83 ec 28             	sub    $0x28,%esp
    int cnt = 0;
  100393:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    char c;
    while ((c = *str ++) != '\0') {
  10039a:	eb 13                	jmp    1003af <cputs+0x22>
        cputch(c, &cnt);
  10039c:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  1003a0:	8d 55 f0             	lea    -0x10(%ebp),%edx
  1003a3:	89 54 24 04          	mov    %edx,0x4(%esp)
  1003a7:	89 04 24             	mov    %eax,(%esp)
  1003aa:	e8 52 ff ff ff       	call   100301 <cputch>
 * */
int
cputs(const char *str) {
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
  1003af:	8b 45 08             	mov    0x8(%ebp),%eax
  1003b2:	8d 50 01             	lea    0x1(%eax),%edx
  1003b5:	89 55 08             	mov    %edx,0x8(%ebp)
  1003b8:	0f b6 00             	movzbl (%eax),%eax
  1003bb:	88 45 f7             	mov    %al,-0x9(%ebp)
  1003be:	80 7d f7 00          	cmpb   $0x0,-0x9(%ebp)
  1003c2:	75 d8                	jne    10039c <cputs+0xf>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
  1003c4:	8d 45 f0             	lea    -0x10(%ebp),%eax
  1003c7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1003cb:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
  1003d2:	e8 2a ff ff ff       	call   100301 <cputch>
    return cnt;
  1003d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1003da:	c9                   	leave  
  1003db:	c3                   	ret    

001003dc <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
  1003dc:	55                   	push   %ebp
  1003dd:	89 e5                	mov    %esp,%ebp
  1003df:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = cons_getc()) == 0)
  1003e2:	e8 76 12 00 00       	call   10165d <cons_getc>
  1003e7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1003ea:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1003ee:	74 f2                	je     1003e2 <getchar+0x6>
        /* do nothing */;
    return c;
  1003f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1003f3:	c9                   	leave  
  1003f4:	c3                   	ret    

001003f5 <stab_binsearch>:
 *      stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
 * will exit setting left = 118, right = 554.
 * */
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
  1003f5:	55                   	push   %ebp
  1003f6:	89 e5                	mov    %esp,%ebp
  1003f8:	83 ec 20             	sub    $0x20,%esp
    int l = *region_left, r = *region_right, any_matches = 0;
  1003fb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1003fe:	8b 00                	mov    (%eax),%eax
  100400:	89 45 fc             	mov    %eax,-0x4(%ebp)
  100403:	8b 45 10             	mov    0x10(%ebp),%eax
  100406:	8b 00                	mov    (%eax),%eax
  100408:	89 45 f8             	mov    %eax,-0x8(%ebp)
  10040b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

    while (l <= r) {
  100412:	e9 d2 00 00 00       	jmp    1004e9 <stab_binsearch+0xf4>
        int true_m = (l + r) / 2, m = true_m;
  100417:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10041a:	8b 55 fc             	mov    -0x4(%ebp),%edx
  10041d:	01 d0                	add    %edx,%eax
  10041f:	89 c2                	mov    %eax,%edx
  100421:	c1 ea 1f             	shr    $0x1f,%edx
  100424:	01 d0                	add    %edx,%eax
  100426:	d1 f8                	sar    %eax
  100428:	89 45 ec             	mov    %eax,-0x14(%ebp)
  10042b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10042e:	89 45 f0             	mov    %eax,-0x10(%ebp)

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
  100431:	eb 04                	jmp    100437 <stab_binsearch+0x42>
            m --;
  100433:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)

    while (l <= r) {
        int true_m = (l + r) / 2, m = true_m;

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
  100437:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10043a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  10043d:	7c 1f                	jl     10045e <stab_binsearch+0x69>
  10043f:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100442:	89 d0                	mov    %edx,%eax
  100444:	01 c0                	add    %eax,%eax
  100446:	01 d0                	add    %edx,%eax
  100448:	c1 e0 02             	shl    $0x2,%eax
  10044b:	89 c2                	mov    %eax,%edx
  10044d:	8b 45 08             	mov    0x8(%ebp),%eax
  100450:	01 d0                	add    %edx,%eax
  100452:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  100456:	0f b6 c0             	movzbl %al,%eax
  100459:	3b 45 14             	cmp    0x14(%ebp),%eax
  10045c:	75 d5                	jne    100433 <stab_binsearch+0x3e>
            m --;
        }
        if (m < l) {    // no match in [l, m]
  10045e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100461:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  100464:	7d 0b                	jge    100471 <stab_binsearch+0x7c>
            l = true_m + 1;
  100466:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100469:	83 c0 01             	add    $0x1,%eax
  10046c:	89 45 fc             	mov    %eax,-0x4(%ebp)
            continue;
  10046f:	eb 78                	jmp    1004e9 <stab_binsearch+0xf4>
        }

        // actual binary search
        any_matches = 1;
  100471:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
        if (stabs[m].n_value < addr) {
  100478:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10047b:	89 d0                	mov    %edx,%eax
  10047d:	01 c0                	add    %eax,%eax
  10047f:	01 d0                	add    %edx,%eax
  100481:	c1 e0 02             	shl    $0x2,%eax
  100484:	89 c2                	mov    %eax,%edx
  100486:	8b 45 08             	mov    0x8(%ebp),%eax
  100489:	01 d0                	add    %edx,%eax
  10048b:	8b 40 08             	mov    0x8(%eax),%eax
  10048e:	3b 45 18             	cmp    0x18(%ebp),%eax
  100491:	73 13                	jae    1004a6 <stab_binsearch+0xb1>
            *region_left = m;
  100493:	8b 45 0c             	mov    0xc(%ebp),%eax
  100496:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100499:	89 10                	mov    %edx,(%eax)
            l = true_m + 1;
  10049b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10049e:	83 c0 01             	add    $0x1,%eax
  1004a1:	89 45 fc             	mov    %eax,-0x4(%ebp)
  1004a4:	eb 43                	jmp    1004e9 <stab_binsearch+0xf4>
        } else if (stabs[m].n_value > addr) {
  1004a6:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1004a9:	89 d0                	mov    %edx,%eax
  1004ab:	01 c0                	add    %eax,%eax
  1004ad:	01 d0                	add    %edx,%eax
  1004af:	c1 e0 02             	shl    $0x2,%eax
  1004b2:	89 c2                	mov    %eax,%edx
  1004b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1004b7:	01 d0                	add    %edx,%eax
  1004b9:	8b 40 08             	mov    0x8(%eax),%eax
  1004bc:	3b 45 18             	cmp    0x18(%ebp),%eax
  1004bf:	76 16                	jbe    1004d7 <stab_binsearch+0xe2>
            *region_right = m - 1;
  1004c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1004c4:	8d 50 ff             	lea    -0x1(%eax),%edx
  1004c7:	8b 45 10             	mov    0x10(%ebp),%eax
  1004ca:	89 10                	mov    %edx,(%eax)
            r = m - 1;
  1004cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1004cf:	83 e8 01             	sub    $0x1,%eax
  1004d2:	89 45 f8             	mov    %eax,-0x8(%ebp)
  1004d5:	eb 12                	jmp    1004e9 <stab_binsearch+0xf4>
        } else {
            // exact match for 'addr', but continue loop to find
            // *region_right
            *region_left = m;
  1004d7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004da:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1004dd:	89 10                	mov    %edx,(%eax)
            l = m;
  1004df:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1004e2:	89 45 fc             	mov    %eax,-0x4(%ebp)
            addr ++;
  1004e5:	83 45 18 01          	addl   $0x1,0x18(%ebp)
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
    int l = *region_left, r = *region_right, any_matches = 0;

    while (l <= r) {
  1004e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1004ec:	3b 45 f8             	cmp    -0x8(%ebp),%eax
  1004ef:	0f 8e 22 ff ff ff    	jle    100417 <stab_binsearch+0x22>
            l = m;
            addr ++;
        }
    }

    if (!any_matches) {
  1004f5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1004f9:	75 0f                	jne    10050a <stab_binsearch+0x115>
        *region_right = *region_left - 1;
  1004fb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004fe:	8b 00                	mov    (%eax),%eax
  100500:	8d 50 ff             	lea    -0x1(%eax),%edx
  100503:	8b 45 10             	mov    0x10(%ebp),%eax
  100506:	89 10                	mov    %edx,(%eax)
  100508:	eb 3f                	jmp    100549 <stab_binsearch+0x154>
    }
    else {
        // find rightmost region containing 'addr'
        l = *region_right;
  10050a:	8b 45 10             	mov    0x10(%ebp),%eax
  10050d:	8b 00                	mov    (%eax),%eax
  10050f:	89 45 fc             	mov    %eax,-0x4(%ebp)
        for (; l > *region_left && stabs[l].n_type != type; l --)
  100512:	eb 04                	jmp    100518 <stab_binsearch+0x123>
  100514:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
  100518:	8b 45 0c             	mov    0xc(%ebp),%eax
  10051b:	8b 00                	mov    (%eax),%eax
  10051d:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  100520:	7d 1f                	jge    100541 <stab_binsearch+0x14c>
  100522:	8b 55 fc             	mov    -0x4(%ebp),%edx
  100525:	89 d0                	mov    %edx,%eax
  100527:	01 c0                	add    %eax,%eax
  100529:	01 d0                	add    %edx,%eax
  10052b:	c1 e0 02             	shl    $0x2,%eax
  10052e:	89 c2                	mov    %eax,%edx
  100530:	8b 45 08             	mov    0x8(%ebp),%eax
  100533:	01 d0                	add    %edx,%eax
  100535:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  100539:	0f b6 c0             	movzbl %al,%eax
  10053c:	3b 45 14             	cmp    0x14(%ebp),%eax
  10053f:	75 d3                	jne    100514 <stab_binsearch+0x11f>
            /* do nothing */;
        *region_left = l;
  100541:	8b 45 0c             	mov    0xc(%ebp),%eax
  100544:	8b 55 fc             	mov    -0x4(%ebp),%edx
  100547:	89 10                	mov    %edx,(%eax)
    }
}
  100549:	c9                   	leave  
  10054a:	c3                   	ret    

0010054b <debuginfo_eip>:
 * the specified instruction address, @addr.  Returns 0 if information
 * was found, and negative if not.  But even if it returns negative it
 * has stored some information into '*info'.
 * */
int
debuginfo_eip(uintptr_t addr, struct eipdebuginfo *info) {
  10054b:	55                   	push   %ebp
  10054c:	89 e5                	mov    %esp,%ebp
  10054e:	83 ec 58             	sub    $0x58,%esp
    const struct stab *stabs, *stab_end;
    const char *stabstr, *stabstr_end;

    info->eip_file = "<unknown>";
  100551:	8b 45 0c             	mov    0xc(%ebp),%eax
  100554:	c7 00 ac 73 10 00    	movl   $0x1073ac,(%eax)
    info->eip_line = 0;
  10055a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10055d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
    info->eip_fn_name = "<unknown>";
  100564:	8b 45 0c             	mov    0xc(%ebp),%eax
  100567:	c7 40 08 ac 73 10 00 	movl   $0x1073ac,0x8(%eax)
    info->eip_fn_namelen = 9;
  10056e:	8b 45 0c             	mov    0xc(%ebp),%eax
  100571:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
    info->eip_fn_addr = addr;
  100578:	8b 45 0c             	mov    0xc(%ebp),%eax
  10057b:	8b 55 08             	mov    0x8(%ebp),%edx
  10057e:	89 50 10             	mov    %edx,0x10(%eax)
    info->eip_fn_narg = 0;
  100581:	8b 45 0c             	mov    0xc(%ebp),%eax
  100584:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

    stabs = __STAB_BEGIN__;
  10058b:	c7 45 f4 48 8a 10 00 	movl   $0x108a48,-0xc(%ebp)
    stab_end = __STAB_END__;
  100592:	c7 45 f0 50 4b 11 00 	movl   $0x114b50,-0x10(%ebp)
    stabstr = __STABSTR_BEGIN__;
  100599:	c7 45 ec 51 4b 11 00 	movl   $0x114b51,-0x14(%ebp)
    stabstr_end = __STABSTR_END__;
  1005a0:	c7 45 e8 17 78 11 00 	movl   $0x117817,-0x18(%ebp)

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0) {
  1005a7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1005aa:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1005ad:	76 0d                	jbe    1005bc <debuginfo_eip+0x71>
  1005af:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1005b2:	83 e8 01             	sub    $0x1,%eax
  1005b5:	0f b6 00             	movzbl (%eax),%eax
  1005b8:	84 c0                	test   %al,%al
  1005ba:	74 0a                	je     1005c6 <debuginfo_eip+0x7b>
        return -1;
  1005bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1005c1:	e9 c0 02 00 00       	jmp    100886 <debuginfo_eip+0x33b>
    // 'eip'.  First, we find the basic source file containing 'eip'.
    // Then, we look in that source file for the function.  Then we look
    // for the line number.

    // Search the entire set of stabs for the source file (type N_SO).
    int lfile = 0, rfile = (stab_end - stabs) - 1;
  1005c6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  1005cd:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1005d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1005d3:	29 c2                	sub    %eax,%edx
  1005d5:	89 d0                	mov    %edx,%eax
  1005d7:	c1 f8 02             	sar    $0x2,%eax
  1005da:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
  1005e0:	83 e8 01             	sub    $0x1,%eax
  1005e3:	89 45 e0             	mov    %eax,-0x20(%ebp)
    stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
  1005e6:	8b 45 08             	mov    0x8(%ebp),%eax
  1005e9:	89 44 24 10          	mov    %eax,0x10(%esp)
  1005ed:	c7 44 24 0c 64 00 00 	movl   $0x64,0xc(%esp)
  1005f4:	00 
  1005f5:	8d 45 e0             	lea    -0x20(%ebp),%eax
  1005f8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1005fc:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  1005ff:	89 44 24 04          	mov    %eax,0x4(%esp)
  100603:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100606:	89 04 24             	mov    %eax,(%esp)
  100609:	e8 e7 fd ff ff       	call   1003f5 <stab_binsearch>
    if (lfile == 0)
  10060e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100611:	85 c0                	test   %eax,%eax
  100613:	75 0a                	jne    10061f <debuginfo_eip+0xd4>
        return -1;
  100615:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  10061a:	e9 67 02 00 00       	jmp    100886 <debuginfo_eip+0x33b>

    // Search within that file's stabs for the function definition
    // (N_FUN).
    int lfun = lfile, rfun = rfile;
  10061f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100622:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100625:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100628:	89 45 d8             	mov    %eax,-0x28(%ebp)
    int lline, rline;
    stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
  10062b:	8b 45 08             	mov    0x8(%ebp),%eax
  10062e:	89 44 24 10          	mov    %eax,0x10(%esp)
  100632:	c7 44 24 0c 24 00 00 	movl   $0x24,0xc(%esp)
  100639:	00 
  10063a:	8d 45 d8             	lea    -0x28(%ebp),%eax
  10063d:	89 44 24 08          	mov    %eax,0x8(%esp)
  100641:	8d 45 dc             	lea    -0x24(%ebp),%eax
  100644:	89 44 24 04          	mov    %eax,0x4(%esp)
  100648:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10064b:	89 04 24             	mov    %eax,(%esp)
  10064e:	e8 a2 fd ff ff       	call   1003f5 <stab_binsearch>

    if (lfun <= rfun) {
  100653:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100656:	8b 45 d8             	mov    -0x28(%ebp),%eax
  100659:	39 c2                	cmp    %eax,%edx
  10065b:	7f 7c                	jg     1006d9 <debuginfo_eip+0x18e>
        // stabs[lfun] points to the function name
        // in the string table, but check bounds just in case.
        if (stabs[lfun].n_strx < stabstr_end - stabstr) {
  10065d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100660:	89 c2                	mov    %eax,%edx
  100662:	89 d0                	mov    %edx,%eax
  100664:	01 c0                	add    %eax,%eax
  100666:	01 d0                	add    %edx,%eax
  100668:	c1 e0 02             	shl    $0x2,%eax
  10066b:	89 c2                	mov    %eax,%edx
  10066d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100670:	01 d0                	add    %edx,%eax
  100672:	8b 10                	mov    (%eax),%edx
  100674:	8b 4d e8             	mov    -0x18(%ebp),%ecx
  100677:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10067a:	29 c1                	sub    %eax,%ecx
  10067c:	89 c8                	mov    %ecx,%eax
  10067e:	39 c2                	cmp    %eax,%edx
  100680:	73 22                	jae    1006a4 <debuginfo_eip+0x159>
            info->eip_fn_name = stabstr + stabs[lfun].n_strx;
  100682:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100685:	89 c2                	mov    %eax,%edx
  100687:	89 d0                	mov    %edx,%eax
  100689:	01 c0                	add    %eax,%eax
  10068b:	01 d0                	add    %edx,%eax
  10068d:	c1 e0 02             	shl    $0x2,%eax
  100690:	89 c2                	mov    %eax,%edx
  100692:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100695:	01 d0                	add    %edx,%eax
  100697:	8b 10                	mov    (%eax),%edx
  100699:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10069c:	01 c2                	add    %eax,%edx
  10069e:	8b 45 0c             	mov    0xc(%ebp),%eax
  1006a1:	89 50 08             	mov    %edx,0x8(%eax)
        }
        info->eip_fn_addr = stabs[lfun].n_value;
  1006a4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1006a7:	89 c2                	mov    %eax,%edx
  1006a9:	89 d0                	mov    %edx,%eax
  1006ab:	01 c0                	add    %eax,%eax
  1006ad:	01 d0                	add    %edx,%eax
  1006af:	c1 e0 02             	shl    $0x2,%eax
  1006b2:	89 c2                	mov    %eax,%edx
  1006b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1006b7:	01 d0                	add    %edx,%eax
  1006b9:	8b 50 08             	mov    0x8(%eax),%edx
  1006bc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1006bf:	89 50 10             	mov    %edx,0x10(%eax)
        addr -= info->eip_fn_addr;
  1006c2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1006c5:	8b 40 10             	mov    0x10(%eax),%eax
  1006c8:	29 45 08             	sub    %eax,0x8(%ebp)
        // Search within the function definition for the line number.
        lline = lfun;
  1006cb:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1006ce:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfun;
  1006d1:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1006d4:	89 45 d0             	mov    %eax,-0x30(%ebp)
  1006d7:	eb 15                	jmp    1006ee <debuginfo_eip+0x1a3>
    } else {
        // Couldn't find function stab!  Maybe we're in an assembly
        // file.  Search the whole file for the line number.
        info->eip_fn_addr = addr;
  1006d9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1006dc:	8b 55 08             	mov    0x8(%ebp),%edx
  1006df:	89 50 10             	mov    %edx,0x10(%eax)
        lline = lfile;
  1006e2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1006e5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfile;
  1006e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1006eb:	89 45 d0             	mov    %eax,-0x30(%ebp)
    }
    info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
  1006ee:	8b 45 0c             	mov    0xc(%ebp),%eax
  1006f1:	8b 40 08             	mov    0x8(%eax),%eax
  1006f4:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
  1006fb:	00 
  1006fc:	89 04 24             	mov    %eax,(%esp)
  1006ff:	e8 d7 68 00 00       	call   106fdb <strfind>
  100704:	89 c2                	mov    %eax,%edx
  100706:	8b 45 0c             	mov    0xc(%ebp),%eax
  100709:	8b 40 08             	mov    0x8(%eax),%eax
  10070c:	29 c2                	sub    %eax,%edx
  10070e:	8b 45 0c             	mov    0xc(%ebp),%eax
  100711:	89 50 0c             	mov    %edx,0xc(%eax)

    // Search within [lline, rline] for the line number stab.
    // If found, set info->eip_line to the right line number.
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
  100714:	8b 45 08             	mov    0x8(%ebp),%eax
  100717:	89 44 24 10          	mov    %eax,0x10(%esp)
  10071b:	c7 44 24 0c 44 00 00 	movl   $0x44,0xc(%esp)
  100722:	00 
  100723:	8d 45 d0             	lea    -0x30(%ebp),%eax
  100726:	89 44 24 08          	mov    %eax,0x8(%esp)
  10072a:	8d 45 d4             	lea    -0x2c(%ebp),%eax
  10072d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100731:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100734:	89 04 24             	mov    %eax,(%esp)
  100737:	e8 b9 fc ff ff       	call   1003f5 <stab_binsearch>
    if (lline <= rline) {
  10073c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10073f:	8b 45 d0             	mov    -0x30(%ebp),%eax
  100742:	39 c2                	cmp    %eax,%edx
  100744:	7f 24                	jg     10076a <debuginfo_eip+0x21f>
        info->eip_line = stabs[rline].n_desc;
  100746:	8b 45 d0             	mov    -0x30(%ebp),%eax
  100749:	89 c2                	mov    %eax,%edx
  10074b:	89 d0                	mov    %edx,%eax
  10074d:	01 c0                	add    %eax,%eax
  10074f:	01 d0                	add    %edx,%eax
  100751:	c1 e0 02             	shl    $0x2,%eax
  100754:	89 c2                	mov    %eax,%edx
  100756:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100759:	01 d0                	add    %edx,%eax
  10075b:	0f b7 40 06          	movzwl 0x6(%eax),%eax
  10075f:	0f b7 d0             	movzwl %ax,%edx
  100762:	8b 45 0c             	mov    0xc(%ebp),%eax
  100765:	89 50 04             	mov    %edx,0x4(%eax)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
  100768:	eb 13                	jmp    10077d <debuginfo_eip+0x232>
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
    if (lline <= rline) {
        info->eip_line = stabs[rline].n_desc;
    } else {
        return -1;
  10076a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  10076f:	e9 12 01 00 00       	jmp    100886 <debuginfo_eip+0x33b>
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
           && stabs[lline].n_type != N_SOL
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
        lline --;
  100774:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  100777:	83 e8 01             	sub    $0x1,%eax
  10077a:	89 45 d4             	mov    %eax,-0x2c(%ebp)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
  10077d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  100780:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100783:	39 c2                	cmp    %eax,%edx
  100785:	7c 56                	jl     1007dd <debuginfo_eip+0x292>
           && stabs[lline].n_type != N_SOL
  100787:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10078a:	89 c2                	mov    %eax,%edx
  10078c:	89 d0                	mov    %edx,%eax
  10078e:	01 c0                	add    %eax,%eax
  100790:	01 d0                	add    %edx,%eax
  100792:	c1 e0 02             	shl    $0x2,%eax
  100795:	89 c2                	mov    %eax,%edx
  100797:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10079a:	01 d0                	add    %edx,%eax
  10079c:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  1007a0:	3c 84                	cmp    $0x84,%al
  1007a2:	74 39                	je     1007dd <debuginfo_eip+0x292>
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
  1007a4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1007a7:	89 c2                	mov    %eax,%edx
  1007a9:	89 d0                	mov    %edx,%eax
  1007ab:	01 c0                	add    %eax,%eax
  1007ad:	01 d0                	add    %edx,%eax
  1007af:	c1 e0 02             	shl    $0x2,%eax
  1007b2:	89 c2                	mov    %eax,%edx
  1007b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1007b7:	01 d0                	add    %edx,%eax
  1007b9:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  1007bd:	3c 64                	cmp    $0x64,%al
  1007bf:	75 b3                	jne    100774 <debuginfo_eip+0x229>
  1007c1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1007c4:	89 c2                	mov    %eax,%edx
  1007c6:	89 d0                	mov    %edx,%eax
  1007c8:	01 c0                	add    %eax,%eax
  1007ca:	01 d0                	add    %edx,%eax
  1007cc:	c1 e0 02             	shl    $0x2,%eax
  1007cf:	89 c2                	mov    %eax,%edx
  1007d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1007d4:	01 d0                	add    %edx,%eax
  1007d6:	8b 40 08             	mov    0x8(%eax),%eax
  1007d9:	85 c0                	test   %eax,%eax
  1007db:	74 97                	je     100774 <debuginfo_eip+0x229>
        lline --;
    }
    if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr) {
  1007dd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1007e0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1007e3:	39 c2                	cmp    %eax,%edx
  1007e5:	7c 46                	jl     10082d <debuginfo_eip+0x2e2>
  1007e7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1007ea:	89 c2                	mov    %eax,%edx
  1007ec:	89 d0                	mov    %edx,%eax
  1007ee:	01 c0                	add    %eax,%eax
  1007f0:	01 d0                	add    %edx,%eax
  1007f2:	c1 e0 02             	shl    $0x2,%eax
  1007f5:	89 c2                	mov    %eax,%edx
  1007f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1007fa:	01 d0                	add    %edx,%eax
  1007fc:	8b 10                	mov    (%eax),%edx
  1007fe:	8b 4d e8             	mov    -0x18(%ebp),%ecx
  100801:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100804:	29 c1                	sub    %eax,%ecx
  100806:	89 c8                	mov    %ecx,%eax
  100808:	39 c2                	cmp    %eax,%edx
  10080a:	73 21                	jae    10082d <debuginfo_eip+0x2e2>
        info->eip_file = stabstr + stabs[lline].n_strx;
  10080c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10080f:	89 c2                	mov    %eax,%edx
  100811:	89 d0                	mov    %edx,%eax
  100813:	01 c0                	add    %eax,%eax
  100815:	01 d0                	add    %edx,%eax
  100817:	c1 e0 02             	shl    $0x2,%eax
  10081a:	89 c2                	mov    %eax,%edx
  10081c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10081f:	01 d0                	add    %edx,%eax
  100821:	8b 10                	mov    (%eax),%edx
  100823:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100826:	01 c2                	add    %eax,%edx
  100828:	8b 45 0c             	mov    0xc(%ebp),%eax
  10082b:	89 10                	mov    %edx,(%eax)
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
  10082d:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100830:	8b 45 d8             	mov    -0x28(%ebp),%eax
  100833:	39 c2                	cmp    %eax,%edx
  100835:	7d 4a                	jge    100881 <debuginfo_eip+0x336>
        for (lline = lfun + 1;
  100837:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10083a:	83 c0 01             	add    $0x1,%eax
  10083d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  100840:	eb 18                	jmp    10085a <debuginfo_eip+0x30f>
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
            info->eip_fn_narg ++;
  100842:	8b 45 0c             	mov    0xc(%ebp),%eax
  100845:	8b 40 14             	mov    0x14(%eax),%eax
  100848:	8d 50 01             	lea    0x1(%eax),%edx
  10084b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10084e:	89 50 14             	mov    %edx,0x14(%eax)
    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
  100851:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  100854:	83 c0 01             	add    $0x1,%eax
  100857:	89 45 d4             	mov    %eax,-0x2c(%ebp)

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM;
  10085a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10085d:	8b 45 d8             	mov    -0x28(%ebp),%eax
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
  100860:	39 c2                	cmp    %eax,%edx
  100862:	7d 1d                	jge    100881 <debuginfo_eip+0x336>
             lline < rfun && stabs[lline].n_type == N_PSYM;
  100864:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  100867:	89 c2                	mov    %eax,%edx
  100869:	89 d0                	mov    %edx,%eax
  10086b:	01 c0                	add    %eax,%eax
  10086d:	01 d0                	add    %edx,%eax
  10086f:	c1 e0 02             	shl    $0x2,%eax
  100872:	89 c2                	mov    %eax,%edx
  100874:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100877:	01 d0                	add    %edx,%eax
  100879:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  10087d:	3c a0                	cmp    $0xa0,%al
  10087f:	74 c1                	je     100842 <debuginfo_eip+0x2f7>
             lline ++) {
            info->eip_fn_narg ++;
        }
    }
    return 0;
  100881:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100886:	c9                   	leave  
  100887:	c3                   	ret    

00100888 <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void
print_kerninfo(void) {
  100888:	55                   	push   %ebp
  100889:	89 e5                	mov    %esp,%ebp
  10088b:	83 ec 18             	sub    $0x18,%esp
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
  10088e:	c7 04 24 b6 73 10 00 	movl   $0x1073b6,(%esp)
  100895:	e8 ba fa ff ff       	call   100354 <cprintf>
    cprintf("  entry  0x%08x (phys)\n", kern_init);
  10089a:	c7 44 24 04 36 00 10 	movl   $0x100036,0x4(%esp)
  1008a1:	00 
  1008a2:	c7 04 24 cf 73 10 00 	movl   $0x1073cf,(%esp)
  1008a9:	e8 a6 fa ff ff       	call   100354 <cprintf>
    cprintf("  etext  0x%08x (phys)\n", etext);
  1008ae:	c7 44 24 04 f0 72 10 	movl   $0x1072f0,0x4(%esp)
  1008b5:	00 
  1008b6:	c7 04 24 e7 73 10 00 	movl   $0x1073e7,(%esp)
  1008bd:	e8 92 fa ff ff       	call   100354 <cprintf>
    cprintf("  edata  0x%08x (phys)\n", edata);
  1008c2:	c7 44 24 04 36 aa 11 	movl   $0x11aa36,0x4(%esp)
  1008c9:	00 
  1008ca:	c7 04 24 ff 73 10 00 	movl   $0x1073ff,(%esp)
  1008d1:	e8 7e fa ff ff       	call   100354 <cprintf>
    cprintf("  end    0x%08x (phys)\n", end);
  1008d6:	c7 44 24 04 00 58 12 	movl   $0x125800,0x4(%esp)
  1008dd:	00 
  1008de:	c7 04 24 17 74 10 00 	movl   $0x107417,(%esp)
  1008e5:	e8 6a fa ff ff       	call   100354 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n", (end - kern_init + 1023)/1024);
  1008ea:	b8 00 58 12 00       	mov    $0x125800,%eax
  1008ef:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
  1008f5:	b8 36 00 10 00       	mov    $0x100036,%eax
  1008fa:	29 c2                	sub    %eax,%edx
  1008fc:	89 d0                	mov    %edx,%eax
  1008fe:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
  100904:	85 c0                	test   %eax,%eax
  100906:	0f 48 c2             	cmovs  %edx,%eax
  100909:	c1 f8 0a             	sar    $0xa,%eax
  10090c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100910:	c7 04 24 30 74 10 00 	movl   $0x107430,(%esp)
  100917:	e8 38 fa ff ff       	call   100354 <cprintf>
}
  10091c:	c9                   	leave  
  10091d:	c3                   	ret    

0010091e <print_debuginfo>:
/* *
 * print_debuginfo - read and print the stat information for the address @eip,
 * and info.eip_fn_addr should be the first address of the related function.
 * */
void
print_debuginfo(uintptr_t eip) {
  10091e:	55                   	push   %ebp
  10091f:	89 e5                	mov    %esp,%ebp
  100921:	81 ec 48 01 00 00    	sub    $0x148,%esp
    struct eipdebuginfo info;
    if (debuginfo_eip(eip, &info) != 0) {
  100927:	8d 45 dc             	lea    -0x24(%ebp),%eax
  10092a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10092e:	8b 45 08             	mov    0x8(%ebp),%eax
  100931:	89 04 24             	mov    %eax,(%esp)
  100934:	e8 12 fc ff ff       	call   10054b <debuginfo_eip>
  100939:	85 c0                	test   %eax,%eax
  10093b:	74 15                	je     100952 <print_debuginfo+0x34>
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
  10093d:	8b 45 08             	mov    0x8(%ebp),%eax
  100940:	89 44 24 04          	mov    %eax,0x4(%esp)
  100944:	c7 04 24 5a 74 10 00 	movl   $0x10745a,(%esp)
  10094b:	e8 04 fa ff ff       	call   100354 <cprintf>
  100950:	eb 6d                	jmp    1009bf <print_debuginfo+0xa1>
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
  100952:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100959:	eb 1c                	jmp    100977 <print_debuginfo+0x59>
            fnname[j] = info.eip_fn_name[j];
  10095b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10095e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100961:	01 d0                	add    %edx,%eax
  100963:	0f b6 00             	movzbl (%eax),%eax
  100966:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
  10096c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10096f:	01 ca                	add    %ecx,%edx
  100971:	88 02                	mov    %al,(%edx)
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
  100973:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100977:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10097a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  10097d:	7f dc                	jg     10095b <print_debuginfo+0x3d>
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
  10097f:	8d 95 dc fe ff ff    	lea    -0x124(%ebp),%edx
  100985:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100988:	01 d0                	add    %edx,%eax
  10098a:	c6 00 00             	movb   $0x0,(%eax)
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
                fnname, eip - info.eip_fn_addr);
  10098d:	8b 45 ec             	mov    -0x14(%ebp),%eax
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
  100990:	8b 55 08             	mov    0x8(%ebp),%edx
  100993:	89 d1                	mov    %edx,%ecx
  100995:	29 c1                	sub    %eax,%ecx
  100997:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10099a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10099d:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  1009a1:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
  1009a7:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  1009ab:	89 54 24 08          	mov    %edx,0x8(%esp)
  1009af:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009b3:	c7 04 24 76 74 10 00 	movl   $0x107476,(%esp)
  1009ba:	e8 95 f9 ff ff       	call   100354 <cprintf>
                fnname, eip - info.eip_fn_addr);
    }
}
  1009bf:	c9                   	leave  
  1009c0:	c3                   	ret    

001009c1 <read_eip>:

static __noinline uint32_t
read_eip(void) {
  1009c1:	55                   	push   %ebp
  1009c2:	89 e5                	mov    %esp,%ebp
  1009c4:	83 ec 10             	sub    $0x10,%esp
    uint32_t eip;
    asm volatile("movl 4(%%ebp), %0" : "=r" (eip));
  1009c7:	8b 45 04             	mov    0x4(%ebp),%eax
  1009ca:	89 45 fc             	mov    %eax,-0x4(%ebp)
    return eip;
  1009cd:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1009d0:	c9                   	leave  
  1009d1:	c3                   	ret    

001009d2 <print_stackframe>:
 *
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the boundary.
 * */
void
print_stackframe(void) {
  1009d2:	55                   	push   %ebp
  1009d3:	89 e5                	mov    %esp,%ebp
  1009d5:	53                   	push   %ebx
  1009d6:	83 ec 34             	sub    $0x34,%esp
}

static inline uint32_t
read_ebp(void) {
    uint32_t ebp;
    asm volatile ("movl %%ebp, %0" : "=r" (ebp));
  1009d9:	89 e8                	mov    %ebp,%eax
  1009db:	89 45 e8             	mov    %eax,-0x18(%ebp)
    return ebp;
  1009de:	8b 45 e8             	mov    -0x18(%ebp),%eax
      *    (3.4) call print_debuginfo(eip-1) to print the C calling function name and line number, etc.
      *    (3.5) popup a calling stackframe
      *           NOTICE: the calling funciton's return addr eip  = ss:[ebp+4]
      *                   the calling funciton's ebp = ss:[ebp]
      */
    uint32_t ebp = read_ebp();
  1009e1:	89 45 f4             	mov    %eax,-0xc(%ebp)
    uint32_t eip = read_eip();
  1009e4:	e8 d8 ff ff ff       	call   1009c1 <read_eip>
  1009e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    int i;
    for (i = 0; i < ebp && STACKFRAME_DEPTH; i++) {
  1009ec:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  1009f3:	e9 87 00 00 00       	jmp    100a7f <print_stackframe+0xad>
        cprintf("ebp:%08x eip:%08x ", ebp, eip);
  1009f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1009fb:	89 44 24 08          	mov    %eax,0x8(%esp)
  1009ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a02:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a06:	c7 04 24 88 74 10 00 	movl   $0x107488,(%esp)
  100a0d:	e8 42 f9 ff ff       	call   100354 <cprintf>
        cprintf("args:%08x %08x %08x %08x", *(uint32_t*)(ebp + 8), *(uint32_t*)(ebp + 12), *(uint32_t*)(ebp + 16), *(uint32_t*)(ebp + 20));
  100a12:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a15:	83 c0 14             	add    $0x14,%eax
  100a18:	8b 18                	mov    (%eax),%ebx
  100a1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a1d:	83 c0 10             	add    $0x10,%eax
  100a20:	8b 08                	mov    (%eax),%ecx
  100a22:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a25:	83 c0 0c             	add    $0xc,%eax
  100a28:	8b 10                	mov    (%eax),%edx
  100a2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a2d:	83 c0 08             	add    $0x8,%eax
  100a30:	8b 00                	mov    (%eax),%eax
  100a32:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  100a36:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  100a3a:	89 54 24 08          	mov    %edx,0x8(%esp)
  100a3e:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a42:	c7 04 24 9b 74 10 00 	movl   $0x10749b,(%esp)
  100a49:	e8 06 f9 ff ff       	call   100354 <cprintf>
        cprintf("\n");
  100a4e:	c7 04 24 b4 74 10 00 	movl   $0x1074b4,(%esp)
  100a55:	e8 fa f8 ff ff       	call   100354 <cprintf>
        print_debuginfo(eip - 1);
  100a5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100a5d:	83 e8 01             	sub    $0x1,%eax
  100a60:	89 04 24             	mov    %eax,(%esp)
  100a63:	e8 b6 fe ff ff       	call   10091e <print_debuginfo>
        eip = *(uint32_t*)(ebp + 4); //这里要先更新eip再更新ebp
  100a68:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a6b:	83 c0 04             	add    $0x4,%eax
  100a6e:	8b 00                	mov    (%eax),%eax
  100a70:	89 45 f0             	mov    %eax,-0x10(%ebp)
        ebp = *(uint32_t*)(ebp);
  100a73:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a76:	8b 00                	mov    (%eax),%eax
  100a78:	89 45 f4             	mov    %eax,-0xc(%ebp)
      *                   the calling funciton's ebp = ss:[ebp]
      */
    uint32_t ebp = read_ebp();
    uint32_t eip = read_eip();
    int i;
    for (i = 0; i < ebp && STACKFRAME_DEPTH; i++) {
  100a7b:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  100a7f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100a82:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  100a85:	0f 82 6d ff ff ff    	jb     1009f8 <print_stackframe+0x26>
        cprintf("\n");
        print_debuginfo(eip - 1);
        eip = *(uint32_t*)(ebp + 4); //这里要先更新eip再更新ebp
        ebp = *(uint32_t*)(ebp);
    }
}
  100a8b:	83 c4 34             	add    $0x34,%esp
  100a8e:	5b                   	pop    %ebx
  100a8f:	5d                   	pop    %ebp
  100a90:	c3                   	ret    

00100a91 <parse>:
#define MAXARGS         16
#define WHITESPACE      " \t\n\r"

/* parse - parse the command buffer into whitespace-separated arguments */
static int
parse(char *buf, char **argv) {
  100a91:	55                   	push   %ebp
  100a92:	89 e5                	mov    %esp,%ebp
  100a94:	83 ec 28             	sub    $0x28,%esp
    int argc = 0;
  100a97:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
  100a9e:	eb 0c                	jmp    100aac <parse+0x1b>
            *buf ++ = '\0';
  100aa0:	8b 45 08             	mov    0x8(%ebp),%eax
  100aa3:	8d 50 01             	lea    0x1(%eax),%edx
  100aa6:	89 55 08             	mov    %edx,0x8(%ebp)
  100aa9:	c6 00 00             	movb   $0x0,(%eax)
static int
parse(char *buf, char **argv) {
    int argc = 0;
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
  100aac:	8b 45 08             	mov    0x8(%ebp),%eax
  100aaf:	0f b6 00             	movzbl (%eax),%eax
  100ab2:	84 c0                	test   %al,%al
  100ab4:	74 1d                	je     100ad3 <parse+0x42>
  100ab6:	8b 45 08             	mov    0x8(%ebp),%eax
  100ab9:	0f b6 00             	movzbl (%eax),%eax
  100abc:	0f be c0             	movsbl %al,%eax
  100abf:	89 44 24 04          	mov    %eax,0x4(%esp)
  100ac3:	c7 04 24 38 75 10 00 	movl   $0x107538,(%esp)
  100aca:	e8 d9 64 00 00       	call   106fa8 <strchr>
  100acf:	85 c0                	test   %eax,%eax
  100ad1:	75 cd                	jne    100aa0 <parse+0xf>
            *buf ++ = '\0';
        }
        if (*buf == '\0') {
  100ad3:	8b 45 08             	mov    0x8(%ebp),%eax
  100ad6:	0f b6 00             	movzbl (%eax),%eax
  100ad9:	84 c0                	test   %al,%al
  100adb:	75 02                	jne    100adf <parse+0x4e>
            break;
  100add:	eb 67                	jmp    100b46 <parse+0xb5>
        }

        // save and scan past next arg
        if (argc == MAXARGS - 1) {
  100adf:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
  100ae3:	75 14                	jne    100af9 <parse+0x68>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
  100ae5:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  100aec:	00 
  100aed:	c7 04 24 3d 75 10 00 	movl   $0x10753d,(%esp)
  100af4:	e8 5b f8 ff ff       	call   100354 <cprintf>
        }
        argv[argc ++] = buf;
  100af9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100afc:	8d 50 01             	lea    0x1(%eax),%edx
  100aff:	89 55 f4             	mov    %edx,-0xc(%ebp)
  100b02:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  100b09:	8b 45 0c             	mov    0xc(%ebp),%eax
  100b0c:	01 c2                	add    %eax,%edx
  100b0e:	8b 45 08             	mov    0x8(%ebp),%eax
  100b11:	89 02                	mov    %eax,(%edx)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
  100b13:	eb 04                	jmp    100b19 <parse+0x88>
            buf ++;
  100b15:	83 45 08 01          	addl   $0x1,0x8(%ebp)
        // save and scan past next arg
        if (argc == MAXARGS - 1) {
            cprintf("Too many arguments (max %d).\n", MAXARGS);
        }
        argv[argc ++] = buf;
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
  100b19:	8b 45 08             	mov    0x8(%ebp),%eax
  100b1c:	0f b6 00             	movzbl (%eax),%eax
  100b1f:	84 c0                	test   %al,%al
  100b21:	74 1d                	je     100b40 <parse+0xaf>
  100b23:	8b 45 08             	mov    0x8(%ebp),%eax
  100b26:	0f b6 00             	movzbl (%eax),%eax
  100b29:	0f be c0             	movsbl %al,%eax
  100b2c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b30:	c7 04 24 38 75 10 00 	movl   $0x107538,(%esp)
  100b37:	e8 6c 64 00 00       	call   106fa8 <strchr>
  100b3c:	85 c0                	test   %eax,%eax
  100b3e:	74 d5                	je     100b15 <parse+0x84>
            buf ++;
        }
    }
  100b40:	90                   	nop
static int
parse(char *buf, char **argv) {
    int argc = 0;
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
  100b41:	e9 66 ff ff ff       	jmp    100aac <parse+0x1b>
        argv[argc ++] = buf;
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
            buf ++;
        }
    }
    return argc;
  100b46:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100b49:	c9                   	leave  
  100b4a:	c3                   	ret    

00100b4b <runcmd>:
/* *
 * runcmd - parse the input string, split it into separated arguments
 * and then lookup and invoke some related commands/
 * */
static int
runcmd(char *buf, struct trapframe *tf) {
  100b4b:	55                   	push   %ebp
  100b4c:	89 e5                	mov    %esp,%ebp
  100b4e:	83 ec 68             	sub    $0x68,%esp
    char *argv[MAXARGS];
    int argc = parse(buf, argv);
  100b51:	8d 45 b0             	lea    -0x50(%ebp),%eax
  100b54:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b58:	8b 45 08             	mov    0x8(%ebp),%eax
  100b5b:	89 04 24             	mov    %eax,(%esp)
  100b5e:	e8 2e ff ff ff       	call   100a91 <parse>
  100b63:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if (argc == 0) {
  100b66:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  100b6a:	75 0a                	jne    100b76 <runcmd+0x2b>
        return 0;
  100b6c:	b8 00 00 00 00       	mov    $0x0,%eax
  100b71:	e9 85 00 00 00       	jmp    100bfb <runcmd+0xb0>
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
  100b76:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100b7d:	eb 5c                	jmp    100bdb <runcmd+0x90>
        if (strcmp(commands[i].name, argv[0]) == 0) {
  100b7f:	8b 4d b0             	mov    -0x50(%ebp),%ecx
  100b82:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100b85:	89 d0                	mov    %edx,%eax
  100b87:	01 c0                	add    %eax,%eax
  100b89:	01 d0                	add    %edx,%eax
  100b8b:	c1 e0 02             	shl    $0x2,%eax
  100b8e:	05 00 a0 11 00       	add    $0x11a000,%eax
  100b93:	8b 00                	mov    (%eax),%eax
  100b95:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  100b99:	89 04 24             	mov    %eax,(%esp)
  100b9c:	e8 68 63 00 00       	call   106f09 <strcmp>
  100ba1:	85 c0                	test   %eax,%eax
  100ba3:	75 32                	jne    100bd7 <runcmd+0x8c>
            return commands[i].func(argc - 1, argv + 1, tf);
  100ba5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100ba8:	89 d0                	mov    %edx,%eax
  100baa:	01 c0                	add    %eax,%eax
  100bac:	01 d0                	add    %edx,%eax
  100bae:	c1 e0 02             	shl    $0x2,%eax
  100bb1:	05 00 a0 11 00       	add    $0x11a000,%eax
  100bb6:	8b 40 08             	mov    0x8(%eax),%eax
  100bb9:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100bbc:	8d 4a ff             	lea    -0x1(%edx),%ecx
  100bbf:	8b 55 0c             	mov    0xc(%ebp),%edx
  100bc2:	89 54 24 08          	mov    %edx,0x8(%esp)
  100bc6:	8d 55 b0             	lea    -0x50(%ebp),%edx
  100bc9:	83 c2 04             	add    $0x4,%edx
  100bcc:	89 54 24 04          	mov    %edx,0x4(%esp)
  100bd0:	89 0c 24             	mov    %ecx,(%esp)
  100bd3:	ff d0                	call   *%eax
  100bd5:	eb 24                	jmp    100bfb <runcmd+0xb0>
    int argc = parse(buf, argv);
    if (argc == 0) {
        return 0;
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
  100bd7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100bdb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100bde:	83 f8 02             	cmp    $0x2,%eax
  100be1:	76 9c                	jbe    100b7f <runcmd+0x34>
        if (strcmp(commands[i].name, argv[0]) == 0) {
            return commands[i].func(argc - 1, argv + 1, tf);
        }
    }
    cprintf("Unknown command '%s'\n", argv[0]);
  100be3:	8b 45 b0             	mov    -0x50(%ebp),%eax
  100be6:	89 44 24 04          	mov    %eax,0x4(%esp)
  100bea:	c7 04 24 5b 75 10 00 	movl   $0x10755b,(%esp)
  100bf1:	e8 5e f7 ff ff       	call   100354 <cprintf>
    return 0;
  100bf6:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100bfb:	c9                   	leave  
  100bfc:	c3                   	ret    

00100bfd <kmonitor>:

/***** Implementations of basic kernel monitor commands *****/

void
kmonitor(struct trapframe *tf) {
  100bfd:	55                   	push   %ebp
  100bfe:	89 e5                	mov    %esp,%ebp
  100c00:	83 ec 28             	sub    $0x28,%esp
    cprintf("Welcome to the kernel debug monitor!!\n");
  100c03:	c7 04 24 74 75 10 00 	movl   $0x107574,(%esp)
  100c0a:	e8 45 f7 ff ff       	call   100354 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
  100c0f:	c7 04 24 9c 75 10 00 	movl   $0x10759c,(%esp)
  100c16:	e8 39 f7 ff ff       	call   100354 <cprintf>

    if (tf != NULL) {
  100c1b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  100c1f:	74 0b                	je     100c2c <kmonitor+0x2f>
        print_trapframe(tf);
  100c21:	8b 45 08             	mov    0x8(%ebp),%eax
  100c24:	89 04 24             	mov    %eax,(%esp)
  100c27:	e8 3b 0f 00 00       	call   101b67 <print_trapframe>
    }

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
  100c2c:	c7 04 24 c1 75 10 00 	movl   $0x1075c1,(%esp)
  100c33:	e8 13 f6 ff ff       	call   10024b <readline>
  100c38:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100c3b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100c3f:	74 18                	je     100c59 <kmonitor+0x5c>
            if (runcmd(buf, tf) < 0) {
  100c41:	8b 45 08             	mov    0x8(%ebp),%eax
  100c44:	89 44 24 04          	mov    %eax,0x4(%esp)
  100c48:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100c4b:	89 04 24             	mov    %eax,(%esp)
  100c4e:	e8 f8 fe ff ff       	call   100b4b <runcmd>
  100c53:	85 c0                	test   %eax,%eax
  100c55:	79 02                	jns    100c59 <kmonitor+0x5c>
                break;
  100c57:	eb 02                	jmp    100c5b <kmonitor+0x5e>
            }
        }
    }
  100c59:	eb d1                	jmp    100c2c <kmonitor+0x2f>
}
  100c5b:	c9                   	leave  
  100c5c:	c3                   	ret    

00100c5d <mon_help>:

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
  100c5d:	55                   	push   %ebp
  100c5e:	89 e5                	mov    %esp,%ebp
  100c60:	83 ec 28             	sub    $0x28,%esp
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
  100c63:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100c6a:	eb 3f                	jmp    100cab <mon_help+0x4e>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
  100c6c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c6f:	89 d0                	mov    %edx,%eax
  100c71:	01 c0                	add    %eax,%eax
  100c73:	01 d0                	add    %edx,%eax
  100c75:	c1 e0 02             	shl    $0x2,%eax
  100c78:	05 00 a0 11 00       	add    $0x11a000,%eax
  100c7d:	8b 48 04             	mov    0x4(%eax),%ecx
  100c80:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c83:	89 d0                	mov    %edx,%eax
  100c85:	01 c0                	add    %eax,%eax
  100c87:	01 d0                	add    %edx,%eax
  100c89:	c1 e0 02             	shl    $0x2,%eax
  100c8c:	05 00 a0 11 00       	add    $0x11a000,%eax
  100c91:	8b 00                	mov    (%eax),%eax
  100c93:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  100c97:	89 44 24 04          	mov    %eax,0x4(%esp)
  100c9b:	c7 04 24 c5 75 10 00 	movl   $0x1075c5,(%esp)
  100ca2:	e8 ad f6 ff ff       	call   100354 <cprintf>

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
  100ca7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100cab:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100cae:	83 f8 02             	cmp    $0x2,%eax
  100cb1:	76 b9                	jbe    100c6c <mon_help+0xf>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
    }
    return 0;
  100cb3:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100cb8:	c9                   	leave  
  100cb9:	c3                   	ret    

00100cba <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
  100cba:	55                   	push   %ebp
  100cbb:	89 e5                	mov    %esp,%ebp
  100cbd:	83 ec 08             	sub    $0x8,%esp
    print_kerninfo();
  100cc0:	e8 c3 fb ff ff       	call   100888 <print_kerninfo>
    return 0;
  100cc5:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100cca:	c9                   	leave  
  100ccb:	c3                   	ret    

00100ccc <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
  100ccc:	55                   	push   %ebp
  100ccd:	89 e5                	mov    %esp,%ebp
  100ccf:	83 ec 08             	sub    $0x8,%esp
    print_stackframe();
  100cd2:	e8 fb fc ff ff       	call   1009d2 <print_stackframe>
    return 0;
  100cd7:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100cdc:	c9                   	leave  
  100cdd:	c3                   	ret    

00100cde <__panic>:
/* *
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
  100cde:	55                   	push   %ebp
  100cdf:	89 e5                	mov    %esp,%ebp
  100ce1:	83 ec 28             	sub    $0x28,%esp
    if (is_panic) {
  100ce4:	a1 20 d4 11 00       	mov    0x11d420,%eax
  100ce9:	85 c0                	test   %eax,%eax
  100ceb:	74 02                	je     100cef <__panic+0x11>
        goto panic_dead;
  100ced:	eb 59                	jmp    100d48 <__panic+0x6a>
    }
    is_panic = 1;
  100cef:	c7 05 20 d4 11 00 01 	movl   $0x1,0x11d420
  100cf6:	00 00 00 

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
  100cf9:	8d 45 14             	lea    0x14(%ebp),%eax
  100cfc:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
  100cff:	8b 45 0c             	mov    0xc(%ebp),%eax
  100d02:	89 44 24 08          	mov    %eax,0x8(%esp)
  100d06:	8b 45 08             	mov    0x8(%ebp),%eax
  100d09:	89 44 24 04          	mov    %eax,0x4(%esp)
  100d0d:	c7 04 24 ce 75 10 00 	movl   $0x1075ce,(%esp)
  100d14:	e8 3b f6 ff ff       	call   100354 <cprintf>
    vcprintf(fmt, ap);
  100d19:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100d1c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100d20:	8b 45 10             	mov    0x10(%ebp),%eax
  100d23:	89 04 24             	mov    %eax,(%esp)
  100d26:	e8 f6 f5 ff ff       	call   100321 <vcprintf>
    cprintf("\n");
  100d2b:	c7 04 24 ea 75 10 00 	movl   $0x1075ea,(%esp)
  100d32:	e8 1d f6 ff ff       	call   100354 <cprintf>
    
    cprintf("stack trackback:\n");
  100d37:	c7 04 24 ec 75 10 00 	movl   $0x1075ec,(%esp)
  100d3e:	e8 11 f6 ff ff       	call   100354 <cprintf>
    print_stackframe();
  100d43:	e8 8a fc ff ff       	call   1009d2 <print_stackframe>
    
    va_end(ap);

panic_dead:
    intr_disable();
  100d48:	e8 85 09 00 00       	call   1016d2 <intr_disable>
    while (1) {
        kmonitor(NULL);
  100d4d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  100d54:	e8 a4 fe ff ff       	call   100bfd <kmonitor>
    }
  100d59:	eb f2                	jmp    100d4d <__panic+0x6f>

00100d5b <__warn>:
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
  100d5b:	55                   	push   %ebp
  100d5c:	89 e5                	mov    %esp,%ebp
  100d5e:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    va_start(ap, fmt);
  100d61:	8d 45 14             	lea    0x14(%ebp),%eax
  100d64:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
  100d67:	8b 45 0c             	mov    0xc(%ebp),%eax
  100d6a:	89 44 24 08          	mov    %eax,0x8(%esp)
  100d6e:	8b 45 08             	mov    0x8(%ebp),%eax
  100d71:	89 44 24 04          	mov    %eax,0x4(%esp)
  100d75:	c7 04 24 fe 75 10 00 	movl   $0x1075fe,(%esp)
  100d7c:	e8 d3 f5 ff ff       	call   100354 <cprintf>
    vcprintf(fmt, ap);
  100d81:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100d84:	89 44 24 04          	mov    %eax,0x4(%esp)
  100d88:	8b 45 10             	mov    0x10(%ebp),%eax
  100d8b:	89 04 24             	mov    %eax,(%esp)
  100d8e:	e8 8e f5 ff ff       	call   100321 <vcprintf>
    cprintf("\n");
  100d93:	c7 04 24 ea 75 10 00 	movl   $0x1075ea,(%esp)
  100d9a:	e8 b5 f5 ff ff       	call   100354 <cprintf>
    va_end(ap);
}
  100d9f:	c9                   	leave  
  100da0:	c3                   	ret    

00100da1 <is_kernel_panic>:

bool
is_kernel_panic(void) {
  100da1:	55                   	push   %ebp
  100da2:	89 e5                	mov    %esp,%ebp
    return is_panic;
  100da4:	a1 20 d4 11 00       	mov    0x11d420,%eax
}
  100da9:	5d                   	pop    %ebp
  100daa:	c3                   	ret    

00100dab <clock_init>:
/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void
clock_init(void) {
  100dab:	55                   	push   %ebp
  100dac:	89 e5                	mov    %esp,%ebp
  100dae:	83 ec 28             	sub    $0x28,%esp
  100db1:	66 c7 45 f6 43 00    	movw   $0x43,-0xa(%ebp)
  100db7:	c6 45 f5 34          	movb   $0x34,-0xb(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  100dbb:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
  100dbf:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  100dc3:	ee                   	out    %al,(%dx)
  100dc4:	66 c7 45 f2 40 00    	movw   $0x40,-0xe(%ebp)
  100dca:	c6 45 f1 9c          	movb   $0x9c,-0xf(%ebp)
  100dce:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
  100dd2:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  100dd6:	ee                   	out    %al,(%dx)
  100dd7:	66 c7 45 ee 40 00    	movw   $0x40,-0x12(%ebp)
  100ddd:	c6 45 ed 2e          	movb   $0x2e,-0x13(%ebp)
  100de1:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
  100de5:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  100de9:	ee                   	out    %al,(%dx)
    outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
    outb(IO_TIMER1, TIMER_DIV(100) % 256);
    outb(IO_TIMER1, TIMER_DIV(100) / 256);

    // initialize time counter 'ticks' to zero
    ticks = 0;
  100dea:	c7 05 2c 57 12 00 00 	movl   $0x0,0x12572c
  100df1:	00 00 00 

    cprintf("++ setup timer interrupts\n");
  100df4:	c7 04 24 1c 76 10 00 	movl   $0x10761c,(%esp)
  100dfb:	e8 54 f5 ff ff       	call   100354 <cprintf>
    pic_enable(IRQ_TIMER);
  100e00:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  100e07:	e8 24 09 00 00       	call   101730 <pic_enable>
}
  100e0c:	c9                   	leave  
  100e0d:	c3                   	ret    

00100e0e <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
  100e0e:	55                   	push   %ebp
  100e0f:	89 e5                	mov    %esp,%ebp
  100e11:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
  100e14:	9c                   	pushf  
  100e15:	58                   	pop    %eax
  100e16:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
  100e19:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
  100e1c:	25 00 02 00 00       	and    $0x200,%eax
  100e21:	85 c0                	test   %eax,%eax
  100e23:	74 0c                	je     100e31 <__intr_save+0x23>
        intr_disable();
  100e25:	e8 a8 08 00 00       	call   1016d2 <intr_disable>
        return 1;
  100e2a:	b8 01 00 00 00       	mov    $0x1,%eax
  100e2f:	eb 05                	jmp    100e36 <__intr_save+0x28>
    }
    return 0;
  100e31:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100e36:	c9                   	leave  
  100e37:	c3                   	ret    

00100e38 <__intr_restore>:

static inline void
__intr_restore(bool flag) {
  100e38:	55                   	push   %ebp
  100e39:	89 e5                	mov    %esp,%ebp
  100e3b:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
  100e3e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  100e42:	74 05                	je     100e49 <__intr_restore+0x11>
        intr_enable();
  100e44:	e8 83 08 00 00       	call   1016cc <intr_enable>
    }
}
  100e49:	c9                   	leave  
  100e4a:	c3                   	ret    

00100e4b <delay>:
#include <memlayout.h>
#include <sync.h>

/* stupid I/O delay routine necessitated by historical PC design flaws */
static void
delay(void) {
  100e4b:	55                   	push   %ebp
  100e4c:	89 e5                	mov    %esp,%ebp
  100e4e:	83 ec 10             	sub    $0x10,%esp
  100e51:	66 c7 45 fe 84 00    	movw   $0x84,-0x2(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  100e57:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
  100e5b:	89 c2                	mov    %eax,%edx
  100e5d:	ec                   	in     (%dx),%al
  100e5e:	88 45 fd             	mov    %al,-0x3(%ebp)
  100e61:	66 c7 45 fa 84 00    	movw   $0x84,-0x6(%ebp)
  100e67:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
  100e6b:	89 c2                	mov    %eax,%edx
  100e6d:	ec                   	in     (%dx),%al
  100e6e:	88 45 f9             	mov    %al,-0x7(%ebp)
  100e71:	66 c7 45 f6 84 00    	movw   $0x84,-0xa(%ebp)
  100e77:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  100e7b:	89 c2                	mov    %eax,%edx
  100e7d:	ec                   	in     (%dx),%al
  100e7e:	88 45 f5             	mov    %al,-0xb(%ebp)
  100e81:	66 c7 45 f2 84 00    	movw   $0x84,-0xe(%ebp)
  100e87:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
  100e8b:	89 c2                	mov    %eax,%edx
  100e8d:	ec                   	in     (%dx),%al
  100e8e:	88 45 f1             	mov    %al,-0xf(%ebp)
    inb(0x84);
    inb(0x84);
    inb(0x84);
    inb(0x84);
}
  100e91:	c9                   	leave  
  100e92:	c3                   	ret    

00100e93 <cga_init>:
static uint16_t addr_6845;

/* TEXT-mode CGA/VGA display output */

static void
cga_init(void) {
  100e93:	55                   	push   %ebp
  100e94:	89 e5                	mov    %esp,%ebp
  100e96:	83 ec 20             	sub    $0x20,%esp
    volatile uint16_t *cp = (uint16_t *)(CGA_BUF + KERNBASE);
  100e99:	c7 45 fc 00 80 0b c0 	movl   $0xc00b8000,-0x4(%ebp)
    uint16_t was = *cp;
  100ea0:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100ea3:	0f b7 00             	movzwl (%eax),%eax
  100ea6:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
    *cp = (uint16_t) 0xA55A;
  100eaa:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100ead:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
    if (*cp != 0xA55A) {
  100eb2:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100eb5:	0f b7 00             	movzwl (%eax),%eax
  100eb8:	66 3d 5a a5          	cmp    $0xa55a,%ax
  100ebc:	74 12                	je     100ed0 <cga_init+0x3d>
        cp = (uint16_t*)(MONO_BUF + KERNBASE);
  100ebe:	c7 45 fc 00 00 0b c0 	movl   $0xc00b0000,-0x4(%ebp)
        addr_6845 = MONO_BASE;
  100ec5:	66 c7 05 46 d4 11 00 	movw   $0x3b4,0x11d446
  100ecc:	b4 03 
  100ece:	eb 13                	jmp    100ee3 <cga_init+0x50>
    } else {
        *cp = was;
  100ed0:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100ed3:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
  100ed7:	66 89 10             	mov    %dx,(%eax)
        addr_6845 = CGA_BASE;
  100eda:	66 c7 05 46 d4 11 00 	movw   $0x3d4,0x11d446
  100ee1:	d4 03 
    }

    // Extract cursor location
    uint32_t pos;
    outb(addr_6845, 14);
  100ee3:	0f b7 05 46 d4 11 00 	movzwl 0x11d446,%eax
  100eea:	0f b7 c0             	movzwl %ax,%eax
  100eed:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
  100ef1:	c6 45 f1 0e          	movb   $0xe,-0xf(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  100ef5:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
  100ef9:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  100efd:	ee                   	out    %al,(%dx)
    pos = inb(addr_6845 + 1) << 8;
  100efe:	0f b7 05 46 d4 11 00 	movzwl 0x11d446,%eax
  100f05:	83 c0 01             	add    $0x1,%eax
  100f08:	0f b7 c0             	movzwl %ax,%eax
  100f0b:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  100f0f:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
  100f13:	89 c2                	mov    %eax,%edx
  100f15:	ec                   	in     (%dx),%al
  100f16:	88 45 ed             	mov    %al,-0x13(%ebp)
    return data;
  100f19:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
  100f1d:	0f b6 c0             	movzbl %al,%eax
  100f20:	c1 e0 08             	shl    $0x8,%eax
  100f23:	89 45 f4             	mov    %eax,-0xc(%ebp)
    outb(addr_6845, 15);
  100f26:	0f b7 05 46 d4 11 00 	movzwl 0x11d446,%eax
  100f2d:	0f b7 c0             	movzwl %ax,%eax
  100f30:	66 89 45 ea          	mov    %ax,-0x16(%ebp)
  100f34:	c6 45 e9 0f          	movb   $0xf,-0x17(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  100f38:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
  100f3c:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
  100f40:	ee                   	out    %al,(%dx)
    pos |= inb(addr_6845 + 1);
  100f41:	0f b7 05 46 d4 11 00 	movzwl 0x11d446,%eax
  100f48:	83 c0 01             	add    $0x1,%eax
  100f4b:	0f b7 c0             	movzwl %ax,%eax
  100f4e:	66 89 45 e6          	mov    %ax,-0x1a(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  100f52:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax
  100f56:	89 c2                	mov    %eax,%edx
  100f58:	ec                   	in     (%dx),%al
  100f59:	88 45 e5             	mov    %al,-0x1b(%ebp)
    return data;
  100f5c:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
  100f60:	0f b6 c0             	movzbl %al,%eax
  100f63:	09 45 f4             	or     %eax,-0xc(%ebp)

    crt_buf = (uint16_t*) cp;
  100f66:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100f69:	a3 40 d4 11 00       	mov    %eax,0x11d440
    crt_pos = pos;
  100f6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100f71:	66 a3 44 d4 11 00    	mov    %ax,0x11d444
}
  100f77:	c9                   	leave  
  100f78:	c3                   	ret    

00100f79 <serial_init>:

static bool serial_exists = 0;

static void
serial_init(void) {
  100f79:	55                   	push   %ebp
  100f7a:	89 e5                	mov    %esp,%ebp
  100f7c:	83 ec 48             	sub    $0x48,%esp
  100f7f:	66 c7 45 f6 fa 03    	movw   $0x3fa,-0xa(%ebp)
  100f85:	c6 45 f5 00          	movb   $0x0,-0xb(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  100f89:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
  100f8d:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  100f91:	ee                   	out    %al,(%dx)
  100f92:	66 c7 45 f2 fb 03    	movw   $0x3fb,-0xe(%ebp)
  100f98:	c6 45 f1 80          	movb   $0x80,-0xf(%ebp)
  100f9c:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
  100fa0:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  100fa4:	ee                   	out    %al,(%dx)
  100fa5:	66 c7 45 ee f8 03    	movw   $0x3f8,-0x12(%ebp)
  100fab:	c6 45 ed 0c          	movb   $0xc,-0x13(%ebp)
  100faf:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
  100fb3:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  100fb7:	ee                   	out    %al,(%dx)
  100fb8:	66 c7 45 ea f9 03    	movw   $0x3f9,-0x16(%ebp)
  100fbe:	c6 45 e9 00          	movb   $0x0,-0x17(%ebp)
  100fc2:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
  100fc6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
  100fca:	ee                   	out    %al,(%dx)
  100fcb:	66 c7 45 e6 fb 03    	movw   $0x3fb,-0x1a(%ebp)
  100fd1:	c6 45 e5 03          	movb   $0x3,-0x1b(%ebp)
  100fd5:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
  100fd9:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
  100fdd:	ee                   	out    %al,(%dx)
  100fde:	66 c7 45 e2 fc 03    	movw   $0x3fc,-0x1e(%ebp)
  100fe4:	c6 45 e1 00          	movb   $0x0,-0x1f(%ebp)
  100fe8:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
  100fec:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
  100ff0:	ee                   	out    %al,(%dx)
  100ff1:	66 c7 45 de f9 03    	movw   $0x3f9,-0x22(%ebp)
  100ff7:	c6 45 dd 01          	movb   $0x1,-0x23(%ebp)
  100ffb:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
  100fff:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  101003:	ee                   	out    %al,(%dx)
  101004:	66 c7 45 da fd 03    	movw   $0x3fd,-0x26(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  10100a:	0f b7 45 da          	movzwl -0x26(%ebp),%eax
  10100e:	89 c2                	mov    %eax,%edx
  101010:	ec                   	in     (%dx),%al
  101011:	88 45 d9             	mov    %al,-0x27(%ebp)
    return data;
  101014:	0f b6 45 d9          	movzbl -0x27(%ebp),%eax
    // Enable rcv interrupts
    outb(COM1 + COM_IER, COM_IER_RDI);

    // Clear any preexisting overrun indications and interrupts
    // Serial port doesn't exist if COM_LSR returns 0xFF
    serial_exists = (inb(COM1 + COM_LSR) != 0xFF);
  101018:	3c ff                	cmp    $0xff,%al
  10101a:	0f 95 c0             	setne  %al
  10101d:	0f b6 c0             	movzbl %al,%eax
  101020:	a3 48 d4 11 00       	mov    %eax,0x11d448
  101025:	66 c7 45 d6 fa 03    	movw   $0x3fa,-0x2a(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  10102b:	0f b7 45 d6          	movzwl -0x2a(%ebp),%eax
  10102f:	89 c2                	mov    %eax,%edx
  101031:	ec                   	in     (%dx),%al
  101032:	88 45 d5             	mov    %al,-0x2b(%ebp)
  101035:	66 c7 45 d2 f8 03    	movw   $0x3f8,-0x2e(%ebp)
  10103b:	0f b7 45 d2          	movzwl -0x2e(%ebp),%eax
  10103f:	89 c2                	mov    %eax,%edx
  101041:	ec                   	in     (%dx),%al
  101042:	88 45 d1             	mov    %al,-0x2f(%ebp)
    (void) inb(COM1+COM_IIR);
    (void) inb(COM1+COM_RX);

    if (serial_exists) {
  101045:	a1 48 d4 11 00       	mov    0x11d448,%eax
  10104a:	85 c0                	test   %eax,%eax
  10104c:	74 0c                	je     10105a <serial_init+0xe1>
        pic_enable(IRQ_COM1);
  10104e:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  101055:	e8 d6 06 00 00       	call   101730 <pic_enable>
    }
}
  10105a:	c9                   	leave  
  10105b:	c3                   	ret    

0010105c <lpt_putc_sub>:

static void
lpt_putc_sub(int c) {
  10105c:	55                   	push   %ebp
  10105d:	89 e5                	mov    %esp,%ebp
  10105f:	83 ec 20             	sub    $0x20,%esp
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
  101062:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  101069:	eb 09                	jmp    101074 <lpt_putc_sub+0x18>
        delay();
  10106b:	e8 db fd ff ff       	call   100e4b <delay>
}

static void
lpt_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
  101070:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  101074:	66 c7 45 fa 79 03    	movw   $0x379,-0x6(%ebp)
  10107a:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
  10107e:	89 c2                	mov    %eax,%edx
  101080:	ec                   	in     (%dx),%al
  101081:	88 45 f9             	mov    %al,-0x7(%ebp)
    return data;
  101084:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
  101088:	84 c0                	test   %al,%al
  10108a:	78 09                	js     101095 <lpt_putc_sub+0x39>
  10108c:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
  101093:	7e d6                	jle    10106b <lpt_putc_sub+0xf>
        delay();
    }
    outb(LPTPORT + 0, c);
  101095:	8b 45 08             	mov    0x8(%ebp),%eax
  101098:	0f b6 c0             	movzbl %al,%eax
  10109b:	66 c7 45 f6 78 03    	movw   $0x378,-0xa(%ebp)
  1010a1:	88 45 f5             	mov    %al,-0xb(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  1010a4:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
  1010a8:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  1010ac:	ee                   	out    %al,(%dx)
  1010ad:	66 c7 45 f2 7a 03    	movw   $0x37a,-0xe(%ebp)
  1010b3:	c6 45 f1 0d          	movb   $0xd,-0xf(%ebp)
  1010b7:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
  1010bb:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  1010bf:	ee                   	out    %al,(%dx)
  1010c0:	66 c7 45 ee 7a 03    	movw   $0x37a,-0x12(%ebp)
  1010c6:	c6 45 ed 08          	movb   $0x8,-0x13(%ebp)
  1010ca:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
  1010ce:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  1010d2:	ee                   	out    %al,(%dx)
    outb(LPTPORT + 2, 0x08 | 0x04 | 0x01);
    outb(LPTPORT + 2, 0x08);
}
  1010d3:	c9                   	leave  
  1010d4:	c3                   	ret    

001010d5 <lpt_putc>:

/* lpt_putc - copy console output to parallel port */
static void
lpt_putc(int c) {
  1010d5:	55                   	push   %ebp
  1010d6:	89 e5                	mov    %esp,%ebp
  1010d8:	83 ec 04             	sub    $0x4,%esp
    if (c != '\b') {
  1010db:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
  1010df:	74 0d                	je     1010ee <lpt_putc+0x19>
        lpt_putc_sub(c);
  1010e1:	8b 45 08             	mov    0x8(%ebp),%eax
  1010e4:	89 04 24             	mov    %eax,(%esp)
  1010e7:	e8 70 ff ff ff       	call   10105c <lpt_putc_sub>
  1010ec:	eb 24                	jmp    101112 <lpt_putc+0x3d>
    }
    else {
        lpt_putc_sub('\b');
  1010ee:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  1010f5:	e8 62 ff ff ff       	call   10105c <lpt_putc_sub>
        lpt_putc_sub(' ');
  1010fa:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101101:	e8 56 ff ff ff       	call   10105c <lpt_putc_sub>
        lpt_putc_sub('\b');
  101106:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  10110d:	e8 4a ff ff ff       	call   10105c <lpt_putc_sub>
    }
}
  101112:	c9                   	leave  
  101113:	c3                   	ret    

00101114 <cga_putc>:

/* cga_putc - print character to console */
static void
cga_putc(int c) {
  101114:	55                   	push   %ebp
  101115:	89 e5                	mov    %esp,%ebp
  101117:	53                   	push   %ebx
  101118:	83 ec 34             	sub    $0x34,%esp
    // set black on white
    if (!(c & ~0xFF)) {
  10111b:	8b 45 08             	mov    0x8(%ebp),%eax
  10111e:	b0 00                	mov    $0x0,%al
  101120:	85 c0                	test   %eax,%eax
  101122:	75 07                	jne    10112b <cga_putc+0x17>
        c |= 0x0700;
  101124:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)
    }

    switch (c & 0xff) {
  10112b:	8b 45 08             	mov    0x8(%ebp),%eax
  10112e:	0f b6 c0             	movzbl %al,%eax
  101131:	83 f8 0a             	cmp    $0xa,%eax
  101134:	74 4c                	je     101182 <cga_putc+0x6e>
  101136:	83 f8 0d             	cmp    $0xd,%eax
  101139:	74 57                	je     101192 <cga_putc+0x7e>
  10113b:	83 f8 08             	cmp    $0x8,%eax
  10113e:	0f 85 88 00 00 00    	jne    1011cc <cga_putc+0xb8>
    case '\b':
        if (crt_pos > 0) {
  101144:	0f b7 05 44 d4 11 00 	movzwl 0x11d444,%eax
  10114b:	66 85 c0             	test   %ax,%ax
  10114e:	74 30                	je     101180 <cga_putc+0x6c>
            crt_pos --;
  101150:	0f b7 05 44 d4 11 00 	movzwl 0x11d444,%eax
  101157:	83 e8 01             	sub    $0x1,%eax
  10115a:	66 a3 44 d4 11 00    	mov    %ax,0x11d444
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
  101160:	a1 40 d4 11 00       	mov    0x11d440,%eax
  101165:	0f b7 15 44 d4 11 00 	movzwl 0x11d444,%edx
  10116c:	0f b7 d2             	movzwl %dx,%edx
  10116f:	01 d2                	add    %edx,%edx
  101171:	01 c2                	add    %eax,%edx
  101173:	8b 45 08             	mov    0x8(%ebp),%eax
  101176:	b0 00                	mov    $0x0,%al
  101178:	83 c8 20             	or     $0x20,%eax
  10117b:	66 89 02             	mov    %ax,(%edx)
        }
        break;
  10117e:	eb 72                	jmp    1011f2 <cga_putc+0xde>
  101180:	eb 70                	jmp    1011f2 <cga_putc+0xde>
    case '\n':
        crt_pos += CRT_COLS;
  101182:	0f b7 05 44 d4 11 00 	movzwl 0x11d444,%eax
  101189:	83 c0 50             	add    $0x50,%eax
  10118c:	66 a3 44 d4 11 00    	mov    %ax,0x11d444
    case '\r':
        crt_pos -= (crt_pos % CRT_COLS);
  101192:	0f b7 1d 44 d4 11 00 	movzwl 0x11d444,%ebx
  101199:	0f b7 0d 44 d4 11 00 	movzwl 0x11d444,%ecx
  1011a0:	0f b7 c1             	movzwl %cx,%eax
  1011a3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  1011a9:	c1 e8 10             	shr    $0x10,%eax
  1011ac:	89 c2                	mov    %eax,%edx
  1011ae:	66 c1 ea 06          	shr    $0x6,%dx
  1011b2:	89 d0                	mov    %edx,%eax
  1011b4:	c1 e0 02             	shl    $0x2,%eax
  1011b7:	01 d0                	add    %edx,%eax
  1011b9:	c1 e0 04             	shl    $0x4,%eax
  1011bc:	29 c1                	sub    %eax,%ecx
  1011be:	89 ca                	mov    %ecx,%edx
  1011c0:	89 d8                	mov    %ebx,%eax
  1011c2:	29 d0                	sub    %edx,%eax
  1011c4:	66 a3 44 d4 11 00    	mov    %ax,0x11d444
        break;
  1011ca:	eb 26                	jmp    1011f2 <cga_putc+0xde>
    default:
        crt_buf[crt_pos ++] = c;     // write the character
  1011cc:	8b 0d 40 d4 11 00    	mov    0x11d440,%ecx
  1011d2:	0f b7 05 44 d4 11 00 	movzwl 0x11d444,%eax
  1011d9:	8d 50 01             	lea    0x1(%eax),%edx
  1011dc:	66 89 15 44 d4 11 00 	mov    %dx,0x11d444
  1011e3:	0f b7 c0             	movzwl %ax,%eax
  1011e6:	01 c0                	add    %eax,%eax
  1011e8:	8d 14 01             	lea    (%ecx,%eax,1),%edx
  1011eb:	8b 45 08             	mov    0x8(%ebp),%eax
  1011ee:	66 89 02             	mov    %ax,(%edx)
        break;
  1011f1:	90                   	nop
    }

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
  1011f2:	0f b7 05 44 d4 11 00 	movzwl 0x11d444,%eax
  1011f9:	66 3d cf 07          	cmp    $0x7cf,%ax
  1011fd:	76 5b                	jbe    10125a <cga_putc+0x146>
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
  1011ff:	a1 40 d4 11 00       	mov    0x11d440,%eax
  101204:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  10120a:	a1 40 d4 11 00       	mov    0x11d440,%eax
  10120f:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  101216:	00 
  101217:	89 54 24 04          	mov    %edx,0x4(%esp)
  10121b:	89 04 24             	mov    %eax,(%esp)
  10121e:	e8 83 5f 00 00       	call   1071a6 <memmove>
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
  101223:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
  10122a:	eb 15                	jmp    101241 <cga_putc+0x12d>
            crt_buf[i] = 0x0700 | ' ';
  10122c:	a1 40 d4 11 00       	mov    0x11d440,%eax
  101231:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101234:	01 d2                	add    %edx,%edx
  101236:	01 d0                	add    %edx,%eax
  101238:	66 c7 00 20 07       	movw   $0x720,(%eax)

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
  10123d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  101241:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
  101248:	7e e2                	jle    10122c <cga_putc+0x118>
            crt_buf[i] = 0x0700 | ' ';
        }
        crt_pos -= CRT_COLS;
  10124a:	0f b7 05 44 d4 11 00 	movzwl 0x11d444,%eax
  101251:	83 e8 50             	sub    $0x50,%eax
  101254:	66 a3 44 d4 11 00    	mov    %ax,0x11d444
    }

    // move that little blinky thing
    outb(addr_6845, 14);
  10125a:	0f b7 05 46 d4 11 00 	movzwl 0x11d446,%eax
  101261:	0f b7 c0             	movzwl %ax,%eax
  101264:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
  101268:	c6 45 f1 0e          	movb   $0xe,-0xf(%ebp)
  10126c:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
  101270:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  101274:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos >> 8);
  101275:	0f b7 05 44 d4 11 00 	movzwl 0x11d444,%eax
  10127c:	66 c1 e8 08          	shr    $0x8,%ax
  101280:	0f b6 c0             	movzbl %al,%eax
  101283:	0f b7 15 46 d4 11 00 	movzwl 0x11d446,%edx
  10128a:	83 c2 01             	add    $0x1,%edx
  10128d:	0f b7 d2             	movzwl %dx,%edx
  101290:	66 89 55 ee          	mov    %dx,-0x12(%ebp)
  101294:	88 45 ed             	mov    %al,-0x13(%ebp)
  101297:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
  10129b:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  10129f:	ee                   	out    %al,(%dx)
    outb(addr_6845, 15);
  1012a0:	0f b7 05 46 d4 11 00 	movzwl 0x11d446,%eax
  1012a7:	0f b7 c0             	movzwl %ax,%eax
  1012aa:	66 89 45 ea          	mov    %ax,-0x16(%ebp)
  1012ae:	c6 45 e9 0f          	movb   $0xf,-0x17(%ebp)
  1012b2:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
  1012b6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
  1012ba:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos);
  1012bb:	0f b7 05 44 d4 11 00 	movzwl 0x11d444,%eax
  1012c2:	0f b6 c0             	movzbl %al,%eax
  1012c5:	0f b7 15 46 d4 11 00 	movzwl 0x11d446,%edx
  1012cc:	83 c2 01             	add    $0x1,%edx
  1012cf:	0f b7 d2             	movzwl %dx,%edx
  1012d2:	66 89 55 e6          	mov    %dx,-0x1a(%ebp)
  1012d6:	88 45 e5             	mov    %al,-0x1b(%ebp)
  1012d9:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
  1012dd:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
  1012e1:	ee                   	out    %al,(%dx)
}
  1012e2:	83 c4 34             	add    $0x34,%esp
  1012e5:	5b                   	pop    %ebx
  1012e6:	5d                   	pop    %ebp
  1012e7:	c3                   	ret    

001012e8 <serial_putc_sub>:

static void
serial_putc_sub(int c) {
  1012e8:	55                   	push   %ebp
  1012e9:	89 e5                	mov    %esp,%ebp
  1012eb:	83 ec 10             	sub    $0x10,%esp
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
  1012ee:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1012f5:	eb 09                	jmp    101300 <serial_putc_sub+0x18>
        delay();
  1012f7:	e8 4f fb ff ff       	call   100e4b <delay>
}

static void
serial_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
  1012fc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  101300:	66 c7 45 fa fd 03    	movw   $0x3fd,-0x6(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  101306:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
  10130a:	89 c2                	mov    %eax,%edx
  10130c:	ec                   	in     (%dx),%al
  10130d:	88 45 f9             	mov    %al,-0x7(%ebp)
    return data;
  101310:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
  101314:	0f b6 c0             	movzbl %al,%eax
  101317:	83 e0 20             	and    $0x20,%eax
  10131a:	85 c0                	test   %eax,%eax
  10131c:	75 09                	jne    101327 <serial_putc_sub+0x3f>
  10131e:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
  101325:	7e d0                	jle    1012f7 <serial_putc_sub+0xf>
        delay();
    }
    outb(COM1 + COM_TX, c);
  101327:	8b 45 08             	mov    0x8(%ebp),%eax
  10132a:	0f b6 c0             	movzbl %al,%eax
  10132d:	66 c7 45 f6 f8 03    	movw   $0x3f8,-0xa(%ebp)
  101333:	88 45 f5             	mov    %al,-0xb(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  101336:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
  10133a:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  10133e:	ee                   	out    %al,(%dx)
}
  10133f:	c9                   	leave  
  101340:	c3                   	ret    

00101341 <serial_putc>:

/* serial_putc - print character to serial port */
static void
serial_putc(int c) {
  101341:	55                   	push   %ebp
  101342:	89 e5                	mov    %esp,%ebp
  101344:	83 ec 04             	sub    $0x4,%esp
    if (c != '\b') {
  101347:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
  10134b:	74 0d                	je     10135a <serial_putc+0x19>
        serial_putc_sub(c);
  10134d:	8b 45 08             	mov    0x8(%ebp),%eax
  101350:	89 04 24             	mov    %eax,(%esp)
  101353:	e8 90 ff ff ff       	call   1012e8 <serial_putc_sub>
  101358:	eb 24                	jmp    10137e <serial_putc+0x3d>
    }
    else {
        serial_putc_sub('\b');
  10135a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  101361:	e8 82 ff ff ff       	call   1012e8 <serial_putc_sub>
        serial_putc_sub(' ');
  101366:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10136d:	e8 76 ff ff ff       	call   1012e8 <serial_putc_sub>
        serial_putc_sub('\b');
  101372:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  101379:	e8 6a ff ff ff       	call   1012e8 <serial_putc_sub>
    }
}
  10137e:	c9                   	leave  
  10137f:	c3                   	ret    

00101380 <cons_intr>:
/* *
 * cons_intr - called by device interrupt routines to feed input
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
  101380:	55                   	push   %ebp
  101381:	89 e5                	mov    %esp,%ebp
  101383:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = (*proc)()) != -1) {
  101386:	eb 33                	jmp    1013bb <cons_intr+0x3b>
        if (c != 0) {
  101388:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10138c:	74 2d                	je     1013bb <cons_intr+0x3b>
            cons.buf[cons.wpos ++] = c;
  10138e:	a1 64 d6 11 00       	mov    0x11d664,%eax
  101393:	8d 50 01             	lea    0x1(%eax),%edx
  101396:	89 15 64 d6 11 00    	mov    %edx,0x11d664
  10139c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10139f:	88 90 60 d4 11 00    	mov    %dl,0x11d460(%eax)
            if (cons.wpos == CONSBUFSIZE) {
  1013a5:	a1 64 d6 11 00       	mov    0x11d664,%eax
  1013aa:	3d 00 02 00 00       	cmp    $0x200,%eax
  1013af:	75 0a                	jne    1013bb <cons_intr+0x3b>
                cons.wpos = 0;
  1013b1:	c7 05 64 d6 11 00 00 	movl   $0x0,0x11d664
  1013b8:	00 00 00 
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
    int c;
    while ((c = (*proc)()) != -1) {
  1013bb:	8b 45 08             	mov    0x8(%ebp),%eax
  1013be:	ff d0                	call   *%eax
  1013c0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1013c3:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  1013c7:	75 bf                	jne    101388 <cons_intr+0x8>
            if (cons.wpos == CONSBUFSIZE) {
                cons.wpos = 0;
            }
        }
    }
}
  1013c9:	c9                   	leave  
  1013ca:	c3                   	ret    

001013cb <serial_proc_data>:

/* serial_proc_data - get data from serial port */
static int
serial_proc_data(void) {
  1013cb:	55                   	push   %ebp
  1013cc:	89 e5                	mov    %esp,%ebp
  1013ce:	83 ec 10             	sub    $0x10,%esp
  1013d1:	66 c7 45 fa fd 03    	movw   $0x3fd,-0x6(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  1013d7:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
  1013db:	89 c2                	mov    %eax,%edx
  1013dd:	ec                   	in     (%dx),%al
  1013de:	88 45 f9             	mov    %al,-0x7(%ebp)
    return data;
  1013e1:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
    if (!(inb(COM1 + COM_LSR) & COM_LSR_DATA)) {
  1013e5:	0f b6 c0             	movzbl %al,%eax
  1013e8:	83 e0 01             	and    $0x1,%eax
  1013eb:	85 c0                	test   %eax,%eax
  1013ed:	75 07                	jne    1013f6 <serial_proc_data+0x2b>
        return -1;
  1013ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1013f4:	eb 2a                	jmp    101420 <serial_proc_data+0x55>
  1013f6:	66 c7 45 f6 f8 03    	movw   $0x3f8,-0xa(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  1013fc:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  101400:	89 c2                	mov    %eax,%edx
  101402:	ec                   	in     (%dx),%al
  101403:	88 45 f5             	mov    %al,-0xb(%ebp)
    return data;
  101406:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
    }
    int c = inb(COM1 + COM_RX);
  10140a:	0f b6 c0             	movzbl %al,%eax
  10140d:	89 45 fc             	mov    %eax,-0x4(%ebp)
    if (c == 127) {
  101410:	83 7d fc 7f          	cmpl   $0x7f,-0x4(%ebp)
  101414:	75 07                	jne    10141d <serial_proc_data+0x52>
        c = '\b';
  101416:	c7 45 fc 08 00 00 00 	movl   $0x8,-0x4(%ebp)
    }
    return c;
  10141d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  101420:	c9                   	leave  
  101421:	c3                   	ret    

00101422 <serial_intr>:

/* serial_intr - try to feed input characters from serial port */
void
serial_intr(void) {
  101422:	55                   	push   %ebp
  101423:	89 e5                	mov    %esp,%ebp
  101425:	83 ec 18             	sub    $0x18,%esp
    if (serial_exists) {
  101428:	a1 48 d4 11 00       	mov    0x11d448,%eax
  10142d:	85 c0                	test   %eax,%eax
  10142f:	74 0c                	je     10143d <serial_intr+0x1b>
        cons_intr(serial_proc_data);
  101431:	c7 04 24 cb 13 10 00 	movl   $0x1013cb,(%esp)
  101438:	e8 43 ff ff ff       	call   101380 <cons_intr>
    }
}
  10143d:	c9                   	leave  
  10143e:	c3                   	ret    

0010143f <kbd_proc_data>:
 *
 * The kbd_proc_data() function gets data from the keyboard.
 * If we finish a character, return it, else 0. And return -1 if no data.
 * */
static int
kbd_proc_data(void) {
  10143f:	55                   	push   %ebp
  101440:	89 e5                	mov    %esp,%ebp
  101442:	83 ec 38             	sub    $0x38,%esp
  101445:	66 c7 45 f0 64 00    	movw   $0x64,-0x10(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  10144b:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
  10144f:	89 c2                	mov    %eax,%edx
  101451:	ec                   	in     (%dx),%al
  101452:	88 45 ef             	mov    %al,-0x11(%ebp)
    return data;
  101455:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
    int c;
    uint8_t data;
    static uint32_t shift;

    if ((inb(KBSTATP) & KBS_DIB) == 0) {
  101459:	0f b6 c0             	movzbl %al,%eax
  10145c:	83 e0 01             	and    $0x1,%eax
  10145f:	85 c0                	test   %eax,%eax
  101461:	75 0a                	jne    10146d <kbd_proc_data+0x2e>
        return -1;
  101463:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101468:	e9 59 01 00 00       	jmp    1015c6 <kbd_proc_data+0x187>
  10146d:	66 c7 45 ec 60 00    	movw   $0x60,-0x14(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  101473:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  101477:	89 c2                	mov    %eax,%edx
  101479:	ec                   	in     (%dx),%al
  10147a:	88 45 eb             	mov    %al,-0x15(%ebp)
    return data;
  10147d:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
    }

    data = inb(KBDATAP);
  101481:	88 45 f3             	mov    %al,-0xd(%ebp)

    if (data == 0xE0) {
  101484:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
  101488:	75 17                	jne    1014a1 <kbd_proc_data+0x62>
        // E0 escape character
        shift |= E0ESC;
  10148a:	a1 68 d6 11 00       	mov    0x11d668,%eax
  10148f:	83 c8 40             	or     $0x40,%eax
  101492:	a3 68 d6 11 00       	mov    %eax,0x11d668
        return 0;
  101497:	b8 00 00 00 00       	mov    $0x0,%eax
  10149c:	e9 25 01 00 00       	jmp    1015c6 <kbd_proc_data+0x187>
    } else if (data & 0x80) {
  1014a1:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1014a5:	84 c0                	test   %al,%al
  1014a7:	79 47                	jns    1014f0 <kbd_proc_data+0xb1>
        // Key released
        data = (shift & E0ESC ? data : data & 0x7F);
  1014a9:	a1 68 d6 11 00       	mov    0x11d668,%eax
  1014ae:	83 e0 40             	and    $0x40,%eax
  1014b1:	85 c0                	test   %eax,%eax
  1014b3:	75 09                	jne    1014be <kbd_proc_data+0x7f>
  1014b5:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1014b9:	83 e0 7f             	and    $0x7f,%eax
  1014bc:	eb 04                	jmp    1014c2 <kbd_proc_data+0x83>
  1014be:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1014c2:	88 45 f3             	mov    %al,-0xd(%ebp)
        shift &= ~(shiftcode[data] | E0ESC);
  1014c5:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1014c9:	0f b6 80 40 a0 11 00 	movzbl 0x11a040(%eax),%eax
  1014d0:	83 c8 40             	or     $0x40,%eax
  1014d3:	0f b6 c0             	movzbl %al,%eax
  1014d6:	f7 d0                	not    %eax
  1014d8:	89 c2                	mov    %eax,%edx
  1014da:	a1 68 d6 11 00       	mov    0x11d668,%eax
  1014df:	21 d0                	and    %edx,%eax
  1014e1:	a3 68 d6 11 00       	mov    %eax,0x11d668
        return 0;
  1014e6:	b8 00 00 00 00       	mov    $0x0,%eax
  1014eb:	e9 d6 00 00 00       	jmp    1015c6 <kbd_proc_data+0x187>
    } else if (shift & E0ESC) {
  1014f0:	a1 68 d6 11 00       	mov    0x11d668,%eax
  1014f5:	83 e0 40             	and    $0x40,%eax
  1014f8:	85 c0                	test   %eax,%eax
  1014fa:	74 11                	je     10150d <kbd_proc_data+0xce>
        // Last character was an E0 escape; or with 0x80
        data |= 0x80;
  1014fc:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
        shift &= ~E0ESC;
  101500:	a1 68 d6 11 00       	mov    0x11d668,%eax
  101505:	83 e0 bf             	and    $0xffffffbf,%eax
  101508:	a3 68 d6 11 00       	mov    %eax,0x11d668
    }

    shift |= shiftcode[data];
  10150d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101511:	0f b6 80 40 a0 11 00 	movzbl 0x11a040(%eax),%eax
  101518:	0f b6 d0             	movzbl %al,%edx
  10151b:	a1 68 d6 11 00       	mov    0x11d668,%eax
  101520:	09 d0                	or     %edx,%eax
  101522:	a3 68 d6 11 00       	mov    %eax,0x11d668
    shift ^= togglecode[data];
  101527:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10152b:	0f b6 80 40 a1 11 00 	movzbl 0x11a140(%eax),%eax
  101532:	0f b6 d0             	movzbl %al,%edx
  101535:	a1 68 d6 11 00       	mov    0x11d668,%eax
  10153a:	31 d0                	xor    %edx,%eax
  10153c:	a3 68 d6 11 00       	mov    %eax,0x11d668

    c = charcode[shift & (CTL | SHIFT)][data];
  101541:	a1 68 d6 11 00       	mov    0x11d668,%eax
  101546:	83 e0 03             	and    $0x3,%eax
  101549:	8b 14 85 40 a5 11 00 	mov    0x11a540(,%eax,4),%edx
  101550:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101554:	01 d0                	add    %edx,%eax
  101556:	0f b6 00             	movzbl (%eax),%eax
  101559:	0f b6 c0             	movzbl %al,%eax
  10155c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (shift & CAPSLOCK) {
  10155f:	a1 68 d6 11 00       	mov    0x11d668,%eax
  101564:	83 e0 08             	and    $0x8,%eax
  101567:	85 c0                	test   %eax,%eax
  101569:	74 22                	je     10158d <kbd_proc_data+0x14e>
        if ('a' <= c && c <= 'z')
  10156b:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
  10156f:	7e 0c                	jle    10157d <kbd_proc_data+0x13e>
  101571:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
  101575:	7f 06                	jg     10157d <kbd_proc_data+0x13e>
            c += 'A' - 'a';
  101577:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
  10157b:	eb 10                	jmp    10158d <kbd_proc_data+0x14e>
        else if ('A' <= c && c <= 'Z')
  10157d:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
  101581:	7e 0a                	jle    10158d <kbd_proc_data+0x14e>
  101583:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
  101587:	7f 04                	jg     10158d <kbd_proc_data+0x14e>
            c += 'a' - 'A';
  101589:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
    }

    // Process special keys
    // Ctrl-Alt-Del: reboot
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  10158d:	a1 68 d6 11 00       	mov    0x11d668,%eax
  101592:	f7 d0                	not    %eax
  101594:	83 e0 06             	and    $0x6,%eax
  101597:	85 c0                	test   %eax,%eax
  101599:	75 28                	jne    1015c3 <kbd_proc_data+0x184>
  10159b:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
  1015a2:	75 1f                	jne    1015c3 <kbd_proc_data+0x184>
        cprintf("Rebooting!\n");
  1015a4:	c7 04 24 37 76 10 00 	movl   $0x107637,(%esp)
  1015ab:	e8 a4 ed ff ff       	call   100354 <cprintf>
  1015b0:	66 c7 45 e8 92 00    	movw   $0x92,-0x18(%ebp)
  1015b6:	c6 45 e7 03          	movb   $0x3,-0x19(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  1015ba:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  1015be:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
  1015c2:	ee                   	out    %al,(%dx)
        outb(0x92, 0x3); // courtesy of Chris Frost
    }
    return c;
  1015c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1015c6:	c9                   	leave  
  1015c7:	c3                   	ret    

001015c8 <kbd_intr>:

/* kbd_intr - try to feed input characters from keyboard */
static void
kbd_intr(void) {
  1015c8:	55                   	push   %ebp
  1015c9:	89 e5                	mov    %esp,%ebp
  1015cb:	83 ec 18             	sub    $0x18,%esp
    cons_intr(kbd_proc_data);
  1015ce:	c7 04 24 3f 14 10 00 	movl   $0x10143f,(%esp)
  1015d5:	e8 a6 fd ff ff       	call   101380 <cons_intr>
}
  1015da:	c9                   	leave  
  1015db:	c3                   	ret    

001015dc <kbd_init>:

static void
kbd_init(void) {
  1015dc:	55                   	push   %ebp
  1015dd:	89 e5                	mov    %esp,%ebp
  1015df:	83 ec 18             	sub    $0x18,%esp
    // drain the kbd buffer
    kbd_intr();
  1015e2:	e8 e1 ff ff ff       	call   1015c8 <kbd_intr>
    pic_enable(IRQ_KBD);
  1015e7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1015ee:	e8 3d 01 00 00       	call   101730 <pic_enable>
}
  1015f3:	c9                   	leave  
  1015f4:	c3                   	ret    

001015f5 <cons_init>:

/* cons_init - initializes the console devices */
void
cons_init(void) {
  1015f5:	55                   	push   %ebp
  1015f6:	89 e5                	mov    %esp,%ebp
  1015f8:	83 ec 18             	sub    $0x18,%esp
    cga_init();
  1015fb:	e8 93 f8 ff ff       	call   100e93 <cga_init>
    serial_init();
  101600:	e8 74 f9 ff ff       	call   100f79 <serial_init>
    kbd_init();
  101605:	e8 d2 ff ff ff       	call   1015dc <kbd_init>
    if (!serial_exists) {
  10160a:	a1 48 d4 11 00       	mov    0x11d448,%eax
  10160f:	85 c0                	test   %eax,%eax
  101611:	75 0c                	jne    10161f <cons_init+0x2a>
        cprintf("serial port does not exist!!\n");
  101613:	c7 04 24 43 76 10 00 	movl   $0x107643,(%esp)
  10161a:	e8 35 ed ff ff       	call   100354 <cprintf>
    }
}
  10161f:	c9                   	leave  
  101620:	c3                   	ret    

00101621 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void
cons_putc(int c) {
  101621:	55                   	push   %ebp
  101622:	89 e5                	mov    %esp,%ebp
  101624:	83 ec 28             	sub    $0x28,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
  101627:	e8 e2 f7 ff ff       	call   100e0e <__intr_save>
  10162c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        lpt_putc(c);
  10162f:	8b 45 08             	mov    0x8(%ebp),%eax
  101632:	89 04 24             	mov    %eax,(%esp)
  101635:	e8 9b fa ff ff       	call   1010d5 <lpt_putc>
        cga_putc(c);
  10163a:	8b 45 08             	mov    0x8(%ebp),%eax
  10163d:	89 04 24             	mov    %eax,(%esp)
  101640:	e8 cf fa ff ff       	call   101114 <cga_putc>
        serial_putc(c);
  101645:	8b 45 08             	mov    0x8(%ebp),%eax
  101648:	89 04 24             	mov    %eax,(%esp)
  10164b:	e8 f1 fc ff ff       	call   101341 <serial_putc>
    }
    local_intr_restore(intr_flag);
  101650:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101653:	89 04 24             	mov    %eax,(%esp)
  101656:	e8 dd f7 ff ff       	call   100e38 <__intr_restore>
}
  10165b:	c9                   	leave  
  10165c:	c3                   	ret    

0010165d <cons_getc>:
/* *
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int
cons_getc(void) {
  10165d:	55                   	push   %ebp
  10165e:	89 e5                	mov    %esp,%ebp
  101660:	83 ec 28             	sub    $0x28,%esp
    int c = 0;
  101663:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
  10166a:	e8 9f f7 ff ff       	call   100e0e <__intr_save>
  10166f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        // poll for any pending input characters,
        // so that this function works even when interrupts are disabled
        // (e.g., when called from the kernel monitor).
        serial_intr();
  101672:	e8 ab fd ff ff       	call   101422 <serial_intr>
        kbd_intr();
  101677:	e8 4c ff ff ff       	call   1015c8 <kbd_intr>

        // grab the next character from the input buffer.
        if (cons.rpos != cons.wpos) {
  10167c:	8b 15 60 d6 11 00    	mov    0x11d660,%edx
  101682:	a1 64 d6 11 00       	mov    0x11d664,%eax
  101687:	39 c2                	cmp    %eax,%edx
  101689:	74 31                	je     1016bc <cons_getc+0x5f>
            c = cons.buf[cons.rpos ++];
  10168b:	a1 60 d6 11 00       	mov    0x11d660,%eax
  101690:	8d 50 01             	lea    0x1(%eax),%edx
  101693:	89 15 60 d6 11 00    	mov    %edx,0x11d660
  101699:	0f b6 80 60 d4 11 00 	movzbl 0x11d460(%eax),%eax
  1016a0:	0f b6 c0             	movzbl %al,%eax
  1016a3:	89 45 f4             	mov    %eax,-0xc(%ebp)
            if (cons.rpos == CONSBUFSIZE) {
  1016a6:	a1 60 d6 11 00       	mov    0x11d660,%eax
  1016ab:	3d 00 02 00 00       	cmp    $0x200,%eax
  1016b0:	75 0a                	jne    1016bc <cons_getc+0x5f>
                cons.rpos = 0;
  1016b2:	c7 05 60 d6 11 00 00 	movl   $0x0,0x11d660
  1016b9:	00 00 00 
            }
        }
    }
    local_intr_restore(intr_flag);
  1016bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1016bf:	89 04 24             	mov    %eax,(%esp)
  1016c2:	e8 71 f7 ff ff       	call   100e38 <__intr_restore>
    return c;
  1016c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1016ca:	c9                   	leave  
  1016cb:	c3                   	ret    

001016cc <intr_enable>:
#include <x86.h>
#include <intr.h>

/* intr_enable - enable irq interrupt */
void
intr_enable(void) {
  1016cc:	55                   	push   %ebp
  1016cd:	89 e5                	mov    %esp,%ebp
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
}

static inline void
sti(void) {
    asm volatile ("sti");
  1016cf:	fb                   	sti    
    sti();
}
  1016d0:	5d                   	pop    %ebp
  1016d1:	c3                   	ret    

001016d2 <intr_disable>:

/* intr_disable - disable irq interrupt */
void
intr_disable(void) {
  1016d2:	55                   	push   %ebp
  1016d3:	89 e5                	mov    %esp,%ebp
}

static inline void
cli(void) {
    asm volatile ("cli" ::: "memory");
  1016d5:	fa                   	cli    
    cli();
}
  1016d6:	5d                   	pop    %ebp
  1016d7:	c3                   	ret    

001016d8 <pic_setmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static uint16_t irq_mask = 0xFFFF & ~(1 << IRQ_SLAVE);
static bool did_init = 0;

static void
pic_setmask(uint16_t mask) {
  1016d8:	55                   	push   %ebp
  1016d9:	89 e5                	mov    %esp,%ebp
  1016db:	83 ec 14             	sub    $0x14,%esp
  1016de:	8b 45 08             	mov    0x8(%ebp),%eax
  1016e1:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
    irq_mask = mask;
  1016e5:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1016e9:	66 a3 50 a5 11 00    	mov    %ax,0x11a550
    if (did_init) {
  1016ef:	a1 6c d6 11 00       	mov    0x11d66c,%eax
  1016f4:	85 c0                	test   %eax,%eax
  1016f6:	74 36                	je     10172e <pic_setmask+0x56>
        outb(IO_PIC1 + 1, mask);
  1016f8:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1016fc:	0f b6 c0             	movzbl %al,%eax
  1016ff:	66 c7 45 fe 21 00    	movw   $0x21,-0x2(%ebp)
  101705:	88 45 fd             	mov    %al,-0x3(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  101708:	0f b6 45 fd          	movzbl -0x3(%ebp),%eax
  10170c:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
  101710:	ee                   	out    %al,(%dx)
        outb(IO_PIC2 + 1, mask >> 8);
  101711:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  101715:	66 c1 e8 08          	shr    $0x8,%ax
  101719:	0f b6 c0             	movzbl %al,%eax
  10171c:	66 c7 45 fa a1 00    	movw   $0xa1,-0x6(%ebp)
  101722:	88 45 f9             	mov    %al,-0x7(%ebp)
  101725:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
  101729:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
  10172d:	ee                   	out    %al,(%dx)
    }
}
  10172e:	c9                   	leave  
  10172f:	c3                   	ret    

00101730 <pic_enable>:

void
pic_enable(unsigned int irq) {
  101730:	55                   	push   %ebp
  101731:	89 e5                	mov    %esp,%ebp
  101733:	83 ec 04             	sub    $0x4,%esp
    pic_setmask(irq_mask & ~(1 << irq));
  101736:	8b 45 08             	mov    0x8(%ebp),%eax
  101739:	ba 01 00 00 00       	mov    $0x1,%edx
  10173e:	89 c1                	mov    %eax,%ecx
  101740:	d3 e2                	shl    %cl,%edx
  101742:	89 d0                	mov    %edx,%eax
  101744:	f7 d0                	not    %eax
  101746:	89 c2                	mov    %eax,%edx
  101748:	0f b7 05 50 a5 11 00 	movzwl 0x11a550,%eax
  10174f:	21 d0                	and    %edx,%eax
  101751:	0f b7 c0             	movzwl %ax,%eax
  101754:	89 04 24             	mov    %eax,(%esp)
  101757:	e8 7c ff ff ff       	call   1016d8 <pic_setmask>
}
  10175c:	c9                   	leave  
  10175d:	c3                   	ret    

0010175e <pic_init>:

/* pic_init - initialize the 8259A interrupt controllers */
void
pic_init(void) {
  10175e:	55                   	push   %ebp
  10175f:	89 e5                	mov    %esp,%ebp
  101761:	83 ec 44             	sub    $0x44,%esp
    did_init = 1;
  101764:	c7 05 6c d6 11 00 01 	movl   $0x1,0x11d66c
  10176b:	00 00 00 
  10176e:	66 c7 45 fe 21 00    	movw   $0x21,-0x2(%ebp)
  101774:	c6 45 fd ff          	movb   $0xff,-0x3(%ebp)
  101778:	0f b6 45 fd          	movzbl -0x3(%ebp),%eax
  10177c:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
  101780:	ee                   	out    %al,(%dx)
  101781:	66 c7 45 fa a1 00    	movw   $0xa1,-0x6(%ebp)
  101787:	c6 45 f9 ff          	movb   $0xff,-0x7(%ebp)
  10178b:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
  10178f:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
  101793:	ee                   	out    %al,(%dx)
  101794:	66 c7 45 f6 20 00    	movw   $0x20,-0xa(%ebp)
  10179a:	c6 45 f5 11          	movb   $0x11,-0xb(%ebp)
  10179e:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
  1017a2:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  1017a6:	ee                   	out    %al,(%dx)
  1017a7:	66 c7 45 f2 21 00    	movw   $0x21,-0xe(%ebp)
  1017ad:	c6 45 f1 20          	movb   $0x20,-0xf(%ebp)
  1017b1:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
  1017b5:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  1017b9:	ee                   	out    %al,(%dx)
  1017ba:	66 c7 45 ee 21 00    	movw   $0x21,-0x12(%ebp)
  1017c0:	c6 45 ed 04          	movb   $0x4,-0x13(%ebp)
  1017c4:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
  1017c8:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  1017cc:	ee                   	out    %al,(%dx)
  1017cd:	66 c7 45 ea 21 00    	movw   $0x21,-0x16(%ebp)
  1017d3:	c6 45 e9 03          	movb   $0x3,-0x17(%ebp)
  1017d7:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
  1017db:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
  1017df:	ee                   	out    %al,(%dx)
  1017e0:	66 c7 45 e6 a0 00    	movw   $0xa0,-0x1a(%ebp)
  1017e6:	c6 45 e5 11          	movb   $0x11,-0x1b(%ebp)
  1017ea:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
  1017ee:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
  1017f2:	ee                   	out    %al,(%dx)
  1017f3:	66 c7 45 e2 a1 00    	movw   $0xa1,-0x1e(%ebp)
  1017f9:	c6 45 e1 28          	movb   $0x28,-0x1f(%ebp)
  1017fd:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
  101801:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
  101805:	ee                   	out    %al,(%dx)
  101806:	66 c7 45 de a1 00    	movw   $0xa1,-0x22(%ebp)
  10180c:	c6 45 dd 02          	movb   $0x2,-0x23(%ebp)
  101810:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
  101814:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  101818:	ee                   	out    %al,(%dx)
  101819:	66 c7 45 da a1 00    	movw   $0xa1,-0x26(%ebp)
  10181f:	c6 45 d9 03          	movb   $0x3,-0x27(%ebp)
  101823:	0f b6 45 d9          	movzbl -0x27(%ebp),%eax
  101827:	0f b7 55 da          	movzwl -0x26(%ebp),%edx
  10182b:	ee                   	out    %al,(%dx)
  10182c:	66 c7 45 d6 20 00    	movw   $0x20,-0x2a(%ebp)
  101832:	c6 45 d5 68          	movb   $0x68,-0x2b(%ebp)
  101836:	0f b6 45 d5          	movzbl -0x2b(%ebp),%eax
  10183a:	0f b7 55 d6          	movzwl -0x2a(%ebp),%edx
  10183e:	ee                   	out    %al,(%dx)
  10183f:	66 c7 45 d2 20 00    	movw   $0x20,-0x2e(%ebp)
  101845:	c6 45 d1 0a          	movb   $0xa,-0x2f(%ebp)
  101849:	0f b6 45 d1          	movzbl -0x2f(%ebp),%eax
  10184d:	0f b7 55 d2          	movzwl -0x2e(%ebp),%edx
  101851:	ee                   	out    %al,(%dx)
  101852:	66 c7 45 ce a0 00    	movw   $0xa0,-0x32(%ebp)
  101858:	c6 45 cd 68          	movb   $0x68,-0x33(%ebp)
  10185c:	0f b6 45 cd          	movzbl -0x33(%ebp),%eax
  101860:	0f b7 55 ce          	movzwl -0x32(%ebp),%edx
  101864:	ee                   	out    %al,(%dx)
  101865:	66 c7 45 ca a0 00    	movw   $0xa0,-0x36(%ebp)
  10186b:	c6 45 c9 0a          	movb   $0xa,-0x37(%ebp)
  10186f:	0f b6 45 c9          	movzbl -0x37(%ebp),%eax
  101873:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
  101877:	ee                   	out    %al,(%dx)
    outb(IO_PIC1, 0x0a);    // read IRR by default

    outb(IO_PIC2, 0x68);    // OCW3
    outb(IO_PIC2, 0x0a);    // OCW3

    if (irq_mask != 0xFFFF) {
  101878:	0f b7 05 50 a5 11 00 	movzwl 0x11a550,%eax
  10187f:	66 83 f8 ff          	cmp    $0xffff,%ax
  101883:	74 12                	je     101897 <pic_init+0x139>
        pic_setmask(irq_mask);
  101885:	0f b7 05 50 a5 11 00 	movzwl 0x11a550,%eax
  10188c:	0f b7 c0             	movzwl %ax,%eax
  10188f:	89 04 24             	mov    %eax,(%esp)
  101892:	e8 41 fe ff ff       	call   1016d8 <pic_setmask>
    }
}
  101897:	c9                   	leave  
  101898:	c3                   	ret    

00101899 <print_ticks>:
#include <console.h>
#include <kdebug.h>

#define TICK_NUM 100

static void print_ticks() {
  101899:	55                   	push   %ebp
  10189a:	89 e5                	mov    %esp,%ebp
  10189c:	83 ec 18             	sub    $0x18,%esp
    cprintf("%d ticks\n",TICK_NUM);
  10189f:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  1018a6:	00 
  1018a7:	c7 04 24 80 76 10 00 	movl   $0x107680,(%esp)
  1018ae:	e8 a1 ea ff ff       	call   100354 <cprintf>
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}
  1018b3:	c9                   	leave  
  1018b4:	c3                   	ret    

001018b5 <idt_init>:
    sizeof(idt) - 1, (uintptr_t)idt
};

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S */
void
idt_init(void) {
  1018b5:	55                   	push   %ebp
  1018b6:	89 e5                	mov    %esp,%ebp
  1018b8:	83 ec 10             	sub    $0x10,%esp
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
    extern uintptr_t __vectors[];
    int i;
    for (i = 0; i < 256; i++) {
  1018bb:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1018c2:	e9 c3 00 00 00       	jmp    10198a <idt_init+0xd5>
        SETGATE(idt[i], 0, GD_KTEXT, __vectors[i], DPL_KERNEL);
  1018c7:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1018ca:	8b 04 85 e0 a5 11 00 	mov    0x11a5e0(,%eax,4),%eax
  1018d1:	89 c2                	mov    %eax,%edx
  1018d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1018d6:	66 89 14 c5 80 d6 11 	mov    %dx,0x11d680(,%eax,8)
  1018dd:	00 
  1018de:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1018e1:	66 c7 04 c5 82 d6 11 	movw   $0x8,0x11d682(,%eax,8)
  1018e8:	00 08 00 
  1018eb:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1018ee:	0f b6 14 c5 84 d6 11 	movzbl 0x11d684(,%eax,8),%edx
  1018f5:	00 
  1018f6:	83 e2 e0             	and    $0xffffffe0,%edx
  1018f9:	88 14 c5 84 d6 11 00 	mov    %dl,0x11d684(,%eax,8)
  101900:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101903:	0f b6 14 c5 84 d6 11 	movzbl 0x11d684(,%eax,8),%edx
  10190a:	00 
  10190b:	83 e2 1f             	and    $0x1f,%edx
  10190e:	88 14 c5 84 d6 11 00 	mov    %dl,0x11d684(,%eax,8)
  101915:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101918:	0f b6 14 c5 85 d6 11 	movzbl 0x11d685(,%eax,8),%edx
  10191f:	00 
  101920:	83 e2 f0             	and    $0xfffffff0,%edx
  101923:	83 ca 0e             	or     $0xe,%edx
  101926:	88 14 c5 85 d6 11 00 	mov    %dl,0x11d685(,%eax,8)
  10192d:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101930:	0f b6 14 c5 85 d6 11 	movzbl 0x11d685(,%eax,8),%edx
  101937:	00 
  101938:	83 e2 ef             	and    $0xffffffef,%edx
  10193b:	88 14 c5 85 d6 11 00 	mov    %dl,0x11d685(,%eax,8)
  101942:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101945:	0f b6 14 c5 85 d6 11 	movzbl 0x11d685(,%eax,8),%edx
  10194c:	00 
  10194d:	83 e2 9f             	and    $0xffffff9f,%edx
  101950:	88 14 c5 85 d6 11 00 	mov    %dl,0x11d685(,%eax,8)
  101957:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10195a:	0f b6 14 c5 85 d6 11 	movzbl 0x11d685(,%eax,8),%edx
  101961:	00 
  101962:	83 ca 80             	or     $0xffffff80,%edx
  101965:	88 14 c5 85 d6 11 00 	mov    %dl,0x11d685(,%eax,8)
  10196c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10196f:	8b 04 85 e0 a5 11 00 	mov    0x11a5e0(,%eax,4),%eax
  101976:	c1 e8 10             	shr    $0x10,%eax
  101979:	89 c2                	mov    %eax,%edx
  10197b:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10197e:	66 89 14 c5 86 d6 11 	mov    %dx,0x11d686(,%eax,8)
  101985:	00 
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
    extern uintptr_t __vectors[];
    int i;
    for (i = 0; i < 256; i++) {
  101986:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  10198a:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
  101991:	0f 8e 30 ff ff ff    	jle    1018c7 <idt_init+0x12>
        SETGATE(idt[i], 0, GD_KTEXT, __vectors[i], DPL_KERNEL);
    }
    // 只有0x80这个特殊，用户就能用，而且是trap门
    SETGATE(idt[T_SYSCALL], 1, GD_KTEXT, __vectors[T_SYSCALL], DPL_USER);
  101997:	a1 e0 a7 11 00       	mov    0x11a7e0,%eax
  10199c:	66 a3 80 da 11 00    	mov    %ax,0x11da80
  1019a2:	66 c7 05 82 da 11 00 	movw   $0x8,0x11da82
  1019a9:	08 00 
  1019ab:	0f b6 05 84 da 11 00 	movzbl 0x11da84,%eax
  1019b2:	83 e0 e0             	and    $0xffffffe0,%eax
  1019b5:	a2 84 da 11 00       	mov    %al,0x11da84
  1019ba:	0f b6 05 84 da 11 00 	movzbl 0x11da84,%eax
  1019c1:	83 e0 1f             	and    $0x1f,%eax
  1019c4:	a2 84 da 11 00       	mov    %al,0x11da84
  1019c9:	0f b6 05 85 da 11 00 	movzbl 0x11da85,%eax
  1019d0:	83 c8 0f             	or     $0xf,%eax
  1019d3:	a2 85 da 11 00       	mov    %al,0x11da85
  1019d8:	0f b6 05 85 da 11 00 	movzbl 0x11da85,%eax
  1019df:	83 e0 ef             	and    $0xffffffef,%eax
  1019e2:	a2 85 da 11 00       	mov    %al,0x11da85
  1019e7:	0f b6 05 85 da 11 00 	movzbl 0x11da85,%eax
  1019ee:	83 c8 60             	or     $0x60,%eax
  1019f1:	a2 85 da 11 00       	mov    %al,0x11da85
  1019f6:	0f b6 05 85 da 11 00 	movzbl 0x11da85,%eax
  1019fd:	83 c8 80             	or     $0xffffff80,%eax
  101a00:	a2 85 da 11 00       	mov    %al,0x11da85
  101a05:	a1 e0 a7 11 00       	mov    0x11a7e0,%eax
  101a0a:	c1 e8 10             	shr    $0x10,%eax
  101a0d:	66 a3 86 da 11 00    	mov    %ax,0x11da86
    SETGATE(idt[T_SWITCH_TOU], 0, GD_KTEXT, __vectors[T_SWITCH_TOU], DPL_KERNEL);
  101a13:	a1 c0 a7 11 00       	mov    0x11a7c0,%eax
  101a18:	66 a3 40 da 11 00    	mov    %ax,0x11da40
  101a1e:	66 c7 05 42 da 11 00 	movw   $0x8,0x11da42
  101a25:	08 00 
  101a27:	0f b6 05 44 da 11 00 	movzbl 0x11da44,%eax
  101a2e:	83 e0 e0             	and    $0xffffffe0,%eax
  101a31:	a2 44 da 11 00       	mov    %al,0x11da44
  101a36:	0f b6 05 44 da 11 00 	movzbl 0x11da44,%eax
  101a3d:	83 e0 1f             	and    $0x1f,%eax
  101a40:	a2 44 da 11 00       	mov    %al,0x11da44
  101a45:	0f b6 05 45 da 11 00 	movzbl 0x11da45,%eax
  101a4c:	83 e0 f0             	and    $0xfffffff0,%eax
  101a4f:	83 c8 0e             	or     $0xe,%eax
  101a52:	a2 45 da 11 00       	mov    %al,0x11da45
  101a57:	0f b6 05 45 da 11 00 	movzbl 0x11da45,%eax
  101a5e:	83 e0 ef             	and    $0xffffffef,%eax
  101a61:	a2 45 da 11 00       	mov    %al,0x11da45
  101a66:	0f b6 05 45 da 11 00 	movzbl 0x11da45,%eax
  101a6d:	83 e0 9f             	and    $0xffffff9f,%eax
  101a70:	a2 45 da 11 00       	mov    %al,0x11da45
  101a75:	0f b6 05 45 da 11 00 	movzbl 0x11da45,%eax
  101a7c:	83 c8 80             	or     $0xffffff80,%eax
  101a7f:	a2 45 da 11 00       	mov    %al,0x11da45
  101a84:	a1 c0 a7 11 00       	mov    0x11a7c0,%eax
  101a89:	c1 e8 10             	shr    $0x10,%eax
  101a8c:	66 a3 46 da 11 00    	mov    %ax,0x11da46
    SETGATE(idt[T_SWITCH_TOK], 0, GD_KTEXT, __vectors[T_SWITCH_TOK], DPL_USER);
  101a92:	a1 c4 a7 11 00       	mov    0x11a7c4,%eax
  101a97:	66 a3 48 da 11 00    	mov    %ax,0x11da48
  101a9d:	66 c7 05 4a da 11 00 	movw   $0x8,0x11da4a
  101aa4:	08 00 
  101aa6:	0f b6 05 4c da 11 00 	movzbl 0x11da4c,%eax
  101aad:	83 e0 e0             	and    $0xffffffe0,%eax
  101ab0:	a2 4c da 11 00       	mov    %al,0x11da4c
  101ab5:	0f b6 05 4c da 11 00 	movzbl 0x11da4c,%eax
  101abc:	83 e0 1f             	and    $0x1f,%eax
  101abf:	a2 4c da 11 00       	mov    %al,0x11da4c
  101ac4:	0f b6 05 4d da 11 00 	movzbl 0x11da4d,%eax
  101acb:	83 e0 f0             	and    $0xfffffff0,%eax
  101ace:	83 c8 0e             	or     $0xe,%eax
  101ad1:	a2 4d da 11 00       	mov    %al,0x11da4d
  101ad6:	0f b6 05 4d da 11 00 	movzbl 0x11da4d,%eax
  101add:	83 e0 ef             	and    $0xffffffef,%eax
  101ae0:	a2 4d da 11 00       	mov    %al,0x11da4d
  101ae5:	0f b6 05 4d da 11 00 	movzbl 0x11da4d,%eax
  101aec:	83 c8 60             	or     $0x60,%eax
  101aef:	a2 4d da 11 00       	mov    %al,0x11da4d
  101af4:	0f b6 05 4d da 11 00 	movzbl 0x11da4d,%eax
  101afb:	83 c8 80             	or     $0xffffff80,%eax
  101afe:	a2 4d da 11 00       	mov    %al,0x11da4d
  101b03:	a1 c4 a7 11 00       	mov    0x11a7c4,%eax
  101b08:	c1 e8 10             	shr    $0x10,%eax
  101b0b:	66 a3 4e da 11 00    	mov    %ax,0x11da4e
  101b11:	c7 45 f8 60 a5 11 00 	movl   $0x11a560,-0x8(%ebp)
    }
}

static inline void
lidt(struct pseudodesc *pd) {
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
  101b18:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101b1b:	0f 01 18             	lidtl  (%eax)
    lidt(&idt_pd);
}
  101b1e:	c9                   	leave  
  101b1f:	c3                   	ret    

00101b20 <trapname>:

static const char *
trapname(int trapno) {
  101b20:	55                   	push   %ebp
  101b21:	89 e5                	mov    %esp,%ebp
        "Alignment Check",
        "Machine-Check",
        "SIMD Floating-Point Exception"
    };

    if (trapno < sizeof(excnames)/sizeof(const char * const)) {
  101b23:	8b 45 08             	mov    0x8(%ebp),%eax
  101b26:	83 f8 13             	cmp    $0x13,%eax
  101b29:	77 0c                	ja     101b37 <trapname+0x17>
        return excnames[trapno];
  101b2b:	8b 45 08             	mov    0x8(%ebp),%eax
  101b2e:	8b 04 85 e0 79 10 00 	mov    0x1079e0(,%eax,4),%eax
  101b35:	eb 18                	jmp    101b4f <trapname+0x2f>
    }
    if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16) {
  101b37:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  101b3b:	7e 0d                	jle    101b4a <trapname+0x2a>
  101b3d:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  101b41:	7f 07                	jg     101b4a <trapname+0x2a>
        return "Hardware Interrupt";
  101b43:	b8 8a 76 10 00       	mov    $0x10768a,%eax
  101b48:	eb 05                	jmp    101b4f <trapname+0x2f>
    }
    return "(unknown trap)";
  101b4a:	b8 9d 76 10 00       	mov    $0x10769d,%eax
}
  101b4f:	5d                   	pop    %ebp
  101b50:	c3                   	ret    

00101b51 <trap_in_kernel>:

/* trap_in_kernel - test if trap happened in kernel */
bool
trap_in_kernel(struct trapframe *tf) {
  101b51:	55                   	push   %ebp
  101b52:	89 e5                	mov    %esp,%ebp
    return (tf->tf_cs == (uint16_t)KERNEL_CS);
  101b54:	8b 45 08             	mov    0x8(%ebp),%eax
  101b57:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101b5b:	66 83 f8 08          	cmp    $0x8,%ax
  101b5f:	0f 94 c0             	sete   %al
  101b62:	0f b6 c0             	movzbl %al,%eax
}
  101b65:	5d                   	pop    %ebp
  101b66:	c3                   	ret    

00101b67 <print_trapframe>:
    "TF", "IF", "DF", "OF", NULL, NULL, "NT", NULL,
    "RF", "VM", "AC", "VIF", "VIP", "ID", NULL, NULL,
};

void
print_trapframe(struct trapframe *tf) {
  101b67:	55                   	push   %ebp
  101b68:	89 e5                	mov    %esp,%ebp
  101b6a:	83 ec 28             	sub    $0x28,%esp
    cprintf("trapframe at %p\n", tf);
  101b6d:	8b 45 08             	mov    0x8(%ebp),%eax
  101b70:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b74:	c7 04 24 de 76 10 00 	movl   $0x1076de,(%esp)
  101b7b:	e8 d4 e7 ff ff       	call   100354 <cprintf>
    print_regs(&tf->tf_regs);
  101b80:	8b 45 08             	mov    0x8(%ebp),%eax
  101b83:	89 04 24             	mov    %eax,(%esp)
  101b86:	e8 a1 01 00 00       	call   101d2c <print_regs>
    cprintf("  ds   0x----%04x\n", tf->tf_ds);
  101b8b:	8b 45 08             	mov    0x8(%ebp),%eax
  101b8e:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  101b92:	0f b7 c0             	movzwl %ax,%eax
  101b95:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b99:	c7 04 24 ef 76 10 00 	movl   $0x1076ef,(%esp)
  101ba0:	e8 af e7 ff ff       	call   100354 <cprintf>
    cprintf("  es   0x----%04x\n", tf->tf_es);
  101ba5:	8b 45 08             	mov    0x8(%ebp),%eax
  101ba8:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101bac:	0f b7 c0             	movzwl %ax,%eax
  101baf:	89 44 24 04          	mov    %eax,0x4(%esp)
  101bb3:	c7 04 24 02 77 10 00 	movl   $0x107702,(%esp)
  101bba:	e8 95 e7 ff ff       	call   100354 <cprintf>
    cprintf("  fs   0x----%04x\n", tf->tf_fs);
  101bbf:	8b 45 08             	mov    0x8(%ebp),%eax
  101bc2:	0f b7 40 24          	movzwl 0x24(%eax),%eax
  101bc6:	0f b7 c0             	movzwl %ax,%eax
  101bc9:	89 44 24 04          	mov    %eax,0x4(%esp)
  101bcd:	c7 04 24 15 77 10 00 	movl   $0x107715,(%esp)
  101bd4:	e8 7b e7 ff ff       	call   100354 <cprintf>
    cprintf("  gs   0x----%04x\n", tf->tf_gs);
  101bd9:	8b 45 08             	mov    0x8(%ebp),%eax
  101bdc:	0f b7 40 20          	movzwl 0x20(%eax),%eax
  101be0:	0f b7 c0             	movzwl %ax,%eax
  101be3:	89 44 24 04          	mov    %eax,0x4(%esp)
  101be7:	c7 04 24 28 77 10 00 	movl   $0x107728,(%esp)
  101bee:	e8 61 e7 ff ff       	call   100354 <cprintf>
    cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
  101bf3:	8b 45 08             	mov    0x8(%ebp),%eax
  101bf6:	8b 40 30             	mov    0x30(%eax),%eax
  101bf9:	89 04 24             	mov    %eax,(%esp)
  101bfc:	e8 1f ff ff ff       	call   101b20 <trapname>
  101c01:	8b 55 08             	mov    0x8(%ebp),%edx
  101c04:	8b 52 30             	mov    0x30(%edx),%edx
  101c07:	89 44 24 08          	mov    %eax,0x8(%esp)
  101c0b:	89 54 24 04          	mov    %edx,0x4(%esp)
  101c0f:	c7 04 24 3b 77 10 00 	movl   $0x10773b,(%esp)
  101c16:	e8 39 e7 ff ff       	call   100354 <cprintf>
    cprintf("  err  0x%08x\n", tf->tf_err);
  101c1b:	8b 45 08             	mov    0x8(%ebp),%eax
  101c1e:	8b 40 34             	mov    0x34(%eax),%eax
  101c21:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c25:	c7 04 24 4d 77 10 00 	movl   $0x10774d,(%esp)
  101c2c:	e8 23 e7 ff ff       	call   100354 <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
  101c31:	8b 45 08             	mov    0x8(%ebp),%eax
  101c34:	8b 40 38             	mov    0x38(%eax),%eax
  101c37:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c3b:	c7 04 24 5c 77 10 00 	movl   $0x10775c,(%esp)
  101c42:	e8 0d e7 ff ff       	call   100354 <cprintf>
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
  101c47:	8b 45 08             	mov    0x8(%ebp),%eax
  101c4a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101c4e:	0f b7 c0             	movzwl %ax,%eax
  101c51:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c55:	c7 04 24 6b 77 10 00 	movl   $0x10776b,(%esp)
  101c5c:	e8 f3 e6 ff ff       	call   100354 <cprintf>
    cprintf("  flag 0x%08x ", tf->tf_eflags);
  101c61:	8b 45 08             	mov    0x8(%ebp),%eax
  101c64:	8b 40 40             	mov    0x40(%eax),%eax
  101c67:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c6b:	c7 04 24 7e 77 10 00 	movl   $0x10777e,(%esp)
  101c72:	e8 dd e6 ff ff       	call   100354 <cprintf>

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
  101c77:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  101c7e:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
  101c85:	eb 3e                	jmp    101cc5 <print_trapframe+0x15e>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
  101c87:	8b 45 08             	mov    0x8(%ebp),%eax
  101c8a:	8b 50 40             	mov    0x40(%eax),%edx
  101c8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101c90:	21 d0                	and    %edx,%eax
  101c92:	85 c0                	test   %eax,%eax
  101c94:	74 28                	je     101cbe <print_trapframe+0x157>
  101c96:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c99:	8b 04 85 80 a5 11 00 	mov    0x11a580(,%eax,4),%eax
  101ca0:	85 c0                	test   %eax,%eax
  101ca2:	74 1a                	je     101cbe <print_trapframe+0x157>
            cprintf("%s,", IA32flags[i]);
  101ca4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101ca7:	8b 04 85 80 a5 11 00 	mov    0x11a580(,%eax,4),%eax
  101cae:	89 44 24 04          	mov    %eax,0x4(%esp)
  101cb2:	c7 04 24 8d 77 10 00 	movl   $0x10778d,(%esp)
  101cb9:	e8 96 e6 ff ff       	call   100354 <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
    cprintf("  flag 0x%08x ", tf->tf_eflags);

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
  101cbe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  101cc2:	d1 65 f0             	shll   -0x10(%ebp)
  101cc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101cc8:	83 f8 17             	cmp    $0x17,%eax
  101ccb:	76 ba                	jbe    101c87 <print_trapframe+0x120>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
            cprintf("%s,", IA32flags[i]);
        }
    }
    cprintf("IOPL=%d\n", (tf->tf_eflags & FL_IOPL_MASK) >> 12);
  101ccd:	8b 45 08             	mov    0x8(%ebp),%eax
  101cd0:	8b 40 40             	mov    0x40(%eax),%eax
  101cd3:	25 00 30 00 00       	and    $0x3000,%eax
  101cd8:	c1 e8 0c             	shr    $0xc,%eax
  101cdb:	89 44 24 04          	mov    %eax,0x4(%esp)
  101cdf:	c7 04 24 91 77 10 00 	movl   $0x107791,(%esp)
  101ce6:	e8 69 e6 ff ff       	call   100354 <cprintf>

    if (!trap_in_kernel(tf)) {
  101ceb:	8b 45 08             	mov    0x8(%ebp),%eax
  101cee:	89 04 24             	mov    %eax,(%esp)
  101cf1:	e8 5b fe ff ff       	call   101b51 <trap_in_kernel>
  101cf6:	85 c0                	test   %eax,%eax
  101cf8:	75 30                	jne    101d2a <print_trapframe+0x1c3>
        cprintf("  esp  0x%08x\n", tf->tf_esp);
  101cfa:	8b 45 08             	mov    0x8(%ebp),%eax
  101cfd:	8b 40 44             	mov    0x44(%eax),%eax
  101d00:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d04:	c7 04 24 9a 77 10 00 	movl   $0x10779a,(%esp)
  101d0b:	e8 44 e6 ff ff       	call   100354 <cprintf>
        cprintf("  ss   0x----%04x\n", tf->tf_ss);
  101d10:	8b 45 08             	mov    0x8(%ebp),%eax
  101d13:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101d17:	0f b7 c0             	movzwl %ax,%eax
  101d1a:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d1e:	c7 04 24 a9 77 10 00 	movl   $0x1077a9,(%esp)
  101d25:	e8 2a e6 ff ff       	call   100354 <cprintf>
    }
}
  101d2a:	c9                   	leave  
  101d2b:	c3                   	ret    

00101d2c <print_regs>:

void
print_regs(struct pushregs *regs) {
  101d2c:	55                   	push   %ebp
  101d2d:	89 e5                	mov    %esp,%ebp
  101d2f:	83 ec 18             	sub    $0x18,%esp
    cprintf("  edi  0x%08x\n", regs->reg_edi);
  101d32:	8b 45 08             	mov    0x8(%ebp),%eax
  101d35:	8b 00                	mov    (%eax),%eax
  101d37:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d3b:	c7 04 24 bc 77 10 00 	movl   $0x1077bc,(%esp)
  101d42:	e8 0d e6 ff ff       	call   100354 <cprintf>
    cprintf("  esi  0x%08x\n", regs->reg_esi);
  101d47:	8b 45 08             	mov    0x8(%ebp),%eax
  101d4a:	8b 40 04             	mov    0x4(%eax),%eax
  101d4d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d51:	c7 04 24 cb 77 10 00 	movl   $0x1077cb,(%esp)
  101d58:	e8 f7 e5 ff ff       	call   100354 <cprintf>
    cprintf("  ebp  0x%08x\n", regs->reg_ebp);
  101d5d:	8b 45 08             	mov    0x8(%ebp),%eax
  101d60:	8b 40 08             	mov    0x8(%eax),%eax
  101d63:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d67:	c7 04 24 da 77 10 00 	movl   $0x1077da,(%esp)
  101d6e:	e8 e1 e5 ff ff       	call   100354 <cprintf>
    cprintf("  oesp 0x%08x\n", regs->reg_oesp);
  101d73:	8b 45 08             	mov    0x8(%ebp),%eax
  101d76:	8b 40 0c             	mov    0xc(%eax),%eax
  101d79:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d7d:	c7 04 24 e9 77 10 00 	movl   $0x1077e9,(%esp)
  101d84:	e8 cb e5 ff ff       	call   100354 <cprintf>
    cprintf("  ebx  0x%08x\n", regs->reg_ebx);
  101d89:	8b 45 08             	mov    0x8(%ebp),%eax
  101d8c:	8b 40 10             	mov    0x10(%eax),%eax
  101d8f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d93:	c7 04 24 f8 77 10 00 	movl   $0x1077f8,(%esp)
  101d9a:	e8 b5 e5 ff ff       	call   100354 <cprintf>
    cprintf("  edx  0x%08x\n", regs->reg_edx);
  101d9f:	8b 45 08             	mov    0x8(%ebp),%eax
  101da2:	8b 40 14             	mov    0x14(%eax),%eax
  101da5:	89 44 24 04          	mov    %eax,0x4(%esp)
  101da9:	c7 04 24 07 78 10 00 	movl   $0x107807,(%esp)
  101db0:	e8 9f e5 ff ff       	call   100354 <cprintf>
    cprintf("  ecx  0x%08x\n", regs->reg_ecx);
  101db5:	8b 45 08             	mov    0x8(%ebp),%eax
  101db8:	8b 40 18             	mov    0x18(%eax),%eax
  101dbb:	89 44 24 04          	mov    %eax,0x4(%esp)
  101dbf:	c7 04 24 16 78 10 00 	movl   $0x107816,(%esp)
  101dc6:	e8 89 e5 ff ff       	call   100354 <cprintf>
    cprintf("  eax  0x%08x\n", regs->reg_eax);
  101dcb:	8b 45 08             	mov    0x8(%ebp),%eax
  101dce:	8b 40 1c             	mov    0x1c(%eax),%eax
  101dd1:	89 44 24 04          	mov    %eax,0x4(%esp)
  101dd5:	c7 04 24 25 78 10 00 	movl   $0x107825,(%esp)
  101ddc:	e8 73 e5 ff ff       	call   100354 <cprintf>
}
  101de1:	c9                   	leave  
  101de2:	c3                   	ret    

00101de3 <trap_dispatch>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static void
trap_dispatch(struct trapframe *tf) {
  101de3:	55                   	push   %ebp
  101de4:	89 e5                	mov    %esp,%ebp
  101de6:	57                   	push   %edi
  101de7:	56                   	push   %esi
  101de8:	53                   	push   %ebx
  101de9:	81 ec ac 00 00 00    	sub    $0xac,%esp
    char c;

    switch (tf->tf_trapno) {
  101def:	8b 45 08             	mov    0x8(%ebp),%eax
  101df2:	8b 40 30             	mov    0x30(%eax),%eax
  101df5:	83 f8 2f             	cmp    $0x2f,%eax
  101df8:	77 21                	ja     101e1b <trap_dispatch+0x38>
  101dfa:	83 f8 2e             	cmp    $0x2e,%eax
  101dfd:	0f 83 72 03 00 00    	jae    102175 <trap_dispatch+0x392>
  101e03:	83 f8 21             	cmp    $0x21,%eax
  101e06:	0f 84 8a 00 00 00    	je     101e96 <trap_dispatch+0xb3>
  101e0c:	83 f8 24             	cmp    $0x24,%eax
  101e0f:	74 5c                	je     101e6d <trap_dispatch+0x8a>
  101e11:	83 f8 20             	cmp    $0x20,%eax
  101e14:	74 1c                	je     101e32 <trap_dispatch+0x4f>
  101e16:	e9 22 03 00 00       	jmp    10213d <trap_dispatch+0x35a>
  101e1b:	83 f8 78             	cmp    $0x78,%eax
  101e1e:	0f 84 2c 02 00 00    	je     102050 <trap_dispatch+0x26d>
  101e24:	83 f8 79             	cmp    $0x79,%eax
  101e27:	0f 84 a4 02 00 00    	je     1020d1 <trap_dispatch+0x2ee>
  101e2d:	e9 0b 03 00 00       	jmp    10213d <trap_dispatch+0x35a>
        /* handle the timer interrupt */
        /* (1) After a timer interrupt, you should record this event using a global variable (increase it), such as ticks in kern/driver/clock.c
         * (2) Every TICK_NUM cycle, you can print some info using a funciton, such as print_ticks().
         * (3) Too Simple? Yes, I think so!
         */
        ticks++;
  101e32:	a1 2c 57 12 00       	mov    0x12572c,%eax
  101e37:	83 c0 01             	add    $0x1,%eax
  101e3a:	a3 2c 57 12 00       	mov    %eax,0x12572c
        if (ticks % TICK_NUM == 0) {
  101e3f:	8b 0d 2c 57 12 00    	mov    0x12572c,%ecx
  101e45:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
  101e4a:	89 c8                	mov    %ecx,%eax
  101e4c:	f7 e2                	mul    %edx
  101e4e:	89 d0                	mov    %edx,%eax
  101e50:	c1 e8 05             	shr    $0x5,%eax
  101e53:	6b c0 64             	imul   $0x64,%eax,%eax
  101e56:	29 c1                	sub    %eax,%ecx
  101e58:	89 c8                	mov    %ecx,%eax
  101e5a:	85 c0                	test   %eax,%eax
  101e5c:	75 0a                	jne    101e68 <trap_dispatch+0x85>
            print_ticks();
  101e5e:	e8 36 fa ff ff       	call   101899 <print_ticks>
        }
        break;
  101e63:	e9 0e 03 00 00       	jmp    102176 <trap_dispatch+0x393>
  101e68:	e9 09 03 00 00       	jmp    102176 <trap_dispatch+0x393>
    case IRQ_OFFSET + IRQ_COM1:
        c = cons_getc();
  101e6d:	e8 eb f7 ff ff       	call   10165d <cons_getc>
  101e72:	88 45 e7             	mov    %al,-0x19(%ebp)
        cprintf("serial [%03d] %c\n", c, c);
  101e75:	0f be 55 e7          	movsbl -0x19(%ebp),%edx
  101e79:	0f be 45 e7          	movsbl -0x19(%ebp),%eax
  101e7d:	89 54 24 08          	mov    %edx,0x8(%esp)
  101e81:	89 44 24 04          	mov    %eax,0x4(%esp)
  101e85:	c7 04 24 34 78 10 00 	movl   $0x107834,(%esp)
  101e8c:	e8 c3 e4 ff ff       	call   100354 <cprintf>
        break;
  101e91:	e9 e0 02 00 00       	jmp    102176 <trap_dispatch+0x393>
    case IRQ_OFFSET + IRQ_KBD:
        c = cons_getc();
  101e96:	e8 c2 f7 ff ff       	call   10165d <cons_getc>
  101e9b:	88 45 e7             	mov    %al,-0x19(%ebp)
        cprintf("kbd [%03d] %c\n", c, c);
  101e9e:	0f be 55 e7          	movsbl -0x19(%ebp),%edx
  101ea2:	0f be 45 e7          	movsbl -0x19(%ebp),%eax
  101ea6:	89 54 24 08          	mov    %edx,0x8(%esp)
  101eaa:	89 44 24 04          	mov    %eax,0x4(%esp)
  101eae:	c7 04 24 46 78 10 00 	movl   $0x107846,(%esp)
  101eb5:	e8 9a e4 ff ff       	call   100354 <cprintf>
        if (c == 51 && tf->tf_cs == KERNEL_CS) { //切换到用户态
  101eba:	80 7d e7 33          	cmpb   $0x33,-0x19(%ebp)
  101ebe:	75 76                	jne    101f36 <trap_dispatch+0x153>
  101ec0:	8b 45 08             	mov    0x8(%ebp),%eax
  101ec3:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101ec7:	66 83 f8 08          	cmp    $0x8,%ax
  101ecb:	75 69                	jne    101f36 <trap_dispatch+0x153>
            struct trapframe fake_tf = *tf;
  101ecd:	8b 45 08             	mov    0x8(%ebp),%eax
  101ed0:	8d 95 64 ff ff ff    	lea    -0x9c(%ebp),%edx
  101ed6:	89 c3                	mov    %eax,%ebx
  101ed8:	b8 13 00 00 00       	mov    $0x13,%eax
  101edd:	89 d7                	mov    %edx,%edi
  101edf:	89 de                	mov    %ebx,%esi
  101ee1:	89 c1                	mov    %eax,%ecx
  101ee3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
            //设置段寄存器
            fake_tf.tf_cs = USER_CS;
  101ee5:	66 c7 45 a0 1b 00    	movw   $0x1b,-0x60(%ebp)
            fake_tf.tf_ss = fake_tf.tf_ds = fake_tf.tf_es = fake_tf.tf_fs = fake_tf.tf_gs = USER_DS;
  101eeb:	66 c7 45 84 23 00    	movw   $0x23,-0x7c(%ebp)
  101ef1:	0f b7 45 84          	movzwl -0x7c(%ebp),%eax
  101ef5:	66 89 45 88          	mov    %ax,-0x78(%ebp)
  101ef9:	0f b7 45 88          	movzwl -0x78(%ebp),%eax
  101efd:	66 89 45 8c          	mov    %ax,-0x74(%ebp)
  101f01:	0f b7 45 8c          	movzwl -0x74(%ebp),%eax
  101f05:	66 89 45 90          	mov    %ax,-0x70(%ebp)
  101f09:	0f b7 45 90          	movzwl -0x70(%ebp),%eax
  101f0d:	66 89 45 ac          	mov    %ax,-0x54(%ebp)
            //设置esp，相当于骗CPU，让它以为是从U到K，然后他就会恢复esp的值
            fake_tf.tf_esp = (&tf->tf_esp);
  101f11:	8b 45 08             	mov    0x8(%ebp),%eax
  101f14:	83 c0 44             	add    $0x44,%eax
  101f17:	89 45 a8             	mov    %eax,-0x58(%ebp)
            //把eflags的IO位打开，要不切换到用户态后没办法打印信息了。
            fake_tf.tf_eflags |= FL_IOPL_MASK;
  101f1a:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  101f1d:	80 cc 30             	or     $0x30,%ah
  101f20:	89 45 a4             	mov    %eax,-0x5c(%ebp)
            //存在栈里的esp指向了tf的首地址，这里把这个esp的值改了，pop之后
            //的esp就指向fake_tf了
            *((uint32_t*)tf - 1) = &fake_tf;
  101f23:	8b 45 08             	mov    0x8(%ebp),%eax
  101f26:	8d 50 fc             	lea    -0x4(%eax),%edx
  101f29:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
  101f2f:	89 02                	mov    %eax,(%edx)
        cprintf("serial [%03d] %c\n", c, c);
        break;
    case IRQ_OFFSET + IRQ_KBD:
        c = cons_getc();
        cprintf("kbd [%03d] %c\n", c, c);
        if (c == 51 && tf->tf_cs == KERNEL_CS) { //切换到用户态
  101f31:	e9 15 01 00 00       	jmp    10204b <trap_dispatch+0x268>
            fake_tf.tf_eflags |= FL_IOPL_MASK;
            //存在栈里的esp指向了tf的首地址，这里把这个esp的值改了，pop之后
            //的esp就指向fake_tf了
            *((uint32_t*)tf - 1) = &fake_tf;
        }
        else if (c == 48 && tf->tf_cs == USER_CS) { //切换到内核态
  101f36:	80 7d e7 30          	cmpb   $0x30,-0x19(%ebp)
  101f3a:	0f 85 0b 01 00 00    	jne    10204b <trap_dispatch+0x268>
  101f40:	8b 45 08             	mov    0x8(%ebp),%eax
  101f43:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101f47:	66 83 f8 1b          	cmp    $0x1b,%ax
  101f4b:	0f 85 fa 00 00 00    	jne    10204b <trap_dispatch+0x268>
            struct trapframe fake_tf = *tf;
  101f51:	8b 45 08             	mov    0x8(%ebp),%eax
  101f54:	8d 95 64 ff ff ff    	lea    -0x9c(%ebp),%edx
  101f5a:	89 c3                	mov    %eax,%ebx
  101f5c:	b8 13 00 00 00       	mov    $0x13,%eax
  101f61:	89 d7                	mov    %edx,%edi
  101f63:	89 de                	mov    %ebx,%esi
  101f65:	89 c1                	mov    %eax,%ecx
  101f67:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
            //设置段寄存器
            fake_tf.tf_cs = KERNEL_CS;
  101f69:	66 c7 45 a0 08 00    	movw   $0x8,-0x60(%ebp)
            fake_tf.tf_ss = fake_tf.tf_ds = fake_tf.tf_es = fake_tf.tf_fs = fake_tf.tf_gs = KERNEL_DS;
  101f6f:	66 c7 45 84 10 00    	movw   $0x10,-0x7c(%ebp)
  101f75:	0f b7 45 84          	movzwl -0x7c(%ebp),%eax
  101f79:	66 89 45 88          	mov    %ax,-0x78(%ebp)
  101f7d:	0f b7 45 88          	movzwl -0x78(%ebp),%eax
  101f81:	66 89 45 8c          	mov    %ax,-0x74(%ebp)
  101f85:	0f b7 45 8c          	movzwl -0x74(%ebp),%eax
  101f89:	66 89 45 90          	mov    %ax,-0x70(%ebp)
  101f8d:	0f b7 45 90          	movzwl -0x70(%ebp),%eax
  101f91:	66 89 45 ac          	mov    %ax,-0x54(%ebp)
            fake_tf.tf_eflags &= ~FL_IOPL_MASK;
  101f95:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  101f98:	80 e4 cf             	and    $0xcf,%ah
  101f9b:	89 45 a4             	mov    %eax,-0x5c(%ebp)
            uintptr_t user_tf_add = (struct trapframe*)fake_tf.tf_esp - 1;
  101f9e:	8b 45 a8             	mov    -0x58(%ebp),%eax
  101fa1:	83 e8 4c             	sub    $0x4c,%eax
  101fa4:	89 45 e0             	mov    %eax,-0x20(%ebp)
            user_tf_add += 8;
  101fa7:	83 45 e0 08          	addl   $0x8,-0x20(%ebp)
            __memmove(user_tf_add, &fake_tf, sizeof(struct trapframe) - 8);
  101fab:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101fae:	89 45 dc             	mov    %eax,-0x24(%ebp)
  101fb1:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
  101fb7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  101fba:	c7 45 d4 44 00 00 00 	movl   $0x44,-0x2c(%ebp)

#ifndef __HAVE_ARCH_MEMMOVE
#define __HAVE_ARCH_MEMMOVE
static inline void *
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
  101fc1:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101fc4:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  101fc7:	73 3f                	jae    102008 <trap_dispatch+0x225>
  101fc9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101fcc:	89 45 d0             	mov    %eax,-0x30(%ebp)
  101fcf:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101fd2:	89 45 cc             	mov    %eax,-0x34(%ebp)
  101fd5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  101fd8:	89 45 c8             	mov    %eax,-0x38(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
  101fdb:	8b 45 c8             	mov    -0x38(%ebp),%eax
  101fde:	c1 e8 02             	shr    $0x2,%eax
  101fe1:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
  101fe3:	8b 55 d0             	mov    -0x30(%ebp),%edx
  101fe6:	8b 45 cc             	mov    -0x34(%ebp),%eax
  101fe9:	89 d7                	mov    %edx,%edi
  101feb:	89 c6                	mov    %eax,%esi
  101fed:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  101fef:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  101ff2:	83 e1 03             	and    $0x3,%ecx
  101ff5:	74 02                	je     101ff9 <trap_dispatch+0x216>
  101ff7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  101ff9:	89 f0                	mov    %esi,%eax
  101ffb:	89 fa                	mov    %edi,%edx
  101ffd:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
  102000:	89 55 c0             	mov    %edx,-0x40(%ebp)
  102003:	89 45 bc             	mov    %eax,-0x44(%ebp)
  102006:	eb 33                	jmp    10203b <trap_dispatch+0x258>
    asm volatile (
        "std;"
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
  102008:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10200b:	8d 50 ff             	lea    -0x1(%eax),%edx
  10200e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102011:	01 c2                	add    %eax,%edx
  102013:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102016:	8d 48 ff             	lea    -0x1(%eax),%ecx
  102019:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10201c:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
        return __memcpy(dst, src, n);
    }
    int d0, d1, d2;
    asm volatile (
  10201f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102022:	89 c1                	mov    %eax,%ecx
  102024:	89 d8                	mov    %ebx,%eax
  102026:	89 d6                	mov    %edx,%esi
  102028:	89 c7                	mov    %eax,%edi
  10202a:	fd                   	std    
  10202b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  10202d:	fc                   	cld    
  10202e:	89 f8                	mov    %edi,%eax
  102030:	89 f2                	mov    %esi,%edx
  102032:	89 4d b8             	mov    %ecx,-0x48(%ebp)
  102035:	89 55 b4             	mov    %edx,-0x4c(%ebp)
  102038:	89 45 b0             	mov    %eax,-0x50(%ebp)
            //存在栈里的esp指向了tf的首地址，这里把这个esp的值改了，pop之后
            //的esp就指向fake_tf了
            *((uint32_t*)tf - 1) = user_tf_add;
  10203b:	8b 45 08             	mov    0x8(%ebp),%eax
  10203e:	8d 50 fc             	lea    -0x4(%eax),%edx
  102041:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102044:	89 02                	mov    %eax,(%edx)
        }
        break;
  102046:	e9 2b 01 00 00       	jmp    102176 <trap_dispatch+0x393>
  10204b:	e9 26 01 00 00       	jmp    102176 <trap_dispatch+0x393>
    //LAB1 CHALLENGE 1 : YOUR CODE you should modify below codes.
    case T_SWITCH_TOU:
        if (tf->tf_cs != USER_CS) {
  102050:	8b 45 08             	mov    0x8(%ebp),%eax
  102053:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  102057:	66 83 f8 1b          	cmp    $0x1b,%ax
  10205b:	74 6f                	je     1020cc <trap_dispatch+0x2e9>
            //设置段寄存
            tf->tf_cs = USER_CS;
  10205d:	8b 45 08             	mov    0x8(%ebp),%eax
  102060:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
            tf->tf_ss = tf->tf_ds = tf->tf_es = tf->tf_fs = tf->tf_gs = USER_DS;
  102066:	8b 45 08             	mov    0x8(%ebp),%eax
  102069:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
  10206f:	8b 45 08             	mov    0x8(%ebp),%eax
  102072:	0f b7 50 20          	movzwl 0x20(%eax),%edx
  102076:	8b 45 08             	mov    0x8(%ebp),%eax
  102079:	66 89 50 24          	mov    %dx,0x24(%eax)
  10207d:	8b 45 08             	mov    0x8(%ebp),%eax
  102080:	0f b7 50 24          	movzwl 0x24(%eax),%edx
  102084:	8b 45 08             	mov    0x8(%ebp),%eax
  102087:	66 89 50 28          	mov    %dx,0x28(%eax)
  10208b:	8b 45 08             	mov    0x8(%ebp),%eax
  10208e:	0f b7 50 28          	movzwl 0x28(%eax),%edx
  102092:	8b 45 08             	mov    0x8(%ebp),%eax
  102095:	66 89 50 2c          	mov    %dx,0x2c(%eax)
  102099:	8b 45 08             	mov    0x8(%ebp),%eax
  10209c:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
  1020a0:	8b 45 08             	mov    0x8(%ebp),%eax
  1020a3:	66 89 50 48          	mov    %dx,0x48(%eax)
            tf->tf_esp += 4;
  1020a7:	8b 45 08             	mov    0x8(%ebp),%eax
  1020aa:	8b 40 44             	mov    0x44(%eax),%eax
  1020ad:	8d 50 04             	lea    0x4(%eax),%edx
  1020b0:	8b 45 08             	mov    0x8(%ebp),%eax
  1020b3:	89 50 44             	mov    %edx,0x44(%eax)
            //把eflags的IO位打开，要不切换到用户态后没办法打印信息了。
            tf->tf_eflags |= FL_IOPL_MASK;
  1020b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1020b9:	8b 40 40             	mov    0x40(%eax),%eax
  1020bc:	80 cc 30             	or     $0x30,%ah
  1020bf:	89 c2                	mov    %eax,%edx
  1020c1:	8b 45 08             	mov    0x8(%ebp),%eax
  1020c4:	89 50 40             	mov    %edx,0x40(%eax)
        }
        break;
  1020c7:	e9 aa 00 00 00       	jmp    102176 <trap_dispatch+0x393>
  1020cc:	e9 a5 00 00 00       	jmp    102176 <trap_dispatch+0x393>
    case T_SWITCH_TOK:
        if (tf->tf_cs != KERNEL_CS) {
  1020d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1020d4:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1020d8:	66 83 f8 08          	cmp    $0x8,%ax
  1020dc:	74 5d                	je     10213b <trap_dispatch+0x358>
            //设置段寄存器
            tf->tf_cs = KERNEL_CS;
  1020de:	8b 45 08             	mov    0x8(%ebp),%eax
  1020e1:	66 c7 40 3c 08 00    	movw   $0x8,0x3c(%eax)
            tf->tf_ss = tf->tf_ds = tf->tf_es = tf->tf_fs = tf->tf_gs = KERNEL_DS;
  1020e7:	8b 45 08             	mov    0x8(%ebp),%eax
  1020ea:	66 c7 40 20 10 00    	movw   $0x10,0x20(%eax)
  1020f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1020f3:	0f b7 50 20          	movzwl 0x20(%eax),%edx
  1020f7:	8b 45 08             	mov    0x8(%ebp),%eax
  1020fa:	66 89 50 24          	mov    %dx,0x24(%eax)
  1020fe:	8b 45 08             	mov    0x8(%ebp),%eax
  102101:	0f b7 50 24          	movzwl 0x24(%eax),%edx
  102105:	8b 45 08             	mov    0x8(%ebp),%eax
  102108:	66 89 50 28          	mov    %dx,0x28(%eax)
  10210c:	8b 45 08             	mov    0x8(%ebp),%eax
  10210f:	0f b7 50 28          	movzwl 0x28(%eax),%edx
  102113:	8b 45 08             	mov    0x8(%ebp),%eax
  102116:	66 89 50 2c          	mov    %dx,0x2c(%eax)
  10211a:	8b 45 08             	mov    0x8(%ebp),%eax
  10211d:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
  102121:	8b 45 08             	mov    0x8(%ebp),%eax
  102124:	66 89 50 48          	mov    %dx,0x48(%eax)
            //把eflags的IO位关闭
            tf->tf_eflags &= ~FL_IOPL_MASK;
  102128:	8b 45 08             	mov    0x8(%ebp),%eax
  10212b:	8b 40 40             	mov    0x40(%eax),%eax
  10212e:	80 e4 cf             	and    $0xcf,%ah
  102131:	89 c2                	mov    %eax,%edx
  102133:	8b 45 08             	mov    0x8(%ebp),%eax
  102136:	89 50 40             	mov    %edx,0x40(%eax)
        }
        break;
  102139:	eb 3b                	jmp    102176 <trap_dispatch+0x393>
  10213b:	eb 39                	jmp    102176 <trap_dispatch+0x393>
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
    default:
        // in kernel, it must be a mistake
        if ((tf->tf_cs & 3) == 0) {
  10213d:	8b 45 08             	mov    0x8(%ebp),%eax
  102140:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  102144:	0f b7 c0             	movzwl %ax,%eax
  102147:	83 e0 03             	and    $0x3,%eax
  10214a:	85 c0                	test   %eax,%eax
  10214c:	75 28                	jne    102176 <trap_dispatch+0x393>
            print_trapframe(tf);
  10214e:	8b 45 08             	mov    0x8(%ebp),%eax
  102151:	89 04 24             	mov    %eax,(%esp)
  102154:	e8 0e fa ff ff       	call   101b67 <print_trapframe>
            panic("unexpected trap in kernel.\n");
  102159:	c7 44 24 08 55 78 10 	movl   $0x107855,0x8(%esp)
  102160:	00 
  102161:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  102168:	00 
  102169:	c7 04 24 71 78 10 00 	movl   $0x107871,(%esp)
  102170:	e8 69 eb ff ff       	call   100cde <__panic>
        }
        break;
    case IRQ_OFFSET + IRQ_IDE1:
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
  102175:	90                   	nop
        if ((tf->tf_cs & 3) == 0) {
            print_trapframe(tf);
            panic("unexpected trap in kernel.\n");
        }
    }
}
  102176:	81 c4 ac 00 00 00    	add    $0xac,%esp
  10217c:	5b                   	pop    %ebx
  10217d:	5e                   	pop    %esi
  10217e:	5f                   	pop    %edi
  10217f:	5d                   	pop    %ebp
  102180:	c3                   	ret    

00102181 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
  102181:	55                   	push   %ebp
  102182:	89 e5                	mov    %esp,%ebp
  102184:	83 ec 18             	sub    $0x18,%esp
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
  102187:	8b 45 08             	mov    0x8(%ebp),%eax
  10218a:	89 04 24             	mov    %eax,(%esp)
  10218d:	e8 51 fc ff ff       	call   101de3 <trap_dispatch>
}
  102192:	c9                   	leave  
  102193:	c3                   	ret    

00102194 <__alltraps>:
.text
.globl __alltraps
__alltraps:
    # push registers to build a trap frame
    # therefore make the stack look like a struct trapframe
    pushl %ds
  102194:	1e                   	push   %ds
    pushl %es
  102195:	06                   	push   %es
    pushl %fs
  102196:	0f a0                	push   %fs
    pushl %gs
  102198:	0f a8                	push   %gs
    pushal
  10219a:	60                   	pusha  

    # load GD_KDATA into %ds and %es to set up data segments for kernel
    movl $GD_KDATA, %eax
  10219b:	b8 10 00 00 00       	mov    $0x10,%eax
    movw %ax, %ds
  1021a0:	8e d8                	mov    %eax,%ds
    movw %ax, %es
  1021a2:	8e c0                	mov    %eax,%es

    # push %esp to pass a pointer to the trapframe as an argument to trap()
    pushl %esp
  1021a4:	54                   	push   %esp

    # call trap(tf), where tf=%esp
    call trap
  1021a5:	e8 d7 ff ff ff       	call   102181 <trap>

    # pop the pushed stack pointer
    popl %esp
  1021aa:	5c                   	pop    %esp

001021ab <__trapret>:

    # return falls through to trapret...
.globl __trapret
__trapret:
    # restore registers from stack
    popal
  1021ab:	61                   	popa   

    # restore %ds, %es, %fs and %gs
    popl %gs
  1021ac:	0f a9                	pop    %gs
    popl %fs
  1021ae:	0f a1                	pop    %fs
    popl %es
  1021b0:	07                   	pop    %es
    popl %ds
  1021b1:	1f                   	pop    %ds

    # get rid of the trap number and error code
    addl $0x8, %esp
  1021b2:	83 c4 08             	add    $0x8,%esp
    iret
  1021b5:	cf                   	iret   

001021b6 <vector0>:
# handler
.text
.globl __alltraps
.globl vector0
vector0:
  pushl $0
  1021b6:	6a 00                	push   $0x0
  pushl $0
  1021b8:	6a 00                	push   $0x0
  jmp __alltraps
  1021ba:	e9 d5 ff ff ff       	jmp    102194 <__alltraps>

001021bf <vector1>:
.globl vector1
vector1:
  pushl $0
  1021bf:	6a 00                	push   $0x0
  pushl $1
  1021c1:	6a 01                	push   $0x1
  jmp __alltraps
  1021c3:	e9 cc ff ff ff       	jmp    102194 <__alltraps>

001021c8 <vector2>:
.globl vector2
vector2:
  pushl $0
  1021c8:	6a 00                	push   $0x0
  pushl $2
  1021ca:	6a 02                	push   $0x2
  jmp __alltraps
  1021cc:	e9 c3 ff ff ff       	jmp    102194 <__alltraps>

001021d1 <vector3>:
.globl vector3
vector3:
  pushl $0
  1021d1:	6a 00                	push   $0x0
  pushl $3
  1021d3:	6a 03                	push   $0x3
  jmp __alltraps
  1021d5:	e9 ba ff ff ff       	jmp    102194 <__alltraps>

001021da <vector4>:
.globl vector4
vector4:
  pushl $0
  1021da:	6a 00                	push   $0x0
  pushl $4
  1021dc:	6a 04                	push   $0x4
  jmp __alltraps
  1021de:	e9 b1 ff ff ff       	jmp    102194 <__alltraps>

001021e3 <vector5>:
.globl vector5
vector5:
  pushl $0
  1021e3:	6a 00                	push   $0x0
  pushl $5
  1021e5:	6a 05                	push   $0x5
  jmp __alltraps
  1021e7:	e9 a8 ff ff ff       	jmp    102194 <__alltraps>

001021ec <vector6>:
.globl vector6
vector6:
  pushl $0
  1021ec:	6a 00                	push   $0x0
  pushl $6
  1021ee:	6a 06                	push   $0x6
  jmp __alltraps
  1021f0:	e9 9f ff ff ff       	jmp    102194 <__alltraps>

001021f5 <vector7>:
.globl vector7
vector7:
  pushl $0
  1021f5:	6a 00                	push   $0x0
  pushl $7
  1021f7:	6a 07                	push   $0x7
  jmp __alltraps
  1021f9:	e9 96 ff ff ff       	jmp    102194 <__alltraps>

001021fe <vector8>:
.globl vector8
vector8:
  pushl $8
  1021fe:	6a 08                	push   $0x8
  jmp __alltraps
  102200:	e9 8f ff ff ff       	jmp    102194 <__alltraps>

00102205 <vector9>:
.globl vector9
vector9:
  pushl $0
  102205:	6a 00                	push   $0x0
  pushl $9
  102207:	6a 09                	push   $0x9
  jmp __alltraps
  102209:	e9 86 ff ff ff       	jmp    102194 <__alltraps>

0010220e <vector10>:
.globl vector10
vector10:
  pushl $10
  10220e:	6a 0a                	push   $0xa
  jmp __alltraps
  102210:	e9 7f ff ff ff       	jmp    102194 <__alltraps>

00102215 <vector11>:
.globl vector11
vector11:
  pushl $11
  102215:	6a 0b                	push   $0xb
  jmp __alltraps
  102217:	e9 78 ff ff ff       	jmp    102194 <__alltraps>

0010221c <vector12>:
.globl vector12
vector12:
  pushl $12
  10221c:	6a 0c                	push   $0xc
  jmp __alltraps
  10221e:	e9 71 ff ff ff       	jmp    102194 <__alltraps>

00102223 <vector13>:
.globl vector13
vector13:
  pushl $13
  102223:	6a 0d                	push   $0xd
  jmp __alltraps
  102225:	e9 6a ff ff ff       	jmp    102194 <__alltraps>

0010222a <vector14>:
.globl vector14
vector14:
  pushl $14
  10222a:	6a 0e                	push   $0xe
  jmp __alltraps
  10222c:	e9 63 ff ff ff       	jmp    102194 <__alltraps>

00102231 <vector15>:
.globl vector15
vector15:
  pushl $0
  102231:	6a 00                	push   $0x0
  pushl $15
  102233:	6a 0f                	push   $0xf
  jmp __alltraps
  102235:	e9 5a ff ff ff       	jmp    102194 <__alltraps>

0010223a <vector16>:
.globl vector16
vector16:
  pushl $0
  10223a:	6a 00                	push   $0x0
  pushl $16
  10223c:	6a 10                	push   $0x10
  jmp __alltraps
  10223e:	e9 51 ff ff ff       	jmp    102194 <__alltraps>

00102243 <vector17>:
.globl vector17
vector17:
  pushl $17
  102243:	6a 11                	push   $0x11
  jmp __alltraps
  102245:	e9 4a ff ff ff       	jmp    102194 <__alltraps>

0010224a <vector18>:
.globl vector18
vector18:
  pushl $0
  10224a:	6a 00                	push   $0x0
  pushl $18
  10224c:	6a 12                	push   $0x12
  jmp __alltraps
  10224e:	e9 41 ff ff ff       	jmp    102194 <__alltraps>

00102253 <vector19>:
.globl vector19
vector19:
  pushl $0
  102253:	6a 00                	push   $0x0
  pushl $19
  102255:	6a 13                	push   $0x13
  jmp __alltraps
  102257:	e9 38 ff ff ff       	jmp    102194 <__alltraps>

0010225c <vector20>:
.globl vector20
vector20:
  pushl $0
  10225c:	6a 00                	push   $0x0
  pushl $20
  10225e:	6a 14                	push   $0x14
  jmp __alltraps
  102260:	e9 2f ff ff ff       	jmp    102194 <__alltraps>

00102265 <vector21>:
.globl vector21
vector21:
  pushl $0
  102265:	6a 00                	push   $0x0
  pushl $21
  102267:	6a 15                	push   $0x15
  jmp __alltraps
  102269:	e9 26 ff ff ff       	jmp    102194 <__alltraps>

0010226e <vector22>:
.globl vector22
vector22:
  pushl $0
  10226e:	6a 00                	push   $0x0
  pushl $22
  102270:	6a 16                	push   $0x16
  jmp __alltraps
  102272:	e9 1d ff ff ff       	jmp    102194 <__alltraps>

00102277 <vector23>:
.globl vector23
vector23:
  pushl $0
  102277:	6a 00                	push   $0x0
  pushl $23
  102279:	6a 17                	push   $0x17
  jmp __alltraps
  10227b:	e9 14 ff ff ff       	jmp    102194 <__alltraps>

00102280 <vector24>:
.globl vector24
vector24:
  pushl $0
  102280:	6a 00                	push   $0x0
  pushl $24
  102282:	6a 18                	push   $0x18
  jmp __alltraps
  102284:	e9 0b ff ff ff       	jmp    102194 <__alltraps>

00102289 <vector25>:
.globl vector25
vector25:
  pushl $0
  102289:	6a 00                	push   $0x0
  pushl $25
  10228b:	6a 19                	push   $0x19
  jmp __alltraps
  10228d:	e9 02 ff ff ff       	jmp    102194 <__alltraps>

00102292 <vector26>:
.globl vector26
vector26:
  pushl $0
  102292:	6a 00                	push   $0x0
  pushl $26
  102294:	6a 1a                	push   $0x1a
  jmp __alltraps
  102296:	e9 f9 fe ff ff       	jmp    102194 <__alltraps>

0010229b <vector27>:
.globl vector27
vector27:
  pushl $0
  10229b:	6a 00                	push   $0x0
  pushl $27
  10229d:	6a 1b                	push   $0x1b
  jmp __alltraps
  10229f:	e9 f0 fe ff ff       	jmp    102194 <__alltraps>

001022a4 <vector28>:
.globl vector28
vector28:
  pushl $0
  1022a4:	6a 00                	push   $0x0
  pushl $28
  1022a6:	6a 1c                	push   $0x1c
  jmp __alltraps
  1022a8:	e9 e7 fe ff ff       	jmp    102194 <__alltraps>

001022ad <vector29>:
.globl vector29
vector29:
  pushl $0
  1022ad:	6a 00                	push   $0x0
  pushl $29
  1022af:	6a 1d                	push   $0x1d
  jmp __alltraps
  1022b1:	e9 de fe ff ff       	jmp    102194 <__alltraps>

001022b6 <vector30>:
.globl vector30
vector30:
  pushl $0
  1022b6:	6a 00                	push   $0x0
  pushl $30
  1022b8:	6a 1e                	push   $0x1e
  jmp __alltraps
  1022ba:	e9 d5 fe ff ff       	jmp    102194 <__alltraps>

001022bf <vector31>:
.globl vector31
vector31:
  pushl $0
  1022bf:	6a 00                	push   $0x0
  pushl $31
  1022c1:	6a 1f                	push   $0x1f
  jmp __alltraps
  1022c3:	e9 cc fe ff ff       	jmp    102194 <__alltraps>

001022c8 <vector32>:
.globl vector32
vector32:
  pushl $0
  1022c8:	6a 00                	push   $0x0
  pushl $32
  1022ca:	6a 20                	push   $0x20
  jmp __alltraps
  1022cc:	e9 c3 fe ff ff       	jmp    102194 <__alltraps>

001022d1 <vector33>:
.globl vector33
vector33:
  pushl $0
  1022d1:	6a 00                	push   $0x0
  pushl $33
  1022d3:	6a 21                	push   $0x21
  jmp __alltraps
  1022d5:	e9 ba fe ff ff       	jmp    102194 <__alltraps>

001022da <vector34>:
.globl vector34
vector34:
  pushl $0
  1022da:	6a 00                	push   $0x0
  pushl $34
  1022dc:	6a 22                	push   $0x22
  jmp __alltraps
  1022de:	e9 b1 fe ff ff       	jmp    102194 <__alltraps>

001022e3 <vector35>:
.globl vector35
vector35:
  pushl $0
  1022e3:	6a 00                	push   $0x0
  pushl $35
  1022e5:	6a 23                	push   $0x23
  jmp __alltraps
  1022e7:	e9 a8 fe ff ff       	jmp    102194 <__alltraps>

001022ec <vector36>:
.globl vector36
vector36:
  pushl $0
  1022ec:	6a 00                	push   $0x0
  pushl $36
  1022ee:	6a 24                	push   $0x24
  jmp __alltraps
  1022f0:	e9 9f fe ff ff       	jmp    102194 <__alltraps>

001022f5 <vector37>:
.globl vector37
vector37:
  pushl $0
  1022f5:	6a 00                	push   $0x0
  pushl $37
  1022f7:	6a 25                	push   $0x25
  jmp __alltraps
  1022f9:	e9 96 fe ff ff       	jmp    102194 <__alltraps>

001022fe <vector38>:
.globl vector38
vector38:
  pushl $0
  1022fe:	6a 00                	push   $0x0
  pushl $38
  102300:	6a 26                	push   $0x26
  jmp __alltraps
  102302:	e9 8d fe ff ff       	jmp    102194 <__alltraps>

00102307 <vector39>:
.globl vector39
vector39:
  pushl $0
  102307:	6a 00                	push   $0x0
  pushl $39
  102309:	6a 27                	push   $0x27
  jmp __alltraps
  10230b:	e9 84 fe ff ff       	jmp    102194 <__alltraps>

00102310 <vector40>:
.globl vector40
vector40:
  pushl $0
  102310:	6a 00                	push   $0x0
  pushl $40
  102312:	6a 28                	push   $0x28
  jmp __alltraps
  102314:	e9 7b fe ff ff       	jmp    102194 <__alltraps>

00102319 <vector41>:
.globl vector41
vector41:
  pushl $0
  102319:	6a 00                	push   $0x0
  pushl $41
  10231b:	6a 29                	push   $0x29
  jmp __alltraps
  10231d:	e9 72 fe ff ff       	jmp    102194 <__alltraps>

00102322 <vector42>:
.globl vector42
vector42:
  pushl $0
  102322:	6a 00                	push   $0x0
  pushl $42
  102324:	6a 2a                	push   $0x2a
  jmp __alltraps
  102326:	e9 69 fe ff ff       	jmp    102194 <__alltraps>

0010232b <vector43>:
.globl vector43
vector43:
  pushl $0
  10232b:	6a 00                	push   $0x0
  pushl $43
  10232d:	6a 2b                	push   $0x2b
  jmp __alltraps
  10232f:	e9 60 fe ff ff       	jmp    102194 <__alltraps>

00102334 <vector44>:
.globl vector44
vector44:
  pushl $0
  102334:	6a 00                	push   $0x0
  pushl $44
  102336:	6a 2c                	push   $0x2c
  jmp __alltraps
  102338:	e9 57 fe ff ff       	jmp    102194 <__alltraps>

0010233d <vector45>:
.globl vector45
vector45:
  pushl $0
  10233d:	6a 00                	push   $0x0
  pushl $45
  10233f:	6a 2d                	push   $0x2d
  jmp __alltraps
  102341:	e9 4e fe ff ff       	jmp    102194 <__alltraps>

00102346 <vector46>:
.globl vector46
vector46:
  pushl $0
  102346:	6a 00                	push   $0x0
  pushl $46
  102348:	6a 2e                	push   $0x2e
  jmp __alltraps
  10234a:	e9 45 fe ff ff       	jmp    102194 <__alltraps>

0010234f <vector47>:
.globl vector47
vector47:
  pushl $0
  10234f:	6a 00                	push   $0x0
  pushl $47
  102351:	6a 2f                	push   $0x2f
  jmp __alltraps
  102353:	e9 3c fe ff ff       	jmp    102194 <__alltraps>

00102358 <vector48>:
.globl vector48
vector48:
  pushl $0
  102358:	6a 00                	push   $0x0
  pushl $48
  10235a:	6a 30                	push   $0x30
  jmp __alltraps
  10235c:	e9 33 fe ff ff       	jmp    102194 <__alltraps>

00102361 <vector49>:
.globl vector49
vector49:
  pushl $0
  102361:	6a 00                	push   $0x0
  pushl $49
  102363:	6a 31                	push   $0x31
  jmp __alltraps
  102365:	e9 2a fe ff ff       	jmp    102194 <__alltraps>

0010236a <vector50>:
.globl vector50
vector50:
  pushl $0
  10236a:	6a 00                	push   $0x0
  pushl $50
  10236c:	6a 32                	push   $0x32
  jmp __alltraps
  10236e:	e9 21 fe ff ff       	jmp    102194 <__alltraps>

00102373 <vector51>:
.globl vector51
vector51:
  pushl $0
  102373:	6a 00                	push   $0x0
  pushl $51
  102375:	6a 33                	push   $0x33
  jmp __alltraps
  102377:	e9 18 fe ff ff       	jmp    102194 <__alltraps>

0010237c <vector52>:
.globl vector52
vector52:
  pushl $0
  10237c:	6a 00                	push   $0x0
  pushl $52
  10237e:	6a 34                	push   $0x34
  jmp __alltraps
  102380:	e9 0f fe ff ff       	jmp    102194 <__alltraps>

00102385 <vector53>:
.globl vector53
vector53:
  pushl $0
  102385:	6a 00                	push   $0x0
  pushl $53
  102387:	6a 35                	push   $0x35
  jmp __alltraps
  102389:	e9 06 fe ff ff       	jmp    102194 <__alltraps>

0010238e <vector54>:
.globl vector54
vector54:
  pushl $0
  10238e:	6a 00                	push   $0x0
  pushl $54
  102390:	6a 36                	push   $0x36
  jmp __alltraps
  102392:	e9 fd fd ff ff       	jmp    102194 <__alltraps>

00102397 <vector55>:
.globl vector55
vector55:
  pushl $0
  102397:	6a 00                	push   $0x0
  pushl $55
  102399:	6a 37                	push   $0x37
  jmp __alltraps
  10239b:	e9 f4 fd ff ff       	jmp    102194 <__alltraps>

001023a0 <vector56>:
.globl vector56
vector56:
  pushl $0
  1023a0:	6a 00                	push   $0x0
  pushl $56
  1023a2:	6a 38                	push   $0x38
  jmp __alltraps
  1023a4:	e9 eb fd ff ff       	jmp    102194 <__alltraps>

001023a9 <vector57>:
.globl vector57
vector57:
  pushl $0
  1023a9:	6a 00                	push   $0x0
  pushl $57
  1023ab:	6a 39                	push   $0x39
  jmp __alltraps
  1023ad:	e9 e2 fd ff ff       	jmp    102194 <__alltraps>

001023b2 <vector58>:
.globl vector58
vector58:
  pushl $0
  1023b2:	6a 00                	push   $0x0
  pushl $58
  1023b4:	6a 3a                	push   $0x3a
  jmp __alltraps
  1023b6:	e9 d9 fd ff ff       	jmp    102194 <__alltraps>

001023bb <vector59>:
.globl vector59
vector59:
  pushl $0
  1023bb:	6a 00                	push   $0x0
  pushl $59
  1023bd:	6a 3b                	push   $0x3b
  jmp __alltraps
  1023bf:	e9 d0 fd ff ff       	jmp    102194 <__alltraps>

001023c4 <vector60>:
.globl vector60
vector60:
  pushl $0
  1023c4:	6a 00                	push   $0x0
  pushl $60
  1023c6:	6a 3c                	push   $0x3c
  jmp __alltraps
  1023c8:	e9 c7 fd ff ff       	jmp    102194 <__alltraps>

001023cd <vector61>:
.globl vector61
vector61:
  pushl $0
  1023cd:	6a 00                	push   $0x0
  pushl $61
  1023cf:	6a 3d                	push   $0x3d
  jmp __alltraps
  1023d1:	e9 be fd ff ff       	jmp    102194 <__alltraps>

001023d6 <vector62>:
.globl vector62
vector62:
  pushl $0
  1023d6:	6a 00                	push   $0x0
  pushl $62
  1023d8:	6a 3e                	push   $0x3e
  jmp __alltraps
  1023da:	e9 b5 fd ff ff       	jmp    102194 <__alltraps>

001023df <vector63>:
.globl vector63
vector63:
  pushl $0
  1023df:	6a 00                	push   $0x0
  pushl $63
  1023e1:	6a 3f                	push   $0x3f
  jmp __alltraps
  1023e3:	e9 ac fd ff ff       	jmp    102194 <__alltraps>

001023e8 <vector64>:
.globl vector64
vector64:
  pushl $0
  1023e8:	6a 00                	push   $0x0
  pushl $64
  1023ea:	6a 40                	push   $0x40
  jmp __alltraps
  1023ec:	e9 a3 fd ff ff       	jmp    102194 <__alltraps>

001023f1 <vector65>:
.globl vector65
vector65:
  pushl $0
  1023f1:	6a 00                	push   $0x0
  pushl $65
  1023f3:	6a 41                	push   $0x41
  jmp __alltraps
  1023f5:	e9 9a fd ff ff       	jmp    102194 <__alltraps>

001023fa <vector66>:
.globl vector66
vector66:
  pushl $0
  1023fa:	6a 00                	push   $0x0
  pushl $66
  1023fc:	6a 42                	push   $0x42
  jmp __alltraps
  1023fe:	e9 91 fd ff ff       	jmp    102194 <__alltraps>

00102403 <vector67>:
.globl vector67
vector67:
  pushl $0
  102403:	6a 00                	push   $0x0
  pushl $67
  102405:	6a 43                	push   $0x43
  jmp __alltraps
  102407:	e9 88 fd ff ff       	jmp    102194 <__alltraps>

0010240c <vector68>:
.globl vector68
vector68:
  pushl $0
  10240c:	6a 00                	push   $0x0
  pushl $68
  10240e:	6a 44                	push   $0x44
  jmp __alltraps
  102410:	e9 7f fd ff ff       	jmp    102194 <__alltraps>

00102415 <vector69>:
.globl vector69
vector69:
  pushl $0
  102415:	6a 00                	push   $0x0
  pushl $69
  102417:	6a 45                	push   $0x45
  jmp __alltraps
  102419:	e9 76 fd ff ff       	jmp    102194 <__alltraps>

0010241e <vector70>:
.globl vector70
vector70:
  pushl $0
  10241e:	6a 00                	push   $0x0
  pushl $70
  102420:	6a 46                	push   $0x46
  jmp __alltraps
  102422:	e9 6d fd ff ff       	jmp    102194 <__alltraps>

00102427 <vector71>:
.globl vector71
vector71:
  pushl $0
  102427:	6a 00                	push   $0x0
  pushl $71
  102429:	6a 47                	push   $0x47
  jmp __alltraps
  10242b:	e9 64 fd ff ff       	jmp    102194 <__alltraps>

00102430 <vector72>:
.globl vector72
vector72:
  pushl $0
  102430:	6a 00                	push   $0x0
  pushl $72
  102432:	6a 48                	push   $0x48
  jmp __alltraps
  102434:	e9 5b fd ff ff       	jmp    102194 <__alltraps>

00102439 <vector73>:
.globl vector73
vector73:
  pushl $0
  102439:	6a 00                	push   $0x0
  pushl $73
  10243b:	6a 49                	push   $0x49
  jmp __alltraps
  10243d:	e9 52 fd ff ff       	jmp    102194 <__alltraps>

00102442 <vector74>:
.globl vector74
vector74:
  pushl $0
  102442:	6a 00                	push   $0x0
  pushl $74
  102444:	6a 4a                	push   $0x4a
  jmp __alltraps
  102446:	e9 49 fd ff ff       	jmp    102194 <__alltraps>

0010244b <vector75>:
.globl vector75
vector75:
  pushl $0
  10244b:	6a 00                	push   $0x0
  pushl $75
  10244d:	6a 4b                	push   $0x4b
  jmp __alltraps
  10244f:	e9 40 fd ff ff       	jmp    102194 <__alltraps>

00102454 <vector76>:
.globl vector76
vector76:
  pushl $0
  102454:	6a 00                	push   $0x0
  pushl $76
  102456:	6a 4c                	push   $0x4c
  jmp __alltraps
  102458:	e9 37 fd ff ff       	jmp    102194 <__alltraps>

0010245d <vector77>:
.globl vector77
vector77:
  pushl $0
  10245d:	6a 00                	push   $0x0
  pushl $77
  10245f:	6a 4d                	push   $0x4d
  jmp __alltraps
  102461:	e9 2e fd ff ff       	jmp    102194 <__alltraps>

00102466 <vector78>:
.globl vector78
vector78:
  pushl $0
  102466:	6a 00                	push   $0x0
  pushl $78
  102468:	6a 4e                	push   $0x4e
  jmp __alltraps
  10246a:	e9 25 fd ff ff       	jmp    102194 <__alltraps>

0010246f <vector79>:
.globl vector79
vector79:
  pushl $0
  10246f:	6a 00                	push   $0x0
  pushl $79
  102471:	6a 4f                	push   $0x4f
  jmp __alltraps
  102473:	e9 1c fd ff ff       	jmp    102194 <__alltraps>

00102478 <vector80>:
.globl vector80
vector80:
  pushl $0
  102478:	6a 00                	push   $0x0
  pushl $80
  10247a:	6a 50                	push   $0x50
  jmp __alltraps
  10247c:	e9 13 fd ff ff       	jmp    102194 <__alltraps>

00102481 <vector81>:
.globl vector81
vector81:
  pushl $0
  102481:	6a 00                	push   $0x0
  pushl $81
  102483:	6a 51                	push   $0x51
  jmp __alltraps
  102485:	e9 0a fd ff ff       	jmp    102194 <__alltraps>

0010248a <vector82>:
.globl vector82
vector82:
  pushl $0
  10248a:	6a 00                	push   $0x0
  pushl $82
  10248c:	6a 52                	push   $0x52
  jmp __alltraps
  10248e:	e9 01 fd ff ff       	jmp    102194 <__alltraps>

00102493 <vector83>:
.globl vector83
vector83:
  pushl $0
  102493:	6a 00                	push   $0x0
  pushl $83
  102495:	6a 53                	push   $0x53
  jmp __alltraps
  102497:	e9 f8 fc ff ff       	jmp    102194 <__alltraps>

0010249c <vector84>:
.globl vector84
vector84:
  pushl $0
  10249c:	6a 00                	push   $0x0
  pushl $84
  10249e:	6a 54                	push   $0x54
  jmp __alltraps
  1024a0:	e9 ef fc ff ff       	jmp    102194 <__alltraps>

001024a5 <vector85>:
.globl vector85
vector85:
  pushl $0
  1024a5:	6a 00                	push   $0x0
  pushl $85
  1024a7:	6a 55                	push   $0x55
  jmp __alltraps
  1024a9:	e9 e6 fc ff ff       	jmp    102194 <__alltraps>

001024ae <vector86>:
.globl vector86
vector86:
  pushl $0
  1024ae:	6a 00                	push   $0x0
  pushl $86
  1024b0:	6a 56                	push   $0x56
  jmp __alltraps
  1024b2:	e9 dd fc ff ff       	jmp    102194 <__alltraps>

001024b7 <vector87>:
.globl vector87
vector87:
  pushl $0
  1024b7:	6a 00                	push   $0x0
  pushl $87
  1024b9:	6a 57                	push   $0x57
  jmp __alltraps
  1024bb:	e9 d4 fc ff ff       	jmp    102194 <__alltraps>

001024c0 <vector88>:
.globl vector88
vector88:
  pushl $0
  1024c0:	6a 00                	push   $0x0
  pushl $88
  1024c2:	6a 58                	push   $0x58
  jmp __alltraps
  1024c4:	e9 cb fc ff ff       	jmp    102194 <__alltraps>

001024c9 <vector89>:
.globl vector89
vector89:
  pushl $0
  1024c9:	6a 00                	push   $0x0
  pushl $89
  1024cb:	6a 59                	push   $0x59
  jmp __alltraps
  1024cd:	e9 c2 fc ff ff       	jmp    102194 <__alltraps>

001024d2 <vector90>:
.globl vector90
vector90:
  pushl $0
  1024d2:	6a 00                	push   $0x0
  pushl $90
  1024d4:	6a 5a                	push   $0x5a
  jmp __alltraps
  1024d6:	e9 b9 fc ff ff       	jmp    102194 <__alltraps>

001024db <vector91>:
.globl vector91
vector91:
  pushl $0
  1024db:	6a 00                	push   $0x0
  pushl $91
  1024dd:	6a 5b                	push   $0x5b
  jmp __alltraps
  1024df:	e9 b0 fc ff ff       	jmp    102194 <__alltraps>

001024e4 <vector92>:
.globl vector92
vector92:
  pushl $0
  1024e4:	6a 00                	push   $0x0
  pushl $92
  1024e6:	6a 5c                	push   $0x5c
  jmp __alltraps
  1024e8:	e9 a7 fc ff ff       	jmp    102194 <__alltraps>

001024ed <vector93>:
.globl vector93
vector93:
  pushl $0
  1024ed:	6a 00                	push   $0x0
  pushl $93
  1024ef:	6a 5d                	push   $0x5d
  jmp __alltraps
  1024f1:	e9 9e fc ff ff       	jmp    102194 <__alltraps>

001024f6 <vector94>:
.globl vector94
vector94:
  pushl $0
  1024f6:	6a 00                	push   $0x0
  pushl $94
  1024f8:	6a 5e                	push   $0x5e
  jmp __alltraps
  1024fa:	e9 95 fc ff ff       	jmp    102194 <__alltraps>

001024ff <vector95>:
.globl vector95
vector95:
  pushl $0
  1024ff:	6a 00                	push   $0x0
  pushl $95
  102501:	6a 5f                	push   $0x5f
  jmp __alltraps
  102503:	e9 8c fc ff ff       	jmp    102194 <__alltraps>

00102508 <vector96>:
.globl vector96
vector96:
  pushl $0
  102508:	6a 00                	push   $0x0
  pushl $96
  10250a:	6a 60                	push   $0x60
  jmp __alltraps
  10250c:	e9 83 fc ff ff       	jmp    102194 <__alltraps>

00102511 <vector97>:
.globl vector97
vector97:
  pushl $0
  102511:	6a 00                	push   $0x0
  pushl $97
  102513:	6a 61                	push   $0x61
  jmp __alltraps
  102515:	e9 7a fc ff ff       	jmp    102194 <__alltraps>

0010251a <vector98>:
.globl vector98
vector98:
  pushl $0
  10251a:	6a 00                	push   $0x0
  pushl $98
  10251c:	6a 62                	push   $0x62
  jmp __alltraps
  10251e:	e9 71 fc ff ff       	jmp    102194 <__alltraps>

00102523 <vector99>:
.globl vector99
vector99:
  pushl $0
  102523:	6a 00                	push   $0x0
  pushl $99
  102525:	6a 63                	push   $0x63
  jmp __alltraps
  102527:	e9 68 fc ff ff       	jmp    102194 <__alltraps>

0010252c <vector100>:
.globl vector100
vector100:
  pushl $0
  10252c:	6a 00                	push   $0x0
  pushl $100
  10252e:	6a 64                	push   $0x64
  jmp __alltraps
  102530:	e9 5f fc ff ff       	jmp    102194 <__alltraps>

00102535 <vector101>:
.globl vector101
vector101:
  pushl $0
  102535:	6a 00                	push   $0x0
  pushl $101
  102537:	6a 65                	push   $0x65
  jmp __alltraps
  102539:	e9 56 fc ff ff       	jmp    102194 <__alltraps>

0010253e <vector102>:
.globl vector102
vector102:
  pushl $0
  10253e:	6a 00                	push   $0x0
  pushl $102
  102540:	6a 66                	push   $0x66
  jmp __alltraps
  102542:	e9 4d fc ff ff       	jmp    102194 <__alltraps>

00102547 <vector103>:
.globl vector103
vector103:
  pushl $0
  102547:	6a 00                	push   $0x0
  pushl $103
  102549:	6a 67                	push   $0x67
  jmp __alltraps
  10254b:	e9 44 fc ff ff       	jmp    102194 <__alltraps>

00102550 <vector104>:
.globl vector104
vector104:
  pushl $0
  102550:	6a 00                	push   $0x0
  pushl $104
  102552:	6a 68                	push   $0x68
  jmp __alltraps
  102554:	e9 3b fc ff ff       	jmp    102194 <__alltraps>

00102559 <vector105>:
.globl vector105
vector105:
  pushl $0
  102559:	6a 00                	push   $0x0
  pushl $105
  10255b:	6a 69                	push   $0x69
  jmp __alltraps
  10255d:	e9 32 fc ff ff       	jmp    102194 <__alltraps>

00102562 <vector106>:
.globl vector106
vector106:
  pushl $0
  102562:	6a 00                	push   $0x0
  pushl $106
  102564:	6a 6a                	push   $0x6a
  jmp __alltraps
  102566:	e9 29 fc ff ff       	jmp    102194 <__alltraps>

0010256b <vector107>:
.globl vector107
vector107:
  pushl $0
  10256b:	6a 00                	push   $0x0
  pushl $107
  10256d:	6a 6b                	push   $0x6b
  jmp __alltraps
  10256f:	e9 20 fc ff ff       	jmp    102194 <__alltraps>

00102574 <vector108>:
.globl vector108
vector108:
  pushl $0
  102574:	6a 00                	push   $0x0
  pushl $108
  102576:	6a 6c                	push   $0x6c
  jmp __alltraps
  102578:	e9 17 fc ff ff       	jmp    102194 <__alltraps>

0010257d <vector109>:
.globl vector109
vector109:
  pushl $0
  10257d:	6a 00                	push   $0x0
  pushl $109
  10257f:	6a 6d                	push   $0x6d
  jmp __alltraps
  102581:	e9 0e fc ff ff       	jmp    102194 <__alltraps>

00102586 <vector110>:
.globl vector110
vector110:
  pushl $0
  102586:	6a 00                	push   $0x0
  pushl $110
  102588:	6a 6e                	push   $0x6e
  jmp __alltraps
  10258a:	e9 05 fc ff ff       	jmp    102194 <__alltraps>

0010258f <vector111>:
.globl vector111
vector111:
  pushl $0
  10258f:	6a 00                	push   $0x0
  pushl $111
  102591:	6a 6f                	push   $0x6f
  jmp __alltraps
  102593:	e9 fc fb ff ff       	jmp    102194 <__alltraps>

00102598 <vector112>:
.globl vector112
vector112:
  pushl $0
  102598:	6a 00                	push   $0x0
  pushl $112
  10259a:	6a 70                	push   $0x70
  jmp __alltraps
  10259c:	e9 f3 fb ff ff       	jmp    102194 <__alltraps>

001025a1 <vector113>:
.globl vector113
vector113:
  pushl $0
  1025a1:	6a 00                	push   $0x0
  pushl $113
  1025a3:	6a 71                	push   $0x71
  jmp __alltraps
  1025a5:	e9 ea fb ff ff       	jmp    102194 <__alltraps>

001025aa <vector114>:
.globl vector114
vector114:
  pushl $0
  1025aa:	6a 00                	push   $0x0
  pushl $114
  1025ac:	6a 72                	push   $0x72
  jmp __alltraps
  1025ae:	e9 e1 fb ff ff       	jmp    102194 <__alltraps>

001025b3 <vector115>:
.globl vector115
vector115:
  pushl $0
  1025b3:	6a 00                	push   $0x0
  pushl $115
  1025b5:	6a 73                	push   $0x73
  jmp __alltraps
  1025b7:	e9 d8 fb ff ff       	jmp    102194 <__alltraps>

001025bc <vector116>:
.globl vector116
vector116:
  pushl $0
  1025bc:	6a 00                	push   $0x0
  pushl $116
  1025be:	6a 74                	push   $0x74
  jmp __alltraps
  1025c0:	e9 cf fb ff ff       	jmp    102194 <__alltraps>

001025c5 <vector117>:
.globl vector117
vector117:
  pushl $0
  1025c5:	6a 00                	push   $0x0
  pushl $117
  1025c7:	6a 75                	push   $0x75
  jmp __alltraps
  1025c9:	e9 c6 fb ff ff       	jmp    102194 <__alltraps>

001025ce <vector118>:
.globl vector118
vector118:
  pushl $0
  1025ce:	6a 00                	push   $0x0
  pushl $118
  1025d0:	6a 76                	push   $0x76
  jmp __alltraps
  1025d2:	e9 bd fb ff ff       	jmp    102194 <__alltraps>

001025d7 <vector119>:
.globl vector119
vector119:
  pushl $0
  1025d7:	6a 00                	push   $0x0
  pushl $119
  1025d9:	6a 77                	push   $0x77
  jmp __alltraps
  1025db:	e9 b4 fb ff ff       	jmp    102194 <__alltraps>

001025e0 <vector120>:
.globl vector120
vector120:
  pushl $0
  1025e0:	6a 00                	push   $0x0
  pushl $120
  1025e2:	6a 78                	push   $0x78
  jmp __alltraps
  1025e4:	e9 ab fb ff ff       	jmp    102194 <__alltraps>

001025e9 <vector121>:
.globl vector121
vector121:
  pushl $0
  1025e9:	6a 00                	push   $0x0
  pushl $121
  1025eb:	6a 79                	push   $0x79
  jmp __alltraps
  1025ed:	e9 a2 fb ff ff       	jmp    102194 <__alltraps>

001025f2 <vector122>:
.globl vector122
vector122:
  pushl $0
  1025f2:	6a 00                	push   $0x0
  pushl $122
  1025f4:	6a 7a                	push   $0x7a
  jmp __alltraps
  1025f6:	e9 99 fb ff ff       	jmp    102194 <__alltraps>

001025fb <vector123>:
.globl vector123
vector123:
  pushl $0
  1025fb:	6a 00                	push   $0x0
  pushl $123
  1025fd:	6a 7b                	push   $0x7b
  jmp __alltraps
  1025ff:	e9 90 fb ff ff       	jmp    102194 <__alltraps>

00102604 <vector124>:
.globl vector124
vector124:
  pushl $0
  102604:	6a 00                	push   $0x0
  pushl $124
  102606:	6a 7c                	push   $0x7c
  jmp __alltraps
  102608:	e9 87 fb ff ff       	jmp    102194 <__alltraps>

0010260d <vector125>:
.globl vector125
vector125:
  pushl $0
  10260d:	6a 00                	push   $0x0
  pushl $125
  10260f:	6a 7d                	push   $0x7d
  jmp __alltraps
  102611:	e9 7e fb ff ff       	jmp    102194 <__alltraps>

00102616 <vector126>:
.globl vector126
vector126:
  pushl $0
  102616:	6a 00                	push   $0x0
  pushl $126
  102618:	6a 7e                	push   $0x7e
  jmp __alltraps
  10261a:	e9 75 fb ff ff       	jmp    102194 <__alltraps>

0010261f <vector127>:
.globl vector127
vector127:
  pushl $0
  10261f:	6a 00                	push   $0x0
  pushl $127
  102621:	6a 7f                	push   $0x7f
  jmp __alltraps
  102623:	e9 6c fb ff ff       	jmp    102194 <__alltraps>

00102628 <vector128>:
.globl vector128
vector128:
  pushl $0
  102628:	6a 00                	push   $0x0
  pushl $128
  10262a:	68 80 00 00 00       	push   $0x80
  jmp __alltraps
  10262f:	e9 60 fb ff ff       	jmp    102194 <__alltraps>

00102634 <vector129>:
.globl vector129
vector129:
  pushl $0
  102634:	6a 00                	push   $0x0
  pushl $129
  102636:	68 81 00 00 00       	push   $0x81
  jmp __alltraps
  10263b:	e9 54 fb ff ff       	jmp    102194 <__alltraps>

00102640 <vector130>:
.globl vector130
vector130:
  pushl $0
  102640:	6a 00                	push   $0x0
  pushl $130
  102642:	68 82 00 00 00       	push   $0x82
  jmp __alltraps
  102647:	e9 48 fb ff ff       	jmp    102194 <__alltraps>

0010264c <vector131>:
.globl vector131
vector131:
  pushl $0
  10264c:	6a 00                	push   $0x0
  pushl $131
  10264e:	68 83 00 00 00       	push   $0x83
  jmp __alltraps
  102653:	e9 3c fb ff ff       	jmp    102194 <__alltraps>

00102658 <vector132>:
.globl vector132
vector132:
  pushl $0
  102658:	6a 00                	push   $0x0
  pushl $132
  10265a:	68 84 00 00 00       	push   $0x84
  jmp __alltraps
  10265f:	e9 30 fb ff ff       	jmp    102194 <__alltraps>

00102664 <vector133>:
.globl vector133
vector133:
  pushl $0
  102664:	6a 00                	push   $0x0
  pushl $133
  102666:	68 85 00 00 00       	push   $0x85
  jmp __alltraps
  10266b:	e9 24 fb ff ff       	jmp    102194 <__alltraps>

00102670 <vector134>:
.globl vector134
vector134:
  pushl $0
  102670:	6a 00                	push   $0x0
  pushl $134
  102672:	68 86 00 00 00       	push   $0x86
  jmp __alltraps
  102677:	e9 18 fb ff ff       	jmp    102194 <__alltraps>

0010267c <vector135>:
.globl vector135
vector135:
  pushl $0
  10267c:	6a 00                	push   $0x0
  pushl $135
  10267e:	68 87 00 00 00       	push   $0x87
  jmp __alltraps
  102683:	e9 0c fb ff ff       	jmp    102194 <__alltraps>

00102688 <vector136>:
.globl vector136
vector136:
  pushl $0
  102688:	6a 00                	push   $0x0
  pushl $136
  10268a:	68 88 00 00 00       	push   $0x88
  jmp __alltraps
  10268f:	e9 00 fb ff ff       	jmp    102194 <__alltraps>

00102694 <vector137>:
.globl vector137
vector137:
  pushl $0
  102694:	6a 00                	push   $0x0
  pushl $137
  102696:	68 89 00 00 00       	push   $0x89
  jmp __alltraps
  10269b:	e9 f4 fa ff ff       	jmp    102194 <__alltraps>

001026a0 <vector138>:
.globl vector138
vector138:
  pushl $0
  1026a0:	6a 00                	push   $0x0
  pushl $138
  1026a2:	68 8a 00 00 00       	push   $0x8a
  jmp __alltraps
  1026a7:	e9 e8 fa ff ff       	jmp    102194 <__alltraps>

001026ac <vector139>:
.globl vector139
vector139:
  pushl $0
  1026ac:	6a 00                	push   $0x0
  pushl $139
  1026ae:	68 8b 00 00 00       	push   $0x8b
  jmp __alltraps
  1026b3:	e9 dc fa ff ff       	jmp    102194 <__alltraps>

001026b8 <vector140>:
.globl vector140
vector140:
  pushl $0
  1026b8:	6a 00                	push   $0x0
  pushl $140
  1026ba:	68 8c 00 00 00       	push   $0x8c
  jmp __alltraps
  1026bf:	e9 d0 fa ff ff       	jmp    102194 <__alltraps>

001026c4 <vector141>:
.globl vector141
vector141:
  pushl $0
  1026c4:	6a 00                	push   $0x0
  pushl $141
  1026c6:	68 8d 00 00 00       	push   $0x8d
  jmp __alltraps
  1026cb:	e9 c4 fa ff ff       	jmp    102194 <__alltraps>

001026d0 <vector142>:
.globl vector142
vector142:
  pushl $0
  1026d0:	6a 00                	push   $0x0
  pushl $142
  1026d2:	68 8e 00 00 00       	push   $0x8e
  jmp __alltraps
  1026d7:	e9 b8 fa ff ff       	jmp    102194 <__alltraps>

001026dc <vector143>:
.globl vector143
vector143:
  pushl $0
  1026dc:	6a 00                	push   $0x0
  pushl $143
  1026de:	68 8f 00 00 00       	push   $0x8f
  jmp __alltraps
  1026e3:	e9 ac fa ff ff       	jmp    102194 <__alltraps>

001026e8 <vector144>:
.globl vector144
vector144:
  pushl $0
  1026e8:	6a 00                	push   $0x0
  pushl $144
  1026ea:	68 90 00 00 00       	push   $0x90
  jmp __alltraps
  1026ef:	e9 a0 fa ff ff       	jmp    102194 <__alltraps>

001026f4 <vector145>:
.globl vector145
vector145:
  pushl $0
  1026f4:	6a 00                	push   $0x0
  pushl $145
  1026f6:	68 91 00 00 00       	push   $0x91
  jmp __alltraps
  1026fb:	e9 94 fa ff ff       	jmp    102194 <__alltraps>

00102700 <vector146>:
.globl vector146
vector146:
  pushl $0
  102700:	6a 00                	push   $0x0
  pushl $146
  102702:	68 92 00 00 00       	push   $0x92
  jmp __alltraps
  102707:	e9 88 fa ff ff       	jmp    102194 <__alltraps>

0010270c <vector147>:
.globl vector147
vector147:
  pushl $0
  10270c:	6a 00                	push   $0x0
  pushl $147
  10270e:	68 93 00 00 00       	push   $0x93
  jmp __alltraps
  102713:	e9 7c fa ff ff       	jmp    102194 <__alltraps>

00102718 <vector148>:
.globl vector148
vector148:
  pushl $0
  102718:	6a 00                	push   $0x0
  pushl $148
  10271a:	68 94 00 00 00       	push   $0x94
  jmp __alltraps
  10271f:	e9 70 fa ff ff       	jmp    102194 <__alltraps>

00102724 <vector149>:
.globl vector149
vector149:
  pushl $0
  102724:	6a 00                	push   $0x0
  pushl $149
  102726:	68 95 00 00 00       	push   $0x95
  jmp __alltraps
  10272b:	e9 64 fa ff ff       	jmp    102194 <__alltraps>

00102730 <vector150>:
.globl vector150
vector150:
  pushl $0
  102730:	6a 00                	push   $0x0
  pushl $150
  102732:	68 96 00 00 00       	push   $0x96
  jmp __alltraps
  102737:	e9 58 fa ff ff       	jmp    102194 <__alltraps>

0010273c <vector151>:
.globl vector151
vector151:
  pushl $0
  10273c:	6a 00                	push   $0x0
  pushl $151
  10273e:	68 97 00 00 00       	push   $0x97
  jmp __alltraps
  102743:	e9 4c fa ff ff       	jmp    102194 <__alltraps>

00102748 <vector152>:
.globl vector152
vector152:
  pushl $0
  102748:	6a 00                	push   $0x0
  pushl $152
  10274a:	68 98 00 00 00       	push   $0x98
  jmp __alltraps
  10274f:	e9 40 fa ff ff       	jmp    102194 <__alltraps>

00102754 <vector153>:
.globl vector153
vector153:
  pushl $0
  102754:	6a 00                	push   $0x0
  pushl $153
  102756:	68 99 00 00 00       	push   $0x99
  jmp __alltraps
  10275b:	e9 34 fa ff ff       	jmp    102194 <__alltraps>

00102760 <vector154>:
.globl vector154
vector154:
  pushl $0
  102760:	6a 00                	push   $0x0
  pushl $154
  102762:	68 9a 00 00 00       	push   $0x9a
  jmp __alltraps
  102767:	e9 28 fa ff ff       	jmp    102194 <__alltraps>

0010276c <vector155>:
.globl vector155
vector155:
  pushl $0
  10276c:	6a 00                	push   $0x0
  pushl $155
  10276e:	68 9b 00 00 00       	push   $0x9b
  jmp __alltraps
  102773:	e9 1c fa ff ff       	jmp    102194 <__alltraps>

00102778 <vector156>:
.globl vector156
vector156:
  pushl $0
  102778:	6a 00                	push   $0x0
  pushl $156
  10277a:	68 9c 00 00 00       	push   $0x9c
  jmp __alltraps
  10277f:	e9 10 fa ff ff       	jmp    102194 <__alltraps>

00102784 <vector157>:
.globl vector157
vector157:
  pushl $0
  102784:	6a 00                	push   $0x0
  pushl $157
  102786:	68 9d 00 00 00       	push   $0x9d
  jmp __alltraps
  10278b:	e9 04 fa ff ff       	jmp    102194 <__alltraps>

00102790 <vector158>:
.globl vector158
vector158:
  pushl $0
  102790:	6a 00                	push   $0x0
  pushl $158
  102792:	68 9e 00 00 00       	push   $0x9e
  jmp __alltraps
  102797:	e9 f8 f9 ff ff       	jmp    102194 <__alltraps>

0010279c <vector159>:
.globl vector159
vector159:
  pushl $0
  10279c:	6a 00                	push   $0x0
  pushl $159
  10279e:	68 9f 00 00 00       	push   $0x9f
  jmp __alltraps
  1027a3:	e9 ec f9 ff ff       	jmp    102194 <__alltraps>

001027a8 <vector160>:
.globl vector160
vector160:
  pushl $0
  1027a8:	6a 00                	push   $0x0
  pushl $160
  1027aa:	68 a0 00 00 00       	push   $0xa0
  jmp __alltraps
  1027af:	e9 e0 f9 ff ff       	jmp    102194 <__alltraps>

001027b4 <vector161>:
.globl vector161
vector161:
  pushl $0
  1027b4:	6a 00                	push   $0x0
  pushl $161
  1027b6:	68 a1 00 00 00       	push   $0xa1
  jmp __alltraps
  1027bb:	e9 d4 f9 ff ff       	jmp    102194 <__alltraps>

001027c0 <vector162>:
.globl vector162
vector162:
  pushl $0
  1027c0:	6a 00                	push   $0x0
  pushl $162
  1027c2:	68 a2 00 00 00       	push   $0xa2
  jmp __alltraps
  1027c7:	e9 c8 f9 ff ff       	jmp    102194 <__alltraps>

001027cc <vector163>:
.globl vector163
vector163:
  pushl $0
  1027cc:	6a 00                	push   $0x0
  pushl $163
  1027ce:	68 a3 00 00 00       	push   $0xa3
  jmp __alltraps
  1027d3:	e9 bc f9 ff ff       	jmp    102194 <__alltraps>

001027d8 <vector164>:
.globl vector164
vector164:
  pushl $0
  1027d8:	6a 00                	push   $0x0
  pushl $164
  1027da:	68 a4 00 00 00       	push   $0xa4
  jmp __alltraps
  1027df:	e9 b0 f9 ff ff       	jmp    102194 <__alltraps>

001027e4 <vector165>:
.globl vector165
vector165:
  pushl $0
  1027e4:	6a 00                	push   $0x0
  pushl $165
  1027e6:	68 a5 00 00 00       	push   $0xa5
  jmp __alltraps
  1027eb:	e9 a4 f9 ff ff       	jmp    102194 <__alltraps>

001027f0 <vector166>:
.globl vector166
vector166:
  pushl $0
  1027f0:	6a 00                	push   $0x0
  pushl $166
  1027f2:	68 a6 00 00 00       	push   $0xa6
  jmp __alltraps
  1027f7:	e9 98 f9 ff ff       	jmp    102194 <__alltraps>

001027fc <vector167>:
.globl vector167
vector167:
  pushl $0
  1027fc:	6a 00                	push   $0x0
  pushl $167
  1027fe:	68 a7 00 00 00       	push   $0xa7
  jmp __alltraps
  102803:	e9 8c f9 ff ff       	jmp    102194 <__alltraps>

00102808 <vector168>:
.globl vector168
vector168:
  pushl $0
  102808:	6a 00                	push   $0x0
  pushl $168
  10280a:	68 a8 00 00 00       	push   $0xa8
  jmp __alltraps
  10280f:	e9 80 f9 ff ff       	jmp    102194 <__alltraps>

00102814 <vector169>:
.globl vector169
vector169:
  pushl $0
  102814:	6a 00                	push   $0x0
  pushl $169
  102816:	68 a9 00 00 00       	push   $0xa9
  jmp __alltraps
  10281b:	e9 74 f9 ff ff       	jmp    102194 <__alltraps>

00102820 <vector170>:
.globl vector170
vector170:
  pushl $0
  102820:	6a 00                	push   $0x0
  pushl $170
  102822:	68 aa 00 00 00       	push   $0xaa
  jmp __alltraps
  102827:	e9 68 f9 ff ff       	jmp    102194 <__alltraps>

0010282c <vector171>:
.globl vector171
vector171:
  pushl $0
  10282c:	6a 00                	push   $0x0
  pushl $171
  10282e:	68 ab 00 00 00       	push   $0xab
  jmp __alltraps
  102833:	e9 5c f9 ff ff       	jmp    102194 <__alltraps>

00102838 <vector172>:
.globl vector172
vector172:
  pushl $0
  102838:	6a 00                	push   $0x0
  pushl $172
  10283a:	68 ac 00 00 00       	push   $0xac
  jmp __alltraps
  10283f:	e9 50 f9 ff ff       	jmp    102194 <__alltraps>

00102844 <vector173>:
.globl vector173
vector173:
  pushl $0
  102844:	6a 00                	push   $0x0
  pushl $173
  102846:	68 ad 00 00 00       	push   $0xad
  jmp __alltraps
  10284b:	e9 44 f9 ff ff       	jmp    102194 <__alltraps>

00102850 <vector174>:
.globl vector174
vector174:
  pushl $0
  102850:	6a 00                	push   $0x0
  pushl $174
  102852:	68 ae 00 00 00       	push   $0xae
  jmp __alltraps
  102857:	e9 38 f9 ff ff       	jmp    102194 <__alltraps>

0010285c <vector175>:
.globl vector175
vector175:
  pushl $0
  10285c:	6a 00                	push   $0x0
  pushl $175
  10285e:	68 af 00 00 00       	push   $0xaf
  jmp __alltraps
  102863:	e9 2c f9 ff ff       	jmp    102194 <__alltraps>

00102868 <vector176>:
.globl vector176
vector176:
  pushl $0
  102868:	6a 00                	push   $0x0
  pushl $176
  10286a:	68 b0 00 00 00       	push   $0xb0
  jmp __alltraps
  10286f:	e9 20 f9 ff ff       	jmp    102194 <__alltraps>

00102874 <vector177>:
.globl vector177
vector177:
  pushl $0
  102874:	6a 00                	push   $0x0
  pushl $177
  102876:	68 b1 00 00 00       	push   $0xb1
  jmp __alltraps
  10287b:	e9 14 f9 ff ff       	jmp    102194 <__alltraps>

00102880 <vector178>:
.globl vector178
vector178:
  pushl $0
  102880:	6a 00                	push   $0x0
  pushl $178
  102882:	68 b2 00 00 00       	push   $0xb2
  jmp __alltraps
  102887:	e9 08 f9 ff ff       	jmp    102194 <__alltraps>

0010288c <vector179>:
.globl vector179
vector179:
  pushl $0
  10288c:	6a 00                	push   $0x0
  pushl $179
  10288e:	68 b3 00 00 00       	push   $0xb3
  jmp __alltraps
  102893:	e9 fc f8 ff ff       	jmp    102194 <__alltraps>

00102898 <vector180>:
.globl vector180
vector180:
  pushl $0
  102898:	6a 00                	push   $0x0
  pushl $180
  10289a:	68 b4 00 00 00       	push   $0xb4
  jmp __alltraps
  10289f:	e9 f0 f8 ff ff       	jmp    102194 <__alltraps>

001028a4 <vector181>:
.globl vector181
vector181:
  pushl $0
  1028a4:	6a 00                	push   $0x0
  pushl $181
  1028a6:	68 b5 00 00 00       	push   $0xb5
  jmp __alltraps
  1028ab:	e9 e4 f8 ff ff       	jmp    102194 <__alltraps>

001028b0 <vector182>:
.globl vector182
vector182:
  pushl $0
  1028b0:	6a 00                	push   $0x0
  pushl $182
  1028b2:	68 b6 00 00 00       	push   $0xb6
  jmp __alltraps
  1028b7:	e9 d8 f8 ff ff       	jmp    102194 <__alltraps>

001028bc <vector183>:
.globl vector183
vector183:
  pushl $0
  1028bc:	6a 00                	push   $0x0
  pushl $183
  1028be:	68 b7 00 00 00       	push   $0xb7
  jmp __alltraps
  1028c3:	e9 cc f8 ff ff       	jmp    102194 <__alltraps>

001028c8 <vector184>:
.globl vector184
vector184:
  pushl $0
  1028c8:	6a 00                	push   $0x0
  pushl $184
  1028ca:	68 b8 00 00 00       	push   $0xb8
  jmp __alltraps
  1028cf:	e9 c0 f8 ff ff       	jmp    102194 <__alltraps>

001028d4 <vector185>:
.globl vector185
vector185:
  pushl $0
  1028d4:	6a 00                	push   $0x0
  pushl $185
  1028d6:	68 b9 00 00 00       	push   $0xb9
  jmp __alltraps
  1028db:	e9 b4 f8 ff ff       	jmp    102194 <__alltraps>

001028e0 <vector186>:
.globl vector186
vector186:
  pushl $0
  1028e0:	6a 00                	push   $0x0
  pushl $186
  1028e2:	68 ba 00 00 00       	push   $0xba
  jmp __alltraps
  1028e7:	e9 a8 f8 ff ff       	jmp    102194 <__alltraps>

001028ec <vector187>:
.globl vector187
vector187:
  pushl $0
  1028ec:	6a 00                	push   $0x0
  pushl $187
  1028ee:	68 bb 00 00 00       	push   $0xbb
  jmp __alltraps
  1028f3:	e9 9c f8 ff ff       	jmp    102194 <__alltraps>

001028f8 <vector188>:
.globl vector188
vector188:
  pushl $0
  1028f8:	6a 00                	push   $0x0
  pushl $188
  1028fa:	68 bc 00 00 00       	push   $0xbc
  jmp __alltraps
  1028ff:	e9 90 f8 ff ff       	jmp    102194 <__alltraps>

00102904 <vector189>:
.globl vector189
vector189:
  pushl $0
  102904:	6a 00                	push   $0x0
  pushl $189
  102906:	68 bd 00 00 00       	push   $0xbd
  jmp __alltraps
  10290b:	e9 84 f8 ff ff       	jmp    102194 <__alltraps>

00102910 <vector190>:
.globl vector190
vector190:
  pushl $0
  102910:	6a 00                	push   $0x0
  pushl $190
  102912:	68 be 00 00 00       	push   $0xbe
  jmp __alltraps
  102917:	e9 78 f8 ff ff       	jmp    102194 <__alltraps>

0010291c <vector191>:
.globl vector191
vector191:
  pushl $0
  10291c:	6a 00                	push   $0x0
  pushl $191
  10291e:	68 bf 00 00 00       	push   $0xbf
  jmp __alltraps
  102923:	e9 6c f8 ff ff       	jmp    102194 <__alltraps>

00102928 <vector192>:
.globl vector192
vector192:
  pushl $0
  102928:	6a 00                	push   $0x0
  pushl $192
  10292a:	68 c0 00 00 00       	push   $0xc0
  jmp __alltraps
  10292f:	e9 60 f8 ff ff       	jmp    102194 <__alltraps>

00102934 <vector193>:
.globl vector193
vector193:
  pushl $0
  102934:	6a 00                	push   $0x0
  pushl $193
  102936:	68 c1 00 00 00       	push   $0xc1
  jmp __alltraps
  10293b:	e9 54 f8 ff ff       	jmp    102194 <__alltraps>

00102940 <vector194>:
.globl vector194
vector194:
  pushl $0
  102940:	6a 00                	push   $0x0
  pushl $194
  102942:	68 c2 00 00 00       	push   $0xc2
  jmp __alltraps
  102947:	e9 48 f8 ff ff       	jmp    102194 <__alltraps>

0010294c <vector195>:
.globl vector195
vector195:
  pushl $0
  10294c:	6a 00                	push   $0x0
  pushl $195
  10294e:	68 c3 00 00 00       	push   $0xc3
  jmp __alltraps
  102953:	e9 3c f8 ff ff       	jmp    102194 <__alltraps>

00102958 <vector196>:
.globl vector196
vector196:
  pushl $0
  102958:	6a 00                	push   $0x0
  pushl $196
  10295a:	68 c4 00 00 00       	push   $0xc4
  jmp __alltraps
  10295f:	e9 30 f8 ff ff       	jmp    102194 <__alltraps>

00102964 <vector197>:
.globl vector197
vector197:
  pushl $0
  102964:	6a 00                	push   $0x0
  pushl $197
  102966:	68 c5 00 00 00       	push   $0xc5
  jmp __alltraps
  10296b:	e9 24 f8 ff ff       	jmp    102194 <__alltraps>

00102970 <vector198>:
.globl vector198
vector198:
  pushl $0
  102970:	6a 00                	push   $0x0
  pushl $198
  102972:	68 c6 00 00 00       	push   $0xc6
  jmp __alltraps
  102977:	e9 18 f8 ff ff       	jmp    102194 <__alltraps>

0010297c <vector199>:
.globl vector199
vector199:
  pushl $0
  10297c:	6a 00                	push   $0x0
  pushl $199
  10297e:	68 c7 00 00 00       	push   $0xc7
  jmp __alltraps
  102983:	e9 0c f8 ff ff       	jmp    102194 <__alltraps>

00102988 <vector200>:
.globl vector200
vector200:
  pushl $0
  102988:	6a 00                	push   $0x0
  pushl $200
  10298a:	68 c8 00 00 00       	push   $0xc8
  jmp __alltraps
  10298f:	e9 00 f8 ff ff       	jmp    102194 <__alltraps>

00102994 <vector201>:
.globl vector201
vector201:
  pushl $0
  102994:	6a 00                	push   $0x0
  pushl $201
  102996:	68 c9 00 00 00       	push   $0xc9
  jmp __alltraps
  10299b:	e9 f4 f7 ff ff       	jmp    102194 <__alltraps>

001029a0 <vector202>:
.globl vector202
vector202:
  pushl $0
  1029a0:	6a 00                	push   $0x0
  pushl $202
  1029a2:	68 ca 00 00 00       	push   $0xca
  jmp __alltraps
  1029a7:	e9 e8 f7 ff ff       	jmp    102194 <__alltraps>

001029ac <vector203>:
.globl vector203
vector203:
  pushl $0
  1029ac:	6a 00                	push   $0x0
  pushl $203
  1029ae:	68 cb 00 00 00       	push   $0xcb
  jmp __alltraps
  1029b3:	e9 dc f7 ff ff       	jmp    102194 <__alltraps>

001029b8 <vector204>:
.globl vector204
vector204:
  pushl $0
  1029b8:	6a 00                	push   $0x0
  pushl $204
  1029ba:	68 cc 00 00 00       	push   $0xcc
  jmp __alltraps
  1029bf:	e9 d0 f7 ff ff       	jmp    102194 <__alltraps>

001029c4 <vector205>:
.globl vector205
vector205:
  pushl $0
  1029c4:	6a 00                	push   $0x0
  pushl $205
  1029c6:	68 cd 00 00 00       	push   $0xcd
  jmp __alltraps
  1029cb:	e9 c4 f7 ff ff       	jmp    102194 <__alltraps>

001029d0 <vector206>:
.globl vector206
vector206:
  pushl $0
  1029d0:	6a 00                	push   $0x0
  pushl $206
  1029d2:	68 ce 00 00 00       	push   $0xce
  jmp __alltraps
  1029d7:	e9 b8 f7 ff ff       	jmp    102194 <__alltraps>

001029dc <vector207>:
.globl vector207
vector207:
  pushl $0
  1029dc:	6a 00                	push   $0x0
  pushl $207
  1029de:	68 cf 00 00 00       	push   $0xcf
  jmp __alltraps
  1029e3:	e9 ac f7 ff ff       	jmp    102194 <__alltraps>

001029e8 <vector208>:
.globl vector208
vector208:
  pushl $0
  1029e8:	6a 00                	push   $0x0
  pushl $208
  1029ea:	68 d0 00 00 00       	push   $0xd0
  jmp __alltraps
  1029ef:	e9 a0 f7 ff ff       	jmp    102194 <__alltraps>

001029f4 <vector209>:
.globl vector209
vector209:
  pushl $0
  1029f4:	6a 00                	push   $0x0
  pushl $209
  1029f6:	68 d1 00 00 00       	push   $0xd1
  jmp __alltraps
  1029fb:	e9 94 f7 ff ff       	jmp    102194 <__alltraps>

00102a00 <vector210>:
.globl vector210
vector210:
  pushl $0
  102a00:	6a 00                	push   $0x0
  pushl $210
  102a02:	68 d2 00 00 00       	push   $0xd2
  jmp __alltraps
  102a07:	e9 88 f7 ff ff       	jmp    102194 <__alltraps>

00102a0c <vector211>:
.globl vector211
vector211:
  pushl $0
  102a0c:	6a 00                	push   $0x0
  pushl $211
  102a0e:	68 d3 00 00 00       	push   $0xd3
  jmp __alltraps
  102a13:	e9 7c f7 ff ff       	jmp    102194 <__alltraps>

00102a18 <vector212>:
.globl vector212
vector212:
  pushl $0
  102a18:	6a 00                	push   $0x0
  pushl $212
  102a1a:	68 d4 00 00 00       	push   $0xd4
  jmp __alltraps
  102a1f:	e9 70 f7 ff ff       	jmp    102194 <__alltraps>

00102a24 <vector213>:
.globl vector213
vector213:
  pushl $0
  102a24:	6a 00                	push   $0x0
  pushl $213
  102a26:	68 d5 00 00 00       	push   $0xd5
  jmp __alltraps
  102a2b:	e9 64 f7 ff ff       	jmp    102194 <__alltraps>

00102a30 <vector214>:
.globl vector214
vector214:
  pushl $0
  102a30:	6a 00                	push   $0x0
  pushl $214
  102a32:	68 d6 00 00 00       	push   $0xd6
  jmp __alltraps
  102a37:	e9 58 f7 ff ff       	jmp    102194 <__alltraps>

00102a3c <vector215>:
.globl vector215
vector215:
  pushl $0
  102a3c:	6a 00                	push   $0x0
  pushl $215
  102a3e:	68 d7 00 00 00       	push   $0xd7
  jmp __alltraps
  102a43:	e9 4c f7 ff ff       	jmp    102194 <__alltraps>

00102a48 <vector216>:
.globl vector216
vector216:
  pushl $0
  102a48:	6a 00                	push   $0x0
  pushl $216
  102a4a:	68 d8 00 00 00       	push   $0xd8
  jmp __alltraps
  102a4f:	e9 40 f7 ff ff       	jmp    102194 <__alltraps>

00102a54 <vector217>:
.globl vector217
vector217:
  pushl $0
  102a54:	6a 00                	push   $0x0
  pushl $217
  102a56:	68 d9 00 00 00       	push   $0xd9
  jmp __alltraps
  102a5b:	e9 34 f7 ff ff       	jmp    102194 <__alltraps>

00102a60 <vector218>:
.globl vector218
vector218:
  pushl $0
  102a60:	6a 00                	push   $0x0
  pushl $218
  102a62:	68 da 00 00 00       	push   $0xda
  jmp __alltraps
  102a67:	e9 28 f7 ff ff       	jmp    102194 <__alltraps>

00102a6c <vector219>:
.globl vector219
vector219:
  pushl $0
  102a6c:	6a 00                	push   $0x0
  pushl $219
  102a6e:	68 db 00 00 00       	push   $0xdb
  jmp __alltraps
  102a73:	e9 1c f7 ff ff       	jmp    102194 <__alltraps>

00102a78 <vector220>:
.globl vector220
vector220:
  pushl $0
  102a78:	6a 00                	push   $0x0
  pushl $220
  102a7a:	68 dc 00 00 00       	push   $0xdc
  jmp __alltraps
  102a7f:	e9 10 f7 ff ff       	jmp    102194 <__alltraps>

00102a84 <vector221>:
.globl vector221
vector221:
  pushl $0
  102a84:	6a 00                	push   $0x0
  pushl $221
  102a86:	68 dd 00 00 00       	push   $0xdd
  jmp __alltraps
  102a8b:	e9 04 f7 ff ff       	jmp    102194 <__alltraps>

00102a90 <vector222>:
.globl vector222
vector222:
  pushl $0
  102a90:	6a 00                	push   $0x0
  pushl $222
  102a92:	68 de 00 00 00       	push   $0xde
  jmp __alltraps
  102a97:	e9 f8 f6 ff ff       	jmp    102194 <__alltraps>

00102a9c <vector223>:
.globl vector223
vector223:
  pushl $0
  102a9c:	6a 00                	push   $0x0
  pushl $223
  102a9e:	68 df 00 00 00       	push   $0xdf
  jmp __alltraps
  102aa3:	e9 ec f6 ff ff       	jmp    102194 <__alltraps>

00102aa8 <vector224>:
.globl vector224
vector224:
  pushl $0
  102aa8:	6a 00                	push   $0x0
  pushl $224
  102aaa:	68 e0 00 00 00       	push   $0xe0
  jmp __alltraps
  102aaf:	e9 e0 f6 ff ff       	jmp    102194 <__alltraps>

00102ab4 <vector225>:
.globl vector225
vector225:
  pushl $0
  102ab4:	6a 00                	push   $0x0
  pushl $225
  102ab6:	68 e1 00 00 00       	push   $0xe1
  jmp __alltraps
  102abb:	e9 d4 f6 ff ff       	jmp    102194 <__alltraps>

00102ac0 <vector226>:
.globl vector226
vector226:
  pushl $0
  102ac0:	6a 00                	push   $0x0
  pushl $226
  102ac2:	68 e2 00 00 00       	push   $0xe2
  jmp __alltraps
  102ac7:	e9 c8 f6 ff ff       	jmp    102194 <__alltraps>

00102acc <vector227>:
.globl vector227
vector227:
  pushl $0
  102acc:	6a 00                	push   $0x0
  pushl $227
  102ace:	68 e3 00 00 00       	push   $0xe3
  jmp __alltraps
  102ad3:	e9 bc f6 ff ff       	jmp    102194 <__alltraps>

00102ad8 <vector228>:
.globl vector228
vector228:
  pushl $0
  102ad8:	6a 00                	push   $0x0
  pushl $228
  102ada:	68 e4 00 00 00       	push   $0xe4
  jmp __alltraps
  102adf:	e9 b0 f6 ff ff       	jmp    102194 <__alltraps>

00102ae4 <vector229>:
.globl vector229
vector229:
  pushl $0
  102ae4:	6a 00                	push   $0x0
  pushl $229
  102ae6:	68 e5 00 00 00       	push   $0xe5
  jmp __alltraps
  102aeb:	e9 a4 f6 ff ff       	jmp    102194 <__alltraps>

00102af0 <vector230>:
.globl vector230
vector230:
  pushl $0
  102af0:	6a 00                	push   $0x0
  pushl $230
  102af2:	68 e6 00 00 00       	push   $0xe6
  jmp __alltraps
  102af7:	e9 98 f6 ff ff       	jmp    102194 <__alltraps>

00102afc <vector231>:
.globl vector231
vector231:
  pushl $0
  102afc:	6a 00                	push   $0x0
  pushl $231
  102afe:	68 e7 00 00 00       	push   $0xe7
  jmp __alltraps
  102b03:	e9 8c f6 ff ff       	jmp    102194 <__alltraps>

00102b08 <vector232>:
.globl vector232
vector232:
  pushl $0
  102b08:	6a 00                	push   $0x0
  pushl $232
  102b0a:	68 e8 00 00 00       	push   $0xe8
  jmp __alltraps
  102b0f:	e9 80 f6 ff ff       	jmp    102194 <__alltraps>

00102b14 <vector233>:
.globl vector233
vector233:
  pushl $0
  102b14:	6a 00                	push   $0x0
  pushl $233
  102b16:	68 e9 00 00 00       	push   $0xe9
  jmp __alltraps
  102b1b:	e9 74 f6 ff ff       	jmp    102194 <__alltraps>

00102b20 <vector234>:
.globl vector234
vector234:
  pushl $0
  102b20:	6a 00                	push   $0x0
  pushl $234
  102b22:	68 ea 00 00 00       	push   $0xea
  jmp __alltraps
  102b27:	e9 68 f6 ff ff       	jmp    102194 <__alltraps>

00102b2c <vector235>:
.globl vector235
vector235:
  pushl $0
  102b2c:	6a 00                	push   $0x0
  pushl $235
  102b2e:	68 eb 00 00 00       	push   $0xeb
  jmp __alltraps
  102b33:	e9 5c f6 ff ff       	jmp    102194 <__alltraps>

00102b38 <vector236>:
.globl vector236
vector236:
  pushl $0
  102b38:	6a 00                	push   $0x0
  pushl $236
  102b3a:	68 ec 00 00 00       	push   $0xec
  jmp __alltraps
  102b3f:	e9 50 f6 ff ff       	jmp    102194 <__alltraps>

00102b44 <vector237>:
.globl vector237
vector237:
  pushl $0
  102b44:	6a 00                	push   $0x0
  pushl $237
  102b46:	68 ed 00 00 00       	push   $0xed
  jmp __alltraps
  102b4b:	e9 44 f6 ff ff       	jmp    102194 <__alltraps>

00102b50 <vector238>:
.globl vector238
vector238:
  pushl $0
  102b50:	6a 00                	push   $0x0
  pushl $238
  102b52:	68 ee 00 00 00       	push   $0xee
  jmp __alltraps
  102b57:	e9 38 f6 ff ff       	jmp    102194 <__alltraps>

00102b5c <vector239>:
.globl vector239
vector239:
  pushl $0
  102b5c:	6a 00                	push   $0x0
  pushl $239
  102b5e:	68 ef 00 00 00       	push   $0xef
  jmp __alltraps
  102b63:	e9 2c f6 ff ff       	jmp    102194 <__alltraps>

00102b68 <vector240>:
.globl vector240
vector240:
  pushl $0
  102b68:	6a 00                	push   $0x0
  pushl $240
  102b6a:	68 f0 00 00 00       	push   $0xf0
  jmp __alltraps
  102b6f:	e9 20 f6 ff ff       	jmp    102194 <__alltraps>

00102b74 <vector241>:
.globl vector241
vector241:
  pushl $0
  102b74:	6a 00                	push   $0x0
  pushl $241
  102b76:	68 f1 00 00 00       	push   $0xf1
  jmp __alltraps
  102b7b:	e9 14 f6 ff ff       	jmp    102194 <__alltraps>

00102b80 <vector242>:
.globl vector242
vector242:
  pushl $0
  102b80:	6a 00                	push   $0x0
  pushl $242
  102b82:	68 f2 00 00 00       	push   $0xf2
  jmp __alltraps
  102b87:	e9 08 f6 ff ff       	jmp    102194 <__alltraps>

00102b8c <vector243>:
.globl vector243
vector243:
  pushl $0
  102b8c:	6a 00                	push   $0x0
  pushl $243
  102b8e:	68 f3 00 00 00       	push   $0xf3
  jmp __alltraps
  102b93:	e9 fc f5 ff ff       	jmp    102194 <__alltraps>

00102b98 <vector244>:
.globl vector244
vector244:
  pushl $0
  102b98:	6a 00                	push   $0x0
  pushl $244
  102b9a:	68 f4 00 00 00       	push   $0xf4
  jmp __alltraps
  102b9f:	e9 f0 f5 ff ff       	jmp    102194 <__alltraps>

00102ba4 <vector245>:
.globl vector245
vector245:
  pushl $0
  102ba4:	6a 00                	push   $0x0
  pushl $245
  102ba6:	68 f5 00 00 00       	push   $0xf5
  jmp __alltraps
  102bab:	e9 e4 f5 ff ff       	jmp    102194 <__alltraps>

00102bb0 <vector246>:
.globl vector246
vector246:
  pushl $0
  102bb0:	6a 00                	push   $0x0
  pushl $246
  102bb2:	68 f6 00 00 00       	push   $0xf6
  jmp __alltraps
  102bb7:	e9 d8 f5 ff ff       	jmp    102194 <__alltraps>

00102bbc <vector247>:
.globl vector247
vector247:
  pushl $0
  102bbc:	6a 00                	push   $0x0
  pushl $247
  102bbe:	68 f7 00 00 00       	push   $0xf7
  jmp __alltraps
  102bc3:	e9 cc f5 ff ff       	jmp    102194 <__alltraps>

00102bc8 <vector248>:
.globl vector248
vector248:
  pushl $0
  102bc8:	6a 00                	push   $0x0
  pushl $248
  102bca:	68 f8 00 00 00       	push   $0xf8
  jmp __alltraps
  102bcf:	e9 c0 f5 ff ff       	jmp    102194 <__alltraps>

00102bd4 <vector249>:
.globl vector249
vector249:
  pushl $0
  102bd4:	6a 00                	push   $0x0
  pushl $249
  102bd6:	68 f9 00 00 00       	push   $0xf9
  jmp __alltraps
  102bdb:	e9 b4 f5 ff ff       	jmp    102194 <__alltraps>

00102be0 <vector250>:
.globl vector250
vector250:
  pushl $0
  102be0:	6a 00                	push   $0x0
  pushl $250
  102be2:	68 fa 00 00 00       	push   $0xfa
  jmp __alltraps
  102be7:	e9 a8 f5 ff ff       	jmp    102194 <__alltraps>

00102bec <vector251>:
.globl vector251
vector251:
  pushl $0
  102bec:	6a 00                	push   $0x0
  pushl $251
  102bee:	68 fb 00 00 00       	push   $0xfb
  jmp __alltraps
  102bf3:	e9 9c f5 ff ff       	jmp    102194 <__alltraps>

00102bf8 <vector252>:
.globl vector252
vector252:
  pushl $0
  102bf8:	6a 00                	push   $0x0
  pushl $252
  102bfa:	68 fc 00 00 00       	push   $0xfc
  jmp __alltraps
  102bff:	e9 90 f5 ff ff       	jmp    102194 <__alltraps>

00102c04 <vector253>:
.globl vector253
vector253:
  pushl $0
  102c04:	6a 00                	push   $0x0
  pushl $253
  102c06:	68 fd 00 00 00       	push   $0xfd
  jmp __alltraps
  102c0b:	e9 84 f5 ff ff       	jmp    102194 <__alltraps>

00102c10 <vector254>:
.globl vector254
vector254:
  pushl $0
  102c10:	6a 00                	push   $0x0
  pushl $254
  102c12:	68 fe 00 00 00       	push   $0xfe
  jmp __alltraps
  102c17:	e9 78 f5 ff ff       	jmp    102194 <__alltraps>

00102c1c <vector255>:
.globl vector255
vector255:
  pushl $0
  102c1c:	6a 00                	push   $0x0
  pushl $255
  102c1e:	68 ff 00 00 00       	push   $0xff
  jmp __alltraps
  102c23:	e9 6c f5 ff ff       	jmp    102194 <__alltraps>

00102c28 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
  102c28:	55                   	push   %ebp
  102c29:	89 e5                	mov    %esp,%ebp
    return page - pages;
  102c2b:	8b 55 08             	mov    0x8(%ebp),%edx
  102c2e:	a1 fc 57 12 00       	mov    0x1257fc,%eax
  102c33:	29 c2                	sub    %eax,%edx
  102c35:	89 d0                	mov    %edx,%eax
  102c37:	c1 f8 02             	sar    $0x2,%eax
  102c3a:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
  102c40:	5d                   	pop    %ebp
  102c41:	c3                   	ret    

00102c42 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
  102c42:	55                   	push   %ebp
  102c43:	89 e5                	mov    %esp,%ebp
  102c45:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
  102c48:	8b 45 08             	mov    0x8(%ebp),%eax
  102c4b:	89 04 24             	mov    %eax,(%esp)
  102c4e:	e8 d5 ff ff ff       	call   102c28 <page2ppn>
  102c53:	c1 e0 0c             	shl    $0xc,%eax
}
  102c56:	c9                   	leave  
  102c57:	c3                   	ret    

00102c58 <set_page_ref>:
page_ref(struct Page *page) {
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
  102c58:	55                   	push   %ebp
  102c59:	89 e5                	mov    %esp,%ebp
    page->ref = val;
  102c5b:	8b 45 08             	mov    0x8(%ebp),%eax
  102c5e:	8b 55 0c             	mov    0xc(%ebp),%edx
  102c61:	89 10                	mov    %edx,(%eax)
}
  102c63:	5d                   	pop    %ebp
  102c64:	c3                   	ret    

00102c65 <print_buddy_sys>:
free_area_t free_area[MAX_ORDER + 1];
#define free_list(i) (free_area[i].free_list)
#define nr_free(i) (free_area[i].nr_free)

static void
print_buddy_sys(char* s) {
  102c65:	55                   	push   %ebp
  102c66:	89 e5                	mov    %esp,%ebp
  102c68:	83 ec 38             	sub    $0x38,%esp
    cprintf("===============================\n%s\n", s);
  102c6b:	8b 45 08             	mov    0x8(%ebp),%eax
  102c6e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102c72:	c7 04 24 30 7a 10 00 	movl   $0x107a30,(%esp)
  102c79:	e8 d6 d6 ff ff       	call   100354 <cprintf>
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
  102c7e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102c85:	e9 a6 00 00 00       	jmp    102d30 <print_buddy_sys+0xcb>
        cprintf("order %d: ", i);
  102c8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102c8d:	89 44 24 04          	mov    %eax,0x4(%esp)
  102c91:	c7 04 24 54 7a 10 00 	movl   $0x107a54,(%esp)
  102c98:	e8 b7 d6 ff ff       	call   100354 <cprintf>
        list_entry_t *le = &free_list(i);
  102c9d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102ca0:	89 d0                	mov    %edx,%eax
  102ca2:	01 c0                	add    %eax,%eax
  102ca4:	01 d0                	add    %edx,%eax
  102ca6:	c1 e0 02             	shl    $0x2,%eax
  102ca9:	05 40 57 12 00       	add    $0x125740,%eax
  102cae:	89 45 f0             	mov    %eax,-0x10(%ebp)
        while ((le = list_next(le)) != &free_list(i)) {
  102cb1:	eb 48                	jmp    102cfb <print_buddy_sys+0x96>
            struct Page *page = le2page(le, page_link);
  102cb3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102cb6:	83 e8 0c             	sub    $0xc,%eax
  102cb9:	89 45 ec             	mov    %eax,-0x14(%ebp)
            intptr_t off = offset(page);
  102cbc:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102cbf:	a1 80 de 11 00       	mov    0x11de80,%eax
  102cc4:	29 c2                	sub    %eax,%edx
  102cc6:	89 d0                	mov    %edx,%eax
  102cc8:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
  102ccd:	f7 e2                	mul    %edx
  102ccf:	89 d0                	mov    %edx,%eax
  102cd1:	c1 e8 04             	shr    $0x4,%eax
  102cd4:	89 45 e8             	mov    %eax,-0x18(%ebp)
            cprintf("va: %x, offset: %d, property: %d->", page, off, page->property);
  102cd7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102cda:	8b 40 08             	mov    0x8(%eax),%eax
  102cdd:	89 44 24 0c          	mov    %eax,0xc(%esp)
  102ce1:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102ce4:	89 44 24 08          	mov    %eax,0x8(%esp)
  102ce8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102ceb:	89 44 24 04          	mov    %eax,0x4(%esp)
  102cef:	c7 04 24 60 7a 10 00 	movl   $0x107a60,(%esp)
  102cf6:	e8 59 d6 ff ff       	call   100354 <cprintf>
  102cfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102cfe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  102d01:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102d04:	8b 40 04             	mov    0x4(%eax),%eax
    cprintf("===============================\n%s\n", s);
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
        cprintf("order %d: ", i);
        list_entry_t *le = &free_list(i);
        while ((le = list_next(le)) != &free_list(i)) {
  102d07:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102d0a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102d0d:	89 d0                	mov    %edx,%eax
  102d0f:	01 c0                	add    %eax,%eax
  102d11:	01 d0                	add    %edx,%eax
  102d13:	c1 e0 02             	shl    $0x2,%eax
  102d16:	05 40 57 12 00       	add    $0x125740,%eax
  102d1b:	39 45 f0             	cmp    %eax,-0x10(%ebp)
  102d1e:	75 93                	jne    102cb3 <print_buddy_sys+0x4e>
            struct Page *page = le2page(le, page_link);
            intptr_t off = offset(page);
            cprintf("va: %x, offset: %d, property: %d->", page, off, page->property);
        }
        cprintf("\n");
  102d20:	c7 04 24 83 7a 10 00 	movl   $0x107a83,(%esp)
  102d27:	e8 28 d6 ff ff       	call   100354 <cprintf>

static void
print_buddy_sys(char* s) {
    cprintf("===============================\n%s\n", s);
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
  102d2c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102d30:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
  102d34:	0f 8e 50 ff ff ff    	jle    102c8a <print_buddy_sys+0x25>
            intptr_t off = offset(page);
            cprintf("va: %x, offset: %d, property: %d->", page, off, page->property);
        }
        cprintf("\n");
    }
}
  102d3a:	c9                   	leave  
  102d3b:	c3                   	ret    

00102d3c <buddy_init>:

static void
buddy_init(void) {
  102d3c:	55                   	push   %ebp
  102d3d:	89 e5                	mov    %esp,%ebp
  102d3f:	83 ec 10             	sub    $0x10,%esp
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
  102d42:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  102d49:	eb 44                	jmp    102d8f <buddy_init+0x53>
        list_init(&free_list(i));
  102d4b:	8b 55 fc             	mov    -0x4(%ebp),%edx
  102d4e:	89 d0                	mov    %edx,%eax
  102d50:	01 c0                	add    %eax,%eax
  102d52:	01 d0                	add    %edx,%eax
  102d54:	c1 e0 02             	shl    $0x2,%eax
  102d57:	05 40 57 12 00       	add    $0x125740,%eax
  102d5c:	89 45 f8             	mov    %eax,-0x8(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
  102d5f:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102d62:	8b 55 f8             	mov    -0x8(%ebp),%edx
  102d65:	89 50 04             	mov    %edx,0x4(%eax)
  102d68:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102d6b:	8b 50 04             	mov    0x4(%eax),%edx
  102d6e:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102d71:	89 10                	mov    %edx,(%eax)
        nr_free(i) = 0;
  102d73:	8b 55 fc             	mov    -0x4(%ebp),%edx
  102d76:	89 d0                	mov    %edx,%eax
  102d78:	01 c0                	add    %eax,%eax
  102d7a:	01 d0                	add    %edx,%eax
  102d7c:	c1 e0 02             	shl    $0x2,%eax
  102d7f:	05 40 57 12 00       	add    $0x125740,%eax
  102d84:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}

static void
buddy_init(void) {
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
  102d8b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  102d8f:	83 7d fc 0e          	cmpl   $0xe,-0x4(%ebp)
  102d93:	7e b6                	jle    102d4b <buddy_init+0xf>
        list_init(&free_list(i));
        nr_free(i) = 0;
    }
}
  102d95:	c9                   	leave  
  102d96:	c3                   	ret    

00102d97 <flip_bit_map>:

static inline void 
flip_bit_map(int32_t order, struct Page* page) {
  102d97:	55                   	push   %ebp
  102d98:	89 e5                	mov    %esp,%ebp
  102d9a:	56                   	push   %esi
  102d9b:	53                   	push   %ebx
  102d9c:	83 ec 10             	sub    $0x10,%esp
    int32_t bit_num = (offset(page) >> (order + 1));
  102d9f:	8b 55 0c             	mov    0xc(%ebp),%edx
  102da2:	a1 80 de 11 00       	mov    0x11de80,%eax
  102da7:	29 c2                	sub    %eax,%edx
  102da9:	89 d0                	mov    %edx,%eax
  102dab:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
  102db0:	f7 e2                	mul    %edx
  102db2:	c1 ea 04             	shr    $0x4,%edx
  102db5:	8b 45 08             	mov    0x8(%ebp),%eax
  102db8:	83 c0 01             	add    $0x1,%eax
  102dbb:	89 c1                	mov    %eax,%ecx
  102dbd:	d3 ea                	shr    %cl,%edx
  102dbf:	89 d0                	mov    %edx,%eax
  102dc1:	89 45 f4             	mov    %eax,-0xc(%ebp)
    bit_map[order][bit_num / 32] ^= (1 << (bit_num % 32));
  102dc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102dc7:	8d 50 1f             	lea    0x1f(%eax),%edx
  102dca:	85 c0                	test   %eax,%eax
  102dcc:	0f 48 c2             	cmovs  %edx,%eax
  102dcf:	c1 f8 05             	sar    $0x5,%eax
  102dd2:	8b 55 08             	mov    0x8(%ebp),%edx
  102dd5:	c1 e2 09             	shl    $0x9,%edx
  102dd8:	01 c2                	add    %eax,%edx
  102dda:	8b 1c 95 a0 de 11 00 	mov    0x11dea0(,%edx,4),%ebx
  102de1:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102de4:	89 d1                	mov    %edx,%ecx
  102de6:	c1 f9 1f             	sar    $0x1f,%ecx
  102de9:	c1 e9 1b             	shr    $0x1b,%ecx
  102dec:	01 ca                	add    %ecx,%edx
  102dee:	83 e2 1f             	and    $0x1f,%edx
  102df1:	29 ca                	sub    %ecx,%edx
  102df3:	be 01 00 00 00       	mov    $0x1,%esi
  102df8:	89 d1                	mov    %edx,%ecx
  102dfa:	d3 e6                	shl    %cl,%esi
  102dfc:	89 f2                	mov    %esi,%edx
  102dfe:	31 da                	xor    %ebx,%edx
  102e00:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102e03:	c1 e1 09             	shl    $0x9,%ecx
  102e06:	01 c8                	add    %ecx,%eax
  102e08:	89 14 85 a0 de 11 00 	mov    %edx,0x11dea0(,%eax,4)
}
  102e0f:	83 c4 10             	add    $0x10,%esp
  102e12:	5b                   	pop    %ebx
  102e13:	5e                   	pop    %esi
  102e14:	5d                   	pop    %ebp
  102e15:	c3                   	ret    

00102e16 <buddy_init_memmap>:

static void
buddy_init_memmap(struct Page *base, size_t n) {
  102e16:	55                   	push   %ebp
  102e17:	89 e5                	mov    %esp,%ebp
  102e19:	53                   	push   %ebx
  102e1a:	83 ec 54             	sub    $0x54,%esp
    // 这里发现只有一个可用的页框
    cprintf("va: 0x%x, pa: 0x%x, num: %d\n", base, page2pa(base), n);
  102e1d:	8b 45 08             	mov    0x8(%ebp),%eax
  102e20:	89 04 24             	mov    %eax,(%esp)
  102e23:	e8 1a fe ff ff       	call   102c42 <page2pa>
  102e28:	8b 55 0c             	mov    0xc(%ebp),%edx
  102e2b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102e2f:	89 44 24 08          	mov    %eax,0x8(%esp)
  102e33:	8b 45 08             	mov    0x8(%ebp),%eax
  102e36:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e3a:	c7 04 24 85 7a 10 00 	movl   $0x107a85,(%esp)
  102e41:	e8 0e d5 ff ff       	call   100354 <cprintf>
    assert(n > 0);
  102e46:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  102e4a:	75 24                	jne    102e70 <buddy_init_memmap+0x5a>
  102e4c:	c7 44 24 0c a2 7a 10 	movl   $0x107aa2,0xc(%esp)
  102e53:	00 
  102e54:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  102e5b:	00 
  102e5c:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
  102e63:	00 
  102e64:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  102e6b:	e8 6e de ff ff       	call   100cde <__panic>
    //设置base_page，用于归零
    base_page = base;
  102e70:	8b 45 08             	mov    0x8(%ebp),%eax
  102e73:	a3 80 de 11 00       	mov    %eax,0x11de80
    struct Page *p = base;
  102e78:	8b 45 08             	mov    0x8(%ebp),%eax
  102e7b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
  102e7e:	eb 7d                	jmp    102efd <buddy_init_memmap+0xe7>
        assert(PageReserved(p));
  102e80:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e83:	83 c0 04             	add    $0x4,%eax
  102e86:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  102e8d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  102e90:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102e93:	8b 55 e8             	mov    -0x18(%ebp),%edx
  102e96:	0f a3 10             	bt     %edx,(%eax)
  102e99:	19 c0                	sbb    %eax,%eax
  102e9b:	89 45 e0             	mov    %eax,-0x20(%ebp)
    return oldbit != 0;
  102e9e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  102ea2:	0f 95 c0             	setne  %al
  102ea5:	0f b6 c0             	movzbl %al,%eax
  102ea8:	85 c0                	test   %eax,%eax
  102eaa:	75 24                	jne    102ed0 <buddy_init_memmap+0xba>
  102eac:	c7 44 24 0c d1 7a 10 	movl   $0x107ad1,0xc(%esp)
  102eb3:	00 
  102eb4:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  102ebb:	00 
  102ebc:	c7 44 24 04 39 00 00 	movl   $0x39,0x4(%esp)
  102ec3:	00 
  102ec4:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  102ecb:	e8 0e de ff ff       	call   100cde <__panic>
        p->flags = p->property = 0;
  102ed0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ed3:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  102eda:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102edd:	8b 50 08             	mov    0x8(%eax),%edx
  102ee0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ee3:	89 50 04             	mov    %edx,0x4(%eax)
        set_page_ref(p, 0);
  102ee6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102eed:	00 
  102eee:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ef1:	89 04 24             	mov    %eax,(%esp)
  102ef4:	e8 5f fd ff ff       	call   102c58 <set_page_ref>
    cprintf("va: 0x%x, pa: 0x%x, num: %d\n", base, page2pa(base), n);
    assert(n > 0);
    //设置base_page，用于归零
    base_page = base;
    struct Page *p = base;
    for (; p != base + n; p ++) {
  102ef9:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
  102efd:	8b 55 0c             	mov    0xc(%ebp),%edx
  102f00:	89 d0                	mov    %edx,%eax
  102f02:	c1 e0 02             	shl    $0x2,%eax
  102f05:	01 d0                	add    %edx,%eax
  102f07:	c1 e0 02             	shl    $0x2,%eax
  102f0a:	89 c2                	mov    %eax,%edx
  102f0c:	8b 45 08             	mov    0x8(%ebp),%eax
  102f0f:	01 d0                	add    %edx,%eax
  102f11:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  102f14:	0f 85 66 ff ff ff    	jne    102e80 <buddy_init_memmap+0x6a>
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    struct Page *page = base;
  102f1a:	8b 45 08             	mov    0x8(%ebp),%eax
  102f1d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    int32_t now_order = MAX_ORDER;
  102f20:	c7 45 ec 0e 00 00 00 	movl   $0xe,-0x14(%ebp)
    // 由于初始时只映射了4M，这里如果全用了，按照算法实现会返回没有被映射到的页
    // while (now_order <= MAX_ORDER) {
        if (n > (1 << now_order)) {
  102f27:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102f2a:	ba 01 00 00 00       	mov    $0x1,%edx
  102f2f:	89 c1                	mov    %eax,%ecx
  102f31:	d3 e2                	shl    %cl,%edx
  102f33:	89 d0                	mov    %edx,%eax
  102f35:	3b 45 0c             	cmp    0xc(%ebp),%eax
  102f38:	0f 83 fe 00 00 00    	jae    10303c <buddy_init_memmap+0x226>
            page->property = (1 << now_order);
  102f3e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102f41:	ba 01 00 00 00       	mov    $0x1,%edx
  102f46:	89 c1                	mov    %eax,%ecx
  102f48:	d3 e2                	shl    %cl,%edx
  102f4a:	89 d0                	mov    %edx,%eax
  102f4c:	89 c2                	mov    %eax,%edx
  102f4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102f51:	89 50 08             	mov    %edx,0x8(%eax)
            SetPageProperty(page);
  102f54:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102f57:	83 c0 04             	add    $0x4,%eax
  102f5a:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
  102f61:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  102f64:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102f67:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102f6a:	0f ab 10             	bts    %edx,(%eax)
            nr_free(now_order)  += (1 << now_order);
  102f6d:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102f70:	89 d0                	mov    %edx,%eax
  102f72:	01 c0                	add    %eax,%eax
  102f74:	01 d0                	add    %edx,%eax
  102f76:	c1 e0 02             	shl    $0x2,%eax
  102f79:	05 40 57 12 00       	add    $0x125740,%eax
  102f7e:	8b 50 08             	mov    0x8(%eax),%edx
  102f81:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102f84:	bb 01 00 00 00       	mov    $0x1,%ebx
  102f89:	89 c1                	mov    %eax,%ecx
  102f8b:	d3 e3                	shl    %cl,%ebx
  102f8d:	89 d8                	mov    %ebx,%eax
  102f8f:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
  102f92:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102f95:	89 d0                	mov    %edx,%eax
  102f97:	01 c0                	add    %eax,%eax
  102f99:	01 d0                	add    %edx,%eax
  102f9b:	c1 e0 02             	shl    $0x2,%eax
  102f9e:	05 40 57 12 00       	add    $0x125740,%eax
  102fa3:	89 48 08             	mov    %ecx,0x8(%eax)
            list_add(&free_list(now_order), &(page->page_link));
  102fa6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102fa9:	8d 48 0c             	lea    0xc(%eax),%ecx
  102fac:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102faf:	89 d0                	mov    %edx,%eax
  102fb1:	01 c0                	add    %eax,%eax
  102fb3:	01 d0                	add    %edx,%eax
  102fb5:	c1 e0 02             	shl    $0x2,%eax
  102fb8:	05 40 57 12 00       	add    $0x125740,%eax
  102fbd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  102fc0:	89 4d d0             	mov    %ecx,-0x30(%ebp)
  102fc3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102fc6:	89 45 cc             	mov    %eax,-0x34(%ebp)
  102fc9:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102fcc:	89 45 c8             	mov    %eax,-0x38(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
  102fcf:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102fd2:	8b 40 04             	mov    0x4(%eax),%eax
  102fd5:	8b 55 c8             	mov    -0x38(%ebp),%edx
  102fd8:	89 55 c4             	mov    %edx,-0x3c(%ebp)
  102fdb:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102fde:	89 55 c0             	mov    %edx,-0x40(%ebp)
  102fe1:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  102fe4:	8b 45 bc             	mov    -0x44(%ebp),%eax
  102fe7:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  102fea:	89 10                	mov    %edx,(%eax)
  102fec:	8b 45 bc             	mov    -0x44(%ebp),%eax
  102fef:	8b 10                	mov    (%eax),%edx
  102ff1:	8b 45 c0             	mov    -0x40(%ebp),%eax
  102ff4:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  102ff7:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  102ffa:	8b 55 bc             	mov    -0x44(%ebp),%edx
  102ffd:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  103000:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  103003:	8b 55 c0             	mov    -0x40(%ebp),%edx
  103006:	89 10                	mov    %edx,(%eax)
            // 这里位图要更新一下
            flip_bit_map(now_order, page);
  103008:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10300b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10300f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103012:	89 04 24             	mov    %eax,(%esp)
  103015:	e8 7d fd ff ff       	call   102d97 <flip_bit_map>
            page += (1 << now_order);
  10301a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10301d:	ba 14 00 00 00       	mov    $0x14,%edx
  103022:	89 c1                	mov    %eax,%ecx
  103024:	d3 e2                	shl    %cl,%edx
  103026:	89 d0                	mov    %edx,%eax
  103028:	01 45 f0             	add    %eax,-0x10(%ebp)
            n -= (1 << now_order);
  10302b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10302e:	ba 01 00 00 00       	mov    $0x1,%edx
  103033:	89 c1                	mov    %eax,%ecx
  103035:	d3 e2                	shl    %cl,%edx
  103037:	89 d0                	mov    %edx,%eax
  103039:	29 45 0c             	sub    %eax,0xc(%ebp)
        }
        now_order += 1;
  10303c:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
    // }
    cprintf("base_page is: %x\n", base_page);
  103040:	a1 80 de 11 00       	mov    0x11de80,%eax
  103045:	89 44 24 04          	mov    %eax,0x4(%esp)
  103049:	c7 04 24 e1 7a 10 00 	movl   $0x107ae1,(%esp)
  103050:	e8 ff d2 ff ff       	call   100354 <cprintf>
    print_buddy_sys("init_status");
  103055:	c7 04 24 f3 7a 10 00 	movl   $0x107af3,(%esp)
  10305c:	e8 04 fc ff ff       	call   102c65 <print_buddy_sys>
}
  103061:	83 c4 54             	add    $0x54,%esp
  103064:	5b                   	pop    %ebx
  103065:	5d                   	pop    %ebp
  103066:	c3                   	ret    

00103067 <buddy_alloc_pages>:

static struct Page *
buddy_alloc_pages(size_t n) {
  103067:	55                   	push   %ebp
  103068:	89 e5                	mov    %esp,%ebp
  10306a:	83 ec 78             	sub    $0x78,%esp
    assert(n > 0);
  10306d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  103071:	75 24                	jne    103097 <buddy_alloc_pages+0x30>
  103073:	c7 44 24 0c a2 7a 10 	movl   $0x107aa2,0xc(%esp)
  10307a:	00 
  10307b:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  103082:	00 
  103083:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  10308a:	00 
  10308b:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  103092:	e8 47 dc ff ff       	call   100cde <__panic>
    int32_t upper_order = 0;
  103097:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    //找到刚好大于n，且有空闲页框的阶
    while ((1 << upper_order) < n || nr_free(upper_order) < n) {
  10309e:	eb 04                	jmp    1030a4 <buddy_alloc_pages+0x3d>
        upper_order += 1;
  1030a0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    int32_t upper_order = 0;
    //找到刚好大于n，且有空闲页框的阶
    while ((1 << upper_order) < n || nr_free(upper_order) < n) {
  1030a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030a7:	ba 01 00 00 00       	mov    $0x1,%edx
  1030ac:	89 c1                	mov    %eax,%ecx
  1030ae:	d3 e2                	shl    %cl,%edx
  1030b0:	89 d0                	mov    %edx,%eax
  1030b2:	3b 45 08             	cmp    0x8(%ebp),%eax
  1030b5:	72 e9                	jb     1030a0 <buddy_alloc_pages+0x39>
  1030b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1030ba:	89 d0                	mov    %edx,%eax
  1030bc:	01 c0                	add    %eax,%eax
  1030be:	01 d0                	add    %edx,%eax
  1030c0:	c1 e0 02             	shl    $0x2,%eax
  1030c3:	05 40 57 12 00       	add    $0x125740,%eax
  1030c8:	8b 40 08             	mov    0x8(%eax),%eax
  1030cb:	3b 45 08             	cmp    0x8(%ebp),%eax
  1030ce:	72 d0                	jb     1030a0 <buddy_alloc_pages+0x39>
        upper_order += 1;
    }
    if (upper_order > MAX_ORDER) {
  1030d0:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
  1030d4:	7e 0a                	jle    1030e0 <buddy_alloc_pages+0x79>
        return NULL;
  1030d6:	b8 00 00 00 00       	mov    $0x0,%eax
  1030db:	e9 fe 01 00 00       	jmp    1032de <buddy_alloc_pages+0x277>
    }
    struct Page *page = NULL;
  1030e0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    list_entry_t *le = &free_list(upper_order);
  1030e7:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1030ea:	89 d0                	mov    %edx,%eax
  1030ec:	01 c0                	add    %eax,%eax
  1030ee:	01 d0                	add    %edx,%eax
  1030f0:	c1 e0 02             	shl    $0x2,%eax
  1030f3:	05 40 57 12 00       	add    $0x125740,%eax
  1030f8:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1030fb:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1030fe:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  103101:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103104:	8b 40 04             	mov    0x4(%eax),%eax
    le = list_next(le);
  103107:	89 45 e8             	mov    %eax,-0x18(%ebp)
    page = le2page(le, page_link);
  10310a:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10310d:	83 e8 0c             	sub    $0xc,%eax
  103110:	89 45 f0             	mov    %eax,-0x10(%ebp)
    //把当前这个页摘下来
    // 设置位图
    flip_bit_map(upper_order, page);
  103113:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103116:	89 44 24 04          	mov    %eax,0x4(%esp)
  10311a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10311d:	89 04 24             	mov    %eax,(%esp)
  103120:	e8 72 fc ff ff       	call   102d97 <flip_bit_map>
    // 把这个页框从链表删除
    list_del(&(page->page_link));
  103125:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103128:	83 c0 0c             	add    $0xc,%eax
  10312b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
  10312e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  103131:	8b 40 04             	mov    0x4(%eax),%eax
  103134:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103137:	8b 12                	mov    (%edx),%edx
  103139:	89 55 d0             	mov    %edx,-0x30(%ebp)
  10313c:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
  10313f:	8b 45 d0             	mov    -0x30(%ebp),%eax
  103142:	8b 55 cc             	mov    -0x34(%ebp),%edx
  103145:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
  103148:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10314b:	8b 55 d0             	mov    -0x30(%ebp),%edx
  10314e:	89 10                	mov    %edx,(%eax)
    nr_free(upper_order) -= page->property;
  103150:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103153:	89 d0                	mov    %edx,%eax
  103155:	01 c0                	add    %eax,%eax
  103157:	01 d0                	add    %edx,%eax
  103159:	c1 e0 02             	shl    $0x2,%eax
  10315c:	05 40 57 12 00       	add    $0x125740,%eax
  103161:	8b 50 08             	mov    0x8(%eax),%edx
  103164:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103167:	8b 40 08             	mov    0x8(%eax),%eax
  10316a:	89 d1                	mov    %edx,%ecx
  10316c:	29 c1                	sub    %eax,%ecx
  10316e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103171:	89 d0                	mov    %edx,%eax
  103173:	01 c0                	add    %eax,%eax
  103175:	01 d0                	add    %edx,%eax
  103177:	c1 e0 02             	shl    $0x2,%eax
  10317a:	05 40 57 12 00       	add    $0x125740,%eax
  10317f:	89 48 08             	mov    %ecx,0x8(%eax)
    if (page->property >= (n << 1)) {
  103182:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103185:	8b 40 08             	mov    0x8(%eax),%eax
  103188:	8b 55 08             	mov    0x8(%ebp),%edx
  10318b:	01 d2                	add    %edx,%edx
  10318d:	39 d0                	cmp    %edx,%eax
  10318f:	0f 82 2d 01 00 00    	jb     1032c2 <buddy_alloc_pages+0x25b>
        // 如果可以分裂，得一直分裂，分裂结束得条件是当前的页框大小/2<n
        // now_order记录当前分裂的页框的阶
        int32_t now_order = upper_order;
  103195:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103198:	89 45 ec             	mov    %eax,-0x14(%ebp)
        while ((page->property >> 1) >= n) {
  10319b:	e9 11 01 00 00       	jmp    1032b1 <buddy_alloc_pages+0x24a>
            int32_t lower_order = now_order - 1;
  1031a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1031a3:	83 e8 01             	sub    $0x1,%eax
  1031a6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            // 把当前页分裂成左右两个
            struct Page *left_sub_page, *right_sub_page;
            left_sub_page = page;
  1031a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1031ac:	89 45 e0             	mov    %eax,-0x20(%ebp)
            right_sub_page = page + page->property / 2;
  1031af:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1031b2:	8b 40 08             	mov    0x8(%eax),%eax
  1031b5:	d1 e8                	shr    %eax
  1031b7:	89 c2                	mov    %eax,%edx
  1031b9:	89 d0                	mov    %edx,%eax
  1031bb:	c1 e0 02             	shl    $0x2,%eax
  1031be:	01 d0                	add    %edx,%eax
  1031c0:	c1 e0 02             	shl    $0x2,%eax
  1031c3:	89 c2                	mov    %eax,%edx
  1031c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1031c8:	01 d0                	add    %edx,%eax
  1031ca:	89 45 dc             	mov    %eax,-0x24(%ebp)
            // 把右边页插入到下一阶的链表中，并设置位图
            SetPageProperty(right_sub_page);
  1031cd:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1031d0:	83 c0 04             	add    $0x4,%eax
  1031d3:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
  1031da:	89 45 c4             	mov    %eax,-0x3c(%ebp)
  1031dd:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  1031e0:	8b 55 c8             	mov    -0x38(%ebp),%edx
  1031e3:	0f ab 10             	bts    %edx,(%eax)
            right_sub_page->property = page->property / 2;
  1031e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1031e9:	8b 40 08             	mov    0x8(%eax),%eax
  1031ec:	d1 e8                	shr    %eax
  1031ee:	89 c2                	mov    %eax,%edx
  1031f0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1031f3:	89 50 08             	mov    %edx,0x8(%eax)
            list_add(&free_list(lower_order), &right_sub_page->page_link);
  1031f6:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1031f9:	8d 48 0c             	lea    0xc(%eax),%ecx
  1031fc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1031ff:	89 d0                	mov    %edx,%eax
  103201:	01 c0                	add    %eax,%eax
  103203:	01 d0                	add    %edx,%eax
  103205:	c1 e0 02             	shl    $0x2,%eax
  103208:	05 40 57 12 00       	add    $0x125740,%eax
  10320d:	89 45 c0             	mov    %eax,-0x40(%ebp)
  103210:	89 4d bc             	mov    %ecx,-0x44(%ebp)
  103213:	8b 45 c0             	mov    -0x40(%ebp),%eax
  103216:	89 45 b8             	mov    %eax,-0x48(%ebp)
  103219:	8b 45 bc             	mov    -0x44(%ebp),%eax
  10321c:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
  10321f:	8b 45 b8             	mov    -0x48(%ebp),%eax
  103222:	8b 40 04             	mov    0x4(%eax),%eax
  103225:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  103228:	89 55 b0             	mov    %edx,-0x50(%ebp)
  10322b:	8b 55 b8             	mov    -0x48(%ebp),%edx
  10322e:	89 55 ac             	mov    %edx,-0x54(%ebp)
  103231:	89 45 a8             	mov    %eax,-0x58(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  103234:	8b 45 a8             	mov    -0x58(%ebp),%eax
  103237:	8b 55 b0             	mov    -0x50(%ebp),%edx
  10323a:	89 10                	mov    %edx,(%eax)
  10323c:	8b 45 a8             	mov    -0x58(%ebp),%eax
  10323f:	8b 10                	mov    (%eax),%edx
  103241:	8b 45 ac             	mov    -0x54(%ebp),%eax
  103244:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  103247:	8b 45 b0             	mov    -0x50(%ebp),%eax
  10324a:	8b 55 a8             	mov    -0x58(%ebp),%edx
  10324d:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  103250:	8b 45 b0             	mov    -0x50(%ebp),%eax
  103253:	8b 55 ac             	mov    -0x54(%ebp),%edx
  103256:	89 10                	mov    %edx,(%eax)
            nr_free(lower_order) += right_sub_page->property;
  103258:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10325b:	89 d0                	mov    %edx,%eax
  10325d:	01 c0                	add    %eax,%eax
  10325f:	01 d0                	add    %edx,%eax
  103261:	c1 e0 02             	shl    $0x2,%eax
  103264:	05 40 57 12 00       	add    $0x125740,%eax
  103269:	8b 50 08             	mov    0x8(%eax),%edx
  10326c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10326f:	8b 40 08             	mov    0x8(%eax),%eax
  103272:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
  103275:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103278:	89 d0                	mov    %edx,%eax
  10327a:	01 c0                	add    %eax,%eax
  10327c:	01 d0                	add    %edx,%eax
  10327e:	c1 e0 02             	shl    $0x2,%eax
  103281:	05 40 57 12 00       	add    $0x125740,%eax
  103286:	89 48 08             	mov    %ecx,0x8(%eax)
            flip_bit_map(lower_order, right_sub_page);
  103289:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10328c:	89 44 24 04          	mov    %eax,0x4(%esp)
  103290:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103293:	89 04 24             	mov    %eax,(%esp)
  103296:	e8 fc fa ff ff       	call   102d97 <flip_bit_map>
            // 左边页继续分裂
            now_order -= 1;
  10329b:	83 6d ec 01          	subl   $0x1,-0x14(%ebp)
            left_sub_page->property = right_sub_page->property;
  10329f:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1032a2:	8b 50 08             	mov    0x8(%eax),%edx
  1032a5:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1032a8:	89 50 08             	mov    %edx,0x8(%eax)
            page = left_sub_page;
  1032ab:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1032ae:	89 45 f0             	mov    %eax,-0x10(%ebp)
    nr_free(upper_order) -= page->property;
    if (page->property >= (n << 1)) {
        // 如果可以分裂，得一直分裂，分裂结束得条件是当前的页框大小/2<n
        // now_order记录当前分裂的页框的阶
        int32_t now_order = upper_order;
        while ((page->property >> 1) >= n) {
  1032b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1032b4:	8b 40 08             	mov    0x8(%eax),%eax
  1032b7:	d1 e8                	shr    %eax
  1032b9:	3b 45 08             	cmp    0x8(%ebp),%eax
  1032bc:	0f 83 de fe ff ff    	jae    1031a0 <buddy_alloc_pages+0x139>
            now_order -= 1;
            left_sub_page->property = right_sub_page->property;
            page = left_sub_page;
        }
    }
    ClearPageProperty(page);
  1032c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1032c5:	83 c0 04             	add    $0x4,%eax
  1032c8:	c7 45 a4 01 00 00 00 	movl   $0x1,-0x5c(%ebp)
  1032cf:	89 45 a0             	mov    %eax,-0x60(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  1032d2:	8b 45 a0             	mov    -0x60(%ebp),%eax
  1032d5:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  1032d8:	0f b3 10             	btr    %edx,(%eax)
    return page;
  1032db:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1032de:	c9                   	leave  
  1032df:	c3                   	ret    

001032e0 <get_buddy>:

static inline struct Page *
get_buddy(struct Page* page, int32_t order) {
  1032e0:	55                   	push   %ebp
  1032e1:	89 e5                	mov    %esp,%ebp
  1032e3:	83 ec 10             	sub    $0x10,%esp
    // 得到当前页的伙伴
    int32_t off = offset(page);
  1032e6:	8b 55 08             	mov    0x8(%ebp),%edx
  1032e9:	a1 80 de 11 00       	mov    0x11de80,%eax
  1032ee:	29 c2                	sub    %eax,%edx
  1032f0:	89 d0                	mov    %edx,%eax
  1032f2:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
  1032f7:	f7 e2                	mul    %edx
  1032f9:	89 d0                	mov    %edx,%eax
  1032fb:	c1 e8 04             	shr    $0x4,%eax
  1032fe:	89 45 fc             	mov    %eax,-0x4(%ebp)
    int32_t buddy_off = (off ^ (1 << order));
  103301:	8b 45 0c             	mov    0xc(%ebp),%eax
  103304:	ba 01 00 00 00       	mov    $0x1,%edx
  103309:	89 c1                	mov    %eax,%ecx
  10330b:	d3 e2                	shl    %cl,%edx
  10330d:	89 d0                	mov    %edx,%eax
  10330f:	33 45 fc             	xor    -0x4(%ebp),%eax
  103312:	89 45 f8             	mov    %eax,-0x8(%ebp)
    return base_page + buddy_off * sizeof(struct Page);
  103315:	8b 55 f8             	mov    -0x8(%ebp),%edx
  103318:	89 d0                	mov    %edx,%eax
  10331a:	c1 e0 02             	shl    $0x2,%eax
  10331d:	01 d0                	add    %edx,%eax
  10331f:	c1 e0 02             	shl    $0x2,%eax
  103322:	89 c2                	mov    %eax,%edx
  103324:	a1 80 de 11 00       	mov    0x11de80,%eax
  103329:	01 d0                	add    %edx,%eax
}
  10332b:	c9                   	leave  
  10332c:	c3                   	ret    

0010332d <buddy_free_pages>:

static void
buddy_free_pages(struct Page *base, size_t n) {
  10332d:	55                   	push   %ebp
  10332e:	89 e5                	mov    %esp,%ebp
  103330:	53                   	push   %ebx
  103331:	83 ec 74             	sub    $0x74,%esp
    // 先检查n的合法性
    assert(n > 0);
  103334:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  103338:	75 24                	jne    10335e <buddy_free_pages+0x31>
  10333a:	c7 44 24 0c a2 7a 10 	movl   $0x107aa2,0xc(%esp)
  103341:	00 
  103342:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  103349:	00 
  10334a:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
  103351:	00 
  103352:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  103359:	e8 80 d9 ff ff       	call   100cde <__panic>
    int now_order = 0;
  10335e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while ((1 << now_order) < n) {
  103365:	eb 04                	jmp    10336b <buddy_free_pages+0x3e>
        now_order += 1;
  103367:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
static void
buddy_free_pages(struct Page *base, size_t n) {
    // 先检查n的合法性
    assert(n > 0);
    int now_order = 0;
    while ((1 << now_order) < n) {
  10336b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10336e:	ba 01 00 00 00       	mov    $0x1,%edx
  103373:	89 c1                	mov    %eax,%ecx
  103375:	d3 e2                	shl    %cl,%edx
  103377:	89 d0                	mov    %edx,%eax
  103379:	3b 45 0c             	cmp    0xc(%ebp),%eax
  10337c:	72 e9                	jb     103367 <buddy_free_pages+0x3a>
        now_order += 1;
    }
    n = (1 << now_order);
  10337e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103381:	ba 01 00 00 00       	mov    $0x1,%edx
  103386:	89 c1                	mov    %eax,%ecx
  103388:	d3 e2                	shl    %cl,%edx
  10338a:	89 d0                	mov    %edx,%eax
  10338c:	89 45 0c             	mov    %eax,0xc(%ebp)
    assert(now_order <= MAX_ORDER && now_order >= 0);
  10338f:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
  103393:	7f 06                	jg     10339b <buddy_free_pages+0x6e>
  103395:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103399:	79 24                	jns    1033bf <buddy_free_pages+0x92>
  10339b:	c7 44 24 0c 00 7b 10 	movl   $0x107b00,0xc(%esp)
  1033a2:	00 
  1033a3:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  1033aa:	00 
  1033ab:	c7 44 24 04 91 00 00 	movl   $0x91,0x4(%esp)
  1033b2:	00 
  1033b3:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  1033ba:	e8 1f d9 ff ff       	call   100cde <__panic>
    // 再检查base的合法性
    assert(offset(base) % n == 0);
  1033bf:	8b 55 08             	mov    0x8(%ebp),%edx
  1033c2:	a1 80 de 11 00       	mov    0x11de80,%eax
  1033c7:	29 c2                	sub    %eax,%edx
  1033c9:	89 d0                	mov    %edx,%eax
  1033cb:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
  1033d0:	f7 e2                	mul    %edx
  1033d2:	89 d0                	mov    %edx,%eax
  1033d4:	c1 e8 04             	shr    $0x4,%eax
  1033d7:	ba 00 00 00 00       	mov    $0x0,%edx
  1033dc:	f7 75 0c             	divl   0xc(%ebp)
  1033df:	89 d0                	mov    %edx,%eax
  1033e1:	85 c0                	test   %eax,%eax
  1033e3:	74 24                	je     103409 <buddy_free_pages+0xdc>
  1033e5:	c7 44 24 0c 29 7b 10 	movl   $0x107b29,0xc(%esp)
  1033ec:	00 
  1033ed:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  1033f4:	00 
  1033f5:	c7 44 24 04 93 00 00 	movl   $0x93,0x4(%esp)
  1033fc:	00 
  1033fd:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  103404:	e8 d5 d8 ff ff       	call   100cde <__panic>
    struct Page *p = base;
  103409:	8b 45 08             	mov    0x8(%ebp),%eax
  10340c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    for (; p != base + n; p ++) {
  10340f:	e9 9d 00 00 00       	jmp    1034b1 <buddy_free_pages+0x184>
        assert(!PageReserved(p) && !PageProperty(p));
  103414:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103417:	83 c0 04             	add    $0x4,%eax
  10341a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  103421:	89 45 e0             	mov    %eax,-0x20(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  103424:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103427:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10342a:	0f a3 10             	bt     %edx,(%eax)
  10342d:	19 c0                	sbb    %eax,%eax
  10342f:	89 45 dc             	mov    %eax,-0x24(%ebp)
    return oldbit != 0;
  103432:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  103436:	0f 95 c0             	setne  %al
  103439:	0f b6 c0             	movzbl %al,%eax
  10343c:	85 c0                	test   %eax,%eax
  10343e:	75 2c                	jne    10346c <buddy_free_pages+0x13f>
  103440:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103443:	83 c0 04             	add    $0x4,%eax
  103446:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
  10344d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  103450:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  103453:	8b 55 d8             	mov    -0x28(%ebp),%edx
  103456:	0f a3 10             	bt     %edx,(%eax)
  103459:	19 c0                	sbb    %eax,%eax
  10345b:	89 45 d0             	mov    %eax,-0x30(%ebp)
    return oldbit != 0;
  10345e:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  103462:	0f 95 c0             	setne  %al
  103465:	0f b6 c0             	movzbl %al,%eax
  103468:	85 c0                	test   %eax,%eax
  10346a:	74 24                	je     103490 <buddy_free_pages+0x163>
  10346c:	c7 44 24 0c 40 7b 10 	movl   $0x107b40,0xc(%esp)
  103473:	00 
  103474:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  10347b:	00 
  10347c:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
  103483:	00 
  103484:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  10348b:	e8 4e d8 ff ff       	call   100cde <__panic>
        p->flags = 0;
  103490:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103493:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
        set_page_ref(p, 0);
  10349a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1034a1:	00 
  1034a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1034a5:	89 04 24             	mov    %eax,(%esp)
  1034a8:	e8 ab f7 ff ff       	call   102c58 <set_page_ref>
    n = (1 << now_order);
    assert(now_order <= MAX_ORDER && now_order >= 0);
    // 再检查base的合法性
    assert(offset(base) % n == 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
  1034ad:	83 45 f0 14          	addl   $0x14,-0x10(%ebp)
  1034b1:	8b 55 0c             	mov    0xc(%ebp),%edx
  1034b4:	89 d0                	mov    %edx,%eax
  1034b6:	c1 e0 02             	shl    $0x2,%eax
  1034b9:	01 d0                	add    %edx,%eax
  1034bb:	c1 e0 02             	shl    $0x2,%eax
  1034be:	89 c2                	mov    %eax,%edx
  1034c0:	8b 45 08             	mov    0x8(%ebp),%eax
  1034c3:	01 d0                	add    %edx,%eax
  1034c5:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1034c8:	0f 85 46 ff ff ff    	jne    103414 <buddy_free_pages+0xe7>
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
  1034ce:	8b 45 08             	mov    0x8(%ebp),%eax
  1034d1:	8b 55 0c             	mov    0xc(%ebp),%edx
  1034d4:	89 50 08             	mov    %edx,0x8(%eax)
    // 开始尝试合并页框
    flip_bit_map(now_order, base);
  1034d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1034da:	89 44 24 04          	mov    %eax,0x4(%esp)
  1034de:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1034e1:	89 04 24             	mov    %eax,(%esp)
  1034e4:	e8 ae f8 ff ff       	call   102d97 <flip_bit_map>
    intptr_t bit_num = (offset(base) >> (now_order + 1));
  1034e9:	8b 55 08             	mov    0x8(%ebp),%edx
  1034ec:	a1 80 de 11 00       	mov    0x11de80,%eax
  1034f1:	29 c2                	sub    %eax,%edx
  1034f3:	89 d0                	mov    %edx,%eax
  1034f5:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
  1034fa:	f7 e2                	mul    %edx
  1034fc:	c1 ea 04             	shr    $0x4,%edx
  1034ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103502:	83 c0 01             	add    $0x1,%eax
  103505:	89 c1                	mov    %eax,%ecx
  103507:	d3 ea                	shr    %cl,%edx
  103509:	89 d0                	mov    %edx,%eax
  10350b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    while (now_order < MAX_ORDER && (bit_map[now_order][bit_num / 32] & (1 << (bit_num % 32))) == 0) {
  10350e:	e9 e3 00 00 00       	jmp    1035f6 <buddy_free_pages+0x2c9>
        // 得到当前插入页框的buddy
        struct Page *now_buddy = get_buddy(base, now_order);
  103513:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103516:	89 44 24 04          	mov    %eax,0x4(%esp)
  10351a:	8b 45 08             	mov    0x8(%ebp),%eax
  10351d:	89 04 24             	mov    %eax,(%esp)
  103520:	e8 bb fd ff ff       	call   1032e0 <get_buddy>
  103525:	89 45 e8             	mov    %eax,-0x18(%ebp)
        list_del(&now_buddy->page_link);
  103528:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10352b:	83 c0 0c             	add    $0xc,%eax
  10352e:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
  103531:	8b 45 cc             	mov    -0x34(%ebp),%eax
  103534:	8b 40 04             	mov    0x4(%eax),%eax
  103537:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10353a:	8b 12                	mov    (%edx),%edx
  10353c:	89 55 c8             	mov    %edx,-0x38(%ebp)
  10353f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
  103542:	8b 45 c8             	mov    -0x38(%ebp),%eax
  103545:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  103548:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
  10354b:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  10354e:	8b 55 c8             	mov    -0x38(%ebp),%edx
  103551:	89 10                	mov    %edx,(%eax)
        ClearPageProperty(now_buddy);
  103553:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103556:	83 c0 04             	add    $0x4,%eax
  103559:	c7 45 c0 01 00 00 00 	movl   $0x1,-0x40(%ebp)
  103560:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  103563:	8b 45 bc             	mov    -0x44(%ebp),%eax
  103566:	8b 55 c0             	mov    -0x40(%ebp),%edx
  103569:	0f b3 10             	btr    %edx,(%eax)
        nr_free(now_order) -= now_buddy->property;
  10356c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10356f:	89 d0                	mov    %edx,%eax
  103571:	01 c0                	add    %eax,%eax
  103573:	01 d0                	add    %edx,%eax
  103575:	c1 e0 02             	shl    $0x2,%eax
  103578:	05 40 57 12 00       	add    $0x125740,%eax
  10357d:	8b 50 08             	mov    0x8(%eax),%edx
  103580:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103583:	8b 40 08             	mov    0x8(%eax),%eax
  103586:	89 d1                	mov    %edx,%ecx
  103588:	29 c1                	sub    %eax,%ecx
  10358a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10358d:	89 d0                	mov    %edx,%eax
  10358f:	01 c0                	add    %eax,%eax
  103591:	01 d0                	add    %edx,%eax
  103593:	c1 e0 02             	shl    $0x2,%eax
  103596:	05 40 57 12 00       	add    $0x125740,%eax
  10359b:	89 48 08             	mov    %ecx,0x8(%eax)
        if (now_buddy < base) {
  10359e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1035a1:	3b 45 08             	cmp    0x8(%ebp),%eax
  1035a4:	73 06                	jae    1035ac <buddy_free_pages+0x27f>
            base = now_buddy;
  1035a6:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1035a9:	89 45 08             	mov    %eax,0x8(%ebp)
        }
        base->property <<= 1;
  1035ac:	8b 45 08             	mov    0x8(%ebp),%eax
  1035af:	8b 40 08             	mov    0x8(%eax),%eax
  1035b2:	8d 14 00             	lea    (%eax,%eax,1),%edx
  1035b5:	8b 45 08             	mov    0x8(%ebp),%eax
  1035b8:	89 50 08             	mov    %edx,0x8(%eax)
        now_order += 1;
  1035bb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
        flip_bit_map(now_order, base);
  1035bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1035c2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1035c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1035c9:	89 04 24             	mov    %eax,(%esp)
  1035cc:	e8 c6 f7 ff ff       	call   102d97 <flip_bit_map>
        bit_num = (offset(base) >> (now_order + 1));
  1035d1:	8b 55 08             	mov    0x8(%ebp),%edx
  1035d4:	a1 80 de 11 00       	mov    0x11de80,%eax
  1035d9:	29 c2                	sub    %eax,%edx
  1035db:	89 d0                	mov    %edx,%eax
  1035dd:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
  1035e2:	f7 e2                	mul    %edx
  1035e4:	c1 ea 04             	shr    $0x4,%edx
  1035e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1035ea:	83 c0 01             	add    $0x1,%eax
  1035ed:	89 c1                	mov    %eax,%ecx
  1035ef:	d3 ea                	shr    %cl,%edx
  1035f1:	89 d0                	mov    %edx,%eax
  1035f3:	89 45 ec             	mov    %eax,-0x14(%ebp)
    }
    base->property = n;
    // 开始尝试合并页框
    flip_bit_map(now_order, base);
    intptr_t bit_num = (offset(base) >> (now_order + 1));
    while (now_order < MAX_ORDER && (bit_map[now_order][bit_num / 32] & (1 << (bit_num % 32))) == 0) {
  1035f6:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
  1035fa:	7f 3c                	jg     103638 <buddy_free_pages+0x30b>
  1035fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1035ff:	8d 50 1f             	lea    0x1f(%eax),%edx
  103602:	85 c0                	test   %eax,%eax
  103604:	0f 48 c2             	cmovs  %edx,%eax
  103607:	c1 f8 05             	sar    $0x5,%eax
  10360a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10360d:	c1 e2 09             	shl    $0x9,%edx
  103610:	01 d0                	add    %edx,%eax
  103612:	8b 1c 85 a0 de 11 00 	mov    0x11dea0(,%eax,4),%ebx
  103619:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10361c:	99                   	cltd   
  10361d:	c1 ea 1b             	shr    $0x1b,%edx
  103620:	01 d0                	add    %edx,%eax
  103622:	83 e0 1f             	and    $0x1f,%eax
  103625:	29 d0                	sub    %edx,%eax
  103627:	89 c1                	mov    %eax,%ecx
  103629:	d3 fb                	sar    %cl,%ebx
  10362b:	89 d8                	mov    %ebx,%eax
  10362d:	83 e0 01             	and    $0x1,%eax
  103630:	85 c0                	test   %eax,%eax
  103632:	0f 84 db fe ff ff    	je     103513 <buddy_free_pages+0x1e6>
        base->property <<= 1;
        now_order += 1;
        flip_bit_map(now_order, base);
        bit_num = (offset(base) >> (now_order + 1));
    }
    SetPageProperty(base);
  103638:	8b 45 08             	mov    0x8(%ebp),%eax
  10363b:	83 c0 04             	add    $0x4,%eax
  10363e:	c7 45 b8 01 00 00 00 	movl   $0x1,-0x48(%ebp)
  103645:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  103648:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  10364b:	8b 55 b8             	mov    -0x48(%ebp),%edx
  10364e:	0f ab 10             	bts    %edx,(%eax)
    nr_free(now_order) += base->property;
  103651:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103654:	89 d0                	mov    %edx,%eax
  103656:	01 c0                	add    %eax,%eax
  103658:	01 d0                	add    %edx,%eax
  10365a:	c1 e0 02             	shl    $0x2,%eax
  10365d:	05 40 57 12 00       	add    $0x125740,%eax
  103662:	8b 50 08             	mov    0x8(%eax),%edx
  103665:	8b 45 08             	mov    0x8(%ebp),%eax
  103668:	8b 40 08             	mov    0x8(%eax),%eax
  10366b:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
  10366e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103671:	89 d0                	mov    %edx,%eax
  103673:	01 c0                	add    %eax,%eax
  103675:	01 d0                	add    %edx,%eax
  103677:	c1 e0 02             	shl    $0x2,%eax
  10367a:	05 40 57 12 00       	add    $0x125740,%eax
  10367f:	89 48 08             	mov    %ecx,0x8(%eax)
    list_add(&free_list(now_order), &base->page_link);
  103682:	8b 45 08             	mov    0x8(%ebp),%eax
  103685:	8d 48 0c             	lea    0xc(%eax),%ecx
  103688:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10368b:	89 d0                	mov    %edx,%eax
  10368d:	01 c0                	add    %eax,%eax
  10368f:	01 d0                	add    %edx,%eax
  103691:	c1 e0 02             	shl    $0x2,%eax
  103694:	05 40 57 12 00       	add    $0x125740,%eax
  103699:	89 45 b0             	mov    %eax,-0x50(%ebp)
  10369c:	89 4d ac             	mov    %ecx,-0x54(%ebp)
  10369f:	8b 45 b0             	mov    -0x50(%ebp),%eax
  1036a2:	89 45 a8             	mov    %eax,-0x58(%ebp)
  1036a5:	8b 45 ac             	mov    -0x54(%ebp),%eax
  1036a8:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
  1036ab:	8b 45 a8             	mov    -0x58(%ebp),%eax
  1036ae:	8b 40 04             	mov    0x4(%eax),%eax
  1036b1:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  1036b4:	89 55 a0             	mov    %edx,-0x60(%ebp)
  1036b7:	8b 55 a8             	mov    -0x58(%ebp),%edx
  1036ba:	89 55 9c             	mov    %edx,-0x64(%ebp)
  1036bd:	89 45 98             	mov    %eax,-0x68(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  1036c0:	8b 45 98             	mov    -0x68(%ebp),%eax
  1036c3:	8b 55 a0             	mov    -0x60(%ebp),%edx
  1036c6:	89 10                	mov    %edx,(%eax)
  1036c8:	8b 45 98             	mov    -0x68(%ebp),%eax
  1036cb:	8b 10                	mov    (%eax),%edx
  1036cd:	8b 45 9c             	mov    -0x64(%ebp),%eax
  1036d0:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  1036d3:	8b 45 a0             	mov    -0x60(%ebp),%eax
  1036d6:	8b 55 98             	mov    -0x68(%ebp),%edx
  1036d9:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  1036dc:	8b 45 a0             	mov    -0x60(%ebp),%eax
  1036df:	8b 55 9c             	mov    -0x64(%ebp),%edx
  1036e2:	89 10                	mov    %edx,(%eax)
}
  1036e4:	83 c4 74             	add    $0x74,%esp
  1036e7:	5b                   	pop    %ebx
  1036e8:	5d                   	pop    %ebp
  1036e9:	c3                   	ret    

001036ea <buddy_nr_free_pages>:

static size_t
buddy_nr_free_pages(void) {
  1036ea:	55                   	push   %ebp
  1036eb:	89 e5                	mov    %esp,%ebp
  1036ed:	83 ec 10             	sub    $0x10,%esp
    size_t total_nr_free = 0;
  1036f0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
  1036f7:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  1036fe:	eb 1b                	jmp    10371b <buddy_nr_free_pages+0x31>
        total_nr_free += nr_free(i);
  103700:	8b 55 f8             	mov    -0x8(%ebp),%edx
  103703:	89 d0                	mov    %edx,%eax
  103705:	01 c0                	add    %eax,%eax
  103707:	01 d0                	add    %edx,%eax
  103709:	c1 e0 02             	shl    $0x2,%eax
  10370c:	05 40 57 12 00       	add    $0x125740,%eax
  103711:	8b 40 08             	mov    0x8(%eax),%eax
  103714:	01 45 fc             	add    %eax,-0x4(%ebp)

static size_t
buddy_nr_free_pages(void) {
    size_t total_nr_free = 0;
    int i;
    for (i = 0; i <= MAX_ORDER; i++) {
  103717:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  10371b:	83 7d f8 0e          	cmpl   $0xe,-0x8(%ebp)
  10371f:	7e df                	jle    103700 <buddy_nr_free_pages+0x16>
        total_nr_free += nr_free(i);
    }
    return total_nr_free;
  103721:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  103724:	c9                   	leave  
  103725:	c3                   	ret    

00103726 <buddy_check>:

static void
buddy_check(void) {
  103726:	55                   	push   %ebp
  103727:	89 e5                	mov    %esp,%ebp
  103729:	83 ec 28             	sub    $0x28,%esp
    struct Page *p0, *p1, *p2;
    cprintf("\ntest_stage 1\n");
  10372c:	c7 04 24 65 7b 10 00 	movl   $0x107b65,(%esp)
  103733:	e8 1c cc ff ff       	call   100354 <cprintf>
    p0 = buddy_alloc_pages(1);
  103738:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10373f:	e8 23 f9 ff ff       	call   103067 <buddy_alloc_pages>
  103744:	89 45 f0             	mov    %eax,-0x10(%ebp)
    print_buddy_sys("alloc p0, size 1");
  103747:	c7 04 24 74 7b 10 00 	movl   $0x107b74,(%esp)
  10374e:	e8 12 f5 ff ff       	call   102c65 <print_buddy_sys>
    buddy_free_pages(p0, 1);
  103753:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10375a:	00 
  10375b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10375e:	89 04 24             	mov    %eax,(%esp)
  103761:	e8 c7 fb ff ff       	call   10332d <buddy_free_pages>
    print_buddy_sys("free p0");
  103766:	c7 04 24 85 7b 10 00 	movl   $0x107b85,(%esp)
  10376d:	e8 f3 f4 ff ff       	call   102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER));
  103772:	e8 73 ff ff ff       	call   1036ea <buddy_nr_free_pages>
  103777:	3d 00 40 00 00       	cmp    $0x4000,%eax
  10377c:	74 24                	je     1037a2 <buddy_check+0x7c>
  10377e:	c7 44 24 0c 90 7b 10 	movl   $0x107b90,0xc(%esp)
  103785:	00 
  103786:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  10378d:	00 
  10378e:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
  103795:	00 
  103796:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  10379d:	e8 3c d5 ff ff       	call   100cde <__panic>

    cprintf("\ntest_stage 2\n");
  1037a2:	c7 04 24 ba 7b 10 00 	movl   $0x107bba,(%esp)
  1037a9:	e8 a6 cb ff ff       	call   100354 <cprintf>
    p0 = buddy_alloc_pages(7);
  1037ae:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
  1037b5:	e8 ad f8 ff ff       	call   103067 <buddy_alloc_pages>
  1037ba:	89 45 f0             	mov    %eax,-0x10(%ebp)
    print_buddy_sys("alloc p0, size 7");
  1037bd:	c7 04 24 c9 7b 10 00 	movl   $0x107bc9,(%esp)
  1037c4:	e8 9c f4 ff ff       	call   102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 8);
  1037c9:	e8 1c ff ff ff       	call   1036ea <buddy_nr_free_pages>
  1037ce:	3d f8 3f 00 00       	cmp    $0x3ff8,%eax
  1037d3:	74 24                	je     1037f9 <buddy_check+0xd3>
  1037d5:	c7 44 24 0c dc 7b 10 	movl   $0x107bdc,0xc(%esp)
  1037dc:	00 
  1037dd:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  1037e4:	00 
  1037e5:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  1037ec:	00 
  1037ed:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  1037f4:	e8 e5 d4 ff ff       	call   100cde <__panic>
    p1 = buddy_alloc_pages(15);
  1037f9:	c7 04 24 0f 00 00 00 	movl   $0xf,(%esp)
  103800:	e8 62 f8 ff ff       	call   103067 <buddy_alloc_pages>
  103805:	89 45 ec             	mov    %eax,-0x14(%ebp)
    print_buddy_sys("alloc p1, size 15");
  103808:	c7 04 24 0a 7c 10 00 	movl   $0x107c0a,(%esp)
  10380f:	e8 51 f4 ff ff       	call   102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 24);
  103814:	e8 d1 fe ff ff       	call   1036ea <buddy_nr_free_pages>
  103819:	3d e8 3f 00 00       	cmp    $0x3fe8,%eax
  10381e:	74 24                	je     103844 <buddy_check+0x11e>
  103820:	c7 44 24 0c 1c 7c 10 	movl   $0x107c1c,0xc(%esp)
  103827:	00 
  103828:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  10382f:	00 
  103830:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
  103837:	00 
  103838:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  10383f:	e8 9a d4 ff ff       	call   100cde <__panic>
    p2 = buddy_alloc_pages(1);
  103844:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10384b:	e8 17 f8 ff ff       	call   103067 <buddy_alloc_pages>
  103850:	89 45 e8             	mov    %eax,-0x18(%ebp)
    print_buddy_sys("alloc p2, size 1");
  103853:	c7 04 24 4b 7c 10 00 	movl   $0x107c4b,(%esp)
  10385a:	e8 06 f4 ff ff       	call   102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 25);
  10385f:	e8 86 fe ff ff       	call   1036ea <buddy_nr_free_pages>
  103864:	3d e7 3f 00 00       	cmp    $0x3fe7,%eax
  103869:	74 24                	je     10388f <buddy_check+0x169>
  10386b:	c7 44 24 0c 5c 7c 10 	movl   $0x107c5c,0xc(%esp)
  103872:	00 
  103873:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  10387a:	00 
  10387b:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  103882:	00 
  103883:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  10388a:	e8 4f d4 ff ff       	call   100cde <__panic>
    buddy_free_pages(p0, 7);
  10388f:	c7 44 24 04 07 00 00 	movl   $0x7,0x4(%esp)
  103896:	00 
  103897:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10389a:	89 04 24             	mov    %eax,(%esp)
  10389d:	e8 8b fa ff ff       	call   10332d <buddy_free_pages>
    print_buddy_sys("free p0");
  1038a2:	c7 04 24 85 7b 10 00 	movl   $0x107b85,(%esp)
  1038a9:	e8 b7 f3 ff ff       	call   102c65 <print_buddy_sys>
    buddy_free_pages(p1, 15);
  1038ae:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
  1038b5:	00 
  1038b6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1038b9:	89 04 24             	mov    %eax,(%esp)
  1038bc:	e8 6c fa ff ff       	call   10332d <buddy_free_pages>
    print_buddy_sys("free p1");
  1038c1:	c7 04 24 8b 7c 10 00 	movl   $0x107c8b,(%esp)
  1038c8:	e8 98 f3 ff ff       	call   102c65 <print_buddy_sys>
    buddy_free_pages(p2, 1);
  1038cd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1038d4:	00 
  1038d5:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1038d8:	89 04 24             	mov    %eax,(%esp)
  1038db:	e8 4d fa ff ff       	call   10332d <buddy_free_pages>
    print_buddy_sys("free p2");
  1038e0:	c7 04 24 93 7c 10 00 	movl   $0x107c93,(%esp)
  1038e7:	e8 79 f3 ff ff       	call   102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER));
  1038ec:	e8 f9 fd ff ff       	call   1036ea <buddy_nr_free_pages>
  1038f1:	3d 00 40 00 00       	cmp    $0x4000,%eax
  1038f6:	74 24                	je     10391c <buddy_check+0x1f6>
  1038f8:	c7 44 24 0c 90 7b 10 	movl   $0x107b90,0xc(%esp)
  1038ff:	00 
  103900:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  103907:	00 
  103908:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  10390f:	00 
  103910:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  103917:	e8 c2 d3 ff ff       	call   100cde <__panic>

    cprintf("\ntest_stage 3\n");
  10391c:	c7 04 24 9b 7c 10 00 	movl   $0x107c9b,(%esp)
  103923:	e8 2c ca ff ff       	call   100354 <cprintf>
    p0 = buddy_alloc_pages(257);
  103928:	c7 04 24 01 01 00 00 	movl   $0x101,(%esp)
  10392f:	e8 33 f7 ff ff       	call   103067 <buddy_alloc_pages>
  103934:	89 45 f0             	mov    %eax,-0x10(%ebp)
    print_buddy_sys("alloc p0, size 257");
  103937:	c7 04 24 aa 7c 10 00 	movl   $0x107caa,(%esp)
  10393e:	e8 22 f3 ff ff       	call   102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 512);
  103943:	e8 a2 fd ff ff       	call   1036ea <buddy_nr_free_pages>
  103948:	3d 00 3e 00 00       	cmp    $0x3e00,%eax
  10394d:	74 24                	je     103973 <buddy_check+0x24d>
  10394f:	c7 44 24 0c c0 7c 10 	movl   $0x107cc0,0xc(%esp)
  103956:	00 
  103957:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  10395e:	00 
  10395f:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
  103966:	00 
  103967:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  10396e:	e8 6b d3 ff ff       	call   100cde <__panic>
    p1 = buddy_alloc_pages(257);
  103973:	c7 04 24 01 01 00 00 	movl   $0x101,(%esp)
  10397a:	e8 e8 f6 ff ff       	call   103067 <buddy_alloc_pages>
  10397f:	89 45 ec             	mov    %eax,-0x14(%ebp)
    print_buddy_sys("alloc p1, size 257");
  103982:	c7 04 24 f0 7c 10 00 	movl   $0x107cf0,(%esp)
  103989:	e8 d7 f2 ff ff       	call   102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 1024);
  10398e:	e8 57 fd ff ff       	call   1036ea <buddy_nr_free_pages>
  103993:	3d 00 3c 00 00       	cmp    $0x3c00,%eax
  103998:	74 24                	je     1039be <buddy_check+0x298>
  10399a:	c7 44 24 0c 04 7d 10 	movl   $0x107d04,0xc(%esp)
  1039a1:	00 
  1039a2:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  1039a9:	00 
  1039aa:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
  1039b1:	00 
  1039b2:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  1039b9:	e8 20 d3 ff ff       	call   100cde <__panic>
    p2 = buddy_alloc_pages(257);
  1039be:	c7 04 24 01 01 00 00 	movl   $0x101,(%esp)
  1039c5:	e8 9d f6 ff ff       	call   103067 <buddy_alloc_pages>
  1039ca:	89 45 e8             	mov    %eax,-0x18(%ebp)
    print_buddy_sys("alloc p2, size 257");
  1039cd:	c7 04 24 35 7d 10 00 	movl   $0x107d35,(%esp)
  1039d4:	e8 8c f2 ff ff       	call   102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER) - 1536);
  1039d9:	e8 0c fd ff ff       	call   1036ea <buddy_nr_free_pages>
  1039de:	3d 00 3a 00 00       	cmp    $0x3a00,%eax
  1039e3:	74 24                	je     103a09 <buddy_check+0x2e3>
  1039e5:	c7 44 24 0c 48 7d 10 	movl   $0x107d48,0xc(%esp)
  1039ec:	00 
  1039ed:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  1039f4:	00 
  1039f5:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
  1039fc:	00 
  1039fd:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  103a04:	e8 d5 d2 ff ff       	call   100cde <__panic>
    buddy_free_pages(p0, 257);
  103a09:	c7 44 24 04 01 01 00 	movl   $0x101,0x4(%esp)
  103a10:	00 
  103a11:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103a14:	89 04 24             	mov    %eax,(%esp)
  103a17:	e8 11 f9 ff ff       	call   10332d <buddy_free_pages>
    print_buddy_sys("free p0");
  103a1c:	c7 04 24 85 7b 10 00 	movl   $0x107b85,(%esp)
  103a23:	e8 3d f2 ff ff       	call   102c65 <print_buddy_sys>
    buddy_free_pages(p1, 257);
  103a28:	c7 44 24 04 01 01 00 	movl   $0x101,0x4(%esp)
  103a2f:	00 
  103a30:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103a33:	89 04 24             	mov    %eax,(%esp)
  103a36:	e8 f2 f8 ff ff       	call   10332d <buddy_free_pages>
    print_buddy_sys("free p1");
  103a3b:	c7 04 24 8b 7c 10 00 	movl   $0x107c8b,(%esp)
  103a42:	e8 1e f2 ff ff       	call   102c65 <print_buddy_sys>
    buddy_free_pages(p2, 257);
  103a47:	c7 44 24 04 01 01 00 	movl   $0x101,0x4(%esp)
  103a4e:	00 
  103a4f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a52:	89 04 24             	mov    %eax,(%esp)
  103a55:	e8 d3 f8 ff ff       	call   10332d <buddy_free_pages>
    print_buddy_sys("free p2");
  103a5a:	c7 04 24 93 7c 10 00 	movl   $0x107c93,(%esp)
  103a61:	e8 ff f1 ff ff       	call   102c65 <print_buddy_sys>
    assert(buddy_nr_free_pages() == (1 << MAX_ORDER));
  103a66:	e8 7f fc ff ff       	call   1036ea <buddy_nr_free_pages>
  103a6b:	3d 00 40 00 00       	cmp    $0x4000,%eax
  103a70:	74 24                	je     103a96 <buddy_check+0x370>
  103a72:	c7 44 24 0c 90 7b 10 	movl   $0x107b90,0xc(%esp)
  103a79:	00 
  103a7a:	c7 44 24 08 a8 7a 10 	movl   $0x107aa8,0x8(%esp)
  103a81:	00 
  103a82:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  103a89:	00 
  103a8a:	c7 04 24 bd 7a 10 00 	movl   $0x107abd,(%esp)
  103a91:	e8 48 d2 ff ff       	call   100cde <__panic>

    cprintf("\ntest_stage 4\n");
  103a96:	c7 04 24 79 7d 10 00 	movl   $0x107d79,(%esp)
  103a9d:	e8 b2 c8 ff ff       	call   100354 <cprintf>
    p0 = buddy_alloc_pages(8);
  103aa2:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  103aa9:	e8 b9 f5 ff ff       	call   103067 <buddy_alloc_pages>
  103aae:	89 45 f0             	mov    %eax,-0x10(%ebp)
    print_buddy_sys("alloc p0, size 8");
  103ab1:	c7 04 24 88 7d 10 00 	movl   $0x107d88,(%esp)
  103ab8:	e8 a8 f1 ff ff       	call   102c65 <print_buddy_sys>
    int32_t i;
    for (i = 0; i < 8; i += 2) {
  103abd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  103ac4:	eb 34                	jmp    103afa <buddy_check+0x3d4>
        buddy_free_pages(p0 + i, 1);
  103ac6:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103ac9:	89 d0                	mov    %edx,%eax
  103acb:	c1 e0 02             	shl    $0x2,%eax
  103ace:	01 d0                	add    %edx,%eax
  103ad0:	c1 e0 02             	shl    $0x2,%eax
  103ad3:	89 c2                	mov    %eax,%edx
  103ad5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103ad8:	01 d0                	add    %edx,%eax
  103ada:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103ae1:	00 
  103ae2:	89 04 24             	mov    %eax,(%esp)
  103ae5:	e8 43 f8 ff ff       	call   10332d <buddy_free_pages>
        print_buddy_sys("free p0 + i, size 1");
  103aea:	c7 04 24 99 7d 10 00 	movl   $0x107d99,(%esp)
  103af1:	e8 6f f1 ff ff       	call   102c65 <print_buddy_sys>

    cprintf("\ntest_stage 4\n");
    p0 = buddy_alloc_pages(8);
    print_buddy_sys("alloc p0, size 8");
    int32_t i;
    for (i = 0; i < 8; i += 2) {
  103af6:	83 45 f4 02          	addl   $0x2,-0xc(%ebp)
  103afa:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
  103afe:	7e c6                	jle    103ac6 <buddy_check+0x3a0>
        buddy_free_pages(p0 + i, 1);
        print_buddy_sys("free p0 + i, size 1");
    }
    for (i = 1; i < 8; i += 2) {
  103b00:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  103b07:	eb 34                	jmp    103b3d <buddy_check+0x417>
        buddy_free_pages(p0 + i, 1);
  103b09:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103b0c:	89 d0                	mov    %edx,%eax
  103b0e:	c1 e0 02             	shl    $0x2,%eax
  103b11:	01 d0                	add    %edx,%eax
  103b13:	c1 e0 02             	shl    $0x2,%eax
  103b16:	89 c2                	mov    %eax,%edx
  103b18:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103b1b:	01 d0                	add    %edx,%eax
  103b1d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103b24:	00 
  103b25:	89 04 24             	mov    %eax,(%esp)
  103b28:	e8 00 f8 ff ff       	call   10332d <buddy_free_pages>
        print_buddy_sys("free p0 + i, size 1");
  103b2d:	c7 04 24 99 7d 10 00 	movl   $0x107d99,(%esp)
  103b34:	e8 2c f1 ff ff       	call   102c65 <print_buddy_sys>
    int32_t i;
    for (i = 0; i < 8; i += 2) {
        buddy_free_pages(p0 + i, 1);
        print_buddy_sys("free p0 + i, size 1");
    }
    for (i = 1; i < 8; i += 2) {
  103b39:	83 45 f4 02          	addl   $0x2,-0xc(%ebp)
  103b3d:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
  103b41:	7e c6                	jle    103b09 <buddy_check+0x3e3>
        buddy_free_pages(p0 + i, 1);
        print_buddy_sys("free p0 + i, size 1");
    }
}
  103b43:	c9                   	leave  
  103b44:	c3                   	ret    

00103b45 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
  103b45:	55                   	push   %ebp
  103b46:	89 e5                	mov    %esp,%ebp
    return page - pages;
  103b48:	8b 55 08             	mov    0x8(%ebp),%edx
  103b4b:	a1 fc 57 12 00       	mov    0x1257fc,%eax
  103b50:	29 c2                	sub    %eax,%edx
  103b52:	89 d0                	mov    %edx,%eax
  103b54:	c1 f8 02             	sar    $0x2,%eax
  103b57:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
  103b5d:	5d                   	pop    %ebp
  103b5e:	c3                   	ret    

00103b5f <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
  103b5f:	55                   	push   %ebp
  103b60:	89 e5                	mov    %esp,%ebp
  103b62:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
  103b65:	8b 45 08             	mov    0x8(%ebp),%eax
  103b68:	89 04 24             	mov    %eax,(%esp)
  103b6b:	e8 d5 ff ff ff       	call   103b45 <page2ppn>
  103b70:	c1 e0 0c             	shl    $0xc,%eax
}
  103b73:	c9                   	leave  
  103b74:	c3                   	ret    

00103b75 <page_ref>:
pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
}

static inline int
page_ref(struct Page *page) {
  103b75:	55                   	push   %ebp
  103b76:	89 e5                	mov    %esp,%ebp
    return page->ref;
  103b78:	8b 45 08             	mov    0x8(%ebp),%eax
  103b7b:	8b 00                	mov    (%eax),%eax
}
  103b7d:	5d                   	pop    %ebp
  103b7e:	c3                   	ret    

00103b7f <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
  103b7f:	55                   	push   %ebp
  103b80:	89 e5                	mov    %esp,%ebp
    page->ref = val;
  103b82:	8b 45 08             	mov    0x8(%ebp),%eax
  103b85:	8b 55 0c             	mov    0xc(%ebp),%edx
  103b88:	89 10                	mov    %edx,(%eax)
}
  103b8a:	5d                   	pop    %ebp
  103b8b:	c3                   	ret    

00103b8c <default_init>:

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
  103b8c:	55                   	push   %ebp
  103b8d:	89 e5                	mov    %esp,%ebp
  103b8f:	83 ec 10             	sub    $0x10,%esp
  103b92:	c7 45 fc 40 57 12 00 	movl   $0x125740,-0x4(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
  103b99:	8b 45 fc             	mov    -0x4(%ebp),%eax
  103b9c:	8b 55 fc             	mov    -0x4(%ebp),%edx
  103b9f:	89 50 04             	mov    %edx,0x4(%eax)
  103ba2:	8b 45 fc             	mov    -0x4(%ebp),%eax
  103ba5:	8b 50 04             	mov    0x4(%eax),%edx
  103ba8:	8b 45 fc             	mov    -0x4(%ebp),%eax
  103bab:	89 10                	mov    %edx,(%eax)
    list_init(&free_list);
    nr_free = 0;
  103bad:	c7 05 48 57 12 00 00 	movl   $0x0,0x125748
  103bb4:	00 00 00 
}
  103bb7:	c9                   	leave  
  103bb8:	c3                   	ret    

00103bb9 <default_init_memmap>:

static void
default_init_memmap(struct Page *base, size_t n) {
  103bb9:	55                   	push   %ebp
  103bba:	89 e5                	mov    %esp,%ebp
  103bbc:	83 ec 48             	sub    $0x48,%esp
    cprintf("va: 0x%x, pa: 0x%x, num: %d\n", base, page2pa(base), n);
  103bbf:	8b 45 08             	mov    0x8(%ebp),%eax
  103bc2:	89 04 24             	mov    %eax,(%esp)
  103bc5:	e8 95 ff ff ff       	call   103b5f <page2pa>
  103bca:	8b 55 0c             	mov    0xc(%ebp),%edx
  103bcd:	89 54 24 0c          	mov    %edx,0xc(%esp)
  103bd1:	89 44 24 08          	mov    %eax,0x8(%esp)
  103bd5:	8b 45 08             	mov    0x8(%ebp),%eax
  103bd8:	89 44 24 04          	mov    %eax,0x4(%esp)
  103bdc:	c7 04 24 dc 7d 10 00 	movl   $0x107ddc,(%esp)
  103be3:	e8 6c c7 ff ff       	call   100354 <cprintf>
    assert(n > 0);
  103be8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  103bec:	75 24                	jne    103c12 <default_init_memmap+0x59>
  103bee:	c7 44 24 0c f9 7d 10 	movl   $0x107df9,0xc(%esp)
  103bf5:	00 
  103bf6:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  103bfd:	00 
  103bfe:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
  103c05:	00 
  103c06:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  103c0d:	e8 cc d0 ff ff       	call   100cde <__panic>
    struct Page *p = base;
  103c12:	8b 45 08             	mov    0x8(%ebp),%eax
  103c15:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
  103c18:	eb 7d                	jmp    103c97 <default_init_memmap+0xde>
        assert(PageReserved(p));
  103c1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c1d:	83 c0 04             	add    $0x4,%eax
  103c20:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  103c27:	89 45 ec             	mov    %eax,-0x14(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  103c2a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103c2d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  103c30:	0f a3 10             	bt     %edx,(%eax)
  103c33:	19 c0                	sbb    %eax,%eax
  103c35:	89 45 e8             	mov    %eax,-0x18(%ebp)
    return oldbit != 0;
  103c38:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  103c3c:	0f 95 c0             	setne  %al
  103c3f:	0f b6 c0             	movzbl %al,%eax
  103c42:	85 c0                	test   %eax,%eax
  103c44:	75 24                	jne    103c6a <default_init_memmap+0xb1>
  103c46:	c7 44 24 0c 2a 7e 10 	movl   $0x107e2a,0xc(%esp)
  103c4d:	00 
  103c4e:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  103c55:	00 
  103c56:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
  103c5d:	00 
  103c5e:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  103c65:	e8 74 d0 ff ff       	call   100cde <__panic>
        p->flags = p->property = 0;
  103c6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c6d:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  103c74:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c77:	8b 50 08             	mov    0x8(%eax),%edx
  103c7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c7d:	89 50 04             	mov    %edx,0x4(%eax)
        set_page_ref(p, 0);
  103c80:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103c87:	00 
  103c88:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c8b:	89 04 24             	mov    %eax,(%esp)
  103c8e:	e8 ec fe ff ff       	call   103b7f <set_page_ref>
static void
default_init_memmap(struct Page *base, size_t n) {
    cprintf("va: 0x%x, pa: 0x%x, num: %d\n", base, page2pa(base), n);
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
  103c93:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
  103c97:	8b 55 0c             	mov    0xc(%ebp),%edx
  103c9a:	89 d0                	mov    %edx,%eax
  103c9c:	c1 e0 02             	shl    $0x2,%eax
  103c9f:	01 d0                	add    %edx,%eax
  103ca1:	c1 e0 02             	shl    $0x2,%eax
  103ca4:	89 c2                	mov    %eax,%edx
  103ca6:	8b 45 08             	mov    0x8(%ebp),%eax
  103ca9:	01 d0                	add    %edx,%eax
  103cab:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  103cae:	0f 85 66 ff ff ff    	jne    103c1a <default_init_memmap+0x61>
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
  103cb4:	8b 45 08             	mov    0x8(%ebp),%eax
  103cb7:	8b 55 0c             	mov    0xc(%ebp),%edx
  103cba:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
  103cbd:	8b 45 08             	mov    0x8(%ebp),%eax
  103cc0:	83 c0 04             	add    $0x4,%eax
  103cc3:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
  103cca:	89 45 e0             	mov    %eax,-0x20(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  103ccd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103cd0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103cd3:	0f ab 10             	bts    %edx,(%eax)
    nr_free += n;
  103cd6:	8b 15 48 57 12 00    	mov    0x125748,%edx
  103cdc:	8b 45 0c             	mov    0xc(%ebp),%eax
  103cdf:	01 d0                	add    %edx,%eax
  103ce1:	a3 48 57 12 00       	mov    %eax,0x125748
    //默认地址是从小到大来的，因此这里要改成before
    list_add_before(&free_list, &(base->page_link));
  103ce6:	8b 45 08             	mov    0x8(%ebp),%eax
  103ce9:	83 c0 0c             	add    $0xc,%eax
  103cec:	c7 45 dc 40 57 12 00 	movl   $0x125740,-0x24(%ebp)
  103cf3:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
  103cf6:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103cf9:	8b 00                	mov    (%eax),%eax
  103cfb:	8b 55 d8             	mov    -0x28(%ebp),%edx
  103cfe:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  103d01:	89 45 d0             	mov    %eax,-0x30(%ebp)
  103d04:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103d07:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  103d0a:	8b 45 cc             	mov    -0x34(%ebp),%eax
  103d0d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103d10:	89 10                	mov    %edx,(%eax)
  103d12:	8b 45 cc             	mov    -0x34(%ebp),%eax
  103d15:	8b 10                	mov    (%eax),%edx
  103d17:	8b 45 d0             	mov    -0x30(%ebp),%eax
  103d1a:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  103d1d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  103d20:	8b 55 cc             	mov    -0x34(%ebp),%edx
  103d23:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  103d26:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  103d29:	8b 55 d0             	mov    -0x30(%ebp),%edx
  103d2c:	89 10                	mov    %edx,(%eax)
}
  103d2e:	c9                   	leave  
  103d2f:	c3                   	ret    

00103d30 <default_alloc_pages>:

static struct Page *
default_alloc_pages(size_t n) {
  103d30:	55                   	push   %ebp
  103d31:	89 e5                	mov    %esp,%ebp
  103d33:	83 ec 68             	sub    $0x68,%esp
    assert(n > 0);
  103d36:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  103d3a:	75 24                	jne    103d60 <default_alloc_pages+0x30>
  103d3c:	c7 44 24 0c f9 7d 10 	movl   $0x107df9,0xc(%esp)
  103d43:	00 
  103d44:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  103d4b:	00 
  103d4c:	c7 44 24 04 7e 00 00 	movl   $0x7e,0x4(%esp)
  103d53:	00 
  103d54:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  103d5b:	e8 7e cf ff ff       	call   100cde <__panic>
    if (n > nr_free) {
  103d60:	a1 48 57 12 00       	mov    0x125748,%eax
  103d65:	3b 45 08             	cmp    0x8(%ebp),%eax
  103d68:	73 0a                	jae    103d74 <default_alloc_pages+0x44>
        return NULL;
  103d6a:	b8 00 00 00 00       	mov    $0x0,%eax
  103d6f:	e9 3d 01 00 00       	jmp    103eb1 <default_alloc_pages+0x181>
    }
    struct Page *page = NULL;
  103d74:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    list_entry_t *le = &free_list;
  103d7b:	c7 45 f0 40 57 12 00 	movl   $0x125740,-0x10(%ebp)
    while ((le = list_next(le)) != &free_list) {
  103d82:	eb 1c                	jmp    103da0 <default_alloc_pages+0x70>
        struct Page *p = le2page(le, page_link);
  103d84:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103d87:	83 e8 0c             	sub    $0xc,%eax
  103d8a:	89 45 ec             	mov    %eax,-0x14(%ebp)
        if (p->property >= n) {
  103d8d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103d90:	8b 40 08             	mov    0x8(%eax),%eax
  103d93:	3b 45 08             	cmp    0x8(%ebp),%eax
  103d96:	72 08                	jb     103da0 <default_alloc_pages+0x70>
            page = p;
  103d98:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103d9b:	89 45 f4             	mov    %eax,-0xc(%ebp)
            break;
  103d9e:	eb 18                	jmp    103db8 <default_alloc_pages+0x88>
  103da0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103da3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  103da6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103da9:	8b 40 04             	mov    0x4(%eax),%eax
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
  103dac:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103daf:	81 7d f0 40 57 12 00 	cmpl   $0x125740,-0x10(%ebp)
  103db6:	75 cc                	jne    103d84 <default_alloc_pages+0x54>
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
  103db8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103dbc:	0f 84 ec 00 00 00    	je     103eae <default_alloc_pages+0x17e>
        if (page->property > n) {
  103dc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103dc5:	8b 40 08             	mov    0x8(%eax),%eax
  103dc8:	3b 45 08             	cmp    0x8(%ebp),%eax
  103dcb:	0f 86 8c 00 00 00    	jbe    103e5d <default_alloc_pages+0x12d>
            struct Page *p = page + n;
  103dd1:	8b 55 08             	mov    0x8(%ebp),%edx
  103dd4:	89 d0                	mov    %edx,%eax
  103dd6:	c1 e0 02             	shl    $0x2,%eax
  103dd9:	01 d0                	add    %edx,%eax
  103ddb:	c1 e0 02             	shl    $0x2,%eax
  103dde:	89 c2                	mov    %eax,%edx
  103de0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103de3:	01 d0                	add    %edx,%eax
  103de5:	89 45 e8             	mov    %eax,-0x18(%ebp)
            p->property = page->property - n;
  103de8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103deb:	8b 40 08             	mov    0x8(%eax),%eax
  103dee:	2b 45 08             	sub    0x8(%ebp),%eax
  103df1:	89 c2                	mov    %eax,%edx
  103df3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103df6:	89 50 08             	mov    %edx,0x8(%eax)
            SetPageProperty(p);
  103df9:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103dfc:	83 c0 04             	add    $0x4,%eax
  103dff:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
  103e06:	89 45 dc             	mov    %eax,-0x24(%ebp)
  103e09:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103e0c:	8b 55 e0             	mov    -0x20(%ebp),%edx
  103e0f:	0f ab 10             	bts    %edx,(%eax)
            list_add_after(page->page_link.prev, &(p->page_link));
  103e12:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103e15:	8d 50 0c             	lea    0xc(%eax),%edx
  103e18:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103e1b:	8b 40 0c             	mov    0xc(%eax),%eax
  103e1e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  103e21:	89 55 d4             	mov    %edx,-0x2c(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
  103e24:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103e27:	8b 40 04             	mov    0x4(%eax),%eax
  103e2a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103e2d:	89 55 d0             	mov    %edx,-0x30(%ebp)
  103e30:	8b 55 d8             	mov    -0x28(%ebp),%edx
  103e33:	89 55 cc             	mov    %edx,-0x34(%ebp)
  103e36:	89 45 c8             	mov    %eax,-0x38(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  103e39:	8b 45 c8             	mov    -0x38(%ebp),%eax
  103e3c:	8b 55 d0             	mov    -0x30(%ebp),%edx
  103e3f:	89 10                	mov    %edx,(%eax)
  103e41:	8b 45 c8             	mov    -0x38(%ebp),%eax
  103e44:	8b 10                	mov    (%eax),%edx
  103e46:	8b 45 cc             	mov    -0x34(%ebp),%eax
  103e49:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  103e4c:	8b 45 d0             	mov    -0x30(%ebp),%eax
  103e4f:	8b 55 c8             	mov    -0x38(%ebp),%edx
  103e52:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  103e55:	8b 45 d0             	mov    -0x30(%ebp),%eax
  103e58:	8b 55 cc             	mov    -0x34(%ebp),%edx
  103e5b:	89 10                	mov    %edx,(%eax)
        }
        list_del(&(page->page_link));
  103e5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103e60:	83 c0 0c             	add    $0xc,%eax
  103e63:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
  103e66:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  103e69:	8b 40 04             	mov    0x4(%eax),%eax
  103e6c:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  103e6f:	8b 12                	mov    (%edx),%edx
  103e71:	89 55 c0             	mov    %edx,-0x40(%ebp)
  103e74:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
  103e77:	8b 45 c0             	mov    -0x40(%ebp),%eax
  103e7a:	8b 55 bc             	mov    -0x44(%ebp),%edx
  103e7d:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
  103e80:	8b 45 bc             	mov    -0x44(%ebp),%eax
  103e83:	8b 55 c0             	mov    -0x40(%ebp),%edx
  103e86:	89 10                	mov    %edx,(%eax)
        nr_free -= n;
  103e88:	a1 48 57 12 00       	mov    0x125748,%eax
  103e8d:	2b 45 08             	sub    0x8(%ebp),%eax
  103e90:	a3 48 57 12 00       	mov    %eax,0x125748
        ClearPageProperty(page);
  103e95:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103e98:	83 c0 04             	add    $0x4,%eax
  103e9b:	c7 45 b8 01 00 00 00 	movl   $0x1,-0x48(%ebp)
  103ea2:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  103ea5:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  103ea8:	8b 55 b8             	mov    -0x48(%ebp),%edx
  103eab:	0f b3 10             	btr    %edx,(%eax)
    }
    return page;
  103eae:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  103eb1:	c9                   	leave  
  103eb2:	c3                   	ret    

00103eb3 <default_free_pages>:

static void
default_free_pages(struct Page *base, size_t n) {
  103eb3:	55                   	push   %ebp
  103eb4:	89 e5                	mov    %esp,%ebp
  103eb6:	81 ec 98 00 00 00    	sub    $0x98,%esp
    assert(n > 0);
  103ebc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  103ec0:	75 24                	jne    103ee6 <default_free_pages+0x33>
  103ec2:	c7 44 24 0c f9 7d 10 	movl   $0x107df9,0xc(%esp)
  103ec9:	00 
  103eca:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  103ed1:	00 
  103ed2:	c7 44 24 04 9b 00 00 	movl   $0x9b,0x4(%esp)
  103ed9:	00 
  103eda:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  103ee1:	e8 f8 cd ff ff       	call   100cde <__panic>
    struct Page *p = base;
  103ee6:	8b 45 08             	mov    0x8(%ebp),%eax
  103ee9:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
  103eec:	e9 9d 00 00 00       	jmp    103f8e <default_free_pages+0xdb>
        assert(!PageReserved(p) && !PageProperty(p));
  103ef1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ef4:	83 c0 04             	add    $0x4,%eax
  103ef7:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  103efe:	89 45 e8             	mov    %eax,-0x18(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  103f01:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103f04:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103f07:	0f a3 10             	bt     %edx,(%eax)
  103f0a:	19 c0                	sbb    %eax,%eax
  103f0c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    return oldbit != 0;
  103f0f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  103f13:	0f 95 c0             	setne  %al
  103f16:	0f b6 c0             	movzbl %al,%eax
  103f19:	85 c0                	test   %eax,%eax
  103f1b:	75 2c                	jne    103f49 <default_free_pages+0x96>
  103f1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103f20:	83 c0 04             	add    $0x4,%eax
  103f23:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
  103f2a:	89 45 dc             	mov    %eax,-0x24(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  103f2d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103f30:	8b 55 e0             	mov    -0x20(%ebp),%edx
  103f33:	0f a3 10             	bt     %edx,(%eax)
  103f36:	19 c0                	sbb    %eax,%eax
  103f38:	89 45 d8             	mov    %eax,-0x28(%ebp)
    return oldbit != 0;
  103f3b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  103f3f:	0f 95 c0             	setne  %al
  103f42:	0f b6 c0             	movzbl %al,%eax
  103f45:	85 c0                	test   %eax,%eax
  103f47:	74 24                	je     103f6d <default_free_pages+0xba>
  103f49:	c7 44 24 0c 3c 7e 10 	movl   $0x107e3c,0xc(%esp)
  103f50:	00 
  103f51:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  103f58:	00 
  103f59:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  103f60:	00 
  103f61:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  103f68:	e8 71 cd ff ff       	call   100cde <__panic>
        p->flags = 0;
  103f6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103f70:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
        set_page_ref(p, 0);
  103f77:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103f7e:	00 
  103f7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103f82:	89 04 24             	mov    %eax,(%esp)
  103f85:	e8 f5 fb ff ff       	call   103b7f <set_page_ref>

static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
  103f8a:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
  103f8e:	8b 55 0c             	mov    0xc(%ebp),%edx
  103f91:	89 d0                	mov    %edx,%eax
  103f93:	c1 e0 02             	shl    $0x2,%eax
  103f96:	01 d0                	add    %edx,%eax
  103f98:	c1 e0 02             	shl    $0x2,%eax
  103f9b:	89 c2                	mov    %eax,%edx
  103f9d:	8b 45 08             	mov    0x8(%ebp),%eax
  103fa0:	01 d0                	add    %edx,%eax
  103fa2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  103fa5:	0f 85 46 ff ff ff    	jne    103ef1 <default_free_pages+0x3e>
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
  103fab:	8b 45 08             	mov    0x8(%ebp),%eax
  103fae:	8b 55 0c             	mov    0xc(%ebp),%edx
  103fb1:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
  103fb4:	8b 45 08             	mov    0x8(%ebp),%eax
  103fb7:	83 c0 04             	add    $0x4,%eax
  103fba:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  103fc1:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  103fc4:	8b 45 d0             	mov    -0x30(%ebp),%eax
  103fc7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103fca:	0f ab 10             	bts    %edx,(%eax)
  103fcd:	c7 45 cc 40 57 12 00 	movl   $0x125740,-0x34(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  103fd4:	8b 45 cc             	mov    -0x34(%ebp),%eax
  103fd7:	8b 40 04             	mov    0x4(%eax),%eax
    list_entry_t *le = list_next(&free_list);
  103fda:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
  103fdd:	e9 0b 01 00 00       	jmp    1040ed <default_free_pages+0x23a>
        p = le2page(le, page_link);
  103fe2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103fe5:	83 e8 0c             	sub    $0xc,%eax
  103fe8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  103feb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103fee:	89 45 c8             	mov    %eax,-0x38(%ebp)
  103ff1:	8b 45 c8             	mov    -0x38(%ebp),%eax
  103ff4:	8b 40 04             	mov    0x4(%eax),%eax
        le = list_next(le);
  103ff7:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (base + base->property == p) {
  103ffa:	8b 45 08             	mov    0x8(%ebp),%eax
  103ffd:	8b 50 08             	mov    0x8(%eax),%edx
  104000:	89 d0                	mov    %edx,%eax
  104002:	c1 e0 02             	shl    $0x2,%eax
  104005:	01 d0                	add    %edx,%eax
  104007:	c1 e0 02             	shl    $0x2,%eax
  10400a:	89 c2                	mov    %eax,%edx
  10400c:	8b 45 08             	mov    0x8(%ebp),%eax
  10400f:	01 d0                	add    %edx,%eax
  104011:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104014:	75 5d                	jne    104073 <default_free_pages+0x1c0>
            base->property += p->property;
  104016:	8b 45 08             	mov    0x8(%ebp),%eax
  104019:	8b 50 08             	mov    0x8(%eax),%edx
  10401c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10401f:	8b 40 08             	mov    0x8(%eax),%eax
  104022:	01 c2                	add    %eax,%edx
  104024:	8b 45 08             	mov    0x8(%ebp),%eax
  104027:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(p);
  10402a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10402d:	83 c0 04             	add    $0x4,%eax
  104030:	c7 45 c4 01 00 00 00 	movl   $0x1,-0x3c(%ebp)
  104037:	89 45 c0             	mov    %eax,-0x40(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  10403a:	8b 45 c0             	mov    -0x40(%ebp),%eax
  10403d:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  104040:	0f b3 10             	btr    %edx,(%eax)
            list_del(&(p->page_link));
  104043:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104046:	83 c0 0c             	add    $0xc,%eax
  104049:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
  10404c:	8b 45 bc             	mov    -0x44(%ebp),%eax
  10404f:	8b 40 04             	mov    0x4(%eax),%eax
  104052:	8b 55 bc             	mov    -0x44(%ebp),%edx
  104055:	8b 12                	mov    (%edx),%edx
  104057:	89 55 b8             	mov    %edx,-0x48(%ebp)
  10405a:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
  10405d:	8b 45 b8             	mov    -0x48(%ebp),%eax
  104060:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  104063:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
  104066:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  104069:	8b 55 b8             	mov    -0x48(%ebp),%edx
  10406c:	89 10                	mov    %edx,(%eax)
            break;
  10406e:	e9 87 00 00 00       	jmp    1040fa <default_free_pages+0x247>
        }
        else if (p + p->property == base) {
  104073:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104076:	8b 50 08             	mov    0x8(%eax),%edx
  104079:	89 d0                	mov    %edx,%eax
  10407b:	c1 e0 02             	shl    $0x2,%eax
  10407e:	01 d0                	add    %edx,%eax
  104080:	c1 e0 02             	shl    $0x2,%eax
  104083:	89 c2                	mov    %eax,%edx
  104085:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104088:	01 d0                	add    %edx,%eax
  10408a:	3b 45 08             	cmp    0x8(%ebp),%eax
  10408d:	75 5e                	jne    1040ed <default_free_pages+0x23a>
            p->property += base->property;
  10408f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104092:	8b 50 08             	mov    0x8(%eax),%edx
  104095:	8b 45 08             	mov    0x8(%ebp),%eax
  104098:	8b 40 08             	mov    0x8(%eax),%eax
  10409b:	01 c2                	add    %eax,%edx
  10409d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1040a0:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(base);
  1040a3:	8b 45 08             	mov    0x8(%ebp),%eax
  1040a6:	83 c0 04             	add    $0x4,%eax
  1040a9:	c7 45 b0 01 00 00 00 	movl   $0x1,-0x50(%ebp)
  1040b0:	89 45 ac             	mov    %eax,-0x54(%ebp)
  1040b3:	8b 45 ac             	mov    -0x54(%ebp),%eax
  1040b6:	8b 55 b0             	mov    -0x50(%ebp),%edx
  1040b9:	0f b3 10             	btr    %edx,(%eax)
            list_del(&(p->page_link));
  1040bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1040bf:	83 c0 0c             	add    $0xc,%eax
  1040c2:	89 45 a8             	mov    %eax,-0x58(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
  1040c5:	8b 45 a8             	mov    -0x58(%ebp),%eax
  1040c8:	8b 40 04             	mov    0x4(%eax),%eax
  1040cb:	8b 55 a8             	mov    -0x58(%ebp),%edx
  1040ce:	8b 12                	mov    (%edx),%edx
  1040d0:	89 55 a4             	mov    %edx,-0x5c(%ebp)
  1040d3:	89 45 a0             	mov    %eax,-0x60(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
  1040d6:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  1040d9:	8b 55 a0             	mov    -0x60(%ebp),%edx
  1040dc:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
  1040df:	8b 45 a0             	mov    -0x60(%ebp),%eax
  1040e2:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  1040e5:	89 10                	mov    %edx,(%eax)
            base = p;
  1040e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1040ea:	89 45 08             	mov    %eax,0x8(%ebp)
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    list_entry_t *le = list_next(&free_list);
    while (le != &free_list) {
  1040ed:	81 7d f0 40 57 12 00 	cmpl   $0x125740,-0x10(%ebp)
  1040f4:	0f 85 e8 fe ff ff    	jne    103fe2 <default_free_pages+0x12f>
  1040fa:	c7 45 9c 40 57 12 00 	movl   $0x125740,-0x64(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  104101:	8b 45 9c             	mov    -0x64(%ebp),%eax
  104104:	8b 40 04             	mov    0x4(%eax),%eax
            ClearPageProperty(base);
            list_del(&(p->page_link));
            base = p;
        }
    }
    le = list_next(&free_list);
  104107:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
  10410a:	eb 22                	jmp    10412e <default_free_pages+0x27b>
        p = le2page(le, page_link);
  10410c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10410f:	83 e8 0c             	sub    $0xc,%eax
  104112:	89 45 f4             	mov    %eax,-0xc(%ebp)
        if (base < p) {
  104115:	8b 45 08             	mov    0x8(%ebp),%eax
  104118:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  10411b:	73 02                	jae    10411f <default_free_pages+0x26c>
            break;
  10411d:	eb 18                	jmp    104137 <default_free_pages+0x284>
  10411f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104122:	89 45 98             	mov    %eax,-0x68(%ebp)
  104125:	8b 45 98             	mov    -0x68(%ebp),%eax
  104128:	8b 40 04             	mov    0x4(%eax),%eax
        }
        le = list_next(le);
  10412b:	89 45 f0             	mov    %eax,-0x10(%ebp)
            list_del(&(p->page_link));
            base = p;
        }
    }
    le = list_next(&free_list);
    while (le != &free_list) {
  10412e:	81 7d f0 40 57 12 00 	cmpl   $0x125740,-0x10(%ebp)
  104135:	75 d5                	jne    10410c <default_free_pages+0x259>
        if (base < p) {
            break;
        }
        le = list_next(le);
    }
    nr_free += n;
  104137:	8b 15 48 57 12 00    	mov    0x125748,%edx
  10413d:	8b 45 0c             	mov    0xc(%ebp),%eax
  104140:	01 d0                	add    %edx,%eax
  104142:	a3 48 57 12 00       	mov    %eax,0x125748
    list_add_before(le, &(base->page_link));
  104147:	8b 45 08             	mov    0x8(%ebp),%eax
  10414a:	8d 50 0c             	lea    0xc(%eax),%edx
  10414d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104150:	89 45 94             	mov    %eax,-0x6c(%ebp)
  104153:	89 55 90             	mov    %edx,-0x70(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
  104156:	8b 45 94             	mov    -0x6c(%ebp),%eax
  104159:	8b 00                	mov    (%eax),%eax
  10415b:	8b 55 90             	mov    -0x70(%ebp),%edx
  10415e:	89 55 8c             	mov    %edx,-0x74(%ebp)
  104161:	89 45 88             	mov    %eax,-0x78(%ebp)
  104164:	8b 45 94             	mov    -0x6c(%ebp),%eax
  104167:	89 45 84             	mov    %eax,-0x7c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  10416a:	8b 45 84             	mov    -0x7c(%ebp),%eax
  10416d:	8b 55 8c             	mov    -0x74(%ebp),%edx
  104170:	89 10                	mov    %edx,(%eax)
  104172:	8b 45 84             	mov    -0x7c(%ebp),%eax
  104175:	8b 10                	mov    (%eax),%edx
  104177:	8b 45 88             	mov    -0x78(%ebp),%eax
  10417a:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  10417d:	8b 45 8c             	mov    -0x74(%ebp),%eax
  104180:	8b 55 84             	mov    -0x7c(%ebp),%edx
  104183:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  104186:	8b 45 8c             	mov    -0x74(%ebp),%eax
  104189:	8b 55 88             	mov    -0x78(%ebp),%edx
  10418c:	89 10                	mov    %edx,(%eax)
}
  10418e:	c9                   	leave  
  10418f:	c3                   	ret    

00104190 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void) {
  104190:	55                   	push   %ebp
  104191:	89 e5                	mov    %esp,%ebp
    return nr_free;
  104193:	a1 48 57 12 00       	mov    0x125748,%eax
}
  104198:	5d                   	pop    %ebp
  104199:	c3                   	ret    

0010419a <basic_check>:

static void
basic_check(void) {
  10419a:	55                   	push   %ebp
  10419b:	89 e5                	mov    %esp,%ebp
  10419d:	83 ec 48             	sub    $0x48,%esp
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
  1041a0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1041a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1041aa:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1041ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1041b0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    assert((p0 = alloc_page()) != NULL);
  1041b3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1041ba:	e8 db 0e 00 00       	call   10509a <alloc_pages>
  1041bf:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1041c2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1041c6:	75 24                	jne    1041ec <basic_check+0x52>
  1041c8:	c7 44 24 0c 61 7e 10 	movl   $0x107e61,0xc(%esp)
  1041cf:	00 
  1041d0:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  1041d7:	00 
  1041d8:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  1041df:	00 
  1041e0:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  1041e7:	e8 f2 ca ff ff       	call   100cde <__panic>
    assert((p1 = alloc_page()) != NULL);
  1041ec:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1041f3:	e8 a2 0e 00 00       	call   10509a <alloc_pages>
  1041f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1041fb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1041ff:	75 24                	jne    104225 <basic_check+0x8b>
  104201:	c7 44 24 0c 7d 7e 10 	movl   $0x107e7d,0xc(%esp)
  104208:	00 
  104209:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104210:	00 
  104211:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
  104218:	00 
  104219:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104220:	e8 b9 ca ff ff       	call   100cde <__panic>
    assert((p2 = alloc_page()) != NULL);
  104225:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10422c:	e8 69 0e 00 00       	call   10509a <alloc_pages>
  104231:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104234:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  104238:	75 24                	jne    10425e <basic_check+0xc4>
  10423a:	c7 44 24 0c 99 7e 10 	movl   $0x107e99,0xc(%esp)
  104241:	00 
  104242:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104249:	00 
  10424a:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
  104251:	00 
  104252:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104259:	e8 80 ca ff ff       	call   100cde <__panic>

    assert(p0 != p1 && p0 != p2 && p1 != p2);
  10425e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104261:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104264:	74 10                	je     104276 <basic_check+0xdc>
  104266:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104269:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  10426c:	74 08                	je     104276 <basic_check+0xdc>
  10426e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104271:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104274:	75 24                	jne    10429a <basic_check+0x100>
  104276:	c7 44 24 0c b8 7e 10 	movl   $0x107eb8,0xc(%esp)
  10427d:	00 
  10427e:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104285:	00 
  104286:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  10428d:	00 
  10428e:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104295:	e8 44 ca ff ff       	call   100cde <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
  10429a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10429d:	89 04 24             	mov    %eax,(%esp)
  1042a0:	e8 d0 f8 ff ff       	call   103b75 <page_ref>
  1042a5:	85 c0                	test   %eax,%eax
  1042a7:	75 1e                	jne    1042c7 <basic_check+0x12d>
  1042a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042ac:	89 04 24             	mov    %eax,(%esp)
  1042af:	e8 c1 f8 ff ff       	call   103b75 <page_ref>
  1042b4:	85 c0                	test   %eax,%eax
  1042b6:	75 0f                	jne    1042c7 <basic_check+0x12d>
  1042b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1042bb:	89 04 24             	mov    %eax,(%esp)
  1042be:	e8 b2 f8 ff ff       	call   103b75 <page_ref>
  1042c3:	85 c0                	test   %eax,%eax
  1042c5:	74 24                	je     1042eb <basic_check+0x151>
  1042c7:	c7 44 24 0c dc 7e 10 	movl   $0x107edc,0xc(%esp)
  1042ce:	00 
  1042cf:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  1042d6:	00 
  1042d7:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  1042de:	00 
  1042df:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  1042e6:	e8 f3 c9 ff ff       	call   100cde <__panic>

    assert(page2pa(p0) < npage * PGSIZE);
  1042eb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1042ee:	89 04 24             	mov    %eax,(%esp)
  1042f1:	e8 69 f8 ff ff       	call   103b5f <page2pa>
  1042f6:	8b 15 a0 56 12 00    	mov    0x1256a0,%edx
  1042fc:	c1 e2 0c             	shl    $0xc,%edx
  1042ff:	39 d0                	cmp    %edx,%eax
  104301:	72 24                	jb     104327 <basic_check+0x18d>
  104303:	c7 44 24 0c 18 7f 10 	movl   $0x107f18,0xc(%esp)
  10430a:	00 
  10430b:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104312:	00 
  104313:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  10431a:	00 
  10431b:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104322:	e8 b7 c9 ff ff       	call   100cde <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
  104327:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10432a:	89 04 24             	mov    %eax,(%esp)
  10432d:	e8 2d f8 ff ff       	call   103b5f <page2pa>
  104332:	8b 15 a0 56 12 00    	mov    0x1256a0,%edx
  104338:	c1 e2 0c             	shl    $0xc,%edx
  10433b:	39 d0                	cmp    %edx,%eax
  10433d:	72 24                	jb     104363 <basic_check+0x1c9>
  10433f:	c7 44 24 0c 35 7f 10 	movl   $0x107f35,0xc(%esp)
  104346:	00 
  104347:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  10434e:	00 
  10434f:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  104356:	00 
  104357:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  10435e:	e8 7b c9 ff ff       	call   100cde <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
  104363:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104366:	89 04 24             	mov    %eax,(%esp)
  104369:	e8 f1 f7 ff ff       	call   103b5f <page2pa>
  10436e:	8b 15 a0 56 12 00    	mov    0x1256a0,%edx
  104374:	c1 e2 0c             	shl    $0xc,%edx
  104377:	39 d0                	cmp    %edx,%eax
  104379:	72 24                	jb     10439f <basic_check+0x205>
  10437b:	c7 44 24 0c 52 7f 10 	movl   $0x107f52,0xc(%esp)
  104382:	00 
  104383:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  10438a:	00 
  10438b:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
  104392:	00 
  104393:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  10439a:	e8 3f c9 ff ff       	call   100cde <__panic>

    list_entry_t free_list_store = free_list;
  10439f:	a1 40 57 12 00       	mov    0x125740,%eax
  1043a4:	8b 15 44 57 12 00    	mov    0x125744,%edx
  1043aa:	89 45 d0             	mov    %eax,-0x30(%ebp)
  1043ad:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  1043b0:	c7 45 e0 40 57 12 00 	movl   $0x125740,-0x20(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
  1043b7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1043ba:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1043bd:	89 50 04             	mov    %edx,0x4(%eax)
  1043c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1043c3:	8b 50 04             	mov    0x4(%eax),%edx
  1043c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1043c9:	89 10                	mov    %edx,(%eax)
  1043cb:	c7 45 dc 40 57 12 00 	movl   $0x125740,-0x24(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
  1043d2:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1043d5:	8b 40 04             	mov    0x4(%eax),%eax
  1043d8:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  1043db:	0f 94 c0             	sete   %al
  1043de:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
  1043e1:	85 c0                	test   %eax,%eax
  1043e3:	75 24                	jne    104409 <basic_check+0x26f>
  1043e5:	c7 44 24 0c 6f 7f 10 	movl   $0x107f6f,0xc(%esp)
  1043ec:	00 
  1043ed:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  1043f4:	00 
  1043f5:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
  1043fc:	00 
  1043fd:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104404:	e8 d5 c8 ff ff       	call   100cde <__panic>

    unsigned int nr_free_store = nr_free;
  104409:	a1 48 57 12 00       	mov    0x125748,%eax
  10440e:	89 45 e8             	mov    %eax,-0x18(%ebp)
    nr_free = 0;
  104411:	c7 05 48 57 12 00 00 	movl   $0x0,0x125748
  104418:	00 00 00 

    assert(alloc_page() == NULL);
  10441b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104422:	e8 73 0c 00 00       	call   10509a <alloc_pages>
  104427:	85 c0                	test   %eax,%eax
  104429:	74 24                	je     10444f <basic_check+0x2b5>
  10442b:	c7 44 24 0c 86 7f 10 	movl   $0x107f86,0xc(%esp)
  104432:	00 
  104433:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  10443a:	00 
  10443b:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  104442:	00 
  104443:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  10444a:	e8 8f c8 ff ff       	call   100cde <__panic>

    free_page(p0);
  10444f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104456:	00 
  104457:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10445a:	89 04 24             	mov    %eax,(%esp)
  10445d:	e8 70 0c 00 00       	call   1050d2 <free_pages>
    free_page(p1);
  104462:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104469:	00 
  10446a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10446d:	89 04 24             	mov    %eax,(%esp)
  104470:	e8 5d 0c 00 00       	call   1050d2 <free_pages>
    free_page(p2);
  104475:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10447c:	00 
  10447d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104480:	89 04 24             	mov    %eax,(%esp)
  104483:	e8 4a 0c 00 00       	call   1050d2 <free_pages>
    assert(nr_free == 3);
  104488:	a1 48 57 12 00       	mov    0x125748,%eax
  10448d:	83 f8 03             	cmp    $0x3,%eax
  104490:	74 24                	je     1044b6 <basic_check+0x31c>
  104492:	c7 44 24 0c 9b 7f 10 	movl   $0x107f9b,0xc(%esp)
  104499:	00 
  10449a:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  1044a1:	00 
  1044a2:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
  1044a9:	00 
  1044aa:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  1044b1:	e8 28 c8 ff ff       	call   100cde <__panic>

    assert((p0 = alloc_page()) != NULL);
  1044b6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1044bd:	e8 d8 0b 00 00       	call   10509a <alloc_pages>
  1044c2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1044c5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1044c9:	75 24                	jne    1044ef <basic_check+0x355>
  1044cb:	c7 44 24 0c 61 7e 10 	movl   $0x107e61,0xc(%esp)
  1044d2:	00 
  1044d3:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  1044da:	00 
  1044db:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  1044e2:	00 
  1044e3:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  1044ea:	e8 ef c7 ff ff       	call   100cde <__panic>
    assert((p1 = alloc_page()) != NULL);
  1044ef:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1044f6:	e8 9f 0b 00 00       	call   10509a <alloc_pages>
  1044fb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1044fe:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104502:	75 24                	jne    104528 <basic_check+0x38e>
  104504:	c7 44 24 0c 7d 7e 10 	movl   $0x107e7d,0xc(%esp)
  10450b:	00 
  10450c:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104513:	00 
  104514:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  10451b:	00 
  10451c:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104523:	e8 b6 c7 ff ff       	call   100cde <__panic>
    assert((p2 = alloc_page()) != NULL);
  104528:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10452f:	e8 66 0b 00 00       	call   10509a <alloc_pages>
  104534:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104537:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10453b:	75 24                	jne    104561 <basic_check+0x3c7>
  10453d:	c7 44 24 0c 99 7e 10 	movl   $0x107e99,0xc(%esp)
  104544:	00 
  104545:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  10454c:	00 
  10454d:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
  104554:	00 
  104555:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  10455c:	e8 7d c7 ff ff       	call   100cde <__panic>

    assert(alloc_page() == NULL);
  104561:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104568:	e8 2d 0b 00 00       	call   10509a <alloc_pages>
  10456d:	85 c0                	test   %eax,%eax
  10456f:	74 24                	je     104595 <basic_check+0x3fb>
  104571:	c7 44 24 0c 86 7f 10 	movl   $0x107f86,0xc(%esp)
  104578:	00 
  104579:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104580:	00 
  104581:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  104588:	00 
  104589:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104590:	e8 49 c7 ff ff       	call   100cde <__panic>

    free_page(p0);
  104595:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10459c:	00 
  10459d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1045a0:	89 04 24             	mov    %eax,(%esp)
  1045a3:	e8 2a 0b 00 00       	call   1050d2 <free_pages>
  1045a8:	c7 45 d8 40 57 12 00 	movl   $0x125740,-0x28(%ebp)
  1045af:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1045b2:	8b 40 04             	mov    0x4(%eax),%eax
  1045b5:	39 45 d8             	cmp    %eax,-0x28(%ebp)
  1045b8:	0f 94 c0             	sete   %al
  1045bb:	0f b6 c0             	movzbl %al,%eax
    assert(!list_empty(&free_list));
  1045be:	85 c0                	test   %eax,%eax
  1045c0:	74 24                	je     1045e6 <basic_check+0x44c>
  1045c2:	c7 44 24 0c a8 7f 10 	movl   $0x107fa8,0xc(%esp)
  1045c9:	00 
  1045ca:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  1045d1:	00 
  1045d2:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
  1045d9:	00 
  1045da:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  1045e1:	e8 f8 c6 ff ff       	call   100cde <__panic>

    struct Page *p;
    assert((p = alloc_page()) == p0);
  1045e6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1045ed:	e8 a8 0a 00 00       	call   10509a <alloc_pages>
  1045f2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1045f5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1045f8:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1045fb:	74 24                	je     104621 <basic_check+0x487>
  1045fd:	c7 44 24 0c c0 7f 10 	movl   $0x107fc0,0xc(%esp)
  104604:	00 
  104605:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  10460c:	00 
  10460d:	c7 44 24 04 ed 00 00 	movl   $0xed,0x4(%esp)
  104614:	00 
  104615:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  10461c:	e8 bd c6 ff ff       	call   100cde <__panic>
    assert(alloc_page() == NULL);
  104621:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104628:	e8 6d 0a 00 00       	call   10509a <alloc_pages>
  10462d:	85 c0                	test   %eax,%eax
  10462f:	74 24                	je     104655 <basic_check+0x4bb>
  104631:	c7 44 24 0c 86 7f 10 	movl   $0x107f86,0xc(%esp)
  104638:	00 
  104639:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104640:	00 
  104641:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
  104648:	00 
  104649:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104650:	e8 89 c6 ff ff       	call   100cde <__panic>

    assert(nr_free == 0);
  104655:	a1 48 57 12 00       	mov    0x125748,%eax
  10465a:	85 c0                	test   %eax,%eax
  10465c:	74 24                	je     104682 <basic_check+0x4e8>
  10465e:	c7 44 24 0c d9 7f 10 	movl   $0x107fd9,0xc(%esp)
  104665:	00 
  104666:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  10466d:	00 
  10466e:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
  104675:	00 
  104676:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  10467d:	e8 5c c6 ff ff       	call   100cde <__panic>
    free_list = free_list_store;
  104682:	8b 45 d0             	mov    -0x30(%ebp),%eax
  104685:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  104688:	a3 40 57 12 00       	mov    %eax,0x125740
  10468d:	89 15 44 57 12 00    	mov    %edx,0x125744
    nr_free = nr_free_store;
  104693:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104696:	a3 48 57 12 00       	mov    %eax,0x125748

    free_page(p);
  10469b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1046a2:	00 
  1046a3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1046a6:	89 04 24             	mov    %eax,(%esp)
  1046a9:	e8 24 0a 00 00       	call   1050d2 <free_pages>
    free_page(p1);
  1046ae:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1046b5:	00 
  1046b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1046b9:	89 04 24             	mov    %eax,(%esp)
  1046bc:	e8 11 0a 00 00       	call   1050d2 <free_pages>
    free_page(p2);
  1046c1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1046c8:	00 
  1046c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1046cc:	89 04 24             	mov    %eax,(%esp)
  1046cf:	e8 fe 09 00 00       	call   1050d2 <free_pages>
}
  1046d4:	c9                   	leave  
  1046d5:	c3                   	ret    

001046d6 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
  1046d6:	55                   	push   %ebp
  1046d7:	89 e5                	mov    %esp,%ebp
  1046d9:	53                   	push   %ebx
  1046da:	81 ec 94 00 00 00    	sub    $0x94,%esp
    int count = 0, total = 0;
  1046e0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1046e7:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    list_entry_t *le = &free_list;
  1046ee:	c7 45 ec 40 57 12 00 	movl   $0x125740,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
  1046f5:	eb 6b                	jmp    104762 <default_check+0x8c>
        struct Page *p = le2page(le, page_link);
  1046f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1046fa:	83 e8 0c             	sub    $0xc,%eax
  1046fd:	89 45 e8             	mov    %eax,-0x18(%ebp)
        assert(PageProperty(p));
  104700:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104703:	83 c0 04             	add    $0x4,%eax
  104706:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  10470d:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104710:	8b 45 cc             	mov    -0x34(%ebp),%eax
  104713:	8b 55 d0             	mov    -0x30(%ebp),%edx
  104716:	0f a3 10             	bt     %edx,(%eax)
  104719:	19 c0                	sbb    %eax,%eax
  10471b:	89 45 c8             	mov    %eax,-0x38(%ebp)
    return oldbit != 0;
  10471e:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
  104722:	0f 95 c0             	setne  %al
  104725:	0f b6 c0             	movzbl %al,%eax
  104728:	85 c0                	test   %eax,%eax
  10472a:	75 24                	jne    104750 <default_check+0x7a>
  10472c:	c7 44 24 0c e6 7f 10 	movl   $0x107fe6,0xc(%esp)
  104733:	00 
  104734:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  10473b:	00 
  10473c:	c7 44 24 04 01 01 00 	movl   $0x101,0x4(%esp)
  104743:	00 
  104744:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  10474b:	e8 8e c5 ff ff       	call   100cde <__panic>
        count ++, total += p->property;
  104750:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  104754:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104757:	8b 50 08             	mov    0x8(%eax),%edx
  10475a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10475d:	01 d0                	add    %edx,%eax
  10475f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104762:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104765:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  104768:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  10476b:	8b 40 04             	mov    0x4(%eax),%eax
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
  10476e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  104771:	81 7d ec 40 57 12 00 	cmpl   $0x125740,-0x14(%ebp)
  104778:	0f 85 79 ff ff ff    	jne    1046f7 <default_check+0x21>
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());
  10477e:	8b 5d f0             	mov    -0x10(%ebp),%ebx
  104781:	e8 7e 09 00 00       	call   105104 <nr_free_pages>
  104786:	39 c3                	cmp    %eax,%ebx
  104788:	74 24                	je     1047ae <default_check+0xd8>
  10478a:	c7 44 24 0c f6 7f 10 	movl   $0x107ff6,0xc(%esp)
  104791:	00 
  104792:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104799:	00 
  10479a:	c7 44 24 04 04 01 00 	movl   $0x104,0x4(%esp)
  1047a1:	00 
  1047a2:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  1047a9:	e8 30 c5 ff ff       	call   100cde <__panic>

    basic_check();
  1047ae:	e8 e7 f9 ff ff       	call   10419a <basic_check>

    struct Page *p0 = alloc_pages(5), *p1, *p2;
  1047b3:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
  1047ba:	e8 db 08 00 00       	call   10509a <alloc_pages>
  1047bf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(p0 != NULL);
  1047c2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  1047c6:	75 24                	jne    1047ec <default_check+0x116>
  1047c8:	c7 44 24 0c 0f 80 10 	movl   $0x10800f,0xc(%esp)
  1047cf:	00 
  1047d0:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  1047d7:	00 
  1047d8:	c7 44 24 04 09 01 00 	movl   $0x109,0x4(%esp)
  1047df:	00 
  1047e0:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  1047e7:	e8 f2 c4 ff ff       	call   100cde <__panic>
    assert(!PageProperty(p0));
  1047ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1047ef:	83 c0 04             	add    $0x4,%eax
  1047f2:	c7 45 c0 01 00 00 00 	movl   $0x1,-0x40(%ebp)
  1047f9:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  1047fc:	8b 45 bc             	mov    -0x44(%ebp),%eax
  1047ff:	8b 55 c0             	mov    -0x40(%ebp),%edx
  104802:	0f a3 10             	bt     %edx,(%eax)
  104805:	19 c0                	sbb    %eax,%eax
  104807:	89 45 b8             	mov    %eax,-0x48(%ebp)
    return oldbit != 0;
  10480a:	83 7d b8 00          	cmpl   $0x0,-0x48(%ebp)
  10480e:	0f 95 c0             	setne  %al
  104811:	0f b6 c0             	movzbl %al,%eax
  104814:	85 c0                	test   %eax,%eax
  104816:	74 24                	je     10483c <default_check+0x166>
  104818:	c7 44 24 0c 1a 80 10 	movl   $0x10801a,0xc(%esp)
  10481f:	00 
  104820:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104827:	00 
  104828:	c7 44 24 04 0a 01 00 	movl   $0x10a,0x4(%esp)
  10482f:	00 
  104830:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104837:	e8 a2 c4 ff ff       	call   100cde <__panic>

    list_entry_t free_list_store = free_list;
  10483c:	a1 40 57 12 00       	mov    0x125740,%eax
  104841:	8b 15 44 57 12 00    	mov    0x125744,%edx
  104847:	89 45 80             	mov    %eax,-0x80(%ebp)
  10484a:	89 55 84             	mov    %edx,-0x7c(%ebp)
  10484d:	c7 45 b4 40 57 12 00 	movl   $0x125740,-0x4c(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
  104854:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  104857:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  10485a:	89 50 04             	mov    %edx,0x4(%eax)
  10485d:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  104860:	8b 50 04             	mov    0x4(%eax),%edx
  104863:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  104866:	89 10                	mov    %edx,(%eax)
  104868:	c7 45 b0 40 57 12 00 	movl   $0x125740,-0x50(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
  10486f:	8b 45 b0             	mov    -0x50(%ebp),%eax
  104872:	8b 40 04             	mov    0x4(%eax),%eax
  104875:	39 45 b0             	cmp    %eax,-0x50(%ebp)
  104878:	0f 94 c0             	sete   %al
  10487b:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
  10487e:	85 c0                	test   %eax,%eax
  104880:	75 24                	jne    1048a6 <default_check+0x1d0>
  104882:	c7 44 24 0c 6f 7f 10 	movl   $0x107f6f,0xc(%esp)
  104889:	00 
  10488a:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104891:	00 
  104892:	c7 44 24 04 0e 01 00 	movl   $0x10e,0x4(%esp)
  104899:	00 
  10489a:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  1048a1:	e8 38 c4 ff ff       	call   100cde <__panic>
    assert(alloc_page() == NULL);
  1048a6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1048ad:	e8 e8 07 00 00       	call   10509a <alloc_pages>
  1048b2:	85 c0                	test   %eax,%eax
  1048b4:	74 24                	je     1048da <default_check+0x204>
  1048b6:	c7 44 24 0c 86 7f 10 	movl   $0x107f86,0xc(%esp)
  1048bd:	00 
  1048be:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  1048c5:	00 
  1048c6:	c7 44 24 04 0f 01 00 	movl   $0x10f,0x4(%esp)
  1048cd:	00 
  1048ce:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  1048d5:	e8 04 c4 ff ff       	call   100cde <__panic>

    unsigned int nr_free_store = nr_free;
  1048da:	a1 48 57 12 00       	mov    0x125748,%eax
  1048df:	89 45 e0             	mov    %eax,-0x20(%ebp)
    nr_free = 0;
  1048e2:	c7 05 48 57 12 00 00 	movl   $0x0,0x125748
  1048e9:	00 00 00 

    free_pages(p0 + 2, 3);
  1048ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1048ef:	83 c0 28             	add    $0x28,%eax
  1048f2:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
  1048f9:	00 
  1048fa:	89 04 24             	mov    %eax,(%esp)
  1048fd:	e8 d0 07 00 00       	call   1050d2 <free_pages>
    assert(alloc_pages(4) == NULL);
  104902:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  104909:	e8 8c 07 00 00       	call   10509a <alloc_pages>
  10490e:	85 c0                	test   %eax,%eax
  104910:	74 24                	je     104936 <default_check+0x260>
  104912:	c7 44 24 0c 2c 80 10 	movl   $0x10802c,0xc(%esp)
  104919:	00 
  10491a:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104921:	00 
  104922:	c7 44 24 04 15 01 00 	movl   $0x115,0x4(%esp)
  104929:	00 
  10492a:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104931:	e8 a8 c3 ff ff       	call   100cde <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
  104936:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104939:	83 c0 28             	add    $0x28,%eax
  10493c:	83 c0 04             	add    $0x4,%eax
  10493f:	c7 45 ac 01 00 00 00 	movl   $0x1,-0x54(%ebp)
  104946:	89 45 a8             	mov    %eax,-0x58(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104949:	8b 45 a8             	mov    -0x58(%ebp),%eax
  10494c:	8b 55 ac             	mov    -0x54(%ebp),%edx
  10494f:	0f a3 10             	bt     %edx,(%eax)
  104952:	19 c0                	sbb    %eax,%eax
  104954:	89 45 a4             	mov    %eax,-0x5c(%ebp)
    return oldbit != 0;
  104957:	83 7d a4 00          	cmpl   $0x0,-0x5c(%ebp)
  10495b:	0f 95 c0             	setne  %al
  10495e:	0f b6 c0             	movzbl %al,%eax
  104961:	85 c0                	test   %eax,%eax
  104963:	74 0e                	je     104973 <default_check+0x29d>
  104965:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104968:	83 c0 28             	add    $0x28,%eax
  10496b:	8b 40 08             	mov    0x8(%eax),%eax
  10496e:	83 f8 03             	cmp    $0x3,%eax
  104971:	74 24                	je     104997 <default_check+0x2c1>
  104973:	c7 44 24 0c 44 80 10 	movl   $0x108044,0xc(%esp)
  10497a:	00 
  10497b:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104982:	00 
  104983:	c7 44 24 04 16 01 00 	movl   $0x116,0x4(%esp)
  10498a:	00 
  10498b:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104992:	e8 47 c3 ff ff       	call   100cde <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
  104997:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
  10499e:	e8 f7 06 00 00       	call   10509a <alloc_pages>
  1049a3:	89 45 dc             	mov    %eax,-0x24(%ebp)
  1049a6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  1049aa:	75 24                	jne    1049d0 <default_check+0x2fa>
  1049ac:	c7 44 24 0c 70 80 10 	movl   $0x108070,0xc(%esp)
  1049b3:	00 
  1049b4:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  1049bb:	00 
  1049bc:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
  1049c3:	00 
  1049c4:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  1049cb:	e8 0e c3 ff ff       	call   100cde <__panic>
    assert(alloc_page() == NULL);
  1049d0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1049d7:	e8 be 06 00 00       	call   10509a <alloc_pages>
  1049dc:	85 c0                	test   %eax,%eax
  1049de:	74 24                	je     104a04 <default_check+0x32e>
  1049e0:	c7 44 24 0c 86 7f 10 	movl   $0x107f86,0xc(%esp)
  1049e7:	00 
  1049e8:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  1049ef:	00 
  1049f0:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
  1049f7:	00 
  1049f8:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  1049ff:	e8 da c2 ff ff       	call   100cde <__panic>
    assert(p0 + 2 == p1);
  104a04:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104a07:	83 c0 28             	add    $0x28,%eax
  104a0a:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  104a0d:	74 24                	je     104a33 <default_check+0x35d>
  104a0f:	c7 44 24 0c 8e 80 10 	movl   $0x10808e,0xc(%esp)
  104a16:	00 
  104a17:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104a1e:	00 
  104a1f:	c7 44 24 04 19 01 00 	movl   $0x119,0x4(%esp)
  104a26:	00 
  104a27:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104a2e:	e8 ab c2 ff ff       	call   100cde <__panic>

    p2 = p0 + 1;
  104a33:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104a36:	83 c0 14             	add    $0x14,%eax
  104a39:	89 45 d8             	mov    %eax,-0x28(%ebp)
    free_page(p0);
  104a3c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104a43:	00 
  104a44:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104a47:	89 04 24             	mov    %eax,(%esp)
  104a4a:	e8 83 06 00 00       	call   1050d2 <free_pages>
    free_pages(p1, 3);
  104a4f:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
  104a56:	00 
  104a57:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104a5a:	89 04 24             	mov    %eax,(%esp)
  104a5d:	e8 70 06 00 00       	call   1050d2 <free_pages>
    assert(PageProperty(p0) && p0->property == 1);
  104a62:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104a65:	83 c0 04             	add    $0x4,%eax
  104a68:	c7 45 a0 01 00 00 00 	movl   $0x1,-0x60(%ebp)
  104a6f:	89 45 9c             	mov    %eax,-0x64(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104a72:	8b 45 9c             	mov    -0x64(%ebp),%eax
  104a75:	8b 55 a0             	mov    -0x60(%ebp),%edx
  104a78:	0f a3 10             	bt     %edx,(%eax)
  104a7b:	19 c0                	sbb    %eax,%eax
  104a7d:	89 45 98             	mov    %eax,-0x68(%ebp)
    return oldbit != 0;
  104a80:	83 7d 98 00          	cmpl   $0x0,-0x68(%ebp)
  104a84:	0f 95 c0             	setne  %al
  104a87:	0f b6 c0             	movzbl %al,%eax
  104a8a:	85 c0                	test   %eax,%eax
  104a8c:	74 0b                	je     104a99 <default_check+0x3c3>
  104a8e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104a91:	8b 40 08             	mov    0x8(%eax),%eax
  104a94:	83 f8 01             	cmp    $0x1,%eax
  104a97:	74 24                	je     104abd <default_check+0x3e7>
  104a99:	c7 44 24 0c 9c 80 10 	movl   $0x10809c,0xc(%esp)
  104aa0:	00 
  104aa1:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104aa8:	00 
  104aa9:	c7 44 24 04 1e 01 00 	movl   $0x11e,0x4(%esp)
  104ab0:	00 
  104ab1:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104ab8:	e8 21 c2 ff ff       	call   100cde <__panic>
    assert(PageProperty(p1) && p1->property == 3);
  104abd:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104ac0:	83 c0 04             	add    $0x4,%eax
  104ac3:	c7 45 94 01 00 00 00 	movl   $0x1,-0x6c(%ebp)
  104aca:	89 45 90             	mov    %eax,-0x70(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104acd:	8b 45 90             	mov    -0x70(%ebp),%eax
  104ad0:	8b 55 94             	mov    -0x6c(%ebp),%edx
  104ad3:	0f a3 10             	bt     %edx,(%eax)
  104ad6:	19 c0                	sbb    %eax,%eax
  104ad8:	89 45 8c             	mov    %eax,-0x74(%ebp)
    return oldbit != 0;
  104adb:	83 7d 8c 00          	cmpl   $0x0,-0x74(%ebp)
  104adf:	0f 95 c0             	setne  %al
  104ae2:	0f b6 c0             	movzbl %al,%eax
  104ae5:	85 c0                	test   %eax,%eax
  104ae7:	74 0b                	je     104af4 <default_check+0x41e>
  104ae9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104aec:	8b 40 08             	mov    0x8(%eax),%eax
  104aef:	83 f8 03             	cmp    $0x3,%eax
  104af2:	74 24                	je     104b18 <default_check+0x442>
  104af4:	c7 44 24 0c c4 80 10 	movl   $0x1080c4,0xc(%esp)
  104afb:	00 
  104afc:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104b03:	00 
  104b04:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
  104b0b:	00 
  104b0c:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104b13:	e8 c6 c1 ff ff       	call   100cde <__panic>

    assert((p0 = alloc_page()) == p2 - 1);
  104b18:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104b1f:	e8 76 05 00 00       	call   10509a <alloc_pages>
  104b24:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  104b27:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104b2a:	83 e8 14             	sub    $0x14,%eax
  104b2d:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
  104b30:	74 24                	je     104b56 <default_check+0x480>
  104b32:	c7 44 24 0c ea 80 10 	movl   $0x1080ea,0xc(%esp)
  104b39:	00 
  104b3a:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104b41:	00 
  104b42:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
  104b49:	00 
  104b4a:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104b51:	e8 88 c1 ff ff       	call   100cde <__panic>
    free_page(p0);
  104b56:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104b5d:	00 
  104b5e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104b61:	89 04 24             	mov    %eax,(%esp)
  104b64:	e8 69 05 00 00       	call   1050d2 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
  104b69:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  104b70:	e8 25 05 00 00       	call   10509a <alloc_pages>
  104b75:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  104b78:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104b7b:	83 c0 14             	add    $0x14,%eax
  104b7e:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
  104b81:	74 24                	je     104ba7 <default_check+0x4d1>
  104b83:	c7 44 24 0c 08 81 10 	movl   $0x108108,0xc(%esp)
  104b8a:	00 
  104b8b:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104b92:	00 
  104b93:	c7 44 24 04 23 01 00 	movl   $0x123,0x4(%esp)
  104b9a:	00 
  104b9b:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104ba2:	e8 37 c1 ff ff       	call   100cde <__panic>

    free_pages(p0, 2);
  104ba7:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  104bae:	00 
  104baf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104bb2:	89 04 24             	mov    %eax,(%esp)
  104bb5:	e8 18 05 00 00       	call   1050d2 <free_pages>
    free_page(p2);
  104bba:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104bc1:	00 
  104bc2:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104bc5:	89 04 24             	mov    %eax,(%esp)
  104bc8:	e8 05 05 00 00       	call   1050d2 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
  104bcd:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
  104bd4:	e8 c1 04 00 00       	call   10509a <alloc_pages>
  104bd9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  104bdc:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  104be0:	75 24                	jne    104c06 <default_check+0x530>
  104be2:	c7 44 24 0c 28 81 10 	movl   $0x108128,0xc(%esp)
  104be9:	00 
  104bea:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104bf1:	00 
  104bf2:	c7 44 24 04 28 01 00 	movl   $0x128,0x4(%esp)
  104bf9:	00 
  104bfa:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104c01:	e8 d8 c0 ff ff       	call   100cde <__panic>
    assert(alloc_page() == NULL);
  104c06:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104c0d:	e8 88 04 00 00       	call   10509a <alloc_pages>
  104c12:	85 c0                	test   %eax,%eax
  104c14:	74 24                	je     104c3a <default_check+0x564>
  104c16:	c7 44 24 0c 86 7f 10 	movl   $0x107f86,0xc(%esp)
  104c1d:	00 
  104c1e:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104c25:	00 
  104c26:	c7 44 24 04 29 01 00 	movl   $0x129,0x4(%esp)
  104c2d:	00 
  104c2e:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104c35:	e8 a4 c0 ff ff       	call   100cde <__panic>

    assert(nr_free == 0);
  104c3a:	a1 48 57 12 00       	mov    0x125748,%eax
  104c3f:	85 c0                	test   %eax,%eax
  104c41:	74 24                	je     104c67 <default_check+0x591>
  104c43:	c7 44 24 0c d9 7f 10 	movl   $0x107fd9,0xc(%esp)
  104c4a:	00 
  104c4b:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104c52:	00 
  104c53:	c7 44 24 04 2b 01 00 	movl   $0x12b,0x4(%esp)
  104c5a:	00 
  104c5b:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104c62:	e8 77 c0 ff ff       	call   100cde <__panic>
    nr_free = nr_free_store;
  104c67:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104c6a:	a3 48 57 12 00       	mov    %eax,0x125748

    free_list = free_list_store;
  104c6f:	8b 45 80             	mov    -0x80(%ebp),%eax
  104c72:	8b 55 84             	mov    -0x7c(%ebp),%edx
  104c75:	a3 40 57 12 00       	mov    %eax,0x125740
  104c7a:	89 15 44 57 12 00    	mov    %edx,0x125744
    free_pages(p0, 5);
  104c80:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
  104c87:	00 
  104c88:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104c8b:	89 04 24             	mov    %eax,(%esp)
  104c8e:	e8 3f 04 00 00       	call   1050d2 <free_pages>

    le = &free_list;
  104c93:	c7 45 ec 40 57 12 00 	movl   $0x125740,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
  104c9a:	eb 5b                	jmp    104cf7 <default_check+0x621>
        assert(le->next->prev == le && le->prev->next == le);
  104c9c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104c9f:	8b 40 04             	mov    0x4(%eax),%eax
  104ca2:	8b 00                	mov    (%eax),%eax
  104ca4:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  104ca7:	75 0d                	jne    104cb6 <default_check+0x5e0>
  104ca9:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104cac:	8b 00                	mov    (%eax),%eax
  104cae:	8b 40 04             	mov    0x4(%eax),%eax
  104cb1:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  104cb4:	74 24                	je     104cda <default_check+0x604>
  104cb6:	c7 44 24 0c 48 81 10 	movl   $0x108148,0xc(%esp)
  104cbd:	00 
  104cbe:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104cc5:	00 
  104cc6:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
  104ccd:	00 
  104cce:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104cd5:	e8 04 c0 ff ff       	call   100cde <__panic>
        struct Page *p = le2page(le, page_link);
  104cda:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104cdd:	83 e8 0c             	sub    $0xc,%eax
  104ce0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        count --, total -= p->property;
  104ce3:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
  104ce7:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104cea:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  104ced:	8b 40 08             	mov    0x8(%eax),%eax
  104cf0:	29 c2                	sub    %eax,%edx
  104cf2:	89 d0                	mov    %edx,%eax
  104cf4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104cf7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104cfa:	89 45 88             	mov    %eax,-0x78(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  104cfd:	8b 45 88             	mov    -0x78(%ebp),%eax
  104d00:	8b 40 04             	mov    0x4(%eax),%eax

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
  104d03:	89 45 ec             	mov    %eax,-0x14(%ebp)
  104d06:	81 7d ec 40 57 12 00 	cmpl   $0x125740,-0x14(%ebp)
  104d0d:	75 8d                	jne    104c9c <default_check+0x5c6>
        assert(le->next->prev == le && le->prev->next == le);
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
  104d0f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  104d13:	74 24                	je     104d39 <default_check+0x663>
  104d15:	c7 44 24 0c 75 81 10 	movl   $0x108175,0xc(%esp)
  104d1c:	00 
  104d1d:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104d24:	00 
  104d25:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
  104d2c:	00 
  104d2d:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104d34:	e8 a5 bf ff ff       	call   100cde <__panic>
    assert(total == 0);
  104d39:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104d3d:	74 24                	je     104d63 <default_check+0x68d>
  104d3f:	c7 44 24 0c 80 81 10 	movl   $0x108180,0xc(%esp)
  104d46:	00 
  104d47:	c7 44 24 08 ff 7d 10 	movl   $0x107dff,0x8(%esp)
  104d4e:	00 
  104d4f:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
  104d56:	00 
  104d57:	c7 04 24 14 7e 10 00 	movl   $0x107e14,(%esp)
  104d5e:	e8 7b bf ff ff       	call   100cde <__panic>
}
  104d63:	81 c4 94 00 00 00    	add    $0x94,%esp
  104d69:	5b                   	pop    %ebx
  104d6a:	5d                   	pop    %ebp
  104d6b:	c3                   	ret    

00104d6c <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
  104d6c:	55                   	push   %ebp
  104d6d:	89 e5                	mov    %esp,%ebp
    return page - pages;
  104d6f:	8b 55 08             	mov    0x8(%ebp),%edx
  104d72:	a1 fc 57 12 00       	mov    0x1257fc,%eax
  104d77:	29 c2                	sub    %eax,%edx
  104d79:	89 d0                	mov    %edx,%eax
  104d7b:	c1 f8 02             	sar    $0x2,%eax
  104d7e:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
  104d84:	5d                   	pop    %ebp
  104d85:	c3                   	ret    

00104d86 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
  104d86:	55                   	push   %ebp
  104d87:	89 e5                	mov    %esp,%ebp
  104d89:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
  104d8c:	8b 45 08             	mov    0x8(%ebp),%eax
  104d8f:	89 04 24             	mov    %eax,(%esp)
  104d92:	e8 d5 ff ff ff       	call   104d6c <page2ppn>
  104d97:	c1 e0 0c             	shl    $0xc,%eax
}
  104d9a:	c9                   	leave  
  104d9b:	c3                   	ret    

00104d9c <pa2page>:

static inline struct Page *
pa2page(uintptr_t pa) {
  104d9c:	55                   	push   %ebp
  104d9d:	89 e5                	mov    %esp,%ebp
  104d9f:	83 ec 18             	sub    $0x18,%esp
    if (PPN(pa) >= npage) {
  104da2:	8b 45 08             	mov    0x8(%ebp),%eax
  104da5:	c1 e8 0c             	shr    $0xc,%eax
  104da8:	89 c2                	mov    %eax,%edx
  104daa:	a1 a0 56 12 00       	mov    0x1256a0,%eax
  104daf:	39 c2                	cmp    %eax,%edx
  104db1:	72 1c                	jb     104dcf <pa2page+0x33>
        panic("pa2page called with invalid pa");
  104db3:	c7 44 24 08 bc 81 10 	movl   $0x1081bc,0x8(%esp)
  104dba:	00 
  104dbb:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  104dc2:	00 
  104dc3:	c7 04 24 db 81 10 00 	movl   $0x1081db,(%esp)
  104dca:	e8 0f bf ff ff       	call   100cde <__panic>
    }
    return &pages[PPN(pa)];
  104dcf:	8b 0d fc 57 12 00    	mov    0x1257fc,%ecx
  104dd5:	8b 45 08             	mov    0x8(%ebp),%eax
  104dd8:	c1 e8 0c             	shr    $0xc,%eax
  104ddb:	89 c2                	mov    %eax,%edx
  104ddd:	89 d0                	mov    %edx,%eax
  104ddf:	c1 e0 02             	shl    $0x2,%eax
  104de2:	01 d0                	add    %edx,%eax
  104de4:	c1 e0 02             	shl    $0x2,%eax
  104de7:	01 c8                	add    %ecx,%eax
}
  104de9:	c9                   	leave  
  104dea:	c3                   	ret    

00104deb <page2kva>:

static inline void *
page2kva(struct Page *page) {
  104deb:	55                   	push   %ebp
  104dec:	89 e5                	mov    %esp,%ebp
  104dee:	83 ec 28             	sub    $0x28,%esp
    return KADDR(page2pa(page));
  104df1:	8b 45 08             	mov    0x8(%ebp),%eax
  104df4:	89 04 24             	mov    %eax,(%esp)
  104df7:	e8 8a ff ff ff       	call   104d86 <page2pa>
  104dfc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104dff:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104e02:	c1 e8 0c             	shr    $0xc,%eax
  104e05:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104e08:	a1 a0 56 12 00       	mov    0x1256a0,%eax
  104e0d:	39 45 f0             	cmp    %eax,-0x10(%ebp)
  104e10:	72 23                	jb     104e35 <page2kva+0x4a>
  104e12:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104e15:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104e19:	c7 44 24 08 ec 81 10 	movl   $0x1081ec,0x8(%esp)
  104e20:	00 
  104e21:	c7 44 24 04 61 00 00 	movl   $0x61,0x4(%esp)
  104e28:	00 
  104e29:	c7 04 24 db 81 10 00 	movl   $0x1081db,(%esp)
  104e30:	e8 a9 be ff ff       	call   100cde <__panic>
  104e35:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104e38:	2d 00 00 00 40       	sub    $0x40000000,%eax
}
  104e3d:	c9                   	leave  
  104e3e:	c3                   	ret    

00104e3f <pte2page>:
kva2page(void *kva) {
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte) {
  104e3f:	55                   	push   %ebp
  104e40:	89 e5                	mov    %esp,%ebp
  104e42:	83 ec 18             	sub    $0x18,%esp
    if (!(pte & PTE_P)) {
  104e45:	8b 45 08             	mov    0x8(%ebp),%eax
  104e48:	83 e0 01             	and    $0x1,%eax
  104e4b:	85 c0                	test   %eax,%eax
  104e4d:	75 1c                	jne    104e6b <pte2page+0x2c>
        panic("pte2page called with invalid pte");
  104e4f:	c7 44 24 08 10 82 10 	movl   $0x108210,0x8(%esp)
  104e56:	00 
  104e57:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
  104e5e:	00 
  104e5f:	c7 04 24 db 81 10 00 	movl   $0x1081db,(%esp)
  104e66:	e8 73 be ff ff       	call   100cde <__panic>
    }
    return pa2page(PTE_ADDR(pte));
  104e6b:	8b 45 08             	mov    0x8(%ebp),%eax
  104e6e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104e73:	89 04 24             	mov    %eax,(%esp)
  104e76:	e8 21 ff ff ff       	call   104d9c <pa2page>
}
  104e7b:	c9                   	leave  
  104e7c:	c3                   	ret    

00104e7d <pde2page>:

static inline struct Page *
pde2page(pde_t pde) {
  104e7d:	55                   	push   %ebp
  104e7e:	89 e5                	mov    %esp,%ebp
  104e80:	83 ec 18             	sub    $0x18,%esp
    return pa2page(PDE_ADDR(pde));
  104e83:	8b 45 08             	mov    0x8(%ebp),%eax
  104e86:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104e8b:	89 04 24             	mov    %eax,(%esp)
  104e8e:	e8 09 ff ff ff       	call   104d9c <pa2page>
}
  104e93:	c9                   	leave  
  104e94:	c3                   	ret    

00104e95 <page_ref>:

static inline int
page_ref(struct Page *page) {
  104e95:	55                   	push   %ebp
  104e96:	89 e5                	mov    %esp,%ebp
    return page->ref;
  104e98:	8b 45 08             	mov    0x8(%ebp),%eax
  104e9b:	8b 00                	mov    (%eax),%eax
}
  104e9d:	5d                   	pop    %ebp
  104e9e:	c3                   	ret    

00104e9f <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
  104e9f:	55                   	push   %ebp
  104ea0:	89 e5                	mov    %esp,%ebp
    page->ref = val;
  104ea2:	8b 45 08             	mov    0x8(%ebp),%eax
  104ea5:	8b 55 0c             	mov    0xc(%ebp),%edx
  104ea8:	89 10                	mov    %edx,(%eax)
}
  104eaa:	5d                   	pop    %ebp
  104eab:	c3                   	ret    

00104eac <page_ref_inc>:

static inline int
page_ref_inc(struct Page *page) {
  104eac:	55                   	push   %ebp
  104ead:	89 e5                	mov    %esp,%ebp
    page->ref += 1;
  104eaf:	8b 45 08             	mov    0x8(%ebp),%eax
  104eb2:	8b 00                	mov    (%eax),%eax
  104eb4:	8d 50 01             	lea    0x1(%eax),%edx
  104eb7:	8b 45 08             	mov    0x8(%ebp),%eax
  104eba:	89 10                	mov    %edx,(%eax)
    return page->ref;
  104ebc:	8b 45 08             	mov    0x8(%ebp),%eax
  104ebf:	8b 00                	mov    (%eax),%eax
}
  104ec1:	5d                   	pop    %ebp
  104ec2:	c3                   	ret    

00104ec3 <page_ref_dec>:

static inline int
page_ref_dec(struct Page *page) {
  104ec3:	55                   	push   %ebp
  104ec4:	89 e5                	mov    %esp,%ebp
    page->ref -= 1;
  104ec6:	8b 45 08             	mov    0x8(%ebp),%eax
  104ec9:	8b 00                	mov    (%eax),%eax
  104ecb:	8d 50 ff             	lea    -0x1(%eax),%edx
  104ece:	8b 45 08             	mov    0x8(%ebp),%eax
  104ed1:	89 10                	mov    %edx,(%eax)
    return page->ref;
  104ed3:	8b 45 08             	mov    0x8(%ebp),%eax
  104ed6:	8b 00                	mov    (%eax),%eax
}
  104ed8:	5d                   	pop    %ebp
  104ed9:	c3                   	ret    

00104eda <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
  104eda:	55                   	push   %ebp
  104edb:	89 e5                	mov    %esp,%ebp
  104edd:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
  104ee0:	9c                   	pushf  
  104ee1:	58                   	pop    %eax
  104ee2:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
  104ee5:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
  104ee8:	25 00 02 00 00       	and    $0x200,%eax
  104eed:	85 c0                	test   %eax,%eax
  104eef:	74 0c                	je     104efd <__intr_save+0x23>
        intr_disable();
  104ef1:	e8 dc c7 ff ff       	call   1016d2 <intr_disable>
        return 1;
  104ef6:	b8 01 00 00 00       	mov    $0x1,%eax
  104efb:	eb 05                	jmp    104f02 <__intr_save+0x28>
    }
    return 0;
  104efd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  104f02:	c9                   	leave  
  104f03:	c3                   	ret    

00104f04 <__intr_restore>:

static inline void
__intr_restore(bool flag) {
  104f04:	55                   	push   %ebp
  104f05:	89 e5                	mov    %esp,%ebp
  104f07:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
  104f0a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  104f0e:	74 05                	je     104f15 <__intr_restore+0x11>
        intr_enable();
  104f10:	e8 b7 c7 ff ff       	call   1016cc <intr_enable>
    }
}
  104f15:	c9                   	leave  
  104f16:	c3                   	ret    

00104f17 <lgdt>:
/* *
 * lgdt - load the global descriptor table register and reset the
 * data/code segement registers for kernel.
 * */
static inline void
lgdt(struct pseudodesc *pd) {
  104f17:	55                   	push   %ebp
  104f18:	89 e5                	mov    %esp,%ebp
    asm volatile ("lgdt (%0)" :: "r" (pd));
  104f1a:	8b 45 08             	mov    0x8(%ebp),%eax
  104f1d:	0f 01 10             	lgdtl  (%eax)
    asm volatile ("movw %%ax, %%gs" :: "a" (USER_DS));
  104f20:	b8 23 00 00 00       	mov    $0x23,%eax
  104f25:	8e e8                	mov    %eax,%gs
    asm volatile ("movw %%ax, %%fs" :: "a" (USER_DS));
  104f27:	b8 23 00 00 00       	mov    $0x23,%eax
  104f2c:	8e e0                	mov    %eax,%fs
    asm volatile ("movw %%ax, %%es" :: "a" (KERNEL_DS));
  104f2e:	b8 10 00 00 00       	mov    $0x10,%eax
  104f33:	8e c0                	mov    %eax,%es
    asm volatile ("movw %%ax, %%ds" :: "a" (KERNEL_DS));
  104f35:	b8 10 00 00 00       	mov    $0x10,%eax
  104f3a:	8e d8                	mov    %eax,%ds
    asm volatile ("movw %%ax, %%ss" :: "a" (KERNEL_DS));
  104f3c:	b8 10 00 00 00       	mov    $0x10,%eax
  104f41:	8e d0                	mov    %eax,%ss
    // reload cs
    asm volatile ("ljmp %0, $1f\n 1:\n" :: "i" (KERNEL_CS));
  104f43:	ea 4a 4f 10 00 08 00 	ljmp   $0x8,$0x104f4a
}
  104f4a:	5d                   	pop    %ebp
  104f4b:	c3                   	ret    

00104f4c <load_esp0>:
 * load_esp0 - change the ESP0 in default task state segment,
 * so that we can use different kernel stack when we trap frame
 * user to kernel.
 * */
void
load_esp0(uintptr_t esp0) {
  104f4c:	55                   	push   %ebp
  104f4d:	89 e5                	mov    %esp,%ebp
    ts.ts_esp0 = esp0;
  104f4f:	8b 45 08             	mov    0x8(%ebp),%eax
  104f52:	a3 c4 56 12 00       	mov    %eax,0x1256c4
}
  104f57:	5d                   	pop    %ebp
  104f58:	c3                   	ret    

00104f59 <gdt_init>:

/* gdt_init - initialize the default GDT and TSS */
static void
gdt_init(void) {
  104f59:	55                   	push   %ebp
  104f5a:	89 e5                	mov    %esp,%ebp
  104f5c:	83 ec 14             	sub    $0x14,%esp
    // set boot kernel stack and default SS0
    load_esp0((uintptr_t)bootstacktop);
  104f5f:	b8 00 a0 11 00       	mov    $0x11a000,%eax
  104f64:	89 04 24             	mov    %eax,(%esp)
  104f67:	e8 e0 ff ff ff       	call   104f4c <load_esp0>
    ts.ts_ss0 = KERNEL_DS;
  104f6c:	66 c7 05 c8 56 12 00 	movw   $0x10,0x1256c8
  104f73:	10 00 

    // initialize the TSS filed of the gdt
    gdt[SEG_TSS] = SEGTSS(STS_T32A, (uintptr_t)&ts, sizeof(ts), DPL_KERNEL);
  104f75:	66 c7 05 28 aa 11 00 	movw   $0x68,0x11aa28
  104f7c:	68 00 
  104f7e:	b8 c0 56 12 00       	mov    $0x1256c0,%eax
  104f83:	66 a3 2a aa 11 00    	mov    %ax,0x11aa2a
  104f89:	b8 c0 56 12 00       	mov    $0x1256c0,%eax
  104f8e:	c1 e8 10             	shr    $0x10,%eax
  104f91:	a2 2c aa 11 00       	mov    %al,0x11aa2c
  104f96:	0f b6 05 2d aa 11 00 	movzbl 0x11aa2d,%eax
  104f9d:	83 e0 f0             	and    $0xfffffff0,%eax
  104fa0:	83 c8 09             	or     $0x9,%eax
  104fa3:	a2 2d aa 11 00       	mov    %al,0x11aa2d
  104fa8:	0f b6 05 2d aa 11 00 	movzbl 0x11aa2d,%eax
  104faf:	83 e0 ef             	and    $0xffffffef,%eax
  104fb2:	a2 2d aa 11 00       	mov    %al,0x11aa2d
  104fb7:	0f b6 05 2d aa 11 00 	movzbl 0x11aa2d,%eax
  104fbe:	83 e0 9f             	and    $0xffffff9f,%eax
  104fc1:	a2 2d aa 11 00       	mov    %al,0x11aa2d
  104fc6:	0f b6 05 2d aa 11 00 	movzbl 0x11aa2d,%eax
  104fcd:	83 c8 80             	or     $0xffffff80,%eax
  104fd0:	a2 2d aa 11 00       	mov    %al,0x11aa2d
  104fd5:	0f b6 05 2e aa 11 00 	movzbl 0x11aa2e,%eax
  104fdc:	83 e0 f0             	and    $0xfffffff0,%eax
  104fdf:	a2 2e aa 11 00       	mov    %al,0x11aa2e
  104fe4:	0f b6 05 2e aa 11 00 	movzbl 0x11aa2e,%eax
  104feb:	83 e0 ef             	and    $0xffffffef,%eax
  104fee:	a2 2e aa 11 00       	mov    %al,0x11aa2e
  104ff3:	0f b6 05 2e aa 11 00 	movzbl 0x11aa2e,%eax
  104ffa:	83 e0 df             	and    $0xffffffdf,%eax
  104ffd:	a2 2e aa 11 00       	mov    %al,0x11aa2e
  105002:	0f b6 05 2e aa 11 00 	movzbl 0x11aa2e,%eax
  105009:	83 c8 40             	or     $0x40,%eax
  10500c:	a2 2e aa 11 00       	mov    %al,0x11aa2e
  105011:	0f b6 05 2e aa 11 00 	movzbl 0x11aa2e,%eax
  105018:	83 e0 7f             	and    $0x7f,%eax
  10501b:	a2 2e aa 11 00       	mov    %al,0x11aa2e
  105020:	b8 c0 56 12 00       	mov    $0x1256c0,%eax
  105025:	c1 e8 18             	shr    $0x18,%eax
  105028:	a2 2f aa 11 00       	mov    %al,0x11aa2f

    // reload all segment registers
    lgdt(&gdt_pd);
  10502d:	c7 04 24 30 aa 11 00 	movl   $0x11aa30,(%esp)
  105034:	e8 de fe ff ff       	call   104f17 <lgdt>
  105039:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
    asm volatile ("cli" ::: "memory");
}

static inline void
ltr(uint16_t sel) {
    asm volatile ("ltr %0" :: "r" (sel) : "memory");
  10503f:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
  105043:	0f 00 d8             	ltr    %ax

    // load the TSS
    ltr(GD_TSS);
}
  105046:	c9                   	leave  
  105047:	c3                   	ret    

00105048 <init_pmm_manager>:

//init_pmm_manager - initialize a pmm_manager instance
static void
init_pmm_manager(void) {
  105048:	55                   	push   %ebp
  105049:	89 e5                	mov    %esp,%ebp
  10504b:	83 ec 18             	sub    $0x18,%esp
#ifdef __DEFAULT_PMM_MANAGER__
    pmm_manager = &default_pmm_manager;
  10504e:	c7 05 f4 57 12 00 a0 	movl   $0x1081a0,0x1257f4
  105055:	81 10 00 
#else
    pmm_manager = &buddy_pmm_manager;
#endif
    cprintf("memory management: %s\n", pmm_manager->name);
  105058:	a1 f4 57 12 00       	mov    0x1257f4,%eax
  10505d:	8b 00                	mov    (%eax),%eax
  10505f:	89 44 24 04          	mov    %eax,0x4(%esp)
  105063:	c7 04 24 3c 82 10 00 	movl   $0x10823c,(%esp)
  10506a:	e8 e5 b2 ff ff       	call   100354 <cprintf>
    pmm_manager->init();
  10506f:	a1 f4 57 12 00       	mov    0x1257f4,%eax
  105074:	8b 40 04             	mov    0x4(%eax),%eax
  105077:	ff d0                	call   *%eax
}
  105079:	c9                   	leave  
  10507a:	c3                   	ret    

0010507b <init_memmap>:

//init_memmap - call pmm->init_memmap to build Page struct for free memory  
static void
init_memmap(struct Page *base, size_t n) {
  10507b:	55                   	push   %ebp
  10507c:	89 e5                	mov    %esp,%ebp
  10507e:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->init_memmap(base, n);
  105081:	a1 f4 57 12 00       	mov    0x1257f4,%eax
  105086:	8b 40 08             	mov    0x8(%eax),%eax
  105089:	8b 55 0c             	mov    0xc(%ebp),%edx
  10508c:	89 54 24 04          	mov    %edx,0x4(%esp)
  105090:	8b 55 08             	mov    0x8(%ebp),%edx
  105093:	89 14 24             	mov    %edx,(%esp)
  105096:	ff d0                	call   *%eax
}
  105098:	c9                   	leave  
  105099:	c3                   	ret    

0010509a <alloc_pages>:

//alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory 
struct Page *
alloc_pages(size_t n) {
  10509a:	55                   	push   %ebp
  10509b:	89 e5                	mov    %esp,%ebp
  10509d:	83 ec 28             	sub    $0x28,%esp
    struct Page *page=NULL;
  1050a0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
  1050a7:	e8 2e fe ff ff       	call   104eda <__intr_save>
  1050ac:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        page = pmm_manager->alloc_pages(n);
  1050af:	a1 f4 57 12 00       	mov    0x1257f4,%eax
  1050b4:	8b 40 0c             	mov    0xc(%eax),%eax
  1050b7:	8b 55 08             	mov    0x8(%ebp),%edx
  1050ba:	89 14 24             	mov    %edx,(%esp)
  1050bd:	ff d0                	call   *%eax
  1050bf:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }
    local_intr_restore(intr_flag);
  1050c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1050c5:	89 04 24             	mov    %eax,(%esp)
  1050c8:	e8 37 fe ff ff       	call   104f04 <__intr_restore>
    return page;
  1050cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1050d0:	c9                   	leave  
  1050d1:	c3                   	ret    

001050d2 <free_pages>:

//free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory 
void
free_pages(struct Page *base, size_t n) {
  1050d2:	55                   	push   %ebp
  1050d3:	89 e5                	mov    %esp,%ebp
  1050d5:	83 ec 28             	sub    $0x28,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
  1050d8:	e8 fd fd ff ff       	call   104eda <__intr_save>
  1050dd:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        pmm_manager->free_pages(base, n);
  1050e0:	a1 f4 57 12 00       	mov    0x1257f4,%eax
  1050e5:	8b 40 10             	mov    0x10(%eax),%eax
  1050e8:	8b 55 0c             	mov    0xc(%ebp),%edx
  1050eb:	89 54 24 04          	mov    %edx,0x4(%esp)
  1050ef:	8b 55 08             	mov    0x8(%ebp),%edx
  1050f2:	89 14 24             	mov    %edx,(%esp)
  1050f5:	ff d0                	call   *%eax
    }
    local_intr_restore(intr_flag);
  1050f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1050fa:	89 04 24             	mov    %eax,(%esp)
  1050fd:	e8 02 fe ff ff       	call   104f04 <__intr_restore>
}
  105102:	c9                   	leave  
  105103:	c3                   	ret    

00105104 <nr_free_pages>:

//nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE) 
//of current free memory
size_t
nr_free_pages(void) {
  105104:	55                   	push   %ebp
  105105:	89 e5                	mov    %esp,%ebp
  105107:	83 ec 28             	sub    $0x28,%esp
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
  10510a:	e8 cb fd ff ff       	call   104eda <__intr_save>
  10510f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        ret = pmm_manager->nr_free_pages();
  105112:	a1 f4 57 12 00       	mov    0x1257f4,%eax
  105117:	8b 40 14             	mov    0x14(%eax),%eax
  10511a:	ff d0                	call   *%eax
  10511c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    }
    local_intr_restore(intr_flag);
  10511f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105122:	89 04 24             	mov    %eax,(%esp)
  105125:	e8 da fd ff ff       	call   104f04 <__intr_restore>
    return ret;
  10512a:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  10512d:	c9                   	leave  
  10512e:	c3                   	ret    

0010512f <page_init>:

/* pmm_init - initialize the physical memory management */
static void
page_init(void) {
  10512f:	55                   	push   %ebp
  105130:	89 e5                	mov    %esp,%ebp
  105132:	57                   	push   %edi
  105133:	56                   	push   %esi
  105134:	53                   	push   %ebx
  105135:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
  10513b:	c7 45 c4 00 80 00 c0 	movl   $0xc0008000,-0x3c(%ebp)
    uint64_t maxpa = 0;
  105142:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  105149:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

    cprintf("e820map:\n");
  105150:	c7 04 24 53 82 10 00 	movl   $0x108253,(%esp)
  105157:	e8 f8 b1 ff ff       	call   100354 <cprintf>
    // 检测出内存能用的最大物理地址
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
  10515c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  105163:	e9 15 01 00 00       	jmp    10527d <page_init+0x14e>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
  105168:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  10516b:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10516e:	89 d0                	mov    %edx,%eax
  105170:	c1 e0 02             	shl    $0x2,%eax
  105173:	01 d0                	add    %edx,%eax
  105175:	c1 e0 02             	shl    $0x2,%eax
  105178:	01 c8                	add    %ecx,%eax
  10517a:	8b 50 08             	mov    0x8(%eax),%edx
  10517d:	8b 40 04             	mov    0x4(%eax),%eax
  105180:	89 45 b8             	mov    %eax,-0x48(%ebp)
  105183:	89 55 bc             	mov    %edx,-0x44(%ebp)
  105186:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  105189:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10518c:	89 d0                	mov    %edx,%eax
  10518e:	c1 e0 02             	shl    $0x2,%eax
  105191:	01 d0                	add    %edx,%eax
  105193:	c1 e0 02             	shl    $0x2,%eax
  105196:	01 c8                	add    %ecx,%eax
  105198:	8b 48 0c             	mov    0xc(%eax),%ecx
  10519b:	8b 58 10             	mov    0x10(%eax),%ebx
  10519e:	8b 45 b8             	mov    -0x48(%ebp),%eax
  1051a1:	8b 55 bc             	mov    -0x44(%ebp),%edx
  1051a4:	01 c8                	add    %ecx,%eax
  1051a6:	11 da                	adc    %ebx,%edx
  1051a8:	89 45 b0             	mov    %eax,-0x50(%ebp)
  1051ab:	89 55 b4             	mov    %edx,-0x4c(%ebp)
        cprintf("  memory: %08llx, [%08llx, %08llx], type = %d.\n",
  1051ae:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  1051b1:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1051b4:	89 d0                	mov    %edx,%eax
  1051b6:	c1 e0 02             	shl    $0x2,%eax
  1051b9:	01 d0                	add    %edx,%eax
  1051bb:	c1 e0 02             	shl    $0x2,%eax
  1051be:	01 c8                	add    %ecx,%eax
  1051c0:	83 c0 14             	add    $0x14,%eax
  1051c3:	8b 00                	mov    (%eax),%eax
  1051c5:	89 85 7c ff ff ff    	mov    %eax,-0x84(%ebp)
  1051cb:	8b 45 b0             	mov    -0x50(%ebp),%eax
  1051ce:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  1051d1:	83 c0 ff             	add    $0xffffffff,%eax
  1051d4:	83 d2 ff             	adc    $0xffffffff,%edx
  1051d7:	89 c6                	mov    %eax,%esi
  1051d9:	89 d7                	mov    %edx,%edi
  1051db:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  1051de:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1051e1:	89 d0                	mov    %edx,%eax
  1051e3:	c1 e0 02             	shl    $0x2,%eax
  1051e6:	01 d0                	add    %edx,%eax
  1051e8:	c1 e0 02             	shl    $0x2,%eax
  1051eb:	01 c8                	add    %ecx,%eax
  1051ed:	8b 48 0c             	mov    0xc(%eax),%ecx
  1051f0:	8b 58 10             	mov    0x10(%eax),%ebx
  1051f3:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  1051f9:	89 44 24 1c          	mov    %eax,0x1c(%esp)
  1051fd:	89 74 24 14          	mov    %esi,0x14(%esp)
  105201:	89 7c 24 18          	mov    %edi,0x18(%esp)
  105205:	8b 45 b8             	mov    -0x48(%ebp),%eax
  105208:	8b 55 bc             	mov    -0x44(%ebp),%edx
  10520b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10520f:	89 54 24 10          	mov    %edx,0x10(%esp)
  105213:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  105217:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  10521b:	c7 04 24 60 82 10 00 	movl   $0x108260,(%esp)
  105222:	e8 2d b1 ff ff       	call   100354 <cprintf>
                memmap->map[i].size, begin, end - 1, memmap->map[i].type);
        if (memmap->map[i].type == E820_ARM) {
  105227:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  10522a:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10522d:	89 d0                	mov    %edx,%eax
  10522f:	c1 e0 02             	shl    $0x2,%eax
  105232:	01 d0                	add    %edx,%eax
  105234:	c1 e0 02             	shl    $0x2,%eax
  105237:	01 c8                	add    %ecx,%eax
  105239:	83 c0 14             	add    $0x14,%eax
  10523c:	8b 00                	mov    (%eax),%eax
  10523e:	83 f8 01             	cmp    $0x1,%eax
  105241:	75 36                	jne    105279 <page_init+0x14a>
            if (maxpa < end && begin < KMEMSIZE) {
  105243:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105246:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  105249:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
  10524c:	77 2b                	ja     105279 <page_init+0x14a>
  10524e:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
  105251:	72 05                	jb     105258 <page_init+0x129>
  105253:	3b 45 b0             	cmp    -0x50(%ebp),%eax
  105256:	73 21                	jae    105279 <page_init+0x14a>
  105258:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
  10525c:	77 1b                	ja     105279 <page_init+0x14a>
  10525e:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
  105262:	72 09                	jb     10526d <page_init+0x13e>
  105264:	81 7d b8 ff ff ff 37 	cmpl   $0x37ffffff,-0x48(%ebp)
  10526b:	77 0c                	ja     105279 <page_init+0x14a>
                maxpa = end;
  10526d:	8b 45 b0             	mov    -0x50(%ebp),%eax
  105270:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  105273:	89 45 e0             	mov    %eax,-0x20(%ebp)
  105276:	89 55 e4             	mov    %edx,-0x1c(%ebp)
    uint64_t maxpa = 0;

    cprintf("e820map:\n");
    // 检测出内存能用的最大物理地址
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
  105279:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
  10527d:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  105280:	8b 00                	mov    (%eax),%eax
  105282:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  105285:	0f 8f dd fe ff ff    	jg     105168 <page_init+0x39>
            if (maxpa < end && begin < KMEMSIZE) {
                maxpa = end;
            }
        }
    }
    if (maxpa > KMEMSIZE) {
  10528b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  10528f:	72 1d                	jb     1052ae <page_init+0x17f>
  105291:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  105295:	77 09                	ja     1052a0 <page_init+0x171>
  105297:	81 7d e0 00 00 00 38 	cmpl   $0x38000000,-0x20(%ebp)
  10529e:	76 0e                	jbe    1052ae <page_init+0x17f>
        maxpa = KMEMSIZE;
  1052a0:	c7 45 e0 00 00 00 38 	movl   $0x38000000,-0x20(%ebp)
  1052a7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    }

    extern char end[];

    npage = maxpa / PGSIZE;
  1052ae:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1052b1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1052b4:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
  1052b8:	c1 ea 0c             	shr    $0xc,%edx
  1052bb:	a3 a0 56 12 00       	mov    %eax,0x1256a0
    // 内核之后就是pages结构体数组
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
  1052c0:	c7 45 ac 00 10 00 00 	movl   $0x1000,-0x54(%ebp)
  1052c7:	b8 00 58 12 00       	mov    $0x125800,%eax
  1052cc:	8d 50 ff             	lea    -0x1(%eax),%edx
  1052cf:	8b 45 ac             	mov    -0x54(%ebp),%eax
  1052d2:	01 d0                	add    %edx,%eax
  1052d4:	89 45 a8             	mov    %eax,-0x58(%ebp)
  1052d7:	8b 45 a8             	mov    -0x58(%ebp),%eax
  1052da:	ba 00 00 00 00       	mov    $0x0,%edx
  1052df:	f7 75 ac             	divl   -0x54(%ebp)
  1052e2:	89 d0                	mov    %edx,%eax
  1052e4:	8b 55 a8             	mov    -0x58(%ebp),%edx
  1052e7:	29 c2                	sub    %eax,%edx
  1052e9:	89 d0                	mov    %edx,%eax
  1052eb:	a3 fc 57 12 00       	mov    %eax,0x1257fc

    for (i = 0; i < npage; i ++) {
  1052f0:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  1052f7:	eb 2f                	jmp    105328 <page_init+0x1f9>
        SetPageReserved(pages + i);
  1052f9:	8b 0d fc 57 12 00    	mov    0x1257fc,%ecx
  1052ff:	8b 55 dc             	mov    -0x24(%ebp),%edx
  105302:	89 d0                	mov    %edx,%eax
  105304:	c1 e0 02             	shl    $0x2,%eax
  105307:	01 d0                	add    %edx,%eax
  105309:	c1 e0 02             	shl    $0x2,%eax
  10530c:	01 c8                	add    %ecx,%eax
  10530e:	83 c0 04             	add    $0x4,%eax
  105311:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  105318:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  10531b:	8b 45 8c             	mov    -0x74(%ebp),%eax
  10531e:	8b 55 90             	mov    -0x70(%ebp),%edx
  105321:	0f ab 10             	bts    %edx,(%eax)

    npage = maxpa / PGSIZE;
    // 内核之后就是pages结构体数组
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    for (i = 0; i < npage; i ++) {
  105324:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
  105328:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10532b:	a1 a0 56 12 00       	mov    0x1256a0,%eax
  105330:	39 c2                	cmp    %eax,%edx
  105332:	72 c5                	jb     1052f9 <page_init+0x1ca>
        SetPageReserved(pages + i);
    }

    // 相当于最小能用的物理地址
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);
  105334:	8b 15 a0 56 12 00    	mov    0x1256a0,%edx
  10533a:	89 d0                	mov    %edx,%eax
  10533c:	c1 e0 02             	shl    $0x2,%eax
  10533f:	01 d0                	add    %edx,%eax
  105341:	c1 e0 02             	shl    $0x2,%eax
  105344:	89 c2                	mov    %eax,%edx
  105346:	a1 fc 57 12 00       	mov    0x1257fc,%eax
  10534b:	01 d0                	add    %edx,%eax
  10534d:	89 45 a4             	mov    %eax,-0x5c(%ebp)
  105350:	81 7d a4 ff ff ff bf 	cmpl   $0xbfffffff,-0x5c(%ebp)
  105357:	77 23                	ja     10537c <page_init+0x24d>
  105359:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  10535c:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105360:	c7 44 24 08 90 82 10 	movl   $0x108290,0x8(%esp)
  105367:	00 
  105368:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  10536f:	00 
  105370:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105377:	e8 62 b9 ff ff       	call   100cde <__panic>
  10537c:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  10537f:	05 00 00 00 40       	add    $0x40000000,%eax
  105384:	89 45 a0             	mov    %eax,-0x60(%ebp)
    cprintf("freemem low addr: %x, high addr: %x\n", freemem, KMEMSIZE);
  105387:	c7 44 24 08 00 00 00 	movl   $0x38000000,0x8(%esp)
  10538e:	38 
  10538f:	8b 45 a0             	mov    -0x60(%ebp),%eax
  105392:	89 44 24 04          	mov    %eax,0x4(%esp)
  105396:	c7 04 24 c4 82 10 00 	movl   $0x1082c4,(%esp)
  10539d:	e8 b2 af ff ff       	call   100354 <cprintf>
    for (i = 0; i < memmap->nr_map; i ++) {
  1053a2:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  1053a9:	e9 74 01 00 00       	jmp    105522 <page_init+0x3f3>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
  1053ae:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  1053b1:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1053b4:	89 d0                	mov    %edx,%eax
  1053b6:	c1 e0 02             	shl    $0x2,%eax
  1053b9:	01 d0                	add    %edx,%eax
  1053bb:	c1 e0 02             	shl    $0x2,%eax
  1053be:	01 c8                	add    %ecx,%eax
  1053c0:	8b 50 08             	mov    0x8(%eax),%edx
  1053c3:	8b 40 04             	mov    0x4(%eax),%eax
  1053c6:	89 45 d0             	mov    %eax,-0x30(%ebp)
  1053c9:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  1053cc:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  1053cf:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1053d2:	89 d0                	mov    %edx,%eax
  1053d4:	c1 e0 02             	shl    $0x2,%eax
  1053d7:	01 d0                	add    %edx,%eax
  1053d9:	c1 e0 02             	shl    $0x2,%eax
  1053dc:	01 c8                	add    %ecx,%eax
  1053de:	8b 48 0c             	mov    0xc(%eax),%ecx
  1053e1:	8b 58 10             	mov    0x10(%eax),%ebx
  1053e4:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1053e7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1053ea:	01 c8                	add    %ecx,%eax
  1053ec:	11 da                	adc    %ebx,%edx
  1053ee:	89 45 c8             	mov    %eax,-0x38(%ebp)
  1053f1:	89 55 cc             	mov    %edx,-0x34(%ebp)
        if (memmap->map[i].type == E820_ARM) {
  1053f4:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  1053f7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1053fa:	89 d0                	mov    %edx,%eax
  1053fc:	c1 e0 02             	shl    $0x2,%eax
  1053ff:	01 d0                	add    %edx,%eax
  105401:	c1 e0 02             	shl    $0x2,%eax
  105404:	01 c8                	add    %ecx,%eax
  105406:	83 c0 14             	add    $0x14,%eax
  105409:	8b 00                	mov    (%eax),%eax
  10540b:	83 f8 01             	cmp    $0x1,%eax
  10540e:	0f 85 0a 01 00 00    	jne    10551e <page_init+0x3ef>
            if (begin < freemem) {
  105414:	8b 45 a0             	mov    -0x60(%ebp),%eax
  105417:	ba 00 00 00 00       	mov    $0x0,%edx
  10541c:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  10541f:	72 17                	jb     105438 <page_init+0x309>
  105421:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  105424:	77 05                	ja     10542b <page_init+0x2fc>
  105426:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  105429:	76 0d                	jbe    105438 <page_init+0x309>
                begin = freemem;
  10542b:	8b 45 a0             	mov    -0x60(%ebp),%eax
  10542e:	89 45 d0             	mov    %eax,-0x30(%ebp)
  105431:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
            }
            if (end > KMEMSIZE) {
  105438:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  10543c:	72 1d                	jb     10545b <page_init+0x32c>
  10543e:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  105442:	77 09                	ja     10544d <page_init+0x31e>
  105444:	81 7d c8 00 00 00 38 	cmpl   $0x38000000,-0x38(%ebp)
  10544b:	76 0e                	jbe    10545b <page_init+0x32c>
                end = KMEMSIZE;
  10544d:	c7 45 c8 00 00 00 38 	movl   $0x38000000,-0x38(%ebp)
  105454:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
            }
            if (begin < end) {
  10545b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10545e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  105461:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  105464:	0f 87 b4 00 00 00    	ja     10551e <page_init+0x3ef>
  10546a:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  10546d:	72 09                	jb     105478 <page_init+0x349>
  10546f:	3b 45 c8             	cmp    -0x38(%ebp),%eax
  105472:	0f 83 a6 00 00 00    	jae    10551e <page_init+0x3ef>
                begin = ROUNDUP(begin, PGSIZE);
  105478:	c7 45 9c 00 10 00 00 	movl   $0x1000,-0x64(%ebp)
  10547f:	8b 55 d0             	mov    -0x30(%ebp),%edx
  105482:	8b 45 9c             	mov    -0x64(%ebp),%eax
  105485:	01 d0                	add    %edx,%eax
  105487:	83 e8 01             	sub    $0x1,%eax
  10548a:	89 45 98             	mov    %eax,-0x68(%ebp)
  10548d:	8b 45 98             	mov    -0x68(%ebp),%eax
  105490:	ba 00 00 00 00       	mov    $0x0,%edx
  105495:	f7 75 9c             	divl   -0x64(%ebp)
  105498:	89 d0                	mov    %edx,%eax
  10549a:	8b 55 98             	mov    -0x68(%ebp),%edx
  10549d:	29 c2                	sub    %eax,%edx
  10549f:	89 d0                	mov    %edx,%eax
  1054a1:	ba 00 00 00 00       	mov    $0x0,%edx
  1054a6:	89 45 d0             	mov    %eax,-0x30(%ebp)
  1054a9:	89 55 d4             	mov    %edx,-0x2c(%ebp)
                end = ROUNDDOWN(end, PGSIZE);
  1054ac:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1054af:	89 45 94             	mov    %eax,-0x6c(%ebp)
  1054b2:	8b 45 94             	mov    -0x6c(%ebp),%eax
  1054b5:	ba 00 00 00 00       	mov    $0x0,%edx
  1054ba:	89 c7                	mov    %eax,%edi
  1054bc:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  1054c2:	89 7d 80             	mov    %edi,-0x80(%ebp)
  1054c5:	89 d0                	mov    %edx,%eax
  1054c7:	83 e0 00             	and    $0x0,%eax
  1054ca:	89 45 84             	mov    %eax,-0x7c(%ebp)
  1054cd:	8b 45 80             	mov    -0x80(%ebp),%eax
  1054d0:	8b 55 84             	mov    -0x7c(%ebp),%edx
  1054d3:	89 45 c8             	mov    %eax,-0x38(%ebp)
  1054d6:	89 55 cc             	mov    %edx,-0x34(%ebp)
                if (begin < end) {
  1054d9:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1054dc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1054df:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  1054e2:	77 3a                	ja     10551e <page_init+0x3ef>
  1054e4:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  1054e7:	72 05                	jb     1054ee <page_init+0x3bf>
  1054e9:	3b 45 c8             	cmp    -0x38(%ebp),%eax
  1054ec:	73 30                	jae    10551e <page_init+0x3ef>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
  1054ee:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  1054f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  1054f4:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1054f7:	8b 55 cc             	mov    -0x34(%ebp),%edx
  1054fa:	29 c8                	sub    %ecx,%eax
  1054fc:	19 da                	sbb    %ebx,%edx
  1054fe:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
  105502:	c1 ea 0c             	shr    $0xc,%edx
  105505:	89 c3                	mov    %eax,%ebx
  105507:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10550a:	89 04 24             	mov    %eax,(%esp)
  10550d:	e8 8a f8 ff ff       	call   104d9c <pa2page>
  105512:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  105516:	89 04 24             	mov    %eax,(%esp)
  105519:	e8 5d fb ff ff       	call   10507b <init_memmap>
    }

    // 相当于最小能用的物理地址
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);
    cprintf("freemem low addr: %x, high addr: %x\n", freemem, KMEMSIZE);
    for (i = 0; i < memmap->nr_map; i ++) {
  10551e:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
  105522:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  105525:	8b 00                	mov    (%eax),%eax
  105527:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  10552a:	0f 8f 7e fe ff ff    	jg     1053ae <page_init+0x27f>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
                }
            }
        }
    }
}
  105530:	81 c4 9c 00 00 00    	add    $0x9c,%esp
  105536:	5b                   	pop    %ebx
  105537:	5e                   	pop    %esi
  105538:	5f                   	pop    %edi
  105539:	5d                   	pop    %ebp
  10553a:	c3                   	ret    

0010553b <boot_map_segment>:
//  la:   linear address of this memory need to map (after x86 segment map)
//  size: memory size
//  pa:   physical address of this memory
//  perm: permission of this memory  
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
  10553b:	55                   	push   %ebp
  10553c:	89 e5                	mov    %esp,%ebp
  10553e:	83 ec 38             	sub    $0x38,%esp
    assert(PGOFF(la) == PGOFF(pa));
  105541:	8b 45 14             	mov    0x14(%ebp),%eax
  105544:	8b 55 0c             	mov    0xc(%ebp),%edx
  105547:	31 d0                	xor    %edx,%eax
  105549:	25 ff 0f 00 00       	and    $0xfff,%eax
  10554e:	85 c0                	test   %eax,%eax
  105550:	74 24                	je     105576 <boot_map_segment+0x3b>
  105552:	c7 44 24 0c e9 82 10 	movl   $0x1082e9,0xc(%esp)
  105559:	00 
  10555a:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105561:	00 
  105562:	c7 44 24 04 06 01 00 	movl   $0x106,0x4(%esp)
  105569:	00 
  10556a:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105571:	e8 68 b7 ff ff       	call   100cde <__panic>
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
  105576:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
  10557d:	8b 45 0c             	mov    0xc(%ebp),%eax
  105580:	25 ff 0f 00 00       	and    $0xfff,%eax
  105585:	89 c2                	mov    %eax,%edx
  105587:	8b 45 10             	mov    0x10(%ebp),%eax
  10558a:	01 c2                	add    %eax,%edx
  10558c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10558f:	01 d0                	add    %edx,%eax
  105591:	83 e8 01             	sub    $0x1,%eax
  105594:	89 45 ec             	mov    %eax,-0x14(%ebp)
  105597:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10559a:	ba 00 00 00 00       	mov    $0x0,%edx
  10559f:	f7 75 f0             	divl   -0x10(%ebp)
  1055a2:	89 d0                	mov    %edx,%eax
  1055a4:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1055a7:	29 c2                	sub    %eax,%edx
  1055a9:	89 d0                	mov    %edx,%eax
  1055ab:	c1 e8 0c             	shr    $0xc,%eax
  1055ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
    la = ROUNDDOWN(la, PGSIZE);
  1055b1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1055b4:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1055b7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1055ba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1055bf:	89 45 0c             	mov    %eax,0xc(%ebp)
    pa = ROUNDDOWN(pa, PGSIZE);
  1055c2:	8b 45 14             	mov    0x14(%ebp),%eax
  1055c5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1055c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1055cb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1055d0:	89 45 14             	mov    %eax,0x14(%ebp)
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
  1055d3:	eb 6b                	jmp    105640 <boot_map_segment+0x105>
        pte_t *ptep = get_pte(pgdir, la, 1);
  1055d5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  1055dc:	00 
  1055dd:	8b 45 0c             	mov    0xc(%ebp),%eax
  1055e0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1055e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1055e7:	89 04 24             	mov    %eax,(%esp)
  1055ea:	e8 82 01 00 00       	call   105771 <get_pte>
  1055ef:	89 45 e0             	mov    %eax,-0x20(%ebp)
        assert(ptep != NULL);
  1055f2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  1055f6:	75 24                	jne    10561c <boot_map_segment+0xe1>
  1055f8:	c7 44 24 0c 15 83 10 	movl   $0x108315,0xc(%esp)
  1055ff:	00 
  105600:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105607:	00 
  105608:	c7 44 24 04 0c 01 00 	movl   $0x10c,0x4(%esp)
  10560f:	00 
  105610:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105617:	e8 c2 b6 ff ff       	call   100cde <__panic>
        *ptep = pa | PTE_P | perm;
  10561c:	8b 45 18             	mov    0x18(%ebp),%eax
  10561f:	8b 55 14             	mov    0x14(%ebp),%edx
  105622:	09 d0                	or     %edx,%eax
  105624:	83 c8 01             	or     $0x1,%eax
  105627:	89 c2                	mov    %eax,%edx
  105629:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10562c:	89 10                	mov    %edx,(%eax)
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
    assert(PGOFF(la) == PGOFF(pa));
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
  10562e:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
  105632:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
  105639:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  105640:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  105644:	75 8f                	jne    1055d5 <boot_map_segment+0x9a>
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pa | PTE_P | perm;
    }
}
  105646:	c9                   	leave  
  105647:	c3                   	ret    

00105648 <boot_alloc_page>:

//boot_alloc_page - allocate one page using pmm->alloc_pages(1) 
// return value: the kernel virtual address of this allocated page
//note: this function is used to get the memory for PDT(Page Directory Table)&PT(Page Table)
static void *
boot_alloc_page(void) {
  105648:	55                   	push   %ebp
  105649:	89 e5                	mov    %esp,%ebp
  10564b:	83 ec 28             	sub    $0x28,%esp
    struct Page *p = alloc_page();
  10564e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  105655:	e8 40 fa ff ff       	call   10509a <alloc_pages>
  10565a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (p == NULL) {
  10565d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  105661:	75 1c                	jne    10567f <boot_alloc_page+0x37>
        panic("boot_alloc_page failed.\n");
  105663:	c7 44 24 08 22 83 10 	movl   $0x108322,0x8(%esp)
  10566a:	00 
  10566b:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
  105672:	00 
  105673:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  10567a:	e8 5f b6 ff ff       	call   100cde <__panic>
    }
    return page2kva(p);
  10567f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105682:	89 04 24             	mov    %eax,(%esp)
  105685:	e8 61 f7 ff ff       	call   104deb <page2kva>
}
  10568a:	c9                   	leave  
  10568b:	c3                   	ret    

0010568c <pmm_init>:

//pmm_init - setup a pmm to manage physical memory, build PDT&PT to setup paging mechanism 
//         - check the correctness of pmm & paging mechanism, print PDT&PT
void
pmm_init(void) {
  10568c:	55                   	push   %ebp
  10568d:	89 e5                	mov    %esp,%ebp
  10568f:	83 ec 38             	sub    $0x38,%esp
    // We've already enabled paging
    boot_cr3 = PADDR(boot_pgdir);
  105692:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  105697:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10569a:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
  1056a1:	77 23                	ja     1056c6 <pmm_init+0x3a>
  1056a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1056a6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1056aa:	c7 44 24 08 90 82 10 	movl   $0x108290,0x8(%esp)
  1056b1:	00 
  1056b2:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
  1056b9:	00 
  1056ba:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  1056c1:	e8 18 b6 ff ff       	call   100cde <__panic>
  1056c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1056c9:	05 00 00 00 40       	add    $0x40000000,%eax
  1056ce:	a3 f8 57 12 00       	mov    %eax,0x1257f8
    //We need to alloc/free the physical memory (granularity is 4KB or other size). 
    //So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    //First we should init a physical memory manager(pmm) based on the framework.
    //Then pmm can alloc/free the physical memory. 
    //Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();
  1056d3:	e8 70 f9 ff ff       	call   105048 <init_pmm_manager>

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();
  1056d8:	e8 52 fa ff ff       	call   10512f <page_init>

    //use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();
  1056dd:	e8 21 04 00 00       	call   105b03 <check_alloc_page>

    check_pgdir();
  1056e2:	e8 3a 04 00 00       	call   105b21 <check_pgdir>

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // recursively insert boot_pgdir in itself
    // to form a virtual page table at virtual address VPT
    boot_pgdir[PDX(VPT)] = PADDR(boot_pgdir) | PTE_P | PTE_W;
  1056e7:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  1056ec:	8d 90 ac 0f 00 00    	lea    0xfac(%eax),%edx
  1056f2:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  1056f7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1056fa:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
  105701:	77 23                	ja     105726 <pmm_init+0x9a>
  105703:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105706:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10570a:	c7 44 24 08 90 82 10 	movl   $0x108290,0x8(%esp)
  105711:	00 
  105712:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
  105719:	00 
  10571a:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105721:	e8 b8 b5 ff ff       	call   100cde <__panic>
  105726:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105729:	05 00 00 00 40       	add    $0x40000000,%eax
  10572e:	83 c8 03             	or     $0x3,%eax
  105731:	89 02                	mov    %eax,(%edx)

    // map all physical memory to linear memory with base linear addr KERNBASE
    // linear_addr KERNBASE ~ KERNBASE + KMEMSIZE = phy_addr 0 ~ KMEMSIZE
    boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, 0, PTE_W);
  105733:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  105738:	c7 44 24 10 02 00 00 	movl   $0x2,0x10(%esp)
  10573f:	00 
  105740:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105747:	00 
  105748:	c7 44 24 08 00 00 00 	movl   $0x38000000,0x8(%esp)
  10574f:	38 
  105750:	c7 44 24 04 00 00 00 	movl   $0xc0000000,0x4(%esp)
  105757:	c0 
  105758:	89 04 24             	mov    %eax,(%esp)
  10575b:	e8 db fd ff ff       	call   10553b <boot_map_segment>

    // Since we are using bootloader's GDT,
    // we should reload gdt (second time, the last time) to get user segments and the TSS
    // map virtual_addr 0 ~ 4G = linear_addr 0 ~ 4G
    // then set kernel stack (ss:esp) in TSS, setup TSS in gdt, load TSS
    gdt_init();
  105760:	e8 f4 f7 ff ff       	call   104f59 <gdt_init>

    //now the basic virtual memory map(see memalyout.h) is established.
    //check the correctness of the basic virtual memory map.
    check_boot_pgdir();
  105765:	e8 52 0a 00 00       	call   1061bc <check_boot_pgdir>

    print_pgdir();
  10576a:	e8 da 0e 00 00       	call   106649 <print_pgdir>

}
  10576f:	c9                   	leave  
  105770:	c3                   	ret    

00105771 <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *
get_pte(pde_t *pgdir, uintptr_t la, bool create) {
  105771:	55                   	push   %ebp
  105772:	89 e5                	mov    %esp,%ebp
  105774:	83 ec 48             	sub    $0x48,%esp
    }
    return NULL;          // (8) return page table entry
#endif
    // 注意页目录表和页表存的都是物理地址，（如果是虚拟地址的话陷入循环了）
    // 但是操作系统代码里要虚拟地址，CPU可以帮忙转
    pte_t *result = NULL;
  105777:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    pde_t *pdep = &pgdir[PDX(la)];
  10577e:	8b 45 0c             	mov    0xc(%ebp),%eax
  105781:	c1 e8 16             	shr    $0x16,%eax
  105784:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  10578b:	8b 45 08             	mov    0x8(%ebp),%eax
  10578e:	01 d0                	add    %edx,%eax
  105790:	89 45 e8             	mov    %eax,-0x18(%ebp)
    pte_t *pte_base = NULL;
  105793:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    struct Page *page;
    bool find_pte = 1;
  10579a:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
    if (*pdep & PTE_P) { //存在对应的页表
  1057a1:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1057a4:	8b 00                	mov    (%eax),%eax
  1057a6:	83 e0 01             	and    $0x1,%eax
  1057a9:	85 c0                	test   %eax,%eax
  1057ab:	74 53                	je     105800 <get_pte+0x8f>
        pte_base = KADDR(*pdep & ~0xFFF); 
  1057ad:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1057b0:	8b 00                	mov    (%eax),%eax
  1057b2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1057b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1057ba:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1057bd:	c1 e8 0c             	shr    $0xc,%eax
  1057c0:	89 45 e0             	mov    %eax,-0x20(%ebp)
  1057c3:	a1 a0 56 12 00       	mov    0x1256a0,%eax
  1057c8:	39 45 e0             	cmp    %eax,-0x20(%ebp)
  1057cb:	72 23                	jb     1057f0 <get_pte+0x7f>
  1057cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1057d0:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1057d4:	c7 44 24 08 ec 81 10 	movl   $0x1081ec,0x8(%esp)
  1057db:	00 
  1057dc:	c7 44 24 04 7d 01 00 	movl   $0x17d,0x4(%esp)
  1057e3:	00 
  1057e4:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  1057eb:	e8 ee b4 ff ff       	call   100cde <__panic>
  1057f0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1057f3:	2d 00 00 00 40       	sub    $0x40000000,%eax
  1057f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1057fb:	e9 c2 00 00 00       	jmp    1058c2 <get_pte+0x151>
    } 
    else if (create && (page = alloc_page()) != NULL) { //不存在对应的页表，但允许分配
  105800:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105804:	0f 84 b1 00 00 00    	je     1058bb <get_pte+0x14a>
  10580a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  105811:	e8 84 f8 ff ff       	call   10509a <alloc_pages>
  105816:	89 45 dc             	mov    %eax,-0x24(%ebp)
  105819:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  10581d:	0f 84 98 00 00 00    	je     1058bb <get_pte+0x14a>
        set_page_ref(page, 1);
  105823:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10582a:	00 
  10582b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10582e:	89 04 24             	mov    %eax,(%esp)
  105831:	e8 69 f6 ff ff       	call   104e9f <set_page_ref>
        *pdep = page2pa(page);
  105836:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105839:	89 04 24             	mov    %eax,(%esp)
  10583c:	e8 45 f5 ff ff       	call   104d86 <page2pa>
  105841:	8b 55 e8             	mov    -0x18(%ebp),%edx
  105844:	89 02                	mov    %eax,(%edx)
        pte_base = KADDR(*pdep);
  105846:	8b 45 e8             	mov    -0x18(%ebp),%eax
  105849:	8b 00                	mov    (%eax),%eax
  10584b:	89 45 d8             	mov    %eax,-0x28(%ebp)
  10584e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105851:	c1 e8 0c             	shr    $0xc,%eax
  105854:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  105857:	a1 a0 56 12 00       	mov    0x1256a0,%eax
  10585c:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
  10585f:	72 23                	jb     105884 <get_pte+0x113>
  105861:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105864:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105868:	c7 44 24 08 ec 81 10 	movl   $0x1081ec,0x8(%esp)
  10586f:	00 
  105870:	c7 44 24 04 82 01 00 	movl   $0x182,0x4(%esp)
  105877:	00 
  105878:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  10587f:	e8 5a b4 ff ff       	call   100cde <__panic>
  105884:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105887:	2d 00 00 00 40       	sub    $0x40000000,%eax
  10588c:	89 45 f0             	mov    %eax,-0x10(%ebp)
        memset(pte_base, 0, PGSIZE);
  10588f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105896:	00 
  105897:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10589e:	00 
  10589f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1058a2:	89 04 24             	mov    %eax,(%esp)
  1058a5:	e8 bd 18 00 00       	call   107167 <memset>
        *pdep = *pdep | PTE_P | PTE_W | PTE_U;
  1058aa:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1058ad:	8b 00                	mov    (%eax),%eax
  1058af:	83 c8 07             	or     $0x7,%eax
  1058b2:	89 c2                	mov    %eax,%edx
  1058b4:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1058b7:	89 10                	mov    %edx,(%eax)
  1058b9:	eb 07                	jmp    1058c2 <get_pte+0x151>
    }
    else {
        find_pte = 0;
  1058bb:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
    }
    if (find_pte) {
  1058c2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1058c6:	74 1a                	je     1058e2 <get_pte+0x171>
        result = &pte_base[PTX(la)];
  1058c8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1058cb:	c1 e8 0c             	shr    $0xc,%eax
  1058ce:	25 ff 03 00 00       	and    $0x3ff,%eax
  1058d3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  1058da:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1058dd:	01 d0                	add    %edx,%eax
  1058df:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }
    return result;
  1058e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1058e5:	c9                   	leave  
  1058e6:	c3                   	ret    

001058e7 <get_page>:

//get_page - get related Page struct for linear address la using PDT pgdir
struct Page *
get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
  1058e7:	55                   	push   %ebp
  1058e8:	89 e5                	mov    %esp,%ebp
  1058ea:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
  1058ed:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1058f4:	00 
  1058f5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1058f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1058fc:	8b 45 08             	mov    0x8(%ebp),%eax
  1058ff:	89 04 24             	mov    %eax,(%esp)
  105902:	e8 6a fe ff ff       	call   105771 <get_pte>
  105907:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep_store != NULL) {
  10590a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10590e:	74 08                	je     105918 <get_page+0x31>
        *ptep_store = ptep;
  105910:	8b 45 10             	mov    0x10(%ebp),%eax
  105913:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105916:	89 10                	mov    %edx,(%eax)
    }
    if (ptep != NULL && *ptep & PTE_P) {
  105918:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10591c:	74 1b                	je     105939 <get_page+0x52>
  10591e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105921:	8b 00                	mov    (%eax),%eax
  105923:	83 e0 01             	and    $0x1,%eax
  105926:	85 c0                	test   %eax,%eax
  105928:	74 0f                	je     105939 <get_page+0x52>
        return pte2page(*ptep);
  10592a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10592d:	8b 00                	mov    (%eax),%eax
  10592f:	89 04 24             	mov    %eax,(%esp)
  105932:	e8 08 f5 ff ff       	call   104e3f <pte2page>
  105937:	eb 05                	jmp    10593e <get_page+0x57>
    }
    return NULL;
  105939:	b8 00 00 00 00       	mov    $0x0,%eax
}
  10593e:	c9                   	leave  
  10593f:	c3                   	ret    

00105940 <page_remove_pte>:

//page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
//note: PT is changed, so the TLB need to be invalidate 
static inline void
page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
  105940:	55                   	push   %ebp
  105941:	89 e5                	mov    %esp,%ebp
  105943:	83 ec 28             	sub    $0x28,%esp
                                  //(4) and free this page when page reference reachs 0
                                  //(5) clear second page table entry
                                  //(6) flush tlb
    }
#endif
    if (!(*ptep & PTE_P)) {
  105946:	8b 45 10             	mov    0x10(%ebp),%eax
  105949:	8b 00                	mov    (%eax),%eax
  10594b:	83 e0 01             	and    $0x1,%eax
  10594e:	85 c0                	test   %eax,%eax
  105950:	75 02                	jne    105954 <page_remove_pte+0x14>
        return;
  105952:	eb 53                	jmp    1059a7 <page_remove_pte+0x67>
    }
    struct Page *page = pte2page(*ptep);
  105954:	8b 45 10             	mov    0x10(%ebp),%eax
  105957:	8b 00                	mov    (%eax),%eax
  105959:	89 04 24             	mov    %eax,(%esp)
  10595c:	e8 de f4 ff ff       	call   104e3f <pte2page>
  105961:	89 45 f4             	mov    %eax,-0xc(%ebp)
    page_ref_dec(page);
  105964:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105967:	89 04 24             	mov    %eax,(%esp)
  10596a:	e8 54 f5 ff ff       	call   104ec3 <page_ref_dec>
    if (page->ref <= 0) {
  10596f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105972:	8b 00                	mov    (%eax),%eax
  105974:	85 c0                	test   %eax,%eax
  105976:	7f 13                	jg     10598b <page_remove_pte+0x4b>
        free_page(page);
  105978:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10597f:	00 
  105980:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105983:	89 04 24             	mov    %eax,(%esp)
  105986:	e8 47 f7 ff ff       	call   1050d2 <free_pages>
    }
    *ptep = 0;
  10598b:	8b 45 10             	mov    0x10(%ebp),%eax
  10598e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    tlb_invalidate(pgdir, la);
  105994:	8b 45 0c             	mov    0xc(%ebp),%eax
  105997:	89 44 24 04          	mov    %eax,0x4(%esp)
  10599b:	8b 45 08             	mov    0x8(%ebp),%eax
  10599e:	89 04 24             	mov    %eax,(%esp)
  1059a1:	e8 00 01 00 00       	call   105aa6 <tlb_invalidate>
    return;
  1059a6:	90                   	nop
}
  1059a7:	c9                   	leave  
  1059a8:	c3                   	ret    

001059a9 <page_remove>:

//page_remove - free an Page which is related linear address la and has an validated pte
void
page_remove(pde_t *pgdir, uintptr_t la) {
  1059a9:	55                   	push   %ebp
  1059aa:	89 e5                	mov    %esp,%ebp
  1059ac:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
  1059af:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1059b6:	00 
  1059b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1059ba:	89 44 24 04          	mov    %eax,0x4(%esp)
  1059be:	8b 45 08             	mov    0x8(%ebp),%eax
  1059c1:	89 04 24             	mov    %eax,(%esp)
  1059c4:	e8 a8 fd ff ff       	call   105771 <get_pte>
  1059c9:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep != NULL) {
  1059cc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1059d0:	74 19                	je     1059eb <page_remove+0x42>
        page_remove_pte(pgdir, la, ptep);
  1059d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1059d5:	89 44 24 08          	mov    %eax,0x8(%esp)
  1059d9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1059dc:	89 44 24 04          	mov    %eax,0x4(%esp)
  1059e0:	8b 45 08             	mov    0x8(%ebp),%eax
  1059e3:	89 04 24             	mov    %eax,(%esp)
  1059e6:	e8 55 ff ff ff       	call   105940 <page_remove_pte>
    }
}
  1059eb:	c9                   	leave  
  1059ec:	c3                   	ret    

001059ed <page_insert>:
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
//note: PT is changed, so the TLB need to be invalidate 
int
page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
  1059ed:	55                   	push   %ebp
  1059ee:	89 e5                	mov    %esp,%ebp
  1059f0:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 1);
  1059f3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  1059fa:	00 
  1059fb:	8b 45 10             	mov    0x10(%ebp),%eax
  1059fe:	89 44 24 04          	mov    %eax,0x4(%esp)
  105a02:	8b 45 08             	mov    0x8(%ebp),%eax
  105a05:	89 04 24             	mov    %eax,(%esp)
  105a08:	e8 64 fd ff ff       	call   105771 <get_pte>
  105a0d:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep == NULL) {
  105a10:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  105a14:	75 0a                	jne    105a20 <page_insert+0x33>
        return -E_NO_MEM;
  105a16:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
  105a1b:	e9 84 00 00 00       	jmp    105aa4 <page_insert+0xb7>
    }
    page_ref_inc(page);
  105a20:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a23:	89 04 24             	mov    %eax,(%esp)
  105a26:	e8 81 f4 ff ff       	call   104eac <page_ref_inc>
    if (*ptep & PTE_P) {
  105a2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105a2e:	8b 00                	mov    (%eax),%eax
  105a30:	83 e0 01             	and    $0x1,%eax
  105a33:	85 c0                	test   %eax,%eax
  105a35:	74 3e                	je     105a75 <page_insert+0x88>
        struct Page *p = pte2page(*ptep);
  105a37:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105a3a:	8b 00                	mov    (%eax),%eax
  105a3c:	89 04 24             	mov    %eax,(%esp)
  105a3f:	e8 fb f3 ff ff       	call   104e3f <pte2page>
  105a44:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (p == page) {
  105a47:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105a4a:	3b 45 0c             	cmp    0xc(%ebp),%eax
  105a4d:	75 0d                	jne    105a5c <page_insert+0x6f>
            page_ref_dec(page);
  105a4f:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a52:	89 04 24             	mov    %eax,(%esp)
  105a55:	e8 69 f4 ff ff       	call   104ec3 <page_ref_dec>
  105a5a:	eb 19                	jmp    105a75 <page_insert+0x88>
        }
        else {
            page_remove_pte(pgdir, la, ptep);
  105a5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105a5f:	89 44 24 08          	mov    %eax,0x8(%esp)
  105a63:	8b 45 10             	mov    0x10(%ebp),%eax
  105a66:	89 44 24 04          	mov    %eax,0x4(%esp)
  105a6a:	8b 45 08             	mov    0x8(%ebp),%eax
  105a6d:	89 04 24             	mov    %eax,(%esp)
  105a70:	e8 cb fe ff ff       	call   105940 <page_remove_pte>
        }
    }
    *ptep = page2pa(page) | PTE_P | perm;
  105a75:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a78:	89 04 24             	mov    %eax,(%esp)
  105a7b:	e8 06 f3 ff ff       	call   104d86 <page2pa>
  105a80:	0b 45 14             	or     0x14(%ebp),%eax
  105a83:	83 c8 01             	or     $0x1,%eax
  105a86:	89 c2                	mov    %eax,%edx
  105a88:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105a8b:	89 10                	mov    %edx,(%eax)
    tlb_invalidate(pgdir, la);
  105a8d:	8b 45 10             	mov    0x10(%ebp),%eax
  105a90:	89 44 24 04          	mov    %eax,0x4(%esp)
  105a94:	8b 45 08             	mov    0x8(%ebp),%eax
  105a97:	89 04 24             	mov    %eax,(%esp)
  105a9a:	e8 07 00 00 00       	call   105aa6 <tlb_invalidate>
    return 0;
  105a9f:	b8 00 00 00 00       	mov    $0x0,%eax
}
  105aa4:	c9                   	leave  
  105aa5:	c3                   	ret    

00105aa6 <tlb_invalidate>:

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void
tlb_invalidate(pde_t *pgdir, uintptr_t la) {
  105aa6:	55                   	push   %ebp
  105aa7:	89 e5                	mov    %esp,%ebp
  105aa9:	83 ec 28             	sub    $0x28,%esp
}

static inline uintptr_t
rcr3(void) {
    uintptr_t cr3;
    asm volatile ("mov %%cr3, %0" : "=r" (cr3) :: "memory");
  105aac:	0f 20 d8             	mov    %cr3,%eax
  105aaf:	89 45 f0             	mov    %eax,-0x10(%ebp)
    return cr3;
  105ab2:	8b 45 f0             	mov    -0x10(%ebp),%eax
    if (rcr3() == PADDR(pgdir)) {
  105ab5:	89 c2                	mov    %eax,%edx
  105ab7:	8b 45 08             	mov    0x8(%ebp),%eax
  105aba:	89 45 f4             	mov    %eax,-0xc(%ebp)
  105abd:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
  105ac4:	77 23                	ja     105ae9 <tlb_invalidate+0x43>
  105ac6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105ac9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105acd:	c7 44 24 08 90 82 10 	movl   $0x108290,0x8(%esp)
  105ad4:	00 
  105ad5:	c7 44 24 04 f1 01 00 	movl   $0x1f1,0x4(%esp)
  105adc:	00 
  105add:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105ae4:	e8 f5 b1 ff ff       	call   100cde <__panic>
  105ae9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105aec:	05 00 00 00 40       	add    $0x40000000,%eax
  105af1:	39 c2                	cmp    %eax,%edx
  105af3:	75 0c                	jne    105b01 <tlb_invalidate+0x5b>
        invlpg((void *)la);
  105af5:	8b 45 0c             	mov    0xc(%ebp),%eax
  105af8:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

static inline void
invlpg(void *addr) {
    asm volatile ("invlpg (%0)" :: "r" (addr) : "memory");
  105afb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105afe:	0f 01 38             	invlpg (%eax)
    }
}
  105b01:	c9                   	leave  
  105b02:	c3                   	ret    

00105b03 <check_alloc_page>:

static void
check_alloc_page(void) {
  105b03:	55                   	push   %ebp
  105b04:	89 e5                	mov    %esp,%ebp
  105b06:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->check();
  105b09:	a1 f4 57 12 00       	mov    0x1257f4,%eax
  105b0e:	8b 40 18             	mov    0x18(%eax),%eax
  105b11:	ff d0                	call   *%eax
    cprintf("check_alloc_page() succeeded!\n");
  105b13:	c7 04 24 3c 83 10 00 	movl   $0x10833c,(%esp)
  105b1a:	e8 35 a8 ff ff       	call   100354 <cprintf>
}
  105b1f:	c9                   	leave  
  105b20:	c3                   	ret    

00105b21 <check_pgdir>:

static void
check_pgdir(void) {
  105b21:	55                   	push   %ebp
  105b22:	89 e5                	mov    %esp,%ebp
  105b24:	83 ec 38             	sub    $0x38,%esp
    assert(npage <= KMEMSIZE / PGSIZE);
  105b27:	a1 a0 56 12 00       	mov    0x1256a0,%eax
  105b2c:	3d 00 80 03 00       	cmp    $0x38000,%eax
  105b31:	76 24                	jbe    105b57 <check_pgdir+0x36>
  105b33:	c7 44 24 0c 5b 83 10 	movl   $0x10835b,0xc(%esp)
  105b3a:	00 
  105b3b:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105b42:	00 
  105b43:	c7 44 24 04 fe 01 00 	movl   $0x1fe,0x4(%esp)
  105b4a:	00 
  105b4b:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105b52:	e8 87 b1 ff ff       	call   100cde <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
  105b57:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  105b5c:	85 c0                	test   %eax,%eax
  105b5e:	74 0e                	je     105b6e <check_pgdir+0x4d>
  105b60:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  105b65:	25 ff 0f 00 00       	and    $0xfff,%eax
  105b6a:	85 c0                	test   %eax,%eax
  105b6c:	74 24                	je     105b92 <check_pgdir+0x71>
  105b6e:	c7 44 24 0c 78 83 10 	movl   $0x108378,0xc(%esp)
  105b75:	00 
  105b76:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105b7d:	00 
  105b7e:	c7 44 24 04 ff 01 00 	movl   $0x1ff,0x4(%esp)
  105b85:	00 
  105b86:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105b8d:	e8 4c b1 ff ff       	call   100cde <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
  105b92:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  105b97:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105b9e:	00 
  105b9f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  105ba6:	00 
  105ba7:	89 04 24             	mov    %eax,(%esp)
  105baa:	e8 38 fd ff ff       	call   1058e7 <get_page>
  105baf:	85 c0                	test   %eax,%eax
  105bb1:	74 24                	je     105bd7 <check_pgdir+0xb6>
  105bb3:	c7 44 24 0c b0 83 10 	movl   $0x1083b0,0xc(%esp)
  105bba:	00 
  105bbb:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105bc2:	00 
  105bc3:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
  105bca:	00 
  105bcb:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105bd2:	e8 07 b1 ff ff       	call   100cde <__panic>

    struct Page *p1, *p2;
    p1 = alloc_page();
  105bd7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  105bde:	e8 b7 f4 ff ff       	call   10509a <alloc_pages>
  105be3:	89 45 f4             	mov    %eax,-0xc(%ebp)
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
  105be6:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  105beb:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105bf2:	00 
  105bf3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105bfa:	00 
  105bfb:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105bfe:	89 54 24 04          	mov    %edx,0x4(%esp)
  105c02:	89 04 24             	mov    %eax,(%esp)
  105c05:	e8 e3 fd ff ff       	call   1059ed <page_insert>
  105c0a:	85 c0                	test   %eax,%eax
  105c0c:	74 24                	je     105c32 <check_pgdir+0x111>
  105c0e:	c7 44 24 0c d8 83 10 	movl   $0x1083d8,0xc(%esp)
  105c15:	00 
  105c16:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105c1d:	00 
  105c1e:	c7 44 24 04 04 02 00 	movl   $0x204,0x4(%esp)
  105c25:	00 
  105c26:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105c2d:	e8 ac b0 ff ff       	call   100cde <__panic>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
  105c32:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  105c37:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105c3e:	00 
  105c3f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  105c46:	00 
  105c47:	89 04 24             	mov    %eax,(%esp)
  105c4a:	e8 22 fb ff ff       	call   105771 <get_pte>
  105c4f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105c52:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  105c56:	75 24                	jne    105c7c <check_pgdir+0x15b>
  105c58:	c7 44 24 0c 04 84 10 	movl   $0x108404,0xc(%esp)
  105c5f:	00 
  105c60:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105c67:	00 
  105c68:	c7 44 24 04 07 02 00 	movl   $0x207,0x4(%esp)
  105c6f:	00 
  105c70:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105c77:	e8 62 b0 ff ff       	call   100cde <__panic>
    assert(pte2page(*ptep) == p1);
  105c7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105c7f:	8b 00                	mov    (%eax),%eax
  105c81:	89 04 24             	mov    %eax,(%esp)
  105c84:	e8 b6 f1 ff ff       	call   104e3f <pte2page>
  105c89:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  105c8c:	74 24                	je     105cb2 <check_pgdir+0x191>
  105c8e:	c7 44 24 0c 31 84 10 	movl   $0x108431,0xc(%esp)
  105c95:	00 
  105c96:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105c9d:	00 
  105c9e:	c7 44 24 04 08 02 00 	movl   $0x208,0x4(%esp)
  105ca5:	00 
  105ca6:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105cad:	e8 2c b0 ff ff       	call   100cde <__panic>
    assert(page_ref(p1) == 1);
  105cb2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105cb5:	89 04 24             	mov    %eax,(%esp)
  105cb8:	e8 d8 f1 ff ff       	call   104e95 <page_ref>
  105cbd:	83 f8 01             	cmp    $0x1,%eax
  105cc0:	74 24                	je     105ce6 <check_pgdir+0x1c5>
  105cc2:	c7 44 24 0c 47 84 10 	movl   $0x108447,0xc(%esp)
  105cc9:	00 
  105cca:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105cd1:	00 
  105cd2:	c7 44 24 04 09 02 00 	movl   $0x209,0x4(%esp)
  105cd9:	00 
  105cda:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105ce1:	e8 f8 af ff ff       	call   100cde <__panic>

    ptep = &((pte_t *)KADDR(PDE_ADDR(boot_pgdir[0])))[1];
  105ce6:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  105ceb:	8b 00                	mov    (%eax),%eax
  105ced:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105cf2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  105cf5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105cf8:	c1 e8 0c             	shr    $0xc,%eax
  105cfb:	89 45 e8             	mov    %eax,-0x18(%ebp)
  105cfe:	a1 a0 56 12 00       	mov    0x1256a0,%eax
  105d03:	39 45 e8             	cmp    %eax,-0x18(%ebp)
  105d06:	72 23                	jb     105d2b <check_pgdir+0x20a>
  105d08:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105d0b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105d0f:	c7 44 24 08 ec 81 10 	movl   $0x1081ec,0x8(%esp)
  105d16:	00 
  105d17:	c7 44 24 04 0b 02 00 	movl   $0x20b,0x4(%esp)
  105d1e:	00 
  105d1f:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105d26:	e8 b3 af ff ff       	call   100cde <__panic>
  105d2b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105d2e:	2d 00 00 00 40       	sub    $0x40000000,%eax
  105d33:	83 c0 04             	add    $0x4,%eax
  105d36:	89 45 f0             	mov    %eax,-0x10(%ebp)
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
  105d39:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  105d3e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105d45:	00 
  105d46:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  105d4d:	00 
  105d4e:	89 04 24             	mov    %eax,(%esp)
  105d51:	e8 1b fa ff ff       	call   105771 <get_pte>
  105d56:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  105d59:	74 24                	je     105d7f <check_pgdir+0x25e>
  105d5b:	c7 44 24 0c 5c 84 10 	movl   $0x10845c,0xc(%esp)
  105d62:	00 
  105d63:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105d6a:	00 
  105d6b:	c7 44 24 04 0c 02 00 	movl   $0x20c,0x4(%esp)
  105d72:	00 
  105d73:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105d7a:	e8 5f af ff ff       	call   100cde <__panic>

    p2 = alloc_page();
  105d7f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  105d86:	e8 0f f3 ff ff       	call   10509a <alloc_pages>
  105d8b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
  105d8e:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  105d93:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  105d9a:	00 
  105d9b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105da2:	00 
  105da3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  105da6:	89 54 24 04          	mov    %edx,0x4(%esp)
  105daa:	89 04 24             	mov    %eax,(%esp)
  105dad:	e8 3b fc ff ff       	call   1059ed <page_insert>
  105db2:	85 c0                	test   %eax,%eax
  105db4:	74 24                	je     105dda <check_pgdir+0x2b9>
  105db6:	c7 44 24 0c 84 84 10 	movl   $0x108484,0xc(%esp)
  105dbd:	00 
  105dbe:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105dc5:	00 
  105dc6:	c7 44 24 04 0f 02 00 	movl   $0x20f,0x4(%esp)
  105dcd:	00 
  105dce:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105dd5:	e8 04 af ff ff       	call   100cde <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
  105dda:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  105ddf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105de6:	00 
  105de7:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  105dee:	00 
  105def:	89 04 24             	mov    %eax,(%esp)
  105df2:	e8 7a f9 ff ff       	call   105771 <get_pte>
  105df7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105dfa:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  105dfe:	75 24                	jne    105e24 <check_pgdir+0x303>
  105e00:	c7 44 24 0c bc 84 10 	movl   $0x1084bc,0xc(%esp)
  105e07:	00 
  105e08:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105e0f:	00 
  105e10:	c7 44 24 04 10 02 00 	movl   $0x210,0x4(%esp)
  105e17:	00 
  105e18:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105e1f:	e8 ba ae ff ff       	call   100cde <__panic>
    assert(*ptep & PTE_U);
  105e24:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105e27:	8b 00                	mov    (%eax),%eax
  105e29:	83 e0 04             	and    $0x4,%eax
  105e2c:	85 c0                	test   %eax,%eax
  105e2e:	75 24                	jne    105e54 <check_pgdir+0x333>
  105e30:	c7 44 24 0c ec 84 10 	movl   $0x1084ec,0xc(%esp)
  105e37:	00 
  105e38:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105e3f:	00 
  105e40:	c7 44 24 04 11 02 00 	movl   $0x211,0x4(%esp)
  105e47:	00 
  105e48:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105e4f:	e8 8a ae ff ff       	call   100cde <__panic>
    assert(*ptep & PTE_W);
  105e54:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105e57:	8b 00                	mov    (%eax),%eax
  105e59:	83 e0 02             	and    $0x2,%eax
  105e5c:	85 c0                	test   %eax,%eax
  105e5e:	75 24                	jne    105e84 <check_pgdir+0x363>
  105e60:	c7 44 24 0c fa 84 10 	movl   $0x1084fa,0xc(%esp)
  105e67:	00 
  105e68:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105e6f:	00 
  105e70:	c7 44 24 04 12 02 00 	movl   $0x212,0x4(%esp)
  105e77:	00 
  105e78:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105e7f:	e8 5a ae ff ff       	call   100cde <__panic>
    assert(boot_pgdir[0] & PTE_U);
  105e84:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  105e89:	8b 00                	mov    (%eax),%eax
  105e8b:	83 e0 04             	and    $0x4,%eax
  105e8e:	85 c0                	test   %eax,%eax
  105e90:	75 24                	jne    105eb6 <check_pgdir+0x395>
  105e92:	c7 44 24 0c 08 85 10 	movl   $0x108508,0xc(%esp)
  105e99:	00 
  105e9a:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105ea1:	00 
  105ea2:	c7 44 24 04 13 02 00 	movl   $0x213,0x4(%esp)
  105ea9:	00 
  105eaa:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105eb1:	e8 28 ae ff ff       	call   100cde <__panic>
    assert(page_ref(p2) == 1);
  105eb6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105eb9:	89 04 24             	mov    %eax,(%esp)
  105ebc:	e8 d4 ef ff ff       	call   104e95 <page_ref>
  105ec1:	83 f8 01             	cmp    $0x1,%eax
  105ec4:	74 24                	je     105eea <check_pgdir+0x3c9>
  105ec6:	c7 44 24 0c 1e 85 10 	movl   $0x10851e,0xc(%esp)
  105ecd:	00 
  105ece:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105ed5:	00 
  105ed6:	c7 44 24 04 14 02 00 	movl   $0x214,0x4(%esp)
  105edd:	00 
  105ede:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105ee5:	e8 f4 ad ff ff       	call   100cde <__panic>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
  105eea:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  105eef:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105ef6:	00 
  105ef7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105efe:	00 
  105eff:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105f02:	89 54 24 04          	mov    %edx,0x4(%esp)
  105f06:	89 04 24             	mov    %eax,(%esp)
  105f09:	e8 df fa ff ff       	call   1059ed <page_insert>
  105f0e:	85 c0                	test   %eax,%eax
  105f10:	74 24                	je     105f36 <check_pgdir+0x415>
  105f12:	c7 44 24 0c 30 85 10 	movl   $0x108530,0xc(%esp)
  105f19:	00 
  105f1a:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105f21:	00 
  105f22:	c7 44 24 04 16 02 00 	movl   $0x216,0x4(%esp)
  105f29:	00 
  105f2a:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105f31:	e8 a8 ad ff ff       	call   100cde <__panic>
    assert(page_ref(p1) == 2);
  105f36:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105f39:	89 04 24             	mov    %eax,(%esp)
  105f3c:	e8 54 ef ff ff       	call   104e95 <page_ref>
  105f41:	83 f8 02             	cmp    $0x2,%eax
  105f44:	74 24                	je     105f6a <check_pgdir+0x449>
  105f46:	c7 44 24 0c 5c 85 10 	movl   $0x10855c,0xc(%esp)
  105f4d:	00 
  105f4e:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105f55:	00 
  105f56:	c7 44 24 04 17 02 00 	movl   $0x217,0x4(%esp)
  105f5d:	00 
  105f5e:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105f65:	e8 74 ad ff ff       	call   100cde <__panic>
    assert(page_ref(p2) == 0);
  105f6a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105f6d:	89 04 24             	mov    %eax,(%esp)
  105f70:	e8 20 ef ff ff       	call   104e95 <page_ref>
  105f75:	85 c0                	test   %eax,%eax
  105f77:	74 24                	je     105f9d <check_pgdir+0x47c>
  105f79:	c7 44 24 0c 6e 85 10 	movl   $0x10856e,0xc(%esp)
  105f80:	00 
  105f81:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105f88:	00 
  105f89:	c7 44 24 04 18 02 00 	movl   $0x218,0x4(%esp)
  105f90:	00 
  105f91:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105f98:	e8 41 ad ff ff       	call   100cde <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
  105f9d:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  105fa2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105fa9:	00 
  105faa:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  105fb1:	00 
  105fb2:	89 04 24             	mov    %eax,(%esp)
  105fb5:	e8 b7 f7 ff ff       	call   105771 <get_pte>
  105fba:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105fbd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  105fc1:	75 24                	jne    105fe7 <check_pgdir+0x4c6>
  105fc3:	c7 44 24 0c bc 84 10 	movl   $0x1084bc,0xc(%esp)
  105fca:	00 
  105fcb:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  105fd2:	00 
  105fd3:	c7 44 24 04 19 02 00 	movl   $0x219,0x4(%esp)
  105fda:	00 
  105fdb:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  105fe2:	e8 f7 ac ff ff       	call   100cde <__panic>
    assert(pte2page(*ptep) == p1);
  105fe7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105fea:	8b 00                	mov    (%eax),%eax
  105fec:	89 04 24             	mov    %eax,(%esp)
  105fef:	e8 4b ee ff ff       	call   104e3f <pte2page>
  105ff4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  105ff7:	74 24                	je     10601d <check_pgdir+0x4fc>
  105ff9:	c7 44 24 0c 31 84 10 	movl   $0x108431,0xc(%esp)
  106000:	00 
  106001:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  106008:	00 
  106009:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
  106010:	00 
  106011:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  106018:	e8 c1 ac ff ff       	call   100cde <__panic>
    assert((*ptep & PTE_U) == 0);
  10601d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106020:	8b 00                	mov    (%eax),%eax
  106022:	83 e0 04             	and    $0x4,%eax
  106025:	85 c0                	test   %eax,%eax
  106027:	74 24                	je     10604d <check_pgdir+0x52c>
  106029:	c7 44 24 0c 80 85 10 	movl   $0x108580,0xc(%esp)
  106030:	00 
  106031:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  106038:	00 
  106039:	c7 44 24 04 1b 02 00 	movl   $0x21b,0x4(%esp)
  106040:	00 
  106041:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  106048:	e8 91 ac ff ff       	call   100cde <__panic>

    page_remove(boot_pgdir, 0x0);
  10604d:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  106052:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  106059:	00 
  10605a:	89 04 24             	mov    %eax,(%esp)
  10605d:	e8 47 f9 ff ff       	call   1059a9 <page_remove>
    assert(page_ref(p1) == 1);
  106062:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106065:	89 04 24             	mov    %eax,(%esp)
  106068:	e8 28 ee ff ff       	call   104e95 <page_ref>
  10606d:	83 f8 01             	cmp    $0x1,%eax
  106070:	74 24                	je     106096 <check_pgdir+0x575>
  106072:	c7 44 24 0c 47 84 10 	movl   $0x108447,0xc(%esp)
  106079:	00 
  10607a:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  106081:	00 
  106082:	c7 44 24 04 1e 02 00 	movl   $0x21e,0x4(%esp)
  106089:	00 
  10608a:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  106091:	e8 48 ac ff ff       	call   100cde <__panic>
    assert(page_ref(p2) == 0);
  106096:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  106099:	89 04 24             	mov    %eax,(%esp)
  10609c:	e8 f4 ed ff ff       	call   104e95 <page_ref>
  1060a1:	85 c0                	test   %eax,%eax
  1060a3:	74 24                	je     1060c9 <check_pgdir+0x5a8>
  1060a5:	c7 44 24 0c 6e 85 10 	movl   $0x10856e,0xc(%esp)
  1060ac:	00 
  1060ad:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  1060b4:	00 
  1060b5:	c7 44 24 04 1f 02 00 	movl   $0x21f,0x4(%esp)
  1060bc:	00 
  1060bd:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  1060c4:	e8 15 ac ff ff       	call   100cde <__panic>

    page_remove(boot_pgdir, PGSIZE);
  1060c9:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  1060ce:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  1060d5:	00 
  1060d6:	89 04 24             	mov    %eax,(%esp)
  1060d9:	e8 cb f8 ff ff       	call   1059a9 <page_remove>
    assert(page_ref(p1) == 0);
  1060de:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1060e1:	89 04 24             	mov    %eax,(%esp)
  1060e4:	e8 ac ed ff ff       	call   104e95 <page_ref>
  1060e9:	85 c0                	test   %eax,%eax
  1060eb:	74 24                	je     106111 <check_pgdir+0x5f0>
  1060ed:	c7 44 24 0c 95 85 10 	movl   $0x108595,0xc(%esp)
  1060f4:	00 
  1060f5:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  1060fc:	00 
  1060fd:	c7 44 24 04 22 02 00 	movl   $0x222,0x4(%esp)
  106104:	00 
  106105:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  10610c:	e8 cd ab ff ff       	call   100cde <__panic>
    assert(page_ref(p2) == 0);
  106111:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  106114:	89 04 24             	mov    %eax,(%esp)
  106117:	e8 79 ed ff ff       	call   104e95 <page_ref>
  10611c:	85 c0                	test   %eax,%eax
  10611e:	74 24                	je     106144 <check_pgdir+0x623>
  106120:	c7 44 24 0c 6e 85 10 	movl   $0x10856e,0xc(%esp)
  106127:	00 
  106128:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  10612f:	00 
  106130:	c7 44 24 04 23 02 00 	movl   $0x223,0x4(%esp)
  106137:	00 
  106138:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  10613f:	e8 9a ab ff ff       	call   100cde <__panic>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
  106144:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  106149:	8b 00                	mov    (%eax),%eax
  10614b:	89 04 24             	mov    %eax,(%esp)
  10614e:	e8 2a ed ff ff       	call   104e7d <pde2page>
  106153:	89 04 24             	mov    %eax,(%esp)
  106156:	e8 3a ed ff ff       	call   104e95 <page_ref>
  10615b:	83 f8 01             	cmp    $0x1,%eax
  10615e:	74 24                	je     106184 <check_pgdir+0x663>
  106160:	c7 44 24 0c a8 85 10 	movl   $0x1085a8,0xc(%esp)
  106167:	00 
  106168:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  10616f:	00 
  106170:	c7 44 24 04 25 02 00 	movl   $0x225,0x4(%esp)
  106177:	00 
  106178:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  10617f:	e8 5a ab ff ff       	call   100cde <__panic>
    free_page(pde2page(boot_pgdir[0]));
  106184:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  106189:	8b 00                	mov    (%eax),%eax
  10618b:	89 04 24             	mov    %eax,(%esp)
  10618e:	e8 ea ec ff ff       	call   104e7d <pde2page>
  106193:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10619a:	00 
  10619b:	89 04 24             	mov    %eax,(%esp)
  10619e:	e8 2f ef ff ff       	call   1050d2 <free_pages>
    boot_pgdir[0] = 0;
  1061a3:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  1061a8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_pgdir() succeeded!\n");
  1061ae:	c7 04 24 cf 85 10 00 	movl   $0x1085cf,(%esp)
  1061b5:	e8 9a a1 ff ff       	call   100354 <cprintf>
}
  1061ba:	c9                   	leave  
  1061bb:	c3                   	ret    

001061bc <check_boot_pgdir>:

static void
check_boot_pgdir(void) {
  1061bc:	55                   	push   %ebp
  1061bd:	89 e5                	mov    %esp,%ebp
  1061bf:	83 ec 38             	sub    $0x38,%esp
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
  1061c2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1061c9:	e9 ca 00 00 00       	jmp    106298 <check_boot_pgdir+0xdc>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
  1061ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1061d1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1061d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1061d7:	c1 e8 0c             	shr    $0xc,%eax
  1061da:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1061dd:	a1 a0 56 12 00       	mov    0x1256a0,%eax
  1061e2:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  1061e5:	72 23                	jb     10620a <check_boot_pgdir+0x4e>
  1061e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1061ea:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1061ee:	c7 44 24 08 ec 81 10 	movl   $0x1081ec,0x8(%esp)
  1061f5:	00 
  1061f6:	c7 44 24 04 31 02 00 	movl   $0x231,0x4(%esp)
  1061fd:	00 
  1061fe:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  106205:	e8 d4 aa ff ff       	call   100cde <__panic>
  10620a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10620d:	2d 00 00 00 40       	sub    $0x40000000,%eax
  106212:	89 c2                	mov    %eax,%edx
  106214:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  106219:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  106220:	00 
  106221:	89 54 24 04          	mov    %edx,0x4(%esp)
  106225:	89 04 24             	mov    %eax,(%esp)
  106228:	e8 44 f5 ff ff       	call   105771 <get_pte>
  10622d:	89 45 e8             	mov    %eax,-0x18(%ebp)
  106230:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  106234:	75 24                	jne    10625a <check_boot_pgdir+0x9e>
  106236:	c7 44 24 0c ec 85 10 	movl   $0x1085ec,0xc(%esp)
  10623d:	00 
  10623e:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  106245:	00 
  106246:	c7 44 24 04 31 02 00 	movl   $0x231,0x4(%esp)
  10624d:	00 
  10624e:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  106255:	e8 84 aa ff ff       	call   100cde <__panic>
        assert(PTE_ADDR(*ptep) == i);
  10625a:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10625d:	8b 00                	mov    (%eax),%eax
  10625f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106264:	89 c2                	mov    %eax,%edx
  106266:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106269:	39 c2                	cmp    %eax,%edx
  10626b:	74 24                	je     106291 <check_boot_pgdir+0xd5>
  10626d:	c7 44 24 0c 29 86 10 	movl   $0x108629,0xc(%esp)
  106274:	00 
  106275:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  10627c:	00 
  10627d:	c7 44 24 04 32 02 00 	movl   $0x232,0x4(%esp)
  106284:	00 
  106285:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  10628c:	e8 4d aa ff ff       	call   100cde <__panic>

static void
check_boot_pgdir(void) {
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
  106291:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
  106298:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10629b:	a1 a0 56 12 00       	mov    0x1256a0,%eax
  1062a0:	39 c2                	cmp    %eax,%edx
  1062a2:	0f 82 26 ff ff ff    	jb     1061ce <check_boot_pgdir+0x12>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }

    assert(PDE_ADDR(boot_pgdir[PDX(VPT)]) == PADDR(boot_pgdir));
  1062a8:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  1062ad:	05 ac 0f 00 00       	add    $0xfac,%eax
  1062b2:	8b 00                	mov    (%eax),%eax
  1062b4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1062b9:	89 c2                	mov    %eax,%edx
  1062bb:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  1062c0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1062c3:	81 7d e4 ff ff ff bf 	cmpl   $0xbfffffff,-0x1c(%ebp)
  1062ca:	77 23                	ja     1062ef <check_boot_pgdir+0x133>
  1062cc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1062cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1062d3:	c7 44 24 08 90 82 10 	movl   $0x108290,0x8(%esp)
  1062da:	00 
  1062db:	c7 44 24 04 35 02 00 	movl   $0x235,0x4(%esp)
  1062e2:	00 
  1062e3:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  1062ea:	e8 ef a9 ff ff       	call   100cde <__panic>
  1062ef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1062f2:	05 00 00 00 40       	add    $0x40000000,%eax
  1062f7:	39 c2                	cmp    %eax,%edx
  1062f9:	74 24                	je     10631f <check_boot_pgdir+0x163>
  1062fb:	c7 44 24 0c 40 86 10 	movl   $0x108640,0xc(%esp)
  106302:	00 
  106303:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  10630a:	00 
  10630b:	c7 44 24 04 35 02 00 	movl   $0x235,0x4(%esp)
  106312:	00 
  106313:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  10631a:	e8 bf a9 ff ff       	call   100cde <__panic>

    assert(boot_pgdir[0] == 0);
  10631f:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  106324:	8b 00                	mov    (%eax),%eax
  106326:	85 c0                	test   %eax,%eax
  106328:	74 24                	je     10634e <check_boot_pgdir+0x192>
  10632a:	c7 44 24 0c 74 86 10 	movl   $0x108674,0xc(%esp)
  106331:	00 
  106332:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  106339:	00 
  10633a:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
  106341:	00 
  106342:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  106349:	e8 90 a9 ff ff       	call   100cde <__panic>

    struct Page *p;
    p = alloc_page();
  10634e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  106355:	e8 40 ed ff ff       	call   10509a <alloc_pages>
  10635a:	89 45 e0             	mov    %eax,-0x20(%ebp)
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W) == 0);
  10635d:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  106362:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
  106369:	00 
  10636a:	c7 44 24 08 00 01 00 	movl   $0x100,0x8(%esp)
  106371:	00 
  106372:	8b 55 e0             	mov    -0x20(%ebp),%edx
  106375:	89 54 24 04          	mov    %edx,0x4(%esp)
  106379:	89 04 24             	mov    %eax,(%esp)
  10637c:	e8 6c f6 ff ff       	call   1059ed <page_insert>
  106381:	85 c0                	test   %eax,%eax
  106383:	74 24                	je     1063a9 <check_boot_pgdir+0x1ed>
  106385:	c7 44 24 0c 88 86 10 	movl   $0x108688,0xc(%esp)
  10638c:	00 
  10638d:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  106394:	00 
  106395:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
  10639c:	00 
  10639d:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  1063a4:	e8 35 a9 ff ff       	call   100cde <__panic>
    assert(page_ref(p) == 1);
  1063a9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1063ac:	89 04 24             	mov    %eax,(%esp)
  1063af:	e8 e1 ea ff ff       	call   104e95 <page_ref>
  1063b4:	83 f8 01             	cmp    $0x1,%eax
  1063b7:	74 24                	je     1063dd <check_boot_pgdir+0x221>
  1063b9:	c7 44 24 0c b6 86 10 	movl   $0x1086b6,0xc(%esp)
  1063c0:	00 
  1063c1:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  1063c8:	00 
  1063c9:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
  1063d0:	00 
  1063d1:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  1063d8:	e8 01 a9 ff ff       	call   100cde <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W) == 0);
  1063dd:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  1063e2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
  1063e9:	00 
  1063ea:	c7 44 24 08 00 11 00 	movl   $0x1100,0x8(%esp)
  1063f1:	00 
  1063f2:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1063f5:	89 54 24 04          	mov    %edx,0x4(%esp)
  1063f9:	89 04 24             	mov    %eax,(%esp)
  1063fc:	e8 ec f5 ff ff       	call   1059ed <page_insert>
  106401:	85 c0                	test   %eax,%eax
  106403:	74 24                	je     106429 <check_boot_pgdir+0x26d>
  106405:	c7 44 24 0c c8 86 10 	movl   $0x1086c8,0xc(%esp)
  10640c:	00 
  10640d:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  106414:	00 
  106415:	c7 44 24 04 3d 02 00 	movl   $0x23d,0x4(%esp)
  10641c:	00 
  10641d:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  106424:	e8 b5 a8 ff ff       	call   100cde <__panic>
    assert(page_ref(p) == 2);
  106429:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10642c:	89 04 24             	mov    %eax,(%esp)
  10642f:	e8 61 ea ff ff       	call   104e95 <page_ref>
  106434:	83 f8 02             	cmp    $0x2,%eax
  106437:	74 24                	je     10645d <check_boot_pgdir+0x2a1>
  106439:	c7 44 24 0c ff 86 10 	movl   $0x1086ff,0xc(%esp)
  106440:	00 
  106441:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  106448:	00 
  106449:	c7 44 24 04 3e 02 00 	movl   $0x23e,0x4(%esp)
  106450:	00 
  106451:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  106458:	e8 81 a8 ff ff       	call   100cde <__panic>

    const char *str = "ucore: Hello world!!";
  10645d:	c7 45 dc 10 87 10 00 	movl   $0x108710,-0x24(%ebp)
    strcpy((void *)0x100, str);
  106464:	8b 45 dc             	mov    -0x24(%ebp),%eax
  106467:	89 44 24 04          	mov    %eax,0x4(%esp)
  10646b:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
  106472:	e8 19 0a 00 00       	call   106e90 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
  106477:	c7 44 24 04 00 11 00 	movl   $0x1100,0x4(%esp)
  10647e:	00 
  10647f:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
  106486:	e8 7e 0a 00 00       	call   106f09 <strcmp>
  10648b:	85 c0                	test   %eax,%eax
  10648d:	74 24                	je     1064b3 <check_boot_pgdir+0x2f7>
  10648f:	c7 44 24 0c 28 87 10 	movl   $0x108728,0xc(%esp)
  106496:	00 
  106497:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  10649e:	00 
  10649f:	c7 44 24 04 42 02 00 	movl   $0x242,0x4(%esp)
  1064a6:	00 
  1064a7:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  1064ae:	e8 2b a8 ff ff       	call   100cde <__panic>

    *(char *)(page2kva(p) + 0x100) = '\0';
  1064b3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1064b6:	89 04 24             	mov    %eax,(%esp)
  1064b9:	e8 2d e9 ff ff       	call   104deb <page2kva>
  1064be:	05 00 01 00 00       	add    $0x100,%eax
  1064c3:	c6 00 00             	movb   $0x0,(%eax)
    assert(strlen((const char *)0x100) == 0);
  1064c6:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
  1064cd:	e8 66 09 00 00       	call   106e38 <strlen>
  1064d2:	85 c0                	test   %eax,%eax
  1064d4:	74 24                	je     1064fa <check_boot_pgdir+0x33e>
  1064d6:	c7 44 24 0c 60 87 10 	movl   $0x108760,0xc(%esp)
  1064dd:	00 
  1064de:	c7 44 24 08 00 83 10 	movl   $0x108300,0x8(%esp)
  1064e5:	00 
  1064e6:	c7 44 24 04 45 02 00 	movl   $0x245,0x4(%esp)
  1064ed:	00 
  1064ee:	c7 04 24 b4 82 10 00 	movl   $0x1082b4,(%esp)
  1064f5:	e8 e4 a7 ff ff       	call   100cde <__panic>

    free_page(p);
  1064fa:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  106501:	00 
  106502:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106505:	89 04 24             	mov    %eax,(%esp)
  106508:	e8 c5 eb ff ff       	call   1050d2 <free_pages>
    free_page(pde2page(boot_pgdir[0]));
  10650d:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  106512:	8b 00                	mov    (%eax),%eax
  106514:	89 04 24             	mov    %eax,(%esp)
  106517:	e8 61 e9 ff ff       	call   104e7d <pde2page>
  10651c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  106523:	00 
  106524:	89 04 24             	mov    %eax,(%esp)
  106527:	e8 a6 eb ff ff       	call   1050d2 <free_pages>
    boot_pgdir[0] = 0;
  10652c:	a1 e0 a9 11 00       	mov    0x11a9e0,%eax
  106531:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_boot_pgdir() succeeded!\n");
  106537:	c7 04 24 84 87 10 00 	movl   $0x108784,(%esp)
  10653e:	e8 11 9e ff ff       	call   100354 <cprintf>
}
  106543:	c9                   	leave  
  106544:	c3                   	ret    

00106545 <perm2str>:

//perm2str - use string 'u,r,w,-' to present the permission
static const char *
perm2str(int perm) {
  106545:	55                   	push   %ebp
  106546:	89 e5                	mov    %esp,%ebp
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
  106548:	8b 45 08             	mov    0x8(%ebp),%eax
  10654b:	83 e0 04             	and    $0x4,%eax
  10654e:	85 c0                	test   %eax,%eax
  106550:	74 07                	je     106559 <perm2str+0x14>
  106552:	b8 75 00 00 00       	mov    $0x75,%eax
  106557:	eb 05                	jmp    10655e <perm2str+0x19>
  106559:	b8 2d 00 00 00       	mov    $0x2d,%eax
  10655e:	a2 28 57 12 00       	mov    %al,0x125728
    str[1] = 'r';
  106563:	c6 05 29 57 12 00 72 	movb   $0x72,0x125729
    str[2] = (perm & PTE_W) ? 'w' : '-';
  10656a:	8b 45 08             	mov    0x8(%ebp),%eax
  10656d:	83 e0 02             	and    $0x2,%eax
  106570:	85 c0                	test   %eax,%eax
  106572:	74 07                	je     10657b <perm2str+0x36>
  106574:	b8 77 00 00 00       	mov    $0x77,%eax
  106579:	eb 05                	jmp    106580 <perm2str+0x3b>
  10657b:	b8 2d 00 00 00       	mov    $0x2d,%eax
  106580:	a2 2a 57 12 00       	mov    %al,0x12572a
    str[3] = '\0';
  106585:	c6 05 2b 57 12 00 00 	movb   $0x0,0x12572b
    return str;
  10658c:	b8 28 57 12 00       	mov    $0x125728,%eax
}
  106591:	5d                   	pop    %ebp
  106592:	c3                   	ret    

00106593 <get_pgtable_items>:
//  table:       the beginning addr of table
//  left_store:  the pointer of the high side of table's next range
//  right_store: the pointer of the low side of table's next range
// return value: 0 - not a invalid item range, perm - a valid item range with perm permission 
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
  106593:	55                   	push   %ebp
  106594:	89 e5                	mov    %esp,%ebp
  106596:	83 ec 10             	sub    $0x10,%esp
    if (start >= right) {
  106599:	8b 45 10             	mov    0x10(%ebp),%eax
  10659c:	3b 45 0c             	cmp    0xc(%ebp),%eax
  10659f:	72 0a                	jb     1065ab <get_pgtable_items+0x18>
        return 0;
  1065a1:	b8 00 00 00 00       	mov    $0x0,%eax
  1065a6:	e9 9c 00 00 00       	jmp    106647 <get_pgtable_items+0xb4>
    }
    while (start < right && !(table[start] & PTE_P)) {
  1065ab:	eb 04                	jmp    1065b1 <get_pgtable_items+0x1e>
        start ++;
  1065ad:	83 45 10 01          	addl   $0x1,0x10(%ebp)
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
    if (start >= right) {
        return 0;
    }
    while (start < right && !(table[start] & PTE_P)) {
  1065b1:	8b 45 10             	mov    0x10(%ebp),%eax
  1065b4:	3b 45 0c             	cmp    0xc(%ebp),%eax
  1065b7:	73 18                	jae    1065d1 <get_pgtable_items+0x3e>
  1065b9:	8b 45 10             	mov    0x10(%ebp),%eax
  1065bc:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  1065c3:	8b 45 14             	mov    0x14(%ebp),%eax
  1065c6:	01 d0                	add    %edx,%eax
  1065c8:	8b 00                	mov    (%eax),%eax
  1065ca:	83 e0 01             	and    $0x1,%eax
  1065cd:	85 c0                	test   %eax,%eax
  1065cf:	74 dc                	je     1065ad <get_pgtable_items+0x1a>
        start ++;
    }
    if (start < right) {
  1065d1:	8b 45 10             	mov    0x10(%ebp),%eax
  1065d4:	3b 45 0c             	cmp    0xc(%ebp),%eax
  1065d7:	73 69                	jae    106642 <get_pgtable_items+0xaf>
        if (left_store != NULL) {
  1065d9:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
  1065dd:	74 08                	je     1065e7 <get_pgtable_items+0x54>
            *left_store = start;
  1065df:	8b 45 18             	mov    0x18(%ebp),%eax
  1065e2:	8b 55 10             	mov    0x10(%ebp),%edx
  1065e5:	89 10                	mov    %edx,(%eax)
        }
        int perm = (table[start ++] & PTE_USER);
  1065e7:	8b 45 10             	mov    0x10(%ebp),%eax
  1065ea:	8d 50 01             	lea    0x1(%eax),%edx
  1065ed:	89 55 10             	mov    %edx,0x10(%ebp)
  1065f0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  1065f7:	8b 45 14             	mov    0x14(%ebp),%eax
  1065fa:	01 d0                	add    %edx,%eax
  1065fc:	8b 00                	mov    (%eax),%eax
  1065fe:	83 e0 07             	and    $0x7,%eax
  106601:	89 45 fc             	mov    %eax,-0x4(%ebp)
        while (start < right && (table[start] & PTE_USER) == perm) {
  106604:	eb 04                	jmp    10660a <get_pgtable_items+0x77>
            start ++;
  106606:	83 45 10 01          	addl   $0x1,0x10(%ebp)
    if (start < right) {
        if (left_store != NULL) {
            *left_store = start;
        }
        int perm = (table[start ++] & PTE_USER);
        while (start < right && (table[start] & PTE_USER) == perm) {
  10660a:	8b 45 10             	mov    0x10(%ebp),%eax
  10660d:	3b 45 0c             	cmp    0xc(%ebp),%eax
  106610:	73 1d                	jae    10662f <get_pgtable_items+0x9c>
  106612:	8b 45 10             	mov    0x10(%ebp),%eax
  106615:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  10661c:	8b 45 14             	mov    0x14(%ebp),%eax
  10661f:	01 d0                	add    %edx,%eax
  106621:	8b 00                	mov    (%eax),%eax
  106623:	83 e0 07             	and    $0x7,%eax
  106626:	89 c2                	mov    %eax,%edx
  106628:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10662b:	39 c2                	cmp    %eax,%edx
  10662d:	74 d7                	je     106606 <get_pgtable_items+0x73>
            start ++;
        }
        if (right_store != NULL) {
  10662f:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
  106633:	74 08                	je     10663d <get_pgtable_items+0xaa>
            *right_store = start;
  106635:	8b 45 1c             	mov    0x1c(%ebp),%eax
  106638:	8b 55 10             	mov    0x10(%ebp),%edx
  10663b:	89 10                	mov    %edx,(%eax)
        }
        return perm;
  10663d:	8b 45 fc             	mov    -0x4(%ebp),%eax
  106640:	eb 05                	jmp    106647 <get_pgtable_items+0xb4>
    }
    return 0;
  106642:	b8 00 00 00 00       	mov    $0x0,%eax
}
  106647:	c9                   	leave  
  106648:	c3                   	ret    

00106649 <print_pgdir>:

//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
  106649:	55                   	push   %ebp
  10664a:	89 e5                	mov    %esp,%ebp
  10664c:	57                   	push   %edi
  10664d:	56                   	push   %esi
  10664e:	53                   	push   %ebx
  10664f:	83 ec 4c             	sub    $0x4c,%esp
    cprintf("-------------------- BEGIN --------------------\n");
  106652:	c7 04 24 a4 87 10 00 	movl   $0x1087a4,(%esp)
  106659:	e8 f6 9c ff ff       	call   100354 <cprintf>
    size_t left, right = 0, perm;
  10665e:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
  106665:	e9 fa 00 00 00       	jmp    106764 <print_pgdir+0x11b>
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
  10666a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10666d:	89 04 24             	mov    %eax,(%esp)
  106670:	e8 d0 fe ff ff       	call   106545 <perm2str>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
  106675:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  106678:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10667b:	29 d1                	sub    %edx,%ecx
  10667d:	89 ca                	mov    %ecx,%edx
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
  10667f:	89 d6                	mov    %edx,%esi
  106681:	c1 e6 16             	shl    $0x16,%esi
  106684:	8b 55 dc             	mov    -0x24(%ebp),%edx
  106687:	89 d3                	mov    %edx,%ebx
  106689:	c1 e3 16             	shl    $0x16,%ebx
  10668c:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10668f:	89 d1                	mov    %edx,%ecx
  106691:	c1 e1 16             	shl    $0x16,%ecx
  106694:	8b 7d dc             	mov    -0x24(%ebp),%edi
  106697:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10669a:	29 d7                	sub    %edx,%edi
  10669c:	89 fa                	mov    %edi,%edx
  10669e:	89 44 24 14          	mov    %eax,0x14(%esp)
  1066a2:	89 74 24 10          	mov    %esi,0x10(%esp)
  1066a6:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  1066aa:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1066ae:	89 54 24 04          	mov    %edx,0x4(%esp)
  1066b2:	c7 04 24 d5 87 10 00 	movl   $0x1087d5,(%esp)
  1066b9:	e8 96 9c ff ff       	call   100354 <cprintf>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
  1066be:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1066c1:	c1 e0 0a             	shl    $0xa,%eax
  1066c4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
  1066c7:	eb 54                	jmp    10671d <print_pgdir+0xd4>
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
  1066c9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1066cc:	89 04 24             	mov    %eax,(%esp)
  1066cf:	e8 71 fe ff ff       	call   106545 <perm2str>
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
  1066d4:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  1066d7:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1066da:	29 d1                	sub    %edx,%ecx
  1066dc:	89 ca                	mov    %ecx,%edx
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
  1066de:	89 d6                	mov    %edx,%esi
  1066e0:	c1 e6 0c             	shl    $0xc,%esi
  1066e3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1066e6:	89 d3                	mov    %edx,%ebx
  1066e8:	c1 e3 0c             	shl    $0xc,%ebx
  1066eb:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1066ee:	c1 e2 0c             	shl    $0xc,%edx
  1066f1:	89 d1                	mov    %edx,%ecx
  1066f3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  1066f6:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1066f9:	29 d7                	sub    %edx,%edi
  1066fb:	89 fa                	mov    %edi,%edx
  1066fd:	89 44 24 14          	mov    %eax,0x14(%esp)
  106701:	89 74 24 10          	mov    %esi,0x10(%esp)
  106705:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  106709:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  10670d:	89 54 24 04          	mov    %edx,0x4(%esp)
  106711:	c7 04 24 f4 87 10 00 	movl   $0x1087f4,(%esp)
  106718:	e8 37 9c ff ff       	call   100354 <cprintf>
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
  10671d:	ba 00 00 c0 fa       	mov    $0xfac00000,%edx
  106722:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106725:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  106728:	89 ce                	mov    %ecx,%esi
  10672a:	c1 e6 0a             	shl    $0xa,%esi
  10672d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  106730:	89 cb                	mov    %ecx,%ebx
  106732:	c1 e3 0a             	shl    $0xa,%ebx
  106735:	8d 4d d4             	lea    -0x2c(%ebp),%ecx
  106738:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  10673c:	8d 4d d8             	lea    -0x28(%ebp),%ecx
  10673f:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  106743:	89 54 24 0c          	mov    %edx,0xc(%esp)
  106747:	89 44 24 08          	mov    %eax,0x8(%esp)
  10674b:	89 74 24 04          	mov    %esi,0x4(%esp)
  10674f:	89 1c 24             	mov    %ebx,(%esp)
  106752:	e8 3c fe ff ff       	call   106593 <get_pgtable_items>
  106757:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  10675a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  10675e:	0f 85 65 ff ff ff    	jne    1066c9 <print_pgdir+0x80>
//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
  106764:	ba 00 b0 fe fa       	mov    $0xfafeb000,%edx
  106769:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10676c:	8d 4d dc             	lea    -0x24(%ebp),%ecx
  10676f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  106773:	8d 4d e0             	lea    -0x20(%ebp),%ecx
  106776:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  10677a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10677e:	89 44 24 08          	mov    %eax,0x8(%esp)
  106782:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  106789:	00 
  10678a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  106791:	e8 fd fd ff ff       	call   106593 <get_pgtable_items>
  106796:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  106799:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  10679d:	0f 85 c7 fe ff ff    	jne    10666a <print_pgdir+0x21>
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
        }
    }
    cprintf("--------------------- END ---------------------\n");
  1067a3:	c7 04 24 18 88 10 00 	movl   $0x108818,(%esp)
  1067aa:	e8 a5 9b ff ff       	call   100354 <cprintf>
}
  1067af:	83 c4 4c             	add    $0x4c,%esp
  1067b2:	5b                   	pop    %ebx
  1067b3:	5e                   	pop    %esi
  1067b4:	5f                   	pop    %edi
  1067b5:	5d                   	pop    %ebp
  1067b6:	c3                   	ret    

001067b7 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  1067b7:	55                   	push   %ebp
  1067b8:	89 e5                	mov    %esp,%ebp
  1067ba:	83 ec 58             	sub    $0x58,%esp
  1067bd:	8b 45 10             	mov    0x10(%ebp),%eax
  1067c0:	89 45 d0             	mov    %eax,-0x30(%ebp)
  1067c3:	8b 45 14             	mov    0x14(%ebp),%eax
  1067c6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    unsigned long long result = num;
  1067c9:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1067cc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1067cf:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1067d2:	89 55 ec             	mov    %edx,-0x14(%ebp)
    unsigned mod = do_div(result, base);
  1067d5:	8b 45 18             	mov    0x18(%ebp),%eax
  1067d8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1067db:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1067de:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1067e1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  1067e4:	89 55 f0             	mov    %edx,-0x10(%ebp)
  1067e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1067ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1067ed:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1067f1:	74 1c                	je     10680f <printnum+0x58>
  1067f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1067f6:	ba 00 00 00 00       	mov    $0x0,%edx
  1067fb:	f7 75 e4             	divl   -0x1c(%ebp)
  1067fe:	89 55 f4             	mov    %edx,-0xc(%ebp)
  106801:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106804:	ba 00 00 00 00       	mov    $0x0,%edx
  106809:	f7 75 e4             	divl   -0x1c(%ebp)
  10680c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10680f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106812:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106815:	f7 75 e4             	divl   -0x1c(%ebp)
  106818:	89 45 e0             	mov    %eax,-0x20(%ebp)
  10681b:	89 55 dc             	mov    %edx,-0x24(%ebp)
  10681e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106821:	8b 55 f0             	mov    -0x10(%ebp),%edx
  106824:	89 45 e8             	mov    %eax,-0x18(%ebp)
  106827:	89 55 ec             	mov    %edx,-0x14(%ebp)
  10682a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10682d:	89 45 d8             	mov    %eax,-0x28(%ebp)

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
  106830:	8b 45 18             	mov    0x18(%ebp),%eax
  106833:	ba 00 00 00 00       	mov    $0x0,%edx
  106838:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  10683b:	77 56                	ja     106893 <printnum+0xdc>
  10683d:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  106840:	72 05                	jb     106847 <printnum+0x90>
  106842:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  106845:	77 4c                	ja     106893 <printnum+0xdc>
        printnum(putch, putdat, result, base, width - 1, padc);
  106847:	8b 45 1c             	mov    0x1c(%ebp),%eax
  10684a:	8d 50 ff             	lea    -0x1(%eax),%edx
  10684d:	8b 45 20             	mov    0x20(%ebp),%eax
  106850:	89 44 24 18          	mov    %eax,0x18(%esp)
  106854:	89 54 24 14          	mov    %edx,0x14(%esp)
  106858:	8b 45 18             	mov    0x18(%ebp),%eax
  10685b:	89 44 24 10          	mov    %eax,0x10(%esp)
  10685f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  106862:	8b 55 ec             	mov    -0x14(%ebp),%edx
  106865:	89 44 24 08          	mov    %eax,0x8(%esp)
  106869:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10686d:	8b 45 0c             	mov    0xc(%ebp),%eax
  106870:	89 44 24 04          	mov    %eax,0x4(%esp)
  106874:	8b 45 08             	mov    0x8(%ebp),%eax
  106877:	89 04 24             	mov    %eax,(%esp)
  10687a:	e8 38 ff ff ff       	call   1067b7 <printnum>
  10687f:	eb 1c                	jmp    10689d <printnum+0xe6>
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
            putch(padc, putdat);
  106881:	8b 45 0c             	mov    0xc(%ebp),%eax
  106884:	89 44 24 04          	mov    %eax,0x4(%esp)
  106888:	8b 45 20             	mov    0x20(%ebp),%eax
  10688b:	89 04 24             	mov    %eax,(%esp)
  10688e:	8b 45 08             	mov    0x8(%ebp),%eax
  106891:	ff d0                	call   *%eax
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  106893:	83 6d 1c 01          	subl   $0x1,0x1c(%ebp)
  106897:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
  10689b:	7f e4                	jg     106881 <printnum+0xca>
            putch(padc, putdat);
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  10689d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1068a0:	05 cc 88 10 00       	add    $0x1088cc,%eax
  1068a5:	0f b6 00             	movzbl (%eax),%eax
  1068a8:	0f be c0             	movsbl %al,%eax
  1068ab:	8b 55 0c             	mov    0xc(%ebp),%edx
  1068ae:	89 54 24 04          	mov    %edx,0x4(%esp)
  1068b2:	89 04 24             	mov    %eax,(%esp)
  1068b5:	8b 45 08             	mov    0x8(%ebp),%eax
  1068b8:	ff d0                	call   *%eax
}
  1068ba:	c9                   	leave  
  1068bb:	c3                   	ret    

001068bc <getuint>:
 * getuint - get an unsigned int of various possible sizes from a varargs list
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static unsigned long long
getuint(va_list *ap, int lflag) {
  1068bc:	55                   	push   %ebp
  1068bd:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
  1068bf:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  1068c3:	7e 14                	jle    1068d9 <getuint+0x1d>
        return va_arg(*ap, unsigned long long);
  1068c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1068c8:	8b 00                	mov    (%eax),%eax
  1068ca:	8d 48 08             	lea    0x8(%eax),%ecx
  1068cd:	8b 55 08             	mov    0x8(%ebp),%edx
  1068d0:	89 0a                	mov    %ecx,(%edx)
  1068d2:	8b 50 04             	mov    0x4(%eax),%edx
  1068d5:	8b 00                	mov    (%eax),%eax
  1068d7:	eb 30                	jmp    106909 <getuint+0x4d>
    }
    else if (lflag) {
  1068d9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  1068dd:	74 16                	je     1068f5 <getuint+0x39>
        return va_arg(*ap, unsigned long);
  1068df:	8b 45 08             	mov    0x8(%ebp),%eax
  1068e2:	8b 00                	mov    (%eax),%eax
  1068e4:	8d 48 04             	lea    0x4(%eax),%ecx
  1068e7:	8b 55 08             	mov    0x8(%ebp),%edx
  1068ea:	89 0a                	mov    %ecx,(%edx)
  1068ec:	8b 00                	mov    (%eax),%eax
  1068ee:	ba 00 00 00 00       	mov    $0x0,%edx
  1068f3:	eb 14                	jmp    106909 <getuint+0x4d>
    }
    else {
        return va_arg(*ap, unsigned int);
  1068f5:	8b 45 08             	mov    0x8(%ebp),%eax
  1068f8:	8b 00                	mov    (%eax),%eax
  1068fa:	8d 48 04             	lea    0x4(%eax),%ecx
  1068fd:	8b 55 08             	mov    0x8(%ebp),%edx
  106900:	89 0a                	mov    %ecx,(%edx)
  106902:	8b 00                	mov    (%eax),%eax
  106904:	ba 00 00 00 00       	mov    $0x0,%edx
    }
}
  106909:	5d                   	pop    %ebp
  10690a:	c3                   	ret    

0010690b <getint>:
 * getint - same as getuint but signed, we can't use getuint because of sign extension
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static long long
getint(va_list *ap, int lflag) {
  10690b:	55                   	push   %ebp
  10690c:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
  10690e:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  106912:	7e 14                	jle    106928 <getint+0x1d>
        return va_arg(*ap, long long);
  106914:	8b 45 08             	mov    0x8(%ebp),%eax
  106917:	8b 00                	mov    (%eax),%eax
  106919:	8d 48 08             	lea    0x8(%eax),%ecx
  10691c:	8b 55 08             	mov    0x8(%ebp),%edx
  10691f:	89 0a                	mov    %ecx,(%edx)
  106921:	8b 50 04             	mov    0x4(%eax),%edx
  106924:	8b 00                	mov    (%eax),%eax
  106926:	eb 28                	jmp    106950 <getint+0x45>
    }
    else if (lflag) {
  106928:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  10692c:	74 12                	je     106940 <getint+0x35>
        return va_arg(*ap, long);
  10692e:	8b 45 08             	mov    0x8(%ebp),%eax
  106931:	8b 00                	mov    (%eax),%eax
  106933:	8d 48 04             	lea    0x4(%eax),%ecx
  106936:	8b 55 08             	mov    0x8(%ebp),%edx
  106939:	89 0a                	mov    %ecx,(%edx)
  10693b:	8b 00                	mov    (%eax),%eax
  10693d:	99                   	cltd   
  10693e:	eb 10                	jmp    106950 <getint+0x45>
    }
    else {
        return va_arg(*ap, int);
  106940:	8b 45 08             	mov    0x8(%ebp),%eax
  106943:	8b 00                	mov    (%eax),%eax
  106945:	8d 48 04             	lea    0x4(%eax),%ecx
  106948:	8b 55 08             	mov    0x8(%ebp),%edx
  10694b:	89 0a                	mov    %ecx,(%edx)
  10694d:	8b 00                	mov    (%eax),%eax
  10694f:	99                   	cltd   
    }
}
  106950:	5d                   	pop    %ebp
  106951:	c3                   	ret    

00106952 <printfmt>:
 * @putch:      specified putch function, print a single character
 * @putdat:     used by @putch function
 * @fmt:        the format string to use
 * */
void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  106952:	55                   	push   %ebp
  106953:	89 e5                	mov    %esp,%ebp
  106955:	83 ec 28             	sub    $0x28,%esp
    va_list ap;

    va_start(ap, fmt);
  106958:	8d 45 14             	lea    0x14(%ebp),%eax
  10695b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    vprintfmt(putch, putdat, fmt, ap);
  10695e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106961:	89 44 24 0c          	mov    %eax,0xc(%esp)
  106965:	8b 45 10             	mov    0x10(%ebp),%eax
  106968:	89 44 24 08          	mov    %eax,0x8(%esp)
  10696c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10696f:	89 44 24 04          	mov    %eax,0x4(%esp)
  106973:	8b 45 08             	mov    0x8(%ebp),%eax
  106976:	89 04 24             	mov    %eax,(%esp)
  106979:	e8 02 00 00 00       	call   106980 <vprintfmt>
    va_end(ap);
}
  10697e:	c9                   	leave  
  10697f:	c3                   	ret    

00106980 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  106980:	55                   	push   %ebp
  106981:	89 e5                	mov    %esp,%ebp
  106983:	56                   	push   %esi
  106984:	53                   	push   %ebx
  106985:	83 ec 40             	sub    $0x40,%esp
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  106988:	eb 18                	jmp    1069a2 <vprintfmt+0x22>
            if (ch == '\0') {
  10698a:	85 db                	test   %ebx,%ebx
  10698c:	75 05                	jne    106993 <vprintfmt+0x13>
                return;
  10698e:	e9 d1 03 00 00       	jmp    106d64 <vprintfmt+0x3e4>
            }
            putch(ch, putdat);
  106993:	8b 45 0c             	mov    0xc(%ebp),%eax
  106996:	89 44 24 04          	mov    %eax,0x4(%esp)
  10699a:	89 1c 24             	mov    %ebx,(%esp)
  10699d:	8b 45 08             	mov    0x8(%ebp),%eax
  1069a0:	ff d0                	call   *%eax
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  1069a2:	8b 45 10             	mov    0x10(%ebp),%eax
  1069a5:	8d 50 01             	lea    0x1(%eax),%edx
  1069a8:	89 55 10             	mov    %edx,0x10(%ebp)
  1069ab:	0f b6 00             	movzbl (%eax),%eax
  1069ae:	0f b6 d8             	movzbl %al,%ebx
  1069b1:	83 fb 25             	cmp    $0x25,%ebx
  1069b4:	75 d4                	jne    10698a <vprintfmt+0xa>
            }
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
  1069b6:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
        width = precision = -1;
  1069ba:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  1069c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1069c4:	89 45 e8             	mov    %eax,-0x18(%ebp)
        lflag = altflag = 0;
  1069c7:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  1069ce:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1069d1:	89 45 e0             	mov    %eax,-0x20(%ebp)

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
  1069d4:	8b 45 10             	mov    0x10(%ebp),%eax
  1069d7:	8d 50 01             	lea    0x1(%eax),%edx
  1069da:	89 55 10             	mov    %edx,0x10(%ebp)
  1069dd:	0f b6 00             	movzbl (%eax),%eax
  1069e0:	0f b6 d8             	movzbl %al,%ebx
  1069e3:	8d 43 dd             	lea    -0x23(%ebx),%eax
  1069e6:	83 f8 55             	cmp    $0x55,%eax
  1069e9:	0f 87 44 03 00 00    	ja     106d33 <vprintfmt+0x3b3>
  1069ef:	8b 04 85 f0 88 10 00 	mov    0x1088f0(,%eax,4),%eax
  1069f6:	ff e0                	jmp    *%eax

        // flag to pad on the right
        case '-':
            padc = '-';
  1069f8:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
            goto reswitch;
  1069fc:	eb d6                	jmp    1069d4 <vprintfmt+0x54>

        // flag to pad with 0's instead of spaces
        case '0':
            padc = '0';
  1069fe:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
            goto reswitch;
  106a02:	eb d0                	jmp    1069d4 <vprintfmt+0x54>

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
  106a04:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
                precision = precision * 10 + ch - '0';
  106a0b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  106a0e:	89 d0                	mov    %edx,%eax
  106a10:	c1 e0 02             	shl    $0x2,%eax
  106a13:	01 d0                	add    %edx,%eax
  106a15:	01 c0                	add    %eax,%eax
  106a17:	01 d8                	add    %ebx,%eax
  106a19:	83 e8 30             	sub    $0x30,%eax
  106a1c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
                ch = *fmt;
  106a1f:	8b 45 10             	mov    0x10(%ebp),%eax
  106a22:	0f b6 00             	movzbl (%eax),%eax
  106a25:	0f be d8             	movsbl %al,%ebx
                if (ch < '0' || ch > '9') {
  106a28:	83 fb 2f             	cmp    $0x2f,%ebx
  106a2b:	7e 0b                	jle    106a38 <vprintfmt+0xb8>
  106a2d:	83 fb 39             	cmp    $0x39,%ebx
  106a30:	7f 06                	jg     106a38 <vprintfmt+0xb8>
            padc = '0';
            goto reswitch;

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
  106a32:	83 45 10 01          	addl   $0x1,0x10(%ebp)
                precision = precision * 10 + ch - '0';
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
  106a36:	eb d3                	jmp    106a0b <vprintfmt+0x8b>
            goto process_precision;
  106a38:	eb 33                	jmp    106a6d <vprintfmt+0xed>

        case '*':
            precision = va_arg(ap, int);
  106a3a:	8b 45 14             	mov    0x14(%ebp),%eax
  106a3d:	8d 50 04             	lea    0x4(%eax),%edx
  106a40:	89 55 14             	mov    %edx,0x14(%ebp)
  106a43:	8b 00                	mov    (%eax),%eax
  106a45:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            goto process_precision;
  106a48:	eb 23                	jmp    106a6d <vprintfmt+0xed>

        case '.':
            if (width < 0)
  106a4a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  106a4e:	79 0c                	jns    106a5c <vprintfmt+0xdc>
                width = 0;
  106a50:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
            goto reswitch;
  106a57:	e9 78 ff ff ff       	jmp    1069d4 <vprintfmt+0x54>
  106a5c:	e9 73 ff ff ff       	jmp    1069d4 <vprintfmt+0x54>

        case '#':
            altflag = 1;
  106a61:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
            goto reswitch;
  106a68:	e9 67 ff ff ff       	jmp    1069d4 <vprintfmt+0x54>

        process_precision:
            if (width < 0)
  106a6d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  106a71:	79 12                	jns    106a85 <vprintfmt+0x105>
                width = precision, precision = -1;
  106a73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  106a76:	89 45 e8             	mov    %eax,-0x18(%ebp)
  106a79:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
            goto reswitch;
  106a80:	e9 4f ff ff ff       	jmp    1069d4 <vprintfmt+0x54>
  106a85:	e9 4a ff ff ff       	jmp    1069d4 <vprintfmt+0x54>

        // long flag (doubled for long long)
        case 'l':
            lflag ++;
  106a8a:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
            goto reswitch;
  106a8e:	e9 41 ff ff ff       	jmp    1069d4 <vprintfmt+0x54>

        // character
        case 'c':
            putch(va_arg(ap, int), putdat);
  106a93:	8b 45 14             	mov    0x14(%ebp),%eax
  106a96:	8d 50 04             	lea    0x4(%eax),%edx
  106a99:	89 55 14             	mov    %edx,0x14(%ebp)
  106a9c:	8b 00                	mov    (%eax),%eax
  106a9e:	8b 55 0c             	mov    0xc(%ebp),%edx
  106aa1:	89 54 24 04          	mov    %edx,0x4(%esp)
  106aa5:	89 04 24             	mov    %eax,(%esp)
  106aa8:	8b 45 08             	mov    0x8(%ebp),%eax
  106aab:	ff d0                	call   *%eax
            break;
  106aad:	e9 ac 02 00 00       	jmp    106d5e <vprintfmt+0x3de>

        // error message
        case 'e':
            err = va_arg(ap, int);
  106ab2:	8b 45 14             	mov    0x14(%ebp),%eax
  106ab5:	8d 50 04             	lea    0x4(%eax),%edx
  106ab8:	89 55 14             	mov    %edx,0x14(%ebp)
  106abb:	8b 18                	mov    (%eax),%ebx
            if (err < 0) {
  106abd:	85 db                	test   %ebx,%ebx
  106abf:	79 02                	jns    106ac3 <vprintfmt+0x143>
                err = -err;
  106ac1:	f7 db                	neg    %ebx
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  106ac3:	83 fb 06             	cmp    $0x6,%ebx
  106ac6:	7f 0b                	jg     106ad3 <vprintfmt+0x153>
  106ac8:	8b 34 9d b0 88 10 00 	mov    0x1088b0(,%ebx,4),%esi
  106acf:	85 f6                	test   %esi,%esi
  106ad1:	75 23                	jne    106af6 <vprintfmt+0x176>
                printfmt(putch, putdat, "error %d", err);
  106ad3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  106ad7:	c7 44 24 08 dd 88 10 	movl   $0x1088dd,0x8(%esp)
  106ade:	00 
  106adf:	8b 45 0c             	mov    0xc(%ebp),%eax
  106ae2:	89 44 24 04          	mov    %eax,0x4(%esp)
  106ae6:	8b 45 08             	mov    0x8(%ebp),%eax
  106ae9:	89 04 24             	mov    %eax,(%esp)
  106aec:	e8 61 fe ff ff       	call   106952 <printfmt>
            }
            else {
                printfmt(putch, putdat, "%s", p);
            }
            break;
  106af1:	e9 68 02 00 00       	jmp    106d5e <vprintfmt+0x3de>
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
                printfmt(putch, putdat, "error %d", err);
            }
            else {
                printfmt(putch, putdat, "%s", p);
  106af6:	89 74 24 0c          	mov    %esi,0xc(%esp)
  106afa:	c7 44 24 08 e6 88 10 	movl   $0x1088e6,0x8(%esp)
  106b01:	00 
  106b02:	8b 45 0c             	mov    0xc(%ebp),%eax
  106b05:	89 44 24 04          	mov    %eax,0x4(%esp)
  106b09:	8b 45 08             	mov    0x8(%ebp),%eax
  106b0c:	89 04 24             	mov    %eax,(%esp)
  106b0f:	e8 3e fe ff ff       	call   106952 <printfmt>
            }
            break;
  106b14:	e9 45 02 00 00       	jmp    106d5e <vprintfmt+0x3de>

        // string
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
  106b19:	8b 45 14             	mov    0x14(%ebp),%eax
  106b1c:	8d 50 04             	lea    0x4(%eax),%edx
  106b1f:	89 55 14             	mov    %edx,0x14(%ebp)
  106b22:	8b 30                	mov    (%eax),%esi
  106b24:	85 f6                	test   %esi,%esi
  106b26:	75 05                	jne    106b2d <vprintfmt+0x1ad>
                p = "(null)";
  106b28:	be e9 88 10 00       	mov    $0x1088e9,%esi
            }
            if (width > 0 && padc != '-') {
  106b2d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  106b31:	7e 3e                	jle    106b71 <vprintfmt+0x1f1>
  106b33:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
  106b37:	74 38                	je     106b71 <vprintfmt+0x1f1>
                for (width -= strnlen(p, precision); width > 0; width --) {
  106b39:	8b 5d e8             	mov    -0x18(%ebp),%ebx
  106b3c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  106b3f:	89 44 24 04          	mov    %eax,0x4(%esp)
  106b43:	89 34 24             	mov    %esi,(%esp)
  106b46:	e8 15 03 00 00       	call   106e60 <strnlen>
  106b4b:	29 c3                	sub    %eax,%ebx
  106b4d:	89 d8                	mov    %ebx,%eax
  106b4f:	89 45 e8             	mov    %eax,-0x18(%ebp)
  106b52:	eb 17                	jmp    106b6b <vprintfmt+0x1eb>
                    putch(padc, putdat);
  106b54:	0f be 45 db          	movsbl -0x25(%ebp),%eax
  106b58:	8b 55 0c             	mov    0xc(%ebp),%edx
  106b5b:	89 54 24 04          	mov    %edx,0x4(%esp)
  106b5f:	89 04 24             	mov    %eax,(%esp)
  106b62:	8b 45 08             	mov    0x8(%ebp),%eax
  106b65:	ff d0                	call   *%eax
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
                p = "(null)";
            }
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
  106b67:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
  106b6b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  106b6f:	7f e3                	jg     106b54 <vprintfmt+0x1d4>
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  106b71:	eb 38                	jmp    106bab <vprintfmt+0x22b>
                if (altflag && (ch < ' ' || ch > '~')) {
  106b73:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  106b77:	74 1f                	je     106b98 <vprintfmt+0x218>
  106b79:	83 fb 1f             	cmp    $0x1f,%ebx
  106b7c:	7e 05                	jle    106b83 <vprintfmt+0x203>
  106b7e:	83 fb 7e             	cmp    $0x7e,%ebx
  106b81:	7e 15                	jle    106b98 <vprintfmt+0x218>
                    putch('?', putdat);
  106b83:	8b 45 0c             	mov    0xc(%ebp),%eax
  106b86:	89 44 24 04          	mov    %eax,0x4(%esp)
  106b8a:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  106b91:	8b 45 08             	mov    0x8(%ebp),%eax
  106b94:	ff d0                	call   *%eax
  106b96:	eb 0f                	jmp    106ba7 <vprintfmt+0x227>
                }
                else {
                    putch(ch, putdat);
  106b98:	8b 45 0c             	mov    0xc(%ebp),%eax
  106b9b:	89 44 24 04          	mov    %eax,0x4(%esp)
  106b9f:	89 1c 24             	mov    %ebx,(%esp)
  106ba2:	8b 45 08             	mov    0x8(%ebp),%eax
  106ba5:	ff d0                	call   *%eax
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  106ba7:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
  106bab:	89 f0                	mov    %esi,%eax
  106bad:	8d 70 01             	lea    0x1(%eax),%esi
  106bb0:	0f b6 00             	movzbl (%eax),%eax
  106bb3:	0f be d8             	movsbl %al,%ebx
  106bb6:	85 db                	test   %ebx,%ebx
  106bb8:	74 10                	je     106bca <vprintfmt+0x24a>
  106bba:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  106bbe:	78 b3                	js     106b73 <vprintfmt+0x1f3>
  106bc0:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
  106bc4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  106bc8:	79 a9                	jns    106b73 <vprintfmt+0x1f3>
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
  106bca:	eb 17                	jmp    106be3 <vprintfmt+0x263>
                putch(' ', putdat);
  106bcc:	8b 45 0c             	mov    0xc(%ebp),%eax
  106bcf:	89 44 24 04          	mov    %eax,0x4(%esp)
  106bd3:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  106bda:	8b 45 08             	mov    0x8(%ebp),%eax
  106bdd:	ff d0                	call   *%eax
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
  106bdf:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
  106be3:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  106be7:	7f e3                	jg     106bcc <vprintfmt+0x24c>
                putch(' ', putdat);
            }
            break;
  106be9:	e9 70 01 00 00       	jmp    106d5e <vprintfmt+0x3de>

        // (signed) decimal
        case 'd':
            num = getint(&ap, lflag);
  106bee:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106bf1:	89 44 24 04          	mov    %eax,0x4(%esp)
  106bf5:	8d 45 14             	lea    0x14(%ebp),%eax
  106bf8:	89 04 24             	mov    %eax,(%esp)
  106bfb:	e8 0b fd ff ff       	call   10690b <getint>
  106c00:	89 45 f0             	mov    %eax,-0x10(%ebp)
  106c03:	89 55 f4             	mov    %edx,-0xc(%ebp)
            if ((long long)num < 0) {
  106c06:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106c09:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106c0c:	85 d2                	test   %edx,%edx
  106c0e:	79 26                	jns    106c36 <vprintfmt+0x2b6>
                putch('-', putdat);
  106c10:	8b 45 0c             	mov    0xc(%ebp),%eax
  106c13:	89 44 24 04          	mov    %eax,0x4(%esp)
  106c17:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  106c1e:	8b 45 08             	mov    0x8(%ebp),%eax
  106c21:	ff d0                	call   *%eax
                num = -(long long)num;
  106c23:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106c26:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106c29:	f7 d8                	neg    %eax
  106c2b:	83 d2 00             	adc    $0x0,%edx
  106c2e:	f7 da                	neg    %edx
  106c30:	89 45 f0             	mov    %eax,-0x10(%ebp)
  106c33:	89 55 f4             	mov    %edx,-0xc(%ebp)
            }
            base = 10;
  106c36:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
  106c3d:	e9 a8 00 00 00       	jmp    106cea <vprintfmt+0x36a>

        // unsigned decimal
        case 'u':
            num = getuint(&ap, lflag);
  106c42:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106c45:	89 44 24 04          	mov    %eax,0x4(%esp)
  106c49:	8d 45 14             	lea    0x14(%ebp),%eax
  106c4c:	89 04 24             	mov    %eax,(%esp)
  106c4f:	e8 68 fc ff ff       	call   1068bc <getuint>
  106c54:	89 45 f0             	mov    %eax,-0x10(%ebp)
  106c57:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 10;
  106c5a:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
  106c61:	e9 84 00 00 00       	jmp    106cea <vprintfmt+0x36a>

        // (unsigned) octal
        case 'o':
            num = getuint(&ap, lflag);
  106c66:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106c69:	89 44 24 04          	mov    %eax,0x4(%esp)
  106c6d:	8d 45 14             	lea    0x14(%ebp),%eax
  106c70:	89 04 24             	mov    %eax,(%esp)
  106c73:	e8 44 fc ff ff       	call   1068bc <getuint>
  106c78:	89 45 f0             	mov    %eax,-0x10(%ebp)
  106c7b:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 8;
  106c7e:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
            goto number;
  106c85:	eb 63                	jmp    106cea <vprintfmt+0x36a>

        // pointer
        case 'p':
            putch('0', putdat);
  106c87:	8b 45 0c             	mov    0xc(%ebp),%eax
  106c8a:	89 44 24 04          	mov    %eax,0x4(%esp)
  106c8e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  106c95:	8b 45 08             	mov    0x8(%ebp),%eax
  106c98:	ff d0                	call   *%eax
            putch('x', putdat);
  106c9a:	8b 45 0c             	mov    0xc(%ebp),%eax
  106c9d:	89 44 24 04          	mov    %eax,0x4(%esp)
  106ca1:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  106ca8:	8b 45 08             	mov    0x8(%ebp),%eax
  106cab:	ff d0                	call   *%eax
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  106cad:	8b 45 14             	mov    0x14(%ebp),%eax
  106cb0:	8d 50 04             	lea    0x4(%eax),%edx
  106cb3:	89 55 14             	mov    %edx,0x14(%ebp)
  106cb6:	8b 00                	mov    (%eax),%eax
  106cb8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  106cbb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
            base = 16;
  106cc2:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
            goto number;
  106cc9:	eb 1f                	jmp    106cea <vprintfmt+0x36a>

        // (unsigned) hexadecimal
        case 'x':
            num = getuint(&ap, lflag);
  106ccb:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106cce:	89 44 24 04          	mov    %eax,0x4(%esp)
  106cd2:	8d 45 14             	lea    0x14(%ebp),%eax
  106cd5:	89 04 24             	mov    %eax,(%esp)
  106cd8:	e8 df fb ff ff       	call   1068bc <getuint>
  106cdd:	89 45 f0             	mov    %eax,-0x10(%ebp)
  106ce0:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 16;
  106ce3:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
        number:
            printnum(putch, putdat, num, base, width, padc);
  106cea:	0f be 55 db          	movsbl -0x25(%ebp),%edx
  106cee:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106cf1:	89 54 24 18          	mov    %edx,0x18(%esp)
  106cf5:	8b 55 e8             	mov    -0x18(%ebp),%edx
  106cf8:	89 54 24 14          	mov    %edx,0x14(%esp)
  106cfc:	89 44 24 10          	mov    %eax,0x10(%esp)
  106d00:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106d03:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106d06:	89 44 24 08          	mov    %eax,0x8(%esp)
  106d0a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  106d0e:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d11:	89 44 24 04          	mov    %eax,0x4(%esp)
  106d15:	8b 45 08             	mov    0x8(%ebp),%eax
  106d18:	89 04 24             	mov    %eax,(%esp)
  106d1b:	e8 97 fa ff ff       	call   1067b7 <printnum>
            break;
  106d20:	eb 3c                	jmp    106d5e <vprintfmt+0x3de>

        // escaped '%' character
        case '%':
            putch(ch, putdat);
  106d22:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d25:	89 44 24 04          	mov    %eax,0x4(%esp)
  106d29:	89 1c 24             	mov    %ebx,(%esp)
  106d2c:	8b 45 08             	mov    0x8(%ebp),%eax
  106d2f:	ff d0                	call   *%eax
            break;
  106d31:	eb 2b                	jmp    106d5e <vprintfmt+0x3de>

        // unrecognized escape sequence - just print it literally
        default:
            putch('%', putdat);
  106d33:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d36:	89 44 24 04          	mov    %eax,0x4(%esp)
  106d3a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  106d41:	8b 45 08             	mov    0x8(%ebp),%eax
  106d44:	ff d0                	call   *%eax
            for (fmt --; fmt[-1] != '%'; fmt --)
  106d46:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  106d4a:	eb 04                	jmp    106d50 <vprintfmt+0x3d0>
  106d4c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  106d50:	8b 45 10             	mov    0x10(%ebp),%eax
  106d53:	83 e8 01             	sub    $0x1,%eax
  106d56:	0f b6 00             	movzbl (%eax),%eax
  106d59:	3c 25                	cmp    $0x25,%al
  106d5b:	75 ef                	jne    106d4c <vprintfmt+0x3cc>
                /* do nothing */;
            break;
  106d5d:	90                   	nop
        }
    }
  106d5e:	90                   	nop
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  106d5f:	e9 3e fc ff ff       	jmp    1069a2 <vprintfmt+0x22>
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  106d64:	83 c4 40             	add    $0x40,%esp
  106d67:	5b                   	pop    %ebx
  106d68:	5e                   	pop    %esi
  106d69:	5d                   	pop    %ebp
  106d6a:	c3                   	ret    

00106d6b <sprintputch>:
 * sprintputch - 'print' a single character in a buffer
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
  106d6b:	55                   	push   %ebp
  106d6c:	89 e5                	mov    %esp,%ebp
    b->cnt ++;
  106d6e:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d71:	8b 40 08             	mov    0x8(%eax),%eax
  106d74:	8d 50 01             	lea    0x1(%eax),%edx
  106d77:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d7a:	89 50 08             	mov    %edx,0x8(%eax)
    if (b->buf < b->ebuf) {
  106d7d:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d80:	8b 10                	mov    (%eax),%edx
  106d82:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d85:	8b 40 04             	mov    0x4(%eax),%eax
  106d88:	39 c2                	cmp    %eax,%edx
  106d8a:	73 12                	jae    106d9e <sprintputch+0x33>
        *b->buf ++ = ch;
  106d8c:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d8f:	8b 00                	mov    (%eax),%eax
  106d91:	8d 48 01             	lea    0x1(%eax),%ecx
  106d94:	8b 55 0c             	mov    0xc(%ebp),%edx
  106d97:	89 0a                	mov    %ecx,(%edx)
  106d99:	8b 55 08             	mov    0x8(%ebp),%edx
  106d9c:	88 10                	mov    %dl,(%eax)
    }
}
  106d9e:	5d                   	pop    %ebp
  106d9f:	c3                   	ret    

00106da0 <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
  106da0:	55                   	push   %ebp
  106da1:	89 e5                	mov    %esp,%ebp
  106da3:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
  106da6:	8d 45 14             	lea    0x14(%ebp),%eax
  106da9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vsnprintf(str, size, fmt, ap);
  106dac:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106daf:	89 44 24 0c          	mov    %eax,0xc(%esp)
  106db3:	8b 45 10             	mov    0x10(%ebp),%eax
  106db6:	89 44 24 08          	mov    %eax,0x8(%esp)
  106dba:	8b 45 0c             	mov    0xc(%ebp),%eax
  106dbd:	89 44 24 04          	mov    %eax,0x4(%esp)
  106dc1:	8b 45 08             	mov    0x8(%ebp),%eax
  106dc4:	89 04 24             	mov    %eax,(%esp)
  106dc7:	e8 08 00 00 00       	call   106dd4 <vsnprintf>
  106dcc:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
  106dcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  106dd2:	c9                   	leave  
  106dd3:	c3                   	ret    

00106dd4 <vsnprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
  106dd4:	55                   	push   %ebp
  106dd5:	89 e5                	mov    %esp,%ebp
  106dd7:	83 ec 28             	sub    $0x28,%esp
    struct sprintbuf b = {str, str + size - 1, 0};
  106dda:	8b 45 08             	mov    0x8(%ebp),%eax
  106ddd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  106de0:	8b 45 0c             	mov    0xc(%ebp),%eax
  106de3:	8d 50 ff             	lea    -0x1(%eax),%edx
  106de6:	8b 45 08             	mov    0x8(%ebp),%eax
  106de9:	01 d0                	add    %edx,%eax
  106deb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  106dee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if (str == NULL || b.buf > b.ebuf) {
  106df5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  106df9:	74 0a                	je     106e05 <vsnprintf+0x31>
  106dfb:	8b 55 ec             	mov    -0x14(%ebp),%edx
  106dfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106e01:	39 c2                	cmp    %eax,%edx
  106e03:	76 07                	jbe    106e0c <vsnprintf+0x38>
        return -E_INVAL;
  106e05:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  106e0a:	eb 2a                	jmp    106e36 <vsnprintf+0x62>
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
  106e0c:	8b 45 14             	mov    0x14(%ebp),%eax
  106e0f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  106e13:	8b 45 10             	mov    0x10(%ebp),%eax
  106e16:	89 44 24 08          	mov    %eax,0x8(%esp)
  106e1a:	8d 45 ec             	lea    -0x14(%ebp),%eax
  106e1d:	89 44 24 04          	mov    %eax,0x4(%esp)
  106e21:	c7 04 24 6b 6d 10 00 	movl   $0x106d6b,(%esp)
  106e28:	e8 53 fb ff ff       	call   106980 <vprintfmt>
    // null terminate the buffer
    *b.buf = '\0';
  106e2d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106e30:	c6 00 00             	movb   $0x0,(%eax)
    return b.cnt;
  106e33:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  106e36:	c9                   	leave  
  106e37:	c3                   	ret    

00106e38 <strlen>:
 * @s:      the input string
 *
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
  106e38:	55                   	push   %ebp
  106e39:	89 e5                	mov    %esp,%ebp
  106e3b:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
  106e3e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (*s ++ != '\0') {
  106e45:	eb 04                	jmp    106e4b <strlen+0x13>
        cnt ++;
  106e47:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
  106e4b:	8b 45 08             	mov    0x8(%ebp),%eax
  106e4e:	8d 50 01             	lea    0x1(%eax),%edx
  106e51:	89 55 08             	mov    %edx,0x8(%ebp)
  106e54:	0f b6 00             	movzbl (%eax),%eax
  106e57:	84 c0                	test   %al,%al
  106e59:	75 ec                	jne    106e47 <strlen+0xf>
        cnt ++;
    }
    return cnt;
  106e5b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  106e5e:	c9                   	leave  
  106e5f:	c3                   	ret    

00106e60 <strnlen>:
 * The return value is strlen(s), if that is less than @len, or
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
  106e60:	55                   	push   %ebp
  106e61:	89 e5                	mov    %esp,%ebp
  106e63:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
  106e66:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (cnt < len && *s ++ != '\0') {
  106e6d:	eb 04                	jmp    106e73 <strnlen+0x13>
        cnt ++;
  106e6f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
  106e73:	8b 45 fc             	mov    -0x4(%ebp),%eax
  106e76:	3b 45 0c             	cmp    0xc(%ebp),%eax
  106e79:	73 10                	jae    106e8b <strnlen+0x2b>
  106e7b:	8b 45 08             	mov    0x8(%ebp),%eax
  106e7e:	8d 50 01             	lea    0x1(%eax),%edx
  106e81:	89 55 08             	mov    %edx,0x8(%ebp)
  106e84:	0f b6 00             	movzbl (%eax),%eax
  106e87:	84 c0                	test   %al,%al
  106e89:	75 e4                	jne    106e6f <strnlen+0xf>
        cnt ++;
    }
    return cnt;
  106e8b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  106e8e:	c9                   	leave  
  106e8f:	c3                   	ret    

00106e90 <strcpy>:
 * To avoid overflows, the size of array pointed by @dst should be long enough to
 * contain the same string as @src (including the terminating null character), and
 * should not overlap in memory with @src.
 * */
char *
strcpy(char *dst, const char *src) {
  106e90:	55                   	push   %ebp
  106e91:	89 e5                	mov    %esp,%ebp
  106e93:	57                   	push   %edi
  106e94:	56                   	push   %esi
  106e95:	83 ec 20             	sub    $0x20,%esp
  106e98:	8b 45 08             	mov    0x8(%ebp),%eax
  106e9b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  106e9e:	8b 45 0c             	mov    0xc(%ebp),%eax
  106ea1:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCPY
#define __HAVE_ARCH_STRCPY
static inline char *
__strcpy(char *dst, const char *src) {
    int d0, d1, d2;
    asm volatile (
  106ea4:	8b 55 f0             	mov    -0x10(%ebp),%edx
  106ea7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106eaa:	89 d1                	mov    %edx,%ecx
  106eac:	89 c2                	mov    %eax,%edx
  106eae:	89 ce                	mov    %ecx,%esi
  106eb0:	89 d7                	mov    %edx,%edi
  106eb2:	ac                   	lods   %ds:(%esi),%al
  106eb3:	aa                   	stos   %al,%es:(%edi)
  106eb4:	84 c0                	test   %al,%al
  106eb6:	75 fa                	jne    106eb2 <strcpy+0x22>
  106eb8:	89 fa                	mov    %edi,%edx
  106eba:	89 f1                	mov    %esi,%ecx
  106ebc:	89 4d ec             	mov    %ecx,-0x14(%ebp)
  106ebf:	89 55 e8             	mov    %edx,-0x18(%ebp)
  106ec2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        "stosb;"
        "testb %%al, %%al;"
        "jne 1b;"
        : "=&S" (d0), "=&D" (d1), "=&a" (d2)
        : "0" (src), "1" (dst) : "memory");
    return dst;
  106ec5:	8b 45 f4             	mov    -0xc(%ebp),%eax
    char *p = dst;
    while ((*p ++ = *src ++) != '\0')
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
  106ec8:	83 c4 20             	add    $0x20,%esp
  106ecb:	5e                   	pop    %esi
  106ecc:	5f                   	pop    %edi
  106ecd:	5d                   	pop    %ebp
  106ece:	c3                   	ret    

00106ecf <strncpy>:
 * @len:    maximum number of characters to be copied from @src
 *
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
  106ecf:	55                   	push   %ebp
  106ed0:	89 e5                	mov    %esp,%ebp
  106ed2:	83 ec 10             	sub    $0x10,%esp
    char *p = dst;
  106ed5:	8b 45 08             	mov    0x8(%ebp),%eax
  106ed8:	89 45 fc             	mov    %eax,-0x4(%ebp)
    while (len > 0) {
  106edb:	eb 21                	jmp    106efe <strncpy+0x2f>
        if ((*p = *src) != '\0') {
  106edd:	8b 45 0c             	mov    0xc(%ebp),%eax
  106ee0:	0f b6 10             	movzbl (%eax),%edx
  106ee3:	8b 45 fc             	mov    -0x4(%ebp),%eax
  106ee6:	88 10                	mov    %dl,(%eax)
  106ee8:	8b 45 fc             	mov    -0x4(%ebp),%eax
  106eeb:	0f b6 00             	movzbl (%eax),%eax
  106eee:	84 c0                	test   %al,%al
  106ef0:	74 04                	je     106ef6 <strncpy+0x27>
            src ++;
  106ef2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
        }
        p ++, len --;
  106ef6:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  106efa:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
    char *p = dst;
    while (len > 0) {
  106efe:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  106f02:	75 d9                	jne    106edd <strncpy+0xe>
        if ((*p = *src) != '\0') {
            src ++;
        }
        p ++, len --;
    }
    return dst;
  106f04:	8b 45 08             	mov    0x8(%ebp),%eax
}
  106f07:	c9                   	leave  
  106f08:	c3                   	ret    

00106f09 <strcmp>:
 * - A value greater than zero indicates that the first character that does
 *   not match has a greater value in @s1 than in @s2;
 * - And a value less than zero indicates the opposite.
 * */
int
strcmp(const char *s1, const char *s2) {
  106f09:	55                   	push   %ebp
  106f0a:	89 e5                	mov    %esp,%ebp
  106f0c:	57                   	push   %edi
  106f0d:	56                   	push   %esi
  106f0e:	83 ec 20             	sub    $0x20,%esp
  106f11:	8b 45 08             	mov    0x8(%ebp),%eax
  106f14:	89 45 f4             	mov    %eax,-0xc(%ebp)
  106f17:	8b 45 0c             	mov    0xc(%ebp),%eax
  106f1a:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCMP
#define __HAVE_ARCH_STRCMP
static inline int
__strcmp(const char *s1, const char *s2) {
    int d0, d1, ret;
    asm volatile (
  106f1d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106f20:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106f23:	89 d1                	mov    %edx,%ecx
  106f25:	89 c2                	mov    %eax,%edx
  106f27:	89 ce                	mov    %ecx,%esi
  106f29:	89 d7                	mov    %edx,%edi
  106f2b:	ac                   	lods   %ds:(%esi),%al
  106f2c:	ae                   	scas   %es:(%edi),%al
  106f2d:	75 08                	jne    106f37 <strcmp+0x2e>
  106f2f:	84 c0                	test   %al,%al
  106f31:	75 f8                	jne    106f2b <strcmp+0x22>
  106f33:	31 c0                	xor    %eax,%eax
  106f35:	eb 04                	jmp    106f3b <strcmp+0x32>
  106f37:	19 c0                	sbb    %eax,%eax
  106f39:	0c 01                	or     $0x1,%al
  106f3b:	89 fa                	mov    %edi,%edx
  106f3d:	89 f1                	mov    %esi,%ecx
  106f3f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  106f42:	89 4d e8             	mov    %ecx,-0x18(%ebp)
  106f45:	89 55 e4             	mov    %edx,-0x1c(%ebp)
        "orb $1, %%al;"
        "3:"
        : "=a" (ret), "=&S" (d0), "=&D" (d1)
        : "1" (s1), "2" (s2)
        : "memory");
    return ret;
  106f48:	8b 45 ec             	mov    -0x14(%ebp),%eax
    while (*s1 != '\0' && *s1 == *s2) {
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
#endif /* __HAVE_ARCH_STRCMP */
}
  106f4b:	83 c4 20             	add    $0x20,%esp
  106f4e:	5e                   	pop    %esi
  106f4f:	5f                   	pop    %edi
  106f50:	5d                   	pop    %ebp
  106f51:	c3                   	ret    

00106f52 <strncmp>:
 * they are equal to each other, it continues with the following pairs until
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
  106f52:	55                   	push   %ebp
  106f53:	89 e5                	mov    %esp,%ebp
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
  106f55:	eb 0c                	jmp    106f63 <strncmp+0x11>
        n --, s1 ++, s2 ++;
  106f57:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  106f5b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  106f5f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
  106f63:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  106f67:	74 1a                	je     106f83 <strncmp+0x31>
  106f69:	8b 45 08             	mov    0x8(%ebp),%eax
  106f6c:	0f b6 00             	movzbl (%eax),%eax
  106f6f:	84 c0                	test   %al,%al
  106f71:	74 10                	je     106f83 <strncmp+0x31>
  106f73:	8b 45 08             	mov    0x8(%ebp),%eax
  106f76:	0f b6 10             	movzbl (%eax),%edx
  106f79:	8b 45 0c             	mov    0xc(%ebp),%eax
  106f7c:	0f b6 00             	movzbl (%eax),%eax
  106f7f:	38 c2                	cmp    %al,%dl
  106f81:	74 d4                	je     106f57 <strncmp+0x5>
        n --, s1 ++, s2 ++;
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
  106f83:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  106f87:	74 18                	je     106fa1 <strncmp+0x4f>
  106f89:	8b 45 08             	mov    0x8(%ebp),%eax
  106f8c:	0f b6 00             	movzbl (%eax),%eax
  106f8f:	0f b6 d0             	movzbl %al,%edx
  106f92:	8b 45 0c             	mov    0xc(%ebp),%eax
  106f95:	0f b6 00             	movzbl (%eax),%eax
  106f98:	0f b6 c0             	movzbl %al,%eax
  106f9b:	29 c2                	sub    %eax,%edx
  106f9d:	89 d0                	mov    %edx,%eax
  106f9f:	eb 05                	jmp    106fa6 <strncmp+0x54>
  106fa1:	b8 00 00 00 00       	mov    $0x0,%eax
}
  106fa6:	5d                   	pop    %ebp
  106fa7:	c3                   	ret    

00106fa8 <strchr>:
 *
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
  106fa8:	55                   	push   %ebp
  106fa9:	89 e5                	mov    %esp,%ebp
  106fab:	83 ec 04             	sub    $0x4,%esp
  106fae:	8b 45 0c             	mov    0xc(%ebp),%eax
  106fb1:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
  106fb4:	eb 14                	jmp    106fca <strchr+0x22>
        if (*s == c) {
  106fb6:	8b 45 08             	mov    0x8(%ebp),%eax
  106fb9:	0f b6 00             	movzbl (%eax),%eax
  106fbc:	3a 45 fc             	cmp    -0x4(%ebp),%al
  106fbf:	75 05                	jne    106fc6 <strchr+0x1e>
            return (char *)s;
  106fc1:	8b 45 08             	mov    0x8(%ebp),%eax
  106fc4:	eb 13                	jmp    106fd9 <strchr+0x31>
        }
        s ++;
  106fc6:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
  106fca:	8b 45 08             	mov    0x8(%ebp),%eax
  106fcd:	0f b6 00             	movzbl (%eax),%eax
  106fd0:	84 c0                	test   %al,%al
  106fd2:	75 e2                	jne    106fb6 <strchr+0xe>
        if (*s == c) {
            return (char *)s;
        }
        s ++;
    }
    return NULL;
  106fd4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  106fd9:	c9                   	leave  
  106fda:	c3                   	ret    

00106fdb <strfind>:
 * The strfind() function is like strchr() except that if @c is
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
  106fdb:	55                   	push   %ebp
  106fdc:	89 e5                	mov    %esp,%ebp
  106fde:	83 ec 04             	sub    $0x4,%esp
  106fe1:	8b 45 0c             	mov    0xc(%ebp),%eax
  106fe4:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
  106fe7:	eb 11                	jmp    106ffa <strfind+0x1f>
        if (*s == c) {
  106fe9:	8b 45 08             	mov    0x8(%ebp),%eax
  106fec:	0f b6 00             	movzbl (%eax),%eax
  106fef:	3a 45 fc             	cmp    -0x4(%ebp),%al
  106ff2:	75 02                	jne    106ff6 <strfind+0x1b>
            break;
  106ff4:	eb 0e                	jmp    107004 <strfind+0x29>
        }
        s ++;
  106ff6:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
    while (*s != '\0') {
  106ffa:	8b 45 08             	mov    0x8(%ebp),%eax
  106ffd:	0f b6 00             	movzbl (%eax),%eax
  107000:	84 c0                	test   %al,%al
  107002:	75 e5                	jne    106fe9 <strfind+0xe>
        if (*s == c) {
            break;
        }
        s ++;
    }
    return (char *)s;
  107004:	8b 45 08             	mov    0x8(%ebp),%eax
}
  107007:	c9                   	leave  
  107008:	c3                   	ret    

00107009 <strtol>:
 * an optional "0x" or "0X" prefix.
 *
 * The strtol() function returns the converted integral number as a long int value.
 * */
long
strtol(const char *s, char **endptr, int base) {
  107009:	55                   	push   %ebp
  10700a:	89 e5                	mov    %esp,%ebp
  10700c:	83 ec 10             	sub    $0x10,%esp
    int neg = 0;
  10700f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    long val = 0;
  107016:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
  10701d:	eb 04                	jmp    107023 <strtol+0x1a>
        s ++;
  10701f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
strtol(const char *s, char **endptr, int base) {
    int neg = 0;
    long val = 0;

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
  107023:	8b 45 08             	mov    0x8(%ebp),%eax
  107026:	0f b6 00             	movzbl (%eax),%eax
  107029:	3c 20                	cmp    $0x20,%al
  10702b:	74 f2                	je     10701f <strtol+0x16>
  10702d:	8b 45 08             	mov    0x8(%ebp),%eax
  107030:	0f b6 00             	movzbl (%eax),%eax
  107033:	3c 09                	cmp    $0x9,%al
  107035:	74 e8                	je     10701f <strtol+0x16>
        s ++;
    }

    // plus/minus sign
    if (*s == '+') {
  107037:	8b 45 08             	mov    0x8(%ebp),%eax
  10703a:	0f b6 00             	movzbl (%eax),%eax
  10703d:	3c 2b                	cmp    $0x2b,%al
  10703f:	75 06                	jne    107047 <strtol+0x3e>
        s ++;
  107041:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107045:	eb 15                	jmp    10705c <strtol+0x53>
    }
    else if (*s == '-') {
  107047:	8b 45 08             	mov    0x8(%ebp),%eax
  10704a:	0f b6 00             	movzbl (%eax),%eax
  10704d:	3c 2d                	cmp    $0x2d,%al
  10704f:	75 0b                	jne    10705c <strtol+0x53>
        s ++, neg = 1;
  107051:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107055:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)
    }

    // hex or octal base prefix
    if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x')) {
  10705c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107060:	74 06                	je     107068 <strtol+0x5f>
  107062:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
  107066:	75 24                	jne    10708c <strtol+0x83>
  107068:	8b 45 08             	mov    0x8(%ebp),%eax
  10706b:	0f b6 00             	movzbl (%eax),%eax
  10706e:	3c 30                	cmp    $0x30,%al
  107070:	75 1a                	jne    10708c <strtol+0x83>
  107072:	8b 45 08             	mov    0x8(%ebp),%eax
  107075:	83 c0 01             	add    $0x1,%eax
  107078:	0f b6 00             	movzbl (%eax),%eax
  10707b:	3c 78                	cmp    $0x78,%al
  10707d:	75 0d                	jne    10708c <strtol+0x83>
        s += 2, base = 16;
  10707f:	83 45 08 02          	addl   $0x2,0x8(%ebp)
  107083:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
  10708a:	eb 2a                	jmp    1070b6 <strtol+0xad>
    }
    else if (base == 0 && s[0] == '0') {
  10708c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107090:	75 17                	jne    1070a9 <strtol+0xa0>
  107092:	8b 45 08             	mov    0x8(%ebp),%eax
  107095:	0f b6 00             	movzbl (%eax),%eax
  107098:	3c 30                	cmp    $0x30,%al
  10709a:	75 0d                	jne    1070a9 <strtol+0xa0>
        s ++, base = 8;
  10709c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1070a0:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
  1070a7:	eb 0d                	jmp    1070b6 <strtol+0xad>
    }
    else if (base == 0) {
  1070a9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1070ad:	75 07                	jne    1070b6 <strtol+0xad>
        base = 10;
  1070af:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

    // digits
    while (1) {
        int dig;

        if (*s >= '0' && *s <= '9') {
  1070b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1070b9:	0f b6 00             	movzbl (%eax),%eax
  1070bc:	3c 2f                	cmp    $0x2f,%al
  1070be:	7e 1b                	jle    1070db <strtol+0xd2>
  1070c0:	8b 45 08             	mov    0x8(%ebp),%eax
  1070c3:	0f b6 00             	movzbl (%eax),%eax
  1070c6:	3c 39                	cmp    $0x39,%al
  1070c8:	7f 11                	jg     1070db <strtol+0xd2>
            dig = *s - '0';
  1070ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1070cd:	0f b6 00             	movzbl (%eax),%eax
  1070d0:	0f be c0             	movsbl %al,%eax
  1070d3:	83 e8 30             	sub    $0x30,%eax
  1070d6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1070d9:	eb 48                	jmp    107123 <strtol+0x11a>
        }
        else if (*s >= 'a' && *s <= 'z') {
  1070db:	8b 45 08             	mov    0x8(%ebp),%eax
  1070de:	0f b6 00             	movzbl (%eax),%eax
  1070e1:	3c 60                	cmp    $0x60,%al
  1070e3:	7e 1b                	jle    107100 <strtol+0xf7>
  1070e5:	8b 45 08             	mov    0x8(%ebp),%eax
  1070e8:	0f b6 00             	movzbl (%eax),%eax
  1070eb:	3c 7a                	cmp    $0x7a,%al
  1070ed:	7f 11                	jg     107100 <strtol+0xf7>
            dig = *s - 'a' + 10;
  1070ef:	8b 45 08             	mov    0x8(%ebp),%eax
  1070f2:	0f b6 00             	movzbl (%eax),%eax
  1070f5:	0f be c0             	movsbl %al,%eax
  1070f8:	83 e8 57             	sub    $0x57,%eax
  1070fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1070fe:	eb 23                	jmp    107123 <strtol+0x11a>
        }
        else if (*s >= 'A' && *s <= 'Z') {
  107100:	8b 45 08             	mov    0x8(%ebp),%eax
  107103:	0f b6 00             	movzbl (%eax),%eax
  107106:	3c 40                	cmp    $0x40,%al
  107108:	7e 3d                	jle    107147 <strtol+0x13e>
  10710a:	8b 45 08             	mov    0x8(%ebp),%eax
  10710d:	0f b6 00             	movzbl (%eax),%eax
  107110:	3c 5a                	cmp    $0x5a,%al
  107112:	7f 33                	jg     107147 <strtol+0x13e>
            dig = *s - 'A' + 10;
  107114:	8b 45 08             	mov    0x8(%ebp),%eax
  107117:	0f b6 00             	movzbl (%eax),%eax
  10711a:	0f be c0             	movsbl %al,%eax
  10711d:	83 e8 37             	sub    $0x37,%eax
  107120:	89 45 f4             	mov    %eax,-0xc(%ebp)
        }
        else {
            break;
        }
        if (dig >= base) {
  107123:	8b 45 f4             	mov    -0xc(%ebp),%eax
  107126:	3b 45 10             	cmp    0x10(%ebp),%eax
  107129:	7c 02                	jl     10712d <strtol+0x124>
            break;
  10712b:	eb 1a                	jmp    107147 <strtol+0x13e>
        }
        s ++, val = (val * base) + dig;
  10712d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107131:	8b 45 f8             	mov    -0x8(%ebp),%eax
  107134:	0f af 45 10          	imul   0x10(%ebp),%eax
  107138:	89 c2                	mov    %eax,%edx
  10713a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10713d:	01 d0                	add    %edx,%eax
  10713f:	89 45 f8             	mov    %eax,-0x8(%ebp)
        // we don't properly detect overflow!
    }
  107142:	e9 6f ff ff ff       	jmp    1070b6 <strtol+0xad>

    if (endptr) {
  107147:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  10714b:	74 08                	je     107155 <strtol+0x14c>
        *endptr = (char *) s;
  10714d:	8b 45 0c             	mov    0xc(%ebp),%eax
  107150:	8b 55 08             	mov    0x8(%ebp),%edx
  107153:	89 10                	mov    %edx,(%eax)
    }
    return (neg ? -val : val);
  107155:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
  107159:	74 07                	je     107162 <strtol+0x159>
  10715b:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10715e:	f7 d8                	neg    %eax
  107160:	eb 03                	jmp    107165 <strtol+0x15c>
  107162:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  107165:	c9                   	leave  
  107166:	c3                   	ret    

00107167 <memset>:
 * @n:      number of bytes to be set to the value
 *
 * The memset() function returns @s.
 * */
void *
memset(void *s, char c, size_t n) {
  107167:	55                   	push   %ebp
  107168:	89 e5                	mov    %esp,%ebp
  10716a:	57                   	push   %edi
  10716b:	83 ec 24             	sub    $0x24,%esp
  10716e:	8b 45 0c             	mov    0xc(%ebp),%eax
  107171:	88 45 d8             	mov    %al,-0x28(%ebp)
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
  107174:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  107178:	8b 55 08             	mov    0x8(%ebp),%edx
  10717b:	89 55 f8             	mov    %edx,-0x8(%ebp)
  10717e:	88 45 f7             	mov    %al,-0x9(%ebp)
  107181:	8b 45 10             	mov    0x10(%ebp),%eax
  107184:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_MEMSET
#define __HAVE_ARCH_MEMSET
static inline void *
__memset(void *s, char c, size_t n) {
    int d0, d1;
    asm volatile (
  107187:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  10718a:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  10718e:	8b 55 f8             	mov    -0x8(%ebp),%edx
  107191:	89 d7                	mov    %edx,%edi
  107193:	f3 aa                	rep stos %al,%es:(%edi)
  107195:	89 fa                	mov    %edi,%edx
  107197:	89 4d ec             	mov    %ecx,-0x14(%ebp)
  10719a:	89 55 e8             	mov    %edx,-0x18(%ebp)
        "rep; stosb;"
        : "=&c" (d0), "=&D" (d1)
        : "0" (n), "a" (c), "1" (s)
        : "memory");
    return s;
  10719d:	8b 45 f8             	mov    -0x8(%ebp),%eax
    while (n -- > 0) {
        *p ++ = c;
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
  1071a0:	83 c4 24             	add    $0x24,%esp
  1071a3:	5f                   	pop    %edi
  1071a4:	5d                   	pop    %ebp
  1071a5:	c3                   	ret    

001071a6 <memmove>:
 * @n:      number of bytes to copy
 *
 * The memmove() function returns @dst.
 * */
void *
memmove(void *dst, const void *src, size_t n) {
  1071a6:	55                   	push   %ebp
  1071a7:	89 e5                	mov    %esp,%ebp
  1071a9:	57                   	push   %edi
  1071aa:	56                   	push   %esi
  1071ab:	53                   	push   %ebx
  1071ac:	83 ec 30             	sub    $0x30,%esp
  1071af:	8b 45 08             	mov    0x8(%ebp),%eax
  1071b2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1071b5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1071b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1071bb:	8b 45 10             	mov    0x10(%ebp),%eax
  1071be:	89 45 e8             	mov    %eax,-0x18(%ebp)

#ifndef __HAVE_ARCH_MEMMOVE
#define __HAVE_ARCH_MEMMOVE
static inline void *
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
  1071c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1071c4:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1071c7:	73 42                	jae    10720b <memmove+0x65>
  1071c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1071cc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1071cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1071d2:	89 45 e0             	mov    %eax,-0x20(%ebp)
  1071d5:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1071d8:	89 45 dc             	mov    %eax,-0x24(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
  1071db:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1071de:	c1 e8 02             	shr    $0x2,%eax
  1071e1:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
  1071e3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1071e6:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1071e9:	89 d7                	mov    %edx,%edi
  1071eb:	89 c6                	mov    %eax,%esi
  1071ed:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  1071ef:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  1071f2:	83 e1 03             	and    $0x3,%ecx
  1071f5:	74 02                	je     1071f9 <memmove+0x53>
  1071f7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  1071f9:	89 f0                	mov    %esi,%eax
  1071fb:	89 fa                	mov    %edi,%edx
  1071fd:	89 4d d8             	mov    %ecx,-0x28(%ebp)
  107200:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  107203:	89 45 d0             	mov    %eax,-0x30(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
  107206:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  107209:	eb 36                	jmp    107241 <memmove+0x9b>
    asm volatile (
        "std;"
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
  10720b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10720e:	8d 50 ff             	lea    -0x1(%eax),%edx
  107211:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107214:	01 c2                	add    %eax,%edx
  107216:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107219:	8d 48 ff             	lea    -0x1(%eax),%ecx
  10721c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10721f:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
        return __memcpy(dst, src, n);
    }
    int d0, d1, d2;
    asm volatile (
  107222:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107225:	89 c1                	mov    %eax,%ecx
  107227:	89 d8                	mov    %ebx,%eax
  107229:	89 d6                	mov    %edx,%esi
  10722b:	89 c7                	mov    %eax,%edi
  10722d:	fd                   	std    
  10722e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  107230:	fc                   	cld    
  107231:	89 f8                	mov    %edi,%eax
  107233:	89 f2                	mov    %esi,%edx
  107235:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  107238:	89 55 c8             	mov    %edx,-0x38(%ebp)
  10723b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
        : "memory");
    return dst;
  10723e:	8b 45 f0             	mov    -0x10(%ebp),%eax
            *d ++ = *s ++;
        }
    }
    return dst;
#endif /* __HAVE_ARCH_MEMMOVE */
}
  107241:	83 c4 30             	add    $0x30,%esp
  107244:	5b                   	pop    %ebx
  107245:	5e                   	pop    %esi
  107246:	5f                   	pop    %edi
  107247:	5d                   	pop    %ebp
  107248:	c3                   	ret    

00107249 <memcpy>:
 * it always copies exactly @n bytes. To avoid overflows, the size of arrays pointed
 * by both @src and @dst, should be at least @n bytes, and should not overlap
 * (for overlapping memory area, memmove is a safer approach).
 * */
void *
memcpy(void *dst, const void *src, size_t n) {
  107249:	55                   	push   %ebp
  10724a:	89 e5                	mov    %esp,%ebp
  10724c:	57                   	push   %edi
  10724d:	56                   	push   %esi
  10724e:	83 ec 20             	sub    $0x20,%esp
  107251:	8b 45 08             	mov    0x8(%ebp),%eax
  107254:	89 45 f4             	mov    %eax,-0xc(%ebp)
  107257:	8b 45 0c             	mov    0xc(%ebp),%eax
  10725a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10725d:	8b 45 10             	mov    0x10(%ebp),%eax
  107260:	89 45 ec             	mov    %eax,-0x14(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
  107263:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107266:	c1 e8 02             	shr    $0x2,%eax
  107269:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
  10726b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10726e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107271:	89 d7                	mov    %edx,%edi
  107273:	89 c6                	mov    %eax,%esi
  107275:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  107277:	8b 4d ec             	mov    -0x14(%ebp),%ecx
  10727a:	83 e1 03             	and    $0x3,%ecx
  10727d:	74 02                	je     107281 <memcpy+0x38>
  10727f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  107281:	89 f0                	mov    %esi,%eax
  107283:	89 fa                	mov    %edi,%edx
  107285:	89 4d e8             	mov    %ecx,-0x18(%ebp)
  107288:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  10728b:	89 45 e0             	mov    %eax,-0x20(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
  10728e:	8b 45 f4             	mov    -0xc(%ebp),%eax
    while (n -- > 0) {
        *d ++ = *s ++;
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
  107291:	83 c4 20             	add    $0x20,%esp
  107294:	5e                   	pop    %esi
  107295:	5f                   	pop    %edi
  107296:	5d                   	pop    %ebp
  107297:	c3                   	ret    

00107298 <memcmp>:
 *   match in both memory blocks has a greater value in @v1 than in @v2
 *   as if evaluated as unsigned char values;
 * - And a value less than zero indicates the opposite.
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
  107298:	55                   	push   %ebp
  107299:	89 e5                	mov    %esp,%ebp
  10729b:	83 ec 10             	sub    $0x10,%esp
    const char *s1 = (const char *)v1;
  10729e:	8b 45 08             	mov    0x8(%ebp),%eax
  1072a1:	89 45 fc             	mov    %eax,-0x4(%ebp)
    const char *s2 = (const char *)v2;
  1072a4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1072a7:	89 45 f8             	mov    %eax,-0x8(%ebp)
    while (n -- > 0) {
  1072aa:	eb 30                	jmp    1072dc <memcmp+0x44>
        if (*s1 != *s2) {
  1072ac:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1072af:	0f b6 10             	movzbl (%eax),%edx
  1072b2:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1072b5:	0f b6 00             	movzbl (%eax),%eax
  1072b8:	38 c2                	cmp    %al,%dl
  1072ba:	74 18                	je     1072d4 <memcmp+0x3c>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
  1072bc:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1072bf:	0f b6 00             	movzbl (%eax),%eax
  1072c2:	0f b6 d0             	movzbl %al,%edx
  1072c5:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1072c8:	0f b6 00             	movzbl (%eax),%eax
  1072cb:	0f b6 c0             	movzbl %al,%eax
  1072ce:	29 c2                	sub    %eax,%edx
  1072d0:	89 d0                	mov    %edx,%eax
  1072d2:	eb 1a                	jmp    1072ee <memcmp+0x56>
        }
        s1 ++, s2 ++;
  1072d4:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  1072d8:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
  1072dc:	8b 45 10             	mov    0x10(%ebp),%eax
  1072df:	8d 50 ff             	lea    -0x1(%eax),%edx
  1072e2:	89 55 10             	mov    %edx,0x10(%ebp)
  1072e5:	85 c0                	test   %eax,%eax
  1072e7:	75 c3                	jne    1072ac <memcmp+0x14>
        if (*s1 != *s2) {
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
    }
    return 0;
  1072e9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1072ee:	c9                   	leave  
  1072ef:	c3                   	ret    
