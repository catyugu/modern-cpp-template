# # Dependencies.cmake
# Centralized dependency management (CPM / FetchContent)

include(CPM)

# cxxopts command-line parsing library
CPMAddPackage(
  NAME cxxopts
  GITHUB_REPOSITORY jarro2783/cxxopts
  GIT_TAG v3.0.0
)

# googletest
if(MYPROJECT_BUILD_TESTS)
  CPMAddPackage(
    NAME googletest
    GITHUB_REPOSITORY google/googletest
    GIT_TAG "d72f9c8"
    OPTIONS
    "BUILD_GMOCK OFF"
    "INSTALL_GTEST OFF"
  )
endif()
