// Consumer of the installed package. Exercises the public API, including
// catching the library's exception by type across the DSO boundary when the
// library is built as a shared library.
#include "myproject/cli.hpp"
#include "myproject/config.h"
#include "myproject/core.hpp"

#include <cstdio>
#include <string>

int main()
{
    const std::string greeting = myproject::get_greeting("consumer");
    std::printf("%s\n", greeting.c_str());
    std::printf("version=%s\n", std::string(myproject::config::VERSION).c_str());

    int caught = 0;
    try {
        char* argv[] = {const_cast<char*>("consumer"), const_cast<char*>("--unknown")};
        myproject::cli::parse(2, argv);
    }
    catch (const myproject::cli::ParseError& error) {
        caught = 1;
        std::printf("caught: %s\n", error.what());
    }

    if (greeting.empty() || caught != 1) {
        return 1;
    }
    return myproject::cli::usage().empty() ? 1 : 0;
}
