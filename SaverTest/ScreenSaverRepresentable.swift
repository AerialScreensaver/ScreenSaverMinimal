//
//  ScreenSaverRepresentable.swift
//  SaverTest
//
//  SwiftUI wrapper for ScreenSaverMinimalView
//

import SwiftUI
import AppKit

struct ScreenSaverRepresentable: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeNSView(context: Context) -> ScreenSaverMinimalView {
        let screenSaverView = ScreenSaverMinimalView(frame: NSZeroRect, isPreview: false)
        context.coordinator.screenSaverView = screenSaverView
        
        // Start animation after a brief delay to ensure view is properly set up
        DispatchQueue.main.async {
            screenSaverView.startAnimation()
        }
        
        return screenSaverView
    }
    
    func updateNSView(_ nsView: ScreenSaverMinimalView, context: Context) {
        // Update the view if needed
        nsView.needsDisplay = true
    }
    
    static func dismantleNSView(_ nsView: ScreenSaverMinimalView, coordinator: Coordinator) {
        // Stop animation when view is being dismantled
        nsView.stopAnimation()
    }
    
    class Coordinator {
        var screenSaverView: ScreenSaverMinimalView?
    }
}