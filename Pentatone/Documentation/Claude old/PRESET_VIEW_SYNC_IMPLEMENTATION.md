# Preset View Synchronization Implementation

## Overview
This document describes the implementation of synchronization between SoundView and PresetView to improve the user experience when navigating between these two preset interfaces.

## Problem Statement
Previously, when a user switched from SoundView to EditView (PresetView), the PresetView would show the last navigated preset position, even if that preset wasn't actually loaded. This created confusion because:

1. Users could see a different preset in PresetView than the one currently playing
2. The "active" preset and the "displayed" preset were out of sync
3. Users had to manually navigate PresetView to find which preset was actually loaded

## Solution
When a user taps the preset name in SoundView to switch to EditView, the PresetView now automatically syncs to display the currently active preset.

## Implementation Details

### Key Changes to `V3-S2 SoundView.swift`

#### 1. Added PresetView Storage References
```swift
// PresetView's @AppStorage properties - update these when switching to EditView
@AppStorage("presetView.selectedRow") private var presetViewSelectedRow: Int = 1
@AppStorage("presetView.selectedColumn") private var presetViewSelectedColumn: Int = 1
```

These properties provide direct access to PresetView's selection state through AppStorage.

#### 2. Added Synchronization Function
```swift
/// Synchronize PresetView to show the currently active preset
private func syncPresetViewToCurrentPreset() {
    // Update PresetView's selection to match SoundView's current selection
    presetViewSelectedRow = selectedRow
    presetViewSelectedColumn = selectedColumn
    // Note: selectedBankTypeRawValue is already shared between both views
}
```

This function updates PresetView's row and column to match the currently active preset in SoundView.

#### 3. Updated Preset Name Tap Handler
```swift
.onTapGesture {
    // Sync PresetView to show the currently active preset
    syncPresetViewToCurrentPreset()
    onSwitchToEdit?()
}
```

When the user taps the preset name, PresetView is synchronized BEFORE switching to EditView.

## How It Works

### Data Flow

1. **SoundView maintains its active preset position:**
   - `selectedRow` and `selectedColumn` track which preset is currently loaded
   - These values persist via `@AppStorage("soundView.selectedRow")` and `@AppStorage("soundView.selectedColumn")`

2. **PresetView maintains its browsing position:**
   - `selectedRow` and `selectedColumn` (in PresetView) track where the user is browsing
   - These values persist via `@AppStorage("presetView.selectedRow")` and `@AppStorage("presetView.selectedColumn")`
   - Users can navigate without loading presets

3. **Bank selection is shared:**
   - Both views use `@AppStorage("presetView.selectedBankTypeRawValue")` 
   - Changing banks in either view affects both

4. **Synchronization on view switch:**
   - When tapping the preset name in SoundView, `syncPresetViewToCurrentPreset()` is called
   - This copies SoundView's active position to PresetView's browsing position
   - PresetView opens showing the currently active preset

### User Experience Flow

#### Before Implementation:
```
User in SoundView → Preset 2.3 is loaded and playing
User taps preset name to open EditView
PresetView opens → Shows 4.5 (last browsed position)
User is confused: "Why does it show 4.5 when 2.3 is playing?"
```

#### After Implementation:
```
User in SoundView → Preset 2.3 is loaded and playing
User taps preset name to open EditView
syncPresetViewToCurrentPreset() is called → PresetView position set to 2.3
PresetView opens → Shows 2.3 (currently active preset)
User sees the correct preset and can now navigate to others if desired
```

## Preserving Existing Behavior

### What Still Works as Before:

1. **PresetView navigation doesn't auto-load:**
   - Users can still browse through presets without loading them
   - Only the "LOAD PRESET" button actually loads a preset

2. **Bidirectional sync when loading:**
   - When a preset is loaded from PresetView, SoundView's selection is updated
   - This was already implemented in PresetView's `handleLoadOrSave()` function

3. **Bank selection remains shared:**
   - Both views continue to share the selected bank via AppStorage

## Benefits

1. **Reduced confusion:** Users always see the active preset when opening EditView
2. **Maintains flexibility:** Users can still browse without loading once in PresetView
3. **Seamless workflow:** Natural transition from quick preset selection to detailed editing
4. **Minimal code change:** Simple synchronization call before view switch

## Testing Recommendations

1. **Basic sync test:**
   - Load preset 1.1 in SoundView
   - Tap preset name to open EditView
   - Verify PresetView shows 1.1

2. **Different bank test:**
   - Switch to User A bank
   - Load preset 3.4
   - Tap preset name
   - Verify PresetView shows 3.4 in User A bank

3. **Browse without loading test:**
   - In PresetView, navigate to 5.5 (don't load it)
   - Return to SoundView (2.3 still playing)
   - Tap preset name again
   - Verify PresetView shows 2.3 (not 5.5)

4. **Load from PresetView test:**
   - Open PresetView (should show currently active preset)
   - Navigate to different preset
   - Load it
   - Return to SoundView
   - Verify SoundView shows the newly loaded preset

## Notes

- The synchronization is one-way at the moment of view switch: SoundView → PresetView
- The existing bidirectional sync when loading remains: both views track the loaded preset
- Both views maintain independent navigation while visible
- AppStorage ensures persistence across app sessions

## Date
Implementation completed: January 30, 2026
