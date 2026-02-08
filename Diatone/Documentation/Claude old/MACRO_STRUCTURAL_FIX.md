//
//  MACRO_STRUCTURAL_FIX.md
//  Pentatone
//
//  Created by Chiel Zwinkels on 02/01/2026.
//

# Macro Control Structural Fix

## Problem

The original implementation had hardcoded default values in `MacroControlState.default`:

```swift
static let `default` = MacroControlState(
    baseModulationIndex: 1.0,
    baseFilterCutoff: 1200.0,
    baseFilterSaturation: 2.0,
    baseDelayFeedback: 0.5,
    // ... etc
)
```

**This was problematic because:**
1. If parameter defaults changed, macro state defaults wouldn't automatically update
2. The values were duplicated in two places (parameters and macro state)
3. It was fragile and error-prone to maintain

## Solution

The `MacroControlState` now derives its default values from the actual parameters:

```swift
/// Initialize macro state from current parameters
init(from voiceParams: VoiceParameters, masterParams: MasterParameters) {
    self.baseModulationIndex = voiceParams.oscillator.modulationIndex
    self.baseFilterCutoff = voiceParams.filter.cutoffFrequency
    self.baseFilterSaturation = voiceParams.filter.saturation
    self.baseDelayFeedback = masterParams.delay.feedback
    self.baseDelayMix = masterParams.delay.dryWetMix
    self.baseReverbFeedback = masterParams.reverb.feedback
    self.baseReverbMix = masterParams.reverb.balance
    self.basePreVolume = masterParams.output.preVolume
    
    // Initialize positions
    self.volumePosition = masterParams.output.preVolume
    self.tonePosition = 0.0
    self.ambiencePosition = 0.0
}

static let `default` = MacroControlState(
    from: VoiceParameters.default,
    masterParams: MasterParameters.default
)
```

## Benefits

1. **Single Source of Truth**: Parameter defaults are defined in one place only
2. **Automatic Consistency**: Changing parameter defaults automatically updates macro state defaults
3. **Explicit Initialization**: The initializer makes it clear where values come from
4. **Type Safety**: The compiler ensures all parameters are accounted for

## Updated API

### `captureBaseValues()`
Now creates a fresh `MacroControlState` from current parameters:

```swift
func captureBaseValues() {
    // Create a fresh macro state from current parameters
    macroState = MacroControlState(from: voiceTemplate, masterParams: master)
}
```

**When to use:**
- After loading a preset
- When you want to reset macros to neutral and use current parameters as baseline

### `syncMacroBaseValues()` (NEW)
Updates base values without resetting macro positions:

```swift
func syncMacroBaseValues() {
    macroState.baseModulationIndex = voiceTemplate.oscillator.modulationIndex
    macroState.baseFilterCutoff = voiceTemplate.filter.cutoffFrequency
    // ... etc
    // Note: positions are NOT reset
}
```

**When to use:**
- When user directly edits parameters and you want macros to continue working relative to new values
- When you want to update the baseline but preserve macro positions

## Initialization Flow

### App Startup
```swift
// AudioParameterManager initializes with defaults
private(set) var master: MasterParameters = .default
private(set) var voiceTemplate: VoiceParameters = .default
private(set) var macroState: MacroControlState = .default

// MacroControlState.default is automatically derived from parameter defaults
// So everything is consistent from the start
```

### Loading a Preset
```swift
func loadPreset(_ preset: AudioParameterSet) {
    voiceTemplate = preset.voiceTemplate
    master = preset.master
    macroState = preset.macroState  // Loads saved macro state
    
    applyAllParameters()
}

// Then optionally:
AudioParameterManager.shared.captureBaseValues()  // Resets macros to neutral
```

### Direct Parameter Edit
```swift
// User changes delay feedback in advanced editor
AudioParameterManager.shared.updateDelayFeedback(0.7)

// Option 1: Keep macro positions, update baseline
AudioParameterManager.shared.syncMacroBaseValues()

// Option 2: Reset macros to neutral with new baseline
AudioParameterManager.shared.captureBaseValues()
```

## Preset Compatibility

Old presets with hardcoded macro state values will still load correctly thanks to the Codable initializer:

```swift
init(baseModulationIndex: Double, baseFilterCutoff: Double, ...) {
    self.baseModulationIndex = baseModulationIndex
    // ... all properties
}
```

This ensures backward compatibility with any saved presets.

## Testing

After this change:

1. **Default state matches**: `MacroControlState.default` base values should exactly match parameter defaults
2. **App startup**: Everything initializes consistently
3. **Preset loading**: Macro state is properly restored from preset
4. **Parameter changes**: Can choose to reset or preserve macro positions
5. **Future changes**: Changing parameter defaults automatically updates macro defaults

## Code Quality Improvements

✅ **Removed duplication**: No more hardcoded values in two places  
✅ **Clear intent**: Initializer shows exactly where values come from  
✅ **Type safety**: Compiler catches missing parameters  
✅ **Maintainability**: Single place to change defaults  
✅ **Flexibility**: Two methods for different use cases (`captureBaseValues` vs `syncMacroBaseValues`)

This is a much more robust foundation for the macro control system!
