# Sideloading this fork with a free Apple Developer account

> For what this fork changes beyond sideloading, see
> [FORK_CHANGES.md](FORK_CHANGES.md).

Upstream Blink is built for a paid Apple Developer Program account. A free
"Personal Team" cannot sign several of the capabilities upstream depends on, so
this fork carries the minimum set of changes needed to build, install and run on
a personal device at no cost.

Everything here is a local-install concern. None of it is worth sending upstream.

## One-time setup

```bash
./get_frameworks.sh          # prebuilt libssh2, OpenSSL, libmoshios, protobuf, ios_system
./get_resources.sh           # vim runtime
cp template_setup.xcconfig developer_setup.xcconfig
```

Edit `developer_setup.xcconfig`:

```
TEAM_ID   = <your 10-character Personal Team id>
BUNDLE_ID = <your own reverse-dns id>
GROUP_ID  = <your own reverse-dns prefix>
```

Find the team id from your signing certificate:

```bash
security find-certificate -c "Apple Development: <your apple id>" -p \
  | openssl x509 -noout -subject
# OU=<TEAM_ID>
```

Xcode must be signed in under **Settings > Accounts**, and the device needs
**Developer Mode** on (Settings > Privacy & Security).

## Build and install

```bash
./scripts/sideload.sh
```

Then trust the certificate on the device, once per certificate:
**Settings > General > VPN & Device Management**.

## The 7-day clock

A Personal Team provisioning profile expires after 7 days. The app stops
launching when it does. Re-run `./scripts/sideload.sh`; it reissues the profile,
rebuilds and reinstalls. App data is preserved across reinstalls.

Other Personal Team limits: 3 sideloaded apps on a device at a time, 10 App IDs
per 7 days, 100 devices per year.

## What was changed, and why

| Change | Reason |
|---|---|
| `Blink/Blink.entitlements` | Removed push, iCloud/CloudKit, app groups, associated domains, web-browser, user-fonts, keychain sharing. A Personal Team cannot sign any of them. |
| `BlinkFileProviderExtension/…entitlements` | Same, for the extension. |
| `Blink.xcodeproj/project.pbxproj` | Unlinked `StoreKit.framework` and disabled the Push, iCloud, Keychain and DataProtection system capabilities. Linking StoreKit makes Xcode request the In-App Purchase service on the App ID, which a Personal Team is refused. |
| `BlinkConfig/BlinkPaths.m` | `groupContainerPath` falls back to the app's own container when there is no app group. Blink keeps its entire home directory there, so without this nothing resolves. `iCloudDriveDocuments` returns nil instead of building a path from a nil ubiquity container, and `linkICloudDriveIfNeeded` skips the symlink when it does. |
| `Blink/VoiceInput.swift`, `Blink/Terminal/TermView.*` | Push-to-talk voice input, unrelated to signing. See [FORK_CHANGES.md](FORK_CHANGES.md). |
| `Blink/Migrator/1810Migration.swift` | Skipped `deleteFileProviderStorage()`. `NSFileProviderManager.default.documentStorageURL` raises an Objective-C assertion when no File Provider is provisioned, and that cannot be caught from Swift. Also skipped the iCloud reachability sync beside it. |

## What you lose

Push notifications, iCloud settings sync, in-app purchase, and the Files.app
File Provider integration.

Terminal, SSH, mosh, keys, themes, vim, tmux, splits, tabs, hardware keyboard
and gestures are unaffected.

## Restoring the upstream behaviour

The full history is in git. On a paid account, revert the commit that
introduced these changes and build normally.
