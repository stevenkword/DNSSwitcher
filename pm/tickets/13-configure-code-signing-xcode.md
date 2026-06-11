STATUS: deferred
DECISION: Only needed for distribution to other users. Deferred until the app needs to be shared outside the development machine.

TICKET 13: Configure Code Signing in Xcode Project
Milestone: Notarization Setup
Domain: Code signing
Priority: P1 — required for notarytool submission
Effort: S
PRD: Section 3.4 | Blockers: none

## HANDOFF BLOCK
PRD Section: 3.4 — Notarization & Distribution
Why: The project.pbxproj has CODE_SIGN_IDENTITY = "Mac Developer" for the
     macosx SDK override, which is a development certificate. Distribution (and
     notarization) requires "Developer ID Application". The DEVELOPMENT_TEAM must
     also be set to match the provisioned certificate.

## DESCRIPTION
Update the Xcode project's code signing settings for the Release build configuration
to use the Developer ID Application certificate provisioned in Ticket 12. Debug
can retain "Mac Developer" for local development. Also ensure the hardened runtime
entitlement is enabled, as Apple's notarization service requires it.

## ACCEPTANCE CRITERIA
- [ ] Release build configuration has `CODE_SIGN_IDENTITY = "Developer ID Application";`
- [ ] Release build configuration has `DEVELOPMENT_TEAM = <Team ID from Ticket 12>;`
- [ ] `CODE_SIGN_STYLE = Manual;` (avoids Xcode auto-signing conflicts)
- [ ] `ENABLE_HARDENED_RUNTIME = YES;` in the Release build configuration
      (required by notarytool since 2019)
- [ ] Debug build configuration retains its existing signing settings unchanged
- [ ] A Release archive build signs the binary (no CODE_SIGNING_REQUIRED=NO override)

## IMPLEMENTATION DETAIL
In `project.pbxproj`, locate the Release XCBuildConfiguration block for the
DNSSwitcher target and update/add:

  CODE_SIGN_IDENTITY = "Developer ID Application";
  CODE_SIGN_STYLE = Manual;
  DEVELOPMENT_TEAM = <YOUR_TEAM_ID>;
  ENABLE_HARDENED_RUNTIME = YES;

The existing project.pbxproj has:
  CODE_SIGN_IDENTITY = "Developer ID Application";  ← already correct for Release
  CODE_SIGN_IDENTITY[sdk=macosx*] = "Mac Developer"; ← this overrides the above!

The `sdk=macosx*` conditional override must be removed from the Release
configuration (or changed to "Developer ID Application") — it takes precedence over
the base setting and causes the wrong certificate to be used for signing.

For the macosx sdk override in Debug, retain "Mac Developer" for local builds:
  /* Debug only */
  CODE_SIGN_IDENTITY[sdk=macosx*] = "Mac Developer";

Hardened runtime is enabled per-target in the entitlements. If no .entitlements
file exists, create `DNSSwitcher/DNSSwitcher.entitlements` with:

  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
  </dict>
  </plist>

An empty entitlements file with ENABLE_HARDENED_RUNTIME = YES is sufficient unless
specific capabilities (e.g., network access, keychain) are required.

Set CODE_SIGN_ENTITLEMENTS in the Release build settings to point to this file:
  CODE_SIGN_ENTITLEMENTS = DNSSwitcher/DNSSwitcher.entitlements;

## DEFERRED SCOPE
- Sandboxing the application (com.apple.security.app-sandbox) — would improve
  security but requires entitlement updates and changes to how the app accesses
  user files and runs networksetup. Deferred to a future hardening pass.

## DEPENDENCIES
Ticket 12 must be complete (Developer ID Application certificate installed,
Team ID known).

## VERIFICATION
1. Run `grep -A5 "Release" DNSSwitcher.xcodeproj/project.pbxproj | grep "CODE_SIGN_IDENTITY"` — must show `"Developer ID Application"` with no `Mac Developer` override for the Release block.
2. Run `grep "DEVELOPMENT_TEAM" DNSSwitcher.xcodeproj/project.pbxproj` — must show the correct Team ID.
3. Run `grep "ENABLE_HARDENED_RUNTIME" DNSSwitcher.xcodeproj/project.pbxproj` — must show `YES` in the Release block.
4. [Regression guard] Run a signed Release archive build: `xcodebuild -workspace DNSSwitcher.xcworkspace -scheme DNSSwitcher -configuration Release -archivePath build/DNSSwitcher.xcarchive archive` — must exit 0 and binary must be signed (run `codesign -dv build/DNSSwitcher.xcarchive/Products/Applications/DNSSwitcher.app` to confirm).
