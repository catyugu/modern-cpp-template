#include "myproject/cli.hpp"
#include "myproject/config.h"
#include "options.hpp"

namespace myproject::detail {

    cxxopts::Options greeting_parser(std::string program)
    {
        cxxopts::Options options(std::move(program), "A modern C++ project executable");

        options.add_options()("n,name", "Name to greet", cxxopts::value<std::string>()->default_value("World"))("h,help", "Print usage");

        return options;
    }

} // namespace myproject::detail

namespace myproject::cli {

    Arguments parse(int argc, char** argv)
    {
        auto options = detail::greeting_parser(std::string(config::PROJECT_NAME));

        cxxopts::ParseResult result;
        try {
            result = options.parse(argc, argv);
        }
        catch (const cxxopts::exceptions::exception& error) {
            // 把第三方异常翻译成库自己的错误类型
            throw ParseError(error.what());
        }

        Arguments arguments;
        arguments.help = result.count("help") > 0;
        arguments.name = result["name"].as<std::string>();
        return arguments;
    }

    std::string usage()
    {
        return detail::greeting_parser(std::string(config::PROJECT_NAME)).help();
    }

} // namespace myproject::cli
