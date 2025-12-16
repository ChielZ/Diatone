//
//  DynamicKeyColorTests.swift
//  Penta-Tone
//
//  Created by Xcode Assistant on 14/12/2025.
//
/*
import Testing
@testable import Penta_Tone

@Suite("Dynamic Key Color Tests")
struct DynamicKeyColorTests {
    
    /// Helper function that replicates the color calculation logic from MainKeyboardView
    private func keyColor(for keyIndex: Int, rotation: Int) -> String {
        let baseColorIndex = keyIndex % 5
        let rotatedColorIndex = (baseColorIndex + rotation + 5) % 5
        return "KeyColour\(rotatedColorIndex + 1)"
    }
    
    @Test("Rotation 0 produces standard color pattern")
    func testRotation0Colors() async throws {
        // With no rotation, keys should follow the base pattern: 1,2,3,4,5,1,2,3,4,5...
        #expect(keyColor(for: 0, rotation: 0) == "KeyColour1")
        #expect(keyColor(for: 1, rotation: 0) == "KeyColour2")
        #expect(keyColor(for: 2, rotation: 0) == "KeyColour3")
        #expect(keyColor(for: 3, rotation: 0) == "KeyColour4")
        #expect(keyColor(for: 4, rotation: 0) == "KeyColour5")
        
        // Second octave should repeat the pattern
        #expect(keyColor(for: 5, rotation: 0) == "KeyColour1")
        #expect(keyColor(for: 6, rotation: 0) == "KeyColour2")
        #expect(keyColor(for: 7, rotation: 0) == "KeyColour3")
        #expect(keyColor(for: 8, rotation: 0) == "KeyColour4")
        #expect(keyColor(for: 9, rotation: 0) == "KeyColour5")
        
        // Third octave
        #expect(keyColor(for: 10, rotation: 0) == "KeyColour1")
        #expect(keyColor(for: 11, rotation: 0) == "KeyColour2")
        #expect(keyColor(for: 12, rotation: 0) == "KeyColour3")
        #expect(keyColor(for: 13, rotation: 0) == "KeyColour4")
        #expect(keyColor(for: 14, rotation: 0) == "KeyColour5")
        
        // Fourth octave (partial)
        #expect(keyColor(for: 15, rotation: 0) == "KeyColour1")
        #expect(keyColor(for: 16, rotation: 0) == "KeyColour2")
        #expect(keyColor(for: 17, rotation: 0) == "KeyColour3")
    }
    
    @Test("Rotation +1 shifts colors to the left")
    func testRotationPlus1Colors() async throws {
        // With rotation +1, the colors should shift: 2,3,4,5,1,2,3,4,5,1...
        #expect(keyColor(for: 0, rotation: 1) == "KeyColour2")
        #expect(keyColor(for: 1, rotation: 1) == "KeyColour3")
        #expect(keyColor(for: 2, rotation: 1) == "KeyColour4")
        #expect(keyColor(for: 3, rotation: 1) == "KeyColour5")
        #expect(keyColor(for: 4, rotation: 1) == "KeyColour1")
        
        #expect(keyColor(for: 5, rotation: 1) == "KeyColour2")
        #expect(keyColor(for: 6, rotation: 1) == "KeyColour3")
        #expect(keyColor(for: 7, rotation: 1) == "KeyColour4")
        #expect(keyColor(for: 8, rotation: 1) == "KeyColour5")
        #expect(keyColor(for: 9, rotation: 1) == "KeyColour1")
    }
    
    @Test("Rotation +2 shifts colors by 2 positions to the left")
    func testRotationPlus2Colors() async throws {
        // With rotation +2, the colors should shift: 3,4,5,1,2,3,4,5,1,2...
        #expect(keyColor(for: 0, rotation: 2) == "KeyColour3")
        #expect(keyColor(for: 1, rotation: 2) == "KeyColour4")
        #expect(keyColor(for: 2, rotation: 2) == "KeyColour5")
        #expect(keyColor(for: 3, rotation: 2) == "KeyColour1")
        #expect(keyColor(for: 4, rotation: 2) == "KeyColour2")
        
        #expect(keyColor(for: 5, rotation: 2) == "KeyColour3")
        #expect(keyColor(for: 6, rotation: 2) == "KeyColour4")
    }
    
    @Test("Rotation -1 shifts colors to the right")
    func testRotationMinus1Colors() async throws {
        // With rotation -1, the colors should shift: 5,1,2,3,4,5,1,2,3,4...
        #expect(keyColor(for: 0, rotation: -1) == "KeyColour5")
        #expect(keyColor(for: 1, rotation: -1) == "KeyColour1")
        #expect(keyColor(for: 2, rotation: -1) == "KeyColour2")
        #expect(keyColor(for: 3, rotation: -1) == "KeyColour3")
        #expect(keyColor(for: 4, rotation: -1) == "KeyColour4")
        
        #expect(keyColor(for: 5, rotation: -1) == "KeyColour5")
        #expect(keyColor(for: 6, rotation: -1) == "KeyColour1")
    }
    
    @Test("Rotation -2 shifts colors by 2 positions to the right")
    func testRotationMinus2Colors() async throws {
        // With rotation -2, the colors should shift: 4,5,1,2,3,4,5,1,2,3...
        #expect(keyColor(for: 0, rotation: -2) == "KeyColour4")
        #expect(keyColor(for: 1, rotation: -2) == "KeyColour5")
        #expect(keyColor(for: 2, rotation: -2) == "KeyColour1")
        #expect(keyColor(for: 3, rotation: -2) == "KeyColour2")
        #expect(keyColor(for: 4, rotation: -2) == "KeyColour3")
        
        #expect(keyColor(for: 5, rotation: -2) == "KeyColour4")
        #expect(keyColor(for: 6, rotation: -2) == "KeyColour5")
    }
    
    @Test("Same color keys are 5 positions apart")
    func testColorSpacing() async throws {
        // Regardless of rotation, keys that are 5 positions apart should have the same color
        for rotation in -2...2 {
            for startKey in 0..<5 {
                let color1 = keyColor(for: startKey, rotation: rotation)
                let color2 = keyColor(for: startKey + 5, rotation: rotation)
                let color3 = keyColor(for: startKey + 10, rotation: rotation)
                
                #expect(color1 == color2, 
                        "Keys \(startKey) and \(startKey+5) should have same color with rotation \(rotation)")
                #expect(color1 == color3, 
                        "Keys \(startKey) and \(startKey+10) should have same color with rotation \(rotation)")
            }
        }
    }
    
    @Test("All five colors are used in first five keys")
    func testAllColorsPresent() async throws {
        for rotation in -2...2 {
            var colors = Set<String>()
            for keyIndex in 0..<5 {
                colors.insert(keyColor(for: keyIndex, rotation: rotation))
            }
            
            #expect(colors.count == 5, 
                    "All 5 colors should be present in first 5 keys with rotation \(rotation)")
            #expect(colors.contains("KeyColour1"))
            #expect(colors.contains("KeyColour2"))
            #expect(colors.contains("KeyColour3"))
            #expect(colors.contains("KeyColour4"))
            #expect(colors.contains("KeyColour5"))
        }
    }
    
    @Test("Color shift matches note rotation direction")
    func testColorRotationConsistency() async throws {
        // When rotation increases (+1), the first key should get the color that was previously on key 1
        let key0_rotation0 = keyColor(for: 0, rotation: 0)  // KeyColour1
        let key1_rotation0 = keyColor(for: 1, rotation: 0)  // KeyColour2
        let key0_rotation1 = keyColor(for: 0, rotation: 1)  // Should be KeyColour2
        
        #expect(key1_rotation0 == key0_rotation1, 
                "Positive rotation should shift colors from higher keys to lower keys")
        
        // When rotation decreases (-1), the first key should get the color that was previously on key 4
        let key4_rotation0 = keyColor(for: 4, rotation: 0)   // KeyColour5
        let key0_rotationMinus1 = keyColor(for: 0, rotation: -1)  // Should be KeyColour5
        
        #expect(key4_rotation0 == key0_rotationMinus1,
                "Negative rotation should shift colors from lower keys to higher keys")
    }
}
*/
