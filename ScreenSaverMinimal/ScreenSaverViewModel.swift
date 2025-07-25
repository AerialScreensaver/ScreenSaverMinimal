//
//  ScreenSaverViewModel.swift
//  ScreenSaverMinimal
//
//  SwiftUI + Combine reactive view model for screensaver
//

import Foundation
import Combine
import SwiftUI
import OSLog

class ScreenSaverViewModel: ObservableObject {
    // Published properties for SwiftUI
    @Published var instanceNumber: Int
    @Published var totalInstances: Int = 0
    @Published var currentTime: Date = Date()
    @Published var isAnimating: Bool = false
    @Published var versionString: String = ""
    
    // Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    private var instanceTracker: InstanceTracker
    
    init(instanceNumber: Int, tracker: InstanceTracker = InstanceTracker.shared) {
        self.instanceNumber = instanceNumber
        self.instanceTracker = tracker
        setupPublishers()
        loadVersionString()
        
        OSLog.info("ScreenSaverViewModel init: \(instanceNumber)")
    }
    
    deinit {
        OSLog.info("ScreenSaverViewModel deinit: \(instanceNumber)")
    }
    
    private func setupPublishers() {
        // Timer for regular updates
        Timer.publish(every: 1.0, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] time in
                self?.updateData(time)
            }
            .store(in: &cancellables)
        
        // Instance count changes (if available)
        NotificationCenter.default
            .publisher(for: .instanceCountChanged)
            .sink { [weak self] _ in
                self?.updateInstanceCount()
            }
            .store(in: &cancellables)
        
        // Preferences changes
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.updatePreferences()
            }
            .store(in: &cancellables)
    }
    
    private func updateData(_ time: Date) {
        currentTime = time
        totalInstances = instanceTracker.getTotalInstanceCount()
    }
    
    private func updateInstanceCount() {
        totalInstances = instanceTracker.getTotalInstanceCount()
    }
    
    private func updatePreferences() {
        // React to preference changes if needed
        OSLog.info("ScreenSaverViewModel preferences changed: \(instanceNumber)")
    }
    
    private func loadVersionString() {
        let bundle = Bundle(for: ScreenSaverMinimalView.self)
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildDate = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        versionString = "v\(version) (\(buildDate))"
    }
    
    // Public methods for lifecycle management
    func startAnimation() {
        isAnimating = true
        OSLog.info("ScreenSaverViewModel startAnimation: \(instanceNumber)")
    }
    
    func stopAnimation() {
        isAnimating = false
        OSLog.info("ScreenSaverViewModel stopAnimation: \(instanceNumber)")
    }
}
