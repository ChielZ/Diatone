# Preset Overwrite Feature

## Overview

The preset system now supports **overwriting existing presets** for iterative sound design workflows.

---

## User Workflow

### **Before (Limited):**
1. Edit a sound
2. Save to slot U1.1 → Creates "Sound v1"
3. Tweak the sound more
4. Want to update? → ❌ No option!
5. Had to: Delete → Save new → Reassign to slot

### **After (Improved):**
1. Edit a sound
2. Save to slot U1.1 → Creates "Sound v1"
3. Tweak the sound more
4. Press "OVERWRITE PRESET" → ✅ Updates in place!
5. Slot still has "Sound v1" but with new parameters

---

## UI Changes

### **Row 8: DELETE → OVERWRITE**

**Before:**
- Row 8: "DELETE PRESET" button
- Removed preset from slot and disk

**After:**
- Row 8: "OVERWRITE PRESET" button
- Updates preset with current parameters
- Keeps same name, UUID, slot assignment

**Why:**
- Overwrite is more useful for sound design
- Deletion was rarely needed (users can just overwrite with something else)
- Matches DAW workflow (save over existing project)

---

## Button Behavior

### **Row 5: LOAD/SAVE (Unchanged)**

**Empty Slot:**
- Shows: "SAVE PRESET"
- Action: Opens dialog, creates new preset

**Occupied Slot:**
- Shows: "LOAD PRESET"
- Action: Loads preset to current sound

### **Row 8: OVERWRITE (New)**

**Factory Slot (F1-F5):**
- Button disabled/hidden
- Cannot overwrite read-only presets

**Empty User Slot:**
- Button disabled/hidden
- Nothing to overwrite

**Occupied User Slot:**
- Button enabled
- Shows: "OVERWRITE PRESET"
- Action: Updates preset in place

---

## Technical Implementation

### **How Overwriting Works:**

1. **Same UUID**: Preset keeps its unique identifier
2. **Same file**: Updates existing JSON file on disk
3. **Same name**: Preset name doesn't change
4. **New parameters**: All sound parameters updated
5. **Same slot**: Slot assignment stays the same

### **File System:**
```
UserPresets/
├── A1B2C3D4-...-...json  → Updated in place ✅
├── E5F6G7H8-...-...json
└── UserLayout.json
```

### **Code Flow:**

```swift
// User presses "OVERWRITE PRESET"
func handleOverwrite() {
    let currentPreset = currentSlotPreset // Get preset from slot
    presetManager.updatePreset(currentPreset) // Update with current params
    // ✅ Same UUID, same file, same slot, new sound
}

// In PresetManager
func updatePreset(_ preset: AudioParameterSet) throws {
    // Capture current parameters
    paramManager.captureCurrentAsBase()
    
    // Create updated preset with SAME UUID
    let updated = AudioParameterSet(
        id: preset.id, // ← Same ID!
        name: preset.name, // ← Same name
        voiceTemplate: paramManager.voiceTemplate, // New sound
        master: paramManager.master, // New params
        macroState: paramManager.macroState, // New state
        createdAt: preset.createdAt // Original date
    )
    
    // Save (overwrites file)
    try savePreset(updated)
}
```

---

## Examples

### **Example 1: Iterative Design**

1. Create a pad sound → Save to U1.1 as "Warm Pad"
2. Tweak filter → Press "OVERWRITE" → U1.1 still shows "Warm Pad"
3. Adjust envelope → Press "OVERWRITE" → Still "Warm Pad"
4. Result: Incremental improvements to same preset

### **Example 2: Factory Preset**

1. Navigate to F1.1 (factory preset)
2. Row 8 button is **disabled** (grayed out)
3. Cannot overwrite factory presets
4. Must save as new user preset instead

### **Example 3: Empty Slot**

1. Navigate to U2.3 (empty)
2. Row 5: "SAVE PRESET" (create new)
3. Row 8: **disabled** (nothing to overwrite)

### **Example 4: Performance Tweaking**

1. Load preset "Bright Lead" from U3.2
2. During performance, move macros, adjust filter
3. Like the changes? Press "OVERWRITE"
4. Next time you load U3.2, it has your improvements

---

## Confirmation Dialog

**Alert shows:**
```
Overwrite Preset

Overwrite 'Warm Pad' with current sound?
This cannot be undone.

[Cancel]  [Overwrite]
```

**Why confirmation?**
- Destructive action (replaces preset permanently)
- No undo available
- User should be intentional

---

## Comparison: Delete vs. Overwrite

### **Delete (Removed):**
- Removes preset from disk
- Clears slot assignment
- Preset is gone forever
- **Rarely needed** in practice

### **Overwrite (Added):**
- Updates preset on disk
- Keeps slot assignment
- Preset evolves with your sound
- **Commonly needed** for sound design

**Why remove delete?**
- Overwrite serves the same purpose (just save something else over it)
- Simpler UI (one less button to explain)
- Less destructive workflow (can't accidentally delete)
- If user wants to "delete," they can save a new preset over it

---

## Safety Features

### **Cannot Overwrite Factory Presets:**
```swift
guard userPresets.contains(where: { $0.id == preset.id }) else {
    throw PresetError.cannotUpdateFactoryPreset
}
```

### **Confirmation Required:**
- User must confirm overwrite action
- Prevents accidental updates

### **Creation Date Preserved:**
```swift
createdAt: preset.createdAt // Keep original date
```
- Shows when preset was first created
- Helpful for organizing/sorting

---

## User Mental Model

### **Workflow:**
1. **Create** → "SAVE PRESET" on empty slot
2. **Iterate** → "OVERWRITE PRESET" on same slot
3. **Use** → "LOAD PRESET" when needed
4. **Share** → "EXPORT PRESET" to send to others

### **Analogy:**
Like a DAW project file:
- Save → Creates new file
- Save (again) → Overwrites same file
- Load → Opens file
- Export → Share with others

---

## Future Enhancements (Optional)

### **Possible Additions:**

1. **Rename Preset:**
   - Edit preset name without changing sound
   - Useful for organization

2. **Duplicate Preset:**
   - Copy preset to new slot
   - Create variations without losing original

3. **Undo/History:**
   - Keep previous versions
   - Revert accidental overwrites

4. **Preset Versions:**
   - "Warm Pad v1", "Warm Pad v2"
   - Automatic versioning

5. **Delete Option:**
   - Add back as separate action
   - "Clear Slot" or "Delete Preset" in menu

---

## Summary

✅ **Added:** "OVERWRITE PRESET" button  
✅ **Removed:** "DELETE PRESET" button  
✅ **Behavior:** Updates preset in place with current sound  
✅ **Safety:** Factory presets protected, confirmation required  
✅ **Workflow:** Supports iterative sound design  

This matches professional synthesizer workflows and makes preset management more intuitive! 🎵
