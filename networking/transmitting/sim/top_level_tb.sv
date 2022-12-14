`default_nettype none
`timescale 1ns / 1ps

module top_level_tb();
    logic clk_in; // System clock
    logic rst_in; // System reset

    logic eth_refclk; // Ethernet clock
    logic eth_rstn; // Ethernet reset
    logic eth_txen; // Ethernet enable
    logic [1:0] eth_txd; // Ethernet data bus


    logic axiiv;
    logic [1:0] axiid;

    top_level uut (
        .clk(clk_in),
        .btnc(rst_in),
        .eth_refclk(eth_refclk), 
        .eth_rstn(eth_rstn),
        .eth_txen(eth_txen),
        .eth_txd(eth_txd)
        );

    always begin
        #10;
        clk_in = !clk_in;
    end

    // TODO Change to a transmitting testbench
    // logic [31:0] checksum = 32'h6e24_48c0;

    initial begin
        $dumpfile("t_top_level.vcd");
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
        // 32'hFEED_BEEF;
        for (int i = 0; i < 300; i = i + 1)begin
            $display("%2b", eth_txd);
            #20;
        end
        rst_in = 1;
        #20;
        rst_in = 0;
        #20;
        for (int i = 0; i < 300; i = i + 1)begin
            $display("%2b", eth_txd);
            #20;
        end
        // axiiv = 1'b1;
        // axiid = 2'b11; // F
        // #20;
        // axiid = 2'b11;
        // #20;
        // axiid = 2'b11; // E
        // #20;
        // axiid = 2'b10;
        // #20;
        // axiid = 2'b11; // E
        // #20;
        // axiid = 2'b10;
        // #20;
        // axiid = 2'b11; // D
        // #20;
        // axiid = 2'b01;
        // #20;
        // axiid = 2'b10; // B
        // #20;
        // axiid = 2'b11;
        // #20;
        // axiid = 2'b11; // E
        // #20;
        // axiid = 2'b10;
        // #20;
        // axiid = 2'b11; // E
        // #20;
        // axiid = 2'b10;
        // #20;
        // axiid = 2'b11; // F
        // #20;
        // axiid = 2'b11;
        // #20;
        // axiiv = 1'b0;
        // axiid = 2'b0;
        // #20;
        #100;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule // top_level_tb

`default_nettype wire
