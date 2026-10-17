# Modern C++ Template (MyProject)

一个基于 CMake 的现代 C++ 项目模板，使用 C++20 和 CPM 管理第三方依赖（示例包含 `fmt` 与 `googletest`）。库目标的源码位于 `src/`、公共头位于 `include/myproject/`，配有单元测试 `tests/`、示例 `examples/` 与独立工具 `tools/`。安装包通过标准的 `find_dependency` 声明外部依赖；独立构建可以同时安装 CPM 下载的 fmt，使用系统 fmt 时由消费者自行提供。

## 特性

- **C++20**：项目启用 C++20 标准。
- **现代 CMake**：顶层 `CMakeLists.txt` 定义库目标，`cmake/myprojectOptions.cmake` 提供跨编译器/配置的编译选项。
- **中央化依赖**：依赖只在 `cmake/Dependencies.cmake` 里出现，其余文件只引用变量 `MYPROJECT_DEPENDENCIES`。
- **可测性**：内置 GoogleTest 示例与 CTest 集成。
- **可配置构建项**：`MYPROJECT_BUILD_EXAMPLES` / `MYPROJECT_BUILD_TESTS` / `MYPROJECT_BUILD_TOOLS` 分别开关示例、测试与工具，作为子项目嵌入时默认关闭。`MYPROJECT_INSTALL` 顶层默认开启，嵌入时默认关闭，父项目可显式覆盖；开启时开启安装后父项目自己的 `cmake --install` 会连本库一起装进父项目的 prefix，见「作为子项目嵌入」。
- **编译选项集中管理**：警告集与 `MYPROJECT_WERROR` 在 `cmake/myprojectOptions.cmake`，只作用于本仓库自己的代码；优化级别与调试信息交给 `CMAKE_BUILD_TYPE`，见「编译选项」。
- **代码格式**：`.clang-format` + `python ci/check_format.py`，见「代码格式」。

## 要求

- CMake >= 3.26
- 支持的编译器：GCC / Clang / MSVC（符合 C++20）
- 第三方依赖由 CPM 自动获取，无需预先安装
- 推荐生成器：Ninja（可选）

## 快速开始

1. 使用`script/init_project.py`初始化项目命名，原始命名为：项目名MyProject，命名空间myproject（脚本会重命名含占位符的目录和文件，并替换内容）：

```bash
python script/init_project.py
```

1. 在仓库根目录创建构建目录并生成构建系统：

```bash
mkdir build
cd build
cmake -S .. -B . -G "Ninja"
cmake --build .
```

1. 可执行文件位于构建输出的 `examples/`（示例）与 `tools/`（工具）目录下，例如：

```bash
# Linux / macOS
./build/examples/myproject_example --name World
./build/tools/myproject_wc README.md

# Windows (PowerShell)
.\build\examples\myproject_example.exe --name World
.\build\tools\myproject_wc.exe README.md
```

如果不使用 Ninja，可以用默认生成器：

```bash
cmake -S . -B build
cmake --build build --config Release
```

**运行测试**
在构建目录中运行：

```bash
ctest --output-on-failure
```

或者直接用 CMake 调用：

```bash
cmake --build . --target test
```

## 项目结构（概要）

- `CMakeLists.txt`：顶层 CMake 配置（选项、构建类型、库目标 `myproject` 与子目录）
- `cmake/myprojectOptions.cmake`：跨编译器与配置的编译/链接选项（只作用于本仓库自己的目标）
- `cmake/Dependencies.cmake`：先复用已安装依赖，再通过 CPM 回退，提供 `MYPROJECT_PRIVATE_LIBRARIES`
- `cmake/myprojectConfig.cmake.in`：安装后供 `find_package(myproject)` 使用的包配置模板
- `.clang-format` / `.gitattributes`：格式约定与行尾约定（索引一律 LF，`*.sh` 检出也是 LF）
- `include/myproject/`：公共头文件（随安装导出）
- `src/`：库目标的实现；`src/options.hpp` 是私有头文件，不随安装导出
- `tests/`、`examples/`、`tools/`：单元测试、示例、独立小工具（工具不使用第三方库）
- `ci/`：CI 用的检查脚本与两个消费方工程（`consumer/` 用 `find_package`、`superproject/` 用 `add_subdirectory`），不参与本库自身的构建
- `script/`：Python 脚本

## 依赖

依赖都在 `cmake/Dependencies.cmake` 里用 CPM 获取（含依赖自身的编译），，按实现依赖和测试依赖分为两类：

- **实现层依赖**：fmt 优先复用父项目提供的 target，再尝试系统 `find_package(fmt 12 CONFIG)`，最后通过 CPM 获取。它通过 `fmt::fmt` 链接到库。
- **测试依赖**：GoogleTest 只在测试启用时获取，不进入安装包的公开接口。

本库的 CMake package 使用 `find_dependency(fmt 12 CONFIG)`。如果 fmt 来自 CPM，它使用自身的安装规则安装其库、头文件及 CMake package；如果来自系统包，消费者也需要由自己的包管理器提供兼容的 fmt。不要直接修改或导出第三方 target。

