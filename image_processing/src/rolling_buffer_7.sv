`timescale 1ns / 1ps
`default_nettype none


module rolling_buffer_7 (
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire [4:0] hcount_in, //current hcount being read
    input wire [4:0] vcount_in, //current vcount being read
    input wire signed [20:0] pixel_data_in, //incoming pixel
    input wire data_valid_in, //incoming  valid data signal

    output logic signed [8:0][20:0] line_buffer_out, //output pixels of data (blah make this packed)
    output logic [4:0] hcount_out, //current hcount being read
    output logic [4:0] vcount_out, //current vcount being read
    output logic data_valid_out //valid data out signal
  );

  logic [4:0] hcount_pipe;
  logic [4:0] vcount_pipe;
  logic data_valid_pipe;

  
  
  logic [20:0] pixel_in;
  logic [5:0] hcount_old;
  logic [3:0] bram_count;
  logic signed [20:0] douts[9:0];

    always_comb begin
            case(bram_count)
                0: line_buffer_out = {douts[1],douts[2],douts[3],douts[4],douts[5],douts[6],douts[7],douts[8],douts[9]};
                1: line_buffer_out = {douts[2],douts[3],douts[4],douts[5],douts[6],douts[7],douts[8],douts[9],douts[0]};
                2: line_buffer_out = {douts[3],douts[4],douts[5],douts[6],douts[7],douts[8],douts[9],douts[0],douts[1]};
                3: line_buffer_out = {douts[4],douts[5],douts[6],douts[7],douts[8],douts[9],douts[0],douts[1],douts[2]};
                4: line_buffer_out = {douts[5],douts[6],douts[7],douts[8],douts[9],douts[0],douts[1],douts[2],douts[3]};
                5: line_buffer_out = {douts[6],douts[7],douts[8],douts[9],douts[0],douts[1],douts[2],douts[3],douts[4]};
                6: line_buffer_out = {douts[7],douts[8],douts[9],douts[0],douts[1],douts[2],douts[3],douts[4],douts[5]};
                7: line_buffer_out = {douts[8],douts[9],douts[0],douts[1],douts[2],douts[3],douts[4],douts[5],douts[6]};
              endcase
        end

  always_ff @(posedge clk_in)begin

    if(rst_in) begin
      bram_count <= 0;
    end

    if (!(hcount_old == 0) && hcount_in == 0 && data_valid_in) begin
      if (bram_count == 9) begin
        bram_count <= 0;
      end else begin
        bram_count <= bram_count + 1;
      end
    end
    hcount_old <= hcount_in;

    //pipelining hcount and vcount
    hcount_pipe <= hcount_in;
    vcount_pipe <= vcount_in;
    data_valid_pipe <= data_valid_in;

    hcount_out <= hcount_pipe;

    if (vcount_pipe == 0) begin
      vcount_out <= 27;
    end else if (vcount_pipe == 1) begin
      vcount_out <= 28;
    end else if (vcount_pipe == 2) begin
      vcount_out <= 29;
    end else if (vcount_pipe == 3) begin
      vcount_out <= 30;
    end else if (vcount_pipe == 4) begin
      vcount_out <= 31;
    end else begin
      vcount_out <= vcount_pipe - 5;
    end

    data_valid_out <= data_valid_pipe;
    
  end

  xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_DEPTH(24), .RAM_WIDTH(21)) bram_0 (
    .addra(hcount_in), .addrb(hcount_in),
    .dina(), .dinb(pixel_data_in),
    .clka(clk_in),
    .wea(1'b0), .web((bram_count == 0) && data_valid_in),
    .ena(1'b1), .enb(1'b1),
    .rsta(rst_in), .rstb(),
    .regcea(1'b1), .regceb(1'b0),
    .douta(douts[0]), .doutb()
  );
  xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_DEPTH(24), .RAM_WIDTH(21)) bram_1 (
    .addra(hcount_in), .addrb(hcount_in),
    .dina(), .dinb(pixel_data_in),
    .clka(clk_in),
    .wea(1'b0), .web((bram_count == 1) && data_valid_in),
    .ena(1'b1), .enb(1'b1),
    .rsta(rst_in), .rstb(),
    .regcea(1'b1), .regceb(1'b0),
    .douta(douts[1]), .doutb()
  );
  xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_DEPTH(24), .RAM_WIDTH(21)) bram_2 (
    .addra(hcount_in), .addrb(hcount_in),
    .dina(), .dinb(pixel_data_in),
    .clka(clk_in),
    .wea(1'b0), .web((bram_count == 2) && data_valid_in),
    .ena(1'b1), .enb(1'b1),
    .rsta(rst_in), .rstb(),
    .regcea(1'b1), .regceb(1'b0),
    .douta(douts[2]), .doutb()
  );
  xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_DEPTH(24), .RAM_WIDTH(21)) bram_3 (
    .addra(hcount_in), .addrb(hcount_in),
    .dina(), .dinb(pixel_data_in),
    .clka(clk_in),
    .wea(1'b0), .web((bram_count == 3) && data_valid_in),
    .ena(1'b1), .enb(1'b1),
    .rsta(rst_in), .rstb(),
    .regcea(1'b1), .regceb(1'b0),
    .douta(douts[3]), .doutb()
  );
  xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_DEPTH(24), .RAM_WIDTH(21)) bram_4 (
    .addra(hcount_in), .addrb(hcount_in),
    .dina(), .dinb(pixel_data_in),
    .clka(clk_in),
    .wea(1'b0), .web((bram_count == 4) && data_valid_in),
    .ena(1'b1), .enb(1'b1),
    .rsta(rst_in), .rstb(),
    .regcea(1'b1), .regceb(1'b0),
    .douta(douts[4]), .doutb()
  );
  xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_DEPTH(24), .RAM_WIDTH(21)) bram_5 (
    .addra(hcount_in), .addrb(hcount_in),
    .dina(), .dinb(pixel_data_in),
    .clka(clk_in),
    .wea(1'b0), .web((bram_count == 5) && data_valid_in),
    .ena(1'b1), .enb(1'b1),
    .rsta(rst_in), .rstb(),
    .regcea(1'b1), .regceb(1'b0),
    .douta(douts[5]), .doutb()
  );
  xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_DEPTH(24), .RAM_WIDTH(21)) bram_6 (
    .addra(hcount_in), .addrb(hcount_in),
    .dina(), .dinb(pixel_data_in),
    .clka(clk_in),
    .wea(1'b0), .web((bram_count == 6) && data_valid_in),
    .ena(1'b1), .enb(1'b1),
    .rsta(rst_in), .rstb(),
    .regcea(1'b1), .regceb(1'b0),
    .douta(douts[6]), .doutb()
  );
  xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_DEPTH(24), .RAM_WIDTH(21)) bram_7 (
    .addra(hcount_in), .addrb(hcount_in),
    .dina(), .dinb(pixel_data_in),
    .clka(clk_in),
    .wea(1'b0), .web((bram_count == 7) && data_valid_in),
    .ena(1'b1), .enb(1'b1),
    .rsta(rst_in), .rstb(),
    .regcea(1'b1), .regceb(1'b0),
    .douta(douts[7]), .doutb()
  );
  xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_DEPTH(24), .RAM_WIDTH(21)) bram_8 (
    .addra(hcount_in), .addrb(hcount_in),
    .dina(), .dinb(pixel_data_in),
    .clka(clk_in),
    .wea(1'b0), .web((bram_count == 8) && data_valid_in),
    .ena(1'b1), .enb(1'b1),
    .rsta(rst_in), .rstb(),
    .regcea(1'b1), .regceb(1'b0),
    .douta(douts[8]), .doutb()
  );
  xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_DEPTH(24), .RAM_WIDTH(21)) bram_9 (
    .addra(hcount_in), .addrb(hcount_in),
    .dina(), .dinb(pixel_data_in),
    .clka(clk_in),
    .wea(1'b0), .web((bram_count == 9) && data_valid_in),
    .ena(1'b1), .enb(1'b1),
    .rsta(rst_in), .rstb(),
    .regcea(1'b1), .regceb(1'b0),
    .douta(douts[9]), .doutb()
  );


endmodule


`default_nettype wire
