//
//  V5 ManualView.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 10/01/2026.
//

import SwiftUI

/// Creates an AttributedString with underline styling (iOS 15 compatible)
private func underlinedText(_ text: String) -> AttributedString {
    var attributedString = AttributedString(text)
    attributedString.underlineStyle = .single
    return attributedString
}

struct ManualView: View {
    @Binding var showingOptions: Bool
    var onSwitchToOptions: (() -> Void)? = nil
    
    @State private var selectedSection: Int = 0 // 0 = Introduction, 1 = How to Use, 2 = Background
    @State private var scrollToTopTrigger: Int = 0 // Used to trigger scroll to top
    
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
                            .fill(Color("SupportColour"))
                        Text("I")
                            .foregroundColor(selectedSection == 0 ? Color("HighlightColour") : Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSection = 0
                        scrollToTopTrigger += 1
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Section II: How to Use
                    ZStack {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                        Text("II")
                            .foregroundColor(selectedSection == 1 ? Color("HighlightColour") : Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSection = 1
                        scrollToTopTrigger += 1
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Section III: Background
                    ZStack {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                        Text("III")
                            .foregroundColor(selectedSection == 2 ? Color("HighlightColour") : Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSection = 2
                        scrollToTopTrigger += 1
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
                            
                            ScrollViewReader { proxy in
                                ScrollView(showsIndicators: false) {
                                    VStack(alignment: .center, spacing: 15) {
                                        // Invisible anchor at the top for scrolling
                                        Color.clear
                                            .frame(height: 0)
                                            .id("scrollTop")
                                        
                                        switch selectedSection {
                                        case 0:
                                            introductionContent
                                        case 1:
                                            howToUseContent(scrollProxy: proxy)
                                        case 2:
                                            backgroundContent(scrollProxy: proxy)
                                        default:
                                            introductionContent
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                }
                                .onChange(of: scrollToTopTrigger) { _ in
                                    proxy.scrollTo("scrollTop", anchor: .top)
                                }
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
        
        Text("I: INTRODUCTION")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 24)
            .padding(.top, 10)
            .centeredText()
        
        Text("Welcome to the Arithmophone Diatone! This guide explains all the functions of the app, and also includes a background section on musical scales and tunings")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("WHAT IS AN ARITHMOPHONE?")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 20)
            .centeredText()
        
        Text("An Arithmophone is a thing that turns numbers into sounds, or math into music. Its name is derived from the ancient Greek words ἀριθμός (arithmos; number) and φωνή (phone; sound). The device you're holding in your hands right now is itself an Arithmophone, in the sense that it routinely turns long strings of binary numbers into sounds. But this app is a bit more 'arithmophonic' still, in that it features a just intonation tuning mode, which takes pure and simple numeric ratios like 3/2 and 5/4 and turn these into musical notes directly.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("WHAT IS DIATONE?")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 20)
            .centeredText()
        
        Text("Diatone is an iOS music app featuring an expressive keyboard, a wide selection of diatonic scales and a built in synthesizer with a custom sound engine. You can use it as a musical instrument, a source of melodic and harmonic inspiration or a tool for learning music and exploring the deep connection it has with numbers.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("The keyboard")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("Diatone's music keyboard is purpose-built for the form factor of handheld touchscreen devices. It turns your iPhone or iPad into an instrument with exactly the right ergonomics for playing music. Rather than emulating a piano or a guitar fretboard (which are both great interfaces, but with a very different form factor), the Diatone features an original design that takes inspiration from traditional African instruments like the Kora and the Mbira (also known as Kalimba or Karimba), on which melodies are played by alternating between the left and right hand.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("Diatone features a keyboard with 22 keys, 11 on each side of the screen, which can be played very comfortably with both thumbs while holding your iPhone or iPad in your hands. If you rest your device on your lap or some other suitable surface, you can use your other fingers as well, so you can play chords and arpeggios too. To play the notes in scale order, start with the lowest key on the left, then play the lowest key on the right, then the second key on the left, and so on.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("The scales")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("The name Diatone comes from the Greek words διατονικός (diatonikos; diatonic), a term that has been used since ancient times to describe scales with 7 notes per octave. The familiar 'do re mi fa sol la ti do' is such a scale, but there are many others as well. The Arithmophone Diatone has 12 different scales to choose from, and each of these can be played in any musical key and in two different tuning modes: just intonation (rational harmonic intervals, where the notes sound perfectly in tune with each other) or equal temperament (standard Western tuning, suitable for playing together with guitars, pianos and most electronic instruments).")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("Because the keyboard of the Arithmophone Diatone has only 7 notes per octave, it is much easier to play scales and melodies on it than on a 'chromatic' instrument like a piano or a guitar: just select the scale you need and there are no 'wrong notes' to worry about anymore. But because it is also very quick and easy to change scales and keys, the Diatone still retains much of the flexibility of standard chromatic instruments, and there is lots of depth to explore here for more advanced users.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("The sounds")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("Diatone has its own built-in sound engine and there are 49 preset sounds to choose from. The sounds respond to initial touch (where on the key you first place your finger) and aftertouch (how you move your finger on the key while holding it down). Different preset sounds respond to your touch in different ways: on some sounds, moving your finger may change the brightness of the tone, on others it may change the pitch, allowing you to 'bend' the notes, and so on.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("Each of the preset sounds can be changed by adjusting the volume, tone and ambience sliders, and the keyboard's response can be customised further on the 'setup' page. Diatone's sound engine uses a combination of FM (frequency modulation) and substractive synthesis. It is inspired by some classic digital synthesizers and keyboards from the 1980s, but it also adds a few more modern twists like binaural stereo imaging and effects.")
        /*
         It features a binaural 2x2 operator FM synth with a resonant lowpass filter per voice, a flexible modulation system and stereo detune, delay and reverb. An optional in-app purchase unlocks the full sound design experience, giving you access to all parameters of the sound engine, as well as the ability to create, store, import and export up to 100 user presets.
         */
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("* * * * * * *")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
        
        Text("Use the buttons below to turn to the next sections and learn how to use the Arithmophone Diatone (section II) or read about musical scales and tunings (section III).")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
        
    }
    
    @ViewBuilder
    private func howToUseContent(scrollProxy: ScrollViewProxy) -> some View {
        Text("II: HOW TO USE DIATONE")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 24)
            .padding(.top, 10)
            .centeredText()
        
        Text("This section will guide you through using all the features of the Arithmophone Diatone. Scroll down to read on or click one of the subsection names below to jump there directly.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 20)
        
        Text(underlinedText("II A: The Keyboard"))
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
            .onTapGesture {
                withAnimation {
                    scrollProxy.scrollTo("keyboard", anchor: .top)
                }
            }
        
        Text(underlinedText("II B: The Scale View"))
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
            .onTapGesture {
                withAnimation {
                    scrollProxy.scrollTo("scaleView", anchor: .top)
                }
            }
        
        Text(underlinedText("II C: The Sound View"))
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
            .onTapGesture {
                withAnimation {
                    scrollProxy.scrollTo("soundView", anchor: .top)
                }
            }

        Text(underlinedText("II D: The Setup View"))
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
            .onTapGesture {
                withAnimation {
                    scrollProxy.scrollTo("setupView", anchor: .top)
                }
            }
        
        
        Text("* * * * * * *")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
            .padding(.bottom, 20)
        
 
        Text("THE KEYBOARD")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
            .id("keyboard")
        
        Text("When you first open the Arithmophone Diatone app, you will see the keyboard, divided into a right and a left section by a small vertical bar. The left and right sections combine to form one keyboard together: to play a scale, alternate between playing the left and right keys as you move up or down the keyboard. The keyboard responds to both initial touch and aftertouch: try hitting the keys on different places and moving your finger around while you hold down a key to hear the effect this has on the sound.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Touching the 'UNFOLD' text in the central bar will unfold the option view, which has three different pages for adjusting the scale, sound and keyboard setup. When you're done adjusting the settings, you can always touch the 'FOLD' button at the top of the screen to close the option view, maximizing the playable area of the keys.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The bottom of the option view always shows the note display, that lets you know which notes are currently mapped to the keyboard by corresponding colours (this changes as you switch to different scales and/or keys).")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)

        
        Text("THE SCALE VIEW")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
            .id("scaleView")
        
        Text("The scale view lets you switch between different scales, keys and tunings. At the top of the view (just below the main page selector) there is an image that shows how the notes of the currently selected scale are related to each other: their distance in semitones for equal temperament scales, and the rational intervals between them for just intonation scales. How you can read these images precisely is explained at the end of section III of this guide, but regardless of that they serve as a quick visual indication of the currently selected scale. Beneath this are 5 options for changing the notes of the keyboard:")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("TUNING: here you can switch between equal temperament and just intonation tuning. Equal temperament is the standard tuning system used in Western musical instruments like guitars and pianos, while just intonation uses rational harmonic intervals instead, so that the notes in the scale are in perfect numerical proportions to each other. This tuning method is much more ancient and universal than the modern Western system of equal temperament and has a distinctly 'harmonious' feel to it, though this comes at the expense of less flexibility in playing chords and moving to different keys.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Both of these tuning systems have their own distinct character. The differences are fairly subtle but put simply, with just intonation some note combinations sound perfect together while other combinations are quite out of tune, whereas in equal temperament, no note combinations are perfect, but all combinations are quite acceptable. If you'd like to learn more about this, please read the background information in section III of this guide, but you don't need to worry about it if you don't want to. You can simply leave this on 'equal', forget about it and start making some music, and revisit this setting any time you feel like exploring the wonderfully deep connection between notes and numbers.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("KEY: this lets you select the musical key that the keyboard is in: changing this transposes the entire keyboard up or down. In combination with the scale selection, this determines which musical note is mapped to each of the keys.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("SCALE: this lets you select which musical scale is mapped to the keyboard. Each scale has its own selection of 7 notes and provides its own unique mood. There is more detailed information about the available scales in section III of this guide. To get started without delving into all of that, just use the Ionian mode for typical 'major' melodies, use the Aeolian mode for typical 'minor' melodies, or try the double harmonic scale for a more spicy flavour.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("SCALE GROUP: the 12 available scales are arranged in 3 groups: modal, melodic and harmonic. The modal scales will probably sound most familiar to most users, as these are essentially all permutations of the familiar 'do re mi fa sol la ti do' scale. The melodic and harmonic scales offer some interesting alternatives: these don't fit the modal pattern, but are commonly used across multiple musical traditions nonetheless.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("ROTATION: this keeps the mapping from scale note to key colour intact, but shifts the screen keyboard up or down by up to 3 steps. This gives you control over the lowest and highest notes available for playing.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        
        
        Text("THE SOUND VIEW")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
            .id("soundView")
        
        Text("The sound view lets you select one of the 49 available synthesizer presets. These are arranged in 7 groups of 7. After selecting a preset, you can change its sound by using the control sliders.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("At the top of the view (just below the main page selector) you will see the name of the currently selected preset. The first row of buttons below that lets you switch between one of the 7 preset groups. The second row lets you switch between the 7 presets within each group.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Below the preset selection buttons there are three sliders that let you adjust the sound to your liking. These are automatically reset to their default (centered) positions when a new preset is selected. The VOLUME slider simply makes the sound softer or louder. Tip: set the volume to the desired level with the main volume controls of your device while the Diatone's volume slider is in its center position, then use the slider for quick 'on the fly' adjustments or expressive control.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The TONE slider affects different preset sounds in different ways, but it will generally make the sound brighter as you move the slider to the right, and sometimes also a bit louder and/or more overdriven.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The AMBIENCE slider also has a different effect depending on the selected preset, but it generally provides a more spacious sound when moved to the right and a drier, more direct sound when moved to the left.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        
        Text("THE SETUP VIEW")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
            .id("setupView")
        
        Text("The setup view lets you adjust some further settings that determine how Diatone sounds and how the keyboard responds to your playing. By default, this setup is reset when a new preset is loaded, just like the sliders in the sound view. If you want to maintain the same setup while you switch between presets, you can tap the 'Per Sound' text to make the setup mode change to 'Global'.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("TEMPO lets you adjust the rate of synchronized modulations and delays, this is particularly useful when you want to play along with existing songs or with other synthesizers/sequencers.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("OCTAVE transposes the keyboard up or down in full octaves and lets you adjust for bass, chord or lead playing.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("TUNE allows you to fine tune the keyboard in steps of 1 cent (a cent is 1/100 of an equal temperament semitone). This is particularly useful when you want to play together with an acoustic instrument like a guitar or piano, that may not be tuned to standard pitch.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("BEND lets you adjust how much the pitch of the notes changes as you move your fingers from left to right (or from right to left of course) while holding down keys. A setting of 0 means no pitch bend, this is the easiest to play and ensures that your notes are always perfectly in tune.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("Settings between 100 and 250 will allow you to bend the notes in a reasonably controlled manner, giving you access to all the 'notes in between the notes'. This will let you play guitar solo-like note bends and - with some practice and depending on the sound you've selected - you can even play full chromatic scales on the keyboard. It does require more careful playing though, as you'll need to avoid unintentional finger motion.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("Higher settings of 500 to 750 will allow for very wide pitch slides, great for theremin-like sounds and special effects, but difficult to control. Some of the presets have this pitch bending 'built in' and these also feature sounds that are particularly suited for it. Tip: when using note bending, make sure the keys are displayed with enough size to give you maximum control over the effect - try folding the option view to increase the key size, or if you're using an iPad, try switching to landscape orientation.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("* * * * * * *")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
        
        Text("Use the buttons below to turn to the next section and read on about musical scales and tunings, or close this guide and use what you've learned here to make some music.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
    }
    

    
    
    @ViewBuilder
    private func backgroundContent(scrollProxy: ScrollViewProxy) -> some View {
        Text("III: BACKGROUND")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 24)
            .padding(.top, 10)
            .centeredText()
        
        Text("In this section, you can learn about the musical concepts behind the Arithmophone Diatone. Scroll down to read on or click one of the subsection names below to jump there directly. Double tap any of the images in this section to zoom in or out.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 20)
        
        
        Text(underlinedText("III A: What is a diatonic scale?"))
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
            .onTapGesture {
                withAnimation {
                    scrollProxy.scrollTo("diatonicScale", anchor: .top)
                }
            }
        
        Text(underlinedText("III B: What is just intonation?"))
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
            .onTapGesture {
                withAnimation {
                    scrollProxy.scrollTo("justIntonation", anchor: .top)
                }
            }
        
        Text(underlinedText("III C: What is equal temperament?"))
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
            .onTapGesture {
                withAnimation {
                    scrollProxy.scrollTo("equalTemperament", anchor: .top)
                }
            }

        Text(underlinedText("III D: Scales and modes"))
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
            .onTapGesture {
                withAnimation {
                    scrollProxy.scrollTo("modes", anchor: .top)
                }
            }
        
        Text(underlinedText("III E: The Diatone scale selection"))
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
            .onTapGesture {
                withAnimation {
                    scrollProxy.scrollTo("scaleSelection", anchor: .top)
                }
            }
        
        Text(underlinedText("III F: Diatone scale diagrams"))
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
            .onTapGesture {
                withAnimation {
                    scrollProxy.scrollTo("scaleDiagrams", anchor: .top)
                }
            }
        
        
        Text("* * * * * * *")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .padding(.top, 10)
            .centeredText()
            .padding(.bottom, 20)
        
        Text("What is a diatonic scale?")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
            .id("diatonicScale")
        
        Text("Historically, the term diatonic refers to a particular family of musical scales with 7 notes per octave, that are built out of whole steps (tones) and half steps (semitones) in such a way that the steps are distributed across the octave as evenly as possible.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)

        Text("Informally, the term 'diatonic' is also used to describe any musical scale with 7 notes per octave. This contrasts it with, for example, pentatonic scales (which have only 5 notes per octave) and with the chromatic scale (which contains all of the available notes in 12 tone equal temperament).")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Any whole step / half step note system divides the octave into 12 semitones, so you can think of the process of making a diatonic scale as picking 7 out of 12 notes. If you have ever played a piano-style keyboard, you may have noticed that there are 7 white keys and 5 black keys for each octave. This is no coincidence. The piano keyboard is essentially a diatonic design, with its 'natural' notes being the white keys. The black keys fill the gaps between the notes that are a whole tone apart, and because there are only five such gaps, there are only five black keys. Some of the white keys (B and C, E and F) are just a semitone apart, and these don't have a black key in between them.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("On the piano, the white keys are called A, B, C, D, E, F and G. The black keys don't get their own letter, instead they are 'raised' or 'lowered' versions of the natural notes, that are called things like E♭ (E flat - the lowered version of E, which is the black key in between D and E) or C♯ (C sharp - the raised version of C, which is the black key in between C and D). Depending on context, the black keys may take different names. For example, the black key in between G and A my be called G♯ if it takes the place of G in a scale, or A♭ if it takes the place of A.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Any 'proper' diatonic scale will always include one note for each letter, A through G. If you play all the consecutive piano keys starting from A up to E♭, you'd have seven notes — but you'd have two versions of the B note (B♭ and B), two versions of the C note (C and C♯), and no F or G note at all. While this is technically a 7 note scale, it's not a very musically useful one, because the notes are all clustered together in one half of the octave. On the other hand, as long as you make sure that your scale includes a note for each of the 7 letters, the notes will be more properly distributed and you're likely to produce a musical sounding scale, even if the sequence is something complicated like A, Bb, C#, D, Eb, F#, G.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The keyboard of the Arithmophone only has seven notes per octave, so it works a little differently from a piano. You don't have 12 notes at your fingertips at all times, but instead you choose which notes you want to map to the keyboard by selecting a key and scale. This is more similar to instruments like the harp or the harmonica, that are tuned to a specific scale - except that retuning to a different scale or key is instant and effortless on the Diatone.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("All common musical keys are available on the Diatone, from the central D (the natural center point because it is in the middle of the sequence a-b-c-D-e-f-g) all the way up to G# or down to Ab.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The scales that are available on the Diatone keyboard are divided into three groups: in the first group are the 7 modes of the strictly diatonic scale, labeled with their traditional Greek names, from Locrian to Lydian. In the second and third group are some melodic and harmonic scales that are not 'strictly' diatonic, but nonetheless satisfy the 'one of each note' requirement. All of these are scales that are commonly used across different musical traditions.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        
        
        
        
        
        
        Text("What is just intonation?")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
            .id("justIntonation")
        
        Text("Just intonation is a tuning system that is based on the natural harmonics of musical notes. It can be used on many musical instruments, as well as for singing, but how it works is most easily explained by using a stringed instrument like a violin as an example.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("When you play an open A string on a violin, the string vibrates at a rate of 440 times per second (assuming the violin is in standard tuning). This rate is called the frequency, and is usually expressed in Hertz (Hz). So the pitch of the tuned A string is 440 Hz, but the sound you hear is not just a single frequency, because the string also vibrates at multiples of its root frequency. These multiples of the root frequency are called harmonics or overtones. Together they combine with the root frequency to produce a complex sound that gives the instrument its own particular tone colour or timbre.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("On an instrument where you can touch the strings directly, like a violin or a guitar, it is very easy to check this for yourself. If you lightly touch the string at exactly half the length of the string (on a fretted instrument like a guitar, this is just over the 12th fret), you will mute the root frequency and accentuate the second harmonic. This uses half the length of the string, and sounds at twice the frequency (880 Hz). If you place your finger at one third of the length (or over the 7th fret), you will hear the third harmonic accentuated (three times the root frequency), et cetera. If you then just play the open string again, you will probably be able to hear how the full sound of the vibrating string contains all of these individual harmonics within itself.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("If we listen to the harmonics in isolation, we can hear that they correspond to different notes. The second harmonic of the A string produces another A, an octave higher, the third harmonic produces an E, the fourth harmonic is an A again, 2 octaves higher this time, and the fifth harmonic produces a C#.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Each of the harmonics of a note stands in a certain ratio to its root frequency, and each of those ratios corresponds to a certain note. We can use this fact to tune the other strings of the violin (or on any stringed instrument in general) in relation to one specific root frequency, and this is in fact precisely what just intonation means. When we sound the third harmonic of the A string, which produces the note E, and then tune our E string so that it resonates perfectly with the harmonic, we are using just intonation, plain and simple.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("We can use the principle of harmonic proportions to find a ratio for any note we might want to tune to. We have just established that for the note A, the ratios 2:1 and 4:1 just give us more A notes, in higher octaves. And in general, multiplying or dividing by 2 will give us the same note in a different octave. But all the odd ratios provide us with new notes: if 1:1 is A, then 3:1 is E, and 5:1 is C#. But we can go the other way as well: 1:3 is D (because 3:1 on D is A) and 1:5 is F (because 5:1 on F is A). We can also combine ratios: 5:3 is F#, because 1:3 is D and 5:1 on D is F# (and 5:1 x 1:3 is 5:3).")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        
        
        Text("Any multiple of the root frequency produces a new harmonic and in principle this goes on forever, but the relative loudness of the harmonics decreases as their frequency increases, so in practice the first few harmonics are much more prominent than the higher ones. Simply by combining factors of 2, 3 and 5, we can create all of the diatonic scales that are featured in this app. For example, the ratios and notes of a D major scale might be: 1/1 (D), 9/8 (E), 5/4 (F#), 4/3 (G), 3/2 (A), 5/3 (B), 15/8 (C#), 2/1 (D).")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("To avoid confusion, we should pay careful attention to the distinction between scale position and harmonic position. For example, in the C major scale, E is the third note and for this reason, the interval from C to E is usually called a (major) third. But E is the fifth harmonic of C. In contrast, G is the fifth note of the scale and usually called a (perfect) fifth, even though G is the third harmonic of C. This is potentially very confusing, but the scale position terminology is quite useful in itself for describing diatonic note relations, and it is so deeply ingrained in music theory and education that it can hardly be avoided, so it is just something that we will need to stay aware of.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The diagram below shows some of the most commonly used just intonation ratios, arranged in a so called '3-5 grid': you start with a fundamental note (the ratio 1/1) and then build other notes by multiplying or dividing. Moving left multiplies by 3 (going up a perfect fifth), while moving up multiplies by 5 (going up a major third). You can also divide to go in the opposite direction. With just two harmonic building blocks, this creates a complete lattice of musical notes, all related to each other through simple ratios. To bring the notes within the same octave, simply multiply or divide their ratios by 2 as needed.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        ZoomableDownsampledImageView(imageName: "Guide JI grid", maxHeight: 200)
            .padding(.vertical, 5)
        
        Text("If we now colour these notes with the colour scheme that is used for the keyboard of this app, the result will look like this:")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        ZoomableDownsampledImageView(imageName: "Guide JI ratios", maxHeight: 200)
            .padding(.vertical, 5)
        
        Text("And if we replace the ratios with note names, using D for 1/1, it looks like this:")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        ZoomableDownsampledImageView(imageName: "Guide JI note names", maxHeight: 200)
            .padding(.vertical, 5)
        
        Text("The scale display in the app shows which of these notes/ratios are used in any particular scale. At the end of this guide, some diagrams are included that show the images for each of the 12 available scales, with ratios and note names inscribed.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("An important characteristic of just intonation is that there are multiple options for each note (except for the root, which is always 1:1). For example, with root D, there is a C at 1:9 (because 1:3 on D is G and 1:3 on G is C - and 1/3 x 1/3 is 1/9), but there is also a C at 9:5 (because 3:1 on D is A, 3:1 on A is E and 1:5 on E is C - and 3/1 x 3/1 x 1/5 = 9/5) These notes share the same name, but they don't have the same frequency - because 9/5 is not equal to 1/9, not even when we change the latter to 16/9 so they fall within the same octave.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The distance between these two notes is small enough that tempered tunings can 'sweep it under the rug' and represent both ratios with just a single note, but it is definitely audible, and becomes particularly apparent when multiple notes are played simultaneously in chords. And these are just two of the options for the C note on D: there are other, more 'microtonal' candidates for the C note, most notably the 'pure harmonic seventh' or 7/1 ratio, and there are multiple options for all other notes as well. With just intonation, there are essentially infinitely many different tonal colours.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        
        
        
    
        
        Text("What is equal temperament?")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
            .id("equalTemperament")
        

        
        Text("The infinite possibilities of just intonation can be a wonderful thing, but it has its downsides too. One situation where it is clearly not desirable to have infinitely many different notes, is when you're trying to build a fixed pitch instrument like a piano or a guitar, that only has a limited number of notes/strings/frets available. With just intonation, you can tune a piano so that it sounds great in the key of C, but then if you'd want to play something in the key of D flat, you will find that it is quite badly out of tune. This can only be resolved by retuning the entire instrument - but in that case it will no longer be in tune in the key of C.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("As classical music evolved in Western Europe, keyboard instruments like organs and harpsichords became more prominent, and modulation between different keys became an important part of the musical style. This motivated instrument makers and music theorists to explore alternatives to just intonation tuning, and this finally led to the introduction of 12 tone equal temperament, which has since become the standard tuning system for Western musical instruments, from guitars and pianos to saxophones and synthesizers.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("In an equal temperament tuning, the octave is divided into a number of steps of exactly the same size. If that number is 12, then we get a selection of notes that provides a pretty good approximation of the first 5 harmonics from whichever note we choose to select as the root. In fact, the third harmonic is nearly perfect, although the fifth harmonic is not quite as good (the second and fourth harmonic are octaves, and they are perfect by definition, because it is the octave that is being divided).")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("As we have seen in the section on just intonation, we can find all the notes of Western diatonic music just by combining the third and fifth harmonic, so all of these are available in 12 tone equal temperament. All of the notes are now slightly out of tune with respect to each other, but none of them terribly much so. This means we can now play in any key we like without having to worry about retuning our instruments.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Furthermore, we now have only 12 different notes to deal with in total. This is why the scale display in this app shows different images for equal temperament scales, one like the illustration below. This full image does show 13 notes in total, but The G# and Ab are really just the same note, that is shown either on the far left or on the far right of the display depending on the context of the scale.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        ZoomableDownsampledImageView(imageName: "Guide ET note names", maxHeight: 200)
            .padding(.vertical, 5)
        
        Text("With 12 tone equal temperament, what we lose in tuning accuracy, we gain in flexibility. Whether or not this is a good tradeoff really depends on the musical context. Listen to a piano piece by a composer like Claude Debussy and you can hear the full power of 12 tone equal temperament: that kind of harmonic motion and musical flexibility is hardly imaginable with just intonation tuning. But listen to a kora piece by one of the great players of this instrument like Toumani Diabaté, and you can hear the rich harmonic resonance of just intonation that is impossible to achieve on an instrument tuned to equal temperament.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Both of these are the result of wonderfully rich musical traditions. The Arithmophone Diatone lets you get a taste of each approach. If you want to use it to play along with other instruments, then make sure you use the proper tuning system. For typical Western instruments like a guitar or a keyboard, this will be equal temperament, but many instruments from other musical traditions, like the Indian sitar or the Arabic oud, are commonly tuned with just intonation intervals. If you are playing by yourself then it may be worth experimenting a bit to see if you can hear the different feeling each tuning system imparts on your playing. Don't be discouraged if you don't immediately hear the difference: it's subtle and more prominent on some note combinations than on others, but it's definitely there.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("It should be noted that there are also some very rich musical traditions that can be represented neither by 12 tone equal temperament nor by '3-5 grid' harmonic ratios. A great example of this is the Arabic Maqam system. This requires either more complex musical ratios that incorporate higher harmonics like the 7th and 11th harmonic, or larger temperaments like 24 tone or even 53 tone equal temperament. Unfortunately, this takes it outside of the current scope of this app, but to be aware of this is a great reminder of the infinite subtleties and complexities of music.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)

        

        
        
        
        
        
        
        
        Text("Scales and modes")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
            .id("modes")
        
        Text("The terms 'scale' and 'mode' are closely related but describe slightly different concepts. You can think of it like this: a scale is a collection of notes arranged from lowest to highest, while a mode is a collection of notes arranged around a specific center. In practice, their meanings overlap and the terms are often used interchangeably, but they are not identical. If we take the selection of notes 'A, B, C, D, E, F, G' and use C as our tonal center, then we are in the Ionian mode, regardless of the order of the notes. If we now play these notes starting from C and up to the next C (C, D, E, F, G, A, B and C again), we are playing a C major scale, sometimes also called the C Ionian scale. In both cases, we use the same set of notes, but in the one case the emphasis is on the order in which we play the notes, while in the other case the emphasis is on the note we attach the most weight to in our playing.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The seven diatonic modes - Locrian, Phrygian, Aeolian, Dorian, Mixolydian, Ionian and Lydian - have names that come from ancient Greek music theory, but their current forms originated in medieval European liturgical music. Because of this historical connection to church music, they are also sometimes called 'church modes' or 'church scales'. Each of these modes has its own distinct character, mood or atmosphere.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Using only the white keys on a piano, you can play all seven modes simply by putting a different note at the center. If you play around C, you get the Ionian mode (the familiar major scale). If you play around D, you get Dorian. Taking E as the center gives you the Phrygian mode, and so on. These seven modes all contain exactly the same notes - just the white keys - but each mode takes a different note as its center point, and this is what creates its specific character.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        ZoomableDownsampledImageView(imageName: "Guide modes natural", maxHeight: 800)
            .padding(.vertical, 5)
        
        Text("The diagram above shows all seven modes using only the natural notes (the white keys on a piano). This represents one way to understand how the modes relate to each other: same notes, different roots.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("However, all of the seven modes can also be played in any other key, using a combination of natural notes and accidentals (raised/lowered notes) to maintain their characteristic pattern of whole steps and half steps.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        ZoomableDownsampledImageView(imageName: "Guide modes D", maxHeight: 800)
            .padding(.vertical, 5)
        
        Text("The diagram above shows all seven modes in the key of D. This is the complementary way to understand modes: same root, different notes.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("On the Arithmophone Diatone, you can explore all seven modes by selecting them from the 'modal' scale group, and you can play each one in any key you choose. This makes it easy to experiment with the unique flavour of each mode.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        
        
        
        
        
        Text("The Diatone scale selection")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
            .id("scaleSelection")
        
        Text("The seven modal scales, which were discussed in the previous paragraphs, are in a way all just different rotations of the same scale. Apart from these, this app includes two 'melodic' and three 'harmonic' scales, that have a different internal structure. Each of these can even be said to have its own set of modes. Although these are not presented as separate options in this app, they are still available by selecting a scale and using different notes as center.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Melodic scales are scales that contain only wholetone and halftone steps. In fact, the 'modal' scale(s) can be considered a special case of this category. As far as the other included melodic scales are concerned: the minor melodic scale is often used in jazz music and its modes include things like the lydo-mixolydian and altered scales. The major melodic scale is in fact another mode of this same scalar pattern.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Harmonic scales are scales that contain at least one augmented whole tone, meaning they have at least one gap of three semitones between consecutive notes. This means that the notes in these scales are less evenly distributed than the notes in melodic scales, which gives them a particular effect that is hard to describe but easy to hear. The minor harmonic scale is often (but not only) used in Western Classical music, because it matches the common harmonic progression of a dominant chord to a minor root. The major harmonic scale is also called the 'molldur' scale sometimes, and it has a particularly bittersweet quality to it, combining the major root with the minor subdominant. The double harmonic scale has not just one but two large gaps of three semitones. This is scale is commonly, and highly effectively, used in Balkan and Klezmer music.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("It should be emphasized that, for the modal scales in particular, there is an important difference between the equal temperament and just intonation scale selections. Whereas in equal temperament there is a lot of overlap in these scales (for example, C Ionian and D Dorian contain exactly the same notes), in just intonation there are many subtle differences. For example, there is not just one single 'Mixolydian' scale in just intonation: there are many different combinations of ratios that will produce that particular combination of notes. In this app, there are 5 different 'shapes' of just intonation modal scales, and each shape determines which combination of chords is perfectly tuned within that scale. Different shapes work best with different chord progressions, so experimentation is highly recommended.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
    /*
        Text("For reference, a list is included below which shows for  which triads are perfectly tuned for each of the available just intonation scales, expressed in scale degrees with chord names in the key of D as examples.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
   
   
     Text("Locrian: ♭II major, IV minor, ♭V major, ♭VI major and ♭VII minor")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("In the key of D: E♭, Gm, A♭, B♭, Cm")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 15)
        
        Text("Phrygian: I minor, ♭II major, IV minor, ♭VI major and ♭VII minor")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("In the key of D: Dm, E♭, Gm, B♭, Cm")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 15)
        
        Text("Aeolian: I minor, IV minor, ♭VI major and ♭VII major")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("In the key of D: Dm, Gm, B♭, C")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 15)

        
        Text("Dorian: I minor, II minor, ♭III major and IV major")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("In the key of D: Dm, Em, Fm, G")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 15)

        
        Text("Mixolydian: I major, IV major, V minor and VI minor")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("In the key of D: D, G, Am, Bm")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 15)

        
        Text("Ionian: I major, III minor, IV major, V major and VI minor")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("In the key of D: D, Em, G, A, Bm")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 15)

        
        Text("Lydian: I major, III minor, V major, VI minor and VII minor")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("In the key of D: D, F♯m, A, Bm, C♯m")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 15)

        Text("Minor Melodic: I minor and V major")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("In the key of D: Dm, A")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 15)

        
        Text("Major Melodic: I major and IV minor")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("In the key of D: D, Gm")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 15)

        
        Text("Minor Harmonic: I minor, IV minor, V major and ♭VI major")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("In the key of D: Dm, Gm, A, B♭")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 15)

        
       Text("Double Harmonic: I major, ♭II major, III minor and IV minor (in the key of D: D, E♭, F♯m, Gm)")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 15)

        
        Text("Major Harmonic: I major, III minor, IV minor and V major (in the key of D: D, F♯m, Gm, A)")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 15)

  */
        
        Text("Diatone scale diagrams")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
            .id("scaleDiagrams")
        
        Text("The diagrams below show all of the available scales in the Arithmophone Diatone app. The first diagram shows all the scales in equal temperament, the second diagram shows the just intonation scales with ratios inscribed, while the last diagram shows those same scales with note names inscribed instead.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 20)
        
        Text("EQUAL TEMPERAMENT SCALES WITH NOTE NAMES")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.top, 20)
        ZoomableDownsampledImageView(imageName: "Guide ET scales", maxHeight: 800)
            .padding(.vertical, 5)
 
        Text("JUST INTONATION SCALES WITH RATIOS")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.top, 20)
        ZoomableDownsampledImageView(imageName: "Guide JI scales ratios", maxHeight: 800)
            .padding(.vertical, 5)
        
        Text("JUST INTONATION SCALES WITH NOTE NAMES")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.top, 20)
        ZoomableDownsampledImageView(imageName: "Guide JI scales notes", maxHeight: 800)
            .padding(.vertical, 5)
        
        
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

// MARK: - PDF Rendering Helper

/// Maximum pixels per rendered image (~48 MB in RGBA).
private let maxPixelsPerImage: CGFloat = 12_000_000

/// Renders a PDF from the app bundle at the requested pixel width.
/// Uses CGPDFDocument so the vector is rasterized directly at the target size.
/// If the total pixel count would exceed the budget, the image is scaled down.
private func renderPDFImage(named name: String, targetPixelWidth: CGFloat) -> UIImage? {
    guard let url = Bundle.main.url(forResource: name, withExtension: "pdf"),
          let document = CGPDFDocument(url as CFURL),
          let page = document.page(at: 1) else {
        return nil
    }
    
    let mediaBox = page.getBoxRect(.mediaBox)
    guard mediaBox.width > 0 else { return nil }
    
    var pxScale = targetPixelWidth / mediaBox.width
    let candidateW = mediaBox.width * pxScale
    let candidateH = mediaBox.height * pxScale
    if candidateW * candidateH > maxPixelsPerImage {
        pxScale *= sqrt(maxPixelsPerImage / (candidateW * candidateH))
    }
    
    let targetWidth = ceil(mediaBox.width * pxScale)
    let targetHeight = ceil(mediaBox.height * pxScale)
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: Int(targetWidth),
        height: Int(targetHeight),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }
    
    context.scaleBy(x: pxScale, y: pxScale)
    context.drawPDFPage(page)
    
    guard let cgImage = context.makeImage() else { return nil }
    return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
}

// MARK: - Zoomable Guide Image View
/// Renders the PDF at 3x display resolution so the image stays crisp up to 3x zoom.
/// Tap toggles between 1x and 2x, pinch zooms up to 3x.
struct ZoomableDownsampledImageView: View {
    let imageName: String
    let maxHeight: CGFloat
    
    private let maxZoom: CGFloat = 3.0
    private let tapZoom: CGFloat = 2.0
    
    @State private var renderedImage: UIImage?
    @State private var renderedForWidth: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            Group {
                if let image = renderedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1.0), maxZoom)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale < 1.0 {
                                        withAnimation(.spring()) {
                                            scale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            scale > 1.0 ?
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                            : nil
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = tapZoom
                                }
                            }
                        }
                } else {
                    Color.clear
                        .frame(width: geo.size.width)
                }
            }
            .onAppear { renderIfNeeded(width: geo.size.width) }
            .onChange(of: geo.size.width) { newWidth in
                renderIfNeeded(width: newWidth)
            }
        }
        .aspectRatio(guideImageAspectRatios[imageName] ?? 1.0, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .zIndex(scale > 1.0 ? 999 : 0)
    }
    
    private func renderIfNeeded(width: CGFloat) {
        guard width > 0, renderedImage == nil || abs(width - renderedForWidth) > 10 else { return }
        renderedForWidth = width
        // Render at maxZoom × display pixels so the image is crisp at full zoom
        let targetPixelWidth = width * UIScreen.main.scale * maxZoom
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = renderPDFImage(named: imageName, targetPixelWidth: targetPixelWidth) {
                DispatchQueue.main.async {
                    self.renderedImage = image
                }
            }
        }
    }
}

/// Pre-defined aspect ratios for Guide PDF images.
private let guideImageAspectRatios: [String: CGFloat] = [
    // Landscape: 1125 x 625 pt
    "Guide JI grid":       1125.0 / 625.0,
    "Guide JI ratios":     1125.0 / 625.0,
    "Guide JI note names": 1125.0 / 625.0,
    "Guide ET note names": 1125.0 / 625.0,
    // Square: 1490 x 1490 pt
    "Guide modes natural": 1.0,
    "Guide modes D":       1.0,
    // Tall portrait: 950 x 2225 pt
    "Guide JI scales ratios": 950.0 / 2225.0,
    "Guide JI scales notes":  950.0 / 2225.0,
    "Guide ET scales":        950.0 / 2225.0,
]

#Preview {
    ManualView(
        showingOptions: .constant(true)
    )
}
