`default_nettype none
`timescale 1ns / 1ps

module bitorder (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,

    output logic axiov,
    output logic [1:0] axiod
);
    logic [7:0] buf_a, buf_b;
    logic read_buf;
    logic [1:0] buf_counter;

    localparam IDLE = 0;
    localparam RNOW = 1; // Read, no write (start of sequence)
    localparam RANDW = 2; // Read and write (middle of sequence)
    localparam WNOR = 3; // Write, no read (end of sequence)
    logic [1:0] state;

    always_ff @(posedge clk) begin
        if (rst) begin
            read_buf <= 1'b0;
            buf_counter <= 0;
            buf_a <= 8'b0;
            buf_b <= 8'b0;
            axiov <= 1'b0;
            state <= IDLE;
        end
        case (state)
            IDLE: begin
                axiod <= 2'b0;
                axiov <= 1'b0;
                if (axiiv == 1'b1) begin
                    buf_b <= 8'b0;
                    buf_a <= {axiid, 6'b0};
                    read_buf <= 1'b0;
                    buf_counter <= 0;
                    state <= RNOW;
                end
            end
            RNOW: begin
                if (axiiv == 1'b1) begin
                    if (buf_counter == 3) begin // go-to RANDW
                        buf_b <= {axiid, buf_b[7:2]};
                        axiod <= buf_a[7:6]; // output is from buf_a
                        axiov <= 1'b1; // write buffer is buf_a
                        read_buf <= ~read_buf;
                        buf_counter <= 0;
                        state <= RANDW;
                    end else begin
                        buf_a <= {axiid, buf_a[7:2]};
                        buf_counter <= buf_counter + 1;
                    end
                end else begin // valid went low
                    if (buf_counter == 3) begin // go-to WNOR
                        axiod <= buf_a[7:6]; // output is from buf_a
                        axiov <= 1'b1; // write buffer is buf_a
                        read_buf <= 1'b1;
                        buf_counter <= 0;
                        state <= WNOR;
                    end else begin
                        buf_counter <= 0;
                        buf_a <= 8'b0;
                        state <= IDLE;
                    end
                end
            end
            RANDW: begin
                axiov <= 1'b1;
                if (axiiv == 1'b1) begin
                    if (read_buf == 1'b0) begin
                        case (buf_counter)
                            3: begin
                                buf_b <= {axiid, buf_b[7:2]};
                                axiod <= buf_a[7:6];
                            end
                            0: begin
                                buf_a <= {axiid, buf_a[7:2]};
                                axiod <= buf_b[5:4];
                            end
                            1: begin
                                buf_a <= {axiid, buf_a[7:2]};
                                axiod <= buf_b[3:2];
                            end
                            2: begin
                                buf_a <= {axiid, buf_a[7:2]};
                                axiod <= buf_b[1:0];
                            end
                        endcase
                    end else begin
                        case (buf_counter)
                            3: begin 
                                buf_a <= {axiid, buf_a[7:2]};
                                axiod <= buf_b[7:6];
                            end
                            0: begin
                                buf_b <= {axiid, buf_b[7:2]};
                                axiod <= buf_a[5:4];
                            end
                            1: begin
                                buf_b <= {axiid, buf_b[7:2]};
                                axiod <= buf_a[3:2];
                            end
                            2: begin
                                buf_b <= {axiid, buf_b[7:2]};
                                axiod <= buf_a[1:0];
                            end
                        endcase
                    end
                    if (buf_counter == 3) begin
                        read_buf <= ~read_buf;
                        buf_counter <= 0;
                    end else begin
                        buf_counter <= buf_counter + 1;
                    end
                end else begin // handle invalid i.e. transition to WNOR
                    if (read_buf == 1'b0) begin
                        case (buf_counter)
                            3: begin
                                axiod <= buf_a[7:6];
                            end
                            0: begin
                                axiod <= buf_b[5:4];
                            end
                            1: begin
                                axiod <= buf_b[3:2];
                            end
                            2: begin
                                axiod <= buf_b[1:0];
                            end
                        endcase
                    end else begin
                        case (buf_counter)
                            3: begin
                                axiod <= buf_b[7:6];
                            end
                            0: begin
                                axiod <= buf_a[5:4];
                            end
                            1: begin
                                axiod <= buf_a[3:2];
                            end
                            2: begin
                                axiod <= buf_a[1:0];
                            end
                        endcase
                    end
                    axiov <= 1'b1;
                    if (buf_counter == 3) begin
                        buf_counter <= 0;
                        read_buf <= ~read_buf;
                        state <= WNOR;
                    end else begin
                        buf_counter <= buf_counter + 1;
                        state <= WNOR;
                    end
                end
            end
            WNOR: begin
                axiov <= 1'b1;
                // if (axiiv == 1'b0) begin
                    if (read_buf == 1'b0) begin
                        case (buf_counter)
                            3: begin 
                                axiod <= buf_b[7:6];
                            end
                            0: begin 
                                axiod <= buf_b[5:4];
                            end
                            1: begin 
                                axiod <= buf_b[3:2];
                            end
                            2: begin 
                                axiod <= buf_b[1:0];
                            end
                        endcase
                    end else begin
                        case (buf_counter)
                            3: begin 
                                axiod <= buf_a[7:6];
                            end
                            0: begin 
                                axiod <= buf_a[5:4];
                            end
                            1: begin 
                                axiod <= buf_a[3:2];
                            end
                            2: begin 
                                axiod <= buf_a[1:0];
                            end
                        endcase
                    end
                    if (buf_counter == 3) begin
                        axiov <= 1'b0;
                        axiod <= 2'b00;
                        buf_counter <= 0;
                        state <= IDLE;
                    end else buf_counter <= buf_counter + 1; 
                // end else begin // handle new sequence i.e. transition to RNOW

                // end
            end
        endcase
    end


endmodule

`default_nettype wire