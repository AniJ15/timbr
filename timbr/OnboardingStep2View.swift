//
//  OnboardingStep2View.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct OnboardingStep2View: View {
    @ObservedObject var manager: OnboardingManager
    
    var body: some View {
        VStack(spacing: 32) {
            // Progress indicator
            ProgressView(value: Double(manager.currentStep), total: Double(manager.totalSteps))
                .progressViewStyle(LinearProgressViewStyle(tint: .timbrAccent))
                .padding(.horizontal, 24)
                .padding(.top, 20)
            
            // Back button
            HStack {
                Button(action: {
                    manager.previousStep()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            VStack(spacing: 24) {
                Text("What are you looking for?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Select all that apply")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            // Property type chips
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(PropertyType.allCases, id: \.self) { type in
                        PropertyTypeChip(
                            type: type,
                            isSelected: manager.preferences.propertyTypes.contains(type)
                        ) {
                            if manager.preferences.propertyTypes.contains(type) {
                                manager.preferences.propertyTypes.removeAll { $0 == type }
                            } else {
                                manager.preferences.propertyTypes.append(type)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Continue button
            Button(action: {
                if !manager.preferences.propertyTypes.isEmpty {
                    manager.nextStep()
                }
            }) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(manager.preferences.propertyTypes.isEmpty ? Color.white.opacity(0.3) : Color.white)
                    )
            }
            .disabled(manager.preferences.propertyTypes.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.timbrDark.ignoresSafeArea())
    }
}

struct PropertyTypeChip: View {
    let type: PropertyType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: iconForType(type))
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(isSelected ? .timbrAccent : .white.opacity(0.6))
                
                Text(type.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.timbrAccent : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
    
    private func iconForType(_ type: PropertyType) -> String {
        switch type {
        case .house:
            return "house.fill"
        case .apartment:
            return "building.2.fill"
        case .condo:
            return "building.fill"
        case .warehouse:
            return "archivebox.fill"
        case .land:
            return "mountain.2.fill"
        case .townhouse:
            return "building.2.crop.circle.fill"
        case .commercial:
            return "briefcase.fill"
        }
    }
}

