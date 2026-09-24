#!/usr/bin/env bash
#
# Checks used by CI, runnable by hand from any platform:
#
#   ci/run_checks.sh format        clang-format --dry-run -Werror over the tracked sources
#   ci/run_checks.sh library       build + ctest + install, then a find_package consumer
#   ci/run_checks.sh superproject  add_subdirectory embed, author warnings as errors
#   ci/run_checks.sh all           library + superproject (format is its own step)
#
# library and superproject run once per value of LINK_MODES, so a static and a
# shared build are both covered without extra CI jobs.
#
# Environment (all optional):
#   BUILD_TYPE         Release
#   LINK_MODES         "OFF ON" (BUILD_SHARED_LIBS values to check)
#   GENERATOR          unset = platform default (newest Visual Studio on Windows,
#                      Unix Makefiles elsewhere)
#   PREFIX             <repo>/_install/<mode>
#   BUILD_ROOT         <repo>/_ci
#   CPM_SOURCE_CACHE   <BUILD_ROOT>/cpm-cache
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${BUILD_ROOT:-$REPO_DIR/_ci}"
PREFIX="${PREFIX:-$REPO_DIR/_install}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
LINK_MODES="${LINK_MODES:-OFF ON}"
CPM_SOURCE_CACHE="${CPM_SOURCE_CACHE:-$BUILD_ROOT/cpm-cache}"

# Native tools (cmake, ctest, find) do not understand MSYS/Cygwin paths, so an
# MSYS-style absolute path in the environment is converted to a native one.
if command -v cygpath >/dev/null 2>&1; then
    for var in REPO_DIR BUILD_ROOT PREFIX CPM_SOURCE_CACHE; do
        case "${!var}" in /*) printf -v "$var" '%s' "$(cygpath -m "${!var}")" ;; esac
    done
fi

# No generator is pinned: naming "Visual Studio 17 2022" breaks on runner images
# that ship another version, and Ninja is not installed everywhere. Set
# GENERATOR=<name> to choose one explicitly.
# -DCMAKE_BUILD_TYPE is ignored by multi-config generators, and --config covers them.
configure() { # $1 = source dir, $2 = build dir, rest = extra cmake arguments
    local src="$1" build="$2"
    shift 2
    # No argument array here on purpose: macOS ships bash 3.2, where expanding an
    # empty array under `set -u` is an "unbound variable" error.
    if [ -n "${GENERATOR:-}" ]; then
        cmake -S "$src" -B "$build" -G "$GENERATOR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" "$@"
    else
        cmake -S "$src" -B "$build" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" "$@"
    fi
}

# CMake 4.4 renamed -Werror=dev to -Werror=author. Unknown categories are ignored
# before 4.4 and fatal from 4.4 on, so the wrong flag either loses the check or
# fails the configure.
case "$(cmake --version | sed -n '1s/.*version //p')" in
    1.* | 2.* | 3.* | 4.0.* | 4.1.* | 4.2.* | 4.3.*) WERROR_FLAG="-Werror=dev" ;;
    *) WERROR_FLAG="-Werror=author" ;;
esac

find_exe() { # $1 = directory, $2 = executable base name
    # -print -quit rather than piping into head: a SIGPIPE'd find fails the
    # pipeline under `set -o pipefail`.
    find "$1" -type f \( -name "$2" -o -name "$2.exe" \) -print -quit
}

# A consumer of the installed package finds the shared library through the prefix,
# not through the build tree's rpath. Missing it is a runtime failure (Windows:
# exit 127 / 0xc0000135), never a link error. The PATH entry must be in MSYS form
# or a native binary does not read it.
run_installed() { # $1 = executable, $2 = prefix
    local exe="$1" prefix="$2" bin="$2/bin"
    command -v cygpath >/dev/null 2>&1 && bin="$(cygpath -u "$bin")"
    PATH="$bin:$PATH" \
        LD_LIBRARY_PATH="$prefix/lib:${LD_LIBRARY_PATH:-}" \
        DYLD_LIBRARY_PATH="$prefix/lib:${DYLD_LIBRARY_PATH:-}" \
        "$exe"
}

step_format() {
    echo "== format: clang-format --dry-run -Werror =="
    if ! command -v clang-format >/dev/null 2>&1; then
        echo "clang-format not found on PATH (pip install clang-format==23.1.1)" >&2
        exit 1
    fi
    clang-format --version
    local rc=0 count=0
    while IFS= read -r file; do
        count=$((count + 1))
        clang-format --dry-run -Werror "$REPO_DIR/$file" || rc=1
    done < <(git -C "$REPO_DIR" ls-files '*.h' '*.hpp' '*.cpp' '*.cc' '*.c')
    [ "$count" -gt 0 ] || { echo "no source files to check" >&2; exit 1; }
    echo "checked $count files"
    return "$rc"
}

step_library() {
    for mode in $LINK_MODES; do
        local build="$BUILD_ROOT/library-$mode" prefix="$PREFIX/$mode"
        echo "== library: build_type=$BUILD_TYPE shared=$mode =="
        configure "$REPO_DIR" "$build" \
            -DBUILD_SHARED_LIBS="$mode" \
            -DCMAKE_INSTALL_PREFIX="$prefix" \
            -DCPM_SOURCE_CACHE="$CPM_SOURCE_CACHE"
        cmake --build "$build" --config "$BUILD_TYPE"
        ctest --test-dir "$build" -C "$BUILD_TYPE" --output-on-failure
        cmake --install "$build" --config "$BUILD_TYPE"

        # Out-of-tree consumer of the installed package; for the shared build it
        # also catches the library's exception type across the DSO boundary.
        configure "$REPO_DIR/ci/consumer" "$BUILD_ROOT/consumer-$mode" -DCMAKE_PREFIX_PATH="$prefix"
        cmake --build "$BUILD_ROOT/consumer-$mode" --config "$BUILD_TYPE"
        local exe
        exe="$(find_exe "$BUILD_ROOT/consumer-$mode" consumer)"
        [ -n "$exe" ] || { echo "consumer executable not found" >&2; exit 1; }
        run_installed "$exe" "$prefix"
    done
}

step_superproject() {
    for mode in $LINK_MODES; do
        local build="$BUILD_ROOT/superproject-$mode"
        echo "== superproject: add_subdirectory, $WERROR_FLAG, library tests on, shared=$mode =="
        # The parent enables testing before add_subdirectory (otherwise the
        # library's add_test calls are dropped) and configures with author warnings
        # as errors: this repository's own install rules and vendored modules must
        # not raise any.
        configure "$REPO_DIR/ci/superproject" "$build" \
            "$WERROR_FLAG" \
            -DBUILD_SHARED_LIBS="$mode" \
            -DMYPROJECT_BUILD_TESTS=ON \
            -DCPM_SOURCE_CACHE="$CPM_SOURCE_CACHE"
        cmake --build "$build" --config "$BUILD_TYPE"
        # The parent's own test plus the library's five must be registered here.
        ctest --test-dir "$build" -C "$BUILD_TYPE" --output-on-failure
        local exe
        exe="$(find_exe "$build" superapp)"
        [ -n "$exe" ] || { echo "superapp executable not found" >&2; exit 1; }
        # The library stages its runtime next to the executable, so no prefix is
        # needed here (see the README).
        "$exe"
    done
}

case "${1:-all}" in
    format) step_format ;;
    library) step_library ;;
    superproject) step_superproject ;;
    all)
        step_library
        step_superproject
        ;;
    *)
        echo "usage: $(basename "$0") [format|library|superproject|all]" >&2
        exit 2
        ;;
esac
