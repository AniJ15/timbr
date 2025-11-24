//
//  PropertyAPIService.swift
//  timbr
//
//  Property API Service - Handles fetching properties from external APIs
//

import Foundation
import CoreLocation

/// Service to fetch properties from external APIs
/// Currently supports multiple API providers with fallback options
class PropertyAPIService {
    static let shared = PropertyAPIService()
    
    /// Get current API usage statistics
    var currentUsage: Int {
        return getCurrentUsage()
    }
    
    var maxUsage: Int {
        return maxMonthlyRequests
    }
    
    var usagePercentage: Double {
        return Double(currentUsage) / Double(maxMonthlyRequests) * 100.0
    }
    
    // API Configuration
    private let baseURL: String
    private let apiKey: String?
    
    // Rate limiting and usage tracking
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 1.0 // 1 second between requests
    
    // Usage tracking to stay under 1000 requests/month
    private let maxMonthlyRequests = 1000
    private let usageTrackingKey = "hasdata_api_usage"
    private let usageResetDateKey = "hasdata_api_reset_date"
    
    private init() {
        // HasData Zillow Listing API Configuration
        // Free tier: 1,000 requests/month
        // Endpoint: https://api.hasdata.com/scrape/zillow/listing
        // Auth: x-api-key header
        self.baseURL = "https://api.hasdata.com"
        self.apiKey = "0f7a30f8-4d8e-4a54-b3b7-015f6871ac82"
        
        // Initialize usage tracking
        initializeUsageTracking()
    }
    
    // MARK: - Usage Tracking
    
    private func initializeUsageTracking() {
        // Check if we need to reset monthly usage
        if let resetDate = UserDefaults.standard.object(forKey: usageResetDateKey) as? Date {
            if Date() > resetDate {
                // New month, reset usage
                UserDefaults.standard.set(0, forKey: usageTrackingKey)
                UserDefaults.standard.set(getNextMonthStart(), forKey: usageResetDateKey)
                print("📊 HasData API: Monthly usage reset")
            }
        } else {
            // First time setup
            UserDefaults.standard.set(0, forKey: usageTrackingKey)
            UserDefaults.standard.set(getNextMonthStart(), forKey: usageResetDateKey)
        }
    }
    
