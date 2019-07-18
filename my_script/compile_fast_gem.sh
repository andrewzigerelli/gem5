#!/bin/bash
set -e
GEM5_PATH=~/gemb/gem5
cd $GEM5_PATH;
scons --max-drift=1 build/X86_MESI_Two_Level/gem5.fast -j 30;
