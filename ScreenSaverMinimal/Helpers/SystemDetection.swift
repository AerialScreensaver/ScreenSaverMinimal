//
//  SystemDetection.swift
//  ScreenSaverMinimal
//
//  System detection and process information utilities
//

import Foundation
import AppKit
import Darwin
import OSLog

struct SystemDetection {
    
    static func isSystemSettingsRunning() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            if let bundleID = app.bundleIdentifier {
                // Check for System Settings on macOS Ventura+
                if bundleID == "com.apple.systempreferences" || bundleID == "com.apple.Preferences" {
                    OSLog.info("isSystemSettingsRunning: System Settings is running")
                    return true
                }
            }
        }
        
        OSLog.info("isSystemSettingsRunning: System Settings is NOT running")
        return false
    }
    
    static func logProcessInfo(instanceNumber: Int) {
        // Current process info
        let processInfo = ProcessInfo.processInfo
        let currentPID = processInfo.processIdentifier
        let processName = processInfo.processName
        let processPath = processInfo.arguments.first ?? "unknown"
        
        // Parent process info
        let parentPID = getppid()
        var parentName = "unknown"
        var parentBundleID = "unknown"
        
        if let parentApp = NSRunningApplication(processIdentifier: parentPID) {
            parentName = parentApp.localizedName ?? "unknown"
            parentBundleID = parentApp.bundleIdentifier ?? "unknown"
        }
        
        // Bundle context
        let mainBundle = Bundle.main
        let ourBundle = Bundle(for: ScreenSaverMinimalView.self)
        
        let instanceInfo = ScreenSaverUtilities.instanceInfo(instanceNumber)
        OSLog.info("init \(instanceInfo): Process Info:")
        OSLog.info("  Current: PID=\(currentPID), name=\(processName), path=\(processPath)")
        OSLog.info("  Parent: PID=\(parentPID), name=\(parentName), bundleID=\(parentBundleID)")
        OSLog.info("  MainBundle: \(mainBundle.bundleIdentifier ?? "nil") at \(mainBundle.bundlePath)")
        OSLog.info("  OurBundle: \(ourBundle.bundleIdentifier ?? "nil") at \(ourBundle.bundlePath)")
    }
}
