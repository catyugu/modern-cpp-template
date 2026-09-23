cmake_minimum_required(VERSION 3.26)

# 同一份源码经两条路径被引入时（两个子项目各自 add_subdirectory 本仓库），目标会被重复定义；
# 已在构建树里就退出，让后一处复用已有目标。
if(TARGET myproject::myproject)
    return()
endif()

# 默认项目名称，会被 Python 脚本替换。C 是有意保留的：模板同样适用于含 C 源码的项目
project(MyProject VERSION 0.1.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

# 构建策略属于构建的所有者：作为子项目时由父项目决定构建类型、并行度等
if(PROJECT_IS_TOP_LEVEL)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

    if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
        set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the type of build." FORCE)
    endif()
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release RelWithDebInfo MinSizeRel)
    message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")

    # Automatically detect CPU core number.
    cmake_host_system_information(RESULT CPU_NUMS QUERY NUMBER_OF_LOGICAL_CORES)
    message(STATUS "CPU NUMS on current device is:${CPU_NUMS}")
    math(EXPR JOBS "${CPU_NUMS} + ${CPU_NUMS} / 2")
    set(CMAKE_BUILD_PARALLEL_LEVEL ${JOBS} CACHE STRING "parallel compiling thread num")
    message(STATUS "Compiler default work jobs: ${CMAKE_BUILD_PARALLEL_LEVEL}")
endif()

# 独立构建默认全开；作为子项目时默认只构建库目标
option(MYPROJECT_BUILD_EXAMPLES "build examples" ${PROJECT_IS_TOP_LEVEL})
option(MYPROJECT_BUILD_TESTS "build tests" ${PROJECT_IS_TOP_LEVEL})
option(MYPROJECT_BUILD_TOOLS "build tools" ${PROJECT_IS_TOP_LEVEL})
option(MYPROJECT_WERROR "treat warnings in this project as errors" ${PROJECT_IS_TOP_LEVEL})
option(MYPROJECT_INSTALL "generate the install target" ON)

# 生成的头文件位于构建目录，但保持与安装后一致的 include 布局
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/config.h.in ${PROJECT_BINARY_DIR}/include/myproject/config.h)

include(cmake/myprojectOptions.cmake)
include(cmake/Dependencies.cmake)

# library target: implementation in src/ (with its private headers), public headers under include/<project>/
file(GLOB_RECURSE MYPROJECT_SOURCES CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/src/*.cpp" "${PROJECT_SOURCE_DIR}/src/*.cc" "${PROJECT_SOURCE_DIR}/src/*.c")
file(GLOB_RECURSE MYPROJECT_HEADERS CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/include/*.h" "${PROJECT_SOURCE_DIR}/include/*.hpp")
file(GLOB_RECURSE MYPROJECT_PRIVATE_HEADERS CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/src/*.h" "${PROJECT_SOURCE_DIR}/src/*.hpp")

# 库目标 = 自己的源码（依赖经 MYPROJECT_DEPENDENCIES 链接，见 cmake/Dependencies.cmake）
add_library(myproject ${MYPROJECT_SOURCES} ${MYPROJECT_HEADERS} ${MYPROJECT_PRIVATE_HEADERS})
add_library(myproject::myproject ALIAS myproject)

target_include_directories(myproject PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    PRIVATE
    ${PROJECT_SOURCE_DIR}/src
)

# 编译选项只用于本仓库自己的构建；依赖要进导出目标，因此不包在 BUILD_INTERFACE 里
target_link_libraries(myproject PRIVATE
    $<BUILD_INTERFACE:myproject_options>
    ${MYPROJECT_DEPENDENCIES}
)

# C++20 是 myproject 向使用方发布的唯一要求
target_compile_features(myproject PUBLIC cxx_std_20)

# VERSION/SOVERSION 只对共享库有意义：ELF 上生成 libmyproject.so.0.1.0 与 .so.0 符号链接（SONAME），
# 静态库忽略它们；Windows 的 DLL 名不受影响。SOVERSION 取主版本号，即 ABI 兼容的承诺范围
set_target_properties(myproject PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
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
    include(GNUInstallDirs)

    install(TARGETS myproject ${MYPROJECT_DEPENDENCIES} EXPORT myprojectTargets
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )

    # public header files, installed preserving the include/<project>/ layout
    install(DIRECTORY "${PROJECT_SOURCE_DIR}/include/"
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )
    install(FILES "${PROJECT_BINARY_DIR}/include/myproject/config.h"
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/myproject
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
    write_basic_package_version_file(
        "${PROJECT_BINARY_DIR}/myprojectConfigVersion.cmake"
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMajorVersion
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
