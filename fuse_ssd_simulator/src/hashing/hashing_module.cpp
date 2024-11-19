#include "hashing/hashing_module.h"
#include "hashing/xxhash.h"

HashingModule::HashingModule(const std::string& seed_str) {
    // Convert seed string to uint64_t using XXH64
    seed_ = XXH64(seed_str.c_str(), seed_str.length(), 0);
}

uint64_t HashingModule::hash(const std::string& input) const {
    return XXH64(input.c_str(), input.length(), seed_);
}
