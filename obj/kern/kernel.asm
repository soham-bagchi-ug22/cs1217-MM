
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
f0100015:	b8 00 30 11 00       	mov    $0x113000,%eax
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
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

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
f010004c:	81 c3 bc 22 01 00    	add    $0x122bc,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 40 11 f0    	mov    $0xf0114060,%edx
f0100058:	c7 c0 a0 46 11 f0    	mov    $0xf01146a0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 76 17 00 00       	call   f01017df <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 18 f9 fe ff    	lea    -0x106e8(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 fd 0b 00 00       	call   f0100c7f <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 14 0a 00 00       	call   f0100a9b <mem_init>
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
f01000a7:	81 c3 61 22 01 00    	add    $0x12261,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 a4 46 11 f0    	mov    $0xf01146a4,%eax
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
f01000da:	8d 83 33 f9 fe ff    	lea    -0x106cd(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 99 0b 00 00       	call   f0100c7f <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 58 0b 00 00       	call   f0100c48 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 6f f9 fe ff    	lea    -0x10691(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 81 0b 00 00       	call   f0100c7f <cprintf>
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
f010010d:	81 c3 fb 21 01 00    	add    $0x121fb,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 4b f9 fe ff    	lea    -0x106b5(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 54 0b 00 00       	call   f0100c7f <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 11 0b 00 00       	call   f0100c48 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 6f f9 fe ff    	lea    -0x10691(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 3a 0b 00 00       	call   f0100c7f <cprintf>
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
f010017c:	81 c3 8c 21 01 00    	add    $0x1218c,%ebx
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
f01001c7:	81 c3 41 21 01 00    	add    $0x12141,%ebx
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
f0100217:	0f b6 84 13 98 fa fe 	movzbl -0x10568(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 98 f9 fe 	movzbl -0x10668(%ebx,%edx,1),%ecx
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
f010026a:	8d 83 65 f9 fe ff    	lea    -0x1069b(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 09 0a 00 00       	call   f0100c7f <cprintf>
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
f01002b1:	0f b6 84 13 98 fa fe 	movzbl -0x10568(%ebx,%edx,1),%eax
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
f01002fd:	81 c3 0b 20 01 00    	add    $0x1200b,%ebx
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
f01004d2:	e8 55 13 00 00       	call   f010182c <memmove>
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
f010050a:	05 fe 1d 01 00       	add    $0x11dfe,%eax
	if (serial_exists)
f010050f:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 4b de fe ff    	lea    -0x121b5(%eax),%eax
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
f0100538:	05 d0 1d 01 00       	add    $0x11dd0,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b5 de fe ff    	lea    -0x1214b(%eax),%eax
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
f0100556:	81 c3 b2 1d 01 00    	add    $0x11db2,%ebx
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
f01005b2:	81 c3 56 1d 01 00    	add    $0x11d56,%ebx
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
f01006b5:	8d 83 71 f9 fe ff    	lea    -0x1068f(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 be 05 00 00       	call   f0100c7f <cprintf>
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
f01006ff:	81 c3 09 1c 01 00    	add    $0x11c09,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 98 fb fe ff    	lea    -0x10468(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 b6 fb fe ff    	lea    -0x1044a(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 bb fb fe ff    	lea    -0x10445(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 5d 05 00 00       	call   f0100c7f <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 24 fc fe ff    	lea    -0x103dc(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 c4 fb fe ff    	lea    -0x1043c(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 46 05 00 00       	call   f0100c7f <cprintf>
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
f0100753:	81 c3 b5 1b 01 00    	add    $0x11bb5,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100759:	8d 83 cd fb fe ff    	lea    -0x10433(%ebx),%eax
f010075f:	50                   	push   %eax
f0100760:	e8 1a 05 00 00       	call   f0100c7f <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100765:	83 c4 08             	add    $0x8,%esp
f0100768:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010076e:	8d 83 4c fc fe ff    	lea    -0x103b4(%ebx),%eax
f0100774:	50                   	push   %eax
f0100775:	e8 05 05 00 00       	call   f0100c7f <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010077a:	83 c4 0c             	add    $0xc,%esp
f010077d:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100783:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100789:	50                   	push   %eax
f010078a:	57                   	push   %edi
f010078b:	8d 83 74 fc fe ff    	lea    -0x1038c(%ebx),%eax
f0100791:	50                   	push   %eax
f0100792:	e8 e8 04 00 00       	call   f0100c7f <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100797:	83 c4 0c             	add    $0xc,%esp
f010079a:	c7 c0 19 1c 10 f0    	mov    $0xf0101c19,%eax
f01007a0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007a6:	52                   	push   %edx
f01007a7:	50                   	push   %eax
f01007a8:	8d 83 98 fc fe ff    	lea    -0x10368(%ebx),%eax
f01007ae:	50                   	push   %eax
f01007af:	e8 cb 04 00 00       	call   f0100c7f <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007b4:	83 c4 0c             	add    $0xc,%esp
f01007b7:	c7 c0 60 40 11 f0    	mov    $0xf0114060,%eax
f01007bd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007c3:	52                   	push   %edx
f01007c4:	50                   	push   %eax
f01007c5:	8d 83 bc fc fe ff    	lea    -0x10344(%ebx),%eax
f01007cb:	50                   	push   %eax
f01007cc:	e8 ae 04 00 00       	call   f0100c7f <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007d1:	83 c4 0c             	add    $0xc,%esp
f01007d4:	c7 c6 a0 46 11 f0    	mov    $0xf01146a0,%esi
f01007da:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007e0:	50                   	push   %eax
f01007e1:	56                   	push   %esi
f01007e2:	8d 83 e0 fc fe ff    	lea    -0x10320(%ebx),%eax
f01007e8:	50                   	push   %eax
f01007e9:	e8 91 04 00 00       	call   f0100c7f <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007ee:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007f1:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f01007f7:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f9:	c1 fe 0a             	sar    $0xa,%esi
f01007fc:	56                   	push   %esi
f01007fd:	8d 83 04 fd fe ff    	lea    -0x102fc(%ebx),%eax
f0100803:	50                   	push   %eax
f0100804:	e8 76 04 00 00       	call   f0100c7f <cprintf>
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
f010082e:	81 c3 da 1a 01 00    	add    $0x11ada,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100834:	8d 83 30 fd fe ff    	lea    -0x102d0(%ebx),%eax
f010083a:	50                   	push   %eax
f010083b:	e8 3f 04 00 00       	call   f0100c7f <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100840:	8d 83 54 fd fe ff    	lea    -0x102ac(%ebx),%eax
f0100846:	89 04 24             	mov    %eax,(%esp)
f0100849:	e8 31 04 00 00       	call   f0100c7f <cprintf>
f010084e:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100851:	8d bb ea fb fe ff    	lea    -0x10416(%ebx),%edi
f0100857:	eb 4a                	jmp    f01008a3 <monitor+0x83>
f0100859:	83 ec 08             	sub    $0x8,%esp
f010085c:	0f be c0             	movsbl %al,%eax
f010085f:	50                   	push   %eax
f0100860:	57                   	push   %edi
f0100861:	e8 3c 0f 00 00       	call   f01017a2 <strchr>
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
f0100894:	8d 83 ef fb fe ff    	lea    -0x10411(%ebx),%eax
f010089a:	50                   	push   %eax
f010089b:	e8 df 03 00 00       	call   f0100c7f <cprintf>
f01008a0:	83 c4 10             	add    $0x10,%esp
	//cprintf("%d %d\n", sizeof(char), sizeof(int)); 
	// Nikhil won lol


	while (1) {
		buf = readline("K> ");
f01008a3:	8d 83 e6 fb fe ff    	lea    -0x1041a(%ebx),%eax
f01008a9:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01008ac:	83 ec 0c             	sub    $0xc,%esp
f01008af:	ff 75 a4             	pushl  -0x5c(%ebp)
f01008b2:	e8 b3 0c 00 00       	call   f010156a <readline>
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
f01008e2:	e8 bb 0e 00 00       	call   f01017a2 <strchr>
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
f010090b:	8d 83 b6 fb fe ff    	lea    -0x1044a(%ebx),%eax
f0100911:	50                   	push   %eax
f0100912:	ff 75 a8             	pushl  -0x58(%ebp)
f0100915:	e8 2a 0e 00 00       	call   f0101744 <strcmp>
f010091a:	83 c4 10             	add    $0x10,%esp
f010091d:	85 c0                	test   %eax,%eax
f010091f:	74 38                	je     f0100959 <monitor+0x139>
f0100921:	83 ec 08             	sub    $0x8,%esp
f0100924:	8d 83 c4 fb fe ff    	lea    -0x1043c(%ebx),%eax
f010092a:	50                   	push   %eax
f010092b:	ff 75 a8             	pushl  -0x58(%ebp)
f010092e:	e8 11 0e 00 00       	call   f0101744 <strcmp>
f0100933:	83 c4 10             	add    $0x10,%esp
f0100936:	85 c0                	test   %eax,%eax
f0100938:	74 1a                	je     f0100954 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f010093a:	83 ec 08             	sub    $0x8,%esp
f010093d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100940:	8d 83 0c fc fe ff    	lea    -0x103f4(%ebx),%eax
f0100946:	50                   	push   %eax
f0100947:	e8 33 03 00 00       	call   f0100c7f <cprintf>
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

f0100983 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
f0100986:	53                   	push   %ebx
f0100987:	83 ec 04             	sub    $0x4,%esp
f010098a:	e8 c0 f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010098f:	81 c3 79 19 01 00    	add    $0x11979,%ebx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100995:	83 bb 90 1f 00 00 00 	cmpl   $0x0,0x1f90(%ebx)
f010099c:	74 1e                	je     f01009bc <boot_alloc+0x39>
	//
	// LAB 2: Your code here.

	// If n==0, returns the address of the next free page without allocating
	// anything.
	if(n == 0){ 
f010099e:	85 c0                	test   %eax,%eax
f01009a0:	74 34                	je     f01009d6 <boot_alloc+0x53>
		//         HEX    f    0    0    0    0    0    0    0
		// LIMIT is    1111 1111 1111 1111 1111 1111 1111 1111
		//         HEX    f    f    f    f    f    f    f    f
		
		// nextfree is already at a page granularity
		uint32_t pageAddress = ROUNDUP(n, PGSIZE);
f01009a2:	05 ff 0f 00 00       	add    $0xfff,%eax
		uint32_t finalAddress = ((uint32_t) nextfree + pageAddress);
f01009a7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009ac:	03 83 90 1f 00 00    	add    0x1f90(%ebx),%eax
		
		if(finalAddress >= 0xffffffff)
f01009b2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01009b5:	74 27                	je     f01009de <boot_alloc+0x5b>
		//cprintf("fin: %x\n", (int) finalAddress); // used this to identify which portion of memory the pages get allocated in
		return (char *) finalAddress;
	}

	return NULL;
}
f01009b7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01009ba:	c9                   	leave  
f01009bb:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009bc:	c7 c2 a0 46 11 f0    	mov    $0xf01146a0,%edx
f01009c2:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f01009c8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009ce:	89 93 90 1f 00 00    	mov    %edx,0x1f90(%ebx)
f01009d4:	eb c8                	jmp    f010099e <boot_alloc+0x1b>
		return nextfree;
f01009d6:	8b 83 90 1f 00 00    	mov    0x1f90(%ebx),%eax
f01009dc:	eb d9                	jmp    f01009b7 <boot_alloc+0x34>
			panic("out of memory\n");
f01009de:	83 ec 04             	sub    $0x4,%esp
f01009e1:	8d 83 79 fd fe ff    	lea    -0x10287(%ebx),%eax
f01009e7:	50                   	push   %eax
f01009e8:	6a 7e                	push   $0x7e
f01009ea:	8d 83 88 fd fe ff    	lea    -0x10278(%ebx),%eax
f01009f0:	50                   	push   %eax
f01009f1:	e8 a3 f6 ff ff       	call   f0100099 <_panic>

f01009f6 <nvram_read>:
{
f01009f6:	55                   	push   %ebp
f01009f7:	89 e5                	mov    %esp,%ebp
f01009f9:	57                   	push   %edi
f01009fa:	56                   	push   %esi
f01009fb:	53                   	push   %ebx
f01009fc:	83 ec 18             	sub    $0x18,%esp
f01009ff:	e8 4b f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100a04:	81 c3 04 19 01 00    	add    $0x11904,%ebx
f0100a0a:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a0c:	50                   	push   %eax
f0100a0d:	e8 e6 01 00 00       	call   f0100bf8 <mc146818_read>
f0100a12:	89 c6                	mov    %eax,%esi
f0100a14:	83 c7 01             	add    $0x1,%edi
f0100a17:	89 3c 24             	mov    %edi,(%esp)
f0100a1a:	e8 d9 01 00 00       	call   f0100bf8 <mc146818_read>
f0100a1f:	c1 e0 08             	shl    $0x8,%eax
f0100a22:	09 f0                	or     %esi,%eax
}
f0100a24:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a27:	5b                   	pop    %ebx
f0100a28:	5e                   	pop    %esi
f0100a29:	5f                   	pop    %edi
f0100a2a:	5d                   	pop    %ebp
f0100a2b:	c3                   	ret    

f0100a2c <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100a2c:	55                   	push   %ebp
f0100a2d:	89 e5                	mov    %esp,%ebp
f0100a2f:	57                   	push   %edi
f0100a30:	56                   	push   %esi
f0100a31:	53                   	push   %ebx
f0100a32:	83 ec 04             	sub    $0x4,%esp
f0100a35:	e8 ba 01 00 00       	call   f0100bf4 <__x86.get_pc_thunk.si>
f0100a3a:	81 c6 ce 18 01 00    	add    $0x118ce,%esi
f0100a40:	89 75 f0             	mov    %esi,-0x10(%ebp)
f0100a43:	8b 9e 94 1f 00 00    	mov    0x1f94(%esi),%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100a49:	ba 00 00 00 00       	mov    $0x0,%edx
f0100a4e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a53:	c7 c7 a8 46 11 f0    	mov    $0xf01146a8,%edi
		pages[i].pp_ref = 0;
f0100a59:	c7 c6 b0 46 11 f0    	mov    $0xf01146b0,%esi
	for (i = 0; i < npages; i++) {
f0100a5f:	eb 1f                	jmp    f0100a80 <page_init+0x54>
f0100a61:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100a68:	89 d1                	mov    %edx,%ecx
f0100a6a:	03 0e                	add    (%esi),%ecx
f0100a6c:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100a72:	89 19                	mov    %ebx,(%ecx)
	for (i = 0; i < npages; i++) {
f0100a74:	83 c0 01             	add    $0x1,%eax
		page_free_list = &pages[i];
f0100a77:	89 d3                	mov    %edx,%ebx
f0100a79:	03 1e                	add    (%esi),%ebx
f0100a7b:	ba 01 00 00 00       	mov    $0x1,%edx
	for (i = 0; i < npages; i++) {
f0100a80:	39 07                	cmp    %eax,(%edi)
f0100a82:	77 dd                	ja     f0100a61 <page_init+0x35>
f0100a84:	84 d2                	test   %dl,%dl
f0100a86:	75 08                	jne    f0100a90 <page_init+0x64>
	}
}
f0100a88:	83 c4 04             	add    $0x4,%esp
f0100a8b:	5b                   	pop    %ebx
f0100a8c:	5e                   	pop    %esi
f0100a8d:	5f                   	pop    %edi
f0100a8e:	5d                   	pop    %ebp
f0100a8f:	c3                   	ret    
f0100a90:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a93:	89 98 94 1f 00 00    	mov    %ebx,0x1f94(%eax)
f0100a99:	eb ed                	jmp    f0100a88 <page_init+0x5c>

f0100a9b <mem_init>:
{
f0100a9b:	55                   	push   %ebp
f0100a9c:	89 e5                	mov    %esp,%ebp
f0100a9e:	57                   	push   %edi
f0100a9f:	56                   	push   %esi
f0100aa0:	53                   	push   %ebx
f0100aa1:	83 ec 0c             	sub    $0xc,%esp
f0100aa4:	e8 a6 f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100aa9:	81 c3 5f 18 01 00    	add    $0x1185f,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f0100aaf:	b8 15 00 00 00       	mov    $0x15,%eax
f0100ab4:	e8 3d ff ff ff       	call   f01009f6 <nvram_read>
f0100ab9:	89 c6                	mov    %eax,%esi
	extmem = nvram_read(NVRAM_EXTLO);
f0100abb:	b8 17 00 00 00       	mov    $0x17,%eax
f0100ac0:	e8 31 ff ff ff       	call   f01009f6 <nvram_read>
f0100ac5:	89 c7                	mov    %eax,%edi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100ac7:	b8 34 00 00 00       	mov    $0x34,%eax
f0100acc:	e8 25 ff ff ff       	call   f01009f6 <nvram_read>
f0100ad1:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0100ad4:	85 c0                	test   %eax,%eax
f0100ad6:	75 0e                	jne    f0100ae6 <mem_init+0x4b>
		totalmem = basemem;
f0100ad8:	89 f0                	mov    %esi,%eax
	else if (extmem)
f0100ada:	85 ff                	test   %edi,%edi
f0100adc:	74 0d                	je     f0100aeb <mem_init+0x50>
		totalmem = 1 * 1024 + extmem;
f0100ade:	8d 87 00 04 00 00    	lea    0x400(%edi),%eax
f0100ae4:	eb 05                	jmp    f0100aeb <mem_init+0x50>
		totalmem = 16 * 1024 + ext16mem;
f0100ae6:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f0100aeb:	89 c1                	mov    %eax,%ecx
f0100aed:	c1 e9 02             	shr    $0x2,%ecx
f0100af0:	c7 c2 a8 46 11 f0    	mov    $0xf01146a8,%edx
f0100af6:	89 0a                	mov    %ecx,(%edx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100af8:	89 c2                	mov    %eax,%edx
f0100afa:	29 f2                	sub    %esi,%edx
f0100afc:	52                   	push   %edx
f0100afd:	56                   	push   %esi
f0100afe:	50                   	push   %eax
f0100aff:	8d 83 94 fd fe ff    	lea    -0x1026c(%ebx),%eax
f0100b05:	50                   	push   %eax
f0100b06:	e8 74 01 00 00       	call   f0100c7f <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100b0b:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100b10:	e8 6e fe ff ff       	call   f0100983 <boot_alloc>
f0100b15:	c7 c6 ac 46 11 f0    	mov    $0xf01146ac,%esi
f0100b1b:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f0100b1d:	83 c4 0c             	add    $0xc,%esp
f0100b20:	68 00 10 00 00       	push   $0x1000
f0100b25:	6a 00                	push   $0x0
f0100b27:	50                   	push   %eax
f0100b28:	e8 b2 0c 00 00       	call   f01017df <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100b2d:	8b 06                	mov    (%esi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b2f:	83 c4 10             	add    $0x10,%esp
f0100b32:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100b37:	77 19                	ja     f0100b52 <mem_init+0xb7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b39:	50                   	push   %eax
f0100b3a:	8d 83 d0 fd fe ff    	lea    -0x10230(%ebx),%eax
f0100b40:	50                   	push   %eax
f0100b41:	68 a8 00 00 00       	push   $0xa8
f0100b46:	8d 83 88 fd fe ff    	lea    -0x10278(%ebx),%eax
f0100b4c:	50                   	push   %eax
f0100b4d:	e8 47 f5 ff ff       	call   f0100099 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100b52:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100b58:	83 ca 05             	or     $0x5,%edx
f0100b5b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0100b61:	c7 c6 a8 46 11 f0    	mov    $0xf01146a8,%esi
f0100b67:	8b 06                	mov    (%esi),%eax
f0100b69:	c1 e0 03             	shl    $0x3,%eax
f0100b6c:	e8 12 fe ff ff       	call   f0100983 <boot_alloc>
f0100b71:	c7 c2 b0 46 11 f0    	mov    $0xf01146b0,%edx
f0100b77:	89 02                	mov    %eax,(%edx)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0100b79:	83 ec 04             	sub    $0x4,%esp
f0100b7c:	8b 16                	mov    (%esi),%edx
f0100b7e:	c1 e2 03             	shl    $0x3,%edx
f0100b81:	52                   	push   %edx
f0100b82:	6a 00                	push   $0x0
f0100b84:	50                   	push   %eax
f0100b85:	e8 55 0c 00 00       	call   f01017df <memset>
	page_init();
f0100b8a:	e8 9d fe ff ff       	call   f0100a2c <page_init>
	panic("mem_init: This function is not finished\n");
f0100b8f:	83 c4 0c             	add    $0xc,%esp
f0100b92:	8d 83 f4 fd fe ff    	lea    -0x1020c(%ebx),%eax
f0100b98:	50                   	push   %eax
f0100b99:	68 c2 00 00 00       	push   $0xc2
f0100b9e:	8d 83 88 fd fe ff    	lea    -0x10278(%ebx),%eax
f0100ba4:	50                   	push   %eax
f0100ba5:	e8 ef f4 ff ff       	call   f0100099 <_panic>

f0100baa <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100baa:	55                   	push   %ebp
f0100bab:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100bad:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bb2:	5d                   	pop    %ebp
f0100bb3:	c3                   	ret    

f0100bb4 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100bb4:	55                   	push   %ebp
f0100bb5:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f0100bb7:	5d                   	pop    %ebp
f0100bb8:	c3                   	ret    

f0100bb9 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100bb9:	55                   	push   %ebp
f0100bba:	89 e5                	mov    %esp,%ebp
f0100bbc:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100bbf:	66 83 68 04 01       	subw   $0x1,0x4(%eax)
		page_free(pp);
}
f0100bc4:	5d                   	pop    %ebp
f0100bc5:	c3                   	ret    

f0100bc6 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100bc6:	55                   	push   %ebp
f0100bc7:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100bc9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bce:	5d                   	pop    %ebp
f0100bcf:	c3                   	ret    

f0100bd0 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100bd0:	55                   	push   %ebp
f0100bd1:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100bd3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bd8:	5d                   	pop    %ebp
f0100bd9:	c3                   	ret    

f0100bda <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100bda:	55                   	push   %ebp
f0100bdb:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100bdd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100be2:	5d                   	pop    %ebp
f0100be3:	c3                   	ret    

f0100be4 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100be4:	55                   	push   %ebp
f0100be5:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100be7:	5d                   	pop    %ebp
f0100be8:	c3                   	ret    

f0100be9 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100be9:	55                   	push   %ebp
f0100bea:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100bec:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bef:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100bf2:	5d                   	pop    %ebp
f0100bf3:	c3                   	ret    

f0100bf4 <__x86.get_pc_thunk.si>:
f0100bf4:	8b 34 24             	mov    (%esp),%esi
f0100bf7:	c3                   	ret    

f0100bf8 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100bf8:	55                   	push   %ebp
f0100bf9:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100bfb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100bfe:	ba 70 00 00 00       	mov    $0x70,%edx
f0100c03:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100c04:	ba 71 00 00 00       	mov    $0x71,%edx
f0100c09:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100c0a:	0f b6 c0             	movzbl %al,%eax
}
f0100c0d:	5d                   	pop    %ebp
f0100c0e:	c3                   	ret    

f0100c0f <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100c0f:	55                   	push   %ebp
f0100c10:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100c12:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c15:	ba 70 00 00 00       	mov    $0x70,%edx
f0100c1a:	ee                   	out    %al,(%dx)
f0100c1b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c1e:	ba 71 00 00 00       	mov    $0x71,%edx
f0100c23:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100c24:	5d                   	pop    %ebp
f0100c25:	c3                   	ret    

f0100c26 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100c26:	55                   	push   %ebp
f0100c27:	89 e5                	mov    %esp,%ebp
f0100c29:	53                   	push   %ebx
f0100c2a:	83 ec 10             	sub    $0x10,%esp
f0100c2d:	e8 1d f5 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100c32:	81 c3 d6 16 01 00    	add    $0x116d6,%ebx
	cputchar(ch);
f0100c38:	ff 75 08             	pushl  0x8(%ebp)
f0100c3b:	e8 86 fa ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f0100c40:	83 c4 10             	add    $0x10,%esp
f0100c43:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100c46:	c9                   	leave  
f0100c47:	c3                   	ret    

f0100c48 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100c48:	55                   	push   %ebp
f0100c49:	89 e5                	mov    %esp,%ebp
f0100c4b:	53                   	push   %ebx
f0100c4c:	83 ec 14             	sub    $0x14,%esp
f0100c4f:	e8 fb f4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100c54:	81 c3 b4 16 01 00    	add    $0x116b4,%ebx
	int cnt = 0;
f0100c5a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100c61:	ff 75 0c             	pushl  0xc(%ebp)
f0100c64:	ff 75 08             	pushl  0x8(%ebp)
f0100c67:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100c6a:	50                   	push   %eax
f0100c6b:	8d 83 1e e9 fe ff    	lea    -0x116e2(%ebx),%eax
f0100c71:	50                   	push   %eax
f0100c72:	e8 1c 04 00 00       	call   f0101093 <vprintfmt>
	return cnt;
}
f0100c77:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c7a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100c7d:	c9                   	leave  
f0100c7e:	c3                   	ret    

f0100c7f <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100c7f:	55                   	push   %ebp
f0100c80:	89 e5                	mov    %esp,%ebp
f0100c82:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100c85:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100c88:	50                   	push   %eax
f0100c89:	ff 75 08             	pushl  0x8(%ebp)
f0100c8c:	e8 b7 ff ff ff       	call   f0100c48 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100c91:	c9                   	leave  
f0100c92:	c3                   	ret    

f0100c93 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100c93:	55                   	push   %ebp
f0100c94:	89 e5                	mov    %esp,%ebp
f0100c96:	57                   	push   %edi
f0100c97:	56                   	push   %esi
f0100c98:	53                   	push   %ebx
f0100c99:	83 ec 14             	sub    $0x14,%esp
f0100c9c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100c9f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100ca2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100ca5:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100ca8:	8b 32                	mov    (%edx),%esi
f0100caa:	8b 01                	mov    (%ecx),%eax
f0100cac:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100caf:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100cb6:	eb 2f                	jmp    f0100ce7 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100cb8:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100cbb:	39 c6                	cmp    %eax,%esi
f0100cbd:	7f 49                	jg     f0100d08 <stab_binsearch+0x75>
f0100cbf:	0f b6 0a             	movzbl (%edx),%ecx
f0100cc2:	83 ea 0c             	sub    $0xc,%edx
f0100cc5:	39 f9                	cmp    %edi,%ecx
f0100cc7:	75 ef                	jne    f0100cb8 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100cc9:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100ccc:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100ccf:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100cd3:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100cd6:	73 35                	jae    f0100d0d <stab_binsearch+0x7a>
			*region_left = m;
f0100cd8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100cdb:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100cdd:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100ce0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100ce7:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100cea:	7f 4e                	jg     f0100d3a <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100cec:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100cef:	01 f0                	add    %esi,%eax
f0100cf1:	89 c3                	mov    %eax,%ebx
f0100cf3:	c1 eb 1f             	shr    $0x1f,%ebx
f0100cf6:	01 c3                	add    %eax,%ebx
f0100cf8:	d1 fb                	sar    %ebx
f0100cfa:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100cfd:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100d00:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100d04:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100d06:	eb b3                	jmp    f0100cbb <stab_binsearch+0x28>
			l = true_m + 1;
f0100d08:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100d0b:	eb da                	jmp    f0100ce7 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100d0d:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100d10:	76 14                	jbe    f0100d26 <stab_binsearch+0x93>
			*region_right = m - 1;
f0100d12:	83 e8 01             	sub    $0x1,%eax
f0100d15:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100d18:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100d1b:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100d1d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100d24:	eb c1                	jmp    f0100ce7 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100d26:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100d29:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100d2b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100d2f:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100d31:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100d38:	eb ad                	jmp    f0100ce7 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100d3a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100d3e:	74 16                	je     f0100d56 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d40:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d43:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100d45:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100d48:	8b 0e                	mov    (%esi),%ecx
f0100d4a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100d4d:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100d50:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100d54:	eb 12                	jmp    f0100d68 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100d56:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d59:	8b 00                	mov    (%eax),%eax
f0100d5b:	83 e8 01             	sub    $0x1,%eax
f0100d5e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100d61:	89 07                	mov    %eax,(%edi)
f0100d63:	eb 16                	jmp    f0100d7b <stab_binsearch+0xe8>
		     l--)
f0100d65:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100d68:	39 c1                	cmp    %eax,%ecx
f0100d6a:	7d 0a                	jge    f0100d76 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100d6c:	0f b6 1a             	movzbl (%edx),%ebx
f0100d6f:	83 ea 0c             	sub    $0xc,%edx
f0100d72:	39 fb                	cmp    %edi,%ebx
f0100d74:	75 ef                	jne    f0100d65 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100d76:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d79:	89 07                	mov    %eax,(%edi)
	}
}
f0100d7b:	83 c4 14             	add    $0x14,%esp
f0100d7e:	5b                   	pop    %ebx
f0100d7f:	5e                   	pop    %esi
f0100d80:	5f                   	pop    %edi
f0100d81:	5d                   	pop    %ebp
f0100d82:	c3                   	ret    

f0100d83 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100d83:	55                   	push   %ebp
f0100d84:	89 e5                	mov    %esp,%ebp
f0100d86:	57                   	push   %edi
f0100d87:	56                   	push   %esi
f0100d88:	53                   	push   %ebx
f0100d89:	83 ec 2c             	sub    $0x2c,%esp
f0100d8c:	e8 fa 01 00 00       	call   f0100f8b <__x86.get_pc_thunk.cx>
f0100d91:	81 c1 77 15 01 00    	add    $0x11577,%ecx
f0100d97:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100d9a:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100d9d:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100da0:	8d 81 20 fe fe ff    	lea    -0x101e0(%ecx),%eax
f0100da6:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0100da8:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0100daf:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0100db2:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0100db9:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0100dbc:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100dc3:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0100dc9:	0f 86 f4 00 00 00    	jbe    f0100ec3 <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100dcf:	c7 c0 75 68 10 f0    	mov    $0xf0106875,%eax
f0100dd5:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f0100ddb:	0f 86 88 01 00 00    	jbe    f0100f69 <debuginfo_eip+0x1e6>
f0100de1:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100de4:	c7 c0 c2 84 10 f0    	mov    $0xf01084c2,%eax
f0100dea:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100dee:	0f 85 7c 01 00 00    	jne    f0100f70 <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100df4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100dfb:	c7 c0 44 23 10 f0    	mov    $0xf0102344,%eax
f0100e01:	c7 c2 74 68 10 f0    	mov    $0xf0106874,%edx
f0100e07:	29 c2                	sub    %eax,%edx
f0100e09:	c1 fa 02             	sar    $0x2,%edx
f0100e0c:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100e12:	83 ea 01             	sub    $0x1,%edx
f0100e15:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100e18:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100e1b:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100e1e:	83 ec 08             	sub    $0x8,%esp
f0100e21:	53                   	push   %ebx
f0100e22:	6a 64                	push   $0x64
f0100e24:	e8 6a fe ff ff       	call   f0100c93 <stab_binsearch>
	if (lfile == 0)
f0100e29:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e2c:	83 c4 10             	add    $0x10,%esp
f0100e2f:	85 c0                	test   %eax,%eax
f0100e31:	0f 84 40 01 00 00    	je     f0100f77 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100e37:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100e3a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e3d:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100e40:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100e43:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e46:	83 ec 08             	sub    $0x8,%esp
f0100e49:	53                   	push   %ebx
f0100e4a:	6a 24                	push   $0x24
f0100e4c:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100e4f:	c7 c0 44 23 10 f0    	mov    $0xf0102344,%eax
f0100e55:	e8 39 fe ff ff       	call   f0100c93 <stab_binsearch>

	if (lfun <= rfun) {
f0100e5a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100e5d:	83 c4 10             	add    $0x10,%esp
f0100e60:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0100e63:	7f 79                	jg     f0100ede <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100e65:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100e68:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100e6b:	c7 c2 44 23 10 f0    	mov    $0xf0102344,%edx
f0100e71:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0100e74:	8b 11                	mov    (%ecx),%edx
f0100e76:	c7 c0 c2 84 10 f0    	mov    $0xf01084c2,%eax
f0100e7c:	81 e8 75 68 10 f0    	sub    $0xf0106875,%eax
f0100e82:	39 c2                	cmp    %eax,%edx
f0100e84:	73 09                	jae    f0100e8f <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100e86:	81 c2 75 68 10 f0    	add    $0xf0106875,%edx
f0100e8c:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100e8f:	8b 41 08             	mov    0x8(%ecx),%eax
f0100e92:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100e95:	83 ec 08             	sub    $0x8,%esp
f0100e98:	6a 3a                	push   $0x3a
f0100e9a:	ff 77 08             	pushl  0x8(%edi)
f0100e9d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100ea0:	e8 1e 09 00 00       	call   f01017c3 <strfind>
f0100ea5:	2b 47 08             	sub    0x8(%edi),%eax
f0100ea8:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100eab:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100eae:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100eb1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100eb4:	c7 c2 44 23 10 f0    	mov    $0xf0102344,%edx
f0100eba:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f0100ebe:	83 c4 10             	add    $0x10,%esp
f0100ec1:	eb 29                	jmp    f0100eec <debuginfo_eip+0x169>
  	        panic("User address");
f0100ec3:	83 ec 04             	sub    $0x4,%esp
f0100ec6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100ec9:	8d 83 2a fe fe ff    	lea    -0x101d6(%ebx),%eax
f0100ecf:	50                   	push   %eax
f0100ed0:	6a 7f                	push   $0x7f
f0100ed2:	8d 83 37 fe fe ff    	lea    -0x101c9(%ebx),%eax
f0100ed8:	50                   	push   %eax
f0100ed9:	e8 bb f1 ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f0100ede:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0100ee1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ee4:	eb af                	jmp    f0100e95 <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100ee6:	83 ee 01             	sub    $0x1,%esi
f0100ee9:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100eec:	39 f3                	cmp    %esi,%ebx
f0100eee:	7f 3a                	jg     f0100f2a <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f0100ef0:	0f b6 10             	movzbl (%eax),%edx
f0100ef3:	80 fa 84             	cmp    $0x84,%dl
f0100ef6:	74 0b                	je     f0100f03 <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100ef8:	80 fa 64             	cmp    $0x64,%dl
f0100efb:	75 e9                	jne    f0100ee6 <debuginfo_eip+0x163>
f0100efd:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100f01:	74 e3                	je     f0100ee6 <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100f03:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0100f06:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100f09:	c7 c0 44 23 10 f0    	mov    $0xf0102344,%eax
f0100f0f:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100f12:	c7 c0 c2 84 10 f0    	mov    $0xf01084c2,%eax
f0100f18:	81 e8 75 68 10 f0    	sub    $0xf0106875,%eax
f0100f1e:	39 c2                	cmp    %eax,%edx
f0100f20:	73 08                	jae    f0100f2a <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100f22:	81 c2 75 68 10 f0    	add    $0xf0106875,%edx
f0100f28:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100f2a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100f2d:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100f30:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100f35:	39 cb                	cmp    %ecx,%ebx
f0100f37:	7d 4a                	jge    f0100f83 <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0100f39:	8d 53 01             	lea    0x1(%ebx),%edx
f0100f3c:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f0100f3f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f42:	c7 c0 44 23 10 f0    	mov    $0xf0102344,%eax
f0100f48:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0100f4c:	eb 07                	jmp    f0100f55 <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0100f4e:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0100f52:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0100f55:	39 d1                	cmp    %edx,%ecx
f0100f57:	74 25                	je     f0100f7e <debuginfo_eip+0x1fb>
f0100f59:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100f5c:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0100f60:	74 ec                	je     f0100f4e <debuginfo_eip+0x1cb>
	return 0;
f0100f62:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f67:	eb 1a                	jmp    f0100f83 <debuginfo_eip+0x200>
		return -1;
f0100f69:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100f6e:	eb 13                	jmp    f0100f83 <debuginfo_eip+0x200>
f0100f70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100f75:	eb 0c                	jmp    f0100f83 <debuginfo_eip+0x200>
		return -1;
f0100f77:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100f7c:	eb 05                	jmp    f0100f83 <debuginfo_eip+0x200>
	return 0;
f0100f7e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100f83:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f86:	5b                   	pop    %ebx
f0100f87:	5e                   	pop    %esi
f0100f88:	5f                   	pop    %edi
f0100f89:	5d                   	pop    %ebp
f0100f8a:	c3                   	ret    

f0100f8b <__x86.get_pc_thunk.cx>:
f0100f8b:	8b 0c 24             	mov    (%esp),%ecx
f0100f8e:	c3                   	ret    

f0100f8f <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100f8f:	55                   	push   %ebp
f0100f90:	89 e5                	mov    %esp,%ebp
f0100f92:	57                   	push   %edi
f0100f93:	56                   	push   %esi
f0100f94:	53                   	push   %ebx
f0100f95:	83 ec 2c             	sub    $0x2c,%esp
f0100f98:	e8 ee ff ff ff       	call   f0100f8b <__x86.get_pc_thunk.cx>
f0100f9d:	81 c1 6b 13 01 00    	add    $0x1136b,%ecx
f0100fa3:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100fa6:	89 c7                	mov    %eax,%edi
f0100fa8:	89 d6                	mov    %edx,%esi
f0100faa:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fad:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100fb0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100fb3:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100fb6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100fb9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100fbe:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100fc1:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100fc4:	39 d3                	cmp    %edx,%ebx
f0100fc6:	72 09                	jb     f0100fd1 <printnum+0x42>
f0100fc8:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100fcb:	0f 87 83 00 00 00    	ja     f0101054 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100fd1:	83 ec 0c             	sub    $0xc,%esp
f0100fd4:	ff 75 18             	pushl  0x18(%ebp)
f0100fd7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fda:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100fdd:	53                   	push   %ebx
f0100fde:	ff 75 10             	pushl  0x10(%ebp)
f0100fe1:	83 ec 08             	sub    $0x8,%esp
f0100fe4:	ff 75 dc             	pushl  -0x24(%ebp)
f0100fe7:	ff 75 d8             	pushl  -0x28(%ebp)
f0100fea:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100fed:	ff 75 d0             	pushl  -0x30(%ebp)
f0100ff0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100ff3:	e8 e8 09 00 00       	call   f01019e0 <__udivdi3>
f0100ff8:	83 c4 18             	add    $0x18,%esp
f0100ffb:	52                   	push   %edx
f0100ffc:	50                   	push   %eax
f0100ffd:	89 f2                	mov    %esi,%edx
f0100fff:	89 f8                	mov    %edi,%eax
f0101001:	e8 89 ff ff ff       	call   f0100f8f <printnum>
f0101006:	83 c4 20             	add    $0x20,%esp
f0101009:	eb 13                	jmp    f010101e <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010100b:	83 ec 08             	sub    $0x8,%esp
f010100e:	56                   	push   %esi
f010100f:	ff 75 18             	pushl  0x18(%ebp)
f0101012:	ff d7                	call   *%edi
f0101014:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0101017:	83 eb 01             	sub    $0x1,%ebx
f010101a:	85 db                	test   %ebx,%ebx
f010101c:	7f ed                	jg     f010100b <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010101e:	83 ec 08             	sub    $0x8,%esp
f0101021:	56                   	push   %esi
f0101022:	83 ec 04             	sub    $0x4,%esp
f0101025:	ff 75 dc             	pushl  -0x24(%ebp)
f0101028:	ff 75 d8             	pushl  -0x28(%ebp)
f010102b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010102e:	ff 75 d0             	pushl  -0x30(%ebp)
f0101031:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101034:	89 f3                	mov    %esi,%ebx
f0101036:	e8 c5 0a 00 00       	call   f0101b00 <__umoddi3>
f010103b:	83 c4 14             	add    $0x14,%esp
f010103e:	0f be 84 06 45 fe fe 	movsbl -0x101bb(%esi,%eax,1),%eax
f0101045:	ff 
f0101046:	50                   	push   %eax
f0101047:	ff d7                	call   *%edi
}
f0101049:	83 c4 10             	add    $0x10,%esp
f010104c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010104f:	5b                   	pop    %ebx
f0101050:	5e                   	pop    %esi
f0101051:	5f                   	pop    %edi
f0101052:	5d                   	pop    %ebp
f0101053:	c3                   	ret    
f0101054:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0101057:	eb be                	jmp    f0101017 <printnum+0x88>

f0101059 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101059:	55                   	push   %ebp
f010105a:	89 e5                	mov    %esp,%ebp
f010105c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010105f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101063:	8b 10                	mov    (%eax),%edx
f0101065:	3b 50 04             	cmp    0x4(%eax),%edx
f0101068:	73 0a                	jae    f0101074 <sprintputch+0x1b>
		*b->buf++ = ch;
f010106a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010106d:	89 08                	mov    %ecx,(%eax)
f010106f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101072:	88 02                	mov    %al,(%edx)
}
f0101074:	5d                   	pop    %ebp
f0101075:	c3                   	ret    

f0101076 <printfmt>:
{
f0101076:	55                   	push   %ebp
f0101077:	89 e5                	mov    %esp,%ebp
f0101079:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f010107c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010107f:	50                   	push   %eax
f0101080:	ff 75 10             	pushl  0x10(%ebp)
f0101083:	ff 75 0c             	pushl  0xc(%ebp)
f0101086:	ff 75 08             	pushl  0x8(%ebp)
f0101089:	e8 05 00 00 00       	call   f0101093 <vprintfmt>
}
f010108e:	83 c4 10             	add    $0x10,%esp
f0101091:	c9                   	leave  
f0101092:	c3                   	ret    

f0101093 <vprintfmt>:
{
f0101093:	55                   	push   %ebp
f0101094:	89 e5                	mov    %esp,%ebp
f0101096:	57                   	push   %edi
f0101097:	56                   	push   %esi
f0101098:	53                   	push   %ebx
f0101099:	83 ec 2c             	sub    $0x2c,%esp
f010109c:	e8 ae f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01010a1:	81 c3 67 12 01 00    	add    $0x11267,%ebx
f01010a7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010aa:	8b 7d 10             	mov    0x10(%ebp),%edi
f01010ad:	e9 8e 03 00 00       	jmp    f0101440 <.L35+0x48>
		padc = ' ';
f01010b2:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01010b6:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01010bd:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f01010c4:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01010cb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010d0:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01010d3:	8d 47 01             	lea    0x1(%edi),%eax
f01010d6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01010d9:	0f b6 17             	movzbl (%edi),%edx
f01010dc:	8d 42 dd             	lea    -0x23(%edx),%eax
f01010df:	3c 55                	cmp    $0x55,%al
f01010e1:	0f 87 e1 03 00 00    	ja     f01014c8 <.L22>
f01010e7:	0f b6 c0             	movzbl %al,%eax
f01010ea:	89 d9                	mov    %ebx,%ecx
f01010ec:	03 8c 83 d4 fe fe ff 	add    -0x1012c(%ebx,%eax,4),%ecx
f01010f3:	ff e1                	jmp    *%ecx

f01010f5 <.L67>:
f01010f5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01010f8:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01010fc:	eb d5                	jmp    f01010d3 <vprintfmt+0x40>

f01010fe <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f01010fe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0101101:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0101105:	eb cc                	jmp    f01010d3 <vprintfmt+0x40>

f0101107 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0101107:	0f b6 d2             	movzbl %dl,%edx
f010110a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f010110d:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0101112:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101115:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0101119:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f010111c:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010111f:	83 f9 09             	cmp    $0x9,%ecx
f0101122:	77 55                	ja     f0101179 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0101124:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0101127:	eb e9                	jmp    f0101112 <.L29+0xb>

f0101129 <.L26>:
			precision = va_arg(ap, int);
f0101129:	8b 45 14             	mov    0x14(%ebp),%eax
f010112c:	8b 00                	mov    (%eax),%eax
f010112e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101131:	8b 45 14             	mov    0x14(%ebp),%eax
f0101134:	8d 40 04             	lea    0x4(%eax),%eax
f0101137:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010113a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f010113d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101141:	79 90                	jns    f01010d3 <vprintfmt+0x40>
				width = precision, precision = -1;
f0101143:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101146:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101149:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101150:	eb 81                	jmp    f01010d3 <vprintfmt+0x40>

f0101152 <.L27>:
f0101152:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101155:	85 c0                	test   %eax,%eax
f0101157:	ba 00 00 00 00       	mov    $0x0,%edx
f010115c:	0f 49 d0             	cmovns %eax,%edx
f010115f:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101162:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101165:	e9 69 ff ff ff       	jmp    f01010d3 <vprintfmt+0x40>

f010116a <.L23>:
f010116a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f010116d:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101174:	e9 5a ff ff ff       	jmp    f01010d3 <vprintfmt+0x40>
f0101179:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010117c:	eb bf                	jmp    f010113d <.L26+0x14>

f010117e <.L33>:
			lflag++;
f010117e:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101182:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0101185:	e9 49 ff ff ff       	jmp    f01010d3 <vprintfmt+0x40>

f010118a <.L30>:
			putch(va_arg(ap, int), putdat);
f010118a:	8b 45 14             	mov    0x14(%ebp),%eax
f010118d:	8d 78 04             	lea    0x4(%eax),%edi
f0101190:	83 ec 08             	sub    $0x8,%esp
f0101193:	56                   	push   %esi
f0101194:	ff 30                	pushl  (%eax)
f0101196:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101199:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f010119c:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f010119f:	e9 99 02 00 00       	jmp    f010143d <.L35+0x45>

f01011a4 <.L32>:
			err = va_arg(ap, int);
f01011a4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a7:	8d 78 04             	lea    0x4(%eax),%edi
f01011aa:	8b 00                	mov    (%eax),%eax
f01011ac:	99                   	cltd   
f01011ad:	31 d0                	xor    %edx,%eax
f01011af:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01011b1:	83 f8 06             	cmp    $0x6,%eax
f01011b4:	7f 27                	jg     f01011dd <.L32+0x39>
f01011b6:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f01011bd:	85 d2                	test   %edx,%edx
f01011bf:	74 1c                	je     f01011dd <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01011c1:	52                   	push   %edx
f01011c2:	8d 83 66 fe fe ff    	lea    -0x1019a(%ebx),%eax
f01011c8:	50                   	push   %eax
f01011c9:	56                   	push   %esi
f01011ca:	ff 75 08             	pushl  0x8(%ebp)
f01011cd:	e8 a4 fe ff ff       	call   f0101076 <printfmt>
f01011d2:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01011d5:	89 7d 14             	mov    %edi,0x14(%ebp)
f01011d8:	e9 60 02 00 00       	jmp    f010143d <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f01011dd:	50                   	push   %eax
f01011de:	8d 83 5d fe fe ff    	lea    -0x101a3(%ebx),%eax
f01011e4:	50                   	push   %eax
f01011e5:	56                   	push   %esi
f01011e6:	ff 75 08             	pushl  0x8(%ebp)
f01011e9:	e8 88 fe ff ff       	call   f0101076 <printfmt>
f01011ee:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01011f1:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01011f4:	e9 44 02 00 00       	jmp    f010143d <.L35+0x45>

f01011f9 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f01011f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011fc:	83 c0 04             	add    $0x4,%eax
f01011ff:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101202:	8b 45 14             	mov    0x14(%ebp),%eax
f0101205:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101207:	85 ff                	test   %edi,%edi
f0101209:	8d 83 56 fe fe ff    	lea    -0x101aa(%ebx),%eax
f010120f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101212:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101216:	0f 8e b5 00 00 00    	jle    f01012d1 <.L36+0xd8>
f010121c:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101220:	75 08                	jne    f010122a <.L36+0x31>
f0101222:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101225:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101228:	eb 6d                	jmp    f0101297 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f010122a:	83 ec 08             	sub    $0x8,%esp
f010122d:	ff 75 d0             	pushl  -0x30(%ebp)
f0101230:	57                   	push   %edi
f0101231:	e8 49 04 00 00       	call   f010167f <strnlen>
f0101236:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101239:	29 c2                	sub    %eax,%edx
f010123b:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010123e:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101241:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101245:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101248:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010124b:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f010124d:	eb 10                	jmp    f010125f <.L36+0x66>
					putch(padc, putdat);
f010124f:	83 ec 08             	sub    $0x8,%esp
f0101252:	56                   	push   %esi
f0101253:	ff 75 e0             	pushl  -0x20(%ebp)
f0101256:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101259:	83 ef 01             	sub    $0x1,%edi
f010125c:	83 c4 10             	add    $0x10,%esp
f010125f:	85 ff                	test   %edi,%edi
f0101261:	7f ec                	jg     f010124f <.L36+0x56>
f0101263:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101266:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0101269:	85 d2                	test   %edx,%edx
f010126b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101270:	0f 49 c2             	cmovns %edx,%eax
f0101273:	29 c2                	sub    %eax,%edx
f0101275:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101278:	89 75 0c             	mov    %esi,0xc(%ebp)
f010127b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010127e:	eb 17                	jmp    f0101297 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0101280:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101284:	75 30                	jne    f01012b6 <.L36+0xbd>
					putch(ch, putdat);
f0101286:	83 ec 08             	sub    $0x8,%esp
f0101289:	ff 75 0c             	pushl  0xc(%ebp)
f010128c:	50                   	push   %eax
f010128d:	ff 55 08             	call   *0x8(%ebp)
f0101290:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101293:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101297:	83 c7 01             	add    $0x1,%edi
f010129a:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f010129e:	0f be c2             	movsbl %dl,%eax
f01012a1:	85 c0                	test   %eax,%eax
f01012a3:	74 52                	je     f01012f7 <.L36+0xfe>
f01012a5:	85 f6                	test   %esi,%esi
f01012a7:	78 d7                	js     f0101280 <.L36+0x87>
f01012a9:	83 ee 01             	sub    $0x1,%esi
f01012ac:	79 d2                	jns    f0101280 <.L36+0x87>
f01012ae:	8b 75 0c             	mov    0xc(%ebp),%esi
f01012b1:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01012b4:	eb 32                	jmp    f01012e8 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01012b6:	0f be d2             	movsbl %dl,%edx
f01012b9:	83 ea 20             	sub    $0x20,%edx
f01012bc:	83 fa 5e             	cmp    $0x5e,%edx
f01012bf:	76 c5                	jbe    f0101286 <.L36+0x8d>
					putch('?', putdat);
f01012c1:	83 ec 08             	sub    $0x8,%esp
f01012c4:	ff 75 0c             	pushl  0xc(%ebp)
f01012c7:	6a 3f                	push   $0x3f
f01012c9:	ff 55 08             	call   *0x8(%ebp)
f01012cc:	83 c4 10             	add    $0x10,%esp
f01012cf:	eb c2                	jmp    f0101293 <.L36+0x9a>
f01012d1:	89 75 0c             	mov    %esi,0xc(%ebp)
f01012d4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01012d7:	eb be                	jmp    f0101297 <.L36+0x9e>
				putch(' ', putdat);
f01012d9:	83 ec 08             	sub    $0x8,%esp
f01012dc:	56                   	push   %esi
f01012dd:	6a 20                	push   $0x20
f01012df:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01012e2:	83 ef 01             	sub    $0x1,%edi
f01012e5:	83 c4 10             	add    $0x10,%esp
f01012e8:	85 ff                	test   %edi,%edi
f01012ea:	7f ed                	jg     f01012d9 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01012ec:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01012ef:	89 45 14             	mov    %eax,0x14(%ebp)
f01012f2:	e9 46 01 00 00       	jmp    f010143d <.L35+0x45>
f01012f7:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01012fa:	8b 75 0c             	mov    0xc(%ebp),%esi
f01012fd:	eb e9                	jmp    f01012e8 <.L36+0xef>

f01012ff <.L31>:
f01012ff:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101302:	83 f9 01             	cmp    $0x1,%ecx
f0101305:	7e 40                	jle    f0101347 <.L31+0x48>
		return va_arg(*ap, long long);
f0101307:	8b 45 14             	mov    0x14(%ebp),%eax
f010130a:	8b 50 04             	mov    0x4(%eax),%edx
f010130d:	8b 00                	mov    (%eax),%eax
f010130f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101312:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101315:	8b 45 14             	mov    0x14(%ebp),%eax
f0101318:	8d 40 08             	lea    0x8(%eax),%eax
f010131b:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f010131e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101322:	79 55                	jns    f0101379 <.L31+0x7a>
				putch('-', putdat);
f0101324:	83 ec 08             	sub    $0x8,%esp
f0101327:	56                   	push   %esi
f0101328:	6a 2d                	push   $0x2d
f010132a:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010132d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101330:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101333:	f7 da                	neg    %edx
f0101335:	83 d1 00             	adc    $0x0,%ecx
f0101338:	f7 d9                	neg    %ecx
f010133a:	83 c4 10             	add    $0x10,%esp
			base = 10;
f010133d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101342:	e9 db 00 00 00       	jmp    f0101422 <.L35+0x2a>
	else if (lflag)
f0101347:	85 c9                	test   %ecx,%ecx
f0101349:	75 17                	jne    f0101362 <.L31+0x63>
		return va_arg(*ap, int);
f010134b:	8b 45 14             	mov    0x14(%ebp),%eax
f010134e:	8b 00                	mov    (%eax),%eax
f0101350:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101353:	99                   	cltd   
f0101354:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101357:	8b 45 14             	mov    0x14(%ebp),%eax
f010135a:	8d 40 04             	lea    0x4(%eax),%eax
f010135d:	89 45 14             	mov    %eax,0x14(%ebp)
f0101360:	eb bc                	jmp    f010131e <.L31+0x1f>
		return va_arg(*ap, long);
f0101362:	8b 45 14             	mov    0x14(%ebp),%eax
f0101365:	8b 00                	mov    (%eax),%eax
f0101367:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010136a:	99                   	cltd   
f010136b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010136e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101371:	8d 40 04             	lea    0x4(%eax),%eax
f0101374:	89 45 14             	mov    %eax,0x14(%ebp)
f0101377:	eb a5                	jmp    f010131e <.L31+0x1f>
			num = getint(&ap, lflag);
f0101379:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010137c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010137f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101384:	e9 99 00 00 00       	jmp    f0101422 <.L35+0x2a>

f0101389 <.L37>:
f0101389:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f010138c:	83 f9 01             	cmp    $0x1,%ecx
f010138f:	7e 15                	jle    f01013a6 <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f0101391:	8b 45 14             	mov    0x14(%ebp),%eax
f0101394:	8b 10                	mov    (%eax),%edx
f0101396:	8b 48 04             	mov    0x4(%eax),%ecx
f0101399:	8d 40 08             	lea    0x8(%eax),%eax
f010139c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010139f:	b8 0a 00 00 00       	mov    $0xa,%eax
f01013a4:	eb 7c                	jmp    f0101422 <.L35+0x2a>
	else if (lflag)
f01013a6:	85 c9                	test   %ecx,%ecx
f01013a8:	75 17                	jne    f01013c1 <.L37+0x38>
		return va_arg(*ap, unsigned int);
f01013aa:	8b 45 14             	mov    0x14(%ebp),%eax
f01013ad:	8b 10                	mov    (%eax),%edx
f01013af:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013b4:	8d 40 04             	lea    0x4(%eax),%eax
f01013b7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01013ba:	b8 0a 00 00 00       	mov    $0xa,%eax
f01013bf:	eb 61                	jmp    f0101422 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01013c1:	8b 45 14             	mov    0x14(%ebp),%eax
f01013c4:	8b 10                	mov    (%eax),%edx
f01013c6:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013cb:	8d 40 04             	lea    0x4(%eax),%eax
f01013ce:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01013d1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01013d6:	eb 4a                	jmp    f0101422 <.L35+0x2a>

f01013d8 <.L34>:
			putch('X', putdat);
f01013d8:	83 ec 08             	sub    $0x8,%esp
f01013db:	56                   	push   %esi
f01013dc:	6a 58                	push   $0x58
f01013de:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01013e1:	83 c4 08             	add    $0x8,%esp
f01013e4:	56                   	push   %esi
f01013e5:	6a 58                	push   $0x58
f01013e7:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01013ea:	83 c4 08             	add    $0x8,%esp
f01013ed:	56                   	push   %esi
f01013ee:	6a 58                	push   $0x58
f01013f0:	ff 55 08             	call   *0x8(%ebp)
			break;
f01013f3:	83 c4 10             	add    $0x10,%esp
f01013f6:	eb 45                	jmp    f010143d <.L35+0x45>

f01013f8 <.L35>:
			putch('0', putdat);
f01013f8:	83 ec 08             	sub    $0x8,%esp
f01013fb:	56                   	push   %esi
f01013fc:	6a 30                	push   $0x30
f01013fe:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101401:	83 c4 08             	add    $0x8,%esp
f0101404:	56                   	push   %esi
f0101405:	6a 78                	push   $0x78
f0101407:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f010140a:	8b 45 14             	mov    0x14(%ebp),%eax
f010140d:	8b 10                	mov    (%eax),%edx
f010140f:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0101414:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101417:	8d 40 04             	lea    0x4(%eax),%eax
f010141a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010141d:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0101422:	83 ec 0c             	sub    $0xc,%esp
f0101425:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101429:	57                   	push   %edi
f010142a:	ff 75 e0             	pushl  -0x20(%ebp)
f010142d:	50                   	push   %eax
f010142e:	51                   	push   %ecx
f010142f:	52                   	push   %edx
f0101430:	89 f2                	mov    %esi,%edx
f0101432:	8b 45 08             	mov    0x8(%ebp),%eax
f0101435:	e8 55 fb ff ff       	call   f0100f8f <printnum>
			break;
f010143a:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f010143d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101440:	83 c7 01             	add    $0x1,%edi
f0101443:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101447:	83 f8 25             	cmp    $0x25,%eax
f010144a:	0f 84 62 fc ff ff    	je     f01010b2 <vprintfmt+0x1f>
			if (ch == '\0')
f0101450:	85 c0                	test   %eax,%eax
f0101452:	0f 84 91 00 00 00    	je     f01014e9 <.L22+0x21>
			putch(ch, putdat);
f0101458:	83 ec 08             	sub    $0x8,%esp
f010145b:	56                   	push   %esi
f010145c:	50                   	push   %eax
f010145d:	ff 55 08             	call   *0x8(%ebp)
f0101460:	83 c4 10             	add    $0x10,%esp
f0101463:	eb db                	jmp    f0101440 <.L35+0x48>

f0101465 <.L38>:
f0101465:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101468:	83 f9 01             	cmp    $0x1,%ecx
f010146b:	7e 15                	jle    f0101482 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f010146d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101470:	8b 10                	mov    (%eax),%edx
f0101472:	8b 48 04             	mov    0x4(%eax),%ecx
f0101475:	8d 40 08             	lea    0x8(%eax),%eax
f0101478:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010147b:	b8 10 00 00 00       	mov    $0x10,%eax
f0101480:	eb a0                	jmp    f0101422 <.L35+0x2a>
	else if (lflag)
f0101482:	85 c9                	test   %ecx,%ecx
f0101484:	75 17                	jne    f010149d <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0101486:	8b 45 14             	mov    0x14(%ebp),%eax
f0101489:	8b 10                	mov    (%eax),%edx
f010148b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101490:	8d 40 04             	lea    0x4(%eax),%eax
f0101493:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101496:	b8 10 00 00 00       	mov    $0x10,%eax
f010149b:	eb 85                	jmp    f0101422 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010149d:	8b 45 14             	mov    0x14(%ebp),%eax
f01014a0:	8b 10                	mov    (%eax),%edx
f01014a2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01014a7:	8d 40 04             	lea    0x4(%eax),%eax
f01014aa:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01014ad:	b8 10 00 00 00       	mov    $0x10,%eax
f01014b2:	e9 6b ff ff ff       	jmp    f0101422 <.L35+0x2a>

f01014b7 <.L25>:
			putch(ch, putdat);
f01014b7:	83 ec 08             	sub    $0x8,%esp
f01014ba:	56                   	push   %esi
f01014bb:	6a 25                	push   $0x25
f01014bd:	ff 55 08             	call   *0x8(%ebp)
			break;
f01014c0:	83 c4 10             	add    $0x10,%esp
f01014c3:	e9 75 ff ff ff       	jmp    f010143d <.L35+0x45>

f01014c8 <.L22>:
			putch('%', putdat);
f01014c8:	83 ec 08             	sub    $0x8,%esp
f01014cb:	56                   	push   %esi
f01014cc:	6a 25                	push   $0x25
f01014ce:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01014d1:	83 c4 10             	add    $0x10,%esp
f01014d4:	89 f8                	mov    %edi,%eax
f01014d6:	eb 03                	jmp    f01014db <.L22+0x13>
f01014d8:	83 e8 01             	sub    $0x1,%eax
f01014db:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01014df:	75 f7                	jne    f01014d8 <.L22+0x10>
f01014e1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01014e4:	e9 54 ff ff ff       	jmp    f010143d <.L35+0x45>
}
f01014e9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014ec:	5b                   	pop    %ebx
f01014ed:	5e                   	pop    %esi
f01014ee:	5f                   	pop    %edi
f01014ef:	5d                   	pop    %ebp
f01014f0:	c3                   	ret    

f01014f1 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01014f1:	55                   	push   %ebp
f01014f2:	89 e5                	mov    %esp,%ebp
f01014f4:	53                   	push   %ebx
f01014f5:	83 ec 14             	sub    $0x14,%esp
f01014f8:	e8 52 ec ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01014fd:	81 c3 0b 0e 01 00    	add    $0x10e0b,%ebx
f0101503:	8b 45 08             	mov    0x8(%ebp),%eax
f0101506:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101509:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010150c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101510:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101513:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010151a:	85 c0                	test   %eax,%eax
f010151c:	74 2b                	je     f0101549 <vsnprintf+0x58>
f010151e:	85 d2                	test   %edx,%edx
f0101520:	7e 27                	jle    f0101549 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101522:	ff 75 14             	pushl  0x14(%ebp)
f0101525:	ff 75 10             	pushl  0x10(%ebp)
f0101528:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010152b:	50                   	push   %eax
f010152c:	8d 83 51 ed fe ff    	lea    -0x112af(%ebx),%eax
f0101532:	50                   	push   %eax
f0101533:	e8 5b fb ff ff       	call   f0101093 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101538:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010153b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010153e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101541:	83 c4 10             	add    $0x10,%esp
}
f0101544:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101547:	c9                   	leave  
f0101548:	c3                   	ret    
		return -E_INVAL;
f0101549:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010154e:	eb f4                	jmp    f0101544 <vsnprintf+0x53>

f0101550 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101550:	55                   	push   %ebp
f0101551:	89 e5                	mov    %esp,%ebp
f0101553:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101556:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101559:	50                   	push   %eax
f010155a:	ff 75 10             	pushl  0x10(%ebp)
f010155d:	ff 75 0c             	pushl  0xc(%ebp)
f0101560:	ff 75 08             	pushl  0x8(%ebp)
f0101563:	e8 89 ff ff ff       	call   f01014f1 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101568:	c9                   	leave  
f0101569:	c3                   	ret    

f010156a <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010156a:	55                   	push   %ebp
f010156b:	89 e5                	mov    %esp,%ebp
f010156d:	57                   	push   %edi
f010156e:	56                   	push   %esi
f010156f:	53                   	push   %ebx
f0101570:	83 ec 1c             	sub    $0x1c,%esp
f0101573:	e8 d7 eb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101578:	81 c3 90 0d 01 00    	add    $0x10d90,%ebx
f010157e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101581:	85 c0                	test   %eax,%eax
f0101583:	74 13                	je     f0101598 <readline+0x2e>
		cprintf("%s", prompt);
f0101585:	83 ec 08             	sub    $0x8,%esp
f0101588:	50                   	push   %eax
f0101589:	8d 83 66 fe fe ff    	lea    -0x1019a(%ebx),%eax
f010158f:	50                   	push   %eax
f0101590:	e8 ea f6 ff ff       	call   f0100c7f <cprintf>
f0101595:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101598:	83 ec 0c             	sub    $0xc,%esp
f010159b:	6a 00                	push   $0x0
f010159d:	e8 45 f1 ff ff       	call   f01006e7 <iscons>
f01015a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01015a5:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01015a8:	bf 00 00 00 00       	mov    $0x0,%edi
f01015ad:	eb 46                	jmp    f01015f5 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01015af:	83 ec 08             	sub    $0x8,%esp
f01015b2:	50                   	push   %eax
f01015b3:	8d 83 2c 00 ff ff    	lea    -0xffd4(%ebx),%eax
f01015b9:	50                   	push   %eax
f01015ba:	e8 c0 f6 ff ff       	call   f0100c7f <cprintf>
			return NULL;
f01015bf:	83 c4 10             	add    $0x10,%esp
f01015c2:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01015c7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01015ca:	5b                   	pop    %ebx
f01015cb:	5e                   	pop    %esi
f01015cc:	5f                   	pop    %edi
f01015cd:	5d                   	pop    %ebp
f01015ce:	c3                   	ret    
			if (echoing)
f01015cf:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01015d3:	75 05                	jne    f01015da <readline+0x70>
			i--;
f01015d5:	83 ef 01             	sub    $0x1,%edi
f01015d8:	eb 1b                	jmp    f01015f5 <readline+0x8b>
				cputchar('\b');
f01015da:	83 ec 0c             	sub    $0xc,%esp
f01015dd:	6a 08                	push   $0x8
f01015df:	e8 e2 f0 ff ff       	call   f01006c6 <cputchar>
f01015e4:	83 c4 10             	add    $0x10,%esp
f01015e7:	eb ec                	jmp    f01015d5 <readline+0x6b>
			buf[i++] = c;
f01015e9:	89 f0                	mov    %esi,%eax
f01015eb:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f01015f2:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f01015f5:	e8 dc f0 ff ff       	call   f01006d6 <getchar>
f01015fa:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f01015fc:	85 c0                	test   %eax,%eax
f01015fe:	78 af                	js     f01015af <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101600:	83 f8 08             	cmp    $0x8,%eax
f0101603:	0f 94 c2             	sete   %dl
f0101606:	83 f8 7f             	cmp    $0x7f,%eax
f0101609:	0f 94 c0             	sete   %al
f010160c:	08 c2                	or     %al,%dl
f010160e:	74 04                	je     f0101614 <readline+0xaa>
f0101610:	85 ff                	test   %edi,%edi
f0101612:	7f bb                	jg     f01015cf <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101614:	83 fe 1f             	cmp    $0x1f,%esi
f0101617:	7e 1c                	jle    f0101635 <readline+0xcb>
f0101619:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f010161f:	7f 14                	jg     f0101635 <readline+0xcb>
			if (echoing)
f0101621:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101625:	74 c2                	je     f01015e9 <readline+0x7f>
				cputchar(c);
f0101627:	83 ec 0c             	sub    $0xc,%esp
f010162a:	56                   	push   %esi
f010162b:	e8 96 f0 ff ff       	call   f01006c6 <cputchar>
f0101630:	83 c4 10             	add    $0x10,%esp
f0101633:	eb b4                	jmp    f01015e9 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0101635:	83 fe 0a             	cmp    $0xa,%esi
f0101638:	74 05                	je     f010163f <readline+0xd5>
f010163a:	83 fe 0d             	cmp    $0xd,%esi
f010163d:	75 b6                	jne    f01015f5 <readline+0x8b>
			if (echoing)
f010163f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101643:	75 13                	jne    f0101658 <readline+0xee>
			buf[i] = 0;
f0101645:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f010164c:	00 
			return buf;
f010164d:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f0101653:	e9 6f ff ff ff       	jmp    f01015c7 <readline+0x5d>
				cputchar('\n');
f0101658:	83 ec 0c             	sub    $0xc,%esp
f010165b:	6a 0a                	push   $0xa
f010165d:	e8 64 f0 ff ff       	call   f01006c6 <cputchar>
f0101662:	83 c4 10             	add    $0x10,%esp
f0101665:	eb de                	jmp    f0101645 <readline+0xdb>

f0101667 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101667:	55                   	push   %ebp
f0101668:	89 e5                	mov    %esp,%ebp
f010166a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010166d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101672:	eb 03                	jmp    f0101677 <strlen+0x10>
		n++;
f0101674:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0101677:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010167b:	75 f7                	jne    f0101674 <strlen+0xd>
	return n;
}
f010167d:	5d                   	pop    %ebp
f010167e:	c3                   	ret    

f010167f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010167f:	55                   	push   %ebp
f0101680:	89 e5                	mov    %esp,%ebp
f0101682:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101685:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101688:	b8 00 00 00 00       	mov    $0x0,%eax
f010168d:	eb 03                	jmp    f0101692 <strnlen+0x13>
		n++;
f010168f:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101692:	39 d0                	cmp    %edx,%eax
f0101694:	74 06                	je     f010169c <strnlen+0x1d>
f0101696:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010169a:	75 f3                	jne    f010168f <strnlen+0x10>
	return n;
}
f010169c:	5d                   	pop    %ebp
f010169d:	c3                   	ret    

f010169e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010169e:	55                   	push   %ebp
f010169f:	89 e5                	mov    %esp,%ebp
f01016a1:	53                   	push   %ebx
f01016a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01016a5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01016a8:	89 c2                	mov    %eax,%edx
f01016aa:	83 c1 01             	add    $0x1,%ecx
f01016ad:	83 c2 01             	add    $0x1,%edx
f01016b0:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01016b4:	88 5a ff             	mov    %bl,-0x1(%edx)
f01016b7:	84 db                	test   %bl,%bl
f01016b9:	75 ef                	jne    f01016aa <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01016bb:	5b                   	pop    %ebx
f01016bc:	5d                   	pop    %ebp
f01016bd:	c3                   	ret    

f01016be <strcat>:

char *
strcat(char *dst, const char *src)
{
f01016be:	55                   	push   %ebp
f01016bf:	89 e5                	mov    %esp,%ebp
f01016c1:	53                   	push   %ebx
f01016c2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01016c5:	53                   	push   %ebx
f01016c6:	e8 9c ff ff ff       	call   f0101667 <strlen>
f01016cb:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01016ce:	ff 75 0c             	pushl  0xc(%ebp)
f01016d1:	01 d8                	add    %ebx,%eax
f01016d3:	50                   	push   %eax
f01016d4:	e8 c5 ff ff ff       	call   f010169e <strcpy>
	return dst;
}
f01016d9:	89 d8                	mov    %ebx,%eax
f01016db:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01016de:	c9                   	leave  
f01016df:	c3                   	ret    

f01016e0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01016e0:	55                   	push   %ebp
f01016e1:	89 e5                	mov    %esp,%ebp
f01016e3:	56                   	push   %esi
f01016e4:	53                   	push   %ebx
f01016e5:	8b 75 08             	mov    0x8(%ebp),%esi
f01016e8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01016eb:	89 f3                	mov    %esi,%ebx
f01016ed:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01016f0:	89 f2                	mov    %esi,%edx
f01016f2:	eb 0f                	jmp    f0101703 <strncpy+0x23>
		*dst++ = *src;
f01016f4:	83 c2 01             	add    $0x1,%edx
f01016f7:	0f b6 01             	movzbl (%ecx),%eax
f01016fa:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01016fd:	80 39 01             	cmpb   $0x1,(%ecx)
f0101700:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101703:	39 da                	cmp    %ebx,%edx
f0101705:	75 ed                	jne    f01016f4 <strncpy+0x14>
	}
	return ret;
}
f0101707:	89 f0                	mov    %esi,%eax
f0101709:	5b                   	pop    %ebx
f010170a:	5e                   	pop    %esi
f010170b:	5d                   	pop    %ebp
f010170c:	c3                   	ret    

f010170d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010170d:	55                   	push   %ebp
f010170e:	89 e5                	mov    %esp,%ebp
f0101710:	56                   	push   %esi
f0101711:	53                   	push   %ebx
f0101712:	8b 75 08             	mov    0x8(%ebp),%esi
f0101715:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101718:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010171b:	89 f0                	mov    %esi,%eax
f010171d:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101721:	85 c9                	test   %ecx,%ecx
f0101723:	75 0b                	jne    f0101730 <strlcpy+0x23>
f0101725:	eb 17                	jmp    f010173e <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101727:	83 c2 01             	add    $0x1,%edx
f010172a:	83 c0 01             	add    $0x1,%eax
f010172d:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101730:	39 d8                	cmp    %ebx,%eax
f0101732:	74 07                	je     f010173b <strlcpy+0x2e>
f0101734:	0f b6 0a             	movzbl (%edx),%ecx
f0101737:	84 c9                	test   %cl,%cl
f0101739:	75 ec                	jne    f0101727 <strlcpy+0x1a>
		*dst = '\0';
f010173b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010173e:	29 f0                	sub    %esi,%eax
}
f0101740:	5b                   	pop    %ebx
f0101741:	5e                   	pop    %esi
f0101742:	5d                   	pop    %ebp
f0101743:	c3                   	ret    

f0101744 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101744:	55                   	push   %ebp
f0101745:	89 e5                	mov    %esp,%ebp
f0101747:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010174a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010174d:	eb 06                	jmp    f0101755 <strcmp+0x11>
		p++, q++;
f010174f:	83 c1 01             	add    $0x1,%ecx
f0101752:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101755:	0f b6 01             	movzbl (%ecx),%eax
f0101758:	84 c0                	test   %al,%al
f010175a:	74 04                	je     f0101760 <strcmp+0x1c>
f010175c:	3a 02                	cmp    (%edx),%al
f010175e:	74 ef                	je     f010174f <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101760:	0f b6 c0             	movzbl %al,%eax
f0101763:	0f b6 12             	movzbl (%edx),%edx
f0101766:	29 d0                	sub    %edx,%eax
}
f0101768:	5d                   	pop    %ebp
f0101769:	c3                   	ret    

f010176a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010176a:	55                   	push   %ebp
f010176b:	89 e5                	mov    %esp,%ebp
f010176d:	53                   	push   %ebx
f010176e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101771:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101774:	89 c3                	mov    %eax,%ebx
f0101776:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101779:	eb 06                	jmp    f0101781 <strncmp+0x17>
		n--, p++, q++;
f010177b:	83 c0 01             	add    $0x1,%eax
f010177e:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101781:	39 d8                	cmp    %ebx,%eax
f0101783:	74 16                	je     f010179b <strncmp+0x31>
f0101785:	0f b6 08             	movzbl (%eax),%ecx
f0101788:	84 c9                	test   %cl,%cl
f010178a:	74 04                	je     f0101790 <strncmp+0x26>
f010178c:	3a 0a                	cmp    (%edx),%cl
f010178e:	74 eb                	je     f010177b <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101790:	0f b6 00             	movzbl (%eax),%eax
f0101793:	0f b6 12             	movzbl (%edx),%edx
f0101796:	29 d0                	sub    %edx,%eax
}
f0101798:	5b                   	pop    %ebx
f0101799:	5d                   	pop    %ebp
f010179a:	c3                   	ret    
		return 0;
f010179b:	b8 00 00 00 00       	mov    $0x0,%eax
f01017a0:	eb f6                	jmp    f0101798 <strncmp+0x2e>

f01017a2 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01017a2:	55                   	push   %ebp
f01017a3:	89 e5                	mov    %esp,%ebp
f01017a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01017a8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01017ac:	0f b6 10             	movzbl (%eax),%edx
f01017af:	84 d2                	test   %dl,%dl
f01017b1:	74 09                	je     f01017bc <strchr+0x1a>
		if (*s == c)
f01017b3:	38 ca                	cmp    %cl,%dl
f01017b5:	74 0a                	je     f01017c1 <strchr+0x1f>
	for (; *s; s++)
f01017b7:	83 c0 01             	add    $0x1,%eax
f01017ba:	eb f0                	jmp    f01017ac <strchr+0xa>
			return (char *) s;
	return 0;
f01017bc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01017c1:	5d                   	pop    %ebp
f01017c2:	c3                   	ret    

f01017c3 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01017c3:	55                   	push   %ebp
f01017c4:	89 e5                	mov    %esp,%ebp
f01017c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01017c9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01017cd:	eb 03                	jmp    f01017d2 <strfind+0xf>
f01017cf:	83 c0 01             	add    $0x1,%eax
f01017d2:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01017d5:	38 ca                	cmp    %cl,%dl
f01017d7:	74 04                	je     f01017dd <strfind+0x1a>
f01017d9:	84 d2                	test   %dl,%dl
f01017db:	75 f2                	jne    f01017cf <strfind+0xc>
			break;
	return (char *) s;
}
f01017dd:	5d                   	pop    %ebp
f01017de:	c3                   	ret    

f01017df <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01017df:	55                   	push   %ebp
f01017e0:	89 e5                	mov    %esp,%ebp
f01017e2:	57                   	push   %edi
f01017e3:	56                   	push   %esi
f01017e4:	53                   	push   %ebx
f01017e5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01017e8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01017eb:	85 c9                	test   %ecx,%ecx
f01017ed:	74 13                	je     f0101802 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01017ef:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01017f5:	75 05                	jne    f01017fc <memset+0x1d>
f01017f7:	f6 c1 03             	test   $0x3,%cl
f01017fa:	74 0d                	je     f0101809 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01017fc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017ff:	fc                   	cld    
f0101800:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101802:	89 f8                	mov    %edi,%eax
f0101804:	5b                   	pop    %ebx
f0101805:	5e                   	pop    %esi
f0101806:	5f                   	pop    %edi
f0101807:	5d                   	pop    %ebp
f0101808:	c3                   	ret    
		c &= 0xFF;
f0101809:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010180d:	89 d3                	mov    %edx,%ebx
f010180f:	c1 e3 08             	shl    $0x8,%ebx
f0101812:	89 d0                	mov    %edx,%eax
f0101814:	c1 e0 18             	shl    $0x18,%eax
f0101817:	89 d6                	mov    %edx,%esi
f0101819:	c1 e6 10             	shl    $0x10,%esi
f010181c:	09 f0                	or     %esi,%eax
f010181e:	09 c2                	or     %eax,%edx
f0101820:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0101822:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101825:	89 d0                	mov    %edx,%eax
f0101827:	fc                   	cld    
f0101828:	f3 ab                	rep stos %eax,%es:(%edi)
f010182a:	eb d6                	jmp    f0101802 <memset+0x23>

f010182c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010182c:	55                   	push   %ebp
f010182d:	89 e5                	mov    %esp,%ebp
f010182f:	57                   	push   %edi
f0101830:	56                   	push   %esi
f0101831:	8b 45 08             	mov    0x8(%ebp),%eax
f0101834:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101837:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010183a:	39 c6                	cmp    %eax,%esi
f010183c:	73 35                	jae    f0101873 <memmove+0x47>
f010183e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101841:	39 c2                	cmp    %eax,%edx
f0101843:	76 2e                	jbe    f0101873 <memmove+0x47>
		s += n;
		d += n;
f0101845:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101848:	89 d6                	mov    %edx,%esi
f010184a:	09 fe                	or     %edi,%esi
f010184c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101852:	74 0c                	je     f0101860 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101854:	83 ef 01             	sub    $0x1,%edi
f0101857:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f010185a:	fd                   	std    
f010185b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010185d:	fc                   	cld    
f010185e:	eb 21                	jmp    f0101881 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101860:	f6 c1 03             	test   $0x3,%cl
f0101863:	75 ef                	jne    f0101854 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101865:	83 ef 04             	sub    $0x4,%edi
f0101868:	8d 72 fc             	lea    -0x4(%edx),%esi
f010186b:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f010186e:	fd                   	std    
f010186f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101871:	eb ea                	jmp    f010185d <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101873:	89 f2                	mov    %esi,%edx
f0101875:	09 c2                	or     %eax,%edx
f0101877:	f6 c2 03             	test   $0x3,%dl
f010187a:	74 09                	je     f0101885 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010187c:	89 c7                	mov    %eax,%edi
f010187e:	fc                   	cld    
f010187f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101881:	5e                   	pop    %esi
f0101882:	5f                   	pop    %edi
f0101883:	5d                   	pop    %ebp
f0101884:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101885:	f6 c1 03             	test   $0x3,%cl
f0101888:	75 f2                	jne    f010187c <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010188a:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f010188d:	89 c7                	mov    %eax,%edi
f010188f:	fc                   	cld    
f0101890:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101892:	eb ed                	jmp    f0101881 <memmove+0x55>

f0101894 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101894:	55                   	push   %ebp
f0101895:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101897:	ff 75 10             	pushl  0x10(%ebp)
f010189a:	ff 75 0c             	pushl  0xc(%ebp)
f010189d:	ff 75 08             	pushl  0x8(%ebp)
f01018a0:	e8 87 ff ff ff       	call   f010182c <memmove>
}
f01018a5:	c9                   	leave  
f01018a6:	c3                   	ret    

