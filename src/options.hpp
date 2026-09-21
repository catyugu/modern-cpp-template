#pragma once

// 私有头文件：位于 src/ 下，不随安装导出，仅供库内部实现使用。
// 这里是库中唯一认识 cxxopts 的地方，第三方类型不会外泄到公开头文件。
#include <cxxopts.hpp>
#include <string>

namespace myproject::detail {

    // 命令行选项表的唯一定义：parse() 与 usage() 都基于它，两者不会各自漂移。
    cxxopts::Options greeting_parser(std::string program);

} // namespace myproject::detail
