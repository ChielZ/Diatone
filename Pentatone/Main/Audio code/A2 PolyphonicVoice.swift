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
import QuartzCore  // For CACurrentMediaTime()

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
    
    /// Fader for loudness envelope control (replaces AmplitudeEnvelope)
    /// Controlled manually via loudness envelope calculation
    let fader: Fader
    
    // MARK: - Voice State
    
    /// Whether this voice is available for allocation
    var isAvailable: Bool = true
    var isPlaying: Bool = false
    
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

        // Create fader for loudness envelope control (replaces AmplitudeEnvelope)
        // Start with gain = 0 (silent) - will be ramped up on trigger
        self.fader = Fader(filter, gain: 0.0)
        
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
            // Set ramp duration for smooth parameter changes
            oscLeft.$baseFrequency.ramp(to: Float(currentFrequency), duration: 0.005)
            oscRight.$baseFrequency.ramp(to: Float(currentFrequency), duration: 0.005)
            oscLeft.$amplitude.ramp(to: currentAmplitude, duration: 0.005)
            oscRight.$amplitude.ramp(to: currentAmplitude, duration: 0.005)
            
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
    
    /// Retriggers this voice for legato (updates parameters without restarting envelopes)
    /// Used in monophonic mode when a note is triggered while another is playing
    /// - Parameters:
    ///   - frequency: New frequency to play
    ///   - initialTouchX: Initial touch x-position for the new note
    ///   - templateFilterCutoff: Optional override for base filter cutoff (from current template)
    func retrigger(frequency: Double, initialTouchX: Double = 0.5, templateFilterCutoff: Double? = nil) {
        guard isInitialized else {
            assertionFailure("Voice must be initialized before retriggering")
            return
        }
        
        // Update base filter cutoff from template if provided
        if let cutoff = templateFilterCutoff {
            modulationState.baseFilterCutoff = cutoff
        }
        
        // Update initial touch value for new note
        modulationState.initialTouchX = initialTouchX
        modulationState.currentTouchX = initialTouchX
        
        // Update base frequency in modulation state
        modulationState.baseFrequency = frequency
        
        // Apply immediate amplitude adjustment for initial touch
        let immediateAmplitude: Double
        if voiceModulation.touchInitial.amountToOscillatorAmplitude != 0.0 {
            immediateAmplitude = ModulationRouter.calculateOscillatorAmplitude(
                baseAmplitude: modulationState.baseAmplitude,
                initialTouchValue: initialTouchX,
                initialTouchAmount: voiceModulation.touchInitial.amountToOscillatorAmplitude
            )
        } else {
            immediateAmplitude = modulationState.baseAmplitude
        }
        
        oscLeft.$amplitude.ramp(to: AUValue(immediateAmplitude), duration: 0.005)
        oscRight.$amplitude.ramp(to: AUValue(immediateAmplitude), duration: 0.005)
        
        // Update key tracking value for new frequency
        modulationState.keyTrackingValue = voiceModulation.keyTracking.trackingValue(forFrequency: frequency)
        
        // IMPROVED: Calculate final filter target including both key tracking AND envelope modulation
        // In legato mode, we want the filter to follow the new note's key tracking
        // but maintain the current envelope state (not restart to peak)
        let keyTrackedBaseCutoff: Double
        if voiceModulation.keyTracking.amountToFilterFrequency != 0.0 {
            let keyTrackOctaves = modulationState.keyTrackingValue * voiceModulation.keyTracking.amountToFilterFrequency
            keyTrackedBaseCutoff = modulationState.baseFilterCutoff * pow(2.0, keyTrackOctaves)
        } else {
            keyTrackedBaseCutoff = modulationState.baseFilterCutoff
        }
        
        // In legato retrigger, we need to consider if aux envelope is currently modulating
        // If so, apply the CURRENT envelope value (not the peak), so the filter smoothly transitions
        let finalFilterTarget: Double
        if voiceModulation.auxiliaryEnvelope.amountToFilterFrequency != 0.0 {
            // Aux envelope IS modulating - calculate current envelope value
            let currentAuxEnvValue = ModulationRouter.calculateActiveEnvelopeValue(
                time: modulationState.auxiliaryEnvelopeTime,
                isGateOpen: modulationState.isGateOpen,
                attack: voiceModulation.auxiliaryEnvelope.attack,
                decay: voiceModulation.auxiliaryEnvelope.decay,
                sustain: voiceModulation.auxiliaryEnvelope.sustain,
                release: voiceModulation.auxiliaryEnvelope.release,
                capturedLevel: modulationState.auxiliarySustainLevel
            )
            
            // Apply initial touch meta-modulation if active
            var effectiveAuxEnvFilterAmount = voiceModulation.auxiliaryEnvelope.amountToFilterFrequency
            if voiceModulation.touchInitial.amountToAuxEnvCutoff != 0.0 {
                effectiveAuxEnvFilterAmount = ModulationRouter.calculateTouchScaledAmount(
                    baseAmount: effectiveAuxEnvFilterAmount,
                    initialTouchValue: initialTouchX,
                    initialTouchAmount: voiceModulation.touchInitial.amountToAuxEnvCutoff
                )
            }
            
            // Calculate target with current envelope value (not peak)
            let octaveOffset = currentAuxEnvValue * effectiveAuxEnvFilterAmount
            finalFilterTarget = keyTrackedBaseCutoff * pow(2.0, octaveOffset)
        } else {
            // Aux envelope is NOT modulating - just use key-tracked base
            finalFilterTarget = keyTrackedBaseCutoff
        }
        
        let clampedFilterTarget = max(12.0, min(20000.0, finalFilterTarget))
        filter.$cutoffFrequency.ramp(to: AUValue(clampedFilterTarget), duration: 0.000)
        
        // Update oscillator frequencies with smooth glide
        setFrequency(frequency)
        
        print("🎵 Legato retrigger: frequency \(frequency) Hz, touchX \(String(format: "%.2f", initialTouchX))")
        
        // NOTE: Envelopes are NOT restarted - this is the key difference from trigger()
        // The voice continues playing with its current envelope state
    }
    
    /// Applies initial envelope modulation values at trigger time
    /// This eliminates 0-5ms timing jitter by applying envelope peak values immediately
    /// with ramp duration = attack time, so the ramp IS the attack phase
    ///
    /// Handles two critical destinations:
    /// 1. Mod envelope → Modulation Index
    /// 2. Aux envelope → Pitch
    ///
    /// NOTE: Filter frequency is now handled directly in trigger() to avoid overlapping ramps
    ///
    /// - Parameter keyTrackedBaseCutoff: Pre-calculated key-tracked filter cutoff (kept for compatibility, not used)
    private func applyInitialEnvelopeModulation(keyTrackedBaseCutoff: Double) {
        // Calculate peak envelope values (what they will be after attack completes)
        // Peak value for envelopes is always 1.0 (full modulation amount)
        let modEnvPeakValue = 1.0
        let auxEnvPeakValue = 1.0
        
        // Get attack times for ramp durations
        let modEnvAttack = voiceModulation.modulatorEnvelope.attack
        let auxEnvAttack = voiceModulation.auxiliaryEnvelope.attack
        
        // 1) MOD ENVELOPE → MODULATION INDEX
        if voiceModulation.modulatorEnvelope.amountToModulationIndex != 0.0 {
            // Apply initial touch meta-modulation if active
            var effectiveModEnvAmount = voiceModulation.modulatorEnvelope.amountToModulationIndex
            if voiceModulation.touchInitial.amountToModEnvelope != 0.0 {
                effectiveModEnvAmount = ModulationRouter.calculateTouchScaledAmount(
                    baseAmount: effectiveModEnvAmount,
                    initialTouchValue: modulationState.initialTouchX,
                    initialTouchAmount: voiceModulation.touchInitial.amountToModEnvelope
                )
            }

            // Calculate target modulation index (base + peak envelope offset)
            let targetModIndex = modulationState.baseModulationIndex + (modEnvPeakValue * effectiveModEnvAmount)
            let clampedModIndex = max(0.0, min(10.0, targetModIndex))

            // Start value for the ramp (base value, or current value for voice stealing)
            let startModIndex = modulationState.baseModulationIndex

            // EXPERIMENTAL: Force the start value before ramping for consistent behavior
            oscLeft.$modulationIndex.ramp(to: AUValue(startModIndex), duration: 0)
            oscRight.$modulationIndex.ramp(to: AUValue(startModIndex), duration: 0)

            // Now apply the attack ramp from the known start value
            let smoothingDuration = max(Float(modEnvAttack), 0.000)
            oscLeft.$modulationIndex.ramp(to: AUValue(clampedModIndex), duration: smoothingDuration)
            oscRight.$modulationIndex.ramp(to: AUValue(clampedModIndex), duration: smoothingDuration)
        }
        
        // 2) AUX ENVELOPE → PITCH
        if voiceModulation.auxiliaryEnvelope.amountToOscillatorPitch != 0.0 {
            // Apply initial touch meta-modulation if active
            var effectiveAuxEnvPitchAmount = voiceModulation.auxiliaryEnvelope.amountToOscillatorPitch
            if voiceModulation.touchInitial.amountToAuxEnvPitch != 0.0 {
                effectiveAuxEnvPitchAmount = ModulationRouter.calculateTouchScaledAmount(
                    baseAmount: effectiveAuxEnvPitchAmount,
                    initialTouchValue: modulationState.initialTouchX,
                    initialTouchAmount: voiceModulation.touchInitial.amountToAuxEnvPitch
                )
            }

            // Calculate target frequency (base + peak envelope offset in semitones)
            let semitoneOffset = auxEnvPeakValue * effectiveAuxEnvPitchAmount
            let targetFrequency = modulationState.baseFrequency * pow(2.0, semitoneOffset / 12.0)
            let clampedFrequency = max(20.0, min(20000.0, targetFrequency))

            // Apply with ramp duration = attack time
            // Note: We apply to baseFrequency directly, then update oscillators
            // The ramp is applied at the oscillator level via updateOscillatorFrequencies
            currentFrequency = clampedFrequency

            // Calculate start and target left/right frequencies with stereo offset
            let startLeftFreq: Double
            let startRightFreq: Double
            let targetLeftFreq: Double
            let targetRightFreq: Double

            switch detuneMode {
            case .proportional:
                let ratio = pow(2.0, frequencyOffsetCents / 1200.0)
                startLeftFreq = modulationState.baseFrequency * ratio
                startRightFreq = modulationState.baseFrequency / ratio
                targetLeftFreq = clampedFrequency * ratio
                targetRightFreq = clampedFrequency / ratio
            case .constant:
                startLeftFreq = modulationState.baseFrequency + frequencyOffsetHz
                startRightFreq = modulationState.baseFrequency - frequencyOffsetHz
                targetLeftFreq = clampedFrequency + frequencyOffsetHz
                targetRightFreq = clampedFrequency - frequencyOffsetHz
            }

            // EXPERIMENTAL: Force the start value before ramping for consistent behavior
            oscLeft.$baseFrequency.ramp(to: Float(startLeftFreq), duration: 0)
            oscRight.$baseFrequency.ramp(to: Float(startRightFreq), duration: 0)

            // Now apply the attack ramp from the known start value
            oscLeft.$baseFrequency.ramp(to: Float(targetLeftFreq), duration: Float(auxEnvAttack))
            oscRight.$baseFrequency.ramp(to: Float(targetRightFreq), duration: Float(auxEnvAttack))
        }
        
        // NOTE: Filter frequency modulation is now handled directly in trigger()
        // to avoid overlapping ramps and ensure smooth voice stealing behavior
    
    }

    
    /// Triggers this voice (starts envelope attack)
    ///
    /// **CRITICAL TIMING REQUIREMENTS:**
    /// - Initial touch amplitude modulation is applied immediately (zero-latency)
    /// - Key tracking filter offset is applied immediately (zero-latency)
    /// - Envelope modulation values are applied immediately with ramp time = attack time
    /// - Envelope elapsed time tracking starts immediately at trigger (not at next control rate cycle)
    ///
    /// **NOTE-ON PROPERTIES (applied once at trigger):**
    /// - Key tracking: Calculated based on note frequency, remains constant for note lifetime
    /// - Initial touch: Captured at note-on, used for amplitude and meta-modulation
    ///
    /// - Parameters:
    ///   - initialTouchX: Initial touch x-position (0.0 = left, 1.0 = right) for velocity-like response
    ///   - templateFilterCutoff: Optional override for base filter cutoff (from current template)
    ///   - templateFilterStatic: Optional override for static filter parameters (resonance, saturation)
    func trigger(initialTouchX: Double = 0.5, templateFilterCutoff: Double? = nil, templateFilterStatic: FilterStaticParameters? = nil) {
        guard isInitialized else {
            assertionFailure("Voice must be initialized before triggering")
            return
        }

        // CRITICAL: Calculate current fader level BEFORE reset() changes the modulation state
        // This captures the previous note's envelope value for smooth voice stealing.
        //
        // NOTE: We cannot use fader.leftGain here because AudioKit's gain property
        // always reports either the start or target value of a ramp, never the
        // intermediate interpolated value. Instead, we calculate the current
        // envelope value directly using the stored timing information.
        let currentFaderLevel: Double
        if modulationState.isGateOpen {
            // Voice was in attack/decay/sustain phase - calculate current level
            currentFaderLevel = ModulationRouter.calculateLoudnessEnvelopeValue(
                time: modulationState.loudnessEnvelopeTime,
                isGateOpen: true,
                attack: voiceModulation.loudnessEnvelope.attack,
                decay: voiceModulation.loudnessEnvelope.decay,
                sustain: voiceModulation.loudnessEnvelope.sustain,
                release: voiceModulation.loudnessEnvelope.release,
                capturedLevel: modulationState.loudnessSustainLevel,
                startLevel: modulationState.loudnessStartLevel
            )
        } else if modulationState.loudnessSustainLevel > 0.001 {
            // Voice was in release phase - calculate current level
            currentFaderLevel = ModulationRouter.calculateLoudnessEnvelopeValue(
                time: modulationState.loudnessEnvelopeTime,
                isGateOpen: false,
                attack: voiceModulation.loudnessEnvelope.attack,
                decay: voiceModulation.loudnessEnvelope.decay,
                sustain: voiceModulation.loudnessEnvelope.sustain,
                release: voiceModulation.loudnessEnvelope.release,
                capturedLevel: modulationState.loudnessSustainLevel,
                startLevel: modulationState.loudnessStartLevel
            )
        } else {
            // Voice was idle or fully released - start from zero
            currentFaderLevel = 0.0
        }

        // CRITICAL: Update base filter cutoff from template if provided
        // This ensures we always use the latest UI setting, not a stale value
        if let cutoff = templateFilterCutoff {
            modulationState.baseFilterCutoff = cutoff
        }
        /* DEPRECATED - no longer need to set filter static values at note on
        // CRITICAL: Apply static filter parameters (resonance, saturation) at note-on
        // These are NOTE-ON properties - set once and never modulated
        if let filterStatic = templateFilterStatic {
            filter.$resonance.ramp(to: AUValue(filterStatic.clampedResonance), duration: 0.005)
            filter.$distortion.ramp(to: AUValue(filterStatic.clampedSaturation), duration: 0.005)
        }
        */
        
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
        
        // CRITICAL: Calculate and apply key-tracked filter cutoff with smooth transition
        // This must happen BEFORE the envelope opens to avoid transients
        // First, reset modulation state to get the key tracking value
        let shouldResetLFO = voiceModulation.voiceLFO.resetMode != .free

        // CRITICAL: Set trigger timestamp and increment sequence BEFORE reset() sets isGateOpen = true
        // The sequence number allows the modulation loop to detect a new trigger and capture
        // its own timing, avoiding race conditions between main thread and modulation thread
        modulationState.triggerTimestamp = CACurrentMediaTime()
        modulationState.triggerSequence &+= 1  // Wrapping increment

        modulationState.reset(
            frequency: currentFrequency,
            touchX: initialTouchX,
            resetLFOPhase: shouldResetLFO,
            keyTrackingParams: voiceModulation.keyTracking
        )
        
        // CRITICAL: Calculate key-tracked filter cutoff UNCONDITIONALLY
        // This is a NOTE-ON property that applies regardless of envelope/LFO modulation
        let keyTrackedBaseCutoff: Double
        if voiceModulation.keyTracking.amountToFilterFrequency != 0.0 {
            let keyTrackOctaves = modulationState.keyTrackingValue * voiceModulation.keyTracking.amountToFilterFrequency
            keyTrackedBaseCutoff = modulationState.baseFilterCutoff * pow(2.0, keyTrackOctaves)
        } else {
            keyTrackedBaseCutoff = modulationState.baseFilterCutoff
        }
        
        // IMPROVED: Calculate final filter target including both key tracking AND envelope modulation
        // This ensures we do a SINGLE smooth ramp from current value to final target
        // (avoids overlapping ramps that can cause discontinuities)
        let finalFilterTarget: Double
        let filterRampDuration: Float
        
        if voiceModulation.auxiliaryEnvelope.amountToFilterFrequency != 0.0 {
            // Aux envelope IS modulating filter - calculate peak target with envelope
            var effectiveAuxEnvFilterAmount = voiceModulation.auxiliaryEnvelope.amountToFilterFrequency
            
            // Apply initial touch meta-modulation if active
            if voiceModulation.touchInitial.amountToAuxEnvCutoff != 0.0 {
                effectiveAuxEnvFilterAmount = ModulationRouter.calculateTouchScaledAmount(
                    baseAmount: effectiveAuxEnvFilterAmount,
                    initialTouchValue: initialTouchX,
                    initialTouchAmount: voiceModulation.touchInitial.amountToAuxEnvCutoff
                )
            }
            
            // Calculate target with envelope at peak (1.0)
            let auxEnvPeakValue = 1.0
            let octaveOffset = auxEnvPeakValue * effectiveAuxEnvFilterAmount
            finalFilterTarget = keyTrackedBaseCutoff * pow(2.0, octaveOffset)
            
            // Use attack time as ramp duration (with minimum for smoothness)
            filterRampDuration = max(Float(voiceModulation.auxiliaryEnvelope.attack), 0.000)
        } else {
            // Aux envelope is NOT modulating - just use key-tracked base
            finalFilterTarget = keyTrackedBaseCutoff
            
            // Use short ramp for voice stealing smoothness
            filterRampDuration = 0.000
        }
        
        // Apply single smooth ramp to final target
        let clampedFilterTarget = max(12.0, min(20000.0, finalFilterTarget))
        let clampedFilterStart = max(12.0, min(20000.0, keyTrackedBaseCutoff))

        // EXPERIMENTAL: Force the start value before ramping for consistent behavior
        filter.$cutoffFrequency.ramp(to: AUValue(clampedFilterStart), duration: 0)

        // Now apply the attack ramp from the known start value
        filter.$cutoffFrequency.ramp(to: AUValue(clampedFilterTarget), duration: filterRampDuration)

        // Capture filter cutoff start and peak for smooth handover during attack phase
        modulationState.auxiliaryStartFilterCutoff = clampedFilterStart
        modulationState.auxiliaryPeakFilterCutoff = clampedFilterTarget

        // Capture current modulation index for smooth handover during attack phase
        // This allows the modulation loop to interpolate from current value to peak
        modulationState.modulatorStartModIndex = Double(oscLeft.modulationIndex)

        // Calculate peak mod index (target at end of attack) for handover tracking
        if voiceModulation.modulatorEnvelope.amountToModulationIndex != 0.0 {
            var effectiveModEnvAmount = voiceModulation.modulatorEnvelope.amountToModulationIndex
            if voiceModulation.touchInitial.amountToModEnvelope != 0.0 {
                effectiveModEnvAmount = ModulationRouter.calculateTouchScaledAmount(
                    baseAmount: effectiveModEnvAmount,
                    initialTouchValue: initialTouchX,
                    initialTouchAmount: voiceModulation.touchInitial.amountToModEnvelope
                )
            }
            modulationState.modulatorPeakModIndex = max(0.0, min(10.0, modulationState.baseModulationIndex + effectiveModEnvAmount))
        } else {
            modulationState.modulatorPeakModIndex = modulationState.baseModulationIndex
        }

        // CRITICAL: Apply envelope modulation values immediately with ramp time = attack time
        // This eliminates 0-5ms timing jitter between trigger and first control rate update
        // Pass the key-tracked base cutoff so envelope modulation applies on top of it
        applyInitialEnvelopeModulation(keyTrackedBaseCutoff: keyTrackedBaseCutoff)

        // CRITICAL: Apply initial loudness envelope ramp (replaces envelope.openGate())
        // Start from current fader level (for voice stealing) and ramp to 1.0 over attack time
        // NOTE: currentFaderLevel was calculated at the top of trigger(), BEFORE reset() was called
        let loudnessAttack = voiceModulation.loudnessEnvelope.attack

        // DEBUG: Log the actual fader value from AudioKit vs our calculated value
        let actualFaderLeft = fader.leftGain
        let actualFaderRight = fader.rightGain
        print("🎹 TRIGGER: attack=\(String(format: "%.1f", loudnessAttack * 1000))ms, calculated=\(String(format: "%.3f", currentFaderLevel)), actualL=\(String(format: "%.3f", actualFaderLeft)), actualR=\(String(format: "%.3f", actualFaderRight))")
        
        // For voice stealing: use actual fader value if significantly different from calculated
        // With smaller audio buffers, fader.leftGain now reports more accurate values
        // This prevents clicks from mismatched start values during voice stealing
        let effectiveStartLevel: Double
        let discrepancy = abs(Double(actualFaderLeft) - currentFaderLevel)
        if discrepancy > 0.05 {
            // Significant discrepancy - use actual value to prevent click
            effectiveStartLevel = Double(actualFaderLeft)
            print("🎹 VOICE STEAL: Using actual fader value \(String(format: "%.3f", effectiveStartLevel)) instead of calculated \(String(format: "%.3f", currentFaderLevel))")
        } else {
            effectiveStartLevel = currentFaderLevel
        }

        // Apply attack ramp - AudioKit will ramp from current value to target
        // No need to "force" start value since we're now accounting for actual fader state
        fader.$leftGain.ramp(to: 1.0, duration: Float(loudnessAttack))
        fader.$rightGain.ramp(to: 1.0, duration: Float(loudnessAttack))

        // Store attack timing for mod loop backup
        let attackStartTime = CACurrentMediaTime()
        modulationState.loudnessAttackEndTime = attackStartTime + loudnessAttack
        modulationState.loudnessAttackDuration = loudnessAttack
        modulationState.loudnessAttackStartTime = attackStartTime



        // Store the start level for envelope calculation (needed for voice stealing)
        // Use effectiveStartLevel which accounts for any discrepancy with actual fader value
        modulationState.loudnessStartLevel = effectiveStartLevel
        
        // Reset filter and mark voice as active
        //filter.reset()
        isAvailable = false
        isPlaying = true
        triggerTime = Date()
    }
    
    /// Releases this voice (starts envelope release)
    /// The voice will be marked available after the release duration
    func release() {
        // Capture current envelope values for smooth release using ModulationRouter
        let modulatorValue = ModulationRouter.calculateHybridEnvelopeValue(
            time: modulationState.modulatorEnvelopeTime,
            isGateOpen: true,
            attack: voiceModulation.modulatorEnvelope.attack,
            decay: voiceModulation.modulatorEnvelope.decay,
            sustain: voiceModulation.modulatorEnvelope.sustain,
            release: voiceModulation.modulatorEnvelope.release
        )
        
        let auxiliaryValue = ModulationRouter.calculateHybridEnvelopeValue(
            time: modulationState.auxiliaryEnvelopeTime,
            isGateOpen: true,
            attack: voiceModulation.auxiliaryEnvelope.attack,
            decay: voiceModulation.auxiliaryEnvelope.decay,
            sustain: voiceModulation.auxiliaryEnvelope.sustain,
            release: voiceModulation.auxiliaryEnvelope.release
        )
        
        // NEW: Capture current loudness envelope value for smooth release
        let loudnessValue = ModulationRouter.calculateLoudnessEnvelopeValue(
            time: modulationState.loudnessEnvelopeTime,
            isGateOpen: true,
            attack: voiceModulation.loudnessEnvelope.attack,
            decay: voiceModulation.loudnessEnvelope.decay,
            sustain: voiceModulation.loudnessEnvelope.sustain,
            release: voiceModulation.loudnessEnvelope.release,
            startLevel: modulationState.loudnessStartLevel
        )
        
        modulationState.closeGate(
            modulatorValue: modulatorValue,
            auxiliaryValue: auxiliaryValue,
            loudnessValue: loudnessValue
        )
        
        // Mark voice available after release completes
        isPlaying = false
        let releaseTime = voiceModulation.loudnessEnvelope.release * 8 // 'middle ground' value for exponential envelopes
        let releaseStartTime = Date()  // Capture when this release was initiated
        Task {
            try? await Task.sleep(nanoseconds: UInt64(releaseTime * 1_000_000_000))
            await MainActor.run {
                // Only mark available if the voice wasn't retriggered since this release started
                // triggerTime is updated in trigger(), so if it's newer than releaseStartTime,
                // the voice was retriggered and should stay unavailable
                if self.triggerTime < releaseStartTime {
                    self.isAvailable = true
                }
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
        modulationState.baseAmplitude = parameters.amplitude
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
        oscLeft.$modulatingMultiplier.ramp(to: AUValue(modulationState.baseModulatorMultiplier), duration: 0.005)
        oscRight.$modulatingMultiplier.ramp(to: AUValue(modulationState.baseModulatorMultiplier), duration: 0.005)
    }
    
    /// Resets modulation index to base (unmodulated) value
    /// Called when voice LFO modulation amount is set to zero
    func resetModulationIndexToBase() {
        oscLeft.$modulationIndex.ramp(to: AUValue(modulationState.baseModulationIndex), duration: 0.005)
        oscRight.$modulationIndex.ramp(to: AUValue(modulationState.baseModulationIndex), duration: 0.005)
    }
    
    /// Resets filter cutoff to base (unmodulated) value
    /// Called when voice LFO or other modulation amounts are set to zero
    func resetFilterCutoffToBase() {
        // Calculate the key-tracked base (if key tracking is active)
        let keyTrackedBaseCutoff: Double
        if voiceModulation.keyTracking.amountToFilterFrequency != 0.0 {
            let keyTrackOctaves = modulationState.keyTrackingValue * voiceModulation.keyTracking.amountToFilterFrequency
            keyTrackedBaseCutoff = modulationState.baseFilterCutoff * pow(2.0, keyTrackOctaves)
        } else {
            keyTrackedBaseCutoff = modulationState.baseFilterCutoff
        }
        
        // Clamp to valid range
        let clampedCutoff = max(12.0, min(20000.0, keyTrackedBaseCutoff))
        
        filter.$cutoffFrequency.ramp(to: AUValue(clampedCutoff), duration: 0.005)
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
        filter.$cutoffFrequency.ramp(to: AUValue(parameters.clampedCutoff), duration: 0.005)
    }
    
    /// Updates static (non-modulatable) filter parameters
    /// These are applied immediately and never modulated
    /// Should be called on main thread only, never during modulation
    func updateFilterStaticParameters(_ parameters: FilterStaticParameters) {
        // Use 5ms ramps for smooth application
        // These parameters are NEVER touched by the modulation system
        filter.$resonance.ramp(to: AUValue(parameters.clampedResonance), duration: 0.005)
        filter.$distortion.ramp(to: AUValue(parameters.clampedSaturation), duration: 0.005)
    }
    
    /// Updates modulation parameters (Phase 5)
    func updateModulationParameters(_ parameters: VoiceModulationParameters) {
        voiceModulation = parameters
        // Note: Runtime state (modulationState) is not reset here
        // It continues tracking from current position
    }
    
    /// Updates loudness envelope parameters
    /// Note: This only affects the modulation calculation, not the initial attack ramp
    /// Initial attack is always applied at trigger() time with the attack duration
    func updateLoudnessEnvelopeParameters(_ parameters: LoudnessEnvelopeParameters) {
        voiceModulation.loudnessEnvelope = parameters
        // The modulation system will pick up the new parameters on the next update cycle
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
        // Update envelope times based on gate state
        if modulationState.isGateOpen {
            // THREAD-SAFE TRIGGER DETECTION:
            // Check if we've seen a new trigger since last update.
            // This solves race conditions where main thread sets isGateOpen=true but
            // we read a stale triggerTimestamp due to memory ordering issues.
            let currentTime = CACurrentMediaTime()

            if modulationState.triggerSequence != modulationState.lastSeenTriggerSequence {
                // New trigger detected! This is the first modulation update for this new note.
                modulationState.lastSeenTriggerSequence = modulationState.triggerSequence

                // Calculate elapsed time with sanity check for thread race conditions.
                // The first mod update after trigger should be within ~50ms (a few control cycles).
                // If we see invalid values, the timestamp is likely stale due to memory ordering.
                let rawElapsed = currentTime - modulationState.triggerTimestamp
                let preciseElapsedTime: Double
                if rawElapsed >= 0 && rawElapsed < 0.05 {
                    // Reasonable elapsed time - use it
                    preciseElapsedTime = rawElapsed
                } else {
                    // Timestamp seems stale - treat as just triggered (time = 0)
                    // This ensures we enter the attack phase and apply proper handover
                    // CRITICAL: Using 0.0 instead of updateInterval so we don't skip short attacks
                    preciseElapsedTime = 0.0
                }

                modulationState.modulatorEnvelopeTime = preciseElapsedTime
                modulationState.auxiliaryEnvelopeTime = preciseElapsedTime
                modulationState.loudnessEnvelopeTime = preciseElapsedTime
            } else {
                // Same note as before - use timestamp-based timing
                let preciseElapsedTime = currentTime - modulationState.triggerTimestamp
                modulationState.modulatorEnvelopeTime = preciseElapsedTime
                modulationState.auxiliaryEnvelopeTime = preciseElapsedTime
                modulationState.loudnessEnvelopeTime = preciseElapsedTime
            }
        } else {
            // Gate closed (Release): use incremental deltaTime
            // Release starts at time=0.0 (set by closeGate) and increments from there
            // This avoids parameter jumps by quantizing release to the control rate
            modulationState.modulatorEnvelopeTime += deltaTime
            modulationState.auxiliaryEnvelopeTime += deltaTime
            modulationState.loudnessEnvelopeTime += deltaTime  // NEW: Increment loudness envelope time
        }
        
        // Update voice LFO phase and delay ramp (still uses deltaTime for incremental updates)
        updateVoiceLFOPhase(deltaTime: deltaTime, tempo: currentTempo)
        modulationState.updateVoiceLFODelayRamp(
            deltaTime: deltaTime,
            delayTime: voiceModulation.voiceLFO.delayTime
        )
        
        // Calculate envelope values using ModulationRouter
        let modulatorEnvValue = ModulationRouter.calculateActiveEnvelopeValue(
            time: modulationState.modulatorEnvelopeTime,
            isGateOpen: modulationState.isGateOpen,
            attack: voiceModulation.modulatorEnvelope.attack,
            decay: voiceModulation.modulatorEnvelope.decay,
            sustain: voiceModulation.modulatorEnvelope.sustain,
            release: voiceModulation.modulatorEnvelope.release,
            capturedLevel: modulationState.modulatorSustainLevel
        )
        
        let auxiliaryEnvValue = ModulationRouter.calculateActiveEnvelopeValue(
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
        
        // NEW: Apply loudness envelope to fader
        // This controls the voice output level, replacing the old AmplitudeEnvelope node
        applyLoudnessEnvelope()
    }
    
    // MARK: - Voice LFO Phase Update (Phase 5C)
    
    /// Updates the voice LFO phase based on time
    /// Note: Voice LFO frequency is always in Hz (no tempo sync)
    ///
    /// **Timing Precision:**
    /// - Free mode: Uses incremental deltaTime (continuous, ignores trigger)
    /// - Trigger mode: Uses precise elapsed time from trigger timestamp (eliminates jitter)
    /// - Sync mode: Uses incremental deltaTime (global timing, not per-note)
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
        
        // Update phase based on reset mode
        switch lfo.resetMode {
        case .free:
            // Free running: just increment and wrap (no trigger dependency)
            let phaseIncrement = effectiveFrequency * deltaTime
            modulationState.voiceLFOPhase += phaseIncrement
            if modulationState.voiceLFOPhase >= 1.0 {
                modulationState.voiceLFOPhase -= floor(modulationState.voiceLFOPhase)
            }
            
        case .trigger:
            // Trigger reset: calculate precise phase from trigger timestamp
            // This eliminates 0-5ms timing jitter by using absolute time
            let currentTime = CACurrentMediaTime()
            let elapsedSinceTrigger = currentTime - modulationState.triggerTimestamp
            
            // Calculate absolute phase based on elapsed time (cycles = frequency × time)
            let absolutePhase = elapsedSinceTrigger * effectiveFrequency
            
            // Wrap to 0-1 range
            modulationState.voiceLFOPhase = absolutePhase - floor(absolutePhase)
            
        case .sync:
            // Tempo sync reset mode: uses incremental updates (global timing)
            // Not tied to individual note triggers, so deltaTime is appropriate
            let phaseIncrement = effectiveFrequency * deltaTime
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
        let modEnvAttack = voiceModulation.modulatorEnvelope.attack
        let isInAttackPhase = modulationState.isGateOpen && modulationState.modulatorEnvelopeTime < modEnvAttack

        // Calculate envelope contribution to mod index
        let envelopeModIndex: Double
        if isInAttackPhase && modEnvAttack > 0 {
            // During attack phase, use linear interpolation from start to peak
            // This matches the ramp set up by trigger() for smooth handover
            let progress = modulationState.modulatorEnvelopeTime / modEnvAttack
            envelopeModIndex = modulationState.modulatorStartModIndex +
                (modulationState.modulatorPeakModIndex - modulationState.modulatorStartModIndex) * progress
        } else {
            // After attack (decay/sustain/release), use normal calculation
            var effectiveModEnvAmount = voiceModulation.modulatorEnvelope.amountToModulationIndex
            if voiceModulation.touchInitial.amountToModEnvelope != 0.0 {
                effectiveModEnvAmount = ModulationRouter.calculateTouchScaledAmount(
                    baseAmount: effectiveModEnvAmount,
                    initialTouchValue: modulationState.initialTouchX,
                    initialTouchAmount: voiceModulation.touchInitial.amountToModEnvelope
                )
            }
            envelopeModIndex = modulationState.baseModulationIndex + modulatorEnvValue * effectiveModEnvAmount
        }

        // Add LFO and aftertouch modulation on top of envelope
        var finalModIndex = envelopeModIndex

        // Voice LFO contribution (with delay ramp)
        if voiceModulation.voiceLFO.amountToModulatorLevel != 0.0 {
            let lfoContribution = voiceLFORawValue * voiceModulation.voiceLFO.amountToModulatorLevel * modulationState.voiceLFORampFactor
            finalModIndex += lfoContribution
        }

        // Aftertouch contribution
        if voiceModulation.touchAftertouch.amountToModulatorLevel != 0.0 {
            let aftertouchContribution = aftertouchDelta * voiceModulation.touchAftertouch.amountToModulatorLevel
            finalModIndex += aftertouchContribution
        }

        // Clamp and apply
        finalModIndex = max(0.0, min(10.0, finalModIndex))

        // During attack phase, use remaining attack time as ramp duration for smooth handover
        let rampDuration: Float
        if isInAttackPhase && modEnvAttack > 0 {
            let remainingAttack = modEnvAttack - modulationState.modulatorEnvelopeTime
            rampDuration = Float(max(0.001, remainingAttack))  // Minimum 1ms
        } else {
            rampDuration = ControlRateConfig.modulationRampDuration
        }

        oscLeft.$modulationIndex.ramp(to: AUValue(finalModIndex), duration: rampDuration)
        oscRight.$modulationIndex.ramp(to: AUValue(finalModIndex), duration: rampDuration)
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
    /// Sources: Auxiliary envelope, Voice LFO, Global LFO, Aftertouch
    /// Note: Key tracking is NOT applied here - it's a note-on property applied in trigger()
    private func applyCombinedFilterFrequency(
        auxiliaryEnvValue: Double,
        voiceLFORawValue: Double,
        globalLFORawValue: Double,
        globalLFOParameters: GlobalLFOParameters,
        keyTrackValue: Double,  // Kept for signature compatibility but not used
        aftertouchDelta: Double
    ) {
        // Check if any CONTINUOUS modulation source is active
        // Key tracking is NOT checked here - it's applied once at note-on in trigger()
        let hasAuxEnv = voiceModulation.auxiliaryEnvelope.amountToFilterFrequency != 0.0
        let hasVoiceLFO = voiceModulation.voiceLFO.amountToFilterFrequency != 0.0
        let hasGlobalLFO = globalLFOParameters.amountToFilterFrequency != 0.0
        let hasAftertouch = voiceModulation.touchAftertouch.amountToFilterFrequency != 0.0
        let hasInitialTouchToFilter = voiceModulation.touchInitial.amountToAuxEnvCutoff != 0.0

        guard hasAuxEnv || hasVoiceLFO || hasGlobalLFO || hasAftertouch || hasInitialTouchToFilter else { return }

        let auxEnvAttack = voiceModulation.auxiliaryEnvelope.attack
        let isInAttackPhase = modulationState.isGateOpen && modulationState.auxiliaryEnvelopeTime < auxEnvAttack

        // Calculate envelope contribution to filter cutoff
        let envelopeCutoff: Double
        if isInAttackPhase && auxEnvAttack > 0 && hasAuxEnv {
            // During attack phase, use linear interpolation from start to peak
            // This matches the ramp set up by trigger() for smooth handover
            let progress = modulationState.auxiliaryEnvelopeTime / auxEnvAttack
            envelopeCutoff = modulationState.auxiliaryStartFilterCutoff +
                (modulationState.auxiliaryPeakFilterCutoff - modulationState.auxiliaryStartFilterCutoff) * progress
        } else {
            // After attack (decay/sustain/release), use normal calculation
            var effectiveAuxEnvFilterAmount = voiceModulation.auxiliaryEnvelope.amountToFilterFrequency
            if voiceModulation.touchInitial.amountToAuxEnvCutoff != 0.0 {
                effectiveAuxEnvFilterAmount = ModulationRouter.calculateTouchScaledAmount(
                    baseAmount: effectiveAuxEnvFilterAmount,
                    initialTouchValue: modulationState.initialTouchX,
                    initialTouchAmount: voiceModulation.touchInitial.amountToAuxEnvCutoff
                )
            }

            // Calculate the base cutoff with key tracking already applied
            let keyTrackedBaseCutoff: Double
            if voiceModulation.keyTracking.amountToFilterFrequency != 0.0 {
                let keyTrackOctaves = modulationState.keyTrackingValue * voiceModulation.keyTracking.amountToFilterFrequency
                keyTrackedBaseCutoff = modulationState.baseFilterCutoff * pow(2.0, keyTrackOctaves)
            } else {
                keyTrackedBaseCutoff = modulationState.baseFilterCutoff
            }

            // Apply envelope modulation (octave-based)
            let octaveOffset = auxiliaryEnvValue * effectiveAuxEnvFilterAmount
            envelopeCutoff = keyTrackedBaseCutoff * pow(2.0, octaveOffset)
        }

        // Add LFO and aftertouch modulation on top of envelope (in octaves)
        var finalCutoff = envelopeCutoff

        // Voice LFO contribution
        if hasVoiceLFO {
            let lfoOctaves = voiceLFORawValue * voiceModulation.voiceLFO.amountToFilterFrequency * modulationState.voiceLFORampFactor
            finalCutoff *= pow(2.0, lfoOctaves)
        }

        // Global LFO contribution
        if hasGlobalLFO {
            let globalLfoOctaves = globalLFORawValue * globalLFOParameters.amountToFilterFrequency
            finalCutoff *= pow(2.0, globalLfoOctaves)
        }

        // Aftertouch contribution
        if hasAftertouch {
            let aftertouchOctaves = aftertouchDelta * voiceModulation.touchAftertouch.amountToFilterFrequency
            finalCutoff *= pow(2.0, aftertouchOctaves)
        }

        // Clamp to valid range
        finalCutoff = max(12.0, min(20000.0, finalCutoff))
        
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
        
        // During attack phase, use remaining attack time as ramp duration for smooth handover
        let rampDuration: Float
        if isInAttackPhase && auxEnvAttack > 0 && hasAuxEnv {
            let remainingAttack = auxEnvAttack - modulationState.auxiliaryEnvelopeTime
            rampDuration = Float(max(0.001, remainingAttack))  // Minimum 1ms
        } else {
            rampDuration = ControlRateConfig.modulationRampDuration
        }

        filter.$cutoffFrequency.ramp(to: AUValue(smoothedCutoff), duration: rampDuration)
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
            oscLeft.$modulatingMultiplier.ramp(to: AUValue(finalMultiplier), duration: ControlRateConfig.modulationRampDuration)
            oscRight.$modulatingMultiplier.ramp(to: AUValue(finalMultiplier), duration: ControlRateConfig.modulationRampDuration)
        }

        // Note: Filter frequency modulation is handled in applyCombinedFilterFrequency()
        // Note: Delay time and mixer volume (tremolo) modulation are handled at VoicePool level
    }
    
    /// Applies loudness envelope to the fader (replaces AmplitudeEnvelope node)
    /// This provides manual control over the voice output level with support for
    /// starting from non-zero levels (critical for voice stealing and legato)
    private func applyLoudnessEnvelope() {
        let time = modulationState.loudnessEnvelopeTime
        let attack = voiceModulation.loudnessEnvelope.attack

        // ATTACK PHASE: Stay completely passive and let trigger()'s ramp run undisturbed
        // Using envelope time (not wall clock) for reliable attack phase detection
        let isInAttackPhase = modulationState.isGateOpen && time < attack

        if isInAttackPhase {
            // Log but don't apply any ramps - let trigger() handle the attack
            print("🔊 ATTACK: time=\(String(format: "%.1f", time * 1000))ms, attack=\(String(format: "%.1f", attack * 1000))ms (passive)")
            return
        }

        // Calculate the current expected envelope value for decay/sustain/release phases
        // NOTE: We cannot use fader.leftGain because AudioKit's gain property always reports
        // either the start or target value of a ramp, never the intermediate interpolated value.
        let calculatedEnvelopeValue = ModulationRouter.calculateLoudnessEnvelopeValue(
            time: time,
            isGateOpen: modulationState.isGateOpen,
            attack: attack,
            decay: voiceModulation.loudnessEnvelope.decay,
            sustain: voiceModulation.loudnessEnvelope.sustain,
            release: voiceModulation.loudnessEnvelope.release,
            capturedLevel: modulationState.loudnessSustainLevel,
            startLevel: modulationState.loudnessStartLevel
        )

        // Log first post-attack update to see transition
        if modulationState.isGateOpen && time < attack + 0.05 {
            print("🔊 POST-ATTACK: time=\(String(format: "%.1f", time * 1000))ms, attack=\(String(format: "%.1f", attack * 1000))ms, envelope=\(String(format: "%.3f", calculatedEnvelopeValue))")
        }

        // DECAY/SUSTAIN/RELEASE: Apply calculated envelope value with standard ramp
        fader.$leftGain.ramp(to: AUValue(calculatedEnvelopeValue), duration: ControlRateConfig.modulationRampDuration)
        fader.$rightGain.ramp(to: AUValue(calculatedEnvelopeValue), duration: ControlRateConfig.modulationRampDuration)
    }
}

