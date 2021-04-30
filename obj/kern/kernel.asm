
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
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
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
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

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
f010004c:	81 c3 bc 32 01 00    	add    $0x132bc,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 50 11 f0    	mov    $0xf0115060,%edx
f0100058:	c7 c0 c0 56 11 f0    	mov    $0xf01156c0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 5f 1e 00 00       	call   f0101ec8 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 18 f0 fe ff    	lea    -0x10fe8(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 e6 12 00 00       	call   f0101368 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 b8 0a 00 00       	call   f0100b3f <mem_init>
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
f01000a7:	81 c3 61 32 01 00    	add    $0x13261,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 c4 56 11 f0    	mov    $0xf01156c4,%eax
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
f01000da:	8d 83 33 f0 fe ff    	lea    -0x10fcd(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 82 12 00 00       	call   f0101368 <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 41 12 00 00       	call   f0101331 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 6f f0 fe ff    	lea    -0x10f91(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 6a 12 00 00       	call   f0101368 <cprintf>
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
f010010d:	81 c3 fb 31 01 00    	add    $0x131fb,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 4b f0 fe ff    	lea    -0x10fb5(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 3d 12 00 00       	call   f0101368 <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 fa 11 00 00       	call   f0101331 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 6f f0 fe ff    	lea    -0x10f91(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 23 12 00 00       	call   f0101368 <cprintf>
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
f010017c:	81 c3 8c 31 01 00    	add    $0x1318c,%ebx
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
f01001c7:	81 c3 41 31 01 00    	add    $0x13141,%ebx
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
f0100217:	0f b6 84 13 98 f1 fe 	movzbl -0x10e68(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 98 f0 fe 	movzbl -0x10f68(%ebx,%edx,1),%ecx
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
f010026a:	8d 83 65 f0 fe ff    	lea    -0x10f9b(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 f2 10 00 00       	call   f0101368 <cprintf>
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
f01002b1:	0f b6 84 13 98 f1 fe 	movzbl -0x10e68(%ebx,%edx,1),%eax
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
f01002fd:	81 c3 0b 30 01 00    	add    $0x1300b,%ebx
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
f01004d2:	e8 3e 1a 00 00       	call   f0101f15 <memmove>
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
f010050a:	05 fe 2d 01 00       	add    $0x12dfe,%eax
	if (serial_exists)
f010050f:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 4b ce fe ff    	lea    -0x131b5(%eax),%eax
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
f0100538:	05 d0 2d 01 00       	add    $0x12dd0,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b5 ce fe ff    	lea    -0x1314b(%eax),%eax
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
f0100556:	81 c3 b2 2d 01 00    	add    $0x12db2,%ebx
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
f01005b2:	81 c3 56 2d 01 00    	add    $0x12d56,%ebx
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
f01006b5:	8d 83 71 f0 fe ff    	lea    -0x10f8f(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 a7 0c 00 00       	call   f0101368 <cprintf>
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
f01006ff:	81 c3 09 2c 01 00    	add    $0x12c09,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 98 f2 fe ff    	lea    -0x10d68(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 b6 f2 fe ff    	lea    -0x10d4a(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 bb f2 fe ff    	lea    -0x10d45(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 46 0c 00 00       	call   f0101368 <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 24 f3 fe ff    	lea    -0x10cdc(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 c4 f2 fe ff    	lea    -0x10d3c(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 2f 0c 00 00       	call   f0101368 <cprintf>
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
f0100753:	81 c3 b5 2b 01 00    	add    $0x12bb5,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100759:	8d 83 cd f2 fe ff    	lea    -0x10d33(%ebx),%eax
f010075f:	50                   	push   %eax
f0100760:	e8 03 0c 00 00       	call   f0101368 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100765:	83 c4 08             	add    $0x8,%esp
f0100768:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010076e:	8d 83 4c f3 fe ff    	lea    -0x10cb4(%ebx),%eax
f0100774:	50                   	push   %eax
f0100775:	e8 ee 0b 00 00       	call   f0101368 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010077a:	83 c4 0c             	add    $0xc,%esp
f010077d:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100783:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100789:	50                   	push   %eax
f010078a:	57                   	push   %edi
f010078b:	8d 83 74 f3 fe ff    	lea    -0x10c8c(%ebx),%eax
f0100791:	50                   	push   %eax
f0100792:	e8 d1 0b 00 00       	call   f0101368 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100797:	83 c4 0c             	add    $0xc,%esp
f010079a:	c7 c0 09 23 10 f0    	mov    $0xf0102309,%eax
f01007a0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007a6:	52                   	push   %edx
f01007a7:	50                   	push   %eax
f01007a8:	8d 83 98 f3 fe ff    	lea    -0x10c68(%ebx),%eax
f01007ae:	50                   	push   %eax
f01007af:	e8 b4 0b 00 00       	call   f0101368 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007b4:	83 c4 0c             	add    $0xc,%esp
f01007b7:	c7 c0 60 50 11 f0    	mov    $0xf0115060,%eax
f01007bd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007c3:	52                   	push   %edx
f01007c4:	50                   	push   %eax
f01007c5:	8d 83 bc f3 fe ff    	lea    -0x10c44(%ebx),%eax
f01007cb:	50                   	push   %eax
f01007cc:	e8 97 0b 00 00       	call   f0101368 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007d1:	83 c4 0c             	add    $0xc,%esp
f01007d4:	c7 c6 c0 56 11 f0    	mov    $0xf01156c0,%esi
f01007da:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007e0:	50                   	push   %eax
f01007e1:	56                   	push   %esi
f01007e2:	8d 83 e0 f3 fe ff    	lea    -0x10c20(%ebx),%eax
f01007e8:	50                   	push   %eax
f01007e9:	e8 7a 0b 00 00       	call   f0101368 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007ee:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007f1:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f01007f7:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f9:	c1 fe 0a             	sar    $0xa,%esi
f01007fc:	56                   	push   %esi
f01007fd:	8d 83 04 f4 fe ff    	lea    -0x10bfc(%ebx),%eax
f0100803:	50                   	push   %eax
f0100804:	e8 5f 0b 00 00       	call   f0101368 <cprintf>
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
f010082e:	81 c3 da 2a 01 00    	add    $0x12ada,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100834:	8d 83 30 f4 fe ff    	lea    -0x10bd0(%ebx),%eax
f010083a:	50                   	push   %eax
f010083b:	e8 28 0b 00 00       	call   f0101368 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100840:	8d 83 54 f4 fe ff    	lea    -0x10bac(%ebx),%eax
f0100846:	89 04 24             	mov    %eax,(%esp)
f0100849:	e8 1a 0b 00 00       	call   f0101368 <cprintf>
f010084e:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100851:	8d bb ea f2 fe ff    	lea    -0x10d16(%ebx),%edi
f0100857:	eb 4a                	jmp    f01008a3 <monitor+0x83>
f0100859:	83 ec 08             	sub    $0x8,%esp
f010085c:	0f be c0             	movsbl %al,%eax
f010085f:	50                   	push   %eax
f0100860:	57                   	push   %edi
f0100861:	e8 25 16 00 00       	call   f0101e8b <strchr>
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
f0100894:	8d 83 ef f2 fe ff    	lea    -0x10d11(%ebx),%eax
f010089a:	50                   	push   %eax
f010089b:	e8 c8 0a 00 00       	call   f0101368 <cprintf>
f01008a0:	83 c4 10             	add    $0x10,%esp
	//cprintf("%d %d\n", sizeof(char), sizeof(int)); 
	// Nikhil won lol


	while (1) {
		buf = readline("K> ");
f01008a3:	8d 83 e6 f2 fe ff    	lea    -0x10d1a(%ebx),%eax
f01008a9:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01008ac:	83 ec 0c             	sub    $0xc,%esp
f01008af:	ff 75 a4             	pushl  -0x5c(%ebp)
f01008b2:	e8 9c 13 00 00       	call   f0101c53 <readline>
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
f01008e2:	e8 a4 15 00 00       	call   f0101e8b <strchr>
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
f010090b:	8d 83 b6 f2 fe ff    	lea    -0x10d4a(%ebx),%eax
f0100911:	50                   	push   %eax
f0100912:	ff 75 a8             	pushl  -0x58(%ebp)
f0100915:	e8 13 15 00 00       	call   f0101e2d <strcmp>
f010091a:	83 c4 10             	add    $0x10,%esp
f010091d:	85 c0                	test   %eax,%eax
f010091f:	74 38                	je     f0100959 <monitor+0x139>
f0100921:	83 ec 08             	sub    $0x8,%esp
f0100924:	8d 83 c4 f2 fe ff    	lea    -0x10d3c(%ebx),%eax
f010092a:	50                   	push   %eax
f010092b:	ff 75 a8             	pushl  -0x58(%ebp)
f010092e:	e8 fa 14 00 00       	call   f0101e2d <strcmp>
f0100933:	83 c4 10             	add    $0x10,%esp
f0100936:	85 c0                	test   %eax,%eax
f0100938:	74 1a                	je     f0100954 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f010093a:	83 ec 08             	sub    $0x8,%esp
f010093d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100940:	8d 83 0c f3 fe ff    	lea    -0x10cf4(%ebx),%eax
f0100946:	50                   	push   %eax
f0100947:	e8 1c 0a 00 00       	call   f0101368 <cprintf>
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
f010098f:	81 c3 79 29 01 00    	add    $0x12979,%ebx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100995:	83 bb 90 1f 00 00 00 	cmpl   $0x0,0x1f90(%ebx)
f010099c:	74 26                	je     f01009c4 <boot_alloc+0x41>
	//
	// LAB 2: Your code here.

	// If n==0, returns the address of the next free page without allocating
	// anything.
	if(n == 0){ 
f010099e:	85 c0                	test   %eax,%eax
f01009a0:	74 3c                	je     f01009de <boot_alloc+0x5b>
		
		// nextfree is already at a page granularity
		uint32_t pageAddress = ROUNDUP(n, PGSIZE);
		//uint32_t finalAddress = ((uint32_t) nextfree + pageAddress);
		uint32_t finalAddressTemp = ((uint32_t) nextfree + n);
		uint32_t finalAddress = ROUNDUP(finalAddressTemp, PGSIZE);
f01009a2:	8b 93 90 1f 00 00    	mov    0x1f90(%ebx),%edx
f01009a8:	8d 94 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%edx
f01009af:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
		
		//if(finalAddress > KERNBASE + npages*PGSIZE){ // 0xffffffff is 4GB Limit
		if(finalAddress > KERNBASE + 0x0e000000){
f01009b5:	81 fa 00 00 00 fe    	cmp    $0xfe000000,%edx
f01009bb:	77 29                	ja     f01009e6 <boot_alloc+0x63>
			cprintf("%d %p %p %p\n", n, finalAddress, pageAddress, KERNBASE + npages*PGSIZE);
			panic("out of memory\n"); //PHYSTOP => STOP AT 2GB ABOVE KERNBASE 0xfe000000
		}
		//cprintf("fin: %x\n", (int) finalAddress); // used this to identify which portion of memory the pages get allocated in
		return (void *) finalAddress;
f01009bd:	89 d0                	mov    %edx,%eax
	}

	return NULL;
}
f01009bf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01009c2:	c9                   	leave  
f01009c3:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009c4:	c7 c2 c0 56 11 f0    	mov    $0xf01156c0,%edx
f01009ca:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f01009d0:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009d6:	89 93 90 1f 00 00    	mov    %edx,0x1f90(%ebx)
f01009dc:	eb c0                	jmp    f010099e <boot_alloc+0x1b>
		return nextfree;
f01009de:	8b 83 90 1f 00 00    	mov    0x1f90(%ebx),%eax
f01009e4:	eb d9                	jmp    f01009bf <boot_alloc+0x3c>
			cprintf("%d %p %p %p\n", n, finalAddress, pageAddress, KERNBASE + npages*PGSIZE);
f01009e6:	83 ec 0c             	sub    $0xc,%esp
f01009e9:	c7 c1 c8 56 11 f0    	mov    $0xf01156c8,%ecx
f01009ef:	8b 09                	mov    (%ecx),%ecx
f01009f1:	81 c1 00 00 0f 00    	add    $0xf0000,%ecx
f01009f7:	c1 e1 0c             	shl    $0xc,%ecx
f01009fa:	51                   	push   %ecx
		uint32_t pageAddress = ROUNDUP(n, PGSIZE);
f01009fb:	8d 88 ff 0f 00 00    	lea    0xfff(%eax),%ecx
			cprintf("%d %p %p %p\n", n, finalAddress, pageAddress, KERNBASE + npages*PGSIZE);
f0100a01:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100a07:	51                   	push   %ecx
f0100a08:	52                   	push   %edx
f0100a09:	50                   	push   %eax
f0100a0a:	8d 83 79 f4 fe ff    	lea    -0x10b87(%ebx),%eax
f0100a10:	50                   	push   %eax
f0100a11:	e8 52 09 00 00       	call   f0101368 <cprintf>
			panic("out of memory\n"); //PHYSTOP => STOP AT 2GB ABOVE KERNBASE 0xfe000000
f0100a16:	83 c4 1c             	add    $0x1c,%esp
f0100a19:	8d 83 86 f4 fe ff    	lea    -0x10b7a(%ebx),%eax
f0100a1f:	50                   	push   %eax
f0100a20:	68 83 00 00 00       	push   $0x83
f0100a25:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f0100a2b:	50                   	push   %eax
f0100a2c:	e8 68 f6 ff ff       	call   f0100099 <_panic>

f0100a31 <nvram_read>:
{
f0100a31:	55                   	push   %ebp
f0100a32:	89 e5                	mov    %esp,%ebp
f0100a34:	57                   	push   %edi
f0100a35:	56                   	push   %esi
f0100a36:	53                   	push   %ebx
f0100a37:	83 ec 18             	sub    $0x18,%esp
f0100a3a:	e8 10 f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100a3f:	81 c3 c9 28 01 00    	add    $0x128c9,%ebx
f0100a45:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a47:	50                   	push   %eax
f0100a48:	e8 94 08 00 00       	call   f01012e1 <mc146818_read>
f0100a4d:	89 c6                	mov    %eax,%esi
f0100a4f:	83 c7 01             	add    $0x1,%edi
f0100a52:	89 3c 24             	mov    %edi,(%esp)
f0100a55:	e8 87 08 00 00       	call   f01012e1 <mc146818_read>
f0100a5a:	c1 e0 08             	shl    $0x8,%eax
f0100a5d:	09 f0                	or     %esi,%eax
}
f0100a5f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a62:	5b                   	pop    %ebx
f0100a63:	5e                   	pop    %esi
f0100a64:	5f                   	pop    %edi
f0100a65:	5d                   	pop    %ebp
f0100a66:	c3                   	ret    

f0100a67 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100a67:	55                   	push   %ebp
f0100a68:	89 e5                	mov    %esp,%ebp
f0100a6a:	57                   	push   %edi
f0100a6b:	56                   	push   %esi
f0100a6c:	53                   	push   %ebx
f0100a6d:	83 ec 1c             	sub    $0x1c,%esp
f0100a70:	e8 68 08 00 00       	call   f01012dd <__x86.get_pc_thunk.di>
f0100a75:	81 c7 93 28 01 00    	add    $0x12893,%edi
	// However this is not truly the case.  What memory is free?
	//  1) Mark physical page 0 as in use.
	//     This way we preserve the real-mode IDT and BIOS structures
	//     in case we ever need them.  (Currently we don't, but...)
	
	pages[0].pp_ref = 1;
f0100a7b:	c7 c0 d0 56 11 f0    	mov    $0xf01156d0,%eax
f0100a81:	8b 00                	mov    (%eax),%eax
f0100a83:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f0100a89:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	
	//  2) The rest of base memory, [PGSIZE, npages_basemem * PGSIZE) ==> [1, 160)
	//     is free.
	
	size_t i;
	for(i = 1; i < npages_basemem; i++){
f0100a8f:	8b 87 98 1f 00 00    	mov    0x1f98(%edi),%eax
f0100a95:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100a98:	8b 9f 94 1f 00 00    	mov    0x1f94(%edi),%ebx
f0100a9e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100aa3:	b8 01 00 00 00       	mov    $0x1,%eax
		pages[i].pp_ref = 0;
f0100aa8:	c7 c6 d0 56 11 f0    	mov    $0xf01156d0,%esi
	for(i = 1; i < npages_basemem; i++){
f0100aae:	eb 1f                	jmp    f0100acf <page_init+0x68>
		pages[i].pp_ref = 0;
f0100ab0:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100ab7:	89 d1                	mov    %edx,%ecx
f0100ab9:	03 0e                	add    (%esi),%ecx
f0100abb:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100ac1:	89 19                	mov    %ebx,(%ecx)
	for(i = 1; i < npages_basemem; i++){
f0100ac3:	83 c0 01             	add    $0x1,%eax
		page_free_list = &pages[i];
f0100ac6:	03 16                	add    (%esi),%edx
f0100ac8:	89 d3                	mov    %edx,%ebx
f0100aca:	ba 01 00 00 00       	mov    $0x1,%edx
	for(i = 1; i < npages_basemem; i++){
f0100acf:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0100ad2:	77 dc                	ja     f0100ab0 <page_init+0x49>
f0100ad4:	84 d2                	test   %dl,%dl
f0100ad6:	75 16                	jne    f0100aee <page_init+0x87>
	//     Some of it is in use, some is free. Where is the kernel
	//     in physical memory?  Which pages are already in use for
	//     page tables and other data structures?
	//
	
	for(i = extphysmem; i < npages; i++){
f0100ad8:	bb 00 01 00 00       	mov    $0x100,%ebx
f0100add:	c7 c6 c8 56 11 f0    	mov    $0xf01156c8,%esi
		if(((uint32_t) boot_alloc(0))/PGSIZE < i){
			pages[i].pp_ref = 0;
f0100ae3:	c7 c0 d0 56 11 f0    	mov    $0xf01156d0,%eax
f0100ae9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100aec:	eb 0b                	jmp    f0100af9 <page_init+0x92>
f0100aee:	89 9f 94 1f 00 00    	mov    %ebx,0x1f94(%edi)
f0100af4:	eb e2                	jmp    f0100ad8 <page_init+0x71>
	for(i = extphysmem; i < npages; i++){
f0100af6:	83 c3 01             	add    $0x1,%ebx
f0100af9:	39 1e                	cmp    %ebx,(%esi)
f0100afb:	76 3a                	jbe    f0100b37 <page_init+0xd0>
		if(((uint32_t) boot_alloc(0))/PGSIZE < i){
f0100afd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b02:	e8 7c fe ff ff       	call   f0100983 <boot_alloc>
f0100b07:	c1 e8 0c             	shr    $0xc,%eax
f0100b0a:	39 d8                	cmp    %ebx,%eax
f0100b0c:	73 e8                	jae    f0100af6 <page_init+0x8f>
f0100b0e:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
			pages[i].pp_ref = 0;
f0100b15:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b18:	89 c2                	mov    %eax,%edx
f0100b1a:	03 11                	add    (%ecx),%edx
f0100b1c:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list;
f0100b22:	8b 8f 94 1f 00 00    	mov    0x1f94(%edi),%ecx
f0100b28:	89 0a                	mov    %ecx,(%edx)
			page_free_list = &pages[i];
f0100b2a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b2d:	03 01                	add    (%ecx),%eax
f0100b2f:	89 87 94 1f 00 00    	mov    %eax,0x1f94(%edi)
f0100b35:	eb bf                	jmp    f0100af6 <page_init+0x8f>
	// 	pages[i].pp_ref = 0;
	// 	pages[i].pp_link = page_free_list;
	// 	page_free_list = &pages[i];
	// 	//cprintf("%d -> %p\n", i, page_free_list);
	// }
}
f0100b37:	83 c4 1c             	add    $0x1c,%esp
f0100b3a:	5b                   	pop    %ebx
f0100b3b:	5e                   	pop    %esi
f0100b3c:	5f                   	pop    %edi
f0100b3d:	5d                   	pop    %ebp
f0100b3e:	c3                   	ret    

f0100b3f <mem_init>:
{
f0100b3f:	55                   	push   %ebp
f0100b40:	89 e5                	mov    %esp,%ebp
f0100b42:	57                   	push   %edi
f0100b43:	56                   	push   %esi
f0100b44:	53                   	push   %ebx
f0100b45:	83 ec 2c             	sub    $0x2c,%esp
f0100b48:	e8 02 f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100b4d:	81 c3 bb 27 01 00    	add    $0x127bb,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f0100b53:	b8 15 00 00 00       	mov    $0x15,%eax
f0100b58:	e8 d4 fe ff ff       	call   f0100a31 <nvram_read>
f0100b5d:	89 c6                	mov    %eax,%esi
	extmem = nvram_read(NVRAM_EXTLO);
f0100b5f:	b8 17 00 00 00       	mov    $0x17,%eax
f0100b64:	e8 c8 fe ff ff       	call   f0100a31 <nvram_read>
f0100b69:	89 c7                	mov    %eax,%edi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100b6b:	b8 34 00 00 00       	mov    $0x34,%eax
f0100b70:	e8 bc fe ff ff       	call   f0100a31 <nvram_read>
f0100b75:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0100b78:	85 c0                	test   %eax,%eax
f0100b7a:	75 0e                	jne    f0100b8a <mem_init+0x4b>
		totalmem = basemem;
f0100b7c:	89 f0                	mov    %esi,%eax
	else if (extmem)
f0100b7e:	85 ff                	test   %edi,%edi
f0100b80:	74 0d                	je     f0100b8f <mem_init+0x50>
		totalmem = 1 * 1024 + extmem;
f0100b82:	8d 87 00 04 00 00    	lea    0x400(%edi),%eax
f0100b88:	eb 05                	jmp    f0100b8f <mem_init+0x50>
		totalmem = 16 * 1024 + ext16mem;
f0100b8a:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f0100b8f:	89 c1                	mov    %eax,%ecx
f0100b91:	c1 e9 02             	shr    $0x2,%ecx
f0100b94:	c7 c2 c8 56 11 f0    	mov    $0xf01156c8,%edx
f0100b9a:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f0100b9c:	89 f2                	mov    %esi,%edx
f0100b9e:	c1 ea 02             	shr    $0x2,%edx
f0100ba1:	89 93 98 1f 00 00    	mov    %edx,0x1f98(%ebx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100ba7:	89 c2                	mov    %eax,%edx
f0100ba9:	29 f2                	sub    %esi,%edx
f0100bab:	52                   	push   %edx
f0100bac:	56                   	push   %esi
f0100bad:	50                   	push   %eax
f0100bae:	8d 83 94 f5 fe ff    	lea    -0x10a6c(%ebx),%eax
f0100bb4:	50                   	push   %eax
f0100bb5:	e8 ae 07 00 00       	call   f0101368 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100bba:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100bbf:	e8 bf fd ff ff       	call   f0100983 <boot_alloc>
f0100bc4:	c7 c6 cc 56 11 f0    	mov    $0xf01156cc,%esi
f0100bca:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f0100bcc:	83 c4 0c             	add    $0xc,%esp
f0100bcf:	68 00 10 00 00       	push   $0x1000
f0100bd4:	6a 00                	push   $0x0
f0100bd6:	50                   	push   %eax
f0100bd7:	e8 ec 12 00 00       	call   f0101ec8 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100bdc:	8b 06                	mov    (%esi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100bde:	83 c4 10             	add    $0x10,%esp
f0100be1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100be6:	77 19                	ja     f0100c01 <mem_init+0xc2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100be8:	50                   	push   %eax
f0100be9:	8d 83 d0 f5 fe ff    	lea    -0x10a30(%ebx),%eax
f0100bef:	50                   	push   %eax
f0100bf0:	68 ac 00 00 00       	push   $0xac
f0100bf5:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f0100bfb:	50                   	push   %eax
f0100bfc:	e8 98 f4 ff ff       	call   f0100099 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100c01:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100c07:	83 ca 05             	or     $0x5,%edx
f0100c0a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0100c10:	c7 c6 c8 56 11 f0    	mov    $0xf01156c8,%esi
f0100c16:	8b 06                	mov    (%esi),%eax
f0100c18:	c1 e0 03             	shl    $0x3,%eax
f0100c1b:	e8 63 fd ff ff       	call   f0100983 <boot_alloc>
f0100c20:	c7 c2 d0 56 11 f0    	mov    $0xf01156d0,%edx
f0100c26:	89 02                	mov    %eax,(%edx)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0100c28:	83 ec 04             	sub    $0x4,%esp
f0100c2b:	8b 16                	mov    (%esi),%edx
f0100c2d:	c1 e2 03             	shl    $0x3,%edx
f0100c30:	52                   	push   %edx
f0100c31:	6a 00                	push   $0x0
f0100c33:	50                   	push   %eax
f0100c34:	e8 8f 12 00 00       	call   f0101ec8 <memset>
	page_init();
f0100c39:	e8 29 fe ff ff       	call   f0100a67 <page_init>
	cprintf("%p\n", page_free_list);		
f0100c3e:	83 c4 08             	add    $0x8,%esp
f0100c41:	ff b3 94 1f 00 00    	pushl  0x1f94(%ebx)
f0100c47:	8d 83 b4 f4 fe ff    	lea    -0x10b4c(%ebx),%eax
f0100c4d:	50                   	push   %eax
f0100c4e:	e8 15 07 00 00       	call   f0101368 <cprintf>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c53:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f0100c59:	83 c4 10             	add    $0x10,%esp
f0100c5c:	85 c0                	test   %eax,%eax
f0100c5e:	74 76                	je     f0100cd6 <mem_init+0x197>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100c60:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100c63:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c66:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c69:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c6c:	c7 c6 d0 56 11 f0    	mov    $0xf01156d0,%esi
f0100c72:	89 c2                	mov    %eax,%edx
f0100c74:	2b 16                	sub    (%esi),%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100c76:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100c7c:	0f 95 c2             	setne  %dl
f0100c7f:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100c82:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100c86:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c88:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c8c:	8b 00                	mov    (%eax),%eax
f0100c8e:	85 c0                	test   %eax,%eax
f0100c90:	75 e0                	jne    f0100c72 <mem_init+0x133>
		}
		*tp[1] = 0;
f0100c92:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c95:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100c9b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c9e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ca1:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ca3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ca6:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	}
	cprintf("%p\n", page_free_list);
f0100cac:	83 ec 08             	sub    $0x8,%esp
f0100caf:	50                   	push   %eax
f0100cb0:	8d 83 b4 f4 fe ff    	lea    -0x10b4c(%ebx),%eax
f0100cb6:	50                   	push   %eax
f0100cb7:	e8 ac 06 00 00       	call   f0101368 <cprintf>
	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.

	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100cbc:	8b b3 94 1f 00 00    	mov    0x1f94(%ebx),%esi
f0100cc2:	83 c4 10             	add    $0x10,%esp
f0100cc5:	c7 c7 d0 56 11 f0    	mov    $0xf01156d0,%edi
	if (PGNUM(pa) >= npages)
f0100ccb:	c7 c0 c8 56 11 f0    	mov    $0xf01156c8,%eax
f0100cd1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100cd4:	eb 33                	jmp    f0100d09 <mem_init+0x1ca>
		panic("'page_free_list' is a null pointer!");
f0100cd6:	83 ec 04             	sub    $0x4,%esp
f0100cd9:	8d 83 f4 f5 fe ff    	lea    -0x10a0c(%ebx),%eax
f0100cdf:	50                   	push   %eax
f0100ce0:	68 e8 02 00 00       	push   $0x2e8
f0100ce5:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f0100ceb:	50                   	push   %eax
f0100cec:	e8 a8 f3 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cf1:	52                   	push   %edx
f0100cf2:	8d 83 18 f6 fe ff    	lea    -0x109e8(%ebx),%eax
f0100cf8:	50                   	push   %eax
f0100cf9:	6a 52                	push   $0x52
f0100cfb:	8d 83 a1 f4 fe ff    	lea    -0x10b5f(%ebx),%eax
f0100d01:	50                   	push   %eax
f0100d02:	e8 92 f3 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d07:	8b 36                	mov    (%esi),%esi
f0100d09:	85 f6                	test   %esi,%esi
f0100d0b:	74 3d                	je     f0100d4a <mem_init+0x20b>
	return (pp - pages) << PGSHIFT;
f0100d0d:	89 f0                	mov    %esi,%eax
f0100d0f:	2b 07                	sub    (%edi),%eax
f0100d11:	c1 f8 03             	sar    $0x3,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100d14:	89 c2                	mov    %eax,%edx
f0100d16:	c1 e2 0c             	shl    $0xc,%edx
f0100d19:	a9 00 fc 0f 00       	test   $0xffc00,%eax
f0100d1e:	75 e7                	jne    f0100d07 <mem_init+0x1c8>
	if (PGNUM(pa) >= npages)
f0100d20:	89 d0                	mov    %edx,%eax
f0100d22:	c1 e8 0c             	shr    $0xc,%eax
f0100d25:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100d28:	3b 01                	cmp    (%ecx),%eax
f0100d2a:	73 c5                	jae    f0100cf1 <mem_init+0x1b2>
			memset(page2kva(pp), 0x97, 128);
f0100d2c:	83 ec 04             	sub    $0x4,%esp
f0100d2f:	68 80 00 00 00       	push   $0x80
f0100d34:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100d39:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100d3f:	52                   	push   %edx
f0100d40:	e8 83 11 00 00       	call   f0101ec8 <memset>
f0100d45:	83 c4 10             	add    $0x10,%esp
f0100d48:	eb bd                	jmp    f0100d07 <mem_init+0x1c8>

	first_free_page = (char *) boot_alloc(0);
f0100d4a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d4f:	e8 2f fc ff ff       	call   f0100983 <boot_alloc>
f0100d54:	89 45 c8             	mov    %eax,-0x38(%ebp)
	cprintf("ffp: %p\n", first_free_page);
f0100d57:	83 ec 08             	sub    $0x8,%esp
f0100d5a:	50                   	push   %eax
f0100d5b:	8d 83 af f4 fe ff    	lea    -0x10b51(%ebx),%eax
f0100d61:	50                   	push   %eax
f0100d62:	e8 01 06 00 00       	call   f0101368 <cprintf>
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d67:	8b b3 94 1f 00 00    	mov    0x1f94(%ebx),%esi
f0100d6d:	83 c4 10             	add    $0x10,%esp
	int nfree_basemem = 0, nfree_extmem = 0;
f0100d70:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f0100d77:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d7e:	c7 c7 d0 56 11 f0    	mov    $0xf01156d0,%edi
		assert(pp < pages + npages);
f0100d84:	c7 c0 c8 56 11 f0    	mov    $0xf01156c8,%eax
f0100d8a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d8d:	e9 13 01 00 00       	jmp    f0100ea5 <mem_init+0x366>
		assert(pp >= pages);
f0100d92:	8d 83 b8 f4 fe ff    	lea    -0x10b48(%ebx),%eax
f0100d98:	50                   	push   %eax
f0100d99:	8d 83 c4 f4 fe ff    	lea    -0x10b3c(%ebx),%eax
f0100d9f:	50                   	push   %eax
f0100da0:	68 04 03 00 00       	push   $0x304
f0100da5:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f0100dab:	50                   	push   %eax
f0100dac:	e8 e8 f2 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100db1:	8d 83 d9 f4 fe ff    	lea    -0x10b27(%ebx),%eax
f0100db7:	50                   	push   %eax
f0100db8:	8d 83 c4 f4 fe ff    	lea    -0x10b3c(%ebx),%eax
f0100dbe:	50                   	push   %eax
f0100dbf:	68 05 03 00 00       	push   $0x305
f0100dc4:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f0100dca:	50                   	push   %eax
f0100dcb:	e8 c9 f2 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100dd0:	8d 83 3c f6 fe ff    	lea    -0x109c4(%ebx),%eax
f0100dd6:	50                   	push   %eax
f0100dd7:	8d 83 c4 f4 fe ff    	lea    -0x10b3c(%ebx),%eax
f0100ddd:	50                   	push   %eax
f0100dde:	68 06 03 00 00       	push   $0x306
f0100de3:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f0100de9:	50                   	push   %eax
f0100dea:	e8 aa f2 ff ff       	call   f0100099 <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100def:	8d 83 ed f4 fe ff    	lea    -0x10b13(%ebx),%eax
f0100df5:	50                   	push   %eax
f0100df6:	8d 83 c4 f4 fe ff    	lea    -0x10b3c(%ebx),%eax
f0100dfc:	50                   	push   %eax
f0100dfd:	68 09 03 00 00       	push   $0x309
f0100e02:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f0100e08:	50                   	push   %eax
f0100e09:	e8 8b f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e0e:	8d 83 fe f4 fe ff    	lea    -0x10b02(%ebx),%eax
f0100e14:	50                   	push   %eax
f0100e15:	8d 83 c4 f4 fe ff    	lea    -0x10b3c(%ebx),%eax
f0100e1b:	50                   	push   %eax
f0100e1c:	68 0a 03 00 00       	push   $0x30a
f0100e21:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f0100e27:	50                   	push   %eax
f0100e28:	e8 6c f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e2d:	8d 83 70 f6 fe ff    	lea    -0x10990(%ebx),%eax
f0100e33:	50                   	push   %eax
f0100e34:	8d 83 c4 f4 fe ff    	lea    -0x10b3c(%ebx),%eax
f0100e3a:	50                   	push   %eax
f0100e3b:	68 0b 03 00 00       	push   $0x30b
f0100e40:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f0100e46:	50                   	push   %eax
f0100e47:	e8 4d f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e4c:	8d 83 17 f5 fe ff    	lea    -0x10ae9(%ebx),%eax
f0100e52:	50                   	push   %eax
f0100e53:	8d 83 c4 f4 fe ff    	lea    -0x10b3c(%ebx),%eax
f0100e59:	50                   	push   %eax
f0100e5a:	68 0c 03 00 00       	push   $0x30c
f0100e5f:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f0100e65:	50                   	push   %eax
f0100e66:	e8 2e f2 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100e6b:	89 c1                	mov    %eax,%ecx
f0100e6d:	c1 e9 0c             	shr    $0xc,%ecx
f0100e70:	39 ca                	cmp    %ecx,%edx
f0100e72:	0f 86 b8 00 00 00    	jbe    f0100f30 <mem_init+0x3f1>
	return (void *)(pa + KERNBASE);
f0100e78:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e7e:	39 55 c8             	cmp    %edx,-0x38(%ebp)
f0100e81:	0f 87 bf 00 00 00    	ja     f0100f46 <mem_init+0x407>
		if (page2pa(pp) < EXTPHYSMEM){
			cprintf("%p < %u\n", page2pa(pp), EXTPHYSMEM);
			++nfree_basemem;
		}
		else{
			cprintf("%p > %u\n", page2pa(pp), EXTPHYSMEM);
f0100e87:	83 ec 04             	sub    $0x4,%esp
f0100e8a:	68 00 00 10 00       	push   $0x100000
f0100e8f:	50                   	push   %eax
f0100e90:	8d 83 3a f5 fe ff    	lea    -0x10ac6(%ebx),%eax
f0100e96:	50                   	push   %eax
f0100e97:	e8 cc 04 00 00       	call   f0101368 <cprintf>
			++nfree_extmem;
f0100e9c:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100ea0:	83 c4 10             	add    $0x10,%esp
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ea3:	8b 36                	mov    (%esi),%esi
f0100ea5:	85 f6                	test   %esi,%esi
f0100ea7:	0f 84 b8 00 00 00    	je     f0100f65 <mem_init+0x426>
		assert(pp >= pages);
f0100ead:	8b 07                	mov    (%edi),%eax
f0100eaf:	39 f0                	cmp    %esi,%eax
f0100eb1:	0f 87 db fe ff ff    	ja     f0100d92 <mem_init+0x253>
		assert(pp < pages + npages);
f0100eb7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100eba:	8b 12                	mov    (%edx),%edx
f0100ebc:	8d 0c d0             	lea    (%eax,%edx,8),%ecx
f0100ebf:	39 ce                	cmp    %ecx,%esi
f0100ec1:	0f 83 ea fe ff ff    	jae    f0100db1 <mem_init+0x272>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ec7:	89 f1                	mov    %esi,%ecx
f0100ec9:	29 c1                	sub    %eax,%ecx
f0100ecb:	89 c8                	mov    %ecx,%eax
f0100ecd:	a8 07                	test   $0x7,%al
f0100ecf:	0f 85 fb fe ff ff    	jne    f0100dd0 <mem_init+0x291>
	return (pp - pages) << PGSHIFT;
f0100ed5:	c1 f8 03             	sar    $0x3,%eax
f0100ed8:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100edb:	85 c0                	test   %eax,%eax
f0100edd:	0f 84 0c ff ff ff    	je     f0100def <mem_init+0x2b0>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ee3:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ee8:	0f 84 20 ff ff ff    	je     f0100e0e <mem_init+0x2cf>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100eee:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ef3:	0f 84 34 ff ff ff    	je     f0100e2d <mem_init+0x2ee>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ef9:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100efe:	0f 84 48 ff ff ff    	je     f0100e4c <mem_init+0x30d>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100f04:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100f09:	0f 87 5c ff ff ff    	ja     f0100e6b <mem_init+0x32c>
			cprintf("%p < %u\n", page2pa(pp), EXTPHYSMEM);
f0100f0f:	83 ec 04             	sub    $0x4,%esp
f0100f12:	68 00 00 10 00       	push   $0x100000
f0100f17:	50                   	push   %eax
f0100f18:	8d 83 31 f5 fe ff    	lea    -0x10acf(%ebx),%eax
f0100f1e:	50                   	push   %eax
f0100f1f:	e8 44 04 00 00       	call   f0101368 <cprintf>
			++nfree_basemem;
f0100f24:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
f0100f28:	83 c4 10             	add    $0x10,%esp
f0100f2b:	e9 73 ff ff ff       	jmp    f0100ea3 <mem_init+0x364>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f30:	50                   	push   %eax
f0100f31:	8d 83 18 f6 fe ff    	lea    -0x109e8(%ebx),%eax
f0100f37:	50                   	push   %eax
f0100f38:	6a 52                	push   $0x52
f0100f3a:	8d 83 a1 f4 fe ff    	lea    -0x10b5f(%ebx),%eax
f0100f40:	50                   	push   %eax
f0100f41:	e8 53 f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100f46:	8d 83 94 f6 fe ff    	lea    -0x1096c(%ebx),%eax
f0100f4c:	50                   	push   %eax
f0100f4d:	8d 83 c4 f4 fe ff    	lea    -0x10b3c(%ebx),%eax
f0100f53:	50                   	push   %eax
f0100f54:	68 0d 03 00 00       	push   $0x30d
f0100f59:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f0100f5f:	50                   	push   %eax
f0100f60:	e8 34 f1 ff ff       	call   f0100099 <_panic>
		}
			
	}
	cprintf("5 HERE\n");
f0100f65:	83 ec 0c             	sub    $0xc,%esp
f0100f68:	8d 83 43 f5 fe ff    	lea    -0x10abd(%ebx),%eax
f0100f6e:	50                   	push   %eax
f0100f6f:	e8 f4 03 00 00       	call   f0101368 <cprintf>
	assert(nfree_basemem > 0);
f0100f74:	83 c4 10             	add    $0x10,%esp
f0100f77:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100f7b:	7e 30                	jle    f0100fad <mem_init+0x46e>
	assert(nfree_extmem > 0);
f0100f7d:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0100f81:	7e 49                	jle    f0100fcc <mem_init+0x48d>

	cprintf("check_page_free_list() succeeded!\n");
f0100f83:	83 ec 0c             	sub    $0xc,%esp
f0100f86:	8d 83 dc f6 fe ff    	lea    -0x10924(%ebx),%eax
f0100f8c:	50                   	push   %eax
f0100f8d:	e8 d6 03 00 00       	call   f0101368 <cprintf>
	panic("mem_init: This function is not finished\n");
f0100f92:	83 c4 0c             	add    $0xc,%esp
f0100f95:	8d 83 00 f7 fe ff    	lea    -0x10900(%ebx),%eax
f0100f9b:	50                   	push   %eax
f0100f9c:	68 d4 00 00 00       	push   $0xd4
f0100fa1:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f0100fa7:	50                   	push   %eax
f0100fa8:	e8 ec f0 ff ff       	call   f0100099 <_panic>
	assert(nfree_basemem > 0);
f0100fad:	8d 83 4b f5 fe ff    	lea    -0x10ab5(%ebx),%eax
f0100fb3:	50                   	push   %eax
f0100fb4:	8d 83 c4 f4 fe ff    	lea    -0x10b3c(%ebx),%eax
f0100fba:	50                   	push   %eax
f0100fbb:	68 1a 03 00 00       	push   $0x31a
f0100fc0:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f0100fc6:	50                   	push   %eax
f0100fc7:	e8 cd f0 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100fcc:	8d 83 5d f5 fe ff    	lea    -0x10aa3(%ebx),%eax
f0100fd2:	50                   	push   %eax
f0100fd3:	8d 83 c4 f4 fe ff    	lea    -0x10b3c(%ebx),%eax
f0100fd9:	50                   	push   %eax
f0100fda:	68 1b 03 00 00       	push   $0x31b
f0100fdf:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f0100fe5:	50                   	push   %eax
f0100fe6:	e8 ae f0 ff ff       	call   f0100099 <_panic>

f0100feb <page_alloc>:
{
f0100feb:	55                   	push   %ebp
f0100fec:	89 e5                	mov    %esp,%ebp
f0100fee:	56                   	push   %esi
f0100fef:	53                   	push   %ebx
f0100ff0:	e8 5a f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100ff5:	81 c3 13 23 01 00    	add    $0x12313,%ebx
	struct PageInfo *page_pop = page_free_list;
f0100ffb:	8b b3 94 1f 00 00    	mov    0x1f94(%ebx),%esi
	if (page_pop == NULL)
f0101001:	85 f6                	test   %esi,%esi
f0101003:	74 14                	je     f0101019 <page_alloc+0x2e>
	page_free_list = page_pop->pp_link;
f0101005:	8b 06                	mov    (%esi),%eax
f0101007:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	page_pop->pp_link = NULL; 
f010100d:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if (alloc_flags & ALLOC_ZERO)
f0101013:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101017:	75 09                	jne    f0101022 <page_alloc+0x37>
}
f0101019:	89 f0                	mov    %esi,%eax
f010101b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010101e:	5b                   	pop    %ebx
f010101f:	5e                   	pop    %esi
f0101020:	5d                   	pop    %ebp
f0101021:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f0101022:	c7 c0 d0 56 11 f0    	mov    $0xf01156d0,%eax
f0101028:	89 f2                	mov    %esi,%edx
f010102a:	2b 10                	sub    (%eax),%edx
f010102c:	89 d0                	mov    %edx,%eax
f010102e:	c1 f8 03             	sar    $0x3,%eax
f0101031:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101034:	89 c1                	mov    %eax,%ecx
f0101036:	c1 e9 0c             	shr    $0xc,%ecx
f0101039:	c7 c2 c8 56 11 f0    	mov    $0xf01156c8,%edx
f010103f:	3b 0a                	cmp    (%edx),%ecx
f0101041:	73 1a                	jae    f010105d <page_alloc+0x72>
		memset(ptr, 0, PGSIZE);
f0101043:	83 ec 04             	sub    $0x4,%esp
f0101046:	68 00 10 00 00       	push   $0x1000
f010104b:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f010104d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101052:	50                   	push   %eax
f0101053:	e8 70 0e 00 00       	call   f0101ec8 <memset>
f0101058:	83 c4 10             	add    $0x10,%esp
f010105b:	eb bc                	jmp    f0101019 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010105d:	50                   	push   %eax
f010105e:	8d 83 18 f6 fe ff    	lea    -0x109e8(%ebx),%eax
f0101064:	50                   	push   %eax
f0101065:	6a 52                	push   $0x52
f0101067:	8d 83 a1 f4 fe ff    	lea    -0x10b5f(%ebx),%eax
f010106d:	50                   	push   %eax
f010106e:	e8 26 f0 ff ff       	call   f0100099 <_panic>

f0101073 <page_free>:
{
f0101073:	55                   	push   %ebp
f0101074:	89 e5                	mov    %esp,%ebp
f0101076:	53                   	push   %ebx
f0101077:	83 ec 04             	sub    $0x4,%esp
f010107a:	e8 d0 f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010107f:	81 c3 89 22 01 00    	add    $0x12289,%ebx
f0101085:	8b 45 08             	mov    0x8(%ebp),%eax
	assert(pp->pp_ref == 0);  
f0101088:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010108d:	75 18                	jne    f01010a7 <page_free+0x34>
	assert(pp->pp_link == NULL); 
f010108f:	83 38 00             	cmpl   $0x0,(%eax)
f0101092:	75 32                	jne    f01010c6 <page_free+0x53>
	pp->pp_link = page_free_list;
f0101094:	8b 8b 94 1f 00 00    	mov    0x1f94(%ebx),%ecx
f010109a:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f010109c:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
}
f01010a2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010a5:	c9                   	leave  
f01010a6:	c3                   	ret    
	assert(pp->pp_ref == 0);  
f01010a7:	8d 83 6e f5 fe ff    	lea    -0x10a92(%ebx),%eax
f01010ad:	50                   	push   %eax
f01010ae:	8d 83 c4 f4 fe ff    	lea    -0x10b3c(%ebx),%eax
f01010b4:	50                   	push   %eax
f01010b5:	68 a8 01 00 00       	push   $0x1a8
f01010ba:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f01010c0:	50                   	push   %eax
f01010c1:	e8 d3 ef ff ff       	call   f0100099 <_panic>
	assert(pp->pp_link == NULL); 
f01010c6:	8d 83 7e f5 fe ff    	lea    -0x10a82(%ebx),%eax
f01010cc:	50                   	push   %eax
f01010cd:	8d 83 c4 f4 fe ff    	lea    -0x10b3c(%ebx),%eax
f01010d3:	50                   	push   %eax
f01010d4:	68 ac 01 00 00       	push   $0x1ac
f01010d9:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f01010df:	50                   	push   %eax
f01010e0:	e8 b4 ef ff ff       	call   f0100099 <_panic>

f01010e5 <page_decref>:
{
f01010e5:	55                   	push   %ebp
f01010e6:	89 e5                	mov    %esp,%ebp
f01010e8:	83 ec 08             	sub    $0x8,%esp
f01010eb:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01010ee:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01010f2:	83 e8 01             	sub    $0x1,%eax
f01010f5:	66 89 42 04          	mov    %ax,0x4(%edx)
f01010f9:	66 85 c0             	test   %ax,%ax
f01010fc:	74 02                	je     f0101100 <page_decref+0x1b>
}
f01010fe:	c9                   	leave  
f01010ff:	c3                   	ret    
		page_free(pp);
f0101100:	83 ec 0c             	sub    $0xc,%esp
f0101103:	52                   	push   %edx
f0101104:	e8 6a ff ff ff       	call   f0101073 <page_free>
f0101109:	83 c4 10             	add    $0x10,%esp
}
f010110c:	eb f0                	jmp    f01010fe <page_decref+0x19>

f010110e <pgdir_walk>:
{
f010110e:	55                   	push   %ebp
f010110f:	89 e5                	mov    %esp,%ebp
f0101111:	57                   	push   %edi
f0101112:	56                   	push   %esi
f0101113:	53                   	push   %ebx
f0101114:	83 ec 0c             	sub    $0xc,%esp
f0101117:	e8 33 f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010111c:	81 c3 ec 21 01 00    	add    $0x121ec,%ebx
f0101122:	8b 75 0c             	mov    0xc(%ebp),%esi
	uintptr_t pd_index = PDX(va);
f0101125:	89 f7                	mov    %esi,%edi
f0101127:	c1 ef 16             	shr    $0x16,%edi
	pde_t pd_entry = pgdir[pd_index];
f010112a:	c1 e7 02             	shl    $0x2,%edi
f010112d:	03 7d 08             	add    0x8(%ebp),%edi
f0101130:	8b 07                	mov    (%edi),%eax
	if (pd_entry == 0) 
f0101132:	85 c0                	test   %eax,%eax
f0101134:	75 2c                	jne    f0101162 <pgdir_walk+0x54>
		if (create == 0) // create 0 implies we don't want to initialize a new page dir entry
f0101136:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010113a:	74 6b                	je     f01011a7 <pgdir_walk+0x99>
			newpg = page_alloc(ALLOC_ZERO);
f010113c:	83 ec 0c             	sub    $0xc,%esp
f010113f:	6a 01                	push   $0x1
f0101141:	e8 a5 fe ff ff       	call   f0100feb <page_alloc>
			if (newpg == NULL)
f0101146:	83 c4 10             	add    $0x10,%esp
f0101149:	85 c0                	test   %eax,%eax
f010114b:	74 61                	je     f01011ae <pgdir_walk+0xa0>
			newpg->pp_ref += 1;
f010114d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101152:	c7 c2 d0 56 11 f0    	mov    $0xf01156d0,%edx
f0101158:	2b 02                	sub    (%edx),%eax
f010115a:	c1 f8 03             	sar    $0x3,%eax
f010115d:	c1 e0 0c             	shl    $0xc,%eax
			pgdir[pd_index] = pd_entry;
f0101160:	89 07                	mov    %eax,(%edi)
	physaddr_t pt_physadd = PTE_ADDR(pd_entry); // Now we have the physical address of the page table
f0101162:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101167:	89 c1                	mov    %eax,%ecx
f0101169:	c1 e9 0c             	shr    $0xc,%ecx
f010116c:	c7 c2 c8 56 11 f0    	mov    $0xf01156c8,%edx
f0101172:	3b 0a                	cmp    (%edx),%ecx
f0101174:	73 18                	jae    f010118e <pgdir_walk+0x80>
	uintptr_t pt_index = PTX(va); // Here, we get an index into the page table 
f0101176:	c1 ee 0a             	shr    $0xa,%esi
	pte_t *pt_entry = &pt_virtadd[pt_index]; // Finally, we have a pointer to the page table entry that we can now return
f0101179:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010117f:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
}
f0101186:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101189:	5b                   	pop    %ebx
f010118a:	5e                   	pop    %esi
f010118b:	5f                   	pop    %edi
f010118c:	5d                   	pop    %ebp
f010118d:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010118e:	50                   	push   %eax
f010118f:	8d 83 18 f6 fe ff    	lea    -0x109e8(%ebx),%eax
f0101195:	50                   	push   %eax
f0101196:	68 05 02 00 00       	push   $0x205
f010119b:	8d 83 95 f4 fe ff    	lea    -0x10b6b(%ebx),%eax
f01011a1:	50                   	push   %eax
f01011a2:	e8 f2 ee ff ff       	call   f0100099 <_panic>
			return NULL;
f01011a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01011ac:	eb d8                	jmp    f0101186 <pgdir_walk+0x78>
				return NULL;
f01011ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01011b3:	eb d1                	jmp    f0101186 <pgdir_walk+0x78>

f01011b5 <page_lookup>:
{
f01011b5:	55                   	push   %ebp
f01011b6:	89 e5                	mov    %esp,%ebp
f01011b8:	56                   	push   %esi
f01011b9:	53                   	push   %ebx
f01011ba:	e8 90 ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01011bf:	81 c3 49 21 01 00    	add    $0x12149,%ebx
f01011c5:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t * pt_entry = pgdir_walk(pgdir, (void *) va, 0);
f01011c8:	83 ec 04             	sub    $0x4,%esp
f01011cb:	6a 00                	push   $0x0
f01011cd:	ff 75 0c             	pushl  0xc(%ebp)
f01011d0:	ff 75 08             	pushl  0x8(%ebp)
f01011d3:	e8 36 ff ff ff       	call   f010110e <pgdir_walk>
	if(!pt_entry){
f01011d8:	83 c4 10             	add    $0x10,%esp
f01011db:	85 c0                	test   %eax,%eax
f01011dd:	74 3d                	je     f010121c <page_lookup+0x67>
	if(pte_store != 0){
f01011df:	85 f6                	test   %esi,%esi
f01011e1:	74 02                	je     f01011e5 <page_lookup+0x30>
		*pte_store = pt_entry;
f01011e3:	89 06                	mov    %eax,(%esi)
f01011e5:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011e8:	c7 c2 c8 56 11 f0    	mov    $0xf01156c8,%edx
f01011ee:	39 02                	cmp    %eax,(%edx)
f01011f0:	76 12                	jbe    f0101204 <page_lookup+0x4f>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f01011f2:	c7 c2 d0 56 11 f0    	mov    $0xf01156d0,%edx
f01011f8:	8b 12                	mov    (%edx),%edx
f01011fa:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01011fd:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101200:	5b                   	pop    %ebx
f0101201:	5e                   	pop    %esi
f0101202:	5d                   	pop    %ebp
f0101203:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101204:	83 ec 04             	sub    $0x4,%esp
f0101207:	8d 83 2c f7 fe ff    	lea    -0x108d4(%ebx),%eax
f010120d:	50                   	push   %eax
f010120e:	6a 4b                	push   $0x4b
f0101210:	8d 83 a1 f4 fe ff    	lea    -0x10b5f(%ebx),%eax
f0101216:	50                   	push   %eax
f0101217:	e8 7d ee ff ff       	call   f0100099 <_panic>
		return NULL;
f010121c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101221:	eb da                	jmp    f01011fd <page_lookup+0x48>

f0101223 <page_remove>:
{
f0101223:	55                   	push   %ebp
f0101224:	89 e5                	mov    %esp,%ebp
f0101226:	53                   	push   %ebx
f0101227:	83 ec 18             	sub    $0x18,%esp
f010122a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo * page = page_lookup(pgdir, va, &pt_entry_store);
f010122d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101230:	50                   	push   %eax
f0101231:	53                   	push   %ebx
f0101232:	ff 75 08             	pushl  0x8(%ebp)
f0101235:	e8 7b ff ff ff       	call   f01011b5 <page_lookup>
	page_decref(page);
f010123a:	89 04 24             	mov    %eax,(%esp)
f010123d:	e8 a3 fe ff ff       	call   f01010e5 <page_decref>
	if(pt_entry_store != 0){
f0101242:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101245:	83 c4 10             	add    $0x10,%esp
f0101248:	85 c0                	test   %eax,%eax
f010124a:	74 06                	je     f0101252 <page_remove+0x2f>
		*pt_entry_store = 0;
f010124c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101252:	0f 01 3b             	invlpg (%ebx)
}
f0101255:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101258:	c9                   	leave  
f0101259:	c3                   	ret    

f010125a <page_insert>:
{
f010125a:	55                   	push   %ebp
f010125b:	89 e5                	mov    %esp,%ebp
f010125d:	57                   	push   %edi
f010125e:	56                   	push   %esi
f010125f:	53                   	push   %ebx
f0101260:	83 ec 10             	sub    $0x10,%esp
f0101263:	e8 75 00 00 00       	call   f01012dd <__x86.get_pc_thunk.di>
f0101268:	81 c7 a0 20 01 00    	add    $0x120a0,%edi
f010126e:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pt_entry = pgdir_walk(pgdir, va, 1);
f0101271:	6a 01                	push   $0x1
f0101273:	ff 75 10             	pushl  0x10(%ebp)
f0101276:	ff 75 08             	pushl  0x8(%ebp)
f0101279:	e8 90 fe ff ff       	call   f010110e <pgdir_walk>
	if(pt_entry == NULL){
f010127e:	83 c4 10             	add    $0x10,%esp
f0101281:	85 c0                	test   %eax,%eax
f0101283:	74 46                	je     f01012cb <page_insert+0x71>
f0101285:	89 c3                	mov    %eax,%ebx
	pp->pp_ref += 1;
f0101287:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	if((*pt_entry & PTE_P) != 0){ // check permissions
f010128c:	f6 00 01             	testb  $0x1,(%eax)
f010128f:	75 27                	jne    f01012b8 <page_insert+0x5e>
	return (pp - pages) << PGSHIFT;
f0101291:	c7 c0 d0 56 11 f0    	mov    $0xf01156d0,%eax
f0101297:	2b 30                	sub    (%eax),%esi
f0101299:	89 f0                	mov    %esi,%eax
f010129b:	c1 f8 03             	sar    $0x3,%eax
f010129e:	c1 e0 0c             	shl    $0xc,%eax
	*pt_entry = page2pa(pp) | perm | PTE_P; // permissions from comments, but what does it mean?
f01012a1:	8b 55 14             	mov    0x14(%ebp),%edx
f01012a4:	83 ca 01             	or     $0x1,%edx
f01012a7:	09 d0                	or     %edx,%eax
f01012a9:	89 03                	mov    %eax,(%ebx)
	return 0;
f01012ab:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012b3:	5b                   	pop    %ebx
f01012b4:	5e                   	pop    %esi
f01012b5:	5f                   	pop    %edi
f01012b6:	5d                   	pop    %ebp
f01012b7:	c3                   	ret    
		page_remove(pgdir, va);
f01012b8:	83 ec 08             	sub    $0x8,%esp
f01012bb:	ff 75 10             	pushl  0x10(%ebp)
f01012be:	ff 75 08             	pushl  0x8(%ebp)
f01012c1:	e8 5d ff ff ff       	call   f0101223 <page_remove>
f01012c6:	83 c4 10             	add    $0x10,%esp
f01012c9:	eb c6                	jmp    f0101291 <page_insert+0x37>
		return -E_NO_MEM;
f01012cb:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01012d0:	eb de                	jmp    f01012b0 <page_insert+0x56>

f01012d2 <tlb_invalidate>:
{
f01012d2:	55                   	push   %ebp
f01012d3:	89 e5                	mov    %esp,%ebp
f01012d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012d8:	0f 01 38             	invlpg (%eax)
}
f01012db:	5d                   	pop    %ebp
f01012dc:	c3                   	ret    

f01012dd <__x86.get_pc_thunk.di>:
f01012dd:	8b 3c 24             	mov    (%esp),%edi
f01012e0:	c3                   	ret    

f01012e1 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01012e1:	55                   	push   %ebp
f01012e2:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01012e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01012e7:	ba 70 00 00 00       	mov    $0x70,%edx
f01012ec:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01012ed:	ba 71 00 00 00       	mov    $0x71,%edx
f01012f2:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01012f3:	0f b6 c0             	movzbl %al,%eax
}
f01012f6:	5d                   	pop    %ebp
f01012f7:	c3                   	ret    

f01012f8 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01012f8:	55                   	push   %ebp
f01012f9:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01012fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01012fe:	ba 70 00 00 00       	mov    $0x70,%edx
f0101303:	ee                   	out    %al,(%dx)
f0101304:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101307:	ba 71 00 00 00       	mov    $0x71,%edx
f010130c:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010130d:	5d                   	pop    %ebp
f010130e:	c3                   	ret    

f010130f <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010130f:	55                   	push   %ebp
f0101310:	89 e5                	mov    %esp,%ebp
f0101312:	53                   	push   %ebx
f0101313:	83 ec 10             	sub    $0x10,%esp
f0101316:	e8 34 ee ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010131b:	81 c3 ed 1f 01 00    	add    $0x11fed,%ebx
	cputchar(ch);
f0101321:	ff 75 08             	pushl  0x8(%ebp)
f0101324:	e8 9d f3 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f0101329:	83 c4 10             	add    $0x10,%esp
f010132c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010132f:	c9                   	leave  
f0101330:	c3                   	ret    

f0101331 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101331:	55                   	push   %ebp
f0101332:	89 e5                	mov    %esp,%ebp
f0101334:	53                   	push   %ebx
f0101335:	83 ec 14             	sub    $0x14,%esp
f0101338:	e8 12 ee ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010133d:	81 c3 cb 1f 01 00    	add    $0x11fcb,%ebx
	int cnt = 0;
f0101343:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010134a:	ff 75 0c             	pushl  0xc(%ebp)
f010134d:	ff 75 08             	pushl  0x8(%ebp)
f0101350:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101353:	50                   	push   %eax
f0101354:	8d 83 07 e0 fe ff    	lea    -0x11ff9(%ebx),%eax
f010135a:	50                   	push   %eax
f010135b:	e8 1c 04 00 00       	call   f010177c <vprintfmt>
	return cnt;
}
f0101360:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101363:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101366:	c9                   	leave  
f0101367:	c3                   	ret    

f0101368 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0101368:	55                   	push   %ebp
f0101369:	89 e5                	mov    %esp,%ebp
f010136b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010136e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101371:	50                   	push   %eax
f0101372:	ff 75 08             	pushl  0x8(%ebp)
f0101375:	e8 b7 ff ff ff       	call   f0101331 <vcprintf>
	va_end(ap);

	return cnt;
}
f010137a:	c9                   	leave  
f010137b:	c3                   	ret    

f010137c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010137c:	55                   	push   %ebp
f010137d:	89 e5                	mov    %esp,%ebp
f010137f:	57                   	push   %edi
f0101380:	56                   	push   %esi
f0101381:	53                   	push   %ebx
f0101382:	83 ec 14             	sub    $0x14,%esp
f0101385:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101388:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010138b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010138e:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101391:	8b 32                	mov    (%edx),%esi
f0101393:	8b 01                	mov    (%ecx),%eax
f0101395:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101398:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010139f:	eb 2f                	jmp    f01013d0 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01013a1:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f01013a4:	39 c6                	cmp    %eax,%esi
f01013a6:	7f 49                	jg     f01013f1 <stab_binsearch+0x75>
f01013a8:	0f b6 0a             	movzbl (%edx),%ecx
f01013ab:	83 ea 0c             	sub    $0xc,%edx
f01013ae:	39 f9                	cmp    %edi,%ecx
f01013b0:	75 ef                	jne    f01013a1 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01013b2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01013b5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01013b8:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01013bc:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01013bf:	73 35                	jae    f01013f6 <stab_binsearch+0x7a>
			*region_left = m;
f01013c1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01013c4:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f01013c6:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f01013c9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01013d0:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f01013d3:	7f 4e                	jg     f0101423 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f01013d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01013d8:	01 f0                	add    %esi,%eax
f01013da:	89 c3                	mov    %eax,%ebx
f01013dc:	c1 eb 1f             	shr    $0x1f,%ebx
f01013df:	01 c3                	add    %eax,%ebx
f01013e1:	d1 fb                	sar    %ebx
f01013e3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01013e6:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01013e9:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01013ed:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f01013ef:	eb b3                	jmp    f01013a4 <stab_binsearch+0x28>
			l = true_m + 1;
f01013f1:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f01013f4:	eb da                	jmp    f01013d0 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f01013f6:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01013f9:	76 14                	jbe    f010140f <stab_binsearch+0x93>
			*region_right = m - 1;
f01013fb:	83 e8 01             	sub    $0x1,%eax
f01013fe:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101401:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101404:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0101406:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010140d:	eb c1                	jmp    f01013d0 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010140f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101412:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0101414:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0101418:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f010141a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101421:	eb ad                	jmp    f01013d0 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0101423:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0101427:	74 16                	je     f010143f <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101429:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010142c:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010142e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101431:	8b 0e                	mov    (%esi),%ecx
f0101433:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101436:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0101439:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f010143d:	eb 12                	jmp    f0101451 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f010143f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101442:	8b 00                	mov    (%eax),%eax
f0101444:	83 e8 01             	sub    $0x1,%eax
f0101447:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010144a:	89 07                	mov    %eax,(%edi)
f010144c:	eb 16                	jmp    f0101464 <stab_binsearch+0xe8>
		     l--)
f010144e:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0101451:	39 c1                	cmp    %eax,%ecx
f0101453:	7d 0a                	jge    f010145f <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0101455:	0f b6 1a             	movzbl (%edx),%ebx
f0101458:	83 ea 0c             	sub    $0xc,%edx
f010145b:	39 fb                	cmp    %edi,%ebx
f010145d:	75 ef                	jne    f010144e <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f010145f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101462:	89 07                	mov    %eax,(%edi)
	}
}
f0101464:	83 c4 14             	add    $0x14,%esp
f0101467:	5b                   	pop    %ebx
f0101468:	5e                   	pop    %esi
f0101469:	5f                   	pop    %edi
f010146a:	5d                   	pop    %ebp
f010146b:	c3                   	ret    

f010146c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010146c:	55                   	push   %ebp
f010146d:	89 e5                	mov    %esp,%ebp
f010146f:	57                   	push   %edi
f0101470:	56                   	push   %esi
f0101471:	53                   	push   %ebx
f0101472:	83 ec 2c             	sub    $0x2c,%esp
f0101475:	e8 fa 01 00 00       	call   f0101674 <__x86.get_pc_thunk.cx>
f010147a:	81 c1 8e 1e 01 00    	add    $0x11e8e,%ecx
f0101480:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101483:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101486:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101489:	8d 81 4c f7 fe ff    	lea    -0x108b4(%ecx),%eax
f010148f:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0101491:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0101498:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f010149b:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f01014a2:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f01014a5:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01014ac:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01014b2:	0f 86 f4 00 00 00    	jbe    f01015ac <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01014b8:	c7 c0 d9 7a 10 f0    	mov    $0xf0107ad9,%eax
f01014be:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f01014c4:	0f 86 88 01 00 00    	jbe    f0101652 <debuginfo_eip+0x1e6>
f01014ca:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01014cd:	c7 c0 fe 97 10 f0    	mov    $0xf01097fe,%eax
f01014d3:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01014d7:	0f 85 7c 01 00 00    	jne    f0101659 <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01014dd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01014e4:	c7 c0 6c 2c 10 f0    	mov    $0xf0102c6c,%eax
f01014ea:	c7 c2 d8 7a 10 f0    	mov    $0xf0107ad8,%edx
f01014f0:	29 c2                	sub    %eax,%edx
f01014f2:	c1 fa 02             	sar    $0x2,%edx
f01014f5:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01014fb:	83 ea 01             	sub    $0x1,%edx
f01014fe:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0101501:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0101504:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0101507:	83 ec 08             	sub    $0x8,%esp
f010150a:	53                   	push   %ebx
f010150b:	6a 64                	push   $0x64
f010150d:	e8 6a fe ff ff       	call   f010137c <stab_binsearch>
	if (lfile == 0)
f0101512:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101515:	83 c4 10             	add    $0x10,%esp
f0101518:	85 c0                	test   %eax,%eax
f010151a:	0f 84 40 01 00 00    	je     f0101660 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0101520:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0101523:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101526:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101529:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010152c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010152f:	83 ec 08             	sub    $0x8,%esp
f0101532:	53                   	push   %ebx
f0101533:	6a 24                	push   $0x24
f0101535:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0101538:	c7 c0 6c 2c 10 f0    	mov    $0xf0102c6c,%eax
f010153e:	e8 39 fe ff ff       	call   f010137c <stab_binsearch>

	if (lfun <= rfun) {
f0101543:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0101546:	83 c4 10             	add    $0x10,%esp
f0101549:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f010154c:	7f 79                	jg     f01015c7 <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010154e:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0101551:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101554:	c7 c2 6c 2c 10 f0    	mov    $0xf0102c6c,%edx
f010155a:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f010155d:	8b 11                	mov    (%ecx),%edx
f010155f:	c7 c0 fe 97 10 f0    	mov    $0xf01097fe,%eax
f0101565:	81 e8 d9 7a 10 f0    	sub    $0xf0107ad9,%eax
f010156b:	39 c2                	cmp    %eax,%edx
f010156d:	73 09                	jae    f0101578 <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010156f:	81 c2 d9 7a 10 f0    	add    $0xf0107ad9,%edx
f0101575:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101578:	8b 41 08             	mov    0x8(%ecx),%eax
f010157b:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010157e:	83 ec 08             	sub    $0x8,%esp
f0101581:	6a 3a                	push   $0x3a
f0101583:	ff 77 08             	pushl  0x8(%edi)
f0101586:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101589:	e8 1e 09 00 00       	call   f0101eac <strfind>
f010158e:	2b 47 08             	sub    0x8(%edi),%eax
f0101591:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101594:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101597:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010159a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010159d:	c7 c2 6c 2c 10 f0    	mov    $0xf0102c6c,%edx
f01015a3:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f01015a7:	83 c4 10             	add    $0x10,%esp
f01015aa:	eb 29                	jmp    f01015d5 <debuginfo_eip+0x169>
  	        panic("User address");
f01015ac:	83 ec 04             	sub    $0x4,%esp
f01015af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01015b2:	8d 83 56 f7 fe ff    	lea    -0x108aa(%ebx),%eax
f01015b8:	50                   	push   %eax
f01015b9:	6a 7f                	push   $0x7f
f01015bb:	8d 83 63 f7 fe ff    	lea    -0x1089d(%ebx),%eax
f01015c1:	50                   	push   %eax
f01015c2:	e8 d2 ea ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f01015c7:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f01015ca:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01015cd:	eb af                	jmp    f010157e <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01015cf:	83 ee 01             	sub    $0x1,%esi
f01015d2:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f01015d5:	39 f3                	cmp    %esi,%ebx
f01015d7:	7f 3a                	jg     f0101613 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f01015d9:	0f b6 10             	movzbl (%eax),%edx
f01015dc:	80 fa 84             	cmp    $0x84,%dl
f01015df:	74 0b                	je     f01015ec <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01015e1:	80 fa 64             	cmp    $0x64,%dl
f01015e4:	75 e9                	jne    f01015cf <debuginfo_eip+0x163>
f01015e6:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f01015ea:	74 e3                	je     f01015cf <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01015ec:	8d 14 76             	lea    (%esi,%esi,2),%edx
f01015ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01015f2:	c7 c0 6c 2c 10 f0    	mov    $0xf0102c6c,%eax
f01015f8:	8b 14 90             	mov    (%eax,%edx,4),%edx
f01015fb:	c7 c0 fe 97 10 f0    	mov    $0xf01097fe,%eax
f0101601:	81 e8 d9 7a 10 f0    	sub    $0xf0107ad9,%eax
f0101607:	39 c2                	cmp    %eax,%edx
f0101609:	73 08                	jae    f0101613 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010160b:	81 c2 d9 7a 10 f0    	add    $0xf0107ad9,%edx
f0101611:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101613:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101616:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101619:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f010161e:	39 cb                	cmp    %ecx,%ebx
f0101620:	7d 4a                	jge    f010166c <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0101622:	8d 53 01             	lea    0x1(%ebx),%edx
f0101625:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f0101628:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010162b:	c7 c0 6c 2c 10 f0    	mov    $0xf0102c6c,%eax
f0101631:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0101635:	eb 07                	jmp    f010163e <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0101637:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f010163b:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f010163e:	39 d1                	cmp    %edx,%ecx
f0101640:	74 25                	je     f0101667 <debuginfo_eip+0x1fb>
f0101642:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101645:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0101649:	74 ec                	je     f0101637 <debuginfo_eip+0x1cb>
	return 0;
f010164b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101650:	eb 1a                	jmp    f010166c <debuginfo_eip+0x200>
		return -1;
f0101652:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101657:	eb 13                	jmp    f010166c <debuginfo_eip+0x200>
f0101659:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010165e:	eb 0c                	jmp    f010166c <debuginfo_eip+0x200>
		return -1;
f0101660:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101665:	eb 05                	jmp    f010166c <debuginfo_eip+0x200>
	return 0;
f0101667:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010166c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010166f:	5b                   	pop    %ebx
f0101670:	5e                   	pop    %esi
f0101671:	5f                   	pop    %edi
f0101672:	5d                   	pop    %ebp
f0101673:	c3                   	ret    

f0101674 <__x86.get_pc_thunk.cx>:
f0101674:	8b 0c 24             	mov    (%esp),%ecx
f0101677:	c3                   	ret    

f0101678 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101678:	55                   	push   %ebp
f0101679:	89 e5                	mov    %esp,%ebp
f010167b:	57                   	push   %edi
f010167c:	56                   	push   %esi
f010167d:	53                   	push   %ebx
f010167e:	83 ec 2c             	sub    $0x2c,%esp
f0101681:	e8 ee ff ff ff       	call   f0101674 <__x86.get_pc_thunk.cx>
f0101686:	81 c1 82 1c 01 00    	add    $0x11c82,%ecx
f010168c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010168f:	89 c7                	mov    %eax,%edi
f0101691:	89 d6                	mov    %edx,%esi
f0101693:	8b 45 08             	mov    0x8(%ebp),%eax
f0101696:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101699:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010169c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010169f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01016a2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01016a7:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f01016aa:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01016ad:	39 d3                	cmp    %edx,%ebx
f01016af:	72 09                	jb     f01016ba <printnum+0x42>
f01016b1:	39 45 10             	cmp    %eax,0x10(%ebp)
f01016b4:	0f 87 83 00 00 00    	ja     f010173d <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01016ba:	83 ec 0c             	sub    $0xc,%esp
f01016bd:	ff 75 18             	pushl  0x18(%ebp)
f01016c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01016c3:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01016c6:	53                   	push   %ebx
f01016c7:	ff 75 10             	pushl  0x10(%ebp)
f01016ca:	83 ec 08             	sub    $0x8,%esp
f01016cd:	ff 75 dc             	pushl  -0x24(%ebp)
f01016d0:	ff 75 d8             	pushl  -0x28(%ebp)
f01016d3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016d6:	ff 75 d0             	pushl  -0x30(%ebp)
f01016d9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01016dc:	e8 ef 09 00 00       	call   f01020d0 <__udivdi3>
f01016e1:	83 c4 18             	add    $0x18,%esp
f01016e4:	52                   	push   %edx
f01016e5:	50                   	push   %eax
f01016e6:	89 f2                	mov    %esi,%edx
f01016e8:	89 f8                	mov    %edi,%eax
f01016ea:	e8 89 ff ff ff       	call   f0101678 <printnum>
f01016ef:	83 c4 20             	add    $0x20,%esp
f01016f2:	eb 13                	jmp    f0101707 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01016f4:	83 ec 08             	sub    $0x8,%esp
f01016f7:	56                   	push   %esi
f01016f8:	ff 75 18             	pushl  0x18(%ebp)
f01016fb:	ff d7                	call   *%edi
f01016fd:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0101700:	83 eb 01             	sub    $0x1,%ebx
f0101703:	85 db                	test   %ebx,%ebx
f0101705:	7f ed                	jg     f01016f4 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101707:	83 ec 08             	sub    $0x8,%esp
f010170a:	56                   	push   %esi
f010170b:	83 ec 04             	sub    $0x4,%esp
f010170e:	ff 75 dc             	pushl  -0x24(%ebp)
f0101711:	ff 75 d8             	pushl  -0x28(%ebp)
f0101714:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101717:	ff 75 d0             	pushl  -0x30(%ebp)
f010171a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010171d:	89 f3                	mov    %esi,%ebx
f010171f:	e8 cc 0a 00 00       	call   f01021f0 <__umoddi3>
f0101724:	83 c4 14             	add    $0x14,%esp
f0101727:	0f be 84 06 71 f7 fe 	movsbl -0x1088f(%esi,%eax,1),%eax
f010172e:	ff 
f010172f:	50                   	push   %eax
f0101730:	ff d7                	call   *%edi
}
f0101732:	83 c4 10             	add    $0x10,%esp
f0101735:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101738:	5b                   	pop    %ebx
f0101739:	5e                   	pop    %esi
f010173a:	5f                   	pop    %edi
f010173b:	5d                   	pop    %ebp
f010173c:	c3                   	ret    
f010173d:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0101740:	eb be                	jmp    f0101700 <printnum+0x88>

f0101742 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101742:	55                   	push   %ebp
f0101743:	89 e5                	mov    %esp,%ebp
f0101745:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101748:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010174c:	8b 10                	mov    (%eax),%edx
f010174e:	3b 50 04             	cmp    0x4(%eax),%edx
f0101751:	73 0a                	jae    f010175d <sprintputch+0x1b>
		*b->buf++ = ch;
f0101753:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101756:	89 08                	mov    %ecx,(%eax)
f0101758:	8b 45 08             	mov    0x8(%ebp),%eax
f010175b:	88 02                	mov    %al,(%edx)
}
f010175d:	5d                   	pop    %ebp
f010175e:	c3                   	ret    

f010175f <printfmt>:
{
f010175f:	55                   	push   %ebp
f0101760:	89 e5                	mov    %esp,%ebp
f0101762:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0101765:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101768:	50                   	push   %eax
f0101769:	ff 75 10             	pushl  0x10(%ebp)
f010176c:	ff 75 0c             	pushl  0xc(%ebp)
f010176f:	ff 75 08             	pushl  0x8(%ebp)
f0101772:	e8 05 00 00 00       	call   f010177c <vprintfmt>
}
f0101777:	83 c4 10             	add    $0x10,%esp
f010177a:	c9                   	leave  
f010177b:	c3                   	ret    

f010177c <vprintfmt>:
{
f010177c:	55                   	push   %ebp
f010177d:	89 e5                	mov    %esp,%ebp
f010177f:	57                   	push   %edi
f0101780:	56                   	push   %esi
f0101781:	53                   	push   %ebx
f0101782:	83 ec 2c             	sub    $0x2c,%esp
f0101785:	e8 c5 e9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010178a:	81 c3 7e 1b 01 00    	add    $0x11b7e,%ebx
f0101790:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101793:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101796:	e9 8e 03 00 00       	jmp    f0101b29 <.L35+0x48>
		padc = ' ';
f010179b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f010179f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01017a6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f01017ad:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01017b4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01017b9:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01017bc:	8d 47 01             	lea    0x1(%edi),%eax
f01017bf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01017c2:	0f b6 17             	movzbl (%edi),%edx
f01017c5:	8d 42 dd             	lea    -0x23(%edx),%eax
f01017c8:	3c 55                	cmp    $0x55,%al
f01017ca:	0f 87 e1 03 00 00    	ja     f0101bb1 <.L22>
f01017d0:	0f b6 c0             	movzbl %al,%eax
f01017d3:	89 d9                	mov    %ebx,%ecx
f01017d5:	03 8c 83 fc f7 fe ff 	add    -0x10804(%ebx,%eax,4),%ecx
f01017dc:	ff e1                	jmp    *%ecx

f01017de <.L67>:
f01017de:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01017e1:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01017e5:	eb d5                	jmp    f01017bc <vprintfmt+0x40>

f01017e7 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f01017e7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f01017ea:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01017ee:	eb cc                	jmp    f01017bc <vprintfmt+0x40>

f01017f0 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f01017f0:	0f b6 d2             	movzbl %dl,%edx
f01017f3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f01017f6:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f01017fb:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01017fe:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0101802:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0101805:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0101808:	83 f9 09             	cmp    $0x9,%ecx
f010180b:	77 55                	ja     f0101862 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f010180d:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0101810:	eb e9                	jmp    f01017fb <.L29+0xb>

f0101812 <.L26>:
			precision = va_arg(ap, int);
f0101812:	8b 45 14             	mov    0x14(%ebp),%eax
f0101815:	8b 00                	mov    (%eax),%eax
f0101817:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010181a:	8b 45 14             	mov    0x14(%ebp),%eax
f010181d:	8d 40 04             	lea    0x4(%eax),%eax
f0101820:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101823:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0101826:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010182a:	79 90                	jns    f01017bc <vprintfmt+0x40>
				width = precision, precision = -1;
f010182c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010182f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101832:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101839:	eb 81                	jmp    f01017bc <vprintfmt+0x40>

f010183b <.L27>:
f010183b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010183e:	85 c0                	test   %eax,%eax
f0101840:	ba 00 00 00 00       	mov    $0x0,%edx
f0101845:	0f 49 d0             	cmovns %eax,%edx
f0101848:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010184b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010184e:	e9 69 ff ff ff       	jmp    f01017bc <vprintfmt+0x40>

f0101853 <.L23>:
f0101853:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0101856:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010185d:	e9 5a ff ff ff       	jmp    f01017bc <vprintfmt+0x40>
f0101862:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101865:	eb bf                	jmp    f0101826 <.L26+0x14>

f0101867 <.L33>:
			lflag++;
f0101867:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010186b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010186e:	e9 49 ff ff ff       	jmp    f01017bc <vprintfmt+0x40>

f0101873 <.L30>:
			putch(va_arg(ap, int), putdat);
f0101873:	8b 45 14             	mov    0x14(%ebp),%eax
f0101876:	8d 78 04             	lea    0x4(%eax),%edi
f0101879:	83 ec 08             	sub    $0x8,%esp
f010187c:	56                   	push   %esi
f010187d:	ff 30                	pushl  (%eax)
f010187f:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101882:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0101885:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0101888:	e9 99 02 00 00       	jmp    f0101b26 <.L35+0x45>

f010188d <.L32>:
			err = va_arg(ap, int);
f010188d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101890:	8d 78 04             	lea    0x4(%eax),%edi
f0101893:	8b 00                	mov    (%eax),%eax
f0101895:	99                   	cltd   
f0101896:	31 d0                	xor    %edx,%eax
f0101898:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010189a:	83 f8 06             	cmp    $0x6,%eax
f010189d:	7f 27                	jg     f01018c6 <.L32+0x39>
f010189f:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f01018a6:	85 d2                	test   %edx,%edx
f01018a8:	74 1c                	je     f01018c6 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01018aa:	52                   	push   %edx
f01018ab:	8d 83 d6 f4 fe ff    	lea    -0x10b2a(%ebx),%eax
f01018b1:	50                   	push   %eax
f01018b2:	56                   	push   %esi
f01018b3:	ff 75 08             	pushl  0x8(%ebp)
f01018b6:	e8 a4 fe ff ff       	call   f010175f <printfmt>
f01018bb:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01018be:	89 7d 14             	mov    %edi,0x14(%ebp)
f01018c1:	e9 60 02 00 00       	jmp    f0101b26 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f01018c6:	50                   	push   %eax
f01018c7:	8d 83 89 f7 fe ff    	lea    -0x10877(%ebx),%eax
f01018cd:	50                   	push   %eax
f01018ce:	56                   	push   %esi
f01018cf:	ff 75 08             	pushl  0x8(%ebp)
f01018d2:	e8 88 fe ff ff       	call   f010175f <printfmt>
f01018d7:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01018da:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01018dd:	e9 44 02 00 00       	jmp    f0101b26 <.L35+0x45>

f01018e2 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f01018e2:	8b 45 14             	mov    0x14(%ebp),%eax
f01018e5:	83 c0 04             	add    $0x4,%eax
f01018e8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01018eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01018ee:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01018f0:	85 ff                	test   %edi,%edi
f01018f2:	8d 83 82 f7 fe ff    	lea    -0x1087e(%ebx),%eax
f01018f8:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01018fb:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01018ff:	0f 8e b5 00 00 00    	jle    f01019ba <.L36+0xd8>
f0101905:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101909:	75 08                	jne    f0101913 <.L36+0x31>
f010190b:	89 75 0c             	mov    %esi,0xc(%ebp)
f010190e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101911:	eb 6d                	jmp    f0101980 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101913:	83 ec 08             	sub    $0x8,%esp
f0101916:	ff 75 d0             	pushl  -0x30(%ebp)
f0101919:	57                   	push   %edi
f010191a:	e8 49 04 00 00       	call   f0101d68 <strnlen>
f010191f:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101922:	29 c2                	sub    %eax,%edx
f0101924:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0101927:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010192a:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010192e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101931:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101934:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101936:	eb 10                	jmp    f0101948 <.L36+0x66>
					putch(padc, putdat);
f0101938:	83 ec 08             	sub    $0x8,%esp
f010193b:	56                   	push   %esi
f010193c:	ff 75 e0             	pushl  -0x20(%ebp)
f010193f:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101942:	83 ef 01             	sub    $0x1,%edi
f0101945:	83 c4 10             	add    $0x10,%esp
f0101948:	85 ff                	test   %edi,%edi
f010194a:	7f ec                	jg     f0101938 <.L36+0x56>
f010194c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010194f:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0101952:	85 d2                	test   %edx,%edx
f0101954:	b8 00 00 00 00       	mov    $0x0,%eax
f0101959:	0f 49 c2             	cmovns %edx,%eax
f010195c:	29 c2                	sub    %eax,%edx
f010195e:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101961:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101964:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101967:	eb 17                	jmp    f0101980 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0101969:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010196d:	75 30                	jne    f010199f <.L36+0xbd>
					putch(ch, putdat);
f010196f:	83 ec 08             	sub    $0x8,%esp
f0101972:	ff 75 0c             	pushl  0xc(%ebp)
f0101975:	50                   	push   %eax
f0101976:	ff 55 08             	call   *0x8(%ebp)
f0101979:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010197c:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101980:	83 c7 01             	add    $0x1,%edi
f0101983:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101987:	0f be c2             	movsbl %dl,%eax
f010198a:	85 c0                	test   %eax,%eax
f010198c:	74 52                	je     f01019e0 <.L36+0xfe>
f010198e:	85 f6                	test   %esi,%esi
f0101990:	78 d7                	js     f0101969 <.L36+0x87>
f0101992:	83 ee 01             	sub    $0x1,%esi
f0101995:	79 d2                	jns    f0101969 <.L36+0x87>
f0101997:	8b 75 0c             	mov    0xc(%ebp),%esi
f010199a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010199d:	eb 32                	jmp    f01019d1 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f010199f:	0f be d2             	movsbl %dl,%edx
f01019a2:	83 ea 20             	sub    $0x20,%edx
f01019a5:	83 fa 5e             	cmp    $0x5e,%edx
f01019a8:	76 c5                	jbe    f010196f <.L36+0x8d>
					putch('?', putdat);
f01019aa:	83 ec 08             	sub    $0x8,%esp
f01019ad:	ff 75 0c             	pushl  0xc(%ebp)
f01019b0:	6a 3f                	push   $0x3f
f01019b2:	ff 55 08             	call   *0x8(%ebp)
f01019b5:	83 c4 10             	add    $0x10,%esp
f01019b8:	eb c2                	jmp    f010197c <.L36+0x9a>
f01019ba:	89 75 0c             	mov    %esi,0xc(%ebp)
f01019bd:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01019c0:	eb be                	jmp    f0101980 <.L36+0x9e>
				putch(' ', putdat);
f01019c2:	83 ec 08             	sub    $0x8,%esp
f01019c5:	56                   	push   %esi
f01019c6:	6a 20                	push   $0x20
f01019c8:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01019cb:	83 ef 01             	sub    $0x1,%edi
f01019ce:	83 c4 10             	add    $0x10,%esp
f01019d1:	85 ff                	test   %edi,%edi
f01019d3:	7f ed                	jg     f01019c2 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01019d5:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01019d8:	89 45 14             	mov    %eax,0x14(%ebp)
f01019db:	e9 46 01 00 00       	jmp    f0101b26 <.L35+0x45>
f01019e0:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01019e3:	8b 75 0c             	mov    0xc(%ebp),%esi
f01019e6:	eb e9                	jmp    f01019d1 <.L36+0xef>

f01019e8 <.L31>:
f01019e8:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f01019eb:	83 f9 01             	cmp    $0x1,%ecx
f01019ee:	7e 40                	jle    f0101a30 <.L31+0x48>
		return va_arg(*ap, long long);
f01019f0:	8b 45 14             	mov    0x14(%ebp),%eax
f01019f3:	8b 50 04             	mov    0x4(%eax),%edx
f01019f6:	8b 00                	mov    (%eax),%eax
f01019f8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01019fb:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01019fe:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a01:	8d 40 08             	lea    0x8(%eax),%eax
f0101a04:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101a07:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101a0b:	79 55                	jns    f0101a62 <.L31+0x7a>
				putch('-', putdat);
f0101a0d:	83 ec 08             	sub    $0x8,%esp
f0101a10:	56                   	push   %esi
f0101a11:	6a 2d                	push   $0x2d
f0101a13:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101a16:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101a19:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101a1c:	f7 da                	neg    %edx
f0101a1e:	83 d1 00             	adc    $0x0,%ecx
f0101a21:	f7 d9                	neg    %ecx
f0101a23:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101a26:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101a2b:	e9 db 00 00 00       	jmp    f0101b0b <.L35+0x2a>
	else if (lflag)
f0101a30:	85 c9                	test   %ecx,%ecx
f0101a32:	75 17                	jne    f0101a4b <.L31+0x63>
		return va_arg(*ap, int);
f0101a34:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a37:	8b 00                	mov    (%eax),%eax
f0101a39:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101a3c:	99                   	cltd   
f0101a3d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101a40:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a43:	8d 40 04             	lea    0x4(%eax),%eax
f0101a46:	89 45 14             	mov    %eax,0x14(%ebp)
f0101a49:	eb bc                	jmp    f0101a07 <.L31+0x1f>
		return va_arg(*ap, long);
f0101a4b:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a4e:	8b 00                	mov    (%eax),%eax
f0101a50:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101a53:	99                   	cltd   
f0101a54:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101a57:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a5a:	8d 40 04             	lea    0x4(%eax),%eax
f0101a5d:	89 45 14             	mov    %eax,0x14(%ebp)
f0101a60:	eb a5                	jmp    f0101a07 <.L31+0x1f>
			num = getint(&ap, lflag);
f0101a62:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101a65:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101a68:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101a6d:	e9 99 00 00 00       	jmp    f0101b0b <.L35+0x2a>

f0101a72 <.L37>:
f0101a72:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101a75:	83 f9 01             	cmp    $0x1,%ecx
f0101a78:	7e 15                	jle    f0101a8f <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f0101a7a:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a7d:	8b 10                	mov    (%eax),%edx
f0101a7f:	8b 48 04             	mov    0x4(%eax),%ecx
f0101a82:	8d 40 08             	lea    0x8(%eax),%eax
f0101a85:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101a88:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101a8d:	eb 7c                	jmp    f0101b0b <.L35+0x2a>
	else if (lflag)
f0101a8f:	85 c9                	test   %ecx,%ecx
f0101a91:	75 17                	jne    f0101aaa <.L37+0x38>
		return va_arg(*ap, unsigned int);
f0101a93:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a96:	8b 10                	mov    (%eax),%edx
f0101a98:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101a9d:	8d 40 04             	lea    0x4(%eax),%eax
f0101aa0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101aa3:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101aa8:	eb 61                	jmp    f0101b0b <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101aaa:	8b 45 14             	mov    0x14(%ebp),%eax
f0101aad:	8b 10                	mov    (%eax),%edx
f0101aaf:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101ab4:	8d 40 04             	lea    0x4(%eax),%eax
f0101ab7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101aba:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101abf:	eb 4a                	jmp    f0101b0b <.L35+0x2a>

f0101ac1 <.L34>:
			putch('X', putdat);
f0101ac1:	83 ec 08             	sub    $0x8,%esp
f0101ac4:	56                   	push   %esi
f0101ac5:	6a 58                	push   $0x58
f0101ac7:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0101aca:	83 c4 08             	add    $0x8,%esp
f0101acd:	56                   	push   %esi
f0101ace:	6a 58                	push   $0x58
f0101ad0:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0101ad3:	83 c4 08             	add    $0x8,%esp
f0101ad6:	56                   	push   %esi
f0101ad7:	6a 58                	push   $0x58
f0101ad9:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101adc:	83 c4 10             	add    $0x10,%esp
f0101adf:	eb 45                	jmp    f0101b26 <.L35+0x45>

f0101ae1 <.L35>:
			putch('0', putdat);
f0101ae1:	83 ec 08             	sub    $0x8,%esp
f0101ae4:	56                   	push   %esi
f0101ae5:	6a 30                	push   $0x30
f0101ae7:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101aea:	83 c4 08             	add    $0x8,%esp
f0101aed:	56                   	push   %esi
f0101aee:	6a 78                	push   $0x78
f0101af0:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0101af3:	8b 45 14             	mov    0x14(%ebp),%eax
f0101af6:	8b 10                	mov    (%eax),%edx
f0101af8:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0101afd:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101b00:	8d 40 04             	lea    0x4(%eax),%eax
f0101b03:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101b06:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0101b0b:	83 ec 0c             	sub    $0xc,%esp
f0101b0e:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101b12:	57                   	push   %edi
f0101b13:	ff 75 e0             	pushl  -0x20(%ebp)
f0101b16:	50                   	push   %eax
f0101b17:	51                   	push   %ecx
f0101b18:	52                   	push   %edx
f0101b19:	89 f2                	mov    %esi,%edx
f0101b1b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b1e:	e8 55 fb ff ff       	call   f0101678 <printnum>
			break;
f0101b23:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0101b26:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101b29:	83 c7 01             	add    $0x1,%edi
f0101b2c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101b30:	83 f8 25             	cmp    $0x25,%eax
f0101b33:	0f 84 62 fc ff ff    	je     f010179b <vprintfmt+0x1f>
			if (ch == '\0')
f0101b39:	85 c0                	test   %eax,%eax
f0101b3b:	0f 84 91 00 00 00    	je     f0101bd2 <.L22+0x21>
			putch(ch, putdat);
f0101b41:	83 ec 08             	sub    $0x8,%esp
f0101b44:	56                   	push   %esi
f0101b45:	50                   	push   %eax
f0101b46:	ff 55 08             	call   *0x8(%ebp)
f0101b49:	83 c4 10             	add    $0x10,%esp
f0101b4c:	eb db                	jmp    f0101b29 <.L35+0x48>

f0101b4e <.L38>:
f0101b4e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101b51:	83 f9 01             	cmp    $0x1,%ecx
f0101b54:	7e 15                	jle    f0101b6b <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0101b56:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b59:	8b 10                	mov    (%eax),%edx
f0101b5b:	8b 48 04             	mov    0x4(%eax),%ecx
f0101b5e:	8d 40 08             	lea    0x8(%eax),%eax
f0101b61:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101b64:	b8 10 00 00 00       	mov    $0x10,%eax
f0101b69:	eb a0                	jmp    f0101b0b <.L35+0x2a>
	else if (lflag)
f0101b6b:	85 c9                	test   %ecx,%ecx
f0101b6d:	75 17                	jne    f0101b86 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0101b6f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b72:	8b 10                	mov    (%eax),%edx
f0101b74:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101b79:	8d 40 04             	lea    0x4(%eax),%eax
f0101b7c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101b7f:	b8 10 00 00 00       	mov    $0x10,%eax
f0101b84:	eb 85                	jmp    f0101b0b <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101b86:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b89:	8b 10                	mov    (%eax),%edx
f0101b8b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101b90:	8d 40 04             	lea    0x4(%eax),%eax
f0101b93:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101b96:	b8 10 00 00 00       	mov    $0x10,%eax
f0101b9b:	e9 6b ff ff ff       	jmp    f0101b0b <.L35+0x2a>

f0101ba0 <.L25>:
			putch(ch, putdat);
f0101ba0:	83 ec 08             	sub    $0x8,%esp
f0101ba3:	56                   	push   %esi
f0101ba4:	6a 25                	push   $0x25
f0101ba6:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101ba9:	83 c4 10             	add    $0x10,%esp
f0101bac:	e9 75 ff ff ff       	jmp    f0101b26 <.L35+0x45>

f0101bb1 <.L22>:
			putch('%', putdat);
f0101bb1:	83 ec 08             	sub    $0x8,%esp
f0101bb4:	56                   	push   %esi
f0101bb5:	6a 25                	push   $0x25
f0101bb7:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101bba:	83 c4 10             	add    $0x10,%esp
f0101bbd:	89 f8                	mov    %edi,%eax
f0101bbf:	eb 03                	jmp    f0101bc4 <.L22+0x13>
f0101bc1:	83 e8 01             	sub    $0x1,%eax
f0101bc4:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0101bc8:	75 f7                	jne    f0101bc1 <.L22+0x10>
f0101bca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101bcd:	e9 54 ff ff ff       	jmp    f0101b26 <.L35+0x45>
}
f0101bd2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101bd5:	5b                   	pop    %ebx
f0101bd6:	5e                   	pop    %esi
f0101bd7:	5f                   	pop    %edi
f0101bd8:	5d                   	pop    %ebp
f0101bd9:	c3                   	ret    

f0101bda <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101bda:	55                   	push   %ebp
f0101bdb:	89 e5                	mov    %esp,%ebp
f0101bdd:	53                   	push   %ebx
f0101bde:	83 ec 14             	sub    $0x14,%esp
f0101be1:	e8 69 e5 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101be6:	81 c3 22 17 01 00    	add    $0x11722,%ebx
f0101bec:	8b 45 08             	mov    0x8(%ebp),%eax
f0101bef:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101bf2:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101bf5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101bf9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101bfc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101c03:	85 c0                	test   %eax,%eax
f0101c05:	74 2b                	je     f0101c32 <vsnprintf+0x58>
f0101c07:	85 d2                	test   %edx,%edx
f0101c09:	7e 27                	jle    f0101c32 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101c0b:	ff 75 14             	pushl  0x14(%ebp)
f0101c0e:	ff 75 10             	pushl  0x10(%ebp)
f0101c11:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101c14:	50                   	push   %eax
f0101c15:	8d 83 3a e4 fe ff    	lea    -0x11bc6(%ebx),%eax
f0101c1b:	50                   	push   %eax
f0101c1c:	e8 5b fb ff ff       	call   f010177c <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101c21:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101c24:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101c27:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101c2a:	83 c4 10             	add    $0x10,%esp
}
f0101c2d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101c30:	c9                   	leave  
f0101c31:	c3                   	ret    
		return -E_INVAL;
f0101c32:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101c37:	eb f4                	jmp    f0101c2d <vsnprintf+0x53>

f0101c39 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101c39:	55                   	push   %ebp
f0101c3a:	89 e5                	mov    %esp,%ebp
f0101c3c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101c3f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101c42:	50                   	push   %eax
f0101c43:	ff 75 10             	pushl  0x10(%ebp)
f0101c46:	ff 75 0c             	pushl  0xc(%ebp)
f0101c49:	ff 75 08             	pushl  0x8(%ebp)
f0101c4c:	e8 89 ff ff ff       	call   f0101bda <vsnprintf>
	va_end(ap);

	return rc;
}
f0101c51:	c9                   	leave  
f0101c52:	c3                   	ret    

f0101c53 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101c53:	55                   	push   %ebp
f0101c54:	89 e5                	mov    %esp,%ebp
f0101c56:	57                   	push   %edi
f0101c57:	56                   	push   %esi
f0101c58:	53                   	push   %ebx
f0101c59:	83 ec 1c             	sub    $0x1c,%esp
f0101c5c:	e8 ee e4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101c61:	81 c3 a7 16 01 00    	add    $0x116a7,%ebx
f0101c67:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101c6a:	85 c0                	test   %eax,%eax
f0101c6c:	74 13                	je     f0101c81 <readline+0x2e>
		cprintf("%s", prompt);
f0101c6e:	83 ec 08             	sub    $0x8,%esp
f0101c71:	50                   	push   %eax
f0101c72:	8d 83 d6 f4 fe ff    	lea    -0x10b2a(%ebx),%eax
f0101c78:	50                   	push   %eax
f0101c79:	e8 ea f6 ff ff       	call   f0101368 <cprintf>
f0101c7e:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101c81:	83 ec 0c             	sub    $0xc,%esp
f0101c84:	6a 00                	push   $0x0
f0101c86:	e8 5c ea ff ff       	call   f01006e7 <iscons>
f0101c8b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101c8e:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0101c91:	bf 00 00 00 00       	mov    $0x0,%edi
f0101c96:	eb 46                	jmp    f0101cde <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0101c98:	83 ec 08             	sub    $0x8,%esp
f0101c9b:	50                   	push   %eax
f0101c9c:	8d 83 54 f9 fe ff    	lea    -0x106ac(%ebx),%eax
f0101ca2:	50                   	push   %eax
f0101ca3:	e8 c0 f6 ff ff       	call   f0101368 <cprintf>
			return NULL;
f0101ca8:	83 c4 10             	add    $0x10,%esp
f0101cab:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0101cb0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101cb3:	5b                   	pop    %ebx
f0101cb4:	5e                   	pop    %esi
f0101cb5:	5f                   	pop    %edi
f0101cb6:	5d                   	pop    %ebp
f0101cb7:	c3                   	ret    
			if (echoing)
f0101cb8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101cbc:	75 05                	jne    f0101cc3 <readline+0x70>
			i--;
f0101cbe:	83 ef 01             	sub    $0x1,%edi
f0101cc1:	eb 1b                	jmp    f0101cde <readline+0x8b>
				cputchar('\b');
f0101cc3:	83 ec 0c             	sub    $0xc,%esp
f0101cc6:	6a 08                	push   $0x8
f0101cc8:	e8 f9 e9 ff ff       	call   f01006c6 <cputchar>
f0101ccd:	83 c4 10             	add    $0x10,%esp
f0101cd0:	eb ec                	jmp    f0101cbe <readline+0x6b>
			buf[i++] = c;
f0101cd2:	89 f0                	mov    %esi,%eax
f0101cd4:	88 84 3b b8 1f 00 00 	mov    %al,0x1fb8(%ebx,%edi,1)
f0101cdb:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0101cde:	e8 f3 e9 ff ff       	call   f01006d6 <getchar>
f0101ce3:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0101ce5:	85 c0                	test   %eax,%eax
f0101ce7:	78 af                	js     f0101c98 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101ce9:	83 f8 08             	cmp    $0x8,%eax
f0101cec:	0f 94 c2             	sete   %dl
f0101cef:	83 f8 7f             	cmp    $0x7f,%eax
f0101cf2:	0f 94 c0             	sete   %al
f0101cf5:	08 c2                	or     %al,%dl
f0101cf7:	74 04                	je     f0101cfd <readline+0xaa>
f0101cf9:	85 ff                	test   %edi,%edi
f0101cfb:	7f bb                	jg     f0101cb8 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101cfd:	83 fe 1f             	cmp    $0x1f,%esi
f0101d00:	7e 1c                	jle    f0101d1e <readline+0xcb>
f0101d02:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0101d08:	7f 14                	jg     f0101d1e <readline+0xcb>
			if (echoing)
f0101d0a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101d0e:	74 c2                	je     f0101cd2 <readline+0x7f>
				cputchar(c);
f0101d10:	83 ec 0c             	sub    $0xc,%esp
f0101d13:	56                   	push   %esi
f0101d14:	e8 ad e9 ff ff       	call   f01006c6 <cputchar>
f0101d19:	83 c4 10             	add    $0x10,%esp
f0101d1c:	eb b4                	jmp    f0101cd2 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0101d1e:	83 fe 0a             	cmp    $0xa,%esi
f0101d21:	74 05                	je     f0101d28 <readline+0xd5>
f0101d23:	83 fe 0d             	cmp    $0xd,%esi
f0101d26:	75 b6                	jne    f0101cde <readline+0x8b>
			if (echoing)
f0101d28:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101d2c:	75 13                	jne    f0101d41 <readline+0xee>
			buf[i] = 0;
f0101d2e:	c6 84 3b b8 1f 00 00 	movb   $0x0,0x1fb8(%ebx,%edi,1)
f0101d35:	00 
			return buf;
f0101d36:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f0101d3c:	e9 6f ff ff ff       	jmp    f0101cb0 <readline+0x5d>
				cputchar('\n');
f0101d41:	83 ec 0c             	sub    $0xc,%esp
f0101d44:	6a 0a                	push   $0xa
f0101d46:	e8 7b e9 ff ff       	call   f01006c6 <cputchar>
f0101d4b:	83 c4 10             	add    $0x10,%esp
f0101d4e:	eb de                	jmp    f0101d2e <readline+0xdb>

f0101d50 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101d50:	55                   	push   %ebp
f0101d51:	89 e5                	mov    %esp,%ebp
f0101d53:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101d56:	b8 00 00 00 00       	mov    $0x0,%eax
f0101d5b:	eb 03                	jmp    f0101d60 <strlen+0x10>
		n++;
f0101d5d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0101d60:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101d64:	75 f7                	jne    f0101d5d <strlen+0xd>
	return n;
}
f0101d66:	5d                   	pop    %ebp
f0101d67:	c3                   	ret    

f0101d68 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101d68:	55                   	push   %ebp
f0101d69:	89 e5                	mov    %esp,%ebp
f0101d6b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101d6e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101d71:	b8 00 00 00 00       	mov    $0x0,%eax
f0101d76:	eb 03                	jmp    f0101d7b <strnlen+0x13>
		n++;
f0101d78:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101d7b:	39 d0                	cmp    %edx,%eax
f0101d7d:	74 06                	je     f0101d85 <strnlen+0x1d>
f0101d7f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101d83:	75 f3                	jne    f0101d78 <strnlen+0x10>
	return n;
}
f0101d85:	5d                   	pop    %ebp
f0101d86:	c3                   	ret    

f0101d87 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101d87:	55                   	push   %ebp
f0101d88:	89 e5                	mov    %esp,%ebp
f0101d8a:	53                   	push   %ebx
f0101d8b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d8e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101d91:	89 c2                	mov    %eax,%edx
f0101d93:	83 c1 01             	add    $0x1,%ecx
f0101d96:	83 c2 01             	add    $0x1,%edx
f0101d99:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101d9d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101da0:	84 db                	test   %bl,%bl
f0101da2:	75 ef                	jne    f0101d93 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101da4:	5b                   	pop    %ebx
f0101da5:	5d                   	pop    %ebp
f0101da6:	c3                   	ret    

f0101da7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101da7:	55                   	push   %ebp
f0101da8:	89 e5                	mov    %esp,%ebp
f0101daa:	53                   	push   %ebx
f0101dab:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101dae:	53                   	push   %ebx
f0101daf:	e8 9c ff ff ff       	call   f0101d50 <strlen>
f0101db4:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101db7:	ff 75 0c             	pushl  0xc(%ebp)
f0101dba:	01 d8                	add    %ebx,%eax
f0101dbc:	50                   	push   %eax
f0101dbd:	e8 c5 ff ff ff       	call   f0101d87 <strcpy>
	return dst;
}
f0101dc2:	89 d8                	mov    %ebx,%eax
f0101dc4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101dc7:	c9                   	leave  
f0101dc8:	c3                   	ret    

f0101dc9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101dc9:	55                   	push   %ebp
f0101dca:	89 e5                	mov    %esp,%ebp
f0101dcc:	56                   	push   %esi
f0101dcd:	53                   	push   %ebx
f0101dce:	8b 75 08             	mov    0x8(%ebp),%esi
f0101dd1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101dd4:	89 f3                	mov    %esi,%ebx
f0101dd6:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101dd9:	89 f2                	mov    %esi,%edx
f0101ddb:	eb 0f                	jmp    f0101dec <strncpy+0x23>
		*dst++ = *src;
f0101ddd:	83 c2 01             	add    $0x1,%edx
f0101de0:	0f b6 01             	movzbl (%ecx),%eax
f0101de3:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101de6:	80 39 01             	cmpb   $0x1,(%ecx)
f0101de9:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101dec:	39 da                	cmp    %ebx,%edx
f0101dee:	75 ed                	jne    f0101ddd <strncpy+0x14>
	}
	return ret;
}
f0101df0:	89 f0                	mov    %esi,%eax
f0101df2:	5b                   	pop    %ebx
f0101df3:	5e                   	pop    %esi
f0101df4:	5d                   	pop    %ebp
f0101df5:	c3                   	ret    

f0101df6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101df6:	55                   	push   %ebp
f0101df7:	89 e5                	mov    %esp,%ebp
f0101df9:	56                   	push   %esi
f0101dfa:	53                   	push   %ebx
f0101dfb:	8b 75 08             	mov    0x8(%ebp),%esi
f0101dfe:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101e01:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101e04:	89 f0                	mov    %esi,%eax
f0101e06:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101e0a:	85 c9                	test   %ecx,%ecx
f0101e0c:	75 0b                	jne    f0101e19 <strlcpy+0x23>
f0101e0e:	eb 17                	jmp    f0101e27 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101e10:	83 c2 01             	add    $0x1,%edx
f0101e13:	83 c0 01             	add    $0x1,%eax
f0101e16:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101e19:	39 d8                	cmp    %ebx,%eax
f0101e1b:	74 07                	je     f0101e24 <strlcpy+0x2e>
f0101e1d:	0f b6 0a             	movzbl (%edx),%ecx
f0101e20:	84 c9                	test   %cl,%cl
f0101e22:	75 ec                	jne    f0101e10 <strlcpy+0x1a>
		*dst = '\0';
f0101e24:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101e27:	29 f0                	sub    %esi,%eax
}
f0101e29:	5b                   	pop    %ebx
f0101e2a:	5e                   	pop    %esi
f0101e2b:	5d                   	pop    %ebp
f0101e2c:	c3                   	ret    

f0101e2d <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101e2d:	55                   	push   %ebp
f0101e2e:	89 e5                	mov    %esp,%ebp
f0101e30:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101e33:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101e36:	eb 06                	jmp    f0101e3e <strcmp+0x11>
		p++, q++;
f0101e38:	83 c1 01             	add    $0x1,%ecx
f0101e3b:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101e3e:	0f b6 01             	movzbl (%ecx),%eax
f0101e41:	84 c0                	test   %al,%al
f0101e43:	74 04                	je     f0101e49 <strcmp+0x1c>
f0101e45:	3a 02                	cmp    (%edx),%al
f0101e47:	74 ef                	je     f0101e38 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101e49:	0f b6 c0             	movzbl %al,%eax
f0101e4c:	0f b6 12             	movzbl (%edx),%edx
f0101e4f:	29 d0                	sub    %edx,%eax
}
f0101e51:	5d                   	pop    %ebp
f0101e52:	c3                   	ret    

f0101e53 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101e53:	55                   	push   %ebp
f0101e54:	89 e5                	mov    %esp,%ebp
f0101e56:	53                   	push   %ebx
f0101e57:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e5a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101e5d:	89 c3                	mov    %eax,%ebx
f0101e5f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101e62:	eb 06                	jmp    f0101e6a <strncmp+0x17>
		n--, p++, q++;
f0101e64:	83 c0 01             	add    $0x1,%eax
f0101e67:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101e6a:	39 d8                	cmp    %ebx,%eax
f0101e6c:	74 16                	je     f0101e84 <strncmp+0x31>
f0101e6e:	0f b6 08             	movzbl (%eax),%ecx
f0101e71:	84 c9                	test   %cl,%cl
f0101e73:	74 04                	je     f0101e79 <strncmp+0x26>
f0101e75:	3a 0a                	cmp    (%edx),%cl
f0101e77:	74 eb                	je     f0101e64 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101e79:	0f b6 00             	movzbl (%eax),%eax
f0101e7c:	0f b6 12             	movzbl (%edx),%edx
f0101e7f:	29 d0                	sub    %edx,%eax
}
f0101e81:	5b                   	pop    %ebx
f0101e82:	5d                   	pop    %ebp
f0101e83:	c3                   	ret    
		return 0;
f0101e84:	b8 00 00 00 00       	mov    $0x0,%eax
f0101e89:	eb f6                	jmp    f0101e81 <strncmp+0x2e>

f0101e8b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101e8b:	55                   	push   %ebp
f0101e8c:	89 e5                	mov    %esp,%ebp
f0101e8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e91:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101e95:	0f b6 10             	movzbl (%eax),%edx
f0101e98:	84 d2                	test   %dl,%dl
f0101e9a:	74 09                	je     f0101ea5 <strchr+0x1a>
		if (*s == c)
f0101e9c:	38 ca                	cmp    %cl,%dl
f0101e9e:	74 0a                	je     f0101eaa <strchr+0x1f>
	for (; *s; s++)
f0101ea0:	83 c0 01             	add    $0x1,%eax
f0101ea3:	eb f0                	jmp    f0101e95 <strchr+0xa>
			return (char *) s;
	return 0;
f0101ea5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101eaa:	5d                   	pop    %ebp
f0101eab:	c3                   	ret    

f0101eac <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101eac:	55                   	push   %ebp
f0101ead:	89 e5                	mov    %esp,%ebp
f0101eaf:	8b 45 08             	mov    0x8(%ebp),%eax
f0101eb2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101eb6:	eb 03                	jmp    f0101ebb <strfind+0xf>
f0101eb8:	83 c0 01             	add    $0x1,%eax
f0101ebb:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101ebe:	38 ca                	cmp    %cl,%dl
f0101ec0:	74 04                	je     f0101ec6 <strfind+0x1a>
f0101ec2:	84 d2                	test   %dl,%dl
f0101ec4:	75 f2                	jne    f0101eb8 <strfind+0xc>
			break;
	return (char *) s;
}
f0101ec6:	5d                   	pop    %ebp
f0101ec7:	c3                   	ret    

f0101ec8 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101ec8:	55                   	push   %ebp
f0101ec9:	89 e5                	mov    %esp,%ebp
f0101ecb:	57                   	push   %edi
f0101ecc:	56                   	push   %esi
f0101ecd:	53                   	push   %ebx
f0101ece:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101ed1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101ed4:	85 c9                	test   %ecx,%ecx
f0101ed6:	74 13                	je     f0101eeb <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101ed8:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101ede:	75 05                	jne    f0101ee5 <memset+0x1d>
f0101ee0:	f6 c1 03             	test   $0x3,%cl
f0101ee3:	74 0d                	je     f0101ef2 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101ee5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101ee8:	fc                   	cld    
f0101ee9:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101eeb:	89 f8                	mov    %edi,%eax
f0101eed:	5b                   	pop    %ebx
f0101eee:	5e                   	pop    %esi
f0101eef:	5f                   	pop    %edi
f0101ef0:	5d                   	pop    %ebp
f0101ef1:	c3                   	ret    
		c &= 0xFF;
f0101ef2:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101ef6:	89 d3                	mov    %edx,%ebx
f0101ef8:	c1 e3 08             	shl    $0x8,%ebx
f0101efb:	89 d0                	mov    %edx,%eax
f0101efd:	c1 e0 18             	shl    $0x18,%eax
f0101f00:	89 d6                	mov    %edx,%esi
f0101f02:	c1 e6 10             	shl    $0x10,%esi
f0101f05:	09 f0                	or     %esi,%eax
f0101f07:	09 c2                	or     %eax,%edx
f0101f09:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0101f0b:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101f0e:	89 d0                	mov    %edx,%eax
f0101f10:	fc                   	cld    
f0101f11:	f3 ab                	rep stos %eax,%es:(%edi)
f0101f13:	eb d6                	jmp    f0101eeb <memset+0x23>

f0101f15 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101f15:	55                   	push   %ebp
f0101f16:	89 e5                	mov    %esp,%ebp
f0101f18:	57                   	push   %edi
f0101f19:	56                   	push   %esi
f0101f1a:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f1d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101f20:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101f23:	39 c6                	cmp    %eax,%esi
f0101f25:	73 35                	jae    f0101f5c <memmove+0x47>
f0101f27:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101f2a:	39 c2                	cmp    %eax,%edx
f0101f2c:	76 2e                	jbe    f0101f5c <memmove+0x47>
		s += n;
		d += n;
f0101f2e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101f31:	89 d6                	mov    %edx,%esi
f0101f33:	09 fe                	or     %edi,%esi
f0101f35:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101f3b:	74 0c                	je     f0101f49 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101f3d:	83 ef 01             	sub    $0x1,%edi
f0101f40:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101f43:	fd                   	std    
f0101f44:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101f46:	fc                   	cld    
f0101f47:	eb 21                	jmp    f0101f6a <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101f49:	f6 c1 03             	test   $0x3,%cl
f0101f4c:	75 ef                	jne    f0101f3d <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101f4e:	83 ef 04             	sub    $0x4,%edi
f0101f51:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101f54:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101f57:	fd                   	std    
f0101f58:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101f5a:	eb ea                	jmp    f0101f46 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101f5c:	89 f2                	mov    %esi,%edx
f0101f5e:	09 c2                	or     %eax,%edx
f0101f60:	f6 c2 03             	test   $0x3,%dl
f0101f63:	74 09                	je     f0101f6e <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101f65:	89 c7                	mov    %eax,%edi
f0101f67:	fc                   	cld    
f0101f68:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101f6a:	5e                   	pop    %esi
f0101f6b:	5f                   	pop    %edi
f0101f6c:	5d                   	pop    %ebp
f0101f6d:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101f6e:	f6 c1 03             	test   $0x3,%cl
f0101f71:	75 f2                	jne    f0101f65 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101f73:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101f76:	89 c7                	mov    %eax,%edi
f0101f78:	fc                   	cld    
f0101f79:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101f7b:	eb ed                	jmp    f0101f6a <memmove+0x55>

f0101f7d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101f7d:	55                   	push   %ebp
f0101f7e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101f80:	ff 75 10             	pushl  0x10(%ebp)
f0101f83:	ff 75 0c             	pushl  0xc(%ebp)
f0101f86:	ff 75 08             	pushl  0x8(%ebp)
f0101f89:	e8 87 ff ff ff       	call   f0101f15 <memmove>
}
f0101f8e:	c9                   	leave  
f0101f8f:	c3                   	ret    

f0101f90 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101f90:	55                   	push   %ebp
f0101f91:	89 e5                	mov    %esp,%ebp
f0101f93:	56                   	push   %esi
f0101f94:	53                   	push   %ebx
f0101f95:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f98:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101f9b:	89 c6                	mov    %eax,%esi
f0101f9d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101fa0:	39 f0                	cmp    %esi,%eax
f0101fa2:	74 1c                	je     f0101fc0 <memcmp+0x30>
		if (*s1 != *s2)
f0101fa4:	0f b6 08             	movzbl (%eax),%ecx
f0101fa7:	0f b6 1a             	movzbl (%edx),%ebx
f0101faa:	38 d9                	cmp    %bl,%cl
f0101fac:	75 08                	jne    f0101fb6 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101fae:	83 c0 01             	add    $0x1,%eax
f0101fb1:	83 c2 01             	add    $0x1,%edx
f0101fb4:	eb ea                	jmp    f0101fa0 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0101fb6:	0f b6 c1             	movzbl %cl,%eax
f0101fb9:	0f b6 db             	movzbl %bl,%ebx
f0101fbc:	29 d8                	sub    %ebx,%eax
f0101fbe:	eb 05                	jmp    f0101fc5 <memcmp+0x35>
	}

	return 0;
f0101fc0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101fc5:	5b                   	pop    %ebx
f0101fc6:	5e                   	pop    %esi
f0101fc7:	5d                   	pop    %ebp
f0101fc8:	c3                   	ret    

f0101fc9 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101fc9:	55                   	push   %ebp
f0101fca:	89 e5                	mov    %esp,%ebp
f0101fcc:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fcf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101fd2:	89 c2                	mov    %eax,%edx
f0101fd4:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101fd7:	39 d0                	cmp    %edx,%eax
f0101fd9:	73 09                	jae    f0101fe4 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101fdb:	38 08                	cmp    %cl,(%eax)
f0101fdd:	74 05                	je     f0101fe4 <memfind+0x1b>
	for (; s < ends; s++)
f0101fdf:	83 c0 01             	add    $0x1,%eax
f0101fe2:	eb f3                	jmp    f0101fd7 <memfind+0xe>
			break;
	return (void *) s;
}
f0101fe4:	5d                   	pop    %ebp
f0101fe5:	c3                   	ret    

f0101fe6 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101fe6:	55                   	push   %ebp
f0101fe7:	89 e5                	mov    %esp,%ebp
f0101fe9:	57                   	push   %edi
f0101fea:	56                   	push   %esi
f0101feb:	53                   	push   %ebx
f0101fec:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101fef:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101ff2:	eb 03                	jmp    f0101ff7 <strtol+0x11>
		s++;
f0101ff4:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0101ff7:	0f b6 01             	movzbl (%ecx),%eax
f0101ffa:	3c 20                	cmp    $0x20,%al
f0101ffc:	74 f6                	je     f0101ff4 <strtol+0xe>
f0101ffe:	3c 09                	cmp    $0x9,%al
f0102000:	74 f2                	je     f0101ff4 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0102002:	3c 2b                	cmp    $0x2b,%al
f0102004:	74 2e                	je     f0102034 <strtol+0x4e>
	int neg = 0;
f0102006:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f010200b:	3c 2d                	cmp    $0x2d,%al
f010200d:	74 2f                	je     f010203e <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010200f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0102015:	75 05                	jne    f010201c <strtol+0x36>
f0102017:	80 39 30             	cmpb   $0x30,(%ecx)
f010201a:	74 2c                	je     f0102048 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010201c:	85 db                	test   %ebx,%ebx
f010201e:	75 0a                	jne    f010202a <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0102020:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0102025:	80 39 30             	cmpb   $0x30,(%ecx)
f0102028:	74 28                	je     f0102052 <strtol+0x6c>
		base = 10;
f010202a:	b8 00 00 00 00       	mov    $0x0,%eax
f010202f:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0102032:	eb 50                	jmp    f0102084 <strtol+0x9e>
		s++;
f0102034:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0102037:	bf 00 00 00 00       	mov    $0x0,%edi
f010203c:	eb d1                	jmp    f010200f <strtol+0x29>
		s++, neg = 1;
f010203e:	83 c1 01             	add    $0x1,%ecx
f0102041:	bf 01 00 00 00       	mov    $0x1,%edi
f0102046:	eb c7                	jmp    f010200f <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102048:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010204c:	74 0e                	je     f010205c <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010204e:	85 db                	test   %ebx,%ebx
f0102050:	75 d8                	jne    f010202a <strtol+0x44>
		s++, base = 8;
f0102052:	83 c1 01             	add    $0x1,%ecx
f0102055:	bb 08 00 00 00       	mov    $0x8,%ebx
f010205a:	eb ce                	jmp    f010202a <strtol+0x44>
		s += 2, base = 16;
f010205c:	83 c1 02             	add    $0x2,%ecx
f010205f:	bb 10 00 00 00       	mov    $0x10,%ebx
f0102064:	eb c4                	jmp    f010202a <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0102066:	8d 72 9f             	lea    -0x61(%edx),%esi
f0102069:	89 f3                	mov    %esi,%ebx
f010206b:	80 fb 19             	cmp    $0x19,%bl
f010206e:	77 29                	ja     f0102099 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0102070:	0f be d2             	movsbl %dl,%edx
f0102073:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0102076:	3b 55 10             	cmp    0x10(%ebp),%edx
f0102079:	7d 30                	jge    f01020ab <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f010207b:	83 c1 01             	add    $0x1,%ecx
f010207e:	0f af 45 10          	imul   0x10(%ebp),%eax
f0102082:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0102084:	0f b6 11             	movzbl (%ecx),%edx
f0102087:	8d 72 d0             	lea    -0x30(%edx),%esi
f010208a:	89 f3                	mov    %esi,%ebx
f010208c:	80 fb 09             	cmp    $0x9,%bl
f010208f:	77 d5                	ja     f0102066 <strtol+0x80>
			dig = *s - '0';
f0102091:	0f be d2             	movsbl %dl,%edx
f0102094:	83 ea 30             	sub    $0x30,%edx
f0102097:	eb dd                	jmp    f0102076 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0102099:	8d 72 bf             	lea    -0x41(%edx),%esi
f010209c:	89 f3                	mov    %esi,%ebx
f010209e:	80 fb 19             	cmp    $0x19,%bl
f01020a1:	77 08                	ja     f01020ab <strtol+0xc5>
			dig = *s - 'A' + 10;
f01020a3:	0f be d2             	movsbl %dl,%edx
f01020a6:	83 ea 37             	sub    $0x37,%edx
f01020a9:	eb cb                	jmp    f0102076 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01020ab:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01020af:	74 05                	je     f01020b6 <strtol+0xd0>
		*endptr = (char *) s;
f01020b1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01020b4:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01020b6:	89 c2                	mov    %eax,%edx
f01020b8:	f7 da                	neg    %edx
f01020ba:	85 ff                	test   %edi,%edi
f01020bc:	0f 45 c2             	cmovne %edx,%eax
}
f01020bf:	5b                   	pop    %ebx
f01020c0:	5e                   	pop    %esi
f01020c1:	5f                   	pop    %edi
f01020c2:	5d                   	pop    %ebp
f01020c3:	c3                   	ret    
f01020c4:	66 90                	xchg   %ax,%ax
f01020c6:	66 90                	xchg   %ax,%ax
f01020c8:	66 90                	xchg   %ax,%ax
f01020ca:	66 90                	xchg   %ax,%ax
f01020cc:	66 90                	xchg   %ax,%ax
f01020ce:	66 90                	xchg   %ax,%ax

f01020d0 <__udivdi3>:
f01020d0:	55                   	push   %ebp
f01020d1:	57                   	push   %edi
f01020d2:	56                   	push   %esi
f01020d3:	53                   	push   %ebx
f01020d4:	83 ec 1c             	sub    $0x1c,%esp
f01020d7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01020db:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01020df:	8b 74 24 34          	mov    0x34(%esp),%esi
f01020e3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01020e7:	85 d2                	test   %edx,%edx
f01020e9:	75 35                	jne    f0102120 <__udivdi3+0x50>
f01020eb:	39 f3                	cmp    %esi,%ebx
f01020ed:	0f 87 bd 00 00 00    	ja     f01021b0 <__udivdi3+0xe0>
f01020f3:	85 db                	test   %ebx,%ebx
f01020f5:	89 d9                	mov    %ebx,%ecx
f01020f7:	75 0b                	jne    f0102104 <__udivdi3+0x34>
f01020f9:	b8 01 00 00 00       	mov    $0x1,%eax
f01020fe:	31 d2                	xor    %edx,%edx
f0102100:	f7 f3                	div    %ebx
f0102102:	89 c1                	mov    %eax,%ecx
f0102104:	31 d2                	xor    %edx,%edx
f0102106:	89 f0                	mov    %esi,%eax
f0102108:	f7 f1                	div    %ecx
f010210a:	89 c6                	mov    %eax,%esi
f010210c:	89 e8                	mov    %ebp,%eax
f010210e:	89 f7                	mov    %esi,%edi
f0102110:	f7 f1                	div    %ecx
f0102112:	89 fa                	mov    %edi,%edx
f0102114:	83 c4 1c             	add    $0x1c,%esp
f0102117:	5b                   	pop    %ebx
f0102118:	5e                   	pop    %esi
f0102119:	5f                   	pop    %edi
f010211a:	5d                   	pop    %ebp
f010211b:	c3                   	ret    
f010211c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102120:	39 f2                	cmp    %esi,%edx
f0102122:	77 7c                	ja     f01021a0 <__udivdi3+0xd0>
f0102124:	0f bd fa             	bsr    %edx,%edi
f0102127:	83 f7 1f             	xor    $0x1f,%edi
f010212a:	0f 84 98 00 00 00    	je     f01021c8 <__udivdi3+0xf8>
f0102130:	89 f9                	mov    %edi,%ecx
f0102132:	b8 20 00 00 00       	mov    $0x20,%eax
f0102137:	29 f8                	sub    %edi,%eax
f0102139:	d3 e2                	shl    %cl,%edx
f010213b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010213f:	89 c1                	mov    %eax,%ecx
f0102141:	89 da                	mov    %ebx,%edx
f0102143:	d3 ea                	shr    %cl,%edx
f0102145:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0102149:	09 d1                	or     %edx,%ecx
f010214b:	89 f2                	mov    %esi,%edx
f010214d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102151:	89 f9                	mov    %edi,%ecx
f0102153:	d3 e3                	shl    %cl,%ebx
f0102155:	89 c1                	mov    %eax,%ecx
f0102157:	d3 ea                	shr    %cl,%edx
f0102159:	89 f9                	mov    %edi,%ecx
f010215b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010215f:	d3 e6                	shl    %cl,%esi
f0102161:	89 eb                	mov    %ebp,%ebx
f0102163:	89 c1                	mov    %eax,%ecx
f0102165:	d3 eb                	shr    %cl,%ebx
f0102167:	09 de                	or     %ebx,%esi
f0102169:	89 f0                	mov    %esi,%eax
f010216b:	f7 74 24 08          	divl   0x8(%esp)
f010216f:	89 d6                	mov    %edx,%esi
f0102171:	89 c3                	mov    %eax,%ebx
f0102173:	f7 64 24 0c          	mull   0xc(%esp)
f0102177:	39 d6                	cmp    %edx,%esi
f0102179:	72 0c                	jb     f0102187 <__udivdi3+0xb7>
f010217b:	89 f9                	mov    %edi,%ecx
f010217d:	d3 e5                	shl    %cl,%ebp
f010217f:	39 c5                	cmp    %eax,%ebp
f0102181:	73 5d                	jae    f01021e0 <__udivdi3+0x110>
f0102183:	39 d6                	cmp    %edx,%esi
f0102185:	75 59                	jne    f01021e0 <__udivdi3+0x110>
f0102187:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010218a:	31 ff                	xor    %edi,%edi
f010218c:	89 fa                	mov    %edi,%edx
f010218e:	83 c4 1c             	add    $0x1c,%esp
f0102191:	5b                   	pop    %ebx
f0102192:	5e                   	pop    %esi
f0102193:	5f                   	pop    %edi
f0102194:	5d                   	pop    %ebp
f0102195:	c3                   	ret    
f0102196:	8d 76 00             	lea    0x0(%esi),%esi
f0102199:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01021a0:	31 ff                	xor    %edi,%edi
f01021a2:	31 c0                	xor    %eax,%eax
f01021a4:	89 fa                	mov    %edi,%edx
f01021a6:	83 c4 1c             	add    $0x1c,%esp
f01021a9:	5b                   	pop    %ebx
f01021aa:	5e                   	pop    %esi
f01021ab:	5f                   	pop    %edi
f01021ac:	5d                   	pop    %ebp
f01021ad:	c3                   	ret    
f01021ae:	66 90                	xchg   %ax,%ax
f01021b0:	31 ff                	xor    %edi,%edi
f01021b2:	89 e8                	mov    %ebp,%eax
f01021b4:	89 f2                	mov    %esi,%edx
f01021b6:	f7 f3                	div    %ebx
f01021b8:	89 fa                	mov    %edi,%edx
f01021ba:	83 c4 1c             	add    $0x1c,%esp
f01021bd:	5b                   	pop    %ebx
f01021be:	5e                   	pop    %esi
f01021bf:	5f                   	pop    %edi
f01021c0:	5d                   	pop    %ebp
f01021c1:	c3                   	ret    
f01021c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01021c8:	39 f2                	cmp    %esi,%edx
f01021ca:	72 06                	jb     f01021d2 <__udivdi3+0x102>
f01021cc:	31 c0                	xor    %eax,%eax
f01021ce:	39 eb                	cmp    %ebp,%ebx
f01021d0:	77 d2                	ja     f01021a4 <__udivdi3+0xd4>
f01021d2:	b8 01 00 00 00       	mov    $0x1,%eax
f01021d7:	eb cb                	jmp    f01021a4 <__udivdi3+0xd4>
f01021d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01021e0:	89 d8                	mov    %ebx,%eax
f01021e2:	31 ff                	xor    %edi,%edi
f01021e4:	eb be                	jmp    f01021a4 <__udivdi3+0xd4>
f01021e6:	66 90                	xchg   %ax,%ax
f01021e8:	66 90                	xchg   %ax,%ax
f01021ea:	66 90                	xchg   %ax,%ax
f01021ec:	66 90                	xchg   %ax,%ax
f01021ee:	66 90                	xchg   %ax,%ax

f01021f0 <__umoddi3>:
f01021f0:	55                   	push   %ebp
f01021f1:	57                   	push   %edi
f01021f2:	56                   	push   %esi
f01021f3:	53                   	push   %ebx
f01021f4:	83 ec 1c             	sub    $0x1c,%esp
f01021f7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f01021fb:	8b 74 24 30          	mov    0x30(%esp),%esi
f01021ff:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0102203:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102207:	85 ed                	test   %ebp,%ebp
f0102209:	89 f0                	mov    %esi,%eax
f010220b:	89 da                	mov    %ebx,%edx
f010220d:	75 19                	jne    f0102228 <__umoddi3+0x38>
f010220f:	39 df                	cmp    %ebx,%edi
f0102211:	0f 86 b1 00 00 00    	jbe    f01022c8 <__umoddi3+0xd8>
f0102217:	f7 f7                	div    %edi
f0102219:	89 d0                	mov    %edx,%eax
f010221b:	31 d2                	xor    %edx,%edx
f010221d:	83 c4 1c             	add    $0x1c,%esp
f0102220:	5b                   	pop    %ebx
f0102221:	5e                   	pop    %esi
f0102222:	5f                   	pop    %edi
f0102223:	5d                   	pop    %ebp
f0102224:	c3                   	ret    
f0102225:	8d 76 00             	lea    0x0(%esi),%esi
f0102228:	39 dd                	cmp    %ebx,%ebp
f010222a:	77 f1                	ja     f010221d <__umoddi3+0x2d>
f010222c:	0f bd cd             	bsr    %ebp,%ecx
f010222f:	83 f1 1f             	xor    $0x1f,%ecx
f0102232:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0102236:	0f 84 b4 00 00 00    	je     f01022f0 <__umoddi3+0x100>
f010223c:	b8 20 00 00 00       	mov    $0x20,%eax
f0102241:	89 c2                	mov    %eax,%edx
f0102243:	8b 44 24 04          	mov    0x4(%esp),%eax
f0102247:	29 c2                	sub    %eax,%edx
f0102249:	89 c1                	mov    %eax,%ecx
f010224b:	89 f8                	mov    %edi,%eax
f010224d:	d3 e5                	shl    %cl,%ebp
f010224f:	89 d1                	mov    %edx,%ecx
f0102251:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102255:	d3 e8                	shr    %cl,%eax
f0102257:	09 c5                	or     %eax,%ebp
f0102259:	8b 44 24 04          	mov    0x4(%esp),%eax
f010225d:	89 c1                	mov    %eax,%ecx
f010225f:	d3 e7                	shl    %cl,%edi
f0102261:	89 d1                	mov    %edx,%ecx
f0102263:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0102267:	89 df                	mov    %ebx,%edi
f0102269:	d3 ef                	shr    %cl,%edi
f010226b:	89 c1                	mov    %eax,%ecx
f010226d:	89 f0                	mov    %esi,%eax
f010226f:	d3 e3                	shl    %cl,%ebx
f0102271:	89 d1                	mov    %edx,%ecx
f0102273:	89 fa                	mov    %edi,%edx
f0102275:	d3 e8                	shr    %cl,%eax
f0102277:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010227c:	09 d8                	or     %ebx,%eax
f010227e:	f7 f5                	div    %ebp
f0102280:	d3 e6                	shl    %cl,%esi
f0102282:	89 d1                	mov    %edx,%ecx
f0102284:	f7 64 24 08          	mull   0x8(%esp)
f0102288:	39 d1                	cmp    %edx,%ecx
f010228a:	89 c3                	mov    %eax,%ebx
f010228c:	89 d7                	mov    %edx,%edi
f010228e:	72 06                	jb     f0102296 <__umoddi3+0xa6>
f0102290:	75 0e                	jne    f01022a0 <__umoddi3+0xb0>
f0102292:	39 c6                	cmp    %eax,%esi
f0102294:	73 0a                	jae    f01022a0 <__umoddi3+0xb0>
f0102296:	2b 44 24 08          	sub    0x8(%esp),%eax
f010229a:	19 ea                	sbb    %ebp,%edx
f010229c:	89 d7                	mov    %edx,%edi
f010229e:	89 c3                	mov    %eax,%ebx
f01022a0:	89 ca                	mov    %ecx,%edx
f01022a2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01022a7:	29 de                	sub    %ebx,%esi
f01022a9:	19 fa                	sbb    %edi,%edx
f01022ab:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01022af:	89 d0                	mov    %edx,%eax
f01022b1:	d3 e0                	shl    %cl,%eax
f01022b3:	89 d9                	mov    %ebx,%ecx
f01022b5:	d3 ee                	shr    %cl,%esi
f01022b7:	d3 ea                	shr    %cl,%edx
f01022b9:	09 f0                	or     %esi,%eax
f01022bb:	83 c4 1c             	add    $0x1c,%esp
f01022be:	5b                   	pop    %ebx
f01022bf:	5e                   	pop    %esi
f01022c0:	5f                   	pop    %edi
f01022c1:	5d                   	pop    %ebp
f01022c2:	c3                   	ret    
f01022c3:	90                   	nop
f01022c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01022c8:	85 ff                	test   %edi,%edi
f01022ca:	89 f9                	mov    %edi,%ecx
f01022cc:	75 0b                	jne    f01022d9 <__umoddi3+0xe9>
f01022ce:	b8 01 00 00 00       	mov    $0x1,%eax
f01022d3:	31 d2                	xor    %edx,%edx
f01022d5:	f7 f7                	div    %edi
f01022d7:	89 c1                	mov    %eax,%ecx
f01022d9:	89 d8                	mov    %ebx,%eax
f01022db:	31 d2                	xor    %edx,%edx
f01022dd:	f7 f1                	div    %ecx
f01022df:	89 f0                	mov    %esi,%eax
f01022e1:	f7 f1                	div    %ecx
f01022e3:	e9 31 ff ff ff       	jmp    f0102219 <__umoddi3+0x29>
f01022e8:	90                   	nop
f01022e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01022f0:	39 dd                	cmp    %ebx,%ebp
f01022f2:	72 08                	jb     f01022fc <__umoddi3+0x10c>
f01022f4:	39 f7                	cmp    %esi,%edi
f01022f6:	0f 87 21 ff ff ff    	ja     f010221d <__umoddi3+0x2d>
f01022fc:	89 da                	mov    %ebx,%edx
f01022fe:	89 f0                	mov    %esi,%eax
f0102300:	29 f8                	sub    %edi,%eax
f0102302:	19 ea                	sbb    %ebp,%edx
f0102304:	e9 14 ff ff ff       	jmp    f010221d <__umoddi3+0x2d>
