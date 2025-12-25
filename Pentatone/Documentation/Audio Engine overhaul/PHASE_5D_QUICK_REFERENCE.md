# Touch & Key Tracking - Quick Reference

## Modulation Sources

| Source | Type | Range | Description |
|--------|------|-------|-------------|
| **Touch Initial** | Unipolar | 0.0 - 1.0 | Initial touch X position (0=inner, 1=outer) |
| **Touch Aftertouch** | Bipolar | -1.0 - +1.0 | X movement from initial position |
| **Key Tracking** | Unipolar | 0.0 - 1.0 | Note frequency (0=low, 1=high, 0.5=A4) |

## Available Destinations (Voice-Level)

| Destination | Parameter | Typical Range | Effect |
|-------------|-----------|---------------|--------|
| `.oscillatorAmplitude` | Volume | 0.0 - 1.0 | Amplitude control, velocity sensitivity |
| `.oscillatorBaseFrequency` | Pitch | Any frequency | Vibrato, pitch bends, pitch envelope |
| `.modulationIndex` | FM Depth | 0.0 - 10.0 | Timbral brightness, FM intensity |
| `.modulatingMultiplier` | FM Ratio | 0.1 - 20.0 | Harmonic content, FM character |
| `.filterCutoff` | Filter Brightness | 20 - 22050 Hz | Filter sweeps, key tracking |
| `.stereoSpreadAmount` | Stereo Width | Varies by mode | Dynamic stereo image |
| `.voiceLFOFrequency` | LFO Rate | 0.01 - 10 Hz | Meta-modulation |
| `.voiceLFOAmount` | LFO Depth | 0.0 - 1.0 | Meta-modulation |

## Configuration Examples

### Example 1: Classic Velocity + Filter Aftertouch (Default Behavior)

```swift
// Initial touch controls volume (velocity)
touchInitial: TouchInitialParameters(
    destination: .oscillatorAmplitude,
    amount: 1.0,         // Full velocity range (0.0 to 1.0)
    isEnabled: true
)

// Aftertouch controls filter brightness
touchAftertouch: TouchAftertouchParameters(
    destination: .filterCutoff,
    amount: 1.0,         // Full filter sweep
    isEnabled: true
)
```

**Behavior:** Touch outer edge = loud, move finger right = brighter filter

---

### Example 2: FM Expression Setup

```swift
// Initial touch controls FM intensity
touchInitial: TouchInitialParameters(
    destination: .modulationIndex,
    amount: 5.0,         // 0-5 FM range (bright when touched on outer edge)
    isEnabled: true
)

// Aftertouch shifts FM harmonics
touchAftertouch: TouchAftertouchParameters(
    destination: .modulatingMultiplier,
    amount: 2.0,         // ±2 ratio units
    isEnabled: true
)
```

**Behavior:** Touch outer edge = bright FM, move finger = harmonic shifts

---

### Example 3: Filter Key Tracking

```swift
// Note frequency controls filter cutoff
keyTracking: KeyTrackingParameters(
    destination: .filterCutoff,
    amount: 2.0,         // Higher notes are 2 octaves brighter
    isEnabled: true
)

// Initial touch still controls volume
touchInitial: TouchInitialParameters(
    destination: .oscillatorAmplitude,
    amount: 1.0,
    isEnabled: true
)
```

**Behavior:** High notes automatically have brighter filter, touch controls volume

---

### Example 4: Amplitude Key Balancing

```swift
// Higher notes are quieter (natural balance)
keyTracking: KeyTrackingParameters(
    destination: .oscillatorAmplitude,
    amount: -0.3,        // Negative amount: higher = quieter
    isEnabled: true
)
```

**Behavior:** Low notes are louder, high notes are quieter

---

### Example 5: Complex Expression

