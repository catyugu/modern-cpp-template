# MyProject

一个基于 CMake 的跨平台 C++20 库项目起点。包含单元测试、示例、命令行工具和 CI，既能独立构建，也能通过 `add_subdirectory()` 或 `find_package()` 被其他项目使用。

## 快速开始

需要 **CMake 3.26+**、支持 C++20 的编译器（GCC、Clang 或 MSVC）及 Python 3。Ninja 可选，不要求预装第三方 C++ 依赖。

从本模板创建新仓库后，在项目根目录执行：

```sh
python script/init_project.py
```

按提示输入项目名（如 `AwesomeApp`）和命名空间/短前缀（如 `awesome`）。脚本会同步更新目标、头文件路径和 CMake 包名。**建议在开始编写自己的代码前运行一次。**

```sh
cmake -S . -B build
cmake --build build --config Debug
ctest --test-dir build -C Debug --output-on-failure
```

独立构建在单配置生成器下默认使用 Debug。首次配置时，如未找到已安装的依赖，CPM 会自动下载所需源码。

## 项目结构

```text
include/myproject/   公共头文件
src/                 库实现与私有头文件
tests/               GoogleTest 单元测试
examples/            示例程序
tools/               独立命令行工具
cmake/               构建选项、依赖与安装包配置
ci/                  构建及消费方验证
script/              项目初始化脚本
```

在 `include/` 和 `src/` 下新增常见的 C/C++ 头文件或源码时，CMake 会自动发现它们。

## 构建选项

常用开关可在配置时通过 `-D...` 指定：

| 选项 | 作用 |
| --- | --- |
| `BUILD_SHARED_LIBS=ON` | 构建共享库；默认构建静态库 |
| `MYPROJECT_BUILD_TESTS=OFF` | 关闭测试 |
| `MYPROJECT_BUILD_EXAMPLES=OFF` | 关闭示例 |
| `MYPROJECT_BUILD_TOOLS=OFF` | 关闭工具 |
| `MYPROJECT_INSTALL=OFF` | 关闭安装及 CMake 包导出 |
| `MYPROJECT_WERROR=OFF` | 不将本项目的编译警告视为错误 |

独立构建默认开启测试、示例、工具和安装；作为子项目时这些功能默认关闭。初始化后，选项中的 `MYPROJECT` 会替换为新项目名的大写形式。

第三方依赖统一在 [`cmake/Dependencies.cmake`](cmake/Dependencies.cmake) 中维护。模板使用 `fmt`，测试使用 GoogleTest；优先复用现有 target 或已安装包，不存在时由 CPM 获取固定版本。

## 供其他项目使用

**直接嵌入：**

```cmake
add_subdirectory(third_party/myproject)
target_link_libraries(your_app PRIVATE myproject::myproject)
```

**安装后使用：**

```sh
cmake --install build --config Debug --prefix /path/to/prefix
```

消费方在配置时将该安装目录加入 `CMAKE_PREFIX_PATH`，然后：

```cmake
find_package(myproject CONFIG REQUIRED)
target_link_libraries(your_app PRIVATE myproject::myproject)
```

安装包会复用已有的 `fmt::fmt`，否则查找兼容的 fmt 12 包；静态链接时也会保留必要的链接依赖。若构建共享库，使用方仍需自行安排运行时动态库的位置；构建树中的可执行程序可使用 `myproject_stage_runtime(your_app)` 辅助部署 DLL。

## 检查与贡献

```sh
python ci/check_build.py    # 构建、测试、安装及消费方验证
python ci/check_format.py   # 需要 clang-format 23.1.1
```

GitHub Actions 覆盖 Linux、macOS 和 Windows 上的代表性编译器与生成器，并验证模板初始化、静态/动态链接和 Sanitizer。欢迎通过 Issue 或 Pull Request 提出改进。

## 许可证

[MIT](LICENSE)
