STATUS: deferred
DECISION: Only needed for distribution to other users. Deferred until the app needs to be shared outside the development machine.

TICKET 12: Provision Developer ID Application Certificate
Milestone: Notarization Setup
Domain: Code signing / Apple Developer Program
Priority: P1 — required for notarization; no owner action needed for Milestones 1–3
Effort: S
PRD: Section 3.4, Section 5 | Blockers: none

## HANDOFF BLOCK
PRD Section: 3.4 — Notarization & Distribution; Section 5 — Apple Developer Program
Why: Notarization requires the binary to be signed with a Developer ID Application
     certificate, which is issued by Apple and associated with an Apple Developer
     Program account (paid, $99/year). Without this certificate, `xcrun notarytool`
     will reject the submission.

## DESCRIPTION
Provision a Developer ID Application certificate from the Apple Developer portal
and install it in the macOS Keychain on the development machine. This is a manual
owner action — it cannot be automated. The certificate is then referenced in
Ticket 13 to configure Xcode code signing.

## ACCEPTANCE CRITERIA
- [ ] Apple Developer Program enrollment is active (verify at developer.apple.com)
- [ ] A "Developer ID Application" certificate is created in Certificates,
      Identifiers & Profiles at developer.apple.com
- [ ] The certificate (.cer file) is downloaded and installed in Keychain Access
- [ ] The private key for the certificate is present in the login or System keychain
      (Keychain Access shows both the certificate and its associated private key)
- [ ] `security find-identity -v -p codesigning` lists a valid
      "Developer ID Application: <Your Name> (TEAM_ID)" identity

## IMPLEMENTATION DETAIL
Steps (owner action required):

1. Sign in to developer.apple.com with your Apple ID.
2. Navigate to Certificates, Identifiers & Profiles → Certificates → + button.
3. Select "Developer ID Application" under the Software section.
4. Follow the prompts to create a Certificate Signing Request (CSR) from Keychain
   Access on your Mac (Keychain Access → Certificate Assistant → Request a Certificate
   From a Certificate Authority).
5. Upload the CSR and download the resulting .cer file.
6. Double-click the .cer file to install it in Keychain Access.
7. Verify: open Keychain Access, search for "Developer ID Application" — you should
   see the certificate with a disclosure triangle showing the private key below it.
8. Run: security find-identity -v -p codesigning
   Expected output includes: "Developer ID Application: Your Name (TEAM_ID)"

If a Developer ID Application certificate already exists and is still valid (check
expiry in Keychain Access), skip creation and just verify it is installed.

Note the Team ID (10-character alphanumeric string like 4U5N6YJ52K) — it is needed
for Ticket 13 (DEVELOPMENT_TEAM setting).

## DEFERRED SCOPE
- Certificate rotation / renewal reminder — Developer ID certificates expire after
  5 years. A calendar reminder should be set, but is out of scope for this ticket.

## DEPENDENCIES
None (owner action; can start independently of Tickets 08–11).

## VERIFICATION
1. Run `security find-identity -v -p codesigning` — must show a non-expired "Developer ID Application: ..." entry.
2. Open Keychain Access, search "Developer ID Application" — the certificate must have a disclosure triangle (private key present). A certificate icon without a triangle means the private key is missing and the cert cannot sign.
3. Note the Team ID from the output and record it in the RESOLUTION section.
4. [Regression guard] Confirm the existing "Mac Developer" certificate (used for local development) is still present and valid — this is used by the Debug signing configuration.
