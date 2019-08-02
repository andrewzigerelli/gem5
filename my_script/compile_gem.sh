#!/bin/bash
set -e
GEM5_PATH=~/gem5_fix_freq
cd $GEM5_PATH;
scons --ignore-style --max-drift=1 build/X86_MESI_Two_Level/gem5.opt -j 30;
