//
//  UserPreferences.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import Foundation

enum UserIntent: String, Codable, CaseIterable {
    case buying = "buying"
    case investing = "investing"
    case browsing = "browsing"
    
    var displayName: String {
        switch self {
        case .buying:
            return "Buying a home"
        case .investing:
            return "Exploring commercial real estate / investment opportunities"
        case .browsing:
            return "Browsing casually"
        }
    }
}

enum PropertyType: String, Codable, CaseIterable {
    case house = "house"
    case apartment = "apartment"
    case condo = "condo"
    case warehouse = "warehouse"
    case land = "land"
    case townhouse = "townhouse"
    case commercial = "commercial"
    case browsing = "browsing"
    
    var displayName: String {
        switch self {
        case .house:
            return "Houses"
        case .apartment:
            return "Apartments"
        case .condo:
            return "Condos"
        case .warehouse:
            return "Warehouses"
        case .land:
            return "Land"
        case .townhouse:
            return "Townhouses"
        case .commercial:
            return "Commercial"
        case .browsing:
            return "Just browsing"
        }
    }
}

struct UserPreferences: Codable {
    var intent: UserIntent?
    var propertyTypes: [PropertyType] = []
    var minPrice: Int?
    var maxPrice: Int?
    var location: String?
    var latitude: Double?
    var longitude: Double?
    var hasCompletedOnboarding: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init() {}
}

