//
//  V4-C ParameterComponents.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 27/12/2025.
//
//  Reusable UI components for parameter editing

import SwiftUI

// MARK: - Parameter Row (for discrete list selections)

/// A row for cycling through discrete parameter values (like enums)
/// Shows < value > with tap targets on the left and right buttons
struct ParameterRow<T: CaseIterable & Equatable>: View where T.AllCases.Index == Int {
    let label: String
    @Binding var value: T
    let displayText: (T) -> String
    
    @ObservedObject private var sharedButtonWidth = SharedButtonWidth.shared
    
    init(label: String, value: Binding<T>, displayText: @escaping (T) -> String) {
        self.label = label
        self._value = value
        self.displayText = displayText
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            HStack(spacing: 0) {
                let buttonWidth = sharedButtonWidth.width > 0 ? sharedButtonWidth.width : 60
                
                // Left button (<)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cyclePrevious()
                    }
                
                Spacer()
                
                // Center display - label and value
                VStack(spacing: 2) {
                    Text(label)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayText(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 24)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Right button (>)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cycleNext()
                    }
            }
        }
    }
    
    private func cycleNext() {
        let allCases = Array(T.allCases)
        guard let currentIndex = allCases.firstIndex(of: value) else { return }
        let nextIndex = (currentIndex + 1) % allCases.count
        value = allCases[nextIndex]
    }
    
    private func cyclePrevious() {
        let allCases = Array(T.allCases)
        guard let currentIndex = allCases.firstIndex(of: value) else { return }
        let previousIndex = (currentIndex - 1 + allCases.count) % allCases.count
        value = allCases[previousIndex]
    }
}

// MARK: - Time Sync Parameter Row (for tempo-synced values)

/// A row for cycling through tempo-synced parameter values (like delay time)
/// Shows < value > with tap targets on the left and right buttons
/// Behavior optimized for tempo divisions where:
/// - Right button (>) increases speed (smaller note values like 1/32)
/// - Left button (<) decreases speed (larger note values like 1/4)
/// - Does not wrap around at the ends
struct TimeSyncParameterRow<T: CaseIterable & Equatable>: View where T.AllCases.Index == Int {
    let label: String
    @Binding var value: T
    let displayText: (T) -> String
    
    @ObservedObject private var sharedButtonWidth = SharedButtonWidth.shared
    
    init(label: String, value: Binding<T>, displayText: @escaping (T) -> String) {
        self.label = label
        self._value = value
        self.displayText = displayText
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            HStack(spacing: 0) {
                let buttonWidth = sharedButtonWidth.width > 0 ? sharedButtonWidth.width : 60
                
                // Left button (<)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cycleNext()
                    }
                
                Spacer()
                
                // Center display - label and value
                VStack(spacing: 2) {
                    Text(label)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayText(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 24)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Right button (>)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cyclePrevious()
                    }
            }
        }
    }
    
    private func cycleNext() {
        let allCases = Array(T.allCases)
        guard let currentIndex = allCases.firstIndex(of: value) else { return }
        // Decrement index to go to faster speeds (smaller fractions)
        // Clamp to 0 instead of wrapping
        let nextIndex = max(currentIndex - 1, 0)
        value = allCases[nextIndex]
    }
    
    private func cyclePrevious() {
        let allCases = Array(T.allCases)
        guard let currentIndex = allCases.firstIndex(of: value) else { return }
        // Increment index to go to slower speeds (larger fractions)
        // Clamp to last index instead of wrapping
        let previousIndex = min(currentIndex + 1, allCases.count - 1)
        value = allCases[previousIndex]
    }
}


// MARK: - Time Sync Parameter Row (for tempo-synced values)

/// A row for cycling through tempo-synced parameter values (like delay time)
/// Shows < value > with tap targets on the left and right buttons
/// Behavior optimized for tempo divisions where:
/// - Right button (>) increases speed (smaller note values like 1/32)
/// - Left button (<) decreases speed (larger note values like 1/4)
/// - Does not wrap around at the ends
struct RevTimeSyncParameterRow<T: CaseIterable & Equatable>: View where T.AllCases.Index == Int {
    let label: String
    @Binding var value: T
    let displayText: (T) -> String
    
    @ObservedObject private var sharedButtonWidth = SharedButtonWidth.shared
    
