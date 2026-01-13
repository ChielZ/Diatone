//
//  A2 PolyphonicVoice.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 20/12/2025.
//

import AudioKit
import SoundpipeAudioKit
import AudioKitEX
import AVFAudio
import DunneAudioKit

// MARK: - Detune Mode

/// Defines how stereo spread is calculated
enum DetuneMode: String, CaseIterable, Codable {
    case proportional  // Constant cents (natural, more beating at higher pitches)
    case constant      // Constant Hz (uniform beating across all pitches)
    
    var displayName: String {
        switch self {
        case .proportional: return "Proportional (Cents)"
        case .constant: return "Constant (Hz)"
        }
    }
    
    var description: String {
        switch self {
        case .proportional: return "More beating at higher notes (natural)"
        case .constant: return "Same beat rate for all notes (uniform)"
        }
    }
}

/// A single voice in the polyphonic synthesizer with stereo dual-oscillator architecture
/// Signal path: [Osc Left (hard L) + Osc Right (hard R)] → Stereo Mixer → Filter → Envelope
final class PolyphonicVoice {
    
    // MARK: - Audio Nodes
    
    /// Left oscillator (will be panned hard left)
    var oscLeft: FMOscillator
    
    /// Right oscillator (will be panned hard right)
    var oscRight: FMOscillator
    
    /// Panner for left oscillator (hard left)
    private var panLeft: Panner
    
    /// Panner for right oscillator (hard right)
    private var panRight: Panner
    
    /// Stereo mixer to combine panned oscillators
    private let stereoMixer: Mixer
    
    /// Low-pass filter processing the stereo signal
    let filter: ThreePoleLowpassFilter
    
    /// Amplitude envelope shaping the stereo signal
    let envelope: AmplitudeEnvelope
    
    // MARK: - Voice State
    
    /// Whether this voice is available for allocation
    var isAvailable: Bool = true
    
    /// The current base frequency (center frequency between left and right oscillators)
    private(set) var currentFrequency: Double = 440.0
    
    /// Timestamp when this voice was last triggered (for voice stealing)
    private(set) var triggerTime: Date = Date()
    
    /// Whether the voice has been initialized (oscillators started)
    private var isInitialized: Bool = false
    
    // MARK: - Parameters
    
    /// Detune mode determines how stereo spread is calculated
    var detuneMode: DetuneMode {
        didSet {
            if isInitialized {
                updateOscillatorFrequencies()
            }
        }
    }
    
    /// Frequency offset for PROPORTIONAL mode (cents)
    /// 0 = no offset (both oscillators at same frequency)
    /// 10 = ±10 cents (20 cents total spread)
    /// Left oscillator gets +cents, right gets -cents
    var frequencyOffsetCents: Double {
        didSet {
            if isInitialized && detuneMode == .proportional {
                updateOscillatorFrequencies()
            }
        }
    }
    
    /// Frequency offset for CONSTANT mode (Hz)
    /// 0 Hz = no offset (mono)
    /// 2 Hz = 4 Hz beat rate (2 Hz each side)
    /// 5 Hz = 10 Hz beat rate (5 Hz each side)
    /// Left oscillator adds this value, right subtracts it
    var frequencyOffsetHz: Double {
        didSet {
            if isInitialized && detuneMode == .constant {
                updateOscillatorFrequencies()
            }
        }
    }
    
    // MARK: - Modulation (Phase 5 - placeholder)
    
    /// Modulation parameters for this voice (Phase 5)
    var voiceModulation: VoiceModulationParameters = .default
    
    /// Modulation runtime state (Phase 5)
    var modulationState: ModulationState = ModulationState()
    
    // MARK: - Initialization
    
    init(parameters: VoiceParameters = .default) {
        // Initialize stereo detune parameters from template
        self.detuneMode = parameters.oscillator.detuneMode
        self.frequencyOffsetCents = parameters.oscillator.stereoOffsetProportional
        self.frequencyOffsetHz = parameters.oscillator.stereoOffsetConstant
        
        // Create left oscillator
        self.oscLeft = FMOscillator(
            waveform: parameters.oscillator.waveform.makeTable(),
            baseFrequency: AUValue(currentFrequency),
            carrierMultiplier: AUValue(parameters.oscillator.carrierMultiplier),
            modulatingMultiplier: AUValue(parameters.oscillator.modulatingMultiplier),
            modulationIndex: AUValue(parameters.oscillator.modulationIndex),
            amplitude: AUValue(parameters.oscillator.amplitude)
        )
        
        // Create right oscillator (identical parameters, different frequency offset)
        self.oscRight = FMOscillator(
            waveform: parameters.oscillator.waveform.makeTable(),
            baseFrequency: AUValue(currentFrequency),
            carrierMultiplier: AUValue(parameters.oscillator.carrierMultiplier),
            modulatingMultiplier: AUValue(parameters.oscillator.modulatingMultiplier),
            modulationIndex: AUValue(parameters.oscillator.modulationIndex),
            amplitude: AUValue(parameters.oscillator.amplitude)
        )
        
        // Pan oscillators hard left and right
        self.panLeft = Panner(oscLeft, pan: -1.0)  // Hard left
        self.panRight = Panner(oscRight, pan: 1.0)  // Hard right
        
        // Create stereo mixer to combine panned oscillators
        self.stereoMixer = Mixer(panLeft, panRight)
        
        // Create filter processing the stereo signal
        self.filter = ThreePoleLowpassFilter(
            stereoMixer,
            distortion: AUValue(parameters.filterStatic.clampedSaturation),  // use saturation slot for distortion
            cutoffFrequency: AUValue(parameters.filter.clampedCutoff),
            resonance: AUValue(parameters.filterStatic.clampedResonance)
        )

        // Create envelope shaping the stereo signal
        self.envelope = AmplitudeEnvelope(
            filter,
            attackDuration: AUValue(parameters.envelope.attackDuration),
            decayDuration: AUValue(parameters.envelope.decayDuration),
            sustainLevel: AUValue(parameters.envelope.sustainLevel),
            releaseDuration: AUValue(parameters.envelope.releaseDuration)
        )
        
        // Initialize base values in modulation state
        modulationState.baseAmplitude = parameters.oscillator.amplitude
        modulationState.baseFilterCutoff = parameters.filter.clampedCutoff
        modulationState.baseModulationIndex = parameters.oscillator.modulationIndex
    }
    
