# @@PROJECT_NAME@@

`@@PROJECT_NAME@@` 是一个基于 CMake 的跨平台 C++20 库。仓库自带一套可运行的示例实现（Eigen 做直线最小二乘拟合、fmt 格式化结果），开始写自己的代码时把它替换掉即可。

## 构建与测试

需要 **CMake 3.26+**、支持 C++20 的编译器（GCC、Clang 或 MSVC）及 Python 3。Ninja 可选，不要求预装第三方 C++ 依赖。

```sh
cmake -S . -B build
cmake --build build --config Debug
ctest --test-dir build -C Debug --output-on-failure
```

单配置生成器下默认使用 Debug；首次配置时如未找到已安装的依赖，CPM 会自动下载所需源码。`@@PROJECT_NAME@@_example` 展示库调用，`@@PROJECT_NAME@@_fit examples/samples.txt` 从两列文本数据中拟合直线。

GitHub Actions 在 Linux、macOS 和 Windows 上验证构建、单元测试、静态/动态安装包与消费方、`add_subdirectory` 嵌入使用和 Sanitizer。

## 项目结构

```text
include/@@NAMESPACE@@/   公共头文件
src/                     库实现与私有头文件
tests/                   GoogleTest 单元测试
examples/                示例程序
tools/                   独立命令行工具
cmake/                   构建选项、依赖与安装包配置
.github/                 CI 脚本、工作流与复合 Action
```

在 `src/` 下新增 `.c`、`.cc`、`.cpp`、`.cxx` 源码，或在 `include/` 下新增头文件时，CMake 会自动发现。`include/` 只放公开文件：安装时整个目录都会复制，所以 `.inl`、`.ipp`、`.tpp` 这类实现文件不需要单独登记。

## 构建选项

| 选项 | 作用 |
| --- | --- |
| `BUILD_SHARED_LIBS=ON` | 构建共享库；默认构建静态库 |
| `@@UPPER@@_BUILD_TESTS=OFF` | 关闭测试 |
| `@@UPPER@@_BUILD_EXAMPLES=OFF` | 关闭示例 |
| `@@UPPER@@_BUILD_TOOLS=OFF` | 关闭工具 |
| `@@UPPER@@_INSTALL=OFF` | 关闭安装及 CMake 包导出 |
| `@@UPPER@@_WERROR=OFF` | 不将本项目的编译警告视为错误 |

独立构建默认开启测试、示例、工具和安装；作为子项目时这些功能默认关闭。

## 第三方依赖

依赖统一在 [`cmake/Dependencies.cmake`](cmake/Dependencies.cmake) 中获取、链接并声明安装包要求；添加或修改库依赖只需编辑这个文件。Eigen 只在构建本库时需要：它是头文件依赖，没有出现在公开头文件中，因此安装后的静态包不要求消费方提供 Eigen。fmt 是真实的静态链接依赖，静态安装包会为消费方保留这条链接要求。

源码默认缓存到 `.cache/cpm`，可用 `CPM_SOURCE_CACHE` 环境变量或 `-DCPM_SOURCE_CACHE=/path/to/cache` 覆盖。

## 供其他项目使用

**直接嵌入：**

```cmake
add_subdirectory(third_party/@@NAMESPACE@@)
target_link_libraries(your_app PRIVATE @@NAMESPACE@@::@@NAMESPACE@@)
```

**安装后使用：**

```sh
cmake --install build --config Debug --prefix /path/to/prefix
```

把该安装目录加入 `CMAKE_PREFIX_PATH`，然后：

```cmake
find_package(@@NAMESPACE@@ CONFIG REQUIRED)
target_link_libraries(your_app PRIVATE @@NAMESPACE@@::@@NAMESPACE@@)
```

共享库使用方需安排运行时库的位置；构建树中的程序可用 `@@NAMESPACE@@_stage_runtime(your_app)` 部署 DLL。

## 版本与发布

库版本由 `CMakeLists.txt` 中的 `@@UPPER@@_VERSION_MAJOR`、`@@UPPER@@_VERSION_MINOR`、`@@UPPER@@_VERSION_PATCH` 给出，安装包的 `find_package` 版本判断和共享库 SONAME 都基于它。打 Tag 发布时，请让 Git Tag（如 `v1.2.3`）与这三个数字保持一致。

`.github/workflows/release.yml` 由 `vX.Y.Z` Tag 触发：先确认 Tag 的提交已经在 `main` 历史中，再等待该提交的完整 CI 通过，最后才创建 GitHub Release。Release 资产是源码归档，不是二进制安装包。

要发布二进制，可以在 `CMakeLists.txt` 中启用 CPack 并在 `release.yml` 中加一个打包 Job，顺序是：构建 → CTest → `cmake --install` 到暂存目录 → 用暂存目录做一次消费方验证 → 打包 → 作为 Release 资产上传。版本号仍以 Tag 为准。

本仓库的仓库设置不在代码里，建议在 Settings → Rules 中为 `main` 启用分支规则（要求 Pull Request 且 CI 检查必须通过），并为 `v*` Tag 启用标签规则（只允许管理员创建），避免直接推送绕过验证。

## 许可证

`LICENSE` 保留自模板的 MIT 声明。分发本项目的代码前，请在同一文件中补上你自己的版权行（例如 `Copyright (c) 2026 Your Name`），而不是删除原始声明：MIT 要求保留原始版权与许可声明。
