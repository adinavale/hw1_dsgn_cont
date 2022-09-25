`timescale 1ns / 1ps

module vid5a(
    input clk,
    input reset,

    input selin,
    input [2:0] cmdin,
    input [1:0] lenin, 
    input [31:0] addrdatain,
    input ackin,
    input enable, //

    output logic [1:0] reqout,
    output logic [1:0] lenout,
    output logic [31:0] addrdataout,
    output logic [2:0] cmdout,
    output logic [3:0] reqtar,

    output logic hsync, //
    output logic hblank, //
    output logic vsync,
    output logic vblank,

    output logic [7:0] R,
    output logic [7:0] G,
    output logic [7:0] B
    );

  always_ff @ (posedge clk) begin
    if (reset) begin
        hsync = 0;
        hblank = 0;
        vsync = 0;
        vblank = 0;
        R = 0;
        G = 0;
        B = 0;
        addrdataout = 0;
    end
  end

  always_ff @ (posedge clk) begin
    if(cmdin == 3'b100) begin //Testbench makes write request
        reqout = 2'b11; //Makes high bid for the bus
    end
  end

    logic [1:0] count = 0;
    logic [1:0] count_d = 0;

  always_ff @ (posedge clk) begin
    if (ackin) begin
        cmdout = 3'b101; //Requests write response from tb
        count_d = count + 1;
        count = count_d;
    end
    if (count_d == 1) begin
        cmdout = 3'b010; //Read request to tb
    end
  end
endmodule
