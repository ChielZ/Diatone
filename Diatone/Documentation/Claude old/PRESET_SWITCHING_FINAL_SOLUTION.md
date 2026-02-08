# Preset Switching: Complete Fix - Final Solution

## The Core Problem

When switching presets, voices were getting **inconsistent modulated parameter values** (modulatingMultiplier, modulationIndex, filter cutoff) due to:

1. **Stale modulation state** from the previous preset
2. **Race conditions** between parameter resets and modulation loop updates
3. **recreateOscillators()** reading transient oscillator values instead of base values

## Design Requirements

**For normal playing:**
- Modulation MUST run continuously on ALL voices at ALL times
- No interruptions, no filtering by availability status
- Smooth, continuous modulation is essential for proper sound

**For preset switching:**
- It's perfectly fine to completely reset/discontinue modulation
- Need a clean slate with NO carry-over from previous preset
- Consistency across all voices is critical

## The Complete Solution (3 Parts)

### Part 1: Reset All Parameters in silenceAndResetAllVoices()

**File: A3 VoicePool.swift**

Reset BOTH modulation state AND actual audio parameters:

```swift
func silenceAndResetAllVoices() {
    for voice in voices {
        // ... fader reset ...
        
        // Reset modulation state variables
        voice.modulationState.isGateOpen = false
        voice.modulationState.modulatorEnvelopeTime = 0.0
        voice.modulationState.auxiliaryEnvelopeTime = 0.0
        voice.modulationState.loudnessEnvelopeTime = 0.0
        voice.modulationState.voiceLFOPhase = 0.0
        voice.modulationState.voiceLFORampFactor = 0.0
        voice.modulationState.currentFrequency = voice.modulationState.baseFrequency
        // ... other state resets ...
        
        // CRITICAL: Reset actual audio parameters to base values
        voice.oscLeft.$modulatingMultiplier.ramp(to: AUValue(voice.modulationState.baseModulatorMultiplier), duration: 0)
        voice.oscRight.$modulatingMultiplier.ramp(to: AUValue(voice.modulationState.baseModulatorMultiplier), duration: 0)
        
        voice.oscLeft.$modulationIndex.ramp(to: AUValue(voice.modulationState.baseModulationIndex), duration: 0)
        voice.oscRight.$modulationIndex.ramp(to: AUValue(voice.modulationState.baseModulationIndex), duration: 0)
        
        voice.filter.$cutoffFrequency.ramp(to: AUValue(voice.modulationState.baseFilterCutoff), duration: 0)
    }
    
    // CRITICAL: Reset GLOBAL modulation state (LFO phase, etc.)
    globalModulationState = GlobalModulationState()
    globalModulationState.currentTempo = currentTempo
    
    // ... clear key mappings ...
}
```

**Why this is critical:**
- Resets ALL state, not just modulation tracking variables
- Oscillators get base values, not transient modulated values
- Global LFO phase is reset to 0, preventing carry-over
- Ensures completely clean slate for new preset

### Part 2: Use Base Values in recreateOscillators()

**File: A2 PolyphonicVoice.swift**

Read from base values (source of truth) instead of current oscillator values:

```swift
func recreateOscillators(waveform: OscillatorWaveform) {
    // OLD (incorrect):
    let currentModulatingMult = oscLeft.modulatingMultiplier  // ❌ Transient value
    let currentModIndex = oscLeft.modulationIndex              // ❌ Transient value
    
    // NEW (correct):
    let currentAmplitude = modulationState.baseAmplitude                      // ✅
    let currentModulatingMult = modulationState.baseModulatorMultiplier       // ✅
    let currentModIndex = modulationState.baseModulationIndex                 // ✅
    
    // ... create new oscillators with these base values ...
}
```

**Why this is critical:**
- Base values = user's intended settings (always correct)
- Current values = transient (affected by modulation)
- Ensures all voices recreate with identical, correct parameters
- No more voice-to-voice inconsistencies

### Part 3: Keep Modulation Loop Running (No Stop/Start)

**Key Insight:** We don't need to pause the modulation loop! Instead, we just reset ALL state (including global modulation state) so the loop sees clean values.

**File: A7 ParameterManager.swift**

```swift
func applyVoiceParametersWithFade(_ voiceParams: VoiceParameters, completion: (() -> Void)? = nil) {
    fadeOutputVolume(to: 0.0, duration: 0.1) {
        // CRITICAL: Reset all state (voice + global modulation)
        // Modulation loop continues running, but with clean state
        voicePool?.silenceAndResetAllVoices()
        
        // Clear FX buffers
        self.clearFXBuffers()
        
        // Apply new parameters
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.applyVoiceParameters(voiceParams)
            // ... fade back in ...
        }
    }
}
```

**Why this works:**
- Modulation loop stays running (no start/stop overhead)
- All state is reset, so modulation sees clean values
- No race conditions (state is reset before parameters are applied)
- Clean, simple solution

## Why Previous Attempts Failed

### Attempt 1: Only Reset Modulation State
- **Problem:** Audio parameters (modulatingMultiplier, modulationIndex) weren't reset
- **Result:** Oscillators kept old modulated values

### Attempt 2: Reset Parameters + Filter Modulation Loop
- **Problem:** Filtering `where !voice.isAvailable` broke normal operation
- **Result:** Modulation didn't work properly during playing

### Attempt 3: Pause/Resume Modulation Loop
- **Problem:** Pausing didn't reset global modulation state (LFO phase)
- **Result:** Global LFO carried over from previous preset

### Final Solution: Reset Everything
- **Success:** Reset ALL state (voice + global) but keep loop running
- **Result:** Clean slate for preset switching, continuous modulation during playing

## Testing Results

✅ Load default preset → consistent sound
✅ Switch to preset with heavy modulation → works correctly  
✅ Switch to preset with no modulation → no artifacts
✅ Play multiple notes → identical timbre across all notes
✅ Adjust any parameter → voices remain consistent
✅ Rapid preset switching → no inconsistencies
✅ Load same preset multiple times → identical every time
✅ Modulation stays continuous during normal playing

## Key Lessons

### 1. Base Values Are The Single Source of Truth

There are two types of values:
- **Base values** (modulationState.base*) = User's intended settings
- **Current values** (oscillator properties) = What's actually playing (including modulation)

**Always use base values when initializing/recreating components.**

### 2. Global State Matters

Voice-level state is not enough - global modulation state (like global LFO phase) must also be reset during preset switching. Otherwise, global modulation carries over between presets.

### 3. Continuous Modulation ≠ Persistent State

Modulation can be **continuous** (always running) while state is **ephemeral** (reset on preset load). The modulation loop doesn't need to stop - the state just needs to be clean.

### 4. Don't Stop What You Don't Need To

Stopping/starting timers adds complexity and potential bugs. If you can solve the problem by resetting state instead, that's simpler and more robust.

## Implementation Summary

**Changed Files:**
1. **A3 VoicePool.swift**
   - `silenceAndResetAllVoices()`: Reset audio parameters + global modulation state
   
2. **A2 PolyphonicVoice.swift**
   - `recreateOscillators()`: Use base values instead of current values
   
3. **A7 ParameterManager.swift**
   - `applyVoiceParametersWithFade()`: Simplified (no stop/start modulation)

**Total LOC Changed:** ~15 lines
**Complexity:** Minimal - just resetting state properly

This is the cleanest, most robust solution that preserves continuous modulation during playing while ensuring perfect consistency during preset switching.
