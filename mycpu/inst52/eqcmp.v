`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/23 22:57:01
// Design Name: 
// Module Name: eqcmp
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
module eqcmp(
	input wire [31:0] a,b,
	input wire[5:0] op,
	input wire[4:0] branch_type,
	output wire y
    );
    reg tmp = 1'b0;
    always @(*) begin
		case (op)
			`BEQ: tmp = (a == b) ? 1'b1 : 1'b0;// BEQ
			`BNE: tmp = (a != b)? 1'b1 : 1'b0;
			`BGTZ: tmp = ($signed(a) > 0)? 1'b1 : 1'b0;
			`BLEZ: tmp = ($signed(a) <= 0)? 1'b1 : 1'b0;
			6'b000001: begin
			     case(branch_type)
			         `BGEZ: tmp = ($signed(a) >= 0)? 1'b1 : 1'b0;
			         `BLTZ:  tmp = ($signed(a) < 0)? 1'b1 : 1'b0;
			         `BGEZAL: tmp = ($signed(a) >= 0)? 1'b1 : 1'b0;
			         `BLTZAL: tmp = ($signed(a) < 0)? 1'b1 : 1'b0;
			         default:  tmp = 1'b0;
			     endcase
			end
			default:  tmp = 1'b0;
		endcase
	end
	assign y = tmp;
endmodule
