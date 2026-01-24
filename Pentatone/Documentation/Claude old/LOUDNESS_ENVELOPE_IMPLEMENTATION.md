# Loudness Envelope Implementation

## Overview

This document describes the replacement of AudioKit's `AmplitudeEnvelope` node with a manual loudness envelope system controlled via a `Fader` node. This change provides significantly better control over voice behavior, especially for voice stealing and legato (monophonic) playing.

## Motivation

### Problems with AmplitudeEnvelope

1. **Always starts from zero**: The `AmplitudeEnvelope` node always begins its attack from silence (0.0), which causes audible clicks when stealing voices or retriggering in legato mode
2. **Limited control**: Once you call `openGate()` or `closeGate()`, the envelope runs autonomously - you can't inject custom behavior
3. **Exponential attack**: AudioKit's envelope uses exponential curves for all stages, but our modulation system uses linear attack (which matches AudioKit's `.ramp()` behavior better)

### Benefits of Fader-Based Approach

1. **Start from any level**: Can begin attack from the current fader level (e.g., 0.3 instead of 0.0), eliminating clicks during voice stealing
2. **Consistent architecture**: All envelopes now use the same modulation system and timing model (hybrid: linear attack, exponential decay/release)
3. **Full control**: The loudness envelope is just another modulation source - we can manipulate it however we want
4. **Better legato**: In monophonic mode, notes can transition smoothly without the envelope dropping to zero

## Architecture Changes

### 1. New Loudness Envelope Parameters

Added `LoudnessEnvelopeParameters` to the modulation system:

```swift
struct LoudnessEnvelopeParameters: Codable, Equatable {
    var attack: Double      // Linear ramp (0 to 1)
    var decay: Double       // Exponential decay (1 to sustain)
    var sustain: Double     // Sustain level (0.0 - 1.0)
    var release: Double     // Exponential release (sustain to 0)
    var isEnabled: Bool
    
    static let `default` = LoudnessEnvelopeParameters(
        attack: 0.01,
        decay: 0.1,
        sustain: 0.7,
        release: 0.2,
        isEnabled: true
    )
}
```

### 2. ModulationState Updates

Added loudness envelope tracking to `ModulationState`:

```swift
struct ModulationState {
    // Envelope timing
    var loudnessEnvelopeTime: Double = 0.0      // Time in current envelope stage
    
    // Sustain level capture
    var loudnessSustainLevel: Double = 0.0      // Captured at gate close
    
    // Voice stealing support
    var loudnessStartLevel: Double = 0.0        // Starting level for attack
}
```

### 3. PolyphonicVoice Changes

**Replaced AmplitudeEnvelope with Fader:**

```swift
// OLD:
let envelope: AmplitudeEnvelope

// NEW:
let fader: Fader
```

**Signal path change:**

```
OLD: [Oscillators] → [Mixer] → [Filter] → [AmplitudeEnvelope]
NEW: [Oscillators] → [Mixer] → [Filter] → [Fader]
```

### 4. New ModulationRouter Helper

Added `calculateLoudnessEnvelopeValue()` to support starting from non-zero levels:

```swift
static func calculateLoudnessEnvelopeValue(
    time: Double,
    isGateOpen: Bool,
    attack: Double,
    decay: Double,
    sustain: Double,
    release: Double,
    capturedLevel: Double = 0.0,
    startLevel: Double = 0.0  // NEW: Support non-zero start
) -> Double
```

## Implementation Details

### Trigger Behavior

When a note is triggered, the system:

1. **Captures current fader level** (for voice stealing):
   ```swift
   let currentFaderLevel = Double(fader.leftGain)  // e.g., 0.3 if voice stolen
   ```

2. **Applies immediate attack ramp**:
   ```swift
   fader.$leftGain.ramp(to: 1.0, duration: Float(loudnessAttack))
   fader.$rightGain.ramp(to: 1.0, duration: Float(loudnessAttack))
   ```

3. **Stores start level for envelope calculation**:
   ```swift
   modulationState.loudnessStartLevel = currentFaderLevel
   ```

4. **Modulation system takes over** on the next control rate cycle (5ms later)

### Control Rate Updates (200 Hz)

On each modulation cycle:

1. **Update envelope time** (timestamp-based for attack/decay, incremental for release)
2. **Calculate envelope value** using `ModulationRouter.calculateLoudnessEnvelopeValue()`
3. **Apply to fader** with 5ms ramp for smooth transitions

### Release Behavior

When a note is released:

1. **Capture current envelope value**:
   ```swift
   let loudnessValue = ModulationRouter.calculateLoudnessEnvelopeValue(
       time: modulationState.loudnessEnvelopeTime,
       isGateOpen: true,
       // ... other parameters
   )
   ```

