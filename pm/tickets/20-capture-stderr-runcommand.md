STATUS: done
COMPLETED: 2026-06-11 | commit: pending
COMMITS: pending

TICKET 20: Capture stderr in runCommand
Milestone: Security Hardening
Domain: stability
Priority: P2 — blank error dialogs on every networksetup failure; no security implication but confirmed user-visible defect
Effort: S
PRD: N/A (deepsec scan finding) | Blockers: none

## HANDOFF BLOCK

**Source:** deepsec scan — finding `other-crash`, confirmed true-positive by revalidation pass.
**File:** `.deepsec/.deepsec/findings/BUG/DNSSwitcher-other-crash-75611f4afd.md`
**Why:** `runCommand()` attached a `Pipe` only to `task.standardOutput`. `networksetup` writes all diagnostic text to stderr, so when it exits non-zero the captured output string is empty. Both error alert invocations in `setDNSServers` produce NSAlert dialogs with a blank `informativeText` field — users see "DNS change failed with exit code 1: " with no explanation.

## DESCRIPTION

One-line fix: `task.standardError = pipe` added immediately after `task.standardOutput = pipe` in `runCommand()`. Both streams now flow into the same `Pipe`, so the full diagnostic output from `networksetup` (and any future command) is captured and surfaced in error dialogs.

## ACCEPTANCE CRITERIA

- [x] `task.standardError = pipe` set in `runCommand()` before `task.launch()`
- [x] `networksetup` error output (written to stderr) is now included in the returned `output` string
- [x] Error alert dialogs show non-empty `informativeText` when `networksetup` fails

## DEFERRED SCOPE

A more structured approach would capture stdout and stderr into separate strings and label them in the alert body ("stdout: … / stderr: …"). Deferred — the combined stream is sufficient for diagnostic purposes in this app.

## DEPENDENCIES

None.

## VERIFICATION

1. Open `DNSSwitcher/DNSSwitcher/AppDelegate.swift` `runCommand()` — `task.standardError = pipe` appears directly after `task.standardOutput = pipe`
2. Build in Xcode — zero compile errors
3. Both `task.standardOutput` and `task.standardError` point to the same `Pipe` instance
4. [Regression guard] `runCommand(["networksetup", "-listallnetworkservices"])` in `loadNetworkInterfaces()` still returns the expected output — combined pipe capture does not break the success path

## RESOLUTION

Added `task.standardError = pipe` on one line in `runCommand()` in `DNSSwitcher/DNSSwitcher/AppDelegate.swift`, immediately after `task.standardOutput = pipe`.

Commit: pending

## SESSION AUDIT
Captured: 2026-06-11

### No decisions recorded
Fix was mechanical — no design choices required.
