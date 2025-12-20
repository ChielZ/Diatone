//
//  NoteSpellingTests.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 20/12/2025.
//
/*
import Testing
@testable import Penta_Tone

@Suite("Note Spelling Algorithm Tests")
struct NoteSpellingTests {
    
    @Test("Center Meridian in D produces D, E, G, A, C")
    func testCenterMeridianInD() async throws {
        let scale = ScalesCatalog.centerMeridian_JI
        let names = noteNames(forScale: scale, inKey: .D)
        
        #expect(names[0].display == "D", "First note should be D")
        #expect(names[1].display == "E", "Second note should be E")
        #expect(names[2].display == "G", "Third note should be G")
        #expect(names[3].display == "A", "Fourth note should be A")
        #expect(names[4].display == "C", "Fifth note should be C")
    }
    
    @Test("Center Meridian in A♭ produces A♭, B♭, D♭, E♭, G♭")
    func testCenterMeridianInAFlat() async throws {
        let scale = ScalesCatalog.centerMeridian_JI
        let names = noteNames(forScale: scale, inKey: .Ab)
        
        #expect(names[0].display == "A♭", "First note should be A♭")
        #expect(names[1].display == "B♭", "Second note should be B♭")
        #expect(names[2].display == "D♭", "Third note should be D♭")
        #expect(names[3].display == "E♭", "Fourth note should be E♭")
        #expect(names[4].display == "G♭", "Fifth note should be G♭")
    }
    
    @Test("Center Orient in D produces D, F♯, G, A, B♭")
    func testCenterOrientInD() async throws {
        let scale = ScalesCatalog.centerOrient_JI
        let names = noteNames(forScale: scale, inKey: .D)
        
        #expect(names[0].display == "D", "First note should be D")
        #expect(names[1].display == "F♯", "Second note should be F♯")
        #expect(names[2].display == "G", "Third note should be G")
        #expect(names[3].display == "A", "Fourth note should be A")
        #expect(names[4].display == "B♭", "Fifth note should be B♭")
    }
    
    @Test("Center Orient in G♯ produces G♯, B♯, C♯, D♯, E")
    func testCenterOrientInGSharp() async throws {
        let scale = ScalesCatalog.centerOrient_JI
        let names = noteNames(forScale: scale, inKey: .Gs)
        
        #expect(names[0].display == "G♯", "First note should be G♯")
        #expect(names[1].display == "B♯", "Second note should be B♯")
        #expect(names[2].display == "C♯", "Third note should be C♯")
        #expect(names[3].display == "D♯", "Fourth note should be D♯")
        #expect(names[4].display == "E", "Fifth note should be E")
    }
    
    @Test("Moon Occident in D produces D, F, G, A, C")
    func testMoonOccidentInD() async throws {
        let scale = ScalesCatalog.moonOccident_JI
        let names = noteNames(forScale: scale, inKey: .D)
        
        #expect(names[0].display == "D", "First note should be D")
        #expect(names[1].display == "F", "Second note should be F")
        #expect(names[2].display == "G", "Third note should be G")
        #expect(names[3].display == "A", "Fourth note should be A")
        #expect(names[4].display == "C", "Fifth note should be C")
    }
    
    @Test("Center Occident in D produces D, F, G, A, B")
    func testCenterOccidentInD() async throws {
        let scale = ScalesCatalog.centerOccident_JI
        let names = noteNames(forScale: scale, inKey: .D)
        
        #expect(names[0].display == "D", "First note should be D")
        #expect(names[1].display == "F", "Second note should be F")
        #expect(names[2].display == "G", "Third note should be G")
        #expect(names[3].display == "A", "Fourth note should be A")
        #expect(names[4].display == "B", "Fifth note should be B")
    }
    
    @Test("Moon Occident in A produces A, C, D, E, G")
    func testMoonOccidentInA() async throws {
        let scale = ScalesCatalog.moonOccident_JI
        let names = noteNames(forScale: scale, inKey: .A)
        
        #expect(names[0].display == "A", "First note should be A")
        #expect(names[1].display == "C", "Second note should be C (not B♯)")
        #expect(names[2].display == "D", "Third note should be D")
        #expect(names[3].display == "E", "Fourth note should be E")
        #expect(names[4].display == "G", "Fifth note should be G")
    }
    
    @Test("Center Occident in A produces A, C, D, E, F♯")
    func testCenterOccidentInA() async throws {
        let scale = ScalesCatalog.centerOccident_JI
        let names = noteNames(forScale: scale, inKey: .A)
        
        #expect(names[0].display == "A", "First note should be A")
        #expect(names[1].display == "C", "Second note should be C (not B♯)")
        #expect(names[2].display == "D", "Third note should be D")
        #expect(names[3].display == "E", "Fourth note should be E")
        #expect(names[4].display == "F♯", "Fifth note should be F♯")
    }
    
    @Test("Equal temperament produces same note names as JI")
    func testETandJISameName() async throws {
        let scaleJI = ScalesCatalog.centerMeridian_JI
        let scaleET = ScalesCatalog.centerMeridian_ET
        
        let namesJI = noteNames(forScale: scaleJI, inKey: .D)
        let namesET = noteNames(forScale: scaleET, inKey: .D)
        
        for i in 0..<5 {
            #expect(namesJI[i].display == namesET[i].display, 
                    "JI and ET should produce same note names at index \(i)")
        }
    }
    
    @Test("DiatonicLetter advanced works correctly")
    func testDiatonicLetterAdvanced() async throws {
        let c = DiatonicLetter.c
        
        #expect(c.advanced(by: 0) == .c)
        #expect(c.advanced(by: 1) == .d)
        #expect(c.advanced(by: 2) == .e)
        #expect(c.advanced(by: 7) == .c, "Should wrap around")
        #expect(c.advanced(by: 8) == .d, "Should wrap around")
    }
    
    @Test("Spelling algorithm handles sharps correctly")
    func testSpellingSharps() async throws {
        // C natural is semitone 0, but we want semitone 1
        let result = spell(semitone: 1, usingLetter: .c)
        #expect(result.display == "C♯", "Should produce C♯")
        
        // F natural is semitone 5, but we want semitone 6
        let result2 = spell(semitone: 6, usingLetter: .f)
        #expect(result2.display == "F♯", "Should produce F♯")
    }
    
    @Test("Spelling algorithm handles flats correctly")
    func testSpellingFlats() async throws {
        // B natural is semitone 11, but we want semitone 10
        let result = spell(semitone: 10, usingLetter: .b)
        #expect(result.display == "B♭", "Should produce B♭")
        
        // A natural is semitone 9, but we want semitone 8
        let result2 = spell(semitone: 8, usingLetter: .a)
        #expect(result2.display == "A♭", "Should produce A♭")
    }
}
*/
