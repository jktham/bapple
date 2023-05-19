`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2023 04:16:15 PM
// Design Name: 
// Module Name: Flash
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


module Flash(
    input clk,

    output reg cs, // chip select
    output reg sdi, // serial in, rising edge
    input sdo, // serial out, falling edge
    output reg wp, // write protect
    output reg hld, // hold
    output reg sck // clk in, min 25ns
);

    parameter cacheBytes = 4;
    parameter startAddr = 24'h070000;


endmodule
