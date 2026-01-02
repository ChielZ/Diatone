//
//  V4-S10 ParameterPage10View.swift
//  Pentatone
//
//  Created by Chiel Zwinkels on 25/12/2025.
// SUBVIEW 10 - PRESET MANAGEMENT


 import SwiftUI

 struct PresetView: View {
     var body: some View {
         Group {
             ZStack { // Row 3
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 HStack {
                     RoundedRectangle(cornerRadius: radius)
                         .fill(Color("SupportColour"))
                         .aspectRatio(1.0, contentMode: .fit)
                         .overlay(
                             Text("<")
                                 .foregroundColor(Color("BackgroundColour"))
                                 .adaptiveFont("Futura", size: 30)
                         )
                     Spacer()
                     Text("BANK 1")
                         .foregroundColor(Color("HighlightColour"))
                         .adaptiveFont("Futura", size: 30)
                     Spacer()
                     RoundedRectangle(cornerRadius: radius)
                         .fill(Color("SupportColour"))
                         .aspectRatio(1.0, contentMode: .fit)
                         .overlay(
                             Text(">")
                                 .foregroundColor(Color("BackgroundColour"))
                                 .adaptiveFont("Futura", size: 30)
                         )
                 }
             }
             ZStack { // Row 4
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
                 HStack {
                     RoundedRectangle(cornerRadius: radius)
                         .fill(Color("SupportColour"))
                         .aspectRatio(1.0, contentMode: .fit)
                         .overlay(
                             Text("<")
                                 .foregroundColor(Color("BackgroundColour"))
                                 .adaptiveFont("Futura", size: 30)
                         )
                     Spacer()
                     Text("1.1 KEYS")
                         .foregroundColor(Color("HighlightColour"))
                         .adaptiveFont("Futura", size: 30)
                     Spacer()
                     RoundedRectangle(cornerRadius: radius)
                         .fill(Color("SupportColour"))
                         .aspectRatio(1.0, contentMode: .fit)
                         .overlay(
                             Text(">")
                                 .foregroundColor(Color("BackgroundColour"))
                                 .adaptiveFont("Futura", size: 30)
                         )
                 }
             }
             ZStack { // Row 5
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("SupportColour"))
                 GeometryReader { geometry in
                     Text("•SAVE PRESET•")
                         .foregroundColor(Color("BackgroundColour"))
                         .adaptiveFont("Futura", size: 30)
                         .frame(width: geometry.size.width, height: geometry.size.height)
                         .contentShape(Rectangle())
                         //.offset(y: -(geometry.size.height/2 + 11))
                         .padding(0)
                 }
             }
             ZStack { // Row 6
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("SupportColour"))
                 GeometryReader { geometry in
                     Text("•IMPORT PRESET•")
                         .foregroundColor(Color("BackgroundColour"))
                         .adaptiveFont("Futura", size: 30)
                         .frame(width: geometry.size.width, height: geometry.size.height)
                         .contentShape(Rectangle())
                         //.offset(y: -(geometry.size.height/2 + 11))
                         .padding(0)
                 }
             }
             ZStack { // Row 7
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("SupportColour"))
                 GeometryReader { geometry in
                     Text("•EXPORT PRESET•")
                         .foregroundColor(Color("BackgroundColour"))
                         .adaptiveFont("Futura", size: 30)
                         .frame(width: geometry.size.width, height: geometry.size.height)
                         .contentShape(Rectangle())
                         //.offset(y: -(geometry.size.height/2 + 11))
                         .padding(0)
                 }
             }
             
             ZStack { // Row 8
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
             }
             ZStack { // Row 9
                 RoundedRectangle(cornerRadius: radius)
                     .fill(Color("BackgroundColour"))
             }
         }
     }
 }

 #Preview {
     ZStack {
         Color("BackgroundColour").ignoresSafeArea()
         VStack {
             PresetView()
         }
         .padding(25)
     }
 }

 
