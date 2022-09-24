// Contains a number of message item definitions

	typedef struct packed{
		reg [15:0] addr;
		reg [31:0] dataw;
	} RI;
	typedef struct packed{
		reg [31:0] addr;
		reg [31:0] dataw;
	} MI;
	typedef struct packed{
		reg hsync;
		reg hblank;
		reg vsync;
		reg vblank;
		reg [7:0] R,G,B;
	} PI;

// sequence -> sequencer -> driver message item
typedef enum {
	delay=0,
	Wreg=1,
	Lmem,
	Lexp,
	Wimage
} DRV_ACTIONS;

class SI extends uvm_sequence_item;
	DRV_ACTIONS action;
	int amount;
	reg [31:0] addr;
	reg [31:0] dataw;
	PI exp;

endclass : SI

class moutmsg;
	reg hsync,hblank,vsync,vblank;
	reg [7:0] R,G,B;
endclass : moutmsg
