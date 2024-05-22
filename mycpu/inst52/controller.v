`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: controller
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


module controller(
	input wire clk,rst,
	//decode stage
	input wire[5:0] opD,functD,
	input wire[4:0] rsD,
	input wire[4:0] rtD,
	output wire pcsrcD,branchD,
	input wire equalD,
	output wire jumpD,
	/*�����ź�*/
	output wire memwriteD,
	output wire jalD,jrD,invalidD,
	/*����*/
	
	//execute stage
	input wire stallE,flushE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,	
	output wire[4:0] alucontrolE,
	/*�����ź�*/
	output wire isunsignE,hiloE,pcto31E,jrE,cp0wE,
	/*����*/

	//mem stage
	output wire memtoregM,
	   memwriteM, // ȡ���˴�memwriteM�Ĵ���     SOC�����ֵ�Ĵ���
	   regwriteM,
	/*�����ź�*/
	output wire cp0wM,cp0rM,
	input wire flushM,
	output wire[2:0] memopM,
	/*����*/

	//write back stage
	output wire memtoregW,regwriteW,
	input wire flushW, // +++
	
	// axi
	input wire inst_on,stallM,stallW

    );
	
	//decode stage
	wire[3:0] aluopD; //��ʱ������4λ
	wire memtoregD,alusrcD,
		regdstD,regwriteD;
	wire[4:0] alucontrolD;
	/*�����ź�*/
	wire isunsignD;
	wire[2:0] memopD;
	wire hiloD;
	wire pcto31D;
	wire cp0wD;
	wire cp0rD;
	wire cp0rE;

	//execute stage
	wire memwriteE;
	/*�����ź�*/
	wire[2:0] memopE;
	
	//mem stage
	/*�����ź�*/
//	wire pcto31M;

	maindec md(
		opD,functD,rsD,rtD,
		inst_on, // +++
		memtoregD,memwriteD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,
		aluopD,
		/*�����ź�*/
		isunsignD,
		hiloD,
		pcto31D,jalD,jrD,invalidD,cp0wD,cp0rD,
		memopD
		);
	aludec ad(functD,aluopD,alucontrolD);

	assign pcsrcD = branchD & equalD;

	//pipeline registers
	flopenrc #(19) regE(
		clk,
		rst,
		~stallE,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,isunsignD,hiloD,pcto31D,jrD,cp0wD,cp0rD,memopD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,isunsignE,hiloE,pcto31E,jrE,cp0wE,cp0rE,memopE}
		);
	flopenrc #(8) regM(
		clk,rst,~stallM,flushM, // +++
		{memtoregE,memwriteE,regwriteE,cp0wE,cp0rE,memopE},
		{memtoregM,memwriteM,regwriteM,cp0wM,cp0rM,memopM}
		);
	flopenrc #(2) regW(
		clk,rst,~stallW,flushW, // +++
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
		);
//	 flopenrc #(1) regW(
//	 	clk,rst,~stallW,flushW, // +++
//	 	{memtoregM},
//	 	{memtoregW}
//	 	);
//	 flopenrc_rw #(1) reg_rwW(
//	 	clk,rst,~stallW,flushW,
//	 	regwriteM,
//	 	regwriteW
//	 	);
endmodule
