STATUS: done
COMPLETED: 2026-06-11 | commit: ce9bf05
COMMITS: ce9bf05

TICKET 07: Verify Clean Compile in Modern Xcode
Milestone: Swift Syntax Migration
Domain: Build verification
Priority: P0 — gates all architecture and signing work
Effort: S
PRD: Section 3.2, Section 8 | Blockers: none

## HANDOFF BLOCK
PRD Section: 3.2 — Swift Language Migration; Section 8 — Success Metrics
Why: Tickets 05 and 06 may each compile individually but introduce type mismatches
     at the call sites (e.g., Config.init now takes Data, and AppDelegate passes
     Data — they must agree). This ticket does a full project build to catch any
     cross-file integration errors.

## DESCRIPTION
Build the full DNSSwitcher scheme from the workspace and confirm zero compiler
errors. Any remaining warnings should be noted but are not blockers unless they
indicate a logic error (e.g., a result of a call is unused where it previously was
not). This is the gate before architecture and signing work begins.

## ACCEPTANCE CRITERIA
- [x] `xcodebuild` on the DNSSwitcher scheme exits with code 0
- [x] Zero compiler errors in any source file
- [x] Any compiler warnings reviewed and documented (not necessarily fixed here)
- [x] The built app launches on the development machine (smoke test)

## IMPLEMENTATION DETAIL
Build command:

  xcodebuild -workspace DNSSwitcher.xcworkspace \
             -scheme DNSSwitcher \
             -configuration Debug \
             -sdk macosx \
             build

Expected output ends with:
  ** BUILD SUCCEEDED **

If any errors remain, they must be fixed before marking this ticket done. Common
remaining errors after the mechanical migration:
  - Type mismatch: passing NSData where Data is expected (check AppDelegate
    call sites that create Config instances)
  - Missing @objc on action methods if the XIB still references old signatures
  - SwiftyJSON API: JSON(data:) is now throwing, ensure all call sites use try/try?

To smoke-test the built app, find the binary in DerivedData and launch it:
  open ~/Library/Developer/Xcode/DerivedData/DNSSwitcher-*/Build/Products/Debug/DNSSwitcher.app

## DEFERRED SCOPE
- Resolving all compiler warnings (deprecation notices, unused variable warnings) —
  not required for Apple Silicon support but should be a future clean-up pass.

## DEPENDENCIES
Tickets 05 and 06 must both be complete.

## VERIFICATION
1. Run the xcodebuild command above — exit code must be 0 and output must contain `** BUILD SUCCEEDED **`.
2. Run `xcodebuild ... build 2>&1 | grep -c "error:"` — must output `0`.
3. Run `xcodebuild ... build 2>&1 | grep "warning:" | wc -l` — note the count; record it in this ticket's RESOLUTION section.
4. [Regression guard] Open the built DNSSwitcher.app — the menu bar icon must appear and the menu must open without crashing.

## RESOLUTION
Root cause: `SWIFT_VERSION` was absent from both the Debug and Release target-level
build configurations in `DNSSwitcher.xcodeproj/project.pbxproj`. Xcode treated the
empty value as unsupported and refused to compile.

Fix applied: added `SWIFT_VERSION = 5.0;` to both `C9B374CE` (Debug) and `C9B374CF`
(Release) target build configurations.

Build result: `** BUILD SUCCEEDED **`, exit code 0.
Compiler errors: 0.
Compiler warnings: 2 — both CocoaPods build-phase dependency analysis notices
  ("Run script build phase ... will be run during every build because it does not
  specify any outputs"). These are pre-existing CocoaPods infrastructure warnings,
  not logic errors, and are deferred per DEFERRED SCOPE.
Smoke test: DNSSwitcher.app launched; menu bar icon appeared and menu opened without
  crashing. User confirmed.

Files changed:
- DNSSwitcher.xcodeproj/project.pbxproj — added SWIFT_VERSION = 5.0 to target Debug and Release configs

## SESSION AUDIT
Captured: 2026-06-11

### Decisions Made
- [D1] Build verification runs with `CODE_SIGNING_ALLOWED=NO` override — the signing
  identity in the target ("Developer ID Application") requires a provisioned team,
  which is deferred to the distribution milestone. Overriding at the command line
  keeps the project file correct for eventual signing while unblocking local compile
  verification.

### Clarifications Provided
- [C1] User confirmed smoke test passed ("continue") after viewing the menu bar
  screenshot showing the app launched successfully.

### Scope Changes
- [S1] Added: `SWIFT_VERSION = 5.0` to project.pbxproj target configs — this was a
  pre-condition for any build at all (missing setting caused an immediate build error),
  not called out explicitly in the ticket but falls squarely within its scope.
