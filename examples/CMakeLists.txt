# 示例可执行：演示内部库 myproject + 第三方库 cxxopts + 生成的 config.h 的协作方式
add_executable(myproject_example main.cpp)

# 生成的 config.h 位于构建目录顶层（configure_file 输出到 ${CMAKE_BINARY_DIR}/config.h）
target_include_directories(myproject_example
    PRIVATE
    ${CMAKE_BINARY_DIR}
)

# 链接内部库和第三方库 cxxopts
target_link_libraries(myproject_example
    PRIVATE
    myproject
    cxxopts::cxxopts
)
