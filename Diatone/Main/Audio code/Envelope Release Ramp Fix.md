# Envelope Release Ramp Fix

## Bug 1: Ramp duration snap on early release

When a note is released before the envelope attack phase completes, the **mod level** and **filter cutoff** destinations jump to 100% (the attack target) instead of decaying from the current partial value. Loudness and pitch envelopes are not affected.

### Root Cause

During the attack phase, `applyCombinedModulationIndex` and `applyCombinedFilterFrequency` were using `remainingAttack` (up to several seconds) as the AudioKit ramp duration. When a short control-rate ramp (10ms) replaced this long in-progress ramp at note release, AudioKit's parameter ramper snapped to the original trigger ramp's peak target rather than continuing from the interpolated value.

Loudness and pitch were unaffected because:
- **Loudness**: passive during attack (returns early, lets the trigger ramp run undisturbed)
- **Pitch**: already used short `ControlRateConfig.modulationRampDuration` ramps during attack

### Fix

In `A2 PolyphonicVoice.swift`, change the attack-phase ramp duration from `remainingAttack` to `ControlRateConfig.modulationRampDuration` in two places:

#### 1. `applyCombinedModulationIndex` — ramp duration calculation

Before:
```swift
if isInAttackPhase && modEnvAttack > 0 {
    let remainingAttack = modEnvAttack - modulationState.modulatorEnvelopeTime
    rampDuration = Float(max(0.001, remainingAttack))
}
```

After:
```swift
if isInAttackPhase && modEnvAttack > 0 {
    rampDuration = ControlRateConfig.modulationRampDuration
}
```

#### 2. `applyCombinedFilterFrequency` — ramp duration calculation

Before:
```swift
if isInAttackPhase && auxEnvAttack > 0 && hasAuxEnv {
    let remainingAttack = auxEnvAttack - modulationState.auxiliaryEnvelopeTime
    rampDuration = Float(max(0.001, remainingAttack))
}
```

After:
```swift
if isInAttackPhase && auxEnvAttack > 0 && hasAuxEnv {
    rampDuration = ControlRateConfig.modulationRampDuration
}
```

### Why This Works

The modulation loop's calculated target values already track the linear attack curve at control rate. Since each cycle's target closely matches the previous one, short 10ms ramps produce the same smooth attack as the long ramps did — but without the artifact when transitioning to release.

---

## Bug 2: Formula mismatch on early release (value discontinuity)

After fixing Bug 1, a subtler discontinuity remains in **filter cutoff** and **mod level** when releasing during the attack phase. There is no level jump, but a sudden change in the parameter value at the exact moment of release.

### Root Cause

The attack path and release path in `applyCombinedFilterFrequency` and `applyCombinedModulationIndex` use **different formulas** to convert the raw 0–1 envelope value into actual parameter values.

**Filter cutoff:**
- Attack path: linear interpolation in Hz between pre-baked start and peak values
  ```swift
  envelopeCutoff = startCutoff + (peakCutoff - startCutoff) * progress
  ```
- Release path: octave-based exponential mapping
  ```swift
  envelopeCutoff = baseCutoff * pow(2.0, envValue * amount)
  ```

These produce different Hz values for the same raw envelope value. For example, with a 2-octave filter sweep at 50% attack progress:
- Attack formula: `1000 × (1 + (4-1) × 0.5)` = **2500 Hz**
- Release formula: `1000 × 2^(0.5 × 2)` = **2000 Hz**
- Result: **500 Hz discontinuity** at the handover

**Mod index:** a similar mismatch exists because the attack path interpolates between `modulatorStartModIndex` (actual AudioKit value at trigger, which may differ from `baseModulationIndex` after voice stealing) and `modulatorPeakModIndex`, while the release path calculates from `baseModulationIndex`.

**Loudness and pitch are not affected** because:
- **Loudness**: the raw envelope value maps directly to the fader gain — there is no intermediate formula, so there is nothing to mismatch
- **Pitch**: uses the same octave-based formula in both attack and release (no special attack-phase interpolation)

