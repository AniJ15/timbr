//
//  OnboardingStep4View.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI
import Combine
import CoreLocation

struct OnboardingStep4View: View {
    @ObservedObject var manager: OnboardingManager
    @StateObject private var locationManager = LocationManager()
    @State private var manualLocation: String = ""
    @State private var useLocation: Bool = true
    @State private var locationError: String?
    
    var body: some View {
        VStack(spacing: 32) {
            // Progress indicator
            ProgressView(value: Double(manager.currentStep), total: Double(manager.totalSteps))
                .progressViewStyle(LinearProgressViewStyle(tint: .timbrAccent))
                .padding(.horizontal, 24)
                .padding(.top, 20)
            
            // Back button
            HStack {
                Button(action: {
                    manager.previousStep()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            VStack(spacing: 24) {
                Text("Where are you looking?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Help us show you nearby properties")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 20) {
                // Use current location option
                Button(action: {
                    useLocation = true
                    locationError = nil
                    locationManager.requestLocation()
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.timbrAccent)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Use current location")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                            
                            if let location = locationManager.currentLocation {
                                Text("Location found")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.6))
                            } else if locationManager.isRequesting {
                                Text("Finding location...")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.6))
                            } else if locationManager.authorizationStatus == .denied {
                                Text("Location access denied")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.red.opacity(0.8))
                            } else if let error = locationError {
                                Text(error)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.red.opacity(0.8))
                            } else {
                                Text("Tap to enable location")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        
                        Spacer()
                        
                        if useLocation && locationManager.currentLocation != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.timbrAccent)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(useLocation ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(useLocation ? Color.timbrAccent : Color.clear, lineWidth: 2)
                            )
                    )
                }
                
                // Manual entry option
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Or enter location manually")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    TextField("City, State or ZIP", text: $manualLocation)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                        .onChange(of: manualLocation) { newValue in
                            if !newValue.isEmpty {
                                useLocation = false
                                manager.preferences.location = newValue
                            }
                        }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Continue button
            Button(action: {
                if useLocation, let location = locationManager.currentLocation {
                    manager.preferences.latitude = location.coordinate.latitude
                    manager.preferences.longitude = location.coordinate.longitude
                    manager.preferences.location = "Current Location"
                } else if !manualLocation.isEmpty {
                    manager.preferences.location = manualLocation
                }
                
                Task {
                    await manager.savePreferences()
                }
            }) {
                HStack {
                    if manager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Text("Get Started")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(canContinue ? Color.white : Color.white.opacity(0.3))
                )
            }
            .disabled(!canContinue || manager.isLoading)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.timbrDark.ignoresSafeArea())
        .onAppear {
            // Automatically request location when view appears if useLocation is true
            if useLocation {
                locationManager.requestLocation()
            }
        }
        .onChange(of: locationManager.currentLocation) { location in
            if let location = location {
                manager.preferences.latitude = location.coordinate.latitude
                manager.preferences.longitude = location.coordinate.longitude
                locationError = nil
            }
        }
        .onChange(of: locationManager.locationError) { error in
            locationError = error
        }
    }
    
    private var canContinue: Bool {
        if useLocation {
            return locationManager.currentLocation != nil
        } else {
            return !manualLocation.isEmpty
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var isRequesting = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }
    
    func requestLocation() {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .notDetermined:
            isRequesting = true
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isRequesting = true
            manager.requestLocation()
        case .denied, .restricted:
            locationError = "Location access denied. Please enable in Settings."
            isRequesting = false
        @unknown default:
            locationError = "Unable to access location"
            isRequesting = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            isRequesting = true
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            locationError = "Location access denied. Please enable in Settings."
            isRequesting = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
            isRequesting = false
            locationError = nil
            print("✅ Location found: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
        isRequesting = false
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = "Location access denied"
            case .locationUnknown:
                locationError = "Unable to determine location"
            case .network:
                locationError = "Network error. Please check your connection."
            default:
                locationError = "Failed to get location: \(error.localizedDescription)"
            }
        } else {
            locationError = "Failed to get location"
        }
    }
}

