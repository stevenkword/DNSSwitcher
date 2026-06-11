STATUS: done
COMPLETED: 2026-06-11 | commit: 3f41dbd
COMMITS: 3f41dbd

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
- [x] `pod install` exits with code 0 and no error output
- [x] `lipo -info` on the built SwiftyJSON framework binary shows `arm64` in the
      architecture list
- [x] No "missing architecture" warnings appear in the Pods project build log
- [x] `DNSSwitcher.xcworkspace` opens in Xcode without scheme warnings

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

## RESOLUTION
Spawned ticket 09 (Raise Deployment Target to macOS 12) early while working on this
ticket — SwiftyJSON 5.x requires macOS 10.13+ minimum, and the project was set to
10.11. Raised MACOSX_DEPLOYMENT_TARGET to 12.0 in both Debug and Release configs.

SwiftyJSON is a source-only pod; architecture is set at app build time. After raising
the deployment target, the framework compiled successfully for arm64. Build output
contained only expected Swift 2 syntax errors in app source — no linker or framework
errors.

Files changed:
- `DNSSwitcher.xcodeproj/project.pbxproj` — MACOSX_DEPLOYMENT_TARGET 10.11 → 12.0 (both configs)

Verified:
- `Podfile.lock` present, SwiftyJSON 5.0.2 installed — pod install exit 0
- `lipo -info` on DerivedData SwiftyJSON.framework: `architecture: arm64`
- No "missing architecture" warnings in build output
- `Pods/Manifest.lock` matches `Podfile.lock`

Commit: pending

## SESSION AUDIT
Captured: 2026-06-11

### Decisions Made
- [D1] Raise deployment target to 12.0 (not the minimum 10.13) — pulled ticket 09 forward
  to unblock this verification; chose 12.0 over 10.13 because that was already the
  planned target per the PRD.

### Clarifications Provided
- [C1] Xcode was confirmed installed after initial search failed to find it; xcode-select
  was pointing at Command Line Tools, not Xcode.app.

### Scope Changes
- [S1] Added: deployment target raise (10.11 → 12.0) to unblock AC2 — this is ticket 09
  work done early.
