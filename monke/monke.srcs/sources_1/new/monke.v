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

// controls
// sw15: debug mode
// sw14: all on
// sw13: r
// sw12: g
// sw11: b
// sw2: enable renderer
// sw1: start drawing
// sw0: turn on screen
// btn up: reset
// btn left: previous scene
// btn center: default scene
// btn right: next scene

module monke(
    input clk,
    input [4:0] btn,
    input [15:0] sw,
    output [15:0] led,
    output [6:0] seg,
    output dp,
    output [3:0] an,
    output [7:0] JC
);
    wire drawBuffer;
    wire [15:0] buffer;
    wire [31:0] pixel;
    wire [31:0] frame;
    
    renderer r(
        .clk(clk),
        .btn(btn),
        .sw(sw),
        .seg(seg),
        .dp(dp),
        .an(an),
        .buffer(buffer),
        .drawBuffer(drawBuffer),
        .pixel(pixel),
        .frame(frame)
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
        .rst(JC[4]),
        .drawBuffer(drawBuffer),
        .pixel(pixel),
        .frame(frame),
        .buffer(buffer)
    );

endmodule

