add_executable(myproject_test test_core.cpp)

# 链接内部库和 gtest (gtest_main 包含了自带的 main 函数)
target_link_libraries(myproject_test 
    PRIVATE 
        MyProject::myproject_lib
        GTest::gtest_main
)

# 注册测试以便被 CTest 发现和运行
include(GoogleTest)
gtest_discover_tests(myproject_test)
