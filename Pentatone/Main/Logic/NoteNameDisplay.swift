//
//  NoteNameDisplay.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 20/12/2025.
//

import Foundation
import SwiftUI


/// Represents the seven diatonic letters (A-G) used in Western music notation
enum DiatonicLetter: Int, CaseIterable {
    case c = 0, d = 1, e = 2, f = 3, g = 4, a = 5, b = 6
    
    /// The letter name in uppercase (e.g., "C", "D", "E")
    var name: String {
        String(describing: self).uppercased()
    }
    
    /// Advance by a number of diatonic steps (wraps around at 7)
    func advanced(by steps: Int) -> DiatonicLetter {
        let newIndex = (rawValue + steps % 7 + 7) % 7
        return DiatonicLetter(rawValue: newIndex)!
    }
    
    /// The semitone offset of this letter when unmodified (natural)
    /// Relative to C = 0
    var naturalSemitoneOffset: Int {
        switch self {
        case .c: return 0
        case .d: return 2
        case .e: return 4
        case .f: return 5
        case .g: return 7
        case .a: return 9
        case .b: return 11
        }
    }
}



/// A view that displays a note name with the letter in Futura
/// and the accidental (♯ or ♭) in Arial Unicode MS for better typography.
struct NoteNameText: View {
    let noteName: NoteName
    let size: CGFloat
    let color: Color
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var adaptiveSize: CGFloat {
        // Regular width and height = iPad in any orientation
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return size
        } else if horizontalSizeClass == .regular {
            // iPhone Plus/Max in landscape
            return size * 0.75
        } else {
            // iPhone in portrait (compact width)
            return size * 0.65
        }
    }
    
    var body: some View {
        HStack(spacing: -2) {
            // Note letter in Futura
            Text(noteName.letter)
                .foregroundColor(color)
                .font(.custom("Futura", size: adaptiveSize))
            
            // Accidental in Arial Unicode MS (if present)
            if let accidental = noteName.accidental {
                // For double sharps/flats, use tighter kerning
                if accidental.count > 1 {
                    // Double sharp or double flat
                    Text(accidental)
                        .foregroundColor(color)
                        .font(.custom("Arial Unicode MS", size: adaptiveSize * 0.7))
                        .baselineOffset(adaptiveSize * 0.15)
                        .kerning(-adaptiveSize * 0.18) // Tight kerning for double accidentals
                } else {
                    // Single sharp or flat
                    Text(accidental)
                        .foregroundColor(color)
                        .font(.custom("Arial Unicode MS", size: adaptiveSize * 0.7))
                        .baselineOffset(adaptiveSize * 0.15)
                }
            }
        }
    }
}


/// Represents a musical note name with a letter and optional accidental
struct NoteName {
    let letter: String        // "A", "B", "C", etc.
    let accidental: String?   // "♯", "♭", "♯♯", "♭♭", or nil
    
    /// Plain text display of the note name
    var display: String {
        letter + (accidental ?? "")
    }
}





/// Determines what accidental is needed to spell a target semitone using a specific letter
func spell(semitone targetSemitone: Int, usingLetter letter: DiatonicLetter) -> NoteName {
    let natural = letter.naturalSemitoneOffset
    let difference = (targetSemitone - natural + 12) % 12
    
    let accidental: String?
    switch difference {
    case 0:  accidental = nil      // Natural
    case 1:  accidental = "♯"      // Sharp
    case 2:  accidental = "♯♯"     // Double sharp (rare)
    case 11: accidental = "♭"      // Flat (11 = -1 mod 12)
    case 10: accidental = "♭♭"     // Double flat (rare)
    default:
        // For extreme cases, fall back to multiple sharps
        // (In practice, well-formed scales shouldn't hit this)
        accidental = String(repeating: "♯", count: difference)
    }
    
    return NoteName(letter: letter.name, accidental: accidental)
}

/// Generates the note names for a scale in a given key
func noteNames(forScale scale: Scale, inKey root: MusicalKey) -> [NoteName] {
    let rootLetter = root.baseLetter
    
    return zip(scale.letterPattern, scale.semitonePattern).map { (letterStep, semitoneStep) in
        // Which diatonic letter to use for this note
        let targetLetter = rootLetter.advanced(by: letterStep)
        
        // Which chromatic pitch to hit
        let targetSemitone = (root.semitoneOffset + semitoneStep) % 12
        
        // Spell that pitch using that letter
        return spell(semitone: targetSemitone, usingLetter: targetLetter)
    }
}
