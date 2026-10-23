"""Rename the template placeholders into a fresh project.

The initialization is a one-shot, multi-file rewrite: every step either succeeds,
is reported as a failure with a non-zero exit code, or is explicitly out of scope
(binary assets and the directories listed in SKIP_PATTERNS). A partially
initialized tree must never be reported as a success.
"""

import argparse
import fnmatch
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Path components that take no part in renaming or rewriting. The build patterns
# mirror .gitignore, so a tree that was built before initialization keeps its
# build outputs untouched; script/ holds this initializer itself.
SKIP_PATTERNS = (
    ".git",
    ".cache",
    ".ruff_cache",
    "__pycache__",
    "_ci",
    "_deps",
    "_install",
    "Build",
    "build",
    "build-*",
    "out",
    "script",
)

# Files that only make sense in the template repository.
TEMPLATE_ONLY_FILES = (
    ".github/scripts/test_template.py",
    ".github/workflows/template.yml",
    "script/README.project.md",
    "script/init_project.py",
)

PROJECT_NAME_PATTERN = r"[A-Za-z][A-Za-z0-9_]*"
NAMESPACE_PATTERN = r"[a-z][a-z0-9_]*"


def fail(message):
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-name", help="CMake project name, e.g. AwesomeApp")
    parser.add_argument(
        "--namespace", help="C++ namespace and CMake package prefix, e.g. awesome"
    )
    args = parser.parse_args()
    if not args.project_name:
        args.project_name = input(
            "Enter Project Name (CamelCase, e.g., AwesomeApp): "
        ).strip()
    if not args.namespace:
        args.namespace = input(
            "Enter Namespace/Prefix (lowercase, e.g., awesome): "
        ).strip()
    if not re.fullmatch(PROJECT_NAME_PATTERN, args.project_name):
        fail(
            f"invalid project name {args.project_name!r}: use letters, digits and "
            "underscores, starting with a letter (e.g. AwesomeApp)"
        )
    if not re.fullmatch(NAMESPACE_PATTERN, args.namespace):
        fail(
            f"invalid namespace {args.namespace!r}: use lowercase letters, digits and "
            "underscores, starting with a lowercase letter (e.g. awesome)"
        )
    if args.project_name == "MyProject" or args.namespace == "myproject":
        fail(
            "choose names that differ from the template's MyProject/myproject placeholders"
        )
    return args


def is_skipped(relative):
    return any(
        fnmatch.fnmatchcase(part, pattern)
        for part in relative.parts
        for pattern in SKIP_PATTERNS
    )


def walk(root):
    """Yield (path relative to root, subdirectories, files) for every directory in scope."""
    for current, dirnames, filenames in os.walk(root):
        relative = Path(current).relative_to(root)
        dirnames[:] = sorted(
            name for name in dirnames if not is_skipped(relative / name)
        )
        yield relative, dirnames, sorted(filenames)


def plan(root, project_name, namespace):
    """Collect the renames before touching the tree, so failures leave no half state."""
    directories = []
    files = []
    for relative, dirnames, filenames in walk(root):
        for name in dirnames:
            if name == "myproject":
                directories.append(root / relative / name)
        for name in filenames:
            target = name.replace("MyProject", project_name).replace(
                "myproject", namespace
            )
            if target != name:
                files.append((root / relative / name, target))
    return directories, files


def rename(path, target):
    if target.exists():
        fail(f"cannot rename {path.relative_to(ROOT)}: {target.name} already exists")
    path.rename(target)
    print(f"renamed {path.relative_to(ROOT)} -> {target.name}")


def rewrite_file(path, replacements):
    data = path.read_bytes()
    if b"\0" in data:
        return False  # binary asset: a project placeholder is not meaningful here
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        # Not UTF-8 text. Leaving it alone is only safe when it carries no
        # placeholder; otherwise the tree would be initialized halfway.
        if any(
            marker in data.decode("utf-8", errors="replace") for marker in replacements
        ):
            fail(
                f"{path.relative_to(ROOT)} is not UTF-8 text but contains a project placeholder"
            )
        return False
    updated = text
    for old, new in replacements.items():
        updated = updated.replace(old, new)
    if updated == text:
        return False
    try:
        path.write_text(updated, encoding="utf-8", newline="")
    except OSError as error:
        fail(f"cannot rewrite {path.relative_to(ROOT)}: {error}")
    return True


def rewrite_tree(root, replacements):
    changed = 0
    for relative, _, filenames in walk(root):
        for name in filenames:
            changed += rewrite_file(root / relative / name, replacements)
    return changed


def write_readme(project_name, namespace):
    template = ROOT / "script" / "README.project.md"
    text = template.read_text(encoding="utf-8")
    for marker, value in (
        ("@@PROJECT_NAME@@", project_name),
        ("@@NAMESPACE@@", namespace),
        ("@@UPPER@@", project_name.upper()),
    ):
        text = text.replace(marker, value)
    (ROOT / "README.md").write_text(text, encoding="utf-8", newline="")
    print(f"wrote README.md for {project_name}")


def remove_template_files():
    removed = []
    for name in TEMPLATE_ONLY_FILES:
        path = ROOT / name
        if path.exists():
            path.unlink()
            removed.append(name)
    script_dir = ROOT / "script"
    if script_dir.is_dir() and not any(script_dir.iterdir()):
        script_dir.rmdir()
    print(f"removed template-only files: {', '.join(removed) if removed else 'none'}")


def main():
    args = parse_args()
    project_name = args.project_name
    namespace = args.namespace
    replacements = {
        "MyProject": project_name,
        "MYPROJECT": project_name.upper(),
        "myproject": namespace,
    }

    directories, files = plan(ROOT, project_name, namespace)
    if not directories and not files:
        fail(
            "nothing to initialize: the MyProject/myproject placeholders were not found, "
            "which means this tree is already initialized"
        )

    # Files first: their parent directories may themselves be renamed afterwards.
    for path, name in files:
        rename(path, path.with_name(name))
    # Deepest directory first, so an already renamed parent never invalidates a
    # pending path.
    for path in sorted(directories, key=lambda item: len(item.parts), reverse=True):
        rename(path, path.with_name(namespace))

    rewritten = rewrite_tree(ROOT, replacements)
    write_readme(project_name, namespace)
    remove_template_files()

    print(
        f"\nInitialized {project_name} (namespace {namespace}); rewrote {rewritten} files."
    )
    print("Next steps:")
    print("  mkdir build && cd build")
    print("  cmake ..")
    print("  cmake --build .")
    print("  ctest --output-on-failure")


if __name__ == "__main__":
    main()
