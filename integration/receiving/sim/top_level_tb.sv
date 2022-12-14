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
    logic [47:0] destination = 48'b01101001_01101001_10100101_10010000_00010101_01000110; // destination in MSB, LSb order
    logic [47:0] source = 48'b01101001_01101001_10100101_10010000_00010101_00000110; // source in MSB, LSb order
    logic [15:0] ethertype = 16'b00000001_00000001; // experimental ethertype, MSB, MSb order i.e. h0101
    // logic [167:0] message = 168'h4261_7272_7921_2042_7265_616b_6661_7374_2074_696d65;
    logic [31:0] data = 32'hBF7B_BEFB; // MSB, LSb
    // logic [31:0] checksum = 32'b01101011_01010011_01010110_10100001; // MSB, MSb,LSdb
    logic [31:0] checksum = 32'b01010111_10100011_10101001_01010010; // MSB, MSb
    // logic [31:0] checksum = 32'hb57c_0a54;
    // logic [31:0] checksum = 32'h6e24_48c0;
    // logic [31:0] checksum = 32'h00000000;

    logic [1199:0] whole_damn_thing = 1200'b000000000000000001010101010101010101010101010101010101010101010101010101010101110110100101101001101001011001000000010101010001100110100101101001101001011001000000010101000001100100000001000000101111110111101110111110111110110101011110100011101010010101001010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000101010101010101010101010101010101010101010101010101010101010111011010010110100110100101100100000001010101000110011010010110100110100101100100000001010100000110010000000100000010111111011110111011111011111011010101111010001110101001010100101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010;

    // logic [31:0] checksum = 32'h0000_0000;

    initial begin
        $dumpfile("r_top_level.vcd");
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
        // for (int i = 0; i < 24; i = i + 1) begin
        //     rxd_in = 2'b11;
        //     #20;
        // end
        // rxd_in = 2'b00;
        // #20;
        for (int i = 0; i < 24; i = i + 1) begin
            rxd_in = destination[47:46]; 
            destination = {destination[45:0], destination[47:46]};
            #20;
        end
        // Source
        for (int i = 0; i < 24; i = i + 1) begin
            rxd_in = source[47:46]; 
            source = {source[45:0], source[47:46]};
            #20;
        end
        // Ethertype
        for (int i = 0; i < 8; i = i + 1) begin
            case (i)
                0: rxd_in = 2'b01;
                4: rxd_in = 2'b01;
                default: rxd_in = 2'b00;
            endcase
            #20;
        end
        // Data - for loop from cksum_tb
        // axiod at this point should be the checksum
        // for (int i = 168; i>0; i = i - 2) begin 
        //     rxd_in = {message[i-2], message[i-1]}; 
        //     #20;
        // end
        for (int i = 32; i>0; i = i - 2) begin
            rxd_in = {data[i-1], data[i-2]};
            #20;
        end
        // "xor" the value with itself to get the constant
        for (int i = 32; i>0; i = i - 2) begin
            rxd_in = {checksum[i-1], checksum[i-2]}; //potentially reverse these
            #20;
        end
        crsdv_in = 1'b0;
        rxd_in = 2'b0;
        #20;
        #200;
        $display("2: Full output from transmitting but twice in a row");
        #1000;
        crsdv_in = 1'b0;
        rxd_in = 2'b0;
        #20;
        for (int i = 1200; i>0; i = i - 2) begin
            if (i == 1184) begin
                crsdv_in = 1'b1;
            end
            if (i == 944) begin
                crsdv_in = 1'b0;
            end
            if (i == 586) begin
                crsdv_in = 1'b1;
            end
            if (i == 346) begin
                crsdv_in = 1'b0;
            end
            rxd_in = {whole_damn_thing[i-1], whole_damn_thing[i-2]};
            $display("%1b - %2b", crsdv_in, rxd_in);
            #20;
        end
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule // top_level_tb

`default_nettype wire