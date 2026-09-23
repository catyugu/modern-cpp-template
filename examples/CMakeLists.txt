# 示例可执行：只依赖库的公开接口
add_executable(myproject_example main.cpp)

target_link_libraries(myproject_example
    PRIVATE
    myproject::myproject
    myproject_options
)

myproject_stage_runtime(myproject_example)
