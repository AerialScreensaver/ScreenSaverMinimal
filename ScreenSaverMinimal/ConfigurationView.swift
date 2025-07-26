//
//  ConfigurationView.swift
//  ScreenSaverMinimal
//
//  SwiftUI configuration interface for the screensaver
//

import SwiftUI

struct ConfigurationView: View {
    @StateObject private var viewModel = ConfigurationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Callback for close button
    var onClose: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            // Configuration Form
            Form {
                Section("Appearance") {
                    HStack(alignment: .center) {
                        Text("Canvas Color:")
                            .font(.title3)
                        Spacer()
                        ColorPicker("", selection: $viewModel.canvasColor)
                            .labelsHidden()
                            .frame(width: 100)
                    }
                }
                
                Section("Debug Options") {
                    Toggle(isOn: $viewModel.logDrawCalls) {
                        Text("Log Draw Calls")
                            .font(.title3).padding(.top, 5)
                    }
                    .help("Logs each draw() call to Console.app")
                    
                    Toggle(isOn: $viewModel.logAnimateOneFrameCalls) {
                        Text("Log Animate One Frame Calls")
                            .font(.title3).padding(.top, 5)
                    }
                    .help("Logs each animateOneFrame() call to Console.app")
                    
                    Toggle(isOn: $viewModel.enableExitFixOnWillStop) {
                        Text("Enable Exit Fix on willStop")
                            .font(.title3).padding(.top, 5)
                    }
                    .help("Exits the screensaver process 2 seconds after receiving willStop notification")
                }
                
                Section("About logs") {
                    Text("To view log messages, open Console.app and filter by \"ScreenSaverMinimal:\"")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .formStyle(.grouped)
            .controlSize(.extraLarge)
            
            //.frame(minHeight: 600)
            .frame(maxHeight: 800)
            
            // Buttons
            HStack {
                Spacer()
                
                Button("Close") {
                    // Close color panel if open
                    NSColorPanel.shared.close()
                    
                    // Call the close callback
                    onClose?()
                }
                .keyboardShortcut(.defaultAction)
            }.controlSize(.extraLarge)
            .padding()
        }
        // Buttons accept tint, but not Toggles 🤷
        //.tint(Color("AccentColor"))
        .frame(width: 450, height: 550)
        .background(Color(nsColor: NSColor.windowBackgroundColor))
    }
    
}

// MARK: - Preview
struct ConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationView()
    }
}