    // MARK: - Initialization
    
    /// Initializes the voice (starts oscillators)
    /// Must be called after audio engine is started but before first use
    func initialize() {
        guard !isInitialized else { return }
        
        // Set ramp duration to 0 for instant frequency changes (no pitch sliding)
        oscLeft.$baseFrequency.ramp(to: Float(currentFrequency), duration: 0)
        oscRight.$baseFrequency.ramp(to: Float(currentFrequency), duration: 0)
        
        // Also disable ramping for other parameters to ensure instant response
        oscLeft.$amplitude.ramp(to: oscLeft.amplitude, duration: 0)
        oscRight.$amplitude.ramp(to: oscRight.amplitude, duration: 0)
        
        oscLeft.start()
        oscRight.start()
        isInitialized = true
        
        // Apply initial frequency with offset
        updateOscillatorFrequencies()
    }
    
    /// Cleanup method to safely stop and disconnect this voice
    /// Should be called before destroying the voice
    func cleanup() {
        if isInitialized {
            oscLeft.stop()
            oscRight.stop()
            isInitialized = false
        }
        isAvailable = true
    }
    
    // MARK: - Oscillator Recreation
    
    /// Recreates the oscillators with a new waveform while keeping the rest of the voice intact
    /// This allows waveform changes without recreating the entire voice
    /// - Parameter waveform: The new waveform to use
    func recreateOscillators(waveform: OscillatorWaveform) {
        print("🎵 Recreating oscillators for voice with new waveform: \(waveform)")
        
        // Store current state before recreation
        let wasInitialized = isInitialized
        let currentBaseFreq = currentFrequency
        let currentAmplitude = oscLeft.amplitude
        let currentCarrierMult = oscLeft.carrierMultiplier
        let currentModulatingMult = oscLeft.modulatingMultiplier
        let currentModIndex = oscLeft.modulationIndex
        
        // Stop and disconnect old oscillators
        if isInitialized {
            oscLeft.stop()
            oscRight.stop()
        }
        
        // Disconnect old panners from stereo mixer
        stereoMixer.removeInput(panLeft)
        stereoMixer.removeInput(panRight)
        
        // Explicitly detach old panners and oscillators to ensure proper cleanup
        // This helps AudioKit release internal references and prevents memory buildup
        panLeft.detach()
        panRight.detach()
        oscLeft.detach()
        oscRight.detach()
        
        // Create new oscillators with the new waveform
        let newOscLeft = FMOscillator(
            waveform: waveform.makeTable(),
            baseFrequency: AUValue(currentBaseFreq),
            carrierMultiplier: currentCarrierMult,
            modulatingMultiplier: currentModulatingMult,
            modulationIndex: currentModIndex,
            amplitude: currentAmplitude
        )
        
        let newOscRight = FMOscillator(
            waveform: waveform.makeTable(),
            baseFrequency: AUValue(currentBaseFreq),
            carrierMultiplier: currentCarrierMult,
            modulatingMultiplier: currentModulatingMult,
            modulationIndex: currentModIndex,
            amplitude: currentAmplitude
        )
        
        // Create new panners with the new oscillators
        let newPanLeft = Panner(newOscLeft, pan: -1.0)  // Hard left
        let newPanRight = Panner(newOscRight, pan: 1.0)  // Hard right
        
        // Connect new panners to stereo mixer
        stereoMixer.addInput(newPanLeft)
        stereoMixer.addInput(newPanRight)
        
        // Update references (old nodes will now be deallocated by ARC)
        self.oscLeft = newOscLeft
        self.oscRight = newOscRight
        self.panLeft = newPanLeft
        self.panRight = newPanRight
        
        // Reinitialize if the voice was previously initialized
        if wasInitialized {
            // Set ramp duration to 0 for instant parameter changes
            oscLeft.$baseFrequency.ramp(to: Float(currentFrequency), duration: 0.05)
            oscRight.$baseFrequency.ramp(to: Float(currentFrequency), duration: 0.05)
            oscLeft.$amplitude.ramp(to: currentAmplitude, duration: 0.05)
            oscRight.$amplitude.ramp(to: currentAmplitude, duration: 0.05)
            
            // Start new oscillators
            oscLeft.start()
            oscRight.start()
            
            // Restore initialized state
            isInitialized = true
            
            // Apply frequency offsets
            updateOscillatorFrequencies()
            
            print("🎵   Oscillators recreated and restarted")
        } else {
            print("🎵   Oscillators recreated (not yet initialized)")
        }
    }
    
