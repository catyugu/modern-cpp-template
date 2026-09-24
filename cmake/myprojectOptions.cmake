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

target_compile_options(myproject_options INTERFACE
    $<${_MYPROJECT_GNU_FRONTEND}:
    -Wpedantic
    -fno-strict-aliasing
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

target_link_options(myproject_options INTERFACE
    $<$<AND:$<PLATFORM_ID:linux>,${_MYPROJECT_GNU_FRONTEND}>:
    -rdynamic # Required by stack traceback
    >
)

target_compile_definitions(myproject_options INTERFACE
    $<$<CONFIG:Debug>:MYPROJECT_DEBUG>
)

target_compile_options(myproject_options INTERFACE
    $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:Debug>>:-O0>
    $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:Debug>>:-g3>
    $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:Debug>>:-ggdb>
)

target_compile_options(myproject_options INTERFACE
    $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:Release>>:-DNDEBUG>
    $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:Release>>:-O2>
    $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:Release>>:-fno-omit-frame-pointer>
    $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:RelWithDebInfo>>:-DNDEBUG>
    $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:RelWithDebInfo>>:-O2>
    $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:RelWithDebInfo>>:-g>
    $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:RelWithDebInfo>>:-fno-omit-frame-pointer>
)

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
