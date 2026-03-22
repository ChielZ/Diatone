//
//  A1 SoundParameters.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 16/12/2025.
//

import Foundation
import Combine
import AudioKit
import DunneAudioKit
import AudioKitEX
import SoundpipeAudioKit

// MARK: - Encoding Helpers

/// Snap a value to the nearest step size for clean preset storage
/// Includes a final rounding pass to eliminate floating-point representation artifacts
private func snap(_ value: Double, to step: Double) -> Double {
    let snapped = (value / step).rounded() * step
    // Determine decimal places from step size to eliminate artifacts like 5.050000000000001
    let decimals = -log10(step).rounded(.up)
    let factor = pow(10.0, max(decimals, 0))
    return (snapped * factor).rounded() / factor
}

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

/// Carrier multiplier values for FM synthesis (UI only)
/// Combines integer harmonics (1-8) with subharmonic fractional values (1/2 - 1/8)
/// This enum is used ONLY in the UI layer - storage uses Double
enum CarrierMultiplier: Double, CaseIterable, Identifiable {
    case oneEighth = 0.125      // 1/8
    case oneSeventh = 0.142857  // 1/7 (approx)
    case oneSixth = 0.166667    // 1/6 (approx)
    case oneFifth = 0.2         // 1/5
    case oneFourth = 0.25       // 1/4
    case oneThird = 0.333333    // 1/3 (approx)
    case oneHalf = 0.5          // 1/2
    case one = 1.0
    case two = 2.0
    case three = 3.0
    case four = 4.0
    case five = 5.0
    case six = 6.0
    case seven = 7.0
    case eight = 8.0
    
    var id: Double { rawValue }
    
    /// Display as fraction for values < 1, integer for values >= 1
    var displayName: String {
        switch self {
        case .oneEighth: return "1/8"
        case .oneSeventh: return "1/7"
        case .oneSixth: return "1/6"
        case .oneFifth: return "1/5"
        case .oneFourth: return "1/4"
        case .oneThird: return "1/3"
        case .oneHalf: return "1/2"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        }
    }
    
    /// Find the nearest enum case to a given Double value
    /// Used to initialize UI from stored Double values
    static func nearest(to value: Double) -> CarrierMultiplier {
        return allCases.min(by: { abs($0.rawValue - value) < abs($1.rawValue - value) }) ?? .one
    }
}

/// Waveform types available for the FM oscillator
enum OscillatorWaveform: String, Codable, Equatable, CaseIterable {
    case sine
    case triangle
    case square3
    case square5
    case square7
    case square
    case unsquare

    
    /// User-friendly display name
    var displayName: String {
        switch self {
        case .sine: return "sine"
        case .triangle: return "triangle"
        case .square3: return "odd 3"
        case .square5: return "odd 5"
        case .square7: return "odd 7"
        case .square: return "square"
        case .unsquare: return "unsquare"
        
        
        }
    }
    
    /// Convert to AudioKit Table
    func makeTable() -> Table {
        switch self {
        case .sine: return Table(.sine)
        case .triangle: return Table(.triangle)
        case .square3: return Self.makeBandLimitedSquareWave(maxHarmonic: 3)
        case .square5: return Self.makeBandLimitedSquareWave(maxHarmonic: 5)
        case .square7: return Self.makeBandLimitedSquareWave(maxHarmonic: 7)
        case .square: return Self.makeBandLimitedSquareWave(maxHarmonic: 15)
        case .unsquare: return Table(.square)
        
        }
    }
    
