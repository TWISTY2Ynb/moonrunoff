"""Independent version boundary tests for the release toolchain gate."""
import contextlib
import io
import subprocess
import unittest
from unittest.mock import patch

from check_toolchain import main, validate_version


class ToolchainTests(unittest.TestCase):
    def test_supported_versions(self):
        for version in ["v1.0.0-rc1+3c0520448 (2026-11-26)", "v1.0.0-rc2", "v1.0.0", "v1.0.1-beta1", "v2.0.0-alpha1"]:
            with self.subTest(version=version):
                validate_version(version)

    def test_unsupported_and_malformed_versions(self):
        for version in ["v0.10.22+124d61d05", "v0.99.99", "v1.0.0-alpha9", "v1.0.0-beta99", "v1.0.0-rc0", "v1.0.0-rc", "v1.0.0-rc01", "v1.0.0-preview1", "v1.0.0bad", "v01.0.0", "", "unknown", "v1.0.0+"]:
            with self.subTest(version=version), self.assertRaises(ValueError):
                validate_version(version)

    def test_rejected_cli_returns_failure(self):
        with patch("subprocess.check_output", return_value="v0.10.18"), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(main(), 1)

    def test_missing_or_failed_compiler_returns_failure(self):
        for error in [FileNotFoundError("moonc"), subprocess.CalledProcessError(1, ["moonc", "-v"])]:
            with self.subTest(error=error), patch("subprocess.check_output", side_effect=error), contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(main(), 1)

    def test_current_cli_returns_success(self):
        with patch("subprocess.check_output", return_value="v1.0.0-rc1+3c0520448"), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(main(), 0)


if __name__ == "__main__":
    unittest.main()
