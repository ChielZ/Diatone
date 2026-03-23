# Preset Restructure Migration Guide

This document describes **all** changes made during the preset system restructure in **Diatone**. Use it as a step-by-step guide to apply the same changes to the other apps that share this audio engine and preset system.

All struct and field names are identical across apps. Minor UI-side differences may exist but don't affect this migration.

---

## Files Modified

| File | Changes |
|------|---------|
| **A1 SoundParameters.swift** | Remove `amplitude` stored property, remove `LegacyEnvelopeParameters`, remove `envelope` bridge, derive `macroState` on load, add `snap()` helper, add custom `encode(to:)` to 11 structs |
| **A2 PolyphonicVoice.swift** | Replace `isEnabled` guards with `hasActiveDestinations`, remove `amountToAuxEnvPitch` meta-modulation |
| **A3 VoicePool.swift** | Replace `isEnabled` guards with `hasActiveDestinations` |
| **A6 ModulationSystem.swift** | Remove `isEnabled` from 8 structs, remove `amountToAuxEnvPitch` from `TouchInitialParameters`, add `snap()` helper, add custom `encode(to:)` to 9 structs |
| **A7 ParameterManager.swift** | Couple volume macro to preVolume, remove `isEnabled` update methods, remove `amountToAuxEnvPitch` update method, remove `updateTemplateEnvelope`, add global mode system |
| **V2 MainKeyboardView.swift** | Use `effectiveGlobalPitch` instead of `master.globalPitch` |
| **V3-S3 VoiceView.swift** | All controls read/write through global-mode-aware API |
| **V4-S07 TouchView.swift** | Use `effectiveModulationForVoices` |
| **P1 PresetManager.swift** | Add filename helpers, update save/delete/export for name+UUID filenames, ensure `.sortedKeys` on all encoders |

---

## Phase 1: Code-side changes (don't break existing presets)

These steps modify runtime behavior but keep backward-compatible Codable. Old presets still load.

### Step 1: Couple volume macro slider to preVolume parameter

**File: A7 ParameterManager.swift**

In `updateVolumeMacro()`, after applying the volume to the audio engine, also sync the master parameter:
```swift
master.output.preVolume = clampedPosition
```

In `updatePreVolume()`, also sync the macro position:
```swift
macroState.volumePosition = preVolume
```

This makes the SoundView macro slider and the GlobalView editor slider share the same underlying value.

---

### Step 2: Remove `isEnabled` flags from all modulation structs

**File: A6 ModulationSystem.swift**

Remove `var isEnabled: Bool` (stored property + default value) from all 8 structs:
- `VoiceLFOParameters`
- `ModulatorEnvelopeParameters`
- `AuxiliaryEnvelopeParameters`
- `LoudnessEnvelopeParameters`
- `KeyTrackingParameters`
- `TouchInitialParameters`
- `TouchAftertouchParameters`
- `GlobalLFOParameters`

Also remove `guard isEnabled else { return 0.0 }` from:
- `VoiceLFOParameters.rawValue(at:)`
- `GlobalLFOParameters.rawValue(at:)`

Each struct already has a computed `hasActiveDestinations` property that checks whether any destination amount is non-zero. This replaces `isEnabled` everywhere.

**File: A3 VoicePool.swift**

Replace all `isEnabled` guards with `hasActiveDestinations`:
- `guard globalLFO.isEnabled` → `guard globalLFO.hasActiveDestinations`
- Remove `guard globalLFO.isEnabled else { return 0.0 }` (raw value already returns 0 when inactive)
- Update debug print statements to use `hasActiveDestinations` terminology

**File: A2 PolyphonicVoice.swift**

Replace `guard voiceModulation.voiceLFO.isEnabled` with `guard voiceModulation.voiceLFO.hasActiveDestinations`

**File: A7 ParameterManager.swift**

Delete these three methods entirely:
- `updateKeyTrackingEnabled(_ enabled: Bool)`
- `updateVoiceLFOEnabled(_ enabled: Bool)`
- `updateGlobalLFOEnabled(_ enabled: Bool)`

