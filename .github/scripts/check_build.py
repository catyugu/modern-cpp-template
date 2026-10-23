"""Verify one toolchain with a build, package or embedded scope."""

import argparse
import json
import os
import re
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent  # .github/scripts/
REPO = SCRIPTS.parents[1]


def run(*command, capture=False):
    args = [str(arg) for arg in command]
    print(f"+ {shlex.join(args)}", flush=True)
    return subprocess.run(
        args,
        cwd=REPO,
        check=True,
        text=True,
        encoding="utf-8",
        stdout=subprocess.PIPE if capture else None,
    ).stdout


def configure(args, source, build, *options):
    command = ["cmake", "-S", source, "-B", build]
    if args.generator:
        command += ["-G", args.generator]
    run(*command, f"-DCMAKE_BUILD_TYPE={args.config}", *args.cmake_flag, *options)


def build(args, directory):
    run(
        "cmake",
        "--build",
        directory,
        "--config",
        args.config,
        "--parallel",
        args.jobs,
    )


def cpm_cache():
    return os.environ.get("CPM_SOURCE_CACHE") or REPO / ".cache" / "cpm"


def test(directory, config, *, required=()):
    command = ("ctest", "--test-dir", directory, "-C", config)
    listing = json.loads(run(*command, "--show-only=json-v1", capture=True))
    names = {entry["name"] for entry in listing["tests"]}
    missing = set(required) - names
    if missing:
        raise RuntimeError(f"Tests not registered in {directory}: {sorted(missing)}")
    run(*command, "--output-on-failure", "--no-tests=error", "--timeout", "60")
    return names


def library_test_names(names, directory):
    tests = {name for name in names if name.startswith("myproject.")}
    if not tests:
        raise RuntimeError(f"Library tests not registered in {directory}")
    return tests


def build_library(args, root):
    directory = root / "library"
    configure(
        args,
        REPO,
        directory,
        f"-DBUILD_SHARED_LIBS={'ON' if args.linkage == 'shared' else 'OFF'}",
        f"-DCPM_SOURCE_CACHE={cpm_cache()}",
        f"-DCMAKE_INSTALL_PREFIX={root / 'install'}",
        "-DMYPROJECT_BUILD_TESTS=ON",
        "-DMYPROJECT_WERROR=ON",
    )
    build(args, directory)
    names = test(directory, args.config)
    return directory, library_test_names(names, directory)


def check_package(args, root, library):
    prefix = root / "install"
    run("cmake", "--install", library, "--config", args.config)

    # include/ is installed wholesale (GNUInstallDirs' default INCLUDE dir is
    # "include" on every platform), so every public file must arrive: a whitelist
    # that misses .inl/.ipp/.tpp breaks downstream builds.
    installed_headers = prefix / "include"
    source_headers = {
        path.relative_to(REPO / "include")
        for path in (REPO / "include").rglob("*")
        if path.is_file()
    }
    shipped_headers = {
        path.relative_to(installed_headers)
        for path in installed_headers.rglob("*")
        if path.is_file()
    }
    missing = sorted(str(path) for path in source_headers - shipped_headers)
    if missing:
        raise RuntimeError(f"Public headers not installed: {missing}")

    # Consume only this run's install; never search a stale prefix or source tree.
    consumer = root / "consumer"
    options = [f"-DCMAKE_PREFIX_PATH={prefix}"]
    # Eigen is an implementation detail of this library: neither linkage may
    # require the consumer to provide it.
    options += ["-DCMAKE_DISABLE_FIND_PACKAGE_Eigen3=ON"]
    if args.linkage == "shared":
        # Shared exports must not require private implementation packages.
        options += ["-DCMAKE_DISABLE_FIND_PACKAGE_fmt=ON"]
    configure(args, SCRIPTS / "consumer", consumer, *options)
    build(args, consumer)
    test(consumer, args.config, required={"consumer.smoke"})

    if args.linkage == "static":
        # Existing dependency targets must be reused instead of being searched
        # again; static imports must still preserve the fmt link edge.
        preprovided = root / "consumer-preprovided"
        configure(
            args,
            SCRIPTS / "consumer",
            preprovided,
            f"-DCMAKE_PREFIX_PATH={prefix}",
            "-DCMAKE_DISABLE_FIND_PACKAGE_Eigen3=ON",
            "-DMYPROJECT_PREPROVIDE_DEPENDENCIES=ON",
        )
        build(args, preprovided)
        test(preprovided, args.config, required={"consumer.smoke"})


