`timescale 1ns/1ps

// Fase 10: clase de estimulo constrained-random (rand/constraint/dist)
class fifo_stim;
  rand bit wr_en;
  rand bit rd_en;
  rand bit [7:0] wr_data;
  int wr_weight = 70;
  int rd_weight = 70;
  constraint c_dist {
    wr_en dist {1'b1 := wr_weight, 1'b0 := (100 - wr_weight)};
    rd_en dist {1'b1 := rd_weight, 1'b0 := (100 - rd_weight)};
  }
endclass

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

    // Phase 9: reset asíncrono (dos escenarios)
    // --- A) Reset desde FIFO llena con escrituras durante el reset ---
    while (q.size() < 16) cycle(1, 0, 8'hC0);
    #1;  // dejar pasar el NBA de la ultima escritura antes de comprobar
    err_check(full == 1, "P9A: FIFO deberia estar llena antes del reset");
    // Estamos a +1ns de un posedge. Ir a +4ns (mitad de ciclo, lejos de un flanco) y asertar reset con wr_en=1
    #3;
    wr_en = 1; rd_en = 0; wr_data = 8'hEE; rst_n = 0;
    // Esperar 1ns sin cruzar flanco y comprobar reset asincrono inmediato
    #1;
    err_check(empty == 1, "P9A: empty debe ser 1 inmediatamente tras reset asincrono");
    err_check(full  == 0, "P9A: full debe ser 0 inmediatamente tras reset asincrono");
    // Mantener reset durante 3 posedges con wr_en=1; escrituras ignoradas
    repeat (3) begin
      @(posedge clk);
      #1;
      err_check(empty == 1, "P9A: empty debe seguir 1 durante reset");
      err_check(full  == 0, "P9A: full debe seguir 0 durante reset");
    end
    // Liberar reset 1ns despues de un posedge con wr_en=0
    wr_en = 0; rd_en = 0; wr_data = 8'h00;
    #1;
    rst_n = 1;
    q.delete();
    // Reajustar a posedge para que cycle() quede alineado
    @(posedge clk);
    // Escribir 3 valores conocidos y leerlos
    cycle(1, 0, 8'h11);
    cycle(1, 0, 8'h22);
    cycle(1, 0, 8'h33);
    cycle(0, 1, 8'h00);
    cycle(0, 1, 8'h00);
    cycle(0, 1, 8'h00);
    #1;  // dejar pasar el NBA del ultimo pop antes de comprobar
    err_check(empty == 1, "P9A: FIFO debe quedar vacia tras leer los 3 valores");

    // --- B) Pulso de reset estrictamente entre dos flancos ---
    // Estamos en posedge. Escribir 4 valores
    cycle(1, 0, 8'hA1);
    cycle(1, 0, 8'hA2);
    cycle(1, 0, 8'hA3);
    cycle(1, 0, 8'hA4);
    // Tras el ultimo cycle estamos en posedge; esperar 1ns (evita carrera con el flanco) y poner wr_en=0, rd_en=0
    #1;
    wr_en = 0; rd_en = 0; wr_data = 8'h00;
    // Pulso de reset de 2ns (entre +2ns y +4ns del ciclo), sin flanco de reloj en medio
    #1;
    rst_n = 0;
    #2;
    rst_n = 1;
    q.delete();
    // Comprobar inmediatamente (antes del siguiente flanco)
    #1;
    err_check(empty == 1, "P9B: empty debe ser 1 tras pulso de reset entre flancos");
    err_check(full  == 0, "P9B: full debe ser 0 tras pulso de reset entre flancos");
    // Reajustar a posedge
    @(posedge clk);
    // Confirmar con un ciclo nulo
    cycle(0, 0, 8'h00);
    // Confirmar que la FIFO funciona tras el reset
    cycle(1, 0, 8'h5A);
    cycle(0, 1, 8'h00);
    #1;  // dejar pasar el NBA del ultimo pop antes de comprobar
    err_check(empty == 1, "P9B: FIFO debe quedar vacia tras escribir y leer 8'h5A");

    // Fase 10: constrained-random con dist real (rand/constraint/dist)
    begin
      fifo_stim stim = new();
      int pesos_wr [4] = '{70, 90, 30, 50};
      int pesos_rd [4] = '{70, 30, 90, 50};
      for (int b = 0; b < 4; b++) begin
        stim.wr_weight = pesos_wr[b];
        stim.rd_weight = pesos_rd[b];
        for (int i = 0; i < 1000; i++) begin
          void'(stim.randomize());
          cycle(stim.wr_en, stim.rd_en, stim.wr_data);
        end
      end
      $display("Fase 10: constrained-random dist, 4000 ciclos (4x1000), pesos wr/rd = 70/70, 90/30, 30/90, 50/50");
    end

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
