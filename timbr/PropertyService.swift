//
//  PropertyService.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import Foundation
import Combine
import FirebaseFirestore
import CoreLocation

@MainActor
class PropertyService: ObservableObject {
    @Published var properties: [Property] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        // Load properties on init
        Task {
            await loadProperties()
        }
    }
    
    deinit {
        listener?.remove()
    }
    
    func loadProperties() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let snapshot = try await db.collection("properties")
                .order(by: "createdAt", descending: true)
                .limit(to: 100)
                .getDocuments()
            
            properties = try snapshot.documents.compactMap { doc in
                var data = doc.data()
                data["id"] = doc.documentID
                return try Property.fromDictionary(data)
            }
            
            print("✅ Loaded \(properties.count) properties")
            isLoading = false
        } catch {
            errorMessage = "Failed to load properties: \(error.localizedDescription)"
            print("❌ Error loading properties: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    func loadPropertiesNearLocation(_ location: CLLocation, radiusInMiles: Double = 50) async {
        isLoading = true
        errorMessage = nil
        
        // For now, load all and filter by distance
        // In production, use GeoFirestore or similar for efficient geo-queries
        await loadProperties()
        
        let filtered = properties.filter { property in
            let distance = location.distance(from: property.location) / 1609.34 // Convert to miles
            return distance <= radiusInMiles
        }
        
        properties = filtered
        isLoading = false
    }
    
    func filterProperties(by preferences: UserPreferences) -> [Property] {
        print("🔍 Filtering \(properties.count) properties with preferences:")
        print("   - Property types: \(preferences.propertyTypes.map { $0.rawValue })")
        print("   - Price range: \(preferences.minPrice?.description ?? "none") - \(preferences.maxPrice?.description ?? "none")")
        
        // If no preferences set, return all properties
        if preferences.propertyTypes.isEmpty && 
           preferences.minPrice == nil && 
           preferences.maxPrice == nil {
            print("📋 No filters applied - showing all \(properties.count) properties")
            return properties
        }
        
        let filtered = properties.filter { property in
            // Filter by property type
            if !preferences.propertyTypes.isEmpty {
                let propertyTypeMap: [PropertyType: String] = [
                    .house: "house",
                    .apartment: "apartment",
                    .condo: "condo",
                    .townhouse: "townhouse",
                    .commercial: "commercial",
                    .warehouse: "warehouse",
                    .land: "land",
                    .browsing: "" // browsing shouldn't filter
                ]
                
                let matchingTypes = preferences.propertyTypes
                    .filter { $0 != .browsing }
                    .compactMap { propertyTypeMap[$0] }
                
                // If only "browsing" is selected, show all
                if !matchingTypes.isEmpty {
                    let propertyTypeLower = property.propertyType.lowercased()
                    if !matchingTypes.contains(propertyTypeLower) {
                        print("   ❌ Filtered out \(property.address) - type '\(property.propertyType)' not in \(matchingTypes)")
                        return false
                    }
                }
            }
            
            // Filter by price range
            if let minPrice = preferences.minPrice, property.price < minPrice {
                print("   ❌ Filtered out \(property.address) - price \(property.price) < min \(minPrice)")
                return false
            }
            if let maxPrice = preferences.maxPrice, property.price > maxPrice {
                print("   ❌ Filtered out \(property.address) - price \(property.price) > max \(maxPrice)")
                return false
            }
            
            // Location filter - disabled for mock data
            // (Mock properties are in NY, users might be anywhere)
            
            return true
        }
        
        print("✅ Filtered to \(filtered.count) properties")
        
        // If filtering resulted in empty, return all properties (for testing)
        if filtered.isEmpty && !properties.isEmpty {
            print("⚠️ Filter returned empty - showing all properties for testing")
            return properties
        }
        
        return filtered
    }
    
    func getPropertiesForUser(_ preferences: UserPreferences) -> [Property] {
        return filterProperties(by: preferences)
    }
}