    /// Creates a band-limited square wave using additive synthesis
    /// Only includes harmonics up to a safe frequency to prevent aliasing
    /// 
    /// - Parameters:
    ///   - tableSize: Size of the wavetable (default: 4096)
    ///   - maxHarmonic: Maximum harmonic number to include (default: 15)
    /// - Returns: A Table containing the band-limited square wave
    ///
    /// Technical notes:
    /// - Square waves contain only odd harmonics (1, 3, 5, 7, ...)
    /// - Each harmonic has amplitude 1/n (where n is the harmonic number)
    /// - Limiting to ~15 harmonics keeps content below 7kHz for most musical notes
    /// - This prevents the harsh aliasing artifacts while maintaining square wave character
    ///
    /// Tuning guide:
    /// - maxHarmonic = 7:  Very soft, minimal brightness
    /// - maxHarmonic = 11: Gentle square character
    /// - maxHarmonic = 15: Balanced (recommended default)
    /// - maxHarmonic = 21: Brighter, more aggressive
    /// - maxHarmonic = 31: Maximum brightness (may alias on high notes)
    private static func makeBandLimitedSquareWave(tableSize: Int = 4096, maxHarmonic: Int = 15) -> Table {
        var waveform = [Float](repeating: 0.0, count: tableSize)
        
        // Generate square wave using additive synthesis
        // Square wave = sum of odd harmonics with amplitude 1/n
        for i in 0..<tableSize {
            let phase = (Float(i) / Float(tableSize)) * 2.0 * .pi
            var sample: Float = 0.0
            
            // Add odd harmonics (1, 3, 5, 7, ...)
            for harmonic in stride(from: 1, through: maxHarmonic, by: 2) {
                let amplitude = 1.0 / Float(harmonic)
                sample += amplitude * sin(Float(harmonic) * phase)
            }
            
            // Normalize to approximate square wave amplitude
            // Pure square wave would be 4/π ≈ 1.273, but we're missing high harmonics
            waveform[i] = sample * (4.0 / .pi)
        }
        
        return Table(waveform)
    }
    
    /// Creates a dynamically band-limited square wave that adjusts harmonics based on frequency
    /// This is more sophisticated but requires knowing the playback frequency
    /// >>>> This is not currently implemented in the sound engine and probably won't be, but kept here for reference; static bandlimited squarewave is working well and using this would require complex refactoring and increase CPU load
    ///
    /// - Parameters:
    ///   - frequency: The fundamental frequency in Hz (used to calculate safe harmonic limit)
    ///   - sampleRate: The audio sample rate (default: 44100 Hz)
    ///   - safetyMargin: How much below Nyquist to stay (default: 0.8 = 80% of Nyquist)
    ///   - tableSize: Size of the wavetable (default: 4096)
    /// - Returns: A Table containing the frequency-dependent band-limited square wave
    ///
    /// Example: At 440 Hz with 44.1kHz sample rate:
    /// - Nyquist = 22,050 Hz
    /// - Safe limit = 17,640 Hz (80% of Nyquist)
    /// - Max harmonic = 17,640 / 440 = 40 harmonics
    static func makeDynamicBandLimitedSquareWave(
        frequency: Double = 440.0,
        sampleRate: Double = 44100.0,
        safetyMargin: Double = 0.8,
        tableSize: Int = 4096
    ) -> Table {
        // Calculate Nyquist frequency
        let nyquist = sampleRate / 2.0
        
        // Calculate safe upper frequency limit
        let safeLimit = nyquist * safetyMargin
        
        // Calculate maximum harmonic number
        let maxHarmonic = max(1, Int(floor(safeLimit / frequency)))
        
        var waveform = [Float](repeating: 0.0, count: tableSize)
        
        for i in 0..<tableSize {
            let phase = (Float(i) / Float(tableSize)) * 2.0 * .pi
            var sample: Float = 0.0
            
            // Add odd harmonics up to the calculated limit
            for harmonic in stride(from: 1, through: maxHarmonic, by: 2) {
                let amplitude = 1.0 / Float(harmonic)
                sample += amplitude * sin(Float(harmonic) * phase)
            }
            
            waveform[i] = sample * (4.0 / .pi)
        }
        
        return Table(waveform)
    }
}

/// Parameters for the FM oscillator
struct OscillatorParameters: Codable, Equatable {
    var carrierMultiplier: Double
    var modulatingMultiplier: Double          // Combined coarse + fine (e.g., 2.50 = coarse:2, fine:0.50)
    var modulationIndex: Double
    var waveform: OscillatorWaveform
    var detuneMode: DetuneMode                // How stereo spread is calculated
    var stereoOffsetProportional: Double      // For proportional mode (cents, e.g., 5.0)
    var stereoOffsetConstant: Double          // For constant mode (Hz, e.g., 2.0)
    
