//
//  AudioParameters.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 16/12/2025.
//

import Foundation
import Combine
import AudioKit
import DunneAudioKit
import AudioKitEX
import SoundpipeAudioKit

// MARK: - Parameter Models

/// Waveform types available for the FM oscillator
enum OscillatorWaveform: String, Codable, Equatable, CaseIterable {
    case sine
    case triangle
    case square
    
    /// User-friendly display name
    var displayName: String {
        switch self {
        case .sine: return "Sine"
        case .triangle: return "Triangle"
        case .square: return "Square"
        }
    }
    
    /// Convert to AudioKit Table
    func makeTable() -> Table {
        switch self {
        case .sine: return Table(.sine)
        case .triangle: return Table(.triangle)
        case .square: return Table(.square)
        }
    }
}

/// Parameters for the FM oscillator
struct OscillatorParameters: Codable, Equatable {
    var carrierMultiplier: Double
    var modulatingMultiplier: Double
    var modulationIndex: Double
    var amplitude: Double
    var waveform: OscillatorWaveform
    
    static let `default` = OscillatorParameters(
        carrierMultiplier: 1.0,
        modulatingMultiplier: 2.0,
        modulationIndex: 0.95,
        amplitude: 0.5,
        waveform: .triangle
    )
}

/// Parameters for the low-pass filter
struct FilterParameters: Codable, Equatable {
    var cutoffFrequency: Double
    var resonance: Double
    
    static let `default` = FilterParameters(
        cutoffFrequency: 1200,
        resonance: 1.5
    )
    
    /// Clamps cutoff to valid range (20 Hz - 20 kHz)
    var clampedCutoff: Double {
        min(max(cutoffFrequency, 10), 20_000)
    }
}

/// Parameters for the amplitude envelope
struct EnvelopeParameters: Codable, Equatable {
    var attackDuration: Double
    var decayDuration: Double
    var sustainLevel: Double
    var releaseDuration: Double
    
    static let `default` = EnvelopeParameters(
        attackDuration: 0.01,
        decayDuration: 0.2,
        sustainLevel: 0.7,
        releaseDuration: 0.2
    )
}

/// Parameters for stereo panning (-1 = left, 0 = center, +1 = right)
struct PanParameters: Codable, Equatable {
    var pan: Double
    
    static let `default` = PanParameters(pan: 0.0)
    
    /// Clamps pan to valid range
    var clampedPan: Double {
        min(max(pan, -1.0), 1.0)
    }
}

/// Combined parameters for a single voice
struct VoiceParameters: Codable, Equatable {
    var oscillator: OscillatorParameters
    var filter: FilterParameters
    var envelope: EnvelopeParameters
    var pan: PanParameters
    
    static let `default` = VoiceParameters(
        oscillator: .default,
        filter: .default,
        envelope: .default,
        pan: .default
    )
}

/// Parameters for the stereo delay effect
struct DelayParameters: Codable, Equatable {
    var time: Double
    var feedback: Double
    var dryWetMix: Double
    var pingPong: Bool
    
    static let `default` = DelayParameters(
        time: 0.5,
        feedback: 0.2,
        dryWetMix: 0.5,
        pingPong: true
    )
}

/// Parameters for the reverb effect
struct ReverbParameters: Codable, Equatable {
    var feedback: Double
    var cutoffFrequency: Double
    var dryWetBalance: Double  // 0 = all dry, 1 = all wet
    
    static let `default` = ReverbParameters(
        feedback: 0.9,
        cutoffFrequency: 10_000,
        dryWetBalance: 0.0
    )
}

/// Master parameters affecting the entire audio engine
struct MasterParameters: Codable, Equatable {
    var delay: DelayParameters
    var reverb: ReverbParameters
    
    static let `default` = MasterParameters(
        delay: .default,
        reverb: .default
    )
}

// MARK: - Complete Parameter Set (for Presets)

/// A complete snapshot of all audio parameters - used for presets
struct AudioParameterSet: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var voiceTemplate: VoiceParameters  // Template applied to all voices
    var master: MasterParameters
    var createdAt: Date
    
    static let `default` = AudioParameterSet(
        id: UUID(),
        name: "Default",
        voiceTemplate: .default,
        master: .default,
        createdAt: Date()
    )
}

// MARK: - Parameter Manager

