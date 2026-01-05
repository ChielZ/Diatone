# Filter Frequency Key Tracking Bug Fix

**Date:** January 5, 2026  
**Issue:** Inconsistent filter frequencies across voices when adjusting filter cutoff with key tracking active

---

## Problem Description

When the user adjusted the filter cutoff slider while key tracking was enabled, the filter frequency would be different across the 5 polyphonic voices, even when playing the same note repeatedly. This created an audible "chorus" effect of 5 slightly different filter cutoffs.

### Root Cause

The issue occurred due to **stale frequency state** in silent voices:

1. When filter cutoff was adjusted via UI, `applyFilterToAllVoices()` updated **all 5 voices**, including silent ones
2. Each silent voice retained `modulationState.currentFrequency` from whatever note it had **previously** played
3. The 200 Hz modulation timer would then calculate key tracking offsets based on these **stale frequencies**:
   ```swift
   finalCutoff = baseCutoff * pow(2.0, keyTrackOctaves + ...)
   ```
4. Result: Even though all voices got the same `baseFilterCutoff`, they immediately diverged due to different key tracking offsets

### Example Scenario

- Voice 0: Last played C4 (262 Hz) → filter offset for C4 applied
- Voice 1: Last played E4 (330 Hz) → filter offset for E4 applied  
- Voice 2: Last played G4 (392 Hz) → filter offset for G4 applied
- Voice 3: Last played A4 (440 Hz) → filter offset for A4 applied
- Voice 4: Last played D5 (587 Hz) → filter offset for D5 applied

When the user adjusted the filter slider, all voices were updated, but each retained its own key tracking offset from the previous note, causing 5 different final frequencies.

---

## Solution

### Core Fix: Two-Part Approach

**Part 1: Only update active voices from UI**
- Modified `VoicePool.updateAllVoiceFilters()` to only update voices where `!voice.isAvailable` (currently playing)
- Silent voices no longer get their `modulationState.baseFilterCutoff` updated directly

**Part 2: Capture fresh template value at trigger time**
- Added `templateFilterCutoff` parameter to `PolyphonicVoice.trigger()`
- `VoicePool` now stores `currentTemplate: VoiceParameters` 
- At note-on, `allocateVoice()` passes the current template's filter cutoff to `trigger()`
- This ensures every triggered voice gets the **latest** filter cutoff from the UI

### Implementation Details

#### Modified Files

**1. `A2 PolyphonicVoice.swift`**
```swift
func trigger(initialTouchX: Double = 0.5, templateFilterCutoff: Double? = nil) {
    // Update base filter cutoff from template if provided
    if let cutoff = templateFilterCutoff {
        modulationState.baseFilterCutoff = cutoff
    }
    // ... rest of trigger logic
}
```

**2. `A3 VoicePool.swift`**
```swift
// Added property to track current template
private var currentTemplate: VoiceParameters = .default

// Modified allocateVoice to pass template value
func allocateVoice(...) -> PolyphonicVoice {
    voice.setFrequency(finalFrequency)
    voice.trigger(
        initialTouchX: initialTouchX, 
        templateFilterCutoff: currentTemplate.filter.clampedCutoff  // ← Fresh value!
    )
    // ...
}

// Modified updateAllVoiceFilters to only update active voices
func updateAllVoiceFilters(_ parameters: FilterParameters) {
    currentTemplate.filter = parameters  // Update template
    for voice in voices where !voice.isAvailable {  // Only active voices
        voice.updateFilterParameters(parameters)
    }
}
```

**3. `A7 ParameterManager.swift`**
```swift
// Simplified - now delegates to VoicePool
func updateFilterCutoff(_ value: Double) {
    voiceTemplate.filter.cutoffFrequency = value
    voicePool?.updateAllVoiceFilters(voiceTemplate.filter)
}

// Removed applyFilterToAllVoices() - no longer needed
```

**4. `V4-S02 ParameterPage2View.swift`**
```swift
// Removed manual applyFilterToAllVoices() calls
// ParameterManager methods now handle everything
set: { newValue in
    paramManager.updateFilterCutoff(newValue)
    // No longer needed: applyFilterToAllVoices()
}
```

---

## How It Works Now

### When User Adjusts Filter Cutoff Slider:

