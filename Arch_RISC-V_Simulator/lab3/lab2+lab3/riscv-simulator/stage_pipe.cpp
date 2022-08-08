#include "machine_p.hpp"
#include "utils.hpp"
#include "riscvISA.hpp"
#include <stdio.h>

bool predict_pc_updated;
uint64_t f_pred_pc;
bool data_forwarded_rs1;
bool data_forwarded_rs2;

inline uint32_t
maskvalue(int len, uint32_t &value)
{
	uint32_t res = value & ((1 << len) - 1);
	value >>= len;
	return res;
}

inline int64_t
signext64(int len_src, uint64_t value)
{
	uint64_t sign = (1ll << (len_src - 1));
	if (sign & value) 
		return value | ((-1ll) ^ ((1ll << len_src) - 1));
	else
		return value & ((1ll << len_src) - 1);
}

void
Machine::UpdatePipeline()
{

	if (!F_reg.stall && !predict_pc_updated)
		WriteReg(P_PCReg, f_pred_pc);
	F_reg.stall = false;
	if (!f_reg.stall)
		D_reg = f_reg;
	if (!d_reg.stall)
		E_reg = d_reg;
	if (!e_reg.stall)
		M_reg = e_reg;
	W_reg = m_reg;
}

int
Machine::Fetch()
{
	predict_pc_updated = false;
	if (F_reg.bubble) 
	{
		F_reg.bubble = false;
		F_reg.stall  = false;
		if(singleStep)
			vprintf("[F] --BUBBLE--\n");
		f_reg.bubble = true;
		f_reg.stall  = false;
		return 1;
	}

	Instruction *inst = &F_reg.inst;
	uint64_t inst_adr = ReadReg(P_PCReg);
	inst->adr = inst_adr;
	if(!ReadMem(inst_adr, 4, (void*)&(inst->value)))
	{
		vprintf("--Can not fetch operation. [Fetch]\n");
		return 0;
	}
	char *c;
	int hit, time;
	i_cache.HandleRequest((uint32_t)inst_adr, 1, 4, c, hit, time);
	//printf("Request access time: %d cycle\n", time);

	if(singleStep)
		printf("[F] Decode 0x%08llx (0x%016llx)\n", inst->value, inst_adr);

	f_reg = F_reg;
	f_reg.bubble = false;
	f_reg.stall  = false;

	if ((inst->value & 0x7f) == 0x6f) 
	{
		uint64_t jmp_imm = 0;
		uint32_t tmp_val = inst->value;
		maskvalue(12, tmp_val);
		jmp_imm |= (maskvalue(8, tmp_val) << 12);
		jmp_imm |= (maskvalue(1, tmp_val) << 11);
		jmp_imm |= (maskvalue(10, tmp_val) << 1);
		jmp_imm |= (maskvalue(1, tmp_val) << 20);
		jmp_imm = signext64(21, jmp_imm);

		f_pred_pc = inst->adr + jmp_imm;
	}
	else if ((inst->value & 0x7f) == 0x63) 
	{
		f_reg.pred_j = predictor->Predict(inst_adr);
		if (f_reg.pred_j) 
		{
			uint64_t jmp_imm = 0;
			uint32_t tmp_val = inst->value;
			maskvalue(7, tmp_val);
			jmp_imm = 0;
			jmp_imm |= (maskvalue(1, tmp_val) << 11);
			jmp_imm |= (maskvalue(4, tmp_val) << 1);
			maskvalue(13, tmp_val);
			jmp_imm |= (maskvalue(6, tmp_val) << 5);
			jmp_imm |= (maskvalue(1, tmp_val) << 12);
			jmp_imm = signext64(13, jmp_imm);

			f_pred_pc = inst->adr + jmp_imm;
		}
		else	
			f_pred_pc = inst->adr + 4;	
	}	
	else
	{
		f_pred_pc = inst->adr + 4;
		f_reg.pred_j = false;
	}
	return time;
}

