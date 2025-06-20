# Limpa a biblioteca work antiga, se existir
catch {vdel -all -lib work}

# Cria a biblioteca work nova
vlib work

# Mapeia a biblioteca work
vmap work work

# Compila os arquivos (mude os nomes para os seus arquivos .sv)
vlog -work work my_FPU.sv
vlog -work work tb.sv

# Roda a simulação com otimização e acesso completo
vsim -voptargs=+acc work.tb

# Abre a janela de waveform (opcional)
add wave -r /*

# Roda a simulação por um tempo (ajuste conforme seu teste)
run 10ns

# Fecha a simulação (opcional)
#quit
