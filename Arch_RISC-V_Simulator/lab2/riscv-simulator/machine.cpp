#include <stdio.h>
#include <string.h>
#include "machine.hpp"
#include "utils.hpp"

void ns1::singleStepP()
{
	printf("c: continue\n");
	printf("r: print registers\n");
	printf("x <address/hex> <size/dec>: get (size) bytes data from memory (address)\n");
	printf("q: quit\n\n");
}

void
ns1::Machine::SingleStepDebug()
{
	char buf[100], tbuf[100];
	while (true)
	{
		fgets(buf, 100, stdin);

		switch (buf[0])
		{
			case 'c':
				return;
			case 'r':
				PrintReg();
				break;
			case 'x':
				uint64_t addr, data;
				int size;
				sscanf(buf, "%s %llx %d", tbuf, &addr, &size);
				if (!ReadMem(addr, size, (void*)&data))
					continue;
				printf("[%08llx]  ", addr);
				for (int i = size - 1; i >= 0 ; --i)
				{
					printf("%02llx ", (data >> (i * 8)) & 0xff);
				}
				printf("\n");
				break;
			case 'q':
				exit(0);
			default:
				printf("Unknown Command.\n");
				singleStepP();
		}
	}
}

bool
ns1::Machine::ReadMem(uint64_t addr, int size, void *value)
{
	uint32_t p_addr = (uint32_t)addr;

	if (p_addr > PhysicalMemSize)
	{
		vprintf("[Error] Physical address out of bound.\n");
		return false;
	}

	switch (size)
	{
		case 1:
			*(uint8_t*)value = *(uint8_t*)(mem + p_addr);
			break;
		case 2:
			*(uint16_t*)value = *(uint16_t*)(mem + p_addr);
			break;
		case 4:
			*(uint32_t*)value = *(uint32_t*)(mem + p_addr);
			break;
		case 8:
			*(uint64_t*)value = *(uint64_t*)(mem + p_addr);
			break;
		default:
			vprintf("[Error] Output data bytes should be 1, 2, 4 or 8.\n");
			return false;
	}

	return true;
}

bool
ns1::Machine::WriteMem(uint64_t addr, int size, uint64_t value)
{
	uint32_t p_addr = (uint32_t)addr;

	if (p_addr > PhysicalMemSize)
	{
		vprintf("[Error] Physical address out of bound.\n");
		return false;
	}

	switch (size)
	{
		case 1:
			*(uint8_t*)(mem + p_addr) = (uint8_t)value;
			break;
		case 2:
			*(uint16_t*)(mem + p_addr) = (uint16_t)value;
			break;
		case 4:
			*(uint32_t*)(mem + p_addr) = (uint32_t)value;
			break;
		case 8:
			*(uint64_t*)(mem + p_addr) = (uint64_t)value;
			break;
		default:
			vprintf("[Error] Input data bytes should be 1, 2, 4 or 8.\n");
			return false;
	}

	return true;
}

ns1::Machine::Machine(bool singleStep) : singleStep(singleStep)
{
	// Machine initialization
	memset(reg, 0, sizeof reg);
	mem = new uint8_t[PhysicalMemSize];

	instCount = 1;
	runTime = .0;

	if(singleStep)
		singleStepP();
}

ns1::Machine::~Machine()
{
	delete mem;
}

void
ns1::Machine::Run()
{
	Timer timer;

	runTime = 0;
    for ( ; ; )
    {
    	timer.StepTime();

		if (!Fetch())
			panic("Fetch Error!\n");
		if (!Decode())
			panic("Decode Error!\n");
		if (!Execute())
			panic("Execute Error!\n");
		if (!MemoryAccess())
			panic("Memory Error!\n");
		if (!WriteBack())
			panic("WriteBack Error!\n");

    	WriteReg(0, 0);
		instCount++;
		runTime += timer.StepTime();

		if (singleStep)
			SingleStepDebug();
    }

    Status();
}

void
ns1::Machine::Status(FILE *fout)
{

	fout = stdout;
	
	fprintf(fout, "\n----------- Stat Info ----------\n");
	fprintf(fout, "Instruction Count:    %d\n", instCount);
	fprintf(fout, "Running Time:         %.4lf\n", runTime);
	fprintf(fout, "MIPS:                 %.2lf\n", (double)instCount/runTime/1e6);
	fprintf(fout,   "--------------------------------\n");
	fprintf(fout, "\n-------- Register Status -------\n");
	PrintReg(fout);
	fprintf(fout,   "--------------------------------\n");

}

void
ns1::Machine::PrintReg(FILE *fout)
{
	if (fout == NULL)
		fout = stdout;
	for (int i = 0; i < RegNum; i += 5)
	{
		for (int j = 0; j < 5; j++)
			fprintf(fout, "[%4s]: 0x%08llx   ", i+j>37?"na":reg_str[i+j], reg[i+j]);
		fprintf(fout, "\n");
	}
}
