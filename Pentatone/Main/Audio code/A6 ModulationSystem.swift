//
//  A6 ModulationSystem.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 20/12/2025.
//

import Foundation
import AudioKit



// MARK: - LFO Waveforms

/// Waveform shapes available for LFO modulation
enum LFOWaveform: String, Codable, CaseIterable {
    case sine
    case triangle
    case square
    case sawtooth
    case reverseSawtooth
    
    var displayName: String {
        switch self {
        case .sine: return "Sine"
        case .triangle: return "Triangle"
        case .square: return "Square"
        case .sawtooth: return "Sawtooth"
        case .reverseSawtooth: return "Reverse Saw"
        }
    }
    
    /// Calculate the waveform value at a given phase
    /// - Parameters:
    ///   - phase: Current phase of the LFO (0.0 = start, 1.0 = end of cycle)
    ///   - bipolar: If true, returns -1.0 to +1.0 (for Global LFO). If false, uses Voice LFO behavior.
    /// - Returns: Raw waveform value in specified range
    ///
    /// **Voice LFO Behavior (bipolar = false):**
    /// - **Sine/Triangle**: Bipolar -1 to +1 (centered vibrato, starts at 0, natural for pitch modulation)
    /// - **Square/Sawtooth**: Unipolar 0 to 2 (rhythmic pulsing, double range for consistency)
    /// - **Reverse Sawtooth**: Unipolar 2 to 0 (reverse pulse, double range)
    func value(at phase: Double, bipolar: Bool = true) -> Double {
        // Normalize phase to 0-1 range (handle wraparound)
        let normalizedPhase = phase - floor(phase)
        
        let rawValue: Double
        
        switch self {
        case .sine:
            if bipolar {
                // Sine wave: smooth oscillation (bipolar: -1 to +1)
                rawValue = sin(normalizedPhase * 2.0 * .pi)
            } else {
                // Voice LFO: Same as bipolar (centered vibrato -1 to +1)
                // Perfect for pitch modulation - oscillates around nominal frequency
                // Starts at 0, rises to +1, dips to -1, returns to 0
                rawValue = sin(normalizedPhase * 2.0 * .pi)
            }
            
        case .triangle:
            if bipolar {
                // Triangle wave: linear rise and fall (bipolar: -1 to +1)
                // 0.0-0.5: rise from -1 to +1
                // 0.5-1.0: fall from +1 to -1
                if normalizedPhase < 0.5 {
                    rawValue = (normalizedPhase * 4.0) - 1.0  // -1 to +1
                } else {
                    rawValue = 3.0 - (normalizedPhase * 4.0)  // +1 to -1
                }
            } else {
                // Voice LFO: Same as bipolar (centered vibrato -1 to +1)
                // Phase shift by +90° (add 0.25 to phase) so it starts at 0 like sine
                // Perfect for smooth pitch sweeps around nominal frequency
                let shiftedPhase = normalizedPhase + 0.25
                let wrappedPhase = shiftedPhase - floor(shiftedPhase)  // Handle wraparound
                
                if wrappedPhase < 0.5 {
                    rawValue = (wrappedPhase * 4.0) - 1.0  // -1 to +1
                } else {
                    rawValue = 3.0 - (wrappedPhase * 4.0)  // +1 to -1
                }
            }
            
        case .square:
            if bipolar {
                // Square wave: instant transitions (bipolar: -1 to +1)
                // 0.0-0.5: +1
                // 0.5-1.0: -1
                rawValue = normalizedPhase < 0.5 ? 1.0 : -1.0
            } else {
                // Voice LFO: Unipolar with double range (0 to 2)
                // 0.0-0.5: 0 (base parameter value)
                // 0.5-1.0: 2 (full upward modulation, double the amount)
                // This maintains consistent total modulation range with sine/triangle
                rawValue = normalizedPhase < 0.5 ? 0.0 : 2.0
            }
            
        case .sawtooth:
            if bipolar {
                // Sawtooth wave: linear rise, instant drop (bipolar: -1 to +1)
                // 0.0-1.0: -1 to +1 (then instant drop to -1)
                rawValue = (normalizedPhase * 2.0) - 1.0
            } else {
                // Voice LFO: Unipolar with double range (0 to 2)
                // 0.0-1.0: 0 to 2 (then instant drop to 0)
                // Double range maintains consistent modulation depth with sine/triangle
                rawValue = normalizedPhase * 2.0
            }
            
        case .reverseSawtooth:
            if bipolar {
                // Reverse sawtooth: instant rise, linear fall (bipolar: -1 to +1)
                // 0.0-1.0: +1 to -1 (instant rise from -1 to +1 at start)
                rawValue = 1.0 - (normalizedPhase * 2.0)
            } else {
                // Voice LFO: Unipolar with double range (2 to 0)
                // 0.0-1.0: 2 to 0 (instant rise from 0 to 2 at start, then fall)
                // Double range maintains consistent modulation depth
                rawValue = 2.0 - (normalizedPhase * 2.0)
            }
        }
        
        return rawValue
    }
}

// MARK: - LFO Reset Mode

/// Determines how LFO phase is reset when a voice is triggered
enum LFOResetMode: String, Codable, CaseIterable {
    case free       // LFO runs continuously, ignores note triggers
    case trigger    // LFO resets to phase 0 on each note trigger
    case sync       // LFO syncs to tempo (global timing)
    
    var displayName: String {
        switch self {
        case .free: return "Free Running"
        case .trigger: return "Trigger Reset"
        case .sync: return "Tempo Sync"
        }
    }
}

// MARK: - LFO Frequency Mode

/// Determines whether LFO frequency is in Hz or tempo-synced
enum LFOFrequencyMode: String, Codable, CaseIterable {
    case hertz          // Direct Hz value (0-10 Hz)
    case tempoSync      // Tempo multiplier (1/4, 1/2, 1, 2, 4, etc.)
    
    var displayName: String {
        switch self {
        case .hertz: return "Hz"
        case .tempoSync: return "Tempo Sync"
        }
    }
}

// MARK: - LFO Tempo Sync Values

/// Musical subdivisions for tempo-synced LFO frequency
/// Represents how many cycles per 4 beats (one bar at 4/4)
/// At 120 BPM, 1 bar = 2 seconds, so:
/// - 1/32 = 0.0625 seconds per cycle = 16 Hz
/// - 1/16 = 0.125 seconds per cycle = 8 Hz
/// - 1/8 = 0.25 seconds per cycle = 4 Hz
/// - 1/4 = 0.5 seconds per cycle = 2 Hz
/// - 1/2 = 1 second per cycle = 1 Hz
/// - 1 = 2 seconds per cycle = 0.5 Hz
/// - 2 = 4 seconds per cycle = 0.25 Hz
/// - 4 = 8 seconds per cycle = 0.125 Hz
enum LFOSyncValue: Double, Codable, Equatable, CaseIterable {
    case thirtySecond = 32.0    // 1/32 - very fast
    case twentyFourth = 24.0
    case sixteenth = 16.0       // 1/16
    case twelfth = 12.0
    case eighth = 8.0           // 1/8
    case sixth = 6.0
    case quarter = 4.0          // 1/4
    case third = 3.0
    case half = 2.0             // 1/2
    case whole = 1.0            // 1 bar
    case two = 0.5              // 2 bars
    case three = 0.33333333
    case four = 0.25            // 4 bars
    
    var displayName: String {
        switch self {
        case .thirtySecond: return "1/32"
        case .twentyFourth: return "1/24"
        case .sixteenth: return "1/16"
        case .twelfth: return "1/12"
        case .eighth: return "1/8"
        case .sixth: return "1/6"
        case .quarter: return "1/4"
        case .third: return "1/3"
        case .half: return "1/2"
        case .whole: return "1/1"
        case .two: return "2/1"
        case .three: return "3/1"
        case .four: return "4/1"
        }
    }
    
