//
//  OnboardingStep3View.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct OnboardingStep3View: View {
    @ObservedObject var manager: OnboardingManager
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 2000000
    
    private let priceRanges: [(min: Int, max: Int, label: String)] = [
        (0, 250000, "Under $250K"),
        (250000, 500000, "$250K - $500K"),
        (500000, 750000, "$500K - $750K"),
        (750000, 1000000, "$750K - $1M"),
        (1000000, 2000000, "$1M - $2M"),
        (2000000, 5000000, "$2M - $5M"),
        (5000000, Int.max, "$5M+")
    ]
    
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
                Text("What's your budget?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Select your price range")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            // Price range options
            ScrollView {
                VStack(spacing: 16) {
                    // No set budget option
                    let noBudgetSelected = manager.preferences.minPrice == nil && manager.preferences.maxPrice == nil
                    Button(action: {
                        manager.preferences.minPrice = nil
                        manager.preferences.maxPrice = nil
                    }) {
                        HStack {
                            Text("No set budget")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            if noBudgetSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.timbrAccent)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(noBudgetSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(noBudgetSelected ? Color.timbrAccent : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                    
                    ForEach(priceRanges.indices, id: \.self) { index in
                        let range = priceRanges[index]
                        let isSelected = manager.preferences.minPrice == range.min && 
                                        manager.preferences.maxPrice == (range.max == Int.max ? nil : range.max)
                        
                        Button(action: {
                            manager.preferences.minPrice = range.min
                            manager.preferences.maxPrice = range.max == Int.max ? nil : range.max
                        }) {
                            HStack {
                                Text(range.label)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.timbrAccent)
                                }
                            }
                            .padding(20)
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
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Continue button
            Button(action: {
                manager.nextStep()
            }) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.timbrDark.ignoresSafeArea())
        .onAppear {
            // Initialize with existing values if available
            if let min = manager.preferences.minPrice {
                minPrice = Double(min)
            }
            if let max = manager.preferences.maxPrice {
                maxPrice = Double(max)
            }
        }
    }
}

