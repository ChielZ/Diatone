//
//  ModulationSystem.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 20/12/2025.
//

import Foundation
import AudioKit

// MARK: - Modulation Destinations

/// Defines where modulation can be routed
enum ModulationDestination: String, Codable, CaseIterable {
    // Voice-level destinations (per-voice LFO can target these)
    case filterCutoff
    case osc1Amplitude
    case osc2Amplitude
    case frequencyOffset        // Stereo spread amount
    case envelopeAmount
    
    // Global-level destinations (only global LFO can target these)
    case delayTime
    case delayFeedback
    case reverbMix
    
    /// Returns true if this destination can be modulated by per-voice LFOs
    var isVoiceLevel: Bool {
        switch self {
        case .filterCutoff, .osc1Amplitude, .osc2Amplitude, .frequencyOffset, .envelopeAmount:
            return true
        case .delayTime, .delayFeedback, .reverbMix:
            return false
        }
    }
    
    /// Returns true if this destination can be modulated by global LFO
    var isGlobalLevel: Bool {
        return true  // Global LFO can target anything
    }
}

// MARK: - LFO Modulator

/// Represents a low-frequency oscillator for modulation
/// NOTE: This is a data structure for Phase 5 implementation
/// Actual LFO audio processing will be implemented in Phase 5
struct LFOModulator: Codable, Equatable {
    var rate: Double                      // Hz (0.01 - 20 Hz)
    var depth: Double                     // 0.0 - 1.0
    var waveform: OscillatorWaveform      // Sine, triangle, square
    var destination: ModulationDestination
    var isEnabled: Bool
    
    static let `default` = LFOModulator(
        rate: 2.0,
        depth: 0.5,
        waveform: .sine,
        destination: .filterCutoff,
        isEnabled: false
    )
    
    // Phase 5: Will implement actual LFO value generation
    // For now, this is just a placeholder structure
    func currentValue() -> Double {
        // TODO: Phase 5 - Implement actual LFO oscillation
        // Will use AudioKit's Oscillator or manual sine calculation
        return 0.0
    }
}

// MARK: - Modulation Envelope

/// Represents an envelope generator for modulation (not amplitude)
/// This is separate from the amplitude envelope and can modulate parameters over time
struct ModulationEnvelope: Codable, Equatable {
    var attack: Double
    var decay: Double
    var sustain: Double
    var release: Double
    var depth: Double                     // 0.0 - 1.0
    var destination: ModulationDestination
    var isEnabled: Bool
    
    static let `default` = ModulationEnvelope(
        attack: 0.1,
        decay: 0.2,
        sustain: 0.5,
        release: 0.3,
        depth: 0.5,
        destination: .filterCutoff,
        isEnabled: false
    )
    
    // Phase 5: Will implement actual envelope value generation
    func currentValue(timeInEnvelope: Double, isGateOpen: Bool) -> Double {
        // TODO: Phase 5 - Implement envelope stage calculation
        return 0.0
    }
}

// MARK: - Modulation Parameters (for VoiceParameters expansion in Phase 5)

/// Container for all modulation sources for a voice
/// This will be integrated into VoiceParameters in Phase 5
struct ModulationParameters: Codable, Equatable {
    var voiceLFO: LFOModulator              // Per-voice LFO
    var modEnvelope1: ModulationEnvelope    // First mod envelope
    var modEnvelope2: ModulationEnvelope    // Second mod envelope (optional)
    
    static let `default` = ModulationParameters(
        voiceLFO: .default,
        modEnvelope1: .default,
        modEnvelope2: .default
    )
}

/// Global LFO that affects all voices
/// Lives in VoicePool, not in individual voices
struct GlobalLFOParameters: Codable, Equatable {
    var rate: Double
    var depth: Double
    var waveform: OscillatorWaveform
    var destination: ModulationDestination
    var isEnabled: Bool
    
    static let `default` = GlobalLFOParameters(
        rate: 1.0,
        depth: 0.3,
        waveform: .sine,
        destination: .filterCutoff,
        isEnabled: false
    )
}
