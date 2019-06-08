`timescale 1ns / 1ps
module selector(
    input CLK,
    input [15:0] ADDRESS,
    input wire [7:0] DATA_IO,
    input wire [7:0] DATA_RAM,
    output wire [7:0] DATA,
    output reg RAM,
    output reg IO,
    output reg COLOR
    );
    
wire [3:0] line = ADDRESS[15:12];
wire cmp = line == 4'b1111;    

always @ (posedge CLK)
begin     
    RAM <= line != 4'hF;      
    IO <= line == 4'hF;
    COLOR <= (line == 4'h9) || (line == 4'hA) || (line == 4'hB);       
end    

assign DATA = (cmp) ? DATA_IO : DATA_RAM;

    
endmodule
