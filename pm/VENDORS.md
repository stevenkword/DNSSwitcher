# Integration & Secrets Registry

**Version:** 1.0.0
> Last updated: 2026-06-11

| Vendor | Purpose | Phase | Environment | Auth Status | Rate Limit | Notes |
|--------|---------|-------|-------------|-------------|------------|-------|
| Apple Developer Program | Code signing + notarization | 2 | Production | ⏳ Cert needed | N/A | Developer ID Application cert required; app-specific password for notarytool |

## Details

### Apple Developer Program
- **Env var(s):** None (credentials stored in macOS Keychain via `xcrun notarytool store-credentials`)
- **Sandbox vs. Production:** Production only (no sandbox for notarization)
- **Auth verified:** No
- **Webhook secret verified:** N/A
- **Rate limit:** No documented limit for notarization submissions
- **Abstraction interface:** N/A — invoked via `xcrun notarytool` CLI
- **Active implementation:** `xcrun notarytool submit` + `xcrun stapler staple`
- **BLOCKED_BY_OWNER:** Enroll in / verify access to Apple Developer Program → provision Developer ID Application certificate → unblocks Tickets 12, 13, 14
