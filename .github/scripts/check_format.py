"""Check the formatting of tracked C and C++ sources."""

import subprocess
import sys
from pathlib import Path


def main():
    repo = Path(__file__).resolve().parents[2]  # .github/scripts/ -> repository root
    subprocess.run(["clang-format", "--version"], check=True)
    tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=repo)
    suffixes = {".h", ".hpp", ".cpp", ".cc", ".c"}
    files = [Path(name.decode("utf-8")) for name in tracked.split(b"\0") if name]
    sources = [path for path in files if path.suffix in suffixes]
    if not sources:
        raise RuntimeError("No tracked C or C++ sources found")
    failed = False
    for source in sources:
        result = subprocess.run(
            ["clang-format", "--dry-run", "-Werror", str(repo / source)], check=False
        )
        failed |= result.returncode != 0
    print(f"Checked {len(sources)} source files")
    return int(failed)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, subprocess.CalledProcessError, RuntimeError) as error:
        print(f"FAILED: {error}", file=sys.stderr)
        sys.exit(1)
