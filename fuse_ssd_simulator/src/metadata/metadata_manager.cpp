#include "metadata/metadata_manager.h"
#include <algorithm>
#include <sys/stat.h> // For S_IFDIR
#include <unistd.h>   // For getuid(), getgid()


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
