#include "storage_accelerator/load_balancer.h"
#include <limits>
#include <algorithm>

size_t LoadBalancer::selectDrive(size_t primary_drive, size_t size) {
    // Check load of primary drive
    if (primary_drive >= drive_stats_.size()) {
        logger_->error("Invalid primary drive index: " + std::to_string(primary_drive));
        return 0;
    }

    auto& primary_stats = drive_stats_[primary_drive];
    if (primary_stats.pending_ops < MAX_PENDING_OPS) {
        return primary_drive;
    }

    // Find least loaded drive
    size_t selected = primary_drive;
    size_t min_ops = primary_stats.pending_ops;

    for (size_t i = 0; i < drive_stats_.size(); i++) {
        if (drive_stats_[i].pending_ops < min_ops) {
            min_ops = drive_stats_[i].pending_ops;
            selected = i;
        }
    }

    if (selected != primary_drive) {
        logger_->debug("Load balanced: Redirecting from drive " + 
                      std::to_string(primary_drive) + " to " + 
                      std::to_string(selected));
    }

    return selected;
}

void LoadBalancer::recordOperation(size_t drive_id, size_t size, 
                                 const std::chrono::nanoseconds& duration) {
    if (drive_id >= drive_stats_.size()) {
        logger_->error("Invalid drive ID in recordOperation: " + std::to_string(drive_id));
        return;
    }

    auto& stats = drive_stats_[drive_id];
    stats.total_bytes += size;
    
    double duration_ms = duration.count() / 1e6;  // Convert to milliseconds
    double old_latency = stats.avg_latency.load();
    stats.avg_latency.store((old_latency + duration_ms) / 2.0);
    
    size_t old_pending = stats.pending_ops.fetch_sub(1);
    if (old_pending == 0) {
        logger_->error("Pending ops underflow for drive " + std::to_string(drive_id));
    }

    if (duration_ms > 100.0) {  // More than 100ms
        logger_->info("High latency operation on drive " + std::to_string(drive_id) + 
                     ": " + std::to_string(duration_ms) + "ms");
    }
}

void LoadBalancer::startOperation(size_t drive_id) {
    if (drive_id >= drive_stats_.size()) {
        logger_->error("Invalid drive ID in startOperation: " + std::to_string(drive_id));
        return;
    }

    drive_stats_[drive_id].pending_ops++;
}