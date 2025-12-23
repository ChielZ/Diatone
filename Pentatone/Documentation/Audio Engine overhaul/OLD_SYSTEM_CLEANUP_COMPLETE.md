# Old Voice System Cleanup - Complete ✅

**Date:** December 23, 2025  
**Status:** Successfully completed

## Summary

The old 1:1 key-to-voice architecture (18 fixed voices) has been completely removed from the codebase. The new polyphonic voice pool system is now the only active voice system.

---

## Changes Made

### 1. **MainKeyboardView.swift** - Simplified keyboard interface

**Removed:**
- `useNewVoiceSystem` feature flag parameter
- `oldSystemTrigger` and `oldSystemRelease` callback parameters (18×2 = 36 callbacks)
- All branching logic between old/new systems in gesture handlers
- `handleOldSystemTrigger()` and `handleOldSystemRelease()` methods

**Simplified:**
- `KeyButton` now only requires: `colorName`, `keyIndex`, `isLeftSide`, `keyboardState`
- Gesture handlers now have single code path (no branching)
- Methods renamed: `handleNewSystemTrigger` → `handleTrigger`, etc.

**Result:** ~150 lines of code removed, no more dual-system complexity

---

### 2. **AudioKitCode.swift** - Removed old voice architecture

**Removed:**
- `OscVoice` class entirely (~100 lines)
- 18 global oscillator variables (`oscillator01` through `oscillator18`)
- `createAllVoices()` helper function
- `EngineManager.initializeVoices()` method
- `EngineManager.applyScale()` method
- `voiceMixer` (old mixer for 18 voices)
- `combinedMixer` (mixed old + new systems)
- `AudioEngineTestView` (old test view - ~250 lines)
- `TestKeyButton` struct

**Renamed:**
- `NewVoicePoolTestView` → `VoicePoolTestView`
- Updated preview macro accordingly

**Updated:**
- `EngineManager.startIfNeeded()` now only creates voice pool
- Effects chain now processes only `voicePool.voiceMixer`
- Removed "Phase 1/2/3" comments, cleaned up documentation

**Result:** ~450 lines of code removed

---

### 3. **PentatoneApp.swift** - Removed feature flag and old system calls

**Removed:**
- `useNewVoiceSystem` feature flag state variable
- `useNewVoiceSystem` parameter in `MainKeyboardView` initialization
- `EngineManager.initializeVoices(count: 18)` call in startup
- `EngineManager.applyScale(frequencies:)` call in scale changes
- Frequency calculation for old system in `applyCurrentScale()`

**Simplified:**
- `initializeAudio()` now only starts engine (no voice initialization)
- `applyCurrentScale()` now only updates `KeyboardState` (no dual updates)

**Result:** Cleaner app initialization, single point of truth for frequencies

---

### 4. **SoundParameters.swift** - Removed old voice management

**Removed:**
- `voiceOverrides: [Int: VoiceParameters]` dictionary (18-voice overrides)
- `lastFilterCutoffs: [Int: Double]` dictionary (smoothing state for 18 voices)
- All per-voice update methods:
  - `updateVoice(at:parameters:)`
  - `updateVoiceFilter(at:parameters:)`
  - `updateVoiceFilterCutoff(at:normalizedValue:)`
  - `updateVoicePan(at:pan:)`
  - `updateVoiceAmplitude(at:amplitude:)`
  - `clearVoiceOverrides()`
  - `clearVoiceOverride(at:)`
- `applyTemplateToAllVoices()` method
- `applyParametersToVoice(at:parameters:)` method
- `getVoice(at:)` helper (big switch statement for 18 voices)
- All touch mapping helper methods (moved to deprecated extension)

**Deprecated (marked with `@available(*, deprecated)`):**
- `mapTouchToFilterCutoff()` - now handled per-voice in `MainKeyboardView`
- `mapAftertouchToFilterCutoff()` - now handled per-voice
- `mapAftertouchToFilterCutoffSmoothed()` - now handled per-voice
- `resetVoiceFilterToTemplate()` - no longer needed
- `mapTouchToPan()` - pan is now fixed (stereo design)
- `mapTouchToAmplitude()` - now handled per-voice
- `mapTouchToResonance()` - experimental feature removed

