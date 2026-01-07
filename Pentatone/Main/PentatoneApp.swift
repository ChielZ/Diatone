//
//  PentatoneApp.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 30/11/2025.
//

import SwiftUI
import AudioKit

let radius = 6.0

let screenWidth = UIScreen.main.bounds.size.width
let screenHeight = UIScreen.main.bounds.size.height

// MARK: - App Delegate for Orientation Control

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        // iPhone: Portrait only
        // iPad: All orientations
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }
}

@main
struct Penta_ToneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isReady = false
    
    // MARK: - Navigation & State Management
    
    /// Manages scale selection, rotation, and key transposition
    @StateObject private var navigationManager = ScaleNavigationManager(
        initialScale: ScalesCatalog.centerMeridian_JI,
        initialKey: .D
    )
    
    /// Keyboard state manages frequency calculations
    /// Created once and updated as scale/key changes
    @State private var keyboardState: KeyboardState = KeyboardState(
        scale: ScalesCatalog.centerMeridian_JI,
        key: .D
    )
    
    var body: some Scene {
        WindowGroup {
            contentView
        }
        .onOpenURL { url in
            handleIncomingPreset(url)
        }
        //.applyWindowResizability()
    }
    
    @ViewBuilder
    private var contentView: some View {
        ZStack {
            if isReady {
                MainKeyboardView(
                    onPrevScale: { navigationManager.decrementScale() },
                    onNextScale: { navigationManager.incrementScale() },
                    currentScale: navigationManager.currentScale,
                    currentKey: navigationManager.musicalKey,
                    onCycleIntonation: { navigationManager.cycleIntonation(forward: $0) },
                    onCycleCelestial: { navigationManager.cycleCelestial(forward: $0) },
                    onCycleTerrestrial: { navigationManager.cycleTerrestrial(forward: $0) },
                    onCycleRotation: { navigationManager.cycleRotation(forward: $0) },
                    onCycleKey: { navigationManager.cycleKey(forward: $0) },
                    keyboardState: keyboardState
                )
                .transition(.opacity)
            } else {
                StartupView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 1.0), value: isReady)
        .modifier(SystemGestureModifier())
        .task { await initializeAudio() }
    }
    
    // MARK: - Audio Initialization
    
    private func initializeAudio() async {
        do {
            // Start audio engine
            try EngineManager.startEngine()
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            // Initialize preset system
            await MainActor.run {
                PresetManager.shared.loadAllPresets()
                PresetManager.shared.initializeLayouts()
            }
            
            // Set up callback to update keyboard state when navigation changes
            navigationManager.onScaleChanged = { [self] scale in
                self.keyboardState.updateScaleAndKey(scale: scale, key: navigationManager.musicalKey)
            }
            
            navigationManager.onKeyChanged = { [self] key in
                self.keyboardState.updateScaleAndKey(scale: navigationManager.currentScale, key: key)
            }
            
            // Apply initial scale and key
            keyboardState.updateScaleAndKey(
                scale: navigationManager.currentScale,
                key: navigationManager.musicalKey
            )
            
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            await MainActor.run {
                isReady = true
            }
        } catch {
            print("Failed to initialize audio: \(error)")
        }
    }
    
    // MARK: - Preset File Handling
    
    /// Handle preset files opened from external sources (Files app, AirDrop, Mail, etc.)
    private func handleIncomingPreset(_ url: URL) {
        Task { @MainActor in
            do {
                let preset = try PresetManager.shared.importPreset(from: url)
                print("✅ Imported preset from external source: '\(preset.name)'")
                // Note: Preset is automatically added to user presets
                // Consider showing an alert or auto-loading the preset here if desired
            } catch {
                print("⚠️ Failed to import preset from external source: \(error)")
            }
        }
    }
}

// MARK: - Availability Wrappers for iOS Version Compatibility

/// ViewModifier to defer system gestures on iOS 16+
struct SystemGestureModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .defersSystemGestures(on: [.top, .leading, .trailing])
                .persistentSystemOverlays(.hidden)
        } else {
            content
        }
    }
}
/*
/// Extension to conditionally apply window resizability on iOS 17+
extension Scene {
    func applyWindowResizability() -> some Scene {
        if #available(iOS 17.0, *) {
            #if os(iOS)
            return windowResizability(.contentSize)
            #else
            return self
            #endif
        } else {
            return self
        }
    }
}
*/
