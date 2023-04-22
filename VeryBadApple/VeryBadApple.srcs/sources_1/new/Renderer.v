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
    output [6:0] seg,
    output reg dp,
    output [3:0] an,

    input enableRenderer,
    input drawBuffer,
    input [31:0] pixelCount,
    input [31:0] frameCount,
    output reg [15:0] pixelData
);

    reg [31:0] p, f,x, y;
    
    // encoding
    reg current, ready, invert, init; // remove 0s later and see if it breaks
    reg [31:0] nextFlip, addr;
    
    // memory
    parameter frames = 16;
	reg [7:0] img [0:612747];
	initial $readmemb("Memory.mem", img);

	// frame counter
	always @ (negedge pixelCount[13]) begin
		if (sw[3]) begin
			if (f < frames-1) f = f + 1;
			else f = 0;
		end else f = -1;
	end

    always @ (posedge clk) begin
        // render
        if (enableRenderer) begin : JIMOTHY
            // inputs
            p = pixelCount; // 0 - 16383
            //f = frameCount; // 0 - maxint
            x = pixelCount[6:0]; // 0 - 127
            y = pixelCount[13:7]; // 0 - 127

			// sync to start
			if (sw[3]) begin
				if (p == 32'b0) ready = 1;
			end else begin
				init = 1;
				ready = 0;
			end
			
			// init
			if (f == 0 && init) begin
				nextFlip = 0;
				addr = -1;
				init = 0;
			end
			
			if (f > 0) init = 1;
			
			if (ready) begin
				
				if (p == 32'b0 && nextFlip == 0) begin
					invert = 0;
					addr = addr + 1;
					current = 1; // replace this with img[addr]
				end
				
				if (nextFlip == p) begin
					current = current ^ invert;
					addr = addr + 1;
					nextFlip = p + img[addr];
					invert = ~(img[addr] == 8'b11111111);
				end
				
				if (p == 12287) nextFlip = 0;
				
            	pixelData = current ? 16'b1111111111111111 : 16'b0000000000000000;
			
			end else pixelData = 16'b1111100000011111;
        end
    end

endmodule
