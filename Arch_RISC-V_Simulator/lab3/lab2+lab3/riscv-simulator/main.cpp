#include <iostream>
#include <fstream>
#include <sstream>
#include <elfio/elfio.hpp>
#include <string.h>
#include "machine_p.hpp"
#include "utils.hpp"

using namespace std;

#include <boost/program_options.hpp>
using namespace boost::program_options;

Machine *machine_p;
bool singleStep = false;
string fileName, cfgFileName;
PRED_TYPE predType;

void ParseArg(int argc, char *argv[])
{
    options_description opts("RISC-V Simulator Parameters:");

    opts.add_options()
	("filename,f", value<string>()->required(), "riscv elf file")
    ("single,s", "single step mode")
    ("config,c", value<string>()->required(), "set config file (default 'cfg/default.cfg')")   
    ("branch,b", value<int>()->required(),
         "branch prediction strategy (default 'always taken'):\n 0: always taken\n 1: always not taken\n 2: 1-bit predictor\n 3: 2-bits predictor")
    ("help,h", "help info");

    variables_map vm;
    
    store(parse_command_line(argc, argv, opts), vm);

	if(vm.count("help"))
    {
        cout << opts << endl;
        exit(0);
    }

    if(vm.count("filename"))
        fileName = vm["filename"].as<string>();  
    else
    {
        printf("Please use '-f <filepath>' to input ELF file.\n");
        exit(0);
    }

	if(vm.count("config"))
	    cfgFileName = vm["config"].as<string>();
	else
	    cfgFileName = string("cfg/default.cfg");

	if (vm.count("branch"))
	{
	    int b = vm["branch"].as<int>();
	    if (b >= 0 && b <= 3)
	        predType = (PRED_TYPE)b;
	    else
	    {
	        printf("branch prediction strategy not found (should in 0-3), use ALWAYS_TAKEN.\n");
	        predType = ALWAYS_TAKEN;
	    }
	}
	else
	    predType = ALWAYS_TAKEN;

    if(vm.count("single"))
        singleStep = true;

}


int main(int argc, char *argv[])
{
	ELFIO::elfio elf;
    Timer timer;

    ParseArg(argc, argv);

    // build machine
	machine_p = new Machine(predType, cfgFileName.c_str());
	machine_p->singleStep = singleStep;

    vprintf("Loading elf file...\n");
    elf.load(fileName.c_str());

    if (elf.get_machine() != EM_RISCV)
    {
        panic("Not a riscv prog.\n");
        exit(0);
    }

    vprintf("Loading data to memory...\n");
    ELFIO::Elf_Half n_seg = elf.segments.size();

	for (int i = 0; i < n_seg; ++i)
    {
        const ELFIO::segment *pseg = elf.segments[i];
        uint64_t addr = pseg->get_virtual_address();
        uint64_t m_end = addr + pseg->get_memory_size();
        uint64_t f_end = addr + pseg->get_file_size();
        const uint8_t* data = (uint8_t*)pseg->get_data();
        for (uint64_t offset = 0; addr < m_end; addr++, offset++)
            machine_p->WriteMem(addr, 1, data[offset]);		
    }

    machine_p->WriteReg(P_PCReg, elf.get_entry());

	// stack initialization    
	vprintf("Initializing stack...\n");

	machine_p->WriteReg(SPReg, StackTopPtr-8);
	machine_p->WriteMem(StackTopPtr-8, 8, 0xdeadbeefdeadbeefll);

    vprintf("Finished loading elf file\n\n");

    machine_p->Run();

    return 0;
}