int
Machine::Decode()
{

	if (D_reg.bubble) 
	{
		if(singleStep)
			vprintf("[D] --BUBBLE--\n");
		d_reg = D_reg;
		d_reg.bubble = true;
		d_reg.stall  = false;
		data_forwarded_rs1 = true;
		data_forwarded_rs2 = true;	
		return 1;
	}

	Instruction *inst = &D_reg.inst;	
	uint32_t value = inst->value;
	uint32_t opcode = maskvalue(7, value);
	inst->opcode = opcode;
	inst->rd  = 0;
	inst->rs1 = 0;
	inst->rs2 = 0;

	switch (opcode)
	{
		case 0x03:
		case 0x13:
		case 0x1b:
		case 0x67:
		case 0x73:
			inst->type = Itype;
			inst->rd = maskvalue(5, value);
			inst->func3 = maskvalue(3, value);
			inst->rs1 = maskvalue(5, value);
			inst->imm = maskvalue(12, value);
			inst->func7 = (((inst->value) >> 26) & 0x3f);
			inst->imm = signext64(12, inst->imm);
			break;
		case 0x17:
		case 0x37:
			inst->type = Utype;
			inst->rd = maskvalue(5, value);
			inst->imm = (maskvalue(20, value) << 12);
			inst->imm = signext64(32, inst->imm);
			break;
		case 0x23:
			inst->type = Stype;
			inst->imm = 0;
			inst->imm |= maskvalue(5, value);
			inst->func3 = maskvalue(3, value);
			inst->rs1 = maskvalue(5, value);
			inst->rs2 = maskvalue(5, value);
			inst->imm |= (maskvalue(7, value) << 5);
			inst->imm = signext64(12, inst->imm);
			break;
		case 0x33:
		case 0x3b:
			inst->type = Rtype;
			inst->rd = maskvalue(5, value);
			inst->func3 = maskvalue(3, value);
			inst->rs1 = maskvalue(5, value);
			inst->rs2 = maskvalue(5, value);
			inst->func7 = maskvalue(7, value);
			break;
		case 0x63:
			inst->type = SBtype;
			inst->imm = 0;
			inst->imm |= (maskvalue(1, value) << 11);
			inst->imm |= (maskvalue(4, value) << 1);
			inst->func3 = maskvalue(3, value);
			inst->rs1 = maskvalue(5, value);
			inst->rs2 = maskvalue(5, value);
			inst->imm |= (maskvalue(6, value) << 5);
			inst->imm |= (maskvalue(1, value) << 12);
			inst->imm = signext64(13, inst->imm);
			break;
		case 0x6f:
			inst->type = UJtype;
			inst->rd = maskvalue(5, value);
			inst->imm = 0;
			inst->imm |= (maskvalue(8, value) << 12);
			inst->imm |= (maskvalue(1, value) << 11);
			inst->imm |= (maskvalue(10, value) << 1);
			inst->imm |= (maskvalue(1, value) << 20);
			inst->imm = signext64(21, inst->imm);
			break;
		default:
			vprintf("[Error] Unknown opcode 0x%02x. [Decode]\n", opcode);
			return false;
	}

	switch (inst->type)
	{
		case Itype:
			switch (inst->opcode)
			{
				case 0x13:
					switch (inst->func3)
					{
						case 0x00:
							inst->optype = Op_addi;
							break;
						case 0x01:
							if (inst->func7 == 0x00)
								inst->optype = Op_slli;
							else
								goto I_UNKNOWN;
							break;
						case 0x02:
							inst->optype = Op_slti;
							break;
						case 0x03:
							inst->optype = Op_sltiu;
							break;
						case 0x04:
							inst->optype = Op_xori;
							break;
						case 0x05:
							if (inst->func7 == 0x00)
								inst->optype = Op_srli;
							else if (inst->func7 == 0x10)
								inst->optype = Op_srai;
							else
								goto I_UNKNOWN;
							break;
						case 0x06:
							inst->optype = Op_ori;
							break;
						case 0x07:
							inst->optype = Op_andi;
							break;
						default:
							goto I_UNKNOWN;	
					}
					break;
				case 0x1b:
					switch (inst->func3)
					{
						case 0x00:
							inst->optype = Op_addiw;
							break;
						case 0x01:
							if (inst->func7 == 0x00)
								inst->optype = Op_slliw;
							else
								goto I_UNKNOWN;
							break;
						case 0x05:
							if (inst->func7 == 0x00)
								inst->optype = Op_srliw;
							else if (inst->func7 == 0x10)
								inst->optype = Op_sraiw;
							else
								goto I_UNKNOWN;
							break;
						default:
							goto I_UNKNOWN;	
					}
					break;
				case 0x03:
					switch (inst->func3)
					{
						case 0x00:
							inst->optype = Op_lb;
							break;
						case 0x01:
							inst->optype = Op_lh;
							break;
						case 0x02:
							inst->optype = Op_lw;
							break;
						case 0x03:
							inst->optype = Op_ld;
							break;
						case 0x04:
							inst->optype = Op_lbu;
							break;
						case 0x05:
							inst->optype = Op_lhu;
							break;
						case 0x06:
							inst->optype = Op_lwu;
							break;
						default:
							goto I_UNKNOWN;	
					}
					break;
				case 0x73:
					switch (inst->func3)
					{
						case 0x00:
							if (inst->func7 == 0x00)
								inst->optype = Op_ecall;
							else
								goto I_UNKNOWN;
							break;
						default:
							goto I_UNKNOWN;	
					}
					break;
				case 0x67:
					switch (inst->func3)
					{
						case 0x00:
							inst->optype = Op_jalr;
							break;
						default:
							goto I_UNKNOWN;	
					}
					break;			
				default:
					I_UNKNOWN:
					vprintf("[Error] Unknown Itype inst(opcode=0x%02x, func3=0x%02x, func7=0x%02x). [Decode]\n",
							 inst->opcode, inst->func3, inst->func7);
					return false;	
			}
			break;

		case Rtype:
			switch (inst->opcode)
			{
				case 0x3b:
					switch (inst->func3)
					{
						case 0x01:
							switch (inst->func7)
							{
								case 0x00:
									inst->optype = Op_sllw;
									break;
								default:
									goto R_UNKNOWN;	
							}
							break;
						case 0x05:
							switch (inst->func7)
							{
								case 0x00:
									inst->optype = Op_srlw;
									break;
								case 0x20:
									inst->optype = Op_sraw;
									break;
								default:
									goto R_UNKNOWN;	
							}
							break;
						case 0x00:
							switch (inst->func7)
							{
								case 0x00:
									inst->optype = Op_addw;
									break;
								case 0x20:
									inst->optype = Op_subw;
									break;
								default:
									goto R_UNKNOWN;	
							}
							break;
					}
					break;
				case 0x33:
					switch (inst->func3)
					{
						case 0x00:
							switch (inst->func7)
							{
								case 0x00:
									inst->optype = Op_add;
									break;
								case 0x01:
									inst->optype = Op_mul;
									break;
								case 0x20:
									inst->optype = Op_sub;
									break;
								default:
									goto R_UNKNOWN;	
							}
							break;
						case 0x01:
							switch (inst->func7)
							{
								case 0x00:
									inst->optype = Op_sll;
									break;
								case 0x01:
									inst->optype = Op_mulh;
									break;
								default:
									goto R_UNKNOWN;	
							}
							break;
						case 0x02:
							switch (inst->func7)
							{
								case 0x00:
									inst->optype = Op_slt;
									break;
								default:
									goto R_UNKNOWN;	
							}
							break;	
						case 0x03:
							switch (inst->func7)
							{
								case 0x00:
									inst->optype = Op_sltu;
									break;
								default:
									goto R_UNKNOWN;	
							}
							break;	
						case 0x04:
							switch (inst->func7)
							{
								case 0x00:
									inst->optype = Op_xor;
									break;
								case 0x01:
									inst->optype = Op_div;
									break;
								default:
									goto R_UNKNOWN;	
							}
							break;	
						case 0x05:
							switch (inst->func7)
							{
								case 0x00:
									inst->optype = Op_srl;
									break;
								case 0x20:
									inst->optype = Op_sra;
									break;
								default:
									goto R_UNKNOWN;	
							}
							break;
						case 0x06:
							switch (inst->func7)
							{
								case 0x00:
									inst->optype = Op_or;
									break;
								case 0x01:
									inst->optype = Op_rem;
									break;
								default:
									goto R_UNKNOWN;	
							}
							break;	
						case 0x07:
							switch (inst->func7)
							{
								case 0x00:
									inst->optype = Op_and;
									break;
								default:
									goto R_UNKNOWN;	
							}
							break;	
						default:
							goto R_UNKNOWN;		
					}
					break;
				default:
					R_UNKNOWN:
					vprintf("[Error] Unknown Rtype inst(opcode=0x%02x, func3=0x%02x, func7=0x%02x). [Decode]\n",
							 inst->opcode, inst->func3, inst->func7);
					return false;
			}
			break;		

        case Utype:
			switch (inst->opcode)
			{
				case 0x17:
					inst->optype = Op_auipc;
					break;
				case 0x37:
					inst->optype = Op_lui;
					break;
				default:
					vprintf("[Error] Unknown opcode 0x%02x for Utype inst. [Decode]\n",
							 inst->opcode);
					return false;
			}
			break;

		case Stype:
			switch (inst->func3)
			{
				case 0x00:
					inst->optype = Op_sb;
					break;
				case 0x01:
					inst->optype = Op_sh;
					break;
				case 0x02:
					inst->optype = Op_sw;
					break;
				case 0x03:
					inst->optype = Op_sd;
					break;
				default:
					vprintf("[Error] Unknown func3 0x%02x for Stype inst. [Decode]\n",
							 inst->func3);
					return false;
			}
			break;

		case SBtype:
			switch (inst->func3)
			{
				case 0x00:
					inst->optype = Op_beq;
					break;
				case 0x01:
					inst->optype = Op_bne;
					break;
				case 0x04:
					inst->optype = Op_blt;
					break;
				case 0x05:
					inst->optype = Op_bge;
					break;
				case 0x06:
					inst->optype = Op_bltu;
					break;
				case 0x07:
					inst->optype = Op_bgeu;
					break;
				default:
					vprintf("[Error] Unknown func3 0x%02x for SBtype inst. [Decode]\n",
							 inst->func3);
					return false;
			}
			break;
		
		case UJtype:
			switch (inst->opcode)
			{
				case 0x6f:
					inst->optype = Op_jal;
					break;
				default:
					vprintf("[Error] Unknown opcode 0x%02x for UJtype inst. [Decode]\n",
							 inst->opcode);
					return false;	
			}
			break;
		default:
			ASSERT(false);
	}

	if (singleStep)
	{
		printf("[D] ");
		inst->PrintInst();
	}

	d_reg = D_reg;
	d_reg.stall  = false;
	d_reg.bubble = false;
	d_reg.val_e = ReadReg(inst->rs1);
	d_reg.val_c = ReadReg(inst->rs2);
	data_forwarded_rs1 = false;
	data_forwarded_rs2 = false;

	if (inst->optype == Op_jalr)
	{
		f_reg.bubble = true;
		F_reg.bubble = true;
	}

	if (inst->optype == Op_ecall)
	{
		F_reg.stall  = true;
		f_reg.bubble = true;
	}

	return 1;
}

