# API Integration Guide for Timbr

## Best Free Real Estate APIs (2024-2025)

### 1. **RentCast API** ⭐ Top Recommendation
- **Free Tier**: 1,000 requests/month
- **URL**: https://rentcast.io/
- **API Docs**: https://developers.rentcast.io/
- **Pros**: 
  - Generous free tier (1,000 requests/month)
  - Real-time property and rental data
  - Good documentation
  - Property search, details, rental estimates
  - Market statistics
- **Cons**: 
  - US-only data
  - Requires credit card for free tier (but won't charge)
- **Sign Up**: https://rentcast.io/pricing

### 2. **HasData Real Estate APIs** ⭐ Good Alternative
- **Free Tier**: 1,000 requests/month
- **URL**: https://hasdata.com/apis/real-estate
- **Pros**: 
  - 1,000 free requests/month
  - Real-time property listings
  - Agent information
  - Market trends
- **Cons**: 
  - May require approval
- **Sign Up**: https://hasdata.com/

### 3. **RealtyMole Property API** (via RapidAPI)
- **Free Tier**: 500 requests/month
- **URL**: Search "RealtyMole" on RapidAPI marketplace
- **Pros**: 
  - Available on RapidAPI (easy integration)
  - Comprehensive property data
  - Includes rental estimates
- **Cons**: 
  - Lower free tier limit
  - Some endpoints may require paid plan
- **Sign Up**: https://rapidapi.com (search for RealtyMole)

### 4. **Apify Real Estate API**
- **Free Tier**: Trial available
- **URL**: https://apify.com/api/real-estate-api
- **Pros**: 
  - No credit card required for trial
  - Programmatic access to real estate data
- **Cons**: 
  - May have usage limits on free tier
- **Sign Up**: https://apify.com/

### 5. **TovoData Real Estate API**
- **Free Tier**: Available with registration
- **URL**: https://tovodata.com/real-estate-data-api/
- **Pros**: 
  - Free access with registration
  - Comprehensive data (property characteristics, ownership, mortgage)
- **Cons**: 
  - May have limited features on free tier
- **Sign Up**: https://tovodata.com/

### 6. **Zillow API** ❌ Not Available
- Zillow shut down their public API in 2018
- Not recommended for new projects

## Implementation Architecture

### Recommended Approach:

1. **Hybrid Model** (Best for your use case):
   - Fetch properties from API
   - Cache results in Firestore
   - Serve from Firestore to app (faster, offline support)
   - Refresh cache periodically

2. **Service Layer Structure**:
   ```
   PropertyAPIService (handles API calls)
        ↓
   PropertyService (manages Firestore cache + API sync)
        ↓
   SwipeView (displays properties)
   ```

## Step-by-Step Implementation

### Step 1: Choose and Sign Up for an API

**Recommended: RentCast** (easiest to get started)

1. Go to https://rentcast.io/pricing
2. Sign up for the free tier (1,000 requests/month)
3. Get your API key from the dashboard
4. Review documentation at https://developers.rentcast.io/

**Alternative: HasData** (also good free tier)

1. Go to https://hasdata.com/
2. Sign up for free account
3. Navigate to Real Estate APIs section
4. Get your API key

### Step 2: Configure API Key

**For RentCast**, update `PropertyAPIService.swift`:
```swift
private init() {
    self.baseURL = "https://api.rentcast.io/v1"
    self.apiKey = "YOUR_RENTCAST_API_KEY_HERE" // Add your key
}
```

**For HasData**, update:
```swift
private init() {
    self.baseURL = "https://api.hasdata.com/v1"
    self.apiKey = "YOUR_HASDATA_API_KEY_HERE" // Add your key
}
```

### Step 3: Implement API Endpoints

Update `PropertyAPIService.swift` with actual API calls. 

**Example for RentCast:**

```swift
func fetchProperties(
    location: CLLocation,
    radius: Double = 50,
    minPrice: Int? = nil,
    maxPrice: Int? = nil,
    propertyTypes: [String] = [],
    limit: Int = 50
) async throws -> [Property] {
    // Rate limiting check
    await checkRateLimit()
    
    let endpoint = "/properties"
    var parameters: [String: Any] = [
        "latitude": location.coordinate.latitude,
        "longitude": location.coordinate.longitude,
        "radius": radius,
        "limit": limit
    ]
    
    if let minPrice = minPrice {
        parameters["minPrice"] = minPrice
    }
    if let maxPrice = maxPrice {
        parameters["maxPrice"] = maxPrice
    }
    if !propertyTypes.isEmpty {
        parameters["propertyType"] = propertyTypes.first // RentCast uses single type
    }
    
    let response: RentCastResponse = try await makeRequest(
        endpoint: endpoint,
        parameters: parameters
    )
    
    // Convert API response to Property models
    return response.map { apiProperty in
        convertRentCastToProperty(apiProperty)
    }
}
```

**RentCast API Endpoints:**
- `GET /properties` - Search properties
- `GET /properties/{id}` - Get property details
- `GET /properties/rental-estimates` - Get rental estimates

See full docs: https://developers.rentcast.io/

### Step 4: Update PropertyService to Use API

Modify `PropertyService.swift` to:
1. Check Firestore cache first
2. If cache is stale/empty, fetch from API
3. Save API results to Firestore
4. Return properties to app

### Step 5: Handle API Response Models

Create response models matching the API structure. **For RentCast:**

```swift
struct RentCastProperty: Codable {
    let id: String
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let price: Int?
    let bedrooms: Int?
    let bathrooms: Double?
    let squareFootage: Int?
    let propertyType: String
    let latitude: Double
    let longitude: Double
    let description: String?
    let images: [String]?
    // ... add other fields as needed
}

// Helper function to convert RentCast property to your Property model
private func convertRentCastToProperty(_ rentCast: RentCastProperty) -> Property {
    return Property(
        id: rentCast.id,
        address: rentCast.address,
        city: rentCast.city,
        state: rentCast.state,
        zipCode: rentCast.zipCode,
        price: rentCast.price ?? 0,
        propertyType: rentCast.propertyType.lowercased(),
        bedrooms: rentCast.bedrooms ?? 0,
        bathrooms: rentCast.bathrooms ?? 0,
        squareFeet: rentCast.squareFootage,
        imageUrls: rentCast.images ?? [],
        latitude: rentCast.latitude,
        longitude: rentCast.longitude,
        description: rentCast.description ?? "",
        features: []
    )
}
```

## Caching Strategy

### Recommended Cache Settings:
- **Cache Duration**: 24 hours for property listings
- **Refresh Strategy**: 
  - Background refresh when app opens
  - Manual refresh button in settings
  - Auto-refresh when cache is > 24 hours old

### Implementation:
```swift
func loadProperties() async {
    // 1. Check Firestore cache
    let cachedProperties = await loadFromFirestore()
    
    // 2. Check if cache is stale
    if isCacheStale() {
        // 3. Fetch from API
        let apiProperties = try? await PropertyAPIService.shared.fetchProperties(...)
        
        // 4. Update Firestore cache
        if let apiProperties = apiProperties {
            await saveToFirestore(apiProperties)
            self.properties = apiProperties
        } else {
            // Fallback to cache if API fails
            self.properties = cachedProperties
        }
    } else {
        self.properties = cachedProperties
    }
}
```

## Error Handling

Implement robust error handling:
- Network failures → Use cached data
- API rate limits → Queue requests, show user message
- Invalid responses → Log error, use fallback
- Authentication errors → Prompt user to check API key

## Rate Limiting

Most free APIs have rate limits:
- **RentSpider**: 500 requests/month (free tier)
- Implement request queuing
- Cache aggressively to minimize API calls
- Show user-friendly messages when limits are reached

## Testing

1. **Test with Mock Data First**: Ensure your Property model conversion works
2. **Test API Calls**: Use Postman or curl to verify API responses
3. **Test Caching**: Verify Firestore cache works correctly
4. **Test Error Cases**: Network failures, rate limits, invalid responses

## Cost Considerations

### Free Tier Limitations:
- Most APIs: 500-1000 requests/month
- For production, you'll likely need a paid plan

### Cost Optimization:
- Cache aggressively (24+ hour cache)
- Batch requests when possible
- Only fetch what you need (use filters)
- Consider upgrading to paid tier for production

## Next Steps

1. ✅ Choose an API provider (RentSpider recommended)
2. ✅ Sign up and get API key
3. ✅ Update `PropertyAPIService.swift` with your API key
4. ✅ Implement API endpoint methods
5. ✅ Create API response models
6. ✅ Update `PropertyService` to use API + cache
7. ✅ Test thoroughly
8. ✅ Deploy and monitor API usage

## Alternative: Use Your Own Backend

If API costs become prohibitive, consider:
- Building a web scraper (legal considerations apply)
- Partnering with MLS (requires membership)
- Using a property data aggregator service
- Building your own data collection system

