# DNS Switcher

A macOS menu bar utility for quickly switching DNS server settings across named profiles.

> **Fork notice:** This is a maintained fork of [mattmcneeney/DNSSwitcher](https://github.com/mattmcneeney/DNSSwitcher), originally created by [Matt McNeeney](https://github.com/mattmcneeney) in 2016. Full credit to Matt for the original concept, architecture, and implementation. This fork modernizes the project for Apple Silicon and applies security hardening; the core design is unchanged.

---

## What it does

DNS Switcher lives in the macOS menu bar. Click the icon, pick a profile, and your DNS servers switch instantly via `networksetup`. No Terminal required.

![DNS Switcher screenshot 1](Docs/Screenshot1.jpg) ![DNS Switcher screenshot 2](Docs/Screenshot2.jpg)

---

## What this fork adds

### Apple Silicon / Swift 5 modernization (2026)

The original binary was Intel-only (x86_64), built with Xcode 7.3.1, Swift 2, and CocoaPods 0.39.0. This fork:

- **Universal binary** — compiles for `arm64 + x86_64`; runs natively on Apple Silicon with no Rosetta layer
- **Swift 5 migration** — all four source files updated from Swift 2 syntax (`NSTask`, `NSPipe`, `NSBundle`, `componentsSeparatedByString`, etc.) to Swift 5/6 equivalents
- **CocoaPods 1.16.2** — updated from 0.39.0; `pod install` resolves cleanly
- **SwiftyJSON 5.x** — updated from the git-commit-pinned 2.3.2 snapshot to a semver range; `arm64` framework verified with `lipo`
- **Deployment target: macOS 12.0** (Monterey) — raised from macOS 10.11 (El Capitan)

### Security hardening (2026)

Identified and fixed by a `deepsec` security scan:

- **Removed `load_cmd` execution (HIGH)** — the original config format supported a `load_cmd` string that was split on spaces and executed via `Process()` with no validation. Any process able to write `~/.dnsswitcher.json` could achieve arbitrary code execution as the logged-in user on the next menu click. The feature has been removed entirely; DNS switching has no legitimate need for pre-flight shell hooks.
- **Symlink guard on config restore (MEDIUM)** — "Restore Default Servers" now checks whether `~/.dnsswitcher.json` is a symlink before writing; if it is, the write is aborted rather than silently overwriting the symlink target.
- **Crash guard on empty interface list (BUG)** — the failover path in interface selection now checks that the interface list is non-empty before accessing `items[0]`, preventing a startup crash on VMs or machines with only disabled network services.
- **`stderr` captured in `runCommand` (BUG)** — `networksetup` writes diagnostics to stderr; error alert dialogs now show the actual error message instead of a blank body.

---

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode 16.x (for building from source)
- CocoaPods 1.x

---

## Building from source

```bash
# Install dependencies
pod install

# Open the workspace (not the .xcodeproj)
open DNSSwitcher.xcworkspace
```

Build and run with **⌘R**. The app appears in the menu bar.

---

## Configuration

DNS Switcher reads `~/.dnsswitcher.json`. The file is created automatically on first launch using the bundled default. Edit it directly (menu bar → **Edit Servers…**) or open it in any text editor.

### Format

```json
{
  "interface": "Wi-Fi",
  "settings": [
    {
      "name": "Google",
      "servers": ["8.8.8.8", "8.8.4.4"]
    },
    {
      "name": "Cloudflare",
      "servers": ["1.1.1.1", "1.0.0.1"]
    },
    {
      "name": "Custom",
      "servers": ["192.168.1.1"]
    }
  ]
}
```

| Field | Type | Description |
|---|---|---|
| `interface` | string | Network interface to configure (e.g. `"Wi-Fi"`, `"Ethernet"`) |
| `settings[].name` | string | Display name shown in the menu |
| `settings[].servers` | string[] | One or more DNS server IP addresses |

The active interface can also be changed from the menu bar without editing the file.

> **Note:** The `load_cmd` field supported by the original project has been removed in this fork. See [Security hardening](#security-hardening-2026) above.

---

## Original project

- **Author:** [Matt McNeeney](https://github.com/mattmcneeney)
- **Original repo:** [github.com/mattmcneeney/DNSSwitcher](https://github.com/mattmcneeney/DNSSwitcher)
- **Original documentation site:** [mattmcneeney.github.io/DNSSwitcher](http://mattmcneeney.github.io/DNSSwitcher/)
- **License:** See the original repository for license terms.
