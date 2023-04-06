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

// trying to make assignments non-blocking fucks shit up severely, non-deterministic shenanigans and everything, i gave up

module display(
    input clk,
    input [4:0] btn,
    input [15:0] sw,
    output reg [15:0] led,
    output reg din, // data input
    output reg sclk, // clock input, min 220 ns
    output reg cs, // chip select, active low
    output reg dc, // data/cmd select, cmd low, data high
    output reg rst // reset, active low
);

    // breaks when >32, weird int literal bit stuff maybe?
    // breaks even more at ~1000, synthesis fails. probably need to actually implement properly with hardware considerations
    parameter QUEUE_SIZE = 32;

    reg enabled;
    reg resetting;
    reg transmitting;
    reg allOn;
    reg drawing;
    reg configured;
    reg debug;

    reg [31:0] div;
    reg [31:0] count;

    reg [QUEUE_SIZE-1:0] data;
    reg [QUEUE_SIZE-1:0] mode;
    reg [31:0] size;

    reg [31:0] dataByte;
    reg [31:0] pixelCount;
    reg [5:0] r;
    reg [5:0] g;
    reg [5:0] b;

    initial begin
        div = 4; // min 4 -> ~24 fps
        resetting = 1;
    end

    always @ (posedge clk) begin
        count = count + 1;

        if (count[div] == 1) begin
            count = 0;
            sclk = ~sclk;

            if (sclk == 0) begin // write to pins on negedge, display reads on posedge
                if (resetting) begin
                    din = 1;
                    cs = 1;
                    dc = 1;
                    rst = 0;

                    data = 0;
                    mode = 0;
                    size = 0;
                    configured = 0;
                    resetting = 0;
                    transmitting = 0;

                end else if (transmitting) begin
                    din = data[0];
                    cs = 0;
                    dc = mode[0];
                    rst = 1;

                    data = data >> 1;
                    mode = mode >> 1;
                    size = size - 1;

                    if (size == 0) begin
                        data = 0;
                        mode = 0;
                        size = 0;
                        transmitting = 0;
                    end

                end else begin
                    din = 1;
                    cs = 1;
                    dc = 1;
                    rst = 1;

                end
            end

            if (sw[0] & !enabled & !transmitting) begin // exit sleep
                enabled = 1;
                transmitting = 1;
                transmit(8'b10101111, 0, 8, data, mode, size);
            end
            if (!sw[0] & enabled & !transmitting) begin // enter sleep
                enabled = 0;
                transmitting = 1;
                transmit(8'b10101110, 0, 8, data, mode, size);
            end

            if (sw[1] & !allOn & !transmitting) begin // all on display mode
                allOn = 1;
                transmitting = 1;
                transmit(8'b10100101, 0, 8, data, mode, size);
            end
            if (!sw[1] & allOn & !transmitting) begin // normal display mode
                allOn = 0;
                transmitting = 1;
                transmit(8'b10100110, 0, 8, data, mode, size);
            end

            if (sw[2] & !drawing & !transmitting) begin // start gddram write
                if (!configured) begin
                    configured = 1;
                    transmitting = 1;
                    transmit(16'b10100000_00100000, 0, 16, data, mode, size);
                end else begin
                    drawing = 1;
                    dataByte = 0;
                    transmitting = 1;
                    transmit(8'b01011100, 0, 8, data, mode, size);
                end
            end
            if (!sw[2] & drawing & !transmitting) begin // stop gddram write
                drawing = 0;
                transmitting = 1;
                transmit(8'b10101101, 0, 8, data, mode, size);
            end
            if (drawing & !transmitting) begin // send data
                if (dataByte == 0) begin
                    dataByte = 1;
                    transmitting = 1;
                    transmit({b[5:1], g[5:3]}, 1, 8, data, mode, size);
                end else if (dataByte == 1) begin
                    dataByte = 0;
                    pixelCount = pixelCount + 1;
                    transmitting = 1;
                    transmit({g[2:0], r[5:1]}, 1, 8, data, mode, size);
                end
            end

            if (sw[15] & !debug) begin // debug transmit mode
                debug = 1;
                div = 23;
            end
            if (!sw[15] & debug) begin // normal transmit mode
                debug = 0;
                div = 4;
            end

            if (btn[0]) begin // reset
                resetting = 1;
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

        if (debug) begin
            led[0] = data[0];
            led[1] = data[1];
            led[2] = data[2];
            led[3] = data[3];
            led[4] = data[4];
            led[5] = data[5];
            led[6] = data[6];
            led[7] = data[7];
            led[8] = drawing;
            led[9] = transmitting;
            led[10] = resetting;
            led[11] = rst;
            led[12] = dc;
            led[13] = cs;
            led[14] = din;
            led[15] = sclk;

        end else begin
            led[0] = enabled;
            led[1] = allOn;
            led[2] = drawing;
            led[3] = sw[3];
            led[4] = sw[4];
            led[5] = sw[5];
            led[6] = 0;
            led[7] = sw[7];
            led[9] = 0;
            led[8] = 0;
            led[10] = 0;
            led[11] = 0;
            led[12] = configured;
            led[13] = transmitting;
            led[14] = resetting;
            led[15] = sclk;

        end

    end

    // originally had a proper queueing system and everything, now just overwrites and is instead only called when queue is empty
    task transmit(input [QUEUE_SIZE-1:0] d, input t, input [31:0] s, inout [QUEUE_SIZE-1:0] data, inout [QUEUE_SIZE-1:0] mode, inout [31:0] size);
        begin : JEFF
            reg [31:0] i;
            for (i = 0; i < QUEUE_SIZE; i = i + 1) begin
                data[i] = d[s-i-1];
                if (i < 8) begin
                    mode[i] = t;
                end else begin
                    mode[i] = 1;
                end
            end
            size = s;

        end
    endtask

endmodule
