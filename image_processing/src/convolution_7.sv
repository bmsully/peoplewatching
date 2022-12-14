`timescale 1ns / 1ps
`default_nettype none

module convolution_7 (
    input wire clk_in,
    input wire rst_in,
    input wire signed [6:0][20:0] data_in,
    input wire signed [6:0][17:0] weights_in,
    input wire [3:0] row_num,
    input wire [4:0] hcount_in,
    input wire [4:0] vcount_in,
    input wire data_valid_in,

    output logic data_valid_out,
    output logic [4:0] hcount_out,
    output logic [4:0] vcount_out,
    output logic signed [20:0] line_out
    );

    // columns, rows, pixels 
    logic signed [6:0][6:0][20:0] cache;
    logic signed [6:0][20:0] curr_data;


    logic [7:0][10:0] hcount_pipe;
    logic [7:0][9:0] vcount_pipe;
    logic data_valid_pipe; 


  always_ff @(posedge clk_in)begin
        
        if (rst_in) begin
            cache[0] <= {21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0};
            cache[1] <= {21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0};
            cache[2] <= {21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0};
            cache[3] <= {21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0};
            cache[4] <= {21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0};
            cache[5] <= {21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0};
            cache[6] <= {21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0};
            cache[7] <= {21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0};
            cache[8] <= {21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0,21'd0};
        end
        
        if (data_valid_in) begin //what about new line
            cache[0] <= cache[1];
            cache[1] <= cache[2];
            cache[2] <= cache[3];
            cache[3] <= cache[4];
            cache[4] <= cache[5];
            cache[5] <= cache[6];
            cache[6] <= cache[7];
            cache[7] <= cache[8];
            cache[8] <= data_in;

            line_out <= 0;
        end

        case(row_num)
            0: curr_data = cache[0];
            1: curr_data = cache[1];
            2: curr_data = cache[2];
            3: curr_data = cache[3];
            4: curr_data = cache[4];
            5: curr_data = cache[5];
            6: curr_data = cache[6];
            7: curr_data = cache[7];
            8: curr_data = cache[8];
        endcase

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


        //multiplying
        if (row_num == 6) begin
            line_out <= $signed(line_out) + $signed(weights_in[0]) * $signed(curr_data[0])
                + $signed(weights_in[1]) * $signed(curr_data[1]) 
                + $signed(weights_in[2]) * $signed(curr_data[2]) 
                + $signed(weights_in[3]) * $signed(curr_data[3]) 
                + $signed(weights_in[4]) * $signed(curr_data[4]);
            // line_out <= 8;
            data_valid_out <= 1;
        end else begin
            line_out <= $signed(line_out) + $signed(weights_in[0]) * $signed(curr_data[0])
                + $signed(weights_in[1]) * $signed(curr_data[1]) 
                + $signed(weights_in[2]) * $signed(curr_data[2]) 
                + $signed(weights_in[3]) * $signed(curr_data[3]) 
                + $signed(weights_in[4]) * $signed(curr_data[4]) ;
            line_out <= 1;
            data_valid_out <= 0;
        end
        //if row_num is 9, add bias and say it's valid out
    end

    always_ff @(posedge clk_in)begin


        //multiplying
        if (row_num == 6) begin
            line_out <= ($signed(line_out) 
                + $signed(weights_in[5]) * $signed(curr_data[5]) 
                + $signed(weights_in[6]) * $signed(curr_data[6]) 
                + $signed(weights_in[7]) * $signed(curr_data[7]) 
                + $signed(weights_in[8]) * $signed(curr_data[8])
                + $signed(13'b1100110010010)) >>> 17; //bias 
            // line_out <= 8;
            data_valid_out <= 1;
        end else begin
            line_out <= ($signed(line_out)
                + $signed(weights_in[5]) * $signed(curr_data[5]) 
                + $signed(weights_in[6]) * $signed(curr_data[6]) 
                + $signed(weights_in[7]) * $signed(curr_data[7]) 
                + $signed(weights_in[8]) * $signed(curr_data[8])) >>> 17;
            // line_out <= 1;
            data_valid_out <= 0;
        end
        //if row_num is 9, add bias and say it's valid out
    end


endmodule

`default_nettype wire
