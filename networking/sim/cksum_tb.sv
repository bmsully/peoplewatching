`default_nettype none
`timescale 1ns / 1ps

module cksum_tb();
    logic clk_in; // System clock
    logic rst_in; // System reset
    logic axiiv; // Data valid input
    logic [1:0] axiid; // Data input bus

    logic done;
    logic kill;

    logic [167:0] message = 168'h4261_7272_7921_2042_7265_616b_6661_7374_2074_696d65;
    logic [31:0] checksum = 32'h1a3a_ccb2;
    logic [199:0] both = {message, checksum};

    cksum uut (
        .clk(clk_in),
        .rst(rst_in),
        .axiiv(axiiv), 
        .axiid(axiid),
        .done(done),
        .kill(kill)
        );

    always begin
        #10;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("cksum.vcd");
        $dumpvars(0, cksum_tb);
        $display("Starting Sim");
        clk_in = 0;
        #10;
        rst_in = 0; 
        // use #20 for clock cycle 
        #20;
        rst_in = 1;
        #20; 
        rst_in = 0;
        axiiv = 1'b0;
        axiid = 2'b00;
        $display("1: ");
        #100;
        axiiv = 1'b1;
        // axiod at this point should be the checksum
        for (int i = 168; i>0; i = i - 2) begin 
            axiid = {message[i-2], message[i-1]};
            #20;
        end
        // "xor" the value with itself to get the constant
        for (int i = 32; i>0; i = i - 2) begin
            axiid = {checksum[i-2], checksum[i-1]};
            #20;
        end
        axiiv = 1'b0;
        axiid = 2'b0;
        #20;
        #500;
        $display("2: ");
        $display("3: ");
        $display("4: ");
        $display("5: ");
        $display("6: ");
        // unimplemented
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule // cksum_tb

`default_nettype wire