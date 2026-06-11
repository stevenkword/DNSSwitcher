STATUS: blocked
BLOCKED_BY_TICKET: Ticket 03

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
