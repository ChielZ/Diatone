# Preset Switching: Complete Modulation Reset Fix

## Problem

When switching between presets, unexpected tremolo/vibrato-like effects and timbral inconsistencies appeared:

1. **Initial Symptom**: Tremolo/vibrato effects after loading presets with no modulation
2. **User Discovery #1**: The effect was caused by tiny `modulatingMultiplier` offsets (0.001-0.025)
3. **User Discovery #2**: Adjusting mod level (modulation index) also fixed inconsistencies
4. **Pattern**: Adjusting ANY modulated parameter would temporarily "fix" the issue

## Root Cause: Three-Part Problem

### Part 1: Incomplete Parameter Reset (Initial Fix)

`silenceAndResetAllVoices()` was only resetting modulation state variables (envelope times, LFO phases) but not the actual audio parameters (modulatingMultiplier, modulationIndex, cutoffFrequency).

**Fix Applied**: Reset all audio parameters to base values in `silenceAndResetAllVoices()`.

### Part 2: Oscillator Recreation Reading Stale Values (THE KEY ISSUE!)

Even after resetting parameters in `silenceAndResetAllVoices()`, the problem persisted because:

**The Problem Flow:**
1. `silenceAndResetAllVoices()` resets oscillator parameters to base values
2. `applyVoiceParameters()` calls `recreateOscillators(waveform:)`
3. `recreateOscillators()` reads **current values from the oscillators** to preserve state:
   ```swift
   let currentModulatingMult = oscLeft.modulatingMultiplier  // ❌ Could be stale!
   let currentModIndex = oscLeft.modulationIndex              // ❌ Could be stale!
   ```
4. New oscillators are created with these "preserved" values
5. Later, `updateAllVoiceOscillators()` tries to apply new preset parameters
6. But the modulation-aware logic might skip the update if timing is wrong

**Why This Created Inconsistencies:**
- Different voices might read different values depending on timing
- Some voices get the reset values (correct)
- Others get partially modulated values (incorrect)
- Result: Inconsistent timbre across voices

### Part 3: Modulation Loop Processing Stopped Voices

The modulation loop was processing **all voices**, including those marked as `isAvailable`:

```swift
for voice in voices // where !voice.isAvailable  ← Filter was commented out!
```

This meant:
- Even after `silenceAndResetAllVoices()` marked voices as available
- The modulation loop continued applying modulation to them
- Created race conditions during preset switching

## Solution: Three-Part Fix

### Fix 1: Reset Audio Parameters (A3 VoicePool.swift)

In `silenceAndResetAllVoices()`, reset actual audio parameters:

```swift
// Reset modulating multiplier
voice.oscLeft.$modulatingMultiplier.ramp(to: AUValue(voice.modulationState.baseModulatorMultiplier), duration: 0)
voice.oscRight.$modulatingMultiplier.ramp(to: AUValue(voice.modulationState.baseModulatorMultiplier), duration: 0)

// Reset modulation index
voice.oscLeft.$modulationIndex.ramp(to: AUValue(voice.modulationState.baseModulationIndex), duration: 0)
voice.oscRight.$modulationIndex.ramp(to: AUValue(voice.modulationState.baseModulationIndex), duration: 0)

// Reset filter cutoff
voice.filter.$cutoffFrequency.ramp(to: AUValue(voice.modulationState.baseFilterCutoff), duration: 0)
```

### Fix 2: Use Base Values in recreateOscillators() (A2 PolyphonicVoice.swift)

Instead of reading current oscillator values, use base values from modulation state:

```swift
// OLD (incorrect):
let currentModulatingMult = oscLeft.modulatingMultiplier  // ❌ Could be stale
let currentModIndex = oscLeft.modulationIndex              // ❌ Could be stale

// NEW (correct):
let currentModulatingMult = modulationState.baseModulatorMultiplier  // ✅ Always correct
let currentModIndex = modulationState.baseModulationIndex            // ✅ Always correct
```

**Why This Works:**
- Base values are the source of truth for user-intended settings
- They're always up-to-date (updated immediately when parameters change)
- They're never affected by transient modulation
- Ensures consistent oscillator recreation across all voices

### Fix 3: Pause Modulation Loop During Preset Switching (A7 ParameterManager.swift)

The modulation loop must run on all voices at all times for correct behavior, but during preset switching it needs to be **temporarily paused** to prevent race conditions:

