#pragma once
#include "myproject/export.hpp"
#include <stdexcept>
#include <string>

namespace myproject::cli {

    // Parsed command line. Only standard library types appear here: how the
    // command line is parsed stays a detail of the library.
    struct Arguments {
        std::string name = "World";
        bool help = false;
    };

    // Thrown when the command line cannot be parsed; callers do not need to know
    // the underlying parser's exception type. The class must be exported so that
    // a caller catching it by type from another DSO matches the same typeinfo
    class MYPROJECT_API ParseError : public std::runtime_error {
    public:
        explicit ParseError(const std::string& message)
            : std::runtime_error(message)
        {
        }
    };

    MYPROJECT_API Arguments parse(int argc, char** argv);
    MYPROJECT_API std::string usage();

} // namespace myproject::cli
