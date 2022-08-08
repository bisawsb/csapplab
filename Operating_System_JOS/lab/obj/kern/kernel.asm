
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f8100000 <_start+0xf7fffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f8100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f8100006:	00 00                	add    %al,(%eax)
f8100008:	fe 4f 52             	decb   0x52(%edi)
f810000b:	e4                   	.byte 0xe4

f810000c <entry>:
f810000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f8100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f8100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f810001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f810001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f8100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f8100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f8100028:	b8 2f 00 10 f8       	mov    $0xf810002f,%eax
	jmp	*%eax
f810002d:	ff e0                	jmp    *%eax

f810002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f810002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f8100034:	bc 00 50 11 f8       	mov    $0xf8115000,%esp

	# now to C code
	call	i386_init
f8100039:	e8 02 00 00 00       	call   f8100040 <i386_init>

f810003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f810003e:	eb fe                	jmp    f810003e <spin>

f8100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f8100040:	55                   	push   %ebp
f8100041:	89 e5                	mov    %esp,%ebp
f8100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f8100046:	b8 60 79 11 f8       	mov    $0xf8117960,%eax
f810004b:	2d 00 73 11 f8       	sub    $0xf8117300,%eax
f8100050:	50                   	push   %eax
f8100051:	6a 00                	push   $0x0
f8100053:	68 00 73 11 f8       	push   $0xf8117300
f8100058:	e8 5b 32 00 00       	call   f81032b8 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f810005d:	e8 96 04 00 00       	call   f81004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f8100062:	83 c4 08             	add    $0x8,%esp
f8100065:	68 ac 1a 00 00       	push   $0x1aac
f810006a:	68 60 37 10 f8       	push   $0xf8103760
f810006f:	e8 eb 26 00 00       	call   f810275f <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f8100074:	e8 30 10 00 00       	call   f81010a9 <mem_init>
f8100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f810007c:	83 ec 0c             	sub    $0xc,%esp
f810007f:	6a 00                	push   $0x0
f8100081:	e8 79 07 00 00       	call   f81007ff <monitor>
f8100086:	83 c4 10             	add    $0x10,%esp
f8100089:	eb f1                	jmp    f810007c <i386_init+0x3c>

f810008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f810008b:	55                   	push   %ebp
f810008c:	89 e5                	mov    %esp,%ebp
f810008e:	56                   	push   %esi
f810008f:	53                   	push   %ebx
f8100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f8100093:	83 3d 64 79 11 f8 00 	cmpl   $0x0,0xf8117964
f810009a:	75 37                	jne    f81000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f810009c:	89 35 64 79 11 f8    	mov    %esi,0xf8117964

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f81000a2:	fa                   	cli    
f81000a3:	fc                   	cld    

	va_start(ap, fmt);
f81000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f81000a7:	83 ec 04             	sub    $0x4,%esp
f81000aa:	ff 75 0c             	pushl  0xc(%ebp)
f81000ad:	ff 75 08             	pushl  0x8(%ebp)
f81000b0:	68 7b 37 10 f8       	push   $0xf810377b
f81000b5:	e8 a5 26 00 00       	call   f810275f <cprintf>
	vcprintf(fmt, ap);
f81000ba:	83 c4 08             	add    $0x8,%esp
f81000bd:	53                   	push   %ebx
f81000be:	56                   	push   %esi
f81000bf:	e8 75 26 00 00       	call   f8102739 <vcprintf>
	cprintf("\n");
f81000c4:	c7 04 24 c0 3f 10 f8 	movl   $0xf8103fc0,(%esp)
f81000cb:	e8 8f 26 00 00       	call   f810275f <cprintf>
	va_end(ap);
f81000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f81000d3:	83 ec 0c             	sub    $0xc,%esp
f81000d6:	6a 00                	push   $0x0
f81000d8:	e8 22 07 00 00       	call   f81007ff <monitor>
f81000dd:	83 c4 10             	add    $0x10,%esp
f81000e0:	eb f1                	jmp    f81000d3 <_panic+0x48>

f81000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f81000e2:	55                   	push   %ebp
f81000e3:	89 e5                	mov    %esp,%ebp
f81000e5:	53                   	push   %ebx
f81000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f81000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f81000ec:	ff 75 0c             	pushl  0xc(%ebp)
f81000ef:	ff 75 08             	pushl  0x8(%ebp)
f81000f2:	68 93 37 10 f8       	push   $0xf8103793
f81000f7:	e8 63 26 00 00       	call   f810275f <cprintf>
	vcprintf(fmt, ap);
f81000fc:	83 c4 08             	add    $0x8,%esp
f81000ff:	53                   	push   %ebx
f8100100:	ff 75 10             	pushl  0x10(%ebp)
f8100103:	e8 31 26 00 00       	call   f8102739 <vcprintf>
	cprintf("\n");
f8100108:	c7 04 24 c0 3f 10 f8 	movl   $0xf8103fc0,(%esp)
f810010f:	e8 4b 26 00 00       	call   f810275f <cprintf>
	va_end(ap);
}
f8100114:	83 c4 10             	add    $0x10,%esp
f8100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f810011a:	c9                   	leave  
f810011b:	c3                   	ret    

f810011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f810011c:	55                   	push   %ebp
f810011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f810011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f8100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f8100125:	a8 01                	test   $0x1,%al
f8100127:	74 0b                	je     f8100134 <serial_proc_data+0x18>
f8100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f810012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f810012f:	0f b6 c0             	movzbl %al,%eax
f8100132:	eb 05                	jmp    f8100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f8100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f8100139:	5d                   	pop    %ebp
f810013a:	c3                   	ret    

f810013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f810013b:	55                   	push   %ebp
f810013c:	89 e5                	mov    %esp,%ebp
f810013e:	53                   	push   %ebx
f810013f:	83 ec 04             	sub    $0x4,%esp
f8100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f8100144:	eb 2b                	jmp    f8100171 <cons_intr+0x36>
		if (c == 0)
f8100146:	85 c0                	test   %eax,%eax
f8100148:	74 27                	je     f8100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f810014a:	8b 0d 24 75 11 f8    	mov    0xf8117524,%ecx
f8100150:	8d 51 01             	lea    0x1(%ecx),%edx
f8100153:	89 15 24 75 11 f8    	mov    %edx,0xf8117524
f8100159:	88 81 20 73 11 f8    	mov    %al,-0x7ee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f810015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f8100165:	75 0a                	jne    f8100171 <cons_intr+0x36>
			cons.wpos = 0;
f8100167:	c7 05 24 75 11 f8 00 	movl   $0x0,0xf8117524
f810016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f8100171:	ff d3                	call   *%ebx
f8100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f8100176:	75 ce                	jne    f8100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f8100178:	83 c4 04             	add    $0x4,%esp
f810017b:	5b                   	pop    %ebx
f810017c:	5d                   	pop    %ebp
f810017d:	c3                   	ret    

f810017e <kbd_proc_data>:
f810017e:	ba 64 00 00 00       	mov    $0x64,%edx
f8100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f8100184:	a8 01                	test   $0x1,%al
f8100186:	0f 84 f8 00 00 00    	je     f8100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f810018c:	a8 20                	test   $0x20,%al
f810018e:	0f 85 f6 00 00 00    	jne    f810028a <kbd_proc_data+0x10c>
f8100194:	ba 60 00 00 00       	mov    $0x60,%edx
f8100199:	ec                   	in     (%dx),%al
f810019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f810019c:	3c e0                	cmp    $0xe0,%al
f810019e:	75 0d                	jne    f81001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f81001a0:	83 0d 00 73 11 f8 40 	orl    $0x40,0xf8117300
		return 0;
f81001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f81001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f81001ad:	55                   	push   %ebp
f81001ae:	89 e5                	mov    %esp,%ebp
f81001b0:	53                   	push   %ebx
f81001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f81001b4:	84 c0                	test   %al,%al
f81001b6:	79 36                	jns    f81001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f81001b8:	8b 0d 00 73 11 f8    	mov    0xf8117300,%ecx
f81001be:	89 cb                	mov    %ecx,%ebx
f81001c0:	83 e3 40             	and    $0x40,%ebx
f81001c3:	83 e0 7f             	and    $0x7f,%eax
f81001c6:	85 db                	test   %ebx,%ebx
f81001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f81001cb:	0f b6 d2             	movzbl %dl,%edx
f81001ce:	0f b6 82 00 39 10 f8 	movzbl -0x7efc700(%edx),%eax
f81001d5:	83 c8 40             	or     $0x40,%eax
f81001d8:	0f b6 c0             	movzbl %al,%eax
f81001db:	f7 d0                	not    %eax
f81001dd:	21 c8                	and    %ecx,%eax
f81001df:	a3 00 73 11 f8       	mov    %eax,0xf8117300
		return 0;
f81001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f81001e9:	e9 a4 00 00 00       	jmp    f8100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f81001ee:	8b 0d 00 73 11 f8    	mov    0xf8117300,%ecx
f81001f4:	f6 c1 40             	test   $0x40,%cl
f81001f7:	74 0e                	je     f8100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f81001f9:	83 c8 80             	or     $0xffffff80,%eax
f81001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f81001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f8100201:	89 0d 00 73 11 f8    	mov    %ecx,0xf8117300
	}

	shift |= shiftcode[data];
f8100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f810020a:	0f b6 82 00 39 10 f8 	movzbl -0x7efc700(%edx),%eax
f8100211:	0b 05 00 73 11 f8    	or     0xf8117300,%eax
f8100217:	0f b6 8a 00 38 10 f8 	movzbl -0x7efc800(%edx),%ecx
f810021e:	31 c8                	xor    %ecx,%eax
f8100220:	a3 00 73 11 f8       	mov    %eax,0xf8117300

	c = charcode[shift & (CTL | SHIFT)][data];
f8100225:	89 c1                	mov    %eax,%ecx
f8100227:	83 e1 03             	and    $0x3,%ecx
f810022a:	8b 0c 8d e0 37 10 f8 	mov    -0x7efc820(,%ecx,4),%ecx
f8100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f8100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f8100238:	a8 08                	test   $0x8,%al
f810023a:	74 1b                	je     f8100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f810023c:	89 da                	mov    %ebx,%edx
f810023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f8100241:	83 f9 19             	cmp    $0x19,%ecx
f8100244:	77 05                	ja     f810024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f8100246:	83 eb 20             	sub    $0x20,%ebx
f8100249:	eb 0c                	jmp    f8100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f810024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f810024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f8100251:	83 fa 19             	cmp    $0x19,%edx
f8100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f8100257:	f7 d0                	not    %eax
f8100259:	a8 06                	test   $0x6,%al
f810025b:	75 33                	jne    f8100290 <kbd_proc_data+0x112>
f810025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f8100263:	75 2b                	jne    f8100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f8100265:	83 ec 0c             	sub    $0xc,%esp
f8100268:	68 ad 37 10 f8       	push   $0xf81037ad
f810026d:	e8 ed 24 00 00       	call   f810275f <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f8100272:	ba 92 00 00 00       	mov    $0x92,%edx
f8100277:	b8 03 00 00 00       	mov    $0x3,%eax
f810027c:	ee                   	out    %al,(%dx)
f810027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f8100280:	89 d8                	mov    %ebx,%eax
f8100282:	eb 0e                	jmp    f8100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f8100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f8100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f810028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f810028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f8100290:	89 d8                	mov    %ebx,%eax
}
f8100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f8100295:	c9                   	leave  
f8100296:	c3                   	ret    

f8100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f8100297:	55                   	push   %ebp
f8100298:	89 e5                	mov    %esp,%ebp
f810029a:	57                   	push   %edi
f810029b:	56                   	push   %esi
f810029c:	53                   	push   %ebx
f810029d:	83 ec 1c             	sub    $0x1c,%esp
f81002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f81002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f81002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f81002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f81002b1:	eb 09                	jmp    f81002bc <cons_putc+0x25>
f81002b3:	89 ca                	mov    %ecx,%edx
f81002b5:	ec                   	in     (%dx),%al
f81002b6:	ec                   	in     (%dx),%al
f81002b7:	ec                   	in     (%dx),%al
f81002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f81002b9:	83 c3 01             	add    $0x1,%ebx
f81002bc:	89 f2                	mov    %esi,%edx
f81002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f81002bf:	a8 20                	test   $0x20,%al
f81002c1:	75 08                	jne    f81002cb <cons_putc+0x34>
f81002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f81002c9:	7e e8                	jle    f81002b3 <cons_putc+0x1c>
f81002cb:	89 f8                	mov    %edi,%eax
f81002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f81002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f81002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f81002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f81002db:	be 79 03 00 00       	mov    $0x379,%esi
f81002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f81002e5:	eb 09                	jmp    f81002f0 <cons_putc+0x59>
f81002e7:	89 ca                	mov    %ecx,%edx
f81002e9:	ec                   	in     (%dx),%al
f81002ea:	ec                   	in     (%dx),%al
f81002eb:	ec                   	in     (%dx),%al
f81002ec:	ec                   	in     (%dx),%al
f81002ed:	83 c3 01             	add    $0x1,%ebx
f81002f0:	89 f2                	mov    %esi,%edx
f81002f2:	ec                   	in     (%dx),%al
f81002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f81002f9:	7f 04                	jg     f81002ff <cons_putc+0x68>
f81002fb:	84 c0                	test   %al,%al
f81002fd:	79 e8                	jns    f81002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f81002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f8100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f8100308:	ee                   	out    %al,(%dx)
f8100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f810030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f8100313:	ee                   	out    %al,(%dx)
f8100314:	b8 08 00 00 00       	mov    $0x8,%eax
f8100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f810031a:	89 fa                	mov    %edi,%edx
f810031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f8100322:	89 f8                	mov    %edi,%eax
f8100324:	80 cc 07             	or     $0x7,%ah
f8100327:	85 d2                	test   %edx,%edx
f8100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f810032c:	89 f8                	mov    %edi,%eax
f810032e:	0f b6 c0             	movzbl %al,%eax
f8100331:	83 f8 09             	cmp    $0x9,%eax
f8100334:	74 74                	je     f81003aa <cons_putc+0x113>
f8100336:	83 f8 09             	cmp    $0x9,%eax
f8100339:	7f 0a                	jg     f8100345 <cons_putc+0xae>
f810033b:	83 f8 08             	cmp    $0x8,%eax
f810033e:	74 14                	je     f8100354 <cons_putc+0xbd>
f8100340:	e9 99 00 00 00       	jmp    f81003de <cons_putc+0x147>
f8100345:	83 f8 0a             	cmp    $0xa,%eax
f8100348:	74 3a                	je     f8100384 <cons_putc+0xed>
f810034a:	83 f8 0d             	cmp    $0xd,%eax
f810034d:	74 3d                	je     f810038c <cons_putc+0xf5>
f810034f:	e9 8a 00 00 00       	jmp    f81003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f8100354:	0f b7 05 28 75 11 f8 	movzwl 0xf8117528,%eax
f810035b:	66 85 c0             	test   %ax,%ax
f810035e:	0f 84 e6 00 00 00    	je     f810044a <cons_putc+0x1b3>
			crt_pos--;
f8100364:	83 e8 01             	sub    $0x1,%eax
f8100367:	66 a3 28 75 11 f8    	mov    %ax,0xf8117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f810036d:	0f b7 c0             	movzwl %ax,%eax
f8100370:	66 81 e7 00 ff       	and    $0xff00,%di
f8100375:	83 cf 20             	or     $0x20,%edi
f8100378:	8b 15 2c 75 11 f8    	mov    0xf811752c,%edx
f810037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f8100382:	eb 78                	jmp    f81003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f8100384:	66 83 05 28 75 11 f8 	addw   $0x50,0xf8117528
f810038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f810038c:	0f b7 05 28 75 11 f8 	movzwl 0xf8117528,%eax
f8100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f8100399:	c1 e8 16             	shr    $0x16,%eax
f810039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f810039f:	c1 e0 04             	shl    $0x4,%eax
f81003a2:	66 a3 28 75 11 f8    	mov    %ax,0xf8117528
f81003a8:	eb 52                	jmp    f81003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f81003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f81003af:	e8 e3 fe ff ff       	call   f8100297 <cons_putc>
		cons_putc(' ');
f81003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f81003b9:	e8 d9 fe ff ff       	call   f8100297 <cons_putc>
		cons_putc(' ');
f81003be:	b8 20 00 00 00       	mov    $0x20,%eax
f81003c3:	e8 cf fe ff ff       	call   f8100297 <cons_putc>
		cons_putc(' ');
f81003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f81003cd:	e8 c5 fe ff ff       	call   f8100297 <cons_putc>
		cons_putc(' ');
f81003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f81003d7:	e8 bb fe ff ff       	call   f8100297 <cons_putc>
f81003dc:	eb 1e                	jmp    f81003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f81003de:	0f b7 05 28 75 11 f8 	movzwl 0xf8117528,%eax
f81003e5:	8d 50 01             	lea    0x1(%eax),%edx
f81003e8:	66 89 15 28 75 11 f8 	mov    %dx,0xf8117528
f81003ef:	0f b7 c0             	movzwl %ax,%eax
f81003f2:	8b 15 2c 75 11 f8    	mov    0xf811752c,%edx
f81003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f81003fc:	66 81 3d 28 75 11 f8 	cmpw   $0x7cf,0xf8117528
f8100403:	cf 07 
f8100405:	76 43                	jbe    f810044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f8100407:	a1 2c 75 11 f8       	mov    0xf811752c,%eax
f810040c:	83 ec 04             	sub    $0x4,%esp
f810040f:	68 00 0f 00 00       	push   $0xf00
f8100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f810041a:	52                   	push   %edx
f810041b:	50                   	push   %eax
f810041c:	e8 e4 2e 00 00       	call   f8103305 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f8100421:	8b 15 2c 75 11 f8    	mov    0xf811752c,%edx
f8100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f810042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f8100433:	83 c4 10             	add    $0x10,%esp
f8100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f810043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f810043e:	39 d0                	cmp    %edx,%eax
f8100440:	75 f4                	jne    f8100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f8100442:	66 83 2d 28 75 11 f8 	subw   $0x50,0xf8117528
f8100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f810044a:	8b 0d 30 75 11 f8    	mov    0xf8117530,%ecx
f8100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f8100455:	89 ca                	mov    %ecx,%edx
f8100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f8100458:	0f b7 1d 28 75 11 f8 	movzwl 0xf8117528,%ebx
f810045f:	8d 71 01             	lea    0x1(%ecx),%esi
f8100462:	89 d8                	mov    %ebx,%eax
f8100464:	66 c1 e8 08          	shr    $0x8,%ax
f8100468:	89 f2                	mov    %esi,%edx
f810046a:	ee                   	out    %al,(%dx)
f810046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f8100470:	89 ca                	mov    %ecx,%edx
f8100472:	ee                   	out    %al,(%dx)
f8100473:	89 d8                	mov    %ebx,%eax
f8100475:	89 f2                	mov    %esi,%edx
f8100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f8100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f810047b:	5b                   	pop    %ebx
f810047c:	5e                   	pop    %esi
f810047d:	5f                   	pop    %edi
f810047e:	5d                   	pop    %ebp
f810047f:	c3                   	ret    

f8100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f8100480:	80 3d 34 75 11 f8 00 	cmpb   $0x0,0xf8117534
f8100487:	74 11                	je     f810049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f8100489:	55                   	push   %ebp
f810048a:	89 e5                	mov    %esp,%ebp
f810048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f810048f:	b8 1c 01 10 f8       	mov    $0xf810011c,%eax
f8100494:	e8 a2 fc ff ff       	call   f810013b <cons_intr>
}
f8100499:	c9                   	leave  
f810049a:	f3 c3                	repz ret 

f810049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f810049c:	55                   	push   %ebp
f810049d:	89 e5                	mov    %esp,%ebp
f810049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f81004a2:	b8 7e 01 10 f8       	mov    $0xf810017e,%eax
f81004a7:	e8 8f fc ff ff       	call   f810013b <cons_intr>
}
f81004ac:	c9                   	leave  
f81004ad:	c3                   	ret    

f81004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f81004ae:	55                   	push   %ebp
f81004af:	89 e5                	mov    %esp,%ebp
f81004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f81004b4:	e8 c7 ff ff ff       	call   f8100480 <serial_intr>
	kbd_intr();
f81004b9:	e8 de ff ff ff       	call   f810049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f81004be:	a1 20 75 11 f8       	mov    0xf8117520,%eax
f81004c3:	3b 05 24 75 11 f8    	cmp    0xf8117524,%eax
f81004c9:	74 26                	je     f81004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f81004cb:	8d 50 01             	lea    0x1(%eax),%edx
f81004ce:	89 15 20 75 11 f8    	mov    %edx,0xf8117520
f81004d4:	0f b6 88 20 73 11 f8 	movzbl -0x7ee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f81004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f81004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f81004e3:	75 11                	jne    f81004f6 <cons_getc+0x48>
			cons.rpos = 0;
f81004e5:	c7 05 20 75 11 f8 00 	movl   $0x0,0xf8117520
f81004ec:	00 00 00 
f81004ef:	eb 05                	jmp    f81004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f81004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f81004f6:	c9                   	leave  
f81004f7:	c3                   	ret    

f81004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f81004f8:	55                   	push   %ebp
f81004f9:	89 e5                	mov    %esp,%ebp
f81004fb:	57                   	push   %edi
f81004fc:	56                   	push   %esi
f81004fd:	53                   	push   %ebx
f81004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f8100501:	0f b7 15 00 80 0b f8 	movzwl 0xf80b8000,%edx
	*cp = (uint16_t) 0xA55A;
f8100508:	66 c7 05 00 80 0b f8 	movw   $0xa55a,0xf80b8000
f810050f:	5a a5 
	if (*cp != 0xA55A) {
f8100511:	0f b7 05 00 80 0b f8 	movzwl 0xf80b8000,%eax
f8100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f810051c:	74 11                	je     f810052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f810051e:	c7 05 30 75 11 f8 b4 	movl   $0x3b4,0xf8117530
f8100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f8100528:	be 00 00 0b f8       	mov    $0xf80b0000,%esi
f810052d:	eb 16                	jmp    f8100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f810052f:	66 89 15 00 80 0b f8 	mov    %dx,0xf80b8000
		addr_6845 = CGA_BASE;
f8100536:	c7 05 30 75 11 f8 d4 	movl   $0x3d4,0xf8117530
f810053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f8100540:	be 00 80 0b f8       	mov    $0xf80b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f8100545:	8b 3d 30 75 11 f8    	mov    0xf8117530,%edi
f810054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f8100550:	89 fa                	mov    %edi,%edx
f8100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f8100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f8100556:	89 da                	mov    %ebx,%edx
f8100558:	ec                   	in     (%dx),%al
f8100559:	0f b6 c8             	movzbl %al,%ecx
f810055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f810055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f8100564:	89 fa                	mov    %edi,%edx
f8100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f8100567:	89 da                	mov    %ebx,%edx
f8100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f810056a:	89 35 2c 75 11 f8    	mov    %esi,0xf811752c
	crt_pos = pos;
f8100570:	0f b6 c0             	movzbl %al,%eax
f8100573:	09 c8                	or     %ecx,%eax
f8100575:	66 a3 28 75 11 f8    	mov    %ax,0xf8117528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f810057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f8100580:	b8 00 00 00 00       	mov    $0x0,%eax
f8100585:	89 f2                	mov    %esi,%edx
f8100587:	ee                   	out    %al,(%dx)
f8100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f810058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f8100592:	ee                   	out    %al,(%dx)
f8100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f8100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f810059d:	89 da                	mov    %ebx,%edx
f810059f:	ee                   	out    %al,(%dx)
f81005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f81005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f81005aa:	ee                   	out    %al,(%dx)
f81005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f81005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f81005b5:	ee                   	out    %al,(%dx)
f81005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f81005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f81005c0:	ee                   	out    %al,(%dx)
f81005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f81005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f81005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f81005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f81005d1:	ec                   	in     (%dx),%al
f81005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f81005d4:	3c ff                	cmp    $0xff,%al
f81005d6:	0f 95 05 34 75 11 f8 	setne  0xf8117534
f81005dd:	89 f2                	mov    %esi,%edx
f81005df:	ec                   	in     (%dx),%al
f81005e0:	89 da                	mov    %ebx,%edx
f81005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f81005e3:	80 f9 ff             	cmp    $0xff,%cl
f81005e6:	75 10                	jne    f81005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f81005e8:	83 ec 0c             	sub    $0xc,%esp
f81005eb:	68 b9 37 10 f8       	push   $0xf81037b9
f81005f0:	e8 6a 21 00 00       	call   f810275f <cprintf>
f81005f5:	83 c4 10             	add    $0x10,%esp
}
f81005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f81005fb:	5b                   	pop    %ebx
f81005fc:	5e                   	pop    %esi
f81005fd:	5f                   	pop    %edi
f81005fe:	5d                   	pop    %ebp
f81005ff:	c3                   	ret    

f8100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f8100600:	55                   	push   %ebp
f8100601:	89 e5                	mov    %esp,%ebp
f8100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f8100606:	8b 45 08             	mov    0x8(%ebp),%eax
f8100609:	e8 89 fc ff ff       	call   f8100297 <cons_putc>
}
f810060e:	c9                   	leave  
f810060f:	c3                   	ret    

f8100610 <getchar>:

int
getchar(void)
{
f8100610:	55                   	push   %ebp
f8100611:	89 e5                	mov    %esp,%ebp
f8100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f8100616:	e8 93 fe ff ff       	call   f81004ae <cons_getc>
f810061b:	85 c0                	test   %eax,%eax
f810061d:	74 f7                	je     f8100616 <getchar+0x6>
		/* do nothing */;
	if(c=='k') return 'n';
f810061f:	ba 6e 00 00 00       	mov    $0x6e,%edx
f8100624:	83 f8 6b             	cmp    $0x6b,%eax
f8100627:	74 0b                	je     f8100634 <getchar+0x24>
	if(c=='n') return 'k';
f8100629:	83 f8 6e             	cmp    $0x6e,%eax
int
getchar(void)
{
	int c;

	while ((c = cons_getc()) == 0)
f810062c:	ba 6b 00 00 00       	mov    $0x6b,%edx
f8100631:	0f 45 d0             	cmovne %eax,%edx
		/* do nothing */;
	if(c=='k') return 'n';
	if(c=='n') return 'k';
	return c;
}
f8100634:	89 d0                	mov    %edx,%eax
f8100636:	c9                   	leave  
f8100637:	c3                   	ret    

f8100638 <iscons>:

int
iscons(int fdnum)
{
f8100638:	55                   	push   %ebp
f8100639:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f810063b:	b8 01 00 00 00       	mov    $0x1,%eax
f8100640:	5d                   	pop    %ebp
f8100641:	c3                   	ret    

f8100642 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f8100642:	55                   	push   %ebp
f8100643:	89 e5                	mov    %esp,%ebp
f8100645:	56                   	push   %esi
f8100646:	53                   	push   %ebx
f8100647:	bb a0 3c 10 f8       	mov    $0xf8103ca0,%ebx
f810064c:	be d0 3c 10 f8       	mov    $0xf8103cd0,%esi
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f8100651:	83 ec 04             	sub    $0x4,%esp
f8100654:	ff 73 04             	pushl  0x4(%ebx)
f8100657:	ff 33                	pushl  (%ebx)
f8100659:	68 00 3a 10 f8       	push   $0xf8103a00
f810065e:	e8 fc 20 00 00       	call   f810275f <cprintf>
f8100663:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
f8100666:	83 c4 10             	add    $0x10,%esp
f8100669:	39 f3                	cmp    %esi,%ebx
f810066b:	75 e4                	jne    f8100651 <mon_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f810066d:	b8 00 00 00 00       	mov    $0x0,%eax
f8100672:	8d 65 f8             	lea    -0x8(%ebp),%esp
f8100675:	5b                   	pop    %ebx
f8100676:	5e                   	pop    %esi
f8100677:	5d                   	pop    %ebp
f8100678:	c3                   	ret    

f8100679 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f8100679:	55                   	push   %ebp
f810067a:	89 e5                	mov    %esp,%ebp
f810067c:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f810067f:	68 09 3a 10 f8       	push   $0xf8103a09
f8100684:	e8 d6 20 00 00       	call   f810275f <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f8100689:	83 c4 08             	add    $0x8,%esp
f810068c:	68 0c 00 10 00       	push   $0x10000c
f8100691:	68 1c 3b 10 f8       	push   $0xf8103b1c
f8100696:	e8 c4 20 00 00       	call   f810275f <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f810069b:	83 c4 0c             	add    $0xc,%esp
f810069e:	68 0c 00 10 00       	push   $0x10000c
f81006a3:	68 0c 00 10 f8       	push   $0xf810000c
f81006a8:	68 44 3b 10 f8       	push   $0xf8103b44
f81006ad:	e8 ad 20 00 00       	call   f810275f <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f81006b2:	83 c4 0c             	add    $0xc,%esp
f81006b5:	68 41 37 10 00       	push   $0x103741
f81006ba:	68 41 37 10 f8       	push   $0xf8103741
f81006bf:	68 68 3b 10 f8       	push   $0xf8103b68
f81006c4:	e8 96 20 00 00       	call   f810275f <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f81006c9:	83 c4 0c             	add    $0xc,%esp
f81006cc:	68 00 73 11 00       	push   $0x117300
f81006d1:	68 00 73 11 f8       	push   $0xf8117300
f81006d6:	68 8c 3b 10 f8       	push   $0xf8103b8c
f81006db:	e8 7f 20 00 00       	call   f810275f <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f81006e0:	83 c4 0c             	add    $0xc,%esp
f81006e3:	68 60 79 11 00       	push   $0x117960
f81006e8:	68 60 79 11 f8       	push   $0xf8117960
f81006ed:	68 b0 3b 10 f8       	push   $0xf8103bb0
f81006f2:	e8 68 20 00 00       	call   f810275f <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f81006f7:	b8 5f 7d 11 f8       	mov    $0xf8117d5f,%eax
f81006fc:	2d 0c 00 10 f8       	sub    $0xf810000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f8100701:	83 c4 08             	add    $0x8,%esp
f8100704:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f8100709:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f810070f:	85 c0                	test   %eax,%eax
f8100711:	0f 48 c2             	cmovs  %edx,%eax
f8100714:	c1 f8 0a             	sar    $0xa,%eax
f8100717:	50                   	push   %eax
f8100718:	68 d4 3b 10 f8       	push   $0xf8103bd4
f810071d:	e8 3d 20 00 00       	call   f810275f <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f8100722:	b8 00 00 00 00       	mov    $0x0,%eax
f8100727:	c9                   	leave  
f8100728:	c3                   	ret    

f8100729 <mon_helloworld>:
		ebp = (unsigned int*)(ebp[0]);
	}
	return 0;
}

int mon_helloworld(int argc, char **argv, struct Trapframe *tf) {
f8100729:	55                   	push   %ebp
f810072a:	89 e5                	mov    %esp,%ebp
f810072c:	83 ec 14             	sub    $0x14,%esp
	cprintf("Hello world!\n");
f810072f:	68 22 3a 10 f8       	push   $0xf8103a22
f8100734:	e8 26 20 00 00       	call   f810275f <cprintf>
	return 0;
}
f8100739:	b8 00 00 00 00       	mov    $0x0,%eax
f810073e:	c9                   	leave  
f810073f:	c3                   	ret    

f8100740 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f8100740:	55                   	push   %ebp
f8100741:	89 e5                	mov    %esp,%ebp
f8100743:	57                   	push   %edi
f8100744:	56                   	push   %esi
f8100745:	53                   	push   %ebx
f8100746:	83 ec 38             	sub    $0x38,%esp
	// Your code here.
	cprintf("Stack backtrace:\n");