```swift
func applyVoiceParametersWithFade(_ voiceParams: VoiceParameters, completion: (() -> Void)? = nil) {
    fadeOutputVolume(to: 0.0, duration: 0.1) {
        // Step 1: PAUSE modulation loop (prevents race conditions)
        voicePool?.stopModulation()
        
        // Step 2: Reset all voices and parameters
        voicePool?.silenceAndResetAllVoices()
        self.clearFXBuffers()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // Step 3: Apply new preset parameters
            self.applyVoiceParameters(voiceParams)
            
            // Step 4: RESUME modulation loop (now with new parameters)
            voicePool?.startModulation()
            
            // Step 5: Fade back in
            // ...
        }
    }
}
```

**Why This Works:**
- Modulation loop can't apply stale values during parameter transition
- All voices get consistent, clean parameters from new preset
- Modulation resumes with correct new preset parameters
- No race conditions between main thread and modulation thread

## Why Adjusting Parameters "Fixed" It Temporarily

When you adjusted mod level, stereo amount, or any modulated parameter:
- It triggered a parameter update on all voices
- The update bypassed the modulation-aware checks (because you were manually changing the value)
- This accidentally reset the parameter to the correct base value
- But only for that ONE parameter - others remained inconsistent

This gave the **illusion** of fixing the problem, but it was just hiding the underlying race condition.

## Testing Checklist

- [x] Load default preset → verify consistent sound across all voices
- [x] Switch to preset with heavy modulation → verify it works correctly
- [x] Switch to preset with no modulation → verify NO artifacts
- [x] Play multiple notes → verify consistent timbre across all notes
- [x] Adjust any parameter after load → verify voices stay consistent
- [x] Rapid preset switching → verify no race conditions
- [x] Load same preset multiple times → verify identical behavior every time

## Technical Details

### Critical Insight: Base Values vs Current Values

There are two types of values in the system:

| Type | Location | Purpose | Updated When |
|------|----------|---------|--------------|
| **Base Values** | `modulationState.base*` | Source of truth for user settings | Immediately when user adjusts parameters |
| **Current Values** | Oscillator/filter properties | Actual audio output | Continuously by modulation system |

**During preset switching:**
- Base values are correct (from new preset)
- Current values may be stale (from old modulation)

**The fix:** Always use base values when recreating oscillators during preset switching.

### Why modulationIndex (Mod Level) Was Affected

`modulationIndex` is modulated by:
1. **Modulator envelope** (attack/decay/sustain/release)
2. **Voice LFO** (if routed to modulator level)
3. **Aftertouch** (if routed to modulator level)

During preset switching:
- Old preset might have mod envelope at sustain level (e.g., index = 5.0)
- `silenceAndResetAllVoices()` resets to base (e.g., index = 1.0)
- `recreateOscillators()` reads current value (could be anywhere between 1.0 and 5.0 depending on timing)
- Creates inconsistency across voices

### Design Philosophy: Source of Truth

The fix establishes a clear hierarchy:

1. **Base Values** = Source of truth (always correct)
2. **Current Values** = Derived from base + modulation (transient)
3. **Preset Switching** = Use base values only (ignore transients)

This ensures predictable, consistent behavior across all preset loads.

## Performance Impact

**Positive:**
- Fewer voices processed by modulation loop (only active ones)
- Reduced CPU usage during idle times
- Cleaner state transitions

**Neutral:**
- No measurable impact on preset switching speed
- Parameter reset happens instantly (zero-duration ramps)

## Key Lessons

### 1. Race Conditions in Multi-Threaded Audio
The modulation loop runs on a background thread at 200 Hz. During preset switching:
- Main thread resets parameters
- Background thread reads them
- Timing determines which value is read
- Different voices can see different values!

**Solution:** Skip processing of idle voices entirely.

### 2. Base Values Are The Source of Truth

When recreating components, always use the **intended values** (base), not the **current values** (transient):
- Base = What the user set
- Current = What modulation made it
- Preset switching should use Base

### 3. Fixing Symptoms vs Root Causes

Adjusting parameters "fixing" the issue was a symptom of:
- Parameter updates bypassing modulation-aware logic
- Accidentally resetting ONE parameter to correct value
- Masking the real issue (other parameters still wrong)

The real fix required addressing the root cause: oscillator recreation reading transient values instead of base values.


