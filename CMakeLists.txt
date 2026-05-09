cmake_minimum_required(VERSION 3.24)

# 默认项目名称，会被 Python 脚本替换
project(MyProject VERSION 0.1.0 LANGUAGES CXX)

# 设置 C++20 标准
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 设置输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# --- 依赖管理 (centralized in cmake/Dependencies.cmake) ---
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(cmake/Dependencies.cmake)

# --- 添加子模块 ---
add_subdirectory(src)
add_subdirectory(bin)

if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME OR BUILD_TESTING)
    add_subdirectory(test)
endif()
