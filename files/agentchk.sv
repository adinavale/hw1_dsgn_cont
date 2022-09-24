// agent used for some easy checking

class agentchk extends uvm_agent;
`uvm_component_utils(agentchk)
	monout mo;
	chkx ckx;
	startchk schk;
	chkdata cdata;
	
	function new(string name, uvm_component par=null);
		super.new(name,par);
	endfunction : new
	
	function void build_phase(uvm_phase phase);
		mo=monout::type_id::create("Monitor_out",this);
		ckx=chkx::type_id::create("CheckX",this);
		schk=startchk::type_id::create("findstartchk",this);
		cdata=chkdata::type_id::create("checkData",this);
	endfunction : build_phase
	
	function void connect_phase(uvm_phase phase);
		mo.outmsg.connect(ckx.mo.analysis_export);
		mo.outmsg.connect(schk.mo.analysis_export);
		schk.omsg.connect(cdata.mchk.analysis_export);
	endfunction : connect_phase

endclass : agentchk
