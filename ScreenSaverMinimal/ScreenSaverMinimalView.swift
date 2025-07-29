//
//  ScreenSaverMinimalView.swift
//  ScreenSaverMinimal
//
//  Created by Mirko Fetter on 28.10.16.
//
// Based on https://github.com/erikdoe/swift-circle


import ScreenSaver
import SwiftUI
import os.log
import Darwin
import Quartz
import AppKit

class ScreenSaverMinimalView : ScreenSaverView {
    
    // Configuration sheet controller
    lazy var swiftUISheetController: SwiftUIConfigureSheetController = SwiftUIConfigureSheetController()
    
    var isPreviewBug: Bool = false
    var originalIsPreview: Bool = false
    var actualIsPreview: Bool = false
    
    private var instanceNumber: Int
    private var willStopObserver: NSObjectProtocol?
    private var redrawTimer: Timer?
    private var isAnimationStarted: Bool = false
    private var systemSettingsCheckTimer: Timer?
    private var lastSystemSettingsCheck: Date = Date()
    
    // Check if we're running in the SaverTest app
    private var isRunningInApp: Bool {
        return InstanceTracker.isRunningInApp
    }
    
    private func instanceInfo() -> String {
        return ScreenSaverUtilities.instanceInfo(instanceNumber)
    }
    
    override init(frame: NSRect, isPreview: Bool) {
        // Need to set instanceNumber before super.init
        instanceNumber = 0 // Temporary value
        
        // Check and log screen lock status for debugging
        let screenLocked = ScreenSaverUtilities.isScreenLocked()
        OSLog.info("init: CGSSessionScreenIsLocked = \(screenLocked)")
        
        var preview = isPreview
        originalIsPreview = isPreview
        
        // isPreview detection simplified using isScreenLocked() on Tahoe
        if InstanceTracker.isRunningInApp {
            // App mode - use original values
            preview = isPreview
            actualIsPreview = isPreview
        } else if #available(macOS 26.0, *) {
            // Tahoe - use screen lock detection (simple!)
            if Preferences.tahoeIsPreviewFix {
                if screenLocked {
                    // Screen is locked = actual screensaver
                    preview = false
                    actualIsPreview = false
                } else {
                    // Screen not locked = preview mode
                    preview = true
                    actualIsPreview = true
                }
            } else {
                // Use original isPreview value if fix is disabled
                preview = isPreview
                actualIsPreview = isPreview
            }
        } else {
            // Pre-Tahoe - existing frame size logic
            // Radar# FB7486243, legacyScreenSaver.appex always returns true
            preview = true
            actualIsPreview = true
            // We can workaround that bug by looking at the size of the frame
            // It's always 296.0 x 184.0 when running in preview mode
            if frame.width > 400 && frame.height > 300 {
                if isPreview {
                    isPreviewBug = true
                }
                preview = false
                actualIsPreview = false
            }
        }
        
        super.init(frame: frame, isPreview: preview)!
        
        // Always register with the tracker and log
        instanceNumber = InstanceTracker.shared.registerInstance(self)
        OSLog.info("init \(instanceInfo()): frame=\(ScreenSaverUtilities.formatFrame(frame)), isPreview=\(isPreview), actualIsPreview=\(actualIsPreview)")
        
