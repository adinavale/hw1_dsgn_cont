// A simple watch dog timer for the system

typedef struct {
	int cycles;
	string msg;
} Wtmsg;


class WDT extends uvm_scoreboard;
`uvm_component_utils(WDT)
	uvm_analysis_imp#(Wtmsg,WDT) wtmsg;
	uvm_tlm_analysis_fifo#(reg) clkevent;
	
	int cycles;
	string msg;
	Wtmsg min;
	reg cjunk;

	function new(string name, uvm_component par=null);
		super.new(name,par);
	endfunction : new
	
	function void build_phase(uvm_phase phase);
		wtmsg=new("wtmsg",this);
		clkevent=new("clkevent",this);
	endfunction : build_phase

	task run_phase(uvm_phase phase);
		cycles=0;
		msg="empty";
		forever begin
			clkevent.get(cjunk);
			if(cycles <= 0) begin
				cycles=0;
			end else begin
				cycles-=1;
				if(cycles<=0) begin
					`uvm_fatal("Watchdog",msg);
				end
			end
		end
	endtask : run_phase

	function void write(Wtmsg x);
		cycles=x.cycles;
		msg=x.msg;
	endfunction : write

endclass : WDT
