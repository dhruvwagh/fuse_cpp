#include "storage_accelerator/storage_accelerator.h"
#include <filesystem>
#include <sys/stat.h>
#include <unistd.h>

StorageAccelerator::StorageAccelerator(int num_drives, const std::string& hash_seed)
    : num_drives_(num_drives),
      hashing_module_(std::make_unique<HashingModule>(hash_seed)),
      metadata_manager_(std::make_unique<MetadataManager>()),
      logger_("StorageAccelerator") {
    
    logger_.info("Initializing Storage Accelerator with " + std::to_string(num_drives_) + " drives.");
    drives_.reserve(num_drives_);  // Reserve space to avoid reallocations
    
    // Initialize drives
    for (int i = 0; i < num_drives_; ++i) {
        logger_.info("Initializing SSD Simulator Drive " + std::to_string(i));
        drives_.emplace_back(std::make_unique<SSD_Simulator>(i, &logger_));
    }
}

StorageAccelerator::~StorageAccelerator() {
    logger_.info("Shutting down Storage Accelerator.");
}

std::shared_ptr<FileMetadata> StorageAccelerator::getMetadata(const std::string& path) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
    return metadata_manager_->getMetadata(path);
}

std::vector<std::string> StorageAccelerator::listDirectory(const std::string& path) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
    return metadata_manager_->listDirectory(path);
}

int StorageAccelerator::createFile(const std::string& path, mode_t mode) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
    
    if (metadata_manager_->exists(path)) {
        logger_.error("Create File Failed: " + path + " already exists");
        return -EEXIST;
    }

    FileMetadata metadata;
    metadata.mode = S_IFREG | (mode & 07777);  // Regular file with specified permissions
    metadata.nlink = 1;
    metadata.uid = getuid();
    metadata.gid = getgid();
    metadata.size = 0;
    metadata.atime = time(nullptr);
    metadata.mtime = metadata.atime;
    metadata.ctime = metadata.atime;

    metadata_manager_->addMetadata(path, metadata);
    logger_.info("File created: " + path);
    return 0;
}

int StorageAccelerator::deleteFile(const std::string& path) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);

    auto metadata = metadata_manager_->getMetadata(path);
    if (!metadata) {
        logger_.error("Delete File Failed: " + path + " does not exist");
        return -ENOENT;
    }

    if ((metadata->mode & S_IFMT) != S_IFREG) {
        logger_.error("Delete File Failed: " + path + " is not a regular file");
        return -EISDIR;
    }

    // Clean up file data from the drive
    SSD_Simulator* drive = getDrive(path);
    if (drive) {
        IORequest request;
        request.type = IOType::DELETE;
        request.path = path;
        drive->enqueueIO(request);
    }

    metadata_manager_->removeMetadata(path);
    logger_.info("File deleted: " + path);
    return 0;
}

int StorageAccelerator::createDirectory(const std::string& path, mode_t mode) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);

    if (metadata_manager_->exists(path)) {
        logger_.error("Create Directory Failed: " + path + " already exists");
        return -EEXIST;
    }

    FileMetadata metadata;
    metadata.mode = S_IFDIR | (mode & 07777);  // Directory with specified permissions
    metadata.nlink = 2;  // "." and ".."
    metadata.uid = getuid();
    metadata.gid = getgid();
    metadata.size = 0;
    metadata.atime = time(nullptr);
    metadata.mtime = metadata.atime;
    metadata.ctime = metadata.atime;

    metadata_manager_->addMetadata(path, metadata);
    logger_.info("Directory created: " + path);
    return 0;
}

int StorageAccelerator::removeDirectory(const std::string& path) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);

    auto metadata = metadata_manager_->getMetadata(path);
    if (!metadata) {
        logger_.error("Remove Directory Failed: " + path + " does not exist");
        return -ENOENT;
    }

    if ((metadata->mode & S_IFMT) != S_IFDIR) {
        logger_.error("Remove Directory Failed: " + path + " is not a directory");
        return -ENOTDIR;
    }

    auto entries = metadata_manager_->listDirectory(path);
    if (!entries.empty()) {
        logger_.error("Remove Directory Failed: " + path + " is not empty");
        return -ENOTEMPTY;
    }

    metadata_manager_->removeMetadata(path);
    logger_.info("Directory removed: " + path);
    return 0;
}

