//
//  Logger.swift
//  ScreenSaverMinimal
//
//  Logging utilities for the screensaver
//

import Foundation
import os.log

// Helper to log to Console
// Open Console.app to see the logs and filter by "SSM (P:"
extension OSLog {
    static let screenSaver = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "ScreenSaverMinimal", category: "Screensaver")
    
    static func info(_ message: String) {
        let pid = ProcessInfo.processInfo.processIdentifier
        os_log("SSM (P:%d): %{public}@", log: .screenSaver, type: .default, pid, message)
    }
}