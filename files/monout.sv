// Monitors the outputs of the design

class monout extends uvm_monitor;
`uvm_component_utils(monout)
	uvm_analysis_port#(moutmsg) outmsg;
	
	virtual Vid5I v;
	moutmsg mo;
	
	function new(string name, uvm_component par=null);
		super.new(name,par);
	endfunction : new
	
	function void connect_phase(uvm_phase phase);
		if(!uvm_config_db#(virtual Vid5I)::get(null,"vid5i","vid5i",v)) begin
			`uvm_fatal("interface","Failed to get vid5i")
		end
	endfunction : connect_phase

	function void build_phase(uvm_phase phase);
		outmsg=new("main_mon",this);
	endfunction : build_phase
	
	task run_phase(uvm_phase phase);
		forever begin
			@(posedge(v.clk));
			mo=new();
			mo.hsync=v.hsync;
			mo.hblank=v.hblank;
			mo.vsync=v.vsync;
			mo.vblank=v.vblank;
			mo.R=v.R;
			mo.G=v.G;
			mo.B=v.B;
			outmsg.write(mo);
		end
	endtask : run_phase


endclass : monout
