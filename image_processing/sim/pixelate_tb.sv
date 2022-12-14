`timescale 1ns / 1ps
`default_nettype none

module pixelate_tb;
  //make logics for inputs and outputs!


  logic clk_in;
  logic [10:0] hcount_in;
  logic [9:0] vcount_in;
  logic data_valid_in;
  logic pixel_in;
  logic pixel_out;
  logic [4:0] hcount_out;
  logic [4:0] vcount_out;
  logic data_valid_out;

  logic signed [20:0] pixelate_normalize;
  logic [4:0] hcount_normalize;
  logic [4:0] vcount_normalize;
  logic data_valid_normalize;

    pixelate uut (
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
  normalize uut1 (
  .clk_in(clk_in),
  .hcount_in(hcount_out),
  .vcount_in(vcount_out),
  .data_valid_in(data_valid_out),
  .pixel_in(pixel_out),
  .pixel_out(pixelate_normalize),
  .hcount_out(hcount_normalize),
  .vcount_out(vcount_normalize),
  .data_valid_out(data_valid_normalize)
  );

  always begin
    #5;
    clk_in = !clk_in;
  end


  //initial block...this is our test simulation
  initial begin
    $display("Starting Sim"); //print nice message
    $dumpfile("pixelate.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,pixelate_tb); //store everything at the current level and below
    $display("Testing assorted values");
    clk_in = 0;

    data_valid_in = 0;

    for (int h = 0; h<30; h = h + 1)begin
      for (int v = 0; v<30; v = v+1)begin
        hcount_in = h;
        vcount_in = v;
        if (v == 5 || v == 25)begin
            pixel_in = 1;
        end else begin
            pixel_in = 0;
        end
        data_valid_in = 1;
        #10

        $display("data_valid_in=%4d vcount_in= %3d hcount_in=%3d pixel_in=%2b",data_valid_in, vcount_in, hcount_in, pixel_in); //print nice message
        $display("data_valid_out=%4d vcount_out= %3d hcount_out=%3d pixel_out=%2b",data_valid_out, vcount_out, hcount_out, pixel_out); //print nice message
        

        #10

        data_valid_in = 0;

        $display("pixelate_normalize=%6d data_valid_normalize=%1d", pixelate_normalize, data_valid_normalize);
        $display();

        
      end
    end

    
    $display("Finishing Sim"); //print nice message
    $finish;

  end
endmodule //pixelate_tb

`default_nettype wire
