# PresetView Update Summary

## Changes Made to V4-S10 ParameterPage10View.swift

### 1. State Variables Updated

**Old:**
```swift
@AppStorage("presetView.selectedBank") private var selectedBank: Int = 1 // 1-5
@AppStorage("presetView.selectedPosition") private var selectedPosition: Int = 1 // 1-5
@AppStorage("presetView.selectedTypeRawValue") private var selectedTypeRawValue: String = PentatonePresetSlot.SlotType.factory.rawValue

private var selectedType: PentatonePresetSlot.SlotType {
    get { PentatonePresetSlot.SlotType(rawValue: selectedTypeRawValue) ?? .factory }
    set { selectedTypeRawValue = newValue.rawValue }
}
```

**New:**
```swift
@AppStorage("presetView.selectedBankTypeRawValue") private var selectedBankTypeRawValue: String = PentatoneBankType.factory.rawValue
@AppStorage("presetView.selectedRow") private var selectedRow: Int = 1 // 1-5
@AppStorage("presetView.selectedColumn") private var selectedColumn: Int = 1 // 1-5

private var selectedBankType: PentatoneBankType {
    get { PentatoneBankType(rawValue: selectedBankTypeRawValue) ?? .factory }
    set { selectedBankTypeRawValue = newValue.rawValue }
}
```

### 2. Display Text Updated

**Old:**
```swift
private var bankDisplayText: String {
    let prefix = selectedType == .factory ? "F" : "U"
    return "\(prefix) BANK \(selectedBank)"
}
// Output: "F BANK 3" or "U BANK 2"

private var positionDisplayText: String {
    let prefix = selectedType == .factory ? "F" : "U"
    let slotName = "\(prefix)\(selectedBank).\(selectedPosition)"
    // ...
}
// Output: "F3.4: My Preset" or "U2.1 - Empty"
```

**New:**
```swift
private var bankDisplayText: String {
    return selectedBankType.displayName.uppercased()
}
// Output: "FACTORY" or "USER A" or "USER B" or "USER C"

private var positionDisplayText: String {
    let slotName = "\(selectedRow).\(selectedColumn)"
    // ...
}
// Output: "2.3: My Preset" or "4.5 - Empty"
```

### 3. Navigation Logic Updated

**Old - previousBank():**
```swift
if selectedBank > 1 {
    selectedBank -= 1
} else {
    // Wrap to bank 5, and toggle type
    selectedBank = 5
    selectedTypeRawValue = (selectedType == .factory) ? 
        PentatonePresetSlot.SlotType.user.rawValue : 
        PentatonePresetSlot.SlotType.factory.rawValue
}
// Cycles: F1 → F2 → F3 → F4 → F5 → U1 → U2 → U3 → U4 → U5 → F1
```

**New - previousBank():**
```swift
let allBanks = PentatoneBankType.allCases
if let currentIndex = allBanks.firstIndex(of: selectedBankType) {
    if currentIndex > 0 {
        selectedBankTypeRawValue = allBanks[currentIndex - 1].rawValue
    } else {
        selectedBankTypeRawValue = allBanks.last!.rawValue
    }
}
// Cycles: Factory → User A → User B → User C → Factory
```

**Old - previousPosition():**
```swift
if selectedPosition > 1 {
    selectedPosition -= 1
} else {
    selectedPosition = 5
}
// Simple 1-5 cycle
```

**New - previousPosition():**
```swift
if selectedColumn > 1 {
    selectedColumn -= 1
} else if selectedRow > 1 {
    selectedColumn = 5
    selectedRow -= 1
} else {
    selectedRow = 5
    selectedColumn = 5
}
// Navigates through 5×5 grid:
// 1.1 → 1.2 → 1.3 → 1.4 → 1.5 → 2.1 → 2.2 → ... → 5.5 → 1.1
```

### 4. PresetManager Method Calls Updated