**Backward compatibility**: At this point, add temporary `CodingKeys` and custom `init(from decoder:)` to all 8 structs so `isEnabled` is read-and-ignored from old presets. Example:
```swift
enum CodingKeys: String, CodingKey {
    case isEnabled  // Legacy, read but ignored
    case waveform, resetMode, frequency, /* ... other current fields ... */
}

init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    _ = try? c.decode(Bool.self, forKey: .isEnabled) // Silently discard
    waveform = try c.decode(LFOWaveform.self, forKey: .waveform)
    // ... decode remaining fields ...
}
```
Also add explicit memberwise `init(...)` since custom Codable suppresses the synthesized one.

> **Note**: This backward-compatibility code is temporary and will be removed in Phase 2 after all presets are converted.

---

### Step 3: Strip `oscillator.amplitude` from preset serialization

**File: A1 SoundParameters.swift**

In `OscillatorParameters`:
- Remove `var amplitude: Double` stored property
- Replace with computed property: `var amplitude: Double { 0.5 }`
- Add `CodingKeys` that excludes `amplitude`
- Add backward-compatible `init(from decoder:)` that reads-and-discards old `amplitude`
- Add explicit memberwise `init`

---

### Step 4: Make `loudnessEnvelope` canonical, remove `envelope` bridge

**File: A1 SoundParameters.swift**

If your `VoiceParameters` struct has an `envelope` property (old `EnvelopeParameters` type) that was bridged/synced to `modulation.loudnessEnvelope`:

1. Remove the `EnvelopeParameters` struct entirely (or the `LegacyEnvelopeParameters` private struct if already renamed)
2. Remove `var envelope` from `VoiceParameters`
3. Keep a convenience accessor if needed:
```swift
var loudnessEnvelope: LoudnessEnvelopeParameters {
    get { modulation.loudnessEnvelope }
    set { modulation.loudnessEnvelope = newValue }
}
```
4. Add backward-compatible decoder that reads legacy `envelope` and writes it into `modulation.loudnessEnvelope`:
```swift
private struct LegacyEnvelopeParameters: Codable {
    var attackDuration: Double
    var decayDuration: Double
    var sustainLevel: Double
    var releaseDuration: Double
    func toLoudnessEnvelope() -> LoudnessEnvelopeParameters {
        LoudnessEnvelopeParameters(attack: attackDuration, decay: decayDuration,
                                    sustain: sustainLevel, release: releaseDuration)
    }
}

enum CodingKeys: String, CodingKey {
    case oscillator, filter, filterStatic, envelope, modulation
}

init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    oscillator = try c.decode(OscillatorParameters.self, forKey: .oscillator)
    filter = try c.decode(FilterParameters.self, forKey: .filter)
    filterStatic = try c.decode(FilterStaticParameters.self, forKey: .filterStatic)
    var modulation = (try? c.decode(VoiceModulationParameters.self, forKey: .modulation)) ?? .default
    if let legacy = try? c.decode(LegacyEnvelopeParameters.self, forKey: .envelope) {
        modulation.loudnessEnvelope = legacy.toLoudnessEnvelope()
    }
    self.modulation = modulation
}
```

**File: A3 VoicePool.swift** — Remove deprecated `updateAllVoiceEnvelopes(_ parameters: EnvelopeParameters)` method if present.

**File: A7 ParameterManager.swift** — Remove `updateTemplateEnvelope(_ parameters: EnvelopeParameters)` method and any old EnvelopeParameters conversion logic.

---

### Step 5: Derive `macroState` from parameters on load

**File: A1 SoundParameters.swift**

In `AudioParameterSet`:
- Add `macroState` exclusion from CodingKeys (only encode: `id`, `name`, `voiceTemplate`, `master`, `createdAt`)
- Custom decoder derives macroState:
```swift
macroState = MacroControlState(from: voiceTemplate, masterParams: master)
```
- Custom encoder skips macroState entirely

> **Note**: The backward-compatible decoder handles old presets that had `macroState` in JSON — `JSONDecoder` silently ignores unknown keys when CodingKeys doesn't include them.

---

### Step 6: Add global mode for octave/tune/bend range

**File: A7 ParameterManager.swift**

Add a global mode system. When enabled, tempo, octave, fine tune, and bend range persist across preset changes instead of being overwritten by preset data.

Add these published properties:
```swift
@Published var isGlobalMode: Bool = false
@Published var globalTempo: Double = 100.0
@Published var globalOctaveOffset: Int = 0
@Published var globalFineTuneCents: Double = 0.0
@Published var globalBendRange: Double = 2.0
```

