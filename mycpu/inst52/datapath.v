`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 15:12:22
// Design Name: 
// Module Name: datapath
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
module datapath(
	input wire clk,rst,
	//fetch stage
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	//decode stage
	input wire pcsrcD,branchD,
	input wire jumpD,
	/*�����ź�*/
	input wire memwriteD,
	input wire jalD,jrD,invalidD,
	/*����*/
	output wire equalD,
	output wire[5:0] opD,functD,
	output wire[4:0] rsD,rtD, // rsD�����ж�cp0�Ĵ������ָ�rtD�����жϷ�֧����
	//execute stage
	input wire memtoregE,
	input wire alusrcE,regdstE,
	input wire regwriteE,
	input wire[4:0] alucontrolE,
	output wire stallE,flushE,
	/*�����ź�*/
	input wire isunsignE,hiloE,pcto31E,jrE,cp0wE,
	/*����*/
	//mem stage
	input wire memtoregM,
	input wire regwriteM,
	output wire[31:0] aluoutM,writedataM2,
	input wire[31:0] readdataM,
	/*�����ź�*/
	input wire[2:0] memopM,
	output wire[3:0] sel,
	input wire cp0wM,cp0rM,
	output wire flushM, // +++
	/*����*/
	
	//writeback stage
	input wire memtoregW,
	input wire regwriteW,
	output wire flushW, // +++
	
	// ����SOC
	output wire[31:0] pcW,
	output wire[4:0] writeregW,
	output wire[31:0] resultW,
	
	// axi
	input wire inst_on,
	input wire data_on,
//	output wire stallF,
//	output wire stallD,
	output wire stallM,
	output wire stallW,
	output wire longstall,
	output wire flushF,
	input wire flush,

	// d_cache
	output wire ades
	
    );
	
	//fetch stage
	wire stallF;
	//FD
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD;
	
	//decode stage
	wire [31:0] pcplus4D,instrD;
	wire forwardaD,forwardbD;
	wire [4:0] rdD;
	wire flushD,stallD;   // stallD   --- 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	
	//execute stage
	wire [1:0] forwardaE,forwardbE;
	wire [4:0] rsE,rtE,rdE;
	wire [4:0] writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE;
	/*�����ź�*/
	wire [63:0] hilo_in,hilo_out;
	wire [63:0] hilo_out_tmp;
	// �������
	wire is_div;
	wire div_ready,div_start,div_signed;
	wire [63:0] div_result;
	/*����*/
	
	//mem stage
	wire [4:0] writeregM;
	//����
	wire [4:0] rdM;
	
	//writeback stage
//	wire [4:0] writeregW;
	wire [31:0] aluoutW,readdataW;
//	wire[31:0] resultW;

    // �����ź�
    wire[31:0] except_type;
    wire[31:0] epc_o;
    wire[31:0] newpc;
    wire[`RegBus] data_o;
