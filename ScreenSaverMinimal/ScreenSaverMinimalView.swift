//
//  ScreenSaverMinimalView.swift
//  ScreenSaverMinimal
//  Combine branch : Use SwiftUI + Combine. This works in app mode but fails in
//  ScreenSaver mode, reason unknown for now. Maybe we can't use NSHostingView. 
//
//  Created by Mirko Fetter on 28.10.16.
//
// Based on https://github.com/erikdoe/swift-circle


import ScreenSaver
import SwiftUI
import Combine
import OSLog

class ScreenSaverMinimalView : ScreenSaverView {
    
    lazy var sheetController: ConfigureSheetController = ConfigureSheetController()
    var isPreviewBug: Bool = false
    var originalIsPreview: Bool = false
    
    private var instanceNumber: Int
    private var willStopObserver: NSObjectProtocol?
    private var hostingView: NSHostingView<ScreenSaverContentView>?
    
    private func getVersionString() -> String {
        let bundle = Bundle(for: type(of: self))
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildDate = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "v\(version) (\(buildDate))"
    }
    
    private func setupSwiftUI() {
        let contentView = ScreenSaverContentView(
            instanceNumber: instanceNumber,
            isPreview: originalIsPreview,
            isPreviewBug: isPreviewBug
        )
        hostingView = NSHostingView(rootView: contentView)
        
        guard let hostingView = hostingView else { return }
        
        hostingView.frame = bounds
        hostingView.autoresizingMask = [.width, .height]
        addSubview(hostingView)
        
        OSLog.info("SwiftUI setup complete: \(instanceNumber)")
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
        OSLog.info("init: \(self.instanceNumber)")
        
        // Setup SwiftUI
        setupSwiftUI()
        
        // Register for willStop notification if the preference is enabled
        if Preferences.enableExitFixOnWillStop {
            willStopObserver = DistributedNotificationCenter.default().addObserver(
                forName: NSNotification.Name("com.apple.screensaver.willstop"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleWillStopNotification()
            }
            OSLog.info("init: \(self.instanceNumber) - Registered for willStop notification")
        }
        

    }
    
    required init?(coder aDecoder: NSCoder) {
        instanceNumber = 0
        super.init(coder: aDecoder)
        instanceNumber = InstanceTracker.shared.registerInstance(self)
        OSLog.info("init(coder:): \(self.instanceNumber)")
        
        // Setup SwiftUI
        setupSwiftUI()
        
        // Register for willStop notification if the preference is enabled
        if Preferences.enableExitFixOnWillStop {
            willStopObserver = DistributedNotificationCenter.default().addObserver(
                forName: NSNotification.Name("com.apple.screensaver.willstop"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleWillStopNotification()
            }
            OSLog.info("init(coder:): \(self.instanceNumber) - Registered for willStop notification")
        }
    }
    
    
    override var hasConfigureSheet: Bool {
        OSLog.info("hasConfigureSheet: \(self.instanceNumber)")
        return true
    }
    
    override var configureSheet: NSWindow? {
        OSLog.info("configureSheet: \(self.instanceNumber)")
        return sheetController.window
    }

    
    override func startAnimation() {
        OSLog.info("startAnimation: \(self.instanceNumber)")
        super.startAnimation()
        
        // Notify SwiftUI view model about animation start
        if let hostingView = hostingView {
            // The view model will be notified through SwiftUI's onAppear
            OSLog.info("SwiftUI hostingView available for animation start: \(instanceNumber)")
        }
    }
    
    override func stopAnimation() {
        OSLog.info("stopAnimation: \(self.instanceNumber)")
        super.stopAnimation()
        
        // Notify SwiftUI view model about animation stop
        if let hostingView = hostingView {
            // The view model will be notified through SwiftUI's onDisappear
            OSLog.info("SwiftUI hostingView available for animation stop: \(instanceNumber)")
        }
    }
    

    override func draw(_ rect: NSRect) {
        if Preferences.logDrawCalls {
            OSLog.info("draw: \(self.instanceNumber)")
        }
        
        // SwiftUI handles most rendering, we just need a basic background
        // In case SwiftUI isn't working properly, provide a fallback
        if hostingView == nil {
            NSColor.black.set()
            NSBezierPath(rect: bounds).fill()
            
            // Fallback text
            let fallbackText = "SwiftUI Loading... Instance \(instanceNumber)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 24),
                .foregroundColor: NSColor.white
            ]
            
            let textSize = fallbackText.size(withAttributes: attributes)
            let x = (bounds.width - textSize.width) / 2
            let y = (bounds.height - textSize.height) / 2
            
            fallbackText.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
        }
    }
    
    override func animateOneFrame() {
        if Preferences.logAnimateOneFrameCalls {
            OSLog.info("animateOneFrame: \(self.instanceNumber)")
        }
        window!.disableFlushing()
        
        window!.enableFlushing()
    }
    
    private func handleWillStopNotification() {
        OSLog.info("handleWillStopNotification: \(self.instanceNumber) - Received willStop notification, scheduling exit in 2 seconds")
        
        // Schedule exit after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            OSLog.info("handleWillStopNotification: \(self.instanceNumber) - Executing exit(0)")
            exit(0)
        }
    }
    
    deinit {
        // Remove notification observer if it was registered
        if let observer = willStopObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
            OSLog.info("deinit: \(self.instanceNumber) - Removed willStop notification observer")
        }
        OSLog.info("deinit: \(self.instanceNumber)")
    }
}
    

