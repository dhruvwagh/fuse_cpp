#include "ssd_simulator/ssd_simulator.h"
#include <chrono>
#include <thread>
#include <cstring>
#include <system_error>

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
    if (isQueueFull()) {
        logger_->error("Drive " + std::to_string(drive_id_) + " queue is full");
        if (request.promise) {
            request.promise->promise.set_value(-EBUSY);
        }
        return;
    }

    {
        std::lock_guard<std::mutex> lock(queue_mutex_);
        io_queue_.push(request);
    }
    cv_.notify_one();
}

ssize_t SSD_Simulator::readFile(const std::string& path, char* buffer, size_t size, off_t offset) {
    auto promise_ptr = std::make_shared<IOPromise>();
    auto future = promise_ptr->promise.get_future();
    
    IORequest request;
    request.type = IOType::READ;
    request.path = path;
    request.buffer = buffer;
    request.size = size;
    request.offset = offset;
    request.promise = promise_ptr;

    enqueueIO(request);
    
    // Wait for completion with timeout
    auto status = future.wait_for(std::chrono::seconds(5));
    if (status == std::future_status::timeout) {
        logger_->error("Read operation timed out for " + path);
        return -ETIMEDOUT;
    }
    
    return future.get();
}

ssize_t SSD_Simulator::writeFile(const std::string& path, const char* buffer, size_t size, off_t offset) {
    auto promise_ptr = std::make_shared<IOPromise>();
    auto future = promise_ptr->promise.get_future();
    
    // Create a copy of the data
    std::vector<char> data_copy(buffer, buffer + size);
    
    IORequest request;
    request.type = IOType::WRITE;
    request.path = path;
    request.buffer = data_copy.data();
    request.size = size;
    request.offset = offset;
    request.promise = promise_ptr;

    enqueueIO(request);
    
    // Wait for completion with timeout
    auto status = future.wait_for(std::chrono::seconds(5));
    if (status == std::future_status::timeout) {
        logger_->error("Write operation timed out for " + path);
        return -ETIMEDOUT;
    }
    
    return future.get();
}

void SSD_Simulator::truncate(const std::string& path, off_t size) {
    auto promise_ptr = std::make_shared<IOPromise>();
    auto future = promise_ptr->promise.get_future();
    
    IORequest request;
    request.type = IOType::TRUNCATE;
    request.path = path;
    request.size = size;
    request.promise = promise_ptr;

    enqueueIO(request);
    
    // Wait for completion
    future.wait();
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

        ssize_t result = 0;
        try {
            switch (request.type) {
                case IOType::READ: {
                    std::shared_lock<std::shared_mutex> lock(storage_mutex_);
                    auto it = storage_.find(request.path);
                    if (it != storage_.end()) {
                        size_t available = it->second.size() > static_cast<size_t>(request.offset) ?
                                         it->second.size() - request.offset : 0;
                        size_t to_read = std::min(request.size, available);
                        if (to_read > 0) {
                            memcpy(request.buffer, it->second.data() + request.offset, to_read);
                            result = to_read;
                            logger_->info("Drive " + std::to_string(drive_id_) + " read " + 
                                        std::to_string(to_read) + " bytes from " + request.path);
                        } else {
                            result = 0;
                            logger_->info("Drive " + std::to_string(drive_id_) + 
                                        " read 0 bytes from " + request.path);
                        }
                    } else {
                        result = -ENOENT;
                        logger_->error("Drive " + std::to_string(drive_id_) + 
                                     " read failed: " + request.path + " does not exist");
                    }
                    break;
                }
                case IOType::WRITE: {
                    std::unique_lock<std::shared_mutex> lock(storage_mutex_);
                    auto& data = storage_[request.path];
                    if (request.offset + request.size > data.size()) {
                        data.resize(request.offset + request.size);
                    }
                    memcpy(data.data() + request.offset, request.buffer, request.size);
                    result = request.size;
                    logger_->info("Drive " + std::to_string(drive_id_) + " wrote " + 
                                std::to_string(request.size) + " bytes to " + request.path);
                    break;
                }
                case IOType::TRUNCATE: {
                    std::unique_lock<std::shared_mutex> lock(storage_mutex_);
                    auto it = storage_.find(request.path);
                    if (it != storage_.end()) {
                        it->second.resize(request.size, 0);
                        result = 0;
                        logger_->info("Drive " + std::to_string(drive_id_) + 
                                    " truncated " + request.path + " to " + 
                                    std::to_string(request.size));
                    } else {
                        result = -ENOENT;
                        logger_->error("Drive " + std::to_string(drive_id_) + 
                                     " truncate failed: " + request.path + " does not exist");
                    }
                    break;
                }
                // Add other cases as needed
            }
        } catch (const std::exception& e) {
            logger_->error("Drive " + std::to_string(drive_id_) + 
                          " error processing IO: " + std::string(e.what()));
            result = -EIO;
        }

        // Complete the operation
        if (request.promise) {
            request.promise->promise.set_value(result);
        }
    }
}

void SSD_Simulator::simulateLatency(IOType type) {
    int latency_ms = 0;
    switch (type) {
        case IOType::READ:
            latency_ms = 2;
            break;
        case IOType::WRITE:
            latency_ms = 3;
            break;
        case IOType::TRUNCATE:
            latency_ms = 2;
            break;
        default:
            latency_ms = 1;
            break;
    }

    std::this_thread::sleep_for(std::chrono::milliseconds(latency_ms));
}