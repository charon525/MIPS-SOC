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
	/*增添信号*/
	output wire memwriteD,
	output wire jalD,jrD,invalidD,
	/*结束*/
	
	//execute stage
	input wire stallE,flushE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,	
	output wire[4:0] alucontrolE,
	/*增添信号*/
	output wire isunsignE,hiloE,pcto31E,jrE,cp0wE,
	/*结束*/

	//mem stage
	output wire memtoregM,
	   memwriteM, // 取消此处memwriteM的传输     SOC加入该值的传递
	   regwriteM,
	/*增添信号*/
	output wire cp0wM,cp0rM,
	input wire flushM,
	output wire[2:0] memopM,
	/*结束*/

	//write back stage
	output wire memtoregW,regwriteW,
	input wire flushW, // +++
	
	// axi
	input wire inst_on,stallM,stallW

    );
	
	//decode stage
	wire[3:0] aluopD; //暂时扩充至4位
	wire memtoregD,alusrcD,
		regdstD,regwriteD;
	wire[4:0] alucontrolD;
	/*增添信号*/
	wire isunsignD;
	wire[2:0] memopD;
	wire hiloD;
	wire pcto31D;
	wire cp0wD;
	wire cp0rD;
	wire cp0rE;

	//execute stage
	wire memwriteE;
	/*增添信号*/
	wire[2:0] memopE;
	
	//mem stage
	/*增添信号*/
//	wire pcto31M;

	maindec md(
		opD,functD,rsD,rtD,
		inst_on, // +++
		memtoregD,memwriteD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,
		aluopD,
		/*增添信号*/
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
