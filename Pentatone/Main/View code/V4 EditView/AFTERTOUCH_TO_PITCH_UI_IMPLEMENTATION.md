# Aftertouch to Pitch - UI Implementation Summary

## Overview
Added UI control for the new **Aftertouch → Oscillator Pitch** modulation routing on Page 9 (Touch Response).

This feature temporarily replaces "Initial Touch → Aux Envelope Pitch Amount" (row 3) for testing purposes. The old routing will be removed from the engine later once this new control is validated.

## Changes Made

### 1. A7 ParameterManager.swift
Added new update method to handle the parameter change:

```swift
/// Update aftertouch amount to oscillator pitch
func updateAftertouchAmountToPitch(_ value: Double) {
    voiceTemplate.modulation.touchAftertouch.amountToOscillatorPitch = value
}
```

This method is placed logically with the other aftertouch update methods (before filter, modulator level, and vibrato).

### 2. V4-S09 ParameterPage9View.swift

#### Header Comment
Updated to reflect the replacement:
- Changed row 3 from "Initial touch to aux envelope pitch amount"
- To: "Aftertouch to oscillator pitch amount (REPLACING: Initial touch to aux envelope pitch amount)"

#### Row 3 Control
Replaced the slider with new parameters:

**Label**: `"AFTER TO PITCH"`

**Binding**:
- Get: `paramManager.voiceTemplate.modulation.touchAftertouch.amountToOscillatorPitch`
- Set: Calls `paramManager.updateAftertouchAmountToPitch(newValue)` and `applyModulationToAllVoices()`

**Range**: `0...12`
- 0 = no pitch bend
- 12 = ±1 octave pitch bend (12 semitones up or down)

**Step**: `1.0` (whole semitone increments)

**Display Format**: 
```swift
displayFormatter: { value in
    let semitones = Int(value)
    return semitones == 1 ? "±\(semitones) st" : "±\(semitones) st"
}
```
- Shows as "±0 st", "±1 st", "±2 st", ... "±12 st"
- The ± symbol indicates bidirectional control (pitch bends up or down based on finger movement direction)

## User Experience

### How It Works
1. User sets the slider to a desired semitone range (e.g., 2 semitones)
2. When playing a note and holding it:
   - Moving finger **toward center** of key → pitch bends **up** by up to 2 semitones
   - Moving finger **toward edge** of key → pitch bends **down** by up to 2 semitones
   - Aftertouch delta ranges from -1.0 to +1.0, scaled by the semitone amount

### Typical Settings
- **0 st** - No pitch bend (default, maintains backward compatibility)
- **2 st** - Whole-step bend (±1 whole tone) - subtle expression
- **5 st** - Perfect fourth bend - moderate expression
- **7 st** - Perfect fifth bend - guitar-like bending
- **12 st** - Octave bend - dramatic effects

### Interaction with Other Modulation
The aftertouch pitch bend works additively with:
- **Auxiliary Envelope** pitch sweeps
- **Voice LFO** vibrato
- **Aftertouch to Vibrato** meta-modulation (row 7)

All pitch modulations combine in semitone space before being converted to frequency.

## Technical Notes

### Parameter Flow
```
User adjusts slider (0-12 semitones)
    ↓
updateAftertouchAmountToPitch() called
    ↓
voiceTemplate.modulation.touchAftertouch.amountToOscillatorPitch updated
    ↓
applyModulationToAllVoices() called
    ↓
All voices receive new modulation parameters
    ↓
ModulationRouter.calculateOscillatorPitch() uses the value
    ↓
Pitch modulation applied at control rate (200 Hz)
```

### Preset Compatibility
⚠️ **Breaking Change**: Presets saved before this change will need migration to include the new parameter. The default value of 0.0 maintains previous behavior (no aftertouch pitch bend).

### Future Work
- Remove the "Initial Touch → Aux Envelope Pitch Amount" routing from the engine (currently still exists but unused)
- Reorganize the Touch Response page layout once testing is complete
- Consider adding negative range option if users want inverted control (toward center = bend down)

## Testing Checklist
- [x] Parameter manager method added
- [x] UI control implemented
- [x] Display format shows semitones correctly
- [x] Range allows 0-12 semitones (0-1 octave)
- [x] Step size is 1.0 (whole semitone increments)
- [ ] Test with various semitone values (2, 5, 7, 12)
- [ ] Verify interaction with other pitch modulation sources
- [ ] Test in combination with vibrato meta-modulation
- [ ] Verify preset loading/saving with new parameter
