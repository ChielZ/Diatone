//
//  V5 ManualView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 10/01/2026.
//

import SwiftUI

struct ManualView: View {
    @Binding var showingOptions: Bool
    var onSwitchToOptions: (() -> Void)? = nil
    
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
                
                // Row 10 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                ZStack { // Row 11 - Close Manual Button
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
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
                // Overlay the scrollable content on top of rows 2-10
                GeometryReader { geometry in
                    let totalHeight = geometry.size.height - 38 // Account for padding (19 * 2)
                    let spacing: CGFloat = 11
                    let rowHeight = (totalHeight - (spacing * 10)) / 11 // 11 rows, 10 spacings
                    let contentTop = rowHeight + spacing // After row 1
                    let contentHeight = rowHeight * 9 + spacing * 8 // 9 rows and 8 spacings between them
                    
                    VStack {
                        Spacer()
                            .frame(height: contentTop)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: radius)
                                .fill(Color("BackgroundColour"))
                            
                            ScrollView {
                                VStack(alignment: .center, spacing: 15) {
                                    Text("Welcome to the Arithmophone Pentatone!")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .multilineTextAlignment(.center)
                                        .padding(.bottom, 5)
                                    
                                    Text("This guide explains all the functions of the app, and also includes background sections on music theory and sound synthesis.")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 16)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("I: INTRODUCTION")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 24)
                                        .padding(.top, 25)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("WHAT IS AN ARITHMOPHONE?")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 20)
                                        .multilineTextAlignment(.center)
                                    
                                    
                                    Text("An Arithmophone is a thing that turns numbers into sounds, or math into music. Its name is derived from the ancient Greek words ἀριθμός (arithmos; number) and φωνή (phone; sound). The device you're holding in your hands right now is itself an Arithmophone, in the sense that it routinely turns long strings of binary numbers into sounds. But this app is even more 'arithmophonic' than that, because it uses pure and simple harmonic ratios like 3/2 and 5/4 to produce musical notes. You can use this app as a musical instrument, a source of melodic and harmonic inspiration or a tool for exploring the deep connection between music and numbers.")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 16)
                                        .multilineTextAlignment(.center)
                                    
                                    
                                    Text("WHAT IS PENTATONE?")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 20)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Pentatone is an iOS music app featuring an expressive keyboard, a unique selection of pentatonic scales and a custom sound engine:")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 16)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("The keyboard")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Pentatone's music keyboard is designed from the ground up for the form factor of handheld touchscreen devices. It turns your iPhone or iPad into an instrument with exactly the right ergonomics for playing music. Rather than emulating a piano or a guitar fretboard (which are both very well designed interfaces, but with a very different form factor), the Pentatone features an original design that takes inspiration from traditional African instruments like the Kora, on which melodies are played by alternating between the left and right hand, and the Mbira (also known as Kalimba or Karimba), which is played with the thumbs. The alternating thumb approach makes it natural and intuitive to play flowing melodies on a touchscreen.")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 16)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Pentatone features a keyboard with 18 keys, 9 on each side of the screen, which can be played very comfortably with both thumbs while holding your iPhone or iPad in your hands. To play the notes in scale order, alternate between left and right: start with the lowest key on the left, then play the lowest key on the right, then the second key on the left, and so on.")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 16)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("The scales")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("The name Pentatone comes from the Greek words πεντᾰ (pentă; five) and τόνος (tónos; note) and the keyboard uses pentatonic scales: scales with 5 notes per octave. There are 9 unique scales to choose from, and each of these can be played in any musical key and in two different tuning modes: just intonation (rational harmonic intervals, where the notes sound perfectly in tune with each other) or equal temperament (standard Western tuning, suitable for playing along with guitars, pianos et cetera).")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 16)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Because pentatonic scales contain only 5 different notes, every combination of notes tends to sounds musical. There are no 'wrong notes' to worry about, making them very suitable for beginners and casual musicians, but many rich musical traditions are based on pentatonic scales, and there is lots of depth to explore here too for more advanced users.")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 16)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("The sound engine")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Pentatone has its own built-in synthesizer and there are 25 preset sounds to choose from. The keyboard responds to initial touch (where on the key you first place your finger) and aftertouch (how you move your finger on the key while holding it down). Different preset sounds respond to your touch in different ways: on some sounds, moving your finger may change the brightness of the tone, on others it may change the pitch, allowing you to 'bend' the notes. There are three sliders that allow you to quickly adjust the volume, tone and ambience of each preset sound.")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 16)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Pentatone's sound engine uses Frequency Modulation synthesis (the same technology behind classic 1980s digital synths) with spatial stereo imaging and effects. Specifically, it is a binaural 2x2 operator FM synth with a resonant lowpass filter per voice, a flexible modulation system and stereo detune, delay and reverb effects. An optional in-app purchase unlocks the full sound design experience, giving you access to all parameters of the sound engine, as well as the ability to create, store, import and export up to 100 user presets.")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 16)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("II: USER MANUAL")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 24)
                                        .padding(.top, 25)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("The Scales View")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("The Sounds View")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("The Settings View")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("III: BACKGROUND")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 24)
                                        .padding(.top, 25)
                                        .multilineTextAlignment(.center)
                                
                                    Text("What is just intonation?")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("What is equal temperament?")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("The arithmophone pentatonic scale system")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Scale diagrams")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("FM and Sound synthesis")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("IV: THE SOUND EDITOR")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 24)
                                        .padding(.top, 25)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Page 1 - Oscillators")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Page 2 - Amp + Filter")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Page 3 - Mod + Track")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Page 4 - Aux Env")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Page 5 - Voice LFO")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Page 6 - Global LFO")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Page 7 - Touch")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Page 8 - Effects")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Page 9 - Master")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Page 10 - Macro")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Page 11 - Preset")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                    

                                    
                                    // Add more content as needed
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
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
}

#Preview {
    ManualView(
        showingOptions: .constant(true)
    )
}
