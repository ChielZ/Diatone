//
//  V4-S11 PresetView.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 11 - PRESET MANAGEMENT

import SwiftUI
import UniformTypeIdentifiers

struct PresetView: View {
    // Connect to managers
    @ObservedObject private var presetManager = PresetManager.shared
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    @ObservedObject private var sharedButtonWidth = SharedButtonWidth.shared
    
    // UI State - Using @AppStorage to persist across view changes
    @AppStorage("presetView.selectedBankTypeRawValue") private var selectedBankTypeRawValue: String = PentatoneBankType.factory.rawValue
    @AppStorage("presetView.selectedRow") private var selectedRow: Int = 1 // 1-5
    @AppStorage("presetView.selectedColumn") private var selectedColumn: Int = 1 // 1-5
    
    // SoundView's @AppStorage properties - update these when loading/saving a preset
    @AppStorage("soundView.selectedRow") private var soundViewSelectedRow: Int = 1
    @AppStorage("soundView.selectedColumn") private var soundViewSelectedColumn: Int = 1
    
    // Track the actually loaded preset (for color computation)
    @AppStorage("activePreset.bankType") private var activePresetBankType: String = PentatoneBankType.factory.rawValue
    @AppStorage("activePreset.row") private var activePresetRow: Int = 1
    @AppStorage("activePreset.column") private var activePresetColumn: Int = 1
    
    // Computed property for selectedBankType
    private var selectedBankType: PentatoneBankType {
        get {
            PentatoneBankType(rawValue: selectedBankTypeRawValue) ?? .factory
        }
        set {
            selectedBankTypeRawValue = newValue.rawValue
        }
    }
    
    // Sheet/Alert State
    @State private var showingSaveDialog = false
    @State private var showingOverwriteDialog = false
    @State private var showingImportPicker = false
    @State private var showingCleanupView = false  // DEBUG
    @State private var newPresetName: String = ""
    @State private var alertMessage: String?
    @State private var showingAlert = false
    
    var body: some View {
        Group {
            // Row 3 - Bank Navigation
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack(spacing: 0) {
                    let buttonWidth = sharedButtonWidth.width > 0 ? sharedButtonWidth.width : 60
                    
                    // Previous Bank
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .frame(width: buttonWidth)
                        .overlay(
                            Text("<")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            previousBank()
                        }
                    
                    Spacer()
                    
                    // Bank Display
                    Text(bankDisplayText)
                        .foregroundColor(bankDisplayColor)
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                    
                    Spacer()
                    
                    // Next Bank
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .frame(width: buttonWidth)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            nextBank()
                        }
                }
            }
            
