# Loudness Envelope Migration Guide

## Overview

This guide explains how to migrate existing code from the old `AmplitudeEnvelope` node approach to the new `Fader`-based loudness envelope system.

## Files Modified

### Core Files
- ✅ `A6 ModulationSystem.swift` - Added loudness envelope parameters and calculation
- ✅ `A2 PolyphonicVoice.swift` - Replaced AmplitudeEnvelope with Fader
- ⚠️ `A1 SoundParameters.swift` - **Needs update** (see below)
- ⚠️ `VoicePool` - **May need updates** for voice creation
- ⚠️ `ParameterManager` or similar - **May need updates** for parameter routing

## Required Changes to A1 SoundParameters.swift

### Option 1: Remove EnvelopeParameters (Recommended)

Since loudness envelope is now part of the modulation system, we can remove the old `EnvelopeParameters` struct:

```swift
/// Combined parameters for a single voice
struct VoiceParameters: Codable, Equatable {
    var oscillator: OscillatorParameters
    var filter: FilterParameters                   
    var filterStatic: FilterStaticParameters       
    // REMOVED: var envelope: EnvelopeParameters
    var modulation: VoiceModulationParameters      // Now includes loudnessEnvelope
    
    static let `default` = VoiceParameters(
        oscillator: .default,
        filter: .default,
        filterStatic: .default,
        // REMOVED: envelope: .default,
        modulation: .default  // Includes loudnessEnvelope
    )
}
```

### Option 2: Keep EnvelopeParameters for Backward Compatibility

If you need to support loading old presets, keep `EnvelopeParameters` but mark it as deprecated:

```swift
/// Parameters for the amplitude envelope
/// ⚠️ DEPRECATED: Use voiceModulation.loudnessEnvelope instead
@available(*, deprecated, message: "Use voiceModulation.loudnessEnvelope instead")
struct EnvelopeParameters: Codable, Equatable {
    var attackDuration: Double
    var decayDuration: Double
    var sustainLevel: Double
    var releaseDuration: Double
    
    static let `default` = EnvelopeParameters(
        attackDuration: 0.005,
        decayDuration: 0.5,
        sustainLevel: 1.0,
        releaseDuration: 0.1
    )
    
    /// Convert to new LoudnessEnvelopeParameters
    func toLoudnessEnvelope() -> LoudnessEnvelopeParameters {
        return LoudnessEnvelopeParameters(
            attack: attackDuration,
            decay: decayDuration,
            sustain: sustainLevel,
            release: releaseDuration,
            isEnabled: true
        )
    }
}
```

Then add a migration helper to `AudioParameterSet`:

```swift
extension AudioParameterSet {
    /// Migrate old envelope parameters to new loudness envelope
    mutating func migrateEnvelopeToLoudness() {
        if let oldEnvelope = voiceTemplate.envelope {  // If envelope still exists
            voiceTemplate.modulation.loudnessEnvelope = oldEnvelope.toLoudnessEnvelope()
        }
    }
}
```

## Required Changes to VoicePool

### Voice Initialization

Update voice creation to use the new fader instead of envelope:

```swift
// OLD:
func createVoice() -> PolyphonicVoice {
    let voice = PolyphonicVoice(parameters: voiceTemplate)
    voice.envelope.attackDuration = voiceTemplate.envelope.attackDuration
    // ... etc
    return voice
}

// NEW:
func createVoice() -> PolyphonicVoice {
    let voice = PolyphonicVoice(parameters: voiceTemplate)
    // No need to set envelope parameters - they're in modulation system
    return voice
}
```

### Voice Output Connection

The output node has changed:

```swift
// OLD:
let voiceMixer = Mixer()
for voice in voices {
    voiceMixer.addInput(voice.envelope)  // ❌ Old way
}

// NEW:
let voiceMixer = Mixer()
for voice in voices {
    voiceMixer.addInput(voice.fader)  // ✅ New way
}
```

## Required Changes to Parameter Update Methods

### Updating Envelope Parameters

Replace calls to `updateEnvelopeParameters()`:

```swift
// OLD:
func updateVoiceEnvelopes() {
    for voice in voices {
        voice.updateEnvelopeParameters(currentTemplate.envelope)
    }
}

// NEW:
func updateVoiceEnvelopes() {
    for voice in voices {
        voice.updateLoudnessEnvelopeParameters(currentTemplate.modulation.loudnessEnvelope)
        // OR, update entire modulation system:
        voice.updateModulationParameters(currentTemplate.modulation)
    }
}
```

### Parameter Change Broadcasts

Update any code that broadcasts envelope parameter changes:

```swift
// OLD:
func setEnvelopeAttack(_ value: Double) {
    currentTemplate.envelope.attackDuration = value
    for voice in voices {
        voice.envelope.attackDuration = AUValue(value)
    }
}

// NEW:
func setEnvelopeAttack(_ value: Double) {
    currentTemplate.modulation.loudnessEnvelope.attack = value
    for voice in voices {
        voice.updateLoudnessEnvelopeParameters(currentTemplate.modulation.loudnessEnvelope)
    }
}
```

## UI Updates

### Envelope Control Bindings

Update SwiftUI bindings or UIKit outlets:

