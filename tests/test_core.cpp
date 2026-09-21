#include "myproject/cli.hpp"
#include "myproject/core.hpp"
#include <gtest/gtest.h>
#include <string>
#include <vector>

namespace {

    myproject::cli::Arguments parse(const std::vector<std::string>& arguments)
    {
        std::vector<const char*> argv;
        argv.reserve(arguments.size());
        for (const auto& argument : arguments) {
            argv.push_back(argument.c_str());
        }

        return myproject::cli::parse(static_cast<int>(argv.size()), const_cast<char**>(argv.data()));
    }

} // namespace

TEST(CoreTest, GreetingFormat)
{
    EXPECT_EQ(myproject::get_greeting("Alice"), "Hello, Alice! Welcome to modern C++20.");
}

TEST(CliTest, UsesWorldWhenNoNameIsGiven)
{
    EXPECT_EQ(parse({"myproject"}).name, "World");
}

TEST(CliTest, ParsesNameOption)
{
    const auto arguments = parse({"myproject", "--name", "Alice"});

    EXPECT_EQ(arguments.name, "Alice");
    EXPECT_FALSE(arguments.help);
}

TEST(CliTest, ParsesHelpFlag)
{
    EXPECT_TRUE(parse({"myproject", "-h"}).help);
}

TEST(CliTest, RejectsUnknownOptionWithLibraryError)
{
    EXPECT_THROW(parse({"myproject", "--unknown"}), myproject::cli::ParseError);
}
