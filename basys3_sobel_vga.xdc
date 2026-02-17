## basys3_sobel_vga.xdc
## Basys3 Master XDC constraints for top_sobel_vga_basys3
## Only the signals used by this design are included.


## Slide Switch 0 - U17
## UP   = 1 = show original image
## DOWN = 0 = show Sobel edges
set_property PACKAGE_PIN V17     [get_ports sw0]
set_property IOSTANDARD LVCMOS33 [get_ports sw0]
## Board clock: 100 MHz
set_property PACKAGE_PIN W5      [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Center button (reset)
set_property PACKAGE_PIN U18     [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## VGA Horizontal / Vertical Sync
set_property PACKAGE_PIN P19     [get_ports Hsync]
set_property IOSTANDARD LVCMOS33 [get_ports Hsync]
set_property PACKAGE_PIN R19     [get_ports Vsync]
set_property IOSTANDARD LVCMOS33 [get_ports Vsync]

## VGA Red
set_property PACKAGE_PIN G19     [get_ports {vgaRed[0]}]
set_property PACKAGE_PIN H19     [get_ports {vgaRed[1]}]
set_property PACKAGE_PIN J19     [get_ports {vgaRed[2]}]
set_property PACKAGE_PIN N19     [get_ports {vgaRed[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[*]}]

## VGA Green
set_property PACKAGE_PIN J17     [get_ports {vgaGreen[0]}]
set_property PACKAGE_PIN H17     [get_ports {vgaGreen[1]}]
set_property PACKAGE_PIN G17     [get_ports {vgaGreen[2]}]
set_property PACKAGE_PIN D17     [get_ports {vgaGreen[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[*]}]

## VGA Blue
set_property PACKAGE_PIN N18     [get_ports {vgaBlue[0]}]
set_property PACKAGE_PIN L18     [get_ports {vgaBlue[1]}]
set_property PACKAGE_PIN K18     [get_ports {vgaBlue[2]}]
set_property PACKAGE_PIN J18     [get_ports {vgaBlue[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[*]}]