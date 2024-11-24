#pragma once

#include <vector>
#include <atomic>
#include <chrono>
#include "../logger/logger.h"

class LoadBalancer {
public:
    struct DriveStats {
        std::atomic<size_t> pending_ops{0};
        std::atomic<uint64_t> total_bytes{0};
        std::atomic<double> avg_latency{0.0};
        std::chrono::steady_clock::time_point last_op;

        DriveStats() : last_op(std::chrono::steady_clock::now()) {}
    };

    LoadBalancer(size_t num_drives, Logger* logger) 
        : drive_stats_(num_drives), logger_(logger) {}

    size_t selectDrive(size_t primary_drive, size_t size);
    void recordOperation(size_t drive_id, size_t size, 
                        const std::chrono::nanoseconds& duration);
    void startOperation(size_t drive_id);

private:
    static constexpr size_t MAX_PENDING_OPS = 1000;
    std::vector<DriveStats> drive_stats_;
    Logger* logger_;
};