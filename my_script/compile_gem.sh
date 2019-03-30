#!/bin/bash
set -e
GEM5_PATH=~/clean_gem5
cd $GEM5_PATH;
scons --max-drift=1 build/X86_MESI_Two_Level/gem5.opt -j 30;
