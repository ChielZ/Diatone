//  V4-S04 AuxEnvView.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 4 - AUX ENVELOPE

/*
 PAGE 6 - AUXILIARY ENVELOPE (REFACTORED - FIXED DESTINATIONS)
 √ 1) Aux envelope Attack time
 √ 2) Aux envelope Decay time
 √ 3) Aux envelope Sustain level
 √ 4) Aux envelope Release time
 √ 5) Aux envelope to oscillator pitch amount
 √ 6) Aux envelope to filter frequency amount
 √ 7) Aux envelope to vibrato (voice lfo >> oscillator pitch) amount
*/

import SwiftUI

struct AuxEnvView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 1 - Auxiliary Envelope Attack (0-5 seconds, displayed in ms)
            LogarithmicSliderRowWithLinearButtons(
                label: "AUX ENV ATTACK",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.attack },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeAttack(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0.001...5,  // 1ms to 5000ms (zero accessible via button)
                buttonStep: 0.001,  // Fixed 1 ms steps for buttons
                displayFormatter: { value in
                    if value == 0.0 {
                        return "0 ms"
                    } else {
                        return String(format: "%.0f ms", value * 1000)
                    }
                }
            )
            
            // Row 2 - Auxiliary Envelope Decay (0-5 seconds, displayed in ms)
            LogarithmicSliderRowWithLinearButtons(
                label: "AUX ENV DECAY",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.decay },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeDecay(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0.01...5,  // 1ms to 5000ms (zero accessible via button)
                buttonStep: 0.01,  // Fixed 1 ms steps for buttons
                displayFormatter: { value in
                    let round = (value * 100).rounded() * 10
                    if value == 0.0 {
                        return "0 ms"
                    } else {
                        return String(format: "%.0f ms", round)
                    }
                }
            )
            
            // Row 3 - Auxiliary Envelope Sustain (0-1)
            SliderRow(
                label: "AUX ENV SUSTAIN",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.sustain },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeSustain(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
            // Row 4 - Auxiliary Envelope Release (0-5 seconds, displayed in ms)
            LogarithmicSliderRowWithLinearButtons(
                label: "AUX ENV RELEASE",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.release },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeRelease(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: 0.01...1,  // 1ms to 1000ms (zero accessible via button)
                buttonStep: 0.01,  // Fixed 1 ms steps for buttons
                displayFormatter: { value in
                    let round = (value * 100).rounded() * 10
                    if value == 0.0 {
                        return "0 ms"
                    } else {
                        return String(format: "%.0f ms", round)
                    }
                }
            )
            
            // Row 5 - Auxiliary Envelope to Oscillator Pitch (pitch sweep)
            SliderRow(
                label: "AUX ENV TO PITCH",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.amountToOscillatorPitch },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeAmountToPitch(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: -12...12,
                step: 0.1,
                displayFormatter: { value in
                    // Convert semitones to cents (1 semitone = 100 cents)
                    let cents = value * 100
                    if abs(cents) < 0.5 {  // Use epsilon for floating-point comparison
                        return "0 ct"
                    } else if cents > 0 {
                        return String(format: "+%.0f ct", cents)
                    } else {
                        return String(format: "%.0f ct", cents)
                    }
                }
            )
            
            // Row 6 - Auxiliary Envelope to Filter Frequency
            SliderRow(
                label: "AUX ENV TO FILTER",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.amountToFilterFrequency },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeAmountToFilter(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: -5...5,
                step: 0.05,
                displayFormatter: { value in
                    if abs(value) < 0.005 {  // Use epsilon for floating-point comparison
                        return "0.00 oct"
                    } else if value > 0 {
                        return String(format: "+%.2f oct", value)
                    } else {
                        return String(format: "%.2f oct", value)
                    }
                }
            )
            
            // Row 7 - Auxiliary Envelope to Vibrato (meta-modulation of voice LFO pitch amount)
            SliderRow(
                label: "AUX ENV TO VIBRATO",
                value: Binding(
                    get: { paramManager.voiceTemplate.modulation.auxiliaryEnvelope.amountToVibrato },
                    set: { newValue in
                        paramManager.updateAuxiliaryEnvelopeAmountToVibrato(newValue)
                        applyModulationToAllVoices()
                    }
                ),
                range: -2...2,
                step: 0.02,
                displayFormatter: { value in
                    let normalizedValue = value / 2
                    if abs(value) < 0.005 {  // Use epsilon for floating-point comparison
                        return "0.00"
                    } else if normalizedValue > 0 {
                        return String(format: "+%.2f", normalizedValue)
                    } else {
                        return String(format: "%.2f", normalizedValue)
                    }
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
            AuxEnvView()
        }
        .padding(25)
    }
}
