// a simple top level file for vid5
`timescale 1ns/10ps

`include "intf.svh"

package mejuvm;

import uvm_pkg::*;
`include "msgitems.sv"
`include "wdt.sv"
`include "clkmon.sv"
`include "monout.sv"
`include "chkx.sv"
`include "startchk.sv"
`include "chkdata.sv"

`include "agentchk.sv"
`include "agentssd.sv"
`include "envt1.sv"
`include "test1.sv"

endpackage : mejuvm

import uvm_pkg::*;



module top();
	reg clk,reset;

	Vid5I i0(clk,reset);

	initial begin
		clk=1;
		repeat(5000) #5 clk=~clk;
		$display("Ran out of clocks");
		$finish;
	end
	
	initial begin
		reset=1;
		repeat(3) @(posedge(clk)) #1;
		reset=0;
	end
	
	initial begin
		uvm_config_db#(virtual Vid5I)::set(null,"vid5i","vid5i",i0);
		run_test("test1");
	end
	
	initial begin
		$dumpfile("vid5.vcd");
		$dumpvars(0,top);
	end
	
	vid5a v(.clk(i0.clk),.reset(i0.reset),
		.selin(i0.selin),.cmdin(i0.cmdin),
		.lenin(i0.lenin),.addrdatain(i0.addrdatain),
		.reqout(i0.reqout),.lenout(i0.lenout),.addrdataout(i0.addrdataout),
		.cmdout(i0.cmdout),.reqtar(i0.reqtar),.ackin(i0.ackin),
		.enable(i0.enable),
		.hsync(i0.hsync),.hblank(i0.hblank),
		.vsync(i0.vsync),.vblank(i0.vblank),
		.R(i0.R),.G(i0.G),.B(i0.B) );

endmodule : top

`include "vid5a.sv"
