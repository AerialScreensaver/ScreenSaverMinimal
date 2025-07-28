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

// Helper to log to Console
// Open Console.app to see the logs and filter by "SSM (P:"
extension OSLog {
    static let screenSaver = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "ScreenSaverMinimal", category: "Screensaver")
    
    static func info(_ message: String) {
        let pid = ProcessInfo.processInfo.processIdentifier
        os_log("SSM (P:%d): %{public}@", log: .screenSaver, type: .default, pid, message)
    }
}

class ScreenSaverMinimalView : ScreenSaverView {
    
    // Configuration sheet controller
    lazy var swiftUISheetController: SwiftUIConfigureSheetController = SwiftUIConfigureSheetController()
    
    var isPreviewBug: Bool = false
    var originalIsPreview: Bool = false
    
    private var instanceNumber: Int
    private var willStopObserver: NSObjectProtocol?
    private var redrawTimer: Timer?
    
    private func getVersionString() -> String {
        let bundle = Bundle(for: type(of: self))
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildDate = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "v\(version) (\(buildDate))"
    }
    
    private func instanceInfo() -> String {
        return "(\(instanceNumber)/\(InstanceTracker.shared.totalInstances))"
    }
    
    private func formatFrame(_ frame: NSRect) -> String {
        return "(x:\(frame.origin.x), y:\(frame.origin.y), w:\(frame.size.width), h:\(frame.size.height))"
    }
    
    private func logProcessInfo() {
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
        let ourBundle = Bundle(for: type(of: self))
        
        OSLog.info("init \(instanceInfo()): Process Info:")
        OSLog.info("  Current: PID=\(currentPID), name=\(processName), path=\(processPath)")
        OSLog.info("  Parent: PID=\(parentPID), name=\(parentName), bundleID=\(parentBundleID)")
        OSLog.info("  MainBundle: \(mainBundle.bundleIdentifier ?? "nil") at \(mainBundle.bundlePath)")
        OSLog.info("  OurBundle: \(ourBundle.bundleIdentifier ?? "nil") at \(ourBundle.bundlePath)")
    }
    
    override init(frame: NSRect, isPreview: Bool) {
        // Need to set instanceNumber before super.init
        instanceNumber = 0 // Temporary value
        
        var preview = isPreview
        originalIsPreview = isPreview
        
        // isPreview is differently bugged depending on macOS versions. The common bug pre macOS 26 can be workarounded. The Tahoe+ bug has no workaround at this time.
        if #available(macOS 26.0, *) {
            preview = isPreview
        } else {
            // Radar# FB7486243, legacyScreenSaver.appex always returns true, unlike what used
            // to happen in previous macOS versions, see documentation here : https://developer.apple.com/documentation/screensaver/screensaverview/1512475-init$
            // This is only true pre-macOS Tahoe, that has the opposite bug, that we can't workaround this way!
            preview = true
            // We can workaround that bug by looking at the size of the frame
            // It's always 296.0 x 184.0 when running in preview mode
            if frame.width > 400 && frame.height > 300 {
                if isPreview {
                    isPreviewBug = true
                }
                preview = false
            }
        }
        
        super.init(frame: frame, isPreview: preview)!
        
        // Now register with the tracker after super.init
        instanceNumber = InstanceTracker.shared.registerInstance(self)
        OSLog.info("init \(instanceInfo()): frame=\(formatFrame(frame)), isPreview=\(isPreview)")
        
        // Log process information for debugging
        logProcessInfo()
        
        // Register for willStop notification if the preference is enabled
        if Preferences.enableExitFixOnWillStop {
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
        
        // Register for willStop notification if the preference is enabled
        if Preferences.enableExitFixOnWillStop {
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
        OSLog.info("startAnimation \(instanceInfo()):")
        super.startAnimation()
        
        // Start redraw timer - triggers redraw every second
        redrawTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.needsDisplay = true
        }
    }
    
    override func stopAnimation() {
        OSLog.info("stopAnimation \(instanceInfo()):")
        super.stopAnimation()
        
        // Stop and clean up redraw timer
        redrawTimer?.invalidate()
        redrawTimer = nil
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if let window = self.window {
            OSLog.info("viewDidMoveToWindow \(instanceInfo()): window=\(window), frame=\(formatFrame(window.frame)), screen=\(window.screen?.localizedName ?? "unknown")")
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
        OSLog.info("viewWillStartLiveResize \(instanceInfo()): frame=\(formatFrame(self.window?.frame ?? .zero))")
    }
    
    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        OSLog.info("viewDidEndLiveResize \(instanceInfo()): frame=\(formatFrame(self.window?.frame ?? .zero))")
    }
    

    override func draw(_ rect: NSRect) {
        if Preferences.logDrawCalls {
            OSLog.info("draw \(instanceInfo()): rect=\(formatFrame(rect))")
        }
        // Fill entire rect with border color
        Preferences.canvasColor.nsColor.set()
        NSBezierPath(rect: bounds).fill()
        
        // Clear the inner area
        let borderWidth = bounds.width * 0.05
        let innerRect = bounds.insetBy(dx: borderWidth, dy: borderWidth)
        
        // Use dark purple if in preview mode, black otherwise
        let innerColor = originalIsPreview ? NSColor(red: 0.3, green: 0.1, blue: 0.4, alpha: 1.0) : NSColor.black
        innerColor.set()
        NSBezierPath(rect: innerRect).fill()

        // Draw preview status text
        let previewText = "Preview: \(originalIsPreview ? "YES" : "NO")"
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
        let versionText = getVersionString()
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
        window!.disableFlushing()
        
        window!.enableFlushing()
    }
    
    private func handleWillStopNotification() {
        OSLog.info("handleWillStopNotification \(instanceInfo()): Received willStop notification, scheduling exit in 2 seconds")
        
        // Stop redraw timer before exit
        redrawTimer?.invalidate()
        redrawTimer = nil
        
        // Schedule exit after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            OSLog.info("handleWillStopNotification \(self.instanceInfo()): Executing exit(0)")
            exit(0)
        }
    }
    
    deinit {
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
    

