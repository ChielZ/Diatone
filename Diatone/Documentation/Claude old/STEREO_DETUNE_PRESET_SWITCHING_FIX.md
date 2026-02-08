# Stereo Detune Preset Switching Fix

## Problem

When switching between presets, stereo detune behavior was erratic:

1. **Symptom**: After loading a preset with no modulation, users heard tremolo/vibrato-like effects
2. **Rate**: Effect rate was proportional to note frequency (faster on higher notes)
3. **Variability**: Effect rate changed unpredictably between preset loads
4. **Inconsistency**: After touching stereo amount slider, voices became inconsistent in timbre/loudness
5. **Reproducibility**: Perfectly reproducible across sessions, but couldn't be triggered from clean state

## Root Cause

The issue was caused by **incomplete modulation state reset** during preset switching:

### What Was Happening

1. **Previous Preset State Persisted**:
   - When switching presets, `silenceAndResetAllVoices()` only reset loudness envelope timing
   - Auxiliary and modulator envelope times were NOT reset
   - Voice LFO phase and ramp factors were NOT reset
   - **Most critically**: `currentFrequency` retained the modulated value from the previous preset

2. **Stereo Detune Applied to Wrong Frequency**:
   - When new preset loaded, `updateOscillatorParameters()` was called
   - This updated `frequencyOffsetCents` and `frequencyOffsetHz`
   - The `didSet` observers triggered `updateOscillatorFrequencies()`
   - **BUG**: `updateOscillatorFrequencies()` calculated detune using `currentFrequency`
   - But `currentFrequency` still contained a **pitch-modulated value** from the previous preset!
   - Example: If previous preset had +12 semitones pitch modulation, and note was A440:
     - `currentFrequency` = 880 Hz (modulated)
     - New preset loaded with 5 cents detune
     - Detune applied to 880 Hz instead of 440 Hz
     - Result: 2x the expected detuning amount

3. **Modulation Loop Compounded the Error**:
   - Modulation loop continued running with stale envelope times
   - It read the **incorrectly detuned** oscillator frequencies
   - Applied new modulation on top of the wrong base
   - Created chaotic, tempo-dependent wobbling effects

### Why Touching Stereo Amount "Fixed" It

- Adjusting stereo amount re-triggered `updateOscillatorFrequencies()`
- At this point, modulation state had been updated by the new preset
- `currentFrequency` was now correct (either reset by new note or by time passing)
- Detune applied correctly this time

### Why It Was Proportional to Note Frequency

- The error was a **ratio mismatch**, not a fixed Hz offset
- If `currentFrequency` was 2x the correct value, detune was 2x too strong
- Higher notes had higher modulated frequencies → more noticeable effects

## Solution

Enhanced `silenceAndResetAllVoices()` to perform a **complete modulation state reset**:

### Changes Made to `A3 VoicePool.swift`

```swift
func silenceAndResetAllVoices() {
    for voice in voices {
        // ... existing fader reset code ...
        
        // CRITICAL: Reset ALL envelope timing, not just loudness
        voice.modulationState.isGateOpen = false
        voice.modulationState.modulatorEnvelopeTime = 0.0
        voice.modulationState.auxiliaryEnvelopeTime = 0.0
        voice.modulationState.loudnessEnvelopeTime = 0.0
        voice.modulationState.modulatorSustainLevel = 0.0
        voice.modulationState.auxiliarySustainLevel = 0.0
        voice.modulationState.loudnessStartLevel = 0.0
        voice.modulationState.loudnessSustainLevel = 0.0
        
        // CRITICAL: Reset voice LFO phase and ramp
        voice.modulationState.voiceLFOPhase = 0.0
        voice.modulationState.voiceLFORampFactor = 0.0
        voice.modulationState.voiceLFODelayTimer = 0.0
        
        // CRITICAL: Reset frequency tracking
        // currentFrequency is used by updateOscillatorFrequencies()
        // If it contains a modulated value, detune will be applied incorrectly
        voice.modulationState.currentFrequency = voice.modulationState.baseFrequency
    }
    
    // ... existing cleanup code ...
}
```

### Why This Works

1. **Complete State Reset**: All envelope times, LFO states, and frequency tracking reset to clean values
2. **Correct Base Frequency**: `currentFrequency` is set to `baseFrequency`, ensuring detune calculations use the unmodulated value
3. **No Interference**: Modulation loop sees clean state and doesn't apply stale modulation
4. **Surgical Fix**: Only touched `silenceAndResetAllVoices()`, no changes to complex modulation logic

## Testing Checklist

- [ ] Load default preset → verify stereo detune works as expected
- [ ] Switch to preset with heavy pitch modulation → verify it works correctly
- [ ] Switch to preset with no modulation at all → verify NO unwanted tremolo/vibrato
- [ ] Play different notes → verify detune rate is consistent (or proportional, depending on mode)
- [ ] Adjust stereo amount slider → verify voices remain consistent in timbre/loudness
- [ ] Repeat preset switching multiple times → verify behavior is consistent and predictable
- [ ] Test with both proportional (cents) and constant (Hz) detune modes
- [ ] Test voice stealing during preset transitions → verify smooth transitions

## Technical Details

### Modulation State Fields Reset

| Field | Purpose | Why Reset Needed |
|-------|---------|------------------|
| `modulatorEnvelopeTime` | Mod envelope progress | Prevents stale envelope values from modulating mod index |
| `auxiliaryEnvelopeTime` | Aux envelope progress | Prevents stale envelope values from modulating pitch/filter |
| `loudnessEnvelopeTime` | Loudness envelope progress | Prevents unexpected volume changes |
| `*SustainLevel` fields | Captured envelope values for release | Prevents incorrect release curves |
| `voiceLFOPhase` | Current LFO cycle position | Prevents LFO from continuing mid-cycle |
| `voiceLFORampFactor` | LFO delay ramp progress | Prevents delayed LFO from suddenly appearing |
| `currentFrequency` | **Last modulated frequency** | **Prevents detune from using wrong base frequency** |

### Design Philosophy

The fix follows the principle of **"clean slate" preset switching**:

- When a preset loads, voices should be in a completely neutral state
- No modulation state should carry over from the previous preset
- All parameters should apply cleanly without fighting against stale values
- The only state that persists is the audio node graph structure itself

This ensures predictable, glitch-free preset transitions.
