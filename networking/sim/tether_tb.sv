`default_nettype none
`timescale 1ns / 1ps

module tether_tb();
    logic clk_in; // System clock
    logic rst_in; // System reset
    logic axiiv; // Data valid input
    logic [1:0] axiid; // Data input bus

    logic eth_txen; // Output valid
    logic [1:0] eth_txd; // Output data bus

    tether uut (
        .clk(clk_in),
        .rst(rst_in),
        .axiiv(axiiv), 
        .axiid(axiid),
        .axiov(eth_txen),
        .axiod(eth_txd)
        );

    always begin
        #10;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("tether.vcd");
        $dumpvars(0, tether_tb);
        $display("Starting Sim");
        clk_in = 0;
        #10;
        rst_in = 0; 
        // use #20 for clock cycle 
        #20;
        rst_in = 1;
        #20; 
        rst_in = 0;
        $display("1: Half a byte of data");
        #100;
        axiiv = 1'b1;
        axiid = 2'b10;
        #20;
        axiid = 2'b01;
        #20;
        axiiv = 1'b0;
        axiid = 2'b0;
        #20;
        #2000;
        $display("2: One byte of data");
        #100; 
        axiiv = 1'b1;
        axiid = 2'b01;
        #20
        axiid = 2'b10;
        #20;
        axiid = 2'b10;
        #20;
        axiid = 2'b01;
        #20;
        axiiv = 1'b0;
        axiid = 2'b0;
        #20;
        #2000;
        $display("3: 2 bytes of data");
        #100;
        axiiv = 1'b1;
        for (int i = 0; i<8; i = i + 1) begin 
            axiid = 2'b01;
            #20;
        end
        axiiv = 1'b0;
        axiid = 2'b0;
        #20;
        #2000;
        $display("4: 22 bytes of data");
        #100;
        axiiv = 1'b1;
        for (int i = 0; i<88; i = i + 1) begin 
            axiid = 2'b01;
            #20;
        end
        axiiv = 1'b0;
        axiid = 2'b00;
        #20;
        #2000;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule // tether_tb

`default_nettype wire
