//
//  V4 EditView.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// MAIN VIEW


import SwiftUI





enum EditSubView: String, CaseIterable {
    case oscillators,contour,modenv, auxenv,voicelfo,globallfo,touch,effects,global,macro, preset
    
    var displayName: String {
        switch self {
        case .oscillators: return "OSCILLATORS"
        case .contour: return "AMP + FILTER"
        case .modenv: return "MOD + TRACK"
        case .auxenv: return "AUX ENV"
        case .voicelfo: return "VOICE LFO"
        case .globallfo: return "GLOBAL LFO"
        case .touch: return "TOUCH"
        case .effects: return "EFFECTS"
        case .global: return "MASTER"
        case .macro: return "MACRO"
        case .preset: return "PRESET"
        }
    }
}

struct EditView: View {
    @Binding var showingOptions: Bool
    @Binding var currentSubView: EditSubView
    
    // View switching
    var onSwitchToOptions: (() -> Void)? = nil
    
    // Observe the shared button width from OptionsView
    @ObservedObject private var sharedButtonWidth = SharedButtonWidth.shared

    var body: some View {
        

        
        ZStack{
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("HighlightColour"))
                .padding(5)
            
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
                .padding(9)
            
            VStack(spacing: 11) {
                ZStack{ // Row 1
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("HighlightColour"))
                    Text("･FOLD･")
                        .foregroundColor(Color("BackgroundColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingOptions = false
                        }
                }
                .frame(maxHeight: .infinity)
                
                // Row 2 - Buttons with width matching OptionsView
                ZStack{
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("BackgroundColour"))
                    
                    HStack(spacing: 0) {
                        // Use the exact same width as OptionsView buttons
                        let buttonWidth = sharedButtonWidth.width > 0 ? sharedButtonWidth.width : 60 // fallback
                        
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .frame(width: buttonWidth)
                            .overlay(
                                Text("<")
                                    .foregroundColor(Color("BackgroundColour"))
                                    .adaptiveFont("MontserratAlternates-Medium", size: 30)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                previousSubView()
                            }
                        
                        Spacer()
                        
                        Text(currentSubView.displayName)
                            .foregroundColor(Color("HighlightColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .frame(width: buttonWidth)
                            .overlay(
                                Text(">")
                                    .foregroundColor(Color("BackgroundColour"))
                                    .adaptiveFont("MontserratAlternates-Medium", size: 30)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                nextSubView()
                            }
                    }
                }
                .frame(maxHeight: .infinity)
                
                ZStack { // Row 3
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("BackgroundColour"))
                    GeometryReader { geometry in
                        Text("Arithmophone")
                            .foregroundColor(Color("SupportColour"))
                            .adaptiveFont("LobsterTwo-Italic", size: 42)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .offset(y: -(geometry.size.height/10))
                            .padding(0)
                            .onTapGesture {
                                onSwitchToOptions?()
                            }
                    }
                }


                Group {
                    switch currentSubView {
                    
                    case .oscillators:
                        OscillatorView()
                    case .contour:
                        ContourView()
                    case .modenv:
                        ModEnvView()
                    case .auxenv:
                        AuxEnvView()
                    case .voicelfo:
                        VoiceLFOView()
                    case .globallfo:
                        GlobLFOView()
                    case .touch:
                        TouchView()
                    case .effects:
                        EffectsView()
                    case .global:
                        GlobalView()
                    case .macro:
                        MacroView()
                    case .preset:
                        PresetView()
                    }
                }
                .frame(maxHeight: .infinity)
                
                ZStack { // Row 10 - Close Editor button
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                    GeometryReader { geometry in
                        Text("･CLOSE EDITOR･")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .padding(0)
                            .onTapGesture {
                                onSwitchToOptions?()
                            }
                    }
                }
                .frame(maxHeight: .infinity)
            }.padding(19)
            
        }
    }
    
    // MARK: - Navigation Functions
    
    private func nextSubView() {
        let allCases = EditSubView.allCases
        if let currentIndex = allCases.firstIndex(of: currentSubView) {
            let nextIndex = (currentIndex + 1) % allCases.count
            currentSubView = allCases[nextIndex]
        }
    }
    
    private func previousSubView() {
        let allCases = EditSubView.allCases
        if let currentIndex = allCases.firstIndex(of: currentSubView) {
            let previousIndex = (currentIndex - 1 + allCases.count) % allCases.count
            currentSubView = allCases[previousIndex]
        }
    }
}

#Preview {
    EditView(
        showingOptions: .constant(true),
        currentSubView: .constant(.preset),
        onSwitchToOptions: {}
     )
}
