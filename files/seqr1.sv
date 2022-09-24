// A simple sequencer for the first test

class seqr1 extends uvm_sequencer#(SI);
`uvm_component_utils(seqr1)

	function new(string name, uvm_component par=null);
		super.new(name,par);
	endfunction : new


endclass : seqr1
