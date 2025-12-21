# Phase 1 - Voice Pool Architecture Diagram

## Overview
This document provides a visual reference for understanding the new voice pool architecture.

---

## Single PolyphonicVoice Internal Structure

```
┌──────────────────────────────────────────────────────────────┐
│                     PolyphonicVoice                          │
│                                                              │
│  baseFrequency: 293.66 Hz (D4)                              │
│  frequencyOffset: 1.005 (±8.6 cents)                        │
│                                                              │
│  ┌─────────────────────────────┐                            │
│  │ oscLeft: FMOscillator       │                            │
│  │ frequency: 293.66 × 1.005   │                            │
│  │         = 295.13 Hz         │                            │
│  └──────────────┬──────────────┘                            │
│                 │                                            │
│                 ▼                                            │
│  ┌─────────────────────────────┐                            │
│  │ panLeft: Panner             │                            │
│  │ pan: -1.0 (hard left)       │                            │
│  └──────────────┬──────────────┘                            │
│                 │                                            │
│                 │   ┌────────────────────────────┐          │
│                 └──►│                            │          │
│                     │  stereoMixer: Mixer        │          │
│  ┌─────────────────────────────┐  │                        │          │
│  │ oscRight: FMOscillator      │  │                        │          │
│  │ frequency: 293.66 ÷ 1.005   │  │                        │          │
│  │         = 292.20 Hz         │  │                        │          │
│  └──────────────┬──────────────┘  │                        │          │
│                 │                  │                        │          │
│                 ▼                  │                        │          │
│  ┌─────────────────────────────┐  │                        │          │
│  │ panRight: Panner            │  │                        │          │
│  │ pan: +1.0 (hard right)      │  │                        │          │
│  └──────────────┬──────────────┘  │                        │          │
│                 │                  │                        │          │
│                 └─────────────────►│                        │          │
│                                    └────────────┬───────────┘          │
│                                                 │                      │
│                                                 ▼                      │
│                                    ┌────────────────────────┐         │
│                                    │ filter: LowPassFilter  │         │
│                                    │ (processes stereo)     │         │
│                                    └────────────┬───────────┘         │
│                                                 │                      │
│                                                 ▼                      │
│                                    ┌────────────────────────┐         │
│                                    │ envelope:              │         │
│                                    │ AmplitudeEnvelope      │         │
│                                    │ (shapes stereo)        │         │
│                                    └────────────┬───────────┘         │
│                                                 │                      │
│                                                 ▼                      │
│                                              Output                    │
│                                         (stereo signal)                │
└──────────────────────────────────────────────────────────────────────┘
```

**Key Points:**
- Two oscillators at slightly different frequencies create stereo width
- Hard panning (L/R) maximizes stereo separation
- Symmetric offset: one higher, one lower by same ratio
- Signal merges before filter (processes as stereo, not separate L/R filters)

---

## VoicePool Management System

```
┌────────────────────────────────────────────────────────────────┐
│                         VoicePool                              │
│                    (5 voices, round-robin)                     │
│                                                                │
│  voices: [PolyphonicVoice]                                    │
│  currentVoiceIndex: Int (round-robin pointer)                 │
│  keyToVoiceMap: [Int: PolyphonicVoice]                        │
│                                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Voice 0  │  │ Voice 1  │  │ Voice 2  │  │ Voice 3  │ ... │
│  │ Key: 5   │  │ Key: 12  │  │ Key: --  │  │ Key: 7   │     │
│  │ Playing  │  │ Playing  │  │ Available│  │ Playing  │     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘     │
│       │             │             │             │            │
│       │             │             │             │            │
│       └─────────────┴─────────────┴─────────────┘            │
│                             │                                 │
│                   ┌─────────▼──────────┐                     │
│                   │  voiceMixer: Mixer │                     │
│                   │  (combines all 5)  │                     │
│                   └─────────┬──────────┘                     │
│                             │                                 │
└─────────────────────────────┼─────────────────────────────────┘
                              │
                              ▼
                     To effects chain
```

