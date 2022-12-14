//now runs on 65 MHz:
module normalize (
  input wire clk_in,
  input wire [4:0] hcount_in,
  input wire [4:0] vcount_in,
  input wire data_valid_in,
  input wire pixel_in,
  output logic signed [20:0] pixel_out,
  output logic [4:0] hcount_out,
  output logic [4:0] vcount_out,
  output logic data_valid_out
  );

  always_ff @(posedge clk_in) begin

    // shifted by 17 bits
    if (pixel_in == 1)begin
        pixel_out <= 644_573;
    end else if (pixel_in == 0)begin
        pixel_out <= -26_653;
    end
    
    data_valid_out <= ~data_valid_in;
    hcount_out <= hcount_in;
    vcount_out <= vcount_in;


  end
endmodule
