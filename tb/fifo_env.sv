// fifo_env.sv - UVM environment for synchronous FIFO
`ifndef FIFO_ENV_SV
`define FIFO_ENV_SV

class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)

  fifo_agent      agent;
  fifo_scoreboard scoreboard;
  fifo_coverage   coverage;

  function new(string name = "fifo_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent      = fifo_agent::type_id::create("agent", this);
    scoreboard = fifo_scoreboard::type_id::create("scoreboard", this);
    coverage   = fifo_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.ap.connect(scoreboard.imp);
    agent.ap.connect(coverage.analysis_export);
    agent.monitor.rst_ap.connect(scoreboard.rst_imp);
  endfunction

endclass

`endif
