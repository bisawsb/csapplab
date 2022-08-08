#ifndef CACHE_CACHE_H_
#define CACHE_CACHE_H_

#include <stdio.h>
#include <stdint.h>
#include <cstdlib>
#include "storage.h"
#include "def.h"
#include <list>

using namespace std;

typedef struct CacheItem_ {
	CacheItem_(uint32_t t): tag(t) {}
	uint32_t tag;
	int dirty = 0;
	char *block;
} CacheItem;
typedef list<CacheItem> CACHE_LIST;

typedef struct TagFinder_ {
	TagFinder_(uint32_t t): tag(t) {}
	bool operator() (const CacheItem cc) {
		return (tag == cc.tag);
	}
	uint32_t tag;
} TagFinder;

typedef struct CacheConfig_ {
    int size;
    int associativity;
    int set_num; // Number of cache sets
	int block_bits;
	int set_bits;
    int write_through; // 0|1 for back|through
    int write_allocate; // 0|1 for no-alc|alc
	REPLACE_STRA strategy;
} CacheConfig;

class Cache: public Storage {

public:
    Cache() {}
    ~Cache() {}

  // Sets & Gets
    void SetConfig(CacheConfig cc);
    void GetConfig(CacheConfig &cc) { cc = config_; };
    void SetLower(Storage *ll) { lower_ = ll; }
  // Main access process
    void HandleRequest(uint32_t addr, int bytes, int read,
                       char* storage, int &hit, int &time);

	CACHE_LIST *cache_set;
	int *setItemNum;

private:
  // Bypassing 
    int BypassDecision();
  // Prefetching
    int PrefetchDecision();
    void PrefetchAlgorithm();

    CacheConfig config_;
    Storage *lower_;
    DISALLOW_COPY_AND_ASSIGN(Cache);

};

#endif //CACHE_CACHE_H_ 
