`default_nettype none
`timescale 1ns / 1ps

module aggregate (
    input wire clk, // 50 MHz clock
    input wire rst, // System reset
    input wire axiiv, // Data valid input
    input wire [1:0] axiid, // Data input bus

    output logic axiov, // Output valid
    output logic [31:0] axiod // Output data bus
);
    localparam IDLE = 0;
    localparam DATA = 1;
    localparam FCS = 2;
    localparam IGNORE = 3;
    logic [1:0] state;

    logic [4:0] counter;

    always_ff @(posedge clk) begin
        if (rst) begin
            axiov <= 1'b0;
            axiod <= 32'b0;
            counter <= 0;
            state <= IDLE;
        end
        case (state)
            IDLE: begin
                if (axiiv) begin
                    axiod <= {30'b0, axiid};
                    counter <= 0;
                    state <= DATA;
                end
            end
            DATA: begin
                if (axiiv) begin
                    if (counter == 15) begin
                        counter <= counter + 1;
                        state <= FCS;
                    end else begin
                        axiod <= {axiod[29:0], axiid};
                        counter <= counter + 1;
                    end
                end else begin
                    counter <= 0;
                    state <= IDLE;
                end
            end
            FCS: begin
                if (counter == 31) begin
                    // state <= 1'b1;
                    counter <= 0;
                    state <= axiiv == 1'b1 ? IGNORE : IDLE;
                end else begin
                    if (axiiv) begin
                        counter <= counter + 1;
                    end else begin
                        counter <= 0;
                        state <= IDLE;
                    end
                end
            end
            IGNORE: begin
                if (axiiv == 1'b0) begin
                    state <= IDLE;
                end
            end
        endcase
    end

    always_comb begin
        if (rst) begin
            axiov = 1'b0;
        end else if (counter == 31 && axiiv == 1'b1) begin
            axiov = 1'b1;
        end else begin
            axiov = 1'b0;
        end
    end
    
endmodule

`default_nettype wire
