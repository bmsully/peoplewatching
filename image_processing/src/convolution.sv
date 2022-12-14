`timescale 1ns / 1ps
`default_nettype none

module convolution #(
    parameter K_SELECT=0)(
    input wire clk_in,
    input wire rst_in,
    input wire [2:0][15:0] data_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire data_valid_in,

    output logic data_valid_out,
    output logic [10:0] hcount_out,
    output logic [9:0] vcount_out,
    output logic [15:0] line_out
    );

    // columns, rows, pixels 
    logic [2:0][2:0][15:0] cache;
    logic signed [2:0][2:0][7:0] coeffs;
    logic signed [7:0] shift;

    logic signed [15:0] red;
    logic signed [15:0] green;
    logic signed [15:0] blue;
    logic signed [4:0] non_neg_red;
    logic signed [5:0] non_neg_green;
    logic signed [4:0] non_neg_blue;

    logic [10:0] hcount_pipe;
    logic [9:0] vcount_pipe;
    logic data_valid_pipe;


    always_ff @(posedge clk_in)begin
        
        if (rst_in) begin
            cache[0] <= {16'd0,16'd0,16'd0};
            cache[1] <= {16'd0,16'd0,16'd0};
            cache[2] <= {16'd0,16'd0,16'd0};
        end
        
        if (data_valid_in) begin //what about new line
            cache[0] <= cache[1];
            cache[1] <= cache[2];
            cache[2] <= data_in;
        end

        hcount_pipe <= hcount_in;
        vcount_pipe <= vcount_in;
        data_valid_pipe <= data_valid_in;

        hcount_out <= hcount_pipe;
        vcount_out <= vcount_pipe;
        data_valid_out <= data_valid_pipe;

    end

    always_ff @(posedge clk_in)begin
        
        red <= (($signed(coeffs[0][0]) * $signed({1'b0, cache[0][0][15:11]}))
            +($signed(coeffs[0][1]) * $signed({1'b0, cache[0][1][15:11]}))
            +($signed(coeffs[0][2]) * $signed({1'b0, cache[0][2][15:11]}))
            +($signed(coeffs[1][0]) * $signed({1'b0, cache[1][0][15:11]}))
            +($signed(coeffs[1][1]) * $signed({1'b0, cache[1][1][15:11]}))
            +($signed(coeffs[1][2]) * $signed({1'b0, cache[1][2][15:11]}))
            +($signed(coeffs[2][0]) * $signed({1'b0, cache[2][0][15:11]}))
            +($signed(coeffs[2][1]) * $signed({1'b0, cache[2][1][15:11]}))
            +($signed(coeffs[2][2]) * $signed({1'b0, cache[2][2][15:11]})))
             >>> shift;
        green <= (($signed(coeffs[0][0]) * $signed({1'b0, cache[0][0][10:5]}))
            +($signed(coeffs[0][1]) * $signed({1'b0, cache[0][1][10:5]}))
            +($signed(coeffs[0][2]) * $signed({1'b0, cache[0][2][10:5]}))
            +($signed(coeffs[1][0]) * $signed({1'b0, cache[1][0][10:5]}))
            +($signed(coeffs[1][1]) * $signed({1'b0, cache[1][1][10:5]}))
            +($signed(coeffs[1][2]) * $signed({1'b0, cache[1][2][10:5]}))
            +($signed(coeffs[2][0]) * $signed({1'b0, cache[2][0][10:5]}))
            +($signed(coeffs[2][1]) * $signed({1'b0, cache[2][1][10:5]}))
            +($signed(coeffs[2][2]) * $signed({1'b0, cache[2][2][10:5]})))
            >>> shift;
        blue <= (($signed(coeffs[0][0]) * $signed({1'b0, cache[0][0][4:0]}))
            +($signed(coeffs[0][1]) * $signed({1'b0, cache[0][1][4:0]}))
            +($signed(coeffs[0][2]) * $signed({1'b0, cache[0][2][4:0]}))
            +($signed(coeffs[1][0]) * $signed({1'b0, cache[1][0][4:0]}))
            +($signed(coeffs[1][1]) * $signed({1'b0, cache[1][1][4:0]}))
            +($signed(coeffs[1][2]) * $signed({1'b0, cache[1][2][4:0]}))
            +($signed(coeffs[2][0]) * $signed({1'b0, cache[2][0][4:0]}))
            +($signed(coeffs[2][1]) * $signed({1'b0, cache[2][1][4:0]}))
            +($signed(coeffs[2][2]) * $signed({1'b0, cache[2][2][4:0]})))
            >>> shift;
      
    end

    always_ff @(posedge clk_in)begin

        line_out <= {(red < 5'sb0)? 5'b0 : red[4:0], (green < 6'sb0)? 6'b0 : green[5:0], (blue < 5'sb0)? 5'b0 : blue[4:0]};
    end


    kernels #(.K_SELECT(K_SELECT)) kernel (.rst_in(rst_in), .coeffs(coeffs), .shift(shift));



    // Your code here!

    /* Note that the coeffs output of the kernels module
     * is packed in all dimensions, so coeffs should be 
     * defined as `logic signed [2:0][2:0][7:0] coeffs`
     *
     * This is because iVerilog seems to be weird about passing 
     * signals between modules that are unpacked in more
     * than one dimension - even though this is perfectly
     * fine Verilog.
     */
    

    // always_ff @(posedge clk_in) begin
    //   // Make sure to have your output be set with registered logic!
    //   // Otherwise you'll have timing violations.
    //   line_out <= {r, g, 1'b0, b};
    // end
endmodule

`default_nettype wire
