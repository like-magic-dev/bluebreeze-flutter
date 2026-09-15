"""
Update the version number in pubspec.yaml.

This script updates pubspec.yaml's top-level "version" field, the single source of truth for
this package's own release version -- separate from android/build.gradle's and
ios/bluebreeze.podspec's/ios/bluebreeze/Package.swift's BlueBreeze *dependency* version pins,
which track the native bluebreeze-android/bluebreeze-ios SDKs' own releases and are bumped
independently of this package's version.

ios/bluebreeze.podspec reads pubspec.yaml's version directly at pod-install time (see its
`YAML.load_file` line), so it never needs a separate update here.

Usage:
    python bump_version.py <version>

Example:
    python bump_version.py 1.0.1
"""

import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
PUBSPEC = PROJECT_ROOT / "pubspec.yaml"

# Anchored to the start of the line so this only matches the top-level "version:" field --
# not e.g. the "flutter:"/"environment:" sections, which don't contain a same-named key.
VERSION_PATTERN = re.compile(r"^(version: )[\d.]+", re.MULTILINE)


def update_pubspec_version(version: str) -> bool:
    if not PUBSPEC.exists():
        print(f"✗ pubspec.yaml not found: {PUBSPEC}")
        return False

    print(f"\n{'=' * 60}")
    print(f"Updating pubspec.yaml to version {version}...")
    print("=" * 60)

    try:
        content = PUBSPEC.read_text(encoding="utf-8")

        new_content, count = VERSION_PATTERN.subn(rf"\g<1>{version}", content)

        if count == 0:
            print('✗ Did not find a top-level "version: ..." field to update')
            return False

        PUBSPEC.write_text(new_content, encoding="utf-8")

        print(f"✓ Updated pubspec.yaml to version {version}")
        return True

    except Exception as e:
        print(f"✗ Failed to update pubspec.yaml: {e}")
        return False


def main():
    if len(sys.argv) != 2:
        print("Usage: python bump_version.py <version>")
        print("Example: python bump_version.py 1.0.1")
        sys.exit(1)

    version = sys.argv[1]

    if not re.match(r"^\d+\.\d+\.\d+$", version):
        print(f"✗ Invalid version format: {version}")
        print("Version should be in format: X.Y.Z (e.g., 1.0.1)")
        sys.exit(1)

    if not update_pubspec_version(version):
        sys.exit(1)

    print("=" * 60)


if __name__ == "__main__":
    main()
