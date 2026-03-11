//
//  P2 DiatonePresetStructures.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 07/01/2026.
//

import Foundation

// MARK: - Bank Type

/// Represents the five available preset banks in Diatone
enum DiatoneBankType: String, Codable, Equatable, CaseIterable {
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

/// Represents a single preset slot in the Diatone 7×7 grid system
/// Each bank contains 49 slots (7 rows × 7 columns), numbered 1.1 to 7.7
struct DiatonePresetSlot: Codable, Equatable, Identifiable {
    
    /// Unique identifier for this slot (not the preset's ID)
    var id: UUID
    
    /// Which bank this slot belongs to
    var bankType: DiatoneBankType
    
    /// Row number within the bank (1-7)
    var row: Int
    
    /// Column number within the bank (1-7)
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
    init(bankType: DiatoneBankType, row: Int, column: Int, presetID: UUID? = nil) {
        self.id = UUID()
        self.bankType = bankType
        self.row = row
        self.column = column
        self.presetID = presetID
    }
}

// MARK: - Factory Layout (Hardcoded)

/// Factory preset layout for Diatone
/// This defines the mapping of factory presets to a 7×7 grid (49 slots: 1.1 to 7.7)
struct DiatoneFactoryLayout {
    
    /// All 25 factory preset slots (5 rows × 5 columns)
    /// These UUIDs must match the IDs inside the factory preset JSON files
    
