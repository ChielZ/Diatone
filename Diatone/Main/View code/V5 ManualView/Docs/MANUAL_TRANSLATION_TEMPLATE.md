# Manual Translation Template

This document contains all English strings from the ManualView that need translation. You can use this as a reference when working with translators or AI translation.

## Structure

Each entry follows this format:
- **Key**: The localization key used in code
- **Context**: Where/how it's used
- **English**: The source text
- **Notes**: Important context for translators

---

## General UI

### manual.title
- **Context**: Navigation bar title
- **English**: "Manual"
- **Notes**: Short word preferred

---

## Welcome Section

### manual.welcome.title
- **Context**: Main heading of welcome section
- **English**: "Welcome to Pentatone"
- **Notes**: "Pentatone" is the app name - do not translate

### manual.welcome.description
- **Context**: App description paragraph
- **English**: "Pentatone is a musical instrument based on the Arithmophone, a keyboard designed to explore just intonation through pentatonic scales."
- **Notes**: 
  - "Arithmophone" = proper name, do not translate
  - "just intonation" = technical music term
  - "pentatonic" = five-note scales

### manual.welcome.instruction
- **Context**: Instruction text below description
- **English**: "Select any section below to learn more about the app's features."
- **Notes**: Informal, friendly tone

---

## Section Titles

### manual.section.keyboard
- **Context**: Main section heading
- **English**: "The Keyboard"
- **Notes**: The musical keyboard/piano interface

### manual.section.scales
- **Context**: Main section heading
- **English**: "The Scales"
- **Notes**: Musical scales (not weight scales!)

### manual.section.sounds
- **Context**: Main section heading
- **English**: "The Sounds"
- **Notes**: Sound design/audio section

### manual.section.settings
- **Context**: Main section heading
- **English**: "The Settings"
- **Notes**: App configuration section

### manual.section.background
- **Context**: Main section heading
- **English**: "Background"
- **Notes**: Music theory and educational content

### manual.section.editor
- **Context**: Main section heading
- **English**: "The Editor"
- **Notes**: Advanced sound editing interface

---

## Keyboard Section

### manual.keyboard.touch.title
- **Context**: Subsection heading
- **English**: "Touch Sensitivity"
- **Notes**: Refers to touchscreen responsiveness

### manual.keyboard.touch.content
- **Context**: Explanation text
- **English**: "The keyboard responds to touch position and pressure. Slide your finger horizontally across a key to add vibrato. Touch harder for more expression."
- **Notes**: 
  - "vibrato" = musical term for pitch oscillation
  - Instructional, clear tone

### manual.keyboard.fold.title
- **Context**: Subsection heading
- **English**: "Fold/Unfold"
- **Notes**: "Fold" = collapse/compact (not paper folding)

### manual.keyboard.fold.content
- **Context**: Explanation text
- **English**: "Use the fold button to compact the keyboard for easier playing in smaller layouts, or unfold for full access to all keys."
- **Notes**: Describe UI space-saving feature

---

## Scales Section

### manual.scales.ji.title
- **Context**: Subsection heading
- **English**: "Just Intonation vs Equal Temperament"
- **Notes**: 
  - "Just Intonation" = pure tuning system
  - "Equal Temperament" = modern piano tuning
  - Both are technical terms with standard translations

### manual.scales.ji.content
- **Context**: Explanation text
- **English**: "Pentatone uses just intonation, where intervals are based on simple frequency ratios, creating purer harmonies than equal temperament. See the Background section for more details."
- **Notes**: Brief introduction to tuning systems

### manual.scales.keys.title
- **Context**: Subsection heading
- **English**: "Keys"
- **Notes**: Musical keys (C, D, E, etc.) not physical keys

### manual.scales.keys.content
- **Context**: Explanation text
- **English**: "Select the root key for your current scale. The keyboard will adjust all frequencies accordingly."
- **Notes**: "root key" = tonal center

### manual.scales.scales.title
- **Context**: Subsection heading
- **English**: "Scale Selection"
- **Notes**: Choosing between different musical scales

### manual.scales.scales.content
- **Context**: Explanation text
- **English**: "Pentatone features the Arithmophone scale system with multiple pentatonic scales. Swipe or use the arrows to navigate between scales. See Background for scale theory."
- **Notes**: Describes navigation UI

### manual.scales.rotation.title
- **Context**: Subsection heading
- **English**: "Rotation"
- **Notes**: Musical rotation (changing the starting note)

### manual.scales.rotation.content
- **Context**: Explanation text
- **English**: "Rotate through different modes of the current scale by changing which note functions as the tonal center."
- **Notes**: 
  - "modes" = scale variations
  - "tonal center" = root note

---

## Sounds Section

### manual.sounds.presets.title
- **Context**: Subsection heading
- **English**: "Preset Selector"
- **Notes**: Choosing saved sound designs

### manual.sounds.presets.content
- **Context**: Explanation text
- **English**: "Choose from factory presets or create your own. Each preset contains a complete sound design including oscillators, effects, and modulation."
- **Notes**: 
  - "oscillators" = sound generators
  - "modulation" = sound variation over time

### manual.sounds.macros.title
- **Context**: Subsection heading
- **English**: "Macro Sliders"
- **Notes**: "Macro" = grouped controls

### manual.sounds.macros.content
- **Context**: Explanation text
- **English**: "Each preset exposes up to four macro controls for real-time sound shaping. These can be customized in the Editor to control any parameter."
- **Notes**: Describes simplified sound controls

---

## Settings Section

