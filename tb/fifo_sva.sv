// fifo_sva.sv - Aserciones SVA y cobertura para sync_fifo (se conecta con bind)
`ifndef FIFO_SVA_SV
`define FIFO_SVA_SV

module fifo_sva #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 16
) (
  input logic                     clk,
  input logic                     rst_n,
  input logic                     wr_en,
  input logic [WIDTH-1:0]         wr_data,
  input logic                     full,
  input logic                     rd_en,
  input logic [WIDTH-1:0]         rd_data,
  input logic                     empty,
  input logic [$clog2(DEPTH):0]   wr_ptr,
  input logic [$clog2(DEPTH):0]   rd_ptr
);

  localparam int AW = $clog2(DEPTH);

  default clocking cb @(posedge clk);
  endclocking

  // Nunca lleno y vacio a la vez
  a_never_full_empty: assert property (disable iff (!rst_n) !(full && empty));

  // Tras el reset: vacio y no lleno
  a_after_reset: assert property ($rose(rst_n) |-> (empty === 1'b1) && (full === 1'b0));

  // Coherencia flags <-> punteros (bit extra distingue lleno de vacio)
  a_empty_ptrs: assert property (disable iff (!rst_n) empty === (wr_ptr == rd_ptr));
  a_full_ptrs:  assert property (disable iff (!rst_n)
    full === ((wr_ptr[AW] != rd_ptr[AW]) && (wr_ptr[AW-1:0] == rd_ptr[AW-1:0])));

  // Escritura con FIFO llena: el puntero de escritura no avanza
  a_no_overflow: assert property (disable iff (!rst_n) (full && wr_en) |=> $stable(wr_ptr));

  // Lectura con FIFO vacia: el puntero de lectura no avanza
  a_no_underflow: assert property (disable iff (!rst_n) (empty && rd_en) |=> $stable(rd_ptr));

  // Sin lectura y con datos, rd_data no cambia
  a_rd_data_stable: assert property (disable iff (!rst_n) (!empty && !rd_en) |=> $stable(rd_data));

  // Cobertura
  c_fill_to_full:   cover property (disable iff (!rst_n) empty ##[1:$] full);
  c_drain_to_empty: cover property (disable iff (!rst_n) full ##[1:$] empty);
  c_simul_rd_wr:    cover property (disable iff (!rst_n) wr_en && rd_en && !full && !empty);
  c_wr_when_full:   cover property (disable iff (!rst_n) full && wr_en);
  c_rd_when_empty:  cover property (disable iff (!rst_n) empty && rd_en);

endmodule

bind sync_fifo fifo_sva #(.WIDTH(WIDTH), .DEPTH(DEPTH)) fifo_sva_inst (.*);

`endif
