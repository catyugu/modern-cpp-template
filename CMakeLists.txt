cmake_minimum_required(VERSION 3.26)

# 目标名在整棵构建树里是全局的：同一份源码若经两条依赖路径被引入（两个子项目各自
# add_subdirectory/FetchContent 本仓库），myproject 等目标会被重复定义并直接报错。
# 已在构建树里就退出，让后一处引入复用已有目标。
if(TARGET myproject::myproject)
    return()
endif()

# 默认项目名称，会被 Python 脚本替换
project(MyProject VERSION 0.1.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

# Build policy belongs to whoever owns the build. As a subproject the
# superproject decides build type, parallel level and compile commands.
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

# CPM 的源码缓存目录是本仓库的构建便利，不该替父项目决定依赖下载位置
if(PROJECT_IS_TOP_LEVEL)
    set(CPM_SOURCE_CACHE "${CMAKE_CURRENT_SOURCE_DIR}/.cache/cpm" CACHE PATH "CPM cache to avoid repeated fetching")
endif()

# 独立构建默认全开；作为子项目时默认只构建库目标
option(MYPROJECT_BUILD_EXAMPLES "build examples" ${PROJECT_IS_TOP_LEVEL})
option(MYPROJECT_BUILD_TESTS "build tests" ${PROJECT_IS_TOP_LEVEL})
option(MYPROJECT_BUILD_TOOLS "build tools" ${PROJECT_IS_TOP_LEVEL})
option(MYPROJECT_INSTALL "generate the install target" ${PROJECT_IS_TOP_LEVEL})
option(MYPROJECT_WERROR "treat warnings in this project as errors" ${PROJECT_IS_TOP_LEVEL})

# 生成的头文件位于构建目录，但保持与安装后一致的 include 布局
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/config.h.in ${PROJECT_BINARY_DIR}/include/myproject/config.h)

include(cmake/myprojectOptions.cmake)

# dependencies
include(cmake/Dependencies.cmake)

# library target: implementation in src/ (with its private headers), public headers under include/<project>/
file(GLOB_RECURSE MYPROJECT_SOURCES CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/src/*.cpp" "${PROJECT_SOURCE_DIR}/src/*.cc" "${PROJECT_SOURCE_DIR}/src/*.c")
file(GLOB_RECURSE MYPROJECT_HEADERS CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/include/*.h" "${PROJECT_SOURCE_DIR}/include/*.hpp")
file(GLOB_RECURSE MYPROJECT_PRIVATE_HEADERS CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/src/*.h" "${PROJECT_SOURCE_DIR}/src/*.hpp")

add_library(myproject ${MYPROJECT_SOURCES} ${MYPROJECT_HEADERS} ${MYPROJECT_PRIVATE_HEADERS})
add_library(myproject::myproject ALIAS myproject)

target_include_directories(myproject PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    PRIVATE
    ${PROJECT_SOURCE_DIR}/src
)

# 严格编译选项与第三方依赖都只是本仓库的构建期需求：用 BUILD_INTERFACE 包住后
# 既不成为 myproject 的对外使用需求，也不会被 install(EXPORT) 要求一起导出。
# 依赖本身在 cmake/Dependencies.cmake 里声明并挂到 myproject_dependencies 上。
target_link_libraries(myproject PRIVATE
    $<BUILD_INTERFACE:myproject_options>
    $<BUILD_INTERFACE:myproject_dependencies>
)

# C++20 是 myproject 向使用方发布的唯一要求
target_compile_features(myproject PUBLIC cxx_std_20)
set_target_properties(myproject PROPERTIES POSITION_INDEPENDENT_CODE ON)

if(BUILD_SHARED_LIBS)
    target_compile_definitions(myproject
        PRIVATE MYPROJECT_EXPORTS
        PUBLIC MYPROJECT_SHARED
    )
endif()

# 把目标依赖的运行时 DLL 拷到它自己所在目录，保证构建树里可直接运行、ctest 能找到。
# $<TARGET_RUNTIME_DLLS:> 会枚举全部传递依赖里的 SHARED 目标，且在非 DLL 平台恒为空，
# 因此这里不需要平台或 BUILD_SHARED_LIBS 判断（-t 形式的 copy 需要 CMake 3.26）。
function(myproject_stage_runtime target)
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy -t $<TARGET_FILE_DIR:${target}> $<TARGET_RUNTIME_DLLS:${target}>
        COMMAND_EXPAND_LISTS
    )
endfunction()

if(MYPROJECT_INSTALL)
    include(GNUInstallDirs)

    install(TARGETS myproject EXPORT myprojectTargets
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