    /// Fixed base amplitude for oscillators (used by touch modulation as baseAmplitude)
    var amplitude: Double { 0.5 }
    
    static let `default` = OscillatorParameters(
        carrierMultiplier: 1.0,
        modulatingMultiplier: 2.00,
        modulationIndex: 1.0,
        waveform: .sine,
        detuneMode: .proportional,
        stereoOffsetProportional: 5.0,        // 5 cents (clean default)
        stereoOffsetConstant: 2.0
    )
    
    enum CodingKeys: String, CodingKey {
        case carrierMultiplier, modulatingMultiplier, modulationIndex
        case waveform, detuneMode, stereoOffsetProportional, stereoOffsetConstant
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(waveform, forKey: .waveform)
        try c.encode(carrierMultiplier, forKey: .carrierMultiplier)
        // Snap fine part to 0.001, keep coarse integer intact
        let coarse = floor(modulatingMultiplier)
        let fine = snap(modulatingMultiplier - coarse, to: 0.001)
        try c.encode(coarse + fine, forKey: .modulatingMultiplier)
        try c.encode(snap(modulationIndex, to: 0.05), forKey: .modulationIndex)
        try c.encode(detuneMode, forKey: .detuneMode)
        try c.encode(snap(stereoOffsetConstant, to: 0.01), forKey: .stereoOffsetConstant)
        try c.encode(snap(stereoOffsetProportional, to: 0.05), forKey: .stereoOffsetProportional)
    }
    
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
    
    enum CodingKeys: String, CodingKey {
        case cutoffFrequency
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(snap(cutoffFrequency, to: 1.0), forKey: .cutoffFrequency)
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
    
    enum CodingKeys: String, CodingKey {
        case resonance, saturation
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(snap(resonance, to: 0.02), forKey: .resonance)
        try c.encode(snap(saturation, to: 0.02), forKey: .saturation)
    }
}

/// Combined parameters for a single voice
struct VoiceParameters: Codable, Equatable {
    var oscillator: OscillatorParameters
    var filter: FilterParameters                   // Modulatable (cutoff only)
    var filterStatic: FilterStaticParameters       // Non-modulatable (resonance, saturation)
    var modulation: VoiceModulationParameters      // Modulation system (includes loudnessEnvelope)
    
    static let `default` = VoiceParameters(
        oscillator: .default,
        filter: .default,
        filterStatic: .default,
        modulation: .default
    )
    
    enum CodingKeys: String, CodingKey {
        case oscillator, filter, filterStatic, modulation
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(oscillator, forKey: .oscillator)
        try container.encode(filter, forKey: .filter)
        try container.encode(filterStatic, forKey: .filterStatic)
        try container.encode(modulation, forKey: .modulation)
    }
    
