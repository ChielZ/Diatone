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
        VStack{
            Text("This is where the manual will be shown")
                .foregroundColor(Color("HighlightColour"))
                .adaptiveFont("MontserratAlternates-Medium", size: 12)
        ZStack { // Row 9
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("HighlightColour"))
                GeometryReader { geometry in
                    Text("･CLOSE MANUAL･")
                        .foregroundColor(Color("BackgroundColour"))
                        .adaptiveFont("MontserratAlternates-Medium", size: 30)
                        .minimumScaleFactor(0.5)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        //.offset(y: -(geometry.size.height/2 + 11))
                        .padding(0)
                        .onTapGesture {
                            onSwitchToOptions?()
                        }
                }
            }
        }
    }
}

#Preview {
    ManualView()
}
