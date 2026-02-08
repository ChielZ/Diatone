# Transparent Preset Migration - How It Works

## Overview

The loudness envelope migration is now **completely transparent**. Old preset files remain unchanged, and the mapping between `envelope` and `loudnessEnvelope` happens automatically during load/save.

## Key Principle

**Preset files never change format** - they always use the old `envelope` structure. The app handles the conversion internally.

## How It Works

### Loading a Preset (Decoding)

**Old Preset File:**
```json
{
  "voiceTemplate": {
    "envelope": {
      "attackDuration": 0.005,
      "decayDuration": 0.5,
      "sustainLevel": 1.0,
      "releaseDuration": 0.1
    }
  }
}
```

**What Happens:**
1. Swift decodes the preset using `VoiceParameters.init(from decoder:)`
2. Reads `envelope` field from JSON
3. Automatically converts to `modulation.loudnessEnvelope`
4. Result: App uses `loudnessEnvelope` internally, but preset file stays unchanged

**Code:**
```swift
init(from decoder: Decoder) throws {
    // ... decode other fields ...
    
    envelope = try container.decode(EnvelopeParameters.self, forKey: .envelope)
    var modulation = (try? container.decode(...)) ?? .default
    
    // CRITICAL: Sync loudness envelope from envelope field
    modulation.loudnessEnvelope = envelope.toLoudnessEnvelope()
    
    self.modulation = modulation
}
```

### Saving a Preset (Encoding)

**What Happens:**
1. Swift encodes the preset using `VoiceParameters.encode(to encoder:)`
2. Converts `modulation.loudnessEnvelope` back to `envelope` format
3. Writes `envelope` field to JSON
4. Result: Preset file stays in old format, compatible with all versions

**Code:**
```swift
func encode(to encoder: Encoder) throws {
    // ... encode other fields ...
    
    // CRITICAL: Convert loudnessEnvelope back to envelope for saving
    let envelopeForSaving = EnvelopeParameters(
        attackDuration: modulation.loudnessEnvelope.attack,
        decayDuration: modulation.loudnessEnvelope.decay,
        sustainLevel: modulation.loudnessEnvelope.sustain,
        releaseDuration: modulation.loudnessEnvelope.release
    )
    try container.encode(envelopeForSaving, forKey: .envelope)
    
    try container.encode(modulation, forKey: .modulation)
}
```

### UI Updates

**What Happens:**
1. UI changes `voiceTemplate.loudnessEnvelope.attack = 0.05`
2. Computed property syncs: `envelope.attackDuration = 0.05`
3. Both fields stay in sync automatically

**Code:**
```swift
var loudnessEnvelope: LoudnessEnvelopeParameters {
    get { modulation.loudnessEnvelope }
    set { 
        modulation.loudnessEnvelope = newValue
        // Keep envelope field in sync
        envelope = EnvelopeParameters(
            attackDuration: newValue.attack,
            decayDuration: newValue.decay,
            sustainLevel: newValue.sustain,
            releaseDuration: newValue.release
        )
    }
}
```

## Benefits

✅ **Old presets load perfectly** - no migration needed  
✅ **New presets save in old format** - maximum compatibility  
✅ **No data loss** - envelope values are preserved  
✅ **No version tracking** - format never changes  
✅ **Rollback friendly** - can revert code changes without breaking presets  

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESET FILE (JSON)                        │
│  {                                                           │
│    "envelope": {                                             │
│      "attackDuration": 0.005,                                │
│      "decayDuration": 0.5,                                   │
│      "sustainLevel": 1.0,                                    │
│      "releaseDuration": 0.1                                  │
│    }                                                         │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │
                              │ encode/decode
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              VoiceParameters (In Memory)                     │
│                                                              │
│  var envelope: EnvelopeParameters  ◄────┐                   │
│     ↓ (synced via custom Codable)       │ (synced via      │
│  var modulation: VoiceModulationParams   │  computed prop)  │
│    └─ loudnessEnvelope ◄─────────────────┘                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 Audio Engine (Runtime)                       │
│                                                              │
│  Uses: modulation.loudnessEnvelope                          │
│    ↓                                                         │
│  Fader control (linear attack, exp decay/release)           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Example Scenarios

### Scenario 1: Load Old Preset
```
1. User selects "Vintage Bass" preset (created before update)
2. JSONDecoder calls VoiceParameters.init(from decoder:)
3. Reads envelope: {attack: 0.01, decay: 0.5, sustain: 0.7, release: 0.2}
4. Converts to loudnessEnvelope automatically
5. App uses loudnessEnvelope internally
6. ✅ Sound plays correctly with new fader-based system
```

### Scenario 2: Save New Preset
```
1. User creates "Fat Pad" sound
2. UI updates modulation.loudnessEnvelope
3. User clicks "Save Preset"
4. JSONEncoder calls VoiceParameters.encode(to encoder:)
5. Converts loudnessEnvelope back to envelope format
6. Writes envelope: {attackDuration: 0.1, ...} to JSON
7. ✅ Preset file uses old format, compatible with all versions
```

### Scenario 3: Edit Preset
```
1. Load preset (automatic conversion to loudnessEnvelope)
2. User adjusts attack slider in UI
3. UI sets voiceTemplate.loudnessEnvelope.attack = 0.05
4. Computed property syncs envelope.attackDuration = 0.05
5. Both fields stay in sync
6. ✅ Save/load cycle preserves changes correctly
```

## Testing Checklist

- [x] **Load old preset**: Loads without errors
- [x] **Play old preset**: Sounds correct with new system
- [x] **Save new preset**: Saves in old envelope format
- [x] **Load saved preset**: Loads correctly after save
- [x] **Edit and save**: Changes persist correctly
- [x] **Round-trip test**: Load → Edit → Save → Load → Values match

## What Changed from Previous Version

**Before (v1 - broke presets):**
- Made `envelope` optional
- Tried to migrate to new format on save
- Preset files changed format
- ❌ Old presets couldn't load

**After (v2 - transparent):**
- Keep `envelope` mandatory
- Custom encode/decode handles conversion
- Preset files never change format
- ✅ Old presets load perfectly
- ✅ New presets save in old format

## Implementation Details

### Critical Code Points

1. **VoiceParameters.init(from decoder:)**
   - Location: A1 SoundParameters.swift
   - Purpose: Convert envelope → loudnessEnvelope on load
   - Timing: Every preset load

2. **VoiceParameters.encode(to encoder:)**
   - Location: A1 SoundParameters.swift
   - Purpose: Convert loudnessEnvelope → envelope on save
   - Timing: Every preset save

3. **loudnessEnvelope computed property**
   - Location: A1 SoundParameters.swift
   - Purpose: Keep both fields in sync during UI updates
   - Timing: Every parameter change

### No Changes Needed In:

- ✅ Preset Manager
- ✅ UI Code (already updated to use loudnessEnvelope)
- ✅ JSON files
- ✅ File format version tracking
- ✅ Migration utilities

## Conclusion

This approach is **invisible to the user** and **invisible to the preset system**. The app seamlessly converts between the old `envelope` format (used in files) and the new `loudnessEnvelope` format (used internally) without any manual intervention or file format changes.

**Perfect backward and forward compatibility! 🎉**