int
Machine::Execute()
{
	int use_cyc = 1;

	if (E_reg.bubble)
	{
		if(singleStep)
			vprintf("[E] --BUBBLE--\n");
		e_reg = E_reg;
		e_reg.bubble = true;
		e_reg.stall  = false;
		return 1;
	}
	
	Instruction *inst = &E_reg.inst;
	int64_t val_a, val_b, val_e = 0, val_c = 0;
	val_a = E_reg.val_e;
	val_b = E_reg.val_c;
	
	if (singleStep)
	{
		printf("[E] ");
		inst->PrintInst();
	}

	switch (inst->optype)
	{
		case Op_add:
			val_e = val_a + val_b;
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_sub:
			val_e = val_a - val_b;
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_mul:
			val_e = val_a * val_b;
			use_cyc = cfg.u32_cfg[MUL64_CYC];
			break;
		case Op_div:
			val_e = val_a / val_b;
			use_cyc = cfg.u32_cfg[DIV64_CYC];
			break;
		case Op_addw:
			val_e = (int64_t)((int32_t)(val_a + val_b));
			use_cyc = cfg.u32_cfg[ADD32_CYC];
			break;
		case Op_subw:
			val_e = (int64_t)((int32_t)(val_a - val_b));
			use_cyc = cfg.u32_cfg[ADD32_CYC];
			break;
		case Op_mulh:
			val_e = (int64_t)(((__int128_t)val_a * (__int128_t)val_b) >> 64);
			use_cyc = cfg.u32_cfg[MUL64_CYC];
			break;
		case Op_and:
			val_e = val_a & val_b;
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_or:
			val_e = val_a | val_b;	
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_xor:
			val_e = val_a ^ val_b;
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_sll:
			val_e = val_a << val_b;
			use_cyc = cfg.u32_cfg[SFT_CYC];
			break;		
		case Op_slt:
			val_e = val_a < val_b? 1 : 0;
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_sltu:
			val_e = (uint64_t)val_a < (uint64_t)val_b? 1 : 0;
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_sra:
			val_e = val_a >> val_b;	
			use_cyc = cfg.u32_cfg[SFT_CYC];
			break;
		case Op_srl:
			val_e = (int64_t)((uint64_t)val_a >> val_b);
			use_cyc = cfg.u32_cfg[SFT_CYC];
			break;
		case Op_sllw:
			val_e = (int64_t)((int32_t)val_a << val_b);
			use_cyc = cfg.u32_cfg[SFT_CYC];
			break;
		case Op_sraw:
			val_e = (int64_t)((int32_t)val_a >> val_b);
			use_cyc = cfg.u32_cfg[SFT_CYC];
			break;
		case Op_srlw:
			val_e = (uint64_t)((uint32_t)val_a >> val_b);
			use_cyc = cfg.u32_cfg[SFT_CYC];
			break;
		case Op_sb:
		case Op_sh:
		case Op_sw:
		case Op_sd:
			val_c = val_b;
		case Op_lb:
		case Op_lbu:
		case Op_lh:
		case Op_lhu:
		case Op_lw:
		case Op_lwu:
		case Op_ld:
		case Op_addi:
			val_b = inst->imm;
			val_e = val_a + val_b;	
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_addiw:
			val_b = inst->imm;
			val_e = (int64_t)((int32_t)(val_a + val_b));
			use_cyc = cfg.u32_cfg[ADD32_CYC];
			break;
		case Op_andi:
			val_b = inst->imm;
			val_e = val_a & val_b;
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_ori:
			val_b = inst->imm;
			val_e = val_a | val_b;
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_xori:
			val_b = inst->imm;
			val_e = val_a ^ val_b;
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_slli:
			val_b = inst->imm;
			val_e = val_a << (val_b & 0x3f);
			use_cyc = cfg.u32_cfg[SFT_CYC];
			break;	
		case Op_slti:
			val_b = inst->imm;
			val_e = val_a < val_b? 1 : 0;
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_sltiu:
			val_b = inst->imm;
			val_e = (uint64_t)val_a < (uint64_t)val_b? 1 : 0;
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_srai:
			val_b = inst->imm;
			val_e = val_a >> (val_b & 0x3f);
			use_cyc = cfg.u32_cfg[SFT_CYC];
			break;
		case Op_srli:
			val_b = inst->imm;
			val_e = (int64_t)((uint64_t)val_a >> (val_b & 0x3f));
			use_cyc = cfg.u32_cfg[SFT_CYC];
			break;
		case Op_slliw:
			val_b = inst->imm;
			val_e = (int64_t)((int32_t)val_a << (val_b & 0x1f));
			use_cyc = cfg.u32_cfg[SFT_CYC];
			break;	
		case Op_sraiw:
			val_b = inst->imm;
			val_e = (int64_t)((int32_t)val_a >> (val_b & 0x1f));
			use_cyc = cfg.u32_cfg[SFT_CYC];
			break;	
		case Op_srliw:
			val_b = inst->imm;
			val_e = (uint64_t)((uint32_t)val_a >> (val_b & 0x1f));
			use_cyc = cfg.u32_cfg[SFT_CYC];
			break;	
		case Op_jal:
			val_e = inst->adr + 4;
			val_c = inst->adr + inst->imm;
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_jalr:
			val_b = inst->imm;
			val_e = inst->adr + 4;
			val_c = (val_a + val_b) & (-1ll ^ 0x1);
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			WriteReg(P_PCReg, val_c);
			F_reg.bubble = false;
			F_reg.stall  = false;
			predict_pc_updated = true;
			jalrStlCount++;
			break;	
		case Op_beq:
			val_e = (val_a == val_b);
			val_c = inst->adr + inst->imm;
			goto PRED_JUDGE;
		case Op_bne:
			val_e = (val_a != val_b);
			val_c = inst->adr + inst->imm;
			goto PRED_JUDGE;
		case Op_bge:
			val_e = (val_a >= val_b);
			val_c = inst->adr + inst->imm;
			goto PRED_JUDGE;
		case Op_bgeu:
			val_e = ((uint64_t)val_a >= (uint64_t)val_b);
			val_c = inst->adr + inst->imm;
			goto PRED_JUDGE;
		case Op_blt:
			val_e = (val_a < val_b);
			val_c = inst->adr + inst->imm;
			goto PRED_JUDGE;
		case Op_bltu:
			val_e = ((uint64_t)val_a < (uint64_t)val_b);
			val_c = inst->adr + inst->imm;
			goto PRED_JUDGE;
		PRED_JUDGE:
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			if (E_reg.pred_j != val_e) 
			{
				predictor->Update(inst->adr, val_e);
				ctrlHzdCount++;
				predict_pc_updated = true;
				WriteReg(P_PCReg, val_e ? val_c : inst->adr+4);
				F_reg.bubble = false;
				F_reg.stall  = false;
				f_reg.bubble = true;
				d_reg.bubble = true;
			}
			break;
		case Op_auipc:
			val_e = inst->adr + inst->imm; 
			use_cyc = cfg.u32_cfg[ADD64_CYC];
			break;
		case Op_lui:
			val_e = inst->imm;
			break;
		case Op_rem:
			val_e = val_a % val_b;
			use_cyc = cfg.u32_cfg[DIV64_CYC];
			break;
		case Op_ecall:
			break;
		default:
			vprintf("[Error] Unknown optype %d. [Execute]\n",
					 inst->optype);
			return 0;
	}

	e_reg = E_reg;
	e_reg.stall  = false;
	e_reg.bubble = false;
	e_reg.val_c = val_c;
	e_reg.val_e = val_e;

	if (inst->rd) 
	{
		if (inst->opcode == 0x03)
		{
			if (inst->rd == d_reg.inst.rs1
				|| inst->rd == d_reg.inst.rs2)
			{
				f_reg.stall  = true;
				F_reg.stall  = true;
				d_reg.bubble = true;
				data_forwarded_rs1 = true;
				data_forwarded_rs2 = true;
				loadHzdCount++;
			}
		}

		else
		{
			if (inst->rd == d_reg.inst.rs1)
			{
				d_reg.val_e = val_e;
				data_forwarded_rs1 = true;
			}
			if (inst->rd == d_reg.inst.rs2)
			{
				d_reg.val_c = val_e;
				data_forwarded_rs2 = true;
			}
		}
	}

	if (inst->optype == Op_ecall)
	{
		F_reg.stall  = true;
		f_reg.bubble = true;
		d_reg.bubble = true;
	}

	return use_cyc;
}

