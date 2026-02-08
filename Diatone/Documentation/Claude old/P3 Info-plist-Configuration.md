# Info.plist Configuration for Arithmophone Presets

## File Type Registration

Add the following entries to your `Info.plist` file to register the `.arithmophonepreset` file type.

This enables:
- Opening preset files in your app from Files, Mail, Messages, AirDrop, etc.
- Showing your app as an option when users tap on `.arithmophonepreset` files
- Cross-app compatibility across all Arithmophone apps (Pentatone, ChromaTone, etc.)

---

## XML Configuration (Source Code View)

Open `Info.plist` in **Source Code** mode (right-click → Open As → Source Code) and add these entries:

### 1. Declare the Custom Type (UTImportedTypeDeclarations)

Add this BEFORE the closing `</dict></plist>` tags:

```xml
<key>UTImportedTypeDeclarations</key>
<array>
    <dict>
        <key>UTTypeIdentifier</key>
        <string>com.chielzwinkels.arithmophone.preset</string>
        <key>UTTypeConformsTo</key>
        <array>
            <string>public.json</string>
            <string>public.data</string>
        </array>
        <key>UTTypeDescription</key>
        <string>Arithmophone Preset</string>
        <key>UTTypeTagSpecification</key>
        <dict>
            <key>public.filename-extension</key>
            <array>
                <string>arithmophonepreset</string>
            </array>
            <key>public.mime-type</key>
            <array>
                <string>application/json</string>
            </array>
        </dict>
    </dict>
</array>
```

### 2. Register Your App as Handler (CFBundleDocumentTypes)

Add this AFTER the UTImportedTypeDeclarations:

```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Arithmophone Preset</string>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>LSHandlerRank</key>
        <string>Owner</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>com.chielzwinkels.arithmophone.preset</string>
        </array>
    </dict>
</array>
```

### 3. Enable Document Browser (Optional, but Recommended)

```xml
<key>UISupportsDocumentBrowser</key>
<true/>
```

---

## Property List View Configuration

If you prefer using Xcode's Property List editor:

### 1. UTImportedTypeDeclarations

1. Right-click in Info.plist → Add Row
2. Key: `Imported Type Identifiers` (or type `UTImportedTypeDeclarations`)
3. Expand the array → Click `+` to add an item
4. Expand Item 0 → Add these entries:
   - **Identifier**: `com.chielzwinkels.arithmophone.preset`
   - **Conforms To**: (Array)
     - Item 0: `public.json`
     - Item 1: `public.data`
   - **Description**: `Arithmophone Preset`
   - **Tag Specification**: (Dictionary)
     - **Extensions**: (Array)
       - Item 0: `arithmophonepreset`
     - **MIME Types**: (Array)
       - Item 0: `application/json`

### 2. CFBundleDocumentTypes

1. Right-click in Info.plist → Add Row
2. Key: `Document types` (or type `CFBundleDocumentTypes`)
3. Expand the array → Click `+` to add an item
4. Expand Item 0 → Add these entries:
   - **Document Type Name**: `Arithmophone Preset`
   - **Handler rank**: `Owner`
   - **Document Content Type UTIs**: (Array)
     - Item 0: `com.chielzwinkels.arithmophone.preset`
   - **Role**: `Editor`

---

## Testing File Type Registration

After adding these entries:

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Rebuild**: Product → Build (⌘B)
3. **Install on Device**: Run the app
4. **Test Import**:
   - Export a preset from your app
   - AirDrop it to the same device or save to Files
   - Tap the `.arithmophonepreset` file
   - Your app should appear as an option to open it

---

## Handling Incoming Files

The `DocumentPicker` in `PresetView` already handles file imports.

To handle files opened directly (e.g., from Files app):

Add this to `PentatoneApp.swift`:

```swift
@main
struct Penta_ToneApp: App {
    // ... existing code ...
    
    var body: some Scene {
        WindowGroup {
            contentView
        }
        .onOpenURL { url in
            handleIncomingPreset(url)
        }
    }
    
    private func handleIncomingPreset(_ url: URL) {
        Task { @MainActor in
            do {
                let preset = try PresetManager.shared.importPreset(from: url)
                print("✅ Imported preset from external source: \(preset.name)")
                // Optionally show an alert or auto-load the preset
            } catch {
                print("⚠️ Failed to import preset: \(error)")
            }
        }
    }
}
```

---

## Notes

- **Bundle Identifier**: Replace `com.chielzwinkels.arithmophone` with your actual bundle identifier base if different
- **Cross-App Compatibility**: Use the same UTI (`com.chielzwinkels.arithmophone.preset`) in all your Arithmophone apps
- **File Extension**: Always use `.arithmophonepreset` (no dots or spaces)
- **JSON Conformance**: The preset files are JSON, so they conform to `public.json`

---

## Complete Info.plist Example

Here's what the relevant section should look like:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Your existing Info.plist entries here -->
    
    <key>UTImportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>com.chielzwinkels.arithmophone.preset</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.json</string>
                <string>public.data</string>
            </array>
            <key>UTTypeDescription</key>
            <string>Arithmophone Preset</string>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>arithmophonepreset</string>
                </array>
                <key>public.mime-type</key>
                <array>
                    <string>application/json</string>
                </array>
            </dict>
        </dict>
    </array>
    
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Arithmophone Preset</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>com.chielzwinkels.arithmophone.preset</string>
            </array>
        </dict>
    </array>
    
    <key>UISupportsDocumentBrowser</key>
    <true/>
    
</dict>
</plist>
```

---

## Troubleshooting

### "App doesn't appear when tapping preset file"

- Clean build folder and rebuild
- Restart device
- Check UTI spelling matches exactly in both declarations

### "Import fails with 'invalid file type'"

- Ensure exported files have `.arithmophonepreset` extension
- Check JSON encoding is valid
- Verify `public.json` conformance in UTI declaration

### "Can't find Info.plist entries"

- Look for `Info.plist` in your project navigator
- May be inside the app target's settings under "Custom iOS Target Properties"
- Can also edit directly in Xcode: Select target → Info tab

---

Good luck! 🎹