f01018a7 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01018a7:	55                   	push   %ebp
f01018a8:	89 e5                	mov    %esp,%ebp
f01018aa:	56                   	push   %esi
f01018ab:	53                   	push   %ebx
f01018ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01018af:	8b 55 0c             	mov    0xc(%ebp),%edx
f01018b2:	89 c6                	mov    %eax,%esi
f01018b4:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01018b7:	39 f0                	cmp    %esi,%eax
f01018b9:	74 1c                	je     f01018d7 <memcmp+0x30>
		if (*s1 != *s2)
f01018bb:	0f b6 08             	movzbl (%eax),%ecx
f01018be:	0f b6 1a             	movzbl (%edx),%ebx
f01018c1:	38 d9                	cmp    %bl,%cl
f01018c3:	75 08                	jne    f01018cd <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01018c5:	83 c0 01             	add    $0x1,%eax
f01018c8:	83 c2 01             	add    $0x1,%edx
f01018cb:	eb ea                	jmp    f01018b7 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01018cd:	0f b6 c1             	movzbl %cl,%eax
f01018d0:	0f b6 db             	movzbl %bl,%ebx
f01018d3:	29 d8                	sub    %ebx,%eax
f01018d5:	eb 05                	jmp    f01018dc <memcmp+0x35>
	}

	return 0;
