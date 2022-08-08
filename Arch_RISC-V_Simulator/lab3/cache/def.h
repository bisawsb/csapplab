#ifndef CACHE_DEF_H_
#define CACHE_DEF_H_

#define TRUE 1
#define FALSE 0

#define L1_BLOCK_SIZE 256
#define L1_BLOCK_SIZE_BITS 8
#define L1_ASSOCIATIVITY 2
#define L1_SET 512
#define L1_SET_BITS 9

#define L2_BLOCK_SIZE 1024
#define L2_BLOCK_SIZE_BITS 10
#define L2_ASSOCIATIVITY 2
#define L2_SET 512
#define L2_SET_BITS 9

#define WRITE_THROUGH 0
#define WRITE_ALLOCATE 1

enum REPLACE_STRA
{ 
	RANDOM, FIFO, LRU
};

#endif //CACHE_DEF_H_
