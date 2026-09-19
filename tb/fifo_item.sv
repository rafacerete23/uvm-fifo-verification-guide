// fifo_item.sv - Sequence item representing one clock cycle of FIFO activity
`ifndef FIFO_ITEM_SV
`define FIFO_ITEM_SV

class fifo_item extends uvm_sequence_item;
  rand bit wr_en;
  rand bit rd_en;
  rand bit [FIFO_WIDTH-1:0] wr_data;

  bit full;
  bit empty;
  bit [FIFO_WIDTH-1:0] rd_data;

  `uvm_object_utils_begin(fifo_item)
    `uvm_field_int(wr_en, UVM_ALL_ON)
    `uvm_field_int(rd_en, UVM_ALL_ON)
    `uvm_field_int(wr_data, UVM_ALL_ON)
    `uvm_field_int(full, UVM_ALL_ON)
    `uvm_field_int(empty, UVM_ALL_ON)
    `uvm_field_int(rd_data, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "fifo_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("wr_en=%0b rd_en=%0b wr_data=0x%0h full=%0b empty=%0b rd_data=0x%0h",
                     wr_en, rd_en, wr_data, full, empty, rd_data);
  endfunction
endclass

`endif
