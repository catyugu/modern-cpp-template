add_library(myproject_options INTERFACE)

set(_MYPROJECT_GNU_FRONTEND $<CXX_COMPILER_FRONTEND_VARIANT:GNU>)
set(_MYPROJECT_MSVC_FRONTEND $<CXX_COMPILER_FRONTEND_VARIANT:MSVC>)

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
    # 只在 /W4 + /WX 组合下才会把正常代码变成错误的、对库代码没有可行动信号的两条：
    # 导出类继承/内嵌标准库类型（std::string、std::runtime_error 跨 DLL 使用）是正常做法，
    # MSVC 文档也说明这类情况可以忽略，gtest（-wd4251 -wd4275）、re2、spdlog 同样关掉。
    # 有意义的警告一律保留：4127（常量条件表达式）、4189/4100（未使用变量/参数）、4702（不可达
    # 代码）等照常报错，配 /WX 时仍会中断构建（已实测）
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