f8100749:	68 30 3a 10 f8       	push   $0xf8103a30
f810074e:	e8 0c 20 00 00       	call   f810275f <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f8100753:	89 ee                	mov    %ebp,%esi
	unsigned int *ebp = (unsigned int*)read_ebp();
	while(ebp){
f8100755:	83 c4 10             	add    $0x10,%esp
f8100758:	e9 8d 00 00 00       	jmp    f81007ea <mon_backtrace+0xaa>
		cprintf("  ebp %08x  eip %08x  args", (unsigned int)ebp, ebp[1]);
f810075d:	83 ec 04             	sub    $0x4,%esp
f8100760:	ff 76 04             	pushl  0x4(%esi)
f8100763:	56                   	push   %esi
f8100764:	68 42 3a 10 f8       	push   $0xf8103a42
f8100769:	e8 f1 1f 00 00       	call   f810275f <cprintf>
f810076e:	8d 5e 08             	lea    0x8(%esi),%ebx
f8100771:	8d 7e 1c             	lea    0x1c(%esi),%edi
f8100774:	83 c4 10             	add    $0x10,%esp
		for(int i = 2; i < 7; i++)
			cprintf(" %08x", ebp[i]);
f8100777:	83 ec 08             	sub    $0x8,%esp
f810077a:	ff 33                	pushl  (%ebx)
f810077c:	68 5d 3a 10 f8       	push   $0xf8103a5d
f8100781:	e8 d9 1f 00 00       	call   f810275f <cprintf>
f8100786:	83 c3 04             	add    $0x4,%ebx
	// Your code here.
	cprintf("Stack backtrace:\n");
	unsigned int *ebp = (unsigned int*)read_ebp();
	while(ebp){
		cprintf("  ebp %08x  eip %08x  args", (unsigned int)ebp, ebp[1]);
		for(int i = 2; i < 7; i++)
f8100789:	83 c4 10             	add    $0x10,%esp
f810078c:	39 fb                	cmp    %edi,%ebx
f810078e:	75 e7                	jne    f8100777 <mon_backtrace+0x37>
			cprintf(" %08x", ebp[i]);
		cprintf("\n");
f8100790:	83 ec 0c             	sub    $0xc,%esp
f8100793:	68 c0 3f 10 f8       	push   $0xf8103fc0
f8100798:	e8 c2 1f 00 00       	call   f810275f <cprintf>
		struct Eipdebuginfo info;
		if (debuginfo_eip(ebp[1], &info) < 0) {
f810079d:	83 c4 08             	add    $0x8,%esp
f81007a0:	8d 45 d0             	lea    -0x30(%ebp),%eax
f81007a3:	50                   	push   %eax
f81007a4:	ff 76 04             	pushl  0x4(%esi)
f81007a7:	e8 bd 20 00 00       	call   f8102869 <debuginfo_eip>
f81007ac:	83 c4 10             	add    $0x10,%esp
f81007af:	85 c0                	test   %eax,%eax
f81007b1:	79 12                	jns    f81007c5 <mon_backtrace+0x85>
			cprintf("    \tNo debuginfo\n");
f81007b3:	83 ec 0c             	sub    $0xc,%esp
f81007b6:	68 63 3a 10 f8       	push   $0xf8103a63
f81007bb:	e8 9f 1f 00 00       	call   f810275f <cprintf>
			continue;
f81007c0:	83 c4 10             	add    $0x10,%esp
f81007c3:	eb 25                	jmp    f81007ea <mon_backtrace+0xaa>
		}
		cprintf("    \t%s:%d: %.*s+%d\n",
f81007c5:	83 ec 08             	sub    $0x8,%esp
f81007c8:	8b 46 04             	mov    0x4(%esi),%eax
f81007cb:	2b 45 e0             	sub    -0x20(%ebp),%eax
f81007ce:	50                   	push   %eax
f81007cf:	ff 75 d8             	pushl  -0x28(%ebp)
f81007d2:	ff 75 dc             	pushl  -0x24(%ebp)
f81007d5:	ff 75 d4             	pushl  -0x2c(%ebp)
f81007d8:	ff 75 d0             	pushl  -0x30(%ebp)
f81007db:	68 76 3a 10 f8       	push   $0xf8103a76
f81007e0:	e8 7a 1f 00 00       	call   f810275f <cprintf>
			info.eip_line,
			info.eip_fn_namelen,
			info.eip_fn_name,
			ebp[1] - info.eip_fn_addr
			);
		ebp = (unsigned int*)(ebp[0]);
f81007e5:	8b 36                	mov    (%esi),%esi
f81007e7:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	cprintf("Stack backtrace:\n");
	unsigned int *ebp = (unsigned int*)read_ebp();
	while(ebp){
f81007ea:	85 f6                	test   %esi,%esi
f81007ec:	0f 85 6b ff ff ff    	jne    f810075d <mon_backtrace+0x1d>
			ebp[1] - info.eip_fn_addr
			);
		ebp = (unsigned int*)(ebp[0]);
	}
	return 0;
}
f81007f2:	b8 00 00 00 00       	mov    $0x0,%eax
f81007f7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f81007fa:	5b                   	pop    %ebx
f81007fb:	5e                   	pop    %esi
f81007fc:	5f                   	pop    %edi
f81007fd:	5d                   	pop    %ebp
f81007fe:	c3                   	ret    

f81007ff <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f81007ff:	55                   	push   %ebp
f8100800:	89 e5                	mov    %esp,%ebp
f8100802:	57                   	push   %edi
f8100803:	56                   	push   %esi
f8100804:	53                   	push   %ebx
f8100805:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f8100808:	68 00 3c 10 f8       	push   $0xf8103c00
f810080d:	e8 4d 1f 00 00       	call   f810275f <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f8100812:	c7 04 24 24 3c 10 f8 	movl   $0xf8103c24,(%esp)
f8100819:	e8 41 1f 00 00       	call   f810275f <cprintf>
f810081e:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f8100821:	83 ec 0c             	sub    $0xc,%esp
f8100824:	68 8b 3a 10 f8       	push   $0xf8103a8b
f8100829:	e8 33 28 00 00       	call   f8103061 <readline>
f810082e:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f8100830:	83 c4 10             	add    $0x10,%esp
f8100833:	85 c0                	test   %eax,%eax
f8100835:	74 ea                	je     f8100821 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f8100837:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f810083e:	be 00 00 00 00       	mov    $0x0,%esi
f8100843:	eb 0a                	jmp    f810084f <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f8100845:	c6 03 00             	movb   $0x0,(%ebx)
f8100848:	89 f7                	mov    %esi,%edi
f810084a:	8d 5b 01             	lea    0x1(%ebx),%ebx
f810084d:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f810084f:	0f b6 03             	movzbl (%ebx),%eax
f8100852:	84 c0                	test   %al,%al
f8100854:	74 63                	je     f81008b9 <monitor+0xba>
f8100856:	83 ec 08             	sub    $0x8,%esp
f8100859:	0f be c0             	movsbl %al,%eax
f810085c:	50                   	push   %eax
f810085d:	68 8f 3a 10 f8       	push   $0xf8103a8f
f8100862:	e8 14 2a 00 00       	call   f810327b <strchr>
f8100867:	83 c4 10             	add    $0x10,%esp
f810086a:	85 c0                	test   %eax,%eax
f810086c:	75 d7                	jne    f8100845 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f810086e:	80 3b 00             	cmpb   $0x0,(%ebx)
f8100871:	74 46                	je     f81008b9 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f8100873:	83 fe 0f             	cmp    $0xf,%esi
f8100876:	75 14                	jne    f810088c <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f8100878:	83 ec 08             	sub    $0x8,%esp
f810087b:	6a 10                	push   $0x10
f810087d:	68 94 3a 10 f8       	push   $0xf8103a94
f8100882:	e8 d8 1e 00 00       	call   f810275f <cprintf>
f8100887:	83 c4 10             	add    $0x10,%esp
f810088a:	eb 95                	jmp    f8100821 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f810088c:	8d 7e 01             	lea    0x1(%esi),%edi
f810088f:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f8100893:	eb 03                	jmp    f8100898 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f8100895:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f8100898:	0f b6 03             	movzbl (%ebx),%eax
f810089b:	84 c0                	test   %al,%al
f810089d:	74 ae                	je     f810084d <monitor+0x4e>
f810089f:	83 ec 08             	sub    $0x8,%esp
f81008a2:	0f be c0             	movsbl %al,%eax
f81008a5:	50                   	push   %eax
f81008a6:	68 8f 3a 10 f8       	push   $0xf8103a8f
f81008ab:	e8 cb 29 00 00       	call   f810327b <strchr>
f81008b0:	83 c4 10             	add    $0x10,%esp
f81008b3:	85 c0                	test   %eax,%eax
f81008b5:	74 de                	je     f8100895 <monitor+0x96>
f81008b7:	eb 94                	jmp    f810084d <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f81008b9:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f81008c0:	00 

	// Lookup and invoke the command
	if (argc == 0)
f81008c1:	85 f6                	test   %esi,%esi
f81008c3:	0f 84 58 ff ff ff    	je     f8100821 <monitor+0x22>
f81008c9:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f81008ce:	83 ec 08             	sub    $0x8,%esp
f81008d1:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f81008d4:	ff 34 85 a0 3c 10 f8 	pushl  -0x7efc360(,%eax,4)
f81008db:	ff 75 a8             	pushl  -0x58(%ebp)
f81008de:	e8 3a 29 00 00       	call   f810321d <strcmp>
f81008e3:	83 c4 10             	add    $0x10,%esp
f81008e6:	85 c0                	test   %eax,%eax
f81008e8:	75 21                	jne    f810090b <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f81008ea:	83 ec 04             	sub    $0x4,%esp
f81008ed:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f81008f0:	ff 75 08             	pushl  0x8(%ebp)
f81008f3:	8d 55 a8             	lea    -0x58(%ebp),%edx
f81008f6:	52                   	push   %edx
f81008f7:	56                   	push   %esi
f81008f8:	ff 14 85 a8 3c 10 f8 	call   *-0x7efc358(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f81008ff:	83 c4 10             	add    $0x10,%esp
f8100902:	85 c0                	test   %eax,%eax
f8100904:	78 25                	js     f810092b <monitor+0x12c>
f8100906:	e9 16 ff ff ff       	jmp    f8100821 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f810090b:	83 c3 01             	add    $0x1,%ebx
f810090e:	83 fb 04             	cmp    $0x4,%ebx
f8100911:	75 bb                	jne    f81008ce <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f8100913:	83 ec 08             	sub    $0x8,%esp
f8100916:	ff 75 a8             	pushl  -0x58(%ebp)
f8100919:	68 b1 3a 10 f8       	push   $0xf8103ab1
f810091e:	e8 3c 1e 00 00       	call   f810275f <cprintf>
f8100923:	83 c4 10             	add    $0x10,%esp
f8100926:	e9 f6 fe ff ff       	jmp    f8100821 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f810092b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f810092e:	5b                   	pop    %ebx
f810092f:	5e                   	pop    %esi
f8100930:	5f                   	pop    %edi
f8100931:	5d                   	pop    %ebp
f8100932:	c3                   	ret    

f8100933 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f8100933:	55                   	push   %ebp
f8100934:	89 e5                	mov    %esp,%ebp
f8100936:	56                   	push   %esi
f8100937:	53                   	push   %ebx
f8100938:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f810093a:	83 ec 0c             	sub    $0xc,%esp
f810093d:	50                   	push   %eax
f810093e:	e8 ae 1d 00 00       	call   f81026f1 <mc146818_read>
f8100943:	89 c6                	mov    %eax,%esi
f8100945:	83 c3 01             	add    $0x1,%ebx
f8100948:	89 1c 24             	mov    %ebx,(%esp)
f810094b:	e8 a1 1d 00 00       	call   f81026f1 <mc146818_read>
f8100950:	c1 e0 08             	shl    $0x8,%eax
f8100953:	09 f0                	or     %esi,%eax
}
f8100955:	8d 65 f8             	lea    -0x8(%ebp),%esp
f8100958:	5b                   	pop    %ebx
f8100959:	5e                   	pop    %esi
f810095a:	5d                   	pop    %ebp
f810095b:	c3                   	ret    

f810095c <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f810095c:	83 3d 38 75 11 f8 00 	cmpl   $0x0,0xf8117538
f8100963:	75 11                	jne    f8100976 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f8100965:	ba 5f 89 11 f8       	mov    $0xf811895f,%edx
f810096a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f8100970:	89 15 38 75 11 f8    	mov    %edx,0xf8117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n > 0){
f8100976:	85 c0                	test   %eax,%eax
f8100978:	74 5b                	je     f81009d5 <boot_alloc+0x79>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f810097a:	55                   	push   %ebp
f810097b:	89 e5                	mov    %esp,%ebp
f810097d:	53                   	push   %ebx
f810097e:	83 ec 04             	sub    $0x4,%esp
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n > 0){
		char *pageBegin = nextfree;
f8100981:	8b 1d 38 75 11 f8    	mov    0xf8117538,%ebx
		nextfree = ROUNDUP((char *)(pageBegin + n), PGSIZE);      //allocate n bytes and aligned to PGSIZE.
f8100987:	8d 84 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%eax
f810098e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f8100993:	a3 38 75 11 f8       	mov    %eax,0xf8117538
		if ((uint32_t)nextfree - KERNBASE > (npages * PGSIZE))      //JOS panic when out of memory.
f8100998:	8d 88 00 00 00 08    	lea    0x8000000(%eax),%ecx
f810099e:	8b 15 68 79 11 f8    	mov    0xf8117968,%edx
f81009a4:	c1 e2 0c             	shl    $0xc,%edx
f81009a7:	39 d1                	cmp    %edx,%ecx
f81009a9:	76 14                	jbe    f81009bf <boot_alloc+0x63>
			panic("Out of memory");
f81009ab:	83 ec 04             	sub    $0x4,%esp
f81009ae:	68 d0 3c 10 f8       	push   $0xf8103cd0
f81009b3:	6a 6d                	push   $0x6d
f81009b5:	68 de 3c 10 f8       	push   $0xf8103cde
f81009ba:	e8 cc f6 ff ff       	call   f810008b <_panic>
		cprintf("Boot memory start at %x and end with %x\n", pageBegin, nextfree);
f81009bf:	83 ec 04             	sub    $0x4,%esp
f81009c2:	50                   	push   %eax
f81009c3:	53                   	push   %ebx
f81009c4:	68 f4 3f 10 f8       	push   $0xf8103ff4
f81009c9:	e8 91 1d 00 00       	call   f810275f <cprintf>
		return pageBegin;
f81009ce:	83 c4 10             	add    $0x10,%esp
f81009d1:	89 d8                	mov    %ebx,%eax
f81009d3:	eb 06                	jmp    f81009db <boot_alloc+0x7f>
	}
	//cprintf("No memory allocating\n");
	return nextfree;
f81009d5:	a1 38 75 11 f8       	mov    0xf8117538,%eax
f81009da:	c3                   	ret    
}
f81009db:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f81009de:	c9                   	leave  
f81009df:	c3                   	ret    

f81009e0 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f81009e0:	89 d1                	mov    %edx,%ecx
f81009e2:	c1 e9 16             	shr    $0x16,%ecx
f81009e5:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f81009e8:	a8 01                	test   $0x1,%al
f81009ea:	74 52                	je     f8100a3e <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f81009ec:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f81009f1:	89 c1                	mov    %eax,%ecx
f81009f3:	c1 e9 0c             	shr    $0xc,%ecx
f81009f6:	3b 0d 68 79 11 f8    	cmp    0xf8117968,%ecx
f81009fc:	72 1b                	jb     f8100a19 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f81009fe:	55                   	push   %ebp
f81009ff:	89 e5                	mov    %esp,%ebp
f8100a01:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f8100a04:	50                   	push   %eax
f8100a05:	68 20 40 10 f8       	push   $0xf8104020
f8100a0a:	68 cb 02 00 00       	push   $0x2cb
f8100a0f:	68 de 3c 10 f8       	push   $0xf8103cde
f8100a14:	e8 72 f6 ff ff       	call   f810008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f8100a19:	c1 ea 0c             	shr    $0xc,%edx
f8100a1c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f8100a22:	8b 84 90 00 00 00 f8 	mov    -0x8000000(%eax,%edx,4),%eax
f8100a29:	89 c2                	mov    %eax,%edx
f8100a2b:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f8100a2e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f8100a33:	85 d2                	test   %edx,%edx
f8100a35:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f8100a3a:	0f 44 c2             	cmove  %edx,%eax
f8100a3d:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f8100a3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f8100a43:	c3                   	ret    

f8100a44 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f8100a44:	55                   	push   %ebp
f8100a45:	89 e5                	mov    %esp,%ebp
f8100a47:	57                   	push   %edi
f8100a48:	56                   	push   %esi
f8100a49:	53                   	push   %ebx
f8100a4a:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f8100a4d:	84 c0                	test   %al,%al
f8100a4f:	0f 85 81 02 00 00    	jne    f8100cd6 <check_page_free_list+0x292>
f8100a55:	e9 8e 02 00 00       	jmp    f8100ce8 <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f8100a5a:	83 ec 04             	sub    $0x4,%esp
f8100a5d:	68 44 40 10 f8       	push   $0xf8104044
f8100a62:	68 0c 02 00 00       	push   $0x20c
f8100a67:	68 de 3c 10 f8       	push   $0xf8103cde
f8100a6c:	e8 1a f6 ff ff       	call   f810008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f8100a71:	8d 55 d8             	lea    -0x28(%ebp),%edx
f8100a74:	89 55 e0             	mov    %edx,-0x20(%ebp)
f8100a77:	8d 55 dc             	lea    -0x24(%ebp),%edx
f8100a7a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f8100a7d:	89 c2                	mov    %eax,%edx
f8100a7f:	2b 15 70 79 11 f8    	sub    0xf8117970,%edx
f8100a85:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f8100a8b:	0f 95 c2             	setne  %dl
f8100a8e:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f8100a91:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f8100a95:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f8100a97:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f8100a9b:	8b 00                	mov    (%eax),%eax
f8100a9d:	85 c0                	test   %eax,%eax
f8100a9f:	75 dc                	jne    f8100a7d <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f8100aa1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f8100aa4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f8100aaa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f8100aad:	8b 55 dc             	mov    -0x24(%ebp),%edx
f8100ab0:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f8100ab2:	8b 45 d8             	mov    -0x28(%ebp),%eax
f8100ab5:	a3 3c 75 11 f8       	mov    %eax,0xf811753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f8100aba:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f8100abf:	8b 1d 3c 75 11 f8    	mov    0xf811753c,%ebx
f8100ac5:	eb 53                	jmp    f8100b1a <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f8100ac7:	89 d8                	mov    %ebx,%eax
f8100ac9:	2b 05 70 79 11 f8    	sub    0xf8117970,%eax
f8100acf:	c1 f8 03             	sar    $0x3,%eax
f8100ad2:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f8100ad5:	89 c2                	mov    %eax,%edx
f8100ad7:	c1 ea 16             	shr    $0x16,%edx
f8100ada:	39 f2                	cmp    %esi,%edx
f8100adc:	73 3a                	jae    f8100b18 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f8100ade:	89 c2                	mov    %eax,%edx
f8100ae0:	c1 ea 0c             	shr    $0xc,%edx
f8100ae3:	3b 15 68 79 11 f8    	cmp    0xf8117968,%edx
f8100ae9:	72 12                	jb     f8100afd <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f8100aeb:	50                   	push   %eax
f8100aec:	68 20 40 10 f8       	push   $0xf8104020
f8100af1:	6a 52                	push   $0x52
f8100af3:	68 ea 3c 10 f8       	push   $0xf8103cea
f8100af8:	e8 8e f5 ff ff       	call   f810008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f8100afd:	83 ec 04             	sub    $0x4,%esp
f8100b00:	68 80 00 00 00       	push   $0x80
f8100b05:	68 97 00 00 00       	push   $0x97
f8100b0a:	2d 00 00 00 08       	sub    $0x8000000,%eax
f8100b0f:	50                   	push   %eax
f8100b10:	e8 a3 27 00 00       	call   f81032b8 <memset>
f8100b15:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f8100b18:	8b 1b                	mov    (%ebx),%ebx
f8100b1a:	85 db                	test   %ebx,%ebx
f8100b1c:	75 a9                	jne    f8100ac7 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f8100b1e:	b8 00 00 00 00       	mov    $0x0,%eax
f8100b23:	e8 34 fe ff ff       	call   f810095c <boot_alloc>
f8100b28:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f8100b2b:	8b 15 3c 75 11 f8    	mov    0xf811753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f8100b31:	8b 0d 70 79 11 f8    	mov    0xf8117970,%ecx
		assert(pp < pages + npages);
f8100b37:	a1 68 79 11 f8       	mov    0xf8117968,%eax
f8100b3c:	89 45 c8             	mov    %eax,-0x38(%ebp)
f8100b3f:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f8100b42:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f8100b45:	be 00 00 00 00       	mov    $0x0,%esi
f8100b4a:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f8100b4d:	e9 30 01 00 00       	jmp    f8100c82 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f8100b52:	39 ca                	cmp    %ecx,%edx
f8100b54:	73 19                	jae    f8100b6f <check_page_free_list+0x12b>
f8100b56:	68 f8 3c 10 f8       	push   $0xf8103cf8
f8100b5b:	68 04 3d 10 f8       	push   $0xf8103d04
f8100b60:	68 26 02 00 00       	push   $0x226
f8100b65:	68 de 3c 10 f8       	push   $0xf8103cde
f8100b6a:	e8 1c f5 ff ff       	call   f810008b <_panic>
		assert(pp < pages + npages);
f8100b6f:	39 fa                	cmp    %edi,%edx
f8100b71:	72 19                	jb     f8100b8c <check_page_free_list+0x148>
f8100b73:	68 19 3d 10 f8       	push   $0xf8103d19
f8100b78:	68 04 3d 10 f8       	push   $0xf8103d04
f8100b7d:	68 27 02 00 00       	push   $0x227
f8100b82:	68 de 3c 10 f8       	push   $0xf8103cde
f8100b87:	e8 ff f4 ff ff       	call   f810008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f8100b8c:	89 d0                	mov    %edx,%eax
f8100b8e:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f8100b91:	a8 07                	test   $0x7,%al
f8100b93:	74 19                	je     f8100bae <check_page_free_list+0x16a>
f8100b95:	68 68 40 10 f8       	push   $0xf8104068
f8100b9a:	68 04 3d 10 f8       	push   $0xf8103d04
f8100b9f:	68 28 02 00 00       	push   $0x228
f8100ba4:	68 de 3c 10 f8       	push   $0xf8103cde
f8100ba9:	e8 dd f4 ff ff       	call   f810008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f8100bae:	c1 f8 03             	sar    $0x3,%eax
f8100bb1:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f8100bb4:	85 c0                	test   %eax,%eax
f8100bb6:	75 19                	jne    f8100bd1 <check_page_free_list+0x18d>
f8100bb8:	68 2d 3d 10 f8       	push   $0xf8103d2d
f8100bbd:	68 04 3d 10 f8       	push   $0xf8103d04
f8100bc2:	68 2b 02 00 00       	push   $0x22b
f8100bc7:	68 de 3c 10 f8       	push   $0xf8103cde
f8100bcc:	e8 ba f4 ff ff       	call   f810008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f8100bd1:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f8100bd6:	75 19                	jne    f8100bf1 <check_page_free_list+0x1ad>
f8100bd8:	68 3e 3d 10 f8       	push   $0xf8103d3e
f8100bdd:	68 04 3d 10 f8       	push   $0xf8103d04
f8100be2:	68 2c 02 00 00       	push   $0x22c
f8100be7:	68 de 3c 10 f8       	push   $0xf8103cde
f8100bec:	e8 9a f4 ff ff       	call   f810008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f8100bf1:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f8100bf6:	75 19                	jne    f8100c11 <check_page_free_list+0x1cd>
f8100bf8:	68 9c 40 10 f8       	push   $0xf810409c
f8100bfd:	68 04 3d 10 f8       	push   $0xf8103d04
f8100c02:	68 2d 02 00 00       	push   $0x22d
f8100c07:	68 de 3c 10 f8       	push   $0xf8103cde
f8100c0c:	e8 7a f4 ff ff       	call   f810008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f8100c11:	3d 00 00 10 00       	cmp    $0x100000,%eax
f8100c16:	75 19                	jne    f8100c31 <check_page_free_list+0x1ed>
f8100c18:	68 57 3d 10 f8       	push   $0xf8103d57
f8100c1d:	68 04 3d 10 f8       	push   $0xf8103d04
f8100c22:	68 2e 02 00 00       	push   $0x22e
f8100c27:	68 de 3c 10 f8       	push   $0xf8103cde
f8100c2c:	e8 5a f4 ff ff       	call   f810008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f8100c31:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f8100c36:	76 3f                	jbe    f8100c77 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f8100c38:	89 c3                	mov    %eax,%ebx
f8100c3a:	c1 eb 0c             	shr    $0xc,%ebx
f8100c3d:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f8100c40:	77 12                	ja     f8100c54 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f8100c42:	50                   	push   %eax
f8100c43:	68 20 40 10 f8       	push   $0xf8104020
f8100c48:	6a 52                	push   $0x52
f8100c4a:	68 ea 3c 10 f8       	push   $0xf8103cea
f8100c4f:	e8 37 f4 ff ff       	call   f810008b <_panic>
f8100c54:	2d 00 00 00 08       	sub    $0x8000000,%eax
f8100c59:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f8100c5c:	76 1e                	jbe    f8100c7c <check_page_free_list+0x238>
f8100c5e:	68 c0 40 10 f8       	push   $0xf81040c0
f8100c63:	68 04 3d 10 f8       	push   $0xf8103d04
f8100c68:	68 2f 02 00 00       	push   $0x22f
f8100c6d:	68 de 3c 10 f8       	push   $0xf8103cde
f8100c72:	e8 14 f4 ff ff       	call   f810008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f8100c77:	83 c6 01             	add    $0x1,%esi
f8100c7a:	eb 04                	jmp    f8100c80 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f8100c7c:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f8100c80:	8b 12                	mov    (%edx),%edx
f8100c82:	85 d2                	test   %edx,%edx
f8100c84:	0f 85 c8 fe ff ff    	jne    f8100b52 <check_page_free_list+0x10e>
f8100c8a:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f8100c8d:	85 f6                	test   %esi,%esi
f8100c8f:	7f 19                	jg     f8100caa <check_page_free_list+0x266>
f8100c91:	68 71 3d 10 f8       	push   $0xf8103d71
f8100c96:	68 04 3d 10 f8       	push   $0xf8103d04
f8100c9b:	68 37 02 00 00       	push   $0x237
f8100ca0:	68 de 3c 10 f8       	push   $0xf8103cde
f8100ca5:	e8 e1 f3 ff ff       	call   f810008b <_panic>
	assert(nfree_extmem > 0);
f8100caa:	85 db                	test   %ebx,%ebx
f8100cac:	7f 19                	jg     f8100cc7 <check_page_free_list+0x283>
f8100cae:	68 83 3d 10 f8       	push   $0xf8103d83
f8100cb3:	68 04 3d 10 f8       	push   $0xf8103d04
f8100cb8:	68 38 02 00 00       	push   $0x238
f8100cbd:	68 de 3c 10 f8       	push   $0xf8103cde
f8100cc2:	e8 c4 f3 ff ff       	call   f810008b <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f8100cc7:	83 ec 0c             	sub    $0xc,%esp
f8100cca:	68 08 41 10 f8       	push   $0xf8104108
f8100ccf:	e8 8b 1a 00 00       	call   f810275f <cprintf>
}
f8100cd4:	eb 29                	jmp    f8100cff <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f8100cd6:	a1 3c 75 11 f8       	mov    0xf811753c,%eax
f8100cdb:	85 c0                	test   %eax,%eax
f8100cdd:	0f 85 8e fd ff ff    	jne    f8100a71 <check_page_free_list+0x2d>
f8100ce3:	e9 72 fd ff ff       	jmp    f8100a5a <check_page_free_list+0x16>
f8100ce8:	83 3d 3c 75 11 f8 00 	cmpl   $0x0,0xf811753c
f8100cef:	0f 84 65 fd ff ff    	je     f8100a5a <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f8100cf5:	be 00 04 00 00       	mov    $0x400,%esi
f8100cfa:	e9 c0 fd ff ff       	jmp    f8100abf <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f8100cff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f8100d02:	5b                   	pop    %ebx
f8100d03:	5e                   	pop    %esi
f8100d04:	5f                   	pop    %edi
f8100d05:	5d                   	pop    %ebp
f8100d06:	c3                   	ret    

f8100d07 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f8100d07:	55                   	push   %ebp
f8100d08:	89 e5                	mov    %esp,%ebp
f8100d0a:	56                   	push   %esi
f8100d0b:	53                   	push   %ebx
	//     page tables and other data structures?
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	page_free_list = NULL;
f8100d0c:	c7 05 3c 75 11 f8 00 	movl   $0x0,0xf811753c
f8100d13:	00 00 00 
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f8100d16:	8b 35 40 75 11 f8    	mov    0xf8117540,%esi
f8100d1c:	ba 00 00 00 00       	mov    $0x0,%edx
f8100d21:	bb 00 00 00 00       	mov    $0x0,%ebx
f8100d26:	b8 01 00 00 00       	mov    $0x1,%eax
f8100d2b:	eb 27                	jmp    f8100d54 <page_init+0x4d>
		pages[i].pp_ref = 0;
f8100d2d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f8100d34:	89 d1                	mov    %edx,%ecx
f8100d36:	03 0d 70 79 11 f8    	add    0xf8117970,%ecx
f8100d3c:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f8100d42:	89 19                	mov    %ebx,(%ecx)
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	page_free_list = NULL;
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f8100d44:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f8100d47:	89 d3                	mov    %edx,%ebx
f8100d49:	03 1d 70 79 11 f8    	add    0xf8117970,%ebx
f8100d4f:	ba 01 00 00 00       	mov    $0x1,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	page_free_list = NULL;
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f8100d54:	39 f0                	cmp    %esi,%eax
f8100d56:	72 d5                	jb     f8100d2d <page_init+0x26>
f8100d58:	84 d2                	test   %dl,%dl
f8100d5a:	74 06                	je     f8100d62 <page_init+0x5b>
f8100d5c:	89 1d 3c 75 11 f8    	mov    %ebx,0xf811753c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	uint32_t extphysmem = (uint32_t)ROUNDUP((uint32_t)boot_alloc(0) + sizeof(struct PageInfo)*npages - KERNBASE, PGSIZE)/PGSIZE;
f8100d62:	b8 00 00 00 00       	mov    $0x0,%eax
f8100d67:	e8 f0 fb ff ff       	call   f810095c <boot_alloc>
f8100d6c:	8b 15 68 79 11 f8    	mov    0xf8117968,%edx
f8100d72:	8d 94 d0 ff 0f 00 08 	lea    0x8000fff(%eax,%edx,8),%edx
f8100d79:	c1 ea 0c             	shr    $0xc,%edx
f8100d7c:	8b 1d 3c 75 11 f8    	mov    0xf811753c,%ebx
f8100d82:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
	for (i = extphysmem; i < npages; i++) {
f8100d89:	b9 00 00 00 00       	mov    $0x0,%ecx
f8100d8e:	eb 23                	jmp    f8100db3 <page_init+0xac>
		pages[i].pp_ref = 0;
f8100d90:	89 c1                	mov    %eax,%ecx
f8100d92:	03 0d 70 79 11 f8    	add    0xf8117970,%ecx
f8100d98:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f8100d9e:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f8100da0:	89 c3                	mov    %eax,%ebx
f8100da2:	03 1d 70 79 11 f8    	add    0xf8117970,%ebx
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	uint32_t extphysmem = (uint32_t)ROUNDUP((uint32_t)boot_alloc(0) + sizeof(struct PageInfo)*npages - KERNBASE, PGSIZE)/PGSIZE;
	for (i = extphysmem; i < npages; i++) {
f8100da8:	83 c2 01             	add    $0x1,%edx
f8100dab:	83 c0 08             	add    $0x8,%eax
f8100dae:	b9 01 00 00 00       	mov    $0x1,%ecx
f8100db3:	3b 15 68 79 11 f8    	cmp    0xf8117968,%edx
f8100db9:	72 d5                	jb     f8100d90 <page_init+0x89>
f8100dbb:	84 c9                	test   %cl,%cl
f8100dbd:	74 06                	je     f8100dc5 <page_init+0xbe>
f8100dbf:	89 1d 3c 75 11 f8    	mov    %ebx,0xf811753c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f8100dc5:	5b                   	pop    %ebx
f8100dc6:	5e                   	pop    %esi
f8100dc7:	5d                   	pop    %ebp
f8100dc8:	c3                   	ret    

f8100dc9 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f8100dc9:	55                   	push   %ebp
f8100dca:	89 e5                	mov    %esp,%ebp
f8100dcc:	53                   	push   %ebx
f8100dcd:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *ret = NULL;
	if(page_free_list == NULL)
f8100dd0:	8b 1d 3c 75 11 f8    	mov    0xf811753c,%ebx
f8100dd6:	85 db                	test   %ebx,%ebx
f8100dd8:	74 58                	je     f8100e32 <page_alloc+0x69>
		return ret;
	ret = page_free_list;
	page_free_list = ret->pp_link;
f8100dda:	8b 03                	mov    (%ebx),%eax
f8100ddc:	a3 3c 75 11 f8       	mov    %eax,0xf811753c
	ret->pp_link = NULL;
f8100de1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO)
f8100de7:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f8100deb:	74 45                	je     f8100e32 <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f8100ded:	89 d8                	mov    %ebx,%eax
f8100def:	2b 05 70 79 11 f8    	sub    0xf8117970,%eax
f8100df5:	c1 f8 03             	sar    $0x3,%eax
f8100df8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f8100dfb:	89 c2                	mov    %eax,%edx
f8100dfd:	c1 ea 0c             	shr    $0xc,%edx
f8100e00:	3b 15 68 79 11 f8    	cmp    0xf8117968,%edx
f8100e06:	72 12                	jb     f8100e1a <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f8100e08:	50                   	push   %eax
f8100e09:	68 20 40 10 f8       	push   $0xf8104020
f8100e0e:	6a 52                	push   $0x52
f8100e10:	68 ea 3c 10 f8       	push   $0xf8103cea
f8100e15:	e8 71 f2 ff ff       	call   f810008b <_panic>
		memset(page2kva(ret), 0, PGSIZE);
f8100e1a:	83 ec 04             	sub    $0x4,%esp
f8100e1d:	68 00 10 00 00       	push   $0x1000
f8100e22:	6a 00                	push   $0x0
f8100e24:	2d 00 00 00 08       	sub    $0x8000000,%eax
f8100e29:	50                   	push   %eax
f8100e2a:	e8 89 24 00 00       	call   f81032b8 <memset>
f8100e2f:	83 c4 10             	add    $0x10,%esp
	return ret;
}
f8100e32:	89 d8                	mov    %ebx,%eax
f8100e34:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f8100e37:	c9                   	leave  
f8100e38:	c3                   	ret    

f8100e39 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f8100e39:	55                   	push   %ebp
f8100e3a:	89 e5                	mov    %esp,%ebp
f8100e3c:	83 ec 08             	sub    $0x8,%esp
f8100e3f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref != 0 || pp->pp_link != NULL)
f8100e42:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f8100e47:	75 05                	jne    f8100e4e <page_free+0x15>
f8100e49:	83 38 00             	cmpl   $0x0,(%eax)
f8100e4c:	74 17                	je     f8100e65 <page_free+0x2c>
		panic("Try to free a wrong page.");
f8100e4e:	83 ec 04             	sub    $0x4,%esp
f8100e51:	68 94 3d 10 f8       	push   $0xf8103d94
f8100e56:	68 3f 01 00 00       	push   $0x13f
f8100e5b:	68 de 3c 10 f8       	push   $0xf8103cde
f8100e60:	e8 26 f2 ff ff       	call   f810008b <_panic>
	pp->pp_link = page_free_list;
