// fifo_agent.sv - UVM agent for synchronous FIFO
`ifndef FIFO_AGENT_SV
`define FIFO_AGENT_SV

typedef uvm_sequencer #(fifo_item) fifo_sequencer;

class fifo_agent extends uvm_agent;
  `uvm_component_utils(fifo_agent)

  fifo_sequencer sequencer;
  fifo_driver    driver;
  fifo_monitor   monitor;

  uvm_analysis_port #(fifo_item) ap;

  virtual fifo_if #(FIFO_WIDTH) vif;

  function new(string name = "fifo_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual fifo_if #(FIFO_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Virtual interface 'vif' not found in config_db")

    ap = new("ap", this);

    monitor = fifo_monitor::type_id::create("monitor", this);

    if (get_is_active() == UVM_ACTIVE) begin
      sequencer = fifo_sequencer::type_id::create("sequencer", this);
      driver    = fifo_driver::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
    monitor.ap.connect(ap);
  endfunction

endclass

`endif
