"""
Prepare a new release of bluebreeze.

This is a verifying gate, not just a file-rewriter: it runs the full release preparation
sequence, but checks its own work at each step and stops at the first problem instead of leaving
you to discover it after tagging and pushing.

Unlike the native bluebreeze-android/bluebreeze-ios repos, this package has no assigned-numbers
table to refresh (BBAssignedNumbers lives in, and is generated for, those native SDKs only) and
doesn't follow their copyright-header convention, so this script has no equivalent of their
fetch_assigned_numbers.py/fix_copyright_headers.py steps -- in that respect it mirrors
bluebreeze-react-native's tools/prepare_release.py more closely than the native repos' scripts.
What it does add, since this package ships real native code of its own, is a build check for
each platform's bridge module, via the example app.

Steps:
1. Verifies the git working tree is clean (so unrelated changes don't get swept into the release).
2. Verifies the requested version is valid and newer than every existing tag.
3. bump_version.py       - updates pubspec.yaml's version.
4. Verifies pubspec.yaml was actually updated to the requested version.
5. flutter analyze       - verifies the Dart source has no type or lint errors.
6. flutter test          - verifies the Dart unit test suite passes (skipped if there is no
                            top-level test/ directory -- this package doesn't have one yet).
7. flutter pub publish   - dry run; verifies the package passes pub.dev's own publish checks
                            (pubspec correctness, required files, package size, ...).
8. Android build         - verifies the Kotlin native plugin compiles, via the example app.
9. iOS build             - verifies the Swift native plugin compiles, via the example app.
                            Skipped on non-macOS hosts, since it needs Xcode.

Nothing is committed, tagged, published, or pushed automatically -- this only prepares and
verifies the working tree, and prints the remaining manual steps at the end.

Usage:
    python prepare_release.py <version>

Example:
    python prepare_release.py 1.0.1
"""

import os
import platform
import re
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
TOOLS_DIR = Path(__file__).parent

VERSION_PATTERN = re.compile(r"^\d+\.\d+\.\d+$")


def fail(message: str) -> None:
    print(f"\n✗ {message}")
    sys.exit(1)


def resolve_flutter_bin() -> str:
    """Resolve `flutter` to an absolute path.

    It's often reachable only via a project-relative PATH entry (e.g. fvm's
    `.fvm/flutter_sdk/bin`), which stops resolving once we cwd into example/ for the native
    builds below -- so we need an absolute path good from any cwd, not just the bare name.
    """
    flutter_bin = shutil.which("flutter", path=f"{PROJECT_ROOT / '.fvm/flutter_sdk/bin'}:{os.environ.get('PATH', '')}")
    if flutter_bin is None:
        fail("Could not find the `flutter` executable on PATH or in .fvm/flutter_sdk/bin.")
    return flutter_bin


def run_script(script_name: str, args: list = None) -> None:
    """Run a tools script from the project root, failing the release if it doesn't succeed."""
    print(f"\n{'=' * 60}")
    print(f"Running {script_name}...")
    print("=" * 60)

    cmd = [sys.executable, str(TOOLS_DIR / script_name)]
    if args:
        cmd.extend(args)

    result = subprocess.run(cmd, cwd=PROJECT_ROOT)
    if result.returncode != 0:
        fail(f"{script_name} failed with exit code {result.returncode}")

    print(f"✓ {script_name} completed successfully")


def run_command(description: str, cmd: list, cwd: Path = PROJECT_ROOT) -> None:
    """Run a plain shell command, failing the release if it doesn't succeed."""
    print(f"\n{'=' * 60}")
    print(f"{description}...")
    print("=" * 60)

    result = subprocess.run(cmd, cwd=cwd)
    if result.returncode != 0:
        fail(f"{description} failed with exit code {result.returncode}")

    print(f"✓ {description} succeeded")


def check_git_tree_clean() -> None:
    result = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    if result.stdout.strip():
        fail(
            "Working tree is not clean. Commit or stash pending changes before preparing a "
            "release -- otherwise they'll get mixed into the release commit.\n\n"
            f"{result.stdout}"
        )


def existing_tags() -> list:
    result = subprocess.run(
        ["git", "tag"],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return [tag for tag in result.stdout.splitlines() if tag.strip()]


def check_version_is_new(version: str) -> None:
    tags = existing_tags()

    if version in tags:
        fail(f"Tag {version} already exists.")

    version_tuple = tuple(int(part) for part in version.split("."))
    for tag in tags:
        if not VERSION_PATTERN.match(tag):
            continue

        if version_tuple <= tuple(int(part) for part in tag.split(".")):
            fail(
                f"Version {version} is not newer than existing tag {tag}. Double-check you "
                "passed the intended version."
            )


def check_pubspec_version(version: str) -> None:
    pubspec_path = PROJECT_ROOT / "pubspec.yaml"
    content = pubspec_path.read_text(encoding="utf-8")

    if not re.search(rf"^version: {re.escape(version)}$", content, re.MULTILINE):
        fail(f"pubspec.yaml's version was not updated to {version} as expected.")

    print(f"✓ pubspec.yaml correctly reflects version {version}")


def main():
    if len(sys.argv) != 2:
        print("Usage: python prepare_release.py <version>")
        print("Example: python prepare_release.py 1.0.1")
        sys.exit(1)

    version = sys.argv[1]

    if not VERSION_PATTERN.match(version):
        fail(f"Invalid version format: {version}. Version should be in format: X.Y.Z (e.g., 1.0.1)")

    print(f"Preparing release version {version}...")

    flutter_bin = resolve_flutter_bin()

    check_git_tree_clean()
    check_version_is_new(version)

    run_script("bump_version.py", [version])
    check_pubspec_version(version)

    run_command("Fetching Dart dependencies", [flutter_bin, "pub", "get"])
    run_command("Analyzing the Dart source", [flutter_bin, "analyze"])

    if (PROJECT_ROOT / "test").is_dir():
        run_command("Running the Dart unit test suite", [flutter_bin, "test"])
    else:
        print(f"\n{'=' * 60}")
        print("Skipping the Dart unit test suite -- there is no top-level test/ directory.")
        print("=" * 60)

    run_command("Verifying the package is publishable", [flutter_bin, "pub", "publish", "--dry-run"])

    run_command("Fetching the example app's Dart dependencies", [flutter_bin, "pub", "get"], cwd=PROJECT_ROOT / "example")
    run_command(
        "Building the Android native module",
        [flutter_bin, "build", "apk", "--debug"],
        cwd=PROJECT_ROOT / "example",
    )

    if platform.system() == "Darwin":
        run_command(
            "Building the iOS native module",
            [flutter_bin, "build", "ios", "--no-codesign", "--debug"],
            cwd=PROJECT_ROOT / "example",
        )
    else:
        print(f"\n{'=' * 60}")
        print("Skipping the iOS build -- it requires Xcode, which only runs on macOS.")
        print("=" * 60)

    print(f"\n{'=' * 60}")
    print(f"✓ Release {version} prepared successfully!")
    print("\nNext steps:")
    print("  1. Review changes: git diff")
    print(f"  2. Update CHANGES.md with a # {version} entry describing what changed")
    print(f"  3. Commit changes: git add . && git commit -m 'Prepare release {version}'")
    print(f"  4. Tag release: git tag {version}")
    print("  5. Publish to pub.dev: flutter pub publish")
    print("  6. Push: git push && git push --tags")
    print("=" * 60)


if __name__ == "__main__":
    main()
