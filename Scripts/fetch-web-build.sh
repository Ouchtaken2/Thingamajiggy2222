#!/usr/bin/env bash
set -euo pipefail

# Downloads the publicly served GameMaker HTML5 build of Frickbear's 3
# into the Game/ folder that gets bundled into the iOS app.
#
# IMPORTANT: This fetches third-party fan-game assets. Use for personal,
# non-commercial purposes only and keep the credits in CREDITS.md intact.

BASE="https://cdn.gachaplay.online/games/frickbears-3"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/Game"

mkdir -p "$DEST"

echo "==> Downloading index.html"
curl -fsSL "$BASE/index.html" -o "$DEST/index.html"

echo "==> Resolving file list from manifestFiles()"
python3 - "$DEST/index.html" "$BASE" "$DEST" <<'PY'
import os
import re
import sys
import urllib.request

index_path, base, dest = sys.argv[1], sys.argv[2], sys.argv[3]

with open(index_path, "r", encoding="utf-8") as handle:
    html = handle.read()

match = re.search(
    r"function\s+manifestFiles\s*\(\s*\)\s*\{.*?return\s*\[(.*?)\]\s*\.join",
    html,
    re.S,
)
files = re.findall(r'"([^"]+)"', match.group(1)) if match else []

# Files referenced directly by index.html but not in manifestFiles().
files += [
    "index.html",
    "manifest.webmanifest",
    "icon-192.png",
    "runner.svg",
]

# Preserve order, remove duplicates.
files = list(dict.fromkeys(files))

if not files:
    raise SystemExit("Could not parse file list - check the CDN build layout.")

for name in files:
    name = name.strip()
    if not name:
        continue
    out = os.path.join(dest, name)
    if os.path.exists(out) and os.path.getsize(out) > 0:
        print("    skip    %s" % name)
        continue
    url = "%s/%s" % (base, name)
    print("    fetch   %s" % name)
    urllib.request.urlretrieve(url, out)

total = sum(
    os.path.getsize(os.path.join(dest, f))
    for f in os.listdir(dest)
    if os.path.isfile(os.path.join(dest, f))
)
print("==> Done. Game bundle size: %.1f MB" % (total / 1024 / 1024))
PY
