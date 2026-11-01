"""Initialize a fresh project from the template and run that project's own checks.

This script tests the template repository: it copies the tree, runs the real
initializer with a non-default name, and then verifies the result the way the
generated project's CI does. The generated project never runs the initializer
again -- this script and the template workflow are removed while initializing.
"""

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]  # .github/scripts/ -> repository root
PROJECT_NAME = "AwesomeApp"
NAMESPACE = "awesome"

# Build outputs and caches from the template checkout never belong to the copy.
COPY_IGNORED = (
    ".git",
    ".cache",
    ".ruff_cache",
    "__pycache__",
    "Build",
    "build",
    "build-*",
    "out",
    "_ci",
    "_deps",
    "_install",
)


def run(*argv, cwd=None, check=True):
    print("+", " ".join(map(str, argv)), flush=True)
    result = subprocess.run([str(arg) for arg in argv], check=False, cwd=cwd, text=True)
    if check and result.returncode != 0:
        raise SystemExit(f"FAILED (exit {result.returncode}): {argv[0]}")
    return result


def copy_template(destination):
    shutil.copytree(REPO, destination, ignore=shutil.ignore_patterns(*COPY_IGNORED))


def initialize(project):
    run(
        sys.executable,
        "script/init_project.py",
        "--project-name",
        PROJECT_NAME,
        "--namespace",
        NAMESPACE,
        cwd=project,
    )


def check_initialized(project):
    for relative in (
        f"include/{NAMESPACE}/core.hpp",
        f"include/{NAMESPACE}/export.hpp",
        f"cmake/{NAMESPACE}Config.cmake.in",
        f"cmake/{NAMESPACE}Options.cmake",
        "tests/CMakeLists.txt",
    ):
        if not (project / relative).is_file():
            raise SystemExit(f"initialization did not produce {relative}")
    for relative in ("include/myproject", "script"):
        if (project / relative).exists():
            raise SystemExit(f"initialization left {relative} behind")
    for relative in (
        ".github/scripts/test_template.py",
        ".github/workflows/template.yml",
    ):
        if (project / relative).exists():
            raise SystemExit(f"template-only {relative} survived initialization")
    # The generated project must not keep a job that initializes a template.
    if "template-e2e" in (project / ".github/workflows/ci.yml").read_text(
        encoding="utf-8"
    ):
        raise SystemExit("generated ci.yml still contains the template job")

    readme = (project / "README.md").read_text(encoding="utf-8")
    if not readme.startswith(f"# {PROJECT_NAME}"):
        raise SystemExit("generated README.md is not about the new project")

    leftover = placeholders(project)
    if leftover:
        raise SystemExit(f"template placeholders survived initialization: {leftover}")


def placeholders(root):
    """Report any text file that still carries a template placeholder."""
    found = []
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        data = path.read_bytes()
        if b"\0" in data:
            continue
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            continue
        for marker in ("MyProject", "MYPROJECT", "myproject"):
            if marker in text:
                found.append(f"{path.relative_to(root)} ({marker})")
    return found


def check_rejected_input(project):
    """Invalid names must fail before the tree is touched."""
    for arguments in (
        ("--project-name", "Bad-Name", "--namespace", "awesome"),
        ("--project-name", "AwesomeApp", "--namespace", "Awesome"),
        ("--project-name", "Awesome App", "--namespace", "awesome"),
        ("--project-name", "AwesomeApp", "--namespace", "a/b"),
    ):
        result = run(
            sys.executable,
            "script/init_project.py",
            *arguments,
            cwd=project,
            check=False,
        )
        if result.returncode == 0:
            raise SystemExit(
                f"initializer accepted invalid input: {' '.join(arguments)}"
            )
    if not (project / "include/myproject/core.hpp").is_file():
        raise SystemExit("a rejected initialization modified the tree")


def check_generated_ci(project):
    """Run the platform-neutral part of the generated project's own CI."""
    run("git", "init", "-q", "-b", "main", cwd=project)
    identity = (
        "-c",
        "user.name=template-e2e",
        "-c",
        "user.email=template-e2e@example.com",
    )
    run("git", *identity, "add", "-A", cwd=project)
    run(
        "git",
        *identity,
        "commit",
        "-q",
        "-m",
        "Initialize from the template",
        cwd=project,
    )

    # Same commands as the generated project's ci.yml, restricted to one machine:
    # both linkagings over every scope.
    for linkage, config in (("static", "Debug"), ("shared", "Release")):
        run(
            sys.executable,
            ".github/scripts/check_build.py",
            "--generator",
            "Ninja",
            "--config",
            config,
            "--linkage",
            linkage,
            "--scope",
            "all",
            cwd=project,
        )


def main():
    # Reuse the template checkout's dependency sources instead of downloading them
    # again for the copies.
    os.environ.setdefault("CPM_SOURCE_CACHE", str(REPO / ".cache" / "cpm"))
    with tempfile.TemporaryDirectory(prefix="cpp-template-") as workspace:
        project = Path(workspace) / "fresh-project"
        copy_template(project)
        # Run the real initializer without mutating the source tree.
        initialize(project)
        check_initialized(project)

        rejected = Path(workspace) / "rejected-input"
        copy_template(rejected)
        check_rejected_input(rejected)

        check_generated_ci(project)
        print(
            f"\n{PROJECT_NAME} initialized from the template and passed its own CI checks."
        )


if __name__ == "__main__":
    main()
