#include "memory.h"

void Memory::HandleRequest(uint32_t addr, int bytes, int read,
                           char* storage, int &hit, int &time) {
    hit = 1;
	stats_.access_counter += 1;
    time = latency_.hit_latency;
    stats_.access_time += time;
}

