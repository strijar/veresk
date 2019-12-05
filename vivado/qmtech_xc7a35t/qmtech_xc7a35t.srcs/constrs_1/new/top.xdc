set_property IOSTANDARD LVCMOS33 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property PACKAGE_PIN N11 [get_ports clk]
set_property PACKAGE_PIN E6 [get_ports led]
set_property PACKAGE_PIN K5 [get_ports rst_n]
set_property PACKAGE_PIN B7 [get_ports uart_rx]
set_property PACKAGE_PIN B6 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

create_clock -period 20.000 -name clk -waveform {0.000 10.000} [get_ports clk]



