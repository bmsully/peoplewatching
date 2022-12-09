`default_nettype none
`timescale 1ns / 1ps

module bitorder_tb();
    logic clk_in; // System clock
    logic rst_in; // System reset
    logic axiiv; // Data valid input
    logic [1:0] axiid; // Data input bus

    logic axiov; // Output valid
    logic [1:0] axiod; // Output data bus

    bitorder uut (
        .clk(clk_in),
        .rst(rst_in),
        .axiiv(axiiv), 
        .axiid(axiid),
        .axiov(axiov),
        .axiod(axiod)
        );

    always begin
        #10;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("bitorder.vcd");
        $dumpvars(0, bitorder_tb);
        $display("Starting Sim");
        clk_in = 0;
        #10;
        rst_in = 0; 
        // use #20 for clock cycle 
        #20;
        rst_in = 1;
        #20; 
        rst_in = 0;
        $display("1: Only four bits of data");
        #100;
        axiiv = 1'b1;
        for (int i = 0; i<2; i = i + 1) begin 
            axiid = 2'b10;
            #20;
        end
        axiiv = 1'b0;
        axiid = 2'b0;
        #20;
        #100;
        $display("2: Exactly one byte of data");
        #100;
        axiiv = 1'b1;
        for (int i = 0; i<2; i = i + 1) begin 
            axiid = 2'b10;
            #20;
        end
        for (int i = 0; i<2; i = i + 1) begin
            axiid = 2'b11;
            #20;
        end
        axiiv = 1'b0;
        axiid = 2'b0;
        #20;
        #100;
        $display("3: 1.5 bytes, should only see 1 output");
        #100;
        axiiv = 1'b1;
        for (int i = 0; i<2; i = i + 1) begin 
            axiid = 2'b10;
            #20;
        end
        for (int i = 0; i<2; i = i + 1) begin
            axiid = 2'b11;
            #20;
        end
        for (int i = 0; i<2; i = i + 1) begin
            axiid = 2'b01;
            #20;
        end
        axiiv = 1'b0;
        axiid = 2'b0;
        #20;
        #100;
        $display("4: Two bytes of input, two bytes of output");
        #100;
        axiiv = 1'b1;
        for (int i = 0; i<2; i = i + 1) begin 
            axiid = 2'b10;
            #20;
        end
        for (int i = 0; i<2; i = i + 1) begin
            axiid = 2'b11;
            #20;
        end
        for (int i = 0; i<2; i = i + 1) begin
            axiid = 2'b01;
            #20;
        end
        for (int i = 0; i<2; i = i + 1) begin
            axiid = 2'b11;
            #20;
        end
        axiiv = 1'b0;
        axiid = 2'b0;
        #20;
        #100;
        $display("5: One more bit than two bytes");
        #100;
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiid = 2'b01;
        #20;
        axiid = 2'b10;
        #20;
        axiid = 2'b11;
        #20;
        axiid = 2'b11;
        #20;
        axiid = 2'b10;
        #20;
        axiid = 2'b01;
        #20;
        axiid = 2'b10;
        #20;
        // axiiv = 1'b0;
        // axiid = 2'b00;
        // #20;
        // axiiv = 1'b0;
        // axiid = 2'b00;
        // #20;
        // axiiv = 1'b0;
        // axiid = 2'b00;
        // #20;
        // axiiv = 1'b1;
        axiid = 2'b01;
        #20;
        axiiv = 1'b0;
        axiid = 2'b0;
        #20;
        #100;
        $display("6: three bytes in, three bytes out");
        // unimplemented, passes in lab05 testbench
        $display("7: two bytes in a row sans reset");
        // unimplemented, passes in lab05 testbench
        $display("8: three bytes + change sans reset");
        // unimplemented, passes in lab05 testbench
        $display("9: so many bytes");
        // unimplemented, passes in lab05 testbench
        $display("10: symmetric resest logic");
        // unimplemented, passes in lab05 testbench
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule // bitorder_tb

`default_nettype wire
