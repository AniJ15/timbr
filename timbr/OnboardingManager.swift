//
//  OnboardingManager.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class OnboardingManager: ObservableObject {
    @Published var currentStep: Int = 1
    @Published var preferences = UserPreferences()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    
    private let db = Firestore.firestore()
    
    var totalSteps: Int {
        return 4 // Intent, Property Types, Price Range, Location
    }
    
    func nextStep() {
        if currentStep < totalSteps {
            currentStep += 1
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    func savePreferences() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        preferences.updatedAt = Date()
        preferences.hasCompletedOnboarding = true
        
        do {
            let preferencesData = try preferences.toDictionary()
            try await db.collection("users").document(userId).setData(preferencesData, merge: true)
            print("✅ Preferences saved successfully")
            isLoading = false
            // Show success screen after saving
            showSuccess = true
        } catch {
            errorMessage = "Failed to save preferences: \(error.localizedDescription)"
            print("❌ Error saving preferences: \(error.localizedDescription)")
            isLoading = false
            // Still show success even if Firestore fails (for demo purposes)
            showSuccess = true
        }
    }
    
    func loadPreferences() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No user ID - defaulting to onboarding")
            preferences.hasCompletedOnboarding = false
            return
        }
        
        isLoading = true
        
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            if document.exists, let data = document.data() {
                preferences = try UserPreferences.fromDictionary(data)
                print("✅ Preferences loaded successfully - hasCompletedOnboarding: \(preferences.hasCompletedOnboarding)")
            } else {
                print("⚠️ No preferences found - defaulting to onboarding")
                preferences.hasCompletedOnboarding = false
            }
            isLoading = false
        } catch {
            errorMessage = "Failed to load preferences: \(error.localizedDescription)"
            print("❌ Error loading preferences: \(error.localizedDescription)")
            print("⚠️ Defaulting to onboarding (hasCompletedOnboarding = false)")
            // If Firestore fails, default to showing onboarding
            preferences.hasCompletedOnboarding = false
            isLoading = false
        }
    }
}

// MARK: - Codable Extensions
extension UserPreferences {
    func toDictionary() throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return dictionary
    }
    
    static func fromDictionary(_ dictionary: [String: Any]) throws -> UserPreferences {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(UserPreferences.self, from: data)
    }
}

