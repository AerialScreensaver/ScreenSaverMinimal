//
//  ScreenSaverRepresentable.swift
//  SaverTest
//
//  SwiftUI wrapper for ScreenSaverMinimalView
//

import SwiftUI
import AppKit

struct ScreenSaverRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> ScreenSaverMinimalView {
        let screenSaverView = ScreenSaverMinimalView(frame: NSZeroRect, isPreview: false)
        return screenSaverView
    }
    
    func updateNSView(_ nsView: ScreenSaverMinimalView, context: Context) {
        // Update the view if needed
        nsView.needsDisplay = true
    }
}