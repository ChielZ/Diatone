# Voice LFO Unipolar Modulation Changes

## Summary

The Voice LFO has been converted from **bipolar** (±1.0) to **unipolar** (0.0 to 1.0) modulation. All waveforms now start at their minimum value (the nominal, unmodulated parameter value) and rise upward.

## Key Changes

### 1. Waveform Generation (`LFOWaveform.value(at:bipolar:)`)
- Added `bipolar` parameter to switch between bipolar and unipolar modes
- **Bipolar mode** (Global LFO): Returns -1.0 to +1.0 (unchanged behavior)
- **Unipolar mode** (Voice LFO): Returns 0.0 to 1.0 with phase adjustments

#### Waveform Transformations (Unipolar Mode)
- **Sine**: Phase shifted -90° to start at minimum (bottom of wave)
- **Triangle**: Starts at 0, rises to 1 at midpoint, falls back to 0
- **Square**: Low (0) for first half, high (1) for second half
- **Sawtooth**: Linear rise from 0 to 1
- **Reverse Sawtooth**: Starts at 1, falls to 0 (now redundant - use negative amounts instead)

### 2. Voice LFO Raw Value (`VoiceLFOParameters.rawValue(at:)`)
- Now calls `waveform.value(at: phase, bipolar: false)`
- Returns 0.0 to 1.0 instead of -1.0 to +1.0

### 3. Global LFO Raw Value (`GlobalLFOParameters.rawValue(at:)`)
- Now explicitly calls `waveform.value(at: phase, bipolar: true)`
- Maintains unchanged bipolar behavior (-1.0 to +1.0)

### 4. Modulation Calculations (`ModulationRouter`)

All Voice LFO modulation calculations now treat the LFO value as unipolar:

#### Oscillator Pitch (`calculateOscillatorPitch`)
- **Before**: `lfoSemitones = voiceLFOValue × amount` (bipolar: -amount to +amount)
- **After**: `lfoSemitones = voiceLFOValue × amount` (unipolar: 0 to +amount)
- **Effect**: LFO peak raises pitch by full amount, LFO minimum leaves pitch unchanged

#### Modulation Index (`calculateModulationIndex`)
- **Before**: `lfoOffset = voiceLFOValue × amount` (bipolar: -amount to +amount)
- **After**: `lfoOffset = voiceLFOValue × amount` (unipolar: 0 to +amount)
- **Effect**: LFO peak adds full amount, LFO minimum adds nothing

#### Filter Frequency (`calculateFilterFrequency` and `calculateFilterFrequencyContinuous`)
- **Before**: `voiceLFOOctaves = voiceLFOValue × amount` (bipolar: -amount to +amount octaves)
- **After**: `voiceLFOOctaves = voiceLFOValue × amount` (unipolar: 0 to +amount octaves)
- **Effect**: LFO peak shifts filter by full amount, LFO minimum leaves filter unchanged

## Example: Square Wave at 1 Hz with 2 Semitones to Pitch

### Before (Bipolar)
- t=0.0s: LFO value = +1.0 → Pitch = base + 2 semitones
- t=0.5s: LFO value = -1.0 → Pitch = base - 2 semitones
- t=1.0s: LFO value = +1.0 → Pitch = base + 2 semitones

### After (Unipolar)
- t=0.0s: LFO value = 0.0 → Pitch = base (nominal frequency)
- t=0.5s: LFO value = 1.0 → Pitch = base + 2 semitones
- t=1.0s: LFO value = 0.0 → Pitch = base (nominal frequency)

## Benefits

1. **Harmony with Triggering**: The note starts at its nominal frequency, matching user expectations and envelope initial states
2. **Precise Note Values**: Users can set exact pitch intervals (e.g., "add a perfect fifth on LFO peak")
3. **Directional Control**: Use positive amounts to raise parameters, negative amounts to lower them
4. **Predictable Behavior**: All modulation starts from the base value and moves in one direction

## Backwards Compatibility

### Global LFO
- **No changes** - remains fully bipolar
- All existing presets and behavior preserved

### Voice LFO
- **Breaking change** - existing presets will sound different
- Waveforms now start at minimum instead of center
- Consider migrating existing presets by:
  - Doubling the amount values (to maintain peak deviation)
  - Adjusting phase/timing expectations

## Code Changes Made

1. `LFOWaveform.value(at:bipolar:)` - Added bipolar parameter, implemented unipolar waveforms
2. `VoiceLFOParameters.rawValue(at:)` - Now uses `bipolar: false`
3. `GlobalLFOParameters.rawValue(at:)` - Now explicitly uses `bipolar: true`
4. `ModulationRouter.calculateOscillatorPitch()` - Updated comments to clarify unipolar behavior
5. `ModulationRouter.calculateModulationIndex()` - Updated comments to clarify unipolar behavior
6. `ModulationRouter.calculateFilterFrequency()` - Updated comments to clarify unipolar behavior
7. `ModulationRouter.calculateFilterFrequencyContinuous()` - Updated comments to clarify unipolar behavior
8. `VoiceLFOParameters` struct comments - Clarified unipolar behavior and amount polarity

## Testing Recommendations

1. Test all Voice LFO waveforms with positive amounts (should add to base parameter)
2. Test all Voice LFO waveforms with negative amounts (should subtract from base parameter)
3. Verify sine and triangle waves start at minimum (not at zero-crossing)
4. Verify square wave starts low (not high)
5. Confirm Global LFO remains unchanged (bipolar, tremolo effect works correctly)
6. Test with LFO delay/ramp to ensure smooth fade-in
7. Verify interaction with envelopes and other modulation sources
