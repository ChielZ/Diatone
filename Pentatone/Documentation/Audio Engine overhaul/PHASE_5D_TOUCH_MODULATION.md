# Phase 5D: Touch & Key Tracking Modulation

## Overview

Phase 5D completes the modulation system by adding touch-based and frequency-based modulation sources with routable destinations. This allows initial touch position, aftertouch movement, and note frequency to modulate any voice-level parameter.

## Implementation Summary

### What Was Added

1. **Touch Initial Modulation** - Initial touch X position as a modulation source
2. **Touch Aftertouch Modulation** - X movement while holding a key as a modulation source  
3. **Key Tracking Modulation** - Note frequency as a modulation source
4. **Routable Destinations** - All three sources can target any voice-level parameter

### Files Modified

1. **A02 PolyphonicVoice.swift**
   - Added `applyTouchInitial()` - applies initial touch X modulation
   - Added `applyTouchAftertouch()` - applies aftertouch delta modulation
   - Added `applyKeyTracking()` - applies frequency-based modulation
   - Added helper methods `getBaseValue()` and `applyModulatedValue()`
   - Updated `applyModulation()` to call touch/key tracking modulators

2. **V02 MainKeyboardView.swift**
   - Updated `handleTrigger()` to store touch position in `modulationState`
   - Updated `handleAftertouch()` to update `modulationState.currentTouchX`
   - Maintained backward compatibility with hardwired touch control

3. **A01 SoundParameters.swift**
   - Updated default parameters to include touch modulation (disabled by default)

4. **A06 ModulationSystem.swift**
   - Already contained the data structures (implemented in Phase 5B/5C)

## Architecture

### Touch Position Storage

Touch positions are stored in `ModulationState`:
```swift
struct ModulationState {
    var initialTouchX: Double = 0.0      // Where key was first touched (0.0-1.0)
    var currentTouchX: Double = 0.0      // Current touch position (0.0-1.0)
    var currentFrequency: Double = 440.0 // Note frequency for key tracking
    // ...
}
```

### Modulation Flow

1. **User touches key** → `handleTrigger()` in MainKeyboardView
   - Stores `initialTouchX` in modulation state
   - Also sets `baseAmplitude` for immediate response (hardwired fallback)

2. **User moves finger** → `handleAftertouch()` in MainKeyboardView
   - Updates `currentTouchX` in modulation state
   - Also updates `baseFilterCutoff` for immediate response (hardwired fallback)

3. **Modulation system (200 Hz)** → `applyModulation()` in PolyphonicVoice
   - Reads touch positions from modulation state
   - Applies modulation to configured destinations
   - Touch modulation runs AFTER envelopes/LFOs

### Modulation Types

#### 1. Touch Initial (Unipolar)

**Source:** Initial touch X position (0.0 = inner edge, 1.0 = outer edge)

**Modulation type:** Unipolar (uses envelope modulation math)
- `amount = 1.0` → full range (0.0 to 1.0)
- `amount = 0.5` → half range (0.0 to 0.5)
- `amount = -1.0` → inverted range (1.0 to 0.0)

**Use cases:**
- Touch position controls amplitude (velocity sensitivity)
- Touch position controls filter brightness (timbral variation)
- Touch position controls FM modulation index (expressive FM)

**Example:**
```swift
touchInitial: TouchInitialParameters(
    destination: .oscillatorAmplitude,  // Control volume by touch position
    amount: 1.0,                         // Full range (0.0 to 1.0)
    isEnabled: true
)
```

#### 2. Touch Aftertouch (Bipolar)

**Source:** X movement from initial position (negative = moved left, positive = moved right)

**Modulation type:** Bipolar (uses LFO modulation math)
- `amount = 1.0` → full range modulation around base value
- Movement adds/subtracts from base value
- Centered around initial touch position

**Use cases:**
- Aftertouch controls filter cutoff (expressive filter sweeps)
- Aftertouch controls pitch (manual vibrato/pitch bend)
- Aftertouch controls FM modulation (timbral expression)

**Example:**
```swift
touchAftertouch: TouchAftertouchParameters(
    destination: .filterCutoff,  // Sweep filter by moving finger
    amount: 1.0,                  // Full range modulation
    isEnabled: true
)
```

**Important:** The hardwired aftertouch in MainKeyboardView includes:
- Logarithmic scaling (exponential frequency response)
- Smoothing (linear interpolation)
- Movement threshold (reduces jitter)

When using routable aftertouch modulation, you get the raw delta value without these refinements. The hardwired behavior is retained for backward compatibility.

#### 3. Key Tracking (Unipolar)

**Source:** Note frequency mapped to 0.0-1.0 range
- Reference: 440 Hz (A4) = 0.5
- Range: ~55 Hz (A1) = 0.0 to ~3520 Hz (A7) = 1.0
- Logarithmic mapping (equal steps per octave)

**Modulation type:** Unipolar (uses envelope modulation math)

