`timescale 1ns / 1ps

module main(

  //------------------Cypress CY7C68013A-56
   input wire      fx2Clk_in,
  output wire[1:0] fx2Addr_out,   // select FIFO: "10" for EP6OUT, "11" for EP8IN
   inout wire[7:0] fx2Data_io,    // 8-bit data to/from FX2
  // When EP6OUT selected:
  output wire      fx2Read_out,   // asserted (active-low) when reading from FX2
  output wire      fx2OE_out,     // asserted (active-low) to tell FX2 to drive bus
   input wire      fx2GotData_in, // asserted (active-high) when FX2 has data for us
  // When EP8IN selected:
  output wire      fx2Write_out,  // asserted (active-low) when writing to FX2
   input wire      fx2GotRoom_in, // asserted (active-high) when FX2 has room for more data from us
  output wire      fx2PktEnd_out, // asserted (active-low) when a host read needs to be committed early


    input BTN_RST_N,
    input wire [3:1] btn,
    input wire UartRx,
    
    output wire [7:0] Led,

    input wire CLK,
    output [3:0] TMDS,
    output [3:0] TMDSB
);

// connections
wire [7:0] DATA_OUT_IO;
wire [7:0] DATA_OUT_RAM;
wire [7:0] DATA_OUT;
wire BUS_HOLD;
wire BUS_SELECT;

// write
wire CPU_WE;
wire LOADER_WE;
wire RAM_WE = CPU_WE | LOADER_WE;

// select
wire [7:0] CPU_DATA_IN;
wire [7:0] LOADER_DATA_IN;
wire [7:0] DATA_IN = (BUS_SELECT) ? LOADER_DATA_IN : CPU_DATA_IN;
wire [15:0] CPU_ADDRESS;
wire [15:0] LOADER_ADDRESS;
wire [15:0] ADDRESS = (BUS_SELECT) ? LOADER_ADDRESS : CPU_ADDRESS;


wire [2:0] RGB;
wire [2:0] RGB_OUT;



// selector
wire E_RAM, E_IO, E_COLOR;
selector selector_inst (
  .CLK(CLK),
  .ADDRESS(CPU_ADDRESS),
  .RAM(E_RAM),
  .IO(E_IO),
  .COLOR(E_COLOR),
  .DATA_IO(DATA_OUT_IO),
  .DATA_RAM(DATA_OUT_RAM),
  .DATA(DATA_OUT)
);

// RAM 64k
wire RAM_CLKB;
wire [15:0] RAM_ADDRB;
wire [7:0] RAM_DOUTB;
wire RAM_B_WRITE_ENABLE;
wire [7:0] RAM_B_DATA_IN;

blk_mem ram (
  .clka(CLK), // input clka
  .ena(E_RAM), // input ena
  .wea(RAM_WE), // input [0 : 0] wea
  .addra(ADDRESS), // input [15 : 0] addra
  .dina(DATA_IN), // input [7 : 0] dina
  .douta(DATA_OUT_RAM), // output [7 : 0] douta
  .clkb(RAM_CLKB), // input clkb
  .enb(1'b1), // input enb
  .web(1'b0), // input [0 : 0] web
  .addrb(RAM_ADDRB), // input [15 : 0] addrb
  .dinb(8'hFF), // input [7 : 0] dinb
  .doutb(RAM_DOUTB) // output [7 : 0] doutb
);

// shadow buffer ram 12k
blk_mem_color ram_color (
  .clka(CLK), // input clka
  .ena(E_COLOR), // input ena
  .wea(RAM_WE), // input [0 : 0] wea
  .addra(CPU_ADDRESS[13:0]), // input [13 : 0] addra
  .dina(RGB), // input [2 : 0] dina
  .douta(), // output [2 : 0] douta
  .clkb(RAM_CLKB), // input clkb
  .enb(1'b1), // input enb
  .web(1'b0), // input [0 : 0] web
  .addrb(RAM_ADDRB[13:0]), // input [13 : 0] addrb
  .dinb(3'h7), // input [2 : 0] dinb
  .doutb(RGB_OUT) // output [2 : 0] doutb
);

// USB uploader
wire c48;
IBUFG X1Y0 (
   .O(c48),   // Clock buffer output 48 MHz
   .I(fx2Clk_in)  // Clock buffer input from CYPRESS 48 MHz
);

wire [7:0] h2f;
wire h2f_v;


  // CommFPGA module
  assign fx2Read_out = fx2Read;
  assign fx2OE_out = fx2Read;
  assign fx2Addr_out[1] = 1'b1;  // Use EP6OUT/EP8IN, not EP2OUT/EP4IN.
  comm_fpga_fx2 comm_fpga_fx2(
	// FX2 interface
	.fx2Clk_in(c48),
	.fx2FifoSel_out(fx2Addr_out[0]),
	.fx2Data_io(fx2Data_io),
	.fx2Read_out(fx2Read),
	.fx2GotData_in(fx2GotData_in),
	.fx2Write_out(fx2Write_out),
	.fx2GotRoom_in(fx2GotRoom_in),
	.fx2PktEnd_out(fx2PktEnd_out),

	// Channel read/write interface
	.chanAddr_out(),
	.h2fData_out(h2f),
    .h2fValid_out(h2f_v),
    .h2fReady_in(1'b1), // always ready
    .f2hData_in(8'h00),
    .f2hValid_in(1'b0),
    .f2hReady_out()
);

// FIFO
wire [7:0] FIFO_OUT;
wire FIFO_V_N;
wire FIFO_RD;
fifo_generator_v9_3_0 fifo (
  .wr_clk(c48), // input wr_clk
  .rd_clk(CLK), // input rd_clk
  .din(h2f), // input [7 : 0] din
  .wr_en(h2f_v), // input wr_en
  .rd_en(FIFO_RD), // input rd_en
  .dout(FIFO_OUT), // output [7 : 0] dout
  .full(), // output full
  .empty(FIFO_V_N) // output empty
);




reg [7:0] led_tmp;

always @ (posedge c48)
begin
  if (h2f_v == 1'b1)
    led_tmp <= h2f;
end

assign Led = led_tmp; 


// IO
io io_inst(
  .CLK(CLK),
  .btn(btn),
  .UartRx(UartRx),
  
  .FIFO_OUT(FIFO_OUT),
  .FIFO_V_N(FIFO_V_N),
  .FIFO_RD(FIFO_RD),
  
  .E(E_IO),
  .WE(CPU_WE),
  .ADDRESS(CPU_ADDRESS),
  .DIN(CPU_DATA_IN),
  .DOUT(DATA_OUT_IO),
  .W_ADDRESS(LOADER_ADDRESS),
  .W_DATA(LOADER_DATA_IN),
  .W_SELECT(BUS_SELECT),
  .W_ENABLE(LOADER_WE),
  .BUS_HOLD(BUS_HOLD),
  .RGB(RGB),
  .LED() //todo
);


// CPU KR580VM80A
reg f1, f2;
reg [3:0] div;
wire RAM_WE_N;

always @ (posedge CLK)
begin
  if (btn[1] == 1'b0)
  begin
    div <= div + 4'b0001;
    f1 <= div[3]; 
    f2 <= ~div[3];
  end 
end

vm80a_core cpu (
  .pin_clk(CLK),
  .pin_f1(f1),
  .pin_f2(f2),
  .pin_reset(~BTN_RST_N),
  .pin_a(CPU_ADDRESS),
  .pin_dout(CPU_DATA_IN),
  .pin_din(DATA_OUT),
  .pin_hold(1'b0),
  .pin_ready(1'b1),
  .pin_int(1'b0),
  .pin_wr_n(RAM_WE_N)
);

assign CPU_WE = ~RAM_WE_N;


video video_inst (
  .CLK(CLK),
  .RAM_ADDRB(RAM_ADDRB),
  .RAM_CLKB(RAM_CLKB),
  .RAM_DOUTB(RAM_DOUTB),
  .RGB(RGB_OUT),
  .TMDS(TMDS),
  .TMDSB(TMDSB)
);
  
endmodule
