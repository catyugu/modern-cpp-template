#include "myproject/config.h"
#include "myproject/config.h" // Public headers must be safe to include twice.
#include "myproject/core.hpp"
#include <array>
#include <cmath>
#include <iostream>
#include <stdexcept>

int main()
{
    const std::array<myproject::Sample, 3> samples {{{0, 1}, {1, 3}, {2, 5}}};
    const auto fit = myproject::fit_line(samples);
    std::cout << myproject::format_fit(fit) << '\n';
    if (std::abs(fit.slope - 2.0) > 1e-12 || std::abs(fit.predict(4) - 9.0) > 1e-12) {
        return 1;
    }

    // Exercise exception propagation across the shared-library boundary too.
    try {
        myproject::fit_line({});
    }
    catch (const std::invalid_argument&) {
        return 0;
    }
    return 1;
}