**Result:** ~300 lines of code removed, AudioParameterManager now focused only on master effects and voice template

---

## Statistics

### Code Removed
- **Total lines removed:** ~900-1000 lines
- **Files modified:** 4 files
- **Classes removed:** 1 (`OscVoice`)
- **Global variables removed:** 19 (18 oscillators + `voiceMixer`)
- **Methods removed:** 20+

### Code Simplified
- **MainKeyboardView:** 18 `KeyButton` declarations now have 4 parameters instead of 8
- **Gesture handlers:** Single code path instead of branching on feature flag
- **AudioParameterManager:** No longer manages per-voice state for 18 voices
- **App initialization:** 2 fewer async steps (no voice init, no scale apply)

---

## Architecture After Cleanup

### Current Voice System (Only System)
```
voicePool (5 voices)
  ├─ PolyphonicVoice 1 (oscLeft + oscRight, stereo design)
  ├─ PolyphonicVoice 2
  ├─ PolyphonicVoice 3
  ├─ PolyphonicVoice 4
  └─ PolyphonicVoice 5

Dynamic allocation:
- Keys request voices from pool when pressed
- Voices released back to pool when keys released
- Voice stealing when >5 keys pressed simultaneously
- Each voice: dual oscillators → filter → envelope → stereo output
```

### Signal Flow
```
voicePool.voiceMixer → fxDelay → fxReverb → reverbDryWet → sharedEngine.output
```

### Parameter Management
```
AudioParameterManager
  ├─ master (delay + reverb parameters)
  └─ voiceTemplate (default parameters for all voices)

Per-voice parameters (amplitude, filter cutoff):
  - Managed locally in MainKeyboardView's KeyButton
  - Applied directly to allocated PolyphonicVoice
  - No global state tracking needed
```

---

## Benefits of Cleanup

### 1. **Code Clarity**
- ✅ Single voice allocation system (no confusion)
- ✅ No feature flags or branching logic
- ✅ Clear ownership of state (per-voice in KeyButton)

### 2. **Easier Debugging**
- ✅ One code path to follow
- ✅ No wondering "which system is active?"
- ✅ Fewer places for bugs to hide

### 3. **Simpler Testing**
- ✅ One test view instead of two
- ✅ No need to test feature flag combinations
- ✅ Clearer test scenarios

### 4. **Better Foundation for Phase 5**
- ✅ Clean slate for adding modulation system
- ✅ No risk of accidentally triggering old voice code
- ✅ Clearer mental model for next features

### 5. **Performance**
- ✅ Less memory usage (no 18 unused voices)
- ✅ Faster compilation (less code to compile)
- ✅ Cleaner diffs in version control

---

## Testing Checklist

After cleanup, verify:

- [√] App builds successfully
- [√] App launches without crashes
- [√] All 18 keys trigger notes correctly
- [√] Polyphonic playing works (press multiple keys)
- [√] Voice stealing works (press >5 keys)
- [√] Amplitude control via initial touch X position
- [√] Filter cutoff control via aftertouch (slide finger)
- [√] Scale changes work correctly
- [√] Key transposition works
- [√] Rotation works
- [√] Effects (delay/reverb) work
- [ ] VoicePoolTestView preview works

---

## Next Steps

Now ready to proceed with:

### **Phase 5: Modulation System**
- Add modulation envelope (controls FM `modulationIndex`)
- Add per-voice LFO (targets filter cutoff, detune, etc.)
- Add global LFO (targets delay time, reverb mix)
- Keep `AmplitudeEnvelope` for output volume control

### **Phase 6: Preset System**
- Create PresetManager
- Design 15 factory presets
- Build preset browser UI

### **Phase 7: Macro Controls**
- Implement 4 macro controls per preset
- Map macros to multiple parameters
- Add macro UI to main view

### **Phase 8: Polish**
- Performance optimization
- UI/UX refinements
- Documentation
- Final testing

---

## Notes

- All old system code still exists in git history if needed for reference
- The old architecture is documented in `AUDIO_ENGINE_OVERHAUL_PLAN.md`
- Cleanup was done in logical order: UI → Engine → App → Parameters
- No functionality was lost; all features work with new system

---

**Status:** ✅ Ready for Phase 5 (Modulation System)
