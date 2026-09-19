// fifo_driver.sv - Driver for FIFO interface
`ifndef FIFO_DRIVER_SV
`define FIFO_DRIVER_SV

class fifo_driver extends uvm_driver #(fifo_item);
  `uvm_component_utils(fifo_driver)

  virtual fifo_if #(FIFO_WIDTH) vif;

  function new(string name = "fifo_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_if #(FIFO_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Virtual interface must be set for: vif")
  endfunction

  virtual task run_phase(uvm_phase phase);
    vif.drv_cb.wr_en <= 0;
    vif.drv_cb.rd_en <= 0;
    vif.drv_cb.wr_data <= 0;

    wait (vif.rst_n === 1'b1);

    forever begin
      seq_item_port.get_next_item(req);
      if (vif.rst_n === 1'b0) begin
        // reset a mitad de trafico: se descarta el item y el bus queda quieto
        vif.drv_cb.wr_en <= 0;
        vif.drv_cb.rd_en <= 0;
        vif.drv_cb.wr_data <= 0;
      end else begin
        vif.drv_cb.wr_en <= req.wr_en;
        vif.drv_cb.rd_en <= req.rd_en;
        vif.drv_cb.wr_data <= req.wr_data;
      end
      @(vif.drv_cb);
      seq_item_port.item_done();
    end
  endtask
endclass

`endif