int StorageAccelerator::renameFile(const std::string& from, const std::string& to, unsigned int flags) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);

    auto src_metadata = metadata_manager_->getMetadata(from);
    if (!src_metadata) {
        logger_.error("Rename Failed: Source " + from + " does not exist");
        return -ENOENT;
    }

    if (metadata_manager_->exists(to)) {
        logger_.error("Rename Failed: Destination " + to + " already exists");
        return -EEXIST;
    }

    // Move the data between drives if necessary
    SSD_Simulator* src_drive = getDrive(from);
    SSD_Simulator* dst_drive = getDrive(to);
    
    if (src_drive != dst_drive) {
        // Need to move data between drives
        if ((src_metadata->mode & S_IFMT) == S_IFREG) {
            char buffer[4096];
            size_t total_read = 0;
            while (total_read < src_metadata->size) {
                size_t to_read = std::min(sizeof(buffer), static_cast<size_t>(src_metadata->size - total_read));
                ssize_t read = src_drive->readFile(from, buffer, to_read, total_read);
                if (read < 0) {
                    logger_.error("Rename Failed: Error reading from source file");
                    return -EIO;
                }
                
                ssize_t written = dst_drive->writeFile(to, buffer, read, total_read);
                if (written < 0) {
                    logger_.error("Rename Failed: Error writing to destination file");
                    return -EIO;
                }
                
                total_read += read;
            }
        }
    }

    metadata_manager_->addMetadata(to, *src_metadata);
    metadata_manager_->removeMetadata(from);

    // Clean up old file if drives are different
    if (src_drive != dst_drive) {
        IORequest request;
        request.type = IOType::DELETE;
        request.path = from;
        src_drive->enqueueIO(request);
    }

    logger_.info("Renamed " + from + " to " + to);
    return 0;
}

int StorageAccelerator::chmodFile(const std::string& path, mode_t mode) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);

    auto metadata = metadata_manager_->getMetadata(path);
    if (!metadata) {
        logger_.error("Chmod Failed: " + path + " does not exist");
        return -ENOENT;
    }

    metadata->mode = (metadata->mode & S_IFMT) | (mode & 07777);
    metadata->ctime = time(nullptr);

    logger_.info("Changed mode of " + path + " to " + std::to_string(mode));
    return 0;
}

int StorageAccelerator::chownFile(const std::string& path, uid_t uid, gid_t gid) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);

    auto metadata = metadata_manager_->getMetadata(path);
    if (!metadata) {
        logger_.error("Chown Failed: " + path + " does not exist");
        return -ENOENT;
    }

    metadata->uid = uid;
    metadata->gid = gid;
    metadata->ctime = time(nullptr);

    logger_.info("Changed owner of " + path + " to UID: " + std::to_string(uid) + 
                ", GID: " + std::to_string(gid));
    return 0;
}

int StorageAccelerator::truncateFile(const std::string& path, off_t size) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);

    auto metadata = metadata_manager_->getMetadata(path);
    if (!metadata) {
        logger_.error("Truncate Failed: " + path + " does not exist");
        return -ENOENT;
    }

    if ((metadata->mode & S_IFMT) != S_IFREG) {
        logger_.error("Truncate Failed: " + path + " is not a regular file");
        return -EISDIR;
    }

    metadata->size = size;
    metadata->mtime = time(nullptr);
    metadata->ctime = time(nullptr);

    // Tell the drive to truncate the file
    SSD_Simulator* drive = getDrive(path);
    if (drive) {
        IORequest request;
        request.type = IOType::TRUNCATE;
        request.path = path;
        request.size = size;
        drive->enqueueIO(request);
    }

    logger_.info("Truncated " + path + " to size " + std::to_string(size));
    return 0;
}

int StorageAccelerator::utimensFile(const std::string& path, const struct timespec ts[2]) {
    std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);

    auto metadata = metadata_manager_->getMetadata(path);
    if (!metadata) {
        logger_.error("Utimens Failed: " + path + " does not exist");
        return -ENOENT;
    }

    metadata->atime = ts[0].tv_sec;
    metadata->mtime = ts[1].tv_sec;

    logger_.info("Updated timestamps of " + path);
    return 0;
}

ssize_t StorageAccelerator::readFile(const std::string& path, char* buffer, size_t size, off_t offset) {
    // Get the appropriate drive
    SSD_Simulator* drive = getDrive(path);
    if (!drive) {
        logger_.error("Read Failed: Could not find drive for " + path);
        return -EIO;
    }

    ssize_t bytes_read = drive->readFile(path, buffer, size, offset);

    if (bytes_read >= 0) {
        // Update access time
        std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
        auto metadata = metadata_manager_->getMetadata(path);
        if (metadata) {
            metadata->atime = time(nullptr);
        }
        logger_.info("Read " + std::to_string(bytes_read) + " bytes from " + path);
    } else {
        logger_.error("Read Failed: Error reading from " + path);
    }

    return bytes_read;
}

ssize_t StorageAccelerator::writeFile(const std::string& path, const char* buffer, size_t size, off_t offset) {
    // Get the appropriate drive
    SSD_Simulator* drive = getDrive(path);
    if (!drive) {
        logger_.error("Write Failed: Could not find drive for " + path);
        return -EIO;
    }

    ssize_t bytes_written = drive->writeFile(path, buffer, size, offset);

    if (bytes_written >= 0) {
        // Update modification time and size
        std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
        auto metadata = metadata_manager_->getMetadata(path);
        if (metadata) {
            metadata->mtime = time(nullptr);
            if (offset + bytes_written > metadata->size) {
                metadata->size = offset + bytes_written;
            }
        }
        logger_.info("Wrote " + std::to_string(bytes_written) + " bytes to " + path);
    } else {
        logger_.error("Write Failed: Error writing to " + path);
    }

    return bytes_written;
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