```swift
// OLD:
@Published var envelopeAttack: Double = 0.01 {
    didSet {
        soundEngine.currentTemplate.envelope.attackDuration = envelopeAttack
        soundEngine.updateAllVoiceEnvelopes()
    }
}

// NEW:
@Published var envelopeAttack: Double = 0.01 {
    didSet {
        soundEngine.currentTemplate.modulation.loudnessEnvelope.attack = envelopeAttack
        soundEngine.updateAllVoiceLoudnessEnvelopes()
    }
}
```

### Display Values

Update any UI that displays envelope times:

```swift
// OLD:
Text("Attack: \(currentTemplate.envelope.attackDuration, specifier: "%.3f")s")

// NEW:
Text("Attack: \(currentTemplate.modulation.loudnessEnvelope.attack, specifier: "%.3f")s")
```

## Preset Loading

### Option 1: Clean Migration

If you're okay breaking old presets, just use the new structure:

```swift
func loadPreset(_ preset: AudioParameterSet) {
    self.currentTemplate = preset.voiceTemplate
    // loudnessEnvelope is now in modulation.loudnessEnvelope
}
```

### Option 2: Backward-Compatible Migration

If you need to support old presets with `envelope` field:

```swift
func loadPreset(_ preset: AudioParameterSet) {
    var migratedPreset = preset
    
    // Check if old envelope exists and new one doesn't
    if let oldEnvelope = preset.voiceTemplate.envelope,
       preset.voiceTemplate.modulation.loudnessEnvelope == LoudnessEnvelopeParameters.default {
        // Migrate old envelope to new loudness envelope
        migratedPreset.voiceTemplate.modulation.loudnessEnvelope = LoudnessEnvelopeParameters(
            attack: oldEnvelope.attackDuration,
            decay: oldEnvelope.decayDuration,
            sustain: oldEnvelope.sustainLevel,
            release: oldEnvelope.releaseDuration,
            isEnabled: true
        )
    }
    
    self.currentTemplate = migratedPreset.voiceTemplate
}
```

## Testing Checklist

After migration, verify:

- [ ] **Basic playback**: Notes trigger and release correctly
- [ ] **Envelope shapes**: Attack/Decay/Sustain/Release work as expected
- [ ] **Voice stealing**: No clicks when voices are stolen (key improvement!)
- [ ] **Legato mode**: Smooth transitions in monophonic mode (key improvement!)
- [ ] **Preset loading**: Old and new presets load correctly
- [ ] **Parameter changes**: UI controls update envelope correctly
- [ ] **Fast attacks**: Instant attack (0ms) works without clicks
- [ ] **Long releases**: Extended releases (>1s) fade smoothly
- [ ] **Modulation interaction**: Other modulation sources don't conflict

## Common Issues and Solutions

### Issue: Voices don't make sound

**Cause**: Fader starts at 0 gain and isn't being ramped up on trigger.

**Solution**: Check that `trigger()` method calls:
```swift
fader.$leftGain.ramp(to: 1.0, duration: Float(loudnessAttack))
fader.$rightGain.ramp(to: 1.0, duration: Float(loudnessAttack))
```

### Issue: Envelope doesn't sustain

**Cause**: Loudness envelope time not being tracked correctly.

**Solution**: Verify `applyModulation()` updates `modulationState.loudnessEnvelopeTime` in both gate open and closed states.

### Issue: Clicks during voice stealing

**Cause**: Not capturing current fader level before triggering new note.

**Solution**: Check that `trigger()` captures current level:
```swift
let currentFaderLevel = Double(fader.leftGain)
modulationState.loudnessStartLevel = currentFaderLevel
```

### Issue: Old presets don't load

**Cause**: Backward compatibility not implemented.

**Solution**: Use Option 2 migration approach (see "Preset Loading" section above).

### Issue: Attack sounds different

**Cause**: Attack is now linear instead of exponential.

**Solution**: This is expected behavior. Linear attack is generally perceived as more punchy. If you need exponential attack, you can modify `calculateLoudnessEnvelopeValue()` to use exponential curves.

## Performance Notes

- **CPU**: Minimal impact - replaced one node with another
- **Memory**: +24 bytes per voice (3 doubles in ModulationState)
- **Control rate**: +1 envelope calculation per voice per cycle (~50-100 μs total)

## Rollback Instructions

If you need to roll back to the old system:

1. Revert changes to `A2 PolyphonicVoice.swift`:
   - Replace `let fader: Fader` with `let envelope: AmplitudeEnvelope`
   - Restore `trigger()` to call `envelope.openGate()`
   - Restore `release()` to call `envelope.closeGate()`
   - Remove `applyLoudnessEnvelope()` method

2. Revert changes to `A6 ModulationSystem.swift`:
   - Remove `LoudnessEnvelopeParameters`
   - Remove `loudnessEnvelopeTime` from `ModulationState`
   - Remove `calculateLoudnessEnvelopeValue()` from `ModulationRouter`

3. Restore `EnvelopeParameters` usage in `A1 SoundParameters.swift`

4. Update VoicePool to connect `voice.envelope` instead of `voice.fader`

## Questions?

If you encounter issues not covered here, check:
- `LOUDNESS_ENVELOPE_IMPLEMENTATION.md` for architectural details
- AudioKit documentation for `Fader` node usage
- Existing modulation code for envelope calculation examples
