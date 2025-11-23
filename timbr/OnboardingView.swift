//
//  OnboardingView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var manager = OnboardingManager()
    @Environment(\.dismiss) var dismiss
    @State private var showSwipeView = false
    
    var body: some View {
        ZStack {
            if showSwipeView {
                MainTabView(onboardingManager: manager)
                    .transition(.opacity)
            } else if manager.showSuccess {
                OnboardingSuccessView(onShowSwipe: {
                    withAnimation {
                        showSwipeView = true
                    }
                })
            } else {
                Color.timbrDark.ignoresSafeArea()
                
                switch manager.currentStep {
                case 1:
                    OnboardingStep1View(manager: manager)
                case 2:
                    OnboardingStep2View(manager: manager)
                case 3:
                    OnboardingStep3View(manager: manager)
                case 4:
                    OnboardingStep4View(manager: manager)
                default:
                    OnboardingStep1View(manager: manager)
                }
            }
        }
    }
}

