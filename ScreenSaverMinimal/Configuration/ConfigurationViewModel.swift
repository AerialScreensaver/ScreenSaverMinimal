//
//  ConfigurationViewModel.swift
//  ScreenSaverMinimal
//
//  View model for SwiftUI configuration sheet
//

import SwiftUI
import Combine
import AppKit

class ConfigurationViewModel: ObservableObject {
    // Published properties that mirror our preferences
    @Published var canvasColor: Color = Color(NSColor(red: 1, green: 0.0, blue: 0.5, alpha: 1.0))
    @Published var logDrawCalls: Bool = false
    @Published var logAnimateOneFrameCalls: Bool = false
    @Published var enableExitFixOnWillStop: Bool = false
    @Published var tahoeIsPreviewFix: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadPreferences()
        setupBindings()
    }
    
    private func loadPreferences() {
        // Load current preferences
        canvasColor = Color(Preferences.canvasColor.nsColor)
        logDrawCalls = Preferences.logDrawCalls
        logAnimateOneFrameCalls = Preferences.logAnimateOneFrameCalls
        enableExitFixOnWillStop = Preferences.enableExitFixOnWillStop
        tahoeIsPreviewFix = Preferences.tahoeIsPreviewFix
    }
    
    private func setupBindings() {
        // Save canvas color changes
        $canvasColor
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { swiftUIColor in
                // Convert SwiftUI Color to NSColor for macOS 15+
                let nsColor = NSColor(swiftUIColor)
                Preferences.canvasColor = PreferenceColor(nsColor: nsColor)
            }
            .store(in: &cancellables)
        
        // Save log draw calls changes
        $logDrawCalls
            .sink { value in
                Preferences.logDrawCalls = value
            }
            .store(in: &cancellables)
        
        // Save log animate one frame changes
        $logAnimateOneFrameCalls
            .sink { value in
                Preferences.logAnimateOneFrameCalls = value
            }
            .store(in: &cancellables)
        
        // Save exit fix changes
        $enableExitFixOnWillStop
            .sink { value in
                Preferences.enableExitFixOnWillStop = value
            }
            .store(in: &cancellables)
        
        // Save Tahoe isPreview fix changes
        $tahoeIsPreviewFix
            .sink { value in
                Preferences.tahoeIsPreviewFix = value
            }
            .store(in: &cancellables)
    }
}

