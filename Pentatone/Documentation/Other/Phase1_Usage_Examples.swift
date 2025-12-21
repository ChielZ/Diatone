//
//  Phase1_Usage_Examples.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 20/12/2025.
//

// MARK: - Phase 1 Usage Examples (Reference Only - Not Compiled)

/*

// ============================================================================
// BASIC USAGE - Triggering Notes with the New Voice Pool
// ============================================================================

// Example 1: Simple note trigger and release
let keyIndex = 0  // First key (0-17)
let frequency = 293.66  // D4

// Trigger
voicePool.allocateVoice(frequency: frequency, forKey: keyIndex)

// Release (when touch ends)
voicePool.releaseVoice(forKey: keyIndex)


// ============================================================================
// FREQUENCY OFFSET (STEREO SPREAD) CONTROL
// ============================================================================

// Example 2: Adjust stereo spread for all voices
voicePool.updateFrequencyOffset(1.005)  // ~8.6 cents spread
voicePool.updateFrequencyOffset(1.01)   // ~17.3 cents spread (34 cents total)
voicePool.updateFrequencyOffset(1.0)    // No spread (mono)


// ============================================================================
// PARAMETER UPDATES
// ============================================================================

// Example 3: Update parameters for all voices

// Update oscillator parameters
var oscParams = OscillatorParameters.default
oscParams.modulationIndex = 1.5
oscParams.amplitude = 0.7
voicePool.updateAllVoiceOscillators(oscParams)

// Update filter parameters
var filterParams = FilterParameters.default
filterParams.cutoffFrequency = 2000
filterParams.resonance = 0.7
voicePool.updateAllVoiceFilters(filterParams)

// Update envelope parameters
var envParams = EnvelopeParameters.default
envParams.attackDuration = 0.01
envParams.releaseDuration = 0.5
voicePool.updateAllVoiceEnvelopes(envParams)


// ============================================================================
// VOICE POOL STATUS & DIAGNOSTICS
// ============================================================================

// Example 4: Check voice pool status

// Get counts
let totalVoices = voicePool.voiceCount          // e.g., 5
let activeVoices = voicePool.activeVoiceCount   // e.g., 3 (currently playing)
let availableVoices = totalVoices - activeVoices // e.g., 2 (ready for use)

// Print detailed status
voicePool.printStatus()
// Output:
// 🎵 Voice Pool Status:
//    Total voices: 5
//    Active voices: 3
//    Available voices: 2
//    Keys pressed: 3


// ============================================================================
// INTEGRATION WITH SCALE SYSTEM
// ============================================================================

// Example 5: Using voice pool with scale frequencies

let scale = ScalesCatalog.centerMeridian_JI
let key = MusicalKey.D
let frequencies = makeKeyFrequencies(for: scale, musicalKey: key)

// Trigger key 0 with its corresponding frequency
voicePool.allocateVoice(frequency: frequencies[0], forKey: 0)

// Later, release it
voicePool.releaseVoice(forKey: 0)


// ============================================================================
// SWIFTUI INTEGRATION PATTERN
// ============================================================================

// Example 6: Using voice pool in a SwiftUI view

struct MyKeyButton: View {
    let keyIndex: Int
    let frequency: Double
    @State private var isPressed = false
    
    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            voicePool.allocateVoice(
                                frequency: frequency,
                                forKey: keyIndex
                            )
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        voicePool.releaseVoice(forKey: keyIndex)
                    }
            )
    }
}


// ============================================================================
// ADVANCED: ACCESSING INDIVIDUAL VOICES
// ============================================================================

// Example 7: Direct voice access (not recommended for normal use)

// The voice pool manages allocation automatically, but if you need
// to access individual voices for debugging or advanced control:

let voice = voicePool.voices[0]  // First voice
print("Voice 0 available: \(voice.isAvailable)")
print("Voice 0 frequency: \(voice.currentFrequency)")
print("Voice 0 triggered at: \(voice.triggerTime)")


// ============================================================================
// STOPPING ALL VOICES
// ============================================================================

// Example 8: Emergency stop (panic button)

voicePool.stopAll()
// Immediately closes all envelopes and clears all key mappings


// ============================================================================
// INITIALIZATION SEQUENCE (Already done in AudioKitCode.swift)
// ============================================================================

// Example 9: How voice pool is initialized (for reference)

// 1. Create voice pool (during engine setup)
voicePool = VoicePool(voiceCount: 5)

// 2. Mix voice pool output with other audio
let combinedMixer = Mixer(oldVoiceMixer, voicePool.voiceMixer)

// 3. Connect to effects chain
fxDelay = StereoDelay(combinedMixer, ...)

// 4. Start engine
try sharedEngine.start()

// 5. Initialize voice pool (starts oscillators)
voicePool.initialize()


// ============================================================================
// TESTING VOICE STEALING
// ============================================================================

// Example 10: Trigger more notes than available voices

// With 5 voices, trigger 6 notes quickly
for i in 0..<6 {
    voicePool.allocateVoice(frequency: 440.0 * pow(2.0, Double(i)/12.0), forKey: i)
    Thread.sleep(forTimeInterval: 0.1)  // Small delay between notes
}

// The 6th note will steal the oldest (first) voice
// Check console for: "⚠️ Voice stealing: Took voice triggered at ..."


// ============================================================================
// COMPARING OLD VS NEW SYSTEM
// ============================================================================

// OLD SYSTEM (1:1 key-to-voice mapping):
oscillator01.setFrequency(293.66)
oscillator01.trigger()
// Later...
oscillator01.release()

// NEW SYSTEM (dynamic voice allocation):
voicePool.allocateVoice(frequency: 293.66, forKey: 0)
// Later...
voicePool.releaseVoice(forKey: 0)

// Key differences:
// - Old: Each key has dedicated oscillator
// - New: Voices shared dynamically across all keys
// - Old: 18 voices always allocated
// - New: Configurable polyphony (3-12 voices)
// - Old: Mono oscillator
// - New: Stereo dual oscillators with spread control


// ============================================================================
// PHASE 5 PREVIEW: MODULATION (Not yet implemented)
// ============================================================================

// Example 11: How modulation will work (Phase 5)

/*
// Set global LFO parameters
voicePool.globalLFO.rate = 2.0  // 2 Hz
voicePool.globalLFO.depth = 0.5
voicePool.globalLFO.destination = .filterCutoff
voicePool.globalLFO.isEnabled = true

// Start modulation system
voicePool.startModulation()

// Configure per-voice LFO (will vary per voice for organic texture)
let voice = voicePool.voices[0]
voice.voiceLFO.rate = 4.0
voice.voiceLFO.destination = .frequencyOffset
voice.voiceLFO.isEnabled = true
*/

*/
