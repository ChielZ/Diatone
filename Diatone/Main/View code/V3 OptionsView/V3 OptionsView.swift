//
//  V3 OptionsView.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 02/12/2025.
//

import SwiftUI
import Combine

// MARK: - Adaptive Font Modifier (Shared across all option views)
struct AdaptiveFont: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let fontName: String
    let baseSize: CGFloat
    
    var adaptiveSize: CGFloat {
        // Regular width and height = iPad in any orientation
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return baseSize
        } else if horizontalSizeClass == .regular {
            // iPhone Plus/Max in landscape
            return baseSize * 0.75
        } else {
            // iPhone in portrait (compact width)
            return baseSize * 0.65
        }
    }
    
    func body(content: Content) -> some View {
        content
            .font(.custom(fontName, size: adaptiveSize))
    }
}

extension View {
    func adaptiveFont(_ name: String, size: CGFloat) -> some View {
        modifier(AdaptiveFont(fontName: name, baseSize: size))
    }
}

// MARK: - Button Alignment System

/// Stores the frame information for alignment anchors
struct ButtonAnchorData: Equatable {
    var leftFrame: CGRect = .zero
    var rightFrame: CGRect = .zero
    
    /// Computed property for button width
    var buttonWidth: CGFloat {
        leftFrame.width > 0 ? leftFrame.width : rightFrame.width
    }
}

/// Shared button width manager - allows EditView to use the same button width as OptionsView
@MainActor
class SharedButtonWidth: ObservableObject {
    static let shared = SharedButtonWidth()
    @Published var width: CGFloat = 0
    
    private init() {}
}

/// PreferenceKey for passing button anchor positions up the view hierarchy
struct ButtonAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: ButtonAnchorData = ButtonAnchorData()
    
    static func reduce(value: inout ButtonAnchorData, nextValue: () -> ButtonAnchorData) {
        let next = nextValue()
        // Merge the frames - keep whichever one is not zero
        if next.leftFrame != .zero {
            value.leftFrame = next.leftFrame
        }
        if next.rightFrame != .zero {
            value.rightFrame = next.rightFrame
        }
    }
}

/// View modifier to capture and report button frame positions
struct ButtonAnchorModifier: ViewModifier {
    let isLeft: Bool
    let coordinateSpaceName: String
    
    init(isLeft: Bool, coordinateSpaceName: String = "OptionsViewCoordinateSpace") {
        self.isLeft = isLeft
        self.coordinateSpaceName = coordinateSpaceName
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ButtonAnchorPreferenceKey.self,
                        value: {
                            var data = ButtonAnchorData()
                            let frame = geometry.frame(in: .named(coordinateSpaceName))
                            if isLeft {
                                data.leftFrame = frame
                            } else {
                                data.rightFrame = frame
                            }
                            return data
                        }()
                    )
                }
            )
    }
}

extension View {
    /// Marks this view as a left or right button anchor
    func buttonAnchor(isLeft: Bool, coordinateSpaceName: String = "OptionsViewCoordinateSpace") -> some View {
        modifier(ButtonAnchorModifier(isLeft: isLeft, coordinateSpaceName: coordinateSpaceName))
    }
}

extension View {
    /// Marks this view as a left or right button anchor
    func buttonAnchor(isLeft: Bool) -> some View {
        modifier(ButtonAnchorModifier(isLeft: isLeft))
    }
}

// MARK: - Aligned Selector Row Component

/// A row with left/right buttons aligned to the bottom row, with centered text
struct AlignedSelectorRow: View {
    let leftSymbol: String
    let rightSymbol: String
    let centerText: String
    let buttonAnchors: ButtonAnchorData
    let onLeftTap: () -> Void
    let onRightTap: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left button - aligned to anchor
                    if buttonAnchors.leftFrame.width > 0 {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .frame(width: buttonAnchors.leftFrame.width)
                            .overlay(
                                Text(leftSymbol)
                                    .foregroundColor(Color("BackgroundColour"))
                                    .adaptiveFont("MontserratAlternates-Medium", size: 30)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onLeftTap()
                            }
                    }
                    
                    Spacer()
                    
