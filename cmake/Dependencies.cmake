# # Dependencies.cmake
# 唯一的依赖声明处：顶层 CMakeLists.txt 与各子目录只引用变量 MYPROJECT_DEPENDENCIES，
# 新增依赖只改本文件。

# 作为子项目时这两项会写进父项目的构建根（find_package 重定向、CPM 的 lock 文件），
# 本仓库的依赖只经 target 使用，不需要它们
set(CPM_DONT_UPDATE_MODULE_PATH ON)
set(CPM_DONT_CREATE_PACKAGE_LOCK ON)

# 用本仓库自带的 CPM，而不是经 CMAKE_MODULE_PATH 解析（父项目里可能有一份同名的）
include("${CMAKE_CURRENT_LIST_DIR}/CPM.cmake")

# 源码缓存只是独立构建时的便利，不该替父项目决定依赖下载位置
if(PROJECT_IS_TOP_LEVEL)
  set(CPM_SOURCE_CACHE "${PROJECT_SOURCE_DIR}/.cache/cpm" CACHE PATH "CPM cache to avoid repeated fetching")
endif()

# fmt：编译型依赖，由实现层（src/core.cpp、src/cli.cpp）使用；获取与构建都交给 CPM/fmt 自己。
# FMT_MODULE OFF：不需要它额外构建一份 C++20 模块目标（这是 fmt 自己文档化的选项）
CPMAddPackage(
  NAME fmt
  GITHUB_REPOSITORY fmtlib/fmt
  GIT_TAG 12.2.0
  OPTIONS
  "FMT_MODULE OFF"
)

# 随 myproject 一起安装/导出的依赖目标：静态构建时导出目标会引用它（消费者链接需要它的库
# 文件），共享构建时它的 DLL/so 也要一并安装。写真实目标名（别名不能 install）。
# 它的头文件不装：公开头文件里没有第三方类型，消费者不需要。fmt 无条件给目标设了 PUBLIC_HEADER，
# 而我们的 install(TARGETS) 不装依赖的头文件 —— 清空该属性，否则 CMake 会报 author warning，
# 父项目若以 -Werror=dev 配置就会直接失败
set(MYPROJECT_DEPENDENCIES fmt)
set_target_properties(fmt PROPERTIES PUBLIC_HEADER "")

# googletest：只有测试使用，不进 MYPROJECT_DEPENDENCIES，由 tests/ 直接链接；
# 优先复用父项目或系统已提供的 GTest。固定为静态库，避免 BUILD_SHARED_LIBS 把 gtest
# 变成需要额外分发的 DLL
if(MYPROJECT_BUILD_TESTS AND NOT TARGET GTest::gtest_main)
  CPMFindPackage(
    NAME GTest
    GITHUB_REPOSITORY google/googletest
    GIT_TAG "d72f9c8"
    OPTIONS
    "BUILD_GMOCK OFF"
    "INSTALL_GTEST OFF"
    "BUILD_SHARED_LIBS OFF"
  )
endif()
