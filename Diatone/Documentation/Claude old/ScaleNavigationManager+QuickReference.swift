//
//  ScaleNavigationManager+QuickReference.swift
//  Quick Reference Guide for ScaleNavigationManager
//
//  This file is not part of the build - it's documentation only
//

/*

# ScaleNavigationManager Quick Reference

## Basic Usage

### Creating the Manager
```swift
// In your app or view
@StateObject private var navigationManager = ScaleNavigationManager(
    initialScale: ScalesCatalog.centerMeridian_JI,
    initialKey: .D
)
```

### Accessing Current State
```swift
let scale = navigationManager.currentScale        // Scale with rotation applied
let key = navigationManager.musicalKey            // Current transposition key
let baseScale = navigationManager.baseScale       // Scale without rotation
```

### Navigation Methods
```swift
// Scale catalog navigation (does not wrap)
navigationManager.incrementScale()  // Next scale
navigationManager.decrementScale()  // Previous scale

// Property-based navigation
navigationManager.cycleIntonation(forward: true)   // JI ↔ ET (wraps)
navigationManager.cycleCelestial(forward: true)    // Moon → Center → Sun (no wrap)
navigationManager.cycleTerrestrial(forward: true)  // Occident → Meridian → Orient (no wrap)

// Rotation and key
navigationManager.cycleRotation(forward: true)     // -2 to +2 (no wrap)
navigationManager.cycleKey(forward: true)          // Ab → ... → G# (no wrap)
```

### Direct Setters
```swift
navigationManager.setScale(someScale)
navigationManager.setScaleIndex(5)
navigationManager.setRotation(1)
navigationManager.setKey(.A)

// Resets
navigationManager.resetRotation()  // Set to 0
navigationManager.resetKey()       // Set to D
navigationManager.resetToDefaults() // Center Meridian JI, D, rotation 0
```

### State Queries
```swift
if navigationManager.isAtFirstScale { /* ... */ }
if navigationManager.isAtLastScale { /* ... */ }
if navigationManager.isAtMinRotation { /* ... */ }
if navigationManager.isAtMaxRotation { /* ... */ }
if navigationManager.isAtFirstKey { /* ... */ }
if navigationManager.isAtLastKey { /* ... */ }
```

### Observing Changes
```swift
// Set up callbacks to react to changes
navigationManager.onScaleChanged = { newScale in
    print("Scale changed to: \(newScale.name)")
    // Update audio engine, UI, etc.
}

navigationManager.onKeyChanged = { newKey in
    print("Key changed to: \(newKey.rawValue)")
    // Update frequencies, UI, etc.
}
```

### Debugging
```swift
navigationManager.printState()
// Outputs:
// 🧭 Scale Navigation State:
//    Scale Index: 4 of 18
//    Scale: Center Meridian (JI)
//    Rotation: 0
//    Key: D
//    Properties: JUST / CENTER / MERIDIAN
```

## Integration with KeyboardState

The manager doesn't handle frequencies directly. Use it with `KeyboardState`:

```swift
// In PentatoneApp.swift (already implemented)
navigationManager.onScaleChanged = { [self] scale in
    keyboardState.updateScaleAndKey(
        scale: scale, 
        key: navigationManager.musicalKey
    )
}

navigationManager.onKeyChanged = { [self] key in
    keyboardState.updateScaleAndKey(
        scale: navigationManager.currentScale, 
        key: key
    )
}
```

## Common Patterns

### Button Actions
```swift
Button("Next Scale") {
    navigationManager.incrementScale()
}

Button("Previous Key") {
    navigationManager.cycleKey(forward: false)
}
```

### Gesture Handlers
```swift
.onSwipeUp {
    navigationManager.cycleCelestial(forward: true)
}
.onSwipeDown {
    navigationManager.cycleCelestial(forward: false)
}
```

### Picker/Selector
```swift
Picker("Scale", selection: $navigationManager.currentScale) {
    ForEach(ScalesCatalog.all) { scale in
        Text(scale.name).tag(scale)
    }
}
```

### Conditional UI
```swift
Button("→") {
    navigationManager.incrementScale()
}
.disabled(navigationManager.isAtLastScale)

Button("←") {
    navigationManager.decrementScale()
}
.disabled(navigationManager.isAtFirstScale)
```

## Navigation Flow

### Scale Properties
```
Intonation:  JI ↔ ET (wraps)
Celestial:   Moon → Center → Sun (no wrap)
Terrestrial: Occident → Meridian → Orient (no wrap)
```

### Musical Keys (in order)
```
Ab → Eb → Bb → F → C → G → D → A → E → B → F# → C# → G# (no wrap)
```

### Rotation Range
```
-2 → -1 → 0 → +1 → +2 (no wrap)
```

## Notes

- The manager is `@MainActor` isolated for thread safety
- All navigation methods are safe to call even at boundaries (they just won't change state)
- Uses `@Published` properties for automatic SwiftUI updates
- iOS 15+ compatible (uses `ObservableObject`)
- Rotation is automatically applied to `currentScale`, but `baseScale` is unrotated

*/
