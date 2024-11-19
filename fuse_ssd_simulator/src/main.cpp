#include "fuse_interface.h"
#include "storage_accelerator/storage_accelerator.h"
#include "logger/logger.h"
#include <iostream>
#include <memory>
#include <cstring>
#include <filesystem>
#include <system_error>
#include <signal.h>

static std::shared_ptr<FuseInterface> fuse_interface_ptr;
static Logger* signal_logger = nullptr;

void signal_handler(int sig) {
    if (signal_logger) {
        signal_logger->info("Received signal " + std::to_string(sig) + ", cleaning up...");
    }
    if (fuse_interface_ptr) {
        fuse_interface_ptr->cleanup();
    }
    exit(0);
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <mount_point> [-f] [-d]" << std::endl;
        std::cerr << "Options:" << std::endl;
        std::cerr << "  -f  Keep program in foreground" << std::endl;
        std::cerr << "  -d  Enable debug output" << std::endl;
        return 1;
    }

    try {
        // Set up signal handling
        signal_logger = new Logger("SignalHandler");
        signal(SIGINT, signal_handler);
        signal(SIGTERM, signal_handler);
        signal(SIGHUP, signal_handler);

        std::string mount_point = argv[1];
        
        // Initialize logging
        std::filesystem::path log_path = std::filesystem::current_path() / "filesystem.log";
        Logger::init(log_path.string());
        Logger logger("Main");
        logger.info("Starting FUSE SSD Simulator");

        // Check mount point
        if (!std::filesystem::exists(mount_point)) {
            logger.error("Mount point does not exist: " + mount_point);
            return 1;
        }

        if (!std::filesystem::is_directory(mount_point)) {
            logger.error("Mount point is not a directory: " + mount_point);
            return 1;
        }

        // Initialize storage
        int num_drives = 16;
        std::string hash_seed = "default_seed";
        auto accelerator = std::make_shared<StorageAccelerator>(num_drives, hash_seed);
        logger.info("Storage Accelerator initialized with " + std::to_string(num_drives) + " drives");

        // Prepare FUSE arguments
        std::vector<char*> fuse_args;
        fuse_args.push_back(argv[0]);
        fuse_args.push_back(const_cast<char*>(mount_point.c_str()));
        
        // Add default FUSE options
        fuse_args.push_back(const_cast<char*>("-o"));
        fuse_args.push_back(const_cast<char*>("allow_other"));
        fuse_args.push_back(const_cast<char*>("-o"));
        fuse_args.push_back(const_cast<char*>("default_permissions"));
        
        // Process command line options
        bool foreground = false;
        for (int i = 2; i < argc; i++) {
            if (strcmp(argv[i], "-f") == 0) {
                foreground = true;
                fuse_args.push_back(const_cast<char*>("-f"));
            }
            if (strcmp(argv[i], "-d") == 0) {
                fuse_args.push_back(const_cast<char*>("-d"));
            }
        }

        // Initialize FUSE interface
        auto interface = std::make_shared<FuseInterface>(mount_point, accelerator);
        fuse_interface_ptr = interface;
        logger.info("Mounting FUSE filesystem at " + mount_point);
        
        // Run FUSE
        interface->run(fuse_args.size(), fuse_args.data());
        
        return 0;
    }
    catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}