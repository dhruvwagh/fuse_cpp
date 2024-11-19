#pragma once

#include <unordered_map>
#include <string>
#include <vector>
#include <memory>
#include <mutex>
#include "../storage_accelerator/file_metadata.h"

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