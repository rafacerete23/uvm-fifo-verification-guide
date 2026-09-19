// fifo_monitor.sv - Monitor for FIFO interface
`ifndef FIFO_MONITOR_SV
`define FIFO_MONITOR_SV

class fifo_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_monitor)

  virtual fifo_if #(FIFO_WIDTH) vif;
  uvm_analysis_port #(fifo_item) ap;
  uvm_analysis_port #(bit) rst_ap;

  function new(string name = "fifo_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
    rst_ap = new("rst_ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_if #(FIFO_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Virtual interface must be set for: vif")
  endfunction

  virtual task run_phase(uvm_phase phase);
    fifo_item item;
    bit rst_prev = 1'b1;

    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.rst_n === 1'b0) begin
        if (rst_prev !== 1'b0) begin
          rst_ap.write(1'b1);
        end
        rst_prev = 1'b0;
      end else begin
        rst_prev = 1'b1;
        item = fifo_item::type_id::create("item");
        item.wr_en   = vif.mon_cb.wr_en;
        item.rd_en   = vif.mon_cb.rd_en;
        item.wr_data = vif.mon_cb.wr_data;
        item.full    = vif.mon_cb.full;
        item.empty   = vif.mon_cb.empty;
        item.rd_data = vif.mon_cb.rd_data;
        ap.write(item);
      end
    end
  endtask
endclass

`endif