Add computed properties that return the effective value based on mode:
```swift
var effectiveTempo: Double {
    isGlobalMode ? globalTempo : master.tempo
}

var effectiveGlobalPitch: GlobalPitchParameters {
    if isGlobalMode {
        var pitch = GlobalPitchParameters.default
        pitch.setOctaveOffset(globalOctaveOffset)
        pitch.setFineTuneCents(globalFineTuneCents)
        // Transpose always comes from preset
        pitch.transpose = master.globalPitch.transpose
        return pitch
    }
    return master.globalPitch
}

var effectiveBendRange: Double {
    isGlobalMode ? globalBendRange : voiceTemplate.modulation.touchAftertouch.amountToOscillatorPitch
}

var effectiveModulationForVoices: VoiceModulationParameters {
    if isGlobalMode {
        var mod = voiceTemplate.modulation
        mod.touchAftertouch.amountToOscillatorPitch = globalBendRange
        return mod
    }
    return voiceTemplate.modulation
}
```

Add update methods: `toggleGlobalMode()`, `updateEffectiveTempo()`, `updateEffectiveOctaveOffset()`, `updateEffectiveFineTuneCents()`, `updateEffectiveBendRange()`.

In `updateTempo()`, add guard: `guard !isGlobalMode else { return }`.

Replace all occurrences of `master.tempo` in tempo-dependent audio calculations (delay time, LFO frequency, sync value) with `effectiveTempo`.

In `applyVoiceParameters()`, change `voicePool?.updateAllVoiceModulation(voiceParams.modulation)` to `voicePool?.updateAllVoiceModulation(effectiveModulationForVoices)`.

**File: V2 MainKeyboardView.swift**

Change `AudioParameterManager.shared.master.globalPitch` to `AudioParameterManager.shared.effectiveGlobalPitch` in pitch calculation.

**File: V3-S3 VoiceView.swift**

Update all tempo, octave, fine tune, and bend range controls to:
- Read from global-mode-aware source (`effectiveTempo`, etc.)
- Write through global-mode-aware update methods (`updateEffectiveTempo()`, etc.)
- Display mode label: `paramManager.isGlobalMode ? "Global" : "Per Sound"`

**File: V4-S07 TouchView.swift**

Change `paramManager.voiceTemplate.modulation` to `paramManager.effectiveModulationForVoices` in `applyModulationToAllVoices()`.

---

### Step 7: Remove `touchInitial.amountToAuxEnvPitch` parameter

**File: A6 ModulationSystem.swift**

In `TouchInitialParameters`:
- Remove `var amountToAuxEnvPitch: Double` and its default value
- Update `hasActiveDestinations` to exclude it
- CodingKeys: exclude it (add to backward-compat decoder to read-and-discard from old presets)

**File: A2 PolyphonicVoice.swift**

In filter frequency modulation and pitch modulation, remove the initial-touch meta-modulation blocks that computed `effectiveAuxEnvPitchAmount` using `touchInitial.amountToAuxEnvPitch`. Replace with direct use of `auxiliaryEnvelope.amountToOscillatorPitch` and `auxiliaryEnvelope.amountToFilterFrequency` respectively.

Remove `let hasInitialTouchToPitch = voiceModulation.touchInitial.amountToAuxEnvPitch != 0.0` and any guard conditions that used it.

**File: A7 ParameterManager.swift**

- Delete `updateInitialTouchAmountToAuxEnvPitch(_ value: Double)` method
- Remove call to it from the randomize function

---

## Phase 2: Preset file restructure

These steps change how presets are serialized. After this phase, all presets need to be re-converted.

### Step 8: Add value snapping and custom encoders

#### 8a. Add snap() helper function

Add this `private` function near the top of **both** A1 SoundParameters.swift and A6 ModulationSystem.swift (after imports, before any struct/enum definitions):

```swift
// MARK: - Encoding Helpers

/// Snap a value to the nearest step size for clean preset storage
/// Includes a final rounding pass to eliminate floating-point representation artifacts
private func snap(_ value: Double, to step: Double) -> Double {
    let snapped = (value / step).rounded() * step
    // Determine decimal places from step size to eliminate artifacts like 5.050000000000001
    let decimals = -log10(step).rounded(.up)
    let factor = pow(10.0, max(decimals, 0))
    return (snapped * factor).rounded() / factor
}
```

