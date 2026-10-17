cmake_minimum_required(VERSION 3.26)

# 同一份源码经两条路径被引入时（两个子项目各自 add_subdirectory 本仓库），目标会被重复定义；
# 已在构建树里就退出，让后一处复用已有目标。
if(TARGET myproject::myproject)
    return()
endif()

# 默认项目名称，会被 Python 脚本替换。C 是有意保留的：模板同样适用于含 C 源码的项目
project(MyProject LANGUAGES CXX C)

# 版本放在项目作用域变量里，不用 project(VERSION)：后者会把 CMAKE_PROJECT_VERSION{,_MAJOR,_MINOR,_PATCH,_TWEAK}
# 写进 cache，父项目若自己不声明版本，就会在自己的作用域里读到本库的版本
set(MYPROJECT_VERSION_MAJOR 0)
set(MYPROJECT_VERSION_MINOR 1)
set(MYPROJECT_VERSION_PATCH 0)
set(MYPROJECT_VERSION "${MYPROJECT_VERSION_MAJOR}.${MYPROJECT_VERSION_MINOR}.${MYPROJECT_VERSION_PATCH}")

# Pre-1.0 minor releases may break ABI; after 1.0 the major is the ABI boundary.
# Keep the ELF/Mach-O SONAME and find_package version policy consistent.
if(MYPROJECT_VERSION_MAJOR EQUAL 0)
    set(MYPROJECT_ABI_VERSION "${MYPROJECT_VERSION_MAJOR}.${MYPROJECT_VERSION_MINOR}")
    set(MYPROJECT_VERSION_COMPATIBILITY SameMinorVersion)
else()
    set(MYPROJECT_ABI_VERSION "${MYPROJECT_VERSION_MAJOR}")
    set(MYPROJECT_VERSION_COMPATIBILITY SameMajorVersion)
endif()

# 构建策略属于构建的所有者：作为子项目时由父项目决定构建类型、并行度等
if(PROJECT_IS_TOP_LEVEL)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

    # 多配置生成器（Visual Studio / Xcode / Ninja Multi-Config）里 CMAKE_BUILD_TYPE 不是 cache
    # 变量，对它的 CACHE 操作会让 configure 直接失败
    if(NOT CMAKE_CONFIGURATION_TYPES)
        if(NOT CMAKE_BUILD_TYPE)
            set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the type of build." FORCE)
        endif()
        set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release RelWithDebInfo MinSizeRel)
        message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
    else()
        message(STATUS "Multi-config generator: ${CMAKE_CONFIGURATION_TYPES}")
    endif()

endif()

# 独立构建默认全开；作为子项目时默认只构建库目标
option(MYPROJECT_BUILD_EXAMPLES "build examples" ${PROJECT_IS_TOP_LEVEL})
option(MYPROJECT_BUILD_TESTS "build tests" ${PROJECT_IS_TOP_LEVEL})
option(MYPROJECT_BUILD_TOOLS "build tools" ${PROJECT_IS_TOP_LEVEL})
option(MYPROJECT_WERROR "treat warnings in this project as errors" ${PROJECT_IS_TOP_LEVEL})
option(MYPROJECT_INSTALL "install library and CMake package" ${PROJECT_IS_TOP_LEVEL})

# 安装布局变量（CMAKE_INSTALL_LIBDIR 等）必须在第一次使用 ${CMAKE_INSTALL_*} 之前 include：
# 变量在命令执行时展开，否则 $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}> 只在某个依赖
# 恰好先 include 它时才非空，依赖一变导出目标就静默丢掉 include 目录
include(GNUInstallDirs)

# 生成的头文件位于构建目录，但保持与安装后一致的 include 布局
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/config.h.in ${PROJECT_BINARY_DIR}/include/myproject/config.h)

include(cmake/myprojectOptions.cmake)
include(cmake/Dependencies.cmake)

# Explicit sources are reviewed and compiled; FILE_SET HEADERS owns their
# include paths and the install/export layout, including generated config.h.
add_library(myproject)
add_library(myproject::myproject ALIAS myproject)