f8100e65:	8b 15 3c 75 11 f8    	mov    0xf811753c,%edx
f8100e6b:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f8100e6d:	a3 3c 75 11 f8       	mov    %eax,0xf811753c
}
f8100e72:	c9                   	leave  
f8100e73:	c3                   	ret    

f8100e74 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f8100e74:	55                   	push   %ebp
f8100e75:	89 e5                	mov    %esp,%ebp
f8100e77:	83 ec 08             	sub    $0x8,%esp
f8100e7a:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f8100e7d:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f8100e81:	83 e8 01             	sub    $0x1,%eax
f8100e84:	66 89 42 04          	mov    %ax,0x4(%edx)
f8100e88:	66 85 c0             	test   %ax,%ax
f8100e8b:	75 0c                	jne    f8100e99 <page_decref+0x25>
		page_free(pp);
f8100e8d:	83 ec 0c             	sub    $0xc,%esp
f8100e90:	52                   	push   %edx
f8100e91:	e8 a3 ff ff ff       	call   f8100e39 <page_free>
f8100e96:	83 c4 10             	add    $0x10,%esp
}
f8100e99:	c9                   	leave  
f8100e9a:	c3                   	ret    

f8100e9b <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f8100e9b:	55                   	push   %ebp
f8100e9c:	89 e5                	mov    %esp,%ebp
f8100e9e:	56                   	push   %esi
f8100e9f:	53                   	push   %ebx
f8100ea0:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	if (!(pgdir[PDX(va)] & PTE_P)) {              //if pde does not exist
f8100ea3:	89 f3                	mov    %esi,%ebx
f8100ea5:	c1 eb 16             	shr    $0x16,%ebx
f8100ea8:	c1 e3 02             	shl    $0x2,%ebx
f8100eab:	03 5d 08             	add    0x8(%ebp),%ebx
f8100eae:	f6 03 01             	testb  $0x1,(%ebx)
f8100eb1:	75 2d                	jne    f8100ee0 <pgdir_walk+0x45>
		if (create == false)
f8100eb3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f8100eb7:	74 62                	je     f8100f1b <pgdir_walk+0x80>
			return NULL;
		struct PageInfo *pi = page_alloc(ALLOC_ZERO);   //allocate zero page
f8100eb9:	83 ec 0c             	sub    $0xc,%esp
f8100ebc:	6a 01                	push   $0x1
f8100ebe:	e8 06 ff ff ff       	call   f8100dc9 <page_alloc>
		if (pi == NULL)             //fail to allocate
f8100ec3:	83 c4 10             	add    $0x10,%esp
f8100ec6:	85 c0                	test   %eax,%eax
f8100ec8:	74 58                	je     f8100f22 <pgdir_walk+0x87>
			return NULL;
		pi->pp_ref++;
f8100eca:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		pgdir[PDX(va)] = page2pa(pi) | PTE_P | PTE_U | PTE_W;	//use PTE_U and PTE_W to pass checkings
f8100ecf:	2b 05 70 79 11 f8    	sub    0xf8117970,%eax
f8100ed5:	c1 f8 03             	sar    $0x3,%eax
f8100ed8:	c1 e0 0c             	shl    $0xc,%eax
f8100edb:	83 c8 07             	or     $0x7,%eax
f8100ede:	89 03                	mov    %eax,(%ebx)
	}              //分配页表
	pte_t *pgtbl = KADDR(PTE_ADDR(pgdir[PDX(va)]));
f8100ee0:	8b 03                	mov    (%ebx),%eax
f8100ee2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f8100ee7:	89 c2                	mov    %eax,%edx
f8100ee9:	c1 ea 0c             	shr    $0xc,%edx
f8100eec:	3b 15 68 79 11 f8    	cmp    0xf8117968,%edx
f8100ef2:	72 15                	jb     f8100f09 <pgdir_walk+0x6e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f8100ef4:	50                   	push   %eax
f8100ef5:	68 20 40 10 f8       	push   $0xf8104020
f8100efa:	68 72 01 00 00       	push   $0x172
f8100eff:	68 de 3c 10 f8       	push   $0xf8103cde
f8100f04:	e8 82 f1 ff ff       	call   f810008b <_panic>
	pte_t *pte = pgtbl + PTX(va);        //在二级页表中找到对应的PTE项，返回的是地址
f8100f09:	c1 ee 0a             	shr    $0xa,%esi
f8100f0c:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
	return pte;
f8100f12:	8d 84 30 00 00 00 f8 	lea    -0x8000000(%eax,%esi,1),%eax
f8100f19:	eb 0c                	jmp    f8100f27 <pgdir_walk+0x8c>
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
	// Fill this function in
	if (!(pgdir[PDX(va)] & PTE_P)) {              //if pde does not exist
		if (create == false)
			return NULL;
f8100f1b:	b8 00 00 00 00       	mov    $0x0,%eax
f8100f20:	eb 05                	jmp    f8100f27 <pgdir_walk+0x8c>
		struct PageInfo *pi = page_alloc(ALLOC_ZERO);   //allocate zero page
		if (pi == NULL)             //fail to allocate
			return NULL;
f8100f22:	b8 00 00 00 00       	mov    $0x0,%eax
		pgdir[PDX(va)] = page2pa(pi) | PTE_P | PTE_U | PTE_W;	//use PTE_U and PTE_W to pass checkings
	}              //分配页表
	pte_t *pgtbl = KADDR(PTE_ADDR(pgdir[PDX(va)]));
	pte_t *pte = pgtbl + PTX(va);        //在二级页表中找到对应的PTE项，返回的是地址
	return pte;
}
f8100f27:	8d 65 f8             	lea    -0x8(%ebp),%esp
f8100f2a:	5b                   	pop    %ebx
f8100f2b:	5e                   	pop    %esi
f8100f2c:	5d                   	pop    %ebp
f8100f2d:	c3                   	ret    

f8100f2e <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f8100f2e:	55                   	push   %ebp
f8100f2f:	89 e5                	mov    %esp,%ebp
f8100f31:	57                   	push   %edi
f8100f32:	56                   	push   %esi
f8100f33:	53                   	push   %ebx
f8100f34:	83 ec 1c             	sub    $0x1c,%esp
f8100f37:	89 c7                	mov    %eax,%edi
f8100f39:	89 55 e0             	mov    %edx,-0x20(%ebp)
f8100f3c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	for (int i = 0; i < size; i += PGSIZE) {      //分配size/PGSIZE个页面
f8100f3f:	be 00 00 00 00       	mov    $0x0,%esi
		pte_t *pte = pgdir_walk(pgdir, (const void *)(va + i), true);    //使用虚拟地址分配
		if (pte == NULL)
			panic("No avaliable free page");
		*pte = (PTE_ADDR(pa + i)) | perm | PTE_P;   //在PTE项中填入对应地址
f8100f44:	8b 45 0c             	mov    0xc(%ebp),%eax
f8100f47:	83 c8 01             	or     $0x1,%eax
f8100f4a:	89 45 dc             	mov    %eax,-0x24(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	for (int i = 0; i < size; i += PGSIZE) {      //分配size/PGSIZE个页面
f8100f4d:	eb 43                	jmp    f8100f92 <boot_map_region+0x64>
		pte_t *pte = pgdir_walk(pgdir, (const void *)(va + i), true);    //使用虚拟地址分配
f8100f4f:	83 ec 04             	sub    $0x4,%esp
f8100f52:	6a 01                	push   $0x1
f8100f54:	8b 45 e0             	mov    -0x20(%ebp),%eax
f8100f57:	01 f0                	add    %esi,%eax
f8100f59:	50                   	push   %eax
f8100f5a:	57                   	push   %edi
f8100f5b:	e8 3b ff ff ff       	call   f8100e9b <pgdir_walk>
		if (pte == NULL)
f8100f60:	83 c4 10             	add    $0x10,%esp
f8100f63:	85 c0                	test   %eax,%eax
f8100f65:	75 17                	jne    f8100f7e <boot_map_region+0x50>
			panic("No avaliable free page");
f8100f67:	83 ec 04             	sub    $0x4,%esp
f8100f6a:	68 ae 3d 10 f8       	push   $0xf8103dae
f8100f6f:	68 89 01 00 00       	push   $0x189
f8100f74:	68 de 3c 10 f8       	push   $0xf8103cde
f8100f79:	e8 0d f1 ff ff       	call   f810008b <_panic>
		*pte = (PTE_ADDR(pa + i)) | perm | PTE_P;   //在PTE项中填入对应地址
f8100f7e:	03 5d 08             	add    0x8(%ebp),%ebx
f8100f81:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f8100f87:	0b 5d dc             	or     -0x24(%ebp),%ebx
f8100f8a:	89 18                	mov    %ebx,(%eax)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	for (int i = 0; i < size; i += PGSIZE) {      //分配size/PGSIZE个页面
f8100f8c:	81 c6 00 10 00 00    	add    $0x1000,%esi
f8100f92:	89 f3                	mov    %esi,%ebx
f8100f94:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f8100f97:	77 b6                	ja     f8100f4f <boot_map_region+0x21>
		pte_t *pte = pgdir_walk(pgdir, (const void *)(va + i), true);    //使用虚拟地址分配
		if (pte == NULL)
			panic("No avaliable free page");
		*pte = (PTE_ADDR(pa + i)) | perm | PTE_P;   //在PTE项中填入对应地址
	}
}
f8100f99:	8d 65 f4             	lea    -0xc(%ebp),%esp
f8100f9c:	5b                   	pop    %ebx
f8100f9d:	5e                   	pop    %esi
f8100f9e:	5f                   	pop    %edi
f8100f9f:	5d                   	pop    %ebp
f8100fa0:	c3                   	ret    

f8100fa1 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f8100fa1:	55                   	push   %ebp
f8100fa2:	89 e5                	mov    %esp,%ebp
f8100fa4:	83 ec 0c             	sub    $0xc,%esp
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, false);
f8100fa7:	6a 00                	push   $0x0
f8100fa9:	ff 75 0c             	pushl  0xc(%ebp)
f8100fac:	ff 75 08             	pushl  0x8(%ebp)
f8100faf:	e8 e7 fe ff ff       	call   f8100e9b <pgdir_walk>
	if (pte != NULL) {
f8100fb4:	83 c4 10             	add    $0x10,%esp
f8100fb7:	85 c0                	test   %eax,%eax
f8100fb9:	74 36                	je     f8100ff1 <page_lookup+0x50>
        if (!(*pte & PTE_P))
f8100fbb:	f6 00 01             	testb  $0x1,(%eax)
f8100fbe:	74 38                	je     f8100ff8 <page_lookup+0x57>
            return NULL;
		*pte_store = pte;
f8100fc0:	8b 55 10             	mov    0x10(%ebp),%edx
f8100fc3:	89 02                	mov    %eax,(%edx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f8100fc5:	8b 00                	mov    (%eax),%eax
f8100fc7:	c1 e8 0c             	shr    $0xc,%eax
f8100fca:	3b 05 68 79 11 f8    	cmp    0xf8117968,%eax
f8100fd0:	72 14                	jb     f8100fe6 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f8100fd2:	83 ec 04             	sub    $0x4,%esp
f8100fd5:	68 2c 41 10 f8       	push   $0xf810412c
f8100fda:	6a 4b                	push   $0x4b
f8100fdc:	68 ea 3c 10 f8       	push   $0xf8103cea
f8100fe1:	e8 a5 f0 ff ff       	call   f810008b <_panic>
	return &pages[PGNUM(pa)];
f8100fe6:	8b 15 70 79 11 f8    	mov    0xf8117970,%edx
f8100fec:	8d 04 c2             	lea    (%edx,%eax,8),%eax
		physaddr_t pa = PTE_ADDR(*pte) | PGOFF(va);
		return pa2page(pa);
f8100fef:	eb 0c                	jmp    f8100ffd <page_lookup+0x5c>
	}
	return NULL;
f8100ff1:	b8 00 00 00 00       	mov    $0x0,%eax
f8100ff6:	eb 05                	jmp    f8100ffd <page_lookup+0x5c>
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, false);
	if (pte != NULL) {
        if (!(*pte & PTE_P))
            return NULL;
f8100ff8:	b8 00 00 00 00       	mov    $0x0,%eax
		*pte_store = pte;
		physaddr_t pa = PTE_ADDR(*pte) | PGOFF(va);
		return pa2page(pa);
	}
	return NULL;
}
f8100ffd:	c9                   	leave  
f8100ffe:	c3                   	ret    

f8100fff <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f8100fff:	55                   	push   %ebp
f8101000:	89 e5                	mov    %esp,%ebp
f8101002:	56                   	push   %esi
f8101003:	53                   	push   %ebx
f8101004:	83 ec 14             	sub    $0x14,%esp
f8101007:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pi = page_lookup(pgdir, va, &pte);
f810100a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f810100d:	50                   	push   %eax
f810100e:	56                   	push   %esi
f810100f:	ff 75 08             	pushl  0x8(%ebp)
f8101012:	e8 8a ff ff ff       	call   f8100fa1 <page_lookup>
	if (pi == NULL)
f8101017:	83 c4 10             	add    $0x10,%esp
f810101a:	85 c0                	test   %eax,%eax
f810101c:	74 1e                	je     f810103c <page_remove+0x3d>
f810101e:	89 c3                	mov    %eax,%ebx
		return;
	page_decref(pi);
f8101020:	83 ec 0c             	sub    $0xc,%esp
f8101023:	50                   	push   %eax
f8101024:	e8 4b fe ff ff       	call   f8100e74 <page_decref>
	*pte &= ~PTE_P;
f8101029:	8b 45 f4             	mov    -0xc(%ebp),%eax
f810102c:	83 20 fe             	andl   $0xfffffffe,(%eax)
	if (pi->pp_ref == 0) {
f810102f:	83 c4 10             	add    $0x10,%esp
f8101032:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f8101037:	75 03                	jne    f810103c <page_remove+0x3d>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f8101039:	0f 01 3e             	invlpg (%esi)
		tlb_invalidate(pgdir, va);
	}
}
f810103c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f810103f:	5b                   	pop    %ebx
f8101040:	5e                   	pop    %esi
f8101041:	5d                   	pop    %ebp
f8101042:	c3                   	ret    

f8101043 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f8101043:	55                   	push   %ebp
f8101044:	89 e5                	mov    %esp,%ebp
f8101046:	57                   	push   %edi
f8101047:	56                   	push   %esi
f8101048:	53                   	push   %ebx
f8101049:	83 ec 10             	sub    $0x10,%esp
f810104c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f810104f:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, true);
f8101052:	6a 01                	push   $0x1
f8101054:	57                   	push   %edi
f8101055:	ff 75 08             	pushl  0x8(%ebp)
f8101058:	e8 3e fe ff ff       	call   f8100e9b <pgdir_walk>
	if (pte == NULL)
f810105d:	83 c4 10             	add    $0x10,%esp
f8101060:	85 c0                	test   %eax,%eax
f8101062:	74 38                	je     f810109c <page_insert+0x59>
f8101064:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f8101066:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if (*pte & PTE_P) {
f810106b:	f6 00 01             	testb  $0x1,(%eax)
f810106e:	74 0f                	je     f810107f <page_insert+0x3c>
		page_remove(pgdir, va);
f8101070:	83 ec 08             	sub    $0x8,%esp
f8101073:	57                   	push   %edi
f8101074:	ff 75 08             	pushl  0x8(%ebp)
f8101077:	e8 83 ff ff ff       	call   f8100fff <page_remove>
f810107c:	83 c4 10             	add    $0x10,%esp
	}
	*pte = (page2pa(pp) | perm | PTE_P);
f810107f:	2b 1d 70 79 11 f8    	sub    0xf8117970,%ebx
f8101085:	c1 fb 03             	sar    $0x3,%ebx
f8101088:	c1 e3 0c             	shl    $0xc,%ebx
f810108b:	8b 45 14             	mov    0x14(%ebp),%eax
f810108e:	83 c8 01             	or     $0x1,%eax
f8101091:	09 c3                	or     %eax,%ebx
f8101093:	89 1e                	mov    %ebx,(%esi)
	//pgdir[PDX(va)] |= perm;
	return 0;
f8101095:	b8 00 00 00 00       	mov    $0x0,%eax
f810109a:	eb 05                	jmp    f81010a1 <page_insert+0x5e>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, true);
	if (pte == NULL)
		return -E_NO_MEM;
f810109c:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir, va);
	}
	*pte = (page2pa(pp) | perm | PTE_P);
	//pgdir[PDX(va)] |= perm;
	return 0;
}
f81010a1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f81010a4:	5b                   	pop    %ebx
f81010a5:	5e                   	pop    %esi
f81010a6:	5f                   	pop    %edi
f81010a7:	5d                   	pop    %ebp
f81010a8:	c3                   	ret    

f81010a9 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f81010a9:	55                   	push   %ebp
f81010aa:	89 e5                	mov    %esp,%ebp
f81010ac:	57                   	push   %edi
f81010ad:	56                   	push   %esi
f81010ae:	53                   	push   %ebx
f81010af:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f81010b2:	b8 15 00 00 00       	mov    $0x15,%eax
f81010b7:	e8 77 f8 ff ff       	call   f8100933 <nvram_read>
f81010bc:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f81010be:	b8 17 00 00 00       	mov    $0x17,%eax
f81010c3:	e8 6b f8 ff ff       	call   f8100933 <nvram_read>
f81010c8:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f81010ca:	b8 34 00 00 00       	mov    $0x34,%eax
f81010cf:	e8 5f f8 ff ff       	call   f8100933 <nvram_read>
f81010d4:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f81010d7:	85 c0                	test   %eax,%eax
f81010d9:	74 07                	je     f81010e2 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f81010db:	05 00 40 00 00       	add    $0x4000,%eax
f81010e0:	eb 0b                	jmp    f81010ed <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f81010e2:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f81010e8:	85 f6                	test   %esi,%esi
f81010ea:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f81010ed:	89 c2                	mov    %eax,%edx
f81010ef:	c1 ea 02             	shr    $0x2,%edx
f81010f2:	89 15 68 79 11 f8    	mov    %edx,0xf8117968
	npages_basemem = basemem / (PGSIZE / 1024);
f81010f8:	89 da                	mov    %ebx,%edx
f81010fa:	c1 ea 02             	shr    $0x2,%edx
f81010fd:	89 15 40 75 11 f8    	mov    %edx,0xf8117540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f8101103:	89 c2                	mov    %eax,%edx
f8101105:	29 da                	sub    %ebx,%edx
f8101107:	52                   	push   %edx
f8101108:	53                   	push   %ebx
f8101109:	50                   	push   %eax
f810110a:	68 4c 41 10 f8       	push   $0xf810414c
f810110f:	e8 4b 16 00 00       	call   f810275f <cprintf>
	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f8101114:	b8 00 10 00 00       	mov    $0x1000,%eax
f8101119:	e8 3e f8 ff ff       	call   f810095c <boot_alloc>
f810111e:	a3 6c 79 11 f8       	mov    %eax,0xf811796c
	memset(kern_pgdir, 0, PGSIZE);