        // Handle Tahoe ghost instances
        if !InstanceTracker.isRunningInApp, #available(macOS 26.0, *) {
            if actualIsPreview && frame == NSRect(x: 0, y: 0, width: 0, height: 0) {
                OSLog.info("init: Ghost instance detected - skipping initialization")
                return
            }
        }
        
        // Log process information for debugging
        SystemDetection.logProcessInfo(instanceNumber: instanceNumber)
        
        // Register for willStop notification if the preference is enabled AND not in app mode AND not in preview mode
        if Preferences.enableExitFixOnWillStop && !isRunningInApp && !actualIsPreview {
            willStopObserver = DistributedNotificationCenter.default().addObserver(
                forName: NSNotification.Name("com.apple.screensaver.willstop"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleWillStopNotification()
            }
            OSLog.info("init \(instanceInfo()): Registered for willStop notification")
        }
        

    }
    
    required init?(coder aDecoder: NSCoder) {
        instanceNumber = 0
        super.init(coder: aDecoder)
        instanceNumber = InstanceTracker.shared.registerInstance(self)
        OSLog.info("init(coder:) \(instanceInfo()):")
        
        // Register for willStop notification if the preference is enabled AND not in app mode AND not in preview mode
        if Preferences.enableExitFixOnWillStop && !isRunningInApp && !actualIsPreview {
            willStopObserver = DistributedNotificationCenter.default().addObserver(
                forName: NSNotification.Name("com.apple.screensaver.willstop"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleWillStopNotification()
            }
            OSLog.info("init(coder:) \(instanceInfo()): Registered for willStop notification")
        }
    }
    
    
    override var hasConfigureSheet: Bool {
        OSLog.info("hasConfigureSheet \(instanceInfo()):")
        return true
    }
    
    override var configureSheet: NSWindow? {
        OSLog.info("configureSheet \(instanceInfo()):")
        return swiftUISheetController.window
    }

    
    override func startAnimation() {
        if isAnimationStarted {
            OSLog.info("startAnimation \(instanceInfo()): WARNING - Already started! Ignoring duplicate call")
            return
        }
        
        OSLog.info("startAnimation \(instanceInfo()):")
        super.startAnimation()
        isAnimationStarted = true
        
        // Start redraw timer - triggers redraw every second
        redrawTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.needsDisplay = true
        }
    }
    
    override func stopAnimation() {
        if !isAnimationStarted {
            OSLog.info("stopAnimation \(instanceInfo()): WARNING - Not started! Ignoring erroneous call")
            return
        }
        
        OSLog.info("stopAnimation \(instanceInfo()):")
        super.stopAnimation()
        isAnimationStarted = false
        
        // Stop and clean up redraw timer
        redrawTimer?.invalidate()
        redrawTimer = nil
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if let window = self.window {
            OSLog.info("viewDidMoveToWindow \(instanceInfo()): window=\(window), frame=\(ScreenSaverUtilities.formatFrame(window.frame)), screen=\(window.screen?.localizedName ?? "unknown")")
        } else {
            OSLog.info("viewDidMoveToWindow \(instanceInfo()): window=nil (removed from hierarchy)")
        }
    }
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)
        OSLog.info("viewWillMove \(instanceInfo()): from superview=\(self.superview?.description ?? "nil") to superview=\(newSuperview?.description ?? "nil")")
    }
    
    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        OSLog.info("viewDidChangeBackingProperties \(instanceInfo()): backingScaleFactor=\(self.window?.backingScaleFactor ?? 0)")
    }
    
    override func viewWillStartLiveResize() {
        super.viewWillStartLiveResize()
        OSLog.info("viewWillStartLiveResize \(instanceInfo()): frame=\(ScreenSaverUtilities.formatFrame(self.window?.frame ?? .zero))")
    }
    
    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        OSLog.info("viewDidEndLiveResize \(instanceInfo()): frame=\(ScreenSaverUtilities.formatFrame(self.window?.frame ?? .zero))")
    }
    

    override func draw(_ rect: NSRect) {
        if Preferences.logDrawCalls {
            OSLog.info("draw \(instanceInfo()): rect=\(ScreenSaverUtilities.formatFrame(rect))")
        }
        // Fill entire rect with border color
        Preferences.canvasColor.nsColor.set()
        NSBezierPath(rect: bounds).fill()
        
        // Clear the inner area
        let borderWidth = bounds.width * 0.05
        let innerRect = bounds.insetBy(dx: borderWidth, dy: borderWidth)
        
        // Use dark red if bug fix is applied, dark purple if in preview mode, black otherwise
        let innerColor: NSColor
        if actualIsPreview && originalIsPreview != actualIsPreview {
            // Bug fix is active - use dark red
            innerColor = NSColor(red: 0.4, green: 0.1, blue: 0.1, alpha: 1.0)
        } else if actualIsPreview {
            // Normal preview mode - use dark purple
            innerColor = NSColor(red: 0.3, green: 0.1, blue: 0.4, alpha: 1.0)
        } else {
            // Not preview mode - use black
            innerColor = NSColor.black
        }
        innerColor.set()
        NSBezierPath(rect: innerRect).fill()

        // Draw preview status text showing both values
        let previewText = "Preview: \(actualIsPreview ? "YES" : "NO") (Original: \(originalIsPreview ? "YES" : "NO"))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 24),
            .foregroundColor: NSColor.white
        ]
        
        let textSize = previewText.size(withAttributes: attributes)
        let xPosition = bounds.width * 0.1
        let yPosition = bounds.height - borderWidth - textSize.height - 20
        
        previewText.draw(at: NSPoint(x: xPosition, y: yPosition), withAttributes: attributes)
        
        // Draw instance info in top right corner
        let totalInstances = InstanceTracker.shared.totalInstances
        let instanceText = "Instance \(instanceNumber)/\(totalInstances)"
        let instanceAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 48),
            .foregroundColor: NSColor.white
        ]
        
        let instanceTextSize = instanceText.size(withAttributes: instanceAttributes)
        let instanceXPosition = bounds.width - instanceTextSize.width - (bounds.width * 0.1)
        let instanceYPosition = bounds.height - borderWidth - instanceTextSize.height - 20
        
        instanceText.draw(at: NSPoint(x: instanceXPosition, y: instanceYPosition), withAttributes: instanceAttributes)
        
        // Only show Radar# FB7486243 on macOS versions before 26.0
        if #unavailable(macOS 26.0) {
            // Draw debug text in bottom left
            let debugText = "Radar# FB7486243 (isPreview bug): \(isPreviewBug)"
            let debugAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 24),
                .foregroundColor: NSColor.white
            ]
            
            let debugXPosition = bounds.width * 0.1
            let debugYPosition = borderWidth + 20
            
            debugText.draw(at: NSPoint(x: debugXPosition, y: debugYPosition), withAttributes: debugAttributes)
        }
        
        // Draw version info in bottom right corner
        let versionText = ScreenSaverUtilities.getVersionString()
        let versionAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 16),
            .foregroundColor: NSColor.white
        ]
        
        let versionTextSize = versionText.size(withAttributes: versionAttributes)
        let versionXPosition = bounds.width - versionTextSize.width - (bounds.width * 0.05)
        let versionYPosition = borderWidth + 20
        
        versionText.draw(at: NSPoint(x: versionXPosition, y: versionYPosition), withAttributes: versionAttributes)

    }
    
    override func animateOneFrame() {
        if Preferences.logAnimateOneFrameCalls {
            OSLog.info("animateOneFrame \(instanceInfo()):")
        }
        
        // Check System Settings if we're in preview mode and the fix is enabled
        if actualIsPreview && Preferences.tahoeIsPreviewFix {
            let now = Date()
            // Check every second
            if now.timeIntervalSince(lastSystemSettingsCheck) >= 1.0 {
                lastSystemSettingsCheck = now
                if !SystemDetection.isSystemSettingsRunning() {
                    // System Settings is not running, exit after 0.5 seconds
                    OSLog.info("animateOneFrame \(instanceInfo()): System Settings closed, scheduling exit in 0.5 seconds")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        exit(0)
                    }
                }
            }
        }
    }
    
    
    private func handleWillStopNotification() {
        OSLog.info("handleWillStopNotification \(instanceInfo()): Received willStop notification")
        
        // Don't exit if we're in preview mode
        if actualIsPreview {
            OSLog.info("handleWillStopNotification \(instanceInfo()): Ignoring willStop in preview mode")
            return
        }
        
        OSLog.info("handleWillStopNotification \(instanceInfo()): Scheduling exit in 2 seconds")
        
        // Stop redraw timer and mark animation as stopped before exit
        redrawTimer?.invalidate()
        redrawTimer = nil
        isAnimationStarted = false
        
        // Schedule exit after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            OSLog.info("handleWillStopNotification \(self.instanceInfo()): Executing exit(0)")
            exit(0)
        }
    }
    
    deinit {
        // Check for animation state issues
        if isAnimationStarted {
            OSLog.info("deinit \(instanceInfo()): WARNING - Animation was still running")
        }
        
        // Clean up redraw timer
        redrawTimer?.invalidate()
        redrawTimer = nil
        
        // Remove notification observer if it was registered
        if let observer = willStopObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
            OSLog.info("deinit \(instanceInfo()): Removed willStop notification observer")
        }
        OSLog.info("deinit \(instanceInfo()):")
    }
}
    

