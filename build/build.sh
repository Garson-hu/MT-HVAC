#!/bin/bash

# module reset
#module load PrgEnv-gnu 
# module load mercury cmake libfabric
module unload darshan-runtime 

export HVAC_SERVER_COUNT=1
export HVAC_LOG_LEVEL=800
export RDMAV_FORK_SAFE=1
export VERBS_LOG_LEVEL=4
export BBPATH=/mnt/bb/$USER

export http_proxy=http://proxy.ccs.ornl.gov:3128/
export https_proxy=https://proxy.ccs.ornl.gov:3128/

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/lustre/orion/gen008/proj-shared/log4c-1.2.4/install/lib/pkgconfig
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/lustre/orion/gen008/proj-shared/log4c-1.2.4/install/lib
export PATH=/lustre/orion/gen008/proj-shared/mercury-2.0.1/build/bin:$PATH
export LD_LIBRARY_PATH=/lustre/orion/gen008/proj-shared/rlibrary/mercury2.0.1/lib:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=/lustre/orion/gen008/proj-shared/rlibrary/mercury2.0.1/include:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=/lustre/orion/gen008/proj-shared/rlibrary/mercury2.0.1/include:$CPLUS_INCLUDE_PATH
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/lustre/orion/gen008/proj-shared/rlibrary/mercury2.0.1/lib/pkgconfig

# export HVAC_DATA_DIR=/lustre/orion/gen008/proj-shared/ghu4/data/cosmoUniverse_2019_05_4parE_tf_v2_mini/train/

cmake \
    -DCMAKE_C_COMPILER=/opt/cray/pe/gcc/12.2.0/bin/gcc \
    -DCMAKE_CXX_COMPILER=/opt/cray/pe/gcc/12.2.0/bin/g++ \
    -DCMAKE_C_FLAGS="-O3" \
    -DCMAKE_CXX_FLAGS="-O3" \..


# -DCMAKE_C_FLAGS="-O3 -g -pg" \
# -DCMAKE_CXX_FLAGS="-O3 -g -pg" \
# -DCMAKE_EXE_LINKER_FLAGS="-pg" \
# -DCMAKE_SHARED_LINKER_FLAGS="-pg" \..

# 9.1 
# -DCMAKE_C_COMPILER=/lustre/orion/gen008/proj-shared/GCC-9.1.0/bin/gcc -DCMAKE_CXX_COMPILER=/lustre/orion/gen008/proj-shared/GCC-9.1.0/bin/g++

make -j4

