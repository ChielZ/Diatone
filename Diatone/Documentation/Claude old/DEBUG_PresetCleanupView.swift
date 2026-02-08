//
//  DEBUG_PresetCleanupView.swift
//  Pentatone
//
//  DEBUG TOOL - Remove this file before release
//

/*

import SwiftUI

/// Debug view to see and delete orphaned preset files
/// These are presets that exist on disk but aren't in any slot
struct PresetCleanupView: View {
    @ObservedObject private var presetManager = PresetManager.shared
    @State private var orphanedPresets: [AudioParameterSet] = []
    @State private var allPresetFiles: [String] = []
    @State private var showingDeleteConfirmation = false
    @State private var presetToDelete: AudioParameterSet?
    @State private var alertMessage: String?
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Statistics")) {
                    HStack {
                        Text("Factory Presets")
                        Spacer()
                        Text("\(presetManager.factoryPresetCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("User Presets Loaded")
                        Spacer()
                        Text("\(presetManager.userPresetCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Preset Files on Disk")
                        Spacer()
                        Text("\(allPresetFiles.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Orphaned Presets")
                        Spacer()
                        Text("\(orphanedPresets.count)")
                            .foregroundColor(orphanedPresets.count > 0 ? .orange : .secondary)
                    }
                }
                
                if orphanedPresets.isEmpty {
                    Section {
                        Text("No orphaned presets found")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                } else {
                    Section(header: Text("Orphaned Presets (Not in Any Slot)")) {
                        ForEach(orphanedPresets) { preset in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.name)
                                        .font(.headline)
                                    Text("Created: \(formatDate(preset.createdAt))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("ID: \(preset.id.uuidString.prefix(8))...")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(role: .destructive) {
                                    presetToDelete = preset
                                    showingDeleteConfirmation = true
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Refresh Analysis") {
                        analyzePresets()
                    }
                    
                    if !orphanedPresets.isEmpty {
                        Button(role: .destructive) {
                            deleteAllOrphaned()
                        } label: {
                            Text("Delete All Orphaned Presets (\(orphanedPresets.count))")
                        }
                    }
                }
            }
            .navigationTitle("Preset Cleanup")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                analyzePresets()
            }
        }
        .alert("Delete Preset", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let preset = presetToDelete {
                    deletePreset(preset)
                }
            }
        } message: {
            if let preset = presetToDelete {
                Text("Delete '\(preset.name)'? This cannot be undone.")
            }
        }
        .alert("Preset Cleanup", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let message = alertMessage {
                Text(message)
            }
        }
    }
    
    // MARK: - Analysis
    
    private func analyzePresets() {
        // Get all preset files from disk
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let userPresetsURL = documentsURL.appendingPathComponent("UserPresets")
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: userPresetsURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ).filter {
                $0.pathExtension == "json" &&
                $0.lastPathComponent != "UserLayout.json"
            }
            
            allPresetFiles = fileURLs.map { $0.lastPathComponent }
            
            // Get all preset IDs that are assigned to slots
            var assignedPresetIDs = Set<UUID>()
            
            // Check factory slots
            for slot in presetManager.factoryLayout {
                if let presetID = slot.presetID {
                    assignedPresetIDs.insert(presetID)
                }
            }
            
            // Check user slots
            for slot in presetManager.userLayout.userSlots {
                if let presetID = slot.presetID {
                    assignedPresetIDs.insert(presetID)
                }
            }
            
            // Find orphaned presets (loaded but not assigned to any slot)
            orphanedPresets = presetManager.userPresets.filter { preset in
                !assignedPresetIDs.contains(preset.id)
            }
            
            print("📊 Preset Analysis:")
            print("   - Total preset files: \(allPresetFiles.count)")
            print("   - Loaded user presets: \(presetManager.userPresetCount)")
            print("   - Assigned to slots: \(assignedPresetIDs.count)")
            print("   - Orphaned: \(orphanedPresets.count)")
            
        } catch {
            showAlert("Failed to analyze presets: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Actions
    
    private func deletePreset(_ preset: AudioParameterSet) {
        do {
            try presetManager.deletePreset(preset)
            analyzePresets() // Refresh
            showAlert("Deleted '\(preset.name)'")
        } catch {
            showAlert("Failed to delete: \(error.localizedDescription)")
        }
    }
    
    private func deleteAllOrphaned() {
        let count = orphanedPresets.count
        var deletedCount = 0
        var errors: [String] = []
        
        for preset in orphanedPresets {
            do {
                try presetManager.deletePreset(preset)
                deletedCount += 1
            } catch {
                errors.append(preset.name)
            }
        }
        
        analyzePresets() // Refresh
        
        if errors.isEmpty {
            showAlert("Successfully deleted \(deletedCount) orphaned presets")
        } else {
            showAlert("Deleted \(deletedCount) of \(count) presets. Failed: \(errors.joined(separator: ", "))")
        }
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    PresetCleanupView()
}
*/
