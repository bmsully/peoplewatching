`default_nettype none
`timescale 1ns / 1ps

module top_level (
    // input wire clk_100mhz, // need to pass in 100 mhz clock in order to generate 65mhz clock
    // input wire clk_50mhz,
    input wire clk, // get rid of this afterwards
    input wire btnc,
    input wire [0:0] sw,

    // Camera Input and Output
    input wire [7:0] ja, //lower 8 bits of data from camera
    input wire [2:0] jb, //upper three bits from camera (return clock, vsync, hsync)
    output logic jbclk,  //signal we provide to camera
    output logic jblock, //signal for resetting camera

    // Data output
    // output logic axiov,
    // output logic [1:0] axiod,
    output logic [15:0] led
);
    /* Ethernet clock */
    logic clk_50mhz;

    /* Camera and BRAM Loading Pipeline */
    logic clk_65mhz; //65 MHz clock line

    logic axiov;
    logic [1:0] axiod;

    clk_wiz_clk_wiz clk_wizard (.clk(clk), .ethclk(clk_50mhz), .camclk(clk_65mhz));

    logic sys_rst; // Global system reset
    assign sys_rst = btnc;
    logic ready;
    assign ready = sw[0];

    //output module generation signals:
    // logic [10:0] hcount;    // pixel on current line
    // logic [9:0] vcount;     // line number

    //camera module: (see datasheet)
    logic cam_clk_buff, cam_clk_in; //returning camera clock
    logic vsync_buff, vsync_in; //vsync signals from camera
    logic href_buff, href_in; //href signals from camera
    logic [7:0] pixel_buff, pixel_in; //pixel lines from camera
    logic [15:0] cam_pixel; //16 bit 565 RGB image from camera
    logic valid_pixel; //indicates valid pixel from camera
    logic frame_done; //indicates completion of frame from camera

    //rotate module:
    logic valid_pixel_rotate;  //indicates valid rotated pixel
    logic [15:0] pixel_rotate; //rotated 565 rotate pixel
    logic [16:0] pixel_addr_in; //address of rotated pixel in 240X320 memory

    //values  of frame buffer:
    logic [16:0] pixel_addr_out; // output address 
    logic [15:0] frame_buff; //output of scale module

    // output of scale module
    logic [15:0] full_pixel;//mirrored and scaled 565 pixel

    //Clock domain crossing to synchronize the camera's clock
    //to be back on the 65MHz system clock, delayed by a clock cycle.
    always_ff @(posedge clk_65mhz) begin
        cam_clk_buff <= jb[0]; //sync camera
        cam_clk_in <= cam_clk_buff;
        vsync_buff <= jb[1]; //sync vsync signal
        vsync_in <= vsync_buff;
        href_buff <= jb[2]; //sync href signal
        href_in <= href_buff;
        pixel_buff <= ja; //sync pixels
        pixel_in <= pixel_buff;
    end

    //Controls and Processes Camera information
    camera camera_m(
        //signal generate to camera:
        .clk_65mhz(clk_65mhz),
        .jbclk(jbclk),
        .jblock(jblock),
        //returned information from camera:
        .cam_clk_in(cam_clk_in),
        .vsync_in(vsync_in),
        .href_in(href_in),
        .pixel_in(pixel_in),
        //output framed info from camera for processing:
        .pixel_out(cam_pixel),
        .pixel_valid_out(valid_pixel),
        .frame_done_out(frame_done)
        );

      //Rotates Image to render correctly (pi/2 CCW rotate):
    rotate rotate_m (
        .cam_clk_in(cam_clk_in),
        .valid_pixel_in(valid_pixel),
        .pixel_in(cam_pixel),
        .valid_pixel_out(valid_pixel_rotate),
        .pixel_out(pixel_rotate),
        .frame_done_in(frame_done),
        .pixel_addr_in(pixel_addr_in));

    //Two Clock Frame Buffer:
    //Data written on 16.67 MHz (From camera)
    //Data read on 65 MHz (start of video pipeline information)
    //Latency is 2 cycles.
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(320*240))
        frame_buffer (
        //Write Side (16.67MHz)
        .addra(pixel_addr_in),
        .clka(cam_clk_in),
        .wea(valid_pixel_rotate),
        .dina(pixel_rotate),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(sys_rst),
        .douta(),
        //Read Side (50 MHz)
        .addrb(pixel_addr_out),
        .dinb(16'b0),
        .clkb(clk_50mhz),
        .web(1'b0),
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb(frame_buff)
    );

    //Based on current hcount and vcount as well as
    //scaling and mirror information requests correct pixel
    //from BRAM (on 65 MHz side).
    //latency: 2 cycles
    //IMPORTANT: this module is "start" of Output pipeline
    //hcount and vcount are fine here.
    //however latency in the image information starts to build up starting here
    //and we need to make sure to continue to use screen location information
    //that is "delayed" the right amount of cycles!
    //AS A RESULT, most downstream modules after this will need to use appropriately
    //pipelined versions of hcount, vcount, hsync, vsync, blank as needed
    //these The pipelining of these stages will need to be determined
    //for CHECKOFF 3!

    mirror mirror_m(
        .clk_in(clk_50mhz),
        .mirror_in(1'b1), // sw[2]
        .scale_in(2'b00), // sw[1:0]
        .hcount_in(hcount),
        .vcount_in(vcount),
        .pixel_addr_out(pixel_addr_out)
    );

    //vary the packed width based on signal
    //vary the unpacked width based on pipeling depth needed
    logic [10:0] hcount_pipe [6:0]; // 7 stages
    logic [9:0] vcount_pipe [6:0];

    // PS1, PS2, PS3 -> same input, different output stages
    always_ff @(posedge clk_50mhz)begin
        hcount_pipe[0] <= hcount;
        vcount_pipe[0] <= vcount;
        for (int i=1; i<7; i = i+1)begin
        hcount_pipe[i] <= hcount_pipe[i-1];
        vcount_pipe[i] <= vcount_pipe[i-1];
        end
    end

    //Based on hcount and vcount as well as scaling
    //gate the release of frame buffer information
    //Latency: 0
    scale scale_m(
        .scale_in(2'b00), // sw[1:0]
        .hcount_in(hcount_pipe[3]), // 4th stage
        .vcount_in(vcount_pipe[3]), // 4th stage
        .frame_buff_in(frame_buff),
        .cam_out(full_pixel)
        );

    localparam IDLE = 0;
    localparam LINENUM = 1;
    localparam DATA = 2;
    localparam IPG = 3;
    logic [1:0] state;

    logic [9:0] vcount; // handle up to 320
    logic [8:0] hcount; // handle up to 240

    logic [2:0] two_cycle_count; // Handle 8 cycles of transmitting for each value
    logic [5:0] ipg_count;

    logic [15:0] packet_send_count;

    // logic ready; // ready signal from IPG gap in ethernet transmitter (output to future top_level module) // currently from sw[0]


    always_ff @(posedge clk_50mhz) begin
        if (sys_rst) begin
            vcount <= 10'b0;
            hcount <= 9'b0;
            two_cycle_count <= 3'b0;
            ipg_count <= 0;
            packet_send_count <= 0;
            axiov <= 1'b0;
            axiod <= 2'b00;
        end
        case (state)
            IDLE: begin
                if (ready) begin
                    axiov <= 1'b1;
                    axiod <= 2'b00;
                    two_cycle_count <= 0;
                    state <= LINENUM;
                end else begin
                    axiov <= 1'b0;
                    axiod <= 2'b00;
                end
            end
            LINENUM: begin
                if (two_cycle_count < 7) begin
                    axiov <= 1'b1;
                    case (two_cycle_count)
                        0: axiod <= 2'b0;
                        1: axiod <= 2'b0;
                        2: begin
                            axiod <= vcount[9:8];
                            hcount <= 0;
                        end
                        3: axiod <= vcount[7:6];
                        4: axiod <= vcount[5:4];
                        5: axiod <= vcount[3:2];
                        6: axiod <= vcount[1:0];
                    endcase
                    two_cycle_count <= two_cycle_count + 1;
                end else begin
                    axiov <= 1'b1;
                    axiod <= full_pixel[15:14];
                    two_cycle_count <= 0;
                    state <= DATA;
                end
            end
            DATA: begin
                if (two_cycle_count < 7) begin
                    case (two_cycle_count)
                        0: axiod <= full_pixel[13:12];
                        1: axiod <= full_pixel[11:10];
                        2: begin
                            axiod <= full_pixel[9:8];
                            hcount <= hcount + 1;
                        end
                        3: axiod <= full_pixel[7:6];
                        4: axiod <= full_pixel[5:4];
                        5: axiod <= full_pixel[3:2];
                        6: axiod <= full_pixel[1:0];
                    endcase
                    two_cycle_count <= two_cycle_count + 1;
                end else begin
                    if (hcount < 240) begin
                        axiod <= full_pixel[15:14];
                        two_cycle_count <= 0;
                    end else begin
                        axiov <= 1'b0;
                        axiod <= 2'b00;
                        vcount <= (vcount == 319)?0:vcount + 1;
                        state <= IPG;
                    end
                end
            end
            IPG: begin
                axiov <= 1'b0;
                axiod <= 2'b00;
                if (ipg_count >= 35) begin
                    ipg_count <= 0;
                    packet_send_count <= packet_send_count + 1;
                    state <= IDLE;
                end else begin
                    ipg_count <= ipg_count + 1;
                end
            end
        endcase
    end

    assign led = packet_send_count;

endmodule

`default_nettype wire
