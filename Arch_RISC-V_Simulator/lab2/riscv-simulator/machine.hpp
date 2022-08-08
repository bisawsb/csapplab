#ifndef MACHINE_HEADER
#define MACHINE_HEADER

#include "riscvISA.hpp"
#include <map>
#include <queue>
#include <string>
#include <stdint.h>

namespace ns1{

#define SPReg               2
#define A0Reg               10
#define A1Reg               11
#define A7Reg               17
#define PCReg               32
#define E_ValEReg           34
#define E_ValCReg           35  
#define M_ValEReg           36 
#define M_ValCReg           37

#define RegNum              40
#define PageSize            4096
#define PhysicalPageNum     64000
#define PhysicalMemSize     PhysicalPageNum * PageSize

#define StackTopPtr         0x08000000

class Machine 
{
public:
    Machine(bool singleStep);
    ~Machine();

    int64_t ReadReg(int rid)            { return reg[rid]; }
    void WriteReg(int rid, int64_t val) { reg[rid] = val; }
    void PrintReg(FILE *fout = NULL);	
    bool ReadMem(uint64_t addr, int size, void *value);
    bool WriteMem(uint64_t addr, int size, uint64_t value);

    int64_t Forward(int rid);
    bool Fetch();
    bool Decode();
    bool Execute();
    bool MemoryAccess();
    bool WriteBack();

    void Run();
    void Status(FILE *fout = NULL);
    void SingleStepDebug();

    int64_t reg[RegNum];
	uint8_t *mem;

    Instruction f_inst, d_inst, e_inst, m_inst, w_inst;
    Instruction test_inst;
    bool f_bubble, d_bubble, e_bubble, m_bubble, w_bubble;
    bool f_stall, d_stall, e_stall, m_stall, w_stall;

    bool singleStep;
    int instCount;
    double runTime;
};

void singleStepP();

}

#endif
