# Phase 5A: Modulation Foundation - Complete ✅

**Date:** December 23, 2025  
**Status:** ✅ Implementation Complete  
**Next Stage:** 5B - Modulation Envelopes

---

## Objective

Establish comprehensive data structures and architecture for the modulation system. This foundation supports all subsequent modulation features (envelopes, LFOs, touch/key tracking).

---

## What Was Implemented

### 1. Enhanced Modulation Destinations

Created comprehensive `ModulationDestination` enum with all planned targets:

**Oscillator Destinations:**
- `oscillatorAmplitude` - Overall volume modulation
- `oscillatorBaseFrequency` - Pitch modulation (vibrato, etc.)
- `modulationIndex` - FM timbre modulation (primary for mod envelope)
- `modulatingMultiplier` - FM modulator ratio

**Filter Destinations:**
- `filterCutoff` - Low-pass filter frequency

**Stereo/Voice Destinations:**
- `stereoSpreadAmount` - Dynamic stereo width

**Voice LFO Destinations (meta-modulation):**
- `voiceLFOFrequency` - Modulate LFO rate
- `voiceLFOAmount` - Modulate LFO depth

**Global/FX Destinations:**
- `delayTime` - Rhythmic delay modulation
- `delayMix` - Delay wet/dry balance

Each destination includes:
- `isVoiceLevel` / `isGlobalLevel` properties for routing validation
- `displayName` for UI display

---

### 2. LFO System Structures

#### `LFOWaveform` Enum
Five waveform shapes:
- `sine` - Smooth modulation
- `triangle` - Linear modulation
- `square` - Stepped modulation
- `sawtooth` - Rising ramp
- `reverseSawtooth` - Falling ramp

#### `LFOResetMode` Enum
Three reset behaviors:
- `free` - Continuous, ignores note triggers
- `trigger` - Resets phase on each note
- `sync` - Tempo-synced (global timing)

#### `LFOFrequencyMode` Enum
Two frequency modes:
- `hertz` - Direct Hz value (0.01-10 Hz)
- `tempoSync` - Tempo multipliers (1/4, 1/2, 1, 2, 4...)

#### `LFOParameters` Struct
Complete LFO configuration:
```swift
struct LFOParameters {
    var waveform: LFOWaveform
    var resetMode: LFOResetMode
    var frequencyMode: LFOFrequencyMode
    var frequency: Double
    var destination: ModulationDestination
    var amount: Double              // Bipolar (always positive, ±)
    var isEnabled: Bool
}
```

---

### 3. Modulation Envelope Structures

#### `ModulationEnvelopeParameters` Struct
ADSR envelope for parameter modulation:
```swift
struct ModulationEnvelopeParameters {
    var attack: Double              // Attack time (seconds)
    var decay: Double               // Decay time (seconds)
    var sustain: Double             // Sustain level (0-1)
    var release: Double             // Release time (seconds)
    var destination: ModulationDestination
    var amount: Double              // Unipolar (-1 to +1)
    var isEnabled: Bool
}
```

**Two envelopes per voice:**
1. **Modulator Envelope** - Hardwired to `modulationIndex` (FM timbral evolution)
2. **Auxiliary Envelope** - Routable to any destination

---

### 4. Touch & Key Tracking Structures

#### `KeyTrackingParameters`
Frequency-proportional modulation:
- Maps note frequency to modulation value (0-1)
- Reference: 440 Hz (A4) = 0.5
- 6-octave range mapping
- Unipolar amount (-1 to +1)

#### `TouchInitialParameters`
Initial touch X position:
- Captures where key was first touched
- Unipolar amount (-1 to +1)
- Currently hardwired to filter in old system

#### `TouchAftertouchParameters`
Aftertouch X movement:
- Tracks finger movement while holding
- Bipolar amount (always positive, ±)
- Currently hardwired to amplitude in old system
- TODO: Consider relative/absolute mode toggle

---

### 5. Complete Modulation Parameter Structures

#### `VoiceModulationParameters`
All per-voice modulation sources:
```swift
struct VoiceModulationParameters {
    var modulatorEnvelope: ModulationEnvelopeParameters  // → modulationIndex
    var auxiliaryEnvelope: ModulationEnvelopeParameters  // → routable
    var voiceLFO: LFOParameters                          // Per-voice LFO
    var keyTracking: KeyTrackingParameters               // Frequency tracking
    var touchInitial: TouchInitialParameters             // Touch X position
    var touchAftertouch: TouchAftertouchParameters       // Touch X movement
}
```

