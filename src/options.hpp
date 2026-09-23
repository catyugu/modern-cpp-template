#pragma once

// 私有头文件：位于 src/ 下，不随安装导出
#include <array>
#include <string_view>

namespace myproject::detail {

    struct Option {
        std::string_view short_name; // 不含前导 '-'
        std::string_view long_name; // 不含前导 "--"
        std::string_view value_hint; // 空表示开关型选项
        std::string_view description;
    };

    // 选项表的唯一定义：parse() 与 usage() 都基于它
    inline constexpr std::array<Option, 2> options {{
        {"n", "name", "NAME", "Name to greet"},
        {"h", "help", "", "Print usage"},
    }};

} // namespace myproject::detail
