//
//  MainTabView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI
import UIKit

struct MainTabView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home/Swipe Tab
            SwipeView(onboardingManager: onboardingManager)
                .tabItem {
                    Image(systemName: "house.fill")
                        .renderingMode(.template)
                    Text("Home")
                }
                .tag(0)
            
            // Explore Tab
            ExploreView()
                .tabItem {
                    Image(systemName: "map.fill")
                        .renderingMode(.template)
                    Text("Explore")
                }
                .tag(1)
            
            // Saved/Collections Tab
            SavedView()
                .tabItem {
                    Image(systemName: "heart.fill")
                        .renderingMode(.template)
                    Text("Saved")
                }
                .tag(2)
            
            // Profile/Settings Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                        .renderingMode(.template)
                    Text("Profile")
                }
                .tag(3)
        }
        .tint(.timbrAccent)
        .background(Color.timbrDark)
        .onAppear {
            setupTabBarAppearance()
        }
        .onChange(of: selectedTab) { _ in
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        // Ensure tab bar appearance is maintained
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        let darkTealColor = UIColor(red: 0x17 / 255.0, green: 0x3c / 255.0, blue: 0x40 / 255.0, alpha: 1.0)
        appearance.backgroundColor = darkTealColor
        
        // Set normal state to white
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Set selected state to teal accent
        let accentColor = UIColor(red: 0x5F / 255.0, green: 0xE5 / 255.0, blue: 0xD0 / 255.0, alpha: 1.0)
        appearance.stackedLayoutAppearance.selected.iconColor = accentColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: accentColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        appearance.stackedItemPositioning = .centered
        appearance.stackedItemSpacing = 0
        
        // Apply to all tab bars
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().barTintColor = darkTealColor
        UITabBar.appearance().backgroundColor = darkTealColor
        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        UITabBar.appearance().unselectedItemTintColor = UIColor.white
        UITabBar.appearance().tintColor = accentColor
        
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // Force update all existing tab bars
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.subviews.forEach { view in
                    if let tabBar = view as? UITabBar {
                        tabBar.standardAppearance = appearance
                        tabBar.barTintColor = darkTealColor
                        tabBar.backgroundColor = darkTealColor
                        tabBar.unselectedItemTintColor = UIColor.white
                        tabBar.tintColor = accentColor
                        if #available(iOS 15.0, *) {
                            tabBar.scrollEdgeAppearance = appearance
                        }
                    }
                }
            }
        }
    }
}

