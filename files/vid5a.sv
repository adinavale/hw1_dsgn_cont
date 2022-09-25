`timescale 1ns / 1ps

module vid5a(
    input clk,
    input reset,

    input selin,
    input [2:0] cmdin,
    input [1:0] lenin, 
    input [31:0] addrdatain,

    output [1:0] reqout,
    output [1:0] lenout,
    output [31:0] addrdataout,
    output [2:0] cmdout,
    output [3:0] reqtar,
    input ackin,
    input enable, //
    
    output hsync, //
    output hblank, //
    output vsync,
    output vblank,

    output [7:0] R,
    output [7:0] G,
    output [7:0] B
    );

   always_ff @(posedge clk) begin
        if(reset) begin
            hsync = 0;
            hblank = 0;
        end
   end
endmodule
