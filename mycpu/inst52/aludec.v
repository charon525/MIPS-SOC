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
			`ADDI_OP: 	alucontrol = `ADD_CONTROL;//add (for lw/sw/addi/ ���ַô�ָ��)
			`ADDIU_OP:	alucontrol = `ADDU_CONTROL;//addu (for addiu)
			`SLTI_OP: 	alucontrol = `SLT_CONTROL;//slti
			`SLTIU_OP:	alucontrol = `SLTU_CONTROL;//sltu (for sltiu)
			// `MEM_OP:	alucontrol = `ADD_CONTROL; //add �� ADDI_OP��ͬ
			
			`R_TYPE_OP: case (funct)
				/*�߼�����ָ���Լ���������ָ��˳������⣩*/
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

				/*��λָ��*/
				`SLL:	alucontrol = `SLL_CONTROL; // sll�߼�����
				`SRL:	alucontrol = `SRL_CONTROL; // srl�߼�����
				`SRA:	alucontrol = `SRA_CONTROL; // sra��������
				`SLLV:	alucontrol = `SLLV_CONTROL; // sllv
				`SRLV:	alucontrol = `SRLV_CONTROL; // srlv
				`SRAV:	alucontrol = `SRAV_CONTROL; // srav

				/*�����ƶ�ָ��*/
				`MFHI:	alucontrol = `MFHI_CONTROL; // MFHI
				`MFLO:	alucontrol = `MFLO_CONTROL; // MFLO
				`MTHI:	alucontrol = `MTHI_CONTROL; // MTHI
				`MTLO:	alucontrol = `MTLO_CONTROL; // MTLO

				/*�˳���ָ��*/
				`MULT:  alucontrol = `MULT_CONTROL;
				`MULTU: alucontrol = `MULTU_CONTROL;
				`DIV:	alucontrol = `DIV_CONTROL;
				`DIVU:  alucontrol = `DIVU_CONTROL;

				/*��תָ��*/
				`JALR:	alucontrol = `ADD_CONTROL;

				default:alucontrol = 5'b00000;
			endcase
			default:
			    alucontrol = 5'b00000;
		endcase
	
	end
endmodule