f8101123:	83 c4 0c             	add    $0xc,%esp
f8101126:	68 00 10 00 00       	push   $0x1000
f810112b:	6a 00                	push   $0x0
f810112d:	50                   	push   %eax
f810112e:	e8 85 21 00 00       	call   f81032b8 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f8101133:	a1 6c 79 11 f8       	mov    0xf811796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f8101138:	83 c4 10             	add    $0x10,%esp
f810113b:	3d ff ff ff f7       	cmp    $0xf7ffffff,%eax
f8101140:	77 15                	ja     f8101157 <mem_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f8101142:	50                   	push   %eax
f8101143:	68 88 41 10 f8       	push   $0xf8104188
f8101148:	68 93 00 00 00       	push   $0x93
f810114d:	68 de 3c 10 f8       	push   $0xf8103cde
f8101152:	e8 34 ef ff ff       	call   f810008b <_panic>
f8101157:	8d 90 00 00 00 08    	lea    0x8000000(%eax),%edx
f810115d:	83 ca 05             	or     $0x5,%edx
f8101160:	89 90 74 0f 00 00    	mov    %edx,0xf74(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	uint32_t page_size = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
f8101166:	a1 68 79 11 f8       	mov    0xf8117968,%eax
f810116b:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f8101172:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f8101177:	89 c7                	mov    %eax,%edi
f8101179:	89 45 cc             	mov    %eax,-0x34(%ebp)
	pages = (struct PageInfo *)boot_alloc(page_size);         //use boot_alloc allocating memory to store PageInfo struct
f810117c:	e8 db f7 ff ff       	call   f810095c <boot_alloc>
f8101181:	a3 70 79 11 f8       	mov    %eax,0xf8117970
	memset(pages, 0, page_size);
f8101186:	83 ec 04             	sub    $0x4,%esp
f8101189:	57                   	push   %edi
f810118a:	6a 00                	push   $0x0
f810118c:	50                   	push   %eax
f810118d:	e8 26 21 00 00       	call   f81032b8 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f8101192:	e8 70 fb ff ff       	call   f8100d07 <page_init>
	
	check_page_free_list(1);
f8101197:	b8 01 00 00 00       	mov    $0x1,%eax
f810119c:	e8 a3 f8 ff ff       	call   f8100a44 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f81011a1:	83 c4 10             	add    $0x10,%esp
f81011a4:	83 3d 70 79 11 f8 00 	cmpl   $0x0,0xf8117970
f81011ab:	75 17                	jne    f81011c4 <mem_init+0x11b>
		panic("'pages' is a null pointer!");
f81011ad:	83 ec 04             	sub    $0x4,%esp
f81011b0:	68 c5 3d 10 f8       	push   $0xf8103dc5
f81011b5:	68 4b 02 00 00       	push   $0x24b
f81011ba:	68 de 3c 10 f8       	push   $0xf8103cde
f81011bf:	e8 c7 ee ff ff       	call   f810008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f81011c4:	a1 3c 75 11 f8       	mov    0xf811753c,%eax
f81011c9:	bb 00 00 00 00       	mov    $0x0,%ebx
f81011ce:	eb 05                	jmp    f81011d5 <mem_init+0x12c>
		++nfree;
f81011d0:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f81011d3:	8b 00                	mov    (%eax),%eax
f81011d5:	85 c0                	test   %eax,%eax
f81011d7:	75 f7                	jne    f81011d0 <mem_init+0x127>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f81011d9:	83 ec 0c             	sub    $0xc,%esp
f81011dc:	6a 00                	push   $0x0
f81011de:	e8 e6 fb ff ff       	call   f8100dc9 <page_alloc>
f81011e3:	89 c7                	mov    %eax,%edi
f81011e5:	83 c4 10             	add    $0x10,%esp
f81011e8:	85 c0                	test   %eax,%eax
f81011ea:	75 19                	jne    f8101205 <mem_init+0x15c>
f81011ec:	68 e0 3d 10 f8       	push   $0xf8103de0
f81011f1:	68 04 3d 10 f8       	push   $0xf8103d04
f81011f6:	68 53 02 00 00       	push   $0x253
f81011fb:	68 de 3c 10 f8       	push   $0xf8103cde
f8101200:	e8 86 ee ff ff       	call   f810008b <_panic>
	assert((pp1 = page_alloc(0)));
f8101205:	83 ec 0c             	sub    $0xc,%esp
f8101208:	6a 00                	push   $0x0
f810120a:	e8 ba fb ff ff       	call   f8100dc9 <page_alloc>
f810120f:	89 c6                	mov    %eax,%esi
f8101211:	83 c4 10             	add    $0x10,%esp
f8101214:	85 c0                	test   %eax,%eax
f8101216:	75 19                	jne    f8101231 <mem_init+0x188>
f8101218:	68 f6 3d 10 f8       	push   $0xf8103df6
f810121d:	68 04 3d 10 f8       	push   $0xf8103d04
f8101222:	68 54 02 00 00       	push   $0x254
f8101227:	68 de 3c 10 f8       	push   $0xf8103cde
f810122c:	e8 5a ee ff ff       	call   f810008b <_panic>
	assert((pp2 = page_alloc(0)));
f8101231:	83 ec 0c             	sub    $0xc,%esp
f8101234:	6a 00                	push   $0x0
f8101236:	e8 8e fb ff ff       	call   f8100dc9 <page_alloc>
f810123b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f810123e:	83 c4 10             	add    $0x10,%esp
f8101241:	85 c0                	test   %eax,%eax
f8101243:	75 19                	jne    f810125e <mem_init+0x1b5>
f8101245:	68 0c 3e 10 f8       	push   $0xf8103e0c
f810124a:	68 04 3d 10 f8       	push   $0xf8103d04
f810124f:	68 55 02 00 00       	push   $0x255
f8101254:	68 de 3c 10 f8       	push   $0xf8103cde
f8101259:	e8 2d ee ff ff       	call   f810008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f810125e:	39 f7                	cmp    %esi,%edi
f8101260:	75 19                	jne    f810127b <mem_init+0x1d2>
f8101262:	68 22 3e 10 f8       	push   $0xf8103e22
f8101267:	68 04 3d 10 f8       	push   $0xf8103d04
f810126c:	68 58 02 00 00       	push   $0x258
f8101271:	68 de 3c 10 f8       	push   $0xf8103cde
f8101276:	e8 10 ee ff ff       	call   f810008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f810127b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f810127e:	39 c6                	cmp    %eax,%esi
f8101280:	74 04                	je     f8101286 <mem_init+0x1dd>
f8101282:	39 c7                	cmp    %eax,%edi
f8101284:	75 19                	jne    f810129f <mem_init+0x1f6>
f8101286:	68 ac 41 10 f8       	push   $0xf81041ac
f810128b:	68 04 3d 10 f8       	push   $0xf8103d04
f8101290:	68 59 02 00 00       	push   $0x259
f8101295:	68 de 3c 10 f8       	push   $0xf8103cde
f810129a:	e8 ec ed ff ff       	call   f810008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f810129f:	8b 0d 70 79 11 f8    	mov    0xf8117970,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f81012a5:	8b 15 68 79 11 f8    	mov    0xf8117968,%edx
f81012ab:	c1 e2 0c             	shl    $0xc,%edx
f81012ae:	89 f8                	mov    %edi,%eax
f81012b0:	29 c8                	sub    %ecx,%eax
f81012b2:	c1 f8 03             	sar    $0x3,%eax
f81012b5:	c1 e0 0c             	shl    $0xc,%eax
f81012b8:	39 d0                	cmp    %edx,%eax
f81012ba:	72 19                	jb     f81012d5 <mem_init+0x22c>
f81012bc:	68 34 3e 10 f8       	push   $0xf8103e34
f81012c1:	68 04 3d 10 f8       	push   $0xf8103d04
f81012c6:	68 5a 02 00 00       	push   $0x25a
f81012cb:	68 de 3c 10 f8       	push   $0xf8103cde
f81012d0:	e8 b6 ed ff ff       	call   f810008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f81012d5:	89 f0                	mov    %esi,%eax
f81012d7:	29 c8                	sub    %ecx,%eax
f81012d9:	c1 f8 03             	sar    $0x3,%eax
f81012dc:	c1 e0 0c             	shl    $0xc,%eax
f81012df:	39 c2                	cmp    %eax,%edx
f81012e1:	77 19                	ja     f81012fc <mem_init+0x253>
f81012e3:	68 51 3e 10 f8       	push   $0xf8103e51
f81012e8:	68 04 3d 10 f8       	push   $0xf8103d04
f81012ed:	68 5b 02 00 00       	push   $0x25b
f81012f2:	68 de 3c 10 f8       	push   $0xf8103cde
f81012f7:	e8 8f ed ff ff       	call   f810008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f81012fc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f81012ff:	29 c8                	sub    %ecx,%eax
f8101301:	c1 f8 03             	sar    $0x3,%eax
f8101304:	c1 e0 0c             	shl    $0xc,%eax
f8101307:	39 c2                	cmp    %eax,%edx
f8101309:	77 19                	ja     f8101324 <mem_init+0x27b>
f810130b:	68 6e 3e 10 f8       	push   $0xf8103e6e
f8101310:	68 04 3d 10 f8       	push   $0xf8103d04
f8101315:	68 5c 02 00 00       	push   $0x25c
f810131a:	68 de 3c 10 f8       	push   $0xf8103cde
f810131f:	e8 67 ed ff ff       	call   f810008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f8101324:	a1 3c 75 11 f8       	mov    0xf811753c,%eax
f8101329:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f810132c:	c7 05 3c 75 11 f8 00 	movl   $0x0,0xf811753c
f8101333:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f8101336:	83 ec 0c             	sub    $0xc,%esp
f8101339:	6a 00                	push   $0x0
f810133b:	e8 89 fa ff ff       	call   f8100dc9 <page_alloc>
f8101340:	83 c4 10             	add    $0x10,%esp
f8101343:	85 c0                	test   %eax,%eax
f8101345:	74 19                	je     f8101360 <mem_init+0x2b7>
f8101347:	68 8b 3e 10 f8       	push   $0xf8103e8b
f810134c:	68 04 3d 10 f8       	push   $0xf8103d04
f8101351:	68 63 02 00 00       	push   $0x263
f8101356:	68 de 3c 10 f8       	push   $0xf8103cde
f810135b:	e8 2b ed ff ff       	call   f810008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f8101360:	83 ec 0c             	sub    $0xc,%esp
f8101363:	57                   	push   %edi
f8101364:	e8 d0 fa ff ff       	call   f8100e39 <page_free>
	page_free(pp1);
f8101369:	89 34 24             	mov    %esi,(%esp)
f810136c:	e8 c8 fa ff ff       	call   f8100e39 <page_free>
	page_free(pp2);
f8101371:	83 c4 04             	add    $0x4,%esp
f8101374:	ff 75 d4             	pushl  -0x2c(%ebp)
f8101377:	e8 bd fa ff ff       	call   f8100e39 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f810137c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f8101383:	e8 41 fa ff ff       	call   f8100dc9 <page_alloc>
f8101388:	89 c6                	mov    %eax,%esi
f810138a:	83 c4 10             	add    $0x10,%esp
f810138d:	85 c0                	test   %eax,%eax
f810138f:	75 19                	jne    f81013aa <mem_init+0x301>
f8101391:	68 e0 3d 10 f8       	push   $0xf8103de0
f8101396:	68 04 3d 10 f8       	push   $0xf8103d04
f810139b:	68 6a 02 00 00       	push   $0x26a
f81013a0:	68 de 3c 10 f8       	push   $0xf8103cde
f81013a5:	e8 e1 ec ff ff       	call   f810008b <_panic>
	assert((pp1 = page_alloc(0)));
f81013aa:	83 ec 0c             	sub    $0xc,%esp
f81013ad:	6a 00                	push   $0x0
f81013af:	e8 15 fa ff ff       	call   f8100dc9 <page_alloc>
f81013b4:	89 c7                	mov    %eax,%edi
f81013b6:	83 c4 10             	add    $0x10,%esp
f81013b9:	85 c0                	test   %eax,%eax
f81013bb:	75 19                	jne    f81013d6 <mem_init+0x32d>
f81013bd:	68 f6 3d 10 f8       	push   $0xf8103df6
f81013c2:	68 04 3d 10 f8       	push   $0xf8103d04
f81013c7:	68 6b 02 00 00       	push   $0x26b
f81013cc:	68 de 3c 10 f8       	push   $0xf8103cde
f81013d1:	e8 b5 ec ff ff       	call   f810008b <_panic>
	assert((pp2 = page_alloc(0)));
f81013d6:	83 ec 0c             	sub    $0xc,%esp
f81013d9:	6a 00                	push   $0x0
f81013db:	e8 e9 f9 ff ff       	call   f8100dc9 <page_alloc>
f81013e0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f81013e3:	83 c4 10             	add    $0x10,%esp
f81013e6:	85 c0                	test   %eax,%eax
f81013e8:	75 19                	jne    f8101403 <mem_init+0x35a>
f81013ea:	68 0c 3e 10 f8       	push   $0xf8103e0c
f81013ef:	68 04 3d 10 f8       	push   $0xf8103d04
f81013f4:	68 6c 02 00 00       	push   $0x26c
f81013f9:	68 de 3c 10 f8       	push   $0xf8103cde
f81013fe:	e8 88 ec ff ff       	call   f810008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f8101403:	39 fe                	cmp    %edi,%esi
f8101405:	75 19                	jne    f8101420 <mem_init+0x377>
f8101407:	68 22 3e 10 f8       	push   $0xf8103e22
f810140c:	68 04 3d 10 f8       	push   $0xf8103d04
f8101411:	68 6e 02 00 00       	push   $0x26e
f8101416:	68 de 3c 10 f8       	push   $0xf8103cde
f810141b:	e8 6b ec ff ff       	call   f810008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f8101420:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f8101423:	39 c7                	cmp    %eax,%edi
f8101425:	74 04                	je     f810142b <mem_init+0x382>
f8101427:	39 c6                	cmp    %eax,%esi
f8101429:	75 19                	jne    f8101444 <mem_init+0x39b>
f810142b:	68 ac 41 10 f8       	push   $0xf81041ac
f8101430:	68 04 3d 10 f8       	push   $0xf8103d04
f8101435:	68 6f 02 00 00       	push   $0x26f
f810143a:	68 de 3c 10 f8       	push   $0xf8103cde
f810143f:	e8 47 ec ff ff       	call   f810008b <_panic>
	assert(!page_alloc(0));
f8101444:	83 ec 0c             	sub    $0xc,%esp
f8101447:	6a 00                	push   $0x0
f8101449:	e8 7b f9 ff ff       	call   f8100dc9 <page_alloc>
f810144e:	83 c4 10             	add    $0x10,%esp
f8101451:	85 c0                	test   %eax,%eax
f8101453:	74 19                	je     f810146e <mem_init+0x3c5>
f8101455:	68 8b 3e 10 f8       	push   $0xf8103e8b
f810145a:	68 04 3d 10 f8       	push   $0xf8103d04
f810145f:	68 70 02 00 00       	push   $0x270
f8101464:	68 de 3c 10 f8       	push   $0xf8103cde
f8101469:	e8 1d ec ff ff       	call   f810008b <_panic>
f810146e:	89 f0                	mov    %esi,%eax
f8101470:	2b 05 70 79 11 f8    	sub    0xf8117970,%eax
f8101476:	c1 f8 03             	sar    $0x3,%eax
f8101479:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f810147c:	89 c2                	mov    %eax,%edx
f810147e:	c1 ea 0c             	shr    $0xc,%edx
f8101481:	3b 15 68 79 11 f8    	cmp    0xf8117968,%edx
f8101487:	72 12                	jb     f810149b <mem_init+0x3f2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f8101489:	50                   	push   %eax
f810148a:	68 20 40 10 f8       	push   $0xf8104020
f810148f:	6a 52                	push   $0x52
f8101491:	68 ea 3c 10 f8       	push   $0xf8103cea
f8101496:	e8 f0 eb ff ff       	call   f810008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f810149b:	83 ec 04             	sub    $0x4,%esp
f810149e:	68 00 10 00 00       	push   $0x1000
f81014a3:	6a 01                	push   $0x1
f81014a5:	2d 00 00 00 08       	sub    $0x8000000,%eax
f81014aa:	50                   	push   %eax
f81014ab:	e8 08 1e 00 00       	call   f81032b8 <memset>
	page_free(pp0);
f81014b0:	89 34 24             	mov    %esi,(%esp)
f81014b3:	e8 81 f9 ff ff       	call   f8100e39 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f81014b8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f81014bf:	e8 05 f9 ff ff       	call   f8100dc9 <page_alloc>
f81014c4:	83 c4 10             	add    $0x10,%esp
f81014c7:	85 c0                	test   %eax,%eax
f81014c9:	75 19                	jne    f81014e4 <mem_init+0x43b>
f81014cb:	68 9a 3e 10 f8       	push   $0xf8103e9a
f81014d0:	68 04 3d 10 f8       	push   $0xf8103d04
f81014d5:	68 75 02 00 00       	push   $0x275
f81014da:	68 de 3c 10 f8       	push   $0xf8103cde
f81014df:	e8 a7 eb ff ff       	call   f810008b <_panic>
	assert(pp && pp0 == pp);
f81014e4:	39 c6                	cmp    %eax,%esi
f81014e6:	74 19                	je     f8101501 <mem_init+0x458>
f81014e8:	68 b8 3e 10 f8       	push   $0xf8103eb8
f81014ed:	68 04 3d 10 f8       	push   $0xf8103d04
f81014f2:	68 76 02 00 00       	push   $0x276
f81014f7:	68 de 3c 10 f8       	push   $0xf8103cde
f81014fc:	e8 8a eb ff ff       	call   f810008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f8101501:	89 f0                	mov    %esi,%eax
f8101503:	2b 05 70 79 11 f8    	sub    0xf8117970,%eax
f8101509:	c1 f8 03             	sar    $0x3,%eax
f810150c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f810150f:	89 c2                	mov    %eax,%edx
f8101511:	c1 ea 0c             	shr    $0xc,%edx
f8101514:	3b 15 68 79 11 f8    	cmp    0xf8117968,%edx
f810151a:	72 12                	jb     f810152e <mem_init+0x485>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f810151c:	50                   	push   %eax
f810151d:	68 20 40 10 f8       	push   $0xf8104020
f8101522:	6a 52                	push   $0x52
f8101524:	68 ea 3c 10 f8       	push   $0xf8103cea
f8101529:	e8 5d eb ff ff       	call   f810008b <_panic>
f810152e:	8d 90 00 10 00 f8    	lea    -0x7fff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f8101534:	8d 80 00 00 00 f8    	lea    -0x8000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f810153a:	80 38 00             	cmpb   $0x0,(%eax)
f810153d:	74 19                	je     f8101558 <mem_init+0x4af>
f810153f:	68 c8 3e 10 f8       	push   $0xf8103ec8
f8101544:	68 04 3d 10 f8       	push   $0xf8103d04
f8101549:	68 79 02 00 00       	push   $0x279
f810154e:	68 de 3c 10 f8       	push   $0xf8103cde
f8101553:	e8 33 eb ff ff       	call   f810008b <_panic>
f8101558:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f810155b:	39 d0                	cmp    %edx,%eax
f810155d:	75 db                	jne    f810153a <mem_init+0x491>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f810155f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f8101562:	a3 3c 75 11 f8       	mov    %eax,0xf811753c

	// free the pages we took
	page_free(pp0);
f8101567:	83 ec 0c             	sub    $0xc,%esp
f810156a:	56                   	push   %esi
f810156b:	e8 c9 f8 ff ff       	call   f8100e39 <page_free>
	page_free(pp1);
f8101570:	89 3c 24             	mov    %edi,(%esp)
f8101573:	e8 c1 f8 ff ff       	call   f8100e39 <page_free>
	page_free(pp2);
f8101578:	83 c4 04             	add    $0x4,%esp
f810157b:	ff 75 d4             	pushl  -0x2c(%ebp)
f810157e:	e8 b6 f8 ff ff       	call   f8100e39 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f8101583:	a1 3c 75 11 f8       	mov    0xf811753c,%eax
f8101588:	83 c4 10             	add    $0x10,%esp
f810158b:	eb 05                	jmp    f8101592 <mem_init+0x4e9>
		--nfree;
f810158d:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f8101590:	8b 00                	mov    (%eax),%eax
f8101592:	85 c0                	test   %eax,%eax
f8101594:	75 f7                	jne    f810158d <mem_init+0x4e4>
		--nfree;
	assert(nfree == 0);
f8101596:	85 db                	test   %ebx,%ebx
f8101598:	74 19                	je     f81015b3 <mem_init+0x50a>
f810159a:	68 d2 3e 10 f8       	push   $0xf8103ed2
f810159f:	68 04 3d 10 f8       	push   $0xf8103d04
f81015a4:	68 86 02 00 00       	push   $0x286
f81015a9:	68 de 3c 10 f8       	push   $0xf8103cde
f81015ae:	e8 d8 ea ff ff       	call   f810008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f81015b3:	83 ec 0c             	sub    $0xc,%esp
f81015b6:	68 cc 41 10 f8       	push   $0xf81041cc
f81015bb:	e8 9f 11 00 00       	call   f810275f <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f81015c0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f81015c7:	e8 fd f7 ff ff       	call   f8100dc9 <page_alloc>
f81015cc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f81015cf:	83 c4 10             	add    $0x10,%esp
f81015d2:	85 c0                	test   %eax,%eax
f81015d4:	75 19                	jne    f81015ef <mem_init+0x546>
f81015d6:	68 e0 3d 10 f8       	push   $0xf8103de0
f81015db:	68 04 3d 10 f8       	push   $0xf8103d04
f81015e0:	68 df 02 00 00       	push   $0x2df
f81015e5:	68 de 3c 10 f8       	push   $0xf8103cde
f81015ea:	e8 9c ea ff ff       	call   f810008b <_panic>
	assert((pp1 = page_alloc(0)));
f81015ef:	83 ec 0c             	sub    $0xc,%esp
f81015f2:	6a 00                	push   $0x0
f81015f4:	e8 d0 f7 ff ff       	call   f8100dc9 <page_alloc>
f81015f9:	89 c3                	mov    %eax,%ebx
f81015fb:	83 c4 10             	add    $0x10,%esp
f81015fe:	85 c0                	test   %eax,%eax
f8101600:	75 19                	jne    f810161b <mem_init+0x572>
f8101602:	68 f6 3d 10 f8       	push   $0xf8103df6
f8101607:	68 04 3d 10 f8       	push   $0xf8103d04
f810160c:	68 e0 02 00 00       	push   $0x2e0
f8101611:	68 de 3c 10 f8       	push   $0xf8103cde
f8101616:	e8 70 ea ff ff       	call   f810008b <_panic>
	assert((pp2 = page_alloc(0)));
f810161b:	83 ec 0c             	sub    $0xc,%esp
f810161e:	6a 00                	push   $0x0
f8101620:	e8 a4 f7 ff ff       	call   f8100dc9 <page_alloc>
f8101625:	89 c6                	mov    %eax,%esi
f8101627:	83 c4 10             	add    $0x10,%esp
f810162a:	85 c0                	test   %eax,%eax
f810162c:	75 19                	jne    f8101647 <mem_init+0x59e>
f810162e:	68 0c 3e 10 f8       	push   $0xf8103e0c
f8101633:	68 04 3d 10 f8       	push   $0xf8103d04
f8101638:	68 e1 02 00 00       	push   $0x2e1
f810163d:	68 de 3c 10 f8       	push   $0xf8103cde
f8101642:	e8 44 ea ff ff       	call   f810008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f8101647:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f810164a:	75 19                	jne    f8101665 <mem_init+0x5bc>
f810164c:	68 22 3e 10 f8       	push   $0xf8103e22
f8101651:	68 04 3d 10 f8       	push   $0xf8103d04
f8101656:	68 e4 02 00 00       	push   $0x2e4
f810165b:	68 de 3c 10 f8       	push   $0xf8103cde
f8101660:	e8 26 ea ff ff       	call   f810008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f8101665:	39 c3                	cmp    %eax,%ebx
f8101667:	74 05                	je     f810166e <mem_init+0x5c5>
f8101669:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f810166c:	75 19                	jne    f8101687 <mem_init+0x5de>
f810166e:	68 ac 41 10 f8       	push   $0xf81041ac
f8101673:	68 04 3d 10 f8       	push   $0xf8103d04
f8101678:	68 e5 02 00 00       	push   $0x2e5
f810167d:	68 de 3c 10 f8       	push   $0xf8103cde
f8101682:	e8 04 ea ff ff       	call   f810008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f8101687:	a1 3c 75 11 f8       	mov    0xf811753c,%eax
f810168c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f810168f:	c7 05 3c 75 11 f8 00 	movl   $0x0,0xf811753c
f8101696:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f8101699:	83 ec 0c             	sub    $0xc,%esp
f810169c:	6a 00                	push   $0x0
f810169e:	e8 26 f7 ff ff       	call   f8100dc9 <page_alloc>
f81016a3:	83 c4 10             	add    $0x10,%esp
f81016a6:	85 c0                	test   %eax,%eax
f81016a8:	74 19                	je     f81016c3 <mem_init+0x61a>
f81016aa:	68 8b 3e 10 f8       	push   $0xf8103e8b
f81016af:	68 04 3d 10 f8       	push   $0xf8103d04
f81016b4:	68 ec 02 00 00       	push   $0x2ec
f81016b9:	68 de 3c 10 f8       	push   $0xf8103cde
f81016be:	e8 c8 e9 ff ff       	call   f810008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f81016c3:	83 ec 04             	sub    $0x4,%esp
f81016c6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f81016c9:	50                   	push   %eax
f81016ca:	6a 00                	push   $0x0
f81016cc:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f81016d2:	e8 ca f8 ff ff       	call   f8100fa1 <page_lookup>
f81016d7:	83 c4 10             	add    $0x10,%esp
f81016da:	85 c0                	test   %eax,%eax
f81016dc:	74 19                	je     f81016f7 <mem_init+0x64e>
f81016de:	68 ec 41 10 f8       	push   $0xf81041ec
f81016e3:	68 04 3d 10 f8       	push   $0xf8103d04
f81016e8:	68 ef 02 00 00       	push   $0x2ef
f81016ed:	68 de 3c 10 f8       	push   $0xf8103cde
f81016f2:	e8 94 e9 ff ff       	call   f810008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f81016f7:	6a 02                	push   $0x2
f81016f9:	6a 00                	push   $0x0
f81016fb:	53                   	push   %ebx
f81016fc:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f8101702:	e8 3c f9 ff ff       	call   f8101043 <page_insert>
f8101707:	83 c4 10             	add    $0x10,%esp
f810170a:	85 c0                	test   %eax,%eax
f810170c:	78 19                	js     f8101727 <mem_init+0x67e>
f810170e:	68 24 42 10 f8       	push   $0xf8104224
f8101713:	68 04 3d 10 f8       	push   $0xf8103d04
f8101718:	68 f2 02 00 00       	push   $0x2f2
f810171d:	68 de 3c 10 f8       	push   $0xf8103cde
f8101722:	e8 64 e9 ff ff       	call   f810008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f8101727:	83 ec 0c             	sub    $0xc,%esp
f810172a:	ff 75 d4             	pushl  -0x2c(%ebp)
f810172d:	e8 07 f7 ff ff       	call   f8100e39 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f8101732:	6a 02                	push   $0x2
f8101734:	6a 00                	push   $0x0
f8101736:	53                   	push   %ebx
f8101737:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f810173d:	e8 01 f9 ff ff       	call   f8101043 <page_insert>
f8101742:	83 c4 20             	add    $0x20,%esp
f8101745:	85 c0                	test   %eax,%eax
f8101747:	74 19                	je     f8101762 <mem_init+0x6b9>
f8101749:	68 54 42 10 f8       	push   $0xf8104254
f810174e:	68 04 3d 10 f8       	push   $0xf8103d04
f8101753:	68 f6 02 00 00       	push   $0x2f6
f8101758:	68 de 3c 10 f8       	push   $0xf8103cde
f810175d:	e8 29 e9 ff ff       	call   f810008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f8101762:	8b 3d 6c 79 11 f8    	mov    0xf811796c,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f8101768:	a1 70 79 11 f8       	mov    0xf8117970,%eax
f810176d:	89 c1                	mov    %eax,%ecx
f810176f:	89 45 c8             	mov    %eax,-0x38(%ebp)
f8101772:	8b 17                	mov    (%edi),%edx
f8101774:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f810177a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f810177d:	29 c8                	sub    %ecx,%eax
f810177f:	c1 f8 03             	sar    $0x3,%eax
f8101782:	c1 e0 0c             	shl    $0xc,%eax
f8101785:	39 c2                	cmp    %eax,%edx
f8101787:	74 19                	je     f81017a2 <mem_init+0x6f9>
f8101789:	68 84 42 10 f8       	push   $0xf8104284
f810178e:	68 04 3d 10 f8       	push   $0xf8103d04
f8101793:	68 f7 02 00 00       	push   $0x2f7
f8101798:	68 de 3c 10 f8       	push   $0xf8103cde
f810179d:	e8 e9 e8 ff ff       	call   f810008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f81017a2:	ba 00 00 00 00       	mov    $0x0,%edx
f81017a7:	89 f8                	mov    %edi,%eax
f81017a9:	e8 32 f2 ff ff       	call   f81009e0 <check_va2pa>
f81017ae:	89 da                	mov    %ebx,%edx
f81017b0:	2b 55 c8             	sub    -0x38(%ebp),%edx
f81017b3:	c1 fa 03             	sar    $0x3,%edx
f81017b6:	c1 e2 0c             	shl    $0xc,%edx
f81017b9:	39 d0                	cmp    %edx,%eax
f81017bb:	74 19                	je     f81017d6 <mem_init+0x72d>
f81017bd:	68 ac 42 10 f8       	push   $0xf81042ac
f81017c2:	68 04 3d 10 f8       	push   $0xf8103d04
f81017c7:	68 f8 02 00 00       	push   $0x2f8
f81017cc:	68 de 3c 10 f8       	push   $0xf8103cde
f81017d1:	e8 b5 e8 ff ff       	call   f810008b <_panic>
	assert(pp1->pp_ref == 1);
f81017d6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f81017db:	74 19                	je     f81017f6 <mem_init+0x74d>
f81017dd:	68 dd 3e 10 f8       	push   $0xf8103edd
f81017e2:	68 04 3d 10 f8       	push   $0xf8103d04
f81017e7:	68 f9 02 00 00       	push   $0x2f9
f81017ec:	68 de 3c 10 f8       	push   $0xf8103cde
f81017f1:	e8 95 e8 ff ff       	call   f810008b <_panic>
	assert(pp0->pp_ref == 1);
f81017f6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f81017f9:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f81017fe:	74 19                	je     f8101819 <mem_init+0x770>
f8101800:	68 ee 3e 10 f8       	push   $0xf8103eee
f8101805:	68 04 3d 10 f8       	push   $0xf8103d04
f810180a:	68 fa 02 00 00       	push   $0x2fa
f810180f:	68 de 3c 10 f8       	push   $0xf8103cde
f8101814:	e8 72 e8 ff ff       	call   f810008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f8101819:	6a 02                	push   $0x2
f810181b:	68 00 10 00 00       	push   $0x1000
f8101820:	56                   	push   %esi
f8101821:	57                   	push   %edi
f8101822:	e8 1c f8 ff ff       	call   f8101043 <page_insert>
f8101827:	83 c4 10             	add    $0x10,%esp
f810182a:	85 c0                	test   %eax,%eax
f810182c:	74 19                	je     f8101847 <mem_init+0x79e>
f810182e:	68 dc 42 10 f8       	push   $0xf81042dc
f8101833:	68 04 3d 10 f8       	push   $0xf8103d04
f8101838:	68 fd 02 00 00       	push   $0x2fd
f810183d:	68 de 3c 10 f8       	push   $0xf8103cde
f8101842:	e8 44 e8 ff ff       	call   f810008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f8101847:	ba 00 10 00 00       	mov    $0x1000,%edx
f810184c:	a1 6c 79 11 f8       	mov    0xf811796c,%eax
f8101851:	e8 8a f1 ff ff       	call   f81009e0 <check_va2pa>
f8101856:	89 f2                	mov    %esi,%edx
f8101858:	2b 15 70 79 11 f8    	sub    0xf8117970,%edx
f810185e:	c1 fa 03             	sar    $0x3,%edx
f8101861:	c1 e2 0c             	shl    $0xc,%edx
f8101864:	39 d0                	cmp    %edx,%eax
f8101866:	74 19                	je     f8101881 <mem_init+0x7d8>
f8101868:	68 18 43 10 f8       	push   $0xf8104318
f810186d:	68 04 3d 10 f8       	push   $0xf8103d04
f8101872:	68 fe 02 00 00       	push   $0x2fe
f8101877:	68 de 3c 10 f8       	push   $0xf8103cde
f810187c:	e8 0a e8 ff ff       	call   f810008b <_panic>
	assert(pp2->pp_ref == 1);
f8101881:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f8101886:	74 19                	je     f81018a1 <mem_init+0x7f8>
f8101888:	68 ff 3e 10 f8       	push   $0xf8103eff
f810188d:	68 04 3d 10 f8       	push   $0xf8103d04
f8101892:	68 ff 02 00 00       	push   $0x2ff
f8101897:	68 de 3c 10 f8       	push   $0xf8103cde
f810189c:	e8 ea e7 ff ff       	call   f810008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f81018a1:	83 ec 0c             	sub    $0xc,%esp
f81018a4:	6a 00                	push   $0x0
f81018a6:	e8 1e f5 ff ff       	call   f8100dc9 <page_alloc>
f81018ab:	83 c4 10             	add    $0x10,%esp
f81018ae:	85 c0                	test   %eax,%eax
f81018b0:	74 19                	je     f81018cb <mem_init+0x822>
f81018b2:	68 8b 3e 10 f8       	push   $0xf8103e8b
f81018b7:	68 04 3d 10 f8       	push   $0xf8103d04
f81018bc:	68 02 03 00 00       	push   $0x302
f81018c1:	68 de 3c 10 f8       	push   $0xf8103cde
f81018c6:	e8 c0 e7 ff ff       	call   f810008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f81018cb:	6a 02                	push   $0x2
f81018cd:	68 00 10 00 00       	push   $0x1000
f81018d2:	56                   	push   %esi
f81018d3:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f81018d9:	e8 65 f7 ff ff       	call   f8101043 <page_insert>
f81018de:	83 c4 10             	add    $0x10,%esp
f81018e1:	85 c0                	test   %eax,%eax
f81018e3:	74 19                	je     f81018fe <mem_init+0x855>
f81018e5:	68 dc 42 10 f8       	push   $0xf81042dc
f81018ea:	68 04 3d 10 f8       	push   $0xf8103d04
f81018ef:	68 05 03 00 00       	push   $0x305
f81018f4:	68 de 3c 10 f8       	push   $0xf8103cde
f81018f9:	e8 8d e7 ff ff       	call   f810008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f81018fe:	ba 00 10 00 00       	mov    $0x1000,%edx
f8101903:	a1 6c 79 11 f8       	mov    0xf811796c,%eax
f8101908:	e8 d3 f0 ff ff       	call   f81009e0 <check_va2pa>
f810190d:	89 f2                	mov    %esi,%edx
f810190f:	2b 15 70 79 11 f8    	sub    0xf8117970,%edx
f8101915:	c1 fa 03             	sar    $0x3,%edx
f8101918:	c1 e2 0c             	shl    $0xc,%edx
f810191b:	39 d0                	cmp    %edx,%eax
f810191d:	74 19                	je     f8101938 <mem_init+0x88f>
f810191f:	68 18 43 10 f8       	push   $0xf8104318
f8101924:	68 04 3d 10 f8       	push   $0xf8103d04
f8101929:	68 06 03 00 00       	push   $0x306
f810192e:	68 de 3c 10 f8       	push   $0xf8103cde
f8101933:	e8 53 e7 ff ff       	call   f810008b <_panic>
	assert(pp2->pp_ref == 1);
f8101938:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f810193d:	74 19                	je     f8101958 <mem_init+0x8af>
f810193f:	68 ff 3e 10 f8       	push   $0xf8103eff
f8101944:	68 04 3d 10 f8       	push   $0xf8103d04
f8101949:	68 07 03 00 00       	push   $0x307
f810194e:	68 de 3c 10 f8       	push   $0xf8103cde
f8101953:	e8 33 e7 ff ff       	call   f810008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f8101958:	83 ec 0c             	sub    $0xc,%esp
f810195b:	6a 00                	push   $0x0
f810195d:	e8 67 f4 ff ff       	call   f8100dc9 <page_alloc>
f8101962:	83 c4 10             	add    $0x10,%esp
f8101965:	85 c0                	test   %eax,%eax
f8101967:	74 19                	je     f8101982 <mem_init+0x8d9>
f8101969:	68 8b 3e 10 f8       	push   $0xf8103e8b
f810196e:	68 04 3d 10 f8       	push   $0xf8103d04
f8101973:	68 0b 03 00 00       	push   $0x30b
f8101978:	68 de 3c 10 f8       	push   $0xf8103cde
f810197d:	e8 09 e7 ff ff       	call   f810008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f8101982:	8b 15 6c 79 11 f8    	mov    0xf811796c,%edx
f8101988:	8b 02                	mov    (%edx),%eax
f810198a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f810198f:	89 c1                	mov    %eax,%ecx
f8101991:	c1 e9 0c             	shr    $0xc,%ecx
f8101994:	3b 0d 68 79 11 f8    	cmp    0xf8117968,%ecx
f810199a:	72 15                	jb     f81019b1 <mem_init+0x908>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f810199c:	50                   	push   %eax
f810199d:	68 20 40 10 f8       	push   $0xf8104020
f81019a2:	68 0e 03 00 00       	push   $0x30e
f81019a7:	68 de 3c 10 f8       	push   $0xf8103cde
f81019ac:	e8 da e6 ff ff       	call   f810008b <_panic>
f81019b1:	2d 00 00 00 08       	sub    $0x8000000,%eax
f81019b6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f81019b9:	83 ec 04             	sub    $0x4,%esp
f81019bc:	6a 00                	push   $0x0
f81019be:	68 00 10 00 00       	push   $0x1000
f81019c3:	52                   	push   %edx
f81019c4:	e8 d2 f4 ff ff       	call   f8100e9b <pgdir_walk>
f81019c9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f81019cc:	8d 51 04             	lea    0x4(%ecx),%edx
f81019cf:	83 c4 10             	add    $0x10,%esp
f81019d2:	39 d0                	cmp    %edx,%eax
f81019d4:	74 19                	je     f81019ef <mem_init+0x946>
f81019d6:	68 48 43 10 f8       	push   $0xf8104348
f81019db:	68 04 3d 10 f8       	push   $0xf8103d04
f81019e0:	68 0f 03 00 00       	push   $0x30f
f81019e5:	68 de 3c 10 f8       	push   $0xf8103cde
f81019ea:	e8 9c e6 ff ff       	call   f810008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f81019ef:	6a 06                	push   $0x6
f81019f1:	68 00 10 00 00       	push   $0x1000
f81019f6:	56                   	push   %esi
f81019f7:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f81019fd:	e8 41 f6 ff ff       	call   f8101043 <page_insert>
f8101a02:	83 c4 10             	add    $0x10,%esp
f8101a05:	85 c0                	test   %eax,%eax
f8101a07:	74 19                	je     f8101a22 <mem_init+0x979>
f8101a09:	68 88 43 10 f8       	push   $0xf8104388
f8101a0e:	68 04 3d 10 f8       	push   $0xf8103d04
f8101a13:	68 12 03 00 00       	push   $0x312
f8101a18:	68 de 3c 10 f8       	push   $0xf8103cde
f8101a1d:	e8 69 e6 ff ff       	call   f810008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f8101a22:	8b 3d 6c 79 11 f8    	mov    0xf811796c,%edi
f8101a28:	ba 00 10 00 00       	mov    $0x1000,%edx
f8101a2d:	89 f8                	mov    %edi,%eax
f8101a2f:	e8 ac ef ff ff       	call   f81009e0 <check_va2pa>
f8101a34:	89 f2                	mov    %esi,%edx
f8101a36:	2b 15 70 79 11 f8    	sub    0xf8117970,%edx
f8101a3c:	c1 fa 03             	sar    $0x3,%edx
f8101a3f:	c1 e2 0c             	shl    $0xc,%edx
f8101a42:	39 d0                	cmp    %edx,%eax
f8101a44:	74 19                	je     f8101a5f <mem_init+0x9b6>
f8101a46:	68 18 43 10 f8       	push   $0xf8104318
f8101a4b:	68 04 3d 10 f8       	push   $0xf8103d04
f8101a50:	68 13 03 00 00       	push   $0x313
f8101a55:	68 de 3c 10 f8       	push   $0xf8103cde
f8101a5a:	e8 2c e6 ff ff       	call   f810008b <_panic>
	assert(pp2->pp_ref == 1);
f8101a5f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f8101a64:	74 19                	je     f8101a7f <mem_init+0x9d6>
f8101a66:	68 ff 3e 10 f8       	push   $0xf8103eff
f8101a6b:	68 04 3d 10 f8       	push   $0xf8103d04
f8101a70:	68 14 03 00 00       	push   $0x314
f8101a75:	68 de 3c 10 f8       	push   $0xf8103cde
f8101a7a:	e8 0c e6 ff ff       	call   f810008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f8101a7f:	83 ec 04             	sub    $0x4,%esp
f8101a82:	6a 00                	push   $0x0
f8101a84:	68 00 10 00 00       	push   $0x1000
f8101a89:	57                   	push   %edi
f8101a8a:	e8 0c f4 ff ff       	call   f8100e9b <pgdir_walk>
f8101a8f:	83 c4 10             	add    $0x10,%esp
f8101a92:	f6 00 04             	testb  $0x4,(%eax)
f8101a95:	75 19                	jne    f8101ab0 <mem_init+0xa07>
f8101a97:	68 c8 43 10 f8       	push   $0xf81043c8
f8101a9c:	68 04 3d 10 f8       	push   $0xf8103d04
f8101aa1:	68 15 03 00 00       	push   $0x315
f8101aa6:	68 de 3c 10 f8       	push   $0xf8103cde
f8101aab:	e8 db e5 ff ff       	call   f810008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f8101ab0:	a1 6c 79 11 f8       	mov    0xf811796c,%eax
f8101ab5:	f6 00 04             	testb  $0x4,(%eax)
f8101ab8:	75 19                	jne    f8101ad3 <mem_init+0xa2a>
f8101aba:	68 10 3f 10 f8       	push   $0xf8103f10
f8101abf:	68 04 3d 10 f8       	push   $0xf8103d04
f8101ac4:	68 16 03 00 00       	push   $0x316
f8101ac9:	68 de 3c 10 f8       	push   $0xf8103cde
f8101ace:	e8 b8 e5 ff ff       	call   f810008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f8101ad3:	6a 02                	push   $0x2
f8101ad5:	68 00 10 00 00       	push   $0x1000
f8101ada:	56                   	push   %esi
f8101adb:	50                   	push   %eax
f8101adc:	e8 62 f5 ff ff       	call   f8101043 <page_insert>
f8101ae1:	83 c4 10             	add    $0x10,%esp
f8101ae4:	85 c0                	test   %eax,%eax
f8101ae6:	74 19                	je     f8101b01 <mem_init+0xa58>
f8101ae8:	68 dc 42 10 f8       	push   $0xf81042dc
f8101aed:	68 04 3d 10 f8       	push   $0xf8103d04
f8101af2:	68 19 03 00 00       	push   $0x319
f8101af7:	68 de 3c 10 f8       	push   $0xf8103cde
f8101afc:	e8 8a e5 ff ff       	call   f810008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f8101b01:	83 ec 04             	sub    $0x4,%esp
f8101b04:	6a 00                	push   $0x0
f8101b06:	68 00 10 00 00       	push   $0x1000
f8101b0b:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f8101b11:	e8 85 f3 ff ff       	call   f8100e9b <pgdir_walk>
f8101b16:	83 c4 10             	add    $0x10,%esp
f8101b19:	f6 00 02             	testb  $0x2,(%eax)
f8101b1c:	75 19                	jne    f8101b37 <mem_init+0xa8e>
f8101b1e:	68 fc 43 10 f8       	push   $0xf81043fc
f8101b23:	68 04 3d 10 f8       	push   $0xf8103d04
f8101b28:	68 1a 03 00 00       	push   $0x31a
f8101b2d:	68 de 3c 10 f8       	push   $0xf8103cde
f8101b32:	e8 54 e5 ff ff       	call   f810008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f8101b37:	83 ec 04             	sub    $0x4,%esp
f8101b3a:	6a 00                	push   $0x0
f8101b3c:	68 00 10 00 00       	push   $0x1000
f8101b41:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f8101b47:	e8 4f f3 ff ff       	call   f8100e9b <pgdir_walk>
f8101b4c:	83 c4 10             	add    $0x10,%esp
f8101b4f:	f6 00 04             	testb  $0x4,(%eax)
f8101b52:	74 19                	je     f8101b6d <mem_init+0xac4>
f8101b54:	68 30 44 10 f8       	push   $0xf8104430
f8101b59:	68 04 3d 10 f8       	push   $0xf8103d04
f8101b5e:	68 1b 03 00 00       	push   $0x31b
f8101b63:	68 de 3c 10 f8       	push   $0xf8103cde
f8101b68:	e8 1e e5 ff ff       	call   f810008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f8101b6d:	6a 02                	push   $0x2
f8101b6f:	68 00 00 40 00       	push   $0x400000
f8101b74:	ff 75 d4             	pushl  -0x2c(%ebp)
f8101b77:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f8101b7d:	e8 c1 f4 ff ff       	call   f8101043 <page_insert>
f8101b82:	83 c4 10             	add    $0x10,%esp
f8101b85:	85 c0                	test   %eax,%eax
f8101b87:	78 19                	js     f8101ba2 <mem_init+0xaf9>
f8101b89:	68 68 44 10 f8       	push   $0xf8104468
f8101b8e:	68 04 3d 10 f8       	push   $0xf8103d04
f8101b93:	68 1e 03 00 00       	push   $0x31e
f8101b98:	68 de 3c 10 f8       	push   $0xf8103cde
f8101b9d:	e8 e9 e4 ff ff       	call   f810008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f8101ba2:	6a 02                	push   $0x2
f8101ba4:	68 00 10 00 00       	push   $0x1000
f8101ba9:	53                   	push   %ebx
f8101baa:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f8101bb0:	e8 8e f4 ff ff       	call   f8101043 <page_insert>
f8101bb5:	83 c4 10             	add    $0x10,%esp
f8101bb8:	85 c0                	test   %eax,%eax
f8101bba:	74 19                	je     f8101bd5 <mem_init+0xb2c>
f8101bbc:	68 a0 44 10 f8       	push   $0xf81044a0
f8101bc1:	68 04 3d 10 f8       	push   $0xf8103d04
f8101bc6:	68 21 03 00 00       	push   $0x321
f8101bcb:	68 de 3c 10 f8       	push   $0xf8103cde
f8101bd0:	e8 b6 e4 ff ff       	call   f810008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f8101bd5:	83 ec 04             	sub    $0x4,%esp
f8101bd8:	6a 00                	push   $0x0
f8101bda:	68 00 10 00 00       	push   $0x1000
f8101bdf:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f8101be5:	e8 b1 f2 ff ff       	call   f8100e9b <pgdir_walk>
f8101bea:	83 c4 10             	add    $0x10,%esp
f8101bed:	f6 00 04             	testb  $0x4,(%eax)
f8101bf0:	74 19                	je     f8101c0b <mem_init+0xb62>
f8101bf2:	68 30 44 10 f8       	push   $0xf8104430
f8101bf7:	68 04 3d 10 f8       	push   $0xf8103d04
f8101bfc:	68 22 03 00 00       	push   $0x322
f8101c01:	68 de 3c 10 f8       	push   $0xf8103cde
f8101c06:	e8 80 e4 ff ff       	call   f810008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f8101c0b:	8b 3d 6c 79 11 f8    	mov    0xf811796c,%edi
f8101c11:	ba 00 00 00 00       	mov    $0x0,%edx
f8101c16:	89 f8                	mov    %edi,%eax
f8101c18:	e8 c3 ed ff ff       	call   f81009e0 <check_va2pa>
f8101c1d:	89 c1                	mov    %eax,%ecx
f8101c1f:	89 45 c8             	mov    %eax,-0x38(%ebp)
f8101c22:	89 d8                	mov    %ebx,%eax
f8101c24:	2b 05 70 79 11 f8    	sub    0xf8117970,%eax
f8101c2a:	c1 f8 03             	sar    $0x3,%eax
f8101c2d:	c1 e0 0c             	shl    $0xc,%eax
f8101c30:	39 c1                	cmp    %eax,%ecx
f8101c32:	74 19                	je     f8101c4d <mem_init+0xba4>
f8101c34:	68 dc 44 10 f8       	push   $0xf81044dc
f8101c39:	68 04 3d 10 f8       	push   $0xf8103d04
f8101c3e:	68 25 03 00 00       	push   $0x325
f8101c43:	68 de 3c 10 f8       	push   $0xf8103cde
f8101c48:	e8 3e e4 ff ff       	call   f810008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f8101c4d:	ba 00 10 00 00       	mov    $0x1000,%edx
f8101c52:	89 f8                	mov    %edi,%eax
f8101c54:	e8 87 ed ff ff       	call   f81009e0 <check_va2pa>
f8101c59:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f8101c5c:	74 19                	je     f8101c77 <mem_init+0xbce>
f8101c5e:	68 08 45 10 f8       	push   $0xf8104508
f8101c63:	68 04 3d 10 f8       	push   $0xf8103d04
f8101c68:	68 26 03 00 00       	push   $0x326
f8101c6d:	68 de 3c 10 f8       	push   $0xf8103cde
f8101c72:	e8 14 e4 ff ff       	call   f810008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f8101c77:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f8101c7c:	74 19                	je     f8101c97 <mem_init+0xbee>
f8101c7e:	68 26 3f 10 f8       	push   $0xf8103f26
f8101c83:	68 04 3d 10 f8       	push   $0xf8103d04
f8101c88:	68 28 03 00 00       	push   $0x328
f8101c8d:	68 de 3c 10 f8       	push   $0xf8103cde
f8101c92:	e8 f4 e3 ff ff       	call   f810008b <_panic>
	assert(pp2->pp_ref == 0);
f8101c97:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f8101c9c:	74 19                	je     f8101cb7 <mem_init+0xc0e>
f8101c9e:	68 37 3f 10 f8       	push   $0xf8103f37
f8101ca3:	68 04 3d 10 f8       	push   $0xf8103d04
f8101ca8:	68 29 03 00 00       	push   $0x329
f8101cad:	68 de 3c 10 f8       	push   $0xf8103cde
f8101cb2:	e8 d4 e3 ff ff       	call   f810008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f8101cb7:	83 ec 0c             	sub    $0xc,%esp
f8101cba:	6a 00                	push   $0x0
f8101cbc:	e8 08 f1 ff ff       	call   f8100dc9 <page_alloc>
f8101cc1:	83 c4 10             	add    $0x10,%esp
f8101cc4:	85 c0                	test   %eax,%eax
f8101cc6:	74 04                	je     f8101ccc <mem_init+0xc23>
f8101cc8:	39 c6                	cmp    %eax,%esi
f8101cca:	74 19                	je     f8101ce5 <mem_init+0xc3c>
f8101ccc:	68 38 45 10 f8       	push   $0xf8104538
f8101cd1:	68 04 3d 10 f8       	push   $0xf8103d04
f8101cd6:	68 2c 03 00 00       	push   $0x32c
f8101cdb:	68 de 3c 10 f8       	push   $0xf8103cde
f8101ce0:	e8 a6 e3 ff ff       	call   f810008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f8101ce5:	83 ec 08             	sub    $0x8,%esp
f8101ce8:	6a 00                	push   $0x0
f8101cea:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f8101cf0:	e8 0a f3 ff ff       	call   f8100fff <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f8101cf5:	8b 3d 6c 79 11 f8    	mov    0xf811796c,%edi
f8101cfb:	ba 00 00 00 00       	mov    $0x0,%edx
f8101d00:	89 f8                	mov    %edi,%eax
f8101d02:	e8 d9 ec ff ff       	call   f81009e0 <check_va2pa>
f8101d07:	83 c4 10             	add    $0x10,%esp
f8101d0a:	83 f8 ff             	cmp    $0xffffffff,%eax
f8101d0d:	74 19                	je     f8101d28 <mem_init+0xc7f>
f8101d0f:	68 5c 45 10 f8       	push   $0xf810455c
f8101d14:	68 04 3d 10 f8       	push   $0xf8103d04
f8101d19:	68 30 03 00 00       	push   $0x330
f8101d1e:	68 de 3c 10 f8       	push   $0xf8103cde
f8101d23:	e8 63 e3 ff ff       	call   f810008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f8101d28:	ba 00 10 00 00       	mov    $0x1000,%edx
f8101d2d:	89 f8                	mov    %edi,%eax
f8101d2f:	e8 ac ec ff ff       	call   f81009e0 <check_va2pa>
f8101d34:	89 da                	mov    %ebx,%edx
f8101d36:	2b 15 70 79 11 f8    	sub    0xf8117970,%edx
f8101d3c:	c1 fa 03             	sar    $0x3,%edx
f8101d3f:	c1 e2 0c             	shl    $0xc,%edx
f8101d42:	39 d0                	cmp    %edx,%eax
f8101d44:	74 19                	je     f8101d5f <mem_init+0xcb6>
f8101d46:	68 08 45 10 f8       	push   $0xf8104508
f8101d4b:	68 04 3d 10 f8       	push   $0xf8103d04
f8101d50:	68 31 03 00 00       	push   $0x331
f8101d55:	68 de 3c 10 f8       	push   $0xf8103cde
f8101d5a:	e8 2c e3 ff ff       	call   f810008b <_panic>
	assert(pp1->pp_ref == 1);
f8101d5f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f8101d64:	74 19                	je     f8101d7f <mem_init+0xcd6>
f8101d66:	68 dd 3e 10 f8       	push   $0xf8103edd
f8101d6b:	68 04 3d 10 f8       	push   $0xf8103d04
f8101d70:	68 32 03 00 00       	push   $0x332
f8101d75:	68 de 3c 10 f8       	push   $0xf8103cde
f8101d7a:	e8 0c e3 ff ff       	call   f810008b <_panic>
	assert(pp2->pp_ref == 0);
f8101d7f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f8101d84:	74 19                	je     f8101d9f <mem_init+0xcf6>
f8101d86:	68 37 3f 10 f8       	push   $0xf8103f37
f8101d8b:	68 04 3d 10 f8       	push   $0xf8103d04
f8101d90:	68 33 03 00 00       	push   $0x333
f8101d95:	68 de 3c 10 f8       	push   $0xf8103cde
f8101d9a:	e8 ec e2 ff ff       	call   f810008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f8101d9f:	6a 00                	push   $0x0
f8101da1:	68 00 10 00 00       	push   $0x1000
f8101da6:	53                   	push   %ebx
f8101da7:	57                   	push   %edi
f8101da8:	e8 96 f2 ff ff       	call   f8101043 <page_insert>
f8101dad:	83 c4 10             	add    $0x10,%esp
f8101db0:	85 c0                	test   %eax,%eax
f8101db2:	74 19                	je     f8101dcd <mem_init+0xd24>
f8101db4:	68 80 45 10 f8       	push   $0xf8104580
f8101db9:	68 04 3d 10 f8       	push   $0xf8103d04
f8101dbe:	68 36 03 00 00       	push   $0x336
f8101dc3:	68 de 3c 10 f8       	push   $0xf8103cde
f8101dc8:	e8 be e2 ff ff       	call   f810008b <_panic>
	assert(pp1->pp_ref);
f8101dcd:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f8101dd2:	75 19                	jne    f8101ded <mem_init+0xd44>
f8101dd4:	68 48 3f 10 f8       	push   $0xf8103f48
f8101dd9:	68 04 3d 10 f8       	push   $0xf8103d04
f8101dde:	68 37 03 00 00       	push   $0x337
f8101de3:	68 de 3c 10 f8       	push   $0xf8103cde
f8101de8:	e8 9e e2 ff ff       	call   f810008b <_panic>
	assert(pp1->pp_link == NULL);
f8101ded:	83 3b 00             	cmpl   $0x0,(%ebx)
f8101df0:	74 19                	je     f8101e0b <mem_init+0xd62>
f8101df2:	68 54 3f 10 f8       	push   $0xf8103f54
f8101df7:	68 04 3d 10 f8       	push   $0xf8103d04
f8101dfc:	68 38 03 00 00       	push   $0x338
f8101e01:	68 de 3c 10 f8       	push   $0xf8103cde
f8101e06:	e8 80 e2 ff ff       	call   f810008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f8101e0b:	83 ec 08             	sub    $0x8,%esp
f8101e0e:	68 00 10 00 00       	push   $0x1000
f8101e13:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f8101e19:	e8 e1 f1 ff ff       	call   f8100fff <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f8101e1e:	8b 3d 6c 79 11 f8    	mov    0xf811796c,%edi
f8101e24:	ba 00 00 00 00       	mov    $0x0,%edx
f8101e29:	89 f8                	mov    %edi,%eax
f8101e2b:	e8 b0 eb ff ff       	call   f81009e0 <check_va2pa>
f8101e30:	83 c4 10             	add    $0x10,%esp
f8101e33:	83 f8 ff             	cmp    $0xffffffff,%eax
f8101e36:	74 19                	je     f8101e51 <mem_init+0xda8>
f8101e38:	68 5c 45 10 f8       	push   $0xf810455c
f8101e3d:	68 04 3d 10 f8       	push   $0xf8103d04
f8101e42:	68 3c 03 00 00       	push   $0x33c
f8101e47:	68 de 3c 10 f8       	push   $0xf8103cde
f8101e4c:	e8 3a e2 ff ff       	call   f810008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f8101e51:	ba 00 10 00 00       	mov    $0x1000,%edx
f8101e56:	89 f8                	mov    %edi,%eax
f8101e58:	e8 83 eb ff ff       	call   f81009e0 <check_va2pa>
f8101e5d:	83 f8 ff             	cmp    $0xffffffff,%eax
f8101e60:	74 19                	je     f8101e7b <mem_init+0xdd2>
f8101e62:	68 b8 45 10 f8       	push   $0xf81045b8
f8101e67:	68 04 3d 10 f8       	push   $0xf8103d04
f8101e6c:	68 3d 03 00 00       	push   $0x33d
f8101e71:	68 de 3c 10 f8       	push   $0xf8103cde
f8101e76:	e8 10 e2 ff ff       	call   f810008b <_panic>
	assert(pp1->pp_ref == 0);
f8101e7b:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f8101e80:	74 19                	je     f8101e9b <mem_init+0xdf2>
f8101e82:	68 69 3f 10 f8       	push   $0xf8103f69
f8101e87:	68 04 3d 10 f8       	push   $0xf8103d04
f8101e8c:	68 3e 03 00 00       	push   $0x33e
f8101e91:	68 de 3c 10 f8       	push   $0xf8103cde
f8101e96:	e8 f0 e1 ff ff       	call   f810008b <_panic>
	assert(pp2->pp_ref == 0);
f8101e9b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f8101ea0:	74 19                	je     f8101ebb <mem_init+0xe12>
f8101ea2:	68 37 3f 10 f8       	push   $0xf8103f37
f8101ea7:	68 04 3d 10 f8       	push   $0xf8103d04
f8101eac:	68 3f 03 00 00       	push   $0x33f
f8101eb1:	68 de 3c 10 f8       	push   $0xf8103cde
f8101eb6:	e8 d0 e1 ff ff       	call   f810008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f8101ebb:	83 ec 0c             	sub    $0xc,%esp
f8101ebe:	6a 00                	push   $0x0
f8101ec0:	e8 04 ef ff ff       	call   f8100dc9 <page_alloc>
f8101ec5:	83 c4 10             	add    $0x10,%esp
f8101ec8:	39 c3                	cmp    %eax,%ebx
f8101eca:	75 04                	jne    f8101ed0 <mem_init+0xe27>
f8101ecc:	85 c0                	test   %eax,%eax
f8101ece:	75 19                	jne    f8101ee9 <mem_init+0xe40>
f8101ed0:	68 e0 45 10 f8       	push   $0xf81045e0
f8101ed5:	68 04 3d 10 f8       	push   $0xf8103d04
f8101eda:	68 42 03 00 00       	push   $0x342
f8101edf:	68 de 3c 10 f8       	push   $0xf8103cde
f8101ee4:	e8 a2 e1 ff ff       	call   f810008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f8101ee9:	83 ec 0c             	sub    $0xc,%esp
f8101eec:	6a 00                	push   $0x0
f8101eee:	e8 d6 ee ff ff       	call   f8100dc9 <page_alloc>
f8101ef3:	83 c4 10             	add    $0x10,%esp
f8101ef6:	85 c0                	test   %eax,%eax
f8101ef8:	74 19                	je     f8101f13 <mem_init+0xe6a>
f8101efa:	68 8b 3e 10 f8       	push   $0xf8103e8b
f8101eff:	68 04 3d 10 f8       	push   $0xf8103d04
f8101f04:	68 45 03 00 00       	push   $0x345
f8101f09:	68 de 3c 10 f8       	push   $0xf8103cde
f8101f0e:	e8 78 e1 ff ff       	call   f810008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f8101f13:	8b 0d 6c 79 11 f8    	mov    0xf811796c,%ecx
f8101f19:	8b 11                	mov    (%ecx),%edx
f8101f1b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f8101f21:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f8101f24:	2b 05 70 79 11 f8    	sub    0xf8117970,%eax
f8101f2a:	c1 f8 03             	sar    $0x3,%eax
f8101f2d:	c1 e0 0c             	shl    $0xc,%eax
f8101f30:	39 c2                	cmp    %eax,%edx
f8101f32:	74 19                	je     f8101f4d <mem_init+0xea4>
f8101f34:	68 84 42 10 f8       	push   $0xf8104284
f8101f39:	68 04 3d 10 f8       	push   $0xf8103d04
f8101f3e:	68 48 03 00 00       	push   $0x348
f8101f43:	68 de 3c 10 f8       	push   $0xf8103cde
f8101f48:	e8 3e e1 ff ff       	call   f810008b <_panic>
	kern_pgdir[0] = 0;
f8101f4d:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f8101f53:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f8101f56:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f8101f5b:	74 19                	je     f8101f76 <mem_init+0xecd>
f8101f5d:	68 ee 3e 10 f8       	push   $0xf8103eee
f8101f62:	68 04 3d 10 f8       	push   $0xf8103d04
f8101f67:	68 4a 03 00 00       	push   $0x34a
f8101f6c:	68 de 3c 10 f8       	push   $0xf8103cde
f8101f71:	e8 15 e1 ff ff       	call   f810008b <_panic>
	pp0->pp_ref = 0;
f8101f76:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f8101f79:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f8101f7f:	83 ec 0c             	sub    $0xc,%esp
f8101f82:	50                   	push   %eax
f8101f83:	e8 b1 ee ff ff       	call   f8100e39 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f8101f88:	83 c4 0c             	add    $0xc,%esp
f8101f8b:	6a 01                	push   $0x1
f8101f8d:	68 00 10 40 00       	push   $0x401000
f8101f92:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f8101f98:	e8 fe ee ff ff       	call   f8100e9b <pgdir_walk>
f8101f9d:	89 45 c8             	mov    %eax,-0x38(%ebp)
f8101fa0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f8101fa3:	8b 0d 6c 79 11 f8    	mov    0xf811796c,%ecx
f8101fa9:	8b 51 04             	mov    0x4(%ecx),%edx
f8101fac:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f8101fb2:	8b 3d 68 79 11 f8    	mov    0xf8117968,%edi
f8101fb8:	89 d0                	mov    %edx,%eax
f8101fba:	c1 e8 0c             	shr    $0xc,%eax
f8101fbd:	83 c4 10             	add    $0x10,%esp
f8101fc0:	39 f8                	cmp    %edi,%eax
f8101fc2:	72 15                	jb     f8101fd9 <mem_init+0xf30>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f8101fc4:	52                   	push   %edx
f8101fc5:	68 20 40 10 f8       	push   $0xf8104020
f8101fca:	68 51 03 00 00       	push   $0x351
f8101fcf:	68 de 3c 10 f8       	push   $0xf8103cde
f8101fd4:	e8 b2 e0 ff ff       	call   f810008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f8101fd9:	81 ea fc ff ff 07    	sub    $0x7fffffc,%edx
f8101fdf:	39 55 c8             	cmp    %edx,-0x38(%ebp)
f8101fe2:	74 19                	je     f8101ffd <mem_init+0xf54>
f8101fe4:	68 7a 3f 10 f8       	push   $0xf8103f7a
f8101fe9:	68 04 3d 10 f8       	push   $0xf8103d04
f8101fee:	68 52 03 00 00       	push   $0x352
f8101ff3:	68 de 3c 10 f8       	push   $0xf8103cde
f8101ff8:	e8 8e e0 ff ff       	call   f810008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f8101ffd:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f8102004:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f8102007:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f810200d:	2b 05 70 79 11 f8    	sub    0xf8117970,%eax
f8102013:	c1 f8 03             	sar    $0x3,%eax
f8102016:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f8102019:	89 c2                	mov    %eax,%edx
f810201b:	c1 ea 0c             	shr    $0xc,%edx
f810201e:	39 d7                	cmp    %edx,%edi
f8102020:	77 12                	ja     f8102034 <mem_init+0xf8b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f8102022:	50                   	push   %eax
f8102023:	68 20 40 10 f8       	push   $0xf8104020
f8102028:	6a 52                	push   $0x52
f810202a:	68 ea 3c 10 f8       	push   $0xf8103cea
f810202f:	e8 57 e0 ff ff       	call   f810008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f8102034:	83 ec 04             	sub    $0x4,%esp
f8102037:	68 00 10 00 00       	push   $0x1000
f810203c:	68 ff 00 00 00       	push   $0xff
f8102041:	2d 00 00 00 08       	sub    $0x8000000,%eax
f8102046:	50                   	push   %eax
f8102047:	e8 6c 12 00 00       	call   f81032b8 <memset>
	page_free(pp0);
f810204c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f810204f:	89 3c 24             	mov    %edi,(%esp)
f8102052:	e8 e2 ed ff ff       	call   f8100e39 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f8102057:	83 c4 0c             	add    $0xc,%esp
f810205a:	6a 01                	push   $0x1
f810205c:	6a 00                	push   $0x0
f810205e:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f8102064:	e8 32 ee ff ff       	call   f8100e9b <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f8102069:	89 fa                	mov    %edi,%edx
f810206b:	2b 15 70 79 11 f8    	sub    0xf8117970,%edx
f8102071:	c1 fa 03             	sar    $0x3,%edx
f8102074:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f8102077:	89 d0                	mov    %edx,%eax
f8102079:	c1 e8 0c             	shr    $0xc,%eax
f810207c:	83 c4 10             	add    $0x10,%esp
f810207f:	3b 05 68 79 11 f8    	cmp    0xf8117968,%eax
f8102085:	72 12                	jb     f8102099 <mem_init+0xff0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f8102087:	52                   	push   %edx
f8102088:	68 20 40 10 f8       	push   $0xf8104020
f810208d:	6a 52                	push   $0x52
f810208f:	68 ea 3c 10 f8       	push   $0xf8103cea
f8102094:	e8 f2 df ff ff       	call   f810008b <_panic>
	return (void *)(pa + KERNBASE);
f8102099:	8d 82 00 00 00 f8    	lea    -0x8000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f810209f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f81020a2:	81 ea 00 f0 ff 07    	sub    $0x7fff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f81020a8:	f6 00 01             	testb  $0x1,(%eax)
f81020ab:	74 19                	je     f81020c6 <mem_init+0x101d>
f81020ad:	68 92 3f 10 f8       	push   $0xf8103f92
f81020b2:	68 04 3d 10 f8       	push   $0xf8103d04
f81020b7:	68 5c 03 00 00       	push   $0x35c
f81020bc:	68 de 3c 10 f8       	push   $0xf8103cde
f81020c1:	e8 c5 df ff ff       	call   f810008b <_panic>
f81020c6:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f81020c9:	39 d0                	cmp    %edx,%eax
f81020cb:	75 db                	jne    f81020a8 <mem_init+0xfff>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f81020cd:	a1 6c 79 11 f8       	mov    0xf811796c,%eax
f81020d2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f81020d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f81020db:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f81020e1:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f81020e4:	89 0d 3c 75 11 f8    	mov    %ecx,0xf811753c

	// free the pages we took
	page_free(pp0);
f81020ea:	83 ec 0c             	sub    $0xc,%esp
f81020ed:	50                   	push   %eax
f81020ee:	e8 46 ed ff ff       	call   f8100e39 <page_free>
	page_free(pp1);
f81020f3:	89 1c 24             	mov    %ebx,(%esp)
f81020f6:	e8 3e ed ff ff       	call   f8100e39 <page_free>
	page_free(pp2);
f81020fb:	89 34 24             	mov    %esi,(%esp)
f81020fe:	e8 36 ed ff ff       	call   f8100e39 <page_free>

	cprintf("check_page() succeeded!\n");
f8102103:	c7 04 24 a9 3f 10 f8 	movl   $0xf8103fa9,(%esp)
f810210a:	e8 50 06 00 00       	call   f810275f <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, page_size, PADDR(pages), PTE_U);
f810210f:	a1 70 79 11 f8       	mov    0xf8117970,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f8102114:	83 c4 10             	add    $0x10,%esp
f8102117:	3d ff ff ff f7       	cmp    $0xf7ffffff,%eax
f810211c:	77 15                	ja     f8102133 <mem_init+0x108a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f810211e:	50                   	push   %eax
f810211f:	68 88 41 10 f8       	push   $0xf8104188
f8102124:	68 b7 00 00 00       	push   $0xb7
f8102129:	68 de 3c 10 f8       	push   $0xf8103cde
f810212e:	e8 58 df ff ff       	call   f810008b <_panic>
f8102133:	83 ec 08             	sub    $0x8,%esp
f8102136:	6a 04                	push   $0x4
f8102138:	05 00 00 00 08       	add    $0x8000000,%eax
f810213d:	50                   	push   %eax
f810213e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f8102141:	ba 00 00 00 f7       	mov    $0xf7000000,%edx
f8102146:	a1 6c 79 11 f8       	mov    0xf811796c,%eax
f810214b:	e8 de ed ff ff       	call   f8100f2e <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f8102150:	83 c4 10             	add    $0x10,%esp
f8102153:	b8 00 d0 10 f8       	mov    $0xf810d000,%eax
f8102158:	3d ff ff ff f7       	cmp    $0xf7ffffff,%eax
f810215d:	77 15                	ja     f8102174 <mem_init+0x10cb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f810215f:	50                   	push   %eax
f8102160:	68 88 41 10 f8       	push   $0xf8104188
f8102165:	68 c5 00 00 00       	push   $0xc5
f810216a:	68 de 3c 10 f8       	push   $0xf8103cde
f810216f:	e8 17 df ff ff       	call   f810008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE,
f8102174:	83 ec 08             	sub    $0x8,%esp
f8102177:	6a 02                	push   $0x2
f8102179:	68 00 d0 10 00       	push   $0x10d000
f810217e:	b9 00 80 00 00       	mov    $0x8000,%ecx
f8102183:	ba 00 80 ff f7       	mov    $0xf7ff8000,%edx
f8102188:	a1 6c 79 11 f8       	mov    0xf811796c,%eax
f810218d:	e8 9c ed ff ff       	call   f8100f2e <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f8102192:	83 c4 08             	add    $0x8,%esp
f8102195:	6a 02                	push   $0x2
f8102197:	6a 00                	push   $0x0
f8102199:	b9 00 00 00 08       	mov    $0x8000000,%ecx
f810219e:	ba 00 00 00 f8       	mov    $0xf8000000,%edx
f81021a3:	a1 6c 79 11 f8       	mov    0xf811796c,%eax
f81021a8:	e8 81 ed ff ff       	call   f8100f2e <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f81021ad:	8b 35 6c 79 11 f8    	mov    0xf811796c,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f81021b3:	a1 68 79 11 f8       	mov    0xf8117968,%eax
f81021b8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f81021bb:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f81021c2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f81021c7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f81021ca:	8b 3d 70 79 11 f8    	mov    0xf8117970,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f81021d0:	89 7d d0             	mov    %edi,-0x30(%ebp)
f81021d3:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f81021d6:	bb 00 00 00 00       	mov    $0x0,%ebx
f81021db:	eb 55                	jmp    f8102232 <mem_init+0x1189>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f81021dd:	8d 93 00 00 00 f7    	lea    -0x9000000(%ebx),%edx
f81021e3:	89 f0                	mov    %esi,%eax
f81021e5:	e8 f6 e7 ff ff       	call   f81009e0 <check_va2pa>
f81021ea:	81 7d d0 ff ff ff f7 	cmpl   $0xf7ffffff,-0x30(%ebp)
f81021f1:	77 15                	ja     f8102208 <mem_init+0x115f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f81021f3:	57                   	push   %edi
f81021f4:	68 88 41 10 f8       	push   $0xf8104188
f81021f9:	68 9e 02 00 00       	push   $0x29e
f81021fe:	68 de 3c 10 f8       	push   $0xf8103cde
f8102203:	e8 83 de ff ff       	call   f810008b <_panic>
f8102208:	8d 94 1f 00 00 00 08 	lea    0x8000000(%edi,%ebx,1),%edx
f810220f:	39 c2                	cmp    %eax,%edx
f8102211:	74 19                	je     f810222c <mem_init+0x1183>
f8102213:	68 04 46 10 f8       	push   $0xf8104604
f8102218:	68 04 3d 10 f8       	push   $0xf8103d04
f810221d:	68 9e 02 00 00       	push   $0x29e
f8102222:	68 de 3c 10 f8       	push   $0xf8103cde
f8102227:	e8 5f de ff ff       	call   f810008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f810222c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f8102232:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f8102235:	77 a6                	ja     f81021dd <mem_init+0x1134>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f8102237:	8b 7d cc             	mov    -0x34(%ebp),%edi
f810223a:	c1 e7 0c             	shl    $0xc,%edi
f810223d:	bb 00 00 00 00       	mov    $0x0,%ebx
f8102242:	eb 30                	jmp    f8102274 <mem_init+0x11cb>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f8102244:	8d 93 00 00 00 f8    	lea    -0x8000000(%ebx),%edx
f810224a:	89 f0                	mov    %esi,%eax
f810224c:	e8 8f e7 ff ff       	call   f81009e0 <check_va2pa>
f8102251:	39 c3                	cmp    %eax,%ebx
f8102253:	74 19                	je     f810226e <mem_init+0x11c5>
f8102255:	68 38 46 10 f8       	push   $0xf8104638
f810225a:	68 04 3d 10 f8       	push   $0xf8103d04
f810225f:	68 a3 02 00 00       	push   $0x2a3
f8102264:	68 de 3c 10 f8       	push   $0xf8103cde
f8102269:	e8 1d de ff ff       	call   f810008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f810226e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f8102274:	39 fb                	cmp    %edi,%ebx
f8102276:	72 cc                	jb     f8102244 <mem_init+0x119b>
f8102278:	bb 00 80 ff f7       	mov    $0xf7ff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f810227d:	89 da                	mov    %ebx,%edx
f810227f:	89 f0                	mov    %esi,%eax
f8102281:	e8 5a e7 ff ff       	call   f81009e0 <check_va2pa>
f8102286:	8d 93 00 50 11 08    	lea    0x8115000(%ebx),%edx
f810228c:	39 c2                	cmp    %eax,%edx
f810228e:	74 19                	je     f81022a9 <mem_init+0x1200>
f8102290:	68 60 46 10 f8       	push   $0xf8104660
f8102295:	68 04 3d 10 f8       	push   $0xf8103d04
f810229a:	68 a7 02 00 00       	push   $0x2a7
f810229f:	68 de 3c 10 f8       	push   $0xf8103cde
f81022a4:	e8 e2 dd ff ff       	call   f810008b <_panic>
f81022a9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f81022af:	81 fb 00 00 00 f8    	cmp    $0xf8000000,%ebx
f81022b5:	75 c6                	jne    f810227d <mem_init+0x11d4>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f81022b7:	ba 00 00 c0 f7       	mov    $0xf7c00000,%edx
f81022bc:	89 f0                	mov    %esi,%eax
f81022be:	e8 1d e7 ff ff       	call   f81009e0 <check_va2pa>
f81022c3:	83 f8 ff             	cmp    $0xffffffff,%eax
f81022c6:	74 51                	je     f8102319 <mem_init+0x1270>
f81022c8:	68 a8 46 10 f8       	push   $0xf81046a8
f81022cd:	68 04 3d 10 f8       	push   $0xf8103d04
f81022d2:	68 a8 02 00 00       	push   $0x2a8
f81022d7:	68 de 3c 10 f8       	push   $0xf8103cde
f81022dc:	e8 aa dd ff ff       	call   f810008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f81022e1:	3d dc 03 00 00       	cmp    $0x3dc,%eax
f81022e6:	72 36                	jb     f810231e <mem_init+0x1275>
f81022e8:	3d dd 03 00 00       	cmp    $0x3dd,%eax
f81022ed:	76 07                	jbe    f81022f6 <mem_init+0x124d>
f81022ef:	3d df 03 00 00       	cmp    $0x3df,%eax
f81022f4:	75 28                	jne    f810231e <mem_init+0x1275>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f81022f6:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f81022fa:	0f 85 83 00 00 00    	jne    f8102383 <mem_init+0x12da>
f8102300:	68 c2 3f 10 f8       	push   $0xf8103fc2
f8102305:	68 04 3d 10 f8       	push   $0xf8103d04
f810230a:	68 b0 02 00 00       	push   $0x2b0
f810230f:	68 de 3c 10 f8       	push   $0xf8103cde
f8102314:	e8 72 dd ff ff       	call   f810008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f8102319:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f810231e:	3d df 03 00 00       	cmp    $0x3df,%eax
f8102323:	76 3f                	jbe    f8102364 <mem_init+0x12bb>
				assert(pgdir[i] & PTE_P);
