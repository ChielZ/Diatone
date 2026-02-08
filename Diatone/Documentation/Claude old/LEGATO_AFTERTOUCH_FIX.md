# Legato Aftertouch Fix

## Problem
When playing in monophonic legato mode with multiple keys held down, aftertouch (touch movements) from all held keys were being applied to the currently playing voice. This caused:

- **Jumpiness**: Touch position would jump between values from different keys
- **Unpredictable behavior**: The sound would respond to touches on keys that weren't currently playing
- **No initial touch reset**: When a new note was triggered, the aftertouch reference wasn't reset to the new note's initial position

Example scenario:
1. Hold key 1 at left edge (touch position 0.2)
2. Hold key 2 at right edge (touch position 0.8) → sound now plays key 2
3. Move finger on key 1 → sound incorrectly responds to key 1's touch moves
4. Aftertouch modulation jumps between 0.2 (key 1) and 0.8 (key 2)

## Solution
Implement voice ownership tracking so only the currently playing key's touches affect the sound.

### Key Concepts

1. **Voice Ownership**: In monophonic mode, only one key "owns" the active voice at any time
2. **Touch Filtering**: Only touch moves from the owning key update the voice's `currentTouchX`
3. **Stack Tracking**: All held keys' touch positions are still tracked in the mono note stack for retriggering
4. **Automatic Reset**: When a new note takes over, `initialTouchX` is automatically set to the new note's touch position

### Changes Made

#### 1. VoicePool.swift - Enhanced monoVoiceOwner Documentation
Updated the comment to clarify that `monoVoiceOwner` is used for both:
- Release control (who can release the voice)
- Touch filtering (whose touches affect the sound)

```swift
/// In monophonic mode, tracks which key currently "owns" the active voice
/// Only the owning key can release the voice (last-note priority)
/// Also used to filter touch moves - only the owning key's touches affect the sound
private var monoVoiceOwner: Int? = nil
```

#### 2. VoicePool.swift - New Method: isMonoVoiceOwner()
Added a public method to check if a key is the current owner:

```swift
/// Checks if a key is the current owner in monophonic mode
/// Only the owner key's touch movements should affect the sound
/// - Parameter keyIndex: The key index to check
/// - Returns: true if this key owns the active voice, false otherwise
func isMonoVoiceOwner(_ keyIndex: Int) -> Bool {
    guard currentPolyphony == 1 else {
        // In polyphonic mode, each key owns its own voice
        return true
    }
    return monoVoiceOwner == keyIndex
}
```

**Design Notes**:
- In polyphonic mode, always returns `true` (each key owns its own voice)
- In monophonic mode, returns `true` only for the owning key
- This allows the keyboard view to use a single check regardless of mode

#### 3. MainKeyboardView.swift - Filter Touch Updates
Modified `handleTouchMoved()` to only apply touches from the owning key:

```swift
func handleTouchMoved(to location: CGPoint) {
    guard allocatedVoice != nil else { return }
    
    let currentX = isLeftSide ? location.x : viewWidth - location.x
    let normalizedCurrentX = max(0.0, min(1.0, currentX / viewWidth))
    
    // Always update the mono note stack to track this key's position
    voicePool.updateMonoNoteStackTouchPosition(forKey: keyIndex, touchX: normalizedCurrentX)
    
    // IMPORTANT: Only apply touch moves if this key is the owner
    if voicePool.isMonoVoiceOwner(keyIndex) {
        allocatedVoice?.modulationState.currentTouchX = normalizedCurrentX
    }
}
```

**Key Points**:
- All keys still update their position in the mono note stack (for retriggering)
- Only the owner key updates the voice's `currentTouchX` (for actual sound modulation)
- The check works seamlessly in both mono and poly modes

## How It Works Now

### Scenario 1: Monophonic Legato (2 keys held)

