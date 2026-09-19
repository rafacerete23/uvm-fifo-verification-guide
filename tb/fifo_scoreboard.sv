// fifo_scoreboard.sv - Reference model and checker for synchronous FIFO
`ifndef FIFO_SCOREBOARD_SV
`define FIFO_SCOREBOARD_SV

`uvm_analysis_imp_decl(_item)
`uvm_analysis_imp_decl(_rst)

class fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fifo_scoreboard)

  uvm_analysis_imp_item #(fifo_item, fifo_scoreboard) imp;
  uvm_analysis_imp_rst  #(bit, fifo_scoreboard) rst_imp;

  bit [FIFO_WIDTH-1:0] q[$];

  int unsigned writes;
  int unsigned reads;
  int unsigned overflow_attempts;
  int unsigned underflow_attempts;
  int unsigned mismatches;

  function new(string name = "fifo_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    imp = new("imp", this);
    rst_imp = new("rst_imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    writes = 0;
    reads = 0;
    overflow_attempts = 0;
    underflow_attempts = 0;
    mismatches = 0;
    q.delete();
  endfunction

  function void write_item(fifo_item item);
    bit do_rd;
    bit do_wr;
    int unsigned sz;

    sz = q.size();

    if (item.full !== (sz == FIFO_DEPTH)) begin
      `uvm_error(get_type_name(), $sformatf("FULL mismatch: item.full=%0b expected=%0b (size=%0d)", item.full, (sz == FIFO_DEPTH), sz))
      mismatches++;
    end
    if (item.empty !== (sz == 0)) begin
      `uvm_error(get_type_name(), $sformatf("EMPTY mismatch: item.empty=%0b expected=%0b (size=%0d)", item.empty, (sz == 0), sz))
      mismatches++;
    end

    if (sz > 0) begin
      if (item.rd_data !== q[0]) begin
        `uvm_error(get_type_name(), $sformatf("RD_DATA mismatch: got=0x%0h expected=0x%0h (size=%0d)", item.rd_data, q[0], sz))
        mismatches++;
      end
    end

    do_rd = item.rd_en && (sz > 0);
    do_wr = item.wr_en && (sz < FIFO_DEPTH);

    if (item.wr_en && (sz == FIFO_DEPTH)) overflow_attempts++;
    if (item.rd_en && (sz == 0)) underflow_attempts++;

    if (do_rd) begin
      void'(q.pop_front());
      reads++;
    end
    if (do_wr) begin
      q.push_back(item.wr_data);
      writes++;
    end
  endfunction

  function void write_rst(bit rst);
    if (rst) begin
      q.delete();
      `uvm_info(get_type_name(), "Reset observed: reference model cleared", UVM_HIGH)
    end
  endfunction

  function void report_phase(uvm_phase phase);
    string status;
    super.report_phase(phase);
    status = (mismatches == 0) ? "PASS" : "FAIL";
    `uvm_info(get_type_name(), $sformatf("\n===== FIFO Scoreboard Summary =====\n  Status            : %s\n  Writes            : %0d\n  Reads             : %0d\n  Overflow attempts : %0d\n  Underflow attempts: %0d\n  Mismatches        : %0d\n===================================", status, writes, reads, overflow_attempts, underflow_attempts, mismatches), UVM_LOW)
  endfunction

endclass

`endif
