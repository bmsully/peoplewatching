`default_nettype none
`timescale 1ns / 1ps

module rether (
    input wire clk, // 50 MHz clock
    input wire rst, // System reset
    input wire crsdv, // Data valid input
    input wire [1:0] rxd, // Data input bus

    output logic axiov, // Output valid
    output logic [1:0] axiod // Output data bus
);
    localparam IDLE = 0;
    localparam VALIDATE = 1;
    localparam TRANSMIT = 2;
    localparam FALSECARRIER = 3;
    localparam RESET = 4;

    logic [2:0] state;
    logic [4:0] preamble_count;
    logic [1:0] sfd_count;

    always_ff @(posedge clk) begin
        if (rst == 1'b1) begin
            state <= IDLE;
            preamble_count <= 0;
            sfd_count <= 0;
            axiov <= 1'b0;
        end
        case (state)
            IDLE: begin
                if (crsdv == 1'b1 && rxd == 2'b01)begin
                    state <= VALIDATE;
                    preamble_count <= 1;
                    sfd_count <= 0;
                    axiov <= 1'b0;
                end
            end
            VALIDATE: begin
                if (crsdv == 1'b1)begin
                    if (preamble_count < 28)begin // check preamble
                        if (rxd == 2'b01)begin // count preamble
                            preamble_count <= preamble_count + 1;
                        end else begin
                            state <= FALSECARRIER;
                        end
                    end else begin // check SFD
                        case (sfd_count)
                            2'b00: begin
                                if (rxd == 2'b01) begin
                                    sfd_count <= sfd_count + 1;
                                end else begin
                                    state <= FALSECARRIER;
                                end
                            end
                            2'b01: begin
                                if (rxd == 2'b01) begin
                                    sfd_count <= sfd_count + 1;
                                end else begin
                                    state <= FALSECARRIER;
                                end
                            end
                            2'b10:  begin
                                if (rxd == 2'b01) begin
                                    sfd_count <= sfd_count + 1;
                                end else begin
                                    state <= FALSECARRIER;
                                end
                            end
                            2'b11:  begin
                                if (rxd == 2'b11) begin
                                    state <= TRANSMIT;
                                end else begin
                                    state <= FALSECARRIER;
                                end
                            end
                            default: begin 
                                state <= FALSECARRIER;
                            end
                        endcase
                    end
                end else begin
                    state <= RESET;
                end
            end
            TRANSMIT: begin
                if (crsdv == 1'b1) begin
                    axiov <= 1'b1;
                    axiod <= rxd;
                end else begin
                    axiov <= 1'b0;
                    state <= RESET;
                end
            end
            FALSECARRIER: begin
                if (crsdv == 1'b0) begin
                    preamble_count <= 0;
                    sfd_count <= 0;
                    state <= IDLE;
                end
            end
            RESET: begin
                state <= IDLE;
                preamble_count <= 0;
                sfd_count <= 0;
            end
        endcase
    end
endmodule

`default_nettype wire
