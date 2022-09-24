`timescale 1ns / 1ps

module vid5a(
    input clk,
    input reset,

    output selin,
    output [2:0] cmdin,
    output [1:0] lenin, 
    output [31:0] addrdatain,

    input [1:0] reqout,
    input [1:0] lenout,
    input [31:0] addrdataout,
    input [2:0] cmdout,
    output [3:0] reqtar,

    output ackin,
    output enable, //
    output hsync, //
    output hblank, //
    output vsync,
    output vblank,

    input [7:0] R,
    input [7:0] G,
    input [7:0] B
    );

endmodule
