//
//  PropertyDetailView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct PropertyDetailView: View {
    let property: Property
    let onClose: () -> Void
    let onSwipe: (SwipeDirection) -> Void
    
    var body: some View {
        ZStack {
            Color.timbrDark.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Close button
                    HStack {
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Property Image - fills space, crops as needed
                    AsyncImage(url: URL(string: property.imageUrls.first ?? "")) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.gray.opacity(0.4),
                                            Color.gray.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 300)
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 300)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.gray.opacity(0.4),
                                            Color.gray.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 300)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white.opacity(0.6))
                                        Text("Image unavailable")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 300)
                        }
                    }
                    .frame(height: 300)
                    .cornerRadius(20)
                    .clipped()
                    .padding(.horizontal, 20)
                    
                    // Price and Address
                    VStack(alignment: .leading, spacing: 8) {
                        Text(property.formattedPrice)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(property.fullAddress)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Key Details
                    HStack(spacing: 20) {
                        DetailItem(icon: "bed.double.fill", value: "\(property.bedrooms)")
                        DetailItem(icon: "bathtub.fill", value: "\(property.bathrooms)")
                        if let sqft = property.squareFeet {
                            DetailItem(icon: "square.grid.2x2.fill", value: "\(sqft) sqft")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal, 20)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(property.description)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Features
                    if !property.features.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Features")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(property.features, id: \.self) { feature in
                                    HStack {
                                        Text(feature)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(20)
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    }
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        // Dislike button
                        Button(action: {
                            onSwipe(.left)
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
                            onSwipe(.right)
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
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct DetailItem: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.timbrAccent)
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}


