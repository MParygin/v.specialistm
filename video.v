`timescale 1ns / 1ps
module video(
  output wire [15:0] RAM_ADDRB,
  output wire RAM_CLKB,
  input wire [7:0] RAM_DOUTB,
  input wire [2:0] RGB,
  input wire CLK,
  output [3:0] TMDS,
  output [3:0] TMDSB
);
    
    // pipe 1 stage ======================================================================
    
    // clock pixel
    wire pixclk;
    assign RAM_CLKB = pixclk;
    
    // vga generator
    wire [11:0] hdata_w0;
    wire [11:0] vdata_w0;
    wire hsync_w0;
    wire vsync_w0;
    wire de_w0;
    reg [11:0] hdata_b0;
    reg [11:0] vdata_b0;
    reg hsync_b0;
    reg vsync_b0;
    reg de_b0;
    
    vga1920x1080x60 vga_inst (
      .clk(pixclk),
      .hdata(hdata_w0),
      .vdata(vdata_w0),
      .hsync(hsync_w0),
      .vsync(vsync_w0),
      .de(de_w0)
    );
    
    always @ (posedge pixclk)
    begin
      hdata_b0 <= hdata_w0;
      vdata_b0 <= vdata_w0;
      hsync_b0 <= hsync_w0;
      vsync_b0 <= vsync_w0;
      de_b0 <= de_w0;
    end
    
    // pipe 2 stage ======================================================================
    
    // address of video out 1536x1024 (upscale 4x) with offset 192*28 pixels
    wire [7:0] row = vdata_b0[9:2] - 7;
    wire [5:0] col = hdata_b0[10:5] - 6;
    wire [15:0] video_address = {2'b00, col, row} + 16'h9000; // 2, 6, 8 = 16 bit
    reg [15:0] video_address_b1;
    
    // visible area
    wire cx = (hdata_b0 >= 192) && (hdata_b0 < 1728);
    wire cy = (vdata_b0 >= 28) && (vdata_b0 < 1052);
    reg cx_b1, cy_b1;
    
    // vga
    reg [11:0] hdata_b1;
    reg [11:0] vdata_b1;
    reg hsync_b1;
    reg vsync_b1;
    reg de_b1;
    
    always @ (posedge pixclk)
    begin
      video_address_b1 <= video_address;
      cx_b1 <= cx;
      cy_b1 <= cy;
      hdata_b1 <= hdata_b0;
      vdata_b1 <= vdata_b0;
      hsync_b1 <= hsync_b0;
      vsync_b1 <= vsync_b0;
      de_b1 <= de_b0;
    end
    
    // video RAM
    assign RAM_ADDRB = video_address_b1; 
    
    // pipe 3 stage ======================================================================
    
    reg cx_b2, cy_b2;
    reg [11:0] hdata_b2;
    reg hsync_b2;
    reg vsync_b2;
    reg de_b2;
    
    always @ (posedge pixclk)
    begin
      cx_b2 <= cx_b1;
      cy_b2 <= cy_b1;
      hdata_b2 <= hdata_b1;
      hsync_b2 <= hsync_b1;
      vsync_b2 <= vsync_b1;
      de_b2 <= de_b1;
    end
    
    
    // pipe 4 stage ======================================================================
    
    reg [7:0] color_r_b3;
    reg [7:0] color_g_b3;
    reg [7:0] color_b_b3;
    reg hsync_b3;
    reg vsync_b3;
    reg de_b3;
    
    always @ (posedge pixclk)
    begin
      color_r_b3 <= (cx_b2 && cy_b2) ? (RAM_DOUTB[~hdata_b2[4:2]] == 1'b0) ? 8'h0F : {~RGB[2], 7'h00} : 0;
      color_g_b3 <= (cx_b2 && cy_b2) ? (RAM_DOUTB[~hdata_b2[4:2]] == 1'b0) ? 8'h0F : {~RGB[1], 7'h00} : 0;
      color_b_b3 <= (cx_b2 && cy_b2) ? (RAM_DOUTB[~hdata_b2[4:2]] == 1'b0) ? 8'h0F : {~RGB[0], 7'h00} : 0;
      hsync_b3 <= hsync_b2;
      vsync_b3 <= vsync_b2;
      de_b3 <= de_b2;
    end
    
    // pipe 5 stage ======================================================================
    
    reg [7:0] red_b4, green_b4, blue_b4;
    reg hsync_b4;
    reg vsync_b4;
    reg de_b4;
    
    always @ (posedge pixclk)
    begin
      red_b4 <= (de_b3 == 1'b0) ? 8'h00 : color_r_b3;
      green_b4 <= (de_b3 == 1'b0) ? 8'h00 : color_g_b3;
      blue_b4 <= (de_b3 == 1'b0) ? 8'h00 : color_b_b3;
      hsync_b4 <= hsync_b3;
      vsync_b4 <= vsync_b3;
      de_b4 <= de_b3;
    end
    
    
    // debug wires
    //wire [31:0] debug = { 2'b11, RAM_ADDRA, 2'b11, RAM_DINA, 4'b1001 };
    //wire [7:0] c_debug = (hdata[11:2] == 0) ? ( debug[~hdata[6:2]] == 1'b1 ) : c; 
    //wire [7:0] c_debug = (hdata[11:5] == 0) ? RAM_ADDRA[15:8] : c; 
    
    
    // TMDS
    
    ////////////////////////////////////////////////////////////////
    // DVI Encoder
    ////////////////////////////////////////////////////////////////
    
    // clock 148.5
    wire clk_tmp;
    wire clk_tmp2;
    wire clk2; // was 20 10
    dcm #(.M(27),.D(20)) c0 (.in(CLK), .fx_out(clk_tmp)); 
    dcm #(.M(11),.D(10)) c1 (.in(clk_tmp), .fx_out(clk2));
    
    dvi_out DVI (
      //.reset(~BTN_RST_N), 
      .reset(1'b0), 
      .clkfx(clk2), 
      .clk_out(pixclk), 
      
      .red_data(red_b4), 
      .green_data(green_b4), 
      .blue_data(blue_b4),
      .hsync(hsync_b4), 
      .vsync(vsync_b4), 
      .de(de_b4),
       
      .TMDS(TMDS), 
      .TMDSB(TMDSB)
    );    
    
endmodule
