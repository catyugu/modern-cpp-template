#include "myproject/core.hpp"
#include <cxxopts.hpp>
#include <iostream>


int main(int argc, char** argv)
{
    cxxopts::Options options("MyProject", "A modern C++ project executable");

    options.add_options()("n,name", "Name to greet", cxxopts::value<std::string>()->default_value("World"))("h,help", "Print usage");

    auto result = options.parse(argc, argv);

    if (result.count("help")) {
        std::cout << options.help() << std::endl;
        return 0;
    }

    std::string name = result["name"].as<std::string>();
    std::cout << myproject::get_greeting(name) << '\n';

    return 0;
}
