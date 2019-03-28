#!/bin/bash
###################################################
# WE ASSSUME M5_PATH 
# and 
# GEM5_PATH
# ARE SET AS ENVIRONMENT VARIABLES!!!
###################################################


BUILD=X86_MESI_Two_Level
GEM_CMD=$GEM5_PATH/build/$BUILD/gem5.perf
GDB_GEM_CMD=$GEM5_PATH/build/$BUILD/gem5.debug
######## IF YOU CHANGE THIS, MAKE SURE TO RECHECKPOINT!!!
#BENCH_GEM_CMD=$GEM5_PATH/build/X86_MOESI_AMD_Base/gem5.opt
#GEM_MOESI_HAMMER=$GEM5_PATH/build/X86_MOESI_hammer/gem5.opt
CFG=$GEM5_PATH/configs/example/fs.py

####### CFG OPTIONS
######  KERNEL AND DISK IMAGE ARE TO BE LOCATED IN
######  M5_PATH/binaries and M5_PATH/disks respectively
KERNEL_VERSION="4.19.0"
KERNEL="vmlinux_"$KERNEL_VERSION
CPU_TYPE="DerivO3CPU" # This is the cpu type you will ultimately run
CPU_TYPE="AtomicSimpleCPU" # This is the cpu type you will ultimately run
CKPT_CPU_TYPE="AtomicSimpleCPU" # fast for ckpt purposes, if you change this
MEM_SIZE="2GB"


### OUR RCT options config
RCT_SIZE="50" # number of entries
NUM_COUNTERS="5"
RCT_CFG="--rct_size $RCT_SIZE --num_ctrs $NUM_COUNTERS"

####CACHE_CONFIG
CORE_NUM="2"
L1D_SIZE="32kB"
L1I_SIZE="32kB"
L1D_ASSOC="8"
L1I_ASSOC="8"

L2_SIZE="2MB"
L2_ASSOC="16"

L3_SIZE="2MB"
L3_ASSOC="8"

USE_RUBY="TRUE" #SET TO TRUE TO USE RUBY

#MAXINSTS=10000000000
MAXINSTS=100000000000

#### DISK_IMAGE FOLLOW BY root=option since each 
#### image has a different root partition
#DISK_IMAGE="x86root-parsec.img"
#ROOT=/dev/sda1

DISK_IMAGE=ubuntu-16.img
ROOT=/dev/sda2

#DISK_IMAGE=ubuntu-18.04.1_qemu.img
#ROOT=/dev/sda3

#DISK_IMAGE=ubuntu-16.04.5_qemu.img
#ROOT="/dev/sda2"

#DISK_IMAGE=rootfs.ext2
#KERNEL_CMD_OPTIONS=root=/dev/sda2

#### COMMAND LINE OPTIONS TO BE PASSED TO KERNEL AT BOOT
CMD_LINE='earlyprintk=ttyS0 console=ttyS0 console_msg_format=syslog lpj=7999923 panic=-1 printk.devkmsg=on printk.time=y rw'


#### SET UP GEM5 OPTIONS FOR FS.PY
# we don't distinguish between ruby and non ruby checkpoints
# we save checkpoints in own paths for convenience
CKPT_DIR=$GEM5_PATH"/"my_script"/"checkpoints"/"$BUILD"/"attack


### readfile for gem5
CKPT_READFILE="$(pwd)/../configs/boot/hack_back_ckpt.rcS" #set for ckpt for now

### SET UP CACHE CFG
CACHE_CFG="--num-cpus $CORE_NUM --caches --l2cache --num-dirs=$CORE_NUM --num-l2caches=$CORE_NUM
--num-l3caches=$CORE_NUM --l1d_size=$L1D_SIZE --l1i_size=$L1I_SIZE --l2_size=$L2_SIZE --l3_size=$L3_SIZE --l1d_assoc=$L1D_ASSOC --l1i_assoc=$L1I_ASSOC --l2_assoc=$L2_ASSOC --l3_assoc=$L3_ASSOC"
CACHE_OPTIONS=$CACHE_CFG

if [ "$USE_RUBY" == "TRUE" ]; then
    CACHE_OPTIONS="$CACHE_CFG --ruby"

fi

CFG_OPTIONS_CKPT="--checkpoint-dir=$CKPT_DIR --kernel $KERNEL --disk-image $DISK_IMAGE --cpu-type=$CKPT_CPU_TYPE --mem-size $MEM_SIZE $CACHE_CFG"

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

#OUT_DIR="./"output"/"$DISK_IMAGE"/"$KERNEL"/L2_size_"$L2_SIZE
OUT_DIR=$GEM5_PATH"/"my_script"/"output"/"$BUILD"/attack/"$DISK_IMAGE"/"$KERNEL

#### setup checkpointing
# setup readfile for initial checkpoint
CKPT_CMD=$GEM_CMD" "--outdir" "$OUT_DIR" "$CFG" "$CFG_OPTIONS_CKPT" "--command-line" '"$CMD_LINE" root="$ROOT"'"


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
    if [ "$1" = "--dry-run" ]; then
        echo $CKPT_CMD
        exit
    fi
    eval $CKPT_CMD
    echo "Done checkpointing!"
    exit
fi




### BENCHMARK OPTIONS
READFILE_NUMBER=0
BENCH_READFILE="$(pwd)/readfiles/$BENCHMARK"
BENCH_OPTIONS="--checkpoint-dir=$CKPT_DIR --kernel
$KERNEL --disk-image $DISK_IMAGE --cpu-type=$CPU_TYPE
--restore-with-cpu=$CKPT_CPU_TYPE --mem-size $MEM_SIZE $CACHE_OPTIONS $RCT_CFG -r 1"
BENCH_OUT_DIR=$OUT_DIR/$BENCHMARK/
BENCH_DEBUG_FLAG=infoflag
BENCH_DEBUG_FILE=my_trace.out.gz
BENCH_OUT_DEBUG_START=2600000000000
#buid full cmd, potentially unsafe if you screw up the builder variables
FULL_CMD=$GEM_CMD" "--outdir=$BENCH_OUT_DIR" "--debug-flags=$BENCH_DEBUG_FLAG"
"--debug-start=$BENCH_OUT_DEBUG_START" "$CFG" "$BENCH_OPTIONS" "--command-line" '"$CMD_LINE" root="$ROOT"'"

#FULL_CMD=$GEM_CMD" "--outdir=$BENCH_OUT_DIR" "$CFG" "$BENCH_OPTIONS" "--command-line" '"$CMD_LINE" root="$ROOT"'"

FULL_CMD=$GEM_CMD" "--outdir=$BENCH_OUT_DIR" "$CFG" "$BENCH_OPTIONS" "--command-line" '"$CMD_LINE" root="$ROOT"'"


DEBUG_CMD=$GEM_CMD" "--outdir=$BENCH_OUT_DIR" "$CFG" "$BENCH_OPTIONS" "--command-line" '"$CMD_LINE" root="$ROOT"'"
if [ "$1" = "--dry-run" ]; then
    echo $FULL_CMD
    exit
fi
if [ "$1" = "--gdb" ]; then
    GDB_CMD="gdb --args "$FULL_CMD
    eval $GDB_CMD
    exit
fi
if [ "$1" = "--rr" ]; then
    RR_CMD="rr record "$FULL_CMD
    eval $RR_CMD
    exit
fi

eval $FULL_CMD
