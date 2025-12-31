# Modulation System Refactoring Progress

## Overview
Refactoring from **selectable destinations** to **fixed destinations with individual amounts** per modulation source.

## ✅ Phase 1: Data Structures (A6 ModulationSystem.swift) - COMPLETE

### Changes Made:
1. **Deprecated** old `ModulationDestination` enum (kept for reference)
2. **Replaced** all parameter structs with fixed-destination versions:
   - `ModulatorEnvelopeParameters` - 1 fixed destination (modulation index)
   - `AuxiliaryEnvelopeParameters` - 3 fixed destinations (pitch, filter, vibrato)
   - `VoiceLFOParameters` - 3 fixed destinations + delay ramp
   - `GlobalLFOParameters` - 4 fixed destinations
   - `KeyTrackingParameters` - 2 fixed destinations
   - `TouchInitialParameters` - 4 fixed destinations (meta-modulation)
   - `TouchAftertouchParameters` - 3 fixed destinations
3. **Updated** `VoiceModulationParameters` container
4. **Enhanced** `ModulationState` with voice LFO delay/ramp support
5. **Completely rewrote** `ModulationRouter` with methods implementing exact math from spec:
   - `calculateOscillatorPitch()` - logarithmic (semitones)
   - `calculateOscillatorAmplitude()` - linear
   - `calculateModulationIndex()` - linear (additive)
   - `calculateModulatorMultiplier()` - linear
   - `calculateFilterFrequency()` - logarithmic (octaves) with complex routing
   - `calculateDelayTime()` - linear
   - Meta-modulation helpers for voice LFO and initial touch scaling

###Status: ✅ COMPLETE - Ready for next phase

---

## 🔄 Phase 2: Update PolyphonicVoice (A2) - IN PROGRESS

### Tasks:
1. Update `applyModulation()` signature and implementation
2. Rewrite all modulation application methods:
   - `applyModulatorEnvelope()` - use new fixed destination
   - `applyAuxiliaryEnvelope()` - apply to 3 destinations
   - `applyVoiceLFO()` - apply to 3 destinations with delay ramp
   - `applyGlobalLFO()` - handle 4 destinations
   - `applyKeyTracking()` - apply to 2 destinations
   - `applyTouchAftertouch()` - apply to 3 destinations
3. Implement voice LFO delay ramp in `updateVoiceLFOPhase()`
4. Remove old `getBaseValue()` and `applyModulatedValue()` helper methods
5. Update meta-modulation handling (initial touch scaling envelope amounts)

---

## ⏳ Phase 3: Update VoicePool (A3) - TODO

### Tasks:
1. Update `updateGlobalLFO()` method signature
2. Rewrite `applyGlobalLFOToGlobalParameters()` for multiple fixed destinations
3. Update `updateModulation()` to pass multiple amounts to voices
4. Update diagnostic methods

---

## ⏳ Phase 4: Update AudioParameterManager (A1) - TODO

### Tasks:
1. Remove old `update...Destination()` methods
2. Add new `update...AmountTo...()` methods for each source/destination pair
3. Update all affected code paths
4. Add early-exit optimizations (skip when amount = 0)

---

## ⏳ Phase 5: Testing & Validation - TODO

### Tasks:
1. Verify compilation
2. Test each modulation source independently
3. Test interactions between sources
4. Verify meta-modulation (initial touch, aux env → vibrato, etc.)
5. Test voice LFO delay ramp
6. Performance testing with all modulations active

---

## Key Design Decisions

### Bipolar vs. Unipolar
- Envelopes with signed amounts = **bipolar** sources (can be + or -)
- LFOs = **bipolar** sources (oscillate around zero)
- Aftertouch = **bipolar** source (left/right movement)
- Initial touch = **unipolar** source (0 to 1, applied at note-on)
- Key tracking = **unipolar** source (0 to 1, based on frequency)

### Linear vs. Logarithmic
- **LINEAR**: amplitude, modulation index, modulator multiplier, delay time
- **LOGARITHMIC**: pitch (semitones), filter frequency (octaves)

### Modulation Accumulation
- Most destinations: **simple addition** in their natural domain
- Filter frequency: **scaled by key tracking**, then add LFOs
- Amplitude: **scaled by initial touch**, then add global LFO
- Voice LFO outputs: **scaled by delay ramp** before applying amounts

### Performance Optimization
- Early-exit when `amount == 0.0`
- `hasActiveDestinations` properties on all parameter structs
- Skip entire modulation sources if no destinations are active

