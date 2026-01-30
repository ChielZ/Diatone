# Voice LFO Hybrid Modulation - Final Implementation

## Summary

The Voice LFO uses **hybrid modulation** behavior optimized for different use cases:
- **Sine/Triangle**: Bipolar ±1.0 (centered around nominal value, **both start at 0**, perfect for vibrato)
- **Square/Sawtooth/Reverse Saw**: Unipolar 0.0 to 2.0 (rhythmic pulsing from base upward, double range)

This gives you the best of both worlds: smooth waveforms oscillate naturally around the base parameter (ideal for musical vibrato), while sharp waveforms create rhythmic modulation effects (ideal for pulsing/sequencer-style modulation).

## Voice LFO Waveform Behavior Details

### Smooth Waveforms (Bipolar ±1.0, Start at Zero)

**Sine Wave:**
- Range: -1 to +1
- **Phase: Starts at 0** (natural sine phase)
- Progression: 0 → +1 (peak) → 0 → -1 (trough) → 0
- Perfect for: Smooth vibrato, natural pitch oscillation

**Triangle Wave:**
- Range: -1 to +1
- **Phase: Starts at 0** (shifted +90° from standard triangle)
- Progression: 0 → +1 (peak) → 0 → -1 (trough) → 0
- Perfect for: Linear vibrato, smooth filter sweeps

**Key benefit**: Both sine and triangle now start at zero, providing symmetrical modulation from the start of the note. This is ideal for vibrato where you want the pitch to be centered on the base frequency immediately.

### Sharp Waveforms (Unipolar 0 to 2, Start at Minimum)

**Square Wave:**
- Range: 0 to 2
- Phase: Starts at 0 (low state)
- Progression: 0 (holds for half cycle) → 2 (holds for half cycle) → 0
- Perfect for: Rhythmic interval jumps, gate-like modulation

**Sawtooth Wave:**
- Range: 0 to 2
- Phase: Starts at 0
- Progression: 0 → 2 (linear rise) → 0 (instant drop)
- Perfect for: Building intensity effects, rhythmic sweeps

**Reverse Sawtooth Wave:**
- Range: 2 to 0
- Phase: Starts at 2 (instant jump to peak)
- Progression: 2 → 0 (linear fall) → 2 (instant jump)
- Perfect for: Falling intensity effects
- Note: Excluded from Voice LFO UI (redundant - use negative amounts with sawtooth instead)

## Example Use Cases

### Triangle Wave Vibrato (1 Hz, 2 Semitones) - UPDATED
Perfect for natural linear pitch vibrato:
- t=0.00s: Value = 0.0 → Pitch = base (**now starts centered!**)
- t=0.25s: Value = +1.0 → Pitch = base + 2 semitones (peak high)
- t=0.50s: Value = 0.0 → Pitch = base (back to center)
- t=0.75s: Value = -1.0 → Pitch = base - 2 semitones (peak low)
- t=1.00s: Value = 0.0 → Pitch = base (cycle complete)

**Result**: Smooth, linear vibrato oscillating ±2 semitones around the base pitch, starting centered

### Sine Wave Vibrato (1 Hz, 2 Semitones)
Perfect for natural smooth pitch vibrato:
- t=0.00s: Value = 0.0 → Pitch = base (starting at center)
- t=0.25s: Value = +1.0 → Pitch = base + 2 semitones (peak high)
- t=0.50s: Value = 0.0 → Pitch = base (back to center)
- t=0.75s: Value = -1.0 → Pitch = base - 2 semitones (peak low)
- t=1.00s: Value = 0.0 → Pitch = base (cycle complete)

**Result**: Smooth, musical vibrato oscillating ±2 semitones around the base pitch

### Square Wave Pulse (1 Hz, 2 Semitones)
Perfect for rhythmic pitch stepping:
- t=0.0s: Value = 0.0 → Pitch = base (nominal frequency)
- t=0.5s: Value = 2.0 → Pitch = base + 4 semitones (instant jump to major third)
- t=1.0s: Value = 0.0 → Pitch = base (instant drop back)