### manual.settings.voice.title
- **Context**: Subsection heading
- **English**: "Voice Mode"
- **Notes**: "Voice" = sound instance (not human voice)

### manual.settings.voice.content
- **Context**: Explanation text
- **English**: "Choose between polyphonic (multiple simultaneous notes) and monophonic (single note) playing modes."
- **Notes**: 
  - "polyphonic" = many notes at once
  - "monophonic" = one note at a time

### manual.settings.octave.title
- **Context**: Subsection heading
- **English**: "Octave"
- **Notes**: Musical octave (8 notes up/down)

### manual.settings.octave.content
- **Context**: Explanation text
- **English**: "Shift the keyboard's pitch range up or down by octaves."
- **Notes**: Transpose feature

### manual.settings.tune.title
- **Context**: Subsection heading
- **English**: "Tuning"
- **Notes**: Reference pitch setting

### manual.settings.tune.content
- **Context**: Explanation text
- **English**: "Adjust the reference frequency (A4). Standard is 440 Hz, but historical tunings like 432 Hz are also popular."
- **Notes**: 
  - "A4" = musical note designation
  - Hz = Hertz (cycles per second)

### manual.settings.editor.title
- **Context**: Subsection heading
- **English**: "The Editor"
- **Notes**: Sound editing interface

### manual.settings.editor.content
- **Context**: Explanation text
- **English**: "Access the advanced sound editor to create and modify presets. See the Editor section for detailed information."
- **Notes**: Reference to another section

---

## Background Section

### manual.background.ji.title
- **Context**: Subsection heading
- **English**: "What is Just Intonation?"
- **Notes**: Educational content - music theory

### manual.background.ji.content
- **Context**: Explanation text
- **English**: "Just intonation is a tuning system where intervals are based on whole number frequency ratios (like 3:2 for a perfect fifth). This creates exceptionally pure harmonies but limits modulation between keys."
- **Notes**: 
  - Technical explanation
  - "perfect fifth" = musical interval
  - "modulation" = key changes

### manual.background.et.title
- **Context**: Subsection heading
- **English**: "What is Equal Temperament?"
- **Notes**: Educational content - music theory

### manual.background.et.content
- **Context**: Explanation text
- **English**: "Equal temperament divides the octave into 12 equal steps, allowing free modulation between any key. The trade-off is that most intervals are slightly out of tune compared to their just intonation equivalents."
- **Notes**: Comparison with just intonation

### manual.background.arithmophone.title
- **Context**: Subsection heading
- **English**: "The Arithmophone System"
- **Notes**: "Arithmophone" = proper name

### manual.background.arithmophone.content
- **Context**: Explanation text
- **English**: "The Arithmophone uses a unique pentatonic scale system that combines the purity of just intonation with practical playability. It organizes scales in a systematic way that makes exploration intuitive."
- **Notes**: Core concept explanation

---

## Editor Section

### manual.editor.fm.title
- **Context**: Subsection heading
- **English**: "About FM Synthesis"
- **Notes**: 
  - "FM" = Frequency Modulation
  - Technical audio term

### manual.editor.fm.content
- **Context**: Explanation text
- **English**: "Frequency Modulation synthesis creates complex timbres by using one oscillator to modulate another's frequency. This enables a wide range of sounds from bells to brass to electric pianos."
- **Notes**: 
  - Technical explanation
  - "timbres" = sound colors/qualities

### manual.editor.presets.title
- **Context**: Subsection heading
- **English**: "Preset Management"
- **Notes**: File operations for sound presets

### manual.editor.presets.content
- **Context**: Explanation text
- **English**: "Create, save, share, and organize your sound presets. Presets can be exported and shared with other Pentatone users."
- **Notes**: File management features

### manual.editor.oscillators.title
- **Context**: Subsection heading
- **English**: "Oscillators"
- **Notes**: Sound generation modules

### manual.editor.oscillators.content
- **Context**: Explanation text
- **English**: "Configure the FM oscillator stack, including carrier and modulator relationships, ratios, and levels."
- **Notes**: 
  - "carrier" = main sound
  - "modulator" = sound that affects carrier
  - Technical synthesis terms

### manual.editor.more
- **Context**: Summary text listing additional features
- **English**: "Additional editor parameters include: Contour (amplitude envelopes), Effects (reverb, delay, distortion), Master settings, Modulation Envelope, Auxiliary Envelope, Voice LFO, Global LFO, Touch sensitivity routing, and Macro parameter ranges."
- **Notes**: 
  - List of technical features
  - "LFO" = Low Frequency Oscillator
  - "envelope" = volume/pitch shape over time

---

## Help/Tooltip Strings (for future use)

### help.title
- **Context**: Alert dialog title
- **English**: "Help"
- **Notes**: Generic help dialog

### help.dismiss
- **Context**: Button to close help
- **English**: "Got it"
- **Notes**: Informal, friendly

---

## Translation Notes

### Tone and Voice
- **Target audience**: Musicians and music enthusiasts, ages 16-65
- **Tone**: Educational but approachable, not overly technical
- **Voice**: Second person ("you"), informal but professional

### Technical Terms
Many music and synthesis terms have standard translations in music education materials. Consult local music education resources for your target language.

### Length Considerations
- Section titles should remain relatively short (1-4 words)
- Content text can be longer but should be scannable
- Mobile screens have limited space

### Testing
After translation, test on device to ensure:
- Text fits in UI layouts
- Natural phrasing in target language
- Technical terms are accurate and recognized

---

**Note**: This is a living document. As the manual evolves, update this template accordingly.
