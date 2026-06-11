STATUS: blocked
BLOCKED_BY_TICKET: Ticket 04

TICKET 05: Migrate AppDelegate.swift to Swift 5
Milestone: Swift Syntax Migration
Domain: Swift migration
Priority: P0 — largest and most complex source file; gates Ticket 07
Effort: M
PRD: Section 3.2 | Blockers: none

## HANDOFF BLOCK
PRD Section: 3.2 — Swift Language Migration
Why: AppDelegate.swift uses ~25 deprecated or removed Swift 2 APIs. It is the largest
     file and contains all the system API calls (NSTask, NSFileManager, NSWorkspace,
     etc.) that changed significantly between Swift 2 and Swift 5.

## DESCRIPTION
Apply all Swift 2 → Swift 5 changes identified in Ticket 04 to AppDelegate.swift.
This includes renaming Foundation types, updating method signatures to use the `_`
external label convention required by modern Swift/ObjC bridging, and adding `@objc`
to methods referenced via `#selector`.

## ACCEPTANCE CRITERIA
- [ ] All NS-prefixed types replaced with their Swift 5 equivalents (see list below)
- [ ] `NSTask` replaced with `Process`, `NSPipe` replaced with `Pipe`
- [ ] `NSDate` replaced with `Date`, `NSComparisonResult` replaced with `ComparisonResult`
- [ ] `NSBundle.mainBundle()` replaced with `Bundle.main` at all occurrences
- [ ] `NSFileManager.defaultManager()` replaced with `FileManager.default` at all occurrences
- [ ] `NSWorkspace.sharedWorkspace()` replaced with `NSWorkspace.shared` at all occurrences
- [ ] `componentsSeparatedByString` replaced with `components(separatedBy:)`
- [ ] `containsString` replaced with `contains`
- [ ] `item.state = 0/1` replaced with `item.state = .off/.on`
- [ ] `NSAlertStyle.CriticalAlertStyle` replaced with `NSAlert.Style.critical`
- [ ] `NSAlertStyle.WarningAlertStyle` replaced with `NSAlert.Style.warning`
- [ ] `config!.settings!.reverse()` replaced with `config!.settings!.reversed()`
- [ ] `self.menu.insertItem(item, atIndex: 0)` replaced with `self.menu.insertItem(item, at: 0)`
- [ ] `addButtonWithTitle("OK")` replaced with `addButton(withTitle: "OK")`
- [ ] `item.enabled = false` replaced with `item.isEnabled = false`
- [ ] `setInterface` and `setDNSServers` marked `@objc` (required for #selector)
- [ ] NSApplicationDelegate and NSMenuDelegate method signatures updated (external `_` label)
- [ ] `func applicationDidFinishLaunching(aNotification: NSNotification)` signature updated
- [ ] `NSString(data: data, encoding: NSUTF8StringEncoding) as! String` updated to `String(data: data, encoding: .utf8)!`
- [ ] File compiles with zero errors in Xcode 16.x (warnings acceptable but should be noted)

## IMPLEMENTATION DETAIL
Key method signature changes required for protocol conformance:

  // Before (Swift 2):
  func applicationDidFinishLaunching(aNotification: NSNotification) { ... }
  func menuWillOpen(menu: NSMenu) { ... }
  func setInterface(item: NSMenuItem) { ... }
  func setDNSServers(item: DNSMenuItem) { ... }

  // After (Swift 5):
  func applicationDidFinishLaunching(_ aNotification: Notification) { ... }
  func menuWillOpen(_ menu: NSMenu) { ... }
  @objc func setInterface(_ item: NSMenuItem) { ... }
  @objc func setDNSServers(_ item: DNSMenuItem) { ... }

runCommand function — full replacement:

  func runCommand(_ args: [String]) -> (result: Int32, output: String) {
      let task = Process()
      task.launchPath = "/usr/bin/env"
      task.arguments = args
      let pipe = Pipe()
      task.standardOutput = pipe
      task.launch()
      task.waitUntilExit()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: data, encoding: .utf8) ?? ""
      return (task.terminationStatus, output)
  }

NSWorkspace.sharedWorkspace().openFile — no direct Swift 5 equivalent with the same
signature; use NSWorkspace.shared.open(URL(fileURLWithPath: path)) instead:

  // Before:
  NSWorkspace.sharedWorkspace().openFile(self.configFilePath)
  // After:
  NSWorkspace.shared.open(URL(fileURLWithPath: self.configFilePath))

## DEFERRED SCOPE
- Replacing force-unwraps (!) with safe optional handling — improves crash safety
  but is not required for compilation or Apple Silicon support.
- Adopting @MainActor for UI update methods — Swift 6 strict concurrency concern,
  deferred to a future clean-up pass.

## DEPENDENCIES
Ticket 04 must be complete (audit findings confirmed).

## VERIFICATION
1. Run `xcodebuild -workspace DNSSwitcher.xcworkspace -scheme DNSSwitcher -configuration Debug build 2>&1 | grep -E "error:|AppDelegate"` — must show zero errors in AppDelegate.swift.
2. Confirm `git diff DNSSwitcher/AppDelegate.swift | grep "^+" | grep -E "NSTask|NSPipe|NSBundle|NSFileManager|NSDate|NSWorkspace.sharedWorkspace|addButtonWithTitle|NSUTF8StringEncoding"` returns empty (no old APIs remain).
3. Confirm `@objc` is present before `setInterface` and `setDNSServers` function definitions.
4. [Regression guard] Confirm Config.swift, DNSMenuItem.swift, and SettingItem.swift are untouched — `git diff DNSSwitcher/Config.swift DNSSwitcher/DNSMenuItem.swift DNSSwitcher/SettingItem.swift` shows no changes.
