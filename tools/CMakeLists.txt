# 小型工具：myproject_wc —— 统计文件的行数/单词数/字节数（类似 Unix wc）
# 该工具自包含，不依赖内部库，仅使用第三方库 cxxopts 解析命令行参数
add_executable(myproject_wc main.cpp)

target_link_libraries(myproject_wc
    PRIVATE
    cxxopts::cxxopts
)
