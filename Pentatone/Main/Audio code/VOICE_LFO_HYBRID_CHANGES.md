# Voice LFO Hybrid Modulation Changes

## Summary

The Voice LFO uses **hybrid modulation** behavior optimized for different use cases:
- **Sine/Triangle**: Bipolar ±1.0 (centered around nominal value, perfect for vibrato)
- **Square/Sawtooth/Reverse Saw**: Unipolar 0.0 to 2.0 (rhythmic pulsing from base upward, double range)

This gives you the best of both worlds: smooth waveforms oscillate naturally around the base parameter (ideal for musical vibrato), while sharp waveforms create rhythmic modulation effects (ideal for pulsing/sequencer-style modulation).

## Key Changes

### 1. Waveform Generation (`LFOWaveform.value(at:bipolar:)`)
- Added `bipolar` parameter to distinguish between Global LFO and Voice LFO behavior
- **Bipolar mode** (Global LFO): All waveforms return -1.0 to +1.0 (unchanged)
- **Voice LFO mode** (bipolar = false): Hybrid behavior based on waveform type

#### Voice LFO Waveform Behavior (bipolar = false)

**Smooth Waveforms (Bipolar ±1.0):**
- **Sine**: -1 to +1 (centered vibrato, starts at 0, rises to +1, dips to -1, returns to 0)
- **Triangle**: -1 to +1 (centered vibrato, starts at -1, rises to +1, falls to -1)

**Sharp Waveforms (Unipolar 0 to 2):**
- **Square**: 0 to 2 (low 0 for first half cycle, high 2 for second half)
- **Sawtooth**: 0 to 2 (linear rise from 0 to 2, instant drop)
- **Reverse Sawtooth**: 2 to 0 (starts at 2, linear fall to 0)

### 2. Voice LFO Raw Value (`VoiceLFOParameters.rawValue(at:)`)
- Now calls `waveform.value(at: phase, bipolar: false)`
- Returns hybrid values: sine/triangle (-1 to +1), square/sawtooth (0 to 2)

### 3. Global LFO Raw Value (`GlobalLFOParameters.rawValue(at:)`)
- Now explicitly calls `waveform.value(at: phase, bipolar: true)`
- Maintains unchanged bipolar behavior (-1.0 to +1.0) for all waveforms

### 4. Modulation Calculations (`ModulationRouter`)

All Voice LFO modulation calculations handle the hybrid behavior automatically:

#### Oscillator Pitch (`calculateOscillatorPitch`)
- **Sine/Triangle**: `lfoSemitones = voiceLFOValue × amount` where value ranges ±1
  - Example: 2 semitones amount → -2 to +2 semitones (vibrato centered on base pitch)
- **Square/Sawtooth**: `lfoSemitones = voiceLFOValue × amount` where value ranges 0 to 2
  - Example: 2 semitones amount → 0 to +4 semitones (rhythmic pulse from base upward)

#### Modulation Index (`calculateModulationIndex`)
- **Sine/Triangle**: `lfoOffset = voiceLFOValue × amount` (±amount around base)
- **Square/Sawtooth**: `lfoOffset = voiceLFOValue × amount` (0 to 2×amount from base)

#### Filter Frequency (`calculateFilterFrequency` and `calculateFilterFrequencyContinuous`)
- **Sine/Triangle**: `voiceLFOOctaves = voiceLFOValue × amount` (±amount octaves around base)
- **Square/Sawtooth**: `voiceLFOOctaves = voiceLFOValue × amount` (0 to 2×amount octaves from base)

## Example Use Cases

### Sine Wave Vibrato (1 Hz, 2 Semitones)
Perfect for natural pitch vibrato:
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
- Starts at -1 octave below base cutoff
- Rises to +1 octave above base cutoff
- Falls back to -1 octave below
- Perfect for smooth "breathing" filter effect

### Sawtooth Timbre Pulse (4 Hz, 2.0 Modulation Index)
Rhythmic brightness sweep:
- Gradually rises from base index to +4.0 above base
- Instant drop back to base
- Creates "building brightness" effect that resets rhythmically

## Benefits

### 1. **Musical Vibrato** (Sine/Triangle)
- Natural oscillation around the base parameter value
- Intuitive amount values (2 semitones = ±2 semitone vibrato)
- Perfect for expressive pitch modulation
- Works identically to classic analog synthesizer LFOs

### 2. **Rhythmic Effects** (Square/Sawtooth)
- Clear rhythmic pulsing from base value upward
- Double range (0-2) maintains consistent modulation depth with sine/triangle
- Predictable behavior: base value when low, 2× amount when high
- Perfect for sequencer-style modulation

### 3. **Consistent Modulation Range**
- All waveforms have the same total modulation range (2 units peak-to-peak)
- Switching waveforms maintains similar perceived modulation intensity
- Amount parameter has consistent meaning across all waveforms

### 4. **Best of Both Worlds**
- No compromises: each waveform behaves optimally for its intended use
- Sine/triangle for smooth musical modulation (centered)
- Square/sawtooth for rhythmic effects (unipolar pulse)

## Backwards Compatibility

### Global LFO
- **No changes** - remains fully bipolar for all waveforms
- All existing presets and behavior preserved

### Voice LFO
- **Behavioral change** - existing presets will sound different
- Sine and triangle now create centered vibrato instead of unipolar rise
- Square and sawtooth now have 2× range (peak value doubles)

### Migration Notes
- **Sine/Triangle presets**: Will now oscillate around base instead of rising from it
  - This is generally more musical for vibrato
  - No amount adjustment needed - range is equivalent
- **Square/Sawtooth presets**: Peak modulation doubles
  - To maintain same peak deviation, halve the amount values
  - Or keep amounts and enjoy the extra intensity!

## Testing Recommendations

### Sine/Triangle (Centered Vibrato)
1. Set Voice LFO to sine, 1Hz, 2 semitones to pitch
2. Verify smooth vibrato centered on base pitch (±2 semitones)
3. Test with different frequencies - should remain centered
4. Try triangle - should have same range but linear transitions

### Square/Sawtooth (Rhythmic Pulse)
1. Set Voice LFO to square, 1Hz, 2 semitones to pitch
2. Verify half cycle at base, half cycle at +4 semitones
3. Confirm instant transitions (no ramping)
4. Try sawtooth - should rise smoothly to +4, instant drop

### Filter Modulation
1. Test sine with filter - should create smooth "breathing" around base cutoff
2. Test square with filter - should create rhythmic "on/off" filter effect
3. Verify key tracking still works (note-on property, independent of LFO)

### Modulation Index
1. Test sine with mod index - smooth timbre oscillation around base
2. Test sawtooth with mod index - building brightness effect
3. Verify interaction with mod envelope (both should sum correctly)

### LFO Delay/Ramp
1. Verify delay works for all waveforms
2. Confirm ramp scales from 0 to full effect smoothly
3. Test interaction with envelope modulation

### Global LFO Unchanged
1. Verify all Global LFO waveforms remain bipolar
2. Test tremolo effect (should oscillate volume up and down)
3. Confirm FM ratio modulation works correctly (bipolar)
