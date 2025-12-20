# Phase 1-2 Architectural Decisions & Updates

## Document Purpose
This document captures key architectural decisions made during Phases 1, 1.5, and 2 implementation, and updates to the original plan based on real-world testing and sonic considerations.

---

## Major Decisions

### 1. Detune Mode Implementation (Phase 1.5)

**Added Feature:** Dual detune modes for stereo spread

**Proportional Mode (Default):**
- Constant cents detuning (multiplier/divider)
- Higher notes beat faster (natural)
- Range: 1.0 to 1.01 (0 to 34 cents)
- Sweet spot: ~1.005 (17 cents)

**Constant Mode:**
- Fixed Hz offset (addition/subtraction)
- All notes beat at same rate (uniform)
- Range: 0 to 2.5 Hz (0 to 5 Hz beat rate)
- Sweet spot: 0.5-1 Hz (subtle richness)

**Outcome:** Both modes sound excellent. Constant mode at ~0.5-1 Hz provides subtle richness without obvious beating - perfect for adding dimension!

---

### 2. Phase 4 Elimination ✅

**Original Plan:** Expand voice parameters for dual oscillators with:
- Separate parameters per oscillator
- Different waveforms L/R
- Mix control
- Independent amplitude

**Decision:** SKIP PHASE 4 ENTIRELY

**Reasoning:**
- Both oscillators should behave identically (except tuning offset)
- No need for per-oscillator parameter differences
- Current architecture already provides everything needed
- Dual oscillators + detune modes = perfect stereo character

**Implementation Impact:**
- Phase 1 architecture is final for oscillators
- No additional oscillator parameters needed
- Cleaner, simpler codebase
- Reduced development time by ~1-2 days

---

### 3. FM Envelope Architecture (Phase 5 Preparation)

**Question:** How to implement FM modulation envelopes?

**Options Considered:**

**Option A: Static Modulation**
- Keep current simple architecture
- No timbral evolution
- ❌ Rejected - too limiting

**Option B: Hybrid (CHOSEN)**
- Keep AmplitudeEnvelope for output volume
- Add ModulationEnvelope for FM modulationIndex
- Fixed carrier level (no separate carrier envelope)
- ✅ Best balance of simplicity and expressiveness

**Option C: Full Traditional FM**
- Separate carrier and modulator envelopes
- Maximum complexity
- ❌ Rejected - unnecessary complexity

**Selected: Option B (Hybrid Approach)**

**Architecture:**
```
FMOscillators (L+R)
├─ Carrier level: Fixed
├─ Modulator level: Controlled by ModulationEnvelope
└─ modulationIndex updated at control-rate (60 Hz)
       ↓
    Mixer → Filter → AmplitudeEnvelope → Output
                            ↑
                    Volume control (existing)
```

**Benefits:**
- ✅ Simple volume control (existing AmplitudeEnvelope)
- ✅ FM timbral evolution (ModulationEnvelope on modulationIndex)
- ✅ Classic FM sounds possible (bells, brass, evolving pads)
- ✅ Per-preset control (some presets static, some dynamic)
- ✅ Moderate complexity, maximum expressiveness

**Sonic Capabilities:**
- Static modulation: Set depth to 0 (simple tones)
- Dynamic modulation: Full FM evolution (bright → warm)
- Classic FM: All iconic sounds achievable
- No compromise in expressiveness vs. traditional FM

---

## Updated Phase 5 Implementation Notes

### Modulation System Architecture

**Per-Voice Modulation:**
- ModulationEnvelope → FM modulationIndex (timbral evolution)
- Voice LFO → Filter cutoff, frequency offset, etc.

**Global Modulation:**
- Global LFO → Delay time, reverb mix, master parameters

**Control Rate:**
- ~60 Hz update loop
- Updates modulation values
- Applies to AudioKit node parameters

**Implementation in PolyphonicVoice:**
```swift
class PolyphonicVoice {
    let modulationEnvelope: ModulationEnvelope
    private var triggerTime: Date?
    
    func applyModulation() {
        guard let triggerTime = triggerTime else { return }
        
        let timeSinceTrigger = Date().timeIntervalSince(triggerTime)
        let modEnvValue = modulationEnvelope.currentValue(
            timeInEnvelope: timeSinceTrigger,
            isGateOpen: !isAvailable
        )
        
        // Apply to both oscillators
        let targetModIndex = baseModulationIndex * modEnvValue
        oscLeft.modulationIndex = AUValue(targetModIndex)
        oscRight.modulationIndex = AUValue(targetModIndex)
    }
}
```

---

## Preset Design Implications

### Example Preset Configurations

**Simple Presets (Static FM):**
```swift
// Preset: "Keys" (Wurlitzer-esque)
modulationEnvelope.depth = 0.0  // No modulation movement
modulationIndex = 0.8  // Fixed bright tone
amplitudeEnvelope.attack = 0.01, release = 0.3
detuneMode = .proportional, offset = 1.005
```