    // MARK: - Frequency Control
    
    /// Sets the base frequency for this voice
    /// Automatically applies stereo offset (left higher, right lower)
    func setFrequency(_ baseFrequency: Double) {
        currentFrequency = baseFrequency
        
        if isInitialized {
            updateOscillatorFrequencies()
        }
    }
    
    /// Updates oscillator frequencies with symmetric offset
    /// Supports both proportional (cents) and constant (Hz) detune modes
    private func updateOscillatorFrequencies() {
        let leftFreq: Double
        let rightFreq: Double
        
        switch detuneMode {
        case .proportional:
            // Constant cents: higher notes beat faster (natural)
            // Convert cents to frequency ratio: ratio = 2^(cents/1200)
            let ratio = pow(2.0, frequencyOffsetCents / 1200.0)
            // Formula: left = freq × ratio, right = freq ÷ ratio
            leftFreq = currentFrequency * ratio
            rightFreq = currentFrequency / ratio
            
        case .constant:
            // Constant Hz: all notes beat at same rate (uniform)
            // Formula: left = freq + Hz, right = freq - Hz
            leftFreq = currentFrequency + frequencyOffsetHz
            rightFreq = currentFrequency - frequencyOffsetHz
        }
        
        // Apply frequencies with 0 ramp duration for instant pitch changes
        oscLeft.$baseFrequency.ramp(to: Float(leftFreq), duration: 0)
        oscRight.$baseFrequency.ramp(to: Float(rightFreq), duration: 0)
    }
    
    // MARK: - Triggering
    
    /// Triggers this voice (starts envelope attack)
    /// - Parameters:
    ///   - initialTouchX: Initial touch x-position (0.0 = left, 1.0 = right) for velocity-like response
    ///   - templateFilterCutoff: Optional override for base filter cutoff (from current template)
    ///   - templateFilterStatic: Optional override for static filter parameters (resonance, saturation)
    func trigger(initialTouchX: Double = 0.5, templateFilterCutoff: Double? = nil, templateFilterStatic: FilterStaticParameters? = nil) {
        guard isInitialized else {
            assertionFailure("Voice must be initialized before triggering")
            return
        }
        
        // CRITICAL: Update base filter cutoff from template if provided
        // This ensures we always use the latest UI setting, not a stale value
        if let cutoff = templateFilterCutoff {
            modulationState.baseFilterCutoff = cutoff
        }
        
        // CRITICAL: Apply static filter parameters (resonance, saturation) at note-on
        // These are NOTE-ON properties - set once and never modulated
        if let filterStatic = templateFilterStatic {
            filter.$resonance.ramp(to: AUValue(filterStatic.clampedResonance), duration: 0)
            filter.$distortion.ramp(to: AUValue(filterStatic.clampedSaturation), duration: 0)
        }
        
        // CRITICAL: Set initial touch value BEFORE any calculations that depend on it
        // This ensures amplitude modulation uses the correct touch value from the start
        modulationState.initialTouchX = initialTouchX
        modulationState.currentTouchX = initialTouchX
        
        // Apply base values (unmodulated) at note trigger
        // EXCEPT amplitude - that gets immediate initial touch modulation to avoid attack transients
        
        // Calculate initial-touch-modulated amplitude immediately (zero-latency)
        // This prevents percussive artifacts on soft notes
        let immediateAmplitude: Double
        if voiceModulation.touchInitial.amountToOscillatorAmplitude != 0.0 {
            // Use ModulationRouter formula (initial touch only, no global LFO)
            immediateAmplitude = ModulationRouter.calculateOscillatorAmplitude(
                baseAmplitude: modulationState.baseAmplitude,
                initialTouchValue: initialTouchX,  // Use passed-in value directly
                initialTouchAmount: voiceModulation.touchInitial.amountToOscillatorAmplitude
            )
        } else {
            // No initial touch modulation - use base amplitude
            immediateAmplitude = modulationState.baseAmplitude
        }
        
        // Apply calculated amplitude immediately (zero-latency, no ramp)
        oscLeft.$amplitude.ramp(to: AUValue(immediateAmplitude), duration: 0)
        oscRight.$amplitude.ramp(to: AUValue(immediateAmplitude), duration: 0)
        
        // Apply unmodulated filter cutoff (modulation will be applied at control rate)
        filter.$cutoffFrequency.ramp(to: AUValue(modulationState.baseFilterCutoff), duration: 0)
        
        envelope.reset()
        envelope.openGate()
        isAvailable = false
        triggerTime = Date()
        
        // Phase 5: Initialize modulation state with the actual initial touch value
        // Note: voiceLFOPhase is only reset if LFO reset mode is .trigger or .sync
        // IMPORTANT: Pass key tracking parameters so the key tracking value is calculated ONCE at note-on
        let shouldResetLFO = voiceModulation.voiceLFO.resetMode != .free
        modulationState.reset(
            frequency: currentFrequency, 
            touchX: initialTouchX, 
            resetLFOPhase: shouldResetLFO,
            keyTrackingParams: voiceModulation.keyTracking
        )
    }
    
