#include "myproject/core.hpp"
#include <Eigen/QR>
#include <cmath>
#include <fmt/format.h>
#include <stdexcept>

namespace myproject {

    LinearFit fit_line(std::span<const Sample> samples)
    {
        if (samples.size() < 2) {
            throw std::invalid_argument("at least two samples are required");
        }

        const auto count = static_cast<Eigen::Index>(samples.size());
        Eigen::MatrixXd design(count, 2);
        Eigen::VectorXd values(count);
        for (Eigen::Index row = 0; row < count; ++row) {
            const auto& sample = samples[static_cast<std::size_t>(row)];
            if (!std::isfinite(sample.x) || !std::isfinite(sample.y)) {
                throw std::invalid_argument("sample coordinates must be finite");
            }
            design(row, 0) = sample.x;
            design(row, 1) = 1.0;
            values(row) = sample.y;
        }

        const auto qr = design.colPivHouseholderQr();
        if (qr.rank() != 2) {
            throw std::invalid_argument("samples must have distinct x values");
        }
        const Eigen::Vector2d coefficients = qr.solve(values);
        const double rmse = (design * coefficients - values).norm() / std::sqrt(static_cast<double>(count));
        return {coefficients[0], coefficients[1], rmse};
    }

    std::string format_fit(const LinearFit& fit)
    {
        return fmt::format("y = {:.6g} * x + {:.6g}; RMSE = {:.6g}", fit.slope, fit.intercept, fit.rmse);
    }

} // namespace myproject
