# Set the default before CPM initializes its cache; command-line and environment
# settings belong to the build owner and take precedence.
if(PROJECT_IS_TOP_LEVEL AND NOT DEFINED CPM_SOURCE_CACHE AND NOT DEFINED ENV{CPM_SOURCE_CACHE})
    set(CPM_SOURCE_CACHE "${PROJECT_SOURCE_DIR}/.cache/cpm"
        CACHE PATH "CPM dependency source cache")
endif()
if(NOT COMMAND CPMAddPackage)
    include("${CMAKE_CURRENT_LIST_DIR}/CPM.cmake")
endif()

# Keep each dependency's acquisition, link scope, and installed requirement here.
set(MYPROJECT_PACKAGE_DEPENDENCIES "")

# fmt: PRIVATE implementation dependency; trust targets supplied by the parent.
set(MYPROJECT_FMT_MIN_VERSION 12.2.0)
if(NOT TARGET fmt::fmt)
    CPMFindPackage(
        NAME fmt
        VERSION ${MYPROJECT_FMT_MIN_VERSION}
        FIND_PACKAGE_ARGUMENTS CONFIG
        GITHUB_REPOSITORY fmtlib/fmt
        GIT_TAG ${MYPROJECT_FMT_MIN_VERSION}
        SYSTEM YES
        OPTIONS
        "FMT_INSTALL ${MYPROJECT_INSTALL}"
        "FMT_MODULE OFF"
        "FMT_TEST OFF"
        "FMT_DOC OFF"
        "FMT_SYSTEM_HEADERS ON"
    )
endif()
target_link_libraries(myproject PRIVATE fmt::fmt)

# PRIVATE dependencies remain in static exports; PUBLIC ones need this for both.
if(NOT BUILD_SHARED_LIBS)
    string(APPEND MYPROJECT_PACKAGE_DEPENDENCIES "
if(NOT TARGET fmt::fmt)
    find_dependency(fmt ${MYPROJECT_FMT_MIN_VERSION} CONFIG)
endif()
")
endif()

# Eigen: a header-only implementation dependency of this library. Nothing in the
# public headers includes it, so it is a build-only requirement: BUILD_LOCAL_INTERFACE
# keeps it out of the installed static target's link interface, and a consumer of
# the installed package never has to provide Eigen. fmt stays a real static link
# dependency and is exported as such.
set(MYPROJECT_EIGEN_MIN_VERSION 5.0.0)
if(NOT TARGET Eigen3::Eigen)
    CPMFindPackage(
        NAME Eigen3
        VERSION ${MYPROJECT_EIGEN_MIN_VERSION}
        FIND_PACKAGE_ARGUMENTS CONFIG
        GIT_REPOSITORY https://gitlab.com/libeigen/eigen.git
        GIT_TAG ${MYPROJECT_EIGEN_MIN_VERSION}
        SYSTEM YES
        OPTIONS
        "EIGEN_BUILD_TESTING OFF"
        "EIGEN_BUILD_CMAKE_PACKAGE ${MYPROJECT_INSTALL}"
    )
endif()
target_link_libraries(myproject PRIVATE $<BUILD_LOCAL_INTERFACE:Eigen3::Eigen>)

# Tests are optional and do not add a dependency to the installed package.
if(MYPROJECT_BUILD_TESTS AND NOT TARGET GTest::gtest_main)
    CPMFindPackage(
        NAME GTest
        VERSION 1.18.0
        FIND_PACKAGE_ARGUMENTS CONFIG
        GITHUB_REPOSITORY google/googletest
        GIT_TAG "v1.18.0"
        SYSTEM YES
        OPTIONS
        "BUILD_GMOCK OFF"
        "INSTALL_GTEST OFF"
        "BUILD_SHARED_LIBS OFF"
    )
endif()
