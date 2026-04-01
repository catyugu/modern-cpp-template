# 声明可执行文件目标
add_executable(myproject_bin main.cpp)

# 链接内部库和第三方库 cxxopts
target_link_libraries(myproject_bin 
    PRIVATE 
        MyProject::myproject_lib
        cxxopts::cxxopts
)