    init(label: String, value: Binding<T>, displayText: @escaping (T) -> String) {
        self.label = label
        self._value = value
        self.displayText = displayText
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            HStack(spacing: 0) {
                let buttonWidth = sharedButtonWidth.width > 0 ? sharedButtonWidth.width : 60
                
                // Left button (<)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cyclePrevious()
                    }
                
                Spacer()
                
                // Center display - label and value
                VStack(spacing: 2) {
                    Text(label)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayText(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 24)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Right button (>)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cycleNext()
                    }
            }
        }
    }
    
    private func cycleNext() {
        let allCases = Array(T.allCases)
        guard let currentIndex = allCases.firstIndex(of: value) else { return }
        // Decrement index to go to faster speeds (smaller fractions)
        // Clamp to 0 instead of wrapping
        let nextIndex = max(currentIndex - 1, 0)
        value = allCases[nextIndex]
    }
    
    private func cyclePrevious() {
        let allCases = Array(T.allCases)
        guard let currentIndex = allCases.firstIndex(of: value) else { return }
        // Increment index to go to slower speeds (larger fractions)
        // Clamp to last index instead of wrapping
        let previousIndex = min(currentIndex + 1, allCases.count - 1)
        value = allCases[previousIndex]
    }
}






// MARK: - Discrete Enum Slider Row (for enums with many values)

/// A row for selecting from discrete enum values using a slider
/// Values are snapped to exact enum cases - no interpolation or approximation
/// Ideal for parameters with many discrete options (like carrier multiplier with fractions)
struct DiscreteEnumSliderRow<T: CaseIterable & Equatable & Identifiable>: View 
    where T.AllCases: RandomAccessCollection, T.AllCases.Index == Int, T.ID: Hashable {
    
    let label: String
    @Binding var value: T
    let displayFormatter: (T) -> String
    
    @State private var isDragging: Bool = false
    @State private var dragStartIndex: Int = 0
    @State private var dragStartLocation: CGFloat = 0
    
    @ObservedObject private var sharedButtonWidth = SharedButtonWidth.shared
    
    private let allCases: [T]
    
    init(
        label: String,
        value: Binding<T>,
        displayFormatter: @escaping (T) -> String
    ) {
        self.label = label
        self._value = value
        self.displayFormatter = displayFormatter
        self.allCases = Array(T.allCases)
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            HStack(spacing: 0) {
                let buttonWidth = sharedButtonWidth.width > 0 ? sharedButtonWidth.width : 60
                
                // Left button (<) - Decrement
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        decrementValue()
                    }
                
                // Center - Draggable area with label and value
                VStack(spacing: 2) {
                    Text(label)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayFormatter(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 24)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            if !isDragging {
                                isDragging = true
                                dragStartIndex = currentIndex
                                dragStartLocation = gesture.startLocation.x
                            }
                            
                            // Calculate delta from drag start
                            let delta = gesture.location.x - dragStartLocation
                            
                            // Convert pixels to index change
                            // Sensitivity: ~30 pixels per step
                            let sensitivity: CGFloat = 30.0
                            let indexChange = Int(delta / sensitivity)
                            
                            // Calculate new index
                            let newIndex = dragStartIndex + indexChange
                            
                            // Clamp to valid range
                            let clampedIndex = min(max(newIndex, 0), allCases.count - 1)
                            
                            // Update value to exact enum case (no approximation)
                            value = allCases[clampedIndex]
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                .background(
                    RoundedRectangle(cornerRadius: radius)
                        .fill(isDragging ? Color("HighlightColour").opacity(0.1) : Color.clear)
                )
                
                // Right button (>) - Increment
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        incrementValue()
                    }
            }
        }
    }
    
    private var currentIndex: Int {
        allCases.firstIndex(where: { $0.id == value.id }) ?? 0
    }
    
    private func incrementValue() {
        let index = currentIndex
        if index < allCases.count - 1 {
            value = allCases[index + 1]
        }
    }
    
    private func decrementValue() {
        let index = currentIndex
        if index > 0 {
            value = allCases[index - 1]
        }
    }
}

// MARK: - Slider Row (for continuous parameters)

