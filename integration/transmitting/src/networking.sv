`default_nettype none
`timescale 1ns / 1ps

module networking (
    input wire eth_refclk, //clock @ 50 mhz
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid, 

    input wire eth_crsdv,
    input wire [1:0] eth_rxd,
    output logic eth_txen,
    output logic [1:0] eth_txd,

    output logic [6:0] cat_out,
    output logic [7:0] an
);

    // Data Validity Carriers
    logic identity_axiov, bitorder_out_axiov;
    // Data Carriers
    logic [1:0] identity_axiod, bitorder_out_axiod;

    logic [31:0] send_counter;
    logic past_txen;

    always_ff @(posedge eth_refclk) begin 
        if (rst) begin
            send_counter <= 32'h00000000;
        end
        past_txen <= eth_txen;
        if (~eth_txen & past_txen) begin
            send_counter <= send_counter + 32'h100;
        end
    end


    identity destandsource (
        .clk(eth_refclk), 
        .rst(rst),
        .axiiv(axiiv),
        .axiid(axiid),
        .axiov(identity_axiov),
        .axiod(identity_axiod)
    );

    bitorder bitorder_out (
        .clk(eth_refclk), 
        .rst(rst), 
        .axiiv(identity_axiov), 
        .axiid(identity_axiod), 
        .axiov(bitorder_out_axiov), 
        .axiod(bitorder_out_axiod)
        );

    tether ethernet_out (
        .clk(eth_refclk), 
        .rst(rst),
        .axiiv(bitorder_out_axiov),
        .axiid(bitorder_out_axiod),
        .axiov(eth_txen),
        .axiod(eth_txd)
        );

    seven_segment_controller led_display (
        .clk_in(eth_refclk), 
        .rst_in(rst),
        .val_in(send_counter),
        .cat_out(cat_out),
        .an_out(an)
    );


endmodule

`default_nettype wire
