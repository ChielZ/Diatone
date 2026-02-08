# Preset Overwrite with Rename Feature

## Overview

The overwrite feature now includes an integrated rename function - providing a streamlined "two birds with one stone" workflow.

---

## User Experience

### **Before:**
- Overwrite → Confirmation dialog → Done
- No way to rename presets

### **After:**
- Overwrite → Dialog with **pre-filled name** → Edit if desired → Update
- Doubles as a rename function!

---

## Workflow Examples

### **Example 1: Quick Overwrite (Same Name)**

1. Load preset "Warm Pad" from U1.1
2. Tweak filter and envelope
3. Tap "OVERWRITE PRESET"
4. Dialog shows: "Warm Pad" (pre-filled)
5. Just tap "Update" → Done!

**Result:** Same name, updated sound

---

### **Example 2: Overwrite + Rename**

1. Load preset "Test Sound" from U2.3
2. Perfect the sound after tweaking
3. Tap "OVERWRITE PRESET"
4. Dialog shows: "Test Sound" (pre-filled)
5. Edit to: "Epic Lead"
6. Tap "Update"

**Result:** New name, updated sound, same slot

---

### **Example 3: Pure Rename (No Sound Changes)**

1. Load preset "asdf" from U3.1 (bad name!)
2. Don't change anything
3. Tap "OVERWRITE PRESET"
4. Dialog shows: "asdf" (pre-filled)
5. Edit to: "Soft Bells"
6. Tap "Update"

**Result:** Better name, same sound, same slot

---

## Dialog Behavior

### **Save Dialog (Empty Slot):**
```
Title: "Save Preset"
Header: "Name your sound"
TextField: [empty] ← User types new name
Buttons: [Save] [Cancel]
```

### **Overwrite Dialog (Occupied Slot):**
```
Title: "Update Preset"
Header: "Update your sound"
Footer: "You can rename the preset or keep the same name."
TextField: [Current Name] ← Pre-filled, editable
Buttons: [Update] [Cancel]
```

**Key difference:** Overwrite pre-fills the current preset name!

---

## Technical Implementation

### **UI Flow:**

```swift
// When OVERWRITE button is tapped:
.onTapGesture {
    // Pre-fill the text field with current preset name
    if let preset = currentSlotPreset {
        newPresetName = preset.name  // ← Pre-fill!
    }
    showingOverwriteDialog = true
}
```

### **PresetManager:**

```swift
// Updated function signature:
func updatePreset(_ preset: AudioParameterSet, newName: String? = nil) throws -> AudioParameterSet {
    // Use new name if provided, otherwise keep original
    let finalName = newName ?? preset.name
    
    // Create updated preset with potentially new name
    let updatedPreset = AudioParameterSet(
        id: preset.id, // Same UUID
        name: finalName, // New or original name
        voiceTemplate: paramManager.voiceTemplate, // New sound
        master: paramManager.master,
        macroState: paramManager.macroState,
        createdAt: preset.createdAt // Original date
    )
    
    // Save (overwrites file)
    try savePreset(updatedPreset)
}
```

---

## Benefits

### **1. Streamlined Workflow**
- One button, two functions (overwrite + rename)
- No separate "Rename" UI needed
- Fewer taps for common operations

### **2. Flexible**
- Keep name → Just tap "Update"
- Change name → Edit first, then "Update"
- Cancel → No changes made

### **3. Intuitive**
- Pre-filled name shows current state
- Clear what will happen
- Edit field makes rename obvious

### **4. Safe**
- Can review name before confirming
- Clear cancel option
- Name validation (can't be empty)

---

## Comparison to Alternatives

### **Alternative 1: Separate Rename Button**
- ❌ Extra UI element
- ❌ More buttons to explain
- ❌ Extra tap for rename
- ✅ Slightly more explicit

### **Alternative 2: Confirmation Dialog (Previous)**
- ❌ Can't rename
- ❌ Simple yes/no only
- ✅ Faster if name never changes
- ❌ Need separate rename function

### **Current Approach: Integrated Dialog** ✅
- ✅ Two functions in one
- ✅ Still quick (tap Update if no rename)
- ✅ Clear and flexible
- ✅ Matches professional software (DAWs, etc.)

---

## UI Polish Details

### **Text Field:**
- Pre-filled with current name
- Cursor at end for easy editing
- Auto-capitalization for better names
- Full keyboard available

### **Footer Text:**
- Hints that rename is optional
- Clarifies dual purpose
- Friendly guidance

### **Button States:**
- "Update" disabled if name is empty
- Prevents invalid state
- Visual feedback on what's allowed

---

## User Mental Model

### **Overwrite = Update Everything:**
- Sound parameters → Update
- Preset name → Update (if changed)
- File on disk → Update
- Slot assignment → Stays same
- Creation date → Stays same
- UUID → Stays same

### **Use Cases:**
1. **Iterative design:** Overwrite with same name multiple times
2. **Fix bad names:** Rename "asdf" → "Beautiful Pad"
3. **Version naming:** "Lead v1" → "Lead v2"
4. **Finalize sounds:** "Test" → "Epic Brass"

---

## Summary

✅ **Overwrite button opens dialog with pre-filled name**  
✅ **Edit name or keep it → tap Update**  
✅ **Doubles as rename function**  
✅ **Streamlined, intuitive, professional**  

This matches the workflow of professional DAWs and synthesizer plugins - when you "Save" over an existing project, you can change the name in the save dialog. Perfect! 🎵
