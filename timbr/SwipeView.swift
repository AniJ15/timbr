//
//  SwipeView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct SwipeView: View {
    @StateObject private var propertyService = PropertyService()
    @ObservedObject var onboardingManager: OnboardingManager
    
    @State private var currentIndex = 0
    @State private var likedProperties: [String] = []
    @State private var dislikedProperties: [String] = []
    @State private var isTopCardFlipped = false
    @State private var isTopCardSwiping = false
    
    var body: some View {
        ZStack {
            Color.timbrDark.ignoresSafeArea()
            
            if propertyService.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if availableProperties.isEmpty {
                // No more properties
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.timbrAccent)
                    
                    Text("You've seen all properties!")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Check back later for new listings")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
                // Main swipe deck
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Timbr")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Card deck
                    ZStack {
                        // Show next 2 cards stacked behind
                        ForEach(Array(visibleProperties.prefix(3).enumerated().reversed()), id: \.element.id) { index, property in
                            if index < 3 {
                                SwipeCardView(
                                    property: property,
                                    onSwipe: { direction in
                                        handleSwipe(direction)
                                    },
                                    onTap: {
                                        // Flip animation is handled inside SwipeCardView
                                    },
                                    isFlipped: index == 0 ? $isTopCardFlipped : .constant(false),
                                    isSwiping: index == 0 ? $isTopCardSwiping : .constant(false)
                                )
                                .frame(width: 340, height: 600)
                                .scaleEffect(1.0 - CGFloat(index) * 0.05)
                                .offset(y: CGFloat(index) * 10)
                                .zIndex(Double(3 - index))
                                .opacity(index == 0 ? 1.0 : ((isTopCardFlipped || isTopCardSwiping) ? 0.0 : 0.6))
                            }
                        }
                    }
                    .padding(.vertical, 40)
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 40) {
                        // Dislike button
                        Button(action: {
                            if let property = currentProperty {
                                handleSwipe(.left)
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.red.opacity(0.2))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.red, lineWidth: 2)
                                )
                        }
                        
                        // Like button
                        Button(action: {
                            if let property = currentProperty {
                                handleSwipe(.right)
                            }
                        }) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.timbrAccent.opacity(0.2))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.timbrAccent, lineWidth: 2)
                                )
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .task {
            await loadProperties()
            print("🔍 SwipeView loaded. Properties count: \(propertyService.properties.count)")
            print("🔍 Filtered properties: \(availableProperties.count)")
        }
    }
    
    private var availableProperties: [Property] {
        // First, get all properties from service
        let allLoadedProperties = propertyService.properties
        
        // If filtering returns empty, show all properties (for testing)
        let filteredByPreferences = propertyService.getPropertiesForUser(onboardingManager.preferences)
        
        // Use filtered if available, otherwise use all
        let propertiesToShow = filteredByPreferences.isEmpty ? allLoadedProperties : filteredByPreferences
        
        // Remove already swiped properties
        let filtered = propertiesToShow.filter { property in
            !likedProperties.contains(property.id) &&
            !dislikedProperties.contains(property.id)
        }
        
        print("📊 Total loaded: \(allLoadedProperties.count)")
        print("📊 After preference filter: \(filteredByPreferences.count)")
        print("📊 After removing swiped: \(filtered.count)")
        print("📊 User preferences - Property types: \(onboardingManager.preferences.propertyTypes.count)")
        print("📊 User preferences - Price range: \(onboardingManager.preferences.minPrice ?? 0) - \(onboardingManager.preferences.maxPrice?.description ?? "none")")
        
        return filtered
    }
    
    private var visibleProperties: [Property] {
        let start = min(currentIndex, availableProperties.count)
        let end = min(start + 3, availableProperties.count)
        return Array(availableProperties[start..<end])
    }
    
    private var currentProperty: Property? {
        guard currentIndex < availableProperties.count else { return nil }
        return availableProperties[currentIndex]
    }
    
    private func loadProperties() async {
        await propertyService.loadProperties()
    }
    
    private func handleSwipe(_ direction: SwipeDirection) {
        guard let property = currentProperty else { return }
        
        withAnimation {
            if direction == .right {
                likedProperties.append(property.id)
                // TODO: Save to Firestore
                print("✅ Liked: \(property.address)")
            } else {
                dislikedProperties.append(property.id)
                // TODO: Save to Firestore
                print("👎 Disliked: \(property.address)")
            }
            
            currentIndex += 1
            isTopCardSwiping = false
        }
    }
}


