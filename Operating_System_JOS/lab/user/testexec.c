//
// Created by Sirui Lu on 2019-05-26.
//
#include <inc/lib.h>

void umain(int argc, char **argv) {
	int r;
	const char *buff[] = {NULL};
	cprintf("before\n");
	r = exec("hello", buff);
	cprintf("after\n");
	cprintf("%d\n", r);
	panic("Should not come here");
}