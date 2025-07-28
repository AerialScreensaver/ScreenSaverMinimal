//
//  SaverTestApp.swift
//  SaverTest
//
//  SwiftUI App structure for screensaver testing
//

import SwiftUI

@main
struct SaverTestApp: App {
    init() {
        // Set the app mode flag so ScreenSaverMinimalView knows we're running in the test app
        InstanceTracker.isRunningInApp = true
    }
    
    var body: some Scene {
        WindowGroup {
            SaverTestContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
    }
}