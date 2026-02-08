//
//  P2 PentatonePresetStructures.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 07/01/2026.
//

import Foundation

// MARK: - Bank Type

/// Represents the five available preset banks in Pentatone
enum PentatoneBankType: String, Codable, Equatable, CaseIterable {
    case factory = "Factory"
    case userA = "User A"
    case userB = "User B"
    case userC = "User C"
    case userD = "User D"
    
    /// Display name for the bank
    var displayName: String {
        return rawValue
    }
    
    /// Check if this is a user bank (editable)
    var isUserBank: Bool {
        return self != .factory
    }
    
    /// Check if this is the factory bank (read-only)
    var isFactoryBank: Bool {
        return self == .factory
    }
}

// MARK: - Preset Slot Structures

/// Represents a single preset slot in the Pentatone 5×5 grid system
/// Each bank contains 25 slots (5 rows × 5 columns), numbered 1.1 to 5.5
struct PentatonePresetSlot: Codable, Equatable, Identifiable {
    
    /// Unique identifier for this slot (not the preset's ID)
    var id: UUID
    
    /// Which bank this slot belongs to
    var bankType: PentatoneBankType
    
    /// Row number within the bank (1-5)
    var row: Int
    
    /// Column number within the bank (1-5)
    var column: Int
    
    /// UUID of the preset assigned to this slot (if any)
    var presetID: UUID?
    
    /// Human-readable slot name (e.g., "1.1", "3.4", "5.5")
    var displayName: String {
        return "\(row).\(column)"
    }
    
    /// Check if slot is empty (no preset assigned)
    var isEmpty: Bool {
        return presetID == nil
    }
    
    /// Initialize a new slot
    init(bankType: PentatoneBankType, row: Int, column: Int, presetID: UUID? = nil) {
        self.id = UUID()
        self.bankType = bankType
        self.row = row
        self.column = column
        self.presetID = presetID
    }
}

// MARK: - Factory Layout (Hardcoded)

/// Factory preset layout for Pentatone
/// This defines the mapping of factory presets to a 5×5 grid (25 slots: 1.1 to 5.5)
struct PentatoneFactoryLayout {
    
    /// All 25 factory preset slots (5 rows × 5 columns)
    /// These UUIDs must match the IDs inside the factory preset JSON files
    
