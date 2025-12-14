//
//  MainKeyboardView.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 07/12/2025.
//

import SwiftUI

/// Determines the width of the center strip based on device, orientation, and fold state
struct CenterStripConfig {
    let width: CGFloat
    let isIPad: Bool
    let isUnfolded: Bool
    
    static func calculate(geometry: GeometryProxy, isUnfolded: Bool) -> CenterStripConfig {
        let screenWidth = geometry.size.width
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let isLandscape = geometry.size.width > geometry.size.height
        
        let percentage: CGFloat
        
        if isIPad {
            if isLandscape {
                percentage = isUnfolded ? 0.33 : 0.05  // 50% or 5%
            } else {
                percentage = isUnfolded ? 0.65 : 0.07  // 70% or 7%
            }
        } else {
            // iPhone (always portrait for this app)
            percentage = isUnfolded ? 1.0 : 0.10  // 100% or 10%
        }
        
        return CenterStripConfig(width: screenWidth * percentage, isIPad: isIPad, isUnfolded: isUnfolded)
    }
}

struct MainKeyboardView: View {
    // Callbacks provided by the App to change scales
    var onPrevScale: (() -> Void)? = nil
    var onNextScale: (() -> Void)? = nil
    
    // Current scale info and property-based navigation
    var currentScale: Scale = ScalesCatalog.centerMeridian_JI
    var onCycleIntonation: ((Bool) -> Void)? = nil
    var onCycleCelestial: ((Bool) -> Void)? = nil
    var onCycleTerrestrial: ((Bool) -> Void)? = nil
    var onCycleRotation: ((Bool) -> Void)? = nil
    
    @State private var showingOptions: Bool = false
    
    // MARK: - Key Color Calculation
    
    /// Calculates the color name for a given key index (0-17) based on current rotation
    /// Keys cycle through 5 colors corresponding to the 5 scale degrees
    /// With rotation, the color assignment shifts to match the new note mapping
    private func keyColor(for keyIndex: Int) -> String {
        // Base color pattern (without rotation): cycles 1,2,3,4,5,1,2,3,4,5...
        // Each key normally maps to: (keyIndex % 5) + 1
        let baseColorIndex = keyIndex % 5
        
        // Apply rotation offset (sign flipped to match note rotation direction)
        // Positive rotation shifts colors to the left (earlier colors move to later keys)
        // Negative rotation shifts colors to the right (later colors move to earlier keys)
        let rotatedColorIndex = (baseColorIndex + currentScale.rotation + 5) % 5
        
        // Map to color name (1-5)
        return "KeyColour\(rotatedColorIndex + 1)"
    }
    
