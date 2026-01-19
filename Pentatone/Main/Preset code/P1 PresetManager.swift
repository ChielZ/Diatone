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
    
    /// Update an existing user preset with current parameters
    /// Keeps the same UUID and slot assignment, but updates the sound and optionally the name
    /// - Parameters:
    ///   - preset: The existing preset to update
    ///   - newName: Optional new name for the preset (if nil, keeps original name)
    /// - Returns: The updated preset
    /// - Throws: File system errors or validation errors
    @discardableResult
    func updatePreset(_ preset: AudioParameterSet, newName: String? = nil) throws -> AudioParameterSet {
        // Safety check: ensure it's a user preset (not factory)
        guard userPresets.contains(where: { $0.id == preset.id }) else {
            throw PresetError.cannotUpdateFactoryPreset
        }
        
        let paramManager = AudioParameterManager.shared
        
        // Capture current parameter values as new base values
        paramManager.captureCurrentAsBase()
        
        // Use new name if provided, otherwise keep original
        let finalName = newName ?? preset.name
        
        // Create updated preset with SAME UUID, but new parameters and potentially new name
        let updatedPreset = AudioParameterSet(
            id: preset.id, // Keep same ID!
            name: finalName, // New or original name
            voiceTemplate: paramManager.voiceTemplate,
            master: paramManager.master,
            macroState: paramManager.macroState,
            createdAt: preset.createdAt // Keep original creation date
        )
        
        // Save to disk (overwrites existing file)
        try savePreset(updatedPreset)
        
        // Set as current preset
        currentPreset = updatedPreset
        
        print("✅ PresetManager: Updated preset '\(updatedPreset.name)' (ID: \(updatedPreset.id.uuidString))")
        
        return updatedPreset
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
    
    /// Load a preset and apply it to the audio engine with smooth transition
    /// Uses fade-out/fade-in to eliminate noise during preset switching
    /// - Parameter preset: The preset to load
    func loadPreset(_ preset: AudioParameterSet) {
        let paramManager = AudioParameterManager.shared
        
        print("🎵 PresetManager: Loading preset '\(preset.name)' with smooth transition...")
        
        // Use the new fade-based loading method from ParameterManager
        // This handles:
        // 1. Fade out to silence (100ms)
        // 2. Stop all voices
        // 3. Apply new parameters
        // 4. Fade back in (100ms)
        paramManager.loadPresetWithFade(preset) {
            // Set as current preset after loading is complete
            self.currentPreset = preset
            print("✅ PresetManager: Preset '\(preset.name)' loaded successfully")
        }
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
    /// - Parameters:
    ///   - url: URL of the preset file to import
    ///   - loadImmediately: If true, load the preset to the audio engine after importing (default: true)
    /// - Returns: The imported preset
    /// - Throws: Decoding or file system errors
    @discardableResult
    func importPreset(from url: URL, loadImmediately: Bool = true) throws -> AudioParameterSet {
        // Read data
        let data = try Data(contentsOf: url)
        
        // Attempt to decode preset
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var preset: AudioParameterSet
        do {
            preset = try decoder.decode(AudioParameterSet.self, from: data)
        } catch {
            // Provide detailed error information
            print("❌ PresetManager: Failed to decode preset from \(url.lastPathComponent)")
            print("   Error: \(error)")
            
            // Check if it's a decoding error with more details
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   Missing key: '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .typeMismatch(let type, let context):
                    print("   Type mismatch: Expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .valueNotFound(let type, let context):
                    print("   Value not found: \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .dataCorrupted(let context):
                    print("   Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                @unknown default:
                    print("   Unknown decoding error")
                }
            }
            
            throw PresetError.incompatibleFormat("This preset was created with an older version of the app and cannot be imported. The preset format has changed.")
        }
        
        // Check if preset with same ID already exists
        if presetExists(withID: preset.id) {
            // Generate new ID to avoid conflicts (keep original name)
            let oldID = preset.id
            let newID = UUID()
            
            // Create new preset with updated ID but same name
            preset = AudioParameterSet(
                id: newID,
                name: preset.name,
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
        
        // Optionally load the preset to the audio engine
        if loadImmediately {
            loadPreset(preset)
            print("✅ PresetManager: Loaded imported preset '\(preset.name)' to audio engine")
        }
        
        return preset
    }
    
    /// Import a preset and assign it to a specific slot
    /// - Parameters:
    ///   - url: URL of the preset file to import
    ///   - bankType: The bank to assign the preset to (must be a user bank)
    ///   - row: Row position (1-5)
    ///   - column: Column position (1-5)
    ///   - loadImmediately: If true, load the preset to the audio engine after importing (default: true)
    /// - Returns: The imported preset
    /// - Throws: Decoding, file system, or slot assignment errors
    @discardableResult
    func importPresetToSlot(from url: URL, 
                           bankType: PentatoneBankType, 
                           row: Int, 
                           column: Int,
                           loadImmediately: Bool = true) throws -> AudioParameterSet {
        // Import the preset (but don't auto-load yet)
        let preset = try importPreset(from: url, loadImmediately: false)
        
        // Assign to the specified slot
        try assignPresetToSlot(preset: preset, bankType: bankType, row: row, column: column)
        
        print("✅ PresetManager: Assigned imported preset '\(preset.name)' to \(bankType.displayName) \(row).\(column)")
        
        // Load if requested
        if loadImmediately {
            loadPreset(preset)
            print("✅ PresetManager: Loaded imported preset '\(preset.name)' to audio engine")
        }
        
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
    
    /// Check if user preset storage is full (100 slots for Pentatone)
    var userPresetsAreFull: Bool {
        return userPresetCount >= 100
    }
    
    /// Number of available user preset slots remaining
    var availableUserSlots: Int {
        return max(0, 100 - userPresetCount)
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
    ///   - bankType: The bank type (Factory, User A, User B, or User C)
    ///   - row: Row within bank (1-5)
    ///   - column: Column within bank (1-5)
    /// - Returns: The preset assigned to this slot, or nil if empty/not found
    func preset(forBankType bankType: PentatoneBankType, row: Int, column: Int) -> AudioParameterSet? {
        // Get the slot
        let slot: PentatonePresetSlot?
        if bankType == .factory {
            slot = PentatoneFactoryLayout.slot(row: row, column: column)
        } else {
            slot = userLayout.slot(bankType: bankType, row: row, column: column)
        }
        
        // Get preset ID from slot
        guard let presetID = slot?.presetID else {
            return nil
        }
        
        // Lookup preset by ID
        return preset(withID: presetID)
    }
    
    /// Get slot by bank type, row, and column
    func slot(forBankType bankType: PentatoneBankType, row: Int, column: Int) -> PentatonePresetSlot? {
        if bankType == .factory {
            return PentatoneFactoryLayout.slot(row: row, column: column)
        } else {
            return userLayout.slot(bankType: bankType, row: row, column: column)
        }
    }
    
    /// Check if a slot is empty (no preset assigned)
    func isSlotEmpty(bankType: PentatoneBankType, row: Int, column: Int) -> Bool {
        return preset(forBankType: bankType, row: row, column: column) == nil
    }
    
    /// Assign a preset to a user slot
    /// - Parameters:
    ///   - preset: The preset to assign (must be a user preset)
    ///   - bankType: The user bank type (User A, User B, or User C)
    ///   - row: Row within bank (1-5)
    ///   - column: Column within bank (1-5)
    /// - Throws: File system errors or validation errors
    func assignPresetToSlot(preset: AudioParameterSet, bankType: PentatoneBankType, row: Int, column: Int) throws {
        // Validate it's a user preset (not factory)
        guard userPresets.contains(where: { $0.id == preset.id }) else {
            throw PresetError.cannotAssignFactoryPresetToUserSlot
        }
        
        // Validate it's a user bank (not factory)
        guard bankType.isUserBank else {
            throw PresetError.cannotModifyFactoryBank
        }
        
        // Validate row and column
        guard (1...5).contains(row) && (1...5).contains(column) else {
            throw PresetError.invalidSlotPosition
        }
        
        // Assign to layout
        userLayout.assignPreset(preset.id, toBankType: bankType, row: row, column: column)
        
        // Save layout
        try saveUserLayout()
        
        print("✅ PresetManager: Assigned '\(preset.name)' to \(bankType.displayName) \(row).\(column)")
    }
    
    /// Clear a user slot (remove preset assignment)
    /// - Parameters:
    ///   - bankType: The user bank type (User A, User B, or User C)
    ///   - row: Row within bank (1-5)
    ///   - column: Column within bank (1-5)
    /// - Throws: File system errors or validation errors
    func clearSlot(bankType: PentatoneBankType, row: Int, column: Int) throws {
        guard bankType.isUserBank else {
            throw PresetError.cannotModifyFactoryBank
        }
        
        userLayout.clearSlot(bankType: bankType, row: row, column: column)
        try saveUserLayout()
        
        print("✅ PresetManager: Cleared slot \(bankType.displayName) \(row).\(column)")
    }
    
    /// Get all slots for a specific bank type
    func slots(forBankType bankType: PentatoneBankType) -> [PentatonePresetSlot] {
        if bankType == .factory {
            return factoryLayout
        } else {
            return userLayout.slots(for: bankType)
        }
    }
    
    /// Get all presets for a specific bank (non-nil only)
    func presets(forBankType bankType: PentatoneBankType) -> [AudioParameterSet] {
        return slots(forBankType: bankType)
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
        print("   - User A slots: 25 total")
        print("   - User B slots: 25 total")
        print("   - User C slots: 25 total")
        print("   - User D slots: 25 total")
        print("   - Total assigned: \(userLayout.assignedCount), Empty: \(userLayout.emptyCount)")
    }
}

// MARK: - Preset Errors

enum PresetError: LocalizedError {
    case cannotDeleteFactoryPreset
    case cannotUpdateFactoryPreset
    case userPresetLimitReached
    case presetNotFound
    case invalidPresetFile
    case cannotAssignFactoryPresetToUserSlot
    case cannotModifyFactoryBank
    case invalidSlotPosition
    case incompatibleFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .cannotDeleteFactoryPreset:
            return "Factory presets cannot be deleted"
        case .cannotUpdateFactoryPreset:
            return "Factory presets cannot be updated"
        case .userPresetLimitReached:
            return "User preset limit reached (100 presets)"
        case .presetNotFound:
            return "Preset not found"
        case .invalidPresetFile:
            return "Invalid preset file format"
        case .cannotAssignFactoryPresetToUserSlot:
            return "Factory presets cannot be assigned to user slots"
        case .cannotModifyFactoryBank:
            return "Factory bank cannot be modified"
        case .invalidSlotPosition:
            return "Invalid slot position (must be row 1-5, column 1-5)"
        case .incompatibleFormat(let message):
            return message
        }
    }
}