    /// Releases this voice (starts envelope release)
    /// The voice will be marked available after the release duration
    func release() {
        envelope.closeGate()
        
        // Capture current envelope values for smooth release using ModulationRouter
        let modulatorValue = ModulationRouter.calculateEnvelopeValue(
            time: modulationState.modulatorEnvelopeTime,
            isGateOpen: true,
            attack: voiceModulation.modulatorEnvelope.attack,
            decay: voiceModulation.modulatorEnvelope.decay,
            sustain: voiceModulation.modulatorEnvelope.sustain,
            release: voiceModulation.modulatorEnvelope.release,
            capturedLevel: 0.0  // Not used when gate is open
        )
        
        let auxiliaryValue = ModulationRouter.calculateEnvelopeValue(
            time: modulationState.auxiliaryEnvelopeTime,
            isGateOpen: true,
            attack: voiceModulation.auxiliaryEnvelope.attack,
            decay: voiceModulation.auxiliaryEnvelope.decay,
            sustain: voiceModulation.auxiliaryEnvelope.sustain,
            release: voiceModulation.auxiliaryEnvelope.release,
            capturedLevel: 0.0  // Not used when gate is open
        )
        
        modulationState.closeGate(modulatorValue: modulatorValue, auxiliaryValue: auxiliaryValue)
        
        // Mark voice available after release completes
        let releaseTime = envelope.releaseDuration
        Task {
            try? await Task.sleep(nanoseconds: UInt64(releaseTime * 1_000_000_000))
            await MainActor.run {
                self.isAvailable = true
            }
        }
    }
    
    // MARK: - Parameter Updates
    
    /// Updates oscillator parameters
    /// MODULATION-AWARE: Avoids fighting with active modulation sources during playback
    /// - Parameters:
    ///   - parameters: New oscillator parameters to apply
    ///   - globalLFO: Optional global LFO state to check for active modulation
    /// - Note: Updates base values immediately, but defers audio parameter application
    ///         if modulation is active and voice is playing. This prevents glitches
    ///         caused by main thread updates conflicting with background modulation thread.
    func updateOscillatorParameters(_ parameters: OscillatorParameters, globalLFO: GlobalLFOParameters? = nil) {
        // Always update base values first (needed by modulation system)
        modulationState.baseModulatorMultiplier = parameters.modulatingMultiplier
        modulationState.baseModulationIndex = parameters.modulationIndex
        
        // Check if modulation is active for modulation index
        let hasActiveModIndexModulation = 
            voiceModulation.modulatorEnvelope.amountToModulationIndex != 0.0 ||
            voiceModulation.voiceLFO.amountToModulatorLevel != 0.0 ||
            voiceModulation.touchAftertouch.amountToModulatorLevel != 0.0
        
        // Check if global LFO is modulating modulator multiplier
        let hasGlobalLFOModMultiplier = (globalLFO?.amountToModulatorMultiplier ?? 0.0) != 0.0
        
        // Apply non-modulated parameters (always safe to update)
        oscLeft.$carrierMultiplier.ramp(to: AUValue(parameters.carrierMultiplier), duration: 0.005)
        oscRight.$carrierMultiplier.ramp(to: AUValue(parameters.carrierMultiplier), duration: 0.005)
        
        oscLeft.$amplitude.ramp(to: AUValue(parameters.amplitude), duration: 0.005)
        oscRight.$amplitude.ramp(to: AUValue(parameters.amplitude), duration: 0.005)
        
        // Modulation Index: Only apply directly if no active modulation AND voice not playing
        if !hasActiveModIndexModulation || isAvailable {
            oscLeft.$modulationIndex.ramp(to: AUValue(parameters.modulationIndex), duration: 0.005)
            oscRight.$modulationIndex.ramp(to: AUValue(parameters.modulationIndex), duration: 0.005)
        }
        // else: modulation system will pick up the new base value at its next update cycle
        
        // Modulator Multiplier: Only apply directly if no global LFO modulation AND voice not playing
        if !hasGlobalLFOModMultiplier || isAvailable {
            oscLeft.$modulatingMultiplier.ramp(to: AUValue(parameters.modulatingMultiplier), duration: 0.005)
            oscRight.$modulatingMultiplier.ramp(to: AUValue(parameters.modulatingMultiplier), duration: 0.005)
        }
        // else: modulation system will pick up the new base value at its next update cycle
        
        // Update stereo spread parameters
        detuneMode = parameters.detuneMode
        frequencyOffsetCents = parameters.stereoOffsetProportional
        frequencyOffsetHz = parameters.stereoOffsetConstant
        
        // Note: Waveform cannot be changed dynamically in AudioKit's FMOscillator
        // Waveform changes require voice recreation (handled by VoicePool.recreateVoices)
    }
    