The two-pass approach is needed because plain `(value / step).rounded() * step` can produce artifacts like `5.050000000000001` due to binary floating-point representation. The second pass uses `log10` to determine how many decimal places the step size implies and rounds to that precision.

#### 8b. A1 SoundParameters.swift — Add/update encode(to:) on 11 structs

For each struct, add a `CodingKeys` enum (if not already present) and a custom `encode(to:)` method:

**OscillatorParameters:**
```swift
enum CodingKeys: String, CodingKey {
    case carrierMultiplier, modulatingMultiplier, modulationIndex
    case waveform, detuneMode, stereoOffsetProportional, stereoOffsetConstant
}

func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(waveform, forKey: .waveform)
    try c.encode(carrierMultiplier, forKey: .carrierMultiplier)
    let coarse = floor(modulatingMultiplier)
    let fine = snap(modulatingMultiplier - coarse, to: 0.001)
    try c.encode(coarse + fine, forKey: .modulatingMultiplier)
    try c.encode(snap(modulationIndex, to: 0.05), forKey: .modulationIndex)
    try c.encode(detuneMode, forKey: .detuneMode)
    try c.encode(snap(stereoOffsetConstant, to: 0.01), forKey: .stereoOffsetConstant)
    try c.encode(snap(stereoOffsetProportional, to: 0.05), forKey: .stereoOffsetProportional)
}
```

**FilterParameters:**
```swift
enum CodingKeys: String, CodingKey { case cutoffFrequency }
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(snap(cutoffFrequency, to: 1.0), forKey: .cutoffFrequency)
}
```

**FilterStaticParameters:**
```swift
enum CodingKeys: String, CodingKey { case resonance, saturation }
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(snap(resonance, to: 0.02), forKey: .resonance)
    try c.encode(snap(saturation, to: 0.02), forKey: .saturation)
}
```

**VoiceParameters:**
```swift
enum CodingKeys: String, CodingKey {
    case oscillator, filter, filterStatic, modulation
}
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(oscillator, forKey: .oscillator)
    try c.encode(filter, forKey: .filter)
    try c.encode(filterStatic, forKey: .filterStatic)
    try c.encode(modulation, forKey: .modulation)
}
```

**DelayParameters:**
```swift
enum CodingKeys: String, CodingKey { case timeValue, feedback, toneCutoff, dryWetMix }
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(timeValue, forKey: .timeValue)
    try c.encode(snap(feedback, to: 0.01), forKey: .feedback)
    try c.encode(snap(toneCutoff, to: 100.0), forKey: .toneCutoff)
    try c.encode(snap(dryWetMix, to: 0.005), forKey: .dryWetMix)
}
```

**ReverbParameters:**
```swift
enum CodingKeys: String, CodingKey { case feedback, cutoffFrequency, balance }
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(snap(feedback, to: 0.005), forKey: .feedback)
    try c.encode(snap(cutoffFrequency, to: 100.0), forKey: .cutoffFrequency)
    try c.encode(snap(balance, to: 0.005), forKey: .balance)
}
```

**OutputParameters:**
```swift
enum CodingKeys: String, CodingKey { case preVolume, volume }
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(snap(preVolume, to: 0.01), forKey: .preVolume)
    try c.encode(snap(volume, to: 0.01), forKey: .volume)
}
```

**GlobalPitchParameters** (no snapping — computed from integer offsets):
```swift
enum CodingKeys: String, CodingKey { case octave, transpose, fineTune }
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(octave, forKey: .octave)
    try c.encode(transpose, forKey: .transpose)
    try c.encode(fineTune, forKey: .fineTune)
}
```

**MacroControlParameters:**
```swift
enum CodingKeys: String, CodingKey {
    case toneToModulationIndexRange, toneToFilterCutoffOctaves, toneToFilterSaturationRange
    case ambienceToDelayFeedbackRange, ambienceToDelayMixRange
    case ambienceToReverbFeedbackRange, ambienceToReverbMixRange
}
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(snap(toneToModulationIndexRange, to: 0.05), forKey: .toneToModulationIndexRange)
    try c.encode(snap(toneToFilterCutoffOctaves, to: 0.01), forKey: .toneToFilterCutoffOctaves)
    try c.encode(snap(toneToFilterSaturationRange, to: 0.02), forKey: .toneToFilterSaturationRange)
    try c.encode(snap(ambienceToDelayFeedbackRange, to: 0.01), forKey: .ambienceToDelayFeedbackRange)
    try c.encode(snap(ambienceToDelayMixRange, to: 0.01), forKey: .ambienceToDelayMixRange)
    try c.encode(snap(ambienceToReverbFeedbackRange, to: 0.01), forKey: .ambienceToReverbFeedbackRange)
    try c.encode(snap(ambienceToReverbMixRange, to: 0.01), forKey: .ambienceToReverbMixRange)
}
```

