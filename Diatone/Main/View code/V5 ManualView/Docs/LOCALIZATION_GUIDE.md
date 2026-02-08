# Pentatone Localization Guide

## Overview

This guide explains how localization is implemented in Pentatone and how to add or update translations.

## Architecture

### 1. String Catalogs (`.xcstrings`)

Pentatone uses Apple's modern **Strings Catalog** system for all localized text. All translations are stored in a single file: `Localizable.xcstrings`.

**Benefits:**
- Single source of truth for all languages
- Visual editor in Xcode
- Automatic string extraction
- Compile-time validation
- Support for plurals, variables, and string interpolation

### 2. Localization Keys

All user-facing strings use a hierarchical naming convention:

```
<feature>.<section>.<subsection>.<type>

Examples:
- manual.welcome.title
- manual.keyboard.touch.content
- tooltip.keyboard.fold
- help.voicemode
- settings.octave.label
```

**Types:**
- `title` - Section or view titles
- `content` - Body text or descriptions
- `label` - Control labels
- `help` - Help text for tooltips/alerts
- `button` - Button labels
- `message` - User-facing messages

## Supported Languages

### Current Languages

1. **English (en)** - Base language
2. **Spanish (es)**
3. **German (de)**
4. **French (fr)**
5. **Japanese (ja)**

### Adding a New Language

1. In Xcode: Project Settings → Info → Localizations → + button
2. Select the language
3. Xcode will add it to `Localizable.xcstrings` automatically
4. Fill in translations in the Strings Catalog editor

## Usage in Code

### Basic String Localization

```swift
// Preferred method (SwiftUI)
Text("manual.welcome.title", defaultValue: "Welcome to Pentatone")

// Alternative method
let title = String(localized: "manual.welcome.title", defaultValue: "Welcome to Pentatone")
Text(title)
```

**Always include `defaultValue`** - This serves as:
1. Fallback if localization fails
2. Documentation of what the string says
3. Source for extraction tools

### String Interpolation

```swift
Text("settings.octave.current", 
     defaultValue: "Current octave: \(octave)")
```

### Pluralization

```swift
// In code
Text("presets.count", 
     defaultValue: "^[\(count) preset](inflect: true)")

// Xcode will automatically create plural variants in the catalog
```

### Tooltips & Help

```swift
// Long-press tooltip
Button("Fold") { /* action */ }
    .tooltip(key: "tooltip.keyboard.fold")

// Help button with alert
HStack {
    Text("Voice Mode")
    Spacer()
    HelpButton(helpKey: "help.voicemode")
}
```

## Translation Workflow

### For Developer (You)

1. **Write English strings** with localization keys and defaultValues
2. **Build the project** - Xcode extracts strings automatically
3. **Open Localizable.xcstrings** in Xcode
4. **Fill in translations** for each language
5. **Test** by changing device language in Settings

### For Translators

1. Export strings: Editor → Export for Localization (`.xcloc` file)
2. Send to translator or translation service
3. Import translated strings back into project
4. Review and test

## Best Practices

### 1. Context Matters

Always add comments to strings that need context:

```json
"manual.keyboard.fold.title" : {
  "comment" : "Title for the keyboard folding feature - 'fold' means to collapse/compact",
  "localizations" : { ... }
}
```

This is especially important for:
- Technical terms (FM, oscillator, etc.)
- Words with multiple meanings (key = musical key vs keyboard key)
- UI element names

### 2. Keep Music Terms Consistent

Music terminology should remain consistent across languages:

- **Just Intonation**: 
  - ES: Entonación justa
  - DE: Reine Stimmung
  - FR: Intonation juste
  - JA: 純正律 (jyunseiritsu)

- **Equal Temperament**:
  - ES: Temperamento igual
  - DE: Gleichstufige Stimmung
  - FR: Tempérament égal
  - JA: 平均律 (heikinritsu)

- **Pentatonic**:
  - ES: Pentatónica
  - DE: Pentatonisch
  - FR: Pentatonique
  - JA: ペンタトニック (pentatonikku)

### 3. Length Considerations

Text length varies by language:

- German tends to be 30% longer than English
- Japanese can be more compact
- Spanish is similar to English

Design UI with flexible layouts to accommodate different text lengths.

### 4. Testing

Test localization by:

1. **Changing iOS language**: Settings → General → Language & Region
2. **Using Xcode scheme**: Edit Scheme → Run → App Language
3. **Pseudolocalization**: For UI testing without real translations

## File Structure

```
Pentatone/
├── Resources/
│   └── Localizable.xcstrings          ← All translations
├── Views/
│   └── Manual/
│       ├── ManualView.swift           ← Main documentation view
│       └── TooltipView.swift          ← Tooltip/help components
└── Supporting Files/
    └── LOCALIZATION_GUIDE.md          ← This file
```

## Special Considerations for Pentatone

### Musical Terminology

Some terms should **NOT** be translated:
- Proper names: "Arithmophone", "Pentatone"
- Note names: C, D, E, F, G, A, B (in most contexts)
- Technical abbreviations: FM, LFO, ADSR

### Cultural Adaptations

Consider cultural differences in music education:
- Solfège varies by country (do-re-mi vs C-D-E notation)
- Some countries use different reference tunings
- Educational approaches differ

### Right-to-Left (RTL) Languages

If adding Arabic or Hebrew:
- SwiftUI handles text direction automatically
- Test keyboard layout carefully (may need mirroring)
- Musical notation generally stays left-to-right

## Future Enhancements

### Community Translations

Consider:
- Crowdsourcing via GitHub
- In-app translation submission
- Translation credits in About screen

### Dynamic Content

For user-generated content (preset names):
- Keep original language
- Optional user-provided translations
- Use machine translation with disclaimer

### Context-Sensitive Help

Could implement:
- First-launch tutorial in user's language
- Contextual tips that appear based on usage
- Video tutorials with subtitles

## Resources

- [Apple Localization Guide](https://developer.apple.com/localization/)
- [String Catalogs Documentation](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [WWDC Sessions on Localization](https://developer.apple.com/videos/frameworks/localization)

## Translation Status

Track completion percentage for each language:

| Language | Code | Progress | Notes |
|----------|------|----------|-------|
| English | en | 100% | Base language |
| Spanish | es | 0% | Priority 1 |
| German | de | 0% | Priority 1 |
| French | fr | 0% | Priority 2 |
| Japanese | ja | 0% | Priority 2 |

---

**Last Updated:** January 10, 2026  
**Maintainer:** Chiel Zwinkels
