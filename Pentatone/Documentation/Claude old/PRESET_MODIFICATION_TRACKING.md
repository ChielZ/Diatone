# Preset Modification Tracking Implementation

## Overview
This document describes the implementation of visual feedback in PresetView to indicate whether parameters have been modified since a preset was loaded. This helps users understand the relationship between what they see in the UI and what will be saved.

## Problem Statement
Previously, users had no visual indication of whether:
1. The displayed preset was the currently active one
2. Parameters had been modified since loading a preset
3. They were viewing an empty preset slot vs. one with a saved preset

This created confusion when navigating presets and editing parameters.

## Solution
Implemented a color-coded system in PresetView that provides immediate visual feedback about preset state:

### Color Coding System

| Condition | Color | Meaning |
|-----------|-------|---------|
| Active preset, unchanged | `HighlightColour` | Currently loaded, unmodified |
| Active preset, modified | `KeyColour4` | Currently loaded, has changes |
| Different preset, has preset | `KeyColour3` | Not active, slot filled |
| Different preset, empty slot | `KeyColour1` | Not active, slot empty |

## Implementation Details

### 1. AudioParameterManager Changes

#### Added Modification Tracking
```swift
/// Indicates whether parameters have been modified since the last preset load
/// This excludes modulation/envelope changes, only tracks direct UI adjustments
@Published var parametersModifiedSinceLoad: Bool = false

/// Marks parameters as modified (called by parameter update methods)
private func markAsModified() {
    parametersModifiedSinceLoad = true
}

/// Resets the modification flag (called when loading a preset)
private func clearModificationFlag() {
    parametersModifiedSinceLoad = false
}
```

#### Updated All Parameter Update Methods
Added `markAsModified()` calls to all UI-facing parameter update methods, including:
- Master parameters (delay, reverb, output volume, tempo)
- Global pitch parameters (transpose, octave, fine tune)
- Voice template parameters (oscillator, filter, envelopes)
- Modulation parameters (LFOs, envelopes, key tracking, touch response)
- Macro control parameters and positions

**Important:** Macro position updates (`updateVolumeMacro`, `updateToneMacro`, `updateAmbienceMacro`) DO mark as modified because they change the underlying parameter values and affect the sound.

#### Updated Preset Loading
Modified `loadPresetWithFade()` to clear the modification flag after a preset is loaded:
```swift
func loadPresetWithFade(_ preset: AudioParameterSet, completion: (() -> Void)? = nil) {
    // ... load preset ...
    
    // Clear modification flag - preset is now loaded and unmodified
    self.clearModificationFlag()
    
    completion?()
}
```

### 2. PresetView Changes

#### Added Color Computation Logic
Created computed properties to determine text colors based on state:

```swift
private var bankDisplayColor: Color {
    // Check if showing currently active preset
    let isShowingActivePreset = (
        soundViewSelectedRow == selectedRow &&
        soundViewSelectedColumn == selectedColumn &&
        selectedBankTypeRawValue == PentatoneBankType(rawValue: selectedBankTypeRawValue)?.rawValue
    )
    
    if isShowingActivePreset {
        // Active preset - check if modified
        if paramManager.parametersModifiedSinceLoad {
            return Color("KeyColour4") // Modified
        } else {
            return Color("HighlightColour") // Unmodified
        }
    } else {
        // Not the active preset - check if slot has preset
        if currentSlotPreset != nil {
            return Color("KeyColour3") // Different preset, slot filled
        } else {
            return Color("KeyColour1") // Different preset, slot empty
        }
    }
}

private var positionDisplayColor: Color {
    // Same logic as bankDisplayColor
}
```

#### Updated UI to Use Dynamic Colors
Changed the bank and position display text from static `Color("HighlightColour")` to use the computed color properties:

```swift
Text(bankDisplayText)
    .foregroundColor(bankDisplayColor)  // Was: Color("HighlightColour")

Text(positionDisplayText)
    .foregroundColor(positionDisplayColor)  // Was: Color("HighlightColour")
```

## What Counts as a Modification

### Included (marks as modified):
- Any direct parameter adjustment from UI sliders/controls
- Changes from SoundView (macro controls)
- Changes from any EditView subview
- Voice template parameter changes
- Master parameter changes (delay, reverb, volume)
- Global pitch changes (transpose, octave, fine tune)
- Modulation parameter changes (envelopes, LFOs)
- Touch response parameter changes
- **Macro position changes** (volume, tone, ambience sliders)

### Excluded (does NOT mark as modified):
- Real-time modulation from envelopes (loudness, mod, aux)
- Real-time modulation from LFOs (voice, global)
- Key tracking modulation
- Touch/aftertouch modulation
- Any automatic parameter changes from the modulation engine

## User Experience

### Scenario 1: Loading an Unmodified Preset
```
1. User loads preset "Bass 1" from slot 2.3
2. PresetView shows "2.3 Bass 1" in HighlightColour
3. Text remains HighlightColour until user adjusts something
```

### Scenario 2: Modifying a Preset
```
1. User loads preset "Bass 1"
2. User adjusts filter cutoff slider
3. PresetView text changes to KeyColour4 (modified indicator)
4. User knows the sound has changed from the saved preset
```

### Scenario 3: Browsing Other Presets
```
1. User has "Bass 1" (slot 2.3) loaded and modified
2. User navigates to slot 4.1 (has preset "Lead 1")
3. PresetView shows "4.1 Lead 1" in KeyColour3 (different, filled)
4. User navigates to slot 5.5 (empty)
5. PresetView shows "5.5 - Empty" in KeyColour1 (different, empty)
6. User navigates back to 2.3
7. PresetView shows "2.3 Bass 1" in KeyColour4 (active, modified)
```

### Scenario 4: Saving Changes
```
1. User has modified preset (showing KeyColour4)
2. User saves preset (either as new or overwrite)
3. After save, text changes to HighlightColour
   (because saving creates a new unmodified state)
```

## Benefits

1. **Clear State Indication:** Users instantly know if they're viewing the active preset
2. **Modification Awareness:** Color change alerts users when they've modified a preset
3. **Empty Slot Detection:** Distinct color for empty slots
4. **Navigation Context:** Different color for non-active presets helps with navigation

## Technical Notes

### Observable Pattern
The system uses SwiftUI's `@Published` property to automatically update the UI when `parametersModifiedSinceLoad` changes. PresetView observes `AudioParameterManager.shared` and recomputes colors when the flag changes.

### Performance
Color computation is lightweight (simple boolean checks and comparisons). It happens only when the view updates, not on every parameter change.

### Thread Safety
All parameter updates happen on the main thread (`@MainActor`), ensuring thread-safe modification tracking.

## Future Enhancements

Possible improvements:
1. Add visual indication in SoundView as well
2. Show a "save reminder" when leaving a modified preset
3. Add undo/redo support with modification tracking
4. Display which specific parameters were modified
5. Add "revert to saved" functionality

## Date
Implementation completed: January 30, 2026