f8102325:	8b 14 86             	mov    (%esi,%eax,4),%edx
f8102328:	f6 c2 01             	test   $0x1,%dl
f810232b:	75 19                	jne    f8102346 <mem_init+0x129d>
f810232d:	68 c2 3f 10 f8       	push   $0xf8103fc2
f8102332:	68 04 3d 10 f8       	push   $0xf8103d04
f8102337:	68 b4 02 00 00       	push   $0x2b4
f810233c:	68 de 3c 10 f8       	push   $0xf8103cde
f8102341:	e8 45 dd ff ff       	call   f810008b <_panic>
				assert(pgdir[i] & PTE_W);
f8102346:	f6 c2 02             	test   $0x2,%dl
f8102349:	75 38                	jne    f8102383 <mem_init+0x12da>
f810234b:	68 d3 3f 10 f8       	push   $0xf8103fd3
f8102350:	68 04 3d 10 f8       	push   $0xf8103d04
f8102355:	68 b5 02 00 00       	push   $0x2b5
f810235a:	68 de 3c 10 f8       	push   $0xf8103cde
f810235f:	e8 27 dd ff ff       	call   f810008b <_panic>
			} else
				assert(pgdir[i] == 0);
f8102364:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f8102368:	74 19                	je     f8102383 <mem_init+0x12da>
f810236a:	68 e4 3f 10 f8       	push   $0xf8103fe4
f810236f:	68 04 3d 10 f8       	push   $0xf8103d04
f8102374:	68 b7 02 00 00       	push   $0x2b7
f8102379:	68 de 3c 10 f8       	push   $0xf8103cde
f810237e:	e8 08 dd ff ff       	call   f810008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f8102383:	83 c0 01             	add    $0x1,%eax
f8102386:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f810238b:	0f 86 50 ff ff ff    	jbe    f81022e1 <mem_init+0x1238>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f8102391:	83 ec 0c             	sub    $0xc,%esp
f8102394:	68 d8 46 10 f8       	push   $0xf81046d8
f8102399:	e8 c1 03 00 00       	call   f810275f <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f810239e:	a1 6c 79 11 f8       	mov    0xf811796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f81023a3:	83 c4 10             	add    $0x10,%esp
f81023a6:	3d ff ff ff f7       	cmp    $0xf7ffffff,%eax
f81023ab:	77 15                	ja     f81023c2 <mem_init+0x1319>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f81023ad:	50                   	push   %eax
f81023ae:	68 88 41 10 f8       	push   $0xf8104188
f81023b3:	68 db 00 00 00       	push   $0xdb
f81023b8:	68 de 3c 10 f8       	push   $0xf8103cde
f81023bd:	e8 c9 dc ff ff       	call   f810008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f81023c2:	05 00 00 00 08       	add    $0x8000000,%eax
f81023c7:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f81023ca:	b8 00 00 00 00       	mov    $0x0,%eax
f81023cf:	e8 70 e6 ff ff       	call   f8100a44 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f81023d4:	0f 20 c0             	mov    %cr0,%eax
f81023d7:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f81023da:	0d 23 00 05 80       	or     $0x80050023,%eax
f81023df:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f81023e2:	83 ec 0c             	sub    $0xc,%esp
f81023e5:	6a 00                	push   $0x0
f81023e7:	e8 dd e9 ff ff       	call   f8100dc9 <page_alloc>
f81023ec:	89 c3                	mov    %eax,%ebx
f81023ee:	83 c4 10             	add    $0x10,%esp
f81023f1:	85 c0                	test   %eax,%eax
f81023f3:	75 19                	jne    f810240e <mem_init+0x1365>
f81023f5:	68 e0 3d 10 f8       	push   $0xf8103de0
f81023fa:	68 04 3d 10 f8       	push   $0xf8103d04
f81023ff:	68 77 03 00 00       	push   $0x377
f8102404:	68 de 3c 10 f8       	push   $0xf8103cde
f8102409:	e8 7d dc ff ff       	call   f810008b <_panic>
	assert((pp1 = page_alloc(0)));
f810240e:	83 ec 0c             	sub    $0xc,%esp
f8102411:	6a 00                	push   $0x0
f8102413:	e8 b1 e9 ff ff       	call   f8100dc9 <page_alloc>
f8102418:	89 c7                	mov    %eax,%edi
f810241a:	83 c4 10             	add    $0x10,%esp
f810241d:	85 c0                	test   %eax,%eax
f810241f:	75 19                	jne    f810243a <mem_init+0x1391>
f8102421:	68 f6 3d 10 f8       	push   $0xf8103df6
f8102426:	68 04 3d 10 f8       	push   $0xf8103d04
f810242b:	68 78 03 00 00       	push   $0x378
f8102430:	68 de 3c 10 f8       	push   $0xf8103cde
f8102435:	e8 51 dc ff ff       	call   f810008b <_panic>
	assert((pp2 = page_alloc(0)));
