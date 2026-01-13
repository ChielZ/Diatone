# Ramp Time Standardization

## Overview

All parameter ramp times have been standardized to **5ms (0.005 seconds)** for consistent, smooth parameter changes across the audio engine.

## Rationale

- **Matches modulation rate**: The modulation system runs at 200Hz (5ms intervals)
- **Smooth UI response**: Fast enough to feel responsive, slow enough to avoid zipper noise
- **Prevents AudioKit conflicts**: Consistent timing reduces parameter ramping artifacts
- **Reduces graininess**: Smoother parameter interpolation during slider movements

## Exception: Zero-Latency Note Triggering

The following parameters use **0ms ramps** at note-on for instantaneous, zero-latency response:
- Oscillator amplitude (initial touch modulation)
- Filter cutoff (base value at trigger)

These remain at 0ms because:
1. Note triggering requires instantaneous response
2. Any latency would be perceived as sluggish keyboard feel
3. These values are set only once per note, not continuously updated

## Changes Made

### PolyphonicVoice.swift

#### Parameter Update Methods (UI-driven changes)
- `updateOscillatorParameters()`: 5ms ramps for all parameters
- `updateFilterParameters()`: 5ms ramp (when no modulation active)
- `updateFilterStaticParameters()`: 5ms ramps (resonance, saturation)
- `updateEnvelopeParameters()`: 5ms ramps (attack, decay, sustain, release)

#### Reset Methods (modulation disable)
- `resetModulatorMultiplierToBase()`: Changed from 50ms → 5ms
- `resetModulationIndexToBase()`: Changed from 50ms → 5ms

#### Oscillator Recreation
- `recreateOscillators()`: Changed from 50ms → 5ms

#### Note Triggering (zero-latency exceptions)
- `trigger()`: 
  - Filter static parameters: Changed from 0ms → 5ms
  - Amplitude: Remains 0ms (zero-latency)
  - Filter cutoff base: Remains 0ms (zero-latency)

### VoicePool.swift

#### Reset Methods
- `resetDelayTimeToBase()`: Changed from 50ms → 5ms

#### Modulation Application (unchanged)
- Global LFO delay time modulation: Already 5ms ✓

## Before vs After

### Before
```swift
// Mixed ramp times throughout the codebase
filter.$cutoffFrequency.ramp(to: value, duration: 0)      // Instant
oscLeft.$amplitude.ramp(to: value, duration: 0.005)       // 5ms
resetModulatorMultiplier.ramp(to: value, duration: 0.05)  // 50ms
```

### After
```swift
// Consistent 5ms for all UI updates
filter.$cutoffFrequency.ramp(to: value, duration: 0.005)      // 5ms
oscLeft.$amplitude.ramp(to: value, duration: 0.005)           // 5ms
resetModulatorMultiplier.ramp(to: value, duration: 0.005)     // 5ms

// Exception: Zero-latency at note trigger
oscLeft.$amplitude.ramp(to: value, duration: 0)               // 0ms (note-on only)
```

## Testing Checklist

After this change, test for:

1. **Reduced graininess**: Slider movements should feel smoother
2. **No sluggishness**: UI should still feel responsive (5ms is imperceptible)
3. **Smooth modulation**: Envelopes and LFOs should continue working smoothly
4. **No clicks**: No audible clicks when adjusting parameters
5. **Sharp note attacks**: Notes should still trigger immediately (zero latency)

## Reverting if Needed

If any unwanted behavior appears:
1. Revert to previous commit (before ramp time changes)
2. Keep the modulation-aware update system (previous commit)
3. The modulation-aware system is the primary fix; ramp times are optimization

## Technical Details

### Why 5ms?

- **Modulation sync**: Matches the 200Hz control rate (1/200 = 0.005s)
- **Perceptual threshold**: Below 10ms is perceived as instant by humans
- **AudioKit sweet spot**: Long enough to avoid parameter stepping, short enough to feel immediate
- **Nyquist consideration**: At 200Hz update rate, 5ms provides smooth interpolation

### Why Not 0ms Everywhere?

- 0ms ramps can cause:
  - Zipper noise (audible stepping)
  - Parameter conflicts when multiple threads update
  - AudioKit internal state inconsistencies
  
- Exception: Note triggering MUST be 0ms for:
  - Zero-latency keyboard response
  - Sharp percussive attacks
  - Immediate velocity response

### Why Not Longer (50ms, 100ms)?

- Too long causes:
  - Sluggish UI feel
  - Lag between slider movement and sound change
  - Disconnected user experience
  
- Reset operations previously used 50ms as "safety" but 5ms is sufficient

## Related Documentation

- See `MODULATION_AWARE_UPDATES.md` for the primary fix (race condition prevention)
- This ramp time standardization is a secondary optimization
- Both changes work together for smooth, glitch-free parameter updates
