`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2023 04:20:51 PM
// Design Name: 
// Module Name: renderer
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


module Renderer(
    input clk,
    input [4:0] btn,
    input [15:0] sw,
    output reg [6:0] seg,
    output reg dp,
    output reg [3:0] an,

    input enableRenderer,
    input drawBuffer,
    input [31:0] pixelCount,
    input [31:0] frameCount,
    output reg [15:0] pixelData
);

    reg [31:0] p, f, x, y;
    
    // encoding
    reg current, ready, invert;
    reg [31:0] nextFlip;
    reg [8:0] addr;
    
    // memory
	reg [7:0] img [0:345];
	initial $readmemb("Memory.mem", img);

    always @ (posedge clk) begin
        // render
        if (enableRenderer) begin : JIMOTHY
            // inputs
            p = pixelCount; // 0 - 16383
            f = frameCount; // 0 - maxint
            x = pixelCount[6:0]; // 0 - 127
            y = pixelCount[13:7]; // 0 - 127

			if (sw[3]) begin
				if (p == 32'b0) ready = 1;
			end else ready = 0;
			
			if (ready) begin
				
				if (p == 32'b0) begin
					addr = 0;
					nextFlip = 0;
					invert = 0;
					current = 0;
				end
				
				if (nextFlip == p) begin
					current = current ^ invert;
					addr = addr + 1;
					nextFlip = p + img[addr];
					invert = ~(img[addr] == 8'b11111111);
				end
				
				if (nextFlip == p) begin
					current = current ^ invert;
					addr = addr + 1;
					nextFlip = p + img[addr];
					invert = ~(img[addr] == 8'b11111111);
				end
				
			end

            pixelData = current ? 16'b1111111111111111 : 16'b0000000000000000;
        end
    end

endmodule
