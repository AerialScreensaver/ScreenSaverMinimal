//
//  ScreenSaverMinimalView.swift
//  ScreenSaverMinimal
//
//  Created by Mirko Fetter on 28.10.16.
//
// Based on https://github.com/erikdoe/swift-circle


import ScreenSaver
import os.log

class ScreenSaverMinimalView : ScreenSaverView {
    
    lazy var sheetController: ConfigureSheetController = ConfigureSheetController()
    var isPreviewBug: Bool = false
    var originalIsPreview: Bool = false
    
    private var instanceNumber: Int
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScreenSaverMinimal", category: "ScreenSaver")
    private var willStopObserver: NSObjectProtocol?
    
    private func getVersionString() -> String {
        let bundle = Bundle(for: type(of: self))
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildDate = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "v\(version) (\(buildDate))"
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
        logger.info("init: \(self.instanceNumber, privacy: .public)")
        
        // Register for willStop notification if the preference is enabled
        if Preferences.enableExitFixOnWillStop {
            willStopObserver = DistributedNotificationCenter.default().addObserver(
                forName: NSNotification.Name("com.apple.screensaver.willstop"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleWillStopNotification()
            }
            logger.info("init: \(self.instanceNumber, privacy: .public) - Registered for willStop notification")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        instanceNumber = 0
        super.init(coder: aDecoder)
        instanceNumber = InstanceTracker.shared.registerInstance(self)
        logger.info("init(coder:): \(self.instanceNumber, privacy: .public)")
        
        // Register for willStop notification if the preference is enabled
        if Preferences.enableExitFixOnWillStop {
            willStopObserver = DistributedNotificationCenter.default().addObserver(
                forName: NSNotification.Name("com.apple.screensaver.willstop"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleWillStopNotification()
            }
            logger.info("init(coder:): \(self.instanceNumber, privacy: .public) - Registered for willStop notification")
        }
    }
    
    
    override var hasConfigureSheet: Bool {
        logger.info("hasConfigureSheet: \(self.instanceNumber, privacy: .public)")
        return true
    }
    
    override var configureSheet: NSWindow? {
        logger.info("configureSheet: \(self.instanceNumber, privacy: .public)")
        return sheetController.window
    }

    
    override func startAnimation() {
        logger.info("startAnimation: \(self.instanceNumber, privacy: .public)")
        super.startAnimation()
    }
    
    override func stopAnimation() {
        logger.info("stopAnimation: \(self.instanceNumber, privacy: .public)")
        super.stopAnimation()
    }
    

    override func draw(_ rect: NSRect) {
        if Preferences.logDrawCalls {
            logger.info("draw: \(self.instanceNumber, privacy: .public)")
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
            logger.info("animateOneFrame: \(self.instanceNumber, privacy: .public)")
        }
        window!.disableFlushing()
        
        window!.enableFlushing()
    }
    
    private func handleWillStopNotification() {
        logger.info("handleWillStopNotification: \(self.instanceNumber, privacy: .public) - Received willStop notification, scheduling exit in 2 seconds")
        
        // Schedule exit after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.logger.info("handleWillStopNotification: \(self.instanceNumber, privacy: .public) - Executing exit(0)")
            exit(0)
        }
    }
    
    deinit {
        // Remove notification observer if it was registered
        if let observer = willStopObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
            logger.info("deinit: \(self.instanceNumber, privacy: .public) - Removed willStop notification observer")
        }
        logger.info("deinit: \(self.instanceNumber, privacy: .public)")
    }
}
    

