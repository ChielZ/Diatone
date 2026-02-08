# Legato Touch Improvements Summary

This document summarizes two related fixes that improve touch handling in monophonic legato mode.

## Issue 1: Initial Touch Position on Note Return (FIXED)
**Problem**: When returning to a previously held note in legato mode, the initial touch position was reset to default (0.5) instead of using the current touch position of that key.

**Solution**: Track the current touch position in the mono note stack and use it when retriggering.

**Files Modified**:
- `A3 VoicePool.swift`: Added `currentTouchX` field to `MonoNoteStackEntry`, updated to store and retrieve touch positions
- `V2 MainKeyboardView.swift`: Call `updateMonoNoteStackTouchPosition()` on touch moves

**Documentation**: See `LEGATO_INITIAL_TOUCH_FIX.md`

---

## Issue 2: Aftertouch from Multiple Keys (FIXED)
**Problem**: When holding multiple keys in legato mode, touch movements from ALL keys were affecting the sound, causing jumpiness and unpredictable behavior.

**Solution**: Implement voice ownership checking so only the currently playing key's touches affect the sound.

**Files Modified**:
- `A3 VoicePool.swift`: Enhanced `monoVoiceOwner` documentation, added `isMonoVoiceOwner()` method
- `V2 MainKeyboardView.swift`: Filter touch updates through `isMonoVoiceOwner()` check

**Documentation**: See `LEGATO_AFTERTOUCH_FIX.md`

---

## Combined Behavior

With both fixes in place, here's how legato mode now works:

### Playing a Trill (C → D → C)

```
1. Press C at left edge (0.2)
   ├─ C becomes owner
   ├─ initialTouchX = 0.2
   └─ currentTouchX = 0.2

2. Slide finger right on C to middle (0.5)
   ├─ C is owner ✅ → update applies
   ├─ currentTouchX = 0.5
   ├─ Aftertouch delta = +0.3
   └─ Stack: C @ 0.5

3. Press D at right edge (0.8) while holding C
   ├─ D becomes owner
   ├─ initialTouchX = 0.8 (RESET!)
   ├─ currentTouchX = 0.8
   ├─ Aftertouch delta = 0.0 (RESET!)
   └─ Stack: C @ 0.5, D @ 0.8

4. Move finger on C to left edge (0.1)
   ├─ C is NOT owner ❌ → update ignored for sound
   ├─ currentTouchX stays 0.8 (from D)
   └─ Stack: C @ 0.1, D @ 0.8 (position tracked!)

5. Release D while holding C
   ├─ Return to C (from stack)
   ├─ C becomes owner again
   ├─ initialTouchX = 0.1 (from stack! ✨)
   ├─ currentTouchX = 0.1
   ├─ Aftertouch delta = 0.0 (fresh start)
   └─ Stack: C @ 0.1

6. Move finger on C to middle (0.5)
   ├─ C is owner ✅ → update applies
   ├─ currentTouchX = 0.5
   ├─ Aftertouch delta = +0.4
   └─ Smooth continuation from returned position!
```

### Key Features

1. **Initial Touch Continuity**: Returning to a held note uses its current touch position, not default
2. **Aftertouch Isolation**: Only the playing key's touches affect the sound
3. **Automatic Reset**: Each new note starts with aftertouch delta = 0 (relative to its own initial position)
4. **Position Memory**: All held keys remember their touch positions for smooth returns
5. **Mode Agnostic**: Works seamlessly in both monophonic and polyphonic modes

---

## Testing Checklist

### Test 1: Initial Touch Return ✅
- [ ] Play note at left edge
- [ ] Slide to right edge  
- [ ] Play second note
- [ ] Release second note
- [ ] Verify sound returns to right edge position (not center)

### Test 2: Aftertouch Isolation ✅
- [ ] Set aftertouch to modulate filter (3-5 octaves)
- [ ] Play note 1, slide finger right → filter opens
- [ ] Play note 2 (while holding note 1)
- [ ] Slide finger on note 1 → filter should NOT move
- [ ] Slide finger on note 2 → filter should move

### Test 3: Combined Behavior ✅
- [ ] Play note at left edge, slide to middle
- [ ] Play second note at right edge
- [ ] Slide first note to left edge (while playing second)
- [ ] Release second note → returns to first at left edge
- [ ] Slide first note right → smooth continuation

### Test 4: Polyphonic Sanity Check ✅
- [ ] Switch to polyphonic mode
- [ ] Play two notes, slide both → both should respond
- [ ] Verify no interference between notes

---

## Implementation Notes

- Both fixes work together seamlessly
- The mono note stack serves dual purpose:
  1. Stores note frequency/pitch for retriggering
  2. Stores touch position for smooth returns
- Voice ownership (`monoVoiceOwner`) serves dual purpose:
  1. Controls who can release the voice
  2. Filters whose touch moves apply to sound
- In polyphonic mode, both features gracefully degrade to "always allow"

---

## Related Files

- `A3 VoicePool.swift` - Voice allocation and monophonic mode logic
- `V2 MainKeyboardView.swift` - Touch handling and keyboard input
- `A2 PolyphonicVoice.swift` - Voice modulation state tracking
- `A6 ModulationSystem.swift` - Modulation state structure

---

## Future Improvements

Potential enhancements for future consideration:

1. **Polyphonic Aftertouch**: Track touch positions per-voice in poly mode for MPE-like behavior
2. **Touch Smoothing**: Add optional smoothing for aftertouch transitions on note changes
3. **Visual Feedback**: Show which key is the current owner in the UI
4. **Touch Interpolation**: Smooth transition between keys' touch positions during legato changes
