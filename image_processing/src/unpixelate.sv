module unpixelate (
  input wire clk_in,

  input wire data_valid_in,
  input wire [4:0] hcount_in,
  input wire [4:0] vcount_in,
  input logic [15:0] pixel_in

  output logic data_valid_out,
  output logic [9:0] hcount_out,
  output logic [10:0] vcount_out,
  output logic [15:0] pixel_out
  );


    always_ff @(posedge clk_in)begin

        if (data_valid_in == 1)begin
            hcount_out <= hcount_in * 10 - 5;
            vcount_out <= vcount_in * 10 -5;
        end

        pixel_out <= pixel_in;
        data_valid_out <= data_valid_in;

    end


endmodule