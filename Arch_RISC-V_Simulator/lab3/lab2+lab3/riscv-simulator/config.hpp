#ifndef CONFIG_HEADER
#define CONFIG_HEADER
#define ConfigNum 8
#include <stdio.h>

enum CFG_U32
{
	SFT_CYC,			// shift
	ADD32_CYC,			// add 32bit
	ADD64_CYC,			// add 64bit
	MUL32_CYC,			// mul 32bit
	MUL64_CYC,			// mul 64bit
	DIV32_CYC,			// div 32bit 
	DIV64_CYC,			// div 64bit 
	MEM_CYC				// memory access
};

extern char *valid_cfg_u32[10];

class Config
{
public:
	unsigned u32_cfg[ConfigNum];

	Config();
	~Config();
	void LoadConfig(const char *file);
};

#endif
