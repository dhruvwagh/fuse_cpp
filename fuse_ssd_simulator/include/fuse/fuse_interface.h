#pragma once

#include <string>
#include <memory>
#include "storage_accelerator/storage_accelerator.h"
#include "logger/logger.h"
#include <fuse.h>
#include <sys/stat.h>

class FuseInterface {
public:
    FuseInterface(const std::string& mount_point, std::shared_ptr<StorageAccelerator> accelerator);
    void cleanup();
    void run(int argc, char* argv[]);

private:
    std::string mount_point_;
    std::shared_ptr<StorageAccelerator> accelerator_;
    
    static StorageAccelerator* static_accelerator_;
    static Logger* static_logger_;

    // FUSE callback functions
    static int getattr_callback(const char* path, struct stat* stbuf, 
                              struct fuse_file_info* fi);
    
    static int readdir_callback(const char* path, void* buf,
                              fuse_fill_dir_t filler, off_t offset,
                              struct fuse_file_info* fi, 
                              enum fuse_readdir_flags flags);
    
    static int open_callback(const char* path, struct fuse_file_info* fi);
    
    static int read_callback(const char* path, char* buf, size_t size,
                           off_t offset, struct fuse_file_info* fi);
    
    static int write_callback(const char* path, const char* buf,
                            size_t size, off_t offset,
                            struct fuse_file_info* fi);
    
    static int create_callback(const char* path, mode_t mode,
                             struct fuse_file_info* fi);
    
    static int unlink_callback(const char* path);
    
    static int truncate_callback(const char* path, off_t size,
                               struct fuse_file_info* fi);
    
    static int mkdir_callback(const char* path, mode_t mode);
    
    static int rmdir_callback(const char* path);
    
    static int rename_callback(const char* from, const char* to, unsigned int flags);
    
    static int chmod_callback(const char* path, mode_t mode, struct fuse_file_info* fi);
    
    static int chown_callback(const char* path, uid_t uid, gid_t gid, 
                            struct fuse_file_info* fi);
    
    static int utimens_callback(const char* path,
                              const struct timespec ts[2],
                              struct fuse_file_info* fi);
};