#pragma once
#include "myproject/export.hpp"
#include <stdexcept>
#include <string>

namespace myproject::cli {

    // 解析后的命令行结果。这里只出现标准库类型：解析实现属于库的内部细节。
    struct Arguments {
        std::string name = "World";
        bool help = false;
    };

    // 命令行无法解析时抛出，调用方无需认识底层解析库的异常类型。
    class ParseError : public std::runtime_error {
    public:
        explicit ParseError(const std::string& message)
            : std::runtime_error(message)
        {
        }
    };

    MYPROJECT_API Arguments parse(int argc, char** argv);
    MYPROJECT_API std::string usage();

} // namespace myproject::cli
