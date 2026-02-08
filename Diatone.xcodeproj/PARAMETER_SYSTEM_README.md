# Audio Parameter System

## Overview

The audio parameter system provides a clean, type-safe way to control all AudioKit parameters in your app. It separates parameter management from the audio engine itself, making it easy to:

- Build UI controls (sliders, knobs, etc.)
- Map touch gestures to parameters
- Create and load presets
- Control parameters globally or per-voice

## Architecture

### Files

1. **AudioParameters.swift** - Core parameter system
   - Parameter model structs (codable for preset saving)
   - `AudioParameterManager` singleton
   - Convenience methods for common operations

2. **AudioKitCode.swift** - Audio engine (updated)
   - Now uses parameters from the parameter system
   - `OscVoice` accepts `VoiceParameters` on init
   - `EngineManager` uses `MasterParameters` for effects

3. **AudioParameterIntegrationExamples.swift** - Usage examples
   - Reference code for common integrations
   - Not meant to be used directly

## Key Concepts

### 1. Voice Template vs Voice Overrides

**Voice Template**: The default parameters applied to all voices. When you change the template, all voices without overrides are updated.

**Voice Overrides**: Temporary per-voice parameters. Perfect for touch-position-based modulation that only affects one voice.

```swift
// Change filter cutoff for ALL voices
AudioParameterManager.shared.updateTemplateFilter(myFilterParams)

// Change filter cutoff for ONLY voice 5
AudioParameterManager.shared.updateVoiceFilterCutoff(at: 5, normalizedValue: 0.8)

// Clear the override (voice returns to template)
AudioParameterManager.shared.clearVoiceOverride(at: 5)
```

### 2. Parameter Structures

All parameters are organized into logical groups:

- `OscillatorParameters` - FM synthesis parameters
- `FilterParameters` - Low-pass filter cutoff and resonance
- `EnvelopeParameters` - ADSR envelope
- `PanParameters` - Stereo positioning
- `VoiceParameters` - Combines all per-voice parameters
- `DelayParameters` - Stereo delay effect
- `ReverbParameters` - Reverb effect
- `MasterParameters` - Combines all master effects
- `AudioParameterSet` - Complete preset (template + master)

### 3. Presets

Presets are complete snapshots of all parameters:

```swift
let manager = AudioParameterManager.shared

// Create a preset from current settings
let preset = manager.createPreset(named: "My Sound")

// Load a preset
manager.loadPreset(preset)

// Save/load from storage (you implement this)
let json = try JSONEncoder().encode(preset)
UserDefaults.standard.set(json, forKey: "preset_\(preset.id)")
```

## Common Usage Patterns

### Pattern 1: Simple UI Slider

```swift
Slider(value: Binding(
    get: { AudioParameterManager.shared.master.delay.dryWetMix },
    set: { AudioParameterManager.shared.updateDelayMix($0) }
), in: 0...1)
```

### Pattern 2: Touch Position → Parameter

```swift
// In your KeyButton's DragGesture
.onChanged { value in
    AudioParameterManager.shared.mapTouchToFilterCutoff(
        voiceIndex: voiceIndex,
        touchX: value.location.x,
        viewWidth: geometry.size.width
    )
    trigger()
}
.onEnded { _ in
    release()
    AudioParameterManager.shared.clearVoiceOverride(at: voiceIndex)
}
```

### Pattern 3: Parameter Modulation

```swift
// Slowly sweep the filter for all voices
func sweepFilter() {
    var params = AudioParameterManager.shared.voiceTemplate.filter
    params.cutoffFrequency = 500
    AudioParameterManager.shared.updateTemplateFilter(params)
    
    // Animate the change
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        params.cutoffFrequency = 8000
        AudioParameterManager.shared.updateTemplateFilter(params)
    }
}
```

## Available Parameters

### Voice Parameters (per voice or template)

**Oscillator:**
- `carrierMultiplier: Double` - FM carrier frequency multiplier
- `modulatingMultiplier: Double` - FM modulator frequency multiplier
- `modulationIndex: Double` - FM modulation depth (brightness)
- `amplitude: Double` - Output volume

**Filter:**
- `cutoffFrequency: Double` (20-20000 Hz) - Low-pass cutoff
- `resonance: Double` (0-0.9) - Filter resonance/Q

**Envelope:**
- `attackDuration: Double` (seconds) - Time to reach full volume
- `decayDuration: Double` (seconds) - Time to decay to sustain
- `sustainLevel: Double` (0-1) - Sustain volume level
- `releaseDuration: Double` (seconds) - Time to fade out

**Pan:**
- `pan: Double` (-1 to +1) - Stereo position (left to right)

### Master Parameters (global)

**Delay:**
- `time: Double` (seconds) - Delay time
- `feedback: Double` (0-1) - Delay feedback amount
- `dryWetMix: Double` (0-1) - Mix level
- `pingPong: Bool` - Stereo ping-pong mode

**Reverb:**
- `feedback: Double` (0-1) - Reverb size/tail
- `cutoffFrequency: Double` (Hz) - High-frequency damping
- `dryWetBalance: Double` (0-1) - Dry/wet mix

## Quick Start

### Step 1: Access the Manager

```swift
let paramManager = AudioParameterManager.shared
```

### Step 2: Change Parameters

```swift
// Master effect
paramManager.updateDelayMix(0.7)

// Voice template (affects all voices)
var filterParams = paramManager.voiceTemplate.filter
filterParams.cutoffFrequency = 5000
paramManager.updateTemplateFilter(filterParams)

// Single voice override
paramManager.updateVoiceFilterCutoff(at: 0, normalizedValue: 0.8)
```

### Step 3: Build UI

See `AudioParameterIntegrationExamples.swift` for complete UI examples.

## Next Steps

1. **Try the test view**: Run the `AudioEngineTestView` preview to test parameter changes
2. **Add a settings panel**: Use examples from `ParameterControlPanel_Example`
3. **Enable touch-position control**: Update your `KeyButton` with examples from `EnhancedKeyButton_Example`
4. **Implement presets**: Create factory presets and a browser UI
5. **Add parameter automation**: Animate parameters over time for evolving sounds

## Tips

- **Always use the manager**: Don't modify AudioKit nodes directly - go through `AudioParameterManager`
- **Clear overrides**: Call `clearVoiceOverride()` when a key is released to return to template
- **Use normalized values**: For touch mapping, work in 0-1 range then map to parameter range
- **Observable updates**: `AudioParameterManager` is `@Observable`, so SwiftUI views auto-update
- **Type safety**: The compiler helps you - parameter structs prevent invalid values

## Performance

The parameter system is designed for real-time use:
- Parameter updates are thread-safe (uses `@MainActor`)
- No allocations during parameter changes
- Direct AudioKit node updates (no intermediate processing)
- Override system uses dictionary lookups (very fast)

## Future Enhancements

Possible additions you might want:
- Parameter smoothing/interpolation
- MIDI CC mapping
- Parameter automation/LFOs
- Per-key calibration/tuning
- Velocity sensitivity
- Aftertouch mapping
