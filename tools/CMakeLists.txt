# 小型工具：myproject_wc —— 统计文件的行数/单词数/字节数（类似 Unix wc）
# 该工具自包含，不依赖内部库，仅使用第三方库 cxxopts 解析命令行参数。
# 这里刻意直接链接 cxxopts 而不用 myproject_dependencies：那是库的实现依赖聚合目标，
# 链进来会把库用不到的依赖一并拖给这个工具

add_executable(myproject_wc main.cpp)

target_link_libraries(myproject_wc
    PRIVATE
    cxxopts::cxxopts
)
