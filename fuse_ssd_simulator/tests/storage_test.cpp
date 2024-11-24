#include <gtest/gtest.h>
#include "storage_accelerator/storage_accelerator.h"
#include <thread>
#include <vector>
#include <random>
#include <fstream>

class StorageTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Initialize storage accelerator with 4 drives for testing
        accelerator = std::make_unique<StorageAccelerator>(4, "test_seed");
    }

    void TearDown() override {
        accelerator.reset();
    }

    std::unique_ptr<StorageAccelerator> accelerator;
};

TEST_F(StorageTest, BasicFileOperations) {
    // Create a file
    ASSERT_EQ(accelerator->createFile("/test.txt", 0644), 0);

    // Write data
    const char* test_data = "Hello, World!";
    ASSERT_EQ(accelerator->writeFile("/test.txt", test_data, strlen(test_data), 0), 
              strlen(test_data));

    // Read data back
    char buffer[100];
    ASSERT_EQ(accelerator->readFile("/test.txt", buffer, strlen(test_data), 0), 
              strlen(test_data));
    buffer[strlen(test_data)] = '\0';
    ASSERT_STREQ(buffer, test_data);

    // Delete file
    ASSERT_EQ(accelerator->deleteFile("/test.txt"), 0);
}

TEST_F(StorageTest, ParallelAccess) {
    const int num_threads = 4;
    const int ops_per_thread = 100;
    std::vector<std::thread> threads;
    std::atomic<int> success_count{0};

    // Create test files
    for (int i = 0; i < num_threads; i++) {
        std::string path = "/test" + std::to_string(i) + ".txt";
        ASSERT_EQ(accelerator->createFile(path, 0644), 0);
    }

    // Start parallel access
    for (int i = 0; i < num_threads; i++) {
        threads.emplace_back([&, i]() {
            std::string path = "/test" + std::to_string(i) + ".txt";
            std::random_device rd;
            std::mt19937 gen(rd());
            std::uniform_int_distribution<> dis(0, 9999);

            for (int op = 0; op < ops_per_thread; op++) {
                std::string data = std::to_string(dis(gen));
                if (accelerator->writeFile(path, data.c_str(), data.length(), 0) 
                    == static_cast<ssize_t>(data.length())) {
                    success_count++;
                }
            }
        });
    }

    // Wait for all threads to complete
    for (auto& thread : threads) {
        thread.join();
    }

    // Verify results
    ASSERT_EQ(success_count, num_threads * ops_per_thread);

    // Cleanup
    for (int i = 0; i < num_threads; i++) {
        std::string path = "/test" + std::to_string(i) + ".txt";
        ASSERT_EQ(accelerator->deleteFile(path), 0);
    }
}