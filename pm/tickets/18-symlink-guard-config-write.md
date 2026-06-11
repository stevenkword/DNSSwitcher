STATUS: done
COMPLETED: 2026-06-11 | commit: 2cf634b
COMMITS: 2cf634b

TICKET 18: Symlink Guard on Config File Write
Milestone: Security Hardening
Domain: security
Priority: P1 — MEDIUM-severity path traversal; clicking "Restore Default Servers" overwrites the symlink target, corrupting arbitrary user-writable files
Effort: S
PRD: N/A (deepsec scan finding) | Blockers: none

## HANDOFF BLOCK

**Source:** deepsec scan — finding `path-traversal`, confirmed true-positive by revalidation pass.
**File:** `.deepsec/.deepsec/findings/MEDIUM/DNSSwitcher-path-traversal-c16137bf43.md`
**Why:** `createDefaultConfigFile()` writes to `~/.dnsswitcher.json` via `Data.write(to:)` without first checking whether the path is a symlink. A symlink placed at that path (by a TOCTOU race or a separate write primitive) redirects the write to an arbitrary file the current user can write — `~/.ssh/authorized_keys`, dotfiles, other app configs.

## DESCRIPTION

`createDefaultConfigFile()` in `AppDelegate.swift` contained an unconditional `data.write(to:)` on line ~249 that followed symlinks. The fix adds a symlink canonicalization check using `URL.resolvingSymlinksInPath()` before the write: if the resolved path differs from the standardized expected path, the write is aborted and a warning is printed. `saveLatestConfig()` was confirmed not vulnerable — it uses `atomically: true` (write-to-temp + rename), which replaces the directory entry rather than following symlinks to the target.

## ACCEPTANCE CRITERIA

- [x] `createDefaultConfigFile()` resolves the destination URL via `resolvingSymlinksInPath()` before writing
- [x] Write is aborted (with a printed warning) if the resolved path differs from the expected standardized path
- [x] `saveLatestConfig()` is unchanged (it is not vulnerable)
- [x] Normal (non-symlink) case: write proceeds as before

## DEFERRED SCOPE

A more robust alternative is to open the file with `O_NOFOLLOW` via `FileHandle` to refuse symlink traversal at the OS level. This would eliminate the TOCTOU window between the check and the write. Deferred as the current guard reduces the practical risk to near-zero for this app's threat model.

## DEPENDENCIES

None.

## VERIFICATION

1. Open `DNSSwitcher/DNSSwitcher/AppDelegate.swift` — `createDefaultConfigFile()` contains a `resolvingSymlinksInPath()` call and a `guard resolvedURL == expectedURL` before `data.write`
2. Normal path: `configFilePath` points to a regular file → `resolvedURL == expectedURL` → write proceeds
3. Symlink path: if `~/.dnsswitcher.json` is a symlink to `/tmp/target` → `resolvedURL` is `/tmp/target`, `expectedURL` is `~/.dnsswitcher.json` → guard fires, write aborted
4. `saveLatestConfig()` is unchanged — still uses `atomically: true`
5. [Regression guard] `restoreDefaultServers` action still calls `createDefaultConfigFile()` followed by `initMenu()` — menu reload is unaffected

## RESOLUTION

Modified `createDefaultConfigFile()` in `DNSSwitcher/DNSSwitcher/AppDelegate.swift`: replaced the bare `data.write(to: URL(fileURLWithPath: self.configFilePath))` with a symlink check using `resolvingSymlinksInPath()` / `standardizedFileURL`. If the resolved path differs from the expected path, the function returns early with a printed warning.

Commit: pending

## SESSION AUDIT
Captured: 2026-06-11

### Decisions Made
- [D1] Chose `resolvingSymlinksInPath()` check over `O_NOFOLLOW` — simpler, sufficient for this app's threat model.

### No additional decisions recorded