    /// Resets modulator multiplier to base (unmodulated) value
    /// Called when global LFO modulation amount is set to zero
    func resetModulatorMultiplierToBase() {
        oscLeft.$modulatingMultiplier.ramp(to: AUValue(modulationState.baseModulatorMultiplier), duration: 0.05)
        oscRight.$modulatingMultiplier.ramp(to: AUValue(modulationState.baseModulatorMultiplier), duration: 0.05)
    }
    
    /// Resets modulation index to base (unmodulated) value
    /// Called when voice LFO modulation amount is set to zero
    func resetModulationIndexToBase() {
        oscLeft.$modulationIndex.ramp(to: AUValue(modulationState.baseModulationIndex), duration: 0.05)
        oscRight.$modulationIndex.ramp(to: AUValue(modulationState.baseModulationIndex), duration: 0.05)
    }
    /// Updates filter parameters (MODULATABLE only - cutoff frequency)
    /// MODULATION-AWARE: Avoids fighting with active modulation sources during playback
    /// - Parameter parameters: New filter parameters to apply
    /// - Note: Updates base cutoff immediately, but defers audio parameter application
    ///         if modulation is active and voice is playing. This prevents glitches
    ///         caused by main thread updates conflicting with background modulation thread.
    func updateFilterParameters(_ parameters: FilterParameters) {
        // Update the base filter cutoff in modulation state FIRST
        // This ensures the modulation system uses the new value as the base
        modulationState.baseFilterCutoff = parameters.clampedCutoff
        
        // Check if modulation is active for this parameter
        let hasActiveFilterModulation = 
            voiceModulation.auxiliaryEnvelope.amountToFilterFrequency != 0.0 ||
            voiceModulation.voiceLFO.amountToFilterFrequency != 0.0 ||
            voiceModulation.touchAftertouch.amountToFilterFrequency != 0.0 ||
            voiceModulation.keyTracking.amountToFilterFrequency != 0.0
        
        // If modulation is active AND voice is currently playing, let the modulation
        // system handle the update at its next cycle (don't fight with it)
        if hasActiveFilterModulation && !isAvailable {
            // Modulation system will pick up the new base value at its next update
            return
        }
        
        // No modulation active or voice not playing: apply directly
        filter.$cutoffFrequency.ramp(to: AUValue(parameters.clampedCutoff), duration: 0)
    }
    
    /// Updates static (non-modulatable) filter parameters
    /// These are applied immediately and never modulated
    /// Should be called on main thread only, never during modulation
    func updateFilterStaticParameters(_ parameters: FilterStaticParameters) {
        // Use zero-duration ramps for immediate application
        // These parameters are NEVER touched by the modulation system
        filter.$resonance.ramp(to: AUValue(parameters.clampedResonance), duration: 0)
        filter.$distortion.ramp(to: AUValue(parameters.clampedSaturation), duration: 0)
    }
    
    /// Updates envelope parameters
    func updateEnvelopeParameters(_ parameters: EnvelopeParameters) {
        // Use zero-duration ramps to avoid AudioKit parameter ramping artifacts
        envelope.$attackDuration.ramp(to: AUValue(parameters.attackDuration), duration: 0)
        envelope.$decayDuration.ramp(to: AUValue(parameters.decayDuration), duration: 0)
        envelope.$sustainLevel.ramp(to: AUValue(parameters.sustainLevel), duration: 0)
        envelope.$releaseDuration.ramp(to: AUValue(parameters.releaseDuration), duration: 0)
    }
    
    /// Updates modulation parameters (Phase 5)
    func updateModulationParameters(_ parameters: VoiceModulationParameters) {
        voiceModulation = parameters
        // Note: Runtime state (modulationState) is not reset here
        // It continues tracking from current position
    }
    
    // MARK: - Modulation Application (Refactored - Fixed Destinations)
    
