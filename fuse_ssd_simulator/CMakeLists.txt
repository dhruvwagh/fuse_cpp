cmake_minimum_required(VERSION 3.10)
project(fuse_ssd_simulator)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Define FUSE API version
add_definitions(-DFUSE_USE_VERSION=31)

# Find packages
find_package(PkgConfig REQUIRED)
pkg_check_modules(FUSE REQUIRED fuse3)
find_package(GTest REQUIRED)

# Include directories
include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${FUSE_INCLUDE_DIRS}
)

# Source files
set(SOURCE_FILES
    src/main.cpp
    src/fuse/fuse_interface.cpp
    src/hashing/hashing_module.cpp
    src/hashing/xxhash.c
    src/logger/logger.cpp
    src/metadata/metadata_manager.cpp
    src/monitoring/monitor.cpp
    src/ssd_simulator/ssd_simulator.cpp
    src/storage_accelerator/storage_accelerator.cpp
    src/utils/thread_pool.cpp
)

# Main executable
add_executable(fuse_ssd_simulator ${SOURCE_FILES})

# Link libraries
target_link_libraries(fuse_ssd_simulator
    ${FUSE_LIBRARIES}
    pthread
)

# Add compiler options
target_compile_options(fuse_ssd_simulator PRIVATE ${FUSE_CFLAGS})