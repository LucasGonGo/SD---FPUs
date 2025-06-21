catch {vdel -all -lib work}
vlib work
vmap work work

vlog -work work my_FPU.sv
vlog -work work tb.sv

# Rodar com otimização desativada de forma moderna
vsim -O0 work.tb

quietly set StdArithNoWarnings 1
quietly set StdVitalGlitchNoWarnings 1

do wave.do
run 5ms
