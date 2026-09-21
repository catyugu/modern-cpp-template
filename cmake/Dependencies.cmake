# # Dependencies.cmake
# Centralized dependency management (CPM / FetchContent)

include(CPM)

add_library(myproject_dependencies INTERFACE)

# cxxopts command-line parsing library: 由库的实现层（src/cli.cpp）使用，属于实现细节。
# v3.3.1 起自带 <cstdint>，可在 GCC 16 等较新编译器上构建
if(NOT TARGET cxxopts::cxxopts)
  CPMAddPackage(
    NAME cxxopts
    GITHUB_REPOSITORY jarro2783/cxxopts
    GIT_TAG v3.3.1
  )
endif()
target_link_libraries(myproject_dependencies INTERFACE cxxopts::cxxopts)

# googletest：只有测试使用，因此不进 myproject_dependencies，由 tests/ 直接链接。
# 优先使用父项目或系统已提供的 GTest，否则由 CPM 拉取。
# 固定为静态库，避免 BUILD_SHARED_LIBS 把 gtest 变成需要额外分发的 DLL
if(MYPROJECT_BUILD_TESTS AND NOT TARGET GTest::gtest_main)
  CPMFindPackage(
    NAME GTest
    GITHUB_REPOSITORY google/googletest
    GIT_TAG "d72f9c8"
    OPTIONS
    "BUILD_GMOCK OFF"
    "INSTALL_GTEST OFF"
    "BUILD_SHARED_LIBS OFF"
  )
endif()
