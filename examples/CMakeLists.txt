# 示例可执行：演示内部库 myproject + 第三方库 cxxopts + 生成的 config.h 的协作方式
add_executable(myproject_example main.cpp)

# 生成的 config.h 通过 myproject 的构建接口可见（<build>/include/<project>/config.h）
target_link_libraries(myproject_example
    PRIVATE
    myproject::myproject
    myproject_options
    cxxopts::cxxopts
)
