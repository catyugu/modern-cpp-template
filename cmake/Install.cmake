include(CMakePackageConfigHelpers)

set(package_dir "${CMAKE_INSTALL_LIBDIR}/cmake/myproject")

install(TARGETS myproject EXPORT myprojectTargets)
install(DIRECTORY "${PROJECT_SOURCE_DIR}/include/"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
install(FILES "${PROJECT_SOURCE_DIR}/LICENSE"
    DESTINATION "${CMAKE_INSTALL_DOCDIR}")
install(EXPORT myprojectTargets
    NAMESPACE myproject::
    DESTINATION "${package_dir}")

get_target_property(MYPROJECT_LIBRARY_TYPE myproject TYPE)
configure_package_config_file(
    "${PROJECT_SOURCE_DIR}/cmake/myprojectConfig.cmake.in"
    "${PROJECT_BINARY_DIR}/myprojectConfig.cmake"
    INSTALL_DESTINATION "${package_dir}")
write_basic_package_version_file(
    "${PROJECT_BINARY_DIR}/myprojectConfigVersion.cmake"
    VERSION "${MYPROJECT_VERSION}"
    COMPATIBILITY "${MYPROJECT_VERSION_COMPATIBILITY}")
install(FILES
    "${PROJECT_BINARY_DIR}/myprojectConfig.cmake"
    "${PROJECT_BINARY_DIR}/myprojectConfigVersion.cmake"
    DESTINATION "${package_dir}")
