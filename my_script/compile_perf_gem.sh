#!/bin/bash
set -e
cd $GEM5_PATH;
scons --max-drift=1 build/X86_MESI_Two_Level/gem5.perf -j 30;
