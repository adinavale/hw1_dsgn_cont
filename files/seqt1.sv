// A fun and simple sequence to do some things with the first homework


class seqt1 extends uvm_sequence;
`uvm_object_utils(seqt1);
	SI si;

	
	class tc;
		RI rdef[$];
		MI mdef[$];
		PI pdef[$];
	endclass : tc
	
	tc tcase;
	
	function new(string name="seqt1");
		super.new(name);
	endfunction : new

	task Delay(input int tm);
		start_item(si);
		si.action=delay;
		si.amount=tm;
		finish_item(si);
	endtask : Delay
	
	task ReadTest(string fn);
		string ln;
		integer xx;
		integer fi=$fopen(fn,"r");
		if(fi==0) begin
			`uvm_fatal(fn,"Cannot open test file")
		end
		while(! $feof(fi)) begin
			xx=$fgets(ln,fi);
			case(ln[0])
				"#": ;
				"R": begin
					RI r;
					xx=$sscanf(ln,"%*s %x %x",r.addr,r.dataw);
					tcase.rdef.push_back(r);
				end
				"p": begin
					PI p;
					xx=$sscanf(ln,"%*s %x %x %x %x %x %x %x",
						p.hsync,p.hblank,p.vsync,p.vblank,p.R,
						p.G,p.B);
					tcase.pdef.push_back(p);
				end
				"m": begin
					MI m;
					xx=$sscanf(ln,"%*s %x %x",m.addr,m.dataw);
					tcase.mdef.push_back(m);				
				end
			endcase
		end
		
		$fclose(fi);
	
	endtask : ReadTest
	
	task WriteReg(reg [15:0] addr, reg [31:0] dataw);
		start_item(si);
		si.action=Wreg;
		si.addr=addr;
		si.dataw=dataw;
		finish_item(si);
	endtask : WriteReg
	
	task loadregs();
		RI ri;
		foreach( tcase.rdef [xx]) begin
		  ri=tcase.rdef[xx];
		  if(xx==0) begin
			WriteReg(ri.addr,ri.dataw&(~32'h8));
		  end else begin
			WriteReg(ri.addr,ri.dataw);
		  end
		end
		ri=tcase.rdef[0];
		WriteReg(ri.addr,ri.dataw);
	endtask : loadregs
	
	task loadmem();
		MI mi;
		foreach( tcase.mdef [xx]) begin
			mi=tcase.mdef[xx];
			start_item(si);
			si.action=Lmem;
			si.addr=mi.addr;
			si.dataw=mi.dataw;
			finish_item(si);	
		end
	endtask : loadmem
	
	task setexp();
		PI pi;
		foreach( tcase.pdef [xx]) begin
			pi=tcase.pdef[xx];
			start_item(si);
			si.action=Lexp;
			si.exp=pi;
			finish_item(si);				
		end
	
	endtask : setexp
	
	task waitpixels();
		start_item(si);
		si.action=Wimage;
		si.amount=tcase.pdef.size();
		finish_item(si);					
	endtask : waitpixels

	task body();
		si=new();
		tcase=new();
		Delay(5);
		ReadTest("t1.test");
		
		loadregs();
		loadmem();
		setexp();
		waitpixels();
	endtask : body

endclass : seqt1
