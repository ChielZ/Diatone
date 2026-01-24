# Envelope Timing Synchronization Fix

## Problem Statement

The modulation system was experiencing audible pops, clicks, and glitches when envelope modulation was applied to pitch and filter frequency. This was caused by a **timing discrepancy** between:

1. **Note triggering** - Happens immediately upon touch detection (zero latency)
2. **Modulation system** - Runs at 200 Hz control rate (5ms update cycle)

### Root Cause

When a note was triggered:
- The AudioKit amplitude envelope opened immediately
- But the modulation envelopes' time counters didn't start incrementing until the next control rate update
- This created a variable delay of **0-5ms** before modulation was applied
- During this window, the sound used unmodulated values
- When modulation kicked in, the sudden parameter jump caused audible artifacts

### Example Failure Case

With aux envelope attack = 0ms and pitch modulation amount set:
1. Note triggered at t=0ms (base pitch)
2. First control rate update at t=3.7ms (envelope jumps to peak, pitch suddenly changes)
3. **Result**: 3.7ms of base pitch, then sudden jump = audible pop/click

## Solution Implemented

### Two-Part Fix

#### 1. **Immediate Envelope Application at Trigger**
At `trigger()` time, calculate and apply the **peak envelope value** (what the envelope will be after attack completes) with a ramp duration equal to the attack time:

```swift
// Peak value after attack completes = 1.0
let targetValue = baseValue + (1.0 * envelopeAmount)
parameter.ramp(to: targetValue, duration: attackTime)
```

The ramp **IS** the attack phase - it starts immediately with zero latency.

#### 2. **Precise Elapsed Time Tracking**
Track the exact trigger timestamp and calculate precise elapsed time at each control rate update:

```swift
// At trigger:
modulationState.triggerTimestamp = CACurrentMediaTime()

// At each control rate update:
let preciseElapsedTime = CACurrentMediaTime() - modulationState.triggerTimestamp
modulationState.modulatorEnvelopeTime = preciseElapsedTime
```

This ensures the control-rate envelope calculation knows exactly where it is in the envelope timeline and can seamlessly take over from the initial ramp.

### Critical Implementation Details

#### Envelope Curve Matching

For seamless handoff, the trigger ramp and envelope calculation **must use the same curve**:

- **AudioKit `.ramp()`**: Uses linear interpolation
- **Linear envelope calculation**: Matches perfectly ✓
- **Exponential envelope calculation**: Creates mismatch ✗

Therefore, we've switched to **linear envelopes** for initial testing using `ModulationRouter.calculateActiveEnvelopeValue()`, which currently calls `calculateEnvelopeValue()` (linear version).

#### Three Modulation Destinations

The fix is applied to the three envelope destinations most sensitive to timing:

1. **Mod Envelope → Modulation Index** (FM timbre)
2. **Aux Envelope → Pitch** (frequency modulation)
3. **Aux Envelope → Filter Frequency** (filter sweeps)

#### Meta-Modulation Handling

Initial touch meta-modulation (which scales envelope amounts) is correctly applied in the trigger calculations:

```swift
// Apply initial touch scaling if active
var effectiveAmount = baseAmount
if initialTouchAmount != 0.0 {
    effectiveAmount = ModulationRouter.calculateTouchScaledAmount(
        baseAmount: baseAmount,
        initialTouchValue: initialTouchX,
        initialTouchAmount: initialTouchAmount
    )
}
```

#### Key Tracking Integration

Filter frequency modulation correctly combines:
- Key tracking (note-on property, applied once)
- Envelope modulation (continuous, from trigger ramp → control rate)

```swift
// Calculate key-tracked base first
let keyTrackedBase = baseFilterCutoff * pow(2.0, keyTrackOctaves)

// Apply envelope modulation on top
let target = keyTrackedBase * pow(2.0, envelopeOctaves)
```

## Changes Made

### A6 ModulationSystem.swift

1. **Added `triggerTimestamp` field** to `ModulationState`:
   ```swift
   var triggerTimestamp: TimeInterval = 0.0
   ```

2. **Added `calculateActiveEnvelopeValue()` method** to `ModulationRouter`:
   - Centralized envelope calculation with easy linear/exponential switching
   - Currently set to linear to match AudioKit ramps
   - Documented why linear is used and how to switch

### A2 PolyphonicVoice.swift

1. **Updated `trigger()` method**:
   - Records precise trigger timestamp
   - Calls new `applyInitialEnvelopeModulation()` method
   - Updated documentation

2. **Added `applyInitialEnvelopeModulation()` method**:
   - Calculates peak envelope values for all three destinations
   - Applies with ramp duration = attack time
   - Handles meta-modulation and key tracking correctly
   - ~100 lines of implementation

3. **Updated `applyModulation()` method**:
   - Uses precise elapsed time from trigger timestamp
   - Switched to `calculateActiveEnvelopeValue()` for consistency
   - No longer accumulates deltaTime (avoids drift)

4. **Updated `release()` method**:
   - Uses `calculateActiveEnvelopeValue()` for consistency

## Testing Instructions

### Test Case 1: Zero Attack Time
1. Set aux envelope attack = 0ms
2. Set aux envelope to pitch amount = +12 semitones (1 octave up)
3. Trigger multiple notes rapidly
4. **Expected**: All notes start at the higher pitch immediately, no pops/clicks

### Test Case 2: Fast Attack
1. Set aux envelope attack = 10ms
2. Set aux envelope to pitch amount = +12 semitones
3. Trigger multiple notes
4. **Expected**: Smooth pitch sweep from base to +1 octave over 10ms, no discontinuities

### Test Case 3: Slow Attack
1. Set aux envelope attack = 500ms
2. Set aux envelope to filter amount = +3 octaves
3. Trigger notes
4. **Expected**: Smooth filter sweep over 500ms, control rate seamlessly takes over after first 5ms

### Test Case 4: Modulation Index
1. Set mod envelope attack = 0ms
2. Set mod envelope to modulation index = +5.0
3. Trigger notes
4. **Expected**: Bright FM timbre from the start, no transient artifacts

## Future Enhancements

### Hybrid Envelopes
Once linear timing is verified, implement hybrid envelopes:
- **Attack stage**: Linear (matches ramps)
- **Decay/Release stages**: Exponential (analog-style character)

This gives the best of both worlds:
- Zero-latency, artifact-free attacks
- Natural-sounding decay and release

### Implementation sketch:
```swift
if time < attack {
    return time / attack  // Linear attack
} else {
    let decayTime = time - attack
    return calculateExponentialDecay(decayTime, ...)  // Exponential decay
}
```

## Notes

- The attack = 0ms case is handled naturally (ramp duration = 0 = instant application)
- No special cases needed
- All existing modulation routing and meta-modulation continue to work correctly
- Filter smoothing for aftertouch is still applied on continuous updates
- Voice LFO phase updates still use deltaTime (incremental, as intended)

## Success Criteria

✅ No pops/clicks with attack = 0ms and envelope modulation active  
✅ Smooth envelope curves with fast attacks (10-50ms)  
✅ Seamless handoff from trigger ramp to control rate updates  
✅ Consistent behavior across all notes (no timing jitter)  
✅ All three destinations working correctly (pitch, filter, mod index)  

---

**Date**: January 2026  
**Status**: Implemented, ready for testing
