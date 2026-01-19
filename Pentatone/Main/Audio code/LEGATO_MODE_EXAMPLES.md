# Legato Mode - Code Examples

## Example 1: Simple Toggle in Settings

If you have a settings view, you can add a toggle for legato mode:

```swift
// In your Settings view or wherever you control synth parameters
struct SynthSettingsView: View {
    @ObservedObject var audioEngine: AudioEngine  // Or however you access your engine
    @State private var isLegatoEnabled = false
    
    var body: some View {
        Form {
            Section("Monophonic Mode Settings") {
                Toggle("Legato Mode", isOn: $isLegatoEnabled)
                    .onChange(of: isLegatoEnabled) { newValue in
                        audioEngine.voicePool.legatoMode = newValue
                    }
            }
        }
    }
}
```

## Example 2: Combined Polyphony and Legato Control

If you want to control both polyphony and legato together:

```swift
struct VoiceModeControl: View {
    @ObservedObject var audioEngine: AudioEngine
    @State private var isMonophonic = false
    @State private var isLegatoEnabled = false
    
    var body: some View {
        VStack {
            // Polyphony toggle
            Toggle("Monophonic", isOn: $isMonophonic)
                .onChange(of: isMonophonic) { newValue in
                    let voiceCount = newValue ? 1 : nominalPolyphony
                    audioEngine.voicePool.setPolyphony(voiceCount) {
                        print("Switched to \(newValue ? "mono" : "poly") mode")
                    }
                }
            
            // Legato toggle (only enabled in monophonic mode)
            Toggle("Legato", isOn: $isLegatoEnabled)
                .disabled(!isMonophonic)
                .onChange(of: isLegatoEnabled) { newValue in
                    audioEngine.voicePool.legatoMode = newValue
                }
        }
    }
}
```

## Example 3: Preset Integration

If you want legato mode to be part of presets:

```swift
// 1. Add to your VoiceParameters or a new struct
struct VoicePlayParameters: Codable {
    var polyphony: Int = nominalPolyphony
    var legatoMode: Bool = false
}

// 2. When loading a preset
func loadPreset(_ preset: Preset) {
    // ... load other parameters ...
    
    // Set polyphony
    voicePool.setPolyphony(preset.playParameters.polyphony) {
        // Set legato after polyphony change completes
        voicePool.legatoMode = preset.playParameters.legatoMode
    }
}

// 3. When saving a preset
func saveCurrentAsPreset() -> Preset {
    var preset = Preset()
    
    // ... save other parameters ...
    
    preset.playParameters = VoicePlayParameters(
        polyphony: currentPolyphony,
        legatoMode: voicePool.legatoMode
    )
    
    return preset
}
```

## Example 4: Direct Access in AudioEngine

If you have an AudioEngine class, you can expose legato as a property:

```swift
class AudioEngine: ObservableObject {
    let voicePool: VoicePool
    
    // ... other properties ...
    
    // Published property for SwiftUI binding
    @Published var legatoMode: Bool = false {
        didSet {
            voicePool.legatoMode = legatoMode
        }
    }
    
    // Convenience method to switch modes
    func setMonophonicMode(enabled: Bool, legato: Bool = false) {
        let voiceCount = enabled ? 1 : nominalPolyphony
        voicePool.setPolyphony(voiceCount) { [weak self] in
            self?.legatoMode = legato
        }
    }
}

// Usage in SwiftUI
struct ControlPanel: View {
    @ObservedObject var audioEngine: AudioEngine
    
    var body: some View {
        Toggle("Legato", isOn: $audioEngine.legatoMode)
    }
}
```

## Example 5: Keyboard Shortcut

Add a keyboard shortcut to toggle legato mode:

```swift
struct ContentView: View {
    @ObservedObject var audioEngine: AudioEngine
    
    var body: some View {
        YourMainView()
            .keyboardShortcut("l", modifiers: [.command]) {
                // Toggle legato mode
                audioEngine.voicePool.legatoMode.toggle()
                print("Legato mode: \(audioEngine.voicePool.legatoMode ? "ON" : "OFF")")
            }
    }
}
```

## Example 6: Testing in Playgrounds or Debug

Quick test without UI:

```swift
// In your test or debug code
func testLegatoMode() {
    // Switch to mono
    voicePool.setPolyphony(1) {
        // Enable legato
        voicePool.legatoMode = true
        
        // Simulate note sequence
        // Note 1: Normal trigger
        voicePool.allocateVoice(frequency: 440.0, forKey: 0, initialTouchX: 0.5)
        
        // Wait a bit (simulate user holding note)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Note 2: Legato retrigger (while note 1 still playing)
            voicePool.allocateVoice(frequency: 523.25, forKey: 2, initialTouchX: 0.6)
            
            // Release first note (no effect - note 2 owns voice)
            voicePool.releaseVoice(forKey: 0)
            
            // Release second note (triggers release)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                voicePool.releaseVoice(forKey: 2)
            }
        }
    }
}
```

## Example 7: Context Menu (iOS)

Add legato toggle to a context menu:

```swift
.contextMenu {
    Button(action: {
        voicePool.legatoMode.toggle()
    }) {
        Label(
            voicePool.legatoMode ? "Disable Legato" : "Enable Legato",
            systemImage: voicePool.legatoMode ? "checkmark.circle.fill" : "circle"
        )
    }
}
```

## Notes

- Legato mode only works in monophonic mode (`currentPolyphony == 1`)
- The flag can be toggled at any time, but only takes effect when conditions are met
- No need to stop/restart audio engine when changing legato mode
- The implementation is thread-safe (can be toggled from main thread while audio is running)
