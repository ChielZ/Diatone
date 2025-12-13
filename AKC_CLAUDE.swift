/*
//
//  AudioKitCode.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 02/12/2025.
//

import AudioKit
import SoundpipeAudioKit
internal import AudioKitEX
import AVFAudio

// Shared engine and mixer for the entire app (single engine architecture)
// Mixer is created lazily to ensure proper initialization order
let sharedEngine = AudioEngine()
private(set) var sharedMixer: Mixer!

// Configure and activate the audio session explicitly (iOS)
enum AudioSessionManager {
    static func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            assertionFailure("Failed to configure AVAudioSession: \(error)")
        }
    }
}

// A single voice: oscillator -> amplitude envelope -> shared mixer
final class OscVoice {
    let osc = Oscillator(waveform: Table(.sine))
    lazy var env = AmplitudeEnvelope(osc,
                                     attackDuration: 0.002,
                                     decayDuration: 0.12,
                                     sustainLevel: 0.0,
                                     releaseDuration: 0.10)

    // This voice's frequency stored as AUValue (Float) for AudioKit
    private var frequency: AUValue = 200.0
    private var initialised = false

    init() {
        // Connect this voice into the shared mixer
        sharedMixer.addInput(env)
    }

    func initialise() {
        if !initialised {
            initialised = true
            osc.amplitude = 0.15
            osc.frequency = frequency
            // Start oscillator to avoid start latency; safe after engine start
            osc.start()
        }
    }

    // Set the actual frequency for this voice (in Hz)
    // Accepts Double for convenience but converts to AUValue (Float) internally
    func setFrequency(_ freq: Double) {
        frequency = AUValue(freq)
        if initialised {
            // Use parameter ramping with small duration to avoid AudioUnit errors
            // Duration of 0 can cause console errors; use 0.001 instead
            osc.$frequency.ramp(to: frequency, duration: 0.001)
        }
    }

    func trigger() {
        if !initialised {
            initialise()
        }
        env.reset()
        env.openGate()
    }
}

// Engine manager to control the shared engine lifecycle
enum EngineManager {
    private static var started = false
    private static var voicesCreated = false

    static func startIfNeeded() {
        guard !started else { return }
        
        // Step 1: Configure audio session first
        AudioSessionManager.configureSession()
        
        // Step 2: Create the mixer AFTER session is configured
        sharedMixer = Mixer()
        
        // Step 3: Wire output graph before starting
        sharedEngine.output = sharedMixer
        
        // Step 4: Start the engine
        do {
            try sharedEngine.start()
            started = true
        } catch {
            assertionFailure("Failed to start AudioKit engine: \(error)")
        }
    }
    
    // Alternative name for compatibility
    static func startEngine() throws {
        startIfNeeded()
    }
    
    static func initializeVoices(count: Int = 18) {
        guard started else {
            assertionFailure("Cannot initialize voices before engine is started")
            return
        }
        
        // First, create all voice instances (connects them to mixer)
        if !voicesCreated {
            createAllVoices()
            voicesCreated = true
        }
        
        // Then initialize them (sets parameters and starts oscillators)
        oscillator01.initialise()
        oscillator02.initialise()
        oscillator03.initialise()
        oscillator04.initialise()
        oscillator05.initialise()
        oscillator06.initialise()
        oscillator07.initialise()
        oscillator08.initialise()
        oscillator09.initialise()
        oscillator10.initialise()
        oscillator11.initialise()
        oscillator12.initialise()
        oscillator13.initialise()
        oscillator14.initialise()
        oscillator15.initialise()
        oscillator16.initialise()
        oscillator17.initialise()
        oscillator18.initialise()
    }
    
    static func applyScale(frequencies: [Double]) {
        guard frequencies.count == 18 else {
            print("Warning: Expected 18 frequencies, got \(frequencies.count)")
            return
        }
        guard voicesCreated else {
            assertionFailure("Cannot apply scale before voices are created")
            return
        }
        
        oscillator01.setFrequency(frequencies[0])
        oscillator02.setFrequency(frequencies[1])
        oscillator03.setFrequency(frequencies[2])
        oscillator04.setFrequency(frequencies[3])
        oscillator05.setFrequency(frequencies[4])
        oscillator06.setFrequency(frequencies[5])
        oscillator07.setFrequency(frequencies[6])
        oscillator08.setFrequency(frequencies[7])
        oscillator09.setFrequency(frequencies[8])
        oscillator10.setFrequency(frequencies[9])
        oscillator11.setFrequency(frequencies[10])
        oscillator12.setFrequency(frequencies[11])
        oscillator13.setFrequency(frequencies[12])
        oscillator14.setFrequency(frequencies[13])
        oscillator15.setFrequency(frequencies[14])
        oscillator16.setFrequency(frequencies[15])
        oscillator17.setFrequency(frequencies[16])
        oscillator18.setFrequency(frequencies[17])
    }
}

// Voices will be created after engine starts (initially nil)
var oscillator01: OscVoice!
var oscillator02: OscVoice!
var oscillator03: OscVoice!
var oscillator04: OscVoice!
var oscillator05: OscVoice!
var oscillator06: OscVoice!
var oscillator07: OscVoice!
var oscillator08: OscVoice!
var oscillator09: OscVoice!
var oscillator10: OscVoice!
var oscillator11: OscVoice!
var oscillator12: OscVoice!
var oscillator13: OscVoice!
var oscillator14: OscVoice!
var oscillator15: OscVoice!
var oscillator16: OscVoice!
var oscillator17: OscVoice!
var oscillator18: OscVoice!

// Helper to create all oscillators (called AFTER engine starts)
private func createAllVoices() {
    oscillator01 = OscVoice()
    oscillator02 = OscVoice()
    oscillator03 = OscVoice()
    oscillator04 = OscVoice()
    oscillator05 = OscVoice()
    oscillator06 = OscVoice()
    oscillator07 = OscVoice()
    oscillator08 = OscVoice()
    oscillator09 = OscVoice()
    oscillator10 = OscVoice()
    oscillator11 = OscVoice()
    oscillator12 = OscVoice()
    oscillator13 = OscVoice()
    oscillator14 = OscVoice()
    oscillator15 = OscVoice()
    oscillator16 = OscVoice()
    oscillator17 = OscVoice()
    oscillator18 = OscVoice()
}
*/
