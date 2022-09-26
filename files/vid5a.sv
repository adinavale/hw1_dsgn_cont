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

  //FIFO registers
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
      data_in = 5;
      read = 0;
      #9 read = 1;
    end

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

  always_ff @ (posedge clk) begin
    if(cmdin == 3'b100) begin //Testbench makes write request
        reqout = 2'b11; //Makes high bid for the bus
    end
  end

    logic [1:0] count = 0;
    logic [1:0] count_d = 0;

  always_ff @ (posedge clk) begin
    if (ackin) begin
        cmdout = 3'b101; //Requests write response from tb
        count_d = count + 1;
        count = count_d;
    end
    if (count_d == 1) begin
        cmdout = 3'b010; //Read request to tb
    end
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

    logic write_ptr, read_ptr;
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