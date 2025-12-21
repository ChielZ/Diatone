# Phase 3: Visual Code Changes Summary

This document shows the key code changes in Phase 3 for quick reference.

---

## 1. MainKeyboardView.swift

### BEFORE:
```swift
struct MainKeyboardView: View {
    var currentScale: Scale = ScalesCatalog.centerMeridian_JI
    var currentKey: MusicalKey = .D
    // ... callbacks
    
    @State private var showingOptions: Bool = true
    
    var body: some View {
        // ...
        VStack {
            KeyButton(
                colorName: "KeyColour1",
                voiceIndex: 0,
                isLeftSide: true,
                trigger: { oscillator01.trigger() },
                release: { oscillator01.release() }
            )
            // ... 17 more buttons
        }
    }
}

private struct KeyButton: View {
    let voiceIndex: Int
    let trigger: () -> Void
    let release: () -> Void
    
    @State private var isDimmed = false
    
    var body: some View {
        // ... gesture handler
        .onChanged { value in
            if !hasFiredCurrentTouch {
                AudioParameterManager.shared.mapTouchToAmplitude(...)
                trigger()  // Calls oscillator01.trigger()
            }
        }
        .onEnded { _ in
            release()  // Calls oscillator01.release()
        }
    }
}
```

### AFTER:
```swift
struct MainKeyboardView: View {
    var currentScale: Scale = ScalesCatalog.centerMeridian_JI
    var currentKey: MusicalKey = .D
    // ... callbacks
    
    // 🆕 NEW: Phase 3 additions
    var keyboardState: KeyboardState
    var useNewVoiceSystem: Bool = true
    
    @State private var showingOptions: Bool = true
    
    var body: some View {
        // ...
        VStack {
            KeyButton(
                colorName: "KeyColour1",
                keyIndex: 0,                     // 🔄 renamed
                isLeftSide: true,
                keyboardState: keyboardState,    // 🆕 NEW
                useNewVoiceSystem: useNewVoiceSystem,  // 🆕 NEW
                oldSystemTrigger: { oscillator01.trigger() },  // 🔄 renamed
                oldSystemRelease: { oscillator01.release() }   // 🔄 renamed
            )
            // ... 17 more buttons
        }
    }
}

private struct KeyButton: View {
    let keyIndex: Int                        // 🔄 renamed from voiceIndex
    let keyboardState: KeyboardState         // 🆕 NEW
    let useNewVoiceSystem: Bool              // 🆕 NEW
    let oldSystemTrigger: (() -> Void)?      // 🔄 renamed, now optional
    let oldSystemRelease: (() -> Void)?      // 🔄 renamed, now optional
    
    @State private var isDimmed = false
    @State private var allocatedVoice: PolyphonicVoice? = nil  // 🆕 NEW
    
    var body: some View {
        // ... gesture handler
        .onChanged { value in
            if !hasFiredCurrentTouch {
                if useNewVoiceSystem {
                    // 🆕 NEW SYSTEM
                    let freq = keyboardState.frequencyForKey(at: keyIndex)
                    let voice = voicePool.allocateVoice(frequency: freq, forKey: keyIndex)
                    allocatedVoice = voice
                    voice.oscLeft.amplitude = amplitude
                    voice.oscRight.amplitude = amplitude
                } else {
                    // 🔧 OLD SYSTEM (still works)
                    AudioParameterManager.shared.mapTouchToAmplitude(...)
                    oldSystemTrigger?()
                }
            } else {
                // 🆕 NEW: Aftertouch handling
                if useNewVoiceSystem {
                    allocatedVoice?.filter.cutoffFrequency = newCutoff
                } else {
                    AudioParameterManager.shared.mapAftertouchToFilterCutoffSmoothed(...)
                }
            }
        }
        .onEnded { _ in
            if useNewVoiceSystem {
                // 🆕 NEW SYSTEM
                voicePool.releaseVoice(forKey: keyIndex)
                allocatedVoice = nil
            } else {
                // 🔧 OLD SYSTEM
                oldSystemRelease?()
            }
        }
    }
}
```

---

## 2. PentatoneApp.swift