f810243a:	83 ec 0c             	sub    $0xc,%esp
f810243d:	6a 00                	push   $0x0
f810243f:	e8 85 e9 ff ff       	call   f8100dc9 <page_alloc>
f8102444:	89 c6                	mov    %eax,%esi
f8102446:	83 c4 10             	add    $0x10,%esp
f8102449:	85 c0                	test   %eax,%eax
f810244b:	75 19                	jne    f8102466 <mem_init+0x13bd>
f810244d:	68 0c 3e 10 f8       	push   $0xf8103e0c
f8102452:	68 04 3d 10 f8       	push   $0xf8103d04
f8102457:	68 79 03 00 00       	push   $0x379
f810245c:	68 de 3c 10 f8       	push   $0xf8103cde
f8102461:	e8 25 dc ff ff       	call   f810008b <_panic>
	page_free(pp0);
f8102466:	83 ec 0c             	sub    $0xc,%esp
f8102469:	53                   	push   %ebx
f810246a:	e8 ca e9 ff ff       	call   f8100e39 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f810246f:	89 f8                	mov    %edi,%eax
f8102471:	2b 05 70 79 11 f8    	sub    0xf8117970,%eax
f8102477:	c1 f8 03             	sar    $0x3,%eax
f810247a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f810247d:	89 c2                	mov    %eax,%edx
f810247f:	c1 ea 0c             	shr    $0xc,%edx
f8102482:	83 c4 10             	add    $0x10,%esp
f8102485:	3b 15 68 79 11 f8    	cmp    0xf8117968,%edx
f810248b:	72 12                	jb     f810249f <mem_init+0x13f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f810248d:	50                   	push   %eax
f810248e:	68 20 40 10 f8       	push   $0xf8104020
f8102493:	6a 52                	push   $0x52
f8102495:	68 ea 3c 10 f8       	push   $0xf8103cea
f810249a:	e8 ec db ff ff       	call   f810008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f810249f:	83 ec 04             	sub    $0x4,%esp
f81024a2:	68 00 10 00 00       	push   $0x1000
f81024a7:	6a 01                	push   $0x1
f81024a9:	2d 00 00 00 08       	sub    $0x8000000,%eax
f81024ae:	50                   	push   %eax
f81024af:	e8 04 0e 00 00       	call   f81032b8 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f81024b4:	89 f0                	mov    %esi,%eax
f81024b6:	2b 05 70 79 11 f8    	sub    0xf8117970,%eax
f81024bc:	c1 f8 03             	sar    $0x3,%eax
f81024bf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f81024c2:	89 c2                	mov    %eax,%edx
f81024c4:	c1 ea 0c             	shr    $0xc,%edx
f81024c7:	83 c4 10             	add    $0x10,%esp
f81024ca:	3b 15 68 79 11 f8    	cmp    0xf8117968,%edx
f81024d0:	72 12                	jb     f81024e4 <mem_init+0x143b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f81024d2:	50                   	push   %eax
f81024d3:	68 20 40 10 f8       	push   $0xf8104020
f81024d8:	6a 52                	push   $0x52
f81024da:	68 ea 3c 10 f8       	push   $0xf8103cea
f81024df:	e8 a7 db ff ff       	call   f810008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f81024e4:	83 ec 04             	sub    $0x4,%esp
f81024e7:	68 00 10 00 00       	push   $0x1000
f81024ec:	6a 02                	push   $0x2
f81024ee:	2d 00 00 00 08       	sub    $0x8000000,%eax
f81024f3:	50                   	push   %eax
f81024f4:	e8 bf 0d 00 00       	call   f81032b8 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f81024f9:	6a 02                	push   $0x2
f81024fb:	68 00 10 00 00       	push   $0x1000
f8102500:	57                   	push   %edi
f8102501:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f8102507:	e8 37 eb ff ff       	call   f8101043 <page_insert>
	assert(pp1->pp_ref == 1);
f810250c:	83 c4 20             	add    $0x20,%esp
f810250f:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f8102514:	74 19                	je     f810252f <mem_init+0x1486>
f8102516:	68 dd 3e 10 f8       	push   $0xf8103edd
f810251b:	68 04 3d 10 f8       	push   $0xf8103d04
f8102520:	68 7e 03 00 00       	push   $0x37e
f8102525:	68 de 3c 10 f8       	push   $0xf8103cde
f810252a:	e8 5c db ff ff       	call   f810008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f810252f:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f8102536:	01 01 01 
f8102539:	74 19                	je     f8102554 <mem_init+0x14ab>
f810253b:	68 f8 46 10 f8       	push   $0xf81046f8
f8102540:	68 04 3d 10 f8       	push   $0xf8103d04
f8102545:	68 7f 03 00 00       	push   $0x37f
f810254a:	68 de 3c 10 f8       	push   $0xf8103cde
f810254f:	e8 37 db ff ff       	call   f810008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f8102554:	6a 02                	push   $0x2
f8102556:	68 00 10 00 00       	push   $0x1000
f810255b:	56                   	push   %esi
f810255c:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f8102562:	e8 dc ea ff ff       	call   f8101043 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f8102567:	83 c4 10             	add    $0x10,%esp
f810256a:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f8102571:	02 02 02 
f8102574:	74 19                	je     f810258f <mem_init+0x14e6>
f8102576:	68 1c 47 10 f8       	push   $0xf810471c
f810257b:	68 04 3d 10 f8       	push   $0xf8103d04
f8102580:	68 81 03 00 00       	push   $0x381
f8102585:	68 de 3c 10 f8       	push   $0xf8103cde
f810258a:	e8 fc da ff ff       	call   f810008b <_panic>
	assert(pp2->pp_ref == 1);
f810258f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f8102594:	74 19                	je     f81025af <mem_init+0x1506>
f8102596:	68 ff 3e 10 f8       	push   $0xf8103eff
f810259b:	68 04 3d 10 f8       	push   $0xf8103d04
f81025a0:	68 82 03 00 00       	push   $0x382
f81025a5:	68 de 3c 10 f8       	push   $0xf8103cde
f81025aa:	e8 dc da ff ff       	call   f810008b <_panic>
	assert(pp1->pp_ref == 0);
f81025af:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f81025b4:	74 19                	je     f81025cf <mem_init+0x1526>
f81025b6:	68 69 3f 10 f8       	push   $0xf8103f69
f81025bb:	68 04 3d 10 f8       	push   $0xf8103d04
f81025c0:	68 83 03 00 00       	push   $0x383
f81025c5:	68 de 3c 10 f8       	push   $0xf8103cde
f81025ca:	e8 bc da ff ff       	call   f810008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f81025cf:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f81025d6:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f81025d9:	89 f0                	mov    %esi,%eax
f81025db:	2b 05 70 79 11 f8    	sub    0xf8117970,%eax
f81025e1:	c1 f8 03             	sar    $0x3,%eax
f81025e4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f81025e7:	89 c2                	mov    %eax,%edx
f81025e9:	c1 ea 0c             	shr    $0xc,%edx
f81025ec:	3b 15 68 79 11 f8    	cmp    0xf8117968,%edx
f81025f2:	72 12                	jb     f8102606 <mem_init+0x155d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f81025f4:	50                   	push   %eax
f81025f5:	68 20 40 10 f8       	push   $0xf8104020
f81025fa:	6a 52                	push   $0x52
f81025fc:	68 ea 3c 10 f8       	push   $0xf8103cea
f8102601:	e8 85 da ff ff       	call   f810008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f8102606:	81 b8 00 00 00 f8 03 	cmpl   $0x3030303,-0x8000000(%eax)
f810260d:	03 03 03 
f8102610:	74 19                	je     f810262b <mem_init+0x1582>
f8102612:	68 40 47 10 f8       	push   $0xf8104740
f8102617:	68 04 3d 10 f8       	push   $0xf8103d04
f810261c:	68 85 03 00 00       	push   $0x385
f8102621:	68 de 3c 10 f8       	push   $0xf8103cde
f8102626:	e8 60 da ff ff       	call   f810008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f810262b:	83 ec 08             	sub    $0x8,%esp
f810262e:	68 00 10 00 00       	push   $0x1000
f8102633:	ff 35 6c 79 11 f8    	pushl  0xf811796c
f8102639:	e8 c1 e9 ff ff       	call   f8100fff <page_remove>
	assert(pp2->pp_ref == 0);
f810263e:	83 c4 10             	add    $0x10,%esp
f8102641:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f8102646:	74 19                	je     f8102661 <mem_init+0x15b8>
f8102648:	68 37 3f 10 f8       	push   $0xf8103f37
f810264d:	68 04 3d 10 f8       	push   $0xf8103d04
f8102652:	68 87 03 00 00       	push   $0x387
f8102657:	68 de 3c 10 f8       	push   $0xf8103cde
f810265c:	e8 2a da ff ff       	call   f810008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f8102661:	8b 0d 6c 79 11 f8    	mov    0xf811796c,%ecx
f8102667:	8b 11                	mov    (%ecx),%edx
f8102669:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f810266f:	89 d8                	mov    %ebx,%eax
f8102671:	2b 05 70 79 11 f8    	sub    0xf8117970,%eax
f8102677:	c1 f8 03             	sar    $0x3,%eax
f810267a:	c1 e0 0c             	shl    $0xc,%eax
f810267d:	39 c2                	cmp    %eax,%edx
f810267f:	74 19                	je     f810269a <mem_init+0x15f1>
f8102681:	68 84 42 10 f8       	push   $0xf8104284
f8102686:	68 04 3d 10 f8       	push   $0xf8103d04
f810268b:	68 8a 03 00 00       	push   $0x38a
f8102690:	68 de 3c 10 f8       	push   $0xf8103cde
f8102695:	e8 f1 d9 ff ff       	call   f810008b <_panic>
	kern_pgdir[0] = 0;
f810269a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f81026a0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f81026a5:	74 19                	je     f81026c0 <mem_init+0x1617>
f81026a7:	68 ee 3e 10 f8       	push   $0xf8103eee
f81026ac:	68 04 3d 10 f8       	push   $0xf8103d04
f81026b1:	68 8c 03 00 00       	push   $0x38c
f81026b6:	68 de 3c 10 f8       	push   $0xf8103cde
f81026bb:	e8 cb d9 ff ff       	call   f810008b <_panic>
	pp0->pp_ref = 0;
f81026c0:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f81026c6:	83 ec 0c             	sub    $0xc,%esp
f81026c9:	53                   	push   %ebx
f81026ca:	e8 6a e7 ff ff       	call   f8100e39 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f81026cf:	c7 04 24 6c 47 10 f8 	movl   $0xf810476c,(%esp)
f81026d6:	e8 84 00 00 00       	call   f810275f <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f81026db:	83 c4 10             	add    $0x10,%esp
f81026de:	8d 65 f4             	lea    -0xc(%ebp),%esp
f81026e1:	5b                   	pop    %ebx
f81026e2:	5e                   	pop    %esi
f81026e3:	5f                   	pop    %edi
f81026e4:	5d                   	pop    %ebp
f81026e5:	c3                   	ret    

f81026e6 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f81026e6:	55                   	push   %ebp
f81026e7:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f81026e9:	8b 45 0c             	mov    0xc(%ebp),%eax
f81026ec:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f81026ef:	5d                   	pop    %ebp
f81026f0:	c3                   	ret    

f81026f1 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f81026f1:	55                   	push   %ebp
f81026f2:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f81026f4:	ba 70 00 00 00       	mov    $0x70,%edx
f81026f9:	8b 45 08             	mov    0x8(%ebp),%eax
f81026fc:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f81026fd:	ba 71 00 00 00       	mov    $0x71,%edx
f8102702:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f8102703:	0f b6 c0             	movzbl %al,%eax
}
f8102706:	5d                   	pop    %ebp
f8102707:	c3                   	ret    

f8102708 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f8102708:	55                   	push   %ebp
f8102709:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f810270b:	ba 70 00 00 00       	mov    $0x70,%edx
f8102710:	8b 45 08             	mov    0x8(%ebp),%eax
f8102713:	ee                   	out    %al,(%dx)
f8102714:	ba 71 00 00 00       	mov    $0x71,%edx
f8102719:	8b 45 0c             	mov    0xc(%ebp),%eax
f810271c:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f810271d:	5d                   	pop    %ebp
f810271e:	c3                   	ret    

f810271f <putch>:

extern int col;

static void
putch(int ch, int *cnt)
{
f810271f:	55                   	push   %ebp
f8102720:	89 e5                	mov    %esp,%ebp
f8102722:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch | col);
f8102725:	8b 45 08             	mov    0x8(%ebp),%eax
f8102728:	0b 05 74 79 11 f8    	or     0xf8117974,%eax
f810272e:	50                   	push   %eax
f810272f:	e8 cc de ff ff       	call   f8100600 <cputchar>
	*cnt++;
}
f8102734:	83 c4 10             	add    $0x10,%esp
f8102737:	c9                   	leave  
f8102738:	c3                   	ret    

f8102739 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f8102739:	55                   	push   %ebp
f810273a:	89 e5                	mov    %esp,%ebp
f810273c:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f810273f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f8102746:	ff 75 0c             	pushl  0xc(%ebp)
f8102749:	ff 75 08             	pushl  0x8(%ebp)
f810274c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f810274f:	50                   	push   %eax
f8102750:	68 1f 27 10 f8       	push   $0xf810271f
f8102755:	e8 98 04 00 00       	call   f8102bf2 <vprintfmt>
	return cnt;
}
f810275a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f810275d:	c9                   	leave  
f810275e:	c3                   	ret    

f810275f <cprintf>:

int
cprintf(const char *fmt, ...)
{
f810275f:	55                   	push   %ebp
f8102760:	89 e5                	mov    %esp,%ebp
f8102762:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f8102765:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f8102768:	50                   	push   %eax
f8102769:	ff 75 08             	pushl  0x8(%ebp)
f810276c:	e8 c8 ff ff ff       	call   f8102739 <vcprintf>
	va_end(ap);

	return cnt;
}
f8102771:	c9                   	leave  
f8102772:	c3                   	ret    

f8102773 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f8102773:	55                   	push   %ebp
f8102774:	89 e5                	mov    %esp,%ebp
f8102776:	57                   	push   %edi
f8102777:	56                   	push   %esi
f8102778:	53                   	push   %ebx
f8102779:	83 ec 14             	sub    $0x14,%esp
f810277c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f810277f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f8102782:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f8102785:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f8102788:	8b 1a                	mov    (%edx),%ebx
f810278a:	8b 01                	mov    (%ecx),%eax
f810278c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f810278f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f8102796:	eb 7f                	jmp    f8102817 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f8102798:	8b 45 f0             	mov    -0x10(%ebp),%eax
f810279b:	01 d8                	add    %ebx,%eax
f810279d:	89 c6                	mov    %eax,%esi
f810279f:	c1 ee 1f             	shr    $0x1f,%esi
f81027a2:	01 c6                	add    %eax,%esi
f81027a4:	d1 fe                	sar    %esi
f81027a6:	8d 04 76             	lea    (%esi,%esi,2),%eax
f81027a9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f81027ac:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f81027af:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f81027b1:	eb 03                	jmp    f81027b6 <stab_binsearch+0x43>
			m--;
f81027b3:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f81027b6:	39 c3                	cmp    %eax,%ebx
f81027b8:	7f 0d                	jg     f81027c7 <stab_binsearch+0x54>
f81027ba:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f81027be:	83 ea 0c             	sub    $0xc,%edx
f81027c1:	39 f9                	cmp    %edi,%ecx
f81027c3:	75 ee                	jne    f81027b3 <stab_binsearch+0x40>
f81027c5:	eb 05                	jmp    f81027cc <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f81027c7:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f81027ca:	eb 4b                	jmp    f8102817 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f81027cc:	8d 14 40             	lea    (%eax,%eax,2),%edx
f81027cf:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f81027d2:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f81027d6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f81027d9:	76 11                	jbe    f81027ec <stab_binsearch+0x79>
			*region_left = m;
f81027db:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f81027de:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f81027e0:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f81027e3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f81027ea:	eb 2b                	jmp    f8102817 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f81027ec:	39 55 0c             	cmp    %edx,0xc(%ebp)
f81027ef:	73 14                	jae    f8102805 <stab_binsearch+0x92>
			*region_right = m - 1;
f81027f1:	83 e8 01             	sub    $0x1,%eax
f81027f4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f81027f7:	8b 75 e0             	mov    -0x20(%ebp),%esi
f81027fa:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f81027fc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f8102803:	eb 12                	jmp    f8102817 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f8102805:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f8102808:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f810280a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f810280e:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f8102810:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f8102817:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f810281a:	0f 8e 78 ff ff ff    	jle    f8102798 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f8102820:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f8102824:	75 0f                	jne    f8102835 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f8102826:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f8102829:	8b 00                	mov    (%eax),%eax
f810282b:	83 e8 01             	sub    $0x1,%eax
f810282e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f8102831:	89 06                	mov    %eax,(%esi)
f8102833:	eb 2c                	jmp    f8102861 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f8102835:	8b 45 e0             	mov    -0x20(%ebp),%eax
f8102838:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f810283a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f810283d:	8b 0e                	mov    (%esi),%ecx
f810283f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f8102842:	8b 75 ec             	mov    -0x14(%ebp),%esi
f8102845:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f8102848:	eb 03                	jmp    f810284d <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f810284a:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f810284d:	39 c8                	cmp    %ecx,%eax
f810284f:	7e 0b                	jle    f810285c <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f8102851:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f8102855:	83 ea 0c             	sub    $0xc,%edx
f8102858:	39 df                	cmp    %ebx,%edi
f810285a:	75 ee                	jne    f810284a <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f810285c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f810285f:	89 06                	mov    %eax,(%esi)
	}
}
f8102861:	83 c4 14             	add    $0x14,%esp
f8102864:	5b                   	pop    %ebx
f8102865:	5e                   	pop    %esi
f8102866:	5f                   	pop    %edi
f8102867:	5d                   	pop    %ebp
f8102868:	c3                   	ret    

f8102869 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f8102869:	55                   	push   %ebp
f810286a:	89 e5                	mov    %esp,%ebp
f810286c:	57                   	push   %edi
f810286d:	56                   	push   %esi
f810286e:	53                   	push   %ebx
f810286f:	83 ec 3c             	sub    $0x3c,%esp
f8102872:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f8102875:	c7 03 98 47 10 f8    	movl   $0xf8104798,(%ebx)
	info->eip_line = 0;
f810287b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f8102882:	c7 43 08 98 47 10 f8 	movl   $0xf8104798,0x8(%ebx)
	info->eip_fn_namelen = 9;
f8102889:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f8102890:	8b 45 08             	mov    0x8(%ebp),%eax
f8102893:	89 43 10             	mov    %eax,0x10(%ebx)
	info->eip_fn_narg = 0;
f8102896:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f810289d:	3d ff ff 7f f7       	cmp    $0xf77fffff,%eax
f81028a2:	76 11                	jbe    f81028b5 <debuginfo_eip+0x4c>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f81028a4:	b8 c8 c1 10 f8       	mov    $0xf810c1c8,%eax
f81028a9:	3d fd a3 10 f8       	cmp    $0xf810a3fd,%eax
f81028ae:	77 19                	ja     f81028c9 <debuginfo_eip+0x60>
f81028b0:	e9 07 02 00 00       	jmp    f8102abc <debuginfo_eip+0x253>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f81028b5:	83 ec 04             	sub    $0x4,%esp
f81028b8:	68 a2 47 10 f8       	push   $0xf81047a2
f81028bd:	6a 7f                	push   $0x7f
f81028bf:	68 af 47 10 f8       	push   $0xf81047af
f81028c4:	e8 c2 d7 ff ff       	call   f810008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f81028c9:	80 3d c7 c1 10 f8 00 	cmpb   $0x0,0xf810c1c7
f81028d0:	0f 85 ed 01 00 00    	jne    f8102ac3 <debuginfo_eip+0x25a>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f81028d6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f81028dd:	b8 fc a3 10 f8       	mov    $0xf810a3fc,%eax
f81028e2:	2d cc 49 10 f8       	sub    $0xf81049cc,%eax
f81028e7:	c1 f8 02             	sar    $0x2,%eax
f81028ea:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f81028f0:	83 e8 01             	sub    $0x1,%eax
f81028f3:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f81028f6:	83 ec 08             	sub    $0x8,%esp
f81028f9:	ff 75 08             	pushl  0x8(%ebp)
f81028fc:	6a 64                	push   $0x64
f81028fe:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f8102901:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f8102904:	b8 cc 49 10 f8       	mov    $0xf81049cc,%eax
f8102909:	e8 65 fe ff ff       	call   f8102773 <stab_binsearch>
	if (lfile == 0)
f810290e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f8102911:	83 c4 10             	add    $0x10,%esp
f8102914:	85 c0                	test   %eax,%eax
f8102916:	0f 84 ae 01 00 00    	je     f8102aca <debuginfo_eip+0x261>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f810291c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f810291f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f8102922:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f8102925:	83 ec 08             	sub    $0x8,%esp
f8102928:	ff 75 08             	pushl  0x8(%ebp)
f810292b:	6a 24                	push   $0x24
f810292d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f8102930:	8d 55 dc             	lea    -0x24(%ebp),%edx
f8102933:	b8 cc 49 10 f8       	mov    $0xf81049cc,%eax
f8102938:	e8 36 fe ff ff       	call   f8102773 <stab_binsearch>

	if (lfun <= rfun) {
f810293d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f8102940:	8b 55 d8             	mov    -0x28(%ebp),%edx
f8102943:	83 c4 10             	add    $0x10,%esp
f8102946:	39 d0                	cmp    %edx,%eax
f8102948:	7f 3b                	jg     f8102985 <debuginfo_eip+0x11c>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f810294a:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f810294d:	c1 e1 02             	shl    $0x2,%ecx
f8102950:	8d b9 cc 49 10 f8    	lea    -0x7efb634(%ecx),%edi
f8102956:	8b b1 cc 49 10 f8    	mov    -0x7efb634(%ecx),%esi
f810295c:	b9 c8 c1 10 f8       	mov    $0xf810c1c8,%ecx
f8102961:	81 e9 fd a3 10 f8    	sub    $0xf810a3fd,%ecx
f8102967:	39 ce                	cmp    %ecx,%esi
f8102969:	73 09                	jae    f8102974 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f810296b:	81 c6 fd a3 10 f8    	add    $0xf810a3fd,%esi
f8102971:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f8102974:	8b 4f 08             	mov    0x8(%edi),%ecx
f8102977:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f810297a:	29 4d 08             	sub    %ecx,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f810297d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f8102980:	89 55 d0             	mov    %edx,-0x30(%ebp)
f8102983:	eb 12                	jmp    f8102997 <debuginfo_eip+0x12e>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f8102985:	8b 45 08             	mov    0x8(%ebp),%eax
f8102988:	89 43 10             	mov    %eax,0x10(%ebx)
		lline = lfile;
f810298b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f810298e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f8102991:	8b 45 e0             	mov    -0x20(%ebp),%eax
f8102994:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f8102997:	83 ec 08             	sub    $0x8,%esp
f810299a:	6a 3a                	push   $0x3a
f810299c:	ff 73 08             	pushl  0x8(%ebx)
f810299f:	e8 f8 08 00 00       	call   f810329c <strfind>
f81029a4:	2b 43 08             	sub    0x8(%ebx),%eax
f81029a7:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f81029aa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f81029ad:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f81029b0:	8d 14 40             	lea    (%eax,%eax,2),%edx
f81029b3:	8d 14 95 cc 49 10 f8 	lea    -0x7efb634(,%edx,4),%edx
f81029ba:	83 c4 10             	add    $0x10,%esp
f81029bd:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f81029c1:	eb 0a                	jmp    f81029cd <debuginfo_eip+0x164>
f81029c3:	83 e8 01             	sub    $0x1,%eax
f81029c6:	83 ea 0c             	sub    $0xc,%edx
f81029c9:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f81029cd:	89 45 c0             	mov    %eax,-0x40(%ebp)
f81029d0:	39 c7                	cmp    %eax,%edi
f81029d2:	7e 0b                	jle    f81029df <debuginfo_eip+0x176>
f81029d4:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f81029d8:	74 53                	je     f8102a2d <debuginfo_eip+0x1c4>
f81029da:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f81029dd:	eb 4e                	jmp    f8102a2d <debuginfo_eip+0x1c4>
	       && stabs[lline].n_type != N_SOL
f81029df:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f81029e3:	80 f9 84             	cmp    $0x84,%cl
f81029e6:	75 0e                	jne    f81029f6 <debuginfo_eip+0x18d>
f81029e8:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f81029ec:	74 1f                	je     f8102a0d <debuginfo_eip+0x1a4>
f81029ee:	8b 7d c0             	mov    -0x40(%ebp),%edi
f81029f1:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f81029f4:	eb 17                	jmp    f8102a0d <debuginfo_eip+0x1a4>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f81029f6:	80 f9 64             	cmp    $0x64,%cl
f81029f9:	75 c8                	jne    f81029c3 <debuginfo_eip+0x15a>
f81029fb:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f81029ff:	74 c2                	je     f81029c3 <debuginfo_eip+0x15a>
f8102a01:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f8102a05:	74 06                	je     f8102a0d <debuginfo_eip+0x1a4>
f8102a07:	8b 7d c0             	mov    -0x40(%ebp),%edi
f8102a0a:	89 7d d4             	mov    %edi,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f8102a0d:	8d 04 40             	lea    (%eax,%eax,2),%eax
f8102a10:	8b 14 85 cc 49 10 f8 	mov    -0x7efb634(,%eax,4),%edx
f8102a17:	b8 c8 c1 10 f8       	mov    $0xf810c1c8,%eax
f8102a1c:	2d fd a3 10 f8       	sub    $0xf810a3fd,%eax
f8102a21:	39 c2                	cmp    %eax,%edx
f8102a23:	73 08                	jae    f8102a2d <debuginfo_eip+0x1c4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f8102a25:	81 c2 fd a3 10 f8    	add    $0xf810a3fd,%edx
f8102a2b:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f8102a2d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f8102a30:	8b 75 d8             	mov    -0x28(%ebp),%esi
f8102a33:	39 f0                	cmp    %esi,%eax
f8102a35:	7d 52                	jge    f8102a89 <debuginfo_eip+0x220>
		for (lline = lfun + 1;
f8102a37:	8d 50 01             	lea    0x1(%eax),%edx
f8102a3a:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f8102a3d:	89 d0                	mov    %edx,%eax
f8102a3f:	8d 14 52             	lea    (%edx,%edx,2),%edx
f8102a42:	8d 14 95 cc 49 10 f8 	lea    -0x7efb634(,%edx,4),%edx
f8102a49:	bf 00 00 00 00       	mov    $0x0,%edi
f8102a4e:	eb 09                	jmp    f8102a59 <debuginfo_eip+0x1f0>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f8102a50:	83 43 14 01          	addl   $0x1,0x14(%ebx)
f8102a54:	bf 01 00 00 00       	mov    $0x1,%edi
f8102a59:	89 45 c4             	mov    %eax,-0x3c(%ebp)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f8102a5c:	39 c6                	cmp    %eax,%esi
f8102a5e:	7f 0e                	jg     f8102a6e <debuginfo_eip+0x205>
f8102a60:	89 f8                	mov    %edi,%eax
f8102a62:	84 c0                	test   %al,%al
f8102a64:	74 23                	je     f8102a89 <debuginfo_eip+0x220>
f8102a66:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f8102a69:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f8102a6c:	eb 1b                	jmp    f8102a89 <debuginfo_eip+0x220>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f8102a6e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f8102a72:	83 c0 01             	add    $0x1,%eax
f8102a75:	83 c2 0c             	add    $0xc,%edx
f8102a78:	80 f9 a0             	cmp    $0xa0,%cl
f8102a7b:	74 d3                	je     f8102a50 <debuginfo_eip+0x1e7>
f8102a7d:	89 f8                	mov    %edi,%eax
f8102a7f:	84 c0                	test   %al,%al
f8102a81:	74 06                	je     f8102a89 <debuginfo_eip+0x220>
f8102a83:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f8102a86:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		     lline++)
			info->eip_fn_narg++;

	// Search the line number.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f8102a89:	83 ec 08             	sub    $0x8,%esp
f8102a8c:	ff 75 08             	pushl  0x8(%ebp)
f8102a8f:	6a 44                	push   $0x44
f8102a91:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f8102a94:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f8102a97:	b8 cc 49 10 f8       	mov    $0xf81049cc,%eax
f8102a9c:	e8 d2 fc ff ff       	call   f8102773 <stab_binsearch>
	info->eip_line = stabs[lline].n_desc;
f8102aa1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f8102aa4:	8d 04 40             	lea    (%eax,%eax,2),%eax
f8102aa7:	0f b7 04 85 d2 49 10 	movzwl -0x7efb62e(,%eax,4),%eax
f8102aae:	f8 
f8102aaf:	89 43 04             	mov    %eax,0x4(%ebx)

	return 0;
f8102ab2:	83 c4 10             	add    $0x10,%esp
f8102ab5:	b8 00 00 00 00       	mov    $0x0,%eax
f8102aba:	eb 13                	jmp    f8102acf <debuginfo_eip+0x266>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f8102abc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f8102ac1:	eb 0c                	jmp    f8102acf <debuginfo_eip+0x266>
f8102ac3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f8102ac8:	eb 05                	jmp    f8102acf <debuginfo_eip+0x266>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f8102aca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	// Search the line number.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	info->eip_line = stabs[lline].n_desc;

	return 0;
}
f8102acf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f8102ad2:	5b                   	pop    %ebx
f8102ad3:	5e                   	pop    %esi
f8102ad4:	5f                   	pop    %edi
f8102ad5:	5d                   	pop    %ebp
f8102ad6:	c3                   	ret    

f8102ad7 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f8102ad7:	55                   	push   %ebp
f8102ad8:	89 e5                	mov    %esp,%ebp
f8102ada:	57                   	push   %edi
f8102adb:	56                   	push   %esi
f8102adc:	53                   	push   %ebx
f8102add:	83 ec 1c             	sub    $0x1c,%esp
f8102ae0:	89 c7                	mov    %eax,%edi
f8102ae2:	89 d6                	mov    %edx,%esi
f8102ae4:	8b 45 08             	mov    0x8(%ebp),%eax
f8102ae7:	8b 55 0c             	mov    0xc(%ebp),%edx
f8102aea:	89 45 d8             	mov    %eax,-0x28(%ebp)
f8102aed:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f8102af0:	8b 4d 10             	mov    0x10(%ebp),%ecx
f8102af3:	bb 00 00 00 00       	mov    $0x0,%ebx
f8102af8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f8102afb:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f8102afe:	39 d3                	cmp    %edx,%ebx
f8102b00:	72 05                	jb     f8102b07 <printnum+0x30>
f8102b02:	39 45 10             	cmp    %eax,0x10(%ebp)
f8102b05:	77 45                	ja     f8102b4c <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f8102b07:	83 ec 0c             	sub    $0xc,%esp
f8102b0a:	ff 75 18             	pushl  0x18(%ebp)
f8102b0d:	8b 45 14             	mov    0x14(%ebp),%eax
f8102b10:	8d 58 ff             	lea    -0x1(%eax),%ebx
f8102b13:	53                   	push   %ebx
f8102b14:	ff 75 10             	pushl  0x10(%ebp)
f8102b17:	83 ec 08             	sub    $0x8,%esp
f8102b1a:	ff 75 e4             	pushl  -0x1c(%ebp)
f8102b1d:	ff 75 e0             	pushl  -0x20(%ebp)
f8102b20:	ff 75 dc             	pushl  -0x24(%ebp)
f8102b23:	ff 75 d8             	pushl  -0x28(%ebp)
f8102b26:	e8 95 09 00 00       	call   f81034c0 <__udivdi3>
f8102b2b:	83 c4 18             	add    $0x18,%esp
f8102b2e:	52                   	push   %edx
f8102b2f:	50                   	push   %eax
f8102b30:	89 f2                	mov    %esi,%edx
f8102b32:	89 f8                	mov    %edi,%eax
f8102b34:	e8 9e ff ff ff       	call   f8102ad7 <printnum>
f8102b39:	83 c4 20             	add    $0x20,%esp
f8102b3c:	eb 18                	jmp    f8102b56 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f8102b3e:	83 ec 08             	sub    $0x8,%esp
f8102b41:	56                   	push   %esi
f8102b42:	ff 75 18             	pushl  0x18(%ebp)
f8102b45:	ff d7                	call   *%edi
f8102b47:	83 c4 10             	add    $0x10,%esp
f8102b4a:	eb 03                	jmp    f8102b4f <printnum+0x78>
f8102b4c:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f8102b4f:	83 eb 01             	sub    $0x1,%ebx
f8102b52:	85 db                	test   %ebx,%ebx
f8102b54:	7f e8                	jg     f8102b3e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f8102b56:	83 ec 08             	sub    $0x8,%esp
f8102b59:	56                   	push   %esi
f8102b5a:	83 ec 04             	sub    $0x4,%esp
f8102b5d:	ff 75 e4             	pushl  -0x1c(%ebp)
f8102b60:	ff 75 e0             	pushl  -0x20(%ebp)
f8102b63:	ff 75 dc             	pushl  -0x24(%ebp)
f8102b66:	ff 75 d8             	pushl  -0x28(%ebp)
f8102b69:	e8 82 0a 00 00       	call   f81035f0 <__umoddi3>
f8102b6e:	83 c4 14             	add    $0x14,%esp
f8102b71:	0f be 80 bd 47 10 f8 	movsbl -0x7efb843(%eax),%eax
f8102b78:	50                   	push   %eax
f8102b79:	ff d7                	call   *%edi
}
f8102b7b:	83 c4 10             	add    $0x10,%esp
f8102b7e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f8102b81:	5b                   	pop    %ebx
f8102b82:	5e                   	pop    %esi
f8102b83:	5f                   	pop    %edi
f8102b84:	5d                   	pop    %ebp
f8102b85:	c3                   	ret    

