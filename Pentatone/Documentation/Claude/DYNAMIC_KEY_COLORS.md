# Dynamic Key Colors Implementation

## Overview

The key colors on the pentatonic keyboard now update dynamically based on the rotation setting. This ensures that the visual color of each key always corresponds to the scale degree (note position) being played.

## Implementation Details

### Key Color Function

A new helper function `keyColor(for:)` has been added to `MainKeyboardView`:

```swift
private func keyColor(for keyIndex: Int) -> String {
    let baseColorIndex = keyIndex % 5
    let rotatedColorIndex = (baseColorIndex + currentScale.rotation + 5) % 5
    return "KeyColour\(rotatedColorIndex + 1)"
}
```

### How It Works

1. **Base Pattern**: Without rotation, keys cycle through colors 1-5 repeatedly
   - Key 0 → Color 1 (scale degree 1)
   - Key 1 → Color 2 (scale degree 2)
   - Key 2 → Color 3 (scale degree 3)
   - Key 3 → Color 4 (scale degree 4)
   - Key 4 → Color 5 (scale degree 5)
   - Key 5 → Color 1 (scale degree 1, next octave)
   - ...and so on

2. **With Rotation**: The color assignment shifts to match the rotated note mapping
   - **Positive rotation** (+1, +2): Colors shift to the left (earlier colors appear on later keys)
   - **Negative rotation** (-1, -2): Colors shift to the right (later colors appear on earlier keys)

### Example: Rotation +1

When rotation = +1, the first note of the scale shifts from key 0 to key 4 (wrapping around from the previous octave). The colors shift accordingly:

- Key 0 → Color 2 (now plays scale degree 2)
- Key 1 → Color 3 (now plays scale degree 3)
- Key 2 → Color 4 (now plays scale degree 4)
- Key 3 → Color 5 (now plays scale degree 5)
- Key 4 → Color 1 (now plays scale degree 1, next octave)

### Example: Rotation -1

When rotation = -1, the first note of the scale shifts from key 0 to key 1. The colors shift accordingly:

- Key 0 → Color 5 (now plays scale degree 5, previous octave)
- Key 1 → Color 1 (now plays scale degree 1)
- Key 2 → Color 2 (now plays scale degree 2)
- Key 3 → Color 3 (now plays scale degree 3)
- Key 4 → Color 4 (now plays scale degree 4)

## Color Mapping Across All Keys

The keyboard has 18 keys total (indices 0-17):
- Keys 0-4: First octave (×1)
- Keys 5-9: Second octave (×2)
- Keys 10-14: Third octave (×4)
- Keys 15-17: Fourth octave (×8, only first 3 notes)

Each key's color is calculated independently based on its index, ensuring colors always align with the notes being played regardless of rotation.

## Key Benefits

✅ **Visual Consistency**: Key colors always match the scale degree being played
✅ **Automatic Updates**: Colors update immediately when rotation changes
✅ **Simple Logic**: Centralized color calculation keeps the code clean
✅ **No Manual Maintenance**: No need to hardcode colors for different rotations

## Code Changes

### MainKeyboardView.swift
- Added `keyColor(for:)` function to calculate dynamic colors
- Updated all 18 `KeyButton` instances to use `keyColor(for:)` instead of hardcoded color names
- Left column keys (bottom to top): indices 0, 2, 4, 6, 8, 10, 12, 14, 16
- Right column keys (bottom to top): indices 1, 3, 5, 7, 9, 11, 13, 15, 17

## Testing

To verify the implementation:
1. Set rotation to 0 and observe the default color pattern
2. Increment rotation to +1 and observe colors shift
3. Continue through +2, then back through 0, -1, -2
4. Confirm that keys of the same color always trigger the same scale degree (in different octaves)

## Future Considerations

If you want to add visual effects or animations when rotation changes, you could:
- Add a `.animation()` modifier to the key buttons
- Create a transition effect when colors change
- Add haptic feedback when rotation is adjusted
