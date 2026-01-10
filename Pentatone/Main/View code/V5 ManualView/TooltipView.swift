//
//  TooltipView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 10/01/2026.
//

import SwiftUI

// MARK: - Tooltip View Modifier

/// A view modifier that adds a tooltip/help overlay on long press
/// Usage: .tooltip("Tap to fold the keyboard")
struct TooltipModifier: ViewModifier {
    let text: String
    @State private var isPresented = false
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: 0.5) {
                withAnimation(.spring(response: 0.3)) {
                    isPresented = true
                }
                
                // Auto-dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.spring(response: 0.3)) {
                        isPresented = false
                    }
                }
            }
            .overlay(
                Group {
                    if isPresented {
                        VStack {
                            TooltipBubble(text: text)
                            Spacer()
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
    }
}

// MARK: - Tooltip Bubble View

struct TooltipBubble: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Material.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal)
            .offset(y: -10)
    }
}

// MARK: - View Extension

extension View {
    /// Adds a tooltip that appears on long press
    /// - Parameter text: The text to display in the tooltip
    func tooltip(_ text: String) -> some View {
        modifier(TooltipModifier(text: text))
    }
}

// MARK: - Help Button Component

/// A question mark button that shows help text when tapped
struct HelpButton: View {
    let helpText: String
    @State private var isShowingHelp = false
    
    var body: some View {
        Button {
            isShowingHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
                .foregroundColor(.secondary)
                .font(.callout)
        }
        .alert(isPresented: $isShowingHelp) {
            Alert(
                title: Text("Help"),
                message: Text(helpText),
                dismissButton: .default(Text("Got it"))
            )
        }
    }
}

// MARK: - Example Usage

struct TooltipExampleView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Example 1: Long-press tooltip
            Button("Fold Keyboard") {
                // Action
            }
            .tooltip("Long press any button to see help text")
            
            // Example 2: Help button with alert
            HStack {
                Text("Voice Mode")
                Spacer()
                HelpButton(helpText: "Choose between polyphonic (multiple notes) and monophonic (single note) playing modes.")
            }
        }
        .padding()
    }
}

#Preview {
    TooltipExampleView()
}
