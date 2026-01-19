//
//  A1 SoundParameters.swift
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

/// Voice mode determining polyphony behavior
enum VoiceMode: String, Codable, Equatable, CaseIterable {
    case monophonic
    case polyphonic
    
    /// User-friendly display name
    var displayName: String {
        switch self {
        case .monophonic: return "Monophonic"
        case .polyphonic: return "Polyphonic"
        }
    }
}

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
    var modulatingMultiplier: Double          // Combined coarse + fine (e.g., 2.50 = coarse:2, fine:0.50)
    var modulationIndex: Double
    var amplitude: Double
    var waveform: OscillatorWaveform
    var detuneMode: DetuneMode                // How stereo spread is calculated
    var stereoOffsetProportional: Double      // For proportional mode (cents, e.g., 5.0)
    var stereoOffsetConstant: Double          // For constant mode (Hz, e.g., 2.0)
    
    static let `default` = OscillatorParameters(
        carrierMultiplier: 1.0,
        modulatingMultiplier: 2.00,
        modulationIndex: 1.0,
        amplitude: 0.5,
        waveform: .triangle,
        detuneMode: .proportional,
        stereoOffsetProportional: 5.0,        // 5 cents (clean default)
        stereoOffsetConstant: 2.0
    )
    
    /// Helper: Get the coarse part of modulatingMultiplier (integer part)
    var modulatingMultiplierCoarse: Int {
        Int(floor(modulatingMultiplier))
    }
    
    /// Helper: Get the fine part of modulatingMultiplier (fractional part)
    var modulatingMultiplierFine: Double {
        modulatingMultiplier - floor(modulatingMultiplier)
    }
    
    /// Helper: Set modulatingMultiplier from separate coarse and fine values
    mutating func setModulatingMultiplier(coarse: Int, fine: Double) {
        modulatingMultiplier = Double(coarse) + fine
    }
}

/// Parameters for the low-pass filter (MODULATABLE parameters only)
/// Cutoff frequency can be modulated by envelopes, LFOs, key tracking, and aftertouch
struct FilterParameters: Codable, Equatable {
    var cutoffFrequency: Double
    
    static let `default` = FilterParameters(
        cutoffFrequency: 880
    )
    
    /// Clamps cutoff to valid range for ThreePoleLowpassFilter (12 Hz - 20 kHz)
    var clampedCutoff: Double {
        min(max(cutoffFrequency, 12), 20_000)
    }
}

/// Non-modulatable filter parameters (STATIC parameters)
/// These are set once at note-on and never modulated during playback
/// Resonance and saturation control the filter's character but are not performance parameters
struct FilterStaticParameters: Codable, Equatable {
    var resonance: Double
    var saturation: Double // Actual parameter name is "distortion" for ThreePoleLowpassFilter
    
    static let `default` = FilterStaticParameters(
        resonance: 0.5,
        saturation: 0.5
    )
    
    /// Clamps resonance to valid range (0 - 2)
    var clampedResonance: Double {
        min(max(resonance, 0), 2.0)
    }
    
    /// Clamps saturation to valid range (0 - 10)
    var clampedSaturation: Double {
        min(max(saturation, 0), 2.0)
    }
}

/// Parameters for the amplitude envelope
/// ⚠️ DEPRECATED: This struct is maintained for backward compatibility with old presets
/// New code should use modulation.loudnessEnvelope instead
struct EnvelopeParameters: Codable, Equatable {
    var attackDuration: Double
    var decayDuration: Double
    var sustainLevel: Double
    var releaseDuration: Double
    
    static let `default` = EnvelopeParameters(
        attackDuration: 0.005,
        decayDuration: 0.5,
        sustainLevel: 1.0,
        releaseDuration: 0.1
    )
    
    /// Convert to new LoudnessEnvelopeParameters for migration
    func toLoudnessEnvelope() -> LoudnessEnvelopeParameters {
        return LoudnessEnvelopeParameters(
            attack: attackDuration,
            decay: decayDuration,
            sustain: sustainLevel,
            release: releaseDuration,
            isEnabled: true
        )
    }
}

/// Combined parameters for a single voice
struct VoiceParameters: Codable, Equatable {
    var oscillator: OscillatorParameters
    var filter: FilterParameters                   // Modulatable (cutoff only)
    var filterStatic: FilterStaticParameters       // Non-modulatable (resonance, saturation)
    var envelope: EnvelopeParameters               // Maintained for preset compatibility
    var modulation: VoiceModulationParameters      // Phase 5: Modulation system (includes loudnessEnvelope)
    
    // MARK: - Initializers
    
