#include "myproject/cli.hpp"
#include "myproject/config.h"
#include "myproject/core.hpp"
#include <iostream>

int main(int argc, char** argv)
{
    myproject::cli::Arguments arguments;
    try {
        arguments = myproject::cli::parse(argc, argv);
    }
    catch (const myproject::cli::ParseError& error) {
        std::cerr << error.what() << '\n'
                  << myproject::cli::usage() << '\n';
        return 1;
    }

    if (arguments.help) {
        std::cout << myproject::cli::usage() << '\n';
        return 0;
    }

    std::cout << myproject::get_greeting(arguments.name) << '\n';

    std::cout << "The project version is: " << myproject::config::VERSION << '\n';

    return 0;
}
