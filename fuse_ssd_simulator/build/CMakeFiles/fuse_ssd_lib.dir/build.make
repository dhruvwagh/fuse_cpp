# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.22

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build

# Include any dependencies generated for this target.
include CMakeFiles/fuse_ssd_lib.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include CMakeFiles/fuse_ssd_lib.dir/compiler_depend.make

# Include the progress variables for this target.
include CMakeFiles/fuse_ssd_lib.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/fuse_ssd_lib.dir/flags.make

CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.o: CMakeFiles/fuse_ssd_lib.dir/flags.make
CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.o: ../src/fuse/fuse_interface.cpp
CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.o: CMakeFiles/fuse_ssd_lib.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.o"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.o -MF CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.o.d -o CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.o -c /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/fuse/fuse_interface.cpp

CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/fuse/fuse_interface.cpp > CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.i

CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/fuse/fuse_interface.cpp -o CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.s

CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.o: CMakeFiles/fuse_ssd_lib.dir/flags.make
CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.o: ../src/hashing/hashing_module.cpp
CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.o: CMakeFiles/fuse_ssd_lib.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building CXX object CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.o"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.o -MF CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.o.d -o CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.o -c /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/hashing/hashing_module.cpp

CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/hashing/hashing_module.cpp > CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.i

CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/hashing/hashing_module.cpp -o CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.s

CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.o: CMakeFiles/fuse_ssd_lib.dir/flags.make
CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.o: ../src/hashing/xxhash.c
CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.o: CMakeFiles/fuse_ssd_lib.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Building C object CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.o -MF CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.o.d -o CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.o -c /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/hashing/xxhash.c

CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/hashing/xxhash.c > CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.i

CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/hashing/xxhash.c -o CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.s

CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.o: CMakeFiles/fuse_ssd_lib.dir/flags.make
CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.o: ../src/logger/logger.cpp
CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.o: CMakeFiles/fuse_ssd_lib.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Building CXX object CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.o"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.o -MF CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.o.d -o CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.o -c /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/logger/logger.cpp

CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/logger/logger.cpp > CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.i

CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/logger/logger.cpp -o CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.s

CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.o: CMakeFiles/fuse_ssd_lib.dir/flags.make
CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.o: ../src/metadata/metadata_manager.cpp
CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.o: CMakeFiles/fuse_ssd_lib.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_5) "Building CXX object CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.o"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.o -MF CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.o.d -o CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.o -c /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/metadata/metadata_manager.cpp

CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/metadata/metadata_manager.cpp > CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.i

CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/metadata/metadata_manager.cpp -o CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.s

CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.o: CMakeFiles/fuse_ssd_lib.dir/flags.make
CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.o: ../src/monitoring/monitor.cpp
CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.o: CMakeFiles/fuse_ssd_lib.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_6) "Building CXX object CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.o"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.o -MF CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.o.d -o CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.o -c /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/monitoring/monitor.cpp

CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/monitoring/monitor.cpp > CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.i

CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/monitoring/monitor.cpp -o CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.s

CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.o: CMakeFiles/fuse_ssd_lib.dir/flags.make
CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.o: ../src/ssd_simulator/ssd_simulator.cpp
CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.o: CMakeFiles/fuse_ssd_lib.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_7) "Building CXX object CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.o"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.o -MF CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.o.d -o CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.o -c /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/ssd_simulator/ssd_simulator.cpp

CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/ssd_simulator/ssd_simulator.cpp > CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.i

CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/ssd_simulator/ssd_simulator.cpp -o CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.s

CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.o: CMakeFiles/fuse_ssd_lib.dir/flags.make
CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.o: ../src/storage_accelerator/load_balancer.cpp
CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.o: CMakeFiles/fuse_ssd_lib.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_8) "Building CXX object CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.o"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.o -MF CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.o.d -o CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.o -c /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/storage_accelerator/load_balancer.cpp

CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/storage_accelerator/load_balancer.cpp > CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.i

CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/storage_accelerator/load_balancer.cpp -o CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.s

CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.o: CMakeFiles/fuse_ssd_lib.dir/flags.make
CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.o: ../src/storage_accelerator/storage_accelerator.cpp
CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.o: CMakeFiles/fuse_ssd_lib.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_9) "Building CXX object CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.o"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.o -MF CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.o.d -o CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.o -c /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/storage_accelerator/storage_accelerator.cpp

CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/storage_accelerator/storage_accelerator.cpp > CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.i

CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/storage_accelerator/storage_accelerator.cpp -o CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.s

CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.o: CMakeFiles/fuse_ssd_lib.dir/flags.make
CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.o: ../src/utils/thread_pool.cpp
CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.o: CMakeFiles/fuse_ssd_lib.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_10) "Building CXX object CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.o"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.o -MF CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.o.d -o CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.o -c /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/utils/thread_pool.cpp

CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/utils/thread_pool.cpp > CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.i

CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/src/utils/thread_pool.cpp -o CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.s

# Object files for target fuse_ssd_lib
fuse_ssd_lib_OBJECTS = \
"CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.o" \
"CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.o" \
"CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.o" \
"CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.o" \
"CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.o" \
"CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.o" \
"CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.o" \
"CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.o" \
"CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.o" \
"CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.o"

# External object files for target fuse_ssd_lib
fuse_ssd_lib_EXTERNAL_OBJECTS =

libfuse_ssd_lib.a: CMakeFiles/fuse_ssd_lib.dir/src/fuse/fuse_interface.cpp.o
libfuse_ssd_lib.a: CMakeFiles/fuse_ssd_lib.dir/src/hashing/hashing_module.cpp.o
libfuse_ssd_lib.a: CMakeFiles/fuse_ssd_lib.dir/src/hashing/xxhash.c.o
libfuse_ssd_lib.a: CMakeFiles/fuse_ssd_lib.dir/src/logger/logger.cpp.o
libfuse_ssd_lib.a: CMakeFiles/fuse_ssd_lib.dir/src/metadata/metadata_manager.cpp.o
libfuse_ssd_lib.a: CMakeFiles/fuse_ssd_lib.dir/src/monitoring/monitor.cpp.o
libfuse_ssd_lib.a: CMakeFiles/fuse_ssd_lib.dir/src/ssd_simulator/ssd_simulator.cpp.o
libfuse_ssd_lib.a: CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/load_balancer.cpp.o
libfuse_ssd_lib.a: CMakeFiles/fuse_ssd_lib.dir/src/storage_accelerator/storage_accelerator.cpp.o
libfuse_ssd_lib.a: CMakeFiles/fuse_ssd_lib.dir/src/utils/thread_pool.cpp.o
libfuse_ssd_lib.a: CMakeFiles/fuse_ssd_lib.dir/build.make
libfuse_ssd_lib.a: CMakeFiles/fuse_ssd_lib.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_11) "Linking CXX static library libfuse_ssd_lib.a"
	$(CMAKE_COMMAND) -P CMakeFiles/fuse_ssd_lib.dir/cmake_clean_target.cmake
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/fuse_ssd_lib.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/fuse_ssd_lib.dir/build: libfuse_ssd_lib.a
.PHONY : CMakeFiles/fuse_ssd_lib.dir/build

CMakeFiles/fuse_ssd_lib.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/fuse_ssd_lib.dir/cmake_clean.cmake
.PHONY : CMakeFiles/fuse_ssd_lib.dir/clean

CMakeFiles/fuse_ssd_lib.dir/depend:
	cd /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build /home/parallels/Documents/fuse_cpp/fuse_ssd_simulator/build/CMakeFiles/fuse_ssd_lib.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/fuse_ssd_lib.dir/depend

