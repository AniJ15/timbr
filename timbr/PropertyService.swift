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
import CoreLocationUI

@MainActor
class PropertyService: ObservableObject {
    @Published var properties: [Property] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let apiService = PropertyAPIService.shared
    var onboardingManager: OnboardingManager? // Will be set from SwipeView
    
    // Cache settings
    private let cacheDuration: TimeInterval = 24 * 60 * 60 // 24 hours
    private let lastCacheUpdateKey = "lastPropertyCacheUpdate"
    
    init() {
        // Don't load properties on init - wait for onboardingManager to be set
        // Properties will be loaded when SwipeView calls loadProperties()
    }
    
    deinit {
        listener?.remove()
    }
    
    /// Load properties from HasData Zillow API (with Firestore caching)
    /// Only uses API data - no mock data
    func loadProperties() async {
        isLoading = true
        errorMessage = nil
        
        // First, try to load from Firestore cache (only API-sourced data)
        let cachedProperties = await loadFromFirestore()
        
        // Always fetch from API if cache is stale or empty
        // This ensures we only show API data, not old mock data
        let shouldFetchFromAPI = cachedProperties.isEmpty || isCacheStale()
        
        if shouldFetchFromAPI {
            print("🔄 Cache is stale or empty, fetching from API...")
            
            // Try to fetch from HasData Zillow API
            // Note: Zillow API requires city/state, not coordinates
            do {
                // Get city/state from user preferences
                if let onboardingManager = onboardingManager {
                    var city: String?
                    var state: String?
                    var zipCode: String?
                    
                    // First, try to parse location string
                    if let location = onboardingManager.preferences.location,
                       location != "Current Location" {
                        let trimmed = location.trimmingCharacters(in: CharacterSet.whitespaces)
                        
                        // Check if it's a ZIP code (5 digits)
                        if trimmed.count == 5 && trimmed.allSatisfy({ $0.isNumber }) {
                            zipCode = trimmed
                            print("📍 Detected ZIP code: \(zipCode!)")
                        } else {
                            // Try to parse as "City, State" format
                            let components = location.components(separatedBy: ",")
                            if components.count >= 2 {
                                city = components[0].trimmingCharacters(in: CharacterSet.whitespaces)
                                state = components[1].trimmingCharacters(in: CharacterSet.whitespaces)
                            } else {
                                // Single value - might be city name
                                city = trimmed
                                print("⚠️ Location is city name only: \(city!)")
                            }
                        }
                    }
                    
                    // Get user preferences for filtering (define once for all code paths)
                    let minPrice = onboardingManager.preferences.minPrice
                    let maxPrice = onboardingManager.preferences.maxPrice
                    
                    // Convert property types to strings (define once for all code paths)
                    let propertyTypes = onboardingManager.preferences.propertyTypes
                        .filter { $0 != .browsing }
                        .map { type in
                            switch type {
                            case .house: return "house"
                            case .apartment: return "apartment"
                            case .condo: return "condo"
                            case .townhouse: return "townhouse"
                            case .commercial: return "commercial"
                            case .warehouse: return "warehouse"
                            case .land: return "land"
                            case .browsing: return ""
                            }
                        }
                        .filter { !$0.isEmpty }
                    
                    // If we have a ZIP code, use it directly
                    if let zip = zipCode {
                        print("🌐 Fetching from HasData Zillow API using ZIP code: \(zip)")
                        let apiProperties = try await apiService.fetchPropertiesByLocation(
                            city: nil,
                            state: nil,
                            zipCode: zip,
                            minPrice: minPrice,
                            maxPrice: maxPrice,
                            propertyTypes: propertyTypes,
                            limit: 50
                        )
                        
                        if !apiProperties.isEmpty {
                            await saveToFirestore(apiProperties)
                            self.properties = apiProperties
                            updateCacheTimestamp()
                            print("✅ Loaded \(apiProperties.count) properties from HasData Zillow API (ZIP code)")
                            print("📊 PropertyService.properties.count after ZIP fetch: \(self.properties.count)")
                            isLoading = false
                            return // Exit early after successful ZIP code fetch
                        } else {
                            self.properties = cachedProperties
                            print("⚠️ API returned empty for ZIP code, using cached properties")
                            if cachedProperties.isEmpty {
                                errorMessage = "No properties found for ZIP code \(zip). Try a different location."
                            }
                            isLoading = false
                            return // Exit early even if API returned empty
                        }
                    }
                    // If we have coordinates but no city/state/ZIP, reverse geocode them
                    else if (city == nil || state == nil) {
                        if let lat = onboardingManager.preferences.latitude,
                           let lng = onboardingManager.preferences.longitude {
                            print("📍 Have coordinates, reverse geocoding to get city/state: \(lat), \(lng)")
                            
                            // Reverse geocode coordinates to get city/state
                            let location = CLLocation(latitude: lat, longitude: lng)
                            let geocoder = CLGeocoder()
                            
                            do {
                                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                                if let placemark = placemarks.first {
                                    city = placemark.locality ?? placemark.subAdministrativeArea
                                    state = placemark.administrativeArea
                                    print("✅ Reverse geocoded: \(city ?? "unknown"), \(state ?? "unknown")")
                                    
                                    // Update preferences with the actual city/state
                                    if let city = city, let state = state {
                                        onboardingManager.preferences.location = "\(city), \(state)"
                                        Task {
                                            await onboardingManager.savePreferences()
                                        }
                                    }
                                }
                            } catch {
                                print("❌ Reverse geocoding failed: \(error.localizedDescription)")
                            }
                            
                            // If reverse geocoding failed, show error
                            if city == nil || state == nil {
                                print("❌ Could not determine city/state from coordinates")
                                self.properties = cachedProperties
                                errorMessage = "Could not determine your location. Please set it manually in Profile → Settings."
                                isLoading = false
                                return
                            }
                        } else {
                            print("❌ No location data available")
                            self.properties = cachedProperties
                            errorMessage = "Please set your location in Profile → Settings → Edit Preferences"
                            isLoading = false
                            return
                        }
                    }
                    
                    // If we have city and state (or got them from reverse geocoding), use them
                    if let city = city, let state = state {
                        print("🌐 Fetching from HasData Zillow API: \(city), \(state)")
                        let apiProperties = try await apiService.fetchPropertiesByLocation(
                            city: city,
                            state: state,
                            minPrice: minPrice,
                            maxPrice: maxPrice,
                            propertyTypes: propertyTypes,
                            limit: 50
                        )
                        
                        if !apiProperties.isEmpty {
                            await saveToFirestore(apiProperties)
                            self.properties = apiProperties
                            updateCacheTimestamp()
                            print("✅ Loaded \(apiProperties.count) properties from HasData Zillow API")
                        } else {
                            // Fallback to cache if API returns empty
                            self.properties = cachedProperties
                            print("⚠️ API returned empty, using cached properties")
                            if cachedProperties.isEmpty {
                                errorMessage = "No properties found. Try adjusting your filters or location."
                            }
                        }
                    } else {
                        // Can't determine city/state
                        self.properties = cachedProperties
                        print("⚠️ Could not determine city/state from location data")
                        errorMessage = "Please set your location in Profile → Settings → Edit Preferences"
                    }
                } else {
                    // No onboarding manager available
                    self.properties = cachedProperties
                    print("⚠️ No onboarding manager available, using cached properties")
                    errorMessage = "Please complete onboarding to view properties"
                }
            } catch APIError.rateLimitExceeded {
                print("❌ HasData API: Rate limit exceeded, using cached data")
                self.properties = cachedProperties
                errorMessage = "API limit reached. Using cached data."
            } catch APIError.httpError(let code) {
                print("❌ HasData API HTTP error: \(code)")
                // If 404, the endpoint might be wrong - use cache
                if code == 404 {
                    print("⚠️ API endpoint not found - check HasData API documentation")
                    self.properties = cachedProperties
                    errorMessage = "API endpoint not configured. Using cached data."
                } else {
                    self.properties = cachedProperties
                    errorMessage = "API error. Using cached data."
                }
            } catch {
                print("❌ API error: \(error.localizedDescription)")
                // Fallback to cache on error
                self.properties = cachedProperties
                errorMessage = "Using cached data. API unavailable."
            }
        } else {
            // Use cached data
            self.properties = cachedProperties
            print("✅ Loaded \(cachedProperties.count) properties from cache")
        }
        
        isLoading = false
    }
    
