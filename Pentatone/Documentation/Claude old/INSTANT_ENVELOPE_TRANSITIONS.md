# Instant Envelope Transitions Implementation

## Overview
This document describes the implementation of instant (0ms) parameter transitions when envelope decay or release times are set below 1 millisecond. This eliminates the default 10ms ramp that would otherwise cause audible smoothing when the user intends an instant change.

## Background
The modulation system runs at 100 Hz (10ms update intervals) and applies parameter changes with a 10ms ramp duration to ensure smooth transitions. However, when an envelope's decay or release time is set to 0ms (or very close to 0ms), the user expects an instant parameter change, not a smoothed 10ms transition.

## Implementation Details

### Detection Logic
For each envelope destination, we detect three conditions:
1. **Envelope Stage**: Is the envelope currently in decay or release phase?
2. **Timing Window**: Is the decay/release time < 1ms? (uses 1ms threshold for safety margin)
3. **Active Modulation**: Is the envelope actively modulating this destination? (amount ≠ 0)

When all three conditions are met, the ramp duration is set to 0.0 instead of the default 10ms.

### Modified Methods

#### 1. `applyCombinedModulationIndex()` - Modulator Envelope → Mod Index
- **Envelope**: Modulator envelope
- **Destination**: Oscillator modulation index
- **Conditions checked**:
  - Decay phase: `isGateOpen && time >= attack && time < (attack + decay)`
  - Release phase: `!isGateOpen`
  - Timing: `decay < 0.001` or `release < 0.001`
  - Active: `modulatorEnvelope.amountToModulationIndex != 0.0`

#### 2. `applyCombinedPitch()` - Auxiliary Envelope → Pitch
- **Envelope**: Auxiliary envelope
- **Destination**: Oscillator pitch (frequency)
- **Conditions checked**:
  - Decay phase: `isGateOpen && time >= attack && time < (attack + decay)`
  - Release phase: `!isGateOpen`
  - Timing: `decay < 0.001` or `release < 0.001`
  - Active: `hasAuxEnv` (checks `auxiliaryEnvelope.amountToOscillatorPitch != 0.0`)

#### 3. `applyCombinedFilterFrequency()` - Auxiliary Envelope → Filter
- **Envelope**: Auxiliary envelope
- **Destination**: Filter cutoff frequency
- **Conditions checked**:
  - Decay phase: `isGateOpen && time >= attack && time < (attack + decay)`
  - Release phase: `!isGateOpen`
  - Timing: `decay < 0.001` or `release < 0.001`
  - Active: `hasAuxEnv` (checks `auxiliaryEnvelope.amountToFilterFrequency != 0.0`)

#### 4. `applyLoudnessEnvelope()` - Loudness Envelope → Fader Gain
- **Envelope**: Loudness envelope
- **Destination**: Voice output level (fader gain)
- **Conditions checked**:
  - Decay phase: `isGateOpen && time >= attack && time < (attack + decay)`
  - Release phase: `!isGateOpen`
  - Timing: `decay < 0.001` or `release < 0.001`
  - **No active check needed** - loudness envelope is always active

### Code Pattern
All implementations follow this pattern:

```swift
let rampDuration: Float
if /* attack phase logic */ {
    // Use remaining attack time
    rampDuration = Float(max(0.001, remainingAttack))
} else {
    // Check decay/release phases
    let isInDecayPhase = modulationState.isGateOpen && 
                        time >= attack &&
                        time < (attack + decay)
    let isInReleasePhase = !modulationState.isGateOpen
    
    if isInDecayPhase && decay < 0.001 && hasActiveModulation {
        rampDuration = 0.0  // INSTANT DECAY
    } else if isInReleasePhase && release < 0.001 && hasActiveModulation {
        rampDuration = 0.0  // INSTANT RELEASE
    } else {
        rampDuration = ControlRateConfig.modulationRampDuration  // Normal 10ms
    }
}

// Apply with calculated ramp duration
parameter.ramp(to: targetValue, duration: rampDuration)
```

## Safety Considerations

### 1ms Threshold
We use `< 0.001` (1ms) instead of `== 0.0` to provide a safety margin. This accounts for:
- Floating-point precision issues
- UI quantization (10ms steps)
- User intent (0-9ms all treated as "instant")

### Per-Destination Active Checks
Each destination checks if modulation is active before applying instant transitions:
- **Mod envelope**: Checks `amountToModulationIndex != 0.0`
- **Aux envelope to pitch**: Uses `hasAuxEnv` flag
- **Aux envelope to filter**: Uses `hasAuxEnv` flag
- **Loudness envelope**: No check needed (always active)

This prevents unnecessary 0ms ramps when the envelope isn't actually affecting the parameter.

### Attack Phase Preservation
Attack phase logic is unchanged - it continues to use the remaining attack time as the ramp duration for smooth handover from the initial trigger() ramp.

## Testing Scenarios

### Scenario 1: Instant Decay (0ms)
1. Set aux envelope decay to 0ms
2. Set aux envelope → filter amount to +2 octaves
3. Trigger note
4. **Expected**: Filter sweeps down instantly after attack completes

### Scenario 2: Instant Release (0ms)
1. Set loudness envelope release to 0ms
2. Trigger and hold note
3. Release note
4. **Expected**: Note cuts off instantly with no tail

### Scenario 3: Mixed Timing
1. Set aux envelope decay to 0ms
2. Set aux envelope release to 500ms
3. Set aux envelope → pitch to +12 semitones
4. Trigger and release note
5. **Expected**: Pitch drops instantly after attack, then glides down smoothly over 500ms after release

### Scenario 4: Inactive Modulation
1. Set mod envelope decay to 0ms
2. Set mod envelope amount to 0.0 (inactive)
3. Trigger note
4. **Expected**: No special behavior (normal 10ms ramps continue, but parameter doesn't change)

## Performance Impact
Minimal - the additional conditional checks add negligible overhead:
- 3 boolean comparisons per destination
- Only executed when modulation is active
- No memory allocations

## Compatibility
This change is backward compatible:
- Existing presets continue to work as before
- Only affects behavior when decay/release times are < 1ms
- No changes to parameter ranges or UI

## Future Enhancements
Potential improvements for future consideration:
1. **Variable threshold**: Make the 1ms threshold user-configurable
2. **Attack phase**: Consider instant attacks as well (currently not implemented)
3. **Sustain transitions**: Handle instant transitions when changing sustain level during note hold
4. **Visual feedback**: Show "instant" indicator in UI when envelope times are < 1ms

---

**Implementation Date**: January 30, 2026  
**Modified Files**: `A2 PolyphonicVoice.swift`  
**Lines Modified**: ~80 lines across 4 methods
