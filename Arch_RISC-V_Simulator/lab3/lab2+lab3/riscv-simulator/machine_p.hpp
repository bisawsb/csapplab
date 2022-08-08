#ifndef MACHINE_PIPE_HEADER
#define MACHINE_PIPE_HEADER

#include "riscvISA.hpp"
#include "config.hpp"
#include "storage.h"
#include "cache.h"
#include <map>
#include <queue>
#include <string>
#include <stdint.h>

extern char *pred_str[30];

enum PRED_TYPE
{
	ALWAYS_TAKEN, ALWAYS_NOT_TAKEN, BIT1_PRED, BIT2_PRED
};

#define ZeroReg             0
#define SPReg               2
#define A0Reg               10
#define A1Reg               11
#define A7Reg               17
#define PCReg               32
#define P_PCReg             33
#define E_ValEReg           34
#define E_ValCReg           35  
#define M_ValEReg           36 
#define M_ValCReg           37

#define RegNum              40
#define PageSize            4096
#define PhysicalPageNum     64000
#define PhysicalMemSize     PhysicalPageNum * PageSize
#define PredCacheSize	    1024

#define StackTopPtr         0x08000000

class Predictor
{
public:
	PRED_TYPE mode;
	uint64_t *pred_state;

	Predictor(PRED_TYPE mode);
	~Predictor();
	void Init();
	bool Predict(uint64_t addr);
	void Update(uint64_t addr, bool real);
	char* Name(){ return pred_str[mode]; }
};

class PipelineRegister
{
public:
    Instruction inst;
    bool bubble, stall, pred_j;
    int64_t val_e, val_c; 

    PipelineRegister()
    {
        bubble = true;
        stall  = false;
    }
};

class Memory: public Storage {
public:
    Memory() {}
    ~Memory() {}

    void HandleRequest(uint32_t addr, int bytes, int read,
                       char* storage, int &hit, int &time)
	{
		hit = 1;
		stats_.access_counter += 1;
		time = latency_.hit_latency;
		stats_.access_time += time;
	}

};

class Machine 
{
public:
    Machine(PRED_TYPE pred_mode, const char *file);
    ~Machine();

    int64_t ReadReg(int rid)            { return reg[rid]; }
    void WriteReg(int rid, int64_t val) { reg[rid] = val; }
    void PrintReg(FILE *fout = NULL);	
    bool ReadMem(uint64_t addr, int size, void *value);
    bool WriteMem(uint64_t addr, int size, uint64_t value);

    int Fetch();
    int Decode();
    int Execute();
    int MemoryAccess();
    int WriteBack();
    void UpdatePipeline();

    void Run();
    void Status(FILE *fout = NULL);
    void SingleStepDebug();
    int64_t reg[RegNum];
	uint8_t *mem;

    PipelineRegister F_reg, D_reg, E_reg, M_reg, W_reg;
    PipelineRegister f_reg, d_reg, e_reg, m_reg;

    Predictor *predictor;
	Memory vm;
    Cache i_cache;
	Cache d_cache;
	Cache l2;
	Cache llc;

    Config cfg;

    bool singleStep;
    int cycCount;
    int cpuCount;
    int instCount;
    double runTime;

    int loadHzdCount;
    int ctrlHzdCount;
    int totalBranch;
    int ecallStlCount;
    int jalrStlCount;
};

void singleStepP();

#endif
