// A simple interface file for the graphics controller

interface Vid5I(input reg clk, input reg reset);
	logic [2:0] cmdin;
	logic [31:0] addrdatain;
	logic selin;
	logic [1:0] lenin;
	logic [2:0] cmdout;
	logic [31:0] addrdataout;
	logic [1:0] lenout;
	logic [1:0] reqout;
	logic [3:0] reqtar;
	logic ackin;
	logic hblank;
	logic hsync;
	logic vblank;
	logic vsync;
	logic [7:0] R,G,B;
	logic interrupt;
	logic enable;
endinterface : Vid5I