使用 `-DBUILD_SHARED_LIBS=ON` 可构建动态库；导出宏 `MYPROJECT_API` 由本库按静态/共享自动切换，运行时 DLL 的部署见下一节。

## 编译选项

`cmake/myprojectOptions.cmake` 只放"编译本仓库自己的代码需要的"选项，并只通过 `myproject_options`（INTERFACE，PRIVATE 链接）作用于本库、测试、示例与工具，不进导出目标：

- **警告集**：GNU/Clang 前端 `-Wall -Wextra -Wpedantic`；MSVC 前端 `/W4 /permissive- /utf-8 /bigobj /Zc:__cplusplus` 以及 `/wd4251 /wd4275`（导出类内嵌标准库类型时，`/W4` + `/WX` 下必然报错的两条，gtest、spdlog、re2 同样关闭）。`MYPROJECT_WERROR`（默认等于是否顶层）控制 `-Werror` / `/WX`。
- **不设置 `-O` / `-DNDEBUG` / `-g`**：优化级别与调试信息由 `CMAKE_BUILD_TYPE` 决定（CMake 默认 Release 就是 `-O3 -DNDEBUG`），而构建类型属于构建的所有者。作为子项目时目录作用域的选项会追加在父项目 `CMAKE_CXX_FLAGS_<CONFIG>` 之后并覆盖它——本库若追加 `-O2`，只有本库自己的 TU 会忽略父项目的 `-O3`。fmt、spdlog、googletest、abseil、nlohmann/json 同样不设这些。
- **只在顶层保留的三项便利设置**：Debug 的 `-g3 -ggdb`（gdb 宏信息）、优化构建的 `-fno-omit-frame-pointer`（采样 profiler 能走栈）、Linux 上可执行目标的 `-rdynamic`（栈回溯带符号名）。`-rdynamic` 只对最终可执行目标有意义，因此只作用于本仓库自己的测试/示例/工具，父项目要用需在自己的可执行目标上加。
- `/utf-8` 是必需的：源码注释里有非 ASCII 字符，而 MSVC 默认按系统代码页解析源文件（公开头文件则强制纯 ASCII，见「版本与 ABI」）。
- 覆盖率：`-DMYPROJECT_ENABLE_COVERAGE=ON` 给 Debug 构建加 `--coverage`。

## 代码格式

- `.clang-format` 只列与 `BasedOnStyle` 不同的项，且键名以当前 clang-format 为准：被删除或改名的键（`SpacesInParentheses`、`BinPackArguments`、`Standard: Cpp11` 等）会被静默忽略，写了等于没写。
- 格式化工作树：`clang-format -i $(git ls-files '*.h' '*.hpp' '*.cpp' '*.cc' '*.c')`。
- 校验：`python ci/check_format.py`（`clang-format --dry-run -Werror`）。CI 的 format job 装的是 `pip install clang-format==23.1.1`（官方 LLVM 二进制，各 runner 版本一致）；本地版本不同可能得到不同结果。
- `.gitattributes` 固定索引里一律 LF，`*.sh` 检出也是 LF —— CRLF 的 shell 脚本会让 Linux/macOS 上的 CI 直接失败。

## 版本与 ABI

