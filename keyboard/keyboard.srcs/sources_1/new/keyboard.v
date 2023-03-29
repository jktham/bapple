`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2023 04:54:56 PM
// Design Name: 
// Module Name: keyboard
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


module keyboard(
    input clk,
    input btnC,
    input btnL,
    input btnR,
    input RsRx,
    output reg led,
    output reg dp,
    output reg [3:0]an,
    output reg [0:6]seg,
    output reg RsTx
);
    reg [32:0]update_clock;
    reg [32:0]baud_clock;
    reg update_tick;
    reg baud_tick;
    
    integer letter;
    reg transmit;
    reg [7:0] data;
    integer data_index;
    
    always @ (posedge clk) begin
        update_clock = update_clock + 1;
        if (update_clock >= 50000000 / 2) begin
            update_tick = ~update_tick;
            update_clock = 0;
        end
        
        baud_clock = baud_clock + 1;
        if (baud_clock >= 50000000 / 1200) begin
            baud_tick = ~baud_tick;
            baud_clock = 0;
        end
    end
    
    always @ (posedge baud_tick) begin
        RsTx = 1;
        if (transmit) begin
            case (data_index)
                0: RsTx = 0;
                1: RsTx = data[0];
                2: RsTx = data[1];
                3: RsTx = data[2];
                4: RsTx = data[3];
                5: RsTx = data[4];
                6: RsTx = data[5];
                7: RsTx = data[6];
                8: RsTx = 1;
                default: RsTx = 1;
             endcase
             data_index = data_index + 1;
        end else
            data_index = 0;
    end
    
    always @ (posedge baud_tick) begin
        if (btnC | btnL | btnR)
            transmit = 1;
        else
            transmit = 0;
        
        if (btnC)
            data = letter + 7'b1100001;
        else if (btnL)
            data = 7'b0001000;
        else if (btnR)
            data = 7'b0001010;
        
    end
    
    always @ (posedge update_tick) begin
        letter = (letter + 1) % 26;
        led = ~led;
        dp = 1;
        an = 4'b1110;
        case (letter)
            0: seg = 7'b1110111;
            1: seg = 7'b0011111;
            2: seg = 7'b1001110;
            3: seg = 7'b0111101;
            4: seg = 7'b1001111;
            5: seg = 7'b1000111;
            6: seg = 7'b1011110;
            7: seg = 7'b0110111;
            8: seg = 7'b0000110;
            9: seg = 7'b0111100;
            10: seg = 7'b1010111;
            11: seg = 7'b0001110;
            12: seg = 7'b1101010;
            13: seg = 7'b0010101;
            14: seg = 7'b1111110;
            15: seg = 7'b1100111;
            16: seg = 7'b1110011;
            17: seg = 7'b0000101;
            18: seg = 7'b1011011;
            19: seg = 7'b0001111;
            20: seg = 7'b0111110;
            21: seg = 7'b0101010;
            22: seg = 7'b0111111;
            23: seg = 7'b1001001;
            24: seg = 7'b0111011;
            25: seg = 7'b1101101;
            default: seg = 7'b0000000;
        endcase
        seg[0] <= ~seg[0];
        seg[1] <= ~seg[1];
        seg[2] <= ~seg[2];
        seg[3] <= ~seg[3];
        seg[4] <= ~seg[4];
        seg[5] <= ~seg[5];
        seg[6] <= ~seg[6];
    end
endmodule
