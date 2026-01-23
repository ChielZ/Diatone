//
//  V3-S3 VoiceView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 06/12/2025.
//

import SwiftUI

struct VoiceView: View {
    var onSwitchToEdit: (() -> Void)? = nil
    
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    // State for tracking drag gestures
    @State private var tempoDragStart: Double = 0
    @State private var octaveDragStart: Int = 0
    @State private var tuneDragStart: Double = 0
    @State private var dragStartValue: CGFloat = 0
    
    // Computed property to force view updates
    private var fineTuneCentsDisplay: Int {
        let value = Int(round(paramManager.master.globalPitch.fineTuneCents))
        return value
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
                    Text("Arithmophone")
                        .foregroundColor(Color("KeyColour1"))
                        .adaptiveFont("LobsterTwo-Italic", size: 50)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        .offset(y: -(geometry.size.height/2 + 11))
                        .padding(0)
                        //.onTapGesture {
                        //    onSwitchToEdit?()
                        //}
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
                            let current = paramManager.master.tempo
                            if current > -30 {
                                paramManager.updateTempo(Double(current - 1))
                                }
                        }
                    Spacer()
                    Text("TEMPO \(Int(paramManager.master.tempo))")
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .minimumScaleFactor(0.5)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if dragStartValue == 0 {
                                        dragStartValue = value.startLocation.x
                                        tempoDragStart = paramManager.master.tempo
                                    }
                                    
                                    let delta = value.location.x - dragStartValue
                                    let steps = Int(delta / 2) // 10 points per step
                                    let newValue = tempoDragStart + Double(steps)
                                    let clampedValue = max(30, min(240, newValue))
                                    
                                    if clampedValue != paramManager.master.tempo {
                                        paramManager.updateTempo(clampedValue)
                                    }
                                }
                                .onEnded { _ in
                                    dragStartValue = 0
                                }
                        )
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 30)
                                .minimumScaleFactor(0.5)
                        )
                        .onTapGesture {
                            let current = paramManager.master.tempo
                            if current < 240 {
                                paramManager.updateTempo(Double(current + 1))
                                }
                        }
                    
                }
                
            }
            
            
            ZStack { // Row 6
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
                            let current = paramManager.master.globalPitch.octaveOffset
                            if current > -2 {
                                paramManager.updateOctaveOffset(current - 1)
                            }
                        }
                    Spacer()
                    Text("OCTAVE \(paramManager.master.globalPitch.octaveOffset > 0 ? "+" : "")\(paramManager.master.globalPitch.octaveOffset)")
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .minimumScaleFactor(0.5)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if dragStartValue == 0 {
                                        dragStartValue = value.startLocation.x
                                        octaveDragStart = paramManager.master.globalPitch.octaveOffset
                                    }
                                    
                                    let delta = value.location.x - dragStartValue
                                    let steps = Int(delta / 30) // 30 points per step (larger for fewer octaves)
                                    let newValue = octaveDragStart + steps
                                    let clampedValue = max(-2, min(2, newValue))
                                    
                                    if clampedValue != paramManager.master.globalPitch.octaveOffset {
                                        paramManager.updateOctaveOffset(clampedValue)
                                    }
                                }
                                .onEnded { _ in
                                    dragStartValue = 0
                                }
                        )
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
                            let current = paramManager.master.globalPitch.octaveOffset
                            if current < 2 {
                                paramManager.updateOctaveOffset(current + 1)
                            }
                        }
                }
            }
            ZStack { // Row 7
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
                            let current = fineTuneCentsDisplay
                            if current > -50 {
                                paramManager.updateFineTuneCents(Double(current - 1))
                                }
                        }
                    Spacer()
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
                                        tuneDragStart = paramManager.master.globalPitch.fineTuneCents
                                    }
                                    
                                    let delta = value.location.x - dragStartValue
                                    let steps = Int(delta / 5) // 5 points per step (fine control)
                                    let newValue = tuneDragStart + Double(steps)
                                    let clampedValue = max(-50, min(50, newValue))
                                    
                                    if round(clampedValue) != round(paramManager.master.globalPitch.fineTuneCents) {
                                        paramManager.updateFineTuneCents(round(clampedValue))
                                    }
                                }
                                .onEnded { _ in
                                    dragStartValue = 0
                                }
                        )
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 30)
                                .minimumScaleFactor(0.5)
                        )
                        .onTapGesture {
                            let current = fineTuneCentsDisplay
                             if current < 50 {
                                paramManager.updateFineTuneCents(Double(current + 1))
                             }
                        }
                    
                }
                
            }
            
            
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
            ZStack { // Row 9
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("HighlightColour"))
                GeometryReader { geometry in
                    Text("･MANUAL･")
                        .foregroundColor(Color("BackgroundColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .minimumScaleFactor(0.5)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        //.offset(y: -(geometry.size.height/2 + 11))
                        .padding(0)
                }
            }
            
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