```swift
// Touch position controls filter brightness
touchInitial: TouchInitialParameters(
    destination: .filterCutoff,
    amount: 2.0,         // ±2 octaves from base
    isEnabled: true
)

// Aftertouch controls FM modulation (timbral expression)
touchAftertouch: TouchAftertouchParameters(
    destination: .modulationIndex,
    amount: 5.0,         // Wide FM range
    isEnabled: true
)

// Higher notes have brighter filter automatically
keyTracking: KeyTrackingParameters(
    destination: .filterCutoff,
    amount: 1.0,         // +1 octave per frequency range
    isEnabled: true
)
```

**Behavior:** Touch = filter brightness, aftertouch = FM brightness, automatic key tracking

---

### Example 6: Meta-Modulation (LFO Control)

```swift
// Voice LFO adds vibrato to pitch
voiceLFO: LFOParameters(
    waveform: .sine,
    frequency: 5.0,
    destination: .oscillatorBaseFrequency,
    amount: 0.1,
    isEnabled: true
)

// Aftertouch controls vibrato depth
touchAftertouch: TouchAftertouchParameters(
    destination: .voiceLFOAmount,    // Modulate the LFO itself!
    amount: 0.5,
    isEnabled: true
)
```

**Behavior:** Automatic vibrato, move finger right = more vibrato, left = less vibrato

---

## Amount Parameter Guide

### Touch Initial (Unipolar)

- **Positive amount** → Touch outer edge increases parameter
- **Negative amount** → Touch outer edge decreases parameter (inverted)
- **Amount = 1.0** → Full range modulation
- **Amount = 0.5** → Half range modulation

### Touch Aftertouch (Bipolar)

- **Amount** controls sensitivity
- Move right → Adds to base value
- Move left → Subtracts from base value
- **Amount = 1.0** → Standard sensitivity
- **Amount = 2.0** → Double sensitivity (more expressive)

### Key Tracking (Unipolar)

- **Positive amount** → Higher notes increase parameter
- **Negative amount** → Higher notes decrease parameter
- **Amount = 1.0** → Standard key tracking
- **Amount = 2.0** → Aggressive key tracking (±2 octaves filter sweep)

## Tips

### Avoiding Conflicts

⚠️ **Don't route multiple modulators to the same destination** - only the last one will be heard.

Good:
```swift
voiceLFO.destination = .filterCutoff
touchInitial.destination = .oscillatorAmplitude     // Different destination
touchAftertouch.destination = .modulationIndex      // Different destination
```

Bad:
```swift
voiceLFO.destination = .oscillatorAmplitude
touchInitial.destination = .oscillatorAmplitude     // Conflict! Touch wins
```

### Sensitivity Tuning

Start with `amount = 1.0` and adjust:
- Too subtle? Increase amount (e.g., 2.0)
- Too extreme? Decrease amount (e.g., 0.5)
- Inverted response? Use negative amount

### Hardwired vs Routable

**Hardwired (always active):**
- Initial touch X → Sets `baseAmplitude`
- Aftertouch X → Updates `baseFilterCutoff` (with smoothing)

**Routable (when enabled):**
- Reads touch positions from `ModulationState`
- Routes to configured destination
- Applied after hardwired control (last wins)

For clean behavior, use routable modulation OR hardwired, not both.

## Modulation Flow Diagram

```
1. Touch Key → Store in ModulationState
                │
                ├─→ initialTouchX (0.0-1.0)
                ├─→ currentTouchX (0.0-1.0)
                └─→ currentFrequency (Hz)

2. Modulation System (200 Hz) → Apply Modulators
                │
                ├─→ Touch Initial → Route to destination
                ├─→ Touch Aftertouch → Route to destination
                └─→ Key Tracking → Route to destination

3. Audio Parameters Updated → Sound changes
```

## Next Steps

1. **Experiment** - Try different destination combinations
2. **Test touch response** - Verify hardwired behavior still works
3. **Create presets** - Save favorite modulation routings (Phase 6)
4. **Build UI** - Design parameter editing screens (Phase 7+)
