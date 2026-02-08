//
//  S1 Scales.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 04/12/2025.
//

import Foundation

enum Intonation: String, CaseIterable, Equatable {
    case ji = "JUST"
    case et = "EQUAL"
}

enum Celestial: String, CaseIterable, Equatable {
    case moon = "MOON"
    case center = "CENTER"
    case sun = "SUN"
    case easy = "EASY"
    case outward = "OUTWARD"
    case balanced = "BALANCED"
    case inward = "INWARD"
    case double = "DOUBLE"
}

enum Terrestrial: String, CaseIterable, Equatable {
    case occident = "OCCIDENT"
    case meridian = "MERIDIAN"
    case orient = "ORIENT"
    case easy = "EASY"
    case melodic = "MELODIC"
    case ascent = "ASCENT"
    case descent = "DESCENT"
    case harmonic = "HARMONIC"
    case melodicL1 = "MELODIC L1"
    case melodicL2 = "MELODIC L2"
    case melodicS1 = "MELODIC S1"
    case melodicS2 = "MELODIC S2"
    case melodicS3 = "MELODIC S3"
    case melodicR1 = "MELODIC R1"
    case melodicR2 = "MELODIC R2"
}

enum MusicalKey: String, CaseIterable, Equatable {
    case Ab = "A♭"
    case Eb = "E♭"
    case Bb = "B♭"
    case F = "F"
    case C = "C"
    case G = "G"
    case D = "D"     // Default/center key
    case A = "A"
    case E = "E"
    case B = "B"
    case Fs = "F♯"   // F# (using Fs to avoid # in enum name)
    case Cs = "C♯"   // C# (using Cs to avoid # in enum name)
    case Gs = "G♯"   // G# (using Gs to avoid # in enum name)
    
    /// Returns the note letter without accidental (e.g., "A", "F", "C")
    var noteLetter: String {
        switch self {
        case .Ab, .A: return "A"
        case .Bb, .B: return "B"
        case .C, .Cs: return "C"
        case .D: return "D"
        case .Eb, .E: return "E"
        case .F, .Fs: return "F"
        case .G, .Gs: return "G"
        }
    }
    
    /// Returns the accidental symbol if present (♯ or ♭), or nil for natural notes
    var accidental: String? {
        switch self {
        case .Ab, .Eb, .Bb: return "♭"
        case .Fs, .Cs, .Gs: return "♯"
        case .F, .C, .G, .D, .A, .E, .B: return nil
        }
    }
    
    /// The base diatonic letter for this key
    var baseLetter: DiatonicLetter {
        switch self {
        case .C, .Cs: return .c
        case .D: return .d
        case .E, .Eb: return .e
        case .F, .Fs: return .f
        case .G, .Gs: return .g
        case .A, .Ab: return .a
        case .B, .Bb: return .b
        }
    }
    
    /// Chromatic semitone offset (0-11)
    var semitoneOffset: Int {
        switch self {
        case .C: return 0
        case .Cs: return 1
        case .D: return 2
        case .Eb: return 3
        case .E: return 4
        case .F: return 5
        case .Fs: return 6
        case .G: return 7
        case .Gs, .Ab: return 8
        case .A: return 9
        case .Bb: return 10
        case .B: return 11
        }
    }
    
    /// The base frequency for D (the center/default key)
    static let baseFrequency: Double = 146.83
    
    /// Returns the pitch multiplication factor for equal temperament
    /// Positive semitones multiply by 2^(n/12), negative divide
    func pitchFactorET() -> Double {
        let semitones: Int
        switch self {
        case .Ab: semitones = -6
        case .Eb: semitones = 1
        case .Bb: semitones = -4
        case .F:  semitones = 3
        case .C:  semitones = -2
        case .G:  semitones = 5
        case .D:  semitones = 0  // Center/default
        case .A:  semitones = -5
        case .E:  semitones = 2
        case .B:  semitones = -3
        case .Fs: semitones = 4
        case .Cs: semitones = -1
        case .Gs: semitones = 6
        }
        return pow(2.0, Double(semitones) / 12.0)
    }
    
