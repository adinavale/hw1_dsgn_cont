`timescale 1ns / 1ps

module vid5a(
    input clk,
    input reset,
    input selin,
    input cmdin,
    input lenin,
    input addrdatain,

    output reqout,
    output lenout,
    output addrdataout,
    output cmdout,
    output reqtar,

    input ackin,
    input enable,
    input hsync,
    input hblank,
    input vsync,
    input vblank,

    output R,
    output G,
    output B
    );
endmodule
