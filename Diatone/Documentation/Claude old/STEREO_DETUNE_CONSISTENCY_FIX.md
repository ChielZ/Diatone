# Stereo Detune Consistency Fix

## Problem Description

The stereo detune effect was behaving erratically when switching between presets or changing parameters:
- Inconsistent detune amounts between different notes
- Unpredictable stereo spread when presets loaded
- Different voices showing different detune characteristics

## Root Cause Analysis

The issue was in how pitch modulation interacted with the stereo detune calculation:

### Visual Diagram

```
CORRECT FLOW (after fix):
┌─────────────────────────────────────────────────────────────────┐
│ Note-On: setFrequency(440)                                      │
│   ↓                                                              │
│ currentFrequency = 440 Hz (BASE - never changes during mod)     │
│   ↓                                                              │
│ modulationState.baseFrequency = 440 Hz                          │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ Modulation Cycle (200 Hz):                                      │
│   1. Read baseFrequency (440 Hz)                                │
│   2. Apply modulation: finalFreq = 440 × pitch_mods = 450 Hz    │
│   3. Apply stereo detune to finalFreq:                          │
│      - leftFreq = 450 × ratio                                   │
│      - rightFreq = 450 ÷ ratio                                  │
│   4. Update oscillators directly                                │
│      - oscLeft.baseFrequency ← leftFreq                         │
│      - oscRight.baseFrequency ← rightFreq                       │
│   5. currentFrequency UNCHANGED (still 440 Hz)                  │
└─────────────────────────────────────────────────────────────────┘

BUGGY FLOW (before fix):
┌─────────────────────────────────────────────────────────────────┐
│ Note-On: setFrequency(440)                                      │
│   ↓                                                              │
│ currentFrequency = 440 Hz                                       │
│   ↓                                                              │
│ modulationState.baseFrequency = 440 Hz                          │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ Modulation Cycle 1 (200 Hz):                                    │
│   1. Read baseFrequency (440 Hz)                                │
│   2. Apply modulation: finalFreq = 450 Hz                       │
│   3. ❌ currentFrequency = finalFreq (450 Hz) ← CORRUPTION!     │
│   4. updateOscillatorFrequencies() uses currentFrequency:       │
│      - leftFreq = 450 × ratio                                   │
│      - rightFreq = 450 ÷ ratio                                  │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ Modulation Cycle 2:                                             │
│   1. Read baseFrequency (still 440 Hz - correct)                │
│   2. Apply modulation: finalFreq = 455 Hz                       │
│   3. ❌ currentFrequency = finalFreq (455 Hz) ← CORRUPTION!     │
│   4. Detune applied to wrong base (455 instead of 440)          │
│   5. Result: Inconsistent stereo spread across cycles           │
└─────────────────────────────────────────────────────────────────┘
```

### The Bug

1. **`currentFrequency`** is meant to store the **base/center** frequency (unmodulated)
2. **`modulationState.baseFrequency`** is correctly set at note-on to this base frequency
3. **Pitch modulation sources** (aux envelope, voice LFO, aftertouch) calculate a **modulated** frequency from `baseFrequency`
4. **THE BUG**: The modulation code was setting `currentFrequency = finalFreq` where `finalFreq` was the **modulated** frequency
5. **Then** `updateOscillatorFrequencies()` would apply stereo detune to this corrupted `currentFrequency`

### Why This Caused Erratic Behavior

```
Intended flow:
  baseFrequency (440 Hz) 
    → modulation (+vibrato, +envelopes) 
    → finalFreq (450 Hz)
    → apply stereo detune to finalFreq
    → leftOsc (450 Hz × ratio), rightOsc (450 Hz ÷ ratio)

Buggy flow:
  baseFrequency (440 Hz)
    → modulation
    → finalFreq (450 Hz)
    → currentFrequency = 450 Hz ❌ (OVERWRITES BASE!)
    → updateOscillatorFrequencies() uses currentFrequency (450 Hz)
    → On next modulation cycle: uses wrong base
    → Stereo detune applied to inconsistent base values
```

**Result**: Each voice's `currentFrequency` would drift based on its modulation history, causing inconsistent stereo spread across notes and presets.

## The Fix

### Changes in `applyCombinedPitch()` (A2 PolyphonicVoice.swift, ~line 1283)

**Before:**
```swift
let finalFreq = ModulationRouter.calculateOscillatorPitch(
    baseFrequency: modulationState.baseFrequency,
    // ... modulation sources ...
)

currentFrequency = finalFreq  // ❌ WRONG - corrupts base frequency
updateOscillatorFrequencies() // ❌ Applies detune to corrupted value
```

