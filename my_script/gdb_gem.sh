#!/bin/bash
set -e
cd $GEM5_PATH/my_script;
./run_gem.sh --gdb --benchmark `ls readfiles | grep 502`
