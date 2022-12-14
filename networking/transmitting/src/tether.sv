`default_nettype none
`timescale 1ns / 1ps

module tether (
    input wire clk, // 50 MHz clock
    input wire rst, // System reset
    input wire axiiv, // Data valid input
    input wire [1:0] axiid, // Data input bus

    output logic axiov, // Output valid
    output logic [1:0] axiod // Output data bus
);
    localparam IDLE = 0;
    localparam PREAMBLESFD = 1;
    localparam READTRANSMIT = 2; // Data input valid and transmitting
    localparam TRANSMIT = 3; // Data input no longer valid and transmitting
    localparam FCS = 4;
    // localparam IPG = 5; // Interpacket gap
    logic [2:0] state;

    logic [7:0] sfd = 8'b11010101;

    logic [63:0] data_buf; // data stored while start of frame sent
    logic reading_data; // check signal to avoid errant data after going low
    int data_counter; // Need to count to 63 (64 bits)
    logic [5:0] cycle_counter; // Need to count to 32 (cycles)
    int padding_counter;

    logic crcov, checksum_collected;
    logic [31:0] crc_output, fcs_buf;

    logic crc_rst, manual_rst;
    assign crc_rst = rst | manual_rst;

    crc32 build_checksum (
        .clk(clk), 
        .rst(crc_rst),
        .axiiv(axiiv), 
        .axiid(axiid), 
        .axiov(crcov), 
        .axiod(crc_output)
        );

    always_ff @(posedge clk) begin
        if (rst == 1'b1) begin
            axiov <= 1'b0;
            axiod <= 2'b0;
            checksum_collected = 1'b0;
            data_counter <= 0;
            padding_counter <= 0;
            cycle_counter <= 5'b0;
            state <= IDLE;
        end
        case (state)
            IDLE: begin
                manual_rst <= 1'b0;
                if (axiiv == 1'b1) begin
                    axiov <= 1'b1;
                    checksum_collected = 1'b0;
                    data_buf <= {62'b0, axiid};
                    reading_data <= 1'b1;
                    data_counter <= 1;
                    padding_counter <= 183;

                    axiod <= 2'b01;
                    cycle_counter <= 0;

                    state <= PREAMBLESFD;
                end else begin
                    axiov <= 1'b0;
                    axiod <= 2'b00;
                end
            end
            PREAMBLESFD: begin
                cycle_counter <= cycle_counter + 1;
                if (cycle_counter < 27) begin // send preamble
                    axiov <= 1'b1;
                    axiod <= 2'b01; 
                end else if (cycle_counter >= 27 && cycle_counter < 31) begin // Send sfd
                    // Read LSb
                    axiov <= 1'b1;
                    axiod <= sfd[1:0];
                    sfd <= {sfd[1:0], sfd[7:2]};
                end else begin // Send first data
                    if (axiiv == 1'b1 && reading_data == 1'b1) begin // still reading
                        axiov <= 1'b1;
                        axiod <= data_buf[63:62];
                        data_buf <= {data_buf[61:0], axiid};
                        padding_counter <= padding_counter - 1;
                        state <= READTRANSMIT;
                    end else begin // no longer reading i.e. static 
                        axiov <= 1'b1;
                        reading_data <= 1'b0;
                        axiod <= {data_buf[data_counter], data_buf[data_counter-1]};
                        data_counter <= data_counter - 2;
                        state <= TRANSMIT;
                    end
                end
                if (cycle_counter < 31) begin 
                    if (axiiv == 1'b1 && reading_data == 1'b1) begin
                        data_buf <= {data_buf[61:0], axiid};
                        data_counter <= data_counter + 2;
                        padding_counter <= padding_counter - 1;
                    end else begin
                        if (~checksum_collected) begin
                            checksum_collected <= 1'b1;
                            fcs_buf <= crc_output;
                        end
                        reading_data <= 1'b0;
                    end
                end
            end
            READTRANSMIT: begin
                if (axiiv == 1'b1 && reading_data == 1'b1) begin
                    axiov <= 1'b1;
                    axiod <= data_buf[63:62]; 
                    data_buf <= {data_buf[61:0], axiid}; 
                    padding_counter <= padding_counter - 1;
                end else begin
                    if (~checksum_collected) begin
                        checksum_collected <= 1'b1;
                        fcs_buf <= crc_output;
                    end
                    axiov <= 1'b1;
                    reading_data <= 1'b0;
                    axiod <= {data_buf[data_counter], data_buf[data_counter-1]};
                    data_counter <= data_counter - 2;
                    state <= TRANSMIT;
                end
            end
            TRANSMIT: begin
                if (data_counter > 0) begin
                    axiov <= 1'b1;
                    axiod <= {data_buf[data_counter], data_buf[data_counter-1]};
                    data_counter <= data_counter - 2;
                end else begin
                    if (padding_counter > 0) begin
                        axiov <= 1'b1;
                        axiod <= 2'b00;
                        padding_counter <= padding_counter - 1;
                    end else begin
                        axiov <= 1'b1;
                        axiod <= {fcs_buf[31], fcs_buf[30]};
                        fcs_buf <= {fcs_buf[29:0], fcs_buf[31:30]};
                        data_counter <= 0;
                        cycle_counter <= 0;
                        state <= FCS; 
                    end
                end
            end
            FCS: begin
                cycle_counter <= cycle_counter + 1;
                if (cycle_counter < 15) begin
                    axiov <= 1'b1;
                    axiod <= {fcs_buf[31], fcs_buf[30]};
                    fcs_buf <= {fcs_buf[29:0], fcs_buf[31:30]};
                end else begin
                    axiov <= 1'b0;
                    axiod <= 2'b00;
                    manual_rst <= 1'b1;
                    state <= IDLE;
                    // signal to start IPG
                end
            end
        endcase
    end
endmodule

`default_nettype wire
