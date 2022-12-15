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
        hcount_out <= hcount_pred - 3;
        vcount_out <= vcount_pred - 3;
        add_h <= 0;
        add_v <= 0;

    end else begin
        count <= count + 1;
    end

    if (count <= 5 && count >= 0)begin
        add_h <= 1;
        add_v <= 0;
    end else if (count <= 11 && count >= 6)begin
        add_h <= 0;
        add_v <= 1;
    end else if (count <= 12 && count >= 17)begin
        add_h <= -1;
        add_v <= 0;
    end else if (count <= 18 && count >= 23)begin
        add_h <= 0;
        add_v <= -1;
    end

    hcount_out <= hcount_out + add_h;
    vcount_out <= vcount_out + add_v;

    data_valid_out <= ~data_valid_in;

    pixel_out <= 11111_000000_00000;

    

   end

endmodule