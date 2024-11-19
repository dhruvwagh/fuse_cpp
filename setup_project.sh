#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Project Name
PROJECT_NAME="fuse_ssd_simulator"

# Create project root directory
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Create directory structure
mkdir -p src/fuse
mkdir -p src/storage_accelerator
mkdir -p src/ssd_simulator
mkdir -p src/hashing
mkdir -p src/metadata
mkdir -p src/logger
mkdir -p src/monitoring
mkdir -p src/utils
mkdir -p include/fuse
mkdir -p include/storage_accelerator
mkdir -p include/ssd_simulator
mkdir -p include/hashing
mkdir -p include/metadata
mkdir -p include/logger
mkdir -p include/monitoring
mkdir -p include/utils
mkdir -p tests

# Create CMakeLists.txt
cat > CMakeLists.txt <<EOL
cmake_minimum_required(VERSION 3.10)
project(fuse_ssd_simulator)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Find FUSE
find_package(PkgConfig REQUIRED)
pkg_check_modules(FUSE REQUIRED fuse3)

# Include directories
include_directories(
    include
    \${FUSE_INCLUDE_DIRS}
)

# Add source files
file(GLOB SRC_FILES
    src/main.cpp
    src/fuse/*.cpp
    src/storage_accelerator/*.cpp
    src/ssd_simulator/*.cpp
    src/hashing/*.cpp
    src/metadata/*.cpp
    src/logger/*.cpp
    src/monitoring/*.cpp
    src/utils/*.cpp
)

# Add executable
add_executable(fuse_ssd_simulator \${SRC_FILES})

# Link libraries
target_link_libraries(fuse_ssd_simulator \${FUSE_LIBRARIES} pthread)

# Compiler options
target_compile_options(fuse_ssd_simulator PRIVATE \${FUSE_CFLAGS})
EOL

# Create main.cpp
cat > src/main.cpp <<'EOL'
#include "fuse_interface.h"
#include "storage_accelerator/storage_accelerator.h"
#include "logger/logger.h"
#include <iostream>
#include <memory>

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <mount_point>" << std::endl;
        return 1;
    }

    std::string mount_point = argv[1];
    int num_drives = 16; // Up to 16 drives as per requirement
    std::string hash_seed = "default_seed";

    // Initialize Logger
    Logger::init("filesystem.log");
    Logger logger("Main");
    logger.info("Starting FUSE SSD Simulator");

    // Initialize Storage Accelerator
    auto accelerator = std::make_shared<StorageAccelerator>(num_drives, hash_seed);
    logger.info("Storage Accelerator initialized with " + std::to_string(num_drives) + " drives");

    // Initialize FUSE Interface
    FuseInterface fuse_interface(mount_point, accelerator);
    logger.info("Mounting FUSE filesystem at " + mount_point);
    fuse_interface.run();

    return 0;
}
EOL

# Create FuseInterface header and cpp
cat > include/fuse_interface.h <<'EOL'
#pragma once

#include <fuse3/fuse.h>
#include <string>
#include <memory>
#include "storage_accelerator/storage_accelerator.h"

class FuseInterface {
public:
    FuseInterface(const std::string& mount_point, std::shared_ptr<StorageAccelerator> accelerator);
    void run();

private:
    std::string mount_point_;
    std::shared_ptr<StorageAccelerator> accelerator_;

    static StorageAccelerator* static_accelerator_;
    static Logger* static_logger_;

    // FUSE operations
    static int getattr_callback(const char* path, struct stat* stbuf, struct fuse_file_info* fi);
    static int readdir_callback(const char* path, void* buf, fuse_fill_dir_t filler, off_t offset, struct fuse_file_info* fi, enum fuse_readdir_flags flags);
    static int open_callback(const char* path, struct fuse_file_info* fi);
    static int read_callback(const char* path, char* buf, size_t size, off_t offset, struct fuse_file_info* fi);
    static int write_callback(const char* path, const char* buf, size_t size, off_t offset, struct fuse_file_info* fi);
    static int create_callback(const char* path, mode_t mode, struct fuse_file_info* fi);
    static int unlink_callback(const char* path);
    static int truncate_callback(const char* path, off_t size, struct fuse_file_info* fi);
    static int mkdir_callback(const char* path, mode_t mode);
    static int rmdir_callback(const char* path);
    static int rename_callback(const char* from, const char* to, unsigned int flags);
    static int chmod_callback(const char* path, mode_t mode, struct fuse_file_info* fi);
    static int chown_callback(const char* path, uid_t uid, gid_t gid, struct fuse_file_info* fi);
    static int utimens_callback(const char* path, const struct timespec ts[2], struct fuse_file_info* fi);
    
    // Other necessary callbacks can be added here
};
EOL

cat > src/fuse/fuse_interface.cpp <<'EOL'
#include "fuse_interface.h"
#include "../logger/logger.h"
#include <cstring>
#include <iostream>
#include <vector>

// Initialize static members
StorageAccelerator* FuseInterface::static_accelerator_ = nullptr;
Logger* FuseInterface::static_logger_ = nullptr;

FuseInterface::FuseInterface(const std::string& mount_point, std::shared_ptr<StorageAccelerator> accelerator)
    : mount_point_(mount_point), accelerator_(accelerator) {
    static_accelerator_ = accelerator_.get();
    static_logger_ = new Logger("FUSE_Interface");
}

int FuseInterface::getattr_callback(const char* path, struct stat* stbuf, struct fuse_file_info* fi) {
    memset(stbuf, 0, sizeof(struct stat));

    if (strcmp(path, "/") == 0) {
        stbuf->st_mode = S_IFDIR | 0755;
        stbuf->st_nlink = 2;
    } else {
        // Fetch metadata from the accelerator
        auto metadata = FuseInterface::static_accelerator_->getMetadata(path);
        if (!metadata) {
            return -ENOENT;
        }

        stbuf->st_mode = metadata->mode;
        stbuf->st_nlink = metadata->nlink;
        stbuf->st_uid = metadata->uid;
        stbuf->st_gid = metadata->gid;
        stbuf->st_size = metadata->size;
        stbuf->st_atime = metadata->atime;
        stbuf->st_mtime = metadata->mtime;
        stbuf->st_ctime = metadata->ctime;
    }

    return 0;
}

int FuseInterface::readdir_callback(const char* path, void* buf, fuse_fill_dir_t filler, off_t offset, struct fuse_file_info* fi, enum fuse_readdir_flags flags) {
    // Add current and parent directories
    filler(buf, ".", NULL, 0, static_cast<fuse_fill_dir_flags>(0));
    filler(buf, "..", NULL, 0, static_cast<fuse_fill_dir_flags>(0));

    // Fetch directory entries from the accelerator
    auto entries = FuseInterface::static_accelerator_->listDirectory(path);
    for (const auto& entry : entries) {
        filler(buf, entry.c_str(), NULL, 0, static_cast<fuse_fill_dir_flags>(0));
    }

    return 0;
}

int FuseInterface::open_callback(const char* path, struct fuse_file_info* fi) {
    // Validate if the file exists
    auto metadata = FuseInterface::static_accelerator_->getMetadata(path);
    if (!metadata) {
        return -ENOENT;
    }

    // Additional checks can be implemented here (e.g., permissions)

    return 0;
}

int FuseInterface::read_callback(const char* path, char* buf, size_t size, off_t offset, struct fuse_file_info* fi) {
    // Forward read request to Storage Accelerator
    ssize_t bytes_read = FuseInterface::static_accelerator_->readFile(path, buf, size, offset);
    return bytes_read >= 0 ? bytes_read : -EIO;
}

int FuseInterface::write_callback(const char* path, const char* buf, size_t size, off_t offset, struct fuse_file_info* fi) {
    // Forward write request to Storage Accelerator
    ssize_t bytes_written = FuseInterface::static_accelerator_->writeFile(path, buf, size, offset);
    return bytes_written >= 0 ? bytes_written : -EIO;
}

int FuseInterface::create_callback(const char* path, mode_t mode, struct fuse_file_info* fi) {
    // Forward create request to Storage Accelerator
    int res = FuseInterface::static_accelerator_->createFile(path, mode);
    return res;
}

int FuseInterface::unlink_callback(const char* path) {
    // Forward delete request to Storage Accelerator
    int res = FuseInterface::static_accelerator_->deleteFile(path);
    return res;
}

int FuseInterface::truncate_callback(const char* path, off_t size, struct fuse_file_info* fi) {
    // Forward truncate request to Storage Accelerator
    int res = FuseInterface::static_accelerator_->truncateFile(path, size);
    return res;
}

int FuseInterface::mkdir_callback(const char* path, mode_t mode) {
    // Forward mkdir request to Storage Accelerator
    int res = FuseInterface::static_accelerator_->createDirectory(path, mode);
    return res;
}

int FuseInterface::rmdir_callback(const char* path) {
    // Forward rmdir request to Storage Accelerator
    int res = FuseInterface::static_accelerator_->removeDirectory(path);
    return res;
}

int FuseInterface::rename_callback(const char* from, const char* to, unsigned int flags) {
    // Forward rename request to Storage Accelerator
    int res = FuseInterface::static_accelerator_->renameFile(from, to, flags);
    return res;
}

int FuseInterface::chmod_callback(const char* path, mode_t mode, struct fuse_file_info* fi) {
    // Forward chmod request to Storage Accelerator
    int res = FuseInterface::static_accelerator_->chmodFile(path, mode);
    return res;
}

int FuseInterface::chown_callback(const char* path, uid_t uid, gid_t gid, struct fuse_file_info* fi) {
    // Forward chown request to Storage Accelerator
    int res = FuseInterface::static_accelerator_->chownFile(path, uid, gid);
    return res;
}

int FuseInterface::utimens_callback(const char* path, const struct timespec ts[2], struct fuse_file_info* fi) {
    // Forward utimens request to Storage Accelerator
    int res = FuseInterface::static_accelerator_->utimensFile(path, ts);
    return res;
}

void FuseInterface::run() {
    struct fuse_args args = FUSE_ARGS_INIT(0, nullptr);
    fuse_opt_add_arg(&args, "fuse_ssd_simulator");
    fuse_opt_add_arg(&args, mount_point_.c_str());

    struct fuse_operations operations;
    memset(&operations, 0, sizeof(operations));

    operations.getattr = FuseInterface::getattr_callback;
    operations.readdir = FuseInterface::readdir_callback;
    operations.open = FuseInterface::open_callback;
    operations.read = FuseInterface::read_callback;
    operations.write = FuseInterface::write_callback;
    operations.create = FuseInterface::create_callback;
    operations.unlink = FuseInterface::unlink_callback;
    operations.truncate = FuseInterface::truncate_callback;
    operations.mkdir = FuseInterface::mkdir_callback;
    operations.rmdir = FuseInterface::rmdir_callback;
    operations.rename = FuseInterface::rename_callback;
    operations.chmod = FuseInterface::chmod_callback;
    operations.chown = FuseInterface::chown_callback;
    operations.utimens = FuseInterface::utimens_callback;

    // Add more operations as needed

    // Run FUSE main loop
    fuse_main(args.argc, args.argv, &operations, nullptr);

    fuse_opt_free_args(&args);
}
EOL

# Create StorageAccelerator header and cpp
cat > include/storage_accelerator/storage_accelerator.h <<'EOL'
#pragma once

#include <vector>
#include <memory>
#include <string>
#include <unordered_map>
#include <mutex>
#include "ssd_simulator/ssd_simulator.h"
#include "../hashing/hashing_module.h"
#include "../metadata/metadata_manager.h"
#include "../logger/logger.h"

struct FileMetadata {
    mode_t mode;
    nlink_t nlink;
    uid_t uid;
    gid_t gid;
    off_t size;
    time_t atime;
    time_t mtime;
    time_t ctime;
    // Additional metadata as needed
};

class StorageAccelerator {
public:
    StorageAccelerator(int num_drives, const std::string& hash_seed);
    ~StorageAccelerator();

    // Filesystem operations
    int createFile(const std::string& path, mode_t mode);
    int createDirectory(const std::string& path, mode_t mode);
    int deleteFile(const std::string& path);
    int removeDirectory(const std::string& path);
    int renameFile(const std::string& from, const std::string& to, unsigned int flags);
    int chmodFile(const std::string& path, mode_t mode);
    int chownFile(const std::string& path, uid_t uid, gid_t gid);
    int truncateFile(const std::string& path, off_t size);
    int utimensFile(const std::string& path, const struct timespec ts[2]);

    ssize_t readFile(const std::string& path, char* buffer, size_t size, off_t offset);
    ssize_t writeFile(const std::string& path, const char* buffer, size_t size, off_t offset);

    // Metadata operations
    std::shared_ptr<FileMetadata> getMetadata(const std::string& path);
    std::vector<std::string> listDirectory(const std::string& path);

private:
    int num_drives_;
    std::unique_ptr<HashingModule> hashing_module_;
    std::vector<std::unique_ptr<SSD_Simulator>> drives_;
    std::unique_ptr<MetadataManager> metadata_manager_;
    Logger logger_;

    int getDriveIndex(const std::string& path);
    SSD_Simulator* getDrive(const std::string& path);
};
EOL

cat > src/storage_accelerator/storage_accelerator.cpp <<'EOL'
#include "storage_accelerator.h"

StorageAccelerator::StorageAccelerator(int num_drives, const std::string& hash_seed)
    : num_drives_(num_drives),
      hashing_module_(std::make_unique<HashingModule>(hash_seed)),
      metadata_manager_(std::make_unique<MetadataManager>()),
      logger_("StorageAccelerator") {
    logger_.info("Initializing Storage Accelerator with " + std::to_string(num_drives_) + " drives.");
    for (int i = 0; i < num_drives_; ++i) {
        drives_.emplace_back(std::make_unique<SSD_Simulator>(i, &logger_));
    }
}

StorageAccelerator::~StorageAccelerator() {
    logger_.info("Shutting down Storage Accelerator.");
    // Destructor will clean up SSD_Simulator instances
}

int StorageAccelerator::getDriveIndex(const std::string& path) {
    uint64_t hash = hashing_module_->hash(path);
    return hash % num_drives_;
}

SSD_Simulator* StorageAccelerator::getDrive(const std::string& path) {
    int index = getDriveIndex(path);
    logger_.debug("Path: " + path + " mapped to Drive " + std::to_string(index));
    return drives_[index].get();
}

int StorageAccelerator::createFile(const std::string& path, mode_t mode) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
    if (metadata_manager_->exists(path)) {
        logger_.error("Create File Failed: " + path + " already exists.");
        return -EEXIST;
    }

    // Create metadata
    FileMetadata metadata;
    metadata.mode = S_IFREG | mode;
    metadata.nlink = 1;
    metadata.uid = getuid();
    metadata.gid = getgid();
    metadata.size = 0;
    time(&metadata.atime);
    time(&metadata.mtime);
    time(&metadata.ctime);

    metadata_manager_->addMetadata(path, metadata);
    logger_.info("File created: " + path);

    return 0;
}

int StorageAccelerator::createDirectory(const std::string& path, mode_t mode) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
    if (metadata_manager_->exists(path)) {
        logger_.error("Create Directory Failed: " + path + " already exists.");
        return -EEXIST;
    }

    // Create metadata
    FileMetadata metadata;
    metadata.mode = S_IFDIR | mode;
    metadata.nlink = 2; // '.' and '..'
    metadata.uid = getuid();
    metadata.gid = getgid();
    metadata.size = 0;
    time(&metadata.atime);
    time(&metadata.mtime);
    time(&metadata.ctime);

    metadata_manager_->addMetadata(path, metadata);
    logger_.info("Directory created: " + path);

    return 0;
}

int StorageAccelerator::deleteFile(const std::string& path) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
    if (!metadata_manager_->exists(path)) {
        logger_.error("Delete File Failed: " + path + " does not exist.");
        return -ENOENT;
    }

    auto metadata = metadata_manager_->getMetadata(path);
    if ((metadata->mode & S_IFMT) != S_IFREG) {
        logger_.error("Delete File Failed: " + path + " is not a regular file.");
        return -EISDIR;
    }

    // Remove metadata
    metadata_manager_->removeMetadata(path);
    logger_.info("File deleted: " + path);

    return 0;
}

int StorageAccelerator::removeDirectory(const std::string& path) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
    if (!metadata_manager_->exists(path)) {
        logger_.error("Remove Directory Failed: " + path + " does not exist.");
        return -ENOENT;
    }

    auto metadata = metadata_manager_->getMetadata(path);
    if ((metadata->mode & S_IFMT) != S_IFDIR) {
        logger_.error("Remove Directory Failed: " + path + " is not a directory.");
        return -ENOTDIR;
    }

    // Check if directory is empty
    auto entries = metadata_manager_->listDirectory(path);
    if (!entries.empty()) {
        logger_.error("Remove Directory Failed: " + path + " is not empty.");
        return -ENOTEMPTY;
    }

    // Remove metadata
    metadata_manager_->removeMetadata(path);
    logger_.info("Directory removed: " + path);

    return 0;
}

int StorageAccelerator::renameFile(const std::string& from, const std::string& to, unsigned int flags) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
    if (!metadata_manager_->exists(from)) {
        logger_.error("Rename Failed: Source " + from + " does not exist.");
        return -ENOENT;
    }

    if (metadata_manager_->exists(to)) {
        logger_.error("Rename Failed: Destination " + to + " already exists.");
        return -EEXIST;
    }

    // Move metadata
    auto metadata = metadata_manager_->getMetadata(from);
    metadata_manager_->removeMetadata(from);
    metadata_manager_->addMetadata(to, *metadata);
    logger_.info("Renamed " + from + " to " + to);

    return 0;
}

int StorageAccelerator::chmodFile(const std::string& path, mode_t mode) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
    if (!metadata_manager_->exists(path)) {
        logger_.error("Chmod Failed: " + path + " does not exist.");
        return -ENOENT;
    }

    auto metadata = metadata_manager_->getMetadata(path);
    metadata->mode = (metadata->mode & S_IFMT) | mode;
    metadata->ctime = time(nullptr);

    logger_.info("Changed mode of " + path + " to " + std::to_string(mode));

    return 0;
}

int StorageAccelerator::chownFile(const std::string& path, uid_t uid, gid_t gid) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
    if (!metadata_manager_->exists(path)) {
        logger_.error("Chown Failed: " + path + " does not exist.");
        return -ENOENT;
    }

    auto metadata = metadata_manager_->getMetadata(path);
    metadata->uid = uid;
    metadata->gid = gid;
    metadata->ctime = time(nullptr);

    logger_.info("Changed owner of " + path + " to UID: " + std::to_string(uid) + ", GID: " + std::to_string(gid));

    return 0;
}

int StorageAccelerator::truncateFile(const std::string& path, off_t size) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
    if (!metadata_manager_->exists(path)) {
        logger_.error("Truncate Failed: " + path + " does not exist.");
        return -ENOENT;
    }

    auto metadata = metadata_manager_->getMetadata(path);
    if ((metadata->mode & S_IFMT) != S_IFREG) {
        logger_.error("Truncate Failed: " + path + " is not a regular file.");
        return -EISDIR;
    }

    metadata->size = size;
    metadata->mtime = time(nullptr);
    metadata->ctime = time(nullptr);

    // Optionally, inform the SSD simulator about the truncate operation
    getDrive(path)->truncate(path, size);

    logger_.info("Truncated file " + path + " to size " + std::to_string(size));

    return 0;
}

int StorageAccelerator::utimensFile(const std::string& path, const struct timespec ts[2]) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
    if (!metadata_manager_->exists(path)) {
        logger_.error("Utimens Failed: " + path + " does not exist.");
        return -ENOENT;
    }

    auto metadata = metadata_manager_->getMetadata(path);
    metadata->atime = ts[0].tv_sec;
    metadata->mtime = ts[1].tv_sec;

    logger_.info("Updated timestamps of " + path);

    return 0;
}

ssize_t StorageAccelerator::readFile(const std::string& path, char* buffer, size_t size, off_t offset) {
    // Find which SSD handles this file
    SSD_Simulator* drive = getDrive(path);

    // Forward read request to SSD
    ssize_t bytes_read = drive->readFile(path, buffer, size, offset);

    if (bytes_read >= 0) {
        // Update access time
        std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
        auto metadata = metadata_manager_->getMetadata(path);
        metadata->atime = time(nullptr);
    }

    return bytes_read;
}

ssize_t StorageAccelerator::writeFile(const std::string& path, const char* buffer, size_t size, off_t offset) {
    // Find which SSD handles this file
    SSD_Simulator* drive = getDrive(path);

    // Forward write request to SSD
    ssize_t bytes_written = drive->writeFile(path, buffer, size, offset);

    if (bytes_written >= 0) {
        // Update modification time and size
        std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
        auto metadata = metadata_manager_->getMetadata(path);
        metadata->mtime = time(nullptr);
        if (offset + size > metadata->size) {
            metadata->size = offset + size;
        }
    }

    return bytes_written;
}

std::shared_ptr<FileMetadata> StorageAccelerator::getMetadata(const std::string& path) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
    return metadata_manager_->getMetadata(path);
}

std::vector<std::string> StorageAccelerator::listDirectory(const std::string& path) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
    return metadata_manager_->listDirectory(path);
}
EOL

# Create HashingModule header and cpp
cat > include/hashing/hashing_module.h <<'EOL'
#pragma once

#include <string>
#include <cstdint>

class HashingModule {
public:
    HashingModule(const std::string& seed);
    uint64_t hash(const std::string& input) const;

private:
    uint64_t seed_;
};
EOL

cat > src/hashing/hashing_module.cpp <<'EOL'
#include "hashing_module.h"
#include <xxhash.h>

HashingModule::HashingModule(const std::string& seed_str) {
    // Convert seed string to uint64_t using XXH64
    seed_ = XXH64(seed_str.c_str(), seed_str.length(), 0);
}

uint64_t HashingModule::hash(const std::string& input) const {
    return XXH64(input.c_str(), input.length(), seed_);
}
EOL

# Download and include XXHash library
mkdir -p external
cd external
git clone https://github.com/Cyan4973/xxHash.git
cd ..
# Assume that XXHash is built and linked appropriately
# For simplicity, include the xxhash.h in the include directory
cp external/xxHash/xxhash.h include/hashing/
cp external/xxHash/xxhash.c src/hashing/
# Update CMakeLists.txt to include xxhash.c
sed -i '/file(GLOB SRC_FILES/a\    src/hashing/xxhash.c' CMakeLists.txt

# Create MetadataManager header and cpp
cat > include/metadata/metadata_manager.h <<'EOL'
#pragma once

#include <unordered_map>
#include <string>
#include <vector>
#include <memory>
#include <mutex>
#include "../storage_accelerator/storage_accelerator.h"

class MetadataManager {
public:
    MetadataManager();
    ~MetadataManager();

    void addMetadata(const std::string& path, const FileMetadata& metadata);
    void removeMetadata(const std::string& path);
    std::shared_ptr<FileMetadata> getMetadata(const std::string& path);
    bool exists(const std::string& path);
    std::vector<std::string> listDirectory(const std::string& path);

    std::mutex mutex_;
private:
    std::unordered_map<std::string, FileMetadata> metadata_map_;
};
EOL

cat > src/metadata/metadata_manager.cpp <<'EOL'
#include "metadata_manager.h"
#include <algorithm>

MetadataManager::MetadataManager() {
    // Initialize root directory
    FileMetadata root_metadata;
    root_metadata.mode = S_IFDIR | 0755;
    root_metadata.nlink = 2;
    root_metadata.uid = getuid();
    root_metadata.gid = getgid();
    root_metadata.size = 0;
    time(&root_metadata.atime);
    time(&root_metadata.mtime);
    time(&root_metadata.ctime);

    metadata_map_["/"] = root_metadata;
}

MetadataManager::~MetadataManager() {
    // Cleanup if necessary
}

void MetadataManager::addMetadata(const std::string& path, const FileMetadata& metadata) {
    metadata_map_[path] = metadata;
}

void MetadataManager::removeMetadata(const std::string& path) {
    metadata_map_.erase(path);
}

std::shared_ptr<FileMetadata> MetadataManager::getMetadata(const std::string& path) {
    auto it = metadata_map_.find(path);
    if (it != metadata_map_.end()) {
        return std::make_shared<FileMetadata>(it->second);
    }
    return nullptr;
}

bool MetadataManager::exists(const std::string& path) {
    return metadata_map_.find(path) != metadata_map_.end();
}

std::vector<std::string> MetadataManager::listDirectory(const std::string& path) {
    std::vector<std::string> entries;
    std::string prefix = path;
    if (prefix.back() != '/') {
        prefix += "/";
    }

    for (const auto& [key, value] : metadata_map_) {
        if (key.find(prefix) == 0 && key != prefix) {
            std::string remaining = key.substr(prefix.length());
            size_t pos = remaining.find('/');
            if (pos != std::string::npos) {
                remaining = remaining.substr(0, pos);
            }
            if (!remaining.empty() && std::find(entries.begin(), entries.end(), remaining) == entries.end()) {
                entries.push_back(remaining);
            }
        }
    }

    return entries;
}
EOL

# Create SSD_Simulator header and cpp
cat > include/ssd_simulator/ssd_simulator.h <<'EOL'
#pragma once

#include <string>
#include <queue>
#include <mutex>
#include <thread>
#include <condition_variable>
#include <unordered_map>
#include <vector>
#include "../logger/logger.h"

enum class IOType {
    CREATE,
    READ,
    WRITE,
    DELETE,
    TRUNCATE,
    MKDIR,
    RMDIR,
    RENAME,
    CHMOD,
    CHOWN,
    UTIMENS
};

struct IORequest {
    IOType type;
    std::string path;
    char* buffer;
    size_t size;
    off_t offset;
    mode_t mode;
    uid_t uid;
    gid_t gid;
    struct timespec ts[2];
    std::string new_path; // For rename
    unsigned int flags; // For rename
};

class SSD_Simulator {
public:
    SSD_Simulator(int drive_id, Logger* logger);
    ~SSD_Simulator();

    void enqueueIO(const IORequest& request);

    // SSD simulation methods
    ssize_t readFile(const std::string& path, char* buffer, size_t size, off_t offset);
    ssize_t writeFile(const std::string& path, const char* buffer, size_t size, off_t offset);
    void truncate(const std::string& path, off_t size);

private:
    int drive_id_;
    Logger* logger_;
    std::queue<IORequest> io_queue_;
    std::mutex queue_mutex_;
    std::condition_variable cv_;
    bool stop_;
    std::thread worker_thread_;

    // Simulated storage (for simplicity, use an in-memory map)
    std::unordered_map<std::string, std::vector<char>> storage_;
    std::mutex storage_mutex_;

    void processIO();
    void simulateLatency(IOType type);
};
EOL

cat > src/ssd_simulator/ssd_simulator.cpp <<'EOL'
#include "ssd_simulator.h"
#include <chrono>
#include <thread>

SSD_Simulator::SSD_Simulator(int drive_id, Logger* logger)
    : drive_id_(drive_id), logger_(logger), stop_(false) {
    logger_->info("Initializing SSD Simulator Drive " + std::to_string(drive_id_));
    worker_thread_ = std::thread(&SSD_Simulator::processIO, this);
}

SSD_Simulator::~SSD_Simulator() {
    {
        std::lock_guard<std::mutex> lock(queue_mutex_);
        stop_ = true;
    }
    cv_.notify_all();
    if (worker_thread_.joinable()) {
        worker_thread_.join();
    }
    logger_->info("Shutting down SSD Simulator Drive " + std::to_string(drive_id_));
}

void SSD_Simulator::enqueueIO(const IORequest& request) {
    {
        std::lock_guard<std::mutex> lock(queue_mutex_);
        io_queue_.push(request);
    }
    cv_.notify_one();
}

ssize_t SSD_Simulator::readFile(const std::string& path, char* buffer, size_t size, off_t offset) {
    IORequest request;
    request.type = IOType::READ;
    request.path = path;
    request.buffer = buffer;
    request.size = size;
    request.offset = offset;

    enqueueIO(request);

    // For simulation, assume immediate success
    // In a real scenario, you'd have to wait for the operation to complete
    return size;
}

ssize_t SSD_Simulator::writeFile(const std::string& path, const char* buffer, size_t size, off_t offset) {
    IORequest request;
    request.type = IOType::WRITE;
    request.path = path;
    request.buffer = const_cast<char*>(buffer); // Unsafe in real code
    request.size = size;
    request.offset = offset;

    enqueueIO(request);

    // For simulation, assume immediate success
    return size;
}

void SSD_Simulator::truncate(const std::string& path, off_t size) {
    IORequest request;
    request.type = IOType::TRUNCATE;
    request.path = path;
    request.size = size;

    enqueueIO(request);
}

void SSD_Simulator::processIO() {
    while (true) {
        IORequest request;
        {
            std::unique_lock<std::mutex> lock(queue_mutex_);
            cv_.wait(lock, [this]() { return !io_queue_.empty() || stop_; });
            if (stop_ && io_queue_.empty()) {
                break;
            }
            request = io_queue_.front();
            io_queue_.pop();
        }

        // Simulate latency based on IO type
        simulateLatency(request.type);

        // Process the IO request
        switch (request.type) {
            case IOType::CREATE:
                // Implement create logic
                logger_->info("Drive " + std::to_string(drive_id_) + " creating file: " + request.path);
                break;
            case IOType::READ: {
                std::lock_guard<std::mutex> lock(storage_mutex_);
                auto it = storage_.find(request.path);
                if (it != storage_.end()) {
                    size_t available = it->second.size() > static_cast<size_t>(request.offset) ? it->second.size() - request.offset : 0;
                    size_t to_read = std::min(request.size, available);
                    if (to_read > 0) {
                        memcpy(request.buffer, it->second.data() + request.offset, to_read);
                        logger_->info("Drive " + std::to_string(drive_id_) + " read " + std::to_string(to_read) + " bytes from " + request.path);
                    } else {
                        logger_->info("Drive " + std::to_string(drive_id_) + " read 0 bytes from " + request.path);
                    }
                } else {
                    logger_->error("Drive " + std::to_string(drive_id_) + " read failed: " + request.path + " does not exist.");
                }
                break;
            }
            case IOType::WRITE: {
                std::lock_guard<std::mutex> lock(storage_mutex_);
                auto& data = storage_[request.path];
                if (request.offset > data.size()) {
                    data.resize(request.offset, 0);
                }
                if (request.offset + request.size > data.size()) {
                    data.resize(request.offset + request.size);
                }
                memcpy(data.data() + request.offset, request.buffer, request.size);
                logger_->info("Drive " + std::to_string(drive_id_) + " wrote " + std::to_string(request.size) + " bytes to " + request.path);
                break;
            }
            case IOType::DELETE:
                // Implement delete logic
                logger_->info("Drive " + std::to_string(drive_id_) + " deleting file: " + request.path);
                break;
            case IOType::TRUNCATE: {
                std::lock_guard<std::mutex> lock(storage_mutex_);
                auto it = storage_.find(request.path);
                if (it != storage_.end()) {
                    it->second.resize(request.size, 0);
                    logger_->info("Drive " + std::to_string(drive_id_) + " truncated file: " + request.path + " to size " + std::to_string(request.size));
                } else {
                    logger_->error("Drive " + std::to_string(drive_id_) + " truncate failed: " + request.path + " does not exist.");
                }
                break;
            }
            case IOType::MKDIR:
                // Implement mkdir logic
                logger_->info("Drive " + std::to_string(drive_id_) + " creating directory: " + request.path);
                break;
            case IOType::RMDIR:
                // Implement rmdir logic
                logger_->info("Drive " + std::to_string(drive_id_) + " removing directory: " + request.path);
                break;
            case IOType::RENAME:
                // Implement rename logic
                logger_->info("Drive " + std::to_string(drive_id_) + " renaming from " + request.path + " to " + request.new_path);
                break;
            case IOType::CHMOD:
                // Implement chmod logic
                logger_->info("Drive " + std::to_string(drive_id_) + " changing mode of " + request.path);
                break;
            case IOType::CHOWN:
                // Implement chown logic
                logger_->info("Drive " + std::to_string(drive_id_) + " changing owner of " + request.path);
                break;
            case IOType::UTIMENS:
                // Implement utimens logic
                logger_->info("Drive " + std::to_string(drive_id_) + " updating timestamps of " + request.path);
                break;
            default:
                logger_->error("Drive " + std::to_string(drive_id_) + " received unknown IOType.");
                break;
        }
    }
}

void SSD_Simulator::simulateLatency(IOType type) {
    // Define latency in milliseconds based on IO type
    int latency_ms = 0;
    switch (type) {
        case IOType::CREATE:
        case IOType::DELETE:
        case IOType::MKDIR:
        case IOType::RMDIR:
        case IOType::CHMOD:
        case IOType::CHOWN:
        case IOType::UTIMENS:
            latency_ms = 1;
            break;
        case IOType::READ:
            latency_ms = 2;
            break;
        case IOType::WRITE:
            latency_ms = 3;
            break;
        case IOType::TRUNCATE:
            latency_ms = 2;
            break;
        case IOType::RENAME:
            latency_ms = 2;
            break;
        default:
            latency_ms = 1;
            break;
    }

    std::this_thread::sleep_for(std::chrono::milliseconds(latency_ms));
}
EOL

# Create MetadataManager header and cpp
# (Already created above)

# Create Logger header and cpp
cat > include/logger/logger.h <<'EOL'
#pragma once

#include <string>
#include <fstream>
#include <mutex>
#include <memory>

enum LogLevel {
    INFO,
    DEBUG,
    ERROR
};

class Logger {
public:
    Logger(const std::string& component);
    ~Logger();

    void info(const std::string& message);
    void debug(const std::string& message);
    void error(const std::string& message);

    static void init(const std::string& log_file);
    
private:
    std::string component_;
    std::ofstream log_stream_;
    std::mutex log_mutex_;
    static std::unique_ptr<std::ofstream> global_log_stream_;
    static std::mutex global_log_mutex_;

    void log(LogLevel level, const std::string& message);
};
EOL

cat > src/logger/logger.cpp <<'EOL'
#include "logger.h"
#include <iostream>
#include <chrono>
#include <ctime>

std::unique_ptr<std::ofstream> Logger::global_log_stream_ = nullptr;
std::mutex Logger::global_log_mutex_;

Logger::Logger(const std::string& component)
    : component_(component) {
    // Individual logger does not open the file, uses global logger
}

Logger::~Logger() {
    // Destructor
}

void Logger::init(const std::string& log_file) {
    std::lock_guard<std::mutex> lock(global_log_mutex_);
    if (!global_log_stream_) {
        global_log_stream_ = std::make_unique<std::ofstream>(log_file, std::ios::out | std::ios::app);
        if (!global_log_stream_->is_open()) {
            std::cerr << "Failed to open log file: " << log_file << std::endl;
            exit(1);
        }
    }
}

void Logger::info(const std::string& message) {
    log(INFO, message);
}

void Logger::debug(const std::string& message) {
    log(DEBUG, message);
}

void Logger::error(const std::string& message) {
    log(ERROR, message);
}

void Logger::log(LogLevel level, const std::string& message) {
    std::lock_guard<std::mutex> lock(global_log_mutex_);
    if (global_log_stream_ && global_log_stream_->is_open()) {
        // Get current time
        auto now = std::chrono::system_clock::now();
        std::time_t now_c = std::chrono::system_clock::to_time_t(now);

        // Convert LogLevel to string
        std::string level_str;
        switch (level) {
            case INFO:
                level_str = "INFO";
                break;
            case DEBUG:
                level_str = "DEBUG";
                break;
            case ERROR:
                level_str = "ERROR";
                break;
            default:
                level_str = "UNKNOWN";
                break;
        }

        // Write to log
        (*global_log_stream_) << "[" << std::ctime(&now_c) << "] [" << component_ << "] [" << level_str << "] " << message << std::endl;
    }
}
EOL

# Create FuseInterface header and cpp
# (Already created above)

# Create Monitoring components (Placeholder)
cat > include/monitoring/monitor.h <<'EOL'
#pragma once

#include "../storage_accelerator/storage_accelerator.h"
#include "../logger/logger.h"

class Monitor {
public:
    Monitor(std::shared_ptr<StorageAccelerator> accelerator, Logger* logger);
    void start();
    void stop();

private:
    std::shared_ptr<StorageAccelerator> accelerator_;
    Logger* logger_;
    bool running_;
    std::thread monitor_thread_;

    void monitorLoop();
};
EOL

cat > src/monitoring/monitor.cpp <<'EOL'
#include "monitor.h"
#include <chrono>
#include <iostream>

Monitor::Monitor(std::shared_ptr<StorageAccelerator> accelerator, Logger* logger)
    : accelerator_(accelerator), logger_(logger), running_(false) {}

void Monitor::start() {
    running_ = true;
    monitor_thread_ = std::thread(&Monitor::monitorLoop, this);
}

void Monitor::stop() {
    running_ = false;
    if (monitor_thread_.joinable()) {
        monitor_thread_.join();
    }
}

void Monitor::monitorLoop() {
    while (running_) {
        // Collect and log metrics
        // Placeholder for actual monitoring logic
        logger_->info("Monitoring system performance...");

        std::this_thread::sleep_for(std::chrono::seconds(5));
    }
}
EOL

# Create Utils (Placeholder for thread pool, etc.)
cat > include/utils/thread_pool.h <<'EOL'
#pragma once

#include <vector>
#include <thread>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <functional>
#include <future>
#include <atomic>

class ThreadPool {
public:
    ThreadPool(size_t threads);
    ~ThreadPool();

    // Submit a job to the thread pool
    template<class F, class... Args>
    auto enqueue(F&& f, Args&&... args)
        -> std::future<typename std::invoke_result<F, Args...>::type>;

private:
    // Workers
    std::vector<std::thread> workers_;

    // Task queue
    std::queue<std::function<void()>> tasks_;

    // Synchronization
    std::mutex queue_mutex_;
    std::condition_variable condition_;
    std::atomic<bool> stop_;
};

// Implementation of enqueue in the header
template<class F, class... Args>
auto ThreadPool::enqueue(F&& f, Args&&... args)
    -> std::future<typename std::invoke_result<F, Args...>::type> {
    using return_type = typename std::invoke_result<F, Args...>::type;

    auto task = std::make_shared< std::packaged_task<return_type()> >(
        std::bind(std::forward<F>(f), std::forward<Args>(args)...)
    );

    std::future<return_type> res = task->get_future();
    {
        std::lock_guard<std::mutex> lock(queue_mutex_);

        // Don't allow enqueueing after stopping the pool
        if (stop_) {
            throw std::runtime_error("enqueue on stopped ThreadPool");
        }

        tasks_.emplace([task](){ (*task)(); });
    }
    condition_.notify_one();
    return res;
}
EOL

cat > src/utils/thread_pool.cpp <<'EOL'
#include "thread_pool.h"

ThreadPool::ThreadPool(size_t threads)
    : stop_(false) {
    for (size_t i = 0; i < threads; ++i) {
        workers_.emplace_back(
            [this] {
                while (true) {
                    std::function<void()> task;

                    {
                        std::unique_lock<std::mutex> lock(this->queue_mutex_);
                        this->condition_.wait(lock,
                            [this]{ return this->stop_ || !this->tasks_.empty(); });
                        if (this->stop_ && this->tasks_.empty()) {
                            return;
                        }
                        task = std::move(this->tasks_.front());
                        this->tasks_.pop();
                    }

                    task();
                }
            }
        );
    }
}

ThreadPool::~ThreadPool() {
    stop_ = true;
    condition_.notify_all();
    for (std::thread &worker: workers_) {
        if (worker.joinable()) {
            worker.join();
        }
    }
}
EOL

# Create other utility files as needed (config, etc.)
# For brevity, not included here

# Create tests placeholder
cat > tests/test_storage_accelerator.cpp <<'EOL'
#include <gtest/gtest.h>
#include "../src/storage_accelerator/storage_accelerator.h"

TEST(StorageAcceleratorTest, CreateAndDeleteFile) {
    StorageAccelerator accelerator(4, "test_seed");
    int res = accelerator.createFile("/testfile", 0644);
    EXPECT_EQ(res, 0);

    auto metadata = accelerator.getMetadata("/testfile");
    ASSERT_NE(metadata, nullptr);
    EXPECT_EQ(metadata->mode, S_IFREG | 0644);

    res = accelerator.deleteFile("/testfile");
    EXPECT_EQ(res, 0);

    metadata = accelerator.getMetadata("/testfile");
    EXPECT_EQ(metadata, nullptr);
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
EOL

# Update CMakeLists.txt to include tests
cat >> CMakeLists.txt <<'EOL'

# Enable testing
enable_testing()

# Add Google Test
# Assuming Google Test is installed on the system
find_package(GTest REQUIRED)
include_directories(${GTEST_INCLUDE_DIRS})

# Add test executable
add_executable(run_tests tests/test_storage_accelerator.cpp)
target_link_libraries(run_tests ${GTEST_LIBRARIES} pthread)

add_test(NAME StorageAcceleratorTest COMMAND run_tests)
EOL

# Final messages
echo "Project setup complete."
echo "Navigate to the $PROJECT_NAME directory and run the following commands to build the project:"
echo "  mkdir build && cd build"
echo "  cmake .."
echo "  make"
echo "  sudo ./fuse_ssd_simulator <mount_point>"
echo ""
echo "Ensure you have the necessary dependencies installed (e.g., libfuse3-dev, cmake, g++, pthread)."
echo "Refer to the project documentation for further instructions on extending and running the simulator."
