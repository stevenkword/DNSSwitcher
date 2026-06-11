STATUS: done
COMPLETED: 2026-06-11 | commit: 3f41dbd
COMMITS: 3f41dbd

TICKET 04: Audit Source Files for Swift 2 Incompatibilities
Milestone: Swift Syntax Migration
Domain: Analysis
Priority: P0 — produces the authoritative change list for Tickets 05 and 06
Effort: S
PRD: Section 3.2 | Blockers: none

## HANDOFF BLOCK
PRD Section: 3.2 — Swift Language Migration
Why: The four source files use Swift 2 APIs and idioms throughout. Before making
     any changes, a complete inventory of every deprecated or removed symbol is
     needed so that Tickets 05 and 06 can be executed as mechanical find-and-replace
     operations rather than exploratory work.

## DESCRIPTION
Read all four source files and produce a categorised list of every Swift 2 construct
that must change. The output of this ticket is a written inventory appended to this
file in a FINDINGS section. No code changes are made in this ticket.

## ACCEPTANCE CRITERIA
- [ ] All four source files read in full: AppDelegate.swift, Config.swift,
      DNSMenuItem.swift, SettingItem.swift
- [ ] Every Swift 2 API call, type name, and function signature issue is listed
      with its file name and the required Swift 5 replacement
- [ ] SwiftyJSON v5 API differences from v2 are noted separately (the initializer
      and rawString changes affect Config.swift and SettingItem.swift)
- [ ] A count of total changes per file is recorded

## IMPLEMENTATION DETAIL
Known Swift 2 → Swift 5 changes identified during planning (verify against source):

AppDelegate.swift (high change density):
  - NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    → NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  - NSHomeDirectory().stringByAppendingString("/.dnsswitcher.json")
    → NSHomeDirectory() + "/.dnsswitcher.json"
  - NSBundle.mainBundle() → Bundle.main  (multiple occurrences)
  - NSFileManager.defaultManager() → FileManager.default  (multiple occurrences)
  - NSData(contentsOfFile:) → Data(contentsOf: URL(fileURLWithPath:))
  - output.componentsSeparatedByString("\n") → output.components(separatedBy: "\n")
  - interface.containsString("*") → interface.contains("*")
  - item.state = 0 / item.state = 1 → item.state = .off / item.state = .on
  - NSAlertStyle.CriticalAlertStyle → NSAlert.Style.critical
  - NSAlertStyle.WarningAlertStyle → NSAlert.Style.warning
  - config!.settings!.reverse() → config!.settings!.reversed()
  - self.menu.insertItem(item, atIndex: 0) → self.menu.insertItem(item, at: 0)
  - NSDate → Date
  - NSComparisonResult.OrderedDescending → ComparisonResult.orderedDescending
  - NSWorkspace.sharedWorkspace() → NSWorkspace.shared  (multiple occurrences)
  - NSWorkspace.sharedWorkspace().openFile(path) → NSWorkspace.shared.open(URL(fileURLWithPath: path))
  - NSWorkspace.sharedWorkspace().openURL(url) → NSWorkspace.shared.open(url)
  - NSURL(string:) → URL(string:)
  - NSTask() → Process()
  - NSPipe() → Pipe()
  - NSString(data: data, encoding: NSUTF8StringEncoding) as! String
    → String(data: data, encoding: .utf8)!
  - alert.addButtonWithTitle("OK") → alert.addButton(withTitle: "OK")
  - item.enabled = false → item.isEnabled = false
  - func applicationDidFinishLaunching(aNotification: NSNotification)
    → func applicationDidFinishLaunching(_ aNotification: Notification)
  - func menuWillOpen(menu: NSMenu) → func menuWillOpen(_ menu: NSMenu)
  - func setInterface(item: NSMenuItem) → @objc func setInterface(_ item: NSMenuItem)
  - func setDNSServers(item: DNSMenuItem) → @objc func setDNSServers(_ item: DNSMenuItem)

Config.swift (medium change density):
  - init(data: NSData) → init(data: Data)
  - [String: AnyObject] → [String: Any]
  - JSON(data: data) [SwiftyJSON v2] → try? JSON(data: data) [SwiftyJSON v5]
  - JSON(data).rawString() → use JSONSerialization or JSON(data).rawString() with options

SettingItem.swift (low change density):
  - [String: AnyObject] → [String: Any]
  - SwiftyJSON arrayValue usage should be compatible with v5

DNSMenuItem.swift: No changes required (no deprecated APIs used).

