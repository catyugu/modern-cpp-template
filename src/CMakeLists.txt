# 声明库目标
add_library(myproject_lib core.cpp)

# 创建别名，方便被其他模块或其他项目作为依赖引入时保持命名一致性
add_library(MyProject::myproject_lib ALIAS myproject_lib)

# 声明库的包含目录（Public意味着链接它的目标也会继承该路径）
target_include_directories(myproject_lib 
    PUBLIC 
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)
