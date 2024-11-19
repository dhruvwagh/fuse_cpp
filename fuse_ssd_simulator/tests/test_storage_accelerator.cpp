#include <gtest/gtest.h>
#include "../include/storage_accelerator/storage_accelerator.h"

class StorageAcceleratorTest : public ::testing::Test {
protected:
    void SetUp() override {
        accelerator = std::make_unique<StorageAccelerator>(4, "test_seed");
    }

    std::unique_ptr<StorageAccelerator> accelerator;
};

TEST_F(StorageAcceleratorTest, CreateAndDeleteFile) {
    // Create a test file
    int res = accelerator->createFile("/testfile", 0644);
    EXPECT_EQ(res, 0) << "Failed to create file";

    // Verify file metadata
    auto metadata = accelerator->getMetadata("/testfile");
    ASSERT_NE(metadata, nullptr) << "Failed to get metadata";
    EXPECT_EQ(metadata->mode & 0777, 0644) << "Incorrect file permissions";

    // Delete the file
    res = accelerator->deleteFile("/testfile");
    EXPECT_EQ(res, 0) << "Failed to delete file";

    // Verify file is gone
    metadata = accelerator->getMetadata("/testfile");
    EXPECT_EQ(metadata, nullptr) << "File still exists after deletion";
}

// Don't include main() in the test file