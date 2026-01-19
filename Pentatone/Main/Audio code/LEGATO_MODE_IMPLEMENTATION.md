# Legato Mode Implementation

## Overview
Added a legato mode feature that allows smooth note transitions in monophonic mode without restarting envelopes. This is perfect for expressive playing styles where you want to maintain the current envelope state while changing pitch.

## Changes Made

### 1. PolyphonicVoice.swift
Added a new `retrigger()` method that updates voice parameters without restarting envelopes:

```swift
func retrigger(frequency: Double, initialTouchX: Double = 0.5, templateFilterCutoff: Double? = nil)
```

**What it does:**
- Updates oscillator frequency with smooth glide
- Updates amplitude based on new initial touch value
- Recalculates key tracking for the new note
- Updates filter cutoff with key tracking
- **Does NOT restart amplitude envelope**
- **Does NOT restart modulation envelopes**

**Differences from `trigger()`:**
- ❌ Does NOT call `envelope.reset()`
- ❌ Does NOT call `envelope.openGate()`
- ❌ Does NOT call `applyInitialEnvelopeModulation()`
- ✅ DOES update frequency and filter smoothly
- ✅ DOES update touch values for new note
- ✅ DOES recalculate key tracking

### 2. VoicePool.swift
Added legato mode support and modified voice allocation:

**New Property:**
```swift
var legatoMode: Bool = false
```

**Modified `allocateVoice()` method:**
```swift
// Check for legato conditions: monophonic mode + active voice + legato enabled
let isLegatoRetrigger = currentPolyphony == 1 && !voices[0].isAvailable && legatoMode
```

When legato conditions are met:
- Uses `voice.retrigger()` instead of `voice.trigger()`
- Updates key mapping and ownership
- Logs "Legato retrigger" for debugging

## Usage

### Enabling Legato Mode

```swift
// In your AudioEngine or wherever you manage VoicePool
voicePool.legatoMode = true
```

### Disabling Legato Mode

```swift
voicePool.legatoMode = false
```

### Testing

1. **Switch to monophonic mode:**
   ```swift
   voicePool.setPolyphony(1) { /* completion */ }
   ```

2. **Enable legato:**
   ```swift
   voicePool.legatoMode = true
   ```

3. **Play overlapping notes:**
   - Press note 1 → envelope starts attack
   - While note 1 is held, press note 2 → pitch changes but envelope continues
   - Release note 1 → no effect (note 2 owns the voice)
   - Release note 2 → envelope starts release

## Behavior Details

### When Legato Mode is ON (monophonic mode):
- First note: Normal trigger (starts envelopes)
- Subsequent notes (while first is playing): Legato retrigger
  - Pitch glides to new note
  - Filter cutoff updates with key tracking
  - Amplitude adjusts for new touch position
  - **Envelopes continue from current position**

### When Legato Mode is OFF (monophonic mode):
- Each note triggers fully
- Envelopes restart on every note
- Previous note is stolen (voice stealing with envelope restart)

### In Polyphonic Mode:
- Legato mode has no effect
- Each note gets its own voice
- All voices have independent envelopes

## Key Features

✅ **Zero-latency pitch changes** - Frequency updates immediately  
✅ **Smooth transitions** - Uses 5ms ramps for parameter changes  
✅ **Key tracking support** - Filter cutoff tracks the new note  
✅ **Touch sensitivity** - Amplitude responds to new touch position  
✅ **Envelope continuity** - All three envelopes (amplitude, modulator, auxiliary) continue  
✅ **Clean implementation** - Minimal code changes, no breaking changes  
✅ **Debug logging** - Clear console output distinguishes legato from normal triggers  

## Console Output Examples

### Normal Trigger (First Note):
```
🎵 Key 5: Allocated voice, base frequency 440.0 Hz → final 440.0 Hz (×1.0), touchX 0.50
```

### Legato Retrigger (Subsequent Note):
```
🎵 Legato retrigger: frequency 523.25 Hz, touchX 0.65
🎵 Key 7: Legato retrigger, frequency 523.25 Hz → final 523.25 Hz (×1.0), touchX 0.65
```

## Implementation Notes

1. **No polyphonic mode changes** - Legato only works in monophonic mode (`currentPolyphony == 1`)

2. **Voice availability check** - Legato only triggers when voice is already active (`!voices[0].isAvailable`)

3. **Envelope state preservation** - The voice maintains its envelope position, including:
   - Attack phase progress
   - Decay phase progress
   - Sustain level
   - Release phase (if triggered)

4. **Modulation compatibility** - All modulation sources continue to work:
   - Global LFO continues
   - Voice LFO continues (doesn't reset unless reset mode is "trigger")
   - Envelopes continue from current position
   - Key tracking recalculates for new note

## Future Enhancements (Optional)

- **Portamento/Glide time control:** Add a glide time parameter to control how fast the pitch transitions
- **Legato threshold:** Only trigger legato if notes overlap by X milliseconds
- **Legato reset options:** Allow envelope restart on specific conditions (e.g., after X seconds)
- **Visual feedback:** Add UI indicator when legato mode is active

## Testing Checklist

- [ ] Legato works in monophonic mode
- [ ] Legato has no effect in polyphonic mode
- [ ] First note triggers normally (envelopes start)
- [ ] Second note (overlapping) uses legato (envelopes continue)
- [ ] Pitch changes smoothly
- [ ] Filter tracks new note correctly
- [ ] Amplitude responds to new touch position
- [ ] Release works correctly on final note
- [ ] Console logs show "Legato retrigger" for legato notes
- [ ] No crashes or audio glitches
