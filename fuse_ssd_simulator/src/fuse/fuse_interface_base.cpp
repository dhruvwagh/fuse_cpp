#include "fuse_interface.h"
#include <cstring>
#include <iostream>
#include <vector>

StorageAccelerator* FuseInterface::static_accelerator_ = nullptr;
Logger* FuseInterface::static_logger_ = nullptr;

FuseInterface::FuseInterface(const std::string& mount_point, std::shared_ptr<StorageAccelerator> accelerator)
    : mount_point_(mount_point), accelerator_(accelerator) {
    static_accelerator_ = accelerator_.get();
    static_logger_ = new Logger("FUSE_Interface");
}

void FuseInterface::run(int argc, char* argv[]) {
    struct fuse_args args = FUSE_ARGS_INIT(0, nullptr);

    if (argc > 0 && argv != nullptr) {
        args = FUSE_ARGS_INIT(argc, argv);
    } else {
        fuse_opt_add_arg(&args, "fuse_ssd_simulator");
        fuse_opt_add_arg(&args, mount_point_.c_str());
    }

    struct fuse_operations operations = {};
    operations.getattr = getattr_callback;
    operations.readdir = readdir_callback;
    operations.open = open_callback;
    operations.read = read_callback;
    operations.write = write_callback;
    operations.create = create_callback;
    operations.unlink = unlink_callback;
    operations.truncate = truncate_callback;
    operations.mkdir = mkdir_callback;
    operations.rmdir = rmdir_callback;
    operations.rename = rename_callback;
    operations.chmod = chmod_callback;
    operations.chown = chown_callback;
    operations.utimens = utimens_callback;

    int ret = fuse_main(args.argc, args.argv, &operations, nullptr);
    fuse_opt_free_args(&args);

    if (ret != 0) {
        static_logger_->error("FUSE main loop failed with error code: " + std::to_string(ret));
    }
}