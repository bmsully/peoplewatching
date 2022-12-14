`timescale 1ns / 1ps
`default_nettype none

module convolution_9_layer_tb;
  logic clk;
  logic rst;

  logic signed [20:0] data;
  logic [4:0] hcount_in, hcount_out;
  logic [4:0] vcount_in, vcount_out;
  logic data_valid_in, data_valid_out;
  logic signed [8:0][17:0] weights_in;
  logic signed [20:0] pixel_data_out;


  /* A quick note about this simulation! Most waveform viewers
   * (including GTKWave) don't display arrays in their output
   * unless the array is packed along all dimensions. This is
   * to prevent the amount of data GTKWave has to render from 
   * getting too large, but it also means you'll have to use
   * $display statements to read out from your arrays.
  */

  convolution_layer_9 uut (
    .clk_in(clk),
    .rst_in(rst),
    .pixel_data_in(data),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .data_valid_in(data_valid_in),

    .data_valid_out(data_valid_out),
    .hcount_out(hcount_out),
    .vcount_out(vcount_out),
    .pixel_data_out(pixel_data_out));



  always begin
    #5;
    clk = !clk;
  end

  initial begin
    $dumpfile("convolution_9.vcd");
    $dumpvars(0, convolution_9_layer_tb);
    $display("Starting Sim");
    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;
    data_valid_in = 1;
    #40

    for (int i = 0; i<32; i= i+1)begin
      for (int j = 0; j<24; j= j+1)begin
        hcount_in = j;
        vcount_in = i;
        // pixel_data_in = 24*i + j;
        data = 0;
        data_valid_in = 1;
        #100;
        $display("data %d hcount_in %d vcount_in %d hcount_out %d vcount_out %d pixel_data_out %d data_valid_out %d",
        data, hcount_in, vcount_in, hcount_out, vcount_out, pixel_data_out, data_valid_out);
        data_valid_in = 0;
      end
    end

    // $display("Test 1: {go girl give us nothing}");
    // data_valid_in = 1;
    // data[0] = {5'd0, 6'd0, 5'd0};
    // data[1] = {5'd0, 6'd0, 5'd0};
    // data[2] = {5'd0, 6'd0, 5'd0};
    // #10;
    // data[0] = {5'd0, 6'd0, 5'd0};
    // data[1] = {5'd0, 6'd0, 5'd0};
    // data[2] = {5'd0, 6'd0, 5'd0};
    // #10;
    // data[0] = {5'd0, 6'd0, 5'd0};
    // data[1] = {5'd0, 6'd0, 5'd0};
    // data[2] = {5'd0, 6'd0, 5'd0};
    // #10;
    // data_valid_in = 0;
    // #20
    // $display("line_out: (unsigned): %h", line_out);
    // $display("RGB: %3d %3d %3d", r, g, b);
    // #20;

    // $display("Test 1: {gAuSsIAn}");
    // data_valid_in = 1;
    // data[0] = {5'd00002, 6'd000001, 5'd00001};
    // data[1] = {5'd00001, 6'd000001, 5'd00001};
    // data[2] = {5'd00001, 6'd000001, 5'd00001};
    // #10;
    // data[0] = {5'd00001, 6'd000001, 5'd00001};
    // data[1] = {5'd00001, 6'd000002, 5'd00001};
    // data[2] = {5'd00001, 6'd000001, 5'd00001};
    // #10;
    // data[0] = {5'd00002, 6'd000002, 5'd00001};
    // data[1] = {5'd31, 6'd000001, 5'd00001};
    // data[2] = {5'd00002, 6'd000002, 5'd00002};
    // #10;
    // data_valid_in = 0;
    // #20
    // $display("line_out: (unsigned): %h", line_out);
    // $display("RGB: %3d %3d %3d", r, g, b);
    // #20;

    $display("Finishing Sim");
    $finish;
  end
endmodule // convolution_tb

`default_nettype wire
