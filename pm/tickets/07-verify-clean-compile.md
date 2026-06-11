STATUS: blocked
BLOCKED_BY_TICKET: Ticket 05, Ticket 06

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
- [ ] `xcodebuild` on the DNSSwitcher scheme exits with code 0
- [ ] Zero compiler errors in any source file
- [ ] Any compiler warnings reviewed and documented (not necessarily fixed here)
- [ ] The built app launches on the development machine (smoke test)

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
