STATUS: todo

TICKET 11: Confirm Universal Binary with lipo
Milestone: Xcode Project Settings
Domain: Build verification
Priority: P0 — final gate before notarization work; proves Apple Silicon support
Effort: S
PRD: Section 3.3, Section 8 | Blockers: none

## HANDOFF BLOCK
PRD Section: 3.3 — Universal Binary Build; Section 8 — success metric
Why: `lipo -info` is the authoritative tool for confirming that a binary contains
     both arm64 and x86_64 slices. Passing this check closes Milestone 3 and proves
     the Apple Silicon migration is technically complete. Notarization is the final
     distribution step.

## DESCRIPTION
Run `lipo -info` and `lipo -detailed_info` on the DNSSwitcher binary from the
archive produced in Ticket 10. Confirm both arm64 and x86_64 slices are present.
Also verify the SwiftyJSON framework inside the app bundle is universal.

## ACCEPTANCE CRITERIA
- [ ] `lipo -info` on DNSSwitcher binary shows both `arm64` and `x86_64`
- [ ] `lipo -info` on the embedded SwiftyJSON framework binary (if present) also
      shows both architectures
- [ ] `file` command confirms `Mach-O universal binary with 2 architectures`
- [ ] The findings are recorded in this ticket's RESOLUTION section

## IMPLEMENTATION DETAIL
Run these commands against the archive from Ticket 10:

  BINARY="build/DNSSwitcher.xcarchive/Products/Applications/DNSSwitcher.app/Contents/MacOS/DNSSwitcher"
  
  # Confirm universal binary
  lipo -info "$BINARY"
  # Expected: Architectures in the fat file: DNSSwitcher are: x86_64 arm64
  
  # Detailed slice info
  lipo -detailed_info "$BINARY"
  
  # Verify with file command
  file "$BINARY"
  # Expected: Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64] [arm64:Mach-O 64-bit executable arm64]

Also check the SwiftyJSON framework if it is embedded as a binary (as opposed to
compiled from source at build time):

  find build/DNSSwitcher.xcarchive -name "SwiftyJSON" -not -name "*.swift" | head -1 | xargs lipo -info 2>/dev/null || echo "SwiftyJSON compiled from source — no pre-built binary to check"

If the Pods project compiles SwiftyJSON from source (likely for a source pod), the
architecture is determined by the main build settings — the main binary check is
sufficient.

## DEFERRED SCOPE
- Running on physical Apple Silicon hardware to confirm native launch (no Rosetta
  activity monitor indicator) — recommended but requires hardware access.

## DEPENDENCIES
Ticket 10 must be complete (archive produced).

## VERIFICATION
1. Run `lipo -info` on the DNSSwitcher binary — output must contain both `x86_64` and `arm64`.
2. Run `file` on the binary — output must say `Mach-O universal binary with 2 architectures`.
3. Record the exact lipo output in the RESOLUTION section of this ticket.
4. [Regression guard] Confirm the app bundle structure is intact: `ls build/DNSSwitcher.xcarchive/Products/Applications/DNSSwitcher.app/Contents/` must show `Info.plist`, `MacOS/`, and `Resources/`.
