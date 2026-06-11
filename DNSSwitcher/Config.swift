//
//  Config.swift
//  DNSSwitcher
//
//  Created by Matthew McNeeney on 02/06/2016.
//  Copyright © 2016 mattmc. All rights reserved.
//

import Cocoa
import SwiftyJSON

class Config {

    var settings: [SettingItem]?
    var interface: String?

    init(data: Data) {
        self.settings = []
        let json = (try? JSON(data: data)) ?? JSON.null

        if let interface = json["interface"].string {
            self.interface = interface
        }
        else {
            // Set default interface - "Wi-Fi"
            self.interface = "Wi-Fi"
        }

        guard let settings = json["settings"].array else {
            // No servers found
            print("No configuration settings found")
            return
        }

        for setting in settings {
            let settingItem = SettingItem(json: setting)
            if settingItem.name == nil || settingItem.servers == nil {
                print("Error parsing server item: \(settingItem.name)")
                continue
            }
            self.settings?.append(settingItem)
        }
    }

}

extension Config {

    func export() -> String? {
        var settings: [[String: Any]] = []
        for setting in self.settings! {
            settings.append(setting.export())
        }
        let data: [String: Any] = [
            "interface": self.interface!,
            "settings": settings
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return nil
    }

}