/// A row for adjusting continuous numeric parameters
/// Shows < > buttons on sides with label and value in center (matching ParameterRow style)
/// Drag anywhere in the center area to adjust the value
struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let displayFormatter: (Double) -> String
    
    @State private var isDragging: Bool = false
    @State private var dragStartValue: Double = 0
    @State private var dragStartLocation: CGFloat = 0
    
    @ObservedObject private var sharedButtonWidth = SharedButtonWidth.shared
    
    init(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 0.01,
        displayFormatter: @escaping (Double) -> String
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.displayFormatter = displayFormatter
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            HStack(spacing: 0) {
                let buttonWidth = sharedButtonWidth.width > 0 ? sharedButtonWidth.width : 60
                
                // Left button (<) - Decrease value
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        decrementValue()
                    }
                
                // Center - Draggable area with label and value
                VStack(spacing: 2) {
                    Text(label)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayFormatter(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 24)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            if !isDragging {
                                isDragging = true
                                dragStartValue = value
                                dragStartLocation = gesture.startLocation.x
                            }
                            
                            // Calculate delta from drag start
                            let delta = gesture.location.x - dragStartLocation
                            
                            // Convert pixels to value change
                            let rangeSize = range.upperBound - range.lowerBound
                            let sensitivity: CGFloat = 200.0  // pixels to traverse full range
                            let valueChange = Double(delta) * rangeSize / Double(sensitivity)
                            
                            // Apply change and clamp
                            let newValue = dragStartValue + valueChange
                            
                            // Snap to step
                            let steppedValue = round(newValue / step) * step
                            
                            // Clamp to range
                            value = min(max(steppedValue, range.lowerBound), range.upperBound)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                .background(
                    RoundedRectangle(cornerRadius: radius)
                        .fill(isDragging ? Color("HighlightColour").opacity(0.1) : Color.clear)
                )
                
                // Right button (>) - Increase value
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        incrementValue()
                    }
            }
        }
    }
    
    private func incrementValue() {
        let newValue = value + step
        value = min(newValue, range.upperBound)
    }
    
    private func decrementValue() {
        let newValue = value - step
        value = max(newValue, range.lowerBound)
    }
}

// MARK: - Logarithmic Slider Row (for frequency and other exponential parameters)

/// A row for adjusting logarithmic/exponential parameters (like frequency)
/// Shows < > buttons on sides with label and value in center (matching ParameterRow style)
/// Drag anywhere in the center area to adjust the value logarithmically
/// Equal drag distances correspond to equal ratios (e.g., 40→80 same distance as 4000→8000)
struct LogarithmicSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let displayFormatter: (Double) -> String
    
    @State private var isDragging: Bool = false
    @State private var dragStartValue: Double = 0
    @State private var dragStartLocation: CGFloat = 0
    
    @ObservedObject private var sharedButtonWidth = SharedButtonWidth.shared
    
    init(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        displayFormatter: @escaping (Double) -> String
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.displayFormatter = displayFormatter
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            HStack(spacing: 0) {
                let buttonWidth = sharedButtonWidth.width > 0 ? sharedButtonWidth.width : 60
                
                // Left button (<) - Decrease value
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        decrementValue()
                    }
                
                // Center - Draggable area with label and value
                VStack(spacing: 2) {
                    Text(label)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayFormatter(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 24)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            if !isDragging {
                                isDragging = true
                                dragStartValue = value
                                dragStartLocation = gesture.startLocation.x
                            }
                            
                            // Calculate delta from drag start
                            let delta = gesture.location.x - dragStartLocation
                            
                            // Convert to logarithmic scale
                            // We work in log space where equal distances = equal ratios
                            let logMin = log(range.lowerBound)
                            let logMax = log(range.upperBound)
                            let logRange = logMax - logMin
                            
                            // Current value in log space
                            let logStartValue = log(dragStartValue)
                            
                            // Sensitivity: pixels to traverse full logarithmic range
                            let sensitivity: CGFloat = 200.0
                            let logChange = Double(delta) * logRange / Double(sensitivity)
                            
                            // New value in log space
                            let newLogValue = logStartValue + logChange
                            
                            // Convert back to linear space
                            let newValue = exp(newLogValue)
                            
                            // Clamp to range
                            value = min(max(newValue, range.lowerBound), range.upperBound)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                .background(
                    RoundedRectangle(cornerRadius: radius)
                        .fill(isDragging ? Color("HighlightColour").opacity(0.1) : Color.clear)
                )
                
                // Right button (>) - Increase value
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        incrementValue()
                    }
            }
        }
    }
    
    private func incrementValue() {
        // Increment by a small logarithmic step (e.g., multiply by 1.05, which is ~5% increase)
        let multiplier = 1.05
        let newValue = value * multiplier
        value = min(newValue, range.upperBound)
    }
    
    private func decrementValue() {
        // Decrement by a small logarithmic step (divide by 1.05)
        let divider = 1.05
        let newValue = value / divider
        value = max(newValue, range.lowerBound)
    }
}

