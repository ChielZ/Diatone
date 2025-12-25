# Fix: Choppy Aftertouch Response

## Problem

Aftertouch response was choppy and jumpy after switching to the routable modulation system.

## Root Cause

The issue was the **movement threshold** in the MainKeyboardView gesture handler:

```swift
// OLD CODE (PROBLEM):
private let movementThreshold: CGFloat = 1.0

// In gesture handler:
if let lastX = lastAftertouchX, abs(touchX - lastX) >= movementThreshold,
   let initialX = initialTouchX {
    lastAftertouchX = touchX
    handleAftertouch(...)  // Only called when finger moves > 1 point
}
```

### Why This Caused Choppiness

1. The gesture handler only updated `currentTouchX` when the finger moved **more than 1 point**
2. The modulation system runs at **200 Hz** (every 5ms)
3. So `currentTouchX` was "quantized" to 1-point steps
4. The filter jumped in discrete 1-point increments instead of smoothly following the finger

### The Old System Didn't Have This Problem Because:

The old hardwired aftertouch had the same threshold, but it also had **smoothing** (linear interpolation) which blended the 1-point steps into smooth motion:

```swift
// Old system smoothing:
let smoothingFactor = 0.5
let smoothedCutoff = currentCutoff + (targetCutoff - currentCutoff) * (1.0 - smoothingFactor)
```

This smoothing masked the choppiness from the movement threshold.

## Solution

### Fix 1: Remove Movement Threshold

```swift
// NEW CODE (FIXED):
// No movement threshold - update on every touch event
if let initialX = initialTouchX {
    handleAftertouch(initialX: initialX, currentX: touchX, viewWidth: geometry.size.width)
}
```

Now `currentTouchX` updates on every touch event (which happens at screen refresh rate, typically 60-120 Hz), giving the 200 Hz modulation system smooth input data.

### Fix 2: Removed Unused State

Removed `lastAftertouchX` state variable since it was only used for the threshold check.

## Files Modified

**V02 MainKeyboardView.swift:**
- Removed `movementThreshold` constant
- Removed `lastAftertouchX` state variable
- Simplified gesture handler to update on every touch event

## Testing

After this fix, aftertouch should feel smooth and responsive:

1. **Touch and hold a key**
2. **Slowly move finger left/right**
3. **Expected:** Filter sweeps smoothly, no jumping or stepping

## Why This Works

Now the data flow is:
1. Touch event → `currentTouchX` updated immediately (60-120 Hz)
2. Modulation timer → Reads `currentTouchX` and applies to filter (200 Hz)
3. Filter updates smoothly between touch events (interpolated by the 200 Hz timer)

The 200 Hz modulation rate is fast enough to smooth between the touch events, giving buttery smooth response.

## Remaining Differences from Old System

The new system still differs from the old in:

1. **No extra smoothing** - The old system had a smoothing factor of 0.5
2. **Different sensitivity curve** - May need to adjust `amount` parameter
3. **Wider range** - 20-22050 Hz instead of 500-12000 Hz

If aftertouch still feels different after this fix, we can:
- Add smoothing back (in the modulation router or as a parameter)
- Adjust the `amount` value (currently 10.0)
- Implement custom scaling curves

## Performance Note

Updating `currentTouchX` on every touch event (60-120 Hz) is much less frequent than the modulation timer (200 Hz), so there's no performance concern. The touch events are the bottleneck, not the modulation system.
