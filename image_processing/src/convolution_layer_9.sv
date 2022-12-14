
module convolution_layer_9 (
  input wire clk_in,
  input wire rst_in,

  input wire data_valid_in,
  input wire signed [20:0] pixel_data_in,
  input wire [4:0] hcount_in,
  input wire [4:0] vcount_in,

  output logic data_valid_out,
  output logic signed [20:0] pixel_data_out,
  output logic [4:0] hcount_out,
  output logic [4:0] vcount_out
  );

  logic signed [8:0][20:0] buffs; //make this packed in two dimensions for iVerilog
  logic b_to_c_valid, c_valid;
  logic [4:0] hcount_buff;
  logic [4:0] vcount_buff;
  logic signed [8:0][17:0] conv_9_weight_row;
  logic [3:0] row_num;

  rolling_buffer_9 mbuff (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .data_valid_in(data_valid_in),
    .pixel_data_in(pixel_data_in),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .data_valid_out(b_to_c_valid),
    .line_buffer_out(buffs),
    .hcount_out(hcount_buff),
    .vcount_out(vcount_buff)
    );

// weights are multiplied by 2**17
    get_conv9_weights get_conv9_weights_m (
    .clk_in(clk_in), //system clock
    .rst_in(rst_in),
    .data_valid_in(b_to_c_valid),

    .conv_9_weight_row(conv_9_weight_row),
    .data_valid_out(data_valid_get_conv9_weights), //valid data out signal
    .row_num(row_num)
  );

  convolution_9
    mconv (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .data_in(buffs),
    .weights_in(conv_9_weight_row),
    .row_num(row_num),
    .data_valid_in(data_valid_get_conv9_weights),
    .hcount_in(hcount_buff),
    .vcount_in(vcount_buff),
    .line_out(pixel_data_out),
    .data_valid_out(data_valid_out),
    .hcount_out(hcount_out),
    .vcount_out(vcount_out)
  );

endmodule
