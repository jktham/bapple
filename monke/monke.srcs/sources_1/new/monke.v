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


module monke(
    input clk,
    input [15:0] sw,
    input [4:0] btn,
    output reg [15:0] led,
    output reg dp_DIN, // data input
    output reg dp_CLK, // clock input, min 300 ns
    output reg dp_CS, // chip select, active low
    output reg dp_DC, // data/cmd select, cmd low, data high
    output reg dp_RST, // reset, active low
    output reg beep
    );
    
    reg [32:0] counter;
    reg [7:0] data;
    reg [2:0] index;
    
    integer command = 0;
    reg transmit;
    
    always @ (posedge clk) begin
        counter <= counter + 1;
        dp_CLK <= counter[8];
        
    end
    
    always @ (negedge dp_CLK) begin
        if (transmit) begin
            if (command == 0) begin
                dp_CS = 1;
                dp_DC = 1;
                dp_RST = 1;
                dp_DIN = 1;
                data = 8'b00000000;
                index = 0;
                command = 0;
                transmit = 0;
            end else if (command == 1) begin
                dp_CS = 1;
                dp_DC = 1;
                dp_RST = 0;
                dp_DIN = 1;
                command = 0;
                transmit = 0;
            end else if (command == 2) begin
                data = 8'b10101111;
                dp_CS = 0;
                dp_DC = 0;
                dp_RST = 1;
                dp_DIN = data[index];
                index = index + 1;
                if (index == 0) begin
                    command = 0;
                    transmit = 0;
                end
            end else if (command == 3) begin
                data = 8'b10100101;
                dp_CS = 0;
                dp_DC = 0;
                dp_RST = 1;
                dp_DIN = data[index];
                index = index + 1;
                if (index == 0) begin
                    command = 0;
                    transmit = 0;
                end
            end else begin
                
            end
            
        end else begin
            if (sw[0]) begin
                command = 0;
                transmit = 1;
            end else if (sw[1]) begin
                command = 1;
                transmit = 1;
            end else if (sw[2]) begin
                command = 2;
                transmit = 1;
            end else if (sw[3]) begin
                command = 3;
                transmit = 1;
            end else if (sw[4]) begin
            
            end else begin
                
            end
            
        end
        
        beep <= sw[15];
        
        led[0] <= ~led[0];
        led[1] <= dp_CS;
        led[2] <= dp_DC;
        led[3] <= dp_RST;
        led[4] <= dp_DIN;
        
    end
    
endmodule
