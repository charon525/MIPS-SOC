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
	output wire data_en, // �趨��ֵ������
//	output wire memwriteM,
	/*�����ź�*/
	output wire[3:0] sel,
	/*����*/
	output wire[31:0] aluoutM,writedataM,
	input wire[31:0] readdataM,
	
	// ����SOC
	output wire[31:0] pcW,
	output wire regwriteW,
	output wire[4:0] writeregW,
	output wire[31:0] resultW,
	
	// axi�ӿ�
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
    
    // axi�ӿ�
    wire stallD,stallM,stallW;
	
	wire [5:0] opD,functD;
	wire regdstE,alusrcE,pcsrcD,memtoregE,memtoregM,memtoregW,
			regwriteE,regwriteM; // regwriteW
	wire [4:0] alucontrolE;
	wire flushE,equalD;
    /*�����ź�*/
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
	/*����*/
	
	/*SOC���*/
	assign inst_en = 1'b1; // ��ʱ��˶���
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
		// ����
		memwriteD,jalD,jrD,invalidD,
		
		//execute stage
		stallE,flushE,
		memtoregE,alusrcE,
		regdstE,regwriteE,	
		alucontrolE,
		/*�����ź�*/
        isunsignE,hiloE,pcto31E,jrE,cp0wE,
	    /*����*/

		//mem stage
		memtoregM,
		memwriteM,
		regwriteM,
		/*�����ź�*/
		cp0wM,cp0rM,
		flushM,
        memopM,
	    /*����*/
		
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
		/*�����ź�*/
		memwriteD,jalD,jrD,invalidD,
		/*����*/
		equalD,
		opD,functD,
		/*�����ź�*/
		rsD,rtD,
		//execute stage
		memtoregE,
		alusrcE,regdstE,
		regwriteE,
		alucontrolE,
		/*�����ź�*/
		stallE,flushE,
		isunsignE,hiloE,pcto31E,jrE,cp0wE,
		/*����*/
		//mem stage
		memtoregM,
		regwriteM,
		aluoutM,writedataM,
		readdataM,
		/*�����ź�*/
		memopM,sel,cp0wM,cp0rM,flushM,
		/*����*/
		//writeback stage
		memtoregW,
		regwriteW,
		flushW, // +++
		
		// ����SOC
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
