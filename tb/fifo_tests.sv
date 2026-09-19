// fifo_tests.sv - UVM tests for synchronous FIFO
`ifndef FIFO_TESTS_SV
`define FIFO_TESTS_SV

class fifo_base_test extends uvm_test;
  `uvm_component_utils(fifo_base_test)

  fifo_env env;
  virtual fifo_if #(FIFO_WIDTH) vif;

  function new(string name = "fifo_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual fifo_if #(FIFO_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Virtual interface 'vif' not found in config_db")

    env = fifo_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_type_name(), "Topology:", UVM_LOW)
    uvm_top.print_topology();
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask

  task wait_clocks(int n);
    repeat (n) @(posedge vif.clk);
  endtask

endclass

class fifo_smoke_test extends fifo_base_test;
  `uvm_component_utils(fifo_smoke_test)

  function new(string name = "fifo_smoke_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    fifo_write_seq wr_seq;
    fifo_read_seq  rd_seq;

    phase.raise_objection(this);

    wr_seq = fifo_write_seq::type_id::create("wr_seq");
    wr_seq.n = 4;
    wr_seq.start(env.agent.sequencer);

    rd_seq = fifo_read_seq::type_id::create("rd_seq");
    rd_seq.n = 4;
    rd_seq.start(env.agent.sequencer);

    wait_clocks(5);
    phase.drop_objection(this);
  endtask

endclass

class fifo_fill_drain_test extends fifo_base_test;
  `uvm_component_utils(fifo_fill_drain_test)

  function new(string name = "fifo_fill_drain_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    fifo_fill_seq fill_seq;
    fifo_read_seq drain_seq;
    int i;

    phase.raise_objection(this);

    for (i = 0; i < 2; i++) begin
      fill_seq = fifo_fill_seq::type_id::create($sformatf("fill_seq_%0d", i));
      fill_seq.start(env.agent.sequencer);

      drain_seq = fifo_read_seq::type_id::create($sformatf("drain_seq_%0d", i));
      drain_seq.n = FIFO_DEPTH;
      drain_seq.start(env.agent.sequencer);
    end

    wait_clocks(5);
    phase.drop_objection(this);
  endtask

endclass

class fifo_overflow_underflow_test extends fifo_base_test;
  `uvm_component_utils(fifo_overflow_underflow_test)

  function new(string name = "fifo_overflow_underflow_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    fifo_underflow_seq uf_seq;
    fifo_overflow_seq  of_seq;
    fifo_read_seq      drain_seq;

    phase.raise_objection(this);

    uf_seq = fifo_underflow_seq::type_id::create("uf_seq");
    uf_seq.start(env.agent.sequencer);

    of_seq = fifo_overflow_seq::type_id::create("of_seq");
    of_seq.start(env.agent.sequencer);

    drain_seq = fifo_read_seq::type_id::create("drain_seq");
    drain_seq.n = FIFO_DEPTH;
    drain_seq.start(env.agent.sequencer);

    wait_clocks(5);
    phase.drop_objection(this);
  endtask

endclass

class fifo_simul_test extends fifo_base_test;
  `uvm_component_utils(fifo_simul_test)

  function new(string name = "fifo_simul_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    fifo_write_seq  prefill_seq;
    fifo_simul_seq  simul_seq;
    fifo_read_seq   drain_seq;

    phase.raise_objection(this);

    prefill_seq = fifo_write_seq::type_id::create("prefill_seq");
    prefill_seq.n = FIFO_DEPTH / 2;
    prefill_seq.start(env.agent.sequencer);

    simul_seq = fifo_simul_seq::type_id::create("simul_seq");
    simul_seq.n = 50;
    simul_seq.start(env.agent.sequencer);

    drain_seq = fifo_read_seq::type_id::create("drain_seq");
    drain_seq.n = FIFO_DEPTH;
    drain_seq.start(env.agent.sequencer);

    wait_clocks(5);
    phase.drop_objection(this);
  endtask

endclass

class fifo_random_test extends fifo_base_test;
  `uvm_component_utils(fifo_random_test)

  function new(string name = "fifo_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    fifo_rand_seq rand_seq;

    phase.raise_objection(this);

    rand_seq = fifo_rand_seq::type_id::create("rand_seq_balanced");
    rand_seq.n = 3000;
    rand_seq.wr_weight = 50;
    rand_seq.rd_weight = 50;
    rand_seq.start(env.agent.sequencer);

    rand_seq = fifo_rand_seq::type_id::create("rand_seq_full_bias");
    rand_seq.n = 1000;
    rand_seq.wr_weight = 80;
    rand_seq.rd_weight = 20;
    rand_seq.start(env.agent.sequencer);

    rand_seq = fifo_rand_seq::type_id::create("rand_seq_empty_bias");
    rand_seq.n = 1000;
    rand_seq.wr_weight = 20;
    rand_seq.rd_weight = 80;
    rand_seq.start(env.agent.sequencer);

    wait_clocks(5);
    phase.drop_objection(this);
  endtask

endclass

`endif