f8102b86 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f8102b86:	55                   	push   %ebp
f8102b87:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f8102b89:	83 fa 01             	cmp    $0x1,%edx
f8102b8c:	7e 0e                	jle    f8102b9c <getint+0x16>
		return va_arg(*ap, long long);
f8102b8e:	8b 10                	mov    (%eax),%edx
f8102b90:	8d 4a 08             	lea    0x8(%edx),%ecx
f8102b93:	89 08                	mov    %ecx,(%eax)
f8102b95:	8b 02                	mov    (%edx),%eax
f8102b97:	8b 52 04             	mov    0x4(%edx),%edx
f8102b9a:	eb 1a                	jmp    f8102bb6 <getint+0x30>
	else if (lflag)
f8102b9c:	85 d2                	test   %edx,%edx
f8102b9e:	74 0c                	je     f8102bac <getint+0x26>
		return va_arg(*ap, long);
f8102ba0:	8b 10                	mov    (%eax),%edx
f8102ba2:	8d 4a 04             	lea    0x4(%edx),%ecx
f8102ba5:	89 08                	mov    %ecx,(%eax)
f8102ba7:	8b 02                	mov    (%edx),%eax
f8102ba9:	99                   	cltd   
f8102baa:	eb 0a                	jmp    f8102bb6 <getint+0x30>
	else
		return va_arg(*ap, int);
f8102bac:	8b 10                	mov    (%eax),%edx
f8102bae:	8d 4a 04             	lea    0x4(%edx),%ecx
f8102bb1:	89 08                	mov    %ecx,(%eax)
f8102bb3:	8b 02                	mov    (%edx),%eax
f8102bb5:	99                   	cltd   
}
f8102bb6:	5d                   	pop    %ebp
f8102bb7:	c3                   	ret    

f8102bb8 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f8102bb8:	55                   	push   %ebp
f8102bb9:	89 e5                	mov    %esp,%ebp
f8102bbb:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f8102bbe:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f8102bc2:	8b 10                	mov    (%eax),%edx
f8102bc4:	3b 50 04             	cmp    0x4(%eax),%edx
f8102bc7:	73 0a                	jae    f8102bd3 <sprintputch+0x1b>
		*b->buf++ = ch;
f8102bc9:	8d 4a 01             	lea    0x1(%edx),%ecx
f8102bcc:	89 08                	mov    %ecx,(%eax)
f8102bce:	8b 45 08             	mov    0x8(%ebp),%eax
f8102bd1:	88 02                	mov    %al,(%edx)
}
f8102bd3:	5d                   	pop    %ebp
f8102bd4:	c3                   	ret    

f8102bd5 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f8102bd5:	55                   	push   %ebp
f8102bd6:	89 e5                	mov    %esp,%ebp
f8102bd8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f8102bdb:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f8102bde:	50                   	push   %eax
f8102bdf:	ff 75 10             	pushl  0x10(%ebp)
f8102be2:	ff 75 0c             	pushl  0xc(%ebp)
f8102be5:	ff 75 08             	pushl  0x8(%ebp)
f8102be8:	e8 05 00 00 00       	call   f8102bf2 <vprintfmt>
	va_end(ap);
}
f8102bed:	83 c4 10             	add    $0x10,%esp
f8102bf0:	c9                   	leave  
f8102bf1:	c3                   	ret    

f8102bf2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f8102bf2:	55                   	push   %ebp
f8102bf3:	89 e5                	mov    %esp,%ebp
f8102bf5:	57                   	push   %edi
f8102bf6:	56                   	push   %esi
f8102bf7:	53                   	push   %ebx
f8102bf8:	83 ec 2c             	sub    $0x2c,%esp
f8102bfb:	8b 75 08             	mov    0x8(%ebp),%esi
f8102bfe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f8102c01:	8b 7d 10             	mov    0x10(%ebp),%edi
f8102c04:	eb 12                	jmp    f8102c18 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f8102c06:	85 c0                	test   %eax,%eax
f8102c08:	0f 84 e3 03 00 00    	je     f8102ff1 <vprintfmt+0x3ff>
				return;
			putch(ch, putdat);
f8102c0e:	83 ec 08             	sub    $0x8,%esp
f8102c11:	53                   	push   %ebx
f8102c12:	50                   	push   %eax
f8102c13:	ff d6                	call   *%esi
f8102c15:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f8102c18:	83 c7 01             	add    $0x1,%edi
f8102c1b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f8102c1f:	83 f8 25             	cmp    $0x25,%eax
f8102c22:	75 e2                	jne    f8102c06 <vprintfmt+0x14>
f8102c24:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f8102c28:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f8102c2f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f8102c36:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f8102c3d:	ba 00 00 00 00       	mov    $0x0,%edx
f8102c42:	eb 07                	jmp    f8102c4b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f8102c44:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f8102c47:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f8102c4b:	8d 47 01             	lea    0x1(%edi),%eax
f8102c4e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f8102c51:	0f b6 07             	movzbl (%edi),%eax
f8102c54:	0f b6 c8             	movzbl %al,%ecx
f8102c57:	83 e8 23             	sub    $0x23,%eax
f8102c5a:	3c 55                	cmp    $0x55,%al
f8102c5c:	0f 87 74 03 00 00    	ja     f8102fd6 <vprintfmt+0x3e4>
f8102c62:	0f b6 c0             	movzbl %al,%eax
f8102c65:	ff 24 85 48 48 10 f8 	jmp    *-0x7efb7b8(,%eax,4)
f8102c6c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f8102c6f:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f8102c73:	eb d6                	jmp    f8102c4b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f8102c75:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f8102c78:	b8 00 00 00 00       	mov    $0x0,%eax
f8102c7d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f8102c80:	8d 04 80             	lea    (%eax,%eax,4),%eax
f8102c83:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f8102c87:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f8102c8a:	8d 51 d0             	lea    -0x30(%ecx),%edx
f8102c8d:	83 fa 09             	cmp    $0x9,%edx
f8102c90:	77 39                	ja     f8102ccb <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f8102c92:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f8102c95:	eb e9                	jmp    f8102c80 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f8102c97:	8b 45 14             	mov    0x14(%ebp),%eax
f8102c9a:	8d 48 04             	lea    0x4(%eax),%ecx
f8102c9d:	89 4d 14             	mov    %ecx,0x14(%ebp)
f8102ca0:	8b 00                	mov    (%eax),%eax
f8102ca2:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f8102ca5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f8102ca8:	eb 27                	jmp    f8102cd1 <vprintfmt+0xdf>
f8102caa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f8102cad:	85 c0                	test   %eax,%eax
f8102caf:	b9 00 00 00 00       	mov    $0x0,%ecx
f8102cb4:	0f 49 c8             	cmovns %eax,%ecx
f8102cb7:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f8102cba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f8102cbd:	eb 8c                	jmp    f8102c4b <vprintfmt+0x59>
f8102cbf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f8102cc2:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f8102cc9:	eb 80                	jmp    f8102c4b <vprintfmt+0x59>
f8102ccb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f8102cce:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f8102cd1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f8102cd5:	0f 89 70 ff ff ff    	jns    f8102c4b <vprintfmt+0x59>
				width = precision, precision = -1;
f8102cdb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f8102cde:	89 45 e0             	mov    %eax,-0x20(%ebp)
f8102ce1:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f8102ce8:	e9 5e ff ff ff       	jmp    f8102c4b <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f8102ced:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f8102cf0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f8102cf3:	e9 53 ff ff ff       	jmp    f8102c4b <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f8102cf8:	8b 45 14             	mov    0x14(%ebp),%eax
f8102cfb:	8d 50 04             	lea    0x4(%eax),%edx
f8102cfe:	89 55 14             	mov    %edx,0x14(%ebp)
f8102d01:	83 ec 08             	sub    $0x8,%esp
f8102d04:	53                   	push   %ebx
f8102d05:	ff 30                	pushl  (%eax)
f8102d07:	ff d6                	call   *%esi
			break;
f8102d09:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f8102d0c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f8102d0f:	e9 04 ff ff ff       	jmp    f8102c18 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f8102d14:	8b 45 14             	mov    0x14(%ebp),%eax
f8102d17:	8d 50 04             	lea    0x4(%eax),%edx
f8102d1a:	89 55 14             	mov    %edx,0x14(%ebp)
f8102d1d:	8b 00                	mov    (%eax),%eax
f8102d1f:	99                   	cltd   
f8102d20:	31 d0                	xor    %edx,%eax
f8102d22:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f8102d24:	83 f8 06             	cmp    $0x6,%eax
f8102d27:	7f 0b                	jg     f8102d34 <vprintfmt+0x142>
f8102d29:	8b 14 85 a0 49 10 f8 	mov    -0x7efb660(,%eax,4),%edx
f8102d30:	85 d2                	test   %edx,%edx
f8102d32:	75 18                	jne    f8102d4c <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f8102d34:	50                   	push   %eax
f8102d35:	68 d5 47 10 f8       	push   $0xf81047d5
f8102d3a:	53                   	push   %ebx
f8102d3b:	56                   	push   %esi
f8102d3c:	e8 94 fe ff ff       	call   f8102bd5 <printfmt>
f8102d41:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f8102d44:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f8102d47:	e9 cc fe ff ff       	jmp    f8102c18 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f8102d4c:	52                   	push   %edx
f8102d4d:	68 16 3d 10 f8       	push   $0xf8103d16
f8102d52:	53                   	push   %ebx
f8102d53:	56                   	push   %esi
f8102d54:	e8 7c fe ff ff       	call   f8102bd5 <printfmt>
f8102d59:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f8102d5c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f8102d5f:	e9 b4 fe ff ff       	jmp    f8102c18 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f8102d64:	8b 45 14             	mov    0x14(%ebp),%eax
f8102d67:	8d 50 04             	lea    0x4(%eax),%edx
f8102d6a:	89 55 14             	mov    %edx,0x14(%ebp)
f8102d6d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f8102d6f:	85 ff                	test   %edi,%edi
f8102d71:	b8 ce 47 10 f8       	mov    $0xf81047ce,%eax
f8102d76:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f8102d79:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f8102d7d:	0f 8e 94 00 00 00    	jle    f8102e17 <vprintfmt+0x225>
f8102d83:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f8102d87:	0f 84 98 00 00 00    	je     f8102e25 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f8102d8d:	83 ec 08             	sub    $0x8,%esp
f8102d90:	ff 75 d0             	pushl  -0x30(%ebp)
f8102d93:	57                   	push   %edi
f8102d94:	e8 b9 03 00 00       	call   f8103152 <strnlen>
f8102d99:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f8102d9c:	29 c1                	sub    %eax,%ecx
f8102d9e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f8102da1:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f8102da4:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f8102da8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f8102dab:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f8102dae:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f8102db0:	eb 0f                	jmp    f8102dc1 <vprintfmt+0x1cf>
					putch(padc, putdat);
f8102db2:	83 ec 08             	sub    $0x8,%esp
f8102db5:	53                   	push   %ebx
f8102db6:	ff 75 e0             	pushl  -0x20(%ebp)
f8102db9:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f8102dbb:	83 ef 01             	sub    $0x1,%edi
f8102dbe:	83 c4 10             	add    $0x10,%esp
f8102dc1:	85 ff                	test   %edi,%edi
f8102dc3:	7f ed                	jg     f8102db2 <vprintfmt+0x1c0>
f8102dc5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f8102dc8:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f8102dcb:	85 c9                	test   %ecx,%ecx
f8102dcd:	b8 00 00 00 00       	mov    $0x0,%eax
f8102dd2:	0f 49 c1             	cmovns %ecx,%eax
f8102dd5:	29 c1                	sub    %eax,%ecx
f8102dd7:	89 75 08             	mov    %esi,0x8(%ebp)
f8102dda:	8b 75 d0             	mov    -0x30(%ebp),%esi
f8102ddd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f8102de0:	89 cb                	mov    %ecx,%ebx
f8102de2:	eb 4d                	jmp    f8102e31 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f8102de4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f8102de8:	74 1b                	je     f8102e05 <vprintfmt+0x213>
f8102dea:	0f be c0             	movsbl %al,%eax
f8102ded:	83 e8 20             	sub    $0x20,%eax
f8102df0:	83 f8 5e             	cmp    $0x5e,%eax
f8102df3:	76 10                	jbe    f8102e05 <vprintfmt+0x213>
					putch('?', putdat);
f8102df5:	83 ec 08             	sub    $0x8,%esp
f8102df8:	ff 75 0c             	pushl  0xc(%ebp)
f8102dfb:	6a 3f                	push   $0x3f
f8102dfd:	ff 55 08             	call   *0x8(%ebp)
f8102e00:	83 c4 10             	add    $0x10,%esp
f8102e03:	eb 0d                	jmp    f8102e12 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f8102e05:	83 ec 08             	sub    $0x8,%esp
f8102e08:	ff 75 0c             	pushl  0xc(%ebp)
f8102e0b:	52                   	push   %edx
f8102e0c:	ff 55 08             	call   *0x8(%ebp)
f8102e0f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f8102e12:	83 eb 01             	sub    $0x1,%ebx
f8102e15:	eb 1a                	jmp    f8102e31 <vprintfmt+0x23f>
f8102e17:	89 75 08             	mov    %esi,0x8(%ebp)
f8102e1a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f8102e1d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f8102e20:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f8102e23:	eb 0c                	jmp    f8102e31 <vprintfmt+0x23f>
f8102e25:	89 75 08             	mov    %esi,0x8(%ebp)
f8102e28:	8b 75 d0             	mov    -0x30(%ebp),%esi
f8102e2b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f8102e2e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f8102e31:	83 c7 01             	add    $0x1,%edi
f8102e34:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f8102e38:	0f be d0             	movsbl %al,%edx
f8102e3b:	85 d2                	test   %edx,%edx
f8102e3d:	74 23                	je     f8102e62 <vprintfmt+0x270>
f8102e3f:	85 f6                	test   %esi,%esi
f8102e41:	78 a1                	js     f8102de4 <vprintfmt+0x1f2>
f8102e43:	83 ee 01             	sub    $0x1,%esi
f8102e46:	79 9c                	jns    f8102de4 <vprintfmt+0x1f2>
f8102e48:	89 df                	mov    %ebx,%edi
f8102e4a:	8b 75 08             	mov    0x8(%ebp),%esi
f8102e4d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f8102e50:	eb 18                	jmp    f8102e6a <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f8102e52:	83 ec 08             	sub    $0x8,%esp
f8102e55:	53                   	push   %ebx
f8102e56:	6a 20                	push   $0x20
f8102e58:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f8102e5a:	83 ef 01             	sub    $0x1,%edi
f8102e5d:	83 c4 10             	add    $0x10,%esp
f8102e60:	eb 08                	jmp    f8102e6a <vprintfmt+0x278>
f8102e62:	89 df                	mov    %ebx,%edi
f8102e64:	8b 75 08             	mov    0x8(%ebp),%esi
f8102e67:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f8102e6a:	85 ff                	test   %edi,%edi
f8102e6c:	7f e4                	jg     f8102e52 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f8102e6e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f8102e71:	e9 a2 fd ff ff       	jmp    f8102c18 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f8102e76:	8d 45 14             	lea    0x14(%ebp),%eax
f8102e79:	e8 08 fd ff ff       	call   f8102b86 <getint>
f8102e7e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f8102e81:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f8102e84:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f8102e89:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f8102e8d:	0f 89 fa 00 00 00    	jns    f8102f8d <vprintfmt+0x39b>
				putch('-', putdat);
f8102e93:	83 ec 08             	sub    $0x8,%esp
f8102e96:	53                   	push   %ebx
f8102e97:	6a 2d                	push   $0x2d
f8102e99:	ff d6                	call   *%esi
				num = -(long long) num;
f8102e9b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f8102e9e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f8102ea1:	f7 d8                	neg    %eax
f8102ea3:	83 d2 00             	adc    $0x0,%edx
f8102ea6:	f7 da                	neg    %edx
f8102ea8:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f8102eab:	b9 0a 00 00 00       	mov    $0xa,%ecx
f8102eb0:	e9 d8 00 00 00       	jmp    f8102f8d <vprintfmt+0x39b>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f8102eb5:	83 fa 01             	cmp    $0x1,%edx
f8102eb8:	7e 18                	jle    f8102ed2 <vprintfmt+0x2e0>
		return va_arg(*ap, unsigned long long);
f8102eba:	8b 45 14             	mov    0x14(%ebp),%eax
f8102ebd:	8d 50 08             	lea    0x8(%eax),%edx
f8102ec0:	89 55 14             	mov    %edx,0x14(%ebp)
f8102ec3:	8b 50 04             	mov    0x4(%eax),%edx
f8102ec6:	8b 00                	mov    (%eax),%eax
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f8102ec8:	b9 0a 00 00 00       	mov    $0xa,%ecx
f8102ecd:	e9 bb 00 00 00       	jmp    f8102f8d <vprintfmt+0x39b>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f8102ed2:	85 d2                	test   %edx,%edx
f8102ed4:	74 1a                	je     f8102ef0 <vprintfmt+0x2fe>
		return va_arg(*ap, unsigned long);
f8102ed6:	8b 45 14             	mov    0x14(%ebp),%eax
f8102ed9:	8d 50 04             	lea    0x4(%eax),%edx
f8102edc:	89 55 14             	mov    %edx,0x14(%ebp)
f8102edf:	8b 00                	mov    (%eax),%eax
f8102ee1:	ba 00 00 00 00       	mov    $0x0,%edx
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f8102ee6:	b9 0a 00 00 00       	mov    $0xa,%ecx
f8102eeb:	e9 9d 00 00 00       	jmp    f8102f8d <vprintfmt+0x39b>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f8102ef0:	8b 45 14             	mov    0x14(%ebp),%eax
f8102ef3:	8d 50 04             	lea    0x4(%eax),%edx
f8102ef6:	89 55 14             	mov    %edx,0x14(%ebp)
f8102ef9:	8b 00                	mov    (%eax),%eax
f8102efb:	ba 00 00 00 00       	mov    $0x0,%edx
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f8102f00:	b9 0a 00 00 00       	mov    $0xa,%ecx
f8102f05:	e9 83 00 00 00       	jmp    f8102f8d <vprintfmt+0x39b>
			goto number;

		// (unsigned) octal
		case 'o':
			num = getint(&ap, lflag);
f8102f0a:	8d 45 14             	lea    0x14(%ebp),%eax
f8102f0d:	e8 74 fc ff ff       	call   f8102b86 <getint>
			base = 8;
f8102f12:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f8102f17:	eb 74                	jmp    f8102f8d <vprintfmt+0x39b>

		// pointer
		case 'p':
			putch('0', putdat);
f8102f19:	83 ec 08             	sub    $0x8,%esp
f8102f1c:	53                   	push   %ebx
f8102f1d:	6a 30                	push   $0x30
f8102f1f:	ff d6                	call   *%esi
			putch('x', putdat);
f8102f21:	83 c4 08             	add    $0x8,%esp
f8102f24:	53                   	push   %ebx
f8102f25:	6a 78                	push   $0x78
f8102f27:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f8102f29:	8b 45 14             	mov    0x14(%ebp),%eax
f8102f2c:	8d 50 04             	lea    0x4(%eax),%edx
f8102f2f:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f8102f32:	8b 00                	mov    (%eax),%eax
f8102f34:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f8102f39:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f8102f3c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f8102f41:	eb 4a                	jmp    f8102f8d <vprintfmt+0x39b>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f8102f43:	83 fa 01             	cmp    $0x1,%edx
f8102f46:	7e 15                	jle    f8102f5d <vprintfmt+0x36b>
		return va_arg(*ap, unsigned long long);
f8102f48:	8b 45 14             	mov    0x14(%ebp),%eax
f8102f4b:	8d 50 08             	lea    0x8(%eax),%edx
f8102f4e:	89 55 14             	mov    %edx,0x14(%ebp)
f8102f51:	8b 50 04             	mov    0x4(%eax),%edx
f8102f54:	8b 00                	mov    (%eax),%eax
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f8102f56:	b9 10 00 00 00       	mov    $0x10,%ecx
f8102f5b:	eb 30                	jmp    f8102f8d <vprintfmt+0x39b>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f8102f5d:	85 d2                	test   %edx,%edx
f8102f5f:	74 17                	je     f8102f78 <vprintfmt+0x386>
		return va_arg(*ap, unsigned long);
f8102f61:	8b 45 14             	mov    0x14(%ebp),%eax
f8102f64:	8d 50 04             	lea    0x4(%eax),%edx
f8102f67:	89 55 14             	mov    %edx,0x14(%ebp)
f8102f6a:	8b 00                	mov    (%eax),%eax
f8102f6c:	ba 00 00 00 00       	mov    $0x0,%edx
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f8102f71:	b9 10 00 00 00       	mov    $0x10,%ecx
f8102f76:	eb 15                	jmp    f8102f8d <vprintfmt+0x39b>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f8102f78:	8b 45 14             	mov    0x14(%ebp),%eax
f8102f7b:	8d 50 04             	lea    0x4(%eax),%edx
f8102f7e:	89 55 14             	mov    %edx,0x14(%ebp)
f8102f81:	8b 00                	mov    (%eax),%eax
f8102f83:	ba 00 00 00 00       	mov    $0x0,%edx
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f8102f88:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f8102f8d:	83 ec 0c             	sub    $0xc,%esp
f8102f90:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f8102f94:	57                   	push   %edi
f8102f95:	ff 75 e0             	pushl  -0x20(%ebp)
f8102f98:	51                   	push   %ecx
f8102f99:	52                   	push   %edx
f8102f9a:	50                   	push   %eax
f8102f9b:	89 da                	mov    %ebx,%edx
f8102f9d:	89 f0                	mov    %esi,%eax
f8102f9f:	e8 33 fb ff ff       	call   f8102ad7 <printnum>
			break;
f8102fa4:	83 c4 20             	add    $0x20,%esp
f8102fa7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f8102faa:	e9 69 fc ff ff       	jmp    f8102c18 <vprintfmt+0x26>
          
                // color text
		case 'a':
			col = getint(&ap, lflag);
f8102faf:	8d 45 14             	lea    0x14(%ebp),%eax
f8102fb2:	e8 cf fb ff ff       	call   f8102b86 <getint>
f8102fb7:	a3 74 79 11 f8       	mov    %eax,0xf8117974
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f8102fbc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;
          
                // color text
		case 'a':
			col = getint(&ap, lflag);
			break;
f8102fbf:	e9 54 fc ff ff       	jmp    f8102c18 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f8102fc4:	83 ec 08             	sub    $0x8,%esp
f8102fc7:	53                   	push   %ebx
f8102fc8:	51                   	push   %ecx
f8102fc9:	ff d6                	call   *%esi
			break;
f8102fcb:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f8102fce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f8102fd1:	e9 42 fc ff ff       	jmp    f8102c18 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f8102fd6:	83 ec 08             	sub    $0x8,%esp
f8102fd9:	53                   	push   %ebx
f8102fda:	6a 25                	push   $0x25
f8102fdc:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f8102fde:	83 c4 10             	add    $0x10,%esp
f8102fe1:	eb 03                	jmp    f8102fe6 <vprintfmt+0x3f4>
f8102fe3:	83 ef 01             	sub    $0x1,%edi
f8102fe6:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f8102fea:	75 f7                	jne    f8102fe3 <vprintfmt+0x3f1>
f8102fec:	e9 27 fc ff ff       	jmp    f8102c18 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f8102ff1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f8102ff4:	5b                   	pop    %ebx
f8102ff5:	5e                   	pop    %esi
f8102ff6:	5f                   	pop    %edi
f8102ff7:	5d                   	pop    %ebp
f8102ff8:	c3                   	ret    

f8102ff9 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f8102ff9:	55                   	push   %ebp
f8102ffa:	89 e5                	mov    %esp,%ebp
f8102ffc:	83 ec 18             	sub    $0x18,%esp
f8102fff:	8b 45 08             	mov    0x8(%ebp),%eax
f8103002:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f8103005:	89 45 ec             	mov    %eax,-0x14(%ebp)
f8103008:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f810300c:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f810300f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f8103016:	85 c0                	test   %eax,%eax
f8103018:	74 26                	je     f8103040 <vsnprintf+0x47>
f810301a:	85 d2                	test   %edx,%edx
f810301c:	7e 22                	jle    f8103040 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f810301e:	ff 75 14             	pushl  0x14(%ebp)
f8103021:	ff 75 10             	pushl  0x10(%ebp)
f8103024:	8d 45 ec             	lea    -0x14(%ebp),%eax
f8103027:	50                   	push   %eax
f8103028:	68 b8 2b 10 f8       	push   $0xf8102bb8
f810302d:	e8 c0 fb ff ff       	call   f8102bf2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f8103032:	8b 45 ec             	mov    -0x14(%ebp),%eax
f8103035:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f8103038:	8b 45 f4             	mov    -0xc(%ebp),%eax
f810303b:	83 c4 10             	add    $0x10,%esp
f810303e:	eb 05                	jmp    f8103045 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f8103040:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f8103045:	c9                   	leave  
f8103046:	c3                   	ret    

f8103047 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f8103047:	55                   	push   %ebp
f8103048:	89 e5                	mov    %esp,%ebp
f810304a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f810304d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f8103050:	50                   	push   %eax
f8103051:	ff 75 10             	pushl  0x10(%ebp)
f8103054:	ff 75 0c             	pushl  0xc(%ebp)
f8103057:	ff 75 08             	pushl  0x8(%ebp)
f810305a:	e8 9a ff ff ff       	call   f8102ff9 <vsnprintf>
	va_end(ap);

	return rc;
}
f810305f:	c9                   	leave  
f8103060:	c3                   	ret    

f8103061 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f8103061:	55                   	push   %ebp
f8103062:	89 e5                	mov    %esp,%ebp
f8103064:	57                   	push   %edi
f8103065:	56                   	push   %esi
f8103066:	53                   	push   %ebx
f8103067:	83 ec 0c             	sub    $0xc,%esp
f810306a:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f810306d:	85 c0                	test   %eax,%eax
f810306f:	74 11                	je     f8103082 <readline+0x21>
		cprintf("%s", prompt);
f8103071:	83 ec 08             	sub    $0x8,%esp
f8103074:	50                   	push   %eax
f8103075:	68 16 3d 10 f8       	push   $0xf8103d16
f810307a:	e8 e0 f6 ff ff       	call   f810275f <cprintf>
f810307f:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f8103082:	83 ec 0c             	sub    $0xc,%esp
f8103085:	6a 00                	push   $0x0
f8103087:	e8 ac d5 ff ff       	call   f8100638 <iscons>
f810308c:	89 c7                	mov    %eax,%edi
f810308e:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f8103091:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f8103096:	e8 75 d5 ff ff       	call   f8100610 <getchar>
f810309b:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f810309d:	85 c0                	test   %eax,%eax
f810309f:	79 18                	jns    f81030b9 <readline+0x58>
			cprintf("read error: %e\n", c);
f81030a1:	83 ec 08             	sub    $0x8,%esp
f81030a4:	50                   	push   %eax
f81030a5:	68 bc 49 10 f8       	push   $0xf81049bc
f81030aa:	e8 b0 f6 ff ff       	call   f810275f <cprintf>
			return NULL;
f81030af:	83 c4 10             	add    $0x10,%esp
f81030b2:	b8 00 00 00 00       	mov    $0x0,%eax
f81030b7:	eb 79                	jmp    f8103132 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f81030b9:	83 f8 08             	cmp    $0x8,%eax
f81030bc:	0f 94 c2             	sete   %dl
f81030bf:	83 f8 7f             	cmp    $0x7f,%eax
f81030c2:	0f 94 c0             	sete   %al
f81030c5:	08 c2                	or     %al,%dl
f81030c7:	74 1a                	je     f81030e3 <readline+0x82>
f81030c9:	85 f6                	test   %esi,%esi
f81030cb:	7e 16                	jle    f81030e3 <readline+0x82>
			if (echoing)
f81030cd:	85 ff                	test   %edi,%edi
f81030cf:	74 0d                	je     f81030de <readline+0x7d>
				cputchar('\b');
f81030d1:	83 ec 0c             	sub    $0xc,%esp
f81030d4:	6a 08                	push   $0x8
f81030d6:	e8 25 d5 ff ff       	call   f8100600 <cputchar>
f81030db:	83 c4 10             	add    $0x10,%esp
			i--;
f81030de:	83 ee 01             	sub    $0x1,%esi
f81030e1:	eb b3                	jmp    f8103096 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f81030e3:	83 fb 1f             	cmp    $0x1f,%ebx
f81030e6:	7e 23                	jle    f810310b <readline+0xaa>
f81030e8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f81030ee:	7f 1b                	jg     f810310b <readline+0xaa>
			if (echoing)
f81030f0:	85 ff                	test   %edi,%edi
f81030f2:	74 0c                	je     f8103100 <readline+0x9f>
				cputchar(c);
f81030f4:	83 ec 0c             	sub    $0xc,%esp
f81030f7:	53                   	push   %ebx
f81030f8:	e8 03 d5 ff ff       	call   f8100600 <cputchar>
f81030fd:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f8103100:	88 9e 60 75 11 f8    	mov    %bl,-0x7ee8aa0(%esi)
f8103106:	8d 76 01             	lea    0x1(%esi),%esi
f8103109:	eb 8b                	jmp    f8103096 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f810310b:	83 fb 0a             	cmp    $0xa,%ebx
f810310e:	74 05                	je     f8103115 <readline+0xb4>
f8103110:	83 fb 0d             	cmp    $0xd,%ebx
f8103113:	75 81                	jne    f8103096 <readline+0x35>
			if (echoing)
f8103115:	85 ff                	test   %edi,%edi
f8103117:	74 0d                	je     f8103126 <readline+0xc5>
				cputchar('\n');
f8103119:	83 ec 0c             	sub    $0xc,%esp
f810311c:	6a 0a                	push   $0xa
f810311e:	e8 dd d4 ff ff       	call   f8100600 <cputchar>
f8103123:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f8103126:	c6 86 60 75 11 f8 00 	movb   $0x0,-0x7ee8aa0(%esi)
			return buf;
f810312d:	b8 60 75 11 f8       	mov    $0xf8117560,%eax
		}
	}
}
f8103132:	8d 65 f4             	lea    -0xc(%ebp),%esp
f8103135:	5b                   	pop    %ebx
f8103136:	5e                   	pop    %esi
f8103137:	5f                   	pop    %edi
f8103138:	5d                   	pop    %ebp
f8103139:	c3                   	ret    

f810313a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f810313a:	55                   	push   %ebp
f810313b:	89 e5                	mov    %esp,%ebp
f810313d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f8103140:	b8 00 00 00 00       	mov    $0x0,%eax
f8103145:	eb 03                	jmp    f810314a <strlen+0x10>
		n++;
f8103147:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f810314a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f810314e:	75 f7                	jne    f8103147 <strlen+0xd>
		n++;
	return n;
}
f8103150:	5d                   	pop    %ebp
f8103151:	c3                   	ret    

f8103152 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f8103152:	55                   	push   %ebp
f8103153:	89 e5                	mov    %esp,%ebp
f8103155:	8b 4d 08             	mov    0x8(%ebp),%ecx
f8103158:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f810315b:	ba 00 00 00 00       	mov    $0x0,%edx
f8103160:	eb 03                	jmp    f8103165 <strnlen+0x13>
		n++;
f8103162:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f8103165:	39 c2                	cmp    %eax,%edx
f8103167:	74 08                	je     f8103171 <strnlen+0x1f>
f8103169:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f810316d:	75 f3                	jne    f8103162 <strnlen+0x10>
f810316f:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f8103171:	5d                   	pop    %ebp
f8103172:	c3                   	ret    

f8103173 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f8103173:	55                   	push   %ebp
f8103174:	89 e5                	mov    %esp,%ebp
f8103176:	53                   	push   %ebx
f8103177:	8b 45 08             	mov    0x8(%ebp),%eax
f810317a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f810317d:	89 c2                	mov    %eax,%edx
f810317f:	83 c2 01             	add    $0x1,%edx
f8103182:	83 c1 01             	add    $0x1,%ecx
f8103185:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f8103189:	88 5a ff             	mov    %bl,-0x1(%edx)
f810318c:	84 db                	test   %bl,%bl
f810318e:	75 ef                	jne    f810317f <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f8103190:	5b                   	pop    %ebx
f8103191:	5d                   	pop    %ebp
f8103192:	c3                   	ret    

f8103193 <strcat>:

char *
strcat(char *dst, const char *src)
{
f8103193:	55                   	push   %ebp
f8103194:	89 e5                	mov    %esp,%ebp
f8103196:	53                   	push   %ebx
f8103197:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f810319a:	53                   	push   %ebx
f810319b:	e8 9a ff ff ff       	call   f810313a <strlen>
f81031a0:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f81031a3:	ff 75 0c             	pushl  0xc(%ebp)
f81031a6:	01 d8                	add    %ebx,%eax
f81031a8:	50                   	push   %eax
f81031a9:	e8 c5 ff ff ff       	call   f8103173 <strcpy>
	return dst;
}
f81031ae:	89 d8                	mov    %ebx,%eax
f81031b0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f81031b3:	c9                   	leave  
f81031b4:	c3                   	ret    

f81031b5 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f81031b5:	55                   	push   %ebp
f81031b6:	89 e5                	mov    %esp,%ebp
f81031b8:	56                   	push   %esi
f81031b9:	53                   	push   %ebx
f81031ba:	8b 75 08             	mov    0x8(%ebp),%esi
f81031bd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f81031c0:	89 f3                	mov    %esi,%ebx
f81031c2:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f81031c5:	89 f2                	mov    %esi,%edx
f81031c7:	eb 0f                	jmp    f81031d8 <strncpy+0x23>
		*dst++ = *src;
