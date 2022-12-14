`default_nettype none
`timescale 1ns / 1ps

module firewall_tb();
    logic clk_in; // System clock
    logic rst_in; // System reset
    logic axiiv; // Data valid input
    logic [1:0] axiid; // Data input bus

    logic axiov; // Output valid
    logic [1:0] axiod; // Output data bus

    firewall uut (
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
        $dumpfile("firewall.vcd");
        $dumpvars(0, firewall_tb);
        $display("Starting Sim");
        clk_in = 0;
        // #10;
        rst_in = 0; 
        // use #20 for clock cycle 
        #20;
        rst_in = 1;
        #20; 
        rst_in = 0;
        $display("1: Garbage MAC Address");
        #100;
        axiiv = 1'b1;
        for (int i = 0; i<24; i = i + 1) begin 
            axiid = 2'b10;
            #20;
        end
        axiiv = 1'b0;
        axiid = 2'b0;
        #20;
        #500;
        $display("2: Off by one MAC Address");
        // device_addr = 01101001_01101001_01011010_00000110_01010100_10010001 
        #100; 
        axiiv = 1'b1;
        axiid = 2'b01; // 69
        #20;
        axiid = 2'b10;
        #20;
        axiid = 2'b10;
        #20;
        axiid = 2'b01;
        #20;
        axiid = 2'b01; // 69
        #20;
        axiid = 2'b10;
        #20;
        axiid = 2'b10;
        #20;
        axiid = 2'b01;
        #20;
        axiid = 2'b01; // 5A
        #20;
        axiid = 2'b01;
        #20;
        axiid = 2'b10;
        #20;
        axiid = 2'b10;
        #20;
        axiid = 2'b00; // 06
        #20;
        axiid = 2'b00;
        #20;
        axiid = 2'b01;
        #20;
        axiid = 2'b10;
        #20;
        axiid = 2'b01; // 54
        #20;
        axiid = 2'b01;
        #20;
        axiid = 2'b01;
        #20;
        axiid = 2'b00;
        #20;
        axiid = 2'b10; // 90 instead of 91
        #20;
        axiid = 2'b01;
        #20;
        axiid = 2'b00;
        #20;
        axiid = 2'b00;
        #20;
        for (int i = 0; i<4; i = i + 1) begin // 2 bytes of arbitrary data
            axiid = 2'b10;
            #20;
        end
        axiiv = 1'b0;
        axiid = 2'b0;
        #20;
        #100;
        $display("3: Broadcast Address");
        #100;
        axiiv = 1'b1;
        // Destination Address
        for (int i = 0; i<24; i = i + 1) begin 
            axiid = 2'b11;
            #20;
        end
        // Header Address
        for (int i = 0; i<24; i = i + 1) begin 
            axiid = 2'b01;
            #20;
        end
        // Data length
        for (int i = 0; i<7; i = i + 1) begin
            axiid = 2'b00;
            #20;
        end
        axiid = 2'b10;
        #20;
        // Arbitrary data
        // for (int i = 0; i<4; i = i + 1) begin 
        //     axiid = 2'b01;
        //     #20;
        // end
        axiid = 2'b11;
        #20;
        axiid = 2'b00;
        #20;
        axiid = 2'b01;
        #20;
        axiid = 2'b11;
        #20;
        axiiv = 1'b0;
        axiid = 2'b0;
        #20;
        #100;
        $display("4: Personalized MAC Address");
        $display("5: Personal mac + tiny message");
        $display("6: Personal mac + beeg message");
        // unimplemented
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule // firewall_tb

`default_nettype wire