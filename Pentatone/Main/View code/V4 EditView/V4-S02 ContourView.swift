//
//  V4-S02 ContourView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 2 - VOICE CONTOUR

/*
 PAGE 2 - VOICE CONTOUR
 1) Amp Envelope Attack time. SLIDER. Values: 0-5 continuous
 2) Amp Envelope Decay time. SLIDER. Values: 0-5 continuous
 3) Amp Envelope Sustain level. SLIDER. Values: 0-1 continuous
 4) Amp Envelope Release time. SLIDER. Values: 0-5 continuous
 5) Lowpass Filter Cutoff frequency. SLIDER. Values: 20 - 20000 continuous << needs logarithmic scaling
 6) Lowpass Filter Resonance. SLIDER. Values: 0-2 continuous
 7) Lowpass Filter Saturation. SLIDER. Values: 0-10 continuous
 */

import SwiftUI
import AudioKit
import AudioKitEX
import SoundpipeAudioKit

struct ContourView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 3 - Amp Envelope Attack (0-5 seconds, displayed in ms)
            LogarithmicSliderRowWithLinearButtons(
                label: "AMP ENV ATTACK",
                value: Binding(
                    get: { paramManager.voiceTemplate.envelope.attackDuration },
                    set: { newValue in
                        paramManager.updateEnvelopeAttack(newValue)
                        applyEnvelopeToAllVoices()
                    }
                ),
                range: 0.001...2.5,  // 1ms to 2500ms (zero accessible via button)
                buttonStep: 0.001,  // Fixed 1 ms steps for buttons
                displayFormatter: { value in
                    if value == 0.0 {
                        return "0 ms"
                    } else {
                        return String(format: "%.0f ms", value * 1000)
                    }
                }
            )
            
            // Row 4 - Amp Envelope Decay (0-5 seconds, displayed in ms)
            LogarithmicSliderRowWithLinearButtons(
                label: "AMP ENV DECAY",
                value: Binding(
                    get: { paramManager.voiceTemplate.envelope.decayDuration },
                    set: { newValue in
                        paramManager.updateEnvelopeDecay(newValue)
                        applyEnvelopeToAllVoices()
                    }
                ),
                range: 0.001...2.5,  // 1ms to 2500ms (zero accessible via button)
                buttonStep: 0.001,  // Fixed 1 ms steps for buttons
                displayFormatter: { value in
                    if value == 0.0 {
                        return "0 ms"
                    } else {
                        return String(format: "%.0f ms", value * 1000)
                    }
                }
            )
            
            // Row 5 - Amp Envelope Sustain (0-1)
            SliderRow(
                label: "AMP ENV SUSTAIN",
                value: Binding(
                    get: { paramManager.voiceTemplate.envelope.sustainLevel },
                    set: { newValue in
                        paramManager.updateEnvelopeSustain(newValue)
                        applyEnvelopeToAllVoices()
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
            // Row 6 - Amp Envelope Release (0-5 seconds, displayed in ms)
            LogarithmicSliderRowWithLinearButtons(
                label: "AMP ENV RELEASE",
                value: Binding(
                    get: { paramManager.voiceTemplate.envelope.releaseDuration },
                    set: { newValue in
                        paramManager.updateEnvelopeRelease(newValue)
                        applyEnvelopeToAllVoices()
                    }
                ),
                range: 0.001...0.5,  // 1ms to 500ms (zero accessible via button)
                buttonStep: 0.001,  // Fixed 1 ms steps for buttons
                displayFormatter: { value in
                    if value == 0.0 {
                        return "0 ms"
                    } else {
                        return String(format: "%.0f ms", value * 1000)
                    }
                }
            )
            
            // Row 7 - Filter Cutoff
            // Musical (MIDI note) quantization on drag, 1 Hz precision with buttons
            MusicalFrequencySliderRow(
                label: "FILTER CUTOFF",
                value: Binding(
                    get: { paramManager.voiceTemplate.filter.cutoffFrequency },
                    set: { newValue in
                        paramManager.updateFilterCutoff(newValue)
                    }
                ),
                range: 12...20000,
                buttonStep: 1.0,  // Precise 1 Hz steps for fine-tuning
                displayFormatter: { value in
                    return String(format: "%.0f Hz", value)
                }
            )
            
            // Row 8 - Filter Resonance (0-2)
            SliderRow(
                label: "FILTER RESONANCE",
                value: Binding(
                    get: { paramManager.voiceTemplate.filterStatic.resonance },
                    set: { newValue in
                        paramManager.updateFilterResonance(newValue)
                        // No need to call applyFilterToAllVoices - it's handled internally now
                    }
                ),
                range: 0...2,
                step: 0.02,
                displayFormatter: { value in
                    let normalizedValue = value / 2
                    return String(format: "%.2f", normalizedValue)
                }
            )
            
            // Row 9 - Filter Saturation (0-10)
            SliderRow(
                label: "FILTER DRIVE",
                value: Binding(
                    get: { paramManager.voiceTemplate.filterStatic.saturation },
                    set: { newValue in
                        paramManager.updateFilterSaturation(newValue)
                        // No need to call applyFilterToAllVoices - it's handled internally now
                    }
                ),
                range: 0...2,
                step: 0.02,
                displayFormatter: { value in
                    let normalizedValue = value / 2
                    return String(format: "%.2f", normalizedValue)
                }
            )
        }
    }
    
    // MARK: - Helper Functions
    
    /// Applies current envelope parameters to all active voices
    private func applyEnvelopeToAllVoices() {
        let params = paramManager.voiceTemplate.envelope
        
        // Apply to all voices in the pool
        for voice in voicePool.voices {
            voice.updateEnvelopeParameters(params)
        }
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack(spacing: 11) {
            ContourView()
        }
        .padding(25)
    }
}
