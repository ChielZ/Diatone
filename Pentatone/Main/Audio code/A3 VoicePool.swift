//
//  A3 VoicePool.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 20/12/2025.
//

import Foundation
import AudioKit
import AudioKitEX
import SoundpipeAudioKit
import DunneAudioKit

/// actual polyphony
let nominalPolyphony = 10
var currentPolyphony = nominalPolyphony

/// Manages allocation and lifecycle of polyphonic voices
/// Uses round-robin allocation with availability checking and voice stealing
final class VoicePool {
    
    // MARK: - Voice Management
    
    /// All available voices
    private(set) var voices: [PolyphonicVoice] = []
    
    /// Mixer to combine all voice outputs
    let voiceMixer: Mixer
    
    /// Round-robin allocation pointer
    private var currentVoiceIndex: Int = 0
    
    /// Maps key indices (0-17) to their currently playing voices
    /// Enables precise release tracking without frequency matching
    private var keyToVoiceMap: [Int: PolyphonicVoice] = [:]
    
    /// In monophonic mode, tracks which key currently "owns" the active voice
    /// Only the owning key can release the voice (last-note priority)
    private var monoVoiceOwner: Int? = nil
    
    /// Legato mode: in monophonic mode, retriggers without restarting envelopes
    var legatoMode: Bool = true
    
    /// Note stack entry for monophonic mode
    private struct MonoNoteStackEntry {
        let keyIndex: Int
        let frequency: Double
        let globalPitch: GlobalPitchParameters
    }
    
    /// Note stack for monophonic mode - tracks held keys in order pressed
    /// Most recent key is at the end of the array (top of stack)
    /// When a key is released, we can return to playing the previous key
    private var monoNoteStack: [MonoNoteStackEntry] = []
    
    /// Flag to track if the voice pool has been initialized
    private var isInitialized: Bool = false
    
    /// Current voice template - used to provide fresh base values at trigger time
    /// Updated whenever parameters change in the UI
    private var currentTemplate: VoiceParameters = .default
    
    // MARK: - FX Node References
    
    /// Reference to delay node for global LFO modulation
    /// Set after engine initialization via setFXNodes()
    private weak var delay: StereoDelay?
    
    /// Reference to reverb node for global LFO modulation
    /// Set after engine initialization via setFXNodes()
    private weak var reverb: CostelloReverb?
    
    // MARK: - Global Modulation (Phase 5)
    
    /// Global LFO affecting all voices (will be implemented in Phase 5)
    var globalLFO: GlobalLFOParameters = .default
    
    /// Base delay time (from tempo-synced value, before LFO modulation)
    private var baseDelayTime: Double = 0.5  // Default: 1/4 note at 120 BPM
    
    /// Base voice mixer volume (preVolume, before global LFO tremolo modulation)
    /// This should be kept in sync with master.output.preVolume
    private var basePreVolume: Double = 0.5  // Default matches OutputParameters.default
    
    // MARK: - Initialization
    
    /// Creates a voice pool with the specified polyphony
    /// - Parameter voiceCount: Number of voices (defaults to currentPolyphony)
    ///   Use 1 for monophonic mode, nominalPolyphony for polyphonic mode
    init(voiceCount: Int = currentPolyphony) {
        // Create mixer first
        self.voiceMixer = Mixer()
        
        // Always create nominalPolyphony voices (don't change voice count at runtime)
        // In mono mode, we just use the first voice only
        let actualVoiceCount = nominalPolyphony
        
        // Create all voices
        let voiceParams = VoiceParameters.default
        for _ in 0..<actualVoiceCount {
            let voice = PolyphonicVoice(parameters: voiceParams)
            voices.append(voice)
        }
        
        // Connect all voices to mixer
        for voice in voices {
            voiceMixer.addInput(voice.fader)
        }
        
        print("🎵 VoicePool created with \(voices.count) voice(s) available, starting in \(voiceCount == 1 ? "monophonic" : "polyphonic") mode")
    }
    
    /// Initializes all voices (starts oscillators)
    /// Must be called after the audio engine is started
    func initialize() {
        guard !isInitialized else {
            print("🎵 VoicePool already initialized, skipping")
            return
        }
        
        for voice in voices {
            voice.initialize()
        }
        
        isInitialized = true
        print("🎵 VoicePool initialized with \(voices.count) voices")
    }
    
