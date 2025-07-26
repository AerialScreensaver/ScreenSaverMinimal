//
//  SaverTestContentView.swift
//  SaverTest
//
//  Main SwiftUI content view for screensaver testing
//

import SwiftUI

struct SaverTestContentView: View {
    @State private var showingPreferences = false
    private let swiftUISheetController = SwiftUIConfigureSheetController()
    
    var body: some View {
        ScreenSaverRepresentable()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Preferences") {
                        showPreferences()
                    }
                }
            }
            .onAppear {
                // Initial setup if needed
            }
    }
    
    private func showPreferences() {
        if let configWindow = swiftUISheetController.window {
            configWindow.makeKeyAndOrderFront(nil)
            configWindow.styleMask = [.closable, .titled, .miniaturizable]
            
            var frame = configWindow.frame
            frame.origin = configWindow.frame.origin
            configWindow.setFrame(frame, display: true)
        }
    }
}