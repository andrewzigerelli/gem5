#!/bin/bash
set -e
cd $GEM5_PATH;
scons build/X86_MESI_Two_Level/gem5.opt -j 30;
cd my_script;
./run_gem.sh --benchmark `ls readfiles | grep 502`;
cd output/ubuntu-16.img/vmlinux_4.19.0/502.gcc_r_readfile_0;
gunzip -f my_trace.out.gz;
vim my_trace.out;
