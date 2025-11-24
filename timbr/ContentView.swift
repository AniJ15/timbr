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
    @State private var showMainApp = false
    @State private var hasCheckedOnboarding = false
    
    var body: some View {
        NavigationStack {
            if showMainApp {
                MainTabView(onboardingManager: onboardingManager)
            } else if showOnboarding {
                OnboardingView()
                    .onAppear {
                        Task {
                            await onboardingManager.loadPreferences()
                        }
                    }
            } else {
                WelcomeView(
                    authManager: authManager,
                    showOnboarding: $showOnboarding,
                    showMainApp: $showMainApp,
                    onboardingManager: onboardingManager
                )
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: authManager.isSignedIn) { oldValue, newValue in
            if !newValue {
                // User signed out, return to welcome screen
                showMainApp = false
                showOnboarding = false
            }
        }
        // Mock data generation removed - only using HasData Zillow API now
    }
}

struct WelcomeView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var showOnboarding: Bool
    @Binding var showMainApp: Bool
    @ObservedObject var onboardingManager: OnboardingManager
    @State private var isSigningUp = false
    @State private var showLoginSheet = false
    @State private var loginErrorMessage: String?
    
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
                
                // Sign up and Log in buttons
                VStack(spacing: 16) {
                    // Sign up button
                    Button(action: {
                        Task {
                            isSigningUp = true
                            await authManager.signInWithGoogle(clearAccountsFirst: false)
                            isSigningUp = false
                            
                            // After successful sign-up, navigate to onboarding
                            if authManager.isSignedIn {
                                print("🔐 User signed up, checking onboarding status...")
                                
                                // Try to load preferences, but navigate to onboarding regardless
                                await onboardingManager.loadPreferences()
                                
                                print("📋 Onboarding status - hasCompletedOnboarding: \(onboardingManager.preferences.hasCompletedOnboarding)")
                                
                                // Always show onboarding if not completed
                                if !onboardingManager.preferences.hasCompletedOnboarding {
                                    print("➡️ Navigating to onboarding...")
                                    showOnboarding = true
                                } else {
                                    // User has completed onboarding - show main app
                                    print("✅ User has completed onboarding - showing main app")
                                    showMainApp = true
                                }
                            } else {
                                print("❌ Sign-up failed")
                            }
                        }
                    }) {
                        HStack(spacing: 10) {
                            if isSigningUp {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                            }
                            Text(isSigningUp ? "Signing up..." : "Sign up with Google")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(30)
                    }
                    .disabled(isSigningUp)
                    .padding(.horizontal, 24)
                    
                    // Log in button
                    Button(action: {
                        showLoginSheet = true
                    }) {
                        Text("Log in")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
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
            .sheet(isPresented: $showLoginSheet) {
                LoginSheetView(
                    authManager: authManager,
                    onboardingManager: onboardingManager,
                    showMainApp: $showMainApp,
                    loginErrorMessage: $loginErrorMessage
                )
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


// MARK: - Login Sheet View
struct LoginSheetView: View {
    @ObservedObject var authManager: AuthManager
    @ObservedObject var onboardingManager: OnboardingManager
    @Binding var showMainApp: Bool
    @Binding var loginErrorMessage: String?
    @Environment(\.dismiss) var dismiss
    @State private var isLoggingIn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.timbrDark
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image("TimbrLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                        
                        Text("Log in to timbr")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Sign in with your Google account to access your saved preferences and matches.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Button(action: {
                            Task {
                                isLoggingIn = true
                                loginErrorMessage = nil
                                
                                await authManager.signInWithGoogle(clearAccountsFirst: false)
                                
                                if authManager.isSignedIn {
                                    // Check if user has an account
                                    let hasAccount = await onboardingManager.checkIfUserHasAccount()
                                    
                                    if hasAccount {
                                        // Load preferences and navigate to main app
                                        await onboardingManager.loadPreferences()
                                        dismiss()
                                        showMainApp = true
                                    } else {
                                        // User doesn't have an account
                                        loginErrorMessage = "No account found. Please sign up first."
                                        await authManager.signOut()
                                    }
                                } else {
                                    // Sign-in failed
                                    loginErrorMessage = authManager.errorMessage ?? "Failed to sign in. Please try again."
                                }
                                
                                isLoggingIn = false
                            }
                        }) {
                            HStack(spacing: 10) {
                                if isLoggingIn {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Image(systemName: "g.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                }
                                Text(isLoggingIn ? "Logging in..." : "Continue with Google")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(30)
                        }
                        .disabled(isLoggingIn)
                        .padding(.horizontal, 24)
                        
                        if let errorMessage = loginErrorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    WelcomeView(
        authManager: AuthManager(),
        showOnboarding: .constant(false),
        showMainApp: .constant(false),
        onboardingManager: OnboardingManager()
    )
}
