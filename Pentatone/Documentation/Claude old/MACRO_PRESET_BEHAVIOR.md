# Macro Control & Preset Behavior

## Design Philosophy: "Performance Control" Approach

Your app uses the **"Performance Control"** approach to macro controls, matching professional software synthesizers like Serum, Massive, and Omnisphere.

---

## How It Works

### **Key Concept:**
Macro controls (Volume, Tone, Ambience) are **realtime performance tools**, not preset parameters.

When you save a preset:
- ✅ **Final parameter values** are saved (after macro adjustments)
- ✅ **Macro ranges** are saved (per-preset control ranges)
- ✅ **Macro positions** are reset to center (0.0)

When you load a preset:
- ✅ Parameters load at their saved values
- ✅ Macros start at **neutral/center position**
- ✅ Macros are ready to modulate from the preset's base sound

---

## Example Workflow

### **Creating a Preset:**

1. **Edit sound parameters:**
   - Set filter cutoff to 1000 Hz
   - Set modulation index to 3.0
   - Set delay feedback to 0.5

2. **Move Tone macro to +0.5 (halfway up):**
   - Modulation index → 4.25 (increased by macro)
   - Filter cutoff → 2000 Hz (increased by macro)
   - Saturation → 2.5 (increased by macro)

3. **Save preset as "Bright Lead":**
   - Base modulation index: **4.25** (current value)
   - Base filter cutoff: **2000 Hz** (current value)
   - Base saturation: **2.5** (current value)
   - Tone position: **0.0** (reset to center)

4. **Result:**
   - Preset stores the "bright" sound you created
   - Tone macro resets to center, ready for live performance

---

### **Loading a Preset:**

1. **Load "Bright Lead":**
   - Filter cutoff loads at 2000 Hz ✅
   - Modulation index loads at 4.25 ✅
   - Saturation loads at 2.5 ✅
   - **Tone macro is at center (0.0)** ✅

2. **Macros are ready:**
   - Move Tone down → Sound gets darker
   - Move Tone up → Sound gets brighter
   - Move Ambience up → Add reverb/delay

3. **You hear the preset as saved, but can tweak it live!**

---

## Why This Design?

### **Advantages:**
- ✅ **Predictable:** Macros always start at center
- ✅ **Performance-ready:** Macros available for live tweaking
- ✅ **Intuitive:** Load preset → hear saved sound → tweak with macros
- ✅ **Professional:** Matches industry-standard synths
- ✅ **Clean mental model:** Presets = sounds, Macros = performance tools

### **Compared to "Stored Position" approach:**
- ❌ Stored position: Macros load at random positions (+0.3, -0.7, etc.)
- ❌ Stored position: User confused: "Why is Tone already moved?"
- ❌ Stored position: Macros less useful for live performance

---

## Technical Implementation

### **Saving Presets:**

When `saveCurrentAsNewPreset()` is called:
1. `captureCurrentAsBase()` is called
2. Current parameter values → become new base values
3. Macro positions → reset to 0.0 (center)
4. Preset is saved with these values

### **Loading Presets:**

When `loadPreset()` is called:
1. `macroState` is loaded (has positions at 0.0)
2. `voiceTemplate` and `master` are loaded (final values)
3. Parameters are applied to audio engine
4. Macros are at center, ready for performance

### **During Performance:**

When user moves a macro (e.g., Tone to +0.5):
1. `updateToneMacro(0.5)` is called
2. Calculates: `newValue = baseValue + (position × range)`
3. Updates parameters in real-time
4. Audio engine responds immediately

---

## What's Saved in Presets

### **Per-Preset (Saved):**
- ✅ All final parameter values (filter, envelope, oscillator, etc.)
- ✅ Macro control **ranges** (how much each macro affects parameters)
- ✅ Macro **base values** (neutral parameter values before macro movement)
- ✅ Macro **positions** at 0.0 (always center)

### **Not Saved (Realtime Only):**
- ❌ Current macro knob positions during performance
- ❌ Temporary parameter adjustments from macro movements

---

## User Experience

### **What Users Experience:**

1. **Tweak parameters** and **move macros** while designing sound
2. **Save preset** → Current sound is captured
3. **Load preset later** → Sound is exactly as saved
4. **Macros are at center** → Ready to tweak the preset live
5. **Move macros during performance** → Real-time sound variations
6. **Presets stay unchanged** → Only current session is affected

### **Mental Model:**

- **Preset = A snapshot of your sound**
- **Macros = Live performance controls**
- **Saving "bakes in" the current sound, resets macros**
- **Loading gives you that sound + fresh macros to play with**

---

## Examples from Other Synths

### **This Approach (Performance Control):**
- ✅ Serum
- ✅ Massive X
- ✅ Omnisphere
- ✅ Pigments
- ✅ Diva

### **Alternative Approach (Stored Position):**
- Korg Minilogue (hardware)
- Some older hardware synths
- Simpler but less flexible

---

## Future Considerations

### **Possible Enhancements (Optional):**

1. **Macro Position Snapshots:**
   - Save separate "performance snapshots" with macro positions
   - Load preset + optionally load a snapshot

2. **Reset Macros Button:**
   - Quick way to return macros to center during performance

3. **Macro Range Editing:**
   - UI to adjust how much each macro affects each parameter
   - Currently stored per-preset but not user-editable

4. **A/B Comparison:**
   - Store current state
   - Load preset
   - Toggle between original and new sound

---

## Summary

Your macro system uses the **professional "Performance Control" approach**:
- Presets save final sounds
- Macros reset to center on load
- Macros available for real-time performance
- Predictable, intuitive, industry-standard

This is the **correct design** for a modern software instrument! 🎵