**MasterParameters:**
```swift
enum CodingKeys: String, CodingKey {
    case tempo, voiceMode, globalPitch, globalLFO, delay, reverb, output, macroControl
}
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(snap(tempo, to: 1.0), forKey: .tempo)
    try c.encode(voiceMode, forKey: .voiceMode)
    try c.encode(globalPitch, forKey: .globalPitch)
    try c.encode(globalLFO, forKey: .globalLFO)
    try c.encode(delay, forKey: .delay)
    try c.encode(reverb, forKey: .reverb)
    try c.encode(output, forKey: .output)
    try c.encode(macroControl, forKey: .macroControl)
}
```

**AudioParameterSet:**
```swift
enum CodingKeys: String, CodingKey {
    case id, name, voiceTemplate, master, createdAt
}
init(id: UUID, name: String, voiceTemplate: VoiceParameters, master: MasterParameters,
     macroState: MacroControlState, createdAt: Date) {
    self.id = id; self.name = name; self.voiceTemplate = voiceTemplate
    self.master = master; self.macroState = macroState; self.createdAt = createdAt
}
init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(UUID.self, forKey: .id)
    name = try c.decode(String.self, forKey: .name)
    voiceTemplate = try c.decode(VoiceParameters.self, forKey: .voiceTemplate)
    master = try c.decode(MasterParameters.self, forKey: .master)
    createdAt = try c.decode(Date.self, forKey: .createdAt)
    macroState = MacroControlState(from: voiceTemplate, masterParams: master)
}
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(createdAt, forKey: .createdAt)
    try c.encode(id, forKey: .id)
    try c.encode(name, forKey: .name)
    try c.encode(voiceTemplate, forKey: .voiceTemplate)
    try c.encode(master, forKey: .master)
}
```

#### 8c. A6 ModulationSystem.swift — Add/update encode(to:) on 9 structs

**VoiceLFOParameters:**
```swift
enum CodingKeys: String, CodingKey {
    case waveform, resetMode, frequency
    case amountToOscillatorPitch, amountToFilterFrequency, amountToModulatorLevel
    case delayTime
}
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(waveform, forKey: .waveform)
    try c.encode(resetMode, forKey: .resetMode)
    try c.encode(snap(frequency, to: 0.01), forKey: .frequency)
    try c.encode(snap(delayTime, to: 0.01), forKey: .delayTime)
    try c.encode(snap(amountToOscillatorPitch, to: 0.025), forKey: .amountToOscillatorPitch)
    try c.encode(snap(amountToFilterFrequency, to: 0.05), forKey: .amountToFilterFrequency)
    try c.encode(snap(amountToModulatorLevel, to: 0.05), forKey: .amountToModulatorLevel)
}
```

**ModulatorEnvelopeParameters:**
```swift
enum CodingKeys: String, CodingKey {
    case attack, decay, sustain, release, amountToModulationIndex
}
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(snap(attack, to: 0.001), forKey: .attack)
    try c.encode(snap(decay, to: 0.01), forKey: .decay)
    try c.encode(snap(sustain, to: 0.01), forKey: .sustain)
    try c.encode(snap(release, to: 0.01), forKey: .release)
    try c.encode(snap(amountToModulationIndex, to: 0.05), forKey: .amountToModulationIndex)
}
```

**AuxiliaryEnvelopeParameters:**
```swift
enum CodingKeys: String, CodingKey {
    case attack, decay, sustain, release
    case amountToOscillatorPitch, amountToFilterFrequency, amountToVibrato
}
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(snap(attack, to: 0.001), forKey: .attack)
    try c.encode(snap(decay, to: 0.01), forKey: .decay)
    try c.encode(snap(sustain, to: 0.01), forKey: .sustain)
    try c.encode(snap(release, to: 0.01), forKey: .release)
    try c.encode(snap(amountToOscillatorPitch, to: 0.1), forKey: .amountToOscillatorPitch)
    try c.encode(snap(amountToFilterFrequency, to: 0.05), forKey: .amountToFilterFrequency)
    try c.encode(snap(amountToVibrato, to: 0.02), forKey: .amountToVibrato)
}
```