## DEFERRED SCOPE
- Modernising optional chaining and force-unwrap patterns throughout the code
  (safety improvement, not required for compilation).
- Adopting @MainActor and Swift concurrency — out of scope for this migration.

## DEPENDENCIES
Ticket 03 must be complete (SwiftyJSON v5 installed, so v5 API surface is known).

## VERIFICATION
1. Read AppDelegate.swift and confirm every item in the IMPLEMENTATION DETAIL list above is present in the file.
2. Read Config.swift and confirm `NSData` and `[String: AnyObject]` are present.
3. Read SettingItem.swift and confirm `[String: AnyObject]` is present.
4. [Regression guard] Confirm DNSMenuItem.swift is unchanged — `git diff DNSSwitcher/DNSMenuItem.swift` should show no diff at this point.

---

## FINDINGS

Audit completed 2026-06-11. All four files read in full.

### AppDelegate.swift — 51 line edits required

**A. Class renames (NS-prefix removal)**

| Line | Swift 2 | Swift 5 |
|------|---------|---------|
| 23 | `var lastConfigFileUpdate: NSDate?` | `var lastConfigFileUpdate: Date?` |
| 274 | `as? NSDate` | `as? Date` |
| 327 | `NSTask()` | `Process()` |
| 330 | `NSPipe()` | `Pipe()` |

**B. Singleton / shared-instance access**

| Line(s) | Swift 2 | Swift 5 |
|---------|---------|---------|
| 19, 310 | `NSStatusBar.systemStatusBar()` | `NSStatusBar.system` |
| 36, 238, 248, 304 | `NSBundle.mainBundle()` | `Bundle.main` |
| 41, 237, 239, 268 | `NSFileManager.defaultManager()` | `FileManager.default` |
| 295, 305 | `NSWorkspace.sharedWorkspace()` | `NSWorkspace.shared` |

**C. String method renames**

| Line(s) | Swift 2 | Swift 5 |
|---------|---------|---------|
| 20 | `.stringByAppendingString("/.dnsswitcher.json")` | `+ "/.dnsswitcher.json"` |
| 66, 119, 140 | `.componentsSeparatedByString("\n")` | `.components(separatedBy: "\n")` |
| 68 | `.containsString("*")` | `.contains("*")` |

**D. File and data I/O renames**

| Line(s) | Swift 2 | Swift 5 |
|---------|---------|---------|
| 19 | `.statusItemWithLength(-1)` | `.statusItem(withLength: NSStatusItem.variableLength)` |
| 41, 237 | `.fileExistsAtPath(_:)` | `.fileExists(atPath:)` |
| 164, 249 | `NSData(contentsOfFile: path)` | `try? Data(contentsOf: URL(fileURLWithPath: path))` |
| 238 | `Bundle.pathForResource(_:ofType:)` | `Bundle.path(forResource:ofType:)` |
| 239 | `.copyItemAtPath(_:toPath:)` | `.copyItem(atPath:toPath:)` |
| 250 | `NSData.writeToFile(_:atomically:)` | `Data.write(to: URL, options:)` (throws) |
| 256 | `String.writeToFile(_:atomically:encoding:)` | `String.write(toFile:atomically:encoding:)` |
| 268 | `.attributesOfItemAtPath(_:)` | `.attributesOfItem(atPath:)` |
| 295 | `NSWorkspace.openFile(_:)` | `NSWorkspace.open(URL(fileURLWithPath:))` |
| 305 | `NSWorkspace.openURL(_:)` | `NSWorkspace.open(_:)` |
| 305 | `NSURL(string:)` | `URL(string:)` |

**E. Encoding constants**

| Line(s) | Swift 2 | Swift 5 |
|---------|---------|---------|
| 256, 335 | `NSUTF8StringEncoding` | `.utf8` (`String.Encoding.utf8`) |
| 335 | `NSString(data: d, encoding: NSUTF8StringEncoding) as! String` | `String(data: d, encoding: .utf8)!` |

**F. Attributes dictionary type change**

| Line | Swift 2 | Swift 5 |
|------|---------|---------|
| 266 | `var configFileAttributes: [String: AnyObject]?` | `var configFileAttributes: [FileAttributeKey: Any]?` |
| 274 | `configFileAttributes?[NSFileModificationDate]` | `configFileAttributes?[.modificationDate]` |

**G. Menu item state enum**

| Line(s) | Swift 2 | Swift 5 |
|---------|---------|---------|
| 80, 83, 91, 128, 131 | `item.state = 0` / `item.state = 1` | `item.state = .off` / `item.state = .on` |

