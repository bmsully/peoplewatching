//now runs on 65 MHz:
module bw_converter (
  input wire clk_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire data_valid_in,
  input wire [15:0] pixel_in,
  output logic pixel_out,
  output logic [10:0] hcount_out,
  output logic [9:0] vcount_out,
  output logic data_valid_out
  );

  logic [4:0] r;
  logic [5:0] g;
  logic [4:0] b;

  assign r = pixel_in[15:11];
  assign g = pixel_in[10:5];
  assign b = pixel_in[4:0];

  always_ff @(posedge clk_in) begin
    // if gray, set pixel black
    if (r <= 10 && g <= 10 && b <= 10)begin
        pixel_out <= 1;
    // if dark colors, set pixel black
    end else if ((r <= 5 && g <= 10) || (g <= 10 && b <= 5) || (b <= 5 && r <= 5)) begin
        pixel_out <= 1;
    end else begin
        pixel_out <= 0;
    end

    data_valid_out <= data_valid_in;
    hcount_out <= hcount_in;
    vcount_out <= vcount_in;

  end
endmodule
