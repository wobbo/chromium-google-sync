#!/bin/bash
# 2026-09-30 v1.0
# Ernst Lanser <ernst.lanser@wobbo.org>
# https://github.com/wobbo/chromium-google-sync
# https://forums.raspberrypi.com/viewtopic.php?t=373028#p2233233

set -euo pipefail

# Ask before making changes.
read -r -p "Install Google services for Chromium? [y/N]: " answer
case "${answer,,}" in
    y|yes) ;;
    *) echo "Installation cancelled."; exit 0 ;;
esac

# Check required tools and Chromium layout.
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 is required."; exit 1; }

if command -v chromium >/dev/null 2>&1; then
    CHROMIUM_BIN="$(command -v chromium)"
elif command -v chromium-browser >/dev/null 2>&1; then
    CHROMIUM_BIN="$(command -v chromium-browser)"
else
    echo "ERROR: Chromium is not installed."
    exit 1
fi

[ -d /etc/chromium.d ] || {
    echo "ERROR: /etc/chromium.d does not exist."
    exit 1
}

CHROMIUM_REAL="$(readlink -f "$CHROMIUM_BIN" 2>/dev/null || printf '%s' "$CHROMIUM_BIN")"
case "$CHROMIUM_REAL" in
    /snap/*)
        echo "ERROR: Chromium Snap is not supported."
        exit 1
        ;;
esac

# Ask for administrator privileges only after confirmation.
if [ "$EUID" -eq 0 ]; then
    SUDO=()
else
    command -v sudo >/dev/null 2>&1 || { echo "ERROR: sudo is not installed."; exit 1; }
    sudo -v
    SUDO=(sudo)
fi

# Stop Chromium before changing configuration.
echo "Stopping Chromium..."
"${SUDO[@]}" pkill -TERM -x chromium 2>/dev/null || true
"${SUDO[@]}" pkill -TERM -x chromium-browser 2>/dev/null || true
sleep 2
"${SUDO[@]}" pkill -KILL -x chromium 2>/dev/null || true
"${SUDO[@]}" pkill -KILL -x chromium-browser 2>/dev/null || true

# Add Google OAuth values without changing the distro apikeys file.
echo "Installing Google OAuth configuration..."
cat <<'EOF' | "${SUDO[@]}" tee /etc/chromium.d/zz-google-sync >/dev/null
export GOOGLE_DEFAULT_CLIENT_ID="77185425430.apps.googleusercontent.com"
export GOOGLE_DEFAULT_CLIENT_SECRET="OTJgUOQcT7lO7GsGZq2G4IlT"
EOF
"${SUDO[@]}" chmod 644 /etc/chromium.d/zz-google-sync

# Allow browser sign-in system-wide.
echo "Installing Chromium sign-in policy..."
"${SUDO[@]}" mkdir -p /etc/chromium/policies/managed
cat <<'EOF' | "${SUDO[@]}" tee /etc/chromium/policies/managed/zz-google-signin.json >/dev/null
{
  "BrowserSignin": 1
}
EOF
"${SUDO[@]}" chmod 644 /etc/chromium/policies/managed/zz-google-signin.json

# Keep existing Chromium profiles sign-in enabled.
echo "Installing profile compatibility support..."
cat <<'EOF' | "${SUDO[@]}" tee /etc/chromium.d/zz-google-sync-signin >/dev/null
python3 - <<'PY'
import json
import os

base = os.path.expanduser("~/.config/chromium")
if not os.path.isdir(base):
    raise SystemExit

profiles = [n for n in os.listdir(base) if n == "Default" or n.startswith("Profile ")]

for profile in profiles:
    filename = os.path.join(base, profile, "Preferences")
    if not os.path.isfile(filename):
        continue
    try:
        with open(filename, "r", encoding="utf-8") as f:
            prefs = json.load(f)
        signin = prefs.setdefault("signin", {})
        signin["allowed"] = True
        signin["allowed_on_next_startup"] = True
        with open(filename, "w", encoding="utf-8") as f:
            json.dump(prefs, f, separators=(",", ":"))
    except Exception as error:
        print(f"Chromium Google Sync: could not update {filename}: {error}")
PY
EOF
"${SUDO[@]}" chmod 644 /etc/chromium.d/zz-google-sync-signin

echo
echo "Installation complete."
echo "Open chrome://policy and check BrowserSignin = 1."
