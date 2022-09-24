// A basic clock monitor for the vid5

class CLKMON extends uvm_monitor;
`uvm_component_utils(CLKMON)
	uvm_analysis_port#(reg) clkevent;
	virtual Vid5I v;


	function new(string name, uvm_component par=null);
		super.new(name,par);
	endfunction : new
	
	function void build_phase(uvm_phase phase);
		clkevent=new("clkevent",this);
	endfunction : build_phase
	
	function void connect_phase(uvm_phase phase);
		if(!uvm_config_db#(virtual Vid5I)::get(null,"vid5i","vid5i",v)) begin
			`uvm_fatal("interface","Failed to get vid5i")
		end	
	endfunction : connect_phase
	
	task run_phase(uvm_phase phase);
		forever begin
			@(posedge(v.clk)) clkevent.write(1);
		end
	endtask : run_phase
	
	

endclass : CLKMON
