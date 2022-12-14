`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"


module get_conv9_weights (
    input wire clk_in, //system clock
    input wire rst_in,
    input logic data_valid_in,

    output logic signed [8:0][17:0] conv_9_weight_row,
    output logic data_valid_out, //valid data out signal
    output logic [3:0] row_num
  );

  logic [3:0] count;
  logic [161:0] weight_output;
  logic [1:0] data_valid_pipe;
  logic [1:0][3:0] row_num_pipe;

  always_ff @(posedge clk_in)begin

    if (rst_in == 1) begin
        count <= 0;
    end
    
    conv_9_weight_row[0] = $signed(weight_output[161:144]);
    conv_9_weight_row[1] = $signed(weight_output[143:126]);
    conv_9_weight_row[2] = $signed(weight_output[125:108]);
    conv_9_weight_row[3] = $signed(weight_output[107:90]);
    conv_9_weight_row[4] = $signed(weight_output[89:72]);
    conv_9_weight_row[5] = $signed(weight_output[71:54]);
    conv_9_weight_row[6] = $signed(weight_output[53:36]);
    conv_9_weight_row[7] = $signed(weight_output[35:18]);
    conv_9_weight_row[8] = $signed(weight_output[17:0]);

    data_valid_pipe[0] <= data_valid_in;
    data_valid_pipe[1] <= data_valid_pipe[0];
    data_valid_out <= data_valid_pipe[1];

    row_num_pipe[0] <= count;
    row_num_pipe[1] <= row_num_pipe[0];
    row_num <= row_num_pipe[1];

    if(data_valid_in == 1)begin
        if (count < 8) begin
            count <= count + 1;
        end else begin
            count <= 0;
        end
    end

  end


  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(162),                       // Specify RAM data width
    .RAM_DEPTH(9),                     // Specify RAM depth (number of entries)
    .ADDRA_DEPTH(4),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(conv9.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image_brom (
    .addra(count),     // Address bus, width determined from RAM_DEPTH
    .dina(),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(weight_output)      // RAM output data, width determined from RAM_WIDTH
  );



endmodule


`default_nettype wire
