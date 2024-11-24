#include <gtest/gtest.h>
#include "storage_accelerator/storage_accelerator.h"
#include <sys/stat.h>
#include <bitset>

class StorageAcceleratorTest : public ::testing::Test {
protected:
    void SetUp() override {
        accelerator = std::make_unique<StorageAccelerator>(4, "test_seed");
    }

    void TearDown() override {
        accelerator.reset();
    }

    void PrintModeBits(mode_t mode) {
        std::cout << "Mode bits: " << std::bitset<16>(mode) << std::endl;
        std::cout << "File type: " << std::bitset<4>(mode >> 12) << std::endl;
        std::cout << "Permissions: " << std::bitset<9>(mode & 0777) << std::endl;
    }

    std::unique_ptr<StorageAccelerator> accelerator;
};

TEST_F(StorageAcceleratorTest, DirectoryOperations) {
    // Create directory
    mode_t dir_mode = 0755;  // rwxr-xr-x
    ASSERT_EQ(accelerator->createDirectory("/testdir", dir_mode), 0);

    // Verify directory metadata
    auto metadata = accelerator->getMetadata("/testdir");
    ASSERT_TRUE(metadata != nullptr);

    // Debug output
    std::cout << "Directory permissions:\n";
    std::cout << "Expected mode (octal): " << std::oct << dir_mode << std::endl;
    std::cout << "Actual mode (octal): " << std::oct << (metadata->mode & 0777) << std::endl;
    PrintModeBits(metadata->mode);

    // Check file type and permissions separately
    EXPECT_EQ(metadata->mode & S_IFMT, S_IFDIR) << "Not a directory";
    EXPECT_EQ(metadata->mode & 0777, dir_mode) << "Incorrect directory permissions";

    // Create file inside directory
    mode_t file_mode = 0644;  // rw-r--r--
    ASSERT_EQ(accelerator->createFile("/testdir/file.txt", file_mode), 0);

    // Verify file metadata
    auto file_metadata = accelerator->getMetadata("/testdir/file.txt");
    ASSERT_TRUE(file_metadata != nullptr);
    
    std::cout << "File permissions:\n";
    std::cout << "Expected mode (octal): " << std::oct << file_mode << std::endl;
    std::cout << "Actual mode (octal): " << std::oct << (file_metadata->mode & 0777) << std::endl;
    PrintModeBits(file_metadata->mode);

    EXPECT_EQ(file_metadata->mode & S_IFMT, S_IFREG) << "Not a regular file";
    EXPECT_EQ(file_metadata->mode & 0777, file_mode) << "Incorrect file permissions";

    // List directory contents
    auto entries = accelerator->listDirectory("/testdir");
    ASSERT_EQ(entries.size(), 1);
    EXPECT_EQ(entries[0], "file.txt");

    // Delete file
    ASSERT_EQ(accelerator->deleteFile("/testdir/file.txt"), 0);

    // Delete directory
    ASSERT_EQ(accelerator->removeDirectory("/testdir"), 0);
}