    /// Applies modulation from all sources with fixed destinations
    /// This method is called from the control-rate timer (200 Hz)
    /// - Parameters:
    ///   - globalLFO: Global LFO parameters with raw value
    ///   - deltaTime: Time since last update (typically 0.005 seconds at 200 Hz)
    ///   - currentTempo: Current tempo in BPM for tempo sync
    func applyModulation(
        globalLFO: (rawValue: Double, parameters: GlobalLFOParameters),
        deltaTime: Double,
        currentTempo: Double = 120.0
    ) {
        // Update envelope times
        modulationState.modulatorEnvelopeTime += deltaTime
        modulationState.auxiliaryEnvelopeTime += deltaTime
        
        // Update voice LFO phase and delay ramp
        updateVoiceLFOPhase(deltaTime: deltaTime, tempo: currentTempo)
        modulationState.updateVoiceLFODelayRamp(
            deltaTime: deltaTime,
            delayTime: voiceModulation.voiceLFO.delayTime
        )
        
        // Calculate envelope values using ModulationRouter
        let modulatorEnvValue = ModulationRouter.calculateEnvelopeValue(
            time: modulationState.modulatorEnvelopeTime,
            isGateOpen: modulationState.isGateOpen,
            attack: voiceModulation.modulatorEnvelope.attack,
            decay: voiceModulation.modulatorEnvelope.decay,
            sustain: voiceModulation.modulatorEnvelope.sustain,
            release: voiceModulation.modulatorEnvelope.release,
            capturedLevel: modulationState.modulatorSustainLevel
        )
        
        let auxiliaryEnvValue = ModulationRouter.calculateEnvelopeValue(
            time: modulationState.auxiliaryEnvelopeTime,
            isGateOpen: modulationState.isGateOpen,
            attack: voiceModulation.auxiliaryEnvelope.attack,
            decay: voiceModulation.auxiliaryEnvelope.decay,
            sustain: voiceModulation.auxiliaryEnvelope.sustain,
            release: voiceModulation.auxiliaryEnvelope.release,
            capturedLevel: modulationState.auxiliarySustainLevel
        )
        
        // Get raw voice LFO value
        let voiceLFORawValue = voiceModulation.voiceLFO.rawValue(at: modulationState.voiceLFOPhase)
        
        // Get key tracking value (NOTE-ON property - calculated once at trigger, never recalculated)
        // This ensures consistent filter behavior regardless of pitch modulation
        let keyTrackValue = modulationState.keyTrackingValue
        
        // Get aftertouch delta (bipolar: -1 to +1)
        let aftertouchDelta = modulationState.currentTouchX - modulationState.initialTouchX
        
        // Apply all modulations to their destinations
        // Note: Some destinations (pitch, filter, mod index) receive input from multiple sources
        // and must be calculated in a combined fashion to avoid one source overwriting another
        applyCombinedModulationIndex(
            modulatorEnvValue: modulatorEnvValue,
            voiceLFORawValue: voiceLFORawValue,
            aftertouchDelta: aftertouchDelta
        )
        applyCombinedPitch(
            auxiliaryEnvValue: auxiliaryEnvValue,
            voiceLFORawValue: voiceLFORawValue,
            aftertouchDelta: aftertouchDelta
        )
        applyCombinedFilterFrequency(
            auxiliaryEnvValue: auxiliaryEnvValue,
            voiceLFORawValue: voiceLFORawValue,
            globalLFORawValue: globalLFO.rawValue,
            globalLFOParameters: globalLFO.parameters,
            keyTrackValue: keyTrackValue,
            aftertouchDelta: aftertouchDelta
        )
        applyGlobalLFO(rawValue: globalLFO.rawValue, parameters: globalLFO.parameters)
    }
    
    // MARK: - Voice LFO Phase Update (Phase 5C)
    
    /// Updates the voice LFO phase based on time
    /// Note: Voice LFO frequency is always in Hz (no tempo sync)
    private func updateVoiceLFOPhase(deltaTime: Double, tempo: Double) {
        guard voiceModulation.voiceLFO.isEnabled else { return }
        
        let lfo = voiceModulation.voiceLFO
        
        // Apply key tracking modulation to base frequency
        var effectiveFrequency = lfo.frequency
        if voiceModulation.keyTracking.amountToVoiceLFOFrequency != 0.0 {
            let keyTrackValue = voiceModulation.keyTracking.trackingValue(
                forFrequency: modulationState.currentFrequency
            )
            effectiveFrequency = ModulationRouter.calculateVoiceLFOFrequency(
                baseFrequency: lfo.frequency,
                keyTrackValue: keyTrackValue,
                keyTrackAmount: voiceModulation.keyTracking.amountToVoiceLFOFrequency
            )
        }
        
        // Voice LFO is always in Hz (no tempo sync)
        // Phase increment = frequency * deltaTime
        let phaseIncrement = effectiveFrequency * deltaTime
        
        // Update phase based on reset mode
        switch lfo.resetMode {
        case .free:
            // Free running: just increment and wrap
            modulationState.voiceLFOPhase += phaseIncrement
            if modulationState.voiceLFOPhase >= 1.0 {
                modulationState.voiceLFOPhase -= floor(modulationState.voiceLFOPhase)
            }
            
        case .trigger:
            // Trigger reset: phase was reset to 0 in trigger(), now just increment
            modulationState.voiceLFOPhase += phaseIncrement
            if modulationState.voiceLFOPhase >= 1.0 {
                modulationState.voiceLFOPhase -= floor(modulationState.voiceLFOPhase)
            }
            
        case .sync:
            // Tempo sync reset mode: phase aligns to global timing
            // (Currently same as trigger - external sync could be added later)
            modulationState.voiceLFOPhase += phaseIncrement
            if modulationState.voiceLFOPhase >= 1.0 {
                modulationState.voiceLFOPhase -= floor(modulationState.voiceLFOPhase)
            }
        }
    }
    
    // MARK: - Combined Modulation Application Methods
    // These methods handle destinations that receive input from multiple sources
    // and must combine them properly to avoid one source overwriting another
    
