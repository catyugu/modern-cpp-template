#include "myproject/core.hpp"
#include <format> // 使用 C++20 特性

namespace myproject {
    std::string get_greeting(const std::string& name)
    {
        return std::format("Hello, {}! Welcome to modern C++20.", name);
    }
} // namespace myproject
