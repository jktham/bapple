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
    output [15:0] led_pin,
    output [7:0] JC_pin
);
    // janky but necessary to be able to pass outputs to display module
    reg [15:0] led;
    reg [7:0] JC;
    assign led_pin = led;
    assign JC_pin = JC;
    
    reg [31:0] count;
    reg [31:0] prev_count;
    integer i;
    
    display dp(
        .din_pin(JC_pin[0]),
        .clk_pin(JC_pin[1]),
        .cs_pin(JC_pin[2]),
        .dc_pin(JC_pin[3]),
        .rst_pin(JC_pin[4])
    );
    
    always @ (posedge clk) begin
        prev_count = count;
        count = count + 1;
        
        if (count[dp.clockSpeed] != prev_count[dp.clockSpeed]) begin
            display_tick(count[dp.clockSpeed], dp.din, dp.clk, dp.cs, dp.dc, dp.rst, dp.reset, dp.transmit, dp.data, dp.type, dp.index);
        end
                
        if (sw[0] & !dp.enabled) begin
            dp.enabled = 1;
            dp.reset = 1;
            display_transmit(8'hAF, 0, dp.data, dp.type, dp.transmit);
        end
        if (!sw[0] & dp.enabled) begin
            dp.enabled = 0;
            display_transmit(8'hAE, 0, dp.data, dp.type, dp.transmit);
        end
        
        if (sw[1] & !dp.allOn) begin
            dp.allOn = 1;
            display_transmit(8'hA5, 0, dp.data, dp.type, dp.transmit);
        end
        if (!sw[1] & dp.allOn) begin
            dp.allOn = 0;
            display_transmit(8'hA6, 0, dp.data, dp.type, dp.transmit);
        end
        
        if (sw[15] & !dp.slowMode) begin
            dp.slowMode = 1;
            dp.clockSpeed = 24;
        end
        if (!sw[15] & dp.slowMode) begin
            dp.slowMode = 0;
            dp.clockSpeed = 8;
        end
        
        led[0] = dp.enabled;
        led[1] = dp.allOn;
        
        led[15] = dp.clk;
        led[14] = dp.din;
        led[13] = dp.cs;
        led[12] = dp.dc;
        led[11] = dp.rst;
        led[10] = dp.transmit;
        led[9] = dp.reset;
        
    end
    
endmodule

