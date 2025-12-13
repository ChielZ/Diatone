//
//  OptionsView.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 02/12/2025.
//

import SwiftUI

enum OptionsSubView: CaseIterable {
    case scale, sound, voice
    
    var displayName: String {
        switch self {
        case .scale: return "SCALE"
        case .sound: return "SOUND"
        case .voice: return "VOICE"
        }
    }
}

struct OptionsView: View {
    @Binding var showingOptions: Bool
    @State private var currentSubView: OptionsSubView = .scale

    var body: some View {
        
        ZStack{
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("HighlightColour"))
                .padding(5)
            
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
                .padding(12)
            
            VStack {
                ZStack{ // Row 1
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("HighlightColour"))
                    Text("•FOLD•")
                        .foregroundColor(Color("BackgroundColour"))
                        .font(.custom("Futura", size:30))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingOptions = false
                        }
                }
                
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
                                    .font(.custom("Futura",size:30))
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
                            .font(.custom("Futura",size:30))
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
                                    .font(.custom("Futura",size:30))
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                nextSubView()
                            }
                    }
                }
                
                // Rows 3-9: Show the current subview
                Group {
                    switch currentSubView {
                    case .scale:
                        ScaleView()
                    case .sound:
                        SoundView()
                    case .voice:
                        VoiceView()
                    }
                }
                
                ZStack{ // Row 10
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("BackgroundColour"))
                    HStack{
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Text("A")
                                    .foregroundColor(Color("KeyColour4"))
                                    .font(.custom("Futura",size:30))
                                    .minimumScaleFactor(0.3)
                                    .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Text("Bb")
                                    .foregroundColor(Color("KeyColour5"))
                                    .font(.custom("Futura",size:30))
                                    .minimumScaleFactor(0.3)
                                    .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Text("D")
                                    .foregroundColor(Color("KeyColour1"))
                                    .font(.custom("Futura",size:30))
                                    .minimumScaleFactor(0.3)
                                    .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Text("F#")
                                    .foregroundColor(Color("KeyColour2"))
                                    .font(.custom("Futura",size:30))
                                    .minimumScaleFactor(0.3)
                                    .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Text("G")
                                    .foregroundColor(Color("KeyColour3"))
                                    .font(.custom("Futura",size:30))
                                    .minimumScaleFactor(0.3)
                                    .lineLimit(1)
                            )
                    }
                }
                
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
            }.padding(19)
            
        }
    }
    
    // MARK: - Navigation Functions
    
    private func nextSubView() {
        let allCases = OptionsSubView.allCases
        if let currentIndex = allCases.firstIndex(of: currentSubView) {
            let nextIndex = (currentIndex + 1) % allCases.count
            withAnimation(.easeInOut(duration: 0.2)) {
                currentSubView = allCases[nextIndex]
            }
        }
    }
    
    private func previousSubView() {
        let allCases = OptionsSubView.allCases
        if let currentIndex = allCases.firstIndex(of: currentSubView) {
            let previousIndex = (currentIndex - 1 + allCases.count) % allCases.count
            withAnimation(.easeInOut(duration: 0.2)) {
                currentSubView = allCases[previousIndex]
            }
        }
    }
}

#Preview {
    OptionsView(showingOptions: .constant(true))
}
