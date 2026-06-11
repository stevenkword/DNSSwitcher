STATUS: blocked
BLOCKED_BY_TICKET: Ticket 07

TICKET 08: Set Universal Binary Architecture in Xcode Project
Milestone: Xcode Project Settings
Domain: Build configuration
Priority: P0 — the core Apple Silicon deliverable
Effort: S
PRD: Section 3.3 | Blockers: none

## HANDOFF BLOCK
PRD Section: 3.3 — Universal Binary Build
Why: The project.pbxproj has no explicit ARCHS setting, which means it defaults to
     whatever Xcode infers. On Apple Silicon Macs, Xcode 16 will default to arm64
     only for the host architecture. Setting ARCHS = $(ARCHS_STANDARD) explicitly
     produces a universal (fat) binary containing both arm64 and x86_64.

## DESCRIPTION
Add `ARCHS = "$(ARCHS_STANDARD)";` to both Debug and Release build configurations
in project.pbxproj, and ensure `ONLY_ACTIVE_ARCH = NO` in Release so that archive
builds include both slices. Also ensure the Pods project inherits the same setting.

## ACCEPTANCE CRITERIA
- [ ] `ARCHS = "$(ARCHS_STANDARD)";` present in both Debug and Release configs
      in `DNSSwitcher.xcodeproj/project.pbxproj`
- [ ] `ONLY_ACTIVE_ARCH = NO;` set in the Release build configuration
      (Debug can remain YES for faster local builds)
- [ ] `VALID_ARCHS` is not set (or removed if present) — it was deprecated in
      Xcode 12 and conflicts with ARCHS_STANDARD
- [ ] The Pods project target also does not have conflicting ARCHS overrides

## IMPLEMENTATION DETAIL
In `project.pbxproj`, locate the two XCBuildConfiguration blocks for DNSSwitcher
(one for Debug, one for Release). Add to each:

  ARCHS = "$(ARCHS_STANDARD)";

In the Release block specifically, also add:

  ONLY_ACTIVE_ARCH = NO;

The Debug block can keep `ONLY_ACTIVE_ARCH = YES` (default) so that local debug
builds stay fast by only building for the host machine's native architecture.

To edit via Xcode GUI instead:
  1. Select DNSSwitcher project in navigator → Build Settings tab
  2. Set "Architectures" to "Standard Architectures" for both Debug and Release
  3. Set "Build Active Architecture Only" to No for Release, Yes for Debug

Note: CocoaPods may override ARCHS in the Pods.xcconfig files it generates.
After running `pod install` in Ticket 02, check:
  Pods/Target Support Files/Pods-DNSSwitcher/Pods-DNSSwitcher.release.xcconfig
  — if it sets ARCHS, it takes precedence and must be reconciled.

## DEFERRED SCOPE
- Building arm64-only for a future macOS-arm64-only release — once the Intel Mac
  installed base is negligible, the x86_64 slice can be dropped.

## DEPENDENCIES
Ticket 07 must be complete (clean compile confirmed).

## VERIFICATION
1. Run `grep -A2 "ARCHS" DNSSwitcher.xcodeproj/project.pbxproj` — must show `$(ARCHS_STANDARD)` in both Debug and Release blocks.
2. Run `grep "ONLY_ACTIVE_ARCH" DNSSwitcher.xcodeproj/project.pbxproj` — Release block must show `NO`.
3. Run `grep "VALID_ARCHS" DNSSwitcher.xcodeproj/project.pbxproj` — must return empty (setting deprecated; must be absent).
4. [Regression guard] Run `xcodebuild -workspace DNSSwitcher.xcworkspace -scheme DNSSwitcher -configuration Debug build` — must still exit 0 after the settings change.
