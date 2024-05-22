`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:27:24
// Design Name: 
// Module Name: aludec
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
module aludec(
	input wire[5:0] funct,
	input wire[3:0] aluop,
	output reg[4:0] alucontrol
    );
	always @(*) begin
		case (aluop)
		    `ANDI_OP:	alucontrol = `AND_CONTROL;//andi
		    `XORI_OP:	alucontrol = `XOR_CONTROL;//xor (for xori)
		    `ORI_OP:	alucontrol = `OR_CONTROL;//or (for ori)
		    `LUI_OP:	alucontrol = `LUI_CONTROL;//lui
			`ADDI_OP: 	alucontrol = `ADD_CONTROL;//add (for lw/sw/addi/ 各种访存指令)
			`ADDIU_OP:	alucontrol = `ADDU_CONTROL;//addu (for addiu)
			`SLTI_OP: 	alucontrol = `SLT_CONTROL;//slti
			`SLTIU_OP:	alucontrol = `SLTU_CONTROL;//sltu (for sltiu)
			// `MEM_OP:	alucontrol = `ADD_CONTROL; //add 与 ADDI_OP相同
			
			`R_TYPE_OP: case (funct)
				/*逻辑运算指令以及算术运算指令（乘除法除外）*/
				`ADD:	alucontrol = `ADD_CONTROL; //add
				`ADDU:	alucontrol = `ADDU_CONTROL; //addu
				`SUB:	alucontrol = `SUB_CONTROL; //sub
				`SUBU:	alucontrol = `SUBU_CONTROL; //subu
				`AND:	alucontrol = `AND_CONTROL; //and
				`OR:	alucontrol = `OR_CONTROL; //or
				`XOR:	alucontrol = `XOR_CONTROL; //xor
				`NOR:	alucontrol = `NOR_CONTROL; //nor
				`SLT:	alucontrol = `SLT_CONTROL; //slt
				`SLTU:	alucontrol = `SLTU_CONTROL; //sltu

				/*移位指令*/
				`SLL:	alucontrol = `SLL_CONTROL; // sll逻辑左移
				`SRL:	alucontrol = `SRL_CONTROL; // srl逻辑右移
				`SRA:	alucontrol = `SRA_CONTROL; // sra算数右移
				`SLLV:	alucontrol = `SLLV_CONTROL; // sllv
				`SRLV:	alucontrol = `SRLV_CONTROL; // srlv
				`SRAV:	alucontrol = `SRAV_CONTROL; // srav

				/*数据移动指令*/
				`MFHI:	alucontrol = `MFHI_CONTROL; // MFHI
				`MFLO:	alucontrol = `MFLO_CONTROL; // MFLO
				`MTHI:	alucontrol = `MTHI_CONTROL; // MTHI
				`MTLO:	alucontrol = `MTLO_CONTROL; // MTLO

				/*乘除法指令*/
				`MULT:  alucontrol = `MULT_CONTROL;
				`MULTU: alucontrol = `MULTU_CONTROL;
				`DIV:	alucontrol = `DIV_CONTROL;
				`DIVU:  alucontrol = `DIVU_CONTROL;

				/*跳转指令*/
				`JALR:	alucontrol = `ADD_CONTROL;

				default:alucontrol = 5'b00000;
			endcase
			default:
			    alucontrol = 5'b00000;
		endcase
	
	end
endmodule
