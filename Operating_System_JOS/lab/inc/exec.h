//
// Created by Sirui Lu on 2019-05-26.
//

#ifndef JOS_EXEC_H
#define JOS_EXEC_H


#include <inc/types.h>

struct pmnode {
	uintptr_t from;
	uintptr_t to;
	int perm;
	struct pmnode *next;
};

#endif // JOS_EXEC_H
