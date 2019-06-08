`timescale 1ns / 1ps
module io(
    input wire CLK,
    input wire [3:1] btn,
    
    input wire [7:0] FIFO_OUT,
    input wire FIFO_V_N,
    output wire FIFO_RD,
    
    input wire UartRx,
    
    input wire E,
    input wire WE,
    input wire [15:0] ADDRESS,
    input wire [7:0] DIN,
    output wire [7:0] LED,
    output wire [7:0] DOUT,
    output wire [2:0] RGB,
    output wire [15:0] W_ADDRESS,
    output wire [7:0] W_DATA,
    output wire W_SELECT,
    output wire W_ENABLE,
    output wire BUS_HOLD
    );

// keyoard
reg [71:0] keyboard;

// 8055 ports    
reg [7:0] PORT_A, PORT_B, PORT_C, PORT_CONTROL;

// RGB value    
reg R, G, B;    

// Address of reg    
wire [1:0] POS = ADDRESS[1:0];    
    
always @ (posedge CLK)
begin
  //LED <= {5'b0, btn};

  if (E == 1'b1 & WE == 1'b1) 
  begin
    if (POS == 2'b00) 
    begin
      PORT_A <= DIN;     
    end  
    else if (POS == 2'b01) 
    begin
      PORT_B <= DIN;     
    end    
    else if (POS == 2'b10) 
    begin
//      LED <= DIN;
      PORT_C <= DIN;
      R <= DIN[7];      
      G <= DIN[6];      
      B <= DIN[4];      
    end    
    else if (POS == 2'b11) 
    begin
      PORT_CONTROL <= DIN;     
    end    

  end
end    


assign RGB = {R, G, B};

// UART (from FIFO)
wire [7:0] uart_data = FIFO_OUT;
wire ready = ~FIFO_V_N;
/*uart uart_inst(
  .CLK(CLK),
  .RX(UartRx),
  .DATA(uart_data),
  .READY(ready)
);
*/

// commands
reg [15:0] write_address;
reg [7:0] write_data;
reg [3:0] write_cnt; 

always @ (posedge CLK)
begin
  if (btn[1] == 1'b0)
  begin

      // key press
      if (ready == 1'b1 && uart_data[7] == 1'b1)
      begin
        keyboard[uart_data[6:0]] <= 1'b0; 
      end 
      // key release
      if (ready == 1'b1 && uart_data[7] == 1'b0)
      begin
        keyboard[uart_data[6:0]] <= 1'b1; 
      end 

  end else begin
  
      // data
      if (ready == 1'b1)
      begin
        write_data <= uart_data;
        write_cnt <= 15; 
      end
  
  end
  
  if (write_cnt == 1)
    write_address <= write_address + 1; 
  
  if (write_cnt != 0)
    write_cnt <= write_cnt - 1; 
end

// keyboard matrix (key64 == HP)
wire PB7 = (keyboard[0] | PORT_C[3]) & (keyboard[1] | PORT_C[2]) & (keyboard[2] | PORT_C[1]) & (keyboard[3] | PORT_C[0]) &
           (keyboard[4] | PORT_A[7]) & (keyboard[5] | PORT_A[6]) & (keyboard[6] | PORT_A[5]) & (keyboard[7] | PORT_A[4]) & 
           (keyboard[8] | PORT_A[3]) & (keyboard[9] | PORT_A[2]) & (keyboard[10] | PORT_A[1]) & (keyboard[11] | PORT_A[0]);    
wire PB6 = (keyboard[12] | PORT_C[3]) & (keyboard[13] | PORT_C[2]) & (keyboard[14] | PORT_C[1]) & (keyboard[15] | PORT_C[0]) &
           (keyboard[16] | PORT_A[7]) & (keyboard[17] | PORT_A[6]) & (keyboard[18] | PORT_A[5]) & (keyboard[19] | PORT_A[4]) & 
           (keyboard[20] | PORT_A[3]) & (keyboard[21] | PORT_A[2]) & (keyboard[22] | PORT_A[1]) & (keyboard[23] | PORT_A[0]);    
wire PB5 = (keyboard[24] | PORT_C[3]) & (keyboard[25] | PORT_C[2]) & (keyboard[26] | PORT_C[1]) & (keyboard[27] | PORT_C[0]) &
           (keyboard[28] | PORT_A[7]) & (keyboard[29] | PORT_A[6]) & (keyboard[30] | PORT_A[5]) & (keyboard[31] | PORT_A[4]) & 
           (keyboard[32] | PORT_A[3]) & (keyboard[33] | PORT_A[2]) & (keyboard[34] | PORT_A[1]) & (keyboard[35] | PORT_A[0]);    
wire PB4 = (keyboard[36] | PORT_C[3]) & (keyboard[37] | PORT_C[2]) & (keyboard[38] | PORT_C[1]) & (keyboard[39] | PORT_C[0]) &
           (keyboard[40] | PORT_A[7]) & (keyboard[41] | PORT_A[6]) & (keyboard[42] | PORT_A[5]) & (keyboard[43] | PORT_A[4]) & 
           (keyboard[44] | PORT_A[3]) & (keyboard[45] | PORT_A[2]) & (keyboard[46] | PORT_A[1]) & (keyboard[47] | PORT_A[0]);    
wire PB3 = (keyboard[48] | PORT_C[3]) & (keyboard[49] | PORT_C[2]) & (keyboard[50] | PORT_C[1]) & (keyboard[51] | PORT_C[0]) &
           (keyboard[52] | PORT_A[7]) & (keyboard[53] | PORT_A[6]) & (keyboard[54] | PORT_A[5]) & (keyboard[55] | PORT_A[4]) & 
           (keyboard[56] | PORT_A[3]) & (keyboard[57] | PORT_A[2]) & (keyboard[58] | PORT_A[1]) & (keyboard[59] | PORT_A[0]);    
wire PB2 = (keyboard[60] | PORT_C[3]) & (keyboard[61] | PORT_C[2]) & (keyboard[62] | PORT_C[1]) & (keyboard[63] | PORT_C[0]) &
           /* (keyboard[64] | PORT_A[7]) & (keyboard[65] | PORT_A[6]) & */ (keyboard[66] | PORT_A[5]) & (keyboard[67] | PORT_A[4]) & 
           (keyboard[68] | PORT_A[3]) & (keyboard[69] | PORT_A[2]) & (keyboard[70] | PORT_A[1]) & (keyboard[71] | PORT_A[0]);    

wire PA0 = (keyboard[11] | PORT_B[7]) & (keyboard[23] | PORT_B[6]) & (keyboard[35] | PORT_B[5]) & (keyboard[47] | PORT_B[4]) & (keyboard[59] | PORT_B[3]) & (keyboard[71] | PORT_B[2]); 
wire PA1 = (keyboard[10] | PORT_B[7]) & (keyboard[22] | PORT_B[6]) & (keyboard[34] | PORT_B[5]) & (keyboard[46] | PORT_B[4]) & (keyboard[58] | PORT_B[3]) & (keyboard[70] | PORT_B[2]); 
wire PA2 = (keyboard[9] | PORT_B[7]) & (keyboard[21] | PORT_B[6]) & (keyboard[33] | PORT_B[5]) & (keyboard[45] | PORT_B[4]) & (keyboard[57] | PORT_B[3]) & (keyboard[69] | PORT_B[2]); 
wire PA3 = (keyboard[8] | PORT_B[7]) & (keyboard[20] | PORT_B[6]) & (keyboard[32] | PORT_B[5]) & (keyboard[44] | PORT_B[4]) & (keyboard[56] | PORT_B[3]) & (keyboard[68] | PORT_B[2]); 
wire PA4 = (keyboard[7] | PORT_B[7]) & (keyboard[19] | PORT_B[6]) & (keyboard[31] | PORT_B[5]) & (keyboard[43] | PORT_B[4]) & (keyboard[55] | PORT_B[3]) & (keyboard[67] | PORT_B[2]); 
wire PA5 = (keyboard[6] | PORT_B[7]) & (keyboard[18] | PORT_B[6]) & (keyboard[30] | PORT_B[5]) & (keyboard[42] | PORT_B[4]) & (keyboard[54] | PORT_B[3]) & (keyboard[66] | PORT_B[2]); 
wire PA6 = (keyboard[5] | PORT_B[7]) & (keyboard[17] | PORT_B[6]) & (keyboard[29] | PORT_B[5]) & (keyboard[41] | PORT_B[4]) & (keyboard[53] | PORT_B[3])/* & (keyboard[65] | PORT_B[2])*/; 
wire PA7 = (keyboard[4] | PORT_B[7]) & (keyboard[16] | PORT_B[6]) & (keyboard[28] | PORT_B[5]) & (keyboard[40] | PORT_B[4]) & (keyboard[52] | PORT_B[3])/* & (keyboard[64] | PORT_B[2])*/; 
wire PC0 = (keyboard[3] | PORT_B[7]) & (keyboard[15] | PORT_B[6]) & (keyboard[27] | PORT_B[5]) & (keyboard[39] | PORT_B[4]) & (keyboard[51] | PORT_B[3]) & (keyboard[63] | PORT_B[2]); 
wire PC1 = (keyboard[2] | PORT_B[7]) & (keyboard[14] | PORT_B[6]) & (keyboard[26] | PORT_B[5]) & (keyboard[38] | PORT_B[4]) & (keyboard[50] | PORT_B[3]) & (keyboard[62] | PORT_B[2]); 
wire PC2 = (keyboard[1] | PORT_B[7]) & (keyboard[13] | PORT_B[6]) & (keyboard[25] | PORT_B[5]) & (keyboard[37] | PORT_B[4]) & (keyboard[49] | PORT_B[3]) & (keyboard[61] | PORT_B[2]); 
wire PC3 = (keyboard[0] | PORT_B[7]) & (keyboard[12] | PORT_B[6]) & (keyboard[24] | PORT_B[5]) & (keyboard[36] | PORT_B[4]) & (keyboard[48] | PORT_B[3]) & (keyboard[60] | PORT_B[2]); 

wire [7:0] PA = {PA7, PA6, PA5, PA4, PA3, PA2, PA1, PA0};
wire [7:0] PB = {PB7, PB6, PB5, PB4, PB3, PB2, keyboard[64], 1'b1}; 
wire [7:0] PC = {4'b0000, PC3, PC2, PC1, PC0};

assign DOUT = (POS == 0) ? PA : ((POS == 1) ? PB : ((POS == 2) ? PC : PORT_CONTROL));
assign W_ADDRESS = write_address;
assign W_DATA = write_data;
assign W_SELECT = write_cnt > 4 & write_cnt < 12; // [3-14]
assign W_ENABLE = write_cnt == 7; 
assign FIFO_RD = write_cnt == 0;

//assign LED = data_16[7:0]; // {7'h0, UartRx};

reg [1:0] pos;
always @ (posedge CLK)
begin
  if (E == 1'b1)
    pos <= ADDRESS[1:0];
end

assign LED = {6'h0, pos};


initial
begin
  write_address <= 16'hFfff;
  keyboard <= 72'hFFFFFFFFFFFFFFFFFF;
end
    
endmodule
