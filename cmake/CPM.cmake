# CPM.cmake - CMake Package Manager
# https://github.com/cpm-cmake/CPM.cmake
# Version 0.40.2
#
# This is a minimal version of CPM.cmake for downloading dependencies

set(CPM_DOWNLOAD_VERSION 0.40.2)

if(CPM_SOURCE_CACHE)
    set(CPM_DOWNLOAD_LOCATION "${CPM_SOURCE_CACHE}/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
elseif(DEFINED ENV{CPM_SOURCE_CACHE})
    set(CPM_DOWNLOAD_LOCATION "$ENV{CPM_SOURCE_CACHE}/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
else()
    set(CPM_DOWNLOAD_LOCATION "${CMAKE_BINARY_DIR}/cmake/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
endif()

# Expand relative path. This is important if the provided path contains a tilde (~)
get_filename_component(CPM_DOWNLOAD_LOCATION ${CPM_DOWNLOAD_LOCATION} ABSOLUTE)

function(download_cpm)
    message(STATUS "Downloading CPM.cmake v${CPM_DOWNLOAD_VERSION}")
    file(DOWNLOAD
        https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_DOWNLOAD_VERSION}/CPM.cmake
        ${CPM_DOWNLOAD_LOCATION}
    )
endfunction()

if(NOT(EXISTS ${CPM_DOWNLOAD_LOCATION}))
    download_cpm()
else()
    # resume download if it previously failed
    file(READ ${CPM_DOWNLOAD_LOCATION} check_content BEGINNING 1 END 50)

    if(NOT check_content MATCHES "CPM.cmake")
        download_cpm()
    endif()

    unset(check_content)
endif()

include(${CPM_DOWNLOAD_LOCATION})
