"""Build, test, install and consume the library with the selected toolchain."""

import argparse
import json
import re
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]


def run(*command, capture=False):
    args = [str(arg) for arg in command]
    print(f"+ {shlex.join(args)}", flush=True)
    return subprocess.run(
        args, cwd=REPO, check=True, text=True, encoding="utf-8",
        stdout=subprocess.PIPE if capture else None,
    ).stdout


def test(build, config, *, required=(), require_library=False, expected_library_tests=()):
    command = ("ctest", "--test-dir", build, "-C", config)
    listing = json.loads(run(*command, "--show-only=json-v1", capture=True))
    names = {entry["name"] for entry in listing["tests"]}
    missing = (set(required) | set(expected_library_tests)) - names
    if missing:
        raise RuntimeError(f"Tests not registered in {build}: {sorted(missing)}")
    if require_library and not any(name.startswith("myproject.") for name in names):
        raise RuntimeError(f"Library tests not registered in {build}")
    run(*command, "--output-on-failure", "--no-tests=error", "--timeout", "60")
    return {name for name in names if name.startswith("myproject.")}


def check_linkage(args, workspace, linkage, warning_flag):
    root = workspace / linkage
    prefix = root / "install"
    shared = "ON" if linkage == "shared" else "OFF"
    cache = REPO / ".cache" / "cpm"

    def configure(source, build, *options):
        command = ["cmake", "-S", source, "-B", build]
        if args.generator:
            command += ["-G", args.generator]
        if args.toolset:
            command += ["-T", args.toolset]
        run(*command, f"-DCMAKE_BUILD_TYPE={args.config}", *args.cmake_flag, *options)

    def build(directory):
        run("cmake", "--build", directory, "--config", args.config, "--parallel", args.jobs)

    print(f"\n=== {args.config} / {linkage} ===", flush=True)
    library_tests = set()
    if args.scope in ("all", "library"):
        directory = root / "library"
        configure(
            REPO, directory, f"-DBUILD_SHARED_LIBS={shared}",
            f"-DCPM_SOURCE_CACHE={cache}", f"-DCMAKE_INSTALL_PREFIX={prefix}",
            "-DMYPROJECT_BUILD_TESTS=ON", "-DMYPROJECT_WERROR=ON",
        )
        build(directory)
        library_tests = test(directory, args.config, require_library=True)
        run("cmake", "--install", directory, "--config", args.config)

        # Consume only this run's install; never search a stale prefix or source tree.
        consumer = root / "consumer"
        configure(REPO / "ci" / "consumer", consumer, f"-DCMAKE_PREFIX_PATH={prefix}")
        build(consumer)
        test(consumer, args.config, required={"consumer.smoke"})

    if args.scope in ("all", "embedded"):
        directory = root / "embedded"
        configure(
            REPO / "ci" / "superproject", directory, warning_flag,
            f"-DBUILD_SHARED_LIBS={shared}", f"-DCPM_SOURCE_CACHE={cache}",
            "-DMYPROJECT_BUILD_TESTS=ON", "-DMYPROJECT_WERROR=ON",
        )
        build(directory)
        test(
            directory, args.config, required={"superproject.smoke"},
            require_library=True, expected_library_tests=library_tests,
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", choices=("Debug", "Release"), default="Release")
    parser.add_argument("--linkage", choices=("static", "shared", "both"), default="both")
    parser.add_argument("--scope", choices=("all", "library", "embedded"), default="all")
    parser.add_argument("--generator", help="CMake generator; defaults to the platform's generator")
    parser.add_argument("--toolset", help="Visual Studio toolset, e.g. ClangCL")
    parser.add_argument("--jobs", type=int, default=2, help="Maximum parallel build jobs (default: 2)")
    parser.add_argument("--cmake-flag", action="append", default=[], help="Forward an extra -D setting")
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
    warning_flag = "-Werror=author" if tuple(map(int, match.groups())) >= (4, 4, 0) else "-Werror=dev"

    args.build_root = args.build_root.resolve()
    args.build_root.mkdir(parents=True, exist_ok=True)
    workspace = Path(tempfile.mkdtemp(prefix=f"{args.config.lower()}-", dir=args.build_root))
    print(f"Build workspace: {workspace}", flush=True)
    try:
        linkages = ("static", "shared") if args.linkage == "both" else (args.linkage,)
        for linkage in linkages:
            check_linkage(args, workspace, linkage, warning_flag)
    except (subprocess.CalledProcessError, RuntimeError) as error:
        print(f"FAILED: {error}\nBuild files and logs: {workspace}", file=sys.stderr)
        return 1
    print(f"\nAll checks passed. Build files and logs: {workspace}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except OSError as error:
        print(f"FAILED: {error}", file=sys.stderr)
        sys.exit(1)
