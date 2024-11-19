#pragma once

#include "../storage_accelerator/storage_accelerator.h"
#include "../logger/logger.h"

class Monitor {
public:
    Monitor(std::shared_ptr<StorageAccelerator> accelerator, Logger* logger);
    void start();
    void stop();

private:
    std::shared_ptr<StorageAccelerator> accelerator_;
    Logger* logger_;
    bool running_;
    std::thread monitor_thread_;

    void monitorLoop();
};