int
Machine::MemoryAccess()
{

	if (M_reg.bubble) 
	{
		if(singleStep)
			vprintf("[M] --BUBBLE--\n");
		m_reg = M_reg;
		m_reg.stall  = false;
		m_reg.bubble = true;
		return 1;
	}

	Instruction *inst = &M_reg.inst;
	int64_t val_e = M_reg.val_e, val_c = M_reg.val_c;
	char *c;
	int hit, time;

	if (singleStep)
	{
		printf("[M] ");
		inst->PrintInst();
	}
	switch (inst->optype)
	{
		case Op_sb:
			if (!WriteMem(val_e, 1, (uint8_t)val_c))
			{
				vprintf("--Memory access error. [MemoryAccess]\n");
				return 0;
			}
			d_cache.HandleRequest((uint32_t)val_e, 1, 0, c, hit, time);
			break;
		case Op_sh:
			if (!WriteMem(val_e, 2, (uint16_t)val_c))
			{
				vprintf("--Memory access error. [MemoryAccess]\n");
				return 0;
			}
			d_cache.HandleRequest((uint32_t)val_e, 2, 0, c, hit, time);
			break;
		case Op_sw:
			if (!WriteMem(val_e, 4, (uint32_t)val_c))
			{
				vprintf("--Memory access error. [MemoryAccess]\n");
				return 0;
			}
			d_cache.HandleRequest((uint32_t)val_e, 4, 0, c, hit, time);
			break;
		case Op_sd:
			if (!WriteMem(val_e, 8, (uint64_t)val_c))
			{
				vprintf("--Memory access error. [MemoryAccess]\n");
				return 0;
			}
			d_cache.HandleRequest((uint32_t)val_e, 8, 0, c, hit, time);
			break;
		case Op_lb:
			if (!ReadMem(val_e, 1, &val_c))
			{
				vprintf("--Memory access error. [MemoryAccess]\n");
				return 0;
			}		
			d_cache.HandleRequest((uint32_t)val_e, 1, 1, c, hit, time);
			val_e = (int64_t)((int8_t)val_c);
			break;
		case Op_lbu:
			if (!ReadMem(val_e, 1, &val_c))
			{
				vprintf("--Memory access error. [MemoryAccess]\n");
				return 0;
			}
			d_cache.HandleRequest((uint32_t)val_e, 1, 1, c, hit, time);
			val_e = (uint64_t)((uint8_t)val_c);
			break;
		case Op_lh:
			if (!ReadMem(val_e, 2, &val_c))
			{
				vprintf("--Memory access error. [MemoryAccess]\n");
				return 0;
			}
			d_cache.HandleRequest((uint32_t)val_e, 2, 1, c, hit, time);
			val_e = (int64_t)((int16_t)val_c);
			break;
		case Op_lhu:
			if (!ReadMem(val_e, 2, &val_c))
			{
				vprintf("--Memory access error. [MemoryAccess]\n");
				return 0;
			}
			d_cache.HandleRequest((uint32_t)val_e, 2, 1, c, hit, time);
			val_e = (uint64_t)((uint16_t)val_c);
			break;
		case Op_lw:
			if (!ReadMem(val_e, 4, &val_c))
			{
				vprintf("--Memory access error. [MemoryAccess]\n");
				return 0;
			}
			d_cache.HandleRequest((uint32_t)val_e, 4, 1, c, hit, time);
			val_e = (int64_t)((int32_t)val_c);
			break;
		case Op_lwu:
			if (!ReadMem(val_e, 4, &val_c))
			{
				vprintf("--Memory access error. [MemoryAccess]\n");
				return 0;
			}
			d_cache.HandleRequest((uint32_t)val_e, 4, 1, c, hit, time);
			val_e = (uint64_t)((uint32_t)val_c);
			break;
		case Op_ld:
			if (!ReadMem(val_e, 8, &val_c))
			{
				vprintf("--Memory access error. [MemoryAccess]\n");
				return 0;
			}
			d_cache.HandleRequest((uint32_t)val_e, 8, 1, c, hit, time);
			val_e = (int64_t)val_c;
			break;
		default:
			time = 1;
	}
	
	m_reg = M_reg;
	m_reg.stall  = false;
	m_reg.bubble = false;
	m_reg.val_c  = val_c;
	m_reg.val_e  = val_e;

	if (inst->rd)
	{
		if (inst->rd == d_reg.inst.rs1 && !data_forwarded_rs1)
		{
			d_reg.val_e = val_e;
			data_forwarded_rs1 = true;
		}
		if (inst->rd == d_reg.inst.rs2 && !data_forwarded_rs2)
		{
			d_reg.val_c = val_e;
			data_forwarded_rs2 = true;
		}
	}

	if (inst->optype == Op_ecall)
	{
		F_reg.stall  = true;
		f_reg.bubble = true;
		d_reg.bubble = true;
		e_reg.bubble = true;		
	}

	return time;
}

