//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2014 leishangwen@163.com                       ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
// Module:  div
// File:    div.v
// Author:  Lei Silei
// E-mail:  leishangwen@163.com
// Description: ???????
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines2.vh"

module div(

	input wire			clk, 			// ʱ��
	input wire			rst,			// �����ź�
	
	input wire          signed_div_i, 	// �з��ų�
	input wire[31:0]    opdata1_i, 		// ������1
	input wire[31:0]	opdata2_i, 		// ������2
	input wire          start_i, 		// ��ʼ�ź�
	input wire          annul_i,		// ֹͣ��ǰ������ˢ�£�
	
	output reg[63:0]    result_o,		// �������
	output reg			ready_o			// ��������ź�
);

	wire[32:0] div_temp;
	reg[5:0] cnt;
	reg[64:0] dividend;
	reg[1:0] state;
	reg[31:0] divisor;	 
	reg[31:0] temp_op1;
	reg[31:0] temp_op2;
	reg[31:0] op1,op2;
	
	assign div_temp = {1'b0,dividend[63:32]} - {1'b0,divisor}; // ��������32λ��ȥ�����ĸ�32λ

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			state <= `DivFree;
			ready_o <= `DivResultNotReady;
			result_o <= {`ZeroWord,`ZeroWord};
		end 
		else begin
		  	case (state)
		  		`DivFree:
					begin	//DivFree״̬
		  				if(start_i == `DivStart && annul_i == 1'b0) begin
		  					if(opdata2_i == `ZeroWord) begin // ����Ϊ0
		  						state <= `DivByZero;
		  					end
							else begin
		  						state <= `DivOn;
		  						cnt <= 6'b000000;
								/*��1�ж��Ƿ�Ϊ�з��ų������з��ţ��򱻳����ͳ�����ȡ����*/
		  						if(signed_div_i == 1'b1 && opdata1_i[31] == 1'b1 ) begin
		  							temp_op1 = ~opdata1_i + 1;
		  						end
								else begin
		  							temp_op1 = opdata1_i;
		  						end
		  						if(signed_div_i == 1'b1 && opdata2_i[31] == 1'b1 ) begin
		  							temp_op2 = ~opdata2_i + 1;
		  						end
								else begin
		  							temp_op2 = opdata2_i;
		  						end
								/*��1����*/
		  						dividend <= {`ZeroWord,`ZeroWord};
              					dividend[32:1] <= temp_op1; // ������
              					divisor <= temp_op2; // ����
              					op1 <= opdata1_i;
              					op2 <= opdata2_i;
             				end
          				end
						else begin
							ready_o <= `DivResultNotReady;
							result_o <= {`ZeroWord,`ZeroWord};
				  		end          	
		  			end
		  		`DivByZero: // ����Ϊ0
					begin	//DivByZero״̬
         				dividend <= {`ZeroWord,`ZeroWord};
          				state <= `DivEnd;
		  			end
		  		`DivOn:
					begin	//DivOn״̬
		  				if(annul_i == 1'b0) begin
		  					if(cnt != 6'b100000) begin // ǰ31��
               					if(div_temp[32] == 1'b1) begin // ��������ȥ����Ϊ����
                	  				dividend <= {dividend[63:0] , 1'b0}; // ���Ʊ���������32λΪ�̣��̴�λ��0��
               					end
								else begin // ��������ȥ����Ϊ����
                	  				dividend <= {div_temp[31:0] , dividend[31:0] , 1'b1}; // ��32λ��ȥ��������32λ���䣨��32λΪ�̣��̴�λ��1��
               					end
               					cnt <= cnt + 1;
             				end
							else begin // ��32�ֽ���
               					if((signed_div_i == 1'b1) && ((op1[31] ^ op2[31]) == 1'b1)) begin
                	  				dividend[31:0] <= (~dividend[31:0] + 1); // �������ͳ�����ţ���Ϊ������ȡ����
               					end
               					if((signed_div_i == 1'b1) && ((op1[31] ^ dividend[64]) == 1'b1)) begin              
                	  				dividend[64:33] <= (~dividend[64:33] + 1); // ������������ţ�����Ϊ������������Ϊ������ȡ����
               					end
               					state <= `DivEnd;
               					cnt <= 6'b000000;            	
             				end
		  				end
						else begin
		  					state <= `DivFree;
		  				end	
		  			end
		  		`DivEnd:
					begin	//DivEnd״̬
        				result_o <= {dividend[64:33], dividend[31:0]};  
          				ready_o <= `DivResultReady;
          				if(start_i == `DivStop) begin
          					state <= `DivFree;
							ready_o <= `DivResultNotReady;
							result_o <= {`ZeroWord,`ZeroWord};       	
          				end		  	
		  			end
		  	endcase
		end
	end

endmodule