//
//  V1 StartupView.swift
//  Diatone
//
//  Created by Chiel Zwinkels on 04/12/2025.
//

import SwiftUI

struct StartupView: View {
    var body: some View {
        Color("BackgroundColour")
            .overlay {
                Image("Diatone startup icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 1024, maxHeight: 1024)
            }
            .ignoresSafeArea()
            .statusBar(hidden: true)
    }
}

#Preview {
    StartupView()
}