    /// Convert to LFO frequency in Hz based on tempo
    /// Formula: (tempo / 60) × (rawValue / 4)
    /// Where rawValue represents cycles per 4 beats
    /// At 120 BPM: 1 beat = 0.5s, 4 beats = 2s
    /// - "1" (whole) = 1 cycle per 4 beats = 0.5 Hz
    /// - "1/4" (quarter) = 4 cycles per 4 beats = 2 Hz
    func frequencyInHz(tempo: Double) -> Double {
        let beatsPerSecond = tempo / 60.0
        let cyclesPerBeat = self.rawValue / 4.0
        return beatsPerSecond * cyclesPerBeat
    }
}

// MARK: - Voice LFO Parameters (Fixed Destinations)

/// Voice LFO with fixed destinations and individual amounts
/// Each voice has its own LFO instance with independent phase
/// Note: Voice LFO frequency is always in Hz (no tempo sync)
/// **IMPORTANT**: Voice LFO uses UNIPOLAR modulation (0.0 to 1.0)
/// All waveforms start at their minimum (nominal parameter value) and rise upward.
/// Amounts can be positive (increase parameter) or negative (decrease parameter).
struct VoiceLFOParameters: Codable, Equatable {
    // Configuration
    var waveform: LFOWaveform
    var resetMode: LFOResetMode
    var frequency: Double                      // Hz (0.01 - 20 Hz) - always in Hz, no tempo sync
    
    // Fixed destinations with individual amounts (unipolar LFO, amounts can be + or -)
    var amountToOscillatorPitch: Double        // semitones (Page 7, item 4) - positive = raise pitch, negative = lower pitch
    var amountToFilterFrequency: Double        // octaves (Page 7, item 5) - positive = raise cutoff, negative = lower cutoff
    var amountToModulatorLevel: Double         // modulation index (Page 7, item 6) - positive = brighten, negative = darken
    
    // Delay/ramp applied to all LFO outputs (Page 7, item 7)
    var delayTime: Double                      // 0 to 5 seconds
    
    var isEnabled: Bool
    
    static let `default` = VoiceLFOParameters(
        waveform: .sine,
        resetMode: .free,
        frequency: 5.0,
        amountToOscillatorPitch: 0.0,          // No vibrato by default
        amountToFilterFrequency: 0.0,          // No filter modulation by default
        amountToModulatorLevel: 0.0,           // No timbre modulation by default
        delayTime: 0.0,                        // Instant effect by default
        isEnabled: true
    )
    
    /// Check if any destination has a non-zero amount
    var hasActiveDestinations: Bool {
        return amountToOscillatorPitch != 0.0
            || amountToFilterFrequency != 0.0
            || amountToModulatorLevel != 0.0
    }
    
    /// Calculate the raw LFO waveform value at a given phase
    /// - Parameter phase: Current phase of the LFO (0.0 = start, 1.0 = end of cycle)
    /// - Returns: Raw LFO value in range 0.0 to 1.0 (unipolar, unscaled)
    func rawValue(at phase: Double) -> Double {
        guard isEnabled else { return 0.0 }
        return waveform.value(at: phase, bipolar: false)  // Voice LFO uses unipolar mode
    }
}

// MARK: - Modulation Envelopes (Fixed Destinations)

/// Modulator Envelope - affects FM modulation index only
/// This envelope shapes the timbre over the course of the note
struct ModulatorEnvelopeParameters: Codable, Equatable {
    // ADSR timing
    var attack: Double                         // Attack time in seconds
    var decay: Double                          // Decay time in seconds
    var sustain: Double                        // Sustain level (0.0 - 1.0)
    var release: Double                        // Release time in seconds
    
    // Fixed destination: Modulation Index only (Page 5, item 5)
    var amountToModulationIndex: Double        // Can be positive or negative
    
    var isEnabled: Bool
    
    static let `default` = ModulatorEnvelopeParameters(
        attack: 0.01,
        decay: 0.2,
        sustain: 0.3,
        release: 0.1,
        amountToModulationIndex: 0.0,          // No modulation by default
        isEnabled: true
    )
    
    /// Check if envelope has a non-zero amount
    var hasActiveDestinations: Bool {
        return amountToModulationIndex != 0.0
    }
}

/// Auxiliary Envelope - affects pitch, filter, and vibrato amount
/// This envelope provides additional timbral shaping beyond the mod envelope
struct AuxiliaryEnvelopeParameters: Codable, Equatable {
    // ADSR timing
    var attack: Double                         // Attack time in seconds
    var decay: Double                          // Decay time in seconds
    var sustain: Double                        // Sustain level (0.0 - 1.0)
    var release: Double                        // Release time in seconds
    
    // Fixed destinations with individual amounts (Page 6, items 5-7)
    var amountToOscillatorPitch: Double        // ±semitones (can be positive or negative)
    var amountToFilterFrequency: Double        // ±octaves (can be positive or negative)
    var amountToVibrato: Double                // Meta-modulation: scales voice LFO pitch amount
    
    var isEnabled: Bool
    
    static let `default` = AuxiliaryEnvelopeParameters(
        attack: 0.1,
        decay: 0.2,
        sustain: 0.5,
        release: 0.3,
        amountToOscillatorPitch: 0.0,          // No pitch sweep by default
        amountToFilterFrequency: 0.0,          // No filter sweep by default
        amountToVibrato: 0.0,                  // No vibrato modulation by default
        isEnabled: true
    )
    
    /// Check if any destination has a non-zero amount
    var hasActiveDestinations: Bool {
        return amountToOscillatorPitch != 0.0
            || amountToFilterFrequency != 0.0
            || amountToVibrato != 0.0
    }
}

/// Loudness Envelope - controls voice output level via fader gain
/// Replaces the built-in AmplitudeEnvelope node for better control over attack behavior
/// and ability to start from non-zero levels (critical for voice stealing and legato)
struct LoudnessEnvelopeParameters: Codable, Equatable {
    // ADSR timing
    var attack: Double                         // Attack time in seconds (LINEAR ramp)
    var decay: Double                          // Decay time in seconds (EXPONENTIAL)
    var sustain: Double                        // Sustain level (0.0 - 1.0)
    var release: Double                        // Release time in seconds (EXPONENTIAL)
    
    var isEnabled: Bool
    
    static let `default` = LoudnessEnvelopeParameters(
        attack: 0.001,
        decay: 0.0,
        sustain: 1.0,
        release: 0.0,
        isEnabled: true
    )
}

// MARK: - Key Tracking (Fixed Destinations)

/// Key tracking provides modulation based on the pitch of the triggered note
/// **NOTE-ON PROPERTY**: The key tracking value is calculated ONCE at note trigger
/// and remains constant for the lifetime of the note. This ensures consistent
/// filter behavior regardless of any pitch modulation (aux envelope, voice LFO).
/// Higher notes produce higher modulation values (positive octave offset from 440Hz reference).
struct KeyTrackingParameters: Codable, Equatable {
    // Fixed destinations with individual amounts (Page 5, items 6-7)
    var amountToFilterFrequency: Double        // Scales filter modulation (unipolar 0-1)
    var amountToVoiceLFOFrequency: Double      // Scales voice LFO frequency (unipolar 0-1)
    
    var isEnabled: Bool
    
    static let `default` = KeyTrackingParameters(
        amountToFilterFrequency: 0.0,          // No key tracking by default
        amountToVoiceLFOFrequency: 0.0,        // No LFO frequency tracking by default
        isEnabled: true
    )
    
    /// Check if any destination has a non-zero amount
    var hasActiveDestinations: Bool {
        return amountToFilterFrequency != 0.0
            || amountToVoiceLFOFrequency != 0.0
    }
    
