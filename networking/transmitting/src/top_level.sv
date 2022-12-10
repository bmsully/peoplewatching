`default_nettype none
`timescale 1ns / 1ps

module top_level (
    input wire clk, //clock @ 100 mhz
    input wire btnc,
    input wire btnr,

    output wire eth_refclk,
    output wire eth_rstn,
    output logic eth_txen,
    output logic [1:0] eth_txd
);
    logic sys_rst; // Global system reset
    assign sys_rst = btnc;
    assign eth_rstn = ~btnc;

    logic data_transmitted;
    logic [31:0] data = 32'hFEED_BEEF;
    // logic [31:0] data = 32'b11111111_11111111_11111111_11111111;
    logic [4:0] counter;

    output_monitor see_the_stuff (.clk(eth_refclk), .probe0(eth_refclk), .probe1(eth_rstn), .probe2(eth_txen), .probe3(eth_txd));

    divider eth_clk (.clk(clk), .ethclk(eth_refclk)); // comment out for tb

    // ############## ETHERNET TRANSMITTING ENCAPSULATION ##############
    // Data Validity Carriers
    logic eth_axiiv, identity_axiov, bitorder_out_axiov, old_btnr;
    // Data Carriers
    logic [1:0] eth_axiid, identity_axiod, bitorder_out_axiod;

    always_ff @(posedge eth_refclk) begin // comment out for tb
        // always_ff @(posedge clk) begin // uncomment for tb
        if (sys_rst == 1'b1) begin
            data_transmitted <= 1'b1;
            counter <= 0;
        end
	old_btnr <= btnr;
	if (btnr & ~old_btnr) begin
	    data_transmitted <= 1'b0;
	    counter <= 0;
	end
	if (~data_transmitted) begin
	    if (counter < 16) begin
		eth_axiiv <= 1'b1;
		eth_axiid <= data[31:30];
		data <= {data[29:0], data[31:30]};
		counter <= counter + 1;
	    end else begin
		eth_axiiv <= 1'b0;
		eth_axiid <= 2'b0;
		data_transmitted <= 1'b1;
	    end
        end else begin
            eth_axiiv <= 1'b0;
            eth_axiid <= 2'b0;
        end
    end


    identity destandsource (
        .clk(eth_refclk), // comment out for tb
        // .clk(clk), // uncomment for tb
        .rst(sys_rst),
        .axiiv(eth_axiiv),
        .axiid(eth_axiid),
        .axiov(identity_axiov),
        .axiod(identity_axiod)
    );

    bitorder bitorder_out (
        .clk(eth_refclk), // comment out for tb
        // .clk(clk), // uncomment for tb
        .rst(sys_rst), 
        .axiiv(identity_axiov), 
        .axiid(identity_axiod), 
        .axiov(bitorder_out_axiov), 
        .axiod(bitorder_out_axiod)
        );

    tether ethernet_out (
        .clk(eth_refclk), // comment out for tb
        // .clk(clk), // uncomment for tb
        .rst(sys_rst),
        .axiiv(bitorder_out_axiov),
        .axiid(bitorder_out_axiod),
        .axiov(eth_txen),
        .axiod(eth_txd)
        );
    // create some sort of data source to transmit i.e. "BEEF" etc.


endmodule

`default_nettype wire
