//
//  ScreenSaverMinimalView.swift
//  ScreenSaverMinimal
//
//  Created by Mirko Fetter on 28.10.16.
//
// Based on https://github.com/erikdoe/swift-circle


import ScreenSaver

class ScreenSaverMinimalView : ScreenSaverView {
    
    lazy var sheetController: ConfigureSheetController = ConfigureSheetController()
    var isPreviewBug: Bool = false
    var originalIsPreview: Bool = false
    
    override init(frame: NSRect, isPreview: Bool) {

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
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override var hasConfigureSheet: Bool {
        return true
    }
    
    override var configureSheet: NSWindow? {
        return sheetController.window
    }

    
    override func startAnimation() {
        super.startAnimation()
    }
    
    override func stopAnimation() {
        super.stopAnimation()
    }
    

    override func draw(_ rect: NSRect) {
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

    }
    
    override func animateOneFrame() {
        window!.disableFlushing()
        
        window!.enableFlushing()
    }
}
    

