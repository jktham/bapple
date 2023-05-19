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

module Display(
    input clk,
    input [4:0] btn,
    input [15:0] sw,
    output reg [15:0] led,

    output reg din, // data input, blue
    output reg sclk, // clock input, min 220 ns, yellow
    output reg cs, // chip select, active low, orange
    output reg dc, // data/cmd select, cmd low, data high, green
    output reg rst, // reset, active low, white

    output reg enableRenderer,
    output reg drawBuffer,
    output reg [31:0] pixelCount,
    input [15:0] pixelData

);

    // breaks when >32, weird int literal bit stuff maybe?
    // breaks even more at ~1000, synthesis fails. probably need to actually implement properly with hardware considerations
    parameter QUEUE_SIZE = 32;

    reg enabled;
    reg resetting;
    reg transmitting;
    reg allOn;
    reg drawing;
    reg [31:0] configState;
    reg debug;

    reg [31:0] transmitCount;
    reg [31:0] transmitPeriod;
    reg [31:0] frameCount;
    reg [31:0] framePeriod;
    reg frameDone;

    reg [QUEUE_SIZE-1:0] data;
    reg [QUEUE_SIZE-1:0] mode;
    reg [31:0] size;

    reg [5:0] r;
    reg [5:0] g;
    reg [5:0] b;

    initial begin
        transmitPeriod = 16; // min 11 -> ~24 fps (?)
        framePeriod = 10000000; // 10fps
        resetting = 1;

    end

    always @ (posedge clk) begin
        transmitCount = transmitCount + 1;
        frameCount = frameCount + 1;

        if (frameCount == framePeriod) begin // next frame
            frameCount = 0;
            frameDone = 0;
        end

        if (transmitCount == transmitPeriod) begin
            transmitCount = 0;

            if (!frameDone || transmitting || resetting) begin // stop sclk when done drawing frame, but allow last transmit to finish
                // transmit
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
                        configState = 0;
                        resetting = 0;
                        transmitting = 0;
                        frameDone = 0;

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
            end

            // input
            if (sw[13]) begin
                r = 6'b111111;
            end else begin
                r = 6'b000000;
            end
            if (sw[12]) begin
                g = 6'b111111;
            end else begin
                g = 6'b000000;
            end
            if (sw[11]) begin
                b = 6'b111111;
            end else begin
                b = 6'b000000;
            end

            if (sw[0] & !enabled & !transmitting) begin // exit sleep (AF)
                enabled = 1;
                transmitting = 1;
                transmit(8'b10101111, 0, 8);
            end
            if (!sw[0] & enabled & !transmitting) begin // enter sleep (AE)
                enabled = 0;
                transmitting = 1;
                transmit(8'b10101110, 0, 8);
            end

            if (sw[1] & !drawing & !transmitting) begin // start gddram write
                if (configState == 0) begin // set data format (A0)
                    configState = configState + 1;
                    transmitting = 1;
                    transmit(16'b10100000_00100000, 0, 16);
                end else if (configState == 1) begin // set write col (15)
                    configState = configState + 1;
                    transmitting = 1;
                    transmit(24'b00010101_00000000_01111111, 0, 24);
                end else if (configState == 2) begin // set write row (75)
                    configState = configState + 1;
                    transmitting = 1;
                    transmit(24'b01110101_00000000_01111111, 0, 24);
                end else if (configState == 3) begin // start write (5C)
                    configState = configState + 1;
                    transmitting = 1;
                    transmit(8'b01011100, 0, 8);
                end else if (configState >= 4 && configState <= 16384 + 4) begin // clear screen
                    configState = configState + 1;
                    transmitting = 1;
                    transmit(16'b00000000_00000000, 1, 16);
                end else if (configState == 16384 + 5) begin // stop write (AD)
                    configState = configState + 1;
                    transmitting = 1;
                    transmit(8'b10101101, 0, 8);
                end else if (configState == 16384 + 6) begin // set write col (15)
                    configState = configState + 1;
                    transmitting = 1;
                    transmit(24'b00010101_00000000_01111111, 0, 24);
                end else if (configState == 16384 + 7) begin // set write row (75)
                    configState = configState + 1;
                    transmitting = 1;
                    transmit(24'b01110101_00010000_01101111, 0, 24); // 16 - 111
                end else if (configState == 16384 + 8) begin // unlock mcu (FD)
                    configState = configState + 1;
                    transmitting = 1;
                    transmit(16'b11111101_10110001, 0, 16);
                end else if (configState == 16384 + 9) begin // set display offset (A2)
                    configState = configState + 1;
                    transmitting = 1;
                    transmit(16'b10100010_00000000, 0, 16);
                end else if (configState == 16384 + 10) begin // lock mcu (FD)
                    configState = configState + 1;
                    transmitting = 1;
                    transmit(16'b11111101_10110000, 0, 16);
                end else if (configState == 16384 + 11) begin // start write (5C)
                    configState = configState + 1;
                    drawing = 1;
                    pixelCount = 0;
                    transmitting = 1;
                    transmit(8'b01011100, 0, 8);
                end
            end
            if (!sw[1] & drawing & !transmitting) begin // stop gddram write (AD)
                configState = 0;
                drawing = 0;
                transmitting = 1;
                transmit(8'b10101101, 0, 8);
            end
            if (drawing & !transmitting & !frameDone) begin // send data
                transmitting = 1;
                if (enableRenderer) begin
                    transmit(pixelData, 1, 16);
                end else begin
                    transmit({b[5:1], g[5:0], r[5:1]}, 1, 16);
                end
                pixelCount = pixelCount + 1;
                if (pixelCount == 96*128) begin
                    pixelCount = 0;
                    frameDone = 1;
                end
            end

            if (sw[2] & !enableRenderer) begin // draw from renderer
                enableRenderer = 1;
            end
            if (!sw[2] & enableRenderer) begin // draw from rgb switches
                enableRenderer = 0;
            end

            if (sw[3] & !drawBuffer) begin // draw image buffer
                drawBuffer = 1;
            end
            if (!sw[3] & drawBuffer) begin // draw current scene
                drawBuffer = 0;
            end

            if (sw[4] && transmitPeriod == 32) begin // double framerate (20)
                framePeriod = 5000000;
            end
            if (!sw[4] && transmitPeriod == 16) begin // normal framerate (10)
                framePeriod = 10000000;
            end

            // if (sw[4] & !enhance & !transmitting) begin // enable display enhancement (B2)
            //     enhance = 1;
            //     transmitting = 1;
            //     transmit(32'b10110010_10100100_00000000_00000000, 0, 32, data, mode, size);
            // end
            // if (!sw[4] & enhance & !transmitting) begin // disable display enhancement (B2)
            //     enhance = 0;
            //     transmitting = 1;
            //     transmit(32'b10110010_00000000_00000000_00000000, 0, 32, data, mode, size);
            // end

            if (sw[14] & !allOn & !transmitting) begin // all on display mode (A5)
                allOn = 1;
                transmitting = 1;
                transmit(8'b10100101, 0, 8);
            end
            if (!sw[14] & allOn & !transmitting) begin // normal display mode (A6)
                allOn = 0;
                transmitting = 1;
                transmit(8'b10100110, 0, 8);
            end

            if (sw[15] & !debug) begin // debug transmit mode
                debug = 1;
                transmitPeriod = 100000000;
            end
            if (!sw[15] & debug) begin // normal transmit mode
                debug = 0;
                transmitPeriod = 16;
            end

            if (btn[0]) begin // reset
                resetting = 1;
            end

        end

        // ui
        if (debug) begin
            led[0] <= data[0];
            led[1] <= data[1];
            led[2] <= data[2];
            led[3] <= data[3];
            led[4] <= data[4];
            led[5] <= data[5];
            led[6] <= data[6];
            led[7] <= data[7];
            led[8] <= drawing;
            led[9] <= transmitting;
            led[10] <= resetting;
            led[11] <= rst;
            led[12] <= dc;
            led[13] <= cs;
            led[14] <= din;
            led[15] <= sclk;
        end else begin
            led[0] <= enabled;
            led[1] <= drawing;
            led[2] <= enableRenderer;
            led[3] <= drawBuffer;
            led[4] <= sw[4];
            led[5] <= 0;
            led[6] <= 0;
            led[7] <= 0;
            led[9] <= 0;
            led[8] <= 0;
            led[10] <= 0;
            led[11] <= sw[11];
            led[12] <= sw[12];
            led[13] <= sw[13];
            led[14] <= allOn;
            led[15] <= sclk;
        end

    end

    // originally had a proper queueing system and everything, now just overwrites and is instead only called when queue is empty
    task automatic transmit(input [QUEUE_SIZE-1:0] d, input t, input [31:0] s);
        begin : JIMOTHY // fun fact: local variables declared in unnamed blocks cause funky behavior
            reg [31:0] i;
            for (i = 0; i < QUEUE_SIZE; i = i + 1) begin
                if (s-i-1 >= 0) begin
                    data[i] = d[s-i-1];
                end else begin
                    data[i] = 0;
                end
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
