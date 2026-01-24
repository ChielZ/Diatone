# Legato Aftertouch: Voice Ownership Flow

## Visual Diagram: Two Keys Held in Monophonic Mode

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     MONOPHONIC LEGATO MODE                               │
│                     (Only one voice active)                              │
└─────────────────────────────────────────────────────────────────────────┘

TIME: t1 - Press Key 1 at position 0.2
┌────────────┐
│   KEY 1    │  👆 Owner ✓
│ Touch: 0.2 │────────┐
└────────────┘        │        ┌──────────────────┐
                      └───────▶│  ACTIVE VOICE    │  🔊 Sound Playing
┌────────────┐                 │  initialTouchX: 0.2
│   KEY 2    │  🚫 Not Owner   │  currentTouchX: 0.2
│  (empty)   │                 │  Aftertouch: 0.0 │
└────────────┘                 └──────────────────┘

Mono Note Stack: [Key1@0.2]
Voice Owner: Key 1


TIME: t2 - Move finger on Key 1 to 0.5
┌────────────┐
│   KEY 1    │  👆 Owner ✓
│ Touch: 0.5 │────────┐
└────────────┘        │        ┌──────────────────┐
                      └───────▶│  ACTIVE VOICE    │  🔊 Sound Playing
┌────────────┐                 │  initialTouchX: 0.2
│   KEY 2    │  🚫 Not Owner   │  currentTouchX: 0.5 ← APPLIED ✓
│  (empty)   │                 │  Aftertouch: +0.3│
└────────────┘                 └──────────────────┘

Mono Note Stack: [Key1@0.5]
Voice Owner: Key 1
Touch Update: Key 1 → Voice (✓ applied because Key 1 is owner)


TIME: t3 - Press Key 2 at position 0.8 (while holding Key 1)
┌────────────┐
│   KEY 1    │  🚫 Not Owner
│ Touch: 0.5 │─ ─ ─ ┐
└────────────┘       │        ┌──────────────────┐
                     X (blocked) ACTIVE VOICE   │  🔊 Sound Playing
┌────────────┐       │        │  initialTouchX: 0.8 ← RESET!
│   KEY 2    │  👆 Owner ✓   │  currentTouchX: 0.8
│ Touch: 0.8 │────────────────│  Aftertouch: 0.0 ← RESET!
└────────────┘                └──────────────────┘

Mono Note Stack: [Key1@0.5, Key2@0.8]
Voice Owner: Key 2 ← Changed!
Note: Key 1's position is preserved in stack for later retriggering


TIME: t4 - Move finger on Key 1 to 0.1 (non-owner move)
┌────────────┐
│   KEY 1    │  🚫 Not Owner
│ Touch: 0.1 │─ ─ ─ ┐
└────────────┘       │        ┌──────────────────┐
                     X (blocked) ACTIVE VOICE   │  🔊 Sound Playing
┌────────────┐       │        │  initialTouchX: 0.8
│   KEY 2    │  👆 Owner ✓   │  currentTouchX: 0.8 ← NO CHANGE
│ Touch: 0.8 │────────────────│  Aftertouch: 0.0 │
└────────────┘                └──────────────────┘

Mono Note Stack: [Key1@0.1, Key2@0.8]  ← Stack updated!
Voice Owner: Key 2
Touch Update: Key 1 → Voice (✗ BLOCKED because Key 1 is not owner)
Note: Key 1's new position is still saved to stack (for retriggering)


TIME: t5 - Move finger on Key 2 to 0.9 (owner move)
┌────────────┐
│   KEY 1    │  🚫 Not Owner
│ Touch: 0.1 │─ ─ ─ ┐
└────────────┘       │        ┌──────────────────┐
                     X (blocked) ACTIVE VOICE   │  🔊 Sound Playing
┌────────────┐       │        │  initialTouchX: 0.8
│   KEY 2    │  👆 Owner ✓   │  currentTouchX: 0.9 ← APPLIED ✓
│ Touch: 0.9 │────────────────│  Aftertouch: +0.1│
└────────────┘                └──────────────────┘

Mono Note Stack: [Key1@0.1, Key2@0.9]
Voice Owner: Key 2
Touch Update: Key 2 → Voice (✓ applied because Key 2 is owner)


TIME: t6 - Release Key 2 (while holding Key 1) → Retrigger Key 1
┌────────────┐
│   KEY 1    │  👆 Owner ✓ (restored!)
│ Touch: 0.1 │────────┐
└────────────┘        │        ┌──────────────────┐
                      └───────▶│  ACTIVE VOICE    │  🔊 Sound Playing
┌────────────┐                 │  initialTouchX: 0.1 ← From stack! ✨
│   KEY 2    │  🚫 (released)  │  currentTouchX: 0.1
│  (empty)   │                 │  Aftertouch: 0.0 ← Fresh start!
└────────────┘                 └──────────────────┘

Mono Note Stack: [Key1@0.1]  ← Key2 removed
Voice Owner: Key 1 ← Restored!
Retrigger: Used Key 1's saved position (0.1) from stack


TIME: t7 - Move finger on Key 1 to 0.5 (owner again)
┌────────────┐
│   KEY 1    │  👆 Owner ✓
│ Touch: 0.5 │────────┐
└────────────┘        │        ┌──────────────────┐
                      └───────▶│  ACTIVE VOICE    │  🔊 Sound Playing
┌────────────┐                 │  initialTouchX: 0.1
│   KEY 2    │  🚫 (empty)     │  currentTouchX: 0.5 ← APPLIED ✓
│  (empty)   │                 │  Aftertouch: +0.4│
└────────────┘                 └──────────────────┘

Mono Note Stack: [Key1@0.5]
Voice Owner: Key 1
Touch Update: Key 1 → Voice (✓ applied because Key 1 is owner)
Result: Smooth continuation from retrieved position!
```

## Key Observations

### Before Fix
- ❌ Touch moves from both keys would update `currentTouchX`
- ❌ Aftertouch would jump between 0.1 (Key 1) and 0.9 (Key 2)
- ❌ Unpredictable, jumpy modulation

### After Fix
- ✅ Only owner key's touches update `currentTouchX`
- ✅ Non-owner touches are blocked (but still saved to stack)
- ✅ Smooth, predictable modulation
- ✅ Correct position restored on key return

## Code Flow

### Touch Move Event Flow
```
User moves finger on Key X
    ↓
handleTouchMoved() called
    ↓
Calculate normalizedCurrentX
    ↓
Update mono note stack (always)
Stack[Key X].currentTouchX = normalizedCurrentX
    ↓
Check ownership
if voicePool.isMonoVoiceOwner(Key X):
    ↓
    Apply to voice (modulation)
    voice.modulationState.currentTouchX = normalizedCurrentX
else:
    ↓
    Block (but position is saved in stack)
    (Do nothing - sound unaffected)
```

### Voice Ownership Check
```
isMonoVoiceOwner(keyIndex):
    ↓
Is polyphonic mode?
    Yes → return true (all keys are "owners")
    No  → return (monoVoiceOwner == keyIndex)
```

## Benefits

1. **Predictable Behavior**: Only one source of truth for touch position
2. **No Jumpiness**: Position doesn't oscillate between keys
3. **Memory Preserved**: Non-owner positions still tracked for retriggering
4. **Clean Architecture**: Single method handles both mono and poly modes
5. **Expressive Playing**: Smooth legato transitions with preserved positions
