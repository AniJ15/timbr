//
//  timbrApp.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI
import FirebaseCore
import UIKit

@main
struct timbrApp: App {
    init() {
        FirebaseApp.configure()
        setupTabBarAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .preferredColorScheme(.dark)
        }
    }
    
    private func setupTabBarAppearance() {
        // Customize tab bar appearance to make it smaller
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Set background color - use dark teal
        appearance.backgroundColor = UIColor(red: 0x17 / 255.0, green: 0x3c / 255.0, blue: 0x40 / 255.0, alpha: 1.0) // timbrDark
        
        // Make icons and text white for normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Selected state with teal accent
        let accentColor = UIColor(red: 0x5F / 255.0, green: 0xE5 / 255.0, blue: 0xD0 / 255.0, alpha: 1.0) // timbrAccent
        appearance.stackedLayoutAppearance.selected.iconColor = accentColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: accentColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // Reduce tab bar height by adjusting item positioning
        appearance.stackedItemPositioning = .centered
        appearance.stackedItemSpacing = 0
        
        // Set appearance globally - this persists across all tab bars
        let darkTealColor = UIColor(red: 0x17 / 255.0, green: 0x3c / 255.0, blue: 0x40 / 255.0, alpha: 1.0)
        
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
    }
}

