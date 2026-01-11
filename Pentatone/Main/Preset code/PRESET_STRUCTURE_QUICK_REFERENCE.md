# Preset Structure Quick Reference

## What Changed?

### Before (Old System)
```
┌─────────────────────────────────────────┐
│  5 Factory Banks (F1-F5)               │
│  Each with 5 slots = 25 factory slots  │
│  Naming: F1.1, F1.2, ..., F5.5         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  5 User Banks (U1-U5)                   │
│  Each with 5 slots = 25 user slots      │
│  Naming: U1.1, U1.2, ..., U5.5          │
└─────────────────────────────────────────┘

Total: 50 slots
```

### After (New System)
```
┌──────────────────────────────────────────┐
│  Factory Bank                            │
│  25 slots (5×5 grid)                     │
│  Naming: 1.1, 1.2, ..., 5.5              │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│  User A Bank                             │
│  25 slots (5×5 grid)                     │
│  Naming: 1.1, 1.2, ..., 5.5              │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│  User B Bank                             │
│  25 slots (5×5 grid)                     │
│  Naming: 1.1, 1.2, ..., 5.5              │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│  User C Bank                             │
│  25 slots (5×5 grid)                     │
│  Naming: 1.1, 1.2, ..., 5.5              │
└──────────────────────────────────────────┘

Total: 100 slots (25 factory + 75 user)
```

## API Quick Lookup

### Getting a Preset

```swift
// OLD
let preset = presetManager.preset(
    forBank: 2, 
    position: 3, 
    type: .factory
)

// NEW
let preset = presetManager.preset(
    forBankType: .factory,  // or .userA, .userB, .userC
    row: 2,
    column: 3
)
```

### Getting a Slot

```swift
// OLD
let slot = presetManager.slot(
    forBank: 4, 
    position: 1, 
    type: .user
)

// NEW
let slot = presetManager.slot(
    forBankType: .userA,  // or .userB, .userC, .factory
    row: 4,
    column: 1
)
```

### Assigning a Preset to Slot

```swift
// OLD
try presetManager.assignPresetToSlot(
    preset: myPreset,
    bank: 3,
    position: 5
)

// NEW
try presetManager.assignPresetToSlot(
    preset: myPreset,
    bankType: .userB,  // Can be .userA, .userB, or .userC
    row: 3,
    column: 5
)
```

### Clearing a Slot

```swift
// OLD
try presetManager.clearSlot(
    bank: 2,
    position: 4
)

// NEW
try presetManager.clearSlot(
    bankType: .userA,
    row: 2,
    column: 4
)
```

### Getting All Slots in a Bank

```swift
// OLD
let slots = presetManager.slots(
    forBank: 3,
    type: .user
)

// NEW
let slots = presetManager.slots(
    forBankType: .userC  // or .factory, .userA, .userB
)
```

### Getting All Presets in a Bank

```swift
// OLD
let presets = presetManager.presets(
    forBank: 1,
    type: .factory
)

// NEW
let presets = presetManager.presets(
    forBankType: .factory  // or .userA, .userB, .userC
)
```

## Bank Type Enum

```swift
enum PentatoneBankType: String, Codable, Equatable, CaseIterable {
    case factory = "Factory"
    case userA = "User A"
    case userB = "User B"
    case userC = "User C"
    
    var displayName: String     // "Factory", "User A", etc.
    var isUserBank: Bool        // true for A/B/C
    var isFactoryBank: Bool     // true for Factory only
}
```

## Iterating All Banks

```swift
// NEW - Much cleaner!
for bankType in PentatoneBankType.allCases {
    let presets = presetManager.presets(forBankType: bankType)
    print("\(bankType.displayName): \(presets.count) presets")
}

// Output:
// Factory: 25 presets
// User A: 10 presets
// User B: 5 presets
// User C: 0 presets
```

## Display Names

### Old System
- Slot: `"F1.1"`, `"U3.4"`
- Needed prefix to identify bank type

### New System
- Slot: `"1.1"`, `"3.4"` (no prefix)
- Bank name is separate: `"Factory"`, `"User A"`, `"User B"`, `"User C"`
- Display: `"\(bankType.displayName) \(slot.displayName)"` → `"User B 2.3"`

## Struct Property Changes

### PentatonePresetSlot

```swift
// OLD properties
var bank: Int              // 1-5
var position: Int          // 1-5
var slotType: SlotType     // .factory or .user

// NEW properties
var bankType: PentatoneBankType  // .factory, .userA, .userB, .userC
var row: Int                      // 1-5
var column: Int                   // 1-5
```

### PentatoneUserLayout

```swift
// OLD properties
var userSlots: [PentatonePresetSlot]  // 25 slots

// NEW properties
var userASlots: [PentatonePresetSlot]  // 25 slots
var userBSlots: [PentatonePresetSlot]  // 25 slots
var userCSlots: [PentatonePresetSlot]  // 25 slots
```

## Error Changes

New error case:
```swift
case cannotModifyFactoryBank  // Thrown when trying to assign/clear factory slots
```

## Common Patterns

### UI Bank Picker

```swift
// OLD
Picker("Bank", selection: $selectedBank) {
    ForEach(1...5, id: \.self) { bank in
        Text("Bank \(bank)").tag(bank)
    }
}
Picker("Type", selection: $selectedType) {
    Text("Factory").tag(SlotType.factory)
    Text("User").tag(SlotType.user)
}

// NEW
Picker("Bank", selection: $selectedBankType) {
    ForEach(PentatoneBankType.allCases, id: \.self) { bankType in
        Text(bankType.displayName).tag(bankType)
    }
}
// No need for separate type picker!
```

### Grid Display

```swift
// Shows a 5×5 grid of slots for a bank
ForEach(1...5, id: \.self) { row in
    HStack {
        ForEach(1...5, id: \.self) { column in
            if let preset = presetManager.preset(
                forBankType: selectedBankType,
                row: row,
                column: column
            ) {
                PresetButton(preset: preset)
            } else {
                EmptySlotButton(
                    bankType: selectedBankType,
                    row: row,
                    column: column
                )
            }
        }
    }
}
```

## Key Benefits

1. **More capacity**: 100 total slots (up from 50)
2. **Better organization**: Named banks instead of numbers
3. **Type safety**: Enum instead of Int + separate type flag
4. **Cleaner naming**: No prefixes needed for slot numbers
5. **Extensibility**: Easy to add "User D" bank in the future
6. **Simpler iteration**: Use `PentatoneBankType.allCases`

## ⚠️ Breaking Changes

All code that calls preset/slot methods needs to be updated to use:
- `bankType` instead of `bank` + `type`
- `row` instead of `bank` (for positioning)
- `column` instead of `position`

Existing UserLayout.json files are incompatible and will need to be migrated or reset.