**Key Points:**
- 5 voices shared among 18 keys
- Round-robin allocation: cycles through voices 0→1→2→3→4→0...
- Key-to-voice mapping tracks which key controls which voice
- Available voices reused first, oldest voice stolen if all busy

---

## Voice Allocation Flow

### Scenario 1: Triggering a Note (Available Voice)

```
User touches Key 5 (frequency: 440 Hz)
           │
           ▼
   ┌───────────────────┐
   │ findAvailableVoice│
   └───────┬───────────┘
           │
           ▼
   Is Voice 2 available? ✅ YES
           │
           ▼
   ┌───────────────────────────────┐
   │ voice.setFrequency(440)       │
   │ voice.trigger()               │
   │ voice.isAvailable = false     │
   │ voice.triggerTime = now       │
   │ keyToVoiceMap[5] = voice      │
   │ currentVoiceIndex++           │
   └───────────────────────────────┘
           │
           ▼
   Key 5 now playing on Voice 2
```

### Scenario 2: Triggering a Note (Voice Stealing)

```
User touches Key 10 (all voices busy)
           │
           ▼
   ┌───────────────────┐
   │ findAvailableVoice│
   └───────┬───────────┘
           │
           ▼
   Check all voices... ❌ ALL BUSY
           │
           ▼
   ┌─────────────────────────────┐
   │ Find oldest voice:          │
   │ Voice 0 (triggered 2s ago)  │
   │ Voice 1 (triggered 1.8s ago)│
   │ Voice 2 (triggered 1.5s ago)│ ← Oldest!
   │ Voice 3 (triggered 1.0s ago)│
   │ Voice 4 (triggered 0.5s ago)│
   └──────────┬──────────────────┘
              │
              ▼
   ┌────────────────────────────┐
   │ voice2.envelope.closeGate()│ (instant cutoff)
   │ voice2.isAvailable = true  │
   │ Use voice2 for new note    │
   └────────────┬───────────────┘
              │
              ▼
   ┌───────────────────────────────┐
   │ voice2.setFrequency(523.25)   │ (Key 10 freq)
   │ voice2.trigger()              │
   │ keyToVoiceMap[10] = voice2    │
   └───────────────────────────────┘
              │
              ▼
   Key 10 now playing on Voice 2
   (previous key was stolen)
```

### Scenario 3: Releasing a Note

```
User releases Key 5
           │
           ▼
   ┌────────────────────────────┐
   │ Look up keyToVoiceMap[5]   │
   │ → Returns Voice 2          │
   └────────────┬───────────────┘
                │
                ▼
   ┌────────────────────────────┐
   │ voice2.release()           │
   │ → envelope.closeGate()     │
   │ keyToVoiceMap.remove(5)    │
   └────────────┬───────────────┘
                │
                ▼
   ┌────────────────────────────────┐
   │ Async: Wait for release time   │
   │ (e.g., 0.3 seconds)            │
   └────────────┬───────────────────┘
                │
       Wait 0.3s │
                ▼
   ┌────────────────────────────┐
   │ voice2.isAvailable = true  │
   └────────────────────────────┘
                │
                ▼
   Voice 2 ready for reuse
```

---

## Complete Audio Signal Chain (Phase 1)

