module draw_box (
  input wire clk_in,

  input wire data_valid_in,
  input wire [4:0] hcount_pred,
  input wire [4:0] vcount_pred,

  output logic data_valid_out,
  output logic [4:0] hcount_out,
  output logic [4:0] vcount_out,
  output logic [15:0] pixel_out
  );

  logic [5:0] count;
  logic [3:0] add_h;
  logic [3:0] add_v;

   always_ff @(posedge clk_in)begin
    if (data_valid_in == 1)begin
        count <= 0;
        hcount_out<= h

    end else begin
        count <= count + 1;
    end

    if (count -)

    pixel_out <= 11111_000000_00000;

    

   end

endmodule