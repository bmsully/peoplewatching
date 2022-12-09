`default_nettype none
`timescale 1ns / 1ps

module top_level (
    input wire clk, //clock @ 100 mhz
    input wire btnc,
    input wire eth_crsdv,
    input wire [1:0] eth_rxd,

    output logic eth_refclk,
    output logic eth_rstn,
    output logic eth_txen,
    output logic [1:0] eth_txd,
    output logic [15:0] led,
    output logic ca, cb, cc, cd, ce, cf, cg,
    output logic [7:0] an

);
    logic sys_rst; // Global system reset
    assign sys_rst = btnc;
    assign eth_rstn = ~sys_rst; // eth_rstn resets on low signal

    divider eth_clk (.clk(clk), .ethclk(eth_refclk)); // comment out for tb

    // ############## ETHERNET RECEIVING DE-ENCAPSULATION ##############
    // Data Validity Carriers
    logic eth_axiov, bitorder_axiov, firewall_axiov, done, kill, past_done, aggregate_axiov;
    // Data Carriers
    logic [1:0] eth_axiod, bitorder_axiod, firewall_axiod;
    logic [31:0] aggregate_axiod;

    rether ethernet_in (
        .clk(eth_refclk), // comment out for tb
        // .clk(clk), // uncomment for tb
        .rst(sys_rst),
        .crsdv(eth_crsdv),
        .rxd(eth_rxd),
        .axiov(eth_axiov),
        .axiod(eth_axiod)
        );

    bitorder bitorder_in (
        .clk(eth_refclk), // comment out for tb
        // .clk(clk), // uncomment for tb
        .rst(sys_rst), 
        .axiiv(eth_axiov), 
        .axiid(eth_axiod), 
        .axiov(bitorder_axiov), 
        .axiod(bitorder_axiod)
        );

    firewall check_dest (
        .clk(eth_refclk), // comment out for tb
        // .clk(clk), // uncomment for tb
        .rst(sys_rst),
        .axiiv(bitorder_axiov),
        .axiid(bitorder_axiod),
        .axiov(firewall_axiov),
        .axiod(firewall_axiod)
    );

    cksum checksum (
        .clk(eth_refclk), // comment out for tb
        // .clk(clk), // uncomment for tb
        .rst(sys_rst),
        .axiiv(eth_axiov),
        .axiid(eth_axiod),
        .done(done),
        .kill(kill)
    );

    aggregate get_data (
        .clk(eth_refclk), // comment out for tb
        // .clk(clk), // uncomment for tb
        .rst(sys_rst),
        .axiiv(firewall_axiov),
        .axiid(firewall_axiod),
        .axiov(aggregate_axiov),
        .axiod(aggregate_axiod)
    );

    seven_segment_controller led_display (
        .clk_in(eth_refclk), // comment out for tb
        // .clk(clk), // uncomment for tb
        .rst_in(sys_rst),
        .val_in(aggregate_axiod),
        .cat_out({cg, cf, ce, cd, cc, cb, ca}),
        .an_out(an)
    );

    always_ff @(posedge eth_refclk) begin // comment out for tb
        // always_ff @(posedge clk) begin // uncomment for tb
        led[15] <= kill;
        led[14] <= done;
        if (sys_rst == 1'b1) begin
            led[13:0] <= 14'b0;
        end
        if (past_done == 1'b0 && done == 1'b1 && firewall_axiov == 1'b1)begin
            led[13:0] <= led[13:0] + 1;
        end
        past_done <= done;
    end

    // ############## ETHERNET TRANSMITTING ENCAPSULATION ##############
    // Data Validity Carriers
    logic eth_axiiv, identity_axiov, bitorder_out_axiov;
    // Data Carriers
    logic [1:0] eth_axiid, identity_axiod, bitorder_out_axiod;

    identity destandsource (
        .clk(), // comment out for tb
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