**Use cases:**
- Higher notes have brighter filter (keyboard tracking)
- Higher notes have less amplitude (natural volume balance)
- Higher notes have more FM modulation (brighter high notes)

**Example:**
```swift
keyTracking: KeyTrackingParameters(
    destination: .filterCutoff,  // Brighter filter for higher notes
    amount: 0.5,                  // Moderate tracking (±0.5 octaves)
    isEnabled: true
)
```

## Modulation Destinations

All three sources (touch initial, touch aftertouch, key tracking) can route to any voice-level destination:

| Destination | Description | Typical Use |
|-------------|-------------|-------------|
| `.oscillatorAmplitude` | Voice volume | Touch velocity, key balance |
| `.oscillatorBaseFrequency` | Pitch | Vibrato, pitch envelope |
| `.modulationIndex` | FM depth | Timbral expression |
| `.modulatingMultiplier` | FM ratio | Harmonic shifts |
| `.filterCutoff` | Filter frequency | Brightness control, key tracking |
| `.stereoSpreadAmount` | Stereo width | Dynamic stereo image |
| `.voiceLFOFrequency` | LFO rate | Meta-modulation effects |
| `.voiceLFOAmount` | LFO depth | Meta-modulation effects |

## Backward Compatibility

### Hardwired Touch Control (Default)

By default, touch modulation is **disabled**, and the hardwired touch control remains active:

- **Initial touch X** → Sets `baseAmplitude` directly (applied immediately)
- **Aftertouch X** → Updates `baseFilterCutoff` with smoothing and exponential scaling

This preserves the existing touch behavior that was implemented in Phase 5C.

### Enabling Routable Touch Modulation

To use routable touch modulation:

1. **Enable touch modulation** in voice parameters:
   ```swift
   voiceModulation.touchInitial.isEnabled = true
   voiceModulation.touchInitial.destination = .filterCutoff  // Route to filter instead
   ```

2. **Touch values are applied by modulation system** at 200 Hz

3. **Hardwired control still runs** for backward compatibility

⚠️ **Limitation:** If both hardwired and routable modulation target the same parameter, they will conflict (last one wins). For clean behavior, configure routable modulation to target different parameters than the hardwired defaults.

## Order of Operations

The modulation system applies modulators in this order (last one wins for the same destination):

1. **Base values** - Applied from `modulationState.baseAmplitude` and `baseFilterCutoff`
2. **Modulator envelope** - Hardwired to `modulationIndex`
3. **Auxiliary envelope** - Routable destination
4. **Voice LFO** - Routable destination
5. **Global LFO** - Routable destination  
6. **Touch initial** - Routable destination ← NEW
7. **Touch aftertouch** - Routable destination ← NEW
8. **Key tracking** - Routable destination ← NEW

If multiple modulators target the same destination, the last enabled modulator determines the final value. This is a current limitation of the sequential application architecture.

### Example Conflict

```swift
// This configuration has a conflict:
voiceModulation.voiceLFO.destination = .oscillatorAmplitude
voiceModulation.voiceLFO.isEnabled = true

voiceModulation.touchInitial.destination = .oscillatorAmplitude  // Same destination!
voiceModulation.touchInitial.isEnabled = true

// Result: Touch initial wins (applied last), LFO is overwritten
```

### Avoiding Conflicts

Route each modulator to a different destination:
```swift
voiceModulation.voiceLFO.destination = .filterCutoff
voiceModulation.touchInitial.destination = .oscillatorAmplitude
voiceModulation.touchAftertouch.destination = .modulationIndex
voiceModulation.keyTracking.destination = .filterCutoff  // Adds filter key tracking

// Result: All modulators work as expected
```

## Usage Examples

### Example 1: Touch Controls Amplitude (Default-Style)

```swift
voiceModulation.touchInitial = TouchInitialParameters(
    destination: .oscillatorAmplitude,
    amount: 1.0,         // Full velocity range
    isEnabled: true
)

voiceModulation.touchAftertouch = TouchAftertouchParameters(
    destination: .filterCutoff,
    amount: 1.0,         // Full filter sweep
    isEnabled: true
)
```

This replicates the hardwired behavior using the routable system.

### Example 2: Touch Controls FM Timbre

```swift
voiceModulation.touchInitial = TouchInitialParameters(
    destination: .modulationIndex,  // Bright when touched on outer edge
    amount: 5.0,                     // Wide FM range (0-5)
    isEnabled: true
)

voiceModulation.touchAftertouch = TouchAftertouchParameters(
    destination: .modulatingMultiplier,  // Shift harmonics with aftertouch
    amount: 2.0,                          // ±2 ratio units
    isEnabled: true
)
```

Expressive FM control with touch.

### Example 3: Key Tracking + Touch

```swift
voiceModulation.keyTracking = KeyTrackingParameters(
    destination: .filterCutoff,
    amount: 2.0,         // Higher notes are brighter (±2 octaves)
    isEnabled: true
)

voiceModulation.touchInitial = TouchInitialParameters(
    destination: .oscillatorAmplitude,
    amount: 1.0,
    isEnabled: true
)
```

