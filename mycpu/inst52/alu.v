`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:52:16
// Design Name: 
// Module Name: alu
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
module alu(
	input wire[31:0] a,b,
	input wire [4:0] sa,
	input wire[4:0] op,
	output reg[31:0] y,
	input wire[63:0] hilo_in,
	output reg[63:0] hilo_out,
	output reg overflow
    );
    reg [32:0] tmp;
    always@(*) begin
        case(op[4:0])
            `AND_CONTROL:begin y=a&b; overflow=0; end // and
            `OR_CONTROL:begin y=a|b; overflow=0; end // or
            `ADD_CONTROL: // add
                begin
                    tmp={a[31],a} + {b[31],b};
                    if(tmp[32]!=tmp[31])begin
                        overflow=1;
                    end
                    else begin
                        overflow=0;
                    end
                    y=tmp[31:0];
                end
            `ADDU_CONTROL: // addu
                begin
                    y=a+b;
                    overflow=0;
                end
            `LUI_CONTROL: // lui
                begin
                    y={b[15:0],{16{1'b0}}};
                    overflow=0;
                end
            `SUBU_CONTROL: // subu
                begin
                    y=a-b;
                    overflow=0;
                end
            `SUB_CONTROL: // sub
                begin
                    tmp={a[31],a} - {b[31],b};
                    if(tmp[32]!=tmp[31])begin
                        overflow=1;
                    end
                    else begin
                        overflow=0;
                    end
                    y=tmp[31:0];
                end
            `SLT_CONTROL: // slt
                begin
                    if($signed(a)<$signed(b))
                        y=1;
                    else
                        y=0;
                    overflow=0;
                end
            `NOR_CONTROL: // nor
                begin
                    y=~(a|b);
                    overflow=0;
                end
            `XOR_CONTROL: // xor
                begin
                    y=a^b;
                    overflow=0;
                end
            `SLTU_CONTROL: // sltu
                begin
                    if(a<b)
                        y=1;
                    else
                        y=0;
                    overflow=0;
                end
                
            /*ÒÆÎ»*/
            `SLL_CONTROL:// sllÂß¼­×óÒÆ
                begin
                    y = b << sa;  
                end
             `SLLV_CONTROL:// sllvÂß¼­×óÒÆ
                begin
                    y = b << a[4:0];  
                end
             `SRL_CONTROL:// srlÂß¼­ÓÒÒÆ
                begin
                    y = b >> sa;
                end
             `SRLV_CONTROL:// srlvÂß¼­ÓÒÒÆ
                begin
                    y = b >> a[4:0];
                end
             `SRA_CONTROL:// sraËãÊýÓÒÒÆ
                begin
                    y = $signed(b) >>> sa;
                end
             `SRAV_CONTROL:// sraËãÊýÓÒÒÆ
                begin
                    y = $signed(b) >>> a[4:0];
                end
            
            /*Êý¾ÝÒÆ¶¯*/
            `MTHI_CONTROL: // MTHI
                begin
                    hilo_out = {a,hilo_in[31:0]};
                end
            `MTLO_CONTROL: // MTLO
                begin
                    hilo_out = {hilo_in[63:32],a};
                end
            `MFHI_CONTROL: // MFHI
                begin
                    y = hilo_in[63:32];
                end
            `MFLO_CONTROL: // MFLO
                begin
                    y = hilo_in[31:0];
                end
            
            /*³Ë·¨Ö¸Áî*/
            `MULT_CONTROL:
                begin
                    hilo_out = $signed(a) * $signed(b);
                end
            `MULTU_CONTROL:
                begin
                    hilo_out = a * b;
                end
            
            default: // nop
                begin
                    y=0;overflow=0;
                end
        endcase
    end
endmodule
