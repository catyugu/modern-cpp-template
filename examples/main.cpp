#include "myproject/core.hpp"
#include <array>
#include <iostream>

int main()
{
    const std::array<myproject::Sample, 4> samples {{{0, 1}, {1, 3}, {2, 4}, {3, 7}}};
    const auto fit = myproject::fit_line(samples);
    std::cout << myproject::format_fit(fit) << '\n';
    std::cout << "Prediction at x = 4: " << fit.predict(4) << '\n';
}
