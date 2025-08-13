# MT-HVAC - Multi-Tier High Velocity AI Cache

A high-performance multi-tier distributed caching system designed for machine learning workloads, specifically optimized for deep learning training with massive datasets. MT-HVAC provides intelligent multi-tier storage management based on BBpath configuration for optimal data placement across storage hierarchies.

## Overview

MT-HVAC (Multi-Tier High Velocity AI Cache) is a client-server distributed caching system that provides accelerated data access for machine learning training workflows with intelligent multi-tier memory/storage management. It uses Mercury RPC framework for high-performance communication and is optimized for HPC environments like OLCF's Frontier supercomputer, leveraging burst buffer and parallel file system hierarchies for optimal performance.

### Key Features

- **Multi-Tier Cache**: Utilize different storage medie in the system to achieve hierarchy cache (Memory, Burst Buffer, Parallel File System)
- **Lock Contention Optimize**: Optimized for concurrent data access with per-file synchronization
- **HPC Optimized**: Designed for supercomputing environments with InfiniBand support
- **ML Focused**: Specifically tuned for deep learning training data access patterns

## Architecture

### Components

- **MT-HVAC Client** (`hvac_client`): Client library that intercepts file operations and manages multi-tier access
- **MT-HVAC Server** (`hvac_server`): High-performance data server using Mercury RPC with multi-tier awareness
- **Communication Layer**: Mercury-based RPC system for efficient client-server communication
- **Client-Server Data Mover**: Optimized bulk data transfer mechanisms across storage hierarchies
- **Storage Hierarchy Monitor**: Tracks and optimizes data placement across memory, NVME, and parallel file systems

### Performance Optimizations

The system has undergone significant performance optimizations to eliminate global synchronization bottlenecks:

- **Per-file synchronization**: Operations on different files can proceed in parallel
- **Reference counting**: Automatic resource management for sync contexts
- **Diagnostic infrastructure**: Comprehensive performance monitoring
- **Mercury progress thread optimization**: Improved RPC handling efficiency

## Requirements

### System Dependencies

- **Mercury RPC Framework**: Version 2.0.1
- **Log4C**: Logging framework
- **CMake**: Version 3.10.2
- **GCC**: Version 12.2.0 (for Frontier)
- **libfabric**: For high-performance networking

### HPC Environment

- **Cray Programming Environment**: For OLCF Frontier
- **InfiniBand/Slingshot**: High-speed interconnect support
- **Memory (TMPFS)**: For ultra-low latency cache (`/tmp`) (Optional)
- **Burst Buffer (NVME)**: For low latency cache (`/mnt/bb/$USER`)

## Building on OLCF Frontier

### Environment Setup

```bash
# Load required modules
module unload darshan-runtime

# Set environment variables
export HVAC_SERVER_COUNT=1
export HVAC_LOG_LEVEL=800
export RDMAV_FORK_SAFE=1
export VERBS_LOG_LEVEL=4

# Multi-tier storage configuration
export BBPATH=/tmp                  			# tmpfs (Tier 1 - ultra-low latency)

# Configure proxy (if needed)
export http_proxy=http://proxy.ccs.ornl.gov:3128/
export https_proxy=https://proxy.ccs.ornl.gov:3128/

# Set library paths
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:PATH_TO_YOUR/log4c-1.2.4/install/lib/pkgconfig
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:PATH_TO_YOUR/log4c-1.2.4/install/lib
export PATH=PATH_TO_YOUR/mercury-2.0.1/build/bin:$PATH
export LD_LIBRARY_PATH=PATH_TO_YOUR/mercury2.0.1/lib:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=PATH_TO_YOUR/mercury2.0.1/include:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=PATH_TO_YOUR/mercury2.0.1/include:$CPLUS_INCLUDE_PATH
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:PATH_TO_YOUR/mercury2.0.1/lib/pkgconfig
```

### Build Process

1. **Clone/Navigate to MT-HVAC directory**:
   ```bash
   cd MT-HVAC
   ```

2. **Create and enter build directory**:
   ```bash
   mkdir -p build
   cd build
   ```

3. **Run the build script**:
   ```bash
   ./build_frontier.sh
   ```

   Or manually configure and build:
   ```bash
   cmake \
       -DCMAKE_C_COMPILER=/opt/cray/pe/gcc/12.2.0/bin/gcc \
       -DCMAKE_CXX_COMPILER=/opt/cray/pe/gcc/12.2.0/bin/g++ \
       -DCMAKE_C_FLAGS="-O3" \
       -DCMAKE_CXX_FLAGS="-O3" \
       ..
   
   make -j4
   ```

### Build Outputs

After successful build, you'll find:
- `src/hvac_server`: The MT-HVAC server executable with multi-tier support
- `src/libhvac_client.so`: Client library for LD_PRELOAD with multi-tier awareness
- `tests/basic_test`: Basic functionality test including multi-tier operations

