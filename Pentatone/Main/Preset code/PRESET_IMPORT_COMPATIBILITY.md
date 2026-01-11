# Preset Import Compatibility Guide

## The Issue

After restructuring the preset system, **preset files created with the old version of the app cannot be imported** into the new version. This is because the preset JSON files contain parameter structures that may have changed.

### What's Actually Incompatible?

There are **two separate files** involved:

1. **`UserLayout.json`** - Tracks which presets are assigned to which slots in User A/B/C/D banks
   - Location: `Documents/UserPresets/UserLayout.json`
   - **This IS incompatible** with the old structure (changed from 5 user banks to 3, now 4 user banks)

2. **Individual preset files** (e.g., `My-Cool-Sound.json`) - The actual preset data
   - Location: `Documents/UserPresets/*.json`
   - **May be incompatible** if parameter structures changed between versions

### Why Imports Fail

When you try to import a preset, Swift's `JSONDecoder` tries to decode the entire `AudioParameterSet` structure, which includes:

```swift
struct AudioParameterSet: Codable {
    var id: UUID
    var name: String
    var voiceTemplate: VoiceParameters
    var master: MasterParameters
    var macroState: MacroControlState
    var createdAt: Date
}
```

If **any** property in this structure (or nested structures like `VoiceParameters`, `OscillatorParameters`, `FilterParameters`, etc.) has:
- Changed names
- Been added or removed
- Changed types

...then the entire decode operation fails, and the import is rejected.

## Solutions

### Option 1: Clean Slate (Quickest)

**Delete the app and reinstall** to start fresh with the new preset structure.

**Pros:**
- Guaranteed to work
- No file system cleanup needed
- Fresh start with new structure

**Cons:**
- Lose all existing user presets created on that device
- Lose any slot assignments in User A/B/C/D banks

**How to do it:**
1. Delete the app from your iPad
2. Reinstall from Xcode or TestFlight
3. Import will now work for presets created with the new version

### Option 2: Manual File Cleanup (If you want to keep some files)

If you have important data on the device, you can manually clean up incompatible files:

1. **Remove UserLayout.json**
   - Path: `Documents/UserPresets/UserLayout.json`
   - This will reset all slot assignments
   - The app will create a new empty layout on next launch

2. **Remove old preset files** (if they're incompatible)
   - Path: `Documents/UserPresets/*.json` (but NOT UserLayout.json)
   - Delete individual preset files that were created with the old app version
   - Keep any that were created with the new version

### Option 3: Add Version-Aware Migration (Advanced)

For future compatibility, you could add versioning to preset files:

```swift
struct AudioParameterSet: Codable {
    var id: UUID
    var name: String
    var version: Int  // Add this
    var voiceTemplate: VoiceParameters
    var master: MasterParameters
    var macroState: MacroControlState
    var createdAt: Date
}
```

Then in the import function, check the version and apply migrations as needed. This is more work but provides a smoother upgrade path for users.

## What I've Done

I've updated `PresetManager.swift` to:

1. **Add detailed error logging** - When a preset import fails, the console will now show exactly which property caused the decoding failure

2. **Add a specific error case** - `PresetError.incompatibleFormat` that provides a user-friendly message

3. **Better error messages** - Instead of cryptic decoding errors, users see: "This preset was created with an older version of the app and cannot be imported. The preset format has changed."

## Testing the Fix

After rebuilding your app:

1. **Try importing a preset** created with the old version
2. **Check the Xcode console** - You'll see detailed error information like:
   ```
   ❌ PresetManager: Failed to decode preset from My-Preset.json
      Error: ...
      Missing key: 'userDSlots' at path: ...
   ```
3. **User sees** a friendly error message instead of a crash

## Recommendation

For your specific situation:

**Just delete and reinstall the app on your iPad.** Since you mentioned "These are now gone. This is not a problem," it sounds like you don't have critical presets to preserve from the old version.

After reinstalling:
- Import will work for new presets
- You'll have the new User A/B/C/D bank structure
- Everything will be compatible going forward

## Preventing Future Issues

To avoid this in the future:

1. **Add versioning to presets** (see Option 3 above)
2. **Test imports** after making structural changes to parameter types
3. **Consider backward compatibility** when adding/removing properties from `Codable` structures
4. **Use optional properties** with default values where possible:
   ```swift
   var newFeature: Bool = false  // Won't break old presets
   ```

## Summary

**The note about UserLayout.json incompatibility is correct**, but the import failure is likely due to the **preset files themselves** being incompatible, not the layout file.

**Quick fix:** Delete and reinstall the app on your iPad.

**Now with better errors:** After my changes, you'll see helpful error messages in the console and to the user when imports fail due to incompatible formats.
