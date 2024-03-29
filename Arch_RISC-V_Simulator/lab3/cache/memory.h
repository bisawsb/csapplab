#ifndef CACHE_MEMORY_H_
#define CACHE_MEMORY_H_

#include <stdint.h>
#include "storage.h"

class Memory: public Storage {
public:
    Memory() {}
    ~Memory() {}

  // Main access process
    void HandleRequest(uint32_t addr, int bytes, int read,
                       char* storage, int &hit, int &time);

private:
  // Memory implement

    DISALLOW_COPY_AND_ASSIGN(Memory);
};

#endif //CACHE_MEMORY_H_ 
