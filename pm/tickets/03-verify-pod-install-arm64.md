STATUS: blocked
BLOCKED_BY_TICKET: Ticket 02

TICKET 03: Verify Pod Install and arm64 Framework Build
Milestone: CocoaPods + SwiftyJSON Update
Domain: Dependencies / Build verification
Priority: P0 — confirms the dependency layer is arm64-ready before code changes begin
Effort: S
PRD: Section 3.1 | Blockers: none

## HANDOFF BLOCK
PRD Section: 3.1 — Dependency Modernisation
Why: A successful `pod install` does not guarantee the resulting framework contains
     an arm64 slice. This ticket explicitly confirms architecture coverage before
     any Swift migration work begins, preventing a false start.

## DESCRIPTION
After the Podfile has been updated and `pod install` has run, verify that the
SwiftyJSON framework in the Pods build products contains both arm64 and x86_64
slices. This confirms that CocoaPods and the updated podspec are generating a
correctly architected framework.

## ACCEPTANCE CRITERIA
- [ ] `pod install` exits with code 0 and no error output
- [ ] `lipo -info` on the built SwiftyJSON framework binary shows `arm64` in the
      architecture list
- [ ] No "missing architecture" warnings appear in the Pods project build log
- [ ] `DNSSwitcher.xcworkspace` opens in Xcode without scheme warnings

## IMPLEMENTATION DETAIL
After `pod install`, build the Pods scheme to generate the framework binaries:

  xcodebuild -workspace DNSSwitcher.xcworkspace \
             -scheme Pods-DNSSwitcher \
             -configuration Debug \
             -sdk macosx \
             ARCHS="arm64 x86_64" \
             build

Then inspect the framework slice:

  lipo -info Pods/SwiftyJSON/Source/SwiftyJSON.swift
  # For the built product:
  find ~/Library/Developer/Xcode/DerivedData -name "SwiftyJSON.framework" -path "*/Debug/*" 2>/dev/null | head -1

Or build via the main workspace and inspect DerivedData:

  xcodebuild -workspace DNSSwitcher.xcworkspace \
             -scheme DNSSwitcher \
             -configuration Debug \
             -sdk macosx \
             build 2>&1 | tail -20

If the framework is a source-only pod (no pre-built binary), the architecture is
determined at app build time — in that case, verify by building the main scheme
and running `lipo -info` on the resulting app binary in DerivedData.

## DEFERRED SCOPE
- Automated architecture verification in CI — out of scope per PRD Section 9.

## DEPENDENCIES
Ticket 02 must be complete (SwiftyJSON 5.x installed via pod install).

## VERIFICATION
1. Run `pod install` from repo root — exit code must be 0.
2. Run `xcodebuild -workspace DNSSwitcher.xcworkspace -scheme DNSSwitcher -configuration Debug build` — must exit 0 (compiler errors are expected until Swift migration is done; linker/framework errors are not acceptable at this stage).
3. Run `lipo -info` on the SwiftyJSON framework binary or the app binary — output must include `arm64`.
4. [Regression guard] Confirm `Pods/Manifest.lock` matches `Podfile.lock` — the Check Pods Manifest.lock build phase will fail the build if they diverge.
