STATUS: done
COMPLETED: 2026-06-11 | commit: d5495b0
COMMITS: d5495b0

TICKET 06: Migrate Config.swift and SettingItem.swift to Swift 5
Milestone: Swift Syntax Migration
Domain: Swift migration
Priority: P0 — must complete before Ticket 07 can verify a clean build
Effort: S
PRD: Section 3.2 | Blockers: none

## HANDOFF BLOCK
PRD Section: 3.2 — Swift Language Migration
Why: Config.swift and SettingItem.swift use NSData and [String: AnyObject] (both
     removed in Swift 3+) and rely on SwiftyJSON v2 initializer syntax that changed
     in v5. DNSMenuItem.swift requires no changes.

## DESCRIPTION
Apply Swift 2 → Swift 5 changes to Config.swift and SettingItem.swift. The changes
are fewer than AppDelegate.swift but include a SwiftyJSON API change that requires
careful handling: the JSON(data:) initializer is now throwing in v5.

## ACCEPTANCE CRITERIA
- [x] `NSData` replaced with `Data` in Config.swift init parameter
- [x] `[String: AnyObject]` replaced with `[String: Any]` in both files
- [x] SwiftyJSON v5 initializer used correctly in Config.swift
      (`JSON(data)` where data is `Data`, not `NSData`)
- [x] Config.export() still produces valid JSON output
- [x] Both files compile with zero errors in Xcode 16.x
- [x] DNSMenuItem.swift is not modified (it requires no changes)

## IMPLEMENTATION DETAIL
Config.swift — init change:

  // Before (Swift 2 / SwiftyJSON v2):
  init(data: NSData) {
      ...
      let json = JSON(data: data)

  // After (Swift 5 / SwiftyJSON v5):
  init(data: Data) {
      ...
      let json = (try? JSON(data: data)) ?? JSON.null

SwiftyJSON v5 makes JSON(data:) a throwing initializer. Use try? with a fallback
to JSON.null to preserve the existing fail-soft behaviour (the app prints a message
and continues, rather than crashing on malformed JSON).

Config.export() — AnyObject → Any:

  // Before:
  func export() -> String? {
      var settings: [[String: AnyObject]] = []
      for setting in self.settings! {
          settings.append(setting.export())
      }
      let data: [String: AnyObject] = [...]
      return JSON(data).rawString()

  // After:
  func export() -> String? {
      var settings: [[String: Any]] = []
      for setting in self.settings! {
          settings.append(setting.export())
      }
      let data: [String: Any] = [...]
      return (try? JSON(data: JSONSerialization.data(withJSONObject: data))).flatMap { $0.rawString() }

  // Simpler alternative for export():
      if let jsonData = try? JSONSerialization.data(withJSONObject: data),
         let jsonString = String(data: jsonData, encoding: .utf8) {
          return jsonString
      }
      return nil

SettingItem.swift — AnyObject → Any:

  // Before:
  func export() -> [String: AnyObject] {
      var data: [String: AnyObject] = [...]

  // After:
  func export() -> [String: Any] {
      var data: [String: Any] = [...]

## DEFERRED SCOPE
- Replacing the Config class with a Codable struct for type-safe JSON parsing —
  a cleaner architecture, but out of scope for this migration.
- Removing optional chaining and force-unwraps throughout — safety improvement
  deferred to a future clean-up pass.

## DEPENDENCIES
Ticket 04 must be complete (audit findings confirmed).
Can be worked in parallel with Ticket 05.

## VERIFICATION
1. Run `xcodebuild -workspace DNSSwitcher.xcworkspace -scheme DNSSwitcher -configuration Debug build 2>&1 | grep -E "error:|Config.swift|SettingItem.swift"` — must show zero errors in these files.
2. Confirm `git diff DNSSwitcher/Config.swift | grep "^+" | grep "NSData"` returns empty (no NSData remains).
3. Confirm `git diff DNSSwitcher/SettingItem.swift | grep "^+" | grep "AnyObject"` returns empty (no AnyObject remains).
4. [Regression guard] Confirm DNSMenuItem.swift is untouched — `git diff DNSSwitcher/DNSMenuItem.swift` shows no changes.

## RESOLUTION
Commit: d5495b0 — feat: migrate Config.swift and SettingItem.swift to Swift 5 (#006)

Files changed:
- DNSSwitcher/Config.swift — NSData→Data in init, JSON(data:) wrapped with try?/JSON.null, AnyObject→Any in export(), JSONSerialization replaces SwiftyJSON for output
- DNSSwitcher/SettingItem.swift — AnyObject→Any in export() return type and local dict
- DNSSwitcher/AppDelegate.swift — removed leftover `as NSData` cast at Config(data:) call site

## SESSION AUDIT
Captured: 2026-06-11

### Decisions Made
- [D1] Config.export() rewrites JSON output using JSONSerialization (simpler alternative) rather than wrapping SwiftyJSON — chosen because configData is already Data at the call site, making the SwiftyJSON path redundant.

### Scope Changes
- [S1] Added: fix AppDelegate.swift:171 — `as NSData` cast was a leftover from Swift 2 that broke the call site once Config.init was updated to accept Data.

### Clarifications Provided
- [C1] The `as NSData` cast in AppDelegate was not listed in the ticket's implementation detail but surfaced as a compile error; fixed as part of this ticket rather than spawning a new one.
