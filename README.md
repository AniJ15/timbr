# Timbr

Timbr is an iOS app for discovering homes, rentals, and investment properties through a swipe-based experience. After a short onboarding flow, users get a personalized deck of listings powered by real estate data, with matches and preferences synced via Firebase.

## Features

- **Swipe deck** — Browse properties with card-style gestures (like / pass)
- **Onboarding** — Four-step setup: intent, property types, budget, and location
- **Google sign-in** — Authentication and account sync through Firebase Auth
- **Saved listings** — Heart properties to review later
- **Profile & preferences** — View and adjust search criteria stored in Firestore
- **Smart property fetching** — HasData Zillow listings with Firestore caching, rate limiting, and monthly usage caps

## Tech stack

| Layer | Technology |
|-------|------------|
| UI | SwiftUI |
| Auth | Firebase Auth + Google Sign-In |
| Data | Cloud Firestore |
| Listings | [HasData](https://hasdata.com/) Zillow Listing API |
| Dependencies | Swift Package Manager (Firebase iOS SDK, GoogleSignIn) |

## Requirements

- macOS with **Xcode** (project targets iOS **26.1** per `timbr.xcodeproj`)
- An Apple Developer account (for device testing and signing)
- A [Firebase](https://console.firebase.google.com/) project with iOS app configured
- A [HasData](https://hasdata.com/) API key (free tier: 1,000 requests/month)

## Getting started

### 1. Clone and open

```bash
git clone https://github.com/<your-org>/timbr.git
cd timbr
open timbr.xcodeproj
```

### 2. Firebase setup

1. Create or use an existing Firebase project.
2. Add an iOS app with bundle ID `priyaandani.timbr` (or update the bundle ID in Xcode to match your Firebase app).
3. Download `GoogleService-Info.plist` and place it in the `timbr/` folder (replacing the existing file if needed).
4. Enable **Google** as a sign-in provider in Firebase Authentication.
5. Configure the **reversed client ID** URL scheme in `Info.plist` to match your `GoogleService-Info.plist` (see `CFBundleURLSchemes`).

### 3. HasData API key

Set your HasData API key in `PropertyAPIService.swift` (see `PropertyAPIService` initializer). For setup details, caching behavior, and usage limits, see [HASDATA_API_SETUP.md](HASDATA_API_SETUP.md).

> **Note:** Do not commit production API keys or Firebase secrets to a public repository. Use environment-specific config or Xcode build settings for shared repos.

### 4. Build and run

1. Select the **timbr** scheme in Xcode.
2. Choose a simulator or connected device.
3. Press **Run** (⌘R).

Swift Package Manager dependencies resolve automatically on first build.

## App flow

```
Splash → Welcome (sign up / log in)
              ↓
         Onboarding (if new or incomplete)
              ↓
         Main tabs: Home · Saved · Profile
```

**Onboarding steps**

1. Intent (buy, rent, invest, design inspiration, sell soon)
2. Property types
3. Budget range
4. Location

Preferences are saved to Firestore under `users/{uid}`.

## Project structure

```
timbr/
├── timbrApp.swift              # App entry, Firebase init, tab bar styling
├── ContentView.swift           # Welcome, auth, onboarding routing
├── MainTabView.swift           # Tab container
├── SwipeView.swift             # Property swipe deck
├── SwipeCardView.swift         # Card UI
├── SavedView.swift             # Saved properties
├── ProfileView.swift           # User profile & settings
├── Onboarding*.swift             # Onboarding flow views & manager
├── AuthManager.swift           # Google Sign-In
├── PropertyAPIService.swift    # HasData API client
├── PropertyService.swift       # Firestore cache & property loading
├── Property.swift              # Property model
├── UserPreferences.swift       # Onboarding preferences model
└── Assets.xcassets/            # Images, colors, app icon
```

## Documentation

- [HASDATA_API_SETUP.md](HASDATA_API_SETUP.md) — HasData integration, caching, and usage tracking
- [API_INTEGRATION_GUIDE.md](API_INTEGRATION_GUIDE.md) — Alternative real estate APIs and architecture notes

## Permissions

The app requests **location when in use** to personalize nearby listings (`NSLocationWhenInUseUsageDescription` in `Info.plist`).

## License

No license file is included in this repository. Add one if you plan to open-source or distribute the project.
