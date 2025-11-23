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
    @State private var noBudget: Bool = false
    
    private let minRange: Double = 0
    private let maxRange: Double = 5000000
    
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
                
                Text("Set your price range")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            // Price sliders
            VStack(spacing: 32) {
                // No set budget option
                Button(action: {
                    noBudget.toggle()
                    if noBudget {
                        // Move sliders to full range
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            minPrice = minRange
                            maxPrice = maxRange
                        }
                        manager.preferences.minPrice = nil
                        manager.preferences.maxPrice = nil
                    } else {
                        // Use current slider values
                        manager.preferences.minPrice = Int(minPrice)
                        manager.preferences.maxPrice = Int(maxPrice)
                    }
                }) {
                    HStack {
                        Text("No set budget")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        if noBudget {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.timbrAccent)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(noBudget ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(noBudget ? Color.timbrAccent : Color.clear, lineWidth: 2)
                            )
                    )
                }
                .padding(.horizontal, 24)
                
                // Always show sliders
                VStack(spacing: 32) {
                    // Minimum price slider
                    VStack(spacing: 16) {
                        HStack {
                            Text("Minimum")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text(formatPrice(minPrice))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 24)
                        
                        Slider(value: $minPrice, in: minRange...maxRange, step: 10000)
                            .tint(.timbrAccent)
                            .labelsHidden()
                            .disabled(noBudget)
                            .opacity(noBudget ? 0.5 : 1.0)
                            .padding(.horizontal, 24)
                            .onChange(of: minPrice) { newValue in
                                // Ensure min doesn't exceed max
                                if newValue > maxPrice {
                                    minPrice = maxPrice
                                }
                                // Only save if "No set budget" is not checked
                                if !noBudget {
                                    manager.preferences.minPrice = Int(minPrice)
                                }
                            }
                    }
                    
                    // Maximum price slider
                    VStack(spacing: 16) {
                        HStack {
                            Text("Maximum")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text(formatPrice(maxPrice))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 24)
                        
                        Slider(value: $maxPrice, in: minRange...maxRange, step: 10000)
                            .tint(.timbrAccent)
                            .labelsHidden()
                            .disabled(noBudget)
                            .opacity(noBudget ? 0.5 : 1.0)
                            .padding(.horizontal, 24)
                            .onChange(of: maxPrice) { newValue in
                                // Ensure max doesn't go below min
                                if newValue < minPrice {
                                    maxPrice = minPrice
                                }
                                // Only save if "No set budget" is not checked
                                if !noBudget {
                                    manager.preferences.maxPrice = Int(maxPrice)
                                }
                            }
                    }
                }
                .padding(.vertical, 20)
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
                noBudget = false
            } else {
                noBudget = true
            }
            if let max = manager.preferences.maxPrice {
                maxPrice = Double(max)
            }
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.currencySymbol = "$"
        
        let number = NSNumber(value: price)
        if let formatted = formatter.string(from: number) {
            return formatted
        }
        
        // Fallback formatting
        if price >= 1_000_000 {
            return "$\(Int(price / 1_000_000))M"
        } else if price >= 1_000 {
            return "$\(Int(price / 1_000))K"
        } else {
            return "$\(Int(price))"
        }
    }
}

