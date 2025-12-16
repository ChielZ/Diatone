//
//  StartupView.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 04/12/2025.
//

import SwiftUI

struct StartupView: View {
    var body: some View {
        ZStack{
            Color("BackgroundColour").ignoresSafeArea()
           // Rectangle()
             //   .ignoresSafeArea()
               // .fill()
            
            Image("Penta-Tone icon dark")
                .resizable().aspectRatio(contentMode: .fit)
        }.statusBar(hidden: true)
    }
}

#Preview {
    StartupView()
}
