# Envelope Release Ramp Fix

## Bug

When a note is released before the envelope attack phase completes, the **mod level** and **filter cutoff** destinations jump to 100% (the attack target) instead of decaying from the current partial value. Loudness and pitch envelopes are not affected.

## Root Cause

During the attack phase, `applyCombinedModulationIndex` and `applyCombinedFilterFrequency` were using `remainingAttack` (up to several seconds) as the AudioKit ramp duration. When a short control-rate ramp (10ms) replaced this long in-progress ramp at note release, AudioKit's parameter ramper snapped to the original trigger ramp's peak target rather than continuing from the interpolated value.

Loudness and pitch were unaffected because:
- **Loudness**: passive during attack (returns early, lets the trigger ramp run undisturbed)
- **Pitch**: already used short `ControlRateConfig.modulationRampDuration` ramps during attack

## Fix

In `A2 PolyphonicVoice.swift`, change the attack-phase ramp duration from `remainingAttack` to `ControlRateConfig.modulationRampDuration` in two places:

### 1. `applyCombinedModulationIndex` — ramp duration calculation

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

### 2. `applyCombinedFilterFrequency` — ramp duration calculation

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

## Why This Works

The modulation loop's calculated target values already track the linear attack curve at control rate. Since each cycle's target closely matches the previous one, short 10ms ramps produce the same smooth attack as the long ramps did — but without the artifact when transitioning to release.
