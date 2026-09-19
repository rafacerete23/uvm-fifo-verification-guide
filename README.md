# UVM FIFO Verification Guide

Aprende a verificar una FIFO síncrona con un testbench UVM, paso a paso y sin magia.

---

## Qué aprenderás

- Cómo modelar un **DUT** sencillo (una FIFO síncrona con punteros de un bit extra) y qué significa *first-word-fall-through*.
- Cómo estructurar un **testbench UVM** completo: interface, item, sequences, driver, monitor, scoreboard, coverage, agent, env y tests.
- Cómo escribir un **scoreboard** con un modelo de referencia (una cola de SystemVerilog) y comparar flags `full`/`empty` y el dato de cabeza.
- Cómo medir **cobertura funcional** con covergroups (combinaciones de `wr_en`/`rd_en`/`full`/`empty` y bins de ocupación).
- Cómo distinguir entre **verificar el RTL** y **verificar el testbench**: qué se probó de verdad y qué quedó pendiente.

---

## Estructura del repositorio

```
uvm-fifo-verification-guide/
├── rtl/
│   └── sync_fifo.sv          # DUT: FIFO síncrona, WIDTH=8, DEPTH=16, FWFT, reset asíncrono activo en bajo
├── tb/
│   ├── fifo_if.sv            # Interface con clocking blocks drv_cb y mon_cb, y task apply_reset
│   ├── fifo_item.sv          # Un item = un ciclo de reloj: wr_en, rd_en, wr_data + full, empty, rd_data observados
│   ├── fifo_sequences.sv     # Secuencias: write, read, fill, overflow, underflow, simultaneous, random con pesos, idle
│   ├── fifo_driver.sv        # Conduce los items hacia la interface en drv_cb
│   ├── fifo_monitor.sv       # Muestrea cada ciclo; expone ap (items) y rst_ap (reset)
│   ├── fifo_scoreboard.sv    # Modelo de referencia (cola SV): chequea flags, dato FWFT y cuenta intentos de overflow/underflow
│   ├── fifo_coverage.sv      # Covergroups: wr_en x rd_en x full x empty, y bins de ocupación
│   ├── fifo_agent.sv         # Agrupa driver + monitor + sequencer
│   ├── fifo_env.sv           # Agrupa agent + scoreboard + coverage
│   ├── fifo_tests.sv         # Tests: smoke, fill_drain, overflow_underflow, simul, random
│   ├── fifo_pkg.sv           # Paquete UVM que importa y compila todo el testbench
│   ├── tb_top.sv             # Top: reloj 100 MHz, instancia del DUT, interface y run_test()
│   └── selfcheck_tb.sv       # Testbench plano en SystemVerilog con modelo de referencia independiente (para Verilator); incluye la Fase 9 (reset asíncrono)
├── sim/
│   ├── run_selfcheck.sh      # Corre el self-check con Verilator 5
│   └── run_questa.sh         # Corre un test UVM con Questa
├── docs/
│   └── index.html            # Guía didáctica web (ábrela en el navegador)
└── README.md
```

---

## Cómo ejecutarlo

### Opción A: self-check con Verilator (recomendado para empezar)

Requiere **Verilator 5**.

```bash
bash sim/run_selfcheck.sh
```

### Opción B: UVM con Questa

```bash
bash sim/run_questa.sh fifo_random_test
```

### Opción C: otros simuladores comerciales (VCS / Xcelium)

Usa la misma lista de archivos:

```
rtl/sync_fifo.sv tb/fifo_if.sv tb/fifo_pkg.sv tb/tb_top.sv
```

con los flags `+incdir+tb` y `+UVM_TESTNAME=<test>`.

---

## Estado de verificación

> **Importante:** aquí se dice exactamente qué se verificó y qué no. Nada de "todo pasa" sin evidencia.

**RTL verificado con Verilator 5.052** usando `tb/selfcheck_tb.sv` (SystemVerilog plano, con modelo de referencia independiente):

- **RESULT: PASS** sobre **15,354 ciclos**.
- **5,310 escrituras**, **5,274 lecturas**, **4,997 intentos de overflow**, **11 intentos de underflow** (aleatorios más dirigidos), **5,240 ciclos de lectura y escritura simultáneas**.
- **Mutation check:** se inyectaron 3 bugs deliberados en el RTL (escribir cuando está llena, flag `empty` incorrecto, leer cuando está vacía) y **los 3 fueron detectados (FAIL)**. Además, desde la Fase 9 (reset asíncrono) un cuarto mutante —reset síncrono, probado en una copia temporal— también da **FAIL** (7 errores).

**Testbench UVM:**

- **Sí** parsea, elabora y construye toda su topología de componentes contra la librería **Accellera UVM 2020.3.1** bajo **Verilator 5.052**.
- **No** se ejecutó hasta el final: Verilator 5.052 aborta dentro del arranque de fases de la propia librería UVM (`UVM_FATAL OBJTN_ZERO` en tiempo 0), incluso para un test UVM "hello" mínimo. Esto es una **limitación del simulador, no un resultado del testbench**.
- Correrlo en **Questa / VCS / Xcelium** (o en EDA Playground) queda **pendiente**.

---

## Ruta de aprendizaje

1. **Lee el DUT** (`rtl/sync_fifo.sv`) y entiende por qué los punteros tienen un bit extra para distinguir `full` de `empty`.
2. **Corre el self-check** (`bash sim/run_selfcheck.sh`) y observa el PASS sobre 15,354 ciclos.
3. **Estudia el testbench UVM** en orden: `fifo_if.sv` → `fifo_item.sv` → `fifo_sequences.sv` → `fifo_driver.sv` → `fifo_monitor.sv` → `fifo_scoreboard.sv` → `fifo_coverage.sv` → `fifo_agent.sv` → `fifo_env.sv` → `fifo_tests.sv`.
4. **Explora la guía web didáctica** en `docs/index.html` (ábrela en tu navegador): incluye un simulador interactivo de la FIFO y ejercicios guiados.
5. **Corre los tests UVM** en un simulador comercial (`bash sim/run_questa.sh fifo_random_test`) y experimenta con los demás tests.

---

## Guía didáctica web

Abre **`docs/index.html`** directamente en tu navegador. Incluye:

- Un **simulador interactivo** de la FIFO (DEPTH 16) con punteros de cabeza y cola animados, entrada de datos 0–255, botones **Push**, **Pop**, **Push+Pop** (mismo ciclo) y **Random x10**, flags `full`/`empty` en vivo, contadores de *overflow intentados* y *underflow intentados*, y un panel de *scoreboard* que compara la cola de referencia con el contenido de la FIFO.
- La **Clase 1 — Reset asíncrono y cómo verificarlo** (`#clase-1`), con un laboratorio interactivo que compara el reset asíncrono del RTL con un mutante síncrono.
- Una sección de **ejercicios** (`#ejercicios`, ejercicios 1–6) con pistas y soluciones colapsables.
- Un **registro de cambios** (`#cambios`).

---

## Registro de cambios

- **2026-09-19** — Clase 1 (reset asíncrono y su verificación) con laboratorio interactivo; ejercicios 4–6; Fase 9 en `tb/selfcheck_tb.sv` (reset a mitad de ciclo desde FIFO llena, pulso de reset entre flancos, escrituras durante el reset): PASS sobre 15,354 ciclos. El testbench UVM sigue sin ejecutarse en ningún simulador (los fragmentos de aserción del ejercicio 6 tampoco se ejecutaron).
- **2026-09-19** — Versión inicial.

---

## Licencia

MIT. Consulta el archivo `LICENSE` para más detalles.
