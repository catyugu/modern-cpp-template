#pragma once

// MYPROJECT_SHARED is published by the build system when the library is built
// as a shared library; MYPROJECT_EXPORTS only while compiling its own sources.
//
// Public headers must stay ASCII-only: MSVC parses a source file in the system
// code page unless /utf-8 is given, and consumers do not inherit our own flags,
// so a non-ASCII comment here breaks their build.
#if defined(_WIN32) && defined(MYPROJECT_SHARED)
#if defined(MYPROJECT_EXPORTS)
#define MYPROJECT_API __declspec(dllexport)
#else
#define MYPROJECT_API __declspec(dllimport)
#endif
#elif defined(MYPROJECT_SHARED) && (defined(__GNUC__) || defined(__clang__))
// ELF/Mach-O export every symbol by default; the CXX_VISIBILITY_PRESET hidden
// target property flips that, so every public type and function must carry
// MYPROJECT_API.
#define MYPROJECT_API __attribute__((visibility("default")))
#else
#define MYPROJECT_API
#endif
