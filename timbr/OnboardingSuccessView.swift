//
//  OnboardingSuccessView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct OnboardingSuccessView: View {
    let onShowSwipe: () -> Void
    @ObservedObject var onboardingManager: OnboardingManager
    @StateObject private var propertyService = PropertyService()
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var isLoadingProperties = true
    @State private var loadingMessage = "Loading properties..."
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.timbrDark.opacity(1.0),
                    Color.timbrDark.opacity(0.9)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(Color.timbrAccent.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.timbrAccent)
                        .scaleEffect(checkmarkScale)
                        .opacity(checkmarkOpacity)
                }
                .padding(.bottom, 20)
                
                // Success message
                VStack(spacing: 12) {
                    Text("Your Timbr deck is ready.")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(textOpacity)
                    
                    Text("Based on your preferences, we've curated homes you'll love.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(textOpacity)
                }
                
                Spacer()
                
                // Loading indicator or Start Swiping button
                if isLoadingProperties {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .timbrAccent))
                            .scaleEffect(1.2)
                        
                        Text(loadingMessage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .opacity(textOpacity)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                } else {
                    // Start Swiping button
                    Button(action: {
                        onShowSwipe()
                    }) {
                        Text("Start Swiping")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.timbrAccent)
                            .cornerRadius(30)
                    }
                    .opacity(textOpacity)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            // Animate checkmark
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }
            
            // Animate text after checkmark
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeIn(duration: 0.5)) {
                    textOpacity = 1.0
                }
            }
            
            // Start loading properties
            Task {
                await loadProperties()
            }
        }
    }
    
    private func loadProperties() async {
        isLoadingProperties = true
        loadingMessage = "Loading properties..."
        
        // Set onboardingManager reference for API location fetching
        propertyService.onboardingManager = onboardingManager
        
        // Load properties
        await propertyService.loadProperties()
        
        // Update loading message based on result
        if propertyService.properties.isEmpty {
            loadingMessage = "No properties found. Try adjusting your preferences."
        } else {
            loadingMessage = "Found \(propertyService.properties.count) properties!"
            
            // Share properties with interaction manager
            PropertyInteractionManager.shared.setProperties(propertyService.properties)
        }
        
        // Small delay to show the success message
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        isLoadingProperties = false
    }
}