/// Central manager for all audio parameters
/// This provides the interface between UI and the AudioKit engine
@MainActor
final class AudioParameterManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AudioParameterManager()
    
    // MARK: - Current Parameters
    
    /// Current master parameters (delay, reverb)
    @Published private(set) var master: MasterParameters = .default
    
    /// Current voice template - used as base for all voices
    @Published private(set) var voiceTemplate: VoiceParameters = .default
    
    // MARK: - Initialization
    
    private init() {
        // Private to enforce singleton
    }
    
    // MARK: - Master Parameter Updates
    
    func updateDelay(_ parameters: DelayParameters) {
        master.delay = parameters
        applyDelayParameters()
    }
    
    func updateDelayMix(_ mix: Double) {
        master.delay.dryWetMix = mix
        fxDelay?.dryWetMix = AUValue(1-mix)
    }
    
    func updateDelayTime(_ time: Double) {
        master.delay.time = time
        fxDelay?.time = AUValue(time)
    }
    
    func updateDelayFeedback(_ feedback: Double) {
        master.delay.feedback = feedback
        fxDelay?.feedback = AUValue(feedback)
    }
    
    func updateReverb(_ parameters: ReverbParameters) {
        master.reverb = parameters
        applyReverbParameters()
    }
    
    func updateReverbMix(_ balance: Double) {
        master.reverb.dryWetBalance = balance
        reverbDryWet?.balance = AUValue(balance)
    }
    
    func updateReverbFeedback(_ feedback: Double) {
        master.reverb.feedback = feedback
        fxReverb?.feedback = AUValue(feedback)
    }
    
    // MARK: - Voice Template Updates
    
    /// Update the voice template (new voices will use these parameters)
    /// Note: Does not affect currently playing voices - only new voice allocations
    func updateVoiceTemplate(_ parameters: VoiceParameters) {
        voiceTemplate = parameters
    }
    
    func updateTemplateFilter(_ parameters: FilterParameters) {
        voiceTemplate.filter = parameters
    }
    
    func updateTemplateOscillator(_ parameters: OscillatorParameters) {
        voiceTemplate.oscillator = parameters
    }
    
    func updateTemplateEnvelope(_ parameters: EnvelopeParameters) {
        voiceTemplate.envelope = parameters
    }
    
    // MARK: - Preset Management
    
    /// Load a complete parameter set (preset)
    func loadPreset(_ preset: AudioParameterSet) {
        voiceTemplate = preset.voiceTemplate
        master = preset.master
        
        applyAllParameters()
    }
    
    /// Create a preset from current parameters
    func createPreset(named name: String) -> AudioParameterSet {
        AudioParameterSet(
            id: UUID(),
            name: name,
            voiceTemplate: voiceTemplate,
            master: master,
            createdAt: Date()
        )
    }
    
    // MARK: - Application to AudioKit
    
    /// Apply all parameters to the audio engine
    private func applyAllParameters() {
        applyDelayParameters()
        applyReverbParameters()
    }
    
    private func applyDelayParameters() {
        guard let delay = fxDelay else { return }
        delay.time = AUValue(master.delay.time)
        delay.feedback = AUValue(master.delay.feedback)
        delay.dryWetMix = AUValue(master.delay.dryWetMix)
    }
    
    private func applyReverbParameters() {
        guard let reverb = fxReverb, let dryWet = reverbDryWet else { return }
        reverb.feedback = AUValue(master.reverb.feedback)
        reverb.cutoffFrequency = AUValue(master.reverb.cutoffFrequency)
        dryWet.balance = AUValue(master.reverb.dryWetBalance)
    }
}

// MARK: - Convenience Extensions (Deprecated - Old System Only)

extension AudioParameterManager {
    
    /// Maps a touch location to filter cutoff frequency (deprecated - for old 18-voice system)
    /// Note: The new voice pool system handles this per-voice in MainKeyboardView
    @available(*, deprecated, message: "Use per-voice handling in MainKeyboardView instead")
    func mapTouchToFilterCutoff(
        voiceIndex: Int,
        touchX: CGFloat,
        viewWidth: CGFloat,
        range: ClosedRange<Double> = 10...20_000
    ) {
        // No-op: old system removed
    }
    
    /// Maps aftertouch to filter cutoff (deprecated - for old 18-voice system)
    @available(*, deprecated, message: "Use per-voice handling in MainKeyboardView instead")
    func mapAftertouchToFilterCutoff(
        voiceIndex: Int,
        touchX: CGFloat,
        viewWidth: CGFloat,
        range: ClosedRange<Double> = 10...20_000
    ) {
        // No-op: old system removed
    }
    
    /// Maps aftertouch to filter cutoff with smoothing (deprecated - for old 18-voice system)
    @available(*, deprecated, message: "Use per-voice handling in MainKeyboardView instead")
    func mapAftertouchToFilterCutoffSmoothed(
        voiceIndex: Int,
        initialTouchX: CGFloat,
        currentTouchX: CGFloat,
        viewWidth: CGFloat,
        sensitivity: Double = 2.5,
        range: ClosedRange<Double> = 500...12_000,
        smoothingFactor: Double = 0.5
    ) {
        // No-op: old system removed
    }
    
    /// Resets voice filter to template (deprecated - for old 18-voice system)
    @available(*, deprecated, message: "Use per-voice handling in MainKeyboardView instead")
    func resetVoiceFilterToTemplate(at voiceIndex: Int) {
        // No-op: old system removed
    }
    
    /// Maps touch to pan (deprecated - for old 18-voice system)
    @available(*, deprecated, message: "Pan is now fixed in stereo design")
    func mapTouchToPan(
        voiceIndex: Int,
        touchX: CGFloat,
        viewWidth: CGFloat
    ) {
        // No-op: old system removed
    }
    
    /// Maps touch to amplitude (deprecated - for old 18-voice system)
    @available(*, deprecated, message: "Use per-voice handling in MainKeyboardView instead")
    func mapTouchToAmplitude(
        voiceIndex: Int,
        touchX: CGFloat,
        viewWidth: CGFloat
    ) {
        // No-op: old system removed
    }
    
    /// Maps touch Y to resonance (deprecated - experimental feature)
    @available(*, deprecated, message: "Not currently used")
    func mapTouchToResonance(
        voiceIndex: Int,
        touchY: CGFloat,
        viewHeight: CGFloat,
        range: ClosedRange<Double> = 0...0.9
    ) {
        // No-op: experimental feature removed
    }
}

