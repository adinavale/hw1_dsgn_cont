// A simple model for the video 5 system
// A very simple controller for video

typedef enum [1:0] {
	MD24,MD32,MD16,MDText
} VMODE;


typedef struct packed {
	reg [5:0] Pclk;
	reg Enable;
	reg CursorEnable;
	VMODE Mode;
} CR0;

typedef struct packed {
	reg [15:0] Curx;
	reg [15:0] Cury;
} CUR0;

typedef struct packed {
	reg [5:0] BlinkRate;
	reg [4:0] CurXsize;
	reg [4:0] CurYsize;
} CUR1;

typedef struct packed {
	reg [31:0] Curfg;
} CURFG;

typedef struct packed {
	reg [31:0] Curbg;
} CURBG;

typedef struct packed {
	reg [12:0] Hsize;
	reg [12:0] Hend;
} H1;

typedef struct packed {
	reg [12:0] HsyncStart;
	reg [12:0] HsyncEnd;
} H2;


