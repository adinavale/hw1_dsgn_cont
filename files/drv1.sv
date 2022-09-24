// A simple driver for the version 1 test


class drv1 extends uvm_driver#(SI);
`uvm_component_utils(drv1)
	drv1 d1;
	SI si;
	virtual Vid5I v;
	uvm_analysis_port #(PI) expected;
	uvm_analysis_port #(Wtmsg) wdt;
	uvm_tlm_analysis_fifo#(reg) pixelsdone;
	uvm_tlm_analysis_fifo#(reg) start_checking;
	
	reg [31:0] mem [reg [31:0]];

	function new(string name,uvm_component par=null);
		super.new(name,par);
	endfunction : new
	
	function void connect_phase(uvm_phase phase);
		if(!uvm_config_db#(virtual Vid5I)::get(null,"vid5i","vid5i",v)) begin
			`uvm_fatal("interface","Failed to get vid5i")
		end
	endfunction : connect_phase

	function void build_phase(uvm_phase phase);
		expected=new("expected",this);
		wdt=new("wdt",this);
		pixelsdone=new("pixdone",this);
		start_checking=new("startChecking",this);
	endfunction : build_phase
	
	task clearv();
		v.cmdin=0;
		v.addrdatain=0;
		v.selin=0;
		v.lenin=0;
	endtask : clearv
	
	task GetWresp();
		reg rseen=0;
		while(!rseen) begin
			@(posedge(v.clk)) ;
			if(v.cmdout==5 && v.ackin==1 && v.addrdataout==0) rseen=1;
		end
		#1;
	endtask : GetWresp
	
	task DoWreg(reg [15:0] addr,reg [31:0] dataw);
		v.cmdin=4;
		v.addrdatain=addr;
		v.selin=1;
		v.lenin=0;
		@(posedge(v.clk)) #1;
		v.cmdin=1;
		v.addrdatain=dataw;
		v.selin=1;
		v.lenin=0;
		@(posedge(v.clk)) #1;
		clearv();
		GetWresp();
	endtask : DoWreg 

	task InitIdle();
		v.ackin=0;
		v.selin=0;
		v.cmdin=0;
		v.addrdatain=0;
	
	endtask : InitIdle
	
	task genAck();
		forever @(v.reqout)begin
			if(v.reqout!=0) begin
				v.ackin=1;
			end else begin
				v.ackin=0;
			end
		end
	endtask : genAck
	
	task doWimage(int amt);
		reg rr;
		wdt.write('{amt,"Ran out of clocks waiting for image"});
		start_checking.get(rr);
		wdt.write('{0,"Now checking"});
		pixelsdone.get(rr);
	endtask : doWimage
	
	task sendmemresp(reg [31:0] saddr,reg [1:0] slen);
		reg [5:0] bamt;
		reg [2:0] respcode;
		respcode=3;
		case(slen)
			0: bamt=1;
			1: bamt=4;
			2: bamt=8;
			3: bamt=16;
		endcase

		repeat(bamt) begin
			reg [31:0] dt;
			@(posedge(v.clk)) #1;
			v.cmdin=respcode;
			v.lenin=slen;
			v.selin=1;
			dt=mem[saddr];
			if(^dt===1'bx) begin
				dt=32'hdeadbeef;
			end
			v.addrdatain=dt;
			saddr+=4;
			respcode=1;
		end
		@(posedge(v.clk)) #1;
		v.cmdin=0;
		v.addrdatain=0;
		v.lenin=0;
		v.selin=0;
	endtask : sendmemresp
	
	task procMemRead();
		reg [31:0] saddr;
		reg [1:0] slen;
		forever begin
			@(posedge(v.clk)) ;
			if(v.reqout>0) begin
				case(v.cmdout)
				  2 : begin
					saddr=v.addrdataout;
					slen=v.lenout;
					sendmemresp(saddr,slen);
				  end
				endcase
			end
		end
	endtask : procMemRead

	task run_phase(uvm_phase phase);
		InitIdle();
		fork
			genAck();
			procMemRead();
			forever begin
				seq_item_port.get_next_item(si);
				case(si.action)
					delay : begin
					  repeat(si.amount) begin
						@(posedge(v.clk)) #1;
					  end
					end
					Wreg : begin
						DoWreg(si.addr,si.dataw);
					end
					Lmem : begin
						mem[si.addr]=si.dataw;
					end
					Lexp : begin
						expected.write(si.exp);
					end
					Wimage : begin
						doWimage(si.amount);
					end
				endcase
				seq_item_port.item_done();
			end
		join_none
	endtask : run_phase


endclass : drv1