    static var factorySlots: [DiatonePresetSlot] = [
        // Slots 1.1 ... 1.7
        
        DiatonePresetSlot(bankType: .factory, row: 1, column: 1, presetID: UUID(uuidString: "719BFDB1-0FA5-41C4-9579-0A4EBE49A06B")!), // Swirly
       DiatonePresetSlot(bankType: .factory, row: 1, column: 2, presetID: UUID(uuidString: "414B6602-3A5F-4A23-AECB-F7A6BBAE0243")!), // Coconut
        DiatonePresetSlot(bankType: .factory, row: 1, column: 3, presetID: UUID(uuidString: "EE0416D5-CAE6-44A8-B9E1-F78FAFDA5FC5")!), // Rotor
        DiatonePresetSlot(bankType: .factory, row: 1, column: 4, presetID: UUID(uuidString: "3CC21418-B3FF-4A44-9858-8DE49D15F244")!), // Belle
        DiatonePresetSlot(bankType: .factory, row: 1, column: 5, presetID: UUID(uuidString: "A5018C92-471E-4819-92F6-A6CAED674950")!), // Bow
        DiatonePresetSlot(bankType: .factory, row: 1, column: 6, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        DiatonePresetSlot(bankType: .factory, row: 1, column: 7, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        
        // Slots 2.1 ... 2.7 (Piano / E-Piano)
        DiatonePresetSlot(bankType: .factory, row: 2, column: 1, presetID: UUID(uuidString: "A1B2C3D4-1111-4AAA-BBBB-000000000001")!), // Rhodes
        DiatonePresetSlot(bankType: .factory, row: 2, column: 2, presetID: UUID(uuidString: "A1B2C3D4-2222-4AAA-BBBB-000000000002")!), // Wurli
        DiatonePresetSlot(bankType: .factory, row: 2, column: 3, presetID: UUID(uuidString: "A1B2C3D4-3333-4AAA-BBBB-000000000003")!), // DX Piano
        DiatonePresetSlot(bankType: .factory, row: 2, column: 4, presetID: UUID(uuidString: "A1B2C3D4-4444-4AAA-BBBB-000000000004")!), // Tine
        DiatonePresetSlot(bankType: .factory, row: 2, column: 5, presetID: UUID(uuidString: "A1B2C3D4-5555-4AAA-BBBB-000000000005")!), // Clavinet
        DiatonePresetSlot(bankType: .factory, row: 2, column: 6, presetID: UUID(uuidString: "A1B2C3D4-6666-4AAA-BBBB-000000000006")!), // Soft Keys
        DiatonePresetSlot(bankType: .factory, row: 2, column: 7, presetID: UUID(uuidString: "A1B2C3D4-7777-4AAA-BBBB-000000000007")!), // Honky
        
        // Slots 3.1 ... 3.7 (Piano / Keys - Hybrid)
        DiatonePresetSlot(bankType: .factory, row: 3, column: 1, presetID: UUID(uuidString: "B2C3D4E5-1111-4BBB-CCCC-000000000001")!), // Felt
        DiatonePresetSlot(bankType: .factory, row: 3, column: 2, presetID: UUID(uuidString: "B2C3D4E5-2222-4BBB-CCCC-000000000002")!), // Bark
        DiatonePresetSlot(bankType: .factory, row: 3, column: 3, presetID: UUID(uuidString: "B2C3D4E5-3333-4BBB-CCCC-000000000003")!), // Dusk
        DiatonePresetSlot(bankType: .factory, row: 3, column: 4, presetID: UUID(uuidString: "B2C3D4E5-4444-4BBB-CCCC-000000000004")!), // Pluck
        DiatonePresetSlot(bankType: .factory, row: 3, column: 5, presetID: UUID(uuidString: "B2C3D4E5-5555-4BBB-CCCC-000000000005")!), // Mellow
        DiatonePresetSlot(bankType: .factory, row: 3, column: 6, presetID: UUID(uuidString: "B2C3D4E5-6666-4BBB-CCCC-000000000006")!), // Chime
        DiatonePresetSlot(bankType: .factory, row: 3, column: 7, presetID: UUID(uuidString: "B2C3D4E5-7777-4BBB-CCCC-000000000007")!), // Thump
        
        // Slots 4.1 ... 4.7 (Synth Leads / Pads)
        DiatonePresetSlot(bankType: .factory, row: 4, column: 1, presetID: UUID(uuidString: "C3D4E5F6-1111-4CCC-DDDD-000000000001")!), // Siren
        DiatonePresetSlot(bankType: .factory, row: 4, column: 2, presetID: UUID(uuidString: "C3D4E5F6-2222-4CCC-DDDD-000000000002")!), // Growl
        DiatonePresetSlot(bankType: .factory, row: 4, column: 3, presetID: UUID(uuidString: "C3D4E5F6-3333-4CCC-DDDD-000000000003")!), // Pulse
        DiatonePresetSlot(bankType: .factory, row: 4, column: 4, presetID: UUID(uuidString: "C3D4E5F6-4444-4CCC-DDDD-000000000004")!), // Nebula
        DiatonePresetSlot(bankType: .factory, row: 4, column: 5, presetID: UUID(uuidString: "C3D4E5F6-5555-4CCC-DDDD-000000000005")!), // Razor
        DiatonePresetSlot(bankType: .factory, row: 4, column: 6, presetID: UUID(uuidString: "C3D4E5F6-6666-4CCC-DDDD-000000000006")!), // Warp
        DiatonePresetSlot(bankType: .factory, row: 4, column: 7, presetID: UUID(uuidString: "C3D4E5F6-7777-4CCC-DDDD-000000000007")!), // Brass
        
        // Slots 5.1 ... 5.7 (Ambient / Atmospheric)
        DiatonePresetSlot(bankType: .factory, row: 5, column: 1, presetID: UUID(uuidString: "D4E5F6A7-1111-4DDD-EEEE-000000000001")!), // Glisten
        DiatonePresetSlot(bankType: .factory, row: 5, column: 2, presetID: UUID(uuidString: "D4E5F6A7-2222-4DDD-EEEE-000000000002")!), // Drift
        DiatonePresetSlot(bankType: .factory, row: 5, column: 3, presetID: UUID(uuidString: "D4E5F6A7-3333-4DDD-EEEE-000000000003")!), // Haze
        DiatonePresetSlot(bankType: .factory, row: 5, column: 4, presetID: UUID(uuidString: "D4E5F6A7-4444-4DDD-EEEE-000000000004")!), // Vapor
        DiatonePresetSlot(bankType: .factory, row: 5, column: 5, presetID: UUID(uuidString: "D4E5F6A7-5555-4DDD-EEEE-000000000005")!), // Shade
        DiatonePresetSlot(bankType: .factory, row: 5, column: 6, presetID: UUID(uuidString: "D4E5F6A7-6666-4DDD-EEEE-000000000006")!), // Murk
        DiatonePresetSlot(bankType: .factory, row: 5, column: 7, presetID: UUID(uuidString: "D4E5F6A7-7777-4DDD-EEEE-000000000007")!), // Abyss
        
        // Slots 6.1 ... 6.7
        DiatonePresetSlot(bankType: .factory, row: 6, column: 1, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        DiatonePresetSlot(bankType: .factory, row: 6, column: 2, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        DiatonePresetSlot(bankType: .factory, row: 6, column: 3, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        DiatonePresetSlot(bankType: .factory, row: 6, column: 4, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        DiatonePresetSlot(bankType: .factory, row: 6, column: 5, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!),  // Basic
        DiatonePresetSlot(bankType: .factory, row: 6, column: 6, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        DiatonePresetSlot(bankType: .factory, row: 6, column: 7, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        
        // Slots 7.1 ... 7.7
        DiatonePresetSlot(bankType: .factory, row: 7, column: 1, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        DiatonePresetSlot(bankType: .factory, row: 7, column: 2, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        DiatonePresetSlot(bankType: .factory, row: 7, column: 3, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        DiatonePresetSlot(bankType: .factory, row: 7, column: 4, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        DiatonePresetSlot(bankType: .factory, row: 7, column: 5, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!),  // Basic
        DiatonePresetSlot(bankType: .factory, row: 7, column: 6, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
        DiatonePresetSlot(bankType: .factory, row: 7, column: 7, presetID: UUID(uuidString: "6B06BE18-B1BF-4B70-9027-E3DE53ADDC8B")!), // Basic
    ]
    
    /// Get factory slot by row and column
    static func slot(row: Int, column: Int) -> DiatonePresetSlot? {
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

/// User preset layout for Diatone
/// Contains four user banks (User A, User B, User C, User D), each with 49 slots (1.1 to 7.7)
/// This is saved to disk and can be modified by the user
struct DiatoneUserLayout: Codable, Equatable {
    
    /// All user preset slots for User A bank
    var userASlots: [DiatonePresetSlot]
    
    /// All user preset slots for User B bank
    var userBSlots: [DiatonePresetSlot]
    
    /// All user preset slots for User C bank
    var userCSlots: [DiatonePresetSlot]
    
    /// All user preset slots for User D bank
    var userDSlots: [DiatonePresetSlot]
    
    /// Date this layout was last modified
    var lastModified: Date
    
    /// Initialize with custom slots
    init(userASlots: [DiatonePresetSlot], 
         userBSlots: [DiatonePresetSlot],
         userCSlots: [DiatonePresetSlot],
         userDSlots: [DiatonePresetSlot],
         lastModified: Date = Date()) {
        self.userASlots = userASlots
        self.userBSlots = userBSlots
        self.userCSlots = userCSlots
        self.userDSlots = userDSlots
        self.lastModified = lastModified
    }
    
    /// Default layout: 4 banks × 25 empty slots each
    static let `default` = DiatoneUserLayout(
        userASlots: Self.createEmptyBank(for: .userA),
        userBSlots: Self.createEmptyBank(for: .userB),
        userCSlots: Self.createEmptyBank(for: .userC),
        userDSlots: Self.createEmptyBank(for: .userD),
        lastModified: Date()
    )
    
    /// Create 25 empty slots for a specific bank type
    private static func createEmptyBank(for bankType: DiatoneBankType) -> [DiatonePresetSlot] {
        var slots: [DiatonePresetSlot] = []
        for row in 1...7 {
            for column in 1...7 {
                let slot = DiatonePresetSlot(
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
    func slots(for bankType: DiatoneBankType) -> [DiatonePresetSlot] {
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
    func slot(bankType: DiatoneBankType, row: Int, column: Int) -> DiatonePresetSlot? {
        return slots(for: bankType).first { $0.row == row && $0.column == column }
    }
    
    /// Update a user slot with a preset UUID
    mutating func assignPreset(_ presetID: UUID?, toBankType bankType: DiatoneBankType, row: Int, column: Int) {
        guard bankType.isUserBank else { return }
        
        var targetSlots: [DiatonePresetSlot]
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
    mutating func clearSlot(bankType: DiatoneBankType, row: Int, column: Int) {
        assignPreset(nil, toBankType: bankType, row: row, column: column)
    }
    
    /// Get all non-empty slots across all user banks
    var assignedSlots: [DiatonePresetSlot] {
        return (userASlots + userBSlots + userCSlots + userDSlots).filter { !$0.isEmpty }
    }
    
    /// Get count of assigned slots across all user banks
    var assignedCount: Int {
        return assignedSlots.count
    }
    
    /// Get count of empty slots across all user banks
    var emptyCount: Int {
        return 196 - assignedCount // 4 banks × 49 slots = 196 total
    }
}

// Note: Slot management methods and properties are defined in P1 PresetManager.swift
// This file only contains the slot data structures