    /// Standard memberwise initializer (required because we have custom Codable)
    init(oscillator: OscillatorParameters, filter: FilterParameters, filterStatic: FilterStaticParameters, envelope: EnvelopeParameters, modulation: VoiceModulationParameters) {
        self.oscillator = oscillator
        self.filter = filter
        self.filterStatic = filterStatic
        self.envelope = envelope
        self.modulation = modulation
    }
    
    static let `default` = VoiceParameters(
        oscillator: .default,
        filter: .default,
        filterStatic: .default,
        envelope: .default,  // Keep for preset compatibility
        modulation: .default  // Uses VoiceModulationParameters.default
    )
    
    // MARK: - Custom Codable Implementation for Transparent Migration
    
    enum CodingKeys: String, CodingKey {
        case oscillator
        case filter
        case filterStatic
        case envelope
        case modulation
    }
    
    /// Custom decoder that transparently migrates envelope to loudnessEnvelope
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        oscillator = try container.decode(OscillatorParameters.self, forKey: .oscillator)
        filter = try container.decode(FilterParameters.self, forKey: .filter)
        filterStatic = try container.decode(FilterStaticParameters.self, forKey: .filterStatic)
        envelope = try container.decode(EnvelopeParameters.self, forKey: .envelope)
        
        // Decode modulation, or create default if missing (old presets)
        var modulation = (try? container.decode(VoiceModulationParameters.self, forKey: .modulation)) ?? .default
        
        // CRITICAL: Sync loudness envelope from envelope field
        // This happens every time a preset is loaded, ensuring envelope data is never lost
        modulation.loudnessEnvelope = envelope.toLoudnessEnvelope()
        
        self.modulation = modulation
    }
    
    /// Custom encoder that keeps envelope field in sync with loudnessEnvelope
    /// This ensures presets remain in the old format for maximum compatibility
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(oscillator, forKey: .oscillator)
        try container.encode(filter, forKey: .filter)
        try container.encode(filterStatic, forKey: .filterStatic)
        
        // CRITICAL: Convert loudnessEnvelope back to envelope format for saving
        // This keeps preset files in the old format
        let envelopeForSaving = EnvelopeParameters(
            attackDuration: modulation.loudnessEnvelope.attack,
            decayDuration: modulation.loudnessEnvelope.decay,
            sustainLevel: modulation.loudnessEnvelope.sustain,
            releaseDuration: modulation.loudnessEnvelope.release
        )
        try container.encode(envelopeForSaving, forKey: .envelope)
        
        try container.encode(modulation, forKey: .modulation)
    }
    
    /// Get the current loudness envelope (for UI and parameter updates)
    var loudnessEnvelope: LoudnessEnvelopeParameters {
        get { modulation.loudnessEnvelope }
        set { 
            modulation.loudnessEnvelope = newValue
            // Keep envelope field in sync for consistency
            envelope = EnvelopeParameters(
                attackDuration: newValue.attack,
                decayDuration: newValue.decay,
                sustainLevel: newValue.sustain,
                releaseDuration: newValue.release
            )
        }
    }
}

/// Musical note divisions for tempo-synced delay
enum DelayTimeValue: Double, Codable, Equatable, CaseIterable {
    case thirtySecond = 0.03125    // 1/32 note
    case twentyFourth = 0.04166666 // 1/24 note (triplet sixteenth)
    case sixteenth = 0.0625        // 1/16 note
    case dottedSixteenth = 0.09375 // 3/32 note
    case eighth = 0.125            // 1/8 note
    case dottedEighth = 0.1875     // 3/16 note
    case quarter = 0.25            // 1/4 note
    
    var displayName: String {
        switch self {
        case .thirtySecond: return "1/32"
        case .twentyFourth: return "1/24"
        case .sixteenth: return "1/16"
        case .dottedSixteenth: return "3/32"
        case .eighth: return "1/8"
        case .dottedEighth: return "3/16"
        case .quarter: return "1/4"
        }
    }
    
    /// Convert to delay time in seconds based on tempo
    /// Formula: rawValue × (240/tempo)
    /// This gives: 1/4 note at 120 BPM = 0.25 × 2.0 = 0.5 seconds
    func timeInSeconds(tempo: Double) -> Double {
        return self.rawValue * (240.0 / tempo)
    }
}

/// Parameters for the stereo delay effect
struct DelayParameters: Codable, Equatable {
    var timeValue: DelayTimeValue  // Musical note division (always tempo-synced)
    var feedback: Double
    var dryWetMix: Double          // Now controlled by external DryWetMixer
    var toneCutoff: Double         // Lowpass filter cutoff (200 Hz - 20 kHz)
    // Note: pingPong is now always enabled (removed as parameter)
    
    static let `default` = DelayParameters(
        timeValue: .eighth,  // 1/4 note
        feedback: 0.5,
        dryWetMix: 0.0,
        toneCutoff: 10_000    // Wide open by default
    )
    