            // Row 4 - Position Navigation
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack(spacing: 0) {
                    let buttonWidth = sharedButtonWidth.width > 0 ? sharedButtonWidth.width : 60
                    
                    // Previous Position
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .frame(width: buttonWidth)
                        .overlay(
                            Text("<")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            previousPosition()
                        }
                    
                    Spacer()
                    
                    // Position Display (shows preset name if loaded)
                    Text(positionDisplayText)
                        .foregroundColor(positionDisplayColor)
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Spacer()
                    
                    // Next Position
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .frame(width: buttonWidth)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            nextPosition()
                        }
                }
            }
            
            // Row 5 - Load/Save Preset
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(currentSlotPreset != nil ? Color("SupportColour") : Color("HighlightColour"))
                GeometryReader { geometry in
                    Text(currentSlotPreset != nil ? "･LOAD PRESET･" : "･SAVE PRESET･")
                        .foregroundColor(Color("BackgroundColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        .padding(0)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    handleLoadOrSave()
                }
            }
            
            // Row 6 - Import Preset
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(selectedBankType.isUserBank ? Color("SupportColour") : Color("BackgroundColour"))
                if selectedBankType.isUserBank {
                    GeometryReader { geometry in
                        Text("･IMPORT･")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .padding(0)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingImportPicker = true
                    }
                }
            }
            
            // Row 7 - Export Preset
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(currentSlotPreset != nil ? Color("SupportColour") : Color("BackgroundColour").opacity(1.0))
                GeometryReader { geometry in
                    Text("･EXPORT･")
                        .foregroundColor(Color("BackgroundColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        .padding(0)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    handleExport()
                }
            }
            
            // Row 8 - Overwrite Preset (User only)
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(canOverwriteCurrentSlot ? Color("SupportColour") : Color("BackgroundColour"))
                if canOverwriteCurrentSlot {
                    GeometryReader { geometry in
                        Text("･OVERWRITE･")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .padding(0)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingOverwriteDialog = true
                    }
                }
            }
            
            // Row 9 - Info Display
            ZStack {
                
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                /*
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 2.0) {
                        // DEBUG: Long press to open cleanup view
                        showingCleanupView = true
                    }
                 
                 */
                
                
                /*
                VStack(spacing: 4) {
                    if let preset = currentSlotPreset {
                        Text(preset.name)
                            .foregroundColor(Color("HighlightColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 22)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    } else {
                        Text("Empty Slot")
                            .foregroundColor(Color("KeyColour1").opacity(0.5))
                            .adaptiveFont("MontserratAlternates-Medium", size: 22)
                    }
                }
                */
            }
        }
        // Save Dialog Sheet
        .sheet(isPresented: $showingSaveDialog) {
            savePresetDialog
        }
        // Overwrite Dialog Sheet
        .sheet(isPresented: $showingOverwriteDialog) {
            overwritePresetDialog
        }
        // Import File Picker
        .sheet(isPresented: $showingImportPicker) {
            DocumentPicker(allowedTypes: ["public.json", "com.yourname.arithmophone.preset"]) { url in
                handleImport(from: url)
            }
        }
        // General Alert
        .alert("Preset Manager", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let message = alertMessage {
                Text(message)
            }
        }
        /*
        // DEBUG: Cleanup view
        .sheet(isPresented: $showingCleanupView) {
            PresetCleanupView()
        }
         */
    }
    
    // MARK: - Computed Properties
    
    private var bankDisplayText: String {
        return selectedBankType.displayName.uppercased()
    }
    
    /// Color for bank display text based on state
    private var bankDisplayColor: Color {
        // Check if we're showing the currently active preset
        let isShowingActivePreset = (
            activePresetBankType == selectedBankTypeRawValue &&
            activePresetRow == selectedRow &&
            activePresetColumn == selectedColumn
        )
        
        if isShowingActivePreset {
            // Active preset - check if modified
            if paramManager.parametersModifiedSinceLoad {
                return Color("KeyColour4") // Modified
            } else {
                return Color("HighlightColour") // Unmodified
            }
        } else {
            // Not the active preset - check if slot has preset
            if currentSlotPreset != nil {
                return Color("KeyColour3") // Different preset, slot filled
            } else {
                return Color("KeyColour1") // Different preset, slot empty
            }
        }
    }
    
    private var positionDisplayText: String {
        let slotName = "\(selectedRow).\(selectedColumn)"
        
        if let preset = currentSlotPreset {
            return "\(slotName) \(preset.name)"
        } else {
            return "\(slotName) - Empty"
        }
    }
    
    /// Color for position display text based on state
    private var positionDisplayColor: Color {
        // Check if we're showing the currently active preset
        let isShowingActivePreset = (
            activePresetBankType == selectedBankTypeRawValue &&
            activePresetRow == selectedRow &&
            activePresetColumn == selectedColumn
        )
        
        if isShowingActivePreset {
            // Active preset - check if modified
            if paramManager.parametersModifiedSinceLoad {
                return Color("KeyColour4") // Modified
            } else {
                return Color("HighlightColour") // Unmodified
            }
        } else {
            // Not the active preset - check if slot has preset
            if currentSlotPreset != nil {
                return Color("KeyColour3") // Different preset, slot filled
            } else {
                return Color("KeyColour1") // Different preset, slot empty
            }
        }
    }
    
    private var currentSlotPreset: AudioParameterSet? {
        return presetManager.preset(forBankType: selectedBankType, row: selectedRow, column: selectedColumn)
    }
    
    private var canOverwriteCurrentSlot: Bool {
        guard selectedBankType.isUserBank else { return false }
        return currentSlotPreset != nil
    }
    
    // MARK: - Navigation
    
    private func previousBank() {
        // Get all bank types and find current index
        let allBanks = PentatoneBankType.allCases
        if let currentIndex = allBanks.firstIndex(of: selectedBankType) {
            if currentIndex > 0 {
                selectedBankTypeRawValue = allBanks[currentIndex - 1].rawValue
            } else {
                // Wrap to last bank
                selectedBankTypeRawValue = allBanks.last!.rawValue
            }
        }
    }
    
    private func nextBank() {
        // Get all bank types and find current index
        let allBanks = PentatoneBankType.allCases
        if let currentIndex = allBanks.firstIndex(of: selectedBankType) {
            if currentIndex < allBanks.count - 1 {
                selectedBankTypeRawValue = allBanks[currentIndex + 1].rawValue
            } else {
                // Wrap to first bank
                selectedBankTypeRawValue = allBanks.first!.rawValue
            }
        }
    }
    
    private func previousPosition() {
        // Navigate through the 5×5 grid (decrement column, then row)
        if selectedColumn > 1 {
            selectedColumn -= 1
        } else if selectedRow > 1 {
            selectedColumn = 5
            selectedRow -= 1
        } else {
            // Wrap to last position
            selectedRow = 5
            selectedColumn = 5
        }
    }
    
    private func nextPosition() {
        // Navigate through the 5×5 grid (increment column, then row)
        if selectedColumn < 5 {
            selectedColumn += 1
        } else if selectedRow < 5 {
            selectedColumn = 1
            selectedRow += 1
        } else {
            // Wrap to first position
            selectedRow = 1
            selectedColumn = 1
        }
    }
    
    // MARK: - Actions
    
    private func handleLoadOrSave() {
        if let preset = currentSlotPreset {
            // Slot has preset - Load it
            presetManager.loadPreset(preset)
            
            // Update active preset tracking - this is now the loaded preset
            activePresetBankType = selectedBankTypeRawValue
            activePresetRow = selectedRow
            activePresetColumn = selectedColumn
            
            // Sync SoundView's selection to match what we just loaded
            soundViewSelectedRow = selectedRow
            soundViewSelectedColumn = selectedColumn
            
            showAlert("Loaded preset '\(preset.name)'")
        } else {
            // Slot is empty - Save current parameters
            if selectedBankType.isFactoryBank {
                showAlert("Cannot save to factory bank. Switch to User A, User B, User C, or User D.")
            } else {
                showingSaveDialog = true
            }
        }
    }
    
    private func handleSave() {
        guard !newPresetName.isEmpty else {
            showAlert("Please enter a preset name")
            return
        }
        
        do {
            // Save current parameters as new preset
            let newPreset = try presetManager.saveCurrentAsNewPreset(name: newPresetName)
            
            // Assign to current slot
            try presetManager.assignPresetToSlot(preset: newPreset, bankType: selectedBankType, row: selectedRow, column: selectedColumn)
            
            // Update active preset tracking - this saved preset is now active
            activePresetBankType = selectedBankTypeRawValue
            activePresetRow = selectedRow
            activePresetColumn = selectedColumn
            
            // Sync SoundView's selection to match what we just saved
            soundViewSelectedRow = selectedRow
            soundViewSelectedColumn = selectedColumn
            
            showAlert("Saved preset '\(newPresetName)' to \(selectedBankType.displayName) \(selectedRow).\(selectedColumn)")
            newPresetName = ""
            showingSaveDialog = false
        } catch {
            showAlert("Failed to save preset: \(error.localizedDescription)")
        }
    }
    
    private func handleExport() {
        guard let preset = currentSlotPreset else {
            showAlert("No preset in this slot to export")
            return
        }
        
        do {
            let url = try presetManager.exportPreset(preset)
            
            // Present share sheet using UIKit directly
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                showAlert("Failed to present share sheet")
                return
            }
            
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            // For iPad: configure popover presentation
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true)
        } catch {
            showAlert("Failed to export preset: \(error.localizedDescription)")
        }
    }
    
    private func handleImport(from url: URL) {
        // Check if trying to import into factory bank
        if selectedBankType.isFactoryBank {
            showAlert("Cannot import to factory bank. Switch to User A, User B, User C, or User D.")
            return
        }
        
        do {
            // Import and assign to currently selected slot
            let preset = try presetManager.importPresetToSlot(
                from: url,
                bankType: selectedBankType,
                row: selectedRow,
                column: selectedColumn
            )
            showAlert("Imported '\(preset.name)' to \(selectedBankType.displayName) \(selectedRow).\(selectedColumn)")
        } catch {
            showAlert("Failed to import preset: \(error.localizedDescription)")
        }
    }
    
    private func handleOverwrite() {
        guard let preset = currentSlotPreset else { return }
        guard !newPresetName.isEmpty else {
            showAlert("Please enter a preset name")
            return
        }
        
        do {
            // Update the existing preset with current parameters and new name
            let updatedPreset = try presetManager.updatePreset(preset, newName: newPresetName)
            
            // Update active preset tracking - this overwritten preset is now active
            activePresetBankType = selectedBankTypeRawValue
            activePresetRow = selectedRow
            activePresetColumn = selectedColumn
            
            // Sync SoundView's selection to match what we just overwrote
            soundViewSelectedRow = selectedRow
            soundViewSelectedColumn = selectedColumn
            
            showAlert("Updated preset '\(updatedPreset.name)'")
            newPresetName = ""
            showingOverwriteDialog = false
        } catch {
            showAlert("Failed to update preset: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    // MARK: - Save Dialog View
    
    private var savePresetDialog: some View {
        NavigationView {
            List {
                Section {
                    TextField("Preset name", text: $newPresetName)
                        .autocapitalization(.words)
                } header: {
                    Text("Name your sound")
                }
                
                Section {
                    Button("Save") {
                        handleSave()
                    }
                    .disabled(newPresetName.isEmpty)
                    
                    Button("Cancel") {
                        newPresetName = ""
                        showingSaveDialog = false
                    }
                }
            }
            .navigationTitle("Save Preset")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Overwrite Dialog View
    
    private var overwritePresetDialog: some View {
        NavigationView {
            List {
                Section {
                    TextField("Preset name", text: $newPresetName)
                        .autocapitalization(.words)
                } header: {
                    Text("Update your sound")
                } footer: {
                    Text("You can rename the preset or keep the same name.")
                }
                
                Section {
                    Button("Update") {
                        handleOverwrite()
                    }
                    .disabled(newPresetName.isEmpty)
                    
                    Button("Cancel") {
                        newPresetName = ""
                        showingOverwriteDialog = false
                    }
                }
            }
            .navigationTitle("Update Preset")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Pre-fill with the name of the currently active preset
                // (the one being edited), not the preset in the slot being overwritten
                if let activePreset = presetManager.preset(
                    forBankType: PentatoneBankType(rawValue: activePresetBankType) ?? .factory,
                    row: activePresetRow,
                    column: activePresetColumn
                ) {
                    newPresetName = activePreset.name
                } else if let preset = currentSlotPreset {
                    // Fallback: if no active preset found, use the slot's preset name
                    newPresetName = preset.name
                }
            }
        }
    }
}

// MARK: - Document Picker for Import

struct DocumentPicker: UIViewControllerRepresentable {
    let allowedTypes: [String]
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack {
            PresetView()
        }
        .padding(25)
    }
}

 