    /// Applies combined modulation index from all sources
    /// Sources: Modulator envelope, Voice LFO, Aftertouch
    private func applyCombinedModulationIndex(
        modulatorEnvValue: Double,
        voiceLFORawValue: Double,
        aftertouchDelta: Double
    ) {
        
        // Apply initial touch meta-modulation to mod envelope amount
        var effectiveModEnvAmount = voiceModulation.modulatorEnvelope.amountToModulationIndex
        if voiceModulation.touchInitial.amountToModEnvelope != 0.0 {
            effectiveModEnvAmount = ModulationRouter.calculateTouchScaledAmount(
                baseAmount: effectiveModEnvAmount,
                initialTouchValue: modulationState.initialTouchX,
                initialTouchAmount: voiceModulation.touchInitial.amountToModEnvelope
            )
        }
        
        // Use the ModulationRouter to properly combine all sources
        let finalModIndex = ModulationRouter.calculateModulationIndex(
            baseModIndex: modulationState.baseModulationIndex,
            modEnvValue: modulatorEnvValue,
            modEnvAmount: effectiveModEnvAmount,
            voiceLFOValue: voiceLFORawValue,
            voiceLFOAmount: voiceModulation.voiceLFO.amountToModulatorLevel,
            voiceLFORampFactor: modulationState.voiceLFORampFactor,
            aftertouchDelta: aftertouchDelta,
            aftertouchAmount: voiceModulation.touchAftertouch.amountToModulatorLevel
        )
        
        oscLeft.$modulationIndex.ramp(to: AUValue(finalModIndex), duration: 0.005)
        oscRight.$modulationIndex.ramp(to: AUValue(finalModIndex), duration: 0.005)
    }
    
    /// Applies combined pitch modulation from all sources
    /// Sources: Auxiliary envelope, Voice LFO (with meta-modulation from aux env and aftertouch), Aftertouch
    private func applyCombinedPitch(
        auxiliaryEnvValue: Double,
        voiceLFORawValue: Double,
        aftertouchDelta: Double
    ) {
        // Check if any source is active (including meta-modulation sources)
        let hasAuxEnv = voiceModulation.auxiliaryEnvelope.amountToOscillatorPitch != 0.0
        let hasVoiceLFO = voiceModulation.voiceLFO.amountToOscillatorPitch != 0.0
        let hasVibratoMetaMod = voiceModulation.auxiliaryEnvelope.amountToVibrato != 0.0
            || voiceModulation.touchAftertouch.amountToVibrato != 0.0
        let hasInitialTouchToPitch = voiceModulation.touchInitial.amountToAuxEnvPitch != 0.0
        let hasAftertouchToPitch = voiceModulation.touchAftertouch.amountToOscillatorPitch != 0.0
        
        guard hasAuxEnv || hasVoiceLFO || hasVibratoMetaMod || hasInitialTouchToPitch || hasAftertouchToPitch else { return }
        
        // Apply initial touch meta-modulation to aux envelope pitch amount
        var effectiveAuxEnvPitchAmount = voiceModulation.auxiliaryEnvelope.amountToOscillatorPitch
        if voiceModulation.touchInitial.amountToAuxEnvPitch != 0.0 {
            effectiveAuxEnvPitchAmount = ModulationRouter.calculateTouchScaledAmount(
                baseAmount: effectiveAuxEnvPitchAmount,
                initialTouchValue: modulationState.initialTouchX,
                initialTouchAmount: voiceModulation.touchInitial.amountToAuxEnvPitch
            )
        }
        
        // Calculate effective voice LFO amount (with meta-modulation)
        // Allow aftertouch/aux env to add vibrato even if base amount is 0
        var effectiveVoiceLFOAmount = voiceModulation.voiceLFO.amountToOscillatorPitch
        
        if hasVibratoMetaMod {
            // Meta-modulation: aux envelope and aftertouch can modulate the vibrato amount
            effectiveVoiceLFOAmount = ModulationRouter.calculateVoiceLFOPitchAmount(
                baseAmount: effectiveVoiceLFOAmount,
                auxEnvValue: auxiliaryEnvValue,
                auxEnvAmount: voiceModulation.auxiliaryEnvelope.amountToVibrato,
                aftertouchDelta: aftertouchDelta,
                aftertouchAmount: voiceModulation.touchAftertouch.amountToVibrato
            )
        }
        
        // Combine aux envelope, voice LFO, and aftertouch for pitch
        let finalFreq = ModulationRouter.calculateOscillatorPitch(
            baseFrequency: modulationState.baseFrequency,
            auxEnvValue: auxiliaryEnvValue,
            auxEnvAmount: effectiveAuxEnvPitchAmount,
            voiceLFOValue: voiceLFORawValue,
            voiceLFOAmount: effectiveVoiceLFOAmount,
            voiceLFORampFactor: modulationState.voiceLFORampFactor,
            aftertouchDelta: aftertouchDelta,
            aftertouchAmount: voiceModulation.touchAftertouch.amountToOscillatorPitch
        )
        
        currentFrequency = finalFreq
        updateOscillatorFrequencies()
    }
    
