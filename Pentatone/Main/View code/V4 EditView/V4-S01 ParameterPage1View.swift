//
//  V4-S01 ParameterPage1View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 1 - VOICE OSCILLATORS

/*
 PAGE 1 - VOICE OSCILLATORS
 1) Oscillator Waveform. LIST. Values: sine, triangle, square
 2) Carrier multiplier. SLIDER. Values: integers only, range 1-16
 3) Modulator multiplier coarse. SLIDER. Values: integers only, range 1-16
 4) Modulator multiplier fine. SLIDER. Values: 0-1 continuous
 5) Modulator base level. SLIDER. Values: 0-1 continuous
 6) Stereo offset mode. LIST. Values: constant, proportional
 7) Stereo offset amount. SLIDER. Values: 0-4 continuous for constant offset mode, 1.0000-1.0100 continuous for proportional offset mode
 */

import SwiftUI
import AudioKit
import AudioKitEX
import SoundpipeAudioKit

struct OscillatorView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    // Local state for the modulator multiplier split into coarse + fine
    @State private var modulatorCoarse: Double = 2.0
    @State private var modulatorFine: Double = 0.0
    
    var body: some View {
        Group {
            // Row 3 - Waveform (enum cycling)
            ParameterRow(
                label: "WAVEFORM",
                value: Binding(
                    get: { paramManager.voiceTemplate.oscillator.waveform },
                    set: { newValue in
                        paramManager.updateOscillatorWaveform(newValue)
                        // Recreate only the oscillators with new waveform
                        voicePool.recreateOscillators(waveform: newValue) {
                            print("🎹 Oscillators recreated with waveform: \(newValue.displayName)")
                        }
                    }
                ),
                displayText: { $0.displayName }
            )
            // Row 4 - Carrier Multiplier (integer 1-16)
            IntegerSliderRow(
                label: "CARRIER MULTIPLIER",
                value: Binding(
                    get: { paramManager.voiceTemplate.oscillator.carrierMultiplier },
                    set: { newValue in
                        paramManager.updateCarrierMultiplier(newValue)
                        applyToAllVoices()
                    }
                ),
                range: 1...8
            )
            
            // Row 5 - Modulator Multiplier Coarse (integer 1-16)
            IntegerSliderRow(
                label: "MODULATOR COARSE",
                value: $modulatorCoarse,
                range: 1...16
            )
            .onChange(of: modulatorCoarse) { newCoarse in
                updateModulatingMultiplier(coarse: Int(newCoarse), fine: modulatorFine)
            }
            
            // Row 6 - Modulator Multiplier Fine (0-1 continuous)
            SliderRow(
                label: "MODULATOR FINE",
                value: $modulatorFine,
                range: 0...1,
                step: 0.01,
                displayFormatter: { String(format: "%.2f", $0) }
            )
            .onChange(of: modulatorFine) { newFine in
                updateModulatingMultiplier(coarse: Int(modulatorCoarse), fine: newFine)
            }
            
            // Row 7 - Modulation Index (base level, 0-5 internally, 0-1 displayed)
            SliderRow(
                label: "MODULATOR LEVEL",
                value: Binding(
                    get: { paramManager.voiceTemplate.oscillator.modulationIndex },
                    set: { newValue in
                        paramManager.updateModulationIndex(newValue)
                        applyToAllVoices()
                    }
                ),
                range: 0...5,
                step: 0.05,
                displayFormatter: { value in
                    let normalizedValue = value / 5
                    return String(format: "%.2f", normalizedValue)
                }
            )
            
            // Row 8 - Stereo Offset Mode (enum cycling)
            ParameterRow(
                label: "STEREO MODE",
                value: Binding(
                    get: { paramManager.voiceTemplate.oscillator.detuneMode },
                    set: { newValue in
                        paramManager.updateDetuneMode(newValue)
                        applyToAllVoices()
                    }
                ),
                displayText: { mode in
                    switch mode {
                    case .proportional: return "Proportional"
                    case .constant: return "Constant"
                    }
                }
            )
            
            // Row 9 - Stereo Offset Amount (conditional range based on mode)
            SliderRow(
                label: "STEREO AMOUNT",
                value: Binding(
                    get: {
                        if paramManager.voiceTemplate.oscillator.detuneMode == .proportional {
                            // Display cents directly (no conversion needed)
                            return paramManager.voiceTemplate.oscillator.stereoOffsetProportional
                        } else {
                            return paramManager.voiceTemplate.oscillator.stereoOffsetConstant
                        }
                    },
                    set: { newValue in
                        if paramManager.voiceTemplate.oscillator.detuneMode == .proportional {
                            // Store cents directly (no conversion needed)
                            paramManager.updateStereoOffsetProportional(newValue)
                        } else {
                            paramManager.updateStereoOffsetConstant(newValue)
                        }
                        applyToAllVoices()
                    }
                ),
                range: paramManager.voiceTemplate.oscillator.detuneMode == .proportional ? 0...20 : 0...4,
                step: paramManager.voiceTemplate.oscillator.detuneMode == .proportional ? 0.01 : 0.01,
                displayFormatter: { value in
                    if paramManager.voiceTemplate.oscillator.detuneMode == .proportional {
                        return String(format: "%.2f ct", value)
                    } else {
                        return String(format: "%.2f Hz", value)
                    }
                }
            )
        }
        .onAppear {
            // Initialize local state from current template
            let current = paramManager.voiceTemplate.oscillator.modulatingMultiplier
            modulatorCoarse = floor(current)
            modulatorFine = current - floor(current)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Updates the combined modulatingMultiplier from coarse + fine components
    private func updateModulatingMultiplier(coarse: Int, fine: Double) {
        let combined = Double(coarse) + fine
        paramManager.updateModulatingMultiplier(combined)
        applyToAllVoices()
    }
    
    /// Applies current template parameters to all active voices
    /// Uses the proper voice update method to ensure modulation state is updated
    private func applyToAllVoices() {
        let params = paramManager.voiceTemplate.oscillator
        
        // Apply to all voices using the proper update method
        // This ensures modulationState.baseModulationIndex is updated correctly
        voicePool.updateAllVoiceOscillators(params)
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack(spacing: 11) {
            OscillatorView()
        }
        .padding(25)
    }
}
