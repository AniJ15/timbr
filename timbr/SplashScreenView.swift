//
//  SplashScreenView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    
    var body: some View {
        if isActive {
            ContentView()
                .preferredColorScheme(.dark)
        } else {
            ZStack {
                Color.timbrDark
                    .ignoresSafeArea()
                
                Image("TimbrLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .opacity(opacity)
            }
            .onAppear {
                withAnimation(.easeIn(duration: 0.6)) {
                    opacity = 1.0
                }
                
                // Delay before showing main content
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        opacity = 0.0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isActive = true
                    }
                }
            }
        }
    }
}