    static var factorySlots: [PentatonePresetSlot] = [
        // Slots 1.1 ... 1.5
        PentatonePresetSlot(bankType: .factory, row: 1, column: 1, presetID: UUID(uuidString: "719BFDB1-0FA5-41C4-9579-0A4EBE49A06B")!), // Smoothie
        PentatonePresetSlot(bankType: .factory, row: 1, column: 2, presetID: UUID(uuidString: "414B6602-3A5F-4A23-AECB-F7A6BBAE0243")!), // Swirl
        PentatonePresetSlot(bankType: .factory, row: 1, column: 3, presetID: UUID(uuidString: "EE0416D5-CAE6-44A8-B9E1-F78FAFDA5FC5")!), // Rotor
        PentatonePresetSlot(bankType: .factory, row: 1, column: 4, presetID: UUID(uuidString: "3CC21418-B3FF-4A44-9858-8DE49D15F244")!), // Belle
        PentatonePresetSlot(bankType: .factory, row: 1, column: 5, presetID: UUID(uuidString: "A5018C92-471E-4819-92F6-A6CAED674950")!), // Bow
        
        // Slots 2.1 ... 2.5
        PentatonePresetSlot(bankType: .factory, row: 2, column: 1, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 2, column: 2, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 2, column: 3, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 2, column: 4, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 2, column: 5, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        
        // Slots 3.1 ... 3.5
        PentatonePresetSlot(bankType: .factory, row: 3, column: 1, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 3, column: 2, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 3, column: 3, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 3, column: 4, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 3, column: 5, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        
        // Slots 4.1 ... 4.5
        PentatonePresetSlot(bankType: .factory, row: 4, column: 1, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 4, column: 2, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 4, column: 3, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 4, column: 4, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 4, column: 5, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        
        // Slots 5.1 ... 5.5
        PentatonePresetSlot(bankType: .factory, row: 5, column: 1, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 5, column: 2, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 5, column: 3, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 5, column: 4, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        PentatonePresetSlot(bankType: .factory, row: 5, column: 5, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!)  // Basic
    ]
    
    /// Get factory slot by row and column
    static func slot(row: Int, column: Int) -> PentatonePresetSlot? {
        return factorySlots.first { $0.row == row && $0.column == column }
    }
    
    /// Update a factory slot with a preset UUID
    /// Call this during development to assign factory presets to slots
    static func updateSlot(row: Int, column: Int, presetID: UUID) {
        if let index = factorySlots.firstIndex(where: { $0.row == row && $0.column == column }) {
            factorySlots[index].presetID = presetID
        }
    }
}

// MARK: - User Layout (Saved to Disk)

/// User preset layout for Pentatone
/// Contains four user banks (User A, User B, User C, User D), each with 25 slots (1.1 to 5.5)
/// This is saved to disk and can be modified by the user
struct PentatoneUserLayout: Codable, Equatable {
    
    /// All user preset slots for User A bank
    var userASlots: [PentatonePresetSlot]
    
    /// All user preset slots for User B bank
    var userBSlots: [PentatonePresetSlot]
    
    /// All user preset slots for User C bank
    var userCSlots: [PentatonePresetSlot]
    
    /// All user preset slots for User D bank
    var userDSlots: [PentatonePresetSlot]
    
    /// Date this layout was last modified
    var lastModified: Date
    
    /// Initialize with custom slots
    init(userASlots: [PentatonePresetSlot], 
         userBSlots: [PentatonePresetSlot],
         userCSlots: [PentatonePresetSlot],
         userDSlots: [PentatonePresetSlot],
         lastModified: Date = Date()) {
        self.userASlots = userASlots
        self.userBSlots = userBSlots
        self.userCSlots = userCSlots
        self.userDSlots = userDSlots
        self.lastModified = lastModified
    }
    
    /// Default layout: 4 banks × 25 empty slots each
    static let `default` = PentatoneUserLayout(
        userASlots: Self.createEmptyBank(for: .userA),
        userBSlots: Self.createEmptyBank(for: .userB),
        userCSlots: Self.createEmptyBank(for: .userC),
        userDSlots: Self.createEmptyBank(for: .userD),
        lastModified: Date()
    )
    
    /// Create 25 empty slots for a specific bank type
    private static func createEmptyBank(for bankType: PentatoneBankType) -> [PentatonePresetSlot] {
        var slots: [PentatonePresetSlot] = []
        for row in 1...5 {
            for column in 1...5 {
                let slot = PentatonePresetSlot(
                    bankType: bankType,
                    row: row,
                    column: column,
                    presetID: nil
                )
                slots.append(slot)
            }
        }
        return slots
    }
    
    /// Get all slots for a specific bank type
    func slots(for bankType: PentatoneBankType) -> [PentatonePresetSlot] {
        switch bankType {
        case .factory:
            return [] // Factory slots are handled separately
        case .userA:
            return userASlots
        case .userB:
            return userBSlots
        case .userC:
            return userCSlots
        case .userD:
            return userDSlots
        }
    }
    
    /// Get user slot by bank type, row, and column
    func slot(bankType: PentatoneBankType, row: Int, column: Int) -> PentatonePresetSlot? {
        return slots(for: bankType).first { $0.row == row && $0.column == column }
    }
    
    /// Update a user slot with a preset UUID
    mutating func assignPreset(_ presetID: UUID?, toBankType bankType: PentatoneBankType, row: Int, column: Int) {
        guard bankType.isUserBank else { return }
        
        var targetSlots: [PentatonePresetSlot]
        switch bankType {
        case .userA:
            targetSlots = userASlots
        case .userB:
            targetSlots = userBSlots
        case .userC:
            targetSlots = userCSlots
        case .userD:
            targetSlots = userDSlots
        case .factory:
            return // Cannot modify factory slots
        }
        
        if let index = targetSlots.firstIndex(where: { $0.row == row && $0.column == column }) {
            targetSlots[index].presetID = presetID
            
            // Write back to the appropriate property
            switch bankType {
            case .userA:
                userASlots = targetSlots
            case .userB:
                userBSlots = targetSlots
            case .userC:
                userCSlots = targetSlots
            case .userD:
                userDSlots = targetSlots
            case .factory:
                break
            }
            
            lastModified = Date()
        }
    }
    
    /// Clear a user slot (remove preset assignment)
    mutating func clearSlot(bankType: PentatoneBankType, row: Int, column: Int) {
        assignPreset(nil, toBankType: bankType, row: row, column: column)
    }
    
    /// Get all non-empty slots across all user banks
    var assignedSlots: [PentatonePresetSlot] {
        return (userASlots + userBSlots + userCSlots + userDSlots).filter { !$0.isEmpty }
    }
    
    /// Get count of assigned slots across all user banks
    var assignedCount: Int {
        return assignedSlots.count
    }
    
    /// Get count of empty slots across all user banks
    var emptyCount: Int {
        return 100 - assignedCount // 4 banks × 25 slots = 100 total
    }
}

// Note: Slot management methods and properties are defined in P1 PresetManager.swift
// This file only contains the slot data structures

