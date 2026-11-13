# Called after building an executable. An empty DLL list is valid for static
# builds and on non-Windows platforms.
if(MYPROJECT_RUNTIME_DLLS)
    file(COPY ${MYPROJECT_RUNTIME_DLLS} DESTINATION "${MYPROJECT_RUNTIME_DEST}")
endif()
