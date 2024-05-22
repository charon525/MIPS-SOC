`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: maindec
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines2.vh"
module maindec(
	input wire[5:0] op,
	input wire[5:0] funct,
	input wire[4:0] rs,
	input wire[4:0] rt,
	input wire inst_on, // +++

	output wire memtoreg,memwrite,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,
	output wire[3:0] aluop,
	/*增添信号*/
	output wire isunsign, // 判断是否为无符号扩展立即数
	output wire hilo, // 判断是否需要写入hilo寄存器
	output wire pcto31, // 是否将pc+8写入31号寄存器
	output wire jal,
	output wire jr,
	output reg invalid, // 判断是否为未定义的指令
	output wire cp0w, // 为1时写cp0
	output wire cp0r, // 为1时读cp0
	output wire[2:0] memop // mem功能选择
    );

	reg[20:0] controls;
	reg[20:0] controls_tmp;
	assign {regwrite,regdst,alusrc,branch,   memwrite,memtoreg,jump,isunsign,  hilo,memop,  pcto31,jal,jr,  cp0w,cp0r,  aluop} = controls_tmp;
	always @(*) begin
		controls_tmp = 21'b0;
		if(~inst_on)begin
			controls_tmp = controls;
		end
	end
	always @(*) begin
		invalid = 0;
		controls = 21'b0000_0000_0000_000_00_0000;
		// if(~inst_on)begin
			case (op)
				`R_TYPE:
					if(rs==5'b0 && rt==5'b0 && funct==6'b0)
						controls = 21'b0000_0000_0000_000_00_0000; // `NOP
					else
						case(funct) // R-TYRE
							`MTHI:		controls = {17'b0000_0000_1000_000_00,`R_TYPE_OP};
							`MTLO:		controls = {17'b0000_0000_1000_000_00,`R_TYPE_OP};
							`JR:		controls = {17'b0000_0000_0000_001_00,`USELESS_OP};
							`JALR:		controls = {17'b1100_0000_0000_001_00,`R_TYPE_OP};
							`MULT:     	controls = {17'b0000_0000_1000_000_00, `R_TYPE_OP};
							`MULTU:  	controls = {17'b0000_0000_1000_000_00, `R_TYPE_OP};
							`DIV:   	controls = {17'b0000_0000_1000_000_00, `R_TYPE_OP};
							`DIVU:  	controls = {17'b0000_0000_1000_000_00, `R_TYPE_OP};
							`SYSCALL:	controls = {17'b0000_0000_0000_000_00,`USELESS_OP};
							`BREAK:		controls = {17'b0000_0000_0000_000_00,`USELESS_OP}; // 以上有10条指令
							// `NOP:		controls = 21'b0000_0000_0000_000_00_0000;
							`MFHI,`MFLO,`AND,`OR,`XOR,`NOR,`ADD,`ADDU,`SUB,`SUBU,`SLT,
								`SLTU,`SLL,`SRL,`SRA,`SLLV,`SRLV,`SRAV: // 此处有18条指令
										controls = {17'b1100_0000_0000_000_00,`R_TYPE_OP};
							default:	invalid  = 1;
						endcase
				`ADDI:		controls = {17'b1010_0000_0000_000_00,`ADDI_OP}; // ADDI
				`ADDIU:		controls = {17'b1010_0000_0000_000_00,`ADDIU_OP}; // ADDIU
				`SLTI:		controls = {17'b1010_0000_0000_000_00,`SLTI_OP}; // SLTI
				`SLTIU:		controls = {17'b1010_0000_0000_000_00,`SLTIU_OP}; // SLTIU
				`ANDI:		controls = {17'b1010_0001_0000_000_00,`ANDI_OP}; // ANDI
				`ORI:		controls = {17'b1010_0001_0000_000_00,`ORI_OP}; // ORI
				`XORI:		controls = {17'b1010_0001_0000_000_00,`XORI_OP}; // XORI
				`LUI:		controls = {17'b1010_0001_0000_000_00,`LUI_OP}; // LUI
				`LB:		controls = {17'b1010_0100_0000_000_00,`ADDI_OP}; // LB 暂时采用addi  不知是否有错 可全部更换为`MEM_OP?
        	    `LBU:		controls = {17'b1010_0100_0001_000_00,`ADDI_OP}; // LBU
				`LH:		controls = {17'b1010_0100_0010_000_00,`ADDI_OP}; // LH
				`LHU:		controls = {17'b1010_0100_0011_000_00,`ADDI_OP}; // LHU
				`LW:		controls = {17'b1010_0100_0100_000_00,`ADDI_OP}; // LW
				`SB:		controls = {17'b0010_1000_0101_000_00,`ADDI_OP}; // SB
				`SH:		controls = {17'b0010_1000_0110_000_00,`ADDI_OP}; // SH
				`SW:		controls = {17'b0010_1000_0111_000_00,`ADDI_OP}; // SW
				`J:			controls = {17'b0000_0010_0000_000_00,`USELESS_OP}; // J
				`JAL:		controls = {17'b1000_0000_0000_110_00,`ADDI_OP}; // JAL
				`BEQ:		controls = {17'b0001_0000_0000_000_00,`USELESS_OP}; // BEQ
				`BNE:		controls = {17'b0001_0000_0000_000_00,`USELESS_OP}; // BNE
				`BGTZ:		controls = {17'b0001_0000_0000_000_00,`USELESS_OP}; // BGTZ
				`BLEZ:		controls = {17'b0001_0000_0000_000_00,`USELESS_OP}; // BLEZ  22条指令
				`REGIMM_INST:
					case(rt)
						`BLTZ:		controls = {17'b0001_0000_0000_00000,`USELESS_OP}; // BLTZ
						`BGEZAL:	controls = {17'b1001_0000_0000_10000,`ADDI_OP}; // BGEZAL
						`BLTZAL:	controls = {17'b1001_0000_0000_10000,`ADDI_OP}; // BLTZAL
						`BGEZ:		controls = {17'b0001_0000_0000_00000,`USELESS_OP}; // BGEZ
						default:	invalid  = 1;
					endcase
				`SPECIAL3_INST:
					case(rs)
						`MTC0:		controls = {17'b0000_0000_0000_000_10,`ADDI_OP}; // 写cp0寄存器
						`MFC0:		controls = {17'b1000_0000_0000_000_01,`USELESS_OP}; // 读cp0寄存器
						`ERET:		controls = {17'b0000_0000_0000_000_00,`USELESS_OP}; // 以上7条指令
						default:	invalid  = 1;
					endcase
				default:  			invalid  = 1;//illegal op	controls = 19'b0000_0000_0xxx_000_0000
			endcase
		// end
	end
endmodule
