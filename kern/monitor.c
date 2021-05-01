// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>
#include <inc/mmu.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <kern/pmap.h>



#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "showpagemappings", "Display page mappings", mon_showpagemappings }
	// { "dumpmem", "Display memory dump", mon_dumpmem} ,
	// { "pageperms", "Display/change page permissions", mon_pageperms }
};

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	return 0;
}

int 
mon_showpagemappings(int argc, char **argv, struct Trapframe *tf)
{
	// assume hex addresses are clean (no invalid input, no 0x...)
	uintptr_t va1, va2;

	long virtualadd1;
	char *dummyptr1;

	virtualadd1 = strtol(argv[1], &dummyptr1, 16);

	long virtualadd2;
	char *dummyptr2;

	virtualadd2 = strtol(argv[2], &dummyptr2, 16);

	va1 = (uintptr_t) virtualadd1;
	va2 = (uintptr_t) virtualadd2;

	cprintf("You inputted: %p\n", va1);
	cprintf("You inputted: %p\n", va2);

	cprintf("You inputted: %p\n", virtualadd1);
	cprintf("You inputted: %p\n", virtualadd2);

	// Declare a page table entry
	pte_t *pgtentry;
	uintptr_t i;
	for (i = va1; i <= va2; i += PGSIZE)
	{
		pgtentry = pgdir_walk(kern_pgdir, (const void *)i, 0);
		if (pgtentry != 0)
		{
			cprintf("Virtual address %p => maps to => Physical Address %p\n", PTE_ADDR(pgtentry));
		}
		else
		{
			cprintf("This address is not mapped\n");
		}	

	}

	return 0;
}

// int
// mon_dumpmem()
// {
	

// }

// int 
// mon_pageperms()
// {

// }


/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");
	// Nikhil and I couldn't agree on whether chars and ints have same size
	//cprintf("%d %d\n", sizeof(char), sizeof(int)); 
	// Nikhil won lol


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
