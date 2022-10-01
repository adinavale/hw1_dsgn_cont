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

typedef struct packed {
    logic [7:0] data_in;
    logic [7:0] data_out;
} f; //FIFO regs

f f_reg_red, f_reg_green, f_reg_blue;
logic write_to_fifo;
logic read_from_fifo;

logic [31:0] addrdatain_d;
logic data_pres;

typedef struct packed {
    logic [10:0] counter;
    logic [10:0] counter_d;
    logic [31:0] Pptr; //Pixel pointer
    logic [3:0] PC; //Pixel counter. Range 0 to 4.
    logic [4:0] HC; //Horiz_counter. Range 0 to 14. Increments when PC = 0.
    logic [2:0] Xcnt; //Disp pixel counter. Range 0 to 7. Increments when PC = 0 and Xcnt = 7.
    logic [3:0] Vcnt; //Vertical count. Range 0 to 9. Increments @ hysnc posedge
} cnt;

cnt cnt_reg;

typedef enum { 
    wr_req,         //0
    regs_wr,        //1
    tb_idle,        //2
    rgb_fetch,      //3
    tb_rd_resp,     //4
    reg_to_fifo,    //5
    idle            //6
} program_register_states;

program_register_states df_st, df_st_d;

typedef enum { 
    fifo_idle,      //0
    push_fifo       //1
} receiving_data_state;

receiving_data_state rd_st, rd_st_d;

typedef enum { 
    sd_idle,        //0
    rgb_out         //1
} send_data_states;

send_data_states sd_st, sd_st_d;
    
typedef enum {
    disp_pixels,
    front_porch,
    hsync_high,
    back_porch
 } clocking_states;

clocking_states cs_st, cs_st_d;

fifo red_fifo (
    .clk            (clk),
    .reset_n        (~reset),
    .write          (write_to_fifo),
    .read           (read_from_fifo),
    .data_in        (f_reg_red.data_in),
    .data_out       (f_reg_red.data_out),
    .fifo_full      (),
    .fifo_empty     (),
    .fifo_threshold (),
    .fifo_overflow  (),
    .fifo_underflow ()
    );

    fifo green_fifo (
    .clk            (clk),
    .reset_n        (~reset),
    .write          (write_to_fifo),
    .read           (read_from_fifo),
    .data_in        (f_reg_green.data_in),
    .data_out       (f_reg_green.data_out),
    .fifo_full      (),
    .fifo_empty     (),
    .fifo_threshold (),
    .fifo_overflow  (),
    .fifo_underflow ()
    );

    fifo blue_fifo (
    .clk            (clk),
    .reset_n        (~reset),
    .write          (write_to_fifo),
    .read           (read_from_fifo),
    .data_in        (f_reg_blue.data_in),
    .data_out       (f_reg_blue.data_out),
    .fifo_full      (),
    .fifo_empty     (),
    .fifo_threshold (),
    .fifo_overflow  (),
    .fifo_underflow ()
    );

initial begin
    reqout = 0;
    lenout = 0;
    addrdataout = 0;
    cmdout = 0;
    reqtar = 0;
    hsync = 0;
    hblank = 1;
    vsync = 0;
    vblank = 0;
    R = 0;
    G = 0;
    B = 0;
end

//Data fetch state machine
always_ff @(posedge clk) begin 
    df_st <= #1 df_st_d;
end

