# Key Color Mapping Examples

## Rotation = 0 (Default)

```
Key Layout (Bottom to Top):
Left Column        Right Column
─────────          ─────────
Key 16: Color 2    Key 17: Color 3
Key 14: Color 5    Key 15: Color 1
Key 12: Color 3    Key 13: Color 4
Key 10: Color 1    Key 11: Color 2
Key  8: Color 4    Key  9: Color 5
Key  6: Color 2    Key  7: Color 3
Key  4: Color 5    Key  5: Color 1
Key  2: Color 3    Key  3: Color 4
Key  0: Color 1    Key  1: Color 2
```

**Pattern**: Keys cycle through colors 1→2→3→4→5 repeatedly
**Result**: All keys with Color 1 play scale degree 1 (in different octaves)
          All keys with Color 2 play scale degree 2 (in different octaves)
          ...etc.

---

## Rotation = +1 (Shift Left)

```
Key Layout (Bottom to Top):
Left Column        Right Column
─────────          ─────────
Key 16: Color 3    Key 17: Color 4
Key 14: Color 1    Key 15: Color 2
Key 12: Color 4    Key 13: Color 5
Key 10: Color 2    Key 11: Color 3
Key  8: Color 5    Key  9: Color 1
Key  6: Color 3    Key  7: Color 4
Key  4: Color 1    Key  5: Color 2
Key  2: Color 4    Key  3: Color 5
Key  0: Color 2    Key  1: Color 3
```

**Pattern**: Keys cycle through colors 2→3→4→5→1 repeatedly
**Result**: The scale has rotated so note 2 is now the lowest note
          Color 2 now appears where Color 1 was
          All colors shift one position to the left

---

## Rotation = +2 (Shift Left by 2)

```
Key Layout (Bottom to Top):
Left Column        Right Column
─────────          ─────────
Key 16: Color 4    Key 17: Color 5
Key 14: Color 2    Key 15: Color 3
Key 12: Color 5    Key 13: Color 1
Key 10: Color 3    Key 11: Color 4
Key  8: Color 1    Key  9: Color 2
Key  6: Color 4    Key  7: Color 5
Key  4: Color 2    Key  5: Color 3
Key  2: Color 5    Key  3: Color 1
Key  0: Color 3    Key  1: Color 4
```

**Pattern**: Keys cycle through colors 3→4→5→1→2 repeatedly
**Result**: The scale has rotated so note 3 is now the lowest note
          Color 3 now appears where Color 1 was
          All colors shift two positions to the left

---

## Rotation = -1 (Shift Right)

```
Key Layout (Bottom to Top):
Left Column        Right Column
─────────          ─────────
Key 16: Color 1    Key 17: Color 2
Key 14: Color 4    Key 15: Color 5
Key 12: Color 2    Key 13: Color 3
Key 10: Color 5    Key 11: Color 1
Key  8: Color 3    Key  9: Color 4
Key  6: Color 1    Key  7: Color 2
Key  4: Color 4    Key  5: Color 5
Key  2: Color 2    Key  3: Color 3
Key  0: Color 5    Key  1: Color 1
```

**Pattern**: Keys cycle through colors 5→1→2→3→4 repeatedly
**Result**: The scale has rotated so note 5 (from previous octave) is now the lowest note
          Color 5 now appears where Color 1 was
          All colors shift one position to the right

---

## Rotation = -2 (Shift Right by 2)

```
Key Layout (Bottom to Top):
Left Column        Right Column
─────────          ─────────
Key 16: Color 5    Key 17: Color 1
Key 14: Color 3    Key 15: Color 4
Key 12: Color 1    Key 13: Color 2
Key 10: Color 4    Key 11: Color 5
Key  8: Color 2    Key  9: Color 3
Key  6: Color 5    Key  7: Color 1
Key  4: Color 3    Key  5: Color 4
Key  2: Color 1    Key  3: Color 2
Key  0: Color 4    Key  1: Color 5
```

**Pattern**: Keys cycle through colors 4→5→1→2→3 repeatedly
**Result**: The scale has rotated so note 4 (from previous octave) is now the lowest note
          Color 4 now appears where Color 1 was
          All colors shift two positions to the right

---

## Key Insight

**The color rotation matches the note rotation perfectly!**

- When rotation = +1, the notes shift "up" (later scale degrees become earlier keys)
- The colors shift accordingly to the left, so keys playing the same scale degree maintain the same color
- This provides immediate visual feedback about which keys play the same scale degree
- Keys of the same color always play the same note (just in different octaves)

## Visual Color Legend

```
KeyColour1: Usually corresponds to the tonic (1st degree) when rotation = 0
KeyColour2: Usually corresponds to the 2nd degree when rotation = 0
KeyColour3: Usually corresponds to the 3rd degree when rotation = 0
KeyColour4: Usually corresponds to the 4th degree when rotation = 0
KeyColour5: Usually corresponds to the 5th degree when rotation = 0
```

With rotation, these associations shift, but keys of the same color always play the same scale degree.
