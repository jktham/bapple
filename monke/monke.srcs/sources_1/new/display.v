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
    output reg rst, // reset, active low

    output reg drawBuffer,
    output reg [31:0] pixel,
    output reg [31:0] frame,
    input [15:0] buffer
);

    // breaks when >32, weird int literal bit stuff maybe?
    // breaks even more at ~1000, synthesis fails. probably need to actually implement properly with hardware considerations
    parameter QUEUE_SIZE = 32;

    reg enabled;
    reg resetting;
    reg transmitting;
    reg allOn;
    reg drawing;
    reg [3:0] configState;
    reg debug;

    reg [31:0] div;
    reg [31:0] count;

    reg [QUEUE_SIZE-1:0] data;
    reg [QUEUE_SIZE-1:0] mode;
    reg [31:0] size;

    reg [5:0] r;
    reg [5:0] g;
    reg [5:0] b;

    initial begin
        div = 5; // min 4 -> ~24 fps
        resetting = 1;

    end

    always @ (posedge clk) begin
        count = count + 1;

        if (count[div] == 1) begin
            count = 0;
            sclk = ~sclk;

            // transmit
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
                transmit(8'b10101111, 0, 8, data, mode, size);
            end
            if (!sw[0] & enabled & !transmitting) begin // enter sleep (AE)
                enabled = 0;
                transmitting = 1;
                transmit(8'b10101110, 0, 8, data, mode, size);
            end

            if (sw[1] & !drawing & !transmitting) begin // start gddram write
                if (configState == 0) begin // set data format (A0)
                    configState = 1;
                    transmitting = 1;
                    transmit(16'b10100000_00100000, 0, 16, data, mode, size);
                end else if (configState == 1) begin // set write col (15)
                    configState = 2;
                    transmitting = 1;
                    transmit(24'b00010101_00000000_01111111, 0, 24, data, mode, size);
                end else if (configState == 2) begin // set write row (75)
                    configState = 3;
                    transmitting = 1;
                    transmit(24'b01110101_00000000_01111111, 0, 24, data, mode, size);
                end else if (configState == 3) begin // unlock mcu (FD)
                    configState = 4;
                    transmitting = 1;
                    transmit(16'b11111101_10110001, 0, 16, data, mode, size);
                end else if (configState == 4) begin // set display offset (A2)
                    configState = 5;
                    transmitting = 1;
                    transmit(16'b10100010_00000000, 0, 16, data, mode, size);
                end else if (configState == 5) begin // lock mcu (FD)
                    configState = 6;
                    transmitting = 1;
                    transmit(16'b11111101_10110000, 0, 16, data, mode, size);
                end else if (configState == 6) begin // start write (5C)
                    drawing = 1;
                    pixel = 0;
                    frame = 0;
                    transmitting = 1;
                    transmit(8'b01011100, 0, 8, data, mode, size);
                end
            end
            if (!sw[1] & drawing & !transmitting) begin // stop gddram write (AD)
                configState = 0;
                drawing = 0;
                transmitting = 1;
                transmit(8'b10101101, 0, 8, data, mode, size);
            end
            if (drawing & !transmitting) begin // send data
                transmitting = 1;
                if (drawBuffer) begin
                    transmit(buffer, 1, 16, data, mode, size);
                end else begin
                    transmit({b[5:1], g[5:0], r[5:1]}, 1, 16, data, mode, size);
                end
                pixel = pixel + 1;
                if (pixel == 16384) begin
                    pixel = 0;
                    frame = frame + 1;
                end
            end

            if (sw[2] & !drawBuffer) begin // draw from buffer
                drawBuffer = 1;
            end
            if (!sw[2] & drawBuffer) begin // draw from rgb switches
                drawBuffer = 0;
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
                transmit(8'b10100101, 0, 8, data, mode, size);
            end
            if (!sw[14] & allOn & !transmitting) begin // normal display mode (A6)
                allOn = 0;
                transmitting = 1;
                transmit(8'b10100110, 0, 8, data, mode, size);
            end

            if (sw[15] & !debug) begin // debug transmit mode
                debug = 1;
                div = 23;
            end
            if (!sw[15] & debug) begin // normal transmit mode
                debug = 0;
                div = 5;
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
            led[2] <= drawBuffer;
            led[3] <= 0;
            led[4] <= 0;
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
    task transmit(input [QUEUE_SIZE-1:0] d, input t, input [31:0] s, inout [QUEUE_SIZE-1:0] data, inout [QUEUE_SIZE-1:0] mode, inout [31:0] size);
        begin : JEFF // fun fact: local variables declared in unnamed blocks cause funky behavior
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
