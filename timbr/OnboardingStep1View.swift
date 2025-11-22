//
//  OnboardingStep1View.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct OnboardingStep1View: View {
    @ObservedObject var manager: OnboardingManager
    @State private var selectedIntents: Set<UserIntent> = []
    
    var body: some View {
        ZStack {
            // Background gradient using Timbr dark green
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.timbrDark.opacity(1.0),
                    Color.timbrDark.opacity(0.9)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Progress indicator
                ProgressView(value: Double(manager.currentStep), total: Double(manager.totalSteps))
                    .progressViewStyle(LinearProgressViewStyle(tint: .timbrAccent))
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                
                Spacer().frame(height: 32)
                
                // Title + subtitle
                VStack(spacing: 8) {
                    Text("What brings you to\nTimbr?")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("We'll personalize your experience\nbased on your goals.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                
                // Intent options
                VStack(spacing: 12) {
                    ForEach(UserIntent.allCases, id: \.self) { intent in
                        IntentOptionRow(
                            intent: intent,
                            isSelected: selectedIntents.contains(intent)
                        ) {
                            toggleSelection(intent)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Small text under options
                Text("You can update this later in your Timbr settings")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                
                Spacer()
                
                // Continue button
                Button(action: {
                    manager.preferences.intents = Array(selectedIntents)
                    manager.nextStep()
                }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedIntents.isEmpty ? Color.white.opacity(0.15) : Color.timbrAccent)
                        .foregroundColor(.black.opacity(selectedIntents.isEmpty ? 0.4 : 1.0))
                        .cornerRadius(30)
                }
                .disabled(selectedIntents.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            // Initialize selectedIntents from saved preferences
            selectedIntents = Set(manager.preferences.intents)
        }
    }
    
    private func toggleSelection(_ intent: UserIntent) {
        if selectedIntents.contains(intent) {
            selectedIntents.remove(intent)
        } else {
            selectedIntents.insert(intent)
        }
    }
}

// MARK: - Option row
struct IntentOptionRow: View {
    let intent: UserIntent
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 34, height: 34)
                    Image(systemName: intent.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(intent.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        isSelected
                        ? Color.white.opacity(0.12)
                        : Color.white.opacity(0.04)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isSelected
                        ? Color.timbrAccent.opacity(0.9)
                        : Color.white.opacity(0.06),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
