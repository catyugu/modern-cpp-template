#include <cctype>
#include <cstddef>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <iterator>
#include <string>
#include <string_view>
#include <vector>

namespace {

    constexpr std::string_view usage = "Usage: myproject_wc [-l] [-w] [-c] [file ...]\n"
                                       "Count lines, words and bytes in files.\n"
                                       "\n"
                                       "  -l, --lines  print the number of lines\n"
                                       "  -w, --words  print the number of words\n"
                                       "  -c, --bytes  print the number of bytes\n"
                                       "  -h, --help   print usage\n";

} // namespace

int main(int argc, char** argv)
{
    bool show_lines = false;
    bool show_words = false;
    bool show_bytes = false;
    std::vector<std::string> files;

    for (int index = 1; index < argc; ++index) {
        const std::string_view argument = argv[index];
        if (argument == "-l" || argument == "--lines") {
            show_lines = true;
        }
        else if (argument == "-w" || argument == "--words") {
            show_words = true;
        }
        else if (argument == "-c" || argument == "--bytes") {
            show_bytes = true;
        }
        else if (argument == "-h" || argument == "--help") {
            std::cout << usage;
            return 0;
        }
        else {
            files.emplace_back(argument);
        }
    }

    if (!show_lines && !show_words && !show_bytes) {
        // 未指定任何标志时与 wc 一致：全部输出
        show_lines = show_words = show_bytes = true;
    }

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
                }
                else if (!in_word) {
                    ++words;
                    in_word = true;
                }
            }
        }

        // 计数右对齐，列宽与 Unix wc 一致
        if (show_lines) {
            std::cout << std::setw(8) << lines;
        }
        if (show_words) {
            std::cout << std::setw(8) << words;
        }
        if (show_bytes) {
            std::cout << std::setw(8) << content.size();
        }
        std::cout << ' ' << path << '\n';
    }

    return exit_code;
}