### Fix

Convert the captured raw envelope value at the moment of release so the release formula produces the same parameter value the attack formula was producing. This conversion is destination-specific and must be stored per-destination to avoid affecting other destinations that share the same raw envelope.

#### 1. Add corrected sustain levels to `ModulationState`

```swift
// In ModulationState struct:
var correctedModulatorSustainLevel: Double? = nil
var correctedAuxiliarySustainLevelForFilter: Double? = nil
```

Reset these to `nil` in both `reset()` and `closeGate()`.

#### 2. Add corrected values as optional parameters to `closeGate()`

```swift
mutating func closeGate(modulatorValue: Double, auxiliaryValue: Double, loudnessValue: Double,
                       correctedModulatorValue: Double? = nil,
                       correctedAuxiliaryValueForFilter: Double? = nil) {
    // ... existing code ...
    correctedModulatorSustainLevel = correctedModulatorValue
    correctedAuxiliarySustainLevelForFilter = correctedAuxiliaryValueForFilter
    // ... existing code ...
}
```

#### 3. Compute corrected values in `release()` when releasing during attack

For mod index — solve `baseModIndex + x * amount = attackValue` for x:
```swift
let isInModulatorAttack = modulationState.modulatorEnvelopeTime < voiceModulation.modulatorEnvelope.attack
    && voiceModulation.modulatorEnvelope.attack > 0
if isInModulatorAttack {
    let attackModIndex = modulationState.modulatorStartModIndex +
        (modulationState.modulatorPeakModIndex - modulationState.modulatorStartModIndex) * modulatorValue
    let effectiveAmount = // ... compute effective amount including touch scaling ...
    if abs(effectiveAmount) > 0.0001 {
        correctedModulatorValue = (attackModIndex - modulationState.baseModulationIndex) / effectiveAmount
    }
}
```

For filter cutoff — solve `baseCutoff * 2^(x * amount) = attackCutoff` for x:
```swift
let isInAuxiliaryAttack = modulationState.auxiliaryEnvelopeTime < voiceModulation.auxiliaryEnvelope.attack
    && voiceModulation.auxiliaryEnvelope.attack > 0
if isInAuxiliaryAttack && hasFilterEnvelope {
    let attackCutoff = modulationState.auxiliaryStartFilterCutoff +
        (modulationState.auxiliaryPeakFilterCutoff - modulationState.auxiliaryStartFilterCutoff) * auxiliaryValue
    let keyTrackedBaseCutoff = // ... compute with key tracking ...
    let effectiveAmount = // ... compute effective amount including touch scaling ...
    if abs(effectiveAmount) > 0.0001 && attackCutoff > 0 && keyTrackedBaseCutoff > 0 {
        correctedAuxiliaryValueForFilter = log2(attackCutoff / keyTrackedBaseCutoff) / effectiveAmount
    }
}
```

Pass both corrected values to `closeGate()`.

#### 4. Use corrected values in the apply functions during release

In both `applyCombinedModulationIndex` and `applyCombinedFilterFrequency`, in the post-attack code path, scale the envelope value by the correction ratio when a corrected value is available:

```swift
let effectiveEnvValue: Double
if let corrected = modulationState.correctedSustainLevel,  // use appropriate field name
   modulationState.rawSustainLevel > 0.0001 {
    effectiveEnvValue = envValue * (corrected / modulationState.rawSustainLevel)
} else {
    effectiveEnvValue = envValue
}
```

### Why This Works

The scaling ratio `corrected / rawCaptured` converts the raw envelope value into the domain expected by the release formula. Since `envValue = rawCaptured * e^(-t/τ)`, the corrected value becomes `corrected * e^(-t/τ)` — an exponential decay from the correct starting point with the same time constant.

- At t=0: produces exactly the same parameter value the attack was producing
- At t→∞: approaches the base value (same as uncorrected)
- Release time is unchanged (same τ)
- Other destinations sharing the same raw envelope are unaffected (correction is applied per-destination in the apply functions, not at capture)
