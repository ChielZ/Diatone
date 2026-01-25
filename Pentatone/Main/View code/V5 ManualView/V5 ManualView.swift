//
//  V5 ManualView.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 10/01/2026.
//

import SwiftUI

struct ManualView: View {
    var onSwitchToOptions: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("HighlightColour"))
                .padding(5)
            
            RoundedRectangle(cornerRadius: radius)
                .fill(Color("BackgroundColour"))
                .padding(9)
            
            VStack(spacing: 11) {
                ZStack { // Row 1 - Fold Button
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
                            onSwitchToOptions?()
                        }
                }
                .frame(maxHeight: .infinity)
                
                // Row 2 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 3 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 4 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 5 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 6 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 7 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 8 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 9 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                // Row 10 - Empty
                Color.clear.frame(maxHeight: .infinity)
                
                ZStack { // Row 11 - Close Manual Button
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("HighlightColour"))
                    GeometryReader { geometry in
                        Text("･CLOSE MANUAL･")
                            .foregroundColor(Color("BackgroundColour"))
                            .adaptiveFont("MontserratAlternates-Medium", size: 30)
                            .minimumScaleFactor(0.5)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .padding(0)
                            .onTapGesture {
                                onSwitchToOptions?()
                            }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .padding(19)
            .overlay(
                // Overlay the scrollable content on top of rows 2-10
                GeometryReader { geometry in
                    let totalHeight = geometry.size.height - 38 // Account for padding (19 * 2)
                    let spacing: CGFloat = 11
                    let rowHeight = (totalHeight - (spacing * 10)) / 11 // 11 rows, 10 spacings
                    let contentTop = rowHeight + spacing // After row 1
                    let contentHeight = rowHeight * 9 + spacing * 8 // 9 rows and 8 spacings between them
                    
                    VStack {
                        Spacer()
                            .frame(height: contentTop)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: radius)
                                .fill(Color("BackgroundColour"))
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Welcome to Arithmophone")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 24)
                                        .padding(.bottom, 5)
                                    
                                    Text("This is where the manual content will be displayed. You can add detailed information about your music keyboard app here.")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 16)
                                    
                                    Text("Getting Started")
                                        .foregroundColor(Color("KeyColour1"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                    
                                    Text("Add your getting started instructions here...")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 16)
                                    
                                    Text("Features")
                                        .foregroundColor(Color("KeyColour2"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 20)
                                        .padding(.top, 10)
                                    
                                    Text("Add information about features here...")
                                        .foregroundColor(Color("HighlightColour"))
                                        .adaptiveFont("MontserratAlternates-Medium", size: 16)
                                    
                                    // Add more content as needed
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(height: contentHeight)
                        
                        Spacer()
                    }
                    .padding(19)
                }
            )
        }
    }
}

#Preview {
    ManualView()
}