    /// Returns the pitch multiplication factor for just intonation
    func pitchFactorJI() -> Double {
        switch self {
        case .Ab: return 512.0 / 729.0
        case .Eb: return 256.0 / 243.0
        case .Bb: return 64.0 / 81.0
        case .F:  return 32.0 / 27.0
        case .C:  return 8.0 / 9.0
        case .G:  return 4.0 / 3.0
        case .D:  return 1.0  // Center/default
        case .A:  return 3.0 / 4.0
        case .E:  return 9.0 / 8.0
        case .B:  return 27.0 / 32.0
        case .Fs: return 81.0 / 64.0
        case .Cs: return 243.0 / 256.0
        case .Gs: return 729.0 / 512.0
        }
    }
    
    /// Returns the appropriate pitch factor based on the intonation type
    func pitchFactor(for intonation: Intonation) -> Double {
        switch intonation {
        case .et: return pitchFactorET()
        case .ji: return pitchFactorJI()
        }
    }
}

struct Scale: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let intonation: Intonation
    let celestial: Celestial
    let terrestrial: Terrestrial
    // Five-note scale as frequency ratios relative to tonic (1.0 == 1/1)
    let notes: [Double]
    var rotation: Int = 0 // Range: -2 to +2
    
    // For note naming algorithm
    let semitonePattern: [Int]  // e.g., [0, 2, 5, 7, 10]
    let letterPattern: [Int]    // e.g., [0, 1, 3, 4, 6]
}

// MARK: - Helpers

private func et(_ semitoneSteps: [Int]) -> [Double] {
    semitoneSteps.map { step in pow(2.0, Double(step) / 12.0) }
}

// Apply rotation to scale notes
// Rotation determines which note of the scale is mapped to the lowest key
// Positive rotation: shift notes to the left (later notes become earlier)
// Negative rotation: shift notes to the right (earlier notes become later, divided by 2)
private func applyRotation(to notes: [Double], rotation: Int) -> [Double] {
    guard rotation != 0 else { return notes }
    let count = notes.count
    var rotatedNotes: [Double] = []
    
    if rotation > 0 {
        // Positive rotation: notes shift left
        // e.g., rotation +1: [1, 9/8, 4/3, 3/2, 16/9] -> [9/8, 4/3, 3/2, 16/9, 1*2]
        for i in 0..<count {
            let sourceIndex = (i + rotation) % count
            var note = notes[sourceIndex]
            
            // If we wrapped around, multiply by 2 (next octave)
            if sourceIndex < rotation {
                note *= 2.0
            }
            rotatedNotes.append(note)
        }
    } else {
        // Negative rotation: notes shift right
        // e.g., rotation -1: [1, 9/8, 4/3, 3/2, 16/9] -> [16/9 / 2, 1, 9/8, 4/3, 3/2]
        let absRotation = abs(rotation)
        for i in 0..<count {
            let sourceIndex = (i - absRotation + count) % count
            var note = notes[sourceIndex]
            
            // If we wrapped around (sourceIndex >= count - absRotation), divide by 2 (previous octave)
            if sourceIndex >= count - absRotation {
                note /= 2.0
            }
            rotatedNotes.append(note)
        }
    }
    
    return rotatedNotes
}

// Given a scale and a base frequency (RootFreq), produce 22 key frequencies
// Mapping (1-based keys):
// 1..7:  note1..note7
// 8..14: note1..note7 * 2
// 15..21: note1..note7 * 4
// 22: note1 * 8
// With rotation applied, the starting note changes accordingly
// If a musicalKey is provided, applies transposition factor
func makeKeyFrequencies(for scale: Scale, baseFrequency: Double = MusicalKey.baseFrequency, musicalKey: MusicalKey = .D) -> [Double] {
    precondition(scale.notes.count == 7, "Scale must be diatonic (7 notes).")
    
    // Apply rotation to get the reordered notes
    let rotatedNotes = applyRotation(to: scale.notes, rotation: scale.rotation)
    
    // Apply key transposition factor
    let keyFactor = musicalKey.pitchFactor(for: scale.intonation)
    let transposedBaseFrequency = baseFrequency * keyFactor
    
    // Expand notes to absolute frequencies for the base octave
    let baseNotes = rotatedNotes.map { $0 * transposedBaseFrequency }

    var result: [Double] = []
    // Octave multipliers for groups
    let multipliers: [Double] = [1.0, 2.0, 4.0, 8.0]
    // Group sizes: 5, 5, 5, 3
    let groupSizes: [Int] = [7, 7, 7, 1]

    for (groupIndex, groupSize) in groupSizes.enumerated() {
        let mul = multipliers[groupIndex]
        for i in 0..<groupSize {
            result.append(baseNotes[i] * mul)
        }
    }

    // Sanity: ensure we produced exactly 22 frequencies
    assert(result.count == 22)
    return result
}

