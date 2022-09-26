`timescale 1ns / 1ps

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

  //Registers
  logic [31:0] cr;              //Address 0
    logic en;                   //Enable the controller cr[3]
    logic [5:0] pcnt;                 //Pixel divider cr[9:4]
    logic [1:0] vclk;                 //Vertical timing clock source cr[15:14]

  logic [31:0] h1;              //Address 28
    logic [12:0] hend;          //Hend h1[12:0] - Total number of pixels per horizontal line
    logic [12:0] hsize;         //Hsize h1[25:13] - Number of displayed pixels per horizontal line

  logic [31:0] h2;              //Address 30
    logic [12:0] horiz_sync_start; //h2 [25:13] - pixel position of horizontal sync start
    logic [12:0] horiz_sync_end;   //h2 [12:0] - pixel position of horizontal sync end

  logic [31:0] v1;              //Address 38
    logic [12:0] vend;          //Vend v1[12:0] - Total number of lines per frame
    logic [12:0] vsize;         //Vsize v1[25:13] - Number of displayed lines per frame

  logic [31:0] v2;              //Address 40
    logic [12:0] vert_sync_start; //v2[25:13] - line position of vertical sync start
    logic [12:0] vert_sync_end;   //v2[12:0] - line position of vertical sync end

  logic [31:0] base_address;    //Address 48
  logic [31:0] lineinc;         //Address 50

  always_ff @ (posedge clk) begin
    if (reset) begin
        hsync = 0;
        hblank = 0;
        vsync = 0;
        vblank = 0;
        R = 0;
        G = 0;
        B = 0;
        addrdataout = 0;
    end
  end

  logic [31:0] reg_address;

  always_ff @ (posedge clk) begin
    if (cmdin == 3'b100) begin //Testbench makes write request
        reqout = 2'b11; //Makes high bid for the bus
        reg_address = addrdatain;
    end
    if (cmdin == 3'b001) begin
        if (reg_address == 32'h00000000) begin
            cr = addrdatain;
                en = cr[3]; //Controller enable
                pcnt = cr[9:4]; //Pixel divider
                vclk = cr[15:14]; //Vertical timing clock source
        end
        else if (reg_address == 32'h00000028) begin
            h1 = addrdatain;
                hend = h1[12:0]; 
                hsize = h1[25:13];
        end
        else if (reg_address == 32'h00000030) begin
            h2 = addrdatain;
                horiz_sync_start = h2[25:13];
                horiz_sync_end = h2[12:0];
        end
        else if (reg_address == 32'h00000038) begin
            v1 = addrdatain;
                vend = v1[12:0]; 
                vsize = v1[25:13];
        end
        else if (reg_address == 32'h00000040) begin
            v2 = addrdatain;
                vert_sync_start = v2[25:13];
                vert_sync_end = v2[12:0];
        end
        else if (reg_address == 32'h00000048) begin
            base_address = addrdatain;
        end
        else if (reg_address == 32'h00000050) begin
            lineinc = addrdatain;
        end
    end  
  end

  always_ff @ (posedge clk) begin
    if (ackin) begin
        cmdout = 3'b101; //Requests write response from tb
    end
  end
endmodule

/*//FIFO registers
  logic read;
  logic write;
  logic [7:0] data_in;
  logic [7:0] data_out;
  logic fifo_full, fifo_empty, fifo_threshold, fifo_overflow, fifo_underflow;

  //FIFO instantiation
  fifo red_fifo (
    //Inputs
    .clk            (clk),
    .reset_n        (~reset),
    .write          (write),
    .read           (read),
    .data_in        (data_in),

    //Outputs
    .data_out       (data_out),
    .fifo_full      (fifo_full),
    .fifo_empty     (fifo_empty),
    .fifo_threshold (fifo_threshold),
    .fifo_overflow  (fifo_overflow),
    .fifo_underflow (fifo_underflow)
    );

    initial begin
      #40 write = 1;
      data_in = 1;
      read = 0;
      #9 data_in = 2;
      #9 data_in = 3;
      #9 data_in = 4;
      #9 data_in = 5;
      #9 data_in = 6;
      #9 data_in = 7;
      #9 data_in = 8;
      #9 data_in = 9;
      #9 data_in = 10;
      #9 data_in = 11;
      #9 data_in = 12;
      #9 data_in = 13;
      #9 data_in = 14;
      #9 data_in = 15;
      #9 data_in = 100;
      #9 write = 0;
      #9 read = 1;
      
      #200 write = 1;
      read = 0;
      #9 data_in = 20;
      #9 data_in = 21;
      #9 data_in = 22;
      #9 data_in = 23;
      #9 data_in = 24;
      #9 data_in = 25;
      #9 data_in = 26;
      #9 data_in = 27;
      #9 data_in = 28;
      #9 data_in = 29;
      #9 data_in = 30;
      #9 data_in = 31;
      #9 data_in = 32;
      #9 data_in = 33;
      #9 data_in = 200;
      #9 write = 0;
      #9 read = 1;
    end */

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