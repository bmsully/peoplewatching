`default_nettype none
`timescale 1ns / 1ps

module top_level_tb();
    logic clk_in; // System clock
    logic rst_in; // System reset
    logic crsdv_in; // Data valid input
    logic [1:0] rxd_in; // Data input bus

    logic refclk_out; // Ethernet clock at 50 mhz
    logic rstn_out; // Ethernet reset (negated)
    logic [15:0] led_out; // output leds

    top_level uut (
        .clk(clk_in),
        .btnc(rst_in),
        .eth_crsdv(crsdv_in), 
        .eth_rxd(rxd_in),
        .eth_refclk(refclk_out),
        .eth_rstn(rstn_out),
        .led(led_out)
        );

    always begin
        #10;
        clk_in = !clk_in;
    end

    // Bitstream off the wire e.g. preamble[1:0] is the first dibit corresponding to rxd[1:0]
    logic [55:0] preamble = 56'b01010101_01010101_01010101_01010101_01010101_01010101_01010101;
    logic [7:0] sfd = 8'b11101010;
    logic [47:0] destination = 48'b11111111_11111111_11111111_11111111_11111111_11111111; // broadcast destination
    logic [47:0] source = 48'b11111101_01110101_00110000_00001000_11000010_10010110; // random source
    logic [15:0] length = 16'b00010101_00000000; // 21 bytes -> LSB, MSb 
    logic [167:0] message = 168'h4261_7272_7921_2042_7265_616b_6661_7374_2074_696d65;
    logic [31:0] checksum = 32'hb57c_0a54;
    // logic [31:0] checksum = 32'h6e24_48c0;
    // logic [31:0] checksum = 32'h00000000;

    // logic [31:0] checksum = 32'h0000_0000;

    initial begin
        $dumpfile("top_level.vcd");
        $dumpvars(0, top_level_tb);
        $display("Starting Sim");
        clk_in = 0;
        #10;
        rst_in = 0; 
        // use #20 for clock cycle 
        #20;
        rst_in = 1;
        #20; 
        rst_in = 0;
        $display("1: Full message");
        crsdv_in = 1'b1;
        #20;
        // Preamble
        for (int i = 0; i < 28; i = i + 1) begin
            rxd_in = 2'b01;
            #20;
        end
        // Sfd
        for (int i = 0; i < 4; i = i + 1) begin
            case (i)
                3: rxd_in = 2'b11;
                default: rxd_in = 2'b01;
            endcase
            #20;
        end
        // Destination
        for (int i = 0; i < 24; i = i + 1) begin
            rxd_in = 2'b11;
            #20;
        end
        // rxd_in = 2'b00;
        // #20;
        // for (int i = 0; i < 24; i = i + 1) begin
        //     rxd_in = 2'b; // insert device address
        //     #20;
        // end
        // Source
        for (int i = 0; i < 24; i = i + 1) begin
            rxd_in = source[1:0]; 
            source = {source[1:0], source[47:2]};
            #20;
        end
        // Length
        for (int i = 0; i < 8; i = i + 1) begin
            case (i)
                5: rxd_in = 2'b01;
                6: rxd_in = 2'b01;
                7: rxd_in = 2'b01;
                default: rxd_in = 2'b00;
            endcase
            #20;
        end
        // Data - for loop from cksum_tb
        // axiod at this point should be the checksum
        for (int i = 168; i>0; i = i - 2) begin 
            rxd_in = {message[i-2], message[i-1]}; 
            #20;
        end
        // "xor" the value with itself to get the constant
        for (int i = 32; i>0; i = i - 2) begin
            rxd_in = {checksum[i-2], checksum[i-1]}; //
            #20;
        end
        crsdv_in = 1'b0;
        rxd_in = 2'b0;
        #20;
        #100;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule // top_level_tb

`default_nettype wire