```
Timeline:
1. Press key 1 at position 0.2
   - Key 1 becomes owner
   - initialTouchX = 0.2
   - currentTouchX = 0.2
   - Aftertouch delta = 0.0

2. Move finger on key 1 to position 0.4
   - isMonoVoiceOwner(key1) = true ✅
   - currentTouchX = 0.4 (applied)
   - Aftertouch delta = +0.2 (0.4 - 0.2)

3. Press key 2 at position 0.8 (while holding key 1)
   - Key 2 becomes owner
   - initialTouchX = 0.8 (RESET!)
   - currentTouchX = 0.8
   - Aftertouch delta = 0.0 (RESET!)

4. Move finger on key 1 to position 0.3
   - isMonoVoiceOwner(key1) = false ❌
   - currentTouchX stays 0.8 (NOT applied)
   - Stack updated: key1.touchX = 0.3 (for later retriggering)

5. Move finger on key 2 to position 0.9
   - isMonoVoiceOwner(key2) = true ✅
   - currentTouchX = 0.9 (applied)
   - Aftertouch delta = +0.1 (0.9 - 0.8)

6. Release key 2 (while holding key 1)
   - Key 1 becomes owner again
   - initialTouchX = 0.3 (from stack!)
   - currentTouchX = 0.3
   - Aftertouch delta = 0.0 (fresh start)

7. Move finger on key 1 to position 0.5
   - isMonoVoiceOwner(key1) = true ✅
   - currentTouchX = 0.5 (applied)
   - Aftertouch delta = +0.2 (0.5 - 0.3)
```

### Scenario 2: Polyphonic Mode (for comparison)

```
1. Press key 1 at position 0.2
   - Voice 1 allocated
   - isMonoVoiceOwner(key1) = true (always true in poly mode)
   
2. Press key 2 at position 0.8
   - Voice 2 allocated
   - isMonoVoiceOwner(key2) = true (always true in poly mode)
   
3. Move finger on key 1 to position 0.4
   - isMonoVoiceOwner(key1) = true ✅
   - Voice 1's currentTouchX = 0.4
   
4. Move finger on key 2 to position 0.9
   - isMonoVoiceOwner(key2) = true ✅
   - Voice 2's currentTouchX = 0.9
   
Both voices respond to their own keys independently!
```

## Benefits

1. **Predictable Aftertouch**: Only the currently playing key affects the sound
2. **No Jumpiness**: Touch position doesn't jump when multiple keys are held
3. **Automatic Reset**: Each new note starts with aftertouch delta = 0
4. **Preserved History**: Non-owner keys still track their positions for retriggering
5. **Mode Agnostic**: Works seamlessly in both mono and poly modes

## Testing Recommendations

### Test 1: Basic Legato Trill
1. Set aftertouch to modulate filter cutoff (amount: 3-5 octaves)
2. Enter monophonic mode
3. Press key 1 at left edge → filter at base frequency
4. Slide finger right on key 1 → filter should open
5. Press key 2 at left edge (while holding key 1) → filter should reset to base
6. Slide finger right on key 1 (non-owner) → filter should NOT move
7. Slide finger right on key 2 (owner) → filter should open

### Test 2: Note Stack Return
1. Same setup as Test 1
2. Press key 1 at left edge
3. Slide finger right to middle position
4. Press key 2 at left edge (while holding key 1)
5. Release key 2 → should return to key 1 at middle position
6. Slide finger right on key 1 → filter should continue from middle position

### Test 3: Polyphonic Mode (sanity check)
1. Same setup as Test 1
2. Enter polyphonic mode
3. Press key 1 at left edge, slide right → filter opens
4. Press key 2 at left edge (while holding key 1)
5. Slide finger on both keys → both filters should respond independently

## Notes

- This fix only affects aftertouch (continuous touch modulation)
- Initial touch (velocity-like modulation) was already working correctly
- The mono note stack continues to track all keys' positions for proper retriggering
- In polyphonic mode, all keys are considered "owners" so behavior is unchanged
