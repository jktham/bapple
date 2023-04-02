`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2023 11:24:53 AM
// Design Name: 
// Module Name: display
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


module display(
    output din_pin, // data input
    output clk_pin, // clock input, min 300 ns
    output cs_pin, // chip select, active low
    output dc_pin, // data/cmd select, cmd low, data high
    output rst_pin // reset, active low
);
    reg din;
    reg clk;
    reg cs;
    reg dc;
    reg rst;
    assign din_pin = din;
    assign clk_pin = clk;
    assign cs_pin = cs;
    assign dc_pin = dc;
    assign rst_pin = rst;
    
    reg enabled;
    reg reset;
    reg transmit;
    reg [7:0] data;
    reg type;
    reg [2:0] index;
    
    reg allOn;
    reg invert;
    reg slowMode;
    reg [4:0] clockSpeed = 8;
    
    
endmodule

// for some fucking reason vivado doesn't support hierarchical references for tasks inside modules, so i had to do this mess
task automatic display_tick(input c, output din, output clk, output cs, output dc, output rst, inout reset, inout transmit, inout [7:0] data, inout type, inout [2:0] index);
    begin
        clk = c;
        if (clk == 0) begin
            if (reset) begin
                din = 1;
                cs = 1;
                dc = 1;
                rst = 0;
                reset = 0;
                
            end else if (transmit) begin
                cs = 0;
                rst = 1;
                din = data[7-index];
                dc = type;
                index = index + 1;
                if (index == 0) begin
                    transmit = 0;
                    data = 0;
                    type = 0;
                    index = 0;
                end
                
            end else begin
                din = 1;
                cs = 1;
                dc = 1;
                rst = 1;
                
            end
        end
    end
endtask

task automatic display_transmit(input [7:0] d, input t, output [7:0] data, output type, inout transmit);
    begin
        if (!transmit) begin
            transmit = 1;
            data = d;
            type = t;
        end
    end
endtask