int
Machine::WriteBack()
{

	if (W_reg.bubble) 
	{
		if(singleStep)
			vprintf("[W] --BUBBLE--\n");
		return 1;
	}
	
	instCount++;
	Instruction *inst = &W_reg.inst;
	int64_t val_e = W_reg.val_e, val_c = W_reg.val_c;
	WriteReg(PCReg, inst->adr);
	int use_cyc = 1;

	if (singleStep)
	{
		printf("[W] ");
		inst->PrintInst();
	}

	switch (inst->optype)
	{
		case Op_add:
		case Op_sub:	
		case Op_mul:
		case Op_div:
		case Op_addw:
		case Op_subw:
		case Op_mulh:
		case Op_and:
		case Op_or:
		case Op_xor:
		case Op_sll:
		case Op_slt:
		case Op_sltu:
		case Op_sra:
		case Op_srl:
		case Op_sllw:		
		case Op_sraw:
		case Op_srlw:
		case Op_lb:
		case Op_lbu:
		case Op_lh:
		case Op_lhu:
		case Op_lw:
		case Op_lwu:
		case Op_ld:
		case Op_addi:
		case Op_addiw:
		case Op_andi:
		case Op_ori:
		case Op_xori:
		case Op_slli:
		case Op_slti:	
		case Op_sltiu:
		case Op_srai:
		case Op_srli:
		case Op_slliw:	
		case Op_sraiw:	
		case Op_srliw:
		case Op_jal:
		case Op_jalr:	
		case Op_auipc:
		case Op_lui:
		case Op_rem:
			WriteReg(inst->rd, val_e);
			WriteReg(ZeroReg, 0); 
			break;
		case Op_beq:
		case Op_bne:
		case Op_bge:
		case Op_bgeu:
		case Op_blt:
		case Op_bltu:		
			totalBranch++;
			goto NO_WRITEBACK;
			break;
		case Op_ecall:
			ecallStlCount++;
			val_e = ReadReg(A0Reg);
			val_c = ReadReg(A7Reg);
			switch(val_c)
			{
				case 0:
					printf("%d", val_e);
					break;
				case 1:
					printf("%c", val_e);
					break;
				case 2:
					char chr;
					int lim;
					lim = 0;
					while(ReadMem((uint64_t)val_e, 1, (void*)&chr) && chr != '\0' && (++lim) <= 100)
					{
						char *c;
						int hit, time;
						d_cache.HandleRequest((uint32_t)val_e, 1, 1, c, hit, time);
						use_cyc += time;
						printf("%c", chr);
						val_e += 1;
					}
					if (lim >= MaxStrLen)
					{
						vprintf("[Warning] String cut due to length exceeding (> %d).\n", MaxStrLen);
					}
					break;
			  	case 3:
				    scanf("%lld", &val_e);
				    WriteReg(A0Reg, val_e);
				    break;
				case 4:
					scanf("%c", (char*)&val_e);
				    val_e = (int64_t)((char)val_e);
				    WriteReg(A0Reg, val_e);
				    break;
				case 93:
					Status();
					exit(0);
					break;
				default:
					vprintf("[Error] Unknown syscall a0=0x%llx a7=0x%llx. [WriteBack]\n", val_e, val_c);
					return 0;
			}
			break;
	}

	NO_WRITEBACK:

	if (inst->rd)
	{
		if (inst->rd == d_reg.inst.rs1 && !data_forwarded_rs1)
		{
			d_reg.val_e = val_e;
			data_forwarded_rs1 = true;
		}
		if (inst->rd == d_reg.inst.rs2 && !data_forwarded_rs2)
		{
			d_reg.val_c = val_e;
			data_forwarded_rs2 = true;
		}
	}

	if (inst->optype == Op_ecall)
	{
		d_reg.bubble = true;
		e_reg.bubble = true;
		m_reg.bubble = true;
	}
	return use_cyc;

}

