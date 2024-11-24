#pragma once

#include <vector>
#include <memory>
#include <string>
#include <unordered_map>
#include <mutex>
#include "ssd_simulator/ssd_simulator.h"
#include "../hashing/hashing_module.h"
#include "../metadata/metadata_manager.h"
#include "load_balancer.h"
#include "../logger/logger.h"
#include "file_metadata.h"

class StorageAccelerator {
public:
    StorageAccelerator(int num_drives, const std::string& hash_seed);
    ~StorageAccelerator();

    // File operations
    int createFile(const std::string& path, mode_t mode);
    int deleteFile(const std::string& path);
    int truncateFile(const std::string& path, off_t size);
    ssize_t readFile(const std::string& path, char* buffer, size_t size, off_t offset);
    ssize_t writeFile(const std::string& path, const char* buffer, size_t size, off_t offset);

    // Directory operations
    int createDirectory(const std::string& path, mode_t mode);
    int removeDirectory(const std::string& path);
    std::vector<std::string> listDirectory(const std::string& path);

    // Metadata operations
    int renameFile(const std::string& from, const std::string& to, unsigned int flags);
    int chmodFile(const std::string& path, mode_t mode);
    int chownFile(const std::string& path, uid_t uid, gid_t gid);
    int utimensFile(const std::string& path, const struct timespec ts[2]);
    std::shared_ptr<FileMetadata> getMetadata(const std::string& path);

private:
    static constexpr size_t BLOCK_SIZE = 4096;
    
    int num_drives_;
    std::unique_ptr<HashingModule> hashing_module_;
    std::unique_ptr<LoadBalancer> load_balancer_;
    std::vector<std::unique_ptr<SSD_Simulator>> drives_;
    std::unique_ptr<MetadataManager> metadata_manager_;
    Logger logger_;

    int getDriveIndex(const std::string& path);
    SSD_Simulator* getDrive(const std::string& path);
    SSD_Simulator* selectDrive(const std::string& path, size_t size);
};