#!/bin/bash
set -e
cd $GEM5_PATH/my_script;
BUILD_STRING=$(grep -E "^BUILD=" run_gem.sh)
#extract just the ISA
ISA=${BUILD_STRING:6}
CORE_STRING=$(grep -E "^CORE_NUM=" run_gem.sh)
CORE=${CORE_STRING:9}
CORE="${CORE%\"}"
CORE="${CORE#\"}"
./run_gem.sh --benchmark `ls readfiles | grep 502`
#cd output/$ISA/$CORE"_core"/ubuntu-16.img/vmlinux_4.19.0/541.gcc_r_readfile_0;
#gunzip -f my_trace.out.gz;
#vim my_trace.out;