f01018d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01018dc:	5b                   	pop    %ebx
f01018dd:	5e                   	pop    %esi
f01018de:	5d                   	pop    %ebp
f01018df:	c3                   	ret    

f01018e0 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01018e0:	55                   	push   %ebp
f01018e1:	89 e5                	mov    %esp,%ebp
f01018e3:	8b 45 08             	mov    0x8(%ebp),%eax
f01018e6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01018e9:	89 c2                	mov    %eax,%edx
f01018eb:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01018ee:	39 d0                	cmp    %edx,%eax
f01018f0:	73 09                	jae    f01018fb <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01018f2:	38 08                	cmp    %cl,(%eax)
f01018f4:	74 05                	je     f01018fb <memfind+0x1b>
	for (; s < ends; s++)
f01018f6:	83 c0 01             	add    $0x1,%eax
f01018f9:	eb f3                	jmp    f01018ee <memfind+0xe>
			break;
	return (void *) s;
}
f01018fb:	5d                   	pop    %ebp
f01018fc:	c3                   	ret    

f01018fd <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01018fd:	55                   	push   %ebp
f01018fe:	89 e5                	mov    %esp,%ebp
f0101900:	57                   	push   %edi
f0101901:	56                   	push   %esi
f0101902:	53                   	push   %ebx
f0101903:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101906:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101909:	eb 03                	jmp    f010190e <strtol+0x11>
		s++;