    /// Applies combined filter frequency modulation from all sources
    /// Sources: Key tracking, Auxiliary envelope, Voice LFO, Global LFO, Aftertouch
    private func applyCombinedFilterFrequency(
        auxiliaryEnvValue: Double,
        voiceLFORawValue: Double,
        globalLFORawValue: Double,
        globalLFOParameters: GlobalLFOParameters,
        keyTrackValue: Double,
        aftertouchDelta: Double
    ) {
        // Check if any source is active
        // Key tracking is now a direct additive source (note-on offset), not just a multiplier
        let hasKeyTrack = voiceModulation.keyTracking.amountToFilterFrequency != 0.0
        let hasAuxEnv = voiceModulation.auxiliaryEnvelope.amountToFilterFrequency != 0.0
        let hasVoiceLFO = voiceModulation.voiceLFO.amountToFilterFrequency != 0.0
        let hasGlobalLFO = globalLFOParameters.amountToFilterFrequency != 0.0
        let hasAftertouch = voiceModulation.touchAftertouch.amountToFilterFrequency != 0.0
        let hasInitialTouchToFilter = voiceModulation.touchInitial.amountToAuxEnvCutoff != 0.0
        
        guard hasKeyTrack || hasAuxEnv || hasVoiceLFO || hasGlobalLFO || hasAftertouch || hasInitialTouchToFilter else { return }
        
        // Apply initial touch meta-modulation to aux envelope filter amount
        var effectiveAuxEnvFilterAmount = voiceModulation.auxiliaryEnvelope.amountToFilterFrequency
        if voiceModulation.touchInitial.amountToAuxEnvCutoff != 0.0 {
            effectiveAuxEnvFilterAmount = ModulationRouter.calculateTouchScaledAmount(
                baseAmount: effectiveAuxEnvFilterAmount,
                initialTouchValue: modulationState.initialTouchX,
                initialTouchAmount: voiceModulation.touchInitial.amountToAuxEnvCutoff
            )
        }
        
        // Use the ModulationRouter to properly combine all sources
        let finalCutoff = ModulationRouter.calculateFilterFrequency(
            baseCutoff: modulationState.baseFilterCutoff,
            keyTrackValue: keyTrackValue,
            keyTrackAmount: voiceModulation.keyTracking.amountToFilterFrequency,
            auxEnvValue: auxiliaryEnvValue,
            auxEnvAmount: effectiveAuxEnvFilterAmount,
            aftertouchDelta: aftertouchDelta,
            aftertouchAmount: voiceModulation.touchAftertouch.amountToFilterFrequency,
            voiceLFOValue: voiceLFORawValue,
            voiceLFOAmount: voiceModulation.voiceLFO.amountToFilterFrequency,
            voiceLFORampFactor: modulationState.voiceLFORampFactor,
            globalLFOValue: globalLFORawValue,
            globalLFOAmount: globalLFOParameters.amountToFilterFrequency
        )
        
        // Apply smoothing for aftertouch if active
        let smoothedCutoff: Double
        if hasAftertouch && modulationState.lastSmoothedFilterCutoff != nil {
            let currentValue = modulationState.lastSmoothedFilterCutoff ?? finalCutoff
            let smoothingFactor = modulationState.filterSmoothingFactor
            let interpolationAmount = 1.0 - smoothingFactor
            smoothedCutoff = currentValue + (finalCutoff - currentValue) * interpolationAmount
            modulationState.lastSmoothedFilterCutoff = smoothedCutoff
        } else {
            smoothedCutoff = finalCutoff
            if hasAftertouch {
                modulationState.lastSmoothedFilterCutoff = finalCutoff
            }
        }
        
        // Use 5ms ramp for smooth modulation (works with 200 Hz control rate)
        filter.$cutoffFrequency.ramp(to: AUValue(smoothedCutoff), duration: 0.005)
    }
    
 
    
    /// Applies global LFO modulation to voice-level destinations
    /// NOTE: Tremolo (mixer volume) is now handled at VoicePool level, not here
    /// NOTE: Initial touch amplitude modulation is applied immediately at note-on in trigger()
    /// Filter modulation is handled by applyCombinedFilterFrequency()
    private func applyGlobalLFO(rawValue: Double, parameters: GlobalLFOParameters) {
        
        // Destination 1: Modulator multiplier (FM ratio modulation)
        if parameters.amountToModulatorMultiplier != 0.0 {
            let finalMultiplier = ModulationRouter.calculateModulatorMultiplier(
                baseMultiplier: modulationState.baseModulatorMultiplier,  // Use stored base value
                globalLFOValue: rawValue,
                globalLFOAmount: parameters.amountToModulatorMultiplier
            )
            oscLeft.$modulatingMultiplier.ramp(to: AUValue(finalMultiplier), duration: 0.005)
            oscRight.$modulatingMultiplier.ramp(to: AUValue(finalMultiplier), duration: 0.005)
        }
        
        // Note: Filter frequency modulation is handled in applyCombinedFilterFrequency()
        // Note: Delay time and mixer volume (tremolo) modulation are handled at VoicePool level
    }
}
