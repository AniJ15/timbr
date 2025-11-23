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
    
    @State private var dragOffset: CGSize = .zero
    @State private var rotationAngle: Double = 0
    @GestureState private var isDragging = false
    
    private let swipeThreshold: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Card
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
                    .frame(height: geometry.size.height * 0.75)
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
                    .frame(height: geometry.size.height * 0.25)
                    .background(Color.timbrDark)
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                
                // Swipe indicators
                if abs(dragOffset.width) > 20 {
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
            DragGesture()
                .updating($isDragging) { _, state, _ in
                    state = true
                }
                .onChanged { value in
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
                            onSwipe(direction)
                        }
                    } else {
                        // Snap back
                        withAnimation(.spring()) {
                            dragOffset = .zero
                            rotationAngle = 0
                        }
                    }
                }
        )
        .onTapGesture {
            onTap()
        }
    }
}

