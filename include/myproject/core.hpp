#pragma once
#include "myproject/export.hpp"
#include <string>

namespace myproject {
    MYPROJECT_API std::string get_greeting(const std::string& name);
}
