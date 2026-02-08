//
//  ScaleNavigationManager.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 05/01/2026.
//

import Foundation
import Combine

/// Manages navigation through scales, musical keys, and related properties
/// Handles all cycling logic for scale selection, rotation, and key transposition
@MainActor
final class ScaleNavigationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The current scale index in the catalog
    @Published private(set) var currentScaleIndex: Int {
        didSet {
            updateLastSelectedInGroup()
            notifyScaleChanged()
        }
    }
    
    /// The current rotation offset (-2 to +2)
    @Published private(set) var rotation: Int = 0 {
        didSet {
            notifyScaleChanged()
        }
    }
    
    /// The current musical key for transposition
    @Published private(set) var musicalKey: MusicalKey {
        didSet {
            notifyKeyChanged()
        }
    }
    
    // MARK: - Last Selected Scale Memory
    
    /// Stores the last selected celestial property for each terrestrial group
    /// Key: (Intonation, Terrestrial) -> Celestial
    private var lastSelectedCelestial: [CombinedKey: Celestial] = [:]
    
    /// Stores the last selected terrestrial property for each celestial property
    /// Key: (Intonation, Celestial) -> Terrestrial
    private var lastSelectedTerrestrial: [CombinedKey: Terrestrial] = [:]
    
    /// Helper struct for dictionary keys combining intonation and property
    private struct CombinedKey: Hashable {
        let intonation: Intonation
        let property: String // celestial or terrestrial raw value
        
        init(_ intonation: Intonation, _ celestial: Celestial) {
            self.intonation = intonation
            self.property = celestial.rawValue
        }
        
        init(_ intonation: Intonation, _ terrestrial: Terrestrial) {
            self.intonation = intonation
            self.property = terrestrial.rawValue
        }
    }
    
    // MARK: - Computed Properties
    
    /// The current scale with rotation applied
    var currentScale: Scale {
        var scale = ScalesCatalog.all[currentScaleIndex]
        scale.rotation = rotation
        return scale
    }
    
    /// The base scale without rotation
    var baseScale: Scale {
        ScalesCatalog.all[currentScaleIndex]
    }
    
    // MARK: - Callbacks
    
    /// Called whenever the scale or rotation changes
    var onScaleChanged: ((Scale) -> Void)?
    
    /// Called whenever the musical key changes
    var onKeyChanged: ((MusicalKey) -> Void)?
    
    // MARK: - Initialization
    
    /// Creates a scale navigation manager
    /// - Parameters:
    ///   - initialScale: The initial scale to select (defaults to Center Meridian JI)
    ///   - initialKey: The initial musical key (defaults to D)
    init(initialScale: Scale? = nil, initialKey: MusicalKey = .D) {
        // Find the index of the initial scale
        let targetScale = initialScale ?? ScalesCatalog.Dorian_JI_E
        if let index = ScalesCatalog.all.firstIndex(where: { $0 == targetScale }) {
            self.currentScaleIndex = index
        } else {
            self.currentScaleIndex = 0
        }
        
        self.musicalKey = initialKey
        
        // Initialize memory with the initial scale
        updateLastSelectedInGroup()
    }
    
    // MARK: - Direct Scale Navigation
    
    /// Moves to the next scale in the catalog (does not wrap)
    func incrementScale() {
        guard currentScaleIndex < ScalesCatalog.all.count - 1 else { return }
        currentScaleIndex += 1
    }
    
    /// Moves to the previous scale in the catalog (does not wrap)
    func decrementScale() {
        guard currentScaleIndex > 0 else { return }
        currentScaleIndex -= 1
    }
    
    /// Sets the current scale directly
    /// - Parameter scale: The scale to select
    func setScale(_ scale: Scale) {
        if let index = ScalesCatalog.all.firstIndex(where: { $0 == scale }) {
            currentScaleIndex = index
            rotation = scale.rotation
        }
    }
    
    /// Sets the current scale by index
    /// - Parameter index: The index in the catalog
    func setScaleIndex(_ index: Int) {
        guard (0..<ScalesCatalog.all.count).contains(index) else { return }
        currentScaleIndex = index
    }
    
    // MARK: - Property-Based Navigation
    
    /// Cycles between JI and ET intonation
    /// Keeps the same celestial and terrestrial properties
    /// Wraps around: JI ↔ ET
    /// - Parameter forward: Direction (same effect for binary toggle)
    func cycleIntonation(forward: Bool = true) {
        let current = baseScale
        let targetIntonation: Intonation = (current.intonation == .ji) ? .et : .ji
        
        if let newScale = ScalesCatalog.find(
            intonation: targetIntonation,
            celestial: current.celestial,
            terrestrial: current.terrestrial
        ),
           let newIndex = ScalesCatalog.all.firstIndex(where: { $0 == newScale }) {
            currentScaleIndex = newIndex
        }
    }
    
    /// Cycles through celestial properties within the current terrestrial group
    /// For Modal (7 scales): Locrian ↔ Phrygian ↔ Aeolian ↔ Dorian ↔ Mixolydian ↔ Ionian ↔ Lydian
    /// For Melodic (2 scales): Minor ↔ Major
    /// For Harmonic (3 scales): Minor ↔ Major ↔ Double
    /// Does NOT wrap around (stops at ends)
    /// - Parameter forward: true to move forward, false to move backward
    func cycleCelestial(forward: Bool) {
        let current = baseScale
        
        // Get valid celestial options for current terrestrial group
        let validCelestials = getValidCelestialsFor(terrestrial: current.terrestrial)
        guard let currentIdx = validCelestials.firstIndex(of: current.celestial) else { return }
        
        // Calculate next index without wrapping
        let nextIdx: Int
        if forward {
            nextIdx = currentIdx + 1
            guard nextIdx < validCelestials.count else { return } // Stop at end
        } else {
            nextIdx = currentIdx - 1
            guard nextIdx >= 0 else { return } // Stop at beginning
        }
        
        let targetCelestial = validCelestials[nextIdx]
        
        if let newScale = ScalesCatalog.find(
            intonation: current.intonation,
            celestial: targetCelestial,
            terrestrial: current.terrestrial
        ),
           let newIndex = ScalesCatalog.all.firstIndex(where: { $0 == newScale }) {
            currentScaleIndex = newIndex
        }
    }
    
    /// Cycles through terrestrial properties: Modal ↔ Melodic ↔ Harmonic
    /// When switching groups, loads the last selected celestial property for that group
    /// Does NOT wrap around (stops at ends)
    /// - Parameter forward: true to move forward, false to move backward
    func cycleTerrestrial(forward: Bool) {
        let current = baseScale
        let allCases = Terrestrial.allCases.filter { $0 == .modal || $0 == .melodic || $0 == .harmonic }
        guard let currentIdx = allCases.firstIndex(of: current.terrestrial) else { return }
        
        // Calculate next index without wrapping
        let nextIdx: Int
        if forward {
            nextIdx = currentIdx + 1
            guard nextIdx < allCases.count else { return } // Stop at end
        } else {
            nextIdx = currentIdx - 1
            guard nextIdx >= 0 else { return } // Stop at beginning
        }
        
        let targetTerrestrial = allCases[nextIdx]
        
        // Try to load the last selected celestial for this terrestrial group
        let key = CombinedKey(current.intonation, targetTerrestrial)
        let targetCelestial: Celestial
        
        if let remembered = lastSelectedCelestial[key] {
            // Use remembered celestial if available
            targetCelestial = remembered
        } else {
            // Otherwise, use the first valid celestial for this group
            let validCelestials = getValidCelestialsFor(terrestrial: targetTerrestrial)
            targetCelestial = validCelestials.first ?? .dorian
        }
        
        if let newScale = ScalesCatalog.find(
            intonation: current.intonation,
            celestial: targetCelestial,
            terrestrial: targetTerrestrial
        ),
           let newIndex = ScalesCatalog.all.firstIndex(where: { $0 == newScale }) {
            currentScaleIndex = newIndex
        }
    }
    
    // MARK: - Helper Methods for Valid Options
    
    /// Returns the valid celestial options for a given terrestrial group
    private func getValidCelestialsFor(terrestrial: Terrestrial) -> [Celestial] {
        switch terrestrial {
        case .modal:
            return [.locrian, .phrygian, .aeolian, .dorian, .mixolydian, .ionian, .lydian]
        case .melodic:
            return [.minor, .pythagorean, .major]
        case .harmonic:
            return [.minor, .double, .major]
        default:
            return []
        }
    }
    
    /// Updates the memory dictionaries to remember the current selection
    private func updateLastSelectedInGroup() {
        let current = baseScale
        
        // Remember which celestial was selected for this (intonation, terrestrial) combo
        let celestialKey = CombinedKey(current.intonation, current.terrestrial)
        lastSelectedCelestial[celestialKey] = current.celestial
        
        // Remember which terrestrial was selected for this (intonation, celestial) combo
        let terrestrialKey = CombinedKey(current.intonation, current.celestial)
        lastSelectedTerrestrial[terrestrialKey] = current.terrestrial
    }
    
    // MARK: - Rotation Management
    
    /// Cycles rotation: -2 ↔ -1 ↔ 0 ↔ +1 ↔ +2
    /// Does NOT wrap around (stops at ends)
    /// - Parameter forward: true to rotate forward (+), false to rotate backward (-)
    func cycleRotation(forward: Bool) {
        let newRotation = forward ? rotation + 1 : rotation - 1
        
        // Clamp to range [-3, 3]
        guard newRotation >= -3 && newRotation <= 3 else { return }
        
        rotation = newRotation
    }
    
    /// Sets the rotation directly
    /// - Parameter value: The rotation offset (-3 to +3)
    func setRotation(_ value: Int) {
        let clamped = max(-3, min(3, value))
        rotation = clamped
    }
    
    /// Resets rotation to 0
    func resetRotation() {
        rotation = 0
    }
    
    // MARK: - Key (Transposition) Management
    
    /// Cycles through musical keys
    /// Order: Ab → Eb → Bb → F → C → G → D → A → E → B → F♯ → C♯ → G♯
    /// Does NOT wrap around (stops at ends)
    /// - Parameter forward: true to move right, false to move left
    func cycleKey(forward: Bool) {
        let allCases = MusicalKey.allCases
        guard let currentIdx = allCases.firstIndex(of: musicalKey) else { return }
        
        // Calculate next index without wrapping
        let nextIdx: Int
        if forward {
            nextIdx = currentIdx + 1
            guard nextIdx < allCases.count else { return } // Stop at end
        } else {
            nextIdx = currentIdx - 1
            guard nextIdx >= 0 else { return } // Stop at beginning
        }
        
        musicalKey = allCases[nextIdx]
    }
    
    /// Sets the musical key directly
    /// - Parameter key: The key to select
    func setKey(_ key: MusicalKey) {
        musicalKey = key
    }
    
    /// Resets the key to D (center key)
    func resetKey() {
        musicalKey = .D
    }
    
    // MARK: - Convenience Methods
    
    /// Resets to default state: Center Meridian JI, key D, rotation 0
    func resetToDefaults() {
        let target = ScalesCatalog.Dorian_JI_E
        if let idx = ScalesCatalog.all.firstIndex(where: { $0 == target }) {
            currentScaleIndex = idx
        }
        rotation = 0
        musicalKey = .D
    }
    
    /// Returns true if at the beginning of the scale catalog
    var isAtFirstScale: Bool {
        currentScaleIndex == 0
    }
    
    /// Returns true if at the end of the scale catalog
    var isAtLastScale: Bool {
        currentScaleIndex == ScalesCatalog.all.count - 1
    }
    
    /// Returns true if rotation is at minimum (-3)
    var isAtMinRotation: Bool {
        rotation == -3
    }
    
    /// Returns true if rotation is at maximum (+3)
    var isAtMaxRotation: Bool {
        rotation == 3
    }
    
    /// Returns true if key is at the beginning of the key list (Ab)
    var isAtFirstKey: Bool {
        musicalKey == MusicalKey.allCases.first
    }
    
    /// Returns true if key is at the end of the key list (G#)
    var isAtLastKey: Bool {
        musicalKey == MusicalKey.allCases.last
    }
    
    // MARK: - Private Helpers
    
    private func notifyScaleChanged() {
        onScaleChanged?(currentScale)
    }
    
    private func notifyKeyChanged() {
        onKeyChanged?(musicalKey)
    }
    
    // MARK: - Diagnostics
    
    /// Prints current navigation state for debugging
    func printState() {
        print("🧭 Scale Navigation State:")
        print("   Scale Index: \(currentScaleIndex) of \(ScalesCatalog.all.count)")
        print("   Scale: \(currentScale.name)")
        print("   Rotation: \(rotation)")
        print("   Key: \(musicalKey.rawValue)")
        print("   Properties: \(baseScale.intonation.rawValue) / \(baseScale.celestial.rawValue) / \(baseScale.terrestrial.rawValue)")
        print("   Memory - Last Selected Celestials:")
        for (key, value) in lastSelectedCelestial.sorted(by: { $0.key.property < $1.key.property }) {
            print("      \(key.intonation.rawValue) + \(key.property) → \(value.rawValue)")
        }
        print("   Memory - Last Selected Terrestrials:")
        for (key, value) in lastSelectedTerrestrial.sorted(by: { $0.key.property < $1.key.property }) {
            print("      \(key.intonation.rawValue) + \(key.property) → \(value.rawValue)")
        }
    }
}
