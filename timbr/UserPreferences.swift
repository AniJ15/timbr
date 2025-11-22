//
//  UserPreferences.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import Foundation

enum UserIntent: String, Codable, CaseIterable, Hashable {
    case buyHome = "buyHome"
    case rentHome = "rentHome"
    case invest = "invest"
    case designInspiration = "designInspiration"
    case sellSoon = "sellSoon"
    
    var title: String {
        switch self {
        case .buyHome:
            return "Looking for a home to buy"
        case .rentHome:
            return "Searching for a place to rent"
        case .invest:
            return "Exploring investment properties"
        case .designInspiration:
            return "Looking for design inspiration"
        case .sellSoon:
            return "Planning to sell soon"
        }
    }
    
    var iconName: String {
        switch self {
        case .buyHome:
            return "house.fill"
        case .rentHome:
            return "bed.double.fill"
        case .invest:
            return "dollarsign.circle.fill"
        case .designInspiration:
            return "paintpalette.fill"
        case .sellSoon:
            return "arrow.left.arrow.right"
        }
    }
    
    // Legacy support for old displayName
    var displayName: String {
        return title
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
    var intents: [UserIntent] = []
    // Legacy support - keep for backward compatibility
    var intent: UserIntent? {
        get { intents.first }
        set { if let newValue = newValue { intents = [newValue] } else { intents = [] } }
    }
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

