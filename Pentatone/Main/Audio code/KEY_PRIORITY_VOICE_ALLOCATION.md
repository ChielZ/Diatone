# Key Priority Voice Allocation

## Overview

This document describes the implementation of **key priority voice allocation** in the polyphonic voice management system. This feature prevents the same key from triggering multiple overlapping voices when pressed repeatedly.

## Problem Statement

Previously, the voice allocation system used a pure round-robin approach. When the same key was pressed multiple times in succession (even while the previous note was still releasing), each press would allocate a new voice. This could lead to:

- Excessive voice buildup when a key is "drummed" or pressed rapidly
- Unnatural sound from multiple instances of the same note overlapping
- Potential voice exhaustion if all voices are used by the same key

## Solution

The new implementation adds **key priority checking** before allocating a new voice:

1. **Check existing mapping**: Before allocating a new voice, check if this key already has a voice assigned in `keyToVoiceMap`
2. **Retrigger if active**: If the mapped voice is still active (not yet fully released, i.e., `!isAvailable`), retrigger that same voice instead of allocating a new one
3. **Clean up stale mappings**: If the mapped voice has already completed its release (`isAvailable == true`), remove the stale mapping and proceed with normal allocation

## Implementation Details

### Voice Allocation Flow (Polyphonic Mode)

```swift
// In allocateVoice(frequency:forKey:globalPitch:initialTouchX:)

// 1. Check if this key already has a mapped voice
if currentPolyphony > 1, let existingVoice = keyToVoiceMap[keyIndex] {
    
    // 2. Check if that voice is still in use (in release phase or still playing)
    if !existingVoice.isAvailable {
        // Retrigger the existing voice - restart attack from current position
        existingVoice.setFrequency(finalFrequency)
        existingVoice.trigger(...)
        print("🎵 Key \(keyIndex): Retriggered existing voice (key priority)")
        return existingVoice
    } else {
        // Voice has fully released - clean up stale mapping
        keyToVoiceMap.removeValue(forKey: keyIndex)
    }
}

// 3. If no existing voice, proceed with normal round-robin allocation
let voice = findAvailableVoice()
voice.trigger(...)
keyToVoiceMap[keyIndex] = voice
```

### Key State Tracking

The system uses the existing `keyToVoiceMap: [Int: PolyphonicVoice]` dictionary to track which voice is associated with each key. This mapping:

- **Created**: When a key triggers a voice (in `allocateVoice()`)
- **Updated**: When a key retriggers its existing voice
- **Removed**: When a key is released (in `releaseVoice()`) or when a stale mapping is detected

### Voice Availability

The `isAvailable` property on `PolyphonicVoice` is the source of truth for whether a voice can be reused:

- `isAvailable = false`: Voice is either playing or in release phase
- `isAvailable = true`: Voice has completed its release and is ready for allocation

A voice marks itself available asynchronously after its release duration completes:

```swift
// In PolyphonicVoice.release()
let releaseTime = voiceModulation.loudnessEnvelope.release * 8
Task {
    try? await Task.sleep(nanoseconds: UInt64(releaseTime * 1_000_000_000))
    await MainActor.run {
        self.isAvailable = true
    }
}
```

## Behavior Examples

### Example 1: Rapid Key Presses

**Before**: Key 5 pressed 3 times rapidly
- Press 1: Allocates voice 0, starts playing
- Press 2: Allocates voice 1, starts playing (voice 0 still releasing)
- Press 3: Allocates voice 2, starts playing (voices 0-1 still releasing)
- Result: 3 voices playing the same note simultaneously

**After**: Key 5 pressed 3 times rapidly
- Press 1: Allocates voice 0, starts playing
- Press 2: Retriggers voice 0 (restarts from release phase)
- Press 3: Retriggers voice 0 (restarts from attack phase)
- Result: Only 1 voice used, clean retriggering

### Example 2: Different Keys

**Behavior (unchanged)**: Keys 5, 7, 10 pressed in sequence
- Press key 5: Allocates voice 0
- Press key 7: Allocates voice 1 (different key, round-robin continues)
- Press key 10: Allocates voice 2 (different key, round-robin continues)
- Result: 3 different voices for 3 different keys

### Example 3: Same Key After Full Release

**Behavior**: Key 5 pressed, released, then pressed again after release completes
- Press 1: Allocates voice 0, maps key 5 → voice 0
- Release: Voice 0 begins release phase
- [Wait for release to complete]
- Press 2: Voice 0 is now available, stale mapping cleaned, allocates next available voice (could be voice 0 or voice 1 depending on round-robin)

## Scope

### Applies To
- ✅ **Polyphonic mode** (`currentPolyphony > 1`)

### Does Not Apply To
- ❌ **Monophonic mode** (`currentPolyphony == 1`): Uses a completely different system with note stack and legato support

## Benefits

1. **More natural playing feel**: Repeatedly pressing the same key feels like "drumming" on a single object, not spawning multiple instances
2. **Voice efficiency**: Prevents voice exhaustion when a single key is played rapidly
3. **Cleaner sound**: No phase interference or buildup from overlapping instances of the same note
4. **Professional behavior**: Matches the behavior of most hardware synthesizers

## Compatibility

This change is **fully backward compatible**:
- No changes to the API or function signatures
- No changes to monophonic mode behavior
- No changes to preset system or parameter structures
- Existing code continues to work without modification

## Testing Recommendations

1. **Basic retriggering**: Press the same key repeatedly and verify only one voice is used
2. **Different keys**: Press different keys and verify round-robin still works normally
3. **Long releases**: Use long release times and verify retriggering works during release phase
4. **Voice stealing**: With all voices active on different keys, press a new key and verify voice stealing still works
5. **Monophonic mode**: Verify legato and note stack behavior is unchanged

## Future Enhancements

Potential improvements for future consideration:
- **Configurable behavior**: Add a preference to toggle between key priority and pure round-robin
- **Velocity sensitivity**: Different behavior based on touch intensity
- **Release tail preservation**: Option to keep release tail and add new attack on top (layered retriggering)

---

**Implementation Date**: January 22, 2026
**File Modified**: `A3 VoicePool.swift`
**Function Modified**: `allocateVoice(frequency:forKey:globalPitch:initialTouchX:)`
