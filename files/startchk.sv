// Used to find when to start checking the results
// It is after vblank is high, and then vblank and hblank go low

class startchk extends uvm_scoreboard;
`uvm_component_utils(startchk)

	uvm_tlm_analysis_fifo#(moutmsg) mo;
	uvm_analysis_port#(moutmsg) omsg;
	uvm_analysis_port#(reg) start_checking;
	
	moutmsg m;

	function new(string name, uvm_component par=null);
		super.new(name,par);
	endfunction : new
	
	function void build_phase(uvm_phase phase);
		mo=new("schkdin",this);
		omsg=new("dstream",this);
		start_checking=new("start_checking",this);
	endfunction : build_phase
	
	task run_phase(uvm_phase phase);
		forever begin
			mo.get(m);
			if(m.vblank==1) begin
				break;
			end
		end
		forever begin
			mo.get(m);
			if(m.vblank==0 && m.hblank==0) break;
		end
		start_checking.write(1);
		omsg.write(m);
		forever begin
			mo.get(m);
			omsg.write(m);
		end
	endtask : run_phase
	


endclass : startchk