    /// Sets references to FX nodes for global LFO modulation
    /// Must be called after FX nodes are created in the audio engine
    /// - Parameters:
    ///   - delay: The stereo delay node
    ///   - reverb: The reverb node
    func setFXNodes(delay: StereoDelay, reverb: CostelloReverb) {
        self.delay = delay
        self.reverb = reverb
        print("🎵 VoicePool: FX node references set")
    }
    
    // MARK: - Voice Allocation
    
    /// Finds an available voice, or steals the oldest one if all are busy
    /// Uses round-robin allocation starting from current index
    /// In monophonic mode (currentPolyphony == 1), always uses voice 0
    private func findAvailableVoice() -> PolyphonicVoice {
        // Monophonic mode: always use voice 0 and steal it if needed
        if currentPolyphony == 1 {
            let monoVoice = voices[0]
            if monoVoice.isAvailable {
                return monoVoice
            } else {
                // Steal the mono voice - no explicit release needed
                // The new trigger will handle smoothing via fader level capture
                monoVoice.isAvailable = true
                print("⚠️ Mono voice stealing")
                return monoVoice
            }
        }
        
        // Polyphonic mode: use round-robin with all voices
        var checkedCount = 0
        var index = currentVoiceIndex
        
        // First pass: look for available voices (use all nominalPolyphony voices)
        while checkedCount < nominalPolyphony {
            if voices[index].isAvailable {
                currentVoiceIndex = index
                return voices[index]
            }
            
            index = (index + 1) % nominalPolyphony
            checkedCount += 1
        }
        
        // No available voice found - steal the oldest one
        // Find voice with earliest trigger time (from all voices)
        let oldestVoice = voices.min(by: { $0.triggerTime < $1.triggerTime })!
        
        // Mark as available - the new trigger will handle smoothing via fader level capture
        oldestVoice.isAvailable = true  // Mark immediately available
        
        print("⚠️ Voice stealing: Took voice triggered at \(oldestVoice.triggerTime)")
        
        return oldestVoice
    }
    
    /// Increments to the next voice index (round-robin)
    /// Only used in polyphonic mode
    private func incrementVoiceIndex() {
        if currentPolyphony > 1 {
            currentVoiceIndex = (currentVoiceIndex + 1) % nominalPolyphony
        }
        // In mono mode, don't increment (always stay at 0)
    }
    
    // MARK: - Note Triggering
    
