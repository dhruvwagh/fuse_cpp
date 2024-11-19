#include "logger/logger.h"
#include <iostream>
#include <chrono>
#include <ctime>
#include <iomanip>

std::unique_ptr<std::ofstream> Logger::global_log_stream_ = nullptr;
std::mutex Logger::global_log_mutex_;

Logger::Logger(const std::string& component)
    : component_(component) {
}

Logger::~Logger() {
}

void Logger::init(const std::string& log_file) {
    std::lock_guard<std::mutex> lock(global_log_mutex_);
    if (!global_log_stream_) {
        global_log_stream_ = std::make_unique<std::ofstream>(log_file, std::ios::out | std::ios::app);
        if (!global_log_stream_->is_open()) {
            std::cerr << "Failed to open log file: " << log_file << std::endl;
            exit(1);
        }
    }
}

void Logger::info(const std::string& message) {
    log(INFO, message);
}

void Logger::debug(const std::string& message) {
    log(DEBUG, message);
}

void Logger::error(const std::string& message) {
    log(ERROR, message);
}

void Logger::log(LogLevel level, const std::string& message) {
    std::lock_guard<std::mutex> lock(global_log_mutex_);
    
    // Get current time with milliseconds
    auto now = std::chrono::system_clock::now();
    auto now_c = std::chrono::system_clock::to_time_t(now);
    auto now_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
        now.time_since_epoch()) % 1000;

    // Format time string
    std::stringstream time_str;
    time_str << std::put_time(std::localtime(&now_c), "%Y-%m-%d %H:%M:%S")
             << '.' << std::setfill('0') << std::setw(3) << now_ms.count();

    // Convert LogLevel to string
    std::string level_str;
    switch (level) {
        case INFO:  level_str = "INFO "; break;
        case DEBUG: level_str = "DEBUG"; break;
        case ERROR: level_str = "ERROR"; break;
        default:    level_str = "?????"; break;
    }

    // Format the log message
    std::stringstream log_stream;
    log_stream << "[" << time_str.str() << "] "
               << "[" << component_ << "] "
               << "[" << level_str << "] "
               << message;

    // Write to console
    std::cout << log_stream.str() << std::endl;

    // Write to log file if available
    if (global_log_stream_ && global_log_stream_->is_open()) {
        (*global_log_stream_) << log_stream.str() << std::endl;
        global_log_stream_->flush();  // Ensure it's written immediately
    }
}