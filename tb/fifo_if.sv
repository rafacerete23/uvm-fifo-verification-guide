// fifo_if.sv - Interface for synchronous FIFO with clocking blocks and reset task
`ifndef FIFO_IF_SV
`define FIFO_IF_SV

interface fifo_if #(int WIDTH = 8) (input logic clk);
  logic rst_n;
  logic wr_en;
  logic rd_en;
  logic full;
  logic empty;
  logic [WIDTH-1:0] wr_data;
  logic [WIDTH-1:0] rd_data;

  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output wr_en, wr_data, rd_en;
    input full, empty, rd_data;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input wr_en, wr_data, rd_en, full, empty, rd_data, rst_n;
  endclocking

  task apply_reset(int cycles);
    rst_n = 0;
    wr_en = 0;
    rd_en = 0;
    wr_data = 0;
    repeat (cycles) @(posedge clk);
    rst_n = 1;
  endtask
endinterface

`endif
