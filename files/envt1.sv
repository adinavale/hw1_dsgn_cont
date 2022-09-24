// test 1 environment
// This does all the work

`include "seqt1.sv"

class envt1 extends uvm_env;
`uvm_component_utils(envt1)
	agentssd assd;
	agentchk achk;
	seqt1 s1;

	function new(string name,uvm_component par=null);
		super.new(name,par);
	endfunction : new

	function void build_phase(uvm_phase phase);
		assd=agentssd::type_id::create("assd",this);
		achk=agentchk::type_id::create("achk",this);
	endfunction : build_phase
	
	function void connect_phase(uvm_phase phase);
		achk.schk.start_checking.connect(assd.d1.start_checking.analysis_export);
		assd.d1.expected.connect(achk.cdata.exp.analysis_export);
		achk.cdata.pixelsdone.connect(assd.d1.pixelsdone.analysis_export);
	endfunction : connect_phase
	
	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		s1=new();
		s1.start(assd.sqr1);
		phase.drop_objection(this);
	endtask : run_phase

endclass : envt1
