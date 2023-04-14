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


module renderer(
    input clk,
    input [4:0] btn,
    input [15:0] sw,
    output reg [6:0] seg,
    output reg dp,
    output reg [3:0] an,

    input drawBuffer,
    input [31:0] pixel,
    input [31:0] frame,
    output reg [15:0] buffer
);

    //reg [15:0] buffer [16383:0]; // hang on i dont even need this anymore wtf was i planning
    reg [31:0] scene;
    reg btnPressed;
    
    initial begin

    end

    always @ (posedge clk) begin
        // render
        if (drawBuffer) begin : JIMOTHY
            reg [31:0] p, f, x, y, r, g, b;
            // inputs
            p = pixel; // 0 - 16383
            f = frame; // 0 - maxint
            x = pixel[6:0]; // 0 - 127
            y = pixel[13:7]; // 0 - 127
            // outputs
            r = 0; // 0 - 63, lsb discarded
            g = 0; // 0 - 63
            b = 0; // 0 - 63, lsb discarded

            case (scene)
                0: begin
                    r = x[6:1];
                    b = y[6:1];
                end
                1: begin
                    if (x < 32) begin

                    end else if (x < 64) begin
                        r = 63;
                    end else if (x < 96) begin
                        g = 63;
                    end else begin
                        b = 63;
                    end

                    if (y < 32) begin

                    end else if (y < 64) begin
                        r = 63;
                    end else if (y < 96) begin
                        g = 63;
                    end else begin
                        b = 63;
                    end
                end
                2: begin
                    g = f[5:0];
                end
                3: begin
                    if ((x-63)**2 + (y-63)**2 <= 32**2 + 32 && (x-63)**2 + (y-63)**2 >= 32**2 - 32) begin
                        r = 63;
                        g = 63;
                        b = 63;
                    end
                end
            endcase

            buffer = {b[5:1], g[5:0], r[5:1]};
        end

        // input
        if (btn[1] & !btnPressed) begin // prev scene
            scene = scene - 1;
            btnPressed = 1;
        end
        if (btn[3] & !btnPressed) begin // next scene
            scene = scene + 1;
            btnPressed = 1;
        end
        if (btn[2] & !btnPressed) begin // default scene
            scene = 0;
            btnPressed = 1;
        end
        if (!btn[1] & !btn[2] & !btn[3] & btnPressed) begin
            btnPressed = 0;
        end

        // ui
        an <= 4'b1110;
        case (scene)
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
        if (drawBuffer) begin
            dp <= 0;
        end else begin
            dp <= 1;
        end

    end

endmodule