    /// Calculate key tracking value based on frequency (called once at note-on)
    /// Returns the number of octaves from the reference frequency
    /// Reference: 440 Hz (A4) = 0.0 octaves
    /// Positive values = higher notes, negative values = lower notes
    func trackingValue(forFrequency frequency: Double) -> Double {
        // Direct octave calculation from reference frequency
        // This allows proper 1:1 octave tracking when amount = 1.0
        let referenceFreq = 440.0  // A4
        let octavesFromReference = log2(frequency / referenceFreq)
        return octavesFromReference  // No normalization - return raw octave offset
    }
}

// MARK: - Touch Modulation (Fixed Destinations)

/// Touch modulation from initial touch X position
/// The X coordinate where the key was first touched (applied at note-on)
struct TouchInitialParameters: Codable, Equatable {
    // Fixed destinations with individual amounts (Page 9, items 1-4)
    var amountToOscillatorAmplitude: Double    // Scales base amplitude (velocity-like)
    var amountToModEnvelope: Double            // Scales mod envelope amount (meta-modulation)
    var amountToAuxEnvPitch: Double            // Scales aux envelope pitch amount (meta-modulation)
    var amountToAuxEnvCutoff: Double           // Scales aux envelope filter amount (meta-modulation)
    
    var isEnabled: Bool
    
    static let `default` = TouchInitialParameters(
        amountToOscillatorAmplitude: 0.0,      // No velocity sensitivity by default
        amountToModEnvelope: 0.0,              // No envelope scaling by default
        amountToAuxEnvPitch: 0.0,              // No pitch envelope scaling by default
        amountToAuxEnvCutoff: 0.0,             // No filter envelope scaling by default
        isEnabled: true
    )
    
    /// Check if any destination has a non-zero amount
    var hasActiveDestinations: Bool {
        return amountToOscillatorAmplitude != 0.0
            || amountToModEnvelope != 0.0
            || amountToAuxEnvPitch != 0.0
            || amountToAuxEnvCutoff != 0.0
    }
}

/// Aftertouch modulation from change in X position while holding
/// Tracks movement of the finger while the key is held (continuous modulation)
struct TouchAftertouchParameters: Codable, Equatable {
    // Fixed destinations with individual amounts (Page 9, items 5-8)
    var amountToOscillatorPitch: Double        // ±semitones (bipolar modulation)
    var amountToFilterFrequency: Double        // ±octaves (bipolar modulation)
    var amountToModulatorLevel: Double         // ±modulation index (bipolar modulation)
    var amountToVibrato: Double                // Meta-modulation: adds to voice LFO pitch amount
    
    var isEnabled: Bool
    
    static let `default` = TouchAftertouchParameters(
        amountToOscillatorPitch: 0.0,          // No aftertouch pitch control by default
        amountToFilterFrequency: 0.0,          // No aftertouch filter control by default
        amountToModulatorLevel: 0.0,           // No aftertouch timbre control by default
        amountToVibrato: 0.0,                  // No aftertouch vibrato control by default
        isEnabled: true
    )
    
    /// Check if any destination has a non-zero amount
    var hasActiveDestinations: Bool {
        return amountToOscillatorPitch != 0.0
            || amountToFilterFrequency != 0.0
            || amountToModulatorLevel != 0.0
            || amountToVibrato != 0.0
    }
}

// MARK: - Complete Modulation System Parameters

/// Container for all modulation sources and routings for a single voice
/// All destinations are now fixed per source with individual amount controls
struct VoiceModulationParameters: Codable, Equatable {
    // Envelopes
    var modulatorEnvelope: ModulatorEnvelopeParameters   // Fixed: modulation index only
    var auxiliaryEnvelope: AuxiliaryEnvelopeParameters   // Fixed: pitch, filter, vibrato
    var loudnessEnvelope: LoudnessEnvelopeParameters     // Fixed: voice output level (replaces AmplitudeEnvelope)
    
    // LFO
    var voiceLFO: VoiceLFOParameters                     // Fixed: pitch, filter, modulator level
    
    // Touch/Key tracking
    var keyTracking: KeyTrackingParameters               // Fixed: filter freq, LFO freq
    var touchInitial: TouchInitialParameters             // Fixed: amplitude, env amounts (meta-mod)
    var touchAftertouch: TouchAftertouchParameters       // Fixed: filter, modulator, vibrato
    
    static let `default` = VoiceModulationParameters(
        modulatorEnvelope: .default,
        auxiliaryEnvelope: .default,
        loudnessEnvelope: .default,
        voiceLFO: .default,
        keyTracking: .default,
        touchInitial: .default,
        touchAftertouch: .default
    )
}

// MARK: - Global LFO Parameters (Fixed Destinations)

/// Global LFO that affects all voices synchronously
/// Lives in VoicePool, not in individual voices
struct GlobalLFOParameters: Codable, Equatable {
    // Configuration
    var waveform: LFOWaveform
    var resetMode: LFOResetMode             // Free or Sync (no trigger for global)
    var frequencyMode: LFOFrequencyMode
    var frequency: Double                   // Hz (0.01 - 20 Hz) when in hertz mode
    var syncValue: LFOSyncValue             // Musical division when in sync mode
    
    // Fixed destinations with individual amounts (Page 8, items 4-7)
    var amountToVoiceMixerVolume: Double    // ±volume (tremolo effect, applied to voice mixer)
    var amountToModulatorMultiplier: Double // ±modulator ratio (fine tuning of FM ratio)
    var amountToFilterFrequency: Double     // ±octaves
    var amountToDelayTime: Double           // ±seconds
    
    var isEnabled: Bool
    
    static let `default` = GlobalLFOParameters(
        waveform: .sine,
        resetMode: .free,
        frequencyMode: .hertz,
        frequency: 1.0,
        syncValue: .whole,                  // Default to 1 bar
        amountToVoiceMixerVolume: 0.0,      // No tremolo by default
        amountToModulatorMultiplier: 0.0,   // No FM ratio modulation by default
        amountToFilterFrequency: 0.0,       // No global filter modulation by default
        amountToDelayTime: 0.0,             // No delay time modulation by default
        isEnabled: true
    )
    
    /// Check if any destination has a non-zero amount
    var hasActiveDestinations: Bool {
        return amountToVoiceMixerVolume != 0.0
            || amountToModulatorMultiplier != 0.0
            || amountToFilterFrequency != 0.0
            || amountToDelayTime != 0.0
    }
    
    /// Get the actual frequency in Hz based on mode and tempo
    /// - Parameter tempo: Current tempo in BPM
    /// - Returns: Frequency in Hz
    func actualFrequency(tempo: Double) -> Double {
        switch resetMode {
        case .sync:
            // When in sync mode, always use tempo-based frequency
            return syncValue.frequencyInHz(tempo: tempo)
        case .free, .trigger:
            // When in free or trigger mode, use the Hz frequency
            return frequency
        }
    }
    
    /// Calculate the raw LFO waveform value at a given phase
    /// - Parameter phase: Current phase of the LFO (0.0 = start, 1.0 = end of cycle)
    /// - Returns: Raw LFO value in range -1.0 to +1.0 (bipolar, unscaled)
    func rawValue(at phase: Double) -> Double {
        guard isEnabled else { return 0.0 }
        return waveform.value(at: phase, bipolar: true)  // Global LFO uses bipolar mode
    }
}

// MARK: - Modulation State (Runtime)

/// Runtime state for modulation calculation
/// This tracks the current state of modulation sources during voice playback
/// Not part of presets (ephemeral state)
/// 
/// **NOTE-ON PROPERTIES** (calculated once at trigger, constant for note lifetime):
/// - `keyTrackingValue`: Octave offset based on note frequency (for filter tracking)
/// - `initialTouchX`: Touch position where note was triggered (for velocity-like modulation)
/// - `baseFrequency`: Unmodulated frequency set at note-on (reference for pitch modulation)
/// - `triggerTimestamp`: Precise CACurrentMediaTime() when note was triggered (for envelope sync)
/// 
/// **CONTINUOUS PROPERTIES** (updated at 200 Hz by modulation system):
/// - Envelope times, LFO phases, aftertouch position
/// - Current modulated frequency (includes pitch modulation)
struct ModulationState {
    // Envelope timing
    var modulatorEnvelopeTime: Double = 0.0
    var auxiliaryEnvelopeTime: Double = 0.0
    var loudnessEnvelopeTime: Double = 0.0      // NEW: Loudness envelope time
    var isGateOpen: Bool = false
    