                    // Center text
                    Text(centerText)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                    
                    Spacer()
                    
                    // Right button - aligned to anchor
                    if buttonAnchors.rightFrame.width > 0 {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .frame(width: buttonAnchors.rightFrame.width)
                            .overlay(
                                Text(rightSymbol)
                                    .foregroundColor(Color("BackgroundColour"))
                                    .adaptiveFont("MontserratAlternates-Medium", size: 30)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onRightTap()
                            }
                    }
                }
            }
        }
    }
}

/// A row with left/right buttons and a draggable center text for value adjustment
struct AlignedDraggableSelectorRow<Content: View>: View {
    let leftSymbol: String
    let rightSymbol: String
    let centerContent: Content
    let buttonAnchors: ButtonAnchorData
    let onLeftTap: () -> Void
    let onRightTap: () -> Void
    
    init(
        leftSymbol: String,
        rightSymbol: String,
        buttonAnchors: ButtonAnchorData,
        onLeftTap: @escaping () -> Void,
        onRightTap: @escaping () -> Void,
        @ViewBuilder centerContent: () -> Content
    ) {
        self.leftSymbol = leftSymbol
        self.rightSymbol = rightSymbol
        self.buttonAnchors = buttonAnchors
        self.onLeftTap = onLeftTap
        self.onRightTap = onRightTap
        self.centerContent = centerContent()
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left button - aligned to anchor
                    if buttonAnchors.leftFrame.width > 0 {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .frame(width: buttonAnchors.leftFrame.width)
                            .overlay(
                                Text(leftSymbol)
                                    .foregroundColor(Color("BackgroundColour"))
                                    .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onLeftTap()
                            }
                    }
                    
                    Spacer()
                    
                    // Center content with drag gesture support
                    centerContent
                        .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    // Right button - aligned to anchor
                    if buttonAnchors.rightFrame.width > 0 {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("SupportColour"))
                            .frame(width: buttonAnchors.rightFrame.width)
                            .overlay(
                                Text(rightSymbol)
                                    .foregroundColor(Color("BackgroundColour"))
                                    .adaptiveFont("MontserratAlternates-Medium", size: 30)
                                    .minimumScaleFactor(0.5)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onRightTap()
                            }
                    }
                }
            }
        }
    }
}

enum OptionsSubView: CaseIterable {
    case scale, sound, voice
    
    var displayName: String {
        switch self {
        case .scale: return "SCALE"
        case .sound: return "SOUND"
        case .voice: return "SETUP"
        }
    }
}

struct OptionsView: View {
    @Binding var showingOptions: Bool
    @Binding var currentSubView: OptionsSubView
    
    // Scale navigation
    var currentScale: Scale = ScalesCatalog.Dorian_JI_E
    var currentKey: MusicalKey = .D
    var onCycleIntonation: ((Bool) -> Void)? = nil
    var onCycleCelestial: ((Bool) -> Void)? = nil
    var onCycleTerrestrial: ((Bool) -> Void)? = nil
    var onCycleRotation: ((Bool) -> Void)? = nil
    var onCycleKey: ((Bool) -> Void)? = nil
    
    // View switching
    var onSwitchToEdit: (() -> Void)? = nil
    var onSwitchToManual: (() -> Void)? = nil
    
    // Store the button anchor positions from the bottom row
    @State private var buttonAnchors = ButtonAnchorData()
    
