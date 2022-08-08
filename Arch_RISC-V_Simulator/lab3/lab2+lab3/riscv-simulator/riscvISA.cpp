#include "riscvISA.hpp"
#include "utils.hpp"
#include <stdio.h>

const char *op_str[60] =
{
	"add", "mul", "sub", "sll", "mulh",
	"slt", "xor", "div", "srl", "sra",
	"or", "rem", "and", "lb", "lh",
	"lw", "ld", "addi", "slli", "slti",
	"xori", "srli", "srai", "ori", "andi",
	"addiw", "jalr", "ecall", "sb", "sh",
	"sw", "sd", "beq", "bne", "blt",
	"bge", "auipc", "lui", "jal", "bltu",
	"bgeu", "lbu", "lhu", "lwu", "sltiu",
	"sltu", "slliw", "srliw", "sraiw", "addw",
	"subw", "sllw", "srlw", "sraw"
};

const char *reg_str[38] = {
    "zero", "ra", "sp", "gp", "tp",   
    "t0", "t1", "t2", "s0", "s1",   
    "a0", "a1", "a2", "a3", "a4",  
    "a5", "a6", "a7", "s2", "s3",  
    "s4", "s5", "s6", "s7", "s8",  
    "s9", "s10", "s11", "t3", "t4",  
    "t5", "t6", "pc", "p_pc", "E_vE",
	"E_vC", "M_vE", "M_vC"
};

void 
Instruction::PrintInst()
{
	if (optype < 0 || optype >= OpNum)
		goto OP_UNKNOWN;
	printf("%s ", op_str[optype]);
	switch (type)
	{
		case Rtype:
			printf("%s, %s, %s ", reg_str[rd], reg_str[rs1], reg_str[rs2]);
			break;
		case Itype:
			if (opcode == 0x03)
				printf("%s, %lld(%s) ", reg_str[rd], imm, reg_str[rs1]);
			else if(opcode == 0x73)
				printf(" ");
			else
				printf("%s, %s, %lld ", reg_str[rd], reg_str[rs1], imm);
			break;
		case Stype:
			printf("%s, %lld(%s) ", reg_str[rs2], imm, reg_str[rs1]);
			break;
		case SBtype:
			printf("%s, %s, %lld ", reg_str[rs1], reg_str[rs2], imm >> 1);
			break;
		case Utype:
			printf("%s, 0x%llx ", reg_str[rd], (uint64_t)imm >> 12);
			break;
		case UJtype:
			printf("%s, %lld ", reg_str[rd], imm >> 1);
			break;
		default:
			goto OP_UNKNOWN;
	}
	printf("(0x%016llx)\n", adr);
	return;

	OP_UNKNOWN:
	printf("Unknown instruction\n");
}
