#!/bin/bash
#SBATCH -A gen008
#SBATCH -q debug
#SBATCH --nodes=16
#SBATCH -t 00:30:00
#SBATCH -J TMPFS
#SBATCH -C nvme
#SBATCH -o logs/pdsw/TMPFS-%j.out

echo "Allocated Nodes: $SLURM_NODELIST"
# rm hvac_server_log.*
# rm hvac_intercept_log.*
module load rocm/6.0.0
module load python/3.10-miniforge3
module load gcc/12.2.0

export MIOPEN_DISABLE_CACHE=1
export MIOPEN_FIND_MODE=3
export MIOPEN_USER_DB_PATH=/tmp/miopen_cache_$SLURM_PROCID
mkdir -p $MIOPEN_USER_DB_PATH
# export MIOPEN_USER_DB_PATH=Path_To_Your/ghu4/miopen_cache


source Path_To_Your/ghu4/envs/hvac/bin/activate


export HVAC_LOG_LEVEL=500
export RDMAV_FORK_SAFE=1
export VERBS_LOG_LEVEL=4
export TF_CPP_MIN_LOG_LEVEL=3
export http_proxy=http://proxy.ccs.ornl.gov:3128/
export https_proxy=https://proxy.ccs.ornl.gov:3128/

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:Path_To_Your/log4c-1.2.4/install/lib/pkgconfig
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:Path_To_Your/log4c-1.2.4/install/lib
export PATH=Path_To_Your/mercury-2.0.1/build/bin:$PATH
export LD_LIBRARY_PATH=Path_To_Your/mercury2.0.1/lib:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=Path_To_Your/mercury2.0.1/include:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=Path_To_Your/mercury2.0.1/include:$CPLUS_INCLUDE_PATH
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:Path_To_Your/mercury2.0.1/lib/pkgconfig

# ! Should change this to the correct path
export HVAC_DATA_DIR=Path_To_Your_Data

# total number of servers, If I have 4 nodes and then I want to run 2 servers on each node, then I should set this to 8
export HVAC_SERVER_COUNT=32

set -x

export BBPATH=/tmp


# Start 2 servers per node: 128 nodes × 2 = 256 servers total
srun -N 16 -n 16 -c4 --ntasks-per-node=2 --cpus-per-task=1 --cpu-bind=cores Path_To_Your/ghu4/GHU_HVAC/build/src/hvac_server $HVAC_SERVER_COUNT &

sleep 10

HVAC_SERVER_PID_FILE="/tmp/hvac_server.pid"
echo "Waiting for HVAC server to write its PID to $HVAC_SERVER_PID_FILE..."
HVAC_SERVER_ACTUAL_PID=""
for i in $(seq 1 20); do # Wait up to 20 seconds
    if [ -f "$HVAC_SERVER_PID_FILE" ]; then
        HVAC_SERVER_ACTUAL_PID=$(cat "$HVAC_SERVER_PID_FILE")
        # Basic check if PID is a number and process exists
        if [[ "$HVAC_SERVER_ACTUAL_PID" =~ ^[0-9]+$ ]] && ps -p "$HVAC_SERVER_ACTUAL_PID" > /dev/null; then
            echo "HVAC server running with PID: $HVAC_SERVER_ACTUAL_PID"
            break
        fi
    fi
    sleep 1
done

if [ -z "$HVAC_SERVER_ACTUAL_PID" ]; then
    echo "Error: Could not get HVAC server PID from $HVAC_SERVER_PID_FILE after 20 seconds."
    # exit 1 # Or handle error
fi


srun -N 16 -c4 --gpus-per-node=8 --ntasks-per-gpu=1 --cpu-bind=cores Path_To_Your/ghu4/cosmoflow-benchmark-master/command_CF_HVAC.sh

echo "Shutting down HVAC server..."
if [ -n "$HVAC_SERVER_ACTUAL_PID" ] && ps -p "$HVAC_SERVER_ACTUAL_PID" > /dev/null; then
    echo "Sending SIGTERM to HVAC server (PID: $HVAC_SERVER_ACTUAL_PID)."
    kill -SIGTERM "$HVAC_SERVER_ACTUAL_PID"
    # Wait a bit for graceful shutdown
    sleep 5 # Adjust as needed
    if ps -p "$HVAC_SERVER_ACTUAL_PID" > /dev/null; then
        echo "Server didn't shut down, sending SIGKILL."
        kill -SIGKILL "$HVAC_SERVER_ACTUAL_PID"
    else
        echo "Server shut down."
    fi
    rm -f "$HVAC_SERVER_PID_FILE" # Clean up PID file
else
    echo "HVAC server (PID: $HVAC_SERVER_ACTUAL_PID) not found or already exited."
fi

echo "Slurm script finished."