`timescale 1ns / 1ps
`default_nettype none


module buffer (
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire [10:0] hcount_in, //current hcount being read
    input wire [9:0] vcount_in, //current vcount being read
    input wire [15:0] pixel_data_in, //incoming pixel
    input wire data_valid_in, //incoming  valid data signal

    output logic [2:0][15:0] line_buffer_out, //output pixels of data (blah make this packed)
    output logic [10:0] hcount_out, //current hcount being read
    output logic [9:0] vcount_out, //current vcount being read
    output logic data_valid_out //valid data out signal
  );

  logic [10:0] hcount_pipe;
  logic [9:0] vcount_pipe;
  logic data_valid_pipe;
  logic [15:0] pixel_in;
  logic [9:0] hcount_old;
  logic [2:0] bram_count;

  logic [15:0] dina_0;
  logic wea_0;
  logic regcea_0;
  logic [15:0] douta_0;

  logic [15:0] dina_1;
  logic wea_1;
  logic regcea_1;
  logic [15:0] douta_1;

  logic [15:0] dina_2;
  logic wea_2;
  logic regcea_2;
  logic [15:0] douta_2;

  logic [15:0] dina_3;
  logic wea_3;
  logic regcea_3;
  logic [15:0] douta_3;


  always_ff @(posedge clk_in)begin

    if(rst_in) begin
      bram_count <= 0;
    end

    if (!(hcount_old == 0) && hcount_in == 0 && data_valid_in) begin
      if (bram_count == 0) begin
        bram_count <= 3;
      end else begin
        bram_count <= bram_count - 1;
      end
    end
    hcount_old <= hcount_in;

    //pipelining hcount and vcountvv
    hcount_pipe <= hcount_in;
    vcount_pipe <= vcount_in;
    data_valid_pipe <= data_valid_in;

    hcount_out <= hcount_pipe;
    if (vcount_pipe == 1) begin
      vcount_out <= 239;
    end else if (vcount_pipe == 0) begin
      vcount_out <= 238;
    end else begin
      vcount_out <= vcount_pipe - 2;
    end
    data_valid_out <= data_valid_pipe;

  end

  always_ff @(posedge clk_in)begin
    if (data_valid_in) begin
      if (bram_count == 0) begin
        dina_0 <= pixel_data_in;
        wea_0 <= 1'b1;
        regcea_0 <= 1'b0;

        wea_1 <= 1'b0;
        regcea_1 <= 1'b1;
        line_buffer_out[0] <= douta_1;

        wea_2 <= 1'b0;
        regcea_2 <= 1'b1;
        line_buffer_out[1] <= douta_2;

        wea_3 <= 1'b0;
        regcea_3 <= 1'b1;
        line_buffer_out[2] <= douta_3;
      end
      else if (bram_count == 1) begin
        dina_1 <= pixel_data_in;
        wea_1 <= 1'b1;
        regcea_1 <= 1'b0;

        wea_2 <= 1'b0;
        regcea_2 <= 1'b1;
        line_buffer_out[0] <= douta_2;

        wea_3 <= 1'b0;
        regcea_3 <= 1'b1;
        line_buffer_out[1] <= douta_3;
        
        wea_0 <= 1'b0;
        regcea_0 <= 1'b1;
        line_buffer_out[2] <= douta_0;
      end
      else if (bram_count == 2) begin
        dina_2 <= pixel_data_in;
        wea_2 <= 1'b1;
        regcea_2 <= 1'b0;

        wea_3 <= 1'b0;
        regcea_3 <= 1'b1;
        line_buffer_out[0] <= douta_3;

        wea_0 <= 1'b0;
        regcea_0 <= 1'b1;
        line_buffer_out[1] <= douta_0;
        
        wea_1 <= 1'b0;
        regcea_1 <= 1'b1;
        line_buffer_out[2] <= douta_1;
      end
      else if (bram_count == 3) begin
        dina_3 <= pixel_data_in;
        wea_3 <= 1'b1;
        regcea_3 <= 1'b0;

        wea_0 <= 1'b0;
        regcea_0 <= 1'b1;
        line_buffer_out[0] <= douta_0;

        wea_1 <= 1'b0;
        regcea_1 <= 1'b1;
        line_buffer_out[1] <= douta_1;
        
        wea_2 <= 1'b0;
        regcea_2 <= 1'b1;
        line_buffer_out[2] <= douta_2;
      end
    end
  end

  xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_DEPTH(320), .RAM_WIDTH(16)) bram_0 (
    .addra(hcount_in[8:0]), .addrb(),
    .dina(dina_0), .dinb(),
    .clka(clk_in),
    .wea(wea_0), .web(),
    .ena(1'b1), .enb(1'b0),
    .rsta(rst_in), .rstb(),
    .regcea(regcea_0), .regceb(),
    .douta(douta_0), .doutb()
  );
  xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_DEPTH(320), .RAM_WIDTH(16)) bram_1 (
    .addra(hcount_in[8:0]), .addrb(),
    .dina(dina_1), .dinb(),
    .clka(clk_in),
    .wea(wea_1), .web(),
    .ena(1'b1), .enb(1'b0),
    .rsta(rst_in), .rstb(),
    .regcea(regcea_1), .regceb(),
    .douta(douta_1), .doutb()
  );
  xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_DEPTH(320), .RAM_WIDTH(16)) bram_2 (
    .addra(hcount_in[8:0]), .addrb(),
    .dina(dina_2), .dinb(),
    .clka(clk_in),
    .wea(wea_2), .web(),
    .ena(1'b1), .enb(1'b0),
    .rsta(rst_in), .rstb(),
    .regcea(regcea_2), .regceb(),
    .douta(douta_2), .doutb()
  );
  xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_DEPTH(320), .RAM_WIDTH(16)) bram_3 (
    .addra(hcount_in[8:0]), .addrb(),
    .dina(dina_3), .dinb(),
    .clka(clk_in),
    .wea(wea_3), .web(),
    .ena(1'b1), .enb(1'b0),
    .rsta(rst_in), .rstb(),
    .regcea(regcea_3), .regceb(),
    .douta(douta_3), .doutb()
  );


endmodule


`default_nettype wire