// MARK: - All Scales

struct ScalesCatalog {
    
    // NEW: DIATONIC SCALES FOR DIATONE APP
    
    // 1. EASY JI
    
    static let Locrian_JI_E = Scale(
        name: "Locrian",
        intonation: .ji, celestial: .easy, terrestrial: .easy,
        notes: [1.0, 16.0/15.0, 6.0/5.0, 4.0/3.0, 64.0/45.0, 8.0/5.0, 16.0/9.0],
        semitonePattern: [0, 1, 3, 5, 6, 8, 10],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let Phrygian_JI_E = Scale(
        name: "Phrygian",
        intonation: .ji, celestial: .easy, terrestrial: .easy,
        notes: [1.0, 16.0/15.0, 6.0/5.0, 4.0/3.0, 3.0/2.0, 8.0/5.0, 16.0/9.0],
        semitonePattern: [0, 1, 3, 5, 7, 8, 10],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let Aeolian_JI_E = Scale(
        name: "Aeolian",
        intonation: .ji, celestial: .easy, terrestrial: .easy,
        notes: [1.0, 10.0/9.0, 6.0/5.0, 4.0/3.0, 3.0/2.0, 8.0/5.0, 16.0/9.0],
        semitonePattern: [0, 2, 3, 5, 7, 8, 10],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let Dorian_JI_E = Scale(
        name: "Dorian",
        intonation: .ji, celestial: .easy, terrestrial: .easy,
        notes: [1.0, 10.0/9.0, 6.0/5.0, 4.0/3.0, 3.0/2.0, 5.0/3.0, 9.0/5.0],
        semitonePattern: [0, 2, 3, 5, 7, 9, 10],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let Mixolydian_JI_E = Scale(
        name: "Mixolydian",
        intonation: .ji, celestial: .easy, terrestrial: .easy,
        notes: [1.0, 9.0/8.0, 5.0/4.0, 4.0/3.0, 3.0/2.0, 5.0/3.0, 9.0/5.0],
        semitonePattern: [0, 2, 4, 5, 7, 9, 10],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let Ionian_JI_E = Scale(
        name: "Ionian",
        intonation: .ji, celestial: .easy, terrestrial: .easy,
        notes: [1.0, 9.0/8.0, 5.0/4.0, 4.0/3.0, 3.0/2.0, 5.0/3.0, 15.0/8.0],
        semitonePattern: [0, 2, 4, 5, 7, 9, 11],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let Lydian_JI_E = Scale(
        name: "Lydian",
        intonation: .ji, celestial: .easy, terrestrial: .easy,
        notes: [1.0, 9.0/8.0, 5.0/4.0, 45.0/32.0, 3.0/2.0, 5.0/3.0, 15.0/8.0],
        semitonePattern: [0, 2, 4, 6, 7, 9, 11],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let MelodicMinor_JI_E = Scale(
        name: "Melodic Minor",
        intonation: .ji, celestial: .easy, terrestrial: .easy,
        notes: [1.0, 9.0/8.0, 6.0/5.0, 4.0/3.0, 3.0/2.0, 27.0/16.0, 15.0/8.0],
        semitonePattern: [0, 2, 3, 5, 7, 9, 11],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let MelodicMajor_JI_E = Scale(
        name: "Melodic Major",
        intonation: .ji, celestial: .easy, terrestrial: .easy,
        notes: [1.0, 9.0/8.0, 5.0/4.0, 4.0/3.0, 3.0/2.0, 8.0/5.0, 16.0/9.0],
        semitonePattern: [0, 2, 4, 5, 7, 8, 10],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let HarmonicMinor_JI_E = Scale(
        name: "Harmonic Minor",
        intonation: .ji, celestial: .easy, terrestrial: .easy,
        notes: [1.0, 9.0/8.0, 6.0/5.0, 4.0/3.0, 3.0/2.0, 8.0/5.0, 15.0/8.0],
        semitonePattern: [0, 2, 3, 5, 7, 8, 11],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let HarmonicMajor_JI_E = Scale(
        name: "Harmonic Major",
        intonation: .ji, celestial: .easy, terrestrial: .easy,
        notes: [1.0, 9.0/8.0, 5.0/4.0, 4.0/3.0, 3.0/2.0, 8.0/5.0, 15.0/8.0],
        semitonePattern: [0, 2, 4, 5, 7, 8, 11],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let DoubleHarmonic_JI_E = Scale(
        name: "Double Harmonic",
        intonation: .ji, celestial: .easy, terrestrial: .easy,
        notes: [1.0, 16.0/15.0, 5.0/4.0, 4.0/3.0, 3.0/2.0, 8.0/5.0, 15.0/8.0],
        semitonePattern: [0, 1, 4, 5, 7, 8, 11],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    
    // 2. EASY ET
    
    static let Locrian_ET_E = Scale(
        name: "Locrian",
        intonation: .et, celestial: .easy, terrestrial: .easy,
        notes: et([0, 1, 3, 5, 6, 8, 10]),
        semitonePattern: [0, 1, 3, 5, 6, 8, 10],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let Phrygian_ET_E = Scale(
        name: "Phrygian",
        intonation: .et, celestial: .easy, terrestrial: .easy,
        notes: et([0, 1, 3, 5, 7, 8, 10]),
        semitonePattern: [0, 1, 3, 5, 7, 8, 10],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let Aeolian_ET_E = Scale(
        name: "Aeolian",
        intonation: .et, celestial: .easy, terrestrial: .easy,
        notes: et([0, 2, 3, 5, 7, 8, 10]),
        semitonePattern: [0, 2, 3, 5, 7, 8, 10],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let Dorian_ET_E = Scale(
        name: "Dorian",
        intonation: .et, celestial: .easy, terrestrial: .easy,
        notes: et([0, 2, 3, 5, 7, 9, 10]),
        semitonePattern: [0, 2, 3, 5, 7, 9, 10],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let Mixolydian_ET_E = Scale(
        name: "Mixolydian",
        intonation: .et, celestial: .easy, terrestrial: .easy,
        notes: et([0, 2, 4, 5, 7, 9, 10]),
        semitonePattern: [0, 2, 4, 5, 7, 9, 10],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let Ionian_ET_E = Scale(
        name: "Ionian",
        intonation: .et, celestial: .easy, terrestrial: .easy,
        notes: et([0, 2, 4, 5, 7, 9, 11]),
        semitonePattern: [0, 2, 4, 5, 7, 9, 11],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let Lydian_ET_E = Scale(
        name: "Lydian",
        intonation: .et, celestial: .easy, terrestrial: .easy,
        notes: et([0, 2, 4, 6, 7, 9, 11]),
        semitonePattern: [0, 2, 4, 6, 7, 9, 11],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let MelodicMinor_ET_E = Scale(
        name: "Melodic Minor",
        intonation: .et, celestial: .easy, terrestrial: .easy,
        notes: et([0, 2, 3, 5, 7, 9, 11]),
        semitonePattern: [0, 2, 3, 5, 7, 9, 11],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let MelodicMajor_ET_E = Scale(
        name: "Melodic Major",
        intonation: .et, celestial: .easy, terrestrial: .easy,
        notes: et([0, 2, 4, 5, 7, 8, 10]),
        semitonePattern: [0, 2, 4, 5, 7, 8, 10],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let HarmonicMinor_ET_E = Scale(
        name: "Harmonic Minor",
        intonation: .et, celestial: .easy, terrestrial: .easy,
        notes: et([0, 2, 3, 5, 7, 8, 11]),
        semitonePattern: [0, 2, 3, 5, 7, 8, 11],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let HarmonicMajor_ET_E = Scale(
        name: "Harmonic Major",
        intonation: .et, celestial: .easy, terrestrial: .easy,
        notes: et([0, 2, 4, 5, 7, 8, 11]),
        semitonePattern: [0, 2, 4, 5, 7, 8, 11],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    static let DoubleHarmonic_ET_E = Scale(
        name: "Double Harmonic",
        intonation: .et, celestial: .easy, terrestrial: .easy,
        notes: et([0, 1, 4, 5, 7, 8, 11]),
        semitonePattern: [0, 1, 4, 5, 7, 8, 11],
        letterPattern: [0, 1, 2, 3, 4, 5, 6]
    )
    
    
    
    
    // 3. JI PRO
    
    
    
    // 4. ET PRO
    
    
    
    
    
    
    
    
    /*
    // OLD: PENTATONIC SCALES FOR PENTATONE APP
    // Just Intonation (ratios)
    static let moonOrient_JI = Scale(
        name: "Moon Orient (JI)",
        intonation: .ji, celestial: .moon, terrestrial: .orient,
        notes: [1.0, 16.0/15.0, 4.0/3.0, 3.0/2.0, 8.0/5.0],
        semitonePattern: [0, 1, 5, 7, 8],
        letterPattern: [0, 1, 3, 4, 5]
    )

    static let moonMeridian_JI = Scale(
        name: "Moon Meridian (JI)",
        intonation: .ji, celestial: .moon, terrestrial: .meridian,
        notes: [1.0, 6.0/5.0, 4.0/3.0, 3.0/2.0, 8.0/5.0],
        semitonePattern: [0, 3, 5, 7, 8],
        letterPattern: [0, 2, 3, 4, 5]
    )

    static let moonOccident_JI = Scale(
        name: "Moon Occident (JI)",
        intonation: .ji, celestial: .moon, terrestrial: .occident,
        notes: [1.0, 6.0/5.0, 4.0/3.0, 3.0/2.0, 9.0/5.0],
        semitonePattern: [0, 3, 5, 7, 10],
        letterPattern: [0, 2, 3, 4, 6]
    )

    static let centerOrient_JI = Scale(
        name: "Center Orient (JI)",
        intonation: .ji, celestial: .center, terrestrial: .orient,
        notes: [1.0, 5.0/4.0, 4.0/3.0, 3.0/2.0, 8.0/5.0],
        semitonePattern: [0, 4, 5, 7, 8],
        letterPattern: [0, 2, 3, 4, 5]
    )

    static let centerMeridian_JI = Scale(
        name: "Center Meridian (JI)",
        intonation: .ji, celestial: .center, terrestrial: .meridian,
        notes: [1.0, 9.0/8.0, 4.0/3.0, 3.0/2.0, 16.0/9.0],
        semitonePattern: [0, 2, 5, 7, 10],
        letterPattern: [0, 1, 3, 4, 6]
    )

    static let centerOccident_JI = Scale(
        name: "Center Occident (JI)",
        intonation: .ji, celestial: .center, terrestrial: .occident,
        notes: [1.0, 6.0/5.0, 4.0/3.0, 3.0/2.0, 5.0/3.0],
        semitonePattern: [0, 3, 5, 7, 9],
        letterPattern: [0, 2, 3, 4, 5]
    )

    static let sunOrient_JI = Scale(
        name: "Sun Orient (JI)",
        intonation: .ji, celestial: .sun, terrestrial: .orient,
        notes: [1.0, 5.0/4.0, 4.0/3.0, 3.0/2.0, 15.0/8.0],
        semitonePattern: [0, 4, 5, 7, 11],
        letterPattern: [0, 2, 3, 4, 6]
    )

    static let sunMeridian_JI = Scale(
        name: "Sun Meridian (JI)",
        intonation: .ji, celestial: .sun, terrestrial: .meridian,
        notes: [1.0, 5.0/4.0, 4.0/3.0, 3.0/2.0, 5.0/3.0],
        semitonePattern: [0, 4, 5, 7, 9],
        letterPattern: [0, 2, 3, 4, 5]
    )

    static let sunOccident_JI = Scale(
        name: "Sun Occident (JI)",
        intonation: .ji, celestial: .sun, terrestrial: .occident,
        notes: [1.0, 10.0/9.0, 4.0/3.0, 3.0/2.0, 5.0/3.0],
        semitonePattern: [0, 2, 5, 7, 9],
        letterPattern: [0, 1, 3, 4, 5]
    )

    // Equal Temperament (semitone steps -> 2^(n/12))
    // Each list is [0, x, y, z, w] semitone steps from tonic.
    static let moonOrient_ET = Scale(
        name: "Moon Orient (ET)",
        intonation: .et, celestial: .moon, terrestrial: .orient,
        notes: et([0, 1, 5, 7, 8]),
        semitonePattern: [0, 1, 5, 7, 8],
        letterPattern: [0, 1, 3, 4, 5]
    )

    static let moonMeridian_ET = Scale(
        name: "Moon Meridian (ET)",
        intonation: .et, celestial: .moon, terrestrial: .meridian,
        notes: et([0, 3, 5, 7, 8]),
        semitonePattern: [0, 3, 5, 7, 8],
        letterPattern: [0, 2, 3, 4, 5]
    )

    static let moonOccident_ET = Scale(
        name: "Moon Occident (ET)",
        intonation: .et, celestial: .moon, terrestrial: .occident,
        notes: et([0, 3, 5, 7, 10]),
        semitonePattern: [0, 3, 5, 7, 10],
        letterPattern: [0, 2, 3, 4, 6]
    )

    static let centerOrient_ET = Scale(
        name: "Center Orient (ET)",
        intonation: .et, celestial: .center, terrestrial: .orient,
        notes: et([0, 4, 5, 7, 8]),
        semitonePattern: [0, 4, 5, 7, 8],
        letterPattern: [0, 2, 3, 4, 5]
    )

    static let centerMeridian_ET = Scale(
        name: "Center Meridian (ET)",
        intonation: .et, celestial: .center, terrestrial: .meridian,
        notes: et([0, 2, 5, 7, 10]),
        semitonePattern: [0, 2, 5, 7, 10],
        letterPattern: [0, 1, 3, 4, 6]
    )

    static let centerOccident_ET = Scale(
        name: "Center Occident (ET)",
        intonation: .et, celestial: .center, terrestrial: .occident,
        notes: et([0, 3, 5, 7, 9]),
        semitonePattern: [0, 3, 5, 7, 9],
        letterPattern: [0, 2, 3, 4, 5]
    )

    static let sunOrient_ET = Scale(
        name: "Sun Orient (ET)",
        intonation: .et, celestial: .sun, terrestrial: .orient,
        notes: et([0, 4, 5, 7, 11]),
        semitonePattern: [0, 4, 5, 7, 11],
        letterPattern: [0, 2, 3, 4, 6]
    )

    static let sunMeridian_ET = Scale(
        name: "Sun Meridian (ET)",
        intonation: .et, celestial: .sun, terrestrial: .meridian,
        notes: et([0, 4, 5, 7, 9]),
        semitonePattern: [0, 4, 5, 7, 9],
        letterPattern: [0, 2, 3, 4, 5]
    )

    static let sunOccident_ET = Scale(
        name: "Sun Occident (ET)",
        intonation: .et, celestial: .sun, terrestrial: .occident,
        notes: et([0, 2, 5, 7, 9]),
        semitonePattern: [0, 2, 5, 7, 9],
        letterPattern: [0, 1, 3, 4, 5]
    )
*/
    static let all: [Scale] = [
        /*
        moonOrient_JI, moonMeridian_JI, moonOccident_JI,
        centerOrient_JI, centerMeridian_JI, centerOccident_JI,
        sunOrient_JI, sunMeridian_JI, sunOccident_JI,
        moonOrient_ET, moonMeridian_ET, moonOccident_ET,
        centerOrient_ET, centerMeridian_ET, centerOccident_ET,
        sunOrient_ET, sunMeridian_ET, sunOccident_ET
         */
        Locrian_JI_E, Phrygian_JI_E, Aeolian_JI_E, Dorian_JI_E, Mixolydian_JI_E, Ionian_JI_E, Lydian_JI_E, MelodicMinor_JI_E, MelodicMajor_JI_E, HarmonicMinor_JI_E, HarmonicMajor_JI_E, DoubleHarmonic_JI_E,
        Locrian_ET_E, Phrygian_ET_E, Aeolian_ET_E, Dorian_ET_E, Mixolydian_ET_E, Ionian_ET_E, Lydian_ET_E, MelodicMinor_ET_E, MelodicMajor_ET_E, HarmonicMinor_ET_E, HarmonicMajor_ET_E, DoubleHarmonic_ET_E, 
    ]

    static func find(intonation: Intonation, celestial: Celestial, terrestrial: Terrestrial) -> Scale? {
        all.first {
            $0.intonation == intonation &&
            $0.celestial == celestial &&
            $0.terrestrial == terrestrial
        }
    }
}

/*
 
 KEY TRANSPOSITION IMPLEMENTATION
 
 Key transposition is implemented via the MusicalKey enum above.
 Each key has two pitch factors (ET and JI) that multiply the base frequency.
 
 The base frequency is 146.83 Hz (D note), defined as MusicalKey.baseFrequency.
 When returning to D after multiple key changes, the frequency will always be exactly 146.83 Hz
 because the pitch factor for D is exactly 1.0 (no cumulative error).
 
 Key order (non-looping, from left to right):
 Ab -> Eb -> Bb -> F -> C -> G -> D -> A -> E -> B -> F# -> C# -> G#
 
 The makeKeyFrequencies() function accepts a musicalKey parameter and applies
 the appropriate transposition factor based on the scale's intonation type.
 
 */

