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
    var onSwitchToEdit: (() -> Void)? = nil
    
    // Get the currently selected bank from PresetView (persisted)
    @AppStorage("presetView.selectedBankTypeRawValue") private var selectedBankTypeRawValue: String = PentatoneBankType.factory.rawValue
    
    // Persist the currently selected row and column (survives view reloads during app session)
    @AppStorage("soundView.selectedRow") private var selectedRow: Int = 1 // 1-5
    @AppStorage("soundView.selectedColumn") private var selectedColumn: Int = 1 // 1-5
    
    // PresetView's @AppStorage properties - update these when switching to EditView
    @AppStorage("presetView.selectedRow") private var presetViewSelectedRow: Int = 1
    @AppStorage("presetView.selectedColumn") private var presetViewSelectedColumn: Int = 1
    
    // Track the actually loaded preset (shared with PresetView for color computation)
    @AppStorage("activePreset.bankType") private var activePresetBankType: String = PentatoneBankType.factory.rawValue
    @AppStorage("activePreset.row") private var activePresetRow: Int = 1
    @AppStorage("activePreset.column") private var activePresetColumn: Int = 1
    
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
                        .foregroundColor(Color("KeyColour1"))
                        .adaptiveFont("LobsterTwo-Italic", size: 55)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        .offset(y: -(geometry.size.height/2 + 11))
                        .padding(0)
                        .lineLimit(1)
                        //.minimumScaleFactor(0.5)
                        .onTapGesture {
                            // Sync PresetView to show the currently active preset
                            syncPresetViewToCurrentPreset()
                            onSwitchToEdit?()
                        }
                }
                
            }
            
            ZStack { // Row 5 - Top Row (Select Row 1-5)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))

                HStack {
                    ForEach(1...5, id: \.self) { row in
                        PresetButton(
                            row: row,
                            column: row,
                            isSelected: selectedRow == row,
                            action: {
                                selectRow(row)
                            }
                        )
                        
                        if row < 5 {
                            Spacer()
                        }
                    }
                }
            }
            
            ZStack { // Row 6 - Bottom Row (Select Column 1-5)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))

                HStack {
                    ForEach(1...5, id: \.self) { column in
                        PresetButton(
                            row: 1,
                            column: column,
                            isSelected: selectedColumn == column,
                            action: {
                                selectColumn(column)
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
    
    /// Synchronize PresetView to show the currently active preset
    private func syncPresetViewToCurrentPreset() {
        // Update PresetView's selection to match the currently active preset
        // Use the active preset tracking that's shared between views
        presetViewSelectedRow = activePresetRow
        presetViewSelectedColumn = activePresetColumn
        // Note: selectedBankTypeRawValue is already shared between both views
    }
    
    private func selectRow(_ row: Int) {
        // Update row selection
        selectedRow = row
        
        // Load the preset at the new position
        loadCurrentPreset()
    }
    
    private func selectColumn(_ column: Int) {
        // Update column selection
        selectedColumn = column
        
        // Load the preset at the new position
        loadCurrentPreset()
    }
    
    private func loadCurrentPreset() {
        // Load preset if it exists at current row/column
        if let preset = presetManager.preset(forBankType: selectedBankType, row: selectedRow, column: selectedColumn) {
            presetManager.loadPreset(preset)
            
            // Update active preset tracking - this is now the loaded preset
            activePresetBankType = selectedBankTypeRawValue
            activePresetRow = selectedRow
            activePresetColumn = selectedColumn
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
