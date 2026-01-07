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

// Note: Slot management methods and properties are defined in P1 PresetManager.swift
// This file only contains the slot data structures
