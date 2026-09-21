# Modern C++ Template (MyProject)

一个基于 CMake 的现代 C++ 项目模板，使用 C++20 和 CPM/FetchContent 管理第三方依赖（示例包含 `cxxopts` 与 `googletest`）。该模板适合作为小型应用或库的起点，库目标的源码位于顶层 `src/`、公共头位于 `include/myproject/`，并配有单元测试 `tests/`、示例 `examples/` 与独立工具 `tools/`。

## 特性

- **C++20**：项目启用 C++20 标准。
- **现代 CMake**：顶层 `CMakeLists.txt`（含库目标定义）+ `cmake/myprojectOptions.cmake`（跨编译器/配置的编译选项 INTERFACE 目标）+ `include/` 与 `src/`。
- **中央化依赖**：通过 `cmake/Dependencies.cmake` 使用 CPM 管理 `cxxopts` 与 `googletest`。
- **可测性**：内置 GoogleTest 示例与 `CTest` 集成。
- **可配置构建项**：`MYPROJECT_BUILD_EXAMPLES` / `MYPROJECT_BUILD_TESTS` / `MYPROJECT_BUILD_TOOLS` 分别开关示例、测试与工具，`MYPROJECT_INSTALL` 开关安装规则；作为子项目嵌入时它们默认关闭，只构建库目标 `myproject`（别名 `myproject::myproject`）。

## 要求

- CMake >= 3.24
- 支持的编译器：GCC / Clang / MSVC（符合 C++20）
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

- `CMakeLists.txt`：顶层 CMake 配置（选项、BUILD_TYPE、CPU 并行度、依赖、库目标 `myproject` 与子目录）
- `cmake/myprojectOptions.cmake`：跨编译器（GNU/MSVC 前端）与配置（Debug/Release/RelWithDebInfo）的编译/链接选项
- `cmake/Dependencies.cmake`：集中依赖声明（CPM）
- `cmake/myprojectConfig.cmake.in`：安装后供 `find_package(myproject)` 使用的包配置模板
- `include/myproject/`：公共头文件（随安装导出），例如 `#include "myproject/core.hpp"`、`#include "myproject/cli.hpp"`
- `src/`：库目标的实现（`core.cpp`、`cli.cpp`）
- `src/*.hpp`：库的私有头文件（如 `options.hpp`），不随安装导出，第三方类型（如 cxxopts）只出现在这里
- `tests/`：单元测试
- `examples/`：示例可执行（只用公开接口：库 + 生成的 config.h）
- `tools/`：独立小工具（`myproject_wc`，统计文件行数/单词数/字节数）
- `build/`：构建产物（忽略在 VCS）
- `script/`: Python脚本

## 依赖

- 依赖与版本管理见 `cmake/Dependencies.cmake`：通过 CPM 下载 `cxxopts`（由库的实现层 `src/cli.cpp` 使用，属于实现细节）与 `googletest`（仅测试）。
- 使用 `-DBUILD_SHARED_LIBS=ON` 可构建动态库；导出宏 `MYPROJECT_API` 与共享库的运行时部署由 CMake 自动处理。

## 贡献

- 欢迎通过 issue 或 PR 提交改进建议。建议在贡献前打开 issue 讨论大的设计变更。

## 许可证

- 本项目采取MIT证书，您有包括但不限于使用、复制、修改、合并、发布、分发、再许可和/或销售本软件副本的权利。