always @ (*) begin
    df_st_d = df_st;
    case (df_st)
        wr_req : 
            if (cmdin == 3'b100) begin //TB makes write request
                reqout = 2'b11; //Module makes bid for arbiter
                cmdout = 3'b101; //Module makes write response
                df_st_d = regs_wr; 
                addrdatain_d = addrdatain;
            end

        regs_wr :
            if (cr_reg.en == 1) begin
                df_st_d = tb_idle;
            end else if (addrdatain_d == 0 && cmdin == 3'b001) begin
                cr_reg.en = addrdatain[3];
                cr_reg.pcnt = addrdatain[9:4];
                cr_reg.vclk = addrdatain[15:14];
                df_st_d = wr_req;
            end else if (addrdatain_d == 32'h00000028 && cmdin == 3'b001) begin
                h1_reg.hend = addrdatain[12:0];
                h1_reg.hsize = addrdatain[25:13];
                df_st_d = wr_req;
            end else if (addrdatain_d == 32'h00000030 && cmdin == 3'b001) begin
                h2_reg.hsync_start = addrdatain[25:13];
                h2_reg.hsync_end = addrdatain[12:0];
                df_st_d = wr_req;
            end else if (addrdatain_d == 32'h00000038 && cmdin == 3'b001) begin
                v1_reg.vend = addrdatain[12:0];
                v1_reg.vsize = addrdatain[25:13];
                df_st_d = wr_req;
            end else if (addrdatain_d == 32'h00000040 && cmdin == 3'b001) begin
                v2_reg.vsync_start = addrdatain[25:13];
                v2_reg.vsync_end = addrdatain[12:0];
                df_st_d = wr_req;
            end else if (addrdatain_d == 32'h00000048 && cmdin == 3'b001) begin
                base_address = addrdatain;
                df_st_d = wr_req;
            end else if (addrdatain_d == 32'h00000050 && cmdin == 3'b001) begin
                lineinc = addrdatain;
                df_st_d = wr_req;
            end else begin
                df_st_d = wr_req;
            end
        tb_idle :
            if (cmdin == 3'b000) begin
                df_st_d = rgb_fetch;
            end
        rgb_fetch : 
            if (cmdin == 3'b000) begin //TB makes data phase request
                df_st_d = tb_rd_resp;
                cmdout = 3'b010; //Module makes read request
                lenout = 2'b10; //Makes 4 transfers for a request
                addrdataout = base_address; //TODO: UPDATE THIS AS YOU BUILD OUT THE STATE MACHINE!!!!!!!!!!!!!!!!!!!
            end 

        tb_rd_resp :
            begin
                df_st_d = reg_to_fifo;
                cmdout = 3'b101; //Module gives write response to TB
            end
        reg_to_fifo :
            if ( (cmdin == 3'b011) || (cmdin == 3'b001) ) begin
                data_pres = 1; //Data is ready to be pushed to fifo
            end else begin
                data_pres = 0;
                df_st_d = tb_idle;
            end
        default : df_st_d = wr_req;
    endcase
end

logic [31:0] data_to_fifo;

//Receiving data state machine
always_ff @ (posedge clk) begin
    rd_st <= #1 rd_st_d;
    data_to_fifo <= addrdatain;
end

always @ (*) begin
    rd_st_d = rd_st;
    case (rd_st) 
        fifo_idle : 
            if (data_pres) begin
                rd_st_d = push_fifo;
            end
        push_fifo :
            if (!data_pres) begin
                rd_st_d = fifo_idle;
                write_to_fifo = 0;
            end else begin
                write_to_fifo = 1;
                f_reg_red.data_in = data_to_fifo[25:16];
                f_reg_green.data_in = data_to_fifo[15:8];
                f_reg_blue.data_in = data_to_fifo[7:0];
            end
    endcase
end

//Sending data state machine
always_ff @ (posedge clk) begin
    sd_st <= #1 sd_st_d;
end

always @ (*) begin
    sd_st_d = sd_st;

    case (sd_st)
        sd_idle : 
            if (!hblank) begin
                sd_st_d = rgb_out;
            end
        rgb_out :
            if (hblank) begin
                sd_st_d = sd_idle;
            end
    endcase
end

//Pixel counter state machine
always_ff @ (posedge clk) begin
    if (reset) begin
        cnt_reg <= 0;
    end else begin
        cs_st <= #1 cs_st_d;
        cnt_reg.counter <= cnt_reg.counter_d + 1;
    end
end

/*always @ (*) begin
    cs_st_d = cs_st;

    case (cs_st)
        pcnt_inc : 
    endcase
end */

//outputs
logic [10:0]    clk_count;
logic [10:0]    clk_count_d;
logic [31:0]    Ppter_count;
logic [3:0]     PC_count;
logic [4:0]     HC_count;
logic [2:0]     Xcnt_count;
logic [3:0]     Vcnt_count;

 always @ (*) begin
    clk_count = cnt_reg.counter;
    clk_count_d = cnt_reg.counter_d;
    Ppter_count = cnt_reg.Pptr;
    PC_count = cnt_reg.PC;
    HC_count = cnt_reg.HC;
    Xcnt_count = cnt_reg.Xcnt;
    Vcnt_count = cnt_reg.Vcnt;
 end

endmodule































module fifo (
    input clk,
    input reset_n,
    input write,
    input read,
    input [7:0] data_in,

    output [7:0] data_out,
    output fifo_full, fifo_empty, fifo_threshold, fifo_overflow, fifo_underflow
);

    logic [4:0] write_ptr, read_ptr;
    logic fifo_we, fifo_re;

    write_pointer write_inst (
        .write_ptr      (write_ptr),
        .fifo_we        (fifo_we),
        .write          (write),
        .fifo_full      (fifo_full),
        .clk            (clk),
        .reset_n        (reset_n)
    );

    read_pointer read_inst (
        .read_ptr       (read_ptr),
        .fifo_re        (fifo_re),
        .read           (read),
        .fifo_empty     (fifo_empty),
        .clk            (clk),
        .reset_n        (reset_n)
    );

    storage storage_inst (
        .data_out       (data_out),
        .data_in        (data_in),
        .clk            (clk),
        .fifo_we        (fifo_we),
        .write_ptr      (write_ptr),
        .read_ptr       (read_ptr)
    );

    status_signals status_signals_inst (
        .fifo_full      (fifo_full),
        .fifo_empty     (fifo_empty),
        .fifo_threshold (fifo_threshold),
        .fifo_overflow  (fifo_overflow),
        .fifo_underflow (fifo_underflow),
        .write          (write),
        .read           (read),
        .fifo_we        (fifo_we),
        .fifo_re        (fifo_re),
        .write_ptr      (write_ptr),
        .read_ptr       (read_ptr),
        .clk            (clk),
        .reset_n        (reset_n)
    );
endmodule

module storage (
    input clk,
    input fifo_we,
    input [4:0] write_ptr, read_ptr,
    input [7:0] data_in,

    output logic [7:0] data_out
);

    logic [7:0] storage_array [15:0];

    always_ff @(posedge clk) begin
        if (fifo_we) begin
            storage_array[write_ptr[3:0]] = data_in;
        end
    end

    assign data_out = storage_array[read_ptr[3:0]];
endmodule

module read_pointer (
    input clk,
    input reset_n,

    input read,
    input fifo_empty,
    
    output logic [4:0] read_ptr,
    output fifo_re
);

    assign fifo_re = (~fifo_empty) & read;

    always_ff @ (posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            read_ptr <= 0;
        end else if (fifo_re) begin
            read_ptr <= read_ptr + 1;
        end else begin
            read_ptr <= read_ptr;
        end
    end
endmodule

module write_pointer (
    input clk,
    input reset_n,

    input write,
    input fifo_full,

    output logic [4:0] write_ptr,
    output fifo_we
);

    assign fifo_we = (~fifo_full) & write;

    always_ff @( posedge clk or negedge reset_n ) begin
        if (~reset_n) begin
            write_ptr <= 0;
        end else if (fifo_we) begin
            write_ptr = write_ptr + 1;
        end else begin
            write_ptr <= write_ptr;
        end
    end
endmodule

module status_signals (
    input clk,
    input reset_n,

    input write, read,
    input fifo_we, fifo_re,

    input [4:0] write_ptr, read_ptr,

    output logic fifo_full, fifo_empty, fifo_threshold, fifo_overflow, fifo_underflow
);

    logic fbit_comp, overflow_set, underflow_set;
    logic pointer_equal;
    logic [4:0] pointer_result;

    assign fbit_comp = write_ptr[4] ^ read_ptr[4];
    assign pointer_equal = (write_ptr) ? 0 : 1;
    assign pointer_result = write_ptr - read_ptr;
    assign overflow_set = fifo_full & write;
    assign underflow_set = fifo_empty & read;

    always @ (*) begin
        fifo_full = fbit_comp & pointer_equal;
        fifo_empty = (~fbit_comp) & pointer_equal;
        fifo_threshold = (pointer_result[4] || pointer_result [3]) ? 1 : 0;
    end

    always_ff @ (posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            fifo_overflow <= 0;
        end else if ( (overflow_set == 1) && (fifo_re == 0) ) begin
            fifo_overflow <= 1;
        end else if (fifo_re) begin
            fifo_overflow <= 0;
        end else begin
            fifo_overflow <= fifo_overflow;
        end
    end

    always_ff @ (posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            fifo_underflow <= 0;
        end else if ( (underflow_set == 1) && (fifo_we == 0) ) begin
            fifo_underflow <= 1;
        end else if (fifo_we) begin
            fifo_underflow <= 0;
        end else begin
            fifo_underflow <= fifo_underflow;
        end
    end
endmodule