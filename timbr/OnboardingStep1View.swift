//
//  OnboardingStep1View.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct OnboardingStep1View: View {
    @ObservedObject var manager: OnboardingManager
    
    var body: some View {
        VStack(spacing: 32) {
            // Progress indicator
            ProgressView(value: Double(manager.currentStep), total: Double(manager.totalSteps))
                .progressViewStyle(LinearProgressViewStyle(tint: .timbrAccent))
                .padding(.horizontal, 24)
                .padding(.top, 20)
            
            Spacer()
            
            VStack(spacing: 24) {
                Text("Why are you here?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Help us personalize your experience")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 16) {
                ForEach(UserIntent.allCases, id: \.self) { intent in
                    Button(action: {
                        manager.preferences.intent = intent
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            manager.nextStep()
                        }
                    }) {
                        HStack {
                            Text(intent.displayName)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(manager.preferences.intent == intent ? Color.timbrAccent : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Skip button for browsing
            Button(action: {
                manager.preferences.intent = .browsing
                manager.nextStep()
            }) {
                Text("Skip for now")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.timbrDark.ignoresSafeArea())
    }
}