def check_embedded(args, root, warning_flag, expected_library_tests):
    directory = root / "embedded"
    configure(
        args,
        SCRIPTS / "superproject",
        directory,
        warning_flag,
        f"-DBUILD_SHARED_LIBS={'ON' if args.linkage == 'shared' else 'OFF'}",
        f"-DCPM_SOURCE_CACHE={cpm_cache()}",
        "-DMYPROJECT_BUILD_TESTS=ON",
        "-DMYPROJECT_WERROR=ON",
    )
    build(args, directory)
    embedded_tests = test(
        directory,
        args.config,
        required={"superproject.smoke", *expected_library_tests},
    )
    library_test_names(embedded_tests, directory)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", choices=("Debug", "Release"), default="Release")
    parser.add_argument("--linkage", choices=("static", "shared"), default="static")
    parser.add_argument(
        "--scope",
        choices=("build", "package", "embedded", "all"),
        default="build",
        help="build: configure/build/CTest; package: install/find_package/consumer; "
        "embedded: add_subdirectory; all: every scope with one linkage",
    )
    parser.add_argument(
        "--generator", help="CMake generator; defaults to the platform's generator"
    )
    parser.add_argument(
        "--jobs", type=int, default=2, help="Maximum parallel build jobs (default: 2)"
    )
    parser.add_argument(
        "--cmake-flag", action="append", default=[], help="Forward an extra -D setting"
    )
    parser.add_argument("--build-root", type=Path, default=REPO / "_ci")
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    if any(not flag.startswith("-D") for flag in args.cmake_flag):
        parser.error("--cmake-flag must be a -D setting")

    version = run("cmake", "--version", capture=True)
    match = re.search(r"cmake version (\d+)\.(\d+)\.(\d+)", version)
    if not match or tuple(map(int, match.groups())) < (3, 26, 0):
        parser.error("CMake 3.26 or newer is required")
    # CMake 4.4 renamed the warning category; the old name is no longer accepted.
    warning_flag = (
        "-Werror=author"
        if tuple(map(int, match.groups())) >= (4, 4, 0)
        else "-Werror=dev"
    )

    args.build_root = args.build_root.resolve()
    args.build_root.mkdir(parents=True, exist_ok=True)
    workspace = Path(
        tempfile.mkdtemp(prefix=f"{args.config.lower()}-", dir=args.build_root)
    )
    print(f"Build workspace: {workspace}", flush=True)
    try:
        library = None
        expected_library_tests = set()
        if args.scope in ("build", "package", "all"):
            library, expected_library_tests = build_library(args, workspace)
        if args.scope in ("package", "all"):
            check_package(args, workspace, library)
        if args.scope in ("embedded", "all"):
            check_embedded(args, workspace, warning_flag, expected_library_tests)
    except (subprocess.CalledProcessError, RuntimeError) as error:
        print(f"FAILED: {error}\nBuild files and logs: {workspace}", file=sys.stderr)
        return 1
    scope = "all scopes" if args.scope == "all" else f"{args.scope} scope"
    print(
        f"\n{scope.capitalize()} passed ({args.linkage}, {args.config}). "
        f"Build files and logs: {workspace}"
    )
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except OSError as error:
        print(f"FAILED: {error}", file=sys.stderr)
        sys.exit(1)
