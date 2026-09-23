#include "myproject/core.hpp"
#include <fmt/format.h>

namespace myproject {
    std::string get_greeting(const std::string& name)
    {
        // 具名参数是 fmt 相对 std::format 多出来的能力；fmt 只出现在实现层，不进公开头文件
        return fmt::format("Hello, {name}! Welcome to modern C++{standard}.", fmt::arg("name", name), fmt::arg("standard", 20));
    }
} // namespace myproject