//    wire flushF; // ,flushM,flushW
    
    // axi
    wire stallF_tmp,stallD_tmp,stallE_tmp;
    assign stallF = stallF_tmp | data_on | inst_on;
    assign stallD = stallD_tmp | data_on | inst_on;
    assign stallE = stallE_tmp | data_on; //  | inst_on
    assign stallM = data_on; //  | inst_on
    assign stallW = data_on; //  | inst_on
    assign longstall = data_on | inst_on | stallE_tmp;
    
    
	//hazard detection
	hazard h(
		//fetch stage
		stallF_tmp,flushF, // ����flushF
		//decode stage
		rsD,rtD,
		branchD,
		jrD, // ����
		forwardaD,forwardbD,
		stallD_tmp,flushD, // ����flushD
		//execute stage
		rsE,rtE,
		writeregE,
		regwriteE,
		memtoregE,
		is_div,div_ready, // ����
		forwardaE,forwardbE,
		stallE_tmp,flushE, // ����
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		flushM, // ����
		except_type,epc_o,newpc,
		//write back stage
		writeregW,
		regwriteW,
		flushW
		);

	//next PC logic (operates in fetch an decode)
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);
	mux2 #(32) pcmux(pcnextbrFD,
		{pcplus4D[31:28],instrD[25:0],2'b00},
		jumpD | jalD,pcnextFD); // ����jump��jalָ��

	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);
	
	/*��֧��תָ��*/
	wire[31:0] pcnextFFD; // ����ѡ����pc
	mux2 #(32) pcjrmux(pcnextFD, srca2D, jrD, pcnextFFD); // jrָ��

	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,(flushF | flush) ,pcnextFFD,newpc,pcF); //  & ~inst_on
	adder pcadd1(pcF,32'b100,pcplus4F);
	
	/*ȡָ��׶��쳣����Լ��ӳٲ۱��*/
	wire[7:0] exceptF;
	assign exceptF = (pcF[1:0]==2'b00) ? 8'b0000_0000 : 8'b1000_0000;
	wire is_in_delayslotF;
	assign is_in_delayslotF =  branchD | jumpD | jrD | jalD;
	
	//decode stage
	// D�洢�����ݲ���
	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	/*����pc*/
	wire [31:0] pcD;
	flopenrc #(32) r3D(clk,rst,~stallD,flushD,pcF,pcD);
	/*�����쳣��ز���*/
	wire[7:0] exceptD;
	wire is_in_delayslotD;
	flopenrc #(8) r4D(clk,rst,~stallD,flushD,exceptF,exceptD);
	flopenrc #(1) r5D(clk,rst,~stallD,flushD,is_in_delayslotF,is_in_delayslotD);
	
	/*����i��ָ���������*/ 
	signext se(instrD[15:0],signimmD); // �������䣨�÷���λ�����32λ��
	sl2 immsh(signimmD,signimmshD); // ������λ
	/*�����޷�����������չ*/
	wire [31:0] unsignimmD;
	assign unsignimmD = {{16{1'b0}},instrD[15:0]};
	/*�������������*/ 
	adder pcadd2(pcplus4D,signimmshD,pcbranchD); // �ӷ�������branch��ת��ַ
	/*ð�մ���ѡ���Ӧ�Ĳ�����*/ 
	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	/*�Ƚ���������ǰ�ж��Ƿ����*/ 
	eqcmp comp(srca2D,srcb2D,opD,rtD,equalD);
 
	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	// ����
	wire[4:0] saD;
	assign saD = instrD[10:6];
	// �������⴦���ǩ��ֵ
	wire syscallD,breakD,eretD;
	assign syscallD = (opD==6'b000000 && functD == 6'b001100);
	assign breakD = (opD==6'b000000 && functD == 6'b001101);
	assign eretD = (instrD == 32'b0100_0010_0000_0000_0000_0000_0001_1000);

	//     ID��IE�׶�
	flopenrc #(32) r1E(clk,rst,~stallE,flushE,srcaD,srcaE);
	flopenrc #(32) r2E(clk,rst,~stallE,flushE,srcbD,srcbE);
	flopenrc #(32) r3E(clk,rst,~stallE,flushE,signimmD,signimmE);
	flopenrc #(5) r4E(clk,rst,~stallE,flushE,rsD,rsE);
	flopenrc #(5) r5E(clk,rst,~stallE,flushE,rtD,rtE);
	flopenrc #(5) r6E(clk,rst,~stallE,flushE,rdD,rdE);
	/*�����޷����������Ĵ���*/
	wire [31:0] unsignimmE;
	flopenrc #(32) r7E(clk,rst,~stallE,flushE,unsignimmD,unsignimmE);
	/*����洢��д�źŴ���*/
	wire memwriteE;
	flopenrc #(1) r8E(clk,rst,~stallE,flushE,memwriteD,memwriteE);
	/*������λ�źŴ���*/
	wire [4:0] saE;
	flopenrc #(5) r9E(clk,rst,~stallE,flushE,saD,saE);
	/*pc����*/
	wire [31:0] pcE;
	flopenrc #(32) r10E(clk,rst,~stallE,flushE,pcD,pcE);
	/*�����쳣��ز���*/
	wire[7:0] exceptE;
	flopenrc #(8) r11E(clk,rst,~stallE,flushE,{exceptD[7],syscallD,breakD,eretD,invalidD,exceptD[2:0]},exceptE);
    wire is_in_delayslotE;
    flopenrc #(1) r12E(clk,rst,~stallE,flushE,is_in_delayslotD,is_in_delayslotE);

	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	/*����ѡ�����������Ͳ���*/
	wire [31:0] immE;
	mux2 #(32) immmux(signimmE,unsignimmE,isunsignE,immE);
	/*����*/
	mux2 #(32) srcbmux(srcb2E,immE,alusrcE,srcb3E);
	
	/*��תʱѡ�������*/
	wire [31:0] srca3E,srcb4E;
	mux2 #(32) srcamux(srca2E,pcE,pcto31E | jrE,srca3E);
	mux2 #(32) srcbmux2(srcb3E,8,pcto31E | jrE,srcb4E);
	/*дcp0�Ĵ���ʱѡ�����������ʱrsѡ��0��rtĬ�϶�����ֵ*/
	wire [31:0] srca4E;
	mux2 #(32) srcamux2(srca3E,0,cp0wE,srca4E);
	// ����������
	wire overflow;
	alu alu(srca4E,srcb4E,saE,alucontrolE,aluoutE,hilo_in,hilo_out_tmp,overflow);
	// ��תʱд�Ĵ���ѡ��
	wire[4:0] writeregtmp;
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregtmp);
	mux2 #(5) wrmux2(writeregtmp,31,pcto31E,writeregE);
	
	// �������
	assign is_div = alucontrolE == `DIV_CONTROL | alucontrolE == `DIVU_CONTROL;
	assign div_signed = alucontrolE == `DIV_CONTROL;
	assign div_start = is_div & ~div_ready;
	div div(clk,rst,div_signed,srca3E,srcb4E,div_start,1'b0,div_result,div_ready);
	mux2 #(64) hilomux(hilo_out_tmp,div_result,div_ready,hilo_out);
	
	/*����hilo�Ĵ�������*/
	hilo_reg hilo(clk,rst,flushE ? 0 : (is_div ? hiloE&div_ready : hiloE),hilo_out[63:32],hilo_out[31:0],hilo_in[63:32],hilo_in[31:0]);

	//mem stage
	wire [31:0] writedataM;
	flopenrc #(32) r1M(clk,rst,~stallM,flushM,srcb2E,writedataM);
	/*����ѡ������ʹ�ÿɽ�cp0�Ĵ����е�ֵ����ͨ�üĴ����У������洢������*/
	wire[31:0] aluoutM_tmp;
	flopenrc #(32) r2M(clk,rst,~stallM,flushM,aluoutE,aluoutM_tmp);
	mux2 #(32) cp0mux(aluoutM_tmp,data_o,cp0rM,aluoutM);
	
	flopenrc #(5) r3M(clk,rst,~stallM,flushM,writeregE,writeregM);
	
	/*����洢��д�źŴ���*/
	wire memwriteM;
	flopenrc #(1) r4M(clk,rst,~stallM,flushM,memwriteE,memwriteM);
    /*pc����*/
	wire [31:0] pcM;
	flopenrc #(32) r5M(clk,rst,~stallM,flushM,pcE,pcM);
	/*����memwriteM�ź�*/
	wire adel; // �����ݵ�ַ����
	// wire ades; // д���ݵ�ַ����
	wire[31:0] bad_addr; // �������ݵ�ַ
    memcontr memctr(memwriteM,memopM,aluoutM,pcM,writedataM,writedataM2,sel,adel,ades,bad_addr);
    wire [1:0] addrchooseM; // ѡ���ֽڡ����֡���
    assign addrchooseM = aluoutM[1:0];
    /*�����쳣��ز���*/
    wire[7:0] exceptM;
    flopenrc #(8) r6M(clk,rst,~stallM,flushM,{exceptE[7:3],overflow,exceptE[1:0]},exceptM);
    wire is_in_delayslotM;
    flopenrc #(1) r7M(clk,rst,~stallM,flushM,is_in_delayslotE,is_in_delayslotM);
    flopenrc #(5) r8M(clk,rst,~stallM,flushM,rdE,rdM);
    // assign exceptM[1] = ades;
    wire[`RegBus] status_o;
    wire[`RegBus] cause_o;
    exception exp(rst,exceptM,ades,adel,status_o,cause_o,except_type);
    
    /*��������*/
    wire[`RegBus] count_o;
    wire[`RegBus] compare_o;
    wire[`RegBus] config_o;
    wire[`RegBus] prid_o;
    wire[`RegBus] badvaddr;
    wire timer_int_o;
    cp0_reg cp0(.clk(clk),.rst(rst),.we_i(cp0wM),.waddr_i(rdM),.raddr_i(rdM),
        .data_i(aluoutM),.int_i(6'b000000),.excepttype_i(except_type),
        .current_inst_addr_i(pcM),.is_in_delayslot_i(is_in_delayslotM),
        .bad_addr_i(bad_addr),.count_o(count_o),.data_o(data_o),
        .compare_o(compare_o),.status_o(status_o),.cause_o(cause_o),
        .epc_o(epc_o),.config_o(config_o),.prid_o(prid_o),
        .badvaddr(badvaddr),.timer_int_o(timer_int_o));
    
	//writeback stage
	flopenrc #(32) r1W(clk,rst,~stallW,flushW,aluoutM,aluoutW);
	flopenrc #(32) r2W(clk,rst,~stallW,flushW,readdataM,readdataW);
	/*����洢�������źŵĴ���*/
	wire [2:0] memopW;
	flopenrc #(3) r4W(clk,rst,~stallW,flushW,memopM,memopW);
	/*����addrchooseѡ����Ĳ���*/
	wire [1:0] addrchooseW;
	flopenrc #(2) r5W(clk,rst,~stallW,flushW,addrchooseM,addrchooseW);
	/*����memop�������������*/
	wire [31:0] readdata_tmp;
	memdec memdec(readdataW,memopW,addrchooseW,readdata_tmp);
	/*pc����*/
//	wire[31:0] pcW;
	flopenrc #(32) r6W(clk,rst,~stallW,flushW,pcM,pcW);
	
	flopenrc #(5) r3W(clk,rst,~stallW,flushW,writeregM,writeregW);
	mux2 #(32) resmux(aluoutW,readdata_tmp,memtoregW,resultW);
    
endmodule
