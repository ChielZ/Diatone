//
//  V4-S10 ParameterPage10View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 10 - PRESET MANAGEMENT

import SwiftUI
import UniformTypeIdentifiers

struct PresetView: View {
    // Connect to managers
    @ObservedObject private var presetManager = PresetManager.shared
    @ObservedObject private var paramManager = AudioParameterManager.shared
    
    // UI State
    @State private var selectedBank: Int = 1 // 1-5
    @State private var selectedPosition: Int = 1 // 1-5
    @State private var selectedType: PentatonePresetSlot.SlotType = .factory
    
    // Sheet/Alert State
    @State private var showingSaveDialog = false
    @State private var showingImportPicker = false
    @State private var showingExportSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var newPresetName: String = ""
    @State private var exportURL: URL?
    @State private var alertMessage: String?
    @State private var showingAlert = false
    
    var body: some View {
        Group {
            // Row 3 - Bank Navigation
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    // Previous Bank
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
                            previousBank()
                        }
                    
                    Spacer()
                    
                    // Bank Display
                    Text(bankDisplayText)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                    
                    Spacer()
                    
                    // Next Bank
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
                            nextBank()
                        }
                }
            }
            
            // Row 4 - Position Navigation
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    // Previous Position
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
                            previousPosition()
                        }
                    
                    Spacer()
                    
                    // Position Display (shows preset name if loaded)
                    Text(positionDisplayText)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Spacer()
                    
                    // Next Position
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
                            nextPosition()
                        }
                }
            }
            
            // Row 5 - Load/Save Preset
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(currentSlotPreset != nil ? Color("HighlightColour") : Color("SupportColour"))
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
                    .fill(Color("SupportColour"))
                GeometryReader { geometry in
                    Text("･IMPORT PRESET･")
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
            
            // Row 7 - Export Preset
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(currentSlotPreset != nil ? Color("SupportColour") : Color("BackgroundColour").opacity(1.0))
                GeometryReader { geometry in
                    Text("･EXPORT PRESET･")
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
            
            // Row 8 - Delete Preset (User only)
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(canDeleteCurrentSlot ? Color("SupportColour") : Color("BackgroundColour"))
                if canDeleteCurrentSlot {
                    GeometryReader { geometry in
                        Text("･DELETE PRESET･")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .padding(0)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingDeleteConfirmation = true
                    }
                }
            }
            
            // Row 9 - Info Display
            ZStack {
                
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
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
        // Save Dialog Sheet (no dimming)
        .background(
            DimmingRemoverView(isPresented: $showingSaveDialog) {
                savePresetDialog
            }
        )
        // Import File Picker
        .sheet(isPresented: $showingImportPicker) {
            DocumentPicker(allowedTypes: ["public.json", "com.yourname.arithmophone.preset"]) { url in
                handleImport(from: url)
            }
        }
        // Export Share Sheet
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        // Delete Confirmation
        .alert("Delete Preset", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                handleDelete()
            }
        } message: {
            if let preset = currentSlotPreset {
                Text("Are you sure you want to delete '\(preset.name)'? This cannot be undone.")
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
    }
    
    // MARK: - Computed Properties
    
    private var bankDisplayText: String {
        let prefix = selectedType == .factory ? "F" : "U"
        return "\(prefix) BANK \(selectedBank)"
    }
    
    private var positionDisplayText: String {
        let prefix = selectedType == .factory ? "F" : "U"
        let slotName = "\(prefix)\(selectedBank).\(selectedPosition)"
        
        if let preset = currentSlotPreset {
            return "\(slotName): \(preset.name)"
        } else {
            return "\(slotName) - Empty"
        }
    }
    
    private var currentSlotPreset: AudioParameterSet? {
        return presetManager.preset(forBank: selectedBank, position: selectedPosition, type: selectedType)
    }
    
    private var canDeleteCurrentSlot: Bool {
        guard selectedType == .user else { return false }
        return currentSlotPreset != nil
    }
    
    // MARK: - Navigation
    
    private func previousBank() {
        if selectedBank > 1 {
            selectedBank -= 1
        } else {
            // Wrap to bank 5, and toggle type
            selectedBank = 5
            selectedType = (selectedType == .factory) ? .user : .factory
        }
    }
    
    private func nextBank() {
        if selectedBank < 5 {
            selectedBank += 1
        } else {
            // Wrap to bank 1, and toggle type
            selectedBank = 1
            selectedType = (selectedType == .factory) ? .user : .factory
        }
    }
    
    private func previousPosition() {
        if selectedPosition > 1 {
            selectedPosition -= 1
        } else {
            selectedPosition = 5
        }
    }
    
    private func nextPosition() {
        if selectedPosition < 5 {
            selectedPosition += 1
        } else {
            selectedPosition = 1
        }
    }
    
    // MARK: - Actions
    
    private func handleLoadOrSave() {
        if let preset = currentSlotPreset {
            // Slot has preset - Load it
            presetManager.loadPreset(preset)
            showAlert("Loaded preset '\(preset.name)'")
        } else {
            // Slot is empty - Save current parameters
            if selectedType == .factory {
                showAlert("Cannot save to factory slots. Switch to user banks (U1-U5).")
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
            try presetManager.assignPresetToSlot(preset: newPreset, bank: selectedBank, position: selectedPosition)
            
            showAlert("Saved preset '\(newPresetName)' to \(selectedType == .factory ? "F" : "U")\(selectedBank).\(selectedPosition)")
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
            exportURL = try presetManager.exportPreset(preset)
            showingExportSheet = true
        } catch {
            showAlert("Failed to export preset: \(error.localizedDescription)")
        }
    }
    
    private func handleImport(from url: URL) {
        do {
            let preset = try presetManager.importPreset(from: url)
            showAlert("Imported preset '\(preset.name)'")
        } catch {
            showAlert("Failed to import preset: \(error.localizedDescription)")
        }
    }
    
    private func handleDelete() {
        guard let preset = currentSlotPreset else { return }
        
        do {
            // Clear slot first
            try presetManager.clearSlot(bank: selectedBank, position: selectedPosition)
            
            // Then delete preset
            try presetManager.deletePreset(preset)
            
            showAlert("Deleted preset '\(preset.name)'")
        } catch {
            showAlert("Failed to delete preset: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    // MARK: - Save Dialog View
    
    private var savePresetDialog: some View {
        ZStack {
            // Clear background for overFullScreen presentation
            Color.clear
                .ignoresSafeArea()
            
            // Centered dialog card
            VStack(spacing: 25) {
                // Title
                Text("SAVE PRESET")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("MontserratAlternates-Medium", size: 35)
                    .padding(.top, 40)
                
                // Subtitle
                Text("Name your sound")
                    .foregroundColor(Color("KeyColour1"))
                    .adaptiveFont("MontserratAlternates-Medium", size: 20)
                
                // Text field
                ZStack {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour").opacity(0.2))
                        .frame(height: 60)
                    
                    TextField("Enter preset name", text: $newPresetName)
                        .foregroundColor(Color("HighlightColour"))
                        .font(.custom("MontserratAlternates-Medium", size: 24))
                        .padding(.horizontal, 20)
                        .autocapitalization(.words)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                Spacer()
                
                // Buttons
                HStack(spacing: 20) {
                    // Cancel button
                    Button(action: {
                        newPresetName = ""
                        showingSaveDialog = false
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: radius)
                                .fill(Color("SupportColour"))
                                .frame(height: 60)
                            
                            Text("CANCEL")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 24)
                        }
                    }
                    
                    // Save button
                    Button(action: {
                        handleSave()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: radius)
                                .fill(newPresetName.isEmpty ? Color("KeyColour1").opacity(0.3) : Color("HighlightColour"))
                                .frame(height: 60)
                            
                            Text("SAVE")
                                .foregroundColor(Color("BackgroundColour"))
                                .adaptiveFont("MontserratAlternates-Medium", size: 24)
                        }
                    }
                    .disabled(newPresetName.isEmpty)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
            )
            .padding(40)
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

// MARK: - Share Sheet for Export

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Custom Sheet Without Dimming (iOS 15 Compatible)

struct DimmingRemoverView<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let content: () -> Content
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented && uiViewController.presentedViewController == nil {
            let hostingController = NoDimmingHostingController(rootView: content())
            hostingController.modalPresentationStyle = .overFullScreen
            hostingController.view.backgroundColor = .clear
            uiViewController.present(hostingController, animated: true)
        } else if !isPresented && uiViewController.presentedViewController != nil {
            uiViewController.dismiss(animated: true)
        }
    }
}

class NoDimmingHostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
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

 
