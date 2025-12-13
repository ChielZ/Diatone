//
//  Penta_ToneApp.swift
//  Penta-Tone
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
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isReady {
                    MainKeyboardView(
                        onPrevScale: { decrementScale() },
                        onNextScale: { incrementScale() }
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
        let rootFreq: Double = 200
        let scale = ScalesCatalog.all[currentScaleIndex]
        let frequencies = makeKeyFrequencies(for: scale, baseFrequency: rootFreq)
        
        // Pass Double array directly (no conversion needed)
        EngineManager.applyScale(frequencies: frequencies)
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
}
