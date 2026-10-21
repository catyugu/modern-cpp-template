#include "myproject/core.hpp"
#include <fstream>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

int main(int argc, char** argv)
{
    if (argc == 2 && std::string_view(argv[1]) == "--help") {
        std::cout << "Usage: myproject_fit FILE\nFit a line to whitespace-separated x y pairs, one pair per line.\n";
        return 0;
    }
    if (argc != 2) {
        std::cerr << "Usage: myproject_fit FILE\n";
        return 1;
    }

    try {
        std::ifstream input(argv[1]);
        if (!input) {
            throw std::runtime_error("cannot open input file");
        }

        std::vector<myproject::Sample> samples;
        std::string line;
        std::size_t line_number = 0;
        while (std::getline(input, line)) {
            ++line_number;
            std::istringstream row(line);
            row >> std::ws;
            if (row.eof()) {
                continue;
            }
            myproject::Sample sample {};
            if (!(row >> sample.x >> sample.y) || !(row >> std::ws).eof()) {
                throw std::runtime_error("expected an x y pair on line " + std::to_string(line_number));
            }
            samples.push_back(sample);
        }
        if (input.bad()) {
            throw std::runtime_error("failed to read input file");
        }
        std::cout << myproject::format_fit(myproject::fit_line(samples)) << '\n';
    }
    catch (const std::exception& error) {
        std::cerr << "myproject_fit: " << error.what() << '\n';
        return 1;
    }
}
