// fifo_sequences.sv - Sequence definitions for FIFO testbench
`ifndef FIFO_SEQUENCES_SV
`define FIFO_SEQUENCES_SV

class fifo_base_seq extends uvm_sequence #(fifo_item);
  `uvm_object_utils(fifo_base_seq)

  function new(string name = "fifo_base_seq");
    super.new(name);
  endfunction
endclass

class fifo_write_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_write_seq)
  rand int n;

  function new(string name = "fifo_write_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat (n) begin
      `uvm_do_with(req, { wr_en == 1; rd_en == 0; })
    end
  endtask
endclass

class fifo_read_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_read_seq)
  rand int n;

  function new(string name = "fifo_read_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat (n) begin
      `uvm_do_with(req, { wr_en == 0; rd_en == 1; })
    end
  endtask
endclass

class fifo_fill_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_fill_seq)

  function new(string name = "fifo_fill_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat (FIFO_DEPTH) begin
      `uvm_do_with(req, { wr_en == 1; rd_en == 0; })
    end
  endtask
endclass

class fifo_overflow_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_overflow_seq)

  function new(string name = "fifo_overflow_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat (FIFO_DEPTH + 4) begin
      `uvm_do_with(req, { wr_en == 1; rd_en == 0; })
    end
  endtask
endclass

class fifo_underflow_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_underflow_seq)

  function new(string name = "fifo_underflow_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat (5) begin
      `uvm_do_with(req, { wr_en == 0; rd_en == 1; })
    end
  endtask
endclass

class fifo_simul_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_simul_seq)
  rand int n;

  function new(string name = "fifo_simul_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat (n) begin
      `uvm_do_with(req, { wr_en == 1; rd_en == 1; })
    end
  endtask
endclass

class fifo_rand_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_rand_seq)
  rand int n;
  int wr_weight = 50;
  int rd_weight = 50;

  function new(string name = "fifo_rand_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat (n) begin
      `uvm_do_with(req, {
        wr_en dist { 1 := wr_weight, 0 := (100 - wr_weight) };
        rd_en dist { 1 := rd_weight, 0 := (100 - rd_weight) };
      })
    end
  endtask
endclass

class fifo_idle_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_idle_seq)
  rand int n;

  function new(string name = "fifo_idle_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat (n) begin
      `uvm_do_with(req, { wr_en == 0; rd_en == 0; })
    end
  endtask
endclass

`endif
