#!/usr/bin/env python3
"""
DevCLI – Silent Terminal Profile Importer
Imports all DevCLI profiles directly into Terminal.app preferences
WITHOUT opening any new windows.
Also removes any leftover NeoShell profiles.

Usage: python3 import_profiles.py
"""

import plistlib
import subprocess
import os
import sys

SRC = os.path.join(os.path.dirname(__file__), "src")

PROFILES = [
    "DevCLI-Dark.terminal",
    "DevCLI-Glass.terminal",
    "DevCLI-Abyss.terminal",
    "DevCLI-Ghost.terminal",
]

STALE_PREFIXES = ["NeoShell", "neoshell"]


def read_terminal_prefs() -> dict:
    """Export Terminal.app prefs as a Python dict."""
    result = subprocess.run(
        ["defaults", "export", "com.apple.Terminal", "-"],
        capture_output=True,
    )
    if result.returncode != 0:
        print(f"  ✘ Could not read Terminal prefs: {result.stderr.decode()}")
        sys.exit(1)
    return plistlib.loads(result.stdout)


def write_terminal_prefs(prefs: dict) -> None:
    """Write a Python dict back into Terminal.app prefs."""
    plist_bytes = plistlib.dumps(prefs, fmt=plistlib.FMT_XML)
    result = subprocess.run(
        ["defaults", "import", "com.apple.Terminal", "-"],
        input=plist_bytes,
    )
    if result.returncode != 0:
        print(f"  ✘ Could not write Terminal prefs: {result.stderr.decode()}")
        sys.exit(1)


def main():
    print("\n  DevCLI – Terminal Profile Importer")
    print("  ─────────────────────────────────────")

    prefs = read_terminal_prefs()
    window_settings: dict = prefs.setdefault("Window Settings", {})

    # ── 1. Remove stale NeoShell profiles ─────────────────────
    removed = []
    for key in list(window_settings.keys()):
        if any(key.startswith(p) for p in STALE_PREFIXES):
            del window_settings[key]
            removed.append(key)
    if removed:
        for r in removed:
            print(f"  🗑  Removed stale profile: {r}")
    else:
        print("  ✔  No stale profiles found")

    # ── 2. Import DevCLI profiles silently ────────────────────
    for filename in PROFILES:
        path = os.path.join(SRC, filename)
        if not os.path.exists(path):
            print(f"  !  Not found, skipping: {filename}")
            continue
        with open(path, "rb") as f:
            profile = plistlib.load(f)
        profile_name = profile.get("name", filename.replace(".terminal", ""))
        window_settings[profile_name] = profile
        print(f"  ✔  Imported: {profile_name}")

    # ── 3. Set DevCLI Dark as default ─────────────────────────
    default_name = "DevCLI Dark"
    if default_name in window_settings:
        prefs["Default Window Settings"] = default_name
        prefs["Startup Window Settings"] = default_name
        print(f"  ✔  Set default profile: {default_name}")

    # ── 4. Write back ─────────────────────────────────────────
    write_terminal_prefs(prefs)
    print("\n  ✔  All profiles imported — no new windows opened!")
    print("  ✔  Old NeoShell profiles cleaned up\n")
    print("  Tip: To switch theme on your CURRENT window:")
    print("       Shell menu → Use Profile → pick a DevCLI theme\n")


if __name__ == "__main__":
    main()