    /// Calculate actual delay time in seconds based on current tempo
    func timeInSeconds(tempo: Double) -> Double {
        return timeValue.timeInSeconds(tempo: tempo)
    }
}

/// Parameters for the reverb effect
struct ReverbParameters: Codable, Equatable {
    var feedback: Double
    var cutoffFrequency: Double
    var balance: Double  // 0 = all dry, 1 = all wet
    
    static let `default` = ReverbParameters(
        feedback: 0.5,
        cutoffFrequency: 10_000,
        balance: 0.0
    )
}

/// Parameter for the output mixer
struct OutputParameters: Codable, Equatable {
    var preVolume: Double   // Voice mixer volume (before FX)
    var volume: Double      // Output mixer volume (after FX)
    
    static let `default` = OutputParameters(
        preVolume: 0.5,
        volume: 0.5
    )
}

/// Global pitch modifiers applied to all triggered notes
/// All parameters are multiplication factors applied to the base frequency
struct GlobalPitchParameters: Codable, Equatable {
    var transpose: Double   // Semitone transposition (1.0 = no change, 1.059463 ≈ +1 semitone)
    var octave: Double      // Octave shift (1.0 = no change, 2.0 = +1 octave, 0.5 = -1 octave)
    var fineTune: Double    // Fine tuning adjustment (1.0 = no change, subtle variations)
    
    static let `default` = GlobalPitchParameters(
        transpose: 1.0,
        octave: 1.0,
        fineTune: 1.0
    )
    
    /// Combined multiplication factor for all pitch modifiers
    var combinedFactor: Double {
        transpose * octave * fineTune
    }
    
    /// Helper: Set octave from an integer offset (e.g., -1, 0, +1, +2)
    mutating func setOctaveOffset(_ offset: Int) {
        // Each octave offset doubles or halves the frequency
        // offset = 0 -> 2^0 = 1.0
        // offset = 1 -> 2^1 = 2.0
        // offset = -1 -> 2^-1 = 0.5
        octave = pow(2.0, Double(offset))
    }
    
    /// Helper: Get the current octave as an integer offset
    var octaveOffset: Int {
        // Reverse the calculation: offset = log2(octave)
        Int(round(log2(octave)))
    }
    
    /// Helper: Set transpose from semitones (e.g., -12, 0, +7)
    mutating func setTransposeSemitones(_ semitones: Int) {
        // Equal temperament: each semitone is 2^(1/12) ≈ 1.059463
        transpose = pow(2.0, Double(semitones) / 12.0)
    }
    
    /// Helper: Get the current transpose as semitones
    var transposeSemitones: Int {
        // Reverse: semitones = 12 * log2(transpose)
        Int(round(12.0 * log2(transpose)))
    }
    
    /// Helper: Set fine tune from cents (e.g., -50, 0, +50)
    /// Cents are 1/100th of a semitone
    mutating func setFineTuneCents(_ cents: Double) {
        // 100 cents = 1 semitone = 2^(1/12)
        // 1 cent = 2^(1/1200)
        fineTune = pow(2.0, cents / 1200.0)
    }
    
    /// Helper: Get the current fine tune as cents
    var fineTuneCents: Double {
        // Reverse: cents = 1200 * log2(fineTune)
        1200.0 * log2(fineTune)
    }
}

/// Parameters defining how macro controls affect underlying parameters
struct MacroControlParameters: Codable, Equatable {
    // Tone macro -> affects modulation index, filter cutoff, and filter saturation
    var toneToModulationIndexRange: Double      // +/- range (0-5)
    var toneToFilterCutoffOctaves: Double       // +/- range in octaves (0-4)
    var toneToFilterSaturationRange: Double     // +/- range (0-2)
    
    // Ambience macro -> affects delay and reverb
    var ambienceToDelayFeedbackRange: Double    // +/- range (0-1)
    var ambienceToDelayMixRange: Double         // +/- range (0-1)
    var ambienceToReverbFeedbackRange: Double   // +/- range (0-1)
    var ambienceToReverbMixRange: Double        // +/- range (0-1)
    
    static let `default` = MacroControlParameters(
        toneToModulationIndexRange: 1.25,
        toneToFilterCutoffOctaves: 2.5,
        toneToFilterSaturationRange: 0.5,
        ambienceToDelayFeedbackRange: 0.25,
        ambienceToDelayMixRange: 0.25,
        ambienceToReverbFeedbackRange: 0.25,
        ambienceToReverbMixRange: 0.25
    )
}

/// Current state of macro controls and their base values
struct MacroControlState: Codable, Equatable {
    // Base values - set when preset is loaded or edited
    var baseModulationIndex: Double
    var baseFilterCutoff: Double
    var baseFilterSaturation: Double
    var baseDelayFeedback: Double
    var baseDelayMix: Double
    var baseReverbFeedback: Double
    var baseReverbMix: Double
    var basePreVolume: Double
    