    // Precise trigger timing for envelope synchronization
    var triggerTimestamp: TimeInterval = 0.0

    // Trigger sequence for thread-safe detection of new notes
    // Incremented by trigger(), detected by modulation loop to capture fresh timing
    var triggerSequence: UInt64 = 0
    var lastSeenTriggerSequence: UInt64 = 0

    // Attack phase timing - avoids timestamp sync issues between threads
    // Set by trigger(), checked by mod loop using its own clock
    var loudnessAttackEndTime: TimeInterval = 0.0
    var loudnessAttackDuration: Double = 0.0
    var loudnessAttackStartTime: TimeInterval = 0.0  // When attack began (for mod loop to calculate progress)
    
    // Track sustain level at gate close for proper release
    var modulatorSustainLevel: Double = 0.0
    var auxiliarySustainLevel: Double = 0.0
    var loudnessSustainLevel: Double = 0.0      // NEW: Loudness envelope sustain capture
    
    // LFO phase tracking
    var voiceLFOPhase: Double = 0.0        // 0.0 - 1.0 (one full cycle)
    
    // Voice LFO delay/ramp state
    var voiceLFODelayTimer: Double = 0.0   // Time since voice triggered
    var voiceLFORampFactor: Double = 0.0   // 0.0 to 1.0 (scales all voice LFO outputs)
    
    // Touch state
    var initialTouchX: Double = 0.0        // Normalized 0.0 - 1.0
    var currentTouchX: Double = 0.0        // Normalized 0.0 - 1.0
    
    // Key tracking (NOTE-ON property - calculated once at trigger)
    var keyTrackingValue: Double = 0.0     // Octave offset from reference (440Hz), set at note-on
    
    // Frequency tracking
    // NOTE: currentFrequency includes pitch modulation (aux env, voice LFO)
    // Use baseFrequency for note-on calculations to ensure consistency!
    var currentFrequency: Double = 440.0   // Current modulated frequency (Hz)
    
    // User-controlled base values (before modulation)
    // These are set by touch gestures and used as the base for modulation
    var baseAmplitude: Double = 0.5        // User's desired amplitude (0.0 - 1.0)
    var baseFilterCutoff: Double = 1200.0  // User's desired filter cutoff (Hz)
    var baseModulationIndex: Double = 1.0  // User's desired modulation index (0.0 - 10.0)
    var baseModulatorMultiplier: Double = 1.0  // User's desired FM ratio (0.1 - 20.0)
    var baseFrequency: Double = 440.0      // User's desired base frequency (Hz, unmodulated)
    
    // Loudness envelope state
    var loudnessStartLevel: Double = 0.0   // Starting level for loudness envelope attack (for voice stealing)

    // Modulator envelope start values (for smooth trigger/modulation handover)
    // These capture the parameter values at trigger so the modulation loop can
    // interpolate smoothly from the starting value to the peak during attack phase
    var modulatorStartModIndex: Double = 0.0   // Mod index value at trigger
    var modulatorPeakModIndex: Double = 0.0    // Target mod index at end of attack

    // Auxiliary envelope start values (for filter cutoff handover)
    var auxiliaryStartFilterCutoff: Double = 1200.0  // Filter cutoff at trigger
    var auxiliaryPeakFilterCutoff: Double = 1200.0   // Target filter cutoff at end of attack

    // Smoothing state for filter modulation
    var lastSmoothedFilterCutoff: Double? = nil  // Last smoothed filter value (for aftertouch smoothing)
    var filterSmoothingFactor: Double = 0.85     // 0.0 = no smoothing, 1.0 = maximum smoothing (0.85 = smooth 60Hz updates)
    
    /// Reset state when voice is triggered
    /// - Parameters:
    ///   - frequency: The note frequency being triggered
    ///   - touchX: The initial touch X position (0.0 - 1.0)
    ///   - resetLFOPhase: Whether to reset voice LFO phase (depends on LFO reset mode)
    ///   - keyTrackingParams: Key tracking parameters for calculating note-on offset
    mutating func reset(frequency: Double, touchX: Double, resetLFOPhase: Bool = true, keyTrackingParams: KeyTrackingParameters? = nil) {
        modulatorEnvelopeTime = 0.0
        auxiliaryEnvelopeTime = 0.0
        isGateOpen = true
        modulatorSustainLevel = 0.0
        auxiliarySustainLevel = 0.0
        
        // Only reset LFO phase if requested (trigger/sync mode)
        // Free mode keeps the phase running
        if resetLFOPhase {
            voiceLFOPhase = 0.0
        }
        
        // Reset voice LFO delay/ramp
        voiceLFODelayTimer = 0.0
        voiceLFORampFactor = 0.0
        
        initialTouchX = touchX
        currentTouchX = touchX
        currentFrequency = frequency
        baseFrequency = frequency  // Store the base frequency for modulation
        
        // Calculate key tracking value ONCE at note-on (true note-on property)
        // This remains constant for the lifetime of the note
        if let keyTracking = keyTrackingParams {
            keyTrackingValue = keyTracking.trackingValue(forFrequency: frequency)
        } else {
            keyTrackingValue = 0.0
        }
        
        // Reset smoothing state for new note
        lastSmoothedFilterCutoff = nil
    }
    
    /// Update state when gate closes (note released)
    /// Captures current envelope values for smooth release
    mutating func closeGate(modulatorValue: Double, auxiliaryValue: Double, loudnessValue: Double) {
        isGateOpen = false
        modulatorSustainLevel = modulatorValue
        auxiliarySustainLevel = auxiliaryValue
        loudnessSustainLevel = loudnessValue  // NEW: Capture loudness envelope value
        // Reset envelope times to 0 for release stage
        modulatorEnvelopeTime = 0.0
        auxiliaryEnvelopeTime = 0.0
        loudnessEnvelopeTime = 0.0  // NEW: Reset loudness envelope time
    }
    
    /// Update voice LFO delay ramp factor
    /// - Parameters:
    ///   - deltaTime: Time since last update
    ///   - delayTime: Total delay time (0 = instant, >0 = gradual ramp)
    mutating func updateVoiceLFODelayRamp(deltaTime: Double, delayTime: Double) {
        voiceLFODelayTimer += deltaTime
        
        if delayTime > 0.0 {
            // Linear ramp from 0 to 1 over delayTime
            if voiceLFODelayTimer < delayTime {
                voiceLFORampFactor = voiceLFODelayTimer / delayTime
            } else {
                voiceLFORampFactor = 1.0  // Full effect after delay
            }
        } else {
            // No delay: instant full effect
            voiceLFORampFactor = 1.0
        }
    }
}

// MARK: - Global Modulation State (Runtime)

/// Runtime state for global modulation
struct GlobalModulationState {
    var globalLFOPhase: Double = 0.0       // 0.0 - 1.0 (one full cycle)
    var currentTempo: Double = 120.0       // BPM for tempo sync
}

// MARK: - Modulation Router (New Fixed-Destination System)

/// Helper for calculating and applying modulation with fixed destinations
/// Implements the exact routing specified in the development roadmap
struct ModulationRouter {
    
    // MARK: - Envelope Value Calculation
    