    // Computed property for note names - safer for preview compilation
    private var noteNamesArray: [NoteName] {
        noteNames(forScale: currentScale, inKey: currentKey)
    }

    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("HighlightColour"))
                .padding(5)
            
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
                .padding(9)
            
            VStack(spacing: 11) {
                ZStack{ // Row 1
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("HighlightColour"))
                    Text("･FOLD･")
                        .foregroundColor(Color("BackgroundColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingOptions = false
                        }
                }
                .frame(maxHeight: .infinity)
                
                // Row 2 - Now with aligned buttons
                AlignedSelectorRow(
                    leftSymbol: "<",
                    rightSymbol: ">",
                    centerText: currentSubView.displayName,
                    buttonAnchors: buttonAnchors,
                    onLeftTap: { previousSubView() },
                    onRightTap: { nextSubView() }
                )
                .frame(maxHeight: .infinity)
                
                // Rows 3-9: Show the current subview
                Group {
                    switch currentSubView {
                    case .scale:
                        ScaleView(
                            currentScale: currentScale,
                            currentKey: currentKey,
                            buttonAnchors: buttonAnchors,
                            onCycleIntonation: onCycleIntonation,
                            onCycleCelestial: onCycleCelestial,
                            onCycleTerrestrial: onCycleTerrestrial,
                            onCycleRotation: onCycleRotation,
                            onCycleKey: onCycleKey
                        )
                    case .sound:
                        SoundView(
                            
                            onSwitchToEdit: onSwitchToEdit,
                            buttonAnchors: buttonAnchors
                        )
                    case .voice:
                        VoiceView(
                            
                            onSwitchToManual: onSwitchToManual,
                            buttonAnchors: buttonAnchors
                        )
                    }
                }
                .frame(maxHeight: .infinity)
                
                ZStack{ // Row 10
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("BackgroundColour"))
                    HStack{
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                NoteNameText(
                                    noteName: noteNamesArray[4],
                                    size: 30,
                                    color: Color("KeyColour5")
                                )
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                NoteNameText(
                                    noteName: noteNamesArray[5],
                                    size: 30,
                                    color: Color("KeyColour6")
                                )
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                NoteNameText(
                                    noteName: noteNamesArray[6],
                                    size: 30,
                                    color: Color("KeyColour7")
                                )
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                NoteNameText(
                                    noteName: noteNamesArray[0],
                                    size: 30,
                                    color: Color("KeyColour1")
                                )
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                NoteNameText(
                                    noteName: noteNamesArray[1],
                                    size: 30,
                                    color: Color("KeyColour2")
                                )
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                NoteNameText(
                                    noteName: noteNamesArray[2],
                                    size: 30,
                                    color: Color("KeyColour3")
                                )
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                            )
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("BackgroundColour"))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                NoteNameText(
                                    noteName: noteNamesArray[3],
                                    size: 30,
                                    color: Color("KeyColour4")
                                )
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                            )
                    }
                }
                .frame(maxHeight: .infinity)
                
                ZStack{ // Row 11 - This is the reference row for alignment
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("BackgroundColour"))
                    HStack{
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour5"))
                            .buttonAnchor(isLeft: true)
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour6"))
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour7"))
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour1"))
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour2"))
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour3"))
                        Spacer()
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color("KeyColour4"))
                            .buttonAnchor(isLeft: false)
                    }
                }
                .frame(maxHeight: .infinity)
            }.padding(19)
            
        }
        .coordinateSpace(name: "OptionsViewCoordinateSpace")
        .onPreferenceChange(ButtonAnchorPreferenceKey.self) { value in
            buttonAnchors = value
            // Share the button width globally for EditView
            if value.buttonWidth > 0 {
                SharedButtonWidth.shared.width = value.buttonWidth
            }
        }
    }
    
    // MARK: - Navigation Functions
    
    private func nextSubView() {
        let allCases = OptionsSubView.allCases
        if let currentIndex = allCases.firstIndex(of: currentSubView) {
            let nextIndex = (currentIndex + 1) % allCases.count
            currentSubView = allCases[nextIndex]
        }
    }
    
    private func previousSubView() {
        let allCases = OptionsSubView.allCases
        if let currentIndex = allCases.firstIndex(of: currentSubView) {
            let previousIndex = (currentIndex - 1 + allCases.count) % allCases.count
            currentSubView = allCases[previousIndex]
        }
    }
}

#Preview {
    OptionsView(
        showingOptions: .constant(true),
        currentSubView: .constant(.scale),
        currentScale: ScalesCatalog.Dorian_JI_E,
        currentKey: .D,
        onCycleIntonation: { _ in },
        onCycleCelestial: { _ in },
        onCycleTerrestrial: { _ in },
        onCycleRotation: { _ in },
        onCycleKey: { _ in },
        onSwitchToEdit: {},
        onSwitchToManual: {}
    )
}
