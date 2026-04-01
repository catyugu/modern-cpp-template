#include "myproject/core.hpp"
#include <gtest/gtest.h>

TEST(CoreTest, GreetingFormat)
{
    EXPECT_EQ(myproject::get_greeting("Alice"), "Hello, Alice! Welcome to modern C++20.");
}