    /// **ACTIVE ENVELOPE CALCULATOR** - Switch between linear, exponential, and hybrid here
    /// 
    /// This is the main envelope calculation method used throughout the system.
    /// Currently set to: **HYBRID** (linear attack, exponential decay/release)
    /// 
    /// Available envelope modes:
    /// 1. **Linear** (all stages linear) - Use `calculateEnvelopeValue`
    ///    - Pros: Perfect alignment with AudioKit ramps
    ///    - Cons: Less natural sound, especially on decay/release
    /// 
    /// 2. **Exponential** (all stages exponential) - Use `calculateExponentialEnvelopeValue`
    ///    - Pros: Analog-style character, natural sound
    ///    - Cons: Attack curve doesn't match AudioKit's linear ramps
    /// 
    /// 3. **Hybrid** (linear attack, exponential decay/release) - Use `calculateHybridEnvelopeValue`
    ///    - Pros: Best of both worlds - perfect trigger alignment + natural decay/release
    ///    - Cons: Mixed envelope curves (not a problem in practice)
    /// 
    /// **Why hybrid is recommended:**
    /// The trigger() method applies initial envelope modulation using AudioKit's `.ramp()`,
    /// which uses linear interpolation. The hybrid mode ensures:
    /// - Attack phase: Linear (matches trigger ramps perfectly, zero artifacts)
    /// - Decay/Release: Exponential (natural analog-style sound)
    static func calculateActiveEnvelopeValue(
        time: Double,
        isGateOpen: Bool,
        attack: Double,
        decay: Double,
        sustain: Double,
        release: Double,
        capturedLevel: Double = 0.0
    ) -> Double {
        // CURRENT MODE: Hybrid (linear attack, exponential decay/release) - RECOMMENDED
        return calculateHybridEnvelopeValue(
            time: time,
            isGateOpen: isGateOpen,
            attack: attack,
            decay: decay,
            sustain: sustain,
            release: release,
            capturedLevel: capturedLevel
        )
        
        // ALTERNATIVE MODE 1: Linear (all stages)
        // Uncomment this and comment out the hybrid version above to switch:
        /*
        return calculateEnvelopeValue(
            time: time,
            isGateOpen: isGateOpen,
            attack: attack,
            decay: decay,
            sustain: sustain,
            release: release,
            capturedLevel: capturedLevel
        )
        */
        
        // ALTERNATIVE MODE 2: Exponential (all stages)
        // Uncomment this and comment out the hybrid version above to switch:
        /*
        return calculateExponentialEnvelopeValue(
            time: time,
            isGateOpen: isGateOpen,
            attack: attack,
            decay: decay,
            sustain: sustain,
            release: release,
            capturedLevel: capturedLevel
        )
        */
    }
    
    /// Calculate ADSR envelope value at a given time (LINEAR version)
    /// This version uses linear ramps for all stages.
    /// - Parameters:
    ///   - time: Time in envelope (seconds)
    ///   - isGateOpen: Whether gate is open (attack/decay/sustain) or closed (release)
    ///   - attack: Attack time in seconds
    ///   - decay: Decay time in seconds
    ///   - sustain: Sustain level (0.0 - 1.0)
    ///   - release: Release time in seconds
    ///   - capturedLevel: Level when gate closed (for release stage)
    /// - Returns: Envelope value (0.0 - 1.0)
    static func calculateEnvelopeValue(
        time: Double,
        isGateOpen: Bool,
        attack: Double,
        decay: Double,
        sustain: Double,
        release: Double,
        capturedLevel: Double = 0.0
    ) -> Double {
        if isGateOpen {
            // Attack stage
            if time < attack {
                return attack > 0 ? time / attack : 1.0
            }
            // Decay stage
            else if time < (attack + decay) {
                let decayTime = time - attack
                let decayProgress = decay > 0 ? decayTime / decay : 1.0
                return 1.0 - (decayProgress * (1.0 - sustain))
            }
            // Sustain stage
            else {
                return sustain
            }
        } else {
            // Release stage
            if time < release {
                let releaseProgress = release > 0 ? time / release : 1.0
                return capturedLevel * (1.0 - releaseProgress)
            } else {
                return 0.0
            }
        }
    }
    
    // MARK: - Exponential Envelope Calculation
    
    /// Calculate ADSR envelope value with EXPONENTIAL curves (matches AudioKit AmplitudeEnvelope behavior)
    /// 
    /// This implementation mimics the analog-style exponential behavior of the C `adsr.c` code.
    /// Time constants represent τ (tau), where the envelope reaches ~63% of target in τ seconds.
    /// 
    /// **Key differences from linear envelopes:**
    /// - Attack: Exponential approach to peak (fast start, slow finish)
    /// - Decay: Exponential decay to sustain (~63% in τ seconds)
    /// - Release: Exponential decay to zero (~63% in τ seconds)
    /// 
    /// **Time constant behavior:**
    /// - After 1τ: 63% complete (37% remaining)
    /// - After 3τ: 95% complete (5% remaining)
    /// - After 5τ: 99.3% complete (0.7% remaining)
    /// - After 6.91τ: 99.9% complete (-60dB)
    /// 
    /// **Usage Example:**
    /// ```swift
    /// // To use exponential envelopes, simply replace calculateEnvelopeValue with calculateExponentialEnvelopeValue
    /// let modEnvValue = ModulationRouter.calculateExponentialEnvelopeValue(
    ///     time: state.modulatorEnvelopeTime,
    ///     isGateOpen: state.isGateOpen,
    ///     attack: params.modulatorEnvelope.attack,
    ///     decay: params.modulatorEnvelope.decay,
    ///     sustain: params.modulatorEnvelope.sustain,
    ///     release: params.modulatorEnvelope.release,
    ///     capturedLevel: state.modulatorSustainLevel
    /// )
    /// 
    /// // If you want to convert UI time values (practical time) to time constants:
    /// let userDecayTime = 1.0  // User wants "1 second" decay
    /// let actualTau = ModulationRouter.convertPracticalTimeToTau(userDecayTime)  // ≈ 0.145 seconds
    /// params.modulatorEnvelope.decay = actualTau
    /// 
    /// // Or display time constants as practical times:
    /// let displayTime = ModulationRouter.convertTauToPracticalTime(params.modulatorEnvelope.decay)
    /// // User sees: "Decay: 1.0s" (time to near-silence) instead of "Decay: 0.145s" (time constant)
    /// ```
    /// 
    /// - Parameters:
    ///   - time: Time in current envelope stage (seconds)
    ///   - isGateOpen: Whether gate is open (attack/decay/sustain) or closed (release)
    ///   - attack: Attack time constant in seconds (τ)
    ///   - decay: Decay time constant in seconds (τ)
    ///   - sustain: Sustain level (0.0 - 1.0)
    ///   - release: Release time constant in seconds (τ)
    ///   - capturedLevel: Level when gate closed (for release stage)
    /// - Returns: Envelope value (0.0 - 1.0)
    static func calculateExponentialEnvelopeValue(
        time: Double,
        isGateOpen: Bool,
        attack: Double,
        decay: Double,
        sustain: Double,
        release: Double,
        capturedLevel: Double = 0.0
    ) -> Double {
        if isGateOpen {
            // Attack stage: exponential rise from 0 to 1
            // Attack is considered complete when we reach 99% (or when attack time expires)
            let attackComplete = (attack > 0) ? (1.0 - exp(-time / (attack * 0.6))) : 1.0
            
            if attackComplete < 0.99 {
                // Still in attack phase
                return attackComplete
            }
            
            // Decay stage: exponential decay from 1.0 to sustain
            // Calculate time spent in decay (time beyond attack completion)
            let attackDuration = attack > 0 ? (attack * 0.6 * log(100.0)) : 0.0  // Time to reach 99%
            let decayTime = max(0, time - attackDuration)
            
            return calculateExponentialApproach(
                time: decayTime,
                startValue: 1.0,
                targetValue: sustain,
                tau: decay
            )
        } else {
            // Release stage: exponential decay from captured level to 0
            return calculateExponentialApproach(
                time: time,
                startValue: capturedLevel,
                targetValue: 0.0,
                tau: release
            )
        }
    }
    
