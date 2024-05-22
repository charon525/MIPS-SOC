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
	/*增添信号*/
	input wire memwriteD,
	input wire jalD,jrD,invalidD,
	/*结束*/
	output wire equalD,
	output wire[5:0] opD,functD,
	output wire[4:0] rsD,rtD, // rsD用于判断cp0寄存器相关指令，rtD用于判断分支类型
	//execute stage
	input wire memtoregE,
	input wire alusrcE,regdstE,
	input wire regwriteE,
	input wire[4:0] alucontrolE,
	output wire stallE,flushE,
	/*增添信号*/
	input wire isunsignE,hiloE,pcto31E,jrE,cp0wE,
	/*结束*/
	//mem stage
	input wire memtoregM,
	input wire regwriteM,
	output wire[31:0] aluoutM,writedataM2,
	input wire[31:0] readdataM,
	/*增添信号*/
	input wire[2:0] memopM,
	output wire[3:0] sel,
	input wire cp0wM,cp0rM,
	output wire flushM, // +++
	/*结束*/
	
	//writeback stage
	input wire memtoregW,
	input wire regwriteW,
	output wire flushW, // +++
	
	// 连接SOC
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
	/*增添信号*/
	wire [63:0] hilo_in,hilo_out;
	wire [63:0] hilo_out_tmp;
	// 除法相关
	wire is_div;
	wire div_ready,div_start,div_signed;
	wire [63:0] div_result;
	/*结束*/
	
	//mem stage
	wire [4:0] writeregM;
	//增添
	wire [4:0] rdM;
	
	//writeback stage
//	wire [4:0] writeregW;
	wire [31:0] aluoutW,readdataW;
