# Aftertouch Smoothing Implementation

## What Was Added

Added smoothing to the aftertouch modulation system to eliminate choppy/discontinuous filter sweeps.

## Changes Made

### 1. ModulationState (A06 ModulationSystem.swift)

Added smoothing state variables:

```swift
struct ModulationState {
    // ... existing fields ...
    
    // Smoothing state for filter modulation
    var lastSmoothedFilterCutoff: Double? = nil  // Last smoothed filter value
    var filterSmoothingFactor: Double = 0.5      // 0.0 = no smoothing, 1.0 = max smoothing
}
```

**Parameters:**
- `lastSmoothedFilterCutoff`: Stores the last applied filter value for interpolation
- `filterSmoothingFactor`: Controls smoothing amount (0.5 matches old system)

### 2. Updated reset() Method

The `reset()` method now clears smoothing state when a new note is triggered:

```swift
mutating func reset(frequency: Double, touchX: Double, resetLFOPhase: Bool = true) {
    // ... existing code ...
    
    // Reset smoothing state for new note
    lastSmoothedFilterCutoff = nil
}
```

This ensures each note starts with fresh smoothing.

### 3. applyTouchAftertouch() with Smoothing (A02 PolyphonicVoice.swift)

Updated the aftertouch application to include smoothing:

```swift
private func applyTouchAftertouch() {
    // ... calculate target value ...
    
    // Apply smoothing for filter cutoff destination
    let finalValue: Double
    if destination == .filterCutoff {
        // Get current smoothed value
        let currentValue = modulationState.lastSmoothedFilterCutoff ?? targetValue
        
        // Apply linear interpolation (lerp)
        let smoothingFactor = modulationState.filterSmoothingFactor
        let interpolationAmount = 1.0 - smoothingFactor
        finalValue = currentValue + (targetValue - currentValue) * interpolationAmount
        
        // Store for next iteration
        modulationState.lastSmoothedFilterCutoff = finalValue
    } else {
        // No smoothing for other destinations
        finalValue = targetValue
    }
    
    // Apply the final smoothed value
    applyModulatedValue(finalValue, to: destination)
}
```

## How It Works

### Linear Interpolation (LERP)

The smoothing uses linear interpolation to blend between the current and target values:

```
finalValue = currentValue + (targetValue - currentValue) × (1 - smoothingFactor)
```

With `smoothingFactor = 0.5`:
- `interpolationAmount = 1 - 0.5 = 0.5`
- Each frame moves 50% of the way toward the target
- This creates smooth, exponential-like easing

### Example

If current filter = 1000 Hz and target = 2000 Hz:

**Frame 1:** `1000 + (2000 - 1000) × 0.5 = 1500 Hz`  
**Frame 2:** `1500 + (2000 - 1500) × 0.5 = 1750 Hz`  
**Frame 3:** `1750 + (2000 - 1750) × 0.5 = 1875 Hz`  
...and so on (exponential approach to target)

### Why It Works at 200 Hz

The modulation system runs at 200 Hz (every 5ms), which is much faster than:
- Touch events: 60-120 Hz
- Human perception: ~50 Hz for smooth motion

So even with 0.5 smoothing (50% per frame), the filter reaches the target within ~10-20ms, which feels instantaneous while eliminating stepping/choppiness.

## Smoothing Factor Guide

Adjust `filterSmoothingFactor` in code to tune the smoothing:

| Factor | Effect | Use Case |
|--------|--------|----------|
| 0.0 | No smoothing (instant) | Maximum responsiveness, may be choppy |
| 0.3 | Light smoothing | Quick response, minimal smoothing |
| 0.5 | Medium smoothing (default) | Balanced - smooth but responsive |
| 0.7 | Heavy smoothing | Very smooth, slight lag |
| 0.9 | Maximum smoothing | Extremely smooth, noticeable lag |

## Benefits

✅ **Smooth filter sweeps** - No more stepping or jumping  
✅ **Preserves responsiveness** - 200 Hz updates feel instant  
✅ **Low overhead** - Simple arithmetic, no performance impact  
✅ **Matches old behavior** - 0.5 factor matches old system exactly  
✅ **Destination-specific** - Only applies to filter, not amplitude/pitch  

## Future Enhancements

If you want to make smoothing adjustable per-preset:

1. Add `smoothingFactor` to `TouchAftertouchParameters`:
   ```swift
   struct TouchAftertouchParameters: Codable, Equatable {
       var destination: ModulationDestination
       var amount: Double
       var smoothingFactor: Double = 0.5  // NEW
       var isEnabled: Bool
   }
   ```

2. Use preset value instead of hardcoded 0.5:
   ```swift
   let smoothingFactor = params.smoothingFactor
   ```

3. Expose in UI for per-preset control

## Testing

After building with this change:

1. **Touch and hold a key**
2. **Slowly move finger left/right**
3. **Expected:** Filter should sweep smoothly with no stepping
4. **Try fast movements** - Should still track finger well
5. **Try subtle movements** - Should respond to small changes

The smoothing should eliminate choppiness while maintaining the immediate, responsive feel.

## Comparison to Old System

| Feature | Old Hardwired | New Routable with Smoothing |
|---------|--------------|----------------------------|
| Smoothing | ✅ Yes (0.5 factor) | ✅ Yes (0.5 factor) |
| Update rate | Variable (touch events) | ✅ 200 Hz (consistent) |
| Scaling | Logarithmic (custom) | Logarithmic (LFO router) |
| Threshold | 1.0 point | ✅ None (smooth updates) |
| Result | Smooth but quantized | ✅ Smooth and continuous |

The new system should now feel very similar to the old system, with the added benefit of 200 Hz updates and routable destinations!
