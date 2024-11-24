cmake_minimum_required(VERSION 3.10)
project(fuse_ssd_simulator)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Define FUSE API version
add_definitions(-DFUSE_USE_VERSION=31)

# Find required packages
find_package(PkgConfig REQUIRED)
pkg_check_modules(FUSE REQUIRED fuse3)
find_package(Threads REQUIRED)
find_package(GTest REQUIRED)

# Include directories
include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${FUSE_INCLUDE_DIRS}
    ${CMAKE_SOURCE_DIR}/external
)

# Add compile options from FUSE
add_compile_options(${FUSE_CFLAGS})

# Source files
set(SOURCES
    src/fuse/fuse_interface.cpp
    src/hashing/hashing_module.cpp
    src/hashing/xxhash.c
    src/logger/logger.cpp
    src/metadata/metadata_manager.cpp
    src/monitoring/monitor.cpp
    src/ssd_simulator/ssd_simulator.cpp
    src/storage_accelerator/load_balancer.cpp
    src/storage_accelerator/storage_accelerator.cpp
    src/utils/thread_pool.cpp
)

# Create library
add_library(fuse_ssd_lib STATIC ${SOURCES})

target_link_libraries(fuse_ssd_lib
    ${FUSE_LIBRARIES}
    ${CMAKE_THREAD_LIBS_INIT}
)

# Create main executable
add_executable(fuse_ssd_simulator src/main.cpp)

target_link_libraries(fuse_ssd_simulator
    fuse_ssd_lib
    ${FUSE_LIBRARIES}
    ${CMAKE_THREAD_LIBS_INIT}
)

# Tests
enable_testing()

add_executable(run_tests
    tests/test_storage_accelerator.cpp
)

target_link_libraries(run_tests
    fuse_ssd_lib
    GTest::GTest
    GTest::Main
    ${CMAKE_THREAD_LIBS_INIT}
)

add_test(NAME run_tests COMMAND run_tests)s