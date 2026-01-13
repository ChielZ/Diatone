# Modulation-Aware Parameter Updates

## Overview

This implementation prevents glitchy behavior when adjusting parameters during held notes by making parameter updates aware of active modulation sources.

## Problem

When a user adjusts a parameter (e.g., filter cutoff) while a note is playing and that parameter is being modulated (e.g., by an envelope or LFO), two threads compete:

1. **Main Thread**: UI slider triggers immediate parameter update
2. **Modulation Thread**: Background thread at 200Hz continuously calculates and applies modulation

This causes parameter "fighting" where updates from both threads conflict, resulting in:
- Audible clicks and glitches
- Zipper noise
- Jumpy, unstable parameter behavior

## Solution

Parameter update methods now check if modulation is active before applying changes directly:

### Filter Cutoff (`updateFilterParameters`)

**Modulation sources checked:**
- Auxiliary Envelope → Filter Frequency
- Voice LFO → Filter Frequency
- Key Tracking → Filter Frequency
- Aftertouch → Filter Frequency

**Behavior:**
- Always updates `modulationState.baseFilterCutoff` immediately
- If modulation is active AND voice is playing: skip direct parameter application
- If no modulation OR voice not playing: apply parameter directly
- Modulation system picks up new base value at next cycle (5ms)

### Modulation Index (`updateOscillatorParameters`)

**Modulation sources checked:**
- Modulator Envelope → Modulation Index
- Voice LFO → Modulator Level
- Aftertouch → Modulator Level

**Behavior:**
- Always updates `modulationState.baseModulationIndex` immediately
- If modulation is active AND voice is playing: skip direct parameter application
- If no modulation OR voice not playing: apply parameter directly

### Modulator Multiplier (`updateOscillatorParameters`)

**Modulation sources checked:**
- Global LFO → Modulator Multiplier

**Behavior:**
- Always updates `modulationState.baseModulatorMultiplier` immediately
- If global LFO modulation is active AND voice is playing: skip direct parameter application
- If no global LFO modulation OR voice not playing: apply parameter directly

## Modified Files

### `A2 PolyphonicVoice.swift`

1. **`updateOscillatorParameters()`**
   - Added `globalLFO` optional parameter
   - Added modulation checks for modulation index
   - Added global LFO check for modulator multiplier
   - Conditional application based on modulation state

2. **`updateFilterParameters()`**
   - Added comprehensive modulation checks (aux env, voice LFO, aftertouch, key tracking)
   - Conditional application based on modulation state
   - Early return if modulation is active

### `A3 VoicePool.swift`

1. **`updateAllVoiceOscillators()`**
   - Now passes `globalLFO` state to voices
   - Enables voices to make informed decisions about parameter updates

### `A7 ParameterManager.swift`

1. **Class documentation**
   - Added explanation of modulation-aware parameter update system
   - Documents the architecture for future maintainers

## How It Works

### During Parameter Update (Main Thread)

```swift
// User moves filter cutoff slider
func updateFilterParameters(_ parameters: FilterParameters) {
    // 1. Update base value immediately (modulation system needs this)
    modulationState.baseFilterCutoff = parameters.clampedCutoff
    
    // 2. Check if any modulation source is active
    let hasModulation = /* check all sources */
    
    // 3. If modulation active and voice playing: DON'T apply directly
    if hasModulation && !isAvailable {
        return  // Modulation system will apply at next cycle
    }
    
    // 4. Otherwise: apply directly (no conflict)
    filter.$cutoffFrequency.ramp(to: value, duration: 0)
}
```

### During Modulation Update (Background Thread)

```swift
// Runs at 200Hz (every 5ms)
func applyModulation() {
    // 1. Read the latest base value (may have been updated by main thread)
    let base = modulationState.baseFilterCutoff
    
    // 2. Calculate modulated value
    let final = base + envelopeOffset + lfoOffset + aftertouchOffset
    
    // 3. Apply smoothly
    filter.$cutoffFrequency.ramp(to: final, duration: 0.005)
}
```

## Benefits

1. **No More Fighting**: Main thread and modulation thread no longer compete
2. **Smooth Updates**: Base value changes are picked up naturally at next modulation cycle
3. **Preserved Modulation**: Envelopes, LFOs, and aftertouch continue working smoothly
4. **User Expectation**: Slider still controls the "center point" around which modulation happens

## Testing Scenarios

### Before Fix
- Hold note with aux envelope sweeping filter
- Move filter cutoff slider → **Glitchy, fighting behavior**

### After Fix
- Hold note with aux envelope sweeping filter
- Move filter cutoff slider → **Smooth, envelope sweep range shifts smoothly**

## Notes

- Non-modulated parameters (carrier multiplier, amplitude) still update immediately
- Static parameters (resonance, saturation) are unaffected
- Ramp durations remain unchanged (0ms and 5ms as designed)
- Voice availability check (`isAvailable`) ensures released voices can update freely

## Future Considerations

If additional parameters become modulatable in the future, they should follow this same pattern:
1. Always update base value in modulation state
2. Check for active modulation sources
3. Conditionally apply direct updates based on modulation state
