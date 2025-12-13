//
//  ContentView 2.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 02/12/2025.
//

import SwiftUI

private struct KeyButton: View {
    let colorName: String
    // Trigger closure should be audio-first and as immediate as possible.
    let trigger: () -> Void

    @State private var isDimmed = false
    @State private var hasFiredCurrentTouch = false

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Color(colorName))
            .opacity(isDimmed ? 0.5 : 1.0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !hasFiredCurrentTouch {
                            hasFiredCurrentTouch = true
                            trigger()
                            isDimmed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                                withAnimation(.easeOut(duration: 0.28)) {
                                    isDimmed = false
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        hasFiredCurrentTouch = false
                    }
            )
    }
}

struct KeyView: View {
    // Callbacks provided by the App to change scales
    var onPrevScale: (() -> Void)? = nil
    var onNextScale: (() -> Void)? = nil
    
    // Binding to control showing options
    @Binding var showingOptions: Bool

    var body: some View {
        ZStack{
            Color("BackgroundColour").ignoresSafeArea()

            HStack {
                VStack{
                    // Your existing keys left column
                    KeyButton(colorName: "KeyColour2") { oscillator17.trigger() }
                    KeyButton(colorName: "KeyColour5") { oscillator15.trigger() }
                    KeyButton(colorName: "KeyColour3") { oscillator13.trigger() }
                    KeyButton(colorName: "KeyColour1") { oscillator11.trigger() }
                    KeyButton(colorName: "KeyColour4") { oscillator09.trigger() }
                    KeyButton(colorName: "KeyColour2") { oscillator07.trigger() }
                    KeyButton(colorName: "KeyColour5") { oscillator05.trigger() }
                    KeyButton(colorName: "KeyColour3") { oscillator03.trigger() }
                    KeyButton(colorName: "KeyColour1") { oscillator01.trigger() }
                }

                // Middle column with title + scale controls
                VStack{
                    ZStack{
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("HighlightColour"))
                            .frame(width:40)
                        Text("Penta-Tone")
                            .font(.custom("SignPainter", size:35))
                            .foregroundColor(Color("BackgroundColour"))
                            //.fixedSize()
                            .frame(width:30,height:200,alignment:.center)
                            .rotationEffect(Angle(degrees: 90))

                        VStack{
                            Text("•UNFOLD•")
                                .font(.custom("Futura Medium", size:15))
                                .foregroundColor(Color("BackgroundColour"))
                                //.fixedSize()
                                .frame(width:30,height:135,alignment:.center)
                                .rotationEffect(Angle(degrees: 90))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    showingOptions = true
                                }
                            Spacer()
                        }
                        
                        VStack(spacing: 25) {
                            
                            Spacer()
                            // Plus button (next scale)
                            Button {
                                onNextScale?()
                            } label: {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(Color("BackgroundColour"))
                                    .font(.system(size: 22, weight: .bold))
                            }
                            .buttonStyle(.plain)
                            // Minus button (previous scale)
                            Button {
                                onPrevScale?()
                            } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(Color("BackgroundColour"))
                                    .font(.system(size: 22, weight: .bold))
                            }
                            .buttonStyle(.plain)
                            Rectangle()
                                .frame(width:30,height:20,alignment:.center)
                                .foregroundColor(Color("HighlightColour"))
                        }
                    }
                }

                VStack{
                    // Your existing keys right column
                    KeyButton(colorName: "KeyColour3") { oscillator18.trigger() }
                    KeyButton(colorName: "KeyColour1") { oscillator16.trigger() }
                    KeyButton(colorName: "KeyColour4") { oscillator14.trigger() }
                    KeyButton(colorName: "KeyColour2") { oscillator12.trigger() }
                    KeyButton(colorName: "KeyColour5") { oscillator10.trigger() }
                    KeyButton(colorName: "KeyColour3") { oscillator08.trigger() }
                    KeyButton(colorName: "KeyColour1") { oscillator06.trigger() }
                    KeyButton(colorName: "KeyColour4") { oscillator04.trigger() }
                    KeyButton(colorName: "KeyColour2") { oscillator02.trigger() }
                }
            }
            .padding(5)
        }
        .statusBar(hidden: true)
    }
}

#Preview {
    // For preview, provide no-op callbacks
    KeyView(onPrevScale: {}, onNextScale: {}, showingOptions: .constant(false))
}
