`timescale 1ns / 1ps
`default_nettype none

module center_of_mass (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in,
                         input wire tabulate_in,
                         output logic [10:0] x_out,
                         output logic [9:0] y_out,
                         output logic valid_out);

  //your design here!
  logic [31:0] x_sum;
  logic [31:0] y_sum;
  logic [31:0] num_pixels;

  logic [31:0] x_out_32;
  logic [31:0] y_out_32;

  logic divider_valid_in;
  logic x_divider_valid_out;
  logic x_divider_error_out;
  logic x_divider_busy_out;
  logic [31:0] x_divider_remainder;
  logic y_divider_valid_out;
  logic y_divider_error_out;
  logic y_divider_busy_out;
  logic [31:0] y_divider_remainder;

  logic x_divider_valid_out_hold;
  logic y_divider_valid_out_hold;
  

  always_ff @(posedge clk_in)begin
    if (rst_in) begin
      num_pixels <= 0;
      x_sum <= 0;
      y_sum <= 0;
      x_divider_valid_out_hold <= 1'b0;
      y_divider_valid_out_hold <= 1'b0;
      valid_out <= 1'b0;
    end
    if (valid_in) begin
      x_sum <= x_sum + x_in;
      y_sum <= y_sum + y_in;
      num_pixels <= num_pixels + 1;
    end

    if (tabulate_in) begin
      divider_valid_in <= 1'b1;
    end else if (divider_valid_in) begin
      divider_valid_in <= 1'b0;
    end

    if (x_divider_valid_out) begin
      x_divider_valid_out_hold <= 1'b1;
    end
    if (y_divider_valid_out) begin
      y_divider_valid_out_hold <= 1'b1;
    end
 
    if (valid_out) begin
      valid_out <= 1'b0;
      x_sum <= 0;
      y_sum <= 0;
      num_pixels <= 0;
    end
    else if (x_divider_valid_out_hold && y_divider_valid_out_hold) begin
      x_out <= x_out_32[10:0];
      y_out <= y_out_32[9:0];
      valid_out <= 1'b1;
      x_divider_valid_out_hold <= 1'b0;
      y_divider_valid_out_hold <= 1'b0;
    end
    else if (x_divider_error_out || y_divider_error_out) begin
      x_sum <= 0;
      y_sum <= 0;
      num_pixels <= 0;
    end
    
  end

  divider x_divider (.clk_in(clk_in), .rst_in(rst_in), .dividend_in(x_sum), .divisor_in(num_pixels),
  .data_valid_in(divider_valid_in), .quotient_out(x_out_32), .remainder_out(x_divider_remainder),
  .data_valid_out(x_divider_valid_out), .error_out(x_divider_error_out), .busy_out(x_divider_busy_out));

  divider y_divider (.clk_in(clk_in), .rst_in(rst_in), .dividend_in(y_sum), .divisor_in(num_pixels),
  .data_valid_in(divider_valid_in), .quotient_out(y_out_32), .remainder_out(y_divider_remainder),
  .data_valid_out(y_divider_valid_out), .error_out(y_divider_error_out), .busy_out(y_divider_busy_out));

  // module divider #(parameter WIDTH = 32) (input wire clk_in,
  //               input wire rst_in,
  //               input wire[WIDTH-1:0] dividend_in,
  //               input wire[WIDTH-1:0] divisor_in,
  //               input wire data_valid_in,
  //               output logic[WIDTH-1:0] quotient_out,
  //               output logic[WIDTH-1:0] remainder_out,
  //               output logic data_valid_out,
  //               output logic error_out,
  //               output logic busy_out);

endmodule

`default_nettype wire
