`timescale 1ns / 1ps
`default_nettype none

module bw_converter_tb;
  //make logics for inputs and outputs!


  logic clk_in;
  logic [10:0] hcount_in;
  logic [9:0] vcount_in;
  logic data_valid_in;
  logic [15:0] pixel_in;
  logic pixel_out;
  logic [10:0] hcount_out;
  logic [9:0] vcount_out;
  logic data_valid_out;

    bw_converter uut (
  .clk_in(clk_in),
  .hcount_in(hcount_in),
  .vcount_in(vcount_in),
  .data_valid_in(data_valid_in),
  .pixel_in(pixel_in),
  .pixel_out(pixel_out),
  .hcount_out(hcount_out),
  .vcount_out(vcount_out),
  .data_valid_out(data_valid_out)
  );

  always begin
    #5;
    clk_in = !clk_in;
  end


  //initial block...this is our test simulation
  initial begin
    $display("Starting Sim"); //print nice message
    $dumpfile("bw_converter.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,bw_converter_tb); //store everything at the current level and below
    $display("Testing assorted values");
    clk_in = 0;

    data_valid_in = 0;
    hcount_in = 42;
    vcount_in = 69;
    #10;
    data_valid_in = 1;
    pixel_in = 16'b00000_000000_00000;
    #10;

    $display("pixel_out=%4d", pixel_out);

    data_valid_in = 0;
    hcount_in = 42;
    vcount_in = 69;
    #10;
    data_valid_in = 1;
    #10;
    pixel_in = 16'b11111_111111_11111;
    #10;

    $display("pixel_out=%4d", pixel_out);

    data_valid_in = 0;
    hcount_in = 42;
    vcount_in = 69;
    #10;
    data_valid_in = 1;
    #10;
    pixel_in = 16'b00000_111111_00000;
    #10;

    $display("pixel_out=%4d", pixel_out);

    
    $display("Finishing Sim"); //print nice message
    $finish;

  end
endmodule //bw_converter_tb

`default_nettype wire
