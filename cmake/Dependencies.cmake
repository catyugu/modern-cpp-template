# # Dependencies.cmake
# Centralized dependency management (CPM / FetchContent)

include(CPM)

# cxxopts command-line parsing library
if(NOT TARGET cxxopts::cxxopts)
  CPMAddPackage(
    NAME cxxopts
    GITHUB_REPOSITORY jarro2783/cxxopts
    GIT_TAG v3.0.0
  )
endif()

# googletest：优先使用父项目或系统已提供的 GTest，否则由 CPM 拉取
if(MYPROJECT_BUILD_TESTS AND NOT TARGET GTest::gtest_main)
  CPMFindPackage(
    NAME GTest
    GITHUB_REPOSITORY google/googletest
    GIT_TAG "d72f9c8"
    OPTIONS
    "BUILD_GMOCK OFF"
    "INSTALL_GTEST OFF"
  )
endif()
