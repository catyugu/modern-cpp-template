#!/usr/bin/env bash
#
# Build checks used by CI, runnable by hand from any platform:
#
#   ci/run_checks.sh library       configure + build + ctest + install this repository
#   ci/run_checks.sh consumer      build + run ci/consumer against the installed package
#   ci/run_checks.sh superproject  configure (-Werror=dev) + build + ctest + run ci/superproject
#   ci/run_checks.sh all
#
# Environment (all optional):
#   GENERATOR          "Visual Studio 17 2022" on Windows, "Ninja" elsewhere
#   BUILD_TYPE         Release; used by single-config generators and by --config
#   BUILD_SHARED_LIBS  OFF
#   PREFIX             <repo>/_install
#   BUILD_ROOT         <repo>/_ci
#   CPM_SOURCE_CACHE   <BUILD_ROOT>/cpm-cache
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Native tools (cmake, ctest) do not understand MSYS/Cygwin paths
if command -v cygpath >/dev/null 2>&1; then
    REPO_DIR="$(cygpath -m "$REPO_DIR")"
fi
BUILD_ROOT="${BUILD_ROOT:-$REPO_DIR/_ci}"
PREFIX="${PREFIX:-$REPO_DIR/_install}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
BUILD_SHARED_LIBS="${BUILD_SHARED_LIBS:-OFF}"
CPM_SOURCE_CACHE="${CPM_SOURCE_CACHE:-$BUILD_ROOT/cpm-cache}"

if [ -z "${GENERATOR:-}" ]; then
    case "$(uname -s)" in
        MINGW* | MSYS* | CYGWIN*)
            # The platform default is the newest Visual Studio installed. Naming
            # a version explicitly breaks on runner images that ship another one.
            GENERATOR="$(cmake --help 2>/dev/null | awk '/^\*/ {sub(/^\* */, ""); sub(/ *=.*/, ""); print; exit}')"
            ;;
        *) GENERATOR="Ninja" ;;
    esac
fi

# Ninja is not installed everywhere; fall back to the platform's default.
if [ "$GENERATOR" = "Ninja" ] && ! command -v ninja >/dev/null 2>&1; then
    echo "ninja not found; falling back to Unix Makefiles" >&2
    GENERATOR="Unix Makefiles"
fi

generator_args=()
case "$GENERATOR" in
    "") : ;; # nothing resolved: let CMake pick
    "Visual Studio"*) generator_args=(-G "$GENERATOR" -A x64) ;;
    *) generator_args=(-G "$GENERATOR") ;;
esac

# Multi-config generators select the configuration at build time and reject
# CMAKE_BUILD_TYPE; single-config ones need it at configure time.
multi_config=0
case "$GENERATOR" in
    "" | "Visual Studio"* | Xcode | "Ninja Multi-Config") multi_config=1 ;;
esac
config_args=()
if [ "$multi_config" = 0 ]; then
    config_args+=("-DCMAKE_BUILD_TYPE=$BUILD_TYPE")
fi

# The build tree finds the library through the rpath/staging this repository sets
# up; a consumer of the installed package needs <prefix>/bin and <prefix>/lib on
# the runtime search path instead. On Windows the PATH entry must be in MSYS form
# for a native executable to find the DLL.
run_with_runtime() { # $1 = executable
    local exe="$1" runtime_dir="$PREFIX/bin"
    if command -v cygpath >/dev/null 2>&1; then
        runtime_dir="$(cygpath -u "$runtime_dir")"
    fi
    PATH="$runtime_dir:$PATH" \
        LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH:-}" \
        DYLD_LIBRARY_PATH="$PREFIX/lib:${DYLD_LIBRARY_PATH:-}" \
        "$exe"
}

find_exe() { # $1 = directory, $2 = executable base name
    find "$1" -type f \( -name "$2" -o -name "$2.exe" \) | head -n 1
}

step_library() {
    echo "== library: generator=$GENERATOR build_type=$BUILD_TYPE shared=$BUILD_SHARED_LIBS =="
    cmake -S "$REPO_DIR" -B "$BUILD_ROOT/library" "${generator_args[@]}" \
        -DBUILD_SHARED_LIBS="$BUILD_SHARED_LIBS" \
        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
        -DCPM_SOURCE_CACHE="$CPM_SOURCE_CACHE" \
        "${config_args[@]}"
    cmake --build "$BUILD_ROOT/library" --config "$BUILD_TYPE"
    ctest --test-dir "$BUILD_ROOT/library" -C "$BUILD_TYPE" --output-on-failure
    cmake --install "$BUILD_ROOT/library" --config "$BUILD_TYPE"
}

step_consumer() {
    echo "== consumer: find_package(myproject) against $PREFIX =="
    cmake -S "$REPO_DIR/ci/consumer" -B "$BUILD_ROOT/consumer" "${generator_args[@]}" \
        -DCMAKE_PREFIX_PATH="$PREFIX" \
        "${config_args[@]}"
    cmake --build "$BUILD_ROOT/consumer" --config "$BUILD_TYPE"
    local exe
    exe="$(find_exe "$BUILD_ROOT/consumer" consumer)"
    [ -n "$exe" ] || { echo "consumer executable not found under $BUILD_ROOT/consumer"; exit 1; }
    run_with_runtime "$exe"
}

step_superproject() {
    echo "== superproject: add_subdirectory, -Werror=dev, library tests enabled =="
    # -Werror=dev: a parent that configures with it must not be broken by this
    # repository's own author warnings.
    cmake -Werror=dev -S "$REPO_DIR/ci/superproject" -B "$BUILD_ROOT/superproject" "${generator_args[@]}" \
        -DMYPROJECT_BUILD_TESTS=ON \
        -DCPM_SOURCE_CACHE="$CPM_SOURCE_CACHE" \
        "${config_args[@]}"
    cmake --build "$BUILD_ROOT/superproject" --config "$BUILD_TYPE"
    # Both the parent's own test and the library's five tests must be registered here.
    ctest --test-dir "$BUILD_ROOT/superproject" -C "$BUILD_TYPE" --output-on-failure
    local exe
    exe="$(find_exe "$BUILD_ROOT/superproject" superapp)"
    [ -n "$exe" ] || { echo "superapp executable not found under $BUILD_ROOT/superproject"; exit 1; }
    run_with_runtime "$exe"
}

case "${1:-all}" in
    library) step_library ;;
    consumer) step_consumer ;;
    superproject) step_superproject ;;
    all)
        step_library
        step_consumer
        step_superproject
        ;;
    *)
        echo "usage: $(basename "$0") [library|consumer|superproject|all]" >&2
        exit 2
        ;;
esac
