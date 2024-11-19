#include "fuse_interface.h"
#include <cstring>
#include <iostream>
#include <vector>
#include <unistd.h>
#include <sys/mount.h>

// Initialize static members
StorageAccelerator* FuseInterface::static_accelerator_ = nullptr;
Logger* FuseInterface::static_logger_ = nullptr;

FuseInterface::FuseInterface(const std::string& mount_point, std::shared_ptr<StorageAccelerator> accelerator)
    : mount_point_(mount_point), accelerator_(accelerator) {
    static_accelerator_ = accelerator_.get();
    static_logger_ = new Logger("FUSE_Interface");
}

void FuseInterface::cleanup() {
    if (static_logger_) {
        static_logger_->info("Cleaning up FUSE interface...");
    }

    if (!mount_point_.empty()) {
        std::string cmd = "fusermount -u " + mount_point_;
        system(cmd.c_str());
    }

    if (static_logger_) {
        delete static_logger_;
        static_logger_ = nullptr;
    }
    
    static_accelerator_ = nullptr;
}

void FuseInterface::run(int argc, char* argv[]) {
    struct fuse_args args = FUSE_ARGS_INIT(0, nullptr);

    if (argc > 0 && argv != nullptr) {
        args = FUSE_ARGS_INIT(argc, argv);
    } else {
        fuse_opt_add_arg(&args, "fuse_ssd_simulator");
        fuse_opt_add_arg(&args, mount_point_.c_str());
        fuse_opt_add_arg(&args, "-o");
        fuse_opt_add_arg(&args, "default_permissions");
        fuse_opt_add_arg(&args, "-o");
        fuse_opt_add_arg(&args, "allow_other");
    }

    struct fuse_operations operations = {};
    operations.getattr = getattr_callback;
    operations.readdir = readdir_callback;
    operations.open = open_callback;
    operations.read = read_callback;
    operations.write = write_callback;
    operations.create = create_callback;
    operations.unlink = unlink_callback;
    operations.truncate = truncate_callback;
    operations.mkdir = mkdir_callback;
    operations.rmdir = rmdir_callback;
    operations.rename = rename_callback;
    operations.chmod = chmod_callback;
    operations.chown = chown_callback;
    operations.utimens = utimens_callback;

    int ret = fuse_main(args.argc, args.argv, &operations, nullptr);
    fuse_opt_free_args(&args);

    if (ret != 0) {
        static_logger_->error("FUSE main loop failed with error code: " + std::to_string(ret));
    }
}


// FUSE Operation Implementations

int FuseInterface::getattr_callback(const char* path, struct stat* stbuf, struct fuse_file_info* fi) {
    memset(stbuf, 0, sizeof(struct stat));

    if (strcmp(path, "/") == 0) {
        stbuf->st_mode = S_IFDIR | 0755;
        stbuf->st_nlink = 2;
        return 0;
    }

    auto metadata = static_accelerator_->getMetadata(path);
    if (!metadata) {
        return -ENOENT;
    }

    stbuf->st_mode = metadata->mode;
    stbuf->st_nlink = metadata->nlink;
    stbuf->st_size = metadata->size;
    stbuf->st_uid = metadata->uid;
    stbuf->st_gid = metadata->gid;
    stbuf->st_atime = metadata->atime;
    stbuf->st_mtime = metadata->mtime;
    stbuf->st_ctime = metadata->ctime;

    return 0;
}

int FuseInterface::readdir_callback(const char* path, void* buf, fuse_fill_dir_t filler,
                                  off_t offset, struct fuse_file_info* fi, enum fuse_readdir_flags flags) {
    filler(buf, ".", nullptr, 0, static_cast<fuse_fill_dir_flags>(0));
    filler(buf, "..", nullptr, 0, static_cast<fuse_fill_dir_flags>(0));

    auto entries = static_accelerator_->listDirectory(path);
    for (const auto& entry : entries) {
        filler(buf, entry.c_str(), nullptr, 0, static_cast<fuse_fill_dir_flags>(0));
    }

    return 0;
}

int FuseInterface::create_callback(const char* path, mode_t mode, struct fuse_file_info* fi) {
    static_logger_->info("Creating file: " + std::string(path) + " with mode: " + std::to_string(mode));
    
    // Add execute permission for directories
    mode_t adjusted_mode = mode | 0666;  // rw-rw-rw-
    
    int res = static_accelerator_->createFile(path, adjusted_mode);
    if (res < 0) {
        return res;
    }

    // Open the file after creating it
    return open_callback(path, fi);
}

int FuseInterface::mkdir_callback(const char* path, mode_t mode) {
    static_logger_->info("Creating directory: " + std::string(path));
    return static_accelerator_->createDirectory(path, mode);
}

int FuseInterface::unlink_callback(const char* path) {
    static_logger_->info("Deleting file: " + std::string(path));
    return static_accelerator_->deleteFile(path);
}

int FuseInterface::read_callback(const char* path, char* buf, size_t size, off_t offset,
                               struct fuse_file_info* fi) {
    return static_accelerator_->readFile(path, buf, size, offset);
}

int FuseInterface::write_callback(const char* path, const char* buf, size_t size,
                              off_t offset, struct fuse_file_info* fi) {
    static_logger_->info("Writing to file: " + std::string(path) + " size: " + std::to_string(size));
    return static_accelerator_->writeFile(path, buf, size, offset);
}

int FuseInterface::open_callback(const char* path, struct fuse_file_info* fi) {
    static_logger_->info("Opening file: " + std::string(path));
    
    auto metadata = static_accelerator_->getMetadata(path);
    if (!metadata) {
        return -ENOENT;
    }
    
    // Set file handle to non-zero value to indicate it's open
    fi->fh = 1;
    return 0;
}

int FuseInterface::truncate_callback(const char* path, off_t size, struct fuse_file_info* fi) {
    return static_accelerator_->truncateFile(path, size);
}

int FuseInterface::rmdir_callback(const char* path) {
    return static_accelerator_->removeDirectory(path);
}

int FuseInterface::rename_callback(const char* from, const char* to, unsigned int flags) {
    return static_accelerator_->renameFile(from, to, flags);
}

int FuseInterface::chmod_callback(const char* path, mode_t mode, struct fuse_file_info* fi) {
    return static_accelerator_->chmodFile(path, mode);
}

int FuseInterface::chown_callback(const char* path, uid_t uid, gid_t gid, struct fuse_file_info* fi) {
    return static_accelerator_->chownFile(path, uid, gid);
}

int FuseInterface::utimens_callback(const char* path, const struct timespec ts[2], struct fuse_file_info* fi) {
    return static_accelerator_->utimensFile(path, ts);
}