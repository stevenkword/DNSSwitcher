STATUS: deferred
DECISION: Only needed for distribution to other users. Deferred until the app needs to be shared outside the development machine.

TICKET 16: Document Release Process
Milestone: Notarization Setup
Domain: Documentation / Process
Priority: P2 — important for repeatability; not blocking distribution
Effort: S
PRD: Section 3.4, Section 6 | Blockers: none

## HANDOFF BLOCK
PRD Section: 3.4 — Notarization & Distribution; Section 6 — Content Requirements (RELEASING.md)
Why: The notarization pipeline has 7 manual steps. Without documentation, the next
     release will require reconstructing this knowledge from memory or re-running
     Ticket 15. RELEASING.md codifies the proven pipeline and becomes the
     authoritative reference for all future releases.

## DESCRIPTION
Write `RELEASING.md` at the repo root documenting the complete, proven release
pipeline from Ticket 15. The document should be self-contained: a developer who
has never released this app before should be able to follow it without referring
to any other resource.

## ACCEPTANCE CRITERIA
- [ ] `RELEASING.md` exists at the repo root
- [ ] Prerequisites section lists: Xcode version, CocoaPods version, active Apple
      Developer Program enrollment, Developer ID Application certificate in Keychain,
      notarytool credentials stored under profile "DNSSwitcher-notarytool"
- [ ] Step-by-step pipeline covers: archive, export, zip, notarize, wait, staple,
      verify (spctl), create distribution zip
- [ ] Version bump instructions included (where to update the version string)
- [ ] Troubleshooting section covers: notarytool "Invalid" status, missing hardened
      runtime, unsigned embedded frameworks
- [ ] All commands are copy-pasteable with no placeholders left unfilled
      (Team ID, profile name, paths are the real values used in Ticket 15)

## IMPLEMENTATION DETAIL
The RELEASING.md should cover these sections:

  # DNSSwitcher Release Process

  ## Prerequisites
  ## Version Bump
  ## Build & Archive
  ## Export
  ## Notarize
  ## Staple & Verify
  ## Distribute
  ## Troubleshooting

Commands to include verbatim (from Ticket 15, with real Team ID substituted):
  - xcodebuild archive command
  - xcodebuild -exportArchive command + ExportOptions.plist contents
  - ditto zip command
  - xcrun notarytool submit --wait command
  - xcrun stapler staple command
  - spctl --assess command
  - Final ditto zip for distribution

Version bump location: the version string is in the Xcode project's Info.plist
(INFOPLIST_FILE) — specifically `CFBundleShortVersionString`. It can be updated
via Xcode's General tab or by editing Info.plist directly. Document both approaches.

## DEFERRED SCOPE
- Automating the pipeline as a `make release` target or shell script — the documented
  manual process is the foundation; automation can be layered on top later.
- GitHub Releases integration — uploading the distribution zip to a GitHub Release
  as part of the pipeline.

## DEPENDENCIES
Ticket 15 must be complete (pipeline proven; real commands and values known).

## VERIFICATION
1. Confirm `RELEASING.md` exists at the repo root: `ls RELEASING.md`.
2. Confirm the file contains all required section headers: `grep -E "^## " RELEASING.md` must list Prerequisites, Version Bump, Build, Export, Notarize, Staple, Troubleshooting.
3. Confirm no placeholder text remains: `grep -E "YOUR_|<Your|XXXX" RELEASING.md` must return empty.
4. [Regression guard] Ask a second person (or re-read the document cold) to confirm the steps are complete and unambiguous enough to follow without additional context.
