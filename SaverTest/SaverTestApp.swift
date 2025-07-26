//
//  SaverTestApp.swift
//  SaverTest
//
//  SwiftUI App structure for screensaver testing
//

import SwiftUI

@main
struct SaverTestApp: App {
    var body: some Scene {
        WindowGroup {
            SaverTestContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
    }
}