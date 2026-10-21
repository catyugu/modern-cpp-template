#pragma once
#include "myproject/export.hpp"
#include <span>
#include <string>

namespace myproject {

    struct Sample {
        double x;
        double y;
    };

    struct LinearFit {
        double slope;
        double intercept;
        double rmse;

        double predict(double x) const { return slope * x + intercept; }
    };

    // Fit y = slope * x + intercept. Requires at least two finite samples
    // with distinct x values; throws std::invalid_argument otherwise.
    MYPROJECT_API LinearFit fit_line(std::span<const Sample> samples);
    MYPROJECT_API std::string format_fit(const LinearFit& fit);

} // namespace myproject
