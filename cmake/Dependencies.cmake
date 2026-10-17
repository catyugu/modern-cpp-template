# Declare dependencies here; consumers of this file link the provided targets.
# CPMFindPackage tries installed packages first and fetches a pinned fallback.
set(CPM_DONT_UPDATE_MODULE_PATH ON)
set(CPM_DONT_CREATE_PACKAGE_LOCK ON)
if(NOT COMMAND CPMAddPackage)
    include("${CMAKE_CURRENT_LIST_DIR}/CPM.cmake")
endif()

if(PROJECT_IS_TOP_LEVEL AND NOT DEFINED CPM_SOURCE_CACHE)
    set(CPM_SOURCE_CACHE "${PROJECT_SOURCE_DIR}/.cache/cpm"
        CACHE PATH "CPM dependency source cache")
endif()

# Private library dependency: fmt installs its own package when fetched.
# The exported myproject package uses find_dependency(fmt).
if(NOT TARGET fmt::fmt)
    CPMFindPackage(
        NAME fmt
        VERSION 12
        FIND_PACKAGE_ARGUMENTS CONFIG
        GITHUB_REPOSITORY fmtlib/fmt
        GIT_TAG 12.2.0
        OPTIONS
            "FMT_INSTALL ${MYPROJECT_INSTALL}"
            "FMT_MODULE OFF"
            "FMT_TEST OFF"
            "FMT_DOC OFF"
            "FMT_SYSTEM_HEADERS ON"
    )
endif()
set(MYPROJECT_PRIVATE_LIBRARIES fmt::fmt)

# Tests are optional and do not add a dependency to the installed package.
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
