#pragma once

#include <string>
#include <fstream>
#include <mutex>
#include <memory>

enum LogLevel {
    INFO,
    DEBUG,
    ERROR
};

class Logger {
public:
    Logger(const std::string& component);
    ~Logger();

    void info(const std::string& message);
    void debug(const std::string& message);
    void error(const std::string& message);

    static void init(const std::string& log_file);
    
private:
    std::string component_;
    std::ofstream log_stream_;
    std::mutex log_mutex_;
    static std::unique_ptr<std::ofstream> global_log_stream_;
    static std::mutex global_log_mutex_;

    void log(LogLevel level, const std::string& message);
};
