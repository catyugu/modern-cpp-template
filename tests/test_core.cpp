#include "myproject/core.hpp"
#include <array>
#include <cmath>
#include <gtest/gtest.h>
#include <limits>
#include <stdexcept>

TEST(LinearFitTest, FitsAnExactLine)
{
    const std::array<myproject::Sample, 3> samples {{{0, 1}, {1, 3}, {2, 5}}};
    const auto fit = myproject::fit_line(samples);
    EXPECT_NEAR(fit.slope, 2.0, 1e-12);
    EXPECT_NEAR(fit.intercept, 1.0, 1e-12);
    EXPECT_NEAR(fit.rmse, 0.0, 1e-12);
    EXPECT_NEAR(fit.predict(4), 9.0, 1e-12);
}

TEST(LinearFitTest, FitsNoisySamples)
{
    const std::array<myproject::Sample, 4> samples {{{0, 1}, {1, 3}, {2, 4}, {3, 7}}};
    const auto fit = myproject::fit_line(samples);
    EXPECT_NEAR(fit.slope, 1.9, 1e-12);
    EXPECT_NEAR(fit.intercept, 0.9, 1e-12);
    EXPECT_NEAR(fit.rmse, std::sqrt(0.175), 1e-12);
}

TEST(LinearFitTest, FitsAConstantResponse)
{
    const std::array<myproject::Sample, 3> samples {{{-1, 3}, {0, 3}, {1, 3}}};
    const auto fit = myproject::fit_line(samples);
    EXPECT_NEAR(fit.slope, 0.0, 1e-12);
    EXPECT_NEAR(fit.intercept, 3.0, 1e-12);
}

TEST(LinearFitTest, RejectsInsufficientSamples)
{
    const std::array<myproject::Sample, 1> samples {{{0, 1}}};
    EXPECT_THROW(myproject::fit_line({}), std::invalid_argument);
    EXPECT_THROW(myproject::fit_line(samples), std::invalid_argument);
}

TEST(LinearFitTest, RejectsIndeterminateSlope)
{
    const std::array<myproject::Sample, 2> samples {{{1, 2}, {1, 3}}};
    EXPECT_THROW(myproject::fit_line(samples), std::invalid_argument);
}

TEST(LinearFitTest, RejectsNonfiniteCoordinates)
{
    const double infinity = std::numeric_limits<double>::infinity();
    const double nan = std::numeric_limits<double>::quiet_NaN();
    const std::array<myproject::Sample, 2> infinite {{{0, 1}, {infinity, 2}}};
    const std::array<myproject::Sample, 2> missing {{{0, nan}, {1, 2}}};
    EXPECT_THROW(myproject::fit_line(infinite), std::invalid_argument);
    EXPECT_THROW(myproject::fit_line(missing), std::invalid_argument);
}

TEST(LinearFitTest, FormatsTheResult)
{
    const myproject::LinearFit fit {2, 1, 0};
    EXPECT_EQ(myproject::format_fit(fit), "y = 2 * x + 1; RMSE = 0");
}