#### `GlobalLFOParameters`
Single global LFO:
```swift
struct GlobalLFOParameters {
    var waveform: LFOWaveform
    var resetMode: LFOResetMode     // Free or Sync only (no trigger)
    var frequencyMode: LFOFrequencyMode
    var frequency: Double
    var destination: ModulationDestination
    var amount: Double
    var isEnabled: Bool
}
```

---

### 6. Runtime State Structures

#### `ModulationState` (per voice)
Ephemeral runtime state for modulation calculation:
```swift
struct ModulationState {
    var modulatorEnvelopeTime: Double
    var auxiliaryEnvelopeTime: Double
    var isGateOpen: Bool
    var voiceLFOPhase: Double        // 0-1
    var initialTouchX: Double        // 0-1
    var currentTouchX: Double        // 0-1
    var currentFrequency: Double
}
```

Includes:
- `reset(frequency:touchX:)` - Called when voice triggers
- `closeGate()` - Called when voice releases

#### `GlobalModulationState`
Global runtime state:
```swift
struct GlobalModulationState {
    var globalLFOPhase: Double       // 0-1
    var currentTempo: Double         // BPM
}
```

---

### 7. Modulation Routing Infrastructure

#### `ModulationRouter` Helper
Utility for modulation calculation (Phase 5B+ implementation):
- `calculateModulation(for:voiceModulation:modulationState:globalLFOValue:)` → Double
- `applyModulation(baseValue:modulation:destination:)` → Double

Placeholder methods ready for Phase 5B implementation.

#### `ControlRateConfig` 
Configuration for update loop:
- Update rate: **200 Hz** (5ms intervals)
- Provides smooth LFOs and snappy envelopes
- Constant for timer implementation in Phase 5B

---

### 8. Integration with Existing Systems

#### Updated `VoiceParameters`
```swift
struct VoiceParameters {
    var oscillator: OscillatorParameters
    var filter: FilterParameters
    var envelope: EnvelopeParameters
    var modulation: VoiceModulationParameters  // NEW
}
```

#### Updated `MasterParameters`
```swift
struct MasterParameters {
    var delay: DelayParameters
    var reverb: ReverbParameters
    var globalLFO: GlobalLFOParameters  // NEW
    var tempo: Double                    // NEW (for tempo sync)
}
```

#### Updated `PolyphonicVoice`
Added modulation properties:
```swift
class PolyphonicVoice {
    var voiceModulation: VoiceModulationParameters
    var modulationState: ModulationState
    
    func updateModulationParameters(_ parameters: VoiceModulationParameters)
    func applyModulation(globalLFOValue: Double, deltaTime: Double)  // Placeholder
}
```

Modulation state now properly initialized/reset in `trigger()` and `release()`.

---

## Architecture Overview

### Data Flow (Planned)
```
Phase 5B+: Control-Rate Timer (200 Hz)
    ↓
Calculate Modulation Values:
  - Modulator Envelope → modulationIndex
  - Auxiliary Envelope → destination
  - Voice LFO → destination  
  - Global LFO → destination
  - Key Tracking → destination
  - Touch Initial → destination
  - Touch Aftertouch → destination
    ↓
ModulationRouter combines all sources
    ↓
Apply to AudioKit parameters (per voice)
```

### Modulation Hierarchy
```
VoicePool
  ├─ GlobalModulationState
  ├─ GlobalLFOParameters
  └─ PolyphonicVoices (×5)
       ├─ VoiceModulationParameters (config)
       ├─ ModulationState (runtime)
       └─ AudioKit nodes (oscLeft, oscRight, filter, envelope)
```

---

## Files Modified

### Core Files Updated
1. **A06 ModulationSystem.swift**
   - Complete rewrite with comprehensive structures
   - All modulation types defined
   - Runtime state management
   - Routing infrastructure
   - ~350 lines of modulation architecture

2. **A01 SoundParameters.swift**
   - Added `modulation` to `VoiceParameters`
   - Added `globalLFO` and `tempo` to `MasterParameters`
   - Maintains backward compatibility

3. **A02 PolyphonicVoice.swift**
   - Added `voiceModulation` property
   - Added `modulationState` property
   - Updated `trigger()` to initialize modulation state
   - Updated `release()` to close modulation gate
   - Added `updateModulationParameters()` method
   - Added placeholder `applyModulation()` method
   - Deprecated old `voiceLFO` property

---

## Design Decisions

### 1. Bipolar vs. Unipolar Modulation
- **Bipolar** (±, always positive amount): LFOs, Aftertouch
  - Modulates symmetrically around center value
  - Amount controls depth, direction is inherent to waveform
  
- **Unipolar** (+/-, positive or negative amount): Envelopes, Key Tracking, Touch Initial
  - Modulates in one direction
  - Amount can be positive (add) or negative (subtract)