**LoudnessEnvelopeParameters:**
```swift
enum CodingKeys: String, CodingKey { case attack, decay, sustain, release }
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(snap(attack, to: 0.001), forKey: .attack)
    try c.encode(snap(decay, to: 0.01), forKey: .decay)
    try c.encode(snap(sustain, to: 0.01), forKey: .sustain)
    try c.encode(snap(release, to: 0.01), forKey: .release)
}
```

**KeyTrackingParameters:**
```swift
enum CodingKeys: String, CodingKey { case amountToFilterFrequency, amountToVoiceLFOFrequency }
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(snap(amountToFilterFrequency, to: 0.01), forKey: .amountToFilterFrequency)
    try c.encode(snap(amountToVoiceLFOFrequency, to: 0.01), forKey: .amountToVoiceLFOFrequency)
}
```

**TouchInitialParameters:**
```swift
enum CodingKeys: String, CodingKey {
    case amountToOscillatorAmplitude, amountToModEnvelope, amountToAuxEnvCutoff
}
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(snap(amountToOscillatorAmplitude, to: 0.01), forKey: .amountToOscillatorAmplitude)
    try c.encode(snap(amountToModEnvelope, to: 0.02), forKey: .amountToModEnvelope)
    try c.encode(snap(amountToAuxEnvCutoff, to: 0.02), forKey: .amountToAuxEnvCutoff)
}
```

**TouchAftertouchParameters:**
```swift
enum CodingKeys: String, CodingKey {
    case amountToOscillatorPitch, amountToFilterFrequency
    case amountToModulatorLevel, amountToVibrato
}
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(snap(amountToModulatorLevel, to: 0.05), forKey: .amountToModulatorLevel)
    try c.encode(snap(amountToFilterFrequency, to: 0.01), forKey: .amountToFilterFrequency)
    try c.encode(snap(amountToOscillatorPitch, to: 1.0), forKey: .amountToOscillatorPitch)
    try c.encode(snap(amountToVibrato, to: 0.02), forKey: .amountToVibrato)
}
```

**VoiceModulationParameters:**
```swift
enum CodingKeys: String, CodingKey {
    case loudnessEnvelope, modulatorEnvelope, auxiliaryEnvelope
    case voiceLFO, keyTracking, touchInitial, touchAftertouch
}
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(loudnessEnvelope, forKey: .loudnessEnvelope)
    try c.encode(modulatorEnvelope, forKey: .modulatorEnvelope)
    try c.encode(auxiliaryEnvelope, forKey: .auxiliaryEnvelope)
    try c.encode(voiceLFO, forKey: .voiceLFO)
    try c.encode(keyTracking, forKey: .keyTracking)
    try c.encode(touchInitial, forKey: .touchInitial)
    try c.encode(touchAftertouch, forKey: .touchAftertouch)
}
```

**GlobalLFOParameters:**
```swift
enum CodingKeys: String, CodingKey {
    case waveform, resetMode, frequencyMode, frequency, syncValue
    case amountToVoiceMixerVolume, amountToModulatorMultiplier
    case amountToFilterFrequency, amountToDelayTime
}
func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(waveform, forKey: .waveform)
    try c.encode(resetMode, forKey: .resetMode)
    try c.encode(frequencyMode, forKey: .frequencyMode)
    try c.encode(snap(frequency, to: 0.01), forKey: .frequency)
    try c.encode(syncValue, forKey: .syncValue)
    try c.encode(snap(amountToVoiceMixerVolume, to: 0.01), forKey: .amountToVoiceMixerVolume)
    try c.encode(snap(amountToModulatorMultiplier, to: 0.02), forKey: .amountToModulatorMultiplier)
    try c.encode(snap(amountToFilterFrequency, to: 0.01), forKey: .amountToFilterFrequency)
    try c.encode(snap(amountToDelayTime, to: 0.001), forKey: .amountToDelayTime)
}
```

#### 8d. P1 PresetManager.swift — Encoder configuration