    /// Calculate exponential approach from start value to target value
    /// Uses the exponential formula: y(t) = target + (start - target) × e^(-t/τ)
    /// This creates the classic RC circuit charging/discharging curve
    /// - Parameters:
    ///   - time: Time since start of this stage (seconds)
    ///   - startValue: Starting value (where we're coming from)
    ///   - targetValue: Target value (where we're going to)
    ///   - tau: Time constant τ in seconds
    /// - Returns: Current envelope value
    private static func calculateExponentialApproach(
        time: Double,
        startValue: Double,
        targetValue: Double,
        tau: Double
    ) -> Double {
        guard tau > 0 else { return targetValue }
        
        // Exponential approach formula
        // At t=0: returns startValue
        // At t=∞: approaches targetValue
        // At t=τ: 63% of the way from start to target
        let coefficient = exp(-time / tau)
        let value = targetValue + (startValue - targetValue) * coefficient
        
        return max(0.0, min(1.0, value))
    }
    
    /// Convert a "practical time" (time to -60dB) to a time constant τ
    /// Use this if you want to display times as "time to near-silence" rather than time constants
    /// - Parameter time60dB: Time in seconds to reach -60dB (0.1% of original)
    /// - Returns: Time constant τ in seconds
    static func convertPracticalTimeToTau(_ time60dB: Double) -> Double {
        return time60dB / 6.91
    }
    
    /// Convert a time constant τ to "practical time" (time to -60dB)
    /// Use this for display purposes to show users intuitive time values
    /// - Parameter tau: Time constant in seconds
    /// - Returns: Time in seconds to reach -60dB (0.1% of original)
    static func convertTauToPracticalTime(_ tau: Double) -> Double {
        return tau * 6.91
    }
    
    // MARK: - Hybrid Envelope Calculation (Linear Attack + Exponential Decay/Release)
    
    /// Calculate ADSR envelope value with HYBRID curves (RECOMMENDED)
    /// 
    /// This implementation combines the best aspects of linear and exponential envelopes:
    /// - **Attack**: Linear (matches AudioKit ramps perfectly, no trigger artifacts)
    /// - **Decay**: Exponential (natural analog-style sound)
    /// - **Release**: Exponential (smooth natural fadeout)
    /// 
    /// **Why hybrid is ideal:**
    /// 1. The trigger() method uses AudioKit's `.ramp()` for attack, which is linear
    /// 2. Linear attack ensures perfect synchronization (no pops/clicks)
    /// 3. Exponential decay/release provides natural, musical envelope character
    /// 4. No need to compromise between timing accuracy and sound quality
    /// 
    /// **Attack behavior (Linear):**
    /// - Constant rate of change from 0 to 1
    /// - Matches the linear ramp applied at trigger time
    /// - Seamless handoff from trigger ramp to control rate updates
    /// 
    /// **Decay/Release behavior (Exponential):**
    /// - Natural RC circuit-style decay curves
    /// - Smooth, musical fadeouts
    /// - Uses time constants (τ) for predictable behavior
    /// 
    /// **Time constant behavior for decay/release:**
    /// - After 1τ: 63% complete (37% remaining)
    /// - After 3τ: 95% complete (5% remaining)
    /// - After 5τ: 99.3% complete (0.7% remaining)
    /// 
    /// **Usage Example:**
    /// ```swift
    /// let envValue = ModulationRouter.calculateHybridEnvelopeValue(
    ///     time: state.modulatorEnvelopeTime,
    ///     isGateOpen: state.isGateOpen,
    ///     attack: 0.05,    // 50ms linear attack
    ///     decay: 0.2,      // 200ms exponential decay
    ///     sustain: 0.3,    // 30% sustain level
    ///     release: 0.3,    // 300ms exponential release
    ///     capturedLevel: state.modulatorSustainLevel
    /// )
    /// ```
    /// 
    /// - Parameters:
    ///   - time: Time in current envelope stage (seconds)
    ///   - isGateOpen: Whether gate is open (attack/decay/sustain) or closed (release)
    ///   - attack: Attack time in seconds (linear ramp)
    ///   - decay: Decay time constant in seconds (τ for exponential)
    ///   - sustain: Sustain level (0.0 - 1.0)
    ///   - release: Release time constant in seconds (τ for exponential)
    ///   - capturedLevel: Level when gate closed (for release stage)
    /// - Returns: Envelope value (0.0 - 1.0)
    static func calculateHybridEnvelopeValue(
        time: Double,
        isGateOpen: Bool,
        attack: Double,
        decay: Double,
        sustain: Double,
        release: Double,
        capturedLevel: Double = 0.0
    ) -> Double {
        if isGateOpen {
            // Attack stage: LINEAR (matches AudioKit ramps)
            if time < attack {
                return attack > 0 ? time / attack : 1.0
            }
            // Decay stage: EXPONENTIAL (natural analog-style)
            else {
                let decayTime = time - attack
                return calculateExponentialApproach(
                    time: decayTime,
                    startValue: 1.0,
                    targetValue: sustain,
                    tau: decay
                )
            }
        } else {
            // Release stage: EXPONENTIAL (natural fadeout)
            return calculateExponentialApproach(
                time: time,
                startValue: capturedLevel,
                targetValue: 0.0,
                tau: release
            )
        }
    }
    
    /// Calculate loudness envelope value with support for starting from non-zero levels
    /// 
    /// This variant of the hybrid envelope allows the attack to begin from any starting level,
    /// which is critical for voice stealing and legato playing where the previous note's
    /// envelope may still be active.
    /// 
    /// **Key Features:**
    /// - **Attack**: Linear ramp from current level to peak level
    /// - **Decay**: Exponential decay from peak to sustain
    /// - **Release**: Exponential decay from captured level to zero
    /// - **Non-zero start**: Can begin attack from any level (not just zero)
    /// 
    /// **Usage Example:**
    /// ```swift
    /// // Voice stealing: start new envelope from current fader level
    /// let currentLevel = fader.leftGain  // e.g., 0.3 (30%)
    /// let envValue = ModulationRouter.calculateLoudnessEnvelopeValue(
    ///     time: state.loudnessEnvelopeTime,
    ///     isGateOpen: state.isGateOpen,
    ///     attack: 0.05,
    ///     decay: 0.2,
    ///     sustain: 0.7,
    ///     release: 0.3,
    ///     capturedLevel: state.loudnessSustainLevel,
    ///     startLevel: currentLevel  // Start from current level!
    /// )
    /// ```
    /// 
    /// - Parameters:
    ///   - time: Time in current envelope stage (seconds)
    ///   - isGateOpen: Whether gate is open (attack/decay/sustain) or closed (release)
    ///   - attack: Attack time in seconds (linear ramp)
    ///   - decay: Decay time constant in seconds (τ for exponential)
    ///   - sustain: Sustain level (0.0 - 1.0)
    ///   - release: Release time constant in seconds (τ for exponential)
    ///   - capturedLevel: Level when gate closed (for release stage)
    ///   - startLevel: Starting level for attack (default 0.0, can be non-zero for voice stealing)
    /// - Returns: Envelope value (0.0 - 1.0)
    static func calculateLoudnessEnvelopeValue(
        time: Double,
        isGateOpen: Bool,
        attack: Double,
        decay: Double,
        sustain: Double,
        release: Double,
        capturedLevel: Double = 0.0,
        startLevel: Double = 0.0
    ) -> Double {
        if isGateOpen {
            // Attack stage: LINEAR from startLevel to 1.0
            if time < attack {
                if attack > 0 {
                    // Linear interpolation from startLevel to 1.0
                    let progress = time / attack
                    return startLevel + (1.0 - startLevel) * progress
                } else {
                    // Instant attack: jump to 1.0
                    return 1.0
                }
            }
            // Decay stage: EXPONENTIAL from 1.0 to sustain
            else {
                let decayTime = time - attack
                return calculateExponentialApproach(
                    time: decayTime,
                    startValue: 1.0,
                    targetValue: sustain,
                    tau: decay
                )
            }
        } else {
            // Release stage: EXPONENTIAL from capturedLevel to 0.0
            return calculateExponentialApproach(
                time: time,
                startValue: capturedLevel,
                targetValue: 0.0,
                tau: release
            )
        }
    }
    