target_sources(myproject
    PRIVATE
        src/core.cpp
        src/cli.cpp
        src/options.hpp
    PUBLIC
        FILE_SET HEADERS
        BASE_DIRS
            "${PROJECT_SOURCE_DIR}/include"
            "${PROJECT_BINARY_DIR}/include"
        FILES
            "${PROJECT_SOURCE_DIR}/include/myproject/core.hpp"
            "${PROJECT_SOURCE_DIR}/include/myproject/cli.hpp"
            "${PROJECT_SOURCE_DIR}/include/myproject/export.hpp"
            "${PROJECT_BINARY_DIR}/include/myproject/config.h"
)
target_include_directories(myproject PRIVATE "${PROJECT_SOURCE_DIR}/src")
target_link_libraries(myproject PRIVATE
    $<BUILD_INTERFACE:myproject_options>
    ${MYPROJECT_PRIVATE_LIBRARIES}
)

# C++20 是 myproject 向使用方发布的唯一要求
target_compile_features(myproject PUBLIC cxx_std_20)

# VERSION/SOVERSION apply to shared libraries only. Before 1.0, the minor
# version is the ABI boundary; using just SOVERSION=0 would be incorrect.
# 可见性属性让共享库默认隐藏符号：ELF/Mach-O 的默认是全部导出（连内部实现一起进动态符号表），
# 因此公开接口上的每个类型/函数都必须带 MYPROJECT_API（见 include/myproject/export.hpp）
set_target_properties(myproject PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    CXX_VISIBILITY_PRESET hidden
    CXX_EXTENSIONS OFF
    VISIBILITY_INLINES_HIDDEN ON
    DEBUG_POSTFIX "d"
    VERSION ${MYPROJECT_VERSION}
    SOVERSION ${MYPROJECT_ABI_VERSION}
)

if(BUILD_SHARED_LIBS)
    target_compile_definitions(myproject
        PRIVATE MYPROJECT_EXPORTS
        PUBLIC MYPROJECT_SHARED
    )
endif()

# 把目标的运行时 DLL 拷到它自己所在目录，保证构建树里可直接运行、ctest 能找到。
# $<TARGET_RUNTIME_DLLS:> 在非 DLL 平台恒为空，所以不需要平台或 BUILD_SHARED_LIBS 判断
function(myproject_stage_runtime target)
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy -t $<TARGET_FILE_DIR:${target}> $<TARGET_RUNTIME_DLLS:${target}>
        COMMAND_EXPAND_LISTS
    )
endfunction()

if(MYPROJECT_INSTALL)
    install(TARGETS myproject EXPORT myprojectTargets
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        FILE_SET HEADERS DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )

    # 许可证随安装产物分发；CMAKE_INSTALL_DOCDIR 由 GNUInstallDirs 按项目名给出
    install(FILES "${PROJECT_SOURCE_DIR}/LICENSE"
        DESTINATION ${CMAKE_INSTALL_DOCDIR}
    )

    include(CMakePackageConfigHelpers)

    install(EXPORT myprojectTargets
        FILE myprojectTargets.cmake
        NAMESPACE myproject::
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/myproject
    )

    configure_package_config_file(
        "${PROJECT_SOURCE_DIR}/cmake/myprojectConfig.cmake.in"
        "${PROJECT_BINARY_DIR}/myprojectConfig.cmake"
        INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/myproject
    )
    # Apply the same compatibility boundary used by SOVERSION.
    write_basic_package_version_file(
        "${PROJECT_BINARY_DIR}/myprojectConfigVersion.cmake"
        VERSION ${MYPROJECT_VERSION}
        COMPATIBILITY ${MYPROJECT_VERSION_COMPATIBILITY}
    )
    install(FILES
        "${PROJECT_BINARY_DIR}/myprojectConfig.cmake"
        "${PROJECT_BINARY_DIR}/myprojectConfigVersion.cmake"
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/myproject
    )
endif()

if(MYPROJECT_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

if(MYPROJECT_BUILD_TESTS)
    # 只有顶层项目负责开启 CTest；作为子项目时由父项目决定
    if(PROJECT_IS_TOP_LEVEL)
        enable_testing()
    endif()
    add_subdirectory(tests)
endif()

if(MYPROJECT_BUILD_TOOLS)
    add_subdirectory(tools)
endif()
