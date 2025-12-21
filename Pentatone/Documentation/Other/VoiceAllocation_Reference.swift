//
//  VoiceAllocation_Reference.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 20/12/2025.
//

//THE FOLLOWING IS REFERENCE CODE PASTED FROM ANOTHER PROJECT. NOT ALL OF THIS IS RELEVANT TO THE CURRENT PROJECT, BUT IT DOES CONTAIN A WELL WORKING VOICE ALLOCATION MECHANISM

/*
 
 
 //
 //  AudioKitCode.swift
 //  ToneHive
 //
 //  Created by Chiel Zwinkels on 07/12/2025.
 //

 import AudioKit
 import AVFoundation
 import SwiftUI
 import Combine
 import SoundpipeAudioKit
 import AudioKitEX

 import Foundation

 var rootNote: Float = 300

 // MARK: - Voice
 /// A single voice in the polyphonic synthesizer
 /// Signal path: FMOscillator -> LowPassFilter -> AmplitudeEnvelope
 class Voice {
     let oscillator: FMOscillator
     let filter: LowPassFilter
     let envelope: AmplitudeEnvelope
     
     var isAvailable: Bool = true
     var currentFrequency: Double = 400.0
     
     /// Controls the portamento/glide time when changing frequencies
     /// Set to 0 for instant pitch changes, higher values for smoother glides
     var frequencyRampDuration: Double = 0
     
     init() {
         // Create the oscillator
         self.oscillator = FMOscillator(waveform: Table(.triangle), modulationIndex: 0.0)
         
         // Start the oscillator (CRITICAL: oscillators must be started to produce sound)
         self.oscillator.start()
         
         // Create the filter with oscillator as input
         self.filter = LowPassFilter(self.oscillator)
         
         // Set filter cutoff to a high value to let all frequencies through initially
         self.filter.cutoffFrequency = 20000 // 20kHz - essentially bypass the filter for now
         
         // Create the envelope with filter as input
         self.envelope = AmplitudeEnvelope(self.filter)
         
         // Configure envelope parameters
         self.envelope.attackDuration = 0.01   // 10ms attack
         self.envelope.decayDuration = 0.1     // 100ms decay
         self.envelope.sustainLevel = 0.7  // 70% sustain level
         self.envelope.releaseDuration = 0.3   // 300ms release
         
         // Initialize frequency ramp duration to 0 (instant pitch changes by default)
         self.frequencyRampDuration = 0
     }
     
     
     /// Resets the envelope for this voice
     func resetEnvelope() {
         envelope.reset()
     }
     
     /// Opens the gate to start the attack phase
     func openGate() {
         envelope.openGate()
     }
     
     /// Closes the gate to start the release phase
     func closeGate() {
         envelope.closeGate()
     }
     
     /// Sets the base frequency of the oscillator
     func setFrequency(_ frequency: Double) {
         // Use the new AudioKit ramping API
         // If frequencyRampDuration is 0, frequency changes instantly
         // Otherwise, it ramps smoothly over the specified duration
         if frequencyRampDuration > 0 {
             oscillator.$baseFrequency.ramp(to: Float(frequency), duration: Float(frequencyRampDuration))
         } else {
             oscillator.$baseFrequency.ramp(to: Float(frequency), duration: 0)
             //oscillator.baseFrequency = Float(frequency)
         }
         currentFrequency = frequency
     }
 }

 // MARK: - PolyMixer
 /// Mixer that combines all voice outputs
 class PolyMixer {
     let mixer: Mixer
     
     init() {
         self.mixer = Mixer()
     }
     
     /// Connects a voice's envelope output to the mixer
     func connectVoice(_ voice: Voice) {
         mixer.addInput(voice.envelope)
     }
 }

 // MARK: - SynthEngine
 /// Main synthesizer engine managing all voices and audio processing
 class SynthEngine: ObservableObject {
     let engine: AudioEngine
     var polyMixer: PolyMixer?
     var voices: [Voice] = []
     
     let maxPolyphony: Int
     var currentVoiceIndex: Int = 0
     
     /// Maps key numbers to their currently playing voices
     /// This enables precise release tracking without relying on frequency matching
     private var keyToVoiceMap: [Int: Voice] = [:]
     
     /// Flag to track if the synth engine has been initialized
     /// Prevents re-initialization which would disconnect playing voices
     private var isSetup: Bool = false
     
     /// Global portamento/glide control for all voices
     /// Set to 0 for instant pitch changes, higher values (e.g., 0.1-0.5) for portamento effect
     var portamentoTime: Double = 0 {
         didSet {
             // Update all voices when the global portamento time changes
             for voice in voices {
                 voice.frequencyRampDuration = portamentoTime
             }
         }
     }
     
     init(maxPolyphony: Int = 7) {
         self.maxPolyphony = maxPolyphony
         self.engine = AudioEngine()
         // Don't create voices or mixer yet - will be created in setup()
     }
     
     /// Properly initializes and starts the audio engine
     /// Call this after init() to set up the audio chain
     /// Follows the initialization order specified in section B of AudioKitPreCodeStructure:
     /// 1) Start the engine
     /// 2) Create and activate the voicemixer
     /// 3) Create the individual voices
     /// 4) Connect all voices to the voicemixer
     /// 5) Append everything to the audio engine
     /// 6) Set the current voice to voice 0
     /// 7) Set all voices as being available
     ///
     /// This method is safe to call multiple times - it will only initialize once
     func setup() throws {
         // Prevent re-initialization which would disconnect playing voices
         guard !isSetup else {
             print("🎵 Synth engine already initialized, skipping setup")
             return
         }
         // 1) Create and activate the voicemixer
         self.polyMixer = PolyMixer()
         
         // 2) Create the individual voices
         for _ in 0..<maxPolyphony {
             let voice = Voice()
             voices.append(voice)
         }
         
         // 3) Connect all voices to the voicemixer
         guard let mixer = polyMixer else {
             throw NSError(domain: "SynthEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "PolyMixer not initialized"])
         }
         
         for voice in voices {
             mixer.connectVoice(voice)
         }
         
         // 4) Set the output BEFORE starting the engine (required by AudioEngine)
         engine.output = mixer.mixer
         
         // 5) Now start the engine with the output configured
         try engine.start()
         
         // 6) Set the current voice to voice 0
         currentVoiceIndex = 0
         
         // 7) Set all voices as being available
         for voice in voices {
             voice.isAvailable = true
         }
         
         // Mark setup as complete
         isSetup = true
         print("🎵 Synth engine setup completed successfully")
     }
     
     
     /// Returns the current voice based on currentVoiceIndex
     var currentVoice: Voice? {
         guard currentVoiceIndex < voices.count else { return nil }
         return voices[currentVoiceIndex]
     }
     
     /// Finds the next available voice, starting from currentVoiceIndex
     func findAvailableVoice() -> Voice {
         var checkedCount = 0
         var index = currentVoiceIndex
         
         while checkedCount < maxPolyphony {
             if voices[index].isAvailable {
                 currentVoiceIndex = index
                 return voices[index]
             }
             
             index = (index + 1) % maxPolyphony
             checkedCount += 1
         }
         
         // If no available voice found, use current voice (voice stealing)
         return voices[currentVoiceIndex]
     }
     
     /// Increments to the next voice index
     func incrementVoiceIndex() {
         currentVoiceIndex = (currentVoiceIndex + 1) % maxPolyphony
     }
     
     // MARK: - Note Triggering (Section C)
     
     /// Triggers a note when a key is touched
     /// - Parameters:
     ///   - frequency: The frequency of the note to trigger
     ///   - keyNumber: The unique key number (1-88) that triggered this note
     func triggerNote(frequency: Double, forKey keyNumber: Int) {
         // Check if the current voice is available
         // If yes, select the current voice
         // If no, increment through all voices until an available voice is found
         // Loop around as necessary when the highest voice number is reached
         let selectedVoice = findAvailableVoice()
         
         // Reset the envelope of the current voice
         selectedVoice.resetEnvelope()
         
         // Set the base frequency of the voice oscillator to the value attached to the key
         selectedVoice.setFrequency(frequency)
         
         // Trigger the current voice by opening the gate, which should trigger the attack phase
         selectedVoice.openGate()
         
         // Mark the current voice as occupied
         selectedVoice.isAvailable = false
         
         // Map this key number to the voice for precise release tracking
         keyToVoiceMap[keyNumber] = selectedVoice
         
         print("🎵 Key \(keyNumber): Started at \(selectedVoice.currentFrequency) Hz")
         
         // Increment the current voice by one. Loop around if necessary
         incrementVoiceIndex()
     }
     
     /// Releases a note when the touch ends
     /// - Parameter keyNumber: The unique key number (1-88) to release
     func releaseNote(forKey keyNumber: Int) {
         // Look up the voice associated with this key
         guard let voice = keyToVoiceMap[keyNumber] else {
             print("⚠️ Key \(keyNumber): No voice found to release")
             return
         }
         
         // Close the gate (starts the release phase)
         voice.closeGate()
         
         print("🎵 Key \(keyNumber): Released at \(voice.currentFrequency) Hz")
         
         // Remove the mapping immediately - this key is no longer pressed
         keyToVoiceMap.removeValue(forKey: keyNumber)
         
         // Get the release time from the envelope
         let releaseTime = voice.envelope.releaseDuration
         
         // Wait for a duration that equals the length of the release phase
         // Then mark the voice as available
         Task {
             try? await Task.sleep(nanoseconds: UInt64(releaseTime * 1_000_000_000))
             
             // Mark the voice as available for reuse
             voice.isAvailable = true
         }
     }
 }



 /*
  // When a key is touched:
  synthEngine.triggerNote(frequency: 440.0, forKey: 30)

  // When the touch ends:
  synthEngine.releaseNote(forKey: 30)
  */

 
 
 */
