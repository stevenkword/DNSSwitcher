# Project Board — DNSSwitcher Apple Silicon Migration

**Version:** 1.9.0
> Generated artifact. Regenerate by asking Claude "show me the board".
> Last updated: 2026-06-11

---

## Manual Actions Pending

| Action | Owner | Blocking |
|--------|-------|---------|

---

## BLOCKED — owner action required

| # | Ticket | Milestone | Waiting on |
|---|--------|-----------|------------|

---

## BLOCKED — waiting on ticket

| # | Ticket | Milestone | Waiting on |
|---|--------|-----------|------------|

---

## TODO

| # | Ticket | Milestone | Priority | Depends on |
|---|--------|-----------|----------|------------|
| 11 | Confirm Universal Binary with lipo | Xcode Project Settings | P0 | #10 ✓ |

---

## IN PROGRESS

| # | Ticket | Milestone | Started |
|---|--------|-----------|---------|

---

## DONE

| # | Ticket | Milestone | Completed | Commit |
|---|--------|-----------|-----------|--------|
| 01 | Update CocoaPods Tooling to Current Version | CocoaPods + SwiftyJSON Update | 2026-06-11 | 4eba005 |
| 02 | Update SwiftyJSON Dependency to v5.x | CocoaPods + SwiftyJSON Update | 2026-06-11 | pending |
| 03 | Verify Pod Install and arm64 Framework Build | CocoaPods + SwiftyJSON Update | 2026-06-11 | pending |
| 09 | Raise Deployment Target to macOS 12 | Xcode Project Settings | 2026-06-11 | pending |
| 04 | Audit Source Files for Swift 2 Incompatibilities | Swift Syntax Migration | 2026-06-11 | — |
| 05 | Migrate AppDelegate.swift to Swift 5 | Swift Syntax Migration | 2026-06-11 | 7ca9103 |
| 06 | Migrate Config.swift and SettingItem.swift to Swift 5 | Swift Syntax Migration | 2026-06-11 | d5495b0 |
| 07 | Verify Clean Compile in Modern Xcode | Swift Syntax Migration | 2026-06-11 | ce9bf05 |
| 08 | Set Universal Binary Architecture | Xcode Project Settings | 2026-06-11 | 653a1bf |
| 10 | Build and Verify Universal Binary | Xcode Project Settings | 2026-06-11 | pending |

---

## Recommended start order

Start with Ticket 01 (update CocoaPods) — it has no dependencies and unblocks
the entire chain. Tickets 02 and 03 follow sequentially. Once the pod layer is
confirmed (Ticket 03), begin the Swift migration: Tickets 05 and 06 can run in
parallel (both depend only on Ticket 04's audit). Ticket 07 gates all architecture
work. Tickets 08 and 09 can run in parallel after Ticket 07. Ticket 11 is the
finish line — a passing lipo check confirms native Apple Silicon support.

---

## BACKLOG — Deferred Scope

| Item | Source | Gate | Notes |
|------|--------|------|-------|
| Provision Developer ID Application Certificate | #12 | Distribution needed | Required only when distributing to other users |
| Configure code signing (Developer ID) in Xcode | #13 | Distribution needed | Depends on #12 |
| Set up xcrun notarytool credentials | #14 | Distribution needed | Depends on #12; requires Apple Developer Program enrollment |
| Test full archive → notarize → staple pipeline | #15 | Distribution needed | Depends on #11, #14 |
| Document release process (RELEASING.md) | #16 | Distribution needed | Depends on #15 |
| Migrate CocoaPods → Swift Package Manager | #01, #02 | Unscheduled | SPM would remove the Pods/ directory entirely |
| Modernise optional chaining / remove force-unwraps | #05, #06 | Unscheduled | Safety improvement; not required for compilation |
| Adopt @MainActor / Swift 6 concurrency | #05 | Unscheduled | Swift 6 strict concurrency; future clean-up pass |
| Replace Config class with Codable struct | #06 | Unscheduled | Cleaner JSON parsing; deferred to avoid scope creep |
| arm64-only build (drop x86_64 slice) | #08 | Unscheduled | Once Intel Mac installed base is negligible |
| App Store distribution | #13, #15 | Unscheduled | Requires sandboxing, entitlements, App Review |
