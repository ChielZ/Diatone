//
//  Scales.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 04/12/2025.
//

import Foundation

enum Intonation: String, CaseIterable, Equatable {
    case ji = "JI"
    case et = "ET"
}

enum Celestial: String, CaseIterable, Equatable {
    case moon = "Moon"
    case center = "Center"
    case sun = "Sun"
}

enum Terrestrial: String, CaseIterable, Equatable {
    case orient = "Orient"
    case meridian = "Meridian"
    case occident = "Occident"
}

struct Scale: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let intonation: Intonation
    let celestial: Celestial
    let terrestrial: Terrestrial
    // Five-note scale as frequency ratios relative to tonic (1.0 == 1/1)
    let notes: [Double]
}

// MARK: - Helpers

private func et(_ semitoneSteps: [Int]) -> [Double] {
    semitoneSteps.map { step in pow(2.0, Double(step) / 12.0) }
}

// Given a scale and a base frequency (RootFreq), produce 18 key frequencies
// Mapping (1-based keys):
// 1..5:  note1..note5
// 6..10: note1..note5 * 2
// 11..15: note1..note5 * 4
// 16..18: note1..note3 * 8
func makeKeyFrequencies(for scale: Scale, baseFrequency: Double) -> [Double] {
    precondition(scale.notes.count == 5, "Scale must be pentatonic (5 notes).")
    // Expand notes to absolute frequencies for the base octave
    let baseNotes = scale.notes.map { $0 * baseFrequency }

    var result: [Double] = []
    // Octave multipliers for groups
    let multipliers: [Double] = [1.0, 2.0, 4.0, 8.0]
    // Group sizes: 5, 5, 5, 3
    let groupSizes: [Int] = [5, 5, 5, 3]

    for (groupIndex, groupSize) in groupSizes.enumerated() {
        let mul = multipliers[groupIndex]
        for i in 0..<groupSize {
            result.append(baseNotes[i] * mul)
        }
    }

    // Sanity: ensure we produced exactly 18 frequencies
    assert(result.count == 18)
    return result
}

// MARK: - All Scales

struct ScalesCatalog {
    // Just Intonation (ratios)
    static let moonOrient_JI = Scale(
        name: "Moon Orient (JI)",
        intonation: .ji, celestial: .moon, terrestrial: .orient,
        notes: [1.0, 16.0/15.0, 4.0/3.0, 3.0/2.0, 8.0/5.0]
    )

    static let moonMeridian_JI = Scale(
        name: "Moon Meridian (JI)",
        intonation: .ji, celestial: .moon, terrestrial: .meridian,
        notes: [1.0, 6.0/5.0, 4.0/3.0, 3.0/2.0, 8.0/5.0]
    )

    static let moonOccident_JI = Scale(
        name: "Moon Occident (JI)",
        intonation: .ji, celestial: .moon, terrestrial: .occident,
        notes: [1.0, 6.0/5.0, 4.0/3.0, 3.0/2.0, 9.0/5.0]
    )

    static let centerOrient_JI = Scale(
        name: "Center Orient (JI)",
        intonation: .ji, celestial: .center, terrestrial: .orient,
        notes: [1.0, 5.0/4.0, 4.0/3.0, 3.0/2.0, 8.0/5.0]
    )

    static let centerMeridian_JI = Scale(
        name: "Center Meridian (JI)",
        intonation: .ji, celestial: .center, terrestrial: .meridian,
        notes: [1.0, 9.0/8.0, 4.0/3.0, 3.0/2.0, 16.0/9.0]
    )

    static let centerOccident_JI = Scale(
        name: "Center Occident (JI)",
        intonation: .ji, celestial: .center, terrestrial: .occident,
        notes: [1.0, 6.0/5.0, 4.0/3.0, 3.0/2.0, 5.0/3.0]
    )

    static let sunOrient_JI = Scale(
        name: "Sun Orient (JI)",
        intonation: .ji, celestial: .sun, terrestrial: .orient,
        notes: [1.0, 5.0/4.0, 4.0/3.0, 3.0/2.0, 15.0/8.0]
    )

    static let sunMeridian_JI = Scale(
        name: "Sun Meridian (JI)",
        intonation: .ji, celestial: .sun, terrestrial: .meridian,
        notes: [1.0, 5.0/4.0, 4.0/3.0, 3.0/2.0, 5.0/3.0]
    )

    static let sunOccident_JI = Scale(
        name: "Sun Occident (JI)",
        intonation: .ji, celestial: .sun, terrestrial: .occident,
        notes: [1.0, 10.0/9.0, 4.0/3.0, 3.0/2.0, 5.0/3.0]
    )

    // Equal Temperament (semitone steps -> 2^(n/12))
    // Each list is [0, x, y, z, w] semitone steps from tonic.
    static let moonOrient_ET = Scale(
        name: "Moon Orient (ET)",
        intonation: .et, celestial: .moon, terrestrial: .orient,
        notes: et([0, 1, 5, 7, 8])
    )

    static let moonMeridian_ET = Scale(
        name: "Moon Meridian (ET)",
        intonation: .et, celestial: .moon, terrestrial: .meridian,
        notes: et([0, 3, 5, 7, 8])
    )

    static let moonOccident_ET = Scale(
        name: "Moon Occident (ET)",
        intonation: .et, celestial: .moon, terrestrial: .occident,
        notes: et([0, 3, 5, 7, 10])
    )

    static let centerOrient_ET = Scale(
        name: "Center Orient (ET)",
        intonation: .et, celestial: .center, terrestrial: .orient,
        notes: et([0, 4, 5, 7, 8])
    )

    static let centerMeridian_ET = Scale(
        name: "Center Meridian (ET)",
        intonation: .et, celestial: .center, terrestrial: .meridian,
        notes: et([0, 2, 5, 7, 10])
    )

    static let centerOccident_ET = Scale(
        name: "Center Occident (ET)",
        intonation: .et, celestial: .center, terrestrial: .occident,
        notes: et([0, 3, 5, 7, 9])
    )

    static let sunOrient_ET = Scale(
        name: "Sun Orient (ET)",
        intonation: .et, celestial: .sun, terrestrial: .orient,
        notes: et([0, 4, 5, 7, 11])
    )

    static let sunMeridian_ET = Scale(
        name: "Sun Meridian (ET)",
        intonation: .et, celestial: .sun, terrestrial: .meridian,
        notes: et([0, 4, 5, 7, 9])
    )

    static let sunOccident_ET = Scale(
        name: "Sun Occident (ET)",
        intonation: .et, celestial: .sun, terrestrial: .occident,
        notes: et([0, 2, 5, 7, 9])
    )

    static let all: [Scale] = [
        moonOrient_JI, moonMeridian_JI, moonOccident_JI,
        centerOrient_JI, centerMeridian_JI, centerOccident_JI,
        sunOrient_JI, sunMeridian_JI, sunOccident_JI,
        moonOrient_ET, moonMeridian_ET, moonOccident_ET,
        centerOrient_ET, centerMeridian_ET, centerOccident_ET,
        sunOrient_ET, sunMeridian_ET, sunOccident_ET
    ]

    static func find(intonation: Intonation, celestial: Celestial, terrestrial: Terrestrial) -> Scale? {
        all.first {
            $0.intonation == intonation &&
            $0.celestial == celestial &&
            $0.terrestrial == terrestrial
        }
    }
}
