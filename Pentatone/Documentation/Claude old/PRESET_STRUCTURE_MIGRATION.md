# Preset Structure Migration Guide

## Overview
The preset system has been restructured from a bank-based system to a named bank system with larger capacity per bank.

## Changes Made

### Old Structure
- **5 Factory Banks** (F1-F5) with 5 presets each = 25 factory slots
- **5 User Banks** (U1-U5) with 5 presets each = 25 user slots
- **Total**: 50 slots (25 factory + 25 user)
- **Naming**: Slots were prefixed with bank type (e.g., "F1.1", "U2.3")
- **Parameters**: `bank: Int`, `position: Int`, `slotType: SlotType`

### New Structure
- **1 Factory Bank** with 25 presets (5×5 grid: 1.1 to 5.5)
- **3 User Banks** (User A, User B, User C) with 25 presets each = 75 user slots
- **Total**: 100 slots (25 factory + 75 user)
- **Naming**: Slots use row.column format without prefixes (e.g., "1.1", "3.4", "5.5")
- **Parameters**: `bankType: PentatoneBankType`, `row: Int`, `column: Int`

## Key Type Changes

### `PentatoneBankType` enum (NEW)
```swift
enum PentatoneBankType: String, Codable, Equatable, CaseIterable {
    case factory = "Factory"
    case userA = "User A"
    case userB = "User B"
    case userC = "User C"
    
    var displayName: String // "Factory", "User A", etc.
    var isUserBank: Bool    // true for User A/B/C
    var isFactoryBank: Bool // true for Factory only
}
```

### `PentatonePresetSlot` struct (UPDATED)
**Old properties:**
- `bank: Int` (1-5)
- `position: Int` (1-5)
- `slotType: SlotType` (.factory or .user)

**New properties:**
- `bankType: PentatoneBankType` (.factory, .userA, .userB, .userC)
- `row: Int` (1-5)
- `column: Int` (1-5)

### `PentatoneUserLayout` struct (UPDATED)
**Old properties:**
- `userSlots: [PentatonePresetSlot]` (25 slots)

**New properties:**
- `userASlots: [PentatonePresetSlot]` (25 slots)
- `userBSlots: [PentatonePresetSlot]` (25 slots)
- `userCSlots: [PentatonePresetSlot]` (25 slots)

**New methods:**
- `slots(for bankType: PentatoneBankType) -> [PentatonePresetSlot]`
- `slot(bankType:row:column:) -> PentatonePresetSlot?`
- `assignPreset(_:toBankType:row:column:)`
- `clearSlot(bankType:row:column:)`

## API Changes in PresetManager

### Method Signature Updates

#### Getting Presets and Slots
**Old:**
```swift
func preset(forBank bank: Int, position: Int, type: PentatonePresetSlot.SlotType) -> AudioParameterSet?
func slot(forBank bank: Int, position: Int, type: PentatonePresetSlot.SlotType) -> PentatonePresetSlot?
func isSlotEmpty(bank: Int, position: Int, type: PentatonePresetSlot.SlotType) -> Bool
```

**New:**
```swift
func preset(forBankType bankType: PentatoneBankType, row: Int, column: Int) -> AudioParameterSet?
func slot(forBankType bankType: PentatoneBankType, row: Int, column: Int) -> PentatonePresetSlot?
func isSlotEmpty(bankType: PentatoneBankType, row: Int, column: Int) -> Bool
```

#### Assigning and Clearing Slots
**Old:**
```swift
func assignPresetToSlot(preset: AudioParameterSet, bank: Int, position: Int) throws
func clearSlot(bank: Int, position: Int) throws
```

**New:**
```swift
func assignPresetToSlot(preset: AudioParameterSet, bankType: PentatoneBankType, row: Int, column: Int) throws
func clearSlot(bankType: PentatoneBankType, row: Int, column: Int) throws
```

#### Getting All Slots/Presets for a Bank
**Old:**
```swift
func slots(forBank bank: Int, type: PentatonePresetSlot.SlotType) -> [PentatonePresetSlot]
func presets(forBank bank: Int, type: PentatonePresetSlot.SlotType) -> [AudioParameterSet]
```

**New:**
```swift
func slots(forBankType bankType: PentatoneBankType) -> [PentatonePresetSlot]
func presets(forBankType bankType: PentatoneBankType) -> [AudioParameterSet]
```

## Migration Examples

### Example 1: Getting a Preset from a Slot

**Old Code:**
```swift
// Get preset from Factory bank 1, position 3
let preset = presetManager.preset(forBank: 1, position: 3, type: .factory)

// Get preset from User bank 2, position 5
let preset = presetManager.preset(forBank: 2, position: 5, type: .user)
```

