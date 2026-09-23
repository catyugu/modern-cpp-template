# 小型工具：myproject_wc —— 统计文件的行数/单词数/字节数（类似 Unix wc）
# 自包含：不依赖内部库，也不使用任何第三方库

add_executable(myproject_wc main.cpp)

# 源码里的注释含非 ASCII 字符，而 MSVC 默认按系统代码页解析源文件（本目标不链
# myproject_options，拿不到那里的 /utf-8）
if(MSVC)
    target_compile_options(myproject_wc PRIVATE /utf-8)
endif()
