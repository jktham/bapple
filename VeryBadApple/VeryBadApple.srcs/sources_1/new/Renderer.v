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
    input [13:0] pixelCount,
    output reg [15:0] pixelData
);

    reg [32:0] p, f;
    
    // encoding
    reg current, running, invert, init;
    reg [32:0] nextFlip, addr;
    
    // memory
    parameter frames = 30;
	reg [7:0] img [0:110000];
	initial $readmemb("Memory.mem", img);

	// sync and frame counter
	always @ (negedge pixelCount[13]) begin
		running = sw[3];
		if (running) begin
			if (f < frames-1) f = f + 1;
			else f = 0;
		end else f = 0;
	end

    always @ (posedge clk) begin
        // render
        if (enableRenderer) begin
            p = pixelCount; // 0 - 16383 (12287 when display area reduced)

			// reset before first frame
			if (f == 0 && init) begin
				addr = -1;
				nextFlip = 0;
				init = 0;
			end
			if (f > 0) init = 1;
			
			if (running) begin
				if (p == 32'b0 && nextFlip == 0) begin
					addr = addr + 1;
					invert = 0;
					current = img[addr];
				end
				
				if (nextFlip == p) begin
					addr = addr + 1;
					current <= current ^ invert;
					nextFlip <= p + img[addr];
					invert <= ~(img[addr] == 8'b11111111);
				end
				
				if (p == 12287) nextFlip <= 0;
				
            	pixelData = current ? 16'b1111111111111111 : 16'b0000000000000000;
			
			end else begin
				pixelData = {p[13:9], 6'b000000, p[6:2]}; // neat gradient
				init = 1;
			end
        end
    end

endmodule
