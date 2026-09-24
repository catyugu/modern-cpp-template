add_library(myproject_options INTERFACE)

# 前端在配置期就已知，两个变量取常量 0/1，下面继续当条件用。
# 不用 $<CXX_COMPILER_FRONTEND_VARIANT:...>：那个要 CMake 3.30，会让声明支持的 3.26~3.29 配置失败
if(CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
    set(_MYPROJECT_MSVC_FRONTEND 1)
    set(_MYPROJECT_GNU_FRONTEND 0)
else()
    set(_MYPROJECT_MSVC_FRONTEND 0)
    set(_MYPROJECT_GNU_FRONTEND 1)
endif()

# 这里只放"编译本仓库自己的代码需要的"选项：警告集、Werror、源码编码。
# 不设 -O/-DNDEBUG/-g：优化级别与调试信息由 CMAKE_BUILD_TYPE 决定（CMake 默认 Release 就是
# -O3 -DNDEBUG，本库若再追加 -O2 反而把父项目/默认的优化级别降下来），而构建类型属于构建的
# 所有者。fmt、spdlog、googletest、abseil、nlohmann/json 同样不设这些。
target_compile_options(myproject_options INTERFACE
    $<${_MYPROJECT_GNU_FRONTEND}:
    -Wpedantic
    >
)

target_compile_options(myproject_options INTERFACE
    $<${_MYPROJECT_MSVC_FRONTEND}:
    /W4
    /permissive-
    /utf-8
    /bigobj
    /Zc:__cplusplus
    # 只在 /W4 + /WX 下把正常代码变成错误的、对库代码没有可行动信号的两条：导出类继承/内嵌标准库
    # 类型是正常做法，MSVC 文档也说明可忽略，gtest（-wd4251 -wd4275）、re2、spdlog 同样关掉。
    # 4127、4189/4100、4702 等有意义的警告照常报错，配 /WX 时仍会中断构建（已实测）
    /wd4251 # 'type' needs to have dll-interface to be used by clients of class
    /wd4275 # non dll-interface class used as base for dll-interface class
    >
)

if(MYPROJECT_WERROR)
    target_compile_options(myproject_options INTERFACE
        $<${_MYPROJECT_GNU_FRONTEND}:-Werror>
        $<${_MYPROJECT_MSVC_FRONTEND}:/WX>
    )
endif()

# 以下两项只在作为顶层项目时追加：它们属于构建的所有者。目录作用域的选项会追加在父项目
# CMAKE_CXX_FLAGS_<CONFIG> 之后并覆盖它，作为子项目时本库就会忽略父项目的构建策略。
if(PROJECT_IS_TOP_LEVEL)
    # -g3 -ggdb：给 gdb 完整的宏信息；-fno-omit-frame-pointer：让采样 profiler 能走栈
    # （-O0 下帧指针本来就保留，所以它只在优化构建里有意义）
    target_compile_options(myproject_options INTERFACE
        $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:Debug>>:-g3>
        $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:Debug>>:-ggdb>
        $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:Release>>:-fno-omit-frame-pointer>
        $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:RelWithDebInfo>>:-fno-omit-frame-pointer>
    )

    # -rdynamic 只对最终的可执行目标有意义（Linux 上让栈回溯带符号名），因此只作用于本仓库
    # 自己的测试/示例/工具。注意 $<PLATFORM_ID> 的匹配区分大小写：写 linux 恒为假
    target_link_options(myproject_options INTERFACE
        $<$<AND:$<PLATFORM_ID:Linux>,${_MYPROJECT_GNU_FRONTEND}>:-rdynamic>
    )
endif()

option(MYPROJECT_ENABLE_COVERAGE "Enable code coverage instrumentation" OFF)
if(MYPROJECT_ENABLE_COVERAGE)
    target_compile_options(myproject_options INTERFACE
        $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:Debug>>:--coverage>
    )
    target_link_options(myproject_options INTERFACE
        $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:Debug>>:--coverage>
    )
endif()

unset(_MYPROJECT_GNU_FRONTEND)
unset(_MYPROJECT_MSVC_FRONTEND)
