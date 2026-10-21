"""Check CPM source selection, cache reuse, and parent ownership."""

import os
import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]


def run(*command, env=None, succeeds=True):
    print("+", " ".join(map(str, command)), flush=True)
    result = subprocess.run(
        list(map(str, command)), env=env, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    if (result.returncode == 0) != succeeds:
        raise RuntimeError(result.stdout)
    return result.stdout


def main():
    (REPO / "_ci").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="dependencies-", dir=REPO / "_ci") as tmp:
        root = Path(tmp)
        cache = Path(os.environ.get("CPM_SOURCE_CACHE", root / "cache")).resolve()
        prefix = root / "install"
        env = os.environ.copy()
        env["CPM_SOURCE_CACHE"] = str(cache)

        def configure(name, *flags, source=REPO, succeeds=True):
            return run(
                "cmake", "-S", source, "-B", root / name, "-G", "Ninja",
                "-DCMAKE_BUILD_TYPE=Release", "-DMYPROJECT_BUILD_TESTS=OFF",
                "-DMYPROJECT_BUILD_EXAMPLES=OFF", "-DMYPROJECT_BUILD_TOOLS=OFF",
                *flags, env=env, succeeds=succeeds,
            )

        # Bootstrap from pinned source, then exercise a fresh build offline.
        configure("source", "-DCPM_DOWNLOAD_ALL=ON", f"-DCMAKE_INSTALL_PREFIX={prefix}")
        source_cache = (root / "source" / "CMakeCache.txt").read_text()
        assert f"CPM_SOURCE_CACHE:PATH={cache}" in source_cache
        fmt_source = next(cache.glob("fmt/*/CMakeLists.txt")).parent
        run("cmake", "--build", root / "source", "--parallel", "2")
        run("cmake", "--install", root / "source")
        offline = "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
        configure("cached", offline, "-DCMAKE_DISABLE_FIND_PACKAGE_fmt=ON")

        # An installed compatible package works without any source population.
        found = configure(
            "installed", offline, "-DCPM_LOCAL_PACKAGES_ONLY=ON",
            f"-DCMAKE_PREFIX_PATH={prefix}",
        )
        assert "Using local package fmt@12.2.0" in found

        # An old installation must be rejected before its config is executed.
        old = root / "old-fmt"
        old.mkdir()
        (old / "fmt-config-version.cmake").write_text(
            'set(PACKAGE_VERSION "12.1.0")\n'
            'set(PACKAGE_VERSION_COMPATIBLE FALSE)\n',
        )
        (old / "fmt-config.cmake").write_text(
            'message(FATAL_ERROR "Incompatible fmt config was loaded")\n',
        )
        configure("old-fallback", offline, f"-Dfmt_DIR={old}")
        rejected = configure(
            "old-local-only", offline, f"-Dfmt_DIR={old}",
            "-DCPM_LOCAL_PACKAGES_ONLY=ON", succeeds=False,
        )
        assert "not found via find_package" in rejected
        assert "Incompatible fmt config was loaded" not in rejected

        # A source override remains usable without package lookup or network.
        configure(
            "override", offline, "-DCPM_DOWNLOAD_fmt=ON",
            f"-DCPM_fmt_SOURCE={fmt_source}",
        )

        # The template's default is initialized before CPM; CLI beats env.
        default_env = env.copy()
        default_env.pop("CPM_SOURCE_CACHE")
        run(
            "cmake", "-S", REPO, "-B", root / "default-cache", "-G", "Ninja",
            "-DMYPROJECT_BUILD_TESTS=OFF", "-DMYPROJECT_BUILD_EXAMPLES=OFF",
            "-DMYPROJECT_BUILD_TOOLS=OFF", "-DCPM_DOWNLOAD_fmt=ON",
            f"-DCPM_fmt_SOURCE={fmt_source}", env=default_env,
        )
        defaults = (root / "default-cache" / "CMakeCache.txt").read_text()
        assert f"CPM_SOURCE_CACHE:PATH={REPO / '.cache' / 'cpm'}" in defaults
        cli_cache = root / "cli-cache"
        configure(
            "cache-cli", f"-DCPM_SOURCE_CACHE={cli_cache}",
            "-DCPM_DOWNLOAD_fmt=ON", f"-DCPM_fmt_SOURCE={fmt_source}",
        )
        cli = (root / "cache-cli" / "CMakeCache.txt").read_text()
        assert f"CPM_SOURCE_CACHE:PATH={cli_cache}" in cli

        # Top-level locks and redirects must not be disabled by the child.
        parent = root / "parent"
        parent.mkdir()
        lock = parent / "package-lock.cmake"
        lock.write_text(
            'CPMDeclarePackage(fmt NAME fmt VERSION 12.2.0\n'
            f'    SOURCE_DIR "{fmt_source.as_posix()}"\n'
            '    OPTIONS "FMT_INSTALL OFF" "FMT_TEST OFF" "FMT_DOC OFF")\n',
        )
        (parent / "CMakeLists.txt").write_text(
            'cmake_minimum_required(VERSION 3.26)\n'
            'project(parent LANGUAGES CXX C)\n'
            f'include("{REPO.as_posix()}/cmake/CPM.cmake")\n'
            f'CPMUsePackageLock("{lock.as_posix()}")\n'
            f'add_subdirectory("{REPO.as_posix()}" child)\n'
            'if(NOT TARGET cpm-update-package-lock)\n'
            '    message(FATAL_ERROR "Package lock target missing")\n'
            'endif()\n'
            'if(CPM_DONT_UPDATE_MODULE_PATH OR CPM_DONT_CREATE_PACKAGE_LOCK)\n'
            '    message(FATAL_ERROR "Child disabled CPM features")\n'
            'endif()\n'
            'find_package(fmt CONFIG REQUIRED)\n',
        )
        configure("locked", offline, "-DCPM_DOWNLOAD_ALL=ON", source=parent)
        run("cmake", "--build", root / "locked", "--target", "cpm-update-package-lock")
        assert "CPMDeclarePackage(fmt" in lock.read_text()

        # A pre-existing target wins even when package discovery is forbidden.
        (parent / "CMakeLists.txt").write_text(
            'cmake_minimum_required(VERSION 3.26)\n'
            'project(parent LANGUAGES CXX C)\n'
            'find_package(fmt 12.2.0 CONFIG REQUIRED)\n'
            'set(CMAKE_DISABLE_FIND_PACKAGE_fmt ON)\n'
            f'add_subdirectory("{REPO.as_posix()}" child)\n',
        )
        configure("provided", offline, f"-DCMAKE_PREFIX_PATH={prefix}", source=parent)
        print("Dependency selection checks passed.")


if __name__ == "__main__":
    main()