**Old:**
```swift
private var currentSlotPreset: AudioParameterSet? {
    return presetManager.preset(
        forBank: selectedBank, 
        position: selectedPosition, 
        type: selectedType
    )
}

private var canOverwriteCurrentSlot: Bool {
    guard selectedType == .user else { return false }
    return currentSlotPreset != nil
}
```

**New:**
```swift
private var currentSlotPreset: AudioParameterSet? {
    return presetManager.preset(
        forBankType: selectedBankType, 
        row: selectedRow, 
        column: selectedColumn
    )
}

private var canOverwriteCurrentSlot: Bool {
    guard selectedBankType.isUserBank else { return false }
    return currentSlotPreset != nil
}
```

### 5. Save/Load Logic Updated

**Old:**
```swift
private func handleLoadOrSave() {
    if let preset = currentSlotPreset {
        presetManager.loadPreset(preset)
        showAlert("Loaded preset '\(preset.name)'")
    } else {
        if selectedType == .factory {
            showAlert("Cannot save to factory slots. Switch to user banks (U1-U5).")
        } else {
            showingSaveDialog = true
        }
    }
}

private func handleSave() {
    // ...
    let newPreset = try presetManager.saveCurrentAsNewPreset(name: newPresetName)
    try presetManager.assignPresetToSlot(
        preset: newPreset, 
        bank: selectedBank, 
        position: selectedPosition
    )
    showAlert("Saved preset '\(newPresetName)' to \(selectedType == .factory ? "F" : "U")\(selectedBank).\(selectedPosition)")
    // ...
}
```

**New:**
```swift
private func handleLoadOrSave() {
    if let preset = currentSlotPreset {
        presetManager.loadPreset(preset)
        showAlert("Loaded preset '\(preset.name)'")
    } else {
        if selectedBankType.isFactoryBank {
            showAlert("Cannot save to factory bank. Switch to User A, User B, or User C.")
        } else {
            showingSaveDialog = true
        }
    }
}

private func handleSave() {
    // ...
    let newPreset = try presetManager.saveCurrentAsNewPreset(name: newPresetName)
    try presetManager.assignPresetToSlot(
        preset: newPreset, 
        bankType: selectedBankType, 
        row: selectedRow, 
        column: selectedColumn
    )
    showAlert("Saved preset '\(newPresetName)' to \(selectedBankType.displayName) \(selectedRow).\(selectedColumn)")
    // ...
}
```

## User Experience Changes

### Bank Navigation
- **Old:** 10 banks to cycle through (F1-F5, U1-U5)
- **New:** 4 banks to cycle through (Factory, User A, User B, User C)
- **Result:** Faster bank switching, clearer naming

### Slot Display
- **Old:** "F2.3: My Preset" or "U4.1 - Empty"
- **New:** Bank shown separately as "USER B", slot shown as "2.3: My Preset"
- **Result:** Cleaner display, bank name more prominent

### Grid Navigation
- **Old:** Position 1-5 (simple linear)
- **New:** Grid navigation through 5×5 matrix (row.column)
- **Result:** More logical navigation through 25 slots per bank

### Error Messages
- **Old:** "Cannot save to factory slots. Switch to user banks (U1-U5)."
- **New:** "Cannot save to factory bank. Switch to User A, User B, or User C."
- **Result:** Clearer instructions matching new bank names

## Testing Checklist

- [ ] Bank navigation cycles through all 4 banks correctly
- [ ] Position navigation moves through 5×5 grid (1.1 to 5.5)
- [ ] Bank name displays correctly (FACTORY, USER A, USER B, USER C)
- [ ] Slot position displays correctly (1.1, 2.3, 5.5, etc.)
- [ ] Loading presets from different banks works
- [ ] Saving presets to user banks works
- [ ] Cannot save to factory bank (shows correct error)
- [ ] Overwrite function only available for user banks
- [ ] Export function works for all banks
- [ ] Import function works correctly
- [ ] App storage persists bank and position across app restarts

## Migration Notes for Users

When users first open the updated app:
- Their previous bank/position selection will be reset to Factory 1.1
- This is expected behavior due to the AppStorage key changes
- Existing presets in UserLayout.json may need to be remapped or recreated
