#pragma once

#include <string>
#include <queue>
#include <mutex>
#include <thread>
#include <condition_variable>
#include <unordered_map>
#include <vector>
#include <future>
#include <shared_mutex>
#include "../logger/logger.h"

// Forward declare the class
class SSD_Simulator;

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

struct IOPromise {
    std::promise<ssize_t> promise;
    std::chrono::steady_clock::time_point start_time;
    
    IOPromise() : start_time(std::chrono::steady_clock::now()) {}
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
    unsigned int flags;   // For rename
    std::shared_ptr<IOPromise> promise; // For operation completion
};

// Now define the class
class SSD_Simulator {
public:
    SSD_Simulator(int drive_id, Logger* logger);
    ~SSD_Simulator();

    void enqueueIO(const IORequest& request);
    ssize_t readFile(const std::string& path, char* buffer, size_t size, off_t offset);
    ssize_t writeFile(const std::string& path, const char* buffer, size_t size, off_t offset);
    void truncate(const std::string& path, off_t size);

    // Constants
    static constexpr size_t BLOCK_SIZE = 4096;
    static constexpr size_t MAX_QUEUE_SIZE = 1000;

private:
    int drive_id_;
    Logger* logger_;
    std::queue<IORequest> io_queue_;
    std::mutex queue_mutex_;
    std::condition_variable cv_;
    bool stop_;
    std::thread worker_thread_;

    // Use shared mutex for better read concurrency
    std::shared_mutex storage_mutex_;
    std::unordered_map<std::string, std::vector<char>> storage_;

    void processIO();
    void simulateLatency(IOType type);
    bool isQueueFull() const { return io_queue_.size() >= MAX_QUEUE_SIZE; }
};