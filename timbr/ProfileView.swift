//
//  ProfileView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var authManager = AuthManager()
    @ObservedObject var onboardingManager: OnboardingManager
    @ObservedObject private var interactionManager = PropertyInteractionManager.shared
    @State private var showEditPreferences = false
    @State private var showSettings = false
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        ZStack {
            Color.timbrDark.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Profile")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 10)
                    
                    // User Info Card
                    VStack(spacing: 16) {
                        // Profile Picture/Initials
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.timbrAccent.opacity(0.3),
                                            Color.timbrAccent.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            if let email = authManager.user?.email {
                                Text(String(email.prefix(1)).uppercased())
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.timbrAccent)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.timbrAccent)
                            }
                        }
                        
                        // Name and Email
                        VStack(spacing: 4) {
                            if let displayName = authManager.user?.displayName {
                                Text(displayName)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            if let email = authManager.user?.email {
                                Text(email)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Stats Section
                    HStack(spacing: 16) {
                        StatCard(
                            icon: "heart.fill",
                            value: "\(interactionManager.likedProperties.count)",
                            label: "Liked"
                        )
                        
                        StatCard(
                            icon: "xmark.circle.fill",
                            value: "\(interactionManager.dislikedProperties.count)",
                            label: "Disliked"
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Settings Section
                    VStack(spacing: 12) {
                        SettingsRow(
                            icon: "gear",
                            title: "Settings",
                            action: {
                                showSettings = true
                            }
                        )
                        
                        SettingsRow(
                            icon: "questionmark.circle",
                            title: "Help & Support",
                            action: {
                                // TODO: Show help
                            }
                        )
                        
                        SettingsRow(
                            icon: "info.circle",
                            title: "About",
                            action: {
                                // TODO: Show about
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Sign Out Button
                    Button(action: {
                        showSignOutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 16, weight: .medium))
                            Text("Sign Out")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            Task {
                await onboardingManager.loadPreferences()
                await interactionManager.loadProperties()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                onboardingManager: onboardingManager,
                showEditPreferences: $showEditPreferences
            )
        }
        .sheet(isPresented: $showEditPreferences) {
            EditPreferencesView(onboardingManager: onboardingManager)
        }
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
                // Navigate back to welcome screen
                // This will be handled by ContentView
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.timbrAccent)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Preference Section
struct PreferenceSection: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 20)
            
            VStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Text(item)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @Binding var showEditPreferences: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.timbrDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Preferences Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Preferences")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: {
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        showEditPreferences = true
                                    }
                                }) {
                                    Text("Edit")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.timbrAccent)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Intent
                            if !onboardingManager.preferences.intents.isEmpty {
                                PreferenceSection(
                                    title: "What brings you to Timbr?",
                                    items: onboardingManager.preferences.intents.map { $0.title }
                                )
                            }
                            
                            // Property Types
                            if !onboardingManager.preferences.propertyTypes.isEmpty {
                                PreferenceSection(
                                    title: "Property Types",
                                    items: onboardingManager.preferences.propertyTypes.map { $0.displayName }
                                )
                            }
                            
                            // Price Range
                            if let minPrice = onboardingManager.preferences.minPrice,
                               let maxPrice = onboardingManager.preferences.maxPrice {
                                PreferenceSection(
                                    title: "Price Range",
                                    items: [formatPriceRange(min: minPrice, max: maxPrice)]
                                )
                            } else if onboardingManager.preferences.minPrice == nil && onboardingManager.preferences.maxPrice == nil {
                                PreferenceSection(
                                    title: "Price Range",
                                    items: ["No set budget"]
                                )
                            }
                            
                            // Location
                            if let location = onboardingManager.preferences.location {
                                PreferenceSection(
                                    title: "Location",
                                    items: [location]
                                )
                            }
                        }
                        .padding(.top, 20)
                        
                        // Other Settings
                        VStack(spacing: 12) {
                            SettingsRow(
                                icon: "questionmark.circle",
                                title: "Help & Support",
                                action: {
                                    // TODO: Show help
                                }
                            )
                            
                            SettingsRow(
                                icon: "info.circle",
                                title: "About",
                                action: {
                                    // TODO: Show about
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.timbrAccent)
                }
            }
            .onAppear {
                Task {
                    await onboardingManager.loadPreferences()
                }
            }
        }
    }
    
    private func formatPriceRange(min: Int, max: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        
        let minFormatted = formatter.string(from: NSNumber(value: min)) ?? "$\(min)"
        let maxFormatted = formatter.string(from: NSNumber(value: max)) ?? "$\(max)"
        
        return "\(minFormatted) - \(maxFormatted)"
    }
}

