`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
// Design Name: 
// Module Name: mips
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


module mips(
	input wire clk,rst,
	output wire inst_en,
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	output wire data_en, // 需定义值！！！
//	output wire memwriteM,
	/*增添信号*/
	output wire[3:0] sel,
	/*结束*/
	output wire[31:0] aluoutM,writedataM,
	input wire[31:0] readdataM,
	
	// 连接SOC
	output wire[31:0] pcW,
	output wire regwriteW,
	output wire[4:0] writeregW,
	output wire[31:0] resultW,
	
	// axi接口
//	output reg inst_req,
//	input wire inst_addr_ok,
//	input wire inst_data_ok,
//	output reg data_req,
//	input wire data_addr_ok,
//	input wire data_data_ok,
	input wire inst_on,data_on,
	output wire longstall,
	output wire flushF,
	input wire flush,

	// d_cache
	output wire ades
    );
    
    // axi接口
    wire stallD,stallM,stallW;
	
	wire [5:0] opD,functD;
	wire regdstE,alusrcE,pcsrcD,memtoregE,memtoregM,memtoregW,
			regwriteE,regwriteM; // regwriteW
	wire [4:0] alucontrolE;
	wire flushE,equalD;
    /*增添信号*/
	wire isunsignE;
	wire[2:0] memopM;
	wire memwriteD;
	wire hiloE;
	wire[4:0] rsD,rtD;
	wire branchD,jumpD;
	wire jalD,jrD;
	wire pcto31E,jrE;
	wire stallE;
	wire invalidD;
	wire cp0wE,cp0wM,cp0rM;
	/*结束*/
	
	/*SOC添加*/
	assign inst_en = 1'b1; // 暂时如此定义
	wire memwriteM;
	assign data_en = memwriteM | memtoregM;
	wire flushM,flushW;
//    assign data_en = 1'b1;
    
	controller c(
		clk,rst,
		//decode stage
		opD,functD,
		rsD,
		rtD,
		pcsrcD,branchD,equalD,jumpD,
		// 增添
		memwriteD,jalD,jrD,invalidD,
		
		//execute stage
		stallE,flushE,
		memtoregE,alusrcE,
		regdstE,regwriteE,	
		alucontrolE,
		/*增添信号*/
        isunsignE,hiloE,pcto31E,jrE,cp0wE,
	    /*结束*/

		//mem stage
		memtoregM,
		memwriteM,
		regwriteM,
		/*增添信号*/
		cp0wM,cp0rM,
		flushM,
        memopM,
	    /*结束*/
		
		//write back stage
		memtoregW,regwriteW,flushW,
		
		// axi
		inst_on,stallM,stallW
		);
	datapath dp(
		clk,rst,
		//fetch stage
		pcF,
		instrF,
		//decode stage
		pcsrcD,branchD,
		jumpD,
		/*增添信号*/
		memwriteD,jalD,jrD,invalidD,
		/*结束*/
		equalD,
		opD,functD,
		/*增添信号*/
		rsD,rtD,
		//execute stage
		memtoregE,
		alusrcE,regdstE,
		regwriteE,
		alucontrolE,
		/*增添信号*/
		stallE,flushE,
		isunsignE,hiloE,pcto31E,jrE,cp0wE,
		/*结束*/
		//mem stage
		memtoregM,
		regwriteM,
		aluoutM,writedataM,
		readdataM,
		/*增添信号*/
		memopM,sel,cp0wM,cp0rM,flushM,
		/*结束*/
		//writeback stage
		memtoregW,
		regwriteW,
		flushW, // +++
		
		// 连接SOC
		pcW,
		writeregW,
		resultW,
		
		// axi
		inst_on,
		data_on,
		stallM,stallW,
		longstall,
		flushF,
		flush,

		// d_cache
		ades

	    );
	
endmodule
