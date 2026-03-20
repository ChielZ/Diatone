# skipModulation Flag Implementation Guide

## Problem

When playing the keyboard rapidly, there is an occasional glitch at note onset — a brief pitch sweep (a few milliseconds) instead of a stable pitch. This is caused by a race condition between two threads:

1. **Main/touch thread**: calls `setFrequency()` then `trigger()` to start a new note
2. **Background modulation thread**: runs at 100 Hz, calls `applyModulation()` which writes frequency/filter/modulation values to the oscillators

When the modulation timer fires between `setFrequency()` and the completion of `trigger()`, it can overwrite the freshly-set frequency with a stale value calculated from the previous note's modulation state. This creates a brief pitch ramp from the wrong frequency to the correct one.

## Solution

A per-voice `skipModulation` boolean flag that prevents the modulation loop from writing to a voice's audio parameters while `trigger()` or `retrigger()` is in progress. The flag is raised before any parameter writes begin and cleared after all state is consistent.

## Implementation Steps

### Step 1: Add the flag to PolyphonicVoice

In `PolyphonicVoice`, in the `// MARK: - Voice State` section, add the flag after `isPlaying`:

```swift
var isPlaying: Bool = false

/// When true, the modulation loop skips writing to this voice's audio parameters.
/// Set at the start of trigger()/retrigger() and cleared at the end, preventing the
/// background modulation thread from overwriting freshly-set frequency/filter values
/// with stale data calculated from the previous note's modulation state.
var skipModulation: Bool = false
```

### Step 2: Guard in applyModulation()

At the very top of `applyModulation()`, before any envelope time updates or parameter writes, add an early return:

```swift
func applyModulation(
    globalLFO: (rawValue: Double, parameters: GlobalLFOParameters),
    deltaTime: Double,
    currentTempo: Double = 120.0
) {
    // Skip modulation writes while trigger() or retrigger() is in progress on the main thread.
    // This prevents the modulation loop from overwriting freshly-set frequency/filter values
    // with stale data calculated from the previous note's state.
    guard !skipModulation else { return }

    // Update envelope times based on gate state
    // ... (existing code continues)
```

### Step 3: Wrap trigger() with the flag

Set the flag at the very start of `trigger()`, before the `guard isInitialized` check. Clear it at the very end, after all state is set:

```swift
func trigger(initialTouchX: Double = 0.5, templateFilterCutoff: Double? = nil, templateFilterStatic: FilterStaticParameters? = nil) {
    // Prevent the background modulation loop from overwriting parameters during trigger setup
    skipModulation = true

    guard isInitialized else {
        skipModulation = false
        assertionFailure("Voice must be initialized before triggering")
        return
    }

    // ... (all existing trigger code) ...

    isAvailable = false
    isPlaying = true
    triggerTime = Date()

    // Allow the modulation loop to resume writing to this voice's parameters.
    // All modulation state is now fully consistent with the new note.
    skipModulation = false
}
```

### Step 4: Wrap retrigger() with the flag

Same pattern — set at start, clear at end:

```swift
func retrigger(frequency: Double, initialTouchX: Double = 0.5, templateFilterCutoff: Double? = nil) {
    // Prevent the background modulation loop from overwriting parameters during retrigger
    skipModulation = true

    guard isInitialized else {
        skipModulation = false
        assertionFailure("Voice must be initialized before retriggering")
        return
    }

    // ... (all existing retrigger code) ...

    // NOTE: Envelopes are NOT restarted - this is the key difference from trigger()
    // The voice continues playing with its current envelope state

    // Allow the modulation loop to resume writing to this voice's parameters
    skipModulation = false
}
```

### Step 5: Set the flag in VoicePool before setFrequency() + trigger() sequences

In `VoicePool.allocateVoice()`, there are two places where `setFrequency()` is called immediately before `trigger()`. The flag must be set *before* `setFrequency()` because the modulation loop could fire between the two calls. `trigger()` will clear the flag at its end.

**Polyphonic key-priority retrigger path** (the `if currentPolyphony > 1, let existingVoice = keyToVoiceMap[keyIndex]` block):

```swift
if !existingVoice.isAvailable {
    // Retrigger the existing voice for this key
    // Set skip flag before setFrequency to prevent modulation loop from
    // overwriting the new frequency before trigger() completes
    existingVoice.skipModulation = true
    existingVoice.setFrequency(finalFrequency)
    existingVoice.trigger(
        initialTouchX: initialTouchX,
        templateFilterCutoff: currentTemplate.filter.clampedCutoff,
        templateFilterStatic: currentTemplate.filterStatic
    )
    // ... (trigger() clears skipModulation at its end)
```

**Normal trigger path** (after `findAvailableVoice()` and `clearKeyMappingForVoice()`):

```swift
// Set frequency and trigger with initial touch value
// Set skip flag before setFrequency to prevent modulation loop from
// overwriting the new frequency before trigger() completes
voice.skipModulation = true
voice.setFrequency(finalFrequency)
voice.trigger(
    initialTouchX: initialTouchX,
    templateFilterCutoff: currentTemplate.filter.clampedCutoff,
    templateFilterStatic: currentTemplate.filterStatic
)
// ... (trigger() clears skipModulation at its end)
```

### Paths that do NOT need the flag

- **Mono release → legato retrigger** (`releaseVoice` calling `voice.retrigger()`): already protected because `retrigger()` now wraps itself with the flag.
- **Mono release → non-legato frequency update** (`voice.setFrequency()` without `trigger()`): this is just a frequency glide on an already-playing voice. The modulation loop reading the old frequency for one tick produces the intended legato transition, not a glitch.

## Why this is safe

- On ARM64 (all iOS devices), aligned `Bool` writes are atomic at the hardware level, so the background thread will never see a torn value.
- When the flag is true, the modulation loop skips the entire `applyModulation()` call, so it doesn't read any of the in-flight modulation state fields that `trigger()` is updating.
- At most one 10ms modulation tick is skipped, which is inaudible since `trigger()` has already applied correct initial values (frequency, filter cutoff, envelope ramps) with zero-duration ramps.
- The flag adds zero latency to the touch-to-sound path.
