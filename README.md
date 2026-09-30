# Chromium Google Sync

Enable Google account sign-in and Google Sync in native Debian-compatible Chromium without replacing Chromium or installing an extra app manager.

The installer keeps the distribution-provided Chromium files intact and adds its own clearly named configuration files under `/etc`.

## What it does

The installer:

- checks for a native Debian-compatible Chromium installation;
- asks for confirmation before making changes;
- requests `sudo` only after you choose to install;
- closes running Chromium processes before changing the configuration;
- leaves the distribution-provided `/etc/chromium.d/apikeys` file untouched;
- adds Google OAuth client values in a later-loaded `zz-` configuration file;
- enables browser sign-in system-wide with Chromium's `BrowserSignin` policy;
- adds compatibility support for existing Chromium profiles;
- applies the configuration system-wide, including users created later.

It installs these files:

```text
/etc/chromium.d/zz-google-sync
/etc/chromium.d/zz-google-sync-signin
/etc/chromium/policies/managed/zz-google-signin.json
```

The `zz-` prefix is intentional. Files in `/etc/chromium.d/` are loaded by name, so the Google Sync override is loaded after the distribution-provided `apikeys` configuration.

## Supported systems

### Tested

- Raspberry Pi OS / Debian 13 (Trixie) ARM64
- Native Raspberry Pi Chromium
- GNOME desktop

### Expected to work

The same method should work with native Debian-packaged Chromium on other architectures, including AMD64, when these are present:

```text
chromium
/etc/chromium.d/
```

The installer checks for these before making changes.

### Not intended for

- Ubuntu Chromium installed as a Snap
- Flatpak Chromium
- Google Chrome
- Chromium packages that do not use `/etc/chromium.d/`

GNOME itself is not required. The configuration is for Chromium, not the desktop environment.

## Install

Clone the repository:

```bash
git clone https://github.com/wobbo/chromium-google-sync.git
cd chromium-google-sync
chmod +x enable-chromium-google-sync remove-chromium-google-sync
./enable-chromium-google-sync
```

The scripts intentionally have no filename extension. On Linux that is perfectly normal for executable scripts and keeps the commands short.

Start the installer **without** `sudo`.

It first asks:

```text
Install Google services for Chromium? [y/N]:
```

Only after choosing `y` does it request administrator privileges.

After installation, start Chromium and sign in with your Google account.

To check the system-wide policy, open:

```text
chrome://policy
```

`BrowserSignin` should show value `1`, machine scope, and status OK.

## Remove

Run:

```bash
./remove-chromium-google-sync
```

The remover deletes only the configuration files installed by this project.

It does **not** remove:

- Chromium;
- Chromium user profiles;
- bookmarks;
- passwords;
- browsing data.

## Why separate `zz-` files?

A common approach is to edit or replace Chromium's existing API configuration. This project deliberately avoids that.

The distribution file remains:

```text
/etc/chromium.d/apikeys
```

This project adds:

```text
/etc/chromium.d/zz-google-sync
```

That keeps the custom configuration separate from files owned by the Chromium package, makes the change easy to identify, and makes removal straightforward.

## Notes

Google can change Chromium sign-in and Sync requirements in future Chromium releases. A Chromium update should normally leave these separate files under `/etc` untouched, but a future browser change can still require an update to this project.

The OAuth client values used here are application credentials used by Chromium-based setups. They are not credentials for your personal Google account.

## References and prior work

This project was built from testing on Raspberry Pi Chromium and from public Chromium mechanisms and community research.

Useful technical references and prior work:

- [Chromium API keys documentation](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/api_keys.md)
- [Chromium enterprise policies](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/enterprise/policies.md)
- [Raspberry Pi forum discussion: Chromium / Google Sync](https://forums.raspberrypi.com/viewtopic.php?t=399940)
- [Earlier Raspberry Pi forum discussion](https://forums.raspberrypi.com/viewtopic.php?t=395269)
- [Better Chromium in Pi-Apps](https://github.com/Botspot/pi-apps/tree/master/apps/Better%20Chromium)

This repository uses its own installer structure and does not require Pi-Apps or Better Chromium.
