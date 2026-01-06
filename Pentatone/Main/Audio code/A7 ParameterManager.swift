//
//  A1.5 ParameterManager.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 04/01/2026.
//

import Foundation
import Combine
import AudioKit
import DunneAudioKit
import AudioKitEX
import SoundpipeAudioKit

// MARK: - Parameter Manager

/// Central manager for all audio parameters
/// This provides the interface between UI and the AudioKit engine
@MainActor
final class AudioParameterManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AudioParameterManager()
    
    // MARK: - Current Parameters
    
    /// Current master parameters (delay, reverb)
    @Published private(set) var master: MasterParameters = .default
    
    /// Current voice template - used as base for all voices
    @Published private(set) var voiceTemplate: VoiceParameters = .default
    
    /// Current macro control state
    @Published private(set) var macroState: MacroControlState = .default
    
    // MARK: - Initialization
    
    private init() {
        // Private to enforce singleton
    }
    
    // MARK: - Master Parameter Updates
    
    func updateDelay(_ parameters: DelayParameters) {
        master.delay = parameters
        applyDelayParameters()
    }
    /* deprecated, now uses separate drywetmixer
    func updateDelayMix(_ mix: Double) {
        master.delay.dryWetMix = mix
        fxDelay?.dryWetMix = AUValue(1-mix)
    }
    */
    func updateDelayTimeValue(_ timeValue: DelayTimeValue) {
        master.delay.timeValue = timeValue
        // Calculate actual time in seconds and apply to engine
        let timeInSeconds = timeValue.timeInSeconds(tempo: master.tempo)
        fxDelay?.time = AUValue(timeInSeconds)
        // Update base delay time in voice pool for LFO modulation
        voicePool?.updateBaseDelayTime(timeInSeconds)
    }
    
    func updateDelayFeedback(_ feedback: Double) {
        master.delay.feedback = feedback
        fxDelay?.feedback = AUValue(feedback)
    }
    
    func updateDelayToneCutoff(_ cutoff: Double) {
        master.delay.toneCutoff = cutoff
        delayLowpass?.cutoffFrequency = AUValue(cutoff)
    }
    
    func updateDelayMix(_ mix: Double) {
        master.delay.dryWetMix = mix
        delayDryWetMixer?.balance = AUValue(mix)
    }
    
    func updateReverb(_ parameters: ReverbParameters) {
        master.reverb = parameters
        applyReverbParameters()
    }
    
    func updateReverbMix(_ balance: Double) {
        master.reverb.balance = balance
        fxReverb?.balance = AUValue(balance)
    }
    
    func updateReverbFeedback(_ feedback: Double) {
        master.reverb.feedback = feedback
        fxReverb?.feedback = AUValue(feedback)
    }
    
    func updateReverbCutoff(_ cutoff: Double) {
        master.reverb.cutoffFrequency = cutoff
        fxReverb?.cutoffFrequency = AUValue(cutoff)
    }
    
    func updateOutputVolume(_ volume: Double) {
        master.output.volume = volume
        outputMixer?.volume = AUValue(volume)
    }
    
    func updatePreVolume(_ preVolume: Double) {
        master.output.preVolume = preVolume
        // Update voice pool's base preVolume for global LFO tremolo
        voicePool?.updateBasePreVolume(preVolume)
        // Note: If global LFO tremolo is active, it will modulate from this new base
        // If not active, updateBasePreVolume will apply it directly to the mixer
    }
    
    func updateTempo(_ tempo: Double) {
        master.tempo = tempo
        // Recalculate and apply delay time with new tempo
        let timeInSeconds = master.delay.timeInSeconds(tempo: tempo)
        fxDelay?.time = AUValue(timeInSeconds)
        // Update base delay time in voice pool for LFO modulation
        voicePool?.updateBaseDelayTime(timeInSeconds)
        
        // Recalculate and apply global LFO frequency if in sync mode
        if master.globalLFO.resetMode == .sync {
            let lfoFrequency = master.globalLFO.actualFrequency(tempo: tempo)
            master.globalLFO.frequency = lfoFrequency  // Update the master copy too!
            voicePool?.updateGlobalLFOFrequency(lfoFrequency)
        }
    }
    
    // MARK: - Voice Mode Updates
    
    /// Update voice mode (monophonic/polyphonic)
    /// This requires recreating the voice pool with the new voice count
    func updateVoiceMode(_ mode: VoiceMode, completion: @escaping () -> Void = {}) {
        // Update the parameter
        master.voiceMode = mode
        
        // Calculate new voice count
        let newVoiceCount: Int
        switch mode {
        case .monophonic:
            newVoiceCount = 1
        case .polyphonic:
            newVoiceCount = nominalPolyphony
        }
        
        // Update the voice pool
        voicePool?.setPolyphony(newVoiceCount) {
            print("🎵 Voice mode switched to \(mode.displayName)")
            completion()
        }
    }
    
    // MARK: - Global Pitch Updates
    
    func updateGlobalPitch(_ parameters: GlobalPitchParameters) {
        master.globalPitch = parameters
    }
    
    func updateTranspose(_ transpose: Double) {
        master.globalPitch.transpose = transpose
    }
    
    func updateTransposeSemitones(_ semitones: Int) {
        var pitch = master.globalPitch
        pitch.setTransposeSemitones(semitones)
        master.globalPitch = pitch
    }
    
    func updateOctave(_ octave: Double) {
        master.globalPitch.octave = octave
    }
    
    func updateOctaveOffset(_ offset: Int) {
        var pitch = master.globalPitch
        pitch.setOctaveOffset(offset)
        master.globalPitch = pitch
    }
    
    func updateFineTune(_ fineTune: Double) {
        master.globalPitch.fineTune = fineTune
    }
    
    func updateFineTuneCents(_ cents: Double) {
         var pitch = master.globalPitch
        pitch.setFineTuneCents(cents)
        master.globalPitch = pitch
     }
    
    // MARK: - Voice Template Updates
    
    /// Update the voice template (new voices will use these parameters)
    /// Note: Does not affect currently playing voices - only new voice allocations
    func updateVoiceTemplate(_ parameters: VoiceParameters) {
        voiceTemplate = parameters
    }
    
    func updateTemplateFilter(_ parameters: FilterParameters) {
        voiceTemplate.filter = parameters
    }
    
    func updateTemplateFilterStatic(_ parameters: FilterStaticParameters) {
        voiceTemplate.filterStatic = parameters
    }
    
    func updateTemplateOscillator(_ parameters: OscillatorParameters) {
        voiceTemplate.oscillator = parameters
    }
    
    func updateTemplateEnvelope(_ parameters: EnvelopeParameters) {
        voiceTemplate.envelope = parameters
    }
    
    // MARK: - Individual Oscillator Parameter Updates
    
    /// Update oscillator waveform
    func updateOscillatorWaveform(_ waveform: OscillatorWaveform) {
        voiceTemplate.oscillator.waveform = waveform
    }
    
    /// Update carrier multiplier
    func updateCarrierMultiplier(_ value: Double) {
        voiceTemplate.oscillator.carrierMultiplier = value
    }
    
    /// Update modulating multiplier
    func updateModulatingMultiplier(_ value: Double) {
        voiceTemplate.oscillator.modulatingMultiplier = value
    }
    
    /// Update modulation index (base level)
    func updateModulationIndex(_ value: Double) {
        voiceTemplate.oscillator.modulationIndex = value
    }
    
    /// Update detune mode
    func updateDetuneMode(_ mode: DetuneMode) {
        voiceTemplate.oscillator.detuneMode = mode
    }
    
    /// Update stereo offset (proportional)
    func updateStereoOffsetProportional(_ value: Double) {
        voiceTemplate.oscillator.stereoOffsetProportional = value
    }
    
    /// Update stereo offset (constant)
    func updateStereoOffsetConstant(_ value: Double) {
        voiceTemplate.oscillator.stereoOffsetConstant = value
    }
    
    // MARK: - Individual Envelope Parameter Updates
    
    /// Update envelope attack duration
    func updateEnvelopeAttack(_ value: Double) {
        voiceTemplate.envelope.attackDuration = value
    }
    
    /// Update envelope decay duration
    func updateEnvelopeDecay(_ value: Double) {
        voiceTemplate.envelope.decayDuration = value
    }
    
    /// Update envelope sustain level
    func updateEnvelopeSustain(_ value: Double) {
        voiceTemplate.envelope.sustainLevel = value
    }
    
    /// Update envelope release duration
    func updateEnvelopeRelease(_ value: Double) {
        voiceTemplate.envelope.releaseDuration = value
    }
    
    // MARK: - Individual Filter Parameter Updates
    
    /// Update filter cutoff frequency (MODULATABLE parameter)
    func updateFilterCutoff(_ value: Double) {
        voiceTemplate.filter.cutoffFrequency = value
        // VoicePool updates all voices immediately to ensure consistent state
        voicePool?.updateAllVoiceFilters(voiceTemplate.filter)
    }
    
    /// Update filter resonance (NON-MODULATABLE, NOTE-ON parameter)
    func updateFilterResonance(_ value: Double) {
        voiceTemplate.filterStatic.resonance = value
        voicePool?.updateAllVoiceFilterStatic(voiceTemplate.filterStatic)
    }
    
    /// Update filter saturation (NON-MODULATABLE, NOTE-ON parameter)
    func updateFilterSaturation(_ value: Double) {
        voiceTemplate.filterStatic.saturation = value
        voicePool?.updateAllVoiceFilterStatic(voiceTemplate.filterStatic)
    }
    
    // MARK: - Individual Modulation Parameter Updates
    
    /// Update modulator envelope attack
    func updateModulatorEnvelopeAttack(_ value: Double) {
        voiceTemplate.modulation.modulatorEnvelope.attack = value
    }
    
    /// Update modulator envelope decay
    func updateModulatorEnvelopeDecay(_ value: Double) {
        voiceTemplate.modulation.modulatorEnvelope.decay = value
    }
    
    /// Update modulator envelope sustain
    func updateModulatorEnvelopeSustain(_ value: Double) {
        voiceTemplate.modulation.modulatorEnvelope.sustain = value
    }
    
    /// Update modulator envelope release
    func updateModulatorEnvelopeRelease(_ value: Double) {
        voiceTemplate.modulation.modulatorEnvelope.release = value
    }
    
    /// Update modulator envelope amount to modulation index
    func updateModulatorEnvelopeAmountToModulationIndex(_ value: Double) {
        voiceTemplate.modulation.modulatorEnvelope.amountToModulationIndex = value
    }
    
    
    /// Update key tracking amount to filter frequency
    func updateKeyTrackingAmountToFilterFrequency(_ value: Double) {
        voiceTemplate.modulation.keyTracking.amountToFilterFrequency = value
    }
    
    /// Update key tracking amount to voice LFO frequency
    func updateKeyTrackingAmountToVoiceLFOFrequency(_ value: Double) {
        voiceTemplate.modulation.keyTracking.amountToVoiceLFOFrequency = value
    }
  
    
    /// Update key tracking enabled state
    func updateKeyTrackingEnabled(_ enabled: Bool) {
        voiceTemplate.modulation.keyTracking.isEnabled = enabled
    }
    
    /// Update auxiliary envelope attack
    func updateAuxiliaryEnvelopeAttack(_ value: Double) {
        voiceTemplate.modulation.auxiliaryEnvelope.attack = value
    }
    
    /// Update auxiliary envelope decay
    func updateAuxiliaryEnvelopeDecay(_ value: Double) {
        voiceTemplate.modulation.auxiliaryEnvelope.decay = value
    }
    
    /// Update auxiliary envelope sustain
    func updateAuxiliaryEnvelopeSustain(_ value: Double) {
        voiceTemplate.modulation.auxiliaryEnvelope.sustain = value
    }
    
    /// Update auxiliary envelope release
    func updateAuxiliaryEnvelopeRelease(_ value: Double) {
        voiceTemplate.modulation.auxiliaryEnvelope.release = value
    }
    
    /// Update auxiliary envelope amount to oscillator pitch
    func updateAuxiliaryEnvelopeAmountToPitch(_ value: Double) {
        voiceTemplate.modulation.auxiliaryEnvelope.amountToOscillatorPitch = value
    }
    
    /// Update auxiliary envelope amount to filter frequency
    func updateAuxiliaryEnvelopeAmountToFilter(_ value: Double) {
        voiceTemplate.modulation.auxiliaryEnvelope.amountToFilterFrequency = value
    }
    
    /// Update auxiliary envelope amount to vibrato (voice LFO pitch amount)
    func updateAuxiliaryEnvelopeAmountToVibrato(_ value: Double) {
        voiceTemplate.modulation.auxiliaryEnvelope.amountToVibrato = value
    }
    
    
    /// Update voice LFO waveform
    func updateVoiceLFOWaveform(_ waveform: LFOWaveform) {
        voiceTemplate.modulation.voiceLFO.waveform = waveform
    }
    
    /// Update voice LFO reset mode
    func updateVoiceLFOResetMode(_ mode: LFOResetMode) {
        voiceTemplate.modulation.voiceLFO.resetMode = mode
    }
    
    /// Update voice LFO frequency (always in Hz, no tempo sync)
    func updateVoiceLFOFrequency(_ value: Double) {
        voiceTemplate.modulation.voiceLFO.frequency = value
    }
    
    /// Update voice LFO delay time (ramp time)
    func updateVoiceLFODelayTime(_ value: Double) {
        voiceTemplate.modulation.voiceLFO.delayTime = value
    }
    
    /// Update voice LFO amount to oscillator pitch
    func updateVoiceLFOAmountToPitch(_ value: Double) {
        voiceTemplate.modulation.voiceLFO.amountToOscillatorPitch = value
    }
    
    /// Update voice LFO amount to filter frequency
    func updateVoiceLFOAmountToFilter(_ value: Double) {
        voiceTemplate.modulation.voiceLFO.amountToFilterFrequency = value
    }
    
    /// Update voice LFO amount to modulator level
    func updateVoiceLFOAmountToModulatorLevel(_ value: Double) {
        let wasZero = voiceTemplate.modulation.voiceLFO.amountToModulatorLevel == 0.0
        voiceTemplate.modulation.voiceLFO.amountToModulatorLevel = value
        
        // If amount changed from non-zero to zero, reset parameter to base value
        if !wasZero && value == 0.0 {
            voicePool?.resetModulationIndexToBase()
        }
    }
     
    /// Update voice LFO enabled state
    func updateVoiceLFOEnabled(_ enabled: Bool) {
        voiceTemplate.modulation.voiceLFO.isEnabled = enabled
    }
    
    // MARK: - Global LFO Parameter Updates
    
    /// Update global LFO waveform
    func updateGlobalLFOWaveform(_ waveform: LFOWaveform) {
        master.globalLFO.waveform = waveform
        voicePool?.updateGlobalLFO(master.globalLFO)
    }
    
    /// Update global LFO reset mode
    func updateGlobalLFOResetMode(_ mode: LFOResetMode) {
        master.globalLFO.resetMode = mode
        // When switching to sync mode, recalculate frequency from sync value
        // When switching from sync mode, keep the current Hz frequency
        if mode == .sync {
            let lfoFrequency = master.globalLFO.actualFrequency(tempo: master.tempo)
            master.globalLFO.frequency = lfoFrequency  // Update the master copy too!
            voicePool?.updateGlobalLFOFrequency(lfoFrequency)
        }
        voicePool?.updateGlobalLFO(master.globalLFO)
    }
    
    /// Update global LFO frequency mode
    func updateGlobalLFOFrequencyMode(_ mode: LFOFrequencyMode) {
        master.globalLFO.frequencyMode = mode
        voicePool?.updateGlobalLFO(master.globalLFO)
    }
    
    /// Update global LFO frequency (Hz value for free mode)
    func updateGlobalLFOFrequency(_ value: Double) {
        master.globalLFO.frequency = value
        // Only apply if not in sync mode
        if master.globalLFO.resetMode != .sync {
            voicePool?.updateGlobalLFOFrequency(value)
        }
        voicePool?.updateGlobalLFO(master.globalLFO)
    }
    
    /// Update global LFO sync value (for sync mode)
    func updateGlobalLFOSyncValue(_ syncValue: LFOSyncValue) {
        master.globalLFO.syncValue = syncValue
        // Calculate actual frequency from sync value and apply
        let lfoFrequency = syncValue.frequencyInHz(tempo: master.tempo)
        master.globalLFO.frequency = lfoFrequency  // Update the master copy too!
        voicePool?.updateGlobalLFOFrequency(lfoFrequency)
        voicePool?.updateGlobalLFO(master.globalLFO)
    }
    
    /// Update global LFO amount to voice mixer volume (tremolo)
    func updateGlobalLFOAmountToMixerVolume(_ value: Double) {
        let wasZero = master.globalLFO.amountToVoiceMixerVolume == 0.0
        master.globalLFO.amountToVoiceMixerVolume = value
        voicePool?.updateGlobalLFO(master.globalLFO)
        
        // If amount is now zero, reset mixer volume to base
        if value == 0.0 && !wasZero {
            voicePool?.resetMixerVolumeToBase()
        }
    }
    
    /// Update global LFO amount to modulator multiplier
    func updateGlobalLFOAmountToModulatorMultiplier(_ value: Double) {
        let wasZero = master.globalLFO.amountToModulatorMultiplier == 0.0
        master.globalLFO.amountToModulatorMultiplier = value
        voicePool?.updateGlobalLFO(master.globalLFO)
        
        // If amount changed from non-zero to zero, reset parameter to base value
        if !wasZero && value == 0.0 {
            voicePool?.resetModulatorMultiplierToBase()
        }
    }
    
    /// Update global LFO amount to filter frequency
    func updateGlobalLFOAmountToFilter(_ value: Double) {
        master.globalLFO.amountToFilterFrequency = value
        voicePool?.updateGlobalLFO(master.globalLFO)
    }
    
    /// Update global LFO amount to delay time
    func updateGlobalLFOAmountToDelayTime(_ value: Double) {
        let wasZero = master.globalLFO.amountToDelayTime == 0.0
        master.globalLFO.amountToDelayTime = value
        voicePool?.updateGlobalLFO(master.globalLFO)
        
        // If amount changed from non-zero to zero, reset parameter to base value
        if !wasZero && value == 0.0 {
            voicePool?.resetDelayTimeToBase()
        }
    }
    /*
    /// Update global LFO destination (deprecated - destinations are now fixed)
    @available(*, deprecated, message: "Global LFO destinations are now fixed")
    func updateGlobalLFODestination(_ destination: ModulationDestination) {
        // No-op: destinations are now fixed
    }
    
    /// Update global LFO amount (deprecated - use specific amount methods)
    @available(*, deprecated, message: "Use updateGlobalLFOAmountToMixerVolume, AmountToModulatorMultiplier, AmountToFilter, or AmountToDelayTime")
    func updateGlobalLFOAmount(_ value: Double) {
        // Default to mixer volume for backward compatibility
        master.globalLFO.amountToVoiceMixerVolume = value
    }
    */
    
    /// Update global LFO enabled state
    func updateGlobalLFOEnabled(_ enabled: Bool) {
        master.globalLFO.isEnabled = enabled
    }
    
    // MARK: - Touch Response Parameter Updates
    
    /// Update initial touch amount to oscillator amplitude
    func updateInitialTouchAmountToAmplitude(_ value: Double) {
        voiceTemplate.modulation.touchInitial.amountToOscillatorAmplitude = value
    }
    
    /// Update initial touch amount to mod envelope
    func updateInitialTouchAmountToModEnvelope(_ value: Double) {
        voiceTemplate.modulation.touchInitial.amountToModEnvelope = value
    }
    
    /// Update initial touch amount to aux envelope pitch
    func updateInitialTouchAmountToAuxEnvPitch(_ value: Double) {
        voiceTemplate.modulation.touchInitial.amountToAuxEnvPitch = value
    }
    
    /// Update initial touch amount to aux envelope cutoff
    func updateInitialTouchAmountToAuxEnvCutoff(_ value: Double) {
        voiceTemplate.modulation.touchInitial.amountToAuxEnvCutoff = value
    }
    
    /// Update aftertouch amount to filter frequency
    func updateAftertouchAmountToFilter(_ value: Double) {
        voiceTemplate.modulation.touchAftertouch.amountToFilterFrequency = value
    }
    
    /// Update aftertouch amount to modulator level
    func updateAftertouchAmountToModulatorLevel(_ value: Double) {
        voiceTemplate.modulation.touchAftertouch.amountToModulatorLevel = value
    }
    
    /// Update aftertouch amount to vibrato
    func updateAftertouchAmountToVibrato(_ value: Double) {
        voiceTemplate.modulation.touchAftertouch.amountToVibrato = value
    }

    // MARK: - Macro Control Updates
    
    /// Update macro control parameter ranges
    func updateMacroControlParameters(_ parameters: MacroControlParameters) {
        master.macroControl = parameters
    }
    
    /// Update tone to modulation index range
    func updateToneToModulationIndexRange(_ value: Double) {
        master.macroControl.toneToModulationIndexRange = value
    }
    
    /// Update tone to filter cutoff octaves
    func updateToneToFilterCutoffOctaves(_ value: Double) {
        master.macroControl.toneToFilterCutoffOctaves = value
    }
    
    /// Update tone to filter saturation range
    func updateToneToFilterSaturationRange(_ value: Double) {
        master.macroControl.toneToFilterSaturationRange = value
    }
    
    /// Update ambience to delay feedback range
    func updateAmbienceToDelayFeedbackRange(_ value: Double) {
        master.macroControl.ambienceToDelayFeedbackRange = value
    }
    
    /// Update ambience to delay mix range
    func updateAmbienceToDelayMixRange(_ value: Double) {
        master.macroControl.ambienceToDelayMixRange = value
    }
    
    /// Update ambience to reverb feedback range
    func updateAmbienceToReverbFeedbackRange(_ value: Double) {
        master.macroControl.ambienceToReverbFeedbackRange = value
    }
    
    /// Update ambience to reverb mix range
    func updateAmbienceToReverbMixRange(_ value: Double) {
        master.macroControl.ambienceToReverbMixRange = value
    }
    
    // MARK: - Macro Control Position Updates
    
    /// Update volume macro position and apply to parameters
    /// Position is absolute (0.0 to 1.0)
    func updateVolumeMacro(_ position: Double) {
        // Volume is straightforward - directly maps to preVolume
        let clampedPosition = min(max(position, 0.0), 1.0)
        macroState.volumePosition = clampedPosition
        
        // Apply directly to preVolume and update master parameter
        master.output.preVolume = clampedPosition
        // Update voice pool's base preVolume for global LFO tremolo
        voicePool?.updateBasePreVolume(clampedPosition)
        // Note: If global LFO tremolo is active, it will modulate from this new base
    }
    
    
    /// Update tone macro position and apply to parameters
    /// Position is relative (-1.0 to +1.0, where 0 is neutral)
    func updateToneMacro(_ position: Double) {
        let clampedPosition = min(max(position, -1.0), 1.0)
        macroState.tonePosition = clampedPosition
        
        // Apply tone adjustments
        applyToneMacro()
    }
    
    /// Update ambience macro position and apply to parameters
    /// Position is relative (-1.0 to +1.0, where 0 is neutral)
    func updateAmbienceMacro(_ position: Double) {
        let clampedPosition = min(max(position, -1.0), 1.0)
        macroState.ambiencePosition = clampedPosition
        
        // Apply ambience adjustments
        applyAmbienceMacro()
    }
    
    /// Capture current parameter values as base values for macro controls
    /// Should be called when loading a preset or when user edits parameters directly
    /// This resets macro positions and uses current parameters as the new baseline
    func captureBaseValues() {
        // Create a fresh macro state from current parameters
        macroState = MacroControlState(from: voiceTemplate, masterParams: master)
    }
    
    /// Update macro state to match current parameters without resetting positions
    /// Use this when you want to sync base values but keep the current macro positions
    func syncMacroBaseValues() {
        macroState.baseModulationIndex = voiceTemplate.oscillator.modulationIndex
        macroState.baseFilterCutoff = voiceTemplate.filter.cutoffFrequency
        macroState.baseFilterSaturation = voiceTemplate.filterStatic.saturation
        macroState.baseDelayFeedback = master.delay.feedback
        macroState.baseDelayMix = master.delay.dryWetMix
        macroState.baseReverbFeedback = master.reverb.feedback
        macroState.baseReverbMix = master.reverb.balance
        macroState.basePreVolume = master.output.preVolume
        // Note: positions are NOT reset
    }
    
    // MARK: - Private Macro Application Methods
    
    /// Apply tone macro to modulation index, filter cutoff, and saturation
    private func applyToneMacro() {
        let position = macroState.tonePosition
        let ranges = master.macroControl
        
        // Modulation Index: base +/- range
        let newModIndex = macroState.baseModulationIndex + (position * ranges.toneToModulationIndexRange)
        let clampedModIndex = min(max(newModIndex, 0.0), 10.0)
        updateModulationIndex(clampedModIndex)
        
        // Filter Cutoff: base * 2^(position * octaves)
        // Moving up increases frequency, moving down decreases
        let octaveMultiplier = pow(2.0, position * ranges.toneToFilterCutoffOctaves)
        let newCutoff = macroState.baseFilterCutoff * octaveMultiplier
        let clampedCutoff = min(max(newCutoff, 20.0), 20000.0)
        updateFilterCutoff(clampedCutoff)
        
        // Filter Saturation: base +/- range
        let newSaturation = macroState.baseFilterSaturation + (position * ranges.toneToFilterSaturationRange)
        let clampedSaturation = min(max(newSaturation, 0.0), 10.0)
        updateFilterSaturation(clampedSaturation)
        
        // Apply oscillator changes to all voices
        applyOscillatorToAllVoices()
        
        // Filter changes are already applied by updateFilterCutoff/Saturation calls above
        // No need for separate applyFilterToAllVoices() call
    }
    
    /// Apply ambience macro to delay and reverb parameters
    private func applyAmbienceMacro() {
        let position = macroState.ambiencePosition
        let ranges = master.macroControl
        
        // Delay Feedback: base +/- range
        let newDelayFeedback = macroState.baseDelayFeedback + (position * ranges.ambienceToDelayFeedbackRange)
        let clampedDelayFeedback = min(max(newDelayFeedback, 0.0), 1.0)
        updateDelayFeedback(clampedDelayFeedback)
        
        // Delay Mix: base +/- range
        let newDelayMix = macroState.baseDelayMix + (position * ranges.ambienceToDelayMixRange)
        let clampedDelayMix = min(max(newDelayMix, 0.0), 1.0)
        updateDelayMix(clampedDelayMix)
        
        // Reverb Feedback: base +/- range
        let newReverbFeedback = macroState.baseReverbFeedback + (position * ranges.ambienceToReverbFeedbackRange)
        let clampedReverbFeedback = min(max(newReverbFeedback, 0.0), 1.0)
        updateReverbFeedback(clampedReverbFeedback)
        
        // Reverb Mix: base +/- range
        let newReverbMix = macroState.baseReverbMix + (position * ranges.ambienceToReverbMixRange)
        let clampedReverbMix = min(max(newReverbMix, 0.0), 1.0)
        updateReverbMix(clampedReverbMix)
    }
    
    /// Apply oscillator parameters to all voices
    private func applyOscillatorToAllVoices() {
        let params = voiceTemplate.oscillator
        voicePool?.updateAllVoiceOscillators(params)
    }
    
    // MARK: - Preset Management
    
    /// Load a complete parameter set (preset)
    func loadPreset(_ preset: AudioParameterSet) {
        voiceTemplate = preset.voiceTemplate
        master = preset.master
        macroState = preset.macroState
        
        applyAllParameters()
    }
    
    /// Create a preset from current parameters
    func createPreset(named name: String) -> AudioParameterSet {
        AudioParameterSet(
            id: UUID(),
            name: name,
            voiceTemplate: voiceTemplate,
            master: master,
            macroState: macroState,
            createdAt: Date()
        )
    }
    
    // MARK: - Application to AudioKit
    
    /// Apply all parameters to the audio engine
    private func applyAllParameters() {
        applyDelayParameters()
        applyReverbParameters()
    }
    
    private func applyDelayParameters() {
        guard let delay = fxDelay else { return }
        // Calculate time in seconds based on current tempo
        let timeInSeconds = master.delay.timeInSeconds(tempo: master.tempo)
        delay.time = AUValue(timeInSeconds)
        delay.feedback = AUValue(master.delay.feedback)
        // Note: delay.dryWetMix is now fixed at 0.0 (100% wet) - controlled by external mixer
        
        // Update filter
        delayLowpass?.cutoffFrequency = AUValue(master.delay.toneCutoff)
        
        // Update dry/wet mixer
        delayDryWetMixer?.balance = AUValue(master.delay.dryWetMix)
        
        // Update base delay time in voice pool for LFO modulation
        voicePool?.updateBaseDelayTime(timeInSeconds)
    }
    
    private func applyReverbParameters() {
        guard let reverb = fxReverb else { return }
        reverb.feedback = AUValue(master.reverb.feedback)
        reverb.cutoffFrequency = AUValue(master.reverb.cutoffFrequency)
        reverb.balance = AUValue(master.reverb.balance)
    }
}
