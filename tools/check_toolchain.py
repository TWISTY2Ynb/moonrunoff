"""Reject compilers below the documented minimum, including with python -O."""
import re
import subprocess
import sys

MINIMUM_VERSION = (0, 10, 22)


def validate_version(text):
    match = re.search(r"\bv(\d+)\.(\d+)\.(\d+)(?=[+\s]|$)", text)
    if not match or tuple(map(int, match.groups())) < MINIMUM_VERSION:
        raise ValueError("MoonBit moonc >= 0.10.22 is required")


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
