#include "ssd_simulator/ssd_simulator.h"
#include <chrono>
#include <thread>
#include <cstring>


SSD_Simulator::SSD_Simulator(int drive_id, Logger* logger)
    : drive_id_(drive_id), logger_(logger), stop_(false) {
    logger_->info("Initializing SSD Simulator Drive " + std::to_string(drive_id_));
    worker_thread_ = std::thread(&SSD_Simulator::processIO, this);
}

SSD_Simulator::~SSD_Simulator() {
    {
        std::lock_guard<std::mutex> lock(queue_mutex_);
        stop_ = true;
    }
    cv_.notify_all();
    if (worker_thread_.joinable()) {
        worker_thread_.join();
    }
    logger_->info("Shutting down SSD Simulator Drive " + std::to_string(drive_id_));
}

void SSD_Simulator::enqueueIO(const IORequest& request) {
    {
        std::lock_guard<std::mutex> lock(queue_mutex_);
        io_queue_.push(request);
    }
    cv_.notify_one();
}

ssize_t SSD_Simulator::readFile(const std::string& path, char* buffer, size_t size, off_t offset) {
    IORequest request;
    request.type = IOType::READ;
    request.path = path;
    request.buffer = buffer;
    request.size = size;
    request.offset = offset;

    enqueueIO(request);

    // For simulation, assume immediate success
    // In a real scenario, you'd have to wait for the operation to complete
    return size;
}

ssize_t SSD_Simulator::writeFile(const std::string& path, const char* buffer, size_t size, off_t offset) {
    IORequest request;
    request.type = IOType::WRITE;
    request.path = path;
    request.buffer = const_cast<char*>(buffer); // Unsafe in real code
    request.size = size;
    request.offset = offset;

    enqueueIO(request);

    // For simulation, assume immediate success
    return size;
}

void SSD_Simulator::truncate(const std::string& path, off_t size) {
    IORequest request;
    request.type = IOType::TRUNCATE;
    request.path = path;
    request.size = size;

    enqueueIO(request);
}

void SSD_Simulator::processIO() {
    while (true) {
        IORequest request;
        {
            std::unique_lock<std::mutex> lock(queue_mutex_);
            cv_.wait(lock, [this]() { return !io_queue_.empty() || stop_; });
            if (stop_ && io_queue_.empty()) {
                break;
            }
            request = io_queue_.front();
            io_queue_.pop();
        }

        // Simulate latency based on IO type
        simulateLatency(request.type);

        // Process the IO request
        switch (request.type) {
            case IOType::CREATE:
                // Implement create logic
                logger_->info("Drive " + std::to_string(drive_id_) + " creating file: " + request.path);
                break;
            case IOType::READ: {
                std::lock_guard<std::mutex> lock(storage_mutex_);
                auto it = storage_.find(request.path);
                if (it != storage_.end()) {
                    size_t available = it->second.size() > static_cast<size_t>(request.offset) ? it->second.size() - request.offset : 0;
                    size_t to_read = std::min(request.size, available);
                    if (to_read > 0) {
                        memcpy(request.buffer, it->second.data() + request.offset, to_read);
                        logger_->info("Drive " + std::to_string(drive_id_) + " read " + std::to_string(to_read) + " bytes from " + request.path);
                    } else {
                        logger_->info("Drive " + std::to_string(drive_id_) + " read 0 bytes from " + request.path);
                    }
                } else {
                    logger_->error("Drive " + std::to_string(drive_id_) + " read failed: " + request.path + " does not exist.");
                }
                break;
            }
            case IOType::WRITE: {
                std::lock_guard<std::mutex> lock(storage_mutex_);
                auto& data = storage_[request.path];
                if (request.offset > data.size()) {
                    data.resize(request.offset, 0);
                }
                if (request.offset + request.size > data.size()) {
                    data.resize(request.offset + request.size);
                }
                memcpy(data.data() + request.offset, request.buffer, request.size);
                logger_->info("Drive " + std::to_string(drive_id_) + " wrote " + std::to_string(request.size) + " bytes to " + request.path);
                break;
            }
            case IOType::DELETE:
                // Implement delete logic
                logger_->info("Drive " + std::to_string(drive_id_) + " deleting file: " + request.path);
                break;
            case IOType::TRUNCATE: {
                std::lock_guard<std::mutex> lock(storage_mutex_);
                auto it = storage_.find(request.path);
                if (it != storage_.end()) {
                    it->second.resize(request.size, 0);
                    logger_->info("Drive " + std::to_string(drive_id_) + " truncated file: " + request.path + " to size " + std::to_string(request.size));
                } else {
                    logger_->error("Drive " + std::to_string(drive_id_) + " truncate failed: " + request.path + " does not exist.");
                }
                break;
            }
            case IOType::MKDIR:
                // Implement mkdir logic
                logger_->info("Drive " + std::to_string(drive_id_) + " creating directory: " + request.path);
                break;
            case IOType::RMDIR:
                // Implement rmdir logic
                logger_->info("Drive " + std::to_string(drive_id_) + " removing directory: " + request.path);
                break;
            case IOType::RENAME:
                // Implement rename logic
                logger_->info("Drive " + std::to_string(drive_id_) + " renaming from " + request.path + " to " + request.new_path);
                break;
            case IOType::CHMOD:
                // Implement chmod logic
                logger_->info("Drive " + std::to_string(drive_id_) + " changing mode of " + request.path);
                break;
            case IOType::CHOWN:
                // Implement chown logic
                logger_->info("Drive " + std::to_string(drive_id_) + " changing owner of " + request.path);
                break;
            case IOType::UTIMENS:
                // Implement utimens logic
                logger_->info("Drive " + std::to_string(drive_id_) + " updating timestamps of " + request.path);
                break;
            default:
                logger_->error("Drive " + std::to_string(drive_id_) + " received unknown IOType.");
                break;
        }
    }
}

void SSD_Simulator::simulateLatency(IOType type) {
    // Define latency in milliseconds based on IO type
    int latency_ms = 0;
    switch (type) {
        case IOType::CREATE:
        case IOType::DELETE:
        case IOType::MKDIR:
        case IOType::RMDIR:
        case IOType::CHMOD:
        case IOType::CHOWN:
        case IOType::UTIMENS:
            latency_ms = 1;
            break;
        case IOType::READ:
            latency_ms = 2;
            break;
        case IOType::WRITE:
            latency_ms = 3;
            break;
        case IOType::TRUNCATE:
            latency_ms = 2;
            break;
        case IOType::RENAME:
            latency_ms = 2;
            break;
        default:
            latency_ms = 1;
            break;
    }

    std::this_thread::sleep_for(std::chrono::milliseconds(latency_ms));
}