    /// Load properties from Firestore cache (only API-sourced data)
    /// Only returns properties if cache timestamp exists (meaning API data was previously fetched)
    private func loadFromFirestore() async -> [Property] {
        // If no cache timestamp exists, it means no API data has been fetched yet
        // Return empty to force API fetch (prevents using old mock data)
        if !hasValidCacheTimestamp() {
            print("🔄 No API cache found, will fetch from API")
            return []
        }
        
        do {
            let snapshot = try await db.collection("properties")
                .order(by: "createdAt", descending: true)
                .limit(to: 100)
                .getDocuments()
            
            let properties = snapshot.documents.compactMap { doc in
                var data = doc.data()
                data["id"] = doc.documentID
                return try? Property.fromDictionary(data)
            }
            
            return properties
        } catch {
            print("❌ Error loading from Firestore: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Check if we have a valid cache timestamp (meaning API data exists)
    private func hasValidCacheTimestamp() -> Bool {
        return UserDefaults.standard.object(forKey: lastCacheUpdateKey) as? Date != nil
    }
    
    /// Save properties to Firestore cache
    private func saveToFirestore(_ properties: [Property]) async {
        let batch = db.batch()
        
        for property in properties {
            do {
                let data = try property.toDictionary()
                let ref = db.collection("properties").document(property.id)
                batch.setData(data, forDocument: ref, merge: true)
            } catch {
                print("❌ Error saving property \(property.id): \(error)")
            }
        }
        
        do {
            try await batch.commit()
            print("✅ Saved \(properties.count) properties to Firestore")
        } catch {
            print("❌ Error committing batch: \(error)")
        }
    }
    
    /// Check if cache is stale
    /// Returns true if no cache timestamp exists (meaning no API data has been fetched yet)
    private func isCacheStale() -> Bool {
        if let lastUpdate = UserDefaults.standard.object(forKey: lastCacheUpdateKey) as? Date {
            return Date().timeIntervalSince(lastUpdate) > cacheDuration
        }
        // No cache timestamp = no API data has been fetched yet
        // Return true to force API fetch (this prevents using old mock data)
        return true
    }
    
    /// Update cache timestamp
    private func updateCacheTimestamp() {
        UserDefaults.standard.set(Date(), forKey: lastCacheUpdateKey)
    }
    
    /// Get user location from preferences or return nil
    private func getUserLocation() -> CLLocation? {
        // Try to get location from onboarding preferences
        if let onboardingManager = onboardingManager,
           let locationString = onboardingManager.preferences.location {
            // Try to parse coordinates if stored as "lat,lng"
            let components = locationString.components(separatedBy: ",")
            if components.count == 2,
               let lat = Double(components[0].trimmingCharacters(in: CharacterSet.whitespaces)),
               let lng = Double(components[1].trimmingCharacters(in: CharacterSet.whitespaces)) {
                return CLLocation(latitude: lat, longitude: lng)
            }
        }
        return nil
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

