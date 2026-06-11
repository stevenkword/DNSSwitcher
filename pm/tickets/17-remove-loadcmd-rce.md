STATUS: done
COMPLETED: 2026-06-11 | commit: 2cf634b
COMMITS: 2cf634b

TICKET 17: Remove loadCmd Arbitrary Code Execution
Milestone: Security Hardening
Domain: security
Priority: P0 — HIGH-severity RCE; any local write to ~/.dnsswitcher.json yields arbitrary code execution as the logged-in user
Effort: S
PRD: N/A (deepsec scan finding) | Blockers: none

## HANDOFF BLOCK

**Source:** deepsec scan — finding `rce`, confirmed true-positive by revalidation pass.
**File:** `.deepsec/.deepsec/findings/HIGH/DNSSwitcher-rce-61d09edfb9.md`
**Why:** `SettingItem.loadCmd` is a free-form string read from `~/.dnsswitcher.json`, split on spaces, and passed directly to `Process()`. Any process with write access to the config file — malware, a compromised download, a symlink race winner — can inject an arbitrary executable and have it run as the logged-in user on the next menu click. The feature itself is the attack surface; there is no fence around it.

## DESCRIPTION

The `load_cmd` JSON field allowed users to specify a shell command to run before switching DNS servers. The implementation split the string on spaces and passed the result to `runCommand()`, which calls `Process()` with `launchPath = "/usr/bin/env"` — no allowlist, no path validation, no argument sanitization. Chosen fix: remove the feature entirely. DNS switching has no legitimate need for pre-flight shell hooks, and the hardening path (array schema, allowlist, confirmation dialog) adds complexity with no security boundary that can't be trivially bypassed by a local attacker.

## ACCEPTANCE CRITERIA

- [x] `SettingItem.loadCmd` property removed
- [x] `self.loadCmd = json["load_cmd"].string` removed from `SettingItem.init(json:)`
- [x] `load_cmd` export removed from `SettingItem.export()`
- [x] `if let loadCmd = item.setting.loadCmd { ... }` block removed from `AppDelegate.setDNSServers(_:)`
- [x] No references to `loadCmd` or `load_cmd` remain in any Swift source file

## DEFERRED SCOPE

If a pre-flight hook capability is ever reintroduced: require an array of strings in the JSON (not a raw command string), validate the first element is an absolute path to an allowlisted binary under a dedicated hooks directory, and show a one-time confirmation dialog storing a hash of the approved command. This is a significant feature with a non-trivial security surface — do not add it without a full design review.

## DEPENDENCIES

None.

## VERIFICATION

1. `grep -r "loadCmd\|load_cmd" DNSSwitcher/` — must return zero results in Swift files
2. Open `DNSSwitcher/DNSSwitcher/SettingItem.swift` — `loadCmd` property and `json["load_cmd"]` parse are absent
3. Open `DNSSwitcher/DNSSwitcher/AppDelegate.swift` — `setDNSServers` contains no `loadCmd` guard block
4. Build the project in Xcode — zero compile errors related to removed symbol
5. [Regression guard] `AppDelegate.setDNSServers` still constructs the `networksetup -setdnsservers` command and calls `runCommand` — core DNS switching functionality intact

## RESOLUTION

Removed the `loadCmd` feature entirely from two files:

- `DNSSwitcher/DNSSwitcher/SettingItem.swift` — deleted `loadCmd: String?` property, `self.loadCmd = json["load_cmd"].string` from `init`, and the `if let loadCmd` export guard
- `DNSSwitcher/DNSSwitcher/AppDelegate.swift` — deleted the entire `if let loadCmd = item.setting.loadCmd { ... }` block (9 lines) from `setDNSServers(_:)`

Commit: pending

## SESSION AUDIT
Captured: 2026-06-11

### Decisions Made
- [D1] Chose to remove `loadCmd` entirely rather than harden it — owner asked for recommendation; recommendation was removal; owner accepted.

### Clarifications Provided
- [C1] Two options were presented: (a) remove the feature, (b) harden with array schema + allowlist + confirmation dialog. Owner deferred to recommendation (remove).

### Scope Changes
- [S1] Removed: `load_cmd` JSON field support across `SettingItem.swift` and `AppDelegate.swift`.
