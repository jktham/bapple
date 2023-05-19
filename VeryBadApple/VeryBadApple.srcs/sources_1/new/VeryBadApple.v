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

// controls
// sw0: enable display
// sw1: start drawing
// sw2: enable renderer
// sw3: play bapple
// sw4: double framerate
// sw11: sw1 blue channel
// sw12: sw1 green channel
// sw13: sw1 red channel
// sw14: allOn display mode
// sw15: debug transmit mode
// btn up: reset

module VeryBadApple (
    input clk,
    input [4:0] btn,
    input [15:0] sw,
    output [15:0] led,
    output [6:0] seg,
    output dp,
    output [3:0] an,
    output [7:0] JC
);
    wire enableRenderer;
    wire drawBuffer;
    wire [13:0] pixelCount;
    wire [15:0] pixelData;
    wire cclk;
    
    Renderer r(
        .clk(clk),
        .btn(btn),
        .sw(sw),
        .seg(seg),
        .dp(dp),
        .an(an),
        .enableRenderer(enableRenderer),
        .drawBuffer(drawBuffer),
        .pixelCount(pixelCount),
        .pixelData(pixelData)
    );

    Display d(
        .clk(clk),
        .btn(btn),
        .sw(sw),
        .led(led),
        .din(JC[0]),
        .sclk(JC[1]),
        .cs(JC[2]),
        .dc(JC[3]),
        .rst(JC[4]),
        .enableRenderer(enableRenderer),
        .drawBuffer(drawBuffer),
        .pixelCount(pixelCount),
        .pixelData(pixelData)
    );

    Flash f(
        .clk(clk),
        .cs(QspiCSn),
        .sdi(QspiDB[0]),
        .sdo(QspiDB[1]),
        .wp(QspiDB[2]),
        .hld(QspiDB[3]),
        .sck(cclk)
    );

    STARTUPE2 s( // needed to get flash sck pin
        .CLK(1'b0),
        .GSR(1'b0),
        .GTS(1'b0),
        .KEYCLEARB(1'b1),
        .PACK(1'b0),
        .PREQ(),
        .USRCCLKO(cclk),
        .USRCCLKTS(1'b0),
        .USRDONEO(1'b0),
        .USRDONETS(1'b1),
        .CFGCLK(),
        .CFGMCLK(),
        .EOS()
    );

endmodule
