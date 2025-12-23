//
//  VoicePool.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 20/12/2025.
//

import Foundation
import AudioKit
import AudioKitEX

/// Manages allocation and lifecycle of polyphonic voices
/// Uses round-robin allocation with availability checking and voice stealing
final class VoicePool {
    
    // MARK: - Configuration
    
    /// Minimum allowed polyphony
    static let minPolyphony = 3
    
    /// Maximum allowed polyphony
    static let maxPolyphony = 12
    
    /// Current voice count
    private(set) var voiceCount: Int
    
    // MARK: - Voice Management
    
    /// All available voices
    private(set) var voices: [PolyphonicVoice] = []
    
    /// Mixer to combine all voice outputs
    let voiceMixer: Mixer
    
    /// Round-robin allocation pointer
    private var currentVoiceIndex: Int = 0
    
    /// Maps key indices (0-17) to their currently playing voices
    /// Enables precise release tracking without frequency matching
    private var keyToVoiceMap: [Int: PolyphonicVoice] = [:]
    
    /// Flag to track if the voice pool has been initialized
    private var isInitialized: Bool = false
    
    // MARK: - Global Modulation (Phase 5)
    
    /// Global LFO parameters affecting all voices or global parameters
    var globalLFO: GlobalLFOParameters = .default
    
    /// Global modulation runtime state (phase tracking, tempo)
    var globalModulationState = GlobalModulationState()
    
    // MARK: - Initialization
    
    /// Creates a voice pool with the specified polyphony
    /// - Parameter voiceCount: Number of voices (clamped to min/max range)
    init(voiceCount: Int = 5) {
        // Clamp voice count to valid range
        self.voiceCount = min(max(voiceCount, Self.minPolyphony), Self.maxPolyphony)
        
        // Create mixer first
        self.voiceMixer = Mixer()
        
        // Create all voices
        let voiceParams = VoiceParameters.default
        for _ in 0..<self.voiceCount {
            let voice = PolyphonicVoice(parameters: voiceParams)
            voices.append(voice)
        }
        
        // Connect all voices to mixer
        for voice in voices {
            voiceMixer.addInput(voice.envelope)
        }
    }
    
    /// Initializes all voices (starts oscillators)
    /// Must be called after the audio engine is started
    func initialize() {
        guard !isInitialized else {
            print("🎵 VoicePool already initialized, skipping")
            return
        }
        
        for voice in voices {
            voice.initialize()
        }
        
        isInitialized = true
        print("🎵 VoicePool initialized with \(voiceCount) voices")
    }
    
    // MARK: - Voice Allocation
    
    /// Finds an available voice, or steals the oldest one if all are busy
    /// Uses round-robin allocation starting from current index
    private func findAvailableVoice() -> PolyphonicVoice {
        var checkedCount = 0
        var index = currentVoiceIndex
        
        // First pass: look for available voices
        while checkedCount < voiceCount {
            if voices[index].isAvailable {
                currentVoiceIndex = index
                return voices[index]
            }
            
            index = (index + 1) % voiceCount
            checkedCount += 1
        }
        
        // No available voice found - steal the oldest one
        // Find voice with earliest trigger time
        let oldestVoice = voices.min(by: { $0.triggerTime < $1.triggerTime })!
        
        // Force release the oldest voice (instant cutoff as per requirements)
        oldestVoice.envelope.closeGate()
        oldestVoice.isAvailable = true  // Mark immediately available
        
        print("⚠️ Voice stealing: Took voice triggered at \(oldestVoice.triggerTime)")
        
        return oldestVoice
    }
    
    /// Increments to the next voice index (round-robin)
    private func incrementVoiceIndex() {
        currentVoiceIndex = (currentVoiceIndex + 1) % voiceCount
    }
    
    // MARK: - Note Triggering
    
    /// Allocates a voice and triggers it with the specified frequency
    /// - Parameters:
    ///   - frequency: The frequency to play
    ///   - keyIndex: The key index (0-17) triggering this note
    /// - Returns: The allocated voice (for reference if needed)
    @discardableResult
    func allocateVoice(frequency: Double, forKey keyIndex: Int) -> PolyphonicVoice {
        guard isInitialized else {
            assertionFailure("VoicePool must be initialized before allocating voices")
            return voices[0]
        }
        
        // Find an available voice (or steal one)
        let voice = findAvailableVoice()
        
        // Set frequency and trigger
        voice.setFrequency(frequency)
        voice.trigger()
        
        // Map this key to the voice for precise release tracking
        keyToVoiceMap[keyIndex] = voice
        
        print("🎵 Key \(keyIndex): Allocated voice, frequency \(frequency) Hz")
        
        // Move to next voice for round-robin
        incrementVoiceIndex()
        
        return voice
    }
    
    /// Releases the voice associated with a specific key
    /// - Parameter keyIndex: The key index (0-17) to release
    func releaseVoice(forKey keyIndex: Int) {
        guard let voice = keyToVoiceMap[keyIndex] else {
            print("⚠️ Key \(keyIndex): No voice found to release")
            return
        }
        
        // Start envelope release
        voice.release()
        
        print("🎵 Key \(keyIndex): Released")
        
        // Remove mapping immediately - key is no longer pressed
        keyToVoiceMap.removeValue(forKey: keyIndex)
        
        // Note: Voice will mark itself available after release duration completes
    }
    
