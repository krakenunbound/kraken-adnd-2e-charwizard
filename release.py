#!/usr/bin/env python3
"""Build and publish a GitHub Release for the Kraken AD&D 2E Character Wizard.

Rebuilds KrakenCharWizard2E.ext from the extension source and creates (or
updates) a GitHub Release with it attached as a downloadable asset.

Usage:
    python release.py                 # tag = "v" + version from extension.xml
    python release.py v1.0-beta2      # explicit tag
    python release.py v1.0-beta2 --notes "Fixed coins + weapon names."

Requires: git, the GitHub CLI (`gh`) authenticated, and Python 3.
Run it from inside the repo (the live extension folder).
"""
import os, sys, zipfile, shutil, subprocess
import xml.etree.ElementTree as ET

REPO    = os.path.dirname(os.path.abspath(__file__))
FG      = os.path.abspath(os.path.join(REPO, "..", ".."))            # Fantasy Grounds data dir
BUILD   = os.path.join(REPO, "build")

# Only these go into the .ext (everything FGU needs, nothing else).
INCLUDE      = ["extension.xml", "charwizard", "graphics", "strings"]
EXCLUDE_DIRS = {"race_backup_20260531"}   # unused backup art


def version():
    r = ET.parse(os.path.join(REPO, "extension.xml")).getroot()
    return r.findtext("properties/version") or r.get("version") or "0.0.0"


def build_ext(dest):
    n = 0
    with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as z:
        for item in INCLUDE:
            p = os.path.join(REPO, item)
            if os.path.isfile(p):
                z.write(p, item); n += 1
            elif os.path.isdir(p):
                for root, dirs, files in os.walk(p):
                    dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
                    for f in files:
                        full = os.path.join(root, f)
                        rel = os.path.relpath(full, REPO).replace("\\", "/")
                        z.write(full, rel); n += 1
    with zipfile.ZipFile(dest) as z:                 # sanity: loadable shape
        assert "extension.xml" in z.namelist(), "extension.xml not at .ext root"
    return n


def main():
    args = list(sys.argv[1:])
    notes = None
    if "--notes" in args:
        i = args.index("--notes"); notes = args[i + 1]; del args[i:i + 2]
    tag = args[0] if args else ("v" + version())

    os.makedirs(BUILD, exist_ok=True)
    ext_out = os.path.join(BUILD, "KrakenCharWizard2E.ext")
    n = build_ext(ext_out)
    print(f"[build] {os.path.basename(ext_out)}  ({n} files, {os.path.getsize(ext_out)/1e6:.1f} MB)")

    # The extension only: it reads the official 2E books. (The Drowned Archive is
    # Kraken's own games' module, not part of the wizard's release.)
    assets = [ext_out]

    title = f"Kraken AD&D 2E Character Wizard {tag}"
    if not notes:
        notes = (f"{title}\n\n"
                 "Install: KrakenCharWizard2E.ext -> Fantasy Grounds \\extensions\\. "
                 "Requires FGU + the AD&D 2E ruleset + the 2E Player's Handbook module "
                 "(other official 2E books are used when loaded).")

    exists = subprocess.run(["gh", "release", "view", tag], cwd=REPO,
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
    if exists:
        print(f"[gh] release {tag} exists -> uploading assets (--clobber)")
        subprocess.run(["gh", "release", "upload", tag, *assets, "--clobber"], cwd=REPO, check=True)
    else:
        print(f"[gh] creating release {tag}")
        subprocess.run(["gh", "release", "create", tag, *assets, "--title", title, "--notes", notes],
                       cwd=REPO, check=True)
    print("[done]", tag)


if __name__ == "__main__":
    main()
