/* See COPYRIGHT for copyright information. */

#ifndef JOS_KERN_PMAP_H
#define JOS_KERN_PMAP_H
#ifndef JOS_KERNEL
# error "This is a JOS kernel header; user programs should not #include it"
#endif

#include <inc/memlayout.h>
#include <inc/assert.h>

extern char bootstacktop[], bootstack[];

extern struct PageInfo *pages;
extern size_t npages;

// Soham's Superpages
extern struct PageInfo *hpages;
extern size_t hnpages;

extern pde_t *kern_pgdir;


/* This macro takes a kernel virtual address -- an address that points above
 * KERNBASE, where the machine's maximum 256MB of physical memory is mapped --
 * and returns the corresponding physical address.  It panics if you pass it a
 * non-kernel virtual address.
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
}

/* This macro takes a physical address and returns the corresponding kernel
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	//cprintf("kaddr: %p\n", pa);
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
}

#define HKADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_hkaddr(const char *file, int line, physaddr_t pa)
{
	//cprintf("kaddr: %p\n", pa);
	if (HPGNUM(pa) >= hnpages)
		_panic(file, line, "HKADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
}

enum {
	// For page_alloc, zero the returned physical page.
	ALLOC_ZERO = 1<<0,
};

void	mem_init(void);

void	page_init(void);
struct PageInfo *page_alloc(int alloc_flags);
struct PageInfo *hpage_alloc(int alloc_flags);
void	page_free(struct PageInfo *pp);
void 	hpage_free(struct PageInfo *pp);
int	page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm);
int hpage_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm);
void	page_remove(pde_t *pgdir, void *va);
void	hpage_remove(pde_t *pgdir, void *va);
struct PageInfo *page_lookup(pde_t *pgdir, void *va, pte_t **pte_store);
struct PageInfo *page_lookup(pde_t *pgdir, void *va, pte_t **pte_store);
void	page_decref(struct PageInfo *pp);
void 	hpage_decref(struct PageInfo *pp);

void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//cprintf("page2pa: %p - %p = %p <<(12) %p\n", pp, pages, pp-pages, (pp-pages) <<PGSHIFT);
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
}

static inline struct PageInfo*
pa2hpage(physaddr_t pa)
{
	if (HPGNUM(pa) >= hnpages)
		panic("pa2hpage called with invalid pa");
	return &hpages[HPGNUM(pa)];
}

// doesn't work because pgdir is not defined here
// static inline struct PageInfo*
// hpa2page(physaddr_t pa)
// {
// 	return (&pages - 1)[HPGOFF(pa)];
// }

static inline physaddr_t
hpage2pa(struct PageInfo *pp){
	return (pp - pages) << PGSHIFT;
}

static inline void*
hpage2kva(struct PageInfo *pp){
	return HKADDR(hpage2pa(pp));
}

static inline void*
page2kva(struct PageInfo *pp)
{
	//cprintf("page2kva: %p\n", pp);
	return KADDR(page2pa(pp));
}

pte_t *pgdir_walk(pde_t *pgdir, const void *va, int create);

#endif /* !JOS_KERN_PMAP_H */