2. **Close gate and store captured level**:
   ```swift
   modulationState.closeGate(
       modulatorValue: modulatorValue,
       auxiliaryValue: auxiliaryValue,
       loudnessValue: loudnessValue  // NEW
   )
   ```

3. **Envelope transitions smoothly** from captured level to zero over release time

## Voice Stealing Example

**Scenario**: Voice 1 is playing at 50% envelope level, then Voice 2 steals it with a new note.

**Old behavior** (with AmplitudeEnvelope):
```
Time 0ms: Voice 1 at 50% level
Time 0ms: New note triggers, envelope resets to 0% → CLICK!
Time 10ms: Envelope attacks to 100%
```

**New behavior** (with Fader):
```
Time 0ms: Voice 1 at 50% level (fader.leftGain = 0.5)
Time 0ms: New note triggers, ramp starts from 50% → NO CLICK!
Time 10ms: Envelope reaches 100% smoothly
```

## Legato (Monophonic) Example

**Scenario**: Note 1 is held, then Note 2 is triggered without releasing Note 1.

**Old behavior**:
```
Note 1: Envelope at sustain level (70%)
Note 2 triggers: Envelope drops to 0%, then attacks again → CLICK!
```

**New behavior**:
```
Note 1: Fader at sustain level (70%)
Note 2 triggers: Fader ramps from 70% to 100% smoothly → NO CLICK!
```

## Timing Precision

The loudness envelope uses the same precise timing as other envelopes:

- **Attack/Decay**: Uses `CACurrentMediaTime()` for absolute timing (eliminates 0-5ms jitter)
- **Release**: Uses incremental `deltaTime` (quantized to control rate)
- **Initial ramp**: Applied immediately at trigger with duration = attack time

This ensures perfect synchronization between the initial attack ramp (AudioKit's `.ramp()`) and subsequent control rate updates (modulation system).

## Migration Notes

### For Existing Presets

- **Envelope parameters** are now stored in `voiceModulation.loudnessEnvelope` instead of `envelope` node
- **Default values** are compatible with typical ADSR settings
- **Attack behavior** changes from exponential to linear (generally perceived as more punchy)

### For UI Code

Replace references to `envelope` parameters with `voiceModulation.loudnessEnvelope`:

```swift
// OLD:
voice.envelope.attackDuration = 0.05
voice.envelope.decayDuration = 0.2
voice.envelope.sustainLevel = 0.7
voice.envelope.releaseDuration = 0.3

// NEW:
voice.voiceModulation.loudnessEnvelope.attack = 0.05
voice.voiceModulation.loudnessEnvelope.decay = 0.2
voice.voiceModulation.loudnessEnvelope.sustain = 0.7
voice.voiceModulation.loudnessEnvelope.release = 0.3
```

### For Voice Allocation Code

No changes needed! Voice stealing and allocation work the same way, but now they automatically benefit from smooth transitions.

## Testing Recommendations

1. **Voice stealing**: Play rapid notes to trigger voice stealing, listen for clicks
2. **Legato mode**: Hold one note and play another in monophonic mode, verify smooth transition
3. **Fast attacks**: Test with attack = 0ms, ensure instant response
4. **Long releases**: Test with release = 2s, verify smooth fadeout
5. **Envelope modulation**: Verify that other modulation sources (voice LFO, etc.) still work correctly

## Performance Considerations

- **CPU impact**: Minimal - we replaced one AudioKit node with another (envelope → fader)
- **Control rate overhead**: Tiny - one additional envelope calculation per voice per cycle (~5-10 voices × 200 Hz = negligible)
- **Memory**: Slightly increased - added 3 doubles to ModulationState (~24 bytes per voice)

## Future Enhancements

Possible improvements to consider:

1. **Velocity scaling**: Apply initial touch modulation to loudness envelope attack
2. **Envelope curves**: Add curve shape control (concave/linear/convex)
3. **Multiple stages**: Add hold/delay stages for more complex envelopes
4. **Per-note dynamics**: Modulate loudness based on key tracking or aftertouch

## Conclusion

The fader-based loudness envelope provides:

✅ **Better sound quality** - no clicks during voice stealing or legato  
✅ **Consistent architecture** - all envelopes use the same system  
✅ **Full control** - can manipulate loudness envelope at any time  
✅ **Precise timing** - uses the same high-precision timing as other modulation sources  

This change is functionally equivalent to the old `AmplitudeEnvelope` approach (with linear attack instead of exponential), but with significantly improved behavior in edge cases.
