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
    @State private var currentScaleIndex: Int = {
        // Default to centerMeridian_JI
        let target = ScalesCatalog.centerMeridian_JI
        if let idx = ScalesCatalog.all.firstIndex(where: { $0 == target }) {
            return idx
        }
        return 0
    }()
    @State private var rotation: Int = 0 // Range: -2 to +2
    @State private var musicalKey: MusicalKey = .D // Default to D (center key)
    
    // MARK: - Phase 3: New Voice System
    
    /// Keyboard state manages frequency calculations
    /// Created once and updated as scale/key changes
    @State private var keyboardState: KeyboardState = KeyboardState(
        scale: ScalesCatalog.centerMeridian_JI,
        key: .D
    )
    
    /// Feature flag to switch between old and new voice systems
    /// Set to true to use new VoicePool, false to use old oscillator01-18
    @State private var useNewVoiceSystem: Bool = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isReady {
                    MainKeyboardView(
                        onPrevScale: { decrementScale() },
                        onNextScale: { incrementScale() },
                        currentScale: currentScale,
                        currentKey: musicalKey,
                        onCycleIntonation: { cycleIntonation(forward: $0) },
                        onCycleCelestial: { cycleCelestial(forward: $0) },
                        onCycleTerrestrial: { cycleTerrestrial(forward: $0) },
                        onCycleRotation: { cycleRotation(forward: $0) },
                        onCycleKey: { cycleKey(forward: $0) },
                        keyboardState: keyboardState,
                        useNewVoiceSystem: useNewVoiceSystem
                    )
                    .transition(.opacity)
                } else {
                    StartupView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 1.0), value: isReady)
            .task {await initializeAudio()}
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentScale: Scale {
        var scale = ScalesCatalog.all[currentScaleIndex]
        scale.rotation = rotation
        return scale
    }
    
    // MARK: - Audio Initialization
    
    private func initializeAudio() async {
        do {
            try EngineManager.startEngine()
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            EngineManager.initializeVoices(count: 18)
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            applyCurrentScale()
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            await MainActor.run {
                isReady = true
            }
        } catch {
            print("Failed to initialize audio: \(error)")
        }
    }
    
    // MARK: - Scale Management
    
    private func applyCurrentScale() {
        // Use the computed currentScale property which includes rotation
        // Pass the current musical key for transposition
        let frequencies = makeKeyFrequencies(
            for: currentScale,
            baseFrequency: MusicalKey.baseFrequency,
            musicalKey: musicalKey
        )
        
        // OLD SYSTEM: Apply to oscillator01-18
        // Pass Double array directly (no conversion needed)
        EngineManager.applyScale(frequencies: frequencies)
        
        // NEW SYSTEM: Update KeyboardState
        // This will automatically recalculate frequencies for the new voice pool
        keyboardState.updateScaleAndKey(scale: currentScale, key: musicalKey)
    }
    
    private func incrementScale() {
        guard currentScaleIndex < ScalesCatalog.all.count - 1 else { return }
        currentScaleIndex += 1
        applyCurrentScale()
    }
    
    private func decrementScale() {
        guard currentScaleIndex > 0 else { return }
        currentScaleIndex -= 1
        applyCurrentScale()
    }
    
    // MARK: - Property-Based Scale Navigation
    
    /// Cycle through scales with different intonation but same celestial/terrestrial
    /// This one wraps around: JI <-> ET
    private func cycleIntonation(forward: Bool) {
        let current = currentScale
        let targetIntonation: Intonation = (current.intonation == .ji) ? .et : .ji
        
        if let newScale = ScalesCatalog.find(
            intonation: targetIntonation,
            celestial: current.celestial,
            terrestrial: current.terrestrial
        ),
           let newIndex = ScalesCatalog.all.firstIndex(where: { $0 == newScale }) {
            currentScaleIndex = newIndex
            applyCurrentScale()
        }
    }
    
    /// Cycle through scales with different celestial but same intonation/terrestrial
    /// Does NOT wrap around: Moon -> Center -> Sun (stops at ends)
    private func cycleCelestial(forward: Bool) {
        let current = currentScale
        let allCases = Celestial.allCases
        guard let currentIdx = allCases.firstIndex(of: current.celestial) else { return }
        
        // Calculate next index, but don't wrap
        let nextIdx: Int
        if forward {
            nextIdx = currentIdx + 1
            guard nextIdx < allCases.count else { return } // Stop at end
        } else {
            nextIdx = currentIdx - 1
            guard nextIdx >= 0 else { return } // Stop at beginning
        }
        
        let targetCelestial = allCases[nextIdx]
        
        if let newScale = ScalesCatalog.find(
            intonation: current.intonation,
            celestial: targetCelestial,
            terrestrial: current.terrestrial
        ),
           let newIndex = ScalesCatalog.all.firstIndex(where: { $0 == newScale }) {
            currentScaleIndex = newIndex
            applyCurrentScale()
        }
    }
    
    /// Cycle through scales with different terrestrial but same intonation/celestial
    /// Does NOT wrap around: Occident -> Meridian -> Orient (stops at ends)
    private func cycleTerrestrial(forward: Bool) {
        let current = currentScale
        let allCases = Terrestrial.allCases
        guard let currentIdx = allCases.firstIndex(of: current.terrestrial) else { return }
        
        // Calculate next index, but don't wrap
        let nextIdx: Int
        if forward {
            nextIdx = currentIdx + 1
            guard nextIdx < allCases.count else { return } // Stop at end
        } else {
            nextIdx = currentIdx - 1
            guard nextIdx >= 0 else { return } // Stop at beginning
        }
        
        let targetTerrestrial = allCases[nextIdx]
        
        if let newScale = ScalesCatalog.find(
            intonation: current.intonation,
            celestial: current.celestial,
            terrestrial: targetTerrestrial
        ),
           let newIndex = ScalesCatalog.all.firstIndex(where: { $0 == newScale }) {
            currentScaleIndex = newIndex
            applyCurrentScale()
        }
    }
    
    /// Cycle rotation: -2, -1, 0, +1, +2
    /// Does NOT wrap around (stops at ends)
    private func cycleRotation(forward: Bool) {
        let newRotation = forward ? rotation + 1 : rotation - 1
        
        // Clamp to range [-2, 2]
        guard newRotation >= -2 && newRotation <= 2 else { return }
        
        rotation = newRotation
        applyCurrentScale()
    }
    
    /// Cycle through musical keys
    /// Order: Ab -> Eb -> Bb -> F -> C -> G -> D -> A -> E -> B -> F# -> C# -> G#
    /// Does NOT wrap around (stops at ends)
    private func cycleKey(forward: Bool) {
        let allCases = MusicalKey.allCases
        guard let currentIdx = allCases.firstIndex(of: musicalKey) else { return }
        
        // Calculate next index, but don't wrap
        let nextIdx: Int
        if forward {
            nextIdx = currentIdx + 1
            guard nextIdx < allCases.count else { return } // Stop at end
        } else {
            nextIdx = currentIdx - 1
            guard nextIdx >= 0 else { return } // Stop at beginning
        }
        
        musicalKey = allCases[nextIdx]
        applyCurrentScale()
    }
}
