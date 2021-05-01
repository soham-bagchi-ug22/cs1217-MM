
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
f0100064:	e8 5e 3c 00 00       	call   f0103cc7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 18 ce fe ff    	lea    -0x131e8(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 e9 30 00 00       	call   f010316b <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 c7 13 00 00       	call   f010144e <mem_init>
f0100087:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 80 08 00 00       	call   f0100914 <monitor>
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
f01000c0:	e8 4f 08 00 00       	call   f0100914 <monitor>
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
f01000da:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 85 30 00 00       	call   f010316b <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 44 30 00 00       	call   f0103134 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 0b d6 fe ff    	lea    -0x129f5(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 6d 30 00 00       	call   f010316b <cprintf>
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
f010011f:	8d 83 4b ce fe ff    	lea    -0x131b5(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 40 30 00 00       	call   f010316b <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 fd 2f 00 00       	call   f0103134 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 0b d6 fe ff    	lea    -0x129f5(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 26 30 00 00       	call   f010316b <cprintf>
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
f0100217:	0f b6 84 13 98 cf fe 	movzbl -0x13068(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 98 ce fe 	movzbl -0x13168(%ebx,%edx,1),%ecx
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
f010026a:	8d 83 65 ce fe ff    	lea    -0x1319b(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 f5 2e 00 00       	call   f010316b <cprintf>
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
f01002b1:	0f b6 84 13 98 cf fe 	movzbl -0x13068(%ebx,%edx,1),%eax
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
f01004d2:	e8 3d 38 00 00       	call   f0103d14 <memmove>
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
f01006b5:	8d 83 71 ce fe ff    	lea    -0x1318f(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 aa 2a 00 00       	call   f010316b <cprintf>
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
f0100708:	8d 83 98 d0 fe ff    	lea    -0x12f68(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 b6 d0 fe ff    	lea    -0x12f4a(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 bb d0 fe ff    	lea    -0x12f45(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 49 2a 00 00       	call   f010316b <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 78 d1 fe ff    	lea    -0x12e88(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 c4 d0 fe ff    	lea    -0x12f3c(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 32 2a 00 00       	call   f010316b <cprintf>
f0100739:	83 c4 0c             	add    $0xc,%esp
f010073c:	8d 83 cd d0 fe ff    	lea    -0x12f33(%ebx),%eax
f0100742:	50                   	push   %eax
f0100743:	8d 83 e3 d0 fe ff    	lea    -0x12f1d(%ebx),%eax
f0100749:	50                   	push   %eax
f010074a:	56                   	push   %esi
f010074b:	e8 1b 2a 00 00       	call   f010316b <cprintf>
	return 0;
}
f0100750:	b8 00 00 00 00       	mov    $0x0,%eax
f0100755:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100758:	5b                   	pop    %ebx
f0100759:	5e                   	pop    %esi
f010075a:	5d                   	pop    %ebp
f010075b:	c3                   	ret    

f010075c <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010075c:	55                   	push   %ebp
f010075d:	89 e5                	mov    %esp,%ebp
f010075f:	57                   	push   %edi
f0100760:	56                   	push   %esi
f0100761:	53                   	push   %ebx
f0100762:	83 ec 18             	sub    $0x18,%esp
f0100765:	e8 e5 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010076a:	81 c3 9e 6b 01 00    	add    $0x16b9e,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100770:	8d 83 f4 d0 fe ff    	lea    -0x12f0c(%ebx),%eax
f0100776:	50                   	push   %eax
f0100777:	e8 ef 29 00 00       	call   f010316b <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010077c:	83 c4 08             	add    $0x8,%esp
f010077f:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f0100785:	8d 83 a0 d1 fe ff    	lea    -0x12e60(%ebx),%eax
f010078b:	50                   	push   %eax
f010078c:	e8 da 29 00 00       	call   f010316b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100791:	83 c4 0c             	add    $0xc,%esp
f0100794:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010079a:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007a0:	50                   	push   %eax
f01007a1:	57                   	push   %edi
f01007a2:	8d 83 c8 d1 fe ff    	lea    -0x12e38(%ebx),%eax
f01007a8:	50                   	push   %eax
f01007a9:	e8 bd 29 00 00       	call   f010316b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007ae:	83 c4 0c             	add    $0xc,%esp
f01007b1:	c7 c0 09 41 10 f0    	mov    $0xf0104109,%eax
f01007b7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007bd:	52                   	push   %edx
f01007be:	50                   	push   %eax
f01007bf:	8d 83 ec d1 fe ff    	lea    -0x12e14(%ebx),%eax
f01007c5:	50                   	push   %eax
f01007c6:	e8 a0 29 00 00       	call   f010316b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cb:	83 c4 0c             	add    $0xc,%esp
f01007ce:	c7 c0 60 90 11 f0    	mov    $0xf0119060,%eax
f01007d4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007da:	52                   	push   %edx
f01007db:	50                   	push   %eax
f01007dc:	8d 83 10 d2 fe ff    	lea    -0x12df0(%ebx),%eax
f01007e2:	50                   	push   %eax
f01007e3:	e8 83 29 00 00       	call   f010316b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e8:	83 c4 0c             	add    $0xc,%esp
f01007eb:	c7 c6 c0 96 11 f0    	mov    $0xf01196c0,%esi
f01007f1:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007f7:	50                   	push   %eax
f01007f8:	56                   	push   %esi
f01007f9:	8d 83 34 d2 fe ff    	lea    -0x12dcc(%ebx),%eax
f01007ff:	50                   	push   %eax
f0100800:	e8 66 29 00 00       	call   f010316b <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100805:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100808:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010080e:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100810:	c1 fe 0a             	sar    $0xa,%esi
f0100813:	56                   	push   %esi
f0100814:	8d 83 58 d2 fe ff    	lea    -0x12da8(%ebx),%eax
f010081a:	50                   	push   %eax
f010081b:	e8 4b 29 00 00       	call   f010316b <cprintf>
	return 0;
}
f0100820:	b8 00 00 00 00       	mov    $0x0,%eax
f0100825:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100828:	5b                   	pop    %ebx
f0100829:	5e                   	pop    %esi
f010082a:	5f                   	pop    %edi
f010082b:	5d                   	pop    %ebp
f010082c:	c3                   	ret    

f010082d <mon_showpagemappings>:
	return 0;
}

int 
mon_showpagemappings(int argc, char **argv, struct Trapframe *tf)
{
f010082d:	55                   	push   %ebp
f010082e:	89 e5                	mov    %esp,%ebp
f0100830:	57                   	push   %edi
f0100831:	56                   	push   %esi
f0100832:	53                   	push   %ebx
f0100833:	83 ec 30             	sub    $0x30,%esp
f0100836:	e8 14 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010083b:	81 c3 cd 6a 01 00    	add    $0x16acd,%ebx
f0100841:	8b 75 0c             	mov    0xc(%ebp),%esi
	uintptr_t va1, va2;

	long virtualadd1;
	char *dummyptr1;

	virtualadd1 = strtol(argv[1], &dummyptr1, 16);
f0100844:	6a 10                	push   $0x10
f0100846:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100849:	50                   	push   %eax
f010084a:	ff 76 04             	pushl  0x4(%esi)
f010084d:	e8 93 35 00 00       	call   f0103de5 <strtol>
f0100852:	89 c7                	mov    %eax,%edi

	long virtualadd2;
	char *dummyptr2;

	virtualadd2 = strtol(argv[2], &dummyptr2, 16);
f0100854:	83 c4 0c             	add    $0xc,%esp
f0100857:	6a 10                	push   $0x10
f0100859:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010085c:	50                   	push   %eax
f010085d:	ff 76 08             	pushl  0x8(%esi)
f0100860:	e8 80 35 00 00       	call   f0103de5 <strtol>

	va1 = (uintptr_t) virtualadd1;
	va2 = (uintptr_t) virtualadd2;
f0100865:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100868:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	cprintf("You inputted: %p\n", va1);
f010086b:	83 c4 08             	add    $0x8,%esp
f010086e:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0100871:	57                   	push   %edi
f0100872:	8d b3 0d d1 fe ff    	lea    -0x12ef3(%ebx),%esi
f0100878:	56                   	push   %esi
f0100879:	e8 ed 28 00 00       	call   f010316b <cprintf>
	cprintf("You inputted: %p\n", va2);
f010087e:	83 c4 08             	add    $0x8,%esp
f0100881:	ff 75 cc             	pushl  -0x34(%ebp)
f0100884:	56                   	push   %esi
f0100885:	e8 e1 28 00 00       	call   f010316b <cprintf>

	cprintf("You inputted: %p\n", virtualadd1);
f010088a:	83 c4 08             	add    $0x8,%esp
f010088d:	ff 75 d0             	pushl  -0x30(%ebp)
f0100890:	56                   	push   %esi
f0100891:	e8 d5 28 00 00       	call   f010316b <cprintf>
	cprintf("You inputted: %p\n", virtualadd2);
f0100896:	83 c4 08             	add    $0x8,%esp
f0100899:	ff 75 cc             	pushl  -0x34(%ebp)
f010089c:	56                   	push   %esi
f010089d:	e8 c9 28 00 00       	call   f010316b <cprintf>

	// Declare a page table entry
	pte_t *pgtentry;
	uintptr_t i;
	for (i = va1; i <= va2; i += PGSIZE)
f01008a2:	83 c4 10             	add    $0x10,%esp
	{
		pgtentry = pgdir_walk(kern_pgdir, (const void *)i, 0);
f01008a5:	c7 c6 cc 96 11 f0    	mov    $0xf01196cc,%esi
		{
			cprintf("Virtual address %p => maps to => Physical Address %p\n", PTE_ADDR(pgtentry));
		}
		else
		{
			cprintf("This address is not mapped\n");
f01008ab:	8d 83 1f d1 fe ff    	lea    -0x12ee1(%ebx),%eax
f01008b1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = va1; i <= va2; i += PGSIZE)
f01008b4:	eb 14                	jmp    f01008ca <mon_showpagemappings+0x9d>
			cprintf("This address is not mapped\n");
f01008b6:	83 ec 0c             	sub    $0xc,%esp
f01008b9:	ff 75 d0             	pushl  -0x30(%ebp)
f01008bc:	e8 aa 28 00 00       	call   f010316b <cprintf>
f01008c1:	83 c4 10             	add    $0x10,%esp
	for (i = va1; i <= va2; i += PGSIZE)
f01008c4:	81 c7 00 10 00 00    	add    $0x1000,%edi
f01008ca:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01008cd:	77 2e                	ja     f01008fd <mon_showpagemappings+0xd0>
		pgtentry = pgdir_walk(kern_pgdir, (const void *)i, 0);
f01008cf:	83 ec 04             	sub    $0x4,%esp
f01008d2:	6a 00                	push   $0x0
f01008d4:	57                   	push   %edi
f01008d5:	ff 36                	pushl  (%esi)
f01008d7:	e8 85 08 00 00       	call   f0101161 <pgdir_walk>
		if (pgtentry != 0)
f01008dc:	83 c4 10             	add    $0x10,%esp
f01008df:	85 c0                	test   %eax,%eax
f01008e1:	74 d3                	je     f01008b6 <mon_showpagemappings+0x89>
			cprintf("Virtual address %p => maps to => Physical Address %p\n", PTE_ADDR(pgtentry));
f01008e3:	83 ec 08             	sub    $0x8,%esp
f01008e6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008eb:	50                   	push   %eax
f01008ec:	8d 83 84 d2 fe ff    	lea    -0x12d7c(%ebx),%eax
f01008f2:	50                   	push   %eax
f01008f3:	e8 73 28 00 00       	call   f010316b <cprintf>
f01008f8:	83 c4 10             	add    $0x10,%esp
f01008fb:	eb c7                	jmp    f01008c4 <mon_showpagemappings+0x97>
		}	

	}

	return 0;
}
f01008fd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100902:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100905:	5b                   	pop    %ebx
f0100906:	5e                   	pop    %esi
f0100907:	5f                   	pop    %edi
f0100908:	5d                   	pop    %ebp
f0100909:	c3                   	ret    

f010090a <mon_backtrace>:
{
f010090a:	55                   	push   %ebp
f010090b:	89 e5                	mov    %esp,%ebp
}
f010090d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100912:	5d                   	pop    %ebp
f0100913:	c3                   	ret    

f0100914 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100914:	55                   	push   %ebp
f0100915:	89 e5                	mov    %esp,%ebp
f0100917:	57                   	push   %edi
f0100918:	56                   	push   %esi
f0100919:	53                   	push   %ebx
f010091a:	83 ec 68             	sub    $0x68,%esp
f010091d:	e8 2d f8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100922:	81 c3 e6 69 01 00    	add    $0x169e6,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100928:	8d 83 bc d2 fe ff    	lea    -0x12d44(%ebx),%eax
f010092e:	50                   	push   %eax
f010092f:	e8 37 28 00 00       	call   f010316b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100934:	8d 83 e0 d2 fe ff    	lea    -0x12d20(%ebx),%eax
f010093a:	89 04 24             	mov    %eax,(%esp)
f010093d:	e8 29 28 00 00       	call   f010316b <cprintf>
f0100942:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100945:	8d bb 3f d1 fe ff    	lea    -0x12ec1(%ebx),%edi
f010094b:	eb 4a                	jmp    f0100997 <monitor+0x83>
f010094d:	83 ec 08             	sub    $0x8,%esp
f0100950:	0f be c0             	movsbl %al,%eax
f0100953:	50                   	push   %eax
f0100954:	57                   	push   %edi
f0100955:	e8 30 33 00 00       	call   f0103c8a <strchr>
f010095a:	83 c4 10             	add    $0x10,%esp
f010095d:	85 c0                	test   %eax,%eax
f010095f:	74 08                	je     f0100969 <monitor+0x55>
			*buf++ = 0;
f0100961:	c6 06 00             	movb   $0x0,(%esi)
f0100964:	8d 76 01             	lea    0x1(%esi),%esi
f0100967:	eb 79                	jmp    f01009e2 <monitor+0xce>
		if (*buf == 0)
f0100969:	80 3e 00             	cmpb   $0x0,(%esi)
f010096c:	74 7f                	je     f01009ed <monitor+0xd9>
		if (argc == MAXARGS-1) {
f010096e:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f0100972:	74 0f                	je     f0100983 <monitor+0x6f>
		argv[argc++] = buf;
f0100974:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100977:	8d 48 01             	lea    0x1(%eax),%ecx
f010097a:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f010097d:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f0100981:	eb 44                	jmp    f01009c7 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100983:	83 ec 08             	sub    $0x8,%esp
f0100986:	6a 10                	push   $0x10
f0100988:	8d 83 44 d1 fe ff    	lea    -0x12ebc(%ebx),%eax
f010098e:	50                   	push   %eax
f010098f:	e8 d7 27 00 00       	call   f010316b <cprintf>
f0100994:	83 c4 10             	add    $0x10,%esp
	//cprintf("%d %d\n", sizeof(char), sizeof(int)); 
	// Nikhil won lol


	while (1) {
		buf = readline("K> ");
f0100997:	8d 83 3b d1 fe ff    	lea    -0x12ec5(%ebx),%eax
f010099d:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01009a0:	83 ec 0c             	sub    $0xc,%esp
f01009a3:	ff 75 a4             	pushl  -0x5c(%ebp)
f01009a6:	e8 a7 30 00 00       	call   f0103a52 <readline>
f01009ab:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01009ad:	83 c4 10             	add    $0x10,%esp
f01009b0:	85 c0                	test   %eax,%eax
f01009b2:	74 ec                	je     f01009a0 <monitor+0x8c>
	argv[argc] = 0;
f01009b4:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01009bb:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f01009c2:	eb 1e                	jmp    f01009e2 <monitor+0xce>
			buf++;
f01009c4:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01009c7:	0f b6 06             	movzbl (%esi),%eax
f01009ca:	84 c0                	test   %al,%al
f01009cc:	74 14                	je     f01009e2 <monitor+0xce>
f01009ce:	83 ec 08             	sub    $0x8,%esp
f01009d1:	0f be c0             	movsbl %al,%eax
f01009d4:	50                   	push   %eax
f01009d5:	57                   	push   %edi
f01009d6:	e8 af 32 00 00       	call   f0103c8a <strchr>
f01009db:	83 c4 10             	add    $0x10,%esp
f01009de:	85 c0                	test   %eax,%eax
f01009e0:	74 e2                	je     f01009c4 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f01009e2:	0f b6 06             	movzbl (%esi),%eax
f01009e5:	84 c0                	test   %al,%al
f01009e7:	0f 85 60 ff ff ff    	jne    f010094d <monitor+0x39>
	argv[argc] = 0;
f01009ed:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009f0:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f01009f7:	00 
	if (argc == 0)
f01009f8:	85 c0                	test   %eax,%eax
f01009fa:	74 9b                	je     f0100997 <monitor+0x83>
f01009fc:	8d b3 18 1d 00 00    	lea    0x1d18(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a02:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a09:	83 ec 08             	sub    $0x8,%esp
f0100a0c:	ff 36                	pushl  (%esi)
f0100a0e:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a11:	e8 16 32 00 00       	call   f0103c2c <strcmp>
f0100a16:	83 c4 10             	add    $0x10,%esp
f0100a19:	85 c0                	test   %eax,%eax
f0100a1b:	74 29                	je     f0100a46 <monitor+0x132>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a1d:	83 45 a0 01          	addl   $0x1,-0x60(%ebp)
f0100a21:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100a24:	83 c6 0c             	add    $0xc,%esi
f0100a27:	83 f8 03             	cmp    $0x3,%eax
f0100a2a:	75 dd                	jne    f0100a09 <monitor+0xf5>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a2c:	83 ec 08             	sub    $0x8,%esp
f0100a2f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a32:	8d 83 61 d1 fe ff    	lea    -0x12e9f(%ebx),%eax
f0100a38:	50                   	push   %eax
f0100a39:	e8 2d 27 00 00       	call   f010316b <cprintf>
f0100a3e:	83 c4 10             	add    $0x10,%esp
f0100a41:	e9 51 ff ff ff       	jmp    f0100997 <monitor+0x83>
			return commands[i].func(argc, argv, tf);
f0100a46:	83 ec 04             	sub    $0x4,%esp
f0100a49:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100a4c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a4f:	ff 75 08             	pushl  0x8(%ebp)
f0100a52:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a55:	52                   	push   %edx
f0100a56:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a59:	ff 94 83 20 1d 00 00 	call   *0x1d20(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a60:	83 c4 10             	add    $0x10,%esp
f0100a63:	85 c0                	test   %eax,%eax
f0100a65:	0f 89 2c ff ff ff    	jns    f0100997 <monitor+0x83>
				break;
	}
}
f0100a6b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a6e:	5b                   	pop    %ebx
f0100a6f:	5e                   	pop    %esi
f0100a70:	5f                   	pop    %edi
f0100a71:	5d                   	pop    %ebp
f0100a72:	c3                   	ret    

f0100a73 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a73:	55                   	push   %ebp
f0100a74:	89 e5                	mov    %esp,%ebp
f0100a76:	57                   	push   %edi
f0100a77:	56                   	push   %esi
f0100a78:	53                   	push   %ebx
f0100a79:	83 ec 18             	sub    $0x18,%esp
f0100a7c:	e8 ce f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100a81:	81 c3 87 68 01 00    	add    $0x16887,%ebx
f0100a87:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a89:	50                   	push   %eax
f0100a8a:	e8 55 26 00 00       	call   f01030e4 <mc146818_read>
f0100a8f:	89 c6                	mov    %eax,%esi
f0100a91:	83 c7 01             	add    $0x1,%edi
f0100a94:	89 3c 24             	mov    %edi,(%esp)
f0100a97:	e8 48 26 00 00       	call   f01030e4 <mc146818_read>
f0100a9c:	c1 e0 08             	shl    $0x8,%eax
f0100a9f:	09 f0                	or     %esi,%eax
}
f0100aa1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100aa4:	5b                   	pop    %ebx
f0100aa5:	5e                   	pop    %esi
f0100aa6:	5f                   	pop    %edi
f0100aa7:	5d                   	pop    %ebp
f0100aa8:	c3                   	ret    

f0100aa9 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100aa9:	55                   	push   %ebp
f0100aaa:	89 e5                	mov    %esp,%ebp
f0100aac:	53                   	push   %ebx
f0100aad:	83 ec 04             	sub    $0x4,%esp
f0100ab0:	e8 23 26 00 00       	call   f01030d8 <__x86.get_pc_thunk.cx>
f0100ab5:	81 c1 53 68 01 00    	add    $0x16853,%ecx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100abb:	83 b9 90 1f 00 00 00 	cmpl   $0x0,0x1f90(%ecx)
f0100ac2:	74 28                	je     f0100aec <boot_alloc+0x43>
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	char * returnAddress = nextfree;
f0100ac4:	8b 99 90 1f 00 00    	mov    0x1f90(%ecx),%ebx
	//         HEX    f    f    f    f    f    f    f    f
	
	// nextfree is already at a page granularity

	// ROUNDING UP TOTAL BYTES instead of page by page 
	nextfree = ROUNDUP(returnAddress + n, PGSIZE);
f0100aca:	8d 94 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%edx
f0100ad1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ad7:	89 91 90 1f 00 00    	mov    %edx,0x1f90(%ecx)

	// our limit is set to the capacity of a page tables worth of pages.
	// if((uintptr_t) nextfree >= KERNBASE + NPTENTRIES * PGSIZE){
	if((uintptr_t) nextfree >= KERNBASE + 0x0e000000)
f0100add:	81 fa ff ff ff fd    	cmp    $0xfdffffff,%edx
f0100ae3:	77 21                	ja     f0100b06 <boot_alloc+0x5d>
	{
		panic("out of memory\n"); 
	}
	//cprintf("fin: %x\n", (int) finalAddress); // used this to identify which portion of memory the pages get allocated in
	return returnAddress;
}
f0100ae5:	89 d8                	mov    %ebx,%eax
f0100ae7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100aea:	c9                   	leave  
f0100aeb:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100aec:	c7 c2 c0 96 11 f0    	mov    $0xf01196c0,%edx
f0100af2:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100af8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100afe:	89 91 90 1f 00 00    	mov    %edx,0x1f90(%ecx)
f0100b04:	eb be                	jmp    f0100ac4 <boot_alloc+0x1b>
		panic("out of memory\n"); 
f0100b06:	83 ec 04             	sub    $0x4,%esp
f0100b09:	8d 81 05 d3 fe ff    	lea    -0x12cfb(%ecx),%eax
f0100b0f:	50                   	push   %eax
f0100b10:	6a 7e                	push   $0x7e
f0100b12:	8d 81 14 d3 fe ff    	lea    -0x12cec(%ecx),%eax
f0100b18:	50                   	push   %eax
f0100b19:	89 cb                	mov    %ecx,%ebx
f0100b1b:	e8 79 f5 ff ff       	call   f0100099 <_panic>

f0100b20 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b20:	55                   	push   %ebp
f0100b21:	89 e5                	mov    %esp,%ebp
f0100b23:	56                   	push   %esi
f0100b24:	53                   	push   %ebx
f0100b25:	e8 ae 25 00 00       	call   f01030d8 <__x86.get_pc_thunk.cx>
f0100b2a:	81 c1 de 67 01 00    	add    $0x167de,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b30:	89 d3                	mov    %edx,%ebx
f0100b32:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100b35:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100b38:	a8 01                	test   $0x1,%al
f0100b3a:	74 5a                	je     f0100b96 <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b3c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b41:	89 c6                	mov    %eax,%esi
f0100b43:	c1 ee 0c             	shr    $0xc,%esi
f0100b46:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f0100b4c:	3b 33                	cmp    (%ebx),%esi
f0100b4e:	73 2b                	jae    f0100b7b <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100b50:	c1 ea 0c             	shr    $0xc,%edx
f0100b53:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b59:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b60:	89 c2                	mov    %eax,%edx
f0100b62:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b65:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b6a:	85 d2                	test   %edx,%edx
f0100b6c:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b71:	0f 44 c2             	cmove  %edx,%eax
}
f0100b74:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100b77:	5b                   	pop    %ebx
f0100b78:	5e                   	pop    %esi
f0100b79:	5d                   	pop    %ebp
f0100b7a:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b7b:	50                   	push   %eax
f0100b7c:	8d 81 40 d6 fe ff    	lea    -0x129c0(%ecx),%eax
f0100b82:	50                   	push   %eax
f0100b83:	68 db 03 00 00       	push   $0x3db
f0100b88:	8d 81 14 d3 fe ff    	lea    -0x12cec(%ecx),%eax
f0100b8e:	50                   	push   %eax
f0100b8f:	89 cb                	mov    %ecx,%ebx
f0100b91:	e8 03 f5 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100b96:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b9b:	eb d7                	jmp    f0100b74 <check_va2pa+0x54>

f0100b9d <check_page_free_list>:
{
f0100b9d:	55                   	push   %ebp
f0100b9e:	89 e5                	mov    %esp,%ebp
f0100ba0:	57                   	push   %edi
f0100ba1:	56                   	push   %esi
f0100ba2:	53                   	push   %ebx
f0100ba3:	83 ec 3c             	sub    $0x3c,%esp
f0100ba6:	e8 35 25 00 00       	call   f01030e0 <__x86.get_pc_thunk.di>
f0100bab:	81 c7 5d 67 01 00    	add    $0x1675d,%edi
f0100bb1:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bb4:	84 c0                	test   %al,%al
f0100bb6:	0f 85 dd 02 00 00    	jne    f0100e99 <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100bbc:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100bbf:	83 b8 94 1f 00 00 00 	cmpl   $0x0,0x1f94(%eax)
f0100bc6:	74 0c                	je     f0100bd4 <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bc8:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100bcf:	e9 2f 03 00 00       	jmp    f0100f03 <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100bd4:	83 ec 04             	sub    $0x4,%esp
f0100bd7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bda:	8d 83 64 d6 fe ff    	lea    -0x1299c(%ebx),%eax
f0100be0:	50                   	push   %eax
f0100be1:	68 19 03 00 00       	push   $0x319
f0100be6:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0100bec:	50                   	push   %eax
f0100bed:	e8 a7 f4 ff ff       	call   f0100099 <_panic>
f0100bf2:	50                   	push   %eax
f0100bf3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bf6:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f0100bfc:	50                   	push   %eax
f0100bfd:	6a 52                	push   $0x52
f0100bff:	8d 83 20 d3 fe ff    	lea    -0x12ce0(%ebx),%eax
f0100c05:	50                   	push   %eax
f0100c06:	e8 8e f4 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c0b:	8b 36                	mov    (%esi),%esi
f0100c0d:	85 f6                	test   %esi,%esi
f0100c0f:	74 40                	je     f0100c51 <check_page_free_list+0xb4>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c11:	89 f0                	mov    %esi,%eax
f0100c13:	2b 07                	sub    (%edi),%eax
f0100c15:	c1 f8 03             	sar    $0x3,%eax
f0100c18:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c1b:	89 c2                	mov    %eax,%edx
f0100c1d:	c1 ea 16             	shr    $0x16,%edx
f0100c20:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c23:	73 e6                	jae    f0100c0b <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100c25:	89 c2                	mov    %eax,%edx
f0100c27:	c1 ea 0c             	shr    $0xc,%edx
f0100c2a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100c2d:	3b 11                	cmp    (%ecx),%edx
f0100c2f:	73 c1                	jae    f0100bf2 <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100c31:	83 ec 04             	sub    $0x4,%esp
f0100c34:	68 80 00 00 00       	push   $0x80
f0100c39:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c3e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c43:	50                   	push   %eax
f0100c44:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c47:	e8 7b 30 00 00       	call   f0103cc7 <memset>
f0100c4c:	83 c4 10             	add    $0x10,%esp
f0100c4f:	eb ba                	jmp    f0100c0b <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f0100c51:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c56:	e8 4e fe ff ff       	call   f0100aa9 <boot_alloc>
f0100c5b:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c5e:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c61:	8b 97 94 1f 00 00    	mov    0x1f94(%edi),%edx
		assert(pp >= pages);
f0100c67:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100c6d:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100c6f:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100c75:	8b 00                	mov    (%eax),%eax
f0100c77:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100c7a:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c7d:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c80:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c85:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c88:	e9 08 01 00 00       	jmp    f0100d95 <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100c8d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c90:	8d 83 2e d3 fe ff    	lea    -0x12cd2(%ebx),%eax
f0100c96:	50                   	push   %eax
f0100c97:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0100c9d:	50                   	push   %eax
f0100c9e:	68 35 03 00 00       	push   $0x335
f0100ca3:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0100ca9:	50                   	push   %eax
f0100caa:	e8 ea f3 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100caf:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cb2:	8d 83 4f d3 fe ff    	lea    -0x12cb1(%ebx),%eax
f0100cb8:	50                   	push   %eax
f0100cb9:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0100cbf:	50                   	push   %eax
f0100cc0:	68 36 03 00 00       	push   $0x336
f0100cc5:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0100ccb:	50                   	push   %eax
f0100ccc:	e8 c8 f3 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cd1:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cd4:	8d 83 88 d6 fe ff    	lea    -0x12978(%ebx),%eax
f0100cda:	50                   	push   %eax
f0100cdb:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0100ce1:	50                   	push   %eax
f0100ce2:	68 37 03 00 00       	push   $0x337
f0100ce7:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0100ced:	50                   	push   %eax
f0100cee:	e8 a6 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100cf3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cf6:	8d 83 63 d3 fe ff    	lea    -0x12c9d(%ebx),%eax
f0100cfc:	50                   	push   %eax
f0100cfd:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0100d03:	50                   	push   %eax
f0100d04:	68 3a 03 00 00       	push   $0x33a
f0100d09:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0100d0f:	50                   	push   %eax
f0100d10:	e8 84 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d15:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d18:	8d 83 74 d3 fe ff    	lea    -0x12c8c(%ebx),%eax
f0100d1e:	50                   	push   %eax
f0100d1f:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0100d25:	50                   	push   %eax
f0100d26:	68 3b 03 00 00       	push   $0x33b
f0100d2b:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0100d31:	50                   	push   %eax
f0100d32:	e8 62 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d37:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d3a:	8d 83 bc d6 fe ff    	lea    -0x12944(%ebx),%eax
f0100d40:	50                   	push   %eax
f0100d41:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0100d47:	50                   	push   %eax
f0100d48:	68 3c 03 00 00       	push   $0x33c
f0100d4d:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0100d53:	50                   	push   %eax
f0100d54:	e8 40 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d59:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d5c:	8d 83 8d d3 fe ff    	lea    -0x12c73(%ebx),%eax
f0100d62:	50                   	push   %eax
f0100d63:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0100d69:	50                   	push   %eax
f0100d6a:	68 3d 03 00 00       	push   $0x33d
f0100d6f:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0100d75:	50                   	push   %eax
f0100d76:	e8 1e f3 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100d7b:	89 c6                	mov    %eax,%esi
f0100d7d:	c1 ee 0c             	shr    $0xc,%esi
f0100d80:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100d83:	76 70                	jbe    f0100df5 <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100d85:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d8a:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d8d:	77 7f                	ja     f0100e0e <check_page_free_list+0x271>
			++nfree_extmem;
f0100d8f:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d93:	8b 12                	mov    (%edx),%edx
f0100d95:	85 d2                	test   %edx,%edx
f0100d97:	0f 84 93 00 00 00    	je     f0100e30 <check_page_free_list+0x293>
		assert(pp >= pages);
f0100d9d:	39 d1                	cmp    %edx,%ecx
f0100d9f:	0f 87 e8 fe ff ff    	ja     f0100c8d <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100da5:	39 d3                	cmp    %edx,%ebx
f0100da7:	0f 86 02 ff ff ff    	jbe    f0100caf <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100dad:	89 d0                	mov    %edx,%eax
f0100daf:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100db2:	a8 07                	test   $0x7,%al
f0100db4:	0f 85 17 ff ff ff    	jne    f0100cd1 <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100dba:	c1 f8 03             	sar    $0x3,%eax
f0100dbd:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100dc0:	85 c0                	test   %eax,%eax
f0100dc2:	0f 84 2b ff ff ff    	je     f0100cf3 <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100dc8:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100dcd:	0f 84 42 ff ff ff    	je     f0100d15 <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100dd3:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100dd8:	0f 84 59 ff ff ff    	je     f0100d37 <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100dde:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100de3:	0f 84 70 ff ff ff    	je     f0100d59 <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100de9:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100dee:	77 8b                	ja     f0100d7b <check_page_free_list+0x1de>
			++nfree_basemem;
f0100df0:	83 c7 01             	add    $0x1,%edi
f0100df3:	eb 9e                	jmp    f0100d93 <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100df5:	50                   	push   %eax
f0100df6:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100df9:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f0100dff:	50                   	push   %eax
f0100e00:	6a 52                	push   $0x52
f0100e02:	8d 83 20 d3 fe ff    	lea    -0x12ce0(%ebx),%eax
f0100e08:	50                   	push   %eax
f0100e09:	e8 8b f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e0e:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e11:	8d 83 e0 d6 fe ff    	lea    -0x12920(%ebx),%eax
f0100e17:	50                   	push   %eax
f0100e18:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0100e1e:	50                   	push   %eax
f0100e1f:	68 3e 03 00 00       	push   $0x33e
f0100e24:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0100e2a:	50                   	push   %eax
f0100e2b:	e8 69 f2 ff ff       	call   f0100099 <_panic>
f0100e30:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100e33:	85 ff                	test   %edi,%edi
f0100e35:	7e 1e                	jle    f0100e55 <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100e37:	85 f6                	test   %esi,%esi
f0100e39:	7e 3c                	jle    f0100e77 <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100e3b:	83 ec 0c             	sub    $0xc,%esp
f0100e3e:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e41:	8d 83 28 d7 fe ff    	lea    -0x128d8(%ebx),%eax
f0100e47:	50                   	push   %eax
f0100e48:	e8 1e 23 00 00       	call   f010316b <cprintf>
}
f0100e4d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e50:	5b                   	pop    %ebx
f0100e51:	5e                   	pop    %esi
f0100e52:	5f                   	pop    %edi
f0100e53:	5d                   	pop    %ebp
f0100e54:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e55:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e58:	8d 83 a7 d3 fe ff    	lea    -0x12c59(%ebx),%eax
f0100e5e:	50                   	push   %eax
f0100e5f:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0100e65:	50                   	push   %eax
f0100e66:	68 47 03 00 00       	push   $0x347
f0100e6b:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0100e71:	50                   	push   %eax
f0100e72:	e8 22 f2 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100e77:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e7a:	8d 83 b9 d3 fe ff    	lea    -0x12c47(%ebx),%eax
f0100e80:	50                   	push   %eax
f0100e81:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0100e87:	50                   	push   %eax
f0100e88:	68 48 03 00 00       	push   $0x348
f0100e8d:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0100e93:	50                   	push   %eax
f0100e94:	e8 00 f2 ff ff       	call   f0100099 <_panic>
	if (!page_free_list)
f0100e99:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100e9c:	8b 80 94 1f 00 00    	mov    0x1f94(%eax),%eax
f0100ea2:	85 c0                	test   %eax,%eax
f0100ea4:	0f 84 2a fd ff ff    	je     f0100bd4 <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100eaa:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ead:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100eb0:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100eb3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100eb6:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100eb9:	c7 c3 d0 96 11 f0    	mov    $0xf01196d0,%ebx
f0100ebf:	89 c2                	mov    %eax,%edx
f0100ec1:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ec3:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ec9:	0f 95 c2             	setne  %dl
f0100ecc:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ecf:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ed3:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ed5:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ed9:	8b 00                	mov    (%eax),%eax
f0100edb:	85 c0                	test   %eax,%eax
f0100edd:	75 e0                	jne    f0100ebf <check_page_free_list+0x322>
		*tp[1] = 0;
f0100edf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ee2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ee8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100eeb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100eee:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ef0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ef3:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100ef6:	89 87 94 1f 00 00    	mov    %eax,0x1f94(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100efc:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f03:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100f06:	8b b0 94 1f 00 00    	mov    0x1f94(%eax),%esi
f0100f0c:	c7 c7 d0 96 11 f0    	mov    $0xf01196d0,%edi
	if (PGNUM(pa) >= npages)
f0100f12:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100f18:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f1b:	e9 ed fc ff ff       	jmp    f0100c0d <check_page_free_list+0x70>

f0100f20 <page_init>:
{
f0100f20:	55                   	push   %ebp
f0100f21:	89 e5                	mov    %esp,%ebp
f0100f23:	57                   	push   %edi
f0100f24:	56                   	push   %esi
f0100f25:	53                   	push   %ebx
f0100f26:	83 ec 2c             	sub    $0x2c,%esp
f0100f29:	e8 ae 21 00 00       	call   f01030dc <__x86.get_pc_thunk.si>
f0100f2e:	81 c6 da 63 01 00    	add    $0x163da,%esi
f0100f34:	89 75 d8             	mov    %esi,-0x28(%ebp)
	pages[0].pp_ref = 1;
f0100f37:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100f3d:	8b 00                	mov    (%eax),%eax
f0100f3f:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f0100f45:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	for(i = 1; i < npages_basemem; i++){
f0100f4b:	8b be 98 1f 00 00    	mov    0x1f98(%esi),%edi
f0100f51:	8b 9e 94 1f 00 00    	mov    0x1f94(%esi),%ebx
f0100f57:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f5c:	b8 01 00 00 00       	mov    $0x1,%eax
		pages[i].pp_ref = 0;
f0100f61:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
	for(i = 1; i < npages_basemem; i++){
f0100f67:	eb 1f                	jmp    f0100f88 <page_init+0x68>
		pages[i].pp_ref = 0;
f0100f69:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100f70:	89 d1                	mov    %edx,%ecx
f0100f72:	03 0e                	add    (%esi),%ecx
f0100f74:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100f7a:	89 19                	mov    %ebx,(%ecx)
	for(i = 1; i < npages_basemem; i++){
f0100f7c:	83 c0 01             	add    $0x1,%eax
		page_free_list = &pages[i];
f0100f7f:	89 d3                	mov    %edx,%ebx
f0100f81:	03 1e                	add    (%esi),%ebx
f0100f83:	ba 01 00 00 00       	mov    $0x1,%edx
	for(i = 1; i < npages_basemem; i++){
f0100f88:	39 c7                	cmp    %eax,%edi
f0100f8a:	77 dd                	ja     f0100f69 <page_init+0x49>
f0100f8c:	84 d2                	test   %dl,%dl
f0100f8e:	75 57                	jne    f0100fe7 <page_init+0xc7>
	uint32_t firstFreeAlloc = (uint32_t) boot_alloc(0);
f0100f90:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f95:	e8 0f fb ff ff       	call   f0100aa9 <boot_alloc>
f0100f9a:	89 45 e0             	mov    %eax,-0x20(%ebp)
	for(i = ((uint32_t)boot_alloc(0) - KERNBASE)/PGSIZE; i < npages; i++){
f0100f9d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fa2:	e8 02 fb ff ff       	call   f0100aa9 <boot_alloc>
f0100fa7:	05 00 00 00 10       	add    $0x10000000,%eax
f0100fac:	c1 e8 0c             	shr    $0xc,%eax
f0100faf:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100fb2:	8b be 94 1f 00 00    	mov    0x1f94(%esi),%edi
f0100fb8:	8d 90 00 00 0f 00    	lea    0xf0000(%eax),%edx
f0100fbe:	c1 e2 0c             	shl    $0xc,%edx
f0100fc1:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100fc4:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0100fcb:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100fd0:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0100fd6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			pages[i].pp_ref = 0;
f0100fd9:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
f0100fdf:	89 75 dc             	mov    %esi,-0x24(%ebp)
f0100fe2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
	for(i = ((uint32_t)boot_alloc(0) - KERNBASE)/PGSIZE; i < npages; i++){
f0100fe5:	eb 17                	jmp    f0100ffe <page_init+0xde>
f0100fe7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100fea:	89 98 94 1f 00 00    	mov    %ebx,0x1f94(%eax)
f0100ff0:	eb 9e                	jmp    f0100f90 <page_init+0x70>
f0100ff2:	83 c0 01             	add    $0x1,%eax
f0100ff5:	81 c2 00 10 00 00    	add    $0x1000,%edx
f0100ffb:	83 c1 08             	add    $0x8,%ecx
f0100ffe:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101001:	39 06                	cmp    %eax,(%esi)
f0101003:	76 22                	jbe    f0101027 <page_init+0x107>
		if(KERNBASE + i * PGSIZE > firstFreeAlloc){
f0101005:	39 55 e0             	cmp    %edx,-0x20(%ebp)
f0101008:	73 e8                	jae    f0100ff2 <page_init+0xd2>
			pages[i].pp_ref = 0;
f010100a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010100d:	89 ce                	mov    %ecx,%esi
f010100f:	03 33                	add    (%ebx),%esi
f0101011:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
			pages[i].pp_link = page_free_list;
f0101017:	89 3e                	mov    %edi,(%esi)
			page_free_list = &pages[i];
f0101019:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010101c:	89 cf                	mov    %ecx,%edi
f010101e:	03 3b                	add    (%ebx),%edi
f0101020:	bb 01 00 00 00       	mov    $0x1,%ebx
f0101025:	eb cb                	jmp    f0100ff2 <page_init+0xd2>
f0101027:	84 db                	test   %bl,%bl
f0101029:	75 08                	jne    f0101033 <page_init+0x113>
}
f010102b:	83 c4 2c             	add    $0x2c,%esp
f010102e:	5b                   	pop    %ebx
f010102f:	5e                   	pop    %esi
f0101030:	5f                   	pop    %edi
f0101031:	5d                   	pop    %ebp
f0101032:	c3                   	ret    
f0101033:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101036:	89 b8 94 1f 00 00    	mov    %edi,0x1f94(%eax)
f010103c:	eb ed                	jmp    f010102b <page_init+0x10b>

f010103e <page_alloc>:
{
f010103e:	55                   	push   %ebp
f010103f:	89 e5                	mov    %esp,%ebp
f0101041:	56                   	push   %esi
f0101042:	53                   	push   %ebx
f0101043:	e8 07 f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101048:	81 c3 c0 62 01 00    	add    $0x162c0,%ebx
	struct PageInfo *page_pop = page_free_list;
f010104e:	8b b3 94 1f 00 00    	mov    0x1f94(%ebx),%esi
	if (page_pop == NULL)
f0101054:	85 f6                	test   %esi,%esi
f0101056:	74 14                	je     f010106c <page_alloc+0x2e>
	page_free_list = page_pop->pp_link;
f0101058:	8b 06                	mov    (%esi),%eax
f010105a:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	page_pop->pp_link = NULL; 
f0101060:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if (alloc_flags & ALLOC_ZERO)
f0101066:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010106a:	75 09                	jne    f0101075 <page_alloc+0x37>
}
f010106c:	89 f0                	mov    %esi,%eax
f010106e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101071:	5b                   	pop    %ebx
f0101072:	5e                   	pop    %esi
f0101073:	5d                   	pop    %ebp
f0101074:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f0101075:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010107b:	89 f2                	mov    %esi,%edx
f010107d:	2b 10                	sub    (%eax),%edx
f010107f:	89 d0                	mov    %edx,%eax
f0101081:	c1 f8 03             	sar    $0x3,%eax
f0101084:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101087:	89 c1                	mov    %eax,%ecx
f0101089:	c1 e9 0c             	shr    $0xc,%ecx
f010108c:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101092:	3b 0a                	cmp    (%edx),%ecx
f0101094:	73 1a                	jae    f01010b0 <page_alloc+0x72>
		memset(ptr, 0, PGSIZE);
f0101096:	83 ec 04             	sub    $0x4,%esp
f0101099:	68 00 10 00 00       	push   $0x1000
f010109e:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f01010a0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01010a5:	50                   	push   %eax
f01010a6:	e8 1c 2c 00 00       	call   f0103cc7 <memset>
f01010ab:	83 c4 10             	add    $0x10,%esp
f01010ae:	eb bc                	jmp    f010106c <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010b0:	50                   	push   %eax
f01010b1:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f01010b7:	50                   	push   %eax
f01010b8:	6a 52                	push   $0x52
f01010ba:	8d 83 20 d3 fe ff    	lea    -0x12ce0(%ebx),%eax
f01010c0:	50                   	push   %eax
f01010c1:	e8 d3 ef ff ff       	call   f0100099 <_panic>

f01010c6 <page_free>:
{
f01010c6:	55                   	push   %ebp
f01010c7:	89 e5                	mov    %esp,%ebp
f01010c9:	53                   	push   %ebx
f01010ca:	83 ec 04             	sub    $0x4,%esp
f01010cd:	e8 7d f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01010d2:	81 c3 36 62 01 00    	add    $0x16236,%ebx
f01010d8:	8b 45 08             	mov    0x8(%ebp),%eax
	assert(pp->pp_ref == 0);  
f01010db:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01010e0:	75 18                	jne    f01010fa <page_free+0x34>
	assert(pp->pp_link == NULL); 
f01010e2:	83 38 00             	cmpl   $0x0,(%eax)
f01010e5:	75 32                	jne    f0101119 <page_free+0x53>
	pp->pp_link = page_free_list;
f01010e7:	8b 8b 94 1f 00 00    	mov    0x1f94(%ebx),%ecx
f01010ed:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f01010ef:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
}
f01010f5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010f8:	c9                   	leave  
f01010f9:	c3                   	ret    
	assert(pp->pp_ref == 0);  
f01010fa:	8d 83 ca d3 fe ff    	lea    -0x12c36(%ebx),%eax
f0101100:	50                   	push   %eax
f0101101:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0101107:	50                   	push   %eax
f0101108:	68 be 01 00 00       	push   $0x1be
f010110d:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0101113:	50                   	push   %eax
f0101114:	e8 80 ef ff ff       	call   f0100099 <_panic>
	assert(pp->pp_link == NULL); 
f0101119:	8d 83 da d3 fe ff    	lea    -0x12c26(%ebx),%eax
f010111f:	50                   	push   %eax
f0101120:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0101126:	50                   	push   %eax
f0101127:	68 c2 01 00 00       	push   $0x1c2
f010112c:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0101132:	50                   	push   %eax
f0101133:	e8 61 ef ff ff       	call   f0100099 <_panic>

f0101138 <page_decref>:
{
f0101138:	55                   	push   %ebp
f0101139:	89 e5                	mov    %esp,%ebp
f010113b:	83 ec 08             	sub    $0x8,%esp
f010113e:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101141:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101145:	83 e8 01             	sub    $0x1,%eax
f0101148:	66 89 42 04          	mov    %ax,0x4(%edx)
f010114c:	66 85 c0             	test   %ax,%ax
f010114f:	74 02                	je     f0101153 <page_decref+0x1b>
}
f0101151:	c9                   	leave  
f0101152:	c3                   	ret    
		page_free(pp);
f0101153:	83 ec 0c             	sub    $0xc,%esp
f0101156:	52                   	push   %edx
f0101157:	e8 6a ff ff ff       	call   f01010c6 <page_free>
f010115c:	83 c4 10             	add    $0x10,%esp
}
f010115f:	eb f0                	jmp    f0101151 <page_decref+0x19>

f0101161 <pgdir_walk>:
{
f0101161:	55                   	push   %ebp
f0101162:	89 e5                	mov    %esp,%ebp
f0101164:	57                   	push   %edi
f0101165:	56                   	push   %esi
f0101166:	53                   	push   %ebx
f0101167:	83 ec 0c             	sub    $0xc,%esp
f010116a:	e8 e0 ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010116f:	81 c3 99 61 01 00    	add    $0x16199,%ebx
f0101175:	8b 75 0c             	mov    0xc(%ebp),%esi
	uintptr_t pd_index = PDX(va);
f0101178:	89 f7                	mov    %esi,%edi
f010117a:	c1 ef 16             	shr    $0x16,%edi
	pde_t pd_entry = pgdir[pd_index];
f010117d:	c1 e7 02             	shl    $0x2,%edi
f0101180:	03 7d 08             	add    0x8(%ebp),%edi
f0101183:	8b 07                	mov    (%edi),%eax
	if (pd_entry == 0) 
f0101185:	85 c0                	test   %eax,%eax
f0101187:	75 71                	jne    f01011fa <pgdir_walk+0x99>
		if (create == 0) // create 0 implies we don't want to initialize a new page dir entry
f0101189:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010118d:	0f 84 ae 00 00 00    	je     f0101241 <pgdir_walk+0xe0>
		newpg = page_alloc(ALLOC_ZERO);
f0101193:	83 ec 0c             	sub    $0xc,%esp
f0101196:	6a 01                	push   $0x1
f0101198:	e8 a1 fe ff ff       	call   f010103e <page_alloc>
		if (!newpg)
f010119d:	83 c4 10             	add    $0x10,%esp
f01011a0:	85 c0                	test   %eax,%eax
f01011a2:	0f 84 a0 00 00 00    	je     f0101248 <pgdir_walk+0xe7>
		newpg->pp_ref += 1;
f01011a8:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01011ad:	c7 c1 d0 96 11 f0    	mov    $0xf01196d0,%ecx
f01011b3:	89 c2                	mov    %eax,%edx
f01011b5:	2b 11                	sub    (%ecx),%edx
f01011b7:	c1 fa 03             	sar    $0x3,%edx
f01011ba:	c1 e2 0c             	shl    $0xc,%edx
		pgdir[pd_index] = (uintptr_t) page2pa(newpg) | PTE_P | PTE_U | PTE_W;
f01011bd:	83 ca 07             	or     $0x7,%edx
f01011c0:	89 17                	mov    %edx,(%edi)
f01011c2:	2b 01                	sub    (%ecx),%eax
f01011c4:	c1 f8 03             	sar    $0x3,%eax
f01011c7:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01011ca:	89 c2                	mov    %eax,%edx
f01011cc:	c1 ea 0c             	shr    $0xc,%edx
f01011cf:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f01011d5:	39 11                	cmp    %edx,(%ecx)
f01011d7:	76 08                	jbe    f01011e1 <pgdir_walk+0x80>
	return (void *)(pa + KERNBASE);
f01011d9:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f01011df:	eb 33                	jmp    f0101214 <pgdir_walk+0xb3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011e1:	50                   	push   %eax
f01011e2:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f01011e8:	50                   	push   %eax
f01011e9:	68 19 02 00 00       	push   $0x219
f01011ee:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01011f4:	50                   	push   %eax
f01011f5:	e8 9f ee ff ff       	call   f0100099 <_panic>
		physaddr_t pt_physadd = PTE_ADDR(pd_entry); // Now we have the physical address of the page table
f01011fa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f01011ff:	89 c1                	mov    %eax,%ecx
f0101201:	c1 e9 0c             	shr    $0xc,%ecx
f0101204:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f010120a:	3b 0a                	cmp    (%edx),%ecx
f010120c:	73 1a                	jae    f0101228 <pgdir_walk+0xc7>
	return (void *)(pa + KERNBASE);
f010120e:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
	return pt_entry + PTX(va); // add the page table index as an offset to the page table pointer
f0101214:	c1 ee 0a             	shr    $0xa,%esi
f0101217:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010121d:	8d 04 32             	lea    (%edx,%esi,1),%eax
}
f0101220:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101223:	5b                   	pop    %ebx
f0101224:	5e                   	pop    %esi
f0101225:	5f                   	pop    %edi
f0101226:	5d                   	pop    %ebp
f0101227:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101228:	50                   	push   %eax
f0101229:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f010122f:	50                   	push   %eax
f0101230:	68 1e 02 00 00       	push   $0x21e
f0101235:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010123b:	50                   	push   %eax
f010123c:	e8 58 ee ff ff       	call   f0100099 <_panic>
			return NULL;
f0101241:	b8 00 00 00 00       	mov    $0x0,%eax
f0101246:	eb d8                	jmp    f0101220 <pgdir_walk+0xbf>
			return NULL;
f0101248:	b8 00 00 00 00       	mov    $0x0,%eax
f010124d:	eb d1                	jmp    f0101220 <pgdir_walk+0xbf>

f010124f <boot_map_region>:
{
f010124f:	55                   	push   %ebp
f0101250:	89 e5                	mov    %esp,%ebp
f0101252:	57                   	push   %edi
f0101253:	56                   	push   %esi
f0101254:	53                   	push   %ebx
f0101255:	83 ec 1c             	sub    $0x1c,%esp
f0101258:	e8 f2 ee ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010125d:	81 c3 ab 60 01 00    	add    $0x160ab,%ebx
f0101263:	89 c7                	mov    %eax,%edi
f0101265:	8b 45 08             	mov    0x8(%ebp),%eax
	size = ROUNDUP(size, PGSIZE);
f0101268:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
	assert(va % PGSIZE == 0);
f010126e:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0101274:	75 24                	jne    f010129a <boot_map_region+0x4b>
	assert(pa % PGSIZE == 0);
f0101276:	a9 ff 0f 00 00       	test   $0xfff,%eax
f010127b:	75 3c                	jne    f01012b9 <boot_map_region+0x6a>
	for(size_t i = 0; i < size/PGSIZE; i++){
f010127d:	c1 e9 0c             	shr    $0xc,%ecx
f0101280:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101283:	89 d3                	mov    %edx,%ebx
f0101285:	be 00 00 00 00       	mov    $0x0,%esi
			*pt_entry = (pa + i*PGSIZE) | perm | PTE_P;
f010128a:	29 d0                	sub    %edx,%eax
f010128c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010128f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101292:	83 c8 01             	or     $0x1,%eax
f0101295:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101298:	eb 47                	jmp    f01012e1 <boot_map_region+0x92>
	assert(va % PGSIZE == 0);
f010129a:	8d 83 ee d3 fe ff    	lea    -0x12c12(%ebx),%eax
f01012a0:	50                   	push   %eax
f01012a1:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01012a7:	50                   	push   %eax
f01012a8:	68 3f 02 00 00       	push   $0x23f
f01012ad:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01012b3:	50                   	push   %eax
f01012b4:	e8 e0 ed ff ff       	call   f0100099 <_panic>
	assert(pa % PGSIZE == 0);
f01012b9:	8d 83 ff d3 fe ff    	lea    -0x12c01(%ebx),%eax
f01012bf:	50                   	push   %eax
f01012c0:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01012c6:	50                   	push   %eax
f01012c7:	68 40 02 00 00       	push   $0x240
f01012cc:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01012d2:	50                   	push   %eax
f01012d3:	e8 c1 ed ff ff       	call   f0100099 <_panic>
	for(size_t i = 0; i < size/PGSIZE; i++){
f01012d8:	83 c6 01             	add    $0x1,%esi
f01012db:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01012e1:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f01012e4:	74 20                	je     f0101306 <boot_map_region+0xb7>
		pte_t * pt_entry = pgdir_walk(pgdir, (void *) va + i * PGSIZE, 1);
f01012e6:	83 ec 04             	sub    $0x4,%esp
f01012e9:	6a 01                	push   $0x1
f01012eb:	53                   	push   %ebx
f01012ec:	57                   	push   %edi
f01012ed:	e8 6f fe ff ff       	call   f0101161 <pgdir_walk>
		if(pt_entry != NULL){
f01012f2:	83 c4 10             	add    $0x10,%esp
f01012f5:	85 c0                	test   %eax,%eax
f01012f7:	74 df                	je     f01012d8 <boot_map_region+0x89>
			*pt_entry = (pa + i*PGSIZE) | perm | PTE_P;
f01012f9:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01012fc:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
f01012ff:	0b 55 dc             	or     -0x24(%ebp),%edx
f0101302:	89 10                	mov    %edx,(%eax)
f0101304:	eb d2                	jmp    f01012d8 <boot_map_region+0x89>
}
f0101306:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101309:	5b                   	pop    %ebx
f010130a:	5e                   	pop    %esi
f010130b:	5f                   	pop    %edi
f010130c:	5d                   	pop    %ebp
f010130d:	c3                   	ret    

f010130e <page_lookup>:
{
f010130e:	55                   	push   %ebp
f010130f:	89 e5                	mov    %esp,%ebp
f0101311:	56                   	push   %esi
f0101312:	53                   	push   %ebx
f0101313:	e8 37 ee ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101318:	81 c3 f0 5f 01 00    	add    $0x15ff0,%ebx
f010131e:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t * pt_entry = pgdir_walk(pgdir, va, 0);
f0101321:	83 ec 04             	sub    $0x4,%esp
f0101324:	6a 00                	push   $0x0
f0101326:	ff 75 0c             	pushl  0xc(%ebp)
f0101329:	ff 75 08             	pushl  0x8(%ebp)
f010132c:	e8 30 fe ff ff       	call   f0101161 <pgdir_walk>
	if(!pt_entry){
f0101331:	83 c4 10             	add    $0x10,%esp
f0101334:	85 c0                	test   %eax,%eax
f0101336:	74 3f                	je     f0101377 <page_lookup+0x69>
	if(pte_store){
f0101338:	85 f6                	test   %esi,%esi
f010133a:	74 02                	je     f010133e <page_lookup+0x30>
		*pte_store = pt_entry;
f010133c:	89 06                	mov    %eax,(%esi)
f010133e:	8b 00                	mov    (%eax),%eax
f0101340:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101343:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101349:	39 02                	cmp    %eax,(%edx)
f010134b:	76 12                	jbe    f010135f <page_lookup+0x51>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f010134d:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101353:	8b 12                	mov    (%edx),%edx
f0101355:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f0101358:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010135b:	5b                   	pop    %ebx
f010135c:	5e                   	pop    %esi
f010135d:	5d                   	pop    %ebp
f010135e:	c3                   	ret    
		panic("pa2page called with invalid pa");
f010135f:	83 ec 04             	sub    $0x4,%esp
f0101362:	8d 83 4c d7 fe ff    	lea    -0x128b4(%ebx),%eax
f0101368:	50                   	push   %eax
f0101369:	6a 4b                	push   $0x4b
f010136b:	8d 83 20 d3 fe ff    	lea    -0x12ce0(%ebx),%eax
f0101371:	50                   	push   %eax
f0101372:	e8 22 ed ff ff       	call   f0100099 <_panic>
		return NULL;
f0101377:	b8 00 00 00 00       	mov    $0x0,%eax
f010137c:	eb da                	jmp    f0101358 <page_lookup+0x4a>

f010137e <page_remove>:
{
f010137e:	55                   	push   %ebp
f010137f:	89 e5                	mov    %esp,%ebp
f0101381:	53                   	push   %ebx
f0101382:	83 ec 18             	sub    $0x18,%esp
f0101385:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo * page = page_lookup(pgdir, va, &pt_entry_store);
f0101388:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010138b:	50                   	push   %eax
f010138c:	53                   	push   %ebx
f010138d:	ff 75 08             	pushl  0x8(%ebp)
f0101390:	e8 79 ff ff ff       	call   f010130e <page_lookup>
	if(page){
f0101395:	83 c4 10             	add    $0x10,%esp
f0101398:	85 c0                	test   %eax,%eax
f010139a:	74 18                	je     f01013b4 <page_remove+0x36>
		page_decref(page);
f010139c:	83 ec 0c             	sub    $0xc,%esp
f010139f:	50                   	push   %eax
f01013a0:	e8 93 fd ff ff       	call   f0101138 <page_decref>
		*pt_entry_store = 0;
f01013a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01013a8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01013ae:	0f 01 3b             	invlpg (%ebx)
f01013b1:	83 c4 10             	add    $0x10,%esp
}
f01013b4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01013b7:	c9                   	leave  
f01013b8:	c3                   	ret    

f01013b9 <page_insert>:
{
f01013b9:	55                   	push   %ebp
f01013ba:	89 e5                	mov    %esp,%ebp
f01013bc:	57                   	push   %edi
f01013bd:	56                   	push   %esi
f01013be:	53                   	push   %ebx
f01013bf:	83 ec 10             	sub    $0x10,%esp
f01013c2:	e8 19 1d 00 00       	call   f01030e0 <__x86.get_pc_thunk.di>
f01013c7:	81 c7 41 5f 01 00    	add    $0x15f41,%edi
f01013cd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pt_entry = pgdir_walk(pgdir, va, 1);
f01013d0:	6a 01                	push   $0x1
f01013d2:	ff 75 10             	pushl  0x10(%ebp)
f01013d5:	ff 75 08             	pushl  0x8(%ebp)
f01013d8:	e8 84 fd ff ff       	call   f0101161 <pgdir_walk>
	if(pt_entry == NULL){
f01013dd:	83 c4 10             	add    $0x10,%esp
f01013e0:	85 c0                	test   %eax,%eax
f01013e2:	74 63                	je     f0101447 <page_insert+0x8e>
f01013e4:	89 c6                	mov    %eax,%esi
	if(pp->pp_ref == 0){
f01013e6:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01013ea:	66 85 c0             	test   %ax,%ax
f01013ed:	75 0e                	jne    f01013fd <page_insert+0x44>
		page_free_list = pp->pp_link;
f01013ef:	8b 13                	mov    (%ebx),%edx
f01013f1:	89 97 94 1f 00 00    	mov    %edx,0x1f94(%edi)
		pp->pp_link = NULL;
f01013f7:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	pp->pp_ref++;
f01013fd:	83 c0 01             	add    $0x1,%eax
f0101400:	66 89 43 04          	mov    %ax,0x4(%ebx)
	if(*pt_entry)
f0101404:	83 3e 00             	cmpl   $0x0,(%esi)
f0101407:	75 2b                	jne    f0101434 <page_insert+0x7b>
	return (pp - pages) << PGSHIFT;
f0101409:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010140f:	2b 18                	sub    (%eax),%ebx
f0101411:	c1 fb 03             	sar    $0x3,%ebx
f0101414:	c1 e3 0c             	shl    $0xc,%ebx
	*pt_entry = page2pa(pp) | perm | PTE_P; // permissions from comments, but what does it mean?
f0101417:	8b 45 14             	mov    0x14(%ebp),%eax
f010141a:	83 c8 01             	or     $0x1,%eax
f010141d:	09 c3                	or     %eax,%ebx
f010141f:	89 1e                	mov    %ebx,(%esi)
f0101421:	8b 45 10             	mov    0x10(%ebp),%eax
f0101424:	0f 01 38             	invlpg (%eax)
	return 0;
f0101427:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010142c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010142f:	5b                   	pop    %ebx
f0101430:	5e                   	pop    %esi
f0101431:	5f                   	pop    %edi
f0101432:	5d                   	pop    %ebp
f0101433:	c3                   	ret    
		page_remove(pgdir, va);
f0101434:	83 ec 08             	sub    $0x8,%esp
f0101437:	ff 75 10             	pushl  0x10(%ebp)
f010143a:	ff 75 08             	pushl  0x8(%ebp)
f010143d:	e8 3c ff ff ff       	call   f010137e <page_remove>
f0101442:	83 c4 10             	add    $0x10,%esp
f0101445:	eb c2                	jmp    f0101409 <page_insert+0x50>
		return -E_NO_MEM;
f0101447:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010144c:	eb de                	jmp    f010142c <page_insert+0x73>

f010144e <mem_init>:
{
f010144e:	55                   	push   %ebp
f010144f:	89 e5                	mov    %esp,%ebp
f0101451:	57                   	push   %edi
f0101452:	56                   	push   %esi
f0101453:	53                   	push   %ebx
f0101454:	83 ec 3c             	sub    $0x3c,%esp
f0101457:	e8 f3 ec ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010145c:	81 c3 ac 5e 01 00    	add    $0x15eac,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f0101462:	b8 15 00 00 00       	mov    $0x15,%eax
f0101467:	e8 07 f6 ff ff       	call   f0100a73 <nvram_read>
f010146c:	89 c7                	mov    %eax,%edi
	extmem = nvram_read(NVRAM_EXTLO);
f010146e:	b8 17 00 00 00       	mov    $0x17,%eax
f0101473:	e8 fb f5 ff ff       	call   f0100a73 <nvram_read>
f0101478:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010147a:	b8 34 00 00 00       	mov    $0x34,%eax
f010147f:	e8 ef f5 ff ff       	call   f0100a73 <nvram_read>
f0101484:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0101487:	85 c0                	test   %eax,%eax
f0101489:	0f 85 c0 00 00 00    	jne    f010154f <mem_init+0x101>
		totalmem = 1 * 1024 + extmem;
f010148f:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101495:	85 f6                	test   %esi,%esi
f0101497:	0f 44 c7             	cmove  %edi,%eax
	npages = totalmem / (PGSIZE / 1024);
f010149a:	89 c1                	mov    %eax,%ecx
f010149c:	c1 e9 02             	shr    $0x2,%ecx
f010149f:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f01014a5:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f01014a7:	89 fa                	mov    %edi,%edx
f01014a9:	c1 ea 02             	shr    $0x2,%edx
f01014ac:	89 93 98 1f 00 00    	mov    %edx,0x1f98(%ebx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01014b2:	89 c2                	mov    %eax,%edx
f01014b4:	29 fa                	sub    %edi,%edx
f01014b6:	52                   	push   %edx
f01014b7:	57                   	push   %edi
f01014b8:	50                   	push   %eax
f01014b9:	8d 83 6c d7 fe ff    	lea    -0x12894(%ebx),%eax
f01014bf:	50                   	push   %eax
f01014c0:	e8 a6 1c 00 00       	call   f010316b <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01014c5:	b8 00 10 00 00       	mov    $0x1000,%eax
f01014ca:	e8 da f5 ff ff       	call   f0100aa9 <boot_alloc>
f01014cf:	c7 c6 cc 96 11 f0    	mov    $0xf01196cc,%esi
f01014d5:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f01014d7:	83 c4 0c             	add    $0xc,%esp
f01014da:	68 00 10 00 00       	push   $0x1000
f01014df:	6a 00                	push   $0x0
f01014e1:	50                   	push   %eax
f01014e2:	e8 e0 27 00 00       	call   f0103cc7 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01014e7:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f01014e9:	83 c4 10             	add    $0x10,%esp
f01014ec:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01014f1:	76 66                	jbe    f0101559 <mem_init+0x10b>
	return (physaddr_t)kva - KERNBASE;
f01014f3:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01014f9:	83 ca 05             	or     $0x5,%edx
f01014fc:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0101502:	c7 c7 c8 96 11 f0    	mov    $0xf01196c8,%edi
f0101508:	8b 07                	mov    (%edi),%eax
f010150a:	c1 e0 03             	shl    $0x3,%eax
f010150d:	e8 97 f5 ff ff       	call   f0100aa9 <boot_alloc>
f0101512:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
f0101518:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010151a:	83 ec 04             	sub    $0x4,%esp
f010151d:	8b 17                	mov    (%edi),%edx
f010151f:	c1 e2 03             	shl    $0x3,%edx
f0101522:	52                   	push   %edx
f0101523:	6a 00                	push   $0x0
f0101525:	50                   	push   %eax
f0101526:	e8 9c 27 00 00       	call   f0103cc7 <memset>
	page_init();
f010152b:	e8 f0 f9 ff ff       	call   f0100f20 <page_init>
	check_page_free_list(1);
f0101530:	b8 01 00 00 00       	mov    $0x1,%eax
f0101535:	e8 63 f6 ff ff       	call   f0100b9d <check_page_free_list>
	if (!pages)
f010153a:	83 c4 10             	add    $0x10,%esp
f010153d:	83 3e 00             	cmpl   $0x0,(%esi)
f0101540:	74 30                	je     f0101572 <mem_init+0x124>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101542:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f0101548:	be 00 00 00 00       	mov    $0x0,%esi
f010154d:	eb 43                	jmp    f0101592 <mem_init+0x144>
		totalmem = 16 * 1024 + ext16mem;
f010154f:	05 00 40 00 00       	add    $0x4000,%eax
f0101554:	e9 41 ff ff ff       	jmp    f010149a <mem_init+0x4c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101559:	50                   	push   %eax
f010155a:	8d 83 a8 d7 fe ff    	lea    -0x12858(%ebx),%eax
f0101560:	50                   	push   %eax
f0101561:	68 a4 00 00 00       	push   $0xa4
f0101566:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010156c:	50                   	push   %eax
f010156d:	e8 27 eb ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f0101572:	83 ec 04             	sub    $0x4,%esp
f0101575:	8d 83 10 d4 fe ff    	lea    -0x12bf0(%ebx),%eax
f010157b:	50                   	push   %eax
f010157c:	68 5b 03 00 00       	push   $0x35b
f0101581:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0101587:	50                   	push   %eax
f0101588:	e8 0c eb ff ff       	call   f0100099 <_panic>
		++nfree;
f010158d:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101590:	8b 00                	mov    (%eax),%eax
f0101592:	85 c0                	test   %eax,%eax
f0101594:	75 f7                	jne    f010158d <mem_init+0x13f>
	assert((pp0 = page_alloc(0)));
f0101596:	83 ec 0c             	sub    $0xc,%esp
f0101599:	6a 00                	push   $0x0
f010159b:	e8 9e fa ff ff       	call   f010103e <page_alloc>
f01015a0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015a3:	83 c4 10             	add    $0x10,%esp
f01015a6:	85 c0                	test   %eax,%eax
f01015a8:	0f 84 2e 02 00 00    	je     f01017dc <mem_init+0x38e>
	assert((pp1 = page_alloc(0)));
f01015ae:	83 ec 0c             	sub    $0xc,%esp
f01015b1:	6a 00                	push   $0x0
f01015b3:	e8 86 fa ff ff       	call   f010103e <page_alloc>
f01015b8:	89 c7                	mov    %eax,%edi
f01015ba:	83 c4 10             	add    $0x10,%esp
f01015bd:	85 c0                	test   %eax,%eax
f01015bf:	0f 84 36 02 00 00    	je     f01017fb <mem_init+0x3ad>
	assert((pp2 = page_alloc(0)));
f01015c5:	83 ec 0c             	sub    $0xc,%esp
f01015c8:	6a 00                	push   $0x0
f01015ca:	e8 6f fa ff ff       	call   f010103e <page_alloc>
f01015cf:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01015d2:	83 c4 10             	add    $0x10,%esp
f01015d5:	85 c0                	test   %eax,%eax
f01015d7:	0f 84 3d 02 00 00    	je     f010181a <mem_init+0x3cc>
	assert(pp1 && pp1 != pp0);
f01015dd:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f01015e0:	0f 84 53 02 00 00    	je     f0101839 <mem_init+0x3eb>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015e6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015e9:	39 c7                	cmp    %eax,%edi
f01015eb:	0f 84 67 02 00 00    	je     f0101858 <mem_init+0x40a>
f01015f1:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01015f4:	0f 84 5e 02 00 00    	je     f0101858 <mem_init+0x40a>
	return (pp - pages) << PGSHIFT;
f01015fa:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101600:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101602:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0101608:	8b 10                	mov    (%eax),%edx
f010160a:	c1 e2 0c             	shl    $0xc,%edx
f010160d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101610:	29 c8                	sub    %ecx,%eax
f0101612:	c1 f8 03             	sar    $0x3,%eax
f0101615:	c1 e0 0c             	shl    $0xc,%eax
f0101618:	39 d0                	cmp    %edx,%eax
f010161a:	0f 83 57 02 00 00    	jae    f0101877 <mem_init+0x429>
f0101620:	89 f8                	mov    %edi,%eax
f0101622:	29 c8                	sub    %ecx,%eax
f0101624:	c1 f8 03             	sar    $0x3,%eax
f0101627:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010162a:	39 c2                	cmp    %eax,%edx
f010162c:	0f 86 64 02 00 00    	jbe    f0101896 <mem_init+0x448>
f0101632:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101635:	29 c8                	sub    %ecx,%eax
f0101637:	c1 f8 03             	sar    $0x3,%eax
f010163a:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010163d:	39 c2                	cmp    %eax,%edx
f010163f:	0f 86 70 02 00 00    	jbe    f01018b5 <mem_init+0x467>
	fl = page_free_list;
f0101645:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f010164b:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f010164e:	c7 83 94 1f 00 00 00 	movl   $0x0,0x1f94(%ebx)
f0101655:	00 00 00 
	assert(!page_alloc(0));
f0101658:	83 ec 0c             	sub    $0xc,%esp
f010165b:	6a 00                	push   $0x0
f010165d:	e8 dc f9 ff ff       	call   f010103e <page_alloc>
f0101662:	83 c4 10             	add    $0x10,%esp
f0101665:	85 c0                	test   %eax,%eax
f0101667:	0f 85 67 02 00 00    	jne    f01018d4 <mem_init+0x486>
	page_free(pp0);
f010166d:	83 ec 0c             	sub    $0xc,%esp
f0101670:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101673:	e8 4e fa ff ff       	call   f01010c6 <page_free>
	page_free(pp1);
f0101678:	89 3c 24             	mov    %edi,(%esp)
f010167b:	e8 46 fa ff ff       	call   f01010c6 <page_free>
	page_free(pp2);
f0101680:	83 c4 04             	add    $0x4,%esp
f0101683:	ff 75 d0             	pushl  -0x30(%ebp)
f0101686:	e8 3b fa ff ff       	call   f01010c6 <page_free>
	assert((pp0 = page_alloc(0)));
f010168b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101692:	e8 a7 f9 ff ff       	call   f010103e <page_alloc>
f0101697:	89 c7                	mov    %eax,%edi
f0101699:	83 c4 10             	add    $0x10,%esp
f010169c:	85 c0                	test   %eax,%eax
f010169e:	0f 84 4f 02 00 00    	je     f01018f3 <mem_init+0x4a5>
	assert((pp1 = page_alloc(0)));
f01016a4:	83 ec 0c             	sub    $0xc,%esp
f01016a7:	6a 00                	push   $0x0
f01016a9:	e8 90 f9 ff ff       	call   f010103e <page_alloc>
f01016ae:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016b1:	83 c4 10             	add    $0x10,%esp
f01016b4:	85 c0                	test   %eax,%eax
f01016b6:	0f 84 56 02 00 00    	je     f0101912 <mem_init+0x4c4>
	assert((pp2 = page_alloc(0)));
f01016bc:	83 ec 0c             	sub    $0xc,%esp
f01016bf:	6a 00                	push   $0x0
f01016c1:	e8 78 f9 ff ff       	call   f010103e <page_alloc>
f01016c6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01016c9:	83 c4 10             	add    $0x10,%esp
f01016cc:	85 c0                	test   %eax,%eax
f01016ce:	0f 84 5d 02 00 00    	je     f0101931 <mem_init+0x4e3>
	assert(pp1 && pp1 != pp0);
f01016d4:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01016d7:	0f 84 73 02 00 00    	je     f0101950 <mem_init+0x502>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016dd:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01016e0:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01016e3:	0f 84 86 02 00 00    	je     f010196f <mem_init+0x521>
f01016e9:	39 c7                	cmp    %eax,%edi
f01016eb:	0f 84 7e 02 00 00    	je     f010196f <mem_init+0x521>
	assert(!page_alloc(0));
f01016f1:	83 ec 0c             	sub    $0xc,%esp
f01016f4:	6a 00                	push   $0x0
f01016f6:	e8 43 f9 ff ff       	call   f010103e <page_alloc>
f01016fb:	83 c4 10             	add    $0x10,%esp
f01016fe:	85 c0                	test   %eax,%eax
f0101700:	0f 85 88 02 00 00    	jne    f010198e <mem_init+0x540>
f0101706:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010170c:	89 f9                	mov    %edi,%ecx
f010170e:	2b 08                	sub    (%eax),%ecx
f0101710:	89 c8                	mov    %ecx,%eax
f0101712:	c1 f8 03             	sar    $0x3,%eax
f0101715:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101718:	89 c1                	mov    %eax,%ecx
f010171a:	c1 e9 0c             	shr    $0xc,%ecx
f010171d:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101723:	3b 0a                	cmp    (%edx),%ecx
f0101725:	0f 83 82 02 00 00    	jae    f01019ad <mem_init+0x55f>
	memset(page2kva(pp0), 1, PGSIZE);
f010172b:	83 ec 04             	sub    $0x4,%esp
f010172e:	68 00 10 00 00       	push   $0x1000
f0101733:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101735:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010173a:	50                   	push   %eax
f010173b:	e8 87 25 00 00       	call   f0103cc7 <memset>
	page_free(pp0);
f0101740:	89 3c 24             	mov    %edi,(%esp)
f0101743:	e8 7e f9 ff ff       	call   f01010c6 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101748:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010174f:	e8 ea f8 ff ff       	call   f010103e <page_alloc>
f0101754:	83 c4 10             	add    $0x10,%esp
f0101757:	85 c0                	test   %eax,%eax
f0101759:	0f 84 64 02 00 00    	je     f01019c3 <mem_init+0x575>
	assert(pp && pp0 == pp);
f010175f:	39 c7                	cmp    %eax,%edi
f0101761:	0f 85 7b 02 00 00    	jne    f01019e2 <mem_init+0x594>
	return (pp - pages) << PGSHIFT;
f0101767:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010176d:	89 fa                	mov    %edi,%edx
f010176f:	2b 10                	sub    (%eax),%edx
f0101771:	c1 fa 03             	sar    $0x3,%edx
f0101774:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101777:	89 d1                	mov    %edx,%ecx
f0101779:	c1 e9 0c             	shr    $0xc,%ecx
f010177c:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0101782:	3b 08                	cmp    (%eax),%ecx
f0101784:	0f 83 77 02 00 00    	jae    f0101a01 <mem_init+0x5b3>
	return (void *)(pa + KERNBASE);
f010178a:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101790:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f0101796:	80 38 00             	cmpb   $0x0,(%eax)
f0101799:	0f 85 78 02 00 00    	jne    f0101a17 <mem_init+0x5c9>
f010179f:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01017a2:	39 d0                	cmp    %edx,%eax
f01017a4:	75 f0                	jne    f0101796 <mem_init+0x348>
	page_free_list = fl;
f01017a6:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01017a9:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	page_free(pp0);
f01017af:	83 ec 0c             	sub    $0xc,%esp
f01017b2:	57                   	push   %edi
f01017b3:	e8 0e f9 ff ff       	call   f01010c6 <page_free>
	page_free(pp1);
f01017b8:	83 c4 04             	add    $0x4,%esp
f01017bb:	ff 75 d4             	pushl  -0x2c(%ebp)
f01017be:	e8 03 f9 ff ff       	call   f01010c6 <page_free>
	page_free(pp2);
f01017c3:	83 c4 04             	add    $0x4,%esp
f01017c6:	ff 75 d0             	pushl  -0x30(%ebp)
f01017c9:	e8 f8 f8 ff ff       	call   f01010c6 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017ce:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f01017d4:	83 c4 10             	add    $0x10,%esp
f01017d7:	e9 5f 02 00 00       	jmp    f0101a3b <mem_init+0x5ed>
	assert((pp0 = page_alloc(0)));
f01017dc:	8d 83 2b d4 fe ff    	lea    -0x12bd5(%ebx),%eax
f01017e2:	50                   	push   %eax
f01017e3:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01017e9:	50                   	push   %eax
f01017ea:	68 63 03 00 00       	push   $0x363
f01017ef:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01017f5:	50                   	push   %eax
f01017f6:	e8 9e e8 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01017fb:	8d 83 41 d4 fe ff    	lea    -0x12bbf(%ebx),%eax
f0101801:	50                   	push   %eax
f0101802:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0101808:	50                   	push   %eax
f0101809:	68 64 03 00 00       	push   $0x364
f010180e:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0101814:	50                   	push   %eax
f0101815:	e8 7f e8 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010181a:	8d 83 57 d4 fe ff    	lea    -0x12ba9(%ebx),%eax
f0101820:	50                   	push   %eax
f0101821:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0101827:	50                   	push   %eax
f0101828:	68 65 03 00 00       	push   $0x365
f010182d:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0101833:	50                   	push   %eax
f0101834:	e8 60 e8 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101839:	8d 83 6d d4 fe ff    	lea    -0x12b93(%ebx),%eax
f010183f:	50                   	push   %eax
f0101840:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0101846:	50                   	push   %eax
f0101847:	68 68 03 00 00       	push   $0x368
f010184c:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0101852:	50                   	push   %eax
f0101853:	e8 41 e8 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101858:	8d 83 cc d7 fe ff    	lea    -0x12834(%ebx),%eax
f010185e:	50                   	push   %eax
f010185f:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0101865:	50                   	push   %eax
f0101866:	68 69 03 00 00       	push   $0x369
f010186b:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0101871:	50                   	push   %eax
f0101872:	e8 22 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101877:	8d 83 7f d4 fe ff    	lea    -0x12b81(%ebx),%eax
f010187d:	50                   	push   %eax
f010187e:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0101884:	50                   	push   %eax
f0101885:	68 6a 03 00 00       	push   $0x36a
f010188a:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0101890:	50                   	push   %eax
f0101891:	e8 03 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101896:	8d 83 9c d4 fe ff    	lea    -0x12b64(%ebx),%eax
f010189c:	50                   	push   %eax
f010189d:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01018a3:	50                   	push   %eax
f01018a4:	68 6b 03 00 00       	push   $0x36b
f01018a9:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01018af:	50                   	push   %eax
f01018b0:	e8 e4 e7 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01018b5:	8d 83 b9 d4 fe ff    	lea    -0x12b47(%ebx),%eax
f01018bb:	50                   	push   %eax
f01018bc:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01018c2:	50                   	push   %eax
f01018c3:	68 6c 03 00 00       	push   $0x36c
f01018c8:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01018ce:	50                   	push   %eax
f01018cf:	e8 c5 e7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01018d4:	8d 83 d6 d4 fe ff    	lea    -0x12b2a(%ebx),%eax
f01018da:	50                   	push   %eax
f01018db:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01018e1:	50                   	push   %eax
f01018e2:	68 73 03 00 00       	push   $0x373
f01018e7:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01018ed:	50                   	push   %eax
f01018ee:	e8 a6 e7 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f01018f3:	8d 83 2b d4 fe ff    	lea    -0x12bd5(%ebx),%eax
f01018f9:	50                   	push   %eax
f01018fa:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0101900:	50                   	push   %eax
f0101901:	68 7a 03 00 00       	push   $0x37a
f0101906:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010190c:	50                   	push   %eax
f010190d:	e8 87 e7 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101912:	8d 83 41 d4 fe ff    	lea    -0x12bbf(%ebx),%eax
f0101918:	50                   	push   %eax
f0101919:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010191f:	50                   	push   %eax
f0101920:	68 7b 03 00 00       	push   $0x37b
f0101925:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010192b:	50                   	push   %eax
f010192c:	e8 68 e7 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101931:	8d 83 57 d4 fe ff    	lea    -0x12ba9(%ebx),%eax
f0101937:	50                   	push   %eax
f0101938:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010193e:	50                   	push   %eax
f010193f:	68 7c 03 00 00       	push   $0x37c
f0101944:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010194a:	50                   	push   %eax
f010194b:	e8 49 e7 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101950:	8d 83 6d d4 fe ff    	lea    -0x12b93(%ebx),%eax
f0101956:	50                   	push   %eax
f0101957:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010195d:	50                   	push   %eax
f010195e:	68 7e 03 00 00       	push   $0x37e
f0101963:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0101969:	50                   	push   %eax
f010196a:	e8 2a e7 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010196f:	8d 83 cc d7 fe ff    	lea    -0x12834(%ebx),%eax
f0101975:	50                   	push   %eax
f0101976:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010197c:	50                   	push   %eax
f010197d:	68 7f 03 00 00       	push   $0x37f
f0101982:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0101988:	50                   	push   %eax
f0101989:	e8 0b e7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010198e:	8d 83 d6 d4 fe ff    	lea    -0x12b2a(%ebx),%eax
f0101994:	50                   	push   %eax
f0101995:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010199b:	50                   	push   %eax
f010199c:	68 80 03 00 00       	push   $0x380
f01019a1:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01019a7:	50                   	push   %eax
f01019a8:	e8 ec e6 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019ad:	50                   	push   %eax
f01019ae:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f01019b4:	50                   	push   %eax
f01019b5:	6a 52                	push   $0x52
f01019b7:	8d 83 20 d3 fe ff    	lea    -0x12ce0(%ebx),%eax
f01019bd:	50                   	push   %eax
f01019be:	e8 d6 e6 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01019c3:	8d 83 e5 d4 fe ff    	lea    -0x12b1b(%ebx),%eax
f01019c9:	50                   	push   %eax
f01019ca:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01019d0:	50                   	push   %eax
f01019d1:	68 85 03 00 00       	push   $0x385
f01019d6:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01019dc:	50                   	push   %eax
f01019dd:	e8 b7 e6 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f01019e2:	8d 83 03 d5 fe ff    	lea    -0x12afd(%ebx),%eax
f01019e8:	50                   	push   %eax
f01019e9:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01019ef:	50                   	push   %eax
f01019f0:	68 86 03 00 00       	push   $0x386
f01019f5:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01019fb:	50                   	push   %eax
f01019fc:	e8 98 e6 ff ff       	call   f0100099 <_panic>
f0101a01:	52                   	push   %edx
f0101a02:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f0101a08:	50                   	push   %eax
f0101a09:	6a 52                	push   $0x52
f0101a0b:	8d 83 20 d3 fe ff    	lea    -0x12ce0(%ebx),%eax
f0101a11:	50                   	push   %eax
f0101a12:	e8 82 e6 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f0101a17:	8d 83 13 d5 fe ff    	lea    -0x12aed(%ebx),%eax
f0101a1d:	50                   	push   %eax
f0101a1e:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0101a24:	50                   	push   %eax
f0101a25:	68 89 03 00 00       	push   $0x389
f0101a2a:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0101a30:	50                   	push   %eax
f0101a31:	e8 63 e6 ff ff       	call   f0100099 <_panic>
		--nfree;
f0101a36:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a39:	8b 00                	mov    (%eax),%eax
f0101a3b:	85 c0                	test   %eax,%eax
f0101a3d:	75 f7                	jne    f0101a36 <mem_init+0x5e8>
	assert(nfree == 0);
f0101a3f:	85 f6                	test   %esi,%esi
f0101a41:	0f 85 28 08 00 00    	jne    f010226f <mem_init+0xe21>
	cprintf("check_page_alloc() succeeded!\n");
f0101a47:	83 ec 0c             	sub    $0xc,%esp
f0101a4a:	8d 83 ec d7 fe ff    	lea    -0x12814(%ebx),%eax
f0101a50:	50                   	push   %eax
f0101a51:	e8 15 17 00 00       	call   f010316b <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101a56:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a5d:	e8 dc f5 ff ff       	call   f010103e <page_alloc>
f0101a62:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a65:	83 c4 10             	add    $0x10,%esp
f0101a68:	85 c0                	test   %eax,%eax
f0101a6a:	0f 84 1e 08 00 00    	je     f010228e <mem_init+0xe40>
	assert((pp1 = page_alloc(0)));
f0101a70:	83 ec 0c             	sub    $0xc,%esp
f0101a73:	6a 00                	push   $0x0
f0101a75:	e8 c4 f5 ff ff       	call   f010103e <page_alloc>
f0101a7a:	89 c7                	mov    %eax,%edi
f0101a7c:	83 c4 10             	add    $0x10,%esp
f0101a7f:	85 c0                	test   %eax,%eax
f0101a81:	0f 84 26 08 00 00    	je     f01022ad <mem_init+0xe5f>
	assert((pp2 = page_alloc(0)));
f0101a87:	83 ec 0c             	sub    $0xc,%esp
f0101a8a:	6a 00                	push   $0x0
f0101a8c:	e8 ad f5 ff ff       	call   f010103e <page_alloc>
f0101a91:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a94:	83 c4 10             	add    $0x10,%esp
f0101a97:	85 c0                	test   %eax,%eax
f0101a99:	0f 84 2d 08 00 00    	je     f01022cc <mem_init+0xe7e>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a9f:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101aa2:	0f 84 43 08 00 00    	je     f01022eb <mem_init+0xe9d>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101aa8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101aab:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101aae:	0f 84 56 08 00 00    	je     f010230a <mem_init+0xebc>
f0101ab4:	39 c7                	cmp    %eax,%edi
f0101ab6:	0f 84 4e 08 00 00    	je     f010230a <mem_init+0xebc>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101abc:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f0101ac2:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	page_free_list = 0;
f0101ac5:	c7 83 94 1f 00 00 00 	movl   $0x0,0x1f94(%ebx)
f0101acc:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101acf:	83 ec 0c             	sub    $0xc,%esp
f0101ad2:	6a 00                	push   $0x0
f0101ad4:	e8 65 f5 ff ff       	call   f010103e <page_alloc>
f0101ad9:	83 c4 10             	add    $0x10,%esp
f0101adc:	85 c0                	test   %eax,%eax
f0101ade:	0f 85 45 08 00 00    	jne    f0102329 <mem_init+0xedb>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101ae4:	83 ec 04             	sub    $0x4,%esp
f0101ae7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101aea:	50                   	push   %eax
f0101aeb:	6a 00                	push   $0x0
f0101aed:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101af3:	ff 30                	pushl  (%eax)
f0101af5:	e8 14 f8 ff ff       	call   f010130e <page_lookup>
f0101afa:	83 c4 10             	add    $0x10,%esp
f0101afd:	85 c0                	test   %eax,%eax
f0101aff:	0f 85 43 08 00 00    	jne    f0102348 <mem_init+0xefa>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101b05:	6a 02                	push   $0x2
f0101b07:	6a 00                	push   $0x0
f0101b09:	57                   	push   %edi
f0101b0a:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b10:	ff 30                	pushl  (%eax)
f0101b12:	e8 a2 f8 ff ff       	call   f01013b9 <page_insert>
f0101b17:	83 c4 10             	add    $0x10,%esp
f0101b1a:	85 c0                	test   %eax,%eax
f0101b1c:	0f 89 45 08 00 00    	jns    f0102367 <mem_init+0xf19>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101b22:	83 ec 0c             	sub    $0xc,%esp
f0101b25:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b28:	e8 99 f5 ff ff       	call   f01010c6 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101b2d:	6a 02                	push   $0x2
f0101b2f:	6a 00                	push   $0x0
f0101b31:	57                   	push   %edi
f0101b32:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b38:	ff 30                	pushl  (%eax)
f0101b3a:	e8 7a f8 ff ff       	call   f01013b9 <page_insert>
f0101b3f:	83 c4 20             	add    $0x20,%esp
f0101b42:	85 c0                	test   %eax,%eax
f0101b44:	0f 85 3c 08 00 00    	jne    f0102386 <mem_init+0xf38>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b4a:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b50:	8b 08                	mov    (%eax),%ecx
f0101b52:	89 ce                	mov    %ecx,%esi
	return (pp - pages) << PGSHIFT;
f0101b54:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101b5a:	8b 00                	mov    (%eax),%eax
f0101b5c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b5f:	8b 09                	mov    (%ecx),%ecx
f0101b61:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0101b64:	89 ca                	mov    %ecx,%edx
f0101b66:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b6c:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101b6f:	29 c1                	sub    %eax,%ecx
f0101b71:	89 c8                	mov    %ecx,%eax
f0101b73:	c1 f8 03             	sar    $0x3,%eax
f0101b76:	c1 e0 0c             	shl    $0xc,%eax
f0101b79:	39 c2                	cmp    %eax,%edx
f0101b7b:	0f 85 24 08 00 00    	jne    f01023a5 <mem_init+0xf57>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b81:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b86:	89 f0                	mov    %esi,%eax
f0101b88:	e8 93 ef ff ff       	call   f0100b20 <check_va2pa>
f0101b8d:	89 fa                	mov    %edi,%edx
f0101b8f:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b92:	c1 fa 03             	sar    $0x3,%edx
f0101b95:	c1 e2 0c             	shl    $0xc,%edx
f0101b98:	39 d0                	cmp    %edx,%eax
f0101b9a:	0f 85 24 08 00 00    	jne    f01023c4 <mem_init+0xf76>
	assert(pp1->pp_ref == 1);
f0101ba0:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101ba5:	0f 85 38 08 00 00    	jne    f01023e3 <mem_init+0xf95>
	assert(pp0->pp_ref == 1);
f0101bab:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bae:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101bb3:	0f 85 49 08 00 00    	jne    f0102402 <mem_init+0xfb4>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bb9:	6a 02                	push   $0x2
f0101bbb:	68 00 10 00 00       	push   $0x1000
f0101bc0:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101bc3:	56                   	push   %esi
f0101bc4:	e8 f0 f7 ff ff       	call   f01013b9 <page_insert>
f0101bc9:	83 c4 10             	add    $0x10,%esp
f0101bcc:	85 c0                	test   %eax,%eax
f0101bce:	0f 85 4d 08 00 00    	jne    f0102421 <mem_init+0xfd3>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bd4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bd9:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101bdf:	8b 00                	mov    (%eax),%eax
f0101be1:	e8 3a ef ff ff       	call   f0100b20 <check_va2pa>
f0101be6:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101bec:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101bef:	2b 0a                	sub    (%edx),%ecx
f0101bf1:	89 ca                	mov    %ecx,%edx
f0101bf3:	c1 fa 03             	sar    $0x3,%edx
f0101bf6:	c1 e2 0c             	shl    $0xc,%edx
f0101bf9:	39 d0                	cmp    %edx,%eax
f0101bfb:	0f 85 3f 08 00 00    	jne    f0102440 <mem_init+0xff2>
	assert(pp2->pp_ref == 1);
f0101c01:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c04:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c09:	0f 85 50 08 00 00    	jne    f010245f <mem_init+0x1011>

	// should be no free memory
	assert(!page_alloc(0));
f0101c0f:	83 ec 0c             	sub    $0xc,%esp
f0101c12:	6a 00                	push   $0x0
f0101c14:	e8 25 f4 ff ff       	call   f010103e <page_alloc>
f0101c19:	83 c4 10             	add    $0x10,%esp
f0101c1c:	85 c0                	test   %eax,%eax
f0101c1e:	0f 85 5a 08 00 00    	jne    f010247e <mem_init+0x1030>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c24:	6a 02                	push   $0x2
f0101c26:	68 00 10 00 00       	push   $0x1000
f0101c2b:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c2e:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c34:	ff 30                	pushl  (%eax)
f0101c36:	e8 7e f7 ff ff       	call   f01013b9 <page_insert>
f0101c3b:	83 c4 10             	add    $0x10,%esp
f0101c3e:	85 c0                	test   %eax,%eax
f0101c40:	0f 85 57 08 00 00    	jne    f010249d <mem_init+0x104f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c46:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c4b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c51:	8b 00                	mov    (%eax),%eax
f0101c53:	e8 c8 ee ff ff       	call   f0100b20 <check_va2pa>
f0101c58:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101c5e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c61:	2b 0a                	sub    (%edx),%ecx
f0101c63:	89 ca                	mov    %ecx,%edx
f0101c65:	c1 fa 03             	sar    $0x3,%edx
f0101c68:	c1 e2 0c             	shl    $0xc,%edx
f0101c6b:	39 d0                	cmp    %edx,%eax
f0101c6d:	0f 85 49 08 00 00    	jne    f01024bc <mem_init+0x106e>
	assert(pp2->pp_ref == 1);
f0101c73:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c76:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c7b:	0f 85 5a 08 00 00    	jne    f01024db <mem_init+0x108d>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c81:	83 ec 0c             	sub    $0xc,%esp
f0101c84:	6a 00                	push   $0x0
f0101c86:	e8 b3 f3 ff ff       	call   f010103e <page_alloc>
f0101c8b:	83 c4 10             	add    $0x10,%esp
f0101c8e:	85 c0                	test   %eax,%eax
f0101c90:	0f 85 64 08 00 00    	jne    f01024fa <mem_init+0x10ac>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c96:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c9c:	8b 10                	mov    (%eax),%edx
f0101c9e:	8b 02                	mov    (%edx),%eax
f0101ca0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101ca5:	89 c1                	mov    %eax,%ecx
f0101ca7:	c1 e9 0c             	shr    $0xc,%ecx
f0101caa:	89 ce                	mov    %ecx,%esi
f0101cac:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0101cb2:	3b 31                	cmp    (%ecx),%esi
f0101cb4:	0f 83 5f 08 00 00    	jae    f0102519 <mem_init+0x10cb>
	return (void *)(pa + KERNBASE);
f0101cba:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101cbf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101cc2:	83 ec 04             	sub    $0x4,%esp
f0101cc5:	6a 00                	push   $0x0
f0101cc7:	68 00 10 00 00       	push   $0x1000
f0101ccc:	52                   	push   %edx
f0101ccd:	e8 8f f4 ff ff       	call   f0101161 <pgdir_walk>
f0101cd2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101cd5:	8d 51 04             	lea    0x4(%ecx),%edx
f0101cd8:	83 c4 10             	add    $0x10,%esp
f0101cdb:	39 d0                	cmp    %edx,%eax
f0101cdd:	0f 85 4f 08 00 00    	jne    f0102532 <mem_init+0x10e4>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101ce3:	6a 06                	push   $0x6
f0101ce5:	68 00 10 00 00       	push   $0x1000
f0101cea:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ced:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101cf3:	ff 30                	pushl  (%eax)
f0101cf5:	e8 bf f6 ff ff       	call   f01013b9 <page_insert>
f0101cfa:	83 c4 10             	add    $0x10,%esp
f0101cfd:	85 c0                	test   %eax,%eax
f0101cff:	0f 85 4c 08 00 00    	jne    f0102551 <mem_init+0x1103>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d05:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d0b:	8b 00                	mov    (%eax),%eax
f0101d0d:	89 c6                	mov    %eax,%esi
f0101d0f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d14:	e8 07 ee ff ff       	call   f0100b20 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101d19:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101d1f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101d22:	2b 0a                	sub    (%edx),%ecx
f0101d24:	89 ca                	mov    %ecx,%edx
f0101d26:	c1 fa 03             	sar    $0x3,%edx
f0101d29:	c1 e2 0c             	shl    $0xc,%edx
f0101d2c:	39 d0                	cmp    %edx,%eax
f0101d2e:	0f 85 3c 08 00 00    	jne    f0102570 <mem_init+0x1122>
	assert(pp2->pp_ref == 1);
f0101d34:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d37:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101d3c:	0f 85 4d 08 00 00    	jne    f010258f <mem_init+0x1141>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d42:	83 ec 04             	sub    $0x4,%esp
f0101d45:	6a 00                	push   $0x0
f0101d47:	68 00 10 00 00       	push   $0x1000
f0101d4c:	56                   	push   %esi
f0101d4d:	e8 0f f4 ff ff       	call   f0101161 <pgdir_walk>
f0101d52:	83 c4 10             	add    $0x10,%esp
f0101d55:	f6 00 04             	testb  $0x4,(%eax)
f0101d58:	0f 84 50 08 00 00    	je     f01025ae <mem_init+0x1160>
	assert(kern_pgdir[0] & PTE_U);
f0101d5e:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d64:	8b 00                	mov    (%eax),%eax
f0101d66:	f6 00 04             	testb  $0x4,(%eax)
f0101d69:	0f 84 5e 08 00 00    	je     f01025cd <mem_init+0x117f>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d6f:	6a 02                	push   $0x2
f0101d71:	68 00 10 00 00       	push   $0x1000
f0101d76:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d79:	50                   	push   %eax
f0101d7a:	e8 3a f6 ff ff       	call   f01013b9 <page_insert>
f0101d7f:	83 c4 10             	add    $0x10,%esp
f0101d82:	85 c0                	test   %eax,%eax
f0101d84:	0f 85 62 08 00 00    	jne    f01025ec <mem_init+0x119e>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d8a:	83 ec 04             	sub    $0x4,%esp
f0101d8d:	6a 00                	push   $0x0
f0101d8f:	68 00 10 00 00       	push   $0x1000
f0101d94:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d9a:	ff 30                	pushl  (%eax)
f0101d9c:	e8 c0 f3 ff ff       	call   f0101161 <pgdir_walk>
f0101da1:	83 c4 10             	add    $0x10,%esp
f0101da4:	f6 00 02             	testb  $0x2,(%eax)
f0101da7:	0f 84 5e 08 00 00    	je     f010260b <mem_init+0x11bd>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dad:	83 ec 04             	sub    $0x4,%esp
f0101db0:	6a 00                	push   $0x0
f0101db2:	68 00 10 00 00       	push   $0x1000
f0101db7:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101dbd:	ff 30                	pushl  (%eax)
f0101dbf:	e8 9d f3 ff ff       	call   f0101161 <pgdir_walk>
f0101dc4:	83 c4 10             	add    $0x10,%esp
f0101dc7:	f6 00 04             	testb  $0x4,(%eax)
f0101dca:	0f 85 5a 08 00 00    	jne    f010262a <mem_init+0x11dc>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101dd0:	6a 02                	push   $0x2
f0101dd2:	68 00 00 40 00       	push   $0x400000
f0101dd7:	ff 75 d0             	pushl  -0x30(%ebp)
f0101dda:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101de0:	ff 30                	pushl  (%eax)
f0101de2:	e8 d2 f5 ff ff       	call   f01013b9 <page_insert>
f0101de7:	83 c4 10             	add    $0x10,%esp
f0101dea:	85 c0                	test   %eax,%eax
f0101dec:	0f 89 57 08 00 00    	jns    f0102649 <mem_init+0x11fb>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101df2:	6a 02                	push   $0x2
f0101df4:	68 00 10 00 00       	push   $0x1000
f0101df9:	57                   	push   %edi
f0101dfa:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101e00:	ff 30                	pushl  (%eax)
f0101e02:	e8 b2 f5 ff ff       	call   f01013b9 <page_insert>
f0101e07:	83 c4 10             	add    $0x10,%esp
f0101e0a:	85 c0                	test   %eax,%eax
f0101e0c:	0f 85 56 08 00 00    	jne    f0102668 <mem_init+0x121a>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e12:	83 ec 04             	sub    $0x4,%esp
f0101e15:	6a 00                	push   $0x0
f0101e17:	68 00 10 00 00       	push   $0x1000
f0101e1c:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101e22:	ff 30                	pushl  (%eax)
f0101e24:	e8 38 f3 ff ff       	call   f0101161 <pgdir_walk>
f0101e29:	83 c4 10             	add    $0x10,%esp
f0101e2c:	f6 00 04             	testb  $0x4,(%eax)
f0101e2f:	0f 85 52 08 00 00    	jne    f0102687 <mem_init+0x1239>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e35:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101e3b:	8b 00                	mov    (%eax),%eax
f0101e3d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e40:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e45:	e8 d6 ec ff ff       	call   f0100b20 <check_va2pa>
f0101e4a:	89 c6                	mov    %eax,%esi
f0101e4c:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101e52:	89 f9                	mov    %edi,%ecx
f0101e54:	2b 08                	sub    (%eax),%ecx
f0101e56:	89 c8                	mov    %ecx,%eax
f0101e58:	c1 f8 03             	sar    $0x3,%eax
f0101e5b:	c1 e0 0c             	shl    $0xc,%eax
f0101e5e:	39 c6                	cmp    %eax,%esi
f0101e60:	0f 85 40 08 00 00    	jne    f01026a6 <mem_init+0x1258>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e66:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e6b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101e6e:	e8 ad ec ff ff       	call   f0100b20 <check_va2pa>
f0101e73:	39 c6                	cmp    %eax,%esi
f0101e75:	0f 85 4a 08 00 00    	jne    f01026c5 <mem_init+0x1277>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e7b:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101e80:	0f 85 5e 08 00 00    	jne    f01026e4 <mem_init+0x1296>
	assert(pp2->pp_ref == 0);
f0101e86:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e89:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e8e:	0f 85 6f 08 00 00    	jne    f0102703 <mem_init+0x12b5>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e94:	83 ec 0c             	sub    $0xc,%esp
f0101e97:	6a 00                	push   $0x0
f0101e99:	e8 a0 f1 ff ff       	call   f010103e <page_alloc>
f0101e9e:	83 c4 10             	add    $0x10,%esp
f0101ea1:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101ea4:	0f 85 78 08 00 00    	jne    f0102722 <mem_init+0x12d4>
f0101eaa:	85 c0                	test   %eax,%eax
f0101eac:	0f 84 70 08 00 00    	je     f0102722 <mem_init+0x12d4>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101eb2:	83 ec 08             	sub    $0x8,%esp
f0101eb5:	6a 00                	push   $0x0
f0101eb7:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ebd:	89 c6                	mov    %eax,%esi
f0101ebf:	ff 30                	pushl  (%eax)
f0101ec1:	e8 b8 f4 ff ff       	call   f010137e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101ec6:	8b 06                	mov    (%esi),%eax
f0101ec8:	89 c6                	mov    %eax,%esi
f0101eca:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ecf:	e8 4c ec ff ff       	call   f0100b20 <check_va2pa>
f0101ed4:	83 c4 10             	add    $0x10,%esp
f0101ed7:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101eda:	0f 85 61 08 00 00    	jne    f0102741 <mem_init+0x12f3>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ee0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ee5:	89 f0                	mov    %esi,%eax
f0101ee7:	e8 34 ec ff ff       	call   f0100b20 <check_va2pa>
f0101eec:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101ef2:	89 f9                	mov    %edi,%ecx
f0101ef4:	2b 0a                	sub    (%edx),%ecx
f0101ef6:	89 ca                	mov    %ecx,%edx
f0101ef8:	c1 fa 03             	sar    $0x3,%edx
f0101efb:	c1 e2 0c             	shl    $0xc,%edx
f0101efe:	39 d0                	cmp    %edx,%eax
f0101f00:	0f 85 5a 08 00 00    	jne    f0102760 <mem_init+0x1312>
	assert(pp1->pp_ref == 1);
f0101f06:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101f0b:	0f 85 6e 08 00 00    	jne    f010277f <mem_init+0x1331>
	assert(pp2->pp_ref == 0);
f0101f11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f14:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101f19:	0f 85 7f 08 00 00    	jne    f010279e <mem_init+0x1350>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f1f:	6a 00                	push   $0x0
f0101f21:	68 00 10 00 00       	push   $0x1000
f0101f26:	57                   	push   %edi
f0101f27:	56                   	push   %esi
f0101f28:	e8 8c f4 ff ff       	call   f01013b9 <page_insert>
f0101f2d:	83 c4 10             	add    $0x10,%esp
f0101f30:	85 c0                	test   %eax,%eax
f0101f32:	0f 85 85 08 00 00    	jne    f01027bd <mem_init+0x136f>
	assert(pp1->pp_ref);
f0101f38:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101f3d:	0f 84 99 08 00 00    	je     f01027dc <mem_init+0x138e>
	assert(pp1->pp_link == NULL);
f0101f43:	83 3f 00             	cmpl   $0x0,(%edi)
f0101f46:	0f 85 af 08 00 00    	jne    f01027fb <mem_init+0x13ad>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101f4c:	83 ec 08             	sub    $0x8,%esp
f0101f4f:	68 00 10 00 00       	push   $0x1000
f0101f54:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101f5a:	89 c6                	mov    %eax,%esi
f0101f5c:	ff 30                	pushl  (%eax)
f0101f5e:	e8 1b f4 ff ff       	call   f010137e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f63:	8b 06                	mov    (%esi),%eax
f0101f65:	89 c6                	mov    %eax,%esi
f0101f67:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f6c:	e8 af eb ff ff       	call   f0100b20 <check_va2pa>
f0101f71:	83 c4 10             	add    $0x10,%esp
f0101f74:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f77:	0f 85 9d 08 00 00    	jne    f010281a <mem_init+0x13cc>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f7d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f82:	89 f0                	mov    %esi,%eax
f0101f84:	e8 97 eb ff ff       	call   f0100b20 <check_va2pa>
f0101f89:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f8c:	0f 85 a7 08 00 00    	jne    f0102839 <mem_init+0x13eb>
	assert(pp1->pp_ref == 0);
f0101f92:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101f97:	0f 85 bb 08 00 00    	jne    f0102858 <mem_init+0x140a>
	assert(pp2->pp_ref == 0);
f0101f9d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fa0:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101fa5:	0f 85 cc 08 00 00    	jne    f0102877 <mem_init+0x1429>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101fab:	83 ec 0c             	sub    $0xc,%esp
f0101fae:	6a 00                	push   $0x0
f0101fb0:	e8 89 f0 ff ff       	call   f010103e <page_alloc>
f0101fb5:	83 c4 10             	add    $0x10,%esp
f0101fb8:	85 c0                	test   %eax,%eax
f0101fba:	0f 84 d6 08 00 00    	je     f0102896 <mem_init+0x1448>
f0101fc0:	39 c7                	cmp    %eax,%edi
f0101fc2:	0f 85 ce 08 00 00    	jne    f0102896 <mem_init+0x1448>

	// should be no free memory
	assert(!page_alloc(0));
f0101fc8:	83 ec 0c             	sub    $0xc,%esp
f0101fcb:	6a 00                	push   $0x0
f0101fcd:	e8 6c f0 ff ff       	call   f010103e <page_alloc>
f0101fd2:	83 c4 10             	add    $0x10,%esp
f0101fd5:	85 c0                	test   %eax,%eax
f0101fd7:	0f 85 d8 08 00 00    	jne    f01028b5 <mem_init+0x1467>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101fdd:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101fe3:	8b 08                	mov    (%eax),%ecx
f0101fe5:	8b 11                	mov    (%ecx),%edx
f0101fe7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101fed:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101ff3:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101ff6:	2b 30                	sub    (%eax),%esi
f0101ff8:	89 f0                	mov    %esi,%eax
f0101ffa:	c1 f8 03             	sar    $0x3,%eax
f0101ffd:	c1 e0 0c             	shl    $0xc,%eax
f0102000:	39 c2                	cmp    %eax,%edx
f0102002:	0f 85 cc 08 00 00    	jne    f01028d4 <mem_init+0x1486>
	kern_pgdir[0] = 0;
f0102008:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010200e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102011:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102016:	0f 85 d7 08 00 00    	jne    f01028f3 <mem_init+0x14a5>
	pp0->pp_ref = 0;
f010201c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010201f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102025:	83 ec 0c             	sub    $0xc,%esp
f0102028:	50                   	push   %eax
f0102029:	e8 98 f0 ff ff       	call   f01010c6 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010202e:	83 c4 0c             	add    $0xc,%esp
f0102031:	6a 01                	push   $0x1
f0102033:	68 00 10 40 00       	push   $0x401000
f0102038:	c7 c6 cc 96 11 f0    	mov    $0xf01196cc,%esi
f010203e:	ff 36                	pushl  (%esi)
f0102040:	e8 1c f1 ff ff       	call   f0101161 <pgdir_walk>
f0102045:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102048:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010204b:	8b 06                	mov    (%esi),%eax
f010204d:	8b 50 04             	mov    0x4(%eax),%edx
f0102050:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0102056:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f010205c:	8b 09                	mov    (%ecx),%ecx
f010205e:	89 d6                	mov    %edx,%esi
f0102060:	c1 ee 0c             	shr    $0xc,%esi
f0102063:	83 c4 10             	add    $0x10,%esp
f0102066:	39 ce                	cmp    %ecx,%esi
f0102068:	0f 83 a4 08 00 00    	jae    f0102912 <mem_init+0x14c4>
	assert(ptep == ptep1 + PTX(va));
f010206e:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102074:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0102077:	0f 85 ae 08 00 00    	jne    f010292b <mem_init+0x14dd>
	kern_pgdir[PDX(va)] = 0;
f010207d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102084:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0102087:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
	return (pp - pages) << PGSHIFT;
f010208d:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102093:	2b 10                	sub    (%eax),%edx
f0102095:	89 d0                	mov    %edx,%eax
f0102097:	c1 f8 03             	sar    $0x3,%eax
f010209a:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010209d:	89 c2                	mov    %eax,%edx
f010209f:	c1 ea 0c             	shr    $0xc,%edx
f01020a2:	39 d1                	cmp    %edx,%ecx
f01020a4:	0f 86 a0 08 00 00    	jbe    f010294a <mem_init+0x14fc>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01020aa:	83 ec 04             	sub    $0x4,%esp
f01020ad:	68 00 10 00 00       	push   $0x1000
f01020b2:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f01020b7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020bc:	50                   	push   %eax
f01020bd:	e8 05 1c 00 00       	call   f0103cc7 <memset>
	page_free(pp0);
f01020c2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01020c5:	89 34 24             	mov    %esi,(%esp)
f01020c8:	e8 f9 ef ff ff       	call   f01010c6 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01020cd:	83 c4 0c             	add    $0xc,%esp
f01020d0:	6a 01                	push   $0x1
f01020d2:	6a 00                	push   $0x0
f01020d4:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f01020da:	ff 30                	pushl  (%eax)
f01020dc:	e8 80 f0 ff ff       	call   f0101161 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f01020e1:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01020e7:	89 f2                	mov    %esi,%edx
f01020e9:	2b 10                	sub    (%eax),%edx
f01020eb:	c1 fa 03             	sar    $0x3,%edx
f01020ee:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01020f1:	89 d1                	mov    %edx,%ecx
f01020f3:	c1 e9 0c             	shr    $0xc,%ecx
f01020f6:	83 c4 10             	add    $0x10,%esp
f01020f9:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f01020ff:	3b 08                	cmp    (%eax),%ecx
f0102101:	0f 83 59 08 00 00    	jae    f0102960 <mem_init+0x1512>
	return (void *)(pa + KERNBASE);
f0102107:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010210d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102110:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
f0102116:	8b 75 d4             	mov    -0x2c(%ebp),%esi
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102119:	f6 00 01             	testb  $0x1,(%eax)
f010211c:	0f 85 54 08 00 00    	jne    f0102976 <mem_init+0x1528>
f0102122:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0102125:	39 d0                	cmp    %edx,%eax
f0102127:	75 f0                	jne    f0102119 <mem_init+0xccb>
	kern_pgdir[0] = 0;
f0102129:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f010212f:	8b 00                	mov    (%eax),%eax
f0102131:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102137:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010213a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102140:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102143:	89 8b 94 1f 00 00    	mov    %ecx,0x1f94(%ebx)

	// free the pages we took
	page_free(pp0);
f0102149:	83 ec 0c             	sub    $0xc,%esp
f010214c:	50                   	push   %eax
f010214d:	e8 74 ef ff ff       	call   f01010c6 <page_free>
	page_free(pp1);
f0102152:	89 3c 24             	mov    %edi,(%esp)
f0102155:	e8 6c ef ff ff       	call   f01010c6 <page_free>
	page_free(pp2);
f010215a:	89 34 24             	mov    %esi,(%esp)
f010215d:	e8 64 ef ff ff       	call   f01010c6 <page_free>

	cprintf("check_page() succeeded!\n");
f0102162:	8d 83 f4 d5 fe ff    	lea    -0x12a0c(%ebx),%eax
f0102168:	89 04 24             	mov    %eax,(%esp)
f010216b:	e8 fb 0f 00 00       	call   f010316b <cprintf>
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U ); // since PTE_P will be handled by function itself
f0102170:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102176:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102178:	83 c4 10             	add    $0x10,%esp
f010217b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102180:	0f 86 0f 08 00 00    	jbe    f0102995 <mem_init+0x1547>
f0102186:	83 ec 08             	sub    $0x8,%esp
f0102189:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f010218b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102190:	50                   	push   %eax
f0102191:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102196:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010219b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f01021a1:	8b 00                	mov    (%eax),%eax
f01021a3:	e8 a7 f0 ff ff       	call   f010124f <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f01021a8:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f01021ae:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01021b1:	83 c4 10             	add    $0x10,%esp
f01021b4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021b9:	0f 86 ef 07 00 00    	jbe    f01029ae <mem_init+0x1560>
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W); //permissions?);
f01021bf:	c7 c6 cc 96 11 f0    	mov    $0xf01196cc,%esi
f01021c5:	83 ec 08             	sub    $0x8,%esp
f01021c8:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f01021ca:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01021cd:	05 00 00 00 10       	add    $0x10000000,%eax
f01021d2:	50                   	push   %eax
f01021d3:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021d8:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021dd:	8b 06                	mov    (%esi),%eax
f01021df:	e8 6b f0 ff ff       	call   f010124f <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff + 1 - KERNBASE, 0, PTE_W);
f01021e4:	83 c4 08             	add    $0x8,%esp
f01021e7:	6a 02                	push   $0x2
f01021e9:	6a 00                	push   $0x0
f01021eb:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01021f0:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021f5:	8b 06                	mov    (%esi),%eax
f01021f7:	e8 53 f0 ff ff       	call   f010124f <boot_map_region>
	pgdir = kern_pgdir;
f01021fc:	8b 36                	mov    (%esi),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021fe:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0102204:	8b 00                	mov    (%eax),%eax
f0102206:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102209:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102210:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102215:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102218:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010221e:	8b 00                	mov    (%eax),%eax
f0102220:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102223:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102226:	05 00 00 00 10       	add    $0x10000000,%eax
f010222b:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f010222e:	bf 00 00 00 00       	mov    $0x0,%edi
f0102233:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0102236:	89 c6                	mov    %eax,%esi
f0102238:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f010223b:	0f 86 c0 07 00 00    	jbe    f0102a01 <mem_init+0x15b3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102241:	8d 97 00 00 00 ef    	lea    -0x11000000(%edi),%edx
f0102247:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010224a:	e8 d1 e8 ff ff       	call   f0100b20 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f010224f:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102256:	0f 86 6b 07 00 00    	jbe    f01029c7 <mem_init+0x1579>
f010225c:	8d 14 37             	lea    (%edi,%esi,1),%edx
f010225f:	39 c2                	cmp    %eax,%edx
f0102261:	0f 85 7b 07 00 00    	jne    f01029e2 <mem_init+0x1594>
	for (i = 0; i < n; i += PGSIZE)
f0102267:	81 c7 00 10 00 00    	add    $0x1000,%edi
f010226d:	eb c9                	jmp    f0102238 <mem_init+0xdea>
	assert(nfree == 0);
f010226f:	8d 83 1d d5 fe ff    	lea    -0x12ae3(%ebx),%eax
f0102275:	50                   	push   %eax
f0102276:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010227c:	50                   	push   %eax
f010227d:	68 96 03 00 00       	push   $0x396
f0102282:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102288:	50                   	push   %eax
f0102289:	e8 0b de ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f010228e:	8d 83 2b d4 fe ff    	lea    -0x12bd5(%ebx),%eax
f0102294:	50                   	push   %eax
f0102295:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010229b:	50                   	push   %eax
f010229c:	68 ef 03 00 00       	push   $0x3ef
f01022a1:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01022a7:	50                   	push   %eax
f01022a8:	e8 ec dd ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01022ad:	8d 83 41 d4 fe ff    	lea    -0x12bbf(%ebx),%eax
f01022b3:	50                   	push   %eax
f01022b4:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01022ba:	50                   	push   %eax
f01022bb:	68 f0 03 00 00       	push   $0x3f0
f01022c0:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01022c6:	50                   	push   %eax
f01022c7:	e8 cd dd ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01022cc:	8d 83 57 d4 fe ff    	lea    -0x12ba9(%ebx),%eax
f01022d2:	50                   	push   %eax
f01022d3:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01022d9:	50                   	push   %eax
f01022da:	68 f1 03 00 00       	push   $0x3f1
f01022df:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01022e5:	50                   	push   %eax
f01022e6:	e8 ae dd ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01022eb:	8d 83 6d d4 fe ff    	lea    -0x12b93(%ebx),%eax
f01022f1:	50                   	push   %eax
f01022f2:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01022f8:	50                   	push   %eax
f01022f9:	68 f4 03 00 00       	push   $0x3f4
f01022fe:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102304:	50                   	push   %eax
f0102305:	e8 8f dd ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010230a:	8d 83 cc d7 fe ff    	lea    -0x12834(%ebx),%eax
f0102310:	50                   	push   %eax
f0102311:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102317:	50                   	push   %eax
f0102318:	68 f5 03 00 00       	push   $0x3f5
f010231d:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102323:	50                   	push   %eax
f0102324:	e8 70 dd ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102329:	8d 83 d6 d4 fe ff    	lea    -0x12b2a(%ebx),%eax
f010232f:	50                   	push   %eax
f0102330:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102336:	50                   	push   %eax
f0102337:	68 fc 03 00 00       	push   $0x3fc
f010233c:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102342:	50                   	push   %eax
f0102343:	e8 51 dd ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102348:	8d 83 0c d8 fe ff    	lea    -0x127f4(%ebx),%eax
f010234e:	50                   	push   %eax
f010234f:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102355:	50                   	push   %eax
f0102356:	68 ff 03 00 00       	push   $0x3ff
f010235b:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102361:	50                   	push   %eax
f0102362:	e8 32 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102367:	8d 83 44 d8 fe ff    	lea    -0x127bc(%ebx),%eax
f010236d:	50                   	push   %eax
f010236e:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102374:	50                   	push   %eax
f0102375:	68 02 04 00 00       	push   $0x402
f010237a:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102380:	50                   	push   %eax
f0102381:	e8 13 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102386:	8d 83 74 d8 fe ff    	lea    -0x1278c(%ebx),%eax
f010238c:	50                   	push   %eax
f010238d:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102393:	50                   	push   %eax
f0102394:	68 06 04 00 00       	push   $0x406
f0102399:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010239f:	50                   	push   %eax
f01023a0:	e8 f4 dc ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01023a5:	8d 83 a4 d8 fe ff    	lea    -0x1275c(%ebx),%eax
f01023ab:	50                   	push   %eax
f01023ac:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01023b2:	50                   	push   %eax
f01023b3:	68 07 04 00 00       	push   $0x407
f01023b8:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01023be:	50                   	push   %eax
f01023bf:	e8 d5 dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01023c4:	8d 83 cc d8 fe ff    	lea    -0x12734(%ebx),%eax
f01023ca:	50                   	push   %eax
f01023cb:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01023d1:	50                   	push   %eax
f01023d2:	68 08 04 00 00       	push   $0x408
f01023d7:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01023dd:	50                   	push   %eax
f01023de:	e8 b6 dc ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01023e3:	8d 83 28 d5 fe ff    	lea    -0x12ad8(%ebx),%eax
f01023e9:	50                   	push   %eax
f01023ea:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01023f0:	50                   	push   %eax
f01023f1:	68 09 04 00 00       	push   $0x409
f01023f6:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01023fc:	50                   	push   %eax
f01023fd:	e8 97 dc ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102402:	8d 83 39 d5 fe ff    	lea    -0x12ac7(%ebx),%eax
f0102408:	50                   	push   %eax
f0102409:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010240f:	50                   	push   %eax
f0102410:	68 0a 04 00 00       	push   $0x40a
f0102415:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010241b:	50                   	push   %eax
f010241c:	e8 78 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102421:	8d 83 fc d8 fe ff    	lea    -0x12704(%ebx),%eax
f0102427:	50                   	push   %eax
f0102428:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010242e:	50                   	push   %eax
f010242f:	68 0d 04 00 00       	push   $0x40d
f0102434:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010243a:	50                   	push   %eax
f010243b:	e8 59 dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102440:	8d 83 38 d9 fe ff    	lea    -0x126c8(%ebx),%eax
f0102446:	50                   	push   %eax
f0102447:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010244d:	50                   	push   %eax
f010244e:	68 0e 04 00 00       	push   $0x40e
f0102453:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102459:	50                   	push   %eax
f010245a:	e8 3a dc ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f010245f:	8d 83 4a d5 fe ff    	lea    -0x12ab6(%ebx),%eax
f0102465:	50                   	push   %eax
f0102466:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010246c:	50                   	push   %eax
f010246d:	68 0f 04 00 00       	push   $0x40f
f0102472:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102478:	50                   	push   %eax
f0102479:	e8 1b dc ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010247e:	8d 83 d6 d4 fe ff    	lea    -0x12b2a(%ebx),%eax
f0102484:	50                   	push   %eax
f0102485:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010248b:	50                   	push   %eax
f010248c:	68 12 04 00 00       	push   $0x412
f0102491:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102497:	50                   	push   %eax
f0102498:	e8 fc db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010249d:	8d 83 fc d8 fe ff    	lea    -0x12704(%ebx),%eax
f01024a3:	50                   	push   %eax
f01024a4:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01024aa:	50                   	push   %eax
f01024ab:	68 15 04 00 00       	push   $0x415
f01024b0:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01024b6:	50                   	push   %eax
f01024b7:	e8 dd db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01024bc:	8d 83 38 d9 fe ff    	lea    -0x126c8(%ebx),%eax
f01024c2:	50                   	push   %eax
f01024c3:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01024c9:	50                   	push   %eax
f01024ca:	68 16 04 00 00       	push   $0x416
f01024cf:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01024d5:	50                   	push   %eax
f01024d6:	e8 be db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01024db:	8d 83 4a d5 fe ff    	lea    -0x12ab6(%ebx),%eax
f01024e1:	50                   	push   %eax
f01024e2:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01024e8:	50                   	push   %eax
f01024e9:	68 17 04 00 00       	push   $0x417
f01024ee:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01024f4:	50                   	push   %eax
f01024f5:	e8 9f db ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01024fa:	8d 83 d6 d4 fe ff    	lea    -0x12b2a(%ebx),%eax
f0102500:	50                   	push   %eax
f0102501:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102507:	50                   	push   %eax
f0102508:	68 1b 04 00 00       	push   $0x41b
f010250d:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102513:	50                   	push   %eax
f0102514:	e8 80 db ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102519:	50                   	push   %eax
f010251a:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f0102520:	50                   	push   %eax
f0102521:	68 1e 04 00 00       	push   $0x41e
f0102526:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010252c:	50                   	push   %eax
f010252d:	e8 67 db ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102532:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
f0102538:	50                   	push   %eax
f0102539:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010253f:	50                   	push   %eax
f0102540:	68 1f 04 00 00       	push   $0x41f
f0102545:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010254b:	50                   	push   %eax
f010254c:	e8 48 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102551:	8d 83 a8 d9 fe ff    	lea    -0x12658(%ebx),%eax
f0102557:	50                   	push   %eax
f0102558:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010255e:	50                   	push   %eax
f010255f:	68 22 04 00 00       	push   $0x422
f0102564:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010256a:	50                   	push   %eax
f010256b:	e8 29 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102570:	8d 83 38 d9 fe ff    	lea    -0x126c8(%ebx),%eax
f0102576:	50                   	push   %eax
f0102577:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010257d:	50                   	push   %eax
f010257e:	68 23 04 00 00       	push   $0x423
f0102583:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102589:	50                   	push   %eax
f010258a:	e8 0a db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f010258f:	8d 83 4a d5 fe ff    	lea    -0x12ab6(%ebx),%eax
f0102595:	50                   	push   %eax
f0102596:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010259c:	50                   	push   %eax
f010259d:	68 24 04 00 00       	push   $0x424
f01025a2:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01025a8:	50                   	push   %eax
f01025a9:	e8 eb da ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01025ae:	8d 83 e8 d9 fe ff    	lea    -0x12618(%ebx),%eax
f01025b4:	50                   	push   %eax
f01025b5:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01025bb:	50                   	push   %eax
f01025bc:	68 25 04 00 00       	push   $0x425
f01025c1:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01025c7:	50                   	push   %eax
f01025c8:	e8 cc da ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01025cd:	8d 83 5b d5 fe ff    	lea    -0x12aa5(%ebx),%eax
f01025d3:	50                   	push   %eax
f01025d4:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01025da:	50                   	push   %eax
f01025db:	68 26 04 00 00       	push   $0x426
f01025e0:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01025e6:	50                   	push   %eax
f01025e7:	e8 ad da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01025ec:	8d 83 fc d8 fe ff    	lea    -0x12704(%ebx),%eax
f01025f2:	50                   	push   %eax
f01025f3:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01025f9:	50                   	push   %eax
f01025fa:	68 29 04 00 00       	push   $0x429
f01025ff:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102605:	50                   	push   %eax
f0102606:	e8 8e da ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010260b:	8d 83 1c da fe ff    	lea    -0x125e4(%ebx),%eax
f0102611:	50                   	push   %eax
f0102612:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102618:	50                   	push   %eax
f0102619:	68 2a 04 00 00       	push   $0x42a
f010261e:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102624:	50                   	push   %eax
f0102625:	e8 6f da ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010262a:	8d 83 50 da fe ff    	lea    -0x125b0(%ebx),%eax
f0102630:	50                   	push   %eax
f0102631:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102637:	50                   	push   %eax
f0102638:	68 2b 04 00 00       	push   $0x42b
f010263d:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102643:	50                   	push   %eax
f0102644:	e8 50 da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102649:	8d 83 88 da fe ff    	lea    -0x12578(%ebx),%eax
f010264f:	50                   	push   %eax
f0102650:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102656:	50                   	push   %eax
f0102657:	68 2e 04 00 00       	push   $0x42e
f010265c:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102662:	50                   	push   %eax
f0102663:	e8 31 da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102668:	8d 83 c0 da fe ff    	lea    -0x12540(%ebx),%eax
f010266e:	50                   	push   %eax
f010266f:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102675:	50                   	push   %eax
f0102676:	68 31 04 00 00       	push   $0x431
f010267b:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102681:	50                   	push   %eax
f0102682:	e8 12 da ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102687:	8d 83 50 da fe ff    	lea    -0x125b0(%ebx),%eax
f010268d:	50                   	push   %eax
f010268e:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102694:	50                   	push   %eax
f0102695:	68 32 04 00 00       	push   $0x432
f010269a:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01026a0:	50                   	push   %eax
f01026a1:	e8 f3 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01026a6:	8d 83 fc da fe ff    	lea    -0x12504(%ebx),%eax
f01026ac:	50                   	push   %eax
f01026ad:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01026b3:	50                   	push   %eax
f01026b4:	68 35 04 00 00       	push   $0x435
f01026b9:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01026bf:	50                   	push   %eax
f01026c0:	e8 d4 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026c5:	8d 83 28 db fe ff    	lea    -0x124d8(%ebx),%eax
f01026cb:	50                   	push   %eax
f01026cc:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01026d2:	50                   	push   %eax
f01026d3:	68 36 04 00 00       	push   $0x436
f01026d8:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01026de:	50                   	push   %eax
f01026df:	e8 b5 d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f01026e4:	8d 83 71 d5 fe ff    	lea    -0x12a8f(%ebx),%eax
f01026ea:	50                   	push   %eax
f01026eb:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01026f1:	50                   	push   %eax
f01026f2:	68 38 04 00 00       	push   $0x438
f01026f7:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01026fd:	50                   	push   %eax
f01026fe:	e8 96 d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102703:	8d 83 82 d5 fe ff    	lea    -0x12a7e(%ebx),%eax
f0102709:	50                   	push   %eax
f010270a:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102710:	50                   	push   %eax
f0102711:	68 39 04 00 00       	push   $0x439
f0102716:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010271c:	50                   	push   %eax
f010271d:	e8 77 d9 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102722:	8d 83 58 db fe ff    	lea    -0x124a8(%ebx),%eax
f0102728:	50                   	push   %eax
f0102729:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010272f:	50                   	push   %eax
f0102730:	68 3c 04 00 00       	push   $0x43c
f0102735:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010273b:	50                   	push   %eax
f010273c:	e8 58 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102741:	8d 83 7c db fe ff    	lea    -0x12484(%ebx),%eax
f0102747:	50                   	push   %eax
f0102748:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010274e:	50                   	push   %eax
f010274f:	68 40 04 00 00       	push   $0x440
f0102754:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010275a:	50                   	push   %eax
f010275b:	e8 39 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102760:	8d 83 28 db fe ff    	lea    -0x124d8(%ebx),%eax
f0102766:	50                   	push   %eax
f0102767:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010276d:	50                   	push   %eax
f010276e:	68 41 04 00 00       	push   $0x441
f0102773:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102779:	50                   	push   %eax
f010277a:	e8 1a d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f010277f:	8d 83 28 d5 fe ff    	lea    -0x12ad8(%ebx),%eax
f0102785:	50                   	push   %eax
f0102786:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010278c:	50                   	push   %eax
f010278d:	68 42 04 00 00       	push   $0x442
f0102792:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102798:	50                   	push   %eax
f0102799:	e8 fb d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f010279e:	8d 83 82 d5 fe ff    	lea    -0x12a7e(%ebx),%eax
f01027a4:	50                   	push   %eax
f01027a5:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01027ab:	50                   	push   %eax
f01027ac:	68 43 04 00 00       	push   $0x443
f01027b1:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01027b7:	50                   	push   %eax
f01027b8:	e8 dc d8 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01027bd:	8d 83 a0 db fe ff    	lea    -0x12460(%ebx),%eax
f01027c3:	50                   	push   %eax
f01027c4:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01027ca:	50                   	push   %eax
f01027cb:	68 46 04 00 00       	push   $0x446
f01027d0:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01027d6:	50                   	push   %eax
f01027d7:	e8 bd d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f01027dc:	8d 83 93 d5 fe ff    	lea    -0x12a6d(%ebx),%eax
f01027e2:	50                   	push   %eax
f01027e3:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01027e9:	50                   	push   %eax
f01027ea:	68 47 04 00 00       	push   $0x447
f01027ef:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01027f5:	50                   	push   %eax
f01027f6:	e8 9e d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f01027fb:	8d 83 9f d5 fe ff    	lea    -0x12a61(%ebx),%eax
f0102801:	50                   	push   %eax
f0102802:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102808:	50                   	push   %eax
f0102809:	68 48 04 00 00       	push   $0x448
f010280e:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102814:	50                   	push   %eax
f0102815:	e8 7f d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010281a:	8d 83 7c db fe ff    	lea    -0x12484(%ebx),%eax
f0102820:	50                   	push   %eax
f0102821:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102827:	50                   	push   %eax
f0102828:	68 4c 04 00 00       	push   $0x44c
f010282d:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102833:	50                   	push   %eax
f0102834:	e8 60 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102839:	8d 83 d8 db fe ff    	lea    -0x12428(%ebx),%eax
f010283f:	50                   	push   %eax
f0102840:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102846:	50                   	push   %eax
f0102847:	68 4d 04 00 00       	push   $0x44d
f010284c:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102852:	50                   	push   %eax
f0102853:	e8 41 d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102858:	8d 83 b4 d5 fe ff    	lea    -0x12a4c(%ebx),%eax
f010285e:	50                   	push   %eax
f010285f:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102865:	50                   	push   %eax
f0102866:	68 4e 04 00 00       	push   $0x44e
f010286b:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102871:	50                   	push   %eax
f0102872:	e8 22 d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102877:	8d 83 82 d5 fe ff    	lea    -0x12a7e(%ebx),%eax
f010287d:	50                   	push   %eax
f010287e:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102884:	50                   	push   %eax
f0102885:	68 4f 04 00 00       	push   $0x44f
f010288a:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102890:	50                   	push   %eax
f0102891:	e8 03 d8 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102896:	8d 83 00 dc fe ff    	lea    -0x12400(%ebx),%eax
f010289c:	50                   	push   %eax
f010289d:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01028a3:	50                   	push   %eax
f01028a4:	68 52 04 00 00       	push   $0x452
f01028a9:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01028af:	50                   	push   %eax
f01028b0:	e8 e4 d7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01028b5:	8d 83 d6 d4 fe ff    	lea    -0x12b2a(%ebx),%eax
f01028bb:	50                   	push   %eax
f01028bc:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01028c2:	50                   	push   %eax
f01028c3:	68 55 04 00 00       	push   $0x455
f01028c8:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01028ce:	50                   	push   %eax
f01028cf:	e8 c5 d7 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01028d4:	8d 83 a4 d8 fe ff    	lea    -0x1275c(%ebx),%eax
f01028da:	50                   	push   %eax
f01028db:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01028e1:	50                   	push   %eax
f01028e2:	68 58 04 00 00       	push   $0x458
f01028e7:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01028ed:	50                   	push   %eax
f01028ee:	e8 a6 d7 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01028f3:	8d 83 39 d5 fe ff    	lea    -0x12ac7(%ebx),%eax
f01028f9:	50                   	push   %eax
f01028fa:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102900:	50                   	push   %eax
f0102901:	68 5a 04 00 00       	push   $0x45a
f0102906:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010290c:	50                   	push   %eax
f010290d:	e8 87 d7 ff ff       	call   f0100099 <_panic>
f0102912:	52                   	push   %edx
f0102913:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f0102919:	50                   	push   %eax
f010291a:	68 61 04 00 00       	push   $0x461
f010291f:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102925:	50                   	push   %eax
f0102926:	e8 6e d7 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010292b:	8d 83 c5 d5 fe ff    	lea    -0x12a3b(%ebx),%eax
f0102931:	50                   	push   %eax
f0102932:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102938:	50                   	push   %eax
f0102939:	68 62 04 00 00       	push   $0x462
f010293e:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102944:	50                   	push   %eax
f0102945:	e8 4f d7 ff ff       	call   f0100099 <_panic>
f010294a:	50                   	push   %eax
f010294b:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f0102951:	50                   	push   %eax
f0102952:	6a 52                	push   $0x52
f0102954:	8d 83 20 d3 fe ff    	lea    -0x12ce0(%ebx),%eax
f010295a:	50                   	push   %eax
f010295b:	e8 39 d7 ff ff       	call   f0100099 <_panic>
f0102960:	52                   	push   %edx
f0102961:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f0102967:	50                   	push   %eax
f0102968:	6a 52                	push   $0x52
f010296a:	8d 83 20 d3 fe ff    	lea    -0x12ce0(%ebx),%eax
f0102970:	50                   	push   %eax
f0102971:	e8 23 d7 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102976:	8d 83 dd d5 fe ff    	lea    -0x12a23(%ebx),%eax
f010297c:	50                   	push   %eax
f010297d:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102983:	50                   	push   %eax
f0102984:	68 6c 04 00 00       	push   $0x46c
f0102989:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010298f:	50                   	push   %eax
f0102990:	e8 04 d7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102995:	50                   	push   %eax
f0102996:	8d 83 a8 d7 fe ff    	lea    -0x12858(%ebx),%eax
f010299c:	50                   	push   %eax
f010299d:	68 e8 00 00 00       	push   $0xe8
f01029a2:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01029a8:	50                   	push   %eax
f01029a9:	e8 eb d6 ff ff       	call   f0100099 <_panic>
f01029ae:	50                   	push   %eax
f01029af:	8d 83 a8 d7 fe ff    	lea    -0x12858(%ebx),%eax
f01029b5:	50                   	push   %eax
f01029b6:	68 f8 00 00 00       	push   $0xf8
f01029bb:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01029c1:	50                   	push   %eax
f01029c2:	e8 d2 d6 ff ff       	call   f0100099 <_panic>
f01029c7:	ff 75 c0             	pushl  -0x40(%ebp)
f01029ca:	8d 83 a8 d7 fe ff    	lea    -0x12858(%ebx),%eax
f01029d0:	50                   	push   %eax
f01029d1:	68 ae 03 00 00       	push   $0x3ae
f01029d6:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01029dc:	50                   	push   %eax
f01029dd:	e8 b7 d6 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01029e2:	8d 83 24 dc fe ff    	lea    -0x123dc(%ebx),%eax
f01029e8:	50                   	push   %eax
f01029e9:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01029ef:	50                   	push   %eax
f01029f0:	68 ae 03 00 00       	push   $0x3ae
f01029f5:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01029fb:	50                   	push   %eax
f01029fc:	e8 98 d6 ff ff       	call   f0100099 <_panic>
f0102a01:	8b 75 d0             	mov    -0x30(%ebp),%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a04:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0102a07:	c1 e0 0c             	shl    $0xc,%eax
f0102a0a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102a0d:	bf 00 00 00 00       	mov    $0x0,%edi
f0102a12:	eb 17                	jmp    f0102a2b <mem_init+0x15dd>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a14:	8d 97 00 00 00 f0    	lea    -0x10000000(%edi),%edx
f0102a1a:	89 f0                	mov    %esi,%eax
f0102a1c:	e8 ff e0 ff ff       	call   f0100b20 <check_va2pa>
f0102a21:	39 c7                	cmp    %eax,%edi
f0102a23:	75 57                	jne    f0102a7c <mem_init+0x162e>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a25:	81 c7 00 10 00 00    	add    $0x1000,%edi
f0102a2b:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0102a2e:	72 e4                	jb     f0102a14 <mem_init+0x15c6>
f0102a30:	bf 00 80 ff ef       	mov    $0xefff8000,%edi
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102a35:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102a38:	05 00 80 00 20       	add    $0x20008000,%eax
f0102a3d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102a40:	89 fa                	mov    %edi,%edx
f0102a42:	89 f0                	mov    %esi,%eax
f0102a44:	e8 d7 e0 ff ff       	call   f0100b20 <check_va2pa>
f0102a49:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102a4c:	8d 14 39             	lea    (%ecx,%edi,1),%edx
f0102a4f:	39 c2                	cmp    %eax,%edx
f0102a51:	75 48                	jne    f0102a9b <mem_init+0x164d>
f0102a53:	81 c7 00 10 00 00    	add    $0x1000,%edi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102a59:	81 ff 00 00 00 f0    	cmp    $0xf0000000,%edi
f0102a5f:	75 df                	jne    f0102a40 <mem_init+0x15f2>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102a61:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102a66:	89 f0                	mov    %esi,%eax
f0102a68:	e8 b3 e0 ff ff       	call   f0100b20 <check_va2pa>
f0102a6d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a70:	75 48                	jne    f0102aba <mem_init+0x166c>
	for (i = 0; i < NPDENTRIES; i++) {
f0102a72:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a77:	e9 86 00 00 00       	jmp    f0102b02 <mem_init+0x16b4>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a7c:	8d 83 58 dc fe ff    	lea    -0x123a8(%ebx),%eax
f0102a82:	50                   	push   %eax
f0102a83:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102a89:	50                   	push   %eax
f0102a8a:	68 b3 03 00 00       	push   $0x3b3
f0102a8f:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102a95:	50                   	push   %eax
f0102a96:	e8 fe d5 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102a9b:	8d 83 80 dc fe ff    	lea    -0x12380(%ebx),%eax
f0102aa1:	50                   	push   %eax
f0102aa2:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102aa8:	50                   	push   %eax
f0102aa9:	68 b7 03 00 00       	push   $0x3b7
f0102aae:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102ab4:	50                   	push   %eax
f0102ab5:	e8 df d5 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102aba:	8d 83 c8 dc fe ff    	lea    -0x12338(%ebx),%eax
f0102ac0:	50                   	push   %eax
f0102ac1:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102ac7:	50                   	push   %eax
f0102ac8:	68 b8 03 00 00       	push   $0x3b8
f0102acd:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102ad3:	50                   	push   %eax
f0102ad4:	e8 c0 d5 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102ad9:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102add:	74 4f                	je     f0102b2e <mem_init+0x16e0>
	for (i = 0; i < NPDENTRIES; i++) {
f0102adf:	83 c0 01             	add    $0x1,%eax
f0102ae2:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102ae7:	0f 87 ab 00 00 00    	ja     f0102b98 <mem_init+0x174a>
		switch (i) {
f0102aed:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102af2:	72 0e                	jb     f0102b02 <mem_init+0x16b4>
f0102af4:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102af9:	76 de                	jbe    f0102ad9 <mem_init+0x168b>
f0102afb:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102b00:	74 d7                	je     f0102ad9 <mem_init+0x168b>
			if (i >= PDX(KERNBASE)) {
f0102b02:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102b07:	77 44                	ja     f0102b4d <mem_init+0x16ff>
				assert(pgdir[i] == 0);
f0102b09:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102b0d:	74 d0                	je     f0102adf <mem_init+0x1691>
f0102b0f:	8d 83 2f d6 fe ff    	lea    -0x129d1(%ebx),%eax
f0102b15:	50                   	push   %eax
f0102b16:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102b1c:	50                   	push   %eax
f0102b1d:	68 c7 03 00 00       	push   $0x3c7
f0102b22:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102b28:	50                   	push   %eax
f0102b29:	e8 6b d5 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102b2e:	8d 83 0d d6 fe ff    	lea    -0x129f3(%ebx),%eax
f0102b34:	50                   	push   %eax
f0102b35:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102b3b:	50                   	push   %eax
f0102b3c:	68 c0 03 00 00       	push   $0x3c0
f0102b41:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102b47:	50                   	push   %eax
f0102b48:	e8 4c d5 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102b4d:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102b50:	f6 c2 01             	test   $0x1,%dl
f0102b53:	74 24                	je     f0102b79 <mem_init+0x172b>
				assert(pgdir[i] & PTE_W);
f0102b55:	f6 c2 02             	test   $0x2,%dl
f0102b58:	75 85                	jne    f0102adf <mem_init+0x1691>
f0102b5a:	8d 83 1e d6 fe ff    	lea    -0x129e2(%ebx),%eax
f0102b60:	50                   	push   %eax
f0102b61:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102b67:	50                   	push   %eax
f0102b68:	68 c5 03 00 00       	push   $0x3c5
f0102b6d:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102b73:	50                   	push   %eax
f0102b74:	e8 20 d5 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102b79:	8d 83 0d d6 fe ff    	lea    -0x129f3(%ebx),%eax
f0102b7f:	50                   	push   %eax
f0102b80:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102b86:	50                   	push   %eax
f0102b87:	68 c4 03 00 00       	push   $0x3c4
f0102b8c:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102b92:	50                   	push   %eax
f0102b93:	e8 01 d5 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102b98:	83 ec 0c             	sub    $0xc,%esp
f0102b9b:	8d 83 f8 dc fe ff    	lea    -0x12308(%ebx),%eax
f0102ba1:	50                   	push   %eax
f0102ba2:	e8 c4 05 00 00       	call   f010316b <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102ba7:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102bad:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102baf:	83 c4 10             	add    $0x10,%esp
f0102bb2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bb7:	0f 86 41 03 00 00    	jbe    f0102efe <mem_init+0x1ab0>
	return (physaddr_t)kva - KERNBASE;
f0102bbd:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102bc2:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102bc5:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bca:	e8 ce df ff ff       	call   f0100b9d <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102bcf:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102bd2:	83 e0 f3             	and    $0xfffffff3,%eax
f0102bd5:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102bda:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102bdd:	83 ec 0c             	sub    $0xc,%esp
f0102be0:	6a 00                	push   $0x0
f0102be2:	e8 57 e4 ff ff       	call   f010103e <page_alloc>
f0102be7:	89 c6                	mov    %eax,%esi
f0102be9:	83 c4 10             	add    $0x10,%esp
f0102bec:	85 c0                	test   %eax,%eax
f0102bee:	0f 84 23 03 00 00    	je     f0102f17 <mem_init+0x1ac9>
	assert((pp1 = page_alloc(0)));
f0102bf4:	83 ec 0c             	sub    $0xc,%esp
f0102bf7:	6a 00                	push   $0x0
f0102bf9:	e8 40 e4 ff ff       	call   f010103e <page_alloc>
f0102bfe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102c01:	83 c4 10             	add    $0x10,%esp
f0102c04:	85 c0                	test   %eax,%eax
f0102c06:	0f 84 2a 03 00 00    	je     f0102f36 <mem_init+0x1ae8>
	assert((pp2 = page_alloc(0)));
f0102c0c:	83 ec 0c             	sub    $0xc,%esp
f0102c0f:	6a 00                	push   $0x0
f0102c11:	e8 28 e4 ff ff       	call   f010103e <page_alloc>
f0102c16:	89 c7                	mov    %eax,%edi
f0102c18:	83 c4 10             	add    $0x10,%esp
f0102c1b:	85 c0                	test   %eax,%eax
f0102c1d:	0f 84 32 03 00 00    	je     f0102f55 <mem_init+0x1b07>
	page_free(pp0);
f0102c23:	83 ec 0c             	sub    $0xc,%esp
f0102c26:	56                   	push   %esi
f0102c27:	e8 9a e4 ff ff       	call   f01010c6 <page_free>
	return (pp - pages) << PGSHIFT;
f0102c2c:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102c32:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102c35:	2b 08                	sub    (%eax),%ecx
f0102c37:	89 c8                	mov    %ecx,%eax
f0102c39:	c1 f8 03             	sar    $0x3,%eax
f0102c3c:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102c3f:	89 c1                	mov    %eax,%ecx
f0102c41:	c1 e9 0c             	shr    $0xc,%ecx
f0102c44:	83 c4 10             	add    $0x10,%esp
f0102c47:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102c4d:	3b 0a                	cmp    (%edx),%ecx
f0102c4f:	0f 83 1f 03 00 00    	jae    f0102f74 <mem_init+0x1b26>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c55:	83 ec 04             	sub    $0x4,%esp
f0102c58:	68 00 10 00 00       	push   $0x1000
f0102c5d:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102c5f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c64:	50                   	push   %eax
f0102c65:	e8 5d 10 00 00       	call   f0103cc7 <memset>
	return (pp - pages) << PGSHIFT;
f0102c6a:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102c70:	89 f9                	mov    %edi,%ecx
f0102c72:	2b 08                	sub    (%eax),%ecx
f0102c74:	89 c8                	mov    %ecx,%eax
f0102c76:	c1 f8 03             	sar    $0x3,%eax
f0102c79:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102c7c:	89 c1                	mov    %eax,%ecx
f0102c7e:	c1 e9 0c             	shr    $0xc,%ecx
f0102c81:	83 c4 10             	add    $0x10,%esp
f0102c84:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102c8a:	3b 0a                	cmp    (%edx),%ecx
f0102c8c:	0f 83 f8 02 00 00    	jae    f0102f8a <mem_init+0x1b3c>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c92:	83 ec 04             	sub    $0x4,%esp
f0102c95:	68 00 10 00 00       	push   $0x1000
f0102c9a:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102c9c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102ca1:	50                   	push   %eax
f0102ca2:	e8 20 10 00 00       	call   f0103cc7 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102ca7:	6a 02                	push   $0x2
f0102ca9:	68 00 10 00 00       	push   $0x1000
f0102cae:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102cb1:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102cb7:	ff 30                	pushl  (%eax)
f0102cb9:	e8 fb e6 ff ff       	call   f01013b9 <page_insert>
	assert(pp1->pp_ref == 1);
f0102cbe:	83 c4 20             	add    $0x20,%esp
f0102cc1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102cc4:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102cc9:	0f 85 d1 02 00 00    	jne    f0102fa0 <mem_init+0x1b52>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ccf:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102cd6:	01 01 01 
f0102cd9:	0f 85 e0 02 00 00    	jne    f0102fbf <mem_init+0x1b71>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102cdf:	6a 02                	push   $0x2
f0102ce1:	68 00 10 00 00       	push   $0x1000
f0102ce6:	57                   	push   %edi
f0102ce7:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102ced:	ff 30                	pushl  (%eax)
f0102cef:	e8 c5 e6 ff ff       	call   f01013b9 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102cf4:	83 c4 10             	add    $0x10,%esp
f0102cf7:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102cfe:	02 02 02 
f0102d01:	0f 85 d7 02 00 00    	jne    f0102fde <mem_init+0x1b90>
	assert(pp2->pp_ref == 1);
f0102d07:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102d0c:	0f 85 eb 02 00 00    	jne    f0102ffd <mem_init+0x1baf>
	assert(pp1->pp_ref == 0);
f0102d12:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d15:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102d1a:	0f 85 fc 02 00 00    	jne    f010301c <mem_init+0x1bce>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d20:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d27:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102d2a:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102d30:	89 f9                	mov    %edi,%ecx
f0102d32:	2b 08                	sub    (%eax),%ecx
f0102d34:	89 c8                	mov    %ecx,%eax
f0102d36:	c1 f8 03             	sar    $0x3,%eax
f0102d39:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102d3c:	89 c1                	mov    %eax,%ecx
f0102d3e:	c1 e9 0c             	shr    $0xc,%ecx
f0102d41:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102d47:	3b 0a                	cmp    (%edx),%ecx
f0102d49:	0f 83 ec 02 00 00    	jae    f010303b <mem_init+0x1bed>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d4f:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102d56:	03 03 03 
f0102d59:	0f 85 f2 02 00 00    	jne    f0103051 <mem_init+0x1c03>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d5f:	83 ec 08             	sub    $0x8,%esp
f0102d62:	68 00 10 00 00       	push   $0x1000
f0102d67:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102d6d:	ff 30                	pushl  (%eax)
f0102d6f:	e8 0a e6 ff ff       	call   f010137e <page_remove>
	assert(pp2->pp_ref == 0);
f0102d74:	83 c4 10             	add    $0x10,%esp
f0102d77:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d7c:	0f 85 ee 02 00 00    	jne    f0103070 <mem_init+0x1c22>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d82:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102d88:	8b 08                	mov    (%eax),%ecx
f0102d8a:	8b 11                	mov    (%ecx),%edx
f0102d8c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102d92:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102d98:	89 f7                	mov    %esi,%edi
f0102d9a:	2b 38                	sub    (%eax),%edi
f0102d9c:	89 f8                	mov    %edi,%eax
f0102d9e:	c1 f8 03             	sar    $0x3,%eax
f0102da1:	c1 e0 0c             	shl    $0xc,%eax
f0102da4:	39 c2                	cmp    %eax,%edx
f0102da6:	0f 85 e3 02 00 00    	jne    f010308f <mem_init+0x1c41>
	kern_pgdir[0] = 0;
f0102dac:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102db2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102db7:	0f 85 f1 02 00 00    	jne    f01030ae <mem_init+0x1c60>
	pp0->pp_ref = 0;
f0102dbd:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102dc3:	83 ec 0c             	sub    $0xc,%esp
f0102dc6:	56                   	push   %esi
f0102dc7:	e8 fa e2 ff ff       	call   f01010c6 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102dcc:	8d 83 8c dd fe ff    	lea    -0x12274(%ebx),%eax
f0102dd2:	89 04 24             	mov    %eax,(%esp)
f0102dd5:	e8 91 03 00 00       	call   f010316b <cprintf>
	cprintf("Page table index at Linear Address 0xffffffff: %d\n", PDX(0xffffffff));        // Top most hex address
f0102dda:	83 c4 08             	add    $0x8,%esp
f0102ddd:	68 ff 03 00 00       	push   $0x3ff
f0102de2:	8d 83 b8 dd fe ff    	lea    -0x12248(%ebx),%eax
f0102de8:	50                   	push   %eax
f0102de9:	e8 7d 03 00 00       	call   f010316b <cprintf>
	cprintf("Page table index at Linear Address 0xffc00000: %d\n", PDX(0xffc00000));        // Last hex address in Page Dir Entry #1023
f0102dee:	83 c4 08             	add    $0x8,%esp
f0102df1:	68 ff 03 00 00       	push   $0x3ff
f0102df6:	8d 83 ec dd fe ff    	lea    -0x12214(%ebx),%eax
f0102dfc:	50                   	push   %eax
f0102dfd:	e8 69 03 00 00       	call   f010316b <cprintf>
	cprintf("Page table index at Linear Address 0xffbfffff: %d\n", PDX(0xffbfffff));        // First hex address in Page Dir Entry #1022
f0102e02:	83 c4 08             	add    $0x8,%esp
f0102e05:	68 fe 03 00 00       	push   $0x3fe
f0102e0a:	8d 83 20 de fe ff    	lea    -0x121e0(%ebx),%eax
f0102e10:	50                   	push   %eax
f0102e11:	e8 55 03 00 00       	call   f010316b <cprintf>
	cprintf("Page table index at Linear Address 0xff800000: %d\n", PDX(0xff800000));        // Last hex address in Page Dir Entry #1022
f0102e16:	83 c4 08             	add    $0x8,%esp
f0102e19:	68 fe 03 00 00       	push   $0x3fe
f0102e1e:	8d 83 54 de fe ff    	lea    -0x121ac(%ebx),%eax
f0102e24:	50                   	push   %eax
f0102e25:	e8 41 03 00 00       	call   f010316b <cprintf>
 	cprintf("Page table index at Linear Address 0xff7fffff: %d\n", PDX(0xff7fffff));        // First hex address in Page Dir Entry #1021
f0102e2a:	83 c4 08             	add    $0x8,%esp
f0102e2d:	68 fd 03 00 00       	push   $0x3fd
f0102e32:	8d 83 88 de fe ff    	lea    -0x12178(%ebx),%eax
f0102e38:	50                   	push   %eax
f0102e39:	e8 2d 03 00 00       	call   f010316b <cprintf>
	cprintf("Page table index at Linear Address 0xf0000000/KERNBASE: %d\n", PDX(KERNBASE)); // Kernbase hex address
f0102e3e:	83 c4 08             	add    $0x8,%esp
f0102e41:	68 c0 03 00 00       	push   $0x3c0
f0102e46:	8d 83 bc de fe ff    	lea    -0x12144(%ebx),%eax
f0102e4c:	50                   	push   %eax
f0102e4d:	e8 19 03 00 00       	call   f010316b <cprintf>
	cprintf("Page table index at Linear Address kern_pgdir: %d\n", PDX(kern_pgdir));        // kern_pgdir hex address
f0102e52:	83 c4 08             	add    $0x8,%esp
f0102e55:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102e5b:	8b 00                	mov    (%eax),%eax
f0102e5d:	c1 e8 16             	shr    $0x16,%eax
f0102e60:	50                   	push   %eax
f0102e61:	8d 83 f8 de fe ff    	lea    -0x12108(%ebx),%eax
f0102e67:	50                   	push   %eax
f0102e68:	e8 fe 02 00 00       	call   f010316b <cprintf>
	cprintf("Page table index at Linear Address MMIOLIM: %d\n", PDX(MMIOLIM));                  
f0102e6d:	83 c4 08             	add    $0x8,%esp
f0102e70:	68 bf 03 00 00       	push   $0x3bf
f0102e75:	8d 83 2c df fe ff    	lea    -0x120d4(%ebx),%eax
f0102e7b:	50                   	push   %eax
f0102e7c:	e8 ea 02 00 00       	call   f010316b <cprintf>
	cprintf("Page table index at Linear Address MMIOBASE: %d\n", PDX(MMIOBASE));                 
f0102e81:	83 c4 08             	add    $0x8,%esp
f0102e84:	68 be 03 00 00       	push   $0x3be
f0102e89:	8d 83 5c df fe ff    	lea    -0x120a4(%ebx),%eax
f0102e8f:	50                   	push   %eax
f0102e90:	e8 d6 02 00 00       	call   f010316b <cprintf>
	cprintf("Page table index at Linear Address UVPT: %d\n", PDX(UVPT));                  
f0102e95:	83 c4 08             	add    $0x8,%esp
f0102e98:	68 bd 03 00 00       	push   $0x3bd
f0102e9d:	8d 83 90 df fe ff    	lea    -0x12070(%ebx),%eax
f0102ea3:	50                   	push   %eax
f0102ea4:	e8 c2 02 00 00       	call   f010316b <cprintf>
	cprintf("Page table index at Linear Address UPAGES: %d\n", PDX(UPAGES));                 
f0102ea9:	83 c4 08             	add    $0x8,%esp
f0102eac:	68 bc 03 00 00       	push   $0x3bc
f0102eb1:	8d 83 c0 df fe ff    	lea    -0x12040(%ebx),%eax
f0102eb7:	50                   	push   %eax
f0102eb8:	e8 ae 02 00 00       	call   f010316b <cprintf>
	cprintf("Page table index at Linear Address KSTACKTOP: %d\n", PDX(KSTACKTOP));   
f0102ebd:	83 c4 08             	add    $0x8,%esp
f0102ec0:	68 c0 03 00 00       	push   $0x3c0
f0102ec5:	8d 83 f0 df fe ff    	lea    -0x12010(%ebx),%eax
f0102ecb:	50                   	push   %eax
f0102ecc:	e8 9a 02 00 00       	call   f010316b <cprintf>
	cprintf("Page table index at Linear Address IOPHYSMEM: %d\n", PDX(IOPHYSMEM));                  
f0102ed1:	83 c4 08             	add    $0x8,%esp
f0102ed4:	6a 00                	push   $0x0
f0102ed6:	8d 83 24 e0 fe ff    	lea    -0x11fdc(%ebx),%eax
f0102edc:	50                   	push   %eax
f0102edd:	e8 89 02 00 00       	call   f010316b <cprintf>
	cprintf("Page table index at Linear Address EXTPHYSMEM: %d\n", PDX(EXTPHYSMEM));
f0102ee2:	83 c4 08             	add    $0x8,%esp
f0102ee5:	6a 00                	push   $0x0
f0102ee7:	8d 83 58 e0 fe ff    	lea    -0x11fa8(%ebx),%eax
f0102eed:	50                   	push   %eax
f0102eee:	e8 78 02 00 00       	call   f010316b <cprintf>
}
f0102ef3:	83 c4 10             	add    $0x10,%esp
f0102ef6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ef9:	5b                   	pop    %ebx
f0102efa:	5e                   	pop    %esi
f0102efb:	5f                   	pop    %edi
f0102efc:	5d                   	pop    %ebp
f0102efd:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102efe:	50                   	push   %eax
f0102eff:	8d 83 a8 d7 fe ff    	lea    -0x12858(%ebx),%eax
f0102f05:	50                   	push   %eax
f0102f06:	68 11 01 00 00       	push   $0x111
f0102f0b:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102f11:	50                   	push   %eax
f0102f12:	e8 82 d1 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102f17:	8d 83 2b d4 fe ff    	lea    -0x12bd5(%ebx),%eax
f0102f1d:	50                   	push   %eax
f0102f1e:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102f24:	50                   	push   %eax
f0102f25:	68 87 04 00 00       	push   $0x487
f0102f2a:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102f30:	50                   	push   %eax
f0102f31:	e8 63 d1 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102f36:	8d 83 41 d4 fe ff    	lea    -0x12bbf(%ebx),%eax
f0102f3c:	50                   	push   %eax
f0102f3d:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102f43:	50                   	push   %eax
f0102f44:	68 88 04 00 00       	push   $0x488
f0102f49:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102f4f:	50                   	push   %eax
f0102f50:	e8 44 d1 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102f55:	8d 83 57 d4 fe ff    	lea    -0x12ba9(%ebx),%eax
f0102f5b:	50                   	push   %eax
f0102f5c:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102f62:	50                   	push   %eax
f0102f63:	68 89 04 00 00       	push   $0x489
f0102f68:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102f6e:	50                   	push   %eax
f0102f6f:	e8 25 d1 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f74:	50                   	push   %eax
f0102f75:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f0102f7b:	50                   	push   %eax
f0102f7c:	6a 52                	push   $0x52
f0102f7e:	8d 83 20 d3 fe ff    	lea    -0x12ce0(%ebx),%eax
f0102f84:	50                   	push   %eax
f0102f85:	e8 0f d1 ff ff       	call   f0100099 <_panic>
f0102f8a:	50                   	push   %eax
f0102f8b:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f0102f91:	50                   	push   %eax
f0102f92:	6a 52                	push   $0x52
f0102f94:	8d 83 20 d3 fe ff    	lea    -0x12ce0(%ebx),%eax
f0102f9a:	50                   	push   %eax
f0102f9b:	e8 f9 d0 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102fa0:	8d 83 28 d5 fe ff    	lea    -0x12ad8(%ebx),%eax
f0102fa6:	50                   	push   %eax
f0102fa7:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102fad:	50                   	push   %eax
f0102fae:	68 8e 04 00 00       	push   $0x48e
f0102fb3:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102fb9:	50                   	push   %eax
f0102fba:	e8 da d0 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102fbf:	8d 83 18 dd fe ff    	lea    -0x122e8(%ebx),%eax
f0102fc5:	50                   	push   %eax
f0102fc6:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102fcc:	50                   	push   %eax
f0102fcd:	68 8f 04 00 00       	push   $0x48f
f0102fd2:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102fd8:	50                   	push   %eax
f0102fd9:	e8 bb d0 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102fde:	8d 83 3c dd fe ff    	lea    -0x122c4(%ebx),%eax
f0102fe4:	50                   	push   %eax
f0102fe5:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0102feb:	50                   	push   %eax
f0102fec:	68 91 04 00 00       	push   $0x491
f0102ff1:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0102ff7:	50                   	push   %eax
f0102ff8:	e8 9c d0 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102ffd:	8d 83 4a d5 fe ff    	lea    -0x12ab6(%ebx),%eax
f0103003:	50                   	push   %eax
f0103004:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010300a:	50                   	push   %eax
f010300b:	68 92 04 00 00       	push   $0x492
f0103010:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0103016:	50                   	push   %eax
f0103017:	e8 7d d0 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f010301c:	8d 83 b4 d5 fe ff    	lea    -0x12a4c(%ebx),%eax
f0103022:	50                   	push   %eax
f0103023:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f0103029:	50                   	push   %eax
f010302a:	68 93 04 00 00       	push   $0x493
f010302f:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0103035:	50                   	push   %eax
f0103036:	e8 5e d0 ff ff       	call   f0100099 <_panic>
f010303b:	50                   	push   %eax
f010303c:	8d 83 40 d6 fe ff    	lea    -0x129c0(%ebx),%eax
f0103042:	50                   	push   %eax
f0103043:	6a 52                	push   $0x52
f0103045:	8d 83 20 d3 fe ff    	lea    -0x12ce0(%ebx),%eax
f010304b:	50                   	push   %eax
f010304c:	e8 48 d0 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0103051:	8d 83 60 dd fe ff    	lea    -0x122a0(%ebx),%eax
f0103057:	50                   	push   %eax
f0103058:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010305e:	50                   	push   %eax
f010305f:	68 95 04 00 00       	push   $0x495
f0103064:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f010306a:	50                   	push   %eax
f010306b:	e8 29 d0 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0103070:	8d 83 82 d5 fe ff    	lea    -0x12a7e(%ebx),%eax
f0103076:	50                   	push   %eax
f0103077:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010307d:	50                   	push   %eax
f010307e:	68 97 04 00 00       	push   $0x497
f0103083:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0103089:	50                   	push   %eax
f010308a:	e8 0a d0 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010308f:	8d 83 a4 d8 fe ff    	lea    -0x1275c(%ebx),%eax
f0103095:	50                   	push   %eax
f0103096:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f010309c:	50                   	push   %eax
f010309d:	68 9a 04 00 00       	push   $0x49a
f01030a2:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01030a8:	50                   	push   %eax
f01030a9:	e8 eb cf ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01030ae:	8d 83 39 d5 fe ff    	lea    -0x12ac7(%ebx),%eax
f01030b4:	50                   	push   %eax
f01030b5:	8d 83 3a d3 fe ff    	lea    -0x12cc6(%ebx),%eax
f01030bb:	50                   	push   %eax
f01030bc:	68 9c 04 00 00       	push   $0x49c
f01030c1:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f01030c7:	50                   	push   %eax
f01030c8:	e8 cc cf ff ff       	call   f0100099 <_panic>

f01030cd <tlb_invalidate>:
{
f01030cd:	55                   	push   %ebp
f01030ce:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01030d0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030d3:	0f 01 38             	invlpg (%eax)
}
f01030d6:	5d                   	pop    %ebp
f01030d7:	c3                   	ret    

f01030d8 <__x86.get_pc_thunk.cx>:
f01030d8:	8b 0c 24             	mov    (%esp),%ecx
f01030db:	c3                   	ret    

f01030dc <__x86.get_pc_thunk.si>:
f01030dc:	8b 34 24             	mov    (%esp),%esi
f01030df:	c3                   	ret    

f01030e0 <__x86.get_pc_thunk.di>:
f01030e0:	8b 3c 24             	mov    (%esp),%edi
f01030e3:	c3                   	ret    

f01030e4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01030e4:	55                   	push   %ebp
f01030e5:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01030e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01030ea:	ba 70 00 00 00       	mov    $0x70,%edx
f01030ef:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01030f0:	ba 71 00 00 00       	mov    $0x71,%edx
f01030f5:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01030f6:	0f b6 c0             	movzbl %al,%eax
}
f01030f9:	5d                   	pop    %ebp
f01030fa:	c3                   	ret    

f01030fb <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01030fb:	55                   	push   %ebp
f01030fc:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01030fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103101:	ba 70 00 00 00       	mov    $0x70,%edx
f0103106:	ee                   	out    %al,(%dx)
f0103107:	8b 45 0c             	mov    0xc(%ebp),%eax
f010310a:	ba 71 00 00 00       	mov    $0x71,%edx
f010310f:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103110:	5d                   	pop    %ebp
f0103111:	c3                   	ret    

f0103112 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103112:	55                   	push   %ebp
f0103113:	89 e5                	mov    %esp,%ebp
f0103115:	53                   	push   %ebx
f0103116:	83 ec 10             	sub    $0x10,%esp
f0103119:	e8 31 d0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010311e:	81 c3 ea 41 01 00    	add    $0x141ea,%ebx
	cputchar(ch);
f0103124:	ff 75 08             	pushl  0x8(%ebp)
f0103127:	e8 9a d5 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f010312c:	83 c4 10             	add    $0x10,%esp
f010312f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103132:	c9                   	leave  
f0103133:	c3                   	ret    

f0103134 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103134:	55                   	push   %ebp
f0103135:	89 e5                	mov    %esp,%ebp
f0103137:	53                   	push   %ebx
f0103138:	83 ec 14             	sub    $0x14,%esp
f010313b:	e8 0f d0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103140:	81 c3 c8 41 01 00    	add    $0x141c8,%ebx
	int cnt = 0;
f0103146:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010314d:	ff 75 0c             	pushl  0xc(%ebp)
f0103150:	ff 75 08             	pushl  0x8(%ebp)
f0103153:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103156:	50                   	push   %eax
f0103157:	8d 83 0a be fe ff    	lea    -0x141f6(%ebx),%eax
f010315d:	50                   	push   %eax
f010315e:	e8 18 04 00 00       	call   f010357b <vprintfmt>
	return cnt;
}
f0103163:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103166:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103169:	c9                   	leave  
f010316a:	c3                   	ret    

f010316b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010316b:	55                   	push   %ebp
f010316c:	89 e5                	mov    %esp,%ebp
f010316e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103171:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103174:	50                   	push   %eax
f0103175:	ff 75 08             	pushl  0x8(%ebp)
f0103178:	e8 b7 ff ff ff       	call   f0103134 <vcprintf>
	va_end(ap);

	return cnt;
}
f010317d:	c9                   	leave  
f010317e:	c3                   	ret    

f010317f <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010317f:	55                   	push   %ebp
f0103180:	89 e5                	mov    %esp,%ebp
f0103182:	57                   	push   %edi
f0103183:	56                   	push   %esi
f0103184:	53                   	push   %ebx
f0103185:	83 ec 14             	sub    $0x14,%esp
f0103188:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010318b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010318e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103191:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103194:	8b 32                	mov    (%edx),%esi
f0103196:	8b 01                	mov    (%ecx),%eax
f0103198:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010319b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01031a2:	eb 2f                	jmp    f01031d3 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01031a4:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f01031a7:	39 c6                	cmp    %eax,%esi
f01031a9:	7f 49                	jg     f01031f4 <stab_binsearch+0x75>
f01031ab:	0f b6 0a             	movzbl (%edx),%ecx
f01031ae:	83 ea 0c             	sub    $0xc,%edx
f01031b1:	39 f9                	cmp    %edi,%ecx
f01031b3:	75 ef                	jne    f01031a4 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01031b5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01031b8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01031bb:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01031bf:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01031c2:	73 35                	jae    f01031f9 <stab_binsearch+0x7a>
			*region_left = m;
f01031c4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031c7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f01031c9:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f01031cc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01031d3:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f01031d6:	7f 4e                	jg     f0103226 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f01031d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01031db:	01 f0                	add    %esi,%eax
f01031dd:	89 c3                	mov    %eax,%ebx
f01031df:	c1 eb 1f             	shr    $0x1f,%ebx
f01031e2:	01 c3                	add    %eax,%ebx
f01031e4:	d1 fb                	sar    %ebx
f01031e6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01031e9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01031ec:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01031f0:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f01031f2:	eb b3                	jmp    f01031a7 <stab_binsearch+0x28>
			l = true_m + 1;
f01031f4:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f01031f7:	eb da                	jmp    f01031d3 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f01031f9:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01031fc:	76 14                	jbe    f0103212 <stab_binsearch+0x93>
			*region_right = m - 1;
f01031fe:	83 e8 01             	sub    $0x1,%eax
f0103201:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103204:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103207:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0103209:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103210:	eb c1                	jmp    f01031d3 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103212:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103215:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103217:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010321b:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f010321d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103224:	eb ad                	jmp    f01031d3 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0103226:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010322a:	74 16                	je     f0103242 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010322c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010322f:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103231:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103234:	8b 0e                	mov    (%esi),%ecx
f0103236:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103239:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010323c:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0103240:	eb 12                	jmp    f0103254 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0103242:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103245:	8b 00                	mov    (%eax),%eax
f0103247:	83 e8 01             	sub    $0x1,%eax
f010324a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010324d:	89 07                	mov    %eax,(%edi)
f010324f:	eb 16                	jmp    f0103267 <stab_binsearch+0xe8>
		     l--)
f0103251:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0103254:	39 c1                	cmp    %eax,%ecx
f0103256:	7d 0a                	jge    f0103262 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0103258:	0f b6 1a             	movzbl (%edx),%ebx
f010325b:	83 ea 0c             	sub    $0xc,%edx
f010325e:	39 fb                	cmp    %edi,%ebx
f0103260:	75 ef                	jne    f0103251 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0103262:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103265:	89 07                	mov    %eax,(%edi)
	}
}
f0103267:	83 c4 14             	add    $0x14,%esp
f010326a:	5b                   	pop    %ebx
f010326b:	5e                   	pop    %esi
f010326c:	5f                   	pop    %edi
f010326d:	5d                   	pop    %ebp
f010326e:	c3                   	ret    

f010326f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010326f:	55                   	push   %ebp
f0103270:	89 e5                	mov    %esp,%ebp
f0103272:	57                   	push   %edi
f0103273:	56                   	push   %esi
f0103274:	53                   	push   %ebx
f0103275:	83 ec 2c             	sub    $0x2c,%esp
f0103278:	e8 5b fe ff ff       	call   f01030d8 <__x86.get_pc_thunk.cx>
f010327d:	81 c1 8b 40 01 00    	add    $0x1408b,%ecx
f0103283:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0103286:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103289:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010328c:	8d 81 8c e0 fe ff    	lea    -0x11f74(%ecx),%eax
f0103292:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0103294:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f010329b:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f010329e:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f01032a5:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f01032a8:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01032af:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01032b5:	0f 86 f4 00 00 00    	jbe    f01033af <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01032bb:	c7 c0 f1 bf 10 f0    	mov    $0xf010bff1,%eax
f01032c1:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f01032c7:	0f 86 88 01 00 00    	jbe    f0103455 <debuginfo_eip+0x1e6>
f01032cd:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01032d0:	c7 c0 c4 de 10 f0    	mov    $0xf010dec4,%eax
f01032d6:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01032da:	0f 85 7c 01 00 00    	jne    f010345c <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01032e0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01032e7:	c7 c0 ac 55 10 f0    	mov    $0xf01055ac,%eax
f01032ed:	c7 c2 f0 bf 10 f0    	mov    $0xf010bff0,%edx
f01032f3:	29 c2                	sub    %eax,%edx
f01032f5:	c1 fa 02             	sar    $0x2,%edx
f01032f8:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01032fe:	83 ea 01             	sub    $0x1,%edx
f0103301:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103304:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103307:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010330a:	83 ec 08             	sub    $0x8,%esp
f010330d:	53                   	push   %ebx
f010330e:	6a 64                	push   $0x64
f0103310:	e8 6a fe ff ff       	call   f010317f <stab_binsearch>
	if (lfile == 0)
f0103315:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103318:	83 c4 10             	add    $0x10,%esp
f010331b:	85 c0                	test   %eax,%eax
f010331d:	0f 84 40 01 00 00    	je     f0103463 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103323:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103326:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103329:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010332c:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010332f:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103332:	83 ec 08             	sub    $0x8,%esp
f0103335:	53                   	push   %ebx
f0103336:	6a 24                	push   $0x24
f0103338:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010333b:	c7 c0 ac 55 10 f0    	mov    $0xf01055ac,%eax
f0103341:	e8 39 fe ff ff       	call   f010317f <stab_binsearch>

	if (lfun <= rfun) {
f0103346:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103349:	83 c4 10             	add    $0x10,%esp
f010334c:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f010334f:	7f 79                	jg     f01033ca <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103351:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103354:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103357:	c7 c2 ac 55 10 f0    	mov    $0xf01055ac,%edx
f010335d:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0103360:	8b 11                	mov    (%ecx),%edx
f0103362:	c7 c0 c4 de 10 f0    	mov    $0xf010dec4,%eax
f0103368:	81 e8 f1 bf 10 f0    	sub    $0xf010bff1,%eax
f010336e:	39 c2                	cmp    %eax,%edx
f0103370:	73 09                	jae    f010337b <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103372:	81 c2 f1 bf 10 f0    	add    $0xf010bff1,%edx
f0103378:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010337b:	8b 41 08             	mov    0x8(%ecx),%eax
f010337e:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103381:	83 ec 08             	sub    $0x8,%esp
f0103384:	6a 3a                	push   $0x3a
f0103386:	ff 77 08             	pushl  0x8(%edi)
f0103389:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010338c:	e8 1a 09 00 00       	call   f0103cab <strfind>
f0103391:	2b 47 08             	sub    0x8(%edi),%eax
f0103394:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103397:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010339a:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010339d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01033a0:	c7 c2 ac 55 10 f0    	mov    $0xf01055ac,%edx
f01033a6:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f01033aa:	83 c4 10             	add    $0x10,%esp
f01033ad:	eb 29                	jmp    f01033d8 <debuginfo_eip+0x169>
  	        panic("User address");
f01033af:	83 ec 04             	sub    $0x4,%esp
f01033b2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01033b5:	8d 83 96 e0 fe ff    	lea    -0x11f6a(%ebx),%eax
f01033bb:	50                   	push   %eax
f01033bc:	6a 7f                	push   $0x7f
f01033be:	8d 83 a3 e0 fe ff    	lea    -0x11f5d(%ebx),%eax
f01033c4:	50                   	push   %eax
f01033c5:	e8 cf cc ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f01033ca:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f01033cd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01033d0:	eb af                	jmp    f0103381 <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01033d2:	83 ee 01             	sub    $0x1,%esi
f01033d5:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f01033d8:	39 f3                	cmp    %esi,%ebx
f01033da:	7f 3a                	jg     f0103416 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f01033dc:	0f b6 10             	movzbl (%eax),%edx
f01033df:	80 fa 84             	cmp    $0x84,%dl
f01033e2:	74 0b                	je     f01033ef <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01033e4:	80 fa 64             	cmp    $0x64,%dl
f01033e7:	75 e9                	jne    f01033d2 <debuginfo_eip+0x163>
f01033e9:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f01033ed:	74 e3                	je     f01033d2 <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01033ef:	8d 14 76             	lea    (%esi,%esi,2),%edx
f01033f2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01033f5:	c7 c0 ac 55 10 f0    	mov    $0xf01055ac,%eax
f01033fb:	8b 14 90             	mov    (%eax,%edx,4),%edx
f01033fe:	c7 c0 c4 de 10 f0    	mov    $0xf010dec4,%eax
f0103404:	81 e8 f1 bf 10 f0    	sub    $0xf010bff1,%eax
f010340a:	39 c2                	cmp    %eax,%edx
f010340c:	73 08                	jae    f0103416 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010340e:	81 c2 f1 bf 10 f0    	add    $0xf010bff1,%edx
f0103414:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103416:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103419:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010341c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0103421:	39 cb                	cmp    %ecx,%ebx
f0103423:	7d 4a                	jge    f010346f <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0103425:	8d 53 01             	lea    0x1(%ebx),%edx
f0103428:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f010342b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010342e:	c7 c0 ac 55 10 f0    	mov    $0xf01055ac,%eax
f0103434:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0103438:	eb 07                	jmp    f0103441 <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f010343a:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f010343e:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0103441:	39 d1                	cmp    %edx,%ecx
f0103443:	74 25                	je     f010346a <debuginfo_eip+0x1fb>
f0103445:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103448:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f010344c:	74 ec                	je     f010343a <debuginfo_eip+0x1cb>
	return 0;
f010344e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103453:	eb 1a                	jmp    f010346f <debuginfo_eip+0x200>
		return -1;
f0103455:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010345a:	eb 13                	jmp    f010346f <debuginfo_eip+0x200>
f010345c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103461:	eb 0c                	jmp    f010346f <debuginfo_eip+0x200>
		return -1;
f0103463:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103468:	eb 05                	jmp    f010346f <debuginfo_eip+0x200>
	return 0;
f010346a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010346f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103472:	5b                   	pop    %ebx
f0103473:	5e                   	pop    %esi
f0103474:	5f                   	pop    %edi
f0103475:	5d                   	pop    %ebp
f0103476:	c3                   	ret    

f0103477 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103477:	55                   	push   %ebp
f0103478:	89 e5                	mov    %esp,%ebp
f010347a:	57                   	push   %edi
f010347b:	56                   	push   %esi
f010347c:	53                   	push   %ebx
f010347d:	83 ec 2c             	sub    $0x2c,%esp
f0103480:	e8 53 fc ff ff       	call   f01030d8 <__x86.get_pc_thunk.cx>
f0103485:	81 c1 83 3e 01 00    	add    $0x13e83,%ecx
f010348b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010348e:	89 c7                	mov    %eax,%edi
f0103490:	89 d6                	mov    %edx,%esi
f0103492:	8b 45 08             	mov    0x8(%ebp),%eax
f0103495:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103498:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010349b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010349e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01034a1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01034a6:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f01034a9:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01034ac:	39 d3                	cmp    %edx,%ebx
f01034ae:	72 09                	jb     f01034b9 <printnum+0x42>
f01034b0:	39 45 10             	cmp    %eax,0x10(%ebp)
f01034b3:	0f 87 83 00 00 00    	ja     f010353c <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01034b9:	83 ec 0c             	sub    $0xc,%esp
f01034bc:	ff 75 18             	pushl  0x18(%ebp)
f01034bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01034c2:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01034c5:	53                   	push   %ebx
f01034c6:	ff 75 10             	pushl  0x10(%ebp)
f01034c9:	83 ec 08             	sub    $0x8,%esp
f01034cc:	ff 75 dc             	pushl  -0x24(%ebp)
f01034cf:	ff 75 d8             	pushl  -0x28(%ebp)
f01034d2:	ff 75 d4             	pushl  -0x2c(%ebp)
f01034d5:	ff 75 d0             	pushl  -0x30(%ebp)
f01034d8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01034db:	e8 f0 09 00 00       	call   f0103ed0 <__udivdi3>
f01034e0:	83 c4 18             	add    $0x18,%esp
f01034e3:	52                   	push   %edx
f01034e4:	50                   	push   %eax
f01034e5:	89 f2                	mov    %esi,%edx
f01034e7:	89 f8                	mov    %edi,%eax
f01034e9:	e8 89 ff ff ff       	call   f0103477 <printnum>
f01034ee:	83 c4 20             	add    $0x20,%esp
f01034f1:	eb 13                	jmp    f0103506 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01034f3:	83 ec 08             	sub    $0x8,%esp
f01034f6:	56                   	push   %esi
f01034f7:	ff 75 18             	pushl  0x18(%ebp)
f01034fa:	ff d7                	call   *%edi
f01034fc:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f01034ff:	83 eb 01             	sub    $0x1,%ebx
f0103502:	85 db                	test   %ebx,%ebx
f0103504:	7f ed                	jg     f01034f3 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103506:	83 ec 08             	sub    $0x8,%esp
f0103509:	56                   	push   %esi
f010350a:	83 ec 04             	sub    $0x4,%esp
f010350d:	ff 75 dc             	pushl  -0x24(%ebp)
f0103510:	ff 75 d8             	pushl  -0x28(%ebp)
f0103513:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103516:	ff 75 d0             	pushl  -0x30(%ebp)
f0103519:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010351c:	89 f3                	mov    %esi,%ebx
f010351e:	e8 cd 0a 00 00       	call   f0103ff0 <__umoddi3>
f0103523:	83 c4 14             	add    $0x14,%esp
f0103526:	0f be 84 06 b1 e0 fe 	movsbl -0x11f4f(%esi,%eax,1),%eax
f010352d:	ff 
f010352e:	50                   	push   %eax
f010352f:	ff d7                	call   *%edi
}
f0103531:	83 c4 10             	add    $0x10,%esp
f0103534:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103537:	5b                   	pop    %ebx
f0103538:	5e                   	pop    %esi
f0103539:	5f                   	pop    %edi
f010353a:	5d                   	pop    %ebp
f010353b:	c3                   	ret    
f010353c:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010353f:	eb be                	jmp    f01034ff <printnum+0x88>

f0103541 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103541:	55                   	push   %ebp
f0103542:	89 e5                	mov    %esp,%ebp
f0103544:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103547:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010354b:	8b 10                	mov    (%eax),%edx
f010354d:	3b 50 04             	cmp    0x4(%eax),%edx
f0103550:	73 0a                	jae    f010355c <sprintputch+0x1b>
		*b->buf++ = ch;
f0103552:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103555:	89 08                	mov    %ecx,(%eax)
f0103557:	8b 45 08             	mov    0x8(%ebp),%eax
f010355a:	88 02                	mov    %al,(%edx)
}
f010355c:	5d                   	pop    %ebp
f010355d:	c3                   	ret    

f010355e <printfmt>:
{
f010355e:	55                   	push   %ebp
f010355f:	89 e5                	mov    %esp,%ebp
f0103561:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0103564:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103567:	50                   	push   %eax
f0103568:	ff 75 10             	pushl  0x10(%ebp)
f010356b:	ff 75 0c             	pushl  0xc(%ebp)
f010356e:	ff 75 08             	pushl  0x8(%ebp)
f0103571:	e8 05 00 00 00       	call   f010357b <vprintfmt>
}
f0103576:	83 c4 10             	add    $0x10,%esp
f0103579:	c9                   	leave  
f010357a:	c3                   	ret    

f010357b <vprintfmt>:
{
f010357b:	55                   	push   %ebp
f010357c:	89 e5                	mov    %esp,%ebp
f010357e:	57                   	push   %edi
f010357f:	56                   	push   %esi
f0103580:	53                   	push   %ebx
f0103581:	83 ec 2c             	sub    $0x2c,%esp
f0103584:	e8 c6 cb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103589:	81 c3 7f 3d 01 00    	add    $0x13d7f,%ebx
f010358f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103592:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103595:	e9 8e 03 00 00       	jmp    f0103928 <.L35+0x48>
		padc = ' ';
f010359a:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f010359e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01035a5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f01035ac:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01035b3:	b9 00 00 00 00       	mov    $0x0,%ecx
f01035b8:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01035bb:	8d 47 01             	lea    0x1(%edi),%eax
f01035be:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01035c1:	0f b6 17             	movzbl (%edi),%edx
f01035c4:	8d 42 dd             	lea    -0x23(%edx),%eax
f01035c7:	3c 55                	cmp    $0x55,%al
f01035c9:	0f 87 e1 03 00 00    	ja     f01039b0 <.L22>
f01035cf:	0f b6 c0             	movzbl %al,%eax
f01035d2:	89 d9                	mov    %ebx,%ecx
f01035d4:	03 8c 83 3c e1 fe ff 	add    -0x11ec4(%ebx,%eax,4),%ecx
f01035db:	ff e1                	jmp    *%ecx

f01035dd <.L67>:
f01035dd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01035e0:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01035e4:	eb d5                	jmp    f01035bb <vprintfmt+0x40>

f01035e6 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f01035e6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f01035e9:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01035ed:	eb cc                	jmp    f01035bb <vprintfmt+0x40>

f01035ef <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f01035ef:	0f b6 d2             	movzbl %dl,%edx
f01035f2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f01035f5:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f01035fa:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01035fd:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103601:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103604:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103607:	83 f9 09             	cmp    $0x9,%ecx
f010360a:	77 55                	ja     f0103661 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f010360c:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010360f:	eb e9                	jmp    f01035fa <.L29+0xb>

f0103611 <.L26>:
			precision = va_arg(ap, int);
f0103611:	8b 45 14             	mov    0x14(%ebp),%eax
f0103614:	8b 00                	mov    (%eax),%eax
f0103616:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103619:	8b 45 14             	mov    0x14(%ebp),%eax
f010361c:	8d 40 04             	lea    0x4(%eax),%eax
f010361f:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103622:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0103625:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103629:	79 90                	jns    f01035bb <vprintfmt+0x40>
				width = precision, precision = -1;
f010362b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010362e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103631:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103638:	eb 81                	jmp    f01035bb <vprintfmt+0x40>

f010363a <.L27>:
f010363a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010363d:	85 c0                	test   %eax,%eax
f010363f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103644:	0f 49 d0             	cmovns %eax,%edx
f0103647:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010364a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010364d:	e9 69 ff ff ff       	jmp    f01035bb <vprintfmt+0x40>

f0103652 <.L23>:
f0103652:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0103655:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010365c:	e9 5a ff ff ff       	jmp    f01035bb <vprintfmt+0x40>
f0103661:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103664:	eb bf                	jmp    f0103625 <.L26+0x14>

f0103666 <.L33>:
			lflag++;
f0103666:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010366a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010366d:	e9 49 ff ff ff       	jmp    f01035bb <vprintfmt+0x40>

f0103672 <.L30>:
			putch(va_arg(ap, int), putdat);
f0103672:	8b 45 14             	mov    0x14(%ebp),%eax
f0103675:	8d 78 04             	lea    0x4(%eax),%edi
f0103678:	83 ec 08             	sub    $0x8,%esp
f010367b:	56                   	push   %esi
f010367c:	ff 30                	pushl  (%eax)
f010367e:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103681:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103684:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0103687:	e9 99 02 00 00       	jmp    f0103925 <.L35+0x45>

f010368c <.L32>:
			err = va_arg(ap, int);
f010368c:	8b 45 14             	mov    0x14(%ebp),%eax
f010368f:	8d 78 04             	lea    0x4(%eax),%edi
f0103692:	8b 00                	mov    (%eax),%eax
f0103694:	99                   	cltd   
f0103695:	31 d0                	xor    %edx,%eax
f0103697:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103699:	83 f8 06             	cmp    $0x6,%eax
f010369c:	7f 27                	jg     f01036c5 <.L32+0x39>
f010369e:	8b 94 83 3c 1d 00 00 	mov    0x1d3c(%ebx,%eax,4),%edx
f01036a5:	85 d2                	test   %edx,%edx
f01036a7:	74 1c                	je     f01036c5 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01036a9:	52                   	push   %edx
f01036aa:	8d 83 4c d3 fe ff    	lea    -0x12cb4(%ebx),%eax
f01036b0:	50                   	push   %eax
f01036b1:	56                   	push   %esi
f01036b2:	ff 75 08             	pushl  0x8(%ebp)
f01036b5:	e8 a4 fe ff ff       	call   f010355e <printfmt>
f01036ba:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01036bd:	89 7d 14             	mov    %edi,0x14(%ebp)
f01036c0:	e9 60 02 00 00       	jmp    f0103925 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f01036c5:	50                   	push   %eax
f01036c6:	8d 83 c9 e0 fe ff    	lea    -0x11f37(%ebx),%eax
f01036cc:	50                   	push   %eax
f01036cd:	56                   	push   %esi
f01036ce:	ff 75 08             	pushl  0x8(%ebp)
f01036d1:	e8 88 fe ff ff       	call   f010355e <printfmt>
f01036d6:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01036d9:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01036dc:	e9 44 02 00 00       	jmp    f0103925 <.L35+0x45>

f01036e1 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f01036e1:	8b 45 14             	mov    0x14(%ebp),%eax
f01036e4:	83 c0 04             	add    $0x4,%eax
f01036e7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01036ea:	8b 45 14             	mov    0x14(%ebp),%eax
f01036ed:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01036ef:	85 ff                	test   %edi,%edi
f01036f1:	8d 83 c2 e0 fe ff    	lea    -0x11f3e(%ebx),%eax
f01036f7:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01036fa:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01036fe:	0f 8e b5 00 00 00    	jle    f01037b9 <.L36+0xd8>
f0103704:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103708:	75 08                	jne    f0103712 <.L36+0x31>
f010370a:	89 75 0c             	mov    %esi,0xc(%ebp)
f010370d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103710:	eb 6d                	jmp    f010377f <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103712:	83 ec 08             	sub    $0x8,%esp
f0103715:	ff 75 d0             	pushl  -0x30(%ebp)
f0103718:	57                   	push   %edi
f0103719:	e8 49 04 00 00       	call   f0103b67 <strnlen>
f010371e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103721:	29 c2                	sub    %eax,%edx
f0103723:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0103726:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103729:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010372d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103730:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103733:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103735:	eb 10                	jmp    f0103747 <.L36+0x66>
					putch(padc, putdat);
f0103737:	83 ec 08             	sub    $0x8,%esp
f010373a:	56                   	push   %esi
f010373b:	ff 75 e0             	pushl  -0x20(%ebp)
f010373e:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0103741:	83 ef 01             	sub    $0x1,%edi
f0103744:	83 c4 10             	add    $0x10,%esp
f0103747:	85 ff                	test   %edi,%edi
f0103749:	7f ec                	jg     f0103737 <.L36+0x56>
f010374b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010374e:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0103751:	85 d2                	test   %edx,%edx
f0103753:	b8 00 00 00 00       	mov    $0x0,%eax
f0103758:	0f 49 c2             	cmovns %edx,%eax
f010375b:	29 c2                	sub    %eax,%edx
f010375d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0103760:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103763:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103766:	eb 17                	jmp    f010377f <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0103768:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010376c:	75 30                	jne    f010379e <.L36+0xbd>
					putch(ch, putdat);
f010376e:	83 ec 08             	sub    $0x8,%esp
f0103771:	ff 75 0c             	pushl  0xc(%ebp)
f0103774:	50                   	push   %eax
f0103775:	ff 55 08             	call   *0x8(%ebp)
f0103778:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010377b:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f010377f:	83 c7 01             	add    $0x1,%edi
f0103782:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0103786:	0f be c2             	movsbl %dl,%eax
f0103789:	85 c0                	test   %eax,%eax
f010378b:	74 52                	je     f01037df <.L36+0xfe>
f010378d:	85 f6                	test   %esi,%esi
f010378f:	78 d7                	js     f0103768 <.L36+0x87>
f0103791:	83 ee 01             	sub    $0x1,%esi
f0103794:	79 d2                	jns    f0103768 <.L36+0x87>
f0103796:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103799:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010379c:	eb 32                	jmp    f01037d0 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f010379e:	0f be d2             	movsbl %dl,%edx
f01037a1:	83 ea 20             	sub    $0x20,%edx
f01037a4:	83 fa 5e             	cmp    $0x5e,%edx
f01037a7:	76 c5                	jbe    f010376e <.L36+0x8d>
					putch('?', putdat);
f01037a9:	83 ec 08             	sub    $0x8,%esp
f01037ac:	ff 75 0c             	pushl  0xc(%ebp)
f01037af:	6a 3f                	push   $0x3f
f01037b1:	ff 55 08             	call   *0x8(%ebp)
f01037b4:	83 c4 10             	add    $0x10,%esp
f01037b7:	eb c2                	jmp    f010377b <.L36+0x9a>
f01037b9:	89 75 0c             	mov    %esi,0xc(%ebp)
f01037bc:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01037bf:	eb be                	jmp    f010377f <.L36+0x9e>
				putch(' ', putdat);
f01037c1:	83 ec 08             	sub    $0x8,%esp
f01037c4:	56                   	push   %esi
f01037c5:	6a 20                	push   $0x20
f01037c7:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01037ca:	83 ef 01             	sub    $0x1,%edi
f01037cd:	83 c4 10             	add    $0x10,%esp
f01037d0:	85 ff                	test   %edi,%edi
f01037d2:	7f ed                	jg     f01037c1 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01037d4:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01037d7:	89 45 14             	mov    %eax,0x14(%ebp)
f01037da:	e9 46 01 00 00       	jmp    f0103925 <.L35+0x45>
f01037df:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01037e2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01037e5:	eb e9                	jmp    f01037d0 <.L36+0xef>

f01037e7 <.L31>:
f01037e7:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f01037ea:	83 f9 01             	cmp    $0x1,%ecx
f01037ed:	7e 40                	jle    f010382f <.L31+0x48>
		return va_arg(*ap, long long);
f01037ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01037f2:	8b 50 04             	mov    0x4(%eax),%edx
f01037f5:	8b 00                	mov    (%eax),%eax
f01037f7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01037fa:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01037fd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103800:	8d 40 08             	lea    0x8(%eax),%eax
f0103803:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0103806:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010380a:	79 55                	jns    f0103861 <.L31+0x7a>
				putch('-', putdat);
f010380c:	83 ec 08             	sub    $0x8,%esp
f010380f:	56                   	push   %esi
f0103810:	6a 2d                	push   $0x2d
f0103812:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103815:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103818:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010381b:	f7 da                	neg    %edx
f010381d:	83 d1 00             	adc    $0x0,%ecx
f0103820:	f7 d9                	neg    %ecx
f0103822:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0103825:	b8 0a 00 00 00       	mov    $0xa,%eax
f010382a:	e9 db 00 00 00       	jmp    f010390a <.L35+0x2a>
	else if (lflag)
f010382f:	85 c9                	test   %ecx,%ecx
f0103831:	75 17                	jne    f010384a <.L31+0x63>
		return va_arg(*ap, int);
f0103833:	8b 45 14             	mov    0x14(%ebp),%eax
f0103836:	8b 00                	mov    (%eax),%eax
f0103838:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010383b:	99                   	cltd   
f010383c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010383f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103842:	8d 40 04             	lea    0x4(%eax),%eax
f0103845:	89 45 14             	mov    %eax,0x14(%ebp)
f0103848:	eb bc                	jmp    f0103806 <.L31+0x1f>
		return va_arg(*ap, long);
f010384a:	8b 45 14             	mov    0x14(%ebp),%eax
f010384d:	8b 00                	mov    (%eax),%eax
f010384f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103852:	99                   	cltd   
f0103853:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103856:	8b 45 14             	mov    0x14(%ebp),%eax
f0103859:	8d 40 04             	lea    0x4(%eax),%eax
f010385c:	89 45 14             	mov    %eax,0x14(%ebp)
f010385f:	eb a5                	jmp    f0103806 <.L31+0x1f>
			num = getint(&ap, lflag);
f0103861:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103864:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0103867:	b8 0a 00 00 00       	mov    $0xa,%eax
f010386c:	e9 99 00 00 00       	jmp    f010390a <.L35+0x2a>

f0103871 <.L37>:
f0103871:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0103874:	83 f9 01             	cmp    $0x1,%ecx
f0103877:	7e 15                	jle    f010388e <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f0103879:	8b 45 14             	mov    0x14(%ebp),%eax
f010387c:	8b 10                	mov    (%eax),%edx
f010387e:	8b 48 04             	mov    0x4(%eax),%ecx
f0103881:	8d 40 08             	lea    0x8(%eax),%eax
f0103884:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103887:	b8 0a 00 00 00       	mov    $0xa,%eax
f010388c:	eb 7c                	jmp    f010390a <.L35+0x2a>
	else if (lflag)
f010388e:	85 c9                	test   %ecx,%ecx
f0103890:	75 17                	jne    f01038a9 <.L37+0x38>
		return va_arg(*ap, unsigned int);
f0103892:	8b 45 14             	mov    0x14(%ebp),%eax
f0103895:	8b 10                	mov    (%eax),%edx
f0103897:	b9 00 00 00 00       	mov    $0x0,%ecx
f010389c:	8d 40 04             	lea    0x4(%eax),%eax
f010389f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01038a2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01038a7:	eb 61                	jmp    f010390a <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01038a9:	8b 45 14             	mov    0x14(%ebp),%eax
f01038ac:	8b 10                	mov    (%eax),%edx
f01038ae:	b9 00 00 00 00       	mov    $0x0,%ecx
f01038b3:	8d 40 04             	lea    0x4(%eax),%eax
f01038b6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01038b9:	b8 0a 00 00 00       	mov    $0xa,%eax
f01038be:	eb 4a                	jmp    f010390a <.L35+0x2a>

f01038c0 <.L34>:
			putch('X', putdat);
f01038c0:	83 ec 08             	sub    $0x8,%esp
f01038c3:	56                   	push   %esi
f01038c4:	6a 58                	push   $0x58
f01038c6:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01038c9:	83 c4 08             	add    $0x8,%esp
f01038cc:	56                   	push   %esi
f01038cd:	6a 58                	push   $0x58
f01038cf:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01038d2:	83 c4 08             	add    $0x8,%esp
f01038d5:	56                   	push   %esi
f01038d6:	6a 58                	push   $0x58
f01038d8:	ff 55 08             	call   *0x8(%ebp)
			break;
f01038db:	83 c4 10             	add    $0x10,%esp
f01038de:	eb 45                	jmp    f0103925 <.L35+0x45>

f01038e0 <.L35>:
			putch('0', putdat);
f01038e0:	83 ec 08             	sub    $0x8,%esp
f01038e3:	56                   	push   %esi
f01038e4:	6a 30                	push   $0x30
f01038e6:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01038e9:	83 c4 08             	add    $0x8,%esp
f01038ec:	56                   	push   %esi
f01038ed:	6a 78                	push   $0x78
f01038ef:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f01038f2:	8b 45 14             	mov    0x14(%ebp),%eax
f01038f5:	8b 10                	mov    (%eax),%edx
f01038f7:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f01038fc:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f01038ff:	8d 40 04             	lea    0x4(%eax),%eax
f0103902:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103905:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010390a:	83 ec 0c             	sub    $0xc,%esp
f010390d:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103911:	57                   	push   %edi
f0103912:	ff 75 e0             	pushl  -0x20(%ebp)
f0103915:	50                   	push   %eax
f0103916:	51                   	push   %ecx
f0103917:	52                   	push   %edx
f0103918:	89 f2                	mov    %esi,%edx
f010391a:	8b 45 08             	mov    0x8(%ebp),%eax
f010391d:	e8 55 fb ff ff       	call   f0103477 <printnum>
			break;
f0103922:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0103925:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103928:	83 c7 01             	add    $0x1,%edi
f010392b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010392f:	83 f8 25             	cmp    $0x25,%eax
f0103932:	0f 84 62 fc ff ff    	je     f010359a <vprintfmt+0x1f>
			if (ch == '\0')
f0103938:	85 c0                	test   %eax,%eax
f010393a:	0f 84 91 00 00 00    	je     f01039d1 <.L22+0x21>
			putch(ch, putdat);
f0103940:	83 ec 08             	sub    $0x8,%esp
f0103943:	56                   	push   %esi
f0103944:	50                   	push   %eax
f0103945:	ff 55 08             	call   *0x8(%ebp)
f0103948:	83 c4 10             	add    $0x10,%esp
f010394b:	eb db                	jmp    f0103928 <.L35+0x48>

f010394d <.L38>:
f010394d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0103950:	83 f9 01             	cmp    $0x1,%ecx
f0103953:	7e 15                	jle    f010396a <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0103955:	8b 45 14             	mov    0x14(%ebp),%eax
f0103958:	8b 10                	mov    (%eax),%edx
f010395a:	8b 48 04             	mov    0x4(%eax),%ecx
f010395d:	8d 40 08             	lea    0x8(%eax),%eax
f0103960:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103963:	b8 10 00 00 00       	mov    $0x10,%eax
f0103968:	eb a0                	jmp    f010390a <.L35+0x2a>
	else if (lflag)
f010396a:	85 c9                	test   %ecx,%ecx
f010396c:	75 17                	jne    f0103985 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f010396e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103971:	8b 10                	mov    (%eax),%edx
f0103973:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103978:	8d 40 04             	lea    0x4(%eax),%eax
f010397b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010397e:	b8 10 00 00 00       	mov    $0x10,%eax
f0103983:	eb 85                	jmp    f010390a <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103985:	8b 45 14             	mov    0x14(%ebp),%eax
f0103988:	8b 10                	mov    (%eax),%edx
f010398a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010398f:	8d 40 04             	lea    0x4(%eax),%eax
f0103992:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103995:	b8 10 00 00 00       	mov    $0x10,%eax
f010399a:	e9 6b ff ff ff       	jmp    f010390a <.L35+0x2a>

f010399f <.L25>:
			putch(ch, putdat);
f010399f:	83 ec 08             	sub    $0x8,%esp
f01039a2:	56                   	push   %esi
f01039a3:	6a 25                	push   $0x25
f01039a5:	ff 55 08             	call   *0x8(%ebp)
			break;
f01039a8:	83 c4 10             	add    $0x10,%esp
f01039ab:	e9 75 ff ff ff       	jmp    f0103925 <.L35+0x45>

f01039b0 <.L22>:
			putch('%', putdat);
f01039b0:	83 ec 08             	sub    $0x8,%esp
f01039b3:	56                   	push   %esi
f01039b4:	6a 25                	push   $0x25
f01039b6:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01039b9:	83 c4 10             	add    $0x10,%esp
f01039bc:	89 f8                	mov    %edi,%eax
f01039be:	eb 03                	jmp    f01039c3 <.L22+0x13>
f01039c0:	83 e8 01             	sub    $0x1,%eax
f01039c3:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01039c7:	75 f7                	jne    f01039c0 <.L22+0x10>
f01039c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01039cc:	e9 54 ff ff ff       	jmp    f0103925 <.L35+0x45>
}
f01039d1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01039d4:	5b                   	pop    %ebx
f01039d5:	5e                   	pop    %esi
f01039d6:	5f                   	pop    %edi
f01039d7:	5d                   	pop    %ebp
f01039d8:	c3                   	ret    

f01039d9 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01039d9:	55                   	push   %ebp
f01039da:	89 e5                	mov    %esp,%ebp
f01039dc:	53                   	push   %ebx
f01039dd:	83 ec 14             	sub    $0x14,%esp
f01039e0:	e8 6a c7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01039e5:	81 c3 23 39 01 00    	add    $0x13923,%ebx
f01039eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01039ee:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01039f1:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01039f4:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01039f8:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01039fb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103a02:	85 c0                	test   %eax,%eax
f0103a04:	74 2b                	je     f0103a31 <vsnprintf+0x58>
f0103a06:	85 d2                	test   %edx,%edx
f0103a08:	7e 27                	jle    f0103a31 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103a0a:	ff 75 14             	pushl  0x14(%ebp)
f0103a0d:	ff 75 10             	pushl  0x10(%ebp)
f0103a10:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103a13:	50                   	push   %eax
f0103a14:	8d 83 39 c2 fe ff    	lea    -0x13dc7(%ebx),%eax
f0103a1a:	50                   	push   %eax
f0103a1b:	e8 5b fb ff ff       	call   f010357b <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103a20:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103a23:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103a26:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103a29:	83 c4 10             	add    $0x10,%esp
}
f0103a2c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a2f:	c9                   	leave  
f0103a30:	c3                   	ret    
		return -E_INVAL;
f0103a31:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103a36:	eb f4                	jmp    f0103a2c <vsnprintf+0x53>

f0103a38 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103a38:	55                   	push   %ebp
f0103a39:	89 e5                	mov    %esp,%ebp
f0103a3b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103a3e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103a41:	50                   	push   %eax
f0103a42:	ff 75 10             	pushl  0x10(%ebp)
f0103a45:	ff 75 0c             	pushl  0xc(%ebp)
f0103a48:	ff 75 08             	pushl  0x8(%ebp)
f0103a4b:	e8 89 ff ff ff       	call   f01039d9 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103a50:	c9                   	leave  
f0103a51:	c3                   	ret    

f0103a52 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103a52:	55                   	push   %ebp
f0103a53:	89 e5                	mov    %esp,%ebp
f0103a55:	57                   	push   %edi
f0103a56:	56                   	push   %esi
f0103a57:	53                   	push   %ebx
f0103a58:	83 ec 1c             	sub    $0x1c,%esp
f0103a5b:	e8 ef c6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103a60:	81 c3 a8 38 01 00    	add    $0x138a8,%ebx
f0103a66:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103a69:	85 c0                	test   %eax,%eax
f0103a6b:	74 13                	je     f0103a80 <readline+0x2e>
		cprintf("%s", prompt);
f0103a6d:	83 ec 08             	sub    $0x8,%esp
f0103a70:	50                   	push   %eax
f0103a71:	8d 83 4c d3 fe ff    	lea    -0x12cb4(%ebx),%eax
f0103a77:	50                   	push   %eax
f0103a78:	e8 ee f6 ff ff       	call   f010316b <cprintf>
f0103a7d:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103a80:	83 ec 0c             	sub    $0xc,%esp
f0103a83:	6a 00                	push   $0x0
f0103a85:	e8 5d cc ff ff       	call   f01006e7 <iscons>
f0103a8a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a8d:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103a90:	bf 00 00 00 00       	mov    $0x0,%edi
f0103a95:	eb 46                	jmp    f0103add <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0103a97:	83 ec 08             	sub    $0x8,%esp
f0103a9a:	50                   	push   %eax
f0103a9b:	8d 83 94 e2 fe ff    	lea    -0x11d6c(%ebx),%eax
f0103aa1:	50                   	push   %eax
f0103aa2:	e8 c4 f6 ff ff       	call   f010316b <cprintf>
			return NULL;
f0103aa7:	83 c4 10             	add    $0x10,%esp
f0103aaa:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103aaf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103ab2:	5b                   	pop    %ebx
f0103ab3:	5e                   	pop    %esi
f0103ab4:	5f                   	pop    %edi
f0103ab5:	5d                   	pop    %ebp
f0103ab6:	c3                   	ret    
			if (echoing)
f0103ab7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103abb:	75 05                	jne    f0103ac2 <readline+0x70>
			i--;
f0103abd:	83 ef 01             	sub    $0x1,%edi
f0103ac0:	eb 1b                	jmp    f0103add <readline+0x8b>
				cputchar('\b');
f0103ac2:	83 ec 0c             	sub    $0xc,%esp
f0103ac5:	6a 08                	push   $0x8
f0103ac7:	e8 fa cb ff ff       	call   f01006c6 <cputchar>
f0103acc:	83 c4 10             	add    $0x10,%esp
f0103acf:	eb ec                	jmp    f0103abd <readline+0x6b>
			buf[i++] = c;
f0103ad1:	89 f0                	mov    %esi,%eax
f0103ad3:	88 84 3b b8 1f 00 00 	mov    %al,0x1fb8(%ebx,%edi,1)
f0103ada:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0103add:	e8 f4 cb ff ff       	call   f01006d6 <getchar>
f0103ae2:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0103ae4:	85 c0                	test   %eax,%eax
f0103ae6:	78 af                	js     f0103a97 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103ae8:	83 f8 08             	cmp    $0x8,%eax
f0103aeb:	0f 94 c2             	sete   %dl
f0103aee:	83 f8 7f             	cmp    $0x7f,%eax
f0103af1:	0f 94 c0             	sete   %al
f0103af4:	08 c2                	or     %al,%dl
f0103af6:	74 04                	je     f0103afc <readline+0xaa>
f0103af8:	85 ff                	test   %edi,%edi
f0103afa:	7f bb                	jg     f0103ab7 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103afc:	83 fe 1f             	cmp    $0x1f,%esi
f0103aff:	7e 1c                	jle    f0103b1d <readline+0xcb>
f0103b01:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103b07:	7f 14                	jg     f0103b1d <readline+0xcb>
			if (echoing)
f0103b09:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b0d:	74 c2                	je     f0103ad1 <readline+0x7f>
				cputchar(c);
f0103b0f:	83 ec 0c             	sub    $0xc,%esp
f0103b12:	56                   	push   %esi
f0103b13:	e8 ae cb ff ff       	call   f01006c6 <cputchar>
f0103b18:	83 c4 10             	add    $0x10,%esp
f0103b1b:	eb b4                	jmp    f0103ad1 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103b1d:	83 fe 0a             	cmp    $0xa,%esi
f0103b20:	74 05                	je     f0103b27 <readline+0xd5>
f0103b22:	83 fe 0d             	cmp    $0xd,%esi
f0103b25:	75 b6                	jne    f0103add <readline+0x8b>
			if (echoing)
f0103b27:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b2b:	75 13                	jne    f0103b40 <readline+0xee>
			buf[i] = 0;
f0103b2d:	c6 84 3b b8 1f 00 00 	movb   $0x0,0x1fb8(%ebx,%edi,1)
f0103b34:	00 
			return buf;
f0103b35:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f0103b3b:	e9 6f ff ff ff       	jmp    f0103aaf <readline+0x5d>
				cputchar('\n');
f0103b40:	83 ec 0c             	sub    $0xc,%esp
f0103b43:	6a 0a                	push   $0xa
f0103b45:	e8 7c cb ff ff       	call   f01006c6 <cputchar>
f0103b4a:	83 c4 10             	add    $0x10,%esp
f0103b4d:	eb de                	jmp    f0103b2d <readline+0xdb>

f0103b4f <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103b4f:	55                   	push   %ebp
f0103b50:	89 e5                	mov    %esp,%ebp
f0103b52:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103b55:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b5a:	eb 03                	jmp    f0103b5f <strlen+0x10>
		n++;
f0103b5c:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103b5f:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103b63:	75 f7                	jne    f0103b5c <strlen+0xd>
	return n;
}
f0103b65:	5d                   	pop    %ebp
f0103b66:	c3                   	ret    

f0103b67 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103b67:	55                   	push   %ebp
f0103b68:	89 e5                	mov    %esp,%ebp
f0103b6a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b6d:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103b70:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b75:	eb 03                	jmp    f0103b7a <strnlen+0x13>
		n++;
f0103b77:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103b7a:	39 d0                	cmp    %edx,%eax
f0103b7c:	74 06                	je     f0103b84 <strnlen+0x1d>
f0103b7e:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103b82:	75 f3                	jne    f0103b77 <strnlen+0x10>
	return n;
}
f0103b84:	5d                   	pop    %ebp
f0103b85:	c3                   	ret    

f0103b86 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103b86:	55                   	push   %ebp
f0103b87:	89 e5                	mov    %esp,%ebp
f0103b89:	53                   	push   %ebx
f0103b8a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b8d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103b90:	89 c2                	mov    %eax,%edx
f0103b92:	83 c1 01             	add    $0x1,%ecx
f0103b95:	83 c2 01             	add    $0x1,%edx
f0103b98:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103b9c:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103b9f:	84 db                	test   %bl,%bl
f0103ba1:	75 ef                	jne    f0103b92 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103ba3:	5b                   	pop    %ebx
f0103ba4:	5d                   	pop    %ebp
f0103ba5:	c3                   	ret    

f0103ba6 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103ba6:	55                   	push   %ebp
f0103ba7:	89 e5                	mov    %esp,%ebp
f0103ba9:	53                   	push   %ebx
f0103baa:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103bad:	53                   	push   %ebx
f0103bae:	e8 9c ff ff ff       	call   f0103b4f <strlen>
f0103bb3:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103bb6:	ff 75 0c             	pushl  0xc(%ebp)
f0103bb9:	01 d8                	add    %ebx,%eax
f0103bbb:	50                   	push   %eax
f0103bbc:	e8 c5 ff ff ff       	call   f0103b86 <strcpy>
	return dst;
}
f0103bc1:	89 d8                	mov    %ebx,%eax
f0103bc3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103bc6:	c9                   	leave  
f0103bc7:	c3                   	ret    

f0103bc8 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103bc8:	55                   	push   %ebp
f0103bc9:	89 e5                	mov    %esp,%ebp
f0103bcb:	56                   	push   %esi
f0103bcc:	53                   	push   %ebx
f0103bcd:	8b 75 08             	mov    0x8(%ebp),%esi
f0103bd0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103bd3:	89 f3                	mov    %esi,%ebx
f0103bd5:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103bd8:	89 f2                	mov    %esi,%edx
f0103bda:	eb 0f                	jmp    f0103beb <strncpy+0x23>
		*dst++ = *src;
f0103bdc:	83 c2 01             	add    $0x1,%edx
f0103bdf:	0f b6 01             	movzbl (%ecx),%eax
f0103be2:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103be5:	80 39 01             	cmpb   $0x1,(%ecx)
f0103be8:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103beb:	39 da                	cmp    %ebx,%edx
f0103bed:	75 ed                	jne    f0103bdc <strncpy+0x14>
	}
	return ret;
}
f0103bef:	89 f0                	mov    %esi,%eax
f0103bf1:	5b                   	pop    %ebx
f0103bf2:	5e                   	pop    %esi
f0103bf3:	5d                   	pop    %ebp
f0103bf4:	c3                   	ret    

f0103bf5 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103bf5:	55                   	push   %ebp
f0103bf6:	89 e5                	mov    %esp,%ebp
f0103bf8:	56                   	push   %esi
f0103bf9:	53                   	push   %ebx
f0103bfa:	8b 75 08             	mov    0x8(%ebp),%esi
f0103bfd:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c00:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103c03:	89 f0                	mov    %esi,%eax
f0103c05:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103c09:	85 c9                	test   %ecx,%ecx
f0103c0b:	75 0b                	jne    f0103c18 <strlcpy+0x23>
f0103c0d:	eb 17                	jmp    f0103c26 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103c0f:	83 c2 01             	add    $0x1,%edx
f0103c12:	83 c0 01             	add    $0x1,%eax
f0103c15:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103c18:	39 d8                	cmp    %ebx,%eax
f0103c1a:	74 07                	je     f0103c23 <strlcpy+0x2e>
f0103c1c:	0f b6 0a             	movzbl (%edx),%ecx
f0103c1f:	84 c9                	test   %cl,%cl
f0103c21:	75 ec                	jne    f0103c0f <strlcpy+0x1a>
		*dst = '\0';
f0103c23:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103c26:	29 f0                	sub    %esi,%eax
}
f0103c28:	5b                   	pop    %ebx
f0103c29:	5e                   	pop    %esi
f0103c2a:	5d                   	pop    %ebp
f0103c2b:	c3                   	ret    

f0103c2c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103c2c:	55                   	push   %ebp
f0103c2d:	89 e5                	mov    %esp,%ebp
f0103c2f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103c32:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103c35:	eb 06                	jmp    f0103c3d <strcmp+0x11>
		p++, q++;
f0103c37:	83 c1 01             	add    $0x1,%ecx
f0103c3a:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103c3d:	0f b6 01             	movzbl (%ecx),%eax
f0103c40:	84 c0                	test   %al,%al
f0103c42:	74 04                	je     f0103c48 <strcmp+0x1c>
f0103c44:	3a 02                	cmp    (%edx),%al
f0103c46:	74 ef                	je     f0103c37 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103c48:	0f b6 c0             	movzbl %al,%eax
f0103c4b:	0f b6 12             	movzbl (%edx),%edx
f0103c4e:	29 d0                	sub    %edx,%eax
}
f0103c50:	5d                   	pop    %ebp
f0103c51:	c3                   	ret    

f0103c52 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103c52:	55                   	push   %ebp
f0103c53:	89 e5                	mov    %esp,%ebp
f0103c55:	53                   	push   %ebx
f0103c56:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c59:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c5c:	89 c3                	mov    %eax,%ebx
f0103c5e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103c61:	eb 06                	jmp    f0103c69 <strncmp+0x17>
		n--, p++, q++;
f0103c63:	83 c0 01             	add    $0x1,%eax
f0103c66:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103c69:	39 d8                	cmp    %ebx,%eax
f0103c6b:	74 16                	je     f0103c83 <strncmp+0x31>
f0103c6d:	0f b6 08             	movzbl (%eax),%ecx
f0103c70:	84 c9                	test   %cl,%cl
f0103c72:	74 04                	je     f0103c78 <strncmp+0x26>
f0103c74:	3a 0a                	cmp    (%edx),%cl
f0103c76:	74 eb                	je     f0103c63 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103c78:	0f b6 00             	movzbl (%eax),%eax
f0103c7b:	0f b6 12             	movzbl (%edx),%edx
f0103c7e:	29 d0                	sub    %edx,%eax
}
f0103c80:	5b                   	pop    %ebx
f0103c81:	5d                   	pop    %ebp
f0103c82:	c3                   	ret    
		return 0;
f0103c83:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c88:	eb f6                	jmp    f0103c80 <strncmp+0x2e>

f0103c8a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103c8a:	55                   	push   %ebp
f0103c8b:	89 e5                	mov    %esp,%ebp
f0103c8d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c90:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103c94:	0f b6 10             	movzbl (%eax),%edx
f0103c97:	84 d2                	test   %dl,%dl
f0103c99:	74 09                	je     f0103ca4 <strchr+0x1a>
		if (*s == c)
f0103c9b:	38 ca                	cmp    %cl,%dl
f0103c9d:	74 0a                	je     f0103ca9 <strchr+0x1f>
	for (; *s; s++)
f0103c9f:	83 c0 01             	add    $0x1,%eax
f0103ca2:	eb f0                	jmp    f0103c94 <strchr+0xa>
			return (char *) s;
	return 0;
f0103ca4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103ca9:	5d                   	pop    %ebp
f0103caa:	c3                   	ret    

f0103cab <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103cab:	55                   	push   %ebp
f0103cac:	89 e5                	mov    %esp,%ebp
f0103cae:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cb1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103cb5:	eb 03                	jmp    f0103cba <strfind+0xf>
f0103cb7:	83 c0 01             	add    $0x1,%eax
f0103cba:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103cbd:	38 ca                	cmp    %cl,%dl
f0103cbf:	74 04                	je     f0103cc5 <strfind+0x1a>
f0103cc1:	84 d2                	test   %dl,%dl
f0103cc3:	75 f2                	jne    f0103cb7 <strfind+0xc>
			break;
	return (char *) s;
}
f0103cc5:	5d                   	pop    %ebp
f0103cc6:	c3                   	ret    

f0103cc7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103cc7:	55                   	push   %ebp
f0103cc8:	89 e5                	mov    %esp,%ebp
f0103cca:	57                   	push   %edi
f0103ccb:	56                   	push   %esi
f0103ccc:	53                   	push   %ebx
f0103ccd:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103cd0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103cd3:	85 c9                	test   %ecx,%ecx
f0103cd5:	74 13                	je     f0103cea <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103cd7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103cdd:	75 05                	jne    f0103ce4 <memset+0x1d>
f0103cdf:	f6 c1 03             	test   $0x3,%cl
f0103ce2:	74 0d                	je     f0103cf1 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103ce4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ce7:	fc                   	cld    
f0103ce8:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103cea:	89 f8                	mov    %edi,%eax
f0103cec:	5b                   	pop    %ebx
f0103ced:	5e                   	pop    %esi
f0103cee:	5f                   	pop    %edi
f0103cef:	5d                   	pop    %ebp
f0103cf0:	c3                   	ret    
		c &= 0xFF;
f0103cf1:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103cf5:	89 d3                	mov    %edx,%ebx
f0103cf7:	c1 e3 08             	shl    $0x8,%ebx
f0103cfa:	89 d0                	mov    %edx,%eax
f0103cfc:	c1 e0 18             	shl    $0x18,%eax
f0103cff:	89 d6                	mov    %edx,%esi
f0103d01:	c1 e6 10             	shl    $0x10,%esi
f0103d04:	09 f0                	or     %esi,%eax
f0103d06:	09 c2                	or     %eax,%edx
f0103d08:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0103d0a:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103d0d:	89 d0                	mov    %edx,%eax
f0103d0f:	fc                   	cld    
f0103d10:	f3 ab                	rep stos %eax,%es:(%edi)
f0103d12:	eb d6                	jmp    f0103cea <memset+0x23>

f0103d14 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103d14:	55                   	push   %ebp
f0103d15:	89 e5                	mov    %esp,%ebp
f0103d17:	57                   	push   %edi
f0103d18:	56                   	push   %esi
f0103d19:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d1c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103d1f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103d22:	39 c6                	cmp    %eax,%esi
f0103d24:	73 35                	jae    f0103d5b <memmove+0x47>
f0103d26:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103d29:	39 c2                	cmp    %eax,%edx
f0103d2b:	76 2e                	jbe    f0103d5b <memmove+0x47>
		s += n;
		d += n;
f0103d2d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d30:	89 d6                	mov    %edx,%esi
f0103d32:	09 fe                	or     %edi,%esi
f0103d34:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103d3a:	74 0c                	je     f0103d48 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103d3c:	83 ef 01             	sub    $0x1,%edi
f0103d3f:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103d42:	fd                   	std    
f0103d43:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103d45:	fc                   	cld    
f0103d46:	eb 21                	jmp    f0103d69 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d48:	f6 c1 03             	test   $0x3,%cl
f0103d4b:	75 ef                	jne    f0103d3c <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103d4d:	83 ef 04             	sub    $0x4,%edi
f0103d50:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103d53:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103d56:	fd                   	std    
f0103d57:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103d59:	eb ea                	jmp    f0103d45 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d5b:	89 f2                	mov    %esi,%edx
f0103d5d:	09 c2                	or     %eax,%edx
f0103d5f:	f6 c2 03             	test   $0x3,%dl
f0103d62:	74 09                	je     f0103d6d <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103d64:	89 c7                	mov    %eax,%edi
f0103d66:	fc                   	cld    
f0103d67:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103d69:	5e                   	pop    %esi
f0103d6a:	5f                   	pop    %edi
f0103d6b:	5d                   	pop    %ebp
f0103d6c:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d6d:	f6 c1 03             	test   $0x3,%cl
f0103d70:	75 f2                	jne    f0103d64 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103d72:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103d75:	89 c7                	mov    %eax,%edi
f0103d77:	fc                   	cld    
f0103d78:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103d7a:	eb ed                	jmp    f0103d69 <memmove+0x55>

f0103d7c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103d7c:	55                   	push   %ebp
f0103d7d:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103d7f:	ff 75 10             	pushl  0x10(%ebp)
f0103d82:	ff 75 0c             	pushl  0xc(%ebp)
f0103d85:	ff 75 08             	pushl  0x8(%ebp)
f0103d88:	e8 87 ff ff ff       	call   f0103d14 <memmove>
}
f0103d8d:	c9                   	leave  
f0103d8e:	c3                   	ret    

f0103d8f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103d8f:	55                   	push   %ebp
f0103d90:	89 e5                	mov    %esp,%ebp
f0103d92:	56                   	push   %esi
f0103d93:	53                   	push   %ebx
f0103d94:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d97:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103d9a:	89 c6                	mov    %eax,%esi
f0103d9c:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103d9f:	39 f0                	cmp    %esi,%eax
f0103da1:	74 1c                	je     f0103dbf <memcmp+0x30>
		if (*s1 != *s2)
f0103da3:	0f b6 08             	movzbl (%eax),%ecx
f0103da6:	0f b6 1a             	movzbl (%edx),%ebx
f0103da9:	38 d9                	cmp    %bl,%cl
f0103dab:	75 08                	jne    f0103db5 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103dad:	83 c0 01             	add    $0x1,%eax
f0103db0:	83 c2 01             	add    $0x1,%edx
f0103db3:	eb ea                	jmp    f0103d9f <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0103db5:	0f b6 c1             	movzbl %cl,%eax
f0103db8:	0f b6 db             	movzbl %bl,%ebx
f0103dbb:	29 d8                	sub    %ebx,%eax
f0103dbd:	eb 05                	jmp    f0103dc4 <memcmp+0x35>
	}

	return 0;
f0103dbf:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103dc4:	5b                   	pop    %ebx
f0103dc5:	5e                   	pop    %esi
f0103dc6:	5d                   	pop    %ebp
f0103dc7:	c3                   	ret    

f0103dc8 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103dc8:	55                   	push   %ebp
f0103dc9:	89 e5                	mov    %esp,%ebp
f0103dcb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103dd1:	89 c2                	mov    %eax,%edx
f0103dd3:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103dd6:	39 d0                	cmp    %edx,%eax
f0103dd8:	73 09                	jae    f0103de3 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103dda:	38 08                	cmp    %cl,(%eax)
f0103ddc:	74 05                	je     f0103de3 <memfind+0x1b>
	for (; s < ends; s++)
f0103dde:	83 c0 01             	add    $0x1,%eax
f0103de1:	eb f3                	jmp    f0103dd6 <memfind+0xe>
			break;
	return (void *) s;
}
f0103de3:	5d                   	pop    %ebp
f0103de4:	c3                   	ret    

f0103de5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103de5:	55                   	push   %ebp
f0103de6:	89 e5                	mov    %esp,%ebp
f0103de8:	57                   	push   %edi
f0103de9:	56                   	push   %esi
f0103dea:	53                   	push   %ebx
f0103deb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103dee:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103df1:	eb 03                	jmp    f0103df6 <strtol+0x11>
		s++;
f0103df3:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0103df6:	0f b6 01             	movzbl (%ecx),%eax
f0103df9:	3c 20                	cmp    $0x20,%al
f0103dfb:	74 f6                	je     f0103df3 <strtol+0xe>
f0103dfd:	3c 09                	cmp    $0x9,%al
f0103dff:	74 f2                	je     f0103df3 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103e01:	3c 2b                	cmp    $0x2b,%al
f0103e03:	74 2e                	je     f0103e33 <strtol+0x4e>
	int neg = 0;
f0103e05:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103e0a:	3c 2d                	cmp    $0x2d,%al
f0103e0c:	74 2f                	je     f0103e3d <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103e0e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103e14:	75 05                	jne    f0103e1b <strtol+0x36>
f0103e16:	80 39 30             	cmpb   $0x30,(%ecx)
f0103e19:	74 2c                	je     f0103e47 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103e1b:	85 db                	test   %ebx,%ebx
f0103e1d:	75 0a                	jne    f0103e29 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103e1f:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0103e24:	80 39 30             	cmpb   $0x30,(%ecx)
f0103e27:	74 28                	je     f0103e51 <strtol+0x6c>
		base = 10;
f0103e29:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e2e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103e31:	eb 50                	jmp    f0103e83 <strtol+0x9e>
		s++;
f0103e33:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0103e36:	bf 00 00 00 00       	mov    $0x0,%edi
f0103e3b:	eb d1                	jmp    f0103e0e <strtol+0x29>
		s++, neg = 1;
f0103e3d:	83 c1 01             	add    $0x1,%ecx
f0103e40:	bf 01 00 00 00       	mov    $0x1,%edi
f0103e45:	eb c7                	jmp    f0103e0e <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103e47:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103e4b:	74 0e                	je     f0103e5b <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0103e4d:	85 db                	test   %ebx,%ebx
f0103e4f:	75 d8                	jne    f0103e29 <strtol+0x44>
		s++, base = 8;
f0103e51:	83 c1 01             	add    $0x1,%ecx
f0103e54:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103e59:	eb ce                	jmp    f0103e29 <strtol+0x44>
		s += 2, base = 16;
f0103e5b:	83 c1 02             	add    $0x2,%ecx
f0103e5e:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103e63:	eb c4                	jmp    f0103e29 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0103e65:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103e68:	89 f3                	mov    %esi,%ebx
f0103e6a:	80 fb 19             	cmp    $0x19,%bl
f0103e6d:	77 29                	ja     f0103e98 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103e6f:	0f be d2             	movsbl %dl,%edx
f0103e72:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103e75:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103e78:	7d 30                	jge    f0103eaa <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103e7a:	83 c1 01             	add    $0x1,%ecx
f0103e7d:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103e81:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103e83:	0f b6 11             	movzbl (%ecx),%edx
f0103e86:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103e89:	89 f3                	mov    %esi,%ebx
f0103e8b:	80 fb 09             	cmp    $0x9,%bl
f0103e8e:	77 d5                	ja     f0103e65 <strtol+0x80>
			dig = *s - '0';
f0103e90:	0f be d2             	movsbl %dl,%edx
f0103e93:	83 ea 30             	sub    $0x30,%edx
f0103e96:	eb dd                	jmp    f0103e75 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0103e98:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103e9b:	89 f3                	mov    %esi,%ebx
f0103e9d:	80 fb 19             	cmp    $0x19,%bl
f0103ea0:	77 08                	ja     f0103eaa <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103ea2:	0f be d2             	movsbl %dl,%edx
f0103ea5:	83 ea 37             	sub    $0x37,%edx
f0103ea8:	eb cb                	jmp    f0103e75 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103eaa:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103eae:	74 05                	je     f0103eb5 <strtol+0xd0>
		*endptr = (char *) s;
f0103eb0:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103eb3:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103eb5:	89 c2                	mov    %eax,%edx
f0103eb7:	f7 da                	neg    %edx
f0103eb9:	85 ff                	test   %edi,%edi
f0103ebb:	0f 45 c2             	cmovne %edx,%eax
}
f0103ebe:	5b                   	pop    %ebx
f0103ebf:	5e                   	pop    %esi
f0103ec0:	5f                   	pop    %edi
f0103ec1:	5d                   	pop    %ebp
f0103ec2:	c3                   	ret    
f0103ec3:	66 90                	xchg   %ax,%ax
f0103ec5:	66 90                	xchg   %ax,%ax
f0103ec7:	66 90                	xchg   %ax,%ax
f0103ec9:	66 90                	xchg   %ax,%ax
f0103ecb:	66 90                	xchg   %ax,%ax
f0103ecd:	66 90                	xchg   %ax,%ax
f0103ecf:	90                   	nop

f0103ed0 <__udivdi3>:
f0103ed0:	55                   	push   %ebp
f0103ed1:	57                   	push   %edi
f0103ed2:	56                   	push   %esi
f0103ed3:	53                   	push   %ebx
f0103ed4:	83 ec 1c             	sub    $0x1c,%esp
f0103ed7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103edb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0103edf:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103ee3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0103ee7:	85 d2                	test   %edx,%edx
f0103ee9:	75 35                	jne    f0103f20 <__udivdi3+0x50>
f0103eeb:	39 f3                	cmp    %esi,%ebx
f0103eed:	0f 87 bd 00 00 00    	ja     f0103fb0 <__udivdi3+0xe0>
f0103ef3:	85 db                	test   %ebx,%ebx
f0103ef5:	89 d9                	mov    %ebx,%ecx
f0103ef7:	75 0b                	jne    f0103f04 <__udivdi3+0x34>
f0103ef9:	b8 01 00 00 00       	mov    $0x1,%eax
f0103efe:	31 d2                	xor    %edx,%edx
f0103f00:	f7 f3                	div    %ebx
f0103f02:	89 c1                	mov    %eax,%ecx
f0103f04:	31 d2                	xor    %edx,%edx
f0103f06:	89 f0                	mov    %esi,%eax
f0103f08:	f7 f1                	div    %ecx
f0103f0a:	89 c6                	mov    %eax,%esi
f0103f0c:	89 e8                	mov    %ebp,%eax
f0103f0e:	89 f7                	mov    %esi,%edi
f0103f10:	f7 f1                	div    %ecx
f0103f12:	89 fa                	mov    %edi,%edx
f0103f14:	83 c4 1c             	add    $0x1c,%esp
f0103f17:	5b                   	pop    %ebx
f0103f18:	5e                   	pop    %esi
f0103f19:	5f                   	pop    %edi
f0103f1a:	5d                   	pop    %ebp
f0103f1b:	c3                   	ret    
f0103f1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f20:	39 f2                	cmp    %esi,%edx
f0103f22:	77 7c                	ja     f0103fa0 <__udivdi3+0xd0>
f0103f24:	0f bd fa             	bsr    %edx,%edi
f0103f27:	83 f7 1f             	xor    $0x1f,%edi
f0103f2a:	0f 84 98 00 00 00    	je     f0103fc8 <__udivdi3+0xf8>
f0103f30:	89 f9                	mov    %edi,%ecx
f0103f32:	b8 20 00 00 00       	mov    $0x20,%eax
f0103f37:	29 f8                	sub    %edi,%eax
f0103f39:	d3 e2                	shl    %cl,%edx
f0103f3b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103f3f:	89 c1                	mov    %eax,%ecx
f0103f41:	89 da                	mov    %ebx,%edx
f0103f43:	d3 ea                	shr    %cl,%edx
f0103f45:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103f49:	09 d1                	or     %edx,%ecx
f0103f4b:	89 f2                	mov    %esi,%edx
f0103f4d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103f51:	89 f9                	mov    %edi,%ecx
f0103f53:	d3 e3                	shl    %cl,%ebx
f0103f55:	89 c1                	mov    %eax,%ecx
f0103f57:	d3 ea                	shr    %cl,%edx
f0103f59:	89 f9                	mov    %edi,%ecx
f0103f5b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103f5f:	d3 e6                	shl    %cl,%esi
f0103f61:	89 eb                	mov    %ebp,%ebx
f0103f63:	89 c1                	mov    %eax,%ecx
f0103f65:	d3 eb                	shr    %cl,%ebx
f0103f67:	09 de                	or     %ebx,%esi
f0103f69:	89 f0                	mov    %esi,%eax
f0103f6b:	f7 74 24 08          	divl   0x8(%esp)
f0103f6f:	89 d6                	mov    %edx,%esi
f0103f71:	89 c3                	mov    %eax,%ebx
f0103f73:	f7 64 24 0c          	mull   0xc(%esp)
f0103f77:	39 d6                	cmp    %edx,%esi
f0103f79:	72 0c                	jb     f0103f87 <__udivdi3+0xb7>
f0103f7b:	89 f9                	mov    %edi,%ecx
f0103f7d:	d3 e5                	shl    %cl,%ebp
f0103f7f:	39 c5                	cmp    %eax,%ebp
f0103f81:	73 5d                	jae    f0103fe0 <__udivdi3+0x110>
f0103f83:	39 d6                	cmp    %edx,%esi
f0103f85:	75 59                	jne    f0103fe0 <__udivdi3+0x110>
f0103f87:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0103f8a:	31 ff                	xor    %edi,%edi
f0103f8c:	89 fa                	mov    %edi,%edx
f0103f8e:	83 c4 1c             	add    $0x1c,%esp
f0103f91:	5b                   	pop    %ebx
f0103f92:	5e                   	pop    %esi
f0103f93:	5f                   	pop    %edi
f0103f94:	5d                   	pop    %ebp
f0103f95:	c3                   	ret    
f0103f96:	8d 76 00             	lea    0x0(%esi),%esi
f0103f99:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0103fa0:	31 ff                	xor    %edi,%edi
f0103fa2:	31 c0                	xor    %eax,%eax
f0103fa4:	89 fa                	mov    %edi,%edx
f0103fa6:	83 c4 1c             	add    $0x1c,%esp
f0103fa9:	5b                   	pop    %ebx
f0103faa:	5e                   	pop    %esi
f0103fab:	5f                   	pop    %edi
f0103fac:	5d                   	pop    %ebp
f0103fad:	c3                   	ret    
f0103fae:	66 90                	xchg   %ax,%ax
f0103fb0:	31 ff                	xor    %edi,%edi
f0103fb2:	89 e8                	mov    %ebp,%eax
f0103fb4:	89 f2                	mov    %esi,%edx
f0103fb6:	f7 f3                	div    %ebx
f0103fb8:	89 fa                	mov    %edi,%edx
f0103fba:	83 c4 1c             	add    $0x1c,%esp
f0103fbd:	5b                   	pop    %ebx
f0103fbe:	5e                   	pop    %esi
f0103fbf:	5f                   	pop    %edi
f0103fc0:	5d                   	pop    %ebp
f0103fc1:	c3                   	ret    
f0103fc2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103fc8:	39 f2                	cmp    %esi,%edx
f0103fca:	72 06                	jb     f0103fd2 <__udivdi3+0x102>
f0103fcc:	31 c0                	xor    %eax,%eax
f0103fce:	39 eb                	cmp    %ebp,%ebx
f0103fd0:	77 d2                	ja     f0103fa4 <__udivdi3+0xd4>
f0103fd2:	b8 01 00 00 00       	mov    $0x1,%eax
f0103fd7:	eb cb                	jmp    f0103fa4 <__udivdi3+0xd4>
f0103fd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103fe0:	89 d8                	mov    %ebx,%eax
f0103fe2:	31 ff                	xor    %edi,%edi
f0103fe4:	eb be                	jmp    f0103fa4 <__udivdi3+0xd4>
f0103fe6:	66 90                	xchg   %ax,%ax
f0103fe8:	66 90                	xchg   %ax,%ax
f0103fea:	66 90                	xchg   %ax,%ax
f0103fec:	66 90                	xchg   %ax,%ax
f0103fee:	66 90                	xchg   %ax,%ax

f0103ff0 <__umoddi3>:
f0103ff0:	55                   	push   %ebp
f0103ff1:	57                   	push   %edi
f0103ff2:	56                   	push   %esi
f0103ff3:	53                   	push   %ebx
f0103ff4:	83 ec 1c             	sub    $0x1c,%esp
f0103ff7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0103ffb:	8b 74 24 30          	mov    0x30(%esp),%esi
f0103fff:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0104003:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104007:	85 ed                	test   %ebp,%ebp
f0104009:	89 f0                	mov    %esi,%eax
f010400b:	89 da                	mov    %ebx,%edx
f010400d:	75 19                	jne    f0104028 <__umoddi3+0x38>
f010400f:	39 df                	cmp    %ebx,%edi
f0104011:	0f 86 b1 00 00 00    	jbe    f01040c8 <__umoddi3+0xd8>
f0104017:	f7 f7                	div    %edi
f0104019:	89 d0                	mov    %edx,%eax
f010401b:	31 d2                	xor    %edx,%edx
f010401d:	83 c4 1c             	add    $0x1c,%esp
f0104020:	5b                   	pop    %ebx
f0104021:	5e                   	pop    %esi
f0104022:	5f                   	pop    %edi
f0104023:	5d                   	pop    %ebp
f0104024:	c3                   	ret    
f0104025:	8d 76 00             	lea    0x0(%esi),%esi
f0104028:	39 dd                	cmp    %ebx,%ebp
f010402a:	77 f1                	ja     f010401d <__umoddi3+0x2d>
f010402c:	0f bd cd             	bsr    %ebp,%ecx
f010402f:	83 f1 1f             	xor    $0x1f,%ecx
f0104032:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104036:	0f 84 b4 00 00 00    	je     f01040f0 <__umoddi3+0x100>
f010403c:	b8 20 00 00 00       	mov    $0x20,%eax
f0104041:	89 c2                	mov    %eax,%edx
f0104043:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104047:	29 c2                	sub    %eax,%edx
f0104049:	89 c1                	mov    %eax,%ecx
f010404b:	89 f8                	mov    %edi,%eax
f010404d:	d3 e5                	shl    %cl,%ebp
f010404f:	89 d1                	mov    %edx,%ecx
f0104051:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104055:	d3 e8                	shr    %cl,%eax
f0104057:	09 c5                	or     %eax,%ebp
f0104059:	8b 44 24 04          	mov    0x4(%esp),%eax
f010405d:	89 c1                	mov    %eax,%ecx
f010405f:	d3 e7                	shl    %cl,%edi
f0104061:	89 d1                	mov    %edx,%ecx
f0104063:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104067:	89 df                	mov    %ebx,%edi
f0104069:	d3 ef                	shr    %cl,%edi
f010406b:	89 c1                	mov    %eax,%ecx
f010406d:	89 f0                	mov    %esi,%eax
f010406f:	d3 e3                	shl    %cl,%ebx
f0104071:	89 d1                	mov    %edx,%ecx
f0104073:	89 fa                	mov    %edi,%edx
f0104075:	d3 e8                	shr    %cl,%eax
f0104077:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010407c:	09 d8                	or     %ebx,%eax
f010407e:	f7 f5                	div    %ebp
f0104080:	d3 e6                	shl    %cl,%esi
f0104082:	89 d1                	mov    %edx,%ecx
f0104084:	f7 64 24 08          	mull   0x8(%esp)
f0104088:	39 d1                	cmp    %edx,%ecx
f010408a:	89 c3                	mov    %eax,%ebx
f010408c:	89 d7                	mov    %edx,%edi
f010408e:	72 06                	jb     f0104096 <__umoddi3+0xa6>
f0104090:	75 0e                	jne    f01040a0 <__umoddi3+0xb0>
f0104092:	39 c6                	cmp    %eax,%esi
f0104094:	73 0a                	jae    f01040a0 <__umoddi3+0xb0>
f0104096:	2b 44 24 08          	sub    0x8(%esp),%eax
f010409a:	19 ea                	sbb    %ebp,%edx
f010409c:	89 d7                	mov    %edx,%edi
f010409e:	89 c3                	mov    %eax,%ebx
f01040a0:	89 ca                	mov    %ecx,%edx
f01040a2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01040a7:	29 de                	sub    %ebx,%esi
f01040a9:	19 fa                	sbb    %edi,%edx
f01040ab:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01040af:	89 d0                	mov    %edx,%eax
f01040b1:	d3 e0                	shl    %cl,%eax
f01040b3:	89 d9                	mov    %ebx,%ecx
f01040b5:	d3 ee                	shr    %cl,%esi
f01040b7:	d3 ea                	shr    %cl,%edx
f01040b9:	09 f0                	or     %esi,%eax
f01040bb:	83 c4 1c             	add    $0x1c,%esp
f01040be:	5b                   	pop    %ebx
f01040bf:	5e                   	pop    %esi
f01040c0:	5f                   	pop    %edi
f01040c1:	5d                   	pop    %ebp
f01040c2:	c3                   	ret    
f01040c3:	90                   	nop
f01040c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01040c8:	85 ff                	test   %edi,%edi
f01040ca:	89 f9                	mov    %edi,%ecx
f01040cc:	75 0b                	jne    f01040d9 <__umoddi3+0xe9>
f01040ce:	b8 01 00 00 00       	mov    $0x1,%eax
f01040d3:	31 d2                	xor    %edx,%edx
f01040d5:	f7 f7                	div    %edi
f01040d7:	89 c1                	mov    %eax,%ecx
f01040d9:	89 d8                	mov    %ebx,%eax
f01040db:	31 d2                	xor    %edx,%edx
f01040dd:	f7 f1                	div    %ecx
f01040df:	89 f0                	mov    %esi,%eax
f01040e1:	f7 f1                	div    %ecx
f01040e3:	e9 31 ff ff ff       	jmp    f0104019 <__umoddi3+0x29>
f01040e8:	90                   	nop
f01040e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01040f0:	39 dd                	cmp    %ebx,%ebp
f01040f2:	72 08                	jb     f01040fc <__umoddi3+0x10c>
f01040f4:	39 f7                	cmp    %esi,%edi
f01040f6:	0f 87 21 ff ff ff    	ja     f010401d <__umoddi3+0x2d>
f01040fc:	89 da                	mov    %ebx,%edx
f01040fe:	89 f0                	mov    %esi,%eax
f0104100:	29 f8                	sub    %edi,%eax
f0104102:	19 ea                	sbb    %ebp,%edx
f0104104:	e9 14 ff ff ff       	jmp    f010401d <__umoddi3+0x2d>
