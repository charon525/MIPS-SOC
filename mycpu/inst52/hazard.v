`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/22 10:23:13
// Design Name: 
// Module Name: hazard
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


module hazard(
	//fetch stage
	output wire stallF,flushF, // ����flushF
	//decode stage
	input wire[4:0] rsD,rtD,
	input wire branchD,
	input wire jrD, // ����
	output wire forwardaD,forwardbD,
	output wire stallD,flushD,
	//execute stage
	input wire[4:0] rsE,rtE,
	input wire[4:0] writeregE,
	input wire regwriteE,
	input wire memtoregE,
	input wire is_div,div_ready, // ���
	output reg[1:0] forwardaE,forwardbE,
	output wire stallE,flushE, // ���
	//mem stage
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire memtoregM,
	output wire flushM, // ���
	// �����ź�
	input wire[31:0] excepttype,
	input wire[31:0] cp0_epc,
	output reg[31:0] newpc,

	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW,
	output wire flushW // ���
    );

	wire lwstallD,branchstallD;
	
	wire jrstallD; // ����

	//forwarding sources to D stage (branch equality)
	assign forwardaD = (rsD != 0 & rsD == writeregM & regwriteM);
	assign forwardbD = (rtD != 0 & rtD == writeregM & regwriteM);
	
	//forwarding sources to E stage (ALU)

	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
		if(rsE != 0) begin
			/* code */
			if(rsE == writeregM & regwriteM) begin
				/* code */
				forwardaE = 2'b10;
			end else if(rsE == writeregW & regwriteW) begin
				/* code */
				forwardaE = 2'b01;
			end
		end
		if(rtE != 0) begin
			/* code */
			if(rtE == writeregM & regwriteM) begin
				/* code */
				forwardbE = 2'b10;
			end else if(rtE == writeregW & regwriteW) begin
				/* code */
				forwardbE = 2'b01;
			end
		end
	end

	//stalls	�˴�ɾ������assign�� #1
	assign lwstallD = memtoregE & (rtE == rsD | rtE == rtD);
	assign branchstallD = branchD &
				((regwriteE & (writeregE == rsD | writeregE == rtD) ) |
				(memtoregM & (writeregM == rsD | writeregM == rtD)) );
	assign jrstallD = jrD & ((regwriteE & writeregE == rsD) | (memtoregM & writeregM == rsD)) ;
	assign stallD = lwstallD | branchstallD | jrstallD | stallE;
	assign stallF = stallD;
	
	/*���*/
	assign stallE = is_div & ~div_ready;
		//stalling D stalls all previous stages
//	assign #1 flushE = stallD; ��������
		//stalling D flushes next stage
	// Note: not necessary to stall D stage on store
  	//       if source comes from load;
  	//       instead, another bypass network could
  	//       be added from W to M
  	
  	/*���*/
  	always@(*)begin
  	     if(excepttype!=32'b0)begin
  	         case(excepttype)
  	             32'h00000001,32'h00000004,32'h00000005,32'h00000008,
  	                 32'h00000009,32'h0000000a,32'h0000000c,32'h0000000d:
  	                     newpc = 32'hBFC00380;
  	             default:newpc = cp0_epc;
  	         endcase
  	     end
  	end
  	assign flushF = (excepttype!=0);
  	assign flushD = (excepttype!=0);
  	assign flushE = lwstallD | branchstallD | jrstallD | (excepttype!=0);
  	assign flushM = (excepttype!=0);
  	assign flushW = (excepttype!=0);
endmodule
