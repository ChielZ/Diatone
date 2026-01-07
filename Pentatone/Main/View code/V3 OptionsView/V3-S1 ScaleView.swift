//
//  V3-S1 ScaleView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 06/12/2025.
//

import SwiftUI

struct ScaleView: View {
    // Current scale and navigation callbacks
    var currentScale: Scale = ScalesCatalog.centerMeridian_JI
    var currentKey: MusicalKey = .D
    var onCycleIntonation: ((Bool) -> Void)? = nil
    var onCycleCelestial: ((Bool) -> Void)? = nil
    var onCycleTerrestrial: ((Bool) -> Void)? = nil
    var onCycleRotation: ((Bool) -> Void)? = nil
    var onCycleKey: ((Bool) -> Void)? = nil
    
    // Computed property to get the correct image name based on current scale
    private var scaleImageName: String {
        let intonationPrefix = currentScale.intonation == .ji ? "JI" : "ET"
        let celestialPart = currentScale.celestial.rawValue.capitalized
        let terrestrialPart = currentScale.terrestrial.rawValue.capitalized
        return "\(intonationPrefix)_\(celestialPart)\(terrestrialPart)"
    }
    
    var body: some View {
        Group {
            
            ZStack { // Row 3 (top half of image area)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
            }
            ZStack { // Row 4 (bottom half of image area)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
            }
            .overlay(
                GeometryReader { geometry in
                    let scaleFactor: CGFloat = currentScale.intonation == .et ? 0.6 : 1.0
                    let fullHeight: CGFloat = geometry.size.height * 2 + 11
                    let imageHeight: CGFloat = fullHeight * scaleFactor
                    
                    Image(scaleImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: imageHeight)
                        .frame(width: geometry.size.width, height: fullHeight)
                        .offset(y: -(geometry.size.height + 11))
                        .padding(0)
                        
                }
            )
            ZStack { // Row 5 - Intonation
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleIntonation?(false)
                        }
                    Spacer()
                    Text(currentScale.intonation.rawValue)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleIntonation?(true)
                        }
                }
            }
            ZStack { // Row 6 - Musical Key
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleKey?(false)
                        }
                    Spacer()
                    MusicalKeyText(key: currentKey, size: 30)
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleKey?(true)
                        }
                }
            }
            ZStack { // Row 7 - Celestial
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleCelestial?(false)
                        }
                    Spacer()
                    Text(currentScale.celestial.rawValue)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleCelestial?(true)
                        }
                }
            }
            ZStack { // Row 8 - Terrestrial
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleTerrestrial?(false)
                        }
                    Spacer()
                    Text(currentScale.terrestrial.rawValue)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleTerrestrial?(true)
                        }
                }
            }
            ZStack { // Row 9 - Rotation
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleRotation?(false)
                        }
                    Spacer()
                    Text(currentScale.rotation == 0 ? "0" : "\(currentScale.rotation > 0 ? "+" : "−") \(abs(currentScale.rotation))")
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCycleRotation?(true)
                        }
                }
            }
        }
    }
}

// MARK: - Musical Key Text Component

/// A view that displays a musical key with the note letter
/// and the accidental (♯ or ♭)
struct MusicalKeyText: View {
    let key: MusicalKey
    let size: CGFloat
    
    var body: some View {
        HStack(spacing: -2) {
            // Note letter
            Text(key.noteLetter)
                .foregroundColor(Color("HighlightColour"))
                .adaptiveFont("MontserratAlternates-Medium", size: size)
            
            // Accidental
            if let accidental = key.accidental {
                Text(accidental)
                    .foregroundColor(Color("HighlightColour"))
                    .font(.custom("MontserratAlternates-Medium", size: size * 0.7)) // Slightly smaller for better visual balance, orig. 0.7
                    .baselineOffset(size * 0.15) // Fine-tune vertical alignment, orig. 0.05
            }
        }
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack {
            ScaleView(
                currentScale: ScalesCatalog.centerMeridian_JI,
                currentKey: .D,
                onCycleIntonation: { _ in },
                onCycleCelestial: { _ in },
                onCycleTerrestrial: { _ in },
                onCycleRotation: { _ in },
                onCycleKey: { _ in }
            )
        }
        .padding(25)
    }
}
