# Modern C++ Template (MyProject)

一个基于 CMake 的现代 C++ 项目模板，使用 C++20 和 FetchContent 管理第三方依赖（示例包含 `cxxopts` 与 `googletest`）。该模板适合作为小型应用或库的起点，包含示例 `src/`、头文件 `include/`、可执行 `bin/` 与单元测试 `test/`。

**特性**
- **C++20**：项目启用 C++20 标准。
- **中央化依赖**：通过 `cmake/Dependencies.cmake` 使用 `FetchContent` 管理 `cxxopts` 与 `googletest`。
- **可测性**：内置 GoogleTest 示例与 `CTest` 集成。

**要求**
- CMake >= 3.24
- 支持的编译器：GCC / Clang / MSVC（符合 C++20）
- 推荐生成器：Ninja（可选）

**快速开始**

1. 使用`script/init_project.py`初始化项目命名，原始命名为：项目名MyProject，命名空间myproject：
   
```bash
python script/init_project.py
```

2. 在仓库根目录创建构建目录并生成构建系统：

```bash
mkdir build
cd build
cmake -S .. -B . -G "Ninja"
cmake --build .
```

3. 可执行文件位于构建输出的 `bin/` 目录下，例如：

```bash
# Linux / macOS
./bin/myproject_bin

# Windows (PowerShell)
.\bin\myproject_bin.exe
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

**依赖**
- 依赖与版本管理见 `cmake/Dependencies.cmake`：当前通过 `FetchContent` 下载 `cxxopts`（命令行解析）与 `googletest`（单元测试）。

**项目结构（概要）**
- `CMakeLists.txt`：顶层 CMake 配置
- `cmake/Dependencies.cmake`：集中依赖声明
- `include/`：公共头文件（`myproject/`）
- `src/`：源代码实现
- `bin/`：示例可执行相关代码
- `test/`：单元测试
- `build/`：构建产物（忽略在 VCS）
- `script/`: Python脚本

**贡献**
- 欢迎通过 issue 或 PR 提交改进建议。建议在贡献前打开 issue 讨论大的设计变更。