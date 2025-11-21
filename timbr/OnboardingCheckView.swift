//
//  OnboardingCheckView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct OnboardingCheckView: View {
    @ObservedObject var authManager: AuthManager
    @ObservedObject var onboardingManager: OnboardingManager
    @Binding var showOnboarding: Bool
    
    var body: some View {
        ZStack {
            Color.timbrDark.ignoresSafeArea()
            
            if onboardingManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                if !onboardingManager.preferences.hasCompletedOnboarding {
                    OnboardingView()
                } else {
                    // User has completed onboarding - show main app
                    Text("Main App - Coming Soon")
                        .foregroundColor(.white)
                        .font(.title)
                }
            }
        }
        .task {
            await onboardingManager.loadPreferences()
            if !onboardingManager.preferences.hasCompletedOnboarding {
                showOnboarding = true
            }
        }
    }
}

