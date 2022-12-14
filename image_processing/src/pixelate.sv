//now runs on 65 MHz:
module pixelate (
  input wire clk_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire data_valid_in,
  input wire pixel_in,
  output logic pixel_out,
  output logic [4:0] hcount_out,
  output logic [4:0] vcount_out,
  output logic data_valid_out
  );


  always_ff @(posedge clk_in) begin

    if (data_valid_out <= 1) begin
        data_valid_out <= 0;
    end

    if (data_valid_in == 1)begin
        for (int v = 0; v < 24; v = v + 1)begin
            for (int h = 0; h < 32; h = h + 1)begin
                if (v*10 + 5 == vcount_in && h*10 + 5 == hcount_in)begin
                    hcount_out <= h;
                    vcount_out <= v;
                    pixel_out <= pixel_in;
                    data_valid_out <= 1;
                end
            end
        end

    end


  end
endmodule