f010190b:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f010190e:	0f b6 01             	movzbl (%ecx),%eax
f0101911:	3c 20                	cmp    $0x20,%al
f0101913:	74 f6                	je     f010190b <strtol+0xe>
f0101915:	3c 09                	cmp    $0x9,%al
f0101917:	74 f2                	je     f010190b <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101919:	3c 2b                	cmp    $0x2b,%al
f010191b:	74 2e                	je     f010194b <strtol+0x4e>
	int neg = 0;
f010191d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101922:	3c 2d                	cmp    $0x2d,%al
f0101924:	74 2f                	je     f0101955 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101926:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010192c:	75 05                	jne    f0101933 <strtol+0x36>
f010192e:	80 39 30             	cmpb   $0x30,(%ecx)
f0101931:	74 2c                	je     f010195f <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101933:	85 db                	test   %ebx,%ebx
f0101935:	75 0a                	jne    f0101941 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101937:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f010193c:	80 39 30             	cmpb   $0x30,(%ecx)
f010193f:	74 28                	je     f0101969 <strtol+0x6c>
		base = 10;
f0101941:	b8 00 00 00 00       	mov    $0x0,%eax
f0101946:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101949:	eb 50                	jmp    f010199b <strtol+0x9e>
		s++;
f010194b:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f010194e:	bf 00 00 00 00       	mov    $0x0,%edi
f0101953:	eb d1                	jmp    f0101926 <strtol+0x29>
		s++, neg = 1;
