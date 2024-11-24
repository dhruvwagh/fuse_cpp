#include "storage_accelerator/storage_accelerator.h"
#include <filesystem>
#include <sys/stat.h>
#include <unistd.h>
#include <algorithm>

StorageAccelerator::StorageAccelerator(int num_drives, const std::string& hash_seed)
    : num_drives_(num_drives),
      hashing_module_(std::make_unique<HashingModule>(hash_seed)),
      metadata_manager_(std::make_unique<MetadataManager>()),
      load_balancer_(std::make_unique<LoadBalancer>(num_drives, &logger_)),
      logger_("StorageAccelerator") {
    
    logger_.info("Initializing Storage Accelerator with " + std::to_string(num_drives_) + " drives.");
    drives_.reserve(num_drives_);
    
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

    // Calculate the correct mode by preserving only the permission bits from the input mode
    // and adding the regular file type bit
    mode_t adjusted_mode = S_IFREG | (mode & 0777);

    // Debug log the modes
    logger_.debug("Creating file with requested mode: " + std::to_string(mode) + 
                 ", adjusted mode: " + std::to_string(adjusted_mode));

    FileMetadata metadata;
    metadata.mode = adjusted_mode;
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
    SSD_Simulator* drive = selectDrive(path, 0);
    if (drive) {
        auto promise_ptr = std::make_shared<IOPromise>();
        auto future = promise_ptr->promise.get_future();
        
        IORequest request;
        request.type = IOType::DELETE;
        request.path = path;
        request.promise = promise_ptr;
        drive->enqueueIO(request);
        
        // Wait for completion
        auto status = future.wait_for(std::chrono::seconds(5));
        if (status == std::future_status::timeout) {
            logger_.error("Delete operation timed out for " + path);
            return -ETIMEDOUT;
        }
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

    // Calculate the correct mode by preserving only the permission bits from the input mode
    // and adding the directory type bit
    mode_t adjusted_mode = S_IFDIR | (mode & 0777);

    // Debug log the modes
    logger_.debug("Creating directory with requested mode: " + std::to_string(mode) + 
                 ", adjusted mode: " + std::to_string(adjusted_mode));

    FileMetadata metadata;
    metadata.mode = adjusted_mode;
    metadata.nlink = 2;  // . and ..
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
    SSD_Simulator* src_drive = selectDrive(from, src_metadata->size);
    SSD_Simulator* dst_drive = selectDrive(to, src_metadata->size);
    
    if (src_drive != dst_drive && (src_metadata->mode & S_IFMT) == S_IFREG) {
        std::vector<char> buffer(BLOCK_SIZE);
        size_t total_moved = 0;
            
        while (total_moved < src_metadata->size) {
            size_t remaining = src_metadata->size - total_moved;
            size_t to_move = std::min(remaining, BLOCK_SIZE);
                
            // Read from source
            auto read_promise = std::make_shared<IOPromise>();
            auto read_future = read_promise->promise.get_future();
                
            IORequest read_req;
            read_req.type = IOType::READ;
            read_req.path = from;
            read_req.buffer = buffer.data();
            read_req.size = to_move;
            read_req.offset = total_moved;
            read_req.promise = read_promise;
                
            src_drive->enqueueIO(read_req);
                
            ssize_t bytes_read = read_future.get();
            if (bytes_read < 0) {
                logger_.error("Rename Failed: Error reading from source file");
                return -EIO;
            }
                
            // Write to destination
            auto write_promise = std::make_shared<IOPromise>();
            auto write_future = write_promise->promise.get_future();
                
            IORequest write_req;
            write_req.type = IOType::WRITE;
            write_req.path = to;
            write_req.buffer = buffer.data();
            write_req.size = bytes_read;
            write_req.offset = total_moved;
            write_req.promise = write_promise;
                
            dst_drive->enqueueIO(write_req);
                
            ssize_t bytes_written = write_future.get();
            if (bytes_written < 0) {
                logger_.error("Rename Failed: Error writing to destination file");
                return -EIO;
            }
                
            total_moved += bytes_written;
        }
            
        // Delete source file
        auto delete_promise = std::make_shared<IOPromise>();
        auto delete_future = delete_promise->promise.get_future();
            
        IORequest delete_req;
        delete_req.type = IOType::DELETE;
        delete_req.path = from;
        delete_req.promise = delete_promise;
            
        src_drive->enqueueIO(delete_req);
        delete_future.wait();
    }

    metadata_manager_->addMetadata(to, *src_metadata);
    metadata_manager_->removeMetadata(from);
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

    SSD_Simulator* drive = selectDrive(path, size);
    if (drive) {
        auto promise = std::make_shared<IOPromise>();
        auto future = promise->promise.get_future();
        
        IORequest request;
        request.type = IOType::TRUNCATE;
        request.path = path;
        request.size = size;
        request.promise = promise;
        
        drive->enqueueIO(request);
        
        // Wait for completion with timeout
        auto status = future.wait_for(std::chrono::seconds(5));
        if (status == std::future_status::timeout) {
            logger_.error("Truncate operation timed out for " + path);
            return -ETIMEDOUT;
        }
        
        ssize_t result = future.get();
        if (result < 0) {
            return result;
        }
    }

    metadata->size = size;
    metadata->mtime = time(nullptr);
    metadata->ctime = time(nullptr);

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
    auto metadata = getMetadata(path);
    if (!metadata) {
        logger_.error("Read Failed: " + path + " does not exist");
        return -ENOENT;
    }

    if (offset >= metadata->size) {
        return 0;  // EOF
    }

    ssize_t total_read = 0;
    size_t remaining = std::min(size, static_cast<size_t>(metadata->size - offset));

    // Process in blocks
    while (remaining > 0) {
        size_t block_size = std::min(remaining, BLOCK_SIZE);

        // Select drive based on block offset
        std::string block_key = path + ":" + std::to_string(offset + total_read);
        size_t primary_drive = getDriveIndex(block_key);
        size_t selected_drive = load_balancer_->selectDrive(primary_drive, block_size);
        
        // Start operation
        load_balancer_->startOperation(selected_drive);
        auto start_time = std::chrono::steady_clock::now();
        
        ssize_t bytes = drives_[selected_drive]->readFile(
            path,
            buffer + total_read,
            block_size,
            offset + total_read
        );

        if (bytes < 0) {
            logger_.error("Read Failed: Error reading from " + path + 
                         " on drive " + std::to_string(selected_drive));
            return bytes;
        }

        // Record operation stats
        auto duration = std::chrono::steady_clock::now() - start_time;
        load_balancer_->recordOperation(
            selected_drive,
            bytes,
            std::chrono::duration_cast<std::chrono::nanoseconds>(duration)
        );

        total_read += bytes;
        remaining -= bytes;
    }

  // Update access time
    {
        std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
        auto metadata = metadata_manager_->getMetadata(path);
        if (metadata) {
            metadata->atime = time(nullptr);
        }
    }
    
    return total_read;
}

ssize_t StorageAccelerator::writeFile(const std::string& path, const char* buffer, size_t size, off_t offset) {
    auto metadata = getMetadata(path);
    if (!metadata) {
        logger_.error("Write Failed: " + path + " does not exist");
        return -ENOENT;
    }

    ssize_t total_written = 0;
    size_t remaining = size;

    // Process in blocks
    while (remaining > 0) {
        size_t block_size = std::min(remaining, BLOCK_SIZE);
        
        // Select drive based on block offset
        std::string block_key = path + ":" + std::to_string(offset + total_written);
        size_t primary_drive = getDriveIndex(block_key);
        size_t selected_drive = load_balancer_->selectDrive(primary_drive, block_size);
        
        // Start operation
        load_balancer_->startOperation(selected_drive);
        auto start_time = std::chrono::steady_clock::now();
        
        ssize_t bytes = drives_[selected_drive]->writeFile(
            path,
            buffer + total_written,
            block_size,
            offset + total_written
        );

        if (bytes < 0) {
            logger_.error("Write Failed: Error writing to " + path + 
                         " on drive " + std::to_string(selected_drive));
            return bytes;
        }

        // Record operation stats
        auto duration = std::chrono::steady_clock::now() - start_time;
        load_balancer_->recordOperation(
            selected_drive,
            bytes,
            std::chrono::duration_cast<std::chrono::nanoseconds>(duration)
        );

        total_written += bytes;
        remaining -= bytes;
    }

    // Update metadata
    {
        std::lock_guard<std::mutex> lock(metadata_manager_->mutex_);
        auto metadata = metadata_manager_->getMetadata(path);
        if (metadata) {
            metadata->mtime = time(nullptr);
            if (offset + total_written > metadata->size) {
                metadata->size = offset + total_written;
            }
        }
    }
    
    return total_written;
}

int StorageAccelerator::getDriveIndex(const std::string& path) {
    uint64_t hash = hashing_module_->hash(path);
    return hash % num_drives_;
}

SSD_Simulator* StorageAccelerator::selectDrive(const std::string& path, size_t size) {
    int primary_index = getDriveIndex(path);
    size_t selected_index = load_balancer_->selectDrive(primary_index, size);
    logger_.debug("Selected drive " + std::to_string(selected_index) + 
                 " for path: " + path);
    return drives_[selected_index].get();
}

SSD_Simulator* StorageAccelerator::getDrive(const std::string& path) {
    int index = getDriveIndex(path);
    logger_.debug("Path: " + path + " mapped to Drive " + std::to_string(index));
    return drives_[index].get();
}