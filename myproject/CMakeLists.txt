file(GLOB_RECURSE MYPROJECT_SOURCES CONFIGURE_DEPENDS src/*.cpp src/*.cc src/*.c)
file(GLOB_RECURSE MYPROJECT_HEADERS CONFIGURE_DEPENDS include/*.h include/*.hpp)

add_library(myproject STATIC ${MYPROJECT_SOURCES} ${MYPROJECT_HEADERS})

target_include_directories(myproject PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(myproject PUBLIC myproject_options)

target_compile_options(myproject PRIVATE
    $<$<OR:$<CXX_COMPILER_ID:GNU>,$<CXX_COMPILER_ID:Clang>>:
    -Werror
    >
)

install(TARGETS myproject EXPORT myprojectTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# public header files
install(FILES ${MYPROJECT_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/myproject
)