// MARK: - Edit Preferences View
struct EditPreferencesView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedIntents: Set<UserIntent> = []
    @State private var selectedPropertyTypes: Set<PropertyType> = []
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 5000000
    @State private var noBudget: Bool = false
    @State private var location: String = ""
    @State private var isSaving = false
    
    private let minRange: Double = 0
    private let maxRange: Double = 5000000
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.timbrDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Intents
                        VStack(alignment: .leading, spacing: 16) {
                            Text("What brings you to Timbr?")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                ForEach(UserIntent.allCases, id: \.self) { intent in
                                    IntentOptionRow(
                                        intent: intent,
                                        isSelected: selectedIntents.contains(intent)
                                    ) {
                                        if selectedIntents.contains(intent) {
                                            selectedIntents.remove(intent)
                                        } else {
                                            selectedIntents.insert(intent)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Property Types
                        VStack(alignment: .leading, spacing: 16) {
                            Text("What are you looking for?")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(PropertyType.allCases, id: \.self) { type in
                                    PropertyTypeButton(
                                        type: type,
                                        isSelected: selectedPropertyTypes.contains(type)
                                    ) {
                                        if selectedPropertyTypes.contains(type) {
                                            selectedPropertyTypes.remove(type)
                                        } else {
                                            selectedPropertyTypes.insert(type)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Price Range
                        VStack(alignment: .leading, spacing: 16) {
                            Text("What's your budget?")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            // No set budget option
                            Button(action: {
                                noBudget.toggle()
                                if noBudget {
                                    withAnimation {
                                        minPrice = minRange
                                        maxPrice = maxRange
                                    }
                                }
                            }) {
                                HStack {
                                    Text("No set budget")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    if noBudget {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.timbrAccent)
                                    }
                                }
                                .padding(16)
                                .background(Color.white.opacity(noBudget ? 0.15 : 0.05))
                                .cornerRadius(12)
                            }
                            
                            // Sliders
                            VStack(spacing: 24) {
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Minimum")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        Spacer()
                                        Text(formatPrice(minPrice))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Slider(value: $minPrice, in: minRange...maxRange, step: 10000)
                                        .tint(.timbrAccent)
                                        .labelsHidden()
                                        .disabled(noBudget)
                                        .opacity(noBudget ? 0.5 : 1.0)
                                }
                                
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Maximum")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        Spacer()
                                        Text(noBudget && maxPrice >= maxRange ? "5M+" : formatPrice(maxPrice))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Slider(value: $maxPrice, in: minRange...maxRange, step: 10000)
                                        .tint(.timbrAccent)
                                        .labelsHidden()
                                        .disabled(noBudget)
                                        .opacity(noBudget ? 0.5 : 1.0)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Location
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Location")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            TextField("Enter location", text: $location)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        // Save Button
                        Button(action: {
                            savePreferences()
                        }) {
                            Text(isSaving ? "Saving..." : "Save Preferences")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isSaving ? Color.gray : Color.timbrAccent)
                                .cornerRadius(30)
                        }
                        .disabled(isSaving)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Edit Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.timbrDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            loadCurrentPreferences()
        }
    }
    
    private func loadCurrentPreferences() {
        selectedIntents = Set(onboardingManager.preferences.intents)
        selectedPropertyTypes = Set(onboardingManager.preferences.propertyTypes)
        
        if let min = onboardingManager.preferences.minPrice {
            minPrice = Double(min)
            noBudget = false
        } else {
            minPrice = minRange
            noBudget = true
        }
        
        if let max = onboardingManager.preferences.maxPrice {
            maxPrice = Double(max)
        } else {
            maxPrice = maxRange
        }
        
        location = onboardingManager.preferences.location ?? ""
    }
    
    private func savePreferences() {
        isSaving = true
        
        onboardingManager.preferences.intents = Array(selectedIntents)
        onboardingManager.preferences.propertyTypes = Array(selectedPropertyTypes)
        
        if noBudget {
            onboardingManager.preferences.minPrice = nil
            onboardingManager.preferences.maxPrice = nil
        } else {
            onboardingManager.preferences.minPrice = Int(minPrice)
            onboardingManager.preferences.maxPrice = Int(maxPrice)
        }
        
        onboardingManager.preferences.location = location.isEmpty ? nil : location
        
        Task {
            await onboardingManager.savePreferences()
            isSaving = false
            dismiss()
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "$\(Int(price))"
    }
}


// MARK: - Property Type Button
struct PropertyTypeButton: View {
    let type: PropertyType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(type.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.timbrAccent.opacity(0.2) : Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.timbrAccent : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
