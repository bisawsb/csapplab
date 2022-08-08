#include <stdio.h>
#include <string.h>
#include "machine_p.hpp"
#include "utils.hpp"

#define MAX(a, b) ((a) > (b) ? (a) : (b))

char *pred_str[30] =
{
	"always taken", "always not taken", "1-bit predictor", "2-bit predictor"
};

Predictor::Predictor(PRED_TYPE mode) : mode(mode)
{
	pred_state = new uint64_t[PredCacheSize];
	Init();
}

Predictor::~Predictor()
{
	delete [] pred_state;
}

void
Predictor::Init()
{
	for (int i = 0; i < PredCacheSize; ++i)
	{
		switch (mode)
		{
			case BIT1_PRED:
				pred_state[i] = 1;	
				break;
			case BIT2_PRED:
				pred_state[i] = 2; 
				break;
		}
	}
}

bool
Predictor::Predict(uint64_t addr)
{
	uint64_t state = pred_state[(addr >> 2) % PredCacheSize];
	switch (mode)
	{
		case ALWAYS_TAKEN:
			return true;
		case ALWAYS_NOT_TAKEN:
			return false;
		case BIT1_PRED:
			return state;
		case BIT2_PRED:
			return (state>>1);
	}
	return false;
}

void
Predictor::Update(uint64_t addr, bool real)
{
	uint64_t &state = pred_state[(addr >> 2) % PredCacheSize];
	switch (mode)
	{
		case BIT1_PRED:
			if ((bool)state != real)
				state ^= 1;
			break;
		case BIT2_PRED:
			switch (state)
			{
				case 0: 
					if (real)
						state = 1;
					break;
				case 1: 
					if (real)
						state = 3;
					else
						state = 0;
					break;
				case 2: 
					if (real)
						state = 3;
					else
						state = 0;
					break;
				case 3:
					if (!real)
						state = 2;
					break;
			}
			break;
	}
}

void singleStepP()
{
	printf("c: continue\n");
	printf("r: print registers\n");
	printf("x <address/hex> <size/dec>: get (size) bytes data from memory (address)\n");
	printf("q: quit\n\n");
}

void
Machine::SingleStepDebug()
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
Machine::ReadMem(uint64_t addr, int size, void *value)
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
Machine::WriteMem(uint64_t addr, int size, uint64_t value)
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

Machine::Machine(PRED_TYPE mode, const char *file)
{
	// Machine initialization
	memset(reg, 0, sizeof reg);
	cfg.LoadConfig(file);
	mem = new uint8_t[PhysicalMemSize];
	predictor = new Predictor(mode);
	StorageStats s;
    vm.SetStats(s);
    i_cache.SetStats(s);
	d_cache.SetStats(s);
	l2.SetStats(s);;
	llc.SetStats(s);

    StorageLatency ml;
    ml.hit_latency = cfg.u32_cfg[MEM_CYC];
    vm.SetLatency(ml);

    StorageLatency ll;
	CacheConfig lc;
	ll.hit_latency = 1;
	lc.size = 64;
	lc.associativity = 8;
	lc.set_num = 64;
	lc.write_through = 0;
	lc.write_allocate = 1;
	lc.block_bits = 6;
	lc.set_bits = 6;
	lc.strategy = LRU;
    i_cache.SetLatency(ll);
	i_cache.SetConfig(lc);
	d_cache.SetLatency(ll);
	d_cache.SetConfig(lc);

	ll.hit_latency = 8;
	lc.set_num = 512;
	lc.set_bits = 9;
    l2.SetLatency(ll);
	l2.SetConfig(lc);

	ll.hit_latency = 20;
	lc.set_num = 16384;
	lc.set_bits = 14;
    llc.SetLatency(ll);
	llc.SetConfig(lc);

	i_cache.SetLower(&l2);
	d_cache.SetLower(&l2);
	l2.SetLower(&llc);
	llc.SetLower(&vm);

	cycCount = 0;
	cpuCount = 0;
	instCount = 0;
	runTime = .0;

    loadHzdCount = 0;
    ctrlHzdCount = 0;
    ecallStlCount = 0;
    jalrStlCount = 0;
    totalBranch = 0;
}

Machine::~Machine()
{
	delete mem;
	delete predictor;
}

void
Machine::Run()
{
	Timer timer;

	runTime = 0;
	F_reg.bubble = false;

	if(singleStep)
		singleStepP();

    for ( ; ; )
    {
    	int mxCyc = 1, useCyc;
    	timer.StepTime();

		if ((useCyc = Fetch()) == 0)
			panic("Fetch Error!\n");
		else
			mxCyc = MAX(mxCyc, useCyc);
		if ((useCyc = Decode()) == 0)
			panic("Decode Error!\n");
		else
			mxCyc = MAX(mxCyc, useCyc);
		if ((useCyc = Execute()) == 0)
			panic("Execute Error!\n");
		else
			mxCyc = MAX(mxCyc, useCyc);
		if ((useCyc = MemoryAccess()) == 0)
			panic("Memory Error!\n");
		else
			mxCyc = MAX(mxCyc, useCyc);
		if ((useCyc = WriteBack()) == 0)
			panic("WriteBack Error!\n");
		else
			mxCyc = MAX(mxCyc, useCyc);

		UpdatePipeline();
		cycCount++;
		cpuCount += mxCyc;
		runTime += timer.StepTime();

    	if (singleStep)
    		SingleStepDebug();
    }

    Status();
}

void
Machine::Status(FILE *fout)
{

	fout = stdout;
	
	fprintf(fout, "\n----------- Stat Info ----------\n");
	fprintf(fout, "Instruction Count:     %d\n", instCount);
	fprintf(fout, "CPU Cycle Count:       %d\n", cpuCount);	
	fprintf(fout, "CPU Clock CPI:         %.2lf\n", (double)cpuCount/instCount);
	fprintf(fout,   "--------------------------------\n\n");

	StorageStats s;
	i_cache.GetStats(s);
	printf("Total I-Cache access cpu cycle: %d\n", s.access_time);
	float miss_rate = (float)s.miss_num/s.access_counter*100;
	printf("I-Cache Miss rate: %.2f% (%d/%d)\n", miss_rate, s.miss_num, s.access_counter);
	d_cache.GetStats(s);
	printf("Total D-Cache access cpu cycle: %d\n", s.access_time);
	miss_rate = (float)s.miss_num/s.access_counter*100;
	printf("D-Cache Miss rate: %.2f% (%d/%d)\n", miss_rate, s.miss_num, s.access_counter);
	l2.GetStats(s);
	printf("Total L2 access cpu cycle: %d\n", s.access_time);
	miss_rate = (float)s.miss_num/s.access_counter*100;
	printf("L2 Miss rate: %.2f% (%d/%d)\n", miss_rate, s.miss_num, s.access_counter);
	llc.GetStats(s);
	printf("Total LLC access cpu cycle: %d\n", s.access_time);
	miss_rate = (float)s.miss_num/s.access_counter*100;
	printf("LLC Miss rate: %.2f% (%d/%d)\n", miss_rate, s.miss_num, s.access_counter);

}

void
Machine::PrintReg(FILE *fout)
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
