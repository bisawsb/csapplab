#include <string.h>
#include "config.hpp"
#include "utils.hpp"

char *valid_cfg_u32[10] =
{
	"SFT_CYC",
	"ADD32_CYC",
	"ADD64_CYC",
	"MUL32_CYC",
	"MUL64_CYC",
	"DIV32_CYC",
	"DIV64_CYC",
	"MEM_CYC"		
};

bool InConfigU32(char *idf, int &id)
{
	for (int i = 0; i < ConfigNum; ++i)
	{
		if (strcmp(idf, valid_cfg_u32[i]) == 0)
		{
			id = i;
			return true;
		}
	}
	id = -1;
	return false;
}

Config::Config()
{
	for (int i = 0; i < ConfigNum; ++i)
		u32_cfg[i] = 1;
}

Config::~Config() {}

void
Config::LoadConfig(const char *file)
{
	FILE *fi = fopen(file, "r");

	if (fi == NULL)
	{
		printf("config: Fail to open config file '%s'\n", file);
		return;
	}

	char buf[100];
	char idf[100];
	int id;
	while(fgets(buf, 100, fi))
	{
		if ((strlen(buf) < 3) ||
			(buf[0] == '\\' && buf[1] == '\\'))
			continue;
		sscanf(buf, "%[A-Za-z0-9\_]:", idf);
		if (InConfigU32(idf, id))
		{
			unsigned val;
			sscanf(buf, "%[A-Za-z0-9\_]:%u", idf, &val);
			u32_cfg[id] = val;
		}
	}
}

