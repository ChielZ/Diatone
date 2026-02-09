//
//  V5 ManualView.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 10/01/2026.
//

import SwiftUI

struct ManualView: View {
    @Binding var showingOptions: Bool
    var onSwitchToOptions: (() -> Void)? = nil
    
    @State private var selectedSection: Int = 0 // 0 = Introduction, 1 = How to Use, 2 = Background
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("HighlightColour"))
                .padding(5)
            
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
                .padding(9)
            
            VStack(spacing: 11) {
                ZStack { // Row 1 - Fold Button
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
                
                // Row 2 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 3 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 4 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 5 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 6 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 7 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 8 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 9 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                HStack(spacing: 11) { // Row 10 - Section Navigation
                    // Section I: Introduction
                    ZStack {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(selectedSection == 0 ? Color("HighlightColour") : Color("SupportColour"))
                        Text("I")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSection = 0
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Section II: How to Use
                    ZStack {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(selectedSection == 1 ? Color("HighlightColour") : Color("SupportColour"))
                        Text("II")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSection = 1
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Section III: Background
                    ZStack {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(selectedSection == 2 ? Color("HighlightColour") : Color("SupportColour"))
                        Text("III")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSection = 2
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxHeight: .infinity)
                
                ZStack { // Row 11 - Close Manual Button
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("HighlightColour"))
                    GeometryReader { geometry in
                        Text("･CLOSE GUIDE･")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .padding(0)
                            .onTapGesture {
                                onSwitchToOptions?()
                            }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .padding(19)
            .overlay(
                // Overlay the scrollable content on top of rows 2-9
                GeometryReader { geometry in
                    let totalHeight = geometry.size.height - 38 // Account for padding (19 * 2)
                    let spacing: CGFloat = 11
                    let rowHeight = (totalHeight - (spacing * 10)) / 11 // 11 rows, 10 spacings
                    let contentTop = rowHeight + spacing // After row 1
                    let contentHeight = rowHeight * 8 + spacing * 7 // 8 rows (2-9) and 7 spacings between them
                    
                    VStack {
                        Spacer()
                            .frame(height: contentTop)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: radius)
                                .fill(Color("BackgroundColour"))
                            
                            ScrollView {
                                VStack(alignment: .center, spacing: 15) {
                                    switch selectedSection {
                                    case 0:
                                        introductionContent
                                    case 1:
                                        howToUseContent
                                    case 2:
                                        backgroundContent
                                    default:
                                        introductionContent
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: contentHeight)
                        
                        Spacer()
                    }
                    .padding(19)
                }
            )
        }
    }
    
    // MARK: - Section Content Builders
    
    @ViewBuilder
    private var introductionContent: some View {
        Text("Welcome to the Arithmophone Diatone!")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .centeredText()
            .padding(.bottom, 5)
        
        Text("This guide explains all the functions of the app, and also includes background sections on musical scales and tunings")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("I: INTRODUCTION")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 24)
            .padding(.top, 25)
            .centeredText()
        
        Text("WHAT IS AN ARITHMOPHONE?")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 20)
            .centeredText()
        
        Text("An Arithmophone is a thing that turns numbers into sounds, or math into music. Its name is derived from the ancient Greek words ἀριθμός (arithmos; number) and φωνή (phone; sound). The device you're holding in your hands right now is itself an Arithmophone, in the sense that it routinely turns long strings of binary numbers into sounds. But this app is a bit more 'arithmophonic' still, because it uses pure and simple harmonic ratios like 3/2 and 5/4 to produce musical notes.")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("WHAT IS DIATONE?")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 20)
            .centeredText()
        
        Text("Diatone is an iOS music app featuring an expressive keyboard, a unique selection of pentatonic scales and a custom sound engine. You can use it as a musical instrument, a source of melodic and harmonic inspiration or a tool for learning music and exploring the deep connection it has with numbers.")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("The keyboard")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("Diatone's music keyboard is designed from the ground up for the form factor of handheld touchscreen devices. It turns your iPhone or iPad into an instrument with exactly the right ergonomics for playing music. Rather than emulating a piano or a guitar fretboard (which are both very well designed interfaces, but with a very different form factor), the Diatone features an original design that takes inspiration from traditional African instruments like the Kora and the Mbira (also known as Kalimba or Karimba), on which melodies are played by alternating between the left and right hand.")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("Diatone features a keyboard with 22 keys, 11 on each side of the screen, which can be played very comfortably with both thumbs while holding your iPhone or iPad in your hands. To play the notes in scale order, start with the lowest key on the left, then play the lowest key on the right, then the second key on the left, and so on.")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("The scales")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("The name Diatone comes from the Greek words διατονικός (diatonikos; diatonic), a term that has been used since ancient times to describe scales with 7 notes per octave. The familiar 'do re mi fa sol la ti do' is such a scale, but there are many others as well. The Arithmophone Diatone has 12 different scales to choose from, and each of these can be played in any musical key and in two different tuning modes: just intonation (rational harmonic intervals, where the notes sound perfectly in tune with each other) or equal temperament (standard Western tuning, suitable for playing along with guitars, pianos et cetera).")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("Because the keyboard of the Arithmophone Diatone has only 7 notes per octave, it is much easier to play scales and melodies on it than on a 'chromatic' instrument like a piano or a guitar: just select the scale you need and there are no 'wrong notes' to worry about anymore. But because it is also very quick and easy to change scales and keys, the Diatone still retains much of the flexibility of standard chromatic instruments, and there is lots of depth to explore here for more advanced users.")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("The sounds")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("Diatone has its own built-in sound engine and there are 49 preset sounds to choose from. The sounds respond to initial touch (where on the key you first place your finger) and aftertouch (how you move your finger on the key while holding it down). Different preset sounds respond to your touch in different ways: on some sounds, moving your finger may change the brightness of the tone, on others it may change the pitch, allowing you to 'bend' the notes, and so on.")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("Each of the preset sounds can be changed by adjusting the 'volume', 'tone' and 'ambience' sliders, and the keyboard's response can be customised further on the 'setup' page. Diatone's sound engine uses a combination of Frequency Modulation and substractive synthesis. It is inspired by some classic digital synthesizers and keyboards from the 1980s, but it also adds a few more modern twists like binaural stereo imaging and effects.")
        /*
         It features a binaural 2x2 operator FM synth with a resonant lowpass filter per voice, a flexible modulation system and stereo detune, delay and reverb. An optional in-app purchase unlocks the full sound design experience, giving you access to all parameters of the sound engine, as well as the ability to create, store, import and export up to 100 user presets.
         */
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
    }
    
    @ViewBuilder
    private var howToUseContent: some View {
        Text("II: HOW TO USE DIATONE")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 24)
            .padding(.top, 10)
            .centeredText()
        
        Text("This section will guide you through using all the features of the Arithmophone Diatone.")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 20)
        
        Text("Folding and unfolding")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("[Content to be added]")
            .foregroundColor(Color("SupportColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The Scale View")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("[Content to be added]")
            .foregroundColor(Color("SupportColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The Sound View")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("[Content to be added]")
            .foregroundColor(Color("SupportColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The Setup View")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("[Content to be added]")
            .foregroundColor(Color("SupportColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
    }
    
    @ViewBuilder
    private var backgroundContent: some View {
        Text("III: BACKGROUND")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 24)
            .padding(.top, 10)
            .centeredText()
        
        Text("Learn about the musical concepts behind the Arithmophone Diatone.")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 20)
        
        Text("What is just intonation?")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("[Content to be added]")
            .foregroundColor(Color("SupportColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("What is equal temperament?")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("[Content to be added]")
            .foregroundColor(Color("SupportColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The arithmophone diatonic scale selection")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("[Content to be added]")
            .foregroundColor(Color("SupportColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Scale diagrams")
            .foregroundColor(Color("KeyColour1"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("[Content to be added]")
            .foregroundColor(Color("SupportColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
    }
}

// MARK: - View Extensions
extension View {
    func centeredText() -> some View {
        self
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    ManualView(
        showingOptions: .constant(true)
    )
}
