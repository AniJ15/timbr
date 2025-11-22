//
//  Property.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import Foundation
import CoreLocation

struct Property: Codable, Identifiable, Hashable {
    var id: String
    var address: String
    var city: String
    var state: String
    var zipCode: String
    var price: Int
    var propertyType: String // house, apartment, condo, etc.
    
    // Features
    var bedrooms: Int
    var bathrooms: Double
    var squareFeet: Int?
    var lotSize: Double? // in acres
    var yearBuilt: Int?
    
    // Images
    var imageUrls: [String]
    
    // Location
    var latitude: Double
    var longitude: Double
    
    // Description
    var description: String
    var features: [String] // e.g., ["Hardwood Floors", "Garage", "Fireplace"]
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        address: String,
        city: String,
        state: String,
        zipCode: String,
        price: Int,
        propertyType: String,
        bedrooms: Int,
        bathrooms: Double,
        squareFeet: Int? = nil,
        lotSize: Double? = nil,
        yearBuilt: Int? = nil,
        imageUrls: [String] = [],
        latitude: Double,
        longitude: Double,
        description: String,
        features: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.price = price
        self.propertyType = propertyType
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.squareFeet = squareFeet
        self.lotSize = lotSize
        self.yearBuilt = yearBuilt
        self.imageUrls = imageUrls
        self.latitude = latitude
        self.longitude = longitude
        self.description = description
        self.features = features
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var fullAddress: String {
        return "\(address), \(city), \(state) \(zipCode)"
    }
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }
    
    var location: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Firestore Extensions
extension Property {
    func toDictionary() throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    static func fromDictionary(_ dictionary: [String: Any]) throws -> Property {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Property.self, from: data)
    }
}

