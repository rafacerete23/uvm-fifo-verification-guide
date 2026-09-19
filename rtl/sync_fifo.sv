// Synchronous FIFO, first-word-fall-through read.
//  - rd_data always shows the oldest entry while !empty.
//  - A write when full and a read when empty are ignored (no corruption).
//  - Simultaneous read+write is supported (also at full/empty boundaries
//    handled per the rules above: at full, only the read takes effect;
//    at empty, only the write takes effect).
module sync_fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 16          // must be a power of two
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic             wr_en,
  input  logic [WIDTH-1:0] wr_data,
  output logic             full,
  input  logic             rd_en,
  output logic [WIDTH-1:0] rd_data,
  output logic             empty
);
  localparam int AW = $clog2(DEPTH);

  logic [WIDTH-1:0] mem [DEPTH];
  logic [AW:0]      wr_ptr, rd_ptr;     // one extra bit distinguishes full from empty

  assign empty   = (wr_ptr == rd_ptr);
  assign full    = (wr_ptr[AW] != rd_ptr[AW]) && (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]);
  assign rd_data = mem[rd_ptr[AW-1:0]];

  wire do_wr = wr_en && !full;
  wire do_rd = rd_en && !empty;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
    end else begin
      if (do_wr) begin
        mem[wr_ptr[AW-1:0]] <= wr_data;
        wr_ptr <= wr_ptr + 1'b1;
      end
      if (do_rd) rd_ptr <= rd_ptr + 1'b1;
    end
  end
endmodule
