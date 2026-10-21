# Set the default before CPM initializes its cache; command-line and environment
# settings belong to the build owner and take precedence.
if(PROJECT_IS_TOP_LEVEL AND NOT DEFINED CPM_SOURCE_CACHE AND NOT DEFINED ENV{CPM_SOURCE_CACHE})
    set(CPM_SOURCE_CACHE "${PROJECT_SOURCE_DIR}/.cache/cpm"
        CACHE PATH "CPM dependency source cache")
endif()
if(NOT COMMAND CPMAddPackage)
    include("${CMAKE_CURRENT_LIST_DIR}/CPM.cmake")
endif()

# Existing targets are authoritative: the parent owns their compatibility.
# Otherwise let CPM try an installed package, then fetch the pinned fallback.
# Use SYSTEM YES for third-party headers to keep our warning policy local.
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
