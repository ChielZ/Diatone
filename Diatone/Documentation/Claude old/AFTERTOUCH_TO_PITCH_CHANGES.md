# Aftertouch to Oscillator Pitch - Implementation Summary

## Overview
Added a new modulation routing: **Aftertouch → Oscillator Pitch**

This allows aftertouch (X-axis touch movement while holding a note) to directly modulate the pitch of the oscillator, providing expressive pitch bend capabilities.

## Changes Made

### 1. A6 ModulationSystem.swift

#### TouchAftertouchParameters
- **Added**: `amountToOscillatorPitch: Double` property
  - Bipolar modulation (±semitones)
  - Default value: 0.0
  - Comment updated from "Page 9, items 5-7" to "Page 9, items 5-8"
- **Updated**: `hasActiveDestinations` computed property to include the new destination check

#### ModulationRouter.calculateOscillatorPitch()
- **Added**: Two new parameters:
  - `aftertouchDelta: Double` - The change in touch position (-1.0 to +1.0)
  - `aftertouchAmount: Double` - The modulation amount in semitones
- **Updated**: Documentation comment to list Aftertouch as a source
- **Updated**: Formula documentation to include `aftertouchSemitones`
- **Implementation**: Aftertouch delta is converted to semitones and added to the total semitone offset before exponential frequency conversion

### 2. A2 PolyphonicVoice.swift

#### applyCombinedPitch() method
- **Added**: `aftertouchDelta: Double` parameter
- **Added**: `hasAftertouchToPitch` check in the guard statement
- **Updated**: Documentation comment to list Aftertouch as a source
- **Updated**: Call to `ModulationRouter.calculateOscillatorPitch()` to pass:
  - `aftertouchDelta: aftertouchDelta`
  - `aftertouchAmount: voiceModulation.touchAftertouch.amountToOscillatorPitch`

#### applyModulation() method
- **Updated**: Call to `applyCombinedPitch()` to pass `aftertouchDelta` parameter

## Technical Details

### Modulation Behavior
- **Type**: Bipolar, linear in semitone space
- **Range**: Configurable via `amountToOscillatorPitch` parameter
- **Combination**: Additive with other pitch modulation sources in semitone space:
  - Auxiliary Envelope pitch modulation
  - Voice LFO pitch modulation (vibrato)
  - Aftertouch pitch modulation (NEW)

### Signal Flow
1. Touch X position change is captured as `aftertouchDelta` (-1.0 to +1.0)
2. Delta is scaled by `amountToOscillatorPitch` to get semitones
3. Semitones are added to aux envelope and voice LFO contributions
4. Combined semitones are converted to frequency multiplier: `2^(semitones/12)`
5. Base frequency is multiplied by the combined factor
6. Both oscillators (left/right) are updated with the modulated frequency

### Example Use Cases
- **Pitch Bend**: Set amount to ±2.0 for a whole-step bend
- **Subtle Expression**: Set amount to ±0.5 for quarter-tone vibrato control
- **Dramatic Effects**: Set amount to ±12.0 for octave bends

## Preset Compatibility Note
⚠️ **Breaking Change**: Existing presets need to be updated to include the new `amountToOscillatorPitch` property in `TouchAftertouchParameters`. Old presets will fail to load without migration.

## UI Implementation (Future Work)
A UI control needs to be added to expose this parameter to users, likely in:
- **Page 9 (Touch Response)**: Add as item 8 "Aftertouch to Pitch"
- **Control Type**: Bipolar slider (-12 to +12 semitones)
- **Label**: "Aftertouch → Pitch" or "Touch Pitch Bend"

## Testing Recommendations
1. Set `amountToOscillatorPitch` to 2.0
2. Trigger a note and hold
3. Move finger horizontally across the key
4. Verify smooth pitch modulation
5. Test interaction with aux envelope pitch and voice LFO vibrato
6. Verify that key tracking filter behavior remains consistent (unaffected by pitch changes)
