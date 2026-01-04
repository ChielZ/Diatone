//
//  V4-C ParameterComponents.swift
//  Pentatone
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
    
    init(label: String, value: Binding<T>, displayText: @escaping (T) -> String) {
        self.label = label
        self._value = value
        self.displayText = displayText
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
            
            HStack {
                // Left button (<)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("Futura", size: 30)
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
                        .adaptiveFont("Futura", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayText(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("Futura", size: 24)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Right button (>)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("Futura", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cycleNext()
                    }
            }
            .padding(.horizontal, 0)
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
            
            HStack {
                // Left button (<) - Decrease value
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("Futura", size: 30)
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
                        .adaptiveFont("Futura", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayFormatter(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("Futura", size: 24)
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
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("Futura", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        incrementValue()
                    }
            }
            .padding(.horizontal, 0)
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
            
            HStack {
                // Left button (<) - Decrease value
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("Futura", size: 30)
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
                        .adaptiveFont("Futura", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayFormatter(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("Futura", size: 24)
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
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("Futura", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        incrementValue()
                    }
            }
            .padding(.horizontal, 0)
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
            
            HStack {
                // Left button (<) - Decrease value by fixed step
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        Text("<")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("Futura", size: 30)
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
                        .adaptiveFont("Futura", size: 18)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(displayFormatter(value))
                        .foregroundColor(Color("HighlightColour"))
                        .adaptiveFont("Futura", size: 24)
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
                
                // Right button (>) - Increase value by fixed step
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("SupportColour"))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        Text(">")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("Futura", size: 30)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        incrementValue()
                    }
            }
            .padding(.horizontal, 0)
        }
    }
    
    private func incrementValue() {
        // Fixed linear step (e.g., +1 Hz)
        let newValue = value + buttonStep
        value = min(newValue, range.upperBound)
    }
    
    private func decrementValue() {
        // Fixed linear step (e.g., -1 Hz)
        let newValue = value - buttonStep
        value = max(newValue, range.lowerBound)
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
    @State private var cutoffFrequency: Double = 1000.0
    
    var body: some View {
        ZStack {
            Color("BackgroundColour").ignoresSafeArea()
            
            VStack(spacing: 11) {
                // Example: Enum cycling
                ParameterRow(
                    label: "WAVEFORM",
                    value: $waveform,
                    displayText: { $0.displayName }
                )
                
                // Example: Integer slider
                IntegerSliderRow(
                    label: "CARRIER MULTIPLIER",
                    value: $multiplier,
                    range: 1...16
                )
                
                // Example: Continuous slider
                SliderRow(
                    label: "MODULATOR FINE",
                    value: $fineValue,
                    range: 0...1,
                    step: 0.01,
                    displayFormatter: { String(format: "%.2f", $0) }
                )
                
                // Example: Logarithmic slider with linear button steps (for filter)
                LogarithmicSliderRowWithLinearButtons(
                    label: "FILTER CUTOFF",
                    value: $cutoffFrequency,
                    range: 20...20000,
                    buttonStep: 1.0,  // Always ±1 Hz per button press
                    displayFormatter: { value in
                        if value < 1000 {
                            return String(format: "%.0f Hz", value)
                        } else {
                            return String(format: "%.1f kHz", value / 1000)
                        }
                    }
                )
                
                // Example: Another enum
                ParameterRow(
                    label: "STEREO MODE",
                    value: $detuneMode,
                    displayText: { $0.displayName }
                )
            }
            .padding(0)
        }
    }
}

#Preview {
    ParameterComponentsPreview()
}