**New Code:**
```swift
// Get preset from Factory bank, row 1, column 3
let preset = presetManager.preset(forBankType: .factory, row: 1, column: 3)

// Get preset from User A bank, row 2, column 5
let preset = presetManager.preset(forBankType: .userA, row: 2, column: 5)

// Get preset from User B bank, row 3, column 4
let preset = presetManager.preset(forBankType: .userB, row: 3, column: 4)
```

### Example 2: Assigning a Preset to a Slot

**Old Code:**
```swift
try presetManager.assignPresetToSlot(preset: myPreset, bank: 3, position: 2)
```

**New Code:**
```swift
// Can assign to any user bank
try presetManager.assignPresetToSlot(preset: myPreset, bankType: .userA, row: 3, column: 2)
try presetManager.assignPresetToSlot(preset: myPreset, bankType: .userB, row: 1, column: 5)
try presetManager.assignPresetToSlot(preset: myPreset, bankType: .userC, row: 4, column: 3)
```

### Example 3: Iterating Through All Banks

**Old Code:**
```swift
// Iterate through all 5 factory banks
for bankNumber in 1...5 {
    let presets = presetManager.presets(forBank: bankNumber, type: .factory)
    // Process presets...
}

// Iterate through all 5 user banks
for bankNumber in 1...5 {
    let presets = presetManager.presets(forBank: bankNumber, type: .user)
    // Process presets...
}
```

**New Code:**
```swift
// Iterate through all banks using the enum
for bankType in PentatoneBankType.allCases {
    let presets = presetManager.presets(forBankType: bankType)
    print("Bank: \(bankType.displayName), Presets: \(presets.count)")
}

// Or specific banks
let factoryPresets = presetManager.presets(forBankType: .factory)
let userAPresets = presetManager.presets(forBankType: .userA)
let userBPresets = presetManager.presets(forBankType: .userB)
let userCPresets = presetManager.presets(forBankType: .userC)
```

### Example 4: Displaying Slot Names

**Old Code:**
```swift
let slot = presetManager.slot(forBank: 2, position: 4, type: .factory)
print(slot?.displayName) // Prints "F2.4"

let slot2 = presetManager.slot(forBank: 3, position: 1, type: .user)
print(slot2?.displayName) // Prints "U3.1"
```

**New Code:**
```swift
let slot = presetManager.slot(forBankType: .factory, row: 2, column: 4)
print("\(slot?.bankType.displayName ?? "") \(slot?.displayName ?? "")") // Prints "Factory 2.4"

let slot2 = presetManager.slot(forBankType: .userB, row: 3, column: 1)
print("\(slot2?.bankType.displayName ?? "") \(slot2?.displayName ?? "")") // Prints "User B 3.1"
```

## Error Handling Changes

New error case added:
```swift
case cannotModifyFactoryBank
```

This ensures that any attempt to assign or clear a slot in the factory bank will fail gracefully.

## Data Migration Notes

⚠️ **Important**: Existing user layout files will need to be migrated or recreated.

The old `UserLayout.json` structure is incompatible with the new structure. You have two options:

1. **Clean slate**: Delete existing `UserLayout.json` files. The app will create a new default layout with empty slots.

2. **Migration script**: Create a migration function that:
   - Loads the old layout structure
   - Maps old user banks to new user banks (e.g., old banks 1-5 → User A slots)
   - Saves the new layout structure

Example migration approach:
```swift
// This is pseudocode - adapt as needed
func migrateOldLayout() {
    // Load old layout if it exists
    // Map: Old U1-U5 banks → New User A bank (25 slots)
    // Remaining old slots would be lost, or you could map them differently
    // Save new layout
}
```

## Testing Checklist

- [ ] Test loading presets from all 4 banks
- [ ] Test assigning presets to User A, User B, and User C
- [ ] Test that factory bank cannot be modified
- [ ] Test slot display names show correctly (1.1 to 5.5)
- [ ] Test bank display names show correctly (Factory, User A, User B, User C)
- [ ] Test clearing user slots
- [ ] Test that user layout persists across app restarts
- [ ] Test error handling for invalid banks/positions
- [ ] Update UI components to use new bank naming

## UI Considerations

If you have any UI that displays bank names or allows bank selection:

1. Replace numeric bank pickers with `PentatoneBankType` pickers
2. Use `bankType.displayName` for display strings
3. Update any hardcoded bank counts from 5 to 4
4. Update slot count displays from 25 to 75 for total user slots
5. Consider showing bank name alongside slot position (e.g., "User A 2.3" instead of just "U2.3")

## Summary

The new structure provides:
- ✅ More intuitive bank naming (Factory, User A, User B, User C)
- ✅ Triple the user preset capacity (75 vs 25)
- ✅ Cleaner slot naming without type prefixes
- ✅ Type-safe bank selection using enums
- ✅ Better extensibility for future bank additions
- ✅ Total capacity of 100 preset slots (up from 50)
