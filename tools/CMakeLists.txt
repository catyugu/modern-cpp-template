add_executable(myproject_fit main.cpp)
target_link_libraries(myproject_fit PRIVATE myproject::myproject myproject_options)
myproject_stage_runtime(myproject_fit)

if(MYPROJECT_BUILD_TESTS)
    add_test(NAME tool.fit_cli
        COMMAND myproject_fit "${PROJECT_SOURCE_DIR}/examples/samples.txt")
    set_tests_properties(tool.fit_cli PROPERTIES
        PASS_REGULAR_EXPRESSION "RMSE = 0[.]41833")
endif()
