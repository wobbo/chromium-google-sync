#!/bin/bash
set -euo pipefail

# 2026-09-30 v1.0
# Ernst Lanser <ernst.lanser@wobbo.org>
# https://github.com/wobbo/chromium-google-sync
# https://forums.raspberrypi.com/viewtopic.php?t=373028#p2233233

# ============================================================
# Chromium Google Services / Sync
# ============================================================
#
# Enables Google account sign-in and Google Sync for native
# Debian-compatible Chromium installations.
#
# Designed for:
#   - Raspberry Pi OS Chromium
#   - Debian Chromium (ARM64 / AMD64)
#   - Other Debian-based systems using /etc/chromium.d
#
# The installer does not replace Chromium package files.
# It adds separate configuration files under /etc.
#
# References:
#   Chromium's public Google OAuth configuration
#   Raspberry Pi forum discussions about Chromium Sync
#
# ============================================================


echo "=================================================="
echo " Chromium Google Services / Sync"
echo "=================================================="
echo
echo "This installer enables Google account sign-in"
echo "and Google Sync in Chromium."
echo
echo "The configuration will apply system-wide"
echo "to all users."
echo
echo "All running Chromium windows will be closed."
echo


# ------------------------------------------------------------
# Ask before doing anything.
# No sudo password is requested until the user chooses Yes.
# ------------------------------------------------------------

read -r -p "Install Google services for Chromium? [y/N]: " answer

case "$answer" in
    y|Y|yes|YES|Yes)
        ;;
    *)
        echo
        echo "Installation cancelled."
        exit 0
        ;;
esac


# ------------------------------------------------------------
# Obtain administrator privileges.
#
# The script is intended to be started normally:
#
#   ./enable-chromium-google-sync.sh
#
# sudo is requested only after the user confirms installation.
#
# Running the whole script with sudo also remains supported.
# ------------------------------------------------------------

echo

if [ "$EUID" -eq 0 ]; then
    SUDO=()
else
    if ! command -v sudo >/dev/null 2>&1; then
        echo "ERROR: sudo is not installed."
        exit 1
    fi

    echo "Administrator privileges are required."
    sudo -v
    SUDO=(sudo)
fi


# ------------------------------------------------------------
# Check that a supported Chromium installation is available.
#
# /etc/chromium.d is used by native Debian/Raspberry Pi
# Chromium packages to load additional startup configuration.
# ------------------------------------------------------------

echo
echo "Checking Chromium installation..."

if ! command -v chromium >/dev/null 2>&1 &&
   ! command -v chromium-browser >/dev/null 2>&1; then
    echo
    echo "ERROR: Chromium is not installed."
    exit 1
fi

if [ ! -d /etc/chromium.d ]; then
    echo
    echo "ERROR: /etc/chromium.d does not exist."
    echo
    echo "This installer requires a native Debian-compatible"
    echo "Chromium installation."
    exit 1
fi

echo "Compatible Chromium installation detected."


# ------------------------------------------------------------
# Check the distribution-provided Google API configuration.
#
# Debian/Raspberry Pi Chromium normally provides:
#
#   /etc/chromium.d/apikeys
#
# We leave this file untouched.
# Our own OAuth values are loaded afterwards.
# ------------------------------------------------------------

if [ -f /etc/chromium.d/apikeys ]; then
    echo "Existing Chromium API configuration detected."
else
    echo
    echo "WARNING:"
    echo "/etc/chromium.d/apikeys was not found."
    echo "Google services may not work correctly on this build."
fi


# ------------------------------------------------------------
# Stop Chromium before changing its configuration.
#
# First request a clean shutdown.
# If processes remain after 10 seconds, stop them forcefully.
# ------------------------------------------------------------

echo
echo "Stopping all running Chromium processes..."

"${SUDO[@]}" pkill -TERM -x chromium 2>/dev/null || true
"${SUDO[@]}" pkill -TERM -f '(^|/)chromium-browser([[:space:]]|$)' 2>/dev/null || true

for i in {1..10}; do
    if ! pgrep -x chromium >/dev/null 2>&1 &&
       ! pgrep -f '(^|/)chromium-browser([[:space:]]|$)' >/dev/null 2>&1; then
        break
    fi

    sleep 1
done

"${SUDO[@]}" pkill -KILL -x chromium 2>/dev/null || true
"${SUDO[@]}" pkill -KILL -f '(^|/)chromium-browser([[:space:]]|$)' 2>/dev/null || true

echo "Chromium stopped."


