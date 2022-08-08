//
// Created by Sirui Lu on 2019-05-26.
//

#include <inc/exec.h>
#include <inc/lib.h>
#include <inc/elf.h>

static void *utemp2ustack(void *addr, uintptr_t *base) {
	return addr + (USTACKTOP - PGSIZE) - *base;
}

static int MAX_NODE;
static struct pmnode *nodes;
static int free_pos = 0;

static int add_node(struct pmnode **pmlist, uintptr_t from, uintptr_t to, int perm) {
	if (free_pos >= MAX_NODE)
		return -E_NO_MEM;
	struct pmnode *node = &nodes[free_pos++];
	node->from = from;
	node->to = to;
	node->perm = perm;
	node->next = *pmlist;
	*pmlist = node;
	return 0;
}

static void free_list(struct pmnode **pmlist) {
	struct pmnode *node = *pmlist;
	while (node != NULL) {
		if (sys_page_unmap(0, (void*)node->from) < 0)
			panic("Failed to clean up");
		node = node->next;
	}
	sys_page_unmap(0, UTEMP);
}

static int alloc_nodes() {
	int r;
	if ((r = sys_page_alloc(0, UTEMP, PTE_P | PTE_U | PTE_W)) < 0)
		return r;
	nodes = (struct pmnode*)UTEMP;
	free_pos = 0;
	MAX_NODE = PGSIZE / sizeof(struct pmnode);
	return 0;
}

static int list_len(struct pmnode **pmlist) {
	struct pmnode *node = *pmlist;
	int i = 0;
	while (node != NULL) {
		++i;
		node = node->next;
	}
	return i;
}

static int exec_init_stack(const char **argv, uintptr_t *esp, uintptr_t *base, struct pmnode **pmlist) {
	int argc = 0;
	int argvsize = 0;
	int r;
	for (; argv[argc] != NULL; ++argc)
		argvsize += strlen(argv[argc]) + 1;
	char *strings = (char *) *base + PGSIZE - argvsize;
	uintptr_t *argvpos = (uintptr_t *) (ROUNDDOWN(strings, 4) - 4 * (argc + 1));

	if ((uintptr_t) (argvpos - 2) < *base)
		return -E_NO_MEM;

	if ((r = sys_page_alloc(0, (void *) *base, PTE_P | PTE_U | PTE_W)) < 0)
		return r;
	for (int i = 0; i < argc; ++i) {
		argvpos[i] = (uintptr_t) utemp2ustack(strings, base);
		strcpy(strings, argv[i]);
		strings += strlen(argv[i]) + 1;
	}

	argvpos[argc] = 0;
	argvpos[-1] = (uintptr_t) utemp2ustack(argvpos, base);
	argvpos[-2] = argc;

	*esp = (uintptr_t) utemp2ustack(argvpos - 2, base);
	if ((r = add_node(pmlist, *base, USTACKTOP - PGSIZE, PTE_P | PTE_U | PTE_W)))
		return r;
	*base += PGSIZE;
	return 0;
}

static int
exec_map_segment(uintptr_t *base, uintptr_t va, size_t memsz, int fd, size_t filesz, off_t fileoffset, int perm,
				 struct pmnode **pmlist) {
	int pgoff;
	int r;
	if ((pgoff = PGOFF(va))) {
		va -= pgoff;
		memsz += pgoff;
		filesz += pgoff;
		fileoffset -= pgoff;
	}
	for (int i = 0; i < memsz; i += PGSIZE) {
		if (i >= filesz) {
			if ((r = sys_page_alloc(0, (void *) *base, perm)) < 0)
				return r;
			if ((r = add_node(pmlist, *base, va + i, perm)) < 0)
				return r;
			*base += PGSIZE;
		} else {
			if ((r = sys_page_alloc(0, (void*)*base, PTE_P | PTE_U | PTE_W)) < 0)
				return r;
			if ((r = seek(fd, fileoffset + i)) < 0)
				return r;
			if ((r = readn(fd, (void*)*base, MIN(PGSIZE, filesz - i))) < 0)
				return r;
			if ((r = add_node(pmlist, *base, va + i, perm)) < 0)
				return r;
			*base += PGSIZE;
		}
	}
	return 0;
}

int exec(const char *prog, const char **argv) {
	unsigned char elf_buf[512];
	int fd, r;
	struct Elf *elf;
	struct Proghdr *ph;
	int perm;

	struct pmnode *pmlist = NULL;

	if ((r = open(prog, O_RDONLY)) < 0)
		return r;
	fd = r;
	elf = (struct Elf*)elf_buf;
	if (readn(fd, elf_buf, sizeof(elf_buf)) != sizeof(elf_buf) || elf->e_magic != ELF_MAGIC) {
		close(fd);
		return -E_NOT_EXEC;
	}

	if ((r =alloc_nodes()) < 0)
		return r;

	uintptr_t base = (uintptr_t)(UTEMP + PGSIZE);
	uintptr_t esp;

	if ((r = exec_init_stack(argv, &esp, &base, &pmlist)) < 0) {
		close(fd);
		free_list(&pmlist);
		return r;
	}

	ph = (struct Proghdr*)(elf_buf + elf->e_phoff);
	for (int i = 0; i < elf->e_phnum; ++i, ++ph) {
		if (ph->p_type != ELF_PROG_LOAD)
			continue;
		perm = PTE_P | PTE_U;
		if (ph->p_flags & ELF_PROG_FLAG_WRITE)
			perm |= PTE_W;
		if ((r = exec_map_segment(&base, ph->p_va, ph->p_memsz, fd, ph->p_filesz, ph->p_offset, perm, &pmlist)) < 0) {
			close(fd);
			free_list(&pmlist);
			return r;
		}
	}
	close(fd);
	sys_do_exec(&pmlist, elf->e_entry);
	free_list(&pmlist);
	return 0;

}