    // MARK: - 1) Oscillator Pitch [LOGARITHMIC]
    
    /// Calculate oscillator pitch modulation
    /// Sources: Aux envelope (bipolar), Voice LFO (unipolar 0-1, with delay ramp), Aftertouch (bipolar)
    /// Voice LFO now modulates unidirectionally from base frequency upward
    /// Formula: finalFreq = baseFreq × 2^((auxEnvSemitones + lfoSemitones + aftertouchSemitones) / 12)
    static func calculateOscillatorPitch(
        baseFrequency: Double,
        auxEnvValue: Double,
        auxEnvAmount: Double,
        voiceLFOValue: Double,
        voiceLFOAmount: Double,
        voiceLFORampFactor: Double,
        aftertouchDelta: Double,
        aftertouchAmount: Double
    ) -> Double {
        // Aux envelope: can be ± semitones (bipolar)
        let auxEnvSemitones = auxEnvValue * auxEnvAmount
        
        // Voice LFO: unipolar (0-1), modulates upward from base
        // Full amount is applied at LFO peak, zero at LFO minimum
        let lfoSemitones = (voiceLFOValue * voiceLFORampFactor) * voiceLFOAmount
        
        // Aftertouch: can be ± semitones (bipolar)
        let aftertouchSemitones = aftertouchDelta * aftertouchAmount
        
        // Add in semitone space
        let totalSemitones = auxEnvSemitones + lfoSemitones + aftertouchSemitones
        
        // Convert to frequency
        let finalFreq = baseFrequency * pow(2.0, totalSemitones / 12.0)
        
        return max(20.0, min(20000.0, finalFreq))
    }
    
    // MARK: - 2) Oscillator Amplitude [MULTIPLICATIVE]
    
    /// Calculate oscillator amplitude modulation
    /// Sources: Initial touch (unipolar, at note-on)
    /// Note: Global LFO tremolo is now applied at voice mixer level, not per-voice oscillator amplitude
    /// Formula: finalAmp = baseAmp × (1.0 + (touchValue × amount))
    static func calculateOscillatorAmplitude(
        baseAmplitude: Double,
        initialTouchValue: Double,
        initialTouchAmount: Double
    ) -> Double {
        // Initial touch scales the base amplitude (multiplicative)
        let touchScaledBase = baseAmplitude * (1.0 + (initialTouchValue - 0.5) * 2.0 * initialTouchAmount)
        
        return max(0.0, min(1.0, touchScaledBase))
    }
    
    // MARK: - 2B) Voice Mixer Volume [MULTIPLICATIVE]
    
    /// Calculate voice mixer volume (tremolo from global LFO)
    /// Sources: Global LFO (bipolar, multiplicative)
    /// Formula: finalVolume = baseVolume × (1.0 + (lfoValue × amount))
    /// This applies tremolo globally to all voices at once, cleaner than per-voice modulation
    static func calculateVoiceMixerVolume(
        baseVolume: Double,
        globalLFOValue: Double,
        globalLFOAmount: Double
    ) -> Double {
        // Global LFO modulates volume multiplicatively (tremolo)
        // lfoValue ranges from -1 to +1, so this creates proportional modulation
        let lfoFactor = 1.0 + (globalLFOValue * globalLFOAmount)
        
        let finalVolume = baseVolume * lfoFactor
        
        return max(0.0, min(1.0, finalVolume))
    }
    
    // MARK: - 3) Modulation Index [LINEAR]
    
    /// Calculate modulation index
    /// Sources: Mod envelope (bipolar), Voice LFO (unipolar 0-1, with delay ramp), Aftertouch (bipolar)
    /// Voice LFO now modulates unidirectionally from base upward
    /// Formula: finalModIndex = baseModIndex + modEnvOffset + aftertouchOffset + lfoOffset
    static func calculateModulationIndex(
        baseModIndex: Double,
        modEnvValue: Double,
        modEnvAmount: Double,
        voiceLFOValue: Double,
        voiceLFOAmount: Double,
        voiceLFORampFactor: Double,
        aftertouchDelta: Double,
        aftertouchAmount: Double
    ) -> Double {
        // Mod envelope: bipolar offset
        let modEnvOffset = modEnvValue * modEnvAmount
        
        // Aftertouch: bipolar offset
        let aftertouchOffset = aftertouchDelta * aftertouchAmount
        
        // Voice LFO: unipolar (0-1), adds positive offset from base
        let lfoOffset = (voiceLFOValue * voiceLFORampFactor) * voiceLFOAmount
        
        let finalModIndex = baseModIndex + modEnvOffset + aftertouchOffset + lfoOffset
        
        return max(0.0, min(10.0, finalModIndex))
    }
    
    // MARK: - 4) Modulator Multiplier [LINEAR]
    
    /// Calculate modulator multiplier (FM ratio)
    /// Sources: Global LFO (bipolar)
    /// Formula: finalMultiplier = baseMultiplier + lfoOffset
    static func calculateModulatorMultiplier(
        baseMultiplier: Double,
        globalLFOValue: Double,
        globalLFOAmount: Double
    ) -> Double {
        let lfoOffset = globalLFOValue * globalLFOAmount
        let finalMultiplier = baseMultiplier + lfoOffset
        
        return max(0.1, min(20.0, finalMultiplier))
    }
    
    // MARK: - 5) Filter Frequency [LOGARITHMIC]
    
    /// Calculate filter cutoff frequency (LEGACY - includes key tracking)
    /// Sources: Key track (note-on offset), Aux env (bipolar), Voice LFO (unipolar 0-1), Global LFO (bipolar), Aftertouch (bipolar)
    /// Voice LFO now modulates unidirectionally from base upward
    /// Key tracking provides a per-note octave offset applied at note-on
    /// NOTE: This method is kept for backward compatibility but should not be used
    /// for continuous modulation. Use calculateFilterFrequencyContinuous instead.
    static func calculateFilterFrequency(
        baseCutoff: Double,
        keyTrackValue: Double,
        keyTrackAmount: Double,
        auxEnvValue: Double,
        auxEnvAmount: Double,
        aftertouchDelta: Double,
        aftertouchAmount: Double,
        voiceLFOValue: Double,
        voiceLFOAmount: Double,
        voiceLFORampFactor: Double,
        globalLFOValue: Double,
        globalLFOAmount: Double
    ) -> Double {
        // Step 1: Key tracking - direct octave offset based on note frequency
        // At amount = 1.0, filter tracks keyboard 1:1 (one octave up = double filter freq)
        // At amount = 0.0, no tracking (all notes same filter freq)
        let keyTrackOctaves = keyTrackValue * keyTrackAmount
        
        // Step 2: Envelope and aftertouch offsets in octave space (bipolar)
        let auxEnvOctaves = auxEnvValue * auxEnvAmount
        let aftertouchOctaves = aftertouchDelta * aftertouchAmount
        
        // Step 3: LFO offsets in octave space
        // Voice LFO: unipolar (0-1), adds positive offset
        let voiceLFOOctaves = (voiceLFOValue * voiceLFORampFactor) * voiceLFOAmount
        // Global LFO: bipolar
        let globalLFOOctaves = globalLFOValue * globalLFOAmount
        
        // Step 4: Sum all octave offsets
        let totalOctaves = keyTrackOctaves + auxEnvOctaves + aftertouchOctaves + voiceLFOOctaves + globalLFOOctaves
        
        // Step 5: Apply to base cutoff frequency
        let finalCutoff = baseCutoff * pow(2.0, totalOctaves)
        
        // Clamp to ThreePoleLowpassFilter valid range (12 Hz - 20 kHz)
        return max(12.0, min(20000.0, finalCutoff))
    }
    
