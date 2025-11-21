//
//  ContentView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    @StateObject private var onboardingManager = OnboardingManager()
    @State private var showOnboarding = false
    
    var body: some View {
        NavigationStack {
            if authManager.isSignedIn && !showOnboarding {
                // Check if user has completed onboarding
                OnboardingCheckView(
                    authManager: authManager,
                    onboardingManager: onboardingManager,
                    showOnboarding: $showOnboarding
                )
            } else if showOnboarding {
                OnboardingView()
                    .onAppear {
                        Task {
                            await onboardingManager.loadPreferences()
                        }
                    }
            } else {
                WelcomeView(authManager: authManager, showOnboarding: $showOnboarding)
            }
        }
    }
}

struct WelcomeView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var showOnboarding: Bool
    @State private var isSigningIn = false
    
    private let features = [
        "Personalized swipe deck",
        "Quick intent setup",
        "Matches & archives synced"
    ]
    
    var body: some View {
        ZStack {
            // Solid dark background for entire screen
            Color.timbrDark
                .ignoresSafeArea()
            
            // House image - only visible in top portion with gradient fade
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    ZStack {
                        Image("houseBackground")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.35)
                            .clipped()
                        
                        // Gradient overlay that fades the house image out
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.timbrDark.opacity(0.0),
                                Color.timbrDark.opacity(0.3),
                                Color.timbrDark.opacity(0.7),
                                Color.timbrDark.opacity(1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: geometry.size.height * 0.35)
                    }
                    
                    // Solid dark background for rest of screen
                    Color.timbrDark
                        .frame(height: geometry.size.height * 0.65)
                    
                    Spacer()
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer().frame(height: 40)
                
                // Title + Logo
                VStack(spacing: 16) {
                    Text("Welcome to")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Image("TimbrLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                }
                
                // Card with description & feature bullets
                VStack(alignment: .leading, spacing: 20) {
                    Text("Swipe into homes, investments, and inspirations tailored to how you live and what you're searching for.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Divider().background(Color.white.opacity(0.15))
                    
                    VStack(spacing: 12) {
                        FeatureRow(text: "Personalized swipe deck")
                        FeatureRow(text: "Quick intent setup")
                        FeatureRow(text: "Matches & archives synced")
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Google button
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            isSigningIn = true
                            await authManager.signInWithGoogle()
                            isSigningIn = false
                            if authManager.isSignedIn {
                                // Check if user needs onboarding
                                let manager = OnboardingManager()
                                await manager.loadPreferences()
                                if !manager.preferences.hasCompletedOnboarding {
                                    showOnboarding = true
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 10) {
                            if isSigningIn {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                            }
                            Text(isSigningIn ? "Signing in..." : "Continue with Google")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(30)
                    }
                    .disabled(isSigningIn)
                    .padding(.horizontal, 24)
                    
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Text("We only use your Google account to secure sign-in and sync your swipes.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 32)
                }
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.timbrAccent)
            }
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
}

// MARK: - Colors
extension Color {
    /// #173c40
    static let timbrDark = Color(red: 0x17 / 255.0,
                                 green: 0x3c / 255.0,
                                 blue: 0x40 / 255.0)
    
    static let timbrAccent = Color(red: 0x6F / 255.0,
                                   green: 0xE7 / 255.0,
                                   blue: 0xD2 / 255.0)
}

#Preview {
    WelcomeView(
        authManager: AuthManager(),
        showOnboarding: .constant(false)
    )
    .previewDevice("iPhone 15 Pro")
}
