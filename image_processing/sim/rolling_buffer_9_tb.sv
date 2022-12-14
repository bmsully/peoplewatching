`timescale 1ns / 1ps
`default_nettype none

module buffer_tb;
  logic clk;
  logic rst;

  logic [4:0] hcount_in, hcount_out;
  logic [4:0] vcount_in, vcount_out;
  logic data_valid_in, data_valid_out;
  logic [20:0] pixel_data_in;
  logic [8:0][20:0] line_buffer_out; //make this 2D packed

  /* A quick note about this simulation! Most waveform viewers
   * (including GTKWave) don't display arrays in their output
   * unless the array is packed along all dimensions. This is
   * to prevent the amount of data GTKWave has to render from 
   * getting too large, but it also means you'll have to use
   * $display statements to read out from your arrays.
  */

  buffer uut (
    .clk_in(clk),
    .rst_in(rst),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .pixel_data_in(pixel_data_in),
    .data_valid_in(data_valid_in),

    .line_buffer_out(line_buffer_out),
    .hcount_out(hcount_out),
    .vcount_out(vcount_out),
    .data_valid_out(data_valid_out));

  always begin
    #5;
    clk = !clk;
  end

  initial begin
    $dumpfile("buffer.vcd");
    $dumpvars(0, buffer_tb);
    $display("Starting Sim");
    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;

    for (int i = 0; i<32; i= i+1)begin
      for (int j = 0; j<24; j= j+1)begin
        hcount_in = j;
        vcount_in = i;
        pixel_data_in = 24*i + j;
        data_valid_in = 1;
        #10;
        $display("hcount_in %d vcount_in %d hcount_out %d vcount_out %d pixel_data_in %d line_buffer_out[0] %d line_buffer_out[1] %d line_buffer_out[2] %d line_buffer_out[3] %d line_buffer_out[4] %d line_buffer_out[5] %d line_buffer_out[6] %d line_buffer_out[7] %d line_buffer_out[8] %d data_valid_out %d",
        hcount_in, vcount_in, hcount_out, vcount_out, pixel_data_in, line_buffer_out[0], line_buffer_out[1], line_buffer_out[2], line_buffer_out[3], line_buffer_out[4], line_buffer_out[5], line_buffer_out[6], line_buffer_out[7], line_buffer_out[8], data_valid_out);
        $display();
      end
    end

    data_valid_in = 0;
    // Your code here!

    $display("Finishing Sim");
    $finish;
  end
endmodule //buffer_tb

`default_nettype wire
