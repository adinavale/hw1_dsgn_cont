// Used to check for X's on the output pins
// waits 3 clocks (messages) before checking

class chkx extends uvm_scoreboard;
`uvm_component_utils(chkx)
	uvm_tlm_analysis_fifo#(moutmsg) mo;
	
	moutmsg m;
	integer armcnt;
	
	function new(string name, uvm_component par=null);
		super.new(name,par);
	endfunction : new

	function void build_phase(uvm_phase phase);
		mo=new("pinsmsg",this);
	endfunction : build_phase
	
	task checkx(input reg [7:0] v,string what);
		if( ^v===1'bx) begin
			`uvm_fatal("X_signal",$sformatf("Signal %s contains X",what));
		end
	endtask : checkx;
	
	task run_phase(uvm_phase phase);
		armcnt=3;
		forever begin
			mo.get(m);
			if(armcnt>0) begin
				armcnt-=1;
			end else begin
//				`uvm_info("stuff",$sformatf("%x",m.G),UVM_MEDIUM)
				checkx(m.hsync,"hsync");
				checkx(m.hblank,"hblank");
				checkx(m.vsync,"vsync");
				checkx(m.vblank,"vblank");
				checkx(m.R,"Red (R)");
				checkx(m.G,"Green (G)");
				checkx(m.B,"Blue (B)");
			end
		end
	endtask : run_phase

endclass : chkx
