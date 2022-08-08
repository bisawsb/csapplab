#include "stdio.h"
#include "cache.h"
#include "memory.h"
#include "def.h"

int main(void) {

    Memory m;
    Cache l1;
	Cache l2;
    l1.SetLower(&l2);
	l2.SetLower(&m);

    StorageStats s;
    m.SetStats(s);
    l1.SetStats(s);

    StorageLatency ml;
    ml.hit_latency = 50;
    m.SetLatency(ml);

    StorageLatency ll;
	CacheConfig lc;
	ll.hit_latency = 3;
	lc.size = L1_BLOCK_SIZE;
	lc.associativity = L1_ASSOCIATIVITY;
	lc.set_num = L1_SET;
	lc.write_through = WRITE_THROUGH;
	lc.write_allocate = WRITE_ALLOCATE;
	lc.block_bits = L1_BLOCK_SIZE_BITS;
	lc.set_bits = L1_SET_BITS;
	lc.strategy = LRU;
    
    l1.SetLatency(ll);
	l1.SetConfig(lc);

	StorageLatency ll2;
	CacheConfig lc2;
	ll2.hit_latency = 4;
	lc2.size = L2_BLOCK_SIZE;
	lc2.associativity = L2_ASSOCIATIVITY;
	lc2.set_num = L2_SET;
	lc2.write_through = WRITE_THROUGH;
	lc2.write_allocate = WRITE_ALLOCATE;
	lc2.block_bits = L2_BLOCK_SIZE_BITS;
	lc2.set_bits = L2_SET_BITS;
	lc2.strategy = LRU;
    
    l2.SetLatency(ll2);
	l2.SetConfig(lc2);

	freopen("../trace2017/01-mcf-gem5-xcg.trace","r",stdin);
	char op;
	uint32_t addr;

	while(scanf("%c %x", &op, &addr) != EOF)
	{
		int hit, time, read = 0;
		char* storage;
		if(op == 'r') read = 1;
		l1.HandleRequest(addr, 1, read, storage, hit, time);
		//printf("Request access time: %dns\n", time);
	}

	l1.GetStats(s);
	int t = s.access_time;
	printf("Total L1 access time: %dns\n", s.access_time);
	float miss_rate = (float)s.miss_num/s.access_counter*100;
	printf("L1 Miss rate: %.2f% (%d/%d)\n", miss_rate, s.miss_num, s.access_counter);

	l2.GetStats(s);
	printf("Total L2 access time: %dns\n", s.access_time);
	miss_rate = (float)s.miss_num/s.access_counter*100;
	printf("L2 Miss rate: %.2f% (%d/%d)\n", miss_rate, s.miss_num, s.access_counter);

	m.GetStats(s);
	printf("Total Memory access time: %dns\n", s.access_time);

	return 0;

}