// MARK: - Musical Frequency Slider (Quantized to MIDI Notes)

/// A row for adjusting frequency parameters with hybrid behavior:
/// Drag: snaps to nearest MIDI note frequency (musically relevant)
/// Buttons: precise linear 1 Hz steps
/// This combines musical targeting with fine-tuning precision
struct MusicalFrequencySliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let buttonStep: Double  // Linear step for buttons (e.g., 1.0 Hz)
    let displayFormatter: (Double) -> String
    
    @State private var isDragging: Bool = false
    @State private var dragStartValue: Double = 0
    @State private var dragStartLocation: CGFloat = 0
    
    @ObservedObject private var sharedButtonWidth = SharedButtonWidth.shared
    
    init(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        buttonStep: Double = 1.0,  // Default to 1 Hz
        displayFormatter: @escaping (Double) -> String
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.buttonStep = buttonStep
        self.displayFormatter = displayFormatter
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            HStack(spacing: 0) {
                let buttonWidth = sharedButtonWidth.width > 0 ? sharedButtonWidth.width : 60
                
                // Left button (<) - Decrease by fixed linear step
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        decrementValue()
                    }
                
                // Center - Draggable area with label and value
                VStack(spacing: 2) {
                    Text(label)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayFormatter(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 24)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { gesture in
                            if !isDragging {
                                isDragging = true
                                dragStartValue = value
                                dragStartLocation = gesture.startLocation.x
                            }
                            
                            // Calculate delta from drag start
                            let delta = gesture.location.x - dragStartLocation
                            
                            // Convert to MIDI note scale
                            let midiStart = frequencyToMIDI(dragStartValue)
                            
                            // Sensitivity: ~300 pixels to traverse full range
                            let sensitivity: CGFloat = 300.0
                            let midiChange = Double(delta) / Double(sensitivity) * 88.0  // 88 piano keys
                            
                            let newMIDI = midiStart + midiChange
                            
                            // Convert back to frequency and quantize to nearest semitone
                            let quantizedFrequency = midiToFrequency(round(newMIDI))
                            
                            // Clamp to range
                            value = min(max(quantizedFrequency, range.lowerBound), range.upperBound)
                        }
                        .onEnded { _ in
                            isDragging = false
                            // Ensure we're snapped to a MIDI note when done
                            value = midiToFrequency(round(frequencyToMIDI(value)))
                        }
                )
                .background(
                    RoundedRectangle(cornerRadius: radius)
                        .fill(isDragging ? Color("HighlightColour").opacity(0.1) : Color.clear)
                )
                
                // Right button (>) - Increase by fixed linear step
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        incrementValue()
                    }
            }
        }
    }
    
    private func incrementValue() {
        // Linear step (e.g., +1 Hz for fine-tuning)
        let newValue = value + buttonStep
        value = min(newValue, range.upperBound)
    }
    
    private func decrementValue() {
        // Linear step (e.g., -1 Hz for fine-tuning)
        let newValue = value - buttonStep
        value = max(newValue, range.lowerBound)
    }
    
    // MIDI conversion helpers (used for drag quantization only)
    private func frequencyToMIDI(_ frequency: Double) -> Double {
        return 69.0 + 12.0 * log2(frequency / 440.0)
    }
    
    private func midiToFrequency(_ midi: Double) -> Double {
        return 440.0 * pow(2.0, (midi - 69.0) / 12.0)
    }
}

// MARK: - Quantized Logarithmic Slider (5 Hz or 10 Hz Steps)

