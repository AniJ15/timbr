//
//  ContentView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        SignInView()
    }
}

struct SignInView: View {
    private let features = [
        "Personalized swipe deck",
        "Quick intent setup",
        "Matches & archives synced"
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x011A1E), Color(hex: 0x05343C)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            Circle()
                .fill(Color(hex: 0x38D2C8, alpha: 0.25))
                .frame(width: 420, height: 420)
                .blur(radius: 180)
                .offset(x: 120, y: -250)
                .ignoresSafeArea()
            
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 140)
                .offset(x: -160, y: 220)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 28) {
                Spacer(minLength: 32)
                
                VStack(spacing: 12) {
                    Text("Welcome to")
                        .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    
                    Image("TimbrLogo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 320, height: 180)
                        .accessibilityLabel("timbr logo")
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 4)
                
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Swipe into homes, investments, and inspirations tailored to how you live and what you’re searching for.")
                                .font(.callout)
                                .foregroundStyle(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Divider()
                            .overlay(Color.white.opacity(0.15))
                        
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(features, id: \.self) { feature in
                                FeaturePill(text: feature)
                            }
                        }
                    }
                    .foregroundStyle(.white)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: signInWithGoogle) {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.title3)
                            Text("Continue with Google")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(SignInButtonStyle())
                    
                    Text("We only use your Google account to secure sign-in and sync your swipes.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 32)
        }
    }
    
    private func signInWithGoogle() {
        // Placeholder action – integrate Google Sign-In SDK here.
        print("Google Sign-In tapped")
    }
}

private struct SignInButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color(hex: 0x05343C))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.25))
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct GlassCard<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white.opacity(0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(.white.opacity(0.12))
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 30, x: 0, y: 24)
    }
}

private struct FeaturePill: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white.opacity(0.95), Color(hex: 0x38D2C8))
                .font(.subheadline)
                .padding(8)
                .background(
                    Circle()
                        .fill(.white.opacity(0.08))
                )
            
            Text(text)
                .font(.subheadline.weight(.medium))
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.1))
                )
        )
    }
}

private extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

#Preview {
    ContentView()
        .previewDevice("iPhone 15 Pro")
}
