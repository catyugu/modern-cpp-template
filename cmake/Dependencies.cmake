# Resolve dependency targets; linking and package installation are separate.
# Reuse parent targets, then installed packages, then download via CPM.
# Do not mutate a dependency's target properties or export third-party targets.

if(NOT TARGET fmt::fmt)
    find_package(fmt 12 CONFIG QUIET)
endif()

if(NOT TARGET fmt::fmt OR (MYPROJECT_BUILD_TESTS AND NOT TARGET GTest::gtest_main))
    set(CPM_DONT_UPDATE_MODULE_PATH ON)
    set(CPM_DONT_CREATE_PACKAGE_LOCK ON)
    if(NOT COMMAND CPMAddPackage)
        include("${CMAKE_CURRENT_LIST_DIR}/CPM.cmake")
    endif()
    if(PROJECT_IS_TOP_LEVEL AND NOT DEFINED CPM_SOURCE_CACHE)
        set(CPM_SOURCE_CACHE "${PROJECT_SOURCE_DIR}/.cache/cpm" CACHE PATH "CPM download cache")
    endif()
endif()

if(NOT TARGET fmt::fmt)
    # FMT_INSTALL creates fmt's own library, headers, and package config.
    # For an embedded build with installation disabled, add no install rules.
    CPMAddPackage(
        NAME fmt
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

if(NOT TARGET fmt::fmt)
    message(FATAL_ERROR "fmt::fmt was not provided by the selected dependency source")
endif()

# Private compiled dependency; static consumers still need it at link time.
set(MYPROJECT_PRIVATE_LIBRARIES fmt::fmt)

# Test-only dependency: never exported by myproject.
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
