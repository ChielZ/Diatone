# Carrier Multiplier Enum Implementation

## Summary
Successfully implemented discrete carrier multiplier values using an enum-based approach, replacing the previous continuous integer range (1-8) with a set of musically meaningful harmonic and subharmonic ratios (1/8 through 8).

## Changes Made

### 1. New CarrierMultiplier Enum (`A1 SoundParameters.swift`)
Created a new enum with 15 discrete values:
- **Subharmonics (fractional)**: 1/8, 1/7, 1/6, 1/5, 1/4, 1/3, 1/2
- **Harmonics (integer)**: 1, 2, 3, 4, 5, 6, 7, 8

**Features:**
- Raw value type: `Double` (for AudioKit compatibility)
- Conforms to: `Codable`, `Equatable`, `CaseIterable`, `Identifiable`
- Display method: `displayName` shows fractions (e.g., "1/4") or integers (e.g., "2")
- Migration support: `nearest(to:)` method finds closest enum case from a Double value

### 2. Updated OscillatorParameters Struct (`A1 SoundParameters.swift`)
Changed `carrierMultiplier` type from `Double` to `CarrierMultiplier` enum.

**Backward Compatibility:**
- Implemented custom `init(from decoder:)` to support old presets
- If preset contains old `Double` value, it's automatically migrated to nearest enum case
- New presets save as enum (more reliable)

### 3. New UI Component (`V4-C ParameterComponents.swift`)
Created `DiscreteEnumSliderRow` - a slider that snaps to exact enum values:
- Slider with detent snapping (no interpolation)
- < and > buttons for precise stepping
- Label and value display
- Works with any `CaseIterable & Equatable & Identifiable` enum

**Key Feature:** Values pushed to the parameter manager are always **exact enum cases**, never approximations from slider position.

### 4. Updated OscillatorView (`V4-S01 OscillatorView.swift`)
Replaced `IntegerSliderRow` with `DiscreteEnumSliderRow`:
```swift
DiscreteEnumSliderRow(
    label: "CARRIER MULTIPLIER",
    value: Binding(
        get: { paramManager.voiceTemplate.oscillator.carrierMultiplier },
        set: { newValue in
            paramManager.updateCarrierMultiplier(newValue)
            applyToAllVoices()
        }
    ),
    displayFormatter: { $0.displayName }
)
```

### 5. Updated ParameterManager (`A7 ParameterManager.swift`)
Changed `updateCarrierMultiplier` signature:
```swift
func updateCarrierMultiplier(_ value: CarrierMultiplier) {
    voiceTemplate.oscillator.carrierMultiplier = value
    markAsModified()
}
```

### 6. Updated PolyphonicVoice (`A2 PolyphonicVoice.swift`)
Added `.rawValue` to extract Double when passing to AudioKit:
- In `init`: `AUValue(parameters.oscillator.carrierMultiplier.rawValue)`
- In `updateOscillatorParameters`: `AUValue(parameters.carrierMultiplier.rawValue)`
- In `recreateOscillators`: carrierMultiplier is already stored as `AUValue` from oscillator

## Musical Rationale

### Subharmonic Values (< 1.0)
Produce pitches **below** the fundamental frequency:
- **1/2**: One octave down
- **1/3**: Perfect twelfth down (octave + fifth)
- **1/4**: Two octaves down
- Useful for creating bass-heavy, warm tones

### Harmonic Values (>= 1.0)
Standard harmonic series:
- **1**: Fundamental (original pitch)
- **2**: One octave up
- **3**: Perfect fifth above octave
- **4-8**: Higher harmonics for bright, metallic tones

## Benefits of This Approach

1. **Exact Values**: No floating-point approximation errors
2. **Musical Correctness**: Only harmonically meaningful ratios are available
3. **Clear UI**: Fractional display (1/4) is more intuitive than decimals (0.25)
4. **Type Safety**: Compiler enforces valid values
5. **Easy to Extend**: Adding new ratios is straightforward
6. **Preset Compatibility**: Old presets automatically migrate to nearest value

## User Experience

- **Slider**: Quick scrubbing through all 15 values with snap-to-detent behavior
- **Buttons**: Precise stepping (useful at edges of range)
- **Display**: Fractional notation for subharmonics, integers for harmonics
- **Predictable**: Each slider position maps to exact, repeatable value

## Testing Notes

When testing, verify:
1. ✅ All 15 values are accessible via slider
2. ✅ Buttons work at range edges (don't crash)
3. ✅ Old presets load correctly (values migrate to nearest case)
4. ✅ New presets save and load with exact enum values
5. ✅ Sound output matches expected harmonic/subharmonic ratios
6. ✅ No audio glitches when changing carrier multiplier
7. ✅ Display shows fractions (1/4) not decimals (0.25)

## Future Enhancements

If needed, could add:
- More exotic ratios (1/9, 1/10 for very low subharmonics)
- Golden ratio (φ ≈ 1.618) for inharmonic tones
- Custom ratio input (advanced users only)
- Separate "harmonic" and "subharmonic" modes for simpler UI
