//
//  P2 PentatonePresetStructures.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 07/01/2026.
//

import Foundation

// MARK: - Preset Slot Structures

/// Represents a single preset slot in the Pentatone 5×5 grid system
/// Each slot can hold a reference to a preset via its UUID
struct PentatonePresetSlot: Codable, Equatable, Identifiable {
    
    /// Unique identifier for this slot (not the preset's ID)
    var id: UUID
    
    /// Bank number (1-5)
    var bank: Int
    
    /// Position within the bank (1-5)
    var position: Int
    
    /// UUID of the preset assigned to this slot (if any)
    var presetID: UUID?
    
    /// Type of slot (factory or user)
    var slotType: SlotType
    
    enum SlotType: String, Codable, Equatable {
        case factory
        case user
    }
    
    /// Human-readable slot name (e.g., "F1.1" or "U2.3")
    var displayName: String {
        let prefix = slotType == .factory ? "F" : "U"
        return "\(prefix)\(bank).\(position)"
    }
    
    /// Check if slot is empty (no preset assigned)
    var isEmpty: Bool {
        return presetID == nil
    }
    
    /// Initialize a new slot
    init(bank: Int, position: Int, presetID: UUID? = nil, slotType: SlotType) {
        self.id = UUID()
        self.bank = bank
        self.position = position
        self.presetID = presetID
        self.slotType = slotType
    }
}

// MARK: - Factory Layout (Hardcoded)

/// Factory preset layout for Pentatone
/// This defines the mapping of factory presets to the 5×5 grid (F1.1 - F5.5)
struct PentatoneFactoryLayout {
    
    /// All 25 factory preset slots
    /// These UUIDs must match the IDs inside the factory preset JSON files
    static var factorySlots: [PentatonePresetSlot] = {
        var slots: [PentatonePresetSlot] = []
        
        // For now, create 25 empty slots
        // When factory presets are created, update this array with actual UUIDs
        for bank in 1...5 {
            for position in 1...5 {
                let slot = PentatonePresetSlot(
                    bank: bank,
                    position: position,
                    presetID: nil,  // Will be filled in later when factory presets exist
                    slotType: .factory
                )
                slots.append(slot)
            }
        }
        
        return slots
    }()
    
    /// Get factory slot by bank and position
    static func slot(bank: Int, position: Int) -> PentatonePresetSlot? {
        return factorySlots.first { $0.bank == bank && $0.position == position }
    }
    
    /// Update a factory slot with a preset UUID
    /// Call this during development to assign factory presets to slots
    static func updateSlot(bank: Int, position: Int, presetID: UUID) {
        if let index = factorySlots.firstIndex(where: { $0.bank == bank && $0.position == position }) {
            factorySlots[index].presetID = presetID
        }
    }
}

// MARK: - User Layout (Saved to Disk)

/// User preset layout for Pentatone
/// This defines the mapping of user presets to the 5×5 grid (U1.1 - U5.5)
/// Unlike factory layout, this is saved to disk and can be modified by the user
struct PentatoneUserLayout: Codable, Equatable {
    
    /// All 25 user preset slots
    var userSlots: [PentatonePresetSlot]
    
    /// Date this layout was last modified
    var lastModified: Date
    
    /// Initialize with custom slots
    init(userSlots: [PentatonePresetSlot], lastModified: Date = Date()) {
        self.userSlots = userSlots
        self.lastModified = lastModified
    }
    
    /// Default layout: 25 empty slots (U1.1 - U5.5)
    static let `default` = PentatoneUserLayout(
        userSlots: {
            var slots: [PentatonePresetSlot] = []
            for bank in 1...5 {
                for position in 1...5 {
                    let slot = PentatonePresetSlot(
                        bank: bank,
                        position: position,
                        presetID: nil,  // Empty by default
                        slotType: .user
                    )
                    slots.append(slot)
                }
            }
            return slots
        }(),
        lastModified: Date()
    )
    
    /// Get user slot by bank and position
    func slot(bank: Int, position: Int) -> PentatonePresetSlot? {
        return userSlots.first { $0.bank == bank && $0.position == position }
    }
    
    /// Update a user slot with a preset UUID
    mutating func assignPreset(_ presetID: UUID?, toBank bank: Int, position: Int) {
        if let index = userSlots.firstIndex(where: { $0.bank == bank && $0.position == position }) {
            userSlots[index].presetID = presetID
            lastModified = Date()
        }
    }
    
    /// Clear a user slot (remove preset assignment)
    mutating func clearSlot(bank: Int, position: Int) {
        assignPreset(nil, toBank: bank, position: position)
    }
    
    /// Get all non-empty slots
    var assignedSlots: [PentatonePresetSlot] {
        return userSlots.filter { !$0.isEmpty }
    }
    
    /// Get count of assigned slots
    var assignedCount: Int {
        return assignedSlots.count
    }
    
    /// Get count of empty slots
    var emptyCount: Int {
        return 25 - assignedCount
    }
}

// MARK: - Preset Manager Extension (Slot Management)

extension PresetManager {
    
    // MARK: - Layouts
    
    /// User preset layout (U1.1 - U5.5)
    /// This is saved to disk and persists across app launches
    @Published private(set) var userLayout: PentatoneUserLayout = .default
    
    /// Factory preset layout (F1.1 - F5.5)
    /// This is hardcoded and read-only
    var factoryLayout: [PentatonePresetSlot] {
        return PentatoneFactoryLayout.factorySlots
    }
    
    // MARK: - Layout File Path
    
    /// User layout file location
    private var userLayoutURL: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent("UserPresets/UserLayout.json")
    }
    
    // MARK: - Loading User Layout
    
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
    
    // MARK: - Slot Access
    
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
    
    // MARK: - Slot Assignment (User Slots Only)
    
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
    
    // MARK: - Bank Navigation
    
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
    
    // MARK: - Layout Initialization
    
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

// MARK: - Additional Preset Errors

extension PresetError {
    static let cannotAssignFactoryPresetToUserSlot = PresetError.custom("Factory presets cannot be assigned to user slots")
    static let invalidSlotPosition = PresetError.custom("Invalid slot position (must be bank 1-5, position 1-5)")
    
    case custom(String)
    
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
        case .custom(let message):
            return message
        case .cannotAssignFactoryPresetToUserSlot:
            return "Factory presets cannot be assigned to user slots"
        case .invalidSlotPosition:
            return "Invalid slot position"
        }
    }
}