**Result**: Rhythmic pulsing that jumps from base to +4 semitones (maintains same peak deviation as sine's ±2)

### Triangle Filter Sweep (2 Hz, 1 Octave)
Smooth bidirectional filter sweep:
- Starts at base cutoff (centered)
- Rises to +1 octave above base cutoff
- Falls to -1 octave below base cutoff
- Returns to base cutoff
- Perfect for smooth "breathing" filter effect

### Sawtooth Timbre Pulse (4 Hz, 2.0 Modulation Index)
Rhythmic brightness sweep:
- Gradually rises from base index to +4.0 above base
- Instant drop back to base
- Creates "building brightness" effect that resets rhythmically

## Phase Comparison

### Triangle Wave Phase Shift

**Before (Started at -1):**
- t=0.00: -1.0 (started at trough)
- t=0.25: 0.0 (rising through center)
- t=0.50: +1.0 (peak)
- t=0.75: 0.0 (falling through center)
- t=1.00: -1.0 (back to trough)

**After (Starts at 0, +90° phase shift):**
- t=0.00: 0.0 (starts at center, like sine)
- t=0.25: +1.0 (peak)
- t=0.50: 0.0 (back to center)
- t=0.75: -1.0 (trough)
- t=1.00: 0.0 (back to center)

This makes triangle wave behavior consistent with sine wave for centered vibrato effects.

## Benefits

### 1. **Centered Vibrato from Start** (Sine/Triangle)
- Both smooth waveforms now start at 0 (centered on base parameter)
- No initial pitch deviation when note triggers
- Symmetrical modulation from the very first sample
- Perfect for expressive pitch modulation that doesn't "start sharp" or "start flat"

### 2. **Musical Vibrato** (Sine/Triangle)
- Natural oscillation around the base parameter value
- Intuitive amount values (2 semitones = ±2 semitone vibrato)
- Works identically to classic analog synthesizer LFOs
- Linear (triangle) and smooth (sine) options for different musical textures

### 3. **Rhythmic Effects** (Square/Sawtooth)
- Clear rhythmic pulsing from base value upward
- Double range (0-2) maintains consistent modulation depth with sine/triangle
- Predictable behavior: base value when low, 2× amount when high
- Perfect for sequencer-style modulation

### 4. **Consistent Modulation Range**
- All waveforms have the same total modulation range (2 units peak-to-peak)
- Switching waveforms maintains similar perceived modulation intensity
- Amount parameter has consistent meaning across all waveforms

### 5. **Best of Both Worlds**
- No compromises: each waveform behaves optimally for its intended use
- Sine/triangle for smooth musical modulation (centered, starts at 0)
- Square/sawtooth for rhythmic effects (unipolar pulse)

## UI Changes

### Voice LFO Waveform Selection
- **Available waveforms**: Sine, Triangle, Square, Sawtooth (4 options)
- **Excluded**: Reverse Sawtooth (redundant - use negative amounts with sawtooth instead)
- Custom `VoiceLFOWaveformRow` component filters the selection

### Global LFO (Unchanged)
- **Available waveforms**: All 5 waveforms including Reverse Sawtooth
- Maintains full bipolar behavior for all waveforms
- No changes to existing presets or behavior

## Testing Recommendations

### Triangle Wave Phase Testing (Priority)
1. Set Voice LFO to triangle, 1Hz, 2 semitones to pitch
2. Trigger a note and verify pitch starts at base frequency (not 2 semitones flat)
3. Verify smooth rise to +2 semitones, then fall to -2 semitones
4. Compare with sine wave - phase behavior should be identical (both start at 0)

### Sine/Triangle Comparison
1. A/B test sine vs triangle at same rate and amount
2. Verify both start centered on base pitch
3. Confirm triangle has linear transitions while sine is smooth
4. Check that peak deviations match (±amount)

### Square/Sawtooth (Rhythmic Pulse)
1. Test square at 1Hz, 2 semitones - verify 0 to +4 semitone jump
2. Test sawtooth - verify gradual rise to +4, instant drop
3. Confirm both have same peak deviation (2× amount)

### Filter Modulation
1. Test triangle with filter - should create smooth "breathing" centered on base cutoff
2. Test square with filter - should create rhythmic "on/off" filter effect
3. Verify key tracking still works (note-on property, independent of LFO)

### Global LFO Unchanged
1. Verify all Global LFO waveforms remain bipolar
2. Test tremolo effect (should oscillate volume up and down)
3. Confirm FM ratio modulation works correctly (bipolar)
4. Verify all 5 waveforms available in Global LFO UI

## Code Changes Summary

1. **`LFOWaveform.value(at:bipolar:)`** - Updated triangle waveform for Voice LFO mode:
   - Added +90° phase shift (`normalizedPhase + 0.25`)
   - Ensures triangle starts at 0, matching sine wave behavior
   - Bipolar mode (Global LFO) unchanged

2. **`VoiceLFOWaveformRow`** - Custom UI component:
   - Filters out reverse sawtooth from selection
   - Only shows: Sine, Triangle, Square, Sawtooth

3. **Documentation** - Updated comments throughout to reflect phase shift

4. **All modulation router calculations** - Already handle hybrid behavior correctly
