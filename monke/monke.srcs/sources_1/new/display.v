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
    input clk,
    input [4:0] btn,
    input [15:0] sw,
    output reg [15:0] led,
    output reg din, // data input
    output reg sclk, // clock input, min 300 ns
    output reg cs, // chip select, active low
    output reg dc, // data/cmd select, cmd low, data high
    output reg rst // reset, active low
);

    parameter QUEUE_SIZE = 32;
    // breaks when >32, weird int literal bit stuff maybe?
    // breaks even more at ~1000, synthesis fails. probably need to actually implement properly with hardware considerations
    
    // trying to make assignments non-blocking fucks shit up severely, non-deterministic shenanigans and everything, i gave up

    reg enabled;
    reg reset;
    reg transmit;
    reg allOn;
    reg debugMode;
    reg drawing;
    reg configured;
    reg [QUEUE_SIZE-1:0] data;
    reg [QUEUE_SIZE-1:0] type;
    reg [31:0] length;
    reg [31:0] transmitSpeed;
    reg [31:0] inputSpeed;
    reg [31:0] prevCount;
    reg [31:0] count;
    reg [31:0] dataByte;
    reg [31:0] pixelCount;

    reg [5:0] r;
    reg [5:0] g;
    reg [5:0] b;

    initial begin
        transmitSpeed = 4;
        inputSpeed = 8;
        reset = 1;
    end

    always @ (posedge clk) begin
        prevCount = count;
        count = count + 1;

        if (count[transmitSpeed] != prevCount[transmitSpeed]) begin
            sclk = count[transmitSpeed];
            if (sclk == 0) begin
                if (reset) begin
                    din = 1;
                    cs = 1;
                    dc = 1;
                    rst = 0;
                    
                    reset = 0;
                    transmit = 0;
                    data = 0;
                    type = 0;
                    length = 0;
                    configured = 0;

                end else if (transmit) begin
                    din = data[0];
                    cs = 0;
                    dc = type[0];
                    rst = 1;
                    
                    data = data >> 1;
                    type = type >> 1;
                    length = length - 1;

                    if (length == 0) begin
                        transmit = 0;
                        data = 0;
                        type = 0;
                        length = 0;
                    end
                    
                end else begin
                    din = 1;
                    cs = 1;
                    dc = 1;
                    rst = 1;
                    
                end
            end

        end

        if (count[inputSpeed] != prevCount[inputSpeed]) begin
            if (sw[0] & !enabled) begin // exit sleep
                if (length == 0) begin
                    enabled = 1;
                    transmit_queue(8'b10101111, 0, 8, data, type, length, data, type, length, transmit);
                end
            end
            if (!sw[0] & enabled) begin // enter sleep
                if (length == 0) begin
                    enabled = 0;
                    transmit_queue(8'b10101110, 0, 8, data, type, length, data, type, length, transmit);
                end
            end
            
            if (sw[1] & !allOn) begin // full on display mode
                if (length == 0) begin
                    allOn = 1;
                    transmit_queue(8'b10100101, 0, 8, data, type, length, data, type, length, transmit);
                end
            end
            if (!sw[1] & allOn) begin // normal display mode
                if (length == 0) begin
                    allOn = 0;
                    transmit_queue(8'b10100110, 0, 8, data, type, length, data, type, length, transmit);
                end
            end
            
            if (sw[2] & !drawing) begin // start gddram write
                if (length == 0) begin
                    if (!configured) begin
                        configured = 1;
                        transmit_queue(16'b10100000_00100000, 0, 16, data, type, length, data, type, length, transmit);
                    end else begin
                        drawing = 1;
                        dataByte = 0;
                        transmit_queue(8'b01011100, 0, 8, data, type, length, data, type, length, transmit);
                    end
                end
            end
            if (!sw[2] & drawing) begin // stop gddram write
                if (length == 0) begin
                    drawing = 0;
                    transmit_queue(8'b10101101, 0, 8, data, type, length, data, type, length, transmit);
                end
            end
            if (drawing) begin // send data
                if (length == 0) begin
                    if (dataByte == 0) begin
                        dataByte = 1;
                        transmit_queue({b[5:1], g[5:3]}, 1, 8, data, type, length, data, type, length, transmit);
                    end else if (dataByte == 1) begin
                        dataByte = 0;
                        pixelCount = pixelCount + 1;
                        transmit_queue({g[2:0], r[5:1]}, 1, 8, data, type, length, data, type, length, transmit);
                    end
                end
            end
            
            if (sw[15] & !debugMode) begin // debug transmit mode
                debugMode = 1;
                transmitSpeed = 23;
            end
            if (!sw[15] & debugMode) begin // normal transmit mode
                debugMode = 0;
                transmitSpeed = 5;
            end
            
            if (btn[0]) begin // reset
                reset = 1;
            end

            if (sw[7]) begin // sw6 is broken
                r = {6{pixelCount[3]}};
                g = {6{pixelCount[4]}};
                b = {6{pixelCount[10]}};
            end else begin
                if (sw[5]) begin
                    r = 6'b111111;
                end else begin
                    r = 6'b000000;
                end
                if (sw[4]) begin
                    g = 6'b111111;
                end else begin
                    g = 6'b000000;
                end
                if (sw[3]) begin
                    b = 6'b111111;
                end else begin
                    b = 6'b000000;
                end
            end

        end
        
        led[15] = sclk;
        led[14] = din;
        led[13] = cs;
        led[12] = dc;
        led[11] = rst;
        led[10] = transmit;
        led[9] = reset;
        
        led[7] = data[7];
        led[6] = data[6];
        led[5] = data[5];
        led[4] = data[4];
        led[3] = data[3];
        led[2] = data[2];
        led[1] = data[1];
        led[0] = data[0];
        
    end
    
    // originally had a proper queueing system and everything, now just overwrites and is instead only called when queue is empty
    task automatic transmit_queue(input [QUEUE_SIZE-1:0] d, input t, input [31:0] l, input [QUEUE_SIZE-1:0] i_data, input [QUEUE_SIZE-1:0] i_type, input [31:0] i_length, output reg [QUEUE_SIZE-1:0] o_data, output reg [QUEUE_SIZE-1:0] o_type, output reg [31:0] o_length, output reg transmit);
        begin : JEFF
            // reg [31:0] i;
            // if (i_length + l <= QUEUE_SIZE) begin
            //     for (i = 0; i < QUEUE_SIZE; i = i + 1) begin
            //         if (i < length) begin
            //             o_data[i] = i_data[i];
            //             o_type[i] = i_type[i];
            //         end else if (i < length+l) begin
            //             o_data[i] = d[l-1-i-length];
            //             o_type[i] = t;
            //             if (i >= length+8) begin
            //                 o_type[i] = 1;
            //             end
            //         end else begin
            //             o_data[i] = 0;
            //             o_type[i] = 0;
            //         end
            //     end
                
            //     transmit = 1;
            //     o_length = i_length + l;
            // end

            // this shit was working perfectly but now it's broken so i'm just doing it by hand, fuck off

            o_data[0] = d[l-1];
            o_data[1] = d[l-2];
            o_data[2] = d[l-3];
            o_data[3] = d[l-4];
            o_data[4] = d[l-5];
            o_data[5] = d[l-6];
            o_data[6] = d[l-7];
            o_data[7] = d[l-8];
            o_data[8] = d[l-9];
            o_data[9] = d[l-10];
            o_data[10] = d[l-11];
            o_data[11] = d[l-12];
            o_data[12] = d[l-13];
            o_data[13] = d[l-14];
            o_data[14] = d[l-15];
            o_data[15] = d[l-16];
            o_data[16] = d[l-17];
            o_data[17] = d[l-18];
            o_data[18] = d[l-19];
            o_data[19] = d[l-20];
            o_data[20] = d[l-21];
            o_data[21] = d[l-22];
            o_data[22] = d[l-23];
            o_data[23] = d[l-24];
            o_data[24] = d[l-25];
            o_data[25] = d[l-26];
            o_data[26] = d[l-27];
            o_data[27] = d[l-28];
            o_data[28] = d[l-29];
            o_data[29] = d[l-30];
            o_data[30] = d[l-31];
            o_data[31] = d[l-0];

            o_type[0] = t;
            o_type[1] = t;
            o_type[2] = t;
            o_type[3] = t;
            o_type[4] = t;
            o_type[5] = t;
            o_type[6] = t;
            o_type[7] = t;
            o_type[8] = 1;
            o_type[9] = 1;
            o_type[10] = 1;
            o_type[11] = 1;
            o_type[12] = 1;
            o_type[13] = 1;
            o_type[14] = 1;
            o_type[15] = 1;
            o_type[16] = 1;
            o_type[17] = 1;
            o_type[18] = 1;
            o_type[19] = 1;
            o_type[20] = 1;
            o_type[21] = 1;
            o_type[22] = 1;
            o_type[23] = 1;
            o_type[24] = 1;
            o_type[25] = 1;
            o_type[26] = 1;
            o_type[27] = 1;
            o_type[28] = 1;
            o_type[29] = 1;
            o_type[30] = 1;
            o_type[31] = 1;

            o_length = l;
            transmit = 1;

        end
    endtask
    
endmodule
