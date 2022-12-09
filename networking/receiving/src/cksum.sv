`default_nettype none
`timescale 1ns / 1ps

module cksum (
    input wire clk, // 50 MHz clock
    input wire rst, // System reset
    input wire axiiv, // Data valid input
    input wire [1:0] axiid, // Data input bus

    output logic done, // CRC completed
    output logic kill // CRC success/fail
);
    logic crc_axiov;
    logic [31:0] crc_axiod;
    logic [31:0] checksum = 32'b00111000_11111011_00100010_10000100; // 32'h38_fb_22_84

    localparam IDLE = 0;
    localparam BUSY = 1;
    logic state;

    logic crc_rst, manual_rst;
    assign crc_rst = rst | manual_rst;

    crc32 mycrc (
        .clk(clk),
        .rst(crc_rst),
        .axiiv(axiiv),
        .axiid(axiid),
        .axiov(crc_axiov),
        .axiod(crc_axiod)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            done <= 1'b0;
            kill <= 1'b0;
            state <= IDLE;
        end
        case (state)
            IDLE: begin
                manual_rst <= 1'b0;
                if (axiiv == 1'b1) begin
                    done <= 1'b0;
                    kill <= 1'b0;
                    state <= BUSY;
                end
            end
            BUSY: begin
                if (axiiv == 1'b0) begin
                    done <= 1'b1;
                    kill <= (crc_axiod == checksum) ? 1'b0 : 1'b1;
                    state <= IDLE;
                    manual_rst <= 1'b1;
                end
            end
        endcase
    end
    
endmodule

`default_nettype wire
