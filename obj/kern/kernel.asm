
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
f0100058:	c7 c0 c0 46 11 f0    	mov    $0xf01146c0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 e1 1a 00 00       	call   f0101b4a <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 98 fc fe ff    	lea    -0x10368(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 68 0f 00 00       	call   f0100fea <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 a5 0a 00 00       	call   f0100b2c <mem_init>
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
f01000b0:	c7 c0 c4 46 11 f0    	mov    $0xf01146c4,%eax
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
f01000da:	8d 83 b3 fc fe ff    	lea    -0x1034d(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 04 0f 00 00       	call   f0100fea <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 c3 0e 00 00       	call   f0100fb3 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 ef fc fe ff    	lea    -0x10311(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 ec 0e 00 00       	call   f0100fea <cprintf>
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
f010011f:	8d 83 cb fc fe ff    	lea    -0x10335(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 bf 0e 00 00       	call   f0100fea <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 7c 0e 00 00       	call   f0100fb3 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 ef fc fe ff    	lea    -0x10311(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 a5 0e 00 00       	call   f0100fea <cprintf>
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
f0100217:	0f b6 84 13 18 fe fe 	movzbl -0x101e8(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 18 fd fe 	movzbl -0x102e8(%ebx,%edx,1),%ecx
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
f010026a:	8d 83 e5 fc fe ff    	lea    -0x1031b(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 74 0d 00 00       	call   f0100fea <cprintf>
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
f01002b1:	0f b6 84 13 18 fe fe 	movzbl -0x101e8(%ebx,%edx,1),%eax
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
f01004d2:	e8 c0 16 00 00       	call   f0101b97 <memmove>
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
f01006b5:	8d 83 f1 fc fe ff    	lea    -0x1030f(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 29 09 00 00       	call   f0100fea <cprintf>
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
f0100708:	8d 83 18 ff fe ff    	lea    -0x100e8(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 36 ff fe ff    	lea    -0x100ca(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 3b ff fe ff    	lea    -0x100c5(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 c8 08 00 00       	call   f0100fea <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 a4 ff fe ff    	lea    -0x1005c(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 44 ff fe ff    	lea    -0x100bc(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 b1 08 00 00       	call   f0100fea <cprintf>
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
f0100759:	8d 83 4d ff fe ff    	lea    -0x100b3(%ebx),%eax
f010075f:	50                   	push   %eax
f0100760:	e8 85 08 00 00       	call   f0100fea <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100765:	83 c4 08             	add    $0x8,%esp
f0100768:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010076e:	8d 83 cc ff fe ff    	lea    -0x10034(%ebx),%eax
f0100774:	50                   	push   %eax
f0100775:	e8 70 08 00 00       	call   f0100fea <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010077a:	83 c4 0c             	add    $0xc,%esp
f010077d:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100783:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100789:	50                   	push   %eax
f010078a:	57                   	push   %edi
f010078b:	8d 83 f4 ff fe ff    	lea    -0x1000c(%ebx),%eax
f0100791:	50                   	push   %eax
f0100792:	e8 53 08 00 00       	call   f0100fea <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100797:	83 c4 0c             	add    $0xc,%esp
f010079a:	c7 c0 89 1f 10 f0    	mov    $0xf0101f89,%eax
f01007a0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007a6:	52                   	push   %edx
f01007a7:	50                   	push   %eax
f01007a8:	8d 83 18 00 ff ff    	lea    -0xffe8(%ebx),%eax
f01007ae:	50                   	push   %eax
f01007af:	e8 36 08 00 00       	call   f0100fea <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007b4:	83 c4 0c             	add    $0xc,%esp
f01007b7:	c7 c0 60 40 11 f0    	mov    $0xf0114060,%eax
f01007bd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007c3:	52                   	push   %edx
f01007c4:	50                   	push   %eax
f01007c5:	8d 83 3c 00 ff ff    	lea    -0xffc4(%ebx),%eax
f01007cb:	50                   	push   %eax
f01007cc:	e8 19 08 00 00       	call   f0100fea <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007d1:	83 c4 0c             	add    $0xc,%esp
f01007d4:	c7 c6 c0 46 11 f0    	mov    $0xf01146c0,%esi
f01007da:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007e0:	50                   	push   %eax
f01007e1:	56                   	push   %esi
f01007e2:	8d 83 60 00 ff ff    	lea    -0xffa0(%ebx),%eax
f01007e8:	50                   	push   %eax
f01007e9:	e8 fc 07 00 00       	call   f0100fea <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007ee:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007f1:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f01007f7:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f9:	c1 fe 0a             	sar    $0xa,%esi
f01007fc:	56                   	push   %esi
f01007fd:	8d 83 84 00 ff ff    	lea    -0xff7c(%ebx),%eax
f0100803:	50                   	push   %eax
f0100804:	e8 e1 07 00 00       	call   f0100fea <cprintf>
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
f0100834:	8d 83 b0 00 ff ff    	lea    -0xff50(%ebx),%eax
f010083a:	50                   	push   %eax
f010083b:	e8 aa 07 00 00       	call   f0100fea <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100840:	8d 83 d4 00 ff ff    	lea    -0xff2c(%ebx),%eax
f0100846:	89 04 24             	mov    %eax,(%esp)
f0100849:	e8 9c 07 00 00       	call   f0100fea <cprintf>
f010084e:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100851:	8d bb 6a ff fe ff    	lea    -0x10096(%ebx),%edi
f0100857:	eb 4a                	jmp    f01008a3 <monitor+0x83>
f0100859:	83 ec 08             	sub    $0x8,%esp
f010085c:	0f be c0             	movsbl %al,%eax
f010085f:	50                   	push   %eax
f0100860:	57                   	push   %edi
f0100861:	e8 a7 12 00 00       	call   f0101b0d <strchr>
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
f0100894:	8d 83 6f ff fe ff    	lea    -0x10091(%ebx),%eax
f010089a:	50                   	push   %eax
f010089b:	e8 4a 07 00 00       	call   f0100fea <cprintf>
f01008a0:	83 c4 10             	add    $0x10,%esp
	//cprintf("%d %d\n", sizeof(char), sizeof(int)); 
	// Nikhil won lol


	while (1) {
		buf = readline("K> ");
f01008a3:	8d 83 66 ff fe ff    	lea    -0x1009a(%ebx),%eax
f01008a9:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01008ac:	83 ec 0c             	sub    $0xc,%esp
f01008af:	ff 75 a4             	pushl  -0x5c(%ebp)
f01008b2:	e8 1e 10 00 00       	call   f01018d5 <readline>
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
f01008e2:	e8 26 12 00 00       	call   f0101b0d <strchr>
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
f010090b:	8d 83 36 ff fe ff    	lea    -0x100ca(%ebx),%eax
f0100911:	50                   	push   %eax
f0100912:	ff 75 a8             	pushl  -0x58(%ebp)
f0100915:	e8 95 11 00 00       	call   f0101aaf <strcmp>
f010091a:	83 c4 10             	add    $0x10,%esp
f010091d:	85 c0                	test   %eax,%eax
f010091f:	74 38                	je     f0100959 <monitor+0x139>
f0100921:	83 ec 08             	sub    $0x8,%esp
f0100924:	8d 83 44 ff fe ff    	lea    -0x100bc(%ebx),%eax
f010092a:	50                   	push   %eax
f010092b:	ff 75 a8             	pushl  -0x58(%ebp)
f010092e:	e8 7c 11 00 00       	call   f0101aaf <strcmp>
f0100933:	83 c4 10             	add    $0x10,%esp
f0100936:	85 c0                	test   %eax,%eax
f0100938:	74 1a                	je     f0100954 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f010093a:	83 ec 08             	sub    $0x8,%esp
f010093d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100940:	8d 83 8c ff fe ff    	lea    -0x10074(%ebx),%eax
f0100946:	50                   	push   %eax
f0100947:	e8 9e 06 00 00       	call   f0100fea <cprintf>
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
		
		if(finalAddress >= 0xffffffff) // 0xffffffff is 4GB Limit
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
f01009bc:	c7 c2 c0 46 11 f0    	mov    $0xf01146c0,%edx
f01009c2:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f01009c8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009ce:	89 93 90 1f 00 00    	mov    %edx,0x1f90(%ebx)
f01009d4:	eb c8                	jmp    f010099e <boot_alloc+0x1b>
		return nextfree;
f01009d6:	8b 83 90 1f 00 00    	mov    0x1f90(%ebx),%eax
f01009dc:	eb d9                	jmp    f01009b7 <boot_alloc+0x34>
			panic("out of memory\n");
f01009de:	83 ec 04             	sub    $0x4,%esp
f01009e1:	8d 83 f9 00 ff ff    	lea    -0xff07(%ebx),%eax
f01009e7:	50                   	push   %eax
f01009e8:	6a 7f                	push   $0x7f
f01009ea:	8d 83 08 01 ff ff    	lea    -0xfef8(%ebx),%eax
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
f0100a0d:	e8 51 05 00 00       	call   f0100f63 <mc146818_read>
f0100a12:	89 c6                	mov    %eax,%esi
f0100a14:	83 c7 01             	add    $0x1,%edi
f0100a17:	89 3c 24             	mov    %edi,(%esp)
f0100a1a:	e8 44 05 00 00       	call   f0100f63 <mc146818_read>
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
f0100a35:	e8 25 05 00 00       	call   f0100f5f <__x86.get_pc_thunk.di>
f0100a3a:	81 c7 ce 18 01 00    	add    $0x118ce,%edi
f0100a40:	89 fe                	mov    %edi,%esi
f0100a42:	89 7d f0             	mov    %edi,-0x10(%ebp)
	// However this is not truly the case.  What memory is free?
	//  1) Mark physical page 0 as in use.
	//     This way we preserve the real-mode IDT and BIOS structures
	//     in case we ever need them.  (Currently we don't, but...)
	
	pages[0].pp_ref = 1;
f0100a45:	c7 c0 d0 46 11 f0    	mov    $0xf01146d0,%eax
f0100a4b:	8b 00                	mov    (%eax),%eax
f0100a4d:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f0100a53:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	
	//  2) The rest of base memory, [PGSIZE, npages_basemem * PGSIZE)
	//     is free.
	
	size_t i;
	for(i = 1; i < npages_basemem; i++){
f0100a59:	8b bf 98 1f 00 00    	mov    0x1f98(%edi),%edi
f0100a5f:	8b 9e 94 1f 00 00    	mov    0x1f94(%esi),%ebx
f0100a65:	ba 00 00 00 00       	mov    $0x0,%edx
f0100a6a:	b8 01 00 00 00       	mov    $0x1,%eax
		pages[i].pp_ref = 0;
f0100a6f:	c7 c6 d0 46 11 f0    	mov    $0xf01146d0,%esi
	for(i = 1; i < npages_basemem; i++){
f0100a75:	eb 1f                	jmp    f0100a96 <page_init+0x6a>
		pages[i].pp_ref = 0;
f0100a77:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100a7e:	89 d1                	mov    %edx,%ecx
f0100a80:	03 0e                	add    (%esi),%ecx
f0100a82:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100a88:	89 19                	mov    %ebx,(%ecx)
	for(i = 1; i < npages_basemem; i++){
f0100a8a:	83 c0 01             	add    $0x1,%eax
		page_free_list = &pages[i];
f0100a8d:	89 d3                	mov    %edx,%ebx
f0100a8f:	03 1e                	add    (%esi),%ebx
f0100a91:	ba 01 00 00 00       	mov    $0x1,%edx
	for(i = 1; i < npages_basemem; i++){
f0100a96:	39 c7                	cmp    %eax,%edi
f0100a98:	77 dd                	ja     f0100a77 <page_init+0x4b>
f0100a9a:	84 d2                	test   %dl,%dl
f0100a9c:	75 49                	jne    f0100ae7 <page_init+0xbb>
f0100a9e:	b8 00 05 00 00       	mov    $0x500,%eax
	//     never be allocated.
	
	size_t iophysmem = IOPHYSMEM / PGSIZE;		// BUT WHAT ABOUT [npages_basemem, IOPHYSMEM)?
	size_t extphysmem = EXTPHYSMEM / PGSIZE;
	for(i = iophysmem; i < extphysmem; i++){
		pages[i].pp_ref = 1;
f0100aa3:	8b 7d f0             	mov    -0x10(%ebp),%edi
f0100aa6:	c7 c1 d0 46 11 f0    	mov    $0xf01146d0,%ecx
f0100aac:	89 c2                	mov    %eax,%edx
f0100aae:	03 11                	add    (%ecx),%edx
f0100ab0:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
		pages[i].pp_link = NULL;
f0100ab6:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0100abc:	83 c0 08             	add    $0x8,%eax
	for(i = iophysmem; i < extphysmem; i++){
f0100abf:	3d 00 08 00 00       	cmp    $0x800,%eax
f0100ac4:	75 e6                	jne    f0100aac <page_init+0x80>
f0100ac6:	8b 75 f0             	mov    -0x10(%ebp),%esi
f0100ac9:	8b 9e 94 1f 00 00    	mov    0x1f94(%esi),%ebx
f0100acf:	ba 00 00 00 00       	mov    $0x0,%edx
	//     Some of it is in use, some is free. Where is the kernel
	//     in physical memory?  Which pages are already in use for
	//     page tables and other data structures?
	//
	
	for(i = extphysmem; i < npages; i++){
f0100ad4:	b8 00 01 00 00       	mov    $0x100,%eax
f0100ad9:	c7 c7 c8 46 11 f0    	mov    $0xf01146c8,%edi
		pages[i].pp_ref = 0;
f0100adf:	c7 c6 d0 46 11 f0    	mov    $0xf01146d0,%esi
f0100ae5:	eb 2a                	jmp    f0100b11 <page_init+0xe5>
f0100ae7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100aea:	89 98 94 1f 00 00    	mov    %ebx,0x1f94(%eax)
f0100af0:	eb ac                	jmp    f0100a9e <page_init+0x72>
f0100af2:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100af9:	89 d1                	mov    %edx,%ecx
f0100afb:	03 0e                	add    (%esi),%ecx
f0100afd:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100b03:	89 19                	mov    %ebx,(%ecx)
	for(i = extphysmem; i < npages; i++){
f0100b05:	83 c0 01             	add    $0x1,%eax
		page_free_list = &pages[i];
f0100b08:	89 d3                	mov    %edx,%ebx
f0100b0a:	03 1e                	add    (%esi),%ebx
f0100b0c:	ba 01 00 00 00       	mov    $0x1,%edx
	for(i = extphysmem; i < npages; i++){
f0100b11:	39 07                	cmp    %eax,(%edi)
f0100b13:	77 dd                	ja     f0100af2 <page_init+0xc6>
f0100b15:	84 d2                	test   %dl,%dl
f0100b17:	75 08                	jne    f0100b21 <page_init+0xf5>
	// 	pages[i].pp_ref = 0;
	// 	pages[i].pp_link = page_free_list;
	// 	page_free_list = &pages[i];
	// 	//cprintf("%d -> %p\n", i, page_free_list);
	// }
}
f0100b19:	83 c4 04             	add    $0x4,%esp
f0100b1c:	5b                   	pop    %ebx
f0100b1d:	5e                   	pop    %esi
f0100b1e:	5f                   	pop    %edi
f0100b1f:	5d                   	pop    %ebp
f0100b20:	c3                   	ret    
f0100b21:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100b24:	89 98 94 1f 00 00    	mov    %ebx,0x1f94(%eax)
f0100b2a:	eb ed                	jmp    f0100b19 <page_init+0xed>

f0100b2c <mem_init>:
{
f0100b2c:	55                   	push   %ebp
f0100b2d:	89 e5                	mov    %esp,%ebp
f0100b2f:	57                   	push   %edi
f0100b30:	56                   	push   %esi
f0100b31:	53                   	push   %ebx
f0100b32:	83 ec 0c             	sub    $0xc,%esp
f0100b35:	e8 15 f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100b3a:	81 c3 ce 17 01 00    	add    $0x117ce,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f0100b40:	b8 15 00 00 00       	mov    $0x15,%eax
f0100b45:	e8 ac fe ff ff       	call   f01009f6 <nvram_read>
f0100b4a:	89 c6                	mov    %eax,%esi
	extmem = nvram_read(NVRAM_EXTLO);
f0100b4c:	b8 17 00 00 00       	mov    $0x17,%eax
f0100b51:	e8 a0 fe ff ff       	call   f01009f6 <nvram_read>
f0100b56:	89 c7                	mov    %eax,%edi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100b58:	b8 34 00 00 00       	mov    $0x34,%eax
f0100b5d:	e8 94 fe ff ff       	call   f01009f6 <nvram_read>
f0100b62:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0100b65:	85 c0                	test   %eax,%eax
f0100b67:	75 0e                	jne    f0100b77 <mem_init+0x4b>
		totalmem = basemem;
f0100b69:	89 f0                	mov    %esi,%eax
	else if (extmem)
f0100b6b:	85 ff                	test   %edi,%edi
f0100b6d:	74 0d                	je     f0100b7c <mem_init+0x50>
		totalmem = 1 * 1024 + extmem;
f0100b6f:	8d 87 00 04 00 00    	lea    0x400(%edi),%eax
f0100b75:	eb 05                	jmp    f0100b7c <mem_init+0x50>
		totalmem = 16 * 1024 + ext16mem;
f0100b77:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f0100b7c:	89 c1                	mov    %eax,%ecx
f0100b7e:	c1 e9 02             	shr    $0x2,%ecx
f0100b81:	c7 c2 c8 46 11 f0    	mov    $0xf01146c8,%edx
f0100b87:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f0100b89:	89 f2                	mov    %esi,%edx
f0100b8b:	c1 ea 02             	shr    $0x2,%edx
f0100b8e:	89 93 98 1f 00 00    	mov    %edx,0x1f98(%ebx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100b94:	89 c2                	mov    %eax,%edx
f0100b96:	29 f2                	sub    %esi,%edx
f0100b98:	52                   	push   %edx
f0100b99:	56                   	push   %esi
f0100b9a:	50                   	push   %eax
f0100b9b:	8d 83 5c 01 ff ff    	lea    -0xfea4(%ebx),%eax
f0100ba1:	50                   	push   %eax
f0100ba2:	e8 43 04 00 00       	call   f0100fea <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100ba7:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100bac:	e8 d2 fd ff ff       	call   f0100983 <boot_alloc>
f0100bb1:	c7 c6 cc 46 11 f0    	mov    $0xf01146cc,%esi
f0100bb7:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f0100bb9:	83 c4 0c             	add    $0xc,%esp
f0100bbc:	68 00 10 00 00       	push   $0x1000
f0100bc1:	6a 00                	push   $0x0
f0100bc3:	50                   	push   %eax
f0100bc4:	e8 81 0f 00 00       	call   f0101b4a <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100bc9:	8b 06                	mov    (%esi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100bcb:	83 c4 10             	add    $0x10,%esp
f0100bce:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100bd3:	77 19                	ja     f0100bee <mem_init+0xc2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100bd5:	50                   	push   %eax
f0100bd6:	8d 83 98 01 ff ff    	lea    -0xfe68(%ebx),%eax
f0100bdc:	50                   	push   %eax
f0100bdd:	68 a8 00 00 00       	push   $0xa8
f0100be2:	8d 83 08 01 ff ff    	lea    -0xfef8(%ebx),%eax
f0100be8:	50                   	push   %eax
f0100be9:	e8 ab f4 ff ff       	call   f0100099 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100bee:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100bf4:	83 ca 05             	or     $0x5,%edx
f0100bf7:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0100bfd:	c7 c6 c8 46 11 f0    	mov    $0xf01146c8,%esi
f0100c03:	8b 06                	mov    (%esi),%eax
f0100c05:	c1 e0 03             	shl    $0x3,%eax
f0100c08:	e8 76 fd ff ff       	call   f0100983 <boot_alloc>
f0100c0d:	c7 c7 d0 46 11 f0    	mov    $0xf01146d0,%edi
f0100c13:	89 07                	mov    %eax,(%edi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0100c15:	83 ec 04             	sub    $0x4,%esp
f0100c18:	8b 0e                	mov    (%esi),%ecx
f0100c1a:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0100c21:	52                   	push   %edx
f0100c22:	6a 00                	push   $0x0
f0100c24:	50                   	push   %eax
f0100c25:	e8 20 0f 00 00       	call   f0101b4a <memset>
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0100c2a:	8b 06                	mov    (%esi),%eax
f0100c2c:	c1 e0 03             	shl    $0x3,%eax
f0100c2f:	e8 4f fd ff ff       	call   f0100983 <boot_alloc>
f0100c34:	89 07                	mov    %eax,(%edi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0100c36:	83 c4 0c             	add    $0xc,%esp
f0100c39:	8b 16                	mov    (%esi),%edx
f0100c3b:	c1 e2 03             	shl    $0x3,%edx
f0100c3e:	52                   	push   %edx
f0100c3f:	6a 00                	push   $0x0
f0100c41:	50                   	push   %eax
f0100c42:	e8 03 0f 00 00       	call   f0101b4a <memset>
	page_init();
f0100c47:	e8 e0 fd ff ff       	call   f0100a2c <page_init>
	panic("mem_init: This function is not finished\n");
f0100c4c:	83 c4 0c             	add    $0xc,%esp
f0100c4f:	8d 83 bc 01 ff ff    	lea    -0xfe44(%ebx),%eax
f0100c55:	50                   	push   %eax
f0100c56:	68 d7 00 00 00       	push   $0xd7
f0100c5b:	8d 83 08 01 ff ff    	lea    -0xfef8(%ebx),%eax
f0100c61:	50                   	push   %eax
f0100c62:	e8 32 f4 ff ff       	call   f0100099 <_panic>

f0100c67 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100c67:	55                   	push   %ebp
f0100c68:	89 e5                	mov    %esp,%ebp
f0100c6a:	56                   	push   %esi
f0100c6b:	53                   	push   %ebx
f0100c6c:	e8 de f4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100c71:	81 c3 97 16 01 00    	add    $0x11697,%ebx
	// Fill this function in
	struct PageInfo *page_pop = page_free_list;
f0100c77:	8b b3 94 1f 00 00    	mov    0x1f94(%ebx),%esi
	// If there are no free pages, we need to return NULL, indicating an error
	if (page_pop == NULL)
f0100c7d:	85 f6                	test   %esi,%esi
f0100c7f:	74 1a                	je     f0100c9b <page_alloc+0x34>
	{
		return NULL;
	}

	page_free_list = page_pop->pp_link;
f0100c81:	8b 06                	mov    (%esi),%eax
f0100c83:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	page_pop->pp_ref = 1; // Mark in-use
f0100c89:	66 c7 46 04 01 00    	movw   $0x1,0x4(%esi)
	page_pop->pp_link = NULL; 
f0100c8f:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	
	if (alloc_flags & ALLOC_ZERO)
f0100c95:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100c99:	75 09                	jne    f0100ca4 <page_alloc+0x3d>
	{
		struct PageInfo *ptr = page2kva(page_pop); // Convert physical page address to virtual
		memset(ptr, 0, PGSIZE);
	}
	return page_pop;
}
f0100c9b:	89 f0                	mov    %esi,%eax
f0100c9d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ca0:	5b                   	pop    %ebx
f0100ca1:	5e                   	pop    %esi
f0100ca2:	5d                   	pop    %ebp
f0100ca3:	c3                   	ret    
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ca4:	c7 c0 d0 46 11 f0    	mov    $0xf01146d0,%eax
f0100caa:	89 f2                	mov    %esi,%edx
f0100cac:	2b 10                	sub    (%eax),%edx
f0100cae:	89 d0                	mov    %edx,%eax
f0100cb0:	c1 f8 03             	sar    $0x3,%eax
f0100cb3:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100cb6:	89 c1                	mov    %eax,%ecx
f0100cb8:	c1 e9 0c             	shr    $0xc,%ecx
f0100cbb:	c7 c2 c8 46 11 f0    	mov    $0xf01146c8,%edx
f0100cc1:	3b 0a                	cmp    (%edx),%ecx
f0100cc3:	73 1a                	jae    f0100cdf <page_alloc+0x78>
		memset(ptr, 0, PGSIZE);
f0100cc5:	83 ec 04             	sub    $0x4,%esp
f0100cc8:	68 00 10 00 00       	push   $0x1000
f0100ccd:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100ccf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cd4:	50                   	push   %eax
f0100cd5:	e8 70 0e 00 00       	call   f0101b4a <memset>
f0100cda:	83 c4 10             	add    $0x10,%esp
f0100cdd:	eb bc                	jmp    f0100c9b <page_alloc+0x34>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cdf:	50                   	push   %eax
f0100ce0:	8d 83 e8 01 ff ff    	lea    -0xfe18(%ebx),%eax
f0100ce6:	50                   	push   %eax
f0100ce7:	6a 52                	push   $0x52
f0100ce9:	8d 83 14 01 ff ff    	lea    -0xfeec(%ebx),%eax
f0100cef:	50                   	push   %eax
f0100cf0:	e8 a4 f3 ff ff       	call   f0100099 <_panic>

f0100cf5 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100cf5:	55                   	push   %ebp
f0100cf6:	89 e5                	mov    %esp,%ebp
f0100cf8:	53                   	push   %ebx
f0100cf9:	83 ec 04             	sub    $0x4,%esp
f0100cfc:	e8 4e f4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100d01:	81 c3 07 16 01 00    	add    $0x11607,%ebx
f0100d07:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	assert(pp->pp_ref == 0);  
f0100d0a:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100d0f:	75 18                	jne    f0100d29 <page_free+0x34>
	// If there are links to this page (i.e., pp_ref is non-zero), that means that the page cannot be freed
	// We must then initate a panic	

	assert(pp->pp_link == NULL); 
f0100d11:	83 38 00             	cmpl   $0x0,(%eax)
f0100d14:	75 32                	jne    f0100d48 <page_free+0x53>
	// Same thing as above, except we need to check if pp doesn't already point to a free page

	pp->pp_link = page_free_list;
f0100d16:	8b 8b 94 1f 00 00    	mov    0x1f94(%ebx),%ecx
f0100d1c:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f0100d1e:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.

}
f0100d24:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d27:	c9                   	leave  
f0100d28:	c3                   	ret    
	assert(pp->pp_ref == 0);  
f0100d29:	8d 83 22 01 ff ff    	lea    -0xfede(%ebx),%eax
f0100d2f:	50                   	push   %eax
f0100d30:	8d 83 32 01 ff ff    	lea    -0xfece(%ebx),%eax
f0100d36:	50                   	push   %eax
f0100d37:	68 8c 01 00 00       	push   $0x18c
f0100d3c:	8d 83 08 01 ff ff    	lea    -0xfef8(%ebx),%eax
f0100d42:	50                   	push   %eax
f0100d43:	e8 51 f3 ff ff       	call   f0100099 <_panic>
	assert(pp->pp_link == NULL); 
f0100d48:	8d 83 47 01 ff ff    	lea    -0xfeb9(%ebx),%eax
f0100d4e:	50                   	push   %eax
f0100d4f:	8d 83 32 01 ff ff    	lea    -0xfece(%ebx),%eax
f0100d55:	50                   	push   %eax
f0100d56:	68 90 01 00 00       	push   $0x190
f0100d5b:	8d 83 08 01 ff ff    	lea    -0xfef8(%ebx),%eax
f0100d61:	50                   	push   %eax
f0100d62:	e8 32 f3 ff ff       	call   f0100099 <_panic>

f0100d67 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100d67:	55                   	push   %ebp
f0100d68:	89 e5                	mov    %esp,%ebp
f0100d6a:	83 ec 08             	sub    $0x8,%esp
f0100d6d:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100d70:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100d74:	83 e8 01             	sub    $0x1,%eax
f0100d77:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100d7b:	66 85 c0             	test   %ax,%ax
f0100d7e:	74 02                	je     f0100d82 <page_decref+0x1b>
		page_free(pp);
}
f0100d80:	c9                   	leave  
f0100d81:	c3                   	ret    
		page_free(pp);
f0100d82:	83 ec 0c             	sub    $0xc,%esp
f0100d85:	52                   	push   %edx
f0100d86:	e8 6a ff ff ff       	call   f0100cf5 <page_free>
f0100d8b:	83 c4 10             	add    $0x10,%esp
}
f0100d8e:	eb f0                	jmp    f0100d80 <page_decref+0x19>

f0100d90 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100d90:	55                   	push   %ebp
f0100d91:	89 e5                	mov    %esp,%ebp
f0100d93:	57                   	push   %edi
f0100d94:	56                   	push   %esi
f0100d95:	53                   	push   %ebx
f0100d96:	83 ec 0c             	sub    $0xc,%esp
f0100d99:	e8 b1 f3 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100d9e:	81 c3 6a 15 01 00    	add    $0x1156a,%ebx
f0100da4:	8b 75 0c             	mov    0xc(%ebp),%esi

	// Linear Address VA exists in Page Directory pgdir
	// We will access this by doing pgdir[va] but we first need to translate from virtual to physical
	
	// We will use PDX(la) for this
	uintptr_t pd_index = PDX(va);
f0100da7:	89 f7                	mov    %esi,%edi
f0100da9:	c1 ef 16             	shr    $0x16,%edi
	pde_t pd_entry = pgdir[pd_index];
f0100dac:	c1 e7 02             	shl    $0x2,%edi
f0100daf:	03 7d 08             	add    0x8(%ebp),%edi
f0100db2:	8b 07                	mov    (%edi),%eax

	// PART 1: Page Table Entry does not exist 

	// If pd_entry is NULL, that means that the corresponding page table doesn't exist
	if (pd_entry == 0) 
f0100db4:	85 c0                	test   %eax,%eax
f0100db6:	75 2c                	jne    f0100de4 <pgdir_walk+0x54>
	{
		if (create == 0) // create 0 implies we don't want to initialize a new page dir entry
f0100db8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100dbc:	74 6b                	je     f0100e29 <pgdir_walk+0x99>
		}
		else 
		{
			// Now that create is not 0, we can use page_alloc() to create a new page
			struct PageInfo *newpg;
			newpg = page_alloc(ALLOC_ZERO);
f0100dbe:	83 ec 0c             	sub    $0xc,%esp
f0100dc1:	6a 01                	push   $0x1
f0100dc3:	e8 9f fe ff ff       	call   f0100c67 <page_alloc>
			// Page alloc returns NULL if there are no more free pages
			if (newpg == NULL)
f0100dc8:	83 c4 10             	add    $0x10,%esp
f0100dcb:	85 c0                	test   %eax,%eax
f0100dcd:	74 61                	je     f0100e30 <pgdir_walk+0xa0>
			{
				return NULL;
			}
			// Else, since there is one more reference to this page, we will update pp_ref of the newly allocated page
			newpg->pp_ref += 1;
f0100dcf:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0100dd4:	c7 c2 d0 46 11 f0    	mov    $0xf01146d0,%edx
f0100dda:	2b 02                	sub    (%edx),%eax
f0100ddc:	c1 f8 03             	sar    $0x3,%eax
f0100ddf:	c1 e0 0c             	shl    $0xc,%eax


			// Converting the allocated page's address from virtual to physical
			// and storing it in the page directory 
			pd_entry = page2pa(newpg);
			pgdir[pd_index] = pd_entry;
f0100de2:	89 07                	mov    %eax,(%edi)
		}

	}

	// PART 2: Page Table Entry exists
	physaddr_t pt_physadd = PTE_ADDR(pd_entry); // Now we have the physical address of the page table
f0100de4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100de9:	89 c1                	mov    %eax,%ecx
f0100deb:	c1 e9 0c             	shr    $0xc,%ecx
f0100dee:	c7 c2 c8 46 11 f0    	mov    $0xf01146c8,%edx
f0100df4:	3b 0a                	cmp    (%edx),%ecx
f0100df6:	73 18                	jae    f0100e10 <pgdir_walk+0x80>
	pde_t *pt_virtadd = KADDR(pt_physadd); // Now we have a pointer to the virtual address of page table
	uintptr_t pt_index = PTX(va); // Here, we get an index into the page table 
f0100df8:	c1 ee 0c             	shr    $0xc,%esi
f0100dfb:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	pte_t *pt_entry = (pte_t *)pt_virtadd[pt_index]; // Finally, we have a pointer to the page table entry that we can now return
f0100e01:	8b 84 b0 00 00 00 f0 	mov    -0x10000000(%eax,%esi,4),%eax

	return pt_entry;
}
f0100e08:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e0b:	5b                   	pop    %ebx
f0100e0c:	5e                   	pop    %esi
f0100e0d:	5f                   	pop    %edi
f0100e0e:	5d                   	pop    %ebp
f0100e0f:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e10:	50                   	push   %eax
f0100e11:	8d 83 e8 01 ff ff    	lea    -0xfe18(%ebx),%eax
f0100e17:	50                   	push   %eax
f0100e18:	68 eb 01 00 00       	push   $0x1eb
f0100e1d:	8d 83 08 01 ff ff    	lea    -0xfef8(%ebx),%eax
f0100e23:	50                   	push   %eax
f0100e24:	e8 70 f2 ff ff       	call   f0100099 <_panic>
			return NULL;
f0100e29:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e2e:	eb d8                	jmp    f0100e08 <pgdir_walk+0x78>
				return NULL;
f0100e30:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e35:	eb d1                	jmp    f0100e08 <pgdir_walk+0x78>

f0100e37 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100e37:	55                   	push   %ebp
f0100e38:	89 e5                	mov    %esp,%ebp
f0100e3a:	56                   	push   %esi
f0100e3b:	53                   	push   %ebx
f0100e3c:	e8 0e f3 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100e41:	81 c3 c7 14 01 00    	add    $0x114c7,%ebx
f0100e47:	8b 75 10             	mov    0x10(%ebp),%esi

	// we have pgdir
	// we have virtual address va
	// we have pte_store, which is a double pointer, 

	pte_t * pt_entry = pgdir_walk(pgdir, (void *) va, 0);
f0100e4a:	83 ec 04             	sub    $0x4,%esp
f0100e4d:	6a 00                	push   $0x0
f0100e4f:	ff 75 0c             	pushl  0xc(%ebp)
f0100e52:	ff 75 08             	pushl  0x8(%ebp)
f0100e55:	e8 36 ff ff ff       	call   f0100d90 <pgdir_walk>
	
	if(!pt_entry){
f0100e5a:	83 c4 10             	add    $0x10,%esp
f0100e5d:	85 c0                	test   %eax,%eax
f0100e5f:	74 3d                	je     f0100e9e <page_lookup+0x67>
		return NULL;
	}

	if(pte_store != 0){
f0100e61:	85 f6                	test   %esi,%esi
f0100e63:	74 02                	je     f0100e67 <page_lookup+0x30>
		// we're dereferencing a double-pointer, and storing the pt_entry for future usage
		*pte_store = pt_entry;
f0100e65:	89 06                	mov    %eax,(%esi)
f0100e67:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e6a:	c7 c2 c8 46 11 f0    	mov    $0xf01146c8,%edx
f0100e70:	39 02                	cmp    %eax,(%edx)
f0100e72:	76 12                	jbe    f0100e86 <page_lookup+0x4f>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0100e74:	c7 c2 d0 46 11 f0    	mov    $0xf01146d0,%edx
f0100e7a:	8b 12                	mov    (%edx),%edx
f0100e7c:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	physaddr_t pt_physadd = PTE_ADDR(pt_entry);
	// get the page using the physical address
	struct PageInfo *page = pa2page(pt_physadd);
	// return pointer to page
	return page; 
}
f0100e7f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e82:	5b                   	pop    %ebx
f0100e83:	5e                   	pop    %esi
f0100e84:	5d                   	pop    %ebp
f0100e85:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0100e86:	83 ec 04             	sub    $0x4,%esp
f0100e89:	8d 83 0c 02 ff ff    	lea    -0xfdf4(%ebx),%eax
f0100e8f:	50                   	push   %eax
f0100e90:	6a 4b                	push   $0x4b
f0100e92:	8d 83 14 01 ff ff    	lea    -0xfeec(%ebx),%eax
f0100e98:	50                   	push   %eax
f0100e99:	e8 fb f1 ff ff       	call   f0100099 <_panic>
		return NULL;
f0100e9e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ea3:	eb da                	jmp    f0100e7f <page_lookup+0x48>

f0100ea5 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100ea5:	55                   	push   %ebp
f0100ea6:	89 e5                	mov    %esp,%ebp
f0100ea8:	53                   	push   %ebx
f0100ea9:	83 ec 18             	sub    $0x18,%esp
f0100eac:	8b 5d 0c             	mov    0xc(%ebp),%ebx

	// initialize a store pointer for page table entry
	pte_t *pt_entry_store;

	// hitting up page_lookup with pgdir and va
	struct PageInfo * page = page_lookup(pgdir, va, &pt_entry_store);
f0100eaf:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100eb2:	50                   	push   %eax
f0100eb3:	53                   	push   %ebx
f0100eb4:	ff 75 08             	pushl  0x8(%ebp)
f0100eb7:	e8 7b ff ff ff       	call   f0100e37 <page_lookup>
	// if(page->pp_ref == 0){
	// 	page_free(page);
	// }

	// Nikhil discovered that page_decref does all of this automatically, making Soham look stupid
	page_decref(page);
f0100ebc:	89 04 24             	mov    %eax,(%esp)
f0100ebf:	e8 a3 fe ff ff       	call   f0100d67 <page_decref>
	
	// if page table entry exists, we set it to zero
	if(pt_entry_store != 0){
f0100ec4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ec7:	83 c4 10             	add    $0x10,%esp
f0100eca:	85 c0                	test   %eax,%eax
f0100ecc:	74 06                	je     f0100ed4 <page_remove+0x2f>
		*pt_entry_store = 0;
f0100ece:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100ed4:	0f 01 3b             	invlpg (%ebx)

	// calling tlb_invalidate to abstract away the work for us
	// will we ever find out what it does? no. 
	tlb_invalidate(pgdir, va);
	// Fill this function in
}
f0100ed7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100eda:	c9                   	leave  
f0100edb:	c3                   	ret    

f0100edc <page_insert>:
{
f0100edc:	55                   	push   %ebp
f0100edd:	89 e5                	mov    %esp,%ebp
f0100edf:	57                   	push   %edi
f0100ee0:	56                   	push   %esi
f0100ee1:	53                   	push   %ebx
f0100ee2:	83 ec 10             	sub    $0x10,%esp
f0100ee5:	e8 75 00 00 00       	call   f0100f5f <__x86.get_pc_thunk.di>
f0100eea:	81 c7 1e 14 01 00    	add    $0x1141e,%edi
f0100ef0:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pt_entry = pgdir_walk(pgdir, va, 1);
f0100ef3:	6a 01                	push   $0x1
f0100ef5:	ff 75 10             	pushl  0x10(%ebp)
f0100ef8:	ff 75 08             	pushl  0x8(%ebp)
f0100efb:	e8 90 fe ff ff       	call   f0100d90 <pgdir_walk>
	if(pt_entry == NULL){
f0100f00:	83 c4 10             	add    $0x10,%esp
f0100f03:	85 c0                	test   %eax,%eax
f0100f05:	74 46                	je     f0100f4d <page_insert+0x71>
f0100f07:	89 c3                	mov    %eax,%ebx
	pp->pp_ref += 1;
f0100f09:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	if((*pt_entry & PTE_P) != 0){ // check permissions
f0100f0e:	f6 00 01             	testb  $0x1,(%eax)
f0100f11:	75 27                	jne    f0100f3a <page_insert+0x5e>
	return (pp - pages) << PGSHIFT;
f0100f13:	c7 c0 d0 46 11 f0    	mov    $0xf01146d0,%eax
f0100f19:	2b 30                	sub    (%eax),%esi
f0100f1b:	89 f0                	mov    %esi,%eax
f0100f1d:	c1 f8 03             	sar    $0x3,%eax
f0100f20:	c1 e0 0c             	shl    $0xc,%eax
	*pt_entry = page2pa(pp) | perm | PTE_P; // permissions from comments, but what does it mean?
f0100f23:	8b 55 14             	mov    0x14(%ebp),%edx
f0100f26:	83 ca 01             	or     $0x1,%edx
f0100f29:	09 d0                	or     %edx,%eax
f0100f2b:	89 03                	mov    %eax,(%ebx)
	return 0;
f0100f2d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100f32:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f35:	5b                   	pop    %ebx
f0100f36:	5e                   	pop    %esi
f0100f37:	5f                   	pop    %edi
f0100f38:	5d                   	pop    %ebp
f0100f39:	c3                   	ret    
		page_remove(pgdir, va);
f0100f3a:	83 ec 08             	sub    $0x8,%esp
f0100f3d:	ff 75 10             	pushl  0x10(%ebp)
f0100f40:	ff 75 08             	pushl  0x8(%ebp)
f0100f43:	e8 5d ff ff ff       	call   f0100ea5 <page_remove>
f0100f48:	83 c4 10             	add    $0x10,%esp
f0100f4b:	eb c6                	jmp    f0100f13 <page_insert+0x37>
		return -E_NO_MEM;
f0100f4d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0100f52:	eb de                	jmp    f0100f32 <page_insert+0x56>

f0100f54 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100f54:	55                   	push   %ebp
f0100f55:	89 e5                	mov    %esp,%ebp
f0100f57:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f5a:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100f5d:	5d                   	pop    %ebp
f0100f5e:	c3                   	ret    

f0100f5f <__x86.get_pc_thunk.di>:
f0100f5f:	8b 3c 24             	mov    (%esp),%edi
f0100f62:	c3                   	ret    

f0100f63 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100f63:	55                   	push   %ebp
f0100f64:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100f66:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f69:	ba 70 00 00 00       	mov    $0x70,%edx
f0100f6e:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100f6f:	ba 71 00 00 00       	mov    $0x71,%edx
f0100f74:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100f75:	0f b6 c0             	movzbl %al,%eax
}
f0100f78:	5d                   	pop    %ebp
f0100f79:	c3                   	ret    

f0100f7a <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100f7a:	55                   	push   %ebp
f0100f7b:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100f7d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f80:	ba 70 00 00 00       	mov    $0x70,%edx
f0100f85:	ee                   	out    %al,(%dx)
f0100f86:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f89:	ba 71 00 00 00       	mov    $0x71,%edx
f0100f8e:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100f8f:	5d                   	pop    %ebp
f0100f90:	c3                   	ret    

f0100f91 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100f91:	55                   	push   %ebp
f0100f92:	89 e5                	mov    %esp,%ebp
f0100f94:	53                   	push   %ebx
f0100f95:	83 ec 10             	sub    $0x10,%esp
f0100f98:	e8 b2 f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100f9d:	81 c3 6b 13 01 00    	add    $0x1136b,%ebx
	cputchar(ch);
f0100fa3:	ff 75 08             	pushl  0x8(%ebp)
f0100fa6:	e8 1b f7 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f0100fab:	83 c4 10             	add    $0x10,%esp
f0100fae:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fb1:	c9                   	leave  
f0100fb2:	c3                   	ret    

f0100fb3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100fb3:	55                   	push   %ebp
f0100fb4:	89 e5                	mov    %esp,%ebp
f0100fb6:	53                   	push   %ebx
f0100fb7:	83 ec 14             	sub    $0x14,%esp
f0100fba:	e8 90 f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100fbf:	81 c3 49 13 01 00    	add    $0x11349,%ebx
	int cnt = 0;
f0100fc5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100fcc:	ff 75 0c             	pushl  0xc(%ebp)
f0100fcf:	ff 75 08             	pushl  0x8(%ebp)
f0100fd2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fd5:	50                   	push   %eax
f0100fd6:	8d 83 89 ec fe ff    	lea    -0x11377(%ebx),%eax
f0100fdc:	50                   	push   %eax
f0100fdd:	e8 1c 04 00 00       	call   f01013fe <vprintfmt>
	return cnt;
}
f0100fe2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100fe5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fe8:	c9                   	leave  
f0100fe9:	c3                   	ret    

f0100fea <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100fea:	55                   	push   %ebp
f0100feb:	89 e5                	mov    %esp,%ebp
f0100fed:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100ff0:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100ff3:	50                   	push   %eax
f0100ff4:	ff 75 08             	pushl  0x8(%ebp)
f0100ff7:	e8 b7 ff ff ff       	call   f0100fb3 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100ffc:	c9                   	leave  
f0100ffd:	c3                   	ret    

f0100ffe <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100ffe:	55                   	push   %ebp
f0100fff:	89 e5                	mov    %esp,%ebp
f0101001:	57                   	push   %edi
f0101002:	56                   	push   %esi
f0101003:	53                   	push   %ebx
f0101004:	83 ec 14             	sub    $0x14,%esp
f0101007:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010100a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010100d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101010:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101013:	8b 32                	mov    (%edx),%esi
f0101015:	8b 01                	mov    (%ecx),%eax
f0101017:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010101a:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0101021:	eb 2f                	jmp    f0101052 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0101023:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0101026:	39 c6                	cmp    %eax,%esi
f0101028:	7f 49                	jg     f0101073 <stab_binsearch+0x75>
f010102a:	0f b6 0a             	movzbl (%edx),%ecx
f010102d:	83 ea 0c             	sub    $0xc,%edx
f0101030:	39 f9                	cmp    %edi,%ecx
f0101032:	75 ef                	jne    f0101023 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101034:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101037:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010103a:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010103e:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0101041:	73 35                	jae    f0101078 <stab_binsearch+0x7a>
			*region_left = m;
f0101043:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101046:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0101048:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f010104b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0101052:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0101055:	7f 4e                	jg     f01010a5 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0101057:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010105a:	01 f0                	add    %esi,%eax
f010105c:	89 c3                	mov    %eax,%ebx
f010105e:	c1 eb 1f             	shr    $0x1f,%ebx
f0101061:	01 c3                	add    %eax,%ebx
f0101063:	d1 fb                	sar    %ebx
f0101065:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0101068:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010106b:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f010106f:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0101071:	eb b3                	jmp    f0101026 <stab_binsearch+0x28>
			l = true_m + 1;
f0101073:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0101076:	eb da                	jmp    f0101052 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0101078:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010107b:	76 14                	jbe    f0101091 <stab_binsearch+0x93>
			*region_right = m - 1;
f010107d:	83 e8 01             	sub    $0x1,%eax
f0101080:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101083:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101086:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0101088:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010108f:	eb c1                	jmp    f0101052 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0101091:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101094:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0101096:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010109a:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f010109c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01010a3:	eb ad                	jmp    f0101052 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f01010a5:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01010a9:	74 16                	je     f01010c1 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01010ab:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010ae:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01010b0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01010b3:	8b 0e                	mov    (%esi),%ecx
f01010b5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01010b8:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01010bb:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f01010bf:	eb 12                	jmp    f01010d3 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f01010c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010c4:	8b 00                	mov    (%eax),%eax
f01010c6:	83 e8 01             	sub    $0x1,%eax
f01010c9:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01010cc:	89 07                	mov    %eax,(%edi)
f01010ce:	eb 16                	jmp    f01010e6 <stab_binsearch+0xe8>
		     l--)
f01010d0:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01010d3:	39 c1                	cmp    %eax,%ecx
f01010d5:	7d 0a                	jge    f01010e1 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f01010d7:	0f b6 1a             	movzbl (%edx),%ebx
f01010da:	83 ea 0c             	sub    $0xc,%edx
f01010dd:	39 fb                	cmp    %edi,%ebx
f01010df:	75 ef                	jne    f01010d0 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f01010e1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010e4:	89 07                	mov    %eax,(%edi)
	}
}
f01010e6:	83 c4 14             	add    $0x14,%esp
f01010e9:	5b                   	pop    %ebx
f01010ea:	5e                   	pop    %esi
f01010eb:	5f                   	pop    %edi
f01010ec:	5d                   	pop    %ebp
f01010ed:	c3                   	ret    

f01010ee <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01010ee:	55                   	push   %ebp
f01010ef:	89 e5                	mov    %esp,%ebp
f01010f1:	57                   	push   %edi
f01010f2:	56                   	push   %esi
f01010f3:	53                   	push   %ebx
f01010f4:	83 ec 2c             	sub    $0x2c,%esp
f01010f7:	e8 fa 01 00 00       	call   f01012f6 <__x86.get_pc_thunk.cx>
f01010fc:	81 c1 0c 12 01 00    	add    $0x1120c,%ecx
f0101102:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101105:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101108:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010110b:	8d 81 2c 02 ff ff    	lea    -0xfdd4(%ecx),%eax
f0101111:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0101113:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f010111a:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f010111d:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0101124:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0101127:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010112e:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0101134:	0f 86 f4 00 00 00    	jbe    f010122e <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010113a:	c7 c0 41 72 10 f0    	mov    $0xf0107241,%eax
f0101140:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f0101146:	0f 86 88 01 00 00    	jbe    f01012d4 <debuginfo_eip+0x1e6>
f010114c:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010114f:	c7 c0 2b 8f 10 f0    	mov    $0xf0108f2b,%eax
f0101155:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0101159:	0f 85 7c 01 00 00    	jne    f01012db <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010115f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0101166:	c7 c0 4c 27 10 f0    	mov    $0xf010274c,%eax
f010116c:	c7 c2 40 72 10 f0    	mov    $0xf0107240,%edx
f0101172:	29 c2                	sub    %eax,%edx
f0101174:	c1 fa 02             	sar    $0x2,%edx
f0101177:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010117d:	83 ea 01             	sub    $0x1,%edx
f0101180:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0101183:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0101186:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0101189:	83 ec 08             	sub    $0x8,%esp
f010118c:	53                   	push   %ebx
f010118d:	6a 64                	push   $0x64
f010118f:	e8 6a fe ff ff       	call   f0100ffe <stab_binsearch>
	if (lfile == 0)
f0101194:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101197:	83 c4 10             	add    $0x10,%esp
f010119a:	85 c0                	test   %eax,%eax
f010119c:	0f 84 40 01 00 00    	je     f01012e2 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01011a2:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01011a5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011a8:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01011ab:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01011ae:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01011b1:	83 ec 08             	sub    $0x8,%esp
f01011b4:	53                   	push   %ebx
f01011b5:	6a 24                	push   $0x24
f01011b7:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01011ba:	c7 c0 4c 27 10 f0    	mov    $0xf010274c,%eax
f01011c0:	e8 39 fe ff ff       	call   f0100ffe <stab_binsearch>

	if (lfun <= rfun) {
f01011c5:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01011c8:	83 c4 10             	add    $0x10,%esp
f01011cb:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f01011ce:	7f 79                	jg     f0101249 <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01011d0:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01011d3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01011d6:	c7 c2 4c 27 10 f0    	mov    $0xf010274c,%edx
f01011dc:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f01011df:	8b 11                	mov    (%ecx),%edx
f01011e1:	c7 c0 2b 8f 10 f0    	mov    $0xf0108f2b,%eax
f01011e7:	81 e8 41 72 10 f0    	sub    $0xf0107241,%eax
f01011ed:	39 c2                	cmp    %eax,%edx
f01011ef:	73 09                	jae    f01011fa <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01011f1:	81 c2 41 72 10 f0    	add    $0xf0107241,%edx
f01011f7:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01011fa:	8b 41 08             	mov    0x8(%ecx),%eax
f01011fd:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101200:	83 ec 08             	sub    $0x8,%esp
f0101203:	6a 3a                	push   $0x3a
f0101205:	ff 77 08             	pushl  0x8(%edi)
f0101208:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010120b:	e8 1e 09 00 00       	call   f0101b2e <strfind>
f0101210:	2b 47 08             	sub    0x8(%edi),%eax
f0101213:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101216:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101219:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010121c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010121f:	c7 c2 4c 27 10 f0    	mov    $0xf010274c,%edx
f0101225:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f0101229:	83 c4 10             	add    $0x10,%esp
f010122c:	eb 29                	jmp    f0101257 <debuginfo_eip+0x169>
  	        panic("User address");
f010122e:	83 ec 04             	sub    $0x4,%esp
f0101231:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101234:	8d 83 36 02 ff ff    	lea    -0xfdca(%ebx),%eax
f010123a:	50                   	push   %eax
f010123b:	6a 7f                	push   $0x7f
f010123d:	8d 83 43 02 ff ff    	lea    -0xfdbd(%ebx),%eax
f0101243:	50                   	push   %eax
f0101244:	e8 50 ee ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f0101249:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f010124c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010124f:	eb af                	jmp    f0101200 <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0101251:	83 ee 01             	sub    $0x1,%esi
f0101254:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0101257:	39 f3                	cmp    %esi,%ebx
f0101259:	7f 3a                	jg     f0101295 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f010125b:	0f b6 10             	movzbl (%eax),%edx
f010125e:	80 fa 84             	cmp    $0x84,%dl
f0101261:	74 0b                	je     f010126e <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101263:	80 fa 64             	cmp    $0x64,%dl
f0101266:	75 e9                	jne    f0101251 <debuginfo_eip+0x163>
f0101268:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f010126c:	74 e3                	je     f0101251 <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010126e:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0101271:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101274:	c7 c0 4c 27 10 f0    	mov    $0xf010274c,%eax
f010127a:	8b 14 90             	mov    (%eax,%edx,4),%edx
f010127d:	c7 c0 2b 8f 10 f0    	mov    $0xf0108f2b,%eax
f0101283:	81 e8 41 72 10 f0    	sub    $0xf0107241,%eax
f0101289:	39 c2                	cmp    %eax,%edx
f010128b:	73 08                	jae    f0101295 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010128d:	81 c2 41 72 10 f0    	add    $0xf0107241,%edx
f0101293:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101295:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101298:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010129b:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01012a0:	39 cb                	cmp    %ecx,%ebx
f01012a2:	7d 4a                	jge    f01012ee <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f01012a4:	8d 53 01             	lea    0x1(%ebx),%edx
f01012a7:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f01012aa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012ad:	c7 c0 4c 27 10 f0    	mov    $0xf010274c,%eax
f01012b3:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f01012b7:	eb 07                	jmp    f01012c0 <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f01012b9:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f01012bd:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f01012c0:	39 d1                	cmp    %edx,%ecx
f01012c2:	74 25                	je     f01012e9 <debuginfo_eip+0x1fb>
f01012c4:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01012c7:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f01012cb:	74 ec                	je     f01012b9 <debuginfo_eip+0x1cb>
	return 0;
f01012cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01012d2:	eb 1a                	jmp    f01012ee <debuginfo_eip+0x200>
		return -1;
f01012d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01012d9:	eb 13                	jmp    f01012ee <debuginfo_eip+0x200>
f01012db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01012e0:	eb 0c                	jmp    f01012ee <debuginfo_eip+0x200>
		return -1;
f01012e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01012e7:	eb 05                	jmp    f01012ee <debuginfo_eip+0x200>
	return 0;
f01012e9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012ee:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012f1:	5b                   	pop    %ebx
f01012f2:	5e                   	pop    %esi
f01012f3:	5f                   	pop    %edi
f01012f4:	5d                   	pop    %ebp
f01012f5:	c3                   	ret    

f01012f6 <__x86.get_pc_thunk.cx>:
f01012f6:	8b 0c 24             	mov    (%esp),%ecx
f01012f9:	c3                   	ret    

f01012fa <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01012fa:	55                   	push   %ebp
f01012fb:	89 e5                	mov    %esp,%ebp
f01012fd:	57                   	push   %edi
f01012fe:	56                   	push   %esi
f01012ff:	53                   	push   %ebx
f0101300:	83 ec 2c             	sub    $0x2c,%esp
f0101303:	e8 ee ff ff ff       	call   f01012f6 <__x86.get_pc_thunk.cx>
f0101308:	81 c1 00 10 01 00    	add    $0x11000,%ecx
f010130e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101311:	89 c7                	mov    %eax,%edi
f0101313:	89 d6                	mov    %edx,%esi
f0101315:	8b 45 08             	mov    0x8(%ebp),%eax
f0101318:	8b 55 0c             	mov    0xc(%ebp),%edx
f010131b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010131e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101321:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101324:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101329:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f010132c:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010132f:	39 d3                	cmp    %edx,%ebx
f0101331:	72 09                	jb     f010133c <printnum+0x42>
f0101333:	39 45 10             	cmp    %eax,0x10(%ebp)
f0101336:	0f 87 83 00 00 00    	ja     f01013bf <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010133c:	83 ec 0c             	sub    $0xc,%esp
f010133f:	ff 75 18             	pushl  0x18(%ebp)
f0101342:	8b 45 14             	mov    0x14(%ebp),%eax
f0101345:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0101348:	53                   	push   %ebx
f0101349:	ff 75 10             	pushl  0x10(%ebp)
f010134c:	83 ec 08             	sub    $0x8,%esp
f010134f:	ff 75 dc             	pushl  -0x24(%ebp)
f0101352:	ff 75 d8             	pushl  -0x28(%ebp)
f0101355:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101358:	ff 75 d0             	pushl  -0x30(%ebp)
f010135b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010135e:	e8 ed 09 00 00       	call   f0101d50 <__udivdi3>
f0101363:	83 c4 18             	add    $0x18,%esp
f0101366:	52                   	push   %edx
f0101367:	50                   	push   %eax
f0101368:	89 f2                	mov    %esi,%edx
f010136a:	89 f8                	mov    %edi,%eax
f010136c:	e8 89 ff ff ff       	call   f01012fa <printnum>
f0101371:	83 c4 20             	add    $0x20,%esp
f0101374:	eb 13                	jmp    f0101389 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101376:	83 ec 08             	sub    $0x8,%esp
f0101379:	56                   	push   %esi
f010137a:	ff 75 18             	pushl  0x18(%ebp)
f010137d:	ff d7                	call   *%edi
f010137f:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0101382:	83 eb 01             	sub    $0x1,%ebx
f0101385:	85 db                	test   %ebx,%ebx
f0101387:	7f ed                	jg     f0101376 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101389:	83 ec 08             	sub    $0x8,%esp
f010138c:	56                   	push   %esi
f010138d:	83 ec 04             	sub    $0x4,%esp
f0101390:	ff 75 dc             	pushl  -0x24(%ebp)
f0101393:	ff 75 d8             	pushl  -0x28(%ebp)
f0101396:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101399:	ff 75 d0             	pushl  -0x30(%ebp)
f010139c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010139f:	89 f3                	mov    %esi,%ebx
f01013a1:	e8 ca 0a 00 00       	call   f0101e70 <__umoddi3>
f01013a6:	83 c4 14             	add    $0x14,%esp
f01013a9:	0f be 84 06 51 02 ff 	movsbl -0xfdaf(%esi,%eax,1),%eax
f01013b0:	ff 
f01013b1:	50                   	push   %eax
f01013b2:	ff d7                	call   *%edi
}
f01013b4:	83 c4 10             	add    $0x10,%esp
f01013b7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013ba:	5b                   	pop    %ebx
f01013bb:	5e                   	pop    %esi
f01013bc:	5f                   	pop    %edi
f01013bd:	5d                   	pop    %ebp
f01013be:	c3                   	ret    
f01013bf:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01013c2:	eb be                	jmp    f0101382 <printnum+0x88>

f01013c4 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01013c4:	55                   	push   %ebp
f01013c5:	89 e5                	mov    %esp,%ebp
f01013c7:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01013ca:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01013ce:	8b 10                	mov    (%eax),%edx
f01013d0:	3b 50 04             	cmp    0x4(%eax),%edx
f01013d3:	73 0a                	jae    f01013df <sprintputch+0x1b>
		*b->buf++ = ch;
f01013d5:	8d 4a 01             	lea    0x1(%edx),%ecx
f01013d8:	89 08                	mov    %ecx,(%eax)
f01013da:	8b 45 08             	mov    0x8(%ebp),%eax
f01013dd:	88 02                	mov    %al,(%edx)
}
f01013df:	5d                   	pop    %ebp
f01013e0:	c3                   	ret    

f01013e1 <printfmt>:
{
f01013e1:	55                   	push   %ebp
f01013e2:	89 e5                	mov    %esp,%ebp
f01013e4:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01013e7:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01013ea:	50                   	push   %eax
f01013eb:	ff 75 10             	pushl  0x10(%ebp)
f01013ee:	ff 75 0c             	pushl  0xc(%ebp)
f01013f1:	ff 75 08             	pushl  0x8(%ebp)
f01013f4:	e8 05 00 00 00       	call   f01013fe <vprintfmt>
}
f01013f9:	83 c4 10             	add    $0x10,%esp
f01013fc:	c9                   	leave  
f01013fd:	c3                   	ret    

f01013fe <vprintfmt>:
{
f01013fe:	55                   	push   %ebp
f01013ff:	89 e5                	mov    %esp,%ebp
f0101401:	57                   	push   %edi
f0101402:	56                   	push   %esi
f0101403:	53                   	push   %ebx
f0101404:	83 ec 2c             	sub    $0x2c,%esp
f0101407:	e8 43 ed ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010140c:	81 c3 fc 0e 01 00    	add    $0x10efc,%ebx
f0101412:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101415:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101418:	e9 8e 03 00 00       	jmp    f01017ab <.L35+0x48>
		padc = ' ';
f010141d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0101421:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0101428:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f010142f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0101436:	b9 00 00 00 00       	mov    $0x0,%ecx
f010143b:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010143e:	8d 47 01             	lea    0x1(%edi),%eax
f0101441:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101444:	0f b6 17             	movzbl (%edi),%edx
f0101447:	8d 42 dd             	lea    -0x23(%edx),%eax
f010144a:	3c 55                	cmp    $0x55,%al
f010144c:	0f 87 e1 03 00 00    	ja     f0101833 <.L22>
f0101452:	0f b6 c0             	movzbl %al,%eax
f0101455:	89 d9                	mov    %ebx,%ecx
f0101457:	03 8c 83 dc 02 ff ff 	add    -0xfd24(%ebx,%eax,4),%ecx
f010145e:	ff e1                	jmp    *%ecx

f0101460 <.L67>:
f0101460:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0101463:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0101467:	eb d5                	jmp    f010143e <vprintfmt+0x40>

f0101469 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0101469:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f010146c:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0101470:	eb cc                	jmp    f010143e <vprintfmt+0x40>

f0101472 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0101472:	0f b6 d2             	movzbl %dl,%edx
f0101475:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0101478:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f010147d:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101480:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0101484:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0101487:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010148a:	83 f9 09             	cmp    $0x9,%ecx
f010148d:	77 55                	ja     f01014e4 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f010148f:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0101492:	eb e9                	jmp    f010147d <.L29+0xb>

f0101494 <.L26>:
			precision = va_arg(ap, int);
f0101494:	8b 45 14             	mov    0x14(%ebp),%eax
f0101497:	8b 00                	mov    (%eax),%eax
f0101499:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010149c:	8b 45 14             	mov    0x14(%ebp),%eax
f010149f:	8d 40 04             	lea    0x4(%eax),%eax
f01014a2:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01014a5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f01014a8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01014ac:	79 90                	jns    f010143e <vprintfmt+0x40>
				width = precision, precision = -1;
f01014ae:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014b1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01014b4:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01014bb:	eb 81                	jmp    f010143e <vprintfmt+0x40>

f01014bd <.L27>:
f01014bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01014c0:	85 c0                	test   %eax,%eax
f01014c2:	ba 00 00 00 00       	mov    $0x0,%edx
f01014c7:	0f 49 d0             	cmovns %eax,%edx
f01014ca:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01014cd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01014d0:	e9 69 ff ff ff       	jmp    f010143e <vprintfmt+0x40>

f01014d5 <.L23>:
f01014d5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f01014d8:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01014df:	e9 5a ff ff ff       	jmp    f010143e <vprintfmt+0x40>
f01014e4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01014e7:	eb bf                	jmp    f01014a8 <.L26+0x14>

f01014e9 <.L33>:
			lflag++;
f01014e9:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01014ed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01014f0:	e9 49 ff ff ff       	jmp    f010143e <vprintfmt+0x40>

f01014f5 <.L30>:
			putch(va_arg(ap, int), putdat);
f01014f5:	8b 45 14             	mov    0x14(%ebp),%eax
f01014f8:	8d 78 04             	lea    0x4(%eax),%edi
f01014fb:	83 ec 08             	sub    $0x8,%esp
f01014fe:	56                   	push   %esi
f01014ff:	ff 30                	pushl  (%eax)
f0101501:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101504:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0101507:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f010150a:	e9 99 02 00 00       	jmp    f01017a8 <.L35+0x45>

f010150f <.L32>:
			err = va_arg(ap, int);
f010150f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101512:	8d 78 04             	lea    0x4(%eax),%edi
f0101515:	8b 00                	mov    (%eax),%eax
f0101517:	99                   	cltd   
f0101518:	31 d0                	xor    %edx,%eax
f010151a:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010151c:	83 f8 06             	cmp    $0x6,%eax
f010151f:	7f 27                	jg     f0101548 <.L32+0x39>
f0101521:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f0101528:	85 d2                	test   %edx,%edx
f010152a:	74 1c                	je     f0101548 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f010152c:	52                   	push   %edx
f010152d:	8d 83 44 01 ff ff    	lea    -0xfebc(%ebx),%eax
f0101533:	50                   	push   %eax
f0101534:	56                   	push   %esi
f0101535:	ff 75 08             	pushl  0x8(%ebp)
f0101538:	e8 a4 fe ff ff       	call   f01013e1 <printfmt>
f010153d:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0101540:	89 7d 14             	mov    %edi,0x14(%ebp)
f0101543:	e9 60 02 00 00       	jmp    f01017a8 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0101548:	50                   	push   %eax
f0101549:	8d 83 69 02 ff ff    	lea    -0xfd97(%ebx),%eax
f010154f:	50                   	push   %eax
f0101550:	56                   	push   %esi
f0101551:	ff 75 08             	pushl  0x8(%ebp)
f0101554:	e8 88 fe ff ff       	call   f01013e1 <printfmt>
f0101559:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010155c:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010155f:	e9 44 02 00 00       	jmp    f01017a8 <.L35+0x45>

f0101564 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0101564:	8b 45 14             	mov    0x14(%ebp),%eax
f0101567:	83 c0 04             	add    $0x4,%eax
f010156a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010156d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101570:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101572:	85 ff                	test   %edi,%edi
f0101574:	8d 83 62 02 ff ff    	lea    -0xfd9e(%ebx),%eax
f010157a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010157d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101581:	0f 8e b5 00 00 00    	jle    f010163c <.L36+0xd8>
f0101587:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010158b:	75 08                	jne    f0101595 <.L36+0x31>
f010158d:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101590:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101593:	eb 6d                	jmp    f0101602 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101595:	83 ec 08             	sub    $0x8,%esp
f0101598:	ff 75 d0             	pushl  -0x30(%ebp)
f010159b:	57                   	push   %edi
f010159c:	e8 49 04 00 00       	call   f01019ea <strnlen>
f01015a1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01015a4:	29 c2                	sub    %eax,%edx
f01015a6:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01015a9:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01015ac:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01015b0:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01015b3:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01015b6:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f01015b8:	eb 10                	jmp    f01015ca <.L36+0x66>
					putch(padc, putdat);
f01015ba:	83 ec 08             	sub    $0x8,%esp
f01015bd:	56                   	push   %esi
f01015be:	ff 75 e0             	pushl  -0x20(%ebp)
f01015c1:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01015c4:	83 ef 01             	sub    $0x1,%edi
f01015c7:	83 c4 10             	add    $0x10,%esp
f01015ca:	85 ff                	test   %edi,%edi
f01015cc:	7f ec                	jg     f01015ba <.L36+0x56>
f01015ce:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01015d1:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01015d4:	85 d2                	test   %edx,%edx
f01015d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01015db:	0f 49 c2             	cmovns %edx,%eax
f01015de:	29 c2                	sub    %eax,%edx
f01015e0:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01015e3:	89 75 0c             	mov    %esi,0xc(%ebp)
f01015e6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01015e9:	eb 17                	jmp    f0101602 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f01015eb:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01015ef:	75 30                	jne    f0101621 <.L36+0xbd>
					putch(ch, putdat);
f01015f1:	83 ec 08             	sub    $0x8,%esp
f01015f4:	ff 75 0c             	pushl  0xc(%ebp)
f01015f7:	50                   	push   %eax
f01015f8:	ff 55 08             	call   *0x8(%ebp)
f01015fb:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01015fe:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101602:	83 c7 01             	add    $0x1,%edi
f0101605:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101609:	0f be c2             	movsbl %dl,%eax
f010160c:	85 c0                	test   %eax,%eax
f010160e:	74 52                	je     f0101662 <.L36+0xfe>
f0101610:	85 f6                	test   %esi,%esi
f0101612:	78 d7                	js     f01015eb <.L36+0x87>
f0101614:	83 ee 01             	sub    $0x1,%esi
f0101617:	79 d2                	jns    f01015eb <.L36+0x87>
f0101619:	8b 75 0c             	mov    0xc(%ebp),%esi
f010161c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010161f:	eb 32                	jmp    f0101653 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f0101621:	0f be d2             	movsbl %dl,%edx
f0101624:	83 ea 20             	sub    $0x20,%edx
f0101627:	83 fa 5e             	cmp    $0x5e,%edx
f010162a:	76 c5                	jbe    f01015f1 <.L36+0x8d>
					putch('?', putdat);
f010162c:	83 ec 08             	sub    $0x8,%esp
f010162f:	ff 75 0c             	pushl  0xc(%ebp)
f0101632:	6a 3f                	push   $0x3f
f0101634:	ff 55 08             	call   *0x8(%ebp)
f0101637:	83 c4 10             	add    $0x10,%esp
f010163a:	eb c2                	jmp    f01015fe <.L36+0x9a>
f010163c:	89 75 0c             	mov    %esi,0xc(%ebp)
f010163f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101642:	eb be                	jmp    f0101602 <.L36+0x9e>
				putch(' ', putdat);
f0101644:	83 ec 08             	sub    $0x8,%esp
f0101647:	56                   	push   %esi
f0101648:	6a 20                	push   $0x20
f010164a:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f010164d:	83 ef 01             	sub    $0x1,%edi
f0101650:	83 c4 10             	add    $0x10,%esp
f0101653:	85 ff                	test   %edi,%edi
f0101655:	7f ed                	jg     f0101644 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0101657:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010165a:	89 45 14             	mov    %eax,0x14(%ebp)
f010165d:	e9 46 01 00 00       	jmp    f01017a8 <.L35+0x45>
f0101662:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101665:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101668:	eb e9                	jmp    f0101653 <.L36+0xef>

f010166a <.L31>:
f010166a:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f010166d:	83 f9 01             	cmp    $0x1,%ecx
f0101670:	7e 40                	jle    f01016b2 <.L31+0x48>
		return va_arg(*ap, long long);
f0101672:	8b 45 14             	mov    0x14(%ebp),%eax
f0101675:	8b 50 04             	mov    0x4(%eax),%edx
f0101678:	8b 00                	mov    (%eax),%eax
f010167a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010167d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101680:	8b 45 14             	mov    0x14(%ebp),%eax
f0101683:	8d 40 08             	lea    0x8(%eax),%eax
f0101686:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101689:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010168d:	79 55                	jns    f01016e4 <.L31+0x7a>
				putch('-', putdat);
f010168f:	83 ec 08             	sub    $0x8,%esp
f0101692:	56                   	push   %esi
f0101693:	6a 2d                	push   $0x2d
f0101695:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101698:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010169b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010169e:	f7 da                	neg    %edx
f01016a0:	83 d1 00             	adc    $0x0,%ecx
f01016a3:	f7 d9                	neg    %ecx
f01016a5:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01016a8:	b8 0a 00 00 00       	mov    $0xa,%eax
f01016ad:	e9 db 00 00 00       	jmp    f010178d <.L35+0x2a>
	else if (lflag)
f01016b2:	85 c9                	test   %ecx,%ecx
f01016b4:	75 17                	jne    f01016cd <.L31+0x63>
		return va_arg(*ap, int);
f01016b6:	8b 45 14             	mov    0x14(%ebp),%eax
f01016b9:	8b 00                	mov    (%eax),%eax
f01016bb:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01016be:	99                   	cltd   
f01016bf:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01016c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01016c5:	8d 40 04             	lea    0x4(%eax),%eax
f01016c8:	89 45 14             	mov    %eax,0x14(%ebp)
f01016cb:	eb bc                	jmp    f0101689 <.L31+0x1f>
		return va_arg(*ap, long);
f01016cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01016d0:	8b 00                	mov    (%eax),%eax
f01016d2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01016d5:	99                   	cltd   
f01016d6:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01016d9:	8b 45 14             	mov    0x14(%ebp),%eax
f01016dc:	8d 40 04             	lea    0x4(%eax),%eax
f01016df:	89 45 14             	mov    %eax,0x14(%ebp)
f01016e2:	eb a5                	jmp    f0101689 <.L31+0x1f>
			num = getint(&ap, lflag);
f01016e4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01016e7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f01016ea:	b8 0a 00 00 00       	mov    $0xa,%eax
f01016ef:	e9 99 00 00 00       	jmp    f010178d <.L35+0x2a>

f01016f4 <.L37>:
f01016f4:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f01016f7:	83 f9 01             	cmp    $0x1,%ecx
f01016fa:	7e 15                	jle    f0101711 <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f01016fc:	8b 45 14             	mov    0x14(%ebp),%eax
f01016ff:	8b 10                	mov    (%eax),%edx
f0101701:	8b 48 04             	mov    0x4(%eax),%ecx
f0101704:	8d 40 08             	lea    0x8(%eax),%eax
f0101707:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010170a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010170f:	eb 7c                	jmp    f010178d <.L35+0x2a>
	else if (lflag)
f0101711:	85 c9                	test   %ecx,%ecx
f0101713:	75 17                	jne    f010172c <.L37+0x38>
		return va_arg(*ap, unsigned int);
f0101715:	8b 45 14             	mov    0x14(%ebp),%eax
f0101718:	8b 10                	mov    (%eax),%edx
f010171a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010171f:	8d 40 04             	lea    0x4(%eax),%eax
f0101722:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101725:	b8 0a 00 00 00       	mov    $0xa,%eax
f010172a:	eb 61                	jmp    f010178d <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010172c:	8b 45 14             	mov    0x14(%ebp),%eax
f010172f:	8b 10                	mov    (%eax),%edx
f0101731:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101736:	8d 40 04             	lea    0x4(%eax),%eax
f0101739:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010173c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101741:	eb 4a                	jmp    f010178d <.L35+0x2a>

f0101743 <.L34>:
			putch('X', putdat);
f0101743:	83 ec 08             	sub    $0x8,%esp
f0101746:	56                   	push   %esi
f0101747:	6a 58                	push   $0x58
f0101749:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f010174c:	83 c4 08             	add    $0x8,%esp
f010174f:	56                   	push   %esi
f0101750:	6a 58                	push   $0x58
f0101752:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0101755:	83 c4 08             	add    $0x8,%esp
f0101758:	56                   	push   %esi
f0101759:	6a 58                	push   $0x58
f010175b:	ff 55 08             	call   *0x8(%ebp)
			break;
f010175e:	83 c4 10             	add    $0x10,%esp
f0101761:	eb 45                	jmp    f01017a8 <.L35+0x45>

f0101763 <.L35>:
			putch('0', putdat);
f0101763:	83 ec 08             	sub    $0x8,%esp
f0101766:	56                   	push   %esi
f0101767:	6a 30                	push   $0x30
f0101769:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010176c:	83 c4 08             	add    $0x8,%esp
f010176f:	56                   	push   %esi
f0101770:	6a 78                	push   $0x78
f0101772:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0101775:	8b 45 14             	mov    0x14(%ebp),%eax
f0101778:	8b 10                	mov    (%eax),%edx
f010177a:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010177f:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101782:	8d 40 04             	lea    0x4(%eax),%eax
f0101785:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101788:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010178d:	83 ec 0c             	sub    $0xc,%esp
f0101790:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101794:	57                   	push   %edi
f0101795:	ff 75 e0             	pushl  -0x20(%ebp)
f0101798:	50                   	push   %eax
f0101799:	51                   	push   %ecx
f010179a:	52                   	push   %edx
f010179b:	89 f2                	mov    %esi,%edx
f010179d:	8b 45 08             	mov    0x8(%ebp),%eax
f01017a0:	e8 55 fb ff ff       	call   f01012fa <printnum>
			break;
f01017a5:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01017a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01017ab:	83 c7 01             	add    $0x1,%edi
f01017ae:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01017b2:	83 f8 25             	cmp    $0x25,%eax
f01017b5:	0f 84 62 fc ff ff    	je     f010141d <vprintfmt+0x1f>
			if (ch == '\0')
f01017bb:	85 c0                	test   %eax,%eax
f01017bd:	0f 84 91 00 00 00    	je     f0101854 <.L22+0x21>
			putch(ch, putdat);
f01017c3:	83 ec 08             	sub    $0x8,%esp
f01017c6:	56                   	push   %esi
f01017c7:	50                   	push   %eax
f01017c8:	ff 55 08             	call   *0x8(%ebp)
f01017cb:	83 c4 10             	add    $0x10,%esp
f01017ce:	eb db                	jmp    f01017ab <.L35+0x48>

f01017d0 <.L38>:
f01017d0:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f01017d3:	83 f9 01             	cmp    $0x1,%ecx
f01017d6:	7e 15                	jle    f01017ed <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f01017d8:	8b 45 14             	mov    0x14(%ebp),%eax
f01017db:	8b 10                	mov    (%eax),%edx
f01017dd:	8b 48 04             	mov    0x4(%eax),%ecx
f01017e0:	8d 40 08             	lea    0x8(%eax),%eax
f01017e3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01017e6:	b8 10 00 00 00       	mov    $0x10,%eax
f01017eb:	eb a0                	jmp    f010178d <.L35+0x2a>
	else if (lflag)
f01017ed:	85 c9                	test   %ecx,%ecx
f01017ef:	75 17                	jne    f0101808 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f01017f1:	8b 45 14             	mov    0x14(%ebp),%eax
f01017f4:	8b 10                	mov    (%eax),%edx
f01017f6:	b9 00 00 00 00       	mov    $0x0,%ecx
f01017fb:	8d 40 04             	lea    0x4(%eax),%eax
f01017fe:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101801:	b8 10 00 00 00       	mov    $0x10,%eax
f0101806:	eb 85                	jmp    f010178d <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101808:	8b 45 14             	mov    0x14(%ebp),%eax
f010180b:	8b 10                	mov    (%eax),%edx
f010180d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101812:	8d 40 04             	lea    0x4(%eax),%eax
f0101815:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101818:	b8 10 00 00 00       	mov    $0x10,%eax
f010181d:	e9 6b ff ff ff       	jmp    f010178d <.L35+0x2a>

f0101822 <.L25>:
			putch(ch, putdat);
f0101822:	83 ec 08             	sub    $0x8,%esp
f0101825:	56                   	push   %esi
f0101826:	6a 25                	push   $0x25
f0101828:	ff 55 08             	call   *0x8(%ebp)
			break;
f010182b:	83 c4 10             	add    $0x10,%esp
f010182e:	e9 75 ff ff ff       	jmp    f01017a8 <.L35+0x45>

f0101833 <.L22>:
			putch('%', putdat);
f0101833:	83 ec 08             	sub    $0x8,%esp
f0101836:	56                   	push   %esi
f0101837:	6a 25                	push   $0x25
f0101839:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010183c:	83 c4 10             	add    $0x10,%esp
f010183f:	89 f8                	mov    %edi,%eax
f0101841:	eb 03                	jmp    f0101846 <.L22+0x13>
f0101843:	83 e8 01             	sub    $0x1,%eax
f0101846:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f010184a:	75 f7                	jne    f0101843 <.L22+0x10>
f010184c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010184f:	e9 54 ff ff ff       	jmp    f01017a8 <.L35+0x45>
}
f0101854:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101857:	5b                   	pop    %ebx
f0101858:	5e                   	pop    %esi
f0101859:	5f                   	pop    %edi
f010185a:	5d                   	pop    %ebp
f010185b:	c3                   	ret    

f010185c <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010185c:	55                   	push   %ebp
f010185d:	89 e5                	mov    %esp,%ebp
f010185f:	53                   	push   %ebx
f0101860:	83 ec 14             	sub    $0x14,%esp
f0101863:	e8 e7 e8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101868:	81 c3 a0 0a 01 00    	add    $0x10aa0,%ebx
f010186e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101871:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101874:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101877:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010187b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010187e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101885:	85 c0                	test   %eax,%eax
f0101887:	74 2b                	je     f01018b4 <vsnprintf+0x58>
f0101889:	85 d2                	test   %edx,%edx
f010188b:	7e 27                	jle    f01018b4 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010188d:	ff 75 14             	pushl  0x14(%ebp)
f0101890:	ff 75 10             	pushl  0x10(%ebp)
f0101893:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101896:	50                   	push   %eax
f0101897:	8d 83 bc f0 fe ff    	lea    -0x10f44(%ebx),%eax
f010189d:	50                   	push   %eax
f010189e:	e8 5b fb ff ff       	call   f01013fe <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01018a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01018a6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01018a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01018ac:	83 c4 10             	add    $0x10,%esp
}
f01018af:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01018b2:	c9                   	leave  
f01018b3:	c3                   	ret    
		return -E_INVAL;
f01018b4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01018b9:	eb f4                	jmp    f01018af <vsnprintf+0x53>

f01018bb <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01018bb:	55                   	push   %ebp
f01018bc:	89 e5                	mov    %esp,%ebp
f01018be:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01018c1:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01018c4:	50                   	push   %eax
f01018c5:	ff 75 10             	pushl  0x10(%ebp)
f01018c8:	ff 75 0c             	pushl  0xc(%ebp)
f01018cb:	ff 75 08             	pushl  0x8(%ebp)
f01018ce:	e8 89 ff ff ff       	call   f010185c <vsnprintf>
	va_end(ap);

	return rc;
}
f01018d3:	c9                   	leave  
f01018d4:	c3                   	ret    

f01018d5 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01018d5:	55                   	push   %ebp
f01018d6:	89 e5                	mov    %esp,%ebp
f01018d8:	57                   	push   %edi
f01018d9:	56                   	push   %esi
f01018da:	53                   	push   %ebx
f01018db:	83 ec 1c             	sub    $0x1c,%esp
f01018de:	e8 6c e8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01018e3:	81 c3 25 0a 01 00    	add    $0x10a25,%ebx
f01018e9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01018ec:	85 c0                	test   %eax,%eax
f01018ee:	74 13                	je     f0101903 <readline+0x2e>
		cprintf("%s", prompt);
f01018f0:	83 ec 08             	sub    $0x8,%esp
f01018f3:	50                   	push   %eax
f01018f4:	8d 83 44 01 ff ff    	lea    -0xfebc(%ebx),%eax
f01018fa:	50                   	push   %eax
f01018fb:	e8 ea f6 ff ff       	call   f0100fea <cprintf>
f0101900:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101903:	83 ec 0c             	sub    $0xc,%esp
f0101906:	6a 00                	push   $0x0
f0101908:	e8 da ed ff ff       	call   f01006e7 <iscons>
f010190d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101910:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0101913:	bf 00 00 00 00       	mov    $0x0,%edi
f0101918:	eb 46                	jmp    f0101960 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f010191a:	83 ec 08             	sub    $0x8,%esp
f010191d:	50                   	push   %eax
f010191e:	8d 83 34 04 ff ff    	lea    -0xfbcc(%ebx),%eax
f0101924:	50                   	push   %eax
f0101925:	e8 c0 f6 ff ff       	call   f0100fea <cprintf>
			return NULL;
f010192a:	83 c4 10             	add    $0x10,%esp
f010192d:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0101932:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101935:	5b                   	pop    %ebx
f0101936:	5e                   	pop    %esi
f0101937:	5f                   	pop    %edi
f0101938:	5d                   	pop    %ebp
f0101939:	c3                   	ret    
			if (echoing)
f010193a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010193e:	75 05                	jne    f0101945 <readline+0x70>
			i--;
f0101940:	83 ef 01             	sub    $0x1,%edi
f0101943:	eb 1b                	jmp    f0101960 <readline+0x8b>
				cputchar('\b');
f0101945:	83 ec 0c             	sub    $0xc,%esp
f0101948:	6a 08                	push   $0x8
f010194a:	e8 77 ed ff ff       	call   f01006c6 <cputchar>
f010194f:	83 c4 10             	add    $0x10,%esp
f0101952:	eb ec                	jmp    f0101940 <readline+0x6b>
			buf[i++] = c;
f0101954:	89 f0                	mov    %esi,%eax
f0101956:	88 84 3b b8 1f 00 00 	mov    %al,0x1fb8(%ebx,%edi,1)
f010195d:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0101960:	e8 71 ed ff ff       	call   f01006d6 <getchar>
f0101965:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0101967:	85 c0                	test   %eax,%eax
f0101969:	78 af                	js     f010191a <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010196b:	83 f8 08             	cmp    $0x8,%eax
f010196e:	0f 94 c2             	sete   %dl
f0101971:	83 f8 7f             	cmp    $0x7f,%eax
f0101974:	0f 94 c0             	sete   %al
f0101977:	08 c2                	or     %al,%dl
f0101979:	74 04                	je     f010197f <readline+0xaa>
f010197b:	85 ff                	test   %edi,%edi
f010197d:	7f bb                	jg     f010193a <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010197f:	83 fe 1f             	cmp    $0x1f,%esi
f0101982:	7e 1c                	jle    f01019a0 <readline+0xcb>
f0101984:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f010198a:	7f 14                	jg     f01019a0 <readline+0xcb>
			if (echoing)
f010198c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101990:	74 c2                	je     f0101954 <readline+0x7f>
				cputchar(c);
f0101992:	83 ec 0c             	sub    $0xc,%esp
f0101995:	56                   	push   %esi
f0101996:	e8 2b ed ff ff       	call   f01006c6 <cputchar>
f010199b:	83 c4 10             	add    $0x10,%esp
f010199e:	eb b4                	jmp    f0101954 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f01019a0:	83 fe 0a             	cmp    $0xa,%esi
f01019a3:	74 05                	je     f01019aa <readline+0xd5>
f01019a5:	83 fe 0d             	cmp    $0xd,%esi
f01019a8:	75 b6                	jne    f0101960 <readline+0x8b>
			if (echoing)
f01019aa:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01019ae:	75 13                	jne    f01019c3 <readline+0xee>
			buf[i] = 0;
f01019b0:	c6 84 3b b8 1f 00 00 	movb   $0x0,0x1fb8(%ebx,%edi,1)
f01019b7:	00 
			return buf;
f01019b8:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f01019be:	e9 6f ff ff ff       	jmp    f0101932 <readline+0x5d>
				cputchar('\n');
f01019c3:	83 ec 0c             	sub    $0xc,%esp
f01019c6:	6a 0a                	push   $0xa
f01019c8:	e8 f9 ec ff ff       	call   f01006c6 <cputchar>
f01019cd:	83 c4 10             	add    $0x10,%esp
f01019d0:	eb de                	jmp    f01019b0 <readline+0xdb>

f01019d2 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01019d2:	55                   	push   %ebp
f01019d3:	89 e5                	mov    %esp,%ebp
f01019d5:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01019d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01019dd:	eb 03                	jmp    f01019e2 <strlen+0x10>
		n++;
f01019df:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01019e2:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01019e6:	75 f7                	jne    f01019df <strlen+0xd>
	return n;
}
f01019e8:	5d                   	pop    %ebp
f01019e9:	c3                   	ret    

f01019ea <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01019ea:	55                   	push   %ebp
f01019eb:	89 e5                	mov    %esp,%ebp
f01019ed:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01019f0:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01019f3:	b8 00 00 00 00       	mov    $0x0,%eax
f01019f8:	eb 03                	jmp    f01019fd <strnlen+0x13>
		n++;
f01019fa:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01019fd:	39 d0                	cmp    %edx,%eax
f01019ff:	74 06                	je     f0101a07 <strnlen+0x1d>
f0101a01:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101a05:	75 f3                	jne    f01019fa <strnlen+0x10>
	return n;
}
f0101a07:	5d                   	pop    %ebp
f0101a08:	c3                   	ret    

f0101a09 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101a09:	55                   	push   %ebp
f0101a0a:	89 e5                	mov    %esp,%ebp
f0101a0c:	53                   	push   %ebx
f0101a0d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a10:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101a13:	89 c2                	mov    %eax,%edx
f0101a15:	83 c1 01             	add    $0x1,%ecx
f0101a18:	83 c2 01             	add    $0x1,%edx
f0101a1b:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101a1f:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101a22:	84 db                	test   %bl,%bl
f0101a24:	75 ef                	jne    f0101a15 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101a26:	5b                   	pop    %ebx
f0101a27:	5d                   	pop    %ebp
f0101a28:	c3                   	ret    

f0101a29 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101a29:	55                   	push   %ebp
f0101a2a:	89 e5                	mov    %esp,%ebp
f0101a2c:	53                   	push   %ebx
f0101a2d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101a30:	53                   	push   %ebx
f0101a31:	e8 9c ff ff ff       	call   f01019d2 <strlen>
f0101a36:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101a39:	ff 75 0c             	pushl  0xc(%ebp)
f0101a3c:	01 d8                	add    %ebx,%eax
f0101a3e:	50                   	push   %eax
f0101a3f:	e8 c5 ff ff ff       	call   f0101a09 <strcpy>
	return dst;
}
f0101a44:	89 d8                	mov    %ebx,%eax
f0101a46:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101a49:	c9                   	leave  
f0101a4a:	c3                   	ret    

f0101a4b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101a4b:	55                   	push   %ebp
f0101a4c:	89 e5                	mov    %esp,%ebp
f0101a4e:	56                   	push   %esi
f0101a4f:	53                   	push   %ebx
f0101a50:	8b 75 08             	mov    0x8(%ebp),%esi
f0101a53:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101a56:	89 f3                	mov    %esi,%ebx
f0101a58:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101a5b:	89 f2                	mov    %esi,%edx
f0101a5d:	eb 0f                	jmp    f0101a6e <strncpy+0x23>
		*dst++ = *src;
f0101a5f:	83 c2 01             	add    $0x1,%edx
f0101a62:	0f b6 01             	movzbl (%ecx),%eax
f0101a65:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101a68:	80 39 01             	cmpb   $0x1,(%ecx)
f0101a6b:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101a6e:	39 da                	cmp    %ebx,%edx
f0101a70:	75 ed                	jne    f0101a5f <strncpy+0x14>
	}
	return ret;
}
f0101a72:	89 f0                	mov    %esi,%eax
f0101a74:	5b                   	pop    %ebx
f0101a75:	5e                   	pop    %esi
f0101a76:	5d                   	pop    %ebp
f0101a77:	c3                   	ret    

f0101a78 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101a78:	55                   	push   %ebp
f0101a79:	89 e5                	mov    %esp,%ebp
f0101a7b:	56                   	push   %esi
f0101a7c:	53                   	push   %ebx
f0101a7d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101a80:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101a83:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101a86:	89 f0                	mov    %esi,%eax
f0101a88:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101a8c:	85 c9                	test   %ecx,%ecx
f0101a8e:	75 0b                	jne    f0101a9b <strlcpy+0x23>
f0101a90:	eb 17                	jmp    f0101aa9 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101a92:	83 c2 01             	add    $0x1,%edx
f0101a95:	83 c0 01             	add    $0x1,%eax
f0101a98:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101a9b:	39 d8                	cmp    %ebx,%eax
f0101a9d:	74 07                	je     f0101aa6 <strlcpy+0x2e>
f0101a9f:	0f b6 0a             	movzbl (%edx),%ecx
f0101aa2:	84 c9                	test   %cl,%cl
f0101aa4:	75 ec                	jne    f0101a92 <strlcpy+0x1a>
		*dst = '\0';
f0101aa6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101aa9:	29 f0                	sub    %esi,%eax
}
f0101aab:	5b                   	pop    %ebx
f0101aac:	5e                   	pop    %esi
f0101aad:	5d                   	pop    %ebp
f0101aae:	c3                   	ret    

f0101aaf <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101aaf:	55                   	push   %ebp
f0101ab0:	89 e5                	mov    %esp,%ebp
f0101ab2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101ab5:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101ab8:	eb 06                	jmp    f0101ac0 <strcmp+0x11>
		p++, q++;
f0101aba:	83 c1 01             	add    $0x1,%ecx
f0101abd:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101ac0:	0f b6 01             	movzbl (%ecx),%eax
f0101ac3:	84 c0                	test   %al,%al
f0101ac5:	74 04                	je     f0101acb <strcmp+0x1c>
f0101ac7:	3a 02                	cmp    (%edx),%al
f0101ac9:	74 ef                	je     f0101aba <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101acb:	0f b6 c0             	movzbl %al,%eax
f0101ace:	0f b6 12             	movzbl (%edx),%edx
f0101ad1:	29 d0                	sub    %edx,%eax
}
f0101ad3:	5d                   	pop    %ebp
f0101ad4:	c3                   	ret    

f0101ad5 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101ad5:	55                   	push   %ebp
f0101ad6:	89 e5                	mov    %esp,%ebp
f0101ad8:	53                   	push   %ebx
f0101ad9:	8b 45 08             	mov    0x8(%ebp),%eax
f0101adc:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101adf:	89 c3                	mov    %eax,%ebx
f0101ae1:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101ae4:	eb 06                	jmp    f0101aec <strncmp+0x17>
		n--, p++, q++;
f0101ae6:	83 c0 01             	add    $0x1,%eax
f0101ae9:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101aec:	39 d8                	cmp    %ebx,%eax
f0101aee:	74 16                	je     f0101b06 <strncmp+0x31>
f0101af0:	0f b6 08             	movzbl (%eax),%ecx
f0101af3:	84 c9                	test   %cl,%cl
f0101af5:	74 04                	je     f0101afb <strncmp+0x26>
f0101af7:	3a 0a                	cmp    (%edx),%cl
f0101af9:	74 eb                	je     f0101ae6 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101afb:	0f b6 00             	movzbl (%eax),%eax
f0101afe:	0f b6 12             	movzbl (%edx),%edx
f0101b01:	29 d0                	sub    %edx,%eax
}
f0101b03:	5b                   	pop    %ebx
f0101b04:	5d                   	pop    %ebp
f0101b05:	c3                   	ret    
		return 0;
f0101b06:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b0b:	eb f6                	jmp    f0101b03 <strncmp+0x2e>

f0101b0d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101b0d:	55                   	push   %ebp
f0101b0e:	89 e5                	mov    %esp,%ebp
f0101b10:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b13:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101b17:	0f b6 10             	movzbl (%eax),%edx
f0101b1a:	84 d2                	test   %dl,%dl
f0101b1c:	74 09                	je     f0101b27 <strchr+0x1a>
		if (*s == c)
f0101b1e:	38 ca                	cmp    %cl,%dl
f0101b20:	74 0a                	je     f0101b2c <strchr+0x1f>
	for (; *s; s++)
f0101b22:	83 c0 01             	add    $0x1,%eax
f0101b25:	eb f0                	jmp    f0101b17 <strchr+0xa>
			return (char *) s;
	return 0;
f0101b27:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101b2c:	5d                   	pop    %ebp
f0101b2d:	c3                   	ret    

f0101b2e <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101b2e:	55                   	push   %ebp
f0101b2f:	89 e5                	mov    %esp,%ebp
f0101b31:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b34:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101b38:	eb 03                	jmp    f0101b3d <strfind+0xf>
f0101b3a:	83 c0 01             	add    $0x1,%eax
f0101b3d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101b40:	38 ca                	cmp    %cl,%dl
f0101b42:	74 04                	je     f0101b48 <strfind+0x1a>
f0101b44:	84 d2                	test   %dl,%dl
f0101b46:	75 f2                	jne    f0101b3a <strfind+0xc>
			break;
	return (char *) s;
}
f0101b48:	5d                   	pop    %ebp
f0101b49:	c3                   	ret    

f0101b4a <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101b4a:	55                   	push   %ebp
f0101b4b:	89 e5                	mov    %esp,%ebp
f0101b4d:	57                   	push   %edi
f0101b4e:	56                   	push   %esi
f0101b4f:	53                   	push   %ebx
f0101b50:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101b53:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101b56:	85 c9                	test   %ecx,%ecx
f0101b58:	74 13                	je     f0101b6d <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101b5a:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101b60:	75 05                	jne    f0101b67 <memset+0x1d>
f0101b62:	f6 c1 03             	test   $0x3,%cl
f0101b65:	74 0d                	je     f0101b74 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101b67:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b6a:	fc                   	cld    
f0101b6b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101b6d:	89 f8                	mov    %edi,%eax
f0101b6f:	5b                   	pop    %ebx
f0101b70:	5e                   	pop    %esi
f0101b71:	5f                   	pop    %edi
f0101b72:	5d                   	pop    %ebp
f0101b73:	c3                   	ret    
		c &= 0xFF;
f0101b74:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101b78:	89 d3                	mov    %edx,%ebx
f0101b7a:	c1 e3 08             	shl    $0x8,%ebx
f0101b7d:	89 d0                	mov    %edx,%eax
f0101b7f:	c1 e0 18             	shl    $0x18,%eax
f0101b82:	89 d6                	mov    %edx,%esi
f0101b84:	c1 e6 10             	shl    $0x10,%esi
f0101b87:	09 f0                	or     %esi,%eax
f0101b89:	09 c2                	or     %eax,%edx
f0101b8b:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0101b8d:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101b90:	89 d0                	mov    %edx,%eax
f0101b92:	fc                   	cld    
f0101b93:	f3 ab                	rep stos %eax,%es:(%edi)
f0101b95:	eb d6                	jmp    f0101b6d <memset+0x23>

f0101b97 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101b97:	55                   	push   %ebp
f0101b98:	89 e5                	mov    %esp,%ebp
f0101b9a:	57                   	push   %edi
f0101b9b:	56                   	push   %esi
f0101b9c:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b9f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101ba2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101ba5:	39 c6                	cmp    %eax,%esi
f0101ba7:	73 35                	jae    f0101bde <memmove+0x47>
f0101ba9:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101bac:	39 c2                	cmp    %eax,%edx
f0101bae:	76 2e                	jbe    f0101bde <memmove+0x47>
		s += n;
		d += n;
f0101bb0:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101bb3:	89 d6                	mov    %edx,%esi
f0101bb5:	09 fe                	or     %edi,%esi
f0101bb7:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101bbd:	74 0c                	je     f0101bcb <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101bbf:	83 ef 01             	sub    $0x1,%edi
f0101bc2:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101bc5:	fd                   	std    
f0101bc6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101bc8:	fc                   	cld    
f0101bc9:	eb 21                	jmp    f0101bec <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101bcb:	f6 c1 03             	test   $0x3,%cl
f0101bce:	75 ef                	jne    f0101bbf <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101bd0:	83 ef 04             	sub    $0x4,%edi
f0101bd3:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101bd6:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101bd9:	fd                   	std    
f0101bda:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101bdc:	eb ea                	jmp    f0101bc8 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101bde:	89 f2                	mov    %esi,%edx
f0101be0:	09 c2                	or     %eax,%edx
f0101be2:	f6 c2 03             	test   $0x3,%dl
f0101be5:	74 09                	je     f0101bf0 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101be7:	89 c7                	mov    %eax,%edi
f0101be9:	fc                   	cld    
f0101bea:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101bec:	5e                   	pop    %esi
f0101bed:	5f                   	pop    %edi
f0101bee:	5d                   	pop    %ebp
f0101bef:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101bf0:	f6 c1 03             	test   $0x3,%cl
f0101bf3:	75 f2                	jne    f0101be7 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101bf5:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101bf8:	89 c7                	mov    %eax,%edi
f0101bfa:	fc                   	cld    
f0101bfb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101bfd:	eb ed                	jmp    f0101bec <memmove+0x55>

f0101bff <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101bff:	55                   	push   %ebp
f0101c00:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101c02:	ff 75 10             	pushl  0x10(%ebp)
f0101c05:	ff 75 0c             	pushl  0xc(%ebp)
f0101c08:	ff 75 08             	pushl  0x8(%ebp)
f0101c0b:	e8 87 ff ff ff       	call   f0101b97 <memmove>
}
f0101c10:	c9                   	leave  
f0101c11:	c3                   	ret    

f0101c12 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101c12:	55                   	push   %ebp
f0101c13:	89 e5                	mov    %esp,%ebp
f0101c15:	56                   	push   %esi
f0101c16:	53                   	push   %ebx
f0101c17:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c1a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101c1d:	89 c6                	mov    %eax,%esi
f0101c1f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101c22:	39 f0                	cmp    %esi,%eax
f0101c24:	74 1c                	je     f0101c42 <memcmp+0x30>
		if (*s1 != *s2)
f0101c26:	0f b6 08             	movzbl (%eax),%ecx
f0101c29:	0f b6 1a             	movzbl (%edx),%ebx
f0101c2c:	38 d9                	cmp    %bl,%cl
f0101c2e:	75 08                	jne    f0101c38 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101c30:	83 c0 01             	add    $0x1,%eax
f0101c33:	83 c2 01             	add    $0x1,%edx
f0101c36:	eb ea                	jmp    f0101c22 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0101c38:	0f b6 c1             	movzbl %cl,%eax
f0101c3b:	0f b6 db             	movzbl %bl,%ebx
f0101c3e:	29 d8                	sub    %ebx,%eax
f0101c40:	eb 05                	jmp    f0101c47 <memcmp+0x35>
	}

	return 0;
f0101c42:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101c47:	5b                   	pop    %ebx
f0101c48:	5e                   	pop    %esi
f0101c49:	5d                   	pop    %ebp
f0101c4a:	c3                   	ret    

f0101c4b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101c4b:	55                   	push   %ebp
f0101c4c:	89 e5                	mov    %esp,%ebp
f0101c4e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c51:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101c54:	89 c2                	mov    %eax,%edx
f0101c56:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101c59:	39 d0                	cmp    %edx,%eax
f0101c5b:	73 09                	jae    f0101c66 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101c5d:	38 08                	cmp    %cl,(%eax)
f0101c5f:	74 05                	je     f0101c66 <memfind+0x1b>
	for (; s < ends; s++)
f0101c61:	83 c0 01             	add    $0x1,%eax
f0101c64:	eb f3                	jmp    f0101c59 <memfind+0xe>
			break;
	return (void *) s;
}
f0101c66:	5d                   	pop    %ebp
f0101c67:	c3                   	ret    

f0101c68 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101c68:	55                   	push   %ebp
f0101c69:	89 e5                	mov    %esp,%ebp
f0101c6b:	57                   	push   %edi
f0101c6c:	56                   	push   %esi
f0101c6d:	53                   	push   %ebx
f0101c6e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101c71:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101c74:	eb 03                	jmp    f0101c79 <strtol+0x11>
		s++;
f0101c76:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0101c79:	0f b6 01             	movzbl (%ecx),%eax
f0101c7c:	3c 20                	cmp    $0x20,%al
f0101c7e:	74 f6                	je     f0101c76 <strtol+0xe>
f0101c80:	3c 09                	cmp    $0x9,%al
f0101c82:	74 f2                	je     f0101c76 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101c84:	3c 2b                	cmp    $0x2b,%al
f0101c86:	74 2e                	je     f0101cb6 <strtol+0x4e>
	int neg = 0;
f0101c88:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101c8d:	3c 2d                	cmp    $0x2d,%al
f0101c8f:	74 2f                	je     f0101cc0 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101c91:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101c97:	75 05                	jne    f0101c9e <strtol+0x36>
f0101c99:	80 39 30             	cmpb   $0x30,(%ecx)
f0101c9c:	74 2c                	je     f0101cca <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101c9e:	85 db                	test   %ebx,%ebx
f0101ca0:	75 0a                	jne    f0101cac <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101ca2:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0101ca7:	80 39 30             	cmpb   $0x30,(%ecx)
f0101caa:	74 28                	je     f0101cd4 <strtol+0x6c>
		base = 10;
f0101cac:	b8 00 00 00 00       	mov    $0x0,%eax
f0101cb1:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101cb4:	eb 50                	jmp    f0101d06 <strtol+0x9e>
		s++;
f0101cb6:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0101cb9:	bf 00 00 00 00       	mov    $0x0,%edi
f0101cbe:	eb d1                	jmp    f0101c91 <strtol+0x29>
		s++, neg = 1;
f0101cc0:	83 c1 01             	add    $0x1,%ecx
f0101cc3:	bf 01 00 00 00       	mov    $0x1,%edi
f0101cc8:	eb c7                	jmp    f0101c91 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101cca:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101cce:	74 0e                	je     f0101cde <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101cd0:	85 db                	test   %ebx,%ebx
f0101cd2:	75 d8                	jne    f0101cac <strtol+0x44>
		s++, base = 8;
f0101cd4:	83 c1 01             	add    $0x1,%ecx
f0101cd7:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101cdc:	eb ce                	jmp    f0101cac <strtol+0x44>
		s += 2, base = 16;
f0101cde:	83 c1 02             	add    $0x2,%ecx
f0101ce1:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101ce6:	eb c4                	jmp    f0101cac <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0101ce8:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101ceb:	89 f3                	mov    %esi,%ebx
f0101ced:	80 fb 19             	cmp    $0x19,%bl
f0101cf0:	77 29                	ja     f0101d1b <strtol+0xb3>
			dig = *s - 'a' + 10;
f0101cf2:	0f be d2             	movsbl %dl,%edx
f0101cf5:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101cf8:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101cfb:	7d 30                	jge    f0101d2d <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0101cfd:	83 c1 01             	add    $0x1,%ecx
f0101d00:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101d04:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0101d06:	0f b6 11             	movzbl (%ecx),%edx
f0101d09:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101d0c:	89 f3                	mov    %esi,%ebx
f0101d0e:	80 fb 09             	cmp    $0x9,%bl
f0101d11:	77 d5                	ja     f0101ce8 <strtol+0x80>
			dig = *s - '0';
f0101d13:	0f be d2             	movsbl %dl,%edx
f0101d16:	83 ea 30             	sub    $0x30,%edx
f0101d19:	eb dd                	jmp    f0101cf8 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0101d1b:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101d1e:	89 f3                	mov    %esi,%ebx
f0101d20:	80 fb 19             	cmp    $0x19,%bl
f0101d23:	77 08                	ja     f0101d2d <strtol+0xc5>
			dig = *s - 'A' + 10;
f0101d25:	0f be d2             	movsbl %dl,%edx
f0101d28:	83 ea 37             	sub    $0x37,%edx
f0101d2b:	eb cb                	jmp    f0101cf8 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0101d2d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101d31:	74 05                	je     f0101d38 <strtol+0xd0>
		*endptr = (char *) s;
f0101d33:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101d36:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0101d38:	89 c2                	mov    %eax,%edx
f0101d3a:	f7 da                	neg    %edx
f0101d3c:	85 ff                	test   %edi,%edi
f0101d3e:	0f 45 c2             	cmovne %edx,%eax
}
f0101d41:	5b                   	pop    %ebx
f0101d42:	5e                   	pop    %esi
f0101d43:	5f                   	pop    %edi
f0101d44:	5d                   	pop    %ebp
f0101d45:	c3                   	ret    
f0101d46:	66 90                	xchg   %ax,%ax
f0101d48:	66 90                	xchg   %ax,%ax
f0101d4a:	66 90                	xchg   %ax,%ax
f0101d4c:	66 90                	xchg   %ax,%ax
f0101d4e:	66 90                	xchg   %ax,%ax

f0101d50 <__udivdi3>:
f0101d50:	55                   	push   %ebp
f0101d51:	57                   	push   %edi
f0101d52:	56                   	push   %esi
f0101d53:	53                   	push   %ebx
f0101d54:	83 ec 1c             	sub    $0x1c,%esp
f0101d57:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0101d5b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0101d5f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101d63:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0101d67:	85 d2                	test   %edx,%edx
f0101d69:	75 35                	jne    f0101da0 <__udivdi3+0x50>
f0101d6b:	39 f3                	cmp    %esi,%ebx
f0101d6d:	0f 87 bd 00 00 00    	ja     f0101e30 <__udivdi3+0xe0>
f0101d73:	85 db                	test   %ebx,%ebx
f0101d75:	89 d9                	mov    %ebx,%ecx
f0101d77:	75 0b                	jne    f0101d84 <__udivdi3+0x34>
f0101d79:	b8 01 00 00 00       	mov    $0x1,%eax
f0101d7e:	31 d2                	xor    %edx,%edx
f0101d80:	f7 f3                	div    %ebx
f0101d82:	89 c1                	mov    %eax,%ecx
f0101d84:	31 d2                	xor    %edx,%edx
f0101d86:	89 f0                	mov    %esi,%eax
f0101d88:	f7 f1                	div    %ecx
f0101d8a:	89 c6                	mov    %eax,%esi
f0101d8c:	89 e8                	mov    %ebp,%eax
f0101d8e:	89 f7                	mov    %esi,%edi
f0101d90:	f7 f1                	div    %ecx
f0101d92:	89 fa                	mov    %edi,%edx
f0101d94:	83 c4 1c             	add    $0x1c,%esp
f0101d97:	5b                   	pop    %ebx
f0101d98:	5e                   	pop    %esi
f0101d99:	5f                   	pop    %edi
f0101d9a:	5d                   	pop    %ebp
f0101d9b:	c3                   	ret    
f0101d9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101da0:	39 f2                	cmp    %esi,%edx
f0101da2:	77 7c                	ja     f0101e20 <__udivdi3+0xd0>
f0101da4:	0f bd fa             	bsr    %edx,%edi
f0101da7:	83 f7 1f             	xor    $0x1f,%edi
f0101daa:	0f 84 98 00 00 00    	je     f0101e48 <__udivdi3+0xf8>
f0101db0:	89 f9                	mov    %edi,%ecx
f0101db2:	b8 20 00 00 00       	mov    $0x20,%eax
f0101db7:	29 f8                	sub    %edi,%eax
f0101db9:	d3 e2                	shl    %cl,%edx
f0101dbb:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101dbf:	89 c1                	mov    %eax,%ecx
f0101dc1:	89 da                	mov    %ebx,%edx
f0101dc3:	d3 ea                	shr    %cl,%edx
f0101dc5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101dc9:	09 d1                	or     %edx,%ecx
f0101dcb:	89 f2                	mov    %esi,%edx
f0101dcd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101dd1:	89 f9                	mov    %edi,%ecx
f0101dd3:	d3 e3                	shl    %cl,%ebx
f0101dd5:	89 c1                	mov    %eax,%ecx
f0101dd7:	d3 ea                	shr    %cl,%edx
f0101dd9:	89 f9                	mov    %edi,%ecx
f0101ddb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101ddf:	d3 e6                	shl    %cl,%esi
f0101de1:	89 eb                	mov    %ebp,%ebx
f0101de3:	89 c1                	mov    %eax,%ecx
f0101de5:	d3 eb                	shr    %cl,%ebx
f0101de7:	09 de                	or     %ebx,%esi
f0101de9:	89 f0                	mov    %esi,%eax
f0101deb:	f7 74 24 08          	divl   0x8(%esp)
f0101def:	89 d6                	mov    %edx,%esi
f0101df1:	89 c3                	mov    %eax,%ebx
f0101df3:	f7 64 24 0c          	mull   0xc(%esp)
f0101df7:	39 d6                	cmp    %edx,%esi
f0101df9:	72 0c                	jb     f0101e07 <__udivdi3+0xb7>
f0101dfb:	89 f9                	mov    %edi,%ecx
f0101dfd:	d3 e5                	shl    %cl,%ebp
f0101dff:	39 c5                	cmp    %eax,%ebp
f0101e01:	73 5d                	jae    f0101e60 <__udivdi3+0x110>
f0101e03:	39 d6                	cmp    %edx,%esi
f0101e05:	75 59                	jne    f0101e60 <__udivdi3+0x110>
f0101e07:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101e0a:	31 ff                	xor    %edi,%edi
f0101e0c:	89 fa                	mov    %edi,%edx
f0101e0e:	83 c4 1c             	add    $0x1c,%esp
f0101e11:	5b                   	pop    %ebx
f0101e12:	5e                   	pop    %esi
f0101e13:	5f                   	pop    %edi
f0101e14:	5d                   	pop    %ebp
f0101e15:	c3                   	ret    
f0101e16:	8d 76 00             	lea    0x0(%esi),%esi
f0101e19:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101e20:	31 ff                	xor    %edi,%edi
f0101e22:	31 c0                	xor    %eax,%eax
f0101e24:	89 fa                	mov    %edi,%edx
f0101e26:	83 c4 1c             	add    $0x1c,%esp
f0101e29:	5b                   	pop    %ebx
f0101e2a:	5e                   	pop    %esi
f0101e2b:	5f                   	pop    %edi
f0101e2c:	5d                   	pop    %ebp
f0101e2d:	c3                   	ret    
f0101e2e:	66 90                	xchg   %ax,%ax
f0101e30:	31 ff                	xor    %edi,%edi
f0101e32:	89 e8                	mov    %ebp,%eax
f0101e34:	89 f2                	mov    %esi,%edx
f0101e36:	f7 f3                	div    %ebx
f0101e38:	89 fa                	mov    %edi,%edx
f0101e3a:	83 c4 1c             	add    $0x1c,%esp
f0101e3d:	5b                   	pop    %ebx
f0101e3e:	5e                   	pop    %esi
f0101e3f:	5f                   	pop    %edi
f0101e40:	5d                   	pop    %ebp
f0101e41:	c3                   	ret    
f0101e42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101e48:	39 f2                	cmp    %esi,%edx
f0101e4a:	72 06                	jb     f0101e52 <__udivdi3+0x102>
f0101e4c:	31 c0                	xor    %eax,%eax
f0101e4e:	39 eb                	cmp    %ebp,%ebx
f0101e50:	77 d2                	ja     f0101e24 <__udivdi3+0xd4>
f0101e52:	b8 01 00 00 00       	mov    $0x1,%eax
f0101e57:	eb cb                	jmp    f0101e24 <__udivdi3+0xd4>
f0101e59:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101e60:	89 d8                	mov    %ebx,%eax
f0101e62:	31 ff                	xor    %edi,%edi
f0101e64:	eb be                	jmp    f0101e24 <__udivdi3+0xd4>
f0101e66:	66 90                	xchg   %ax,%ax
f0101e68:	66 90                	xchg   %ax,%ax
f0101e6a:	66 90                	xchg   %ax,%ax
f0101e6c:	66 90                	xchg   %ax,%ax
f0101e6e:	66 90                	xchg   %ax,%ax

f0101e70 <__umoddi3>:
f0101e70:	55                   	push   %ebp
f0101e71:	57                   	push   %edi
f0101e72:	56                   	push   %esi
f0101e73:	53                   	push   %ebx
f0101e74:	83 ec 1c             	sub    $0x1c,%esp
f0101e77:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0101e7b:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101e7f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101e83:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101e87:	85 ed                	test   %ebp,%ebp
f0101e89:	89 f0                	mov    %esi,%eax
f0101e8b:	89 da                	mov    %ebx,%edx
f0101e8d:	75 19                	jne    f0101ea8 <__umoddi3+0x38>
f0101e8f:	39 df                	cmp    %ebx,%edi
f0101e91:	0f 86 b1 00 00 00    	jbe    f0101f48 <__umoddi3+0xd8>
f0101e97:	f7 f7                	div    %edi
f0101e99:	89 d0                	mov    %edx,%eax
f0101e9b:	31 d2                	xor    %edx,%edx
f0101e9d:	83 c4 1c             	add    $0x1c,%esp
f0101ea0:	5b                   	pop    %ebx
f0101ea1:	5e                   	pop    %esi
f0101ea2:	5f                   	pop    %edi
f0101ea3:	5d                   	pop    %ebp
f0101ea4:	c3                   	ret    
f0101ea5:	8d 76 00             	lea    0x0(%esi),%esi
f0101ea8:	39 dd                	cmp    %ebx,%ebp
f0101eaa:	77 f1                	ja     f0101e9d <__umoddi3+0x2d>
f0101eac:	0f bd cd             	bsr    %ebp,%ecx
f0101eaf:	83 f1 1f             	xor    $0x1f,%ecx
f0101eb2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101eb6:	0f 84 b4 00 00 00    	je     f0101f70 <__umoddi3+0x100>
f0101ebc:	b8 20 00 00 00       	mov    $0x20,%eax
f0101ec1:	89 c2                	mov    %eax,%edx
f0101ec3:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101ec7:	29 c2                	sub    %eax,%edx
f0101ec9:	89 c1                	mov    %eax,%ecx
f0101ecb:	89 f8                	mov    %edi,%eax
f0101ecd:	d3 e5                	shl    %cl,%ebp
f0101ecf:	89 d1                	mov    %edx,%ecx
f0101ed1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101ed5:	d3 e8                	shr    %cl,%eax
f0101ed7:	09 c5                	or     %eax,%ebp
f0101ed9:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101edd:	89 c1                	mov    %eax,%ecx
f0101edf:	d3 e7                	shl    %cl,%edi
f0101ee1:	89 d1                	mov    %edx,%ecx
f0101ee3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101ee7:	89 df                	mov    %ebx,%edi
f0101ee9:	d3 ef                	shr    %cl,%edi
f0101eeb:	89 c1                	mov    %eax,%ecx
f0101eed:	89 f0                	mov    %esi,%eax
f0101eef:	d3 e3                	shl    %cl,%ebx
f0101ef1:	89 d1                	mov    %edx,%ecx
f0101ef3:	89 fa                	mov    %edi,%edx
f0101ef5:	d3 e8                	shr    %cl,%eax
f0101ef7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101efc:	09 d8                	or     %ebx,%eax
f0101efe:	f7 f5                	div    %ebp
f0101f00:	d3 e6                	shl    %cl,%esi
f0101f02:	89 d1                	mov    %edx,%ecx
f0101f04:	f7 64 24 08          	mull   0x8(%esp)
f0101f08:	39 d1                	cmp    %edx,%ecx
f0101f0a:	89 c3                	mov    %eax,%ebx
f0101f0c:	89 d7                	mov    %edx,%edi
f0101f0e:	72 06                	jb     f0101f16 <__umoddi3+0xa6>
f0101f10:	75 0e                	jne    f0101f20 <__umoddi3+0xb0>
f0101f12:	39 c6                	cmp    %eax,%esi
f0101f14:	73 0a                	jae    f0101f20 <__umoddi3+0xb0>
f0101f16:	2b 44 24 08          	sub    0x8(%esp),%eax
f0101f1a:	19 ea                	sbb    %ebp,%edx
f0101f1c:	89 d7                	mov    %edx,%edi
f0101f1e:	89 c3                	mov    %eax,%ebx
f0101f20:	89 ca                	mov    %ecx,%edx
f0101f22:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101f27:	29 de                	sub    %ebx,%esi
f0101f29:	19 fa                	sbb    %edi,%edx
f0101f2b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0101f2f:	89 d0                	mov    %edx,%eax
f0101f31:	d3 e0                	shl    %cl,%eax
f0101f33:	89 d9                	mov    %ebx,%ecx
f0101f35:	d3 ee                	shr    %cl,%esi
f0101f37:	d3 ea                	shr    %cl,%edx
f0101f39:	09 f0                	or     %esi,%eax
f0101f3b:	83 c4 1c             	add    $0x1c,%esp
f0101f3e:	5b                   	pop    %ebx
f0101f3f:	5e                   	pop    %esi
f0101f40:	5f                   	pop    %edi
f0101f41:	5d                   	pop    %ebp
f0101f42:	c3                   	ret    
f0101f43:	90                   	nop
f0101f44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101f48:	85 ff                	test   %edi,%edi
f0101f4a:	89 f9                	mov    %edi,%ecx
f0101f4c:	75 0b                	jne    f0101f59 <__umoddi3+0xe9>
f0101f4e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101f53:	31 d2                	xor    %edx,%edx
f0101f55:	f7 f7                	div    %edi
f0101f57:	89 c1                	mov    %eax,%ecx
f0101f59:	89 d8                	mov    %ebx,%eax
f0101f5b:	31 d2                	xor    %edx,%edx
f0101f5d:	f7 f1                	div    %ecx
f0101f5f:	89 f0                	mov    %esi,%eax
f0101f61:	f7 f1                	div    %ecx
f0101f63:	e9 31 ff ff ff       	jmp    f0101e99 <__umoddi3+0x29>
f0101f68:	90                   	nop
f0101f69:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101f70:	39 dd                	cmp    %ebx,%ebp
f0101f72:	72 08                	jb     f0101f7c <__umoddi3+0x10c>
f0101f74:	39 f7                	cmp    %esi,%edi
f0101f76:	0f 87 21 ff ff ff    	ja     f0101e9d <__umoddi3+0x2d>
f0101f7c:	89 da                	mov    %ebx,%edx
f0101f7e:	89 f0                	mov    %esi,%eax
f0101f80:	29 f8                	sub    %edi,%eax
f0101f82:	19 ea                	sbb    %ebp,%edx
f0101f84:	e9 14 ff ff ff       	jmp    f0101e9d <__umoddi3+0x2d>
