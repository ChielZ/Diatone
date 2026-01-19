# Loudness Envelope - Quick Reference

## What Changed?

**Before:**
```swift
voice.envelope.openGate()      // Trigger
voice.envelope.closeGate()     // Release
voice.envelope.attackDuration  // Parameter
```

**After:**
```swift
voice.trigger()                // Trigger (handles fader internally)
voice.release()                // Release (handles fader internally)
voice.voiceModulation.loudnessEnvelope.attack  // Parameter
```

## Signal Path

**Before:**
```
[Oscillators] → [Mixer] → [Filter] → [AmplitudeEnvelope] → Output
```

**After:**
```
[Oscillators] → [Mixer] → [Filter] → [Fader] → Output
```

## Parameter Access

**UI Bindings:**
```swift
// OLD:
paramManager.voiceTemplate.envelope.attackDuration
paramManager.voiceTemplate.envelope.decayDuration
paramManager.voiceTemplate.envelope.sustainLevel
paramManager.voiceTemplate.envelope.releaseDuration

// NEW:
paramManager.voiceTemplate.loudnessEnvelope.attack
paramManager.voiceTemplate.loudnessEnvelope.decay
paramManager.voiceTemplate.loudnessEnvelope.sustain
paramManager.voiceTemplate.loudnessEnvelope.release
```

**Voice Updates:**
```swift
// OLD:
voice.updateEnvelopeParameters(params)

// NEW:
voice.updateLoudnessEnvelopeParameters(params)
```

**Voice Pool Updates:**
```swift
// OLD:
voicePool.updateAllVoiceEnvelopes(envelopeParams)

// NEW:
voicePool.updateAllVoiceLoudnessEnvelopes(loudnessParams)
```

## Preset Compatibility

**Old Preset Format** (still works!):
```json
{
  "voiceTemplate": {
    "envelope": {
      "attackDuration": 0.005,
      "decayDuration": 0.5,
      "sustainLevel": 1.0,
      "releaseDuration": 0.1
    }
  }
}
```

**Automatic Migration:**
- Happens during `Codable` decoding
- Converts `envelope` → `modulation.loudnessEnvelope`
- No manual intervention required

**New Preset Format:**
```json
{
  "voiceTemplate": {
    "modulation": {
      "loudnessEnvelope": {
        "attack": 0.005,
        "decay": 0.5,
        "sustain": 1.0,
        "release": 0.1,
        "isEnabled": true
      }
    }
  }
}
```

## How Voice Stealing Works Now

### Before (with AmplitudeEnvelope)
```
Voice playing at 50% envelope level
↓
New note triggers
↓
Envelope resets to 0% → CLICK!
↓
Attack to 100%
```

### After (with Fader)
```
Voice playing at 50% fader level
↓
New note triggers
↓
Capture current level (50%)
↓
Ramp from 50% to 100% → NO CLICK!
```

### Code Flow:
```swift
// In trigger():
let currentFaderLevel = Double(fader.leftGain)  // e.g., 0.5
modulationState.loudnessStartLevel = currentFaderLevel
fader.$leftGain.ramp(to: 1.0, duration: loudnessAttack)

// In applyLoudnessEnvelope() (200 Hz):
let envValue = ModulationRouter.calculateLoudnessEnvelopeValue(
    ...,
    startLevel: modulationState.loudnessStartLevel  // Uses captured level!
)
fader.$leftGain.ramp(to: AUValue(envValue), duration: 0.005)
```

## ModulationState Changes

**Added Fields:**
```swift
var loudnessEnvelopeTime: Double = 0.0      // Time in current stage
var loudnessSustainLevel: Double = 0.0      // Captured at release
var loudnessStartLevel: Double = 0.0        // For voice stealing
```

**Updated Method:**
```swift
mutating func closeGate(
    modulatorValue: Double,
    auxiliaryValue: Double,
    loudnessValue: Double  // NEW parameter
)
```

## Common Patterns

### Update Envelope from UI:
```swift
func updateAttack(_ newValue: Double) {
    paramManager.updateEnvelopeAttack(newValue)
    
    // Apply to all voices
    let params = paramManager.voiceTemplate.loudnessEnvelope
    for voice in voicePool.voices {
        voice.updateLoudnessEnvelopeParameters(params)
    }
}
```

### Access Envelope Value:
```swift
// Direct access (shortcut):
let attack = voiceTemplate.loudnessEnvelope.attack

// Full path:
let attack = voiceTemplate.modulation.loudnessEnvelope.attack
```

### Load Preset with Migration:
```swift
// Automatic migration - no changes needed!
let preset = try JSONDecoder().decode(AudioParameterSet.self, from: data)
// Old envelope is automatically migrated to loudnessEnvelope
```

## Testing Checklist

Quick tests to verify implementation:

- [ ] **Basic playback**: Play a note → Sound works
- [ ] **ADSR works**: Adjust attack/decay/sustain/release → Envelope changes
- [ ] **Voice stealing**: Play 11 notes rapidly → No clicks between notes ⭐
- [ ] **Legato**: Hold one note, play another in mono mode → Smooth transition ⭐
- [ ] **Old preset**: Load a preset created before this change → Works correctly
- [ ] **New preset**: Save a preset → Loads correctly
- [ ] **Fast attack**: Set attack to 0ms → Instant onset, no click
- [ ] **Long release**: Set release to 2s → Smooth fadeout

## Debugging Tips

### Voice Not Making Sound?
```swift
// Check fader level:
print("Fader level: L=\(voice.fader.leftGain) R=\(voice.fader.rightGain)")

// Check if modulation is running:
print("Loudness envelope time: \(voice.modulationState.loudnessEnvelopeTime)")
```

### Envelope Not Responding?
```swift
// Check if parameters are being applied:
print("Loudness envelope: A=\(voice.voiceModulation.loudnessEnvelope.attack)")

// Check if applyLoudnessEnvelope is being called:
// Add a print statement in applyLoudnessEnvelope()
```

### Clicks During Voice Stealing?
```swift
// Check if start level is being captured:
print("Start level: \(voice.modulationState.loudnessStartLevel)")

// Should NOT be 0.0 during voice stealing!
```

## Key Benefits Summary

✅ **No clicks during voice stealing** - envelopes start from current level  
✅ **Better legato in mono mode** - smooth note transitions  
✅ **Consistent architecture** - all envelopes use same system  
✅ **Backward compatible** - old presets work automatically  
✅ **Negligible performance impact** - just swapped nodes  

## Questions?

- **Architecture**: See `LOUDNESS_ENVELOPE_IMPLEMENTATION.md`
- **Migration**: See `LOUDNESS_ENVELOPE_MIGRATION.md`
- **Changes**: See `LOUDNESS_ENVELOPE_CHANGES.md`
- **This file**: Quick reference for common tasks

---

**TL;DR**: We replaced the `AmplitudeEnvelope` node with a `Fader` controlled by our modulation system. This lets envelopes start from any level (not just zero), eliminating clicks during voice stealing and enabling smooth legato. Old presets migrate automatically. 🎵