    /// Allocates a voice and triggers it with the specified frequency
    /// - Parameters:
    ///   - frequency: The base frequency to play (from keyboard/scale)
    ///   - keyIndex: The key index (0-17) triggering this note
    ///   - globalPitch: Global pitch modifiers (transpose, octave, fine tune)
    ///   - initialTouchX: Initial touch x-position (0.0 = left, 1.0 = right) for velocity-like response
    /// - Returns: The allocated voice (for reference if needed)
    @discardableResult
    func allocateVoice(frequency: Double, forKey keyIndex: Int, globalPitch: GlobalPitchParameters = .default, initialTouchX: Double = 0.5) -> PolyphonicVoice {
        guard isInitialized else {
            assertionFailure("VoicePool must be initialized before allocating voices")
            return voices[0]
        }
        
        // Apply global pitch modifiers to the base frequency
        let finalFrequency = frequency * globalPitch.combinedFactor
        
        // In monophonic mode, add key to note stack
        if currentPolyphony == 1 {
            // Remove key if it's already in the stack (shouldn't happen, but be safe)
            monoNoteStack.removeAll { $0.keyIndex == keyIndex }
            // Add key to top of stack with its frequency
            let entry = MonoNoteStackEntry(keyIndex: keyIndex, frequency: frequency, globalPitch: globalPitch)
            monoNoteStack.append(entry)
            print("🎵 Mono note stack: \(monoNoteStack.map { $0.keyIndex }) (added \(keyIndex) @ \(String(format: "%.2f", frequency)) Hz)")
        }
        
        // Check for legato conditions: monophonic mode + active voice + legato enabled
        let isLegatoRetrigger = currentPolyphony == 1 && voices[0].isPlaying && legatoMode
        
        if isLegatoRetrigger {
            // Legato retrigger: update parameters without restarting envelopes
            let voice = voices[0]
            //voice.filter.reset()
            // Update frequency with smooth glide
            voice.retrigger(
                frequency: finalFrequency,
                initialTouchX: initialTouchX,
                
                templateFilterCutoff: currentTemplate.filter.clampedCutoff
            )
            
            // Update key mapping and ownership
            keyToVoiceMap[keyIndex] = voice
            monoVoiceOwner = keyIndex
            
            print("🎵 Key \(keyIndex): Legato retrigger, frequency \(frequency) Hz → final \(finalFrequency) Hz (×\(globalPitch.combinedFactor)), touchX \(String(format: "%.2f", initialTouchX))")
            
            return voice
        } else {
            // Normal trigger: find/allocate voice and start envelopes
            let voice = findAvailableVoice()
            
            // Set frequency and trigger with initial touch value
            voice.setFrequency(finalFrequency)
            voice.trigger(
                initialTouchX: initialTouchX, 
                templateFilterCutoff: currentTemplate.filter.clampedCutoff,
                templateFilterStatic: currentTemplate.filterStatic
            )
            
            // Map this key to the voice for precise release tracking
            keyToVoiceMap[keyIndex] = voice
            
            // In monophonic mode, this key becomes the new owner
            if currentPolyphony == 1 {
                monoVoiceOwner = keyIndex
            }
            
            print("🎵 Key \(keyIndex): Allocated voice, base frequency \(frequency) Hz → final \(finalFrequency) Hz (×\(globalPitch.combinedFactor)), touchX \(String(format: "%.2f", initialTouchX))")
            
            // Move to next voice for round-robin
            incrementVoiceIndex()
            
            return voice
        }
    }
    
    /// Releases the voice associated with a specific key
    /// In monophonic mode with note stack, may retrigger a previously held note
    /// - Parameter keyIndex: The key index (0-17) to release
    func releaseVoice(forKey keyIndex: Int) {
        guard let voice = keyToVoiceMap[keyIndex] else {
            // Key not in map - might have already been released or replaced
            // Still need to remove from mono note stack if present
            if currentPolyphony == 1 {
                monoNoteStack.removeAll { $0.keyIndex == keyIndex }
                print("🎵 Key \(keyIndex): Removed from note stack (no voice mapped)")
            }
            return
        }
        
        // In monophonic mode, handle note stack for retriggering
        if currentPolyphony == 1 {
            // Remove this key from the note stack
            monoNoteStack.removeAll { $0.keyIndex == keyIndex }
            print("🎵 Mono note stack: \(monoNoteStack.map { $0.keyIndex }) (removed \(keyIndex))")
            
            // Check if this key was the owner (top of stack)
            if monoVoiceOwner == keyIndex {
                // Check if there are other keys still held
                if let previousEntry = monoNoteStack.last {
                    // Retrigger the previous note (most recent still-held key)
                    let previousKeyIndex = previousEntry.keyIndex
                    let previousFrequency = previousEntry.frequency
                    let previousGlobalPitch = previousEntry.globalPitch
                    
                    print("🎵 Key \(keyIndex): Released, retriggering previous key \(previousKeyIndex) @ \(String(format: "%.2f", previousFrequency)) Hz")
                    
                    // Calculate final frequency with global pitch
                    let finalFrequency = previousFrequency * previousGlobalPitch.combinedFactor
                    
                    // Retrigger in legato mode (no envelope restart)
                    if legatoMode && voice.isPlaying {
                        // Smooth transition to previous note
                        voice.retrigger(
                            frequency: finalFrequency,
                            initialTouchX: 0.5,  // Default touch position (middle)
                            templateFilterCutoff: currentTemplate.filter.clampedCutoff
                        )
                    } else {
                        // Non-legato: set frequency directly
                        voice.setFrequency(finalFrequency)
                    }
                    
                    // Update ownership and mapping
                    monoVoiceOwner = previousKeyIndex
                    keyToVoiceMap.removeValue(forKey: keyIndex)
                    keyToVoiceMap[previousKeyIndex] = voice
                    
                    // Don't call voice.release() - keep the note playing!
                    print("🎵 Key \(keyIndex): Voice remains active, now playing key \(previousKeyIndex)")
                    
                    return  // Early return - voice stays active
                } else {
                    // No more keys held - release normally
                    voice.release()
                    print("🎵 Key \(keyIndex): Released (last mono key)")
                    monoVoiceOwner = nil
                }
            } else {
                // This key was not the owner - just remove from map without releasing
                print("🎵 Key \(keyIndex): Removed from map (not mono owner)")
            }
        } else {
            // Polyphonic mode - always release
            voice.release()
            print("🎵 Key \(keyIndex): Released")
        }
        
        // Remove mapping - key is no longer pressed
        keyToVoiceMap.removeValue(forKey: keyIndex)
        
        // Note: Voice will mark itself available after release duration completes
    }
    /*
    /// Stops all voices immediately
    func stopAll() {
        for voice in voices {
            voice.release()  // Use voice's release method instead of direct envelope access
            voice.isAvailable = true
        }
        keyToVoiceMap.removeAll()
        monoVoiceOwner = nil
        print("🎵 All voices stopped")
    }
    */
    
