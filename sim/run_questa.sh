#!/bin/bash
# Corre el testbench UVM con Questa/ModelSim (UVM 1.2 incluido en el simulador).
# NO VERIFICADO en la maquina del autor (no hay simulador UVM comercial disponible allí).
# Uso: bash sim/run_questa.sh <nombre_del_test> [semilla]   (ver tb/*_tests.sv)
# Sale con codigo 1 si el log contiene UVM_ERROR o UVM_FATAL.
set -euo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
TEST=${1:?Indica el test, por ejemplo: fifo_random_test}
SEED=${2:-1}
cd "$HERE/sim"
vlib work
vlog -sv +incdir+"$HERE/tb" "$HERE/rtl/sync_fifo.sv" "$HERE/tb/fifo_sva.sv" "$HERE/tb/fifo_if.sv" "$HERE/tb/fifo_pkg.sv" "$HERE/tb/tb_top.sv"
vsim -c tb_top +UVM_TESTNAME="$TEST" -sv_seed "$SEED" -do "run -all; quit -f" | tee run.log
! grep -Eq "UVM_(ERROR|FATAL) *: *[1-9]" run.log   # resumen de UVM: falla si hay errores
