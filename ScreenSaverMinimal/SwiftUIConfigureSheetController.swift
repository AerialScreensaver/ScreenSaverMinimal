//
//  SwiftUIConfigureSheetController.swift
//  ScreenSaverMinimal
//
//  NSWindowController that hosts the SwiftUI configuration view
//

import Cocoa
import SwiftUI
import OSLog

class SwiftUIConfigureSheetController: NSObject {
    
    private(set) var window: NSWindow?
    private var hostingController: NSHostingController<ConfigurationView>?
    
    override init() {
        super.init()
        setupWindow()
    }
    
    private func setupWindow() {
        // Create the SwiftUI view with close callback
        let configView = ConfigurationView { [weak self] in
            self?.closeConfigureSheet()
        }
        
        // Create the hosting controller
        hostingController = NSHostingController(rootView: configView)
        
        // Create the window
        window = NSWindow(contentViewController: hostingController!)
        window?.title = "ScreenSaver Minimal Preferences"
        window?.styleMask = [.titled, .closable]
        window?.isReleasedWhenClosed = false
        window?.level = .floating
        
        // Center the window
        window?.center()
        
        // Set delegate to handle window events
        window?.delegate = self
    }
    
    private func closeConfigureSheet() {
        // Close the sheet properly
        if let sheetParent = window?.sheetParent {
            sheetParent.endSheet(window!)
        } else {
            window?.close()
        }
    }
}

// MARK: - NSWindowDelegate
extension SwiftUIConfigureSheetController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Ensure color panel is closed
        NSColorPanel.shared.close()
        
        OSLog.info("SwiftUI Configuration window closing")
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        OSLog.info("SwiftUI Configuration window became key")
    }
}
