
set_property IOSTANDARD LVCMOS33 [get_ports clk_in]
set_property PACKAGE_PIN AC19 [get_ports clk_in]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets clk_in]

set_property IOSTANDARD LVCMOS33 [get_ports rst_in]
set_property PACKAGE_PIN Y3 [get_ports rst_in]

set_property IOSTANDARD LVCMOS33 [get_ports txd]
set_property PACKAGE_PIN H19 [get_ports txd]
set_property IOSTANDARD LVCMOS33 [get_ports rxd]
set_property PACKAGE_PIN F23 [get_ports rxd]

#VGA
set_property IOSTANDARD LVCMOS33 [get_ports {vga_pixel[7]}]
set_property PACKAGE_PIN U4 [get_ports {vga_pixel[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_pixel[6]}]
set_property PACKAGE_PIN U2 [get_ports {vga_pixel[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_pixel[5]}]
set_property PACKAGE_PIN T2 [get_ports {vga_pixel[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_pixel[4]}]
set_property PACKAGE_PIN R5 [get_ports {vga_pixel[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_pixel[3]}]
set_property PACKAGE_PIN U1 [get_ports {vga_pixel[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_pixel[2]}]
set_property PACKAGE_PIN R1 [get_ports {vga_pixel[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_pixel[1]}]
set_property PACKAGE_PIN P3 [get_ports {vga_pixel[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_pixel[0]}]
set_property PACKAGE_PIN P1 [get_ports {vga_pixel[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports vga_hsync]
set_property PACKAGE_PIN U5 [get_ports vga_hsync]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vsync]
set_property PACKAGE_PIN U6 [get_ports vga_vsync]

#LEDS
set_property PACKAGE_PIN K23  [get_ports {gpio0[15]}]
set_property PACKAGE_PIN J21  [get_ports {gpio0[14]}]
set_property PACKAGE_PIN H23  [get_ports {gpio0[13]}]
set_property PACKAGE_PIN J19  [get_ports {gpio0[12]}]
set_property PACKAGE_PIN G9  [get_ports {gpio0[11]}]
set_property PACKAGE_PIN J26  [get_ports {gpio0[10]}]
set_property PACKAGE_PIN J23  [get_ports {gpio0[9]}]
set_property PACKAGE_PIN J8  [get_ports {gpio0[8]}]
set_property PACKAGE_PIN H8  [get_ports {gpio0[7]}]
set_property PACKAGE_PIN G8  [get_ports {gpio0[6]}]
set_property PACKAGE_PIN F7  [get_ports {gpio0[5]}]
set_property PACKAGE_PIN A4  [get_ports {gpio0[4]}]
set_property PACKAGE_PIN A5  [get_ports {gpio0[3]}]
set_property PACKAGE_PIN A3  [get_ports {gpio0[2]}]
set_property PACKAGE_PIN D5  [get_ports {gpio0[1]}]
set_property PACKAGE_PIN H7  [get_ports {gpio0[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {gpio0[*]}]

#DIP_SW
set_property PACKAGE_PIN AC21 [get_ports {gpio1[0]}]
set_property PACKAGE_PIN AD24 [get_ports {gpio1[1]}]
set_property PACKAGE_PIN AC22 [get_ports {gpio1[2]}]
set_property PACKAGE_PIN AC23 [get_ports {gpio1[3]}]
set_property PACKAGE_PIN AB6  [get_ports {gpio1[4]}]
set_property PACKAGE_PIN W6   [get_ports {gpio1[5]}]
set_property PACKAGE_PIN AA7  [get_ports {gpio1[6]}]
set_property PACKAGE_PIN Y6   [get_ports {gpio1[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio1[*]}]


set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

