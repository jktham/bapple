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
    output reg [6:0] seg,
    output reg dp,
    output reg [3:0] an,

    input enableRenderer,
    input drawBuffer,
    input [31:0] pixelCount,
    input [31:0] frameCount,
    output reg [15:0] pixelData
);

    reg [31:0] p, f, x, y, r, g, b;

    /*parameter BUFFER_SIZE = 16384;
    reg imageBuffer [0:16384];
    reg [31:0] bufferIndex;*/

	reg [7:0] img [0:2047];
	initial $readmemb("Memory.mem", img);

    always @ (posedge clk) begin
        // render
        if (enableRenderer) begin : JIMOTHY
            // inputs
            p = pixelCount; // 0 - 16383
            f = frameCount; // 0 - maxint
            x = pixelCount[6:0]; // 0 - 127
            y = pixelCount[13:7]; // 0 - 127
            // outputs
            r = 0; // 0 - 63, lsb discarded
            g = 0; // 0 - 63
            b = 0; // 0 - 63, lsb discarded

            if (drawBuffer) begin
            	if (img[pixelCount[13:3]][3'b111 - pixelCount[2:0]]) begin
                	r = 63;
                	g = 63;
                	b = 63;
                end else begin
                	r = 0;
                	g = 0;
                	b = 0;
                end
            end else begin
            	r = x[6:1];
            	g = 63;
            	b = y[6:1];
            end

            pixelData = {b[5:1], g[5:0], r[5:1]};
        end

        // ui
        /*case (scene)
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
        endcase*/
        dp = drawBuffer;
    end

    task automatic drawPoint(input [6:0] x0, y0, input [5:0] r0, g0, b0);
        if (x == x0 && y == y0) begin
            r = r0;
            g = g0;
            b = b0;
        end
    endtask

    // janky implementation of Bresenhams algorithm
    task automatic drawLine(input [6:0] x0, y0, x1, y1, input [5:0] r0, g0, b0);
        begin : JOEBAMA
            reg [31:0] p, dx, dy, m, s, s0, s1, t, t0, t1;
            p = 1024;
            dx = x1 - x0;
            dy = y1 - y0;
            s0 = x0;
            s1 = x1;
            t0 = y0;
            t1 = y1;
            if (x0 > x1) begin
                dx = x0 - x1;
                s0 = x1;
                s1 = x0;
            end
            if (y0 > y1) begin
                dy = y0 - y1;
                t0 = y1;
                t1 = y0;
            end
            if (dx >= dy) begin
                m = dy*p/dx;
                t = t0*p;
                for (s = s0; s <= s1; s = s + 1) begin
                    if (x == s && y == t/p) begin
                        r = r0;
                        g = g0;
                        b = b0;
                    end
                    t = t + m;
                end
            end else begin
                m = dx*p/dy;
                s = s0*p;
                for (t = t0; t <= t1; t = t + 1) begin
                    if (y == t && x == s/p) begin
                        r = r0;
                        g = g0;
                        b = b0;
                    end
                    s = s + m;
                end
            end
        end
    endtask

    task automatic drawRectangle(input [6:0] x0, y0, x1, y1, input [6:0] mode, width, input [5:0] r0, g0, b0);
        begin : FRANQUITO
            reg [6:0] s0, s1, t0, t1;
            s0 = x0;
            s1 = x1;
            t0 = y0;
            t1 = y1;
            if (x0 > x1) begin
                s0 = x1;
                s1 = x0;
            end
            if (y0 > y1) begin
                t0 = y1;
                t1 = y0;
            end
            case (mode)
                0: begin // fill inside
                    if (x >= s0 && x <= s1 && y >= t0 && y <= t1) begin
                        r = r0;
                        g = g0;
                        b = b0;
                    end
                end
                1: begin // fill outside
                    if (x < s0 || x > s1 || y < t0 || y > t1) begin
                        r = r0;
                        g = g0;
                        b = b0;
                    end
                end
                2: begin // line inside
                    if ((x >= s0 && x <= s1 && y >= t0 && y <= t1) && (x < s0 + width || x + width > s1 || y < t0 + width || y + width > t1)) begin
                        r = r0;
                        g = g0;
                        b = b0;
                    end
                end
                3: begin // line outside
                    if ((x < s0 || x > s1 || y < t0 || y > t1) && (x + width >= s0 && x <= s1 + width && y + width >= t0 && y <= t1 + width)) begin
                        r = r0;
                        g = g0;
                        b = b0;
                    end
                end
                default: begin

                end
            endcase
        end
    endtask

    task automatic drawCircle(input [6:0] x0, y0, radius, mode, width, input [5:0] r0, g0, b0);
        case (mode)
            0: begin // fill inside
                if ((x - x0)**2 + (y - y0)**2 <= radius**2) begin
                    r = r0;
                    g = g0;
                    b = b0;
                end
            end
            1: begin // fill outside
                if ((x - x0)**2 + (y - y0)**2 > radius**2) begin
                    r = r0;
                    g = g0;
                    b = b0;
                end
            end
            2: begin // line inside
                if ((x - x0)**2 + (y - y0)**2 <= radius**2 && (x - x0)**2 + (y - y0)**2 > (radius - width)**2) begin
                    r = r0;
                    g = g0;
                    b = b0;
                end
            end
            3: begin // line outside
                if ((x - x0)**2 + (y - y0)**2 > radius**2 && (x - x0)**2 + (y - y0)**2 <= (radius + width)**2) begin
                    r = r0;
                    g = g0;
                    b = b0;
                end
            end
            default: begin

            end
        endcase
    endtask

    // draw vertex data, 7b per coord, 14b per vert, max 100 verts
    // line and fill modes group 3 verts into triangles
    task automatic drawVerts(input [1399:0] verts, input [31:0] size, mode, input [5:0] r0, g0, b0);
        begin : GORBACHUSSY
            reg [31:0] i, x0, y0, v0, v1, v2;
            case (mode)
                0: begin // points
                    for (i = 0; i < size; i = i + 1) begin
                        v0 = verts[i*14+:14];
                        drawPoint(v0[13:7], v0[6:0], r0, g0, b0);
                    end
                end
                1: begin // lines
                    for (i = 0; i < size; i = i + 3) begin
                        v0 = verts[i*14+:14];
                        v1 = verts[(i+1)*14+:14];
                        v2 = verts[(i+2)*14+:14];
                        drawLine(v0[13:7], v0[6:0], v1[13:7], v1[6:0], r0, g0, b0);
                        drawLine(v1[13:7], v1[6:0], v2[13:7], v2[6:0], r0, g0, b0);
                        drawLine(v2[13:7], v2[6:0], v0[13:7], v0[6:0], r0, g0, b0);
                    end
                end
                2: begin // fill
                    for (i = 0; i < size; i = i + 3) begin

                    end
                end
                default: begin

                end
            endcase
        end
    endtask

endmodule
