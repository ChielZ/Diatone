//
//  V3-S2 SoundView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 06/12/2025.
//

import SwiftUI

struct SoundView: View {
    // Connect to the global parameter manager
    @ObservedObject private var paramManager = AudioParameterManager.shared
    @ObservedObject private var presetManager = PresetManager.shared
    
    // Get the currently selected bank from PresetView (persisted)
    @AppStorage("presetView.selectedBankTypeRawValue") private var selectedBankTypeRawValue: String = PentatoneBankType.factory.rawValue
    
    // Track which slot is selected in this view
    @State private var selectedRow: Int = 1 // 1-5
    @State private var selectedColumn: Int = 1 // 1-5
    
    // Computed property for selectedBankType
    private var selectedBankType: PentatoneBankType {
        PentatoneBankType(rawValue: selectedBankTypeRawValue) ?? .factory
    }
    
    // Get the currently selected preset
    private var currentPreset: AudioParameterSet? {
        presetManager.preset(forBankType: selectedBankType, row: selectedRow, column: selectedColumn)
    }
    
    // Display text for current selection
    private var presetDisplayText: String {
        let slotName = "\(selectedRow).\(selectedColumn)"
        
        if let preset = currentPreset {
            return "\(slotName) \(preset.name)"
        } else {
            return "\(slotName) - Empty"
        }
    }
    
    var body: some View {
        Group {
            
            ZStack { // Row 3
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                
            }
            ZStack { // Row 4 - Preset Name Display
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                GeometryReader { geometry in
                    Text(presetDisplayText)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("LobsterTwo", size: 55)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        .offset(y: -(geometry.size.height/2 + 11))
                        .padding(0)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                
            }
            
            ZStack { // Row 5 - Top Row of Preset Buttons (Row 1)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))

                HStack {
                    ForEach(1...5, id: \.self) { column in
                        PresetButton(
                            row: 1,
                            column: column,
                            isSelected: selectedRow == 1 && selectedColumn == column,
                            action: {
                                selectPreset(row: 1, column: column)
                            }
                        )
                        
                        if column < 5 {
                            Spacer()
                        }
                    }
                }
            }
            
            ZStack { // Row 6 - Bottom Row of Preset Buttons (Row 2)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))

                HStack {
                    ForEach(1...5, id: \.self) { column in
                        PresetButton(
                            row: 2,
                            column: column,
                            isSelected: selectedRow == 2 && selectedColumn == column,
                            action: {
                                selectPreset(row: 2, column: column)
                            }
                        )
                        
                        if column < 5 {
                            Spacer()
                        }
                    }
                }
            }
            
            ZStack { // Row 7 - VOLUME
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("HighlightColour"))
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .padding(4)
                
                
                // Volume slider (0 to 1, left to right)
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color("HighlightColour"))
                            .frame(width: geometry.size.width * paramManager.macroState.volumePosition)
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .frame(width: geometry.size.width * (1.0 - paramManager.macroState.volumePosition))
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newPosition = value.location.x / geometry.size.width
                                let clampedPosition = min(max(newPosition, 0.0), 1.0)
                                paramManager.updateVolumeMacro(clampedPosition)
                            }
                    )
                }.padding(4)
                
                Text("VOLUME")
                    .foregroundColor(Color("BackgroundColour"))
                    .adaptiveFont("MontserratAlternates-Medium", size: 30)
                    .minimumScaleFactor(0.5)
                    .allowsHitTesting(false)
            }
            
            ZStack { // Row 8 - TONE
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("HighlightColour"))
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .padding(4)
                
                // Tone slider (-1 to +1, bipolar with center at 0)
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Calculate widths based on position (-1 to +1)
                        let normalizedPosition = (paramManager.macroState.tonePosition + 1.0) / 2.0 // Convert -1...1 to 0...1
                        
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color("HighlightColour"))
                            .frame(width: geometry.size.width * normalizedPosition)
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .frame(width: geometry.size.width * (1.0 - normalizedPosition))
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Convert x position to -1...+1 range
                                let normalizedX = value.location.x / geometry.size.width
                                let newPosition = (normalizedX * 2.0) - 1.0 // Convert 0...1 to -1...1
                                paramManager.updateToneMacro(newPosition)
                            }
                    )
                }.padding(4)
                
                Text("TONE")
                    .foregroundColor(Color("BackgroundColour"))
                    .adaptiveFont("MontserratAlternates-Medium", size: 30)
                    .minimumScaleFactor(0.5)
                    .allowsHitTesting(false)
            }
            
            ZStack { // Row 9 - AMBIENCE
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("HighlightColour"))
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .padding(4)
            
                
                // Ambience slider (-1 to +1, bipolar with center at 0)
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Calculate widths based on position (-1 to +1)
                        let normalizedPosition = (paramManager.macroState.ambiencePosition + 1.0) / 2.0 // Convert -1...1 to 0...1
                        
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color("HighlightColour"))
                            .frame(width: geometry.size.width * normalizedPosition)
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .frame(width: geometry.size.width * (1.0 - normalizedPosition))
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Convert x position to -1...+1 range
                                let normalizedX = value.location.x / geometry.size.width
                                let newPosition = (normalizedX * 2.0) - 1.0 // Convert 0...1 to -1...1
                                paramManager.updateAmbienceMacro(newPosition)
                            }
                    )
                }.padding(4)
                
                Text("AMBIENCE")
                    .foregroundColor(Color("BackgroundColour"))
                    .adaptiveFont("MontserratAlternates-Medium", size: 30)
                    .minimumScaleFactor(0.5)
                    .allowsHitTesting(false)
            }
            
            
        }
    }
    
    // MARK: - Actions
    
    private func selectPreset(row: Int, column: Int) {
        // Update selection
        selectedRow = row
        selectedColumn = column
        
        // Load preset if it exists
        if let preset = presetManager.preset(forBankType: selectedBankType, row: row, column: column) {
            presetManager.loadPreset(preset)
        }
        // If slot is empty, just update the display (no sound change)
    }
}

// MARK: - Preset Button Component

private struct PresetButton: View {
    let row: Int
    let column: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(isSelected ? Color("HighlightColour") : Color("SupportColour"))
            .aspectRatio(1.0, contentMode: .fit)
            .overlay(
                Text("\(column)")
                    .foregroundColor(Color("BackgroundColour"))
                    .adaptiveFont("MontserratAlternates-Medium", size: 30)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                action()
            }
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack {
            SoundView()
        }
        .padding(25)
    }
}
