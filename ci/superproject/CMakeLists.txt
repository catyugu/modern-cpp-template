cmake_minimum_required(VERSION 3.26)

# A parent project that embeds the library with add_subdirectory. Driven by
# ci/run_checks.sh and by CI.
project(superproject LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Must come before add_subdirectory: the library's add_test calls are dropped
# unless testing is already enabled in the tree.
enable_testing()

add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/../.." myproject-build)

add_executable(superapp src/main.cpp)
target_link_libraries(superapp PRIVATE myproject::myproject)

# The library does not deploy its runtime, so a parent that wants a runnable
# build-tree executable asks for it (see the README).
myproject_stage_runtime(superapp)

add_test(NAME superproject.smoke COMMAND superapp)
