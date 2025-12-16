//
//  RotationTests.swift
//  Penta-Tone
//
//  Created by Xcode Assistant on 13/12/2025.
//
/*
import Testing
@testable import Penta_Tone

@Suite("Scale Rotation Tests")
struct RotationTests {
    
    // Center Meridian JI notes: [1, 9/8, 4/3, 3/2, 16/9]
    let baseScale = ScalesCatalog.centerMeridian_JI
    let baseFreq = 200.0
    
    @Test("Rotation 0 produces standard mapping")
    func testRotation0() async throws {
        var scale = baseScale
        scale.rotation = 0
        
        let frequencies = makeKeyFrequencies(for: scale, baseFrequency: baseFreq)
        
        // First 5 keys should be: 200, 225, 266.67, 300, 355.56
        #expect(abs(frequencies[0] - 200.0) < 0.1, "First key should be 1/1")
        #expect(abs(frequencies[1] - 225.0) < 0.1, "Second key should be 9/8")
        #expect(abs(frequencies[2] - 266.67) < 0.1, "Third key should be 4/3")
        #expect(abs(frequencies[3] - 300.0) < 0.1, "Fourth key should be 3/2")
        #expect(abs(frequencies[4] - 355.56) < 0.1, "Fifth key should be 16/9")
    }
    
    @Test("Rotation +1 shifts notes left")
    func testRotationPlus1() async throws {
        var scale = baseScale
        scale.rotation = 1
        
        let frequencies = makeKeyFrequencies(for: scale, baseFrequency: baseFreq)
        
        // With rotation +1: [9/8, 4/3, 3/2, 16/9, 1*2]
        // First 5 keys should be: 225, 266.67, 300, 355.56, 400
        #expect(abs(frequencies[0] - 225.0) < 0.1, "First key should be 9/8")
        #expect(abs(frequencies[1] - 266.67) < 0.1, "Second key should be 4/3")
        #expect(abs(frequencies[2] - 300.0) < 0.1, "Third key should be 3/2")
        #expect(abs(frequencies[3] - 355.56) < 0.1, "Fourth key should be 16/9")
        #expect(abs(frequencies[4] - 400.0) < 0.1, "Fifth key should be 1*2 (next octave)")
    }
    
    @Test("Rotation +2 shifts notes left by 2")
    func testRotationPlus2() async throws {
        var scale = baseScale
        scale.rotation = 2
        
        let frequencies = makeKeyFrequencies(for: scale, baseFrequency: baseFreq)
        
        // With rotation +2: [4/3, 3/2, 16/9, 1*2, 9/8*2]
        // First 5 keys should be: 266.67, 300, 355.56, 400, 450
        #expect(abs(frequencies[0] - 266.67) < 0.1, "First key should be 4/3")
        #expect(abs(frequencies[1] - 300.0) < 0.1, "Second key should be 3/2")
        #expect(abs(frequencies[2] - 355.56) < 0.1, "Third key should be 16/9")
        #expect(abs(frequencies[3] - 400.0) < 0.1, "Fourth key should be 1*2")
        #expect(abs(frequencies[4] - 450.0) < 0.1, "Fifth key should be 9/8*2")
    }
    
    @Test("Rotation -1 shifts notes right with octave down")
    func testRotationMinus1() async throws {
        var scale = baseScale
        scale.rotation = -1
        
        let frequencies = makeKeyFrequencies(for: scale, baseFrequency: baseFreq)
        
        // With rotation -1: [16/9 / 2, 1, 9/8, 4/3, 3/2]
        // 16/9 / 2 = 8/9 ≈ 0.889
        // First 5 keys should be: 177.78, 200, 225, 266.67, 300
        #expect(abs(frequencies[0] - 177.78) < 0.1, "First key should be 16/9 / 2")
        #expect(abs(frequencies[1] - 200.0) < 0.1, "Second key should be 1/1")
        #expect(abs(frequencies[2] - 225.0) < 0.1, "Third key should be 9/8")
        #expect(abs(frequencies[3] - 266.67) < 0.1, "Fourth key should be 4/3")
        #expect(abs(frequencies[4] - 300.0) < 0.1, "Fifth key should be 3/2")
    }
    
    @Test("Rotation -2 shifts notes right by 2 with octave down")
    func testRotationMinus2() async throws {
        var scale = baseScale
        scale.rotation = -2
        
        let frequencies = makeKeyFrequencies(for: scale, baseFrequency: baseFreq)
        
        // With rotation -2: [3/2 / 2, 16/9 / 2, 1, 9/8, 4/3]
        // 3/2 / 2 = 3/4 = 0.75
        // 16/9 / 2 = 8/9 ≈ 0.889
        // First 5 keys should be: 150, 177.78, 200, 225, 266.67
        #expect(abs(frequencies[0] - 150.0) < 0.1, "First key should be 3/2 / 2")
        #expect(abs(frequencies[1] - 177.78) < 0.1, "Second key should be 16/9 / 2")
        #expect(abs(frequencies[2] - 200.0) < 0.1, "Third key should be 1/1")
        #expect(abs(frequencies[3] - 225.0) < 0.1, "Fourth key should be 9/8")
        #expect(abs(frequencies[4] - 266.67) < 0.1, "Fifth key should be 4/3")
    }
    
    @Test("Octave relationships maintained across keyboard")
    func testOctaveRelationships() async throws {
        var scale = baseScale
        scale.rotation = 1
        
        let frequencies = makeKeyFrequencies(for: scale, baseFrequency: baseFreq)
        
        // Keys 0-4 (first octave) should be doubled in keys 5-9 (second octave)
        for i in 0..<5 {
            let firstOctave = frequencies[i]
            let secondOctave = frequencies[i + 5]
            #expect(abs(secondOctave - (firstOctave * 2.0)) < 0.1, 
                    "Second octave key \(i+5) should be double of first octave key \(i)")
        }
        
        // Keys 0-4 (first octave) should be quadrupled in keys 10-14 (third octave)
        for i in 0..<5 {
            let firstOctave = frequencies[i]
            let thirdOctave = frequencies[i + 10]
            #expect(abs(thirdOctave - (firstOctave * 4.0)) < 0.1, 
                    "Third octave key \(i+10) should be quadruple of first octave key \(i)")
        }
    }
}
*/
