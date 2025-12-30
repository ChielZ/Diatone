//
//  V4-S08 ParameterPage8View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 8 - GLOBAL LFO

/*
PAGE 8 - GLOBAL LFO
1) Global LFO waveform (sine, triangle, square, sawtooth, reversed sawtooth)
2) Global LFO reset mode (free, sync)
3) Global LFO frequency (0-10 Hz or tempo multipliers depending on mode)
4) Global LFO destination (Oscillator amplitude [default], Oscillator baseFrequency, modulationIndex, modulatingMultiplier, Filter frequency, delay time, delay amount)
5) Global LFO amount (bipolar modulation, so only positive amounts)
*/

import SwiftUI

struct GlobLFOView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 3 - Global LFO Waveform (sine, triangle, square, sawtooth, reverse sawtooth)
            ParameterRow(
                label: "GLOBAL LFO WAVEFORM",
                value: Binding(
                    get: { paramManager.master.globalLFO.waveform },
                    set: { newValue in
                        paramManager.updateGlobalLFOWaveform(newValue)
                    }
                ),
                displayText: { waveform in
                    switch waveform {
                    case .sine: return "SINE"
                    case .triangle: return "TRIANGLE"
                    case .square: return "SQUARE"
                    case .sawtooth: return "SAWTOOTH"
                    case .reverseSawtooth: return "REV SAW"
                    }
                }
            )
            
            // Row 4 - Global LFO Reset Mode (free, sync)
            // Note: Global LFO doesn't have "trigger" mode (no per-note triggering)
            ParameterRow(
                label: "GLOBAL LFO RESET MODE",
                value: Binding(
                    get: { paramManager.master.globalLFO.resetMode },
                    set: { newValue in
                        paramManager.updateGlobalLFOResetMode(newValue)
                    }
                ),
                displayText: { mode in
                    switch mode {
                    case .free: return "FREE"
                    case .trigger: return "TRIGGER"
                    case .sync: return "SYNC"
                    }
                }
            )
            
            // Row 5 - Global LFO Frequency (0.01-10 Hz)
            // Note: For tempo sync mode, this would need different handling
            // For now, implementing as Hz mode (0.01-10 Hz)
            SliderRow(
                label: "GLOBAL LFO FREQUENCY",
                value: Binding(
                    get: { paramManager.master.globalLFO.frequency },
                    set: { newValue in
                        paramManager.updateGlobalLFOFrequency(newValue)
                    }
                ),
                range: 0.01...10,
                step: 0.01,
                displayFormatter: { value in
                    String(format: "%.2f Hz", value)
                }
            )
            
            // Row 6 - Global LFO Destination
            ParameterRow(
                label: "GLOBAL LFO DESTINATION",
                value: Binding(
                    get: { paramManager.master.globalLFO.destination },
                    set: { newValue in
                        paramManager.updateGlobalLFODestination(newValue)
                    }
                ),
                displayText: { destination in
                    // Shortened names to fit in UI
                    switch destination {
                    case .oscillatorAmplitude: return "OSC AMP"
                    case .oscillatorBaseFrequency: return "OSC FREQ"
                    case .modulationIndex: return "MOD IDX"
                    case .modulatingMultiplier: return "MOD MULT"
                    case .filterCutoff: return "FILTER"
                    case .stereoSpreadAmount: return "SPREAD"
                    case .voiceLFOFrequency: return "LFO RATE"
                    case .voiceLFOAmount: return "LFO DEPTH"
                    case .delayTime: return "DLY TIME"
                    case .delayMix: return "DLY MIX"
                    }
                }
            )
            
            // Row 7 - Global LFO Amount (0-1, bipolar modulation but positive amount)
            SliderRow(
                label: "GLOBAL LFO AMOUNT",
                value: Binding(
                    get: { paramManager.master.globalLFO.amount },
                    set: { newValue in
                        paramManager.updateGlobalLFOAmount(newValue)
                    }
                ),
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
            // Row 8 - Empty (for UI consistency)
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
            }
            
            // Row 9 - Empty (for UI consistency)
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
            }
        }
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack {
            GlobLFOView()
        }
        .padding(25)
    }
}
