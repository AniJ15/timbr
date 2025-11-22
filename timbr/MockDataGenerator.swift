//
//  MockDataGenerator.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import Foundation
import FirebaseFirestore
import CoreLocation

class MockDataGenerator {
    private let db = Firestore.firestore()
    
    // Sample addresses in various cities (using real coordinates)
    private let sampleLocations: [(address: String, city: String, state: String, zip: String, lat: Double, lng: Double)] = [
        ("123 Main Street", "Ithaca", "NY", "14850", 42.4439, -76.5019),
        ("456 Oak Avenue", "Ithaca", "NY", "14850", 42.4400, -76.4950),
        ("789 Elm Road", "Ithaca", "NY", "14850", 42.4470, -76.5100),
        ("321 Pine Lane", "Ithaca", "NY", "14850", 42.4350, -76.4850),
        ("654 Maple Drive", "Ithaca", "NY", "14850", 42.4500, -76.5200),
        ("987 Cedar Street", "Syracuse", "NY", "13201", 43.0481, -76.1474),
        ("147 Birch Way", "Syracuse", "NY", "13201", 43.0450, -76.1500),
        ("258 Willow Court", "Syracuse", "NY", "13201", 43.0510, -76.1400),
        ("369 Spruce Avenue", "Binghamton", "NY", "13901", 42.0987, -75.9179),
        ("741 Ash Street", "Binghamton", "NY", "13901", 42.0950, -75.9200),
        ("852 Poplar Road", "Rochester", "NY", "14604", 43.1566, -77.6088),
        ("963 Hickory Lane", "Rochester", "NY", "14604", 43.1540, -77.6100),
        ("159 Chestnut Drive", "Albany", "NY", "12203", 42.6526, -73.7562),
        ("357 Walnut Street", "Albany", "NY", "12203", 42.6500, -75.7550),
        ("468 Cherry Avenue", "Buffalo", "NY", "14202", 42.8864, -78.8784),
        ("579 Plum Road", "Buffalo", "NY", "14202", 42.8840, -78.8800),
        ("680 Peach Lane", "New York", "NY", "10001", 40.7489, -73.9680),
        ("791 Apple Street", "New York", "NY", "10001", 40.7460, -73.9700),
        ("802 Orange Drive", "New York", "NY", "10001", 40.7520, -73.9650),
        ("913 Grape Court", "New York", "NY", "10001", 40.7440, -73.9720)
    ]
    
    // Sample property images (using placeholder URLs - you can replace with real image URLs)
    private let sampleImages: [[String]] = [
        ["https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800"],
        ["https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800"],
        ["https://images.unsplash.com/photo-1568605117035-5e82a6a15539?w=800"],
        ["https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?w=800"],
        ["https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800"],
        ["https://images.unsplash.com/photo-1576941089067-2de3c901e126?w=800"],
        ["https://images.unsplash.com/photo-1571055107559-3e67626fa8be?w=800"],
        ["https://images.unsplash.com/photo-1560520653-9e0e4c89eb11?w=800"]
    ]
    
    private let propertyTypes = ["house", "apartment", "condo", "townhouse", "commercial"]
    
    private let features = [
        ["Hardwood Floors", "Garage", "Fireplace", "Central Air"],
        ["Granite Countertops", "Updated Kitchen", "Finished Basement"],
        ["Walk-in Closet", "Bay Windows", "Garden"],
        ["Modern Appliances", "Open Floor Plan", "Patio"],
        ["Energy Efficient", "Solar Panels", "Smart Home"],
        ["Mountain View", "Waterfront", "Gated Community"],
        ["Pool", "Hot Tub", "Outdoor Kitchen"],
        ["Stainless Steel Appliances", "Marble Bathroom", "Home Office"]
    ]
    
    private let descriptions = [
        "Beautiful home in a prime location with modern updates throughout. Perfect for families or professionals.",
        "Stunning property with spacious rooms and updated finishes. Located in a desirable neighborhood.",
        "Charming home with character and modern amenities. Close to schools, shopping, and parks.",
        "Elegant property featuring high-end finishes and attention to detail. Move-in ready condition.",
        "Spacious home with plenty of room to grow. Features include updated kitchen and bathrooms.",
        "Luxury living in a premier location. This property offers the best of comfort and style.",
        "Cozy home in a quiet neighborhood. Perfect starter home or investment property.",
        "Modern design meets classic charm. This property has been beautifully maintained and updated."
    ]
    
    func generateSampleProperties(count: Int = 50) async throws {
        var properties: [Property] = []
        
        for i in 0..<min(count, sampleLocations.count) {
            let location = sampleLocations[i]
            let priceRange: (min: Int, max: Int)
            
            // Vary prices by property type
            let typeIndex = i % propertyTypes.count
            let propertyType = propertyTypes[typeIndex]
            
            switch propertyType {
            case "house":
                priceRange = (250000, 800000)
            case "apartment":
                priceRange = (150000, 400000)
            case "condo":
                priceRange = (200000, 500000)
            case "townhouse":
                priceRange = (300000, 600000)
            case "commercial":
                priceRange = (500000, 2000000)
            default:
                priceRange = (200000, 600000)
            }
            
            let price = Int.random(in: priceRange.min...priceRange.max)
            let bedrooms = Int.random(in: 1...5)
            let bathrooms = Double.random(in: 1.0...4.5).rounded(toPlaces: 1)
            let squareFeet = Int.random(in: 800...3500)
            let yearBuilt = Int.random(in: 1950...2023)
            let imageIndex = i % sampleImages.count
            
            let property = Property(
                address: location.address,
                city: location.city,
                state: location.state,
                zipCode: location.zip,
                price: price,
                propertyType: propertyType,
                bedrooms: bedrooms,
                bathrooms: bathrooms,
                squareFeet: squareFeet,
                lotSize: propertyType == "house" ? Double.random(in: 0.1...2.0).rounded(toPlaces: 2) : nil,
                yearBuilt: yearBuilt,
                imageUrls: sampleImages[imageIndex],
                latitude: location.lat,
                longitude: location.lng,
                description: descriptions[i % descriptions.count],
                features: features[i % features.count],
                createdAt: Date(),
                updatedAt: Date()
            )
            
            properties.append(property)
        }
        
        // Save to Firestore
        let batch = db.batch()
        
        for property in properties {
            do {
                let data = try property.toDictionary()
                let ref = db.collection("properties").document(property.id)
                batch.setData(data, forDocument: ref)
            } catch {
                print("Error preparing property \(property.id): \(error)")
            }
        }
        
        try await batch.commit()
        print("✅ Successfully generated \(properties.count) mock properties")
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

