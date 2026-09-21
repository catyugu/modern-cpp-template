add_executable(myproject_test test_core.cpp)

# 链接内部库、gtest (gtest_main 包含了自带的 main 函数) 与本仓库的编译选项
target_link_libraries(myproject_test
    PRIVATE
        myproject::myproject
        myproject_options
        GTest::gtest_main
)

# 注册测试以便被 CTest 发现和运行；DISCOVERY_MODE PRE_TEST 避免在构建期执行测试二进制
include(GoogleTest)
gtest_discover_tests(myproject_test
    TEST_PREFIX "myproject."
    DISCOVERY_MODE PRE_TEST
)
