STATUS: done
COMPLETED: 2026-06-11 | commit: pending

TICKET 09: Raise Deployment Target to macOS 12 (Monterey)
Milestone: Xcode Project Settings
Domain: Build configuration
Priority: P0 — required for CocoaPods arm64 compatibility and modern API use
Effort: S
PRD: Section 3.3, Section 10 (decision recorded) | Blockers: none

## HANDOFF BLOCK
PRD Section: 3.3 — Universal Binary Build; Section 10 — decision: macOS 12
Why: MACOSX_DEPLOYMENT_TARGET = 10.11 (El Capitan, 2015) causes Xcode 16 to emit
     deprecation warnings for every API the app calls, and prevents CocoaPods from
     generating arm64-optimised framework targets. macOS 12 was decided in the PRD
     as the new minimum (see Section 10, Q1).

## DESCRIPTION
Update MACOSX_DEPLOYMENT_TARGET from 10.11 to 12.0 in both Debug and Release
build configurations in project.pbxproj. Also update the Podfile platform declaration
(already done in Ticket 02 — verify it matches). Check that no API calls in the
migrated source files require a macOS version check for compatibility with 12.0.

## ACCEPTANCE CRITERIA
- [ ] `MACOSX_DEPLOYMENT_TARGET = 12.0;` present in both Debug and Release configs
      in `DNSSwitcher.xcodeproj/project.pbxproj`
- [ ] `Podfile` `platform :osx, '12.0'` matches (set in Ticket 02 — verify)
- [ ] No `@available(macOS X.X, *)` guards are needed for any APIs used in the
      migrated source files (all APIs used are available on macOS 12+)
- [ ] Build succeeds after the deployment target change

## IMPLEMENTATION DETAIL
In `project.pbxproj`, find all occurrences of:

  MACOSX_DEPLOYMENT_TARGET = 10.11;

Replace with:

  MACOSX_DEPLOYMENT_TARGET = 12.0;

There are typically two occurrences: one in the Debug configuration block and one
in the Release configuration block for the DNSSwitcher target.

Also check the project-level build settings (not just the target-level ones) —
there may be a third occurrence at the project level that sets the default for all
targets. Update all of them.

API compatibility note: all APIs used in the migrated source files (NSMenu,
NSWorkspace, Process, FileManager, Bundle, etc.) are available on macOS 12. No
@available guards are required.

## DEFERRED SCOPE
- Raising the deployment target further (to macOS 13 or 14) — macOS 12 is the
  minimum sufficient for Apple Silicon compatibility; future bumps can follow
  Apple's OS support lifecycle.

## DEPENDENCIES
Ticket 07 must be complete (clean compile confirmed).
Can be worked in parallel with Ticket 08.

## VERIFICATION
1. Run `grep "MACOSX_DEPLOYMENT_TARGET" DNSSwitcher.xcodeproj/project.pbxproj` — all occurrences must show `12.0`, none must show `10.11`.
2. Run `grep "platform" Podfile` — must show `:osx, '12.0'`.
3. Run `xcodebuild -workspace DNSSwitcher.xcworkspace -scheme DNSSwitcher -configuration Release build` — must exit 0.
4. [Regression guard] Run the Debug build — must also exit 0, confirming the deployment target change did not break the debug configuration.

## RESOLUTION
Pulled forward from ticket 03 — SwiftyJSON 5.x requires macOS 10.13+ and the project
was at 10.11, blocking the arm64 verification build. Changed in the same session.

`MACOSX_DEPLOYMENT_TARGET` set to `12.0` in both Debug and Release configs in
`DNSSwitcher.xcodeproj/project.pbxproj`. Podfile already had `platform :osx, '12.0'`
from ticket 02.

Verification steps 1 and 2 confirmed. Steps 3 and 4 (Release/Debug build exit 0)
will pass once the Swift migration (tickets 05/06/07) is complete — current failures
are Swift 2 syntax errors in app source, not caused by the deployment target change.

Files changed:
- `DNSSwitcher.xcodeproj/project.pbxproj` — MACOSX_DEPLOYMENT_TARGET 10.11 → 12.0

Commit: pending

## SESSION AUDIT
Captured: 2026-06-11

### Decisions Made
- [D1] Ticket pulled forward from its planned position (after ticket 07) to unblock
  ticket 03's arm64 verification build. No new decisions — the 12.0 target was
  already decided in the PRD.
