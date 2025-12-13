//
//  ScaleView.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 06/12/2025.
//

import SwiftUI

struct ScaleView: View {
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
                                .font(.custom("Futura",size:30))
                                .frame(width:40,height:20,alignment:.center)
                        )
                    Spacer()
                    Text("JI")
                        .foregroundColor(Color("HighlightColour"))
                        .font(.custom("Futura",size:30))
                        .frame(width:200,height:20,alignment:.center)
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .font(.custom("Futura",size:30))
                                .frame(width:40,height:20,alignment:.center)
                        )
                }
            }
            ZStack { // Row 4
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    
                }
            }
            ZStack { // Row 5
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    
                }
            }
            ZStack { // Row 6
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("<")
                                .foregroundColor(Color("BackgroundColour"))
                                .font(.custom("Futura",size:30))
                                .frame(width:40,height:20,alignment:.center)
                        )
                    Spacer()
                    Text("D")
                        .foregroundColor(Color("HighlightColour"))
                        .font(.custom("Futura",size:30))
                        .frame(width:200,height:20,alignment:.center)
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .font(.custom("Futura",size:30))
                                .frame(width:40,height:20,alignment:.center)
                        )
                }
            }
            ZStack { // Row 7
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("<")
                                .foregroundColor(Color("BackgroundColour"))
                                .font(.custom("Futura",size:30))
                                .frame(width:40,height:20,alignment:.center)
                        )
                    Spacer()
                    Text("MOON")
                        .foregroundColor(Color("HighlightColour"))
                        .font(.custom("Futura",size:30))
                        .frame(width:200,height:20,alignment:.center)
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .font(.custom("Futura",size:30))
                                .frame(width:40,height:20,alignment:.center)
                        )
                }
            }
            ZStack { // Row 8
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("<")
                                .foregroundColor(Color("BackgroundColour"))
                                .font(.custom("Futura",size:30))
                                .frame(width:40,height:20,alignment:.center)
                        )
                    Spacer()
                    Text("ORIENT")
                        .foregroundColor(Color("HighlightColour"))
                        .font(.custom("Futura",size:30))
                        .frame(width:200,height:20,alignment:.center)
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .font(.custom("Futura",size:30))
                                .frame(width:40,height:20,alignment:.center)
                        )
                }
            }
            ZStack { // Row 9
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color("BackgroundColour"))
                HStack {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text("<")
                                .foregroundColor(Color("BackgroundColour"))
                                .font(.custom("Futura",size:30))
                                .frame(width:40,height:20,alignment:.center)
                        )
                    Spacer()
                    Text("0")
                        .foregroundColor(Color("HighlightColour"))
                        .font(.custom("Futura",size:30))
                        .frame(width:200,height:20,alignment:.center)
                    Spacer()
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color("SupportColour"))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(">")
                                .foregroundColor(Color("BackgroundColour"))
                                .font(.custom("Futura",size:30))
                                .frame(width:40,height:20,alignment:.center)
                        )
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color("BackgroundColour").ignoresSafeArea()
        VStack {
            ScaleView()
        }
        .padding(25)
    }
}
