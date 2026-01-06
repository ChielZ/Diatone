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
    /// - Parameter phase: Current phase of the LFO (0.0 = start, 1.0 = end of cycle)
    /// - Returns: Raw waveform value in range -1.0 to +1.0 (bipolar, unscaled)
    func value(at phase: Double) -> Double {
        // Normalize phase to 0-1 range (handle wraparound)
        let normalizedPhase = phase - floor(phase)
        
        switch self {
        case .sine:
            // Sine wave: smooth oscillation
            return sin(normalizedPhase * 2.0 * .pi)
            
        case .triangle:
            // Triangle wave: linear rise and fall
            // 0.0-0.5: rise from -1 to +1
            // 0.5-1.0: fall from +1 to -1
            if normalizedPhase < 0.5 {
                return (normalizedPhase * 4.0) - 1.0  // -1 to +1
            } else {
                return 3.0 - (normalizedPhase * 4.0)  // +1 to -1
            }
            
        case .square:
            // Square wave: instant transitions
            // 0.0-0.5: +1
            // 0.5-1.0: -1
            return normalizedPhase < 0.5 ? 1.0 : -1.0
            
        case .sawtooth:
            // Sawtooth wave: linear rise, instant drop
            // 0.0-1.0: -1 to +1 (then instant drop to -1)
            return (normalizedPhase * 2.0) - 1.0
            
        case .reverseSawtooth:
            // Reverse sawtooth: instant rise, linear fall
            // 0.0-1.0: +1 to -1 (instant rise from -1 to +1 at start)
            return 1.0 - (normalizedPhase * 2.0)
        }
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
    case sixteenth = 16.0       // 1/16
    case eighth = 8.0           // 1/8
    case quarter = 4.0          // 1/4
    case half = 2.0             // 1/2
    case whole = 1.0            // 1 bar
    case two = 0.5              // 2 bars
    case four = 0.25            // 4 bars
    
    var displayName: String {
        switch self {
        case .thirtySecond: return "1/32"
        case .sixteenth: return "1/16"
        case .eighth: return "1/8"
        case .quarter: return "1/4"
        case .half: return "1/2"
        case .whole: return "1"
        case .two: return "2"
        case .four: return "4"
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
struct VoiceLFOParameters: Codable, Equatable {
    // Configuration
    var waveform: LFOWaveform
    var resetMode: LFOResetMode
    var frequency: Double                      // Hz (0.01 - 20 Hz) - always in Hz, no tempo sync
    
    // Fixed destinations with individual amounts (can be positive or negative)
    var amountToOscillatorPitch: Double        // ±semitones (Page 7, item 4)
    var amountToFilterFrequency: Double        // ±octaves (Page 7, item 5)
    var amountToModulatorLevel: Double         // ±modulation index (Page 7, item 6)
    
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
    
    /// Calculate the raw LFO waveform value at a given phase
    /// - Parameter phase: Current phase of the LFO (0.0 = start, 1.0 = end of cycle)
    /// - Returns: Raw LFO value in range -1.0 to +1.0 (unscaled)
    func rawValue(at phase: Double) -> Double {
        guard isEnabled else { return 0.0 }
        return waveform.value(at: phase)
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
}

/// Aftertouch modulation from change in X position while holding
/// Tracks movement of the finger while the key is held (continuous modulation)
struct TouchAftertouchParameters: Codable, Equatable {
    // Fixed destinations with individual amounts (Page 9, items 5-7)
    var amountToFilterFrequency: Double        // ±octaves (bipolar modulation)
    var amountToModulatorLevel: Double         // ±modulation index (bipolar modulation)
    var amountToVibrato: Double                // Meta-modulation: adds to voice LFO pitch amount
    
    var isEnabled: Bool
    
    static let `default` = TouchAftertouchParameters(
        amountToFilterFrequency: 0.0,          // No aftertouch filter control by default
        amountToModulatorLevel: 0.0,           // No aftertouch timbre control by default
        amountToVibrato: 0.0,                  // No aftertouch vibrato control by default
        isEnabled: true
    )
}

// MARK: - Complete Modulation System Parameters

/// Container for all modulation sources and routings for a single voice
/// All destinations are now fixed per source with individual amount controls
struct VoiceModulationParameters: Codable, Equatable {
    // Envelopes
    var modulatorEnvelope: ModulatorEnvelopeParameters   // Fixed: modulation index only
    var auxiliaryEnvelope: AuxiliaryEnvelopeParameters   // Fixed: pitch, filter, vibrato
    
    // LFO
    var voiceLFO: VoiceLFOParameters                     // Fixed: pitch, filter, modulator level
    
    // Touch/Key tracking
    var keyTracking: KeyTrackingParameters               // Fixed: filter freq, LFO freq
    var touchInitial: TouchInitialParameters             // Fixed: amplitude, env amounts (meta-mod)
    var touchAftertouch: TouchAftertouchParameters       // Fixed: filter, modulator, vibrato
    
    static let `default` = VoiceModulationParameters(
        modulatorEnvelope: .default,
        auxiliaryEnvelope: .default,
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
    /// - Returns: Raw LFO value in range -1.0 to +1.0 (unscaled)
    func rawValue(at phase: Double) -> Double {
        guard isEnabled else { return 0.0 }
        return waveform.value(at: phase)
    }
}

// MARK: - Modulation State (Runtime)

/// Runtime state for modulation calculation
/// This tracks the current state of modulation sources during voice playback
/// Not part of presets (ephemeral state)
struct ModulationState {
    // Envelope timing
    var modulatorEnvelopeTime: Double = 0.0
    var auxiliaryEnvelopeTime: Double = 0.0
    var isGateOpen: Bool = false
    
    // Track sustain level at gate close for proper release
    var modulatorSustainLevel: Double = 0.0
    var auxiliarySustainLevel: Double = 0.0
    
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
    mutating func closeGate(modulatorValue: Double, auxiliaryValue: Double) {
        isGateOpen = false
        modulatorSustainLevel = modulatorValue
        auxiliarySustainLevel = auxiliaryValue
        // Reset envelope times to 0 for release stage
        modulatorEnvelopeTime = 0.0
        auxiliaryEnvelopeTime = 0.0
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
    
    /// Calculate ADSR envelope value at a given time
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
    
    // MARK: - 1) Oscillator Pitch [LOGARITHMIC]
    
    /// Calculate oscillator pitch modulation
    /// Sources: Aux envelope (bipolar), Voice LFO (bipolar, with delay ramp)
    /// Formula: finalFreq = baseFreq × 2^((auxEnvSemitones + lfoSemitones) / 12)
    static func calculateOscillatorPitch(
        baseFrequency: Double,
        auxEnvValue: Double,
        auxEnvAmount: Double,
        voiceLFOValue: Double,
        voiceLFOAmount: Double,
        voiceLFORampFactor: Double
    ) -> Double {
        // Aux envelope: can be ± semitones
        let auxEnvSemitones = auxEnvValue * auxEnvAmount
        
        // Voice LFO: can be ± semitones, scaled by delay ramp
        let lfoSemitones = (voiceLFOValue * voiceLFORampFactor) * voiceLFOAmount
        
        // Add in semitone space
        let totalSemitones = auxEnvSemitones + lfoSemitones
        
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
    /// Sources: Mod envelope (bipolar), Voice LFO (bipolar, with delay ramp), Aftertouch (bipolar)
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
        // All sources simply add
        let modEnvOffset = modEnvValue * modEnvAmount
        let aftertouchOffset = aftertouchDelta * aftertouchAmount
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
    
    /// Calculate filter cutoff frequency
    /// Sources: Key track (note-on offset), Aux env, Voice LFO, Global LFO, Aftertouch
    /// Key tracking provides a per-note octave offset applied at note-on
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
        
        // Step 2: Envelope and aftertouch offsets in octave space
        let auxEnvOctaves = auxEnvValue * auxEnvAmount
        let aftertouchOctaves = aftertouchDelta * aftertouchAmount
        
        // Step 3: LFO offsets in octave space
        let voiceLFOOctaves = (voiceLFOValue * voiceLFORampFactor) * voiceLFOAmount
        let globalLFOOctaves = globalLFOValue * globalLFOAmount
        
        // Step 4: Sum all octave offsets
        let totalOctaves = keyTrackOctaves + auxEnvOctaves + aftertouchOctaves + voiceLFOOctaves + globalLFOOctaves
        
        // Step 5: Apply to base cutoff frequency
        let finalCutoff = baseCutoff * pow(2.0, totalOctaves)
        
        return max(20.0, min(22050.0, finalCutoff))
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
    /// Sources: Aux envelope (multiplicative scaling), Aftertouch (hybrid mult+add for amplitude control)
    /// Formula: finalAmount = (baseAmount × auxEnvFactor × aftertouchMultFactor) + aftertouchAdditive
    /// Note: Aftertouch modulates AMPLITUDE/DEPTH bidirectionally:
    ///   - Toward center: increases depth (multiplicative scaling + additive boost)
    ///   - Toward edge: decreases depth (multiplicative scaling only, toward 0)
    static func calculateVoiceLFOPitchAmount(
        baseAmount: Double,
        auxEnvValue: Double,
        auxEnvAmount: Double,
        aftertouchDelta: Double,
        aftertouchAmount: Double
    ) -> Double {
        // Aux envelope: multiplicative scaling (envelope value 0-1 scales the vibrato depth)
        let auxEnvFactor = 1.0 + (auxEnvValue * auxEnvAmount)
        
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
        
        // Combine both components
        let finalAmount = (baseAmount * auxEnvFactor * aftertouchMultFactor) + aftertouchAdditive
        
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
    /// 200 Hz = 5ms updates = smooth LFOs and snappy envelopes
    static let updateRate: Double = 200.0
    
    /// Update interval in seconds
    static let updateInterval: Double = 1.0 / updateRate
    
    /// Update interval in nanoseconds (for Timer use)
    static let updateIntervalNanoseconds: UInt64 = UInt64(updateInterval * 1_000_000_000)
}