1. ✅ UI calls `paramManager.updateFilterCutoff(newValue)`
2. ✅ ParameterManager updates `voiceTemplate.filter.cutoffFrequency`
3. ✅ ParameterManager calls `voicePool.updateAllVoiceFilters()`
4. ✅ VoicePool updates `currentTemplate.filter` (for future notes)
5. ✅ VoicePool updates **only active voices'** `baseFilterCutoff`
6. ✅ Silent voices are **not touched** (they retain stale state, but it doesn't matter)

### When User Plays a New Note:

1. ✅ `voicePool.allocateVoice()` is called
2. ✅ Voice's frequency is set via `setFrequency()` (updates `currentFrequency`)
3. ✅ Voice's trigger is called with **fresh** `templateFilterCutoff`
4. ✅ `modulationState.baseFilterCutoff` is updated to the **latest** UI value
5. ✅ `modulationState.reset()` is called with the **new** frequency
6. ✅ First modulation update (5ms later) uses correct base cutoff + correct frequency
7. ✅ Key tracking calculates offset based on **current note**, not stale previous note

### Result

✅ All voices playing the **same note** have the **same filter frequency**  
✅ Different notes still get appropriate key tracking offsets  
✅ No more "5 different filter chorus" effect  
✅ Filter adjustments apply consistently across all playing voices  

---

## Additional Improvements

### Consistency Across Parameter Updates

For consistency, also updated other VoicePool parameter methods to maintain the template:

```swift
func updateAllVoiceOscillators(_ parameters: OscillatorParameters) {
    currentTemplate.oscillator = parameters  // Keep template in sync
    for voice in voices {
        voice.updateOscillatorParameters(parameters)
    }
}

func updateAllVoiceEnvelopes(_ parameters: EnvelopeParameters) {
    currentTemplate.envelope = parameters
    for voice in voices {
        voice.updateEnvelopeParameters(parameters)
    }
}

func updateAllVoiceModulation(_ parameters: VoiceModulationParameters) {
    currentTemplate.modulation = parameters
    for voice in voices {
        voice.updateModulationParameters(parameters)
    }
}
```

This ensures that **any** parameter change in the UI is captured in the template and applied fresh to newly triggered voices.

---

## Testing Recommendations

### Test Case 1: Basic Consistency
1. Enable key tracking (set amount > 0)
2. Play a single note repeatedly (e.g., middle C)
3. While playing, adjust filter cutoff slider
4. **Expected:** All instances of that note should have identical filter frequency (no chorus)

### Test Case 2: Key Tracking Still Works
1. Enable key tracking
2. Play low note (e.g., C3)
3. Play high note (e.g., C5)
4. **Expected:** High note should have proportionally higher filter cutoff

### Test Case 3: Real-Time Update
1. Hold down a note
2. Adjust filter cutoff slider
3. **Expected:** Filter frequency should update smoothly on the held note

### Test Case 4: Polyphonic Consistency
1. Enable key tracking
2. Play a 5-note chord (all different notes)
3. Adjust filter cutoff slider
4. **Expected:** Each note maintains its relative key tracking offset (no randomness)

---

## Technical Notes

### Why Not Update All Voices?

The original code updated all 5 voices whenever the filter changed, but this caused problems:

- ❌ Silent voices got updated `baseFilterCutoff` but kept stale `currentFrequency`
- ❌ When modulation ran (200 Hz), it used stale frequency for key tracking
- ❌ Created inconsistent offsets even for the same note

### Why The Template Approach?

Passing the template value at trigger time ensures:

- ✅ **Timing independence:** UI updates don't race with modulation timer
- ✅ **State freshness:** Voice always gets latest values, not stale cached values
- ✅ **Simplicity:** No need to track which voices need updates
- ✅ **Correctness:** Key tracking always uses current note's frequency

### Modulation System Untouched

This fix **does not change** any modulation math or timing:

- ✅ ModulationRouter formulas unchanged
- ✅ 200 Hz control rate unchanged
- ✅ Key tracking calculation unchanged
- ✅ All other modulation sources unchanged

Only the **initialization** of `baseFilterCutoff` at note-on was fixed.

---

## Status

✅ **Fix Complete**  
✅ **No Breaking Changes**  
✅ **Modulation System Preserved**  
✅ **Ready for Testing**
