`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/02 17:33:29
// Design Name: 
// Module Name: exception
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


module exception(
    input rst,
    input wire [7:0] except,
    input wire ades, // ¼´ except[1]
    input wire adel,
    input wire[31:0] status,cause,
    output reg[31:0] except_type
    );
    always@(*)begin
        if(rst)begin
            except_type = 32'b0;
        end
        else begin
            if(((cause[15:8] & status[15:8]) != 8'h00) && 
                    (status[1] == 1'b0) && (status[0] == 1'b1))
                begin
                    except_type=32'h00000001;
                end
            else if(except[7]==1'b1 || adel)
                begin
                    except_type=32'h00000004;
                end
            else if(ades==1'b1) // ¼´ except[1]
                begin
                    except_type=32'h00000005;
                end
            else if(except[6]==1'b1)
                begin
                    except_type=32'h00000008;
                end
            else if(except[5]==1'b1)
                begin
                    except_type=32'h00000009;
                end
            else if(except[4]==1'b1)
                begin
                    except_type=32'h0000000e;
                end
            else if(except[3]==1'b1)
                begin
                    except_type=32'h0000000a;
                end
            else if(except[2]==1'b1)
                begin
                    except_type=32'h0000000c;
                end
            else
                begin
                    except_type=32'h0;
                end
        end
    end
endmodule
