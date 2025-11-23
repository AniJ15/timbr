//
//  PropertyInteractionManager.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import Foundation
import Combine

class PropertyInteractionManager: ObservableObject {
    static let shared = PropertyInteractionManager()
    
    @Published var likedPropertyIds: [String] = []
    @Published var dislikedPropertyIds: [String] = []
    
    @Published var allProperties: [Property] = []
    
    private init() {}
    
    func loadProperties() async {
        let propertyService = PropertyService()
        await propertyService.loadProperties()
        await MainActor.run {
            self.allProperties = propertyService.properties
        }
    }
    
    func setProperties(_ properties: [Property]) {
        self.allProperties = properties
    }
    
    func likeProperty(_ propertyId: String) {
        if !likedPropertyIds.contains(propertyId) {
            likedPropertyIds.append(propertyId)
            // Remove from disliked if it was there
            dislikedPropertyIds.removeAll { $0 == propertyId }
            print("❤️ Liked property: \(propertyId)")
            // TODO: Save to Firestore
        }
    }
    
    func likeProperty(_ property: Property) {
        // Ensure property is in allProperties
        if !allProperties.contains(where: { $0.id == property.id }) {
            allProperties.append(property)
            print("➕ Added property to allProperties: \(property.id) with \(property.imageUrls.count) images")
        }
        likeProperty(property.id)
    }
    
    func dislikeProperty(_ propertyId: String) {
        if !dislikedPropertyIds.contains(propertyId) {
            dislikedPropertyIds.append(propertyId)
            // Remove from liked if it was there
            likedPropertyIds.removeAll { $0 == propertyId }
            print("👎 Disliked property: \(propertyId)")
            // TODO: Save to Firestore
        }
    }
    
    func dislikeProperty(_ property: Property) {
        // Ensure property is in allProperties
        if !allProperties.contains(where: { $0.id == property.id }) {
            allProperties.append(property)
            print("➕ Added property to allProperties: \(property.id) with \(property.imageUrls.count) images")
        }
        dislikeProperty(property.id)
    }
    
    var likedProperties: [Property] {
        let filtered = allProperties.filter { likedPropertyIds.contains($0.id) }
        print("🔍 Liked properties: \(filtered.count) found from \(allProperties.count) total")
        for prop in filtered {
            print("  - \(prop.id): \(prop.imageUrls.count) images, first: \(prop.imageUrls.first ?? "none")")
        }
        return filtered
    }
    
    var dislikedProperties: [Property] {
        let filtered = allProperties.filter { dislikedPropertyIds.contains($0.id) }
        print("🔍 Disliked properties: \(filtered.count) found from \(allProperties.count) total")
        for prop in filtered {
            print("  - \(prop.id): \(prop.imageUrls.count) images, first: \(prop.imageUrls.first ?? "none")")
        }
        return filtered
    }
}