**H. Menu item enabled property**

| Line(s) | Swift 2 | Swift 5 |
|---------|---------|---------|
| 196, 200 | `item.enabled = false` | `item.isEnabled = false` |

**I. Enum renames**

| Line(s) | Swift 2 | Swift 5 |
|---------|---------|---------|
| 143, 152 | `NSAlertStyle.CriticalAlertStyle` | `NSAlert.Style.critical` |
| 155 | `NSAlertStyle.WarningAlertStyle` | `NSAlert.Style.warning` |
| 286 | `NSComparisonResult.OrderedDescending` | `ComparisonResult.orderedDescending` |

**J. Collection method renames**

| Line | Swift 2 | Swift 5 |
|------|---------|---------|
| 177 | `.reverse()` (mutating, in-place) | `.reversed()` (returns new sequence; assign back or pass to init) |
| 209 | `insertItem(_:atIndex:)` | `insertItem(_:at:)` |

**K. Function signatures — missing `_` wildcard labels**

In Swift 3+, the first argument no longer gets an implicit external label. Methods called via selectors or as delegate callbacks require `_` or the Objective-C selector will not match.

| Line | Swift 2 | Swift 5 |
|------|---------|---------|
| 27 | `func applicationDidFinishLaunching(aNotification: NSNotification)` | `func applicationDidFinishLaunching(_ aNotification: Notification)` |
| 94 | `func setInterface(item: NSMenuItem)` | `@objc func setInterface(_ item: NSMenuItem)` |
| 137 | `func setDNSServers(item: DNSMenuItem)` | `@objc func setDNSServers(_ item: DNSMenuItem)` |
| 220 | `func menuWillOpen(menu: NSMenu)` | `func menuWillOpen(_ menu: NSMenu)` |
| 294 | `@IBAction func editServers(sender: AnyObject)` | `@IBAction func editServers(_ sender: AnyObject)` |
| 298 | `@IBAction func restoreDefaultServers(sender: AnyObject)` | `@IBAction func restoreDefaultServers(_ sender: AnyObject)` |
| 303 | `@IBAction func about(sender: AnyObject)` | `@IBAction func about(_ sender: AnyObject)` |
| 309 | `@IBAction func quit(sender: AnyObject?)` | `@IBAction func quit(_ sender: AnyObject?)` |
| 317 | `func showAlert(title: String, message: String, style: NSAlertStyle)` | `func showAlert(_ title: String, _ message: String, style: NSAlert.Style)` |
| 326 | `func runCommand(args: [String])` | `func runCommand(_ args: [String])` |

---

### Config.swift — 5 change sites

| Line | Category | Swift 2 | Swift 5 |
|------|----------|---------|---------|
| 17 | Type rename | `init(data: NSData)` | `init(data: Data)` |
| 19 | SwiftyJSON v5 | `let json = JSON(data: data)` | `let json = (try? JSON(data: data)) ?? JSON.null` — v5 init is throwing |
| 50 | Type annotation | `[[String: AnyObject]]` | `[[String: Any]]` |
| 54 | Type annotation | `let data: [String: AnyObject]` | `let data: [String: Any]` |
| 58 | SwiftyJSON v5 | `JSON(data).rawString()` | Unchanged API; verify `rawString()` still returns `String?` against installed v5 |

SwiftyJSON v5 note: `JSON(data:)` now accepts `Data` (not `NSData`) and the initialiser throws — wrap in `try?`. The `rawString()` signature is the same in v5 but the default options differ; confirm it serialises correctly before closing Ticket 06.

---

### SettingItem.swift — 2 change sites

| Line | Category | Swift 2 | Swift 5 |
|------|----------|---------|---------|
| 28 | Type annotation | `func export() -> [String: AnyObject]` | `func export() -> [String: Any]` |
| 29 | Type annotation | `var data: [String: AnyObject]` | `var data: [String: Any]` |

`json["servers"].arrayValue.map({ $0.string! })` on line 20 uses SwiftyJSON API that is identical in v5; no change needed.

---

### DNSMenuItem.swift — 0 changes

Confirmed no deprecated or removed APIs. `git diff DNSSwitcher/DNSMenuItem.swift` shows no diff.

---

### Change count summary

| File | Line edits |
|------|-----------|
| AppDelegate.swift | 51 |
| Config.swift | 5 |
| SettingItem.swift | 2 |
| DNSMenuItem.swift | 0 |
| **Total** | **58** |