    /// Immediately silences all voices and resets them to available state
    /// This is more aggressive than stopAll() - it sets faders to zero instantly
    /// Used during preset switching to ensure a completely clean slate
    func silenceAndResetAllVoices() {
        for voice in voices {
            // Set fader gains to zero immediately (no ramp)
            voice.fader.$leftGain.ramp(to: 0.0, duration: 0)
            voice.fader.$rightGain.ramp(to: 0.0, duration: 0)
            
            // Mark voice as available and not playing
            voice.isAvailable = true
            voice.isPlaying = false
            
            // Reset modulation state so envelope tracking stops
            voice.modulationState.isGateOpen = false
            voice.modulationState.loudnessEnvelopeTime = 0.0
            voice.modulationState.loudnessStartLevel = 0.0
            voice.modulationState.loudnessSustainLevel = 0.0
        }
        
        // Clear all key mappings
        keyToVoiceMap.removeAll()
        monoVoiceOwner = nil
        monoNoteStack.removeAll()
        
        print("🎵 All voices silenced and reset to available state")
    }
    
    // MARK: - Voice Recreation (for waveform changes)
    
    /// Recreates only the oscillators in all voices with a new waveform
    /// This is more efficient than recreating entire voices and avoids connection issues
    /// Warning: Will briefly interrupt any currently playing notes
    /// - Parameters:
    ///   - waveform: The new waveform to use
    ///   - completion: Called when oscillator recreation is complete
    func recreateOscillators(waveform: OscillatorWaveform, completion: @escaping () -> Void) {
        print("🎵 Starting oscillator recreation with waveform: \(waveform)...")
        
        // Stop all playing notes and clear key mappings
        silenceAndResetAllVoices()
        
        // Recreate oscillators in each voice
        for (index, voice) in voices.enumerated() {
            voice.recreateOscillators(waveform: waveform)
            print("🎵   Voice \(index): oscillators recreated")
        }
        
        print("🎵 ✅ Oscillator recreation complete - \(voices.count) voices ready")
        completion()
    }
    
    
      
    // MARK: - Polyphony Adjustment
    
    /// Switches between monophonic and polyphonic modes
    /// Does NOT recreate voices - just changes which voices are used for allocation
    /// - Parameter count: Number of voices to use (1 for mono, nominalPolyphony for poly)
    /// - Parameter completion: Called after mode switch is complete
    func setPolyphony(_ count: Int, completion: @escaping () -> Void) {
        print("🎵 Switching from \(currentPolyphony == 1 ? "monophonic" : "polyphonic") to \(count == 1 ? "monophonic" : "polyphonic") mode...")
        
        // Stop all playing notes and clear key mappings
        silenceAndResetAllVoices()
        
        // Reset voice index
        currentVoiceIndex = 0
        
        // Clear mono voice owner when switching modes
        monoVoiceOwner = nil
        
        // Clear mono note stack when switching modes
        monoNoteStack.removeAll()
        
        // Update global currentPolyphony
        currentPolyphony = count
        
        print("🎵 Mode switched to \(count == 1 ? "monophonic (using voice 0 only)" : "polyphonic (using all \(nominalPolyphony) voices)")")
        completion()
    }
    
