#include "fuse_interface.h"
#include <cstring>
#include <iostream>
#include <unistd.h>
#include <sys/mount.h>

void FuseInterface::cleanup() {
    if (static_logger_) {
        static_logger_->info("Cleaning up FUSE interface...");
    }

    // Try to unmount gracefully
    if (!mount_point_.empty()) {
        // First try fusermount
        std::string cmd = "fusermount -u " + mount_point_;
        if (system(cmd.c_str()) != 0) {
            // If that fails, try force unmount
            umount2(mount_point_.c_str(), MNT_FORCE);
        }
    }

    // Clean up logger
    if (static_logger_) {
        static_logger_->info("Cleanup complete");
        delete static_logger_;
        static_logger_ = nullptr;
    }

    // Reset static accelerator pointer
    static_accelerator_ = nullptr;
}