`timescale 1ns/1ps
module tb_selfcheck;
  logic clk = 0;
  logic rst_n;
  logic wr_en, rd_en;
  logic [7:0] wr_data;
  logic full, empty;
  logic [7:0] rd_data;

  // DUT
  sync_fifo #(8,16) dut (
    .clk(clk), .rst_n(rst_n),
    .wr_en(wr_en), .wr_data(wr_data), .full(full),
    .rd_en(rd_en), .rd_data(rd_data), .empty(empty)
  );

  // Clock: 10ns period
  always #5 clk = ~clk;

  // Reference model
  logic [7:0] q[$];
  int errors = 0;
  int n_cycles = 0, n_writes = 0, n_reads = 0;
  int n_ovf = 0, n_unf = 0, n_simul = 0;
  int err_printed = 0;

  // Watchdog
  initial #50_000_000 begin
    $display("RESULT: FAIL (timeout)");
    $finish;
  end

  // Error helper
  task automatic err_check(input bit cond, input string msg);
    if (!cond) begin
      errors++;
      if (err_printed < 20) begin
        $display("ERROR t=%0t %s", $time, msg);
        err_printed++;
      end
    end
  endtask

  // Single cycle task: drive inputs, wait, check, update model, wait past next posedge
  task automatic cycle(input bit w, input bit r, input logic [7:0] d);
    // Drive inputs 1ns after posedge (we are called right after a posedge)
    #1;
    wr_en = w;
    rd_en = r;
    wr_data = d;
    // Wait until 9ns after posedge (i.e. 8ns more) to check
    #8;
    // Check outputs against model
    err_check(full == (q.size() == 16), "full mismatch");
    err_check(empty == (q.size() == 0), "empty mismatch");
    if (q.size() > 0)
      err_check(rd_data == q[0], "rd_data mismatch");
    // Compute effects
    begin
      bit do_rd = r && (q.size() > 0);
      bit do_wr = w && (q.size() < 16);
      if (r && (q.size() == 0)) n_unf++;
      if (w && (q.size() == 16)) n_ovf++;
      if (r && w) n_simul++;
      if (do_rd) begin
        void'(q.pop_front());
        n_reads++;
      end
      if (do_wr) begin
        q.push_back(d);
        n_writes++;
      end
      n_cycles++;
    end
    // Wait until just after next posedge
    @(posedge clk);
  endtask

  // Reset helper: assert reset for 3 clocks
  task automatic do_reset();
    rst_n = 0;
    wr_en = 0; rd_en = 0; wr_data = 0;
    repeat (3) @(posedge clk);
    #1;
    rst_n = 1;
    q.delete();
  endtask

  // Random seed
  int seed;
  initial seed = $urandom(12345);

  initial begin
    // Initialize
    rst_n = 0;
    wr_en = 0; rd_en = 0; wr_data = 0;

    // Phase 0: reset
    do_reset();

    // Phase 1: read on empty x5
    repeat (5) cycle(0, 1, 8'h00);

    // Phase 2: fill to full then 6 more writes
    for (int i = 0; i < 16; i++) cycle(1, 0, i[7:0]);
    repeat (6) cycle(1, 0, 8'hAA);
    // check full
    err_check(full == 1, "expected full after fill");
    err_check(empty == 0, "expected not empty after fill");

    // Phase 3: drain fully then 5 more reads
    repeat (16) cycle(0, 1, 8'h00);
    repeat (5) cycle(0, 1, 8'h00);
    err_check(empty == 1, "expected empty after drain");

    // Phase 4: fill half then 200 simultaneous r+w
    for (int i = 0; i < 8; i++) cycle(1, 0, i[7:0]);
    for (int i = 0; i < 200; i++) cycle(1, 1, i[7:0]);

    // Phase 5: fill to full then simultaneous r+w for 20 cycles
    while (q.size() < 16) cycle(1, 0, 8'h55);
    repeat (20) cycle(1, 1, 8'h77);

    // Phase 6: drain to empty then simultaneous r+w for 20 cycles
    while (q.size() > 0) cycle(0, 1, 8'h00);
    repeat (20) cycle(1, 1, 8'h33);

    // Phase 7: three random phases of 5000 cycles
    // (50,50)
    for (int i = 0; i < 5000; i++) begin
      bit w = ($urandom_range(0,99) < 50);
      bit r = ($urandom_range(0,99) < 50);
      cycle(w, r, $urandom_range(0,255));
    end
    // (80,20)
    for (int i = 0; i < 5000; i++) begin
      bit w = ($urandom_range(0,99) < 80);
      bit r = ($urandom_range(0,99) < 20);
      cycle(w, r, $urandom_range(0,255));
    end
    // (20,80)
    for (int i = 0; i < 5000; i++) begin
      bit w = ($urandom_range(0,99) < 20);
      bit r = ($urandom_range(0,99) < 80);
      cycle(w, r, $urandom_range(0,255));
    end

    // Phase 8: mid-operation async reset
    for (int i = 0; i < 5; i++) cycle(1, 0, i[7:0]);
    // pulse reset
    rst_n = 0;
    #1;
    q.delete();
    #1;
    rst_n = 1;
    // wait a bit and check
    #1;
    err_check(empty == 1, "expected empty after async reset");
    err_check(full == 0, "expected not full after async reset");
    // one more cycle to confirm
    cycle(0, 0, 8'h00);

    // Summary
    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL (%0d errors)", errors);
    $display("cycles=%0d writes=%0d reads=%0d ovf=%0d unf=%0d simul=%0d",
             n_cycles, n_writes, n_reads, n_ovf, n_unf, n_simul);
    $finish;
  end

endmodule
