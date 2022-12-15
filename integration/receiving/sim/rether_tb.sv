`default_nettype none
`timescale 1ns / 1ps

module rether_tb();
    logic clk_in; // System clock
    logic rst_in; // System reset
    logic crsdv; // Data valid input
    logic [1:0] rxd; // Data input bus

    logic axiov; // Output valid
    logic [1:0] axiod; // Output data bus

    rether uut (
        .clk(clk_in),
        .rst(rst_in),
        .crsdv(crsdv), 
        .rxd(rxd),
        .axiov(axiov),
        .axiod(axiod)
        );

    always begin
        #10;
        clk_in = !clk_in;
    end

    // Bitstream off the wire e.g. preamble[1:0] is the first dibit corresponding to rxd[1:0]
    logic [55:0] preamble = 56'b01010101_01010101_01010101_01010101_01010101_01010101_01010101;
    logic [7:0] sfd = 8'b11101010;
    logic [47:0] destination = 48'b11111111_11111111_11111111_11111111_11111111_11111111;
    logic [47:0] source = 48'b11111101_01110101_00110000_00001000_11000010_10010110; 
    logic [15:0] length = 16'b00000010_00000000; // 4 bytes -> dibits backwards and big endian byte 
    // Data is of variable length
    logic [15:0] data = 16'b00110100_00010010; // data 0-padded to reach 46 bytes 
    logic [351:0] padding = 352'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    logic [31:0] fcs = 32'b11100011_00011111_01101100_10011000;

    initial begin
        $dumpfile("rether.vcd");
        $dumpvars(0, rether_tb);
        $display("Starting Sim");
        clk_in = 0;
        #10;
        rst_in = 0; 
        // use #20 for clock cycle 
        #20;
        rst_in = 1;
        #20; 
        rst_in = 0;
        $display("1: False carrier event in preamble");

        $display("2: False carrier event in sfd");

        $display("3: Loss of media during preamble");

        $display("4: Loss of media during sfd");

        #100;
        $display("5: Good preamble, tiny message");
        crsdv = 1'b1;
        #20;
        for (int i = 0; i<288; i = i + 1) begin // 288 clock cycles for entire 72 byte sequence
            if (i < 28) begin
                // rxd[1:0] = preamble[i*2+1:i*2];
                rxd[1:0] = 2'b01;
            end else if (i >= 28 && i < 32) begin
                // rxd[1:0] = sfd[i*2+1:i*2];
                case (i)
                    31: rxd[1:0] = 2'b11; 
                    default: rxd[1:0] = 2'b01;
                endcase
            end else if (i >= 32 && i < 56) begin
                // rxd[1:0] = destination[i*2+1:i*2];
                rxd[1:0] = 2'b11;
            end else if (i >= 56 && i < 80) begin
                // rxd[1:0] = source[i*2+1:i*2]; 
                rxd[1:0] = source[1:0];
                source = {source[1:0], source[47:2]};
            end else if (i >= 80 && i < 88) begin
                // rxd[1:0] = length[i*2+1:i*2];
                case (i)
                    84: rxd[1:0] = 2'b10; 
                    default: rxd[1:0] = 2'b00;
                endcase
            end else if (i >= 88 && i < 96) begin
                // rxd[1:0] = data[i*2+1:i*2];
                rxd[1:0] = data[1:0];
                data = {data[1:0], data[15:2]};
            end else if (i >= 96 && i < 272) begin
                // rxd[1:0] = padding[i*2+1:i*2];
                rxd[1:0] = 2'b00;
            end else if (i >= 272 && i < 288) begin
                // rxd[1:0] = fcs[i*2+1:i*2];
                rxd[1:0] = fcs[1:0];
                fcs = {fcs[1:0], fcs[31:2]};
            end
            #20;
        end
        crsdv = 1'b0;
        rxd = 2'b0;
        #20;
        #100;


        $display("6: 2'b10 in data but no false carrier");

        $display("7: good preamble, random message");
        crsdv = 1'b1;
        #20;
        for (int i = 0; i<288; i = i + 1) begin // 288 clock cycles for entire 72 byte sequence
            if (i < 28) begin
                // rxd[1:0] = preamble[i*2+1:i*2];
                rxd[1:0] = 2'b01;
            end else if (i >= 28 && i < 32) begin
                // rxd[1:0] = sfd[i*2+1:i*2];
                case (i)
                    31: rxd[1:0] = 2'b11; 
                    default: rxd[1:0] = 2'b01;
                endcase
            end else if (i >= 32 && i < 56) begin
                // rxd[1:0] = destination[i*2+1:i*2];
                rxd[1:0] = 2'b11;
            end else if (i >= 56 && i < 80) begin
                // rxd[1:0] = source[i*2+1:i*2]; 
                rxd[1:0] = source[1:0];
                source = {source[1:0], source[47:2]};
            end else if (i >= 80 && i < 88) begin
                // rxd[1:0] = length[i*2+1:i*2];
                case (i)
                    84: rxd[1:0] = 2'b10; 
                    default: rxd[1:0] = 2'b00;
                endcase
            end else if (i >= 88 && i < 96) begin
                // rxd[1:0] = data[i*2+1:i*2];
                rxd[1:0] = data[1:0];
                data = {data[1:0], data[15:2]};
            end else if (i >= 96 && i < 272) begin
                // rxd[1:0] = padding[i*2+1:i*2];
                rxd[1:0] = 2'b00;
            end else if (i >= 272 && i < 288) begin
                // rxd[1:0] = fcs[i*2+1:i*2];
                rxd[1:0] = fcs[1:0];
                fcs = {fcs[1:0], fcs[31:2]};
            end
            #20;
        end
        crsdv = 1'b0;
        rxd = 2'b0;
        #20;
        #100;

        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule // rether_tb

`default_nettype wire