**Dynamic Presets (Evolving FM):**
```swift
// Preset: "Brass" (Evolving timbre)
modulationEnvelope.attack = 0.02, decay = 0.3, sustain = 0.3
modulationEnvelope.depth = 0.8  // Strong evolution
modulationIndex = 1.2  // Maximum modulation
amplitudeEnvelope.attack = 0.05, sustain = 0.9
detuneMode = .proportional, offset = 1.003
```

**Percussive Presets (Bell-like):**
```swift
// Preset: "Sticks" (Glockenspiel-esque)
modulationEnvelope.attack = 0.0, decay = 2.0
modulationEnvelope.depth = 1.0  // Maximum evolution
modulationIndex = 1.5  // Very bright
amplitudeEnvelope.attack = 0.0, decay = 1.5
detuneMode = .constant, offset = 0.8  // Subtle shimmer
```

---

## Testing Insights

### Detune Sweet Spots

**Proportional Mode:**
- Minimum (1.0): Mono, useful for comparing
- Low (1.002-1.003): Subtle width, ~7-10 cents
- **Sweet spot (1.005):** Rich without obvious beating, ~17 cents
- High (1.008-1.01): Obvious chorus, ~27-34 cents

**Constant Mode:**
- Minimum (0.0): Mono
- **Sweet spot (0.5-1.0 Hz):** Subtle richness, not consciously perceptible
- Medium (1.5-2.0 Hz): Gentle chorus
- High (2.0-2.5 Hz): Obvious beating

### Observations:
- Constant mode's sweet spot is much lower than initially expected
- ~0.5-1 Hz total difference adds huge richness without being noticeable
- Both modes have distinct musical characters
- Proportional likely better default for most presets
- Constant excellent for specific sounds (bass, electronic)

---

## Phase Completion Status

**✅ Phase 1 (Complete):**
- Polyphonic voice pool (5 voices, configurable 3-12)
- Stereo dual-oscillator architecture
- Round-robin allocation with voice stealing
- Key-to-voice mapping

**✅ Phase 1.5 (Complete):**
- Proportional detune mode (constant cents)
- Constant detune mode (constant Hz)
- Segmented control in test view
- Mode-specific sliders and displays

**✅ Phase 2 (Complete):**
- KeyboardState class for frequency management
- Scale/key property cycling helpers
- Reactive @Published properties
- Integration with test view

**🎯 Phase 3 (Next):**
- Integrate VoicePool into MainKeyboardView
- Remove dependency on oscillator01-18
- **CRITICAL TRANSITION POINT**
- Start fresh conversation recommended

---

## Development Velocity & Quality

### Stats:
- **Phases completed:** 3 (1, 1.5, 2)
- **Time taken:** ~1 day
- **Build status:** Compiles, deploys to device ✅
- **No warnings:** Clean build ✅
- **Old functionality:** Fully preserved ✅

### Code Quality:
- Clean architecture
- Well-documented
- Extensive inline comments
- Multiple reference documents
- Easy to understand and maintain

---

## Recommendations for Phase 3+

### Phase 3 (MainKeyboardView Transition):
1. Start fresh conversation (critical phase)
2. Provide context from plan document
3. Mention Phase 4 is skipped
4. Reference KeyboardState and VoicePool implementations
5. Test thoroughly before proceeding to Phase 5

### Phase 5 (Modulation):
1. Implement ModulationEnvelope for modulationIndex first
2. Test FM timbral evolution independently
3. Add control-rate update loop
4. Implement Voice LFO
5. Implement Global LFO
6. Test each modulation source independently

### Phase 6 (Presets):
1. Design preset parameter sets early
2. Test each preset for sonic character
3. Ensure modulationEnvelope settings vary appropriately
4. Use both detune modes across different presets
5. Document preset sonic goals clearly

---

## Architectural Strengths

**What's Working Well:**
- ✅ Dual oscillator architecture is perfect for stereo richness
- ✅ Detune modes provide excellent sonic variety
- ✅ KeyboardState cleanly separates concerns
- ✅ VoicePool manages polyphony elegantly
- ✅ Parallel old/new systems allow safe testing
- ✅ Hybrid FM approach provides maximum expressiveness with moderate complexity

**What to Watch:**
- ⚠️ Phase 3 transition is critical (test thoroughly!)
- ⚠️ Phase 5 modulation timing needs careful testing
- ⚠️ CPU usage to monitor as complexity increases
- ⚠️ Preset design will require sonic expertise and iteration

---

## Final Notes

This implementation has exceeded expectations in code quality, sonic results, and development velocity. The architectural decisions made (especially skipping Phase 4 and choosing hybrid FM) will result in a cleaner, more maintainable codebase with no compromise in sonic capabilities.

The stereo detune character discovered during testing (subtle constant mode at 0.5-1 Hz) is a wonderful example of how real-world testing reveals sonic sweet spots that theoretical planning might miss.

Ready for Phase 3 with confidence! 🚀

---

**Date:** December 20, 2025  
**Phases Complete:** 1, 1.5, 2  
**Build Status:** ✅ Clean build, deploys to device, no warnings  
**Next Phase:** 3 (Critical transition - start fresh conversation)
