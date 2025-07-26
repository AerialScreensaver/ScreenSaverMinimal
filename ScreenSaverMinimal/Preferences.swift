//
//  Preferences.swift
//  ScreenSaverMinimal
//
//  Created by Guillaume Louel on 23/06/2020.
//
//  Includes a couple of convenience helpers using the new Swift 5 property wrappers

import Foundation
import ScreenSaver
import OSLog

struct Preferences {
    @Storage(key: "CanvasColor", defaultValue: PreferenceColor(nsColor: NSColor(red: 1, green: 0.0, blue: 0.5, alpha: 1.0)))
    static var canvasColor: PreferenceColor
    
    @SimpleStorage(key: "LogDrawCalls", defaultValue: false)
    static var logDrawCalls: Bool
    
    @SimpleStorage(key: "LogAnimateOneFrameCalls", defaultValue: false)
    static var logAnimateOneFrameCalls: Bool
    
    @SimpleStorage(key: "EnableExitFixOnWillStop", defaultValue: false)
    static var enableExitFixOnWillStop: Bool
}

// MARK: - Helpers

// We make a wrapper to make NSColor (kinda) codable, this may be needed for some types
struct PreferenceColor : Codable {
    var red : CGFloat = 0.0, green: CGFloat = 0.0, blue: CGFloat = 0.0, alpha: CGFloat = 0.0

    var nsColor : NSColor {
        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    init(nsColor : NSColor) {
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    }
}

// This retrieves/store any type of property in our plist as a readable JSON
@propertyWrapper struct Storage<T: Codable> {
    private let key: String
    private let defaultValue: T
    private let module = Bundle.main.bundleIdentifier!
    // TODO: If you want to share settings between your app target and your saver target, you can manually set a value here. Be aware that in Catalina+, your settings will be sandboxed though !

    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            if let userDefaults = ScreenSaverDefaults(forModuleWithName: module) {
                guard let jsonString = userDefaults.string(forKey: key) else {
                    return defaultValue
                }
                guard let jsonData = jsonString.data(using: .utf8) else {
                    return defaultValue
                }
                guard let value = try? JSONDecoder().decode(T.self, from: jsonData) else {
                    return defaultValue
                }
                return value
            }

            return defaultValue
        }
        set {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]

            let jsonData = try? encoder.encode(newValue)
            let jsonString = String(bytes: jsonData!, encoding: .utf8)

            if let userDefaults = ScreenSaverDefaults(forModuleWithName: module) {
                // Set value to UserDefaults
                userDefaults.set(jsonString, forKey: key)

                // We force the sync so the settings are automatically saved
                // This is needed as the System Preferences instance of Aerial
                // is a separate instance from the screensaver ones
                userDefaults.synchronize()
            } else {
                if #available(OSX 10.12, *) {
                    let log = OSLog(subsystem: module, category: "Screensaver")
                    os_log("ScreenSaverMinimal: %{public}@", log: log, type: .error, "UserDefaults set failed for \(key)")
                } else {
                    NSLog("ScreenSaverMinimal: UserDefaults set failed for \(key)")
                }
            }
        }
    }
}

// This retrieves store "simple" types that are natively storable on plists
@propertyWrapper struct SimpleStorage<T> {
    private let key: String
    private let defaultValue: T
    private let module = Bundle.main.bundleIdentifier!
    // TODO: If you want to share settings between your app target and your saver target, you can manually set a value here. Be aware that in Catalina+, your settings will be sandboxed though !
    
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            if let userDefaults = ScreenSaverDefaults(forModuleWithName: module) {
                return userDefaults.object(forKey: key) as? T ?? defaultValue
            }

            return defaultValue
        }
        set {
            if let userDefaults = ScreenSaverDefaults(forModuleWithName: module) {
                userDefaults.set(newValue, forKey: key)

                userDefaults.synchronize()
            }
        }
    }
}