    // Macro positions (-1.0 to +1.0, where 0 is center/neutral)
    // Volume is absolute (0-1), tone and ambience are relative (-1 to +1)
    var volumePosition: Double
    var tonePosition: Double
    var ambiencePosition: Double
    
    /// Initialize macro state from current parameters
    /// This ensures base values always match the actual parameter state
    init(from voiceParams: VoiceParameters, masterParams: MasterParameters) {
        // Capture base values from parameters
        self.baseModulationIndex = voiceParams.oscillator.modulationIndex
        self.baseFilterCutoff = voiceParams.filter.cutoffFrequency
        self.baseFilterSaturation = voiceParams.filterStatic.saturation
        self.baseDelayFeedback = masterParams.delay.feedback
        self.baseDelayMix = masterParams.delay.dryWetMix
        self.baseReverbFeedback = masterParams.reverb.feedback
        self.baseReverbMix = masterParams.reverb.balance
        self.basePreVolume = masterParams.output.preVolume
        
        // Initialize positions
        // Volume matches preVolume (absolute), others start at neutral
        self.volumePosition = masterParams.output.preVolume
        self.tonePosition = 0.0
        self.ambiencePosition = 0.0
    }
    
    /// Convenience initializer for Codable (required for preset loading)
    init(baseModulationIndex: Double, baseFilterCutoff: Double, baseFilterSaturation: Double,
         baseDelayFeedback: Double, baseDelayMix: Double, baseReverbFeedback: Double, baseReverbMix: Double,
         basePreVolume: Double, volumePosition: Double, tonePosition: Double, ambiencePosition: Double) {
        self.baseModulationIndex = baseModulationIndex
        self.baseFilterCutoff = baseFilterCutoff
        self.baseFilterSaturation = baseFilterSaturation
        self.baseDelayFeedback = baseDelayFeedback
        self.baseDelayMix = baseDelayMix
        self.baseReverbFeedback = baseReverbFeedback
        self.baseReverbMix = baseReverbMix
        self.basePreVolume = basePreVolume
        self.volumePosition = volumePosition
        self.tonePosition = tonePosition
        self.ambiencePosition = ambiencePosition
    }
    
    /// Default macro state with neutral values
    /// Note: This uses hardcoded defaults to avoid circular dependency with MasterParameters
    static let `default` = MacroControlState(
        baseModulationIndex: 1.0,           // matches OscillatorParameters.default.modulationIndex
        baseFilterCutoff: 880.0,            // matches FilterParameters.default.cutoffFrequency
        baseFilterSaturation: 0.5,          // matches FilterStaticParameters.default.saturation
        baseDelayFeedback: 0.5,             // matches DelayParameters.default.feedback
        baseDelayMix: 0.0,                  // matches DelayParameters.default.dryWetMix
        baseReverbFeedback: 0.5,            // matches ReverbParameters.default.feedback
        baseReverbMix: 0.0,                 // matches ReverbParameters.default.balance
        basePreVolume: 0.5,                 // matches OutputParameters.default.preVolume
        volumePosition: 0.5,                // matches preVolume
        tonePosition: 0.0,                  // neutral
        ambiencePosition: 0.0               // neutral
    )
}

/// Master parameters affecting the entire audio engine
struct MasterParameters: Codable, Equatable {
    var delay: DelayParameters
    var reverb: ReverbParameters
    var output: OutputParameters
    var globalPitch: GlobalPitchParameters // Global pitch modifiers (transpose, octave, fine tune)
    var globalLFO: GlobalLFOParameters     // Phase 5C: Global modulation
    var tempo: Double                      // BPM for tempo-synced modulation
    var voiceMode: VoiceMode               // Monophonic or polyphonic
    var macroControl: MacroControlParameters // Macro control ranges
    
    static let `default` = MasterParameters(
        delay: .default,
        reverb: .default,
        output: .default,
        globalPitch: .default,
        globalLFO: .default,  // Uses GlobalLFOParameters.default
        tempo: 100.0,
        voiceMode: .polyphonic,
        macroControl: .default
    )
}

// MARK: - Complete Parameter Set (for Presets)

/// A complete snapshot of all audio parameters - used for presets
struct AudioParameterSet: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var voiceTemplate: VoiceParameters  // Template applied to all voices
    var master: MasterParameters
    var macroState: MacroControlState   // Current macro positions and base values
    var createdAt: Date
    
    /// Default preset
    static let `default` = AudioParameterSet(
        id: UUID(),
        name: "Default",
        voiceTemplate: .default,
        master: .default,
        macroState: .default,
        createdAt: Date()
    )
}

