#!/bin/bash

# 2026-09-30 v1.0
# Ernst Lanser <ernst.lanser@wobbo.org>
# https://github.com/wobbo/chromium-google-sync
# https://forums.raspberrypi.com/viewtopic.php?t=373028#p2233233

set -euo pipefail

# Ask before making changes.
read -r -p "Remove Google services configuration from Chromium? [y/N]: " answer
case "${answer,,}" in
    y|yes) ;;
    *) echo "Removal cancelled."; exit 0 ;;
esac

# Ask for administrator privileges only after confirmation.
if [ "$EUID" -eq 0 ]; then
    SUDO=()
else
    command -v sudo >/dev/null 2>&1 || { echo "ERROR: sudo is not installed."; exit 1; }
    sudo -v
    SUDO=(sudo)
fi

# Stop Chromium before removing configuration.
echo "Stopping Chromium..."
"${SUDO[@]}" pkill -TERM -x chromium 2>/dev/null || true
"${SUDO[@]}" pkill -TERM -x chromium-browser 2>/dev/null || true
sleep 2
"${SUDO[@]}" pkill -KILL -x chromium 2>/dev/null || true
"${SUDO[@]}" pkill -KILL -x chromium-browser 2>/dev/null || true

# Remove only files created by this project.
echo "Removing Chromium Google Sync configuration..."
"${SUDO[@]}" rm -f /etc/chromium.d/zz-google-sync
"${SUDO[@]}" rm -f /etc/chromium.d/zz-google-sync-signin
"${SUDO[@]}" rm -f /etc/chromium/policies/managed/zz-google-signin.json

# Remove empty policy directories only.
"${SUDO[@]}" rmdir /etc/chromium/policies/managed 2>/dev/null || true
"${SUDO[@]}" rmdir /etc/chromium/policies 2>/dev/null || true

echo
echo "Removal complete."
echo "Chromium and user browser data were left untouched."
