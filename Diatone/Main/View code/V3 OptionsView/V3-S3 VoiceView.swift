//
//  V3-S3 VoiceView.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 06/12/2025.
//

import SwiftUI

struct VoiceView: View {
    var onSwitchToEdit: (() -> Void)? = nil
    var onSwitchToManual: (() -> Void)? = nil
    var buttonAnchors: ButtonAnchorData = ButtonAnchorData()
    
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    // State for tracking drag gestures
    @State private var tempoDragStart: Double = 0
    @State private var octaveDragStart: Int = 0
    @State private var tuneDragStart: Double = 0
    @State private var BendDragStart: Double = 0
    @State private var dragStartValue: CGFloat = 0
    
    // Computed property to force view updates
    private var fineTuneCentsDisplay: Int {
        let cents = paramManager.isGlobalMode ? paramManager.globalFineTuneCents : paramManager.master.globalPitch.fineTuneCents
        return Int(round(cents))
    }
    
    var body: some View {
        Group {
            
            ZStack { // Row 3
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    
                }
            }
            ZStack { // Row 4
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                GeometryReader { geometry in
                    Text(paramManager.isGlobalMode ? "Global" : "Per Sound")
                        .foregroundColor(Color("SupportColour"))
                        .adaptiveFont("LobsterTwo-Italic", size: 50)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        .offset(y: -(geometry.size.height/2 + 11))
                        .padding(0)
                        .onTapGesture {
                            paramManager.setGlobalMode(!paramManager.isGlobalMode)
                        }
                }
            }
            
            
            
            /*
            ZStack { // Row 5
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("<")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        )
                        .onTapGesture {
                            // Switch to monophonic
                            if paramManager.master.voiceMode != .monophonic {
                                paramManager.updateVoiceMode(.monophonic)
                            }
                        }
                    Spacer()
                    Text(paramManager.master.voiceMode == .monophonic ? "MONO" : "POLY")
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .minimumScaleFactor(0.5)
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        )
                        .onTapGesture {
                            // Switch to polyphonic
                            if paramManager.master.voiceMode != .polyphonic {
                                paramManager.updateVoiceMode(.polyphonic)
                            }
                        }
                }
            }
            */
            
            ZStack { // Row 5 - Tempo
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Left button - aligned to anchor
                        if buttonAnchors.leftFrame.width > 0 {
                            RoundedRectangle(cornerRadius: radius)
                                .fill(Color("SupportColour"))
                                .frame(width: buttonAnchors.leftFrame.width)
                                .overlay(
                                    Text("<")
                                        .foregroundColor(Color("BackgroundColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    let current = paramManager.effectiveTempo
                                    if current > 30 {
                                        paramManager.updateEffectiveTempo(current - 1)
                                    }
                                }
                        }
                        
                        Spacer()
                        
                        // Center text with drag gesture
                        Text("TEMPO \(Int(paramManager.effectiveTempo))")
                            .foregroundColor(Color("HighlightColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        if dragStartValue == 0 {
                                            dragStartValue = value.startLocation.x
                                            tempoDragStart = paramManager.effectiveTempo
                                        }
                                        
                                        let delta = value.location.x - dragStartValue
                                        let steps = Int(delta / 2)
                                        let newValue = tempoDragStart + Double(steps)
                                        let clampedValue = max(30, min(240, newValue))
                                        
                                        if clampedValue != paramManager.effectiveTempo {
                                            paramManager.updateEffectiveTempo(clampedValue)
                                        }
                                    }
                                    .onEnded { _ in
                                        dragStartValue = 0
                                    }
                            )
                        
                        Spacer()
                        
                        // Right button - aligned to anchor
                        if buttonAnchors.rightFrame.width > 0 {
                            RoundedRectangle(cornerRadius: radius)
                                .fill(Color("SupportColour"))
                                .frame(width: buttonAnchors.rightFrame.width)
                                .overlay(
                                    Text(">")
                                        .foregroundColor(Color("BackgroundColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                                        .minimumScaleFactor(0.5)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    let current = paramManager.effectiveTempo
                                    if current < 240 {
                                        paramManager.updateEffectiveTempo(current + 1)
                                    }
                                }
                        }
                    }
                }
            }
            
            
            ZStack { // Row 6 - Octave
                AlignedDraggableSelectorRow(
                    leftSymbol: "<",
                    rightSymbol: ">",
                    buttonAnchors: buttonAnchors,
                    onLeftTap: {
                        let current = paramManager.isGlobalMode ? paramManager.globalOctaveOffset : paramManager.master.globalPitch.octaveOffset
                        if current > -2 {
                            paramManager.updateEffectiveOctaveOffset(current - 1)
                        }
                    },
                    onRightTap: {
                        let current = paramManager.isGlobalMode ? paramManager.globalOctaveOffset : paramManager.master.globalPitch.octaveOffset
                        if current < 2 {
                            paramManager.updateEffectiveOctaveOffset(current + 1)
                        }
                    }
                ) {
                    let octave = paramManager.isGlobalMode ? paramManager.globalOctaveOffset : paramManager.master.globalPitch.octaveOffset
                    Text("OCTAVE \(octave > 0 ? "+" : "")\(octave)")
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .minimumScaleFactor(0.5)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if dragStartValue == 0 {
                                        dragStartValue = value.startLocation.x
                                        octaveDragStart = paramManager.isGlobalMode ? paramManager.globalOctaveOffset : paramManager.master.globalPitch.octaveOffset
                                    }
                                    
                                    let delta = value.location.x - dragStartValue
                                    let steps = Int(delta / 30)
                                    let newValue = octaveDragStart + steps
                                    let clampedValue = max(-2, min(2, newValue))
                                    
                                    let currentOctave = paramManager.isGlobalMode ? paramManager.globalOctaveOffset : paramManager.master.globalPitch.octaveOffset
                                    if clampedValue != currentOctave {
                                        paramManager.updateEffectiveOctaveOffset(clampedValue)
                                    }
                                }
                                .onEnded { _ in
                                    dragStartValue = 0
                                }
                        )
                }
            }
            ZStack { // Row 7 - Tune
                AlignedDraggableSelectorRow(
                    leftSymbol: "<",
                    rightSymbol: ">",
                    buttonAnchors: buttonAnchors,
                    onLeftTap: {
                        let current = fineTuneCentsDisplay
                        if current > -50 {
                            paramManager.updateEffectiveFineTuneCents(Double(current - 1))
                        }
                    },
                    onRightTap: {
                        let current = fineTuneCentsDisplay
                        if current < 50 {
                            paramManager.updateEffectiveFineTuneCents(Double(current + 1))
                        }
                    }
                ) {
                    Text("TUNE \(fineTuneCentsDisplay > 0 ? "+" : "")\(fineTuneCentsDisplay)")
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .minimumScaleFactor(0.5)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if dragStartValue == 0 {
                                        dragStartValue = value.startLocation.x
                                        let currentCents = paramManager.isGlobalMode ? paramManager.globalFineTuneCents : paramManager.master.globalPitch.fineTuneCents
                                        tuneDragStart = currentCents
                                    }
                                    
                                    let delta = value.location.x - dragStartValue
                                    let steps = Int(delta / 5)
                                    let newValue = tuneDragStart + Double(steps)
                                    let clampedValue = max(-50, min(50, newValue))
                                    
                                    if round(clampedValue) != Double(fineTuneCentsDisplay) {
                                        paramManager.updateEffectiveFineTuneCents(round(clampedValue))
                                    }
                                }
                                .onEnded { _ in
                                    dragStartValue = 0
                                }
                        )
                }
            }
            
            
            ZStack { // Row 8 - Bend
                AlignedDraggableSelectorRow(
                    leftSymbol: "<",
                    rightSymbol: ">",
                    buttonAnchors: buttonAnchors,
                    onLeftTap: {
                        let current = paramManager.effectiveBendRange
                        if current > 0 {
                            paramManager.updateEffectiveBendRange(current - 1)
                            applyModulationToAllVoices()
                        }
                    },
                    onRightTap: {
                        let current = paramManager.effectiveBendRange
                        if current < 15 {
                            paramManager.updateEffectiveBendRange(current + 1)
                            applyModulationToAllVoices()
                        }
                    }
                ) {
                    Text("BEND \(50 * Int(paramManager.effectiveBendRange))")
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .minimumScaleFactor(0.5)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if dragStartValue == 0 {
                                        dragStartValue = value.startLocation.x
                                        BendDragStart = paramManager.effectiveBendRange
                                    }
                                    
                                    let delta = value.location.x - dragStartValue
                                    let steps = Int(delta / 10)
                                    let newValue = Int(BendDragStart) + steps
                                    let clampedValue = max(0, min(15, newValue))
                                    
                                    if clampedValue != Int(paramManager.effectiveBendRange) {
                                        paramManager.updateEffectiveBendRange(Double(clampedValue))
                                        applyModulationToAllVoices()
                                    }
                                }
                                .onEnded { _ in
                                    dragStartValue = 0
                                }
                        )
                }
            }
            /*
            
            // Row 6 - Aftertouch to Oscillator Pitch (replaces Initial to Pitch Env temporarily)
            SliderRow(
                label: "XMOVE TO PITCH",
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
                    let cents = Int(value * 50)  // Half the semitones, convert to cents (1 semitone = 100 cents)
                    return "\(cents) ct"
                }
            )
            */
            
            
            
            /*
            ZStack { // Row 8
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                GeometryReader { geometry in
                    Text("･EDITOR･")
                        .foregroundColor(Color("BackgroundColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .minimumScaleFactor(0.5)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        //.offset(y: -(geometry.size.height/2 + 11))
                        .padding(0)
                        .onTapGesture {
                            onSwitchToEdit?()
                        }
                }
            }
            */
            
            
            ZStack { // Row 9
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("HighlightColour"))
                GeometryReader { geometry in
                    Text("･GUIDE･")
                        .foregroundColor(Color("BackgroundColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .minimumScaleFactor(0.5)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        //.offset(y: -(geometry.size.height/2 + 11))
                        .padding(0)
                        .onTapGesture {
                            onSwitchToManual?()
                        }
                }
            }
            
            
        }
    }
    /// Applies current modulation parameters to all active voices
    private func applyModulationToAllVoices() {
        let modulationParams = paramManager.effectiveModulationForVoices
        
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
            VoiceView()
        }
        .padding(25)
    }
}
