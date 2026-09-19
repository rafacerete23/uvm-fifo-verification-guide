// fifo_pkg.sv - UVM package for synchronous FIFO testbench
`ifndef FIFO_PKG_SV
`define FIFO_PKG_SV

package fifo_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  parameter int FIFO_WIDTH = 8;
  parameter int FIFO_DEPTH = 16;

  `include "fifo_item.sv"
  `include "fifo_sequences.sv"
  `include "fifo_driver.sv"
  `include "fifo_monitor.sv"
  `include "fifo_scoreboard.sv"
  `include "fifo_coverage.sv"
  `include "fifo_agent.sv"
  `include "fifo_env.sv"
  `include "fifo_tests.sv"

endpackage

`endif
