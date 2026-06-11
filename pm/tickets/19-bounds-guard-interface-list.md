STATUS: done
COMPLETED: 2026-06-11 | commit: 2cf634b
COMMITS: 2cf634b

TICKET 19: Bounds Guard in highlightEnabledInterface
Milestone: Security Hardening
Domain: stability
Priority: P1 — deterministic crash on startup in VM environments or machines where all network services are disabled
Effort: S
PRD: N/A (deepsec scan finding) | Blockers: none

## HANDOFF BLOCK

**Source:** deepsec scan — finding `other-crash`, confirmed true-positive by revalidation pass.
**File:** `.deepsec/.deepsec/findings/BUG/DNSSwitcher-other-crash-25647904cc.md`
**Why:** `highlightEnabledInterface()` accesses `self.interfaceMenu.items[0]` unconditionally in its failover path. On machines where `networksetup -listallnetworkservices` succeeds but returns only disabled (starred) services, `loadNetworkInterfaces()` adds nothing to the menu and the subscript throws an `IndexOutOfRange` crash at startup.

## DESCRIPTION

The failover block in `highlightEnabledInterface()` assumed `interfaceMenu.items` was always non-empty — a safe assumption on physical Macs with at least one enabled network service, but not on VMs or machines with only virtual/disabled services. The fix adds `guard !self.interfaceMenu.items.isEmpty else { return }` before the subscript access.

## ACCEPTANCE CRITERIA

- [x] `guard !self.interfaceMenu.items.isEmpty else { return }` added before `self.interfaceMenu.items[0]` access in the failover path
- [x] App does not crash when `interfaceMenu.items` is empty
- [x] Normal path (items non-empty, no matching interface) still sets `items[0]` as active and marks it `.on`

## DEFERRED SCOPE

When `interfaceMenu.items` is empty the app silently does nothing — the user has no network interfaces to configure. A future improvement could show a disabled menu item labeled "No network interfaces found" so the UI surface is informative rather than blank. Deferred as cosmetic.

## DEPENDENCIES

None.

## VERIFICATION

1. Open `DNSSwitcher/DNSSwitcher/AppDelegate.swift` — `highlightEnabledInterface()` failover block opens with `guard !self.interfaceMenu.items.isEmpty else { return }`
2. Normal path unchanged: when items is non-empty and no interface matches, `items[0]` is selected
3. Build in Xcode — zero compile errors
4. [Regression guard] `loadNetworkInterfaces()` still populates `interfaceMenu` and `highlightEnabledInterface()` is still called from `initMenu()` — interface selection flow intact

## RESOLUTION

Added `guard !self.interfaceMenu.items.isEmpty else { return }` in `DNSSwitcher/DNSSwitcher/AppDelegate.swift` inside the `highlightEnabledInterface()` failover block, before the `self.interfaceMenu.items[0]` subscript access.

Commit: pending

## SESSION AUDIT
Captured: 2026-06-11

### No decisions recorded
Fix was mechanical — no design choices required.
