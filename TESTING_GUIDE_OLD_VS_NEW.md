# Testing Guide: Old vs New Touch System

## What Was Changed for Testing

### 1. Disabled Old Hardwired Control (MainKeyboardView)

**In `handleTrigger()`:**
- ❌ OLD: `voice.setAmplitudeFromTouch(normalized)` - Set amplitude directly from touch
- ✅ NEW: `voice.setAmplitudeFromTouch(0.0)` - Set neutral base (modulation system will apply touch)

**In `handleAftertouch()`:**
- ❌ OLD: Full implementation with logarithmic scaling, smoothing, and direct filter control
- ✅ NEW: Only updates `modulationState.currentTouchX` - modulation system handles the rest

### 2. Enabled New Routable Modulation (SoundParameters)

```swift
touchInitial: TouchInitialParameters(
    destination: .oscillatorAmplitude,   // Same as old: touch → amplitude
    amount: 1.0,                         // Full range (0.0 to 1.0)
    isEnabled: true                      // ✅ ENABLED
)

touchAftertouch: TouchAftertouchParameters(
    destination: .filterCutoff,          // Same as old: aftertouch → filter
    amount: 10.0,                        // High sensitivity to match old behavior
    isEnabled: true                      // ✅ ENABLED
)
```

## Expected Behavior (Should Match Old System)

### Test 1: Initial Touch Position (Amplitude Control)

**Old behavior:**
- Touch outer edge of key → Loud sound (amplitude ~1.0)
- Touch inner edge of key → Quiet sound (amplitude ~0.0)
- Linear relationship between position and amplitude

**New behavior should be identical:**
- Touch outer edge → `initialTouchX = 1.0` → Modulation applies 1.0 to amplitude
- Touch inner edge → `initialTouchX = 0.0` → Modulation applies 0.0 to amplitude

✅ **Test:** Touch keys at different positions and verify amplitude matches old behavior

---

### Test 2: Aftertouch (Filter Cutoff Control)

**Old behavior:**
- Hold key and move finger right → Filter gets brighter (cutoff increases)
- Move finger left → Filter gets darker (cutoff decreases)
- Logarithmic scaling (exponential response)
- Smoothing applied (no jitter)
- Range: 500 Hz - 12,000 Hz

**New behavior approximation:**
- Aftertouch delta is calculated: `currentTouchX - initialTouchX`
- Applied with high sensitivity (`amount = 10.0`) to match old scaling
- LFO-style bipolar modulation (adds/subtracts from base)

⚠️ **Differences you might notice:**
1. **No smoothing** - New system applies raw delta, may feel more immediate/jittery
2. **Different clamping** - New system clamps to 20-22050 Hz (wider range)
3. **Slightly different curve** - Old system had custom sensitivity calculation

✅ **Test:** Hold key and move finger left/right, verify filter sweeps in correct direction

---

## Testing Procedure

### Phase 1: Basic Touch Response

1. **Build and run the app**
2. **Touch outer edge of a key** 
   - Expected: Loud sound
   - If silent: Touch modulation may not be applying correctly
   
3. **Touch inner edge of a key**
   - Expected: Quiet sound
   - If loud: Touch modulation is inverted

4. **Touch middle of a key**
   - Expected: Medium volume
   - If wrong: Touch mapping may be incorrect

### Phase 2: Aftertouch Response

1. **Touch and hold a key (any position)**
2. **Slowly move finger to the right (toward outer edge)**
   - Expected: Filter cutoff increases (brighter sound)
   - If decreases: Aftertouch direction is inverted
   
3. **Move finger to the left (toward inner edge)**
   - Expected: Filter cutoff decreases (darker sound)
   
4. **Move finger back to starting position**
   - Expected: Filter returns to original brightness

### Phase 3: Sensitivity Comparison

If you have a way to test the old behavior (e.g., git branch or backup):

1. Test old system sensitivity:
   - Move finger 100 points (roughly 1/4 key width)
   - Note how much filter changes
   
2. Test new system sensitivity:
   - Same movement
   - Should feel similar (maybe slightly different)
   
