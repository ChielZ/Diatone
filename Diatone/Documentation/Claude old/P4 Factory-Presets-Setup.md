# Factory Presets Directory Setup

## Phase 4 Completion Checklist

This file contains instructions for setting up the factory presets directory structure in your Xcode project.

---

## Directory Structure

Create the following folder structure in your Xcode project:

```
Pentatone/
├── Resources/
│   └── Presets/
│       └── Factory/
│           └── (25 factory preset JSON files will go here)
```

---

## Step-by-Step Setup

### 1. Create the Directory in Finder

1. Open Finder and navigate to your Xcode project folder
2. Find the folder where your app's resources are stored (usually next to your Swift files)
3. Create a new folder called `Resources` (if it doesn't exist)
4. Inside `Resources`, create a folder called `Presets`
5. Inside `Presets`, create a folder called `Factory`

### 2. Add to Xcode Project

1. In Xcode, right-click on your project in the navigator
2. Select **Add Files to "Pentatone"...**
3. Navigate to and select the `Resources` folder you just created
4. **Important**: Make sure these options are selected:
   - ✅ **Create folder references** (NOT "Create groups")
   - ✅ **Add to targets**: Check your app target (Pentatone)
5. Click "Add"

The folder should appear **blue** in Xcode (folder reference), not yellow (group).

### 3. Verify Target Membership

1. Select the `Resources` folder in Xcode
2. Open the File Inspector (right sidebar)
3. Verify "Target Membership" includes your app target

---

## Testing (Before Factory Presets Exist)

Currently, the `Factory` folder is empty, which is fine. The app will:

✅ Load successfully (no factory presets yet)  
✅ Show empty factory slots (F1.1 - F5.5)  
✅ Allow user presets to work normally  

You can test by:
1. Building and running the app
2. Going to PresetView (the sound editing preset panel)
3. Navigating to user banks (U1-U5)
4. Creating and saving user presets

---

## Phase 5: Creating Factory Presets

After you've tested the system, you'll create factory presets:

### Workflow:

1. **On iPad**: Run app, create sounds, save as user presets
2. **Export**: Use "Export Preset" to share via AirDrop/Files
3. **On Mac**: Open exported `.arithmophonepreset` files in a text editor
4. **Copy UUID**: Find the `"id"` field and copy the UUID string
5. **Add to Xcode**: 
   - Rename file to descriptive name (e.g., `Warm Pad.json`)
   - Drag into `Resources/Presets/Factory/` in Xcode
   - Ensure target membership is checked
6. **Update Code**: Add UUID to `PentatoneFactoryLayout.swift`

### Example Factory Layout Update:

```swift
// In P2 PentatonePresetStructures.swift
static var factorySlots: [PentatonePresetSlot] = {
    var slots: [PentatonePresetSlot] = []
    
    // Bank 1
    slots.append(PentatonePresetSlot(
        bank: 1, position: 1,
        presetID: UUID(uuidString: "A1B2C3D4-E5F6-4A5B-6C7D-8E9F0A1B2C3D")!, // Warm Pad
        slotType: .factory
    ))
    slots.append(PentatonePresetSlot(
        bank: 1, position: 2,
        presetID: UUID(uuidString: "B2C3D4E5-F6A7-4B5C-6D7E-8F9A0B1C2D3E")!, // Bright Lead
        slotType: .factory
    ))
    // ... add all 25 factory presets
    
    return slots
}()
```

---

## Factory Preset Guidelines

### File Naming:
- Use descriptive names: `Ethereal Bells.json`, `Warm Pad.json`
- Keep names short but meaningful
- No special characters (stick to letters, spaces, numbers)

### Content Guidelines:
- Each file is a complete `AudioParameterSet` JSON
- Must have unique UUID
- Name should match filename (minus extension)
- Date can be any valid ISO 8601 date

### Organization:
- 5 banks × 5 positions = 25 total factory presets
- Suggested categories:
  - **Bank 1**: Basic sounds (sine, square, triangle variations)
  - **Bank 2**: Pads and atmospheres
  - **Bank 3**: Leads and melodic sounds
  - **Bank 4**: Bells and percussive sounds
  - **Bank 5**: Experimental and FX sounds

---

## Troubleshooting

### "Factory presets not loading"

**Check these:**
1. ✅ Folder is a **blue folder reference**, not yellow group
2. ✅ Target membership is checked for your app
3. ✅ Files have `.json` extension
4. ✅ JSON is valid (run through a validator)
5. ✅ Clean Build Folder (⇧⌘K) and rebuild

### "Cannot find factory presets directory"

The warning message is normal if the folder doesn't exist. Create it following steps above.

### "Factory preset shows as empty slot"

**Check:**
1. UUID in `PentatoneFactoryLayout` matches UUID in JSON file
2. JSON file is in `Resources/Presets/Factory/` folder
3. File is included in build (check target membership)

### "App crashes when loading factory preset"

**Check:**
1. JSON is valid and complete `AudioParameterSet`
2. All required fields are present
3. No extra or misspelled keys
4. Date is valid ISO 8601 format

---

## Current Status

✅ **Phase 1**: Core PresetManager - Complete  
✅ **Phase 2**: Slot System - Complete  
✅ **Phase 3**: UI Integration - Complete  
✅ **Phase 4**: App Initialization & File Types - Complete  
⏳ **Phase 5**: Factory Presets - Pending (create presets on device)  

---

## Next Steps

1. **Build and test** the app with empty factory presets
2. **Test user presets**: Create, save, load, export, import
3. **Test navigation**: Banks, positions, factory/user toggle
4. **Create factory presets** on your iPad/iPhone
5. **Add to Xcode** and update factory layout
6. **Final testing** with complete preset system

---

Good luck! 🎵
