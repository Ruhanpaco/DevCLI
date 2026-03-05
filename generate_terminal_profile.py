#!/usr/bin/env python3
"""
DevCLI – Terminal Profile Generator
Generates all DevCLI .terminal profiles for macOS Terminal.app.
Run: python3 generate_terminal_profile.py
"""

import plistlib
import os

SRC = os.path.join(os.path.dirname(__file__), "src")


def make_nscolor(r: float, g: float, b: float, a: float = 1.0) -> bytes:
    """Return a binary-plist NSKeyedArchiver NSColor blob (DeviceRGB)."""
    components_str = f"{r:.10f} {g:.10f} {b:.10f} {a:.10f}"
    data = {
        "$version": 100000,
        "$archiver": "NSKeyedArchiver",
        "$top": {"root": plistlib.UID(1)},
        "$objects": [
            "$null",
            {
                "NSColorSpace": 1,
                "NSComponents": components_str,
                "$class": plistlib.UID(2),
            },
            {
                "$classname": "NSColor",
                "$classes": ["NSColor", "NSObject"],
            },
        ],
    }
    return plistlib.dumps(data, fmt=plistlib.FMT_BINARY)


# ── Shared ANSI palette ────────────────────────────────────────────────────────
ANSI = {
    "ANSIBlackColor":          make_nscolor(0.0,   0.0,   0.0),
    "ANSIRedColor":            make_nscolor(0.800, 0.000, 0.000),
    "ANSIGreenColor":          make_nscolor(0.204, 0.773, 0.361),
    "ANSIYellowColor":         make_nscolor(0.992, 0.737, 0.000),
    "ANSIBlueColor":           make_nscolor(0.000, 0.478, 0.800),
    "ANSIMagentaColor":        make_nscolor(0.686, 0.373, 0.820),
    "ANSICyanColor":           make_nscolor(0.000, 0.749, 0.800),
    "ANSIWhiteColor":          make_nscolor(0.733, 0.733, 0.733),
    "ANSIBrightBlackColor":    make_nscolor(0.267, 0.267, 0.267),
    "ANSIBrightRedColor":      make_nscolor(1.000, 0.298, 0.298),
    "ANSIBrightGreenColor":    make_nscolor(0.384, 0.957, 0.514),
    "ANSIBrightYellowColor":   make_nscolor(1.000, 0.918, 0.231),
    "ANSIBrightBlueColor":     make_nscolor(0.259, 0.631, 1.000),
    "ANSIBrightMagentaColor":  make_nscolor(0.847, 0.518, 1.000),
    "ANSIBrightCyanColor":     make_nscolor(0.000, 1.000, 1.000),
    "ANSIBrightWhiteColor":    make_nscolor(1.000, 1.000, 1.000),
}

def base_profile(name: str, extra: dict) -> dict:
    p = {
        "name": name,
        "type": "Window Settings",
        "columnCount": 220,
        "rowCount": 50,
        "FontAntialias": True,
        "CursorBlink": False,
        "CursorType": 0,
        "UseBoldFonts": True,
        "UseOptionAsMetaKey": True,
        "BackgroundBlur": 0.0,
        "TerminalType": "xterm-256color",
        "Bell": False,
        "VisualBell": False,
        "WindowTitle": "DevCLI",
        **ANSI,
    }
    p.update(extra)
    return p


def write_profile(name: str, profile: dict) -> None:
    path = os.path.join(SRC, f"{name}.terminal")
    with open(path, "wb") as f:
        plistlib.dump(profile, f, fmt=plistlib.FMT_XML)
    print(f"  ✔ {path}")


# 1. DevCLI Dark
write_profile("DevCLI-Dark", base_profile("DevCLI Dark", {
    "BackgroundColor": make_nscolor(0.051, 0.067, 0.090),
    "TextColor":       make_nscolor(0.886, 0.910, 0.941),
    "TextBoldColor":   make_nscolor(1.000, 1.000, 1.000),
    "CursorColor":     make_nscolor(0.000, 0.898, 1.000),
    "SelectionColor":  make_nscolor(0.118, 0.227, 0.373),
}))

# 2. DevCLI Glass (75% transparent + frosted blur)
write_profile("DevCLI-Glass", base_profile("DevCLI Glass", {
    "BackgroundColor": make_nscolor(0.051, 0.067, 0.090, 0.25),
    "TextColor":       make_nscolor(0.950, 0.975, 1.000),
    "TextBoldColor":   make_nscolor(1.000, 1.000, 1.000),
    "CursorColor":     make_nscolor(0.000, 0.898, 1.000),
    "SelectionColor":  make_nscolor(0.118, 0.227, 0.373, 0.70),
    "BackgroundBlur":  0.82,
}))

# 3. DevCLI Abyss (pure black)
write_profile("DevCLI-Abyss", base_profile("DevCLI Abyss", {
    "BackgroundColor": make_nscolor(0.000, 0.000, 0.000),
    "TextColor":       make_nscolor(0.800, 0.800, 0.800),
    "TextBoldColor":   make_nscolor(1.000, 1.000, 1.000),
    "CursorColor":     make_nscolor(0.000, 0.898, 1.000),
    "SelectionColor":  make_nscolor(0.150, 0.150, 0.150),
}))

# 4. DevCLI Ghost (white / light mode)
ANSI_GHOST = {**ANSI,
    "ANSIBrightWhiteColor":  make_nscolor(0.80, 0.80, 0.80),
    "ANSICyanColor":          make_nscolor(0.000, 0.500, 0.600),
    "ANSIBrightCyanColor":    make_nscolor(0.000, 0.600, 0.700),
    "ANSIBlueColor":          make_nscolor(0.000, 0.340, 0.650),
    "ANSIBrightBlueColor":    make_nscolor(0.000, 0.400, 0.750),
    "ANSIGreenColor":         make_nscolor(0.100, 0.500, 0.200),
    "ANSIBrightGreenColor":   make_nscolor(0.100, 0.600, 0.250),
    "ANSIMagentaColor":       make_nscolor(0.550, 0.100, 0.650),
    "ANSIBrightMagentaColor": make_nscolor(0.650, 0.200, 0.750),
    "ANSIWhiteColor":         make_nscolor(0.400, 0.400, 0.400),
}
ghost = base_profile("DevCLI Ghost", {
    "BackgroundColor": make_nscolor(0.980, 0.980, 0.985),
    "TextColor":       make_nscolor(0.100, 0.100, 0.140),
    "TextBoldColor":   make_nscolor(0.000, 0.000, 0.000),
    "CursorColor":     make_nscolor(0.000, 0.500, 0.800),
    "SelectionColor":  make_nscolor(0.780, 0.860, 0.950),
})
ghost.update(ANSI_GHOST)
write_profile("DevCLI-Ghost", ghost)

print("\nAll profiles generated in src/")