3. If new system feels:
   - **Too sensitive:** Decrease `amount` in `touchAftertouch` (try 5.0 or 7.0)
   - **Not sensitive enough:** Increase `amount` (try 15.0 or 20.0)

## Troubleshooting

### Problem: No sound at all

**Possible causes:**
1. Touch modulation not applying amplitude
2. Base amplitude is 0.0 and modulation isn't enabled

**Check:**
- Verify `touchInitial.isEnabled = true` in defaults
- Check console for "🎹 Key X: Allocated voice" messages
- Verify `voicePool` is running the modulation timer

### Problem: Constant volume (no touch sensitivity)

**Possible causes:**
1. Touch modulation targeting wrong parameter
2. Another modulator overwriting touch modulation

**Check:**
- Verify `touchInitial.destination = .oscillatorAmplitude`
- Disable other modulators (LFOs, envelopes) for testing
- Check modulation order (touch should be last)

### Problem: Filter doesn't respond to aftertouch

**Possible causes:**
1. `currentTouchX` not updating
2. Aftertouch modulation not enabled
3. Another modulator overwriting filter

**Check:**
- Verify `touchAftertouch.isEnabled = true`
- Verify `touchAftertouch.destination = .filterCutoff`
- Check that `handleAftertouch()` is being called (add debug print)

### Problem: Aftertouch feels different (jittery, too fast, etc.)

**Expected:** The new system will feel slightly different because:
- No smoothing applied
- Raw delta values used
- Different scaling curve

**Solutions:**
1. Adjust `amount` parameter to match feel
2. Consider adding smoothing back if needed
3. May need to tune the sensitivity calculation

## Adjusting Sensitivity

If aftertouch sensitivity doesn't match the old system:

### Too Sensitive

```swift
touchAftertouch: TouchAftertouchParameters(
    destination: .filterCutoff,
    amount: 5.0,     // Reduced from 10.0
    isEnabled: true
)
```

### Not Sensitive Enough

```swift
touchAftertouch: TouchAftertouchParameters(
    destination: .filterCutoff,
    amount: 15.0,    // Increased from 10.0
    isEnabled: true
)
```

### Different Curve (more subtle at edges)

You might need to implement a custom curve in the modulation router, but try adjusting `amount` first.

## What to Report Back

After testing, please report:

1. **Initial touch (amplitude):**
   - ✅ Works the same
   - ⚠️ Works but feels different (describe difference)
   - ❌ Doesn't work (describe issue)

2. **Aftertouch (filter):**
   - ✅ Works the same
   - ⚠️ Works but feels different (describe difference: too sensitive, not smooth, etc.)
   - ❌ Doesn't work (describe issue)

3. **Any unexpected behavior:**
   - Describe what happened vs. what you expected

## Next Steps

### If Testing is Successful ✅

We can proceed to **remove the old hardwired code entirely**:
1. Delete the commented-out old code from `handleTrigger()` and `handleAftertouch()`
2. Clean up any unused smoothing state variables
3. Update documentation to reflect new system only

### If Adjustments Needed ⚠️

We can tune:
1. Sensitivity (`amount` parameter)
2. Add smoothing back if needed
3. Adjust scaling curves
4. Fine-tune touch mapping

### If Not Working ❌

We'll debug:
1. Check if modulation timer is running
2. Verify touch values are being stored
3. Check modulation application order
4. Verify parameter routing

---

## Current Configuration Summary

| Parameter | Old System | New System |
|-----------|-----------|------------|
| **Initial Touch** | Hardwired to amplitude | `touchInitial` → `.oscillatorAmplitude` |
| **Touch Mapping** | Direct (0.0-1.0) | Direct (0.0-1.0) |
| **Aftertouch** | Hardwired to filter | `touchAftertouch` → `.filterCutoff` |
| **Aftertouch Scaling** | Custom (2.5 octaves/100pt) | `amount = 10.0` (approximation) |
| **Smoothing** | Yes (lerp factor 0.5) | No (raw values) |
| **Range Clamping** | 500-12000 Hz | 20-22050 Hz |

Let me know how the testing goes!
