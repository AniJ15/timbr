//
//  SwipeCardView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct SwipeCardView: View {
    let property: Property
    let onSwipe: (SwipeDirection) -> Void
    let onTap: () -> Void
    @Binding var isFlipped: Bool
    @Binding var isSwiping: Bool
    
    @State private var dragOffset: CGSize = .zero
    @State private var rotationAngle: Double = 0
    @GestureState private var isDragging = false
    
    private let swipeThreshold: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Solid background to block cards behind during flip
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.timbrDark)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Card Front (Image + Price)
                cardFront(geometry: geometry)
                    .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                    .opacity(isFlipped ? 0 : 1)
                
                // Card Back (Details)
                cardBack(geometry: geometry)
                    .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                    .opacity(isFlipped ? 1 : 0)
                
                // Swipe indicators (only show when not flipped)
                if !isFlipped && abs(dragOffset.width) > 20 {
                    VStack {
                        Spacer()
                        
                        if dragOffset.width > 0 {
                            // Like indicator
                            Text("❤️")
                                .font(.system(size: 60))
                                .opacity(min(abs(dragOffset.width) / swipeThreshold, 1.0))
                                .padding(.trailing, 40)
                        } else {
                            // Dislike indicator
                            Text("👎")
                                .font(.system(size: 60))
                                .opacity(min(abs(dragOffset.width) / swipeThreshold, 1.0))
                                .padding(.leading, 40)
                        }
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
        }
        .offset(dragOffset)
        .rotationEffect(.degrees(rotationAngle))
        .gesture(
            // Only allow swiping when not flipped
            isFlipped ? nil : DragGesture()
                .updating($isDragging) { _, state, _ in
                    state = true
                }
                .onChanged { value in
                    isSwiping = true
                    dragOffset = value.translation
                    rotationAngle = Double(value.translation.width / 10)
                }
                .onEnded { value in
                    if abs(value.translation.width) > swipeThreshold {
                        // Swipe completed
                        let direction: SwipeDirection = value.translation.width > 0 ? .right : .left
                        withAnimation(.spring()) {
                            dragOffset = CGSize(
                                width: value.translation.width > 0 ? 1000 : -1000,
                                height: value.translation.height
                            )
                            rotationAngle = value.translation.width > 0 ? 30 : -30
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isSwiping = false
                            onSwipe(direction)
                        }
                    } else {
                        // Snap back
                        withAnimation(.spring()) {
                            dragOffset = .zero
                            rotationAngle = 0
                        }
                        isSwiping = false
                    }
                }
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
        .onChange(of: isFlipped) { _ in
            // Reset drag offset when flipping to prevent visual glitches
            if isFlipped {
                dragOffset = .zero
                rotationAngle = 0
            }
        }
    }
    
    // MARK: - Card Front
    private func cardFront(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Property Image - always fills the space, crops as needed
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
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.75)
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
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height * 0.75)
            .clipped()
            
            // Bottom info section
            VStack(alignment: .leading, spacing: 8) {
                Text(property.formattedPrice)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(property.city), \(property.state)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .frame(width: geometry.size.width, height: geometry.size.height * 0.25)
            .background(Color.timbrDark)
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .background(Color.timbrDark)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    // MARK: - Card Back
    private func cardBack(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Property Image
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
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
                                .overlay(ProgressView().tint(.white))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
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
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.6))
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
                    .clipped()
                    
                    // Price and Address
                    VStack(alignment: .leading, spacing: 8) {
                        Text(property.formattedPrice)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(property.fullAddress)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Key Details
                    HStack(spacing: 16) {
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
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(property.description)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Features
                    if !property.features.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Features")
                                .font(.system(size: 18, weight: .semibold))
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
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
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
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.timbrAccent.opacity(0.2))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.timbrAccent, lineWidth: 2)
                                )
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .background(Color.timbrDark)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

// MARK: - Detail Item Component
struct DetailItem: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.timbrAccent)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

