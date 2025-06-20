onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock & Reset}
add wave -noupdate -radix binary /tb/clk
add wave -noupdate -color {Blue Violet} /tb/rst
add wave -noupdate -divider Entradas
add wave -noupdate -radix binary /tb/send_A
add wave -noupdate -radix binary /tb/send_B
add wave -noupdate -divider Saidas
add wave -noupdate -radix hex /tb/result
add wave -noupdate -radix binary /tb/op_status
add wave -noupdate -divider Estados
add wave -noupdate -radix binary /tb/dut/EA
add wave -noupdate -radix binary /tb/dut/mant_A
add wave -noupdate -radix binary /tb/dut/mant_B
add wave -noupdate /tb/dut/exp_A
add wave -noupdate /tb/dut/exp_B
add wave -noupdate /tb/dut/sign_A
add wave -noupdate /tb/dut/sign_B
add wave -noupdate /tb/dut/sign_OUT
add wave -noupdate /tb/dut/carry
add wave -noupdate /tb/dut/compare
add wave -noupdate /tb/dut/mant_TMP
add wave -noupdate /tb/dut/mant_OUT
add wave -noupdate /tb/dut/exp_TMP
add wave -noupdate /tb/dut/exp_OUT
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {28522011 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {69141288 ps}