### BEFORE:
```swift
@main
struct Penta_ToneApp: App {
    @State private var currentScaleIndex: Int = 0
    @State private var rotation: Int = 0
    @State private var musicalKey: MusicalKey = .D
    
    var body: some Scene {
        WindowGroup {
            MainKeyboardView(
                currentScale: currentScale,
                currentKey: musicalKey,
                // ... callbacks
            )
        }
    }
    
    private func applyCurrentScale() {
        let frequencies = makeKeyFrequencies(...)
        EngineManager.applyScale(frequencies: frequencies)
    }
}
```

### AFTER:
```swift
@main
struct Penta_ToneApp: App {
    @State private var currentScaleIndex: Int = 0
    @State private var rotation: Int = 0
    @State private var musicalKey: MusicalKey = .D
    
    // 🆕 NEW: Phase 3 additions
    @State private var keyboardState: KeyboardState = KeyboardState(
        scale: ScalesCatalog.centerMeridian_JI,
        key: .D
    )
    @State private var useNewVoiceSystem: Bool = true
    
    var body: some Scene {
        WindowGroup {
            MainKeyboardView(
                currentScale: currentScale,
                currentKey: musicalKey,
                // ... callbacks
                keyboardState: keyboardState,           // 🆕 NEW
                useNewVoiceSystem: useNewVoiceSystem    // 🆕 NEW
            )
        }
    }
    
    private func applyCurrentScale() {
        let frequencies = makeKeyFrequencies(...)
        
        // 🔧 OLD SYSTEM: Still works
        EngineManager.applyScale(frequencies: frequencies)
        
        // 🆕 NEW SYSTEM: Update KeyboardState
        keyboardState.updateScaleAndKey(scale: currentScale, key: musicalKey)
    }
}
```

---

## 3. Voice Allocation Flow

### OLD SYSTEM (Still Works):
```
User touches key 0
    ↓
KeyButton calls oldSystemTrigger()
    ↓
oscillator01.trigger() (hard-coded)
    ↓
AudioParameterManager applies parameters
    ↓
Note plays (oscillator01 always for key 0)
```

### NEW SYSTEM:
```
User touches key 0
    ↓
KeyButton checks useNewVoiceSystem = true
    ↓
Get frequency from keyboardState.frequencyForKey(0)
    ↓
Allocate voice: voicePool.allocateVoice(freq, forKey: 0)
    ↓
Store in @State allocatedVoice
    ↓
Apply amplitude directly to voice.oscLeft/oscRight
    ↓
Note plays (any available voice, tracked by pool)
```

---

## 4. Polyphony Comparison

### OLD SYSTEM:
```swift
// 18 hard-coded voices, 1 per key
oscillator01 → Key 0 (always)
oscillator02 → Key 1 (always)
oscillator03 → Key 2 (always)
...
oscillator18 → Key 17 (always)

// Max polyphony: 18 (all keys)
// Voice stealing: Not needed
// Memory: ~1.8 MB
```

### NEW SYSTEM:
```swift
// 5 dynamic voices, shared across keys
voice[0] → Any key (allocated dynamically)
voice[1] → Any key (allocated dynamically)
voice[2] → Any key (allocated dynamically)
voice[3] → Any key (allocated dynamically)
voice[4] → Any key (allocated dynamically)

// Max polyphony: 5 (any combination)
// Voice stealing: Oldest voice stolen when >5
// Memory: ~750 KB
```

---

## 5. Touch Mapping Changes

### OLD SYSTEM:
```swift
// Amplitude mapping (on touch down)
AudioParameterManager.shared.mapTouchToAmplitude(
    voiceIndex: voiceIndex,
    touchX: touchX,
    viewWidth: geometry.size.width
)
// → Updates oscillator amplitude via parameter manager

// Aftertouch mapping (on slide)
AudioParameterManager.shared.mapAftertouchToFilterCutoffSmoothed(
    voiceIndex: voiceIndex,
    initialTouchX: initialX,
    currentTouchX: touchX,
    viewWidth: geometry.size.width
)
// → Updates oscillator filter via parameter manager
```

