# # Dependencies.cmake
# Centralized dependency management (CPM / FetchContent)

# CPM 默认把 <name>-config.cmake 写进 CMAKE_FIND_PACKAGE_REDIRECTS_DIR，而该目录属于整棵
# 构建树：作为子项目时它就是父项目的构建根，父项目之后的 find_package(cxxopts/GTest) 会
# 静默拿到本仓库锁定的版本。本仓库的依赖只经 target 链接使用，不需要这个重定向。
set(CPM_DONT_UPDATE_MODULE_PATH ON)

# 用本仓库自带的 CPM：include(CPM) 要经 CMAKE_MODULE_PATH 解析，父项目里同名的 CPM.cmake
# 可能排在前面并静默顶替本仓库锁定的这份。CMAKE_CURRENT_LIST_DIR 是包含本文件自身的目录
include("${CMAKE_CURRENT_LIST_DIR}/CPM.cmake")

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