    /// Convenience accessor for the loudness envelope
    var loudnessEnvelope: LoudnessEnvelopeParameters {
        get { modulation.loudnessEnvelope }
        set { modulation.loudnessEnvelope = newValue }
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
    
    enum CodingKeys: String, CodingKey {
        case timeValue, feedback, toneCutoff, dryWetMix
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        // Field order matches NewPresetFormat.json
        try c.encode(timeValue, forKey: .timeValue)
        try c.encode(snap(feedback, to: 0.01), forKey: .feedback)
        try c.encode(snap(toneCutoff, to: 100.0), forKey: .toneCutoff)
        try c.encode(snap(dryWetMix, to: 0.005), forKey: .dryWetMix)
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
    
    enum CodingKeys: String, CodingKey {
        case feedback, cutoffFrequency, balance
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(snap(feedback, to: 0.005), forKey: .feedback)
        try c.encode(snap(cutoffFrequency, to: 100.0), forKey: .cutoffFrequency)
        try c.encode(snap(balance, to: 0.005), forKey: .balance)
    }
}

/// Parameter for the output mixer
struct OutputParameters: Codable, Equatable {
    var preVolume: Double   // Voice mixer volume (before FX)
    var volume: Double      // Output mixer volume (after FX)
    
    static let `default` = OutputParameters(
        preVolume: 0.5,
        volume: 0.75
    )
    
    enum CodingKeys: String, CodingKey {
        case preVolume, volume
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(snap(preVolume, to: 0.01), forKey: .preVolume)
        try c.encode(snap(volume, to: 0.01), forKey: .volume)
    }
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
    
    enum CodingKeys: String, CodingKey {
        case octave, transpose, fineTune
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        // Field order matches NewPresetFormat.json
        // No snapping — these are computed from integer offsets/semitones, precise values matter
        try c.encode(octave, forKey: .octave)
        try c.encode(transpose, forKey: .transpose)
        try c.encode(fineTune, forKey: .fineTune)
    }
    
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
    
    enum CodingKeys: String, CodingKey {
        case toneToModulationIndexRange, toneToFilterCutoffOctaves, toneToFilterSaturationRange
        case ambienceToDelayFeedbackRange, ambienceToDelayMixRange
        case ambienceToReverbFeedbackRange, ambienceToReverbMixRange
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(snap(toneToModulationIndexRange, to: 0.05), forKey: .toneToModulationIndexRange)
        try c.encode(snap(toneToFilterCutoffOctaves, to: 0.01), forKey: .toneToFilterCutoffOctaves)
        try c.encode(snap(toneToFilterSaturationRange, to: 0.02), forKey: .toneToFilterSaturationRange)
        try c.encode(snap(ambienceToDelayFeedbackRange, to: 0.01), forKey: .ambienceToDelayFeedbackRange)
        try c.encode(snap(ambienceToDelayMixRange, to: 0.01), forKey: .ambienceToDelayMixRange)
        try c.encode(snap(ambienceToReverbFeedbackRange, to: 0.01), forKey: .ambienceToReverbFeedbackRange)
        try c.encode(snap(ambienceToReverbMixRange, to: 0.01), forKey: .ambienceToReverbMixRange)
    }
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
    
    enum CodingKeys: String, CodingKey {
        case tempo, voiceMode, globalPitch, globalLFO, delay, reverb, output, macroControl
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        // Field order matches NewPresetFormat.json
        try c.encode(snap(tempo, to: 1.0), forKey: .tempo)
        try c.encode(voiceMode, forKey: .voiceMode)
        try c.encode(globalPitch, forKey: .globalPitch)
        try c.encode(globalLFO, forKey: .globalLFO)
        try c.encode(delay, forKey: .delay)
        try c.encode(reverb, forKey: .reverb)
        try c.encode(output, forKey: .output)
        try c.encode(macroControl, forKey: .macroControl)
    }
}

// MARK: - Complete Parameter Set (for Presets)

/// A complete snapshot of all audio parameters - used for presets
struct AudioParameterSet: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var voiceTemplate: VoiceParameters  // Template applied to all voices
    var master: MasterParameters
    var macroState: MacroControlState   // Runtime macro positions and base values (derived on load)
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
    
    // macroState is derived from voiceTemplate/master on load, not serialized
    enum CodingKeys: String, CodingKey {
        case id, name, voiceTemplate, master, createdAt
    }
    
    init(id: UUID, name: String, voiceTemplate: VoiceParameters, master: MasterParameters,
         macroState: MacroControlState, createdAt: Date) {
        self.id = id
        self.name = name
        self.voiceTemplate = voiceTemplate
        self.master = master
        self.macroState = macroState
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        voiceTemplate = try c.decode(VoiceParameters.self, forKey: .voiceTemplate)
        master = try c.decode(MasterParameters.self, forKey: .master)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        macroState = MacroControlState(from: voiceTemplate, masterParams: master)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        // Field order matches NewPresetFormat.json
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(voiceTemplate, forKey: .voiceTemplate)
        try c.encode(master, forKey: .master)
    }
}

