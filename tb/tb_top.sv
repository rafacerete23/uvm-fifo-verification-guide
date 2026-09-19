// tb_top.sv - Top-level testbench module for synchronous FIFO
`timescale 1ns/1ps

module tb_top;

  import uvm_pkg::*;
  import fifo_pkg::*;

  logic clk;

  always #5 clk = ~clk;

  initial clk = 0;

  fifo_if #(FIFO_WIDTH) vif(clk);

  sync_fifo #(FIFO_WIDTH, FIFO_DEPTH) dut (
    .clk     (clk),
    .rst_n   (vif.rst_n),
    .wr_en   (vif.wr_en),
    .wr_data (vif.wr_data),
    .full    (vif.full),
    .rd_en   (vif.rd_en),
    .rd_data (vif.rd_data),
    .empty   (vif.empty)
  );

  initial begin
    uvm_config_db#(virtual fifo_if #(FIFO_WIDTH))::set(null, "*", "vif", vif);

    fork
      vif.apply_reset(3);
    join_none

    run_test();
  end

`ifdef WAVES
  initial begin
    $dumpfile("fifo_waves.vcd");
    $dumpvars(0, tb_top);
  end
`endif

endmodule
