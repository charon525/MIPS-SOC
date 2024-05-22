`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/29 09:00:54
// Design Name: 
// Module Name: memdec
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


module memdec(
    input wire[31:0] a,
    input wire[2:0] op,
    input wire[1:0] addrch,
    output reg [31:0] y
    );
    always@(*) begin
        case(op)
            3'b000: // LB
                begin
                    case(addrch)
                        2'b00:y={{24{a[7]}},a[7:0]};
                        2'b01:y={{24{a[15]}},a[15:8]};
                        2'b10:y={{24{a[23]}},a[23:16]};
                        2'b11:y={{24{a[31]}},a[31:24]};
                    endcase
                end
            3'b001: // LBU
                begin
                    case(addrch)
                        2'b00:y={{24{1'b0}},a[7:0]};
                        2'b01:y={{24{1'b0}},a[15:8]};
                        2'b10:y={{24{1'b0}},a[23:16]};
                        2'b11:y={{24{1'b0}},a[31:24]};
                    endcase
                end
            3'b010: // LH
                begin
                    case(addrch)
                        2'b00:y={{16{a[15]}},a[15:0]};
                        2'b10:y={{16{a[31]}},a[31:16]};
                        default:y=a;
                    endcase
                end
            3'b011: // LHU
                begin
                    case(addrch)
                        2'b00:y={{16{1'b0}},a[15:0]};
                        2'b10:y={{16{1'b0}},a[31:16]};
                        default:y=a;
                    endcase
                end
            3'b100: // LW
                y=a;
            default: y=a;
        endcase
    end
endmodule