    private func getNextMonthStart() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: now)!
        let components = calendar.dateComponents([.year, .month], from: nextMonth)
        return calendar.date(from: components) ?? nextMonth
    }
    
    private func getCurrentUsage() -> Int {
        return UserDefaults.standard.integer(forKey: usageTrackingKey)
    }
    
    private func incrementUsage() {
        let current = getCurrentUsage()
        UserDefaults.standard.set(current + 1, forKey: usageTrackingKey)
        print("📊 HasData API: Usage: \(current + 1)/\(maxMonthlyRequests)")
        
        // Warn if approaching limit
        if current + 1 >= maxMonthlyRequests * 9 / 10 {
            print("⚠️ WARNING: Approaching HasData API limit! (\(current + 1)/\(maxMonthlyRequests))")
        }
    }
    
    private func canMakeRequest() -> Bool {
        let usage = getCurrentUsage()
        if usage >= maxMonthlyRequests {
            print("❌ HasData API: Monthly limit reached (\(usage)/\(maxMonthlyRequests))")
            return false
        }
        return true
    }
    
    // MARK: - Public Methods
    
    /// Fetch properties based on location and filters using HasData Zillow Listing API
    /// Note: Zillow API requires city/state, so this converts coordinates to city/state first
    func fetchProperties(
        location: CLLocation,
        radius: Double = 50, // miles (not directly supported by Zillow API)
        minPrice: Int? = nil,
        maxPrice: Int? = nil,
        propertyTypes: [String] = [],
        minBeds: Int? = nil,
        minBaths: Double? = nil,
        limit: Int = 50
    ) async throws -> [Property] {
        // Zillow API requires city/state, not coordinates
        // For now, we'll need to use reverse geocoding or get city/state from user preferences
        // This method is kept for compatibility but should use fetchPropertiesByLocation instead
        print("⚠️ fetchProperties with CLLocation not fully supported - use fetchPropertiesByLocation with city/state")
        throw APIError.invalidURL
    }
    
    /// Fetch properties by city/state using HasData Zillow Listing API
    func fetchPropertiesByLocation(
        city: String,
        state: String,
        minPrice: Int? = nil,
        maxPrice: Int? = nil,
        propertyTypes: [String] = [],
        minBeds: Int? = nil,
        minBaths: Double? = nil,
        limit: Int = 50
    ) async throws -> [Property] {
        // Check usage limit
        guard canMakeRequest() else {
            throw APIError.rateLimitExceeded
        }
        
        guard apiKey != nil else {
            throw APIError.noAPIKey
        }
        
        // HasData Zillow Listing API endpoint
        let endpoint = "/scrape/zillow/listing"
        
        // Build query parameters for Zillow API
        // Start with minimal required parameters to avoid 422 errors
        var parameters: [String: Any] = [
            "keyword": "\(city), \(state)", // Required: location or ZIP
            "type": "forSale" // Required: forSale | forRent | sold
        ]
        
        // Only add optional parameters if they have values
        // Price filters
        if let minPrice = minPrice, minPrice > 0 {
            parameters["price.min"] = minPrice
        }
        if let maxPrice = maxPrice, maxPrice > 0 {
            parameters["price.max"] = maxPrice
        }
        
        // Bed/Bath filters
        if let minBeds = minBeds, minBeds > 0 {
            parameters["beds.min"] = minBeds
        }
        if let minBaths = minBaths, minBaths > 0 {
            parameters["baths.min"] = Int(minBaths) // API might expect Int
        }
        
        // Property types (homeTypes) - HasData expects array format
        // Valid values: ["house","townhome","multiFamily","condo","lot","apartment","manufactured"]
        var homeTypesArray: [String] = []
        if !propertyTypes.isEmpty {
            // Convert property types to HasData Zillow API format
            let zillowTypes = propertyTypes.compactMap { type -> String? in
                switch type.lowercased() {
                case "house": return "house"
                case "apartment": return "apartment"
                case "condo": return "condo"
                case "townhouse": return "townhome" // API uses "townhome" not "townhouse"
                case "commercial": return nil // Not supported by Zillow API
                case "warehouse": return nil // Not supported by Zillow API
                case "land": return "lot" // API uses "lot" for land
                case "browsing": return nil
                default: return nil
                }
            }
            
            homeTypesArray = zillowTypes
        }
        
        // Pagination - start with page 1 (optional, but helps)
        parameters["page"] = 1
        
        // Log parameters for debugging
        print("📋 API Request Parameters: \(parameters)")
        if !homeTypesArray.isEmpty {
            print("📋 homeTypes array: \(homeTypesArray)")
        }
        
        do {
            // Make request with special handling for homeTypes array
            let response: ZillowListingResponse = try await makeRequestWithArrayParams(
                endpoint: endpoint,
                method: "GET",
                parameters: parameters,
                arrayParams: ["homeTypes": homeTypesArray]
            )
            
            // Track API usage
            incrementUsage()
            lastRequestTime = Date()
            
            // Convert Zillow listings to Property models
            // Use allProperties which handles both "properties" and "results" fields
            let allProperties = response.allProperties
            print("📊 API returned \(allProperties.count) raw properties")
            if let totalResults = response.searchInformation?.totalResults {
                print("📊 Total results available: \(totalResults)")
            }
            let properties = allProperties.prefix(limit).map { convertZillowListingToProperty($0) }
            
            print("✅ Fetched \(properties.count) properties from HasData Zillow API")
            return Array(properties)
        } catch APIError.httpError(let code) where code == 422 {
            // 422 = Unprocessable Entity - try with minimal parameters
            print("⚠️ 422 error - trying with minimal parameters (keyword and type only)")
            
            let minimalParams: [String: Any] = [
                "keyword": "\(city), \(state)",
                "type": "forSale"
            ]
            
            do {
                let response: ZillowListingResponse = try await makeRequest(
                    endpoint: endpoint,
                    method: "GET",
                    parameters: minimalParams
                )
                
                incrementUsage()
                lastRequestTime = Date()
                
                let allProperties = response.allProperties
                print("📊 API returned \(allProperties.count) raw properties")
                let properties = allProperties.prefix(limit).map { convertZillowListingToProperty($0) }
                print("✅ Fetched \(properties.count) properties with minimal parameters")
                return Array(properties)
            } catch {
                print("❌ Retry with minimal parameters also failed: \(error)")
                throw error
            }
        } catch {
            if case APIError.httpError(let code) = error {
                print("❌ HasData Zillow API HTTP error: \(code)")
                if code == 404 {
                    print("⚠️ API endpoint not found - check HasData documentation")
                } else if code == 401 {
                    print("⚠️ Authentication failed - check API key")
                } else if code == 422 {
                    print("⚠️ Invalid request parameters - check API documentation")
                }
            }
            throw error
        }
    }
    
    /// Fetch property details by ID
    func fetchPropertyDetails(propertyId: String) async throws -> Property? {
        // TODO: Implement API call
        print("⚠️ PropertyAPIService: API integration not yet implemented")
        return nil
    }
    
    // MARK: - Private Helper Methods
    
    /// Make request with support for array parameters (like homeTypes)
    private func makeRequestWithArrayParams<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        parameters: [String: Any] = [:],
        arrayParams: [String: [String]] = [:]
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add API key if available
        if let apiKey = apiKey {
            if baseURL.contains("hasdata") {
                // HasData Zillow API uses x-api-key header
                request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
            }
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build query parameters with array support
        if method == "GET" && (!parameters.isEmpty || !arrayParams.isEmpty) {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            var queryItems: [URLQueryItem] = []
            
            // Add regular parameters
            for (key, value) in parameters {
                queryItems.append(URLQueryItem(name: key, value: "\(value)"))
            }
            
            // Add array parameters (multiple query items with same name)
            for (key, values) in arrayParams {
                for value in values {
                    queryItems.append(URLQueryItem(name: key, value: value))
                }
            }
            
            components?.queryItems = queryItems
            if let newURL = components?.url {
                request.url = newURL
            }
        }
        
        // Log the request URL for debugging
        if let url = request.url {
            print("🌐 API Request URL: \(url.absoluteString)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Log the request URL for debugging
        if let url = request.url {
            print("🌐 API Request URL: \(url.absoluteString)")
        }
        
        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 API Response (first 500 chars): \(String(responseString.prefix(500)))")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Log error response body for debugging
            if let errorData = String(data: data, encoding: .utf8) {
                print("❌ API Error Response: \(errorData)")
            }
            print("❌ API Error Status: \(httpResponse.statusCode)")
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Decoding error: \(error)")
            print("❌ Response data: \(String(data: data.prefix(1000), encoding: .utf8) ?? "Unable to decode")")
            throw APIError.decodingError(error)
        }
    }
    
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        parameters: [String: Any] = [:]
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add API key if available
        if let apiKey = apiKey {
            if baseURL.contains("hasdata") {
                // HasData Zillow API uses x-api-key header
                request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
            } else if baseURL.contains("rentcast") {
                request.addValue(apiKey, forHTTPHeaderField: "X-Api-Key")
            } else if baseURL.contains("rapidapi") {
                request.addValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
                request.addValue("realty-mole-property-api.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
            } else {
                request.addValue(apiKey, forHTTPHeaderField: "X-Api-Key")
            }
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add query parameters for GET requests
        if method == "GET" && !parameters.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            var queryItems: [URLQueryItem] = []
            
            for (key, value) in parameters {
                // URLComponents handles encoding automatically, so we don't need to double-encode
                queryItems.append(URLQueryItem(name: key, value: "\(value)"))
            }
            
            components?.queryItems = queryItems
            if let newURL = components?.url {
                request.url = newURL
            }
        }
        
        // Add body for POST requests
        if method == "POST" && !parameters.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 API Response (first 1000 chars): \(String(responseString.prefix(1000)))")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Log error response body for debugging
            if let errorData = String(data: data, encoding: .utf8) {
                print("❌ API Error Response: \(errorData)")
            }
            print("❌ API Error Status: \(httpResponse.statusCode)")
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Decoding error: \(error)")
            print("❌ Response data: \(String(data: data.prefix(1000), encoding: .utf8) ?? "Unable to decode")")
            throw APIError.decodingError(error)
        }
    }
}

    // MARK: - Helper Methods
    
    /// Convert Zillow listing to Property model
    private func convertZillowListingToProperty(_ listing: ZillowListing) -> Property {
        // Parse address components - try multiple sources
        let streetAddress = listing.address?.street ?? listing.streetAddress ?? ""
        let city = listing.address?.city ?? listing.city ?? ""
        let state = listing.address?.state ?? listing.state ?? ""
        let zipCode = listing.address?.zipCode ?? listing.address?.zip ?? listing.zipCode ?? ""
        
        // Parse price - API returns Int directly
        let price = listing.price ?? 0
        
        // Parse beds and baths - try alternative field names
        let beds = listing.beds ?? listing.bedrooms ?? 0
        let baths = listing.baths ?? listing.bathrooms ?? 0.0
        
        // Parse square feet - try alternative field names
        let sqft = listing.squareFeet ?? listing.livingArea ?? listing.area ?? 0
        
        // Get property type - API returns "SINGLE_FAMILY", "CONDO", etc.
        // Convert to lowercase and map to our format
        let homeTypeRaw = (listing.homeType ?? "SINGLE_FAMILY").lowercased()
        let propertyType: String
        switch homeTypeRaw {
        case "single_family", "singlefamily":
            propertyType = "house"
        case "condo", "condominium":
            propertyType = "condo"
        case "townhome", "townhouse":
            propertyType = "townhouse"
        case "apartment", "multi_family", "multifamily":
            propertyType = "apartment"
        case "lot", "land":
            propertyType = "land"
        default:
            propertyType = "house" // Default fallback
        }
        
        // Get images - try both photos array and single image
        var images: [String] = []
        if let photos = listing.photos, !photos.isEmpty {
            images = photos
        } else if let image = listing.image {
            images = [image]
        }
        
        // Get location - try multiple sources
        let lat = listing.location?.latitude ?? listing.latitude ?? 0.0
        let lng = listing.location?.longitude ?? listing.longitude ?? 0.0
        
        // Build description
        var description = listing.description ?? ""
        if description.isEmpty {
            description = "\(propertyType.capitalized) in \(city), \(state)"
            if let status = listing.status {
                description += " - \(status)"
            }
        }
        
        // Build features list
        var features: [String] = []
        if beds > 0 {
            features.append("\(beds) Bed\(beds > 1 ? "s" : "")")
        }
        if baths > 0 {
            features.append("\(baths) Bath\(baths > 1 ? "s" : "")")
        }
        if sqft > 0 {
            features.append("\(sqft) sq ft")
        }
        if let lotSize = listing.lotSize {
            features.append("Lot: \(lotSize)")
        }
        if let yearBuilt = listing.yearBuilt {
            features.append("Built: \(yearBuilt)")
        }
        
        return Property(
            id: listing.id ?? listing.url ?? UUID().uuidString,
            address: streetAddress,
            city: city,
            state: state,
            zipCode: zipCode,
            price: price,
            propertyType: propertyType,
            bedrooms: beds,
            bathrooms: baths,
            squareFeet: sqft > 0 ? sqft : nil,
            lotSize: parseLotSize(listing.lotSize),
            yearBuilt: listing.yearBuilt,
            imageUrls: images,
            latitude: lat,
            longitude: lng,
            description: description,
            features: features,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    /// Parse lot size string to Double (handles "0.5 acres", "5000 sq ft", etc.)
    private func parseLotSize(_ lotSizeString: String?) -> Double? {
        guard let lotSizeString = lotSizeString else { return nil }
        
        // Try to extract number
        let cleaned = lotSizeString.replacingOccurrences(of: ",", with: "")
        let components = cleaned.components(separatedBy: CharacterSet.whitespaces)
        
        if let firstComponent = components.first,
           let value = Double(firstComponent) {
            // Check if it's acres or sq ft
            if lotSizeString.lowercased().contains("acre") {
                return value // Return as acres
            } else {
                // Assume sq ft, convert to acres (1 acre = 43,560 sq ft)
                return value / 43560.0
            }
        }
        
        return nil
    }


// MARK: - HasData Zillow Listing API Response Models

struct ZillowListingResponse: Codable {
    let properties: [ZillowListing]? // API returns "properties" not "results"
    let results: [ZillowListing]? // Fallback for different response formats
    let requestMetadata: RequestMetadata?
    let searchInformation: SearchInformation?
    let hasNextPage: Bool?
    let currentPage: Int?
    
    enum CodingKeys: String, CodingKey {
        case properties, results, requestMetadata, searchInformation
        case hasNextPage, currentPage
    }
    
    // Get properties from either field
    var allProperties: [ZillowListing] {
        return properties ?? results ?? []
    }
}

struct RequestMetadata: Codable {
    let id: String?
    let status: String?
    let html: String?
    let json: String?
    let url: String?
}

struct SearchInformation: Codable {
    let totalResults: Int?
}

struct ZillowListing: Codable {
    let id: String?
    let url: String?
    let price: Int? // Price as integer (API returns number, not string)
    let status: String?
    let daysOnZillow: Int?
    
    // Address - API might return address as object or separate fields
    let address: ZillowAddress?
    let streetAddress: String?
    let city: String?
    let state: String?
    let zipCode: String?
    
    // Property details
    let beds: Int?
    let bedrooms: Int? // Alternative field name
    let baths: Double?
    let bathrooms: Double? // Alternative field name
    let squareFeet: Int?
    let livingArea: Int?
    let area: Int? // Alternative field name
    let homeType: String? // API returns "SINGLE_FAMILY", "CONDO", etc.
    let lotSize: String?
    let yearBuilt: Int?
    
    // Media
    let photos: [String]?
    let image: String? // Single image URL
    
    // Location
    let location: ZillowLocation?
    let latitude: Double?
    let longitude: Double?
    
    // Broker info
    let broker: ZillowBroker?
    
    // Schools
    let schools: [ZillowSchool]?
    
    // Description
    let description: String?
    
    // Additional Zillow fields
    let zestimate: Int?
    let rentZestimate: Int?
    let currency: String?
    
    enum CodingKeys: String, CodingKey {
        case id, url, price, status, daysOnZillow
        case address, streetAddress, city, state, zipCode
        case beds, bedrooms, baths, bathrooms
        case squareFeet, livingArea, area
        case homeType, lotSize, yearBuilt
        case photos, image, location, latitude, longitude
        case broker, schools, description
        case zestimate, rentZestimate, currency
    }
    
    // Computed property for priceString fallback (not in API response)
    var priceString: String? {
        if let price = price {
            return "$\(price)"
        }
        return nil
    }
}

struct ZillowAddress: Codable {
    let street: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let zip: String? // Alternative field name
    
    enum CodingKeys: String, CodingKey {
        case street, city, state, zipCode, zip
    }
}

struct ZillowLocation: Codable {
    let latitude: Double?
    let longitude: Double?
}

struct ZillowBroker: Codable {
    let name: String?
    let phone: String?
    let email: String?
}

struct ZillowSchool: Codable {
    let name: String?
    let district: String?
    let rating: Double?
}

// MARK: - API Error Types
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case rateLimitExceeded
    case noAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "API rate limit exceeded (1000/month limit reached)"
        case .noAPIKey:
            return "API key not configured"
        }
    }
}

