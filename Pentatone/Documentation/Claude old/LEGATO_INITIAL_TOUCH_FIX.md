# Legato Initial Touch Position Fix

## Problem
When playing trills in monophonic legato mode, the initial touch position (used for velocity-like modulation) was not preserved correctly:

1. First note played: initial touch position applied correctly ✅
2. Second note played: new initial touch position applied correctly ✅  
3. Second note released while first held: touch position reset to default (0.5) ❌

This caused modulation to jump to a neutral position when returning to the first note, breaking the expressive performance.

## Solution
Track the current touch position for each key in the mono note stack and use it when retriggering previously held notes.

### Changes Made

#### 1. VoicePool.swift - MonoNoteStackEntry Structure
Added `currentTouchX` field to store the current touch position for each held key:

```swift
private struct MonoNoteStackEntry {
    let keyIndex: Int
    let frequency: Double
    let globalPitch: GlobalPitchParameters
    var currentTouchX: Double  // Made mutable so we can update it during touch moves
}
```

#### 2. VoicePool.swift - Store Initial Touch on Note On
When adding a key to the mono note stack, store its initial touch position:

```swift
let entry = MonoNoteStackEntry(
    keyIndex: keyIndex, 
    frequency: frequency, 
    globalPitch: globalPitch,
    currentTouchX: initialTouchX  // Store initial touch position
)
```

#### 3. VoicePool.swift - New Method to Update Touch Position
Added `updateMonoNoteStackTouchPosition()` to update the stored touch position as the user moves their finger:

```swift
func updateMonoNoteStackTouchPosition(forKey keyIndex: Int, touchX: Double) {
    guard currentPolyphony == 1 else { return }
    
    if let index = monoNoteStack.firstIndex(where: { $0.keyIndex == keyIndex }) {
        monoNoteStack[index].currentTouchX = touchX
    }
}
```

#### 4. VoicePool.swift - Use Stored Touch on Retrigger
When releasing a key and returning to a previous note, use the stored touch position:

```swift
let previousTouchX = previousEntry.currentTouchX  // Use stored touch position!

// Retrigger in legato mode with correct touch position
voice.retrigger(
    frequency: finalFrequency,
    initialTouchX: previousTouchX,  // Use the stored touch position
    templateFilterCutoff: currentTemplate.filter.clampedCutoff
)
```

#### 5. MainKeyboardView.swift - Update Touch Position on Move
Call the new method when touches move to keep the mono note stack up to date:

```swift
func handleTouchMoved(to location: CGPoint) {
    // ... existing code ...
    
    allocatedVoice?.modulationState.currentTouchX = normalizedCurrentX
    
    // Update mono note stack for legato retriggering
    voicePool.updateMonoNoteStackTouchPosition(forKey: keyIndex, touchX: normalizedCurrentX)
}
```

## Result
Now when playing trills in monophonic mode:

1. First note played at position X → modulation uses X ✅
2. User slides finger to position Y while holding first note → mono stack updated to Y ✅
3. Second note played at position Z → modulation uses Z ✅
4. User slides finger on second note to position W → mono stack updated for second key ✅
5. Second note released → retriggering uses Y (current position of first key) ✅

The modulation now maintains continuity and responds to the actual current touch position of each held key, creating a much more natural and expressive playing experience for trills and other legato passages.

## Testing Recommendations
1. Set initial touch modulation to a noticeable destination (e.g., oscillator amplitude or filter cutoff)
2. Play a note on the left side of a key (low initial touch value)
3. While holding, slide finger to the right side (high value)
4. Play a second note on a different key
5. Release the second note while still holding the first
6. Verify the sound returns to the current position (right side) of the first key, not the center

## Notes
- This fix only affects monophonic mode behavior
- Polyphonic mode is unaffected (each voice tracks its own initial touch independently)
- The fix preserves both initial touch (for velocity-like modulation) and aftertouch (for continuous modulation) correctly
