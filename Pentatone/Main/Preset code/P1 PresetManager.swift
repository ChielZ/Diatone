//
//  P1 PresetManager.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 07/01/2026.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Preset Manager

/// Central manager for loading, saving, and organizing presets
/// Handles both factory (bundled) and user (Documents) presets
@MainActor
final class PresetManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = PresetManager()
    
    // MARK: - Published Properties
    
    /// All factory presets (read-only, bundled with app)
    @Published private(set) var factoryPresets: [AudioParameterSet] = []
    
    /// All user presets (read-write, saved to Documents)
    @Published private(set) var userPresets: [AudioParameterSet] = []
    
    /// Currently loaded preset (if any)
    @Published private(set) var currentPreset: AudioParameterSet?
    
    /// Loading state
    @Published private(set) var isLoading: Bool = false
    
    // MARK: - Slot Management Properties
    
    /// User preset layout (U1.1 - U5.5)
    /// This is saved to disk and persists across app launches
    @Published var userLayout: PentatoneUserLayout = .default
    
    /// Factory preset layout (F1.1 - F5.5)
    /// This is hardcoded and read-only
    var factoryLayout: [PentatonePresetSlot] {
        return PentatoneFactoryLayout.factorySlots
    }
    
    /// User layout file location
    private var userLayoutURL: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent("UserPresets/UserLayout.json")
    }
    
    // MARK: - Private Properties
    
    /// Fast lookup: UUID → Preset
    private var presetLookup: [UUID: AudioParameterSet] = [:]
    
    /// File manager for file operations
    private let fileManager = FileManager.default
    
    // MARK: - File Paths
    
    /// Factory presets directory (in app bundle)
    private var factoryPresetsURL: URL? {
        // Try multiple paths to support different folder structures
        if let url = Bundle.main.url(forResource: "Resources/presets/factory", withExtension: nil) {
            return url
        }
        if let url = Bundle.main.url(forResource: "Resources/Presets/Factory", withExtension: nil) {
            return url
        }
        if let url = Bundle.main.url(forResource: "Presets", withExtension: nil) {
            return url.appendingPathComponent("Factory")
        }
        return nil
    }
    
    /// User presets directory (in Documents)
    private var userPresetsURL: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent("UserPresets")
    }
    
    // MARK: - Initialization
    
    private init() {
        // Private to enforce singleton
        // Call loadAllPresets() from app initialization
    }
    
    // MARK: - Loading Presets
    
    /// Load all presets (factory + user)
    /// Call this once during app launch
    func loadAllPresets() {
        Task { @MainActor in
            isLoading = true
            
            loadFactoryPresets()
            loadUserPresets()
            
            isLoading = false
            
            print("✅ PresetManager: Loaded \(factoryPresets.count) factory presets and \(userPresets.count) user presets")
        }
    }
    
    /// Load factory presets from app bundle
    private func loadFactoryPresets() {
        guard let factoryURL = factoryPresetsURL else {
            print("⚠️ PresetManager: Factory presets directory not found in bundle")
            return
        }
        
        // Check if directory exists
        guard fileManager.fileExists(atPath: factoryURL.path) else {
            print("⚠️ PresetManager: Factory presets directory does not exist at \(factoryURL.path)")
            return
        }
        
        do {
            // Get all .json files in factory directory
            let fileURLs = try fileManager.contentsOfDirectory(
                at: factoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "json" }
            
            // Load each preset file
            for fileURL in fileURLs {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let preset = try decoder.decode(AudioParameterSet.self, from: data)
                    
                    // Add to collections
                    factoryPresets.append(preset)
                    presetLookup[preset.id] = preset
                    
                    print("✅ Loaded factory preset: \(preset.name) (ID: \(preset.id.uuidString))")
                } catch {
                    print("⚠️ Failed to load factory preset from \(fileURL.lastPathComponent): \(error)")
                }
            }
            
            // Sort factory presets by name for consistent ordering
            factoryPresets.sort { $0.name < $1.name }
            
        } catch {
            print("⚠️ PresetManager: Failed to read factory presets directory: \(error)")
        }
    }
    
    /// Load user presets from Documents directory
    private func loadUserPresets() {
        // Create UserPresets directory if it doesn't exist
        if !fileManager.fileExists(atPath: userPresetsURL.path) {
            do {
                try fileManager.createDirectory(at: userPresetsURL, withIntermediateDirectories: true)
                print("✅ PresetManager: Created UserPresets directory at \(userPresetsURL.path)")
            } catch {
                print("⚠️ PresetManager: Failed to create UserPresets directory: \(error)")
                return
            }
        }
        
        do {
            // Get all .json files in user directory, excluding UserLayout.json
            let fileURLs = try fileManager.contentsOfDirectory(
                at: userPresetsURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ).filter { 
                $0.pathExtension == "json" && 
                $0.lastPathComponent != "UserLayout.json" 
            }
            
            // Load each preset file
            for fileURL in fileURLs {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let preset = try decoder.decode(AudioParameterSet.self, from: data)
                    
                    // Add to collections
                    userPresets.append(preset)
                    presetLookup[preset.id] = preset
                    
                    print("✅ Loaded user preset: \(preset.name) (ID: \(preset.id.uuidString))")
                } catch {
                    print("⚠️ Failed to load user preset from \(fileURL.lastPathComponent): \(error)")
                }
            }
            
            // Sort user presets by creation date (newest first)
            userPresets.sort { $0.createdAt > $1.createdAt }
            
        } catch {
            print("⚠️ PresetManager: Failed to read user presets directory: \(error)")
        }
    }
    
    // MARK: - Preset Lookup
    
    /// Get preset by UUID (from either factory or user presets)
    func preset(withID id: UUID) -> AudioParameterSet? {
        return presetLookup[id]
    }
    
    /// Check if a preset exists
    func presetExists(withID id: UUID) -> Bool {
        return presetLookup[id] != nil
    }
    
    // MARK: - Saving Presets
    
    /// Save a new preset or update an existing user preset
    /// - Parameter preset: The preset to save
    /// - Throws: File system errors
    func savePreset(_ preset: AudioParameterSet) throws {
        // Ensure UserPresets directory exists
        if !fileManager.fileExists(atPath: userPresetsURL.path) {
            try fileManager.createDirectory(at: userPresetsURL, withIntermediateDirectories: true)
        }
        
        // Encode preset to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(preset)
        
        // Save to file (UUID-based filename)
        let filename = "\(preset.id.uuidString).json"
        let fileURL = userPresetsURL.appendingPathComponent(filename)
        try data.write(to: fileURL)
        
        // Update lookup
        presetLookup[preset.id] = preset
        
        // Update userPresets array
        if let index = userPresets.firstIndex(where: { $0.id == preset.id }) {
            // Update existing preset
            userPresets[index] = preset
        } else {
            // Add new preset (insert at beginning for "newest first" order)
            userPresets.insert(preset, at: 0)
        }
        
        print("✅ PresetManager: Saved user preset '\(preset.name)' (ID: \(preset.id.uuidString))")
    }
    
    /// Save current parameters as a new preset
    /// - Parameter name: Name for the new preset
    /// - Returns: The newly created preset
    /// - Throws: File system errors
    @discardableResult
    func saveCurrentAsNewPreset(name: String) throws -> AudioParameterSet {
        let paramManager = AudioParameterManager.shared
        
        // IMPORTANT: Capture current parameter values as new base values
        // This "bakes in" any macro adjustments and resets macro positions to center
        // Result: When preset loads, macros are at neutral and ready for performance control
        paramManager.captureCurrentAsBase()
        
        // Create new preset from current parameters
        // Macro positions are now at 0.0 (center), base values contain final adjusted values
        let newPreset = AudioParameterSet(
            id: UUID(),
            name: name,
            voiceTemplate: paramManager.voiceTemplate,
            master: paramManager.master,
            macroState: paramManager.macroState,
            createdAt: Date()
        )
        
        // Save to disk
        try savePreset(newPreset)
        
        // Set as current preset
        currentPreset = newPreset
        
        return newPreset
    }
    
    // MARK: - Deleting Presets
    
    /// Delete a user preset
    /// - Parameter preset: The preset to delete (must be a user preset)
    /// - Throws: File system errors
    func deletePreset(_ preset: AudioParameterSet) throws {
        // Safety check: ensure it's a user preset (not factory)
        guard userPresets.contains(where: { $0.id == preset.id }) else {
            throw PresetError.cannotDeleteFactoryPreset
        }
        
        // Remove file from disk
        let filename = "\(preset.id.uuidString).json"
        let fileURL = userPresetsURL.appendingPathComponent(filename)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        
        // Remove from lookup and array
        presetLookup.removeValue(forKey: preset.id)
        userPresets.removeAll(where: { $0.id == preset.id })
        
        // Clear current preset if it was deleted
        if currentPreset?.id == preset.id {
            currentPreset = nil
        }
        
        print("✅ PresetManager: Deleted user preset '\(preset.name)' (ID: \(preset.id.uuidString))")
    }
    
    // MARK: - Loading Presets (Apply to Engine)
    
    /// Load a preset and apply it to the audio engine
    /// - Parameter preset: The preset to load
    func loadPreset(_ preset: AudioParameterSet) {
        let paramManager = AudioParameterManager.shared
        
        // IMPORTANT: Preset parameters are already at their FINAL values
        // (base values + macro adjustments have already been calculated and saved)
        // We should NOT recalculate them!
        
        // Step 1: Apply macro state FIRST
        // This sets the base values and positions for future macro adjustments
        paramManager.macroState = preset.macroState
        
        // Step 2: Apply voice template
        // This includes all oscillator, filter, envelope, modulation params at their final values
        paramManager.voiceTemplate = preset.voiceTemplate
        
        // Step 3: Apply master parameters
        // This includes tempo, delays, reverb, output, globalLFO, etc. at their final values
        paramManager.master = preset.master
        
        // Step 4: Apply all parameters to audio engine nodes
        // These functions transfer the parameter values to the actual audio processing nodes
        paramManager.applyVoiceParameters(preset.voiceTemplate)
        paramManager.applyMasterParameters(preset.master)
        
        // NOTE: We do NOT call updateVolumeMacro/Tone/Ambience here!
        // The preset already contains final parameter values.
        // Calling those functions would recalculate and potentially change values.
        // The macro positions are already stored in macroState for future adjustments.
        
        // Set as current preset
        currentPreset = preset
        
        print("✅ PresetManager: Loaded preset '\(preset.name)'")
    }
    
    /// Load preset by ID
    /// - Parameter id: UUID of the preset to load
    func loadPreset(withID id: UUID) {
        guard let preset = preset(withID: id) else {
            print("⚠️ PresetManager: Preset with ID \(id.uuidString) not found")
            return
        }
        loadPreset(preset)
    }
    
    // MARK: - Export/Import (Share)
    
    /// Export a preset to a temporary file for sharing
    /// - Parameter preset: The preset to export
    /// - Returns: URL of the temporary file
    /// - Throws: Encoding or file system errors
    func exportPreset(_ preset: AudioParameterSet) throws -> URL {
        // Encode preset
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(preset)
        
        // Create temporary file with .arithmophonepreset extension
        let tempDir = fileManager.temporaryDirectory
        let filename = "\(preset.name).arithmophonepreset"
        let tempURL = tempDir.appendingPathComponent(filename)
        
        // Write to temporary file
        try data.write(to: tempURL)
        
        print("✅ PresetManager: Exported preset '\(preset.name)' to \(tempURL.path)")
        
        return tempURL
    }
    
    /// Import a preset from a file (e.g., shared from another device)
    /// - Parameter url: URL of the preset file to import
    /// - Returns: The imported preset
    /// - Throws: Decoding or file system errors
    @discardableResult
    func importPreset(from url: URL) throws -> AudioParameterSet {
        // Read and decode preset
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var preset = try decoder.decode(AudioParameterSet.self, from: data)
        
        // Check if preset with same ID already exists
        if presetExists(withID: preset.id) {
            // Generate new ID to avoid conflicts
            let oldID = preset.id
            let newID = UUID()
            
            // Create new preset with updated ID and name
            preset = AudioParameterSet(
                id: newID,
                name: "\(preset.name) (Imported)",
                voiceTemplate: preset.voiceTemplate,
                master: preset.master,
                macroState: preset.macroState,
                createdAt: Date()
            )
            
            print("⚠️ PresetManager: Preset ID conflict (\(oldID.uuidString)), assigned new ID: \(newID.uuidString)")
        }
        
        // Save to user presets
        try savePreset(preset)
        
        print("✅ PresetManager: Imported preset '\(preset.name)'")
        
        return preset
    }
    
    // MARK: - Preset Count Helpers
    
    /// Total number of factory presets
    var factoryPresetCount: Int {
        return factoryPresets.count
    }
    
    /// Total number of user presets
    var userPresetCount: Int {
        return userPresets.count
    }
    
    /// Total number of all presets
    var totalPresetCount: Int {
        return factoryPresetCount + userPresetCount
    }
    
    /// Check if user preset storage is full (75 slots for Pentatone)
    var userPresetsAreFull: Bool {
        return userPresetCount >= 75
    }
    
    /// Number of available user preset slots remaining
    var availableUserSlots: Int {
        return max(0, 75 - userPresetCount)
    }
    
    // MARK: - Slot Management
    
    /// Load user layout from disk
    /// Call this after loadAllPresets() during app initialization
    func loadUserLayout() {
        // Check if layout file exists
        guard fileManager.fileExists(atPath: userLayoutURL.path) else {
            print("ℹ️ PresetManager: No saved user layout found, using default")
            userLayout = .default
            return
        }
        
        do {
            let data = try Data(contentsOf: userLayoutURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            userLayout = try decoder.decode(PentatoneUserLayout.self, from: data)
            
            print("✅ PresetManager: Loaded user layout (\(userLayout.assignedCount) slots assigned)")
        } catch {
            print("⚠️ PresetManager: Failed to load user layout, using default: \(error)")
            userLayout = .default
        }
    }
    
    /// Save user layout to disk
    func saveUserLayout() throws {
        // Ensure directory exists
        let directoryURL = userLayoutURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        
        // Encode and save
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(userLayout)
        try data.write(to: userLayoutURL)
        
        print("✅ PresetManager: Saved user layout (\(userLayout.assignedCount) slots assigned)")
    }
    
    /// Get preset for a specific slot
    /// - Parameters:
    ///   - bank: Bank number (1-5)
    ///   - position: Position within bank (1-5)
    ///   - type: Factory or user slot
    /// - Returns: The preset assigned to this slot, or nil if empty/not found
    func preset(forBank bank: Int, position: Int, type: PentatonePresetSlot.SlotType) -> AudioParameterSet? {
        // Get the slot
        let slot: PentatonePresetSlot?
        if type == .factory {
            slot = PentatoneFactoryLayout.slot(bank: bank, position: position)
        } else {
            slot = userLayout.slot(bank: bank, position: position)
        }
        
        // Get preset ID from slot
        guard let presetID = slot?.presetID else {
            return nil
        }
        
        // Lookup preset by ID
        return preset(withID: presetID)
    }
    
    /// Get slot by bank and position
    func slot(forBank bank: Int, position: Int, type: PentatonePresetSlot.SlotType) -> PentatonePresetSlot? {
        if type == .factory {
            return PentatoneFactoryLayout.slot(bank: bank, position: position)
        } else {
            return userLayout.slot(bank: bank, position: position)
        }
    }
    
    /// Check if a slot is empty (no preset assigned)
    func isSlotEmpty(bank: Int, position: Int, type: PentatonePresetSlot.SlotType) -> Bool {
        return preset(forBank: bank, position: position, type: type) == nil
    }
    
    /// Assign a preset to a user slot
    /// - Parameters:
    ///   - preset: The preset to assign (must be a user preset)
    ///   - bank: Bank number (1-5)
    ///   - position: Position within bank (1-5)
    /// - Throws: File system errors or validation errors
    func assignPresetToSlot(preset: AudioParameterSet, bank: Int, position: Int) throws {
        // Validate it's a user preset (not factory)
        guard userPresets.contains(where: { $0.id == preset.id }) else {
            throw PresetError.cannotAssignFactoryPresetToUserSlot
        }
        
        // Validate bank and position
        guard (1...5).contains(bank) && (1...5).contains(position) else {
            throw PresetError.invalidSlotPosition
        }
        
        // Assign to layout
        userLayout.assignPreset(preset.id, toBank: bank, position: position)
        
        // Save layout
        try saveUserLayout()
        
        print("✅ PresetManager: Assigned '\(preset.name)' to U\(bank).\(position)")
    }
    
    /// Clear a user slot (remove preset assignment)
    /// - Parameters:
    ///   - bank: Bank number (1-5)
    ///   - position: Position within bank (1-5)
    /// - Throws: File system errors
    func clearSlot(bank: Int, position: Int) throws {
        userLayout.clearSlot(bank: bank, position: position)
        try saveUserLayout()
        
        print("✅ PresetManager: Cleared slot U\(bank).\(position)")
    }
    
    /// Get all slots for a specific bank and type
    func slots(forBank bank: Int, type: PentatonePresetSlot.SlotType) -> [PentatonePresetSlot] {
        let allSlots = type == .factory ? factoryLayout : userLayout.userSlots
        return allSlots.filter { $0.bank == bank }.sorted { $0.position < $1.position }
    }
    
    /// Get all presets for a specific bank (non-nil only)
    func presets(forBank bank: Int, type: PentatonePresetSlot.SlotType) -> [AudioParameterSet] {
        return slots(forBank: bank, type: type)
            .compactMap { slot in
                guard let presetID = slot.presetID else { return nil }
                return preset(withID: presetID)
            }
    }
    
    /// Initialize layouts - call this after loadAllPresets()
    func initializeLayouts() {
        loadUserLayout()
        
        // TODO: When factory presets are created, populate factoryLayout here
        // For now, factory slots remain empty
        
        print("✅ PresetManager: Layouts initialized")
        print("   - Factory slots: \(factoryLayout.count) total")
        print("   - User slots: \(userLayout.assignedCount) assigned, \(userLayout.emptyCount) empty")
    }
}

// MARK: - Preset Errors

enum PresetError: LocalizedError {
    case cannotDeleteFactoryPreset
    case userPresetLimitReached
    case presetNotFound
    case invalidPresetFile
    case cannotAssignFactoryPresetToUserSlot
    case invalidSlotPosition
    
    var errorDescription: String? {
        switch self {
        case .cannotDeleteFactoryPreset:
            return "Factory presets cannot be deleted"
        case .userPresetLimitReached:
            return "User preset limit reached (75 presets)"
        case .presetNotFound:
            return "Preset not found"
        case .invalidPresetFile:
            return "Invalid preset file format"
        case .cannotAssignFactoryPresetToUserSlot:
            return "Factory presets cannot be assigned to user slots"
        case .invalidSlotPosition:
            return "Invalid slot position (must be bank 1-5, position 1-5)"
        }
    }
}

