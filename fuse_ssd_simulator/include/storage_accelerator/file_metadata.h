#pragma once

#include <sys/types.h>
#include <ctime>

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
