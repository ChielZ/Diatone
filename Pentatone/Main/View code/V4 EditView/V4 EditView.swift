//
//  V4 EditView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// MAIN VIEW


import SwiftUI





enum EditSubView: CaseIterable {
    case preset,oscillators,contour,modenv, auxenv,voicelfo,globallfo,touch,effects,global,macro
    
    var displayName: String {
        switch self {
        case .preset: return "PRESET"
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
        }
    }
}

struct EditView: View {
    @Binding var showingOptions: Bool
    @State private var currentSubView: EditSubView = .preset
    
    // View switching
    var onSwitchToOptions: (() -> Void)? = nil

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
                
                ZStack{ // Row 2
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("BackgroundColour"))
                    HStack{
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .aspectRatio(1.0, contentMode: .fit)
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
                            .aspectRatio(1.0, contentMode: .fit)
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
                
                ZStack { // Row 4
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("BackgroundColour"))
                    GeometryReader { geometry in
                        Text("Arithmophone")
                            .foregroundColor(Color("KeyColour1"))
                            .adaptiveFont("LobsterTwo-Italic", size: 35)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .offset(y: -(geometry.size.height/10))
                            .padding(0)
                            //.onTapGesture {
                            //    onSwitchToEdit?()
                            }
                    
                }


                Group {
                    switch currentSubView {
                    case .preset:
                        PresetView()
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
                    }
                }
                .frame(maxHeight: .infinity)
                
   
                
                

                
                
                
                ZStack { // Row 9
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("HighlightColour"))
                    GeometryReader { geometry in
                        Text("･CLOSE EDITOR･")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                            //.offset(y: -(geometry.size.height/2 + 11))
                            .padding(0)
                            .onTapGesture {
                                onSwitchToOptions?()
                            }
                    }
                }
                /*
                ZStack{ // Row 11
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("BackgroundColour"))
                    HStack{
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour4"))
                            .aspectRatio(1.0, contentMode: .fit)
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour5"))
                            .aspectRatio(1.0, contentMode: .fit)
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour1"))
                            .aspectRatio(1.0, contentMode: .fit)
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour2"))
                            .aspectRatio(1.0, contentMode: .fit)
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour3"))
                            .aspectRatio(1.0, contentMode: .fit)
                    }
                }
                */
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
        onSwitchToOptions: {}
     )
}
