//
//  TooltipView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 10/01/2026.
//

import SwiftUI

// MARK: - Tooltip View Modifier

/// A view modifier that adds a localized tooltip/help overlay
/// Usage: .tooltip(key: "keyboard.fold.help")
struct TooltipModifier: ViewModifier {
    let localizedKey: String
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
            .overlay(alignment: .top) {
                if isPresented {
                    TooltipBubble(text: String(localized: LocalizedStringResource(stringLiteral: localizedKey)))
                        .transition(.scale.combined(with: .opacity))
                }
            }
    }
}

// MARK: - Tooltip Bubble View

struct TooltipBubble: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal)
            .offset(y: -10)
    }
}

// MARK: - View Extension

extension View {
    /// Adds a localized tooltip that appears on long press
    /// - Parameter key: The localization key for the tooltip text
    func tooltip(key: String) -> some View {
        modifier(TooltipModifier(localizedKey: key))
    }
}

// MARK: - Help Button Component

/// A question mark button that shows help text when tapped
struct HelpButton: View {
    let helpKey: String
    @State private var isShowingHelp = false
    
    var body: some View {
        Button {
            isShowingHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        .alert(
            String(localized: "help.title", defaultValue: "Help"),
            isPresented: $isShowingHelp
        ) {
            Button(String(localized: "help.dismiss", defaultValue: "Got it")) {
                isShowingHelp = false
            }
        } message: {
            Text(LocalizedStringResource(stringLiteral: helpKey))
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
            .tooltip(key: "tooltip.keyboard.fold")
            
            // Example 2: Help button with alert
            HStack {
                Text("Voice Mode")
                Spacer()
                HelpButton(helpKey: "help.voicemode")
            }
        }
        .padding()
    }
}

#Preview {
    TooltipExampleView()
}
