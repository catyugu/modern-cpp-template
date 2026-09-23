#include "myproject/cli.hpp"
#include "myproject/config.h"
#include "options.hpp"
#include <fmt/format.h>

namespace myproject::cli {

    namespace {

        const detail::Option* find_option(std::string_view name)
        {
            for (const auto& option : detail::options) {
                if (name == option.long_name || name == option.short_name) {
                    return &option;
                }
            }
            return nullptr;
        }

        std::string take_next_value(int& index, int argc, char** argv)
        {
            if (index + 1 >= argc) {
                throw ParseError(fmt::format("option '{}' requires a value", argv[index]));
            }
            return argv[++index];
        }

    } // namespace

    Arguments parse(int argc, char** argv)
    {
        Arguments arguments;

        for (int index = 1; index < argc; ++index) {
            std::string_view argument = argv[index];
            if (argument.size() < 2 || argument.front() != '-') {
                throw ParseError(fmt::format("unexpected argument '{}'", argument));
            }
            // 去掉前导的 '-' 或 '--'
            argument.remove_prefix(argument[1] == '-' ? 2 : 1);

            const auto separator = argument.find('=');
            const std::string_view name = argument.substr(0, separator);
            const bool has_inline_value = separator != std::string_view::npos;

            const detail::Option* option = find_option(name);
            if (option == nullptr) {
                throw ParseError(fmt::format("unknown option '{}'", argv[index]));
            }

            if (option->long_name == "help") {
                if (has_inline_value) {
                    throw ParseError(fmt::format("option '{}' takes no value", argv[index]));
                }
                arguments.help = true;
                continue;
            }

            arguments.name = has_inline_value ? std::string(argument.substr(separator + 1)) : take_next_value(index, argc, argv);
        }

        return arguments;
    }

    std::string usage()
    {
        std::string text = fmt::format("Usage: {} [options]\n\nOptions:\n", config::PROJECT_NAME);
        for (const auto& option : detail::options) {
            const std::string names = option.value_hint.empty()
                ? fmt::format("-{}, --{}", option.short_name, option.long_name)
                : fmt::format("-{}, --{} {}", option.short_name, option.long_name, option.value_hint);
            text += fmt::format("  {:<18}{}\n", names, option.description);
        }
        return text;
    }

} // namespace myproject::cli
