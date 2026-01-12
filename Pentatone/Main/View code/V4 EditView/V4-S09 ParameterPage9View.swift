//
//  V4-S09 ParameterPage9View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 9 - TOUCH RESPONSE

/*
PAGE 9 - TOUCH RESPONSE (REFACTORED - FIXED DESTINATIONS)
√ 1) Initial touch to oscillator amplitude amount
√ 2) Initial touch to mod envelope amount
√ 3) Aftertouch to oscillator pitch amount (REPLACING: Initial touch to aux envelope pitch amount)
√ 4) Initial touch to aux envelope cutoff amount
√ 5) Aftertouch to filter frequency amount
√ 6) Aftertouch to modulator level amount
√ 7) Aftertouch to vibrato (voice lfo >> oscillator pitch) amount
*/

import SwiftUI

struct TouchView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 1 - Initial Touch to Oscillator Amplitude (velocity-like control)
            SliderRow(
                label: "INITIAL TO AMP",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.touchInitial.amountToOscillatorAmplitude },
                    set: { newValue in
                        paramManager.updateInitialTouchAmountToAmplitude(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
            // Row 2 - Initial Touch to Mod Envelope Amount (meta-modulation)
            SliderRow(
                label: "INITIAL TO MOD ENV",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.touchInitial.amountToModEnvelope },
                    set: { newValue in
                        paramManager.updateInitialTouchAmountToModEnvelope(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...2,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
        
            
            // Row 4 - Initial Touch to Aux Envelope Cutoff Amount (meta-modulation)
            SliderRow(
                label: "INITIAL TO FILTER ENV",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.touchInitial.amountToAuxEnvCutoff },
                    set: { newValue in
                        paramManager.updateInitialTouchAmountToAuxEnvCutoff(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...2,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
            // Row 6 - Aftertouch to Modulator Level (modulation index)
            SliderRow(
                label: "AFTER TO MOD",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.touchAftertouch.amountToModulatorLevel },
                    set: { newValue in
                        paramManager.updateAftertouchAmountToModulatorLevel(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...5,
                step: 0.01,
                displayFormatter: { value in
                    return value > 0 ? String(format: "%.2f", value) : String(format: "%.2f", value)
                }
            )
            
            // Row 5 - Aftertouch to Filter Frequency
            SliderRow(
                label: "AFTER TO FILTER",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.touchAftertouch.amountToFilterFrequency },
                    set: { newValue in
                        paramManager.updateAftertouchAmountToFilter(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...3,
                step: 0.01,
                displayFormatter: { value in
                    return value > 0 ? String(format: "%.2f oct", value) : String(format: "%.2f oct", value)
                }
            )
            

            
            // Row 3 - Aftertouch to Oscillator Pitch (replaces Initial to Pitch Env temporarily)
            SliderRow(
                label: "AFTER TO PITCH",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.touchAftertouch.amountToOscillatorPitch },
                    set: { newValue in
                        paramManager.updateAftertouchAmountToPitch(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...24,
                step: 1.0,
                displayFormatter: { value in
                    let cents = Int(value * 100)  // Half the semitones, convert to cents (1 semitone = 100 cents)
                    return "\(cents) ct"
                }
            )
            
            // Row 7 - Aftertouch to Vibrato (meta-modulation of voice LFO pitch amount)
            SliderRow(
                label: "AFTER TO VIBRATO",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.touchAftertouch.amountToVibrato },
                    set: { newValue in
                        paramManager.updateAftertouchAmountToVibrato(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...2,
                step: 0.01,
                displayFormatter: { value in
                    return value > 0 ? String(format: "%.2f", value) : String(format: "%.2f", value)
                }
            )
        }
    }
    
    // MARK: - Helper Functions
    
    /// Applies current modulation parameters to all active voices
    private func applyModulationToAllVoices() {
        let modulationParams = paramManager.voiceTemplate.modulation
        
        // Apply to all voices in the pool
        for voice in voicePool.voices {
            voice.updateModulationParameters(modulationParams)
        }
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack {
            TouchView()
        }
        .padding(25)
    }
}
