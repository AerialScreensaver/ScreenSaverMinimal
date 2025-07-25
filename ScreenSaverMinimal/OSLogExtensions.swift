//
//  OSLogExtensions.swift
//  ScreenSaverMinimal
//
//  Shared logging utilities for the screensaver
//

import os.log
import Foundation

// Helper to log to Console
// Open Console.app to see the logs and filter by "ScreenSaverMinimal:"
extension OSLog {
    static let screenSaver = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "ScreenSaverMinimal", category: "Screensaver")
    
    static func info(_ message: String) {
        os_log("ScreenSaverMinimal: %{public}@", log: .screenSaver, type: .default, message)
    }
}
