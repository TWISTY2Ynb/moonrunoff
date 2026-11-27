"""Reject compilers below the documented minimum, including with python -O."""
import re
import subprocess
import sys

MINIMUM_VERSION = (1, 0, 0, 2, 1)  # 1.0.0-rc1; alpha < beta < rc < stable
_VERSION = re.compile(
    r"\bv(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
    r"(?:-(alpha|beta|rc)(0|[1-9]\d*))?"
    r"(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?(?=\s|$)"
)


def validate_version(text):
    match = _VERSION.search(text)
    if match:
        major, minor, patch, stage, serial = match.groups()
        version = (int(major), int(minor), int(patch),
                   {"alpha": 0, "beta": 1, "rc": 2, None: 3}[stage],
                   int(serial or 0))
        if version >= MINIMUM_VERSION:
            return
    raise ValueError("MoonBit moonc >= 1.0.0-rc1 is required")


def main():
    try:
        text = subprocess.check_output(["moonc", "-v"], text=True)
        validate_version(text)
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        print(f"Toolchain check failed: {error}", file=sys.stderr)
        return 1
    print(text.strip())
    return 0


if __name__ == "__main__":
    sys.exit(main())
