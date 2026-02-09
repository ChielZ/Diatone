//
//
//  A5 AudioEngine.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 02/12/2025.
//

import AudioKit
import SoundpipeAudioKit
import AudioKitEX
import AVFAudio
import DunneAudioKit

// Shared engine and mixer for the entire app (single engine architecture)
let sharedEngine = AudioEngine()
private(set) var fxDelay: StereoDelay!
private(set) var delayLowpass: LowPassButterworthFilter!
private(set) var delayDryWetMixer: DryWetMixer!
private(set) var fxReverb: CostelloReverb!
private(set) var outputMixer: Mixer!

// MARK: - Polyphonic Voice Pool Architecture
// New polyphonic voice pool with dynamic voice allocation
private(set) var voicePool: VoicePool!


// Configure and activate the audio session explicitly (iOS)
enum AudioSessionManager {
    static func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Set preferred sample rate BEFORE activating session
            let desiredSampleRate: Double
            if #available(iOS 18.0, *) {
                desiredSampleRate = 48_000
                Settings.bufferLength = .veryShort
                print("48 KHz / 64 sample buffer")
            } else {
                desiredSampleRate = 44_100
                Settings.bufferLength = .short
                print("44.1 KHz / 128 sample buffer")
            }
            
            try session.setPreferredSampleRate(desiredSampleRate)
            try session.setPreferredIOBufferDuration(Settings.bufferLength.duration)
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            assertionFailure("Failed to configure AVAudioSession: \(error)")
        }
    }
}



// Engine manager to control the shared engine lifecycle
enum EngineManager {
    private static var started = false

    static func startIfNeeded() {
        guard !started else { return }
        
        AudioSessionManager.configureSession()
        
        // Get default parameters from parameter manager
        let masterParams = MasterParameters.default
        let voiceParams = VoiceParameters.default
        
        // Set currentPolyphony based on voice mode
        switch masterParams.voiceMode {
        case .monophonic:
            currentPolyphony = 1
        case .polyphonic:
            currentPolyphony = nominalPolyphony
        }
        
        // Create voice pool with current polyphony
        voicePool = VoicePool(voiceCount: currentPolyphony)
        
        // Note: Voice mixer volume is no longer used for global LFO modulation
        // Global LFO now modulates postMixerFader for stereo panning tremolo
        voicePool.voiceMixer.volume = 0.5
        
        // Apply global LFO parameters from master defaults
        voicePool.updateGlobalLFO(masterParams.globalLFO)
        
        // Apply voice modulation parameters to all voices
        voicePool.updateAllVoiceModulation(voiceParams.modulation)
        
        // NEW SIGNAL CHAIN:
        // VoicePool → PostMixerFader → Delay (100% wet) → Butterworth Lowpass → DryWetMixer → Reverb → Output
        //                                                                            ↑
        //                                                                      PostMixerFader (dry)
        
        // Delay processes the fader output - now 100% wet (dryWetMix = 0)
        fxDelay = StereoDelay(
                                voicePool.postMixerFader,  // Use postMixerFader instead of voiceMixer
                                time: AUValue(masterParams.delay.timeInSeconds(tempo: masterParams.tempo)),
                                feedback: AUValue(masterParams.delay.feedback),
                                dryWetMix: 0.0,  // 100% wet - dry/wet now handled by external mixer
                                pingPong: true,  // Always enabled
                                maximumDelayTime: 2
                                )
        
        // Butterworth lowpass filter after delay (tames digital artifacts)
        delayLowpass = LowPassButterworthFilter(
                                fxDelay,
                                cutoffFrequency: AUValue(masterParams.delay.toneCutoff),
                                //resonance: 0.0  // Butterworth filter does not have resonance
                                )
        
        // DryWetMixer blends dry signal (post-mixer fader) with wet signal (delay → filter)
        delayDryWetMixer = DryWetMixer(
                                voicePool.postMixerFader,   // Input (dry) - use postMixerFader
                                delayLowpass,                // Effect (wet)
                                balance: AUValue(masterParams.delay.dryWetMix)
                                )
        
        // Reverb processes the mixed signal (dry + filtered delay)
        fxReverb = CostelloReverb(
                                delayDryWetMixer,
                                balance: AUValue(masterParams.reverb.balance),
                                feedback: AUValue(masterParams.reverb.feedback),
                                cutoffFrequency: AUValue(masterParams.reverb.cutoffFrequency)
                                
                                )
        
        // OutputMixer for control of post volume
        outputMixer = Mixer(fxReverb)
        outputMixer.volume = AUValue(masterParams.output.volume)
        
        
        // Output mixer is connected to final output
        sharedEngine.output = outputMixer
        
        do {
            try sharedEngine.start()
            started = true
            
            // Initialize voice pool after engine starts
            voicePool.initialize()
            
            // Pass FX node references to voice pool for global LFO modulation
            voicePool.setFXNodes(delay: fxDelay, reverb: fxReverb)
            
            // Initialize base delay time for LFO modulation
            let initialDelayTime = masterParams.delay.timeInSeconds(tempo: masterParams.tempo)
            voicePool.updateBaseDelayTime(initialDelayTime)
            
            // Start modulation system (Phase 5B)
            voicePool.startModulation()
            
        } catch {
            assertionFailure("Failed to start AudioKit engine: \(error)")
        }
    }
    
    static func startEngine() throws {
        startIfNeeded()
    }
}
