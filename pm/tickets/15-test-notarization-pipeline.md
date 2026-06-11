STATUS: deferred
DECISION: Only needed for distribution to other users. Deferred until the app needs to be shared outside the development machine.

TICKET 15: Test Full Archive → Export → Notarize → Staple Pipeline
Milestone: Notarization Setup
Domain: Notarization / Distribution
Priority: P1 — end-to-end validation of the release pipeline
Effort: M
PRD: Section 3.4, Section 8 | Blockers: none

## HANDOFF BLOCK
PRD Section: 3.4 — Notarization & Distribution; Section 8 — success metric: spctl passes
Why: Each step in the pipeline (archive, export, notarize, staple) can fail
     independently. This ticket runs the full sequence end-to-end for the first
     time and documents any errors encountered, ensuring the pipeline is proven
     before it is documented in Ticket 16.

## DESCRIPTION
Run the complete distribution pipeline: build a signed Release archive, export it
to a distributable .app, submit to Apple's notarization service, wait for approval,
staple the notarization ticket, and verify with Gatekeeper's assessment tool.

## ACCEPTANCE CRITERIA
- [ ] `xcodebuild archive` produces a signed archive (codesign -dv shows Developer ID)
- [ ] `xcodebuild -exportArchive` exports a distributable .app to `build/export/`
- [ ] `xcrun notarytool submit` exits 0 and returns a submission UUID
- [ ] `xcrun notarytool wait` exits 0 with status "Accepted" (not "Invalid")
- [ ] `xcrun stapler staple` exits 0 on the exported .app
- [ ] `spctl --assess --verbose build/export/DNSSwitcher.app` exits 0 with no rejection
- [ ] A `build/export/DNSSwitcher.zip` is produced for distribution

## IMPLEMENTATION DETAIL
Full pipeline — run each step and verify before proceeding:

Step 1 — Archive:

  xcodebuild -workspace DNSSwitcher.xcworkspace \
             -scheme DNSSwitcher \
             -configuration Release \
             -archivePath build/DNSSwitcher.xcarchive \
             archive

  # Verify signature:
  codesign -dv --verbose=4 build/DNSSwitcher.xcarchive/Products/Applications/DNSSwitcher.app

Step 2 — Create ExportOptions.plist (required for xcodebuild -exportArchive):

  cat > build/ExportOptions.plist << 'EOF'
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
  </dict>
  </plist>
  EOF

Step 3 — Export:

  xcodebuild -exportArchive \
             -archivePath build/DNSSwitcher.xcarchive \
             -exportPath build/export/ \
             -exportOptionsPlist build/ExportOptions.plist

Step 4 — Create zip for notarization (notarytool requires a zip or dmg):

  ditto -c -k --keepParent build/export/DNSSwitcher.app build/DNSSwitcher-notarize.zip

Step 5 — Submit for notarization:

  xcrun notarytool submit build/DNSSwitcher-notarize.zip \
    --keychain-profile "DNSSwitcher-notarytool" \
    --wait

  # --wait polls until notarization completes. Usually takes 1–5 minutes.
  # Output ends with: status: Accepted

Step 6 — Staple:

  xcrun stapler staple build/export/DNSSwitcher.app

Step 7 — Verify:

  spctl --assess --verbose build/export/DNSSwitcher.app
  # Expected: build/export/DNSSwitcher.app: accepted

Step 8 — Create distribution zip:

  ditto -c -k --keepParent build/export/DNSSwitcher.app build/export/DNSSwitcher.zip

If notarytool returns status "Invalid", retrieve the full log:
  xcrun notarytool log <submission-uuid> --keychain-profile "DNSSwitcher-notarytool"
Common rejection reasons: unsigned binary slices, missing hardened runtime,
disallowed entitlements, or unresolved embedded framework signatures.

## DEFERRED SCOPE
- Creating a .dmg with background art and Applications symlink for a polished
  distribution format — the zip is sufficient for initial distribution.
- Automating the pipeline in a Makefile or shell script — captured in Ticket 16.

## DEPENDENCIES
Ticket 11 must be complete (universal binary confirmed).
Ticket 14 must be complete (notarytool credentials stored).

## VERIFICATION
1. Run `codesign -dv build/export/DNSSwitcher.app 2>&1 | grep "Developer ID Application"` — must match the provisioned certificate.
2. Run `xcrun stapler validate build/export/DNSSwitcher.app` — must output `The validate action worked!`
3. Run `spctl --assess --verbose build/export/DNSSwitcher.app` — must output `accepted`.
4. [Regression guard] Run the app from `build/export/DNSSwitcher.app` (double-click or `open`) on the development machine — must launch without a Gatekeeper quarantine dialog.
