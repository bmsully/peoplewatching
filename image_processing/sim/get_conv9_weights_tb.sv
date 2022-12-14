`timescale 1ns / 1ps
`default_nettype none

module get_conv9_weights_tb;
  logic clk;
  logic rst;
  
  logic [8:0][17:0] conv_9_weight_row;
  logic data_valid_in, data_valid_out;

  /* A quick note about this simulation! Most waveform viewers
   * (including GTKWave) don't display arrays in their output
   * unless the array is packed along all dimensions. This is
   * to prevent the amount of data GTKWave has to render from 
   * getting too large, but it also means you'll have to use
   * $display statements to read out from your arrays.
  */

get_conv9_weights get_conv9_weights_m (
    .clk_in(clk), //system clock
    .rst_in(rst),
    .data_valid_in(data_valid_in),

    .conv_9_weight_row(conv_9_weight_row),
    .data_valid_out(data_valid_out) //valid data out signal
  );

  always begin
    #5;
    clk = !clk;
  end

  initial begin
    $dumpfile("get_conv9_weights_tb.vcd");
    $dumpvars(0, get_conv9_weights_tb);
    $display("Starting Sim");
    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;

    data_valid_in = 0;

    #10;
    data_valid_in = 1;
    #20;
    for (int i = 0; i<9; i= i+1)begin
        data_valid_in = 1;
        #10;
        $display("data_valid_out %b conv_9_weight_row[0] %b conv_9_weight_row[1] %b conv_9_weight_row[7] %b conv_9_weight_row[8] %b", data_valid_out, conv_9_weight_row[0], conv_9_weight_row[1], conv_9_weight_row[7], conv_9_weight_row[8]);
        data_valid_in = 0;
        rst = 0;
    end


    data_valid_in = 0;
    // Your code here!

    $display("Finishing Sim");
    $finish;
  end
endmodule //buffer_tb

`default_nettype wire
