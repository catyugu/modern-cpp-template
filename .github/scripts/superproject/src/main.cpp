#include "myproject/core.hpp"
#include <array>
#include <cmath>
#include <iostream>

int main()
{
    const std::array<myproject::Sample, 3> samples {{{0, 1}, {1, 3}, {2, 5}}};
    const auto fit = myproject::fit_line(samples);
    std::cout << myproject::format_fit(fit) << '\n';
    return std::abs(fit.predict(4) - 9.0) < 1e-12 ? 0 : 1;
}
