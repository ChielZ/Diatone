# Key Priority Voice Allocation - Bug Fix

## The Problem

The initial implementation of key priority voice allocation wasn't working because the `keyToVoiceMap` was being cleared immediately when a key was released, before the voice completed its release phase.

### Flow of the Bug:
1. Key 5 pressed → voice allocated, `keyToVoiceMap[5] = voice0`
2. Key 5 released → `releaseVoice()` called → **`keyToVoiceMap[5]` removed immediately**
3. Voice 0 enters release phase (still sounding)
4. Key 5 pressed again → `keyToVoiceMap[5]` is `nil` → allocates new voice instead of retriggering

Result: The key priority check never triggered because the mapping was gone.

## The Solution

**Keep the key-to-voice mapping alive during the release phase** (polyphonic mode only).

### Changes Made:

#### 1. Modified `releaseVoice()` - Don't Clear Mapping in Poly Mode
```swift
// OLD CODE (line ~370):
keyToVoiceMap.removeValue(forKey: keyIndex)  // Always removed immediately

// NEW CODE:
// Only remove mapping in monophonic mode
if currentPolyphony == 1 {
    keyToVoiceMap.removeValue(forKey: keyIndex)
}
// In polyphonic mode, mapping persists during release phase
```

#### 2. Added Helper Function - `clearKeyMappingForVoice()`
```swift
/// Removes any existing key mapping that points to the given voice
/// Used when voice stealing occurs
private func clearKeyMappingForVoice(_ voice: PolyphonicVoice) {
    if let oldKey = keyToVoiceMap.first(where: { $0.value === voice })?.key {
        keyToVoiceMap.removeValue(forKey: oldKey)
        print("🎵   Cleared old key mapping: key \(oldKey) no longer owns this voice")
    }
}
```

#### 3. Call Helper Before New Allocation
```swift
// In allocateVoice(), normal allocation path:
let voice = findAvailableVoice()

// Clear any old key mapping before assigning to new key
clearKeyMappingForVoice(voice)

// Now assign to new key
keyToVoiceMap[keyIndex] = voice
```

## Key Mapping Lifecycle (Polyphonic Mode)

### Created:
- When `allocateVoice()` assigns a voice to a key

### Persists Through:
- Voice playing (attack, decay, sustain)
- **Voice release phase** ← This is the key fix!

### Removed:
1. **Stale mapping cleanup**: When allocating and `voice.isAvailable == true`
2. **Voice stealing**: When `clearKeyMappingForVoice()` is called for reassignment
3. **Monophonic mode only**: When key is released

## Testing

Now when you press the same key repeatedly:
- First press: Allocates voice (e.g., voice 3)
- Release: Voice enters release, but mapping stays: `keyToVoiceMap[5] = voice3`
- Press again during release: **Retriggers voice 3** ✅
- Console shows: `"🎵 Key 5: Retriggered existing voice (key priority)"`

## Why This Works

The key insight is that **`isAvailable` tracks the voice's release state**, not the key press state:
- `isAvailable = false` → voice is playing OR releasing
- `isAvailable = true` → voice has completed release

By keeping the mapping during `isAvailable = false`, we can detect when the same key is pressed while its voice is still sounding (including during release).

---

**Fixed**: January 22, 2026
**Root Cause**: Premature key mapping cleanup
**Solution**: Preserve mapping during release phase in polyphonic mode
