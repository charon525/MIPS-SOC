`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/29 15:24:36
// Design Name: 
// Module Name: memcontr
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


module memcontr(
    input wire memwrite,
    input wire[2:0] memop,
    input wire [31:0] addr,
    input wire [31:0] pc,
    input wire [31:0] indata, // 对写入存储器数据的修改
    output reg [31:0] outdata,
    output reg[3:0] sel,
    output reg adel, // 读数据地址例外
    output reg ades, // 写数据地址例外
    output reg[31:0] bad_addr
    );
    always@(*)begin
        adel=0;
        ades=0;
        if(memwrite) // 写数据
            begin
                case(memop)
                    3'b101: // SB
                        begin
                            ades=0;
                            outdata={indata[7:0],indata[7:0],indata[7:0],indata[7:0]};
                            case(addr[1:0])
                                2'b00:sel=4'b0001;
                                2'b01:sel=4'b0010;
                                2'b10:sel=4'b0100;
                                2'b11:sel=4'b1000;
                                default: /*    default    */;
                            endcase
                        end
                    3'b110: // SH
                        begin
                            if(addr[0]!=0)
                                begin
                                    sel=4'b0000;ades=1;bad_addr=addr;
                                end
                            else begin
                                ades=0;
                                outdata={indata[15:0],indata[15:0]};
                                    case(addr[1:0])
                                        2'b00:sel=4'b0011;
                                        2'b10:sel=4'b1100;
                                        default: /*    default    */;
                                    endcase
                            end
                        end
                    3'b111: // SW
                        begin
                            if(addr[1:0]!=2'b00)
                                begin
                                    sel=4'b0000;ades=1;bad_addr=addr;
                                end
                            else
                                begin
                                    sel=4'b1111;
                                    outdata=indata;
                                    ades=0;
                                end
                        end
                    default:;
                endcase
            end
        else // 读数据
            begin
                sel=4'b0000;
                outdata=indata;
                bad_addr=pc;
                case(memop)
                    3'b010:if(addr[0]!=0) begin adel=1; bad_addr=addr; end // LH
                    3'b011:if(addr[0]!=0) begin adel=1; bad_addr=addr; end // LHU
                    3'b100:if(addr[1:0]!=2'b00) begin adel=1; bad_addr=addr; end // LW
                    default:adel=0;
                endcase
            end
    end
endmodule

