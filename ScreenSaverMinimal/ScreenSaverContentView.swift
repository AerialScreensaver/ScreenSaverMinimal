//
//  ScreenSaverContentView.swift
//  ScreenSaverMinimal
//
//  SwiftUI view for screensaver content
//

import SwiftUI

struct ScreenSaverContentView: View {
    @StateObject private var viewModel: ScreenSaverViewModel
    @State private var animationOffset: CGFloat = 0
    @State private var animationOpacity: Double = 1.0
    
    let isPreview: Bool
    let isPreviewBug: Bool
    
    init(instanceNumber: Int, isPreview: Bool = false, isPreviewBug: Bool = false) {
        _viewModel = StateObject(wrappedValue: ScreenSaverViewModel(instanceNumber: instanceNumber))
        self.isPreview = isPreview
        self.isPreviewBug = isPreviewBug
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundView
                
                // Content
                contentView(in: geometry)
            }
        }
        .onAppear {
            viewModel.startAnimation()
            startAnimations()
        }
        .onDisappear {
            viewModel.stopAnimation()
        }
    }
    
    private var backgroundView: some View {
        Rectangle()
            .fill(isPreview ? .purple : .black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func contentView(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            Text("ScreenSaver Minimal")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .opacity(animationOpacity)
            
            Text("Instance #\(viewModel.instanceNumber)")
                .font(.title2)
                .foregroundColor(.yellow)
                .opacity(animationOpacity)
            
            Text("Total instances: \(viewModel.totalInstances)")
                .font(.title2)
                .foregroundColor(.green)
                .opacity(animationOpacity)
            
            Text("Preview: \(isPreview ? "YES" : "NO")")
                .font(.title2)
                .foregroundColor(.green)
                .opacity(animationOpacity)
            
            Text("Version: \(viewModel.versionString)")
                .font(.body)
                .foregroundColor(.gray)
                .opacity(animationOpacity)
            
            Text(timeString)
                .font(.body)
                .foregroundColor(.blue)
                .opacity(animationOpacity)
            
            if #unavailable(macOS 26.0) {
                Text("Radar# FB7486243 (isPreview bug): \(isPreviewBug)")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .opacity(animationOpacity)
            }
            
            if Preferences.logDrawCalls {
                Text("🐛 Draw logging enabled")
                    .font(.caption)
                    .foregroundColor(.red)
                    .opacity(animationOpacity)
            }
            
            if Preferences.logAnimateOneFrameCalls {
                Text("🐛 Animation logging enabled")
                    .font(.caption)
                    .foregroundColor(.red)
                    .opacity(animationOpacity)
            }
            
            animationStatusView
        }
        .position(x: geometry.size.width / 2 + animationOffset, 
                 y: geometry.size.height / 2)
        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), 
                  value: animationOffset)
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), 
                  value: animationOpacity)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: viewModel.currentTime)
    }
    
    private var animationStatusView: some View {
        HStack {
            Circle()
                .fill(viewModel.isAnimating ? .green : .red)
                .frame(width: 12, height: 12)
            
            Text(viewModel.isAnimating ? "Animating" : "Stopped")
                .font(.caption)
                .foregroundColor(.white)
        }
        .opacity(animationOpacity)
    }
    
    private func startAnimations() {
        // Start the position animation
        withAnimation {
            animationOffset = 50
        }
        
        // Start the opacity animation with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                animationOpacity = 0.7
            }
        }
    }
}

// MARK: - Preview
struct ScreenSaverContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScreenSaverContentView(instanceNumber: 1, isPreview: false, isPreviewBug: false)
                .frame(width: 800, height: 600)
                .previewDisplayName("Full Screen")
            
            ScreenSaverContentView(instanceNumber: 2, isPreview: true, isPreviewBug: true)
                .frame(width: 400, height: 300)
                .previewDisplayName("Preview Mode")
        }
    }
}