f0101955:	83 c1 01             	add    $0x1,%ecx
f0101958:	bf 01 00 00 00       	mov    $0x1,%edi
f010195d:	eb c7                	jmp    f0101926 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010195f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101963:	74 0e                	je     f0101973 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101965:	85 db                	test   %ebx,%ebx
f0101967:	75 d8                	jne    f0101941 <strtol+0x44>
		s++, base = 8;
f0101969:	83 c1 01             	add    $0x1,%ecx
f010196c:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101971:	eb ce                	jmp    f0101941 <strtol+0x44>
		s += 2, base = 16;
f0101973:	83 c1 02             	add    $0x2,%ecx
f0101976:	bb 10 00 00 00       	mov    $0x10,%ebx
f010197b:	eb c4                	jmp    f0101941 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f010197d:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101980:	89 f3                	mov    %esi,%ebx
f0101982:	80 fb 19             	cmp    $0x19,%bl
f0101985:	77 29                	ja     f01019b0 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0101987:	0f be d2             	movsbl %dl,%edx
f010198a:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010198d:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101990:	7d 30                	jge    f01019c2 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0101992:	83 c1 01             	add    $0x1,%ecx
f0101995:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101999:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f010199b:	0f b6 11             	movzbl (%ecx),%edx
f010199e:	8d 72 d0             	lea    -0x30(%edx),%esi
f01019a1:	89 f3                	mov    %esi,%ebx
f01019a3:	80 fb 09             	cmp    $0x9,%bl
f01019a6:	77 d5                	ja     f010197d <strtol+0x80>
			dig = *s - '0';
