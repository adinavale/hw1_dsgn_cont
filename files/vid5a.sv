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
    logic [12:0] hend;          //Hend h1[12:0] - Total number of pixels per horizontal line
    logic [12:0] hsize;         //Hsize h1[25:13] - Number of displayed pixels per horizontal line  
} h1; //offset 0x0028

typedef struct packed {
    logic [12:0] hsync_start; //h2 [25:13] - pixel position of horizontal sync start
    logic [12:0] hsync_end;   //h2 [12:0] - pixel position of horizontal sync end
} h2; //0x0030

typedef struct packed {
    logic [12:0] vend;          //Vend v1[12:0] - Total number of lines per frame
    logic [12:0] vsize;         //Vsize v1[25:13] - Number of displayed lines per frame    
} v1; //0x0038

typedef struct packed {
    logic [12:0] vsync_start; //v2[25:13] - line position of vertical sync start
    logic [12:0] vsync_end;   //v2[12:0] - line position of vertical sync end
} v2; //0x0040

logic [31:0] base_address;    //Address 0x0048
logic [31:0] lineinc;         //Address 0x0050

cr cr_reg;
h1 h1_reg;
h2 h2_reg;
v1 v1_reg;
v2 v2_reg;

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
    cr_reg.en = 0;
end

typedef enum { 
    wr_req,
    regs_wr,
    rgb_fetch,
    rgb_to_fifo,
    idle
} program_register_states;

program_register_states prog_st, prog_st_d;
logic [31:0] addrdatain_d;

//Register programming sequential block
always_ff @( posedge clk ) begin 
    prog_st <= #1 prog_st_d;
end

always @ (*) begin
    prog_st_d = prog_st;
    case (prog_st)
        wr_req : 
            if (cmdin == 3'b100) begin //TB makes write request
                reqout = 2'b11; //Module makes bid for arbiter
                cmdout = 3'b101; //Module makes write response
                prog_st_d = regs_wr; 
                addrdatain_d = addrdatain;
            end

        regs_wr :
            if (cr_reg.en == 1) begin
                prog_st_d = rgb_fetch;
            end else if (addrdatain_d == 0) begin
                cr_reg.en = addrdatain[3];
                cr_reg.pcnt = addrdatain[9:4];
                cr_reg.vclk = addrdatain[15:14];
                prog_st_d = wr_req;
            end else if (addrdatain_d == 32'h00000028) begin
                h1_reg.hend = addrdatain[12:0];
                h1_reg.hsize = addrdatain[25:13];
                prog_st_d = wr_req;
            end else if (addrdatain_d == 32'h00000030) begin
                h2_reg.hsync_start = addrdatain[25:13];
                h2_reg.hsync_end = addrdatain[12:0];
                prog_st_d = wr_req;
            end else if (addrdatain_d == 32'h00000038) begin
                v1_reg.vend = addrdatain[12:0];
                v1_reg.vsize = addrdatain[25:13];
                prog_st_d = wr_req;
            end else if (addrdatain_d == 32'h00000040) begin
                v2_reg.vsync_start = addrdatain[25:13];
                v2_reg.vsync_end = addrdatain[12:0];
                prog_st_d = wr_req;
            end else if (addrdatain_d == 32'h00000048) begin
                base_address = addrdatain;
                prog_st_d = wr_req;
            end else if (addrdatain_d == 32'h00000050) begin
                lineinc = addrdatain;
                prog_st_d = wr_req;
            end else begin
                prog_st_d = wr_req;
            end

        rgb_fetch : 
            if (cmdin == 3'b001) begin //TB makes data phase request
                prog_st_d = rgb_to_fifo;
            end else begin
                cmdout = 3'b010; //Module makes read request
                lenout = 2'b010; //Makes 4 transfers for a request
                addrdataout = base_address; //TODO: UPDATE THIS AS YOU BUILD OUT THE STATE MACHINE!!!!!!!!!!!!!!!!!!!
            end
        rgb_to_fifo :
            cmdout = 3'b101; //Module gives write response to TB
        default : prog_st_d = wr_req;
    endcase
end
endmodule