All `JSONEncoder` instances (savePreset, exportPreset, saveUserLayout) should use:
```swift
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
encoder.dateEncodingStrategy = .iso8601
```
`.sortedKeys` ensures deterministic alphabetical key ordering. (Custom `encode(to:)` methods do NOT reliably control field order in Swift's JSONEncoder.)

---

### Step 9: Improved naming convention for user preset files

**File: P1 PresetManager.swift**

Add filename helpers:
```swift
// MARK: - Filename Helpers

private func userPresetFilename(name: String, id: UUID) -> String {
    let sanitized = name
        .replacingOccurrences(of: "/", with: "-")
        .replacingOccurrences(of: ":", with: "-")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    let safeName = sanitized.isEmpty ? "Untitled" : sanitized
    return "\(safeName)-\(id.uuidString).json"
}

private func existingFileURL(forPresetID id: UUID) -> URL? {
    let suffix = "-\(id.uuidString).json"
    let legacyName = "\(id.uuidString).json"
    guard let files = try? fileManager.contentsOfDirectory(atPath: userPresetsURL.path) else {
        return nil
    }
    if let match = files.first(where: { $0.hasSuffix(suffix) || $0 == legacyName }) {
        return userPresetsURL.appendingPathComponent(match)
    }
    return nil
}
```

Update `savePreset()` — before writing, remove old file:
```swift
if let oldURL = existingFileURL(forPresetID: preset.id) {
    try? fileManager.removeItem(at: oldURL)
}
let filename = userPresetFilename(name: preset.name, id: preset.id)
let fileURL = userPresetsURL.appendingPathComponent(filename)
try data.write(to: fileURL)
```

Update `deletePreset()` — use UUID-based lookup:
```swift
if let fileURL = existingFileURL(forPresetID: preset.id) {
    try fileManager.removeItem(at: fileURL)
}
```

Update `exportPreset()` — name+UUID filename:
```swift
let sanitized = preset.name
    .replacingOccurrences(of: "/", with: "-")
    .replacingOccurrences(of: ":", with: "-")
    .trimmingCharacters(in: .whitespacesAndNewlines)
let safeName = sanitized.isEmpty ? "Untitled" : sanitized
let filename = "\(safeName)-\(preset.id.uuidString).arithmophonepreset"
```

---

### Step 10: Re-convert all presets

After all code changes, re-encode every factory and user preset. Use `ExecuteSnippet` or a temporary script:

```swift
import Foundation

let factoryPath = "<path-to-project>/Resources/Presets/Factory"
let userPath = "<path-to-project>/Resources/Presets/UserPresets"
let fm = FileManager.default
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
encoder.dateEncodingStrategy = .iso8601

// Convert factory presets
for file in try! fm.contentsOfDirectory(atPath: factoryPath).filter({ $0.hasSuffix(".arithmophonepreset") }) {
    let url = URL(fileURLWithPath: factoryPath).appendingPathComponent(file)
    let preset = try! decoder.decode(AudioParameterSet.self, from: Data(contentsOf: url))
    try! encoder.encode(preset).write(to: url)
    print("Converted: \(file)")
}

// Convert user presets (skip UserLayout.json)
for file in try! fm.contentsOfDirectory(atPath: userPath).filter({ $0.hasSuffix(".json") && $0 != "UserLayout.json" }) {
    let url = URL(fileURLWithPath: userPath).appendingPathComponent(file)
    let preset = try! decoder.decode(AudioParameterSet.self, from: Data(contentsOf: url))
    let reEncoded = try! encoder.encode(preset)
    let sanitized = preset.name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-").trimmingCharacters(in: .whitespacesAndNewlines)
    let safeName = sanitized.isEmpty ? "Untitled" : sanitized
    let newURL = URL(fileURLWithPath: userPath).appendingPathComponent("\(safeName)-\(preset.id.uuidString).json")
    try! reEncoded.write(to: newURL)
    if url != newURL { try? fm.removeItem(at: url) }
    print("Converted: \(file) -> \(newURL.lastPathComponent)")
}
```

---

### Step 11: Remove all backward-compatibility code

Now that all presets are converted, strip the temporary backward-compat Codable code added in Phase 1.

**File: A6 ModulationSystem.swift** — For all 8 modulation structs:
- Remove `isEnabled` from CodingKeys
- Remove custom `init(from decoder:)` (the synthesized one works now)
- Remove explicit memberwise `init(...)` (no longer needed without custom decoder)
- Keep custom `encode(to:)` (needed for snapping)
- For `TouchInitialParameters`: also remove `amountToAuxEnvPitch` from CodingKeys

**File: A1 SoundParameters.swift**:
- `OscillatorParameters`: Remove `amplitude` from CodingKeys, remove custom `init(from:)`, remove memberwise `init`
- `VoiceParameters`: Remove `LegacyEnvelopeParameters` struct, remove `envelope` from CodingKeys, remove custom `init(from:)`, remove memberwise `init`
- `AudioParameterSet`: Remove `macroState` from CodingKeys (keep custom decoder that derives it, keep memberwise init)

---

## Verification

After completing all steps:

1. **Build succeeds** — no compiler errors
2. **Load a preset** — sounds identical to before
3. **Save a preset** — verify no floating-point artifacts in JSON (e.g. `0.5` not `0.49999999`)
4. **Round-trip test** — decode every preset, re-encode, decode again — all succeed
5. **Test on device** — old presets with legacy fields (`isEnabled`, `envelope`, `amplitude`, `macroState`) still load (JSONDecoder silently ignores unknown keys)
6. **Global mode** — toggle on, change octave/tempo, switch presets, verify values persist

---

## Snap Value Reference

| Struct | Field | Step |
|--------|-------|------|
| **OscillatorParameters** | modulatingMultiplier (fine) | 0.001 |
| | modulationIndex | 0.05 |
| | stereoOffsetProportional | 0.05 |
| | stereoOffsetConstant | 0.01 |
| **FilterParameters** | cutoffFrequency | 1.0 |
| **FilterStaticParameters** | resonance, saturation | 0.02 |
| **LoudnessEnvelopeParameters** | attack | 0.001 |
| | decay, sustain, release | 0.01 |
| **ModulatorEnvelopeParameters** | attack | 0.001 |
| | decay, sustain, release | 0.01 |
| | amountToModulationIndex | 0.05 |
| **AuxiliaryEnvelopeParameters** | attack | 0.001 |
| | decay, sustain, release | 0.01 |
| | amountToOscillatorPitch | 0.1 |
| | amountToFilterFrequency | 0.05 |
| | amountToVibrato | 0.02 |
| **VoiceLFOParameters** | frequency, delayTime | 0.01 |
| | amountToOscillatorPitch | 0.025 |
| | amountToFilterFrequency, amountToModulatorLevel | 0.05 |
| **KeyTrackingParameters** | both fields | 0.01 |
| **TouchInitialParameters** | amountToOscillatorAmplitude | 0.01 |
| | amountToModEnvelope, amountToAuxEnvCutoff | 0.02 |
| **TouchAftertouchParameters** | amountToModulatorLevel | 0.05 |
| | amountToFilterFrequency | 0.01 |
| | amountToOscillatorPitch | 1.0 |
| | amountToVibrato | 0.02 |
| **GlobalLFOParameters** | frequency | 0.01 |
| | amountToVoiceMixerVolume, amountToFilterFrequency | 0.01 |
| | amountToModulatorMultiplier | 0.02 |
| | amountToDelayTime | 0.001 |
| **DelayParameters** | feedback | 0.01 |
| | toneCutoff | 100.0 |
| | dryWetMix | 0.005 |
| **ReverbParameters** | feedback, balance | 0.005 |
| | cutoffFrequency | 100.0 |
| **OutputParameters** | preVolume, volume | 0.01 |
| **MacroControlParameters** | toneToModulationIndexRange | 0.05 |
| | toneToFilterCutoffOctaves | 0.01 |
| | toneToFilterSaturationRange | 0.02 |
| | all ambience ranges | 0.01 |
| **MasterParameters** | tempo | 1.0 |
| **GlobalPitchParameters** | *(no snapping)* | — |

---

## Legacy Fields Reference

These fields existed in older presets and are silently ignored by `JSONDecoder`:

| Struct | Legacy Field | Was |
|--------|-------------|-----|
| OscillatorParameters | `amplitude` | Stored property, now computed (`0.5`) |
| VoiceParameters | `envelope` | Old ADSR before modulation system |
| AudioParameterSet | `macroState` | Was serialized, now derived on load |
| All 8 modulation structs | `isEnabled` | Per-module on/off flag |
| TouchInitialParameters | `amountToAuxEnvPitch` | Renamed to `amountToAuxEnvCutoff` |