    // MARK: - Parameter Updates
    
    /// Updates the current template for fresh base values at trigger time
    /// Call this whenever voice parameters are changed in the UI
    /// - Parameter template: The new voice parameter template
    func updateTemplate(_ template: VoiceParameters) {
        currentTemplate = template
    }
    
    /// Updates oscillator parameters for all voices
    func updateAllVoiceOscillators(_ parameters: OscillatorParameters) {
        // Update template
        currentTemplate.oscillator = parameters
        
        // Update all voices with global LFO awareness
        for voice in voices {
            voice.updateOscillatorParameters(parameters, globalLFO: globalLFO)
        }
    }
    
    /// Updates filter parameters for all voices (MODULATABLE only - cutoff frequency)
    func updateAllVoiceFilters(_ parameters: FilterParameters) {
        // Update template so next triggered voice gets fresh values
        currentTemplate.filter = parameters
        
        // Update ALL voices immediately
        // Cutoff is modulatable, but we need to update the base value
        for voice in voices {
            voice.updateFilterParameters(parameters)
        }
    }
    
    /// Updates static filter parameters for all voices (NON-MODULATABLE - resonance, saturation)
    /// These parameters are applied at note-on and should be consistent across all voices
    /// MAIN THREAD ONLY - never called during modulation
    func updateAllVoiceFilterStatic(_ parameters: FilterStaticParameters) {
        // Update template so next triggered voice gets fresh values
        currentTemplate.filterStatic = parameters
        
        // Update ALL voices immediately
        // These are non-modulatable and must be instantly applied to all voices
        for voice in voices {
            voice.updateFilterStaticParameters(parameters)
        }
    }
    
    /// Updates loudness envelope parameters for all voices
    /// Note: The old envelope field is maintained for backward compatibility with presets
    func updateAllVoiceLoudnessEnvelopes(_ parameters: LoudnessEnvelopeParameters) {
        // Update template
        currentTemplate.loudnessEnvelope = parameters
        
        // Update all voices (envelope affects ongoing playback)
        for voice in voices {
            voice.updateLoudnessEnvelopeParameters(parameters)
        }
    }
    
    /// Updates loudness envelope parameters from old EnvelopeParameters structure
    /// This is for backward compatibility when the UI or preset system uses the old structure
    @available(*, deprecated, message: "Use updateAllVoiceLoudnessEnvelopes with LoudnessEnvelopeParameters instead")
    func updateAllVoiceEnvelopes(_ parameters: EnvelopeParameters) {
        // Convert old parameters to new loudness envelope
        let loudnessParams = parameters.toLoudnessEnvelope()
        updateAllVoiceLoudnessEnvelopes(loudnessParams)
    }
    
    /// Updates detune mode for all voices
    func updateDetuneMode(_ mode: DetuneMode) {
        for voice in voices {
            voice.detuneMode = mode
        }
    }
    
    /// Updates frequency offset in cents for all voices (proportional mode)
    func updateFrequencyOffsetCents(_ cents: Double) {
        for voice in voices {
            voice.frequencyOffsetCents = cents
        }
    }
    
    /// Updates frequency offset in Hz for all voices (constant mode)
    func updateFrequencyOffsetHz(_ hz: Double) {
        for voice in voices {
            voice.frequencyOffsetHz = hz
        }
    }
    
    // MARK: - Modulation (Phase 5)
    
    /// Control-rate timer for modulation updates (Phase 5B+)
    private var modulationTimer: DispatchSourceTimer?
    
    /// Global modulation state (Phase 5C)
    private var globalModulationState = GlobalModulationState()
    
    /// Current tempo for tempo-synced modulation (Phase 5C)
    var currentTempo: Double = 120.0 {
        didSet {
            globalModulationState.currentTempo = currentTempo
        }
    }
    
    /// Updates global LFO parameters
    func updateGlobalLFO(_ parameters: GlobalLFOParameters) {
        globalLFO = parameters
    }
    
