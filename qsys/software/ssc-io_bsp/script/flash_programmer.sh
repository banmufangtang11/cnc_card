#!/bin/sh
#
# This file was automatically generated.
#
# It can be overwritten by nios2-flash-programmer-generate or nios2-flash-programmer-gui.
#

#
# Converting SOF File: D:\Code\quartus\spi_123\par\output_files\cnc.sof to: "..\flash/cnc_epcs_flash.flash"
#
sof2flash --input="D:/Code/quartus/spi_123/par/output_files/cnc.sof" --output="../flash/cnc_epcs_flash.flash" --epcs --verbose 

#
# Programming File: "..\flash/cnc_epcs_flash.flash" To Device: epcs_flash
#
nios2-flash-programmer "../flash/cnc_epcs_flash.flash" --base=0x11000 --epcs --sidp=0x12050 --id=0x137 --timestamp=1652759659 --device=1 --instance=0 '--cable=USB-Blaster on localhost [USB-0]' --program --verbose 

#
# Converting ELF File: D:\Code\quartus\spi_123\qsys\software\ssc-io\ssc-io.elf to: "..\flash/ssc-io_epcs_flash.flash"
#
elf2flash --input="D:/Code/quartus/spi_123/qsys/software/ssc-io/ssc-io.elf" --output="../flash/ssc-io_epcs_flash.flash" --epcs --after="../flash/cnc_epcs_flash.flash" --verbose 

#
# Programming File: "..\flash/ssc-io_epcs_flash.flash" To Device: epcs_flash
#
nios2-flash-programmer "../flash/ssc-io_epcs_flash.flash" --base=0x11000 --epcs --sidp=0x12050 --id=0x137 --timestamp=1652759659 --device=1 --instance=0 '--cable=USB-Blaster on localhost [USB-0]' --program --verbose 

