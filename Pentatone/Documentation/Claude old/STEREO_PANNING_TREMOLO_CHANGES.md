# Stereo Panning Tremolo Implementation

## Overview

This document describes the changes made to convert the global LFO tremolo effect from a simple mono volume modulation to a stereo panning tremolo with smooth interpolation.

## Goals

1. **Smoother tremolo**: Use proper ramping (20ms) to interpolate between control-rate updates (50Hz), eliminating zipper noise
2. **Stereo effect**: Modulate left and right channels in opposite directions to create a stereo panning tremolo
3. **Better signal flow**: Use a dedicated Fader node instead of Mixer volume (which doesn't support ramping)

## Changes Made

### 1. VoicePool (A3 VoicePool.swift)

#### New Node
- Added `postMixerFader: Fader` property after `voiceMixer`
- Created with base gain of 0.5 for both L/R channels
- Inserted in signal chain: `voiceMixer` → `postMixerFader` → delay/effects

#### Removed/Replaced Properties
- Removed `basePreVolume` (was for mixer volume modulation)
- Added `baseFaderGain` (default 0.5) for fader gain modulation

#### Removed/Replaced Methods
- Removed `updateBasePreVolume()` - no longer needed
- Removed `resetMixerVolumeToBase()` - no longer needed
- Added `updateBaseFaderGain()` - updates base fader gain
- Added `resetFaderGainsToBase()` - resets L/R gains to base when modulation is disabled

#### Updated Modulation Logic
- `applyGlobalLFOToGlobalParameters()` now calls:
  - `ModulationRouter.calculateFaderStereoGains()` instead of `calculateVoiceMixerVolume()`
  - Applies L/R gains with 20ms ramp: `postMixerFader.$leftGain.ramp(to:duration:)`
  - Uses opposing modulation: left = base × (1.0 + lfo × amount), right = base × (1.0 - lfo × amount)

### 2. AudioEngine (A5 AudioEngine.swift)

#### Signal Chain Update
Old chain:
```
VoicePool.voiceMixer → Delay → Filter → DryWetMixer → Reverb → Output
```

New chain:
```
VoicePool.voiceMixer → PostMixerFader → Delay → Filter → DryWetMixer → Reverb → Output
```

#### Specific Changes
- `voiceMixer.volume` set to 1.0 (unity gain, no longer modulated)
- `fxDelay` now receives `voicePool.postMixerFader` as input
- `delayDryWetMixer` now receives `voicePool.postMixerFader` as dry input
- Removed preVolume initialization from voice pool setup

### 3. ModulationRouter (A6 ModulationSystem.swift)

#### New Function
Added `calculateFaderStereoGains()`:
```swift
static func calculateFaderStereoGains(
    baseFaderGain: Double,
    globalLFOValue: Double,
    globalLFOAmount: Double
) -> (leftGain: Double, rightGain: Double)
```

**Formula:**
- `leftGain = baseFaderGain × (1.0 + (lfoValue × amount))`
- `rightGain = baseFaderGain × (1.0 - (lfoValue × amount))`

**Behavior:**
- When LFO is positive → left channel louder, right channel quieter
- When LFO is negative → right channel louder, left channel quieter
- When LFO is zero → both channels at base gain
- Allows up to 2x gain for compensation (clamped 0.0 to 2.0)

#### Deprecated Function
- `calculateVoiceMixerVolume()` marked as deprecated
- Still available for backward compatibility but no longer used

#### Updated Documentation
- `GlobalLFOParameters.amountToVoiceMixerVolume` comment updated to reflect stereo panning tremolo
- Default value comment updated

### 4. ParameterManager (A7 ParameterManager.swift)

#### Updated Methods
1. `updatePreVolume()`:
   - Removed `voicePool?.updateBasePreVolume()` call
   - Added comment explaining preVolume no longer affects modulation

2. `updateGlobalLFOAmountToMixerVolume()`:
   - Renamed comment to "post-mixer fader (stereo panning tremolo)"
   - Changed reset call from `resetMixerVolumeToBase()` to `resetFaderGainsToBase()`

3. `updateVolumeMacro()`:
   - Removed `voicePool?.updateBasePreVolume()` call
   - Added comment explaining preVolume no longer affects modulation

## Technical Details

### Why 20ms Ramp?
- Control rate runs at 50Hz (20ms intervals)
- Using 20ms ramp ensures smooth interpolation between successive parameter updates
- Eliminates zipper noise from discrete parameter changes
- Previous implementation used direct assignment (no ramping possible with Mixer.volume)

### Why Opposing L/R Modulation?
- Creates stereo width and movement
- More interesting than simple mono tremolo
- When one channel gets quieter, the other gets louder (panning effect)
- Total energy remains more constant than traditional tremolo

### Base Gain of 0.5
- Chosen to allow equal headroom in both directions
- With amount=1.0 and LFO at extremes:
  - Left can go from 0.0 (quiet) to 1.0 (full)
  - Right can go from 0.0 (quiet) to 1.0 (full)
- Provides natural stereo balance at neutral position

## Testing Checklist

- [ ] Tremolo effect is smoother (no zipper noise)
- [ ] Stereo panning is audible (L/R channels modulate in opposite directions)
- [ ] Effect responds to amount control (0.0 = no effect, 1.0 = full effect)
- [ ] Effect resets cleanly when amount is set to zero
- [ ] No audio glitches during preset switching
- [ ] Works with all LFO waveforms (sine, triangle, square, etc.)
- [ ] Works with both free-running and tempo-synced LFO modes
- [ ] Volume macro still works correctly (independent of LFO modulation)
- [ ] Preset loading/saving preserves global LFO settings

## Future Enhancements

Possible future improvements:
1. Make pan spread adjustable (currently fixed at ±100%)
2. Add stereo width control (mono → wide)
3. Add option to switch between tremolo (in-phase) and panning (out-of-phase) modes
4. Visualize L/R gain levels in UI

## Notes

- The parameter name `amountToVoiceMixerVolume` remains unchanged for backward compatibility with saved presets
- The voice mixer volume is now always 1.0 (unity gain)
- The old `calculateVoiceMixerVolume()` function is deprecated but not removed (for reference)
