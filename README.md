# MyProject

一个基于 CMake 的跨平台 C++20 库模板。以直线最小二乘拟合为例：Eigen 负责计算，fmt 负责结果输出；包含单元测试、示例、命令行工具和 CI，支持独立构建、源码嵌入和安装后使用。

## 快速开始

需要 **CMake 3.26+**、支持 C++20 的编译器（GCC、Clang 或 MSVC）及 Python 3。Ninja 可选，不要求预装第三方 C++ 依赖。

从本模板创建新仓库后，在项目根目录执行：

```sh
python script/init_project.py
```

按提示输入项目名（如 `AwesomeApp`）和命名空间/短前缀（如 `awesome`），也可以用 `--project-name AwesomeApp --namespace awesome` 一次给全。脚本会修改目标名、头文件路径和 CMake 包名，把 `README.md` 重写成面向新项目的说明，并删除只属于模板的文件（初始化脚本、模板测试和模板 workflow）。**建议在开始编写自己的代码前运行一次**；项目名和命名空间必须是合法标识符（字母开头，只用字母、数字和下划线，命名空间限小写），不合法时脚本在改动任何文件之前退出。

```sh
cmake -S . -B build
cmake --build build --config Debug
ctest --test-dir build -C Debug --output-on-failure
```

独立构建在单配置生成器下默认使用 Debug。首次配置时，如未找到已安装的依赖，CPM 会自动下载所需源码。`myproject_example` 展示库调用，`myproject_fit examples/samples.txt` 从两列文本数据中拟合直线。

## 项目结构

```text
include/myproject/   公共头文件
src/                 库实现与私有头文件
tests/               GoogleTest 单元测试
examples/            示例程序
tools/               独立命令行工具
cmake/               构建选项、依赖与安装包配置
.github/             CI 脚本（scripts/）、工作流（workflows/）与复合 Action（actions/）
script/              项目初始化脚本（仅模板仓库）
```

在 `src/` 下新增 `.c`、`.cc`、`.cpp`、`.cxx` 源码，或在 `include/`、`src/` 下新增 `.h`、`.hpp`、`.hxx` 头文件时，CMake 会自动发现。`include/` 约定只放公开文件，安装时整个目录都会复制，因此 `.inl`、`.ipp`、`.tpp` 这类实现文件不需要单独登记。

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

## 第三方依赖

依赖统一在 [`cmake/Dependencies.cmake`](cmake/Dependencies.cmake) 中获取、链接并声明安装包要求；添加或修改库依赖只需编辑这个文件。优先复用父项目 target 或兼容的安装包，否则由 CPM 下载固定版本。父项目提供的 target 由父项目保证兼容性。

Eigen 只在本库内部使用，且不出现在公开头文件中，因此用 `$<BUILD_LOCAL_INTERFACE:...>` 保持为构建期依赖：安装后的静态包不要求消费方提供 Eigen。fmt 是真实的静态链接依赖，静态安装包会为消费方保留这条链接要求。共享库两种都不要求。

源码默认缓存到 `.cache/cpm`，可用 `CPM_SOURCE_CACHE` 环境变量或 `-DCPM_SOURCE_CACHE=/path/to/cache` 覆盖。其他选项见 [CPM 文档](https://github.com/cpm-cmake/CPM.cmake#options)。

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

安装包保留必要的链接依赖，不会下载源码。CPM 获取的 fmt 会随本库安装，外部依赖由提供方负责交付。共享库使用方需安排运行时库的位置；构建树中的程序可使用 `myproject_stage_runtime(your_app)` 部署 DLL。

## 发布

本仓库是模板而不是已经定型的库，因此 CD 只发布模板自身：

```sh
git switch main
git pull --ff-only
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin vX.Y.Z
```

推送 Tag 后，`.github/workflows/release.yml` 先确认标签形如 `vX.Y.Z` 且对应提交在 `main` 历史中，再等待**该提交的完整 CI**（`ci.yml` 的全部 Job 和 `template.yml` 的模板验证）通过，然后才创建 GitHub Release；CI 未通过或超时都会终止发布。Release Notes 自动生成，源码归档由 GitHub 提供。

模板的 Tag 版本与初始化后项目的 `MYPROJECT_VERSION` 相互独立，不需要同步；实际项目应让 CMake 版本与 Git Tag 保持一致。需要分发二进制的下游项目应自行启用 CPack，并按“构建 → CTest → install/stage → 安装包消费验证 → 打包 → 发布资产”的顺序发布。

`main` 分支和版本 Tag 由仓库 Ruleset 保护：合并到 `main` 必须走 Pull Request 且 8 个 CI 检查全部通过，禁止强推和删除分支；`v*` Tag 只有仓库管理员能创建、移动和删除。

## 本地验证

提交前在本地跑与改动相关的最小范围。每个脚本只验证一件事：

```sh
python .github/scripts/check_build.py --scope build --linkage static     # configure / build / CTest
python .github/scripts/check_build.py --scope package --linkage shared   # install / find_package / consumer
python .github/scripts/check_build.py --scope embedded --linkage static  # add_subdirectory
python .github/scripts/test_template.py                                  # 把模板初始化成 AwesomeApp 并跑它的检查
python .github/scripts/check_format.py                                   # 需要 clang-format 23.1.1
python .github/scripts/wait_for_ci.py --self-test                        # 发布门禁的判定逻辑
```

`--linkage` 取 `static` 或 `shared`，`--scope all` 一次跑完 build/package/embedded。每次运行的构建目录在 `_ci/` 下按范围隔离，依赖源码缓存在 `.cache/cpm`。

CI 复用同一套脚本，共 8 个 Job：`ci.yml` 的 7 个覆盖 Linux、macOS、Windows 的构建、安装包消费、嵌入使用和 Sanitizer；`template.yml` 的 1 个做模板初始化验证。本地不必复现整张矩阵，平台相关的部分交给 CI。

## 贡献

- 有问题或想法先开 Issue，说明场景和期望行为。
- 改动走 Pull Request：从 `main` 切分支、提交、推送到该分支，然后开 PR。`main` 受规则保护，直接推送会被拒绝，PR 需要 8 个 CI 检查全部通过才能合并。
- PR 描述里写清改动动机和验证方式：哪些范围在本地跑过（见上一节），哪些依赖 CI 覆盖。
- 发布由维护者在合并后的 `main` 上打 `vX.Y.Z` Tag；Release 工作流确认该提交的完整 CI 通过后才创建 Release，普通贡献者不需要打 Tag。

欢迎通过 Issue 或 Pull Request 提出改进！

## 许可证

[MIT](LICENSE)。初始化生成的项目会保留这份版权声明；分发自己的代码时请在同一文件中补上自己的版权行。