    /// Calculate filter cutoff frequency for CONTINUOUS modulation only
    /// Sources: Aux env (bipolar), Voice LFO (unipolar 0-1), Global LFO (bipolar), Aftertouch (bipolar)
    /// Voice LFO now modulates unidirectionally from base upward
    /// NOTE: Key tracking is NOT included - it's a note-on property applied in trigger()
    /// The baseCutoff passed in should already include key tracking if enabled
    static func calculateFilterFrequencyContinuous(
        baseCutoff: Double,  // Already includes key tracking offset if enabled
        auxEnvValue: Double,
        auxEnvAmount: Double,
        aftertouchDelta: Double,
        aftertouchAmount: Double,
        voiceLFOValue: Double,
        voiceLFOAmount: Double,
        voiceLFORampFactor: Double,
        globalLFOValue: Double,
        globalLFOAmount: Double
    ) -> Double {
        // Step 1: Envelope and aftertouch offsets in octave space (bipolar)
        let auxEnvOctaves = auxEnvValue * auxEnvAmount
        let aftertouchOctaves = aftertouchDelta * aftertouchAmount
        
        // Step 2: LFO offsets in octave space
        // Voice LFO: unipolar (0-1), adds positive offset
        let voiceLFOOctaves = (voiceLFOValue * voiceLFORampFactor) * voiceLFOAmount
        // Global LFO: bipolar
        let globalLFOOctaves = globalLFOValue * globalLFOAmount
        
        // Step 3: Sum all octave offsets (no key tracking)
        let totalOctaves = auxEnvOctaves + aftertouchOctaves + voiceLFOOctaves + globalLFOOctaves
        
        // Step 4: Apply to base cutoff frequency (which already includes key tracking)
        let finalCutoff = baseCutoff * pow(2.0, totalOctaves)
        
        // Clamp to ThreePoleLowpassFilter valid range (12 Hz - 20 kHz)
        return max(12.0, min(20000.0, finalCutoff))
    }
    
    // MARK: - 6) Delay Time [LINEAR]
    
    /// Calculate delay time
    /// Sources: Global LFO (bipolar)
    /// Formula: finalDelayTime = baseDelayTime + lfoOffset
    static func calculateDelayTime(
        baseDelayTime: Double,
        globalLFOValue: Double,
        globalLFOAmount: Double
    ) -> Double {
        let lfoOffset = globalLFOValue * globalLFOAmount
        let finalDelayTime = baseDelayTime + lfoOffset
        
        return max(0.0, min(2.0, finalDelayTime))
    }
    
    // MARK: - Meta-Modulation: 7) Voice LFO Pitch Amount [HYBRID: MULT + ADD]
    
    /// Calculate voice LFO to oscillator pitch amount (vibrato amount)
    /// Sources: Aux envelope (hybrid mult+add), Aftertouch (hybrid mult+add for amplitude control)
    /// Formula: finalAmount = (baseAmount × auxEnvFactor × aftertouchMultFactor) + auxEnvAdditive + aftertouchAdditive
    /// Note: Both sources modulate AMPLITUDE/DEPTH bidirectionally:
    ///   - High value: increases depth (multiplicative scaling + additive boost)
    ///   - Low value: decreases depth (multiplicative scaling only, toward 0)
    static func calculateVoiceLFOPitchAmount(
        baseAmount: Double,
        auxEnvValue: Double,
        auxEnvAmount: Double,
        aftertouchDelta: Double,
        aftertouchAmount: Double
    ) -> Double {
        // Aux envelope: split into multiplicative (for existing vibrato) and additive (for zero base)
        
        // Multiplicative factor: scales existing vibrato depth
        // value = 1.0 (peak) → factor = 2.0 (double)
        // value = 0.0 (zero) → factor = 1.0 (unchanged)
        let auxEnvFactor = 1.0 + (auxEnvValue * auxEnvAmount)
        
        // Additive component: allows creating vibrato from zero when envelope is high
        // Only applies when envelope is high (positive value) and base amount is near zero
        let auxEnvAdditive: Double
        if auxEnvValue > 0.0 && abs(baseAmount) < 0.01 {
            // When base amount is essentially zero, treat positive envelope as direct additive vibrato
            auxEnvAdditive = auxEnvValue * auxEnvAmount
        } else {
            // When base amount exists, rely on multiplicative scaling
            auxEnvAdditive = 0.0
        }
        
        // Aftertouch: split into multiplicative (for existing vibrato) and additive (for zero base)
        
        // Multiplicative factor: scales existing vibrato depth
        // delta = +1.0 (toward center) → factor = 2.0 (double)
        // delta = 0.0 (no movement) → factor = 1.0 (unchanged)
        // delta = -1.0 (toward edge) → factor = 0.0 (silence)
        let aftertouchMultFactor = max(0.0, 1.0 + (aftertouchDelta * aftertouchAmount))
        
        // Additive component: allows creating vibrato from zero when moving toward center
        // Only applies when moving toward center (positive delta)
        // Uses absolute value of amount as the reference depth
        let aftertouchAdditive: Double
        if aftertouchDelta > 0.0 && abs(baseAmount) < 0.01 {
            // When base amount is essentially zero, treat positive delta as direct additive vibrato
            aftertouchAdditive = aftertouchDelta * aftertouchAmount
        } else {
            // When base amount exists, rely on multiplicative scaling
            aftertouchAdditive = 0.0
        }
        
        // Combine all components
        let finalAmount = (baseAmount * auxEnvFactor * aftertouchMultFactor) + auxEnvAdditive + aftertouchAdditive
        
        return max(-10.0, min(10.0, finalAmount))
    }
    
    // MARK: - Meta-Modulation: 8) Voice LFO Frequency [LOGARITHMIC]
    
    /// Calculate voice LFO frequency
    /// Sources: Key tracking (octave-based)
    /// Formula: finalFreq = baseFreq × 2^(keyTrackValue × amount)
    /// When amount = 1.0: 1 octave up in note = 2x LFO frequency
    static func calculateVoiceLFOFrequency(
        baseFrequency: Double,
        keyTrackValue: Double,
        keyTrackAmount: Double
    ) -> Double {
        let octaveOffset = keyTrackValue * keyTrackAmount
        let finalFreq = baseFrequency * pow(2.0, octaveOffset)
        
        return max(0.01, min(20.0, finalFreq))
    }
    
    // MARK: - Meta-Modulation: 9-11) Initial Touch Scaling [LINEAR]
    
    /// Calculate scaled envelope amount based on initial touch
    /// Sources: Initial touch (unipolar, at note-on)
    /// Formula: finalAmount = baseAmount × (1.0 + touchFactor)
    static func calculateTouchScaledAmount(
        baseAmount: Double,
        initialTouchValue: Double,
        initialTouchAmount: Double
    ) -> Double {
        let touchFactor = initialTouchValue * initialTouchAmount
        return baseAmount + touchFactor
    }
}

// MARK: - Control Rate Timer Configuration

/// Configuration for the modulation control-rate update loop
/// Phase 5B will implement the actual timer
struct ControlRateConfig {
    /// Update rate for modulation calculations in Hz
    /// 50 Hz = 20ms updates = lower CPU, still smooth for most modulation
    static let updateRate: Double = 50.0

    /// Update interval in seconds
    static let updateInterval: Double = 1.0 / updateRate

    /// Update interval in nanoseconds (for Timer use)
    static let updateIntervalNanoseconds: UInt64 = UInt64(updateInterval * 1_000_000_000)

    /// Ramp duration for modulation parameter updates
    /// Should match updateInterval for smooth transitions between cycles
    static let modulationRampDuration: Float = Float(updateInterval)
}