**After:**
```swift
let finalFreq = ModulationRouter.calculateOscillatorPitch(
    baseFrequency: modulationState.baseFrequency,
    // ... modulation sources ...
)

// CRITICAL: Apply stereo detune to the modulated frequency, not currentFrequency
// currentFrequency should remain the unmodulated base frequency
let leftFreq: Double
let rightFreq: Double

switch detuneMode {
case .proportional:
    let ratio = pow(2.0, frequencyOffsetCents / 1200.0)
    leftFreq = finalFreq * ratio
    rightFreq = finalFreq / ratio
    
case .constant:
    leftFreq = finalFreq + frequencyOffsetHz
    rightFreq = finalFreq - frequencyOffsetHz
}

// Apply modulated + detuned frequencies directly to oscillators
oscLeft.$baseFrequency.ramp(to: Float(leftFreq), duration: ControlRateConfig.modulationRampDuration)
oscRight.$baseFrequency.ramp(to: Float(rightFreq), duration: ControlRateConfig.modulationRampDuration)
```

### Changes in `trigger()` (A2 PolyphonicVoice.swift, ~line 502)

**Before:**
```swift
let targetFrequency = modulationState.baseFrequency * pow(2.0, semitoneOffset / 12.0)
let clampedFrequency = max(20.0, min(20000.0, targetFrequency))

// Apply with ramp duration = attack time
currentFrequency = clampedFrequency  // ❌ WRONG - corrupts base frequency

// Calculate start and target left/right frequencies with stereo offset
// ...
```

**After:**
```swift
let targetFrequency = modulationState.baseFrequency * pow(2.0, semitoneOffset / 12.0)
let clampedFrequency = max(20.0, min(20000.0, targetFrequency))

// Calculate start and target left/right frequencies with stereo offset
// IMPORTANT: Do NOT modify currentFrequency here - it should stay at the base (unmodulated) value
// ...
```

## Key Principles

### What `currentFrequency` Should Be

- **Always** the base (unmodulated) frequency
- Set by `setFrequency()` when a note is triggered
- Used by `modulationState.reset()` to initialize `baseFrequency`
- Should **never** be overwritten with modulated values

### How Modulation Should Work

1. **At note-on**: `setFrequency(440)` → `currentFrequency = 440` → `modulationState.baseFrequency = 440`
2. **During modulation**: Calculate `finalFreq` from `modulationState.baseFrequency` + modulation sources
3. **Apply stereo detune**: Calculate `leftFreq` and `rightFreq` from `finalFreq` (not `currentFrequency`)
4. **Update oscillators**: Set `oscLeft.baseFrequency` and `oscRight.baseFrequency` directly

### Separation of Concerns

- **`currentFrequency`**: Base/center frequency (set once at note-on)
- **`modulationState.baseFrequency`**: Copy of base frequency for modulation calculations
- **`finalFreq`**: Modulated frequency (calculated each modulation cycle)
- **`leftFreq` / `rightFreq`**: Final L/R frequencies after stereo detune

## Testing Checklist

- [ ] Stereo detune is consistent when playing the same note repeatedly
- [ ] Detune amount is the same across different keys/frequencies
- [ ] Preset switching preserves correct detune settings
- [ ] Changing detune parameters (cents/Hz, mode) works consistently
- [ ] Detune works correctly with pitch modulation active (envelopes, LFOs, aftertouch)
- [ ] No frequency drift over time or after multiple note triggers
- [ ] Monophonic legato mode maintains consistent detune
- [ ] Voice stealing doesn't cause detune inconsistencies

## Technical Notes

### Why We Removed `updateOscillatorFrequencies()` Call

The helper function `updateOscillatorFrequencies()` is designed for **static** frequency updates (like changing the base frequency or detune parameters from the UI). It reads from `currentFrequency` and applies stereo detune.

During **dynamic modulation**, we can't use this function because:
1. It expects `currentFrequency` to be the base frequency
2. Modulation produces a continuously changing frequency
3. We need to apply detune to the modulated frequency, not the base

So we inline the detune calculation in the modulation code and apply directly to oscillators.

### Remaining Uses of `updateOscillatorFrequencies()`

This function is still correctly used for:
- `setFrequency()` - when UI or note-on sets a new base frequency
- Parameter changes (detune mode, offset amount) via `didSet` handlers
- Oscillator recreation after waveform changes
- Initial frequency setup in `initialize()`

All these cases work with the base frequency, not modulated values, so they're safe.

## Impact

This is a **surgical fix** that:
- ✅ Maintains the existing modulation architecture
- ✅ Doesn't change the modulation routing or formulas
- ✅ Only fixes the specific interaction between modulation and stereo detune
- ✅ Preserves all other functionality (envelopes, LFOs, aftertouch, etc.)
- ✅ No changes to parameter structures or preset compatibility

The fix ensures that `currentFrequency` maintains its semantic meaning as the **base** frequency, while modulation and stereo detune are calculated correctly from it.