f01019a8:	0f be d2             	movsbl %dl,%edx
f01019ab:	83 ea 30             	sub    $0x30,%edx
f01019ae:	eb dd                	jmp    f010198d <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f01019b0:	8d 72 bf             	lea    -0x41(%edx),%esi
f01019b3:	89 f3                	mov    %esi,%ebx
f01019b5:	80 fb 19             	cmp    $0x19,%bl
f01019b8:	77 08                	ja     f01019c2 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01019ba:	0f be d2             	movsbl %dl,%edx
f01019bd:	83 ea 37             	sub    $0x37,%edx
f01019c0:	eb cb                	jmp    f010198d <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01019c2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01019c6:	74 05                	je     f01019cd <strtol+0xd0>
		*endptr = (char *) s;
f01019c8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01019cb:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01019cd:	89 c2                	mov    %eax,%edx
f01019cf:	f7 da                	neg    %edx
f01019d1:	85 ff                	test   %edi,%edi
f01019d3:	0f 45 c2             	cmovne %edx,%eax
}
f01019d6:	5b                   	pop    %ebx
f01019d7:	5e                   	pop    %esi
f01019d8:	5f                   	pop    %edi
f01019d9:	5d                   	pop    %ebp
f01019da:	c3                   	ret    
f01019db:	66 90                	xchg   %ax,%ax
f01019dd:	66 90                	xchg   %ax,%ax
f01019df:	90                   	nop

