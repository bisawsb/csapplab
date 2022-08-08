#include "cache.h"
#include <algorithm>
#include <string.h>

void Cache::SetConfig(CacheConfig cc){
	config_ = cc;
	cache_set = new CACHE_LIST [config_.set_num];
	setItemNum = new int[config_.set_num];
	memset(setItemNum, 0, sizeof(setItemNum));
}

void Cache::HandleRequest(uint32_t addr, int bytes, int read,
                          char* storage, int &hit, int &time) {

	stats_.access_counter++;
    hit = 0;
    time = 0;
	CACHE_LIST::iterator replace;
	uint32_t tag = addr >> (config_.set_bits + config_.block_bits);
	uint32_t set_n = (addr >> config_.block_bits) - (tag << config_.set_bits);

    // Bypass?
    if (!BypassDecision()) {

		if ( (addr+bytes) > (((addr>>config_.block_bits)+1)<<config_.block_bits) ) {
			printf("Address out of block bound!\n");
			exit(-1);
		}

		CACHE_LIST::iterator iter = find_if(cache_set[set_n].begin(), 
											cache_set[set_n].end(), TagFinder(tag));
		time += latency_.hit_latency;
        stats_.access_time += time;
	//Miss
		if (iter == cache_set[set_n].end()) {
			stats_.miss_num++;
		//Set is not full
			if(setItemNum[set_n] < config_.associativity){
				CacheItem new_block = CacheItem(tag);
				cache_set[set_n].push_back(new_block);
				replace = cache_set[set_n].end();
				setItemNum[set_n]++;
			}
    	// Choose victim
			else
            	replace = cache_set[set_n].begin();
        } 
	//Hit
		else {
			if(read == 0) { 
			//Write through
				if(config_.write_through == 1) {
					int lower_hit, lower_time;
       			    lower_->HandleRequest(addr, bytes, read, storage,
                              			  lower_hit, lower_time);
					time += lower_time;
				}
			//Write back
				else {
					iter->dirty = 1;
				}
			}
			if(config_.strategy == LRU) {
				CacheItem c = (*iter);
				cache_set[set_n].erase(iter);
				cache_set[set_n].push_back(c);
			}
            hit = 1;	
            return;
        }
    }
    // Prefetch?
    if (PrefetchDecision()) {
        PrefetchAlgorithm();
    } 
	else {

		// Fetch from lower layer
        int lower_hit, lower_time;
        lower_->HandleRequest(addr, bytes, read, storage, lower_hit, lower_time);
		hit = 0;
        time += lower_time;
		stats_.fetch_num++;

		if(read==0 && config_.write_allocate == 0)
			return;

		if(replace->dirty == 1 && config_.write_through == 0){
			int lower_hit, lower_time;
			uint32_t addr_ = (((replace->tag)<<config_.set_bits)+set_n) << config_.block_bits;
       	    lower_->HandleRequest(addr_, config_.size, 0, replace->block,
                                  lower_hit, lower_time);
			time += lower_time;
		}
		replace->tag = tag;
		replace->dirty = 0;
		if(config_.strategy == FIFO || config_.strategy == LRU){
			CacheItem r = (*replace);
			cache_set[set_n].pop_front();
			cache_set[set_n].push_back(r);
		}
        
    }

}

int Cache::BypassDecision() {
    return FALSE;
}

int Cache::PrefetchDecision() {
    return FALSE;
}

void Cache::PrefetchAlgorithm() {
}

