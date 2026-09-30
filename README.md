# Chromium Google Sync

**Version 1.0 — 2026-09-30**

Enable Google account sign-in and Google Sync in native Debian-compatible Chromium without replacing Chromium or installing an extra app manager.

This project keeps the distribution-provided Chromium files intact and adds its own configuration under `/etc`.

## What it installs

```text
/etc/chromium.d/zz-google-sync
/etc/chromium.d/zz-google-sync-signin
/etc/chromium/policies/managed/zz-google-signin.json
```

The `zz-` prefix is intentional. The custom files are loaded after the distribution-provided Chromium configuration, while package-owned files remain untouched.

## Install

```bash
git clone https://github.com/wobbo/chromium-google-sync.git
cd chromium-google-sync
chmod +x enable-chromium-google-sync remove-chromium-google-sync
./enable-chromium-google-sync
```

Start the installer without `sudo`. It asks for confirmation first and only then requests administrator privileges.

## Remove

```bash
./remove-chromium-google-sync
```

The remover deletes only the configuration installed by this project. Chromium itself and user browser data remain untouched.

## Supported systems

Tested on Raspberry Pi OS / Debian 13 (Trixie) ARM64 with native Raspberry Pi Chromium and GNOME.

The same method is intended for native Debian-compatible Chromium installations that use `/etc/chromium.d/`.

Not intended for Chromium Snap, Flatpak Chromium, Google Chrome, or Chromium packages that do not use `/etc/chromium.d/`.

## References

- https://github.com/wobbo/chromium-google-sync
- https://forums.raspberrypi.com/viewtopic.php?t=373028#p2233233
- https://forums.raspberrypi.com/viewtopic.php?t=399940
- https://forums.raspberrypi.com/viewtopic.php?t=395269
- https://chromium.googlesource.com/chromium/src/+/HEAD/docs/api_keys.md
- https://chromium.googlesource.com/chromium/src/+/HEAD/docs/enterprise/policies.md