Automatic filter keyboard tracking plus touch-sensitive volume.

### Example 4: Complex Expression Setup

```swift
// Voice LFO adds vibrato
voiceModulation.voiceLFO = LFOParameters(
    waveform: .sine,
    resetMode: .trigger,
    frequencyMode: .hertz,
    frequency: 5.0,
    destination: .oscillatorBaseFrequency,  // Vibrato
    amount: 0.1,
    isEnabled: true
)

// Touch position controls filter
voiceModulation.touchInitial = TouchInitialParameters(
    destination: .filterCutoff,
    amount: 2.0,  // ±2 octaves
    isEnabled: true
)

// Aftertouch controls LFO depth (meta-modulation)
voiceModulation.touchAftertouch = TouchAftertouchParameters(
    destination: .voiceLFOAmount,  // Control vibrato depth
    amount: 0.5,
    isEnabled: true
)

// Key tracking controls amplitude
voiceModulation.keyTracking = KeyTrackingParameters(
    destination: .oscillatorAmplitude,
    amount: -0.3,  // Negative: higher notes quieter
    isEnabled: true
)
```

Advanced expressive setup with four modulation sources.

## Testing

### Test 1: Touch Initial Routing

1. Disable hardwired control by setting:
   ```swift
   voiceModulation.touchInitial.destination = .filterCutoff
   voiceModulation.touchInitial.amount = 2.0
   voiceModulation.touchInitial.isEnabled = true
   ```

2. Touch outer edge of key → filter should be bright
3. Touch inner edge of key → filter should be dark
4. Amplitude should be constant (no touch velocity)

### Test 2: Touch Aftertouch Routing

1. Configure:
   ```swift
   voiceModulation.touchAftertouch.destination = .modulationIndex
   voiceModulation.touchAftertouch.amount = 5.0
   voiceModulation.touchAftertouch.isEnabled = true
   ```

2. Touch and hold a key
3. Move finger left → FM modulation decreases (darker timbre)
4. Move finger right → FM modulation increases (brighter timbre)

### Test 3: Key Tracking

1. Configure:
   ```swift
   voiceModulation.keyTracking.destination = .filterCutoff
   voiceModulation.keyTracking.amount = 2.0
   voiceModulation.keyTracking.isEnabled = true
   ```

2. Play low note → filter dark
3. Play high note → filter bright
4. Filter should scale logarithmically with pitch

### Test 4: Multiple Modulators

1. Enable voice LFO on amplitude
2. Enable touch initial on filter
3. Enable key tracking on FM modulation index
4. Play notes → all three modulators should work independently

## Known Limitations

### 1. Sequential Application (No Summing)

Multiple modulators targeting the same destination don't sum - the last enabled modulator wins.

**Future enhancement:** Implement modulation summing or mixing modes.

### 2. Hardwired Control Interference

The hardwired touch control in MainKeyboardView always runs, even when routable modulation is enabled.

**Current behavior:** Both systems apply, last one wins.  
**Future enhancement:** Detect routable modulation and disable hardwired control automatically.

### 3. Aftertouch Scaling Differences

The hardwired aftertouch has exponential scaling and smoothing. The routable aftertouch uses raw delta values.

**Workaround:** Use hardwired aftertouch for filter control (current default behavior).  
**Future enhancement:** Add sensitivity/curve parameters to touch modulation.

### 4. No Touch Pressure (Z-axis)

iOS doesn't provide touch pressure data, only X/Y position. Touch pressure would be ideal for modulation but is not available.

**Workaround:** Use touch X position and aftertouch movement instead.

## Future Enhancements

1. **Modulation summing** - Allow multiple modulators to sum on the same destination
2. **Modulation matrix UI** - Visual routing interface for modulation sources/destinations
3. **Sensitivity controls** - Adjustable curves for touch modulation
4. **Touch Y modulation** - Use vertical touch position as additional source
5. **Touch velocity** - Calculate velocity from touch movement speed
6. **Smart hardwire detection** - Auto-disable hardwired control when routable modulation is configured

## Phase 5D Completion

✅ **Touch initial modulation** - Implemented and tested  
✅ **Touch aftertouch modulation** - Implemented and tested  
✅ **Key tracking modulation** - Implemented and tested  
✅ **Routable destinations** - All voice-level parameters supported  
✅ **Backward compatibility** - Hardwired touch control preserved  
✅ **Documentation** - Complete usage guide

**Phase 5 is now complete!** All modulation sources are implemented:
- Phase 5A: ✅ Modulation data structures
- Phase 5B: ✅ Modulation envelopes
- Phase 5C: ✅ LFOs (per-voice and global)
- Phase 5D: ✅ Touch & key tracking

**Next phase:** Phase 6 - Preset System (save/load parameter sets)
