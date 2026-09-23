// Parent executable that links the embedded library.
#include "myproject/core.hpp"

#include <cstdio>
#include <string>

int main()
{
    const std::string greeting = myproject::get_greeting("superproject");
    std::printf("%s\n", greeting.c_str());
    return greeting.empty() ? 1 : 0;
}
