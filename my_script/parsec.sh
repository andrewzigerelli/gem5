#!/bin/bash
###################################################
# WE ASSSUME M5_PATH 
# and 
# GEM5_PATH
# ARE SET AS ENVIRONMENT VARIABLES!!!
###################################################


GEM_CMD=$GEM5_PATH/build/X86/gem5.opt
#GEM_MOESI_HAMMER=$GEM5_PATH/build/X86_MOESI_hammer/gem5.opt
CFG=$GEM5_PATH/configs/example/fs.py

####### CFG OPTIONS
######  KERNEL AND DISK IMAGE ARE TO BE LOCATED IN
######  M5_PATH/binaries and M5_PATH/disks respectively
KERNEL_VERSION="4.19.0"
KERNEL="vmlinux_"$KERNEL_VERSION
CPU_TYPE="DerivO3CPU"
CKPT_CPU_TYPE="TimingSimpleCPU"
MEM_SIZE="2GB"

####CACHE_CONFIG
L1D_SIZE="32kB"
L1I_SIZE="32kB"
L1D_ASSOC="8"
L1I_ASSOC="8"

L2_SIZE="256kB"
L2_ASSOC="4"

L3_size="2MB"
L3_ASSOC="8"

USE_RUBY="TRUE" #SET TO TRUE TO USE RUBY

#### DISK_IMAGE FOLLOW BY root=option since each 
#### image has a different root partition
DISK_IMAGE="x86root-parsec.img"
ROOT=/dev/sda1
CKPT_DIR=./parsec_ckpt


#DISK_IMAGE=ubuntu-16.img
#ROOT=/dev/sda2

#DISK_IMAGE=ubuntu-18.04.1_qemu.img
#ROOT=/dev/sda3

#DISK_IMAGE=ubuntu-16.04.5_qemu.img
#ROOT="/dev/sda2"

#DISK_IMAGE=rootfs.ext2
#KERNEL_CMD_OPTIONS=root=/dev/sda2

#### COMMAND LINE OPTIONS TO BE PASSED TO KERNEL AT BOOT
CMD_LINE='earlyprintk=ttyS0 console=ttyS0 console_msg_format=syslog lpj=7999923 panic=-1 printk.devkmsg=on printk.time=y rw'


#### SET UP GEM5 OPTIONS FOR FS.PY
#CKPT_DIR=./checkpoints

### readfile for gem5
CKPT_READFILE="$(pwd)/../configs/boot/hack_back_ckpt.rcS" #set for ckpt for now

### SET UP CACHE CFG
CACHE_CFG="--caches --l2cache --l1d_size=$L1D_SIZE --l1i_size=$L1I_SIZE --l2_size=$L2_SIZE --l3_size=$L3_SIZE --l1d_assoc=$L1D_ASSOC --l1i_assoc=$L1I_ASSOC --l2_assoc=$L2_ASSOC --l3_assoc=$L3_ASSOC"
CACHE_OPTIONS=$CACHE_CFG

if [ "$USE_RUBY" == "TRUE" ]; then
    CACHE_OPTIONS="--ruby $CACHE_CFG"

fi

CFG_OPTIONS_CKPT="--checkpoint-dir=$CKPT_DIR --script $CKPT_READFILE --kernel $KERNEL --disk-image $DISK_IMAGE --cpu-type=$CKPT_CPU_TYPE --mem-size $MEM_SIZE $CACHE_CFG"
# check if help
if [ "$#" -eq 1 ] && [ "$1" = "--help" ]; then
    echo "./run_gem.sh --dry-run to see which would be run"
    echo "./run_gem.sh --fs-help to see options to gem5 fs.py config"
    echo "./run_gem.sh --fs-options to pass options to fs.py"
    echo "      e.g. ./run_gem.sh --fs-options --list-cpu-types"
    exit
fi
if [ "$#" -eq 1 ] && [ "$1" = "--fs-help" ]; then
    $GEM_CMD $CFG --help
    exit
fi
if [ "$1" = "--fs-options" ]; then
    if [ "$#" -eq 1 ] || [ "$#" -gt 2 ] ; then
        echo "--fs-options requires exactly 1 argument following it"
        echo "      e.g. ./run_gem.sh --fs-options --list-cpu-types"
        exit
    fi
    $GEM_CMD $CFG $2
    exit
fi

OUT_DIR="./"output"/"$DISK_IMAGE"/"$KERNEL

#### setup checkpointing
# setup readfile for initial checkpoint
CKPT_CMD=$GEM_CMD" "--outdir" "$OUT_DIR" "$CFG" "$CFG_OPTIONS_CKPT" "--command-line" '"$CMD_LINE" root="$ROOT"'"
# NOT SURE WHY READFILE NOT WORKING


#### Check if we need to checkpoint
#### grep for checkpoint directory using regex (-E flag)
NUM_CKPT=$(cd $CKPT_DIR; ls -d */ 2> /dev/null | grep -E "^cpt\.[0-9]+/" | wc -l)

if ((NUM_CKPT > 1)); then
    echo "More than 1 checkpoint found in $CKPT_DIR"
    echo "Delete all, or all except one, and rerun"
    exit
fi

if ((NUM_CKPT == 0)); then
    echo "No checkpoints found; creating checkpoint for future runs..."
    if [ "$#" -eq 1 ] && [ "$1" = "--dry-run" ]; then
        echo $CKPT_CMD
        exit
    fi
    eval $CKPT_CMD
    echo "Done checkpointing!"
fi

### BENCHMARK OPTIONS
BENCHMARK="testing"
BENCH_READFILE="$(pwd)/test_readfile"
BENCH_OPTIONS="--checkpoint-dir=$CKPT_DIR --script $BENCH_READFILE --kernel $KERNEL --disk-image $DISK_IMAGE --cpu-type=$CKPT_CPU_TYPE --restore-with-cpu=$CPU_TYPE --mem-size $MEM_SIZE $CACHE_OPTIONS -r 1"
BENCH_OUT_DIR=$OUT_DIR/$BENCHMARK/

#buid full cmd, potentially unsafe if you screw up the builder variables
FULL_CMD=$GEM_CMD" "--outdir=$BENCH_OUT_DIR" "$CFG" "$BENCH_OPTIONS" #"--command-line" '"$CMD_LINE" root="$ROOT"'"
if [ "$#" -eq 1 ] && [ "$1" = "--dry-run" ]; then
    echo $FULL_CMD
    exit
fi
eval $FULL_CMD