- 版本定义在顶层 `CMakeLists.txt` 的 `MYPROJECT_VERSION_{MAJOR,MINOR,PATCH}`，不用 `project(VERSION)`：后者会把 `CMAKE_PROJECT_VERSION*` 写进 cache，父项目若自己不声明版本，就会在自己的作用域里读到本库的版本。
- 安装包按 `0.x 阶段采用 `SameMinorVersion`，从 1.0 开始采用 `SameMajorVersion`；共享库的 SOVERSION 按相同 ABI 兼容边界改变（`write_basic_package_version_file` 的调用在顶层 `CMakeLists.txt`）。
- 共享库默认隐藏符号（目标属性 `CXX_VISIBILITY_PRESET hidden`）：公开头文件里新增的每个类型/函数都必须带 `MYPROJECT_API`，否则消费者链接时找不到它（异常类尤其要注意，隐藏后跨 DSO 按类型捕获会失效）。
- Debug 构建的库文件名带 `d` 后缀（`myprojectd.dll`、`libmyprojectd.so`），Debug 与 Release 因此可以装进同一个 prefix。
- 公开头文件必须保持纯 ASCII（注释写英文）：MSVC 默认按系统代码页解析源文件，而消费者不会继承本仓库的 `/utf-8`，头文件里出现非 ASCII 字节会让使用方的编译直接失败。

## 共享库的运行时部署

本库不替使用方决定二进制放在哪里，也不往父项目的目录里拷 DLL：共享构建时 `myproject` 的 DLL/so 只出现在它自己的构建目录，安装时进 `<prefix>/bin`。使用方需要自己让可执行文件找到它，两种做法：

- **构建树里**：本仓库对自己的测试与示例调用 `myproject_stage_runtime(<target>)`（顶层 `CMakeLists.txt` 中定义；`function()` 在整棵构建树里可见），它在链接后把 `$<TARGET_RUNTIME_DLLS:>` 拷到目标自己的目录。父项目可以对链接了本库的可执行文件调用同一个函数：

```cmake
add_subdirectory(third_party/modern-cpp-template)
add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE myproject::myproject)
myproject_stage_runtime(myapp) # 把 myproject 与依赖的 DLL 拷到 myapp 旁边
```

- **安装后**：`<prefix>/bin` 必须在运行时的库搜索路径上（Windows 的 `PATH`，Linux 的 rpath 或 `LD_LIBRARY_PATH`）。使用 vcpkg 这类工具链的父项目通常不需要额外操作。

缺失时表现为运行期失败（Windows 上退出码 127 / `0xc0000135`），而不是链接错误 —— 链接通过不等于能运行。只想在 ctest 里找到 DLL 的话，`set_tests_properties(<test> PROPERTIES ENVIRONMENT_MODIFICATION "PATH=path_list_prepend:$<TARGET_FILE_DIR:myproject>")` 也可以，但 `gtest_discover_tests` 的 `PRE_TEST` 发现阶段同样需要 DLL 可达。

## 作为子项目嵌入

- 在 `add_subdirectory` **之前** `enable_testing()`（或 `include(CTest)`），否则 `-DMYPROJECT_BUILD_TESTS=ON` 构建出的测试不会出现在父项目的 `ctest -N` 里。
- 父项目若需要 GTest，请提供 `GTest::gtest_main`（本库会复用）；本库自己拉取时固定 `BUILD_GMOCK OFF`。
- 父项目应先声明自己的依赖版本：CPM 在整棵构建树里是全局单例，同名依赖以第一次 `CPMAddPackage` 为准。
- `MYPROJECT_INSTALL` 顶层默认开启、嵌入时默认关闭，父项目**不需要**为此做任何事；但要清楚它的后果：父项目自己执行 `cmake --install` 时，会把本库的头文件、库文件与包文件（以及本库依赖的库文件）一并装进父项目的安装 prefix，`-DMYPROJECT_INSTALL=OFF` 可关掉。
- 共享构建时本库不部署 DLL，见上一节：父项目需要对链接了本库的可执行文件自行拷贝 `$<TARGET_RUNTIME_DLLS:>` 或把本库的构建目录加入运行时搜索路径。
- 本库会优先复用父项目提供的 fmt，必要时查找已安装的 fmt，最后通过 CPM 下载。

## 持续集成

`.github/workflows/ci.yml` 在推送 `main`、提交 PR 或手动触发时运行，分为格式检查、原生工具链检查和 MSYS2 工具链检查。原生侧覆盖 Ubuntu 24.04/GCC、macOS 15/AppleClang 与 Windows 2025 的 MSVC、clang-cl，MSYS2 侧覆盖 UCRT64/MINGW64 的 GCC 与 CLANG64 的 Clang；Debug/Release、静态/共享各跑一遍。全部使用 Ninja，并行度限制为 2 个进程；同一分支的新提交会取消尚未结束的旧检查。

本地复现只需要 Python ≥ 3.10、CMake ≥ 3.26 和对应编译器，不依赖 Bash：

```bash
python ci/check_build.py
python ci/check_build.py --config Debug --generator Ninja
python ci/check_build.py --linkage shared --scope library
python ci/check_build.py --toolset ClangCL  # Windows / Visual Studio LLVM
python ci/check_format.py                   # 另需 clang-format==23.1.1
```

编译器用标准的 `CC`、`CXX` 选择：Windows 下先进入 Visual Studio 开发者终端再选 `cl` 或 `clang-cl`，MSYS2 下在对应的 UCRT64/MINGW64/CLANG64 shell 中运行。`ci/check_build.py` 依次检查库构建与测试、安装、`find_package` 消费者和 `add_subdirectory` 父项目，所有程序都由 CTest 执行。每次运行在 `_ci/` 下建立独立的构建与安装目录（切换工具链或配置无需清缓存，成功失败都保留便于排查，可用 `--build-root`、`--jobs`、`--scope` 调整），只有依赖缓存 `.cache/cpm/` 在运行间共享；CI 失败时上传 CMake 与 CTest 日志。

## 贡献

- 欢迎通过 issue 或 PR 提交改进建议。建议在贡献前打开 issue 讨论大的设计变更。

## 许可证

- 本项目采取MIT证书，您有包括但不限于使用、复制、修改、合并、发布、分发、再许可和/或销售本软件副本的权利。

## 构建约定

C++20 通过目标级 `target_compile_features` 声明，不覆盖父项目的全局标准。公共头文件通过 `FILE_SET HEADERS` 管理和安装，新公共头需要添加到文件集中。构建并行度由构建工具或 `cmake --build --parallel` 决定。CI 在现有工具链之外增测 Linux Clang 和最新版 CMake 下的 ASan/UBSan。