```
┌─────────────────────────────────────────────────────────────────┐
│                     Audio Engine Architecture                   │
└─────────────────────────────────────────────────────────────────┘

OLD SYSTEM (18 voices):
┌──────────┐   ┌──────────┐            ┌──────────┐
│oscillator│   │oscillator│    ...     │oscillator│
│    01    │   │    02    │            │    18    │
└────┬─────┘   └────┬─────┘            └────┬─────┘
     │              │                       │
     └──────────────┴───────────────────────┘
                    │
         ┌──────────▼──────────┐
         │  voiceMixer (old)   │
         └──────────┬──────────┘
                    │
                    │
NEW SYSTEM (5 voices):                   │
┌──────────┐   ┌──────────┐   ┌──────────┐
│ Poly     │   │ Poly     │   │ Poly     │
│ Voice 0  │   │ Voice 1  │...│ Voice 4  │
└────┬─────┘   └────┬─────┘   └────┬─────┘
     │              │              │
     └──────────────┴──────────────┘
                    │
    ┌───────────────▼────────────────┐
    │ voicePool.voiceMixer (new)     │
    └───────────────┬────────────────┘
                    │
                    │
         ┌──────────┴──────────┐
         │   combinedMixer     │ ← OLD + NEW mixed together
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │   fxDelay           │ (stereo delay)
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │   fxReverb          │ (reverb)
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │  reverbDryWet       │ (dry/wet mix)
         └──────────┬──────────┘
                    │
                    ▼
            sharedEngine.output
                    │
                    ▼
              Audio Hardware
```

**Key Points:**
- Both old and new systems run in parallel (Phase 1)
- Combined mixer allows testing without breaking existing functionality
- Effects process both systems together
- Phase 3 will remove old system and use only voice pool

---

## Memory & Performance Characteristics

### Voice Count Comparison

**Old System:**
```
18 voices × 1 oscillator = 18 FMOscillators
18 LowPassFilters
18 AmplitudeEnvelopes
18 Panners
= 72 AudioKit nodes total
```

**New System (5 voices):**
```
5 voices × 2 oscillators = 10 FMOscillators
5 voices × 2 panners = 10 Panners
5 stereo mixers
5 LowPassFilters
5 AmplitudeEnvelopes
= 35 AudioKit nodes total
```

**New System (12 voices max):**
```
12 voices × 2 oscillators = 24 FMOscillators
12 voices × 2 panners = 24 Panners
12 stereo mixers
12 LowPassFilters
12 AmplitudeEnvelopes
= 84 AudioKit nodes total
```

### CPU Impact Estimate

- **Old system:** ~15-20% CPU (18 mono voices)
- **New system (5 voices):** ~12-15% CPU (5 stereo voices)
- **New system (8 voices):** ~18-22% CPU (8 stereo voices)
- **New system (12 voices):** ~28-35% CPU (12 stereo voices)

**Recommendation:** Start with 5-7 voices, increase if CPU allows on target device.

---

## Testing Scenarios Visual Guide

### Test 1: Single Note
```
Press Key 0
↓
Voice 0 allocated
↓
Hear: Stereo-wide note (L/R panned oscillators)
```

### Test 2: Polyphony (3 notes)
```
Press Key 0, Key 5, Key 10
↓
Voice 0 ← Key 0
Voice 1 ← Key 5
Voice 2 ← Key 10
↓
Hear: 3 stereo notes playing together
```

### Test 3: Voice Stealing (6 notes)
```
Hold Keys: 0, 1, 2, 3, 4 (all 5 voices busy)
↓
Press Key 5 (no voices available)
↓
Voice 0 stolen (oldest)
Voice 0 ← Key 5 (new)
↓
Hear: Key 0 cuts off, Key 5 starts
```

### Test 4: Stereo Spread Control
```
Press Key 0
↓
Slider at 1.0: Mono (both oscillators at same frequency)
Slider at 1.005: ~17 cents spread (subtle stereo width)
Slider at 1.01: ~34 cents spread (obvious stereo chorus)
↓
Hear: Width increasing as slider moves right
```

---

This architecture provides:
✅ Efficient voice allocation (fewer total voices)
✅ Dynamic polyphony (voices shared across all keys)
✅ Rich stereo field (dual oscillators per voice)
✅ Configurable voice count (3-12 voices)
✅ Instant voice stealing (no fade-out delay)
✅ Precise release tracking (key-to-voice mapping)
