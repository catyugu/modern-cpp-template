"""Exercise the template as a newly initialized downstream project."""

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]  # .github/scripts/ -> repository root


def run(*argv, cwd=None, input_text=None, env=None):
    print("+", " ".join(map(str, argv)), flush=True)
    subprocess.run(
        [str(arg) for arg in argv],
        cwd=cwd,
        input=input_text,
        text=True,
        check=True,
        env=env,
    )


def main():
    # Reuse the repository's dependency sources instead of downloading them again
    # for the copy.
    cpm_cache = os.environ.get("CPM_SOURCE_CACHE") or str(REPO / ".cache" / "cpm")
    env = {**os.environ, "CPM_SOURCE_CACHE": cpm_cache}

    with tempfile.TemporaryDirectory(prefix="cpp-template-e2e-") as workspace:
        project = Path(workspace) / "fresh-project"
        shutil.copytree(
            REPO,
            project,
            ignore=shutil.ignore_patterns(
                ".git", ".cache", "_ci", "build", "out", "__pycache__"
            ),
        )
        # Run the real interactive initializer without mutating the source tree.
        run(
            sys.executable,
            "script/init_project.py",
            cwd=project,
            input_text="FreshProject\nfreshproject\n",
            env=env,
        )
        assert (project / "include/freshproject/core.hpp").is_file()
        assert (project / "cmake/freshprojectConfig.cmake.in").is_file()
        assert not (project / "include/myproject").exists()

        # A single linkage is enough here: the renamed project's install/consumer
        # and add_subdirectory paths are covered once, not per linkage.
        run(
            sys.executable,
            ".github/scripts/check_build.py",
            "--generator",
            "Ninja",
            "--config",
            "Release",
            "--linkage",
            "shared",
            "--scope",
            "all",
            cwd=project,
            env=env,
        )
        print("Freshly initialized project passed end-to-end checks.")


if __name__ == "__main__":
    main()
