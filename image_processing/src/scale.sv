`timescale 1ns / 1ps
`default_nettype none

module scale(
  input wire [1:0] scale_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire [15:0] frame_buff_in,
  output logic [15:0] cam_out
);
  
  logic [10:0] x_lim;
  logic [9:0] y_lim;
  
  always_comb begin
    if (scale_in == 2'b00) begin
      x_lim = 240;
      y_lim = 320;
    end else if (scale_in == 2'b01) begin
      x_lim = 480;
      y_lim = 640;
    end else begin
      x_lim = 640;
      y_lim = 853;
    end 
    
    if (hcount_in < x_lim && vcount_in < y_lim) begin
      cam_out = frame_buff_in;
    end else begin
      cam_out = 16'h0000;
    end
  end
endmodule



`default_nettype wire
