"""Exercise the template as a newly initialized downstream project."""

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]  # .github/scripts/ -> repository root


def run(*argv, cwd=None, input_text=None):
    print("+", " ".join(map(str, argv)), flush=True)
    subprocess.run(
        [str(arg) for arg in argv],
        cwd=cwd,
        input=input_text,
        text=True,
        check=True,
    )


def main():
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
        )
        assert (project / "include/freshproject/core.hpp").is_file()
        assert (project / "cmake/freshprojectConfig.cmake.in").is_file()
        assert not (project / "include/myproject").exists()

        # The renamed CI fixtures must also build an installed package through
        # find_package(), reuse fmt::fmt, and work as an add_subdirectory().
        run(
            sys.executable,
            ".github/scripts/check_build.py",
            "--generator",
            "Ninja",
            "--config",
            "Release",
            "--linkage",
            "both",
            "--scope",
            "all",
            cwd=project,
        )
        print("Freshly initialized project passed end-to-end checks.")


if __name__ == "__main__":
    main()
