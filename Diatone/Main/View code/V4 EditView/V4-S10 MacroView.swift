//
//  V4-S10 MacroView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 26/12/2025.
// SUBVIEW 10 - MACROS
/*
 1) Tone >> ModulationIndex range +/- 0...5
 2) Tone >> Cutoff range +/- 0-4 octaves
 3) Tone >> Filter saturation range +/- 0...2
 4) Ambience >> Delay feedback range +/- 0...1
 5) Ambience >> Delay Mix range +/- 0...1
 6) Ambience >> Reverb size range +/- 0...1
 7) Ambience >> Reverb mix range +/- 0...1
 */


import SwiftUI

struct MacroView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    var body: some View {
        Group {
            // Row 3 - Tone to Modulation Index Range
            SliderRow(
                label: "TONE TO MOD LEVEL",
                value: Binding(
                    get: { paramManager.master.macroControl.toneToModulationIndexRange },
                    set: { newValue in
                        paramManager.updateToneToModulationIndexRange(newValue)
                    }
                ),
                range: 0...2.5,
                step: 0.05,
                displayFormatter: { value in
                    let normalizedValue = value / 5
                    return String(format: "%.2f", normalizedValue)
                }
            )
            
            // Row 4 - Tone to Filter Cutoff Octaves
            SliderRow(
                label: "TONE TO FILTER FREQ",
                value: Binding(
                    get: { paramManager.master.macroControl.toneToFilterCutoffOctaves },
                    set: { newValue in
                        paramManager.updateToneToFilterCutoffOctaves(newValue)
                    }
                ),
                range: 0...5,
                step: 0.01,
                displayFormatter: { String(format: "%.2f oct", $0) }
            )
            
            // Row 5 - Tone to Filter Saturation Range
            SliderRow(
                label: "TONE TO FILTER DRIVE",
                value: Binding(
                    get: { paramManager.master.macroControl.toneToFilterSaturationRange },
                    set: { newValue in
                        paramManager.updateToneToFilterSaturationRange(newValue)
                    }
                ),
                range: 0...1,
                step: 0.02,
                displayFormatter: { value in
                    let normalizedValue = value / 2
                    return String(format: "%.2f", normalizedValue)
                }
            )
            
            // Row 6 - Ambience to Delay Feedback Range
            SliderRow(
                label: "AMB TO DLY FB",
                value: Binding(
                    get: { paramManager.master.macroControl.ambienceToDelayFeedbackRange },
                    set: { newValue in
                        paramManager.updateAmbienceToDelayFeedbackRange(newValue)
                    }
                ),
                range: 0...0.5,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
            // Row 7 - Ambience to Delay Mix Range
            SliderRow(
                label: "AMB TO DLY MIX",
                value: Binding(
                    get: { paramManager.master.macroControl.ambienceToDelayMixRange },
                    set: { newValue in
                        paramManager.updateAmbienceToDelayMixRange(newValue)
                    }
                ),
                range: 0...0.5,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
            // Row 8 - Ambience to Reverb Feedback Range
            SliderRow(
                label: "AMB TO REV SIZE",
                value: Binding(
                    get: { paramManager.master.macroControl.ambienceToReverbFeedbackRange },
                    set: { newValue in
                        paramManager.updateAmbienceToReverbFeedbackRange(newValue)
                    }
                ),
                range: 0...0.5,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            
            // Row 9 - Ambience to Reverb Mix Range
            SliderRow(
                label: "AMB TO REV MIX",
                value: Binding(
                    get: { paramManager.master.macroControl.ambienceToReverbMixRange },
                    set: { newValue in
                        paramManager.updateAmbienceToReverbMixRange(newValue)
                    }
                ),
                range: 0...0.5,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
        }
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack(spacing: 11) {
            MacroView()
        }
        .padding(25)
    }
}
