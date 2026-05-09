# # Dependencies.cmake
# Centralized dependency management (FetchContent)

include(CPM)

# cxxopts command-line parsing library
CPMAddPackage(
  NAME cxxopts
  GITHUB_REPOSITORY jarro2783/cxxopts
  GIT_TAG v3.0.0
)

# googletest
if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME OR BUILD_TESTING)
  enable_testing()
  CPMAddPackage(
    NAME googletest
    GITHUB_REPOSITORY google/googletest
    GIT_TAG v1.17.0
    OPTIONS
    "BUILD_GMOCK OFF"
    "INSTALL_GTEST OFF"
  )
endif()