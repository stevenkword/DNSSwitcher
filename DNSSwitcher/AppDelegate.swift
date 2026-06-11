//
//  AppDelegate.swift
//  DNSSwitcher
//
//  Created by Matthew McNeeney on 02/06/2016.
//  Copyright © 2016 mattmc. All rights reserved.
//

import Cocoa
import SwiftyJSON

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var versionItem: NSMenuItem!
    @IBOutlet weak var interfaceMenu: NSMenu!

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let configFilePath = NSHomeDirectory() + "/.dnsswitcher.json"

    var config: Config?
    var lastConfigFileUpdate: Date?

    // MARK: - Application lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // Add status bar icon
        let menuIcon = NSImage(named: "MenuIcon")
        menuIcon?.isTemplate = true
        statusItem.image = menuIcon
        statusItem.menu = menu

        // Set version number
        if let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String {
            self.versionItem.title = "v\(version)"
        }

        // Create default configuration file if required
        if !FileManager.default.fileExists(atPath: self.configFilePath) {
            self.createDefaultConfigFile()
        }

        // Make sure we know whenever the menu is opened
        self.menu.delegate = self

        // Load available network interfaces
        self.loadNetworkInterfaces()

        // Load the configuration file
        self.initMenu()
    }


    // MARK: - Network interfaces

    func loadNetworkInterfaces() {
        let command: [String] = [ "networksetup", "-listallnetworkservices" ]
        let (result, output) = runCommand(command)
        if result != 0 {
            print("Critical error: could not load network services")
            self.quit(nil)
            return
        }
        for interface in output.components(separatedBy: "\n") {
            // Ignore disabled interfaces
            if interface.contains("*") || interface == "" {
                continue
            }
            // Add the network interface to the interfaces menu
            let interfaceItem = NSMenuItem(title: interface, action: #selector(AppDelegate.setInterface(_:)), keyEquivalent: "")
            self.interfaceMenu.addItem(interfaceItem)
        }
    }

    func highlightEnabledInterface() {
        var interfaceSelected = false
        for item in self.interfaceMenu.items {
            item.state = .off
            if item.title == self.config?.interface {
                item.state = .on
                interfaceSelected = true
            }
        }
        /* Failover - if no interface has been selected, set
         * the first one */
        if !interfaceSelected {
            guard !self.interfaceMenu.items.isEmpty else {
                return
            }
            self.config?.interface = self.interfaceMenu.items[0].title
            self.interfaceMenu.items[0].state = .on
        }
    }

    @objc func setInterface(_ item: NSMenuItem) {
        self.config?.interface = item.title
        self.highlightEnabledInterface()
        self.saveLatestConfig()
    }


    // MARK: - DNS settings

    func clearServers() {
        for item in self.menu.items {
            if item is DNSMenuItem {
                self.menu.removeItem(item)
            }
        }
    }

    func highlightCurrentDNSServers() {
        let command: [String] = [ "networksetup", "-getdnsservers", self.config!.interface! ]
        let (result, output) = self.runCommand(command)
        if result != 0 {
            print("Error fetching current DNS servers")
            return
        }
        var servers: [String] = []
        for s in output.components(separatedBy: "\n") {
            if s != "" {
                servers.append(s)
            }
        }

        // Highlight the selected DNS servers in the menu
        for item in self.menu.items {
            if item is DNSMenuItem {
                item.state = .off
                let setting = (item as! DNSMenuItem).setting!
                if setting.servers! == servers {
                    item.state = .on
                }
            }
        }
    }

    @objc func setDNSServers(_ item: DNSMenuItem) {
        // Change the DNS settings
        let command: [String] = [ "networksetup", "-setdnsservers", self.config!.interface! ] + item.setting.servers!
        let (result, output) = runCommand(command)
        if result != 0 {
            self.showAlert("Error", message: "DNS change failed with exit code \(result): \(output)", style: .critical)
        }
        else {
            self.showAlert("DNS Changed", message: "Your DNS settings have been updated successfully.", style: .warning)
        }
    }


    // MARK: - Dropdown menu

    func initMenu() {

        guard let configData = try? Data(contentsOf: URL(fileURLWithPath: self.configFilePath)) else {
            print("Critical error: configuration file failed to load")
            self.quit(nil)
            return
        }

        // Create the configuration object
        self.config = Config(data: configData)

        // Clear existing servers from the menu
        self.clearServers()

        // Add the new list of servers to the menu
        for setting in self.config!.settings!.reversed() {

            // Add the name of the DNS server as the menu title
            let item = DNSMenuItem(title: setting.name!, action: nil, keyEquivalent: "")
            item.setting = setting

            // Create the submenu
            let submenu = NSMenu()

            // Add a load button
            let loadItem = DNSMenuItem(title: "Load", action: #selector(AppDelegate.setDNSServers(_:)), keyEquivalent: "")
            loadItem.setting = setting
            submenu.addItem(loadItem)

            // Add a separator
            submenu.addItem(NSMenuItem.separator())

            // Add the list of servers
            let serverTitleItem = NSMenuItem(title: "Servers:", action: nil, keyEquivalent: "")
            serverTitleItem.isEnabled = false
            submenu.addItem(serverTitleItem)
            for server in setting.servers! {
                let item = NSMenuItem(title: server, action: nil, keyEquivalent: "")
                item.indentationLevel = 1
                item.isEnabled = false
                submenu.addItem(item)
            }

            // Add the submenu to the menu item
            item.submenu = submenu

            // Add the menu item to the top of the menu
            self.menu.insertItem(item, at: 0)
        }

        /* Highlight the enabled interface */
        self.highlightEnabledInterface()

        /* Fetch the current DNS settings and highlight the
         * selected setting in the menu if appropriate */
        self.highlightCurrentDNSServers()
    }

    func menuWillOpen(_ menu: NSMenu) {
        /* Only initialise the menu if the configuration has changed */
        if !self.checkForConfigUpdate() {
            /* In case the DNS servers have been changed, highlight the selected ones now */
            self.highlightCurrentDNSServers()
            return
        }

        /* Initialise the dropdown menu */
        self.initMenu()
    }


    // MARK: - Configuration file

    func createDefaultConfigFile() {
        // If the file doesn't exist, create it using the default
        if !FileManager.default.fileExists(atPath: self.configFilePath) {
            let defaultFilePath = Bundle.main.path(forResource: "dnsswitcher.default", ofType: "json")
            do {
                try FileManager.default.copyItem(atPath: defaultFilePath!, toPath: self.configFilePath)
            }
            catch {
                print("Critical error: failed to create default config file")
                self.quit(nil)
            }
        }
        // Else copy the contents of the default to the existing file
        let defaultFilePath = Bundle.main.path(forResource: "dnsswitcher.default", ofType: "json")
        if let data = try? Data(contentsOf: URL(fileURLWithPath: defaultFilePath!)) {
            /*
             * Symlink guard: resolve the real destination before writing. If configFilePath
             * has been replaced by a symlink pointing elsewhere, writing would silently
             * overwrite an arbitrary file. We compare the resolved path against the
             * standardized (non-symlink-followed) path; a mismatch means a symlink is
             * in play and we must abort rather than follow it.
             */
            let configURL = URL(fileURLWithPath: self.configFilePath)
            let resolvedURL = configURL.resolvingSymlinksInPath()
            let expectedURL = configURL.standardizedFileURL
            guard resolvedURL == expectedURL else {
                print("Security: config path resolves to a different location via symlink — refusing to overwrite target")
                return
            }
            try? data.write(to: configURL)
        }
    }

    func saveLatestConfig() {
        if let data = self.config?.export() {
            do {
                try data.write(toFile: self.configFilePath, atomically: true, encoding: .utf8)
            }
            catch {
                print("Error saving configuration file")
            }
        }
    }

    func checkForConfigUpdate() -> Bool {
        // Check when the configuration file was last modified
        var configFileAttributes: [FileAttributeKey: Any]?
        do {
            configFileAttributes = try FileManager.default.attributesOfItem(atPath: self.configFilePath)
        }
        catch _ {
            // Failover - reload the configuration file
            return true
        }
        guard let lastModification = configFileAttributes?[FileAttributeKey.modificationDate] as? Date else {
            // Failover - reload the configuration file
            return true
        }

        // This may be the first load
        if self.lastConfigFileUpdate == nil {
            self.lastConfigFileUpdate = lastModification
            return true
        }

        // Compare the modification dates
        let updateNeeded = lastModification > self.lastConfigFileUpdate!
        self.lastConfigFileUpdate = lastModification
        return updateNeeded
    }


    // MARK: - Actions

    @IBAction func editServers(_ sender: Any) {
        NSWorkspace.shared.open(URL(fileURLWithPath: self.configFilePath))
    }

    @IBAction func restoreDefaultServers(_ sender: Any) {
        self.createDefaultConfigFile()
        self.initMenu()
    }

    @IBAction func about(_ sender: Any) {
        if let url = Bundle.main.infoDictionary!["Product Homepage"] as? String {
            NSWorkspace.shared.open(URL(string: url)!)
        }
    }

    @IBAction func quit(_ sender: Any?) {
        NSStatusBar.system.removeStatusItem(statusItem)
        NSApp.terminate(self)
    }


    // MARK: - Helpers

    func showAlert(_ title: String, message: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func runCommand(_ args: [String]) -> (result: Int32, output: String) {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return (task.terminationStatus, output)
    }

}
