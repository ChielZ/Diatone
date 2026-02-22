//
//  V5 ManualView.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 10/01/2026.
//

import SwiftUI

// MARK: - Image Downsampling Helper

/// Loads and downsamples an image from assets to prevent excessive memory usage.
/// This is critical for large vector PDFs that would otherwise be rasterized at full resolution.
private func downsampledImage(named: String, targetHeight: CGFloat) -> UIImage? {
    guard let image = UIImage(named: named) else { return nil }
    
    // Calculate the scale to fit the target height
    let scale = targetHeight / image.size.height
    let targetSize = CGSize(
        width: image.size.width * scale,
        height: targetHeight
    )
    
    // Use a graphics renderer to create a downsampled version
    let format = UIGraphicsImageRendererFormat()
    format.scale = UIScreen.main.scale // Maintain screen resolution quality
    format.opaque = false
    
    let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
    let downsampled = renderer.image { context in
        image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
    
    return downsampled
}

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
                        scrollToTopTrigger += 1
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
                        scrollToTopTrigger += 1
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
                                ScrollView {
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
        
        Text("Welcome to the Arithmophone Diatone! This guide explains all the functions of the app, and also includes background sections on musical scales and tunings")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("WHAT IS AN ARITHMOPHONE?")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 20)
            .centeredText()
        
        Text("An Arithmophone is a thing that turns numbers into sounds, or math into music. Its name is derived from the ancient Greek words ἀριθμός (arithmos; number) and φωνή (phone; sound). The device you're holding in your hands right now is itself an Arithmophone, in the sense that it routinely turns long strings of binary numbers into sounds. But this app is a bit more 'arithmophonic' still, because it uses pure and simple harmonic ratios like 3/2 and 5/4 to produce musical notes.")
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
        
        Text("Diatone's music keyboard is purpose-built for the form factor of handheld touchscreen devices. It turns your iPhone or iPad into an instrument with exactly the right ergonomics for playing music. Rather than emulating a piano or a guitar fretboard (which are both very well designed interfaces, but with a very different form factor), the Diatone features an original design that takes inspiration from traditional African instruments like the Kora and the Mbira (also known as Kalimba or Karimba), on which melodies are played by alternating between the left and right hand.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("Diatone features a keyboard with 22 keys, 11 on each side of the screen, which can be played very comfortably with both thumbs while holding your iPhone or iPad in your hands. If you rest your device on your lap or some other suitable surface, you can also use your other fingers to play chords and arpeggios as well. To play the notes in scale order, start with the lowest key on the left, then play the lowest key on the right, then the second key on the left, and so on.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("The scales")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
        
        Text("The name Diatone comes from the Greek words διατονικός (diatonikos; diatonic), a term that has been used since ancient times to describe scales with 7 notes per octave. The familiar 'do re mi fa sol la ti do' is such a scale, but there are many others as well. The Arithmophone Diatone has 12 different scales to choose from, and each of these can be played in any musical key and in two different tuning modes: just intonation (rational harmonic intervals, where the notes sound perfectly in tune with each other) or equal temperament (standard Western tuning, suitable for playing along with guitars, pianos et cetera).")
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
        
        Text("Each of the preset sounds can be changed by adjusting the 'volume', 'tone' and 'ambience' sliders, and the keyboard's response can be customised further on the 'setup' page. Diatone's sound engine uses a combination of Frequency Modulation and substractive synthesis. It is inspired by some classic digital synthesizers and keyboards from the 1980s, but it also adds a few more modern twists like binaural stereo imaging and effects.")
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
        
        Text("This section will guide you through using all the features of the Arithmophone Diatone. Scroll down to read on or click on one of the subsection names below to jump there directly.")
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
        
        Text(underlinedText("II C: The sound View"))
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
        
        Text("When you first open the Arithmophone Diatone app, you will see the keyboard, divided into a right and a left section divided by a small vertical bar. The left and right sections combine to form one keyboard together: to play a scale, alternate between playing the left and right keys as you move up or down the keyboard. The keyboard responds to both initial touch and aftertouch: try hitting the keys on different places and moving your finger around while you hold down a key to hear the effect this has on the sound.")
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
        
        Text("The scale view lets you switch between different scales, keys and and tunings. At the top of the view (just below the main page selector) there is an image that represents the currently selected scale and tuning. What these images mean exactly is explained at the end of section III of this guide, but mainly this just serves as a quick visual indication of the active scale. Beneath this are 5 options for changing the the notes of the keyboard:")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Tuning: here you can switch between just intonation and equal temperament tuning. Just intonation uses rational harmonic intervals, where the notes sound perfectly in tune with each other, while equal temperament is the standard tuning of Western musical instruments like guitars and pianos. Both of these tuning modes have their own distinct character. The differences are fairly subtle but in general, with just intonation some note combinations sound perfect together while other combinations sound quite out of tune, whereas in equal temperament, no note combinations are perfect, but all combinations are quite acceptable. If you'd like to learn more about this, please read the background information in section III of this guide, but you don't need to worry about this if you don't want to. In general, you can simply leave this on 'just' when you're playing by yourself, or switch to 'equal' when you're playing together with other instruments.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Key: this lets you select the musical key that the keyboard is in: changing this transposes the entire keyboard up or down. In combination with the scale selection, this determines which musical note is mapped to each of the keys.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Scale: this lets you select which musical scale is mapped to the keyboard. Each scale has its own selection of 7 notes and provides its own unique mood. There is more detailed information about the available scales in section III of this guide. To get started without delving in to all of that, just try out the Ionian mode for typical 'major' melodies, the Aeolian mode for typical 'minor' melodies, or the double harmonic scale for a more exotic flavour.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Scale group: the 12 available scales are arranged in 3 groups: modal, melodic and harmonic. The modal scales will probably sound most familiar to most users, as they are essentially all permutations of the familiar 'do re mi fa sol la ti do' scale. The melodic and harmonic scales offer a few more 'spicy' alternatives: melodic scales are often used in jazz while harmonic scales are common in Eastern European and Arabic music.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Rotation: this keeps the mapping from scale note to key colour intact, but shifts the screen keyboard up or down by up to 3 steps. This gives you control over the lowest and highest notes available for playing.")
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
        
        Text("Below the preset selection buttons there are three sliders that let you adjust the sound to your liking. These are automatically reset to their default (centered) positions when a new preset is selected. The 'Volume' slider simply makes the sound softer or louder. Tip: set the volume to the desired level with the main volume controls of your device while the Diatone's volume slider is in its center position, then use the slider for quick 'on the fly' adjustments or expressive control.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The 'Tone' slider affects different preset sounds in different ways, but it will generally make the sound brighter as you move to the slider to the right, and sometimes also a bit louder and/or more overdriven.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The 'Ambience' slider also has a different effect depending on the selected preset, but it generally provides a more spacious sound when moved to the right and a drier, more direct sound when moved to the left.")
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
        
        Text("The setup view lets you adjust some further settings that determine how Diatone sounds and how the keyboard responds to your playing. Like the sliders in the sound view, these are also reset when a new preset is loaded.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("The tempo control lets you adjust the rate of synchronized modulations and delays, this is particularly useful when you want to play along with existing songs or with other synthesizers/sequencers.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("The octave control transposes the keyboard up or down in full octaves and lets you adjust for bass, chord or lead playing.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("The tune control allows you to fine tune the keyboard in steps of 1 cent (a cent is 1/100 of an equal temperament semitone). This is particularly useful when you want to play together with an acoustic instrument like a guitar or piano, that may not be tuned to standard pitch.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        
        Text("Finally, the bend control lets you adjust how much the pitch of the notes change as you move your fingers from left to right (or from right to left of course) while holding down keys. A setting of 0 means no pitch bend, this is the easiest to play and ensures that your notes are always perfectly in tune. Settings between 100 and 250 will allow you to bend the notes in a reasonably controlled manner, giving you access to all the 'notes in between the notes'. This will let you play guitar solo-like note bends and - with some practice and depending on the sound you've selected - you can even play full chromatic scales on the keyboard. It does require more careful playing though, as you'll need to avoid unintentional finger motion. Higher settings of 500 to 750 will allow for very wide pitch slides, great for theremin-like sounds and special effects, but difficult to control. Some of the presets have this pitch bending 'built in' and these also feature sounds that are particularly suited for it. Tip: when trying this out, make sure the keys are displayed with enough size to give you maximum control over the effect - so try folding the option view to increase the key size, or if you're using an iPad, switch to landscape orientation.")
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
        
        Text("In this section, you can learn about the musical concepts behind the Arithmophone Diatone. Scroll down to read on or click on one of the subsection names below to jump there directly.")
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
        
        Text("A whole step / half step note system divides the octave in to 12 steps, so you can think of the process of making a diatonic scale as picking 7 out of 12 notes. If you have ever played a piano-style keyboard, you may have noticed that there are 7 white keys and 5 black keys for each octave. This is no coincidence. The piano keyboard is essentially a diatonic design, with its 'natural' notes being the white keys. The black keys 'fill the gaps' between the notes that are a whole tone apart, and because there are only five such gaps, there are only five black keys. Some of the white keys (B and C, E and F) are just a semitone apart, and these don't have a black key in between them.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("On the piano, the white keys are called A, B, C, D, E, F and G. The black keys don't get their own letter, instead they are 'raised' or 'lowered' versions of the natural notes, that are called things like Eb ('E flat' - the lowered version of E, which is the black key in between D and E) or C# ('C sharp' - the raised version of C, which is the black key in between C and D).")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("What all musically useful 7 note scales have in common, is that they have 'one of each note'. Playing all the white keys on a piano creates a scale with 7 different letters, which works perfectly, but if you were to start on the note A and then play every next note up until you reached the seventh, you would get a sequence like this: A, Bb, B, C, C#, D, Eb. While this is a 7 note scale in some sense, it isn't a very musically useful scale, and this is because it doesn't have 'one of each note'. Instead, there are two versions of 'B' and two version of 'C', while the letters F and G are missing from the scale altogether. On the other hand, as long as you make sure that your scale includes a note for each of the 7 letters, you're very likely to produce a musical sounding scale, even if the sequence is something complicated like A, Bb, C#, D, Eb, F#, G.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The keyboard of the Arithmophone only has seven notes per octave, so it works a little different than a piano. You don't have 12 notes at your fingertips at all times, but you choose which notes you want to map to the keyboard by selecting a key and scale instead. This is more similar to instruments like the harp or the harmonica, that are tuned to a specific scale - except that retuning to a different scale or key is instant and effortless on the Diatone.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("All common musical keys are available on the Diatone, from the central D (the natural center point because it is in the middle of the sequence a-b-c-D-e-f-g) all the way up to G# or down to Ab.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The scales that are available on the Diatone keyboard are divided in to three groups: in the first group are the 7 modes of the strictly diatonic scales, labeled with their traditional names from Locrian to Lydian. In the second and third group are some melodic and harmonic scales that are not 'strictly' diatonic, but nonetheless satisfy the 'one of each note' requirement. All of these are scales that are commonly used across different musical traditions.")
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
        
        Text("Just intonation is a tuning system where musical intervals are based on simple whole number ratios. For example, when you play two notes an octave apart, the higher note vibrates exactly twice as fast as the lower note - a ratio of 2/1. A perfect fifth uses a ratio of 3/2, and a major third uses 5/4. These simple mathematical relationships create harmonies that sound pure and perfectly in tune, because the sound waves align with each other in very natural ways.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The name 'just intonation' comes from the idea that these intervals are 'just right' - they are the tuning that produces the most consonant, beatless harmonies possible. When you hear two notes played in just intonation forming a simple ratio like 3/2 or 5/4, there is a special quality to the sound: it locks together perfectly, without the subtle wavering or 'beating' that you get with other tuning systems.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        DownsampledImageView(imageName: "Guide JI grid", maxHeight: 200)
            .padding(.vertical, 5)
        
        Text("The diagram above shows how just intonation works: you start with a fundamental note (the ratio 1/1) and then build other notes by multiplying or dividing by simple numbers. Moving horizontally multiplies by 3 (going up a perfect fifth), while moving vertically multiplies by 5 (going up a major third). You can also divide to go in the opposite direction. To keep all the notes within a single octave, you multiply or divide by 2 as needed. This creates a lattice of musical notes, all related to each other through pure harmonic ratios.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        DownsampledImageView(imageName: "Guide JI ratios", maxHeight: 200)
            .padding(.vertical, 5)
        
        Text("Just intonation has one significant limitation: because the intervals are defined by their relationship to a root note, some note combinations work perfectly while others don't. If you change the root note or modulate to a different key, the ratios change and some intervals that were pure may no longer be. This is why just intonation works beautifully for music that stays centered around one key, but can be challenging for music that moves between different keys frequently.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        DownsampledImageView(imageName: "Guide JI note names", maxHeight: 200)
            .padding(.vertical, 5)
        
        Text("On the Arithmophone Diatone, each of the 12 available scales has its own carefully chosen set of just intonation ratios, optimized to make the most important harmonies in that particular scale sound as pure as possible. This means you get the benefits of perfect tuning without having to think about the mathematics behind it - just select 'just' as your tuning mode and play.")
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
        
        Text("Equal temperament is the tuning system used by most Western musical instruments, including guitars, pianos and synthesizers. In this system, the octave is divided into 12 exactly equal steps called semitones. Each semitone has the same size: it multiplies the frequency by the twelfth root of 2, which is approximately 1.05946. This means that going up 12 semitones multiplies the frequency by exactly 2, giving you an octave.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The beauty of equal temperament is that every key sounds the same relative to itself. A major third in the key of C sounds exactly the same size as a major third in the key of F# or any other key. This makes it possible to freely modulate between different keys, transpose melodies up or down, and play with other instruments without running into tuning problems. This flexibility is why equal temperament became the standard tuning for Western music.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The trade-off is that equal temperament intervals are based on irrational numbers (roots and powers of 2) rather than simple ratios. This means that most intervals are slightly 'out of tune' compared to their just intonation equivalents. A major third in equal temperament is about 14 cents (14 hundredths of a semitone) sharper than the pure 5/4 ratio, and a perfect fifth is about 2 cents flatter than the pure 3/2 ratio. These differences are small enough that the intervals still sound good, but you can hear a subtle 'beating' or wavering quality that isn't present in pure just intonation intervals.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        DownsampledImageView(imageName: "Guide ET note names", maxHeight: 200)
            .padding(.vertical, 5)
        
        Text("For most musical purposes, equal temperament is an excellent compromise: the intervals are close enough to just intonation that they sound consonant and musical, while the consistent tuning across all keys provides the freedom to modulate and transpose without limitation. When you select 'equal' as the tuning mode on the Arithmophone Diatone, you'll get the standard equal temperament tuning that will match perfectly with other instruments and recorded music.")
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
        
        Text("The terms 'scale' and 'mode' are closely related but describe slightly different concepts. A scale is simply a collection of notes arranged in ascending order, while a mode is a scale with a particular starting note that serves as the tonal center or 'root'. The distinction becomes clear when you understand that the same collection of notes can create different modes depending on which note you treat as home.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("The seven diatonic modes - Locrian, Phrygian, Aeolian, Dorian, Mixolydian, Ionian and Lydian - have names that come from ancient Greek music theory, but their current forms originated in medieval European liturgical music. Because of this historical connection to church music, they are also sometimes called 'church modes' or 'church scales'. Each mode has its own distinctive character and emotional quality, which is why composers throughout history have used them to create different moods and atmospheres.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Using only the white keys on a piano, you can play all seven modes simply by starting on a different note each time. If you play from C to C, you get the Ionian mode (the familiar major scale). If you play from D to D, you get Dorian. From E to E gives you Phrygian, and so on. These seven modes all contain exactly the same notes - just the white keys - but each one sounds completely different because of which note serves as the root.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        ZoomableDownsampledImageView(imageName: "Modes Natural", maxHeight: 800)
            .padding(.vertical, 5)
        
        Text("The diagram above shows all seven modes using only the natural notes (the white keys on a piano). Notice how each mode starts on a different note, but they all share the same collection of pitches. This is one way to understand modes: same notes, different roots.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("However, modes become even more useful when you transpose them to different keys. You can play any of the seven modes starting from any note, not just the white keys. For example, you can play Dorian in the key of D, or in the key of G, or in any other key. When you do this, each mode requires its own unique combination of natural notes (white keys) and accidentals (black keys) to maintain its characteristic pattern of whole steps and half steps.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        ZoomableDownsampledImageView(imageName: "Modes D", maxHeight: 800)
            .padding(.vertical, 5)
        
        Text("The diagram above shows all seven modes in the key of D. Here, each mode starts on the same root note (D), but uses a different selection of pitches to create its characteristic sound. This is the complementary way to understand modes: same root, different notes. Both perspectives are useful: the first helps you see the relationship between modes, while the second is more practical for actually playing music in a specific key.")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("On the Arithmophone Diatone, you can explore all seven modal scales by selecting them from the 'modal' scale group, and you can play each one in any key you choose. This makes it easy to experiment with the unique flavor of each mode and discover which ones work best for the music you want to create.")
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
        
        Text("[Content to be added]")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
            .padding(.bottom, 10)
        
        Text("Diatone scale diagrams")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 20)
            .padding(.top, 10)
            .centeredText()
            .id("scaleDiagrams")
        
        Text("All JI scales ratios")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        ZoomableDownsampledImageView(imageName: "Guide JI scales ratios", maxHeight: 800)
            .padding(.vertical, 5)
        
        Text("All JI scales note names")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        ZoomableDownsampledImageView(imageName: "Guide JI scales notes", maxHeight: 800)
            .padding(.vertical, 5)
        
        Text("All ET scales note names")
            .foregroundColor(Color("HighlightColour"))
            .adaptiveFont("MontserratAlternates-Medium", size: 16)
            .centeredText()
        ZoomableDownsampledImageView(imageName: "Guide ET scales", maxHeight: 800)
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

// MARK: - Downsampled Image View (Non-Zoomable)
struct DownsampledImageView: View {
    let imageName: String
    let maxHeight: CGFloat
    
    var body: some View {
        // Target height accounts for screen scale for high quality on Retina displays
        let targetHeight = maxHeight * UIScreen.main.scale
        
        if let downsampledUIImage = downsampledImage(named: imageName, targetHeight: targetHeight) {
            Image(uiImage: downsampledUIImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        } else {
            // Fallback if downsampling fails
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Zoomable Downsampled Image View
struct ZoomableDownsampledImageView: View {
    let imageName: String
    let maxHeight: CGFloat
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var downsampledUIImage: UIImage?
    @State private var isVisible = false
    
    var body: some View {
        Group {
            if let image = downsampledUIImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale = min(max(scale * delta, 1.0), 5.0)
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
                        // Only enable drag gesture when zoomed in
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
                                scale = 2.0
                            }
                        }
                    }
            } else {
                // Loading placeholder
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: maxHeight)
            }
        }
        .onAppear {
            if !isVisible {
                isVisible = true
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        // Load image on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            // Use a moderate multiplier (1.5x instead of 3x) to balance quality and memory
            // This gives good quality when zoomed to 2x-3x while keeping memory reasonable
            let targetHeight = maxHeight * UIScreen.main.scale * 1.5
            
            if let image = downsampledImage(named: imageName, targetHeight: targetHeight) {
                DispatchQueue.main.async {
                    self.downsampledUIImage = image
                }
            }
        }
    }
}

#Preview {
    ManualView(
        showingOptions: .constant(true)
    )
}
