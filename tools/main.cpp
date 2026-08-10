#include <cctype>
#include <cstddef>
#include <cxxopts.hpp>
#include <fstream>
#include <iostream>
#include <iterator>
#include <string>
#include <vector>

// myproject_wc: 类似 Unix wc 的小工具，统计给定文件的行数 / 单词数 / 字节数。
// 默认同时输出三项；可用 -l / -w / -c 单独选择。
int main(int argc, char** argv)
{
    cxxopts::Options options("myproject_wc", "Count lines, words and bytes in files.");

    options.add_options()
        ("l,lines", "Print the number of lines")
        ("w,words", "Print the number of words")
        ("c,bytes", "Print the number of bytes")
        ("h,help", "Print usage")
        ("file", "File(s) to count", cxxopts::value<std::vector<std::string>>());

    options.parse_positional({"file"});

    auto result = options.parse(argc, argv);

    if (result.count("help")) {
        std::cout << options.help() << '\n';
        return 0;
    }

    bool show_lines = result.count("lines") > 0;
    bool show_words = result.count("words") > 0;
    bool show_bytes = result.count("bytes") > 0;
    if (!show_lines && !show_words && !show_bytes) {
        // 未指定任何标志时与 wc 一致：全部输出
        show_lines = show_words = show_bytes = true;
    }

    const auto files = result["file"].as<std::vector<std::string>>();
    if (files.empty()) {
        std::cerr << "myproject_wc: no input files (use -h for help)\n";
        return 1;
    }

    int exit_code = 0;
    for (const auto& path : files) {
        std::ifstream in(path, std::ios::binary);
        if (!in) {
            std::cerr << "myproject_wc: cannot open '" << path << "'\n";
            exit_code = 1;
            continue;
        }

        const std::string content((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());

        std::size_t lines = 0;
        std::size_t words = 0;
        if (show_lines || show_words) {
            bool in_word = false;
            for (const char c : content) {
                if (c == '\n') {
                    ++lines;
                }
                if (std::isspace(static_cast<unsigned char>(c))) {
                    in_word = false;
                } else if (!in_word) {
                    ++words;
                    in_word = true;
                }
            }
        }
        const std::size_t bytes = content.size();

        if (show_lines) {
            std::cout << lines << ' ';
        }
        if (show_words) {
            std::cout << words << ' ';
        }
        if (show_bytes) {
            std::cout << bytes << ' ';
        }
        std::cout << path << '\n';
    }

    return exit_code;
}