### NEW SYSTEM:
```swift
// Amplitude mapping (on touch down)
let normalizedX = touchX / viewWidth
let amplitude = normalizedX * 0.8 + 0.2  // 0.2 to 1.0
voice.oscLeft.amplitude = AUValue(amplitude)
voice.oscRight.amplitude = AUValue(amplitude)
// → Direct node manipulation

// Aftertouch mapping (on slide)
let movement = currentX - initialX
let normalizedMovement = movement / viewWidth
let currentCutoff = Double(voice.filter.cutoffFrequency)
let cutoffDelta = normalizedMovement * currentCutoff * 0.5
let newCutoff = min(max(currentCutoff + cutoffDelta, 100), 10_000)
voice.filter.cutoffFrequency = AUValue(newCutoff)
// → Direct node manipulation
```

---

## 6. Feature Flag Usage

### To Switch Systems:

**Use New System (Polyphonic):**
```swift
// In PentatoneApp.swift
@State private var useNewVoiceSystem: Bool = true  // ← Change this

// Result:
// ✅ 5-voice polyphony
// ✅ Voice stealing
// ✅ Dynamic allocation
// ✅ Direct voice control
```

**Use Old System (1:1 Mapping):**
```swift
// In PentatoneApp.swift
@State private var useNewVoiceSystem: Bool = false  // ← Change this

// Result:
// ✅ 18 dedicated voices
// ✅ No voice stealing
// ✅ Fixed allocation
// ✅ Parameter manager control
```

---

## 7. Key Identifier Changes

### OLD SYSTEM:
```swift
voiceIndex: Int  // Always maps to specific oscillator
// voiceIndex 0 → oscillator01
// voiceIndex 1 → oscillator02
// etc.
```

### NEW SYSTEM:
```swift
keyIndex: Int  // Just identifies which keyboard key (0-17)
// keyIndex 0 → Any available voice
// keyIndex 1 → Any available voice
// etc.

// Mapping tracked in VoicePool.keyToVoiceMap
// keyToVoiceMap[0] = voice[2]  (dynamic)
// keyToVoiceMap[5] = voice[0]  (dynamic)
```

---

## 8. Dependencies Added

### Files that now depend on Phase 1-2:
```swift
// MainKeyboardView.swift needs:
import SwiftUI
// Implicitly uses:
// - VoicePool (global in AudioKitCode.swift)
// - PolyphonicVoice (imported via VoicePool)
// - KeyboardState (passed as parameter)

// PentatoneApp.swift needs:
import SwiftUI
import AudioKit
// Explicitly creates:
// - KeyboardState instance
// - useNewVoiceSystem flag
```

---

## 9. Console Output Comparison

### OLD SYSTEM:
```
(No voice allocation logs)
(Parameters applied silently via AudioParameterManager)
```

### NEW SYSTEM:
```
🎵 VoicePool initialized with 5 voices
🎹 Key 0: Allocated voice, freq 146.83 Hz, amp 0.65
🎹 Key 5: Allocated voice, freq 220.00 Hz, amp 0.80
🎹 Key 0: Released voice
🎹 Key 5: Released voice
⚠️ Voice stealing: Took voice triggered at 2025-12-21 10:23:45 +0000
```

---

## 10. What Didn't Change

**These remain unchanged:**
- ✅ Scale/key management logic
- ✅ UI layout and appearance
- ✅ Color coding system
- ✅ Options menu
- ✅ Navigation strip
- ✅ Rotation system
- ✅ Device orientation handling
- ✅ AudioKit engine initialization
- ✅ Effects (delay, reverb)

**Old system still fully functional:**
- ✅ oscillator01-18 still exist
- ✅ AudioParameterManager still works
- ✅ EngineManager.applyScale() still called
- ✅ Can switch back anytime with feature flag

---

## Summary of Changes

| Aspect | Old System | New System |
|--------|-----------|------------|
| **Voices** | 18 fixed (oscillator01-18) | 5 dynamic (VoicePool) |
| **Allocation** | 1:1 key mapping | Dynamic allocation |
| **Polyphony** | Up to 18 notes | 5 notes + stealing |
| **Parameter Control** | AudioParameterManager | Direct node manipulation |
| **Frequency Source** | Hard-coded per voice | KeyboardState (dynamic) |
| **Memory** | ~1.8 MB | ~750 KB |
| **Voice Stealing** | N/A | Oldest voice |
| **Feature Flag** | N/A | `useNewVoiceSystem` |

---

**Phase 3 Code Changes:** ✅ **Complete and Ready for Testing**

See `PHASE_3_COMPLETE.md` for full implementation summary.

