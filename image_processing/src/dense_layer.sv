
module dense_layer #(parameter K_SELECT=0)(
  input wire clk_in,
  input wire rst_in,

  input wire data_valid_in,
  input wire [20:0] pixel_data_in,
  input wire [4:0] hcount_in,
  input wire [4:0] vcount_in,

  output logic data_valid_out,
  output logic [20:0] hcount_pred,
  output logic [20:0] vcount_pred,
  output logic [4:0] vcount_out
  );

    // columns, rows, pixels 
    logic signed [23:0][20:0] weights_out;

    logic [5:0] line_count;
    logic [5:0] element_count;


    logic [7:0][10:0] hcount_pipe;
    logic [7:0][9:0] vcount_pipe;
    logic data_valid_pipe; 


  always_ff @(posedge clk_in)begin
        
        if (data_valid_in) begin //what about new line
            line_count <= line_count + 1;
            element_count <= 0;
        end
        if(vcount_in <= 0 && hcount_in <= 0) begin
          pixel_data_out <= 0;
        end

        hcount_pipe[0] <= hcount_in;
        hcount_pipe[1] <= hcount_pipe[0];
        hcount_pipe[2] <= hcount_pipe[1];
        hcount_pipe[3] <= hcount_pipe[2];
        hcount_pipe[4] <= hcount_pipe[3];
        hcount_pipe[5] <= hcount_pipe[4];
        hcount_pipe[6] <= hcount_pipe[5];
        hcount_pipe[7] <= hcount_pipe[6];
        hcount_out <= hcount_pipe[7];

        vcount_pipe[0] <= vcount_in;
        vcount_pipe[1] <= vcount_pipe[0];
        vcount_pipe[2] <= vcount_pipe[1];
        vcount_pipe[3] <= vcount_pipe[2];
        vcount_pipe[4] <= vcount_pipe[3];
        vcount_pipe[5] <= vcount_pipe[4];
        vcount_pipe[6] <= vcount_pipe[5];
        vcount_pipe[7] <= vcount_pipe[6];
        vcount_out <= vcount_pipe[7];

        // data_valid_pipe <= data_valid_in;
        // data_valid_out <= data_valid_pipe;
  end

  always_ff @(posedge clk_in)begin
    for(int i = 0; i< 48; i+2)begin
      if(element_count == i)begin
        hcount_pred <= $signed(hcount_pred) + $signed(weights_out[i]) * $signed(pixel_data_in[0]);
        vcount_pred <= $signed(vcount_pred) + $signed(weights_out[i + 1]) * $signed(pixel_data_in[0]);
      end
    end

    if(row_num == 23) begin
      data_valid_out <= 1;
    end else begin
      data_valid_out <= 0;
    end
  end

    
      xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(20*24*2),                       // Specify RAM data width
    .RAM_DEPTH(64),                     // Specify RAM depth (number of entries)
    .ADDRA_DEPTH(4),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(dense.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image_brom (
    .addra(line_count),     // Address bus, width determined from RAM_DEPTH
    .dina(),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(weight_output)      // RAM output data, width determined from RAM_WIDTH
  );


endmodule
