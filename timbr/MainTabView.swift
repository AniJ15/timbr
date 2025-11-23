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
                    Text("Home")
                }
                .tag(0)
            
            // Explore Tab
            ExploreView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Explore")
                }
                .tag(1)
            
            // Saved/Collections Tab
            SavedView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Saved")
                }
                .tag(2)
            
            // Profile/Settings Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.timbrAccent)
        .onAppear {
            // Customize tab bar appearance to make it smaller
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.timbrDark)
            
            // Make icons and text smaller
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.6),
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.timbrAccent)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color.timbrAccent),
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]
            
            // Reduce tab bar height by adjusting item positioning
            appearance.stackedItemPositioning = .centered
            appearance.stackedItemSpacing = 0
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