### 2. Hardwired vs. Routable
- **Modulator Envelope → modulationIndex**: Hardwired
  - This is the primary FM sound design tool
  - Always available, no routing confusion
  
- **All Other Sources**: Routable
  - Maximum flexibility
  - Each source has default destination

### 3. Control Rate: 200 Hz
- High enough for smooth LFOs (clean waveforms at 10 Hz LFO)
- Fast enough for snappy envelopes (5ms resolution)
- Low enough to avoid CPU overhead
- Standard practice in synthesizer design

### 4. State Separation
- **Parameters** (`VoiceModulationParameters`): Part of presets, Codable
- **State** (`ModulationState`): Ephemeral, not saved
- Clear separation simplifies preset system

### 5. Touch Mapping Migration Path
Currently in `MainKeyboardView`:
- Initial touch X → filter cutoff (hardwired)
- Aftertouch X → amplitude (hardwired)

Phase 5D will:
- Make these routable through modulation system
- Preserve current behavior as defaults
- Allow users to customize in preset system

---

## Backward Compatibility

### Existing Code Unaffected
✅ All existing voice triggering works  
✅ Current touch mappings functional  
✅ Old presets load with default modulation values  
✅ No breaking changes to public APIs  

### Deprecation Path
- `voiceLFO` property deprecated, replaced by `voiceModulation.voiceLFO`
- Accessor provided for backward compatibility
- Will be removed in Phase 6 (preset system)

---

## Next Steps: Phase 5B - Modulation Envelopes

### Implementation Tasks
1. **Envelope Calculation**
   - Implement ADSR stage detection
   - Calculate envelope value based on time and gate state
   - Handle attack, decay, sustain, release transitions

2. **Modulator Envelope**
   - Hardwired to `modulationIndex`
   - Applied to both `oscLeft` and `oscRight`
   - Formula: `modulationIndex = baseValue + (envelopeValue * amount)`

3. **Auxiliary Envelope**
   - Routable destination system
   - Per-destination scaling (linear/exponential)
   - Apply to AudioKit parameters

4. **Control-Rate Timer**
   - 200 Hz update loop in `VoicePool`
   - Iterate all active voices
   - Update envelope times: `time += deltaTime`
   - Call `voice.applyModulation(globalLFOValue, deltaTime)`

5. **Testing**
   - Create test preset with visible envelope modulation
   - Modulator envelope on modulationIndex (hear timbre change)
   - Auxiliary envelope on filter cutoff (hear sweep)
   - Verify ADSR stages work correctly

### Estimated Time
2-3 days (includes testing and refinement)

---

## Documentation Status

- [x] Phase 5A implementation complete
- [x] Data structures documented
- [x] Architecture diagrams included
- [x] Design decisions recorded
- [x] Next steps outlined
- [ ] Phase 5B planning document
- [ ] Update main overhaul plan

---

## Success Criteria ✅

✅ All modulation structures defined  
✅ Runtime state management in place  
✅ Routing infrastructure designed  
✅ Integration with existing systems complete  
✅ No breaking changes  
✅ Backward compatibility maintained  
✅ Code compiles without errors  
✅ Placeholder methods documented  

---

## Technical Notes

### Why Not Use AudioKit's Built-in Modulation?
AudioKit provides parameter automation, but we need:
1. **Per-voice modulation** (5 independent LFOs)
2. **Complex routing** (multiple sources → multiple destinations)
3. **Touch integration** (gesture-based modulation)
4. **Preset system** (save/load modulation configs)
5. **UI control** (real-time parameter editing)

Custom modulation system provides full control and flexibility.

### Why 200 Hz Control Rate?
- **Audio rate** (48 kHz): Too much CPU overhead for parameter updates
- **60 Hz** (display rate): Not smooth enough for fast LFOs/envelopes
- **200 Hz**: Sweet spot for smooth, CPU-efficient modulation
- Nyquist theorem: 200 Hz supports clean 10 Hz LFO (20:1 ratio)

### Memory Impact
Minimal:
- `VoiceModulationParameters`: ~200 bytes per voice (5 voices = 1 KB)
- `ModulationState`: ~80 bytes per voice (5 voices = 400 bytes)
- `GlobalModulationState`: ~16 bytes
- **Total**: <2 KB additional memory

---

## Sign-Off

**Phase 5A Complete:** December 23, 2025  
**Implemented by:** Assistant  
**Ready for:** Phase 5B (Modulation Envelopes)  

---

**Current Status:** Foundation complete, ready to implement envelope calculation and control-rate timer in Phase 5B.