    var body: some View {
        GeometryReader { geometry in
            let centerConfig = CenterStripConfig.calculate(
                geometry: geometry,
                isUnfolded: showingOptions
            )
            
            ZStack {
                Color("BackgroundColour").ignoresSafeArea()
                
                HStack(spacing: 0) {
                    // Left column - Keys
                    VStack {
                        KeyButton(colorName: keyColor(for: 16)) { oscillator17.trigger() }
                        KeyButton(colorName: keyColor(for: 14)) { oscillator15.trigger() }
                        KeyButton(colorName: keyColor(for: 12)) { oscillator13.trigger() }
                        KeyButton(colorName: keyColor(for: 10)) { oscillator11.trigger() }
                        KeyButton(colorName: keyColor(for: 8)) { oscillator09.trigger() }
                        KeyButton(colorName: keyColor(for: 6)) { oscillator07.trigger() }
                        KeyButton(colorName: keyColor(for: 4)) { oscillator05.trigger() }
                        KeyButton(colorName: keyColor(for: 2)) { oscillator03.trigger() }
                        KeyButton(colorName: keyColor(for: 0)) { oscillator01.trigger() }
                    }
                    .padding(5)
                    
                    // Center column - Navigation strip or Options
                    ZStack {
                        if showingOptions {
                            // Add border for iPad, no border for iPhone
                            if centerConfig.isIPad {
                                
                                OptionsView(
                                    showingOptions: $showingOptions,
                                    currentScale: currentScale,
                                    onCycleIntonation: onCycleIntonation,
                                    onCycleCelestial: onCycleCelestial,
                                    onCycleTerrestrial: onCycleTerrestrial,
                                    onCycleRotation: onCycleRotation
                                )
                                       .transition(.opacity)
                            } else {
                                OptionsView(
                                    showingOptions: $showingOptions,
                                    currentScale: currentScale,
                                    onCycleIntonation: onCycleIntonation,
                                    onCycleCelestial: onCycleCelestial,
                                    onCycleTerrestrial: onCycleTerrestrial,
                                    onCycleRotation: onCycleRotation
                                )
                                    .transition(.opacity)
                            }
                        } else {
                            NavigationStrip(
                                showingOptions: $showingOptions,
                                onPrevScale: onPrevScale,
                                onNextScale: onNextScale,
                                stripWidth: centerConfig.width
                            )
                            .transition(.opacity)
                        }
                    }
                    .frame(width: centerConfig.width)
                    .animation(.easeInOut(duration: 0.3), value: showingOptions)
                    
                    // Right column - Keys
                    VStack {
                        KeyButton(colorName: keyColor(for: 17)) { oscillator18.trigger() }
                        KeyButton(colorName: keyColor(for: 15)) { oscillator16.trigger() }
                        KeyButton(colorName: keyColor(for: 13)) { oscillator14.trigger() }
                        KeyButton(colorName: keyColor(for: 11)) { oscillator12.trigger() }
                        KeyButton(colorName: keyColor(for: 9)) { oscillator10.trigger() }
                        KeyButton(colorName: keyColor(for: 7)) { oscillator08.trigger() }
                        KeyButton(colorName: keyColor(for: 5)) { oscillator06.trigger() }
                        KeyButton(colorName: keyColor(for: 3)) { oscillator04.trigger() }
                        KeyButton(colorName: keyColor(for: 1)) { oscillator02.trigger() }
                    }
                    .padding(5)
                }
            }
            .statusBar(hidden: true)
        }
    }
}

/// The navigation strip shown when the options are folded
private struct NavigationStrip: View {
    @Binding var showingOptions: Bool
    var onPrevScale: (() -> Void)? = nil
    var onNextScale: (() -> Void)? = nil
    let stripWidth: CGFloat
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("HighlightColour"))
                
                Text("Pentatone")
                    .font(.custom("SignPainter", size: 42))
                    .foregroundColor(Color("BackgroundColour"))
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: stripWidth * 0.95, height: 250, alignment: .center)
                    .rotationEffect(Angle(degrees: 90))
                   
                
                VStack {
                    Text("•UNFOLD•")
                        .font(.custom("Futura Medium", size: 18))
                        .foregroundColor(Color("BackgroundColour"))
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                        .fixedSize()
                        .frame(width: stripWidth * 0.7, height: 135, alignment: .center)
                        .rotationEffect(Angle(degrees: 90))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingOptions = true
                        }
                    Spacer()
                }
                /*
                VStack(spacing: 25) {
                    Spacer()
                    
                    // Plus button (next scale)
                    Button {
                        onNextScale?()
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(Color("BackgroundColour"))
                            .font(.system(size: min(22, stripWidth * 0.5), weight: .bold))
                    }
                    .buttonStyle(.plain)
                    
                    // Minus button (previous scale)
                    Button {
                        onPrevScale?()
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundColor(Color("BackgroundColour"))
                            .font(.system(size: min(22, stripWidth * 0.5), weight: .bold))
                    }
                    .buttonStyle(.plain)
                    
                    Rectangle()
                        .frame(width: stripWidth * 0.7, height: 20, alignment: .center)
                        .foregroundColor(Color("HighlightColour"))
                }
                */
            }
        }
        .padding(5)
    }
}

/// Reusable key button component
private struct KeyButton: View {
    let colorName: String
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

#Preview {
    MainKeyboardView(
        onPrevScale: {},
        onNextScale: {},
        currentScale: ScalesCatalog.centerMeridian_JI,
        onCycleIntonation: { _ in },
        onCycleCelestial: { _ in },
        onCycleTerrestrial: { _ in },
        onCycleRotation: { _ in }
    )
}
