// A basic first test for the vid5


class test1 extends uvm_test;
`uvm_component_utils(test1)
	envt1 env1;

	function new(string name,uvm_component par=null);
		super.new(name,par);
	endfunction : new

	function void build_phase(uvm_phase phase);
		env1=envt1::type_id::create("env1",this);
	endfunction : build_phase
	
	function void connect_phase(uvm_phase phase);
		
	endfunction : connect_phase
	
	task run_phase(uvm_phase phase);
		uvm_top.print_topology();
		uvm_report_server::get_server().set_max_quit_count(5);
	endtask : run_phase
	
	function void report_phase(uvm_phase phase);
		if(uvm_report_server::get_server().get_severity_count(UVM_ERROR)+
		   uvm_report_server::get_server().get_severity_count(UVM_FATAL)>0) begin
				`uvm_error("Failed (Fix and Try again)","Design had errors, failed the simulation")
		   end
		else begin
			`uvm_info("Passed :-)","Congratulations, you passed the simulation",UVM_LOW)
		end
	endfunction : report_phase

endclass : test1