/// A row for adjusting logarithmic parameters with quantization
/// Drag: logarithmic behavior with quantized steps
/// Buttons: fixed step size (e.g., 5 Hz or 10 Hz)
/// This provides a good balance between musical precision and ease of targeting
struct QuantizedLogarithmicSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let quantization: Double  // e.g., 5.0 for 5 Hz steps
    let buttonStep: Double    // e.g., 10.0 for 10 Hz button increments
    let displayFormatter: (Double) -> String
    
    @State private var isDragging: Bool = false
    @State private var dragStartValue: Double = 0
    @State private var dragStartLocation: CGFloat = 0
    
    @ObservedObject private var sharedButtonWidth = SharedButtonWidth.shared
    
    init(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        quantization: Double = 5.0,
        buttonStep: Double? = nil,
        displayFormatter: @escaping (Double) -> String
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.quantization = quantization
        self.buttonStep = buttonStep ?? quantization
        self.displayFormatter = displayFormatter
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            HStack(spacing: 0) {
                let buttonWidth = sharedButtonWidth.width > 0 ? sharedButtonWidth.width : 60
                
                // Left button (<) - Decrease by button step
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        decrementValue()
                    }
                
                // Center - Draggable area with label and value
                VStack(spacing: 2) {
                    Text(label)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayFormatter(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 24)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { gesture in
                            if !isDragging {
                                isDragging = true
                                dragStartValue = value
                                dragStartLocation = gesture.startLocation.x
                            }
                            
                            // Calculate delta from drag start
                            let delta = gesture.location.x - dragStartLocation
                            
                            // Convert to logarithmic scale
                            let logMin = log(range.lowerBound)
                            let logMax = log(range.upperBound)
                            let logRange = logMax - logMin
                            
                            let logStartValue = log(dragStartValue)
                            
                            // Sensitivity: pixels to traverse full logarithmic range
                            let sensitivity: CGFloat = 200.0
                            let logChange = Double(delta) * logRange / Double(sensitivity)
                            
                            let newLogValue = logStartValue + logChange
                            let newValue = exp(newLogValue)
                            
                            // Quantize to nearest step
                            let quantizedValue = round(newValue / quantization) * quantization
                            
                            // Clamp to range
                            value = min(max(quantizedValue, range.lowerBound), range.upperBound)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                .background(
                    RoundedRectangle(cornerRadius: radius)
                        .fill(isDragging ? Color("HighlightColour").opacity(0.1) : Color.clear)
                )
                
                // Right button (>) - Increase by button step
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        incrementValue()
                    }
            }
        }
    }
    
    private func incrementValue() {
        let newValue = value + buttonStep
        let quantizedValue = round(newValue / quantization) * quantization
        value = min(quantizedValue, range.upperBound)
    }
    
    private func decrementValue() {
        let newValue = value - buttonStep
        let quantizedValue = round(newValue / quantization) * quantization
        value = max(quantizedValue, range.lowerBound)
    }
}

// MARK: - Logarithmic Slider with Linear Button Steps

