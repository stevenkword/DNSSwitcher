STATUS: deferred
DECISION: Only needed for distribution to other users. Deferred until the app needs to be shared outside the development machine.

TICKET 14: Set Up xcrun notarytool Credentials
Milestone: Notarization Setup
Domain: Notarization
Priority: P1 — required before any notarization submission
Effort: S
PRD: Section 3.4, Section 5 | Blockers: none

## HANDOFF BLOCK
PRD Section: 3.4 — Notarization & Distribution; Section 5 — Apple Developer Program
Why: `xcrun notarytool` submits the signed binary to Apple's notarization service.
     It requires stored credentials (Apple ID + app-specific password, or an App
     Store Connect API key) to authenticate. Credentials are stored in the macOS
     Keychain under a named profile so the notarization command does not expose
     credentials in shell history or scripts.

## DESCRIPTION
Store notarization credentials in the macOS Keychain using `xcrun notarytool
store-credentials`. Choose between Apple ID + app-specific password (simpler) or
App Store Connect API key (more secure for CI). For a single-developer project,
the Apple ID approach is sufficient.

## ACCEPTANCE CRITERIA
- [ ] An app-specific password has been generated at appleid.apple.com
      (under Security → App-Specific Passwords)
- [ ] `xcrun notarytool store-credentials` has been run and credentials stored
      under the profile name `DNSSwitcher-notarytool`
- [ ] `xcrun notarytool history --keychain-profile "DNSSwitcher-notarytool"`
      succeeds (exit 0, even if submission list is empty)

## IMPLEMENTATION DETAIL
Step 1 — Generate an app-specific password (owner action):
  1. Sign in to appleid.apple.com
  2. Navigate to Security → App-Specific Passwords → Generate Password
  3. Label it "DNSSwitcher notarytool" and note the generated password (xxxx-xxxx-xxxx-xxxx format)

Step 2 — Store credentials in Keychain:

  xcrun notarytool store-credentials "DNSSwitcher-notarytool" \
    --apple-id "your@apple.id" \
    --team-id "YOUR_TEAM_ID" \
    --password "xxxx-xxxx-xxxx-xxxx"

Step 3 — Verify the credentials work:

  xcrun notarytool history \
    --keychain-profile "DNSSwitcher-notarytool"

Expected output: an empty submission list (or prior submissions if any exist).
An authentication error means the credentials are wrong.

Alternative: App Store Connect API key (preferred for CI pipelines):
  xcrun notarytool store-credentials "DNSSwitcher-notarytool" \
    --key /path/to/AuthKey_XXXXXXXXXX.p8 \
    --key-id "XXXXXXXXXX" \
    --issuer "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
This avoids the app-specific password and uses JWT-based auth. Recommended if
a CI pipeline is added in the future.

## DEFERRED SCOPE
- Migrating from Apple ID + app-specific password to API key authentication
  for CI — deferred until CI automation is set up (out of scope per PRD Section 9).

## DEPENDENCIES
Ticket 13 must be complete (code signing configured, Team ID confirmed).
Owner action: app-specific password must be generated before this ticket can complete.

## VERIFICATION
1. Run `xcrun notarytool history --keychain-profile "DNSSwitcher-notarytool"` — must exit 0 without an authentication error.
2. Confirm the keychain item exists: `security find-generic-password -s "com.apple.dt.xcrun.notarytool.account" 2>/dev/null && echo "found" || echo "not found"` (or search Keychain Access for "notarytool").
3. Confirm the profile name "DNSSwitcher-notarytool" is used consistently — this exact string will be used in the Ticket 15 notarize command and in RELEASING.md.
4. [Regression guard] Confirm the Developer ID Application identity is still valid: `security find-identity -v -p codesigning | grep "Developer ID Application"` must return a non-expired entry.
