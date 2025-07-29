//
//  ScreenSaverUtilities.swift
//  ScreenSaverMinimal
//
//  Utility functions for the screensaver
//

import Foundation
import AppKit
import Quartz

struct ScreenSaverUtilities {
    
    static func getVersionString() -> String {
        let bundle = Bundle(for: ScreenSaverMinimalView.self)
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildDate = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "v\(version) (\(buildDate))"
    }
    
    static func instanceInfo(_ instanceNumber: Int) -> String {
        return "(\(instanceNumber)/\(InstanceTracker.shared.totalInstances))"
    }
    
    static func formatFrame(_ frame: NSRect) -> String {
        return "(x:\(frame.origin.x), y:\(frame.origin.y), w:\(frame.size.width), h:\(frame.size.height))"
    }
    
    static func isScreenLocked() -> Bool {
        guard let dict = CGSessionCopyCurrentDictionary() as? [String: Any] else {
            return false
        }
        
        let isLocked = dict["CGSSessionScreenIsLocked"] as? Bool ?? false
        return isLocked
    }
}