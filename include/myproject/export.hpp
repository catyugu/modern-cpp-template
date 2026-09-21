#pragma once

// MYPROJECT_SHARED is published by the build system when the library is built
// as a shared library; MYPROJECT_EXPORTS only while compiling its own sources.
#if defined(_WIN32) && defined(MYPROJECT_SHARED)
#    if defined(MYPROJECT_EXPORTS)
#        define MYPROJECT_API __declspec(dllexport)
#    else
#        define MYPROJECT_API __declspec(dllimport)
#    endif
#else
#    define MYPROJECT_API
#endif
