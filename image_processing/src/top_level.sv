`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz, //clock @ 100 mhz
  input wire [15:0] sw, //switches
  input wire btnc, //btnc (used for reset)
  input wire btnl, //btnc (used for reset)

  input wire [7:0] ja, //lower 8 bits of data from camera
  input wire [2:0] jb, //upper three bits from camera (return clock, vsync, hsync)
  output logic jbclk,  //signal we provide to camera
  output logic jblock, //signal for resetting camera

  output logic [15:0] led, //just here for the funs

  output logic [3:0] vga_r, vga_g, vga_b,
  output logic vga_hs, vga_vs,
  output logic [7:0] an,
  output logic caa,cab,cac,cad,cae,caf,cag

  );

  //system reset switch linking
  logic sys_rst; //global system reset
  assign sys_rst = btnc; //just done to make sys_rst more obvious
  assign led = sw; //switches drive LED (change if you want)

  /* Video Pipeline */
  logic clk_65mhz; //65 MHz clock line

  //vga module generation signals:
  logic [10:0] hcount;    // pixel on current line
  logic [9:0] vcount;     // line number
  logic hsync, vsync, blank; //control signals for vga
  logic hsync_t, vsync_t, blank_t; //control signals out of transform


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
  logic [16:0] pixel_addr_out; //
  logic [15:0] frame_buff; //output of scale module

  // output of scale module
  logic [15:0] full_pixel;//mirrored and scaled 565 pixel

  //output of rgb to ycrcb conversion:
  logic [9:0] y; //[2:0]; //ycrcb conversion of full pixel (NEW)
  logic [9:0] cr; //[2:0]; //ycrcb conversion of full pixel (NEW)
  logic [9:0] cb; //[2:0]; //ycrcb conversion of full pixel (NEW)

  //output of threshold module:
  logic mask; //Whether or not thresholded pixel is 1 or 0
  logic [3:0] sel_channel; //selected channels four bit information intensity
  //sel_channel could contain any of the six color channels depend on selection

  //Center of Mass variables
  logic [10:0] x_com, x_com_calc; //long term x_com and output from module, resp
  logic [9:0] y_com, y_com_calc; //long term y_com and output from module, resp
  logic new_com; //used to know when to update x_com and y_com ...
  //using x_com_calc and y_com_calc values

  //output of image sprite
  //Output of sprite that should be centered on Center of Mass (x_com, y_com):
  logic [11:0] com_sprite_pixel;

  //Crosshair value hot when hcount,vcount== (x_com, y_com)
  logic crosshair;

  //vga_mux output:
  logic [11:0] mux_pixel; //final 12 bit information from vga multiplexer
  //goes right into RGB of output for video render

  //Generate 65 MHz:
  clk_wiz_lab3 clk_gen(
    .clk_in1(clk_100mhz),
    .clk_out1(clk_65mhz)); //after frame buffer everything on clk_65mhz


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
    .frame_done_out(frame_done));

  //NEW FOR LAB 04B (START)----------------------------------------------
  
  logic [15:0] pixel_data_rec; // pixel data from recovery module
  logic [10:0] hcount_rec; //hcount from recovery module
  logic [9:0] vcount_rec; //vcount from recovery module
  logic  data_valid_rec; //single-cycle (65 MHz) valid data from recovery module

  logic [10:0] hcount_f0;  //hcount from filter modules
  logic [9:0] vcount_f0; //vcount from filter modules
  logic [15:0] pixel_data_f0; //pixel data from filter modules
  logic data_valid_f0; //valid signals for filter modules

  logic [10:0] hcount_f [5:0];  //hcount from filter modules
  logic [9:0] vcount_f [5:0]; //vcount from filter modules
  logic [15:0] pixel_data_f [5:0]; //pixel data from filter modules
  logic data_valid_f [5:0]; //valid signals for filter modules

  logic [10:0] hcount_fmux; //hcount from filter mux
  logic [9:0]  vcount_fmux; //vcount from filter mux
  logic [15:0] pixel_data_fmux; //pixel data from filter mux
  logic data_valid_fmux; //data valid from filter mux




  //recovers hcount and vcount from camera module:
  //generates data and a valid signal on 65 MHz
  recover recover_m (
    .cam_clk_in(cam_clk_in),
    .valid_pixel_in(valid_pixel),
    .pixel_in(cam_pixel),
    .frame_done_in(frame_done),

    .system_clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .pixel_out(pixel_data_rec),
    .data_valid_out(data_valid_rec),
    .hcount_out(hcount_rec),
    .vcount_out(vcount_rec));


    // NEW FOR PROJECT

  logic pixel_bw;
  logic [10:0] hcount_bw;
  logic [9:0] vcount_bw;
  logic data_valid_bw;

  logic pixel_pixelated;
  logic [4:0] hcount_pixelated;
  logic [4:0] vcount_pixelated;
  logic data_valid_pixelated;

  logic signed [20:0] pixelate_normalize;
  logic [4:0] hcount_normalize;
  logic [4:0] vcount_normalize;
  logic data_valid_normalize;

  logic data_valid_conv9;
  logic signed [20:0] pixel_conv9;
  logic [4:0] hcount_conv9;
  logic [4:0] vcount_conv9;

  logic data_valid_conv7;
  logic signed [20:0] pixel_conv7;
  logic [4:0] hcount_conv7;
  logic [4:0] vcount_conv7;
  
  logic [4:0] conv_output_frame_buff_addr_out;
  logic signed [20:0] conv_output_frame_buff;

  logic [1:0][4:0] hcount_conv7_pipe;
  logic [1:0][4:0] vcount_conv7_pipe;

  logic frame_done;

  logic data_valid_dense;
  logic [4:0] hcount_pred;
  logic [4:0] vcount_pred;

  logic [15:0] pixel_box;
  logic [4:0] hcount_box;
  logic [4:0] vcount_box;
  logic data_valid_box;

  logic pixel_unpixelated;
  logic [10:0] hcount_unpixelated;
  logic [9:0] vcount_unpixelated;
  logic data_valid_unpixelated;

  logic in_mask;
  logic [15:0] pixel_out_mask;
  logic [9:0] addr_out_out;

  bw_converter bw_convert (
  .clk_in(clk_65mhz),
  .hcount_in(hcount_rec),
  .vcount_in(vcount_rec),
  .data_valid_in(data_valid_rec),
  .pixel_in(pixel_data_rec),
  .pixel_out(pixel_bw),
  .hcount_out(hcount_bw),
  .vcount_out(vcount_bw),
  .data_valid_out(data_valid_bw)
  );

  pixelate pixelate_m (
  .clk_in(clk_65mhz),
  .hcount_in(hcount_bw),
  .vcount_in(vcount_bw),
  .data_valid_in(data_valid_bw),
  .pixel_in(pixel_bw),
  .pixel_out(pixel_pixelated),
  .hcount_out(hcount_pixelated),
  .vcount_out(vcount_pixelated),
  .data_valid_out(data_valid_pixelated)
  );

  normalize normalize_m (
  .clk_in(clk_65mhz),
  .hcount_in(hcount_pixelated),
  .vcount_in(vcount_pixelated),
  .data_valid_in(data_valid_pixelated),
  .pixel_in(pixel_pixelated),
  .pixel_out(pixelate_normalize),
  .hcount_out(hcount_normalize),
  .vcount_out(vcount_normalize),
  .data_valid_out(data_valid_normalize)
  );

  convolution_layer_9 convolution_layer_9_m (
    .clk_in(clk_65mhz),
  .hcount_in(hcount_normalize),
  .vcount_in(vcount_normalize),
  .data_valid_in(data_valid_normalize),
  .pixel_in(pixelate_normalize),
  .pixel_out(pixel_conv9),
  .hcount_out(hcount_conv9),
  .vcount_out(vcount_conv9),
  .data_valid_out(data_valid_conv9)
  );

  convolution_layer_7 convolution_layer_7_m (
    .clk_in(clk_65mhz),
  .hcount_in(hcount_conv9),
  .vcount_in(vcount_conv9),
  .data_valid_in(data_valid_conv9),
  .pixel_in(pixel_conv9),
  .pixel_out(pixel_conv7),
  .hcount_out(hcount_conv7),
  .vcount_out(vcount_conv7),
  .data_valid_out(data_valid_conv7)
  );

  //pipelining hcount and vcount

  hcount_conv7_pipe[0] <= hcount_conv7;
  hcount_conv7_pipe[1] <= hcount_conv7_pipe[0];

  vcount_conv7_pipe[0] <= vcount_conv7;
  vcount_conv7_pipe[1] <= vcount_conv7_pipe[0];
  
  // convolution output framebuffer
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(21),
    .RAM_DEPTH(32*24))
    conv_output_frame_buffer (
      //write side
    .addra(24*vcount_conv7 + hcount_conv7),
    .clka(clk_65mhz), 
    .wea(data_valid_conv7),
    .dina(pixel_conv7),
    .dina2(),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(sys_rst),
    .douta(),
    //Read Side 
    .addrb(conv_output_frame_buff_addr_out),
    .dinb(16'b0),
    .dinb2(line_done), //1 when one line is ready to go into dense_layer
    .clkb(clk_65mhz),
    .web(1'b0),
    .enb(1'b1),
    .rstb(sys_rst),
    .regceb(1'b1),
    .doutb(conv_output_frame_buff)
  );

  dense_layer dense_layer_m (.clk_in(clk_65mhz),
  .hcount_in(hcount_conv7_pipe[1]),
  .vcount_in(vcount_conv7_pipe[1]),
  .data_valid_in(line_done),
  .pixel_in(conv_output_frame_buff),
  .hcount_out(hcount_pred),
  .vcount_out(vcount_pred),
  .data_valid_out(data_valid_dense)
  );

  draw_box draw_box_m (
    .clk_in(clk_65mhz),
  .hcount_pred(hcount_pred),
  .vcount_pred(vcount_pred),
  .data_valid_in(data_valid_dense),
  .pixel_out(pixel_box),
  .hcount_out(hcount_box),
  .vcount_out(vcount_box),
  .data_valid_out(data_valid_box)
  );

  unpixelate unpixelate_m(
    .clk_in(clk_65mhz),
    .hcount_in(hcount_box),
    .vcount_in(vcount_box),
    .data_valid_in(data_valid_box),
    .hcount_array_out(hcount_unpixelated),
    .vcount_array_out(vcount_unpixelated),
    .data_valid_out(data_valid_unpixelated),
    .pixel_out(pixel_unpixelated),
  );

  // un-pixelated mask buffer
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(240 *320), //hcount,vcount   
    .RAM_DEPTH(16)) // number of pixels in box 
    mask_frame_buffer (
      //write side
    .addra(24*vcounts_unpixelated + hcounts_unpixelated),
    .clka(clk_65mhz), 
    .wea(data_valid_unpixelated),
    .dina(pixel_unpixelated),
    .dina2(1'b1), // signal indicates if pixel included in mask
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(sys_rst),
    .douta(),
    //Read Side 
    .addrb(addr_out_out),
    .dinb(16'b0),
    .dinb2(in_mask) // signal indicates if pixel included in mask
    .clkb(clk_65mhz),
    .web(1'b0),
    .enb(1'b1),
    .rstb(sys_rst),
    .regceb(1'b1),
    .doutb(pixel_out_mask)
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


  // pipelining 
  logic [10:0] hcount_pipe [7-1:0];
  logic [9:0] vcount_pipe [7-1:0];
  logic [8-1:0] hsync_pipe;
  logic [8-1:0] vsync_pipe;
  logic [8-1:0] blank_pipe;
  logic [4-1:0] crosshair_pipe;
  logic [15:0] full_pixel_pipe [3-1:0];

  always_ff @(posedge clk_65mhz)begin
    hcount_pipe[0] <= hcount;
    vcount_pipe[0] <= vcount;
    hsync_pipe[0] <= hsync;
    vsync_pipe[0] <= vsync;
    blank_pipe[0] <= blank;
    full_pixel_pipe[0] <= full_pixel;
    for (int i=1; i<7; i = i+1)begin
      hcount_pipe[i] <= hcount_pipe[i-1];
      vcount_pipe[i] <= vcount_pipe[i-1];
      blank_pipe[i] <= blank_pipe[i-1];
    end
    for (int i=1; i<8; i = i+1)begin
      hsync_pipe[i] <= hsync_pipe[i-1];
      vsync_pipe[i] <= vsync_pipe[i-1];
    end
    for (int i=1; i<3; i = i+1)begin
      full_pixel_pipe[i] <= full_pixel_pipe[i-1];
    end
  end

  //integrate mask
  always_comb begin
    if (data_valid_unpixelated == 1) begin
      full_pixel_pipe <= pixel_out_mask
    end
  end


  //Generate VGA timing signals:
  vga vga_gen(
    .pixel_clk_in(clk_65mhz),
    .hcount_out(hcount),
    .vcount_out(vcount),
    .hsync_out(hsync),
    .vsync_out(vsync),
    .blank_out(blank));

  

  mirror mirror_m(
    .clk_in(clk_65mhz),
    .mirror_in(1'b1), //NEW FOR LAB 04B
    .scale_in(2'b01), //NEW FOR LAB 04B
    .hcount_in(hcount), //
    .vcount_in(vcount),
    .pixel_addr_out(pixel_addr_out)
  );

  //Based on hcount and vcount as well as scaling
  //gate the release of frame buffer information
  //Latency: 0
  scale scale_m(
    .scale_in(2'b01), //NEW FOR LAB 04B
    .hcount_in(hcount), //TODO: needs to use pipelined signal (PS2)
    .vcount_in(vcount), //TODO: needs to use pipelined signal (PS2)
    .frame_buff_in(frame_buff),
    .cam_out(full_pixel)
    );

    //blankig logic.
  //latency 1 cycle
  always_ff @(posedge clk_65mhz)begin
    vga_r <= ~blank?full_pixel[11:8]:0; //TODO: needs to use pipelined signal (PS6)
    vga_g <= ~blank?full_pixel[7:4]:0;  //TODO: needs to use pipelined signal (PS6)
    vga_b <= ~blank?full_pixel[3:0]:0;  //TODO: needs to use pipelined signal (PS6)
  end

  assign vga_hs = ~hsync;  //TODO: needs to use pipelined signal (PS7)
  assign vga_vs = ~vsync;  //TODO: needs to use pipelined signal (PS7)

  // END OF PROJECT



endmodule




`default_nettype wire
