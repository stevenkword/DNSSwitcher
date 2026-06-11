STATUS: blocked
BLOCKED_BY_TICKET: Ticket 08, Ticket 09

TICKET 10: Build and Verify Universal Binary
Milestone: Xcode Project Settings
Domain: Build verification
Priority: P0 — produces the first universal binary; gate for lipo confirmation
Effort: S
PRD: Section 3.3, Section 8 | Blockers: none

## HANDOFF BLOCK
PRD Section: 3.3 — Universal Binary Build; Section 8 — success metric: lipo confirms fat binary
Why: The ARCHS setting change in Ticket 08 only guarantees both architectures are
     requested — it does not guarantee the linker produced a fat binary. This ticket
     does a Release archive build (the same build type used for distribution) and
     captures the binary for lipo inspection in Ticket 11.

## DESCRIPTION
Perform a Release archive build of DNSSwitcher using xcodebuild. Confirm the build
succeeds and that the resulting .xcarchive contains the application bundle. The
binary inside the bundle is what Ticket 11 will inspect with lipo.

## ACCEPTANCE CRITERIA
- [ ] `xcodebuild archive` exits with code 0 and produces `build/DNSSwitcher.xcarchive`
- [ ] `DNSSwitcher.xcarchive/Products/Applications/DNSSwitcher.app` exists
- [ ] `DNSSwitcher.xcarchive/Products/Applications/DNSSwitcher.app/Contents/MacOS/DNSSwitcher`
      exists (the Mach-O binary)
- [ ] Build log shows no `error:` lines

## IMPLEMENTATION DETAIL
Run the archive build from the repo root:

  xcodebuild -workspace DNSSwitcher.xcworkspace \
             -scheme DNSSwitcher \
             -configuration Release \
             -archivePath build/DNSSwitcher.xcarchive \
             -sdk macosx \
             archive

On success, the archive is written to `build/DNSSwitcher.xcarchive/`.

If code signing fails at archive time (because no Developer ID cert is installed
yet — that is Ticket 12), add the CODE_SIGN_IDENTITY override to skip signing
for this verification build:

  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

This produces an unsigned binary for architecture verification purposes only.
The signed build is produced in Ticket 15.

## DEFERRED SCOPE
- Automated CI archive builds (GitHub Actions) — out of scope per PRD Section 9.

## DEPENDENCIES
Ticket 08 (universal arch set) and Ticket 09 (deployment target raised) must both
be complete.

## VERIFICATION
1. Run the archive command above — must output `** ARCHIVE SUCCEEDED **`.
2. Run `ls build/DNSSwitcher.xcarchive/Products/Applications/DNSSwitcher.app/Contents/MacOS/` — must list the `DNSSwitcher` binary.
3. Run `file build/DNSSwitcher.xcarchive/Products/Applications/DNSSwitcher.app/Contents/MacOS/DNSSwitcher` — must output `Mach-O universal binary with 2 architectures`.
4. [Regression guard] Confirm the Debug build still succeeds: `xcodebuild -workspace DNSSwitcher.xcworkspace -scheme DNSSwitcher -configuration Debug build` exits 0.
