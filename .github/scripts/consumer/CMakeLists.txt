cmake_minimum_required(VERSION 3.26)

# Out-of-tree consumer of the installed package: find_package() only, no
# add_subdirectory of the library. Driven by .github/scripts/check_build.py.
project(myproject_consumer LANGUAGES CXX)

# Existing dependency targets must be reused without a second package lookup.
option(MYPROJECT_PREPROVIDE_DEPENDENCIES "Provide dependency targets before importing the library" OFF)
if(MYPROJECT_PREPROVIDE_DEPENDENCIES)
    find_package(fmt 12.2.0 REQUIRED CONFIG)
    set(CMAKE_DISABLE_FIND_PACKAGE_fmt ON)
endif()
find_package(myproject REQUIRED CONFIG)

get_target_property(_library_type myproject::myproject TYPE)
if(_library_type STREQUAL "STATIC_LIBRARY")
    # The archive needs its compiled dependency (fmt) at link time, but the
    # header-only build-only dependency (Eigen) must not leak into the export:
    # check_build.py disables the Eigen lookup to prove that.
    get_target_property(_links myproject::myproject INTERFACE_LINK_LIBRARIES)
    if(NOT "${_links}" MATCHES "fmt::fmt")
        message(FATAL_ERROR "Static package did not export fmt::fmt")
    endif()
    if("${_links}" MATCHES "Eigen3::Eigen")
        message(FATAL_ERROR "Static package exported the build-only Eigen3 dependency")
    endif()
endif()

get_target_property(_includes myproject::myproject INTERFACE_INCLUDE_DIRECTORIES)
foreach(_dir IN LISTS _includes)
    if(NOT _dir MATCHES "^\\$<" AND NOT EXISTS "${_dir}")
        message(FATAL_ERROR "Exported include directory does not exist: ${_dir}")
    endif()
endforeach()

add_executable(consumer main.cpp)
target_link_libraries(consumer PRIVATE myproject::myproject)

enable_testing()
add_test(NAME consumer.smoke COMMAND consumer)

# Use the installed library's directory, including its installed dependencies.
# CTest handles native path separators and multi-config executable locations.
if(WIN32)
    set(_runtime_path PATH)
elseif(APPLE)
    set(_runtime_path DYLD_LIBRARY_PATH)
else()
    set(_runtime_path LD_LIBRARY_PATH)
endif()
set_tests_properties(consumer.smoke PROPERTIES
    ENVIRONMENT_MODIFICATION "${_runtime_path}=path_list_prepend:$<TARGET_FILE_DIR:myproject::myproject>"
)
