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
    /WX
    /permissive-
    /utf-8
    /bigobj
    /Zc:__cplusplus
    >
)

target_compile_options(myproject_options INTERFACE
    $<$<AND:$<PLATFORM_ID:linux>,${_MYPROJECT_GNU_FRONTEND}>:
    -fPIC
    >
)

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

option(ENABLE_COVERAGE "Enable code coverage instrumentation" OFF)
if(ENABLE_COVERAGE)
    target_compile_options(myproject_options INTERFACE
        $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:Debug>>:--coverage>
    )
    target_link_options(myproject_options INTERFACE
        $<$<AND:${_MYPROJECT_GNU_FRONTEND},$<CONFIG:Debug>>:--coverage>
    )
endif()

unset(_MYPROJECT_GNU_FRONTEND)
unset(_MYPROJECT_MSVC_FRONTEND)