    /// Updates just the global LFO frequency (used for tempo sync recalculation)
    /// - Parameter frequency: The new frequency in Hz
    func updateGlobalLFOFrequency(_ frequency: Double) {
        globalLFO.frequency = frequency
    }
    
    /// Resets the delay time to its base (unmodulated) value
    /// Called when LFO modulation amount is set to zero
    func resetDelayTimeToBase() {
        delay?.$time.ramp(to: AUValue(baseDelayTime), duration: 0.005)
    }
    
    /// Resets the voice mixer volume to its base (unmodulated) value
    /// Called when global LFO modulation amount is set to zero
    func resetMixerVolumeToBase() {
        voiceMixer.volume = AUValue(basePreVolume)
    }
    
    /// Updates the base mixer volume (preVolume, before global LFO tremolo modulation)
    /// Should be called whenever preVolume changes in the UI
    /// - Parameter preVolume: The base pre-volume (0.0 - 1.0)
    func updateBasePreVolume(_ preVolume: Double) {
        basePreVolume = preVolume
        // If no global LFO modulation is active, apply directly to mixer
        if globalLFO.amountToVoiceMixerVolume <= 0.0001 {
            voiceMixer.volume = AUValue(preVolume)
        }
        print("🎵 VoicePool: Base preVolume updated to \(preVolume)")
    }
    
    /// Resets modulator multiplier to base for all voices
    /// Called when global LFO modulation amount is set to zero
    func resetModulatorMultiplierToBase() {
        for voice in voices {
            voice.resetModulatorMultiplierToBase()
        }
    }
    
    /// Resets modulation index to base for all voices
    /// Called when voice LFO modulation amount is set to zero
    func resetModulationIndexToBase() {
        for voice in voices {
            voice.resetModulationIndexToBase()
        }
    }
    
    /// Resets filter cutoff to base for all voices
    /// Called when voice LFO or other filter modulation amounts are set to zero
    func resetFilterCutoffToBase() {
        for voice in voices {
            voice.resetFilterCutoffToBase()
        }
    }
    
    /// Updates the base delay time (tempo-synced value before LFO modulation)
    /// Should be called whenever tempo or delay time value changes
    /// - Parameter delayTime: The delay time in seconds (already calculated from tempo and time value)
    func updateBaseDelayTime(_ delayTime: Double) {
        baseDelayTime = delayTime
        print("🎵 VoicePool: Base delay time updated to \(delayTime)s")
    }
    
    /// Updates modulation parameters for all voices
    func updateAllVoiceModulation(_ parameters: VoiceModulationParameters) {
        // Update template
        currentTemplate.modulation = parameters
        
        // Update all voices
        for voice in voices {
            voice.updateModulationParameters(parameters)
        }
    }
    
    /// Starts the modulation update loop (Phase 5B)
    /// Control rate: 200 Hz (5ms intervals) for smooth envelopes
    func startModulation() {
        guard modulationTimer == nil else {
            print("🎵 Modulation timer already running")
            return
        }
        
        // Create a dispatch timer on a background queue
        let queue = DispatchQueue(label: "com.pentatone.modulation", qos: .userInteractive)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        
        // Set to fire every 5ms (200 Hz)
        timer.schedule(deadline: .now(), repeating: ControlRateConfig.updateInterval)
        
        timer.setEventHandler { [weak self] in
            self?.updateModulation()
        }
        
        timer.resume()
        modulationTimer = timer
        
        print("🎵 Modulation system started at \(ControlRateConfig.updateRate) Hz")
    }
    
    /// Stops the modulation update loop
    func stopModulation() {
        modulationTimer?.cancel()
        modulationTimer = nil
        print("🎵 Modulation system stopped")
    }
    
