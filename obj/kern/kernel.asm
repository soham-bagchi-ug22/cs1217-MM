
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 03 01 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010004c:	81 c3 bc 72 01 00    	add    $0x172bc,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 90 11 f0    	mov    $0xf0119060,%edx
f0100058:	c7 c0 c0 96 11 f0    	mov    $0xf01196c0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 6e 3b 00 00       	call   f0103bd7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 18 cd fe ff    	lea    -0x132e8(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 f9 2f 00 00       	call   f010307b <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 d7 12 00 00       	call   f010135e <mem_init>
f0100087:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 8c 07 00 00       	call   f0100820 <monitor>
f0100094:	83 c4 10             	add    $0x10,%esp
f0100097:	eb f1                	jmp    f010008a <i386_init+0x4a>

f0100099 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100099:	55                   	push   %ebp
f010009a:	89 e5                	mov    %esp,%ebp
f010009c:	57                   	push   %edi
f010009d:	56                   	push   %esi
f010009e:	53                   	push   %ebx
f010009f:	83 ec 0c             	sub    $0xc,%esp
f01000a2:	e8 a8 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f01000a7:	81 c3 61 72 01 00    	add    $0x17261,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 c4 96 11 f0    	mov    $0xf01196c4,%eax
f01000b6:	83 38 00             	cmpl   $0x0,(%eax)
f01000b9:	74 0f                	je     f01000ca <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000bb:	83 ec 0c             	sub    $0xc,%esp
f01000be:	6a 00                	push   $0x0
f01000c0:	e8 5b 07 00 00       	call   f0100820 <monitor>
f01000c5:	83 c4 10             	add    $0x10,%esp
f01000c8:	eb f1                	jmp    f01000bb <_panic+0x22>
	panicstr = fmt;
f01000ca:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000cc:	fa                   	cli    
f01000cd:	fc                   	cld    
	va_start(ap, fmt);
f01000ce:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d1:	83 ec 04             	sub    $0x4,%esp
f01000d4:	ff 75 0c             	pushl  0xc(%ebp)
f01000d7:	ff 75 08             	pushl  0x8(%ebp)
f01000da:	8d 83 33 cd fe ff    	lea    -0x132cd(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 95 2f 00 00       	call   f010307b <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 54 2f 00 00       	call   f0103044 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 7f d4 fe ff    	lea    -0x12b81(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 7d 2f 00 00       	call   f010307b <cprintf>
f01000fe:	83 c4 10             	add    $0x10,%esp
f0100101:	eb b8                	jmp    f01000bb <_panic+0x22>

f0100103 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100103:	55                   	push   %ebp
f0100104:	89 e5                	mov    %esp,%ebp
f0100106:	56                   	push   %esi
f0100107:	53                   	push   %ebx
f0100108:	e8 42 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010010d:	81 c3 fb 71 01 00    	add    $0x171fb,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 4b cd fe ff    	lea    -0x132b5(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 50 2f 00 00       	call   f010307b <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 0d 2f 00 00       	call   f0103044 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 7f d4 fe ff    	lea    -0x12b81(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 36 2f 00 00       	call   f010307b <cprintf>
	va_end(ap);
}
f0100145:	83 c4 10             	add    $0x10,%esp
f0100148:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010014b:	5b                   	pop    %ebx
f010014c:	5e                   	pop    %esi
f010014d:	5d                   	pop    %ebp
f010014e:	c3                   	ret    

f010014f <__x86.get_pc_thunk.bx>:
f010014f:	8b 1c 24             	mov    (%esp),%ebx
f0100152:	c3                   	ret    

f0100153 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100153:	55                   	push   %ebp
f0100154:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100156:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010015b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 0b                	je     f010016b <serial_proc_data+0x18>
f0100160:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100165:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100166:	0f b6 c0             	movzbl %al,%eax
}
f0100169:	5d                   	pop    %ebp
f010016a:	c3                   	ret    
		return -1;
f010016b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100170:	eb f7                	jmp    f0100169 <serial_proc_data+0x16>

f0100172 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100172:	55                   	push   %ebp
f0100173:	89 e5                	mov    %esp,%ebp
f0100175:	56                   	push   %esi
f0100176:	53                   	push   %ebx
f0100177:	e8 d3 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010017c:	81 c3 8c 71 01 00    	add    $0x1718c,%ebx
f0100182:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f0100184:	ff d6                	call   *%esi
f0100186:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100189:	74 2e                	je     f01001b9 <cons_intr+0x47>
		if (c == 0)
f010018b:	85 c0                	test   %eax,%eax
f010018d:	74 f5                	je     f0100184 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f010018f:	8b 8b 7c 1f 00 00    	mov    0x1f7c(%ebx),%ecx
f0100195:	8d 51 01             	lea    0x1(%ecx),%edx
f0100198:	89 93 7c 1f 00 00    	mov    %edx,0x1f7c(%ebx)
f010019e:	88 84 0b 78 1d 00 00 	mov    %al,0x1d78(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ab:	75 d7                	jne    f0100184 <cons_intr+0x12>
			cons.wpos = 0;
f01001ad:	c7 83 7c 1f 00 00 00 	movl   $0x0,0x1f7c(%ebx)
f01001b4:	00 00 00 
f01001b7:	eb cb                	jmp    f0100184 <cons_intr+0x12>
	}
}
f01001b9:	5b                   	pop    %ebx
f01001ba:	5e                   	pop    %esi
f01001bb:	5d                   	pop    %ebp
f01001bc:	c3                   	ret    

f01001bd <kbd_proc_data>:
{
f01001bd:	55                   	push   %ebp
f01001be:	89 e5                	mov    %esp,%ebp
f01001c0:	56                   	push   %esi
f01001c1:	53                   	push   %ebx
f01001c2:	e8 88 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01001c7:	81 c3 41 71 01 00    	add    $0x17141,%ebx
f01001cd:	ba 64 00 00 00       	mov    $0x64,%edx
f01001d2:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001d3:	a8 01                	test   $0x1,%al
f01001d5:	0f 84 06 01 00 00    	je     f01002e1 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f01001db:	a8 20                	test   $0x20,%al
f01001dd:	0f 85 05 01 00 00    	jne    f01002e8 <kbd_proc_data+0x12b>
f01001e3:	ba 60 00 00 00       	mov    $0x60,%edx
f01001e8:	ec                   	in     (%dx),%al
f01001e9:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001eb:	3c e0                	cmp    $0xe0,%al
f01001ed:	0f 84 93 00 00 00    	je     f0100286 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f01001f3:	84 c0                	test   %al,%al
f01001f5:	0f 88 a0 00 00 00    	js     f010029b <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f01001fb:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x57>
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 8b 58 1d 00 00    	mov    %ecx,0x1d58(%ebx)
	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
f0100217:	0f b6 84 13 98 ce fe 	movzbl -0x13168(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 98 cd fe 	movzbl -0x13268(%ebx,%edx,1),%ecx
f010022c:	ff 
f010022d:	31 c8                	xor    %ecx,%eax
f010022f:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100235:	89 c1                	mov    %eax,%ecx
f0100237:	83 e1 03             	and    $0x3,%ecx
f010023a:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f0100241:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100245:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100248:	a8 08                	test   $0x8,%al
f010024a:	74 0d                	je     f0100259 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f010024c:	89 f2                	mov    %esi,%edx
f010024e:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100251:	83 f9 19             	cmp    $0x19,%ecx
f0100254:	77 7a                	ja     f01002d0 <kbd_proc_data+0x113>
			c += 'A' - 'a';
f0100256:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100259:	f7 d0                	not    %eax
f010025b:	a8 06                	test   $0x6,%al
f010025d:	75 33                	jne    f0100292 <kbd_proc_data+0xd5>
f010025f:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f0100265:	75 2b                	jne    f0100292 <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f0100267:	83 ec 0c             	sub    $0xc,%esp
f010026a:	8d 83 65 cd fe ff    	lea    -0x1329b(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 05 2e 00 00       	call   f010307b <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100276:	b8 03 00 00 00       	mov    $0x3,%eax
f010027b:	ba 92 00 00 00       	mov    $0x92,%edx
f0100280:	ee                   	out    %al,(%dx)
f0100281:	83 c4 10             	add    $0x10,%esp
f0100284:	eb 0c                	jmp    f0100292 <kbd_proc_data+0xd5>
		shift |= E0ESC;
f0100286:	83 8b 58 1d 00 00 40 	orl    $0x40,0x1d58(%ebx)
		return 0;
f010028d:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100292:	89 f0                	mov    %esi,%eax
f0100294:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100297:	5b                   	pop    %ebx
f0100298:	5e                   	pop    %esi
f0100299:	5d                   	pop    %ebp
f010029a:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010029b:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f01002a1:	89 ce                	mov    %ecx,%esi
f01002a3:	83 e6 40             	and    $0x40,%esi
f01002a6:	83 e0 7f             	and    $0x7f,%eax
f01002a9:	85 f6                	test   %esi,%esi
f01002ab:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002ae:	0f b6 d2             	movzbl %dl,%edx
f01002b1:	0f b6 84 13 98 ce fe 	movzbl -0x13168(%ebx,%edx,1),%eax
f01002b8:	ff 
f01002b9:	83 c8 40             	or     $0x40,%eax
f01002bc:	0f b6 c0             	movzbl %al,%eax
f01002bf:	f7 d0                	not    %eax
f01002c1:	21 c8                	and    %ecx,%eax
f01002c3:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
		return 0;
f01002c9:	be 00 00 00 00       	mov    $0x0,%esi
f01002ce:	eb c2                	jmp    f0100292 <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f01002d0:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002d3:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002d6:	83 fa 1a             	cmp    $0x1a,%edx
f01002d9:	0f 42 f1             	cmovb  %ecx,%esi
f01002dc:	e9 78 ff ff ff       	jmp    f0100259 <kbd_proc_data+0x9c>
		return -1;
f01002e1:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002e6:	eb aa                	jmp    f0100292 <kbd_proc_data+0xd5>
		return -1;
f01002e8:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002ed:	eb a3                	jmp    f0100292 <kbd_proc_data+0xd5>

f01002ef <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ef:	55                   	push   %ebp
f01002f0:	89 e5                	mov    %esp,%ebp
f01002f2:	57                   	push   %edi
f01002f3:	56                   	push   %esi
f01002f4:	53                   	push   %ebx
f01002f5:	83 ec 1c             	sub    $0x1c,%esp
f01002f8:	e8 52 fe ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01002fd:	81 c3 0b 70 01 00    	add    $0x1700b,%ebx
f0100303:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100306:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030b:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100310:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100315:	eb 09                	jmp    f0100320 <cons_putc+0x31>
f0100317:	89 ca                	mov    %ecx,%edx
f0100319:	ec                   	in     (%dx),%al
f010031a:	ec                   	in     (%dx),%al
f010031b:	ec                   	in     (%dx),%al
f010031c:	ec                   	in     (%dx),%al
	     i++)
f010031d:	83 c6 01             	add    $0x1,%esi
f0100320:	89 fa                	mov    %edi,%edx
f0100322:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100323:	a8 20                	test   $0x20,%al
f0100325:	75 08                	jne    f010032f <cons_putc+0x40>
f0100327:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010032d:	7e e8                	jle    f0100317 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f010032f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100332:	89 f8                	mov    %edi,%eax
f0100334:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100337:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010033c:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010033d:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100342:	bf 79 03 00 00       	mov    $0x379,%edi
f0100347:	b9 84 00 00 00       	mov    $0x84,%ecx
f010034c:	eb 09                	jmp    f0100357 <cons_putc+0x68>
f010034e:	89 ca                	mov    %ecx,%edx
f0100350:	ec                   	in     (%dx),%al
f0100351:	ec                   	in     (%dx),%al
f0100352:	ec                   	in     (%dx),%al
f0100353:	ec                   	in     (%dx),%al
f0100354:	83 c6 01             	add    $0x1,%esi
f0100357:	89 fa                	mov    %edi,%edx
f0100359:	ec                   	in     (%dx),%al
f010035a:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100360:	7f 04                	jg     f0100366 <cons_putc+0x77>
f0100362:	84 c0                	test   %al,%al
f0100364:	79 e8                	jns    f010034e <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100366:	ba 78 03 00 00       	mov    $0x378,%edx
f010036b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f010036f:	ee                   	out    %al,(%dx)
f0100370:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100375:	b8 0d 00 00 00       	mov    $0xd,%eax
f010037a:	ee                   	out    %al,(%dx)
f010037b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100380:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100381:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100384:	89 fa                	mov    %edi,%edx
f0100386:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010038c:	89 f8                	mov    %edi,%eax
f010038e:	80 cc 07             	or     $0x7,%ah
f0100391:	85 d2                	test   %edx,%edx
f0100393:	0f 45 c7             	cmovne %edi,%eax
f0100396:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100399:	0f b6 c0             	movzbl %al,%eax
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	0f 84 b9 00 00 00    	je     f010045e <cons_putc+0x16f>
f01003a5:	83 f8 09             	cmp    $0x9,%eax
f01003a8:	7e 74                	jle    f010041e <cons_putc+0x12f>
f01003aa:	83 f8 0a             	cmp    $0xa,%eax
f01003ad:	0f 84 9e 00 00 00    	je     f0100451 <cons_putc+0x162>
f01003b3:	83 f8 0d             	cmp    $0xd,%eax
f01003b6:	0f 85 d9 00 00 00    	jne    f0100495 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f01003bc:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f01003c3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c9:	c1 e8 16             	shr    $0x16,%eax
f01003cc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003cf:	c1 e0 04             	shl    $0x4,%eax
f01003d2:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003d9:	66 81 bb 80 1f 00 00 	cmpw   $0x7cf,0x1f80(%ebx)
f01003e0:	cf 07 
f01003e2:	0f 87 d4 00 00 00    	ja     f01004bc <cons_putc+0x1cd>
	outb(addr_6845, 14);
f01003e8:	8b 8b 88 1f 00 00    	mov    0x1f88(%ebx),%ecx
f01003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003f3:	89 ca                	mov    %ecx,%edx
f01003f5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003f6:	0f b7 9b 80 1f 00 00 	movzwl 0x1f80(%ebx),%ebx
f01003fd:	8d 71 01             	lea    0x1(%ecx),%esi
f0100400:	89 d8                	mov    %ebx,%eax
f0100402:	66 c1 e8 08          	shr    $0x8,%ax
f0100406:	89 f2                	mov    %esi,%edx
f0100408:	ee                   	out    %al,(%dx)
f0100409:	b8 0f 00 00 00       	mov    $0xf,%eax
f010040e:	89 ca                	mov    %ecx,%edx
f0100410:	ee                   	out    %al,(%dx)
f0100411:	89 d8                	mov    %ebx,%eax
f0100413:	89 f2                	mov    %esi,%edx
f0100415:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100416:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100419:	5b                   	pop    %ebx
f010041a:	5e                   	pop    %esi
f010041b:	5f                   	pop    %edi
f010041c:	5d                   	pop    %ebp
f010041d:	c3                   	ret    
	switch (c & 0xff) {
f010041e:	83 f8 08             	cmp    $0x8,%eax
f0100421:	75 72                	jne    f0100495 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f0100423:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010042a:	66 85 c0             	test   %ax,%ax
f010042d:	74 b9                	je     f01003e8 <cons_putc+0xf9>
			crt_pos--;
f010042f:	83 e8 01             	sub    $0x1,%eax
f0100432:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100440:	b2 00                	mov    $0x0,%dl
f0100442:	83 ca 20             	or     $0x20,%edx
f0100445:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f010044b:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010044f:	eb 88                	jmp    f01003d9 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100451:	66 83 83 80 1f 00 00 	addw   $0x50,0x1f80(%ebx)
f0100458:	50 
f0100459:	e9 5e ff ff ff       	jmp    f01003bc <cons_putc+0xcd>
		cons_putc(' ');
f010045e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100463:	e8 87 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100468:	b8 20 00 00 00       	mov    $0x20,%eax
f010046d:	e8 7d fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100472:	b8 20 00 00 00       	mov    $0x20,%eax
f0100477:	e8 73 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f010047c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100481:	e8 69 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100486:	b8 20 00 00 00       	mov    $0x20,%eax
f010048b:	e8 5f fe ff ff       	call   f01002ef <cons_putc>
f0100490:	e9 44 ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100495:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010049c:	8d 50 01             	lea    0x1(%eax),%edx
f010049f:	66 89 93 80 1f 00 00 	mov    %dx,0x1f80(%ebx)
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f01004af:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004b3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b7:	e9 1d ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004bc:	8b 83 84 1f 00 00    	mov    0x1f84(%ebx),%eax
f01004c2:	83 ec 04             	sub    $0x4,%esp
f01004c5:	68 00 0f 00 00       	push   $0xf00
f01004ca:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d0:	52                   	push   %edx
f01004d1:	50                   	push   %eax
f01004d2:	e8 4d 37 00 00       	call   f0103c24 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004d7:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f01004dd:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004e3:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004e9:	83 c4 10             	add    $0x10,%esp
f01004ec:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004f1:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f4:	39 d0                	cmp    %edx,%eax
f01004f6:	75 f4                	jne    f01004ec <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f01004f8:	66 83 ab 80 1f 00 00 	subw   $0x50,0x1f80(%ebx)
f01004ff:	50 
f0100500:	e9 e3 fe ff ff       	jmp    f01003e8 <cons_putc+0xf9>

f0100505 <serial_intr>:
{
f0100505:	e8 e7 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010050a:	05 fe 6d 01 00       	add    $0x16dfe,%eax
	if (serial_exists)
f010050f:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 4b 8e fe ff    	lea    -0x171b5(%eax),%eax
f0100526:	e8 47 fc ff ff       	call   f0100172 <cons_intr>
}
f010052b:	c9                   	leave  
f010052c:	c3                   	ret    

f010052d <kbd_intr>:
{
f010052d:	55                   	push   %ebp
f010052e:	89 e5                	mov    %esp,%ebp
f0100530:	83 ec 08             	sub    $0x8,%esp
f0100533:	e8 b9 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0100538:	05 d0 6d 01 00       	add    $0x16dd0,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b5 8e fe ff    	lea    -0x1714b(%eax),%eax
f0100543:	e8 2a fc ff ff       	call   f0100172 <cons_intr>
}
f0100548:	c9                   	leave  
f0100549:	c3                   	ret    

f010054a <cons_getc>:
{
f010054a:	55                   	push   %ebp
f010054b:	89 e5                	mov    %esp,%ebp
f010054d:	53                   	push   %ebx
f010054e:	83 ec 04             	sub    $0x4,%esp
f0100551:	e8 f9 fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100556:	81 c3 b2 6d 01 00    	add    $0x16db2,%ebx
	serial_intr();
f010055c:	e8 a4 ff ff ff       	call   f0100505 <serial_intr>
	kbd_intr();
f0100561:	e8 c7 ff ff ff       	call   f010052d <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100566:	8b 93 78 1f 00 00    	mov    0x1f78(%ebx),%edx
	return 0;
f010056c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100571:	3b 93 7c 1f 00 00    	cmp    0x1f7c(%ebx),%edx
f0100577:	74 19                	je     f0100592 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100579:	8d 4a 01             	lea    0x1(%edx),%ecx
f010057c:	89 8b 78 1f 00 00    	mov    %ecx,0x1f78(%ebx)
f0100582:	0f b6 84 13 78 1d 00 	movzbl 0x1d78(%ebx,%edx,1),%eax
f0100589:	00 
		if (cons.rpos == CONSBUFSIZE)
f010058a:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100590:	74 06                	je     f0100598 <cons_getc+0x4e>
}
f0100592:	83 c4 04             	add    $0x4,%esp
f0100595:	5b                   	pop    %ebx
f0100596:	5d                   	pop    %ebp
f0100597:	c3                   	ret    
			cons.rpos = 0;
f0100598:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
f010059f:	00 00 00 
f01005a2:	eb ee                	jmp    f0100592 <cons_getc+0x48>

f01005a4 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005a4:	55                   	push   %ebp
f01005a5:	89 e5                	mov    %esp,%ebp
f01005a7:	57                   	push   %edi
f01005a8:	56                   	push   %esi
f01005a9:	53                   	push   %ebx
f01005aa:	83 ec 1c             	sub    $0x1c,%esp
f01005ad:	e8 9d fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01005b2:	81 c3 56 6d 01 00    	add    $0x16d56,%ebx
	was = *cp;
f01005b8:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005bf:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005c6:	5a a5 
	if (*cp != 0xA55A) {
f01005c8:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005cf:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005d3:	0f 84 bc 00 00 00    	je     f0100695 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01005d9:	c7 83 88 1f 00 00 b4 	movl   $0x3b4,0x1f88(%ebx)
f01005e0:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005e3:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01005ea:	8b bb 88 1f 00 00    	mov    0x1f88(%ebx),%edi
f01005f0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005f5:	89 fa                	mov    %edi,%edx
f01005f7:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005f8:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005fb:	89 ca                	mov    %ecx,%edx
f01005fd:	ec                   	in     (%dx),%al
f01005fe:	0f b6 f0             	movzbl %al,%esi
f0100601:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100604:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100609:	89 fa                	mov    %edi,%edx
f010060b:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010060c:	89 ca                	mov    %ecx,%edx
f010060e:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010060f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100612:	89 bb 84 1f 00 00    	mov    %edi,0x1f84(%ebx)
	pos |= inb(addr_6845 + 1);
f0100618:	0f b6 c0             	movzbl %al,%eax
f010061b:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010061d:	66 89 b3 80 1f 00 00 	mov    %si,0x1f80(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100624:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100629:	89 c8                	mov    %ecx,%eax
f010062b:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100630:	ee                   	out    %al,(%dx)
f0100631:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100636:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010063b:	89 fa                	mov    %edi,%edx
f010063d:	ee                   	out    %al,(%dx)
f010063e:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100643:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100648:	ee                   	out    %al,(%dx)
f0100649:	be f9 03 00 00       	mov    $0x3f9,%esi
f010064e:	89 c8                	mov    %ecx,%eax
f0100650:	89 f2                	mov    %esi,%edx
f0100652:	ee                   	out    %al,(%dx)
f0100653:	b8 03 00 00 00       	mov    $0x3,%eax
f0100658:	89 fa                	mov    %edi,%edx
f010065a:	ee                   	out    %al,(%dx)
f010065b:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100660:	89 c8                	mov    %ecx,%eax
f0100662:	ee                   	out    %al,(%dx)
f0100663:	b8 01 00 00 00       	mov    $0x1,%eax
f0100668:	89 f2                	mov    %esi,%edx
f010066a:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010066b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100670:	ec                   	in     (%dx),%al
f0100671:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100673:	3c ff                	cmp    $0xff,%al
f0100675:	0f 95 83 8c 1f 00 00 	setne  0x1f8c(%ebx)
f010067c:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100681:	ec                   	in     (%dx),%al
f0100682:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100687:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100688:	80 f9 ff             	cmp    $0xff,%cl
f010068b:	74 25                	je     f01006b2 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f010068d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100690:	5b                   	pop    %ebx
f0100691:	5e                   	pop    %esi
f0100692:	5f                   	pop    %edi
f0100693:	5d                   	pop    %ebp
f0100694:	c3                   	ret    
		*cp = was;
f0100695:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010069c:	c7 83 88 1f 00 00 d4 	movl   $0x3d4,0x1f88(%ebx)
f01006a3:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a6:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006ad:	e9 38 ff ff ff       	jmp    f01005ea <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006b2:	83 ec 0c             	sub    $0xc,%esp
f01006b5:	8d 83 71 cd fe ff    	lea    -0x1328f(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 ba 29 00 00       	call   f010307b <cprintf>
f01006c1:	83 c4 10             	add    $0x10,%esp
}
f01006c4:	eb c7                	jmp    f010068d <cons_init+0xe9>

f01006c6 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006c6:	55                   	push   %ebp
f01006c7:	89 e5                	mov    %esp,%ebp
f01006c9:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01006cf:	e8 1b fc ff ff       	call   f01002ef <cons_putc>
}
f01006d4:	c9                   	leave  
f01006d5:	c3                   	ret    

f01006d6 <getchar>:

int
getchar(void)
{
f01006d6:	55                   	push   %ebp
f01006d7:	89 e5                	mov    %esp,%ebp
f01006d9:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006dc:	e8 69 fe ff ff       	call   f010054a <cons_getc>
f01006e1:	85 c0                	test   %eax,%eax
f01006e3:	74 f7                	je     f01006dc <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006e5:	c9                   	leave  
f01006e6:	c3                   	ret    

f01006e7 <iscons>:

int
iscons(int fdnum)
{
f01006e7:	55                   	push   %ebp
f01006e8:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01006ef:	5d                   	pop    %ebp
f01006f0:	c3                   	ret    

f01006f1 <__x86.get_pc_thunk.ax>:
f01006f1:	8b 04 24             	mov    (%esp),%eax
f01006f4:	c3                   	ret    

f01006f5 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006f5:	55                   	push   %ebp
f01006f6:	89 e5                	mov    %esp,%ebp
f01006f8:	56                   	push   %esi
f01006f9:	53                   	push   %ebx
f01006fa:	e8 50 fa ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01006ff:	81 c3 09 6c 01 00    	add    $0x16c09,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 98 cf fe ff    	lea    -0x13068(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 b6 cf fe ff    	lea    -0x1304a(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 bb cf fe ff    	lea    -0x13045(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 59 29 00 00       	call   f010307b <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 24 d0 fe ff    	lea    -0x12fdc(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 c4 cf fe ff    	lea    -0x1303c(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 42 29 00 00       	call   f010307b <cprintf>
	return 0;
}
f0100739:	b8 00 00 00 00       	mov    $0x0,%eax
f010073e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100741:	5b                   	pop    %ebx
f0100742:	5e                   	pop    %esi
f0100743:	5d                   	pop    %ebp
f0100744:	c3                   	ret    

f0100745 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100745:	55                   	push   %ebp
f0100746:	89 e5                	mov    %esp,%ebp
f0100748:	57                   	push   %edi
f0100749:	56                   	push   %esi
f010074a:	53                   	push   %ebx
f010074b:	83 ec 18             	sub    $0x18,%esp
f010074e:	e8 fc f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100753:	81 c3 b5 6b 01 00    	add    $0x16bb5,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100759:	8d 83 cd cf fe ff    	lea    -0x13033(%ebx),%eax
f010075f:	50                   	push   %eax
f0100760:	e8 16 29 00 00       	call   f010307b <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100765:	83 c4 08             	add    $0x8,%esp
f0100768:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010076e:	8d 83 4c d0 fe ff    	lea    -0x12fb4(%ebx),%eax
f0100774:	50                   	push   %eax
f0100775:	e8 01 29 00 00       	call   f010307b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010077a:	83 c4 0c             	add    $0xc,%esp
f010077d:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100783:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100789:	50                   	push   %eax
f010078a:	57                   	push   %edi
f010078b:	8d 83 74 d0 fe ff    	lea    -0x12f8c(%ebx),%eax
f0100791:	50                   	push   %eax
f0100792:	e8 e4 28 00 00       	call   f010307b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100797:	83 c4 0c             	add    $0xc,%esp
f010079a:	c7 c0 19 40 10 f0    	mov    $0xf0104019,%eax
f01007a0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007a6:	52                   	push   %edx
f01007a7:	50                   	push   %eax
f01007a8:	8d 83 98 d0 fe ff    	lea    -0x12f68(%ebx),%eax
f01007ae:	50                   	push   %eax
f01007af:	e8 c7 28 00 00       	call   f010307b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007b4:	83 c4 0c             	add    $0xc,%esp
f01007b7:	c7 c0 60 90 11 f0    	mov    $0xf0119060,%eax
f01007bd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007c3:	52                   	push   %edx
f01007c4:	50                   	push   %eax
f01007c5:	8d 83 bc d0 fe ff    	lea    -0x12f44(%ebx),%eax
f01007cb:	50                   	push   %eax
f01007cc:	e8 aa 28 00 00       	call   f010307b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007d1:	83 c4 0c             	add    $0xc,%esp
f01007d4:	c7 c6 c0 96 11 f0    	mov    $0xf01196c0,%esi
f01007da:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007e0:	50                   	push   %eax
f01007e1:	56                   	push   %esi
f01007e2:	8d 83 e0 d0 fe ff    	lea    -0x12f20(%ebx),%eax
f01007e8:	50                   	push   %eax
f01007e9:	e8 8d 28 00 00       	call   f010307b <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007ee:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007f1:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f01007f7:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f9:	c1 fe 0a             	sar    $0xa,%esi
f01007fc:	56                   	push   %esi
f01007fd:	8d 83 04 d1 fe ff    	lea    -0x12efc(%ebx),%eax
f0100803:	50                   	push   %eax
f0100804:	e8 72 28 00 00       	call   f010307b <cprintf>
	return 0;
}
f0100809:	b8 00 00 00 00       	mov    $0x0,%eax
f010080e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100811:	5b                   	pop    %ebx
f0100812:	5e                   	pop    %esi
f0100813:	5f                   	pop    %edi
f0100814:	5d                   	pop    %ebp
f0100815:	c3                   	ret    

f0100816 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100816:	55                   	push   %ebp
f0100817:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100819:	b8 00 00 00 00       	mov    $0x0,%eax
f010081e:	5d                   	pop    %ebp
f010081f:	c3                   	ret    

f0100820 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100820:	55                   	push   %ebp
f0100821:	89 e5                	mov    %esp,%ebp
f0100823:	57                   	push   %edi
f0100824:	56                   	push   %esi
f0100825:	53                   	push   %ebx
f0100826:	83 ec 68             	sub    $0x68,%esp
f0100829:	e8 21 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010082e:	81 c3 da 6a 01 00    	add    $0x16ada,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100834:	8d 83 30 d1 fe ff    	lea    -0x12ed0(%ebx),%eax
f010083a:	50                   	push   %eax
f010083b:	e8 3b 28 00 00       	call   f010307b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100840:	8d 83 54 d1 fe ff    	lea    -0x12eac(%ebx),%eax
f0100846:	89 04 24             	mov    %eax,(%esp)
f0100849:	e8 2d 28 00 00       	call   f010307b <cprintf>
f010084e:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100851:	8d bb ea cf fe ff    	lea    -0x13016(%ebx),%edi
f0100857:	eb 4a                	jmp    f01008a3 <monitor+0x83>
f0100859:	83 ec 08             	sub    $0x8,%esp
f010085c:	0f be c0             	movsbl %al,%eax
f010085f:	50                   	push   %eax
f0100860:	57                   	push   %edi
f0100861:	e8 34 33 00 00       	call   f0103b9a <strchr>
f0100866:	83 c4 10             	add    $0x10,%esp
f0100869:	85 c0                	test   %eax,%eax
f010086b:	74 08                	je     f0100875 <monitor+0x55>
			*buf++ = 0;
f010086d:	c6 06 00             	movb   $0x0,(%esi)
f0100870:	8d 76 01             	lea    0x1(%esi),%esi
f0100873:	eb 79                	jmp    f01008ee <monitor+0xce>
		if (*buf == 0)
f0100875:	80 3e 00             	cmpb   $0x0,(%esi)
f0100878:	74 7f                	je     f01008f9 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f010087a:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f010087e:	74 0f                	je     f010088f <monitor+0x6f>
		argv[argc++] = buf;
f0100880:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100883:	8d 48 01             	lea    0x1(%eax),%ecx
f0100886:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100889:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f010088d:	eb 44                	jmp    f01008d3 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010088f:	83 ec 08             	sub    $0x8,%esp
f0100892:	6a 10                	push   $0x10
f0100894:	8d 83 ef cf fe ff    	lea    -0x13011(%ebx),%eax
f010089a:	50                   	push   %eax
f010089b:	e8 db 27 00 00       	call   f010307b <cprintf>
f01008a0:	83 c4 10             	add    $0x10,%esp
	//cprintf("%d %d\n", sizeof(char), sizeof(int)); 
	// Nikhil won lol


	while (1) {
		buf = readline("K> ");
f01008a3:	8d 83 e6 cf fe ff    	lea    -0x1301a(%ebx),%eax
f01008a9:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01008ac:	83 ec 0c             	sub    $0xc,%esp
f01008af:	ff 75 a4             	pushl  -0x5c(%ebp)
f01008b2:	e8 ab 30 00 00       	call   f0103962 <readline>
f01008b7:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01008b9:	83 c4 10             	add    $0x10,%esp
f01008bc:	85 c0                	test   %eax,%eax
f01008be:	74 ec                	je     f01008ac <monitor+0x8c>
	argv[argc] = 0;
f01008c0:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01008c7:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f01008ce:	eb 1e                	jmp    f01008ee <monitor+0xce>
			buf++;
f01008d0:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d3:	0f b6 06             	movzbl (%esi),%eax
f01008d6:	84 c0                	test   %al,%al
f01008d8:	74 14                	je     f01008ee <monitor+0xce>
f01008da:	83 ec 08             	sub    $0x8,%esp
f01008dd:	0f be c0             	movsbl %al,%eax
f01008e0:	50                   	push   %eax
f01008e1:	57                   	push   %edi
f01008e2:	e8 b3 32 00 00       	call   f0103b9a <strchr>
f01008e7:	83 c4 10             	add    $0x10,%esp
f01008ea:	85 c0                	test   %eax,%eax
f01008ec:	74 e2                	je     f01008d0 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f01008ee:	0f b6 06             	movzbl (%esi),%eax
f01008f1:	84 c0                	test   %al,%al
f01008f3:	0f 85 60 ff ff ff    	jne    f0100859 <monitor+0x39>
	argv[argc] = 0;
f01008f9:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01008fc:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100903:	00 
	if (argc == 0)
f0100904:	85 c0                	test   %eax,%eax
f0100906:	74 9b                	je     f01008a3 <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100908:	83 ec 08             	sub    $0x8,%esp
f010090b:	8d 83 b6 cf fe ff    	lea    -0x1304a(%ebx),%eax
f0100911:	50                   	push   %eax
f0100912:	ff 75 a8             	pushl  -0x58(%ebp)
f0100915:	e8 22 32 00 00       	call   f0103b3c <strcmp>
f010091a:	83 c4 10             	add    $0x10,%esp
f010091d:	85 c0                	test   %eax,%eax
f010091f:	74 38                	je     f0100959 <monitor+0x139>
f0100921:	83 ec 08             	sub    $0x8,%esp
f0100924:	8d 83 c4 cf fe ff    	lea    -0x1303c(%ebx),%eax
f010092a:	50                   	push   %eax
f010092b:	ff 75 a8             	pushl  -0x58(%ebp)
f010092e:	e8 09 32 00 00       	call   f0103b3c <strcmp>
f0100933:	83 c4 10             	add    $0x10,%esp
f0100936:	85 c0                	test   %eax,%eax
f0100938:	74 1a                	je     f0100954 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f010093a:	83 ec 08             	sub    $0x8,%esp
f010093d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100940:	8d 83 0c d0 fe ff    	lea    -0x12ff4(%ebx),%eax
f0100946:	50                   	push   %eax
f0100947:	e8 2f 27 00 00       	call   f010307b <cprintf>
f010094c:	83 c4 10             	add    $0x10,%esp
f010094f:	e9 4f ff ff ff       	jmp    f01008a3 <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100954:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100959:	83 ec 04             	sub    $0x4,%esp
f010095c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010095f:	ff 75 08             	pushl  0x8(%ebp)
f0100962:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100965:	52                   	push   %edx
f0100966:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100969:	ff 94 83 10 1d 00 00 	call   *0x1d10(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100970:	83 c4 10             	add    $0x10,%esp
f0100973:	85 c0                	test   %eax,%eax
f0100975:	0f 89 28 ff ff ff    	jns    f01008a3 <monitor+0x83>
				break;
	}
}
f010097b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010097e:	5b                   	pop    %ebx
f010097f:	5e                   	pop    %esi
f0100980:	5f                   	pop    %edi
f0100981:	5d                   	pop    %ebp
f0100982:	c3                   	ret    

f0100983 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
f0100986:	57                   	push   %edi
f0100987:	56                   	push   %esi
f0100988:	53                   	push   %ebx
f0100989:	83 ec 18             	sub    $0x18,%esp
f010098c:	e8 be f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100991:	81 c3 77 69 01 00    	add    $0x16977,%ebx
f0100997:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100999:	50                   	push   %eax
f010099a:	e8 55 26 00 00       	call   f0102ff4 <mc146818_read>
f010099f:	89 c6                	mov    %eax,%esi
f01009a1:	83 c7 01             	add    $0x1,%edi
f01009a4:	89 3c 24             	mov    %edi,(%esp)
f01009a7:	e8 48 26 00 00       	call   f0102ff4 <mc146818_read>
f01009ac:	c1 e0 08             	shl    $0x8,%eax
f01009af:	09 f0                	or     %esi,%eax
}
f01009b1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009b4:	5b                   	pop    %ebx
f01009b5:	5e                   	pop    %esi
f01009b6:	5f                   	pop    %edi
f01009b7:	5d                   	pop    %ebp
f01009b8:	c3                   	ret    

f01009b9 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009b9:	55                   	push   %ebp
f01009ba:	89 e5                	mov    %esp,%ebp
f01009bc:	53                   	push   %ebx
f01009bd:	83 ec 04             	sub    $0x4,%esp
f01009c0:	e8 23 26 00 00       	call   f0102fe8 <__x86.get_pc_thunk.cx>
f01009c5:	81 c1 43 69 01 00    	add    $0x16943,%ecx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009cb:	83 b9 90 1f 00 00 00 	cmpl   $0x0,0x1f90(%ecx)
f01009d2:	74 28                	je     f01009fc <boot_alloc+0x43>
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	char * returnAddress = nextfree;
f01009d4:	8b 99 90 1f 00 00    	mov    0x1f90(%ecx),%ebx
	//         HEX    f    f    f    f    f    f    f    f
	
	// nextfree is already at a page granularity

	// ROUNDING UP TOTAL BYTES instead of page by page 
	nextfree = ROUNDUP(returnAddress + n, PGSIZE);
f01009da:	8d 94 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%edx
f01009e1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009e7:	89 91 90 1f 00 00    	mov    %edx,0x1f90(%ecx)

	// our limit is set to the capacity of a page tables worth of pages.
	if((uintptr_t) nextfree >= KERNBASE + NPTENTRIES * PGSIZE){
f01009ed:	81 fa ff ff 3f f0    	cmp    $0xf03fffff,%edx
f01009f3:	77 21                	ja     f0100a16 <boot_alloc+0x5d>
		panic("out of memory\n"); 
	}
	//cprintf("fin: %x\n", (int) finalAddress); // used this to identify which portion of memory the pages get allocated in
	return returnAddress;
}
f01009f5:	89 d8                	mov    %ebx,%eax
f01009f7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01009fa:	c9                   	leave  
f01009fb:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009fc:	c7 c2 c0 96 11 f0    	mov    $0xf01196c0,%edx
f0100a02:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100a08:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a0e:	89 91 90 1f 00 00    	mov    %edx,0x1f90(%ecx)
f0100a14:	eb be                	jmp    f01009d4 <boot_alloc+0x1b>
		panic("out of memory\n"); 
f0100a16:	83 ec 04             	sub    $0x4,%esp
f0100a19:	8d 81 79 d1 fe ff    	lea    -0x12e87(%ecx),%eax
f0100a1f:	50                   	push   %eax
f0100a20:	6a 7c                	push   $0x7c
f0100a22:	8d 81 88 d1 fe ff    	lea    -0x12e78(%ecx),%eax
f0100a28:	50                   	push   %eax
f0100a29:	89 cb                	mov    %ecx,%ebx
f0100a2b:	e8 69 f6 ff ff       	call   f0100099 <_panic>

f0100a30 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a30:	55                   	push   %ebp
f0100a31:	89 e5                	mov    %esp,%ebp
f0100a33:	56                   	push   %esi
f0100a34:	53                   	push   %ebx
f0100a35:	e8 ae 25 00 00       	call   f0102fe8 <__x86.get_pc_thunk.cx>
f0100a3a:	81 c1 ce 68 01 00    	add    $0x168ce,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a40:	89 d3                	mov    %edx,%ebx
f0100a42:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100a45:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100a48:	a8 01                	test   $0x1,%al
f0100a4a:	74 5a                	je     f0100aa6 <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a4c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a51:	89 c6                	mov    %eax,%esi
f0100a53:	c1 ee 0c             	shr    $0xc,%esi
f0100a56:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f0100a5c:	3b 33                	cmp    (%ebx),%esi
f0100a5e:	73 2b                	jae    f0100a8b <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100a60:	c1 ea 0c             	shr    $0xc,%edx
f0100a63:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a69:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a70:	89 c2                	mov    %eax,%edx
f0100a72:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a75:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a7a:	85 d2                	test   %edx,%edx
f0100a7c:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a81:	0f 44 c2             	cmove  %edx,%eax
}
f0100a84:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a87:	5b                   	pop    %ebx
f0100a88:	5e                   	pop    %esi
f0100a89:	5d                   	pop    %ebp
f0100a8a:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a8b:	50                   	push   %eax
f0100a8c:	8d 81 b4 d4 fe ff    	lea    -0x12b4c(%ecx),%eax
f0100a92:	50                   	push   %eax
f0100a93:	68 d9 03 00 00       	push   $0x3d9
f0100a98:	8d 81 88 d1 fe ff    	lea    -0x12e78(%ecx),%eax
f0100a9e:	50                   	push   %eax
f0100a9f:	89 cb                	mov    %ecx,%ebx
f0100aa1:	e8 f3 f5 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100aa6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100aab:	eb d7                	jmp    f0100a84 <check_va2pa+0x54>

f0100aad <check_page_free_list>:
{
f0100aad:	55                   	push   %ebp
f0100aae:	89 e5                	mov    %esp,%ebp
f0100ab0:	57                   	push   %edi
f0100ab1:	56                   	push   %esi
f0100ab2:	53                   	push   %ebx
f0100ab3:	83 ec 3c             	sub    $0x3c,%esp
f0100ab6:	e8 35 25 00 00       	call   f0102ff0 <__x86.get_pc_thunk.di>
f0100abb:	81 c7 4d 68 01 00    	add    $0x1684d,%edi
f0100ac1:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ac4:	84 c0                	test   %al,%al
f0100ac6:	0f 85 dd 02 00 00    	jne    f0100da9 <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100acc:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100acf:	83 b8 94 1f 00 00 00 	cmpl   $0x0,0x1f94(%eax)
f0100ad6:	74 0c                	je     f0100ae4 <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ad8:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100adf:	e9 2f 03 00 00       	jmp    f0100e13 <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100ae4:	83 ec 04             	sub    $0x4,%esp
f0100ae7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100aea:	8d 83 d8 d4 fe ff    	lea    -0x12b28(%ebx),%eax
f0100af0:	50                   	push   %eax
f0100af1:	68 17 03 00 00       	push   $0x317
f0100af6:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0100afc:	50                   	push   %eax
f0100afd:	e8 97 f5 ff ff       	call   f0100099 <_panic>
f0100b02:	50                   	push   %eax
f0100b03:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100b06:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f0100b0c:	50                   	push   %eax
f0100b0d:	6a 52                	push   $0x52
f0100b0f:	8d 83 94 d1 fe ff    	lea    -0x12e6c(%ebx),%eax
f0100b15:	50                   	push   %eax
f0100b16:	e8 7e f5 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b1b:	8b 36                	mov    (%esi),%esi
f0100b1d:	85 f6                	test   %esi,%esi
f0100b1f:	74 40                	je     f0100b61 <check_page_free_list+0xb4>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b21:	89 f0                	mov    %esi,%eax
f0100b23:	2b 07                	sub    (%edi),%eax
f0100b25:	c1 f8 03             	sar    $0x3,%eax
f0100b28:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b2b:	89 c2                	mov    %eax,%edx
f0100b2d:	c1 ea 16             	shr    $0x16,%edx
f0100b30:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100b33:	73 e6                	jae    f0100b1b <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100b35:	89 c2                	mov    %eax,%edx
f0100b37:	c1 ea 0c             	shr    $0xc,%edx
f0100b3a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100b3d:	3b 11                	cmp    (%ecx),%edx
f0100b3f:	73 c1                	jae    f0100b02 <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100b41:	83 ec 04             	sub    $0x4,%esp
f0100b44:	68 80 00 00 00       	push   $0x80
f0100b49:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100b4e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b53:	50                   	push   %eax
f0100b54:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100b57:	e8 7b 30 00 00       	call   f0103bd7 <memset>
f0100b5c:	83 c4 10             	add    $0x10,%esp
f0100b5f:	eb ba                	jmp    f0100b1b <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f0100b61:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b66:	e8 4e fe ff ff       	call   f01009b9 <boot_alloc>
f0100b6b:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b6e:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100b71:	8b 97 94 1f 00 00    	mov    0x1f94(%edi),%edx
		assert(pp >= pages);
f0100b77:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100b7d:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100b7f:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100b85:	8b 00                	mov    (%eax),%eax
f0100b87:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100b8a:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b8d:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b90:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b95:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b98:	e9 08 01 00 00       	jmp    f0100ca5 <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100b9d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ba0:	8d 83 a2 d1 fe ff    	lea    -0x12e5e(%ebx),%eax
f0100ba6:	50                   	push   %eax
f0100ba7:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0100bad:	50                   	push   %eax
f0100bae:	68 33 03 00 00       	push   $0x333
f0100bb3:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0100bb9:	50                   	push   %eax
f0100bba:	e8 da f4 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100bbf:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bc2:	8d 83 c3 d1 fe ff    	lea    -0x12e3d(%ebx),%eax
f0100bc8:	50                   	push   %eax
f0100bc9:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0100bcf:	50                   	push   %eax
f0100bd0:	68 34 03 00 00       	push   $0x334
f0100bd5:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0100bdb:	50                   	push   %eax
f0100bdc:	e8 b8 f4 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100be1:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100be4:	8d 83 fc d4 fe ff    	lea    -0x12b04(%ebx),%eax
f0100bea:	50                   	push   %eax
f0100beb:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0100bf1:	50                   	push   %eax
f0100bf2:	68 35 03 00 00       	push   $0x335
f0100bf7:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0100bfd:	50                   	push   %eax
f0100bfe:	e8 96 f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100c03:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c06:	8d 83 d7 d1 fe ff    	lea    -0x12e29(%ebx),%eax
f0100c0c:	50                   	push   %eax
f0100c0d:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0100c13:	50                   	push   %eax
f0100c14:	68 38 03 00 00       	push   $0x338
f0100c19:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0100c1f:	50                   	push   %eax
f0100c20:	e8 74 f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c25:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c28:	8d 83 e8 d1 fe ff    	lea    -0x12e18(%ebx),%eax
f0100c2e:	50                   	push   %eax
f0100c2f:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0100c35:	50                   	push   %eax
f0100c36:	68 39 03 00 00       	push   $0x339
f0100c3b:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0100c41:	50                   	push   %eax
f0100c42:	e8 52 f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c47:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c4a:	8d 83 30 d5 fe ff    	lea    -0x12ad0(%ebx),%eax
f0100c50:	50                   	push   %eax
f0100c51:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0100c57:	50                   	push   %eax
f0100c58:	68 3a 03 00 00       	push   $0x33a
f0100c5d:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0100c63:	50                   	push   %eax
f0100c64:	e8 30 f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c69:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c6c:	8d 83 01 d2 fe ff    	lea    -0x12dff(%ebx),%eax
f0100c72:	50                   	push   %eax
f0100c73:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0100c79:	50                   	push   %eax
f0100c7a:	68 3b 03 00 00       	push   $0x33b
f0100c7f:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0100c85:	50                   	push   %eax
f0100c86:	e8 0e f4 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100c8b:	89 c6                	mov    %eax,%esi
f0100c8d:	c1 ee 0c             	shr    $0xc,%esi
f0100c90:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100c93:	76 70                	jbe    f0100d05 <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100c95:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c9a:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100c9d:	77 7f                	ja     f0100d1e <check_page_free_list+0x271>
			++nfree_extmem;
f0100c9f:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ca3:	8b 12                	mov    (%edx),%edx
f0100ca5:	85 d2                	test   %edx,%edx
f0100ca7:	0f 84 93 00 00 00    	je     f0100d40 <check_page_free_list+0x293>
		assert(pp >= pages);
f0100cad:	39 d1                	cmp    %edx,%ecx
f0100caf:	0f 87 e8 fe ff ff    	ja     f0100b9d <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100cb5:	39 d3                	cmp    %edx,%ebx
f0100cb7:	0f 86 02 ff ff ff    	jbe    f0100bbf <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cbd:	89 d0                	mov    %edx,%eax
f0100cbf:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100cc2:	a8 07                	test   $0x7,%al
f0100cc4:	0f 85 17 ff ff ff    	jne    f0100be1 <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100cca:	c1 f8 03             	sar    $0x3,%eax
f0100ccd:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100cd0:	85 c0                	test   %eax,%eax
f0100cd2:	0f 84 2b ff ff ff    	je     f0100c03 <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cd8:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100cdd:	0f 84 42 ff ff ff    	je     f0100c25 <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ce3:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ce8:	0f 84 59 ff ff ff    	je     f0100c47 <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cee:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cf3:	0f 84 70 ff ff ff    	je     f0100c69 <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cf9:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cfe:	77 8b                	ja     f0100c8b <check_page_free_list+0x1de>
			++nfree_basemem;
f0100d00:	83 c7 01             	add    $0x1,%edi
f0100d03:	eb 9e                	jmp    f0100ca3 <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d05:	50                   	push   %eax
f0100d06:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d09:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f0100d0f:	50                   	push   %eax
f0100d10:	6a 52                	push   $0x52
f0100d12:	8d 83 94 d1 fe ff    	lea    -0x12e6c(%ebx),%eax
f0100d18:	50                   	push   %eax
f0100d19:	e8 7b f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d1e:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d21:	8d 83 54 d5 fe ff    	lea    -0x12aac(%ebx),%eax
f0100d27:	50                   	push   %eax
f0100d28:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0100d2e:	50                   	push   %eax
f0100d2f:	68 3c 03 00 00       	push   $0x33c
f0100d34:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0100d3a:	50                   	push   %eax
f0100d3b:	e8 59 f3 ff ff       	call   f0100099 <_panic>
f0100d40:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100d43:	85 ff                	test   %edi,%edi
f0100d45:	7e 1e                	jle    f0100d65 <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100d47:	85 f6                	test   %esi,%esi
f0100d49:	7e 3c                	jle    f0100d87 <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100d4b:	83 ec 0c             	sub    $0xc,%esp
f0100d4e:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d51:	8d 83 9c d5 fe ff    	lea    -0x12a64(%ebx),%eax
f0100d57:	50                   	push   %eax
f0100d58:	e8 1e 23 00 00       	call   f010307b <cprintf>
}
f0100d5d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d60:	5b                   	pop    %ebx
f0100d61:	5e                   	pop    %esi
f0100d62:	5f                   	pop    %edi
f0100d63:	5d                   	pop    %ebp
f0100d64:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100d65:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d68:	8d 83 1b d2 fe ff    	lea    -0x12de5(%ebx),%eax
f0100d6e:	50                   	push   %eax
f0100d6f:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0100d75:	50                   	push   %eax
f0100d76:	68 45 03 00 00       	push   $0x345
f0100d7b:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0100d81:	50                   	push   %eax
f0100d82:	e8 12 f3 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100d87:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d8a:	8d 83 2d d2 fe ff    	lea    -0x12dd3(%ebx),%eax
f0100d90:	50                   	push   %eax
f0100d91:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0100d97:	50                   	push   %eax
f0100d98:	68 46 03 00 00       	push   $0x346
f0100d9d:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0100da3:	50                   	push   %eax
f0100da4:	e8 f0 f2 ff ff       	call   f0100099 <_panic>
	if (!page_free_list)
f0100da9:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100dac:	8b 80 94 1f 00 00    	mov    0x1f94(%eax),%eax
f0100db2:	85 c0                	test   %eax,%eax
f0100db4:	0f 84 2a fd ff ff    	je     f0100ae4 <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100dba:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100dbd:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100dc0:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100dc3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100dc6:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100dc9:	c7 c3 d0 96 11 f0    	mov    $0xf01196d0,%ebx
f0100dcf:	89 c2                	mov    %eax,%edx
f0100dd1:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100dd3:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100dd9:	0f 95 c2             	setne  %dl
f0100ddc:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ddf:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100de3:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100de5:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100de9:	8b 00                	mov    (%eax),%eax
f0100deb:	85 c0                	test   %eax,%eax
f0100ded:	75 e0                	jne    f0100dcf <check_page_free_list+0x322>
		*tp[1] = 0;
f0100def:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100df2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100df8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100dfb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dfe:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100e00:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e03:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100e06:	89 87 94 1f 00 00    	mov    %eax,0x1f94(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e0c:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100e13:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100e16:	8b b0 94 1f 00 00    	mov    0x1f94(%eax),%esi
f0100e1c:	c7 c7 d0 96 11 f0    	mov    $0xf01196d0,%edi
	if (PGNUM(pa) >= npages)
f0100e22:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100e28:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e2b:	e9 ed fc ff ff       	jmp    f0100b1d <check_page_free_list+0x70>

f0100e30 <page_init>:
{
f0100e30:	55                   	push   %ebp
f0100e31:	89 e5                	mov    %esp,%ebp
f0100e33:	57                   	push   %edi
f0100e34:	56                   	push   %esi
f0100e35:	53                   	push   %ebx
f0100e36:	83 ec 2c             	sub    $0x2c,%esp
f0100e39:	e8 ae 21 00 00       	call   f0102fec <__x86.get_pc_thunk.si>
f0100e3e:	81 c6 ca 64 01 00    	add    $0x164ca,%esi
f0100e44:	89 75 d8             	mov    %esi,-0x28(%ebp)
	pages[0].pp_ref = 1;
f0100e47:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100e4d:	8b 00                	mov    (%eax),%eax
f0100e4f:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f0100e55:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	for(i = 1; i < npages_basemem; i++){
f0100e5b:	8b be 98 1f 00 00    	mov    0x1f98(%esi),%edi
f0100e61:	8b 9e 94 1f 00 00    	mov    0x1f94(%esi),%ebx
f0100e67:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e6c:	b8 01 00 00 00       	mov    $0x1,%eax
		pages[i].pp_ref = 0;
f0100e71:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
	for(i = 1; i < npages_basemem; i++){
f0100e77:	eb 1f                	jmp    f0100e98 <page_init+0x68>
		pages[i].pp_ref = 0;
f0100e79:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100e80:	89 d1                	mov    %edx,%ecx
f0100e82:	03 0e                	add    (%esi),%ecx
f0100e84:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100e8a:	89 19                	mov    %ebx,(%ecx)
	for(i = 1; i < npages_basemem; i++){
f0100e8c:	83 c0 01             	add    $0x1,%eax
		page_free_list = &pages[i];
f0100e8f:	89 d3                	mov    %edx,%ebx
f0100e91:	03 1e                	add    (%esi),%ebx
f0100e93:	ba 01 00 00 00       	mov    $0x1,%edx
	for(i = 1; i < npages_basemem; i++){
f0100e98:	39 c7                	cmp    %eax,%edi
f0100e9a:	77 dd                	ja     f0100e79 <page_init+0x49>
f0100e9c:	84 d2                	test   %dl,%dl
f0100e9e:	75 57                	jne    f0100ef7 <page_init+0xc7>
	uint32_t firstFreeAlloc = (uint32_t) boot_alloc(0);
f0100ea0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ea5:	e8 0f fb ff ff       	call   f01009b9 <boot_alloc>
f0100eaa:	89 45 e0             	mov    %eax,-0x20(%ebp)
	for(i = ((uint32_t)boot_alloc(0) - KERNBASE)/PGSIZE; i < npages; i++){
f0100ead:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eb2:	e8 02 fb ff ff       	call   f01009b9 <boot_alloc>
f0100eb7:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ebc:	c1 e8 0c             	shr    $0xc,%eax
f0100ebf:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100ec2:	8b be 94 1f 00 00    	mov    0x1f94(%esi),%edi
f0100ec8:	8d 90 00 00 0f 00    	lea    0xf0000(%eax),%edx
f0100ece:	c1 e2 0c             	shl    $0xc,%edx
f0100ed1:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100ed4:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0100edb:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100ee0:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0100ee6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			pages[i].pp_ref = 0;
f0100ee9:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
f0100eef:	89 75 dc             	mov    %esi,-0x24(%ebp)
f0100ef2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
	for(i = ((uint32_t)boot_alloc(0) - KERNBASE)/PGSIZE; i < npages; i++){
f0100ef5:	eb 17                	jmp    f0100f0e <page_init+0xde>
f0100ef7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100efa:	89 98 94 1f 00 00    	mov    %ebx,0x1f94(%eax)
f0100f00:	eb 9e                	jmp    f0100ea0 <page_init+0x70>
f0100f02:	83 c0 01             	add    $0x1,%eax
f0100f05:	81 c2 00 10 00 00    	add    $0x1000,%edx
f0100f0b:	83 c1 08             	add    $0x8,%ecx
f0100f0e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100f11:	39 06                	cmp    %eax,(%esi)
f0100f13:	76 22                	jbe    f0100f37 <page_init+0x107>
		if(KERNBASE + i * PGSIZE > firstFreeAlloc){
f0100f15:	39 55 e0             	cmp    %edx,-0x20(%ebp)
f0100f18:	73 e8                	jae    f0100f02 <page_init+0xd2>
			pages[i].pp_ref = 0;
f0100f1a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100f1d:	89 ce                	mov    %ecx,%esi
f0100f1f:	03 33                	add    (%ebx),%esi
f0100f21:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
			pages[i].pp_link = page_free_list;
f0100f27:	89 3e                	mov    %edi,(%esi)
			page_free_list = &pages[i];
f0100f29:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100f2c:	89 cf                	mov    %ecx,%edi
f0100f2e:	03 3b                	add    (%ebx),%edi
f0100f30:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100f35:	eb cb                	jmp    f0100f02 <page_init+0xd2>
f0100f37:	84 db                	test   %bl,%bl
f0100f39:	75 08                	jne    f0100f43 <page_init+0x113>
}
f0100f3b:	83 c4 2c             	add    $0x2c,%esp
f0100f3e:	5b                   	pop    %ebx
f0100f3f:	5e                   	pop    %esi
f0100f40:	5f                   	pop    %edi
f0100f41:	5d                   	pop    %ebp
f0100f42:	c3                   	ret    
f0100f43:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f46:	89 b8 94 1f 00 00    	mov    %edi,0x1f94(%eax)
f0100f4c:	eb ed                	jmp    f0100f3b <page_init+0x10b>

f0100f4e <page_alloc>:
{
f0100f4e:	55                   	push   %ebp
f0100f4f:	89 e5                	mov    %esp,%ebp
f0100f51:	56                   	push   %esi
f0100f52:	53                   	push   %ebx
f0100f53:	e8 f7 f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100f58:	81 c3 b0 63 01 00    	add    $0x163b0,%ebx
	struct PageInfo *page_pop = page_free_list;
f0100f5e:	8b b3 94 1f 00 00    	mov    0x1f94(%ebx),%esi
	if (page_pop == NULL)
f0100f64:	85 f6                	test   %esi,%esi
f0100f66:	74 14                	je     f0100f7c <page_alloc+0x2e>
	page_free_list = page_pop->pp_link;
f0100f68:	8b 06                	mov    (%esi),%eax
f0100f6a:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	page_pop->pp_link = NULL; 
f0100f70:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if (alloc_flags & ALLOC_ZERO)
f0100f76:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f7a:	75 09                	jne    f0100f85 <page_alloc+0x37>
}
f0100f7c:	89 f0                	mov    %esi,%eax
f0100f7e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f81:	5b                   	pop    %ebx
f0100f82:	5e                   	pop    %esi
f0100f83:	5d                   	pop    %ebp
f0100f84:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f0100f85:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100f8b:	89 f2                	mov    %esi,%edx
f0100f8d:	2b 10                	sub    (%eax),%edx
f0100f8f:	89 d0                	mov    %edx,%eax
f0100f91:	c1 f8 03             	sar    $0x3,%eax
f0100f94:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100f97:	89 c1                	mov    %eax,%ecx
f0100f99:	c1 e9 0c             	shr    $0xc,%ecx
f0100f9c:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0100fa2:	3b 0a                	cmp    (%edx),%ecx
f0100fa4:	73 1a                	jae    f0100fc0 <page_alloc+0x72>
		memset(ptr, 0, PGSIZE);
f0100fa6:	83 ec 04             	sub    $0x4,%esp
f0100fa9:	68 00 10 00 00       	push   $0x1000
f0100fae:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100fb0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fb5:	50                   	push   %eax
f0100fb6:	e8 1c 2c 00 00       	call   f0103bd7 <memset>
f0100fbb:	83 c4 10             	add    $0x10,%esp
f0100fbe:	eb bc                	jmp    f0100f7c <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fc0:	50                   	push   %eax
f0100fc1:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f0100fc7:	50                   	push   %eax
f0100fc8:	6a 52                	push   $0x52
f0100fca:	8d 83 94 d1 fe ff    	lea    -0x12e6c(%ebx),%eax
f0100fd0:	50                   	push   %eax
f0100fd1:	e8 c3 f0 ff ff       	call   f0100099 <_panic>

f0100fd6 <page_free>:
{
f0100fd6:	55                   	push   %ebp
f0100fd7:	89 e5                	mov    %esp,%ebp
f0100fd9:	53                   	push   %ebx
f0100fda:	83 ec 04             	sub    $0x4,%esp
f0100fdd:	e8 6d f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100fe2:	81 c3 26 63 01 00    	add    $0x16326,%ebx
f0100fe8:	8b 45 08             	mov    0x8(%ebp),%eax
	assert(pp->pp_ref == 0);  
f0100feb:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100ff0:	75 18                	jne    f010100a <page_free+0x34>
	assert(pp->pp_link == NULL); 
f0100ff2:	83 38 00             	cmpl   $0x0,(%eax)
f0100ff5:	75 32                	jne    f0101029 <page_free+0x53>
	pp->pp_link = page_free_list;
f0100ff7:	8b 8b 94 1f 00 00    	mov    0x1f94(%ebx),%ecx
f0100ffd:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f0100fff:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
}
f0101005:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101008:	c9                   	leave  
f0101009:	c3                   	ret    
	assert(pp->pp_ref == 0);  
f010100a:	8d 83 3e d2 fe ff    	lea    -0x12dc2(%ebx),%eax
f0101010:	50                   	push   %eax
f0101011:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0101017:	50                   	push   %eax
f0101018:	68 bc 01 00 00       	push   $0x1bc
f010101d:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0101023:	50                   	push   %eax
f0101024:	e8 70 f0 ff ff       	call   f0100099 <_panic>
	assert(pp->pp_link == NULL); 
f0101029:	8d 83 4e d2 fe ff    	lea    -0x12db2(%ebx),%eax
f010102f:	50                   	push   %eax
f0101030:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0101036:	50                   	push   %eax
f0101037:	68 c0 01 00 00       	push   $0x1c0
f010103c:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0101042:	50                   	push   %eax
f0101043:	e8 51 f0 ff ff       	call   f0100099 <_panic>

f0101048 <page_decref>:
{
f0101048:	55                   	push   %ebp
f0101049:	89 e5                	mov    %esp,%ebp
f010104b:	83 ec 08             	sub    $0x8,%esp
f010104e:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101051:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101055:	83 e8 01             	sub    $0x1,%eax
f0101058:	66 89 42 04          	mov    %ax,0x4(%edx)
f010105c:	66 85 c0             	test   %ax,%ax
f010105f:	74 02                	je     f0101063 <page_decref+0x1b>
}
f0101061:	c9                   	leave  
f0101062:	c3                   	ret    
		page_free(pp);
f0101063:	83 ec 0c             	sub    $0xc,%esp
f0101066:	52                   	push   %edx
f0101067:	e8 6a ff ff ff       	call   f0100fd6 <page_free>
f010106c:	83 c4 10             	add    $0x10,%esp
}
f010106f:	eb f0                	jmp    f0101061 <page_decref+0x19>

f0101071 <pgdir_walk>:
{
f0101071:	55                   	push   %ebp
f0101072:	89 e5                	mov    %esp,%ebp
f0101074:	57                   	push   %edi
f0101075:	56                   	push   %esi
f0101076:	53                   	push   %ebx
f0101077:	83 ec 0c             	sub    $0xc,%esp
f010107a:	e8 d0 f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010107f:	81 c3 89 62 01 00    	add    $0x16289,%ebx
f0101085:	8b 75 0c             	mov    0xc(%ebp),%esi
	uintptr_t pd_index = PDX(va);
f0101088:	89 f7                	mov    %esi,%edi
f010108a:	c1 ef 16             	shr    $0x16,%edi
	pde_t pd_entry = pgdir[pd_index];
f010108d:	c1 e7 02             	shl    $0x2,%edi
f0101090:	03 7d 08             	add    0x8(%ebp),%edi
f0101093:	8b 07                	mov    (%edi),%eax
	if (pd_entry == 0) 
f0101095:	85 c0                	test   %eax,%eax
f0101097:	75 71                	jne    f010110a <pgdir_walk+0x99>
		if (create == 0) // create 0 implies we don't want to initialize a new page dir entry
f0101099:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010109d:	0f 84 ae 00 00 00    	je     f0101151 <pgdir_walk+0xe0>
		newpg = page_alloc(ALLOC_ZERO);
f01010a3:	83 ec 0c             	sub    $0xc,%esp
f01010a6:	6a 01                	push   $0x1
f01010a8:	e8 a1 fe ff ff       	call   f0100f4e <page_alloc>
		if (!newpg)
f01010ad:	83 c4 10             	add    $0x10,%esp
f01010b0:	85 c0                	test   %eax,%eax
f01010b2:	0f 84 a0 00 00 00    	je     f0101158 <pgdir_walk+0xe7>
		newpg->pp_ref += 1;
f01010b8:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01010bd:	c7 c1 d0 96 11 f0    	mov    $0xf01196d0,%ecx
f01010c3:	89 c2                	mov    %eax,%edx
f01010c5:	2b 11                	sub    (%ecx),%edx
f01010c7:	c1 fa 03             	sar    $0x3,%edx
f01010ca:	c1 e2 0c             	shl    $0xc,%edx
		pgdir[PDX(va)] = (uintptr_t) page2pa(newpg) | PTE_P | PTE_U | PTE_W;
f01010cd:	83 ca 07             	or     $0x7,%edx
f01010d0:	89 17                	mov    %edx,(%edi)
f01010d2:	2b 01                	sub    (%ecx),%eax
f01010d4:	c1 f8 03             	sar    $0x3,%eax
f01010d7:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01010da:	89 c2                	mov    %eax,%edx
f01010dc:	c1 ea 0c             	shr    $0xc,%edx
f01010df:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f01010e5:	39 11                	cmp    %edx,(%ecx)
f01010e7:	76 08                	jbe    f01010f1 <pgdir_walk+0x80>
	return (void *)(pa + KERNBASE);
f01010e9:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f01010ef:	eb 33                	jmp    f0101124 <pgdir_walk+0xb3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010f1:	50                   	push   %eax
f01010f2:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f01010f8:	50                   	push   %eax
f01010f9:	68 17 02 00 00       	push   $0x217
f01010fe:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0101104:	50                   	push   %eax
f0101105:	e8 8f ef ff ff       	call   f0100099 <_panic>
		physaddr_t pt_physadd = PTE_ADDR(pd_entry); // Now we have the physical address of the page table
f010110a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f010110f:	89 c1                	mov    %eax,%ecx
f0101111:	c1 e9 0c             	shr    $0xc,%ecx
f0101114:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f010111a:	3b 0a                	cmp    (%edx),%ecx
f010111c:	73 1a                	jae    f0101138 <pgdir_walk+0xc7>
	return (void *)(pa + KERNBASE);
f010111e:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
	return pt_entry + PTX(va); // add the page table index as an offset to the page table pointer
f0101124:	c1 ee 0a             	shr    $0xa,%esi
f0101127:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010112d:	8d 04 32             	lea    (%edx,%esi,1),%eax
}
f0101130:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101133:	5b                   	pop    %ebx
f0101134:	5e                   	pop    %esi
f0101135:	5f                   	pop    %edi
f0101136:	5d                   	pop    %ebp
f0101137:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101138:	50                   	push   %eax
f0101139:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f010113f:	50                   	push   %eax
f0101140:	68 1c 02 00 00       	push   $0x21c
f0101145:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010114b:	50                   	push   %eax
f010114c:	e8 48 ef ff ff       	call   f0100099 <_panic>
			return NULL;
f0101151:	b8 00 00 00 00       	mov    $0x0,%eax
f0101156:	eb d8                	jmp    f0101130 <pgdir_walk+0xbf>
			return NULL;
f0101158:	b8 00 00 00 00       	mov    $0x0,%eax
f010115d:	eb d1                	jmp    f0101130 <pgdir_walk+0xbf>

f010115f <boot_map_region>:
{
f010115f:	55                   	push   %ebp
f0101160:	89 e5                	mov    %esp,%ebp
f0101162:	57                   	push   %edi
f0101163:	56                   	push   %esi
f0101164:	53                   	push   %ebx
f0101165:	83 ec 1c             	sub    $0x1c,%esp
f0101168:	e8 e2 ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010116d:	81 c3 9b 61 01 00    	add    $0x1619b,%ebx
f0101173:	89 c7                	mov    %eax,%edi
f0101175:	8b 45 08             	mov    0x8(%ebp),%eax
	size = ROUNDUP(size, PGSIZE);
f0101178:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
	assert(va % PGSIZE == 0);
f010117e:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0101184:	75 24                	jne    f01011aa <boot_map_region+0x4b>
	assert(pa % PGSIZE == 0);
f0101186:	a9 ff 0f 00 00       	test   $0xfff,%eax
f010118b:	75 3c                	jne    f01011c9 <boot_map_region+0x6a>
	for(size_t i = 0; i < size/PGSIZE; i++){
f010118d:	c1 e9 0c             	shr    $0xc,%ecx
f0101190:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101193:	89 d3                	mov    %edx,%ebx
f0101195:	be 00 00 00 00       	mov    $0x0,%esi
			*pt_entry = (pa + i*PGSIZE) | perm | PTE_P;
f010119a:	29 d0                	sub    %edx,%eax
f010119c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010119f:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011a2:	83 c8 01             	or     $0x1,%eax
f01011a5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01011a8:	eb 47                	jmp    f01011f1 <boot_map_region+0x92>
	assert(va % PGSIZE == 0);
f01011aa:	8d 83 62 d2 fe ff    	lea    -0x12d9e(%ebx),%eax
f01011b0:	50                   	push   %eax
f01011b1:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01011b7:	50                   	push   %eax
f01011b8:	68 3d 02 00 00       	push   $0x23d
f01011bd:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01011c3:	50                   	push   %eax
f01011c4:	e8 d0 ee ff ff       	call   f0100099 <_panic>
	assert(pa % PGSIZE == 0);
f01011c9:	8d 83 73 d2 fe ff    	lea    -0x12d8d(%ebx),%eax
f01011cf:	50                   	push   %eax
f01011d0:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01011d6:	50                   	push   %eax
f01011d7:	68 3e 02 00 00       	push   $0x23e
f01011dc:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01011e2:	50                   	push   %eax
f01011e3:	e8 b1 ee ff ff       	call   f0100099 <_panic>
	for(size_t i = 0; i < size/PGSIZE; i++){
f01011e8:	83 c6 01             	add    $0x1,%esi
f01011eb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01011f1:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f01011f4:	74 20                	je     f0101216 <boot_map_region+0xb7>
		pte_t * pt_entry = pgdir_walk(pgdir, (void *) va + i * PGSIZE, 1);
f01011f6:	83 ec 04             	sub    $0x4,%esp
f01011f9:	6a 01                	push   $0x1
f01011fb:	53                   	push   %ebx
f01011fc:	57                   	push   %edi
f01011fd:	e8 6f fe ff ff       	call   f0101071 <pgdir_walk>
		if(pt_entry != NULL){
f0101202:	83 c4 10             	add    $0x10,%esp
f0101205:	85 c0                	test   %eax,%eax
f0101207:	74 df                	je     f01011e8 <boot_map_region+0x89>
			*pt_entry = (pa + i*PGSIZE) | perm | PTE_P;
f0101209:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010120c:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
f010120f:	0b 55 dc             	or     -0x24(%ebp),%edx
f0101212:	89 10                	mov    %edx,(%eax)
f0101214:	eb d2                	jmp    f01011e8 <boot_map_region+0x89>
}
f0101216:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101219:	5b                   	pop    %ebx
f010121a:	5e                   	pop    %esi
f010121b:	5f                   	pop    %edi
f010121c:	5d                   	pop    %ebp
f010121d:	c3                   	ret    

f010121e <page_lookup>:
{
f010121e:	55                   	push   %ebp
f010121f:	89 e5                	mov    %esp,%ebp
f0101221:	56                   	push   %esi
f0101222:	53                   	push   %ebx
f0101223:	e8 27 ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101228:	81 c3 e0 60 01 00    	add    $0x160e0,%ebx
f010122e:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t * pt_entry = pgdir_walk(pgdir, va, 0);
f0101231:	83 ec 04             	sub    $0x4,%esp
f0101234:	6a 00                	push   $0x0
f0101236:	ff 75 0c             	pushl  0xc(%ebp)
f0101239:	ff 75 08             	pushl  0x8(%ebp)
f010123c:	e8 30 fe ff ff       	call   f0101071 <pgdir_walk>
	if(!pt_entry){
f0101241:	83 c4 10             	add    $0x10,%esp
f0101244:	85 c0                	test   %eax,%eax
f0101246:	74 3f                	je     f0101287 <page_lookup+0x69>
	if(pte_store){
f0101248:	85 f6                	test   %esi,%esi
f010124a:	74 02                	je     f010124e <page_lookup+0x30>
		*pte_store = pt_entry;
f010124c:	89 06                	mov    %eax,(%esi)
f010124e:	8b 00                	mov    (%eax),%eax
f0101250:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101253:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101259:	39 02                	cmp    %eax,(%edx)
f010125b:	76 12                	jbe    f010126f <page_lookup+0x51>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f010125d:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101263:	8b 12                	mov    (%edx),%edx
f0101265:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f0101268:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010126b:	5b                   	pop    %ebx
f010126c:	5e                   	pop    %esi
f010126d:	5d                   	pop    %ebp
f010126e:	c3                   	ret    
		panic("pa2page called with invalid pa");
f010126f:	83 ec 04             	sub    $0x4,%esp
f0101272:	8d 83 c0 d5 fe ff    	lea    -0x12a40(%ebx),%eax
f0101278:	50                   	push   %eax
f0101279:	6a 4b                	push   $0x4b
f010127b:	8d 83 94 d1 fe ff    	lea    -0x12e6c(%ebx),%eax
f0101281:	50                   	push   %eax
f0101282:	e8 12 ee ff ff       	call   f0100099 <_panic>
		return NULL;
f0101287:	b8 00 00 00 00       	mov    $0x0,%eax
f010128c:	eb da                	jmp    f0101268 <page_lookup+0x4a>

f010128e <page_remove>:
{
f010128e:	55                   	push   %ebp
f010128f:	89 e5                	mov    %esp,%ebp
f0101291:	53                   	push   %ebx
f0101292:	83 ec 18             	sub    $0x18,%esp
f0101295:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo * page = page_lookup(pgdir, va, &pt_entry_store);
f0101298:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010129b:	50                   	push   %eax
f010129c:	53                   	push   %ebx
f010129d:	ff 75 08             	pushl  0x8(%ebp)
f01012a0:	e8 79 ff ff ff       	call   f010121e <page_lookup>
	if(page){
f01012a5:	83 c4 10             	add    $0x10,%esp
f01012a8:	85 c0                	test   %eax,%eax
f01012aa:	74 18                	je     f01012c4 <page_remove+0x36>
		page_decref(page);
f01012ac:	83 ec 0c             	sub    $0xc,%esp
f01012af:	50                   	push   %eax
f01012b0:	e8 93 fd ff ff       	call   f0101048 <page_decref>
		*pt_entry_store = 0;
f01012b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012b8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01012be:	0f 01 3b             	invlpg (%ebx)
f01012c1:	83 c4 10             	add    $0x10,%esp
}
f01012c4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012c7:	c9                   	leave  
f01012c8:	c3                   	ret    

f01012c9 <page_insert>:
{
f01012c9:	55                   	push   %ebp
f01012ca:	89 e5                	mov    %esp,%ebp
f01012cc:	57                   	push   %edi
f01012cd:	56                   	push   %esi
f01012ce:	53                   	push   %ebx
f01012cf:	83 ec 10             	sub    $0x10,%esp
f01012d2:	e8 19 1d 00 00       	call   f0102ff0 <__x86.get_pc_thunk.di>
f01012d7:	81 c7 31 60 01 00    	add    $0x16031,%edi
f01012dd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pt_entry = pgdir_walk(pgdir, va, 1);
f01012e0:	6a 01                	push   $0x1
f01012e2:	ff 75 10             	pushl  0x10(%ebp)
f01012e5:	ff 75 08             	pushl  0x8(%ebp)
f01012e8:	e8 84 fd ff ff       	call   f0101071 <pgdir_walk>
	if(pt_entry == NULL){
f01012ed:	83 c4 10             	add    $0x10,%esp
f01012f0:	85 c0                	test   %eax,%eax
f01012f2:	74 63                	je     f0101357 <page_insert+0x8e>
f01012f4:	89 c6                	mov    %eax,%esi
	if(pp->pp_ref == 0){
f01012f6:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01012fa:	66 85 c0             	test   %ax,%ax
f01012fd:	75 0e                	jne    f010130d <page_insert+0x44>
		page_free_list = pp->pp_link;
f01012ff:	8b 13                	mov    (%ebx),%edx
f0101301:	89 97 94 1f 00 00    	mov    %edx,0x1f94(%edi)
		pp->pp_link = NULL;
f0101307:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	pp->pp_ref++;
f010130d:	83 c0 01             	add    $0x1,%eax
f0101310:	66 89 43 04          	mov    %ax,0x4(%ebx)
	if(*pt_entry)
f0101314:	83 3e 00             	cmpl   $0x0,(%esi)
f0101317:	75 2b                	jne    f0101344 <page_insert+0x7b>
	return (pp - pages) << PGSHIFT;
f0101319:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010131f:	2b 18                	sub    (%eax),%ebx
f0101321:	c1 fb 03             	sar    $0x3,%ebx
f0101324:	c1 e3 0c             	shl    $0xc,%ebx
	*pt_entry = page2pa(pp) | perm | PTE_P; // permissions from comments, but what does it mean?
f0101327:	8b 45 14             	mov    0x14(%ebp),%eax
f010132a:	83 c8 01             	or     $0x1,%eax
f010132d:	09 c3                	or     %eax,%ebx
f010132f:	89 1e                	mov    %ebx,(%esi)
f0101331:	8b 45 10             	mov    0x10(%ebp),%eax
f0101334:	0f 01 38             	invlpg (%eax)
	return 0;
f0101337:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010133c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010133f:	5b                   	pop    %ebx
f0101340:	5e                   	pop    %esi
f0101341:	5f                   	pop    %edi
f0101342:	5d                   	pop    %ebp
f0101343:	c3                   	ret    
		page_remove(pgdir, va);
f0101344:	83 ec 08             	sub    $0x8,%esp
f0101347:	ff 75 10             	pushl  0x10(%ebp)
f010134a:	ff 75 08             	pushl  0x8(%ebp)
f010134d:	e8 3c ff ff ff       	call   f010128e <page_remove>
f0101352:	83 c4 10             	add    $0x10,%esp
f0101355:	eb c2                	jmp    f0101319 <page_insert+0x50>
		return -E_NO_MEM;
f0101357:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010135c:	eb de                	jmp    f010133c <page_insert+0x73>

f010135e <mem_init>:
{
f010135e:	55                   	push   %ebp
f010135f:	89 e5                	mov    %esp,%ebp
f0101361:	57                   	push   %edi
f0101362:	56                   	push   %esi
f0101363:	53                   	push   %ebx
f0101364:	83 ec 3c             	sub    $0x3c,%esp
f0101367:	e8 e3 ed ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010136c:	81 c3 9c 5f 01 00    	add    $0x15f9c,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f0101372:	b8 15 00 00 00       	mov    $0x15,%eax
f0101377:	e8 07 f6 ff ff       	call   f0100983 <nvram_read>
f010137c:	89 c7                	mov    %eax,%edi
	extmem = nvram_read(NVRAM_EXTLO);
f010137e:	b8 17 00 00 00       	mov    $0x17,%eax
f0101383:	e8 fb f5 ff ff       	call   f0100983 <nvram_read>
f0101388:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010138a:	b8 34 00 00 00       	mov    $0x34,%eax
f010138f:	e8 ef f5 ff ff       	call   f0100983 <nvram_read>
f0101394:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0101397:	85 c0                	test   %eax,%eax
f0101399:	0f 85 c0 00 00 00    	jne    f010145f <mem_init+0x101>
		totalmem = 1 * 1024 + extmem;
f010139f:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01013a5:	85 f6                	test   %esi,%esi
f01013a7:	0f 44 c7             	cmove  %edi,%eax
	npages = totalmem / (PGSIZE / 1024);
f01013aa:	89 c1                	mov    %eax,%ecx
f01013ac:	c1 e9 02             	shr    $0x2,%ecx
f01013af:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f01013b5:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f01013b7:	89 fa                	mov    %edi,%edx
f01013b9:	c1 ea 02             	shr    $0x2,%edx
f01013bc:	89 93 98 1f 00 00    	mov    %edx,0x1f98(%ebx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013c2:	89 c2                	mov    %eax,%edx
f01013c4:	29 fa                	sub    %edi,%edx
f01013c6:	52                   	push   %edx
f01013c7:	57                   	push   %edi
f01013c8:	50                   	push   %eax
f01013c9:	8d 83 e0 d5 fe ff    	lea    -0x12a20(%ebx),%eax
f01013cf:	50                   	push   %eax
f01013d0:	e8 a6 1c 00 00       	call   f010307b <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01013d5:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013da:	e8 da f5 ff ff       	call   f01009b9 <boot_alloc>
f01013df:	c7 c6 cc 96 11 f0    	mov    $0xf01196cc,%esi
f01013e5:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f01013e7:	83 c4 0c             	add    $0xc,%esp
f01013ea:	68 00 10 00 00       	push   $0x1000
f01013ef:	6a 00                	push   $0x0
f01013f1:	50                   	push   %eax
f01013f2:	e8 e0 27 00 00       	call   f0103bd7 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013f7:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f01013f9:	83 c4 10             	add    $0x10,%esp
f01013fc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101401:	76 66                	jbe    f0101469 <mem_init+0x10b>
	return (physaddr_t)kva - KERNBASE;
f0101403:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101409:	83 ca 05             	or     $0x5,%edx
f010140c:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0101412:	c7 c7 c8 96 11 f0    	mov    $0xf01196c8,%edi
f0101418:	8b 07                	mov    (%edi),%eax
f010141a:	c1 e0 03             	shl    $0x3,%eax
f010141d:	e8 97 f5 ff ff       	call   f01009b9 <boot_alloc>
f0101422:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
f0101428:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010142a:	83 ec 04             	sub    $0x4,%esp
f010142d:	8b 17                	mov    (%edi),%edx
f010142f:	c1 e2 03             	shl    $0x3,%edx
f0101432:	52                   	push   %edx
f0101433:	6a 00                	push   $0x0
f0101435:	50                   	push   %eax
f0101436:	e8 9c 27 00 00       	call   f0103bd7 <memset>
	page_init();
f010143b:	e8 f0 f9 ff ff       	call   f0100e30 <page_init>
	check_page_free_list(1);
f0101440:	b8 01 00 00 00       	mov    $0x1,%eax
f0101445:	e8 63 f6 ff ff       	call   f0100aad <check_page_free_list>
	if (!pages)
f010144a:	83 c4 10             	add    $0x10,%esp
f010144d:	83 3e 00             	cmpl   $0x0,(%esi)
f0101450:	74 30                	je     f0101482 <mem_init+0x124>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101452:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f0101458:	be 00 00 00 00       	mov    $0x0,%esi
f010145d:	eb 43                	jmp    f01014a2 <mem_init+0x144>
		totalmem = 16 * 1024 + ext16mem;
f010145f:	05 00 40 00 00       	add    $0x4000,%eax
f0101464:	e9 41 ff ff ff       	jmp    f01013aa <mem_init+0x4c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101469:	50                   	push   %eax
f010146a:	8d 83 1c d6 fe ff    	lea    -0x129e4(%ebx),%eax
f0101470:	50                   	push   %eax
f0101471:	68 a2 00 00 00       	push   $0xa2
f0101476:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010147c:	50                   	push   %eax
f010147d:	e8 17 ec ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f0101482:	83 ec 04             	sub    $0x4,%esp
f0101485:	8d 83 84 d2 fe ff    	lea    -0x12d7c(%ebx),%eax
f010148b:	50                   	push   %eax
f010148c:	68 59 03 00 00       	push   $0x359
f0101491:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0101497:	50                   	push   %eax
f0101498:	e8 fc eb ff ff       	call   f0100099 <_panic>
		++nfree;
f010149d:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014a0:	8b 00                	mov    (%eax),%eax
f01014a2:	85 c0                	test   %eax,%eax
f01014a4:	75 f7                	jne    f010149d <mem_init+0x13f>
	assert((pp0 = page_alloc(0)));
f01014a6:	83 ec 0c             	sub    $0xc,%esp
f01014a9:	6a 00                	push   $0x0
f01014ab:	e8 9e fa ff ff       	call   f0100f4e <page_alloc>
f01014b0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014b3:	83 c4 10             	add    $0x10,%esp
f01014b6:	85 c0                	test   %eax,%eax
f01014b8:	0f 84 2e 02 00 00    	je     f01016ec <mem_init+0x38e>
	assert((pp1 = page_alloc(0)));
f01014be:	83 ec 0c             	sub    $0xc,%esp
f01014c1:	6a 00                	push   $0x0
f01014c3:	e8 86 fa ff ff       	call   f0100f4e <page_alloc>
f01014c8:	89 c7                	mov    %eax,%edi
f01014ca:	83 c4 10             	add    $0x10,%esp
f01014cd:	85 c0                	test   %eax,%eax
f01014cf:	0f 84 36 02 00 00    	je     f010170b <mem_init+0x3ad>
	assert((pp2 = page_alloc(0)));
f01014d5:	83 ec 0c             	sub    $0xc,%esp
f01014d8:	6a 00                	push   $0x0
f01014da:	e8 6f fa ff ff       	call   f0100f4e <page_alloc>
f01014df:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01014e2:	83 c4 10             	add    $0x10,%esp
f01014e5:	85 c0                	test   %eax,%eax
f01014e7:	0f 84 3d 02 00 00    	je     f010172a <mem_init+0x3cc>
	assert(pp1 && pp1 != pp0);
f01014ed:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f01014f0:	0f 84 53 02 00 00    	je     f0101749 <mem_init+0x3eb>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014f6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014f9:	39 c7                	cmp    %eax,%edi
f01014fb:	0f 84 67 02 00 00    	je     f0101768 <mem_init+0x40a>
f0101501:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101504:	0f 84 5e 02 00 00    	je     f0101768 <mem_init+0x40a>
	return (pp - pages) << PGSHIFT;
f010150a:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101510:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101512:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0101518:	8b 10                	mov    (%eax),%edx
f010151a:	c1 e2 0c             	shl    $0xc,%edx
f010151d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101520:	29 c8                	sub    %ecx,%eax
f0101522:	c1 f8 03             	sar    $0x3,%eax
f0101525:	c1 e0 0c             	shl    $0xc,%eax
f0101528:	39 d0                	cmp    %edx,%eax
f010152a:	0f 83 57 02 00 00    	jae    f0101787 <mem_init+0x429>
f0101530:	89 f8                	mov    %edi,%eax
f0101532:	29 c8                	sub    %ecx,%eax
f0101534:	c1 f8 03             	sar    $0x3,%eax
f0101537:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010153a:	39 c2                	cmp    %eax,%edx
f010153c:	0f 86 64 02 00 00    	jbe    f01017a6 <mem_init+0x448>
f0101542:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101545:	29 c8                	sub    %ecx,%eax
f0101547:	c1 f8 03             	sar    $0x3,%eax
f010154a:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010154d:	39 c2                	cmp    %eax,%edx
f010154f:	0f 86 70 02 00 00    	jbe    f01017c5 <mem_init+0x467>
	fl = page_free_list;
f0101555:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f010155b:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f010155e:	c7 83 94 1f 00 00 00 	movl   $0x0,0x1f94(%ebx)
f0101565:	00 00 00 
	assert(!page_alloc(0));
f0101568:	83 ec 0c             	sub    $0xc,%esp
f010156b:	6a 00                	push   $0x0
f010156d:	e8 dc f9 ff ff       	call   f0100f4e <page_alloc>
f0101572:	83 c4 10             	add    $0x10,%esp
f0101575:	85 c0                	test   %eax,%eax
f0101577:	0f 85 67 02 00 00    	jne    f01017e4 <mem_init+0x486>
	page_free(pp0);
f010157d:	83 ec 0c             	sub    $0xc,%esp
f0101580:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101583:	e8 4e fa ff ff       	call   f0100fd6 <page_free>
	page_free(pp1);
f0101588:	89 3c 24             	mov    %edi,(%esp)
f010158b:	e8 46 fa ff ff       	call   f0100fd6 <page_free>
	page_free(pp2);
f0101590:	83 c4 04             	add    $0x4,%esp
f0101593:	ff 75 d0             	pushl  -0x30(%ebp)
f0101596:	e8 3b fa ff ff       	call   f0100fd6 <page_free>
	assert((pp0 = page_alloc(0)));
f010159b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015a2:	e8 a7 f9 ff ff       	call   f0100f4e <page_alloc>
f01015a7:	89 c7                	mov    %eax,%edi
f01015a9:	83 c4 10             	add    $0x10,%esp
f01015ac:	85 c0                	test   %eax,%eax
f01015ae:	0f 84 4f 02 00 00    	je     f0101803 <mem_init+0x4a5>
	assert((pp1 = page_alloc(0)));
f01015b4:	83 ec 0c             	sub    $0xc,%esp
f01015b7:	6a 00                	push   $0x0
f01015b9:	e8 90 f9 ff ff       	call   f0100f4e <page_alloc>
f01015be:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015c1:	83 c4 10             	add    $0x10,%esp
f01015c4:	85 c0                	test   %eax,%eax
f01015c6:	0f 84 56 02 00 00    	je     f0101822 <mem_init+0x4c4>
	assert((pp2 = page_alloc(0)));
f01015cc:	83 ec 0c             	sub    $0xc,%esp
f01015cf:	6a 00                	push   $0x0
f01015d1:	e8 78 f9 ff ff       	call   f0100f4e <page_alloc>
f01015d6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01015d9:	83 c4 10             	add    $0x10,%esp
f01015dc:	85 c0                	test   %eax,%eax
f01015de:	0f 84 5d 02 00 00    	je     f0101841 <mem_init+0x4e3>
	assert(pp1 && pp1 != pp0);
f01015e4:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01015e7:	0f 84 73 02 00 00    	je     f0101860 <mem_init+0x502>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015ed:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015f0:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01015f3:	0f 84 86 02 00 00    	je     f010187f <mem_init+0x521>
f01015f9:	39 c7                	cmp    %eax,%edi
f01015fb:	0f 84 7e 02 00 00    	je     f010187f <mem_init+0x521>
	assert(!page_alloc(0));
f0101601:	83 ec 0c             	sub    $0xc,%esp
f0101604:	6a 00                	push   $0x0
f0101606:	e8 43 f9 ff ff       	call   f0100f4e <page_alloc>
f010160b:	83 c4 10             	add    $0x10,%esp
f010160e:	85 c0                	test   %eax,%eax
f0101610:	0f 85 88 02 00 00    	jne    f010189e <mem_init+0x540>
f0101616:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010161c:	89 f9                	mov    %edi,%ecx
f010161e:	2b 08                	sub    (%eax),%ecx
f0101620:	89 c8                	mov    %ecx,%eax
f0101622:	c1 f8 03             	sar    $0x3,%eax
f0101625:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101628:	89 c1                	mov    %eax,%ecx
f010162a:	c1 e9 0c             	shr    $0xc,%ecx
f010162d:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101633:	3b 0a                	cmp    (%edx),%ecx
f0101635:	0f 83 82 02 00 00    	jae    f01018bd <mem_init+0x55f>
	memset(page2kva(pp0), 1, PGSIZE);
f010163b:	83 ec 04             	sub    $0x4,%esp
f010163e:	68 00 10 00 00       	push   $0x1000
f0101643:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101645:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010164a:	50                   	push   %eax
f010164b:	e8 87 25 00 00       	call   f0103bd7 <memset>
	page_free(pp0);
f0101650:	89 3c 24             	mov    %edi,(%esp)
f0101653:	e8 7e f9 ff ff       	call   f0100fd6 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101658:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010165f:	e8 ea f8 ff ff       	call   f0100f4e <page_alloc>
f0101664:	83 c4 10             	add    $0x10,%esp
f0101667:	85 c0                	test   %eax,%eax
f0101669:	0f 84 64 02 00 00    	je     f01018d3 <mem_init+0x575>
	assert(pp && pp0 == pp);
f010166f:	39 c7                	cmp    %eax,%edi
f0101671:	0f 85 7b 02 00 00    	jne    f01018f2 <mem_init+0x594>
	return (pp - pages) << PGSHIFT;
f0101677:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010167d:	89 fa                	mov    %edi,%edx
f010167f:	2b 10                	sub    (%eax),%edx
f0101681:	c1 fa 03             	sar    $0x3,%edx
f0101684:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101687:	89 d1                	mov    %edx,%ecx
f0101689:	c1 e9 0c             	shr    $0xc,%ecx
f010168c:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0101692:	3b 08                	cmp    (%eax),%ecx
f0101694:	0f 83 77 02 00 00    	jae    f0101911 <mem_init+0x5b3>
	return (void *)(pa + KERNBASE);
f010169a:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f01016a0:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01016a6:	80 38 00             	cmpb   $0x0,(%eax)
f01016a9:	0f 85 78 02 00 00    	jne    f0101927 <mem_init+0x5c9>
f01016af:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01016b2:	39 d0                	cmp    %edx,%eax
f01016b4:	75 f0                	jne    f01016a6 <mem_init+0x348>
	page_free_list = fl;
f01016b6:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01016b9:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	page_free(pp0);
f01016bf:	83 ec 0c             	sub    $0xc,%esp
f01016c2:	57                   	push   %edi
f01016c3:	e8 0e f9 ff ff       	call   f0100fd6 <page_free>
	page_free(pp1);
f01016c8:	83 c4 04             	add    $0x4,%esp
f01016cb:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016ce:	e8 03 f9 ff ff       	call   f0100fd6 <page_free>
	page_free(pp2);
f01016d3:	83 c4 04             	add    $0x4,%esp
f01016d6:	ff 75 d0             	pushl  -0x30(%ebp)
f01016d9:	e8 f8 f8 ff ff       	call   f0100fd6 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016de:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f01016e4:	83 c4 10             	add    $0x10,%esp
f01016e7:	e9 5f 02 00 00       	jmp    f010194b <mem_init+0x5ed>
	assert((pp0 = page_alloc(0)));
f01016ec:	8d 83 9f d2 fe ff    	lea    -0x12d61(%ebx),%eax
f01016f2:	50                   	push   %eax
f01016f3:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01016f9:	50                   	push   %eax
f01016fa:	68 61 03 00 00       	push   $0x361
f01016ff:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0101705:	50                   	push   %eax
f0101706:	e8 8e e9 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010170b:	8d 83 b5 d2 fe ff    	lea    -0x12d4b(%ebx),%eax
f0101711:	50                   	push   %eax
f0101712:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0101718:	50                   	push   %eax
f0101719:	68 62 03 00 00       	push   $0x362
f010171e:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0101724:	50                   	push   %eax
f0101725:	e8 6f e9 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010172a:	8d 83 cb d2 fe ff    	lea    -0x12d35(%ebx),%eax
f0101730:	50                   	push   %eax
f0101731:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0101737:	50                   	push   %eax
f0101738:	68 63 03 00 00       	push   $0x363
f010173d:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0101743:	50                   	push   %eax
f0101744:	e8 50 e9 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101749:	8d 83 e1 d2 fe ff    	lea    -0x12d1f(%ebx),%eax
f010174f:	50                   	push   %eax
f0101750:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0101756:	50                   	push   %eax
f0101757:	68 66 03 00 00       	push   $0x366
f010175c:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0101762:	50                   	push   %eax
f0101763:	e8 31 e9 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101768:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f010176e:	50                   	push   %eax
f010176f:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0101775:	50                   	push   %eax
f0101776:	68 67 03 00 00       	push   $0x367
f010177b:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0101781:	50                   	push   %eax
f0101782:	e8 12 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101787:	8d 83 f3 d2 fe ff    	lea    -0x12d0d(%ebx),%eax
f010178d:	50                   	push   %eax
f010178e:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0101794:	50                   	push   %eax
f0101795:	68 68 03 00 00       	push   $0x368
f010179a:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01017a0:	50                   	push   %eax
f01017a1:	e8 f3 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01017a6:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01017ac:	50                   	push   %eax
f01017ad:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01017b3:	50                   	push   %eax
f01017b4:	68 69 03 00 00       	push   $0x369
f01017b9:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01017bf:	50                   	push   %eax
f01017c0:	e8 d4 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01017c5:	8d 83 2d d3 fe ff    	lea    -0x12cd3(%ebx),%eax
f01017cb:	50                   	push   %eax
f01017cc:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01017d2:	50                   	push   %eax
f01017d3:	68 6a 03 00 00       	push   $0x36a
f01017d8:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01017de:	50                   	push   %eax
f01017df:	e8 b5 e8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01017e4:	8d 83 4a d3 fe ff    	lea    -0x12cb6(%ebx),%eax
f01017ea:	50                   	push   %eax
f01017eb:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01017f1:	50                   	push   %eax
f01017f2:	68 71 03 00 00       	push   $0x371
f01017f7:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01017fd:	50                   	push   %eax
f01017fe:	e8 96 e8 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0101803:	8d 83 9f d2 fe ff    	lea    -0x12d61(%ebx),%eax
f0101809:	50                   	push   %eax
f010180a:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0101810:	50                   	push   %eax
f0101811:	68 78 03 00 00       	push   $0x378
f0101816:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010181c:	50                   	push   %eax
f010181d:	e8 77 e8 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101822:	8d 83 b5 d2 fe ff    	lea    -0x12d4b(%ebx),%eax
f0101828:	50                   	push   %eax
f0101829:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010182f:	50                   	push   %eax
f0101830:	68 79 03 00 00       	push   $0x379
f0101835:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010183b:	50                   	push   %eax
f010183c:	e8 58 e8 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101841:	8d 83 cb d2 fe ff    	lea    -0x12d35(%ebx),%eax
f0101847:	50                   	push   %eax
f0101848:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010184e:	50                   	push   %eax
f010184f:	68 7a 03 00 00       	push   $0x37a
f0101854:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010185a:	50                   	push   %eax
f010185b:	e8 39 e8 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101860:	8d 83 e1 d2 fe ff    	lea    -0x12d1f(%ebx),%eax
f0101866:	50                   	push   %eax
f0101867:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010186d:	50                   	push   %eax
f010186e:	68 7c 03 00 00       	push   $0x37c
f0101873:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0101879:	50                   	push   %eax
f010187a:	e8 1a e8 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010187f:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f0101885:	50                   	push   %eax
f0101886:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010188c:	50                   	push   %eax
f010188d:	68 7d 03 00 00       	push   $0x37d
f0101892:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0101898:	50                   	push   %eax
f0101899:	e8 fb e7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010189e:	8d 83 4a d3 fe ff    	lea    -0x12cb6(%ebx),%eax
f01018a4:	50                   	push   %eax
f01018a5:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01018ab:	50                   	push   %eax
f01018ac:	68 7e 03 00 00       	push   $0x37e
f01018b1:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01018b7:	50                   	push   %eax
f01018b8:	e8 dc e7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018bd:	50                   	push   %eax
f01018be:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f01018c4:	50                   	push   %eax
f01018c5:	6a 52                	push   $0x52
f01018c7:	8d 83 94 d1 fe ff    	lea    -0x12e6c(%ebx),%eax
f01018cd:	50                   	push   %eax
f01018ce:	e8 c6 e7 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01018d3:	8d 83 59 d3 fe ff    	lea    -0x12ca7(%ebx),%eax
f01018d9:	50                   	push   %eax
f01018da:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01018e0:	50                   	push   %eax
f01018e1:	68 83 03 00 00       	push   $0x383
f01018e6:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01018ec:	50                   	push   %eax
f01018ed:	e8 a7 e7 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f01018f2:	8d 83 77 d3 fe ff    	lea    -0x12c89(%ebx),%eax
f01018f8:	50                   	push   %eax
f01018f9:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01018ff:	50                   	push   %eax
f0101900:	68 84 03 00 00       	push   $0x384
f0101905:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010190b:	50                   	push   %eax
f010190c:	e8 88 e7 ff ff       	call   f0100099 <_panic>
f0101911:	52                   	push   %edx
f0101912:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f0101918:	50                   	push   %eax
f0101919:	6a 52                	push   $0x52
f010191b:	8d 83 94 d1 fe ff    	lea    -0x12e6c(%ebx),%eax
f0101921:	50                   	push   %eax
f0101922:	e8 72 e7 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f0101927:	8d 83 87 d3 fe ff    	lea    -0x12c79(%ebx),%eax
f010192d:	50                   	push   %eax
f010192e:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0101934:	50                   	push   %eax
f0101935:	68 87 03 00 00       	push   $0x387
f010193a:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0101940:	50                   	push   %eax
f0101941:	e8 53 e7 ff ff       	call   f0100099 <_panic>
		--nfree;
f0101946:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101949:	8b 00                	mov    (%eax),%eax
f010194b:	85 c0                	test   %eax,%eax
f010194d:	75 f7                	jne    f0101946 <mem_init+0x5e8>
	assert(nfree == 0);
f010194f:	85 f6                	test   %esi,%esi
f0101951:	0f 85 28 08 00 00    	jne    f010217f <mem_init+0xe21>
	cprintf("check_page_alloc() succeeded!\n");
f0101957:	83 ec 0c             	sub    $0xc,%esp
f010195a:	8d 83 60 d6 fe ff    	lea    -0x129a0(%ebx),%eax
f0101960:	50                   	push   %eax
f0101961:	e8 15 17 00 00       	call   f010307b <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101966:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010196d:	e8 dc f5 ff ff       	call   f0100f4e <page_alloc>
f0101972:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101975:	83 c4 10             	add    $0x10,%esp
f0101978:	85 c0                	test   %eax,%eax
f010197a:	0f 84 1e 08 00 00    	je     f010219e <mem_init+0xe40>
	assert((pp1 = page_alloc(0)));
f0101980:	83 ec 0c             	sub    $0xc,%esp
f0101983:	6a 00                	push   $0x0
f0101985:	e8 c4 f5 ff ff       	call   f0100f4e <page_alloc>
f010198a:	89 c7                	mov    %eax,%edi
f010198c:	83 c4 10             	add    $0x10,%esp
f010198f:	85 c0                	test   %eax,%eax
f0101991:	0f 84 26 08 00 00    	je     f01021bd <mem_init+0xe5f>
	assert((pp2 = page_alloc(0)));
f0101997:	83 ec 0c             	sub    $0xc,%esp
f010199a:	6a 00                	push   $0x0
f010199c:	e8 ad f5 ff ff       	call   f0100f4e <page_alloc>
f01019a1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01019a4:	83 c4 10             	add    $0x10,%esp
f01019a7:	85 c0                	test   %eax,%eax
f01019a9:	0f 84 2d 08 00 00    	je     f01021dc <mem_init+0xe7e>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019af:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f01019b2:	0f 84 43 08 00 00    	je     f01021fb <mem_init+0xe9d>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019bb:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01019be:	0f 84 56 08 00 00    	je     f010221a <mem_init+0xebc>
f01019c4:	39 c7                	cmp    %eax,%edi
f01019c6:	0f 84 4e 08 00 00    	je     f010221a <mem_init+0xebc>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01019cc:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f01019d2:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	page_free_list = 0;
f01019d5:	c7 83 94 1f 00 00 00 	movl   $0x0,0x1f94(%ebx)
f01019dc:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01019df:	83 ec 0c             	sub    $0xc,%esp
f01019e2:	6a 00                	push   $0x0
f01019e4:	e8 65 f5 ff ff       	call   f0100f4e <page_alloc>
f01019e9:	83 c4 10             	add    $0x10,%esp
f01019ec:	85 c0                	test   %eax,%eax
f01019ee:	0f 85 45 08 00 00    	jne    f0102239 <mem_init+0xedb>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019f4:	83 ec 04             	sub    $0x4,%esp
f01019f7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019fa:	50                   	push   %eax
f01019fb:	6a 00                	push   $0x0
f01019fd:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a03:	ff 30                	pushl  (%eax)
f0101a05:	e8 14 f8 ff ff       	call   f010121e <page_lookup>
f0101a0a:	83 c4 10             	add    $0x10,%esp
f0101a0d:	85 c0                	test   %eax,%eax
f0101a0f:	0f 85 43 08 00 00    	jne    f0102258 <mem_init+0xefa>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a15:	6a 02                	push   $0x2
f0101a17:	6a 00                	push   $0x0
f0101a19:	57                   	push   %edi
f0101a1a:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a20:	ff 30                	pushl  (%eax)
f0101a22:	e8 a2 f8 ff ff       	call   f01012c9 <page_insert>
f0101a27:	83 c4 10             	add    $0x10,%esp
f0101a2a:	85 c0                	test   %eax,%eax
f0101a2c:	0f 89 45 08 00 00    	jns    f0102277 <mem_init+0xf19>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a32:	83 ec 0c             	sub    $0xc,%esp
f0101a35:	ff 75 d0             	pushl  -0x30(%ebp)
f0101a38:	e8 99 f5 ff ff       	call   f0100fd6 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a3d:	6a 02                	push   $0x2
f0101a3f:	6a 00                	push   $0x0
f0101a41:	57                   	push   %edi
f0101a42:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a48:	ff 30                	pushl  (%eax)
f0101a4a:	e8 7a f8 ff ff       	call   f01012c9 <page_insert>
f0101a4f:	83 c4 20             	add    $0x20,%esp
f0101a52:	85 c0                	test   %eax,%eax
f0101a54:	0f 85 3c 08 00 00    	jne    f0102296 <mem_init+0xf38>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a5a:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a60:	8b 08                	mov    (%eax),%ecx
f0101a62:	89 ce                	mov    %ecx,%esi
	return (pp - pages) << PGSHIFT;
f0101a64:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101a6a:	8b 00                	mov    (%eax),%eax
f0101a6c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a6f:	8b 09                	mov    (%ecx),%ecx
f0101a71:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0101a74:	89 ca                	mov    %ecx,%edx
f0101a76:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a7c:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101a7f:	29 c1                	sub    %eax,%ecx
f0101a81:	89 c8                	mov    %ecx,%eax
f0101a83:	c1 f8 03             	sar    $0x3,%eax
f0101a86:	c1 e0 0c             	shl    $0xc,%eax
f0101a89:	39 c2                	cmp    %eax,%edx
f0101a8b:	0f 85 24 08 00 00    	jne    f01022b5 <mem_init+0xf57>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a91:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a96:	89 f0                	mov    %esi,%eax
f0101a98:	e8 93 ef ff ff       	call   f0100a30 <check_va2pa>
f0101a9d:	89 fa                	mov    %edi,%edx
f0101a9f:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101aa2:	c1 fa 03             	sar    $0x3,%edx
f0101aa5:	c1 e2 0c             	shl    $0xc,%edx
f0101aa8:	39 d0                	cmp    %edx,%eax
f0101aaa:	0f 85 24 08 00 00    	jne    f01022d4 <mem_init+0xf76>
	assert(pp1->pp_ref == 1);
f0101ab0:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101ab5:	0f 85 38 08 00 00    	jne    f01022f3 <mem_init+0xf95>
	assert(pp0->pp_ref == 1);
f0101abb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101abe:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ac3:	0f 85 49 08 00 00    	jne    f0102312 <mem_init+0xfb4>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ac9:	6a 02                	push   $0x2
f0101acb:	68 00 10 00 00       	push   $0x1000
f0101ad0:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ad3:	56                   	push   %esi
f0101ad4:	e8 f0 f7 ff ff       	call   f01012c9 <page_insert>
f0101ad9:	83 c4 10             	add    $0x10,%esp
f0101adc:	85 c0                	test   %eax,%eax
f0101ade:	0f 85 4d 08 00 00    	jne    f0102331 <mem_init+0xfd3>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ae4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ae9:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101aef:	8b 00                	mov    (%eax),%eax
f0101af1:	e8 3a ef ff ff       	call   f0100a30 <check_va2pa>
f0101af6:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101afc:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101aff:	2b 0a                	sub    (%edx),%ecx
f0101b01:	89 ca                	mov    %ecx,%edx
f0101b03:	c1 fa 03             	sar    $0x3,%edx
f0101b06:	c1 e2 0c             	shl    $0xc,%edx
f0101b09:	39 d0                	cmp    %edx,%eax
f0101b0b:	0f 85 3f 08 00 00    	jne    f0102350 <mem_init+0xff2>
	assert(pp2->pp_ref == 1);
f0101b11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b14:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b19:	0f 85 50 08 00 00    	jne    f010236f <mem_init+0x1011>

	// should be no free memory
	assert(!page_alloc(0));
f0101b1f:	83 ec 0c             	sub    $0xc,%esp
f0101b22:	6a 00                	push   $0x0
f0101b24:	e8 25 f4 ff ff       	call   f0100f4e <page_alloc>
f0101b29:	83 c4 10             	add    $0x10,%esp
f0101b2c:	85 c0                	test   %eax,%eax
f0101b2e:	0f 85 5a 08 00 00    	jne    f010238e <mem_init+0x1030>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b34:	6a 02                	push   $0x2
f0101b36:	68 00 10 00 00       	push   $0x1000
f0101b3b:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b3e:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b44:	ff 30                	pushl  (%eax)
f0101b46:	e8 7e f7 ff ff       	call   f01012c9 <page_insert>
f0101b4b:	83 c4 10             	add    $0x10,%esp
f0101b4e:	85 c0                	test   %eax,%eax
f0101b50:	0f 85 57 08 00 00    	jne    f01023ad <mem_init+0x104f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b56:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b5b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b61:	8b 00                	mov    (%eax),%eax
f0101b63:	e8 c8 ee ff ff       	call   f0100a30 <check_va2pa>
f0101b68:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101b6e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101b71:	2b 0a                	sub    (%edx),%ecx
f0101b73:	89 ca                	mov    %ecx,%edx
f0101b75:	c1 fa 03             	sar    $0x3,%edx
f0101b78:	c1 e2 0c             	shl    $0xc,%edx
f0101b7b:	39 d0                	cmp    %edx,%eax
f0101b7d:	0f 85 49 08 00 00    	jne    f01023cc <mem_init+0x106e>
	assert(pp2->pp_ref == 1);
f0101b83:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b86:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b8b:	0f 85 5a 08 00 00    	jne    f01023eb <mem_init+0x108d>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b91:	83 ec 0c             	sub    $0xc,%esp
f0101b94:	6a 00                	push   $0x0
f0101b96:	e8 b3 f3 ff ff       	call   f0100f4e <page_alloc>
f0101b9b:	83 c4 10             	add    $0x10,%esp
f0101b9e:	85 c0                	test   %eax,%eax
f0101ba0:	0f 85 64 08 00 00    	jne    f010240a <mem_init+0x10ac>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101ba6:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101bac:	8b 10                	mov    (%eax),%edx
f0101bae:	8b 02                	mov    (%edx),%eax
f0101bb0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101bb5:	89 c1                	mov    %eax,%ecx
f0101bb7:	c1 e9 0c             	shr    $0xc,%ecx
f0101bba:	89 ce                	mov    %ecx,%esi
f0101bbc:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0101bc2:	3b 31                	cmp    (%ecx),%esi
f0101bc4:	0f 83 5f 08 00 00    	jae    f0102429 <mem_init+0x10cb>
	return (void *)(pa + KERNBASE);
f0101bca:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101bcf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101bd2:	83 ec 04             	sub    $0x4,%esp
f0101bd5:	6a 00                	push   $0x0
f0101bd7:	68 00 10 00 00       	push   $0x1000
f0101bdc:	52                   	push   %edx
f0101bdd:	e8 8f f4 ff ff       	call   f0101071 <pgdir_walk>
f0101be2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101be5:	8d 51 04             	lea    0x4(%ecx),%edx
f0101be8:	83 c4 10             	add    $0x10,%esp
f0101beb:	39 d0                	cmp    %edx,%eax
f0101bed:	0f 85 4f 08 00 00    	jne    f0102442 <mem_init+0x10e4>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101bf3:	6a 06                	push   $0x6
f0101bf5:	68 00 10 00 00       	push   $0x1000
f0101bfa:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101bfd:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c03:	ff 30                	pushl  (%eax)
f0101c05:	e8 bf f6 ff ff       	call   f01012c9 <page_insert>
f0101c0a:	83 c4 10             	add    $0x10,%esp
f0101c0d:	85 c0                	test   %eax,%eax
f0101c0f:	0f 85 4c 08 00 00    	jne    f0102461 <mem_init+0x1103>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c15:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c1b:	8b 00                	mov    (%eax),%eax
f0101c1d:	89 c6                	mov    %eax,%esi
f0101c1f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c24:	e8 07 ee ff ff       	call   f0100a30 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101c29:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101c2f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c32:	2b 0a                	sub    (%edx),%ecx
f0101c34:	89 ca                	mov    %ecx,%edx
f0101c36:	c1 fa 03             	sar    $0x3,%edx
f0101c39:	c1 e2 0c             	shl    $0xc,%edx
f0101c3c:	39 d0                	cmp    %edx,%eax
f0101c3e:	0f 85 3c 08 00 00    	jne    f0102480 <mem_init+0x1122>
	assert(pp2->pp_ref == 1);
f0101c44:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c47:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c4c:	0f 85 4d 08 00 00    	jne    f010249f <mem_init+0x1141>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c52:	83 ec 04             	sub    $0x4,%esp
f0101c55:	6a 00                	push   $0x0
f0101c57:	68 00 10 00 00       	push   $0x1000
f0101c5c:	56                   	push   %esi
f0101c5d:	e8 0f f4 ff ff       	call   f0101071 <pgdir_walk>
f0101c62:	83 c4 10             	add    $0x10,%esp
f0101c65:	f6 00 04             	testb  $0x4,(%eax)
f0101c68:	0f 84 50 08 00 00    	je     f01024be <mem_init+0x1160>
	assert(kern_pgdir[0] & PTE_U);
f0101c6e:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c74:	8b 00                	mov    (%eax),%eax
f0101c76:	f6 00 04             	testb  $0x4,(%eax)
f0101c79:	0f 84 5e 08 00 00    	je     f01024dd <mem_init+0x117f>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c7f:	6a 02                	push   $0x2
f0101c81:	68 00 10 00 00       	push   $0x1000
f0101c86:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c89:	50                   	push   %eax
f0101c8a:	e8 3a f6 ff ff       	call   f01012c9 <page_insert>
f0101c8f:	83 c4 10             	add    $0x10,%esp
f0101c92:	85 c0                	test   %eax,%eax
f0101c94:	0f 85 62 08 00 00    	jne    f01024fc <mem_init+0x119e>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c9a:	83 ec 04             	sub    $0x4,%esp
f0101c9d:	6a 00                	push   $0x0
f0101c9f:	68 00 10 00 00       	push   $0x1000
f0101ca4:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101caa:	ff 30                	pushl  (%eax)
f0101cac:	e8 c0 f3 ff ff       	call   f0101071 <pgdir_walk>
f0101cb1:	83 c4 10             	add    $0x10,%esp
f0101cb4:	f6 00 02             	testb  $0x2,(%eax)
f0101cb7:	0f 84 5e 08 00 00    	je     f010251b <mem_init+0x11bd>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101cbd:	83 ec 04             	sub    $0x4,%esp
f0101cc0:	6a 00                	push   $0x0
f0101cc2:	68 00 10 00 00       	push   $0x1000
f0101cc7:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ccd:	ff 30                	pushl  (%eax)
f0101ccf:	e8 9d f3 ff ff       	call   f0101071 <pgdir_walk>
f0101cd4:	83 c4 10             	add    $0x10,%esp
f0101cd7:	f6 00 04             	testb  $0x4,(%eax)
f0101cda:	0f 85 5a 08 00 00    	jne    f010253a <mem_init+0x11dc>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ce0:	6a 02                	push   $0x2
f0101ce2:	68 00 00 40 00       	push   $0x400000
f0101ce7:	ff 75 d0             	pushl  -0x30(%ebp)
f0101cea:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101cf0:	ff 30                	pushl  (%eax)
f0101cf2:	e8 d2 f5 ff ff       	call   f01012c9 <page_insert>
f0101cf7:	83 c4 10             	add    $0x10,%esp
f0101cfa:	85 c0                	test   %eax,%eax
f0101cfc:	0f 89 57 08 00 00    	jns    f0102559 <mem_init+0x11fb>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d02:	6a 02                	push   $0x2
f0101d04:	68 00 10 00 00       	push   $0x1000
f0101d09:	57                   	push   %edi
f0101d0a:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d10:	ff 30                	pushl  (%eax)
f0101d12:	e8 b2 f5 ff ff       	call   f01012c9 <page_insert>
f0101d17:	83 c4 10             	add    $0x10,%esp
f0101d1a:	85 c0                	test   %eax,%eax
f0101d1c:	0f 85 56 08 00 00    	jne    f0102578 <mem_init+0x121a>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d22:	83 ec 04             	sub    $0x4,%esp
f0101d25:	6a 00                	push   $0x0
f0101d27:	68 00 10 00 00       	push   $0x1000
f0101d2c:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d32:	ff 30                	pushl  (%eax)
f0101d34:	e8 38 f3 ff ff       	call   f0101071 <pgdir_walk>
f0101d39:	83 c4 10             	add    $0x10,%esp
f0101d3c:	f6 00 04             	testb  $0x4,(%eax)
f0101d3f:	0f 85 52 08 00 00    	jne    f0102597 <mem_init+0x1239>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d45:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d4b:	8b 00                	mov    (%eax),%eax
f0101d4d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d50:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d55:	e8 d6 ec ff ff       	call   f0100a30 <check_va2pa>
f0101d5a:	89 c6                	mov    %eax,%esi
f0101d5c:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101d62:	89 f9                	mov    %edi,%ecx
f0101d64:	2b 08                	sub    (%eax),%ecx
f0101d66:	89 c8                	mov    %ecx,%eax
f0101d68:	c1 f8 03             	sar    $0x3,%eax
f0101d6b:	c1 e0 0c             	shl    $0xc,%eax
f0101d6e:	39 c6                	cmp    %eax,%esi
f0101d70:	0f 85 40 08 00 00    	jne    f01025b6 <mem_init+0x1258>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d76:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d7b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101d7e:	e8 ad ec ff ff       	call   f0100a30 <check_va2pa>
f0101d83:	39 c6                	cmp    %eax,%esi
f0101d85:	0f 85 4a 08 00 00    	jne    f01025d5 <mem_init+0x1277>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101d8b:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101d90:	0f 85 5e 08 00 00    	jne    f01025f4 <mem_init+0x1296>
	assert(pp2->pp_ref == 0);
f0101d96:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d99:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101d9e:	0f 85 6f 08 00 00    	jne    f0102613 <mem_init+0x12b5>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101da4:	83 ec 0c             	sub    $0xc,%esp
f0101da7:	6a 00                	push   $0x0
f0101da9:	e8 a0 f1 ff ff       	call   f0100f4e <page_alloc>
f0101dae:	83 c4 10             	add    $0x10,%esp
f0101db1:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101db4:	0f 85 78 08 00 00    	jne    f0102632 <mem_init+0x12d4>
f0101dba:	85 c0                	test   %eax,%eax
f0101dbc:	0f 84 70 08 00 00    	je     f0102632 <mem_init+0x12d4>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101dc2:	83 ec 08             	sub    $0x8,%esp
f0101dc5:	6a 00                	push   $0x0
f0101dc7:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101dcd:	89 c6                	mov    %eax,%esi
f0101dcf:	ff 30                	pushl  (%eax)
f0101dd1:	e8 b8 f4 ff ff       	call   f010128e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101dd6:	8b 06                	mov    (%esi),%eax
f0101dd8:	89 c6                	mov    %eax,%esi
f0101dda:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ddf:	e8 4c ec ff ff       	call   f0100a30 <check_va2pa>
f0101de4:	83 c4 10             	add    $0x10,%esp
f0101de7:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dea:	0f 85 61 08 00 00    	jne    f0102651 <mem_init+0x12f3>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101df0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101df5:	89 f0                	mov    %esi,%eax
f0101df7:	e8 34 ec ff ff       	call   f0100a30 <check_va2pa>
f0101dfc:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101e02:	89 f9                	mov    %edi,%ecx
f0101e04:	2b 0a                	sub    (%edx),%ecx
f0101e06:	89 ca                	mov    %ecx,%edx
f0101e08:	c1 fa 03             	sar    $0x3,%edx
f0101e0b:	c1 e2 0c             	shl    $0xc,%edx
f0101e0e:	39 d0                	cmp    %edx,%eax
f0101e10:	0f 85 5a 08 00 00    	jne    f0102670 <mem_init+0x1312>
	assert(pp1->pp_ref == 1);
f0101e16:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101e1b:	0f 85 6e 08 00 00    	jne    f010268f <mem_init+0x1331>
	assert(pp2->pp_ref == 0);
f0101e21:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e24:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e29:	0f 85 7f 08 00 00    	jne    f01026ae <mem_init+0x1350>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e2f:	6a 00                	push   $0x0
f0101e31:	68 00 10 00 00       	push   $0x1000
f0101e36:	57                   	push   %edi
f0101e37:	56                   	push   %esi
f0101e38:	e8 8c f4 ff ff       	call   f01012c9 <page_insert>
f0101e3d:	83 c4 10             	add    $0x10,%esp
f0101e40:	85 c0                	test   %eax,%eax
f0101e42:	0f 85 85 08 00 00    	jne    f01026cd <mem_init+0x136f>
	assert(pp1->pp_ref);
f0101e48:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101e4d:	0f 84 99 08 00 00    	je     f01026ec <mem_init+0x138e>
	assert(pp1->pp_link == NULL);
f0101e53:	83 3f 00             	cmpl   $0x0,(%edi)
f0101e56:	0f 85 af 08 00 00    	jne    f010270b <mem_init+0x13ad>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e5c:	83 ec 08             	sub    $0x8,%esp
f0101e5f:	68 00 10 00 00       	push   $0x1000
f0101e64:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101e6a:	89 c6                	mov    %eax,%esi
f0101e6c:	ff 30                	pushl  (%eax)
f0101e6e:	e8 1b f4 ff ff       	call   f010128e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e73:	8b 06                	mov    (%esi),%eax
f0101e75:	89 c6                	mov    %eax,%esi
f0101e77:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e7c:	e8 af eb ff ff       	call   f0100a30 <check_va2pa>
f0101e81:	83 c4 10             	add    $0x10,%esp
f0101e84:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e87:	0f 85 9d 08 00 00    	jne    f010272a <mem_init+0x13cc>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e8d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e92:	89 f0                	mov    %esi,%eax
f0101e94:	e8 97 eb ff ff       	call   f0100a30 <check_va2pa>
f0101e99:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e9c:	0f 85 a7 08 00 00    	jne    f0102749 <mem_init+0x13eb>
	assert(pp1->pp_ref == 0);
f0101ea2:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101ea7:	0f 85 bb 08 00 00    	jne    f0102768 <mem_init+0x140a>
	assert(pp2->pp_ref == 0);
f0101ead:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eb0:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101eb5:	0f 85 cc 08 00 00    	jne    f0102787 <mem_init+0x1429>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ebb:	83 ec 0c             	sub    $0xc,%esp
f0101ebe:	6a 00                	push   $0x0
f0101ec0:	e8 89 f0 ff ff       	call   f0100f4e <page_alloc>
f0101ec5:	83 c4 10             	add    $0x10,%esp
f0101ec8:	85 c0                	test   %eax,%eax
f0101eca:	0f 84 d6 08 00 00    	je     f01027a6 <mem_init+0x1448>
f0101ed0:	39 c7                	cmp    %eax,%edi
f0101ed2:	0f 85 ce 08 00 00    	jne    f01027a6 <mem_init+0x1448>

	// should be no free memory
	assert(!page_alloc(0));
f0101ed8:	83 ec 0c             	sub    $0xc,%esp
f0101edb:	6a 00                	push   $0x0
f0101edd:	e8 6c f0 ff ff       	call   f0100f4e <page_alloc>
f0101ee2:	83 c4 10             	add    $0x10,%esp
f0101ee5:	85 c0                	test   %eax,%eax
f0101ee7:	0f 85 d8 08 00 00    	jne    f01027c5 <mem_init+0x1467>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101eed:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ef3:	8b 08                	mov    (%eax),%ecx
f0101ef5:	8b 11                	mov    (%ecx),%edx
f0101ef7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101efd:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101f03:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101f06:	2b 30                	sub    (%eax),%esi
f0101f08:	89 f0                	mov    %esi,%eax
f0101f0a:	c1 f8 03             	sar    $0x3,%eax
f0101f0d:	c1 e0 0c             	shl    $0xc,%eax
f0101f10:	39 c2                	cmp    %eax,%edx
f0101f12:	0f 85 cc 08 00 00    	jne    f01027e4 <mem_init+0x1486>
	kern_pgdir[0] = 0;
f0101f18:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f1e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f21:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f26:	0f 85 d7 08 00 00    	jne    f0102803 <mem_init+0x14a5>
	pp0->pp_ref = 0;
f0101f2c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f2f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f35:	83 ec 0c             	sub    $0xc,%esp
f0101f38:	50                   	push   %eax
f0101f39:	e8 98 f0 ff ff       	call   f0100fd6 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f3e:	83 c4 0c             	add    $0xc,%esp
f0101f41:	6a 01                	push   $0x1
f0101f43:	68 00 10 40 00       	push   $0x401000
f0101f48:	c7 c6 cc 96 11 f0    	mov    $0xf01196cc,%esi
f0101f4e:	ff 36                	pushl  (%esi)
f0101f50:	e8 1c f1 ff ff       	call   f0101071 <pgdir_walk>
f0101f55:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f58:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f5b:	8b 06                	mov    (%esi),%eax
f0101f5d:	8b 50 04             	mov    0x4(%eax),%edx
f0101f60:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101f66:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0101f6c:	8b 09                	mov    (%ecx),%ecx
f0101f6e:	89 d6                	mov    %edx,%esi
f0101f70:	c1 ee 0c             	shr    $0xc,%esi
f0101f73:	83 c4 10             	add    $0x10,%esp
f0101f76:	39 ce                	cmp    %ecx,%esi
f0101f78:	0f 83 a4 08 00 00    	jae    f0102822 <mem_init+0x14c4>
	assert(ptep == ptep1 + PTX(va));
f0101f7e:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0101f84:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0101f87:	0f 85 ae 08 00 00    	jne    f010283b <mem_init+0x14dd>
	kern_pgdir[PDX(va)] = 0;
f0101f8d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101f94:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101f97:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
	return (pp - pages) << PGSHIFT;
f0101f9d:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101fa3:	2b 10                	sub    (%eax),%edx
f0101fa5:	89 d0                	mov    %edx,%eax
f0101fa7:	c1 f8 03             	sar    $0x3,%eax
f0101faa:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101fad:	89 c2                	mov    %eax,%edx
f0101faf:	c1 ea 0c             	shr    $0xc,%edx
f0101fb2:	39 d1                	cmp    %edx,%ecx
f0101fb4:	0f 86 a0 08 00 00    	jbe    f010285a <mem_init+0x14fc>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101fba:	83 ec 04             	sub    $0x4,%esp
f0101fbd:	68 00 10 00 00       	push   $0x1000
f0101fc2:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0101fc7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fcc:	50                   	push   %eax
f0101fcd:	e8 05 1c 00 00       	call   f0103bd7 <memset>
	page_free(pp0);
f0101fd2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101fd5:	89 34 24             	mov    %esi,(%esp)
f0101fd8:	e8 f9 ef ff ff       	call   f0100fd6 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101fdd:	83 c4 0c             	add    $0xc,%esp
f0101fe0:	6a 01                	push   $0x1
f0101fe2:	6a 00                	push   $0x0
f0101fe4:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101fea:	ff 30                	pushl  (%eax)
f0101fec:	e8 80 f0 ff ff       	call   f0101071 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0101ff1:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101ff7:	89 f2                	mov    %esi,%edx
f0101ff9:	2b 10                	sub    (%eax),%edx
f0101ffb:	c1 fa 03             	sar    $0x3,%edx
f0101ffe:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102001:	89 d1                	mov    %edx,%ecx
f0102003:	c1 e9 0c             	shr    $0xc,%ecx
f0102006:	83 c4 10             	add    $0x10,%esp
f0102009:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f010200f:	3b 08                	cmp    (%eax),%ecx
f0102011:	0f 83 59 08 00 00    	jae    f0102870 <mem_init+0x1512>
	return (void *)(pa + KERNBASE);
f0102017:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010201d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102020:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
f0102026:	8b 75 d4             	mov    -0x2c(%ebp),%esi
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102029:	f6 00 01             	testb  $0x1,(%eax)
f010202c:	0f 85 54 08 00 00    	jne    f0102886 <mem_init+0x1528>
f0102032:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0102035:	39 d0                	cmp    %edx,%eax
f0102037:	75 f0                	jne    f0102029 <mem_init+0xccb>
	kern_pgdir[0] = 0;
f0102039:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f010203f:	8b 00                	mov    (%eax),%eax
f0102041:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102047:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010204a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102050:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102053:	89 8b 94 1f 00 00    	mov    %ecx,0x1f94(%ebx)

	// free the pages we took
	page_free(pp0);
f0102059:	83 ec 0c             	sub    $0xc,%esp
f010205c:	50                   	push   %eax
f010205d:	e8 74 ef ff ff       	call   f0100fd6 <page_free>
	page_free(pp1);
f0102062:	89 3c 24             	mov    %edi,(%esp)
f0102065:	e8 6c ef ff ff       	call   f0100fd6 <page_free>
	page_free(pp2);
f010206a:	89 34 24             	mov    %esi,(%esp)
f010206d:	e8 64 ef ff ff       	call   f0100fd6 <page_free>

	cprintf("check_page() succeeded!\n");
f0102072:	8d 83 68 d4 fe ff    	lea    -0x12b98(%ebx),%eax
f0102078:	89 04 24             	mov    %eax,(%esp)
f010207b:	e8 fb 0f 00 00       	call   f010307b <cprintf>
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U ); // since PTE_P will be handled by function itself
f0102080:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102086:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102088:	83 c4 10             	add    $0x10,%esp
f010208b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102090:	0f 86 0f 08 00 00    	jbe    f01028a5 <mem_init+0x1547>
f0102096:	83 ec 08             	sub    $0x8,%esp
f0102099:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f010209b:	05 00 00 00 10       	add    $0x10000000,%eax
f01020a0:	50                   	push   %eax
f01020a1:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020a6:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01020ab:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f01020b1:	8b 00                	mov    (%eax),%eax
f01020b3:	e8 a7 f0 ff ff       	call   f010115f <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f01020b8:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f01020be:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01020c1:	83 c4 10             	add    $0x10,%esp
f01020c4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020c9:	0f 86 ef 07 00 00    	jbe    f01028be <mem_init+0x1560>
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W); //permissions?);
f01020cf:	c7 c6 cc 96 11 f0    	mov    $0xf01196cc,%esi
f01020d5:	83 ec 08             	sub    $0x8,%esp
f01020d8:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f01020da:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01020dd:	05 00 00 00 10       	add    $0x10000000,%eax
f01020e2:	50                   	push   %eax
f01020e3:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01020e8:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01020ed:	8b 06                	mov    (%esi),%eax
f01020ef:	e8 6b f0 ff ff       	call   f010115f <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff + 1 - KERNBASE, 0, PTE_W);
f01020f4:	83 c4 08             	add    $0x8,%esp
f01020f7:	6a 02                	push   $0x2
f01020f9:	6a 00                	push   $0x0
f01020fb:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102100:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102105:	8b 06                	mov    (%esi),%eax
f0102107:	e8 53 f0 ff ff       	call   f010115f <boot_map_region>
	pgdir = kern_pgdir;
f010210c:	8b 36                	mov    (%esi),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010210e:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0102114:	8b 00                	mov    (%eax),%eax
f0102116:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102119:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102120:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102125:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102128:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010212e:	8b 00                	mov    (%eax),%eax
f0102130:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102133:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102136:	05 00 00 00 10       	add    $0x10000000,%eax
f010213b:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f010213e:	bf 00 00 00 00       	mov    $0x0,%edi
f0102143:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0102146:	89 c6                	mov    %eax,%esi
f0102148:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f010214b:	0f 86 c0 07 00 00    	jbe    f0102911 <mem_init+0x15b3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102151:	8d 97 00 00 00 ef    	lea    -0x11000000(%edi),%edx
f0102157:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010215a:	e8 d1 e8 ff ff       	call   f0100a30 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f010215f:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102166:	0f 86 6b 07 00 00    	jbe    f01028d7 <mem_init+0x1579>
f010216c:	8d 14 37             	lea    (%edi,%esi,1),%edx
f010216f:	39 c2                	cmp    %eax,%edx
f0102171:	0f 85 7b 07 00 00    	jne    f01028f2 <mem_init+0x1594>
	for (i = 0; i < n; i += PGSIZE)
f0102177:	81 c7 00 10 00 00    	add    $0x1000,%edi
f010217d:	eb c9                	jmp    f0102148 <mem_init+0xdea>
	assert(nfree == 0);
f010217f:	8d 83 91 d3 fe ff    	lea    -0x12c6f(%ebx),%eax
f0102185:	50                   	push   %eax
f0102186:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010218c:	50                   	push   %eax
f010218d:	68 94 03 00 00       	push   $0x394
f0102192:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102198:	50                   	push   %eax
f0102199:	e8 fb de ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f010219e:	8d 83 9f d2 fe ff    	lea    -0x12d61(%ebx),%eax
f01021a4:	50                   	push   %eax
f01021a5:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01021ab:	50                   	push   %eax
f01021ac:	68 ed 03 00 00       	push   $0x3ed
f01021b1:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01021b7:	50                   	push   %eax
f01021b8:	e8 dc de ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01021bd:	8d 83 b5 d2 fe ff    	lea    -0x12d4b(%ebx),%eax
f01021c3:	50                   	push   %eax
f01021c4:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01021ca:	50                   	push   %eax
f01021cb:	68 ee 03 00 00       	push   $0x3ee
f01021d0:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01021d6:	50                   	push   %eax
f01021d7:	e8 bd de ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01021dc:	8d 83 cb d2 fe ff    	lea    -0x12d35(%ebx),%eax
f01021e2:	50                   	push   %eax
f01021e3:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01021e9:	50                   	push   %eax
f01021ea:	68 ef 03 00 00       	push   $0x3ef
f01021ef:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01021f5:	50                   	push   %eax
f01021f6:	e8 9e de ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01021fb:	8d 83 e1 d2 fe ff    	lea    -0x12d1f(%ebx),%eax
f0102201:	50                   	push   %eax
f0102202:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102208:	50                   	push   %eax
f0102209:	68 f2 03 00 00       	push   $0x3f2
f010220e:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102214:	50                   	push   %eax
f0102215:	e8 7f de ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010221a:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f0102220:	50                   	push   %eax
f0102221:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102227:	50                   	push   %eax
f0102228:	68 f3 03 00 00       	push   $0x3f3
f010222d:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102233:	50                   	push   %eax
f0102234:	e8 60 de ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102239:	8d 83 4a d3 fe ff    	lea    -0x12cb6(%ebx),%eax
f010223f:	50                   	push   %eax
f0102240:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102246:	50                   	push   %eax
f0102247:	68 fa 03 00 00       	push   $0x3fa
f010224c:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102252:	50                   	push   %eax
f0102253:	e8 41 de ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102258:	8d 83 80 d6 fe ff    	lea    -0x12980(%ebx),%eax
f010225e:	50                   	push   %eax
f010225f:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102265:	50                   	push   %eax
f0102266:	68 fd 03 00 00       	push   $0x3fd
f010226b:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102271:	50                   	push   %eax
f0102272:	e8 22 de ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102277:	8d 83 b8 d6 fe ff    	lea    -0x12948(%ebx),%eax
f010227d:	50                   	push   %eax
f010227e:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102284:	50                   	push   %eax
f0102285:	68 00 04 00 00       	push   $0x400
f010228a:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102290:	50                   	push   %eax
f0102291:	e8 03 de ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102296:	8d 83 e8 d6 fe ff    	lea    -0x12918(%ebx),%eax
f010229c:	50                   	push   %eax
f010229d:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01022a3:	50                   	push   %eax
f01022a4:	68 04 04 00 00       	push   $0x404
f01022a9:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01022af:	50                   	push   %eax
f01022b0:	e8 e4 dd ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01022b5:	8d 83 18 d7 fe ff    	lea    -0x128e8(%ebx),%eax
f01022bb:	50                   	push   %eax
f01022bc:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01022c2:	50                   	push   %eax
f01022c3:	68 05 04 00 00       	push   $0x405
f01022c8:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01022ce:	50                   	push   %eax
f01022cf:	e8 c5 dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01022d4:	8d 83 40 d7 fe ff    	lea    -0x128c0(%ebx),%eax
f01022da:	50                   	push   %eax
f01022db:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01022e1:	50                   	push   %eax
f01022e2:	68 06 04 00 00       	push   $0x406
f01022e7:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01022ed:	50                   	push   %eax
f01022ee:	e8 a6 dd ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01022f3:	8d 83 9c d3 fe ff    	lea    -0x12c64(%ebx),%eax
f01022f9:	50                   	push   %eax
f01022fa:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102300:	50                   	push   %eax
f0102301:	68 07 04 00 00       	push   $0x407
f0102306:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010230c:	50                   	push   %eax
f010230d:	e8 87 dd ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102312:	8d 83 ad d3 fe ff    	lea    -0x12c53(%ebx),%eax
f0102318:	50                   	push   %eax
f0102319:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010231f:	50                   	push   %eax
f0102320:	68 08 04 00 00       	push   $0x408
f0102325:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010232b:	50                   	push   %eax
f010232c:	e8 68 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102331:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f0102337:	50                   	push   %eax
f0102338:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010233e:	50                   	push   %eax
f010233f:	68 0b 04 00 00       	push   $0x40b
f0102344:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010234a:	50                   	push   %eax
f010234b:	e8 49 dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102350:	8d 83 ac d7 fe ff    	lea    -0x12854(%ebx),%eax
f0102356:	50                   	push   %eax
f0102357:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010235d:	50                   	push   %eax
f010235e:	68 0c 04 00 00       	push   $0x40c
f0102363:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102369:	50                   	push   %eax
f010236a:	e8 2a dd ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f010236f:	8d 83 be d3 fe ff    	lea    -0x12c42(%ebx),%eax
f0102375:	50                   	push   %eax
f0102376:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010237c:	50                   	push   %eax
f010237d:	68 0d 04 00 00       	push   $0x40d
f0102382:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102388:	50                   	push   %eax
f0102389:	e8 0b dd ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010238e:	8d 83 4a d3 fe ff    	lea    -0x12cb6(%ebx),%eax
f0102394:	50                   	push   %eax
f0102395:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010239b:	50                   	push   %eax
f010239c:	68 10 04 00 00       	push   $0x410
f01023a1:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01023a7:	50                   	push   %eax
f01023a8:	e8 ec dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023ad:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f01023b3:	50                   	push   %eax
f01023b4:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01023ba:	50                   	push   %eax
f01023bb:	68 13 04 00 00       	push   $0x413
f01023c0:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01023c6:	50                   	push   %eax
f01023c7:	e8 cd dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023cc:	8d 83 ac d7 fe ff    	lea    -0x12854(%ebx),%eax
f01023d2:	50                   	push   %eax
f01023d3:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01023d9:	50                   	push   %eax
f01023da:	68 14 04 00 00       	push   $0x414
f01023df:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01023e5:	50                   	push   %eax
f01023e6:	e8 ae dc ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01023eb:	8d 83 be d3 fe ff    	lea    -0x12c42(%ebx),%eax
f01023f1:	50                   	push   %eax
f01023f2:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01023f8:	50                   	push   %eax
f01023f9:	68 15 04 00 00       	push   $0x415
f01023fe:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102404:	50                   	push   %eax
f0102405:	e8 8f dc ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010240a:	8d 83 4a d3 fe ff    	lea    -0x12cb6(%ebx),%eax
f0102410:	50                   	push   %eax
f0102411:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102417:	50                   	push   %eax
f0102418:	68 19 04 00 00       	push   $0x419
f010241d:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102423:	50                   	push   %eax
f0102424:	e8 70 dc ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102429:	50                   	push   %eax
f010242a:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f0102430:	50                   	push   %eax
f0102431:	68 1c 04 00 00       	push   $0x41c
f0102436:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010243c:	50                   	push   %eax
f010243d:	e8 57 dc ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102442:	8d 83 dc d7 fe ff    	lea    -0x12824(%ebx),%eax
f0102448:	50                   	push   %eax
f0102449:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010244f:	50                   	push   %eax
f0102450:	68 1d 04 00 00       	push   $0x41d
f0102455:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010245b:	50                   	push   %eax
f010245c:	e8 38 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102461:	8d 83 1c d8 fe ff    	lea    -0x127e4(%ebx),%eax
f0102467:	50                   	push   %eax
f0102468:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010246e:	50                   	push   %eax
f010246f:	68 20 04 00 00       	push   $0x420
f0102474:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010247a:	50                   	push   %eax
f010247b:	e8 19 dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102480:	8d 83 ac d7 fe ff    	lea    -0x12854(%ebx),%eax
f0102486:	50                   	push   %eax
f0102487:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010248d:	50                   	push   %eax
f010248e:	68 21 04 00 00       	push   $0x421
f0102493:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102499:	50                   	push   %eax
f010249a:	e8 fa db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f010249f:	8d 83 be d3 fe ff    	lea    -0x12c42(%ebx),%eax
f01024a5:	50                   	push   %eax
f01024a6:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01024ac:	50                   	push   %eax
f01024ad:	68 22 04 00 00       	push   $0x422
f01024b2:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01024b8:	50                   	push   %eax
f01024b9:	e8 db db ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01024be:	8d 83 5c d8 fe ff    	lea    -0x127a4(%ebx),%eax
f01024c4:	50                   	push   %eax
f01024c5:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01024cb:	50                   	push   %eax
f01024cc:	68 23 04 00 00       	push   $0x423
f01024d1:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01024d7:	50                   	push   %eax
f01024d8:	e8 bc db ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01024dd:	8d 83 cf d3 fe ff    	lea    -0x12c31(%ebx),%eax
f01024e3:	50                   	push   %eax
f01024e4:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01024ea:	50                   	push   %eax
f01024eb:	68 24 04 00 00       	push   $0x424
f01024f0:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01024f6:	50                   	push   %eax
f01024f7:	e8 9d db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024fc:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f0102502:	50                   	push   %eax
f0102503:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102509:	50                   	push   %eax
f010250a:	68 27 04 00 00       	push   $0x427
f010250f:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102515:	50                   	push   %eax
f0102516:	e8 7e db ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010251b:	8d 83 90 d8 fe ff    	lea    -0x12770(%ebx),%eax
f0102521:	50                   	push   %eax
f0102522:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102528:	50                   	push   %eax
f0102529:	68 28 04 00 00       	push   $0x428
f010252e:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102534:	50                   	push   %eax
f0102535:	e8 5f db ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010253a:	8d 83 c4 d8 fe ff    	lea    -0x1273c(%ebx),%eax
f0102540:	50                   	push   %eax
f0102541:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102547:	50                   	push   %eax
f0102548:	68 29 04 00 00       	push   $0x429
f010254d:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102553:	50                   	push   %eax
f0102554:	e8 40 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102559:	8d 83 fc d8 fe ff    	lea    -0x12704(%ebx),%eax
f010255f:	50                   	push   %eax
f0102560:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102566:	50                   	push   %eax
f0102567:	68 2c 04 00 00       	push   $0x42c
f010256c:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102572:	50                   	push   %eax
f0102573:	e8 21 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102578:	8d 83 34 d9 fe ff    	lea    -0x126cc(%ebx),%eax
f010257e:	50                   	push   %eax
f010257f:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102585:	50                   	push   %eax
f0102586:	68 2f 04 00 00       	push   $0x42f
f010258b:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102591:	50                   	push   %eax
f0102592:	e8 02 db ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102597:	8d 83 c4 d8 fe ff    	lea    -0x1273c(%ebx),%eax
f010259d:	50                   	push   %eax
f010259e:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01025a4:	50                   	push   %eax
f01025a5:	68 30 04 00 00       	push   $0x430
f01025aa:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01025b0:	50                   	push   %eax
f01025b1:	e8 e3 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01025b6:	8d 83 70 d9 fe ff    	lea    -0x12690(%ebx),%eax
f01025bc:	50                   	push   %eax
f01025bd:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01025c3:	50                   	push   %eax
f01025c4:	68 33 04 00 00       	push   $0x433
f01025c9:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01025cf:	50                   	push   %eax
f01025d0:	e8 c4 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01025d5:	8d 83 9c d9 fe ff    	lea    -0x12664(%ebx),%eax
f01025db:	50                   	push   %eax
f01025dc:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01025e2:	50                   	push   %eax
f01025e3:	68 34 04 00 00       	push   $0x434
f01025e8:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01025ee:	50                   	push   %eax
f01025ef:	e8 a5 da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f01025f4:	8d 83 e5 d3 fe ff    	lea    -0x12c1b(%ebx),%eax
f01025fa:	50                   	push   %eax
f01025fb:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102601:	50                   	push   %eax
f0102602:	68 36 04 00 00       	push   $0x436
f0102607:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010260d:	50                   	push   %eax
f010260e:	e8 86 da ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102613:	8d 83 f6 d3 fe ff    	lea    -0x12c0a(%ebx),%eax
f0102619:	50                   	push   %eax
f010261a:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102620:	50                   	push   %eax
f0102621:	68 37 04 00 00       	push   $0x437
f0102626:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010262c:	50                   	push   %eax
f010262d:	e8 67 da ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102632:	8d 83 cc d9 fe ff    	lea    -0x12634(%ebx),%eax
f0102638:	50                   	push   %eax
f0102639:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010263f:	50                   	push   %eax
f0102640:	68 3a 04 00 00       	push   $0x43a
f0102645:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010264b:	50                   	push   %eax
f010264c:	e8 48 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102651:	8d 83 f0 d9 fe ff    	lea    -0x12610(%ebx),%eax
f0102657:	50                   	push   %eax
f0102658:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010265e:	50                   	push   %eax
f010265f:	68 3e 04 00 00       	push   $0x43e
f0102664:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010266a:	50                   	push   %eax
f010266b:	e8 29 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102670:	8d 83 9c d9 fe ff    	lea    -0x12664(%ebx),%eax
f0102676:	50                   	push   %eax
f0102677:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010267d:	50                   	push   %eax
f010267e:	68 3f 04 00 00       	push   $0x43f
f0102683:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102689:	50                   	push   %eax
f010268a:	e8 0a da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f010268f:	8d 83 9c d3 fe ff    	lea    -0x12c64(%ebx),%eax
f0102695:	50                   	push   %eax
f0102696:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f010269c:	50                   	push   %eax
f010269d:	68 40 04 00 00       	push   $0x440
f01026a2:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01026a8:	50                   	push   %eax
f01026a9:	e8 eb d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01026ae:	8d 83 f6 d3 fe ff    	lea    -0x12c0a(%ebx),%eax
f01026b4:	50                   	push   %eax
f01026b5:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01026bb:	50                   	push   %eax
f01026bc:	68 41 04 00 00       	push   $0x441
f01026c1:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01026c7:	50                   	push   %eax
f01026c8:	e8 cc d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01026cd:	8d 83 14 da fe ff    	lea    -0x125ec(%ebx),%eax
f01026d3:	50                   	push   %eax
f01026d4:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01026da:	50                   	push   %eax
f01026db:	68 44 04 00 00       	push   $0x444
f01026e0:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01026e6:	50                   	push   %eax
f01026e7:	e8 ad d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f01026ec:	8d 83 07 d4 fe ff    	lea    -0x12bf9(%ebx),%eax
f01026f2:	50                   	push   %eax
f01026f3:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01026f9:	50                   	push   %eax
f01026fa:	68 45 04 00 00       	push   $0x445
f01026ff:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102705:	50                   	push   %eax
f0102706:	e8 8e d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f010270b:	8d 83 13 d4 fe ff    	lea    -0x12bed(%ebx),%eax
f0102711:	50                   	push   %eax
f0102712:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102718:	50                   	push   %eax
f0102719:	68 46 04 00 00       	push   $0x446
f010271e:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102724:	50                   	push   %eax
f0102725:	e8 6f d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010272a:	8d 83 f0 d9 fe ff    	lea    -0x12610(%ebx),%eax
f0102730:	50                   	push   %eax
f0102731:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102737:	50                   	push   %eax
f0102738:	68 4a 04 00 00       	push   $0x44a
f010273d:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102743:	50                   	push   %eax
f0102744:	e8 50 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102749:	8d 83 4c da fe ff    	lea    -0x125b4(%ebx),%eax
f010274f:	50                   	push   %eax
f0102750:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102756:	50                   	push   %eax
f0102757:	68 4b 04 00 00       	push   $0x44b
f010275c:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102762:	50                   	push   %eax
f0102763:	e8 31 d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102768:	8d 83 28 d4 fe ff    	lea    -0x12bd8(%ebx),%eax
f010276e:	50                   	push   %eax
f010276f:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102775:	50                   	push   %eax
f0102776:	68 4c 04 00 00       	push   $0x44c
f010277b:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102781:	50                   	push   %eax
f0102782:	e8 12 d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102787:	8d 83 f6 d3 fe ff    	lea    -0x12c0a(%ebx),%eax
f010278d:	50                   	push   %eax
f010278e:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102794:	50                   	push   %eax
f0102795:	68 4d 04 00 00       	push   $0x44d
f010279a:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01027a0:	50                   	push   %eax
f01027a1:	e8 f3 d8 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01027a6:	8d 83 74 da fe ff    	lea    -0x1258c(%ebx),%eax
f01027ac:	50                   	push   %eax
f01027ad:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01027b3:	50                   	push   %eax
f01027b4:	68 50 04 00 00       	push   $0x450
f01027b9:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01027bf:	50                   	push   %eax
f01027c0:	e8 d4 d8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01027c5:	8d 83 4a d3 fe ff    	lea    -0x12cb6(%ebx),%eax
f01027cb:	50                   	push   %eax
f01027cc:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01027d2:	50                   	push   %eax
f01027d3:	68 53 04 00 00       	push   $0x453
f01027d8:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01027de:	50                   	push   %eax
f01027df:	e8 b5 d8 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01027e4:	8d 83 18 d7 fe ff    	lea    -0x128e8(%ebx),%eax
f01027ea:	50                   	push   %eax
f01027eb:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01027f1:	50                   	push   %eax
f01027f2:	68 56 04 00 00       	push   $0x456
f01027f7:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01027fd:	50                   	push   %eax
f01027fe:	e8 96 d8 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102803:	8d 83 ad d3 fe ff    	lea    -0x12c53(%ebx),%eax
f0102809:	50                   	push   %eax
f010280a:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102810:	50                   	push   %eax
f0102811:	68 58 04 00 00       	push   $0x458
f0102816:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010281c:	50                   	push   %eax
f010281d:	e8 77 d8 ff ff       	call   f0100099 <_panic>
f0102822:	52                   	push   %edx
f0102823:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f0102829:	50                   	push   %eax
f010282a:	68 5f 04 00 00       	push   $0x45f
f010282f:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102835:	50                   	push   %eax
f0102836:	e8 5e d8 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010283b:	8d 83 39 d4 fe ff    	lea    -0x12bc7(%ebx),%eax
f0102841:	50                   	push   %eax
f0102842:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102848:	50                   	push   %eax
f0102849:	68 60 04 00 00       	push   $0x460
f010284e:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102854:	50                   	push   %eax
f0102855:	e8 3f d8 ff ff       	call   f0100099 <_panic>
f010285a:	50                   	push   %eax
f010285b:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f0102861:	50                   	push   %eax
f0102862:	6a 52                	push   $0x52
f0102864:	8d 83 94 d1 fe ff    	lea    -0x12e6c(%ebx),%eax
f010286a:	50                   	push   %eax
f010286b:	e8 29 d8 ff ff       	call   f0100099 <_panic>
f0102870:	52                   	push   %edx
f0102871:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f0102877:	50                   	push   %eax
f0102878:	6a 52                	push   $0x52
f010287a:	8d 83 94 d1 fe ff    	lea    -0x12e6c(%ebx),%eax
f0102880:	50                   	push   %eax
f0102881:	e8 13 d8 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102886:	8d 83 51 d4 fe ff    	lea    -0x12baf(%ebx),%eax
f010288c:	50                   	push   %eax
f010288d:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102893:	50                   	push   %eax
f0102894:	68 6a 04 00 00       	push   $0x46a
f0102899:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010289f:	50                   	push   %eax
f01028a0:	e8 f4 d7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028a5:	50                   	push   %eax
f01028a6:	8d 83 1c d6 fe ff    	lea    -0x129e4(%ebx),%eax
f01028ac:	50                   	push   %eax
f01028ad:	68 e6 00 00 00       	push   $0xe6
f01028b2:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01028b8:	50                   	push   %eax
f01028b9:	e8 db d7 ff ff       	call   f0100099 <_panic>
f01028be:	50                   	push   %eax
f01028bf:	8d 83 1c d6 fe ff    	lea    -0x129e4(%ebx),%eax
f01028c5:	50                   	push   %eax
f01028c6:	68 f6 00 00 00       	push   $0xf6
f01028cb:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01028d1:	50                   	push   %eax
f01028d2:	e8 c2 d7 ff ff       	call   f0100099 <_panic>
f01028d7:	ff 75 c0             	pushl  -0x40(%ebp)
f01028da:	8d 83 1c d6 fe ff    	lea    -0x129e4(%ebx),%eax
f01028e0:	50                   	push   %eax
f01028e1:	68 ac 03 00 00       	push   $0x3ac
f01028e6:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01028ec:	50                   	push   %eax
f01028ed:	e8 a7 d7 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01028f2:	8d 83 98 da fe ff    	lea    -0x12568(%ebx),%eax
f01028f8:	50                   	push   %eax
f01028f9:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01028ff:	50                   	push   %eax
f0102900:	68 ac 03 00 00       	push   $0x3ac
f0102905:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f010290b:	50                   	push   %eax
f010290c:	e8 88 d7 ff ff       	call   f0100099 <_panic>
f0102911:	8b 75 d0             	mov    -0x30(%ebp),%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102914:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0102917:	c1 e0 0c             	shl    $0xc,%eax
f010291a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010291d:	bf 00 00 00 00       	mov    $0x0,%edi
f0102922:	eb 17                	jmp    f010293b <mem_init+0x15dd>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102924:	8d 97 00 00 00 f0    	lea    -0x10000000(%edi),%edx
f010292a:	89 f0                	mov    %esi,%eax
f010292c:	e8 ff e0 ff ff       	call   f0100a30 <check_va2pa>
f0102931:	39 c7                	cmp    %eax,%edi
f0102933:	75 57                	jne    f010298c <mem_init+0x162e>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102935:	81 c7 00 10 00 00    	add    $0x1000,%edi
f010293b:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010293e:	72 e4                	jb     f0102924 <mem_init+0x15c6>
f0102940:	bf 00 80 ff ef       	mov    $0xefff8000,%edi
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102945:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102948:	05 00 80 00 20       	add    $0x20008000,%eax
f010294d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102950:	89 fa                	mov    %edi,%edx
f0102952:	89 f0                	mov    %esi,%eax
f0102954:	e8 d7 e0 ff ff       	call   f0100a30 <check_va2pa>
f0102959:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010295c:	8d 14 39             	lea    (%ecx,%edi,1),%edx
f010295f:	39 c2                	cmp    %eax,%edx
f0102961:	75 48                	jne    f01029ab <mem_init+0x164d>
f0102963:	81 c7 00 10 00 00    	add    $0x1000,%edi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102969:	81 ff 00 00 00 f0    	cmp    $0xf0000000,%edi
f010296f:	75 df                	jne    f0102950 <mem_init+0x15f2>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102971:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102976:	89 f0                	mov    %esi,%eax
f0102978:	e8 b3 e0 ff ff       	call   f0100a30 <check_va2pa>
f010297d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102980:	75 48                	jne    f01029ca <mem_init+0x166c>
	for (i = 0; i < NPDENTRIES; i++) {
f0102982:	b8 00 00 00 00       	mov    $0x0,%eax
f0102987:	e9 86 00 00 00       	jmp    f0102a12 <mem_init+0x16b4>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010298c:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102992:	50                   	push   %eax
f0102993:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102999:	50                   	push   %eax
f010299a:	68 b1 03 00 00       	push   $0x3b1
f010299f:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01029a5:	50                   	push   %eax
f01029a6:	e8 ee d6 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01029ab:	8d 83 f4 da fe ff    	lea    -0x1250c(%ebx),%eax
f01029b1:	50                   	push   %eax
f01029b2:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01029b8:	50                   	push   %eax
f01029b9:	68 b5 03 00 00       	push   $0x3b5
f01029be:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01029c4:	50                   	push   %eax
f01029c5:	e8 cf d6 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01029ca:	8d 83 3c db fe ff    	lea    -0x124c4(%ebx),%eax
f01029d0:	50                   	push   %eax
f01029d1:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01029d7:	50                   	push   %eax
f01029d8:	68 b6 03 00 00       	push   $0x3b6
f01029dd:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f01029e3:	50                   	push   %eax
f01029e4:	e8 b0 d6 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f01029e9:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01029ed:	74 4f                	je     f0102a3e <mem_init+0x16e0>
	for (i = 0; i < NPDENTRIES; i++) {
f01029ef:	83 c0 01             	add    $0x1,%eax
f01029f2:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01029f7:	0f 87 ab 00 00 00    	ja     f0102aa8 <mem_init+0x174a>
		switch (i) {
f01029fd:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102a02:	72 0e                	jb     f0102a12 <mem_init+0x16b4>
f0102a04:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102a09:	76 de                	jbe    f01029e9 <mem_init+0x168b>
f0102a0b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a10:	74 d7                	je     f01029e9 <mem_init+0x168b>
			if (i >= PDX(KERNBASE)) {
f0102a12:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a17:	77 44                	ja     f0102a5d <mem_init+0x16ff>
				assert(pgdir[i] == 0);
f0102a19:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102a1d:	74 d0                	je     f01029ef <mem_init+0x1691>
f0102a1f:	8d 83 a3 d4 fe ff    	lea    -0x12b5d(%ebx),%eax
f0102a25:	50                   	push   %eax
f0102a26:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102a2c:	50                   	push   %eax
f0102a2d:	68 c5 03 00 00       	push   $0x3c5
f0102a32:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102a38:	50                   	push   %eax
f0102a39:	e8 5b d6 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102a3e:	8d 83 81 d4 fe ff    	lea    -0x12b7f(%ebx),%eax
f0102a44:	50                   	push   %eax
f0102a45:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102a4b:	50                   	push   %eax
f0102a4c:	68 be 03 00 00       	push   $0x3be
f0102a51:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102a57:	50                   	push   %eax
f0102a58:	e8 3c d6 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102a5d:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102a60:	f6 c2 01             	test   $0x1,%dl
f0102a63:	74 24                	je     f0102a89 <mem_init+0x172b>
				assert(pgdir[i] & PTE_W);
f0102a65:	f6 c2 02             	test   $0x2,%dl
f0102a68:	75 85                	jne    f01029ef <mem_init+0x1691>
f0102a6a:	8d 83 92 d4 fe ff    	lea    -0x12b6e(%ebx),%eax
f0102a70:	50                   	push   %eax
f0102a71:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102a77:	50                   	push   %eax
f0102a78:	68 c3 03 00 00       	push   $0x3c3
f0102a7d:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102a83:	50                   	push   %eax
f0102a84:	e8 10 d6 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102a89:	8d 83 81 d4 fe ff    	lea    -0x12b7f(%ebx),%eax
f0102a8f:	50                   	push   %eax
f0102a90:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102a96:	50                   	push   %eax
f0102a97:	68 c2 03 00 00       	push   $0x3c2
f0102a9c:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102aa2:	50                   	push   %eax
f0102aa3:	e8 f1 d5 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102aa8:	83 ec 0c             	sub    $0xc,%esp
f0102aab:	8d 83 6c db fe ff    	lea    -0x12494(%ebx),%eax
f0102ab1:	50                   	push   %eax
f0102ab2:	e8 c4 05 00 00       	call   f010307b <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102ab7:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102abd:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102abf:	83 c4 10             	add    $0x10,%esp
f0102ac2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ac7:	0f 86 41 03 00 00    	jbe    f0102e0e <mem_init+0x1ab0>
	return (physaddr_t)kva - KERNBASE;
f0102acd:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102ad2:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102ad5:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ada:	e8 ce df ff ff       	call   f0100aad <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102adf:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102ae2:	83 e0 f3             	and    $0xfffffff3,%eax
f0102ae5:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102aea:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102aed:	83 ec 0c             	sub    $0xc,%esp
f0102af0:	6a 00                	push   $0x0
f0102af2:	e8 57 e4 ff ff       	call   f0100f4e <page_alloc>
f0102af7:	89 c6                	mov    %eax,%esi
f0102af9:	83 c4 10             	add    $0x10,%esp
f0102afc:	85 c0                	test   %eax,%eax
f0102afe:	0f 84 23 03 00 00    	je     f0102e27 <mem_init+0x1ac9>
	assert((pp1 = page_alloc(0)));
f0102b04:	83 ec 0c             	sub    $0xc,%esp
f0102b07:	6a 00                	push   $0x0
f0102b09:	e8 40 e4 ff ff       	call   f0100f4e <page_alloc>
f0102b0e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102b11:	83 c4 10             	add    $0x10,%esp
f0102b14:	85 c0                	test   %eax,%eax
f0102b16:	0f 84 2a 03 00 00    	je     f0102e46 <mem_init+0x1ae8>
	assert((pp2 = page_alloc(0)));
f0102b1c:	83 ec 0c             	sub    $0xc,%esp
f0102b1f:	6a 00                	push   $0x0
f0102b21:	e8 28 e4 ff ff       	call   f0100f4e <page_alloc>
f0102b26:	89 c7                	mov    %eax,%edi
f0102b28:	83 c4 10             	add    $0x10,%esp
f0102b2b:	85 c0                	test   %eax,%eax
f0102b2d:	0f 84 32 03 00 00    	je     f0102e65 <mem_init+0x1b07>
	page_free(pp0);
f0102b33:	83 ec 0c             	sub    $0xc,%esp
f0102b36:	56                   	push   %esi
f0102b37:	e8 9a e4 ff ff       	call   f0100fd6 <page_free>
	return (pp - pages) << PGSHIFT;
f0102b3c:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102b42:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102b45:	2b 08                	sub    (%eax),%ecx
f0102b47:	89 c8                	mov    %ecx,%eax
f0102b49:	c1 f8 03             	sar    $0x3,%eax
f0102b4c:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102b4f:	89 c1                	mov    %eax,%ecx
f0102b51:	c1 e9 0c             	shr    $0xc,%ecx
f0102b54:	83 c4 10             	add    $0x10,%esp
f0102b57:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102b5d:	3b 0a                	cmp    (%edx),%ecx
f0102b5f:	0f 83 1f 03 00 00    	jae    f0102e84 <mem_init+0x1b26>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b65:	83 ec 04             	sub    $0x4,%esp
f0102b68:	68 00 10 00 00       	push   $0x1000
f0102b6d:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102b6f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b74:	50                   	push   %eax
f0102b75:	e8 5d 10 00 00       	call   f0103bd7 <memset>
	return (pp - pages) << PGSHIFT;
f0102b7a:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102b80:	89 f9                	mov    %edi,%ecx
f0102b82:	2b 08                	sub    (%eax),%ecx
f0102b84:	89 c8                	mov    %ecx,%eax
f0102b86:	c1 f8 03             	sar    $0x3,%eax
f0102b89:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102b8c:	89 c1                	mov    %eax,%ecx
f0102b8e:	c1 e9 0c             	shr    $0xc,%ecx
f0102b91:	83 c4 10             	add    $0x10,%esp
f0102b94:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102b9a:	3b 0a                	cmp    (%edx),%ecx
f0102b9c:	0f 83 f8 02 00 00    	jae    f0102e9a <mem_init+0x1b3c>
	memset(page2kva(pp2), 2, PGSIZE);
f0102ba2:	83 ec 04             	sub    $0x4,%esp
f0102ba5:	68 00 10 00 00       	push   $0x1000
f0102baa:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102bac:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bb1:	50                   	push   %eax
f0102bb2:	e8 20 10 00 00       	call   f0103bd7 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102bb7:	6a 02                	push   $0x2
f0102bb9:	68 00 10 00 00       	push   $0x1000
f0102bbe:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102bc1:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102bc7:	ff 30                	pushl  (%eax)
f0102bc9:	e8 fb e6 ff ff       	call   f01012c9 <page_insert>
	assert(pp1->pp_ref == 1);
f0102bce:	83 c4 20             	add    $0x20,%esp
f0102bd1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102bd4:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102bd9:	0f 85 d1 02 00 00    	jne    f0102eb0 <mem_init+0x1b52>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102bdf:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102be6:	01 01 01 
f0102be9:	0f 85 e0 02 00 00    	jne    f0102ecf <mem_init+0x1b71>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102bef:	6a 02                	push   $0x2
f0102bf1:	68 00 10 00 00       	push   $0x1000
f0102bf6:	57                   	push   %edi
f0102bf7:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102bfd:	ff 30                	pushl  (%eax)
f0102bff:	e8 c5 e6 ff ff       	call   f01012c9 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c04:	83 c4 10             	add    $0x10,%esp
f0102c07:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102c0e:	02 02 02 
f0102c11:	0f 85 d7 02 00 00    	jne    f0102eee <mem_init+0x1b90>
	assert(pp2->pp_ref == 1);
f0102c17:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c1c:	0f 85 eb 02 00 00    	jne    f0102f0d <mem_init+0x1baf>
	assert(pp1->pp_ref == 0);
f0102c22:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c25:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102c2a:	0f 85 fc 02 00 00    	jne    f0102f2c <mem_init+0x1bce>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c30:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c37:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102c3a:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102c40:	89 f9                	mov    %edi,%ecx
f0102c42:	2b 08                	sub    (%eax),%ecx
f0102c44:	89 c8                	mov    %ecx,%eax
f0102c46:	c1 f8 03             	sar    $0x3,%eax
f0102c49:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102c4c:	89 c1                	mov    %eax,%ecx
f0102c4e:	c1 e9 0c             	shr    $0xc,%ecx
f0102c51:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102c57:	3b 0a                	cmp    (%edx),%ecx
f0102c59:	0f 83 ec 02 00 00    	jae    f0102f4b <mem_init+0x1bed>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c5f:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c66:	03 03 03 
f0102c69:	0f 85 f2 02 00 00    	jne    f0102f61 <mem_init+0x1c03>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c6f:	83 ec 08             	sub    $0x8,%esp
f0102c72:	68 00 10 00 00       	push   $0x1000
f0102c77:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102c7d:	ff 30                	pushl  (%eax)
f0102c7f:	e8 0a e6 ff ff       	call   f010128e <page_remove>
	assert(pp2->pp_ref == 0);
f0102c84:	83 c4 10             	add    $0x10,%esp
f0102c87:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102c8c:	0f 85 ee 02 00 00    	jne    f0102f80 <mem_init+0x1c22>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c92:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102c98:	8b 08                	mov    (%eax),%ecx
f0102c9a:	8b 11                	mov    (%ecx),%edx
f0102c9c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102ca2:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102ca8:	89 f7                	mov    %esi,%edi
f0102caa:	2b 38                	sub    (%eax),%edi
f0102cac:	89 f8                	mov    %edi,%eax
f0102cae:	c1 f8 03             	sar    $0x3,%eax
f0102cb1:	c1 e0 0c             	shl    $0xc,%eax
f0102cb4:	39 c2                	cmp    %eax,%edx
f0102cb6:	0f 85 e3 02 00 00    	jne    f0102f9f <mem_init+0x1c41>
	kern_pgdir[0] = 0;
f0102cbc:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102cc2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102cc7:	0f 85 f1 02 00 00    	jne    f0102fbe <mem_init+0x1c60>
	pp0->pp_ref = 0;
f0102ccd:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102cd3:	83 ec 0c             	sub    $0xc,%esp
f0102cd6:	56                   	push   %esi
f0102cd7:	e8 fa e2 ff ff       	call   f0100fd6 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102cdc:	8d 83 00 dc fe ff    	lea    -0x12400(%ebx),%eax
f0102ce2:	89 04 24             	mov    %eax,(%esp)
f0102ce5:	e8 91 03 00 00       	call   f010307b <cprintf>
	cprintf("Page table index at Linear Address 0xffffffff: %d\n", PDX(0xffffffff));        // Top most hex address
f0102cea:	83 c4 08             	add    $0x8,%esp
f0102ced:	68 ff 03 00 00       	push   $0x3ff
f0102cf2:	8d 83 2c dc fe ff    	lea    -0x123d4(%ebx),%eax
f0102cf8:	50                   	push   %eax
f0102cf9:	e8 7d 03 00 00       	call   f010307b <cprintf>
	cprintf("Page table index at Linear Address 0xffc00000: %d\n", PDX(0xffc00000));        // Last hex address in Page Dir Entry #1023
f0102cfe:	83 c4 08             	add    $0x8,%esp
f0102d01:	68 ff 03 00 00       	push   $0x3ff
f0102d06:	8d 83 60 dc fe ff    	lea    -0x123a0(%ebx),%eax
f0102d0c:	50                   	push   %eax
f0102d0d:	e8 69 03 00 00       	call   f010307b <cprintf>
	cprintf("Page table index at Linear Address 0xffbfffff: %d\n", PDX(0xffbfffff));        // First hex address in Page Dir Entry #1022
f0102d12:	83 c4 08             	add    $0x8,%esp
f0102d15:	68 fe 03 00 00       	push   $0x3fe
f0102d1a:	8d 83 94 dc fe ff    	lea    -0x1236c(%ebx),%eax
f0102d20:	50                   	push   %eax
f0102d21:	e8 55 03 00 00       	call   f010307b <cprintf>
	cprintf("Page table index at Linear Address 0xff800000: %d\n", PDX(0xff800000));        // Last hex address in Page Dir Entry #1022
f0102d26:	83 c4 08             	add    $0x8,%esp
f0102d29:	68 fe 03 00 00       	push   $0x3fe
f0102d2e:	8d 83 c8 dc fe ff    	lea    -0x12338(%ebx),%eax
f0102d34:	50                   	push   %eax
f0102d35:	e8 41 03 00 00       	call   f010307b <cprintf>
 	cprintf("Page table index at Linear Address 0xff7fffff: %d\n", PDX(0xff7fffff));        // First hex address in Page Dir Entry #1021
f0102d3a:	83 c4 08             	add    $0x8,%esp
f0102d3d:	68 fd 03 00 00       	push   $0x3fd
f0102d42:	8d 83 fc dc fe ff    	lea    -0x12304(%ebx),%eax
f0102d48:	50                   	push   %eax
f0102d49:	e8 2d 03 00 00       	call   f010307b <cprintf>
	cprintf("Page table index at Linear Address 0xf0000000/KERNBASE: %d\n", PDX(KERNBASE)); // Kernbase hex address
f0102d4e:	83 c4 08             	add    $0x8,%esp
f0102d51:	68 c0 03 00 00       	push   $0x3c0
f0102d56:	8d 83 30 dd fe ff    	lea    -0x122d0(%ebx),%eax
f0102d5c:	50                   	push   %eax
f0102d5d:	e8 19 03 00 00       	call   f010307b <cprintf>
	cprintf("Page table index at Linear Address kern_pgdir: %d\n", PDX(kern_pgdir));        // kern_pgdir hex address
f0102d62:	83 c4 08             	add    $0x8,%esp
f0102d65:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102d6b:	8b 00                	mov    (%eax),%eax
f0102d6d:	c1 e8 16             	shr    $0x16,%eax
f0102d70:	50                   	push   %eax
f0102d71:	8d 83 6c dd fe ff    	lea    -0x12294(%ebx),%eax
f0102d77:	50                   	push   %eax
f0102d78:	e8 fe 02 00 00       	call   f010307b <cprintf>
	cprintf("Page table index at Linear Address MMIOLIM: %d\n", PDX(MMIOLIM));                  
f0102d7d:	83 c4 08             	add    $0x8,%esp
f0102d80:	68 bf 03 00 00       	push   $0x3bf
f0102d85:	8d 83 a0 dd fe ff    	lea    -0x12260(%ebx),%eax
f0102d8b:	50                   	push   %eax
f0102d8c:	e8 ea 02 00 00       	call   f010307b <cprintf>
	cprintf("Page table index at Linear Address MMIOBASE: %d\n", PDX(MMIOBASE));                 
f0102d91:	83 c4 08             	add    $0x8,%esp
f0102d94:	68 be 03 00 00       	push   $0x3be
f0102d99:	8d 83 d0 dd fe ff    	lea    -0x12230(%ebx),%eax
f0102d9f:	50                   	push   %eax
f0102da0:	e8 d6 02 00 00       	call   f010307b <cprintf>
	cprintf("Page table index at Linear Address UVPT: %d\n", PDX(UVPT));                  
f0102da5:	83 c4 08             	add    $0x8,%esp
f0102da8:	68 bd 03 00 00       	push   $0x3bd
f0102dad:	8d 83 04 de fe ff    	lea    -0x121fc(%ebx),%eax
f0102db3:	50                   	push   %eax
f0102db4:	e8 c2 02 00 00       	call   f010307b <cprintf>
	cprintf("Page table index at Linear Address UPAGES: %d\n", PDX(UPAGES));                 
f0102db9:	83 c4 08             	add    $0x8,%esp
f0102dbc:	68 bc 03 00 00       	push   $0x3bc
f0102dc1:	8d 83 34 de fe ff    	lea    -0x121cc(%ebx),%eax
f0102dc7:	50                   	push   %eax
f0102dc8:	e8 ae 02 00 00       	call   f010307b <cprintf>
	cprintf("Page table index at Linear Address KSTACKTOP: %d\n", PDX(KSTACKTOP));   
f0102dcd:	83 c4 08             	add    $0x8,%esp
f0102dd0:	68 c0 03 00 00       	push   $0x3c0
f0102dd5:	8d 83 64 de fe ff    	lea    -0x1219c(%ebx),%eax
f0102ddb:	50                   	push   %eax
f0102ddc:	e8 9a 02 00 00       	call   f010307b <cprintf>
	cprintf("Page table index at Linear Address IOPHYSMEM: %d\n", PDX(IOPHYSMEM));                  
f0102de1:	83 c4 08             	add    $0x8,%esp
f0102de4:	6a 00                	push   $0x0
f0102de6:	8d 83 98 de fe ff    	lea    -0x12168(%ebx),%eax
f0102dec:	50                   	push   %eax
f0102ded:	e8 89 02 00 00       	call   f010307b <cprintf>
	cprintf("Page table index at Linear Address EXTPHYSMEM: %d\n", PDX(EXTPHYSMEM));
f0102df2:	83 c4 08             	add    $0x8,%esp
f0102df5:	6a 00                	push   $0x0
f0102df7:	8d 83 cc de fe ff    	lea    -0x12134(%ebx),%eax
f0102dfd:	50                   	push   %eax
f0102dfe:	e8 78 02 00 00       	call   f010307b <cprintf>
}
f0102e03:	83 c4 10             	add    $0x10,%esp
f0102e06:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e09:	5b                   	pop    %ebx
f0102e0a:	5e                   	pop    %esi
f0102e0b:	5f                   	pop    %edi
f0102e0c:	5d                   	pop    %ebp
f0102e0d:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e0e:	50                   	push   %eax
f0102e0f:	8d 83 1c d6 fe ff    	lea    -0x129e4(%ebx),%eax
f0102e15:	50                   	push   %eax
f0102e16:	68 0f 01 00 00       	push   $0x10f
f0102e1b:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102e21:	50                   	push   %eax
f0102e22:	e8 72 d2 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102e27:	8d 83 9f d2 fe ff    	lea    -0x12d61(%ebx),%eax
f0102e2d:	50                   	push   %eax
f0102e2e:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102e34:	50                   	push   %eax
f0102e35:	68 85 04 00 00       	push   $0x485
f0102e3a:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102e40:	50                   	push   %eax
f0102e41:	e8 53 d2 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102e46:	8d 83 b5 d2 fe ff    	lea    -0x12d4b(%ebx),%eax
f0102e4c:	50                   	push   %eax
f0102e4d:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102e53:	50                   	push   %eax
f0102e54:	68 86 04 00 00       	push   $0x486
f0102e59:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102e5f:	50                   	push   %eax
f0102e60:	e8 34 d2 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102e65:	8d 83 cb d2 fe ff    	lea    -0x12d35(%ebx),%eax
f0102e6b:	50                   	push   %eax
f0102e6c:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102e72:	50                   	push   %eax
f0102e73:	68 87 04 00 00       	push   $0x487
f0102e78:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102e7e:	50                   	push   %eax
f0102e7f:	e8 15 d2 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e84:	50                   	push   %eax
f0102e85:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f0102e8b:	50                   	push   %eax
f0102e8c:	6a 52                	push   $0x52
f0102e8e:	8d 83 94 d1 fe ff    	lea    -0x12e6c(%ebx),%eax
f0102e94:	50                   	push   %eax
f0102e95:	e8 ff d1 ff ff       	call   f0100099 <_panic>
f0102e9a:	50                   	push   %eax
f0102e9b:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f0102ea1:	50                   	push   %eax
f0102ea2:	6a 52                	push   $0x52
f0102ea4:	8d 83 94 d1 fe ff    	lea    -0x12e6c(%ebx),%eax
f0102eaa:	50                   	push   %eax
f0102eab:	e8 e9 d1 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102eb0:	8d 83 9c d3 fe ff    	lea    -0x12c64(%ebx),%eax
f0102eb6:	50                   	push   %eax
f0102eb7:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102ebd:	50                   	push   %eax
f0102ebe:	68 8c 04 00 00       	push   $0x48c
f0102ec3:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102ec9:	50                   	push   %eax
f0102eca:	e8 ca d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ecf:	8d 83 8c db fe ff    	lea    -0x12474(%ebx),%eax
f0102ed5:	50                   	push   %eax
f0102ed6:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102edc:	50                   	push   %eax
f0102edd:	68 8d 04 00 00       	push   $0x48d
f0102ee2:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102ee8:	50                   	push   %eax
f0102ee9:	e8 ab d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102eee:	8d 83 b0 db fe ff    	lea    -0x12450(%ebx),%eax
f0102ef4:	50                   	push   %eax
f0102ef5:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102efb:	50                   	push   %eax
f0102efc:	68 8f 04 00 00       	push   $0x48f
f0102f01:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102f07:	50                   	push   %eax
f0102f08:	e8 8c d1 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102f0d:	8d 83 be d3 fe ff    	lea    -0x12c42(%ebx),%eax
f0102f13:	50                   	push   %eax
f0102f14:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102f1a:	50                   	push   %eax
f0102f1b:	68 90 04 00 00       	push   $0x490
f0102f20:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102f26:	50                   	push   %eax
f0102f27:	e8 6d d1 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102f2c:	8d 83 28 d4 fe ff    	lea    -0x12bd8(%ebx),%eax
f0102f32:	50                   	push   %eax
f0102f33:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102f39:	50                   	push   %eax
f0102f3a:	68 91 04 00 00       	push   $0x491
f0102f3f:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102f45:	50                   	push   %eax
f0102f46:	e8 4e d1 ff ff       	call   f0100099 <_panic>
f0102f4b:	50                   	push   %eax
f0102f4c:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f0102f52:	50                   	push   %eax
f0102f53:	6a 52                	push   $0x52
f0102f55:	8d 83 94 d1 fe ff    	lea    -0x12e6c(%ebx),%eax
f0102f5b:	50                   	push   %eax
f0102f5c:	e8 38 d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102f61:	8d 83 d4 db fe ff    	lea    -0x1242c(%ebx),%eax
f0102f67:	50                   	push   %eax
f0102f68:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102f6e:	50                   	push   %eax
f0102f6f:	68 93 04 00 00       	push   $0x493
f0102f74:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102f7a:	50                   	push   %eax
f0102f7b:	e8 19 d1 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102f80:	8d 83 f6 d3 fe ff    	lea    -0x12c0a(%ebx),%eax
f0102f86:	50                   	push   %eax
f0102f87:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102f8d:	50                   	push   %eax
f0102f8e:	68 95 04 00 00       	push   $0x495
f0102f93:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102f99:	50                   	push   %eax
f0102f9a:	e8 fa d0 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102f9f:	8d 83 18 d7 fe ff    	lea    -0x128e8(%ebx),%eax
f0102fa5:	50                   	push   %eax
f0102fa6:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102fac:	50                   	push   %eax
f0102fad:	68 98 04 00 00       	push   $0x498
f0102fb2:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102fb8:	50                   	push   %eax
f0102fb9:	e8 db d0 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102fbe:	8d 83 ad d3 fe ff    	lea    -0x12c53(%ebx),%eax
f0102fc4:	50                   	push   %eax
f0102fc5:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f0102fcb:	50                   	push   %eax
f0102fcc:	68 9a 04 00 00       	push   $0x49a
f0102fd1:	8d 83 88 d1 fe ff    	lea    -0x12e78(%ebx),%eax
f0102fd7:	50                   	push   %eax
f0102fd8:	e8 bc d0 ff ff       	call   f0100099 <_panic>

f0102fdd <tlb_invalidate>:
{
f0102fdd:	55                   	push   %ebp
f0102fde:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102fe0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fe3:	0f 01 38             	invlpg (%eax)
}
f0102fe6:	5d                   	pop    %ebp
f0102fe7:	c3                   	ret    

f0102fe8 <__x86.get_pc_thunk.cx>:
f0102fe8:	8b 0c 24             	mov    (%esp),%ecx
f0102feb:	c3                   	ret    

f0102fec <__x86.get_pc_thunk.si>:
f0102fec:	8b 34 24             	mov    (%esp),%esi
f0102fef:	c3                   	ret    

f0102ff0 <__x86.get_pc_thunk.di>:
f0102ff0:	8b 3c 24             	mov    (%esp),%edi
f0102ff3:	c3                   	ret    

f0102ff4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102ff4:	55                   	push   %ebp
f0102ff5:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ff7:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ffa:	ba 70 00 00 00       	mov    $0x70,%edx
f0102fff:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103000:	ba 71 00 00 00       	mov    $0x71,%edx
f0103005:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103006:	0f b6 c0             	movzbl %al,%eax
}
f0103009:	5d                   	pop    %ebp
f010300a:	c3                   	ret    

f010300b <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010300b:	55                   	push   %ebp
f010300c:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010300e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103011:	ba 70 00 00 00       	mov    $0x70,%edx
f0103016:	ee                   	out    %al,(%dx)
f0103017:	8b 45 0c             	mov    0xc(%ebp),%eax
f010301a:	ba 71 00 00 00       	mov    $0x71,%edx
f010301f:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103020:	5d                   	pop    %ebp
f0103021:	c3                   	ret    

f0103022 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103022:	55                   	push   %ebp
f0103023:	89 e5                	mov    %esp,%ebp
f0103025:	53                   	push   %ebx
f0103026:	83 ec 10             	sub    $0x10,%esp
f0103029:	e8 21 d1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010302e:	81 c3 da 42 01 00    	add    $0x142da,%ebx
	cputchar(ch);
f0103034:	ff 75 08             	pushl  0x8(%ebp)
f0103037:	e8 8a d6 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f010303c:	83 c4 10             	add    $0x10,%esp
f010303f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103042:	c9                   	leave  
f0103043:	c3                   	ret    

f0103044 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103044:	55                   	push   %ebp
f0103045:	89 e5                	mov    %esp,%ebp
f0103047:	53                   	push   %ebx
f0103048:	83 ec 14             	sub    $0x14,%esp
f010304b:	e8 ff d0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103050:	81 c3 b8 42 01 00    	add    $0x142b8,%ebx
	int cnt = 0;
f0103056:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010305d:	ff 75 0c             	pushl  0xc(%ebp)
f0103060:	ff 75 08             	pushl  0x8(%ebp)
f0103063:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103066:	50                   	push   %eax
f0103067:	8d 83 1a bd fe ff    	lea    -0x142e6(%ebx),%eax
f010306d:	50                   	push   %eax
f010306e:	e8 18 04 00 00       	call   f010348b <vprintfmt>
	return cnt;
}
f0103073:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103076:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103079:	c9                   	leave  
f010307a:	c3                   	ret    

f010307b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010307b:	55                   	push   %ebp
f010307c:	89 e5                	mov    %esp,%ebp
f010307e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103081:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103084:	50                   	push   %eax
f0103085:	ff 75 08             	pushl  0x8(%ebp)
f0103088:	e8 b7 ff ff ff       	call   f0103044 <vcprintf>
	va_end(ap);

	return cnt;
}
f010308d:	c9                   	leave  
f010308e:	c3                   	ret    

f010308f <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010308f:	55                   	push   %ebp
f0103090:	89 e5                	mov    %esp,%ebp
f0103092:	57                   	push   %edi
f0103093:	56                   	push   %esi
f0103094:	53                   	push   %ebx
f0103095:	83 ec 14             	sub    $0x14,%esp
f0103098:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010309b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010309e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01030a1:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01030a4:	8b 32                	mov    (%edx),%esi
f01030a6:	8b 01                	mov    (%ecx),%eax
f01030a8:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01030ab:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01030b2:	eb 2f                	jmp    f01030e3 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01030b4:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f01030b7:	39 c6                	cmp    %eax,%esi
f01030b9:	7f 49                	jg     f0103104 <stab_binsearch+0x75>
f01030bb:	0f b6 0a             	movzbl (%edx),%ecx
f01030be:	83 ea 0c             	sub    $0xc,%edx
f01030c1:	39 f9                	cmp    %edi,%ecx
f01030c3:	75 ef                	jne    f01030b4 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01030c5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01030c8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01030cb:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01030cf:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01030d2:	73 35                	jae    f0103109 <stab_binsearch+0x7a>
			*region_left = m;
f01030d4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01030d7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f01030d9:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f01030dc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01030e3:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f01030e6:	7f 4e                	jg     f0103136 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f01030e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01030eb:	01 f0                	add    %esi,%eax
f01030ed:	89 c3                	mov    %eax,%ebx
f01030ef:	c1 eb 1f             	shr    $0x1f,%ebx
f01030f2:	01 c3                	add    %eax,%ebx
f01030f4:	d1 fb                	sar    %ebx
f01030f6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01030f9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01030fc:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0103100:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0103102:	eb b3                	jmp    f01030b7 <stab_binsearch+0x28>
			l = true_m + 1;
f0103104:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0103107:	eb da                	jmp    f01030e3 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0103109:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010310c:	76 14                	jbe    f0103122 <stab_binsearch+0x93>
			*region_right = m - 1;
f010310e:	83 e8 01             	sub    $0x1,%eax
f0103111:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103114:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103117:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0103119:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103120:	eb c1                	jmp    f01030e3 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103122:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103125:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103127:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010312b:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f010312d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103134:	eb ad                	jmp    f01030e3 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0103136:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010313a:	74 16                	je     f0103152 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010313c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010313f:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103141:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103144:	8b 0e                	mov    (%esi),%ecx
f0103146:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103149:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010314c:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0103150:	eb 12                	jmp    f0103164 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0103152:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103155:	8b 00                	mov    (%eax),%eax
f0103157:	83 e8 01             	sub    $0x1,%eax
f010315a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010315d:	89 07                	mov    %eax,(%edi)
f010315f:	eb 16                	jmp    f0103177 <stab_binsearch+0xe8>
		     l--)
f0103161:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0103164:	39 c1                	cmp    %eax,%ecx
f0103166:	7d 0a                	jge    f0103172 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0103168:	0f b6 1a             	movzbl (%edx),%ebx
f010316b:	83 ea 0c             	sub    $0xc,%edx
f010316e:	39 fb                	cmp    %edi,%ebx
f0103170:	75 ef                	jne    f0103161 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0103172:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103175:	89 07                	mov    %eax,(%edi)
	}
}
f0103177:	83 c4 14             	add    $0x14,%esp
f010317a:	5b                   	pop    %ebx
f010317b:	5e                   	pop    %esi
f010317c:	5f                   	pop    %edi
f010317d:	5d                   	pop    %ebp
f010317e:	c3                   	ret    

f010317f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010317f:	55                   	push   %ebp
f0103180:	89 e5                	mov    %esp,%ebp
f0103182:	57                   	push   %edi
f0103183:	56                   	push   %esi
f0103184:	53                   	push   %ebx
f0103185:	83 ec 2c             	sub    $0x2c,%esp
f0103188:	e8 5b fe ff ff       	call   f0102fe8 <__x86.get_pc_thunk.cx>
f010318d:	81 c1 7b 41 01 00    	add    $0x1417b,%ecx
f0103193:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0103196:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103199:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010319c:	8d 81 00 df fe ff    	lea    -0x12100(%ecx),%eax
f01031a2:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f01031a4:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f01031ab:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f01031ae:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f01031b5:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f01031b8:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01031bf:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01031c5:	0f 86 f4 00 00 00    	jbe    f01032bf <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01031cb:	c7 c0 f1 bc 10 f0    	mov    $0xf010bcf1,%eax
f01031d1:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f01031d7:	0f 86 88 01 00 00    	jbe    f0103365 <debuginfo_eip+0x1e6>
f01031dd:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01031e0:	c7 c0 4d db 10 f0    	mov    $0xf010db4d,%eax
f01031e6:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01031ea:	0f 85 7c 01 00 00    	jne    f010336c <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01031f0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01031f7:	c7 c0 20 54 10 f0    	mov    $0xf0105420,%eax
f01031fd:	c7 c2 f0 bc 10 f0    	mov    $0xf010bcf0,%edx
f0103203:	29 c2                	sub    %eax,%edx
f0103205:	c1 fa 02             	sar    $0x2,%edx
f0103208:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010320e:	83 ea 01             	sub    $0x1,%edx
f0103211:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103214:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103217:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010321a:	83 ec 08             	sub    $0x8,%esp
f010321d:	53                   	push   %ebx
f010321e:	6a 64                	push   $0x64
f0103220:	e8 6a fe ff ff       	call   f010308f <stab_binsearch>
	if (lfile == 0)
f0103225:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103228:	83 c4 10             	add    $0x10,%esp
f010322b:	85 c0                	test   %eax,%eax
f010322d:	0f 84 40 01 00 00    	je     f0103373 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103233:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103236:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103239:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010323c:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010323f:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103242:	83 ec 08             	sub    $0x8,%esp
f0103245:	53                   	push   %ebx
f0103246:	6a 24                	push   $0x24
f0103248:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010324b:	c7 c0 20 54 10 f0    	mov    $0xf0105420,%eax
f0103251:	e8 39 fe ff ff       	call   f010308f <stab_binsearch>

	if (lfun <= rfun) {
f0103256:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103259:	83 c4 10             	add    $0x10,%esp
f010325c:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f010325f:	7f 79                	jg     f01032da <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103261:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103264:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103267:	c7 c2 20 54 10 f0    	mov    $0xf0105420,%edx
f010326d:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0103270:	8b 11                	mov    (%ecx),%edx
f0103272:	c7 c0 4d db 10 f0    	mov    $0xf010db4d,%eax
f0103278:	81 e8 f1 bc 10 f0    	sub    $0xf010bcf1,%eax
f010327e:	39 c2                	cmp    %eax,%edx
f0103280:	73 09                	jae    f010328b <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103282:	81 c2 f1 bc 10 f0    	add    $0xf010bcf1,%edx
f0103288:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010328b:	8b 41 08             	mov    0x8(%ecx),%eax
f010328e:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103291:	83 ec 08             	sub    $0x8,%esp
f0103294:	6a 3a                	push   $0x3a
f0103296:	ff 77 08             	pushl  0x8(%edi)
f0103299:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010329c:	e8 1a 09 00 00       	call   f0103bbb <strfind>
f01032a1:	2b 47 08             	sub    0x8(%edi),%eax
f01032a4:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01032a7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01032aa:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01032ad:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01032b0:	c7 c2 20 54 10 f0    	mov    $0xf0105420,%edx
f01032b6:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f01032ba:	83 c4 10             	add    $0x10,%esp
f01032bd:	eb 29                	jmp    f01032e8 <debuginfo_eip+0x169>
  	        panic("User address");
f01032bf:	83 ec 04             	sub    $0x4,%esp
f01032c2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01032c5:	8d 83 0a df fe ff    	lea    -0x120f6(%ebx),%eax
f01032cb:	50                   	push   %eax
f01032cc:	6a 7f                	push   $0x7f
f01032ce:	8d 83 17 df fe ff    	lea    -0x120e9(%ebx),%eax
f01032d4:	50                   	push   %eax
f01032d5:	e8 bf cd ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f01032da:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f01032dd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01032e0:	eb af                	jmp    f0103291 <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01032e2:	83 ee 01             	sub    $0x1,%esi
f01032e5:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f01032e8:	39 f3                	cmp    %esi,%ebx
f01032ea:	7f 3a                	jg     f0103326 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f01032ec:	0f b6 10             	movzbl (%eax),%edx
f01032ef:	80 fa 84             	cmp    $0x84,%dl
f01032f2:	74 0b                	je     f01032ff <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01032f4:	80 fa 64             	cmp    $0x64,%dl
f01032f7:	75 e9                	jne    f01032e2 <debuginfo_eip+0x163>
f01032f9:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f01032fd:	74 e3                	je     f01032e2 <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01032ff:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0103302:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103305:	c7 c0 20 54 10 f0    	mov    $0xf0105420,%eax
f010330b:	8b 14 90             	mov    (%eax,%edx,4),%edx
f010330e:	c7 c0 4d db 10 f0    	mov    $0xf010db4d,%eax
f0103314:	81 e8 f1 bc 10 f0    	sub    $0xf010bcf1,%eax
f010331a:	39 c2                	cmp    %eax,%edx
f010331c:	73 08                	jae    f0103326 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010331e:	81 c2 f1 bc 10 f0    	add    $0xf010bcf1,%edx
f0103324:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103326:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103329:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010332c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0103331:	39 cb                	cmp    %ecx,%ebx
f0103333:	7d 4a                	jge    f010337f <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0103335:	8d 53 01             	lea    0x1(%ebx),%edx
f0103338:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f010333b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010333e:	c7 c0 20 54 10 f0    	mov    $0xf0105420,%eax
f0103344:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0103348:	eb 07                	jmp    f0103351 <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f010334a:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f010334e:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0103351:	39 d1                	cmp    %edx,%ecx
f0103353:	74 25                	je     f010337a <debuginfo_eip+0x1fb>
f0103355:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103358:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f010335c:	74 ec                	je     f010334a <debuginfo_eip+0x1cb>
	return 0;
f010335e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103363:	eb 1a                	jmp    f010337f <debuginfo_eip+0x200>
		return -1;
f0103365:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010336a:	eb 13                	jmp    f010337f <debuginfo_eip+0x200>
f010336c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103371:	eb 0c                	jmp    f010337f <debuginfo_eip+0x200>
		return -1;
f0103373:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103378:	eb 05                	jmp    f010337f <debuginfo_eip+0x200>
	return 0;
f010337a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010337f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103382:	5b                   	pop    %ebx
f0103383:	5e                   	pop    %esi
f0103384:	5f                   	pop    %edi
f0103385:	5d                   	pop    %ebp
f0103386:	c3                   	ret    

f0103387 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103387:	55                   	push   %ebp
f0103388:	89 e5                	mov    %esp,%ebp
f010338a:	57                   	push   %edi
f010338b:	56                   	push   %esi
f010338c:	53                   	push   %ebx
f010338d:	83 ec 2c             	sub    $0x2c,%esp
f0103390:	e8 53 fc ff ff       	call   f0102fe8 <__x86.get_pc_thunk.cx>
f0103395:	81 c1 73 3f 01 00    	add    $0x13f73,%ecx
f010339b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010339e:	89 c7                	mov    %eax,%edi
f01033a0:	89 d6                	mov    %edx,%esi
f01033a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01033a5:	8b 55 0c             	mov    0xc(%ebp),%edx
f01033a8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01033ab:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01033ae:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01033b1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01033b6:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f01033b9:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01033bc:	39 d3                	cmp    %edx,%ebx
f01033be:	72 09                	jb     f01033c9 <printnum+0x42>
f01033c0:	39 45 10             	cmp    %eax,0x10(%ebp)
f01033c3:	0f 87 83 00 00 00    	ja     f010344c <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01033c9:	83 ec 0c             	sub    $0xc,%esp
f01033cc:	ff 75 18             	pushl  0x18(%ebp)
f01033cf:	8b 45 14             	mov    0x14(%ebp),%eax
f01033d2:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01033d5:	53                   	push   %ebx
f01033d6:	ff 75 10             	pushl  0x10(%ebp)
f01033d9:	83 ec 08             	sub    $0x8,%esp
f01033dc:	ff 75 dc             	pushl  -0x24(%ebp)
f01033df:	ff 75 d8             	pushl  -0x28(%ebp)
f01033e2:	ff 75 d4             	pushl  -0x2c(%ebp)
f01033e5:	ff 75 d0             	pushl  -0x30(%ebp)
f01033e8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01033eb:	e8 f0 09 00 00       	call   f0103de0 <__udivdi3>
f01033f0:	83 c4 18             	add    $0x18,%esp
f01033f3:	52                   	push   %edx
f01033f4:	50                   	push   %eax
f01033f5:	89 f2                	mov    %esi,%edx
f01033f7:	89 f8                	mov    %edi,%eax
f01033f9:	e8 89 ff ff ff       	call   f0103387 <printnum>
f01033fe:	83 c4 20             	add    $0x20,%esp
f0103401:	eb 13                	jmp    f0103416 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103403:	83 ec 08             	sub    $0x8,%esp
f0103406:	56                   	push   %esi
f0103407:	ff 75 18             	pushl  0x18(%ebp)
f010340a:	ff d7                	call   *%edi
f010340c:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f010340f:	83 eb 01             	sub    $0x1,%ebx
f0103412:	85 db                	test   %ebx,%ebx
f0103414:	7f ed                	jg     f0103403 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103416:	83 ec 08             	sub    $0x8,%esp
f0103419:	56                   	push   %esi
f010341a:	83 ec 04             	sub    $0x4,%esp
f010341d:	ff 75 dc             	pushl  -0x24(%ebp)
f0103420:	ff 75 d8             	pushl  -0x28(%ebp)
f0103423:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103426:	ff 75 d0             	pushl  -0x30(%ebp)
f0103429:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010342c:	89 f3                	mov    %esi,%ebx
f010342e:	e8 cd 0a 00 00       	call   f0103f00 <__umoddi3>
f0103433:	83 c4 14             	add    $0x14,%esp
f0103436:	0f be 84 06 25 df fe 	movsbl -0x120db(%esi,%eax,1),%eax
f010343d:	ff 
f010343e:	50                   	push   %eax
f010343f:	ff d7                	call   *%edi
}
f0103441:	83 c4 10             	add    $0x10,%esp
f0103444:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103447:	5b                   	pop    %ebx
f0103448:	5e                   	pop    %esi
f0103449:	5f                   	pop    %edi
f010344a:	5d                   	pop    %ebp
f010344b:	c3                   	ret    
f010344c:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010344f:	eb be                	jmp    f010340f <printnum+0x88>

f0103451 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103451:	55                   	push   %ebp
f0103452:	89 e5                	mov    %esp,%ebp
f0103454:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103457:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010345b:	8b 10                	mov    (%eax),%edx
f010345d:	3b 50 04             	cmp    0x4(%eax),%edx
f0103460:	73 0a                	jae    f010346c <sprintputch+0x1b>
		*b->buf++ = ch;
f0103462:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103465:	89 08                	mov    %ecx,(%eax)
f0103467:	8b 45 08             	mov    0x8(%ebp),%eax
f010346a:	88 02                	mov    %al,(%edx)
}
f010346c:	5d                   	pop    %ebp
f010346d:	c3                   	ret    

f010346e <printfmt>:
{
f010346e:	55                   	push   %ebp
f010346f:	89 e5                	mov    %esp,%ebp
f0103471:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0103474:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103477:	50                   	push   %eax
f0103478:	ff 75 10             	pushl  0x10(%ebp)
f010347b:	ff 75 0c             	pushl  0xc(%ebp)
f010347e:	ff 75 08             	pushl  0x8(%ebp)
f0103481:	e8 05 00 00 00       	call   f010348b <vprintfmt>
}
f0103486:	83 c4 10             	add    $0x10,%esp
f0103489:	c9                   	leave  
f010348a:	c3                   	ret    

f010348b <vprintfmt>:
{
f010348b:	55                   	push   %ebp
f010348c:	89 e5                	mov    %esp,%ebp
f010348e:	57                   	push   %edi
f010348f:	56                   	push   %esi
f0103490:	53                   	push   %ebx
f0103491:	83 ec 2c             	sub    $0x2c,%esp
f0103494:	e8 b6 cc ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103499:	81 c3 6f 3e 01 00    	add    $0x13e6f,%ebx
f010349f:	8b 75 0c             	mov    0xc(%ebp),%esi
f01034a2:	8b 7d 10             	mov    0x10(%ebp),%edi
f01034a5:	e9 8e 03 00 00       	jmp    f0103838 <.L35+0x48>
		padc = ' ';
f01034aa:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01034ae:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01034b5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f01034bc:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01034c3:	b9 00 00 00 00       	mov    $0x0,%ecx
f01034c8:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01034cb:	8d 47 01             	lea    0x1(%edi),%eax
f01034ce:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01034d1:	0f b6 17             	movzbl (%edi),%edx
f01034d4:	8d 42 dd             	lea    -0x23(%edx),%eax
f01034d7:	3c 55                	cmp    $0x55,%al
f01034d9:	0f 87 e1 03 00 00    	ja     f01038c0 <.L22>
f01034df:	0f b6 c0             	movzbl %al,%eax
f01034e2:	89 d9                	mov    %ebx,%ecx
f01034e4:	03 8c 83 b0 df fe ff 	add    -0x12050(%ebx,%eax,4),%ecx
f01034eb:	ff e1                	jmp    *%ecx

f01034ed <.L67>:
f01034ed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01034f0:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01034f4:	eb d5                	jmp    f01034cb <vprintfmt+0x40>

f01034f6 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f01034f6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f01034f9:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01034fd:	eb cc                	jmp    f01034cb <vprintfmt+0x40>

f01034ff <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f01034ff:	0f b6 d2             	movzbl %dl,%edx
f0103502:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0103505:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f010350a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010350d:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103511:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103514:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103517:	83 f9 09             	cmp    $0x9,%ecx
f010351a:	77 55                	ja     f0103571 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f010351c:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010351f:	eb e9                	jmp    f010350a <.L29+0xb>

f0103521 <.L26>:
			precision = va_arg(ap, int);
f0103521:	8b 45 14             	mov    0x14(%ebp),%eax
f0103524:	8b 00                	mov    (%eax),%eax
f0103526:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103529:	8b 45 14             	mov    0x14(%ebp),%eax
f010352c:	8d 40 04             	lea    0x4(%eax),%eax
f010352f:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103532:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0103535:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103539:	79 90                	jns    f01034cb <vprintfmt+0x40>
				width = precision, precision = -1;
f010353b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010353e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103541:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103548:	eb 81                	jmp    f01034cb <vprintfmt+0x40>

f010354a <.L27>:
f010354a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010354d:	85 c0                	test   %eax,%eax
f010354f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103554:	0f 49 d0             	cmovns %eax,%edx
f0103557:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010355a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010355d:	e9 69 ff ff ff       	jmp    f01034cb <vprintfmt+0x40>

f0103562 <.L23>:
f0103562:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0103565:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010356c:	e9 5a ff ff ff       	jmp    f01034cb <vprintfmt+0x40>
f0103571:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103574:	eb bf                	jmp    f0103535 <.L26+0x14>

f0103576 <.L33>:
			lflag++;
f0103576:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010357a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010357d:	e9 49 ff ff ff       	jmp    f01034cb <vprintfmt+0x40>

f0103582 <.L30>:
			putch(va_arg(ap, int), putdat);
f0103582:	8b 45 14             	mov    0x14(%ebp),%eax
f0103585:	8d 78 04             	lea    0x4(%eax),%edi
f0103588:	83 ec 08             	sub    $0x8,%esp
f010358b:	56                   	push   %esi
f010358c:	ff 30                	pushl  (%eax)
f010358e:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103591:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103594:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0103597:	e9 99 02 00 00       	jmp    f0103835 <.L35+0x45>

f010359c <.L32>:
			err = va_arg(ap, int);
f010359c:	8b 45 14             	mov    0x14(%ebp),%eax
f010359f:	8d 78 04             	lea    0x4(%eax),%edi
f01035a2:	8b 00                	mov    (%eax),%eax
f01035a4:	99                   	cltd   
f01035a5:	31 d0                	xor    %edx,%eax
f01035a7:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01035a9:	83 f8 06             	cmp    $0x6,%eax
f01035ac:	7f 27                	jg     f01035d5 <.L32+0x39>
f01035ae:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f01035b5:	85 d2                	test   %edx,%edx
f01035b7:	74 1c                	je     f01035d5 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01035b9:	52                   	push   %edx
f01035ba:	8d 83 c0 d1 fe ff    	lea    -0x12e40(%ebx),%eax
f01035c0:	50                   	push   %eax
f01035c1:	56                   	push   %esi
f01035c2:	ff 75 08             	pushl  0x8(%ebp)
f01035c5:	e8 a4 fe ff ff       	call   f010346e <printfmt>
f01035ca:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01035cd:	89 7d 14             	mov    %edi,0x14(%ebp)
f01035d0:	e9 60 02 00 00       	jmp    f0103835 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f01035d5:	50                   	push   %eax
f01035d6:	8d 83 3d df fe ff    	lea    -0x120c3(%ebx),%eax
f01035dc:	50                   	push   %eax
f01035dd:	56                   	push   %esi
f01035de:	ff 75 08             	pushl  0x8(%ebp)
f01035e1:	e8 88 fe ff ff       	call   f010346e <printfmt>
f01035e6:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01035e9:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01035ec:	e9 44 02 00 00       	jmp    f0103835 <.L35+0x45>

f01035f1 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f01035f1:	8b 45 14             	mov    0x14(%ebp),%eax
f01035f4:	83 c0 04             	add    $0x4,%eax
f01035f7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01035fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01035fd:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01035ff:	85 ff                	test   %edi,%edi
f0103601:	8d 83 36 df fe ff    	lea    -0x120ca(%ebx),%eax
f0103607:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010360a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010360e:	0f 8e b5 00 00 00    	jle    f01036c9 <.L36+0xd8>
f0103614:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103618:	75 08                	jne    f0103622 <.L36+0x31>
f010361a:	89 75 0c             	mov    %esi,0xc(%ebp)
f010361d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103620:	eb 6d                	jmp    f010368f <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103622:	83 ec 08             	sub    $0x8,%esp
f0103625:	ff 75 d0             	pushl  -0x30(%ebp)
f0103628:	57                   	push   %edi
f0103629:	e8 49 04 00 00       	call   f0103a77 <strnlen>
f010362e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103631:	29 c2                	sub    %eax,%edx
f0103633:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0103636:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103639:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010363d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103640:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103643:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103645:	eb 10                	jmp    f0103657 <.L36+0x66>
					putch(padc, putdat);
f0103647:	83 ec 08             	sub    $0x8,%esp
f010364a:	56                   	push   %esi
f010364b:	ff 75 e0             	pushl  -0x20(%ebp)
f010364e:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0103651:	83 ef 01             	sub    $0x1,%edi
f0103654:	83 c4 10             	add    $0x10,%esp
f0103657:	85 ff                	test   %edi,%edi
f0103659:	7f ec                	jg     f0103647 <.L36+0x56>
f010365b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010365e:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0103661:	85 d2                	test   %edx,%edx
f0103663:	b8 00 00 00 00       	mov    $0x0,%eax
f0103668:	0f 49 c2             	cmovns %edx,%eax
f010366b:	29 c2                	sub    %eax,%edx
f010366d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0103670:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103673:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103676:	eb 17                	jmp    f010368f <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0103678:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010367c:	75 30                	jne    f01036ae <.L36+0xbd>
					putch(ch, putdat);
f010367e:	83 ec 08             	sub    $0x8,%esp
f0103681:	ff 75 0c             	pushl  0xc(%ebp)
f0103684:	50                   	push   %eax
f0103685:	ff 55 08             	call   *0x8(%ebp)
f0103688:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010368b:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f010368f:	83 c7 01             	add    $0x1,%edi
f0103692:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0103696:	0f be c2             	movsbl %dl,%eax
f0103699:	85 c0                	test   %eax,%eax
f010369b:	74 52                	je     f01036ef <.L36+0xfe>
f010369d:	85 f6                	test   %esi,%esi
f010369f:	78 d7                	js     f0103678 <.L36+0x87>
f01036a1:	83 ee 01             	sub    $0x1,%esi
f01036a4:	79 d2                	jns    f0103678 <.L36+0x87>
f01036a6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01036a9:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01036ac:	eb 32                	jmp    f01036e0 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01036ae:	0f be d2             	movsbl %dl,%edx
f01036b1:	83 ea 20             	sub    $0x20,%edx
f01036b4:	83 fa 5e             	cmp    $0x5e,%edx
f01036b7:	76 c5                	jbe    f010367e <.L36+0x8d>
					putch('?', putdat);
f01036b9:	83 ec 08             	sub    $0x8,%esp
f01036bc:	ff 75 0c             	pushl  0xc(%ebp)
f01036bf:	6a 3f                	push   $0x3f
f01036c1:	ff 55 08             	call   *0x8(%ebp)
f01036c4:	83 c4 10             	add    $0x10,%esp
f01036c7:	eb c2                	jmp    f010368b <.L36+0x9a>
f01036c9:	89 75 0c             	mov    %esi,0xc(%ebp)
f01036cc:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01036cf:	eb be                	jmp    f010368f <.L36+0x9e>
				putch(' ', putdat);
f01036d1:	83 ec 08             	sub    $0x8,%esp
f01036d4:	56                   	push   %esi
f01036d5:	6a 20                	push   $0x20
f01036d7:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01036da:	83 ef 01             	sub    $0x1,%edi
f01036dd:	83 c4 10             	add    $0x10,%esp
f01036e0:	85 ff                	test   %edi,%edi
f01036e2:	7f ed                	jg     f01036d1 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01036e4:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01036e7:	89 45 14             	mov    %eax,0x14(%ebp)
f01036ea:	e9 46 01 00 00       	jmp    f0103835 <.L35+0x45>
f01036ef:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01036f2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01036f5:	eb e9                	jmp    f01036e0 <.L36+0xef>

f01036f7 <.L31>:
f01036f7:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f01036fa:	83 f9 01             	cmp    $0x1,%ecx
f01036fd:	7e 40                	jle    f010373f <.L31+0x48>
		return va_arg(*ap, long long);
f01036ff:	8b 45 14             	mov    0x14(%ebp),%eax
f0103702:	8b 50 04             	mov    0x4(%eax),%edx
f0103705:	8b 00                	mov    (%eax),%eax
f0103707:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010370a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010370d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103710:	8d 40 08             	lea    0x8(%eax),%eax
f0103713:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0103716:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010371a:	79 55                	jns    f0103771 <.L31+0x7a>
				putch('-', putdat);
f010371c:	83 ec 08             	sub    $0x8,%esp
f010371f:	56                   	push   %esi
f0103720:	6a 2d                	push   $0x2d
f0103722:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103725:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103728:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010372b:	f7 da                	neg    %edx
f010372d:	83 d1 00             	adc    $0x0,%ecx
f0103730:	f7 d9                	neg    %ecx
f0103732:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0103735:	b8 0a 00 00 00       	mov    $0xa,%eax
f010373a:	e9 db 00 00 00       	jmp    f010381a <.L35+0x2a>
	else if (lflag)
f010373f:	85 c9                	test   %ecx,%ecx
f0103741:	75 17                	jne    f010375a <.L31+0x63>
		return va_arg(*ap, int);
f0103743:	8b 45 14             	mov    0x14(%ebp),%eax
f0103746:	8b 00                	mov    (%eax),%eax
f0103748:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010374b:	99                   	cltd   
f010374c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010374f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103752:	8d 40 04             	lea    0x4(%eax),%eax
f0103755:	89 45 14             	mov    %eax,0x14(%ebp)
f0103758:	eb bc                	jmp    f0103716 <.L31+0x1f>
		return va_arg(*ap, long);
f010375a:	8b 45 14             	mov    0x14(%ebp),%eax
f010375d:	8b 00                	mov    (%eax),%eax
f010375f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103762:	99                   	cltd   
f0103763:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103766:	8b 45 14             	mov    0x14(%ebp),%eax
f0103769:	8d 40 04             	lea    0x4(%eax),%eax
f010376c:	89 45 14             	mov    %eax,0x14(%ebp)
f010376f:	eb a5                	jmp    f0103716 <.L31+0x1f>
			num = getint(&ap, lflag);
f0103771:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103774:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0103777:	b8 0a 00 00 00       	mov    $0xa,%eax
f010377c:	e9 99 00 00 00       	jmp    f010381a <.L35+0x2a>

f0103781 <.L37>:
f0103781:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0103784:	83 f9 01             	cmp    $0x1,%ecx
f0103787:	7e 15                	jle    f010379e <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f0103789:	8b 45 14             	mov    0x14(%ebp),%eax
f010378c:	8b 10                	mov    (%eax),%edx
f010378e:	8b 48 04             	mov    0x4(%eax),%ecx
f0103791:	8d 40 08             	lea    0x8(%eax),%eax
f0103794:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103797:	b8 0a 00 00 00       	mov    $0xa,%eax
f010379c:	eb 7c                	jmp    f010381a <.L35+0x2a>
	else if (lflag)
f010379e:	85 c9                	test   %ecx,%ecx
f01037a0:	75 17                	jne    f01037b9 <.L37+0x38>
		return va_arg(*ap, unsigned int);
f01037a2:	8b 45 14             	mov    0x14(%ebp),%eax
f01037a5:	8b 10                	mov    (%eax),%edx
f01037a7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01037ac:	8d 40 04             	lea    0x4(%eax),%eax
f01037af:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01037b2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037b7:	eb 61                	jmp    f010381a <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01037b9:	8b 45 14             	mov    0x14(%ebp),%eax
f01037bc:	8b 10                	mov    (%eax),%edx
f01037be:	b9 00 00 00 00       	mov    $0x0,%ecx
f01037c3:	8d 40 04             	lea    0x4(%eax),%eax
f01037c6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01037c9:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037ce:	eb 4a                	jmp    f010381a <.L35+0x2a>

f01037d0 <.L34>:
			putch('X', putdat);
f01037d0:	83 ec 08             	sub    $0x8,%esp
f01037d3:	56                   	push   %esi
f01037d4:	6a 58                	push   $0x58
f01037d6:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01037d9:	83 c4 08             	add    $0x8,%esp
f01037dc:	56                   	push   %esi
f01037dd:	6a 58                	push   $0x58
f01037df:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01037e2:	83 c4 08             	add    $0x8,%esp
f01037e5:	56                   	push   %esi
f01037e6:	6a 58                	push   $0x58
f01037e8:	ff 55 08             	call   *0x8(%ebp)
			break;
f01037eb:	83 c4 10             	add    $0x10,%esp
f01037ee:	eb 45                	jmp    f0103835 <.L35+0x45>

f01037f0 <.L35>:
			putch('0', putdat);
f01037f0:	83 ec 08             	sub    $0x8,%esp
f01037f3:	56                   	push   %esi
f01037f4:	6a 30                	push   $0x30
f01037f6:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01037f9:	83 c4 08             	add    $0x8,%esp
f01037fc:	56                   	push   %esi
f01037fd:	6a 78                	push   $0x78
f01037ff:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0103802:	8b 45 14             	mov    0x14(%ebp),%eax
f0103805:	8b 10                	mov    (%eax),%edx
f0103807:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010380c:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010380f:	8d 40 04             	lea    0x4(%eax),%eax
f0103812:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103815:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010381a:	83 ec 0c             	sub    $0xc,%esp
f010381d:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103821:	57                   	push   %edi
f0103822:	ff 75 e0             	pushl  -0x20(%ebp)
f0103825:	50                   	push   %eax
f0103826:	51                   	push   %ecx
f0103827:	52                   	push   %edx
f0103828:	89 f2                	mov    %esi,%edx
f010382a:	8b 45 08             	mov    0x8(%ebp),%eax
f010382d:	e8 55 fb ff ff       	call   f0103387 <printnum>
			break;
f0103832:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0103835:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103838:	83 c7 01             	add    $0x1,%edi
f010383b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010383f:	83 f8 25             	cmp    $0x25,%eax
f0103842:	0f 84 62 fc ff ff    	je     f01034aa <vprintfmt+0x1f>
			if (ch == '\0')
f0103848:	85 c0                	test   %eax,%eax
f010384a:	0f 84 91 00 00 00    	je     f01038e1 <.L22+0x21>
			putch(ch, putdat);
f0103850:	83 ec 08             	sub    $0x8,%esp
f0103853:	56                   	push   %esi
f0103854:	50                   	push   %eax
f0103855:	ff 55 08             	call   *0x8(%ebp)
f0103858:	83 c4 10             	add    $0x10,%esp
f010385b:	eb db                	jmp    f0103838 <.L35+0x48>

f010385d <.L38>:
f010385d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0103860:	83 f9 01             	cmp    $0x1,%ecx
f0103863:	7e 15                	jle    f010387a <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0103865:	8b 45 14             	mov    0x14(%ebp),%eax
f0103868:	8b 10                	mov    (%eax),%edx
f010386a:	8b 48 04             	mov    0x4(%eax),%ecx
f010386d:	8d 40 08             	lea    0x8(%eax),%eax
f0103870:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103873:	b8 10 00 00 00       	mov    $0x10,%eax
f0103878:	eb a0                	jmp    f010381a <.L35+0x2a>
	else if (lflag)
f010387a:	85 c9                	test   %ecx,%ecx
f010387c:	75 17                	jne    f0103895 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f010387e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103881:	8b 10                	mov    (%eax),%edx
f0103883:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103888:	8d 40 04             	lea    0x4(%eax),%eax
f010388b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010388e:	b8 10 00 00 00       	mov    $0x10,%eax
f0103893:	eb 85                	jmp    f010381a <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103895:	8b 45 14             	mov    0x14(%ebp),%eax
f0103898:	8b 10                	mov    (%eax),%edx
f010389a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010389f:	8d 40 04             	lea    0x4(%eax),%eax
f01038a2:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01038a5:	b8 10 00 00 00       	mov    $0x10,%eax
f01038aa:	e9 6b ff ff ff       	jmp    f010381a <.L35+0x2a>

f01038af <.L25>:
			putch(ch, putdat);
f01038af:	83 ec 08             	sub    $0x8,%esp
f01038b2:	56                   	push   %esi
f01038b3:	6a 25                	push   $0x25
f01038b5:	ff 55 08             	call   *0x8(%ebp)
			break;
f01038b8:	83 c4 10             	add    $0x10,%esp
f01038bb:	e9 75 ff ff ff       	jmp    f0103835 <.L35+0x45>

f01038c0 <.L22>:
			putch('%', putdat);
f01038c0:	83 ec 08             	sub    $0x8,%esp
f01038c3:	56                   	push   %esi
f01038c4:	6a 25                	push   $0x25
f01038c6:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01038c9:	83 c4 10             	add    $0x10,%esp
f01038cc:	89 f8                	mov    %edi,%eax
f01038ce:	eb 03                	jmp    f01038d3 <.L22+0x13>
f01038d0:	83 e8 01             	sub    $0x1,%eax
f01038d3:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01038d7:	75 f7                	jne    f01038d0 <.L22+0x10>
f01038d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01038dc:	e9 54 ff ff ff       	jmp    f0103835 <.L35+0x45>
}
f01038e1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01038e4:	5b                   	pop    %ebx
f01038e5:	5e                   	pop    %esi
f01038e6:	5f                   	pop    %edi
f01038e7:	5d                   	pop    %ebp
f01038e8:	c3                   	ret    

f01038e9 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01038e9:	55                   	push   %ebp
f01038ea:	89 e5                	mov    %esp,%ebp
f01038ec:	53                   	push   %ebx
f01038ed:	83 ec 14             	sub    $0x14,%esp
f01038f0:	e8 5a c8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01038f5:	81 c3 13 3a 01 00    	add    $0x13a13,%ebx
f01038fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01038fe:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103901:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103904:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103908:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010390b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103912:	85 c0                	test   %eax,%eax
f0103914:	74 2b                	je     f0103941 <vsnprintf+0x58>
f0103916:	85 d2                	test   %edx,%edx
f0103918:	7e 27                	jle    f0103941 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010391a:	ff 75 14             	pushl  0x14(%ebp)
f010391d:	ff 75 10             	pushl  0x10(%ebp)
f0103920:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103923:	50                   	push   %eax
f0103924:	8d 83 49 c1 fe ff    	lea    -0x13eb7(%ebx),%eax
f010392a:	50                   	push   %eax
f010392b:	e8 5b fb ff ff       	call   f010348b <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103930:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103933:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103936:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103939:	83 c4 10             	add    $0x10,%esp
}
f010393c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010393f:	c9                   	leave  
f0103940:	c3                   	ret    
		return -E_INVAL;
f0103941:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103946:	eb f4                	jmp    f010393c <vsnprintf+0x53>

f0103948 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103948:	55                   	push   %ebp
f0103949:	89 e5                	mov    %esp,%ebp
f010394b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010394e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103951:	50                   	push   %eax
f0103952:	ff 75 10             	pushl  0x10(%ebp)
f0103955:	ff 75 0c             	pushl  0xc(%ebp)
f0103958:	ff 75 08             	pushl  0x8(%ebp)
f010395b:	e8 89 ff ff ff       	call   f01038e9 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103960:	c9                   	leave  
f0103961:	c3                   	ret    

f0103962 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103962:	55                   	push   %ebp
f0103963:	89 e5                	mov    %esp,%ebp
f0103965:	57                   	push   %edi
f0103966:	56                   	push   %esi
f0103967:	53                   	push   %ebx
f0103968:	83 ec 1c             	sub    $0x1c,%esp
f010396b:	e8 df c7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103970:	81 c3 98 39 01 00    	add    $0x13998,%ebx
f0103976:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103979:	85 c0                	test   %eax,%eax
f010397b:	74 13                	je     f0103990 <readline+0x2e>
		cprintf("%s", prompt);
f010397d:	83 ec 08             	sub    $0x8,%esp
f0103980:	50                   	push   %eax
f0103981:	8d 83 c0 d1 fe ff    	lea    -0x12e40(%ebx),%eax
f0103987:	50                   	push   %eax
f0103988:	e8 ee f6 ff ff       	call   f010307b <cprintf>
f010398d:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103990:	83 ec 0c             	sub    $0xc,%esp
f0103993:	6a 00                	push   $0x0
f0103995:	e8 4d cd ff ff       	call   f01006e7 <iscons>
f010399a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010399d:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01039a0:	bf 00 00 00 00       	mov    $0x0,%edi
f01039a5:	eb 46                	jmp    f01039ed <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01039a7:	83 ec 08             	sub    $0x8,%esp
f01039aa:	50                   	push   %eax
f01039ab:	8d 83 08 e1 fe ff    	lea    -0x11ef8(%ebx),%eax
f01039b1:	50                   	push   %eax
f01039b2:	e8 c4 f6 ff ff       	call   f010307b <cprintf>
			return NULL;
f01039b7:	83 c4 10             	add    $0x10,%esp
f01039ba:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01039bf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01039c2:	5b                   	pop    %ebx
f01039c3:	5e                   	pop    %esi
f01039c4:	5f                   	pop    %edi
f01039c5:	5d                   	pop    %ebp
f01039c6:	c3                   	ret    
			if (echoing)
f01039c7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01039cb:	75 05                	jne    f01039d2 <readline+0x70>
			i--;
f01039cd:	83 ef 01             	sub    $0x1,%edi
f01039d0:	eb 1b                	jmp    f01039ed <readline+0x8b>
				cputchar('\b');
f01039d2:	83 ec 0c             	sub    $0xc,%esp
f01039d5:	6a 08                	push   $0x8
f01039d7:	e8 ea cc ff ff       	call   f01006c6 <cputchar>
f01039dc:	83 c4 10             	add    $0x10,%esp
f01039df:	eb ec                	jmp    f01039cd <readline+0x6b>
			buf[i++] = c;
f01039e1:	89 f0                	mov    %esi,%eax
f01039e3:	88 84 3b b8 1f 00 00 	mov    %al,0x1fb8(%ebx,%edi,1)
f01039ea:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f01039ed:	e8 e4 cc ff ff       	call   f01006d6 <getchar>
f01039f2:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f01039f4:	85 c0                	test   %eax,%eax
f01039f6:	78 af                	js     f01039a7 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01039f8:	83 f8 08             	cmp    $0x8,%eax
f01039fb:	0f 94 c2             	sete   %dl
f01039fe:	83 f8 7f             	cmp    $0x7f,%eax
f0103a01:	0f 94 c0             	sete   %al
f0103a04:	08 c2                	or     %al,%dl
f0103a06:	74 04                	je     f0103a0c <readline+0xaa>
f0103a08:	85 ff                	test   %edi,%edi
f0103a0a:	7f bb                	jg     f01039c7 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103a0c:	83 fe 1f             	cmp    $0x1f,%esi
f0103a0f:	7e 1c                	jle    f0103a2d <readline+0xcb>
f0103a11:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103a17:	7f 14                	jg     f0103a2d <readline+0xcb>
			if (echoing)
f0103a19:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103a1d:	74 c2                	je     f01039e1 <readline+0x7f>
				cputchar(c);
f0103a1f:	83 ec 0c             	sub    $0xc,%esp
f0103a22:	56                   	push   %esi
f0103a23:	e8 9e cc ff ff       	call   f01006c6 <cputchar>
f0103a28:	83 c4 10             	add    $0x10,%esp
f0103a2b:	eb b4                	jmp    f01039e1 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103a2d:	83 fe 0a             	cmp    $0xa,%esi
f0103a30:	74 05                	je     f0103a37 <readline+0xd5>
f0103a32:	83 fe 0d             	cmp    $0xd,%esi
f0103a35:	75 b6                	jne    f01039ed <readline+0x8b>
			if (echoing)
f0103a37:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103a3b:	75 13                	jne    f0103a50 <readline+0xee>
			buf[i] = 0;
f0103a3d:	c6 84 3b b8 1f 00 00 	movb   $0x0,0x1fb8(%ebx,%edi,1)
f0103a44:	00 
			return buf;
f0103a45:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f0103a4b:	e9 6f ff ff ff       	jmp    f01039bf <readline+0x5d>
				cputchar('\n');
f0103a50:	83 ec 0c             	sub    $0xc,%esp
f0103a53:	6a 0a                	push   $0xa
f0103a55:	e8 6c cc ff ff       	call   f01006c6 <cputchar>
f0103a5a:	83 c4 10             	add    $0x10,%esp
f0103a5d:	eb de                	jmp    f0103a3d <readline+0xdb>

f0103a5f <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103a5f:	55                   	push   %ebp
f0103a60:	89 e5                	mov    %esp,%ebp
f0103a62:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103a65:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a6a:	eb 03                	jmp    f0103a6f <strlen+0x10>
		n++;
f0103a6c:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103a6f:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103a73:	75 f7                	jne    f0103a6c <strlen+0xd>
	return n;
}
f0103a75:	5d                   	pop    %ebp
f0103a76:	c3                   	ret    

f0103a77 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103a77:	55                   	push   %ebp
f0103a78:	89 e5                	mov    %esp,%ebp
f0103a7a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103a7d:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a80:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a85:	eb 03                	jmp    f0103a8a <strnlen+0x13>
		n++;
f0103a87:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a8a:	39 d0                	cmp    %edx,%eax
f0103a8c:	74 06                	je     f0103a94 <strnlen+0x1d>
f0103a8e:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103a92:	75 f3                	jne    f0103a87 <strnlen+0x10>
	return n;
}
f0103a94:	5d                   	pop    %ebp
f0103a95:	c3                   	ret    

f0103a96 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103a96:	55                   	push   %ebp
f0103a97:	89 e5                	mov    %esp,%ebp
f0103a99:	53                   	push   %ebx
f0103a9a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a9d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103aa0:	89 c2                	mov    %eax,%edx
f0103aa2:	83 c1 01             	add    $0x1,%ecx
f0103aa5:	83 c2 01             	add    $0x1,%edx
f0103aa8:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103aac:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103aaf:	84 db                	test   %bl,%bl
f0103ab1:	75 ef                	jne    f0103aa2 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103ab3:	5b                   	pop    %ebx
f0103ab4:	5d                   	pop    %ebp
f0103ab5:	c3                   	ret    

f0103ab6 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103ab6:	55                   	push   %ebp
f0103ab7:	89 e5                	mov    %esp,%ebp
f0103ab9:	53                   	push   %ebx
f0103aba:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103abd:	53                   	push   %ebx
f0103abe:	e8 9c ff ff ff       	call   f0103a5f <strlen>
f0103ac3:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103ac6:	ff 75 0c             	pushl  0xc(%ebp)
f0103ac9:	01 d8                	add    %ebx,%eax
f0103acb:	50                   	push   %eax
f0103acc:	e8 c5 ff ff ff       	call   f0103a96 <strcpy>
	return dst;
}
f0103ad1:	89 d8                	mov    %ebx,%eax
f0103ad3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103ad6:	c9                   	leave  
f0103ad7:	c3                   	ret    

f0103ad8 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103ad8:	55                   	push   %ebp
f0103ad9:	89 e5                	mov    %esp,%ebp
f0103adb:	56                   	push   %esi
f0103adc:	53                   	push   %ebx
f0103add:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ae0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103ae3:	89 f3                	mov    %esi,%ebx
f0103ae5:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103ae8:	89 f2                	mov    %esi,%edx
f0103aea:	eb 0f                	jmp    f0103afb <strncpy+0x23>
		*dst++ = *src;
f0103aec:	83 c2 01             	add    $0x1,%edx
f0103aef:	0f b6 01             	movzbl (%ecx),%eax
f0103af2:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103af5:	80 39 01             	cmpb   $0x1,(%ecx)
f0103af8:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103afb:	39 da                	cmp    %ebx,%edx
f0103afd:	75 ed                	jne    f0103aec <strncpy+0x14>
	}
	return ret;
}
f0103aff:	89 f0                	mov    %esi,%eax
f0103b01:	5b                   	pop    %ebx
f0103b02:	5e                   	pop    %esi
f0103b03:	5d                   	pop    %ebp
f0103b04:	c3                   	ret    

f0103b05 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103b05:	55                   	push   %ebp
f0103b06:	89 e5                	mov    %esp,%ebp
f0103b08:	56                   	push   %esi
f0103b09:	53                   	push   %ebx
f0103b0a:	8b 75 08             	mov    0x8(%ebp),%esi
f0103b0d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b10:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103b13:	89 f0                	mov    %esi,%eax
f0103b15:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103b19:	85 c9                	test   %ecx,%ecx
f0103b1b:	75 0b                	jne    f0103b28 <strlcpy+0x23>
f0103b1d:	eb 17                	jmp    f0103b36 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103b1f:	83 c2 01             	add    $0x1,%edx
f0103b22:	83 c0 01             	add    $0x1,%eax
f0103b25:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103b28:	39 d8                	cmp    %ebx,%eax
f0103b2a:	74 07                	je     f0103b33 <strlcpy+0x2e>
f0103b2c:	0f b6 0a             	movzbl (%edx),%ecx
f0103b2f:	84 c9                	test   %cl,%cl
f0103b31:	75 ec                	jne    f0103b1f <strlcpy+0x1a>
		*dst = '\0';
f0103b33:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103b36:	29 f0                	sub    %esi,%eax
}
f0103b38:	5b                   	pop    %ebx
f0103b39:	5e                   	pop    %esi
f0103b3a:	5d                   	pop    %ebp
f0103b3b:	c3                   	ret    

f0103b3c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103b3c:	55                   	push   %ebp
f0103b3d:	89 e5                	mov    %esp,%ebp
f0103b3f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b42:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103b45:	eb 06                	jmp    f0103b4d <strcmp+0x11>
		p++, q++;
f0103b47:	83 c1 01             	add    $0x1,%ecx
f0103b4a:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103b4d:	0f b6 01             	movzbl (%ecx),%eax
f0103b50:	84 c0                	test   %al,%al
f0103b52:	74 04                	je     f0103b58 <strcmp+0x1c>
f0103b54:	3a 02                	cmp    (%edx),%al
f0103b56:	74 ef                	je     f0103b47 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b58:	0f b6 c0             	movzbl %al,%eax
f0103b5b:	0f b6 12             	movzbl (%edx),%edx
f0103b5e:	29 d0                	sub    %edx,%eax
}
f0103b60:	5d                   	pop    %ebp
f0103b61:	c3                   	ret    

f0103b62 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103b62:	55                   	push   %ebp
f0103b63:	89 e5                	mov    %esp,%ebp
f0103b65:	53                   	push   %ebx
f0103b66:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b69:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b6c:	89 c3                	mov    %eax,%ebx
f0103b6e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103b71:	eb 06                	jmp    f0103b79 <strncmp+0x17>
		n--, p++, q++;
f0103b73:	83 c0 01             	add    $0x1,%eax
f0103b76:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103b79:	39 d8                	cmp    %ebx,%eax
f0103b7b:	74 16                	je     f0103b93 <strncmp+0x31>
f0103b7d:	0f b6 08             	movzbl (%eax),%ecx
f0103b80:	84 c9                	test   %cl,%cl
f0103b82:	74 04                	je     f0103b88 <strncmp+0x26>
f0103b84:	3a 0a                	cmp    (%edx),%cl
f0103b86:	74 eb                	je     f0103b73 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b88:	0f b6 00             	movzbl (%eax),%eax
f0103b8b:	0f b6 12             	movzbl (%edx),%edx
f0103b8e:	29 d0                	sub    %edx,%eax
}
f0103b90:	5b                   	pop    %ebx
f0103b91:	5d                   	pop    %ebp
f0103b92:	c3                   	ret    
		return 0;
f0103b93:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b98:	eb f6                	jmp    f0103b90 <strncmp+0x2e>

f0103b9a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103b9a:	55                   	push   %ebp
f0103b9b:	89 e5                	mov    %esp,%ebp
f0103b9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ba0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103ba4:	0f b6 10             	movzbl (%eax),%edx
f0103ba7:	84 d2                	test   %dl,%dl
f0103ba9:	74 09                	je     f0103bb4 <strchr+0x1a>
		if (*s == c)
f0103bab:	38 ca                	cmp    %cl,%dl
f0103bad:	74 0a                	je     f0103bb9 <strchr+0x1f>
	for (; *s; s++)
f0103baf:	83 c0 01             	add    $0x1,%eax
f0103bb2:	eb f0                	jmp    f0103ba4 <strchr+0xa>
			return (char *) s;
	return 0;
f0103bb4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103bb9:	5d                   	pop    %ebp
f0103bba:	c3                   	ret    

f0103bbb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103bbb:	55                   	push   %ebp
f0103bbc:	89 e5                	mov    %esp,%ebp
f0103bbe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bc1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103bc5:	eb 03                	jmp    f0103bca <strfind+0xf>
f0103bc7:	83 c0 01             	add    $0x1,%eax
f0103bca:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103bcd:	38 ca                	cmp    %cl,%dl
f0103bcf:	74 04                	je     f0103bd5 <strfind+0x1a>
f0103bd1:	84 d2                	test   %dl,%dl
f0103bd3:	75 f2                	jne    f0103bc7 <strfind+0xc>
			break;
	return (char *) s;
}
f0103bd5:	5d                   	pop    %ebp
f0103bd6:	c3                   	ret    

f0103bd7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103bd7:	55                   	push   %ebp
f0103bd8:	89 e5                	mov    %esp,%ebp
f0103bda:	57                   	push   %edi
f0103bdb:	56                   	push   %esi
f0103bdc:	53                   	push   %ebx
f0103bdd:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103be0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103be3:	85 c9                	test   %ecx,%ecx
f0103be5:	74 13                	je     f0103bfa <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103be7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103bed:	75 05                	jne    f0103bf4 <memset+0x1d>
f0103bef:	f6 c1 03             	test   $0x3,%cl
f0103bf2:	74 0d                	je     f0103c01 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103bf4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103bf7:	fc                   	cld    
f0103bf8:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103bfa:	89 f8                	mov    %edi,%eax
f0103bfc:	5b                   	pop    %ebx
f0103bfd:	5e                   	pop    %esi
f0103bfe:	5f                   	pop    %edi
f0103bff:	5d                   	pop    %ebp
f0103c00:	c3                   	ret    
		c &= 0xFF;
f0103c01:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103c05:	89 d3                	mov    %edx,%ebx
f0103c07:	c1 e3 08             	shl    $0x8,%ebx
f0103c0a:	89 d0                	mov    %edx,%eax
f0103c0c:	c1 e0 18             	shl    $0x18,%eax
f0103c0f:	89 d6                	mov    %edx,%esi
f0103c11:	c1 e6 10             	shl    $0x10,%esi
f0103c14:	09 f0                	or     %esi,%eax
f0103c16:	09 c2                	or     %eax,%edx
f0103c18:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0103c1a:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103c1d:	89 d0                	mov    %edx,%eax
f0103c1f:	fc                   	cld    
f0103c20:	f3 ab                	rep stos %eax,%es:(%edi)
f0103c22:	eb d6                	jmp    f0103bfa <memset+0x23>

f0103c24 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103c24:	55                   	push   %ebp
f0103c25:	89 e5                	mov    %esp,%ebp
f0103c27:	57                   	push   %edi
f0103c28:	56                   	push   %esi
f0103c29:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c2c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103c2f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103c32:	39 c6                	cmp    %eax,%esi
f0103c34:	73 35                	jae    f0103c6b <memmove+0x47>
f0103c36:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103c39:	39 c2                	cmp    %eax,%edx
f0103c3b:	76 2e                	jbe    f0103c6b <memmove+0x47>
		s += n;
		d += n;
f0103c3d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c40:	89 d6                	mov    %edx,%esi
f0103c42:	09 fe                	or     %edi,%esi
f0103c44:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103c4a:	74 0c                	je     f0103c58 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103c4c:	83 ef 01             	sub    $0x1,%edi
f0103c4f:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103c52:	fd                   	std    
f0103c53:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103c55:	fc                   	cld    
f0103c56:	eb 21                	jmp    f0103c79 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c58:	f6 c1 03             	test   $0x3,%cl
f0103c5b:	75 ef                	jne    f0103c4c <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103c5d:	83 ef 04             	sub    $0x4,%edi
f0103c60:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103c63:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103c66:	fd                   	std    
f0103c67:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c69:	eb ea                	jmp    f0103c55 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c6b:	89 f2                	mov    %esi,%edx
f0103c6d:	09 c2                	or     %eax,%edx
f0103c6f:	f6 c2 03             	test   $0x3,%dl
f0103c72:	74 09                	je     f0103c7d <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103c74:	89 c7                	mov    %eax,%edi
f0103c76:	fc                   	cld    
f0103c77:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103c79:	5e                   	pop    %esi
f0103c7a:	5f                   	pop    %edi
f0103c7b:	5d                   	pop    %ebp
f0103c7c:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c7d:	f6 c1 03             	test   $0x3,%cl
f0103c80:	75 f2                	jne    f0103c74 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103c82:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103c85:	89 c7                	mov    %eax,%edi
f0103c87:	fc                   	cld    
f0103c88:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c8a:	eb ed                	jmp    f0103c79 <memmove+0x55>

f0103c8c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103c8c:	55                   	push   %ebp
f0103c8d:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103c8f:	ff 75 10             	pushl  0x10(%ebp)
f0103c92:	ff 75 0c             	pushl  0xc(%ebp)
f0103c95:	ff 75 08             	pushl  0x8(%ebp)
f0103c98:	e8 87 ff ff ff       	call   f0103c24 <memmove>
}
f0103c9d:	c9                   	leave  
f0103c9e:	c3                   	ret    

f0103c9f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103c9f:	55                   	push   %ebp
f0103ca0:	89 e5                	mov    %esp,%ebp
f0103ca2:	56                   	push   %esi
f0103ca3:	53                   	push   %ebx
f0103ca4:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ca7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103caa:	89 c6                	mov    %eax,%esi
f0103cac:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103caf:	39 f0                	cmp    %esi,%eax
f0103cb1:	74 1c                	je     f0103ccf <memcmp+0x30>
		if (*s1 != *s2)
f0103cb3:	0f b6 08             	movzbl (%eax),%ecx
f0103cb6:	0f b6 1a             	movzbl (%edx),%ebx
f0103cb9:	38 d9                	cmp    %bl,%cl
f0103cbb:	75 08                	jne    f0103cc5 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103cbd:	83 c0 01             	add    $0x1,%eax
f0103cc0:	83 c2 01             	add    $0x1,%edx
f0103cc3:	eb ea                	jmp    f0103caf <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0103cc5:	0f b6 c1             	movzbl %cl,%eax
f0103cc8:	0f b6 db             	movzbl %bl,%ebx
f0103ccb:	29 d8                	sub    %ebx,%eax
f0103ccd:	eb 05                	jmp    f0103cd4 <memcmp+0x35>
	}

	return 0;
f0103ccf:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103cd4:	5b                   	pop    %ebx
f0103cd5:	5e                   	pop    %esi
f0103cd6:	5d                   	pop    %ebp
f0103cd7:	c3                   	ret    

f0103cd8 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103cd8:	55                   	push   %ebp
f0103cd9:	89 e5                	mov    %esp,%ebp
f0103cdb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cde:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103ce1:	89 c2                	mov    %eax,%edx
f0103ce3:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103ce6:	39 d0                	cmp    %edx,%eax
f0103ce8:	73 09                	jae    f0103cf3 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103cea:	38 08                	cmp    %cl,(%eax)
f0103cec:	74 05                	je     f0103cf3 <memfind+0x1b>
	for (; s < ends; s++)
f0103cee:	83 c0 01             	add    $0x1,%eax
f0103cf1:	eb f3                	jmp    f0103ce6 <memfind+0xe>
			break;
	return (void *) s;
}
f0103cf3:	5d                   	pop    %ebp
f0103cf4:	c3                   	ret    

f0103cf5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103cf5:	55                   	push   %ebp
f0103cf6:	89 e5                	mov    %esp,%ebp
f0103cf8:	57                   	push   %edi
f0103cf9:	56                   	push   %esi
f0103cfa:	53                   	push   %ebx
f0103cfb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103cfe:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103d01:	eb 03                	jmp    f0103d06 <strtol+0x11>
		s++;
f0103d03:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0103d06:	0f b6 01             	movzbl (%ecx),%eax
f0103d09:	3c 20                	cmp    $0x20,%al
f0103d0b:	74 f6                	je     f0103d03 <strtol+0xe>
f0103d0d:	3c 09                	cmp    $0x9,%al
f0103d0f:	74 f2                	je     f0103d03 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103d11:	3c 2b                	cmp    $0x2b,%al
f0103d13:	74 2e                	je     f0103d43 <strtol+0x4e>
	int neg = 0;
f0103d15:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103d1a:	3c 2d                	cmp    $0x2d,%al
f0103d1c:	74 2f                	je     f0103d4d <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103d1e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103d24:	75 05                	jne    f0103d2b <strtol+0x36>
f0103d26:	80 39 30             	cmpb   $0x30,(%ecx)
f0103d29:	74 2c                	je     f0103d57 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103d2b:	85 db                	test   %ebx,%ebx
f0103d2d:	75 0a                	jne    f0103d39 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103d2f:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0103d34:	80 39 30             	cmpb   $0x30,(%ecx)
f0103d37:	74 28                	je     f0103d61 <strtol+0x6c>
		base = 10;
f0103d39:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d3e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103d41:	eb 50                	jmp    f0103d93 <strtol+0x9e>
		s++;
f0103d43:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0103d46:	bf 00 00 00 00       	mov    $0x0,%edi
f0103d4b:	eb d1                	jmp    f0103d1e <strtol+0x29>
		s++, neg = 1;
f0103d4d:	83 c1 01             	add    $0x1,%ecx
f0103d50:	bf 01 00 00 00       	mov    $0x1,%edi
f0103d55:	eb c7                	jmp    f0103d1e <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103d57:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103d5b:	74 0e                	je     f0103d6b <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0103d5d:	85 db                	test   %ebx,%ebx
f0103d5f:	75 d8                	jne    f0103d39 <strtol+0x44>
		s++, base = 8;
f0103d61:	83 c1 01             	add    $0x1,%ecx
f0103d64:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103d69:	eb ce                	jmp    f0103d39 <strtol+0x44>
		s += 2, base = 16;
f0103d6b:	83 c1 02             	add    $0x2,%ecx
f0103d6e:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103d73:	eb c4                	jmp    f0103d39 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0103d75:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103d78:	89 f3                	mov    %esi,%ebx
f0103d7a:	80 fb 19             	cmp    $0x19,%bl
f0103d7d:	77 29                	ja     f0103da8 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103d7f:	0f be d2             	movsbl %dl,%edx
f0103d82:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103d85:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103d88:	7d 30                	jge    f0103dba <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103d8a:	83 c1 01             	add    $0x1,%ecx
f0103d8d:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103d91:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103d93:	0f b6 11             	movzbl (%ecx),%edx
f0103d96:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103d99:	89 f3                	mov    %esi,%ebx
f0103d9b:	80 fb 09             	cmp    $0x9,%bl
f0103d9e:	77 d5                	ja     f0103d75 <strtol+0x80>
			dig = *s - '0';
f0103da0:	0f be d2             	movsbl %dl,%edx
f0103da3:	83 ea 30             	sub    $0x30,%edx
f0103da6:	eb dd                	jmp    f0103d85 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0103da8:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103dab:	89 f3                	mov    %esi,%ebx
f0103dad:	80 fb 19             	cmp    $0x19,%bl
f0103db0:	77 08                	ja     f0103dba <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103db2:	0f be d2             	movsbl %dl,%edx
f0103db5:	83 ea 37             	sub    $0x37,%edx
f0103db8:	eb cb                	jmp    f0103d85 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103dba:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103dbe:	74 05                	je     f0103dc5 <strtol+0xd0>
		*endptr = (char *) s;
f0103dc0:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103dc3:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103dc5:	89 c2                	mov    %eax,%edx
f0103dc7:	f7 da                	neg    %edx
f0103dc9:	85 ff                	test   %edi,%edi
f0103dcb:	0f 45 c2             	cmovne %edx,%eax
}
f0103dce:	5b                   	pop    %ebx
f0103dcf:	5e                   	pop    %esi
f0103dd0:	5f                   	pop    %edi
f0103dd1:	5d                   	pop    %ebp
f0103dd2:	c3                   	ret    
f0103dd3:	66 90                	xchg   %ax,%ax
f0103dd5:	66 90                	xchg   %ax,%ax
f0103dd7:	66 90                	xchg   %ax,%ax
f0103dd9:	66 90                	xchg   %ax,%ax
f0103ddb:	66 90                	xchg   %ax,%ax
f0103ddd:	66 90                	xchg   %ax,%ax
f0103ddf:	90                   	nop

f0103de0 <__udivdi3>:
f0103de0:	55                   	push   %ebp
f0103de1:	57                   	push   %edi
f0103de2:	56                   	push   %esi
f0103de3:	53                   	push   %ebx
f0103de4:	83 ec 1c             	sub    $0x1c,%esp
f0103de7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103deb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0103def:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103df3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0103df7:	85 d2                	test   %edx,%edx
f0103df9:	75 35                	jne    f0103e30 <__udivdi3+0x50>
f0103dfb:	39 f3                	cmp    %esi,%ebx
f0103dfd:	0f 87 bd 00 00 00    	ja     f0103ec0 <__udivdi3+0xe0>
f0103e03:	85 db                	test   %ebx,%ebx
f0103e05:	89 d9                	mov    %ebx,%ecx
f0103e07:	75 0b                	jne    f0103e14 <__udivdi3+0x34>
f0103e09:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e0e:	31 d2                	xor    %edx,%edx
f0103e10:	f7 f3                	div    %ebx
f0103e12:	89 c1                	mov    %eax,%ecx
f0103e14:	31 d2                	xor    %edx,%edx
f0103e16:	89 f0                	mov    %esi,%eax
f0103e18:	f7 f1                	div    %ecx
f0103e1a:	89 c6                	mov    %eax,%esi
f0103e1c:	89 e8                	mov    %ebp,%eax
f0103e1e:	89 f7                	mov    %esi,%edi
f0103e20:	f7 f1                	div    %ecx
f0103e22:	89 fa                	mov    %edi,%edx
f0103e24:	83 c4 1c             	add    $0x1c,%esp
f0103e27:	5b                   	pop    %ebx
f0103e28:	5e                   	pop    %esi
f0103e29:	5f                   	pop    %edi
f0103e2a:	5d                   	pop    %ebp
f0103e2b:	c3                   	ret    
f0103e2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e30:	39 f2                	cmp    %esi,%edx
f0103e32:	77 7c                	ja     f0103eb0 <__udivdi3+0xd0>
f0103e34:	0f bd fa             	bsr    %edx,%edi
f0103e37:	83 f7 1f             	xor    $0x1f,%edi
f0103e3a:	0f 84 98 00 00 00    	je     f0103ed8 <__udivdi3+0xf8>
f0103e40:	89 f9                	mov    %edi,%ecx
f0103e42:	b8 20 00 00 00       	mov    $0x20,%eax
f0103e47:	29 f8                	sub    %edi,%eax
f0103e49:	d3 e2                	shl    %cl,%edx
f0103e4b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103e4f:	89 c1                	mov    %eax,%ecx
f0103e51:	89 da                	mov    %ebx,%edx
f0103e53:	d3 ea                	shr    %cl,%edx
f0103e55:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103e59:	09 d1                	or     %edx,%ecx
f0103e5b:	89 f2                	mov    %esi,%edx
f0103e5d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103e61:	89 f9                	mov    %edi,%ecx
f0103e63:	d3 e3                	shl    %cl,%ebx
f0103e65:	89 c1                	mov    %eax,%ecx
f0103e67:	d3 ea                	shr    %cl,%edx
f0103e69:	89 f9                	mov    %edi,%ecx
f0103e6b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103e6f:	d3 e6                	shl    %cl,%esi
f0103e71:	89 eb                	mov    %ebp,%ebx
f0103e73:	89 c1                	mov    %eax,%ecx
f0103e75:	d3 eb                	shr    %cl,%ebx
f0103e77:	09 de                	or     %ebx,%esi
f0103e79:	89 f0                	mov    %esi,%eax
f0103e7b:	f7 74 24 08          	divl   0x8(%esp)
f0103e7f:	89 d6                	mov    %edx,%esi
f0103e81:	89 c3                	mov    %eax,%ebx
f0103e83:	f7 64 24 0c          	mull   0xc(%esp)
f0103e87:	39 d6                	cmp    %edx,%esi
f0103e89:	72 0c                	jb     f0103e97 <__udivdi3+0xb7>
f0103e8b:	89 f9                	mov    %edi,%ecx
f0103e8d:	d3 e5                	shl    %cl,%ebp
f0103e8f:	39 c5                	cmp    %eax,%ebp
f0103e91:	73 5d                	jae    f0103ef0 <__udivdi3+0x110>
f0103e93:	39 d6                	cmp    %edx,%esi
f0103e95:	75 59                	jne    f0103ef0 <__udivdi3+0x110>
f0103e97:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0103e9a:	31 ff                	xor    %edi,%edi
f0103e9c:	89 fa                	mov    %edi,%edx
f0103e9e:	83 c4 1c             	add    $0x1c,%esp
f0103ea1:	5b                   	pop    %ebx
f0103ea2:	5e                   	pop    %esi
f0103ea3:	5f                   	pop    %edi
f0103ea4:	5d                   	pop    %ebp
f0103ea5:	c3                   	ret    
f0103ea6:	8d 76 00             	lea    0x0(%esi),%esi
f0103ea9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0103eb0:	31 ff                	xor    %edi,%edi
f0103eb2:	31 c0                	xor    %eax,%eax
f0103eb4:	89 fa                	mov    %edi,%edx
f0103eb6:	83 c4 1c             	add    $0x1c,%esp
f0103eb9:	5b                   	pop    %ebx
f0103eba:	5e                   	pop    %esi
f0103ebb:	5f                   	pop    %edi
f0103ebc:	5d                   	pop    %ebp
f0103ebd:	c3                   	ret    
f0103ebe:	66 90                	xchg   %ax,%ax
f0103ec0:	31 ff                	xor    %edi,%edi
f0103ec2:	89 e8                	mov    %ebp,%eax
f0103ec4:	89 f2                	mov    %esi,%edx
f0103ec6:	f7 f3                	div    %ebx
f0103ec8:	89 fa                	mov    %edi,%edx
f0103eca:	83 c4 1c             	add    $0x1c,%esp
f0103ecd:	5b                   	pop    %ebx
f0103ece:	5e                   	pop    %esi
f0103ecf:	5f                   	pop    %edi
f0103ed0:	5d                   	pop    %ebp
f0103ed1:	c3                   	ret    
f0103ed2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ed8:	39 f2                	cmp    %esi,%edx
f0103eda:	72 06                	jb     f0103ee2 <__udivdi3+0x102>
f0103edc:	31 c0                	xor    %eax,%eax
f0103ede:	39 eb                	cmp    %ebp,%ebx
f0103ee0:	77 d2                	ja     f0103eb4 <__udivdi3+0xd4>
f0103ee2:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ee7:	eb cb                	jmp    f0103eb4 <__udivdi3+0xd4>
f0103ee9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103ef0:	89 d8                	mov    %ebx,%eax
f0103ef2:	31 ff                	xor    %edi,%edi
f0103ef4:	eb be                	jmp    f0103eb4 <__udivdi3+0xd4>
f0103ef6:	66 90                	xchg   %ax,%ax
f0103ef8:	66 90                	xchg   %ax,%ax
f0103efa:	66 90                	xchg   %ax,%ax
f0103efc:	66 90                	xchg   %ax,%ax
f0103efe:	66 90                	xchg   %ax,%ax

f0103f00 <__umoddi3>:
f0103f00:	55                   	push   %ebp
f0103f01:	57                   	push   %edi
f0103f02:	56                   	push   %esi
f0103f03:	53                   	push   %ebx
f0103f04:	83 ec 1c             	sub    $0x1c,%esp
f0103f07:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0103f0b:	8b 74 24 30          	mov    0x30(%esp),%esi
f0103f0f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0103f13:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103f17:	85 ed                	test   %ebp,%ebp
f0103f19:	89 f0                	mov    %esi,%eax
f0103f1b:	89 da                	mov    %ebx,%edx
f0103f1d:	75 19                	jne    f0103f38 <__umoddi3+0x38>
f0103f1f:	39 df                	cmp    %ebx,%edi
f0103f21:	0f 86 b1 00 00 00    	jbe    f0103fd8 <__umoddi3+0xd8>
f0103f27:	f7 f7                	div    %edi
f0103f29:	89 d0                	mov    %edx,%eax
f0103f2b:	31 d2                	xor    %edx,%edx
f0103f2d:	83 c4 1c             	add    $0x1c,%esp
f0103f30:	5b                   	pop    %ebx
f0103f31:	5e                   	pop    %esi
f0103f32:	5f                   	pop    %edi
f0103f33:	5d                   	pop    %ebp
f0103f34:	c3                   	ret    
f0103f35:	8d 76 00             	lea    0x0(%esi),%esi
f0103f38:	39 dd                	cmp    %ebx,%ebp
f0103f3a:	77 f1                	ja     f0103f2d <__umoddi3+0x2d>
f0103f3c:	0f bd cd             	bsr    %ebp,%ecx
f0103f3f:	83 f1 1f             	xor    $0x1f,%ecx
f0103f42:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103f46:	0f 84 b4 00 00 00    	je     f0104000 <__umoddi3+0x100>
f0103f4c:	b8 20 00 00 00       	mov    $0x20,%eax
f0103f51:	89 c2                	mov    %eax,%edx
f0103f53:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103f57:	29 c2                	sub    %eax,%edx
f0103f59:	89 c1                	mov    %eax,%ecx
f0103f5b:	89 f8                	mov    %edi,%eax
f0103f5d:	d3 e5                	shl    %cl,%ebp
f0103f5f:	89 d1                	mov    %edx,%ecx
f0103f61:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103f65:	d3 e8                	shr    %cl,%eax
f0103f67:	09 c5                	or     %eax,%ebp
f0103f69:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103f6d:	89 c1                	mov    %eax,%ecx
f0103f6f:	d3 e7                	shl    %cl,%edi
f0103f71:	89 d1                	mov    %edx,%ecx
f0103f73:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103f77:	89 df                	mov    %ebx,%edi
f0103f79:	d3 ef                	shr    %cl,%edi
f0103f7b:	89 c1                	mov    %eax,%ecx
f0103f7d:	89 f0                	mov    %esi,%eax
f0103f7f:	d3 e3                	shl    %cl,%ebx
f0103f81:	89 d1                	mov    %edx,%ecx
f0103f83:	89 fa                	mov    %edi,%edx
f0103f85:	d3 e8                	shr    %cl,%eax
f0103f87:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103f8c:	09 d8                	or     %ebx,%eax
f0103f8e:	f7 f5                	div    %ebp
f0103f90:	d3 e6                	shl    %cl,%esi
f0103f92:	89 d1                	mov    %edx,%ecx
f0103f94:	f7 64 24 08          	mull   0x8(%esp)
f0103f98:	39 d1                	cmp    %edx,%ecx
f0103f9a:	89 c3                	mov    %eax,%ebx
f0103f9c:	89 d7                	mov    %edx,%edi
f0103f9e:	72 06                	jb     f0103fa6 <__umoddi3+0xa6>
f0103fa0:	75 0e                	jne    f0103fb0 <__umoddi3+0xb0>
f0103fa2:	39 c6                	cmp    %eax,%esi
f0103fa4:	73 0a                	jae    f0103fb0 <__umoddi3+0xb0>
f0103fa6:	2b 44 24 08          	sub    0x8(%esp),%eax
f0103faa:	19 ea                	sbb    %ebp,%edx
f0103fac:	89 d7                	mov    %edx,%edi
f0103fae:	89 c3                	mov    %eax,%ebx
f0103fb0:	89 ca                	mov    %ecx,%edx
f0103fb2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0103fb7:	29 de                	sub    %ebx,%esi
f0103fb9:	19 fa                	sbb    %edi,%edx
f0103fbb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0103fbf:	89 d0                	mov    %edx,%eax
f0103fc1:	d3 e0                	shl    %cl,%eax
f0103fc3:	89 d9                	mov    %ebx,%ecx
f0103fc5:	d3 ee                	shr    %cl,%esi
f0103fc7:	d3 ea                	shr    %cl,%edx
f0103fc9:	09 f0                	or     %esi,%eax
f0103fcb:	83 c4 1c             	add    $0x1c,%esp
f0103fce:	5b                   	pop    %ebx
f0103fcf:	5e                   	pop    %esi
f0103fd0:	5f                   	pop    %edi
f0103fd1:	5d                   	pop    %ebp
f0103fd2:	c3                   	ret    
f0103fd3:	90                   	nop
f0103fd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103fd8:	85 ff                	test   %edi,%edi
f0103fda:	89 f9                	mov    %edi,%ecx
f0103fdc:	75 0b                	jne    f0103fe9 <__umoddi3+0xe9>
f0103fde:	b8 01 00 00 00       	mov    $0x1,%eax
f0103fe3:	31 d2                	xor    %edx,%edx
f0103fe5:	f7 f7                	div    %edi
f0103fe7:	89 c1                	mov    %eax,%ecx
f0103fe9:	89 d8                	mov    %ebx,%eax
f0103feb:	31 d2                	xor    %edx,%edx
f0103fed:	f7 f1                	div    %ecx
f0103fef:	89 f0                	mov    %esi,%eax
f0103ff1:	f7 f1                	div    %ecx
f0103ff3:	e9 31 ff ff ff       	jmp    f0103f29 <__umoddi3+0x29>
f0103ff8:	90                   	nop
f0103ff9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104000:	39 dd                	cmp    %ebx,%ebp
f0104002:	72 08                	jb     f010400c <__umoddi3+0x10c>
f0104004:	39 f7                	cmp    %esi,%edi
f0104006:	0f 87 21 ff ff ff    	ja     f0103f2d <__umoddi3+0x2d>
f010400c:	89 da                	mov    %ebx,%edx
f010400e:	89 f0                	mov    %esi,%eax
f0104010:	29 f8                	sub    %edi,%eax
f0104012:	19 ea                	sbb    %ebp,%edx
f0104014:	e9 14 ff ff ff       	jmp    f0103f2d <__umoddi3+0x2d>
