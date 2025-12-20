# Detune Modes Explained

## Overview
The stereo spread in the polyphonic voice architecture can operate in two distinct modes, each with different sonic characteristics.

---

## Proportional Mode (Constant Cents)

### How It Works
- Oscillators are offset by a **constant ratio** (multiplier/divider)
- Creates **constant cents** detuning across all frequencies
- Higher frequencies have **faster beating** than lower frequencies

### Formula
```swift
leftFreq = baseFrequency × ratio    // e.g., 440 × 1.005 = 442.2 Hz
rightFreq = baseFrequency ÷ ratio   // e.g., 440 ÷ 1.005 = 437.8 Hz
```

### Examples

**Low Note (A2 = 110 Hz):**
- Offset ratio: 1.005
- Left: 110 × 1.005 = 110.55 Hz
- Right: 110 ÷ 1.005 = 109.45 Hz
- Beat rate: 110.55 - 109.45 = **1.1 Hz** (slow beating)

**High Note (A4 = 440 Hz):**
- Offset ratio: 1.005
- Left: 440 × 1.005 = 442.2 Hz
- Right: 440 ÷ 1.005 = 437.8 Hz
- Beat rate: 442.2 - 437.8 = **4.4 Hz** (4× faster beating)

**Even Higher Note (A5 = 880 Hz):**
- Offset ratio: 1.005
- Left: 880 × 1.005 = 884.4 Hz
- Right: 880 ÷ 1.005 = 875.6 Hz
- Beat rate: 884.4 - 875.6 = **8.8 Hz** (8× faster beating)

### Sonic Characteristics
✅ **Natural sounding** - mimics real-world instrument detuning  
✅ **Wide stereo field** - consistent perceived width across range  
✅ **Subtle on bass notes** - less obvious beating in low register  
✅ **More pronounced on treble** - clear chorus effect on high notes  
✅ **Similar to analog chorus** - classic ensemble/chorus effect  

### Best For
- Natural instrument emulation (strings, pads, pianos)
- Vintage analog synth sounds
- Chorus/ensemble effects
- When you want beating to feel "proportional" to pitch

### Recommended Range
- **1.0 to 1.01** (0 to 34 cents total spread)
- Sweet spot: around **1.005** (17 cents total)

---

## Constant Mode (Constant Hz)

### How It Works
- Oscillators are offset by a **fixed Hz amount** (addition/subtraction)
- Creates **constant beat rate** across all frequencies
- All notes have the **same beating speed** regardless of pitch

### Formula
```swift
leftFreq = baseFrequency + offsetHz   // e.g., 440 + 2 = 442 Hz
rightFreq = baseFrequency - offsetHz  // e.g., 440 - 2 = 438 Hz
```

### Examples

**Low Note (A2 = 110 Hz):**
- Offset: 2 Hz
- Left: 110 + 2 = 112 Hz
- Right: 110 - 2 = 108 Hz
- Beat rate: 112 - 108 = **4 Hz** (fixed rate)

**High Note (A4 = 440 Hz):**
- Offset: 2 Hz
- Left: 440 + 2 = 442 Hz
- Right: 440 - 2 = 438 Hz
- Beat rate: 442 - 438 = **4 Hz** (same rate!)

**Even Higher Note (A5 = 880 Hz):**
- Offset: 2 Hz
- Left: 880 + 2 = 882 Hz
- Right: 880 - 2 = 878 Hz
- Beat rate: 882 - 878 = **4 Hz** (still same rate!)

### Sonic Characteristics
✅ **Uniform beating** - predictable rhythm across all notes  
✅ **Mechanical/electronic** - less "organic" than proportional  
✅ **More detuned in bass** - can sound very wide in low register  
✅ **Less detuned in treble** - narrower effect on high notes  
✅ **Interesting for sequences** - consistent modulation rate  

### Best For
- Electronic/synthetic sounds
- Bass sounds with controlled width
- Rhythmic/pulsing effects
- When you want predictable beating regardless of pitch
- Special effects and sound design

### Recommended Range
- **0 to 10 Hz** (0 to 20 Hz beat rate)
- Gentle chorus: **1-3 Hz**
- Obvious beating: **3-5 Hz**
- Vibrato-like: **5-10 Hz**

---

## Technical Comparison

| Aspect | Proportional | Constant |
|--------|-------------|----------|
| **Parameter** | Ratio (1.0-1.01) | Hz (0-10) |
| **Cents detuning** | Constant | Variable (wider on bass) |
| **Beat rate** | Faster on high notes | Same for all notes |
| **Stereo width** | Consistent | Wider on bass, narrower on treble |
| **CPU cost** | Same | Same |
| **Use case** | Natural instruments | Electronic/synthetic |

