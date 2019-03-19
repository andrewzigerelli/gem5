#!/bin/bash
set -e
cd $GEM5_PATH/my_script;
BUILD_STRING=$(grep -E "^BUILD=" run_gem.sh)
#extract just the ISA
ISA=${BUILD_STRING:6}
./run_gem.sh --benchmark `ls readfiles | grep 502`;
cd output/$ISA/ubuntu-16.img/vmlinux_4.19.0/502.gcc_r_readfile_0;
gunzip -f my_trace.out.gz;
vim my_trace.out;