f01019e0 <__udivdi3>:
f01019e0:	55                   	push   %ebp
f01019e1:	57                   	push   %edi
f01019e2:	56                   	push   %esi
f01019e3:	53                   	push   %ebx
f01019e4:	83 ec 1c             	sub    $0x1c,%esp
f01019e7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01019eb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01019ef:	8b 74 24 34          	mov    0x34(%esp),%esi
f01019f3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01019f7:	85 d2                	test   %edx,%edx
f01019f9:	75 35                	jne    f0101a30 <__udivdi3+0x50>
f01019fb:	39 f3                	cmp    %esi,%ebx
f01019fd:	0f 87 bd 00 00 00    	ja     f0101ac0 <__udivdi3+0xe0>
f0101a03:	85 db                	test   %ebx,%ebx
f0101a05:	89 d9                	mov    %ebx,%ecx
f0101a07:	75 0b                	jne    f0101a14 <__udivdi3+0x34>
f0101a09:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a0e:	31 d2                	xor    %edx,%edx
f0101a10:	f7 f3                	div    %ebx
f0101a12:	89 c1                	mov    %eax,%ecx
f0101a14:	31 d2                	xor    %edx,%edx
f0101a16:	89 f0                	mov    %esi,%eax
f0101a18:	f7 f1                	div    %ecx
f0101a1a:	89 c6                	mov    %eax,%esi
f0101a1c:	89 e8                	mov    %ebp,%eax
f0101a1e:	89 f7                	mov    %esi,%edi
f0101a20:	f7 f1                	div    %ecx
f0101a22:	89 fa                	mov    %edi,%edx
f0101a24:	83 c4 1c             	add    $0x1c,%esp
f0101a27:	5b                   	pop    %ebx
f0101a28:	5e                   	pop    %esi
f0101a29:	5f                   	pop    %edi
f0101a2a:	5d                   	pop    %ebp
f0101a2b:	c3                   	ret    
f0101a2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a30:	39 f2                	cmp    %esi,%edx
f0101a32:	77 7c                	ja     f0101ab0 <__udivdi3+0xd0>
f0101a34:	0f bd fa             	bsr    %edx,%edi
f0101a37:	83 f7 1f             	xor    $0x1f,%edi
f0101a3a:	0f 84 98 00 00 00    	je     f0101ad8 <__udivdi3+0xf8>
f0101a40:	89 f9                	mov    %edi,%ecx
f0101a42:	b8 20 00 00 00       	mov    $0x20,%eax
f0101a47:	29 f8                	sub    %edi,%eax
f0101a49:	d3 e2                	shl    %cl,%edx
f0101a4b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101a4f:	89 c1                	mov    %eax,%ecx
f0101a51:	89 da                	mov    %ebx,%edx
f0101a53:	d3 ea                	shr    %cl,%edx
f0101a55:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101a59:	09 d1                	or     %edx,%ecx
f0101a5b:	89 f2                	mov    %esi,%edx
f0101a5d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101a61:	89 f9                	mov    %edi,%ecx
f0101a63:	d3 e3                	shl    %cl,%ebx
f0101a65:	89 c1                	mov    %eax,%ecx
f0101a67:	d3 ea                	shr    %cl,%edx
f0101a69:	89 f9                	mov    %edi,%ecx
f0101a6b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101a6f:	d3 e6                	shl    %cl,%esi
f0101a71:	89 eb                	mov    %ebp,%ebx
f0101a73:	89 c1                	mov    %eax,%ecx
f0101a75:	d3 eb                	shr    %cl,%ebx
f0101a77:	09 de                	or     %ebx,%esi
f0101a79:	89 f0                	mov    %esi,%eax
f0101a7b:	f7 74 24 08          	divl   0x8(%esp)
f0101a7f:	89 d6                	mov    %edx,%esi
f0101a81:	89 c3                	mov    %eax,%ebx
f0101a83:	f7 64 24 0c          	mull   0xc(%esp)
f0101a87:	39 d6                	cmp    %edx,%esi
f0101a89:	72 0c                	jb     f0101a97 <__udivdi3+0xb7>
f0101a8b:	89 f9                	mov    %edi,%ecx
f0101a8d:	d3 e5                	shl    %cl,%ebp
f0101a8f:	39 c5                	cmp    %eax,%ebp
f0101a91:	73 5d                	jae    f0101af0 <__udivdi3+0x110>
f0101a93:	39 d6                	cmp    %edx,%esi
f0101a95:	75 59                	jne    f0101af0 <__udivdi3+0x110>
f0101a97:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101a9a:	31 ff                	xor    %edi,%edi
f0101a9c:	89 fa                	mov    %edi,%edx
f0101a9e:	83 c4 1c             	add    $0x1c,%esp
f0101aa1:	5b                   	pop    %ebx
f0101aa2:	5e                   	pop    %esi
f0101aa3:	5f                   	pop    %edi
f0101aa4:	5d                   	pop    %ebp
f0101aa5:	c3                   	ret    
f0101aa6:	8d 76 00             	lea    0x0(%esi),%esi
f0101aa9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101ab0:	31 ff                	xor    %edi,%edi
f0101ab2:	31 c0                	xor    %eax,%eax
f0101ab4:	89 fa                	mov    %edi,%edx
f0101ab6:	83 c4 1c             	add    $0x1c,%esp
f0101ab9:	5b                   	pop    %ebx
f0101aba:	5e                   	pop    %esi
f0101abb:	5f                   	pop    %edi
f0101abc:	5d                   	pop    %ebp
f0101abd:	c3                   	ret    
f0101abe:	66 90                	xchg   %ax,%ax
f0101ac0:	31 ff                	xor    %edi,%edi
f0101ac2:	89 e8                	mov    %ebp,%eax
f0101ac4:	89 f2                	mov    %esi,%edx
f0101ac6:	f7 f3                	div    %ebx
f0101ac8:	89 fa                	mov    %edi,%edx
f0101aca:	83 c4 1c             	add    $0x1c,%esp
f0101acd:	5b                   	pop    %ebx
f0101ace:	5e                   	pop    %esi
f0101acf:	5f                   	pop    %edi
f0101ad0:	5d                   	pop    %ebp
f0101ad1:	c3                   	ret    
f0101ad2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101ad8:	39 f2                	cmp    %esi,%edx
f0101ada:	72 06                	jb     f0101ae2 <__udivdi3+0x102>
f0101adc:	31 c0                	xor    %eax,%eax
f0101ade:	39 eb                	cmp    %ebp,%ebx
f0101ae0:	77 d2                	ja     f0101ab4 <__udivdi3+0xd4>
f0101ae2:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ae7:	eb cb                	jmp    f0101ab4 <__udivdi3+0xd4>
f0101ae9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101af0:	89 d8                	mov    %ebx,%eax
f0101af2:	31 ff                	xor    %edi,%edi
f0101af4:	eb be                	jmp    f0101ab4 <__udivdi3+0xd4>
f0101af6:	66 90                	xchg   %ax,%ax
f0101af8:	66 90                	xchg   %ax,%ax
f0101afa:	66 90                	xchg   %ax,%ax
f0101afc:	66 90                	xchg   %ax,%ax
f0101afe:	66 90                	xchg   %ax,%ax