/// A row for adjusting logarithmic/exponential parameters with fixed linear button steps
/// Drag: logarithmic behavior (equal distances = equal ratios)
/// Buttons: fixed linear steps (e.g., always ±1 Hz for filter cutoff)
/// This is ideal for filter cutoff where precise tuning is needed at specific frequencies
struct LogarithmicSliderRowWithLinearButtons: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let buttonStep: Double  // Fixed step for increment/decrement buttons (e.g., 1.0 Hz)
    let displayFormatter: (Double) -> String
    
    @State private var isDragging: Bool = false
    @State private var dragStartValue: Double = 0
    @State private var dragStartLocation: CGFloat = 0
    
    @ObservedObject private var sharedButtonWidth = SharedButtonWidth.shared
    
    init(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        buttonStep: Double,
        displayFormatter: @escaping (Double) -> String
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.buttonStep = buttonStep
        self.displayFormatter = displayFormatter
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            HStack(spacing: 0) {
                let buttonWidth = sharedButtonWidth.width > 0 ? sharedButtonWidth.width : 60
                
                // Left button (<) - Decrease value by fixed step
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        decrementValue()
                    }
                
                // Center - Draggable area with label and value
                VStack(spacing: 2) {
                    Text(label)
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayFormatter(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 24)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { gesture in
                            if !isDragging {
                                isDragging = true
                                dragStartValue = value
                                dragStartLocation = gesture.startLocation.x
                            }
                            
                            // Special case: if starting from zero, treat it as if starting from range minimum
                            let effectiveStartValue = dragStartValue == 0.0 ? range.lowerBound : dragStartValue
                            
                            // Calculate delta from drag start
                            let delta = gesture.location.x - dragStartLocation
                            
                            // Convert to logarithmic scale
                            // We work in log space where equal distances = equal ratios
                            let logMin = log(range.lowerBound)
                            let logMax = log(range.upperBound)
                            let logRange = logMax - logMin
                            
                            // Current value in log space
                            let logStartValue = log(effectiveStartValue)
                            
                            // Sensitivity: pixels to traverse full logarithmic range
                            let sensitivity: CGFloat = 200.0
                            let logChange = Double(delta) * logRange / Double(sensitivity)
                            
                            // New value in log space
                            let newLogValue = logStartValue + logChange
                            
                            // Convert back to linear space
                            let newValue = exp(newLogValue)
                            
                            // Clamp to range (minimum is range.lowerBound, zero can only be set via button)
                            value = min(max(newValue, range.lowerBound), range.upperBound)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                .background(
                    RoundedRectangle(cornerRadius: radius)
                        .fill(isDragging ? Color("HighlightColour").opacity(0.1) : Color.clear)
                )
                
                // Right button (>) - Increase value by fixed step
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .frame(width: buttonWidth)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        incrementValue()
                    }
            }
        }
    }
    
    private func incrementValue() {
        // Special case: if at zero, jump to the range minimum
        if value == 0.0 {
            value = range.lowerBound
        } else {
            // Fixed linear step (e.g., +1 Hz)
            let newValue = value + buttonStep
            value = min(newValue, range.upperBound)
        }
    }
    
    private func decrementValue() {
        // Special case: if at or near the minimum (within one step), snap to zero
        if value <= range.lowerBound || value <= buttonStep {
            value = 0.0
        } else {
            // Fixed linear step (e.g., -1 Hz)
            let newValue = value - buttonStep
            value = max(newValue, range.lowerBound)
        }
    }
}

// MARK: - Integer Slider Row (convenience wrapper)

/// Convenience wrapper for integer-valued sliders
struct IntegerSliderRow: View {
    let label: String
    @Binding var value: Double  // Still Double for AudioKit compatibility
    let range: ClosedRange<Int>
    
    var body: some View {
        SliderRow(
            label: label,
            value: $value,
            range: Double(range.lowerBound)...Double(range.upperBound),
            step: 1.0,
            displayFormatter: { value in
                String(Int(round(value)))
            }
        )
    }
}

// MARK: - Preview Helper

private struct ParameterComponentsPreview: View {
    @State private var waveform: OscillatorWaveform = .sine
    @State private var multiplier: Double = 8.0
    @State private var fineValue: Double = 0.5
    @State private var detuneMode: DetuneMode = .proportional
    @State private var cutoffFrequency: Double = 880.0  // Start at A5 (musical frequency)
    @State private var cutoffFrequency2: Double = 1760.0  // Start at A6
    
    var body: some View {
        ZStack {
            Color("BackgroundColour").ignoresSafeArea()
            
            VStack(spacing: 11) {
                Text("Hybrid: MIDI Snap (Drag) + 1 Hz Steps (Buttons)")
                    .foregroundColor(Color("HighlightColour"))
                    .adaptiveFont("MontserratAlternates-Medium", size: 14)
                    .multilineTextAlignment(.center)
                
                // Example: Musical frequency slider with 1 Hz button steps
                MusicalFrequencySliderRow(
                    label: "FILTER CUTOFF",
                    value: $cutoffFrequency,
                    range: 55...14080,
                    buttonStep: 1.0,  // Precise 1 Hz increments
                    displayFormatter: { value in
                        return String(format: "%.0f Hz", value)
                    }
                )
                
                Text("Drag to snap to musical notes • Buttons for 1 Hz precision")
                    .foregroundColor(Color("HighlightColour").opacity(0.6))
                    .adaptiveFont("MontserratAlternates-Medium", size: 12)
                    .multilineTextAlignment(.center)
                
                Divider().background(Color("HighlightColour").opacity(0.3))
                
                // Other examples
                ParameterRow(
                    label: "WAVEFORM",
                    value: $waveform,
                    displayText: { $0.displayName }
                )
                
                IntegerSliderRow(
                    label: "CARRIER MULTIPLIER",
                    value: $multiplier,
                    range: 1...16
                )
            }
            .padding(25)
        }
    }
}

#Preview {
    ParameterComponentsPreview()
}