    /// Updates modulation for all active voices (refactored for fixed destinations)
    /// Called by control-rate timer at 200 Hz on background thread
    private func updateModulation() {
        let deltaTime = ControlRateConfig.updateInterval
        
        // Update global LFO phase and get raw value
        let globalLFORawValue = updateGlobalLFOPhase(deltaTime: deltaTime)
        
        // Apply global LFO to global-level destinations (delay time only)
        applyGlobalLFOToGlobalParameters(rawValue: globalLFORawValue)
        
        // Update all active voices with global LFO parameters
        // Note: This runs on background thread, AudioKit parameter updates are thread-safe
        for voice in voices //where !voice.isAvailable
        {
            voice.applyModulation(
                globalLFO: (rawValue: globalLFORawValue, parameters: globalLFO),
                deltaTime: deltaTime,
                currentTempo: currentTempo
            )
        }
    }
    
    // MARK: - Global LFO Phase Management (Refactored)
    
    /// Updates the global LFO phase and returns the raw waveform value
    /// - Parameter deltaTime: Time since last update (typically 0.005 seconds)
    /// - Returns: Raw global LFO value (-1.0 to +1.0, unscaled by amounts)
    private func updateGlobalLFOPhase(deltaTime: Double) -> Double {
        guard globalLFO.isEnabled else { return 0.0 }
        
        // Phase increment calculation
        // Get actual frequency based on mode (sync mode uses tempo, free/trigger mode uses Hz)
        let actualFrequency = globalLFO.actualFrequency(tempo: currentTempo)
        let phaseIncrement = actualFrequency * deltaTime
        
        // Update phase (global LFO is always free-running or sync, never trigger)
        globalModulationState.globalLFOPhase += phaseIncrement
        
        // Wrap phase to 0-1 range
        if globalModulationState.globalLFOPhase >= 1.0 {
            globalModulationState.globalLFOPhase -= floor(globalModulationState.globalLFOPhase)
        }
        
        // Get raw LFO value (waveform output, not scaled by amounts)
        return globalLFO.rawValue(at: globalModulationState.globalLFOPhase)
    }
    
    /// Applies global LFO modulation to global-level parameters (delay time, mixer volume)
    /// - Parameter rawValue: Raw global LFO value (-1.0 to +1.0, unscaled)
    private func applyGlobalLFOToGlobalParameters(rawValue: Double) {
        guard globalLFO.isEnabled else { return }
        
        // Global LFO Destination 1: Voice Mixer Volume (tremolo)
        // Apply global tremolo effect to voice mixer (affects all voices at once)
        // Uses basePreVolume (which should match master.output.preVolume) as the baseline
        if globalLFO.amountToVoiceMixerVolume != 0.0 {
            let finalVolume = ModulationRouter.calculateVoiceMixerVolume(
                baseVolume: basePreVolume,
                globalLFOValue: rawValue,
                globalLFOAmount: globalLFO.amountToVoiceMixerVolume
            )
            // Direct assignment (Mixer.volume doesn't support ramping)
            voiceMixer.volume = AUValue(finalVolume)
        }
        
        // Global LFO Destination 2: Delay Time
        // Apply LFO offset to the base tempo-synced delay time (vibrato effect)
        if globalLFO.amountToDelayTime != 0.0, let delay = self.delay {
            let finalDelayTime = ModulationRouter.calculateDelayTime(
                baseDelayTime: baseDelayTime,  // Use stored base (tempo-synced value)
                globalLFOValue: rawValue,
                globalLFOAmount: globalLFO.amountToDelayTime
            )
            // Use ramp for smooth changes (no clicks)
            delay.$time.ramp(to: AUValue(finalDelayTime), duration: 0.005)
        }
        
        // Note: Other global LFO destinations (modulator multiplier, filter)
        // are voice-level and handled by PolyphonicVoice.applyGlobalLFO()
    }
    
    // MARK: - Diagnostics
    
    /// Returns the number of currently active (unavailable) voices
    var activeVoiceCount: Int {
        voices.filter { !$0.isAvailable }.count
    }
    
    /// Prints current voice pool status
    func printStatus() {
        print("🎵 Voice Pool Status:")
        print("   Total voices: \(voices.count)")
        print("   Active voices: \(activeVoiceCount)")
        print("   Available voices: \(voices.count - activeVoiceCount)")
        print("   Keys pressed: \(keyToVoiceMap.count)")
        print("   Global LFO: \(globalLFO.isEnabled ? "enabled" : "disabled")")
        print("   Modulation timer: \(modulationTimer != nil ? "running" : "stopped")")
    }
}