f0101b00 <__umoddi3>:
f0101b00:	55                   	push   %ebp
f0101b01:	57                   	push   %edi
f0101b02:	56                   	push   %esi
f0101b03:	53                   	push   %ebx
f0101b04:	83 ec 1c             	sub    $0x1c,%esp
f0101b07:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0101b0b:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101b0f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101b13:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101b17:	85 ed                	test   %ebp,%ebp
f0101b19:	89 f0                	mov    %esi,%eax
f0101b1b:	89 da                	mov    %ebx,%edx
f0101b1d:	75 19                	jne    f0101b38 <__umoddi3+0x38>
f0101b1f:	39 df                	cmp    %ebx,%edi
f0101b21:	0f 86 b1 00 00 00    	jbe    f0101bd8 <__umoddi3+0xd8>
f0101b27:	f7 f7                	div    %edi
f0101b29:	89 d0                	mov    %edx,%eax
f0101b2b:	31 d2                	xor    %edx,%edx
f0101b2d:	83 c4 1c             	add    $0x1c,%esp
f0101b30:	5b                   	pop    %ebx
f0101b31:	5e                   	pop    %esi
f0101b32:	5f                   	pop    %edi
f0101b33:	5d                   	pop    %ebp
f0101b34:	c3                   	ret    
f0101b35:	8d 76 00             	lea    0x0(%esi),%esi
f0101b38:	39 dd                	cmp    %ebx,%ebp
f0101b3a:	77 f1                	ja     f0101b2d <__umoddi3+0x2d>
f0101b3c:	0f bd cd             	bsr    %ebp,%ecx
f0101b3f:	83 f1 1f             	xor    $0x1f,%ecx
f0101b42:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101b46:	0f 84 b4 00 00 00    	je     f0101c00 <__umoddi3+0x100>
f0101b4c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101b51:	89 c2                	mov    %eax,%edx
f0101b53:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101b57:	29 c2                	sub    %eax,%edx
f0101b59:	89 c1                	mov    %eax,%ecx
f0101b5b:	89 f8                	mov    %edi,%eax
f0101b5d:	d3 e5                	shl    %cl,%ebp
f0101b5f:	89 d1                	mov    %edx,%ecx
f0101b61:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101b65:	d3 e8                	shr    %cl,%eax
f0101b67:	09 c5                	or     %eax,%ebp
f0101b69:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101b6d:	89 c1                	mov    %eax,%ecx
f0101b6f:	d3 e7                	shl    %cl,%edi
f0101b71:	89 d1                	mov    %edx,%ecx
f0101b73:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101b77:	89 df                	mov    %ebx,%edi
f0101b79:	d3 ef                	shr    %cl,%edi
f0101b7b:	89 c1                	mov    %eax,%ecx
f0101b7d:	89 f0                	mov    %esi,%eax
f0101b7f:	d3 e3                	shl    %cl,%ebx
f0101b81:	89 d1                	mov    %edx,%ecx
f0101b83:	89 fa                	mov    %edi,%edx
f0101b85:	d3 e8                	shr    %cl,%eax
f0101b87:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b8c:	09 d8                	or     %ebx,%eax
f0101b8e:	f7 f5                	div    %ebp
f0101b90:	d3 e6                	shl    %cl,%esi
f0101b92:	89 d1                	mov    %edx,%ecx
f0101b94:	f7 64 24 08          	mull   0x8(%esp)
f0101b98:	39 d1                	cmp    %edx,%ecx
f0101b9a:	89 c3                	mov    %eax,%ebx
f0101b9c:	89 d7                	mov    %edx,%edi
f0101b9e:	72 06                	jb     f0101ba6 <__umoddi3+0xa6>
f0101ba0:	75 0e                	jne    f0101bb0 <__umoddi3+0xb0>
f0101ba2:	39 c6                	cmp    %eax,%esi
f0101ba4:	73 0a                	jae    f0101bb0 <__umoddi3+0xb0>
f0101ba6:	2b 44 24 08          	sub    0x8(%esp),%eax
f0101baa:	19 ea                	sbb    %ebp,%edx
f0101bac:	89 d7                	mov    %edx,%edi
f0101bae:	89 c3                	mov    %eax,%ebx
f0101bb0:	89 ca                	mov    %ecx,%edx
f0101bb2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101bb7:	29 de                	sub    %ebx,%esi
f0101bb9:	19 fa                	sbb    %edi,%edx
f0101bbb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0101bbf:	89 d0                	mov    %edx,%eax
f0101bc1:	d3 e0                	shl    %cl,%eax
f0101bc3:	89 d9                	mov    %ebx,%ecx
f0101bc5:	d3 ee                	shr    %cl,%esi
f0101bc7:	d3 ea                	shr    %cl,%edx
f0101bc9:	09 f0                	or     %esi,%eax
f0101bcb:	83 c4 1c             	add    $0x1c,%esp
f0101bce:	5b                   	pop    %ebx
f0101bcf:	5e                   	pop    %esi
f0101bd0:	5f                   	pop    %edi
f0101bd1:	5d                   	pop    %ebp
f0101bd2:	c3                   	ret    
f0101bd3:	90                   	nop
f0101bd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101bd8:	85 ff                	test   %edi,%edi
f0101bda:	89 f9                	mov    %edi,%ecx
f0101bdc:	75 0b                	jne    f0101be9 <__umoddi3+0xe9>
f0101bde:	b8 01 00 00 00       	mov    $0x1,%eax
f0101be3:	31 d2                	xor    %edx,%edx
f0101be5:	f7 f7                	div    %edi
f0101be7:	89 c1                	mov    %eax,%ecx
f0101be9:	89 d8                	mov    %ebx,%eax
f0101beb:	31 d2                	xor    %edx,%edx
f0101bed:	f7 f1                	div    %ecx
f0101bef:	89 f0                	mov    %esi,%eax
f0101bf1:	f7 f1                	div    %ecx
f0101bf3:	e9 31 ff ff ff       	jmp    f0101b29 <__umoddi3+0x29>
f0101bf8:	90                   	nop
f0101bf9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101c00:	39 dd                	cmp    %ebx,%ebp
f0101c02:	72 08                	jb     f0101c0c <__umoddi3+0x10c>
f0101c04:	39 f7                	cmp    %esi,%edi
f0101c06:	0f 87 21 ff ff ff    	ja     f0101b2d <__umoddi3+0x2d>
f0101c0c:	89 da                	mov    %ebx,%edx
f0101c0e:	89 f0                	mov    %esi,%eax
f0101c10:	29 f8                	sub    %edi,%eax
f0101c12:	19 ea                	sbb    %ebp,%edx
f0101c14:	e9 14 ff ff ff       	jmp    f0101b2d <__umoddi3+0x2d>