## Usage

### Server Setup

1. **Configure Multi-Tier Storage**:
   ```bash
   # Set up cache tier
   export BBPATH=/tmp
   ```

2. **Start MT-HVAC Server**:
   ```bash
   cd build
   ./src/hvac_server
   ```

3. **Configure server parameters** via environment variables:
   - `HVAC_SERVER_COUNT`: Number of server instances
   - `HVAC_LOG_LEVEL`: Logging verbosity level

### Client Usage

The MT-HVAC client can be used via LD_PRELOAD to intercept file operations with automatic multi-tier management:

```bash
# Basic usage with automatic tier selection
LD_PRELOAD=./src/libhvac_client.so your_ml_application
```

### Testing

Run the basic test to verify functionality:

```bash
cd build
./tests/basic_test
```


### Storage Tier Hierarchy

1. **Tier 1** (`tmpfs`): 
   - Ultray-low latency access (Memory-based)
   - Limited capacity
   - Ideal for frequently accessed training data

2. **Tier 2 - Burst Buffer**:
   - Low latency access (NVME-based)
   - Limited capacity
   - Good for frequently accessed training data

3. **Tier 3 - Parallel File System**:
   - High latecy
   - Large capacity
   - Persistent storage
   - Suitable for model checkpoints and large datasets

### Multi-Tier Setup

The system uses BBpath configuration to determine optimal data placement:

```bash
# Configure memory tier
export BBPATH=/tmp

```

### MT-HVAC Workflow Example

```bash
# 1. Set up multi-tier environment
export BBPATH=/mnt/bb/$USER

# 2. Start MT-HVAC server with multi-tier support
cd build
./src/hvac_server &

# 3. Run ML training with automatic tier management
LD_PRELOAD=./src/libhvac_client.so python train_model.py
```

You can also find the examples in the scripts directory

## Configuration

### Environment Variables

#### Basic Configuration
- `HVAC_SERVER_COUNT`: Number of server instances (default: 1)
- `HVAC_LOG_LEVEL`: Logging level (default: 800)
- `HVAC_DATA_DIR`: Data directory path for cache
- `RDMAV_FORK_SAFE`: Enable fork-safe RDMA operations
- `VERBS_LOG_LEVEL`: InfiniBand verbs logging level

#### Multi-Tier Configuration
- `BBPATH`: Burst buffer mount point (e.g., `/mnt/bb/$USER or /tmp`)

### Network Configuration

The system uses Mercury RPC with support for:
- InfiniBand/RDMA (verbs provider)
- TCP/IP fallback
- Cray Slingshot interconnect

## Project Structure

```
MT-HVAC/
├── src/                       # Source code
│   ├── hvac_client.cpp        # Multi-tier client implementation
│   ├── hvac_server.cpp        # Multi-tier server implementation
│   ├── hvac_comm.cpp          # Communication layer
│   ├── hvac_comm.h            # Communication interface
│   ├── hvac_data_mover.cpp    # Multi-tier data movement
│   └── ...
├── tests/                     # Test programs (including multi-tier tests)
├── scripts/                   # Helper scripts for multi-tier examples
├── build/                     # Build directory
├── CMakeLists.txt             # Build configuration
└── README.md                  # This file
```

## Performance

The MT-HVAC system has been optimized for high-concurrency machine learning workloads with intelligent multi-tier storage management:

### Core Performance Optimizations
- **Eliminated global synchronization bottlenecks**
- **Per-file parallel operations**
- **Optimized Mercury RPC usage**
- **Comprehensive diagnostic tools**


### Performance Characteristics by Tier

|  Storage Tier  | Access Latency | Bandwidth | Capacity | Use Case |
|----------------|---------------|-----------|----------|----------|
| Memory (Tier 1)| ~100 ns | >200 GB/s | Limited (~200GB) | Hot training data|
| NVME (Tier 2)| ~1-5 μs | >5 GB/s | Limited (~2TB) | Hot training data, checkpoints |
| Parallel FS (Tier 3) | ~50-200 μs | ~5 GB/s | Large (~PB) | Cold data, persistent storage |


## Contributing

When making changes to MT-HVAC:

1. Run tests to verify functionality (including different tier tests)
2. Consider impact on concurrent access patterns and tier selection
3. Test with realistic ML workloads across different storage tiers
4. Verify BBpath configuration changes work correctly

## License

This research used resources of the Oak Ridge Leadership Computing Facility, located at the National Center for Computational Sciences at the Oak Ridge National Laboratory, which is supported by the Office of Science of the DOE under Contract DE-AC05-00OR22725. 


## Contact

Please contact Guangxing Hu (ghu4@ncsu.edu) for any error or inquries.

---