# ------------------------------------------------------------
# Install Google OAuth configuration.
#
# The distribution-provided "apikeys" file is NOT modified.
#
# Because files in /etc/chromium.d are processed by name,
# "zz-google-sync" loads after the standard "apikeys" file.
#
# This lets us override only the OAuth client values needed
# for Google account sign-in and Sync.
# ------------------------------------------------------------

echo
echo "Installing Google OAuth configuration..."

cat <<'EOF' | "${SUDO[@]}" tee /etc/chromium.d/zz-google-sync >/dev/null
# Google account sign-in and Sync for Chromium.
#
# This file is loaded after the distribution-provided
# /etc/chromium.d/apikeys configuration.

export GOOGLE_DEFAULT_CLIENT_ID="77185425430.apps.googleusercontent.com"
export GOOGLE_DEFAULT_CLIENT_SECRET="OTJgUOQcT7lO7GsGZq2G4IlT"
EOF

"${SUDO[@]}" chmod 644 /etc/chromium.d/zz-google-sync


# ------------------------------------------------------------
# Enable Chromium browser sign-in system-wide.
#
# BrowserSignin = 1 means:
#
#   Browser sign-in is allowed.
#
# It does NOT force users to sign in.
#
# Because this is a machine policy, it applies to existing
# users as well as users created later.
# ------------------------------------------------------------

echo "Installing system-wide Chromium sign-in policy..."

"${SUDO[@]}" mkdir -p /etc/chromium/policies/managed


# Remove policy filenames used by earlier versions/tests.
# This prevents the same BrowserSignin policy being defined
# multiple times under different filenames.

"${SUDO[@]}" rm -f \
    /etc/chromium/policies/managed/google-signin.json \
    /etc/chromium/policies/managed/99-google-signin.json


cat <<'EOF' | "${SUDO[@]}" tee /etc/chromium/policies/managed/zz-google-signin.json >/dev/null
{
  "BrowserSignin": 1
}
EOF

"${SUDO[@]}" chmod 644 \
    /etc/chromium/policies/managed/zz-google-signin.json


# ------------------------------------------------------------
# Install profile compatibility support.
#
# Some Chromium versions store an additional per-profile
# sign-in setting in:
#
#   ~/.config/chromium/<profile>/Preferences
#
# This script runs in the context of the user who starts
# Chromium and makes sure sign-in remains enabled.
#
# $HOME therefore automatically refers to the correct user.
# Multiple Chromium profiles are supported.
# ------------------------------------------------------------

echo "Installing Chromium profile compatibility support..."

cat <<'EOF' | "${SUDO[@]}" tee /etc/chromium.d/zz-google-sync-signin >/dev/null
# Keep Chromium profile sign-in enabled.

python3 - <<'PY'
import json
import os

base = os.path.expanduser("~/.config/chromium")

# A completely new user may not have a Chromium profile yet.
# In that case there is nothing to change during this launch.
if not os.path.isdir(base):
    raise SystemExit

profiles = [
    name
    for name in os.listdir(base)
    if name == "Default" or name.startswith("Profile ")
]

for profile in profiles:
    filename = os.path.join(base, profile, "Preferences")

    if not os.path.isfile(filename):
        continue

    try:
        with open(filename, "r", encoding="utf-8") as file:
            prefs = json.load(file)

        signin = prefs.setdefault("signin", {})

        signin["allowed"] = True
        signin["allowed_on_next_startup"] = True

        with open(filename, "w", encoding="utf-8") as file:
            json.dump(
                prefs,
                file,
                separators=(",", ":")
            )

    except Exception as error:
        print(
            f"Chromium Google Sync: "
            f"could not update {filename}: {error}"
        )
PY
EOF

"${SUDO[@]}" chmod 644 \
    /etc/chromium.d/zz-google-sync-signin


# ------------------------------------------------------------
# Installation finished.
#
# The installed files are separate from Chromium's package
# files, so normal Chromium package upgrades should leave
# them untouched.
# ------------------------------------------------------------

echo
echo "=================================================="
echo " Installation complete"
echo "=================================================="
echo
echo "Installed:"
echo
echo "  /etc/chromium.d/zz-google-sync"
echo "  /etc/chromium.d/zz-google-sync-signin"
echo "  /etc/chromium/policies/managed/zz-google-signin.json"
echo
echo "Google account sign-in and Google Sync are now"
echo "enabled system-wide for Chromium users."
echo
echo "Start Chromium and sign in with your Google account."
echo
echo "To verify the machine policy, open:"
echo
echo "  chrome://policy"
echo
echo "BrowserSignin should show:"
echo "  Value: 1"
echo "  Scope: Machine"
echo "  Status: OK"
echo
