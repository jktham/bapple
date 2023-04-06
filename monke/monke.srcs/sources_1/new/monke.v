`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/31/2023 06:07:50 PM
// Design Name: 
// Module Name: monke
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

// todo
// image buffer -> 300 kbit bram
// renderer module
// basic shader stuff, video playback, rasterizer, vert data, ray tracer, ...

module monke(
    input clk,
    input [4:0] btn,
    input [15:0] sw,
    output [15:0] led,
    output [7:0] JC
);
    
    display d(
        .clk(clk),
        .btn(btn),
        .sw(sw),
        .led(led),
        .din(JC[0]),
        .sclk(JC[1]),
        .cs(JC[2]),
        .dc(JC[3]),
        .rst(JC[4])
    );

endmodule

