module fifo (
    input clk,
    input reset_n,
    input write,
    input read,

    input [7:0] data_in,
    output [7:0] data_out,

    output fifo_full, fifo_empty, fifo_threshold, fifo_overflow, fifo_underflow,
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
        .fifo_rd        (fifo_rd),
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
        .fifo_rd        (fifo_rd),
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
    
    output logic [4:0] read_pointer,
    output fifo_re
);

    assign fifo_re = (~fifo_empty) & read;

    always_ff @ (posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            read_pointer <= 0;
        end else if (fifo_re) begin
            read_pointer <= read_pointer + 1;
        end else begin
            read_pointer <= read_pointer;
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
            write_ptr = write_ptr + 1
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
        end else if ( (overflow_set == 1) && (fifo_rd == 0) ) begin
            fifo_overflow <= 1;
        end else if (fifo_rd) begin
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