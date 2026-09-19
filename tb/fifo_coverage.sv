// fifo_coverage.sv - Functional coverage for synchronous FIFO
`ifndef FIFO_COVERAGE_SV
`define FIFO_COVERAGE_SV

class fifo_coverage extends uvm_subscriber #(fifo_item);
  `uvm_component_utils(fifo_coverage)

  fifo_item tr;

  int unsigned occupancy;

  covergroup fifo_cg;
    option.per_instance = 1;

    cp_wr_en : coverpoint tr.wr_en {
      bins low  = {0};
      bins high = {1};
    }
    cp_rd_en : coverpoint tr.rd_en {
      bins low  = {0};
      bins high = {1};
    }
    cp_full : coverpoint tr.full {
      bins low  = {0};
      bins high = {1};
    }
    cp_empty : coverpoint tr.empty {
      bins low  = {0};
      bins high = {1};
    }

    cross_wr_rd_full_empty : cross cp_wr_en, cp_rd_en, cp_full, cp_empty {
      ignore_bins impossible = binsof(cp_full.high) && binsof(cp_empty.high);
    }

    cp_occupancy : coverpoint occupancy {
      bins empty = {0};
      bins low   = {[1 : FIFO_DEPTH/4]};
      bins mid   = {[FIFO_DEPTH/4 + 1 : 3*FIFO_DEPTH/4]};
      bins high  = {[3*FIFO_DEPTH/4 + 1 : FIFO_DEPTH - 1]};
      bins full  = {FIFO_DEPTH};
    }

    cross_occ_wr_rd : cross cp_occupancy, cp_wr_en, cp_rd_en;
  endgroup

  function new(string name = "fifo_coverage", uvm_component parent = null);
    super.new(name, parent);
    occupancy = 0;
    fifo_cg = new();
  endfunction

  function void write(fifo_item t);
    bit do_rd;
    bit do_wr;
    int unsigned sz;

    tr = t;
    sz = occupancy;

    do_rd = t.rd_en && (sz > 0);
    do_wr = t.wr_en && (sz < FIFO_DEPTH);

    fifo_cg.sample();

    if (do_rd) occupancy--;
    if (do_wr) occupancy++;
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("FIFO coverage = %0.2f%%", fifo_cg.get_coverage()), UVM_LOW)
  endfunction

endclass

`endif
