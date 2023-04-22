`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2023 18:37:55
// Design Name: 
// Module Name: WordRenderer
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


module Debug(input clk, input [13:0] num, output reg [3:0] an, output [6:0] seg);
	reg [15:0] count;
	reg [3:0] dig;
	wire [1:0] ledCount;
	
	always@(posedge clk)
		count <= count + 1;
	assign ledCount = count[15:14];
	
	always@(*)
	begin
		case(ledCount)
		4'b00: begin an <= 4'b0111; dig <= (num/1000) % 10; end
		4'b01: begin an <= 4'b1011; dig <= (num/100) % 10; end
		4'b10: begin an <= 4'b1101; dig <= (num/10) % 10; end
		4'b11: begin an <= 4'b1110; dig <= (num) % 10; end
		endcase
	end
	
	DigitDecoder(dig, seg);
	
endmodule

module DigitDecoder(input [3:0] dig, output reg [6:0] seg);
	always@(*)
	begin
		case (dig) 
		0: seg <= 7'b1000000;
		1: seg <= 7'b1111001;
		2: seg <= 7'b0100100;
		3: seg <= 7'b0110000;
		4: seg <= 7'b0011001;
		5: seg <= 7'b0010010;
		6: seg <= 7'b0000010;
		7: seg <= 7'b1111000;
		8: seg <= 7'b0000000;
		9: seg <= 7'b0010000;
		default: seg <= 7'b1110111;
		endcase
	end
endmodule