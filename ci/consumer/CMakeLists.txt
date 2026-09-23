cmake_minimum_required(VERSION 3.26)

# Out-of-tree consumer of the installed package: find_package() only, no
# add_subdirectory of the library. Driven by ci/run_checks.sh and by CI.
project(myproject_consumer LANGUAGES CXX)

find_package(myproject REQUIRED CONFIG)

add_executable(consumer main.cpp)
target_link_libraries(consumer PRIVATE myproject::myproject)
