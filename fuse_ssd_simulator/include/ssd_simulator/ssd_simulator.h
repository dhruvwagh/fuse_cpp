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
