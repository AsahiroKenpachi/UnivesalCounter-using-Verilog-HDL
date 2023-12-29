#!bin/bash
iverilog universalcounter.v
iverilog -o testbench.vvp testbench.v
vvp testbench.vvp
gtkwave
