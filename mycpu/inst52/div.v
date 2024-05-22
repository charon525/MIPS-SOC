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

	input wire			clk, 			// 时钟
	input wire			rst,			// 重置信号
	
	input wire          signed_div_i, 	// 有符号除
	input wire[31:0]    opdata1_i, 		// 操作数1
	input wire[31:0]	opdata2_i, 		// 操作数2
	input wire          start_i, 		// 开始信号
	input wire          annul_i,		// 停止当前除法并刷新？
	
	output reg[63:0]    result_o,		// 除法结果
	output reg			ready_o			// 除法完成信号
);

	wire[32:0] div_temp;
	reg[5:0] cnt;
	reg[64:0] dividend;
	reg[1:0] state;
	reg[31:0] divisor;	 
	reg[31:0] temp_op1;
	reg[31:0] temp_op2;
	reg[31:0] op1,op2;
	
	assign div_temp = {1'b0,dividend[63:32]} - {1'b0,divisor}; // 被除数高32位减去除数的高32位

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			state <= `DivFree;
			ready_o <= `DivResultNotReady;
			result_o <= {`ZeroWord,`ZeroWord};
		end 
		else begin
		  	case (state)
		  		`DivFree:
					begin	//DivFree状态
		  				if(start_i == `DivStart && annul_i == 1'b0) begin
		  					if(opdata2_i == `ZeroWord) begin // 除数为0
		  						state <= `DivByZero;
		  					end
							else begin
		  						state <= `DivOn;
		  						cnt <= 6'b000000;
								/*段1判断是否为有符号除，若有符号，则被除数和除数均取补码*/
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
								/*段1结束*/
		  						dividend <= {`ZeroWord,`ZeroWord};
              					dividend[32:1] <= temp_op1; // 被除数
              					divisor <= temp_op2; // 除数
              					op1 <= opdata1_i;
              					op2 <= opdata2_i;
             				end
          				end
						else begin
							ready_o <= `DivResultNotReady;
							result_o <= {`ZeroWord,`ZeroWord};
				  		end          	
		  			end
		  		`DivByZero: // 除数为0
					begin	//DivByZero状态
         				dividend <= {`ZeroWord,`ZeroWord};
          				state <= `DivEnd;
		  			end
		  		`DivOn:
					begin	//DivOn状态
		  				if(annul_i == 1'b0) begin
		  					if(cnt != 6'b100000) begin // 前31轮
               					if(div_temp[32] == 1'b1) begin // 被除数减去除数为负数
                	  				dividend <= {dividend[63:0] , 1'b0}; // 左移被除数（右32位为商，商此位置0）
               					end
								else begin // 被除数减去除数为正数
                	  				dividend <= {div_temp[31:0] , dividend[31:0] , 1'b1}; // 高32位减去除数，低32位不变（右32位为商，商此位置1）
               					end
               					cnt <= cnt + 1;
             				end
							else begin // 第32轮结束
               					if((signed_div_i == 1'b1) && ((op1[31] ^ op2[31]) == 1'b1)) begin
                	  				dividend[31:0] <= (~dividend[31:0] + 1); // 被除数和除数异号，商为负数，取补码
               					end
               					if((signed_div_i == 1'b1) && ((op1[31] ^ dividend[64]) == 1'b1)) begin              
                	  				dividend[64:33] <= (~dividend[64:33] + 1); // 被除数和商异号（除数为负数），余数为负数，取补码
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
					begin	//DivEnd状态
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