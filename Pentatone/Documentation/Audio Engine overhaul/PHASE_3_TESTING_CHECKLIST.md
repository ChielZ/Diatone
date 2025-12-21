# Phase 3 Testing Checklist

## Pre-Flight Checks (Before Running)

- [ ] Project compiles without errors
- [ ] No new warnings introduced
- [ ] All files saved

## Basic Functionality Tests

### Single Note Tests:
- [ ] Press key 0 (bottom left) → note plays
- [ ] Press key 17 (top right) → note plays
- [ ] Press middle keys → notes play
- [ ] Release key → note stops cleanly
- [ ] No audio glitches or pops

### Touch Position Mapping:
- [ ] Touch near outer edge → loud/bright
- [ ] Touch near center edge → quiet/dark
- [ ] Touch in middle → moderate volume
- [ ] Consistent across all keys

### Aftertouch (Horizontal Slide):
- [ ] Press key and slide toward center → brighter (higher cutoff)
- [ ] Press key and slide toward edge → darker (lower cutoff)
- [ ] Smooth parameter changes (no zipper noise)
- [ ] Works on all keys

## Polyphony Tests

### Basic Polyphony:
- [ ] Press 2 keys simultaneously → both play
- [ ] Press 3 keys simultaneously → all play
- [ ] Press 5 keys simultaneously → all play (max polyphony)
- [ ] All voices sound correctly

### Voice Stealing:
- [ ] Press 6 keys → oldest voice gets stolen (check console for "⚠️ Voice stealing")
- [ ] Press 7+ keys → continues stealing gracefully
- [ ] No audio dropouts or crashes
- [ ] Stealing happens instantly (no fade)

### Release Behavior:
- [ ] Press 5 keys, release 1 → 4 continue playing
- [ ] Press 6 keys, release oldest → freed voice available for new note
- [ ] No stuck notes
- [ ] Clean release envelopes

## Scale/Key Tests

### Scale Changes:
- [ ] Change to different scale → frequencies update
- [ ] Play keys → notes reflect new scale
- [ ] KeyboardState frequencies match old system
- [ ] No console errors

### Key Transposition:
- [ ] Change musical key (e.g., D → C) → pitches shift
- [ ] All keys transpose correctly
- [ ] Consistent transposition across all keys

### Rotation:
- [ ] Change rotation → key color mapping shifts
- [ ] Play keys → note assignments change
- [ ] Frequencies update correctly

## System Comparison Tests

### Feature Flag Test:
1. **With `useNewVoiceSystem = true` (NEW SYSTEM):**
   - [ ] All keys work
   - [ ] Polyphony works
   - [ ] Console shows VoicePool logs

2. **Change to `useNewVoiceSystem = false` (OLD SYSTEM):**
   - [ ] All keys still work
   - [ ] No polyphony (each key has its own voice)
   - [ ] Original behavior preserved

3. **Change back to `useNewVoiceSystem = true`:**
   - [ ] New system works again
   - [ ] No issues from switching

## Performance Tests

### CPU Usage:
- [ ] Open Xcode Instruments → CPU profiler
- [ ] Play 5 simultaneous notes
- [ ] CPU usage < 30% (on iPhone 12 or later)
- [ ] No thermal throttling

### Memory:
- [ ] Check memory usage in Xcode Debug Navigator
- [ ] ~2.5 MB for audio (old + new systems)
- [ ] No memory leaks
- [ ] Stable over time

### Latency:
- [ ] Touch to sound feels instant
- [ ] No noticeable delay
- [ ] Aftertouch responds immediately
- [ ] Comparable to old system

## Edge Cases

### Rapid Interactions:
- [ ] Rapidly press/release keys → no crashes
- [ ] Glissando across all keys → smooth
- [ ] Tap keys very quickly → all triggers register

### Extreme Polyphony:
- [ ] Press all 18 keys at once → voice stealing handles it
- [ ] Release all keys → all voices available again
- [ ] No audio artifacts

### Scale Changes During Play:
- [ ] Press and hold 3 keys
- [ ] Change scale while holding
- [ ] Notes continue playing (old frequencies)
- [ ] Release and re-press → new frequencies
- [ ] Expected behavior

## Console Output Verification

### Look for these logs:
```
🎵 VoicePool initialized with 5 voices
🎹 Key X: Allocated voice, freq XXX.XX Hz, amp X.XX
🎹 Key X: Released voice
⚠️ Voice stealing: Took voice triggered at [timestamp]
```

### Should NOT see:
- [ ] No error messages
- [ ] No "Could not get frequency" warnings
- [ ] No assertion failures
- [ ] No AudioKit errors

## Known Issues (Expected)

These are acceptable at this stage:

1. **No parameter presets yet** → Phase 6
2. **No modulation/LFOs** → Phase 5
3. **Basic amplitude/filter mapping** → Can refine later
4. **Both old and new systems running** → Will clean up in Phase 8

## Regression Tests (Old Features Still Work)

- [ ] Options menu opens/closes
- [ ] Navigation strip works
- [ ] Scale browsing works
- [ ] Color coding works
- [ ] Device rotation works (iPad)
- [ ] Portrait mode locked (iPhone)

## Critical Success Criteria

### Must Pass:
- [ ] ✅ Project compiles without errors
- [ ] ✅ All 18 keys work
- [ ] ✅ Polyphony works (5 voices)
- [ ] ✅ Voice stealing works
- [ ] ✅ No crashes or audio dropouts
- [ ] ✅ Scale/key changes work
- [ ] ✅ Old system still works (feature flag)

### Should Pass:
- [ ] ⚠️ No performance regression
- [ ] ⚠️ Touch mapping feels natural
- [ ] ⚠️ Aftertouch is responsive

### Nice to Have:
- [ ] 💡 Voice stealing is imperceptible
- [ ] 💡 Clean console logs
- [ ] 💡 Smooth transitions

## Testing Environment

**Device:** _______________ (iPhone/iPad model)
**iOS Version:** _______________
**Build Configuration:** Debug / Release
**Date:** _______________
**Tester:** _______________

## Sign-Off

- [ ] All critical tests passed
- [ ] All edge cases handled
- [ ] Performance acceptable
- [ ] Ready for Phase 5 (Modulation)

**Notes:**
_______________________________________
_______________________________________
_______________________________________

---

## Quick Debug Tips

### If keys don't play:
1. Check console for "Could not get frequency" warnings
2. Verify KeyboardState has correct frequencies
3. Check VoicePool initialization logs

### If polyphony doesn't work:
1. Verify `useNewVoiceSystem = true` in PentatoneApp
2. Check console for voice allocation logs
3. Verify VoicePool.voiceCount = 5

### If voice stealing causes issues:
1. Check console for "Voice stealing" warnings
2. Increase polyphony (VoicePool.voiceCount = 8)
3. Verify envelope release times

### If switching systems fails:
1. Verify both old/new systems initialized
2. Check feature flag value
3. Restart app after changing flag

---

**Generated:** December 21, 2025
**Phase:** 3 (Voice Pool Integration)
**Status:** Ready for Testing