    /// Stops all voices immediately
    func stopAll() {
        for voice in voices {
            voice.envelope.closeGate()
            voice.isAvailable = true
        }
        keyToVoiceMap.removeAll()
        print("🎵 All voices stopped")
    }
    
    // MARK: - Polyphony Adjustment
    
    /// Changes the polyphony (number of voices)
    /// WARNING: This requires recreating the voice pool and should be done carefully
    /// Not implemented in Phase 1 - voices are fixed at initialization
    func setPolyphony(_ count: Int) {
        // TODO: Phase 8 - Implement runtime polyphony adjustment
        // Requires stopping engine, recreating voices, reconnecting to mixer
        print("⚠️ Runtime polyphony adjustment not yet implemented")
    }
    
    // MARK: - Parameter Updates
    
    /// Updates oscillator parameters for all voices
    func updateAllVoiceOscillators(_ parameters: OscillatorParameters) {
        for voice in voices {
            voice.updateOscillatorParameters(parameters)
        }
    }
    
    /// Updates filter parameters for all voices
    func updateAllVoiceFilters(_ parameters: FilterParameters) {
        for voice in voices {
            voice.updateFilterParameters(parameters)
        }
    }
    
    /// Updates envelope parameters for all voices
    func updateAllVoiceEnvelopes(_ parameters: EnvelopeParameters) {
        for voice in voices {
            voice.updateEnvelopeParameters(parameters)
        }
    }
    
    /// Updates detune mode for all voices
    func updateDetuneMode(_ mode: DetuneMode) {
        for voice in voices {
            voice.detuneMode = mode
        }
    }
    
    /// Updates frequency offset ratio for all voices (proportional mode)
    func updateFrequencyOffsetRatio(_ ratio: Double) {
        for voice in voices {
            voice.frequencyOffsetRatio = ratio
        }
    }
    
    /// Updates frequency offset in Hz for all voices (constant mode)
    func updateFrequencyOffsetHz(_ hz: Double) {
        for voice in voices {
            voice.frequencyOffsetHz = hz
        }
    }
    
    /// DEPRECATED: Use updateFrequencyOffsetRatio instead
    @available(*, deprecated, renamed: "updateFrequencyOffsetRatio")
    func updateFrequencyOffset(_ offset: Double) {
        updateFrequencyOffsetRatio(offset)
    }
    
    // MARK: - Modulation (Phase 5)
    
    /// Control-rate timer for modulation updates (Phase 5B+)
    private var modulationTimer: Timer?
    
    /// Updates global LFO parameters
    func updateGlobalLFO(_ parameters: GlobalLFOParameters) {
        globalLFO = parameters
    }
    
    /// Updates modulation parameters for all voices
    func updateAllVoiceModulation(_ parameters: VoiceModulationParameters) {
        for voice in voices {
            voice.updateModulationParameters(parameters)
        }
    }
    
    /// Starts the modulation update loop (Phase 5B)
    /// Control rate: 200 Hz (5ms intervals) for smooth LFOs and snappy envelopes
    func startModulation() {
        // TODO: Phase 5B - Implement control-rate timer
        // Will be implemented as:
        // modulationTimer = Timer.scheduledTimer(
        //     withTimeInterval: ControlRateConfig.updateInterval,
        //     repeats: true
        // ) { [weak self] _ in
        //     self?.updateModulation()
        // }
        print("🎵 Modulation system ready (timer will start in Phase 5B)")
    }
    
    /// Stops the modulation update loop
    func stopModulation() {
        modulationTimer?.invalidate()
        modulationTimer = nil
    }
    
    /// Updates modulation for all active voices (Phase 5B+)
    /// Called by control-rate timer at 200 Hz
    private func updateModulation() {
        // TODO: Phase 5B - Implement modulation calculation
        // let deltaTime = ControlRateConfig.updateInterval
        //
        // // Update global LFO phase
        // if globalLFO.isEnabled {
        //     globalModulationState.globalLFOPhase += deltaTime * globalLFO.frequency
        //     globalModulationState.globalLFOPhase = 
        //         globalModulationState.globalLFOPhase.truncatingRemainder(dividingBy: 1.0)
        // }
        //
        // // Calculate global LFO value
        // let globalLFOValue = globalLFO.currentValue(phase: globalModulationState.globalLFOPhase)
        //
        // // Update all active voices
        // for voice in voices where !voice.isAvailable {
        //     voice.applyModulation(globalLFOValue: globalLFOValue, deltaTime: deltaTime)
        // }
    }
    
    // MARK: - Diagnostics
    
    /// Returns the number of currently active (unavailable) voices
    var activeVoiceCount: Int {
        voices.filter { !$0.isAvailable }.count
    }
    
    /// Prints current voice pool status
    func printStatus() {
        print("🎵 Voice Pool Status:")
        print("   Total voices: \(voiceCount)")
        print("   Active voices: \(activeVoiceCount)")
        print("   Available voices: \(voiceCount - activeVoiceCount)")
        print("   Keys pressed: \(keyToVoiceMap.count)")
        print("   Global LFO: \(globalLFO.isEnabled ? "enabled" : "disabled")")
        print("   Modulation timer: \(modulationTimer != nil ? "running" : "stopped")")
    }
}
