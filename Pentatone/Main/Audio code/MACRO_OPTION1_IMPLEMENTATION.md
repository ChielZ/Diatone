# Macro Control Architecture: Option 1 Implementation

## Date: January 12, 2026

## Problem Identified

The macro control system had an architectural inconsistency where:
- Moving macro sliders would change the displayed parameter values
- But the underlying `macroState.base*` values were NOT being updated
- This caused the tone slider to use stale base values from when presets were loaded
- Result: After manually adjusting a parameter, the tone slider would incorrectly calculate from the old base value

## Decision: Option 1 - "Macros Change Base Values"

After careful analysis, we chose **Option 1** architecture where:

### Core Principle
**"What you hear is what you save"**

### Behavior
1. **Macro slider positions are temporary** (reset to neutral when preset loads)
2. **Macro adjustments change underlying base values** (permanently affect parameters)
3. **Presets save the current sonic state** (not the macro positions)

### Example Workflow
```
1. Load preset: cutoff=1000 Hz, tone position=0.0 (neutral)
   → Hear 1000 Hz

2. Move tone slider to +1.0 (rightmost):
   → Hear 2000 Hz (1000 × 2^(+1.0 × 2 octaves))
   → baseFilterCutoff updated to 2000 Hz
   → tonePosition stays at +1.0

3. Save preset:
   → Saves baseFilterCutoff=2000 Hz
   → Does NOT save tonePosition (it's ephemeral)

4. Load preset again:
   → baseFilterCutoff=2000 Hz
   → tonePosition resets to 0.0 (neutral)
   → Hear 2000 Hz (same as when saved!)

5. Move tone slider to +0.5:
   → Hear 2828 Hz (2000 × 2^(+0.5 × 2 octaves))
   → baseFilterCutoff updated to 2828 Hz
```

## Why Option 1?

### Advantages ✅
- **Intuitive**: Presets sound exactly like they did when saved
- **No lost work**: Your creative explorations are preserved
- **Flexible workflow**: Use macros for both sound design and live performance
- **WYSIWYG**: What you hear is what gets saved

### Alternative (Option 2) Would Have Been Problematic ❌
- User tweaks macro to find perfect sound
- Saves preset
- Loads preset → **completely different sound** (macro offset lost)
- User frustration: "Where did my sound go?!"

## Implementation Changes

### 1. Macro Application Methods
**File: `A7 ParameterManager.swift`**

#### `applyToneMacro()` - Lines ~689-720
```swift
// BEFORE:
let newCutoff = macroState.baseFilterCutoff * octaveMultiplier
updateFilterCutoff(clampedCutoff)  // Only updated voiceTemplate

// AFTER:
let newCutoff = macroState.baseFilterCutoff * octaveMultiplier
// Update base values so current state is saved with presets
macroState.baseModulationIndex = clampedModIndex
macroState.baseFilterCutoff = clampedCutoff
macroState.baseFilterSaturation = clampedSaturation
// Then apply to audio engine
updateModulationIndex(clampedModIndex)
updateFilterCutoff(clampedCutoff)
updateFilterSaturation(clampedSaturation)
```

#### `applyAmbienceMacro()` - Lines ~722-745
```swift
// BEFORE:
let newDelayFeedback = macroState.baseDelayFeedback + offset
updateDelayFeedback(clampedDelayFeedback)  // Only updated master params

// AFTER:
let newDelayFeedback = macroState.baseDelayFeedback + offset
// Update base values so current state is saved with presets
macroState.baseDelayFeedback = clampedDelayFeedback
macroState.baseDelayMix = clampedDelayMix
macroState.baseReverbFeedback = clampedReverbFeedback
macroState.baseReverbMix = clampedReverbMix
// Then apply to audio engine
updateDelayFeedback(clampedDelayFeedback)
// ... etc
```

### 2. Direct Parameter Edit Methods
**File: `A7 ParameterManager.swift`**

All direct parameter edit methods now also update the corresponding macro base values:

#### Tone-Controlled Parameters
- `updateModulationIndex()` → updates `macroState.baseModulationIndex`
- `updateFilterCutoff()` → updates `macroState.baseFilterCutoff`
- `updateFilterSaturation()` → updates `macroState.baseFilterSaturation`

#### Ambience-Controlled Parameters
- `updateDelayFeedback()` → updates `macroState.baseDelayFeedback`
- `updateDelayMix()` → updates `macroState.baseDelayMix`
- `updateReverbFeedback()` → updates `macroState.baseReverbFeedback`
- `updateReverbMix()` → updates `macroState.baseReverbMix`

This ensures consistency: whether you adjust via macro or directly, the base value is always kept in sync.

### 3. Documentation
Added comprehensive header documentation to `AudioParameterManager` class explaining the Option 1 architecture.

## Testing Checklist

### ✅ Basic Macro Behavior
- [ ] Load preset with known parameter values
- [ ] Move tone slider → verify filter cutoff changes correctly
- [ ] Move ambience slider → verify delay/reverb change correctly
- [ ] Macro calculations use correct base values and ranges

### ✅ Preset Save/Load Cycle
- [ ] Load factory preset
- [ ] Adjust tone slider to change sound
- [ ] Save as user preset
- [ ] Load the saved preset
- [ ] Verify: Sound is identical to what was heard when saved
- [ ] Verify: Macro sliders are at neutral position

### ✅ Direct Parameter Edits
- [ ] Load preset with cutoff=1000 Hz
- [ ] Move tone slider to get cutoff=2000 Hz
- [ ] Directly edit filter cutoff to 1500 Hz
- [ ] Move tone slider again
- [ ] Verify: Tone slider now modulates around 1500 Hz (not 1000 Hz)

### ✅ Combination Workflow
- [ ] Load preset
- [ ] Adjust parameters directly on parameter pages
- [ ] Also adjust macro sliders
- [ ] Play notes → verify all modulation sources work correctly
- [ ] Save preset
- [ ] Load preset → verify sound is preserved, macros reset to neutral

### ✅ Edge Cases
- [ ] Macro at extreme position (+1.0 or -1.0) → save/load → verify sound preserved
- [ ] Multiple macro adjustments before saving
- [ ] Switch between presets rapidly
- [ ] Adjust parameters while note is held (verify smooth updates)

## Known Behaviors (By Design)

1. **Macro positions don't save**: When you load a preset, all macro sliders return to neutral (center) position. This is intentional.

2. **Base values change continuously**: As you move macro sliders or edit parameters directly, the `macroState.base*` values are constantly updated. This is correct for Option 1.

3. **No "undo" for macro changes**: Since macro adjustments immediately update base values, there's no built-in way to "undo" a macro adjustment. Users can reload the preset to get back to the original sound.

## Future Considerations

### Potential Enhancement: "Lock" Mode
Could add a toggle to temporarily prevent macro changes from updating base values:
- **Unlocked** (default): Current behavior, macros update base values
- **Locked**: Macros become truly temporary, base values don't change
- Use case: Live performance where you want to explore without committing changes

### Potential Enhancement: Macro Position Indicators
UI could show when macros are at non-neutral positions with visual indicators:
- Macro slider track color changes when not at center
- Small indicator showing current offset amount
- Helps users understand when sound will change on preset reload

## Conclusion

Option 1 implementation provides an intuitive, predictable workflow where:
- Macros are convenient performance/exploration tools
- Sonic changes are always preserved (no lost work)
- Preset behavior is consistent (what you hear is what you save)
- The "temporary" aspect is about UI state (slider position), not sonic changes

This architecture supports both creative sound design and live performance use cases.
