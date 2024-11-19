#pragma once

#include <string>
#include <cstdint>

class HashingModule {
public:
    HashingModule(const std::string& seed);
    uint64_t hash(const std::string& input) const;

private:
    uint64_t seed_;
};
