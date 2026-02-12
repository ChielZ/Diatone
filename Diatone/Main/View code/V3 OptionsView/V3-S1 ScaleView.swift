//
//  V3-S1 ScaleView.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 06/12/2025.
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

struct ScaleView: View {
    // Current scale and navigation callbacks
    var currentScale: Scale = ScalesCatalog.Dorian_JI_E
    var currentKey: MusicalKey = .D
    var buttonAnchors: ButtonAnchorData = ButtonAnchorData()
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
                    let scaleFactor: CGFloat = currentScale.intonation == .et ? 0.9 : 0.8
                    let fullHeight: CGFloat = geometry.size.height * 2 + 11
                    let imageHeight: CGFloat = fullHeight * scaleFactor
                    
                    // Downsample the image to the actual display size to prevent excessive memory usage
                    // The target height accounts for screen scale, so a @3x device gets 3x the points
                    let targetHeight = imageHeight * UIScreen.main.scale
                    
                    if let downsampledUIImage = downsampledImage(named: scaleImageName, targetHeight: targetHeight) {
                        Image(uiImage: downsampledUIImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: imageHeight)
                            .frame(width: geometry.size.width, height: fullHeight)
                            .offset(y: -(geometry.size.height + 11))
                            .padding(0)
                    } else {
                        // Fallback to original method if downsampling fails
                        Image(scaleImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: imageHeight)
                            .frame(width: geometry.size.width, height: fullHeight)
                            .offset(y: -(geometry.size.height + 11))
                            .padding(0)
                    }
                }
            )
            ZStack { // Row 5 - Intonation
                AlignedSelectorRow(
                    leftSymbol: "<",
                    rightSymbol: ">",
                    centerText: currentScale.intonation.rawValue,
                    buttonAnchors: buttonAnchors,
                    onLeftTap: { onCycleIntonation?(false) },
                    onRightTap: { onCycleIntonation?(true) }
                )
            }
            ZStack { // Row 6 - Musical Key
                AlignedSelectorRow(
                    leftSymbol: "<",
                    rightSymbol: ">",
                    centerText: "", // Use custom view below
                    buttonAnchors: buttonAnchors,
                    onLeftTap: { onCycleKey?(false) },
                    onRightTap: { onCycleKey?(true) }
                )
                // Overlay the MusicalKeyText for proper formatting
                MusicalKeyText(key: currentKey, size: 30)
            }
            ZStack { // Row 7 - Celestial
                AlignedSelectorRow(
                    leftSymbol: "<",
                    rightSymbol: ">",
                    centerText: currentScale.celestial.rawValue,
                    buttonAnchors: buttonAnchors,
                    onLeftTap: { onCycleCelestial?(false) },
                    onRightTap: { onCycleCelestial?(true) }
                )
            }
            
            ZStack { // Row 8 - Terrestrial
                AlignedSelectorRow(
                    leftSymbol: "<",
                    rightSymbol: ">",
                    centerText: currentScale.terrestrial.rawValue,
                    buttonAnchors: buttonAnchors,
                    onLeftTap: { onCycleTerrestrial?(false) },
                    onRightTap: { onCycleTerrestrial?(true) }
                )
            }
            
            ZStack { // Row 9 - Rotation
                AlignedSelectorRow(
                    leftSymbol: "<",
                    rightSymbol: ">",
                    centerText: currentScale.rotation == 0 ? "0" : "\(currentScale.rotation > 0 ? "+" : "−") \(abs(currentScale.rotation))",
                    buttonAnchors: buttonAnchors,
                    onLeftTap: { onCycleRotation?(false) },
                    onRightTap: { onCycleRotation?(true) }
                )
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
                currentScale: ScalesCatalog.Dorian_JI_E,
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