//	wire[31:0] resultW;

    // 增添信号
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
		stallF_tmp,flushF, // 增添flushF
		//decode stage
		rsD,rtD,
		branchD,
		jrD, // 增添
		forwardaD,forwardbD,
		stallD_tmp,flushD, // 增添flushD
		//execute stage
		rsE,rtE,
		writeregE,
		regwriteE,
		memtoregE,
		is_div,div_ready, // 增添
		forwardaE,forwardbE,
		stallE_tmp,flushE, // 增添
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		flushM, // 增添
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
		jumpD | jalD,pcnextFD); // 对于jump或jal指令

	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);
	
	/*分支跳转指令*/
	wire[31:0] pcnextFFD; // 最终选择后的pc
	mux2 #(32) pcjrmux(pcnextFD, srca2D, jrD, pcnextFFD); // jr指令

	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,(flushF | flush) ,pcnextFFD,newpc,pcF); //  & ~inst_on
	adder pcadd1(pcF,32'b100,pcplus4F);
	
	/*取指令阶段异常标记以及延迟槽标记*/
	wire[7:0] exceptF;
	assign exceptF = (pcF[1:0]==2'b00) ? 8'b0000_0000 : 8'b1000_0000;
	wire is_in_delayslotF;
	assign is_in_delayslotF =  branchD | jumpD | jrD | jalD;
	
	//decode stage
	// D存储器传递参数
	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	/*传递pc*/
	wire [31:0] pcD;
	flopenrc #(32) r3D(clk,rst,~stallD,flushD,pcF,pcD);
	/*传递异常相关参数*/
	wire[7:0] exceptD;
	wire is_in_delayslotD;
	flopenrc #(8) r4D(clk,rst,~stallD,flushD,exceptF,exceptD);
	flopenrc #(1) r5D(clk,rst,~stallD,flushD,is_in_delayslotF,is_in_delayslotD);
	
	/*对于i型指令处理立即数*/ 
	signext se(instrD[15:0],signimmD); // 算术扩充（用符号位填充至32位）
	sl2 immsh(signimmD,signimmshD); // 左移两位
	/*增添无符号立即数扩展*/
	wire [31:0] unsignimmD;
	assign unsignimmD = {{16{1'b0}},instrD[15:0]};
	/*立即数处理结束*/ 
	adder pcadd2(pcplus4D,signimmshD,pcbranchD); // 加法器计算branch跳转地址
	/*冒险处理，选择对应的操作数*/ 
	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	/*比较俩数，提前判断是否相等*/ 
	eqcmp comp(srca2D,srcb2D,opD,rtD,equalD);
 
	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	// 增添
	wire[4:0] saD;
	assign saD = instrD[10:6];
	// 增添例外处理标签赋值
	wire syscallD,breakD,eretD;
	assign syscallD = (opD==6'b000000 && functD == 6'b001100);
	assign breakD = (opD==6'b000000 && functD == 6'b001101);
	assign eretD = (instrD == 32'b0100_0010_0000_0000_0000_0000_0001_1000);

	//     ID到IE阶段
	flopenrc #(32) r1E(clk,rst,~stallE,flushE,srcaD,srcaE);
	flopenrc #(32) r2E(clk,rst,~stallE,flushE,srcbD,srcbE);
	flopenrc #(32) r3E(clk,rst,~stallE,flushE,signimmD,signimmE);
	flopenrc #(5) r4E(clk,rst,~stallE,flushE,rsD,rsE);
	flopenrc #(5) r5E(clk,rst,~stallE,flushE,rtD,rtE);
	flopenrc #(5) r6E(clk,rst,~stallE,flushE,rdD,rdE);
	/*增添无符号立即数的传递*/
	wire [31:0] unsignimmE;
	flopenrc #(32) r7E(clk,rst,~stallE,flushE,unsignimmD,unsignimmE);
	/*增添存储器写信号传递*/
	wire memwriteE;
	flopenrc #(1) r8E(clk,rst,~stallE,flushE,memwriteD,memwriteE);
	/*增添移位信号传递*/
	wire [4:0] saE;
	flopenrc #(5) r9E(clk,rst,~stallE,flushE,saD,saE);
	/*pc传递*/
	wire [31:0] pcE;
	flopenrc #(32) r10E(clk,rst,~stallE,flushE,pcD,pcE);
	/*传递异常相关参数*/
	wire[7:0] exceptE;
	flopenrc #(8) r11E(clk,rst,~stallE,flushE,{exceptD[7],syscallD,breakD,eretD,invalidD,exceptD[2:0]},exceptE);
    wire is_in_delayslotE;
    flopenrc #(1) r12E(clk,rst,~stallE,flushE,is_in_delayslotD,is_in_delayslotE);

	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	/*增添选择立即数类型部分*/
	wire [31:0] immE;
	mux2 #(32) immmux(signimmE,unsignimmE,isunsignE,immE);
	/*结束*/
	mux2 #(32) srcbmux(srcb2E,immE,alusrcE,srcb3E);
	
	/*跳转时选择操作数*/
	wire [31:0] srca3E,srcb4E;
	mux2 #(32) srcamux(srca2E,pcE,pcto31E | jrE,srca3E);
	mux2 #(32) srcbmux2(srcb3E,8,pcto31E | jrE,srcb4E);
	/*写cp0寄存器时选择操作数，此时rs选择0，rt默认读出的值*/
	wire [31:0] srca4E;
	mux2 #(32) srcamux2(srca3E,0,cp0wE,srca4E);
	// 增添溢出标记
	wire overflow;
	alu alu(srca4E,srcb4E,saE,alucontrolE,aluoutE,hilo_in,hilo_out_tmp,overflow);
	// 跳转时写寄存器选择
	wire[4:0] writeregtmp;
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregtmp);
	mux2 #(5) wrmux2(writeregtmp,31,pcto31E,writeregE);
	
	// 除法相关
	assign is_div = alucontrolE == `DIV_CONTROL | alucontrolE == `DIVU_CONTROL;
	assign div_signed = alucontrolE == `DIV_CONTROL;
	assign div_start = is_div & ~div_ready;
	div div(clk,rst,div_signed,srca3E,srcb4E,div_start,1'b0,div_result,div_ready);
	mux2 #(64) hilomux(hilo_out_tmp,div_result,div_ready,hilo_out);
	
	/*增添hilo寄存器部分*/
	hilo_reg hilo(clk,rst,flushE ? 0 : (is_div ? hiloE&div_ready : hiloE),hilo_out[63:32],hilo_out[31:0],hilo_in[63:32],hilo_in[31:0]);

	//mem stage
	wire [31:0] writedataM;
	flopenrc #(32) r1M(clk,rst,~stallM,flushM,srcb2E,writedataM);
	/*增添选择器，使得可将cp0寄存器中的值存入通用寄存器中（或存入存储器？）*/
	wire[31:0] aluoutM_tmp;
	flopenrc #(32) r2M(clk,rst,~stallM,flushM,aluoutE,aluoutM_tmp);
	mux2 #(32) cp0mux(aluoutM_tmp,data_o,cp0rM,aluoutM);
	
	flopenrc #(5) r3M(clk,rst,~stallM,flushM,writeregE,writeregM);
	
	/*增添存储器写信号传递*/
	wire memwriteM;
	flopenrc #(1) r4M(clk,rst,~stallM,flushM,memwriteE,memwriteM);
    /*pc传递*/
	wire [31:0] pcM;
	flopenrc #(32) r5M(clk,rst,~stallM,flushM,pcE,pcM);
	/*处理memwriteM信号*/
	wire adel; // 读数据地址例外
	// wire ades; // 写数据地址例外
	wire[31:0] bad_addr; // 错误数据地址
    memcontr memctr(memwriteM,memopM,aluoutM,pcM,writedataM,writedataM2,sel,adel,ades,bad_addr);
    wire [1:0] addrchooseM; // 选择字节、半字、字
    assign addrchooseM = aluoutM[1:0];
    /*传递异常相关参数*/
    wire[7:0] exceptM;
    flopenrc #(8) r6M(clk,rst,~stallM,flushM,{exceptE[7:3],overflow,exceptE[1:0]},exceptM);
    wire is_in_delayslotM;
    flopenrc #(1) r7M(clk,rst,~stallM,flushM,is_in_delayslotE,is_in_delayslotM);
    flopenrc #(5) r8M(clk,rst,~stallM,flushM,rdE,rdM);
    // assign exceptM[1] = ades;
    wire[`RegBus] status_o;
    wire[`RegBus] cause_o;
    exception exp(rst,exceptM,ades,adel,status_o,cause_o,except_type);
    
    /*处理例外*/
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
	/*增添存储器控制信号的传递*/
	wire [2:0] memopW;
	flopenrc #(3) r4W(clk,rst,~stallW,flushW,memopM,memopW);
	/*根据addrchoose选择读哪部分*/
	wire [1:0] addrchooseW;
	flopenrc #(2) r5W(clk,rst,~stallW,flushW,addrchooseM,addrchooseW);
	/*根据memop处理读出的数据*/
	wire [31:0] readdata_tmp;
	memdec memdec(readdataW,memopW,addrchooseW,readdata_tmp);
	/*pc传递*/
//	wire[31:0] pcW;
	flopenrc #(32) r6W(clk,rst,~stallW,flushW,pcM,pcW);
	
	flopenrc #(5) r3W(clk,rst,~stallW,flushW,writeregM,writeregW);
	mux2 #(32) resmux(aluoutW,readdata_tmp,memtoregW,resultW);
    
endmodule
