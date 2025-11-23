//
//  SavedView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct SavedView: View {
    @ObservedObject private var interactionManager = PropertyInteractionManager.shared
    @State private var selectedTab = 0 // 0 = Liked, 1 = Disliked
    
    var body: some View {
        ZStack {
            Color.timbrDark
                .ignoresSafeArea(.container, edges: .top)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Saved")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // Tab selector
                HStack(spacing: 0) {
                    // Liked tab
                    Button(action: {
                        withAnimation {
                            selectedTab = 0
                        }
                    }) {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 16))
                                Text("Liked")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(selectedTab == 0 ? .timbrAccent : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            
                            if selectedTab == 0 {
                                Rectangle()
                                    .fill(Color.timbrAccent)
                                    .frame(height: 2)
                            } else {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 2)
                            }
                        }
                    }
                    
                    // Disliked tab
                    Button(action: {
                        withAnimation {
                            selectedTab = 1
                        }
                    }) {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                Text("Disliked")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(selectedTab == 1 ? .timbrAccent : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            
                            if selectedTab == 1 {
                                Rectangle()
                                    .fill(Color.timbrAccent)
                                    .frame(height: 2)
                            } else {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 2)
                            }
                        }
                    }
                }
                .background(Color.white.opacity(0.05))
                .padding(.horizontal, 20)
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if selectedTab == 0 {
                            // Liked properties
                            if interactionManager.likedProperties.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "heart")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.3))
                                    Text("No liked properties yet")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("Start swiping to save properties you love")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.4))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 100)
                            } else {
                                ForEach(interactionManager.likedProperties) { property in
                                    SavedPropertyCard(property: property, isLiked: true)
                                        .onAppear {
                                            print("📸 Liked property card appeared: \(property.id), images: \(property.imageUrls.count), first: \(property.imageUrls.first ?? "none")")
                                        }
                                }
                            }
                        } else {
                            // Disliked properties
                            if interactionManager.dislikedProperties.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.3))
                                    Text("No disliked properties")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("Properties you pass on will appear here")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.4))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 100)
                            } else {
                                ForEach(interactionManager.dislikedProperties) { property in
                                    SavedPropertyCard(property: property, isLiked: false)
                                        .onAppear {
                                            print("📸 Disliked property card appeared: \(property.id), images: \(property.imageUrls.count), first: \(property.imageUrls.first ?? "none")")
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .task {
            await interactionManager.loadProperties()
        }
    }
}

// MARK: - Saved Property Card
struct SavedPropertyCard: View {
    let property: Property
    let isLiked: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Property Image
            Group {
                if let firstImageUrl = property.imageUrls.first, !firstImageUrl.isEmpty, let url = URL(string: firstImageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(ProgressView().tint(.white))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white.opacity(0.5))
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
            }
            .frame(width: 100, height: 100)
            .cornerRadius(12)
            .clipped()
            
            // Property Info
            VStack(alignment: .leading, spacing: 6) {
                Text(property.formattedPrice)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(property.city), \(property.state)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "bed.double.fill")
                            .font(.system(size: 12))
                        Text("\(property.bedrooms)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bathtub.fill")
                            .font(.system(size: 12))
                        Text("\(property.bathrooms)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    
                    if let sqft = property.squareFeet {
                        HStack(spacing: 4) {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 12))
                            Text("\(sqft) sqft")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            Image(systemName: isLiked ? "heart.fill" : "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(isLiked ? .timbrAccent : .red.opacity(0.7))
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isLiked ? Color.timbrAccent.opacity(0.3) : Color.red.opacity(0.2), lineWidth: 1)
        )
    }
}