f81031c9:	83 c2 01             	add    $0x1,%edx
f81031cc:	0f b6 01             	movzbl (%ecx),%eax
f81031cf:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f81031d2:	80 39 01             	cmpb   $0x1,(%ecx)
f81031d5:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f81031d8:	39 da                	cmp    %ebx,%edx
f81031da:	75 ed                	jne    f81031c9 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f81031dc:	89 f0                	mov    %esi,%eax
f81031de:	5b                   	pop    %ebx
f81031df:	5e                   	pop    %esi
f81031e0:	5d                   	pop    %ebp
f81031e1:	c3                   	ret    

f81031e2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f81031e2:	55                   	push   %ebp
f81031e3:	89 e5                	mov    %esp,%ebp
f81031e5:	56                   	push   %esi
f81031e6:	53                   	push   %ebx
f81031e7:	8b 75 08             	mov    0x8(%ebp),%esi
f81031ea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f81031ed:	8b 55 10             	mov    0x10(%ebp),%edx
f81031f0:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f81031f2:	85 d2                	test   %edx,%edx
f81031f4:	74 21                	je     f8103217 <strlcpy+0x35>
f81031f6:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f81031fa:	89 f2                	mov    %esi,%edx
f81031fc:	eb 09                	jmp    f8103207 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f81031fe:	83 c2 01             	add    $0x1,%edx
f8103201:	83 c1 01             	add    $0x1,%ecx
f8103204:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f8103207:	39 c2                	cmp    %eax,%edx
f8103209:	74 09                	je     f8103214 <strlcpy+0x32>
f810320b:	0f b6 19             	movzbl (%ecx),%ebx
f810320e:	84 db                	test   %bl,%bl
f8103210:	75 ec                	jne    f81031fe <strlcpy+0x1c>
f8103212:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f8103214:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f8103217:	29 f0                	sub    %esi,%eax
}
f8103219:	5b                   	pop    %ebx
f810321a:	5e                   	pop    %esi
f810321b:	5d                   	pop    %ebp
f810321c:	c3                   	ret    

f810321d <strcmp>:

int
strcmp(const char *p, const char *q)
{
f810321d:	55                   	push   %ebp
f810321e:	89 e5                	mov    %esp,%ebp
f8103220:	8b 4d 08             	mov    0x8(%ebp),%ecx
f8103223:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f8103226:	eb 06                	jmp    f810322e <strcmp+0x11>
		p++, q++;
f8103228:	83 c1 01             	add    $0x1,%ecx
f810322b:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f810322e:	0f b6 01             	movzbl (%ecx),%eax
f8103231:	84 c0                	test   %al,%al
f8103233:	74 04                	je     f8103239 <strcmp+0x1c>
f8103235:	3a 02                	cmp    (%edx),%al
f8103237:	74 ef                	je     f8103228 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f8103239:	0f b6 c0             	movzbl %al,%eax
f810323c:	0f b6 12             	movzbl (%edx),%edx
f810323f:	29 d0                	sub    %edx,%eax
}
f8103241:	5d                   	pop    %ebp
f8103242:	c3                   	ret    

f8103243 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f8103243:	55                   	push   %ebp
f8103244:	89 e5                	mov    %esp,%ebp
f8103246:	53                   	push   %ebx
f8103247:	8b 45 08             	mov    0x8(%ebp),%eax
f810324a:	8b 55 0c             	mov    0xc(%ebp),%edx
f810324d:	89 c3                	mov    %eax,%ebx
f810324f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f8103252:	eb 06                	jmp    f810325a <strncmp+0x17>
		n--, p++, q++;
f8103254:	83 c0 01             	add    $0x1,%eax
f8103257:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f810325a:	39 d8                	cmp    %ebx,%eax
f810325c:	74 15                	je     f8103273 <strncmp+0x30>
f810325e:	0f b6 08             	movzbl (%eax),%ecx
f8103261:	84 c9                	test   %cl,%cl
f8103263:	74 04                	je     f8103269 <strncmp+0x26>
f8103265:	3a 0a                	cmp    (%edx),%cl
f8103267:	74 eb                	je     f8103254 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f8103269:	0f b6 00             	movzbl (%eax),%eax
f810326c:	0f b6 12             	movzbl (%edx),%edx
f810326f:	29 d0                	sub    %edx,%eax
f8103271:	eb 05                	jmp    f8103278 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f8103273:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f8103278:	5b                   	pop    %ebx
f8103279:	5d                   	pop    %ebp
f810327a:	c3                   	ret    

f810327b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f810327b:	55                   	push   %ebp
f810327c:	89 e5                	mov    %esp,%ebp
f810327e:	8b 45 08             	mov    0x8(%ebp),%eax
f8103281:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f8103285:	eb 07                	jmp    f810328e <strchr+0x13>
		if (*s == c)
f8103287:	38 ca                	cmp    %cl,%dl
f8103289:	74 0f                	je     f810329a <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f810328b:	83 c0 01             	add    $0x1,%eax
f810328e:	0f b6 10             	movzbl (%eax),%edx
f8103291:	84 d2                	test   %dl,%dl
f8103293:	75 f2                	jne    f8103287 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f8103295:	b8 00 00 00 00       	mov    $0x0,%eax
}
f810329a:	5d                   	pop    %ebp
f810329b:	c3                   	ret    

f810329c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f810329c:	55                   	push   %ebp
f810329d:	89 e5                	mov    %esp,%ebp
f810329f:	8b 45 08             	mov    0x8(%ebp),%eax
f81032a2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f81032a6:	eb 03                	jmp    f81032ab <strfind+0xf>
f81032a8:	83 c0 01             	add    $0x1,%eax
f81032ab:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f81032ae:	38 ca                	cmp    %cl,%dl
f81032b0:	74 04                	je     f81032b6 <strfind+0x1a>
f81032b2:	84 d2                	test   %dl,%dl
f81032b4:	75 f2                	jne    f81032a8 <strfind+0xc>
			break;
	return (char *) s;
}
f81032b6:	5d                   	pop    %ebp
f81032b7:	c3                   	ret    

f81032b8 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f81032b8:	55                   	push   %ebp
f81032b9:	89 e5                	mov    %esp,%ebp
f81032bb:	57                   	push   %edi
f81032bc:	56                   	push   %esi
f81032bd:	53                   	push   %ebx
f81032be:	8b 7d 08             	mov    0x8(%ebp),%edi
f81032c1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f81032c4:	85 c9                	test   %ecx,%ecx
f81032c6:	74 36                	je     f81032fe <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f81032c8:	f7 c7 03 00 00 00    	test   $0x3,%edi
f81032ce:	75 28                	jne    f81032f8 <memset+0x40>
f81032d0:	f6 c1 03             	test   $0x3,%cl
f81032d3:	75 23                	jne    f81032f8 <memset+0x40>
		c &= 0xFF;
f81032d5:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f81032d9:	89 d3                	mov    %edx,%ebx
f81032db:	c1 e3 08             	shl    $0x8,%ebx
f81032de:	89 d6                	mov    %edx,%esi
f81032e0:	c1 e6 18             	shl    $0x18,%esi
f81032e3:	89 d0                	mov    %edx,%eax
f81032e5:	c1 e0 10             	shl    $0x10,%eax
f81032e8:	09 f0                	or     %esi,%eax
f81032ea:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f81032ec:	89 d8                	mov    %ebx,%eax
f81032ee:	09 d0                	or     %edx,%eax
f81032f0:	c1 e9 02             	shr    $0x2,%ecx
f81032f3:	fc                   	cld    
f81032f4:	f3 ab                	rep stos %eax,%es:(%edi)
f81032f6:	eb 06                	jmp    f81032fe <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f81032f8:	8b 45 0c             	mov    0xc(%ebp),%eax
f81032fb:	fc                   	cld    
f81032fc:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f81032fe:	89 f8                	mov    %edi,%eax
f8103300:	5b                   	pop    %ebx
f8103301:	5e                   	pop    %esi
f8103302:	5f                   	pop    %edi
f8103303:	5d                   	pop    %ebp
f8103304:	c3                   	ret    

f8103305 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f8103305:	55                   	push   %ebp
f8103306:	89 e5                	mov    %esp,%ebp
f8103308:	57                   	push   %edi
f8103309:	56                   	push   %esi
f810330a:	8b 45 08             	mov    0x8(%ebp),%eax
f810330d:	8b 75 0c             	mov    0xc(%ebp),%esi
f8103310:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f8103313:	39 c6                	cmp    %eax,%esi
f8103315:	73 35                	jae    f810334c <memmove+0x47>
f8103317:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f810331a:	39 d0                	cmp    %edx,%eax
f810331c:	73 2e                	jae    f810334c <memmove+0x47>
		s += n;
		d += n;
f810331e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f8103321:	89 d6                	mov    %edx,%esi
f8103323:	09 fe                	or     %edi,%esi
f8103325:	f7 c6 03 00 00 00    	test   $0x3,%esi
f810332b:	75 13                	jne    f8103340 <memmove+0x3b>
f810332d:	f6 c1 03             	test   $0x3,%cl
f8103330:	75 0e                	jne    f8103340 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f8103332:	83 ef 04             	sub    $0x4,%edi
f8103335:	8d 72 fc             	lea    -0x4(%edx),%esi
f8103338:	c1 e9 02             	shr    $0x2,%ecx
f810333b:	fd                   	std    
f810333c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f810333e:	eb 09                	jmp    f8103349 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f8103340:	83 ef 01             	sub    $0x1,%edi
f8103343:	8d 72 ff             	lea    -0x1(%edx),%esi
f8103346:	fd                   	std    
f8103347:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f8103349:	fc                   	cld    
f810334a:	eb 1d                	jmp    f8103369 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f810334c:	89 f2                	mov    %esi,%edx
f810334e:	09 c2                	or     %eax,%edx
f8103350:	f6 c2 03             	test   $0x3,%dl
f8103353:	75 0f                	jne    f8103364 <memmove+0x5f>
f8103355:	f6 c1 03             	test   $0x3,%cl
f8103358:	75 0a                	jne    f8103364 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f810335a:	c1 e9 02             	shr    $0x2,%ecx
f810335d:	89 c7                	mov    %eax,%edi
f810335f:	fc                   	cld    
f8103360:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f8103362:	eb 05                	jmp    f8103369 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f8103364:	89 c7                	mov    %eax,%edi
f8103366:	fc                   	cld    
f8103367:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f8103369:	5e                   	pop    %esi
f810336a:	5f                   	pop    %edi
f810336b:	5d                   	pop    %ebp
f810336c:	c3                   	ret    

f810336d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f810336d:	55                   	push   %ebp
f810336e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f8103370:	ff 75 10             	pushl  0x10(%ebp)
f8103373:	ff 75 0c             	pushl  0xc(%ebp)
f8103376:	ff 75 08             	pushl  0x8(%ebp)
f8103379:	e8 87 ff ff ff       	call   f8103305 <memmove>
}
f810337e:	c9                   	leave  
f810337f:	c3                   	ret    

f8103380 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f8103380:	55                   	push   %ebp
f8103381:	89 e5                	mov    %esp,%ebp
f8103383:	56                   	push   %esi
f8103384:	53                   	push   %ebx
f8103385:	8b 45 08             	mov    0x8(%ebp),%eax
f8103388:	8b 55 0c             	mov    0xc(%ebp),%edx
f810338b:	89 c6                	mov    %eax,%esi
f810338d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f8103390:	eb 1a                	jmp    f81033ac <memcmp+0x2c>
		if (*s1 != *s2)
f8103392:	0f b6 08             	movzbl (%eax),%ecx
f8103395:	0f b6 1a             	movzbl (%edx),%ebx
f8103398:	38 d9                	cmp    %bl,%cl
f810339a:	74 0a                	je     f81033a6 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f810339c:	0f b6 c1             	movzbl %cl,%eax
f810339f:	0f b6 db             	movzbl %bl,%ebx
f81033a2:	29 d8                	sub    %ebx,%eax
f81033a4:	eb 0f                	jmp    f81033b5 <memcmp+0x35>
		s1++, s2++;
f81033a6:	83 c0 01             	add    $0x1,%eax
f81033a9:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f81033ac:	39 f0                	cmp    %esi,%eax
f81033ae:	75 e2                	jne    f8103392 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f81033b0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f81033b5:	5b                   	pop    %ebx
f81033b6:	5e                   	pop    %esi
f81033b7:	5d                   	pop    %ebp
f81033b8:	c3                   	ret    

f81033b9 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f81033b9:	55                   	push   %ebp
f81033ba:	89 e5                	mov    %esp,%ebp
f81033bc:	53                   	push   %ebx
f81033bd:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f81033c0:	89 c1                	mov    %eax,%ecx
f81033c2:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f81033c5:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f81033c9:	eb 0a                	jmp    f81033d5 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f81033cb:	0f b6 10             	movzbl (%eax),%edx
f81033ce:	39 da                	cmp    %ebx,%edx
f81033d0:	74 07                	je     f81033d9 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f81033d2:	83 c0 01             	add    $0x1,%eax
f81033d5:	39 c8                	cmp    %ecx,%eax
f81033d7:	72 f2                	jb     f81033cb <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f81033d9:	5b                   	pop    %ebx
f81033da:	5d                   	pop    %ebp
f81033db:	c3                   	ret    

f81033dc <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f81033dc:	55                   	push   %ebp
f81033dd:	89 e5                	mov    %esp,%ebp
f81033df:	57                   	push   %edi
f81033e0:	56                   	push   %esi
f81033e1:	53                   	push   %ebx
f81033e2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f81033e5:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f81033e8:	eb 03                	jmp    f81033ed <strtol+0x11>
		s++;
f81033ea:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f81033ed:	0f b6 01             	movzbl (%ecx),%eax
f81033f0:	3c 20                	cmp    $0x20,%al
f81033f2:	74 f6                	je     f81033ea <strtol+0xe>
f81033f4:	3c 09                	cmp    $0x9,%al
f81033f6:	74 f2                	je     f81033ea <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f81033f8:	3c 2b                	cmp    $0x2b,%al
f81033fa:	75 0a                	jne    f8103406 <strtol+0x2a>
		s++;
f81033fc:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f81033ff:	bf 00 00 00 00       	mov    $0x0,%edi
f8103404:	eb 11                	jmp    f8103417 <strtol+0x3b>
f8103406:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f810340b:	3c 2d                	cmp    $0x2d,%al
f810340d:	75 08                	jne    f8103417 <strtol+0x3b>
		s++, neg = 1;
f810340f:	83 c1 01             	add    $0x1,%ecx
f8103412:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f8103417:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f810341d:	75 15                	jne    f8103434 <strtol+0x58>
f810341f:	80 39 30             	cmpb   $0x30,(%ecx)
f8103422:	75 10                	jne    f8103434 <strtol+0x58>
f8103424:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f8103428:	75 7c                	jne    f81034a6 <strtol+0xca>
		s += 2, base = 16;
f810342a:	83 c1 02             	add    $0x2,%ecx
f810342d:	bb 10 00 00 00       	mov    $0x10,%ebx
f8103432:	eb 16                	jmp    f810344a <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f8103434:	85 db                	test   %ebx,%ebx
f8103436:	75 12                	jne    f810344a <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f8103438:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f810343d:	80 39 30             	cmpb   $0x30,(%ecx)
f8103440:	75 08                	jne    f810344a <strtol+0x6e>
		s++, base = 8;
f8103442:	83 c1 01             	add    $0x1,%ecx
f8103445:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f810344a:	b8 00 00 00 00       	mov    $0x0,%eax
f810344f:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f8103452:	0f b6 11             	movzbl (%ecx),%edx
f8103455:	8d 72 d0             	lea    -0x30(%edx),%esi
f8103458:	89 f3                	mov    %esi,%ebx
f810345a:	80 fb 09             	cmp    $0x9,%bl
f810345d:	77 08                	ja     f8103467 <strtol+0x8b>
			dig = *s - '0';
f810345f:	0f be d2             	movsbl %dl,%edx
f8103462:	83 ea 30             	sub    $0x30,%edx
f8103465:	eb 22                	jmp    f8103489 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f8103467:	8d 72 9f             	lea    -0x61(%edx),%esi
f810346a:	89 f3                	mov    %esi,%ebx
f810346c:	80 fb 19             	cmp    $0x19,%bl
f810346f:	77 08                	ja     f8103479 <strtol+0x9d>
			dig = *s - 'a' + 10;
f8103471:	0f be d2             	movsbl %dl,%edx
f8103474:	83 ea 57             	sub    $0x57,%edx
f8103477:	eb 10                	jmp    f8103489 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f8103479:	8d 72 bf             	lea    -0x41(%edx),%esi
f810347c:	89 f3                	mov    %esi,%ebx
f810347e:	80 fb 19             	cmp    $0x19,%bl
f8103481:	77 16                	ja     f8103499 <strtol+0xbd>
			dig = *s - 'A' + 10;
f8103483:	0f be d2             	movsbl %dl,%edx
f8103486:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f8103489:	3b 55 10             	cmp    0x10(%ebp),%edx
f810348c:	7d 0b                	jge    f8103499 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f810348e:	83 c1 01             	add    $0x1,%ecx
f8103491:	0f af 45 10          	imul   0x10(%ebp),%eax
f8103495:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f8103497:	eb b9                	jmp    f8103452 <strtol+0x76>

	if (endptr)
f8103499:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f810349d:	74 0d                	je     f81034ac <strtol+0xd0>
		*endptr = (char *) s;
f810349f:	8b 75 0c             	mov    0xc(%ebp),%esi
f81034a2:	89 0e                	mov    %ecx,(%esi)
f81034a4:	eb 06                	jmp    f81034ac <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f81034a6:	85 db                	test   %ebx,%ebx
f81034a8:	74 98                	je     f8103442 <strtol+0x66>
f81034aa:	eb 9e                	jmp    f810344a <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f81034ac:	89 c2                	mov    %eax,%edx
f81034ae:	f7 da                	neg    %edx
f81034b0:	85 ff                	test   %edi,%edi
f81034b2:	0f 45 c2             	cmovne %edx,%eax
}
f81034b5:	5b                   	pop    %ebx
f81034b6:	5e                   	pop    %esi
f81034b7:	5f                   	pop    %edi
f81034b8:	5d                   	pop    %ebp
f81034b9:	c3                   	ret    
f81034ba:	66 90                	xchg   %ax,%ax
f81034bc:	66 90                	xchg   %ax,%ax
f81034be:	66 90                	xchg   %ax,%ax

f81034c0 <__udivdi3>:
f81034c0:	55                   	push   %ebp
f81034c1:	57                   	push   %edi
f81034c2:	56                   	push   %esi
f81034c3:	53                   	push   %ebx
f81034c4:	83 ec 1c             	sub    $0x1c,%esp
f81034c7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f81034cb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f81034cf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f81034d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f81034d7:	85 f6                	test   %esi,%esi
f81034d9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f81034dd:	89 ca                	mov    %ecx,%edx
f81034df:	89 f8                	mov    %edi,%eax
f81034e1:	75 3d                	jne    f8103520 <__udivdi3+0x60>
f81034e3:	39 cf                	cmp    %ecx,%edi
f81034e5:	0f 87 c5 00 00 00    	ja     f81035b0 <__udivdi3+0xf0>
f81034eb:	85 ff                	test   %edi,%edi
f81034ed:	89 fd                	mov    %edi,%ebp
f81034ef:	75 0b                	jne    f81034fc <__udivdi3+0x3c>
f81034f1:	b8 01 00 00 00       	mov    $0x1,%eax
f81034f6:	31 d2                	xor    %edx,%edx
f81034f8:	f7 f7                	div    %edi
f81034fa:	89 c5                	mov    %eax,%ebp
f81034fc:	89 c8                	mov    %ecx,%eax
f81034fe:	31 d2                	xor    %edx,%edx
f8103500:	f7 f5                	div    %ebp
f8103502:	89 c1                	mov    %eax,%ecx
f8103504:	89 d8                	mov    %ebx,%eax
f8103506:	89 cf                	mov    %ecx,%edi
f8103508:	f7 f5                	div    %ebp
f810350a:	89 c3                	mov    %eax,%ebx
f810350c:	89 d8                	mov    %ebx,%eax
f810350e:	89 fa                	mov    %edi,%edx
f8103510:	83 c4 1c             	add    $0x1c,%esp
f8103513:	5b                   	pop    %ebx
f8103514:	5e                   	pop    %esi
f8103515:	5f                   	pop    %edi
f8103516:	5d                   	pop    %ebp
f8103517:	c3                   	ret    
f8103518:	90                   	nop
f8103519:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f8103520:	39 ce                	cmp    %ecx,%esi
f8103522:	77 74                	ja     f8103598 <__udivdi3+0xd8>
f8103524:	0f bd fe             	bsr    %esi,%edi
f8103527:	83 f7 1f             	xor    $0x1f,%edi
f810352a:	0f 84 98 00 00 00    	je     f81035c8 <__udivdi3+0x108>
f8103530:	bb 20 00 00 00       	mov    $0x20,%ebx
f8103535:	89 f9                	mov    %edi,%ecx
f8103537:	89 c5                	mov    %eax,%ebp
f8103539:	29 fb                	sub    %edi,%ebx
f810353b:	d3 e6                	shl    %cl,%esi
f810353d:	89 d9                	mov    %ebx,%ecx
f810353f:	d3 ed                	shr    %cl,%ebp
f8103541:	89 f9                	mov    %edi,%ecx
f8103543:	d3 e0                	shl    %cl,%eax
f8103545:	09 ee                	or     %ebp,%esi
f8103547:	89 d9                	mov    %ebx,%ecx
f8103549:	89 44 24 0c          	mov    %eax,0xc(%esp)
f810354d:	89 d5                	mov    %edx,%ebp
f810354f:	8b 44 24 08          	mov    0x8(%esp),%eax
f8103553:	d3 ed                	shr    %cl,%ebp
f8103555:	89 f9                	mov    %edi,%ecx
f8103557:	d3 e2                	shl    %cl,%edx
f8103559:	89 d9                	mov    %ebx,%ecx
f810355b:	d3 e8                	shr    %cl,%eax
f810355d:	09 c2                	or     %eax,%edx
f810355f:	89 d0                	mov    %edx,%eax
f8103561:	89 ea                	mov    %ebp,%edx
f8103563:	f7 f6                	div    %esi
f8103565:	89 d5                	mov    %edx,%ebp
f8103567:	89 c3                	mov    %eax,%ebx
f8103569:	f7 64 24 0c          	mull   0xc(%esp)
f810356d:	39 d5                	cmp    %edx,%ebp
f810356f:	72 10                	jb     f8103581 <__udivdi3+0xc1>
f8103571:	8b 74 24 08          	mov    0x8(%esp),%esi
f8103575:	89 f9                	mov    %edi,%ecx
f8103577:	d3 e6                	shl    %cl,%esi
f8103579:	39 c6                	cmp    %eax,%esi
f810357b:	73 07                	jae    f8103584 <__udivdi3+0xc4>
f810357d:	39 d5                	cmp    %edx,%ebp
f810357f:	75 03                	jne    f8103584 <__udivdi3+0xc4>
f8103581:	83 eb 01             	sub    $0x1,%ebx
f8103584:	31 ff                	xor    %edi,%edi
f8103586:	89 d8                	mov    %ebx,%eax
f8103588:	89 fa                	mov    %edi,%edx
f810358a:	83 c4 1c             	add    $0x1c,%esp
f810358d:	5b                   	pop    %ebx
f810358e:	5e                   	pop    %esi
f810358f:	5f                   	pop    %edi
f8103590:	5d                   	pop    %ebp
f8103591:	c3                   	ret    
f8103592:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f8103598:	31 ff                	xor    %edi,%edi
f810359a:	31 db                	xor    %ebx,%ebx
f810359c:	89 d8                	mov    %ebx,%eax
f810359e:	89 fa                	mov    %edi,%edx
f81035a0:	83 c4 1c             	add    $0x1c,%esp
f81035a3:	5b                   	pop    %ebx
f81035a4:	5e                   	pop    %esi
f81035a5:	5f                   	pop    %edi
f81035a6:	5d                   	pop    %ebp
f81035a7:	c3                   	ret    
f81035a8:	90                   	nop
f81035a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f81035b0:	89 d8                	mov    %ebx,%eax
f81035b2:	f7 f7                	div    %edi
f81035b4:	31 ff                	xor    %edi,%edi
f81035b6:	89 c3                	mov    %eax,%ebx
f81035b8:	89 d8                	mov    %ebx,%eax
f81035ba:	89 fa                	mov    %edi,%edx
f81035bc:	83 c4 1c             	add    $0x1c,%esp
f81035bf:	5b                   	pop    %ebx
f81035c0:	5e                   	pop    %esi
f81035c1:	5f                   	pop    %edi
f81035c2:	5d                   	pop    %ebp
f81035c3:	c3                   	ret    
f81035c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f81035c8:	39 ce                	cmp    %ecx,%esi
f81035ca:	72 0c                	jb     f81035d8 <__udivdi3+0x118>
f81035cc:	31 db                	xor    %ebx,%ebx
f81035ce:	3b 44 24 08          	cmp    0x8(%esp),%eax
f81035d2:	0f 87 34 ff ff ff    	ja     f810350c <__udivdi3+0x4c>
f81035d8:	bb 01 00 00 00       	mov    $0x1,%ebx
f81035dd:	e9 2a ff ff ff       	jmp    f810350c <__udivdi3+0x4c>
f81035e2:	66 90                	xchg   %ax,%ax
f81035e4:	66 90                	xchg   %ax,%ax
f81035e6:	66 90                	xchg   %ax,%ax
f81035e8:	66 90                	xchg   %ax,%ax
f81035ea:	66 90                	xchg   %ax,%ax
f81035ec:	66 90                	xchg   %ax,%ax
f81035ee:	66 90                	xchg   %ax,%ax

f81035f0 <__umoddi3>:
f81035f0:	55                   	push   %ebp
f81035f1:	57                   	push   %edi
f81035f2:	56                   	push   %esi
f81035f3:	53                   	push   %ebx
f81035f4:	83 ec 1c             	sub    $0x1c,%esp
f81035f7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f81035fb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f81035ff:	8b 74 24 34          	mov    0x34(%esp),%esi
f8103603:	8b 7c 24 38          	mov    0x38(%esp),%edi
f8103607:	85 d2                	test   %edx,%edx
f8103609:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f810360d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f8103611:	89 f3                	mov    %esi,%ebx
f8103613:	89 3c 24             	mov    %edi,(%esp)
f8103616:	89 74 24 04          	mov    %esi,0x4(%esp)
f810361a:	75 1c                	jne    f8103638 <__umoddi3+0x48>
f810361c:	39 f7                	cmp    %esi,%edi
f810361e:	76 50                	jbe    f8103670 <__umoddi3+0x80>
f8103620:	89 c8                	mov    %ecx,%eax
f8103622:	89 f2                	mov    %esi,%edx
f8103624:	f7 f7                	div    %edi
f8103626:	89 d0                	mov    %edx,%eax
f8103628:	31 d2                	xor    %edx,%edx
f810362a:	83 c4 1c             	add    $0x1c,%esp
f810362d:	5b                   	pop    %ebx
f810362e:	5e                   	pop    %esi
f810362f:	5f                   	pop    %edi
f8103630:	5d                   	pop    %ebp
f8103631:	c3                   	ret    
f8103632:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f8103638:	39 f2                	cmp    %esi,%edx
f810363a:	89 d0                	mov    %edx,%eax
f810363c:	77 52                	ja     f8103690 <__umoddi3+0xa0>
f810363e:	0f bd ea             	bsr    %edx,%ebp
f8103641:	83 f5 1f             	xor    $0x1f,%ebp
f8103644:	75 5a                	jne    f81036a0 <__umoddi3+0xb0>
f8103646:	3b 54 24 04          	cmp    0x4(%esp),%edx
f810364a:	0f 82 e0 00 00 00    	jb     f8103730 <__umoddi3+0x140>
f8103650:	39 0c 24             	cmp    %ecx,(%esp)
f8103653:	0f 86 d7 00 00 00    	jbe    f8103730 <__umoddi3+0x140>
f8103659:	8b 44 24 08          	mov    0x8(%esp),%eax
f810365d:	8b 54 24 04          	mov    0x4(%esp),%edx
f8103661:	83 c4 1c             	add    $0x1c,%esp
f8103664:	5b                   	pop    %ebx
f8103665:	5e                   	pop    %esi
f8103666:	5f                   	pop    %edi
f8103667:	5d                   	pop    %ebp
f8103668:	c3                   	ret    
f8103669:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f8103670:	85 ff                	test   %edi,%edi
f8103672:	89 fd                	mov    %edi,%ebp
f8103674:	75 0b                	jne    f8103681 <__umoddi3+0x91>
f8103676:	b8 01 00 00 00       	mov    $0x1,%eax
f810367b:	31 d2                	xor    %edx,%edx
f810367d:	f7 f7                	div    %edi
f810367f:	89 c5                	mov    %eax,%ebp
f8103681:	89 f0                	mov    %esi,%eax
f8103683:	31 d2                	xor    %edx,%edx
f8103685:	f7 f5                	div    %ebp
f8103687:	89 c8                	mov    %ecx,%eax
f8103689:	f7 f5                	div    %ebp
f810368b:	89 d0                	mov    %edx,%eax
f810368d:	eb 99                	jmp    f8103628 <__umoddi3+0x38>
f810368f:	90                   	nop
f8103690:	89 c8                	mov    %ecx,%eax
f8103692:	89 f2                	mov    %esi,%edx
f8103694:	83 c4 1c             	add    $0x1c,%esp
f8103697:	5b                   	pop    %ebx
f8103698:	5e                   	pop    %esi
f8103699:	5f                   	pop    %edi
f810369a:	5d                   	pop    %ebp
f810369b:	c3                   	ret    
f810369c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f81036a0:	8b 34 24             	mov    (%esp),%esi
f81036a3:	bf 20 00 00 00       	mov    $0x20,%edi
f81036a8:	89 e9                	mov    %ebp,%ecx
f81036aa:	29 ef                	sub    %ebp,%edi
f81036ac:	d3 e0                	shl    %cl,%eax
f81036ae:	89 f9                	mov    %edi,%ecx
f81036b0:	89 f2                	mov    %esi,%edx
f81036b2:	d3 ea                	shr    %cl,%edx
f81036b4:	89 e9                	mov    %ebp,%ecx
f81036b6:	09 c2                	or     %eax,%edx
f81036b8:	89 d8                	mov    %ebx,%eax
f81036ba:	89 14 24             	mov    %edx,(%esp)
f81036bd:	89 f2                	mov    %esi,%edx
f81036bf:	d3 e2                	shl    %cl,%edx
f81036c1:	89 f9                	mov    %edi,%ecx
f81036c3:	89 54 24 04          	mov    %edx,0x4(%esp)
f81036c7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f81036cb:	d3 e8                	shr    %cl,%eax
f81036cd:	89 e9                	mov    %ebp,%ecx
f81036cf:	89 c6                	mov    %eax,%esi
f81036d1:	d3 e3                	shl    %cl,%ebx
f81036d3:	89 f9                	mov    %edi,%ecx
f81036d5:	89 d0                	mov    %edx,%eax
f81036d7:	d3 e8                	shr    %cl,%eax
f81036d9:	89 e9                	mov    %ebp,%ecx
f81036db:	09 d8                	or     %ebx,%eax
f81036dd:	89 d3                	mov    %edx,%ebx
f81036df:	89 f2                	mov    %esi,%edx
f81036e1:	f7 34 24             	divl   (%esp)
f81036e4:	89 d6                	mov    %edx,%esi
f81036e6:	d3 e3                	shl    %cl,%ebx
f81036e8:	f7 64 24 04          	mull   0x4(%esp)
f81036ec:	39 d6                	cmp    %edx,%esi
f81036ee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f81036f2:	89 d1                	mov    %edx,%ecx
f81036f4:	89 c3                	mov    %eax,%ebx
f81036f6:	72 08                	jb     f8103700 <__umoddi3+0x110>
f81036f8:	75 11                	jne    f810370b <__umoddi3+0x11b>
f81036fa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f81036fe:	73 0b                	jae    f810370b <__umoddi3+0x11b>
f8103700:	2b 44 24 04          	sub    0x4(%esp),%eax
f8103704:	1b 14 24             	sbb    (%esp),%edx
f8103707:	89 d1                	mov    %edx,%ecx
f8103709:	89 c3                	mov    %eax,%ebx
f810370b:	8b 54 24 08          	mov    0x8(%esp),%edx
f810370f:	29 da                	sub    %ebx,%edx
f8103711:	19 ce                	sbb    %ecx,%esi
f8103713:	89 f9                	mov    %edi,%ecx
f8103715:	89 f0                	mov    %esi,%eax
f8103717:	d3 e0                	shl    %cl,%eax
f8103719:	89 e9                	mov    %ebp,%ecx
f810371b:	d3 ea                	shr    %cl,%edx
f810371d:	89 e9                	mov    %ebp,%ecx
f810371f:	d3 ee                	shr    %cl,%esi
f8103721:	09 d0                	or     %edx,%eax
f8103723:	89 f2                	mov    %esi,%edx
f8103725:	83 c4 1c             	add    $0x1c,%esp
f8103728:	5b                   	pop    %ebx
f8103729:	5e                   	pop    %esi
f810372a:	5f                   	pop    %edi
f810372b:	5d                   	pop    %ebp
f810372c:	c3                   	ret    
f810372d:	8d 76 00             	lea    0x0(%esi),%esi
f8103730:	29 f9                	sub    %edi,%ecx
f8103732:	19 d6                	sbb    %edx,%esi
f8103734:	89 74 24 04          	mov    %esi,0x4(%esp)
f8103738:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f810373c:	e9 18 ff ff ff       	jmp    f8103659 <__umoddi3+0x69>
