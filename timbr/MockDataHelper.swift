//
//  MockDataHelper.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class MockDataHelper: ObservableObject {
    @Published var isGenerating = false
    @Published var generationStatus: String?
    
    static let shared = MockDataHelper()
    
    private init() {}
    
    func generateMockProperties(count: Int = 50) async {
        isGenerating = true
        generationStatus = "Generating \(count) mock properties..."
        
        let generator = MockDataGenerator()
        
        do {
            try await generator.generateSampleProperties(count: count)
            generationStatus = "✅ Successfully generated \(count) properties!"
            print("✅ Mock data generation complete")
        } catch {
            generationStatus = "❌ Error: \(error.localizedDescription)"
            print("❌ Error generating mock data: \(error.localizedDescription)")
        }
        
        isGenerating = false
        
        // Clear status after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.generationStatus = nil
        }
    }
    
    // Check if properties already exist
    func checkIfPropertiesExist() async -> Bool {
        let db = Firestore.firestore()
        
        do {
            let snapshot = try await db.collection("properties")
                .limit(to: 1)
                .getDocuments()
            
            return !snapshot.documents.isEmpty
        } catch {
            print("Error checking properties: \(error.localizedDescription)")
            return false
        }
    }
}

