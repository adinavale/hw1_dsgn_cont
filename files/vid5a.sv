module vid5a(
    input clk,
    input reset,

    input selin,
    input [2:0] cmdin,
    input [1:0] lenin, 
    input [31:0] addrdatain,
    input ackin,
    input enable, //

    output logic [1:0] reqout,
    output logic [1:0] lenout,
    output logic [31:0] addrdataout,
    output logic [2:0] cmdout,
    output logic [3:0] reqtar,

    output logic hsync, //
    output logic hblank, //
    output logic vsync,
    output logic vblank,

    output logic [7:0] R,
    output logic [7:0] G,
    output logic [7:0] B
    );

typedef struct packed {
    logic en;                   //Enable the controller cr[3]
    logic [5:0] pcnt;                 //Pixel divider cr[9:4]
    logic [1:0] vclk;                 //Vertical timing clock source cr[15:14]
} cr; //offset 0x0000

typedef struct packed {
    logic [31:0] h1;              //Address 28
    logic [12:0] hend;          //Hend h1[12:0] - Total number of pixels per horizontal line
    logic [12:0] hsize;         //Hsize h1[25:13] - Number of displayed pixels per horizontal line  
} h1; //offset 0x0028

typedef struct packed {
    logic [12:0] horiz_sync_start; //h2 [25:13] - pixel position of horizontal sync start
    logic [12:0] horiz_sync_end;   //h2 [12:0] - pixel position of horizontal sync end
} h2; //0x0030

typedef struct packed {
    logic [12:0] vend;          //Vend v1[12:0] - Total number of lines per frame
    logic [12:0] vsize;         //Vsize v1[25:13] - Number of displayed lines per frame    
} v1; //0x0038

typedef struct packed {
    logic [12:0] vert_sync_start; //v2[25:13] - line position of vertical sync start
    logic [12:0] vert_sync_end;   //v2[12:0] - line position of vertical sync end
} v2; //0x0040

logic [31:0] base_address;    //Address 0x0048
logic [31:0] lineinc;         //Address 0x0050


initial begin
    reqout = 0;
    lenout = 0;
    addrdataout = 0;
    cmdout = 0;
    reqtar = 0;
    hsync = 0;
    hblank = 0;
    vsync = 0;
    vblank = 0;
    R = 0;
    G = 0;
    B = 0;
end

typedef enum { 
    cr_write,
    regs_write
} program_register_states;

program_register_states prog_st, prog_st_d;

//Register programming sequential block
always_ff @( posedge clk ) begin 
    prog_st <= #1 prog_st_d;
end

always @ (*) begin
    prog_st_d = prog_st;
    case (prog_st)
        cr_write : 
            if (cmdin == 3'b100) begin
                reqout = 2'b11;
                cmdout = 3'b101;
            end

            if (ackin == 1) begin
                prog_st_d = regs_write;
            end
        default : prog_st_d = cr_write;
    endcase
end
endmodule