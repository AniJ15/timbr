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
    
    var body: some View {
        ZStack {
            Color.timbrDark.ignoresSafeArea()
            
            if manager.showSuccess {
                OnboardingSuccessView()
            } else {
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