---

## Perceptual Differences

### Proportional Mode
When you play a scale from low to high:
- **Bass notes:** Subtle warmth, gentle width
- **Mid notes:** Clear stereo spread, moderate beating
- **High notes:** Obvious chorus, fast beating
- **Chords:** Natural, organic detuning

### Constant Mode  
When you play a scale from low to high:
- **Bass notes:** Very wide, obvious detuning
- **Mid notes:** Uniform beating, less relative detune
- **High notes:** Subtle width, tight stereo field
- **Chords:** Unique character, bass notes dominate the beating

---

## Musical Context

### Proportional Mode Examples
🎹 **Analog synth pads** - Classic polysynth detune  
🎸 **String ensembles** - Natural orchestral spacing  
🎹 **Electric pianos** - Rhodes/Wurlitzer-style chorusing  
🎺 **Brass sections** - Realistic ensemble detuning  

### Constant Mode Examples
🎛️ **Bass synthesis** - Controlled low-end width without muddiness  
🎵 **Arpeggios** - Consistent pulse across note changes  
🔊 **Sound design** - Unique character, experimental textures  
📻 **Lo-fi effects** - Intentional "broken radio" aesthetic  

---

## Recommendations

### For This App (Pentatone)
**Proportional mode** is likely the better default because:
- More natural for melodic/harmonic playing
- Consistent perceived stereo width
- Works well across the full key range
- Familiar sound from classic instruments

**However,** constant mode can be useful for:
- Specific presets with electronic character
- Bass-focused sounds where you want controlled low-end
- Experimental/ambient patches
- Per-preset sonic variety (some presets proportional, others constant)

### Preset Ideas
You could assign different modes to different presets:
- **Presets 1-10:** Proportional mode (natural instruments)
- **Presets 11-15:** Constant mode (electronic/synthetic)

Or make it a per-preset parameter that users can adjust.

---

## Testing Checklist

When testing in the preview:

### Proportional Mode
- [ ] Play low, mid, and high notes - notice beating increases with pitch
- [ ] Play chord - sounds natural and organic
- [ ] Adjust slider - stereo width feels proportional
- [ ] Sweet spot around middle of slider range

### Constant Mode
- [ ] Play low, mid, and high notes - notice same beat rate
- [ ] Bass notes have obvious wide character
- [ ] High notes feel tighter/more centered
- [ ] Adjust slider - beat rate is uniform across range

### Comparison
- [ ] Switch modes while holding a chord - hear the difference
- [ ] Test same slider position in both modes on bass note
- [ ] Test same slider position in both modes on treble note
- [ ] Decide which mode feels better for your default sound

---

## Implementation Details

### Voice-Level Implementation
Each `PolyphonicVoice` calculates its frequencies based on mode:

```swift
switch detuneMode {
case .proportional:
    leftFreq = currentFrequency * frequencyOffsetRatio
    rightFreq = currentFrequency / frequencyOffsetRatio
    
case .constant:
    leftFreq = currentFrequency + frequencyOffsetHz
    rightFreq = currentFrequency - frequencyOffsetHz
}
```

### VoicePool Control
The entire voice pool can switch modes simultaneously:

```swift
voicePool.updateDetuneMode(.proportional)  // or .constant
voicePool.updateFrequencyOffsetRatio(1.005)  // for proportional
voicePool.updateFrequencyOffsetHz(2.0)       // for constant
```

### Parameter Persistence
In future phases, detune mode will be part of preset parameters:

```swift
struct VoiceParameters {
    var detuneMode: DetuneMode
    var frequencyOffsetRatio: Double  // for proportional
    var frequencyOffsetHz: Double     // for constant
    // ... other parameters
}
```

---

## Physics & Mathematics

### Beat Frequency Formula
When two frequencies f1 and f2 are played together:
```
Beat Rate = |f1 - f2|
```

### Cents Formula
The musical interval in cents between two frequencies:
```
Cents = 1200 × log2(f1 / f2)
```

### Proportional Mode Math
For a ratio `r`:
- Left: `f × r`
- Right: `f / r`
- Beat rate: `f × r - f / r = f × (r - 1/r)`
- This grows linearly with `f`

### Constant Mode Math
For an offset `h` (Hz):
- Left: `f + h`
- Right: `f - h`
- Beat rate: `(f + h) - (f - h) = 2h`
- This is constant regardless of `f`

---

**Summary:** Both modes are musically useful! Test them both and choose the one that fits your sonic vision. Most classic synthesizers use proportional mode, but constant mode offers unique creative possibilities.
