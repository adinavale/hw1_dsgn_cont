// This checks the data from the system


class chkdata extends uvm_scoreboard;
`uvm_component_utils(chkdata)

	uvm_tlm_analysis_fifo#(PI) exp;
	uvm_tlm_analysis_fifo#(moutmsg) mchk;
	uvm_analysis_port#(reg) pixelsdone;
	
	PI ev[$];
	PI pi;
	moutmsg m;
	integer dcnt;

	function new(string name,uvm_component par=null);
		super.new(name,par);
	endfunction : new

	function void build_phase(uvm_phase phase);
		exp=new("expected",this);
		mchk=new("chkdata",this);
		pixelsdone=new("pixelsdone",this);
	endfunction : build_phase
	
	task getexp();
		forever begin
			exp.get(pi);
			ev.push_back(pi);
		end
	endtask : getexp
	
	task chk1(reg e,reg r,string name,integer dcnt);
		if(e !== r) begin
			`uvm_error("output",$sformatf("Expected %h got %h on %s (pixel %d)",
				e,r,name,dcnt));
		end
	endtask : chk1

	task chk8(reg [7:0] e,reg [7:0] r,string name,integer dcnt);
		if(e !== r) begin
			`uvm_error("output",$sformatf("Expected %h got %h on %s (pixel %d)",
				e,r,name,dcnt));
		end
	endtask : chk8
	
	
	task checkexp();
		forever begin
			mchk.get(m);
			pi=ev.pop_front();
			chk1(pi.hsync,m.hsync,"hsync",dcnt);
			chk1(pi.hblank,m.hblank,"hblank",dcnt);
			chk1(pi.vblank,m.vblank,"vblank",dcnt);
			chk1(pi.vsync,m.vsync,"vsync",dcnt);
			chk8(pi.R,m.R,"R",dcnt);
			chk8(pi.G,m.G,"G",dcnt);
			chk8(pi.B,m.B,"B",dcnt);
			if(ev.size()==0) begin
				pixelsdone.write(1);
				break;
			end
			dcnt+=1;
		end
	endtask : checkexp
	
	task run_phase(uvm_phase phase);
		dcnt=1;
		fork
			getexp();
			checkexp();
		join_none
	endtask : run_phase


endclass : chkdata

