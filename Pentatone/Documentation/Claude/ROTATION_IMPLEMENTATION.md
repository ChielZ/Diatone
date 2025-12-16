# Scale Rotation Implementation

## Overview
This implementation adds rotation functionality to your pentatonic scale system, allowing users to shift which note of the scale is mapped to the lowest keyboard key.

## How Rotation Works

### Rotation Values
- **-2**: Two positions backward (with octave adjustment)
- **-1**: One position backward (with octave adjustment)
- **0**: Standard mapping (no rotation)
- **+1**: One position forward
- **+2**: Two positions forward

### Example: Center Meridian (JI) Scale
Original notes: `[1/1, 9/8, 4/3, 3/2, 16/9]`

#### Rotation 0 (Standard)
```
Key 1: 1/1
Key 2: 9/8
Key 3: 4/3
Key 4: 3/2
Key 5: 16/9
Key 6: 1/1 * 2 (next octave)
...
```

#### Rotation +1
Notes shift left, wrapping to next octave:
```
Key 1: 9/8
Key 2: 4/3
Key 3: 3/2
Key 4: 16/9
Key 5: 1/1 * 2 (wrapped to next octave)
Key 6: 9/8 * 2
...
```

#### Rotation +2
Notes shift left by 2 positions:
```
Key 1: 4/3
Key 2: 3/2
Key 3: 16/9
Key 4: 1/1 * 2
Key 5: 9/8 * 2
Key 6: 4/3 * 2
...
```

#### Rotation -1
Notes shift right, wrapping to previous octave:
```
Key 1: 16/9 ÷ 2 (= 8/9, wrapped down an octave)
Key 2: 1/1
Key 3: 9/8
Key 4: 4/3
Key 5: 3/2
Key 6: 16/9
...
```

#### Rotation -2
Notes shift right by 2 positions:
```
Key 1: 3/2 ÷ 2 (= 3/4, wrapped down)
Key 2: 16/9 ÷ 2 (= 8/9, wrapped down)
Key 3: 1/1
Key 4: 9/8
Key 5: 4/3
Key 6: 3/2
...
```

## Implementation Details

### Modified Files

1. **Scales.swift**
   - Added `rotation: Int` property to `Scale` struct (default: 0)
   - Created `applyRotation(to:rotation:)` function to handle note reordering
   - Modified `makeKeyFrequencies(for:baseFrequency:)` to apply rotation before generating frequencies

2. **Penta_ToneApp.swift**
   - Added `@State private var rotation: Int = 0` to track current rotation
   - Modified `currentScale` computed property to include rotation value
   - Added `cycleRotation(forward:)` function to change rotation (clamped to ±2)
   - Passed `onCycleRotation` callback to MainKeyboardView

3. **MainKeyboardView.swift**
   - Added `onCycleRotation` callback parameter
   - Passed callback through to OptionsView

4. **OptionsView.swift**
   - Added `onCycleRotation` callback parameter
   - Passed callback to ScaleView

5. **ScaleView.swift**
   - Added `onCycleRotation` callback parameter
   - Updated Row 9 to display current rotation value with format specifier `%+d` (shows +/- sign)
   - Wired up < and > buttons to call rotation callback

6. **RotationTests.swift** (NEW)
   - Created comprehensive test suite to verify rotation logic
   - Tests all rotation values (-2, -1, 0, +1, +2)
   - Validates octave relationships are maintained

## UI Behavior

The rotation control appears in Row 9 of the ScaleView:
- **Left button (<)**: Decreases rotation (stops at -2)
- **Center display**: Shows current rotation with sign (+0, +1, +2, -1, -2)
- **Right button (>)**: Increases rotation (stops at +2)

The rotation setting:
- Does NOT wrap around (stops at boundaries)
- Persists while navigating between scales
- Applies to all 18 scales
- Updates keyboard frequencies immediately when changed

## Musical Significance

Rotation allows you to:
1. **Change the tonal center**: Start on different scale degrees
2. **Create modal variations**: Same intervals, different starting point
3. **Explore different voicings**: Access notes from adjacent octaves
4. **Fine-tune harmonic relationships**: Find the best fit for your musical context

This is particularly useful in pentatonic systems where each rotation creates a distinctly different musical character while maintaining the same interval relationships.
