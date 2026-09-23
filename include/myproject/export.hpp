#pragma once

// MYPROJECT_SHARED is published by the build system when the library is built
// as a shared library; MYPROJECT_EXPORTS only while compiling its own sources.
#if defined(_WIN32) && defined(MYPROJECT_SHARED)
#    if defined(MYPROJECT_EXPORTS)
#        define MYPROJECT_API __declspec(dllexport)
#    else
#        define MYPROJECT_API __declspec(dllimport)
#    endif
#elif defined(MYPROJECT_SHARED) && (defined(__GNUC__) || defined(__clang__))
// 共享库在 ELF/Mach-O 上默认导出全部符号；目标属性 CXX_VISIBILITY_PRESET hidden 改为默认隐藏，
// 所以公开接口上的每个类型/函数都必须带 MYPROJECT_API
#    define MYPROJECT_API __attribute__((visibility("default")))
#else
#    define MYPROJECT_API
#endif
