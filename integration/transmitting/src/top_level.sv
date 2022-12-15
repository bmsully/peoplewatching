`default_nettype none
`timescale 1ns / 1ps

module top_level (
    input wire clk, // clock @100mhz
    // Control
    input wire btnc,
    input wire [0:0] sw,

    // Ethernet Input and Output
    input wire eth_crsdv,
    input wire [1:0] eth_rxd,
    output logic eth_refclk,
    output logic eth_rstn,
    output logic eth_txen,
    output logic [1:0] eth_txd,

    // Camera Input and Output
    input wire [7:0] ja, //lower 8 bits of data from camera
    input wire [2:0] jb, //upper three bits from camera (return clock, vsync, hsync)
    output logic jbclk,  //signal we provide to camera
    output logic jblock, //signal for resetting camera

    // Board Feedback
    output logic cg, cf, ce, cd, cc, cb, ca,
    output logic [7:0] an,
    output logic [15:0] led // going to have issue here
);

    logic sys_rst; // Global system reset
    assign sys_rst = btnc;
    assign eth_rstn = ~sys_rst;

     /* Ethernet clock */
    logic clk_50mhz;
    /* Camera and BRAM Loading Pipeline */
    logic clk_65mhz; //65 MHz clock line

    clk_wiz_clk_wiz clk_wizard (.clk(clk), .ethclk(clk_50mhz), .camclk(clk_65mhz));

    assign eth_refclk = clk_50mhz;

    logic ready;
    assign ready = sw[0];

    logic axiov_cam;
    logic [1:0] axiod_cam;

    camera_feed stream_input (
        .clk_65mhz(clk_65mhz),
        .clk_50mhz(clk_50mhz),
        .rst(sys_rst),
        .ready(ready),
        .ja(ja),
        .jb(jb),
        .jbclk(jbclk),
        .jblock(jblock),
        .axiov(axiov_cam),
        .axiod(axiod_cam),
        .led(led)
    );

    networking ethernet (
        .eth_refclk(clk_50mhz),
        .rst(sys_rst),
        .axiiv(axiov_cam),
        .axiid(axiod_cam),
        .eth_crsdv(eth_crsdv),
        .eth_rxd(eth_rxd),
        .eth_txen(eth_txen),
        .eth_txd(eth_txd),
        .cat_out({cg, cf, ce, cd, cc, cb, ca}),
        .an(an)
    );

    // always_ff @(posedge ) begin
    //     // do something cool with data collection here :)
    // end

endmodule

`default_nettype wire