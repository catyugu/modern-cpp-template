cmake_minimum_required(VERSION 3.24)

# 默认项目名称，会被 Python 脚本替换
project(MyProject VERSION 0.1.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CPM_SOURCE_CACHE "${CMAKE_SOURCE_DIR}/.cache/cpm" CACHE PATH "CPM cache to avoid repeated fetching")

option(MYPROJECT_BUILD_EXAMPLES "build examples" ON)
option(MYPROJECT_BUILD_TESTS "build tests" ON)
option(MYPROJECT_BUILD_TOOLS "build tools" ON)

configure_file(${CMAKE_SOURCE_DIR}/cmake/config.h.in ${CMAKE_BINARY_DIR}/config.h)

if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the type of build." FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release RelWithDebInfo MinSizeRel)
endif()

set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release RelWithDebInfo MinSizeRel)
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")

# Automatically detect CPU core number.
cmake_host_system_information(RESULT CPU_NUMS QUERY NUMBER_OF_LOGICAL_CORES)
message(STATUS "CPU NUMS on current device is:${CPU_NUMS}")
math(EXPR JOBS "${CPU_NUMS} + ${CPU_NUMS} / 2")
set(CMAKE_BUILD_PARALLEL_LEVEL ${JOBS} CACHE STRING "parallel compiling thread num")
message(STATUS "Compiler default work jobs: ${CMAKE_BUILD_PARALLEL_LEVEL}")

include(cmake/myprojectOptions.cmake)

# dependencies
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(cmake/Dependencies.cmake)

add_subdirectory(myproject)

if(MYPROJECT_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

if(MYPROJECT_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

if(MYPROJECT_BUILD_TOOLS)
    add_subdirectory(tools)
endif()
